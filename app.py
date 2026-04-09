import os
import sys
import json
import subprocess
import threading
from pathlib import Path
from flask import Flask, render_template, request, jsonify, send_from_directory

# faster-whisper: mismo modelo de OpenAI pero motor más eficiente
sys.path.insert(0, os.path.expanduser("~/Library/Python/3.9/lib/python/site-packages"))
from faster_whisper import WhisperModel

app = Flask(__name__)
app.config["UPLOAD_FOLDER"] = os.path.join(os.path.dirname(__file__), "uploads")
app.config["MAX_CONTENT_LENGTH"] = 500 * 1024 * 1024  # 500MB max

os.makedirs(app.config["UPLOAD_FOLDER"], exist_ok=True)

# Estado global de transcripciones
transcriptions = {}  # id -> {filename, status, text, error, wav_name}
queue_lock = threading.Lock()
model = None


def get_model():
    global model
    if model is None:
        model = WhisperModel("medium", device="cpu", compute_type="int8")
    return model


def convert_to_wav(filepath, wav_name):
    """Convertir a WAV 16kHz mono con 2s de silencio real al inicio.
    Genera silencio como audio real y lo concatena con el archivo."""
    wav_path = os.path.join(app.config["UPLOAD_FOLDER"], wav_name)
    silence_path = wav_path + ".silence.wav"
    temp_audio_path = wav_path + ".temp.wav"

    # 1. Generar 2 segundos de silencio real
    subprocess.run(
        ["ffmpeg", "-y", "-f", "lavfi", "-i",
         "anullsrc=r=16000:cl=mono", "-t", "2",
         "-c:a", "pcm_s16le", silence_path],
        capture_output=True
    )
    # 2. Convertir el audio original a WAV 16kHz mono
    subprocess.run(
        ["ffmpeg", "-y", "-i", filepath,
         "-ar", "16000", "-ac", "1",
         "-c:a", "pcm_s16le", temp_audio_path],
        capture_output=True
    )
    # 3. Concatenar silencio + audio
    subprocess.run(
        ["ffmpeg", "-y",
         "-i", silence_path, "-i", temp_audio_path,
         "-filter_complex", "[0:a][1:a]concat=n=2:v=0:a=1",
         "-ar", "16000", "-ac", "1",
         "-c:a", "pcm_s16le", wav_path],
        capture_output=True
    )
    # Limpiar temporales
    for p in [silence_path, temp_audio_path]:
        if os.path.exists(p):
            os.remove(p)
    return wav_path


def get_audio_duration(filepath):
    """Obtener duración en segundos."""
    result = subprocess.run(
        ["ffprobe", "-v", "quiet", "-show_entries", "format=duration",
         "-of", "default=noprint_wrappers=1:nokey=1", filepath],
        capture_output=True, text=True
    )
    return float(result.stdout.strip())


def transcribe_segment(m, chunk_path):
    """Transcribir un segmento con faster-whisper."""
    segments, _ = m.transcribe(
        chunk_path,
        language="es",
        beam_size=5,
        word_timestamps=True,
        vad_filter=False,
        condition_on_previous_text=False,
    )
    parts = []
    for seg in segments:
        text = seg.text.strip()
        if text:
            parts.append(text)
    return " ".join(parts)


def transcribe_wav(wav_path):
    """Transcribir WAV en segmentos de 15s con 5s de solapamiento."""
    import shutil
    m = get_model()
    duration = get_audio_duration(wav_path)

    chunk_dir = wav_path + "_segments"
    os.makedirs(chunk_dir, exist_ok=True)

    CHUNK = 15
    OVERLAP = 5

    try:
        parts = []
        start = 0.0
        idx = 0
        while start < duration:
            chunk_len = min(CHUNK + OVERLAP, duration - start + 0.5)
            chunk_path = os.path.join(chunk_dir, f"seg_{idx:04d}.wav")
            subprocess.run(
                ["ffmpeg", "-y", "-i", wav_path,
                 "-ss", str(start), "-t", str(chunk_len),
                 "-ar", "16000", "-ac", "1", "-c:a", "pcm_s16le",
                 chunk_path],
                capture_output=True
            )
            text = transcribe_segment(m, chunk_path)
            if text:
                parts.append(text)
            start += CHUNK
            idx += 1

        return " ".join(parts)
    finally:
        shutil.rmtree(chunk_dir, ignore_errors=True)


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
            text = transcribe_wav(wav_path)
            with queue_lock:
                t["status"] = "done"
                t["text"] = text
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
            }
        new_ids.append(tid)

    # Lanzar procesamiento en hilo
    thread = threading.Thread(target=process_queue, daemon=True)
    thread.start()

    return jsonify({"ids": new_ids})


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
            # Borrar archivo original
            stored = t.get("stored_name", "")
            filepath = os.path.join(app.config["UPLOAD_FOLDER"], stored)
            if os.path.exists(filepath):
                os.remove(filepath)
            # Borrar WAV convertido
            wav = t.get("wav_name", "")
            wav_path = os.path.join(app.config["UPLOAD_FOLDER"], wav)
            if wav and os.path.exists(wav_path):
                os.remove(wav_path)
            del transcriptions[tid]
            return jsonify({"ok": True})
    return jsonify({"error": "No encontrado"}), 404


if __name__ == "__main__":
    print("\n  Transcriptor Antigravity")
    print("  Abre en tu navegador: http://localhost:5050\n")
    app.run(debug=False, port=5050)
