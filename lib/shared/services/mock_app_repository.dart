import '../models/child_profile.dart';
import '../models/responsible_account.dart';

class MockAppRepository {
  MockAppRepository._();

  static final instance = MockAppRepository._();

  ResponsibleAccount? _responsible;
  ChildProfile? _childProfile;

  ResponsibleAccount get responsible {
    return _responsible ??
        const ResponsibleAccount(
          name: 'Responsável',
          email: 'responsavel@ligadosaber.app',
        );
  }

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

  Future<void> saveResponsible({
    required String name,
    required String email,
  }) async {
    _responsible = ResponsibleAccount(
      name: name.trim().isEmpty ? 'Responsável' : name.trim(),
      email: email.trim().isEmpty
          ? 'responsavel@ligadosaber.app'
          : email.trim(),
    );
  }

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

  Future<void> saveAvatar(String avatarId) async {
    _childProfile = childProfile.copyWith(avatarId: avatarId);
  }
}
