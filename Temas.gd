extends Control
# Personalización del Club Privado: cantidad de jugadores (2 a 8), fondo, estilo de carta y cómo se ve la carta
# (voltearla enseguida o raspar para descubrirla). Los 2 primeros fondos y cartas son gratis; el resto requiere Premium.

const FONDOS := ["bg_black", "bg_white", "bg_galaxy", "bg_ocean", "bg_sunset"]
const CARTAS := ["card_classic", "card_silver", "card_ruby", "card_emerald", "card_neon"]
const MIN_JUG := 2
const MAX_JUG := 8

var contador: Label

func _ready() -> void:
    Global.entrar_club()
    GameUI.bg_img(self, "res://assets/bg_club.jpg")
    GameUI.frame(self, Rect2(40, 60, 1000, 1800), Color("#3d7fbf"), 5, 60, true, Color(0.02, 0.05, 0.14, 0.82))
    GameUI.title(self, I18n.t("personalize"), 90, 66)

    # Jugadores
    _seccion(I18n.t("tm_players"), 215)
    var menos := GameUI.dot_button(self, Vector2(250, 270), 100, Color("#3a1220"), Color("#ff5a5a"), 5, _menos)
    _signo(menos, false, Color("#ff8a8a"))
    var mas := GameUI.dot_button(self, Vector2(730, 270), 100, Color("#0f3a2c"), Color("#37e0a4"), 5, _mas)
    _signo(mas, true, Color("#8dfcd0"))
    contador = GameUI.label(self, str(Global.club_n), Vector2(380, 265), Vector2(320, 110), 84, Color("#37e0a4"), false, 7)
    GameUI.label(self, I18n.t("tm_max"), Vector2(80, 380), Vector2(920, 44), 28, Color("#9fe8ff"))

    # Fondo
    _seccion(I18n.t("ap_title"), 450)
    GameUI.glossy(self, I18n.t("ap_open"), Vector2(90, 520), Vector2(900, 120), Color("#8a45f0"), Color.WHITE, _ir_apariencia, 44)
    GameUI.label(self, I18n.t("ap_hint"), Vector2(80, 650), Vector2(920, 50), 26, Color("#9fe8ff"))
    # Cartas
    _seccion(I18n.t("cards"), 715)
    for i in range(5):
        _crear_carta(i)
    # Cómo se ve la carta
    _seccion(I18n.t("tm_mode_title"), 1000)
    _boton_modo(0, I18n.t("tm_flip"), I18n.t("tm_flip_hint"), Vector2(90, 1070))
    _boton_modo(1, I18n.t("tm_scratch"), I18n.t("tm_scratch_hint"), Vector2(550, 1070))

    _estado_premium()
    GameUI.glossy(self, "↩  " + I18n.t("back"), Vector2(250, 1690), Vector2(580, 110), Color("#ffc933"), GameUI.DARK_TEXT, _volver, 44)

func _seccion(texto: String, y: float) -> void:
    GameUI.label(self, texto, Vector2(80, y), Vector2(920, 56), 40, Color("#ffe0a0"), false, 6)

func _signo(boton: Button, con_mas: bool, color: Color) -> void:
    var c: Vector2 = boton.size / 2.0
    var h := ColorRect.new()
    h.color = color
    h.size = Vector2(46, 10)
    h.position = c - h.size / 2.0
    h.mouse_filter = Control.MOUSE_FILTER_IGNORE
    boton.add_child(h)
    if con_mas:
        var v := ColorRect.new()
        v.color = color
        v.size = Vector2(10, 46)
        v.position = c - v.size / 2.0
        v.mouse_filter = Control.MOUSE_FILTER_IGNORE
        boton.add_child(v)

func _menos() -> void:
    Global.club_n = clampi(Global.club_n - 1, MIN_JUG, MAX_JUG)
    Global.guardar_club()
    contador.text = str(Global.club_n)

func _mas() -> void:
    Global.club_n = clampi(Global.club_n + 1, MIN_JUG, MAX_JUG)
    Global.guardar_club()
    contador.text = str(Global.club_n)

func _boton_modo(modo: int, titulo: String, sub: String, pos: Vector2) -> void:
    var activo: bool = Global.carta_modo == modo
    var base: Color = Color("#3fd35a") if activo else Color("#27446f")
    var b := GameUI.glossy(self, "", pos, Vector2(440, 170), base, Color.WHITE, _elegir_modo.bind(modo), 40, 40, false)
    GameUI.label(b, ("✓  " if activo else "") + titulo, Vector2(0, 22), Vector2(440, 70), 52, Color.WHITE, false, 6)
    GameUI.label(b, sub, Vector2(0, 98), Vector2(440, 50), 30, Color("#fff6d6") if activo else Color("#b9c8e6"))

func _elegir_modo(modo: int) -> void:
    Global.carta_modo = modo
    Global.guardar_club()
    get_tree().reload_current_scene()

func _crear_fondo(i: int) -> void:
    var info: Array = GameUI.fondo_info(i)
    var top: Color = info[0]
    var bottom: Color = info[1]
    var libre: bool = Global.desbloqueado(i)
    var x: float = 82.0 + float(i) * 180.0
    var seleccionado: bool = Global.fondo_efectivo() == i
    var b := _muestra(Vector2(x, 515.0), Vector2(150, 150), top.lerp(bottom, 0.5), Color("#5a3fb0"), seleccionado, libre, _elegir_fondo.bind(i))
    var mini: Texture2D = GameUI._imagen_fondo(i)
    if mini != null:
        var pic := TextureRect.new()
        pic.texture = mini
        pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
        pic.position = Vector2(8, 8)
        pic.size = b.size - Vector2(16, 16)
        b.add_child(pic)
    if not libre:
        b.text = "🔒"
    GameUI.label(self, I18n.t(FONDOS[i]), Vector2(x - 12, 668), Vector2(174, 40), 26, Color("#d6e6ff"), false, 4)

func _crear_carta(i: int) -> void:
    var info: Array = GameUI.carta_info(i)
    var relleno: Color = info[0]
    var borde: Color = info[1]
    var simbolo: Color = info[2]
    var libre: bool = Global.desbloqueado(i)
    var x: float = 82.0 + float(i) * 180.0
    var seleccionado: bool = Global.carta_efectiva() == i
    var b := _muestra(Vector2(x + 15.0, 780.0), Vector2(120, 170), relleno, borde, seleccionado, libre, _elegir_carta.bind(i))
    for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
        b.add_theme_color_override(c, simbolo)
    b.text = "✦" if libre else "🔒"
    GameUI.label(self, I18n.t(CARTAS[i]), Vector2(x - 12, 952), Vector2(174, 40), 26, Color("#d6e6ff"), false, 4)

func _muestra(pos: Vector2, sz: Vector2, fill: Color, borde: Color, seleccionado: bool, libre: bool, callback: Callable) -> Button:
    var b := Button.new()
    b.position = pos
    b.size = sz
    b.focus_mode = Control.FOCUS_NONE
    b.add_theme_font_size_override("font_size", 52)
    var s := StyleBoxFlat.new()
    s.bg_color = fill
    s.border_color = Color("#ffe08a") if seleccionado else borde
    s.set_border_width_all(9 if seleccionado else 4)
    s.set_corner_radius_all(28)
    if seleccionado:
        s.shadow_color = Color(1, 0.88, 0.5, 0.6)
        s.shadow_size = 18
    for st in ["normal", "hover", "pressed", "disabled"]:
        b.add_theme_stylebox_override(st, s)
    b.pressed.connect(callback)
    if not libre:
        b.modulate = Color(1, 1, 1, 0.6)
    add_child(b)
    return b

func _estado_premium() -> void:
    if Global.GRATIS >= 5:
        return
    if Global.premium:
        var dias: int = maxi(1, int(ceil(float(Global.expira - int(Time.get_unix_time_from_system())) / 86400.0)))
        GameUI.label(self, "★  " + I18n.t("premium_days_fmt") % dias, Vector2(80, 1280), Vector2(920, 80), 34, Color("#8dfcae"), true, 6)
    else:
        GameUI.label(self, I18n.t("themes_hint"), Vector2(80, 1270), Vector2(920, 100), 32, Color("#ffe9a3"), true, 6)
        GameUI.pill(self, I18n.t("get_premium"), Vector2(190, 1400), Vector2(700, 130), "green", _ir_premium, 44, true)

func _elegir_fondo(i: int) -> void:
    if not Global.desbloqueado(i):
        _ir_premium()
        return
    Global.fondo = i
    Global.guardar_club()
    get_tree().reload_current_scene()

func _elegir_carta(i: int) -> void:
    if not Global.desbloqueado(i):
        _ir_premium()
        return
    Global.carta_estilo = i
    Global.guardar_club()
    get_tree().reload_current_scene()

func _ir_premium() -> void:
    get_tree().change_scene_to_file("res://Paywall.tscn")

func _volver() -> void:
    get_tree().change_scene_to_file("res://ClubPrivado.tscn")

func _ir_apariencia() -> void:
    Global.apariencia_volver = "res://Temas.tscn"
    get_tree().change_scene_to_file("res://Apariencia.tscn")
