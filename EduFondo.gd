class_name EduFondo
extends RefCounted
# Fondo de cada categoría educativa. Zootecnia usa res://assets/zoo_fondo.jpg (cámbiala por tu propia imagen).
# Si no existe la imagen de la categoría se usa el fondo normal del juego.

static func aplicar(parent: Control, id: String) -> void:
    var ruta := "res://assets/%s_fondo.jpg" % ("zoo" if id == "zootecnia" else id)
    if ResourceLoader.exists(ruta):
        var t := TextureRect.new()
        t.texture = load(ruta) as Texture2D
        t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        t.mouse_filter = Control.MOUSE_FILTER_IGNORE
        parent.add_child(t)
        GameUI.cubrir(t)
    else:
        GameUI.bg(parent)
