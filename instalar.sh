#!/bin/bash
# ============================================
#  🎙️ Instalador del Transcriptor Antigravity
#  Ejecuta: bash instalar.sh
# ============================================

set -e

echo ""
echo "  🎙️  Transcriptor Antigravity — Instalador"
echo "  ==========================================="
echo ""

# --- Colores ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✅ $1${NC}"; }
fail() { echo -e "  ${RED}❌ $1${NC}"; }
info() { echo -e "  ${YELLOW}⏳ $1${NC}"; }

# --- 1. Comprobar Python ---
echo "  Paso 1/4: Comprobando Python..."
if command -v python3 &> /dev/null; then
    PY_VERSION=$(python3 --version 2>&1)
    ok "Python encontrado: $PY_VERSION"
else
    fail "Python 3 no encontrado."
    echo ""
    echo "  Instálalo primero:"
    echo "    Mac:     brew install python3"
    echo "    Linux:   sudo apt install python3 python3-pip python3-venv"
    echo "    Windows: descarga de https://python.org/downloads"
    echo ""
    exit 1
fi

# --- 2. Comprobar FFmpeg ---
echo ""
echo "  Paso 2/4: Comprobando FFmpeg..."
if command -v ffmpeg &> /dev/null; then
    FF_VERSION=$(ffmpeg -version 2>&1 | head -1)
    ok "FFmpeg encontrado: $FF_VERSION"
else
    fail "FFmpeg no encontrado."
    echo ""
    echo "  Instálalo primero:"
    echo "    Mac:     brew install ffmpeg"
    echo "    Linux:   sudo apt install ffmpeg"
    echo "    Windows: descarga de https://ffmpeg.org/download.html"
    echo ""
    exit 1
fi

# --- 3. Crear entorno virtual e instalar dependencias ---
echo ""
echo "  Paso 3/4: Instalando dependencias de Python..."

if [ ! -d "venv" ]; then
    info "Creando entorno virtual..."
    python3 -m venv venv
    ok "Entorno virtual creado"
else
    ok "Entorno virtual ya existe"
fi

# Activar entorno virtual
source venv/bin/activate

info "Instalando paquetes (esto puede tardar unos minutos)..."
pip install --upgrade pip -q
pip install -r requirements.txt -q

ok "Todas las dependencias instaladas:"
echo "     - faster-whisper (motor de IA para transcribir)"
echo "     - Flask (servidor web)"

# --- 4. Crear carpeta de uploads ---
echo ""
echo "  Paso 4/4: Preparando carpetas..."
mkdir -p uploads
ok "Carpeta 'uploads' lista"

# --- Resumen final ---
echo ""
echo "  ==========================================="
echo -e "  ${GREEN}🎉 ¡Instalación completada!${NC}"
echo "  ==========================================="
echo ""
echo "  Para usar el transcriptor:"
echo ""
echo "    1. Activa el entorno (solo la primera vez por terminal):"
echo "       source venv/bin/activate"
echo ""
echo "    2. Ejecuta la app:"
echo "       python3 app.py"
echo ""
echo "    3. Abre en tu navegador:"
echo "       http://localhost:5050"
echo ""
echo "  NOTA: La primera transcripción descargará el modelo de IA (~1.5 GB)."
echo "  Esto solo ocurre una vez."
echo ""
