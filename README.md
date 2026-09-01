# Pokédex Angular

[![code style: prettier](https://img.shields.io/badge/code_style-prettier-ff69b4.svg)](https://github.com/prettier/prettier)
[![codecov](https://codecov.io/gh/keilermora/pokedex-angular/branch/master/graph/badge.svg?token=9E0D28IOFT)](https://codecov.io/gh/keilermora/pokedex-angular)
[![Commitizen friendly](https://img.shields.io/badge/commitizen-friendly-brightgreen.svg)](http://commitizen.github.io/cz-cli/)

[https://keilermora.github.io/pokedex-angular/](https://keilermora.github.io/pokedex-angular/)

La aplicación muestra el listado y el detalle de los Pokémon de las primeras 3 generaciones.

La imagen que representa un Pokémon en el listado muestra las variaciones que estos tuvieron durante las primeras versiones, desde la versión Green (1996) hasta la version Emerald (2005).

Los detalles de un Pokémon individual muestra sus estadísticas base y los registros de la Pokédex de las diferentes versiones.

El proyecto fue desarrollado usando la librería de JavaScript [Angular](https://angular.io/) para crear la interfaz de usuario, en comunicación con la Api RESTful [PokéAPI](https://pokeapi.co/).

## Requisitos mínimos

- [Nodejs](https://nodejs.org) con soporte de largo plazo (LTS). Angular CLI 14 solo soporta Node 14, 16 y 18.
- Un navegador web. Chrome, además, para los tests unitarios (corren sobre Karma).
- [just](https://just.systems) (opcional) como lanzador de tareas.

## Ambiente de pruebas

Ejecutar en la raíz del proyecto:

```
just setup   # instala las dependencias (npm ci)
just dev     # servidor de desarrollo en http://localhost:4200
just         # lista todas las tareas disponibles
```

Sin `just`, los scripts de npm siguen sirviendo igual (`npm ci`, `npm start`, ...): el
`justfile` los envuelve, no los reemplaza.

`just doctor` revisa el entorno (versión de Node, dependencias, Chrome, PokéAPI) y
`just check-ports` dice quién ocupa los puertos 4200, 8080 y 9876.

### Tareas principales

| Tarea | Qué hace |
| --- | --- |
| `just dev` | Servidor de desarrollo con recarga en caliente. |
| `just build` | Build de producción en `dist/pokedex-angular`. |
| `just test` | Tests en watch sobre Chrome. `just test-ci` los corre una vez, headless y con cobertura. |
| `just lint` / `just format` | ESLint y Prettier. `lint-fix` y `format-check` para las variantes. |
| `just check` | El gate de cierre: formato, lint, tipos, tests y build. |
| `just preview` | Sirve el `dist` ya construido en http://127.0.0.1:8080, con fallback de rutas SPA. |
| `just smoke` | Comprueba contra ese `preview` que el shell responde, que las rutas profundas caen en `index.html` y que el HTML no trae nada inline. |
| `just clean` | Borra `dist`, `coverage` y las cachés. `clean-all` se lleva también `node_modules`. |

> **Nota:** hoy `just check` falla en el paso de formato. El repo está en el disco con
> saltos de línea CRLF y `.prettierrc` exige `lf`, así que Prettier y ESLint marcan todos
> los archivos. Se resuelve normalizando los saltos de línea (`.gitattributes` con
> `* text=auto eol=lf`) o relajando la regla a `endOfLine: "auto"`.

`ng serve` escucha en `localhost`, que en Node 17+ resuelve a `::1`: hay que abrir
`http://localhost:4200`, por `127.0.0.1` no responde.

## Referencias

- [Angular](https://angular.io/): One framework.
- [Angular Folder Structure](https://angular-folder-structure.readthedocs.io/en/latest/): Create a skeleton structure which is flexible for projects big or small.
- [Font Awesome](https://fontawesome.com/): The web's most popular icon set and toolkit.
- [Normalize.css](https://necolas.github.io/normalize.css/): A modern, HTML5-ready alternative to CSS resets.
- [PokéAPI](https://pokeapi.co/): The RESTful Pokémon API.
- [Pokedex](https://keilermora.github.io/angular-pokedex/) : Pokedex funcionando.
