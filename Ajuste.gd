extends Node
# Autoload: ajusta el juego a la pantalla del teléfono.
# El diseño es 1080 x 1920. Si la pantalla es más alta o más ancha, el juego usa todo el espacio
# (sin franjas negras), centra el contenido y los fondos se estiran hasta los bordes.

const BASE := Vector2(1080, 1920)

func _ready() -> void:
    get_tree().root.size_changed.connect(_centrar)
    _centrar()

func _centrar() -> void:
    var vis: Vector2 = get_tree().root.get_visible_rect().size
    var dx: float = maxf(0.0, (vis.x - BASE.x) / 2.0)
    var dy: float = maxf(0.0, (vis.y - BASE.y) / 2.0)
    get_tree().root.canvas_transform = Transform2D(0.0, Vector2(dx, dy))
