extends Control
# Lista de retos del Club Privado: se ven todos, se pueden editar, borrar y añadir (a mano o 20 aleatorios).
# Los cambios se guardan solos. La primera vez, la lista se llena con 20 retos aleatorios.

const CANT_ALEATORIOS := 20
const ORO := Color("#f0cf82")

var lista: VBoxContainer
var scroll: ScrollContainer
var contador: Label
var ultimo_editor: TextEdit = null

func _ready() -> void:
    Global.entrar_club()
    GameUI.bg_img(self, "res://assets/bg_club.jpg")
    _cabecera()
    var t := GameUI.label(self, I18n.t("club_retos_title"), Vector2(40, 236), Vector2(1000, 84), 58, Color("#a8f2ff"), false, 8)
    t.add_theme_color_override("font_outline_color", Color("#0a5a80"))
    GameUI.label(self, I18n.t("club_retos_sub"), Vector2(40, 318), Vector2(1000, 44), 30, Color("#7fe8ff"), false, 5)
    contador = GameUI.label(self, "", Vector2(40, 364), Vector2(1000, 44), 34, Color("#ffe08a"), false, 6)

    scroll = ScrollContainer.new()
    scroll.position = Vector2(50, 420)
    scroll.size = Vector2(980, 1010)
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    add_child(scroll)
    lista = VBoxContainer.new()
    lista.custom_minimum_size = Vector2(960, 0)
    lista.add_theme_constant_override("separation", 18)
    scroll.add_child(lista)

    GameUI.glossy(self, "＋  " + I18n.t("club_add_one"), Vector2(50, 1450), Vector2(470, 108), Color("#3aa0f0"), Color("#06244a"), _anadir_uno, 40, 30)
    GameUI.glossy(self, "🎲  " + I18n.t("club_add_20"), Vector2(560, 1450), Vector2(470, 108), Color("#c69a3e"), Color.WHITE, _anadir_aleatorios, 40, 30)
    GameUI.glossy(self, "✓  " + I18n.t("club_done"), Vector2(150, 1590), Vector2(780, 112), Color("#3fd35a"), Color.WHITE, _volver, 50)

    if Global.retos.is_empty():
        _sumar_aleatorios()
    _construir()

func _cabecera() -> void:
    var franja := Panel.new()
    var fs := StyleBoxFlat.new()
    fs.bg_color = Color(0.02, 0.05, 0.14, 0.92)
    fs.border_color = Color("#2b9fe0")
    fs.border_width_bottom = 3
    franja.add_theme_stylebox_override("panel", fs)
    franja.position = Vector2(0, 96)
    franja.size = Vector2(1080, 122)
    franja.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(franja)
    var atras := GameUI.flat_button(self, Vector2(28, 108), Vector2(100, 98), Color(0, 0, 0, 0), Color(0, 0, 0, 0), _volver, 20, 0)
    atras.text = "←"
    atras.add_theme_font_size_override("font_size", 80)
    for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
        atras.add_theme_color_override(c, Color("#5fe8ff"))
    var h := GameUI.label(self, "💎  " + I18n.t("club_header"), Vector2(130, 108), Vector2(820, 98), 56, ORO, false, 8)
    h.add_theme_color_override("font_outline_color", Color("#2a1c00"))

func _construir() -> void:
    for c in lista.get_children():
        lista.remove_child(c)
        c.queue_free()
    ultimo_editor = null
    for i in range(Global.retos.size()):
        lista.add_child(_fila(i))
    contador.text = I18n.t("club_retos_fmt") % Global.retos.size() + " / %d" % Global.MAX_RETOS

func _fila(i: int) -> Control:
    var fila := Panel.new()
    fila.custom_minimum_size = Vector2(960, 190)
    fila.mouse_filter = Control.MOUSE_FILTER_PASS
    var s := StyleBoxFlat.new()
    s.bg_color = Color(0.02, 0.06, 0.15, 0.9)
    s.border_color = Color("#3d7fbf")
    s.set_border_width_all(3)
    s.set_corner_radius_all(26)
    fila.add_theme_stylebox_override("panel", s)
    GameUI.label(fila, str(i + 1), Vector2(8, 10), Vector2(70, 60), 36, Color("#e8c26a"))
    var te := TextEdit.new()
    te.position = Vector2(80, 16)
    te.size = Vector2(740, 158)
    te.text = Global.retos[i]
    te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
    te.add_theme_font_size_override("font_size", 32)
    te.add_theme_color_override("font_color", Color.WHITE)
    te.add_theme_color_override("caret_color", Color("#ffe08a"))
    te.add_theme_color_override("background_color", Color(0.01, 0.03, 0.09, 1.0))
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color("#06122c")
    sb.border_color = Color("#2b9fe0")
    sb.set_border_width_all(2)
    sb.set_corner_radius_all(18)
    sb.content_margin_left = 16
    sb.content_margin_right = 16
    sb.content_margin_top = 10
    sb.content_margin_bottom = 10
    te.add_theme_stylebox_override("normal", sb)
    te.add_theme_stylebox_override("focus", sb)
    te.text_changed.connect(_editado.bind(i, te))
    fila.add_child(te)
    ultimo_editor = te
    var borrar := GameUI.flat_button(fila, Vector2(836, 40), Vector2(104, 110), Color("#3a1220"), Color("#ff5a5a"), _borrar.bind(i), 26, 4)
    borrar.text = "🗑"
    borrar.add_theme_font_size_override("font_size", 52)
    return fila

func _editado(i: int, te: TextEdit) -> void:
    if i < Global.retos.size():
        Global.retos[i] = te.text
        Global.guardar_club()

func _borrar(i: int) -> void:
    if i < Global.retos.size():
        Global.retos.remove_at(i)
        Global.guardar_club()
        Audio.play("whoosh")
        _construir()

func _anadir_uno() -> void:
    if Global.retos.size() >= Global.MAX_RETOS:
        Audio.play("error")
        return
    Global.retos.append("")
    Global.guardar_club()
    _construir()
    await get_tree().process_frame
    await get_tree().process_frame
    if is_inside_tree():
        scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
        if ultimo_editor != null:
            ultimo_editor.grab_focus()

func _anadir_aleatorios() -> void:
    if Global.retos.size() >= Global.MAX_RETOS:
        Audio.play("error")
        return
    _sumar_aleatorios()
    _construir()
    await get_tree().process_frame
    await get_tree().process_frame
    if is_inside_tree():
        scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)

func _sumar_aleatorios() -> void:
    var pool: Array[String] = []
    if FileAccess.file_exists("res://picante.json"):
        var f := FileAccess.open("res://picante.json", FileAccess.READ)
        var datos: Variant = JSON.parse_string(f.get_as_text())
        if datos is Array:
            for x in datos:
                var t: String = str(x)
                if not Global.retos.has(t):
                    pool.append(t)
    pool.shuffle()
    var n: int = mini(mini(CANT_ALEATORIOS, Global.MAX_RETOS - Global.retos.size()), pool.size())
    for k in range(n):
        Global.retos.append(pool[k])
    Global.guardar_club()

func _volver() -> void:
    # se quitan los retos que quedaron vacíos
    var limpios: Array[String] = []
    for r in Global.retos:
        if str(r).strip_edges() != "":
            limpios.append(str(r).strip_edges())
    Global.retos.clear()
    for r in limpios:
        Global.retos.append(r)
    Global.guardar_club()
    get_tree().change_scene_to_file("res://ClubPrivado.tscn")
