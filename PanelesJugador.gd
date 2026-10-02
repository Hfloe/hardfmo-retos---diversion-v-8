class_name PanelesJugador
extends Node
# Ventanas del menú principal: Perfil, Estadísticas y Puntos. Se añade como hijo del menú (raiz = su padre).

var raiz: Control

func _ready() -> void:
    raiz = get_parent() as Control

# ---------- Avatar circular (foto o emoji) ----------
const SHADER_CIRCULO := "shader_type canvas_item;\nvoid fragment() {\n\tfloat d = length(UV - vec2(0.5));\n\tCOLOR = texture(TEXTURE, UV);\n\tCOLOR.a *= smoothstep(0.5, 0.485, d);\n}\n"

func _avatar(padre: Control, pos: Vector2, diam: float) -> void:
    if Jugador.tiene_foto():
        var img := Image.load_from_file(Jugador.FOTO)
        var foto_rect := TextureRect.new()
        foto_rect.texture = ImageTexture.create_from_image(img)
        foto_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        foto_rect.stretch_mode = TextureRect.STRETCH_SCALE
        foto_rect.position = pos
        foto_rect.size = Vector2(diam, diam)
        foto_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var sh := Shader.new()
        sh.code = SHADER_CIRCULO
        var mat := ShaderMaterial.new()
        mat.shader = sh
        foto_rect.material = mat
        padre.add_child(foto_rect)
    else:
        var c := Panel.new()
        c.position = pos
        c.size = Vector2(diam, diam)
        c.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var col := Color(Jugador.COLORES_AVATAR[Jugador.avatar() % Jugador.COLORES_AVATAR.size()])
        c.add_theme_stylebox_override("panel", GameUI.flat_box(col.darkened(0.35), col, int(diam / 2.0), 0))
        padre.add_child(c)
        GameUI.label(c, Jugador.AVATARES[Jugador.avatar()], Vector2.ZERO, c.size, int(diam * 0.6))
    var aro := Panel.new()
    aro.position = pos
    aro.size = Vector2(diam, diam)
    aro.mouse_filter = Control.MOUSE_FILTER_IGNORE
    aro.add_theme_stylebox_override("panel", GameUI.flat_box(Color(0, 0, 0, 0), Color("#ffd23f"), int(diam / 2.0), 8))
    padre.add_child(aro)

func _barra(padre: Control, pos: Vector2, sz: Vector2, frac: float, color: Color) -> void:
    var fondo := Panel.new()
    fondo.position = pos
    fondo.size = sz
    fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    fondo.add_theme_stylebox_override("panel", GameUI.flat_box(Color(0.04, 0.05, 0.12, 0.95), Color("#3b62c8"), int(sz.y / 2.0), 3))
    padre.add_child(fondo)
    var w: float = clampf(frac, 0.0, 1.0) * (sz.x - 8.0)
    if w > 0.0:
        var r := Panel.new()
        r.position = pos + Vector2(4, 4)
        r.size = Vector2(maxf(w, sz.y - 8.0), sz.y - 8.0)
        r.mouse_filter = Control.MOUSE_FILTER_IGNORE
        r.add_theme_stylebox_override("panel", GameUI.flat_box(color, color.lightened(0.25), int((sz.y - 8.0) / 2.0), 2))
        padre.add_child(r)

func _chip(padre: Control, texto: String, valor: String, pos: Vector2, sz: Vector2, color: Color) -> void:
    GameUI.frame(padre, Rect2(pos, sz), color, 4, 36, false, Color(0.05, 0.06, 0.16, 0.92))
    GameUI.label(padre, texto, pos + Vector2(0, 8), Vector2(sz.x, 48), 30, Color("#d6e6ff"), false, 4)
    GameUI.label(padre, valor, pos + Vector2(0, 50), Vector2(sz.x, sz.y - 56), 58, color, false, 6)

# ---------- PERFIL ----------
func perfil() -> void:
    var p := GameUI.neon_modal(raiz, Vector2(940, 1260))
    GameUI.label(p, "👤  Perfil", Vector2(0, 30), Vector2(940, 90), 58, Color("#5cf0ff"), false, 6)
    _avatar(p, Vector2(340, 135), 260)
    GameUI.label(p, Jugador.nombre(), Vector2(40, 415), Vector2(860, 80), 62, Color("#ffd23f"), false, 7)
    GameUI.label(p, "Nivel %d" % Jugador.nivel(), Vector2(40, 500), Vector2(860, 70), 50, Color.WHITE, false, 6)
    _barra(p, Vector2(110, 585), Vector2(720, 44), float(Jugador.xp_en_nivel()) / float(Jugador.XP_POR_NIVEL), Color("#ff8a1f"))
    GameUI.label(p, "XP  %d / %d" % [Jugador.xp_en_nivel(), Jugador.XP_POR_NIVEL], Vector2(40, 636), Vector2(860, 50), 34, Color("#ffe0b0"), false, 5)
    _chip(p, "🪙 Monedas", str(Jugador.monedas()), Vector2(60, 720), Vector2(400, 150), Color("#ffd23f"))
    _chip(p, "💎 Gemas", str(Jugador.gemas()), Vector2(480, 720), Vector2(400, 150), Color("#c46fe0"))
    GameUI.pill(p, "📷  Cambiar foto", Vector2(60, 920), Vector2(400, 120), "blue", _cambiar_foto.bind(p), 36)
    GameUI.pill(p, "✏️  Cambiar nombre", Vector2(480, 920), Vector2(400, 120), "yellow", _cambiar_nombre.bind(p), 34)
    GameUI.pill(p, "Cerrar", Vector2(270, 1090), Vector2(400, 110), "green", GameUI.close_modal.bind(p), 44)

func _reabrir_perfil(previo: Control) -> void:
    GameUI.close_modal(previo)
    perfil()

func _cambiar_nombre(previo: Control) -> void:
    var p := GameUI.neon_modal(raiz, Vector2(860, 620))
    GameUI.label(p, "✏️  Tu nombre", Vector2(0, 40), Vector2(860, 80), 52, Color("#ffd23f"), false, 6)
    var le := LineEdit.new()
    le.position = Vector2(80, 190)
    le.size = Vector2(700, 120)
    le.max_length = 16
    le.text = Jugador.nombre()
    le.alignment = HORIZONTAL_ALIGNMENT_CENTER
    le.add_theme_font_size_override("font_size", 52)
    for st in ["normal", "focus"]:
        le.add_theme_stylebox_override(st, GameUI.flat_box(Color("#0b0b14"), Color("#5cf0ff"), 36, 4))
    p.add_child(le)
    GameUI.pill(p, "Guardar", Vector2(60, 400), Vector2(350, 120), "green", _guardar_nombre.bind(le, p, previo), 40)
    GameUI.pill(p, "Cancelar", Vector2(450, 400), Vector2(350, 120), "red", GameUI.close_modal.bind(p), 40)

func _guardar_nombre(le: LineEdit, sub: Control, previo: Control) -> void:
    Jugador.set_nombre(le.text)
    GameUI.close_modal(sub)
    _reabrir_perfil(previo)

func _cambiar_foto(previo: Control) -> void:
    var galeria: bool = DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE)
    var alto: int = 1030 if galeria else 880
    var p := GameUI.neon_modal(raiz, Vector2(900, alto))
    GameUI.label(p, "📷  Elige tu avatar", Vector2(0, 40), Vector2(900, 80), 52, Color("#ffd23f"), false, 6)
    for i in range(Jugador.AVATARES.size()):
        var col := Color(Jugador.COLORES_AVATAR[i % Jugador.COLORES_AVATAR.size()])
        var b := Button.new()
        b.position = Vector2(60 + (i % 4) * 200, 150 + floori(i / 4.0) * 190)
        b.size = Vector2(170, 170)
        b.focus_mode = Control.FOCUS_NONE
        b.text = Jugador.AVATARES[i]
        b.add_theme_font_size_override("font_size", 96)
        var sb := GameUI.flat_box(col.darkened(0.35), Color("#ffe08a") if (i == Jugador.avatar() and not Jugador.tiene_foto()) else col, 85, 6)
        for st in ["normal", "hover", "pressed", "disabled"]:
            b.add_theme_stylebox_override(st, sb)
        b.pressed.connect(_elegir_avatar.bind(i, p, previo))
        p.add_child(b)
    var y: int = 740
    if galeria:
        GameUI.pill(p, "🖼️  Elegir de la galería", Vector2(150, 730), Vector2(600, 110), "blue", _abrir_galeria.bind(p, previo), 36)
        y = 880
    GameUI.pill(p, "Cancelar", Vector2(250, y), Vector2(400, 100), "red", GameUI.close_modal.bind(p), 38)

func _elegir_avatar(i: int, sub: Control, previo: Control) -> void:
    Jugador.set_avatar(i)
    GameUI.close_modal(sub)
    _reabrir_perfil(previo)

func _abrir_galeria(sub: Control, previo: Control) -> void:
    DisplayServer.file_dialog_show("Elegir foto", "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp;Imágenes"]), _foto_elegida.bind(sub, previo))

func _foto_elegida(ok: bool, rutas: PackedStringArray, _filtro: int, sub: Control, previo: Control) -> void:
    if not ok or rutas.is_empty():
        return
    if Jugador.guardar_foto(rutas[0]):
        if is_instance_valid(sub):
            GameUI.close_modal.call_deferred(sub)
        if is_instance_valid(previo):
            _reabrir_perfil.call_deferred(previo)

# ---------- ESTADÍSTICAS ----------
func estadisticas() -> void:
    var p := GameUI.neon_modal(raiz, Vector2(940, 1500))
    GameUI.label(p, "📊  Estadísticas", Vector2(0, 30), Vector2(940, 90), 58, Color("#ffab2e"), false, 6)
    var jugadas: Array = Jugador.areas_jugadas()
    if jugadas.is_empty():
        GameUI.label(p, "Todavía no has jugado ninguna área.\n¡Entra a la Academia y empieza!", Vector2(60, 500), Vector2(820, 300), 42, Color("#f1ecff"), true, 5)
    else:
        var sc := ScrollContainer.new()
        sc.position = Vector2(40, 140)
        sc.size = Vector2(860, 1180)
        sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
        p.add_child(sc)
        var vb := VBoxContainer.new()
        vb.custom_minimum_size = Vector2(840, 0)
        vb.add_theme_constant_override("separation", 20)
        sc.add_child(vb)
        for d in jugadas:
            vb.add_child(_tarjeta_area(d))
    GameUI.pill(p, "Cerrar", Vector2(270, 1350), Vector2(400, 110), "green", GameUI.close_modal.bind(p), 44)

func _tarjeta_area(d: Dictionary) -> Control:
    var ok: int = int(d["ok"])
    var mal: int = int(d["mal"])
    var total: int = maxi(1, ok + mal)
    var card := Panel.new()
    card.custom_minimum_size = Vector2(840, 200)
    card.mouse_filter = Control.MOUSE_FILTER_PASS   # deja que el dedo arrastre la lista desde cualquier parte
    card.add_theme_stylebox_override("panel", GameUI.flat_box(Color(0.05, 0.06, 0.16, 0.95), Color("#3b62c8"), 36, 4))
    var nombre: String = I18n.t(str(Global.EDU_NOMBRE.get(d["area"], "edu_title")))
    var n := GameUI.label(card, nombre, Vector2(30, 10), Vector2(780, 64), 46, Color("#ffd23f"), false, 6)
    n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    var a := GameUI.label(card, "✅  %d" % ok, Vector2(30, 82), Vector2(250, 50), 38, Color("#8cf0a0"), false, 5)
    a.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    var m := GameUI.label(card, "❌  %d" % mal, Vector2(300, 82), Vector2(250, 50), 38, Color("#ff9a9a"), false, 5)
    m.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    var pc := GameUI.label(card, "%d%%" % int(round(100.0 * float(ok) / float(total))), Vector2(600, 82), Vector2(210, 50), 38, Color.WHITE, false, 5)
    pc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _barra(card, Vector2(30, 145), Vector2(780, 36), float(ok) / float(total), Color("#3fd35a"))
    return card

# ---------- PUNTOS ----------
func puntos() -> void:
    var p := GameUI.neon_modal(raiz, Vector2(940, 1240))
    GameUI.label(p, "💎  Puntos", Vector2(0, 30), Vector2(940, 90), 58, Color("#c46fe0"), false, 6)
    _chip(p, "🪙 Monedas", str(Jugador.monedas()), Vector2(60, 150), Vector2(400, 160), Color("#ffd23f"))
    _chip(p, "💎 Gemas", str(Jugador.gemas()), Vector2(480, 150), Vector2(400, 160), Color("#c46fe0"))
    _chip(p, "⭐ Puntos de logro", str(Jugador.puntos_logro()), Vector2(60, 340), Vector2(820, 170), Color("#5cf0ff"))
    var areas: Array = Jugador.areas_logro()
    var txt: String = "Ganas %d puntos por cada área nueva que desbloqueas." % Jugador.PUNTOS_AREA
    if areas.is_empty():
        txt += "\nAún no has desbloqueado ninguna."
    else:
        txt += "\n\nÁreas desbloqueadas:"
        for id in areas:
            txt += "\n+%d  ·  %s" % [Jugador.PUNTOS_AREA, I18n.t(str(Global.EDU_NOMBRE.get(id, "edu_title")))]
    GameUI.label(p, txt, Vector2(60, 540), Vector2(820, 520), 36, Color("#f1ecff"), true, 5)
    GameUI.pill(p, "Cerrar", Vector2(270, 1090), Vector2(400, 110), "green", GameUI.close_modal.bind(p), 44)
