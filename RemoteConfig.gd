extends Node
# Autoload: RemoteConfig. Control remoto del juego desde tu PC.
#
# Descarga un archivo config.json que tú editas y subes a internet (ver control/LEEME.txt).
# Con él puedes: bloquear versiones viejas, poner mantenimiento, cambiar tu número de Nequi
# y el límite de tiradas gratis, SIN volver a publicar el APK.

# ========= CONFIGURA ESTO =========
# Número de versión de ESTE build. Súbelo (2, 3, 4...) cada vez que publiques una versión nueva.
const VERSION_ACTUAL := 1
# Enlace directo a tu config.json (ej: https://TUUSUARIO.github.io/retos-config/config.json)
# Vacío = control remoto desactivado.
const CONFIG_URL := ""
# Si es true y NUNCA se pudo descargar la configuración, el juego se bloquea (más estricto).
const EXIGIR_INTERNET := false
# Cada cuántos segundos vuelve a revisar mientras el juego está abierto.
const REVISAR_CADA := 300.0
# ==================================

const CACHE := "user://remote_cfg.json"

var cfg: Dictionary = {}
var _http: HTTPRequest
var _capa: CanvasLayer
var _timer: Timer
var _tuvo_respuesta := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _cargar_cache()
    _aplicar()
    if CONFIG_URL == "":
        return
    _http = HTTPRequest.new()
    _http.timeout = 12.0
    add_child(_http)
    _http.request_completed.connect(_on_respuesta)
    _timer = Timer.new()
    _timer.wait_time = REVISAR_CADA
    _timer.autostart = true
    _timer.timeout.connect(revisar)
    add_child(_timer)
    revisar()

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_RESUMED:
        revisar()

func revisar() -> void:
    if CONFIG_URL == "" or _http == null:
        return
    if _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
        return
    # Parámetro aleatorio para evitar respuestas en caché
    var url: String = CONFIG_URL + ("&" if "?" in CONFIG_URL else "?") + "t=" + str(Time.get_unix_time_from_system())
    _http.request(url)

func _on_respuesta(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
    if result != HTTPRequest.RESULT_SUCCESS or code != 200:
        _aplicar()
        return
    var data = JSON.parse_string(body.get_string_from_utf8())
    if typeof(data) != TYPE_DICTIONARY:
        return
    cfg = data
    _tuvo_respuesta = true
    var f := FileAccess.open(CACHE, FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify(cfg))
    _aplicar()

func _cargar_cache() -> void:
    if FileAccess.file_exists(CACHE):
        var f := FileAccess.open(CACHE, FileAccess.READ)
        if f:
            var data = JSON.parse_string(f.get_as_text())
            if typeof(data) == TYPE_DICTIONARY:
                cfg = data

# ---------- Valores que usa el juego ----------
func numero_nequi(por_defecto: String) -> String:
    return str(cfg.get("nequi_numero", por_defecto))

func url_nequi(por_defecto: String) -> String:
    return str(cfg.get("nequi_url", por_defecto))

func limite_gratis(por_defecto: int) -> int:
    return int(cfg.get("tiradas_gratis", por_defecto))

# ---------- Bloqueo ----------
func _motivo_bloqueo() -> String:
    if bool(cfg.get("mantenimiento", false)):
        return "mantenimiento"
    if int(cfg.get("version_minima", 0)) > VERSION_ACTUAL:
        return "actualizar"
    if EXIGIR_INTERNET and CONFIG_URL != "" and not _tuvo_respuesta and cfg.is_empty():
        return "internet"
    return ""

func _aplicar() -> void:
    var motivo: String = _motivo_bloqueo()
    if motivo == "":
        _quitar_capa()
        return
    _mostrar_capa(motivo)

func _quitar_capa() -> void:
    if _capa != null:
        _capa.queue_free()
        _capa = null

func _mostrar_capa(motivo: String) -> void:
    _quitar_capa()
    _capa = CanvasLayer.new()
    _capa.layer = 200
    add_child(_capa)
    var raiz := Control.new()
    raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    raiz.offset_left = -700
    raiz.offset_right = 700
    raiz.offset_top = -700
    raiz.offset_bottom = 700
    raiz.mouse_filter = Control.MOUSE_FILTER_STOP
    _capa.add_child(raiz)
    var fondo := ColorRect.new()
    fondo.color = Color("#070b1f")
    fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    fondo.offset_left = -700
    fondo.offset_right = 700
    fondo.offset_top = -700
    fondo.offset_bottom = 700
    fondo.mouse_filter = Control.MOUSE_FILTER_STOP
    raiz.add_child(fondo)

    var titulo := "Actualización necesaria"
    var msg := "Esta versión ya no está disponible. Descarga la nueva versión para seguir jugando."
    var icono := "⬆️"
    if motivo == "mantenimiento":
        titulo = "En mantenimiento"
        msg = "Estamos mejorando el juego. Vuelve en unos minutos."
        icono = "🛠️"
    elif motivo == "internet":
        titulo = "Sin conexión"
        msg = "Conéctate a internet para abrir el juego."
        icono = "📡"
    if str(cfg.get("mensaje", "")) != "":
        msg = str(cfg["mensaje"])

    _texto(raiz, icono, 540, 520, 200, Color.WHITE)
    _texto(raiz, titulo, 540, 800, 74, Color("#ffd867"))
    var l := _texto(raiz, msg, 540, 1010, 42, Color.WHITE)
    l.custom_minimum_size = Vector2(880, 0)
    l.size = Vector2(880, 300)
    l.position = Vector2(100, 900)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    var url := str(cfg.get("url_actualizacion", ""))
    if motivo == "actualizar" and url.begins_with("http"):
        var b := Button.new()
        b.text = "Descargar actualización"
        b.position = Vector2(190, 1320)
        b.size = Vector2(700, 140)
        b.add_theme_font_size_override("font_size", 46)
        b.pressed.connect(func(): OS.shell_open(url))
        raiz.add_child(b)
    var r := Button.new()
    r.text = "Reintentar"
    r.position = Vector2(340, 1520)
    r.size = Vector2(400, 110)
    r.add_theme_font_size_override("font_size", 38)
    r.pressed.connect(revisar)
    raiz.add_child(r)

func _texto(p: Control, t: String, cx: float, y: float, fs: int, col: Color) -> Label:
    var l := Label.new()
    l.text = t
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size", fs)
    l.add_theme_color_override("font_color", col)
    l.size = Vector2(1000, fs * 1.4)
    l.position = Vector2(cx - 500, y - fs * 0.7)
    p.add_child(l)
    return l
