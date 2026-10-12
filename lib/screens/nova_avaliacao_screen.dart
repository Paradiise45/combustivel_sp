import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/posto_model.dart';

class NovaAvaliacaoScreen extends StatefulWidget {
  final Posto posto;

  const NovaAvaliacaoScreen({super.key, required this.posto});

  @override
  _NovaAvaliacaoScreenState createState() => _NovaAvaliacaoScreenState();
}

class _NovaAvaliacaoScreenState extends State<NovaAvaliacaoScreen> {
  String _combustivelSelecionado = 'Gasolina Comum';
  bool _conforme = true;
  final _comentarioController = TextEditingController();
  bool _salvando = false;

  Future<void> _salvarAvaliacao() async {
    setState(() => _salvando = true);
    try {
      final usuario = Supabase.instance.client.auth.currentUser;
      if (usuario == null) throw Exception('Sessão expirada. Faça login novamente.');

      // Comando que envia a avaliação real para a tabela do Supabase
      await Supabase.instance.client.from('avaliacoes').insert({
        'posto_id': widget.posto.id,
        'posto_nome': widget.posto.nome,
        'posto_endereco': widget.posto.endereco,
        'usuario_id': usuario.id,
        'combustivel': _combustivelSelecionado,
        'conforme': _conforme,
        'comentario': _comentarioController.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teste Químico registrado com sucesso!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Volta para o mapa após salvar
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Teste'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF1E1E1E),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.posto.nome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber)),
            Text(widget.posto.endereco, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 30),

            const Text('Combustível Analisado', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              dropdownColor: const Color(0xFF2C2C2C),
              value: _combustivelSelecionado,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: ['Gasolina Comum', 'Gasolina Aditivada', 'Etanol', 'Diesel']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => _combustivelSelecionado = val!),
            ),
            const SizedBox(height: 24),

            const Text('Resultado do Teste (Proveta)', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _conforme = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _conforme ? Colors.green.withOpacity(0.2) : const Color(0xFF2C2C2C),
                        border: Border.all(color: _conforme ? Colors.green : Colors.transparent, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Text('CONFORME', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _conforme = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: !_conforme ? Colors.red.withOpacity(0.2) : const Color(0xFF2C2C2C),
                        border: Border.all(color: !_conforme ? Colors.red : Colors.transparent, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Text('FRAUDE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text('Observações (Opcional)', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _comentarioController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ex: Etanol na gasolina bateu 35%. Água no etanol.',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 40),

            _salvando
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _salvarAvaliacao,
                      child: const Text('Registrar Teste', style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
