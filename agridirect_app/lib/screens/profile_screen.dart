import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import 'farmer_earnings_screen.dart';
import '../providers/localization_provider.dart';
import '../utils/vibrant_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploadingProfile = false;

  Future<void> _pickAndUploadProfilePhoto(
      BuildContext context, AuthProvider authProvider) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (pickedFile == null) return;

    setState(() => _isUploadingProfile = true);
    
    try {
      final storageService = StorageService();
      final url = await storageService.uploadProfileImage(
          pickedFile, authProvider.currentUserId);
      await authProvider.updateProfile(profileImage: url);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated!'), backgroundColor: Color(0xFF1B6B3A)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingProfile = false);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final t = context.watch<LocalizationProvider>();
    final name = authProvider.userName;
    final email = authProvider.userEmail;
    final role = authProvider.userRole;

    return Scaffold(
      backgroundColor: VibrantTheme.softBackground,
      appBar: AppBar(
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: VibrantTheme.primaryGradient)),
        title: Text(t.translate('Profile'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Premium Avatar Section
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(gradient: VibrantTheme.primaryGradient, shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: VibrantTheme.primaryGreen,
                      backgroundImage: authProvider.userProfileImage != null ? CachedNetworkImageProvider(authProvider.userProfileImage!) : null,
                      child: authProvider.userProfileImage == null
                          ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: Colors.white))
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _pickAndUploadProfilePhoto(context, authProvider),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: VibrantTheme.primaryGreen, shape: BoxShape.circle, boxShadow: VibrantTheme.vibrantShadow),
                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                if (_isUploadingProfile) const CircularProgressIndicator(color: Colors.white),
              ],
            ),
            const SizedBox(height: 20),
            Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: VibrantTheme.textDark)),
            Text(email, style: const TextStyle(fontSize: 14, color: VibrantTheme.textGrey)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: VibrantTheme.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(
                role == 'farmer' ? '🌾 Farmer' : role == 'business' ? '🏢 Business' : '🛒 Consumer',
                style: const TextStyle(color: VibrantTheme.primaryGreen, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),

            // Language Selector (Modern)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: VibrantTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.translate('Language'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _langButton('English', 'en', t),
                      const SizedBox(width: 8),
                      _langButton('አማርኛ', 'am', t),
                      const SizedBox(width: 8),
                      _langButton('Oromo', 'or', t),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Profile Actions
            Container(
              decoration: VibrantTheme.cardDecoration,
              child: Column(
                children: [
                  _profileTile(Icons.person_outline, 'Edit Profile', () => _showEditDialog(context)),
                  const Divider(height: 1),
                  _profileTile(Icons.sync_rounded, 'Sync Account', () async {
                    await authProvider.syncRole();
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account synchronized 🔄'), backgroundColor: VibrantTheme.primaryGreen, behavior: SnackBarBehavior.floating));
                  }),
                  if (role == 'farmer') ...[
                    const Divider(height: 1),
                    _profileTile(Icons.agriculture_rounded, 'Farm Dashboard', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerEarningsScreen()))),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleLogout(context, authProvider),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: VibrantTheme.primaryGreen,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: VibrantTheme.primaryGreen.withValues(alpha: 0.3))),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleDeleteAccount(context, authProvider),
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text('Delete Account'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.red[100]!)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _profileTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: VibrantTheme.primaryGreen),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _langButton(String label, String code, LocalizationProvider t) {
    final isSelected = t.locale == code;
    return Expanded(
      child: GestureDetector(
        onTap: () => t.setLocale(code),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? VibrantTheme.primaryGradient : null,
            color: isSelected ? null : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? VibrantTheme.softShadow : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: isSelected ? Colors.white : VibrantTheme.textDark, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out of AgriLink?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); auth.logout(); },
            style: ElevatedButton.styleFrom(backgroundColor: VibrantTheme.primaryGreen, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
        content: const Text('Are you sure you want to permanently delete your account? This action cannot be undone and will erase all your data, products, and orders.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await auth.deleteAccount();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final nameController = TextEditingController(text: authProvider.userName);
    final phoneController = TextEditingController(text: authProvider.userPhone);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Profile'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 16),
            TextField(controller: phoneController, decoration: InputDecoration(labelText: 'Phone', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await authProvider.updateProfile(name: nameController.text.trim(), phone: phoneController.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: VibrantTheme.primaryGreen, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

}
