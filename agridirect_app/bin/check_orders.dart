import 'package:supabase/supabase.dart';

Future<void> main() async {
  const supabaseUrl = 'https://bmdmzawwpnbkgttmmbdo.supabase.co';
  const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJtZG16YXd3cG5ia2d0dG1tYmRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNTI4MjUsImV4cCI6MjA5MzkyODgyNX0.dd2d2RWNsPT1ZB26NVOH03hqgd9EZm6VM2FnGXSM84I';

  final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);

  try {
    final response = await supabase.from('orders').select();
    print('Found ${response.length} orders in total:');
    for (final order in response) {
      print('Order ID: ${order["id"]}, Status: ${order["status"]}');
    }
  } catch (e) {
    print('ERROR QUERYING ORDERS: $e');
  }
}
