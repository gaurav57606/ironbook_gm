import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Reusable function to pick an image from the device's storage, 
/// copy it to the local Application Documents directory with a custom prefix,
/// and return the saved file's absolute destination path.
Future<String?> pickImageToDocuments(String prefix) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;
    final sourcePath = result.files.single.path;
    if (sourcePath == null) return null;

    final docsDir = await getApplicationDocumentsDirectory();
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
    final destPath = p.join(docsDir.path, fileName);
    
    await File(sourcePath).copy(destPath);
    return destPath;
  } catch (e) {
    return null;
  }
}
