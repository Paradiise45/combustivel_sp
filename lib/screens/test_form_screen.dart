import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../models/posto_model.dart';
import '../widgets/photo_slot.dart';
import '../utils/ethanol_calculator.dart';
import '../services/evidence_service.dart';

class TestFormScreen extends StatefulWidget {
  final Posto posto;
  const TestFormScreen({super.key, required this.posto});

  @override
  _TestFormScreenState createState() => _TestFormScreenState();
}

class _TestFormScreenState extends State<TestFormScreen> {
  final _volumeController = TextEditingController();
  final _densidadeController = TextEditingController();
  
  double _percentualCalculado = 0.0;
  bool _testeAprovado = false;
  String _mensagemCalculo = 'Aguardando medição...';
  bool _calculoValido = false;
  bool _enviando = false;

  // Variáveis para guardar as provas fotográficas
  File? _fotoProveta;
  File? _fotoCupao;
  File? _fotoFachada;

  // Função disparada a cada letra que o utilizador digita no campo de Volume
  void _aoMudarVolume(String valor) {
    if (valor.isEmpty) {
      setState(() => _calculoValido = false);
      return;
    }

    // Troca vírgula por ponto (teclados pt-BR) e converte para número
    final volume = double.tryParse(valor.replaceAll(',', '.'));
    if (volume == null) return;

    final resultado = EthanolCalculator.calcular(volume);
    
    setState(() {
      _calculoValido = resultado['valido'];
      _percentualCalculado = resultado['percentagem'];
      _testeAprovado = resultado['aprovado'];
      _mensagemCalculo = resultado['msg'];
    });
  }

  Future<void> _submeterTeste() async {
    // Validações antes de deixar enviar
    if (!_calculoValido) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insira um volume válido primeiro.')));
      return;
    }
    if (_fotoProveta == null || _fotoFachada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A foto da Proveta e da Fachada são obrigatórias.')));
      return;
    }

    setState(() => _enviando = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Não autenticado');

      // 1. Gera um ID provisório para o teste (para as fotos saberem a que teste pertencem)
      final testId = Supabase.instance.client.functions.invoke(''); // Trick para gerar UUID não é o melhor, vamos usar um insert com select
      
      // Criamos o registo na base de dados (ficando com o estado 'pendente' garantido pela RLS)
      final resposta = await Supabase.instance.client.from('fuel_tests').insert({
        'station_id': widget.posto.id,
        'user_id': user.id,
        'fuel_type': 'Gasolina C',
        'method': 'Proveta',
        'water_volume': double.parse(_volumeController.text.replaceAll(',', '.')),
        'density': _densidadeController.text.isNotEmpty ? double.parse(_densidadeController.text.replaceAll(',', '.')) : null,
        'ethanol_percent': _percentualCalculado,
        'conformity': _testeAprovado,
      }).select('id').single();

      final idDoTeste = resposta['id'];

      // 2. Envia as fotos para o Storage com o ID real do teste!
      await EvidenceService.fazerUpload(_fotoProveta!, idDoTeste, 'proveta');
      await EvidenceService.fazerUpload(_fotoFachada!, idDoTeste, 'fachada');
      if (_fotoCupao != null) {
        await EvidenceService.fazerUpload(_fotoCupao!, idDoTeste, 'cupao');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Teste submetido para auditoria com sucesso!'),
        backgroundColor: Colors.green,
      ));
      context.pop(); // Volta ao mapa

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao submeter: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Teste de Proveta', style: TextStyle(fontWeight: FontWeight.bold))),
      backgroundColor: cores.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.posto.nome, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cores.primary)),
            Text(widget.posto.endereco, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 30),

            // O CAMPO DE CÁLCULO
            const Text('Volume da Fase Aquosa (mL)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _volumeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: _aoMudarVolume,
              decoration: InputDecoration(
                hintText: 'Ex: 63,5',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            
            // O RESULTADO AO VIVO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _calculoValido 
                    ? (_testeAprovado ? Colors.green.shade50 : Colors.red.shade50) 
                    : Colors.grey.shade100,
                border: Border.all(
                  color: _calculoValido ? (_testeAprovado ? Colors.green : Colors.red) : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text('Etanol na Gasolina:', style: TextStyle(color: Colors.grey.shade700)),
                  Text(
                    _calculoValido ? '${_percentualCalculado.toStringAsFixed(1)}%' : '--', 
                    style: TextStyle(
                      fontSize: 32, 
                      fontWeight: FontWeight.bold,
                      color: _calculoValido ? (_testeAprovado ? Colors.green : Colors.red) : Colors.grey,
                    )
                  ),
                  Text(
                    _mensagemCalculo, 
                    style: TextStyle(fontWeight: FontWeight.bold, color: _calculoValido ? (_testeAprovado ? Colors.green : Colors.red) : Colors.grey)
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Text('Densidade a 20 °C (Opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _densidadeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Ex: 0,745',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // AS PROVAS FOTOGRÁFICAS USANDO O NOSSO WIDGET
            const Text('Evidências Fotográficas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            PhotoSlot(
              titulo: '1. Foto da Proveta (Obrigatório)',
              onFotoSelecionada: (foto) => setState(() => _fotoProveta = foto),
            ),
            const SizedBox(height: 16),
            PhotoSlot(
              titulo: '2. Foto da Fachada (Obrigatório)',
              onFotoSelecionada: (foto) => setState(() => _fotoFachada = foto),
            ),
            const SizedBox(height: 16),
            PhotoSlot(
              titulo: '3. Cupão Fiscal (Opcional)',
              onFotoSelecionada: (foto) => setState(() => _fotoCupao = foto),
            ),

            const SizedBox(height: 40),
            
            // BOTÃO DE ENVIO
            _enviando
                ? Center(child: CircularProgressIndicator(color: cores.primary))
                : SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _submeterTeste,
                      child: const Text('Submeter para Auditoria', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
