import 'package:beerecipe/create_recipe.dart';
import 'package:beerecipe/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'modify_recipe.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<Map<String, dynamic>>>? _dataFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = getBeerData();
  }

  // Kijelentkezés függvény a HomePage-hez
  Future<void> _logOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        // Értesítés a felhasználónak
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully logged out'))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Issue during log out: $e'))
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Beerecipe'),
        actions: [
          _isLoading
              ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
              : IconButton(
            onPressed: () async {
              await _logOut();
              Navigator.of(context).pushReplacementNamed('/');
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No recipes found.'));
          } else {
            final beers = snapshot.data!;
            return ListView.builder(
              itemCount: beers.length,
              itemBuilder: (context, index) {
                final beer = beers[index];
                return InkWell(
                  onLongPress: () async {
                    // First delete all documents in the versions subcollection
                    final versionsSnapshot = await FirebaseFirestore.instance
                        .collection('beers')
                        .doc(beer['id'])
                        .collection('versions')
                        .get();

                    // Delete each document in the subcollection
                    for (var doc in versionsSnapshot.docs) {
                      await FirebaseFirestore.instance
                          .collection('beers')
                          .doc(beer['id'])
                          .collection('versions')
                          .doc(doc.id)
                          .delete();
                    }

                    // Then delete the main document
                    await FirebaseFirestore.instance
                        .collection('beers')
                        .doc(beer['id'])
                        .delete();

                    setState(() {
                      _dataFuture = getBeerData();
                    });
                  },
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ModifyRecipe(beer: beer),
                      ),
                    ).then((_) {
                      // Refresh list when returning from ModifyRecipe
                      setState(() {
                        _dataFuture = getBeerData();
                      });
                    });
                  },
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(beer['name'] ?? 'Unknown'),
                      subtitle: Text('Style: ${beer['style'] ?? 'N/A'}\n'
                          'ABV: ${beer['abv'] ?? '-'}% | IBU: ${beer['ibu'] ?? '-'}'),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateRecipe(),
            ),
          ).then((_) {
            // Refresh list when returning from CreateRecipe
            setState(() {
              _dataFuture = getBeerData();
            });
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
