import 'dart:convert';
import 'package:http/http.dart' as http;
import '../env_config.dart';

class PaymentService {
  Future<String?> initializePayment({
    required double amount,
    required String email,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String txRef,
    String currency = 'ETB',
  }) async {
    // Mock mode when using placeholder key
    if (EnvConfig.isChapaTestMode) {
      await Future.delayed(const Duration(seconds: 1));
      return 'https://mock-checkout.com/$txRef';
    }

    final url = Uri.parse(EnvConfig.chapaInitUrl);
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${EnvConfig.chapaSecretKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': amount.toStringAsFixed(2),
        'currency': currency,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'tx_ref': txRef,
        'return_url': EnvConfig.paymentReturnUrl,
        'customization': {
          'title': 'AgriLink Ethiopia',
          'description': 'Payment for your order #$txRef',
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return data['data']['checkout_url'];
      } else {
        throw Exception(data['message'] ?? 'Failed to get checkout URL');
      }
    } else {
      throw Exception('Failed to initialize Chapa payment: ${response.statusCode} - ${response.body}');
    }
  }

  Future<bool> verifyPayment(String txRef) async {
    if (EnvConfig.isChapaTestMode) {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }

    try {
      final url = Uri.parse(EnvConfig.chapaVerifyUrl(txRef));
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${EnvConfig.chapaSecretKey}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success' && data['data']['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
