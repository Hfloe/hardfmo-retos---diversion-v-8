class_name GameUI
extends RefCounted
# Biblioteca de estilos: fondos, marcos neón, botones tipo píldora, tarjetas y ventanas modales.
# Todo se dibuja con StyleBoxFlat, sin texturas externas.

const W := 1080.0
const H := 1920.0
const DARK_TEXT := Color("#1a1033")

# Colores que puede elegir el usuario para los botones (Apariencia). El menú principal nunca cambia.
const TEMA_BOTONES: Array[Color] = [
    Color("#ffc933"), Color("#2f7df0"), Color("#3fd35a"), Color("#8a45f0"),
    Color("#ff3fa4"), Color("#19c8d8"), Color("#ff8a2e"), Color("#f3f4f9")
]
# Velo oscuro de cada fondo (para que el texto se lea): los fondos claros llevan más.
const TEMA_VELOS: Array[float] = [0.18, 0.10, 0.20, 0.10, 0.55, 0.0]

const PALETA: Array[Color] = [
    Color("#f6c343"), Color("#8a4bdc"), Color("#3f6fe0"), Color("#24b4a8"), Color("#e0559f"), Color("#37b45c"),
    Color("#f0524a"), Color("#ff8a3d"), Color("#9be04a"), Color("#22c7e8"), Color("#b06cff"), Color("#ff7ab8"),
    Color("#8c5a3c"), Color("#14a37f"), Color("#d4d4dc"), Color("#6f7cff")
]

static func palette_size() -> int:
    return PALETA.size()

static func palette_color(i: int) -> Color:
    return PALETA[posmod(i, PALETA.size())]

static func avatar_glyph(i: int) -> String:
    var a: Array[String] = ["🤖", "👽", "🚀", "⭐", "🌙"]
    return a[posmod(i, a.size())]

static func _kind(kind: String) -> Array:
    # [color base, color borde/sombra, color texto, borde completo]
    match kind:
        "yellow": return [Color("#ffd23f"), Color("#e0952b"), DARK_TEXT, false]
        "blue": return [Color("#3b7bf0"), Color("#1c4fb8"), Color.WHITE, false]
        "red": return [Color("#f0524a"), Color("#b02a2a"), Color.WHITE, false]
        "gray": return [Color("#8d8d95"), Color("#5f5f68"), Color("#e2e2e8"), false]
        "gold": return [Color("#f6d27a"), Color("#c99a33"), DARK_TEXT, false]
        "purple": return [Color("#7a3df0"), Color("#4b1fb0"), Color.WHITE, false]
        "pink": return [Color("#d95ad0"), Color("#9b2f94"), Color.WHITE, false]
        "white": return [Color("#fff6e4"), Color("#2a4fa0"), Color("#12307a"), false]
        "dark": return [Color("#15112c"), Color("#f4c95d"), Color.WHITE, true]
        "darkblue": return [Color("#15112c"), Color("#3b62c8"), Color.WHITE, true]
        "mint": return [Color("#37e0a4"), Color("#b9c6f2"), Color.WHITE, false]
        "royal": return [Color("#2a50d2"), Color("#cfd8ff"), Color.WHITE, true]
    return [Color("#3fd35a"), Color("#1f8f3a"), Color.WHITE, false]  # green

static func _box(fill: Color, edge: Color, radius: int, bottom: int, full: bool) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = fill
    s.border_color = edge
    if full:
        s.set_border_width_all(5)
    else:
        s.border_width_bottom = bottom
    s.set_corner_radius_all(radius)
    s.shadow_color = Color(0, 0, 0, 0.35)
    s.shadow_size = 8
    s.shadow_offset = Vector2(0, 6)
    return s

# ---------- Fondo y marcos ----------

static func fondo_info(i: int) -> Array:
    # [color superior, color inferior, es_claro]
    match i:
        1: return [Color("#0a0704"), Color("#c8741c"), false]
        2: return [Color("#100636"), Color("#3b1a86"), false]
        3: return [Color("#4aa8f0"), Color("#a9e4ff"), false]
        4: return [Color("#f7a9c4"), Color("#fde3ec"), false]
    return [Color("#0b0204"), Color("#7a0a10"), false]

static func carta_info(i: int) -> Array:
    # [relleno, borde, símbolo]
    match i:
        1: return [Color("#1a1d2e"), Color("#d5dbea"), Color("#e8edf8")]
        2: return [Color("#3a0d1c"), Color("#ff5a7a"), Color("#ffb3c1")]
        3: return [Color("#0b2e26"), Color("#4de0a5"), Color("#b6ffe0")]
        4: return [Color("#0a0a1f"), Color("#21e6ff"), Color("#a5f5ff")]
    return [Color("#120c33"), Color("#f6c343"), Color("#f6d27a")]

static func _imagen_fondo(i: int) -> Texture2D:
    # Si existe res://fondos/fondo_<n>.png|jpg|webp se usa como fondo de ese tema.
    for ext in ["png", "jpg", "jpeg", "webp"]:
        var ruta: String = "res://fondos/fondo_%d.%s" % [i, ext]
        if ResourceLoader.exists(ruta):
            return load(ruta) as Texture2D
    return null

# Pone el fondo elegido por el usuario (Apariencia). Devuelve false si eligió "Original".
static func fondo_usuario(parent: Control) -> bool:
    var n: int = Global.tema_fondo
    if n < 0 or n >= Global.TEMA_NFONDOS:
        return false
    var ruta: String = "res://fondos/tema_%d.jpg" % (n + 1)
    if not ResourceLoader.exists(ruta):
        return false
    var pic := TextureRect.new()
    pic.texture = load(ruta) as Texture2D
    pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(pic)
    GameUI.cubrir(pic)
    if TEMA_VELOS[n] > 0.0:
        var velo := ColorRect.new()
        velo.color = Color(0, 0, 0, TEMA_VELOS[n])
        velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
        parent.add_child(velo)
        GameUI.cubrir(velo)
    return true

# Logo de HardFmo (dorado, fondo transparente). 'alto' = altura en píxeles; se centra en 'centro_x'.
static func logo(parent: Control, centro_x: float, y: float, alto: float) -> TextureRect:
    var ruta := "res://assets/logo_hardfmo.png"
    if not ResourceLoader.exists(ruta):
        return null
    var t := TextureRect.new()
    t.texture = load(ruta) as Texture2D
    t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    t.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var ancho: float = alto * 520.0 / 579.0
    t.position = Vector2(centro_x - ancho / 2.0, y)
    t.size = Vector2(ancho, alto)
    parent.add_child(t)
    return t

# ¿Se le aplica el color de botones del usuario a esta pantalla? (el menú principal se marca con "sin_tema")
static func _tema_activo(parent: Node) -> bool:
    if Global.tema_boton < 0 or Global.tema_boton >= TEMA_BOTONES.size():
        return false
    var n: Node = parent
    while n != null:
        if n.has_meta("sin_tema"):
            return false
        n = n.get_parent()
    return true

# Cambia el color base por el elegido. Los grises/oscuros y los rojos (cancelar, reiniciar) se dejan como están.
static func _tema_color(base: Color, parent: Node, tematizar: bool) -> Color:
    if not tematizar or not _tema_activo(parent):
        return base
    if base.s < 0.25 or base.v < 0.3 or base.h < 0.03 or base.h > 0.97:
        return base
    return TEMA_BOTONES[Global.tema_boton]

static func _texto_sobre(c: Color, original: Color, cambio: bool) -> Color:
    if not cambio:
        return original
    return DARK_TEXT if c.get_luminance() > 0.55 else Color.WHITE

static func bg(parent: Control, _top: Color = Color(), _bottom: Color = Color()) -> void:
    if fondo_usuario(parent):
        return
    var idx: int = Global.fondo_efectivo()
    var img: Texture2D = _imagen_fondo(idx)
    if img != null:
        var pic := TextureRect.new()
        pic.texture = img
        pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
        parent.add_child(pic)
        GameUI.cubrir(pic)
        var velo := ColorRect.new()
        # los fondos claros (azul y rosa) llevan un velo más oscuro para que se lea el texto
        var velo_a: float = 0.3
        if idx == 3:
            velo_a = 0.5
        elif idx == 4:
            velo_a = 0.62
        velo.color = Color(0, 0, 0, velo_a)
        velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
        parent.add_child(velo)
        velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        velo.offset_left = -700
        velo.offset_right = 700
        velo.offset_top = -700
        velo.offset_bottom = 700
    else:
        var info: Array = fondo_info(idx)
        var top: Color = info[0]
        var bottom: Color = info[1]
        var light: bool = info[2]
        var grad := Gradient.new()
        grad.set_color(0, top)
        grad.set_color(1, bottom)
        var tex := GradientTexture2D.new()
        tex.gradient = grad
        tex.width = 8
        tex.height = 256
        tex.fill_from = Vector2(0.5, 0.0)
        tex.fill_to = Vector2(0.5, 1.0)
        var rect := TextureRect.new()
        rect.texture = tex
        rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        rect.stretch_mode = TextureRect.STRETCH_SCALE
        rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        parent.add_child(rect)
        rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        rect.offset_left = -700
        rect.offset_right = 700
        rect.offset_top = -700
        rect.offset_bottom = 700
        if light:
            # Con fondo blanco el contenido va sobre un panel oscuro para que siga siendo legible.
            frame(parent, Rect2(24, 24, 1032, 1872), Color(0, 0, 0, 0), 0, 90, false, Color("#1a1440"))
        parent.add_child(StarField.new())

static func bg_menu(parent: Control) -> void:
    # Mismo fondo de fuego azul del menú principal.
    var ruta := "res://assets/menu_fuego.jpg"
    if not ResourceLoader.exists(ruta):
        bg(parent)
        return
    var pic := TextureRect.new()
    pic.texture = load(ruta) as Texture2D
    pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(pic)
    GameUI.cubrir(pic)

static func watermark(parent: Control) -> void:
    # Marca de agua visible: cápsula oscura + texto dorado grande, abajo del todo.
    var caja := Panel.new()
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.02, 0.03, 0.12, 0.82)
    sb.border_color = Color("#ffd23f")
    sb.set_border_width_all(3)
    sb.set_corner_radius_all(32)
    caja.add_theme_stylebox_override("panel", sb)
    caja.position = Vector2(290, 1846)
    caja.size = Vector2(500, 64)
    caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(caja)
    var wm := Label.new()
    wm.text = "✨ Creado por HardFmo"
    wm.position = Vector2(290, 1846)
    wm.size = Vector2(500, 64)
    wm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    wm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    wm.add_theme_font_size_override("font_size", 38)
    wm.add_theme_color_override("font_color", Color("#ffe566"))
    wm.add_theme_constant_override("outline_size", 8)
    wm.add_theme_color_override("font_outline_color", Color("#050818"))
    wm.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(wm)

static func frame(parent: Control, rect: Rect2, border: Color, width: int = 8, radius: int = 60, glow: bool = true, fill: Color = Color(0, 0, 0, 0)) -> Panel:
    if glow:
        # Brillo hecho con anillos transparentes (la sombra de StyleBoxFlat teñía todo el interior).
        for k in range(1, 4):
            var grow: float = 7.0 * float(k)
            var g := Panel.new()
            g.position = rect.position - Vector2(grow, grow)
            g.size = rect.size + Vector2(grow * 2.0, grow * 2.0)
            g.mouse_filter = Control.MOUSE_FILTER_IGNORE
            var gs := StyleBoxFlat.new()
            gs.bg_color = Color(0, 0, 0, 0)
            gs.border_color = Color(border.r, border.g, border.b, 0.3 / float(k))
            gs.set_border_width_all(7)
            gs.set_corner_radius_all(radius + int(grow))
            g.add_theme_stylebox_override("panel", gs)
            parent.add_child(g)
    var p := Panel.new()
    p.position = rect.position
    p.size = rect.size
    p.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var s := StyleBoxFlat.new()
    s.bg_color = fill
    s.border_color = border
    s.set_border_width_all(width)
    s.set_corner_radius_all(radius)
    p.add_theme_stylebox_override("panel", s)
    parent.add_child(p)
    return p

static func circle(parent: Control, center: Vector2, radius: float, fill: Color, edge: Color, edge_w: int = 6) -> Panel:
    var p := Panel.new()
    p.size = Vector2(radius * 2.0, radius * 2.0)
    p.position = center - Vector2(radius, radius)
    p.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var s := StyleBoxFlat.new()
    s.bg_color = fill
    s.border_color = edge
    s.set_border_width_all(edge_w)
    s.set_corner_radius_all(int(radius))
    p.add_theme_stylebox_override("panel", s)
    parent.add_child(p)
    return p

static func tricolor_bar(parent: Control, x: float, y: float, width: float, height: float = 14.0) -> void:
    var parts: Array[Color] = [Color("#ffd23f"), Color("#2452b8"), Color("#d9342b")]
    var ws: Array[float] = [0.5, 0.25, 0.25]
    var cx := x
    for i in range(3):
        var r := ColorRect.new()
        r.color = parts[i]
        r.position = Vector2(cx, y)
        r.size = Vector2(width * ws[i], height)
        r.mouse_filter = Control.MOUSE_FILTER_IGNORE
        parent.add_child(r)
        cx += width * ws[i]

static func flag(parent: Control, pos: Vector2, sz: Vector2) -> void:
    var f := Control.new()
    f.position = pos
    f.size = sz
    f.rotation = -0.2
    f.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(f)
    var parts: Array[Color] = [Color("#ffd23f"), Color("#2452b8"), Color("#d9342b")]
    var hs: Array[float] = [0.5, 0.25, 0.25]
    var cy := 0.0
    for i in range(3):
        var r := ColorRect.new()
        r.color = parts[i]
        r.position = Vector2(0, cy)
        r.size = Vector2(sz.x, sz.y * hs[i])
        r.mouse_filter = Control.MOUSE_FILTER_IGNORE
        f.add_child(r)
        cy += sz.y * hs[i]

# ---------- Textos ----------

static func label(parent: Control, text: String, pos: Vector2, sz: Vector2, font_size: int = 32, color: Color = Color.WHITE, envolver: bool = false, outline: int = 0) -> Label:
    var l := Label.new()
    l.text = text
    l.position = pos
    l.size = sz
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", color)
    if outline > 0:
        l.add_theme_constant_override("outline_size", outline)
        l.add_theme_color_override("font_outline_color", Color("#1b0c4d"))
    else:
        # sombra suave para que las letras claras se lean sobre cualquier fondo
        l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
        l.add_theme_constant_override("shadow_offset_x", 0)
        l.add_theme_constant_override("shadow_offset_y", 3)
    if envolver:
        l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(l)
    return l

static func label3d(parent: Control, text: String, pos: Vector2, sz: Vector2, font_size: int, face: Color, side: Color, depth: int = 8, outline: Color = Color("#1b0c4d")) -> Label:
    # Letras con volumen: varias capas desplazadas hacia abajo (el lado oscuro) y la cara clara arriba.
    for d in range(depth, 0, -1):
        var c: Color = side.darkened(float(d) / float(depth) * 0.35)
        var capa := label(parent, text, pos + Vector2(0, d), sz, font_size, c, false, 6)
        capa.add_theme_color_override("font_outline_color", c)
    var top := label(parent, text, pos, sz, font_size, face, false, 6)
    top.add_theme_color_override("font_outline_color", outline)
    return top

static func flat_box(fill: Color, edge: Color, radius: int, edge_w: int) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = fill
    s.border_color = edge
    s.set_border_width_all(edge_w)
    s.set_corner_radius_all(radius)
    return s

static func flat_button(parent: Control, pos: Vector2, sz: Vector2, fill: Color, edge: Color, callback: Callable, radius: int = 44, edge_w: int = 3) -> Button:
    var b := Button.new()
    b.position = pos
    b.size = sz
    b.focus_mode = Control.FOCUS_NONE
    b.add_theme_stylebox_override("normal", flat_box(fill, edge, radius, edge_w))
    b.add_theme_stylebox_override("hover", flat_box(fill.lightened(0.08), edge, radius, edge_w))
    b.add_theme_stylebox_override("pressed", flat_box(fill.darkened(0.12), edge, radius, edge_w))
    b.add_theme_stylebox_override("disabled", flat_box(fill, edge, radius, edge_w))
    b.pressed.connect(callback)
    parent.add_child(b)
    return b

static func left_label(parent: Control, text: String, pos: Vector2, sz: Vector2, font_size: int, color: Color, envolver: bool = true) -> Label:
    var l := label(parent, text, pos, sz, font_size, color, envolver)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    return l

static func neon_modal(parent: Control, panel_size: Vector2) -> Panel:
    # Ventana oscura con doble borde neón azul.
    var p := modal(parent, panel_size, Color("#070a14"))
    var s := flat_box(Color("#070a14"), Color("#3ba0ff"), 64, 7)
    s.shadow_color = Color(0.2, 0.5, 1.0, 0.55)
    s.shadow_size = 34
    p.add_theme_stylebox_override("panel", s)
    frame(p, Rect2(26, 26, panel_size.x - 52, panel_size.y - 52), Color("#2b6fd6"), 3, 44, false)
    return p

static func title(parent: Control, text: String, y: float, font_size: int = 60) -> Label:
    return label(parent, text, Vector2(60, y), Vector2(960, 120), font_size, Color("#ffe08a"), false, 8)

static func subtitle(parent: Control, text: String, y: float) -> Label:
    return label(parent, text, Vector2(90, y), Vector2(900, 80), 28, Color("#d6c7ff"), true)

static func banner(parent: Control, text: String, pos: Vector2, sz: Vector2) -> Panel:
    var p := Panel.new()
    p.position = pos
    p.size = sz
    p.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var s := StyleBoxFlat.new()
    s.bg_color = Color("#fffdf6")
    s.border_color = Color("#ffc933")
    s.set_border_width_all(10)
    s.set_corner_radius_all(int(sz.y / 2.0))
    s.shadow_color = Color(0, 0, 0, 0.4)
    s.shadow_size = 12
    s.shadow_offset = Vector2(0, 8)
    p.add_theme_stylebox_override("panel", s)
    parent.add_child(p)
    label(p, text, Vector2(60, 0), Vector2(sz.x - 60, sz.y), 84, Color("#12307a"))
    return p

# ---------- Botones ----------

static func pill(parent: Control, text: String, pos: Vector2, sz: Vector2, kind: String, callback: Callable, font_size: int = 42, stripes: bool = false, corner: int = -1, outline: Color = Color(0, 0, 0, 0), tematizar: bool = true) -> Button:
    var k: Array = _kind(kind)
    var base: Color = k[0]
    var edge: Color = k[1]
    var fc: Color = k[2]
    var full: bool = k[3]
    var cambiado: Color = _tema_color(base, parent, tematizar)
    if cambiado != base:
        base = cambiado
        edge = base.darkened(0.38)
        fc = _texto_sobre(base, fc, true)
    var radius: int = corner if corner >= 0 else int(sz.y / 2.0)
    var b := Button.new()
    b.text = text
    b.position = pos
    b.size = sz
    b.focus_mode = Control.FOCUS_NONE
    b.add_theme_font_size_override("font_size", font_size)
    for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
        b.add_theme_color_override(c, fc)
    if outline.a > 0.0:
        b.add_theme_constant_override("outline_size", 7)
        b.add_theme_color_override("font_outline_color", outline)
    b.add_theme_stylebox_override("normal", _box(base, edge, radius, 12, full))
    b.add_theme_stylebox_override("hover", _box(base.lightened(0.12), edge, radius, 12, full))
    b.add_theme_stylebox_override("pressed", _box(base.darkened(0.12), edge, radius, 4, full))
    b.add_theme_stylebox_override("disabled", _box(base, edge, radius, 12, full))
    if stripes:
        var parts: Array[Color] = [Color("#ffd23f"), Color("#2452b8"), Color("#e0453a")]
        for i in range(3):
            var r := ColorRect.new()
            r.color = parts[i]
            r.position = Vector2(radius * 0.8, sz.y - 21 + i * 6)
            r.size = Vector2(sz.x - radius * 1.6, 6)
            r.mouse_filter = Control.MOUSE_FILTER_IGNORE
            b.add_child(r)
    b.pressed.connect(callback)
    parent.add_child(b)
    return b

static func dot_button(parent: Control, pos: Vector2, diameter: float, fill: Color, edge: Color, edge_w: int, callback: Callable) -> Button:
    var b := Button.new()
    b.position = pos
    b.size = Vector2(diameter, diameter)
    b.focus_mode = Control.FOCUS_NONE
    var s := StyleBoxFlat.new()
    s.bg_color = fill
    s.border_color = edge
    s.set_border_width_all(edge_w)
    s.set_corner_radius_all(int(diameter / 2.0))
    for st in ["normal", "hover", "pressed", "disabled"]:
        b.add_theme_stylebox_override(st, s)
    b.pressed.connect(callback)
    parent.add_child(b)
    return b

# ---------- Ventana modal ----------

static func modal(parent: Control, panel_size: Vector2, fill: Color = Color.WHITE) -> Panel:
    var overlay := ColorRect.new()
    overlay.color = Color(0, 0, 0, 0.72)
    parent.add_child(overlay)
    cubrir(overlay)   # el fondo oscuro cubre toda la pantalla
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    var p := Panel.new()
    p.size = panel_size
    # el panel va centrado en el área de diseño 1080x1920; se descuenta la posición del overlay (que es negativa)
    p.position = Vector2((W - panel_size.x) / 2.0, (H - panel_size.y) / 2.0 - 40.0) - overlay.position
    var s := StyleBoxFlat.new()
    s.bg_color = fill
    s.border_color = Color("#9b6bff")
    s.set_border_width_all(6)
    s.set_corner_radius_all(56)
    s.shadow_color = Color(0.6, 0.4, 1.0, 0.5)
    s.shadow_size = 30
    p.add_theme_stylebox_override("panel", s)
    overlay.add_child(p)
    return p

static func close_modal(panel: Control) -> void:
    panel.get_parent().queue_free()

# ---------- Fondo con imagen propia ----------

static func bg_img(parent: Control, ruta: String) -> void:
    if fondo_usuario(parent):
        return
    bg_fijo(parent, ruta)

# Fondo que NO cambia con la personalización (lo usa el menú principal).
static func bg_fijo(parent: Control, ruta: String) -> void:
    if not ResourceLoader.exists(ruta):
        bg(parent)
        return
    var pic := TextureRect.new()
    pic.texture = load(ruta) as Texture2D
    pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(pic)
    GameUI.cubrir(pic)

# ---------- Botón brillante (estilo de las pantallas nuevas) ----------

static func _caja_brillo(base: Color, radio: int) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = base
    s.border_color = base.darkened(0.38)
    s.border_width_bottom = 9
    s.set_corner_radius_all(radio)
    s.shadow_color = Color(0, 0, 0, 0.45)
    s.shadow_size = 8
    s.shadow_offset = Vector2(0, 6)
    return s

static func glossy(parent: Control, text: String, pos: Vector2, sz: Vector2, base: Color, txt: Color, callback: Callable, font_size: int = 44, radio: int = 46, tematizar: bool = true) -> Button:
    var nuevo: Color = _tema_color(base, parent, tematizar)
    if nuevo != base:
        base = nuevo
        txt = _texto_sobre(base, txt, true)
    var b := Button.new()
    b.text = text
    b.position = pos
    b.size = sz
    b.focus_mode = Control.FOCUS_NONE
    b.add_theme_font_size_override("font_size", font_size)
    for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
        b.add_theme_color_override(c, txt)
    b.add_theme_stylebox_override("normal", _caja_brillo(base, radio))
    b.add_theme_stylebox_override("hover", _caja_brillo(base.lightened(0.1), radio))
    b.add_theme_stylebox_override("pressed", _caja_brillo(base.darkened(0.12), radio))
    b.add_theme_stylebox_override("disabled", _caja_brillo(base, radio))
    # brillo superior (reflejo)
    var brillo := Panel.new()
    var bs := StyleBoxFlat.new()
    bs.bg_color = Color(1, 1, 1, 0.26)
    bs.set_corner_radius_all(int(sz.y * 0.2))
    brillo.add_theme_stylebox_override("panel", bs)
    brillo.position = Vector2(sz.y * 0.28, 8)
    brillo.size = Vector2(sz.x - sz.y * 0.56, sz.y * 0.34)
    brillo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    b.add_child(brillo)
    b.pressed.connect(callback)
    parent.add_child(b)
    return b

# ---------- Botón para silenciar / activar la lectura en voz alta ----------

static func voz_boton(parent: Control, pos: Vector2, diametro: float = 92.0) -> Button:
    var b := Button.new()
    b.position = pos
    b.size = Vector2(diametro, diametro)
    b.focus_mode = Control.FOCUS_NONE
    b.text = "🔊" if Global.voz else "🔇"
    b.add_theme_font_size_override("font_size", int(diametro * 0.48))
    var s := StyleBoxFlat.new()
    s.bg_color = Color(0.06, 0.05, 0.14, 0.88)
    s.border_color = Color("#ffd23f")
    s.set_border_width_all(4)
    s.set_corner_radius_all(int(diametro / 2.0))
    for st in ["normal", "hover", "pressed", "disabled"]:
        b.add_theme_stylebox_override(st, s)
    b.pressed.connect(_alternar_voz.bind(b))
    parent.add_child(b)
    return b

static func _alternar_voz(b: Button) -> void:
    Voz.alternar()
    b.text = "🔊" if Global.voz else "🔇"

# Fondo de las pantallas de juego: el diseño propio, salvo que en el Club Privado se haya elegido otro tema.
static func bg_tema(parent: Control, ruta: String) -> void:
    bg_img(parent, ruta)

# Hace que una imagen de fondo cubra TODA la pantalla del teléfono (aunque sea más alta que 1080 x 1920),
# sin deformarse: se recorta por los bordes. Funciona junto con Ajuste.gd, que centra el contenido.
static func cubrir(c: Control) -> void:
    var vis: Vector2 = (Engine.get_main_loop() as SceneTree).root.get_visible_rect().size
    vis = Vector2(maxf(vis.x, 1080.0), maxf(vis.y, 1920.0))
    var d := Vector2((vis.x - 1080.0) / 2.0, (vis.y - 1920.0) / 2.0)
    c.set_anchors_preset(Control.PRESET_TOP_LEFT)
    c.position = -d
    c.size = vis
