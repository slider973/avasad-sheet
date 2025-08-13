import 'dart:io';

void main() async {
  final projectDir = Directory.current;
  final claudeFile = File('${projectDir.path}/claude_files.md');
  final buffer = StringBuffer();

  // En-tête du document pour Claude
  buffer.writeln('<documents>');

  // Générer la documentation
  await generateClaudeDocumentation(projectDir, buffer);

  // Fermeture du document
  buffer.writeln('</documents>');

  await claudeFile.writeAsString(buffer.toString());
  print('claude_files.md généré avec succès.');
}

Future<void> generateClaudeDocumentation(Directory dir, StringBuffer buffer, {int index = 1}) async {
  final entities = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));

  for (var entity in entities) {
    final name = entity.path.split(Platform.pathSeparator).last;
    final relativePath = entity.path.replaceAll(Directory.current.path, '').replaceAll('\\', '/');

    if (shouldSkip(name)) continue;

    if (entity is File) {
      try {
        final content = await File(entity.path).readAsString();
        buffer.writeln('''
<document index="$index">
<source>$relativePath</source>
<document_content>
$content
</document_content>
</document>
''');
        index++;
      } catch (e) {
        print('Erreur lors de la lecture du fichier $name: $e');
      }
    } else if (entity is Directory) {
      await generateClaudeDocumentation(entity, buffer, index: index);
    }
  }
}

bool shouldSkip(String name) {
  final skipList = [
    '.devcontainer',
    '.vscode',
    '.turbo',
    '.idea',
    '.run',
    '.git',
    '.gitignore',
    'node_modules',
    'dist',
    'coverage',
    'swagger',
    'claude_files.md',
    "pnpm-lock.yaml",
    "generate_readme.dart",
    "packages",
    "build",
    ".dart_tool",
    "android",
    "macos",
    "web",
    "windows",
    "linux",
    "ios",
  ];

  return skipList.any((skip) => skip.toLowerCase() == name.trim().toLowerCase()) ||
      name.startsWith('.') ||
      name.endsWith('.jpg') ||
      name.endsWith('.png') ||
      name.endsWith('.gif') ||
      name.endsWith('.ico') ||
      name.endsWith('.pdf');
}