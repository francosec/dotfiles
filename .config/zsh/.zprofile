export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/bin/statusbar:$PATH"
# Interface gráfica só na tty1 (as outras TTYs ficam em texto).
# Sessão na tty1: Hyprland por padrão; `trocar-sessao dwm` marca o dwm só para o próximo login.
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
  marca="$HOME/.cache/sessao-proxima"
  sessao=$(cat "$marca" 2>/dev/null); rm -f "$marca"
  if [ -z "$sessao" ]; then
    # Hyprland é o padrão (dwm aposentado em 27/11/2026). [t] em 2 s = só terminal, para consertar algo.
    printf '\n  Hyprland em 2 s   ·   [t] só terminal\n  > '
    read -t 2 -k 1 r; echo
    case "$r" in t|T) sessao=terminal ;; *) sessao=hypr ;; esac
  fi
  case "$sessao" in
    terminal) ;;
    dwm) startx ;;   # só via `trocar-sessao dwm`, se um dia precisar
    *) hypr ;;
  esac
fi
