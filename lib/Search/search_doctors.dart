import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// Doctor Model
class Doctor {
  final int id;
  final String name;
  final String specialization;
  final String hospital;
  final List<String> availability;
  final List<String> appointmentTimes;
  final String contact;
  final String email;
  final Location location;

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.hospital,
    required this.availability,
    required this.appointmentTimes,
    required this.contact,
    required this.email,
    required this.location,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      name: json['name'],
      specialization: json['specialization'],
      hospital: json['hospital'],
      availability: List<String>.from(json['availability']),
      appointmentTimes: List<String>.from(json['appointment_times']),
      contact: json['contact'],
      email: json['email'],
      location: Location.fromJson(json['location']),
    );
  }

  String get googleMapsUrl {
    return "https://www.google.com/maps/search/?api=1&query=${location.lat},${location.lng}";
  }

  bool get isAvailableToday {
    final today = DateTime.now().weekday;
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final todayName = dayNames[today - 1];
    return availability.contains(todayName);
  }
}

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

// Doctor Service
class DoctorService {
  static Future<List<Doctor>> loadDoctors() async {
    try {
      final String response = await rootBundle.loadString('assets/doctors.json');
      final data = await json.decode(response);
      return List<Doctor>.from(data['doctors'].map((x) => Doctor.fromJson(x)));
    } catch (e) {
      print("Error loading doctors: $e");
      return [];
    }
  }
}
// Doctors Screen
class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  List<Doctor> doctors = [];
  List<Doctor> filteredDoctors = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    final loadedDoctors = await DoctorService.loadDoctors();
    setState(() {
      doctors = loadedDoctors;
      filteredDoctors = loadedDoctors;
      isLoading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredDoctors = query.isEmpty
          ? doctors
          : doctors.where((doctor) {
        return doctor.name.toLowerCase().contains(query) ||
            doctor.hospital.toLowerCase().contains(query) ||
            doctor.specialization.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _openMap(Doctor doctor) async {
    final Uri uri = Uri.parse(doctor.googleMapsUrl);
    await _launchUri(uri, 'Could not launch map');
  }

  Future<void> _callDoctor(String phoneNumber) async {
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

  String _getCurrentWeekday() {
    final today = DateTime.now().weekday;
    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return dayNames[today - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search by doctor, hospital or specialty...',
            border: InputBorder.none,
            hintStyle: const TextStyle(color: Colors.black54),
            filled: true,
            fillColor: Color(0x90FFFFFF),
          ),
          style: const TextStyle(color: Colors.black87),
        )
            : const Text('Doctors'),
        backgroundColor: Color(0xFF4BA1AE),
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
                  filteredDoctors = doctors;
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
              : filteredDoctors.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 50, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  _searchController.text.isEmpty
                      ? 'No doctors available'
                      : 'No results found',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          )
              : ListView.builder(
            itemCount: filteredDoctors.length,
            itemBuilder: (context, index) {
              final doctor = filteredDoctors[index];
              return Card(
                margin: const EdgeInsets.all(8),
                color: Color(0x90FFFFFF),
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
                              doctor.name,
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
                              color: doctor.isAvailableToday
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: doctor.isAvailableToday
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            child: Text(
                              doctor.isAvailableToday
                                  ? 'Available Today'
                                  : 'Not Available',
                              style: TextStyle(
                                color: doctor.isAvailableToday
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
                        doctor.specialization,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor.hospital,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: doctor.availability
                            .map((day) => Chip(
                          label: Text(day),
                          backgroundColor: day == _getCurrentWeekday()
                              ? Colors.blue[100]
                              : Colors.grey[200],
                        ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hours: ${doctor.appointmentTimes.join(", ")}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.map, color: Colors.blue),
                            onPressed: () => _openMap(doctor),
                            tooltip: 'Open in Maps',
                          ),
                          IconButton(
                            icon: const Icon(Icons.phone, color: Colors.green),
                            onPressed: () => _callDoctor(doctor.contact),
                            tooltip: 'Call Doctor',
                          ),
                          if (doctor.email.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.email, color: Colors.orange),
                              onPressed: () => _sendEmail(doctor.email),
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