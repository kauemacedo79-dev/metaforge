# ⚙️ MetaForge v3.0 — Deploy no Render

## Como fazer o deploy

### 1. Criar conta no GitHub
- Acesse github.com e crie uma conta gratuita
- Crie um repositório novo chamado `metaforge`
- Faça upload de todos os arquivos desta pasta

### 2. Criar conta no Render
- Acesse render.com
- Clique em "New +" → "Web Service"
- Conecte seu GitHub e selecione o repositório `metaforge`

### 3. Configurar o serviço
Preencha assim:
- **Name:** metaforge
- **Runtime:** Python 3
- **Build Command:** `pip install -r requirements.txt`
- **Start Command:** `gunicorn app:app --workers 2 --timeout 600 --bind 0.0.0.0:$PORT`

### 4. Adicionar FFmpeg
No Render, vá em **Environment** e adicione:
- Key: `FFMPEG_PATH` Value: `/usr/bin/ffmpeg`

O Render já tem FFmpeg instalado no ambiente — não precisa instalar manualmente.

### 5. Deploy
Clique em "Create Web Service" e aguarde ~3 minutos.

Seu link será: `https://metaforge-xxxx.onrender.com`

---

## Funcionalidades v3.0

| Funcionalidade | Status |
|---------------|--------|
| Substituir EXIF foto (piexif) | ✅ |
| Limpar XMP, IPTC, APP13/14 | ✅ |
| Metadados vídeo (FFmpeg real) | ✅ |
| Otimizar vídeo para TikTok | ✅ NOVO |
| Converter 4K → 1080p | ✅ NOVO |
| Converter 120fps → 30fps | ✅ NOVO |
| Análise precisa com ffprobe | ✅ NOVO |
| Score TikTok com dados reais | ✅ NOVO |
| Progresso em tempo real | ✅ NOVO |
| Copiar EXIF de referência | ✅ |
| Visualizador de metadados | ✅ |
