# 🎙️ Transcriptor Antigravity

Transcriptor de audio/vídeo a texto usando inteligencia artificial (Whisper).  
Sube archivos de audio o vídeo y obtén la transcripción en español.

## Requisitos previos

Solo necesitas 2 cosas instaladas **antes** de empezar:

### 1. Python 3.9 o superior

```bash
python3 --version
```

Si no lo tienes:
- **Mac**: `brew install python3` (necesitas [Homebrew](https://brew.sh))
- **Windows**: Descarga de [python.org](https://www.python.org/downloads/)
- **Linux**: `sudo apt install python3 python3-pip python3-venv`

### 2. FFmpeg

```bash
ffmpeg -version
```

Si no lo tienes:
- **Mac**: `brew install ffmpeg`
- **Windows**: Descarga de [ffmpeg.org](https://ffmpeg.org/download.html) y añádelo al PATH
- **Linux**: `sudo apt install ffmpeg`

> ⚠️ **NO necesitas instalar Whisper por separado.** El instalador se encarga de todo.

---

## Instalación (un solo comando)

```bash
bash instalar.sh
```

Esto automáticamente:
1. ✅ Comprueba que tienes Python y FFmpeg
2. ✅ Crea un entorno virtual aislado
3. ✅ Instala todas las dependencias (faster-whisper, Flask, etc.)
4. ✅ Prepara las carpetas necesarias

---

## Uso diario

### Arrancar la app:
```bash
source venv/bin/activate
python3 app.py
```

### Usar:
1. Abre **http://localhost:5050** en tu navegador
2. Sube un archivo de audio o vídeo
3. Espera a que se transcriba
4. ¡Listo! Copia o descarga tu transcripción

> ⏳ **Primera vez**: Se descargará automáticamente el modelo de IA (~1.5 GB). Solo ocurre una vez.

---

## Formatos soportados

MP3, MP4, WAV, OPUS, FLAC, M4A, WebM, OGG

## Notas

- **Tamaño máximo**: 500 MB por archivo
- **Idioma**: Configurado para español
- **Rendimiento**: Un audio de 1 hora tarda ~5-10 min en Mac M1/M2, más en CPU Intel

## Solución de problemas

| Problema | Solución |
|----------|----------|
| `ModuleNotFoundError` | Ejecuta `bash instalar.sh` otra vez |
| `ffmpeg: command not found` | Instala FFmpeg (ver arriba) |
| Tarda mucho | Normal en CPU, paciencia 😊 |
| Error al subir archivo | Comprueba que no supere 500 MB |
