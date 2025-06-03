import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class FirstAidItem {
  final String tag;
  final List<String> patterns;
  final List<String> responses;

  FirstAidItem({
    required this.tag,
    required this.patterns,
    required this.responses,
  });

  factory FirstAidItem.fromJson(Map<String, dynamic> json) {
    return FirstAidItem(
      tag: json['tag'] ?? 'Untitled',
      patterns: List<String>.from(json['patterns'] ?? []),
      responses: List<String>.from(json['responses'] ?? ['No information available']),
    );
  }
}

class FirstAidHome extends StatefulWidget {
  @override
  _FirstAidHomeState createState() => _FirstAidHomeState();
}

class _FirstAidHomeState extends State<FirstAidHome> {
  List<FirstAidItem> _firstAidItems = [];
  bool _isLoading = true;
  final String emergencyNumber = '1122'; // Updated to Pakistan's emergency number

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final String response = await rootBundle.loadString('assets/intents.json');
      final data = await json.decode(response);
      final items = (data['intents'] as List?) ?? [];

      setState(() {
        _firstAidItems = items.map((item) => FirstAidItem.fromJson(item)).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<String> get _categories {
    return ['Injuries', 'Medical', 'Bites', 'Environmental', 'Emergency'];
  }

  List<FirstAidItem> _getByCategory(String category) {
    final categoryMap = {
      'Injuries': ['Cuts', 'Abrasions', 'Sprains', 'Strains', 'Fracture', 'Wound', 'Bruises', 'Pulled Muscle'],
      'Medical': ['Fever', 'Headache', 'Cold', 'Diarrhea', 'Vertigo', 'Nasal Congestion', 'Cough', 'Sore Throat'],
      'Bites': ['Insect Bites', 'Stings', 'snake bite', 'animal bite'],
      'Environmental': ['Heat Stroke', 'Frost bite', 'Sun Burn', 'Heat Exhaustion'],
      'Emergency': ['CPR', 'Choking', 'Drowning', 'seizure', 'Fainting'],
    };

    final categoryTags = categoryMap[category] ?? [];
    return _firstAidItems.where((item) => categoryTags.contains(item.tag)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-AID'),
        centerTitle: true,
        backgroundColor:Color(0xFF4BA1AE),
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black54,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        automaticallyImplyLeading: false,
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : ListView(
          children: _categories.map((category) {
            final items = _getByCategory(category);
            if (items.isEmpty) return const SizedBox();
            return _buildCategoryCard(context, category, items);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
      BuildContext context, String category, List<FirstAidItem> items) {
    return Card(
      margin: const EdgeInsets.all(8),
      color: Color(0x90FFFFFF),
      elevation: 5,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryScreen(
                category: category,
                items: items,
                emergencyNumber: emergencyNumber,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _getCategoryIcon(category),
              const SizedBox(width: 16),
              Text(
                category,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    switch (category) {
      case 'Injuries':
        return const Icon(Icons.healing, size: 36, color: Colors.red);
      case 'Medical':
        return const Icon(Icons.medical_services, size: 36, color: Colors.blue);
      case 'Bites':
        return const Icon(Icons.bug_report, size: 36, color: Colors.green);
      case 'Environmental':
        return const Icon(Icons.wb_sunny, size: 36, color: Colors.orange);
      case 'Emergency':
        return const Icon(Icons.warning, size: 36, color: Colors.red);
      default:
        return const Icon(Icons.help, size: 36, color: Colors.grey);
    }
  }
}

class CategoryScreen extends StatelessWidget {
  final String category;
  final List<FirstAidItem> items;
  final String emergencyNumber;

  const CategoryScreen({
    required this.category,
    required this.items,
    required this.emergencyNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category),
        backgroundColor:Color(0xFF4BA1AE),
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black54,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
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
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Color(0x90FFFFFF),
              child: ListTile(
                title: Text(
                  item.tag,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(
                        item: item,
                        emergencyNumber: emergencyNumber,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  final FirstAidItem item;
  final String emergencyNumber;

  const DetailScreen({
    required this.item,
    required this.emergencyNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item.tag),
        backgroundColor:Color(0xFF4BA1AE),
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black54,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.responses.isNotEmpty)
                ...item.responses.map(
                      (response) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      response,
                      textAlign: TextAlign.justify,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              if (['CPR', 'Choking', 'Drowning', 'seizure', 'Fainting']
                  .contains(item.tag))
                _buildEmergencySection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencySection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Emergency Protocol',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Call emergency services immediately while performing these steps.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.phone, size: 24, color: Colors.white),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'CALL $emergencyNumber',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final Uri phoneUri = Uri.parse('tel:$emergencyNumber');
                launchUrl(phoneUri, mode: LaunchMode.externalApplication);
              },
            ),
          ),
        ],
      ),
    );
  }
}