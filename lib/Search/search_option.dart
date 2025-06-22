import 'package:digitalhealthcareplatform/Search/search_doctors.dart';
import 'package:flutter/material.dart';
import 'package:arc_text/arc_text.dart';  // Add this import
import 'Pharmacy_search.dart';

class OptionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4BA1AE),
      ),
      body: Container(
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
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 90,
                    backgroundImage: AssetImage('assets/DHCP.png'),
                    backgroundColor: Colors.transparent,
                  ),
                  // Curved Text on top
                  Positioned(
                    top: 80,  // Adjust position as needed
                    child: ArcText(
                      radius: 90,
                      text: 'Digital Healthcare Platform',
                      textStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 6,
                            color: Colors.black,
                            offset: Offset(3, -4),
                          ),
                        ],
                      ),
                      startAngle: 5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 70),
              _buildOptionButton(
                context,
                'Doctors',
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DoctorsScreen()),
                  );
                },
              ),
              SizedBox(height: 20),
              _buildOptionButton(
                context,
                'Pharmacy',
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PharmacyScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(BuildContext context, String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF4BA1AE),
          foregroundColor: Color(0xFF184542),
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}