class_name Jugador
extends RefCounted
# Datos del jugador: perfil (nombre, foto, XP), monedas, gemas, puntos de logro y estadísticas por área.
# Se guardan en user://jugador.cfg (en Godot no existe localStorage: esto es el equivalente).
# Los valores de premios se ajustan en las constantes de abajo.

const RUTA := "user://jugador.cfg"
const FOTO := "user://foto_perfil.png"

const XP_ACIERTO := 10          # XP por cada respuesta correcta
const MONEDAS_ACIERTO := 2      # monedas por cada respuesta correcta
const GEMAS_NIVEL := 1          # gemas la primera vez que se supera una dificultad
const COSTO_PISTA := 3          # gemas que cuesta una pista (quiz y crucigramas)
const COSTO_SALVAR := 2         # gemas para salvarse de volver al nivel 1 tras 2 errores
const PUNTOS_AREA := 30         # puntos de logro por cada área nueva desbloqueada
const XP_POR_NIVEL := 100       # XP necesarios para subir cada nivel de perfil
const AVATARES := ["😀", "😎", "🤓", "🦊", "🐯", "🐼", "🦁", "🐸", "🦄", "🐙", "🚀", "⚽"]
const COLORES_AVATAR := ["#3b8bff", "#ff8a1f", "#c46fe0", "#2fd6a0", "#ff5a7a", "#ffd23f"]

static func _cfg() -> ConfigFile:
    var c := ConfigFile.new()
    c.load(RUTA)
    return c

# ---------- Perfil ----------
static func nombre() -> String:
    return str(_cfg().get_value("perfil", "nombre", "Jugador"))

static func set_nombre(n: String) -> void:
    n = n.strip_edges()
    if n == "":
        return
    var c := _cfg()
    c.set_value("perfil", "nombre", n.substr(0, 16))
    c.save(RUTA)

static func avatar() -> int:
    return clampi(int(_cfg().get_value("perfil", "avatar", 0)), 0, AVATARES.size() - 1)

static func set_avatar(i: int) -> void:
    var c := _cfg()
    c.set_value("perfil", "avatar", i)
    c.set_value("perfil", "foto", false)   # elegir un avatar reemplaza la foto
    c.save(RUTA)

static func tiene_foto() -> bool:
    return bool(_cfg().get_value("perfil", "foto", false)) and FileAccess.file_exists(FOTO)

# Recorta la imagen a cuadrado, la reduce a 256x256 y la guarda como foto de perfil.
static func guardar_foto(ruta: String) -> bool:
    var img := Image.load_from_file(ruta)
    if img == null or img.is_empty():
        return false
    var lado: int = mini(img.get_width(), img.get_height())
    @warning_ignore("integer_division")
    img = img.get_region(Rect2i((img.get_width() - lado) / 2, (img.get_height() - lado) / 2, lado, lado))
    img.resize(256, 256, Image.INTERPOLATE_LANCZOS)
    if img.save_png(FOTO) != OK:
        return false
    var c := _cfg()
    c.set_value("perfil", "foto", true)
    c.save(RUTA)
    return true

# ---------- XP, monedas, gemas, puntos ----------
static func xp() -> int:
    return maxi(0, int(_cfg().get_value("perfil", "xp", 0)))

static func nivel() -> int:
    @warning_ignore("integer_division")
    return 1 + xp() / XP_POR_NIVEL

static func xp_en_nivel() -> int:
    return xp() % XP_POR_NIVEL

static func monedas() -> int:
    return maxi(0, int(_cfg().get_value("perfil", "monedas", 0)))

static func gemas() -> int:
    return maxi(0, int(_cfg().get_value("perfil", "gemas", 0)))

static func puntos_logro() -> int:
    return areas_logro().size() * PUNTOS_AREA

static func sumar_gemas(n: int) -> void:
    var c := _cfg()
    c.set_value("perfil", "gemas", int(c.get_value("perfil", "gemas", 0)) + n)
    c.save(RUTA)

# Gasta gemas. Devuelve false (y no descuenta nada) si no alcanzan.
static func gastar_gemas(n: int) -> bool:
    var c := _cfg()
    var tengo: int = int(c.get_value("perfil", "gemas", 0))
    if tengo < n:
        return false
    c.set_value("perfil", "gemas", tengo - n)
    c.save(RUTA)
    return true

# ---------- Estadísticas por área ----------
# Se llama en cada respuesta de la Academia. Solo las áreas jugadas tienen datos.
static func registrar_respuesta(area: String, correcta: bool) -> void:
    var c := _cfg()
    var k: String = area + ("_ok" if correcta else "_mal")
    c.set_value("stats", k, int(c.get_value("stats", k, 0)) + 1)
    if correcta:
        c.set_value("perfil", "xp", int(c.get_value("perfil", "xp", 0)) + XP_ACIERTO)
        c.set_value("perfil", "monedas", int(c.get_value("perfil", "monedas", 0)) + MONEDAS_ACIERTO)
    c.save(RUTA)

# Devuelve [{"area": id, "ok": n, "mal": n}] solo de las áreas con al menos una respuesta, en el orden del menú.
static func areas_jugadas() -> Array:
    var c := _cfg()
    var res: Array = []
    for id in Global.EDU_IDS:
        var ok: int = int(c.get_value("stats", str(id) + "_ok", 0))
        var mal: int = int(c.get_value("stats", str(id) + "_mal", 0))
        if ok + mal > 0:
            res.append({"area": str(id), "ok": ok, "mal": mal})
    return res

# ---------- Puntos de logro: 30 por cada área nueva desbloqueada ----------
static func areas_logro() -> Array:
    var v: Variant = _cfg().get_value("perfil", "areas_logro", [])
    return v if v is Array else []

static func logro_area(area: String) -> bool:
    var lista: Array = areas_logro().duplicate()
    if lista.has(area):
        return false
    lista.append(area)
    var c := _cfg()
    c.set_value("perfil", "areas_logro", lista)
    c.save(RUTA)
    return true
