import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';

class MockChapaScreen extends StatelessWidget {
  final double amount;
  final String txRef;

  const MockChapaScreen({super.key, required this.amount, required this.txRef});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chapa Checkout (Simulation)'),
        backgroundColor: const Color(0xFF1B6B3A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet, size: 80, color: Color(0xFF1B6B3A)),
            const SizedBox(height: 16),
            const Text('TEST ENVIRONMENT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 24),
            Text('Paying ETB ${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 48),
            CustomButton(
              text: 'Authorize Payment (Telebirr/CBE)',
              onPressed: () {
                // Simulate success
                Navigator.pop(context, true);
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Simulate failure
                Navigator.pop(context, false);
              },
              child: const Text('Simulate Failure / Cancel', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
