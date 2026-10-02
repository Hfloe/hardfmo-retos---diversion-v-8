extends Control
# Se llega aquí al acertar las 20 preguntas de un nivel.

func _ready() -> void:
    var id: String = Global.categoria_actual
    if Global.edu_es_final(id, Global.nivel_actual):
        # último nivel de la última área: ya no se avanza directo, hay que pasar por el PIN del club
        get_tree().change_scene_to_file.call_deferred(Global.escena_final())
        return
    EduFondo.aplicar(self, id)
    var panel := Panel.new()
    panel.position = Vector2(80, 300)
    panel.size = Vector2(920, 1300)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_theme_stylebox_override("panel", GameUI.flat_box(Color(0.10, 0.20, 0.40, 0.86), Color("#ffd23f"), 50, 6))
    add_child(panel)
    Audio.play("win")
    GameUI.label(self, "🏆", Vector2(80, 340), Vector2(920, 240), 190)
    GameUI.label3d(self, I18n.t("qz_won_title"), Vector2(80, 600), Vector2(920, 130), 88, Color("#c8f03a"), Color("#5c8a12"), 9, Color("#173a08"))
    var nombre: String = I18n.t(str(Global.EDU_NOMBRE.get(id, "edu_title")))
    var nivel: String = I18n.t(["lvl_easy", "lvl_mid", "lvl_hard"][clampi(Global.nivel_actual - 1, 0, 2)])
    GameUI.label(self, "%s · %s" % [nombre, nivel], Vector2(100, 750), Vector2(880, 70), 42, Color("#9fe8ff"), false, 6)
    if not Global.edu_primera_vez:
        GameUI.label(self, I18n.t("qz_won_again"), Vector2(120, 840), Vector2(840, 150), 44, Color.WHITE, true, 7)
    var ultimo: bool = Global.nivel_actual >= Global.EDU_NIVELES.size()
    if ultimo:
        GameUI.label(self, I18n.t("qz_all_done"), Vector2(120, 1000), Vector2(840, 170), 36, Color("#ffe08a"), true, 6)
    else:
        GameUI.glossy(self, I18n.t("qz_next"), Vector2(190, 1050), Vector2(700, 130), Color("#3fd35a"), Color.WHITE, _siguiente, 46)
    GameUI.glossy(self, I18n.t("qz_back_levels"), Vector2(190, 1230), Vector2(700, 120), Color("#4a3fd6"), Color.WHITE, _niveles, 42)
    GameUI.glossy(self, I18n.t("edu_to_areas"), Vector2(190, 1390), Vector2(700, 120), Color("#ffc933"), GameUI.DARK_TEXT, _areas, 42)

func _siguiente() -> void:
    Global.nivel_actual += 1
    get_tree().change_scene_to_file(Global.escena_nivel(Global.categoria_actual))

func _niveles() -> void:
    get_tree().change_scene_to_file("res://EducativoNiveles.tscn")

func _areas() -> void:
    get_tree().change_scene_to_file("res://EducativoMenu.tscn")
