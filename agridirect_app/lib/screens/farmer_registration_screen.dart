import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/email_service.dart';
import '../providers/farmer_provider.dart';

class FarmerRegistrationScreen extends StatefulWidget {
  const FarmerRegistrationScreen({super.key});

  @override
  State<FarmerRegistrationScreen> createState() =>
      _FarmerRegistrationScreenState();
}

class _FarmerRegistrationScreenState extends State<FarmerRegistrationScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 2: Farm details
  final _farmNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _townController = TextEditingController();
  final _farmSizeController = TextEditingController();
  String? _selectedRegion;
  final List<String> _selectedCategories = [];

  // Step 3: ID & Payment
  String _idType = 'Kebele ID';
  final _paymentNumberController = TextEditingController();
  String _paymentMethod = 'Telebirr';
  Uint8List? _idPhotoBytes;

  final List<String> _idTypes = [
    'Kebele ID',
    'National ID',
    'Passport',
    'Driver\'s Licence',
  ];

  final List<String> _farmCategories = [
    'Vegetables & Fruits',
    'Grains & Cereals',
    'Dairy & Eggs',
    'Meat & Poultry',
  ];

  Future<void> _pickIdPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _idPhotoBytes = bytes;
      });
    }
  }

  Future<void> _submitRegistration() async {
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      await Supabase.instance.client.from('farmers').upsert({
        'user_id': user.id,
        'farm_name': _farmNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'region': _selectedRegion,
        'town': _townController.text.trim(),
        'farm_size': double.tryParse(_farmSizeController.text.trim()),
        'certifications': _selectedCategories,
        'payment_method': _paymentMethod,
        'payment_number': _paymentNumberController.text.trim(),
        'is_verified': false, // Reset verification on major update? Or keep?
        'rating': 0.0,
        'total_reviews': 0,
      }, onConflict: 'user_id');

      // UPGRADE ACCOUNT: Explicitly set role to farmer in both metadata and users table
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        await authProvider.authService.updateRole('farmer');
        authProvider.init(); // Refresh the provider state
        
        // Refresh Farmer list to show new profile
        if (mounted) {
          context.read<FarmerProvider>().fetchFarmers(refresh: true);
        }
        
        // Send Farmer Registration Notification
        try {
          await Supabase.instance.client.from('notifications').insert({
            'user_id': user.id,
            'title': 'Farmer Profile Created! 🌾',
            'body': 'Your registration was successful. You can now list your products and connect with buyers!',
            'data': {'type': 'farmer_registration'}
          });
          
          // Send Farmer Registration Email
          final name = user.userMetadata?['name'] ?? 'Farmer';
          await EmailService().sendFarmerRegistrationEmail(user.email!, name);
        } catch (_) {}

        setState(() => _currentStep = 3); // Go to success step
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _farmNameController.dispose();
    _bioController.dispose();
    _townController.dispose();
    _farmSizeController.dispose();
    _paymentNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text('Farmer Registration'),
        backgroundColor: const Color(0xFF1B6B3A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: List.generate(4, (index) {
                final isActive = index <= _currentStep;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF1B6B3A)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          // Step content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildStep(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildSuccessStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 1: Personal info summary
  Widget _buildStep1() {
    final user = Supabase.instance.client.auth.currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 1: Personal Info',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your account information has been collected during sign up.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _infoRow('Name', user?.userMetadata?['name'] ?? 'N/A'),
                const Divider(),
                _infoRow('Email', user?.email ?? 'N/A'),
                const Divider(),
                _infoRow('Phone', user?.userMetadata?['phone'] ?? 'N/A'),
                const Divider(),
                _infoRow('Role', 'Farmer'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        CustomButton(
          text: 'Continue to Farm Details',
          onPressed: () => setState(() => _currentStep = 1),
        ),
      ],
    );
  }

  // Step 2: Farm details
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 2: Farm Details',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: _farmNameController,
          label: 'Farm Name',
          hint: 'Enter your farm name',
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedRegion,
          decoration: InputDecoration(
            labelText: 'Region',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          items: ethiopianRegions
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
          onChanged: (val) => setState(() => _selectedRegion = val),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _townController,
          label: 'Town',
          hint: 'Enter your town',
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _farmSizeController,
          label: 'Farm Size (hectares)',
          hint: 'e.g. 2.5',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _bioController,
          label: 'Bio',
          hint: 'Tell buyers about your farm...',
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        const Text(
          'What do you produce?',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 8),
        ...List.generate(_farmCategories.length, (i) {
          final cat = _farmCategories[i];
          return CheckboxListTile(
            title: Text('${categoryEmojis[cat] ?? ''} $cat'),
            value: _selectedCategories.contains(cat),
            activeColor: const Color(0xFF1B6B3A),
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedCategories.add(cat);
                } else {
                  _selectedCategories.remove(cat);
                }
              });
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          );
        }),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 0),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: CustomButton(
                text: 'Continue',
                onPressed: () => setState(() => _currentStep = 2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 3: ID & Payment
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 3: Verification & Payment',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: _idType,
          decoration: InputDecoration(
            labelText: 'ID Type',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          items: _idTypes
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (val) => setState(() => _idType = val ?? _idType),
        ),
        const SizedBox(height: 16),
        // Photo upload functionality
        GestureDetector(
          onTap: _pickIdPhoto,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            clipBehavior: Clip.hardEdge,
            child: _idPhotoBytes != null
                ? Image.memory(_idPhotoBytes!, fit: BoxFit.cover)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 36, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Upload ID Photo (Optional)',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: _paymentMethod,
          decoration: InputDecoration(
            labelText: 'Payment Method',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          items: paymentMethods
              .where((p) => p != 'Cash on Delivery')
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: (val) =>
              setState(() => _paymentMethod = val ?? _paymentMethod),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _paymentNumberController,
          label: 'Payment Account Number',
          hint: 'Enter your account number',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 1),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: CustomButton(
                text: 'Submit Registration',
                onPressed: _submitRegistration,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Success step
  Widget _buildSuccessStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1B6B3A).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 80,
              color: Color(0xFF1B6B3A),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Registration Submitted!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Your farm profile will be verified within 24 hours.\nYou can start listing products right away!',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          CustomButton(
            text: 'Go to Dashboard',
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
