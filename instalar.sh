#!/bin/bash
# ============================================
#  Transcriptor Antigravity — Instalador
#  Ejecuta: bash instalar.sh
# ============================================

set -e

echo ""
echo "  Transcriptor Antigravity — Instalador"
echo "  ==========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}[OK] $1${NC}"; }
fail() { echo -e "  ${RED}[ERROR] $1${NC}"; }
info() { echo -e "  ${YELLOW}[...] $1${NC}"; }

# --- 1. Homebrew ---
echo "  Paso 1/6: Comprobando Homebrew..."
if command -v brew &> /dev/null; then
    ok "Homebrew ya instalado"
else
    info "Instalando Homebrew (puede pedir tu contrasena)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ -f "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    fi
    ok "Homebrew instalado"
fi

# --- 2. Python 3.12 ---
echo ""
echo "  Paso 2/6: Comprobando Python 3.12..."
if command -v python3.12 &> /dev/null; then
    ok "Python 3.12 ya instalado"
elif [ -f "/opt/homebrew/opt/python@3.12/bin/python3.12" ]; then
    ok "Python 3.12 ya instalado (Homebrew)"
else
    info "Instalando Python 3.12..."
    brew install python@3.12
    ok "Python 3.12 instalado"
fi

# Determinar ruta de python3.12
if command -v python3.12 &> /dev/null; then
    PY="python3.12"
elif [ -f "/opt/homebrew/opt/python@3.12/bin/python3.12" ]; then
    PY="/opt/homebrew/opt/python@3.12/bin/python3.12"
else
    fail "No se encontro Python 3.12"
    exit 1
fi
ok "Usando: $($PY --version)"

# --- 3. FFmpeg ---
echo ""
echo "  Paso 3/6: Comprobando FFmpeg..."
if command -v ffmpeg &> /dev/null; then
    ok "FFmpeg ya instalado"
else
    info "Instalando FFmpeg..."
    brew install ffmpeg
    ok "FFmpeg instalado"
fi

# --- 4. Deno (necesario para YouTube) ---
echo ""
echo "  Paso 4/6: Comprobando Deno..."
if command -v deno &> /dev/null; then
    ok "Deno ya instalado"
else
    info "Instalando Deno..."
    brew install deno
    ok "Deno instalado"
fi

# --- 5. Entorno virtual y dependencias ---
echo ""
echo "  Paso 5/6: Instalando dependencias de Python..."

if [ ! -d "venv" ]; then
    info "Creando entorno virtual..."
    $PY -m venv venv
    ok "Entorno virtual creado"
else
    ok "Entorno virtual ya existe"
fi

source venv/bin/activate

info "Instalando paquetes (esto puede tardar unos minutos)..."
pip install --upgrade pip -q 2>/dev/null
pip install -r requirements.txt -q 2>/dev/null
ok "Dependencias instaladas (faster-whisper, Flask, yt-dlp)"

# --- 6. Descargar modelo de IA ---
echo ""
echo "  Paso 6/6: Descargando modelo de IA (~1.5 GB, solo la primera vez)..."
python -c "from faster_whisper import WhisperModel; WhisperModel('medium', device='cpu', compute_type='int8')" 2>/dev/null
ok "Modelo de IA descargado"

# --- Resumen final ---
echo ""
echo "  ==========================================="
echo -e "  ${GREEN}Instalacion completada!${NC}"
echo "  ==========================================="
echo ""
echo "  Para usar el transcriptor:"
echo ""
echo "    1. Activa el entorno:"
echo "       source venv/bin/activate"
echo ""
echo "    2. Ejecuta la app:"
echo "       python app.py"
echo ""
echo "    3. Abre en tu navegador:"
echo "       http://localhost:5050"
echo ""
