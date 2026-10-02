extends Control
# Pantalla de bloqueo del final: se llega al superar el Difícil de la última área.
# Sin el PIN (que el jugador consigue escribiendo al correo secreto) no se pasa de aquí.
# El PIN se cambia en Global.gd (CLUB_PIN).

var entrada: LineEdit
var msg: Label

func _ready() -> void:
    var negro := ColorRect.new()
    negro.color = Color.BLACK
    negro.set_anchors_preset(Control.PRESET_FULL_RECT)
    negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(negro)
    GameUI.cubrir(negro)
    GameUI.label(self, "🔒", Vector2(0, 170), Vector2(1080, 220), 170)
    GameUI.label(self, "HAS LLEGADO AL FINAL.\nPARA ENTRAR AL CLUB SECRETO INGRESA EL PIN", Vector2(60, 440), Vector2(960, 300), 56, Color("#ffd23f"), true, 8)

    entrada = LineEdit.new()
    entrada.position = Vector2(290, 800)
    entrada.size = Vector2(500, 170)
    entrada.max_length = 4
    entrada.alignment = HORIZONTAL_ALIGNMENT_CENTER
    entrada.placeholder_text = "••••"
    entrada.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
    entrada.add_theme_font_size_override("font_size", 110)
    entrada.add_theme_color_override("font_color", Color("#ffd23f"))
    entrada.add_theme_color_override("caret_color", Color("#ffd23f"))
    entrada.add_theme_color_override("font_placeholder_color", Color(1, 1, 1, 0.25))
    for st in ["normal", "focus", "read_only"]:
        entrada.add_theme_stylebox_override(st, GameUI.flat_box(Color("#0b0b14"), Color("#ffd23f"), 40, 5))
    entrada.text_changed.connect(_filtrar)
    entrada.text_submitted.connect(func(_t: String) -> void: _desbloquear())
    add_child(entrada)

    GameUI.glossy(self, "Desbloquear", Vector2(240, 1020), Vector2(600, 130), Color("#3fd35a"), Color.WHITE, _desbloquear, 52)
    msg = GameUI.label(self, "", Vector2(60, 1180), Vector2(960, 140), 40, Color("#ff8a8a"), true, 7)
    var v := GameUI.glossy(self, "↩  Volver a la Academia", Vector2(290, 1680), Vector2(500, 100), Color("#4a3fd6"), Color.WHITE, _volver, 34, 40)
    v.focus_mode = Control.FOCUS_NONE

func _filtrar(t: String) -> void:
    var limpio := ""
    for ch in t:
        if ch >= "0" and ch <= "9":
            limpio += ch
    if limpio != t:
        entrada.text = limpio
        entrada.caret_column = limpio.length()

func _desbloquear() -> void:
    if entrada.text == Global.CLUB_PIN:
        Global.club_set_pin_ok()
        Audio.play("win")
        get_tree().change_scene_to_file("res://ClubRecompensas.tscn")
    else:
        msg.text = "PIN incorrecto, escribe al correo secreto"
        Audio.play("error")
        entrada.text = ""

func _volver() -> void:
    get_tree().change_scene_to_file("res://EducativoMenu.tscn")
