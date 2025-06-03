import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class Pharmacy {
  final int id;
  final String name;
  final String address;
  final List<String> openHours;
  final String contact;
  final String email;
  final Location location;
  final bool isOpen24Hours;
  final List<String> services;

  Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.openHours,
    required this.contact,
    required this.email,
    required this.location,
    required this.isOpen24Hours,
    required this.services,
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    // Map the JSON structure to match our model
    List<String> operatingHours = List<String>.from(json['operating_hours'] ?? []);
    bool is24Hours = operatingHours.any((hour) => hour.contains('24/7'));

    return Pharmacy(
      id: json['id'],
      name: json['name'],
      address: json['hospital'] ?? 'Address not specified', // Use hospital field as address
      openHours: operatingHours,
      contact: json['contact'],
      email: json['email'] ?? '',
      location: Location.fromJson(json['location']),
      isOpen24Hours: is24Hours,
      services: List<String>.from(json['services'] ?? []),
    );
  }

  String get googleMapsUrl {
    return "https://www.google.com/maps/search/?api=1&query=${location.lat},${location.lng}";
  }

  bool get isOpenNow {
    if (isOpen24Hours) return true;

    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    for (String hours in openHours) {
      if (hours.contains('-') && !hours.contains('24/7')) {
        // Parse time ranges like "08:00-22:00"
        final parts = hours.split('-');
        if (parts.length == 2) {
          try {
            final openTimeParts = parts[0].trim().split(':');
            final closeTimeParts = parts[1].trim().split(':');

            final openHour = int.parse(openTimeParts[0]);
            final openMin = int.parse(openTimeParts[1]);
            final closeHour = int.parse(closeTimeParts[0]);
            final closeMin = int.parse(closeTimeParts[1]);

            final currentTotalMinutes = currentHour * 60 + currentMinute;
            final openTotalMinutes = openHour * 60 + openMin;
            final closeTotalMinutes = closeHour * 60 + closeMin;

            if (currentTotalMinutes >= openTotalMinutes && currentTotalMinutes <= closeTotalMinutes) {
              return true;
            }
          } catch (e) {
            // If parsing fails, continue to next time slot
            continue;
          }
        }
      }
    }
    return false;
  }
}

// Location Model
class Location {
  final double lat;
  final double lng;

  Location({required this.lat, required this.lng});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: json['lat'].toDouble(),
      lng: json['lng'].toDouble(),
    );
  }
}

class PharmacyService {
  static Future<List<Pharmacy>> loadPharmacies() async {
    try {
      final String response = await rootBundle.loadString('assets/pharmacy.json');
      final data = await json.decode(response);
      return List<Pharmacy>.from(data['pharmacies'].map((x) => Pharmacy.fromJson(x)));
    } catch (e) {
      print("Error loading pharmacies: $e");
      return [];
    }
  }
}

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  List<Pharmacy> pharmacies = [];
  List<Pharmacy> filteredPharmacies = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPharmacies() async {
    final loadedPharmacies = await PharmacyService.loadPharmacies();
    setState(() {
      pharmacies = loadedPharmacies;
      filteredPharmacies = loadedPharmacies;
      isLoading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredPharmacies = query.isEmpty
          ? pharmacies
          : pharmacies.where((pharmacy) {
        return pharmacy.name.toLowerCase().contains(query) ||
            pharmacy.address.toLowerCase().contains(query) ||
            pharmacy.services.any((service) => service.toLowerCase().contains(query));
      }).toList();
    });
  }

  Future<void> _openMap(Pharmacy pharmacy) async {
    final Uri uri = Uri.parse(pharmacy.googleMapsUrl);
    await _launchUri(uri, 'Could not launch map');
  }

  Future<void> _callPharmacy(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final Uri uri = Uri.parse('tel:$cleanPhone');
    await _launchUri(uri, 'Could not launch phone app');
  }

  Future<void> _sendEmail(String email) async {
    final Uri uri = Uri.parse('mailto:$email');
    await _launchUri(uri, 'Could not launch email app');
  }

  Future<void> _launchUri(Uri uri, String errorMessage) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _showError(errorMessage);
      }
    } catch (e) {
      _showError('$errorMessage: $e');
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
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by pharmacy name, address or services...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.black54),
            filled: true,
            fillColor: Color(0x90FFFFFF),
          ),
          style: const TextStyle(color: Colors.black87),
        )
            : const Text('Pharmacies'),
        backgroundColor: const Color(0xFF4BA1AE),
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  filteredPharmacies = pharmacies;
                }
              });
            },
          ),
        ],
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4BA1AE),
              Color(0xFF73B5C1),
              Color(0xFF82BDC8),
              Color(0xFF92C6CF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : filteredPharmacies.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 50, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  _searchController.text.isEmpty
                      ? 'No pharmacies available'
                      : 'No results found',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          )
              : ListView.builder(
            itemCount: filteredPharmacies.length,
            itemBuilder: (context, index) {
              final pharmacy = filteredPharmacies[index];
              return Card(
                margin: const EdgeInsets.all(8),
                color: const Color(0x90FFFFFF),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              pharmacy.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: pharmacy.isOpen24Hours
                                  ? Colors.blue.withOpacity(0.2)
                                  : pharmacy.isOpenNow
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: pharmacy.isOpen24Hours
                                    ? Colors.blue
                                    : pharmacy.isOpenNow
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            child: Text(
                              pharmacy.isOpen24Hours
                                  ? '24/7 Open'
                                  : pharmacy.isOpenNow
                                  ? 'Open Now'
                                  : 'Closed',
                              style: TextStyle(
                                color: pharmacy.isOpen24Hours
                                    ? Colors.blue
                                    : pharmacy.isOpenNow
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pharmacy.address,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!pharmacy.isOpen24Hours && pharmacy.openHours.isNotEmpty)
                        Text(
                          'Hours: ${pharmacy.openHours.join(", ")}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      if (pharmacy.services.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: pharmacy.services
                              .take(3) // Limit to first 3 services to avoid overflow
                              .map((service) => Chip(
                            label: Text(
                              service,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.blue[50],
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ))
                              .toList(),
                        ),
                      ],
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.map, color: Colors.blue),
                            onPressed: () => _openMap(pharmacy),
                            tooltip: 'Open in Maps',
                          ),
                          IconButton(
                            icon: const Icon(Icons.phone, color: Colors.green),
                            onPressed: () => _callPharmacy(pharmacy.contact),
                            tooltip: 'Call Pharmacy',
                          ),
                          if (pharmacy.email.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.email, color: Colors.orange),
                              onPressed: () => _sendEmail(pharmacy.email),
                              tooltip: 'Send Email',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}