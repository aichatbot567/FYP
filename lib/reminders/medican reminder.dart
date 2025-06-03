import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MedicineReminderScreen extends StatefulWidget {
  const MedicineReminderScreen({super.key});

  @override
  _MedicineReminderScreenState createState() => _MedicineReminderScreenState();
}

class _MedicineReminderScreenState extends State<MedicineReminderScreen> {
  final List<Medicine> _medicines = [];
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _setupNotificationListeners();
  }

  void _setupNotificationListeners() {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Allow Notifications'),
            content: const Text('Our app needs notification permission to remind you to take your medicines'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  AwesomeNotifications().requestPermissionToSendNotifications();
                  Navigator.pop(context);
                },
                child: const Text('Allow'),
              ),
            ],
          ),
        );
      }
    });
  }

  Future<void> _initializeApp() async {
    await _loadMedicines();
    setState(() => _isInitialized = true);
  }

  Future<void> _loadMedicines() async {
    _prefs = await SharedPreferences.getInstance();
    final medicinesJson = _prefs.getStringList('medicines') ?? [];

    setState(() {
      _medicines.clear();
      _medicines.addAll(medicinesJson.map((json) => Medicine.fromJson(json)));
    });

    await AwesomeNotifications().cancelAll();
    for (final medicine in _medicines) {
      await _scheduleNotifications(medicine);
    }
  }

  Future<void> _saveMedicines() async {
    await _prefs.setStringList(
        'medicines', _medicines.map((m) => m.toJson()).toList());
  }

  Future<void> _addReminder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddReminderScreen()),
    );

    if (result != null) {
      setState(() => _medicines.add(result));
      await _scheduleNotifications(result);
      await _saveMedicines();
    }
  }

  Future<void> _scheduleNotifications(Medicine medicine) async {
    for (final time in medicine.times) {
      for (final day in medicine.days) {
        final id = '${medicine.id}_${time.hashCode}_$day'.hashCode;

        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: id,
            channelKey: 'medicine_channel_id',
            title: 'Medicine Reminder',
            body: 'Take ${medicine.dosage} of ${medicine.name}',
            notificationLayout: NotificationLayout.Default,
            category: NotificationCategory.Reminder,
          ),
          schedule: NotificationCalendar(
            weekday: day,
            hour: time.time.hour,
            minute: time.time.minute,
            second: 0,
            millisecond: 0,
            repeats: true,
            preciseAlarm: true,
          ),
        );
      }
    }
  }

  Future<void> _deleteMedicine(int index) async {
    final medicine = _medicines[index];
    await _cancelNotifications(medicine);
    setState(() => _medicines.removeAt(index));
    await _saveMedicines();
  }

  Future<void> _cancelNotifications(Medicine medicine) async {
    for (final time in medicine.times) {
      for (final day in medicine.days) {
        final id = '${medicine.id}_${time.hashCode}_$day'.hashCode;
        await AwesomeNotifications().cancel(id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor:Color(0xFF4BA1AE),
        automaticallyImplyLeading: false,
          title: const Text('Medicine Reminder'),
          centerTitle: true,
          elevation: 0,
          titleTextStyle: const TextStyle(
            color: Colors.black54,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          )
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
        child: _medicines.isEmpty
            ? const Center(
          child: Text(
            'No reminders',
            style: TextStyle(fontSize: 18, color: Colors.black),
          ),
        )
            : ListView.builder(
          itemCount: _medicines.length,
          itemBuilder: (context, index) {
            final med = _medicines[index];
            return Dismissible(
              key: Key(med.id.toString()),
              onDismissed: (_) => _deleteMedicine(index),
              background: Container(color: Colors.red),
              child: Card(
                margin: const EdgeInsets.all(8),
                color: Colors.white.withOpacity(0.9), // Slightly transparent for contrast
                child: ListTile(
                  title: Text(med.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dosage: ${med.dosage}'),
                      Text(
                          'Times: ${med.times.map((t) => _formatTimeOfDay(t.time)).join(", ")}'),
                      Text(
                          'Days: ${med.days.map((d) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1]).join(", ")}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteMedicine(index),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        backgroundColor: const Color(0xff4ca1af), // Match gradient start color
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  _AddReminderScreenState createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final List<MedicationTime> _times = [MedicationTime(TimeOfDay.now())];
  final List<bool> _days = List.filled(7, false);
  final _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Future<void> _selectTime(int index) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _times[index].time,
    );
    if (time != null) {
      setState(() => _times[index] = MedicationTime(time));
    }
  }

  void _addTime() => setState(() => _times.add(MedicationTime(TimeOfDay.now())));
  void _removeTime(int index) {
    if (_times.length > 1) {
      setState(() => _times.removeAt(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor:Color(0xFF4BA1AE),
          automaticallyImplyLeading: false,
          title: const Text('Add Medicine'),
          centerTitle: true,
          elevation: 0,
          titleTextStyle: const TextStyle(
            color: Colors.black54,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          )
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Card( 
                  color: Color(0x90FFFFFF),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Medicine Name',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: Color(0x90FFFFFF),
                  child: TextFormField(
                    controller: _dosageController,
                    decoration: InputDecoration(
                      labelText: 'Dosage (e.g. 1 tablet)',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Times:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                ..._times.asMap().entries.map((e) => Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xCDFFFFFF),
                          foregroundColor: Colors.black87,
                        ),
                        child: Text(
                          _formatTimeOfDay(e.value.time),
                          style: const TextStyle(color: Colors.black87),
                        ),
                        onPressed: () => _selectTime(e.key),
                      ),
                    ),
                    if (_times.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.red),
                        onPressed: () => _removeTime(e.key),
                      ),
                  ],
                )),
                TextButton.icon(
                  icon: const Icon(Icons.add, color: Colors.black,size: 25,),
                  label: const Text(
                    'Add Time',
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: _addTime,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Days:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                Wrap(
                  children: _dayNames.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.all(4),
                    child: FilterChip(
                      label: Text(
                        _dayNames[e.key],
                        style: TextStyle(
                          color: _days[e.key] ? Colors.black87 : Color(
                              0xFF054045),
                        ),
                      ),
                      selected: _days[e.key],
                      backgroundColor: Color(0x28FFFFFF),
                      selectedColor: Colors.white.withOpacity(0.9),
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: Color(0xFF000000), // border color for both selected and unselected
                        ),
                      ),
                      onSelected: (v) => setState(() => _days[e.key] = v),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4ca1af),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Save Reminder'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (!_days.contains(true)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please select at least one day')),
                        );
                        return;
                      }

                      final selectedDays = <int>[];
                      for (int i = 0; i < _days.length; i++) {
                        if (_days[i]) selectedDays.add(i + 1);
                      }

                      Navigator.pop(
                        context,
                        Medicine(
                          id: DateTime.now().millisecondsSinceEpoch,
                          name: _nameController.text,
                          dosage: _dosageController.text,
                          times: List.from(_times),
                          days: selectedDays,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class Medicine {
  final int id;
  final String name;
  final String dosage;
  final List<MedicationTime> times;
  final List<int> days;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.times,
    required this.days,
  });

  factory Medicine.fromJson(String json) {
    final data = jsonDecode(json);
    return Medicine(
      id: data['id'],
      name: data['name'],
      dosage: data['dosage'],
      times: (data['times'] as List)
          .map((t) => MedicationTime.fromJson(t))
          .toList(),
      days: List<int>.from(data['days']),
    );
  }

  String toJson() => jsonEncode({
    'id': id,
    'name': name,
    'dosage': dosage,
    'times': times.map((t) => t.toJson()).toList(),
    'days': days,
  });
}

class MedicationTime {
  final TimeOfDay time;
  MedicationTime(this.time);

  factory MedicationTime.fromJson(Map<String, dynamic> json) =>
      MedicationTime(TimeOfDay(hour: json['hour'], minute: json['minute']));

  Map<String, dynamic> toJson() => {'hour': time.hour, 'minute': time.minute};
}