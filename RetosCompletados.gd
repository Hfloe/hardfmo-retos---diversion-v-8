extends Control

func _ready() -> void:
    GameUI.bg(self, Color("#0c1a4d"), Color("#122a72"))
    GameUI.frame(self, Rect2(10, 10, 1060, 1900), Color("#ff8a2b"), 26, 80, false)
    GameUI.label(self, "🏆", Vector2(90, 90), Vector2(240, 200), 150)
    GameUI.label(self, I18n.t("done_title"), Vector2(330, 90), Vector2(660, 200), 70, Color.WHITE, true)
    var total: int = Global.retos.size()
    GameUI.frame(self, Rect2(110, 340, 860, 240), Color("#2fa86a"), 4, 50, false, Color("#132a66"))
    GameUI.label(self, I18n.t("done_msg_fmt") % total, Vector2(130, 360), Vector2(820, 90), 36, Color.WHITE, true)
    GameUI.pill(self, "✓  " + I18n.t("saved_fmt") % [total, Global.MAX_RETOS], Vector2(170, 470), Vector2(740, 90), "green", _noop, 36)

    var scroll := ScrollContainer.new()
    scroll.position = Vector2(110, 620)
    scroll.size = Vector2(860, 990)
    add_child(scroll)
    var box := VBoxContainer.new()
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    box.add_theme_constant_override("separation", 18)
    scroll.add_child(box)
    for i in range(total):
        box.add_child(_row(i))
    GameUI.pill(self, I18n.t("save_menu") + "  ›", Vector2(90, 1690), Vector2(900, 140), "green", _menu, 42)

func _row(i: int) -> Control:
    var row := Panel.new()
    row.custom_minimum_size = Vector2(840, 110)
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var s := StyleBoxFlat.new()
    s.bg_color = Color("#173579")
    s.border_color = Color("#2fa86a")
    s.set_border_width_all(3)
    s.set_corner_radius_all(55)
    row.add_theme_stylebox_override("panel", s)
    var dot := GameUI.circle(row, Vector2(70, 55), 36, Color("#34c760"), Color("#8dfcae"), 3)
    GameUI.label(dot, "✓", Vector2.ZERO, dot.size, 44)
    var l := GameUI.label(row, I18n.t("challenge_row_fmt") % (i + 1), Vector2(130, 0), Vector2(690, 110), 36)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    return row

func _noop() -> void:
    pass

func _menu() -> void:
    get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
