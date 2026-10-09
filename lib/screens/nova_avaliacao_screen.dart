import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/posto_model.dart';
import '../models/teste_combustivel_model.dart';
import '../services/posto_repository.dart';

enum TipoRegistro { teste, avaliacao }

class NovaAvaliacaoScreen extends StatefulWidget {
  const NovaAvaliacaoScreen({super.key, this.postoInicial});
  final Posto? postoInicial;

  @override
  State<NovaAvaliacaoScreen> createState() => _NovaAvaliacaoScreenState();
}

class _NovaAvaliacaoScreenState extends State<NovaAvaliacaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = PostoRepository.instance;
  final _teorCtrl = TextEditingController();
  final _densCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();
  final _comentarioCtrl = TextEditingController();

  late String? _postoId = widget.postoInicial?.id;
  TipoRegistro _tipo = TipoRegistro.teste;
  Combustivel _combustivel = Combustivel.gasolinaC;
  FonteTeste _fonte = FonteTeste.proveta;
  int _nota = 0;

  @override
  void dispose() {
    _teorCtrl.dispose();
    _densCtrl.dispose();
    _obsCtrl.dispose();
    _nomeCtrl.dispose();
    _comentarioCtrl.dispose();
    super.dispose();
  }

  double? _parse(String? s) =>
      double.tryParse((s ?? '').trim().replaceAll(',', '.'));

  String? _validarObrigatorio(String? v, double min, double max, String nome) {
    final n = _parse(v);
    if (n == null) return 'Informe $nome';
    if (n < min || n > max) {
      return 'Valor entre ${min.toString().replaceAll('.', ',')} e '
          '${max.toString().replaceAll('.', ',')}';
    }
    return null;
  }

  String? _validarOpcional(String? v, double min, double max) {
    if (v == null || v.trim().isEmpty) return null;
    final n = _parse(v);
    if (n == null || n < min || n > max) {
      return 'Valor entre ${min.toString().replaceAll('.', ',')} e '
          '${max.toString().replaceAll('.', ',')}';
    }
    return null;
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    if (_tipo == TipoRegistro.avaliacao && _nota == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha uma nota de 1 a 5 estrelas.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final nome =
        _nomeCtrl.text.trim().isEmpty ? 'Anônimo' : _nomeCtrl.text.trim();

    if (_tipo == TipoRegistro.teste) {
      _repo.adicionarTeste(
        _postoId!,
        TesteCombustivel(
          id: id,
          data: DateTime.now(),
          combustivel: _combustivel,
          percentualEtanol: _parse(_teorCtrl.text)!,
          densidade: _parse(_densCtrl.text),
          fonte: _fonte,
          observacao:
              _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
          enviadoPor: nome,
        ),
      );
    } else {
      _repo.adicionarAvaliacao(
        _postoId!,
        Avaliacao(
          id: id,
          autor: nome,
          nota: _nota,
          comentario: _comentarioCtrl.text.trim(),
          data: DateTime.now(),
        ),
      );
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Registro enviado. Obrigado!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo teste ou avaliação')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _postoId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Posto',
                border: OutlineInputBorder(),
              ),
              items: _repo.postos
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text('${p.nome} – ${p.bairro}',
                          overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _postoId = v),
              validator: (v) => v == null ? 'Selecione o posto' : null,
            ),
            const SizedBox(height: 16),
            SegmentedButton<TipoRegistro>(
              segments: const [
                ButtonSegment(
                  value: TipoRegistro.teste,
                  icon: Icon(Icons.science_outlined),
                  label: Text('Teste'),
                ),
                ButtonSegment(
                  value: TipoRegistro.avaliacao,
                  icon: Icon(Icons.star_outline),
                  label: Text('Avaliação'),
                ),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
            ),
            const SizedBox(height: 20),
            if (_tipo == TipoRegistro.teste)
              ..._camposTeste()
            else
              ..._camposAvaliacao(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomeCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Seu nome (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _salvar,
              icon: const Icon(Icons.send),
              label: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _camposTeste() {
    final gasolina = _combustivel == Combustivel.gasolinaC;
    final decimalFormatter =
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));
    return [
      DropdownButtonFormField<Combustivel>(
        value: _combustivel,
        decoration: const InputDecoration(
          labelText: 'Combustível testado',
          border: OutlineInputBorder(),
        ),
        items: Combustivel.values
            .map((c) => DropdownMenuItem(value: c, child: Text(c.rotulo)))
            .toList(),
        onChanged: (v) => setState(() => _combustivel = v!),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<FonteTeste>(
        value: _fonte,
        decoration: const InputDecoration(
          labelText: 'Tipo de teste',
          border: OutlineInputBorder(),
        ),
        items: FonteTeste.values
            .map((f) => DropdownMenuItem(value: f, child: Text(f.rotulo)))
            .toList(),
        onChanged: (v) => setState(() => _fonte = v!),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _teorCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [decimalFormatter],
        decoration: InputDecoration(
          labelText: gasolina
              ? 'Etanol na gasolina (% volumétrica)'
              : 'Teor alcoólico (%)',
          helperText: gasolina && _fonte == FonteTeste.proveta
              ? 'Proveta: (volume da fase aquosa − 50 mL) × 2 + 1'
              : null,
          helperMaxLines: 2,
          border: const OutlineInputBorder(),
        ),
        validator: (v) => _validarObrigatorio(v, 0, 100, 'o percentual'),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _densCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [decimalFormatter],
        decoration: const InputDecoration(
          labelText: 'Densidade a 20 °C, g/cm³ (opcional)',
          hintText: 'Ex.: 0,745',
          border: OutlineInputBorder(),
        ),
        validator: (v) => _validarOpcional(v, 0.6, 1.0),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _obsCtrl,
        maxLines: 3,
        maxLength: 300,
        decoration: InputDecoration(
          labelText: 'Observações (opcional)',
          helperText: _fonte == FonteTeste.laboratorio
              ? 'Cite o laboratório/laudo, se houver.'
              : null,
          border: const OutlineInputBorder(),
        ),
      ),
    ];
  }

  List<Widget> _camposAvaliacao() {
    return [
      Text('Sua nota', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 4),
      Row(
        children: List.generate(5, (i) {
          final marcada = i < _nota;
          return IconButton(
            iconSize: 38,
            onPressed: () => setState(() => _nota = i + 1),
            icon: Icon(
              marcada ? Icons.star : Icons.star_border,
              color: const Color(0xFFF2B600),
            ),
          );
        }),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: _comentarioCtrl,
        maxLines: 4,
        maxLength: 300,
        decoration: const InputDecoration(
          labelText: 'Comentário (opcional)',
          border: OutlineInputBorder(),
        ),
      ),
    ];
  }
}