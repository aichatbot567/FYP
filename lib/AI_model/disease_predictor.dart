import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DiseasePredictorScreen extends StatefulWidget {
  const DiseasePredictorScreen({super.key});

  @override
  _DiseasePredictorScreenState createState() => _DiseasePredictorScreenState();
}
class _DiseasePredictorScreenState extends State<DiseasePredictorScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>>? _predictions;
  List<String> _selectedSymptoms = [];
  Interpreter? _interpreter;
  List<String>? _symptoms;
  List<String>? _diseases;
  List<Map<String, dynamic>>? _descriptions;
  List<Map<String, dynamic>>? _precautions;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load TFLite model
      _interpreter = await Interpreter.fromAsset('assets/randomforest_model.tflite');
      print("Model loaded successfully");

      // Load symptoms
      final symptomData = await DefaultAssetBundle.of(context).loadString('assets/Symptom-severity.csv');
      final symptomList = const CsvToListConverter().convert(symptomData, eol: '\n');
      _symptoms = symptomList.skip(1).map((row) => row[0].toString().trim()).take(132).toList();
      if (_symptoms!.length != 132) {
        throw Exception('Expected 132 symptoms, got ${_symptoms!.length}');
      }

      // Load diseases
      final diseasesData = await DefaultAssetBundle.of(context).loadString('assets/diseases.txt');
      _diseases = diseasesData.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (_diseases!.length != 41) {
        throw Exception('Expected 41 diseases, got ${_diseases!.length}');
      }

      // Load descriptions and precautions
      _descriptions = await _loadCsvMap('assets/description.csv', 'Disease', ['Description']);
      _precautions = await _loadCsvMap('assets/precautions_df.csv', 'Disease', ['Precaution_1', 'Precaution_2', 'Precaution_3', 'Precaution_4']);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load data: $e';
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadCsvMap(String path, String keyColumn, List<String> valueColumns) async {
    final data = await DefaultAssetBundle.of(context).loadString(path);
    final list = const CsvToListConverter().convert(data, eol: '\n');
    final headers = list[0].map((e) => e.toString()).toList();
    return list.skip(1).map((row) {
      final map = <String, dynamic>{};
      for (var i = 0; i < headers.length; i++) {
        map[headers[i]] = row[i].toString();
      }
      return map;
    }).toList();
  }

  String? _correctSpelling(String symptom) {
    if (_symptoms == null) return null;
    String? bestMatch;
    int minDistance = 3; // Adjust threshold for similarity
    for (var s in _symptoms!) {
      final distance = _levenshtein(symptom.toLowerCase(), s.toLowerCase());
      if (distance < minDistance) {
        minDistance = distance;
        bestMatch = s;
      }
    }
    return minDistance <= 2 ? bestMatch : null;
  }

  int _levenshtein(String a, String b) {
    final n = a.length, m = b.length;
    final d = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    for (var i = 0; i <= n; i++) d[i][0] = i;
    for (var j = 0; j <= m; j++) d[0][j] = j;
    for (var i = 1; i <= n; i++) {
      for (var j = 1; j <= m; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1,
          d[i][j - 1] + 1,
          d[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return d[n][m];
  }

  Future<void> _predictDisease(List<String> symptoms) async {
    if (_interpreter == null || _symptoms == null || _diseases == null) {
      setState(() => _error = 'Model or data not loaded');
      return;
    }

    setState(() {
      _isLoading = true;
      _selectedSymptoms = symptoms;
    });

    try {
      // Prepare input: 1x132 binary vector
      final input = Float32List(132);
      for (var i = 0; i < 132; i++) input[i] = 0.0;
      for (var symptom in symptoms) {
        final idx = _symptoms!.indexOf(symptom);
        if (idx != -1) input[idx] = 1.0;
      }
      final inputTensor = input.reshape([1, 132]);

      // Check model output shape
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      print("Output tensor shape: $outputShape");

      if (outputShape.length == 2 && outputShape[1] == 41) {
        // Case 1: Model outputs probabilities for 41 classes
        final output = List.filled(1 * 41, 0.0).reshape([1, 41]);
        _interpreter!.run(inputTensor, output);
        print("Model raw output probabilities: ${output[0]}");

        final probs = output[0] as List<double>;
        final indexedProbs = probs.asMap().entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        _predictions = indexedProbs.take(3).map((entry) {
          final disease = _diseases![entry.key];
          return {
            'disease': disease,
            'probability': entry.value * 100,
            'description': _descriptions!.firstWhere(
                  (d) => d['Disease'] == disease,
              orElse: () => {'Description': 'No description available'},
            )['Description'],
            'precautions': _precautions!.firstWhere(
                  (p) => p['Disease'] == disease,
              orElse: () => {
                'Precaution_1': '',
                'Precaution_2': '',
                'Precaution_3': '',
                'Precaution_4': '',
              },
            ).values.skip(1).where((v) => v.isNotEmpty).toList(),
          };
        }).toList();
      } else if (outputShape.length == 1 || (outputShape.length == 2 && outputShape[1] == 1)) {
        // Case 2: Model outputs a single class index
        final output = Int32List(1).reshape([1]);
        _interpreter!.run(inputTensor, output);
        print("Model raw output index: ${output[0]}");

        final diseaseIndex = output[0];
        if (diseaseIndex < 0 || diseaseIndex >= _diseases!.length) {
          throw Exception('Invalid disease index: $diseaseIndex');
        }
        final disease = _diseases![diseaseIndex];
        _predictions = [
          {
            'disease': disease,
            'probability': 100.0,
            'description': _descriptions!.firstWhere(
                  (d) => d['Disease'] == disease,
              orElse: () => {'Description': 'No description available'},
            )['Description'],
            'precautions': _precautions!.firstWhere(
                  (p) => p['Disease'] == disease,
              orElse: () => {
                'Precaution_1': '',
                'Precaution_2': '',
                'Precaution_3': '',
                'Precaution_4': '',
              },
            ).values.skip(1).where((v) => v.isNotEmpty).toList(),
          }
        ];
      } else {
        throw Exception('Unexpected output shape: $outputShape');
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Prediction failed: $e';
      });
    }
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Prediction',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF4BA1AE),
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _selectedSymptoms = [];
                _predictions = null;
                _error = null;
              });
            },
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Container(
        height: MediaQuery.sizeOf(context).height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4BA1AE),
              Color(0xFF73B5C1),
              Color(0xFF82BDC8),
              Color(0xFF92C6CF),
            ],
            stops: [0.1, 0.4, 0.7, 1.0],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.black)))
            : _error != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _predictions = null;
                      _selectedSymptoms = [];
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        )
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)
                    ],
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                  ),
                  child: SymptomSelector(
                    symptoms: _symptoms!,
                    selectedSymptoms: _selectedSymptoms,
                    onSymptomsChanged: (symptoms) {
                      setState(() {
                        _selectedSymptoms = symptoms;
                      });
                    },
                    onPredictPressed: _predictDisease,
                    onCorrectSpelling: _correctSpelling,
                  ),
                ),
                if (_predictions != null) ...[
                  const SizedBox(height: 24),
                  const Text('Top Predictions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 2, color: Colors.black45, offset: Offset(1, 1))],
                      )),
                  const SizedBox(height: 16),
                  ..._predictions!.map((pred) => PredictionCard(prediction: pred)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SymptomSelector extends StatefulWidget {
  final List<String> symptoms;
  final List<String> selectedSymptoms;
  final Function(List<String>) onSymptomsChanged;
  final Function(List<String>) onPredictPressed;
  final String? Function(String) onCorrectSpelling;

  const SymptomSelector({
    super.key,
    required this.symptoms,
    required this.selectedSymptoms,
    required this.onSymptomsChanged,
    required this.onPredictPressed,
    required this.onCorrectSpelling,
  });

  @override
  _SymptomSelectorState createState() => _SymptomSelectorState();
}

class _SymptomSelectorState extends State<SymptomSelector> {
  String? _selectedSymptom;
  final TextEditingController _controller = TextEditingController();
  String? _suggestion;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Symptoms',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Type a symptom (e.g., headache)',
              hintStyle: TextStyle(color: Colors.black54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.black54),
            onChanged: (value) {
              setState(() {
                _suggestion = widget.onCorrectSpelling(value);
              });
            },
            onSubmitted: (value) {
              final corrected = widget.onCorrectSpelling(value);
              if (corrected != null && !widget.selectedSymptoms.contains(corrected)) {
                widget.onSymptomsChanged([...widget.selectedSymptoms, corrected]);
                _controller.clear();
                setState(() => _suggestion = null);
              }
            },
          ),
          if (_suggestion != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Did you mean: $_suggestion?',
                style: const TextStyle(color: Colors.yellow, fontSize: 14),
              ),
            ),
          const SizedBox(height: 16),
          DropdownButton<String>(
            isExpanded: true,
            hint: const Text('Or select a symptom', style: TextStyle(color: Colors.black)),
            value: _selectedSymptom,
            dropdownColor: const Color(0xEF095961),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
            iconSize: 24,
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            underline: Container(height: 0),
            onChanged: (String? newValue) {
              setState(() {
                _selectedSymptom = newValue;
                if (newValue != null && !widget.selectedSymptoms.contains(newValue)) {
                  widget.onSymptomsChanged([...widget.selectedSymptoms, newValue]);
                }
                _selectedSymptom = null;
              });
            },
            items: widget.symptoms.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          if (widget.selectedSymptoms.isNotEmpty) ...[
            const Text('Selected Symptoms:',
                style: TextStyle(color: Colors.black, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.selectedSymptoms.map((symptom) {
                return Chip(
                  label: Text(symptom),
                  backgroundColor: const Color(0xFF4BA1AE),
                  labelStyle: const TextStyle(color: Colors.black54),
                  deleteIcon: const Icon(Icons.close, size: 18, color: Colors.black54),
                  onDeleted: () {
                    widget.onSymptomsChanged(
                        widget.selectedSymptoms.where((item) => item != symptom).toList());
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.selectedSymptoms.isEmpty
                  ? null
                  : () => widget.onPredictPressed(widget.selectedSymptoms),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4BA1AE),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
              ),
              child: const Text('Predict Disease',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class PredictionCard extends StatelessWidget {
  final Map<String, dynamic> prediction;

  const PredictionCard({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, spreadRadius: 1)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    prediction['disease'],
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF255960),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${prediction['probability'].toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              prediction['description'],
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Recommended Precautions:',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (prediction['precautions'].isEmpty)
              const Text('No specific precautions available', style: TextStyle(color: Colors.black87))
            else
              ...prediction['precautions'].map(
                    (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Colors.black87)),
                      Expanded(child: Text(p, style: const TextStyle(color: Colors.black87))),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

