class_name StarField
extends Control
# Fondo de estrellas dibujado por código (no requiere texturas externas).

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    offset_left = -700
    offset_right = 700
    offset_top = -700
    offset_bottom = 700
    resized.connect(queue_redraw)

func _draw() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 20260928
    var tints: Array[Color] = [Color(1, 1, 1, 0.7), Color(0.96, 0.78, 0.36, 0.7), Color(0.7, 0.5, 1.0, 0.6)]
    for i in range(150):
        var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
        draw_circle(p, rng.randf_range(1.2, 3.8), tints[rng.randi() % 3])
    for i in range(14):
        var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
        var r := rng.randf_range(10.0, 20.0)
        var col := Color(0.96, 0.82, 0.45, 0.55)
        draw_line(p - Vector2(r, 0), p + Vector2(r, 0), col, 2.5)
        draw_line(p - Vector2(0, r), p + Vector2(0, r), col, 2.5)
