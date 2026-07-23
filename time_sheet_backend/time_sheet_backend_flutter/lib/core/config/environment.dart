enum Environment { dev, prod }

class AppConfig {
  static Environment current = Environment.prod;

  static String get supabaseUrl => switch (current) {
        Environment.dev => 'https://dev-supabase.timesheet.staticflow.ch',
        Environment.prod => 'https://supabase.timesheet.staticflow.ch',
      };

  static String get powersyncUrl => switch (current) {
        Environment.dev => 'https://dev-powersync.timesheet.staticflow.ch',
        Environment.prod => 'https://powersync.timesheet.staticflow.ch',
      };

  /// URL de l'app web (React), où l'utilisateur définit son nouveau mot de
  /// passe après un reset. Le lien de recovery doit pointer ici : l'app
  /// mobile n'a pas d'écran de reset, on délègue au web (page /set-password).
  static String get webUrl => switch (current) {
        Environment.dev => 'https://dev.timesheet.staticflow.ch',
        Environment.prod => 'https://timesheet.staticflow.ch',
      };

  static String get anonKey => switch (current) {
        Environment.dev =>
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzg0MTE2MTMyLCJleHAiOjIwOTk0NzYxMzJ9.7SFJIowKRkvMM7YLXIHq8IN9Gwuq1szVW9kdbXEivvc',
        Environment.prod =>
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzAwMDAwMDAwLCJleHAiOjE5MDAwMDAwMDB9.KEoz8wTUGwgLtXFiZ_sBC-wy57qSd-lwH4J0h79R8lU',
      };

  static bool get isDev => current == Environment.dev;
  static bool get isProd => current == Environment.prod;
}
