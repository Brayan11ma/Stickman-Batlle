# HEADSHOT ARENA

Juego multijugador en red hecho con **Python, Pygame y sockets TCP**. Servidor con SQLite
(cuentas, estadísticas y ranking) y cliente gráfico con stickmans.

## Modos de juego (salas independientes)

| Modo | Reglas |
|------|--------|
| **Only 200** | Solo cuentan los **headshots** (1 tiro = muerte; el cuerpo no recibe daño). Cada kill seguida **agranda tu cabeza** (más fácil de impactar) y te da multiplicadores de **velocidad, salto, cadencia y puntos**. Morir reinicia la racha. Gana el primero en llegar a **200 puntos**. |
| **PvP clásico** | Todas las armas: pistola, subfusil, escopeta, francotirador, cuchillo, espada, bate y hacha. Vida 100, headshot x2 (melee x1.5). Primero a 200 puntos. |
| **Cuerpo a cuerpo** | Solo cuchillo, espada, bate y hacha. Primero a 100 puntos. |

Puntos: Only 200 = 10 × multiplicador de racha (x1 → x5). PvP/Melee = 10 por kill (+5 si es headshot).

## Instalación y ejecución

```bash
pip install -r requirements.txt

# 1) Servidor (puerto 5555 por defecto)
python server/server.py            # opciones: --host --port --db --target --bots --bot-skill

# 2) Cliente (uno por jugador)
python client/client.py            # o: python client/client.py 192.168.1.20:5555
```

Para jugar en red local, abre el cliente con la IP del equipo donde corre el servidor.
En internet, abre/redirige el puerto TCP 5555 en el router.

## Bots mientras llegan los amigos

Cada sala se rellena automáticamente con bots hasta tener **4 jugadores** (`--bots N`; `--bots 0` los desactiva).
Cuando entra un humano, sale un bot, y con 4 humanos ya no queda ninguno. La habilidad se ajusta con
`--bot-skill` (0 = torpes, 1 = certeros; por defecto 0.5). Los bots no guardan estadísticas ni salen en el
ranking, y los nombres que empiezan por `Bot_` no se pueden registrar.

## Jugar con amigos por internet

Un jugador hace de **anfitrión** (corre el servidor) y los demás se conectan con la dirección del anfitrión.
Necesitas **Python 3.11–3.13** (en Windows, marca *Add Python to PATH* al instalarlo).

**Opción A – Misma red WiFi / casa:** el anfitrión ejecuta `iniciar_servidor.bat`, que muestra su IP
(por ejemplo `192.168.1.20:5555`). Los demás ejecutan `iniciar_cliente.bat` y escriben esa IP.

**Opción B – Cada uno en su casa (recomendada): Radmin VPN** (gratis, Windows).
1. Todos instalan Radmin VPN. El anfitrión crea una red (*Create network*) y comparte el nombre y la clave.
2. Los demás entran con *Join network*.
3. El anfitrión ejecuta `iniciar_servidor.bat` y copia su IP de Radmin (empieza por `26.`), o la que
   muestra el servidor. Los amigos la escriben en el cliente: `26.x.x.x:5555`.
Alternativas equivalentes: ZeroTier o Tailscale.

**Opción C – Sin que nadie instale nada: túnel TCP (playit.gg).** Solo el anfitrión instala el agente y crea un
túnel TCP al puerto 5555; los amigos usan la dirección que te dé. Puede que los túneles TCP personalizados
requieran el plan de pago.

Si no conecta: permite Python en el Firewall de Windows al iniciar el servidor, y comprueba que el puerto sea el mismo.
Cada sala admite hasta 12 jugadores humanos (`MAX_PLAYERS`). El cliente recuerda el último servidor y usuario, y muestra el ping abajo a la derecha.

Si aún no han llegado todos, los **bots** rellenan la sala.

## Probar en GitHub Codespaces

El repo incluye `.devcontainer/` con un escritorio remoto (noVNC) para ver la ventana de Pygame en el navegador.

1. Abre un Codespace del repo (Code → Codespaces). Si ya estaba abierto, F1 → *Codespaces: Rebuild Container*.
2. Terminal 1: `python server/server.py`
3. Abre la pestaña **Ports**, puerto **6080** → clave `vscode`. Dentro del escritorio abre una terminal:
   `cd /workspaces/<nombre-del-repo> && python client/client.py`
4. Crea una cuenta y entra a un modo: los bots completan la sala.

Limitación: Codespaces solo reenvía HTTP, así que otros jugadores **no pueden conectarse por sockets** a ese servidor.
Para jugar con amigos, corre el servidor en un PC (misma red, o con un túnel TCP como ngrok/playit.gg).

## Controles

| Acción | Tecla |
|--------|-------|
| Mover | A / D o flechas |
| Saltar | W, Espacio o ↑ |
| Atravesar plataforma | S o ↓ |
| Apuntar | Mouse |
| Disparar / atacar | Click izquierdo (mantener) |
| Cambiar arma | 1–8 o rueda del mouse |
| Volver al menú | ESC |

## Arquitectura

```
multijugador_juego/
├── server/server.py   # sockets + hilos, lógica de partida autoritativa, SQLite
├── client/client.py   # Pygame: login, menú, ranking y partida
├── requirements.txt
└── README.md
```

* **Protocolo**: JSON, un mensaje por línea. Cliente → servidor: `register`, `login`, `modes`,
  `join`, `leave`, `input`, `ranking`, `stats`. Servidor → cliente: `auth`, `modes`, `joined`,
  `state` (30 Hz), `ranking`, `stats`.
* **Servidor autoritativo**: física a 60 Hz; el cliente solo envía teclas y ángulo de apuntado.
  Los disparos son instantáneos (hitscan) con detección contra cabeza (círculo) y cuerpo (caja).
* **Seguridad básica**: contraseñas con PBKDF2-SHA256 + sal, consultas SQL parametrizadas,
  una sesión por usuario, límite de tamaño de mensaje.
* **Base de datos** (`server/database.db`, se crea sola): tablas `users` y `mode_stats`
  (victorias, puntos, kills, headshots y mejor racha por modo). El ranking se puede ver global o por modo.

## Ajustes rápidos (server.py)

* `MODES[...]["target"]`: puntos para ganar. `WEAPONS`: daño, cadencia, alcance, retroceso.
* `HEAD_BASE`, `HEAD_GROW`, `HEAD_MAX`: tamaño de cabeza y crecimiento por racha.
* `speed_mult`, `jump_mult`, `fire_mult`, `score_mult`: multiplicadores de racha.
* `PLATFORMS` y `SPAWNS`: diseño del mapa.
