extends Control
# Pantalla "Jugar en línea": crear una sala o unirse con un código.

var nombre_in: LineEdit
var codigo_in: LineEdit
var estado_lbl: Label
var color_sel: int = 0
var dots_box: Control
var ocupado: bool = false

func _ready() -> void:
    if not Online.DISPONIBLE:
        _volver.call_deferred()
        return
    GameUI.bg(self)
    GameUI.frame(self, Rect2(56, 70, 968, 1790), Color("#9b6bff"), 12, 90)
    GameUI.pill(self, "‹  " + I18n.t("back"), Vector2(110, 120), Vector2(300, 100), "yellow", _volver, 38)
    GameUI.title(self, "🌐 " + I18n.t("on_title"), 300, 64)
    color_sel = Online.mi_color
    GameUI.label(self, I18n.t("on_name"), Vector2(100, 400), Vector2(880, 60), 36, Color("#ffe08a"), false, 6)
    nombre_in = OnlineUI.input(self, Vector2(100, 470), Vector2(880, 120), I18n.t("on_name"), 42, 14)
    nombre_in.text = Online.mi_nombre
    GameUI.label(self, I18n.t("on_color"), Vector2(100, 630), Vector2(880, 60), 34, Color("#d6c7ff"), false, 6)
    _dibujar_colores()
    GameUI.pill(self, I18n.t("on_create"), Vector2(140, 950), Vector2(800, 140), "green", _crear, 48, true)
    GameUI.label(self, "— " + I18n.t("on_or") + " —", Vector2(100, 1110), Vector2(880, 60), 34, Color("#b79bff"))
    codigo_in = OnlineUI.input(self, Vector2(290, 1190), Vector2(500, 130), "ABCD", 72, 4)
    codigo_in.alignment = HORIZONTAL_ALIGNMENT_CENTER
    codigo_in.text_changed.connect(_codigo_cambio)
    GameUI.pill(self, I18n.t("on_join"), Vector2(140, 1370), Vector2(800, 140), "blue", _unirse, 48)
    estado_lbl = GameUI.label(self, "", Vector2(100, 1550), Vector2(880, 200), 34, Color("#ffb3b3"), true, 6)
    if not Online.configurado():
        estado_lbl.text = I18n.t("on_err_config")

func _dibujar_colores() -> void:
    if dots_box != null:
        dots_box.queue_free()
    dots_box = OnlineUI.selector_color(self, Vector2(100, 710), color_sel, _elegir_color)

func _elegir_color(c: int) -> void:
    color_sel = c
    _dibujar_colores()

func _codigo_cambio(t: String) -> void:
    var up: String = t.to_upper()
    if up != t:
        codigo_in.text = up
        codigo_in.caret_column = up.length()

func _nombre() -> String:
    var n: String = nombre_in.text.strip_edges()
    return n if n != "" else "Jugador"

func _crear() -> void:
    if ocupado:
        return
    ocupado = true
    estado_lbl.text = "…"
    var err: String = await Online.crear_sala(_nombre(), color_sel)
    ocupado = false
    if not is_inside_tree():
        return
    if err == "":
        get_tree().change_scene_to_file("res://OnlineSala.tscn")
    else:
        estado_lbl.text = OnlineUI.mensaje_error(err)
        Audio.play("error")

func _unirse() -> void:
    if ocupado:
        return
    if codigo_in.text.strip_edges().length() < 4:
        estado_lbl.text = I18n.t("on_err_none")
        Audio.play("error")
        return
    ocupado = true
    estado_lbl.text = "…"
    var err: String = await Online.unirse(codigo_in.text, _nombre(), color_sel)
    ocupado = false
    if not is_inside_tree():
        return
    if err == "":
        get_tree().change_scene_to_file("res://OnlineSala.tscn")
    else:
        estado_lbl.text = OnlineUI.mensaje_error(err)
        Audio.play("error")

func _volver() -> void:
    get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
