import 'package:supabase/supabase.dart';

Future<void> main() async {
  const supabaseUrl = 'https://bmdmzawwpnbkgttmmbdo.supabase.co';
  const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJtZG16YXd3cG5ia2d0dG1tYmRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNTI4MjUsImV4cCI6MjA5MzkyODgyNX0.dd2d2RWNsPT1ZB26NVOH03hqgd9EZm6VM2FnGXSM84I';

  // Use service role key to bypass RLS!
  final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);

  try {
    final orders = await supabase.from('orders').select();
    print('ORDERS:');
    for (var o in orders) {
      print('  ID: ${o["id"]}');
      print('  buyer_id: ${o["buyer_id"]}');
      print('  farmer_id: ${o["farmer_id"]}');
    }

    final farmers = await supabase.from('farmers').select();
    print('\nFARMERS:');
    for (var f in farmers) {
      print('  ID: ${f["id"]}');
      print('  user_id: ${f["user_id"]}');
      print('  farm_name: ${f["farm_name"]}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
