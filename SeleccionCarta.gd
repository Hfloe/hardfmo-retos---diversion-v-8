extends Control
# Cartas de la ronda: salen del mazo (arriba a la derecha) una por cada desafío, con un máximo de 10.
# Si hay 20 desafíos salen 10 cartas; si hay 8, salen 8.
# "Barajar": solo mezcla de lugar las cartas que están afuera.
# "Barajar desde el inicio": las cartas vuelven al mazo y se reparten otras nuevas.

const MAX_CARTAS := 10
const CENTRO_MAZO := Vector2(830, 549)
const TEX_CARTA := "res://assets/carta_reverso.png"

var selected: bool = false
var busy: bool = false
var card_buttons: Array[Button] = []
var slots: Array[Vector2] = []
var card_size: Vector2 = Vector2(174, 387)
var contenido: Array[String] = []
var reto: String = ""
var intentadas: Array[int] = []  # cartas ya tomadas cuyo desafío quedó como "No completado"

func _ready() -> void:
    if Global.retos.is_empty():
        _salir.call_deferred()
        return
    GameUI.bg_tema(self, "res://assets/bg_cartas.jpg")
    var t_all: String = I18n.t("shuffle_all")
    var sp: int = t_all.find(" ")
    if sp > 0:
        t_all = t_all.substr(0, sp) + "\n" + t_all.substr(sp + 1)
    GameUI.glossy(self, "🚪  " + I18n.t("exit"), Vector2(45, 99), Vector2(303, 146), Color("#ffc933"), GameUI.DARK_TEXT, _salir, 48)
    GameUI.glossy(self, "🔀  " + I18n.t("shuffle"), Vector2(383, 99), Vector2(311, 146), Color("#e8322e"), Color.WHITE, _barajar, 48)
    GameUI.glossy(self, "🔄 " + t_all, Vector2(726, 99), Vector2(311, 146), Color("#8a45f0"), Color.WHITE, _barajar_todo, 32)
    var linea := ColorRect.new()
    linea.color = Color(1, 1, 1, 0.22)
    linea.position = Vector2(0, 268)
    linea.size = Vector2(GameUI.W, 2)
    linea.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(linea)
    GameUI.voz_boton(self, Vector2(50, 300))
    _crear_mazo()
    _repartir()

func _calcular_layout(n: int) -> void:
    slots.clear()
    var filas: Array[int] = []
    if n <= 3:
        filas = [n]
    else:
        var c1: int = int(ceil(n / 2.0))
        filas = [c1, n - c1]
    var gap: float = 26.0
    var ys: Array[float] = [788.0, 1264.0]
    card_size = Vector2(174, 387)
    if filas.size() == 1:
        ys = [1000.0]
    for r in range(filas.size()):
        var c: int = filas[r]
        var total: float = float(c) * card_size.x + float(c - 1) * gap
        var x0: float = (GameUI.W - total) / 2.0
        for k in range(c):
            slots.append(Vector2(x0 + float(k) * (card_size.x + gap), ys[r]))

func _repartir() -> void:
    busy = true
    intentadas.clear()
    for b in card_buttons:
        b.queue_free()
    card_buttons.clear()
    var pool: Array[String] = []
    for r in Global.retos:
        pool.append(r)
    pool.shuffle()
    var n: int = mini(pool.size(), MAX_CARTAS)
    contenido.clear()
    for i in range(n):
        contenido.append(pool[i])
    _calcular_layout(n)
    for i in range(n):
        var b := _crear_carta(i)
        b.position = CENTRO_MAZO - b.size / 2.0
        b.scale = Vector2(0.45, 0.45)
        b.rotation = randf_range(-0.2, 0.2)
        b.disabled = true
        add_child(b)
        card_buttons.append(b)
        var d: float = 0.09 * float(i)
        var tw := create_tween().set_parallel(true)
        tw.tween_callback(Audio.play.bind("carta")).set_delay(d)
        tw.tween_property(b, "position", slots[i], 0.5).set_delay(d).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tw.tween_property(b, "scale", Vector2.ONE, 0.5).set_delay(d)
        tw.tween_property(b, "rotation", 0.0, 0.5).set_delay(d)
    await get_tree().create_timer(0.09 * float(n) + 0.6).timeout
    if not is_inside_tree():
        return
    for b in card_buttons:
        b.disabled = false
    busy = false

func _usa_textura() -> bool:
    return Global.carta_efectiva() == 0 and ResourceLoader.exists(TEX_CARTA)

func _crear_mazo() -> void:
    if _usa_textura():
        var holder := Control.new()
        holder.position = CENTRO_MAZO
        holder.rotation = 0.45
        holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(holder)
        var tex: Texture2D = load(TEX_CARTA) as Texture2D
        var sz := Vector2(200, 330)
        for k in range(9):
            var r := TextureRect.new()
            r.texture = tex
            r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            r.stretch_mode = TextureRect.STRETCH_SCALE
            r.size = sz
            r.position = -sz / 2.0 + Vector2(float(k) * 1.5, -float(k) * 4.0)
            r.mouse_filter = Control.MOUSE_FILTER_IGNORE
            holder.add_child(r)
            if k == 8:
                var aro := Panel.new()
                aro.size = sz
                aro.position = r.position
                aro.mouse_filter = Control.MOUSE_FILTER_IGNORE
                aro.add_theme_stylebox_override("panel", _caja_neon(20))
                holder.add_child(aro)
        return
    var info: Array = GameUI.carta_info(Global.carta_efectiva())
    var relleno: Color = info[0]
    var borde: Color = info[1]
    for k in range(8):
        GameUI.frame(self, Rect2(640 + k * 3, 470 - k * 8, 300, 200), borde, 4, 24, k == 7, relleno)

func _caja_neon(radio: int) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = Color(0, 0, 0, 0)
    s.border_color = Color("#5ff2ff")
    s.set_border_width_all(5)
    s.set_corner_radius_all(radio)
    s.shadow_color = Color(0.2, 0.9, 1.0, 0.65)
    s.shadow_size = 16
    return s

func _crear_carta(i: int) -> Button:
    var b := Button.new()
    b.size = card_size
    b.position = slots[i]
    b.pivot_offset = b.size / 2.0
    b.focus_mode = Control.FOCUS_NONE
    if _usa_textura():
        var neon: StyleBoxFlat = _caja_neon(18)
        for st in ["normal", "hover", "pressed", "disabled"]:
            b.add_theme_stylebox_override(st, neon)
        b.pressed.connect(_elegir.bind(i))
        var cara := TextureRect.new()
        cara.texture = load(TEX_CARTA) as Texture2D
        cara.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        cara.stretch_mode = TextureRect.STRETCH_SCALE
        cara.mouse_filter = Control.MOUSE_FILTER_IGNORE
        cara.position = Vector2(3, 3)
        cara.size = b.size - Vector2(6, 6)
        b.add_child(cara)
        return b
    var info: Array = GameUI.carta_info(Global.carta_efectiva())
    var relleno: Color = info[0]
    var borde: Color = info[1]
    var simbolo: Color = info[2]
    for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
        b.add_theme_color_override(c, simbolo)
    var s := StyleBoxFlat.new()
    s.bg_color = relleno
    s.border_color = borde
    s.set_border_width_all(6)
    s.set_corner_radius_all(28)
    s.shadow_color = Color(borde.r, borde.g, borde.b, 0.4)
    s.shadow_size = 16
    for st in ["normal", "hover", "pressed", "disabled"]:
        b.add_theme_stylebox_override(st, s)
    b.pressed.connect(_elegir.bind(i))
    # Reverso de la carta: miles de rayitas finas y juntas
    var rayas := TextureRect.new()
    rayas.texture = _textura_rayas(b.size, borde, relleno)
    rayas.mouse_filter = Control.MOUSE_FILTER_IGNORE
    rayas.position = Vector2.ZERO
    rayas.size = b.size
    rayas.stretch_mode = TextureRect.STRETCH_SCALE
    rayas.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    b.add_child(rayas)
    return b

func _textura_rayas(sz: Vector2, borde: Color, relleno: Color) -> ImageTexture:
    var w: int = int(sz.x)
    var h: int = int(sz.y)
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    var linea: Color = borde.lerp(relleno, 0.35)
    var margen: int = 12   # deja libre el borde de la carta
    var r: float = 20.0    # radio de las esquinas de la zona rayada
    for y in range(h):
        for x in range(w):
            if x < margen or y < margen or x >= w - margen or y >= h - margen:
                continue
            # esquinas redondeadas
            var cx: float = clampf(float(x), margen + r, w - margen - r)
            var cy: float = clampf(float(y), margen + r, h - margen - r)
            if Vector2(x - cx, y - cy).length() > r:
                continue
            if (x + y) % 4 < 2:  # línea de 2 px, hueco de 2 px, en diagonal
                img.set_pixel(x, y, linea)
    return ImageTexture.create_from_image(img)

func _barajar() -> void:
    if selected or busy:
        return
    var orden: Array = slots.duplicate()
    orden.shuffle()
    Audio.play("whoosh")
    for i in range(card_buttons.size()):
        var tw := create_tween()
        tw.tween_property(card_buttons[i], "position", orden[i], 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _barajar_todo() -> void:
    if selected or busy:
        return
    busy = true
    Audio.play("whoosh")
    var n: int = card_buttons.size()
    for i in range(n):
        var b: Button = card_buttons[i]
        b.disabled = true
        var d: float = 0.06 * float(i)
        var tw := create_tween().set_parallel(true)
        tw.tween_property(b, "position", CENTRO_MAZO - b.size / 2.0, 0.4).set_delay(d).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
        tw.tween_property(b, "scale", Vector2(0.45, 0.45), 0.4).set_delay(d)
        tw.tween_property(b, "rotation", randf_range(-0.2, 0.2), 0.4).set_delay(d)
    await get_tree().create_timer(0.06 * float(n) + 0.6).timeout
    if not is_inside_tree():
        return
    # Los desafíos cumplidos vuelven al mazo SOLO al barajar desde el inicio
    var devueltos: int = Global.completados.size()
    if devueltos > 0:
        for t in Global.completados:
            Global.retos.append(t)
        Global.completados.clear()
        Global.guardar_datos()
        _aviso(I18n.t("returned_fmt") % devueltos)
    _repartir()

func _aviso(texto: String) -> void:
    var l := GameUI.label(self, texto, Vector2(200, 330), Vector2(680, 70), 34, Color("#9be04a"), true, 8)
    var tw := create_tween()
    tw.tween_interval(2.2)
    tw.tween_property(l, "modulate:a", 0.0, 0.6)
    tw.tween_callback(l.queue_free)

func _elegir(i: int) -> void:
    if selected:
        return
    selected = true
    Audio.play("carta")
    Global.current_card = i
    var tw := create_tween()
    tw.tween_property(card_buttons[i], "scale", Vector2(1.12, 1.12), 0.2)
    await tw.finished
    if not is_inside_tree():
        return
    reto = contenido[i]
    if reto == "":
        _mostrar_vacia()
    else:
        if Online.activo:
            Online.publicar_reto(reto, Global.current_player)
        if Global.carta_raspar() and not Online.activo:
            _raspar()
        else:
            _mostrar_reto()

func _mostrar_reto() -> void:
    Audio.play("win")
    Voz.decir(I18n.t("your_challenge") + " " + reto)
    var p := GameUI.modal(self, Vector2(860, 660), Color("#fbf8ff"))
    GameUI.label(p, I18n.t("your_challenge"), Vector2(40, 40), Vector2(780, 70), 36, Color("#6a3ad8"))
    GameUI.label(p, reto, Vector2(50, 130), Vector2(760, 330), 50, Global.color_reto(reto), true)
    GameUI.pill(p, I18n.t("complete"), Vector2(30, 500), Vector2(385, 115), "green", _completar, 36)
    GameUI.pill(p, I18n.t("not_complete"), Vector2(445, 500), Vector2(385, 115), "red", _no_completado.bind(p), 36)

# ---------- Modo "raspa y gana": la carta se descubre raspando con el dedo ----------

class Raspador extends TextureRect:
    signal rascando
    signal revelado
    const RADIO := 22
    const CELDA := 20
    var img: Image
    var tex: ImageTexture
    var celdas: Dictionary = {}
    var total_celdas: int = 1
    var listo: bool = false

    func preparar(w: int, h: int) -> void:
        img = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
        var ruido := FastNoiseLite.new()
        ruido.frequency = 0.04
        for y in range(h):
            for x in range(w):
                var n: float = ruido.get_noise_2d(float(x), float(y)) * 0.5 + 0.5
                var franja: float = 0.5 + 0.5 * sin(float(x + y) * 0.09)
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
        for ox in [-10, 0, 10]:
            for oy in [-10, 0, 10]:
                @warning_ignore("integer_division")
                celdas[Vector2i((cx + ox) / CELDA, (cy + oy) / CELDA)] = true
        rascando.emit()
        if celdas.size() >= int(float(total_celdas) * 0.6):
            listo = true
            revelado.emit()

var _rasca_n: int = 0

func _raspar() -> void:
    Audio.play("whoosh")
    var p := GameUI.modal(self, Vector2(860, 800), Color("#14102e"))
    GameUI.label(p, I18n.t("scratch_title"), Vector2(40, 40), Vector2(780, 100), 44, Color("#ffd870"), true, 7)
    var area := Panel.new()
    area.position = Vector2(90, 160)
    area.size = Vector2(680, 440)
    area.add_theme_stylebox_override("panel", GameUI.flat_box(Color("#fbf8ff"), Color("#ffd870"), 36, 5))
    p.add_child(area)
    GameUI.label(area, reto, Vector2(24, 12), Vector2(632, 416), 44, Global.color_reto(reto), true)
    var foil := Raspador.new()
    foil.position = Vector2(104, 174)
    foil.size = Vector2(652, 412)
    foil.preparar(326, 206)
    p.add_child(foil)
    var pista := GameUI.label(p, "✋  " + I18n.t("scratch_here"), Vector2(104, 174), Vector2(652, 412), 56, Color.WHITE, false, 8)
    _rasca_n = 0
    foil.rascando.connect(_rasca_sonido)
    foil.revelado.connect(_revelado.bind(p, foil, pista))

func _rasca_sonido() -> void:
    _rasca_n += 1
    if _rasca_n % 6 == 1:
        Audio.play("tick", -10.0)

func _revelado(p: Control, foil: Control, pista: Control) -> void:
    Audio.play("win")
    pista.queue_free()
    var tw := create_tween()
    tw.tween_property(foil, "modulate:a", 0.0, 0.45)
    tw.tween_callback(foil.queue_free)
    Voz.decir(I18n.t("your_challenge") + " " + reto)
    GameUI.pill(p, I18n.t("complete"), Vector2(30, 650), Vector2(385, 115), "green", _completar, 36)
    GameUI.pill(p, I18n.t("not_complete"), Vector2(445, 650), Vector2(385, 115), "red", _no_completado.bind(p), 36)

func _no_completado(panel: Control) -> void:
    # El desafío sigue en el mazo: se cierra la ventana y hay que tomar otra carta hasta que salga uno completado.
    GameUI.close_modal(panel)
    Audio.play("whoosh")
    var i: int = Global.current_card
    if i >= 0 and i < card_buttons.size():
        intentadas.append(i)
        var b: Button = card_buttons[i]
        b.disabled = true
        var tw := create_tween().set_parallel(true)
        tw.tween_property(b, "scale", Vector2(0.3, 0.3), 0.3)
        tw.tween_property(b, "modulate:a", 0.0, 0.3)
        await tw.finished
        if not is_inside_tree():
            return
        b.visible = false
    selected = false
    if intentadas.size() >= card_buttons.size():
        # ya se tomaron todas las cartas de la mesa: se reparten de nuevo
        _repartir()

func _mostrar_vacia() -> void:
    Audio.play("chime")
    var p := GameUI.modal(self, Vector2(820, 640), Color("#fbf8ff"))
    GameUI.label(p, "🍀", Vector2(0, 30), Vector2(820, 140), 100)
    GameUI.label(p, I18n.t("saved_title"), Vector2(40, 190), Vector2(740, 100), 62, Color("#2a8f4a"))
    GameUI.label(p, I18n.t("saved_body"), Vector2(60, 300), Vector2(700, 100), 36, Color("#3c3a55"), true)
    GameUI.pill(p, I18n.t("continue"), Vector2(190, 470), Vector2(440, 115), "green", _continuar_vacia, 44)

func _continuar_vacia() -> void:
    get_tree().change_scene_to_file("res://Ruleta.tscn")

func _completar() -> void:
    var idx: int = Global.retos.find(reto)
    if idx >= 0:
        Global.retos.remove_at(idx)
        if not Online.activo:
            Global.completados.append(reto)
    if Online.activo:
        var restantes: Array = []
        for t in Global.retos:
            restantes.append(t)
        await Online.completar(restantes)
        if not is_inside_tree():
            return
        if restantes.is_empty():
            Online.salir()
            get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
        else:
            get_tree().change_scene_to_file("res://Ruleta.tscn")
        return
    if Global.retos.is_empty():
        Global.completados.clear()  # se acabó la partida: hay que registrar desafíos nuevos
    Global.guardar_datos()
    if Global.retos.is_empty():
        get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
    else:
        get_tree().change_scene_to_file("res://Ruleta.tscn")

func _noop() -> void:
    pass

func _salir() -> void:
    Voz.parar()
    if Online.activo:
        get_tree().change_scene_to_file("res://Ruleta.tscn")
        return
    Global.salir_club()
    get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
