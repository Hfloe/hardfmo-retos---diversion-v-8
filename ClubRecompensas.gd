extends Control
# CLUB DE RECOMPENSAS: se llega aquí con el PIN correcto.
# 8 cartas (5 con recompensa, 3 vacías) -> 2 s boca arriba -> boca abajo -> barajado -> el jugador elige UNA.
# Personalizable (botón "Personalizar cartas"): estilo del reverso y modo "raspa y gana" (raspar la carta con el dedo) o voltear.
# Los textos de las cartas se cambian en CartasConfig.gd. La carta elegida se guarda: solo se elige una vez (Global.CLUB_REPETIR para pruebas).

const W := Vector2(420, 300)
const COLS_X := [110.0, 550.0]
const Y0 := 330.0
const PASO_Y := 330.0
const MAZO := Vector2(330, 760)
const CENTRO_ELEGIDA := Vector2(330, 650)   # esquina de la carta elegida (queda centrada con escala 1.6)
const ESC := 1.6
const TEX_CARTA := "res://assets/carta_reverso.png"
const NOMBRES_ESTILO := ["Clásica", "Plata", "Rosa", "Verde", "Neón"]

var cartas: Array[Control] = []
var premios: Dictionary = {}      # carta -> índice del premio (0-4) o -1 si está vacía
var slots: Array[Vector2] = []
var info: Label
var btn_pers: Button
var estilo: int = 0
var raspa: bool = true
var tex_rayas: ImageTexture
var estado: int = 0               # 0 = animando · 1 = puede elegir · 2 = ya eligió

func _ready() -> void:
    estilo = Global.club_carta_estilo()
    raspa = Global.club_carta_raspa()
    GameUI.bg(self)
    GameUI.frame(self, Rect2(40, 40, 1000, 1840), Color("#ffc933"), 6, 70, true, Color(0.02, 0.03, 0.09, 0.78))
    var t := GameUI.label3d(self, CartasConfig.TITULO, Vector2(60, 80), Vector2(960, 120), 72, Color("#ffd23f"), Color("#9a6a00"), 8, Color("#3a2400"))
    t.autowrap_mode = TextServer.AUTOWRAP_OFF
    info = GameUI.label(self, "", Vector2(80, 215), Vector2(920, 100), 36, Color.WHITE, true, 6)
    var v := GameUI.glossy(self, "↩  Volver", Vector2(340, 1745), Vector2(400, 95), Color("#4a3fd6"), Color.WHITE, _volver, 38, 40)
    v.focus_mode = Control.FOCUS_NONE
    var previo: String = Global.club_resultado()
    if previo != "":
        _ver_resultado(previo, Global.club_idx())
        return
    btn_pers = GameUI.glossy(self, "🎨  Personalizar cartas", Vector2(290, 1640), Vector2(500, 90), Color("#27446f"), Color.WHITE, _personalizar, 34, 40, false)
    btn_pers.focus_mode = Control.FOCUS_NONE
    _crear_cartas()
    _secuencia()

# ---------- Cartas ----------
func _datos(idx: int) -> Dictionary:
    if idx >= 0 and idx < CartasConfig.PREMIOS.size():
        return CartasConfig.PREMIOS[idx]
    return CartasConfig.VACIA

func _caja_neon(radio: int) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = Color(0, 0, 0, 0)
    s.border_color = Color("#5ff2ff")
    s.set_border_width_all(5)
    s.set_corner_radius_all(radio)
    s.shadow_color = Color(0.2, 0.9, 1.0, 0.65)
    s.shadow_size = 16
    return s

func _textura_rayas(sz: Vector2, borde: Color, relleno: Color) -> ImageTexture:
    var w: int = int(sz.x)
    var h: int = int(sz.y)
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    var linea: Color = borde.lerp(relleno, 0.35)
    var margen: int = 12
    var r: float = 20.0
    for y in range(h):
        for x in range(w):
            if x < margen or y < margen or x >= w - margen or y >= h - margen:
                continue
            var cx: float = clampf(float(x), margen + r, w - margen - r)
            var cy: float = clampf(float(y), margen + r, h - margen - r)
            if Vector2(x - cx, y - cy).length() > r:
                continue
            if (x + y) % 4 < 2:
                img.set_pixel(x, y, linea)
    return ImageTexture.create_from_image(img)

func _hacer_carta(idx: int, pos: Vector2) -> Control:
    var d: Dictionary = _datos(idx)
    var premio: bool = idx >= 0
    var c := Control.new()
    c.position = pos
    c.size = W
    c.pivot_offset = W / 2.0
    c.mouse_filter = Control.MOUSE_FILTER_STOP
    # --- cara (lo que sale) ---
    var frente := Panel.new()
    frente.name = "frente"
    frente.size = W
    frente.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if premio:
        frente.add_theme_stylebox_override("panel", GameUI.flat_box(Color("#1d5a2a"), Color("#ffd23f"), 40, 6))
    else:
        frente.add_theme_stylebox_override("panel", GameUI.flat_box(Color("#4a1d1d"), Color("#c23a3a"), 40, 6))
    GameUI.label(frente, str(d.get("emoji", "")), Vector2(0, 18), Vector2(W.x, 130), 100)
    GameUI.label(frente, str(d.get("titulo", "")), Vector2(10, 150), Vector2(W.x - 20, 70), 40, Color("#ffe08a") if premio else Color("#ffb0b0"), true, 6)
    if str(d.get("detalle", "")) != "":
        GameUI.label(frente, str(d.get("detalle", "")), Vector2(20, 222), Vector2(W.x - 40, 64), 26, Color.WHITE, true, 4)
    c.add_child(frente)
    # --- reverso (según el estilo elegido) ---
    var dorso := Panel.new()
    dorso.name = "dorso"
    dorso.size = W
    dorso.visible = false
    dorso.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var ci: Array = GameUI.carta_info(estilo)
    var usa_tex: bool = estilo == 0 and ResourceLoader.exists(TEX_CARTA)
    var color_txt: Color = ci[2]
    if usa_tex:
        dorso.add_theme_stylebox_override("panel", _caja_neon(30))
        var cara := TextureRect.new()
        cara.texture = load(TEX_CARTA) as Texture2D
        cara.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        cara.stretch_mode = TextureRect.STRETCH_SCALE
        cara.mouse_filter = Control.MOUSE_FILTER_IGNORE
        cara.position = Vector2(3, 3)
        cara.size = W - Vector2(6, 6)
        dorso.add_child(cara)
        color_txt = Color("#ffd23f")
    else:
        dorso.add_theme_stylebox_override("panel", GameUI.flat_box(ci[0], ci[1], 40, 6))
        if tex_rayas == null:
            tex_rayas = _textura_rayas(W, ci[1], ci[0])
        var rayas := TextureRect.new()
        rayas.texture = tex_rayas
        rayas.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        rayas.stretch_mode = TextureRect.STRETCH_SCALE
        rayas.mouse_filter = Control.MOUSE_FILTER_IGNORE
        rayas.size = W
        dorso.add_child(rayas)
    GameUI.label(dorso, CartasConfig.TEXTO_DORSO, Vector2(0, 40), Vector2(W.x, 200), 150, color_txt, false, 10)
    c.add_child(dorso)
    return c

func _crear_cartas() -> void:
    for i in range(8):
        slots.append(Vector2(COLS_X[i % 2], Y0 + floori(i / 2.0) * PASO_Y))
    var tipos: Array = [0, 1, 2, 3, 4, -1, -1, -1]
    tipos.shuffle()
    for i in range(8):
        var c := _hacer_carta(tipos[i], slots[i])
        c.gui_input.connect(_on_carta.bind(c))
        add_child(c)
        cartas.append(c)
        premios[c] = tipos[i]

func _vivo() -> bool:
    return is_inside_tree()

# Gira la carta (escala X a 0 y de vuelta). `extra` se ejecuta justo cuando está de canto, para cambiar la cara sin que se note.
func _voltear(c: Control, arriba: bool, esc: float = 1.0, extra: Callable = Callable()) -> void:
    var tw := create_tween()
    tw.tween_property(c, "scale:x", 0.0, 0.14)
    await tw.finished
    if not _vivo():
        return
    c.get_node("frente").visible = arriba
    c.get_node("dorso").visible = not arriba
    if extra.is_valid():
        extra.call()
    var tw2 := create_tween()
    tw2.tween_property(c, "scale:x", esc, 0.14)
    await tw2.finished

func _secuencia() -> void:
    estado = 0
    info.text = "Mira bien dónde está cada carta..."
    await get_tree().create_timer(2.0).timeout
    if not _vivo():
        return
    info.text = "Barajando..."
    Audio.play("whoosh")
    for c in cartas:
        _voltear(c, false)
    await get_tree().create_timer(0.5).timeout
    if not _vivo():
        return
    await _barajar()
    if not _vivo():
        return
    info.text = "Elige UNA carta. Solo tienes una oportunidad."
    estado = 1

func _barajar() -> void:
    for i in range(cartas.size()):
        var tw := create_tween().set_parallel(true)
        tw.tween_property(cartas[i], "position", MAZO + Vector2(i * 2, -i * 2), 0.5).set_delay(i * 0.04).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
        tw.tween_property(cartas[i], "rotation_degrees", randf_range(-5.0, 5.0), 0.5).set_delay(i * 0.04)
    await get_tree().create_timer(0.95).timeout
    if not _vivo():
        return
    for r in range(4):
        for i in range(cartas.size()):
            var lado: float = -1.0 if (i + r) % 2 == 0 else 1.0
            var tw := create_tween().set_parallel(true)
            tw.tween_property(cartas[i], "position", MAZO + Vector2(lado * 230.0, randf_range(-30.0, 30.0)), 0.16)
            tw.tween_property(cartas[i], "rotation_degrees", lado * randf_range(4.0, 12.0), 0.16)
        await get_tree().create_timer(0.2).timeout
        if not _vivo():
            return
        for c in cartas:
            c.z_index = randi() % 8
        for i in range(cartas.size()):
            var tw2 := create_tween().set_parallel(true)
            tw2.tween_property(cartas[i], "position", MAZO + Vector2(i * 2, -i * 2), 0.16)
            tw2.tween_property(cartas[i], "rotation_degrees", randf_range(-5.0, 5.0), 0.16)
        await get_tree().create_timer(0.2).timeout
        if not _vivo():
            return
    var idx: Array = range(8)
    idx.shuffle()
    for k in range(cartas.size()):
        var c: Control = cartas[k]
        c.z_index = 0
        var tw3 := create_tween().set_parallel(true)
        tw3.tween_property(c, "position", slots[idx[k]], 0.5).set_delay(k * 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tw3.tween_property(c, "rotation_degrees", 0.0, 0.5).set_delay(k * 0.1)
    await get_tree().create_timer(1.4).timeout

# ---------- Elegir ----------
func _on_carta(ev: InputEvent, c: Control) -> void:
    if estado != 1:
        return
    if not (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT):
        return
    estado = 2
    btn_pers.visible = false
    for o in cartas:
        if o != c:
            create_tween().tween_property(o, "modulate:a", 0.25, 0.3)
    c.z_index = 5
    Audio.play("carta")
    info.text = "Descubre tu carta..."
    var tw := create_tween().set_parallel(true)
    tw.tween_property(c, "position", CENTRO_ELEGIDA, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    tw.tween_property(c, "scale", Vector2(ESC, ESC), 0.45)
    await tw.finished
    if not _vivo():
        return
    var idx: int = premios[c]
    if raspa:
        await _voltear(c, true, ESC, _poner_foil.bind(c, idx))
    else:
        await _voltear(c, true, ESC)
        if _vivo():
            _terminar(idx)

func _poner_foil(c: Control, idx: int) -> void:
    var foil := Raspador.new()
    foil.position = Vector2(14, 14)
    foil.size = W - Vector2(28, 28)
    foil.preparar(196, 136)
    c.add_child(foil)
    var pista := GameUI.label(c, CartasConfig.TEXTO_RASPA, Vector2(14, 14), W - Vector2(28, 28), 44, Color.WHITE, false, 8)
    info.text = "¡Raspa con el dedo!"
    foil.rascando.connect(_rasca_sonido)
    foil.revelado.connect(_revelado.bind(foil, pista, idx))

var _rasca_n: int = 0

func _rasca_sonido() -> void:
    _rasca_n += 1
    if _rasca_n % 6 == 1:
        Audio.play("tick", -10.0)

func _revelado(foil: Control, pista: Control, idx: int) -> void:
    pista.queue_free()
    var tw := create_tween()
    tw.tween_property(foil, "modulate:a", 0.0, 0.4)
    tw.tween_callback(foil.queue_free)
    await tw.finished
    if _vivo():
        _terminar(idx)

func _terminar(idx: int) -> void:
    var fecha: String = Time.get_datetime_string_from_system(false, true)
    Global.club_guardar_resultado("premio" if idx >= 0 else "vacia", fecha, idx)
    _mensaje_final(idx, fecha)

func _mensaje_final(idx: int, fecha: String) -> void:
    var d: Dictionary = _datos(idx)
    if idx >= 0:
        Audio.play("win")
        info.text = "🎉 ¡Te salió: %s!" % str(d.get("titulo", ""))
        GameUI.label(self, "¡Toma captura de pantalla y envíala a %s para reclamar tu premio!" % Global.CORREO_SECRETO, Vector2(90, 1640), Vector2(900, 150), 36, Color("#ffe08a"), true, 7)
    else:
        Audio.play("error")
        info.text = "Esta vez la carta salió vacía."
        GameUI.label(self, "Sin premio esta vez. ¡Gracias por llegar hasta el final!", Vector2(90, 1640), Vector2(900, 150), 36, Color("#ffd0d0"), true, 7)
    GameUI.label(self, fecha.replace("T", "  "), Vector2(90, 1700), Vector2(900, 40), 26, Color(1, 1, 1, 0.5))

func _ver_resultado(previo: String, idx: int) -> void:
    # ya eligió antes: se muestra su carta, no se puede volver a elegir
    if previo == "premio" and idx < 0:
        idx = 0
    var c := _hacer_carta(idx if previo == "premio" else -1, CENTRO_ELEGIDA)
    c.scale = Vector2(ESC, ESC)
    c.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(c)
    info.text = "Ya elegiste tu carta."
    _mensaje_final(idx if previo == "premio" else -1, Global.club_fecha())

# ---------- Personalizar ----------
func _personalizar() -> void:
    var p := GameUI.neon_modal(self, Vector2(940, 960))
    GameUI.label(p, "🎨  Personalizar cartas", Vector2(0, 30), Vector2(940, 90), 54, Color("#ffd23f"), false, 6)
    GameUI.label(p, "Estilo del reverso", Vector2(0, 140), Vector2(940, 50), 34, Color.WHITE, false, 5)
    for i in range(5):
        var ci: Array = GameUI.carta_info(i)
        var libre: bool = Global.desbloqueado(i)
        var b := Button.new()
        b.position = Vector2(47 + i * 174, 210)
        b.size = Vector2(150, 210)
        b.focus_mode = Control.FOCUS_NONE
        b.text = "✦" if libre else "🔒"
        b.add_theme_font_size_override("font_size", 56)
        for cn in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
            b.add_theme_color_override(cn, ci[2])
        var sel: bool = i == estilo
        var sb := GameUI.flat_box(ci[0], Color("#ffe08a") if sel else ci[1], 28, 9 if sel else 4)
        for st in ["normal", "hover", "pressed", "disabled"]:
            b.add_theme_stylebox_override(st, sb)
        if not libre:
            b.modulate = Color(1, 1, 1, 0.6)
        b.pressed.connect(_elegir_estilo.bind(i))
        p.add_child(b)
        GameUI.label(p, NOMBRES_ESTILO[i], Vector2(47 + i * 174 - 12, 424), Vector2(174, 40), 26, Color("#d6e6ff"), false, 4)
    GameUI.label(p, "¿Cómo se descubre la carta?", Vector2(0, 500), Vector2(940, 50), 34, Color.WHITE, false, 5)
    _boton_modo(p, "Voltear", false, Vector2(40, 565))
    _boton_modo(p, "Raspa y gana", true, Vector2(490, 565))
    GameUI.pill(p, "Listo", Vector2(270, 800), Vector2(400, 110), "green", GameUI.close_modal.bind(p), 44)

func _boton_modo(p: Control, titulo: String, es_raspa: bool, pos: Vector2) -> void:
    var activo: bool = raspa == es_raspa
    var base: Color = Color("#3fd35a") if activo else Color("#27446f")
    GameUI.glossy(p, ("✓  " if activo else "") + titulo, pos, Vector2(410, 150), base, Color.WHITE, _elegir_modo.bind(es_raspa), 42, 40, false)

func _elegir_estilo(i: int) -> void:
    if not Global.desbloqueado(i):
        get_tree().change_scene_to_file("res://Paywall.tscn")
        return
    Global.club_guardar_carta(i, raspa)
    get_tree().reload_current_scene()

func _elegir_modo(es_raspa: bool) -> void:
    Global.club_guardar_carta(estilo, es_raspa)
    get_tree().reload_current_scene()

func _volver() -> void:
    get_tree().change_scene_to_file("res://EducativoMenu.tscn")

# ---------- Capa plateada de "raspa y gana" ----------
class Raspador extends TextureRect:
    signal rascando
    signal revelado
    const RADIO := 12
    const CELDA := 10
    var img: Image
    var tex: ImageTexture
    var celdas: Dictionary = {}
    var total_celdas: int = 1
    var listo: bool = false

    func preparar(w: int, h: int) -> void:
        img = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
        var ruido := FastNoiseLite.new()
        ruido.frequency = 0.05
        for y in range(h):
            for x in range(w):
                var n: float = ruido.get_noise_2d(float(x), float(y)) * 0.5 + 0.5
                var franja: float = 0.5 + 0.5 * sin(float(x + y) * 0.11)
                var v: float = 0.46 + n * 0.22 + franja * 0.10
                img.set_pixel(x, y, Color(v, v, minf(1.0, v * 1.05), 1.0))
        tex = ImageTexture.create_from_image(img)
        texture = tex
        expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        stretch_mode = TextureRect.STRETCH_SCALE
        mouse_filter = Control.MOUSE_FILTER_STOP
        total_celdas = ceili(float(w) / float(CELDA)) * ceili(float(h) / float(CELDA))

    func _gui_input(e: InputEvent) -> void:
        if listo:
            return
        var mb := e as InputEventMouseButton
        var mm := e as InputEventMouseMotion
        if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
            _borrar(mb.position)
        elif mm != null and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
            _borrar(mm.position)

    func _borrar(pc: Vector2) -> void:
        var k: float = float(img.get_width()) / size.x
        var cx: int = int(pc.x * k)
        var cy: int = int(pc.y * k)
        for dy in range(-RADIO, RADIO + 1):
            var mitad: int = int(sqrt(float(RADIO * RADIO - dy * dy)))
            var y: int = cy + dy
            if y < 0 or y >= img.get_height():
                continue
            var x0: int = maxi(0, cx - mitad)
            var x1: int = mini(img.get_width(), cx + mitad)
            if x1 > x0:
                img.fill_rect(Rect2i(x0, y, x1 - x0, 1), Color(0, 0, 0, 0))
        tex.update(img)
        for ox in [-5, 0, 5]:
            for oy in [-5, 0, 5]:
                @warning_ignore("integer_division")
                celdas[Vector2i((cx + ox) / CELDA, (cy + oy) / CELDA)] = true
        rascando.emit()
        if celdas.size() >= int(float(total_celdas) * 0.6):
            listo = true
            revelado.emit()
