import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/filter_drawer.dart';
import '../constants.dart';
import 'product_detail_screen.dart';
import 'add_product_screen.dart';
import 'orders_screen.dart';
import 'notifications_screen.dart';
import '../widgets/notification_bell.dart';
import 'messages_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:geolocator/geolocator.dart';
import '../services/product_service.dart';
import '../widgets/skeleton_loader.dart';
import '../utils/vibrant_theme.dart';
import '../providers/localization_provider.dart';
import '../services/notification_service.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String? _selectedCategory;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  
  List<String> _recentSearches = [];
  
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _selectedVoiceLocale = 'en_US';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _speech = stt.SpeechToText();
    _loadTrendingAndNear();
    _scrollController.addListener(_onScroll);
    
    // Explicitly initialize notifications at screen mount to ensure 100% token registration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().init().catchError(
        (e) => debugPrint('FCM Init from Marketplace error: $e')
      );
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductProvider>().fetchMoreProducts();
    }
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveSearch(String query) async {
    if (query.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 5) _recentSearches = _recentSearches.sublist(0, 5);
    await prefs.setStringList('recent_searches', _recentSearches);
    setState(() {});
  }


  Future<void> _loadTrendingAndNear() async {
    final service = ProductService();
    await service.fetchTrendingProducts();
    // setState(() => _trendingProducts = trending);
    
    // Near farmers logic
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition();
        final farmers = await Supabase.instance.client.from('farmers').select();
        final mapped = (farmers as List).map((f) {
          final fLat = f['latitude'] as double?;
          final fLng = f['longitude'] as double?;
          double distance = -1;
          if (fLat != null && fLng != null) {
            distance = Geolocator.distanceBetween(position.latitude, position.longitude, fLat, fLng) / 1000;
          }
          return {...f, 'distance': distance};
        }).where((f) => f['distance'] != -1).toList();
        mapped.sort((a,b) => (a['distance'] as double).compareTo(b['distance'] as double));
        // setState(() => _nearFarmers = mapped.take(10).toList().cast<Map<String, dynamic>>());
      }
    } catch (_) {}
  }

  void _listen() {
    _showVoiceSearchSheet();
  }

  void _showVoiceSearchSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Speak to Search',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a language to speak in:',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  _languageOption(
                    '🇬🇧', 'English', 'en_US',
                    onTap: () {
                      Navigator.pop(context);
                      _startListening('en_US');
                    },
                  ),
                  const SizedBox(height: 10),
                  _languageOption(
                    '🇪🇹', 'Amharic (አማርኛ)', 'am_ET',
                    onTap: () {
                      Navigator.pop(context);
                      _startListening('am_ET');
                    },
                  ),
                  const SizedBox(height: 10),
                  _languageOption(
                    '🇪🇹', 'Afaan Oromoo', 'om_ET',
                    onTap: () {
                      Navigator.pop(context);
                      _startListening('om_ET');
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _languageOption(String flag, String name, String localeId, {required VoidCallback onTap}) {
    final isSelected = _selectedVoiceLocale == localeId;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B6B3A).withValues(alpha: 0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B6B3A) : Colors.grey[200]!,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF1B6B3A) : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF1B6B3A)),
          ],
        ),
      ),
    );
  }

  void _startListening(String localeId) async {
    setState(() {
      _selectedVoiceLocale = localeId;
    });

    try {
      bool available = await _speech.initialize(
        onError: (val) => debugPrint('Error: $val'),
        onStatus: (val) => debugPrint('Status: $val'),
      );
      if (!mounted) return;
      if (available) {
        setState(() => _isListening = true);
        
        // Show our gorgeous pulsating overlay
        _showListeningOverlay();

        _speech.listen(
          onResult: (val) {
            if (mounted) {
              setState(() {
                _searchController.text = val.recognizedWords;
                if (val.finalResult) {
                  _isListening = false;
                  Navigator.of(context).pop(); // dismiss listening overlay
                  _saveSearch(val.recognizedWords);
                  context.read<ProductProvider>().searchProducts(val.recognizedWords);
                }
              });
            }
          },
          localeId: localeId,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available on this device.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Microphone error: $e')),
      );
    }
  }

  void _showListeningOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Listening...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Speak clearly into your microphone',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 30),
                
                // Pulsating Wave animation
                const PulsingMic(),
                
                const SizedBox(height: 30),
                ListenableBuilder(
                  listenable: _searchController,
                  builder: (context, child) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'Say something like "Shorba" or "Wheat"...'
                            : _searchController.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _searchController.text.isEmpty ? Colors.grey : Colors.black87,
                          fontStyle: _searchController.text.isEmpty ? FontStyle.italic : FontStyle.normal,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red,
                    elevation: 0,
                    minimumSize: const Size(120, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    _speech.stop();
                    setState(() => _isListening = false);
                    Navigator.pop(context); // close overlay
                  },
                  icon: const Icon(Icons.stop),
                  label: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<String> _getSeasonalCategories() {
    final month = DateTime.now().month;
    final cats = List<String>.from(productCategories);
    if (month >= 6 && month <= 9) {
      // Rainy: Veggies & Fruits
      cats.remove('Vegetables & Fruits');
      cats.insert(0, 'Vegetables & Fruits');
    } else if (month >= 10 || month <= 1) {
      // Harvest: Grains
      cats.remove('Grains & Cereals');
      cats.insert(0, 'Grains & Cereals');
    }
    return cats;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: VibrantTheme.softBackground,
      endDrawer: FilterDrawer(
        selectedCategory: _selectedCategory,
        onApplyFilters: ({category, isOrganic, location, minPrice, maxPrice}) {
          context.read<ProductProvider>().filterProducts(
                category: category,
                isOrganic: isOrganic,
                location: location,
                minPrice: minPrice,
                maxPrice: maxPrice,
              );
        },
        onClearFilters: () {
          context.read<ProductProvider>().clearFilters();
          setState(() => _selectedCategory = null);
        },
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ProductProvider>().fetchProducts(refresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              floating: false,
              pinned: true,
              stretch: true,
              backgroundColor: VibrantTheme.primaryGreen,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D4D26), Color(0xFF1B6B3A), Color(0xFF2D8B4E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AgriLink',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    'Fresh · Direct · Local',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const NotificationBell(color: Colors.white),
                                  const SizedBox(width: 8),
                                  _iconButton(Icons.list_alt, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersScreen()))),
                                  const SizedBox(width: 8),
                                  _iconButton(Icons.filter_list, () => _scaffoldKey.currentState?.openEndDrawer()),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          const Text(
                            'Find the best\nfarm products',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 1. How it Works Feature (Now ABOVE Search Bar)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: VibrantTheme.softShadow,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: VibrantTheme.primaryGreen),
                          const SizedBox(width: 10),
                          Text(
                            context.read<LocalizationProvider>().translate('How it Works'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: VibrantTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.read<LocalizationProvider>().translate('Direct from Farm'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.read<LocalizationProvider>().translate('Our platform connects you directly with local farmers, ensuring fresh products and fair prices.'),
                        style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _howItWorksStepSmall(Icons.search, 'Find', onTap: () => _searchFocusNode.requestFocus()),
                          _howItWorksStepSmall(Icons.chat_bubble_outline, 'Chat', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen()))),
                          _howItWorksStepSmall(Icons.shopping_basket_outlined, 'Order', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Search Bar (Now BELOW How it Works)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: VibrantTheme.vibrantShadow,
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onSubmitted: (val) {
                      _saveSearch(val);
                      context.read<ProductProvider>().searchProducts(val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search fresh produce...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: VibrantTheme.primaryGreen),
                      suffixIcon: IconButton(
                        icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : VibrantTheme.primaryGreen),
                        onPressed: _listen,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ),
              ),
            ),

            // Category Chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  height: 45,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _categoryChip('All', null),
                      ..._getSeasonalCategories().map((cat) {
                        final emoji = categoryEmojis[cat] ?? '';
                        return _categoryChip('$emoji $cat', cat);
                      }),
                    ],
                  ),
                ),
              ),
            ),

            // Main Content
            Consumer<ProductProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.products.isEmpty) {
                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate((ctx, i) => const ProductSkeleton(), childCount: 4),
                    ),
                  );
                }

                final products = provider.products;

                if (products.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text('No products found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        return ProductCard(
                          product: product,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
                          onAddToCart: () {
                            cartProvider.addToCart(product, 1);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${product.name} added to cart'), backgroundColor: VibrantTheme.primaryGreen, behavior: SnackBarBehavior.floating),
                            );
                          },
                        );
                      },
                      childCount: products.length,
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: authProvider.userRole == 'farmer'
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen())),
              backgroundColor: VibrantTheme.primaryGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Post Product'),
            )
          : null,
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
      child: IconButton(icon: Icon(icon, color: Colors.white, size: 20), onPressed: onPressed),
    );
  }

  Widget _categoryChip(String label, String? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: () {
          final newCategory = isSelected ? null : category;
          setState(() => _selectedCategory = newCategory);
          context.read<ProductProvider>().filterProducts(category: newCategory);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? VibrantTheme.primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isSelected ? VibrantTheme.vibrantShadow : VibrantTheme.softShadow,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : VibrantTheme.textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _howItWorksStepSmall(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(icon, color: VibrantTheme.primaryGreen, size: 16),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: VibrantTheme.primaryGreen)),
        ],
      ),
    );
  }
}

class PulsingMic extends StatefulWidget {
  const PulsingMic({super.key});

  @override
  State<PulsingMic> createState() => _PulsingMicState();
}

class _PulsingMicState extends State<PulsingMic> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(12 + (12 * _controller.value)),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1B6B3A).withValues(alpha: 0.1 * (1 - _controller.value)),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1B6B3A),
            ),
            child: const Icon(
              Icons.mic,
              size: 32,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}