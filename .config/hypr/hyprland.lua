-- Hyprland: telas, visual, atalhos e inicialização.
-- O dwm continua instalado; esta sessão abre com `hypr` na tty1 (depois de sair do dwm).
-- Inventário do que existia no dwm: ~/.cache/hypr-migracao/inventario.md

local HOME = os.getenv("HOME")
local terminal = "kitty -o background_opacity=$(cat ~/.cache/st-alpha 2>/dev/null || echo 0.78)"  -- mesma transparência do st
local navegador = "brave"
local mod = "SUPER"

------------------------------------------------------------------ cores (pywal)
-- Lê o colors.json do pywal; o tema acompanha o wallpaper como no dwm.
local function cores_wal()
    local f = io.open(HOME .. "/.cache/wal/colors.json", "r")
    local c = { bg = "060606", fg = "e1e1e1", dim = "9d9d9d" }
    if not f then return c end
    local s = f:read("*a"); f:close()
    c.bg  = (s:match('"background":%s*"#(%x+)"') or c.bg)
    c.fg  = (s:match('"foreground":%s*"#(%x+)"') or c.fg)
    c.dim = (s:match('"color8":%s*"#(%x+)"') or c.dim)
    return c
end
local cor = cores_wal()

------------------------------------------------------------------ telas
-- Notebook à esquerda, tela principal no meio, tela externa à direita.
-- Tela principal: modo personalizado 2560x1440 a 75 Hz (blanking reduzido, 291,06 MHz), o mesmo do script `monitores`.
hl.monitor({ output = "eDP-1",    mode = "1366x768@60", position = "0x336",    scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "modeline 291.06 2560 2568 2600 2640 1440 1443 1448 1470 +hsync -vsync",
             position = "1366x0", scale = 1 })
hl.monitor({ output = "DVI-I-2",  mode = "1920x1080@75", position = "3926x180", scale = 1 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Tags por tela, como no dwm: cada tela tem os seus 1..5.
-- notebook = 1..5, tela principal = 11..15, tela direita = 21..25 (o atalho Super+N escolhe pela tela em foco).
local base_tela = { ["eDP-1"] = 0, ["HDMI-A-1"] = 10, ["DVI-I-2"] = 20 }
for saida, b in pairs(base_tela) do
    for i = 1, 5 do
        hl.workspace_rule({ workspace = tostring(b + i), monitor = saida, persistent = (i == 1), default = (i == 1) })
    end
end

------------------------------------------------------------------ ambiente
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "20")
hl.env("HYPRCURSOR_SIZE", "20")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
-- Versões Wayland de comandos que eram do X (dmenu -> fuzzel etc.) vêm antes no PATH.
hl.env("PATH", HOME .. "/.local/bin/wayland:" .. (os.getenv("PATH") or ""))

------------------------------------------------------------------ visual
hl.config({
    general = {
        gaps_in = 6, gaps_out = 12, border_size = 2,
        col = {
            active_border   = "rgba(" .. cor.fg .. "cc)",
            inactive_border = "rgba(" .. cor.dim .. "33)",
        },
        layout = "master",
        resize_on_border = true,
    },
    decoration = {
        rounding = 12, rounding_power = 2,
        active_opacity = 1.0, inactive_opacity = 1.0,
        shadow = { enabled = true, range = 22, render_power = 3, color = 0xaa000000 },
        -- Vidro igual ao picom: desfoque forte atrás do que for transparente (terminal, barra, pop-ups).
        blur = { enabled = true, size = 6, passes = 3, vibrancy = 0.12, new_optimizations = true, xray = false },
        dim_inactive = false,
    },
    animations = { enabled = true },
    master = { new_status = "slave", mfact = 0.55 },
    dwindle = { preserve_split = true },
    misc = {
        disable_hyprland_logo = true, force_default_wallpaper = 0,
        -- Avisos do overlay de depuração desligados: em 27/11 o Hyprland 0.57.2 travou (deadlock)
        -- desenhando o texto de um desses avisos (Debug::COverlay::createWarningTexture).
        disable_watchdog_warning = true, disable_hyprland_guiutils_check = true, disable_xdg_env_checks = true,
        -- Tela desligada pelo atalho só volta pelo atalho (antes o próprio soltar das teclas a religava).
        mouse_move_enables_dpms = false, key_press_enables_dpms = false,
        focus_on_activate = true,
        -- Se a trava cair, outra (ex.: `hyprlock` via SSH/Termius) pode assumir a tela travada.
        allow_session_lock_restore = true,
    },
    cursor = { no_warps = false },
    input = {
        -- Mapa do teclado exportado do X: ABNT2 + atalhos AltGr do teclado americano (camada abnt-us).
        kb_file = HOME .. "/.config/hypr/teclado.xkb",
        numlock_by_default = true,
        follow_mouse = 1,
        sensitivity = 0,
        repeat_rate = 35, repeat_delay = 280,
    },
})

-- Animações suaves, na pegada dos vídeos de referência.
hl.curve("suave",   { type = "bezier", points = { {0.22, 1}, {0.36, 1} } })
hl.curve("entrada", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.curve("linear",  { type = "bezier", points = { {0, 0}, {1, 1} } })
hl.animation({ leaf = "windowsIn",    enabled = true, speed = 4,   bezier = "entrada", style = "popin 85%" })
hl.animation({ leaf = "windowsOut",   enabled = true, speed = 3,   bezier = "suave",   style = "popin 85%" })
hl.animation({ leaf = "windowsMove",  enabled = true, speed = 4,   bezier = "suave" })
hl.animation({ leaf = "fade",         enabled = true, speed = 4,   bezier = "suave" })
hl.animation({ leaf = "border",       enabled = true, speed = 6,   bezier = "suave" })
hl.animation({ leaf = "layers",       enabled = true, speed = 3,   bezier = "suave", style = "fade" })
hl.animation({ leaf = "workspaces",   enabled = true, speed = 4,   bezier = "suave", style = "slidefade 12%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "suave", style = "slidevert" })

------------------------------------------------------------------ regras de janela
-- Scratchpads do dwm viram "special workspaces" (aparecem por cima, somem no mesmo atalho).
local scratch = {
    term   = { classe = "spterm",   cmd = terminal .. " --class spterm" },
    files  = { classe = "spfiles",  cmd = terminal .. " --class spfiles -e ranger" },
    music  = { classe = "spmusic",  cmd = terminal .. " --class spmusic -e cmus" },
    vol    = { classe = "spvol",    cmd = terminal .. " --class spvol -e pulsemixer" },
    obs    = { classe = "com.obsproject.Studio", cmd = "obs" },
    calc   = { classe = "qalculate-gtk", cmd = "qalculate-gtk" },
    btop   = { classe = "spbtop",   cmd = terminal .. " --class spbtop -e btop" },
}
for nome, s in pairs(scratch) do
    hl.window_rule({ name = "scratch-" .. nome, match = { class = "^" .. s.classe .. "$" },
                     workspace = "special:" .. nome .. " silent", float = true, size = "60% 65%", center = true })
end
local function alterna_scratch(nome)
    return function()
        local s = scratch[nome]
        local existe = false
        for _, w in ipairs(hl.get_windows() or {}) do
            if w.class == s.classe then existe = true break end
        end
        if not existe then hl.exec_cmd(s.cmd) end
        hl.dispatch(hl.dsp.workspace.toggle_special(nome))
    end
end

-- Acessível pelo hyprctl eval (o barpop usa: scratch("vol")).
_G.scratch = function(nome) alterna_scratch(nome)() end

hl.window_rule({ name = "float-dialogos", match = { title = "^(Open File|Save File|Abrir arquivo|Salvar arquivo).*" }, float = true })
hl.window_rule({ name = "float-polkit", match = { class = "^(hyprpolkitagent|polkit-gnome-authentication-agent-1)$" }, float = true, center = true })
hl.window_rule({ name = "vinil-tela-cheia", match = { class = "^[Vv]inil$" }, fullscreen = true })
hl.window_rule({ name = "pip", match = { title = "^(Picture.in.Picture|Picture in picture)$" }, float = true, pin = true })
hl.window_rule({ name = "sem-maximizar", match = { class = ".*" }, suppress_event = "maximize" })
-- Pop-ups da barra (barpop): sem borda, sem animação de janela.
hl.layer_rule({ name = "barpop-vidro", match = { namespace = "^barpop$" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "waybar-vidro", match = { namespace = "^waybar$" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "fuzzel-vidro", match = { namespace = "^launcher$" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "notificacoes", match = { namespace = "^notifications$" }, blur = true, ignore_alpha = 0.2 })

------------------------------------------------------------------ atalhos
local function ex(cmd) return hl.dsp.exec_cmd(cmd) end
local function bind(k, d, f) hl.bind(k, d, f) end

-- Super+N / Super+Shift+N: tags da tela em foco (como o dwm).
local function tag(n, mover)
    return function()
        local m = hl.get_active_monitor()
        local b = (m and base_tela[m.name]) or 0
        if mover then hl.dispatch(hl.dsp.window.move({ workspace = b + n, follow = false }))
        else hl.dispatch(hl.dsp.focus({ workspace = b + n })) end
    end
end
for i = 1, 5 do
    bind(mod .. " + " .. i, tag(i, false))
    bind(mod .. " + SHIFT + " .. i, tag(i, true))
end
bind(mod .. " + Tab", hl.dsp.focus({ workspace = "previous" }))

-- Programas
bind(mod .. " + Return", ex(terminal))
bind(mod .. " + P", ex("fuzzel"))
bind(mod .. " + F2", ex(navegador))
bind(mod .. " + F3", ex("Telegram -l"))
bind(mod .. " + W", ex("brave --app=https://web.whatsapp.com"))
bind(mod .. " + SHIFT + P", ex("menu-energia"))
bind(mod .. " + SHIFT + R", hl.dsp.reload_config())
bind(mod .. " + SHIFT + Q", hl.dsp.window.close())
bind(mod .. " + SHIFT + I", ex("keybinds"))
bind(mod .. " + SHIFT + V", ex("mullvpn"))
bind(mod .. " + SHIFT + E", ex("wg"))
bind(mod .. " + SHIFT + D", ex("dcentral"))
bind(mod .. " + SHIFT + Y", ex("clip-historico"))

-- Scratchpads
bind(mod .. " + SHIFT + Return", alterna_scratch("term"))
bind(mod .. " + F1", alterna_scratch("files"))
bind(mod .. " + F4", alterna_scratch("music"))
bind(mod .. " + F6", alterna_scratch("vol"))
bind(mod .. " + F7", alterna_scratch("obs"))
bind(mod .. " + F8", alterna_scratch("btop"))
bind("XF86Calculator", alterna_scratch("calc"))

-- Foco e pilha (dwm: focusstack / movestack)
bind(mod .. " + right", hl.dsp.layout("cyclenext"))
bind(mod .. " + left",  hl.dsp.layout("cycleprev"))
bind(mod .. " + SHIFT + right", hl.dsp.window.swap({ next = true }))
bind(mod .. " + SHIFT + left",  hl.dsp.window.swap({ prev = true }))
bind(mod .. " + CTRL + right", hl.dsp.focus({ monitor = "r" }))
bind(mod .. " + CTRL + left",  hl.dsp.focus({ monitor = "l" }))
bind(mod .. " + ALT + right", hl.dsp.window.move({ monitor = "r" }))
bind(mod .. " + ALT + left",  hl.dsp.window.move({ monitor = "l" }))

-- Layouts (dwm: t tile, m monocle, f spiral, o grid, u centered master, space alterna)
local ultimo_layout, layout_atual = "dwindle", "master"
local function usa_layout(nome)
    return function()
        if nome ~= layout_atual then ultimo_layout, layout_atual = layout_atual, nome end
        hl.config({ general = { layout = nome } })
    end
end
bind(mod .. " + T", usa_layout("master"))
bind(mod .. " + F", usa_layout("dwindle"))
bind(mod .. " + O", usa_layout("dwindle"))
bind(mod .. " + U", function() usa_layout("master")(); hl.dispatch(hl.dsp.layout("orientationcenter")) end)
bind(mod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized" }))
bind(mod .. " + space", function() usa_layout(ultimo_layout)() end)
bind(mod .. " + SHIFT + space", hl.dsp.window.float({ action = "toggle" }))
bind(mod .. " + S", hl.dsp.window.pin({ action = "toggle" }))
bind(mod .. " + I", hl.dsp.layout("addmaster"))
bind(mod .. " + D", hl.dsp.layout("removemaster"))
bind(mod .. " + H", hl.dsp.layout("mfact -0.05"))
bind(mod .. " + L", hl.dsp.layout("mfact +0.05"))
bind(mod .. " + B", ex("pkill -SIGUSR1 -x dwmblocks"))

-- Espaços entre janelas (dwm vanitygaps)
local gaps_in, gaps_out = 6, 12
local function gaps(d) return function()
    gaps_in = math.max(0, gaps_in + d); gaps_out = math.max(0, gaps_out + 2 * d)
    hl.config({ general = { gaps_in = gaps_in, gaps_out = gaps_out } })
end end
bind(mod .. " + equal", gaps(1), { repeating = true })
bind(mod .. " + minus", gaps(-1), { repeating = true })
bind(mod .. " + ALT + 0", function()
    local zero = (gaps_in ~= 0); gaps_in, gaps_out = zero and 0 or 6, zero and 0 or 12
    hl.config({ general = { gaps_in = gaps_in, gaps_out = gaps_out } })
end)

-- Janela flutuante: Alt+setas move, Alt+Shift redimensiona, Alt+Ctrl leva à borda
for _, d in ipairs({ { "left", -25, 0 }, { "right", 25, 0 }, { "up", 0, -25 }, { "down", 0, 25 } }) do
    bind("ALT + " .. d[1], hl.dsp.window.move({ x = d[2], y = d[3], relative = true }), { repeating = true })
    bind("ALT + SHIFT + " .. d[1], hl.dsp.window.resize({ x = d[2], y = d[3], relative = true }), { repeating = true })
end
bind("ALT + CTRL + left",  hl.dsp.window.move({ direction = "l" }))
bind("ALT + CTRL + right", hl.dsp.window.move({ direction = "r" }))
bind("ALT + CTRL + up",    hl.dsp.window.move({ direction = "u" }))
bind("ALT + CTRL + down",  hl.dsp.window.move({ direction = "d" }))

-- Mouse: Super+arrastar move, Super+botão direito redimensiona
bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Vidro liga/desliga (no dwm era o picom, Super+G)
local vidro = true
bind(mod .. " + G", function()
    vidro = not vidro
    hl.config({ decoration = { blur = { enabled = vidro }, shadow = { enabled = vidro } }, animations = { enabled = vidro } })
end)

-- Telas: Super+Alt+1/2/3 liga/desliga (notebook, tela principal, tela direita)
bind(mod .. " + ALT + 1", ex("tela-desliga 1"))
bind(mod .. " + ALT + 2", ex("tela-desliga 2"))
bind(mod .. " + ALT + 3", ex("tela-desliga 3"))
-- Vinil player
bind(mod .. " + ALT + SHIFT + 1", ex("vinil 1"))
bind(mod .. " + ALT + SHIFT + 2", ex("vinil 2"))
bind(mod .. " + ALT + SHIFT + 3", ex("vinil 3"))
bind(mod .. " + ALT + V", ex("vinil cursor"))
bind(mod .. " + ALT + M", ex("vinil-som"))

-- Prints (flameshot vira grim + slurp): área copiada, tela toda salva, OCR
bind("Print", ex("print-area"))
bind(mod .. " + Print", ex("print-tela"))
bind("SHIFT + Print", ex("print-texto"))

-- Bloqueio (fase 5 porta a trava completa; por enquanto o hyprlock)
bind(mod .. " + F11", ex("trava || hyprlock"))   -- trava nova; se falhar, hyprlock

-- Áudio, mic, mídia e brilho (mesmos scripts do dwm)
bind("XF86AudioRaiseVolume", ex("statusvolume up"), { locked = true, repeating = true })
bind("XF86AudioLowerVolume", ex("statusvolume down"), { locked = true, repeating = true })
bind("XF86AudioMute", ex("statusvolume mute"), { locked = true })
bind("ALT + F2", ex("statusmic down"), { repeating = true })
bind("ALT + F3", ex("statusmic up"), { repeating = true })
bind("ALT + Z", ex("statusmic mute"))
bind("XF86AudioPlay", ex("playerctlstatus play-pause"), { locked = true })
bind("XF86AudioNext", ex("playerctlstatus next"), { locked = true })
bind("XF86AudioPrev", ex("playerctlstatus previous"), { locked = true })
bind("XF86MonBrightnessUp", ex("statusbrightness up"), { locked = true, repeating = true })
bind("XF86MonBrightnessDown", ex("statusbrightness down"), { locked = true, repeating = true })
bind(mod .. " + up", ex("statusbrightness up"), { repeating = true })
bind(mod .. " + down", ex("statusbrightness down"), { repeating = true })

-- Alt+Q / Alt+W digitam / e ? (no dwm era xdotool com AltGr)
bind("ALT + Q", hl.dsp.send_shortcut({ mods = "MOD5", key = "q" }))
bind("ALT + W", hl.dsp.send_shortcut({ mods = "MOD5", key = "w" }))

------------------------------------------------------------------ autostart
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("sleep 1; fundo-wayland")
    hl.exec_cmd("fundo-vigia")   -- reaplica o wallpaper quando uma tela sai/volta
    hl.exec_cmd("dwmblocks")   -- é a Waybar com outro nome: os scripts mandam sinal para "dwmblocks"
    hl.exec_cmd("dunst")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("udiskie")
    hl.exec_cmd("cava-fundo")
    hl.exec_cmd("spotify-launcher")
    hl.exec_cmd("updnotify")
end)
