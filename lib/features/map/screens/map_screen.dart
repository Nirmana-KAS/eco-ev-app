import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:eco_ev_app/data/models/station_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  final List<StationModel> _stations = [
    StationModel(
      id: '1',
      name: "GreenCharge Colombo",
      latitude: 6.9271,
      longitude: 79.8612,
      address: "Colombo City Center",
      availablePorts: 3,
    ),
    StationModel(
      id: '2',
      name: "Eco Power Kandy",
      latitude: 7.2906,
      longitude: 80.6337,
      address: "Kandy Downtown",
      availablePorts: 2,
    ),
  ];

  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _setStationMarkers();
    _getUserLocation();
  }

  void _setStationMarkers() {
    for (final station in _stations) {
      _markers.add(
        Marker(
          markerId: MarkerId(station.id),
          position: LatLng(station.latitude, station.longitude),
          infoWindow: InfoWindow(
            title: station.name,
            snippet: '${station.availablePorts} ports • ${station.address}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }
    setState(() {});
  }

  Future<void> _getUserLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    locationData = await location.getLocation();

    setState(() {
      _currentLocation = LatLng(
        locationData.latitude ?? 7.0,
        locationData.longitude ?? 80.0,
      );
    });

    // Move camera to user's location if map is ready
    if (_mapController != null && _currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 14),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EV Charging Map')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentLocation ?? const LatLng(7.0, 80.0),
          zoom: 7.3,
        ),
        myLocationButtonEnabled: true,
        myLocationEnabled: true,
        onMapCreated: (controller) {
          _mapController = controller;
          if (_currentLocation != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(_currentLocation!, 14),
            );
          }
        },
        markers: _markers,
      ),
    );
  }
}
