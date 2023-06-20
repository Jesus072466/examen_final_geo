import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  final String locationName;
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String name;
  final List<List<double>> coordinates;

  const MapScreen({
    Key? key,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.name,
    required this.coordinates,
  }) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<String> images = [
    "assets/icons/placeholder.png",
    "assets/icons/number-1.png",
    "assets/icons/number-2.png",
    "assets/icons/number-3.png",
    "assets/icons/number-4.png",
    "assets/icons/number-5.png",
  ];

  List<LatLng> polygonPoints = const[
    LatLng(21.14473, -101.69624),
    LatLng(21.12912, -101.64242),
    LatLng(21.07972, -101.61882),
    LatLng(21.09165, -101.68894),
    LatLng(21.1256, -101.73289),
  ];

  final List<Marker> _markers = <Marker>[];

  final Completer<GoogleMapController> _controller = Completer();
  Uint8List? markerImage;

  loadData() async {
    try {
      for (int i = 0; i < images.length; i++) {
        final Uint8List markerIcon = await getBytesFromAsset(images[i], 100);
        _markers.add(
          Marker(
            markerId: MarkerId(i.toString()),
            position:
                LatLng(widget.coordinates[i][0], widget.coordinates[i][1]),
            icon: BitmapDescriptor.fromBytes(markerIcon),
            infoWindow: InfoWindow(
              title: widget.name,
              snippet: widget.formattedAddress,
            ),
          ),
        );
        setState(() {});
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

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
            target: LatLng(widget.latitude, widget.longitude),
            zoom: 10.0,
          ),
          mapType: MapType.normal,
          myLocationButtonEnabled: true,
          myLocationEnabled: true,
          markers: Set<Marker>.of(_markers),
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
          polygons: {
            Polygon(
              polygonId: PolygonId('1'),
              points: polygonPoints,
              fillColor: Colors.blue.withOpacity(0.15),
              strokeWidth: 2
            ),
          },
        ),
      ),
    );
  }
}
