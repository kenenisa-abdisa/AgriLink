// ignore_for_file: avoid_print
import 'package:supabase/supabase.dart'; // ignore: depend_on_referenced_packages

Future<void> main() async {
  const supabaseUrl = 'https://bmdmzawwpnbkgttmmbdo.supabase.co';
  const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJtZG16YXd3cG5ia2d0dG1tYmRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNTI4MjUsImV4cCI6MjA5MzkyODgyNX0.dd2d2RWNsPT1ZB26NVOH03hqgd9EZm6VM2FnGXSM84I';

  final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);

  print('Testing device_tokens table query...');
  try {
    final response = await supabase
        .from('device_tokens')
        .select('*');
    
    print('SUCCESS! Found ${response.length} device tokens.');
    for (final token in response) {
      print('Token for User ID: ${token["user_id"]} (Platform: ${token["platform"]}, Token: ${token["token"]})');
    }
  } catch (e) {
    print('ERROR QUERYING DEVICE TOKENS: $e');
  }

  print('\nTesting order insertion...');
  try {
    // ignore: unused_local_variable
    final buyerId = supabase.auth.currentUser?.id ?? '00000000-0000-0000-0000-000000000000'; // dummy or actual
    // We will just try to insert a dummy order using a known user ID.
    // If it fails with PGRST204 or RLS, we'll see it here.
    
    // First let's get a real user ID
    final users = await supabase.from('users').select('id').limit(2);
    if (users.length < 2) {
       print('Not enough users to test order insertion.');
       return;
    }
    final testBuyerId = users[0]['id'];
    final testFarmerId = users[1]['id']; // This is a user_id, not a farmers.id

    // Check if farmer exists
    var farmerIdForOrder = testFarmerId;
    final farmerResp = await supabase.from('farmers').select('id').eq('user_id', testFarmerId).maybeSingle();
    if (farmerResp != null) {
        farmerIdForOrder = farmerResp['id'];
    }

    final orderResponse = await supabase.from('orders').insert({
        'buyer_id': testBuyerId,
        'farmer_id': farmerIdForOrder,
        'total_amount': 100,
        'payment_method': 'Cash on Delivery',
        'status': 'pending',
    }).select().single();
    
    print('SUCCESS! Order inserted: \${orderResponse["id"]}');
  } catch (e) {
    print('ERROR INSERTING ORDER: \$e');
  }
}
