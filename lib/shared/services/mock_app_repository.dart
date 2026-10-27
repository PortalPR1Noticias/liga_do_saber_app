import 'dart:typed_data';

import '../models/child_profile.dart';
import '../models/photo_explanation.dart';
import '../models/responsible_account.dart';
import 'app_repository.dart';

/// Repositório em memória, usado nos testes e como padrão sem Supabase.
class MockAppRepository implements AppRepository {
  ResponsibleAccount? _responsible;
  ChildProfile? _childProfile;

  @override
  ResponsibleAccount get responsible {
    return _responsible ??
        const ResponsibleAccount(
          name: 'Responsável',
          email: 'responsavel@ligadosaber.app',
        );
  }

  @override
  ChildProfile get childProfile {
    return _childProfile ??
        const ChildProfile(
          nickname: 'Alex G',
          schoolYear: 5,
          focusAreas: ['Leitura', 'Texto'],
          avatarId: 'estrategista',
          level: 14,
          totalXp: 5840,
          streakDays: 19,
        );
  }

  @override
  Future<AuthOutcome> restoreSession() async => AuthOutcome.signedOut;

  @override
  Future<AuthOutcome> signUp({
    required String name,
    required String email,
    required String password,
    required String acceptedTermsVersion,
  }) async {
    _responsible = ResponsibleAccount(
      name: name.trim().isEmpty ? 'Responsável' : name.trim(),
      email: email.trim().isEmpty
          ? 'responsavel@ligadosaber.app'
          : email.trim(),
    );
    return AuthOutcome.needsChildProfile;
  }

  @override
  Future<AuthOutcome> signIn({
    required String email,
    required String password,
  }) async {
    return AuthOutcome.readyWithProfile;
  }

  @override
  Future<void> signOut() async {
    _responsible = null;
    _childProfile = null;
  }

  @override
  Future<void> saveChildProfile({
    required String nickname,
    required int schoolYear,
    required List<String> focusAreas,
  }) async {
    final current = childProfile;
    _childProfile = current.copyWith(
      nickname: nickname.trim().isEmpty ? 'Alex G' : nickname.trim(),
      schoolYear: schoolYear,
      focusAreas: focusAreas,
    );
  }

  @override
  Future<void> saveAvatar(String avatarId) async {
    _childProfile = childProfile.copyWith(avatarId: avatarId);
  }

  @override
  Future<PhotoExplanation> explainPhoto(Uint8List imageBytes) async {
    return const PhotoExplanation(
      readable: true,
      subject: 'matematica',
      characterId: 'nico',
      title: 'Dividindo figurinhas',
      statement: 'Dividir 24 figurinhas entre 3 amigos.',
      steps: [
        ExplanationStep(
          title: 'Entenda a missão',
          explanation: 'Temos 24 figurinhas e 3 amigos.',
        ),
        ExplanationStep(
          title: 'Escolha a operação',
          explanation: 'Repartir em partes iguais é dividir: 24 ÷ 3.',
        ),
      ],
      finalAnswer: 'Cada amigo fica com 8 figurinhas.',
      tip: 'Confira multiplicando: 8 × 3 = 24.',
      closingMessage: 'Estratégia certeira! Você consegue!',
      xp: 20,
    );
  }

  @override
  Future<void> setAiConsent(bool allowed) async {
    _responsible = ResponsibleAccount(
      name: responsible.name,
      email: responsible.email,
      aiConsent: allowed,
    );
  }

  @override
  Future<Map<String, dynamic>> exportMyData() async {
    final profile = childProfile;
    return {
      'responsavel': {
        'nome': responsible.name,
        'email': responsible.email,
        'autoriza_ia': responsible.aiConsent,
      },
      'perfis_criancas': [
        {
          'apelido': profile.nickname,
          'ano_escolar': profile.schoolYear,
          'xp_total': profile.totalXp,
        },
      ],
    };
  }

  @override
  Future<void> deleteAccount() => signOut();
}
