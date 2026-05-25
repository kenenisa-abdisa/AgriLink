import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';

class PaymentFailedScreen extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onPayOnDelivery;

  const PaymentFailedScreen({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    required this.onPayOnDelivery,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(title: const Text('Payment Failed'), backgroundColor: Colors.red),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 100),
            const SizedBox(height: 24),
            const Text('Payment Could Not Be Processed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(errorMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 48),
            CustomButton(text: 'Try Again', onPressed: onRetry),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onPayOnDelivery,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF1B6B3A)),
              ),
              child: const Text('Pay on Delivery Instead', style: TextStyle(color: Color(0xFF1B6B3A))),
            ),
          ],
        ),
      ),
    );
  }
}
