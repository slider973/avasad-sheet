import 'dart:io';

void main() async {
  final projectDir = Directory.current;
  final readmeFile = File('${projectDir.path}/README.md');
  final buffer = StringBuffer();

  buffer.writeln('# Time sheet');
  buffer.writeln();
  buffer.writeln('## Structure du projet');
  buffer.writeln();

  await generateStructure(projectDir, buffer);

  await readmeFile.writeAsString(buffer.toString());
  print('README.md généré avec succès.');
}

Future<void> generateStructure(Directory dir, StringBuffer buffer, {String prefix = ''}) async {
  final entities = dir.listSync()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (var entity in entities) {
    final name = entity.path.split(Platform.pathSeparator).last;

    if (shouldSkip(name)) continue;

    if (entity is File) {
      buffer.writeln('$prefix├── $name');
    } else if (entity is Directory) {
      buffer.writeln('$prefix├── $name/');
      await generateStructure(entity, buffer, prefix: '$prefix│   ');
    }
  }
}

bool shouldSkip(String name) {
  final skipList = [
    '.dart_tool', '.idea', 'build', '.git', '.gitignore',
    'README.md', 'analysis_options.yaml', '.metadata',
    'matetime.iml', '.flutter-plugins', '.flutter-plugins-dependencies','windows', 'mate_time.iml', 'macos', 'linux', 'ios', 'android', 'web', 'generate_readme.dart', 'Readme.md'
  ];
  return skipList.contains(name) || name.startsWith('.');
}