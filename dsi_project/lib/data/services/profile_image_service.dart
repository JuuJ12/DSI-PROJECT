import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dsi_project/core/config/supabase_config.dart';
import 'package:logger/logger.dart';

class ProfileImageService {
  final _picker = ImagePicker();
  final _supabase = Supabase.instance.client;
  final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
    ),
  );

  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        _logger.i('Nenhuma imagem selecionada');
        return null;
      }

      _logger.i('Imagem selecionada: ${pickedFile.path}');
      final file = File(pickedFile.path);

      _logger.i('Comprimindo imagem...');
      final compressedFile = await _compressImage(file);
      _logger.i('Imagem comprimida com sucesso');

      return compressedFile;
    } catch (e, stackTrace) {
      _logger.e('Erro ao selecionar imagem', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<File> _compressImage(File file) async {
    final bytes = await file.readAsBytes();
    var image = img.decodeImage(bytes);

    if (image == null) return file;

    // Comprimir até ficar menor que 1MB
    int quality = 85;
    List<int> compressed;

    do {
      compressed = img.encodeJpg(image, quality: quality);
      if (compressed.length < 1024 * 1024 || quality <= 10) break;
      quality -= 10;
    } while (true);

    final compressedFile = File('${file.path}_compressed.jpg');
    await compressedFile.writeAsBytes(compressed);
    return compressedFile;
  }

  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      _logger.i('Iniciando upload para userId: $userId');
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      _logger.d('Nome do arquivo: $fileName');

      await _supabase.storage
          .from(SupabaseConfig.profileImagesBucket)
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      _logger.i('Upload concluído com sucesso');

      final imageUrl = _supabase.storage
          .from(SupabaseConfig.profileImagesBucket)
          .getPublicUrl(fileName);

      _logger.i('URL gerada: $imageUrl');
      return imageUrl;
    } catch (e, stackTrace) {
      _logger.e('Erro no upload', error: e, stackTrace: stackTrace);
      throw Exception('Erro ao fazer upload da imagem: $e');
    }
  }

  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      _logger.i('Deletando imagem: $imageUrl');
      final uri = Uri.parse(imageUrl);
      final path = uri.pathSegments.last;

      await _supabase.storage.from(SupabaseConfig.profileImagesBucket).remove([
        path,
      ]);
      _logger.i('Imagem deletada com sucesso');
    } catch (e, stackTrace) {
      _logger.e('Erro ao deletar imagem', error: e, stackTrace: stackTrace);
      throw Exception('Erro ao deletar imagem: $e');
    }
  }
}
