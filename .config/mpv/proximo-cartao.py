#!/usr/bin/env python3
"""Desenha o cartão "A seguir" em HTML/CSS e entrega bitmaps ao mpv.

Entrada (stdin): {"ep","titulo","nome","img","s","saida"}. Saída: JSON com tamanhos e peças.
Folha = cartão + peças (anel da contagem, botões em destaque, carregando), BGRA pré-multiplicado.
"""
import html
import json
import os
import subprocess
import sys
import tempfile

e = json.load(sys.stdin)
s = float(e["s"]) * 1.15   # tamanho geral do cartão
M, CW, CH = 48, 680, 590          # margem da sombra, cartão
IH, P, BH = 382, 24, 68           # imagem, respiro, botão
IW = CW - 2 * P
WA = 392
WB = IW - WA - 14
BY = CH - P - BH
ANEL, COLS, N = 84, 18, 121       # 121 quadros: 15 s a 8 por segundo
LARG = max(CW + 2 * M, COLS * ANEL, IW)
Y0 = CH + 2 * M
LIN = -(-N // COLS)
YB = Y0 + LIN * ANEL + 10
ALT = YB + BH * 2 + 20
t = lambda x: html.escape(str(x or ""))
titulo = e.get("titulo") or f"Episódio {e['ep']}"
sub = " · ".join(x for x in [f"Episódio {e['ep']}" if e.get("titulo") else "", e.get("nome") or ""] if x)
img = "file://" + e["img"] if e.get("img") else ""
_F = "file://" + os.path.expanduser("~/.projetos/anime/public/")
FONTE, FONTE2 = _F + "bebasneue.woff2", _F + "montserrat.woff2"
r = 33
C = 2 * 3.14159265 * r
aneis = "".join(
    f'<svg class=anel style="left:{(i % COLS) * ANEL}px;top:{Y0 + i // COLS * ANEL}px" viewBox="0 0 84 84">'
    f'<circle cx=42 cy=42 r=38 fill="rgba(11,11,15,.72)"/><circle cx=42 cy=42 r={r} class=tr />'
    f'<circle cx=42 cy=42 r={r} class=ar stroke-dasharray="{C * i / (N - 1):.2f} 999" transform="rotate(-90 42 42)"/>'
    f'<text x=42 y=53>{max(0, -(-(N - 1 - i) // 8))}</text></svg>' for i in range(N))
PLAY = '<svg class=ic viewBox="0 0 24 24"><path d="M7 4.6c0-1 1.1-1.6 2-1.1l11.2 7.4c.8.5.8 1.700 0 2.200L9 20.500c-.9.6-2 0-2-1.100z"/></svg>'
doc = f"""<!doctype html><meta charset=utf-8><style>
*{{box-sizing:border-box;margin:0}}html,body{{background:transparent;width:{LARG}px;height:{ALT}px;overflow:hidden}}
@font-face{{font-family:Bebas;src:url('{FONTE}')}}@font-face{{font-family:Montserrat;font-weight:400 800;src:url('{FONTE2}')}}
body{{font-family:Montserrat,Roboto,sans-serif;color:#fff;position:relative;-webkit-font-smoothing:antialiased}}
.c{{position:absolute;left:{M}px;top:{M}px;width:{CW}px;height:{CH}px;border-radius:26px;overflow:hidden;background:#0b0b0f;box-shadow:0 14px 40px rgba(0,0,0,.55)}}
.c:after{{content:"";position:absolute;inset:0;border-radius:26px;border:1px solid rgba(255,255,255,.14)}}
.i{{position:absolute;inset:0 0 auto;height:{BY - 40}px;background:#1a1a22 center 30%/cover}}
.i:after{{content:"";position:absolute;inset:0;background:linear-gradient(180deg,rgba(11,11,15,0) 40%,rgba(11,11,15,.72) 72%,#0b0b0f 100%)}}
.x{{position:absolute;left:{P + 4}px;right:{P + 4}px;bottom:{CH - BY + 18}px}}
.k{{display:inline-block;background:#e50914;font-size:19px;font-weight:700;border-radius:20px;padding:4px 15px}}
h1{{font:400 {66 if len(titulo) < 24 else 52}px/.95 Bebas,sans-serif;letter-spacing:.01em;margin-top:8px;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden}}
.s{{font-size:25px;font-weight:500;color:#d3d3da;margin-top:3px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}}
.b{{position:absolute;height:{BH}px;border-radius:14px;display:flex;align-items:center;justify-content:center;gap:12px;font-size:27px;font-weight:700}}
.p{{background:#e50914}}.g{{background:#272731;font-weight:600}}
.ph{{background:#ff2a35}}.gh{{background:#3b3b47}}
.ic{{width:28px;height:28px;fill:currentColor}}
.anel{{position:absolute;width:{ANEL}px;height:{ANEL}px}}.tr,.ar{{fill:none;stroke:rgba(255,255,255,.2);stroke-width:5}}.ar{{stroke:#e50914;stroke-linecap:round}}
text{{font:700 31px Montserrat;fill:#fff;text-anchor:middle}}
.l{{border-radius:0;background:#0b0b0f;color:#d3d3da;font-weight:600}}
.l i{{width:30px;height:30px;border-radius:50%;border:4px solid rgba(255,255,255,.2);border-top-color:#e50914}}
</style><div class=c><div class=i style="background-image:url('{t(img)}')"></div>
<div class=x><div class=k>A seguir</div><h1>{t(titulo)}</h1><div class=s>{t(sub)}</div></div>
<div class="b p" style="left:{P}px;top:{BY}px;width:{WA}px">{PLAY}Reproduzir agora</div>
<div class="b g" style="left:{P + WA + 14}px;top:{BY}px;width:{WB}px">Cancelar</div></div>{aneis}
<div class="b p ph" style="left:0;top:{YB}px;width:{WA}px">{PLAY}Reproduzir agora</div>
<div class="b g gh" style="left:{WA + 14}px;top:{YB}px;width:{WB}px">Cancelar</div>
<div class="b l" style="left:0;top:{YB + BH + 10}px;width:{IW}px"><i></i>Carregando episódio</div>"""
saida = e["saida"]
base = os.path.expanduser("~/.cache/mpv-proximo")
with tempfile.TemporaryDirectory(dir=base) as d:
    pag, png = d + "/c.html", d + "/c.png"
    open(pag, "w").write(doc)
    # sobra de altura: o headless corta a parte de baixo da janela
    subprocess.run(["chromium", "--headless=new", "--disable-gpu", "--no-first-run", "--hide-scrollbars", "--allow-file-access-from-files",
                    f"--user-data-dir={d}/perfil", "--default-background-color=00000000", f"--force-device-scale-factor={s}",
                    f"--window-size={LARG},{ALT + 200}", f"--screenshot={png}", "file://" + pag],
                   check=True, timeout=25, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    W, H = round(LARG * s), round(ALT * s)
    bw, bh = round((CW + 2 * M) * s), round(Y0 * s)
    ff = ["ffmpeg", "-v", "error", "-y", "-i", png]
    raw = ["-f", "rawvideo", "-pix_fmt", "bgra"]
    pm = "format=gbrap,geq=r='r(X,Y)*alpha(X,Y)/255{k}':g='g(X,Y)*alpha(X,Y)/255{k}':b='b(X,Y)*alpha(X,Y)/255{k}':a='alpha(X,Y){k}',format=bgra"
    subprocess.run(ff + ["-vf", f"crop={W}:{H}:0:0," + pm.format(k="")] + raw + [saida + ".folha"], check=True)
    subprocess.run(ff + ["-vf", f"crop={bw}:{bh}:0:0,loop=7:1:0," + pm.format(k="*(N+1)/8"), "-frames:v", "8"] + raw + [saida + ".fade"], check=True)
assert os.path.getsize(saida + ".folha") == W * H * 4 and os.path.getsize(saida + ".fade") == bw * bh * 4 * 8
q = lambda *v: [round(x * s) for x in v]
print(json.dumps({"W": W, "bw": bw, "bh": bh, "m": round(M * s), "cw": round(CW * s), "ch": round(CH * s),
                  "anel": q(ANEL)[0], "cols": COLS, "n": N, "y0": Y0, "passo": ANEL, "s": s,
                  "ax": round((CW - ANEL - 20) * s), "ay": round(20 * s), "by": round(BY * s), "bx": round(P * s),
                  "wa": round(WA * s), "wb": round(WB * s), "xb": round((P + WA + 14) * s), "sxb": round((WA + 14) * s),
                  "hb": round(BH * s), "iw": round(IW * s), "yb": round(YB * s), "yl": round((YB + BH + 10) * s)}))
