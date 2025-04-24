import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeoPerchingPage extends StatelessWidget {
  final void Function(String docId) onDeletePolygon;

  const GeoPerchingPage({super.key, required this.onDeletePolygon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Geo-Perching')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('polygons').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final polygon = (data['polygon'] as List)
                  .map((p) => LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()))
                  .toList();

              return ListTile(
                title: Text('Area ${index + 1}'),
                subtitle: Text('${polygon.length} titik koordinat'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Konfirmasi Hapus'),
                        content: Text('Hapus Area ${index + 1}?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                          TextButton(
                            onPressed: () {
                              onDeletePolygon(doc.id);
                              Navigator.pop(context);
                            },
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('Detail Area ${index + 1}'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView(
                          shrinkWrap: true,
                          children: polygon
                              .map((p) => Text('Lat: ${p.latitude}, Lng: ${p.longitude}'))
                              .toList(),
                        ),
                      ),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
