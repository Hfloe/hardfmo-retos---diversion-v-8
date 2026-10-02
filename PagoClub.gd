extends Control
# Pantalla de pago del Club Privado +18 (50k por Nequi).
# Tras pagar, el jugador escribe su WhatsApp o correo en el mensaje del pago y recibe su código de acceso.

const NEQUI_NUMERO_BASE := "300 127 2040"
const PRECIO_BASE := "$50.000"

var copy_btn: Button
var thanks_label: Label

func _numero() -> String:
    return RemoteConfig.numero_nequi(NEQUI_NUMERO_BASE)

func _precio() -> String:
    return str(RemoteConfig.cfg.get("precio_club", PRECIO_BASE))

func _ready() -> void:
    GameUI.bg(self)
    var velo := ColorRect.new()
    velo.color = Color(0, 0, 0, 0.42)
    velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(velo)
    velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    velo.offset_left = -700
    velo.offset_right = 700
    velo.offset_top = -700
    velo.offset_bottom = 700
    Donacion.marco_ornamental(self, Vector2(GameUI.W, GameUI.H))

    # Título rosa (Club Privado)
    var t := GameUI.label(self, "🔞 " + I18n.t("adult_menu_title"), Vector2(60, 120), Vector2(960, 190), 92, Color("#ff9be0"), false, 16)
    t.add_theme_color_override("font_outline_color", Color("#4a0a3a"))
    t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
    t.add_theme_constant_override("shadow_offset_y", 6)

    var p1 := GameUI.label(self, I18n.t("club_p1") % _precio(), Vector2(80, 330), Vector2(920, 150), 40, Color.WHITE, true, 8)
    p1.add_theme_color_override("font_outline_color", Color("#1a0d00"))
    var p2 := GameUI.label(self, I18n.t("club_p2"), Vector2(80, 500), Vector2(920, 230), 36, Color.WHITE, true, 8)
    p2.add_theme_color_override("font_outline_color", Color("#1a0d00"))

    # Pasos (cristal oscuro con borde rosa)
    var panel := Panel.new()
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.05, 0.02, 0.06, 0.74)
    sb.border_color = Color("#ff6fd0")
    sb.set_border_width_all(4)
    sb.set_corner_radius_all(56)
    panel.add_theme_stylebox_override("panel", sb)
    panel.position = Vector2(110, 760)
    panel.size = Vector2(860, 500)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(panel)
    var pasos: Array[String] = [I18n.t("club_s1") % _precio(), I18n.t("club_s2"), I18n.t("club_s3")]
    for i in range(pasos.size()):
        var y: float = 790.0 + float(i) * 150.0
        var chk := GameUI.circle(self, Vector2(200, y + 60), 42, Color("#ff6fd0"), Color("#ffd6f0"), 5)
        GameUI.label(chk, str(i + 1), Vector2.ZERO, chk.size, 46, Color("#4a0a3a"))
        var l := GameUI.label(self, pasos[i], Vector2(270, y), Vector2(670, 120), 34, Color.WHITE, true, 6)
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        l.add_theme_color_override("font_outline_color", Color("#0d0500"))

    # Botón pagar (verde con el ícono de Nequi)
    var b := GameUI.pill(self, I18n.t("club_pay") % _precio(), Vector2(110, 1310), Vector2(860, 150), "green", _pagar, 46)
    var ico: Texture2D = Donacion.tex("res://assets/nequi_icono.png")
    if ico != null:
        b.icon = ico
        b.expand_icon = true
        b.add_theme_constant_override("icon_max_width", 90)
        b.add_theme_constant_override("h_separation", 24)
    GameUI.pill(self, "🔑  " + I18n.t("club_have"), Vector2(110, 1490), Vector2(860, 120), "purple", _tengo_codigo, 38)
    GameUI.pill(self, I18n.t("back"), Vector2(340, 1650), Vector2(400, 110), "gold", _volver, 42)

func _pagar() -> void:
    var p := Donacion.popup(self, Vector2(900, 1120))
    var logo: Texture2D = Donacion.tex("res://assets/nequi_logo.png")
    if logo != null:
        var logo_rect := TextureRect.new()
        logo_rect.texture = logo
        logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        logo_rect.position = Vector2(230, 100)
        logo_rect.size = Vector2(440, 120)
        logo_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        p.add_child(logo_rect)
    Donacion.texto(p, I18n.t("nequi_title"), Vector2(40, 240), Vector2(820, 100), 70, Donacion.AZUL_OSC, true)
    Donacion.texto(p, I18n.t("club_value") % _precio(), Vector2(40, 350), Vector2(820, 70), 44, Color("#b0207a"), true)
    Donacion.texto(p, _numero(), Vector2(40, 430), Vector2(820, 130), 100, Donacion.AZUL_OSC, true)
    Donacion.texto(p, I18n.t("club_steps") % _precio(), Vector2(60, 580), Vector2(780, 230), 30, Color("#3c3a55"), false, true)
    thanks_label = Donacion.texto(p, "", Vector2(60, 820), Vector2(780, 100), 32, Color("#2a8f4a"), true, true)
    copy_btn = Donacion.boton(p, I18n.t("nequi_copy"), Vector2(80, 950), Vector2(360, 110), Color("#2d7dd2"), _copiar, 38)
    Donacion.boton(p, I18n.t("close"), Vector2(460, 950), Vector2(360, 110), Color("#d4a857"), GameUI.close_modal.bind(p), 38)

func _copiar() -> void:
    DisplayServer.clipboard_set(_numero().replace(" ", ""))
    Audio.play("chime")
    copy_btn.text = I18n.t("copied")
    thanks_label.text = I18n.t("club_copied")

func _tengo_codigo() -> void:
    Global.abrir_pin = true
    _volver()

func _volver() -> void:
    var destino: String = Global.volver_a if Global.volver_a != "" else "res://RetosAnonimos.tscn"
    Global.volver_a = ""
    get_tree().change_scene_to_file(destino)
