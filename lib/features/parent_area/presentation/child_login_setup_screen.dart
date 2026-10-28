import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_widgets.dart';
import '../../../shared/services/app_repository.dart';
import '../../auth/presentation/liga_text_field.dart';
import 'parent_home_screen.dart';

/// O responsável cria o login da criança escolhida (usuário e senha) ou
/// troca a senha. Depois do cadastro da criança, a rota recebe `true` como
/// argumento e termina no painel do responsável.
class ChildLoginSetupScreen extends StatefulWidget {
  const ChildLoginSetupScreen({super.key});

  static const routeName = '/login-crianca';

  /// Usuário sugerido a partir do apelido: sem acentos, minúsculo, com ponto
  /// no lugar dos espaços.
  static String suggestUsername(String nickname) {
    const accents = {
      'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'é': 'e', 'ê': 'e', //
      'í': 'i', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ú': 'u', 'ç': 'c',
    };
    final plain = nickname
        .toLowerCase()
        .split('')
        .map((letter) => accents[letter] ?? letter)
        .join()
        .replaceAll(RegExp(r'\s+'), '.')
        .replaceAll(RegExp(r'[^a-z0-9._]'), '');
    return plain.length > 24 ? plain.substring(0, 24) : plain;
  }

  @override
  State<ChildLoginSetupScreen> createState() => _ChildLoginSetupScreenState();
}

class _ChildLoginSetupScreenState extends State<ChildLoginSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _usernameController = TextEditingController(
    text: ChildLoginSetupScreen.suggestUsername(
      AppRepository.instance.childProfile.nickname,
    ),
  );
  final _passwordController = TextEditingController();
  bool _isSaving = false;

  bool get _fromSetup => ModalRoute.of(context)?.settings.arguments == true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _finish() {
    if (_fromSetup) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(ParentHomeScreen.routeName, (_) => false);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repository = AppRepository.instance;
    final hasLogin = repository.childProfile.username != null;
    setState(() => _isSaving = true);
    try {
      if (hasLogin) {
        await repository.changeChildPassword(_passwordController.text);
      } else {
        await repository.createChildLogin(
          username: _usernameController.text,
          password: _passwordController.text,
        );
      }
    } on AppRepositoryException catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage(error.message);
      return;
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    _showMessage(
      hasLogin
          ? 'Senha trocada.'
          : 'Login criado! Usuário: ${repository.childProfile.username}',
    );
    _finish();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final child = AppRepository.instance.childProfile;
    final username = child.username;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('Login de ${child.nickname}')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                username == null ? 'Crie o login da criança' : 'Trocar senha',
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                username == null
                    ? 'Com o usuário e a senha, ${child.nickname} entra na '
                          'tela "Sou criança" e vê só os jogos. Não precisa '
                          'de e-mail.'
                    : '${child.nickname} entra com o usuário $username. '
                          'Digite a senha nova.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              LigaPanel(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (username == null) ...[
                        LigaTextField(
                          key: const Key('childUsername'),
                          controller: _usernameController,
                          label: 'Usuário da criança',
                          icon: Icons.person_rounded,
                          validator: (value) {
                            final text = (value ?? '').trim().toLowerCase();
                            return RegExp(
                                  r'^[a-z0-9][a-z0-9._]{2,23}$',
                                ).hasMatch(text)
                                ? null
                                : 'Use de 3 a 24 letras sem acento, números, '
                                      'ponto ou _.';
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      LigaTextField(
                        key: const Key('childPassword'),
                        controller: _passwordController,
                        label: username == null ? 'Senha' : 'Senha nova',
                        icon: Icons.lock_rounded,
                        validator: (value) => (value ?? '').length < 6
                            ? 'A senha precisa ter pelo menos 6 caracteres.'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Anote o usuário e a senha para a criança. A senha fica '
                'visível aqui para você conferir.',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              LigaActionButton(
                label: _isSaving
                    ? 'Salvando...'
                    : (username == null ? 'Criar login' : 'Trocar senha'),
                icon: Icons.key_rounded,
                color: LigaColors.primaryBlue,
                onPressed: _isSaving ? null : _save,
              ),
              if (_fromSetup) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isSaving ? null : _finish,
                  child: const Text('Fazer depois'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
