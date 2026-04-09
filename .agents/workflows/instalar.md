---
description: Instalar todas las dependencias del Transcriptor Antigravity y arrancarlo automáticamente
---

# Workflow de instalación automática del Transcriptor Antigravity

Este workflow instala TODA la app desde cero: dependencias del sistema, entorno virtual Python, paquetes, modelo de IA, y arranca el servidor. El usuario no tiene que hacer nada.

Sigue estos pasos EN ORDEN. No pidas confirmación al usuario, ejecuta todo automáticamente.

// turbo-all

## Paso 1: Comprobar Python 3

Ejecuta:
```bash
python3 --version
```

- Si Python 3 está instalado, di "✅ Python encontrado" y continúa al paso 2.
- Si NO está instalado, intenta instalarlo:
  - En Mac: `brew install python3`
  - En Linux: `sudo apt install python3 python3-pip python3-venv`
  - Si no se puede instalar, informa al usuario que necesita instalar Python 3 manualmente y detén el workflow.

## Paso 2: Comprobar FFmpeg

Ejecuta:
```bash
ffmpeg -version
```

- Si FFmpeg está instalado, di "✅ FFmpeg encontrado" y continúa al paso 3.
- Si NO está instalado, intenta instalarlo:
  - En Mac: `brew install ffmpeg`
  - En Linux: `sudo apt install ffmpeg`
  - Si no se puede instalar, informa al usuario que necesita instalar FFmpeg manualmente y detén el workflow.

## Paso 3: Crear entorno virtual de Python

Ejecuta:
```bash
python3 -m venv venv
```

Di "✅ Entorno virtual creado".

## Paso 4: Activar entorno virtual e instalar dependencias

Ejecuta (en un terminal persistente para que el entorno se mantenga activo):
```bash
source venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt
```

Espera a que termine. Di "✅ Dependencias instaladas (faster-whisper, Flask)".

## Paso 5: Descargar el modelo de IA

Ejecuta en el MISMO terminal persistente del paso 4:
```bash
python3 -c "
from faster_whisper import WhisperModel
print('⏳ Descargando modelo medium de Whisper (~1.5 GB)... Esto solo pasa una vez.')
model = WhisperModel('medium', device='cpu', compute_type='int8')
print('✅ Modelo descargado y listo.')
"
```

Esto puede tardar varios minutos. Espera con paciencia a que termine (usa WaitMsBeforeAsync alto o monitorea con command_status).

## Paso 6: Crear carpeta de uploads

Ejecuta:
```bash
mkdir -p uploads
```

## Paso 7: Arrancar la aplicación

Ejecuta en el MISMO terminal persistente:
```bash
python3 app.py
```

Este comando se queda ejecutando (es el servidor). Envíalo en background.

## Paso 8: Mensaje final

Cuando el servidor esté corriendo, muestra este mensaje al usuario:

---

🎉 **¡Todo instalado y funcionando!**

Abre en tu navegador: **http://localhost:5050**

Sube un audio o vídeo y se transcribirá automáticamente. ¡Ya está todo listo!

---
