import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'database_service.dart';
import 'constants.dart';

class ModifyRecipe extends StatefulWidget {
  const ModifyRecipe({super.key, required this.beer});
  final Map<String, dynamic> beer;

  @override
  State<ModifyRecipe> createState() => _ModifyRecipeState();
}

class _ModifyRecipeState extends State<ModifyRecipe> {
  late Future<List<List<Map<String, dynamic>>>> _dataFuture;

  late String createdBy;
  late String beerName;
  late String beerStyle;
  late Map<String, dynamic> hopMap;
  late Map<String, dynamic> maltMap;
  late Map<String, Map<String, dynamic>> hopMapMap;
  late Map<String, Map<String, dynamic>> maltMapMap;
  late String yeast;
  late String ibu;
  late String abv;
  late String og;
  late String fg;
  late String id;
  late String version;
  late String description;
  late TextEditingController beerNameController;
  late TextEditingController hopGramController;
  late TextEditingController hopMinController;
  late TextEditingController maltKgController;
  late TextEditingController maltGramController;
  late TextEditingController ibuController;
  late TextEditingController abvController;
  late TextEditingController ogController;
  late TextEditingController fgController;
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();
    // Assign values from widget.beer or defaults
    createdBy = widget.beer['createdBy'] ?? '';
    id = widget.beer['id'] ?? '';
    beerName = widget.beer['name'] ?? '';
    beerStyle = widget.beer['style'] ?? '';
    hopMapMap = Map<String, Map<String, dynamic>>.from(widget.beer['hops'] ?? {});
    maltMapMap = Map<String, Map<String, dynamic>>.from(widget.beer['malts'] ?? {});
    yeast = widget.beer['yeast'] ?? '';
    ibu = widget.beer['ibu']?.toString() ?? '';
    abv = widget.beer['abv']?.toString() ?? '';
    og = widget.beer['og']?.toString() ?? '';
    fg = widget.beer['fg']?.toString() ?? '';
    version = widget.beer['version']?.toString() ?? '';
    description = widget.beer['description'] ?? '';
    // For new entries
    hopMap = {'id': '', 'name': '', 'g': '0', 'min': '0'};
    maltMap = {'id': '', 'name': '', 'kg': '0', 'g': '0'};
    beerNameController = TextEditingController(text: beerName);
    hopGramController = TextEditingController(text: hopMap['g']);
    hopMinController = TextEditingController(text: hopMap['min']);
    maltKgController = TextEditingController(text: maltMap['kg']);
    maltGramController = TextEditingController(text: maltMap['g']);
    ibuController = TextEditingController(text: ibu);
    abvController = TextEditingController(text: abv);
    ogController = TextEditingController(text: og);
    fgController = TextEditingController(text: fg);
    descriptionController = TextEditingController(text: description);
    _dataFuture = Future.wait([
      getHopsData(),
      getMaltsData(),
      getYeastsData(),
      getBeerData(),
      getVersionsForBeer(id),
    ]);
    print('Current user: ${FirebaseAuth.instance.currentUser?.email}');
  }

  @override
  void dispose() {
    beerNameController.dispose();
    hopGramController.dispose();
    hopMinController.dispose();
    maltKgController.dispose();
    maltGramController.dispose();
    ibuController.dispose();
    abvController.dispose();
    ogController.dispose();
    fgController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> getVersionsForBeer(String beerId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('beers')
        .doc(beerId)
        .collection('versions')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  void loadVersionData(String selectedVersion, List<Map<String, dynamic>> versions) {
    final versionData = versions.firstWhere(
          (v) => v['version'].toString() == selectedVersion,
      orElse: () => {},
    );


    if (versionData.isNotEmpty) {
      setState(() {
        beerName = versionData['name'] ?? '';
        beerStyle = versionData['style'] ?? '';
        hopMapMap = Map<String, Map<String, dynamic>>.from(versionData['hops'] ?? {});
        maltMapMap = Map<String, Map<String, dynamic>>.from(versionData['malts'] ?? {});
        yeast = versionData['yeast'] ?? '';
        ibu = versionData['ibu']?.toString() ?? '';
        abv = versionData['abv']?.toString() ?? '';
        og = versionData['og']?.toString() ?? '';
        fg = versionData['fg']?.toString() ?? '';
        version = versionData['version']?.toString() ?? '';
        description = versionData['description'] ?? '';

        // Frissítsd a kontrollereket is
        beerNameController.text = beerName;
        ibuController.text = ibu;
        abvController.text = abv;
        ogController.text = og;
        fgController.text = fg;
        descriptionController.text = description;
      });
    }
  }

  Future<void> saveBeerRecipe() async {
    final beerData = {
      'createdBy': createdBy,
      'name': beerName,
      'style': beerStyle,
      'hops': hopMapMap,
      'malts': maltMapMap,
      'yeast': yeast,
      'ibu': ibu,
      'abv': abv,
      'og': og,
      'fg': fg,
      'id': id,
      'version': version,
      'description': description,
    };

    // Ellenőrizzük, hogy minden mező ki van-e töltve
    if (beerData.entries.any((element) => element.value == '') || description == '') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Please fill in all fields.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance.collection('beers').doc(id);

      // Tranzakció használata az adatok konzisztens kezelésére
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Lekérjük a dokumentumot a tranzakción belül
        final oldSnapshot = await transaction.get(docRef);

        if (oldSnapshot.exists) {
          final oldData = oldSnapshot.data();

          if (oldData != null) {
            final filteredOldData = Map<String, dynamic>.from(oldData)..remove('timestamp');

            final isEqual = const DeepCollectionEquality().equals(
              _sortedMap(beerData),
              _sortedMap(filteredOldData),
            );

            if (!isEqual) {
              print('Változás történt - új verzió mentése');

              // Növeljük a verzió számot
              int newVersionNumber = int.parse(version) + 1;

              // Az aktuális verzió mentése a versions subcollection-be
              // A verzió ID formátuma: "beerName - X" ahol X az aktuális verzió
              final currentVersionId = "$beerName - $version";

              // Az aktuális adatok másolata lesz a verzió
              final versionData = Map<String, dynamic>.from(beerData);

              // Tranzakción belül hozzuk létre a verzió dokumentumot
              transaction.set(
                  docRef.collection('versions').doc(currentVersionId),
                  versionData
              );

              // Beállítjuk az új verzió számot a fő dokumentumban
              beerData['version'] = newVersionNumber.toString();

              // Frissítjük a fő dokumentumot az új verzióval a tranzakción belül
              transaction.set(docRef, beerData);

              // Frissítjük a helyi version változót is (tranzakción kívül)
              version = newVersionNumber.toString();
            } else {
              print('Nem történt változás - nem ment új verziót.');
            }
          }
        }
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You do not have permission to modify this recipe.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Issue: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected issue: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }




  /// Rekurzívan rendezi a map kulcsait mély összehasonlításhoz
  Map<String, dynamic> _sortedMap(Map<String, dynamic> map) {
    final sorted = Map<String, dynamic>.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    for (final entry in sorted.entries) {
      if (entry.value is Map) {
        sorted[entry.key] = _sortedMap(Map<String, dynamic>.from(entry.value));
      } else if (entry.value is List) {
        sorted[entry.key] = List.from(entry.value);
      }
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
            title: const Text(
              'Modify Recipe',
            )),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustomScrollView(
            slivers: [
              SliverList(delegate: SliverChildListDelegate([
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
                        controller: beerNameController,
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
                              initialSelection: beerStyle,
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
                      final versions = data[4]; // Az 5. elem a versions lista

                      return Column(
                        children: [
                          Row(
                            children: [
                              const SizedBox(
                                width: 50,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text('Ver.'),
                                ),
                              ),
                              SizedBox(
                                width: 200,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: DropdownMenu<String>(
                                    dropdownMenuEntries: versions.map((ver) =>
                                        DropdownMenuEntry<String>(
                                          value: ver['version']?.toString() ?? '',
                                          label: 'Version ${ver['version']}',
                                        )
                                    ).toList(),
                                    onSelected: (value) {
                                      if (value != null) {
                                        loadVersionData(value, versions);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                              Expanded(child: TextField(
                                keyboardType: TextInputType.number,
                                controller: hopGramController,
                                onChanged: (value) {
                                  hopMap['g'] = value;
                                },
                              )),
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('g'),
                              ),
                              Expanded(child: TextField(
                                keyboardType: TextInputType.number,
                                controller: hopMinController,
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
                                String hopId = hopMap['name'] + hopMap['g'] + hopMap['min'];
                                hopMap['id'] = hopId;
                                setState(() {
                                  hopMapMap[hopId] = Map<String, dynamic>.from(hopMap);
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
                                        .map((malt) => DropdownMenuEntry<String>(
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
                              Expanded(child: TextField(
                                keyboardType: TextInputType.number,
                                controller: maltKgController,
                                onChanged: (value) {
                                  maltMap['kg'] = value;
                                },
                              )),
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('kg'),
                              ),
                              Expanded(child: TextField(
                                keyboardType: TextInputType.number,
                                controller: maltGramController,
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
                                String maltId = maltMap['name'] + maltMap['kg'] + maltMap['g'];
                                maltMap['id'] = maltId;
                                setState(() {
                                  maltMapMap[maltId] = Map<String, dynamic>.from(maltMap);
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
                                    initialSelection: yeast,
                                    dropdownMenuEntries: yeasts
                                        .map((yeast) => DropdownMenuEntry<String>(
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
                          controller: ibuController,
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
                      Expanded(child: TextField(
                        keyboardType: TextInputType.number,
                        controller: abvController,
                        onChanged: (value) {
                          setState(() {
                            abv = value;
                          });
                        },
                      )),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('OG'),
                      ),
                      Expanded(child: TextField(
                        keyboardType: TextInputType.number,
                        controller: ogController,
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
                      Expanded(child: TextField(
                        keyboardType: TextInputType.number,
                        controller: fgController,
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
              if(maltMapMap.isNotEmpty)SliverList(
                delegate: SliverChildListDelegate([
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Malts'),
                  ),
                ]),
              ),
              SliverList(delegate: SliverChildBuilderDelegate((context, index) {
                final malt =  maltMapMap.values.toList()[index];
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
              if(hopMapMap.isNotEmpty)SliverList(
                delegate: SliverChildListDelegate([
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Hops'),
                  ),
                ]),
              ),
              SliverList(delegate: SliverChildBuilderDelegate((context, index) {
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

              if(yeast != "")SliverList(
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
                      'IBU: $ibu ABV: $abv% OG: $og° FG: $fg°', style: const TextStyle(color: Colors.brown, fontSize: 18, fontWeight: FontWeight.bold),),
                  ),
                  TextField(
                    keyboardType: TextInputType.multiline,
                    controller: descriptionController,

                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      description = value;
                    },
                  )
                ]),
              ),
            ],
          ),
        )
    );
  }
}