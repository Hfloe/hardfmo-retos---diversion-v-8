extends Node

const MAX_RETOS := 40
const PROGRESO := "user://progreso.cfg"
# Número de Nequi al que se paga el desbloqueo. Escríbelo aquí, por ejemplo "300 123 4567".
const NEQUI_NUMERO := ""
# Academia: 9 áreas en orden (5 jugables + 4 "En Desarrollo"). La primera (Zootecnia) empieza desbloqueada; cada área abre la siguiente al llegar a 30 preguntas respondidas.
const EDU_IDS := ["zootecnia", "mecanica_moto", "psicologia", "agronomia", "biologia", "ciencia_politica", "historia", "datos_curiosos", "famosos"]
# Áreas que ya tienen contenido jugable (Zootecnia, Mecánica, Psicología, Agronomía, Biología); las demás muestran candado y "En Desarrollo".
# Para activar un área nueva: añade su id aquí, pon sus 3 JSON (20 preguntas c/u) y su <area>_palabras.json en preguntas/.
const EDU_ACTIVAS := ["zootecnia", "mecanica_moto", "psicologia", "agronomia", "biologia"]
const EDU_UNIR := ["ingles"]                      # áreas cuyos niveles son de unir parejas (Unir.tscn) en vez de preguntas
const EDU_INICIAL := "zootecnia"                   # área que siempre empieza desbloqueada
const EDU_NIVELES := ["facil", "medio", "dificil"]   # 3 dificultades por área
const EDU_PREGUNTAS := 20                            # preguntas por dificultad (60 por área)
const EDU_PARA_DESBLOQUEAR := 30                     # preguntas respondidas en el área para desbloquear la siguiente
# Reglas de la carrera dentro de una dificultad (20 niveles):
const EDU_NIVEL_VIDA := 12          # al superar este nivel se gana una vida
const EDU_NIVEL_RIESGO := 1         # desde este nivel los errores cuentan (1 = en todos los niveles)
const EDU_ERRORES_MAX := 2          # 2 errores en cualquier nivel = vuelve al nivel 1 (con una vida, la gasta y sigue; si no, puede salvarse pagando gemas)
const EDU_VIDAS_MAX := 3            # máximo de vidas guardadas
# ---------- Secreto final (correo + PIN + cartas) ----------
const CORREO_SECRETO := "hardemojuego@gmail.com"   # correo al que el jugador envía la captura de su carta
const CORREO_OPINIONES := "retosdiversionharfdmo@gmail.com"   # correo donde los participantes envían opiniones y sugerencias
const CLUB_PIN := "4829"                            # PIN que le das tú por correo (cámbialo aquí cuando quieras)
const CLUB_REPETIR := false                         # true = se puede volver a elegir carta (solo para pruebas)
const CLUB_PRIVADO_DISPONIBLE := false   # false = el Club Privado sale como "En desarrollo"
const EDU_EMOJI := {"agronomia": "🌱", "zootecnia": "🐄", "psicologia": "🧠", "biologia": "🧬", "mecanica_moto": "🏍️", "fisica": "⚛️", "matematicas": "➗", "ingles": "🔤", "historia": "📜", "datos_curiosos": "💡", "famosos": "⭐", "ciencia_politica": "🏛️", "cultura": "🌍", "programacion": "💻"}
const EDU_NOMBRE := {"agronomia": "edu_agr", "zootecnia": "edu_zoo", "psicologia": "edu_psy", "biologia": "edu_bio", "mecanica_moto": "edu_moto", "fisica": "edu_fis", "matematicas": "edu_mat", "ingles": "edu_ing", "historia": "edu_his", "datos_curiosos": "edu_dat", "famosos": "edu_fam", "ciencia_politica": "edu_pol", "cultura": "edu_cul", "programacion": "edu_prog"}

# Código que desbloquea el contenido adulto (se entrega tras pagar por Nequi).
const PIN_ADULTOS := "1759"
# --- Periodo de prueba ---
const LIMITE_BASE := 300  # tiradas gratis por defecto (se puede cambiar desde config.json)

var LIMITE_GRATIS: int:
    get:
        return RemoteConfig.limite_gratis(LIMITE_BASE)
const GRATIS := 5  # cuántos fondos/estilos de carta son gratis, de 5 (antes: 2)

var num_jugadores: int = 0
var nombres: Array[String] = []
var colores: Array[int] = []
var avatares: Array[int] = []
var retos: Array[String] = []
var completados: Array[String] = []  # desafíos ya cumplidos: vuelven al mazo solo con "Barajar desde el inicio"
var tiradas_usadas: int = 0
var giros_sesion: int = 0            # giros de ruleta desde que se abrió la app (cada 5 sale el mensaje de donación)
var anuncio_inicio_visto: bool = false   # el anuncio de donación al entrar sale una vez por sesión
var _k: int = 7429
var _check: int = 0
var expira: int = 0
var idioma: String = "es"
var fondo: int = 0
var carta_estilo: int = 0
var sonido: bool = true
var voz: bool = true               # lectura en voz alta del participante y del desafío (se puede silenciar)
var club_verificado: bool = false  # true = ya puso su PIN personal en esta sesión (se borra al cerrar el juego)
var carta_modo: int = 0            # Club: 0 = voltear la carta enseguida · 1 = raspar para descubrirla
var club_n: int = 4                # Club: cantidad de jugadores (2 a 8)
var club_modo: bool = false        # true = partida del Club Privado (la ruleta elimina hasta que queda un ganador)
var club_vivos: Array[int] = []    # índices de los jugadores que siguen en la ruleta del Club
var club_nombres: Array[String] = ["", "", "", "", "", "", "", ""]
var club_colores: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7]
var club_avatares: Array[int] = [0, 1, 2, 3, 4, 0, 1, 2]
var _respaldo: Dictionary = {}     # desafíos de la partida normal, guardados mientras se juega en el Club
var terminos_aceptados: bool = false
var categoria_actual: String = ""
var volver_a: String = ""          # pantalla a la que regresa Paywall (vacío = ruleta)
var abrir_pin: bool = false        # true = al volver a Desafíos se abre directo la ventana del código del Club Privado
var registro_activo: bool = false  # true mientras se están registrando desafíos (evita borrar la lista al volver de otra pantalla)
var nivel_actual: int = 1
var nivel_pregunta: int = 1       # Academia: nivel (1-20) que se está jugando dentro de la dificultad; cada nivel es una pregunta
var current_player: int = -1
var current_card: int = -1
var premium_verificado_servidor: bool = false

var premium: bool:
    get:
        return _check == _k and Time.get_unix_time_from_system() < expira and premium_verificado_servidor

func _ready() -> void:
    cargar_datos()
    cargar_tema()

# Color del texto de un reto picante según su categoría (💑 novios · 👯 amigos · 😈 atrevidos).
func color_reto(texto: String) -> Color:
    if texto.begins_with("💑"):
        return Color("#d6246e")
    if texto.begins_with("👯"):
        return Color("#c76a00")
    if texto.begins_with("😈"):
        return Color("#d62a1a")
    return Color("#1a1033")

func desbloqueado(i: int) -> bool:
    return i < GRATIS or premium

# Fondos y cartas personalizados: solo se aplican dentro del Club Privado.
func fondo_efectivo() -> int:
    return 0   # los fondos antiguos del Club ya no se usan: ahora se elige en Apariencia (tema_fondo)

func carta_efectiva() -> int:
    if not club_modo:
        return 0
    return carta_estilo if desbloqueado(carta_estilo) else 0

func carta_raspar() -> bool:
    if club_modo:
        return carta_modo == 1
    return carta_raspa_normal()

# Cartas de la partida normal (se elige en Configuración > Fondo y botones > Cartas):
# true = "raspa y gana" para ver el reto · false = verlo enseguida. Se guarda en user://progreso.cfg ([tema]).
func carta_raspa_normal() -> bool:
    var cfg := ConfigFile.new()
    if cfg.load(PROGRESO) != OK:
        return false
    return bool(cfg.get_value("tema", "carta_raspa", false))

func guardar_carta_raspa_normal(raspa: bool) -> void:
    var cfg := ConfigFile.new()
    cfg.load(PROGRESO)
    cfg.set_value("tema", "carta_raspa", raspa)
    cfg.save(PROGRESO)

func n_jugadores() -> int:
    return club_n if club_modo else num_jugadores

func nombre_de(i: int) -> String:
    var lista: Array[String] = club_nombres if club_modo else nombres
    if i >= 0 and i < lista.size() and lista[i] != "":
        return lista[i]
    return "%s %02d" % [I18n.t("participant"), i + 1]

func color_de(i: int) -> Color:
    var cols: Array[int] = club_colores if club_modo else colores
    var idx: int = cols[i] if (i >= 0 and i < cols.size()) else i
    return GameUI.palette_color(idx)

func avatar_de(i: int) -> String:
    var avs: Array[int] = club_avatares if club_modo else avatares
    var idx: int = avs[i] if (i >= 0 and i < avs.size()) else i
    return GameUI.avatar_glyph(idx)

func guardar_datos() -> void:
    if Online.activo:
        return  # en línea no se toca la partida guardada del teléfono
    if club_modo:
        guardar_club()  # el Club Privado tiene sus propios datos; la partida normal no se toca
        return
    var cfg := ConfigFile.new()
    cfg.set_value("game", "num_jugadores", num_jugadores)
    cfg.set_value("game", "nombres", nombres)
    cfg.set_value("game", "colores", colores)
    cfg.set_value("game", "avatares", avatares)
    cfg.set_value("game", "retos", retos)
    cfg.set_value("game", "completados", completados)
    cfg.set_value("game", "tiradas_usadas", tiradas_usadas)
    cfg.set_value("game", "expira", expira)
    cfg.set_value("game", "idioma", idioma)
    cfg.set_value("game", "sonido", sonido)
    cfg.set_value("game", "voz", voz)
    cfg.set_value("game", "terminos_aceptados", terminos_aceptados)
    cfg.set_value("game", "fondo", fondo)
    cfg.set_value("game", "carta_estilo", carta_estilo)
    cfg.set_value("game", "premium_check", _check)
    cfg.set_value("game", "premium_verified", premium_verificado_servidor)
    cfg.save("user://s.dat")

func cargar_datos() -> void:
    var cfg := ConfigFile.new()
    if cfg.load("user://s.dat") != OK:
        return
    num_jugadores = int(cfg.get_value("game", "num_jugadores", 0))
    nombres.clear()
    for n in cfg.get_value("game", "nombres", []):
        nombres.append(str(n))
    colores.clear()
    for c in cfg.get_value("game", "colores", []):
        colores.append(int(c))
    avatares.clear()
    for a in cfg.get_value("game", "avatares", []):
        avatares.append(int(a))
    retos.clear()
    for r in cfg.get_value("game", "retos", []):
        retos.append(str(r))
    completados.clear()
    for r in cfg.get_value("game", "completados", []):
        completados.append(str(r))
    tiradas_usadas = int(cfg.get_value("game", "tiradas_usadas", 0))
    expira = int(cfg.get_value("game", "expira", 0))
    idioma = str(cfg.get_value("game", "idioma", "es"))
    sonido = bool(cfg.get_value("game", "sonido", true))
    voz = bool(cfg.get_value("game", "voz", true))
    terminos_aceptados = bool(cfg.get_value("game", "terminos_aceptados", false))
    fondo = int(cfg.get_value("game", "fondo", 0))
    carta_estilo = int(cfg.get_value("game", "carta_estilo", 0))
    _check = int(cfg.get_value("game", "premium_check", 0))
    premium_verificado_servidor = bool(cfg.get_value("game", "premium_verified", false))
    if not premium:
        premium_verificado_servidor = false

func reset_game() -> void:
    num_jugadores = 0
    nombres.clear()
    colores.clear()
    avatares.clear()
    retos.clear()
    completados.clear()
    tiradas_usadas = 0
    current_player = -1
    current_card = -1
    guardar_datos()

# ---------- Progreso guardado en user://progreso.cfg ----------

func adultos_desbloqueado() -> bool:
    var cfg := ConfigFile.new()
    if cfg.load(PROGRESO) != OK:
        return false
    return bool(cfg.get_value("adultos", "desbloqueado", false))

func desbloquear_adultos() -> void:
    var cfg := ConfigFile.new()
    cfg.load(PROGRESO)  # si no existe todavía, se crea al guardar
    cfg.set_value("adultos", "desbloqueado", true)
    cfg.save(PROGRESO)

# ---------- Academia ----------
# 5 áreas, cada una con 3 dificultades de 20 preguntas (60 en total).
# · Zootecnia empieza desbloqueada. La siguiente área se desbloquea al llegar a 30 preguntas respondidas en el área actual
#   (las 20 de la dificultad fácil + 10 de la media). Ahí sale el aviso "Área Desbloqueada".
# · Dificultad fácil: siempre abierta. Media: se abre al terminar la fácil. Difícil: se abre al terminar la media completa.
# Datos en user://progreso.cfg, sección [educativo]:
#   abiertas (áreas desbloqueadas) · <área>_pas (máscara de dificultades superadas) · <área>_mejor ([fácil, media, difícil]: mejor racha de aciertos 0-20)

# ¿Esta dificultad es la Difícil de la última área disponible? (al superarla se pide el PIN del club)
func edu_es_final(cat: String, nivel: int) -> bool:
    return cat == str(EDU_ACTIVAS[EDU_ACTIVAS.size() - 1]) and nivel >= EDU_NIVELES.size()

func escena_final() -> String:
    return "res://ClubRecompensas.tscn" if club_pin_ok() else "res://PinFinal.tscn"

func club_pin_ok() -> bool:
    var cfg := ConfigFile.new()
    cfg.load(PROGRESO)
    return bool(cfg.get_value("secreto", "pin_ok", false))

func club_set_pin_ok() -> void:
    var cfg := ConfigFile.new()
    cfg.load(PROGRESO)
    cfg.set_value("secreto", "pin_ok", true)
    cfg.save(PROGRESO)

# "" = todavía no eligió carta · "premio" o "vacia" = la carta que eligió (solo se puede elegir una vez)
func club_resultado() -> String:
    if CLUB_REPETIR:
        return ""
    var cfg := ConfigFile.new()
    cfg.load(PROGRESO)
    return str(cfg.get_value("secreto", "carta", ""))

func club_fecha() -> String:
    var cfg := ConfigFile.new()
    cfg.load(PROGRESO)
    return str(cfg.get_value("secreto", "fecha", ""))

func club_idx() -> int:
    var cfg := ConfigFile.new()
    cfg.load(PROGRESO)
    return int(cfg.get_value("secreto", "idx", -1))

func club_guardar_resultado(r: String, fecha: String, idx: int = -1) -> void:
    if CLUB_REPETIR:
        return
    var cfg := ConfigFile.new()
    cfg.load(PROGRESO)
    cfg.set_value("secreto", "carta", r)
    cfg.set_value("secreto", "fecha", fecha)
    cfg.set_value("secreto", "idx", idx)
    cfg.save(PROGRESO)

# Personalización de las cartas del Club de Recompensas (estilo del reverso 0-4 y modo "raspa y gana").
func club_carta_estilo() -> int:
    var cfg := ConfigFile.new()
    cfg.load(PROGRESO)
    var e: int = clampi(int(cfg.get_value("secreto", "carta_estilo", 0)), 0, 4)
    return e if desbloqueado(e) else 0

func club_carta_raspa() -> bool:
    var cfg := ConfigFile.new()
    cfg.load(PROGRESO)
    return int(cfg.get_value("secreto", "carta_modo", 1)) == 1

func club_guardar_carta(estilo: int, raspa: bool) -> void:
    var cfg := ConfigFile.new()
    cfg.load(PROGRESO)
    cfg.set_value("secreto", "carta_estilo", estilo)
    cfg.set_value("secreto", "carta_modo", 1 if raspa else 0)
    cfg.save(PROGRESO)

# Escena que abre una dificultad de un área: unir parejas (Inglés) o la lista de 20 niveles de preguntas.
func escena_nivel(cat: String) -> String:
    return "res://Unir.tscn" if EDU_UNIR.has(cat) else "res://EducativoLista.tscn"   # lista de 20 niveles (cada uno abre Quiz.tscn)

var edu_primera_vez: bool = false   # la última dificultad se superó por primera vez

func _edu_cargar() -> ConfigFile:
    var cfg := ConfigFile.new()
    cfg.load(PROGRESO)
    var ver: int = int(cfg.get_value("educativo", "version", 0))
    if ver < 2:
        # Migración del sistema antiguo (niveles en orden, "<área>_lv"): lo ya superado sigue superado.
        for cat in EDU_IDS:
            var n: int = clampi(int(cfg.get_value("educativo", cat + "_lv", 0)), 0, EDU_NIVELES.size())
            if n > 0:
                cfg.set_value("educativo", cat + "_pas", (1 << n) - 1)
    if ver < 3:
        # Sistema por preguntas respondidas: el área que el jugador tenía abierta antes sigue desbloqueada.
        var abiertas: Array = []
        var vieja: String = str(cfg.get_value("educativo", "activa", EDU_INICIAL))
        if EDU_IDS.has(vieja) and vieja != EDU_INICIAL:
            abiertas.append(vieja)
        cfg.set_value("educativo", "abiertas", abiertas)
        cfg.set_value("educativo", "version", 3)
        cfg.save(PROGRESO)
    return cfg

func _edu_abiertas(cfg: ConfigFile) -> Array:
    var v: Variant = cfg.get_value("educativo", "abiertas", [])
    return v if v is Array else []

# ¿El área está desbloqueada? (Zootecnia siempre; las demás al llegar a 30 preguntas en la anterior)
func edu_area_abierta(cat: String) -> bool:
    return cat == EDU_INICIAL or _edu_abiertas(_edu_cargar()).has(cat)

# El área que sigue a "cat" en el orden de EDU_IDS ("" si es la última).
func edu_siguiente_area(cat: String) -> String:
    var i: int = EDU_IDS.find(cat)
    if i < 0 or i + 1 >= EDU_IDS.size():
        return ""
    return str(EDU_IDS[i + 1])

func _bits(n: int) -> int:
    var c: int = 0
    while n > 0:
        c += n & 1
        n >>= 1
    return c

# Cuántas dificultades del área están superadas (0 a 3).
func edu_niveles_ok(cat: String) -> int:
    return _bits(int(_edu_cargar().get_value("educativo", cat + "_pas", 0)))

func edu_nivel_pasado(cat: String, idx: int) -> bool:
    return (int(_edu_cargar().get_value("educativo", cat + "_pas", 0)) & (1 << idx)) != 0

# Fácil (0): siempre abierta · Media (1): al terminar la fácil · Difícil (2): al terminar la media completa.
func edu_nivel_abierto(cat: String, idx: int) -> bool:
    if idx <= 0:
        return true
    return edu_nivel_pasado(cat, idx - 1)

# Mejor progreso (0-20) de una dificultad. Una dificultad superada cuenta como 20.
func edu_mejor(cat: String, idx: int) -> int:
    if edu_nivel_pasado(cat, idx):
        return EDU_PREGUNTAS
    var v: Variant = _edu_cargar().get_value("educativo", cat + "_mejor", [0, 0, 0])
    if v is Array and idx < v.size():
        return clampi(int(v[idx]), 0, EDU_PREGUNTAS)
    return 0

# Preguntas respondidas en el área (suma del mejor progreso de las 3 dificultades, máximo 60).
func edu_respondidas(cat: String) -> int:
    var total: int = 0
    for i in range(EDU_NIVELES.size()):
        total += edu_mejor(cat, i)
    return total

# Se llama al superar un nivel: n = niveles superados en esta dificultad (1 a 20).
# Devuelve el id del área recién desbloqueada, o "" si no se desbloqueó ninguna.
func edu_registrar_progreso(cat: String, idx: int, n: int) -> String:
    var cfg := _edu_cargar()
    var mejor: Array = [0, 0, 0]
    var v: Variant = cfg.get_value("educativo", cat + "_mejor", [0, 0, 0])
    if v is Array:
        for i in range(mini(3, v.size())):
            mejor[i] = int(v[i])
    if n > int(mejor[idx]):
        mejor[idx] = clampi(n, 0, EDU_PREGUNTAS)
        cfg.set_value("educativo", cat + "_mejor", mejor)
        cfg.save(PROGRESO)
    if edu_respondidas(cat) < EDU_PARA_DESBLOQUEAR:
        return ""
    var sig: String = edu_siguiente_area(cat)
    if sig == "" or edu_area_abierta(sig):
        return ""
    cfg = _edu_cargar()
    var abiertas: Array = _edu_abiertas(cfg).duplicate()
    abiertas.append(sig)
    cfg.set_value("educativo", "abiertas", abiertas)
    cfg.save(PROGRESO)
    Jugador.logro_area(sig)   # +30 puntos de logro la primera vez que se desbloquea esa área
    return sig

# ---------- Carrera actual dentro de una dificultad + vidas ----------
# "Mejor progreso" (edu_mejor) nunca baja: sirve para desbloquear áreas. La "carrera" (edu_run) sí vuelve a 0
# cuando el participante falla 2 veces desde el nivel 13 sin tener una vida.

# Niveles superados en la carrera actual de esta dificultad (0-20). Es lo que abre los niveles en la lista.
func edu_run(cat: String, idx: int) -> int:
    var cfg := _edu_cargar()
    var v: Variant = null
    if cfg.has_section_key("educativo", cat + "_run"):
        v = cfg.get_value("educativo", cat + "_run")
    if v is Array and idx < v.size():
        return clampi(int(v[idx]), 0, EDU_PREGUNTAS)
    return edu_mejor(cat, idx)   # partidas guardadas antes de este sistema

func edu_run_set(cat: String, idx: int, n: int) -> void:
    var run: Array = [edu_run(cat, 0), edu_run(cat, 1), edu_run(cat, 2)]
    run[idx] = clampi(n, 0, EDU_PREGUNTAS)
    var cfg := _edu_cargar()
    cfg.set_value("educativo", cat + "_run", run)
    cfg.save(PROGRESO)

func edu_vidas() -> int:
    return clampi(int(_edu_cargar().get_value("educativo", "vidas", 0)), 0, EDU_VIDAS_MAX)

func edu_vidas_sumar(n: int) -> void:
    var nuevo: int = clampi(edu_vidas() + n, 0, EDU_VIDAS_MAX)
    var cfg := _edu_cargar()
    cfg.set_value("educativo", "vidas", nuevo)
    cfg.save(PROGRESO)

# Dificultad superada (idx 0 a 2) al acertar las 20.
func edu_pasar_nivel(cat: String, idx: int) -> void:
    edu_primera_vez = false
    var cfg := _edu_cargar()
    var pas: int = int(cfg.get_value("educativo", cat + "_pas", 0))
    if (pas & (1 << idx)) == 0:
        cfg.set_value("educativo", cat + "_pas", pas | (1 << idx))
        edu_primera_vez = true
        cfg.save(PROGRESO)

# ---------- Apariencia (fondo y color de botones, en todas las pantallas menos el menú principal) ----------
const TEMA_NFONDOS := 6
var tema_fondo: int = -1   # -1 = el fondo original de cada pantalla · 0 a 5 = uno de los 6 fondos de res://fondos/tema_N.jpg
var apariencia_volver: String = "res://Configuracion.tscn"   # pantalla a la que regresa Apariencia
var tema_boton: int = -1   # -1 = colores originales de los botones · 0 a 7 = color elegido (GameUI.TEMA_BOTONES)

func cargar_tema() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(PROGRESO) != OK:
        return
    tema_fondo = clampi(int(cfg.get_value("tema", "fondo", -1)), -1, TEMA_NFONDOS - 1)
    tema_boton = clampi(int(cfg.get_value("tema", "boton", -1)), -1, GameUI.TEMA_BOTONES.size() - 1)

func guardar_tema() -> void:
    var cfg := ConfigFile.new()
    cfg.load(PROGRESO)
    cfg.set_value("tema", "fondo", tema_fondo)
    cfg.set_value("tema", "boton", tema_boton)
    cfg.save(PROGRESO)

# ---------- Club Privado (datos propios, separados de la partida normal) ----------

func entrar_club() -> void:
    if club_modo:
        return
    _respaldo = {"retos": retos.duplicate(), "completados": completados.duplicate()}
    club_modo = true
    club_vivos.clear()
    var cfg := ConfigFile.new()
    cfg.load(PROGRESO)
    club_nombres = ["", "", "", "", "", "", "", ""]
    var n: Variant = cfg.get_value("club", "nombres", [])
    if n is Array:
        for i in range(mini(8, n.size())):
            club_nombres[i] = str(n[i])
    club_n = clampi(int(cfg.get_value("club", "n", 4)), 2, 8)
    carta_modo = clampi(int(cfg.get_value("club", "carta_modo", 0)), 0, 1)
    fondo = clampi(int(cfg.get_value("club", "fondo", fondo)), 0, 4)
    carta_estilo = clampi(int(cfg.get_value("club", "carta_estilo", carta_estilo)), 0, 4)
    retos.clear()
    completados.clear()
    var r: Variant = cfg.get_value("club", "retos", [])
    if r is Array:
        for x in r:
            retos.append(str(x))

func guardar_club() -> void:
    var cfg := ConfigFile.new()
    cfg.load(PROGRESO)
    cfg.set_value("club", "nombres", club_nombres)
    cfg.set_value("club", "n", club_n)
    cfg.set_value("club", "carta_modo", carta_modo)
    cfg.set_value("club", "fondo", fondo)
    cfg.set_value("club", "carta_estilo", carta_estilo)
    cfg.set_value("club", "retos", retos)
    cfg.save(PROGRESO)

func salir_club() -> void:
    if not club_modo:
        return
    guardar_club()
    club_modo = false
    club_vivos.clear()
    retos.clear()
    for r in _respaldo.get("retos", []):
        retos.append(str(r))
    completados.clear()
    for r in _respaldo.get("completados", []):
        completados.append(str(r))
    _respaldo = {}

# ---------- PIN personal del Club Privado ----------
# El código que entrega el creador solo desbloquea; cada persona crea su propio PIN y ese es el que se pide después.

func _hash_pin(pin: String) -> String:
    return (pin + "|chmag|club").sha256_text()

func tiene_pin_personal() -> bool:
    var cfg := ConfigFile.new()
    if cfg.load(PROGRESO) != OK:
        return false
    return str(cfg.get_value("adultos", "pin_personal", "")) != ""

func guardar_pin_personal(pin: String) -> void:
    var cfg := ConfigFile.new()
    cfg.load(PROGRESO)
    cfg.set_value("adultos", "pin_personal", _hash_pin(pin))
    cfg.save(PROGRESO)
    club_verificado = true

func pin_personal_correcto(pin: String) -> bool:
    var cfg := ConfigFile.new()
    if cfg.load(PROGRESO) != OK:
        return false
    return str(cfg.get_value("adultos", "pin_personal", "")) == _hash_pin(pin)
