#!/bin/bash
# Instalador de Transcriptor
# Se ejecuta desde Instalador_Transcriptor.app

clear
echo ""
echo "  =========================================="
echo "  Transcriptor - Instalador"
echo "  =========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}[OK]${NC} $1"; }
info() { echo -e "  ${YELLOW}[...]${NC} $1"; }
fail() { echo -e "  ${RED}[ERROR]${NC} $1"; }

INSTALL_DIR="$HOME/Transcriptor"
REPO_URL="https://github.com/altaventasllc-source/transcriptor.git"
DESKTOP="$HOME/Desktop"

# --- 1. Homebrew ---
echo "  Paso 1/8: Comprobando Homebrew..."
if command -v brew &> /dev/null; then
    ok "Homebrew ya instalado"
elif [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    ok "Homebrew encontrado"
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
echo "  Paso 2/8: Comprobando Python 3.12..."
if command -v python3.12 &> /dev/null; then
    ok "Python 3.12 ya instalado ($(python3.12 --version))"
elif [ -f "/opt/homebrew/opt/python@3.12/bin/python3.12" ]; then
    ok "Python 3.12 ya instalado"
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

# --- 3. FFmpeg ---
echo ""
echo "  Paso 3/8: Comprobando FFmpeg..."
if command -v ffmpeg &> /dev/null; then
    ok "FFmpeg ya instalado"
else
    info "Instalando FFmpeg..."
    brew install ffmpeg
    ok "FFmpeg instalado"
fi

# --- 4. Git ---
echo ""
echo "  Paso 4/8: Comprobando Git..."
if command -v git &> /dev/null; then
    ok "Git ya instalado"
else
    info "Instalando Git..."
    brew install git
    ok "Git instalado"
fi

# --- 5. Deno (para YouTube) ---
echo ""
echo "  Paso 5/8: Comprobando Deno..."
if command -v deno &> /dev/null; then
    ok "Deno ya instalado"
else
    info "Instalando Deno..."
    brew install deno
    ok "Deno instalado"
fi

# --- 6. Descargar / actualizar proyecto ---
echo ""
echo "  Paso 6/8: Descargando proyecto..."
if [ -d "$INSTALL_DIR/.git" ]; then
    info "Proyecto ya existe, actualizando..."
    cd "$INSTALL_DIR"
    git pull origin main 2>/dev/null || true
    ok "Proyecto actualizado"
else
    if [ -d "$INSTALL_DIR" ]; then
        fail "La carpeta ~/Transcriptor existe pero no es un repositorio git."
        echo "      Borrala o renombrala y vuelve a ejecutar este instalador."
        exit 1
    fi
    info "Clonando desde GitHub..."
    git clone "$REPO_URL" "$INSTALL_DIR"
    ok "Proyecto descargado en $INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# --- 7. Entorno virtual y dependencias ---
echo ""
echo "  Paso 7/8: Instalando dependencias Python..."
if [ ! -d "venv" ]; then
    info "Creando entorno virtual..."
    $PY -m venv venv
fi

source venv/bin/activate
info "Instalando paquetes (puede tardar unos minutos)..."
pip install --upgrade pip -q 2>/dev/null
pip install -r requirements.txt -q 2>/dev/null
ok "Dependencias instaladas (faster-whisper, Flask, yt-dlp)"

# --- 8. Descargar modelo de IA y copiar Transcriptor.app al Escritorio ---
echo ""
echo "  Paso 8/8: Descargando modelo de IA (~1.5 GB solo la primera vez)..."
python -c "from faster_whisper import WhisperModel; WhisperModel('medium', device='cpu', compute_type='int8')" 2>/dev/null
ok "Modelo de IA listo"

# Copiar Transcriptor.app al Escritorio
if [ -d "$INSTALL_DIR/Transcriptor.app" ]; then
    info "Copiando icono al Escritorio..."
    if [ -d "$DESKTOP/Transcriptor.app" ]; then
        rm -rf "$DESKTOP/Transcriptor.app"
    fi
    cp -R "$INSTALL_DIR/Transcriptor.app" "$DESKTOP/"
    xattr -dr com.apple.quarantine "$DESKTOP/Transcriptor.app" 2>/dev/null || true
    ok "Transcriptor.app creado en el Escritorio"
else
    fail "No se encontro Transcriptor.app dentro del repo"
fi

# Copiar Desinstalador_Transcriptor.app al Escritorio
if [ -d "$INSTALL_DIR/Desinstalador_Transcriptor.app" ]; then
    if [ -d "$DESKTOP/Desinstalador_Transcriptor.app" ]; then
        rm -rf "$DESKTOP/Desinstalador_Transcriptor.app"
    fi
    cp -R "$INSTALL_DIR/Desinstalador_Transcriptor.app" "$DESKTOP/"
    xattr -dr com.apple.quarantine "$DESKTOP/Desinstalador_Transcriptor.app" 2>/dev/null || true
    ok "Desinstalador_Transcriptor.app creado en el Escritorio"
fi

# --- Resumen final ---
echo ""
echo "  =========================================="
echo -e "  ${GREEN}Instalacion completada!${NC}"
echo "  =========================================="
echo ""
echo "  Busca el icono 'Transcriptor' en tu Escritorio"
echo "  y haz doble clic para abrir la app."
echo ""
echo "  Puedes cerrar esta ventana."
echo ""
