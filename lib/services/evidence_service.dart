import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EvidenceService {
  static final _picker = ImagePicker();
  static final _supabase = Supabase.instance.client;

  // 1. Abre a câmara e tira a foto (Bloqueia o uso da galeria para evitar fraudes)
  static Future<File?> tirarFotoDaCamera() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, // Comprime a 70% para o upload ser super rápido
        maxWidth: 1024,   // Evita imagens gigantescas de 40 Megapixels
      );
      
      if (foto != null) {
        return File(foto.path);
      }
    } catch (e) {
      print('Erro ao abrir câmara: $e');
    }
    return null;
  }

  // 2. Envia a foto recém-tirada para o cofre (Bucket) no Supabase
  static Future<String?> fazerUpload(File arquivo, String testId, String tipoDaFoto) async {
    try {
      final usuario = _supabase.auth.currentUser;
      if (usuario == null) throw Exception('Utilizador não autenticado.');

      // Monta o caminho exato dentro do cofre. 
      // Exemplo: 123-uuid / 456-uuid / proveta.jpg
      final caminhoNoCofre = '${usuario.id}/$testId/$tipoDaFoto.jpg';

      // Faz o upload real para o Supabase
      await _supabase.storage.from('test-evidence').upload(
        caminhoNoCofre,
        arquivo,
        fileOptions: const FileOptions(
          cacheControl: '3600', 
          upsert: true // Se já existir uma foto com esse nome, substitui (útil se o utilizador quiser refazer a foto)
        ),
      );

      // Retorna o caminho para podermos guardar na base de dados depois
      return caminhoNoCofre;
      
    } catch (e) {
      print('Erro ao fazer upload da evidência: $e');
      return null;
    }
  }
}
