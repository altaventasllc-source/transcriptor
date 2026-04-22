#!/bin/bash
PROJECT_DIR="$HOME/Transcriptor"

if [ ! -d "$PROJECT_DIR" ]; then
    osascript -e 'display dialog "No se encuentra el proyecto en ~/Transcriptor.\n\nEjecuta primero Instalador_Transcriptor.app." buttons {"OK"} default button "OK" with icon stop with title "Transcriptor"'
    exit 1
fi

if [ ! -d "$PROJECT_DIR/venv" ]; then
    osascript -e 'display dialog "La instalacion parece incompleta. Vuelve a ejecutar Instalador_Transcriptor.app." buttons {"OK"} default button "OK" with icon stop with title "Transcriptor"'
    exit 1
fi

clear
echo ""
echo "  Transcriptor - Iniciando..."
echo ""

cd "$PROJECT_DIR"
source venv/bin/activate
lsof -ti:5050 | xargs kill 2>/dev/null
sleep 1
(sleep 3 && open http://localhost:5050) &
python app.py
