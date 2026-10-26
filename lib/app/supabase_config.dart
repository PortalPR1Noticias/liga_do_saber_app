/// Configuração do Supabase.
///
/// Os valores podem ser trocados no build com `--dart-define`, por exemplo:
/// `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...`
/// A chave publishable é pública por natureza: a proteção dos dados fica nas
/// políticas de RLS das migrations em `supabase/migrations`.
class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hhcdsnfcthyqpxinoyzi.supabase.co',
  );

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_mQHOZI0IDWw3gSEuQFBzqA_BLKQ4cHK',
  );
}
