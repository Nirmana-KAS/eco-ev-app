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
  Set<Marker> _markers = {};

  final List<StationModel> _stations = [
    StationModel(
      id: '1',
      name: "GreenCharge Colombo",
      owner: "ABC Green Pvt Ltd",
      address: "Colombo City Center",
      latitude: 6.9271,
      longitude: 79.8612,
      contactNumber: "0771234567",
      gmail: "greencharge.colombo@gmail.com",
      slots2x: 5,
      slots1x: 3,
      openingHours: "8:00 AM - 6:00 PM",
      pricePerHour: 500,
      logoUrl: "",
    ),
    StationModel(
      id: '2',
      name: "Eco Power Kandy",
      owner: "Eco Power (Pvt) Ltd",
      address: "Kandy Downtown",
      latitude: 7.2906,
      longitude: 80.6337,
      contactNumber: "0719876543",
      gmail: "eco.kandy@gmail.com",
      slots2x: 4,
      slots1x: 2,
      openingHours: "7:30 AM - 7:00 PM",
      pricePerHour: 450,
      logoUrl: "",
    ),
  ];

  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _setStationMarkers();
  }

  void _setStationMarkers() {
    Set<Marker> markers = {};
    for (final station in _stations) {
      markers.add(
        Marker(
          markerId: MarkerId(station.id),
          position: LatLng(station.latitude, station.longitude),
          infoWindow: InfoWindow(
            title: station.name,
            snippet:
                '${station.slots2x + station.slots1x} ports • ${station.address}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }
    setState(() {
      _markers = markers;
    });
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

    if (!mounted) return;
    setState(() {
      _currentLocation = LatLng(
        locationData.latitude ?? 7.0,
        locationData.longitude ?? 80.0,
      );
    });

    if (_mapController != null && _currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 14),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EV Charging Map')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentLocation ?? const LatLng(7.0, 80.0),
          zoom: _currentLocation == null ? 7.3 : 14,
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
