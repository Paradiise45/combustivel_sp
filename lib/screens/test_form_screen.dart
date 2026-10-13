import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/posto_model.dart';
import '../services/evidence_service.dart';
import '../utils/ethanol_calculator.dart';
import '../widgets/photo_slot.dart';
import '../widgets/status_visual.dart';

class TestFormScreen extends StatefulWidget {
  final Posto posto;
  const TestFormScreen({super.key, required this.posto});

  @override
  State<TestFormScreen> createState() => _TestFormScreenState();
}

class _TestFormScreenState extends State<TestFormScreen> {
  final _volumeController = TextEditingController();
  final _densidadeController = TextEditingController();

  // Regra vigente (buscada no servidor; se falhar, usa o padrão embutido).
  ReferenciaEtanol _referencia = ReferenciaEtanol.padrao;
  bool _referenciaDoServidor = false;

  ResultadoProveta? _resultado;
  bool _enviando = false;

  // Provas fotográficas
  File? _fotoProveta;
  File? _fotoFachada;
  File? _fotoCupom;

  @override
  void initState() {
    super.initState();
    _carregarReferencia();
  }

  @override
  void dispose() {
    _volumeController.dispose();
    _densidadeController.dispose();
    super.dispose();
  }

  /// Aceita vírgula ou ponto (teclado pt-BR). Retorna null se não for número.
  static double? _lerNumero(String texto) =>
      double.tryParse(texto.trim().replaceAll(',', '.'));

  static String _fmt(double v, [int casas = 1]) =>
      v.toStringAsFixed(casas).replaceAll('.', ',');

  Future<void> _carregarReferencia() async {
    try {
      final resposta = await Supabase.instance.client
          .rpc('referencia_vigente', params: {'p_fuel_type': 'Gasolina C'});
      if (resposta is List && resposta.isNotEmpty) {
        final ref = ReferenciaEtanol.fromJson(
          Map<String, dynamic>.from(resposta.first as Map),
        );
        if (!mounted) return;
        setState(() {
          _referencia = ref;
          _referenciaDoServidor = true;
        });
        _recalcular();
      }
    } catch (e) {
      debugPrint('Não foi possível buscar a regra vigente: $e');
    }
  }

  void _recalcular() {
    final volume = _lerNumero(_volumeController.text);
    setState(() {
      _resultado =
          volume == null ? null : EthanolCalculator.calcular(volume, _referencia);
    });
  }

  void _aviso(String mensagem, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? Colors.red : null,
      ),
    );
  }

  String _mensagemDeErro(Object e) {
    if (e is EvidenciaException) return e.mensagem;
    if (e is PostgrestException) return e.message;
    if (e is StorageException) return e.message;
    return 'Erro inesperado: $e';
  }

  Future<void> _submeter() async {
    if (_enviando) return;

    final resultado = _resultado;
    final volume = _lerNumero(_volumeController.text);
    if (resultado == null || !resultado.valido || volume == null) {
      _aviso('Insira um volume válido (50 a 100 mL).');
      return;
    }
    if (_fotoProveta == null || _fotoFachada == null) {
      _aviso('A foto da proveta e a da fachada são obrigatórias.');
      return;
    }

    double? densidade;
    final textoDensidade = _densidadeController.text.trim();
    if (textoDensidade.isNotEmpty) {
      densidade = _lerNumero(textoDensidade);
      if (densidade == null || densidade <= 0.6 || densidade >= 1.0) {
        _aviso('Densidade inválida. Exemplo: 0,745');
        return;
      }
    }

    setState(() => _enviando = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw const EvidenciaException('Sessão expirada. Faça login novamente.');
      }

      final posto = widget.posto;

      // 1. Garante que a estação existe no banco (id do OSM -> UUID).
      final stationId = await supabase.rpc('upsert_station', params: {
        'p_osm_id': posto.id,
        'p_name': posto.nome,
        'p_brand': posto.bandeira,
        'p_address': posto.endereco,
        'p_lat': posto.latitude,
        'p_lon': posto.longitude,
      }) as String;

      // 2. O ID do teste nasce aqui, para as fotos já irem para a pasta certa.
      //    Um ID novo a cada tentativa: foto enviada nunca é sobrescrita.
      final testId = const Uuid().v4();

      // 3. Fotos primeiro. Se alguma falhar, lança erro e NADA é gravado no teste.
      await EvidenceService.fazerUpload(
          _fotoProveta!, testId, TipoEvidencia.proveta);
      await EvidenceService.fazerUpload(
          _fotoFachada!, testId, TipoEvidencia.fachada);
      if (_fotoCupom != null) {
        await EvidenceService.fazerUpload(
            _fotoCupom!, testId, TipoEvidencia.cupom);
      }

      // 4. Registro do teste. Porcentagem e status são calculados pelo
      //    servidor (trigger), que também confere se as fotos existem.
      await supabase.from('fuel_tests').insert({
        'id': testId,
        'station_id': stationId,
        'user_id': user.id,
        'fuel_type': 'Gasolina C',
        'method': 'Proveta',
        'water_volume': volume,
        'density': densidade,
      });

      if (!mounted) return;
      _aviso('Teste enviado para auditoria com sucesso!');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _aviso(_mensagemDeErro(e), erro: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final resultado = _resultado;
    final corResultado = resultado?.status?.cor ?? Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Teste de Proveta',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: cores.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.posto.nome,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: cores.primary,
              ),
            ),
            Text(
              widget.posto.endereco,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 30),

            // CAMPO DE CÁLCULO
            const Text(
              'Volume da fase aquosa (mL)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _volumeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              onChanged: (_) => _recalcular(),
              decoration: InputDecoration(
                hintText: 'Ex: 66,5',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // RESULTADO AO VIVO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: resultado?.status != null
                    ? corResultado.withOpacity(0.10)
                    : Colors.grey.shade100,
                border: Border.all(
                  color: resultado?.status != null
                      ? corResultado
                      : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Etanol na gasolina:',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  Text(
                    (resultado?.valido ?? false)
                        ? '${_fmt(resultado!.percentual)}%'
                        : '--',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: corResultado,
                    ),
                  ),
                  Text(
                    resultado?.mensagem ?? 'Aguardando medição...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: corResultado,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Regra vigente: ${_fmt(_referencia.min)}–${_fmt(_referencia.max)}% '
              'de etanol na gasolina C'
              '${_referenciaDoServidor ? '' : ' (padrão do app; não foi possível consultar o servidor)'}. '
              'Resultado indicativo: o servidor recalcula ao enviar e o teste só '
              'é publicado depois da análise das fotos por um moderador.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 32),
            const Text(
              'Densidade a 20 °C (opcional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _densidadeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                hintText: 'Ex: 0,745',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // PROVAS FOTOGRÁFICAS
            const Text(
              'Evidências fotográficas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            PhotoSlot(
              titulo: '1. Foto da proveta (obrigatório)',
              onFotoSelecionada: (foto) => setState(() => _fotoProveta = foto),
            ),
            const SizedBox(height: 16),
            PhotoSlot(
              titulo: '2. Foto da fachada (obrigatório)',
              onFotoSelecionada: (foto) => setState(() => _fotoFachada = foto),
            ),
            const SizedBox(height: 16),
            PhotoSlot(
              titulo: '3. Cupom fiscal (opcional)',
              onFotoSelecionada: (foto) => setState(() => _fotoCupom = foto),
            ),

            const SizedBox(height: 40),

            // BOTÃO DE ENVIO
            _enviando
                ? Center(child: CircularProgressIndicator(color: cores.primary))
                : SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _submeter,
                      child: const Text(
                        'Enviar para auditoria',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
