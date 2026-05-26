#!/usr/bin/env python3
"""
MetaForge — Backend completo com FFmpeg
Deploy: Render.com
"""

import os, json, uuid, subprocess, threading, time
from datetime import datetime
from flask import Flask, render_template, request, jsonify, send_file
from PIL import Image
import piexif

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 500 * 1024 * 1024  # 500MB
UPLOAD = 'static/uploads'
PROCESSED = 'static/processed'
os.makedirs(UPLOAD, exist_ok=True)
os.makedirs(PROCESSED, exist_ok=True)

# ── DISPOSITIVOS ──────────────────────────────────────────────
DEVICES = {
    "samsung_a15": {
        "name": "Samsung Galaxy A15 (Brasil)",
        "make": "samsung", "model": "SM-A155M/DSN",
        "software": "One UI 6.0",
        "focal_length": (40, 10), "f_number": (18, 10),
        "iso": 20, "fl35": 27,
        "exp_n": 1, "exp_d": 100, "subsec": "347",
    },
    "samsung_s24u": { "name":"Galaxy S24 Ultra","make":"samsung","model":"SM-S928B","software":"One UI 6.1","focal_length":(43,10),"f_number":(17,10),"iso":50,"fl35":24,"exp_n":1,"exp_d":120,"subsec":"512" },
    "samsung_s23":  { "name":"Galaxy S23","make":"samsung","model":"SM-S911B","software":"One UI 5.1","focal_length":(41,10),"f_number":(18,10),"iso":50,"fl35":23,"exp_n":1,"exp_d":100,"subsec":"281" },
    "samsung_a54":  { "name":"Galaxy A54","make":"samsung","model":"SM-A546B","software":"One UI 5.1","focal_length":(46,10),"f_number":(18,10),"iso":50,"fl35":26,"exp_n":1,"exp_d":100,"subsec":"193" },
    "samsung_a34":  { "name":"Galaxy A34","make":"samsung","model":"SM-A346B","software":"One UI 5.1","focal_length":(47,10),"f_number":(20,10),"iso":50,"fl35":26,"exp_n":1,"exp_d":100,"subsec":"445" },
    "moto_edge40":  { "name":"Motorola Edge 40","make":"motorola","model":"XT2303-2","software":"Android 13","focal_length":(45,10),"f_number":(18,10),"iso":50,"fl35":25,"exp_n":1,"exp_d":100,"subsec":"128" },
    "moto_g84":     { "name":"Moto G84","make":"motorola","model":"XT2347-1","software":"Android 13","focal_length":(45,10),"f_number":(18,10),"iso":50,"fl35":25,"exp_n":1,"exp_d":100,"subsec":"076" },
    "moto_g54":     { "name":"Moto G54","make":"motorola","model":"XT2343-1","software":"Android 13","focal_length":(47,10),"f_number":(18,10),"iso":50,"fl35":26,"exp_n":1,"exp_d":100,"subsec":"209" },
    "xiaomi_14t":   { "name":"Xiaomi 14T","make":"Xiaomi","model":"24091PN0DG","software":"MIUI 14","focal_length":(42,10),"f_number":(17,10),"iso":50,"fl35":24,"exp_n":1,"exp_d":120,"subsec":"634" },
    "xiaomi_rn13":  { "name":"Redmi Note 13","make":"Xiaomi","model":"23090RA98G","software":"MIUI 14","focal_length":(47,10),"f_number":(18,10),"iso":50,"fl35":26,"exp_n":1,"exp_d":100,"subsec":"412" },
    "iphone15p":    { "name":"iPhone 15 Pro","make":"Apple","model":"iPhone15,2","software":"17.0","focal_length":(43,10),"f_number":(17,10),"iso":50,"fl35":24,"exp_n":1,"exp_d":120,"subsec":"823" },
    "iphone14":     { "name":"iPhone 14","make":"Apple","model":"iPhone14,7","software":"16.0","focal_length":(47,10),"f_number":(18,10),"iso":50,"fl35":26,"exp_n":1,"exp_d":100,"subsec":"567" },
}

# ── JOBS (rastrear progresso de conversão) ───────────────────
jobs = {}  # job_id -> {status, progress, message, output}

def fmt_size(b):
    for u in ['B','KB','MB','GB']:
        if b < 1024: return f"{b:.1f} {u}"
        b /= 1024
    return f"{b:.1f} GB"

def now_exif():
    return datetime.now().strftime("%Y:%m:%d %H:%M:%S")

# ── PROCESSAMENTO DE FOTO ─────────────────────────────────────
def process_photo(input_path, output_path, device_key, custom_date=None, gps=None):
    dev = DEVICES[device_key]
    import random
    subsec = str(random.randint(100, 999))
    dt = custom_date or now_exif()

    img = Image.open(input_path)
    exif = {"0th":{}, "Exif":{}, "GPS":{}, "1st":{}}

    exif["0th"][piexif.ImageIFD.Make]             = dev["make"].encode()
    exif["0th"][piexif.ImageIFD.Model]            = dev["model"].encode()
    exif["0th"][piexif.ImageIFD.Software]         = dev["software"].encode()
    exif["0th"][piexif.ImageIFD.DateTime]         = dt.encode()
    exif["0th"][piexif.ImageIFD.Orientation]      = 1
    exif["0th"][piexif.ImageIFD.XResolution]      = (72,1)
    exif["0th"][piexif.ImageIFD.YResolution]      = (72,1)
    exif["0th"][piexif.ImageIFD.ResolutionUnit]   = 2
    exif["0th"][piexif.ImageIFD.YCbCrPositioning] = 1

    exif["Exif"][piexif.ExifIFD.ExifVersion]           = b"0220"
    exif["Exif"][piexif.ExifIFD.DateTimeOriginal]      = dt.encode()
    exif["Exif"][piexif.ExifIFD.DateTimeDigitized]     = dt.encode()
    exif["Exif"][piexif.ExifIFD.SubSecTime]            = subsec.encode()
    exif["Exif"][piexif.ExifIFD.SubSecTimeOriginal]    = subsec.encode()
    exif["Exif"][piexif.ExifIFD.SubSecTimeDigitized]   = subsec.encode()
    exif["Exif"][piexif.ExifIFD.FocalLength]           = dev["focal_length"]
    exif["Exif"][piexif.ExifIFD.FNumber]               = dev["f_number"]
    exif["Exif"][piexif.ExifIFD.ISOSpeedRatings]       = dev["iso"]
    exif["Exif"][piexif.ExifIFD.ExposureTime]          = (dev["exp_n"], dev["exp_d"])
    exif["Exif"][piexif.ExifIFD.ExposureProgram]       = 2
    exif["Exif"][piexif.ExifIFD.ExposureBiasValue]     = (0,1)
    exif["Exif"][piexif.ExifIFD.ExposureMode]          = 0
    exif["Exif"][piexif.ExifIFD.Flash]                 = 0
    exif["Exif"][piexif.ExifIFD.MeteringMode]          = 5
    exif["Exif"][piexif.ExifIFD.WhiteBalance]          = 0
    exif["Exif"][piexif.ExifIFD.SceneCaptureType]      = 0
    exif["Exif"][piexif.ExifIFD.ColorSpace]            = 1
    exif["Exif"][piexif.ExifIFD.FlashpixVersion]       = b"0100"
    exif["Exif"][piexif.ExifIFD.PixelXDimension]       = img.width
    exif["Exif"][piexif.ExifIFD.PixelYDimension]       = img.height
    exif["Exif"][piexif.ExifIFD.FocalLengthIn35mmFilm] = dev["fl35"]

    if gps:
        lat, lon = gps
        def to_dms(d):
            deg=int(abs(d)); m=int((abs(d)-deg)*60); s=int(((abs(d)-deg)*60-m)*60*100)
            return ((deg,1),(m,1),(s,100))
        exif["GPS"][piexif.GPSIFD.GPSLatitudeRef]  = b"S" if lat<0 else b"N"
        exif["GPS"][piexif.GPSIFD.GPSLatitude]     = to_dms(lat)
        exif["GPS"][piexif.GPSIFD.GPSLongitudeRef] = b"W" if lon<0 else b"E"
        exif["GPS"][piexif.GPSIFD.GPSLongitude]    = to_dms(lon)

    img.save(output_path, "JPEG", exif=piexif.dump(exif), quality=95)
    return True

# ── ANÁLISE DE VÍDEO ─────────────────────────────────────────
def analyze_video_ffprobe(path):
    cmd = ["ffprobe","-v","quiet","-print_format","json",
           "-show_streams","-show_format", path]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    if r.returncode != 0: return None
    return json.loads(r.stdout)

# ── OTIMIZAÇÃO DE VÍDEO ───────────────────────────────────────
def optimize_video_job(job_id, input_path, output_path, device_key,
                        target_res, target_fps, custom_date):
    dev = DEVICES[device_key]
    jobs[job_id]["status"] = "running"

    def update(pct, msg):
        jobs[job_id]["progress"] = pct
        jobs[job_id]["message"]  = msg

    try:
        update(5, "Analisando vídeo original...")

        # Obter info do vídeo
        info = analyze_video_ffprobe(input_path)
        if not info:
            raise Exception("Não foi possível analisar o vídeo")

        vstream = next((s for s in info["streams"] if s["codec_type"]=="video"), None)
        if not vstream: raise Exception("Stream de vídeo não encontrado")

        orig_w = int(vstream.get("width", 1920))
        orig_h = int(vstream.get("height", 1080))
        orig_fps_str = vstream.get("r_frame_rate","30/1")
        orig_fps_parts = orig_fps_str.split("/")
        orig_fps = float(orig_fps_parts[0]) / float(orig_fps_parts[1]) if len(orig_fps_parts)==2 else 30

        update(15, "Calculando parâmetros de otimização...")

        # Definir resolução alvo
        is_vertical = orig_h > orig_w
        if target_res == "1080p":
            if is_vertical: tw, th = 1080, 1920
            else:           tw, th = 1920, 1080
        elif target_res == "720p":
            if is_vertical: tw, th = 720, 1280
            else:           tw, th = 1280, 720
        else:
            tw, th = orig_w, orig_h  # manter original

        # FPS alvo
        fps_out = int(target_fps) if target_fps else 30

        update(20, f"Convertendo para {tw}×{th} @ {fps_out}fps...")

        dt_str = custom_date or datetime.now().strftime("%Y-%m-%dT%H:%M:%S")

        # Construir comando FFmpeg
        vf_filters = []
        if tw != orig_w or th != orig_h:
            vf_filters.append(f"scale={tw}:{th}:force_original_aspect_ratio=decrease")
            vf_filters.append(f"pad={tw}:{th}:(ow-iw)/2:(oh-ih)/2")

        vf = ",".join(vf_filters) if vf_filters else None

        cmd = ["ffmpeg", "-y", "-i", input_path]

        if vf:
            cmd += ["-vf", vf]

        cmd += [
            "-r", str(fps_out),
            "-c:v", "libx264",
            "-profile:v", "high",
            "-level", "4.0",
            "-preset", "fast",
            "-crf", "18",
            "-c:a", "aac",
            "-b:a", "128k",
            "-movflags", "+faststart",
            "-map_metadata", "-1",
            "-metadata", f"make={dev['make']}",
            "-metadata", f"model={dev['model']}",
            "-metadata", f"software={dev['software']}",
            "-metadata", f"creation_time={dt_str}",
            "-metadata", f"com.android.manufacturer={dev['make']}",
            "-metadata", f"com.android.model={dev['model']}",
            "-metadata", f"com.android.version={dev['software']}",
        ]

        cmd.append(output_path)

        # Executar FFmpeg com progresso
        proc = subprocess.Popen(
            cmd,
            stderr=subprocess.PIPE,
            universal_newlines=True
        )

        # Duração total para calcular progresso
        dur_info = info.get("format",{}).get("duration","0")
        total_dur = float(dur_info) if dur_info else 30.0

        for line in proc.stderr:
            if "time=" in line:
                try:
                    t = line.split("time=")[1].split(" ")[0]
                    parts = t.split(":")
                    if len(parts)==3:
                        secs = float(parts[0])*3600 + float(parts[1])*60 + float(parts[2])
                        pct = min(20 + int((secs/total_dur)*75), 95)
                        update(pct, f"Convertendo... {secs:.0f}s / {total_dur:.0f}s")
                except: pass

        proc.wait()
        if proc.returncode != 0:
            raise Exception("Erro na conversão FFmpeg")

        update(98, "Finalizando...")
        size = os.path.getsize(output_path)
        jobs[job_id]["status"]  = "done"
        jobs[job_id]["progress"] = 100
        jobs[job_id]["message"]  = "Concluído!"
        jobs[job_id]["output"]   = os.path.basename(output_path)
        jobs[job_id]["size"]     = fmt_size(size)

    except Exception as e:
        jobs[job_id]["status"]  = "error"
        jobs[job_id]["message"] = str(e)

# ── ROTAS ────────────────────────────────────────────────────

@app.route('/')
def index():
    return render_template('index.html', devices=DEVICES, server_mode=True)

@app.route('/api/devices')
def api_devices():
    return jsonify(DEVICES)

@app.route('/api/upload', methods=['POST'])
def upload():
    if 'file' not in request.files:
        return jsonify({"error":"Nenhum arquivo"}), 400
    f = request.files['file']
    ext = f.filename.rsplit('.',1)[-1].lower() if '.' in f.filename else 'bin'
    ftype = 'photo' if ext in ['jpg','jpeg','png','webp','heic'] else 'video'
    fid = str(uuid.uuid4())
    fname = f"{fid}.{ext}"
    fpath = os.path.join(UPLOAD, fname)
    f.save(fpath)
    size = os.path.getsize(fpath)

    orig_meta = {"make":"—","model":"—","date":"—"}
    specs = {}

    if ftype == 'photo':
        try:
            img = Image.open(fpath)
            raw = img.info.get('exif', b'')
            if raw:
                ed = piexif.load(raw)
                make  = ed["0th"].get(piexif.ImageIFD.Make, b'').decode(errors='ignore').strip('\x00')
                model = ed["0th"].get(piexif.ImageIFD.Model,b'').decode(errors='ignore').strip('\x00')
                dt    = ed["Exif"].get(piexif.ExifIFD.DateTimeOriginal,b'').decode(errors='ignore').strip('\x00')
                orig_meta = {"make":make or "—","model":model or "—","date":dt or "—"}
        except: pass

    elif ftype == 'video':
        try:
            info = analyze_video_ffprobe(fpath)
            if info:
                vs = next((s for s in info["streams"] if s["codec_type"]=="video"), None)
                tags = info.get("format",{}).get("tags",{})
                orig_meta = {
                    "make":  tags.get("make", tags.get("com.android.manufacturer","—")),
                    "model": tags.get("model", tags.get("com.android.model","—")),
                    "date":  tags.get("creation_time","—")
                }
                if vs:
                    dur = float(info["format"].get("duration",0))
                    br  = int(info["format"].get("bit_rate",0))
                    fps_str = vs.get("r_frame_rate","30/1").split("/")
                    fps = round(float(fps_str[0])/float(fps_str[1])) if len(fps_str)==2 else 30
                    specs = {
                        "width":    int(vs.get("width",0)),
                        "height":   int(vs.get("height",0)),
                        "fps":      fps,
                        "duration": round(dur,1),
                        "bitrate":  round(br/1000000,1),
                        "codec":    vs.get("codec_name",""),
                    }
        except: pass

    return jsonify({
        "file_id":     fid,
        "ext":         ext,
        "type":        ftype,
        "filename":    f.filename,
        "size":        fmt_size(size),
        "orig_meta":   orig_meta,
        "specs":       specs,
    })

@app.route('/api/process_photo', methods=['POST'])
def api_process_photo():
    data = request.json
    fid  = data.get('file_id')
    ext  = data.get('ext','jpg')
    dev  = data.get('device')
    gps  = data.get('gps')
    dt   = data.get('custom_date')

    if not fid or dev not in DEVICES:
        return jsonify({"error":"Dados inválidos"}), 400

    inp = os.path.join(UPLOAD, f"{fid}.{ext}")
    out_name = f"{fid}_metaforge.jpg"
    out = os.path.join(PROCESSED, out_name)

    try:
        process_photo(inp, out, dev, dt, gps)
        return jsonify({"success":True,"output":out_name,"size":fmt_size(os.path.getsize(out))})
    except Exception as e:
        return jsonify({"error":str(e)}), 500

@app.route('/api/process_video', methods=['POST'])
def api_process_video():
    """Aplicar apenas metadados no vídeo (sem recodificar)."""
    data = request.json
    fid  = data.get('file_id')
    ext  = data.get('ext','mp4')
    dev  = data.get('device')
    dt   = data.get('custom_date') or datetime.now().strftime("%Y-%m-%dT%H:%M:%S")

    if not fid or dev not in DEVICES:
        return jsonify({"error":"Dados inválidos"}), 400

    d   = DEVICES[dev]
    inp = os.path.join(UPLOAD, f"{fid}.{ext}")
    out_name = f"{fid}_metaforge.{ext}"
    out = os.path.join(PROCESSED, out_name)

    cmd = [
        "ffmpeg","-y","-i", inp,
        "-c","copy",
        "-map_metadata","-1",
        "-metadata", f"make={d['make']}",
        "-metadata", f"model={d['model']}",
        "-metadata", f"software={d['software']}",
        "-metadata", f"creation_time={dt}",
        "-metadata", f"com.android.manufacturer={d['make']}",
        "-metadata", f"com.android.model={d['model']}",
        "-metadata", f"com.android.version={d['software']}",
        "-movflags","+faststart",
        out
    ]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    if r.returncode != 0:
        return jsonify({"error": r.stderr[-300:]}), 500

    return jsonify({"success":True,"output":out_name,"size":fmt_size(os.path.getsize(out))})

@app.route('/api/optimize_video', methods=['POST'])
def api_optimize_video():
    """Otimizar vídeo para TikTok com FFmpeg + aplicar metadados."""
    data       = request.json
    fid        = data.get('file_id')
    ext        = data.get('ext','mp4')
    dev        = data.get('device','samsung_a15')
    target_res = data.get('resolution','1080p')   # 1080p | 720p | original
    target_fps = data.get('fps', 30)
    dt         = data.get('custom_date')

    if not fid:
        return jsonify({"error":"file_id obrigatório"}), 400

    inp      = os.path.join(UPLOAD, f"{fid}.{ext}")
    out_name = f"{fid}_tiktok.mp4"
    out      = os.path.join(PROCESSED, out_name)
    job_id   = str(uuid.uuid4())

    jobs[job_id] = {"status":"queued","progress":0,"message":"Aguardando...","output":None,"size":None}

    t = threading.Thread(
        target=optimize_video_job,
        args=(job_id, inp, out, dev, target_res, target_fps, dt),
        daemon=True
    )
    t.start()

    return jsonify({"job_id": job_id})

@app.route('/api/job/<job_id>')
def api_job(job_id):
    job = jobs.get(job_id)
    if not job: return jsonify({"error":"Job não encontrado"}), 404
    return jsonify(job)

@app.route('/api/analyze_video', methods=['POST'])
def api_analyze_video():
    """Análise precisa com ffprobe."""
    data = request.json
    fid  = data.get('file_id')
    ext  = data.get('ext','mp4')
    path = os.path.join(UPLOAD, f"{fid}.{ext}")
    info = analyze_video_ffprobe(path)
    if not info: return jsonify({"error":"Não foi possível analisar"}), 500
    vs   = next((s for s in info["streams"] if s["codec_type"]=="video"), None)
    as_  = next((s for s in info["streams"] if s["codec_type"]=="audio"), None)
    dur  = float(info["format"].get("duration",0))
    br   = int(info["format"].get("bit_rate",0))
    fps_str = vs.get("r_frame_rate","30/1").split("/") if vs else ["30","1"]
    fps  = round(float(fps_str[0])/float(fps_str[1]),2) if len(fps_str)==2 else 30
    return jsonify({
        "width":    int(vs.get("width",0)) if vs else 0,
        "height":   int(vs.get("height",0)) if vs else 0,
        "fps":      fps,
        "duration": round(dur,2),
        "bitrate_mbps": round(br/1000000,2),
        "codec_video":  vs.get("codec_name","") if vs else "",
        "codec_audio":  as_.get("codec_name","") if as_ else "",
        "audio_bitrate": round(int(as_.get("bit_rate",0))/1000) if as_ else 0,
        "size_mb":  round(os.path.getsize(path)/1048576,1),
    })

@app.route('/api/download/<filename>')
def download(filename):
    path = os.path.join(PROCESSED, filename)
    if not os.path.exists(path): return "Não encontrado", 404
    return send_file(path, as_attachment=True)

@app.route('/api/cleanup', methods=['POST'])
def cleanup():
    data = request.json
    fid  = data.get('file_id')
    if fid:
        for folder in [UPLOAD, PROCESSED]:
            for f in os.listdir(folder):
                if f.startswith(fid):
                    try: os.remove(os.path.join(folder,f))
                    except: pass
    return jsonify({"ok":True})

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)
