import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class PhotoService {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();
  static const _bucket = 'member-photos';

  /// Pick image from gallery or camera, upload to Supabase, return public URL.
  /// Returns null if user cancels or if upload fails.
  Future<String?> pickAndUpload({
    required String memberId,
    required ImageSource source,
    String? existingUrl,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (file == null) return null;

      if (existingUrl != null) _deleteByUrl(existingUrl);

      final ext = p.extension(file.path).toLowerCase().replaceAll('.', '');
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final storagePath =
          'members/$memberId/photo_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final bytes = await File(file.path).readAsBytes();

      await _supabase.storage.from(_bucket).uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(contentType: mimeType, upsert: false),
      );

      return _supabase.storage.from(_bucket).getPublicUrl(storagePath);
    } catch (e) {
      debugPrint('[PhotoService] upload failed: $e');
      return null;
    }
  }

  /// Delete a photo by its public URL. Silent — never throws.
  Future<void> deletePhoto(String? photoUrl) async {
    if (photoUrl == null || photoUrl.isEmpty) return;
    _deleteByUrl(photoUrl);
  }

  void _deleteByUrl(String publicUrl) async {
    try {
      final uri = Uri.parse(publicUrl);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(_bucket);
      if (bucketIndex == -1) return;
      final storagePath = segments.sublist(bucketIndex + 1).join('/');
      await _supabase.storage.from(_bucket).remove([storagePath]);
    } catch (e) {
      debugPrint('[PhotoService] delete failed (non-critical): $e');
    }
  }
}

final photoService = PhotoService();
