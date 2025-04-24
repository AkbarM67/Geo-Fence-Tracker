import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FirebaseService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> uploadSafeZone(LatLng center, double radius) async {
    await _db.collection("geo_fence").doc("user_1").set({
      "lat": center.latitude,
      "lng": center.longitude,
      "radius": radius,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  static Future<void> uploadCurrentLocation(LatLng location) async {
    await _db.collection("locations").doc("user_1").set({
      "lat": location.latitude,
      "lng": location.longitude,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  static Future<void> uploadPolygon(List<LatLng> points) async {
    final polygonData = points
        .map((e) => {"lat": e.latitude, "lng": e.longitude})
        .toList();

    await _db.collection("geo_fence").doc("user_1_polygon").set({
      "polygon": polygonData,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }
  Future<void> savePolygonToFirebase(List<LatLng> polygon) async {
  final docRef = FirebaseFirestore.instance.collection('polygons').doc();
  await docRef.set({
    'points': polygon
        .map((point) => {'lat': point.latitude, 'lng': point.longitude})
        .toList(),
  });
}
Future<void> deletePolygonFromFirebase(String docId) async {
  await FirebaseFirestore.instance.collection('polygons').doc(docId).delete();
}
}
