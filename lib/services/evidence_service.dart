import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tipos de evidência. O nome do arquivo precisa bater com o que o trigger
/// `fuel_tests_before_insert` procura no Storage (proveta.jpg e fachada.jpg).
enum TipoEvidencia {
  proveta('proveta.jpg'),
  fachada('fachada.jpg'),
  cupom('cupom.jpg');

  const TipoEvidencia(this.arquivo);
  final String arquivo;
}

class EvidenciaException implements Exception {
  const EvidenciaException(this.mensagem);
  final String mensagem;

  @override
  String toString() => mensagem;
}

class EvidenceService {
  EvidenceService._();

  static const String _bucket = 'test-evidence';
  static final ImagePicker _picker = ImagePicker();
  static SupabaseClient get _supabase => Supabase.instance.client;

  /// Caminho no bucket: <user_id>/<test_id>/<tipo>.jpg
  static String caminhoDaEvidencia(
    String userId,
    String testId,
    TipoEvidencia tipo,
  ) =>
      '$userId/$testId/${tipo.arquivo}';

  /// Abre a câmera (a galeria fica bloqueada de propósito, contra fraude).
  /// Retorna null se o usuário cancelar ou se a câmera falhar.
  static Future<File?> tirarFotoDaCamera() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // JPEG
        maxWidth: 1600, // legível o bastante para conferir a escala da proveta
      );
      return foto == null ? null : File(foto.path);
    } catch (e) {
      debugPrint('Erro ao abrir a câmera: $e');
      return null;
    }
  }

  /// Envia a foto para o bucket privado e devolve o caminho.
  /// LANÇA [EvidenciaException] em caso de falha (nada de erro silencioso).
  /// Não usa upsert: uma evidência enviada não pode ser substituída depois.
  static Future<String> fazerUpload(
    File arquivo,
    String testId,
    TipoEvidencia tipo,
  ) async {
    final usuario = _supabase.auth.currentUser;
    if (usuario == null) {
      throw const EvidenciaException(
        'Sessão expirada. Faça login novamente.',
      );
    }

    final caminho = caminhoDaEvidencia(usuario.id, testId, tipo);

    try {
      await _supabase.storage.from(_bucket).upload(
            caminho,
            arquivo,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              cacheControl: '3600',
              upsert: false,
            ),
          );
      return caminho;
    } on StorageException catch (e) {
      throw EvidenciaException(
        'Falha ao enviar a foto (${tipo.name}): ${e.message}',
      );
    } catch (e) {
      throw EvidenciaException('Falha ao enviar a foto (${tipo.name}): $e');
    }
  }
}
