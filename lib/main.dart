import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/liga_do_saber_app.dart';
import 'app/supabase_config.dart';
import 'shared/design_system/liga_sound.dart';
import 'shared/services/app_repository.dart';
import 'shared/services/supabase_app_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  AppRepository.instance = SupabaseAppRepository(Supabase.instance.client);
  await LigaSound.load();
  runApp(const LigaDoSaberApp());
}
