// Céu da tela de bloqueio: posição real do sol e da lua para a localização do wttr.in,
// fase da lua, período do dia e estrelas. Astronomia adaptada do SunCalc (V. Agafonkin, BSD-2).
(() => {
  const { PI, sin, cos, tan, asin, acos, atan2, sqrt, abs, round } = Math;
  const rad = PI / 180, diaMs = 864e5, J1970 = 2440588, J2000 = 2451545, e = rad * 23.4397;
  const julianos = d => d / diaMs - 0.5 + J1970, deJuliano = j => new Date((j + 0.5 - J1970) * diaMs);
  const dias = d => julianos(d) - J2000;
  const ascensao = (l, b) => atan2(sin(l) * cos(e) - tan(b) * sin(e), cos(l));
  const declinacao = (l, b) => asin(sin(b) * cos(e) + cos(b) * sin(e) * sin(l));
  const azimute = (H, phi, dec) => atan2(sin(H), cos(H) * sin(phi) - tan(dec) * cos(phi));
  const altura = (H, phi, dec) => asin(sin(phi) * sin(dec) + cos(phi) * cos(dec) * cos(H));
  const sideral = (d, lw) => rad * (280.16 + 360.9856235 * d) - lw;
  const anomalia = d => rad * (357.5291 + 0.98560028 * d);
  const longEcl = M => M + rad * (1.9148 * sin(M) + 0.02 * sin(2 * M) + 0.0003 * sin(3 * M)) + rad * 102.9372 + PI;
  const coordSol = d => { const L = longEcl(anomalia(d)); return { dec: declinacao(L, 0), ra: ascensao(L, 0) }; };
  const coordLua = d => {
    const L = rad * (218.316 + 13.176396 * d), M = rad * (134.963 + 13.064993 * d), F = rad * (93.272 + 13.229350 * d);
    const l = L + rad * 6.289 * sin(M), b = rad * 5.128 * sin(F);
    return { ra: ascensao(l, b), dec: declinacao(l, b), dist: 385001 - 20905 * cos(M) };
  };
  const refracao = h => { h = Math.max(h, 0); return 0.0002967 / tan(h + 0.00312536 / (h + 0.08901179)); };

  function posSol(data, lat, lon) {
    const lw = rad * -lon, phi = rad * lat, d = dias(data), c = coordSol(d), H = sideral(d, lw) - c.ra;
    return { az: azimute(H, phi, c.dec), alt: altura(H, phi, c.dec) };
  }
  function posLua(data, lat, lon) {
    const lw = rad * -lon, phi = rad * lat, d = dias(data), c = coordLua(d), H = sideral(d, lw) - c.ra;
    const h = altura(H, phi, c.dec);
    // Ângulo paralático: inclinação do lado iluminado vista do lugar.
    const pa = atan2(sin(H), tan(phi) * cos(c.dec) - sin(c.dec) * cos(H));
    return { az: azimute(H, phi, c.dec), alt: h + refracao(h), pa };
  }
  function horariosSol(data, lat, lon) {
    const J0 = 0.0009, lw = rad * -lon, phi = rad * lat, d = dias(data);
    const n = round(d - J0 - lw / (2 * PI)), ds = J0 + lw / (2 * PI) + n;
    const M = anomalia(ds), L = longEcl(M), dec = declinacao(L, 0);
    const transito = (x) => J2000 + x + 0.0053 * sin(M) - 0.0069 * sin(2 * L);
    const Jmeio = transito(ds);
    const w = acos((sin(-0.833 * rad) - sin(phi) * sin(dec)) / (cos(phi) * cos(dec)));
    const Jpor = transito(J0 + (w + lw) / (2 * PI) + n);
    return { nascer: deJuliano(Jmeio - (Jpor - Jmeio)), por: deJuliano(Jpor), meio: deJuliano(Jmeio) };
  }
  function iluminacaoLua(data) {
    const d = dias(data), s = coordSol(d), m = coordLua(d), sdist = 149598000;
    const phi = acos(sin(s.dec) * sin(m.dec) + cos(s.dec) * cos(m.dec) * cos(s.ra - m.ra));
    const inc = atan2(sdist * sin(phi), m.dist - sdist * cos(phi));
    const ang = atan2(cos(s.dec) * sin(s.ra - m.ra), sin(s.dec) * cos(m.dec) - cos(s.dec) * sin(m.dec) * cos(s.ra - m.ra));
    return { fracao: (1 + cos(inc)) / 2, fase: 0.5 + 0.5 * inc * (ang < 0 ? -1 : 1) / PI, angulo: ang };
  }
  function horariosLua(data, lat, lon) {
    const t = new Date(data); t.setHours(0, 0, 0, 0);
    const hc = 0.133 * rad, em = h => new Date(t.getTime() + h * 36e5), alt = h => posLua(em(h), lat, lon).alt - hc;
    let h0 = alt(0), nasce, poe;
    for (let i = 1; i <= 24; i += 2) {
      const h1 = alt(i), h2 = alt(i + 1), a = (h0 + h2) / 2 - h1, b = (h2 - h0) / 2, xe = -b / (2 * a), ye = (a * xe + b) * xe + h1;
      const d = b * b - 4 * a * h1; let raizes = 0, x1 = 0, x2 = 0;
      if (d >= 0) { const dx = sqrt(d) / (abs(a) * 2); x1 = xe - dx; x2 = xe + dx; if (abs(x1) <= 1) raizes++; if (abs(x2) <= 1) raizes++; if (x1 < -1) x1 = x2; }
      if (raizes === 1) { if (h0 < 0) nasce = i + x1; else poe = i + x1; }
      else if (raizes === 2) { nasce = i + (ye < 0 ? x2 : x1); poe = i + (ye < 0 ? x1 : x2); }
      if (nasce !== undefined && poe !== undefined) break;
      h0 = h2;
    }
    return { nasce: nasce !== undefined ? em(nasce) : null, poe: poe !== undefined ? em(poe) : null };
  }
  const nomeFase = (f, k = 1) =>
    k < .02 || f < .03 || f > .97 ? 'Lua nova' : f < .22 ? 'Lua crescente' : f < .28 ? 'Quarto crescente' : f < .47 ? 'Crescente gibosa'
      : f < .53 ? 'Lua cheia' : f < .72 ? 'Minguante gibosa' : f < .78 ? 'Quarto minguante' : 'Lua minguante';
  const hm = d => d ? d.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' }) : '—';

  // Projeção do céu: leste na esquerda, oeste na direita, zênite no alto do arco.
  // Geometria do céu em % da tela; a página pode trocar com window.CEU_GEO = { horizonte, topo, abaixo }.
  // Tela da tela 2: faixa no alto (horizonte 19%, topo 4%), para o caminho do sol nunca cruzar foto nem textos.
  const GEO = window.CEU_GEO || {}, HORIZONTE = GEO.horizonte ?? 88, TOPO = GEO.topo ?? 9, ABAIXO = GEO.abaixo ?? 3.2;
  const projetar = p => ({ x: 50 + 44 * sin(p.az) * cos(p.alt), y: HORIZONTE - (HORIZONTE - TOPO) * sin(Math.max(p.alt, 0)) });

  // Desenho da lua com a fração iluminada; gira pelo ângulo do lado iluminado visto daqui.
  function svgLua(il, inclinacao, r = 50) {
    const k = il.fracao, crescente = il.fase < 0.5, rx = r * abs(1 - 2 * k);
    // Lado claro à direita quando crescente; a rotação ajusta para o hemisfério e a hora.
    const varre = crescente ? 1 : 0, meio = k > 0.5 ? (crescente ? 1 : 0) : (crescente ? 0 : 1);
    const claro = `M ${r} 0 A ${r} ${r} 0 0 ${varre} ${r} ${2 * r} A ${rx} ${r} 0 0 ${meio} ${r} 0 Z`;
    // inclinacao: ângulo do limbo claro a partir do zênite, anti-horário (SunCalc). O desenho
    // tem o limbo claro à direita (crescente) ou à esquerda (minguante); o CSS gira no sentido horário.
    const giro = -inclinacao + (crescente ? -PI / 2 : PI / 2);
    return `<svg viewBox="0 0 ${2 * r} ${2 * r}" class="lua-svg" style="transform: rotate(${giro}rad)">
      <defs><radialGradient id="crateras" cx="40%" cy="35%" r="70%"><stop offset="0" stop-color="#fff" stop-opacity=".95"/><stop offset="1" stop-color="#cfcfcf" stop-opacity=".85"/></radialGradient></defs>
      <circle cx="${r}" cy="${r}" r="${r * 0.985}" class="lua-escura${k < 0.06 ? ' nova' : ''}"/>
      <path d="${claro}" fill="url(#crateras)"/>

    </svg>`;
  }

  function trajetoria(pos, inicio, fim, passos = 60) {
    const pts = [];
    for (let i = 0; i <= passos; i++) {
      const t = new Date(inicio.getTime() + (fim - inicio) * i / passos), p = pos(t);
      if (p.alt >= 0) { const q = projetar(p); pts.push(`${q.x.toFixed(2)},${q.y.toFixed(2)}`); }
    }
    return pts.join(' ');
  }

  function periodo(altSol, agora, meio) {
    const g = altSol / rad;
    if (g > 6) return 'dia';
    if (g > -6) return agora < meio ? 'amanhecer' : 'entardecer';
    return 'noite';
  }

  const ESTRELAS_POR_CAMADA = +(new URLSearchParams(location.search).get('estrelas') || 18);  // ?estrelas=N (estudo de desempenho)
  const texturaEstrelas = (semente) => {
    let s = semente, r = () => (s = (s * 9301 + 49297) % 233280) / 233280, p = '';
    for (let i = 0; i < ESTRELAS_POR_CAMADA; i++) p += `<circle cx='${(r() * 1000).toFixed(0)}' cy='${(r() * 560).toFixed(0)}' r='${(0.8 + r() * 1.4).toFixed(1)}' fill='white' fill-opacity='${(0.5 + r() * 0.5).toFixed(2)}'/>`;
    return `url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 1000 560' preserveAspectRatio='none'>${p}</svg>")`;
  };
  [[1, 3], [2, 11], [3, 29]].forEach(([n, sem]) => document.documentElement.style.setProperty('--estrelas-' + n, texturaEstrelas(sem)));

  window.desenharCeu = function (lat, lon, alvo, chip, saudacao) {
    const agora = new Date(), sol = posSol(agora, lat, lon), hs = horariosSol(agora, lat, lon);
    const per = periodo(sol.alt, agora, hs.meio);
    document.body.dataset.periodo = per;
    const h = agora.getHours();
    if (saudacao) saudacao.textContent = (h >= 5 && h < 12 ? 'Bom dia' : h >= 12 && h < 18 ? 'Boa tarde' : 'Boa noite') + (window.TRAVA_NOME ? ', ' + window.TRAVA_NOME : '');

    const il = iluminacaoLua(agora), lua = posLua(agora, lat, lon), hl = horariosLua(agora, lat, lon);
    // Nasce ou se põe depois da meia-noite: pega do dia seguinte.
    const amanha = new Date(agora.getTime() + diaMs), hl2 = horariosLua(amanha, lat, lon);
    if (!hl.poe || hl.poe < agora) hl.poe = hl2.poe || hl.poe;
    if (!hl.nasce || (hl.nasce < agora && lua.alt < 0)) hl.nasce = hl2.nasce || hl.nasce;
    // Lado iluminado: ângulo do limbo menos o paralático (como visto do local).
    const inclina = il.angulo - lua.pa;
    const mostrarSol = sol.alt > -0.02;
    // A lua sempre aparece: acima do horizonte no lugar real; abaixo dele (à noite), apagada logo
    // sob a linha, no rumo real, com o horário em que nasce. De dia só se estiver no céu.
    const luaNoCeu = lua.alt > 0, mostrarLua = luaNoCeu || !mostrarSol;

    let html = `<svg class="arco" viewBox="0 0 100 100" preserveAspectRatio="none">
      <line x1="2" x2="98" y1="${HORIZONTE}" y2="${HORIZONTE}" class="horizonte"/>`;
    // Caminho: parte percorrida (nascer → agora) mais forte; o que falta, pontilhado.
    const caminho = (pos, ini, fim, passos) => {
      const feito = agora > ini ? trajetoria(pos, ini, new Date(Math.min(+agora, +fim)), passos) : '';
      const falta = agora < fim ? trajetoria(pos, new Date(Math.max(+agora, +ini)), fim, passos) : '';
      return (feito ? `<polyline class="trilha-brilho" points="${feito}"/><polyline class="trilha-feita" points="${feito}"/>` : '') +
        (falta ? `<polyline class="trilha" points="${falta}"/>` : '');
    };
    if (mostrarSol) html += caminho(t => posSol(t, lat, lon), hs.nascer, hs.por, 60);
    if (mostrarLua && !mostrarSol) {
      // Caminho da lua nas próximas horas (ou o da passagem atual, se já está no céu).
      const ini = new Date(agora.getTime() - (luaNoCeu ? 14 : 0) * 36e5), fim = new Date(agora.getTime() + 20 * 36e5);
      html += caminho(t => posLua(t, lat, lon), ini, fim, 160);
    }
    html += `</svg>`;
    const marco = (pos, quando, rotulo) => {
      if (!quando) return '';
      const q = projetar({ ...pos(quando), alt: 0 });
      return `<div class="marco" style="--x:${Math.min(96, Math.max(4, q.x))}%;--y:${HORIZONTE}%"><i></i><span>${rotulo} ${hm(quando)}</span></div>`;
    };
    if (mostrarSol) html += marco(t => posSol(t, lat, lon), hs.nascer, 'nascer') + marco(t => posSol(t, lat, lon), hs.por, 'pôr');
    else if (luaNoCeu) html += marco(t => posLua(t, lat, lon), hl.poe, 'lua se põe');

    if (mostrarSol) {
      const q = projetar(sol);
      html += `<div class="astro sol" style="--x:${q.x}%;--y:${q.y}%"><i></i></div>`;
    }
    if (mostrarLua) {
      // Abaixo do horizonte: fica no ponto do horizonte por onde vai nascer, logo sob a linha.
      const q = projetar(luaNoCeu || !hl.nasce ? lua : { ...posLua(hl.nasce, lat, lon), alt: 0 });
      if (!luaNoCeu) q.y = HORIZONTE + ABAIXO;
      const classe = luaNoCeu ? (mostrarSol ? 'lua de-dia' : 'lua') : 'lua abaixo';
      const rotulo = luaNoCeu ? '' : `<span class="rotulo-astro">nasce ${hm(hl.nasce)}</span>`;
      html += `<div class="astro ${classe}" style="--x:${Math.min(94, Math.max(6, q.x))}%;--y:${q.y}%">${svgLua(il, inclina)}${rotulo}</div>`;
    }
    if (per !== 'dia') {
      // Estrelas como 3 camadas de textura que piscam alternadas (antes: uma camada por estrela).
      html += `<div class="estrelas"><i class="campo c1"></i><i class="campo c2"></i><i class="campo c3"></i></div><div class="cadente"></div>`;
    }
    alvo.innerHTML = html;

    // Chip de informação
    const durSol = (hs.por - hs.nascer) / 36e5, hDur = Math.floor(durSol), mDur = round((durSol - hDur) * 60);
    chip.innerHTML = mostrarSol
      ? `<span class="mini-sol"></span><span><b>${per === 'dia' ? 'sol' : per}</b> · nasceu ${hm(hs.nascer)} · põe ${hm(hs.por)} · ${hDur}h${String(mDur).padStart(2, '0')} de luz</span>`
      : `<span class="mini-lua">${svgLua(il, inclina, 20)}</span><span><b>${nomeFase(il.fase, il.fracao)}</b> · ${round(il.fracao * 100)}% iluminada · nasce ${hm(hl.nasce)} · põe ${hm(hl.poe)}</span>`;
  };
})();
