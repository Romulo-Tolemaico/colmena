#!/usr/bin/env bash
# Script de build para Render Static Site.
# Instala Flutter SDK, compila la app web y genera los archivos estáticos
# en build/web (que Render sirve como static site).

set -e

# Instalar Flutter SDK si no está disponible
if ! command -v flutter &> /dev/null; then
  echo "==> Instalando Flutter SDK..."
  git clone https://github.com/flutter/flutter.git --depth 1 --branch stable /opt/flutter
  export PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH"
fi

flutter --version
flutter pub get

# URL del API en producción (se pasa como variable de entorno de Render).
# Si no está definida, usa un valor por defecto vacío que hará que la app
# intente conectar a localhost (no funcionará en producción, pero al menos
# compila).
API_URL="${API_BASE_URL:-https://colmena-api.onrender.com/api/v1}"

echo "==> Compilando Flutter web con API_BASE_URL=$API_URL"

flutter build web --release --dart-define=API_BASE_URL="$API_URL"

echo "==> Build completado. Archivos en build/web/"
