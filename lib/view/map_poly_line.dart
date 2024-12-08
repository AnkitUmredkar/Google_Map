import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapPolyline extends StatefulWidget {
  const GoogleMapPolyline({super.key});

  @override
  State<GoogleMapPolyline> createState() => _GoogleMapPolylineState();
}

class _GoogleMapPolylineState extends State<GoogleMapPolyline> {
  final Location _locationController = new Location();
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  LatLng? _currentP;

  Set<Marker> markers = {};

  final Set<Polyline> _polyline = {};

  List<LatLng> pointOnMap = [
    const LatLng(21.1168, 72.7411), // Dumas Beach
    // const LatLng(21.1702, 72.7933), // VR Surat Mall
    const LatLng(21.1952, 72.8198), // Surat Railway Station
    // const LatLng(21.2071, 72.7994), // Iskon Mall
    // const LatLng(21.1850, 72.8304), // Gopi Talav
    // const LatLng(21.1887, 72.7835), // Science Centre
    // const LatLng(21.2465, 72.8947) // Sarthana Nature Park
  ];

  @override
  void initState() {
    for (int i = 0; i < pointOnMap.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId(
            i.toString(),
          ),
          position: pointOnMap[i],
          infoWindow: const InfoWindow(
              title: "Place around my country", snippet: " So Beautiful"),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );

      setState(() {
        _polyline.add(
          Polyline(
              polylineId: const PolylineId("Id"),
              points: pointOnMap,
              color: Colors.blue,
              width: 3),
        );
      });
    }
    getLocationUpdates();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentP == null
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.red,
              ),
            )
          : GoogleMap(
              markers: markers,
              myLocationButtonEnabled: false,
              polylines: _polyline,
              onMapCreated: (GoogleMapController controller) {
                _mapController.complete(controller);
              },
              initialCameraPosition:
                  CameraPosition(target: _currentP!, zoom: 14),
            ),
    );
  }

  Future<void> getLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationController.serviceEnabled();
    if (serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
    } else {
      return;
    }

    permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {

          _currentP =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
          markers.add(Marker(markerId: MarkerId("_currentLocation"),position: _currentP!,));
          _cameraToPosition(_currentP!);
        });
      }
    });
  }

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition newCameraPosition = CameraPosition(
      target: pos,
      zoom: 13,
    );
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(newCameraPosition),
    );
  }
}
