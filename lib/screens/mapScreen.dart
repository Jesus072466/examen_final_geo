import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatelessWidget {
  final String locationName;
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String name;
  final List<List<double>> coordinates;

  const MapScreen(
      {Key? key,
      required this.locationName,
      required this.latitude,
      required this.longitude,
      required this.formattedAddress,
      required this.name,
      required this.coordinates})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        color: Colors.white,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(latitude,
                longitude), // Coordenadas iniciales, se actualizarán más adelante
            zoom: 10.0,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('selectedLocation'),
              position: LatLng(latitude, longitude),
              infoWindow: InfoWindow(title: name, snippet: formattedAddress),
            ),
          },
        ),
      ),
    );
  }
}
