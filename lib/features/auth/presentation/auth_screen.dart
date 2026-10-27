import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/services/app_repository.dart';
import '../../child_profile/presentation/child_profile_screen.dart';
import '../../shell/presentation/main_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  static const routeName = '/auth';

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
          ? await repository.signUp(
              name: _nameController.text,
              email: _emailController.text,
              password: _passwordController.text,
            )
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

    switch (outcome) {
      case AuthOutcome.readyWithProfile:
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(MainShell.routeName, (route) => false);
      case AuthOutcome.needsChildProfile:
        Navigator.of(context).pushNamed(ChildProfileScreen.routeName);
      case AuthOutcome.needsEmailConfirmation:
        setState(() => _isCreateAccount = false);
        _showMessage(
          'Conta criada! Enviamos um link de confirmação para o seu e-mail. '
          'Depois de confirmar, entre com a mesma senha.',
        );
      case AuthOutcome.signedOut:
        break;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o nome do responsável.';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Responsável')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              PopIn(
                child: Row(
                  children: [
                    const LigaMascot(character: LigaCharacter.nico, size: 84),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LigaSpeechBubble(
                        text: _isCreateAccount
                            ? 'Oi! Primeiro, um adulto cria a conta. Depois é a sua vez!'
                            : 'Que bom te ver de novo! Vamos continuar a missão?',
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
                'A conta principal é sempre do responsável. O perfil da criança vem no próximo passo.',
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
                        _LigaTextField(
                          controller: _nameController,
                          label: 'Nome do responsável',
                          icon: Icons.person_outline,
                          validator: _validateName,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _LigaTextField(
                        controller: _emailController,
                        label: 'E-mail',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 12),
                      _LigaTextField(
                        controller: _passwordController,
                        label: 'Senha',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        validator: _validatePassword,
                      ),
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
                              'Seus dados ficam protegidos na sua conta. Só você acessa os perfis das crianças.',
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

class _LigaTextField extends StatelessWidget {
  const _LigaTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(
        color: LigaColors.ink,
        fontWeight: FontWeight.w800,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: LigaColors.primaryBlue),
      ),
    );
  }
}
