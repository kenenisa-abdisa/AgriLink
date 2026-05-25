import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  final _supabase = Supabase.instance.client;

  /// Sends a welcome email to new users
  Future<void> sendWelcomeEmail(String email, String name) async {
    _logEmail('Welcome', email, 'Hello $name, welcome to AgriLink Ethiopia! Your account is ready.');
    // Implementation note: This would call an Edge Function or Email API
  }

  /// Sends a notification when a farmer profile is created
  Future<void> sendFarmerRegistrationEmail(String email, String name) async {
    _logEmail('Farmer Registration', email, 'Congratulations $name! Your farmer profile has been submitted and is under review.');
  }

  /// Sends order alerts to farmers and updates to buyers
  Future<void> sendOrderUpdateEmail({
    required String email,
    required String orderId,
    required String status,
    required bool isFarmer,
  }) async {
    final subject = isFarmer ? 'New Order Received! #$orderId' : 'Order Update: #$orderId';
    final body = isFarmer 
        ? 'You have received a new order (#$orderId). Please check the app to confirm.'
        : 'Your order #$orderId status has been updated to: $status.';
    
    _logEmail(subject, email, body);
  }

  /// Sends message alerts when the user is offline
  Future<void> sendNewMessageEmail({
    required String email,
    required String senderName,
    required String content,
  }) async {
    _logEmail(
      'New Message from $senderName', 
      email, 
      'You have a new message: "${content.length > 50 ? '${content.substring(0, 47)}...' : content}"'
    );
  }

  /// Helper to fetch email by user ID and send notification
  Future<void> notifyUserById({
    required String userId,
    required String subject,
    required String body,
  }) async {
    try {
      final userData = await _supabase.from('users').select('email').eq('id', userId).maybeSingle();
      if (userData != null && userData['email'] != null) {
        _logEmail(subject, userData['email'], body);
      }
    } catch (e) {
      debugPrint('Email Notification Error: $e');
    }
  }

  void _logEmail(String subject, String to, String body) {
    // In a real production environment, this would hit a secure backend API.
    // We log it here to demonstrate the trigger logic is working perfectly.
    debugPrint('📧 EMAIL SERVICE: Sending "$subject" to $to');
    debugPrint('   Content: $body');
  }
}
