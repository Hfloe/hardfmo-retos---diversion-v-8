extends Control

const MAX_JUGADORES := 40
const MAX_PERSONALIZABLES := 7
# Colores vivos tipo videojuego para los nombres (el color de la ruleta se asigna solo).
const COLORES_NOMBRE: Array[Color] = [
    Color("#ffd23f"), Color("#37e0a4"), Color("#ff6fb5"), Color("#5cf0ff"),
    Color("#ff9a3d"), Color("#9be04a"), Color("#ff5a5a")
]

var count: int = 1
var count_label: Label
var list: VBoxContainer
var names: Array[String] = []
var avatars: Array[int] = []
var edits: Array[LineEdit] = []

func _ready() -> void:
    count = clampi(Global.num_jugadores, 1, MAX_JUGADORES)
    for n in Global.nombres:
        names.append(n)
    for a in Global.avatares:
        avatars.append(a)
    _ensure(MAX_JUGADORES)

    GameUI.bg(self)
    GameUI.label3d(self, I18n.t("setup_title"), Vector2(60, 100), Vector2(960, 120), 50, Color("#ffd84a"), Color("#a86400"), 9, Color("#5a2d00"))
    GameUI.label(self, I18n.t("setup_sub"), Vector2(90, 205), Vector2(900, 50), 30, Color("#5cf0ff"), false, 6)
    GameUI.pill(self, "‹", Vector2(90, 110), Vector2(90, 90), "dark", _volver, 60)

    GameUI.frame(self, Rect2(90, 280, 900, 320), Color("#7a4be0"), 4, 44, false, Color(0.06, 0.04, 0.16, 0.85))
    # "Cantidad": centrado, sin estrella y en 3D
    GameUI.label3d(self, I18n.t("numbers"), Vector2(90, 295), Vector2(900, 80), 50, Color("#ff7be5"), Color("#8a1f7a"), 8, Color("#3d0a38"))
    # Menos a la izquierda, más a la derecha
    var b_menos := GameUI.dot_button(self, Vector2(150, 400), 130, Color("#3a1220"), Color("#ff5a5a"), 6, _menos)
    _barras(b_menos, false, Color("#ff8a8a"))
    var b_mas := GameUI.dot_button(self, Vector2(800, 400), 130, Color("#0f3a2c"), Color("#37e0a4"), 6, _mas)
    _barras(b_mas, true, Color("#8dfcd0"))
    GameUI.frame(self, Rect2(330, 385, 420, 160), Color("#f6c343"), 3, 30, false, Color("#0b0820"))
    count_label = GameUI.label(self, "", Vector2(330, 390), Vector2(420, 100), 76, Color("#37e0a4"), false, 6)
    GameUI.label(self, I18n.t("max_fmt") % MAX_JUGADORES, Vector2(330, 488), Vector2(420, 50), 24, Color("#9fe8ff"), false, 4)

    var scroll := ScrollContainer.new()
    scroll.position = Vector2(90, 630)
    scroll.size = Vector2(900, 1030)
    add_child(scroll)
    list = VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 20)
    scroll.add_child(list)

    _refresh()
    GameUI.pill(self, I18n.t("continue") + "  ›", Vector2(140, 1700), Vector2(800, 130), "green", _continuar, 46)

func _barras(boton: Button, con_mas: bool, color: Color) -> void:
    # El signo se dibuja con barras para que siempre se vea grande y centrado.
    var c: Vector2 = boton.size / 2.0
    var h := ColorRect.new()
    h.color = color
    h.size = Vector2(64, 14)
    h.position = c - h.size / 2.0
    h.mouse_filter = Control.MOUSE_FILTER_IGNORE
    boton.add_child(h)
    if con_mas:
        var v := ColorRect.new()
        v.color = color
        v.size = Vector2(14, 64)
        v.position = c - v.size / 2.0
        v.mouse_filter = Control.MOUSE_FILTER_IGNORE
        boton.add_child(v)

func _ensure(n: int) -> void:
    while names.size() < n:
        names.append("")
    while avatars.size() < n:
        avatars.append(avatars.size() % 5)

func _capture() -> void:
    for i in range(edits.size()):
        if is_instance_valid(edits[i]) and i < names.size():
            names[i] = edits[i].text

func _menos() -> void:
    _capture()
    count = clampi(count - 1, 1, MAX_JUGADORES)
    _refresh()

func _mas() -> void:
    _capture()
    count = clampi(count + 1, 1, MAX_JUGADORES)
    _refresh()

func _refresh() -> void:
    count_label.text = str(count)
    for c in list.get_children():
        c.queue_free()
    edits.clear()
    if count > MAX_PERSONALIZABLES:
        list.add_child(_bloqueado(I18n.t("name")))
        return
    for i in range(count):
        list.add_child(_fila(i))

func _bloqueado(titulo: String) -> Control:
    var p := Panel.new()
    p.custom_minimum_size = Vector2(880, 190)
    p.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var s := StyleBoxFlat.new()
    s.bg_color = Color("#0e0b24")
    s.border_color = Color("#2fd6c8")
    s.set_border_width_all(3)
    s.set_corner_radius_all(36)
    p.add_theme_stylebox_override("panel", s)
    var l := GameUI.label(p, "🔒  " + titulo, Vector2(40, 20), Vector2(800, 70), 48, Color("#ffd23f"))
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    var h := GameUI.label(p, I18n.t("only7"), Vector2(40, 100), Vector2(800, 60), 28, Color("#9fe8ff"))
    h.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    return p

func _fila(i: int) -> Control:
    var tinta: Color = COLORES_NOMBRE[i % COLORES_NOMBRE.size()]
    var row := Panel.new()
    row.custom_minimum_size = Vector2(880, 190)
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var s := StyleBoxFlat.new()
    s.bg_color = Color(0.04, 0.06, 0.16, 0.9)
    s.border_color = tinta
    s.set_border_width_all(4)
    s.set_corner_radius_all(40)
    row.add_theme_stylebox_override("panel", s)

    var le := LineEdit.new()
    le.position = Vector2(25, 25)
    le.size = Vector2(830, 140)
    le.placeholder_text = "%s %02d" % [I18n.t("participant"), i + 1]
    le.text = names[i]
    le.add_theme_font_size_override("font_size", 50)
    le.add_theme_color_override("font_color", tinta)
    le.add_theme_color_override("caret_color", Color.WHITE)
    le.add_theme_color_override("font_placeholder_color", tinta.darkened(0.35))
    le.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
    le.add_theme_constant_override("outline_size", 5)
    var st := StyleBoxFlat.new()
    st.bg_color = Color("#070b1c")
    st.border_color = tinta.darkened(0.3)
    st.set_border_width_all(3)
    st.set_corner_radius_all(30)
    st.content_margin_left = 30
    st.content_margin_right = 30
    le.add_theme_stylebox_override("normal", st)
    var st_focus: StyleBoxFlat = st.duplicate() as StyleBoxFlat
    st_focus.border_color = Color.WHITE
    le.add_theme_stylebox_override("focus", st_focus)
    row.add_child(le)
    edits.append(le)
    return row

func _continuar() -> void:
    _capture()
    Global.num_jugadores = count
    Global.nombres.clear()
    Global.colores.clear()
    Global.avatares.clear()
    for i in range(count):
        var n := ""
        if count <= MAX_PERSONALIZABLES:
            n = names[i].strip_edges()
        if n == "":
            n = "%s %02d" % [I18n.t("participant"), i + 1]
        Global.nombres.append(n)
        Global.colores.append(i % GameUI.palette_size())  # el color de la ruleta se asigna solo
        Global.avatares.append(avatars[i] if count <= MAX_PERSONALIZABLES else i % 5)
    Global.guardar_datos()
    get_tree().change_scene_to_file("res://RetosAnonimos.tscn")

func _volver() -> void:
    get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
