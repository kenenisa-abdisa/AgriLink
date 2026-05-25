import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env_config.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/message_provider.dart';
import 'providers/farmer_provider.dart';
import 'providers/localization_provider.dart';
import 'screens/marketplace_screen.dart';
import 'screens/farmers_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/business_portal_screen.dart';
import 'screens/bulk_order_screen.dart';
import 'screens/add_product_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
import 'services/cache_service.dart';
import 'screens/splash_screen.dart';
import 'utils/vibrant_theme.dart';

import 'dart:async';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Show errors on screen instead of crashing
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    };

    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
    );

    // Initialize Local Cache
    await CacheService.init();

    try {
      await Firebase.initializeApp();
      // Initialize notifications but don't let it block the app boot
      NotificationService().init().catchError(
        (e) => debugPrint('Notification Init Error: $e'),
      );
    } catch (e) {
      debugPrint('Firebase Init Error: $e');
    }

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => OrderProvider()),
          ChangeNotifierProvider(create: (_) => MessageProvider()),
          ChangeNotifierProvider(create: (_) => FarmerProvider()),
          ChangeNotifierProvider(create: (_) => LocalizationProvider()),
        ],
        child: const AgriLinkApp(),
      ),
    );
  }, (error, stackTrace) {
    debugPrint('FATAL ERROR: $error');
    debugPrint('$stackTrace');
  });
}

class AgriLinkApp extends StatelessWidget {
  const AgriLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriLink',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: VibrantTheme.primaryGreen,
          primary: VibrantTheme.primaryGreen,
          secondary: VibrantTheme.freshLime,
          surface: VibrantTheme.softBackground,
        ),
        scaffoldBackgroundColor: VibrantTheme.softBackground,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: VibrantTheme.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[100]!)),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: VibrantTheme.primaryGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            shadowColor: VibrantTheme.primaryGreen.withValues(alpha: 0.3),
          ),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const AppShell(),
        '/business-portal': (context) => const BusinessPortalScreen(),
        '/bulk-order': (context) => const BulkOrderScreen(),
        '/add-product': (context) => const AddProductScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _handleSplash();
  }

  Future<void> _handleSplash() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return const SplashScreen();
    final authProvider = context.watch<AuthProvider>();
    return authProvider.isAuthenticated ? const AppShell() : const LoginScreen();
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  RealtimeChannel? _notificationChannel;
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initNotificationListener();
    NotificationService().init().catchError(
      (e) => debugPrint('FCM Init from AppShell error: $e'),
    );
    _updatePresence(true);
    _startHeartbeat();
  }

  void _updatePresence(bool isOnline) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client.from('users').update({
        'is_online': isOnline,
        'last_seen_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Error updating presence: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updatePresence(true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updatePresence(true);
      _startHeartbeat();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _updatePresence(false);
      _heartbeatTimer?.cancel();
    }
  }

  void _initNotificationListener() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _notificationChannel = Supabase.instance.client
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId),
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(newRecord['title'] ?? 'Notification', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(newRecord['body'] ?? ''),
                    ],
                  ),
                  backgroundColor: VibrantTheme.primaryGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
        )
      ..subscribe();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _updatePresence(false);
    _notificationChannel?.unsubscribe();
    super.dispose();
  }

  final List<Widget> _screens = const [
    MarketplaceScreen(),
    FarmersScreen(),
    OrdersScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocalizationProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final authProvider = context.watch<AuthProvider>();
    final messageProvider = context.watch<MessageProvider>();

    // Calculate pending orders received (action required by this user)
    final pendingOrdersCount = orderProvider.orders
        .where((o) => o.status == 'pending' && o.buyerId != authProvider.currentUserId)
        .length;

    // Calculate unread chats
    final unreadChatsCount = messageProvider.unreadCount;

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _navItem(0, Icons.storefront_rounded, t.translate('Market'), t),
                _navItem(1, Icons.people_rounded, t.translate('Farmers'), t),
                _navItem(2, Icons.receipt_long_rounded, t.translate('Orders'), t, badgeCount: pendingOrdersCount),
                _navItem(3, Icons.message_rounded, t.translate('Chats'), t, badgeCount: unreadChatsCount),
                _navItem(4, Icons.person_rounded, t.translate('Profile'), t),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _navItem(int index, IconData icon, String label, LocalizationProvider t, {int badgeCount = 0}) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? VibrantTheme.primaryGreen.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: badgeCount > 0,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              label: Text(badgeCount > 99 ? '99+' : badgeCount.toString()),
              child: Icon(icon, color: isSelected ? VibrantTheme.primaryGreen : Colors.grey[400], size: 24),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isSelected ? VibrantTheme.primaryGreen : Colors.grey[400], fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget? _buildFAB(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    if (_selectedIndex == 0 && cartProvider.itemCount > 0) {
      return FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
        backgroundColor: VibrantTheme.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.shopping_cart_rounded),
        label: Text('Cart (${cartProvider.itemCount})'),
      );
    }
    return null;
  }
}
