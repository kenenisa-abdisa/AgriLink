import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String orderId;
  final double amount;
  final String paymentMethod;

  const PaymentSuccessScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF1B6B3A), size: 100),
              const SizedBox(height: 24),
              const Text('Payment Successful!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Order ID: ${orderId.toUpperCase()}'),
              Text('Amount Paid: ETB ${amount.toStringAsFixed(2)}'),
              Text('Method: $paymentMethod'),
              const SizedBox(height: 48),
              CustomButton(
                text: 'View Orders',
                onPressed: () {
                   Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                   Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('Continue Shopping', style: TextStyle(color: Color(0xFF1B6B3A))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
