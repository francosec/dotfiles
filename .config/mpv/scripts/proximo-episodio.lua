-- Cartão "A seguir" no fim do episódio, para o MPV aberto pelo goanime.
-- Ao zerar, aperta "n" (Next episode) no terminal do goanime.
local mp = require "mp"
local utils = require "mp.utils"
local msg = require "mp.msg"

local SEGUNDOS = 15
local DUR_MIN = 120
local FADE = 8
local CACHE = os.getenv("HOME") .. "/.cache/mpv-proximo"
local ESTADO = CACHE .. "/estado.json"
local FONTE = "Roboto"

local function ler(c)
    local f = io.open(c, "rb"); if not f then return nil end
    local t = f:read("*a"); f:close(); return t
end

-- Dois modos: MPV aberto pelo goanime (pai do processo) ou pelo app do celular.
local servidor = mp.get_opt("anime-servidor") == "1"
local stat = ler("/proc/self/stat") or ""
local ppid = stat:match("^%d+ %(.*%) %S (%d+)")
local doGoanime = ppid and (ler("/proc/" .. ppid .. "/comm") or ""):gsub("%s", "") == "goanime"
if not servidor and not doGoanime then return end
local janela
if doGoanime then
    for v in ((ler("/proc/" .. ppid .. "/environ") or "") .. "\0"):gmatch("(.-)%z") do
        janela = v:match("^WINDOWID=(%d+)$") or janela
    end
end

mp.command_native({ name = "subprocess", args = { "mkdir", "-p", CACHE }, playback_only = false })
local ov = mp.create_osd_overlay("ass-events")
local info = {}          -- nome, ep, titulo, total, img
local thumb              -- {arq, w, h}
local gerando
local visivel, cancelado, disparado, hover = false, false, false, nil
local abriu = 0
local quadro_img
local timer
local botoes = {}

local function rodar(args, cb)
    mp.command_native_async({ name = "subprocess", args = args, capture_stdout = true,
        capture_stderr = true, playback_only = false }, function(_, r)
        cb(r and r.status == 0, r and r.stdout or "")
    end)
end

local function chave(s) return (s:gsub("[^%w]+", "_")) end

local function buscar()
    local t = mp.get_property("media-title") or ""
    local nome, ep = t:match("^(.-) S%d+E(%d+)$")
    if not nome then return end
    info = { nome = nome, ep = tonumber(ep) + 1 }
    local alvo = info
    local corpo = utils.format_json({
        query = "query($s:String){Media(search:$s,type:ANIME){episodes bannerImage coverImage{extraLarge} streamingEpisodes{title thumbnail}}}",
        variables = { s = nome } })
    rodar({ "curl", "-s", "-m", "15", "--retry", "3", "--retry-all-errors", "https://graphql.anilist.co", "-H",
        "Content-Type: application/json", "--data-raw", corpo }, function(ok, out)
        if alvo ~= info or not ok then return end
        local d = utils.parse_json(out)
        local m = d and d.data and d.data.Media
        if type(m) ~= "table" then return end
        alvo.total = tonumber(m.episodes)
        local url
        for _, e in ipairs(m.streamingEpisodes or {}) do
            local n, tit = (e.title or ""):match("^Episode (%d+)%s*%-?%s*(.*)$")
            if tonumber(n) == alvo.ep then alvo.titulo, url = tit, e.thumbnail; break end
        end
        url = url or m.bannerImage or (m.coverImage or {}).extraLarge
        if type(url) ~= "string" or not url:match("^https://") then return end
        local arq = CACHE .. "/" .. chave(nome) .. "_" .. alvo.ep .. ".img"
        if utils.file_info(arq) then alvo.img = arq; return end
        rodar({ "curl", "-sfL", "--proto", "=https", "-m", "20", "--retry", "3", "--retry-all-errors", "--max-filesize", "8000000",
            "-o", arq .. ".tmp", url }, function(ok2)
            if ok2 and os.rename(arq .. ".tmp", arq) then alvo.img = arq end
        end)
    end)
end

local function geo()
    local W, H = mp.get_osd_size()
    if not W or W < 200 or H < 200 then return nil end
    local s = math.min(H / 1080, W / 1400)
    local g = { W = W, H = H, s = s }
    g.p = 18 * s
    g.w, g.h = 640 * s, 581 * s
    g.x, g.y = W - g.w - 48 * s, H - g.h - 84 * s
    g.iw = math.floor(g.w - 2 * g.p); g.ih = math.floor(g.iw * 9 / 16)
    g.ix, g.iy = math.floor(g.x + g.p), math.floor(g.y + g.p)
    return g
end

-- Miniatura em BGRA pré-multiplicado, cantos redondos, FADE quadros de entrada.
local function gerar(g)
    if not info.img or gerando or (thumb and thumb.w == g.iw and thumb.h == g.ih and thumb.img == info.img) then return end
    gerando = true
    local arq = string.format("%s/thumb-%d.bgra", CACHE, utils.getpid())
    local alvo, w, h, r = info.img, g.iw, g.ih, 14 * g.s
    local masc = string.format("clip(%f+0.5-hypot(max(0,abs(X-W/2+0.5)-(W/2-%f)),max(0,abs(Y-H/2+0.5)-(H/2-%f))),0,1)", r, r, r)
    local a = string.format("(%s)*(N+1)/%d", masc, FADE)
    local vf = string.format("scale=%d:%d:force_original_aspect_ratio=increase:flags=lanczos,crop=%d:%d,loop=%d:1:0,format=gbrap,geq=r='r(X,Y)*%s':g='g(X,Y)*%s':b='b(X,Y)*%s':a='255*%s',format=bgra",
        w, h, w, h, FADE - 1, a, a, a, a)
    rodar({ "ffmpeg", "-v", "error", "-y", "-i", alvo, "-vf", vf, "-frames:v", tostring(FADE),
        "-f", "rawvideo", "-pix_fmt", "bgra", arq }, function(ok)
        gerando = false
        local fi = utils.file_info(arq)
        if ok and fi and fi.size == w * h * 4 * FADE then
            thumb = { arq = arq, w = w, h = h, img = alvo }; quadro_img = nil
        else msg.warn("miniatura falhou"); os.remove(alvo); if info.img == alvo then info.img = nil end end
    end)
end

-- Cartão em HTML/CSS: proximo-cartao.py renderiza antes; aqui só mostra os bitmaps.
local cartao, fazendo, falhas = nil, nil, 0
local function chaveCartao(g) return table.concat({ info.ep or "", info.titulo or "", info.img or "", g.W, g.H }, "|") end
local function tira_cartao()
    for _, id in ipairs({ 41, 42, 43 }) do mp.commandv("overlay-remove", tostring(id)) end
    if cartao then cartao.mostrado = {} end
end
local function gerarCartao(g)
    local k = chaveCartao(g)
    if not info.ep or fazendo or falhas > 2 or (cartao and cartao.k == k) then return end
    fazendo = true
    local saida = string.format("%s/cartao-%d-%d", CACHE, utils.getpid(), math.floor(mp.get_time() * 1000))
    mp.command_native_async({ name = "subprocess", playback_only = false, capture_stdout = true,
        args = { "nice", "-n", "15", "python3", mp.command_native({ "expand-path", "~~/proximo-cartao.py" }) },
        stdin_data = utils.format_json({ ep = info.ep, titulo = info.titulo, nome = info.nome, img = info.img, s = g.s, saida = saida }) },
        function(_, r)
            fazendo = nil
            local c = r and r.status == 0 and utils.parse_json(r.stdout or "")
            if not c then
                falhas = falhas + 1; msg.warn("cartão HTML falhou")
                os.remove(saida .. ".folha"); os.remove(saida .. ".fade"); return
            end
            local velho = cartao
            c.k, c.arq, c.mostrado = k, saida, {}
            cartao = c
            if velho then os.remove(velho.arq .. ".folha"); os.remove(velho.arq .. ".fade") end
        end)
end
local function poe(id, x, y, arq, off, w, h, stride)
    local s = table.concat({ x, y, off, w, h, arq }, ":")
    if cartao.mostrado[id] == s then return end
    mp.commandv("overlay-add", tostring(id), tostring(x), tostring(y), arq, tostring(off), "bgra", tostring(w), tostring(h), tostring(stride))
    cartao.mostrado[id] = s
end
local function tira1(id)
    if cartao.mostrado[id] then mp.commandv("overlay-remove", tostring(id)); cartao.mostrado[id] = nil end
end

local function tira_img()
    if quadro_img then mp.commandv("overlay-remove", "41"); quadro_img = nil end
end

local function caixa(x, y, w, h, r)
    local k = r * 0.5523
    local f = string.format
    return f("m %.1f %.1f l %.1f %.1f b %.1f %.1f %.1f %.1f %.1f %.1f l %.1f %.1f b %.1f %.1f %.1f %.1f %.1f %.1f l %.1f %.1f b %.1f %.1f %.1f %.1f %.1f %.1f l %.1f %.1f b %.1f %.1f %.1f %.1f %.1f %.1f",
        x+r,y, x+w-r,y, x+w-r+k,y, x+w,y+r-k, x+w,y+r, x+w,y+h-r, x+w,y+h-r+k, x+w-r+k,y+h, x+w-r,y+h,
        x+r,y+h, x+r-k,y+h, x,y+h-r+k, x,y+h-r, x,y+r, x,y+r-k, x+r-k,y, x+r,y)
end

local function desenhaHtml(g, resta)
    local c, t = cartao, math.min(1, (mp.get_time() - abriu) / 0.4)
    local suave = 1 - (1 - t) ^ 3
    local x = math.floor(g.W - c.cw - 48 * g.s)
    local y = math.floor(g.H - c.ch - 84 * g.s + (1 - suave) * 36 * g.s)
    if ov.data ~= "" then ov.data = ""; ov:remove() end
    local q = math.max(0, math.min(7, math.floor(suave * 8 - 0.001)))
    poe(41, x - c.m, y - c.m, c.arq .. ".fade", q * c.bw * c.bh * 4, c.bw, c.bh, c.bw * 4)
    local function folha(px, py) return (py * c.W + px) * 4 end
    botoes = {}
    if t < 1 then return end
    if disparado then
        tira1(42)
        poe(43, x + c.bx, y + c.by, c.arq .. ".folha", folha(0, c.yl), c.iw, c.hb, c.W * 4)
        return
    end
    local i = math.max(0, math.min(c.n - 1, math.floor((SEGUNDOS - resta) * 8)))
    poe(42, x + c.ax, y + c.ay, c.arq .. ".folha",
        folha(math.floor((i % c.cols) * c.passo * c.s + 0.5), math.floor((c.y0 + math.floor(i / c.cols) * c.passo) * c.s + 0.5)), c.anel, c.anel, c.W * 4)
    botoes = { ja = { x + c.bx, y + c.by, c.wa, c.hb }, cancela = { x + c.xb, y + c.by, c.wb, c.hb } }
    if hover == "ja" then poe(43, x + c.bx, y + c.by, c.arq .. ".folha", folha(0, c.yb), c.wa, c.hb, c.W * 4)
    elseif hover == "cancela" then poe(43, x + c.xb, y + c.by, c.arq .. ".folha", folha(c.sxb, c.yb), c.wb, c.hb, c.W * 4)
    else tira1(43) end
end

local function desenha(g, resta)
    if cartao and cartao.k == chaveCartao(g) then quadro_img = nil; return desenhaHtml(g, resta) end
    local t = math.min(1, (mp.get_time() - abriu) / 0.3)
    local function al(o) return string.format("%02X", math.floor(255 - 255 * o * t + 0.5)) end
    local ev = {}
    local function forma(path, cor, o, bord, bcor, bo)
        ev[#ev+1] = string.format("{\\an7\\pos(0,0)\\shad0\\bord%.1f\\1c&H%s&\\1a&H%s&\\3c&H%s&\\3a&H%s&\\p1}%s{\\p0}",
            bord or 0, cor, al(o), bcor or "000000", al(bo or 0), path)
    end
    local function texto(x, y, an, tam, cor, o, neg, s, extra)
        s = s:gsub("\\", "/"):gsub("[{}]", ""):gsub("\n", " ")
        ev[#ev+1] = string.format("{\\an%d\\pos(%.1f,%.1f)\\bord0\\shad0\\q2\\fn%s\\fs%.1f\\b%d\\1c&H%s&\\1a&H%s&%s}%s",
            an, x, y, FONTE, tam, neg, cor, al(o), extra or "", s)
    end
    local s = g.s
    -- sombra difusa + corpo
    ev[#ev+1] = string.format("{\\an7\\pos(0,%.1f)\\bord0\\shad0\\blur%.1f\\1c&H000000&\\1a&H%s&\\p1}%s{\\p0}",
        8*s, 22*s, al(.6), caixa(g.x, g.y, g.w, g.h, 22*s))
    forma(caixa(g.x, g.y, g.w, g.h, 22*s), "141110", .94, 1.2*s, "FFFFFF", .13)
    forma(caixa(g.ix, g.iy, g.iw, g.ih, 14*s), "2A2624", 1)
    local y = g.iy + g.ih + 18*s
    texto(g.ix, y, 7, 27*s, "C8C2BE", 1, 500, "A SEGUIR  ·  EPISÓDIO " .. (info.ep or ""), string.format("\\fsp%.1f", 1.4*s))
    texto(g.ix + g.iw, y, 9, 29*s, "FFFFFF", 1, 700,
        disparado and "Carregando…" or string.format("%d s", math.max(0, math.ceil(resta))))
    y = y + 37*s
    local tit = (info.titulo and info.titulo ~= "") and info.titulo or ("Episódio " .. (info.ep or ""))
    local _, n = tit:gsub("[^\128-\191]", "")
    local tam = math.max(27*s, math.min(45*s, g.iw / (n * 0.5)))
    texto(g.ix, y + 28*s, 4, tam, "FFFFFF", 1, 700, tit,
        string.format("\\clip(%d,%d,%d,%d)", g.ix, math.floor(y), g.ix + g.iw, math.floor(y + 58*s)))
    y = y + 64*s
    forma(caixa(g.ix, y, g.iw, 4*s, 2*s), "FFFFFF", .16)
    local f = disparado and 1 or math.max(0, math.min(1, 1 - resta / SEGUNDOS))
    if f * g.iw > 4*s then forma(caixa(g.ix, y, g.iw * f, 4*s, 2*s), "FFFFFF", 1) end
    y = y + 18*s
    botoes = {}
    if not disparado then
        local bh, gap = 62*s, 10*s
        local w1 = (g.iw - gap) * .6
        local w2 = g.iw - gap - w1
        botoes = { ja = { g.ix, y, w1, bh }, cancela = { g.ix + w1 + gap, y, w2, bh } }
        forma(caixa(g.ix, y, w1, bh, 12*s), "FFFFFF", hover == "ja" and .82 or 1)
        texto(g.ix + w1/2, y + bh/2, 5, 30*s, "141110", 1, 700, "Reproduzir agora")
        forma(caixa(g.ix + w1 + gap, y, w2, bh, 12*s), "FFFFFF", hover == "cancela" and .24 or .12)
        texto(g.ix + w1 + gap + w2/2, y + bh/2, 5, 30*s, "FFFFFF", 1, 500, "Cancelar")
    end
    ov.res_x, ov.res_y, ov.z = g.W, g.H, 50
    ov.data = table.concat(ev, "\n")
    ov:update()
    if thumb and thumb.w == g.iw and thumb.h == g.ih and thumb.img == info.img then
        local q = math.max(0, math.min(FADE - 1, math.floor(t * FADE) - 1))
        local id = q .. ":" .. g.ix .. ":" .. g.iy
        if quadro_img ~= id then
            mp.commandv("overlay-add", "41", tostring(g.ix), tostring(g.iy), thumb.arq,
                tostring(q * thumb.w * thumb.h * 4), "bgra", tostring(thumb.w), tostring(thumb.h), tostring(thumb.w * 4))
            quadro_img = id
        end
    else tira_img() end
end

local function solta_teclas()
    for _, n in ipairs({ "px-enter", "px-esc", "px-clique" }) do mp.remove_key_binding(n) end
    hover = nil
end

local function esconde()
    if timer then timer:kill() end
    ov:remove(); ov.data = ""; tira_img(); tira_cartao(); solta_teclas()
    visivel, botoes = false, {}
end

local function cancela()
    cancelado = true
    mp.set_property("keep-open", "no")
    esconde()
    if mp.get_property_bool("eof-reached") then mp.command("quit") end
end

local function dispara()
    if disparado then return end
    disparado = true
    solta_teclas()
    mp.set_property("keep-open", "yes")
    mp.set_property_bool("pause", true)
    if servidor then mp.commandv("script-message", "anime-proximo"); return end
    local f = io.open(ESTADO, "w")
    if f then
        f:write(utils.format_json({ t = os.time(), fs = mp.get_property_bool("fullscreen"),
            vol = mp.get_property_number("volume"), mudo = mp.get_property_bool("mute") }))
        f:close()
    end
    local function falhou(m) msg.warn(m); mp.osd_message("Não foi possível abrir o próximo episódio", 3)
        mp.add_timeout(3, function() mp.command("quit") end) end
    if not janela then return falhou("sem WINDOWID") end
    local function tecla(...)
        local a = { "xdotool", "key", "--delay", "60", "--window", janela }
        for _, k in ipairs({ ... }) do a[#a+1] = k end
        rodar(a, function(ok) if not ok then msg.warn("xdotool falhou") end end)
    end
    -- Segue o título do terminal: menu do player -> "n". Se o goanime recusar
    -- (vídeo veio de fonte reserva), cai em "Menu": escolhe o episódio na lista.
    local etapa, desde, meu = "inicio", mp.get_time(), tostring(utils.getpid())
    mp.command_native({ name = "subprocess", detach = true, playback_only = false, args = { "python3",
        mp.command_native({ "expand-path", "~~/proximo-episodio-retomar.py" }), ppid, janela, tostring(info.ep), meu } })
    local vigia
    vigia = mp.add_periodic_timer(0.7, function()
        rodar({ "pgrep", "-x", "-P", ppid, "mpv" }, function(_, out)
            for pid in out:gmatch("%d+") do
                if pid ~= meu then vigia:kill(); mp.command("quit"); return end
            end
        end)
        rodar({ "xdotool", "getwindowname", janela }, function(ok, nome)
            if not vigia:is_enabled() then return end
            nome = ok and nome or ""
            if etapa == "inicio" then
                if nome:match("^GoAnime %- Player") then etapa = "pedido"; tecla("n")
                elseif mp.get_time() - desde > 4 then vigia:kill(); falhou("terminal fora do menu: " .. nome) end
            elseif etapa == "pedido" and nome:match("^GoAnime %- Menu") then
                etapa = "lista"; tecla("e")
            elseif etapa == "lista" and nome:match("^GoAnime %- Episodes") then
                etapa = "escolhido"
                -- filtro por número é difuso ("2" acha o 24): anda pela lista
                local ks = { "Home" }
                for _ = 2, info.ep do ks[#ks+1] = "Down" end
                ks[#ks+1] = "Return"
                tecla(unpack(ks))
            elseif mp.get_time() - desde > 90 then vigia:kill(); falhou("goanime não trocou em 90 s") end
        end)
    end)
end

local function clique()
    if hover == "ja" then dispara() elseif hover == "cancela" then cancela() end
end

local function passo()
    local g = geo(); if not g then return end
    gerarCartao(g)
    gerar(g)
    local d, p = mp.get_property_number("duration"), mp.get_property_number("time-pos")
    local fim = mp.get_property_bool("eof-reached")
    local resta = 0
    if d and p and not fim then resta = (d - p) / (mp.get_property_number("speed") or 1) end
    if not disparado and resta > SEGUNDOS + 1 then return esconde() end
    if not disparado and (fim or resta <= 0.25) then dispara() end
    local m = mp.get_property_native("mouse-pos") or {}
    local h
    for n, b in pairs(botoes) do
        if m.hover and m.x >= b[1] and m.x <= b[1]+b[3] and m.y >= b[2] and m.y <= b[2]+b[4] then h = n end
    end
    if h ~= hover and not disparado then
        hover = h
        if h then mp.add_forced_key_binding("MBTN_LEFT", "px-clique", clique)
        else mp.remove_key_binding("px-clique") end
    end
    desenha(g, resta)
end

local function mostra()
    visivel, abriu = true, mp.get_time()
    mp.set_property("keep-open", "yes")   -- segura o último quadro até o goanime trocar
    mp.add_forced_key_binding("ENTER", "px-enter", dispara)
    mp.add_forced_key_binding("ESC", "px-esc", cancela)
    if timer then timer:kill() end
    timer = mp.add_periodic_timer(1 / 20, passo)
    passo()
end

mp.observe_property("time-pos", "number", function(_, p)
    local d = mp.get_property_number("duration")
    if not p or not d or d < DUR_MIN or disparado or not info.ep then return end
    local resta = (d - p) / (mp.get_property_number("speed") or 1)
    if resta > SEGUNDOS then cancelado = false
        if resta < 120 then local g = geo(); if g then gerarCartao(g); gerar(g) end end
        return
    end
    if visivel or cancelado or (info.total and info.ep > info.total) then return end
    mostra()
end)

mp.register_event("start-file", function()
    if not servidor then return end
    esconde(); info, cancelado, disparado = {}, false, false
end)

mp.register_script_message("proximo", function(j)
    if servidor then info = utils.parse_json(j) or {} end
end)

mp.register_event("file-loaded", function()
    if servidor then return end
    buscar()
    local e = utils.parse_json(ler(ESTADO) or "")
    os.remove(ESTADO)
    if type(e) == "table" and os.time() - (e.t or 0) < 120 then
        if e.fs then mp.set_property_bool("fullscreen", true) end
        if e.vol then mp.set_property_number("volume", e.vol) end
        if e.mudo ~= nil then mp.set_property_bool("mute", e.mudo) end
    end
end)

mp.register_event("shutdown", function()
    if thumb then os.remove(thumb.arq) end
    if cartao then os.remove(cartao.arq .. ".folha"); os.remove(cartao.arq .. ".fade") end
end)
