#!/bin/bash
# Script pour démarrer Serverpod en mode debug avec breakpoints

export PATH="/Users/jonathanlemaine/Documents/flutter/bin:$PATH"

echo "Démarrage de Serverpod en mode debug..."
echo "Dart version: $(dart --version)"

# Démarrer avec les options de debug
dart \
  --enable-asserts \
  --enable-vm-service=5858 \
  --pause-isolates-on-unhandled-exceptions \
  bin/main.dart \
  --mode development

# Pour attacher le débogueur VSCode :
# 1. Lancez ce script
# 2. Dans VSCode, créez une configuration "attach"
# 3. Attachez-vous au port 5858