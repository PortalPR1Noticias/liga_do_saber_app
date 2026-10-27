import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/services/app_repository.dart';
import '../../legal/presentation/legal_document_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';

/// Pergunta de adulto antes da Área dos responsáveis, para a criança não
/// mexer sozinha em autorizações e na exclusão da conta (pedido da política
/// Famílias do Google Play). Devolve `true` se a resposta estiver certa.
Future<bool> showParentGate(BuildContext context) async {
  final random = math.Random();
  final a = 6 + random.nextInt(4);
  final b = 6 + random.nextInt(4);
  final controller = TextEditingController();
  final passed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Só para adultos'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quanto é $a × $b?'),
          TextField(
            key: const Key('parentGateAnswer'),
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(int.tryParse(controller.text) == a * b),
          child: const Text('Entrar'),
        ),
      ],
    ),
  );
  controller.dispose();
  return passed ?? false;
}

class ParentAreaScreen extends StatefulWidget {
  const ParentAreaScreen({super.key});

  /// Abre a área depois da pergunta de adulto.
  static Future<void> open(BuildContext context) async {
    if (!await showParentGate(context) || !context.mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ParentAreaScreen()));
  }

  @override
  State<ParentAreaScreen> createState() => _ParentAreaScreenState();
}

class _ParentAreaScreenState extends State<ParentAreaScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on AppRepositoryException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setAiConsent(bool allowed) {
    return _run(() async {
      await AppRepository.instance.setAiConsent(allowed);
      _showMessage(allowed ? 'Foto + IA liberada.' : 'Foto + IA bloqueada.');
    });
  }

  Future<void> _exportData() {
    return _run(() async {
      final data = await AppRepository.instance.exportMyData();
      if (!mounted) return;
      final json = const JsonEncoder.withIndent('  ').convert(data);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cópia dos dados'),
          content: SingleChildScrollView(
            child: SelectableText(
              json,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: json));
                if (context.mounted) Navigator.of(context).pop();
                _showMessage('Dados copiados. Cole num e-mail ou arquivo.');
              },
              child: const Text('Copiar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteAccountDialog(),
    );
    if (confirmed != true || !mounted) return;
    await _run(() async {
      await AppRepository.instance.deleteAccount();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(OnboardingScreen.routeName, (_) => false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Conta e dados excluídos.')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsible = AppRepository.instance.responsible;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Área dos responsáveis')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: AbsorbPointer(
            absorbing: _busy,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                LigaPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(responsible.name, style: textTheme.titleLarge),
                      Text(responsible.email, style: textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                LigaPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        key: const Key('aiConsentSwitch'),
                        contentPadding: EdgeInsets.zero,
                        value: responsible.aiConsent,
                        onChanged: _busy ? null : _setAiConsent,
                        title: Text(
                          'Permitir a Foto + IA',
                          style: textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        'A foto da lição é enviada para a OpenAI (EUA) só '
                        'para gerar a explicação. A foto não é guardada; a '
                        'explicação fica salva por até 12 meses. Você pode '
                        'desligar quando quiser.',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                LigaActionButton(
                  label: 'Baixar cópia dos dados',
                  icon: Icons.download_rounded,
                  color: LigaColors.primaryBlue,
                  onPressed: _busy ? null : _exportData,
                ),
                const SizedBox(height: 12),
                for (final document in LegalDocument.values) ...[
                  LigaActionButton(
                    label: document.title,
                    icon: Icons.description_rounded,
                    color: LigaColors.cyanGlow,
                    onPressed: () =>
                        LegalDocumentScreen.open(context, document),
                  ),
                  const SizedBox(height: 12),
                ],
                LigaActionButton(
                  label: 'Excluir conta e dados',
                  icon: Icons.delete_forever_rounded,
                  color: LigaColors.actionCoral,
                  onPressed: _busy ? null : _deleteAccount,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Confirmação da exclusão: só libera o botão depois de digitar EXCLUIR.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final confirmed = _controller.text.trim().toUpperCase() == 'EXCLUIR';
    return AlertDialog(
      title: const Text('Excluir conta?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Isso apaga para sempre a conta, os perfis das crianças, o '
            'progresso, os textos e as explicações. Não dá para desfazer.',
          ),
          const SizedBox(height: 12),
          const Text('Digite EXCLUIR para confirmar.'),
          TextField(
            key: const Key('deleteAccountConfirm'),
            controller: _controller,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: LigaColors.actionCoral,
          ),
          onPressed: confirmed ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Excluir'),
        ),
      ],
    );
  }
}
