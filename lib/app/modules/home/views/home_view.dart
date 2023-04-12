import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/app/modules/home/views/location_form_view.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  HomeView({Key? key}) : super(key: key);
  final _formKey = GlobalKey<FormState>();
  String ownerName = '';
  String placeName = '';
  String address = '';
  String placeType = '';

  Future<Map<String, dynamic>?> showEditLocationFormDialog(
      BuildContext context, Map<String, dynamic> initialData) async {
    ownerName = initialData['ownerName'];
    placeName = initialData['placeName'];
    address = initialData['address'];
    placeType = initialData['placeType'];

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Location Data'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: ownerName,
                    decoration: InputDecoration(labelText: 'Owner Name'),
                    onChanged: (value) => ownerName = value,
                    validator: (value) => value!.isEmpty ? 'Please enter owner name' : null,
                  ),
                  TextFormField(
                    initialValue: placeName,
                    decoration: InputDecoration(labelText: 'Place Name'),
                    onChanged: (value) => placeName = value,
                    validator: (value) => value!.isEmpty ? 'Please enter place name' : null,
                  ),
                  TextFormField(
                    initialValue: address,
                    decoration: InputDecoration(labelText: 'Address'),
                    onChanged: (value) => address = value,
                    validator: (value) => value!.isEmpty ? 'Please enter address' : null,
                  ),
                  TextFormField(
                    initialValue: placeType,
                    decoration: InputDecoration(labelText: 'Place Type'),
                    onChanged: (value) => placeType = value,
                    validator: (value) => value!.isEmpty ? 'Please enter place type' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  final locationData = {
                    "id": initialData['id'],
                    "ownerName": ownerName,
                    "placeName": placeName,
                    "address": address,
                    "placeType": placeType,
                    "coordinates": initialData['coordinates'],
                    "IsDeleted": false,
                  };
                  Navigator.of(context).pop(locationData);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuliner Jogja'),
        centerTitle: true,
      ),
      body: Obx(
        () => Stack(
          children: [
            GetBuilder<HomeController>(
              builder: (controller) => FlutterMap(
                mapController: controller.mapController,
                options: MapOptions(
                  center:
                      LatLng(-7.791648, 110.375304), // Replace with your desired initial location
                  zoom: 12.5,
                  onTap: (tapPosition, latLng) {
                    controller.popupController.hideAllPopups();
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.atr-bpn.app',
                  ),
                  PopupMarkerLayerWidget(
                    options: PopupMarkerLayerOptions(
                      markers: controller.markers,
                      popupController: controller.popupController,
                      markerRotateAlignment:
                          PopupMarkerLayerOptions.rotationAlignmentFor(AnchorAlign.top),
                      popupBuilder: (BuildContext context, Marker marker) {
                        final location = controller.getLocationForMarker(marker);
                        if (location.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          constraints: BoxConstraints(maxWidth: 200),
                          child: Card(
                            elevation: 4.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${location['placeName']} (${location['ownerName']})",
                                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 4.0),
                                  Text(
                                    'Alamat: ${location['address']}',
                                    style: TextStyle(fontSize: 14.0),
                                  ),
                                  SizedBox(height: 4.0),
                                  Text(
                                    'Tipe: ${location['placeType']}',
                                    style: TextStyle(fontSize: 14.0, fontStyle: FontStyle.italic),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      IconButton(
                                        onPressed: () async {
                                          final updatedLocationData =
                                              await showEditLocationFormDialog(context, location);
                                          if (updatedLocationData != null) {
                                            controller.updateLocation(updatedLocationData);
                                          }
                                        },
                                        icon: Icon(Icons.edit, color: Colors.blue),
                                      ),
                                      IconButton(
                                        onPressed: () async {
                                          try {
                                            await controller.deleteLocation(
                                                context, location['id']);
                                            controller.popupController.hidePopupsOnlyFor([marker]);
                                          } catch (e) {
                                            print(e);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Failed to delete location'),
                                              ),
                                            );
                                          }
                                        },
                                        icon: Icon(Icons.delete, color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                        ;
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (controller.isAddingLocation.value)
              Center(
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Add new location?'),
                          content:
                              Text('Do you want to add a new location at the marker position?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                LatLng currentMarkerCoordinates = controller.mapController.center;

                                Navigator.of(context).pop();
                                Get.to(
                                    () => LocationFormView(coordinates: currentMarkerCoordinates));
                              },
                              child: Text('Add new map'),
                            ),
                            TextButton(
                              onPressed: () {
                                // Cancel logic (if needed)
                                controller.toggleAddingLocation();
                                Navigator.of(context).pop();
                              },
                              child: Text('Cancel'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Icon(Icons.location_pin, color: Colors.green, size: 40.0),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.toggleAddingLocation();
        },
        child: const Icon(Icons.add_location),
      ),
    );
  }
}
