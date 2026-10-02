class_name Donacion
extends RefCounted
# Utilidades visuales premium para la pantalla y el popup de donación.

const ORO := Color("#e8b94a")
const ORO_OSC := Color("#a87a24")
const ORO_CLARO := Color("#fff0a8")
const AZUL_OSC := Color("#1a2a5a")

const SHADER_BLUR := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
void fragment() {
    vec4 c = textureLod(screen_tex, SCREEN_UV, 3.0);
    COLOR = vec4(c.rgb * 0.38, 1.0);
}
"""

# ---------- Diamante brillante ----------
class Gema extends Control:
    var r: float = 30.0
    func _draw() -> void:
        var c := Vector2.ZERO
        var w: float = r * 0.82
        var oro := PackedVector2Array([c + Vector2(0, -r), c + Vector2(w, 0), c + Vector2(0, r), c + Vector2(-w, 0)])
        draw_colored_polygon(oro, Color("#c99a33"))
        var k: float = 0.74
        var top := c + Vector2(0, -r * k)
        var der := c + Vector2(w * k, 0)
        var bot := c + Vector2(0, r * k)
        var izq := c + Vector2(-w * k, 0)
        draw_colored_polygon(PackedVector2Array([top, der, bot, izq]), Color("#f4fbff"))
        draw_colored_polygon(PackedVector2Array([top, c, izq]), Color("#ffffff"))
        draw_colored_polygon(PackedVector2Array([top, der, c]), Color("#dff0ff"))
        draw_colored_polygon(PackedVector2Array([izq, c, bot]), Color("#cfe3f5"))
        draw_colored_polygon(PackedVector2Array([c, der, bot]), Color("#b9d4ee"))
        draw_polyline(PackedVector2Array([top, der, bot, izq, top]), Color("#f6d27a"), 2.0)
        # destello
        var s: float = r * 0.5
        draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.9, -s * 0.9) + Vector2(0, -s * 0.5), c + Vector2(-s * 0.9, -s * 0.9) + Vector2(s * 0.12, 0), c + Vector2(-s * 0.9, -s * 0.9) + Vector2(0, s * 0.5), c + Vector2(-s * 0.9, -s * 0.9) + Vector2(-s * 0.12, 0)]), Color(1, 1, 1, 0.9))

# ---------- Borde de perlas/diamantes pequeños ----------
class BordePerlas extends Control:
    var margen: float = 26.0
    var radio_esq: float = 18.0
    func _draw() -> void:
        var rect := Rect2(Vector2(margen, margen), size - Vector2(margen, margen) * 2.0)
        draw_rect(rect, Color("#e8b94a"), false, 3.0)
        var rect2 := rect.grow(-16.0)
        draw_rect(rect2, Color("#f6d27a"), false, 2.0)
        var paso: float = 24.0
        var x: float = rect.position.x + 24.0
        while x <= rect.end.x - 24.0:
            _perla(Vector2(x, rect.position.y + 8.0))
            _perla(Vector2(x, rect.end.y - 8.0))
            x += paso
        var y: float = rect.position.y + 24.0
        while y <= rect.end.y - 24.0:
            _perla(Vector2(rect.position.x + 8.0, y))
            _perla(Vector2(rect.end.x - 8.0, y))
            y += paso

    func _perla(p: Vector2) -> void:
        draw_circle(p, 7.5, Color("#d9a63c"))
        draw_circle(p, 5.5, Color("#fffdf2"))
        draw_circle(p + Vector2(-1.5, -1.5), 2.0, Color(1, 1, 1, 1))

# ---------- Marco ornamental dorado (pantalla completa) ----------
class MarcoOrnamental extends Control:
    func _draw() -> void:
        var m: float = 26.0
        var rect := Rect2(Vector2(m, m), size - Vector2(m, m) * 2.0)
        draw_rect(rect, Color("#f6d27a"), false, 6.0)
        draw_rect(rect.grow(-16.0), Color("#c99a33"), false, 2.5)
        draw_rect(rect.grow(-30.0), Color(0.96, 0.82, 0.4, 0.45), false, 1.5)
        var esq: Array[Vector2] = [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
        var ang: Array[float] = [PI, PI * 1.5, 0.0, PI * 0.5]
        for i in range(4):
            var c: Vector2 = esq[i] + Vector2(1 if i == 0 or i == 3 else -1, 1 if i < 2 else -1) * 46.0
            draw_arc(c, 34.0, ang[i], ang[i] + PI * 0.5, 20, Color("#ffd867"), 5.0)
            draw_arc(c, 60.0, ang[i], ang[i] + PI * 0.5, 24, Color("#c99a33"), 3.0)
            draw_circle(c, 9.0, Color("#ffe08a"))
            draw_circle(c, 5.0, Color("#c99a33"))
        # destellos dorados pequeños a lo largo del borde
        for i in range(10):
            var t: float = float(i + 1) / 11.0
            draw_circle(Vector2(lerpf(rect.position.x, rect.end.x, t), rect.position.y), 3.0, Color("#fff0a8"))
            draw_circle(Vector2(lerpf(rect.position.x, rect.end.x, t), rect.end.y), 3.0, Color("#fff0a8"))

static func gema(parent: Control, centro: Vector2, radio: float) -> Control:
    var g := Gema.new()
    g.r = radio
    g.position = centro
    g.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(g)
    return g

static func marco_ornamental(parent: Control, tam: Vector2) -> void:
    var m := MarcoOrnamental.new()
    m.size = tam
    m.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(m)

static func tex(ruta: String) -> Texture2D:
    if ResourceLoader.exists(ruta):
        return load(ruta) as Texture2D
    return null

# ---------- Botón con esquinas redondeadas (color plano) ----------
static func boton(parent: Control, etiqueta: String, pos: Vector2, tam: Vector2, color: Color, cb: Callable, fs: int, radio: int = 20) -> Button:
    var b := Button.new()
    b.text = etiqueta
    b.position = pos
    b.size = tam
    b.focus_mode = Control.FOCUS_NONE
    b.add_theme_font_size_override("font_size", fs)
    for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
        b.add_theme_color_override(c, Color.WHITE)
    b.add_theme_constant_override("outline_size", 4)
    b.add_theme_color_override("font_outline_color", color.darkened(0.45))
    b.add_theme_stylebox_override("normal", _caja(color, radio))
    b.add_theme_stylebox_override("hover", _caja(color.lightened(0.1), radio))
    b.add_theme_stylebox_override("pressed", _caja(color.darkened(0.12), radio))
    b.pressed.connect(cb)
    parent.add_child(b)
    return b

static func _caja(color: Color, radio: int) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = color
    s.border_color = color.lightened(0.35)
    s.set_border_width_all(3)
    s.set_corner_radius_all(radio)
    s.shadow_color = Color(0, 0, 0, 0.25)
    s.shadow_size = 8
    s.shadow_offset = Vector2(0, 5)
    return s

# ---------- Popup premium ----------
# Devuelve el panel blanco; el overlay (blur oscuro) es su padre.
static func popup(parent: Control, tam: Vector2) -> Panel:
    var overlay := ColorRect.new()
    overlay.color = Color(0, 0, 0, 0.6)
    var sh := Shader.new()
    sh.code = SHADER_BLUR
    var mat := ShaderMaterial.new()
    mat.shader = sh
    overlay.material = mat
    parent.add_child(overlay)
    GameUI.cubrir(overlay)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP

    var p := Panel.new()
    p.size = tam
    p.position = Vector2((GameUI.W - tam.x) / 2.0, (GameUI.H - tam.y) / 2.0 - 40.0) - overlay.position
    var s := StyleBoxFlat.new()
    s.bg_color = Color("#fffef8")
    s.border_color = Color("#d9a63c")
    s.set_border_width_all(8)
    s.set_corner_radius_all(30)
    s.shadow_color = Color(1.0, 0.85, 0.35, 0.55)
    s.shadow_size = 38
    p.add_theme_stylebox_override("panel", s)
    overlay.add_child(p)

    var borde := BordePerlas.new()
    borde.size = tam
    borde.mouse_filter = Control.MOUSE_FILTER_IGNORE
    p.add_child(borde)
    # 4 diamantes grandes en las esquinas + 4 medianos en los centros de cada lado
    var e: float = 26.0
    for pos in [Vector2(e, e), Vector2(tam.x - e, e), Vector2(tam.x - e, tam.y - e), Vector2(e, tam.y - e)]:
        gema(p, pos, 46.0)
    for pos2 in [Vector2(tam.x / 2.0, e), Vector2(tam.x / 2.0, tam.y - e), Vector2(e, tam.y / 2.0), Vector2(tam.x - e, tam.y / 2.0)]:
        gema(p, pos2, 26.0)
    return p

static func texto(parent: Control, t: String, pos: Vector2, tam: Vector2, fs: int, color: Color, negrita: bool = false, envolver: bool = false) -> Label:
    var l := Label.new()
    l.text = t
    l.position = pos
    l.size = tam
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size", fs)
    l.add_theme_color_override("font_color", color)
    if negrita:
        @warning_ignore("integer_division")
        l.add_theme_constant_override("outline_size", maxi(2, fs / 24))
        l.add_theme_color_override("font_outline_color", color)
    if envolver:
        l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.clip_text = true
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(l)
    _ajustar(l, tam, fs)
    return l

# Reduce la letra hasta que el texto quepa dentro del recuadro (no se sale del banner, en cualquier idioma).
static func _ajustar(l: Label, tam: Vector2, fs: int) -> void:
    var fuente: Font = l.get_theme_font("font")
    if fuente == null:
        return
    var ancho: float = tam.x * 0.96
    var size_actual: int = fs
    while size_actual > 16:
        var ancho_wrap: float = ancho if l.autowrap_mode != TextServer.AUTOWRAP_OFF else -1.0
        var medida: Vector2 = fuente.get_multiline_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, ancho_wrap, size_actual)
        if medida.y <= tam.y * 0.96 and medida.x <= ancho:
            break
        size_actual -= 2
    l.add_theme_font_size_override("font_size", size_actual)
    if l.get_theme_constant("outline_size") > 0:
        @warning_ignore("integer_division")
        l.add_theme_constant_override("outline_size", maxi(2, size_actual / 24))

# ---------- Anuncio de donación (al entrar al juego y cada 5 giros de la ruleta) ----------
# variante 0 = bienvenida · 1 = ruleta. "volver" = escena a la que regresa la pantalla de donación.
# Devuelve el panel; se puede esperar con: await p.tree_exited
static func anuncio(parent: Control, volver: String, variante: int = 0) -> Panel:
    var tam := Vector2(900, 1290 if variante != 0 else 1500)
    var p := popup(parent, tam)
    var s := StyleBoxFlat.new()
    s.bg_color = Color("#0a0a10")
    s.border_color = Color("#d9a63c")
    s.set_border_width_all(8)
    s.set_corner_radius_all(30)
    s.shadow_color = Color(1.0, 0.85, 0.35, 0.55)
    s.shadow_size = 38
    p.add_theme_stylebox_override("panel", s)
    GameUI.logo(p, tam.x / 2.0, 65.0, 200.0)
    if variante == 0:
        # Anuncio del menú principal: "¿Le das una vida extra a HARDFMO-RETOS & DIVERSION?"
        texto(p, I18n.t("ann_title"), Vector2(40, 272), Vector2(820, 140), 46, ORO_CLARO, true, true)
        texto(p, I18n.t("ann_p1"), Vector2(60, 418), Vector2(780, 160), 32, Color.WHITE, false, true)
        var lista0 := texto(p, I18n.t("ann_list"), Vector2(120, 590), Vector2(700, 230), 34, ORO_CLARO)
        lista0.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        # por qué y para qué es la donación
        texto(p, I18n.t("ann_why_t"), Vector2(40, 830), Vector2(820, 60), 38, ORO, true)
        texto(p, I18n.t("ann_why"), Vector2(70, 895), Vector2(760, 130), 29, Color.WHITE, false, true)
        texto(p, I18n.t("ann_for_t"), Vector2(40, 1040), Vector2(820, 60), 38, ORO, true)
        texto(p, I18n.t("ann_for"), Vector2(70, 1105), Vector2(760, 130), 29, Color.WHITE, false, true)
        texto(p, I18n.t("ann_p2"), Vector2(60, 1245), Vector2(780, 90), 30, ORO_CLARO, false, true)
    else:
        texto(p, "💗 CADA PESO CUENTA 💗", Vector2(40, 280), Vector2(820, 80), 54, ORO_CLARO, true)
        var cuerpo: String = "¡Ya llevas 5 giros! Si te estás divirtiendo, tu donación, por pequeña que sea, me ayuda a seguir mejorando el juego."
        texto(p, cuerpo, Vector2(70, 375), Vector2(760, 230), 37, Color.WHITE, false, true)
        texto(p, "¿EN QUÉ SE VA TU DONACIÓN?", Vector2(40, 625), Vector2(820, 70), 42, ORO, true)
        var lista := texto(p, "🌐  Activar el modo EN LÍNEA\n📲  Subir el juego a Play Store\n🧠  Añadir más niveles y áreas", Vector2(130, 710), Vector2(700, 210), 37, Color.WHITE)
        lista.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        texto(p, "Aunque sea poquito, ¡me ayudas a seguir! Gracias de corazón 🙏", Vector2(70, 940), Vector2(760, 110), 34, ORO_CLARO, false, true)
    var y_botones: float = 1065.0 if variante != 0 else 1345.0
    boton(p, "💚 Donar Ahora", Vector2(55, y_botones), Vector2(390, 125), Color("#2fc24f"), _ir_donar.bind(p, volver), 40, 50)
    boton(p, "Seguir Jugando", Vector2(455, y_botones), Vector2(390, 125), Color("#5d5d68"), GameUI.close_modal.bind(p), 40, 50)
    return p

static func _ir_donar(p: Control, volver: String) -> void:
    Global.volver_a = volver
    p.get_tree().change_scene_to_file("res://Paywall.tscn")
