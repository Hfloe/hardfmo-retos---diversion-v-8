extends Control
# Personalización de la apariencia: fondo (6 opciones + el original de cada pantalla) y color de los botones.
# Se aplica a todas las pantallas MENOS el menú principal. Se guarda en user://progreso.cfg ([tema]).
# Los fondos están en res://fondos/tema_1.jpg ... tema_6.jpg (1080x1920). El logo: res://assets/logo_hardfmo.png.

const FONDOS := ["ap_f1", "ap_f2", "ap_f3", "ap_f4", "ap_f5", "ap_f6"]
const ORO := Color("#ffe08a")

func _ready() -> void:
    GameUI.bg(self)   # ya muestra el fondo elegido
    GameUI.title(self, I18n.t("ap_title"), 190, 62)
    GameUI.label(self, I18n.t("ap_hint"), Vector2(60, 330), Vector2(960, 44), 27, Color("#d6e6ff"), false, 5)

    # ----- Fondo: "Original" + 6 -----
    GameUI.label(self, I18n.t("ap_bg"), Vector2(60, 440), Vector2(960, 56), 40, ORO, false, 6)
    _tile_fondo(-1, 0)
    for i in range(Global.TEMA_NFONDOS):
        _tile_fondo(i, i + 1)

    # ----- Color de botones: "Original" + 8 -----
    GameUI.label(self, I18n.t("ap_btn"), Vector2(60, 1160), Vector2(960, 56), 40, ORO, false, 6)
    _punto_color(-1, 0)
    for i in range(GameUI.TEMA_BOTONES.size()):
        _punto_color(i, i + 1)

    # ----- Cartas: cómo se ve el reto (raspa y gana o enseguida) -----
    GameUI.label(self, I18n.t("tm_mode_title"), Vector2(60, 1505), Vector2(960, 56), 40, ORO, false, 6)
    var raspa: bool = Global.carta_raspa_normal()
    _boton_modo(false, I18n.t("ap_card_flip"), not raspa, Vector2(60, 1572))
    _boton_modo(true, I18n.t("ap_card_scratch"), raspa, Vector2(550, 1572))
    GameUI.glossy(self, "↩  " + I18n.t("back"), Vector2(250, 1700), Vector2(580, 110), Color("#ffc933"), GameUI.DARK_TEXT, _volver, 44)

func _boton_modo(es_raspa: bool, titulo: String, activo: bool, pos: Vector2) -> void:
    var base: Color = Color("#3fd35a") if activo else Color("#27446f")
    GameUI.glossy(self, ("✓  " if activo else "") + titulo, pos, Vector2(470, 105), base, Color.WHITE, _elegir_modo.bind(es_raspa), 34, 40, false)

func _elegir_modo(es_raspa: bool) -> void:
    Global.guardar_carta_raspa_normal(es_raspa)
    get_tree().reload_current_scene()

# Cuadrícula de 4 columnas: posición k = 0..6
func _tile_fondo(idx: int, k: int) -> void:
    var col: int = k % 4
    @warning_ignore("integer_division")
    var fila: int = k / 4
    var x: float = 55.0 + float(col) * 250.0
    var y: float = 510.0 + float(fila) * 320.0
    var sel: bool = Global.tema_fondo == idx
    var b := Button.new()
    b.position = Vector2(x, y)
    b.size = Vector2(220, 260)
    b.focus_mode = Control.FOCUS_NONE
    var s := GameUI.flat_box(Color("#15112c"), ORO if sel else Color("#5a3fb0"), 28, 9 if sel else 4)
    if sel:
        s.shadow_color = Color(1, 0.88, 0.5, 0.6)
        s.shadow_size = 16
    for st in ["normal", "hover", "pressed", "disabled"]:
        b.add_theme_stylebox_override(st, s)
    b.pressed.connect(_elegir_fondo.bind(idx))
    add_child(b)
    var ruta: String = "res://fondos/tema_%d.jpg" % (idx + 1)
    if idx >= 0 and ResourceLoader.exists(ruta):
        var pic := TextureRect.new()
        pic.texture = load(ruta) as Texture2D
        pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
        pic.position = Vector2(10, 10)
        pic.size = Vector2(200, 240)
        b.add_child(pic)
    else:
        GameUI.label(b, "↺", Vector2(0, 70), Vector2(220, 120), 100, Color("#d6e6ff"))
    var nombre: String = I18n.t("ap_original") if idx < 0 else I18n.t(FONDOS[idx])
    GameUI.label(self, ("✓ " if sel else "") + nombre, Vector2(x - 15.0, y + 264.0), Vector2(250, 40), 28, ORO if sel else Color("#d6e6ff"), false, 4)

func _punto_color(idx: int, k: int) -> void:
    var col: int = k % 5
    @warning_ignore("integer_division")
    var fila: int = k / 5
    var d: float = 120.0
    var x: float = 75.0 + float(col) * 190.0
    var y: float = 1235.0 + float(fila) * 150.0
    var sel: bool = Global.tema_boton == idx
    var relleno: Color = Color("#15112c") if idx < 0 else GameUI.TEMA_BOTONES[idx]
    var b := GameUI.dot_button(self, Vector2(x, y), d, relleno, ORO if sel else Color(1, 1, 1, 0.55), 10 if sel else 4, _elegir_boton.bind(idx))
    if idx < 0:
        GameUI.label(b, I18n.t("ap_original"), Vector2(0, 0), Vector2(d, d), 22, Color.WHITE)
    elif sel:
        var t: Color = GameUI.DARK_TEXT if relleno.get_luminance() > 0.55 else Color.WHITE
        GameUI.label(b, "✓", Vector2(0, 0), Vector2(d, d), 64, t)

func _elegir_fondo(idx: int) -> void:
    Global.tema_fondo = idx
    Global.guardar_tema()
    get_tree().reload_current_scene()

func _elegir_boton(idx: int) -> void:
    Global.tema_boton = idx
    Global.guardar_tema()
    get_tree().reload_current_scene()

func _volver() -> void:
    get_tree().change_scene_to_file(Global.apariencia_volver)
