import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';


class JobRouteScreen extends StatefulWidget {
  const JobRouteScreen({Key? key}) : super(key: key);

  @override
  State<JobRouteScreen> createState() => _JobRouteScreenState();
}

class _JobRouteScreenState extends State<JobRouteScreen> {
  GoogleMapController? _mapController;

  LatLng? _currentLocation;
  late final List<LatLng> _pickups;
  final LatLng _warehouseLocation = const LatLng(12.961115, 77.600000);

  final Set<Marker> _markers = <Marker>{};

  final Set<Polyline> _polylines = <Polyline>{};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  // Step 1: mock current location & generate pickups
  Future<void> _initData() async {
    final mockLoc = const LatLng(12.971598, 77.594566); // Bengaluru

    _pickups = _generateMockPickups(mockLoc); // Generate 5 pickups
    setState(() {
      _currentLocation = mockLoc;
      _addMarkers();
      _buildPolyline();
    });
  }

  // Step 2: 5 random points within 5km
  List<LatLng> _generateMockPickups(LatLng origin, {double radiusKm = 5}) {
    final rnd = Random();
    const degPerKm = 1 / 111.0;
    return List.generate(5, (_) {
      final angle = rnd.nextDouble() * 2 * pi;
      final dist = rnd.nextDouble() * radiusKm;
      final dx = dist * cos(angle) * degPerKm;
      final dy = dist * sin(angle) * degPerKm;
      return LatLng(origin.latitude + dy, origin.longitude + dx);
    });
  }

  // Step 3: Add markers
  void _addMarkers() {
    if (_currentLocation == null) return;

    // Rider marker
    _markers.add(Marker(
      markerId: const MarkerId('rider'),
      position: _currentLocation!,
      infoWindow: const InfoWindow(title: 'Warehouse'),
    ));

    // Pickup markers
    for (var i = 0; i < _pickups.length; i++) {
      _markers.add(Marker(
        markerId: MarkerId('pickup_$i'),
        position: _pickups[i],
        infoWindow: InfoWindow(title: 'Pickup ${i + 1}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }

    // Warehouse marker
    _markers.add(Marker(
      markerId: const MarkerId('warehouse'),
      position: _warehouseLocation,
      infoWindow: const InfoWindow(title: 'Warehouse'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ));
  }

  void _buildPolyline() {
    if (_currentLocation == null) return;

    final List<LatLng> points = [
      _currentLocation!,
      ..._pickups.map((p) => p),
      _warehouseLocation,
    ];

    _polylines.add(Polyline(
      polylineId: const PolylineId('job_route'),
      points: points,
      color: Colors.blue,
      width: 4,
    ));
  }


  Future<void> _launchNavigation() async {
    if (_currentLocation == null) return;

    final waypoints = _pickups
        .map((p) => '${p.latitude},${p.longitude}')
        .join('|');

    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
            '&origin=${_currentLocation!.latitude},${_currentLocation!.longitude}'
            '&destination=${_warehouseLocation.latitude},${_warehouseLocation.longitude}'
            '&waypoints=$waypoints'
            '&travelmode=driving');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch Google Maps')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_currentLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Job Route')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _launchNavigation,
        label: const Text('Navigate'),
        icon: const Icon(Icons.navigation),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentLocation!,
          zoom: 13,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _markers,
        zoomControlsEnabled: true,
        polylines: _polylines
      ),
    );
  }
}
