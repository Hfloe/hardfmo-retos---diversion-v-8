extends Control
# Términos y condiciones. La primera vez es obligatorio aceptarlos; después se pueden releer desde Configuración.

func _ready() -> void:
    GameUI.bg(self)
    GameUI.frame(self, Rect2(56, 70, 968, 1790), Color("#9b6bff"), 12, 90)
    GameUI.label3d(self, I18n.t("terms_title"), Vector2(60, 120), Vector2(960, 120), 54, Color("#ffd84a"), Color("#a86400"), 9, Color("#5a2d00"))

    GameUI.frame(self, Rect2(90, 270, 900, 1080), Color("#7a4be0"), 4, 40, false, Color(0.05, 0.03, 0.15, 0.9))
    var scroll := ScrollContainer.new()
    scroll.position = Vector2(110, 290)
    scroll.size = Vector2(860, 1040)
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    add_child(scroll)
    var texto := Label.new()
    texto.text = I18n.t("terms_body")
    texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    texto.custom_minimum_size = Vector2(830, 0)
    texto.add_theme_font_size_override("font_size", 32)
    texto.add_theme_color_override("font_color", Color("#e9e2ff"))
    scroll.add_child(texto)

    if Global.terminos_aceptados:
        GameUI.pill(self, I18n.t("back"), Vector2(330, 1560), Vector2(420, 120), "yellow", _volver, 40)
    else:
        GameUI.label(self, I18n.t("terms_must"), Vector2(90, 1380), Vector2(900, 120), 30, Color("#ffe08a"), true, 6)
        GameUI.pill(self, I18n.t("terms_decline"), Vector2(90, 1560), Vector2(420, 130), "red", _rechazar, 40)
        GameUI.pill(self, I18n.t("terms_accept"), Vector2(570, 1560), Vector2(420, 130), "green", _aceptar, 44)

func _aceptar() -> void:
    Global.terminos_aceptados = true
    Global.guardar_datos()
    get_tree().change_scene_to_file("res://MenuPrincipal.tscn")

func _rechazar() -> void:
    get_tree().quit()

func _volver() -> void:
    get_tree().change_scene_to_file("res://Configuracion.tscn")
