#!/usr/bin/env python3
"""Registra cada pomodoro concluído num CSV local e numa planilha do Google.

O applet Pomodoro do Cinnamon roda este script quando começa uma pausa, ou
seja, quando um pomodoro acabou. Ele é chamado por dois links em ~/.local/bin,
e o nome do link diz qual pausa vem depois:
  pomodoro-pausa-curta  e  pomodoro-pausa-longa

Uso manual:
  registrar.py --codigo     copia o código da planilha (planilha.gs) já com o token
  registrar.py --url LINK   guarda o link do app da Web, testa e envia o pendente
  registrar.py --enviar     só reenvia o que ficou pendente (ex.: estava sem internet)
  registrar.py --testar     confere se a planilha responde (não grava nada)
"""
import csv
import datetime
import json
import os
import subprocess
import sys
import urllib.request
import uuid
from pathlib import Path

DADOS = Path.home() / ".local/share/pomodoro"
CSV = DADOS / "pomodoros.csv"
PENDENTES = DADOS / "pendentes.jsonl"
ERROS = DADOS / "erros.log"
# {"url": "https://script.google.com/macros/s/.../exec", "token": "..."} (fora do git)
CONFIG = Path.home() / ".config/pomodoro/planilha.json"
APPLET = Path.home() / ".config/cinnamon/spices/pomodoro@gregfreeman.org/pomodoro@gregfreeman.org.json"
CAMPOS = ["id", "inicio", "fim", "minutos", "foco", "app", "janela", "pausa"]


def log_erro(msg):
    DADOS.mkdir(parents=True, exist_ok=True)
    with open(ERROS, "a") as f:
        f.write(f"{datetime.datetime.now():%Y-%m-%d %H:%M:%S} {msg}\n")


def minutos_do_pomodoro():
    try:
        return int(json.load(open(APPLET))["pomodoro_duration"]["value"])
    except Exception:
        return 25


def janela_ativa():
    """(app, título) da janela em foco, pelo xprop."""
    try:
        wid = subprocess.run(["xprop", "-root", "_NET_ACTIVE_WINDOW"], capture_output=True, text=True).stdout.split()[-1]
        out = subprocess.run(["xprop", "-id", wid, "WM_CLASS", "_NET_WM_NAME"], capture_output=True, text=True).stdout
        app = titulo = ""
        for linha in out.splitlines():
            if linha.startswith("WM_CLASS"):
                app = linha.split('"')[-2]
            elif linha.startswith("_NET_WM_NAME"):
                titulo = linha.split("=", 1)[1].strip().strip('"')
        return app, titulo
    except Exception:
        return "", ""


def focos_recentes(n=8):
    if not CSV.exists():
        return []
    vistos = []
    for linha in reversed(list(csv.DictReader(open(CSV)))):
        f = linha["foco"].strip()
        if f and f not in vistos:
            vistos.append(f)
    return vistos[:n]


def perguntar_foco(minutos):
    """Janelinha perguntando no que foi o pomodoro. Some sozinha em 5 min."""
    cmd = ["zenity", "--entry", "--title=🍅 Pomodoro concluído",
           f"--text=No que você focou nesses {minutos} minutos?", "--timeout=300"]
    r = subprocess.run(cmd + focos_recentes(), capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else ""


def enviar():
    """Manda as linhas pendentes pra planilha. Devolve a resposta ou None."""
    if not PENDENTES.exists() or not CONFIG.exists() or not json.load(open(CONFIG)).get("url"):
        return None
    linhas = [json.loads(l) for l in open(PENDENTES) if l.strip()]
    if not linhas:
        return None
    resp = chamar_planilha(linhas)
    if resp.get("ok"):
        PENDENTES.unlink()
    else:
        log_erro(f"planilha recusou: {resp}")
    return resp


def chamar_planilha(linhas):
    cfg = json.load(open(CONFIG))
    corpo = json.dumps({"token": cfg["token"], "linhas": linhas}).encode()
    req = urllib.request.Request(cfg["url"], data=corpo, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=20) as r:
        return json.load(r)


def copiar_codigo():
    """planilha.gs com o token deste PC, direto na área de transferência (CopyQ)."""
    token = json.load(open(CONFIG))["token"]
    codigo = (Path(__file__).resolve().parent / "planilha.gs").read_text().replace("COLE_O_TOKEN_AQUI", token)
    copyq = ["flatpak", "run", "--command=copyq", "com.github.hluk.copyq", "copy", "text/plain", "-"]
    if subprocess.run(copyq, input=codigo, text=True, capture_output=True).returncode == 0:
        print("Código copiado! É só colar (Ctrl+V) no editor do Apps Script.")
    else:
        print(codigo)


def guardar_url(url):
    cfg = json.load(open(CONFIG))
    cfg["url"] = url.strip()
    CONFIG.write_text(json.dumps(cfg, indent=2) + "\n")
    print("Teste:", chamar_planilha([]))
    print("Pendentes:", enviar() or "nada pendente")


def criar_config():
    """Gera o token na primeira vez (o link entra depois, com --url)."""
    if CONFIG.exists():
        return
    import secrets
    CONFIG.parent.mkdir(parents=True, exist_ok=True)
    CONFIG.write_text(json.dumps({"url": "", "token": secrets.token_urlsafe(24)}, indent=2) + "\n")
    CONFIG.chmod(0o600)


def registrar(pausa):
    fim = datetime.datetime.now().astimezone().replace(microsecond=0)
    minutos = minutos_do_pomodoro()
    app, janela = janela_ativa()  # antes da janelinha, senão pega ela
    foco = perguntar_foco(minutos)
    linha = {
        "id": uuid.uuid4().hex[:12],
        "inicio": (fim - datetime.timedelta(minutes=minutos)).isoformat(),
        "fim": fim.isoformat(),
        "minutos": minutos,
        "foco": foco,
        "app": app,
        "janela": janela[:150],
        "pausa": pausa,
    }
    DADOS.mkdir(parents=True, exist_ok=True)
    novo = not CSV.exists()
    with open(CSV, "a", newline="") as f:
        w = csv.DictWriter(f, fieldnames=CAMPOS)
        if novo:
            w.writeheader()
        w.writerow(linha)
    with open(PENDENTES, "a") as f:
        f.write(json.dumps(linha, ensure_ascii=False) + "\n")
    enviar()


def main():
    criar_config()
    try:
        if "--codigo" in sys.argv:
            copiar_codigo()
        elif "--url" in sys.argv:
            guardar_url(sys.argv[sys.argv.index("--url") + 1])
        elif "--testar" in sys.argv:
            print(chamar_planilha([]))
        elif "--enviar" in sys.argv:
            print(enviar() or "nada pendente (ou planilha não configurada)")
        else:
            nome = os.path.basename(sys.argv[0])
            registrar("longa" if "longa" in nome else "curta")
    except Exception as e:
        log_erro(repr(e))
        if sys.stdout.isatty():
            raise


if __name__ == "__main__":
    main()
