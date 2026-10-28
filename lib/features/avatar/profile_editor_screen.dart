import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/design_system/liga_avatars.dart';
import '../../shared/design_system/liga_widgets.dart';
import '../../shared/models/avatar.dart';
import '../../shared/services/app_repository.dart';

/// Editor de perfil: apelido, herói parceiro e o nome que aparece no
/// ranking. O nome do ranking é montado de listas (bicho + qualidade +
/// número) para nunca expor o nome de verdade da criança.
class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({super.key});

  static const routeName = '/perfil/editar';

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  final _profile = AppRepository.instance.childProfile;
  late final _nickname = TextEditingController(text: _profile.nickname);
  late String _avatarId = _profile.avatarId;
  late String _animal;
  late String _quality;
  late int _number;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final parsed = LeagueName.parse(_profile.leagueName ?? LeagueName.random());
    final (animal, quality, number) =
        parsed ?? LeagueName.parse(LeagueName.random())!;
    _animal = animal;
    _quality = quality;
    _number = number;
  }

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  String get _leagueName => LeagueName.compose(_animal, _quality, _number);

  void _shuffleName() {
    final (animal, quality, number) = LeagueName.parse(
      LeagueName.random(math.Random()),
    )!;
    setState(() {
      _animal = animal;
      _quality = quality;
      _number = number;
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await AppRepository.instance.saveGameProfile(
        nickname: _nickname.text,
        avatarId: _avatarId,
        leagueName: _leagueName,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AppRepositoryException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              LigaPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Apelido', style: textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Como a Liga chama você nas telas do jogo. Só aparece '
                      'para você e para o seu responsável.',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('apelidoField'),
                      controller: _nickname,
                      maxLength: 20,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.badge_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LigaPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nome no ranking', style: textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'No ranking aparece só este nome e o seu avatar. Seu '
                      'nome de verdade fica guardado.',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        color: LigaColors.ink,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _leagueName,
                        key: const Key('nomeLigaPreview'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: LigaTheme.displayFont,
                          fontWeight: FontWeight.w800,
                          color: LigaColors.achievementYellow,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _Picker(
                            label: 'Bicho',
                            value: _animal,
                            options: LeagueName.animals,
                            onChanged: (v) => setState(() => _animal = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Picker(
                            label: 'Jeito',
                            value: _quality,
                            options: LeagueName.qualities,
                            onChanged: (v) => setState(() => _quality = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Diminuir número',
                          onPressed: () => setState(
                            () => _number = _number <= 1 ? 99 : _number - 1,
                          ),
                          icon: const Icon(Icons.remove_rounded),
                        ),
                        Expanded(
                          child: Text(
                            'Número $_number',
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium,
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Aumentar número',
                          onPressed: () => setState(
                            () => _number = _number >= 99 ? 1 : _number + 1,
                          ),
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        key: const Key('sortearNome'),
                        onPressed: _shuffleName,
                        icon: const Icon(Icons.casino_rounded),
                        label: const Text('Sortear um nome'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LigaPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Herói parceiro', style: textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Quem acompanha você na Base e no HUD.',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final avatar in LigaAvatar.all)
                          Semantics(
                            button: true,
                            selected: avatar.id == _avatarId,
                            label: avatar.character.displayName,
                            child: LigaPressable(
                              onTap: () =>
                                  setState(() => _avatarId = avatar.id),
                              child: Container(
                                key: ValueKey('heroi-${avatar.id}'),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: avatar.id == _avatarId
                                        ? LigaColors.achievementYellow
                                        : Colors.transparent,
                                    width: 4,
                                  ),
                                ),
                                child: LigaAvatarBadge(
                                  avatarId: avatar.id,
                                  radius: 26,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              LigaActionButton(
                key: const Key('salvarPerfil'),
                label: 'Salvar perfil',
                icon: Icons.check_rounded,
                color: LigaColors.progressGreen,
                onPressed: _busy ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Picker extends StatelessWidget {
  const _Picker({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('picker-$label-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final option in options)
          DropdownMenuItem(value: option, child: Text(option)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
