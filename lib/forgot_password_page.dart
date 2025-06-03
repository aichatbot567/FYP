import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatelessWidget {
  final emailController = TextEditingController();

  ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 50,),
            Icon(Icons.lock_open,size: 100,color: Colors.red,),
            SizedBox(height: 20,),
            const Text(
              'Forgot your password?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your email below, and we\'ll send you a link to reset your password.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Email Field
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email),
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0), // Blue border when focused
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 1.5), // Blue border when not focused
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Send Email Button
        SizedBox(
          width: 200, height: 60,
            child: ElevatedButton(
              onPressed: () {
                final email = emailController.text.trim(); // Trimmed input
                ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Dismiss previous SnackBar

                if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid email address.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('A password reset link has been sent to $email'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  emailController.clear(); // Clear the text field
                }
              },

              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue, // Blue background color
                foregroundColor: Colors.white, // White text color
              ),
              child: const Text(
                'Send Reset Link',
                style: TextStyle(fontSize: 16),
              ),
            ),
        ),
          ],
        ),
      ),
    );
  }
}