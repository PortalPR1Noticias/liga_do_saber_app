import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/models/account_role.dart';
import '../../../shared/services/app_repository.dart';
import '../../auth/presentation/liga_text_field.dart';

/// O responsável escolhe quais professores acompanham a criança escolhida:
/// pelo e-mail do professor e com o nome que a criança vai ter para ele.
/// Cada liberação gera um código que o responsável manda ao professor; é o
/// código, não o e-mail, que dá acesso (o e-mail não é confirmado).
/// Cada liberação é um consentimento do responsável (LGPD art. 14) e pode
/// ser removida quando ele quiser.
class TeacherLinksScreen extends StatefulWidget {
  const TeacherLinksScreen({super.key});

  @override
  State<TeacherLinksScreen> createState() => _TeacherLinksScreenState();
}

class _TeacherLinksScreenState extends State<TeacherLinksScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  late final _nameController = TextEditingController(
    text: AppRepository.instance.childProfile.nickname,
  );
  late Future<List<TeacherLink>> _links = AppRepository.instance
      .loadTeacherLinks();
  bool _consent = false;
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      _showMessage(done);
      setState(() {
        _links = AppRepository.instance.loadTeacherLinks();
      });
    } on AppRepositoryException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_consent) {
      _showMessage('Marque a autorização para liberar o professor.');
      return;
    }
    await _run(() async {
      await AppRepository.instance.addTeacherLink(
        teacherEmail: _emailController.text,
        childName: _nameController.text,
      );
      _emailController.clear();
      _consent = false;
    }, 'Professor liberado. Mande o código para ele.');
  }

  Future<void> _copyCode(TeacherLink link) async {
    await Clipboard.setData(
      ClipboardData(
        text:
            'Olá! Para acompanhar ${link.childName} na Liga do Saber, entre '
            'no app em "Sou professor" e digite o código ${link.code}.',
      ),
    );
    _showMessage(
      'Convite copiado. Cole no WhatsApp ou no e-mail do professor.',
    );
  }

  Future<void> _remove(TeacherLink link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover professor?'),
        content: Text(
          '${link.teacherEmail} deixa de ver o desempenho de '
          '${link.childName}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(
      () => AppRepository.instance.removeTeacherLink(link.id),
      'Professor removido.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = AppRepository.instance.childProfile;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('Professores de ${child.nickname}')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: AbsorbPointer(
            absorbing: _busy,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Quem acompanha ${child.nickname}',
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Depois de liberar, mande o código ao professor. Ele entra '
                  'com a conta dele (Sou professor) e digita o código. Ele vê '
                  'só o resumo '
                  'de desempenho: nível, dias de prática, aproveitamento por '
                  'matéria e os acertos na Revanche da prova. Textos, fotos e '
                  'provas continuam só com você.',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                FutureBuilder<List<TeacherLink>>(
                  future: _links,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      final error = snapshot.error;
                      return LigaPanel(
                        child: Text(
                          error is AppRepositoryException
                              ? error.message
                              : 'Não consegui carregar os professores.',
                        ),
                      );
                    }
                    final links = snapshot.data;
                    if (links == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (links.isEmpty) {
                      return LigaPanel(
                        child: Text(
                          'Nenhum professor liberado ainda.',
                          style: textTheme.bodyMedium,
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final link in links)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: LigaPanel(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.school_rounded,
                                    color: LigaColors.adventurePurple,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          link.teacherEmail,
                                          style: textTheme.titleMedium,
                                        ),
                                        Text(
                                          'Vê a criança como "${link.childName}"',
                                          style: textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          link.connected
                                              ? 'Professor conectado'
                                              : 'Código: ${link.code}',
                                          key: ValueKey(
                                            'teacherCode-${link.id}',
                                          ),
                                          style: textTheme.titleSmall?.copyWith(
                                            color: link.connected
                                                ? LigaColors.adventurePurple
                                                : LigaColors.actionCoral,
                                            letterSpacing: link.connected
                                                ? 0
                                                : 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!link.connected)
                                    IconButton(
                                      tooltip: 'Copiar convite',
                                      icon: const Icon(Icons.copy_rounded),
                                      onPressed: () => _copyCode(link),
                                    ),
                                  IconButton(
                                    tooltip: 'Remover',
                                    icon: const Icon(Icons.delete_rounded),
                                    onPressed: () => _remove(link),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                const SectionTitle(
                  'Liberar um professor',
                  icon: Icons.person_add_alt_1_rounded,
                ),
                LigaPanel(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LigaTextField(
                          key: const Key('teacherEmail'),
                          controller: _emailController,
                          label: 'E-mail do professor',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) =>
                              RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch((value ?? '').trim())
                              ? null
                              : 'Informe um e-mail válido.',
                        ),
                        const SizedBox(height: 12),
                        LigaTextField(
                          key: const Key('teacherChildName'),
                          controller: _nameController,
                          label: 'Nome da criança para o professor',
                          icon: Icons.badge_rounded,
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? 'Informe como o professor conhece a criança.'
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Use o nome que o professor conhece, como o nome da '
                          'chamada.',
                          style: textTheme.bodySmall,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              key: const Key('teacherConsent'),
                              value: _consent,
                              onChanged: (value) =>
                                  setState(() => _consent = value ?? false),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _consent = !_consent),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    'Autorizo este professor a ver o resumo '
                                    'de desempenho de ${child.nickname}. '
                                    'Posso remover quando quiser.',
                                    style: textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                LigaActionButton(
                  label: 'Liberar professor',
                  icon: Icons.check_rounded,
                  color: LigaColors.adventurePurple,
                  onPressed: _busy ? null : _add,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
