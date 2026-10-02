extends Control
# Dificultades de un área (estilo "selección de nivel"): Fácil, Media y Difícil, con 20 preguntas cada una.
# · Fácil: siempre abierta. · Media: se abre al terminar la fácil. · Difícil: se abre al terminar la media completa.
# El fondo cambia según el área (res://assets/<area>_fondo.jpg; Zootecnia usa zoo_fondo.jpg).

const COLORES: Array[Color] = [Color("#58cf3c"), Color("#ff9f1c"), Color("#ef4b4b")]

var id: String = ""

func _ready() -> void:
    id = Global.categoria_actual
    EduFondo.aplicar(self, id)

    # Panel azul translúcido con borde, como la lista de niveles de referencia
    var panel := Panel.new()
    panel.position = Vector2(56, 245)
    panel.size = Vector2(966, 1500)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_theme_stylebox_override("panel", GameUI.flat_box(Color(0.10, 0.20, 0.40, 0.78), Color(0.55, 0.75, 1.0, 0.3), 44, 2))
    add_child(panel)

    var nombre: String = I18n.t(str(Global.EDU_NOMBRE.get(id, "edu_title")))
    var t := GameUI.label3d(self, nombre.to_upper(), Vector2(60, 285), Vector2(960, 130), 92, Color("#c8f03a"), Color("#5c8a12"), 9, Color("#173a08"))
    t.autowrap_mode = TextServer.AUTOWRAP_OFF
    GameUI.label(self, I18n.t("edu_sel"), Vector2(100, 425), Vector2(880, 70), 42, Color.WHITE, false, 7)
    GameUI.label(self, I18n.t("lvl_rule"), Vector2(100, 495), Vector2(880, 90), 28, Color("#cfe3ff"), true, 6)

    # Botón de regreso redondo con flecha
    var atras := GameUI.dot_button(self, Vector2(49, 58), 150, Color("#0f2456"), Color("#54d0ff"), 7, _volver)
    atras.text = "←"
    atras.add_theme_font_size_override("font_size", 90)
    for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
        atras.add_theme_color_override(c, Color.WHITE)

    # Insignia arriba a la derecha: preguntas respondidas del área (X/60)
    var badge := Panel.new()
    badge.position = Vector2(560, 70)
    badge.size = Vector2(460, 120)
    badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
    badge.add_theme_stylebox_override("panel", GameUI.flat_box(Color("#10275a"), Color("#54d0ff"), 60, 4))
    add_child(badge)
    GameUI.label(badge, "⭐", Vector2(14, 0), Vector2(90, 120), 52)
    GameUI.label(badge, I18n.t("edu_preg"), Vector2(100, 10), Vector2(340, 52), 34, Color.WHITE, false, 6)
    GameUI.label(badge, "%d/%d" % [Global.edu_respondidas(id), Global.EDU_PREGUNTAS * 3], Vector2(100, 60), Vector2(340, 52), 38, Color("#ffd23f"), false, 6)

    var textos: Array[String] = ["lvl_easy", "lvl_mid", "lvl_hard"]
    for i in range(3):
        _boton_nivel(i, I18n.t(textos[i]), COLORES[i])

func _boton_nivel(i: int, texto: String, color: Color) -> void:
    var pos := Vector2(120, 630 + i * 360)
    var sz := Vector2(840, 320)
    var superado: bool = Global.edu_nivel_pasado(id, i)
    var disponible: bool = Global.edu_nivel_abierto(id, i)
    # azul oscuro con candado = bloqueada · color vivo = disponible · verde-lima con estrella = superada
    var base: Color = Color("#27446f")
    if superado:
        base = Color("#a8d82a")
    elif disponible:
        base = color
    var b := GameUI.glossy(self, "", pos, sz, base, Color.WHITE, _abrir.bind(i), 40, 56, false)
    var icono: String = "🔒"
    if superado:
        icono = "⭐"
    elif disponible:
        icono = "▶"
    GameUI.label(b, icono, Vector2(24, 40), Vector2(150, 150), 100, Color.WHITE, false, 6)
    GameUI.left_label(b, texto.to_upper(), Vector2(190, 36), Vector2(620, 110), 52, Color.WHITE, false)
    var linea: String
    if superado:
        linea = "✓ " + I18n.t("lvl_done") + "  ·  %d/%d" % [Global.EDU_PREGUNTAS, Global.EDU_PREGUNTAS]
    elif disponible:
        linea = I18n.t("lvl_play") + "  ·  %d/%d" % [Global.edu_mejor(id, i), Global.EDU_PREGUNTAS]
    else:
        linea = I18n.t("lvl_locked_prev")
    GameUI.left_label(b, linea, Vector2(190, 170), Vector2(620, 110), 36, Color("#fff6d6") if disponible else Color("#9fb4d8"), true)
    if not disponible:
        b.modulate = Color(1, 1, 1, 0.92)

func _abrir(i: int) -> void:
    if not Global.edu_nivel_abierto(id, i):
        # difícil -> hay que completar la media · media -> hay que completar la fácil
        _mensaje(I18n.t("lvl_need_mid") if i == 2 else I18n.t("lvl_need_easy"))
    elif Global.edu_es_final(id, i + 1) and Global.edu_nivel_pasado(id, i):
        # el Difícil final ya está superado: sigue el PIN del club (o las cartas si ya lo desbloqueó)
        get_tree().change_scene_to_file(Global.escena_final())
    else:
        Global.nivel_actual = i + 1
        get_tree().change_scene_to_file(Global.escena_nivel(id))

func _mensaje(texto: String) -> void:
    var p := GameUI.neon_modal(self, Vector2(820, 560))
    GameUI.label(p, "🔒", Vector2(0, 50), Vector2(820, 130), 90)
    GameUI.label(p, texto, Vector2(60, 210), Vector2(700, 160), 38, Color("#f1ecff"), true, 5)
    GameUI.pill(p, I18n.t("on_ok"), Vector2(210, 410), Vector2(400, 110), "green", GameUI.close_modal.bind(p), 40)

func _volver() -> void:
    get_tree().change_scene_to_file("res://EducativoMenu.tscn")
