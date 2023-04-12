import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeController extends GetxController {
  List<dynamic> locations = [];

  RxList<Marker> markers = RxList<Marker>();
  Rx<Marker?> tempMarker = Rx<Marker?>(null);
  Rx<LatLng> markerPosition = LatLng(-7.791648, 110.375304).obs;
  RxBool isAddingLocation = false.obs;

  final PopupController _popupController = PopupController();
  final MapController mapController = MapController();

  PopupController get popupController => _popupController;

  @override
  void onInit() {
    super.onInit();
    fetchMarkers();
  }

  void toggleAddingLocation() {
    isAddingLocation.value = !isAddingLocation.value;
  }

  Map<String, dynamic> getLocationForMarker(Marker marker) {
    try {
      return locations.firstWhere((location) {
        final coords = location['coordinates'].split(',');
        final lat = double.parse(coords[0]);
        final lng = double.parse(coords[1]);

        return marker.point.latitude == lat && marker.point.longitude == lng;
      });
    } catch (e) {
      return {}; // Return an empty map if no location data is found for the marker
    }
  }

  Future<void> fetchMarkers() async {
    final response = await http.get(Uri.parse('http://localhost:36887/api/places'));

    if (response.statusCode == 200) {
      final List<dynamic> decodedLocations = json.decode(response.body);
      locations = decodedLocations.map((location) => location as Map<String, dynamic>).toList();

      markers.value = locations.map((location) {
        final coords = location['coordinates'].split(',');
        final lat = double.parse(coords[0]);
        final lng = double.parse(coords[1]);

        return Marker(
          width: 120,
          point: LatLng(lat, lng),
          builder: (ctx) => const Icon(Icons.location_pin, color: Colors.red, size: 30),
          anchorPos: AnchorPos.align(AnchorAlign.top),
        );
      }).toList();
      update();
    } else {
      throw Exception('Failed to load locations from API');
    }
  }

  Future<void> addLocation(Map<String, dynamic> locationData) async {
    final coords = locationData['coordinates'].split(',');
    final lat = double.parse(coords[0]);
    final lng = double.parse(coords[1]);

    final newMarker = Marker(
      point: LatLng(lat, lng),
      builder: (ctx) => const Icon(
        Icons.location_pin,
        color: Colors.red,
        size: 30,
      ),
      anchorPos: AnchorPos.align(AnchorAlign.top),
    );

    markers.add(newMarker);
    locations.add(locationData);
    update();

    final response = await http.post(
      Uri.parse('http://localhost:36887/api/places/store'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(locationData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add location');
    }
  }

  Future<void> deleteLocation(BuildContext context, int id) async {
    final confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Location'),
          content: Text('Are you sure you want to delete this location?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final response = await http.delete(Uri.parse('http://localhost:36887/api/places/$id'));

      if (response.statusCode == 200) {
        final deletedMarker = markers.firstWhere((marker) {
          final location = getLocationForMarker(marker);
          return location['id'] == id;
        });
        markers.remove(deletedMarker);
        update();
      } else {
        throw Exception('Failed to delete location');
      }
    }
  }

  Future<void> updateLocation(Map<String, dynamic> updatedLocationData) async {
    final String apiUrl = 'http://localhost:36887/api/places/${updatedLocationData['id']}';
    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updatedLocationData),
      );

      if (response.statusCode == 200) {
        // The update was successful, you can refresh the markers or perform any other necessary actions.
        // For example, you can call a method to fetch the updated locations data and update the markers:
        fetchMarkers();
      } else {
        print('Error updating location: ${response.statusCode} - ${response.reasonPhrase}');
        throw Exception('Failed to update location');
      }
    } catch (e) {
      print('Error updating location: $e');
      throw Exception('Failed to update location');
    }
  }
}
