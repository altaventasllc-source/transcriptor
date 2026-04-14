# Transcriptor Antigravity

Transcriptor de audio y video a texto usando inteligencia artificial (faster-whisper).
Sube archivos, pega una URL de YouTube/Instagram/TikTok, y obtiene la transcripcion en español.

---

## Funcionalidades

- **Subida de archivos**: arrastra o selecciona audios y videos para transcribir
- **Transcripcion desde URL**: pega un enlace de YouTube, Instagram, TikTok, Twitter, Facebook y mas
- **Subida en bloque**: sube varios archivos a la vez, se procesan en cola uno a uno
- **Timestamps opcionales**: activa/desactiva marcas de tiempo [M:SS] en la transcripcion
- **Reproductor de audio**: escucha el audio procesado directamente en la app
- **Barra de progreso**: visualiza el porcentaje de transcripcion en tiempo real
- **Copiar transcripcion**: boton para copiar al portapapeles (con o sin timestamps)
- **Sin limite de tamaño**: sube archivos de cualquier tamaño
- **Limpieza automatica**: la carpeta de archivos temporales se borra al reiniciar

## Formatos soportados

**Archivos**: MP3, MP4, WAV, OPUS, FLAC, M4A, WebM, OGG, MOV

**URLs**: YouTube, Instagram, TikTok, Twitter/X, Facebook y +1000 plataformas (via yt-dlp)

---

## Instalacion

### Mac — Instalacion automatica (recomendado)

```bash
git clone https://github.com/altaventasllc-source/transcriptor.git
cd transcriptor
bash instalar.sh
```

El script instala todo automaticamente: Homebrew, Python 3.12, FFmpeg, Deno, dependencias y el modelo de IA.

Para ejecutar la app despues de instalar:

```bash
source venv/bin/activate
python app.py
```

### Mac — Instalacion manual

```bash
brew install python@3.12 ffmpeg deno
git clone https://github.com/altaventasllc-source/transcriptor.git
cd transcriptor
python3.12 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python app.py
```

### Windows

```bash
winget install Python.Python.3.12
winget install Gyan.FFmpeg
winget install Git.Git
git clone https://github.com/altaventasllc-source/transcriptor.git
cd transcriptor
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python app.py
```

Abrir **http://localhost:5050** en el navegador.

---

## Uso

### Transcribir archivos
1. Arrastra archivos a la zona de subida o haz clic para seleccionar
2. Espera a que se complete la transcripcion (barra de progreso)
3. Haz clic en la transcripcion para desplegarla
4. Usa los botones para copiar, activar timestamps o eliminar

### Transcribir desde URL
1. Pega la URL en el campo de texto
2. Pulsa "Transcribir URL"
3. La app descarga el audio automaticamente y lo transcribe

### Timestamps
- Pulsa el boton "Timestamps" para ver en que momento se dijo cada frase
- Formato: `[M:SS] texto de la frase`
- El boton "Copiar" copia la version visible (con o sin timestamps)

---

## Tecnologias

- **faster-whisper**: motor de transcripcion (modelo medium, ejecucion local)
- **Flask**: servidor web
- **yt-dlp**: descarga de audio desde URLs
- **FFmpeg**: conversion y procesamiento de audio
- **deno**: runtime JS para resolver challenges de YouTube

## Notas

- **Primera vez**: se descarga el modelo de IA (~1.5 GB). Solo ocurre una vez.
- **Idioma**: español (configurable en `app.py`).
- **Todo es local**: no se envia nada a ningun servidor externo. La transcripcion se ejecuta en tu ordenador.
- **Puerto**: la app se ejecuta en `localhost:5050`.
