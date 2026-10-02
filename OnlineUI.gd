class_name OnlineUI
extends RefCounted
# Ayudas visuales para las pantallas en línea.

static func input(parent: Control, pos: Vector2, size: Vector2, placeholder: String, fs: int = 40, max_len: int = 0) -> LineEdit:
    var e := LineEdit.new()
    e.position = pos
    e.size = size
    e.placeholder_text = placeholder
    if max_len > 0:
        e.max_length = max_len
    e.add_theme_font_size_override("font_size", fs)
    e.add_theme_color_override("font_color", Color.WHITE)
    e.add_theme_color_override("font_placeholder_color", Color("#8f86b8"))
    e.add_theme_color_override("caret_color", Color("#ffe08a"))
    var st := StyleBoxFlat.new()
    st.bg_color = Color("#120d30")
    st.border_color = Color("#7a4be0")
    st.set_border_width_all(3)
    st.set_corner_radius_all(40)
    st.content_margin_left = 30
    st.content_margin_right = 30
    e.add_theme_stylebox_override("normal", st)
    var sf: StyleBoxFlat = st.duplicate() as StyleBoxFlat
    sf.border_color = Color("#f6c343")
    e.add_theme_stylebox_override("focus", sf)
    parent.add_child(e)
    return e

static func selector_color(parent: Control, origen: Vector2, seleccionado: int, cb: Callable) -> Control:
    var caja := Control.new()
    caja.position = origen
    caja.size = Vector2(880, 200)
    parent.add_child(caja)
    for c in range(GameUI.palette_size()):
        var sel: bool = c == seleccionado
        GameUI.dot_button(caja, Vector2(float(c % 8) * 112.0, float(c / 8) * 100.0), 84, GameUI.palette_color(c), Color.WHITE if sel else Color(0, 0, 0, 0.35), 10 if sel else 3, cb.bind(c))
    return caja

static func limpiar(caja: Control) -> void:
    for h in caja.get_children():
        h.queue_free()

static func mensaje_error(codigo: String) -> String:
    match codigo:
        "no_config": return I18n.t("on_err_config")
        "no_existe": return I18n.t("on_err_none")
        "en_juego": return I18n.t("on_err_started")
        "llena": return I18n.t("on_err_full")
        "pocos", "sin_retos": return I18n.t("on_need")
    return I18n.t("on_err_net")
