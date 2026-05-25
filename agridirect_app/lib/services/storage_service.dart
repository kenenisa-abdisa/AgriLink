import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import '../env_config.dart';

class StorageService {
  final _supabase = Supabase.instance.client;

  /// Uploads a product image and returns the public URL.
  /// Accepts [XFile] (cross-platform – works on Web, Android & iOS).
  Future<String> uploadProductImage(XFile imageFile, String userId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = p.extension(imageFile.name).isNotEmpty
          ? p.extension(imageFile.name)
          : '.jpg';
      final fileName = '$timestamp$extension';
      final path = 'products/$userId/$fileName';

      final bytes = await imageFile.readAsBytes();
      await _supabase.storage
          .from(EnvConfig.productImagesBucket)
          .uploadBinary(path, bytes);

      return _supabase.storage.from(EnvConfig.productImagesBucket).getPublicUrl(path);
    } catch (e) {
      rethrow;
    }
  }

  /// Uploads a profile image and returns the public URL.
  /// Accepts [XFile] (cross-platform – works on Web, Android & iOS).
  Future<String> uploadProfileImage(XFile imageFile, String userId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = p.extension(imageFile.name).isNotEmpty
          ? p.extension(imageFile.name)
          : '.jpg';
      final fileName = '$timestamp$extension';
      final path = 'profiles/$userId/$fileName';

      final bytes = await imageFile.readAsBytes();
      await _supabase.storage
          .from(EnvConfig.profileImagesBucket)
          .uploadBinary(path, bytes);

      return _supabase.storage.from(EnvConfig.profileImagesBucket).getPublicUrl(path);
    } catch (e) {
      rethrow;
    }
  }
}
