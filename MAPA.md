# Mapa — dotfiles (Arch Linux + Hyprland)
Atualizado em 2026-11-27

## Peças

- `.config/zsh/.zprofile` abre Hyprland na tty1. A tecla `t` durante a
  contagem entra no terminal. `trocar-sessao` mantém a opção local de iniciar X.
- `.config/hypr/hyprland.lua` define monitores, workspaces, atalhos e
  inicialização. `teclado.xkb` define o layout do teclado.
- `.config/waybar/` configura a barra. `.local/bin/barpop` abre painéis GTK
  de métricas, áudio, rede e calendário.
- `.config/fuzzel/` configura o launcher. `fundo-wayland` usa awww.
  `cava-fundo` abre Cava numa camada de fundo do Kitty.
- `.local/bin/wayland/` reúne captura, OCR, clipboard, brilho e bloqueio
  de sessão. Os scripts compartilhados com serviços externos podem
  delegar para essa pasta mesmo quando chamados fora da sessão.
- `.config/trava/` contém as páginas de bloqueio. `wayland/trava` usa
  GtkSessionLock e hospeda as páginas via `trava-saver`, com PAM via
  `auth_trava`.

## Fluxos

```text
tty1 → .zprofile → hypr → start-hyprland
Hyprland → Waybar → barpop → PipeWire, playerctl e métricas
Hyprland → fundo-wayland → awww
Hyprland → cava-fundo → Kitty panel → Cava
Hyprland → wayland/trava → GtkSessionLock → trava-saver + PAM
```

Os arquivos ativos da home apontam para o repositório. `hypr` e
`waybar` usam links por arquivo para manter testes e backups nos
diretórios locais. `fuzzel` e `wayland` usam links por pasta.

## Estado e dependências

- `~/.cache/wal/` armazena as cores dos aplicativos. Os dados de
  bloqueio também são locais e lidos por URLs relativas à página.
- `$XDG_RUNTIME_DIR/barhist/` armazena amostras dos gráficos do barpop.
- `~/.local/share/dispositivos.env` guarda valores privados de periféricos.
- Instalação manual e pacotes no README. O instalador antigo ainda se
  refere ao X e não faz parte do fluxo de instalação documentado.

## Pontos frágeis

- Confirme saídas e modos no compositor antes de adaptar os workspaces.
- O caminho Wayland precede os scripts compartilhados. Serviços externos
  precisam dos wrappers de nível superior para localizar a sessão.
- A Waybar também tem um alias local chamado `dwmblocks`. Scripts de
  áudio e barra ainda podem depender desse nome.
- Teste bloqueio e áudio em sessão real. A trava usa um helper PAM
  instalado fora do repositório.
