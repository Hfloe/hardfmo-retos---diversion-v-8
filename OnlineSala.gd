extends Control
# Sala de espera: código para compartir, jugadores conectados y desafíos de cada uno.

var lista_box: VBoxContainer
var retos_box: VBoxContainer
var retos_lbl: Label
var input: LineEdit
var hint_lbl: Label
var start_btn: Button
var _firma_jug: String = ""
var _firma_retos: String = ""
var _yendo: bool = false

func _ready() -> void:
    if not Online.activo:
        _volver.call_deferred()
        return
    GameUI.bg(self)
    GameUI.frame(self, Rect2(56, 70, 968, 1790), Color("#9b6bff"), 12, 90)
    GameUI.title(self, I18n.t("on_room"), 110, 56)
    var cod := GameUI.label(self, Online.codigo, Vector2(100, 190), Vector2(880, 150), 130, Color("#ffd867"), false, 14)
    cod.add_theme_color_override("font_outline_color", Color("#5a3600"))
    GameUI.label(self, I18n.t("on_share_txt"), Vector2(100, 345), Vector2(880, 50), 30, Color("#d6c7ff"))
    GameUI.pill(self, "📤  " + I18n.t("on_share"), Vector2(100, 410), Vector2(430, 100), "green", _compartir, 36)
    GameUI.pill(self, "📋  " + I18n.t("on_copy"), Vector2(550, 410), Vector2(430, 100), "blue", _copiar, 34)

    GameUI.label(self, "👥  " + I18n.t("on_players"), Vector2(100, 535), Vector2(880, 50), 34, Color("#b79bff"))
    var sc := ScrollContainer.new()
    sc.position = Vector2(100, 590)
    sc.size = Vector2(880, 330)
    add_child(sc)
    lista_box = VBoxContainer.new()
    lista_box.custom_minimum_size = Vector2(860, 0)
    lista_box.add_theme_constant_override("separation", 10)
    sc.add_child(lista_box)

    retos_lbl = GameUI.label(self, "", Vector2(100, 940), Vector2(880, 50), 34, Color("#ffe08a"))
    input = OnlineUI.input(self, Vector2(100, 1000), Vector2(600, 110), I18n.t("on_ph"), 30, 90)
    GameUI.pill(self, I18n.t("on_add"), Vector2(720, 1000), Vector2(260, 110), "gold", _agregar, 38)
    var sc2 := ScrollContainer.new()
    sc2.position = Vector2(100, 1130)
    sc2.size = Vector2(880, 290)
    add_child(sc2)
    retos_box = VBoxContainer.new()
    retos_box.custom_minimum_size = Vector2(860, 0)
    retos_box.add_theme_constant_override("separation", 8)
    sc2.add_child(retos_box)

    hint_lbl = GameUI.label(self, "", Vector2(100, 1440), Vector2(880, 90), 30, Color("#ffb3b3"), true, 5)
    if Online.soy_host:
        start_btn = GameUI.pill(self, I18n.t("on_start"), Vector2(140, 1540), Vector2(800, 140), "green", _iniciar, 50, true)
    else:
        GameUI.label(self, I18n.t("on_wait_start"), Vector2(100, 1560), Vector2(880, 100), 34, Color("#ffe08a"), true, 6)
    GameUI.pill(self, I18n.t("exit"), Vector2(340, 1710), Vector2(400, 100), "yellow", _salir, 38)

    Online.sala_actualizada.connect(_refrescar)
    Online.sala_cerrada.connect(_cerrada)
    Online.error_red.connect(_sin_red)
    _refrescar()

func _refrescar() -> void:
    if _yendo:
        return
    if Online.estado() == "juego":
        _ir_al_juego()
        return
    # Jugadores
    var js: Array = Online.jugadores_ordenados()
    var firma := ""
    for j in js:
        firma += "%s|%s|%d;" % [j["pid"], j["n"], j["c"]]
    if firma != _firma_jug:
        _firma_jug = firma
        OnlineUI.limpiar(lista_box)
        for j in js:
            var fila := Panel.new()
            fila.custom_minimum_size = Vector2(860, 80)
            var s := StyleBoxFlat.new()
            s.bg_color = GameUI.palette_color(int(j["c"]))
            s.set_corner_radius_all(30)
            s.border_color = Color.WHITE if j["pid"] == Online.pid else Color(0, 0, 0, 0.3)
            s.set_border_width_all(5 if j["pid"] == Online.pid else 2)
            fila.add_theme_stylebox_override("panel", s)
            var nombre: String = str(j["n"]) + ("  👑" if j["pid"] == str(Online.sala.get("host", "")) else "")
            var l := GameUI.label(fila, nombre, Vector2(20, 0), Vector2(820, 80), 38, Color.WHITE, false, 6)
            l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
            lista_box.add_child(fila)
    # Mis desafíos
    var mis: Array[String] = Online.mis_retos()
    var f2: String = "|".join(mis)
    retos_lbl.text = "%s: %d/%d   ·   %s: %d" % [I18n.t("on_my_retos"), mis.size(), Online.MAX_RETOS_JUGADOR, I18n.t("on_total"), Online.total_retos()]
    if f2 != _firma_retos:
        _firma_retos = f2
        OnlineUI.limpiar(retos_box)
        for i in range(mis.size()):
            var fila2 := HBoxContainer.new()
            fila2.custom_minimum_size = Vector2(860, 70)
            var t := Label.new()
            t.text = mis[i]
            t.custom_minimum_size = Vector2(740, 70)
            t.clip_text = true
            t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
            t.add_theme_font_size_override("font_size", 30)
            fila2.add_child(t)
            var x := Button.new()
            x.text = "✕"
            x.custom_minimum_size = Vector2(90, 70)
            x.add_theme_font_size_override("font_size", 34)
            x.pressed.connect(_quitar.bind(i))
            fila2.add_child(x)
            retos_box.add_child(fila2)
    if start_btn != null:
        var ok: bool = js.size() >= 2 and Online.total_retos() >= 1
        start_btn.disabled = not ok
        hint_lbl.text = "" if ok else I18n.t("on_need")

func _agregar() -> void:
    if Online.agregar_reto(input.text):
        input.text = ""
        _firma_retos = "x"
        _refrescar()
    else:
        Audio.play("error")
        hint_lbl.text = I18n.t("on_max")

func _quitar(i: int) -> void:
    Online.quitar_reto(i)
    _firma_retos = "x"
    _refrescar()

func _texto_compartir() -> String:
    var msg: String = I18n.t("on_share_msg_fmt") % Online.codigo
    var url: String = str(RemoteConfig.cfg.get("url_descarga", ""))
    if url != "":
        msg += "\n" + url
    return msg

func _compartir() -> void:
    OS.shell_open("https://wa.me/?text=" + _texto_compartir().uri_encode())

func _copiar() -> void:
    DisplayServer.clipboard_set(Online.codigo)
    Audio.play("chime")
    hint_lbl.text = I18n.t("on_copied")
    hint_lbl.add_theme_color_override("font_color", Color("#9be04a"))

func _iniciar() -> void:
    if _yendo:
        return
    start_btn.disabled = true
    var err: String = await Online.iniciar_partida()
    if not is_inside_tree():
        return
    if err == "":
        _ir_al_juego()
    else:
        hint_lbl.text = OnlineUI.mensaje_error(err)
        Audio.play("error")
        start_btn.disabled = false

func _ir_al_juego() -> void:
    if _yendo:
        return
    _yendo = true
    Online.preparar_globales()
    get_tree().change_scene_to_file("res://Ruleta.tscn")

func _cerrada() -> void:
    if _yendo:
        return
    _yendo = true
    var p := GameUI.modal(self, Vector2(780, 460), Color("#fbf8ff"))
    GameUI.label(p, I18n.t("on_closed"), Vector2(40, 90), Vector2(700, 160), 44, GameUI.DARK_TEXT, true)
    GameUI.pill(p, I18n.t("on_ok"), Vector2(190, 300), Vector2(400, 110), "green", _salir, 40)

func _sin_red() -> void:
    hint_lbl.text = I18n.t("on_err_net")

func _salir() -> void:
    Online.salir()
    get_tree().change_scene_to_file("res://OnlineMenu.tscn")

func _volver() -> void:
    get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
