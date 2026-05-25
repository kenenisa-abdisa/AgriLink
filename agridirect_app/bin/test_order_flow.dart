import 'package:supabase/supabase.dart';
import 'dart:math';

Future<void> main() async {
  const supabaseUrl = 'https://bmdmzawwpnbkgttmmbdo.supabase.co';
  const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJtZG16YXd3cG5ia2d0dG1tYmRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNTI4MjUsImV4cCI6MjA5MzkyODgyNX0.dd2d2RWNsPT1ZB26NVOH03hqgd9EZm6VM2FnGXSM84I';

  final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);

  // 1. Create a dummy buyer and farmer
  final rand = Random().nextInt(100000);
  final buyerEmail = 'buyer$rand@test.com';
  final farmerEmail = 'farmer$rand@test.com';
  final pass = 'password123';

  print('Signing up buyer...');
  final buyerAuth = await supabase.auth.signUp(email: buyerEmail, password: pass);
  final buyerId = buyerAuth.user!.id;
  await supabase.from('users').insert({'id': buyerId, 'email': buyerEmail, 'name': 'Buyer $rand', 'role': 'buyer'});

  print('Signing up farmer...');
  final farmerAuth = await supabase.auth.signUp(email: farmerEmail, password: pass);
  final farmerUserId = farmerAuth.user!.id;
  await supabase.from('users').insert({'id': farmerUserId, 'email': farmerEmail, 'name': 'Farmer $rand', 'role': 'farmer'});

  // 2. Create a farmer profile for the farmer
  print('Creating farmer profile...');
  final farmerProfile = await supabase.from('farmers').insert({
    'user_id': farmerUserId,
    'farm_name': 'Test Farm $rand',
    'is_verified': true,
  }).select().single();
  final farmerId = farmerProfile['id'];

  // 3. Create a product
  print('Creating product...');
  final product = await supabase.from('products').insert({
    'user_id': farmerUserId,
    'farmer_id': farmerId,
    'name': 'Test Product',
    'price': 100.0,
    'category': 'Other',
    'location': 'Test',
    'quantity': 50,
  }).select().single();

  // 4. Log in as buyer and place order
  print('Logging in as buyer to place order...');
  await supabase.auth.signInWithPassword(email: buyerEmail, password: pass);
  
  print('Placing order...');
  final order = await supabase.from('orders').insert({
    'buyer_id': buyerId,
    'farmer_id': farmerId,
    'total_amount': 200.0,
    'payment_method': 'Cash',
    'status': 'pending'
  }).select().single();
  final orderId = order['id'];

  print('Inserting order item...');
  await supabase.from('order_items').insert({
    'order_id': orderId,
    'product_id': product['id'],
    'product_name': 'Test Product',
    'quantity': 2,
    'price': 100.0,
  });

  // 5. Log in as farmer and try to fetch orders!
  print('Logging in as farmer to fetch orders...');
  await supabase.auth.signInWithPassword(email: farmerEmail, password: pass);

  try {
    print('Fetching farmer orders using service logic...');
    final orders = await supabase
        .from('orders')
        .select()
        .or('farmer_id.eq.$farmerId,buyer_id.eq.$farmerUserId');
    print('Farmer fetched ${orders.length} orders successfully.');

    if (orders.isNotEmpty) {
      for (var o in orders) {
        print('Fetching items for order ${o['id']}...');
        final items = await supabase.from('order_items').select().eq('order_id', o['id']);
        print('  Found ${items.length} items.');
      }
    }
  } catch (e) {
    print('!!! ERROR FETCHING ORDERS AS FARMER !!!');
    print(e);
  }
}
