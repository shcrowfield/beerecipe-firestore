import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<Map<String, dynamic>>> getBeerData() async {
  final docSnapshot = await FirebaseFirestore.instance.collection('beers').get();
  return docSnapshot.docs.map((doc) => doc.data()).toList();
}

Future<List<Map<String, dynamic>>> getHopsData() async {
  final docSnapshot = await FirebaseFirestore.instance.collection('ingredients').doc('hops').get();
  final data = docSnapshot.data();
  if (data == null) return [];

  final hopList = data.values.map((hop) => Map<String, dynamic>.from(hop)).toList();
  hopList.sort((a, b) => a['name'].compareTo(b['name']));
  return hopList;
}

Future<List<Map<String, dynamic>>> getMaltsData() async {
  final docSnapshot = await FirebaseFirestore.instance.collection('ingredients').doc('malts').get();
  final data = docSnapshot.data();
  if (data == null) return [];

  final maltList = data.values.map((malt) => Map<String, dynamic>.from(malt)).toList();
  maltList.sort((a, b) => a['name'].compareTo(b['name']));
  return maltList;
}

Future<List<Map<String, dynamic>>> getYeastsData() async {
  final docSnapshot = await FirebaseFirestore.instance.collection('ingredients').doc('yeasts').get();
  final data = docSnapshot.data();
  if (data == null) return [];

  final yeastList = data.values.map((yeast) => Map<String, dynamic>.from(yeast)).toList();
  yeastList.sort((a, b) => a['name'].compareTo(b['name']));
  return yeastList;
}


