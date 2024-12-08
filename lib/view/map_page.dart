import 'dart:async';
import 'dart:collection';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

TextEditingController _searchController = TextEditingController();

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  //todo --------> controller and object declaration
  final Location _locationController = Location();
  final CustomInfoWindowController customInfoWindowController =
      CustomInfoWindowController();
  final Completer<GoogleMapController> completer =
      Completer<GoogleMapController>();
  late GoogleMapController googleMapController;
  BitmapDescriptor customIcon = BitmapDescriptor.defaultMarker;

  //todo --------> list, Map or variable initialization
  static LatLng destination = const LatLng(21.190237, 72.865296);
  Set<Marker> markers = {};
  Set<Polygon> polygons = HashSet<Polygon>();
  LatLng? _currentP;
  List<LatLng> points = [
    const LatLng(21.178114, 72.797981),
    const LatLng(21.137744, 72.826559),
    const LatLng(21.175130, 72.870825),
    const LatLng(21.209372, 72.833386),
  ];

  void addPolygon() {
    polygons.add(
      Polygon(
        polygonId: const PolygonId("Id"),
        points: points,
        strokeColor: Colors.blue.shade400,
        strokeWidth: 4,
        fillColor: Colors.green.withOpacity(0.1),
        geodesic: true,
      ),
    );
  }

  void initCustomMarker() {
    BitmapDescriptor.asset(
            const ImageConfiguration(), "assets/images/location.png")
        .then(
      (value) {
        setState(() {
          customIcon = value;
        });
      },
    );
  }

  @override
  void initState() {
    getLocationRequest();
    addPolygon();
    initCustomMarker();
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
          : Stack(
              children: [
                GoogleMap(
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  onMapCreated: (GoogleMapController controller) {
                    googleMapController = controller;
                    completer.complete(controller);
                    customInfoWindowController.googleMapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: _currentP!,
                    zoom: 13,
                  ),
                  markers: markers,
                  polygons: polygons,
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId(
                          "route1"), // Unique ID for the polyline
                      points: [
                        LatLng(_currentP!.latitude, _currentP!.longitude),
                        LatLng(destination.latitude, destination.longitude),
                      ],
                      color: Colors.blue, // Line color
                      width: 5, // Line width
                    ),
                  },
                ),
                CustomInfoWindow(
                  controller: customInfoWindowController,
                  height: 155,
                  width: 250,
                  offset: 40,
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                    child: TextField(
                      controller: _searchController,
                      // Assign controller to manage text
                      onSubmitted: (value) {},
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: "Search destination",
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: (_currentP != null)
          ? FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () {
                setState(() {
                  getCurrentLocation();
                });
              },
              child: const Icon(Icons.my_location),
            )
          : const SizedBox(),
    );
  }

  Future<void> getLocationRequest() async {
    bool serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) {
        return; // Exit if location service is not enabled
      }
    }

    PermissionStatus permissionGranted =
        await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return; // Exit if permission is not granted
      }
    }

    //todo ------------------------------------> Fetch current location
    Position currentLocation = await Geolocator.getCurrentPosition();
    setState(() {
      _currentP = LatLng(currentLocation.latitude, currentLocation.longitude);
      markers.add(Marker(
        markerId: const MarkerId("_currentLocation"),
        icon: customIcon,
        position: _currentP!,
        onTap: () {
          customInfoWindowController.addInfoWindow!(
            Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.network(
                    "https://i.ytimg.com/vi/bsRBZr7VkQY/maxresdefault.jpg",
                    height: 125,
                    width: 250,
                    fit: BoxFit.cover,
                  ),
                  const Text(
                    "Adajan",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            _currentP!,
          );
          // Hide the info window after 5 seconds
          Future.delayed(const Duration(seconds: 5), () {
            customInfoWindowController.hideInfoWindow!();
          });
        },
      ));
      markers.add(
        Marker(
          markerId: const MarkerId("_destinationLocation"),
          draggable: true,
          onDragEnd: (value) {
            setState(() {
              destination = value;
              getCurrentLocation(); //todo -----------> Update the destination when drag ends
            });
          },
          icon: customIcon,
          //BitmapDescriptor.defaultMarker,
          position: destination,
          infoWindow: const InfoWindow(
            title: "Title of marker",
            snippet: "More info about marker",
          ),
        ),
      );
    });
    _moveCameraToPosition(_currentP!);
  }

  Future<void> getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentP = LatLng(position.latitude, position.longitude);
      markers.add(Marker(
        markerId: const MarkerId("_currentLocation"),
        icon: customIcon,
        position: _currentP!,
        onTap: () {
          customInfoWindowController.addInfoWindow!(
            Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.network(
                    "https://i.ytimg.com/vi/bsRBZr7VkQY/maxresdefault.jpg",
                    height: 125,
                    width: 250,
                    fit: BoxFit.cover,
                  ),
                  const Text(
                    "Adajan",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            _currentP!,
          );
          // Hide the info window after 5 seconds
          Future.delayed(const Duration(seconds: 5), () {
            customInfoWindowController.hideInfoWindow!();
          });
        },
      ));
      markers.add(
        Marker(
          draggable: true,
          onDragEnd: (value) {
            setState(() {
              destination = value; //todo ----------> Update the destination when drag ends
            });
          },
          markerId: const MarkerId("_destinationLocation"),
          icon: customIcon, //BitmapDescriptor.defaultMarker,
          position: destination,
          infoWindow: const InfoWindow(
            title: "Title of marker",
            snippet: "More info about marker",
          ),
        ),
      );
    });

    _moveCameraToPosition(_currentP!);
  }

  Future<void> _moveCameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await completer.future;
    CameraPosition newCameraPosition = CameraPosition(
      target: pos,
      zoom: 13,
    );
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(newCameraPosition),
    );
  }
}
