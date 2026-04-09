# 🎙️ Transcriptor Antigravity

Transcriptor de audio/vídeo a texto usando inteligencia artificial (Whisper).  
Sube archivos de audio o vídeo y obtén la transcripción en español.

---

## Instalación automática (recomendado)

Si tienes **Antigravity** (la IA), solo tienes que escribir:

```
/instalar
```

La IA se encarga de **todo**: comprueba requisitos, instala dependencias, descarga el modelo de IA y arranca la app. No tienes que hacer nada más.

---

## Instalación manual (alternativa)

Si prefieres hacerlo a mano:

### Requisitos previos

1. **Python 3.9+**: [python.org](https://www.python.org/downloads/) o `brew install python3`
2. **FFmpeg**: `brew install ffmpeg` (Mac) / `sudo apt install ffmpeg` (Linux)

### Pasos

```bash
bash instalar.sh
source venv/bin/activate
python3 app.py
```

Abre **http://localhost:5050** en tu navegador.

---

## Formatos soportados

MP3, MP4, WAV, OPUS, FLAC, M4A, WebM, OGG

## Notas

- **Primera vez**: Se descarga el modelo de IA (~1.5 GB). Solo ocurre una vez.
- **Tamaño máximo**: 500 MB por archivo.
- **Idioma**: Español.
