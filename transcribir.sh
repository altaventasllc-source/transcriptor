#!/bin/bash
# Transcriptor de audio/video usando Whisper (modelo medium, español)
# Uso: ./transcribir.sh archivo.opus [modelo]
# Formatos soportados: .opus, .mp3, .mp4, .m4a, .wav, .webm, .ogg, .flac

export PATH="$HOME/Library/Python/3.9/bin:$PATH"

if [ -z "$1" ]; then
    echo "Uso: ./transcribir.sh <archivo_audio_o_video> [modelo]"
    echo "Modelos: tiny, base, small, medium (default), large"
    exit 1
fi

MODEL="${2:-medium}"
INPUT="$1"
OUTPUT_DIR="$(dirname "$INPUT")"

echo "Transcribiendo: $INPUT"
echo "Modelo: $MODEL"
echo "Idioma: Español"
echo "---"

whisper "$INPUT" --model "$MODEL" --language Spanish --output_dir "$OUTPUT_DIR" --output_format txt

echo "---"
echo "Transcripción guardada en: ${INPUT%.*}.txt"
