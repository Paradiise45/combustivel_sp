import 'dart:io';
import 'package:flutter/material.dart';
import '../services/evidence_service.dart';

class PhotoSlot extends StatefulWidget {
  final String titulo; // Ex: "Foto da Proveta (Obrigatório)"
  final Function(File?) onFotoSelecionada; // Avisa o formulário quando a foto é tirada

  const PhotoSlot({super.key, required this.titulo, required this.onFotoSelecionada});

  @override
  _PhotoSlotState createState() => _PhotoSlotState();
}

class _PhotoSlotState extends State<PhotoSlot> {
  File? _foto;
  bool _carregando = false;

  Future<void> _tirarFoto() async {
    setState(() => _carregando = true);
    
    // Chama o serviço que criámos no Passo 2
    final fotoTirada = await EvidenceService.tirarFotoDaCamera();
    
    if (fotoTirada != null) {
      setState(() => _foto = fotoTirada);
      widget.onFotoSelecionada(_foto); // Envia o ficheiro para o formulário principal
    }
    
    setState(() => _carregando = false);
  }

  void _removerFoto() {
    setState(() => _foto = null);
    widget.onFotoSelecionada(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _foto == null ? _tirarFoto : null, // Só deixa clicar se não houver foto
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 140, // Altura do retângulo da foto
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400, width: 1.5, style: BorderStyle.solid),
            ),
            child: _carregando
                ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                : _foto != null
                    // Se a foto existir, mostra a miniatura
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_foto!, fit: BoxFit.cover),
                            // Botão vermelho de "X" no canto superior direito para apagar
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _removerFoto,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    // Se não houver foto, mostra o ícone da câmara
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey.shade500),
                          const SizedBox(height: 8),
                          Text('Tocar para fotografar', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                        ],
                      ),
          ),
        ),
      ],
    );
  }
}
