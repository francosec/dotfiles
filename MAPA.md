# Mapa — dotfiles (desktop Arch + dwm)
Atualizado: 2026-11-25

## O que é
Repositório `github.com/odrdk/dotfiles` com toda a configuração do desktop:
dwm, barra, terminal, editor, tela de bloqueio, temas e scripts do dia a dia.
Mora em `~/.projetos/dotfiles`; cada pasta de `~/.config` e cada script de
`~/.local/bin` é um link para cá (77 links). O caminho antigo
`~/Documents/dotfiles` virou link para não quebrar nada.

## Peças
Instalação
- `install.sh` — pacotes (yay, multilib), links para `~/.config` e `~/.local/bin`
- `instalar-arch-luks.sh` — instalação do Arch com LUKS no SSD escolhido
- `sistema/` — arquivos de `/etc` e afins; `img/` — prints do README
Ambiente gráfico (`.config/`)
- `suckless/` — dwm, dwmblocks-async, dmenu, st, slock (código C com patches)
- `picom/`, `dunst/`, `xmenu/`, `xsettingsd/`, `qt5ct/`, `qt6ct/`, `wal/templates/`
- `trava/` — dados da tela de bloqueio (xsecurelock + páginas)
Apps
- `nvim/` (lua `emnesty`), `kitty/`, `alacritty/`, `zsh/` (+ plugins), `ranger/`
- `qutebrowser/`, `mpv/`, `cmus/`, `mpd/`, `ncmpcpp/`, `cava/`, `zathura/`, `btop/`,
  `flameshot/`, `redshift/`, `sxiv/`, `PCSX2/`, `emacs/`, `neofetch/`
Scripts (`.local/bin/`)
- `statusbar/s_*` — blocos da barra; `statusvolume`, `statusmic`, `statusbrightness`
- `trava-*`, `alwayslock`, `auth_trava`, `lockwall` — tela de bloqueio e páginas
- `vinil` — player da trava (`radar.html`) em janela "Vinil" no monitor escolhido; `vinil-som` — Spotify + microfone na chamada (qualidade de voz); `vinil-web` — vinil + som original numa guia do Brave, 127.0.0.1:5247
- `monitores`, `fundo`, `dwall`, `nightmode`, `picom-alternar` — telas e visual
- `teclado`, `bluetooth`, `fone`, `fixscroll`, `micshift`, `soundshift` — periféricos
- `dfiles`, `dfind`, `dcentral`, `dwifi`, `emoji`, `keybinds`, `layoutmenu` — menus dmenu
- `screenshot`, `snipertext`, `colorpicker`, `webcam`, `phoneview`, `droidmount`
- `atualizar`, `updnotify`, `sync-appimages`, `mullvpn`, `wg`, `chatgpt`, `baby-shark`

### Detalhe: dwm + barra
- dwm — `.config/suckless/dwm/config.def.h` — atalhos, regras, scratchpads
- dwmblocks-async — `.config/suckless/dwmblocks-async/config.c` — lista de blocos, intervalo e sinal de cada um
- blocos — `.local/bin/statusbar/s_*` — cada um imprime um pedaço da barra e trata cliques
- statusvolume / statusmic — `.local/bin/` — ações de volume e microfone (teclas e scroll), via `wpctl`

## Como se conectam
```
install.sh ─ln -s─> ~/.config/<app>  e  ~/.local/bin/<script>
.xinitrc ─> monitores, fundo, picom, dwmblocks, dwm
```
Barra:
```
dwmblocks ──(intervalo ou kill -SINAL)──> s_* ──stdout──> barra do dwm
clique na barra ─ dwm sigstatusbar ─> BLOCK_BUTTON=1..6 ─> s_*
teclas de mídia ─ dwm spawn ─> statusvolume ─> wpctl ─> kill -41 dwmblocks
s_vol / s_mic ──> wpctl (PipeWire)      s_spotify ──> playerctl
```

## Fluxos principais
0. Próximo episódio: mpv a 15 s do fim → cartão → `xdotool` `n` → goanime resolve a URL → fecha o mpv antigo e abre o novo (tela cheia e volume restaurados por `estado.json`).
1. Volume: tecla ou scroll → `statusvolume up|down|mute` → `wpctl` → notificação (dunstify) → sinal 41 → `s_vol` relê com `wpctl`.
2. Clique na barra: botão 1–5 = mouse; 6 = Shift+clique esquerdo (abre o script no nvim).
4. Vinil: atalho → `vinil N` cria a janela → `trava-saver` com `TRAVA_SO_PLAYER=1` desenha dentro dela.
5. Música na chamada: `vinil-som` → Spotify + mic do notebook → `vinil_mix` → `vinil_mic` → entradas do Brave.
6. Som original: Spotify → sink `vinil_web` → `/audio` → Web Audio na guia → Meet (guia com áudio). Sem ouvinte, o Spotify volta à saída padrão.
3. Blocos de 1 s: `s_cmus`, `s_spotify`, `s_vpn` (os mais caros no total).

## Dados e estado
- `$XDG_RUNTIME_DIR/s_cpu.prev` — última leitura de /proc/stat; escrito e lido pelo `s_cpu`.
- `/tmp/cmus_scroll_offset` — posição da rolagem do nome da música no `s_cmus`.

## Dependências externas
PipeWire (`wpctl`), `playerctl`, `cmus-remote`, `mullvad`, `dunstify`, `xdotool`.

## Pontos frágeis — testar mais aqui
- Mudança no `config.def.h` só vale após `sudo make install` + `Super+Shift+R` (o `.xinitrc` relança o dwm).
- `statusvolume`/`statusmic` dependem do `wpctl` (PipeWire); sem ele, teclas de volume param.
- `vinil-web` lê funções do `trava-saver` pelo nome (`_ler_musica`, `_buscar_letra`…); renomear lá quebra aqui.
- `vinil-som` em chamada real ainda não foi testado (só o sinal do `vinil_mic`); o filtro de ruído do Meet pode cortar a música.
- `~/.local/bin/trava-saver` é arquivo próprio, mais novo que a cópia do repositório.
- `s_vpn` e a rolagem do `s_cmus` não foram testados após a mudança de 2026-11-16.

- `mpv/scripts/proximo-episodio.lua` depende dos títulos e teclas do menu do goanime ("GoAnime - Player", `n`); atualização do goanime pode quebrar. Caminho reserva (menu "GoAnime - Menu" → lista, Home + setas) ainda não foi testado no fluxo; supõe lista começando no ep 1. Só funciona em terminal com `WINDOWID` (st), não por SSH/tmux.

## Decisões
- 2026-11-16 — blocos da barra usam `wpctl`/`playerctl` direto — `pulsemixer` (Python) levava ~120 ms por chamada.
- 2026-11-16 — `s_cpu` compara com a execução anterior em vez de `sleep 0.5` — sem espera e mede a média do intervalo de 5 s.
- 2026-11-16 — `Super+Shift+Enter` = só terminal flutuante (zoom fica no clique do meio no título) — os dois disparavam juntos.
- 2026-11-16 — backups do `config.def.h` em `dwm/.copias/` (fora do git) — limpar a pasta sem perder cópias.
- 2026-11-16 — `monitores`: uma troca de modo só (posição + 75 Hz juntos) e `xrandr --current` após a 1ª sondagem; `fundo` em segundo plano — login 5,8 s → 3,0 s nesse script. Tempos do login em `~/.cache/xinit-tempos.log`.
- 2026-11-16 — barra: igual à original (fonte 9, semitransparente), disco só % e RAM só usada, mic mudo = ícone + 0%,, só com o `|` em cinza #6f706f (`SchemeDim` + `drawstatustext()` no dwm.c); o último pedaço recebe a folga de 12 px para o ícone Nerd Font não sair cortado.
- 2026-11-21 — repositório movido para `~/.projetos/dotfiles` com os outros projetos; links de `~/.config` e `~/.local/bin` apontam direto para cá.
- 2026-11-23 — `mpv.conf`: `lanczos` + deband de 1 passada e legenda em caixa a 50% — na UHD 620 em 1440p, `ewa_lanczossharp` leva ~200 ms por quadro (limite a 24 fps: 41,7 ms). Cores no arquivo precisam de aspas, porque `#` abre comentário.
- 2026-11-23 — cartão "A seguir" no mpv: Lua desenha (miniatura do AniList, cache em `~/.cache/mpv-proximo`) e o `xdotool` aperta `n` no terminal do goanime; `mpv/proximo-episodio-retomar.py` responde ao "Resume episode?" — evita manter um goanime próprio compilado.
- 2026-11-23 — `proximo-episodio.lua` também atende o app `~/.projetos/anime` (opção `anime-servidor=1`).
- 2026-11-23 — `vinil` usa janela comum, não override-redirect — só assim Meet e OBS a listam para compartilhar.
- 2026-11-23 — `vinil-som` mistura só o Spotify, não a saída inteira — o som da chamada voltaria como eco.
- 2026-11-23 — `vinil-web`: música pela guia, não pelo microfone — o Meet trata o microfone como voz e estraga a música.
- 2026-11-23 — bloqueio só manual: `alwayslock` não sobe mais o `xautolock`, só impede a tela de apagar — pedido do usuário; `trava-auto` ficou sem uso (volta por `alwayslock.bak-20261123-manual`).
- 2026-11-23 — `vinil-web.service` (usuário, `~/.config/systemd/user`, fora do repositório) mantém a porta 5247 sempre ligada; recria a saída `vinil_web` se o PipeWire reiniciar.
- 2026-11-23 — `vinil_web` como saída padrão calava tudo: o serviço devolve a saída anterior, tira o que não for Spotify de lá, e o `soundshift` não a lista mais.
- 2026-11-25 — guia do `vinil-web`: falha ao iniciar o áudio aparece no botão e o fluxo `/audio` religa sozinho se cair — antes o botão sumia e nada acontecia. O primeiro clique depende do navegador.
