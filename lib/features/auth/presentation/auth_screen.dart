import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/services/app_repository.dart';
import '../../legal/presentation/legal_document_screen.dart';
import 'auth_routing.dart';
import 'liga_text_field.dart';

/// Conta por e-mail e senha: do responsável ou, com [forTeacher], do
/// professor.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.forTeacher = false});

  static const routeName = '/auth';
  static const teacherRouteName = '/auth-professor';

  final bool forTeacher;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isCreateAccount = true;
  bool _isSaving = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final AuthOutcome outcome;
    try {
      final repository = AppRepository.instance;
      outcome = _isCreateAccount
          ? await (widget.forTeacher
                ? repository.signUpTeacher(
                    name: _nameController.text,
                    email: _emailController.text,
                    password: _passwordController.text,
                    acceptedTermsVersion: LegalDocument.version,
                  )
                : repository.signUp(
                    name: _nameController.text,
                    email: _emailController.text,
                    password: _passwordController.text,
                    acceptedTermsVersion: LegalDocument.version,
                  ))
          : await repository.signIn(
              email: _emailController.text,
              password: _passwordController.text,
            );
    } on AppRepositoryException catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage(error.message);
      return;
    }
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (outcome == AuthOutcome.needsEmailConfirmation) {
      setState(() => _isCreateAccount = false);
      _showMessage(
        'Conta criada! Enviamos um link de confirmação para o seu e-mail. '
        'Depois de confirmar, entre com a mesma senha.',
      );
      return;
    }
    await openHomeFor(context, outcome);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return widget.forTeacher
          ? 'Informe o seu nome.'
          : 'Informe o nome do responsável.';
    }
    return null;
  }

  static String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return isValid ? null : 'Informe um e-mail válido.';
  }

  static String? _validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'A senha precisa ter pelo menos 6 caracteres.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final teacher = widget.forTeacher;
    final String greeting;
    if (teacher) {
      greeting = _isCreateAccount
          ? 'Olá, professor! Com a sua conta, você acompanha os alunos que as famílias liberarem.'
          : 'Bem-vindo de volta! Vamos ver como a turma está indo?';
    } else {
      greeting = _isCreateAccount
          ? 'Oi! Primeiro, um adulto cria a conta. Depois é a sua vez!'
          : 'Que bom te ver de novo! Vamos continuar a missão?';
    }
    return Scaffold(
      appBar: AppBar(title: Text(teacher ? 'Professor' : 'Responsável')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              PopIn(
                child: Row(
                  children: [
                    LigaMascot(
                      character: teacher
                          ? LigaCharacter.mila
                          : LigaCharacter.nico,
                      size: 84,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LigaSpeechBubble(
                        text: greeting,
                        color: LigaColors.primaryBlue.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _isCreateAccount ? 'Crie sua conta' : 'Entre na sua conta',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                teacher
                    ? 'Você só vê o desempenho das crianças que os responsáveis '
                          'liberarem para o seu e-mail.'
                    : 'A conta principal é sempre do responsável. O perfil e o '
                          'login da criança vêm nos próximos passos.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Criar')),
                  ButtonSegment(value: false, label: Text('Entrar')),
                ],
                selected: {_isCreateAccount},
                onSelectionChanged: (value) {
                  setState(() => _isCreateAccount = value.first);
                },
              ),
              const SizedBox(height: 18),
              LigaPanel(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_isCreateAccount) ...[
                        LigaTextField(
                          controller: _nameController,
                          label: teacher ? 'Seu nome' : 'Nome do responsável',
                          icon: Icons.person_outline,
                          validator: _validateName,
                        ),
                        const SizedBox(height: 12),
                      ],
                      LigaTextField(
                        controller: _emailController,
                        label: 'E-mail',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 12),
                      LigaTextField(
                        controller: _passwordController,
                        label: 'Senha',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        validator: _validatePassword,
                      ),
                      if (_isCreateAccount) ...[
                        const SizedBox(height: 12),
                        _ConsentField(forTeacher: teacher),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.verified_user_rounded,
                            color: LigaColors.progressGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              teacher
                                  ? 'Você vê só um resumo do desempenho. Textos, '
                                        'fotos e provas das crianças continuam '
                                        'só com a família.'
                                  : 'Seus dados ficam protegidos na sua conta. '
                                        'Só você e os professores que você '
                                        'liberar veem o desempenho das crianças.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              LigaActionButton(
                label: _isSaving
                    ? 'Salvando...'
                    : (_isCreateAccount ? 'Continuar' : 'Entrar'),
                icon: _isCreateAccount
                    ? Icons.arrow_forward_rounded
                    : Icons.login_rounded,
                color: LigaColors.primaryBlue,
                onPressed: _isSaving ? null : _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Consentimento específico e em destaque do responsável (LGPD art. 14,
/// § 1º): sem marcar, a conta não é criada. O professor aceita os termos e
/// se compromete a usar os dados só para acompanhar o aprendizado.
class _ConsentField extends StatelessWidget {
  const _ConsentField({required this.forTeacher});

  final bool forTeacher;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FormField<bool>(
      initialValue: false,
      validator: (value) => value == true
          ? null
          : (forTeacher
                ? 'Para criar a conta, aceite os termos.'
                : 'Para criar a conta, confirme que você é o responsável.'),
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  key: const Key('parentalConsent'),
                  value: field.value,
                  onChanged: field.didChange,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => field.didChange(!(field.value ?? false)),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        forTeacher
                            ? 'Sou professor(a), vou usar o desempenho das '
                                  'crianças só para acompanhar o aprendizado '
                                  'delas e não vou compartilhar com outras '
                                  'pessoas. Li e aceito os Termos de Uso e a '
                                  'Política de Privacidade.'
                            : 'Tenho 18 anos ou mais, sou pai, mãe ou '
                                  'responsável legal pela criança e autorizo o '
                                  'uso dos dados dela como descrito na Política '
                                  'de Privacidade. Li e aceito os Termos de Uso.',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  field.errorText!,
                  style: textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            Wrap(
              spacing: 4,
              children: [
                for (final document in LegalDocument.values)
                  TextButton(
                    onPressed: () =>
                        LegalDocumentScreen.open(context, document),
                    child: Text(document.title),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
