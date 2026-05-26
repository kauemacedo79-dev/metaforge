#!/bin/bash
# Script de build para o Render
set -e

echo "📦 Instalando dependências Python..."
pip install -r requirements.txt

echo "🎬 Instalando FFmpeg..."
apt-get update -qq && apt-get install -y -qq ffmpeg

echo "📁 Criando diretórios..."
mkdir -p static/uploads static/processed

echo "✅ Build concluído!"
