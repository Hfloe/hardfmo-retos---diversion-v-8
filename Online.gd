extends Node
# Autoload: Online. Salas de juego en línea con Firebase Realtime Database (REST, sin plugins).
# Configuración: ver control/ONLINE_LEEME.txt

# ========= CONFIGURA ESTO (datos de tu proyecto Firebase) =========
const API_KEY := ""   # Configuración del proyecto > General > Clave de API web
const DB_URL := ""    # Ej: https://retos-estelares-default-rtdb.firebaseio.com
# ==================================================================

# false = el modo en línea aparece bloqueado ("En desarrollo"). Ponlo en true cuando esté listo.
const DISPONIBLE := false

const MAX_JUGADORES := 12
const MAX_RETOS_JUGADOR := 10
const LETRAS := "ABCDEFGHJKLMNPQRSTUVWXYZ"

signal sala_actualizada
signal sala_cerrada
signal error_red

var activo: bool = false
var codigo: String = ""
var pid: String = ""
var soy_host: bool = false
var sala: Dictionary = {}
var mi_nombre: String = ""
var mi_color: int = 0

var _token: String = ""
var _token_exp: float = 0.0
var _timer: Timer
var _polling: bool = false
var _fallos: int = 0
var _snap: Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    var cfg := ConfigFile.new()
    cfg.load("user://online.cfg")
    pid = str(cfg.get_value("o", "pid", ""))
    if pid == "":
        pid = _aleatorio(14)
        cfg.set_value("o", "pid", pid)
        cfg.save("user://online.cfg")
    mi_nombre = str(cfg.get_value("o", "nombre", ""))
    mi_color = int(cfg.get_value("o", "color", 0))
    _timer = Timer.new()
    _timer.wait_time = 1.2
    _timer.timeout.connect(_poll)
    add_child(_timer)

func recordar_perfil(nombre: String, color: int) -> void:
    mi_nombre = nombre
    mi_color = color
    var cfg := ConfigFile.new()
    cfg.load("user://online.cfg")
    cfg.set_value("o", "nombre", nombre)
    cfg.set_value("o", "color", color)
    cfg.save("user://online.cfg")

func configurado() -> bool:
    return API_KEY != "" and DB_URL != ""

func _aleatorio(n: int) -> String:
    var chars := "abcdefghijklmnopqrstuvwxyz0123456789"
    var s := ""
    for i in range(n):
        s += chars[randi() % chars.length()]
    return s

func _codigo_nuevo() -> String:
    var s := ""
    for i in range(4):
        s += LETRAS[randi() % LETRAS.length()]
    return s

# ---------------- Red ----------------
func _auth() -> bool:
    if _token != "" and Time.get_unix_time_from_system() < _token_exp - 60.0:
        return true
    var http := HTTPRequest.new()
    http.timeout = 12.0
    add_child(http)
    var url := "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" + API_KEY
    var err := http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, "{\"returnSecureToken\":true}")
    if err != OK:
        http.queue_free()
        return false
    var r: Array = await http.request_completed
    http.queue_free()
    if r[0] != HTTPRequest.RESULT_SUCCESS or r[1] != 200:
        return false
    var d = JSON.parse_string((r[3] as PackedByteArray).get_string_from_utf8())
    if typeof(d) != TYPE_DICTIONARY:
        return false
    _token = str(d.get("idToken", ""))
    _token_exp = Time.get_unix_time_from_system() + float(d.get("expiresIn", "3600"))
    return _token != ""

func _req(metodo: int, ruta: String, cuerpo = null) -> Dictionary:
    var fallo := {"ok": false, "code": 0, "data": null}
    if not configurado():
        return fallo
    var autenticado: bool = await _auth()
    if not autenticado:
        return fallo
    var http := HTTPRequest.new()
    http.timeout = 12.0
    add_child(http)
    var url := "%s/%s.json?auth=%s" % [DB_URL.rstrip("/"), ruta, _token]
    var body := ""
    if cuerpo != null:
        body = JSON.stringify(cuerpo)
    var err := http.request(url, ["Content-Type: application/json"], metodo, body)
    if err != OK:
        http.queue_free()
        return fallo
    var r: Array = await http.request_completed
    http.queue_free()
    var data = null
    var txt: String = (r[3] as PackedByteArray).get_string_from_utf8()
    if txt != "":
        data = JSON.parse_string(txt)
    var ok: bool = r[0] == HTTPRequest.RESULT_SUCCESS and int(r[1]) >= 200 and int(r[1]) < 300
    return {"ok": ok, "code": int(r[1]), "data": data}

# ---------------- Utilidades de datos ----------------
func _lista(v) -> Array[String]:
    var out: Array[String] = []
    if v is Array:
        for x in v:
            if x != null:
                out.append(str(x))
    elif v is Dictionary:
        var ks: Array = v.keys()
        ks.sort_custom(func(a, b): return int(a) < int(b))
        for k in ks:
            if v[k] != null:
                out.append(str(v[k]))
    return out

func jugadores_ordenados() -> Array:
    var out: Array = []
    var js = sala.get("jugadores", {})
    if js is Dictionary:
        for k in js.keys():
            var d = js[k]
            if d is Dictionary:
                out.append({"pid": str(k), "n": str(d.get("n", "?")), "c": int(d.get("c", 0)), "t": float(d.get("t", 0.0))})
    out.sort_custom(func(a, b): return a["t"] < b["t"] or (a["t"] == b["t"] and a["pid"] < b["pid"]))
    return out

func mi_indice() -> int:
    var js: Array = jugadores_ordenados()
    for i in range(js.size()):
        if js[i]["pid"] == pid:
            return i
    return -1

func ronda() -> Dictionary:
    var r = sala.get("ronda", {})
    if r is Dictionary:
        return r
    return {}

func ronda_id() -> int:
    return int(ronda().get("id", 0))

func pool() -> Array[String]:
    return _lista(sala.get("pool"))

func estado() -> String:
    return str(sala.get("estado", ""))

func mis_retos() -> Array[String]:
    var rs = sala.get("retos", {})
    if rs is Dictionary:
        return _lista(rs.get(pid))
    return []

func total_retos() -> int:
    var n := 0
    var rs = sala.get("retos", {})
    if rs is Dictionary:
        for k in rs.keys():
            n += _lista(rs[k]).size()
    return n

func colores_usados() -> Array:
    var out: Array = []
    for j in jugadores_ordenados():
        out.append(j["c"])
    return out

# ---------------- Crear / unirse / salir ----------------
func crear_sala(nombre: String, color: int) -> String:
    if not configurado():
        return "no_config"
    recordar_perfil(nombre, color)
    for i in range(6):
        var c: String = _codigo_nuevo()
        var r: Dictionary = await _req(HTTPClient.METHOD_GET, "salas/" + c)
        if not r["ok"]:
            return "red"
        if r["data"] == null:
            var t: float = Time.get_unix_time_from_system()
            var datos := {
                "host": pid, "estado": "lobby", "creado": t,
                "jugadores": {pid: {"n": nombre, "c": color, "t": t}},
                "ronda": {"id": 0, "fase": "espera", "ganador": -1}
            }
            var w: Dictionary = await _req(HTTPClient.METHOD_PUT, "salas/" + c, datos)
            if not w["ok"]:
                return "red"
            _entrar(c, true)
            sala = datos
            return ""
    return "red"

func unirse(cod: String, nombre: String, color: int) -> String:
    if not configurado():
        return "no_config"
    recordar_perfil(nombre, color)
    var c: String = cod.strip_edges().to_upper()
    var r: Dictionary = await _req(HTTPClient.METHOD_GET, "salas/" + c)
    if not r["ok"]:
        return "red"
    if r["data"] == null or not (r["data"] is Dictionary):
        return "no_existe"
    var d: Dictionary = r["data"]
    var jug = d.get("jugadores", {})
    if not (jug is Dictionary):
        jug = {}
    if str(d.get("estado", "")) != "lobby" and not jug.has(pid):
        return "en_juego"
    if jug.size() >= MAX_JUGADORES and not jug.has(pid):
        return "llena"
    var usados: Array = []
    for k in jug.keys():
        if k != pid and jug[k] is Dictionary:
            usados.append(int(jug[k].get("c", -1)))
    var col: int = color
    if usados.has(col):
        for i in range(GameUI.palette_size()):
            if not usados.has(i):
                col = i
                break
    var t: float = Time.get_unix_time_from_system()
    if jug.has(pid) and jug[pid] is Dictionary:
        t = float(jug[pid].get("t", t))
    var w: Dictionary = await _req(HTTPClient.METHOD_PUT, "salas/%s/jugadores/%s" % [c, pid], {"n": nombre, "c": col, "t": t})
    if not w["ok"]:
        return "red"
    _entrar(c, str(d.get("host", "")) == pid)
    mi_color = col
    return ""

func _entrar(c: String, host: bool) -> void:
    # Guarda la partida local para restaurarla al salir
    _snap = {
        "num": Global.num_jugadores, "nombres": Global.nombres.duplicate(), "colores": Global.colores.duplicate(),
        "avatares": Global.avatares.duplicate(), "retos": Global.retos.duplicate()
    }
    activo = true
    codigo = c
    soy_host = host
    _fallos = 0
    sala = {}
    _timer.start()
    _poll()

func salir() -> void:
    if not activo:
        return
    var c: String = codigo
    var eh: bool = soy_host
    var en_lobby: bool = estado() == "lobby"
    activo = false
    codigo = ""
    soy_host = false
    _timer.stop()
    sala = {}
    # Restaurar la partida local
    if not _snap.is_empty():
        Global.num_jugadores = int(_snap["num"])
        Global.nombres.clear()
        for x in _snap["nombres"]:
            Global.nombres.append(str(x))
        Global.colores.clear()
        for x in _snap["colores"]:
            Global.colores.append(int(x))
        Global.avatares.clear()
        for x in _snap["avatares"]:
            Global.avatares.append(int(x))
        Global.retos.clear()
        for x in _snap["retos"]:
            Global.retos.append(str(x))
        Global.current_player = -1
        Global.current_card = -1
        _snap = {}
    if eh:
        _req(HTTPClient.METHOD_DELETE, "salas/" + c)
    elif en_lobby:
        _req(HTTPClient.METHOD_DELETE, "salas/%s/jugadores/%s" % [c, pid])

func _poll() -> void:
    if not activo or _polling:
        return
    _polling = true
    var c: String = codigo
    var r: Dictionary = await _req(HTTPClient.METHOD_GET, "salas/" + c)
    _polling = false
    if not activo or c != codigo:
        return
    if r["ok"]:
        _fallos = 0
        if r["data"] == null:
            sala = {}
            sala_cerrada.emit()
        elif r["data"] is Dictionary:
            sala = r["data"]
            sala_actualizada.emit()
    else:
        _fallos += 1
        if _fallos == 8:
            error_red.emit()

# ---------------- Lobby ----------------
func _guardar_mis_retos(lista: Array[String]) -> void:
    var rs = sala.get("retos", {})
    if not (rs is Dictionary):
        rs = {}
    rs[pid] = lista.duplicate()
    sala["retos"] = rs
    await _req(HTTPClient.METHOD_PUT, "salas/%s/retos/%s" % [codigo, pid], lista)

func agregar_reto(texto: String) -> bool:
    var lista: Array[String] = mis_retos()
    if lista.size() >= MAX_RETOS_JUGADOR or texto.strip_edges() == "":
        return false
    lista.append(texto.strip_edges())
    _guardar_mis_retos(lista)
    return true

func quitar_reto(i: int) -> void:
    var lista: Array[String] = mis_retos()
    if i >= 0 and i < lista.size():
        lista.remove_at(i)
        _guardar_mis_retos(lista)

func iniciar_partida() -> String:
    var r: Dictionary = await _req(HTTPClient.METHOD_GET, "salas/" + codigo)
    if not r["ok"] or not (r["data"] is Dictionary):
        return "red"
    sala = r["data"]
    if jugadores_ordenados().size() < 2:
        return "pocos"
    var todos: Array = []
    var rs = sala.get("retos", {})
    if rs is Dictionary:
        for k in rs.keys():
            for t in _lista(rs[k]):
                todos.append(t)
    if todos.is_empty():
        return "sin_retos"
    todos.shuffle()
    var ronda_nueva := {"id": ronda_id() + 1, "fase": "espera", "ganador": -1}
    # "retos": null borra quién escribió cada desafío (queda solo el mazo mezclado y anónimo)
    var w: Dictionary = await _req(HTTPClient.METHOD_PATCH, "salas/" + codigo, {"estado": "juego", "pool": todos, "ronda": ronda_nueva, "retos": null})
    if not w["ok"]:
        return "red"
    sala["estado"] = "juego"
    sala["pool"] = todos
    sala["ronda"] = ronda_nueva
    sala.erase("retos")
    return ""

func preparar_globales() -> void:
    var js: Array = jugadores_ordenados()
    Global.num_jugadores = js.size()
    Global.nombres.clear()
    Global.colores.clear()
    Global.avatares.clear()
    for i in range(js.size()):
        Global.nombres.append(str(js[i]["n"]))
        Global.colores.append(int(js[i]["c"]))
        Global.avatares.append(i)
    Global.retos.clear()
    for t in pool():
        Global.retos.append(t)
    Global.current_player = -1
    Global.current_card = -1

# ---------------- Partida ----------------
func girar() -> Dictionary:
    var n: int = jugadores_ordenados().size()
    if n < 1 or pool().is_empty():
        return {}
    var d := {"id": ronda_id() + 1, "fase": "giro", "ganador": randi_range(0, n - 1), "vueltas": randi_range(4, 6), "jit": randf_range(-0.35, 0.35)}
    sala["ronda"] = d
    _req(HTTPClient.METHOD_PATCH, "salas/" + codigo, {"ronda": d})
    return d

func publicar_reto(texto: String, ganador: int) -> void:
    var d := {"id": ronda_id() + 1, "fase": "reto", "ganador": ganador, "reto": texto}
    sala["ronda"] = d
    await _req(HTTPClient.METHOD_PATCH, "salas/" + codigo, {"ronda": d})

func completar(nueva: Array) -> void:
    var fin: bool = nueva.is_empty()
    var d := {"id": ronda_id() + 1, "fase": "fin" if fin else "espera", "ganador": -1}
    sala["ronda"] = d
    sala["pool"] = nueva
    var payload := {"ronda": d}
    if fin:
        payload["pool"] = null
    else:
        payload["pool"] = nueva
    await _req(HTTPClient.METHOD_PATCH, "salas/" + codigo, payload)
