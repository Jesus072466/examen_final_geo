import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:examen_final/constants.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart' as plp;
import 'package:google_directions_api/google_directions_api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/directions.dart' as directions;
import 'package:http/http.dart' as http;


class MapScreen extends StatefulWidget {
  final String locationName;
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String name;
  final List<List<double>> coordinates;
  final List<String> names;

  const MapScreen({
    Key? key,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.name,
    required this.coordinates,
    required this.names,
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

  List<LatLng> polygonPoints = const [
    LatLng(21.14473, -101.69624),
    LatLng(21.12912, -101.64242),
    LatLng(21.07972, -101.61882),
    LatLng(21.09165, -101.68894),
    LatLng(21.1256, -101.73289),
  ];

  late var destinations;

   double _duration = 0;

  final List<Marker> _markers = <Marker>[];

  final Completer<GoogleMapController> _controller = Completer();
  Uint8List? markerImage;

  Set<Polyline> _polylines = {};
  
  @override
  initState() {
    super.initState();
    loadData(); // load markers
    
  }

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
    ordenar();
  }

  ordenar() async {
    List<dynamic> distancias = await Distancias();
    print(distancias);
    distancias.sort((a, b) => a[1].compareTo(b[1]));

    // Imprimir la lista ordenada
    distancias.forEach((item) {
      print("${item[0]}: ${item[1]} km");
    });

    LatLng origin = LatLng(widget.latitude, widget.longitude ); // Coordenadas del origen (ejemplo: San Francisco)
    LatLng destination = LatLng(distancias[1][2],distancias[1][3]); // Coordenadas del destino (ejemplo: Los Angeles)
LatLng destination2 = LatLng(distancias[2][2],distancias[3][3]);

    _addRuta(origin, destination);
    _addRuta(origin, destination2);
    
  _createRoutePolygon();
  }



  FutureOr<List<dynamic>> Distancias() async {
    final distancias = [];
    print(widget.names[0]);

    print(widget.names);
    List<Map<String, dynamic>> locations = [
      {
        "lat": widget.coordinates[0][0],
        "lng": widget.coordinates[0][1],
        "name": widget.names[0]
      }, // Ubicación 1
      {
        "lat": widget.coordinates[1][0],
        "lng": widget.coordinates[1][1],
        "name": widget.names[1]
      }, // Ubicación 2
      {
        "lat": widget.coordinates[2][0],
        "lng": widget.coordinates[2][1],
        "name": widget.names[2]
      }, // Ubicación 3
      {
        "lat": widget.coordinates[3][0],
        "lng": widget.coordinates[3][1],
        "name": widget.names[3]
      }, // Ubicación 4
      {
        "lat": widget.coordinates[4][0],
        "lng": widget.coordinates[4][1],
        "name": widget.names[4]
      }, // Ubicación 5
    ];
    // Calcular la distancia a cada ubicación
    for (var location in locations) {
      double endLat = location["lat"];
      double endLng = location["lng"];
      String name = location["name"];
      double distance =
          await getDistance(widget.latitude, widget.longitude, endLat, endLng);
      print(
          "Distancia ${name} ubicación (${endLat}, ${endLng}): ${distance} km");
      distancias.add([name, distance, endLat, endLng]);
    }
    return distancias;
  }
List<LatLng> _point = [];

FutureOr<void> _addRuta(LatLng origin, LatLng destination) async {
    final request = DirectionsRequest(
        origin: GeoCoord(origin.latitude, origin.longitude),
        destination: GeoCoord(destination.latitude, destination.longitude),
        travelMode: TravelMode.driving,
        optimizeWaypoints: false);

    DirectionsService.init(apiKey);
    final DirectionsService directionsService = DirectionsService();
    
    await directionsService.route(request, (routeResult, status) {
      if (status == DirectionsStatus.ok) {
        _duration +=
            routeResult.routes!.first.legs!.first.duration!.value!.floor();
        var pointsFirst = plp.PolylinePoints().decodePolyline(
            routeResult.routes!.first.overviewPolyline!.points!);
            List<LatLng> polylineCoordinates = [];
            
        print(routeResult.routes![0].legs!.first.duration?.value);
        _point.addAll(
            pointsFirst.map((e) => LatLng(e.latitude, e.longitude)).toList());
        
        
      } else {
        print(routeResult.errorMessage);
      }
    });
  }


  _createRoutePolygon() {
    return Polygon(
        geodesic: false,
        fillColor: Colors.blue,
        strokeColor: Colors.red,
        polygonId: PolygonId('route'),
        points: _point..addAll((_point.reversed.toList())));
  }

  
  FutureOr<double> getDistance(
      double startLat, double startLng, double endLat, double endLng) async {
    final String baseUrl =
        "https://maps.googleapis.com/maps/api/directions/json";

    final response = await http.get(Uri.parse(
        "$baseUrl?origin=$startLat,$startLng&destination=$endLat,$endLng&key=$apiKey"));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final distanceText = data["routes"][0]["legs"][0]["distance"]["text"];
      final distanceValue = data["routes"][0]["legs"][0]["distance"]["value"];

      print("Distancia a ubicación (${endLat}, ${endLng}): $distanceText");

      return distanceValue / 1000.0; // Convertir la distancia a kilómetros
    } else {
      throw Exception("Error al obtener la distancia: ${response.statusCode}");
    }
  }

  FutureOr<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
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
          polylines: _polylines,
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
                polygonId: const PolygonId('1'),
                points: polygonPoints,
                fillColor: Colors.blue.withOpacity(0.15),
                strokeWidth: 2),
          },
        ),
      ),
    );
  }
}
