extends Control
# Sala del Club Privado VIP: de 2 a 8 jugadores (por defecto 4), retos y personalización.
# Los datos del Club (nombres, retos, fondo y cartas) se guardan solos y no tocan la partida normal.
# Al iniciar, la ruleta elimina a un jugador por giro hasta que queda un ganador (ver Ruleta.gd).

const ORO := Color("#f0cf82")
const CIAN := Color("#7fe8ff")
const ALTO_MARCO := 236.0

var info: Label

func _ready() -> void:
    Global.entrar_club()
    GameUI.bg_img(self, "res://assets/bg_club.jpg")
    _cabecera()
    var t := GameUI.label(self, I18n.t("club_title_fmt") % Global.club_n, Vector2(40, 246), Vector2(1000, 84), 56, Color("#a8f2ff"), false, 8)
    t.add_theme_color_override("font_outline_color", Color("#0a5a80"))
    var linea := ColorRect.new()
    linea.color = Color("#c9a24a")
    linea.position = Vector2(250, 352)
    linea.size = Vector2(580, 2)
    linea.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(linea)
    GameUI.label(self, "◆", Vector2(490, 328), Vector2(100, 50), 34, ORO)
    GameUI.label(self, I18n.t("club_sub_fmt") % Global.club_n, Vector2(40, 372), Vector2(1000, 44), 32, CIAN, false, 5)
    info = GameUI.label(self, "", Vector2(40, 424), Vector2(1000, 40), 30, Color("#ffe08a"), false, 5)

    # Lista de jugadores con desplazamiento (se ven 4 a la vez; hasta 8 con scroll)
    var scroll := ScrollContainer.new()
    scroll.position = Vector2(0, 470)
    scroll.size = Vector2(1080, 960)
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    add_child(scroll)
    var contenido := Control.new()
    contenido.custom_minimum_size = Vector2(1080, ALTO_MARCO * float(Global.club_n) + 10.0)
    scroll.add_child(contenido)
    for i in range(Global.club_n):
        _marco_jugador(contenido, i, 10.0 + float(i) * ALTO_MARCO)

    GameUI.glossy(self, "🎲  " + I18n.t("club_add_rnd"), Vector2(67, 1440), Vector2(945, 108), Color("#3aa0f0"), Color("#06244a"), _ir_retos, 44, 30)
    GameUI.glossy(self, I18n.t("club_start"), Vector2(150, 1566), Vector2(780, 104), Color("#3fd35a"), Color.WHITE, _iniciar, 48)
    _panel_personalizar()
    _contador()

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

func _estilo_campo() -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = Color(0.02, 0.06, 0.15, 0.95)
    s.border_color = Color("#2b9fe0")
    s.set_border_width_all(3)
    s.set_corner_radius_all(41)
    s.content_margin_left = 40
    s.content_margin_right = 40
    return s

func _marco_jugador(parent: Control, i: int, y: float) -> void:
    GameUI.frame(parent, Rect2(136, y, 809, 204), Color("#3d7fbf"), 3, 14, true, Color(0.02, 0.06, 0.15, 0.88))
    var aro := GameUI.circle(parent, Vector2(192, y + 54), 34, Color("#0a1a3a"), Color("#e8c26a"), 5)
    GameUI.label(aro, "👤", Vector2.ZERO, aro.size, 36)
    GameUI.left_label(parent, I18n.t("club_player_fmt") % (i + 1), Vector2(245, y + 22), Vector2(420, 64), 46, Color("#f3d9a0"), false)
    if i == 0:
        var vip := Panel.new()
        var vs := StyleBoxFlat.new()
        vs.bg_color = Color("#0d2747")
        vs.border_color = Color("#e8c26a")
        vs.set_border_width_all(3)
        vs.set_corner_radius_all(14)
        vip.add_theme_stylebox_override("panel", vs)
        vip.position = Vector2(790, y + 18)
        vip.size = Vector2(130, 66)
        vip.mouse_filter = Control.MOUSE_FILTER_IGNORE
        parent.add_child(vip)
        GameUI.label(vip, "👑 VIP", Vector2.ZERO, vip.size, 30, Color("#ffd870"))
    var e := LineEdit.new()
    e.position = Vector2(170, y + 100)
    e.size = Vector2(740, 82)
    e.placeholder_text = I18n.t("club_name")
    e.max_length = 14
    e.text = Global.club_nombres[i]
    e.add_theme_font_size_override("font_size", 40)
    e.add_theme_color_override("font_color", Color.WHITE)
    e.add_theme_color_override("font_placeholder_color", Color("#7fd4f0"))
    e.add_theme_color_override("caret_color", Color("#ffe08a"))
    var st: StyleBoxFlat = _estilo_campo()
    e.add_theme_stylebox_override("normal", st)
    var sf: StyleBoxFlat = st.duplicate() as StyleBoxFlat
    sf.border_color = Color("#ffe08a")
    e.add_theme_stylebox_override("focus", sf)
    e.text_changed.connect(_nombre_cambiado.bind(i))
    parent.add_child(e)

func _nombre_cambiado(t: String, i: int) -> void:
    Global.club_nombres[i] = t.strip_edges()
    Global.guardar_club()

func _panel_personalizar() -> void:
    var b := GameUI.flat_button(self, Vector2(67, 1696), Vector2(945, 164), Color(0.02, 0.06, 0.15, 0.92), Color("#d9b25a"), _ir_personalizar, 16, 4)
    var av := GameUI.circle(b, Vector2(120, 82), 52, Color("#0a2a4a"), Color("#5fe8ff"), 4)
    av.mouse_filter = Control.MOUSE_FILTER_IGNORE
    GameUI.label(av, "👤", Vector2.ZERO, av.size, 58)
    GameUI.left_label(b, I18n.t("club_custom_player"), Vector2(215, 16), Vector2(700, 84), 60, Color("#f3d9a0"), false)
    GameUI.left_label(b, I18n.t("club_custom_sub"), Vector2(215, 104), Vector2(710, 44), 28, Color("#8fc4f0"), false)

func _contador() -> void:
    info.text = I18n.t("club_retos_fmt") % Global.retos.size()
    info.add_theme_color_override("font_color", Color("#ffe08a"))

func _mensaje(texto: String) -> void:
    Audio.play("error")
    info.text = texto
    info.add_theme_color_override("font_color", Color("#ff8d8d"))
    await get_tree().create_timer(2.6).timeout
    if is_inside_tree():
        _contador()

func _ir_retos() -> void:
    Global.guardar_club()
    get_tree().change_scene_to_file("res://ClubRetos.tscn")

func _ir_personalizar() -> void:
    Global.guardar_club()
    get_tree().change_scene_to_file("res://Temas.tscn")

func _iniciar() -> void:
    for i in range(Global.club_n):
        if Global.club_nombres[i].strip_edges() == "":
            _mensaje("⚠  " + I18n.t("club_need_names"))
            return
    if Global.retos.is_empty():
        _mensaje("⚠  " + I18n.t("club_need_retos"))
        return
    Global.guardar_club()
    Global.club_vivos.clear()
    get_tree().change_scene_to_file("res://Ruleta.tscn")

func _volver() -> void:
    Global.salir_club()
    get_tree().change_scene_to_file("res://RetosAnonimos.tscn")
