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

  static String get anonKey => switch (current) {
        Environment.dev =>
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzAwMDAwMDAwLCJleHAiOjE5MDAwMDAwMDB9.MdkUvagcXQ9cs5hO-fw0FkENVVq6vskG3wBR-P5gR58',
        Environment.prod =>
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzAwMDAwMDAwLCJleHAiOjE5MDAwMDAwMDB9.KEoz8wTUGwgLtXFiZ_sBC-wy57qSd-lwH4J0h79R8lU',
      };

  static bool get isDev => current == Environment.dev;
  static bool get isProd => current == Environment.prod;
}
