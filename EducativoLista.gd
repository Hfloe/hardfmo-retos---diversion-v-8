extends Control
# Selección de nivel (estilo de la imagen de referencia): 20 niveles por dificultad, en cuadrícula de 4 x 5.
# Cada nivel es UNA pregunta. El nivel 1 empieza abierto; cada nivel se abre al acertar el anterior.
# Cada nivel superado da 2 puntos (máximo 40 por dificultad). Al acertar el nivel 20 se supera la dificultad.
# El avance de la carrera se guarda con Global.edu_run (0-20); edu_mejor / edu_registrar_progreso guardan el mejor progreso (desbloquea áreas).
# Al pasar el nivel 12 se gana una vida; con 2 errores desde el nivel 13 la carrera vuelve al nivel 1 (si hay una vida, se gasta y sigue).

const COLORES: Array[Color] = [Color("#58cf3c"), Color("#ff9f1c"), Color("#ef4b4b")]
const COLUMNAS := 4
const CELDA := Vector2(196, 196)
const SEPARACION := 24.0
const PUNTOS_NIVEL := 2

var id: String = ""
var dif: int = 0   # 0 fácil · 1 media · 2 difícil

func _ready() -> void:
    id = Global.categoria_actual
    dif = clampi(Global.nivel_actual - 1, 0, 2)
    EduFondo.aplicar(self, id)

    var panel := Panel.new()
    panel.position = Vector2(56, 245)
    panel.size = Vector2(966, 1490)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_theme_stylebox_override("panel", GameUI.flat_box(Color(0.10, 0.20, 0.40, 0.78), Color(0.55, 0.75, 1.0, 0.3), 44, 2))
    add_child(panel)

    var nombre: String = I18n.t(str(Global.EDU_NOMBRE.get(id, "edu_title")))
    var t := GameUI.label3d(self, nombre.to_upper(), Vector2(60, 280), Vector2(960, 130), 92, Color("#c8f03a"), Color("#5c8a12"), 9, Color("#173a08"))
    t.autowrap_mode = TextServer.AUTOWRAP_OFF
    GameUI.label(self, I18n.t("lvl_select_title"), Vector2(100, 420), Vector2(880, 66), 42, Color.WHITE, false, 7)
    # Etiqueta con la dificultad (fácil / media / difícil), en el color de esa dificultad
    var etiqueta_dif := Panel.new()
    etiqueta_dif.position = Vector2(300, 490)
    etiqueta_dif.size = Vector2(480, 64)
    etiqueta_dif.mouse_filter = Control.MOUSE_FILTER_IGNORE
    etiqueta_dif.add_theme_stylebox_override("panel", GameUI.flat_box(COLORES[dif].darkened(0.25), COLORES[dif].lightened(0.3), 32, 3))
    add_child(etiqueta_dif)
    GameUI.label(etiqueta_dif, I18n.t(["lvl_easy", "lvl_mid", "lvl_hard"][dif]).to_upper(), Vector2(0, 0), Vector2(480, 64), 34, Color.WHITE, false, 5)

    # Botón de regreso redondo con flecha (vuelve a elegir dificultad)
    var atras := GameUI.dot_button(self, Vector2(49, 58), 150, Color("#0f2456"), Color("#54d0ff"), 7, _volver)
    atras.text = "←"
    atras.add_theme_font_size_override("font_size", 90)
    for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
        atras.add_theme_color_override(c, Color.WHITE)

    # Insignia arriba a la derecha: puntos de esta dificultad
    var hechos: int = Global.edu_run(id, dif)   # niveles superados en la carrera actual (vuelve a 0 si falla 2 veces)
    GameUI.label(self, "❤️ x%d" % Global.edu_vidas(), Vector2(215, 62), Vector2(330, 62), 46, Color("#ff9aa8"), false, 6)
    GameUI.label(self, "💎 x%d" % Jugador.gemas(), Vector2(215, 126), Vector2(330, 62), 46, Color("#e9b3ff"), false, 6)
    var badge := Panel.new()
    badge.position = Vector2(560, 70)
    badge.size = Vector2(460, 120)
    badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
    badge.add_theme_stylebox_override("panel", GameUI.flat_box(Color("#10275a"), Color("#54d0ff"), 60, 4))
    add_child(badge)
    GameUI.label(badge, "⭐", Vector2(14, 0), Vector2(90, 120), 52)
    GameUI.label(badge, I18n.t("lvl_points_fmt") % (hechos * PUNTOS_NIVEL), Vector2(100, 10), Vector2(340, 52), 34, Color.WHITE, false, 6)
    GameUI.label(badge, "%d/%d PTS" % [hechos * PUNTOS_NIVEL, Global.EDU_PREGUNTAS * PUNTOS_NIVEL], Vector2(100, 60), Vector2(340, 52), 38, Color("#ffd23f"), false, 6)

    for n in range(1, Global.EDU_PREGUNTAS + 1):
        _boton_nivel(n, hechos)

    var v := GameUI.glossy(self, "↩  " + I18n.t("qz_back_levels"), Vector2(190, 1765), Vector2(700, 110), Color("#4a3fd6"), Color.WHITE, _volver, 40, 40)
    v.focus_mode = Control.FOCUS_NONE

func _boton_nivel(n: int, hechos: int) -> void:
    var k: int = n - 1
    var col: int = k % COLUMNAS
    @warning_ignore("integer_division")
    var fila: int = k / COLUMNAS
    var ancho_total: float = COLUMNAS * CELDA.x + (COLUMNAS - 1) * SEPARACION
    var x0: float = 56.0 + (966.0 - ancho_total) / 2.0
    var pos := Vector2(x0 + col * (CELDA.x + SEPARACION), 575.0 + fila * (CELDA.y + SEPARACION))
    var superado: bool = n <= hechos
    var disponible: bool = n <= hechos + 1
    # azul oscuro con candado = bloqueado · color de la dificultad = el que toca jugar · verde-lima con estrella = superado
    var base: Color = Color("#27446f")
    if superado:
        base = Color("#a8d82a")
    elif disponible:
        base = COLORES[dif]
    var b := GameUI.glossy(self, "", pos, CELDA, base, Color.WHITE, _abrir.bind(n), 30, 34, false)
    var icono: String = "🔒"
    if superado:
        icono = "⭐"
    elif disponible:
        icono = "▶"
    GameUI.label(b, icono, Vector2(0, 14), Vector2(CELDA.x, 100), 70, Color.WHITE, false, 5)
    var etiqueta: String = I18n.t("lvl_n_fmt") % n
    var fs: int = 32
    GameUI.label(b, etiqueta, Vector2(0, 120), Vector2(CELDA.x, 60), fs, Color.WHITE if disponible else Color("#9fb4d8"), false, 5)
    if not disponible:
        b.modulate = Color(1, 1, 1, 0.92)

func _abrir(n: int) -> void:
    if n > Global.edu_run(id, dif) + 1:
        _mensaje(I18n.t("lvl_need_prev"))
        return
    Global.nivel_pregunta = n
    get_tree().change_scene_to_file("res://Quiz.tscn")

func _mensaje(texto: String) -> void:
    var p := GameUI.neon_modal(self, Vector2(820, 560))
    GameUI.label(p, "🔒", Vector2(0, 50), Vector2(820, 130), 90)
    GameUI.label(p, texto, Vector2(60, 210), Vector2(700, 160), 38, Color("#f1ecff"), true, 5)
    GameUI.pill(p, I18n.t("on_ok"), Vector2(210, 410), Vector2(400, 110), "green", GameUI.close_modal.bind(p), 40)

func _volver() -> void:
    get_tree().change_scene_to_file("res://EducativoNiveles.tscn")
