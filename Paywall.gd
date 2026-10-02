extends Control
# Pantalla "Apoya el juego": donación voluntaria por Nequi.

# Opción A: enlace de pago (Nequi Negocios / Wompi). Si lo pones, el botón abre ese enlace.
const NEQUI_URL_BASE := ""
# Opción B: si NEQUI_URL está vacío, se muestra este número en el popup.
const NEQUI_NUMERO_BASE := "300 127 2040"
# true = muestra un botón para simular el pago y probar los desbloqueos. Déjalo en false al publicar.
const MODO_PRUEBA := false

var NEQUI_URL: String:
    get:
        return RemoteConfig.url_nequi(NEQUI_URL_BASE)
var NEQUI_NUMERO: String:
    get:
        return RemoteConfig.numero_nequi(NEQUI_NUMERO_BASE)

var copy_btn: Button
var thanks_label: Label

func _ready() -> void:
    GameUI.bg(self)
    var velo := ColorRect.new()
    velo.color = Color(0, 0, 0, 0.35)
    velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(velo)
    velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    velo.offset_left = -700
    velo.offset_right = 700
    velo.offset_top = -700
    velo.offset_bottom = 700
    Donacion.marco_ornamental(self, Vector2(GameUI.W, GameUI.H))

    # Título dorado: "IMPULSA EL FUTURO DE HARDFMO-RETOS & DIVERSIÓN"
    var t := GameUI.label(self, I18n.t("don_title"), Vector2(50, 100), Vector2(980, 200), 58, Color("#ffd867"), true, 14)
    t.add_theme_color_override("font_outline_color", Color("#5a3600"))
    t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
    t.add_theme_constant_override("shadow_offset_y", 6)

    # Texto explicativo
    var p1 := GameUI.label(self, I18n.t("don_p1"), Vector2(80, 320), Vector2(920, 250), 36, Color.WHITE, true, 8)
    p1.add_theme_color_override("font_outline_color", Color("#1a0d00"))

    # ¿En qué se utilizará el apoyo?
    var q := GameUI.label(self, I18n.t("don_q"), Vector2(80, 585), Vector2(920, 70), 44, Color("#ffd867"), false, 8)
    q.add_theme_color_override("font_outline_color", Color("#1a0d00"))

    # Panel de usos (cristal oscuro con borde dorado)
    var panel := Panel.new()
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.03, 0.02, 0.02, 0.72)
    sb.border_color = Color("#e8b94a")
    sb.set_border_width_all(4)
    sb.set_corner_radius_all(56)
    panel.add_theme_stylebox_override("panel", sb)
    panel.position = Vector2(110, 665)
    panel.size = Vector2(860, 480)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(panel)
    var items: Array[String] = [I18n.t("don_i1"), I18n.t("don_i2"), I18n.t("don_i3"), I18n.t("don_i4")]
    for i in range(items.size()):
        var y: float = 695.0 + float(i) * 110.0
        var chk := GameUI.circle(self, Vector2(190, y + 50), 36, Color("#e8b94a"), Color("#fff0a8"), 5)
        GameUI.label(chk, "✓", Vector2.ZERO, chk.size, 42, Color("#5a3600"))
        var l := GameUI.label(self, items[i], Vector2(250, y), Vector2(690, 100), 36, Color.WHITE, true, 6)
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        l.add_theme_color_override("font_outline_color", Color("#0d0500"))

    # Cierre
    var c1 := GameUI.label(self, I18n.t("don_cta"), Vector2(80, 1165), Vector2(920, 130), 40, Color("#ffd867"), true, 8)
    c1.add_theme_color_override("font_outline_color", Color("#1a0d00"))
    var c2 := GameUI.label(self, I18n.t("don_cta2"), Vector2(80, 1300), Vector2(920, 100), 34, Color.WHITE, true, 8)
    c2.add_theme_color_override("font_outline_color", Color("#1a0d00"))

    # Botón donar (verde con el ícono de Nequi)
    var b := GameUI.pill(self, I18n.t("pay"), Vector2(140, 1430), Vector2(800, 150), "green", _pay, 52)
    var ico: Texture2D = Donacion.tex("res://assets/nequi_icono.png")
    if ico != null:
        b.icon = ico
        b.expand_icon = true
        b.add_theme_constant_override("icon_max_width", 90)
        b.add_theme_constant_override("h_separation", 24)
    GameUI.pill(self, I18n.t("back"), Vector2(340, 1650), Vector2(400, 120), "gold", _volver, 44)

func _pay() -> void:
    if NEQUI_URL.begins_with("http"):
        OS.shell_open(NEQUI_URL)
        return
    _mostrar_popup()

func _mostrar_popup() -> void:
    var p := Donacion.popup(self, Vector2(900, 1080))
    var logo: Texture2D = Donacion.tex("res://assets/nequi_logo.png")
    if logo != null:
        var tr := TextureRect.new()
        tr.texture = logo
        tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        tr.position = Vector2(230, 100)
        tr.size = Vector2(440, 120)
        tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
        p.add_child(tr)
    Donacion.texto(p, I18n.t("pay_title"), Vector2(40, 250), Vector2(820, 110), 76, Donacion.AZUL_OSC, true)
    Donacion.texto(p, I18n.t("donate_sub"), Vector2(40, 370), Vector2(820, 60), 34, Donacion.AZUL_OSC)
    Donacion.texto(p, NEQUI_NUMERO, Vector2(40, 450), Vector2(820, 130), 100, Donacion.AZUL_OSC, true)
    Donacion.texto(p, I18n.t("pay_steps"), Vector2(70, 610), Vector2(760, 130), 32, Color("#3c3a55"), false, true)
    thanks_label = Donacion.texto(p, "", Vector2(70, 750), Vector2(760, 70), 40, Color("#2a8f4a"), true)
    copy_btn = Donacion.boton(p, I18n.t("pay_copy"), Vector2(80, 870), Vector2(360, 110), Color("#2d7dd2"), _copiar, 38)
    Donacion.boton(p, I18n.t("close"), Vector2(460, 870), Vector2(360, 110), Color("#d4a857"), _cerrar_modal.bind(p), 38)
    if MODO_PRUEBA:
        GameUI.pill(p, I18n.t("pay_test"), Vector2(250, 990), Vector2(400, 70), "pink", _payment_verified, 28)

func _copiar() -> void:
    DisplayServer.clipboard_set(NEQUI_NUMERO.replace(" ", ""))
    Audio.play("chime")
    copy_btn.text = I18n.t("copied")
    thanks_label.text = I18n.t("thanks")

func _cerrar_modal(panel: Control) -> void:
    GameUI.close_modal(panel)

func _volver() -> void:
    var destino: String = Global.volver_a if Global.volver_a != "" else "res://Ruleta.tscn"
    Global.volver_a = ""
    get_tree().change_scene_to_file(destino)

# IMPORTANTE: en producción esto debe llamarse SOLO cuando tu servidor confirme el pago (más adelante).
func _payment_verified() -> void:
    Global._check = 7429
    Global.expira = int(Time.get_unix_time_from_system()) + 15 * 24 * 60 * 60
    Global.tiradas_usadas = 0
    Global.premium_verificado_servidor = true
    Global.guardar_datos()
    get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
