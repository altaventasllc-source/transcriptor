#!/bin/bash
# Launcher de Transcriptor
# Se ejecuta desde Transcriptor.app (el que esta en el Escritorio)

PROJECT_DIR="$HOME/Transcriptor"

# Verificar que el proyecto existe
if [ ! -d "$PROJECT_DIR" ]; then
    osascript -e 'display dialog "No se encuentra el proyecto en ~/Transcriptor.\n\nEjecuta primero Instalador_Transcriptor.app para instalarlo." buttons {"OK"} default button "OK" with icon stop with title "Transcriptor"'
    exit 1
fi

# Verificar que el entorno virtual existe
if [ ! -d "$PROJECT_DIR/venv" ]; then
    osascript -e 'display dialog "La instalacion parece incompleta. Vuelve a ejecutar Instalador_Transcriptor.app." buttons {"OK"} default button "OK" with icon stop with title "Transcriptor"'
    exit 1
fi

cd "$PROJECT_DIR"
source venv/bin/activate

# Matar cualquier proceso anterior en el puerto
lsof -ti:5050 | xargs kill 2>/dev/null
sleep 1

# Abrir navegador después de 3 segundos
(sleep 3 && open http://localhost:5050) &

# Arrancar Flask
python app.py
