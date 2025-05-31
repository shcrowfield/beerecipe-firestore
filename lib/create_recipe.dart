import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'database_service.dart';
import 'constants.dart';

class CreateRecipe extends StatefulWidget {
  const CreateRecipe({super.key});

  @override
  State<CreateRecipe> createState() => _CreateRecipeState();
}

class _CreateRecipeState extends State<CreateRecipe> {
  User? user = FirebaseAuth.instance.currentUser;
  late Future<List<List<Map<String, dynamic>>>> _dataFuture;
  String beerName = '';
  String beerStyle = '';
  Map<String, dynamic> hopMap = {
    'id': '',
    'name': '',
    'g': '',
    'min': '',
  };
  Map<String, dynamic> maltMap = {
    'id': '',
    'name': '',
    'kg': '',
    'g': '',
  };
  Map<String, Map<String, dynamic>> hopMapMap = {};
  Map<String, Map<String, dynamic>> maltMapMap = {};
  String yeast = '';
  String ibu = '0';
  String abv = '0';
  String og = '0';
  String fg = '0';
  int version = 1;
  String description = '';

  @override
  void initState() {
    super.initState();
    _dataFuture = Future.wait([
      getHopsData(),
      getMaltsData(),
      getYeastsData(),
      getBeerData(),
    ]);
    print('Current user: ${FirebaseAuth.instance.currentUser?.email}');

  }

  Future<void> saveBeerRecipe() async {
    String beerId = '$beerName${Random().nextInt(9999).toString().padLeft(4, '0')}';
    final beerData = {
      'id': beerId,
      'createdBy': user?.email,
      'name': beerName,
      'style': beerStyle,
      'hops': hopMapMap,
      'malts': maltMapMap,
      'yeast': yeast,
      'ibu': ibu,
      'abv': abv,
      'og': og,
      'fg': fg,
      'version': version,
      'description': '$beerName - $version - $beerStyle',
    };

    if (beerData.entries.any((element) => element.value == '')) {
      print('Valami nem gyó');
    } else {
      // Tranzakciókezelés bevezetése
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Dokumentum referencia létrehozása
        final docRef = FirebaseFirestore.instance.collection('beers').doc(beerId);

        // Verzió dokumentum referencia létrehozása
        final versionDocRef = docRef.collection('versions').doc('$beerName - $version');

        // Fő dokumentum létrehozása a beers kollekcióban a tranzakción belül
        transaction.set(docRef, {
          'id': beerId,
          'createdBy': user?.email,
          'name': beerName,
          'style': beerStyle,
          'hops': hopMapMap,
          'malts': maltMapMap,
          'yeast': yeast,
          'ibu': ibu,
          'abv': abv,
          'og': og,
          'fg': fg,
          'version': version,
          'description': '$beerName - $version - $beerStyle',
        });

        // Verzió mentése a subcollection-be a tranzakción belül
        transaction.set(versionDocRef, beerData);
      });

      print('Beer recipe saved successfully!');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
            title: const Text(
          'Create Recipe',
        )),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustomScrollView(
            slivers: [
              SliverList(
                  delegate: SliverChildListDelegate([
                Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Name'),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 200,
                      child: TextField(
                        onChanged: (value) {
                          beerName = value;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(
                      width: 50,
                      child: Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text('Style'),
                      ),
                    ),
                    SizedBox(
                        width: 200,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: DropdownMenu(
                              dropdownMenuEntries: beerStylesDropdownEntries,
                              onSelected: (value) {
                                beerStyle = value!;
                              }),
                        )),
                  ],
                ),
                FutureBuilder<List<List<Map<String, dynamic>>>>(
                  future: _dataFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No ingredients found.'));
                    } else {
                      final data = snapshot.data!;
                      final hops = data[0];
                      final malts = data[1];
                      final yeasts = data[2];
                      //final beers = data[3];

                      return Column(
                        children: [
                          Row(
                            children: [
                              const SizedBox(
                                width: 50,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text('Hops'),
                                ),
                              ),
                              SizedBox(
                                width: 200,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: DropdownMenu(
                                    dropdownMenuEntries: hops
                                        .map((hop) => DropdownMenuEntry<String>(
                                              label: hop['name'] ?? 'Unknown',
                                              value: hop['name'] ?? '',
                                            ))
                                        .toList(),
                                    onSelected: (value) {
                                      setState(() {
                                        hopMap['name'] = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              Expanded(
                                  child: TextField(
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  hopMap['g'] = value;
                                },
                              )),
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('g'),
                              ),
                              Expanded(
                                  child: TextField(
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  hopMap['min'] = value;
                                },
                              )),
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('min'),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              child: const Text('Add'),
                              onPressed: () {
                                String hopId = hopMap['name'] +
                                    hopMap['g'] +
                                    hopMap['min'];
                                hopMap['id'] = hopId;
                                setState(() {
                                  hopMapMap[hopId] =
                                      Map<String, dynamic>.from(hopMap);
                                });
                              },
                            ),
                          ),
                          Row(
                            children: [
                              const SizedBox(
                                  width: 50,
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Text('Malts'),
                                  )),
                              SizedBox(
                                width: 200,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: DropdownMenu(
                                    dropdownMenuEntries: malts
                                        .map((malt) =>
                                            DropdownMenuEntry<String>(
                                              label: malt['name'] ?? 'Unknown',
                                              value: malt['name'] ?? '',
                                            ))
                                        .toList(),
                                    onSelected: (value) {
                                      setState(() {
                                        maltMap['name'] = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              Expanded(
                                  child: TextField(
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  maltMap['kg'] = value;
                                },
                              )),
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('kg'),
                              ),
                              Expanded(
                                  child: TextField(
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  maltMap['g'] = value;
                                },
                              )),
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('g'),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              child: const Text('Add'),
                              onPressed: () {
                                String maltId = maltMap['name'] +
                                    maltMap['kg'] +
                                    maltMap['g'];
                                maltMap['id'] = maltId;
                                setState(() {
                                  maltMapMap[maltId] =
                                      Map<String, dynamic>.from(maltMap);
                                });
                              },
                            ),
                          ),
                          Row(
                            children: [
                              const SizedBox(
                                width: 50,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: Text('Yeast'),
                                ),
                              ),
                              SizedBox(
                                width: 200,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: DropdownMenu(
                                    dropdownMenuEntries: yeasts
                                        .map((yeast) =>
                                            DropdownMenuEntry<String>(
                                              label: yeast['name'] ?? 'Unknown',
                                              value: yeast['name'] ?? '',
                                            ))
                                        .toList(),
                                    onSelected: (value) {
                                      setState(() {
                                        yeast = value!;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('IBU'),
                      ),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              ibu = value;
                            });
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('ABV'),
                      ),
                      Expanded(
                          child: TextField(
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            abv = value;
                            ;
                          });
                        },
                      )),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('OG'),
                      ),
                      Expanded(
                          child: TextField(
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            og = value;
                          });
                        },
                      )),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('FG'),
                      ),
                      Expanded(
                          child: TextField(
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            fg = value;
                          });
                        },
                      )),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        saveBeerRecipe().then((_) {
                          Navigator.pop(context);
                        });
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ),
              ])),
              if (maltMapMap.isNotEmpty)
                SliverList(
                  delegate: SliverChildListDelegate([
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Malts'),
                    ),
                  ]),
                ),
              SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                final malt = maltMapMap.values.toList()[index];
                final name = malt['name'] ?? 'Unknown';
                final kg = malt['kg'] ?? '0';
                final g = malt['g'] ?? '0';
                return InkWell(
                  onLongPress: () {
                    setState(() {
                      maltMapMap.remove(malt['id']);
                    });
                  },
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text('kg: $kg' ' g: $g'),
                    ),
                  ),
                );
              }, childCount: maltMapMap.length)),
              if (hopMapMap.isNotEmpty)
                SliverList(
                  delegate: SliverChildListDelegate([
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Hops'),
                    ),
                  ]),
                ),
              SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                final hop = hopMapMap.values.toList()[index];
                final name = hop['name'] ?? 'Unknown';
                final g = hop['g'] ?? '0';
                final min = hop['min'] ?? '0';
                return InkWell(
                  onLongPress: () {
                    setState(() {
                      hopMapMap.remove(hop['id']);
                    });
                  },
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text('g: $g' ' min: $min'),
                    ),
                  ),
                );
              }, childCount: hopMapMap.length)),
              if (yeast != "")
                SliverList(
                  delegate: SliverChildListDelegate([
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Yeast'),
                    ),
                    Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(yeast),
                      ),
                    ),
                    Center(
                      child: Text(
                        'IBU: $ibu ABV: $abv% OG: $og° FG: $fg°',
                        style: const TextStyle(
                            color: Colors.brown,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    )
                  ]),
                ),
            ],
          ),
        ));
  }
}
