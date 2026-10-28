import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_mascots.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/services/app_repository.dart';
import 'auth_routing.dart';
import 'liga_text_field.dart';

/// Login da criança: o usuário e a senha que o responsável criou no painel
/// dele. Logada, a criança só vê os jogos.
class ChildLoginScreen extends StatefulWidget {
  const ChildLoginScreen({super.key});

  static const routeName = '/entrar-crianca';

  @override
  State<ChildLoginScreen> createState() => _ChildLoginScreenState();
}

class _ChildLoginScreenState extends State<ChildLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // O painel do responsável abre esta tela com o usuário da criança.
    final username = ModalRoute.of(context)?.settings.arguments;
    if (username is String && _usernameController.text.isEmpty) {
      _usernameController.text = username;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _enter() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final AuthOutcome outcome;
    try {
      outcome = await AppRepository.instance.signInChild(
        username: _usernameController.text,
        password: _passwordController.text,
      );
    } on AppRepositoryException catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    await openHomeFor(context, outcome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sou criança')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              PopIn(
                child: Row(
                  children: [
                    const LigaMascot(character: LigaCharacter.teo, size: 84),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LigaSpeechBubble(
                        text: 'Bora jogar! Digite o seu usuário e a sua senha.',
                        color: LigaColors.progressGreen.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              LigaPanel(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      LigaTextField(
                        controller: _usernameController,
                        label: 'Usuário',
                        icon: Icons.person_rounded,
                        validator: (value) => (value ?? '').trim().length < 3
                            ? 'Digite o seu usuário.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      LigaTextField(
                        controller: _passwordController,
                        label: 'Senha',
                        icon: Icons.lock_rounded,
                        obscureText: true,
                        validator: (value) => (value ?? '').length < 6
                            ? 'A senha tem pelo menos 6 caracteres.'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Esqueceu a senha? Peça para o seu responsável trocar no '
                'painel dele.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              LigaActionButton(
                label: _isSaving ? 'Entrando...' : 'Entrar',
                icon: Icons.sports_esports_rounded,
                color: LigaColors.progressGreen,
                onPressed: _isSaving ? null : _enter,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
