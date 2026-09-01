# pokedex-angular — tareas del proyecto
#
# Uso:   just              -> lista las tareas
#        just setup        -> deja el proyecto listo desde cero
#        just dev          -> arranca el servidor de desarrollo
#        just check        -> el gate obligatorio antes de dar nada por cerrado
#        just smoke        -> ejercita el build servido de verdad (just preview antes)
#
# Requiere: Node y Chrome (los tests corren en un navegador real, via Karma).
# Angular CLI 14 solo soporta Node 14/16/18: 'just doctor' te lo dice.

set shell := ["bash", "-uc"]

# Puertos. Override:  just PORT=8080 preview   |   PORT=8080 just preview
DEV_PORT   := env_var_or_default("DEV_PORT", "4200")
PORT       := env_var_or_default("PORT", "8080")
KARMA_PORT := env_var_or_default("KARMA_PORT", "9876")

# Carpeta de salida del build (angular.json -> outputPath)
DIST := "dist/pokedex-angular"

# Lista las tareas disponibles
default:
    @just --list


# ─────────────────────────── setup ───────────────────────────

# Deja el proyecto listo desde cero
[group('setup')]
setup: install
    @echo ""
    @echo "Listo. Arranca con:"
    @echo "   just dev     -> http://localhost:{{DEV_PORT}}"

# Instala dependencias respetando el lockfile
[group('setup')]
install:
    npm ci


# ──────────────────────── desarrollo ─────────────────────────

# Ojo: 'ng serve' escucha en localhost, que en Node 17+ es ::1. Por 127.0.0.1
# NO responde: abre siempre http://localhost:PUERTO.

# Servidor de desarrollo con recarga en caliente (por defecto en el 4200)
[group('dev')]
dev:
    npx ng serve --port {{DEV_PORT}}

# Build de produccion (el que se publica). Falla si hay errores de tipos o plantillas
[group('dev')]
build:
    npm run build

# Build de desarrollo en watch, sin optimizar
[group('dev')]
watch:
    npm run watch

# Sirve el build ya generado (requiere 'just build' antes)
[group('dev')]
preview:
    #!/usr/bin/env node
    // Angular no trae "serve del build": sin esto se verificaba con `ng serve`,
    // que es otro bundle (sin optimizar, sin hashing) y no lo que se despliega.
    // Servidor estatico minimo con fallback a index.html, que es lo que hace
    // falta para que las rutas profundas de la SPA carguen.
    const http = require('http'), fs = require('fs'), path = require('path');
    const ROOT = path.resolve('{{DIST}}');
    if (!fs.existsSync(path.join(ROOT, 'index.html'))) {
      console.error(`No hay build en {{DIST}}. Corre 'just build' primero.`);
      process.exit(1);
    }
    const TIPOS = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css',
      '.json': 'application/json', '.ico': 'image/x-icon', '.jpg': 'image/jpeg',
      '.png': 'image/png', '.svg': 'image/svg+xml', '.webp': 'image/webp',
      '.woff': 'font/woff', '.woff2': 'font/woff2', '.txt': 'text/plain' };
    http.createServer((req, res) => {
      const url = decodeURIComponent(req.url.split('?')[0]);
      // path.join normaliza los '..': sin este resolve+startsWith, un
      // '/..%2F..%2Fpackage.json' salia de dist y servia el repo entero.
      let file = path.resolve(ROOT, '.' + url);
      if (!file.startsWith(ROOT)) { res.writeHead(403).end('403'); return; }
      if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) {
        const indice = path.join(file, 'index.html');
        file = fs.existsSync(indice) ? indice : path.join(ROOT, 'index.html');
      }
      res.writeHead(200, { 'content-type': TIPOS[path.extname(file)] ?? 'application/octet-stream' });
      fs.createReadStream(file).pipe(res);
    }).listen({{PORT}}, '127.0.0.1', () => console.log(`{{DIST}} en http://127.0.0.1:{{PORT}}`));


# ───────────────────────── verificacion ──────────────────────

# Gate obligatorio de cierre: formato + lint + tipos + tests + build
[group('verify')]
check: format-check lint typecheck test-ci build
    @echo ""
    @echo "  OK  formato, lint, tipos, tests y build en verde"
    @echo "  i   falta lo que ningun comando puede hacer por ti:"
    @echo "      ejercitar la ruta que tocaste. Usa 'just preview' y 'just smoke'."

# ESLint sobre src (TypeScript + plantillas)
[group('verify')]
lint:
    npm run lint

# ESLint arreglando lo que se pueda automaticamente
[group('verify')]
lint-fix:
    npx ng lint --fix

# Reescribe el codigo con Prettier (mismo alcance que el hook de pre-commit)
[group('verify')]
format:
    npx prettier --write --ignore-unknown --cache --cache-strategy metadata src

# Comprueba el formato sin escribir
[group('verify')]
format-check:
    npx prettier --check --ignore-unknown src

# Typecheck sin emitir, app y tests. Las PLANTILLAS solo las valida 'just build'
[group('verify')]
typecheck:
    npx tsc -p tsconfig.app.json --noEmit
    npx tsc -p tsconfig.spec.json --noEmit

# Tests en watch sobre Chrome visible, para desarrollar
[group('verify')]
test:
    npm test

# Tests una sola vez en Chrome headless, con cobertura (lo que corre el CI)
[group('verify')]
test-ci:
    npm run test:cov

# Ejercita el build servido por 'just preview' (arrancalo antes en otra terminal)
[group('verify')]
smoke:
    #!/usr/bin/env node
    // La app se renderiza en el cliente: aqui no se puede afirmar nada del
    // contenido. Lo que si se comprueba, y el build no: que el shell salga con
    // sus bundles, que una ruta profunda caiga en index.html (si no, la SPA
    // rompe al recargar) y que este el 404.html que gh-pages necesita.
    const BASE = 'http://127.0.0.1:{{PORT}}';
    let fallos = 0;
    const casos = [
      { nombre: 'shell     ', path: '/',                 esperado: 200, requiere: (b) => b.includes('<app-root') },
      { nombre: 'bundles   ', path: '/',                 esperado: 200, requiere: (b) => /<script src="(main|runtime)[^"]*\.js"/.test(b) },
      { nombre: 'ruta honda', path: '/pokemon/1',        esperado: 200, requiere: (b) => b.includes('<app-root') },
      { nombre: '404 pages ', path: '/404.html',         esperado: 200, requiere: (b) => b.length > 0 },
      { nombre: 'favicon   ', path: '/favicon.ico',      esperado: 200, requiere: () => true },
    ];
    (async () => {
      for (const c of casos) {
        try {
          const res = await fetch(BASE + c.path, { signal: AbortSignal.timeout(15000) });
          const body = await res.text();
          const status_ok = res.status === c.esperado;
          let cuerpo_ok = false;
          try { cuerpo_ok = c.requiere(body); } catch { cuerpo_ok = false; }
          const ok = status_ok && cuerpo_ok;
          if (!ok) fallos++;
          const motivo = status_ok ? (cuerpo_ok ? '' : '  <- cuerpo inesperado') : `  <- esperaba ${c.esperado}`;
          console.log(`${ok ? 'OK   ' : 'FALLA'} ${c.nombre} ${c.path.padEnd(16)} ${res.status}  ${body.length}B${motivo}`);
        } catch (e) {
          fallos++;
          console.log(`FALLA ${c.nombre} ${c.path.padEnd(16)} ${e.name}: ${e.message}`);
        }
      }
      console.log(fallos ? `\n${fallos} fallo(s). Hay un 'just preview' vivo en ${BASE}?` : '\nTodo verde.');
      process.exit(fallos ? 1 : 0);
    })();

# Revisa que el entorno tenga todo lo necesario
[group('verify')]
doctor:
    #!/usr/bin/env bash
    set -uo pipefail
    node_v=$(node -v 2>/dev/null) || node_v=""
    # Comparacion NUMERICA del major: en textual "9" > "18" y un Node 9 pasaria.
    node_major=$(echo "${node_v#v}" | cut -d. -f1)
    if [ -z "$node_v" ]; then
      echo "node     FALTA"
    elif [ "${node_major:-0}" -gt 18 ]; then
      echo "node     $node_v  fuera del rango soportado por Angular CLI 14 (14/16/18)"
      echo "         (suele construir igual; si algo falla raro, empieza por aqui)"
    elif [ "${node_major:-0}" -lt 14 ]; then
      echo "node     $node_v  DEMASIADO ANTIGUO - Angular CLI 14 exige 14+"
    else
      echo "node     $node_v"
    fi
    echo "npm      $(npm -v 2>/dev/null || echo 'FALTA')"
    echo "just     $(just --version 2>/dev/null | cut -d' ' -f2 || echo 'FALTA')"
    [ -d node_modules ] && echo "deps     node_modules OK" || echo "deps     FALTA - corre 'just install'"
    [ -f "{{DIST}}/index.html" ] && echo "build    {{DIST}} presente" || echo "build    sin build (opcional, corre 'just build')"
    # Karma lanza un Chrome de verdad: sin navegador, 'just test' no arranca.
    chrome=""
    if [ -n "${CHROME_BIN:-}" ] && [ -f "$CHROME_BIN" ]; then
      chrome="$CHROME_BIN (CHROME_BIN)"
    else
      # Un solo `ls` con varios candidatos falla si CUALQUIERA no existe y daba
      # "no encontrado" con Chrome instalado. Hay que probarlos de uno en uno.
      for c in "/c/Program Files/Google/Chrome/Application/chrome.exe" \
               "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe" \
               "$HOME/AppData/Local/Google/Chrome/Application/chrome.exe"; do
        [ -f "$c" ] && { chrome="$c"; break; }
      done
    fi
    if [ -n "$chrome" ]; then
      echo "chrome   $chrome"
    else
      echo "chrome   NO encontrado - los tests de Karma no podran arrancar (exporta CHROME_BIN)"
    fi
    # La PokeAPI es la unica dependencia externa de la app: si no responde, la
    # UI se queda vacia y el desarrollo se vuelve confuso. Mejor saberlo aqui.
    graphql=$(grep -o "pokeApiGraphQL: '[^']*'" src/environments/environment.ts | head -1 | cut -d"'" -f2)
    if curl -fsS -m 8 -X POST -H 'content-type: application/json' \
         -d '{"query":"{ pokemon_v2_pokemon(limit:1){ id } }"}' "$graphql" >/dev/null 2>&1; then
      echo "graphql  alcanzable  ($graphql)"
    else
      echo "graphql  NO alcanzable - la app no listara nada  ($graphql)"
    fi

# Revisa si los puertos estan libres y quien los ocupa
[group('verify')]
check-ports:
    #!/usr/bin/env node
    const net = require('net');
    const { execSync } = require('child_process');
    const quien = (port) => {
      try {
        if (process.platform !== 'win32') return '';
        const out = execSync(`netstat -ano | findstr ":${port} " | findstr LISTENING`, { encoding: 'utf8' });
        const pid = out.trim().split(/\r?\n/)[0].trim().split(/\s+/).pop();
        const tl = execSync(`tasklist /FI "PID eq ${pid}" /NH /FO CSV`, { encoding: 'utf8' });
        return `  <- PID ${pid} (${tl.split(',')[0].replace(/"/g, '')})`;
      } catch { return ''; }
    };
    // Se prueba CONECTANDO, no bindeando: en Windows SO_REUSEADDR deja
    // re-bindear un puerto que ya tiene un servidor Node y da falsos "libre".
    const tocar = (host, port) => new Promise((r) => {
      const s = net.connect({ host, port });
      const cerrar = (v) => { s.destroy(); r(v); };
      s.setTimeout(2000);
      s.once('connect', () => cerrar(true));
      s.once('timeout', () => cerrar(true));
      s.once('error', () => cerrar(false));
    });
    (async () => {
      for (const port of [{{DEV_PORT}}, {{PORT}}, {{KARMA_PORT}}]) {
        // Hay que mirar las DOS pilas: `ng serve` escucha en localhost, que en
        // Node 17+ es ::1, y sondear solo 127.0.0.1 daba "libre" con el
        // servidor de desarrollo levantado.
        const v4 = await tocar('127.0.0.1', port);
        const v6 = await tocar('::1', port);
        const donde = v4 && v6 ? '' : v4 ? '  (solo IPv4)' : v6 ? '  (solo IPv6 ::1)' : '';
        const ocupado = v4 || v6;
        console.log(`${ocupado ? 'OCUPADO ' : 'libre   '} ${port}${ocupado ? donde + quien(port) : ''}`);
      }
    })();


# ─────────────────────────── deploy ──────────────────────────

# Este build cuelga los assets de /pokedex-angular/, asi que 'just preview'
# (que sirve en la raiz) devolvera 404 en todo. Es para inspeccionar el dist.

# Build con el base-href de GitHub Pages (no publica nada)
[group('deploy')]
build-pages:
    npm run predeploy

# PUBLICA en GitHub Pages (rama gh-pages). Accion externa: confirma antes
[group('deploy')]
deploy:
    npm run deploy


# ─────────────────────────── limpieza ────────────────────────

# Borra artefactos de build y caches. No toca node_modules
[group('limpieza')]
clean:
    rm -rf dist coverage out-tsc .angular/cache .eslintcache

# Borra ademas node_modules: obliga a reinstalar
[group('limpieza')]
clean-all: clean
    rm -rf node_modules
