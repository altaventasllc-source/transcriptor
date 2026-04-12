import os
import shutil
import subprocess
import threading
import yt_dlp
from flask import Flask, render_template, request, jsonify, send_from_directory
from faster_whisper import WhisperModel

app = Flask(__name__)
app.config["UPLOAD_FOLDER"] = os.path.join(os.path.dirname(__file__), "uploads")
app.config["MAX_CONTENT_LENGTH"] = 500 * 1024 * 1024

# Limpiar uploads al arrancar para no dejar basura de sesiones anteriores
if os.path.exists(app.config["UPLOAD_FOLDER"]):
    shutil.rmtree(app.config["UPLOAD_FOLDER"])
os.makedirs(app.config["UPLOAD_FOLDER"], exist_ok=True)

transcriptions = {}
queue_lock = threading.Lock()
model = None


def get_model():
    global model
    if model is None:
        model = WhisperModel("medium", device="cpu", compute_type="int8")
    return model


def convert_to_wav(filepath, wav_name):
    """Convertir a WAV 16kHz mono."""
    wav_path = os.path.join(app.config["UPLOAD_FOLDER"], wav_name)
    subprocess.run(
        ["ffmpeg", "-y", "-i", filepath,
         "-ar", "16000", "-ac", "1",
         "-c:a", "pcm_s16le", wav_path],
        capture_output=True
    )
    return wav_path


def get_audio_duration(filepath):
    result = subprocess.run(
        ["ffprobe", "-v", "quiet", "-show_entries", "format=duration",
         "-of", "default=noprint_wrappers=1:nokey=1", filepath],
        capture_output=True, text=True
    )
    return float(result.stdout.strip())


def transcribe_single_pass(m, wav_path, tid=None):
    """Transcribir con VAD ultra-sensible (funciona para WAV, MP4, FLAC, OPUS)."""
    duration = get_audio_duration(wav_path)
    segments, _ = m.transcribe(
        wav_path,
        language="es",
        beam_size=5,
        word_timestamps=True,
        vad_filter=True,
        vad_parameters=dict(
            threshold=0.05,
            min_silence_duration_ms=2000,
            speech_pad_ms=500,
            min_speech_duration_ms=100,
        ),
        condition_on_previous_text=False,
    )
    parts = []
    for seg in segments:
        text = seg.text.strip()
        if text:
            parts.append(text)
        # Actualizar progreso
        if tid and duration > 0:
            pct = min(int((seg.end / duration) * 100), 99)
            with queue_lock:
                if tid in transcriptions:
                    transcriptions[tid]["progress"] = pct
    return " ".join(parts)


def transcribe_chunked(m, wav_path, tid=None):
    """Transcribir en trozos de 25s — cada trozo < 30s = una sola ventana de Whisper.
    Usado para MP3 donde el mecanismo de seek de Whisper falla."""
    duration = get_audio_duration(wav_path)
    chunk_dir = wav_path + "_chunks"
    os.makedirs(chunk_dir, exist_ok=True)

    FIRST_CHUNK = 3   # Primer trozo ultra-corto: solo la intro
    CHUNK = 25        # Resto: 25s cada uno
    OVERLAP = 2       # 2s de solapamiento

    try:
        parts = []
        start = 0.0
        idx = 0
        while start < duration:
            chunk_len = FIRST_CHUNK if idx == 0 else CHUNK
            chunk_path = os.path.join(chunk_dir, f"c_{idx:04d}.wav")
            subprocess.run(
                ["ffmpeg", "-y", "-i", wav_path,
                 "-ss", str(start), "-t", str(chunk_len),
                 "-ar", "16000", "-ac", "1", "-c:a", "pcm_s16le",
                 chunk_path],
                capture_output=True
            )
            segments, _ = m.transcribe(
                chunk_path,
                language="es",
                beam_size=5,
                word_timestamps=True,
                vad_filter=False,
                condition_on_previous_text=False,
            )
            for seg in segments:
                text = seg.text.strip()
                if text:
                    parts.append(text)
            # Actualizar progreso
            start += (FIRST_CHUNK - OVERLAP) if idx == 0 else CHUNK
            if tid and duration > 0:
                pct = min(int((start / duration) * 100), 99)
                with queue_lock:
                    if tid in transcriptions:
                        transcriptions[tid]["progress"] = pct
            idx += 1

        return " ".join(parts)
    finally:
        shutil.rmtree(chunk_dir, ignore_errors=True)


def transcribe_wav(wav_path, is_mp3=False, tid=None):
    """Transcribir WAV. MP3 usa trozos de 25s, el resto usa VAD."""
    m = get_model()
    if is_mp3:
        return transcribe_chunked(m, wav_path, tid=tid)
    return transcribe_single_pass(m, wav_path, tid=tid)


def process_queue():
    while True:
        pending = None
        with queue_lock:
            for tid, t in transcriptions.items():
                if t["status"] == "pending":
                    t["status"] = "processing"
                    pending = (tid, t)
                    break

        if pending is None:
            break

        tid, t = pending
        try:
            filepath = os.path.join(app.config["UPLOAD_FOLDER"], t["stored_name"])
            wav_name = t["stored_name"] + ".wav"
            wav_path = convert_to_wav(filepath, wav_name)
            with queue_lock:
                t["wav_name"] = wav_name
            text = transcribe_wav(wav_path, is_mp3=t["filename"].lower().endswith(".mp3"), tid=tid)
            with queue_lock:
                t["status"] = "done"
                t["text"] = text
                t["progress"] = 100
        except Exception as e:
            with queue_lock:
                t["status"] = "error"
                t["error"] = str(e)


def download_audio(url, output_path):
    """Descargar audio de una URL con yt-dlp y convertir a WAV."""
    import glob

    # Descargar en una carpeta temporal para controlar el nombre
    dl_dir = output_path + "_dl"
    os.makedirs(dl_dir, exist_ok=True)

    ydl_opts = {
        "format": "bestaudio/best",
        "outtmpl": os.path.join(dl_dir, "audio.%(ext)s"),
        "quiet": True,
        "no_warnings": True,
        "socket_timeout": 30,
    }

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(url, download=True)
        title = info.get("title", "audio")

    # Buscar el archivo descargado (puede tener cualquier extensión)
    matches = glob.glob(os.path.join(dl_dir, "audio.*"))
    if not matches:
        # yt-dlp a veces usa el título como nombre
        matches = glob.glob(os.path.join(dl_dir, "*"))
    if not matches:
        shutil.rmtree(dl_dir, ignore_errors=True)
        raise Exception("No se pudo descargar el archivo")

    downloaded = matches[0]

    # Convertir a WAV 16kHz mono
    wav_path = output_path + ".wav"
    subprocess.run(
        ["ffmpeg", "-y", "-i", downloaded,
         "-ar", "16000", "-ac", "1",
         "-c:a", "pcm_s16le", wav_path],
        capture_output=True
    )

    # Limpiar carpeta temporal
    shutil.rmtree(dl_dir, ignore_errors=True)

    if not os.path.exists(wav_path):
        raise Exception("Error al convertir audio a WAV")

    return title


def process_url_item(tid):
    """Descargar audio de URL y transcribir."""
    with queue_lock:
        t = transcriptions.get(tid)
        if not t:
            return

    try:
        output_base = os.path.join(app.config["UPLOAD_FOLDER"], t["stored_name"])
        with queue_lock:
            t["status"] = "downloading"

        title = download_audio(t["url"], output_base)
        wav_path = output_base + ".wav"

        with queue_lock:
            t["filename"] = title
            t["wav_name"] = t["stored_name"] + ".wav"
            t["status"] = "processing"

        text = transcribe_wav(wav_path, is_mp3=False, tid=tid)
        with queue_lock:
            t["status"] = "done"
            t["text"] = text
            t["progress"] = 100
    except Exception as e:
        with queue_lock:
            t["status"] = "error"
            t["error"] = str(e)


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/upload", methods=["POST"])
def upload():
    files = request.files.getlist("files")
    if not files:
        return jsonify({"error": "No se enviaron archivos"}), 400

    new_ids = []
    for f in files:
        if f.filename == "":
            continue
        tid = f"{len(transcriptions)}_{f.filename}"
        stored_name = f"{len(transcriptions)}_{f.filename}"
        filepath = os.path.join(app.config["UPLOAD_FOLDER"], stored_name)
        f.save(filepath)

        with queue_lock:
            transcriptions[tid] = {
                "filename": f.filename,
                "stored_name": stored_name,
                "status": "pending",
                "text": "",
                "error": "",
                "wav_name": "",
                "progress": 0,
            }
        new_ids.append(tid)

    thread = threading.Thread(target=process_queue, daemon=True)
    thread.start()

    return jsonify({"ids": new_ids})


@app.route("/url", methods=["POST"])
def url_transcribe():
    data = request.get_json()
    url = data.get("url", "").strip() if data else ""
    if not url:
        return jsonify({"error": "No se envio URL"}), 400

    tid = f"{len(transcriptions)}_url"
    stored_name = f"{len(transcriptions)}_url_audio"

    with queue_lock:
        transcriptions[tid] = {
            "filename": url[:60],
            "stored_name": stored_name,
            "status": "downloading",
            "text": "",
            "error": "",
            "wav_name": "",
            "url": url,
        }

    thread = threading.Thread(target=process_url_item, args=(tid,), daemon=True)
    thread.start()

    return jsonify({"id": tid})


@app.route("/status")
def status():
    with queue_lock:
        return jsonify(
            {
                tid: {
                    "filename": t["filename"],
                    "status": t["status"],
                    "text": t["text"],
                    "error": t["error"],
                    "wav_name": t.get("wav_name", ""),
                    "progress": t.get("progress", 0),
                }
                for tid, t in transcriptions.items()
            }
        )


@app.route("/audio/<path:tid>")
def audio(tid):
    with queue_lock:
        t = transcriptions.get(tid)
        if t and t.get("wav_name"):
            return send_from_directory(
                app.config["UPLOAD_FOLDER"], t["wav_name"], mimetype="audio/wav"
            )
    return "No encontrado", 404


@app.route("/delete/<path:tid>", methods=["DELETE"])
def delete(tid):
    with queue_lock:
        if tid in transcriptions:
            t = transcriptions[tid]
            for key in ["stored_name", "wav_name"]:
                name = t.get(key, "")
                if name:
                    path = os.path.join(app.config["UPLOAD_FOLDER"], name)
                    if os.path.exists(path):
                        os.remove(path)
            del transcriptions[tid]
            return jsonify({"ok": True})
    return jsonify({"error": "No encontrado"}), 404


if __name__ == "__main__":
    print("\n  Transcriptor Antigravity")
    print("  Abre en tu navegador: http://localhost:5050\n")
    app.run(debug=False, port=5050)
