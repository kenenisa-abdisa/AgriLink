import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/storage_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minOrderController = TextEditingController(text: '1');
  final _bulkPriceController = TextEditingController();
  final _bulkMinQtyController = TextEditingController();

  /// XFile works on all platforms including Web (unlike dart:io File)
  final List<XFile?> _images = List.filled(4, null);

  /// Cached raw bytes used for Image.memory preview (Web-safe)
  final List<Uint8List?> _imageBytes = List.filled(4, null);

  final _imagePicker = ImagePicker();
  double _uploadProgress = 0.0;
  bool _isUploading = false;

  String? _category;
  String _unit = 'kg';
  bool _deliveryAvailable = true;
  bool _pickupAvailable = true;
  bool _bulkAvailable = false;
  bool _isOrganic = false;
  bool _isLoading = false;
  String _location = '';

  // ── Image picking ──────────────────────────────────────────────────────────

  Future<void> _pickImage(int index) async {
    ImageSource? source;

    if (kIsWeb) {
      // Camera not supported on Web; go straight to gallery (file picker)
      source = ImageSource.gallery;
    } else {
      source = await showDialog<ImageSource>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
    }

    if (source == null) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (picked != null) {
      // Read bytes once — used for Image.memory preview (Web-safe)
      final bytes = await picked.readAsBytes();
      setState(() {
        _images[index] = picked;
        _imageBytes[index] = bytes;
      });
    }
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a category'),
            backgroundColor: Colors.red),
      );
      return;
    }
    if (_images[0] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Main product photo is required'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Try to get farmer_id
      String? farmerId;
      try {
        final farmerResponse = await Supabase.instance.client
            .from('farmers')
            .select('id')
            .eq('user_id', user.id)
            .maybeSingle();
        farmerId = farmerResponse?['id'];
      } catch (_) {}

      // Upload Images via XFile (web-compatible)
      final storageService = StorageService();
      final imageUrls = <String>[];
      final imagesToUpload =
          _images.where((f) => f != null).cast<XFile>().toList();

      for (int i = 0; i < imagesToUpload.length; i++) {
        final url = await storageService.uploadProductImage(
            imagesToUpload[i], user.id);
        imageUrls.add(url);
        setState(() => _uploadProgress = (i + 1) / imagesToUpload.length);
      }

      await Supabase.instance.client.from('products').insert({
        'user_id': user.id,
        'farmer_id': farmerId,
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'unit': _unit,
        'category': _category,
        'location': _location.isEmpty
            ? (user.userMetadata?['region'] ?? 'Ethiopia')
            : _location,
        'quantity': double.parse(_quantityController.text.trim()),
        'min_order': double.tryParse(_minOrderController.text.trim()) ?? 1,
        'is_organic': _isOrganic,
        'delivery_available': _deliveryAvailable,
        'pickup_available': _pickupAvailable,
        'bulk_available': _bulkAvailable,
        'bulk_price':
            _bulkAvailable ? double.tryParse(_bulkPriceController.text) : null,
        'bulk_min_quantity': _bulkAvailable
            ? double.tryParse(_bulkMinQtyController.text)
            : null,
        'image_urls': imageUrls,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🌱 Your listing is live!'),
            backgroundColor: Color(0xFF1B6B3A),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
      }
    }
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _minOrderController.dispose();
    _bulkPriceController.dispose();
    _bulkMinQtyController.dispose();
    super.dispose();
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  /// Image grid using [Image.memory] so it works on Flutter Web.
  Widget _buildImageGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Product Photos',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (index) {
            final isMain = index == 0;
            final bytes = _imageBytes[index];
            return Expanded(
              child: GestureDetector(
                onTap: () => _pickImage(index),
                child: Container(
                  margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: bytes != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              // Image.memory works on all platforms incl. Web
                              child:
                                  Image.memory(bytes, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: -4,
                              right: -4,
                              child: IconButton(
                                icon: const Icon(Icons.cancel,
                                    color: Colors.red, size: 20),
                                onPressed: () => setState(() {
                                  _images[index] = null;
                                  _imageBytes[index] = null;
                                }),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate,
                                color: Colors.grey[400]),
                            if (isMain)
                              const Text('Main\n(Req)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _toggleRow(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF1B6B3A).withValues(alpha: 0.5),
            activeThumbColor: const Color(0xFF1B6B3A),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text('Add Product'),
        backgroundColor: const Color(0xFF1B6B3A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isUploading) ...[
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: Colors.grey[300],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF1B6B3A)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Text(
                      'Uploading photos... ${(_uploadProgress * 100).toInt()}%',
                      style: const TextStyle(color: Color(0xFF1B6B3A))),
                ),
              ],

              _buildImageGrid(),

              CustomTextField(
                controller: _nameController,
                label: 'Product Name',
                hint: 'e.g. Premium Teff, Fresh Tomatoes',
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: productCategories.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text('${categoryEmojis[c] ?? ''} $c'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _category = val),
                validator: (val) =>
                    val == null ? 'Select a category' : null,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _descController,
                label: 'Description',
                hint: 'Describe your product...',
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Price + Unit row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: _priceController,
                      label: 'Price (ETB)',
                      hint: '0.00',
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (double.tryParse(val) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: productUnits
                          .map((u) =>
                              DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _unit = val ?? 'kg'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quantity + Min order
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _quantityController,
                      label: 'Available Qty',
                      hint: '0',
                      keyboardType: TextInputType.number,
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _minOrderController,
                      label: 'Min Order',
                      hint: '1',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location
              DropdownButtonFormField<String>(
                initialValue: _location.isEmpty ? null : _location,
                decoration: InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: ethiopianRegions
                    .map((r) =>
                        DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) => setState(() => _location = val ?? ''),
              ),
              const SizedBox(height: 20),

              // Toggle switches
              _toggleRow('🌿 Organic', _isOrganic,
                  (val) => setState(() => _isOrganic = val)),
              _toggleRow('🚚 I can deliver', _deliveryAvailable,
                  (val) => setState(() => _deliveryAvailable = val)),
              _toggleRow('📦 Buyer can pick up', _pickupAvailable,
                  (val) => setState(() => _pickupAvailable = val)),
              _toggleRow('🏭 Available for bulk orders', _bulkAvailable,
                  (val) => setState(() => _bulkAvailable = val)),

              if (_bulkAvailable) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _bulkPriceController,
                        label: 'Bulk Price (ETB)',
                        hint: 'Lower price',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _bulkMinQtyController,
                        label: 'Bulk Min Qty',
                        hint: 'Min for discount',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 30),

              CustomButton(
                text: 'Publish Listing',
                onPressed: _submitProduct,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
