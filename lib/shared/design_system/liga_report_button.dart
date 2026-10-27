import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../models/ai_report.dart';
import '../services/app_repository.dart';
import 'liga_widgets.dart';

/// Bandeira no topo das telas com IA: abre o "Avisar um problema" para a
/// criança ou o responsável sinalizar uma resposta imprópria ou errada.
/// A política de conteúdo gerado por IA do Google Play exige esse caminho.
class LigaReportAiButton extends StatelessWidget {
  const LigaReportAiButton({super.key, required this.module, this.reference});

  /// Chave da tela (`foto`, `leitura`, `matematica`...).
  final String module;

  /// Devolve o id do conteúdo que está na tela, se houver um.
  final ValueGetter<String?>? reference;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Avisar um problema',
      icon: const Icon(Icons.flag_rounded),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) =>
            _ReportSheet(module: module, reference: reference?.call()),
      ),
    );
  }
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.module, this.reference});

  final String module;
  final String? reference;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _comment = TextEditingController();
  AiReportReason? _reason;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await AppRepository.instance.reportAiContent(
        AiReport(
          module: widget.module,
          reason: reason,
          comment: _comment.text,
          reference: widget.reference,
        ),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Obrigado por avisar! A equipe vai olhar isso.'),
          ),
        );
    } on AppRepositoryException catch (error) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Avisar um problema', style: text.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Algo estranho na resposta da IA? Conte para a gente. '
              'Se algo te deixou desconfortável, chame também um adulto.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 12),
            RadioGroup<AiReportReason>(
              groupValue: _reason,
              onChanged: (value) => setState(() => _reason = value),
              child: Column(
                children: [
                  for (final reason in AiReportReason.values)
                    RadioListTile<AiReportReason>(
                      value: reason,
                      title: Text(reason.label),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            TextField(
              controller: _comment,
              maxLength: 500,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: 'Quer contar mais? (opcional)',
                helperText: 'Não escreva nomes, telefone ou endereço.',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: LigaColors.actionCoral),
              ),
            ],
            const SizedBox(height: 16),
            LigaActionButton(
              label: _sending ? 'Enviando...' : 'Enviar aviso',
              icon: Icons.flag_rounded,
              color: LigaColors.actionCoral,
              onPressed: _reason == null || _sending ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}
