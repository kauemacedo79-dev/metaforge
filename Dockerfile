FROM python:3.11-slim

# Instalar FFmpeg e dependências do sistema
RUN apt-get update && apt-get install -y \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Diretório de trabalho
WORKDIR /app

# Instalar dependências Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código
COPY . .

# Criar diretórios de upload
RUN mkdir -p static/uploads static/processed

# Expor porta
EXPOSE 10000

# Iniciar com gunicorn
CMD gunicorn app:app --workers 2 --timeout 600 --bind 0.0.0.0:$PORT
