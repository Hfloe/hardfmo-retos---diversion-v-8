extends Control
# Registro de desafíos secretos: los participantes se turnan y pueden añadir muchos (hasta MAX_RETOS en total).
# Al guardar, el desafío se borra de la pantalla y no existe ninguna vista para consultarlo.

const CANT_ALEATORIOS := 20

var enviados: int = 0
var iniciado: bool = Global.registro_activo
var total: int = 1
var input: LineEdit
var turn_label: Label
var progress_label: Label
var status: Label

func _ready() -> void:
    Global.salir_club()
    total = maxi(Global.num_jugadores, 1)
    if iniciado:
        enviados = Global.retos.size()
    GameUI.bg_img(self, "res://assets/bg_desafios.jpg")
    # Título dorado en 3D en una sola línea (más pequeño para dejar espacio al texto)
    var tt := GameUI.label3d(self, I18n.t("secret_title"), Vector2(0, 70), Vector2(1080, 150), 100, Color("#ffd84a"), Color("#b87010"), 10, Color("#6b3d00"))
    tt.autowrap_mode = TextServer.AUTOWRAP_OFF
    turn_label = GameUI.label(self, "", Vector2(60, 250), Vector2(960, 64), 56, Color.WHITE, false, 8)
    # Panel oscuro detrás de la explicación para que las letras blancas se lean bien
    var caja := Panel.new()
    caja.position = Vector2(100, 335)
    caja.size = Vector2(880, 130)
    caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
    caja.add_theme_stylebox_override("panel", GameUI.flat_box(Color(0, 0, 0, 0.55), Color(1, 0.8, 0.4, 0.35), 34, 2))
    add_child(caja)
    GameUI.label(self, I18n.t("secret_hint"), Vector2(125, 340), Vector2(830, 120), 34, Color("#fff4dc"), true, 5)
    progress_label = GameUI.label(self, "", Vector2(90, 490), Vector2(900, 56), 40, Color.WHITE, false, 7)
    _crear_barra()

    input = LineEdit.new()
    input.position = Vector2(178, 665)
    input.size = Vector2(724, 106)
    input.placeholder_text = I18n.t("secret_ph")
    input.add_theme_font_size_override("font_size", 32)
    input.add_theme_color_override("font_color", Color.WHITE)
    input.add_theme_color_override("font_placeholder_color", Color("#b4b4c0"))
    input.add_theme_color_override("caret_color", Color("#ffe08a"))
    var st := StyleBoxFlat.new()
    st.bg_color = Color(0.05, 0.05, 0.08, 0.78)
    st.border_color = Color("#d9a64a")
    st.set_border_width_all(3)
    st.set_corner_radius_all(53)
    st.shadow_color = Color(1, 0.65, 0.2, 0.45)
    st.shadow_size = 12
    st.content_margin_left = 100
    st.content_margin_right = 36
    input.add_theme_stylebox_override("normal", st)
    var st_focus: StyleBoxFlat = st.duplicate() as StyleBoxFlat
    st_focus.border_color = Color("#ffe08a")
    input.add_theme_stylebox_override("focus", st_focus)
    input.text_submitted.connect(_on_enter)
    add_child(input)
    GameUI.label(self, "✎", Vector2(200, 679), Vector2(70, 80), 46, Color("#b9b9c4"))

    status = GameUI.label(self, "", Vector2(180, 782), Vector2(720, 44), 30, Color("#ffb0b0"), true, 6)
    GameUI.glossy(self, I18n.t("hide_save"), Vector2(216, 839), Vector2(648, 136), Color("#ffc62b"), GameUI.DARK_TEXT, _guardar, 48)
    GameUI.glossy(self, I18n.t("finish"), Vector2(216, 1009), Vector2(648, 136), Color("#94e02a"), GameUI.DARK_TEXT, _terminar, 48)
    GameUI.glossy(self, "🎲  " + _partir(I18n.t("random_fmt") % CANT_ALEATORIOS), Vector2(216, 1182), Vector2(648, 136), Color("#2b8af0"), Color.WHITE, _popup_aleatorios, 40)
    GameUI.glossy(self, "🎓  " + I18n.t("edu_btn"), Vector2(216, 1359), Vector2(648, 136), Color("#19d3e8"), Color("#0b2a4a"), _ir_educativo, 48)
    GameUI.glossy(self, "🔒  " + I18n.t("adult_btn"), Vector2(216, 1537), Vector2(648, 136), Color("#ff3fa4"), Color.WHITE, _boton_adultos, 48)
    GameUI.glossy(self, "↩  " + I18n.t("back"), Vector2(216, 1714), Vector2(648, 136), Color("#8a45f0"), Color.WHITE, _volver, 48)
    _actualizar()
    if Global.abrir_pin and Global.CLUB_PRIVADO_DISPONIBLE:
        # Venía de la pantalla de pago: abre directo la ventana para ingresar el código
        Global.abrir_pin = false
        _pedir_pin(_ir_club)

var _barra_relleno: Panel
var _barra_texto: Label

func _crear_barra() -> void:
    var marco := Panel.new()
    marco.position = Vector2(203, 560)
    marco.size = Vector2(674, 40)
    marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var ms := StyleBoxFlat.new()
    ms.bg_color = Color(0.05, 0.05, 0.08, 0.85)
    ms.border_color = Color("#d9a64a")
    ms.set_border_width_all(3)
    ms.set_corner_radius_all(20)
    marco.add_theme_stylebox_override("panel", ms)
    add_child(marco)
    _barra_relleno = Panel.new()
    _barra_relleno.position = Vector2(6, 6)
    _barra_relleno.size = Vector2(52, 28)
    _barra_relleno.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var rs := StyleBoxFlat.new()
    rs.bg_color = Color("#d9d9e2")
    rs.set_corner_radius_all(14)
    _barra_relleno.add_theme_stylebox_override("panel", rs)
    marco.add_child(_barra_relleno)
    _barra_texto = GameUI.label(marco, "", Vector2(400, 0), Vector2(260, 40), 26, Color("#e8c77a"))
    _barra_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

# Parte un texto largo en dos líneas por el espacio más cercano a la mitad.
func _partir(t: String) -> String:
    @warning_ignore("integer_division")
    var mitad: int = t.length() / 2
    var mejor: int = -1
    for i in range(t.length()):
        if t[i] == " " and (mejor < 0 or absi(i - mitad) < absi(mejor - mitad)):
            mejor = i
    if mejor < 0:
        return t
    return t.substr(0, mejor) + "\n" + t.substr(mejor + 1)

func _actualizar() -> void:
    turn_label.text = I18n.t("secret_turn_fmt") % Global.nombre_de(enviados % total)
    progress_label.text = I18n.t("secret_count2_fmt") % [enviados, Global.MAX_RETOS]
    _barra_texto.text = "%d/%d" % [enviados, Global.MAX_RETOS]
    _barra_relleno.size.x = maxf(52.0, 662.0 * float(enviados) / float(Global.MAX_RETOS))

func _iniciar_sesion() -> void:
    # La primera vez que se registra algo se empieza una lista nueva; después se va acumulando.
    if not iniciado:
        Global.retos.clear()
        Global.completados.clear()
        iniciado = true
        Global.registro_activo = true

func _mensaje(texto: String, ok: bool) -> void:
    if not ok:
        Audio.play("error")
    status.text = texto
    status.add_theme_color_override("font_color", Color("#8dfcae") if ok else Color("#ff8d8d"))

func _ir_educativo() -> void:
    get_tree().change_scene_to_file("res://EducativoMenu.tscn")

# ---------- Popup de desafíos aleatorios ----------

func _boton_color(texto: String, pos: Vector2, cb: Callable, fill: Color, edge: Color, txt: Color) -> void:
    var b := GameUI.flat_button(self, pos, Vector2(620, 105), fill, edge, cb, 52, 4)
    b.text = texto
    b.add_theme_font_size_override("font_size", 42)
    for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
        b.add_theme_color_override(c, txt)

func _popup_aleatorios() -> void:
    var libre: bool = Global.adultos_desbloqueado()
    var p := GameUI.neon_modal(self, Vector2(960, 1400))
    var t := GameUI.label(p, I18n.t("rnd_q"), Vector2(60, 80), Vector2(840, 210), 68, Color("#ffd870"), true, 8)
    t.add_theme_color_override("font_outline_color", Color("#7a3d00"))
    var linea := ColorRect.new()
    linea.color = Color(1, 0.8, 0.4, 0.55)
    linea.position = Vector2(200, 318)
    linea.size = Vector2(560, 3)
    p.add_child(linea)
    GameUI.label(p, "❖", Vector2(430, 296), Vector2(100, 48), 34, Color("#ffd870"))
    _tarjeta_popup(p, 370, Color("#9de79c"), Color("#c8f7bf"), "✓", Color("#2f7a3a"), I18n.t("rnd_easy"), I18n.t("rnd_easy_sub"), Color("#0b3d16"), Color("#1f5b2a"), _elegir.bind("facil", p))
    _tarjeta_popup(p, 660, Color("#ffc04d"), Color("#ffe08a"), "✓", Color("#a04a10"), I18n.t("rnd_hard"), I18n.t("rnd_hard_sub"), Color("#5a1f00"), Color("#7a3a10"), _elegir.bind("dificil", p))
    if libre:
        _tarjeta_popup(p, 950, Color("#b0207a"), Color("#ff8ad0"), "✓", Color("#ffd6f0"), I18n.t("rnd_spicy"), I18n.t("rnd_spicy_open"), Color.WHITE, Color("#ffd6f0"), _elegir.bind("picante", p))
    else:
        _tarjeta_popup(p, 950, Color("#4a1246"), Color("#a83a8f"), "🔒", Color("#b98ab0"), I18n.t("rnd_spicy"), I18n.t("rnd_spicy_sub"), Color("#ffb3e6"), Color("#d99ac8"), _elegir.bind("picante", p))
    var cancelar := GameUI.flat_button(p, Vector2(300, 1250), Vector2(360, 90), Color("#0a0e1c"), Color("#3ba0ff"), GameUI.close_modal.bind(p), 45, 3)
    cancelar.text = I18n.t("pin_cancel")
    cancelar.add_theme_font_size_override("font_size", 38)
    for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
        cancelar.add_theme_color_override(c, Color("#6fb6ff"))

func _tarjeta_popup(p: Control, y: float, fill: Color, edge: Color, icono: String, icono_col: Color, titulo: String, sub: String, c_titulo: Color, c_sub: Color, cb: Callable) -> void:
    var b := GameUI.flat_button(p, Vector2(60, y), Vector2(840, 250), fill, edge, cb, 46, 3)
    var aro := GameUI.circle(b, Vector2(100, 125), 50, Color(0, 0, 0, 0.12), icono_col, 5)
    aro.mouse_filter = Control.MOUSE_FILTER_IGNORE
    GameUI.label(b, icono, Vector2(50, 75), Vector2(100, 100), 54, icono_col)
    GameUI.left_label(b, titulo, Vector2(180, 30), Vector2(630, 120), 38, c_titulo)
    GameUI.left_label(b, sub, Vector2(180, 150), Vector2(630, 70), 30, c_sub)

func _elegir(nivel: String, panel: Control) -> void:
    GameUI.close_modal(panel)
    match nivel:
        "facil":
            _agregar_aleatorios("res://facil.json")
        "dificil":
            _agregar_aleatorios("res://dificil.json")
        "picante":
            if Global.adultos_desbloqueado():
                _requerir_acceso(_agregar_aleatorios.bind("res://picante.json"))
            else:
                _aviso_picante()

func _aviso_picante() -> void:
    _menu_adultos(_agregar_aleatorios.bind("res://picante.json"))

func _cargar_json(ruta: String) -> Array[String]:
    var salida: Array[String] = []
    if not FileAccess.file_exists(ruta):
        return salida
    var f := FileAccess.open(ruta, FileAccess.READ)
    if f == null:
        return salida
    var datos: Variant = JSON.parse_string(f.get_as_text())
    if datos is Array:
        for x in datos:
            salida.append(str(x))
    return salida

func _agregar_aleatorios(ruta: String) -> void:
    var espacio: int = Global.MAX_RETOS - Global.retos.size()
    if espacio <= 0:
        _mensaje("⚠  " + I18n.t("random_full"), false)
        return
    var pool: Array[String] = []
    for d in _cargar_json(ruta):
        if not Global.retos.has(d):
            pool.append(d)
    if pool.is_empty():
        _mensaje("⚠  " + I18n.t("rnd_empty"), false)
        return
    pool.shuffle()
    var elegidos: Array = pool.slice(0, mini(CANT_ALEATORIOS, espacio))
    _iniciar_sesion()
    for d in elegidos:
        Global.retos.append(d)
    Global.guardar_datos()
    enviados = Global.retos.size()
    _mensaje(I18n.t("random_added_fmt") % elegidos.size(), true)
    _actualizar()

# ---------- Contenido adulto: PIN de 4 dígitos ----------

var _pin: String = ""
var _pin_panel: Panel
var _pin_display: Label
var _pin_msg: Label
var _pin_ok: Callable

func _en_desarrollo_club() -> void:
    var p := GameUI.modal(self, Vector2(780, 560), Color("#fbf8ff"))
    GameUI.label(p, "🛠️", Vector2(0, 30), Vector2(780, 140), 100)
    GameUI.label(p, I18n.t("on_dev_title"), Vector2(40, 190), Vector2(700, 90), 52, GameUI.DARK_TEXT, true)
    GameUI.label(p, "El Club Privado estará disponible muy pronto. ¡Gracias por tu paciencia!", Vector2(60, 290), Vector2(660, 120), 32, Color("#3c3a55"), true)
    GameUI.pill(p, I18n.t("on_ok"), Vector2(190, 430), Vector2(400, 110), "green", GameUI.close_modal.bind(p), 40)

func _boton_adultos() -> void:
    if not Global.CLUB_PRIVADO_DISPONIBLE:
        _en_desarrollo_club()
        return
    if Global.adultos_desbloqueado():
        _requerir_acceso(_ir_club)
    else:
        _menu_adultos(_ir_club)

# Ya desbloqueado: pide el PIN personal (o lo crea la primera vez). Una vez puesto, no lo vuelve a pedir hasta cerrar el juego.
func _requerir_acceso(al_acertar: Callable) -> void:
    if not Global.tiene_pin_personal():
        _abrir_teclado("crear", al_acertar)
    elif Global.club_verificado:
        al_acertar.call()
    else:
        _abrir_teclado("personal", al_acertar)

# Entra a la sala del Club Privado (4 jugadores, diseño VIP)
func _ir_club() -> void:
    Global.registro_activo = false
    get_tree().change_scene_to_file("res://ClubPrivado.tscn")

func _boton_texto(parent: Control, texto: String, pos: Vector2, sz: Vector2, fill: Color, edge: Color, cb: Callable, fuente: int = 38, color: Color = Color.WHITE) -> Button:
    var b := GameUI.flat_button(parent, pos, sz, fill, edge, cb, 44, 3)
    b.text = texto
    b.add_theme_font_size_override("font_size", fuente)
    for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
        b.add_theme_color_override(c, color)
    return b

# Contenido adulto: primero se elige pagar por Nequi o poner el código.
func _menu_adultos(al_acertar: Callable) -> void:
    var p := GameUI.neon_modal(self, Vector2(900, 900))
    GameUI.label(p, "🔞", Vector2(0, 70), Vector2(900, 130), 90)
    var t := GameUI.label(p, I18n.t("adult_menu_title"), Vector2(40, 210), Vector2(820, 100), 56, Color("#ff8ad0"), true, 8)
    t.add_theme_color_override("font_outline_color", Color("#4a0a3a"))
    GameUI.label(p, I18n.t("adult_menu_msg"), Vector2(70, 330), Vector2(760, 180), 32, Color("#e9e2ff"), true)
    _boton_texto(p, I18n.t("nequi_btn"), Vector2(100, 520), Vector2(700, 110), Color("#6b1c8f"), Color("#ff6fd0"), _abrir_nequi.bind(p, al_acertar), 40)
    _boton_texto(p, "🔑  " + I18n.t("code_btn"), Vector2(100, 650), Vector2(700, 110), Color("#12633a"), Color("#5cf0a0"), _abrir_codigo.bind(p, al_acertar), 40)
    _boton_texto(p, I18n.t("pin_cancel"), Vector2(300, 785), Vector2(300, 70), Color("#0a0e1c"), Color("#3ba0ff"), GameUI.close_modal.bind(p), 32, Color("#6fb6ff"))

func _abrir_codigo(panel: Control, al_acertar: Callable) -> void:
    GameUI.close_modal(panel)
    _pedir_pin(al_acertar)

# "Pagar por Nequi 50k": lleva a la pantalla de pago del Club Privado (ahí se copia el número). Al volver regresa aquí.
func _abrir_nequi(panel: Control, _al_acertar: Callable) -> void:
    GameUI.close_modal(panel)
    Global.volver_a = "res://RetosAnonimos.tscn"
    get_tree().change_scene_to_file("res://PagoClub.tscn")

func _pedir_pin(al_acertar: Callable) -> void:
    _abrir_teclado("codigo", al_acertar)

var _pin_modo: String = ""
var _pin_nuevo: String = ""
var _pin_titulo: Label
var _pin_sub: Label

func _abrir_teclado(modo: String, al_acertar: Callable) -> void:
    _pin = ""
    _pin_nuevo = ""
    _pin_modo = modo
    _pin_ok = al_acertar
    _pin_panel = GameUI.modal(self, Vector2(820, 1200), Color("#fbf8ff"))
    GameUI.label(_pin_panel, "🔞", Vector2(0, 20), Vector2(820, 110), 80)
    _pin_titulo = GameUI.label(_pin_panel, "", Vector2(40, 130), Vector2(740, 80), 46, GameUI.DARK_TEXT, true)
    _pin_sub = GameUI.label(_pin_panel, "", Vector2(60, 215), Vector2(700, 60), 30, Color("#3c3a55"), true)
    _pin_display = GameUI.label(_pin_panel, "", Vector2(60, 285), Vector2(700, 100), 70, Color("#6a3ad8"))
    _pin_msg = GameUI.label(_pin_panel, "", Vector2(60, 385), Vector2(700, 50), 28, Color("#d63b3b"), true)
    for n in range(1, 10):
        var col: int = (n - 1) % 3
        var fila: int = floori(float(n - 1) / 3.0)
        GameUI.pill(_pin_panel, str(n), Vector2(130 + col * 190, 450 + fila * 115), Vector2(170, 100), "purple", _pin_digito.bind(n), 52, false, 30)
    GameUI.pill(_pin_panel, "⌫", Vector2(130, 795), Vector2(170, 100), "gray", _pin_borrar, 48, false, 30)
    GameUI.pill(_pin_panel, "0", Vector2(320, 795), Vector2(170, 100), "purple", _pin_digito.bind(0), 52, false, 30)
    GameUI.pill(_pin_panel, "✓", Vector2(510, 795), Vector2(170, 100), "green", _pin_confirmar, 52, false, 30)
    GameUI.pill(_pin_panel, I18n.t("pin_cancel"), Vector2(190, 925), Vector2(440, 100), "red", GameUI.close_modal.bind(_pin_panel), 40)
    if modo == "personal":
        var olv := GameUI.flat_button(_pin_panel, Vector2(190, 1055), Vector2(440, 80), Color("#ece4ff"), Color("#9b6bff"), _olvide_pin, 40, 3)
        olv.text = I18n.t("pin_forgot")
        olv.add_theme_font_size_override("font_size", 30)
        for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
            olv.add_theme_color_override(c, Color("#4b1fb0"))
    _pin_textos()
    _pin_actualizar()

func _pin_textos() -> void:
    match _pin_modo:
        "codigo":
            _pin_titulo.text = I18n.t("pin_title")
            _pin_sub.text = I18n.t("pin_msg")
        "reset":
            _pin_titulo.text = I18n.t("pin_forgot")
            _pin_sub.text = I18n.t("pin_reset_msg")
        "crear":
            _pin_titulo.text = I18n.t("pin_new_title")
            _pin_sub.text = I18n.t("pin_new_msg")
        "confirmar":
            _pin_titulo.text = I18n.t("pin_conf_title")
            _pin_sub.text = I18n.t("pin_conf_msg")
        "personal":
            _pin_titulo.text = I18n.t("pin_title")
            _pin_sub.text = I18n.t("pin_enter_msg")

# "Olvidé mi PIN": con el código original se puede crear uno nuevo.
func _olvide_pin() -> void:
    var cb: Callable = _pin_ok
    GameUI.close_modal(_pin_panel)
    _abrir_teclado("reset", cb)

func _pin_actualizar() -> void:
    var puntos: Array[String] = []
    for i in range(4):
        puntos.append("●" if i < _pin.length() else "○")
    _pin_display.text = "  ".join(puntos)

func _pin_digito(n: int) -> void:
    if _pin.length() >= 4:
        return
    _pin += str(n)
    _pin_msg.text = ""
    _pin_actualizar()

func _pin_borrar() -> void:
    if _pin.length() > 0:
        _pin = _pin.substr(0, _pin.length() - 1)
    _pin_msg.text = ""
    _pin_actualizar()

func _pin_confirmar() -> void:
    if _pin.length() < 4:
        Audio.play("error")
        _pin_msg.text = I18n.t("pin_short")
        return
    match _pin_modo:
        "codigo", "reset":
            if _pin != Global.PIN_ADULTOS:
                Audio.play("error")
                _pin = ""
                _pin_actualizar()
                _pin_msg.text = I18n.t("pin_wrong")
                return
            Global.desbloquear_adultos()
            var cb: Callable = _pin_ok
            GameUI.close_modal(_pin_panel)
            # El código solo desbloquea: ahora la persona crea su PIN personal (siempre si es "reset")
            if _pin_modo == "reset" or not Global.tiene_pin_personal():
                _abrir_teclado("crear", cb)
            else:
                Global.club_verificado = true
                cb.call()
        "crear":
            _pin_nuevo = _pin
            _pin = ""
            _pin_modo = "confirmar"
            _pin_textos()
            _pin_msg.text = ""
            _pin_actualizar()
        "confirmar":
            if _pin != _pin_nuevo:
                Audio.play("error")
                _pin = ""
                _pin_nuevo = ""
                _pin_modo = "crear"
                _pin_textos()
                _pin_actualizar()
                _pin_msg.text = I18n.t("pin_nomatch")
                return
            Global.guardar_pin_personal(_pin)
            var cb2: Callable = _pin_ok
            GameUI.close_modal(_pin_panel)
            cb2.call()
        "personal":
            if not Global.pin_personal_correcto(_pin):
                Audio.play("error")
                _pin = ""
                _pin_actualizar()
                _pin_msg.text = I18n.t("pin_wrong")
                return
            Global.club_verificado = true
            var cb3: Callable = _pin_ok
            GameUI.close_modal(_pin_panel)
            cb3.call()

func _on_enter(_texto: String) -> void:
    _guardar()

func _guardar() -> void:
    var t: String = input.text.strip_edges()
    if t == "":
        _mensaje("⚠  " + I18n.t("need_text"), false)
        return
    status.text = ""
    _iniciar_sesion()
    Global.retos.append(t)
    Global.guardar_datos()
    enviados = Global.retos.size()
    input.text = ""
    input.release_focus()
    if enviados >= Global.MAX_RETOS:
        Global.registro_activo = false
        get_tree().change_scene_to_file("res://RetosCompletados.tscn")
        return
    _mostrar_relevo()
    _actualizar()

func _terminar() -> void:
    if Global.retos.is_empty():
        _mensaje("⚠  " + I18n.t("need_text"), false)
        return
    Global.registro_activo = false
    get_tree().change_scene_to_file("res://RetosCompletados.tscn")

func _mostrar_relevo() -> void:
    var p := GameUI.modal(self, Vector2(780, 560), Color("#fbf8ff"))
    GameUI.label(p, "🔒", Vector2(0, 30), Vector2(780, 130), 90)
    GameUI.label(p, I18n.t("saved_hidden"), Vector2(40, 170), Vector2(700, 80), 42, GameUI.DARK_TEXT, true)
    GameUI.label(p, I18n.t("pass_device"), Vector2(60, 260), Vector2(660, 110), 30, Color("#3c3a55"), true)
    GameUI.pill(p, I18n.t("ready"), Vector2(170, 400), Vector2(440, 115), "green", _cerrar_relevo.bind(p), 44)

func _cerrar_relevo(panel: Control) -> void:
    GameUI.close_modal(panel)

func _volver() -> void:
    Global.registro_activo = false
    get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
