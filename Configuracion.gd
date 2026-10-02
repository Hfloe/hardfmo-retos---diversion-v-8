extends Control

var feedback_btn: Button

func _ready() -> void:
    GameUI.bg(self)
    GameUI.frame(self, Rect2(68, 90, 944, 1740), Color("#9b6bff"), 12, 76)
    GameUI.title(self, I18n.t("settings"), 150, 64)
    GameUI.label(self, I18n.t("language"), Vector2(90, 300), Vector2(900, 70), 34, Color("#d6c7ff"))
    var es_kind := "gold" if Global.idioma == "es" else "purple"
    var en_kind := "gold" if Global.idioma == "en" else "purple"
    GameUI.pill(self, "Español", Vector2(190, 390), Vector2(700, 130), es_kind, _set_lang.bind("es"), 42, false, -1, Color(0, 0, 0, 0), false)
    GameUI.pill(self, "English", Vector2(190, 550), Vector2(700, 130), en_kind, _set_lang.bind("en"), 42, false, -1, Color(0, 0, 0, 0), false)
    var estado: String = I18n.t("on") if Global.sonido else I18n.t("off")
    GameUI.pill(self, I18n.t("audio") + ": " + estado, Vector2(190, 780), Vector2(700, 130), "blue", _toggle_audio, 42)
    GameUI.pill(self, I18n.t("reset"), Vector2(190, 950), Vector2(700, 130), "red", _reset, 42)
    GameUI.pill(self, I18n.t("terms_btn"), Vector2(190, 1120), Vector2(700, 130), "dark", _ver_terminos, 40)
    GameUI.pill(self, I18n.t("ap_open"), Vector2(190, 1290), Vector2(700, 130), "purple", _ir_apariencia, 42)
    feedback_btn = GameUI.pill(self, I18n.t("feedback_btn"), Vector2(190, 1450), Vector2(700, 120), "blue", _enviar_opiniones, 40)
    GameUI.pill(self, I18n.t("back"), Vector2(330, 1600), Vector2(420, 120), "yellow", _volver, 40)

func _set_lang(code: String) -> void:
    I18n.set_language(code)
    get_tree().reload_current_scene()

func _toggle_audio() -> void:
    Global.sonido = not Global.sonido
    Global.guardar_datos()
    Audio.actualizar_musica()
    get_tree().reload_current_scene()

func _reset() -> void:
    Global.reset_game()
    get_tree().change_scene_to_file("res://MenuPrincipal.tscn")

func _volver() -> void:
    get_tree().change_scene_to_file("res://MenuPrincipal.tscn")

func _ver_terminos() -> void:
    get_tree().change_scene_to_file("res://Terminos.tscn")

func _ir_apariencia() -> void:
    Global.apariencia_volver = "res://Configuracion.tscn"
    get_tree().change_scene_to_file("res://Apariencia.tscn")

func _enviar_opiniones() -> void:
    # Copia el correo (por si el teléfono no tiene app de correo) y abre el correo con el asunto listo.
    DisplayServer.clipboard_set(Global.CORREO_OPINIONES)
    Audio.play("chime")
    if feedback_btn:
        feedback_btn.text = I18n.t("feedback_copied")
    OS.shell_open("mailto:" + Global.CORREO_OPINIONES + "?subject=" + I18n.t("feedback_subject").uri_encode())
