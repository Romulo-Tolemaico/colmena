#!/usr/bin/env bash
# Script de build para Render Static Site.
# Instala Flutter SDK, compila la app web y genera los archivos estáticos
# en build/web (que Render sirve como static site).

set -e

# Instalar Flutter SDK en el directorio de trabajo (Render no permite
# escribir en /opt ni /usr/local, pero sí en el working directory).
if [ ! -d ".flutter-sdk" ]; then
  echo "==> Instalando Flutter SDK..."
  git clone https://github.com/flutter/flutter.git --depth 1 --branch stable .flutter-sdk
fi

export PATH="$PWD/.flutter-sdk/bin:$PWD/.flutter-sdk/bin/cache/dart-sdk/bin:$PATH"

flutter --version
flutter pub get

# URL del API en producción (se pasa como variable de entorno de Render).
API_URL="${API_BASE_URL:-https://colmena-api.onrender.com/api/v1}"

echo "==> Compilando Flutter web con API_BASE_URL=$API_URL"

flutter build web --release --no-web-resources-cdn --dart-define=API_BASE_URL="$API_URL"

echo "==> Build completado. Archivos en build/web/"
