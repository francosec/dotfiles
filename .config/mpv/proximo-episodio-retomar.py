#!/usr/bin/env python3
"""Responde ao "Resume episode?" do goanime depois da troca automática.

Uso: proximo-episodio-retomar.py PID_GOANIME JANELA EPISODIO PID_MPV_ANTIGO
Só responde se há progresso salvo do episódio, o terminal está sem título e
nenhum MPV abriu. Começado: retoma. Já terminado: começa de novo.
"""
import os
import sqlite3
import subprocess
import sys
import time

goanime, janela, ep, velho = sys.argv[1:5]
DB = os.path.expanduser("~/.local/goanime/tracking/progress.db")


def saida(*a):
    return subprocess.run(a, capture_output=True, text=True).stdout.strip()


def progresso():
    try:
        c = sqlite3.connect(f"file:{DB}?mode=ro", uri=True, timeout=3)
        return c.execute(
            "select playback_time, duration from media_progress "
            "where episode_number=? and playback_time>0 and allanime_id like ? "
            "order by last_updated desc limit 1", (int(ep), f"%:ep{int(ep)}")).fetchone()
    except sqlite3.Error:
        return None


p = progresso()
if not p:
    sys.exit(0)
livre = None  # desde quando: MPV antigo fora, nenhum novo, terminal sem título
fim = time.time() + 100
while time.time() < fim and os.path.exists(f"/proc/{goanime}"):
    mpvs = saida("pgrep", "-x", "-P", goanime, "mpv").split()
    if [m for m in mpvs if m != velho]:
        break
    if not mpvs and not saida("xdotool", "getwindowname", janela):
        livre = livre or time.time()
        if time.time() - livre > 2.5:
            tecla = "n" if p[0] > 0.9 * p[1] else "y"
            subprocess.run(["xdotool", "key", "--window", janela, tecla])
            break
    else:
        livre = None
    time.sleep(0.5)
