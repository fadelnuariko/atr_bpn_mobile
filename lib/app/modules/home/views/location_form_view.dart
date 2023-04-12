import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/home_controller.dart';

class LocationFormView extends StatefulWidget {
  final LatLng coordinates;
  LocationFormView({required this.coordinates});

  @override
  _LocationFormViewState createState() => _LocationFormViewState();
}

class _LocationFormViewState extends State<LocationFormView> {
  final HomeController homeController = Get.find();
  final _formKey = GlobalKey<FormState>();
  String ownerName = '';
  String placeName = '';
  String address = '';
  String placeType = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location Data'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'Owner Name'),
              onChanged: (value) => ownerName = value,
              validator: (value) => value!.isEmpty ? 'Please enter owner name' : null,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Place Name'),
              onChanged: (value) => placeName = value,
              validator: (value) => value!.isEmpty ? 'Please enter place name' : null,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Address'),
              onChanged: (value) => address = value,
              validator: (value) => value!.isEmpty ? 'Please enter address' : null,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Place Type'),
              onChanged: (value) => placeType = value,
              validator: (value) => value!.isEmpty ? 'Please enter place type' : null,
            ),
            // Submit button
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  final locationData = {
                    "ownerName": ownerName,
                    "placeName": placeName,
                    "address": address,
                    "placeType": placeType,
                    "coordinates": "${widget.coordinates.latitude},${widget.coordinates.longitude}",
                    "IsDeleted": false,
                  };
                  await homeController.addLocation(locationData);
                  Get.back();
                }
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
