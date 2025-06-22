import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' show asin, cos, sqrt, pi, sin;

class Hospital {
  final String id;
  final String name;
  final String phoneNumber;
  final double latitude;
  final double longitude;
  double? distanceFromUser;

  Hospital({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.latitude,
    required this.longitude,
    this.distanceFromUser,
  });
}

class Near_hosiptal extends StatefulWidget {
  const Near_hosiptal({super.key});
  @override
  State<Near_hosiptal> createState() => _Near_hosiptalState();
}

class _Near_hosiptalState extends State<Near_hosiptal> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  List<Hospital> _hospitals = [];
  Hospital? _nearestHospital;
  bool _isLoadingLocation = true;
  bool _locationGranted = false;

  // Default map center - will be updated when location is obtained
  final LatLng _defaultLocation = const LatLng(37.4219999, -122.0840575);

  @override
  void initState() {
    super.initState();
    // Start location permission process after map is displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermission();
    });
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Location services are disabled.');
      setState(() {
        _isLoadingLocation = false;
        _locationGranted = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Location permission denied');
        setState(() {
          _isLoadingLocation = false;
          _locationGranted = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showError('Location permissions permanently denied.');
      setState(() {
        _isLoadingLocation = false;
        _locationGranted = false;
      });
      return;
    }

    setState(() {
      _locationGranted = true;
    });

    // Now that we have permission, get current location
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // Update map camera position
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }

      // Add a marker for current position
      _addCurrentLocationMarker();

      // Now that we have the location, load hospitals and calculate distances
      _loadDummyHospitals();
    } catch (e) {
      _showError('Failed to get current location: $e');
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _addCurrentLocationMarker() {
    if (_currentPosition == null) return;

    final currentLocationMarker = Marker(
      markerId: const MarkerId('currentLocation'),
      position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      infoWindow: const InfoWindow(title: 'Your Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );

    setState(() {
      _markers.add(currentLocationMarker);
    });
  }

  void _loadDummyHospitals() {
    if (_currentPosition == null) return;

    final dummyHospitals = [
      Hospital(
        id: '1',
        name: 'Shifa International Hospital',
        phoneNumber: '+923019806628',
        latitude: 33.6781,
        longitude: 73.0682,
      ),
      Hospital(
        id: '2',
        name: 'Pakistan Institute of Medical Sciences (PIMS)',
        phoneNumber: '+923019806628',
        latitude: 33.6996,
        longitude: 73.0545,
      ),
      Hospital(
        id: '3',
        name: 'Capital Hospital (CDA Hospital)',
        phoneNumber: '+923019806628',
        latitude: 33.7141,
        longitude: 73.0676,
      ),
      Hospital(
        id: '4',
        name: 'Maroof International Hospital',
        phoneNumber: '+923019806628',
        latitude: 33.6978,
        longitude: 73.0293,
      ),
      Hospital(
        id: '5',
        name: 'Advanced International Hospital',
        phoneNumber: '+923019806628',
        latitude: 33.6844,
        longitude: 73.0479,
      ),
    ];
    // Calculate distances for each hospital
    _calculateHospitalDistances(dummyHospitals);
  }

  void _calculateHospitalDistances(List<Hospital> hospitals) {
    if (_currentPosition == null) return;

    for (var hospital in hospitals) {
      hospital.distanceFromUser = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        hospital.latitude,
        hospital.longitude,
      );
    }

    // Sort hospitals by distance
    hospitals.sort((a, b) =>
        (a.distanceFromUser ?? double.infinity)
            .compareTo(b.distanceFromUser ?? double.infinity));

    // After calculating distances, add hospital markers and update UI
    _updateHospitalsUI(hospitals);
  }

  void _updateHospitalsUI(List<Hospital> hospitals) {
    final nearestHospital = hospitals.isNotEmpty ? hospitals.first : null;

    final hospitalMarkers = hospitals.map((hospital) {
      bool isNearest = hospital.id == nearestHospital?.id;
      return Marker(
        markerId: MarkerId(hospital.id),
        position: LatLng(hospital.latitude, hospital.longitude),
        infoWindow: InfoWindow(
          title: hospital.name,
          snippet: '${hospital.distanceFromUser?.toStringAsFixed(2)} km • ${hospital.phoneNumber}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isNearest ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
      );
    }).toSet();

    setState(() {
      _hospitals = hospitals;
      _markers.addAll(hospitalMarkers);
      _nearestHospital = nearestHospital;
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  Future<void> _callHospital(String phoneNumber) async {
    if (_currentPosition == null) {
      _showError('Current location not available');
      return;
    }

    try {
      // Remove all non-numeric characters from phone number
      final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

      // Create a Google Maps link with the user's current location
      final locationUrl = 'https://www.google.com/maps/search/?api=1&query=${_currentPosition!.latitude},${_currentPosition!.longitude}';

      // Create the message to send
      final message = Uri.encodeComponent(
        'Emergency: Please send an ambulance to my location: $locationUrl',
      );

      // Create WhatsApp URL
      final Uri whatsappUri = Uri.parse('https://wa.me/$cleanedNumber?text=$message');

      // Launch WhatsApp with the pre-filled message
      await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      _showError('Failed to open WhatsApp: $e');
    }
  }
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4BA1AE),

      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null
                        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                        : _defaultLocation,
                    zoom: 14.0,
                  ),
                  markers: _markers,
                  myLocationEnabled: _locationGranted,
                  myLocationButtonEnabled: _locationGranted,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  mapType: MapType.normal,
                ),

                // Show loading indicator for location on top of map
                if (_isLoadingLocation)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Getting location...'),
                        ],
                      ),
                    ),
                  ),

                // Show permission request if needed
                if (!_locationGranted && !_isLoadingLocation)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Location permission is required to find nearby hospitals.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _checkLocationPermission,
                            child: const Text('Grant Permission'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Nearest Hospital info panel
          if (_nearestHospital != null)
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Theme.of(context).cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nearest Hospital',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nearestHospital!.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_nearestHospital!.distanceFromUser?.toStringAsFixed(2)} km away',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _callHospital(_nearestHospital!.phoneNumber),
                        icon: const Icon(Icons.message),
                        label: const Text('Contact Ambulance'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}