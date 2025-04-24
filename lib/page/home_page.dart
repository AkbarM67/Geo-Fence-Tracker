import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'geo_perching_page.dart';
import 'location_tracker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _isSatelliteView = false;

  List<LatLng> _currentDrawingPolygon = [];

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) _startTracking();
  }

  void _startTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 10,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      setState(() {
        _currentPosition = position;
      });
    });
  }

  void _onMapTapped(LatLng point) {
    setState(() {
      _currentDrawingPolygon.add(point);
    });
  }

  Future<void> _uploadPolygonToFirestore(List<LatLng> polygon) async {
    final data = polygon
        .map((point) => {'lat': point.latitude, 'lng': point.longitude})
        .toList();

    await FirebaseFirestore.instance.collection('polygons').add({
      'polygon': data,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geo-Fence Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => setState(() => _currentDrawingPolygon.clear()),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              if (_currentDrawingPolygon.length >= 3) {
                await _uploadPolygonToFirestore(_currentDrawingPolygon);
                setState(() => _currentDrawingPolygon.clear());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Polygon disimpan")),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GeoPerchingPage(
                    onDeletePolygon: (String docId) {
                      FirebaseFirestore.instance
                          .collection('polygons')
                          .doc(docId)
                          .delete();
                    },
                  ),
                ),
              );
              setState(() {});
            },
          ),
            IconButton(
            icon: const Icon(Icons.location_searching),
            onPressed: () async {
              final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LocationTracker(
                  onLocationSelected: (LatLng location) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(location, 17),
                    );
                  },
                ),
              ),
              );
              if (result != null && result is LatLng) {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(result, 17),
              );
              }
            },
          ),
          IconButton(
            icon: Icon(_isSatelliteView ? Icons.map : Icons.satellite),
            onPressed: () {
              setState(() {
                _isSatelliteView = !_isSatelliteView;
              });
            },
          ),
        ],
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('polygons').snapshots(),
          builder: (context, polygonSnapshot) {
            if (!polygonSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
            }

            final polygons = polygonSnapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final points = (data['polygon'] as List)
              .map((p) => LatLng(
                (p['lat'] as num).toDouble(),
                (p['lng'] as num).toDouble(),
              ))
              .toList();

          return Polygon(
            polygonId: PolygonId(doc.id),
            points: points,
            strokeColor: Colors.orange,
            strokeWidth: 2,
            fillColor: Colors.orange.withOpacity(0.3),
          );
            }).toSet();

            return GoogleMap(
          mapType: _isSatelliteView ? MapType.satellite : MapType.normal,
          initialCameraPosition: CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 16,
          ),
          myLocationEnabled: true,
          onMapCreated: (controller) => _mapController = controller,
          onTap: _onMapTapped,
          polygons: {
            ...polygons,
            if (_currentDrawingPolygon.length >= 3)
              Polygon(
            polygonId: const PolygonId('current_drawing'),
            points: _currentDrawingPolygon,
            strokeColor: Colors.blue,
            strokeWidth: 2,
            fillColor: Colors.blue.withOpacity(0.3),
              )
          },
          markers: {
            Marker(
              markerId: const MarkerId("id"),
              position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            )
          },
            );
          }
          )
    );
  }
}
