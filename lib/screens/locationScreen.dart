import 'dart:async';

import 'package:examen_final/components/locationListTitle.dart';
import 'package:examen_final/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import '../components/networkUtility.dart';
import '../models/autocompletePredictions.dart';
import 'package:http/http.dart' as http;
import '../models/placeAutoCompleteResponse.dart';
import 'mapScreen.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class SearchLocationScreen extends StatefulWidget {
  const SearchLocationScreen({Key? key}) : super(key: key);

  @override
  State<SearchLocationScreen> createState() => _SearchLocationScreenState();
}

class _SearchLocationScreenState extends State<SearchLocationScreen> {
  TextEditingController searchController = TextEditingController();
  String selectedLocation = '';
  String placeDetails = '';
  String formattedAddress = '';
  String name = '';
  List<List<double>> coordinates = [];
  List<String> names = [];

  List<AutoCompletePrediction> placePredictions = [];

  void clearPlacePredictions() {
    setState(() {
      placePredictions.clear();
    });
  }

  FutureOr<Map<String, dynamic>> fetchPlaceDetails(String placeId) async {
    final url =
        Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
      'key': apiKey,
      'place_id': placeId,
    });

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result'];
    } else {
      throw Exception('Failed to load place details');
    }
  }

  FutureOr<void> placeAutoComplete(String query) async {
    Uri uri =
        Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
      'key': apiKey,
      'input': query,
    });
    String? response = await NetworkUtility.fetchUrl(uri);

    if (response != null) {
      PlaceAutocompleteResponse result =
          PlaceAutocompleteResponse.parseAutocompleteResult(response);
      if (result.predictions != null) {
        setState(() {
          placePredictions = result.predictions!;
        });
      }
    }
  }

  FutureOr<void> fetchData() async {
    try {
      var url = Uri.parse('http://10.0.2.2:3900/api/');
      var response =
          await http.get(url, headers: {'Access-Control-Allow-Origin': '*'});

      if (response.statusCode == 200) {
        // La solicitud fue exitosa
        var jsonResponse = jsonDecode(response.body);

        for (var res in jsonResponse['locaciones']) {
          var lat = res['location']['coordinates'][1];
          var long = res['location']['coordinates'][0];
          var name = res['name'];
          coordinates.add([
            lat,
            long,
          ]);
          names.add(name);
          //print(coordinates);
        }
        // Realiza cualquier manipulación de los datos recibidos aquí
        //print("*******unu******************"+jsonEncode(jsonResponse['locaciones'][2]['location']['coordinates'][0]));
      } else {
        // La solicitud falló
        print(
            '*****unu**************Request failed with status: ${response.statusCode}.');
      }
    } catch (e) {
      print("*******0w0**********************error " + e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: defaultPadding),
          child: CircleAvatar(
            backgroundColor: secondaryColor10LightTheme,
            child: SvgPicture.asset(
              'assets/icons/location.svg',
              height: 16,
              width: 16,
              color: secondaryColor40LightTheme,
            ),
          ),
        ),
        title: const Text(
          'Search Location',
          style: TextStyle(
            color: textColorLightTheme,
          ),
        ),
        actions: const [
          CircleAvatar(
            backgroundColor: secondaryColor10LightTheme,
          )
        ],
      ),
      body: Column(
        children: [
          Form(
              child: Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: TextFormField(
              onChanged: (value) {
                placeAutoComplete(value);
              },
              controller: searchController,
              textInputAction: TextInputAction.search,
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontSize: 20,
              ),
              decoration: InputDecoration(
                  hintText: 'Search your location',
                  hintStyle: const TextStyle(
                    fontSize: 20,
                  ),
                  floatingLabelAlignment: FloatingLabelAlignment.center,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: SvgPicture.asset(
                      'assets/icons/location_pin.svg',
                      color: secondaryColor40LightTheme,
                      alignment: Alignment.center,
                    ),
                  )),
            ),
          )),
          const Divider(
            height: 4,
            thickness: 4,
            color: secondaryColor5LightTheme,
          ),
          Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  List<Location> locations =
                      await locationFromAddress(selectedLocation);
                  fetchData();
                  if (locations.isNotEmpty) {
                    Location firstLocation = locations.first;
                    double latitude = firstLocation.latitude;
                    double longitude = firstLocation.longitude;
                    coordinates.add([latitude, longitude]);
                    // Navegar a la vista del mapa y pasar las coordenadas
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapScreen(
                          locationName: selectedLocation,
                          latitude: latitude,
                          longitude: longitude,
                          formattedAddress: formattedAddress,
                          name: name,
                          coordinates: coordinates,
                          names: names,
                        ),
                      ),
                    );
                  } else {
                    // Manejar el caso de que no se encuentren coordenadas para la ubicación seleccionada
                  }
                } catch (e) {
                  // Manejar cualquier error en la geocodificación
                  print(e.toString());
                }
              },
              icon: SvgPicture.asset(
                'assets/icons/location.svg',
                height: 16,
                color: secondaryColor40LightTheme,
              ),
              label: const Text('Search route'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor10LightTheme,
                  foregroundColor: textColorLightTheme,
                  elevation: 0,
                  fixedSize: const Size(double.infinity, 40),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  )),
            ),
          ),
          const Divider(
            height: 4,
            thickness: 4,
            color: secondaryColor5LightTheme,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: placePredictions.length,
              itemBuilder: (context, index) {
                return LocationListTitle(
                  location: placePredictions[index].description!,
                  press: () async {
                    selectedLocation = placePredictions[index].description!;
                    searchController.text = selectedLocation;
                    try {
                      final placeDetails = await fetchPlaceDetails(
                          placePredictions[index].placeId!);
                      formattedAddress = placeDetails['formatted_address'];
                      name = placeDetails['name'];
                      clearPlacePredictions();
                    } catch (e) {
                      print(e);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
