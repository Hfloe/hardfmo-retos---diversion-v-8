class_name RuletaRueda
extends Control
# Ruleta con una porción por participante (número grande sobre el color de cada uno), aro dorado y centro metálico.
# La porción i ocupa desde i*paso hasta (i+1)*paso, medido en sentido horario desde arriba.
# "ids" son los participantes que siguen en la ruleta: en el Club Privado se van eliminando.

var count: int = 1
var ids: Array[int] = []

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    pivot_offset = size / 2.0
    if ids.is_empty():
        for i in range(maxi(Global.n_jugadores(), 1)):
            ids.append(i)
    count = maxi(ids.size(), 1)
    _crear_etiquetas()

# Reconstruye la ruleta con los participantes que quedan (vuelve a la posición inicial).
func set_ids(nuevos: Array) -> void:
    ids.clear()
    for v in nuevos:
        ids.append(int(v))
    count = maxi(ids.size(), 1)
    for ch in get_children():
        remove_child(ch)
        ch.queue_free()
    rotation = 0.0
    _crear_etiquetas()
    queue_redraw()

func slice_angle() -> float:
    return TAU / float(count)

func _color_de_porcion(i: int) -> Color:
    if ids.is_empty():
        return Global.color_de(i)
    return Global.color_de(ids[i])

func _draw() -> void:
    var c := size / 2.0
    var r: float = minf(size.x, size.y) / 2.0
    var inner: float = r * 0.87
    # aro dorado con volumen
    draw_circle(c, r, Color("#5e3f0c"))
    draw_circle(c, r * 0.985, Color("#c98f26"))
    draw_circle(c, r * 0.95, Color("#f8dc8a"))
    draw_circle(c, r * 0.915, Color("#b27a1c"))
    draw_circle(c, r * 0.895, Color("#ffe9a6"))
    var step: float = slice_angle()
    if count == 1:
        draw_circle(c, inner, _color_de_porcion(0))
    else:
        var arc_pts: int = maxi(6, int(step / 0.1))
        for i in range(count):
            var a0: float = i * step - PI / 2.0
            var pts := PackedVector2Array([c])
            for s in range(arc_pts + 1):
                var a: float = a0 + step * float(s) / float(arc_pts)
                pts.append(c + Vector2(cos(a), sin(a)) * inner)
            var col: Color = _color_de_porcion(i)
            draw_colored_polygon(pts, col)
            # reflejo suave en la mitad exterior de cada porción
            var brillo := PackedVector2Array()
            for s in range(arc_pts + 1):
                var a2: float = a0 + step * float(s) / float(arc_pts)
                brillo.append(c + Vector2(cos(a2), sin(a2)) * inner)
            for s in range(arc_pts, -1, -1):
                var a3: float = a0 + step * float(s) / float(arc_pts)
                brillo.append(c + Vector2(cos(a3), sin(a3)) * inner * 0.62)
            draw_colored_polygon(brillo, Color(1, 1, 1, 0.1))
            draw_line(c, c + Vector2(cos(a0), sin(a0)) * inner, Color("#fff1b8"), 3.0)
    draw_arc(c, inner, 0.0, TAU, 160, Color("#ffe9a6"), 5.0)
    # centro metálico
    draw_circle(c, inner * 0.2, Color("#7a520f"))
    draw_circle(c, inner * 0.17, Color("#f6d27a"))
    draw_circle(c, inner * 0.12, Color("#c8902a"))
    draw_circle(c, inner * 0.07, Color("#fff0a8"))
    draw_circle(c - Vector2(inner * 0.025, inner * 0.03), inner * 0.03, Color(1, 1, 1, 0.85))
    for i in range(24):
        var ang: float = i * TAU / 24.0
        draw_circle(c + Vector2(cos(ang), sin(ang)) * r * 0.932, 5.0, Color("#fff8d6"))

func _crear_etiquetas() -> void:
    var c := size / 2.0
    var r: float = minf(size.x, size.y) / 2.0
    var inner: float = r * 0.87
    var step: float = slice_angle()
    for i in range(count):
        var holder := Control.new()
        holder.position = c
        holder.rotation = (float(i) + 0.5) * step
        holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(holder)
        var numero: int = (ids[i] if i < ids.size() else i) + 1
        var d_n: float = inner * (0.66 if count <= 2 else 0.74)
        if count == 1:
            d_n = 0.0
        var arc: float = TAU * d_n / float(count)
        var fs: int = clampi(int(arc * 0.6), 28, 88)
        if count == 1:
            fs = 110
        var box: float = float(fs) * 1.7
        var num := _etiqueta(str(numero), fs)
        num.size = Vector2(box, box)
        num.position = Vector2(-box / 2.0, -d_n - box / 2.0)
        holder.add_child(num)

func _etiqueta(texto: String, font_size: int) -> Label:
    var l := Label.new()
    l.text = texto
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", Color.WHITE)
    @warning_ignore("integer_division")
    l.add_theme_constant_override("outline_size", clampi(font_size / 6, 4, 10))
    l.add_theme_color_override("font_outline_color", Color(0.12, 0.05, 0.25, 0.55))
    l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
    l.add_theme_constant_override("shadow_offset_x", 2)
    l.add_theme_constant_override("shadow_offset_y", 4)
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return l
