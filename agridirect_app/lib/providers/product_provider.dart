import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../services/cache_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int pageSize = 20;
  
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isOffline = false;

  List<ProductModel> get products => _filteredProducts;
  List<ProductModel> get allProducts => _products;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMore => _hasMore;
  bool get isOffline => _isOffline;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;

  ProductProvider() {
    fetchProducts();
  }

  Future<void> fetchProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _hasMore = true;
    }

    _isLoading = true;
    notifyListeners();

    // 1. Try to load from cache immediately
    if (_products.isEmpty) {
      _products = CacheService.getCachedProducts();
      _applyFilters();
      notifyListeners();
    }

    // 2. Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOffline = connectivityResult.contains(ConnectivityResult.none);
    
    if (_isOffline) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // 3. Fetch fresh data from Supabase (first page)
      final freshProducts = await _productService.fetchProducts(limit: pageSize);
      _products = freshProducts;
      _hasMore = freshProducts.length == pageSize;
      _currentPage = 1;
      
      // Update cache
      await CacheService.cacheProducts(_products);
      _applyFilters();
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMoreProducts() async {
    if (_isFetchingMore || !_hasMore || _isOffline) return;

    _isFetchingMore = true;
    notifyListeners();

    try {
      final moreProducts = await _productService.fetchProducts(
        offset: _currentPage * pageSize,
        limit: pageSize,
      );
      
      if (moreProducts.isEmpty) {
        _hasMore = false;
      } else {
        _products.addAll(moreProducts);
        _currentPage++;
        _hasMore = moreProducts.length == pageSize;
      }
      _applyFilters();
    } catch (e) {
      _hasMore = false;
    }

    _isFetchingMore = false;
    notifyListeners();
  }

  void searchProducts(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void filterByCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void filterProducts({
    String? category,
    bool? isOrganic,
    String? location,
    double? minPrice,
    double? maxPrice,
    String? farmerId,
  }) {
    _filteredProducts = List.from(_products);

    if (category != null && category.isNotEmpty) {
      _filteredProducts = _filteredProducts
          .where((p) => p.category == category)
          .toList();
    }

    if (isOrganic != null) {
      _filteredProducts = _filteredProducts
          .where((p) => p.isOrganic == isOrganic)
          .toList();
    }

    if (location != null && location.isNotEmpty) {
      _filteredProducts = _filteredProducts
          .where((p) =>
              p.location.toLowerCase().contains(location.toLowerCase()))
          .toList();
    }

    if (minPrice != null) {
      _filteredProducts =
          _filteredProducts.where((p) => p.price >= minPrice).toList();
    }

    if (maxPrice != null) {
      _filteredProducts =
          _filteredProducts.where((p) => p.price <= maxPrice).toList();
    }

    if (farmerId != null) {
      _filteredProducts = _filteredProducts
          .where((p) => p.userId == farmerId || p.farmerId == farmerId)
          .toList();
    }

    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _filteredProducts = List.from(_products);
    notifyListeners();
  }

  void _applyFilters() {
    List<ProductModel> filtered = List.from(_products);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.location.toLowerCase().contains(query) ||
            p.category.toLowerCase().contains(query) ||
            (p.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    if (_selectedCategory != null) {
      filtered =
          filtered.where((p) => p.category == _selectedCategory).toList();
    }

    _filteredProducts = filtered;
  }

  ProductModel? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Stream for real-time product updates
  Stream<List<Map<String, dynamic>>> streamProducts() {
    return _productService.streamProducts();
  }
}