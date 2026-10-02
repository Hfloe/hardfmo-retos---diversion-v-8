extends Control
# Academia: 5 áreas de estudio (60 preguntas cada una: 20 fáciles, 20 medias, 20 difíciles).
# Zootecnia empieza desbloqueada. La siguiente área se desbloquea al llegar a 30 preguntas respondidas en la actual.
# Las áreas sin contenido todavía (Global.EDU_ACTIVAS) salen con candado y "En Desarrollo".

const BORDES: Array[Color] = [
    Color("#4fbf5a"), Color("#3bb8d8"), Color("#d9a441"), Color("#ff6fb5"), Color("#9b6bff")
]


# --- Desplazamiento táctil: se puede arrastrar desde cualquier parte (también sobre las tarjetas) ---
const UMBRAL_ARRASTRE := 18.0     # píxeles que hay que mover el dedo para considerarlo un arrastre y no un toque
const FRICCION := 4.0             # inercia: más alto = se detiene antes
var scroll: ScrollContainer
var _presionado := false
var _arrastrando := false
var _inicio_y := 0.0
var _scroll_inicio := 0.0
var _ultimo_y := 0.0
var _vel := 0.0                   # velocidad de inercia (px/s)
var _ultimo_t := 0.0
var _bloqueo_toque := false       # true justo después de arrastrar: ignora el "pressed" de la tarjeta

func _ready() -> void:
    GameUI.bg(self)
    GameUI.frame(self, Rect2(40, 40, 1000, 1840), Color("#3b8bff"), 6, 70, true, Color(0.02, 0.03, 0.09, 0.72))
    GameUI.label3d(self, I18n.t("edu_title"), Vector2(60, 80), Vector2(960, 140), 112, Color("#7ff0ff"), Color("#0a6a8a"), 9, Color("#062a3a"))
    GameUI.label(self, I18n.t("edu_sub2"), Vector2(80, 235), Vector2(920, 110), 34, Color("#e6f6ff"), true, 6)

    scroll = ScrollContainer.new()
    scroll.position = Vector2(70, 380)
    scroll.size = Vector2(940, 1215)
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE   # el arrastre lo maneja _input (funciona sobre las tarjetas también)
    add_child(scroll)
    var margen := MarginContainer.new()
    margen.add_theme_constant_override("margin_left", 10)
    margen.add_theme_constant_override("margin_right", 10)
    margen.add_theme_constant_override("margin_top", 10)
    margen.add_theme_constant_override("margin_bottom", 20)
    scroll.add_child(margen)
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 22)
    grid.add_theme_constant_override("v_separation", 22)
    margen.add_child(grid)
    for i in range(Global.EDU_IDS.size()):
        grid.add_child(_tarjeta(i))

    var v := GameUI.glossy(self, "↩  " + I18n.t("back"), Vector2(190, 1650), Vector2(700, 120), Color("#ffc933"), GameUI.DARK_TEXT, _volver, 46)
    v.focus_mode = Control.FOCUS_NONE

func _tarjeta(i: int) -> Button:
    var id: String = Global.EDU_IDS[i]
    var en_servicio: bool = Global.EDU_ACTIVAS.has(id)      # ya tiene preguntas
    var abierta: bool = Global.edu_area_abierta(id)          # el jugador ya la desbloqueó
    var jugable: bool = en_servicio and abierta
    var borde: Color = BORDES[i % BORDES.size()]
    if jugable:
        borde = Color("#ffd23f")
    elif not abierta or not en_servicio:
        borde = Color("#6b6f86")
    var b := Button.new()
    b.custom_minimum_size = Vector2(445, 300)
    b.focus_mode = Control.FOCUS_NONE
    var fondo: Color = borde.darkened(0.86)
    for st in ["normal", "hover", "pressed", "disabled"]:
        b.add_theme_stylebox_override(st, GameUI.flat_box(fondo, borde, 40, 5 if jugable else 3))
    b.pressed.connect(_tocar.bind(id))
    if not jugable:
        b.modulate = Color(1, 1, 1, 0.88)
    # candado en todas las áreas que todavía no se pueden jugar (bloqueadas o en desarrollo); el emoji solo en las jugables
    GameUI.label(b, Global.EDU_EMOJI[id] if jugable else "🔒", Vector2(10, 22), Vector2(120, 110), 76)
    GameUI.left_label(b, I18n.t(Global.EDU_NOMBRE[id]), Vector2(135, 22), Vector2(300, 110), 34, Color("#fff1cf"))
    var estado: String
    var color: Color
    if not en_servicio:
        estado = "🛠️ " + I18n.t("edu_dev")
        color = Color("#ffb04d")
    elif abierta:
        estado = "✅ " + I18n.t("edu_active")
        color = Color("#8dfcae")
    else:
        estado = "🔒 " + I18n.t("edu_locked_cost")
        color = Color("#ffd0d0")
    GameUI.label(b, estado, Vector2(10, 150), Vector2(425, 50), 30, color, false, 4)
    if jugable:
        var resp: int = Global.edu_respondidas(id)
        GameUI.label(b, "%d/%d  %s" % [resp, Global.EDU_PREGUNTAS * 3, I18n.t("edu_preg").to_lower()], Vector2(10, 198), Vector2(425, 40), 26, Color("#cfd6ee"))
        var marco := Panel.new()
        marco.position = Vector2(30, 250)
        marco.size = Vector2(385, 26)
        marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
        marco.add_theme_stylebox_override("panel", GameUI.flat_box(Color("#0a100c"), Color("#3a4a3a"), 13, 2))
        b.add_child(marco)
        if resp > 0:
            var relleno := Panel.new()
            relleno.position = Vector2(33, 253)
            relleno.size = Vector2(379.0 * float(resp) / float(Global.EDU_PREGUNTAS * 3), 20)
            relleno.mouse_filter = Control.MOUSE_FILTER_IGNORE
            relleno.add_theme_stylebox_override("panel", GameUI.flat_box(Color("#4fbf5a"), Color("#4fbf5a"), 10, 0))
            b.add_child(relleno)
    return b

func _en_zona(pos: Vector2) -> bool:
    return Rect2(scroll.global_position, scroll.size * scroll.get_global_transform().get_scale()).has_point(pos)

func _input(event: InputEvent) -> void:
    if scroll == null:
        return
    if event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        if mb.button_index == MOUSE_BUTTON_WHEEL_UP and _en_zona(mb.position):
            scroll.scroll_vertical -= 120
        elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and _en_zona(mb.position):
            scroll.scroll_vertical += 120
        elif mb.button_index == MOUSE_BUTTON_LEFT:
            if mb.pressed and _en_zona(mb.position):
                _presionado = true
                _arrastrando = false
                _bloqueo_toque = false
                _vel = 0.0
                _inicio_y = mb.position.y
                _ultimo_y = mb.position.y
                _scroll_inicio = float(scroll.scroll_vertical)
                _ultimo_t = Time.get_ticks_msec() / 1000.0
            elif not mb.pressed:
                _presionado = false
                if _arrastrando:
                    _bloqueo_toque = true
                    # se libera el bloqueo en el siguiente frame, cuando la tarjeta ya ignoró su "pressed"
                    get_tree().process_frame.connect(func(): _bloqueo_toque = false, CONNECT_ONE_SHOT)
                _arrastrando = false
    elif event is InputEventMouseMotion and _presionado:
        var mm := event as InputEventMouseMotion
        if not _arrastrando and absf(mm.position.y - _inicio_y) > UMBRAL_ARRASTRE:
            _arrastrando = true
        if _arrastrando:
            scroll.scroll_vertical = int(_scroll_inicio + (_inicio_y - mm.position.y))
            var t := Time.get_ticks_msec() / 1000.0
            var dt := maxf(t - _ultimo_t, 0.001)
            _vel = lerpf(_vel, (_ultimo_y - mm.position.y) / dt, 0.5)
            _ultimo_y = mm.position.y
            _ultimo_t = t
            get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
    if scroll == null or _presionado or absf(_vel) < 8.0:
        return
    scroll.scroll_vertical = int(scroll.scroll_vertical + _vel * delta)
    _vel = lerpf(_vel, 0.0, clampf(FRICCION * delta, 0.0, 1.0))

func _tocar(id: String) -> void:
    if _bloqueo_toque or _arrastrando:
        return   # fue un arrastre para desplazar, no un toque en la tarjeta
    if not Global.EDU_ACTIVAS.has(id):
        _mensaje("🛠️", I18n.t("cat_dev_msg"))
    elif not Global.edu_area_abierta(id):
        var previa: String = str(Global.EDU_IDS[maxi(0, Global.EDU_IDS.find(id) - 1)])
        _mensaje("🔒", I18n.t("edu_need_q_fmt") % I18n.t(Global.EDU_NOMBRE[previa]))
    else:
        _abrir(id)

func _abrir(id: String) -> void:
    Global.categoria_actual = id
    get_tree().change_scene_to_file("res://EducativoNiveles.tscn")

func _mensaje(icono: String, texto: String) -> void:
    var p := GameUI.neon_modal(self, Vector2(820, 560))
    GameUI.label(p, icono, Vector2(0, 40), Vector2(820, 130), 90)
    GameUI.label(p, texto, Vector2(60, 200), Vector2(700, 180), 38, Color("#f1ecff"), true, 5)
    GameUI.pill(p, I18n.t("on_ok"), Vector2(210, 410), Vector2(400, 110), "green", GameUI.close_modal.bind(p), 40)

func _volver() -> void:
    get_tree().change_scene_to_file("res://RetosAnonimos.tscn")
