import 'dart:math';

import 'package:flutter/material.dart';

class BMICalculatorScreen extends StatefulWidget {
  const BMICalculatorScreen({Key? key}) : super(key: key);

  @override
  _BMICalculatorScreenState createState() => _BMICalculatorScreenState();
}

class _BMICalculatorScreenState extends State<BMICalculatorScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightMetersController = TextEditingController();
  final TextEditingController _heightCmController = TextEditingController();
  final TextEditingController _heightFeetController = TextEditingController();
  final TextEditingController _heightInchesController = TextEditingController();
  double _bmi = 0.0;
  String _bmiCategory = '';
  String _heightUnit = 'Meters'; // Default height unit
  String _weightUnit = 'Kilograms'; // Default weight unit
  List<int> _wellnessData = [20, 15, 10]; // Placeholder data: Physical Health, Mental Health, Sleep Hours

  void _calculateBMI() {
    double weightInKg = 0.0;
    double heightInMeters = 0.0;

    // Convert weight to kilograms
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    if (_weightUnit == 'Kilograms') {
      weightInKg = weight;
    } else {
      weightInKg = weight * 0.453592; // Convert pounds to kilograms
    }

    // Convert height to meters
    if (_heightUnit == 'Meters') {
      heightInMeters = double.tryParse(_heightMetersController.text) ?? 0.0;
    } else if (_heightUnit == 'Centimeters') {
      final heightCm = double.tryParse(_heightCmController.text) ?? 0.0;
      heightInMeters = heightCm * 0.01; // Convert centimeters to meters
    } else {
      final feet = double.tryParse(_heightFeetController.text) ?? 0.0;
      final inches = double.tryParse(_heightInchesController.text) ?? 0.0;
      heightInMeters = (feet * 0.3048) + (inches * 0.0254); // Convert feet and inches to meters
    }

    if (weightInKg > 0 && heightInMeters > 0) {
      final bmi = weightInKg / (heightInMeters * heightInMeters);
      setState(() {
        _bmi = double.parse(bmi.toStringAsFixed(1));
        _bmiCategory = _getBMICategory(_bmi);
      });
    }
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi >= 18.5 && bmi < 25) return 'Healthy';
    if (bmi >= 25 && bmi < 30) return 'Overweight';
    return 'Obese';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4BA1AE),
      ),
      body: Container(
        height: MediaQuery.sizeOf(context).height,
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'BMI Calculator',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF4BA1AE),
                        Color(0xBD3D7175),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.monitor_weight_outlined, size: 100),
                        const SizedBox(height: 20),
                        DropdownButton<String>(
                          value: _weightUnit,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF4BA1AE),
                          items: ['Kilograms', 'Pounds'].map((String unit) {
                            return DropdownMenuItem<String>(
                              value: unit,
                              child: Text(
                                unit,
                                style: const TextStyle(color: Colors.black),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _weightUnit = newValue!;
                              _weightController.clear();
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _weightController,
                          decoration: InputDecoration(
                            labelText: 'Weight (${_weightUnit.toLowerCase()})',
                            labelStyle: const TextStyle(color: Colors.black54),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          style: const TextStyle(color: Colors.black54),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 10),
                        DropdownButton<String>(
                          value: _heightUnit,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF4BA1AE),
                          items: ['Meters', 'Centimeters', 'Feet & Inches'].map((String unit) {
                            return DropdownMenuItem<String>(
                              value: unit,
                              child: Text(
                                unit,
                                style: const TextStyle(color: Colors.black),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _heightUnit = newValue!;
                              // Clear height fields when unit changes
                              _heightMetersController.clear();
                              _heightCmController.clear();
                              _heightFeetController.clear();
                              _heightInchesController.clear();
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        if (_heightUnit == 'Meters')
                          TextField(
                            controller: _heightMetersController,
                            decoration: InputDecoration(
                              labelText: 'Height (m)',
                              labelStyle: const TextStyle(color: Colors.black54),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            style: const TextStyle(color: Colors.black54),
                            keyboardType: TextInputType.number,
                          ),
                        if (_heightUnit == 'Centimeters')
                          TextField(
                            controller: _heightCmController,
                            decoration: InputDecoration(
                              labelText: 'Height (cm)',
                              labelStyle: const TextStyle(color: Colors.black54),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            style: const TextStyle(color: Colors.black54),
                            keyboardType: TextInputType.number,
                          ),
                        if (_heightUnit == 'Feet & Inches') ...[
                          TextField(
                            controller: _heightFeetController,
                            decoration: InputDecoration(
                              labelText: 'Height (feet)',
                              labelStyle: const TextStyle(color: Colors.black54),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            style: const TextStyle(color: Colors.black54),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _heightInchesController,
                            decoration: InputDecoration(
                              labelText: 'Height (inches)',
                              labelStyle: const TextStyle(color: Colors.black54),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            style: const TextStyle(color: Colors.black54),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _calculateBMI,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF184542),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text('Calculate BMI'),
                        ),
                        const SizedBox(height: 20),
                        if (_bmi > 0)
                          Column(
                            children: [
                              Text(
                                'Your BMI: $_bmi',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Category: $_bmiCategory',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}