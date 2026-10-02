extends Control
# Nivel de "Unir parejas" (Inglés): 20 rondas por nivel. En cada ronda hay 4 palabras en inglés (izquierda) y sus significados
# en español mezclados (derecha). Se unen tocando una y luego la otra (o arrastrando una línea) y se pulsa "Aceptar".
# Si alguna unión está mal se marca en rojo y la ronda no avanza hasta que la corrijan. Al completar las 20 rondas se supera el nivel.
# Datos: res://preguntas/<area>_<nivel>_pares.json  ->  [["Cat", "Gato"], ["Dog", "Perro"], ...]  (80 pares por nivel, sin repetir)

const POR_RONDA := 4
const CARTA := Vector2(360, 130)
const X_IZQ := 90.0
const X_DER := 630.0
const Y0 := 500.0
const PASO := 210.0
const AZUL := Color("#4d7cff")
const ROJO := Color("#e5484d")
const VERDE := Color("#2f9a3a")
const ORO := Color("#ffc933")

var rondas: Array = []        # cada ronda = POR_RONDA pares [inglés, español]
var pos: int = 0
var holder: Control
var lineas: Control
var msg: Label
var ronda: Array = []
var perm: Array = []          # perm[k] = índice del par cuyo español está en la tarjeta derecha k
var links: Dictionary = {}    # tarjeta izquierda i -> tarjeta derecha k
var malos: Dictionary = {}    # tarjetas izquierdas cuya unión está mal (en rojo)
var cerrado: bool = false
var cartas: Array = [[], []]  # [paneles izquierdos, paneles derechos]
var sel_lado: int = -1
var sel_idx: int = -1
var arrastrando: bool = false
var movido: bool = false
var arr_lado: int = -1
var arr_idx: int = -1
var arr_ini: Vector2 = Vector2.ZERO
var arr_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
    EduFondo.aplicar(self, Global.categoria_actual)
    GameUI.frame(self, Rect2(50, 50, 980, 1820), Color("#3b8bff"), 6, 80, true, Color(0.02, 0.03, 0.09, 0.74))
    holder = Control.new()
    holder.set_anchors_preset(Control.PRESET_FULL_RECT)
    holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(holder)
    _cargar()
    if rondas.is_empty():
        _sin_datos()
    else:
        _mostrar()

func _nombre() -> String:
    return I18n.t(str(Global.EDU_NOMBRE.get(Global.categoria_actual, "edu_title")))

func _nombre_nivel() -> String:
    return I18n.t(["lvl_easy", "lvl_mid", "lvl_hard"][clampi(Global.nivel_actual - 1, 0, 2)])

func _cargar() -> void:
    var ruta := "res://preguntas/%s_%s_pares.json" % [Global.categoria_actual, Global.EDU_NIVELES[clampi(Global.nivel_actual - 1, 0, 2)]]
    if not FileAccess.file_exists(ruta):
        return
    var f := FileAccess.open(ruta, FileAccess.READ)
    var datos: Variant = JSON.parse_string(f.get_as_text())
    if not (datos is Array):
        return
    var pares: Array = datos.duplicate()
    pares.shuffle()
    var n: int = mini(Global.EDU_PREGUNTAS, floori(float(pares.size()) / float(POR_RONDA)))
    for r in range(n):
        rondas.append(pares.slice(r * POR_RONDA, (r + 1) * POR_RONDA))

func _sin_datos() -> void:
    GameUI.label(holder, I18n.t("qz_none"), Vector2(100, 700), Vector2(880, 300), 46, Color.WHITE, true, 8)
    var v := GameUI.glossy(holder, "↩  " + I18n.t("qz_back_levels"), Vector2(250, 1745), Vector2(580, 95), Color("#4a3fd6"), Color.WHITE, _ir_niveles, 36, 40)
    v.focus_mode = Control.FOCUS_NONE

func _mostrar() -> void:
    for c in holder.get_children():
        c.queue_free()
    cartas = [[], []]
    links.clear()
    malos.clear()
    cerrado = false
    sel_lado = -1
    sel_idx = -1
    arrastrando = false
    movido = false
    ronda = rondas[pos]
    # español mezclado, sin dejar ninguna palabra frente a su pareja
    perm = range(POR_RONDA)
    var bien := false
    while not bien:
        perm.shuffle()
        bien = true
        for k in range(POR_RONDA):
            if perm[k] == k:
                bien = false

    var total: int = rondas.size()
    GameUI.frame(holder, Rect2(100, 100, 880, 130), Color("#3b62c8"), 3, 44, false, Color(0.05, 0.06, 0.16, 0.92))
    GameUI.label(holder, "%s · %s" % [_nombre(), _nombre_nivel()], Vector2(100, 100), Vector2(880, 130), 48, Color("#5cf0ff"), false, 6)
    GameUI.frame(holder, Rect2(110, 260, 860, 54), Color("#3b62c8"), 3, 27, false, Color(0.04, 0.05, 0.12, 0.92))
    var relleno := Panel.new()
    relleno.position = Vector2(120, 270)
    relleno.size = Vector2(maxf(34.0, 840.0 * float(pos) / float(total)), 34)
    relleno.mouse_filter = Control.MOUSE_FILTER_IGNORE
    relleno.add_theme_stylebox_override("panel", GameUI.flat_box(Color("#ff8a1f"), Color("#ffb04d"), 17, 2))
    holder.add_child(relleno)
    GameUI.label(holder, I18n.t("un_round_fmt") % [pos + 1, total], Vector2(110, 325), Vector2(860, 60), 38, Color.WHITE, false, 6)
    GameUI.label(holder, I18n.t("un_hint"), Vector2(100, 395), Vector2(880, 90), 30, Color("#e6f6ff"), true, 6)

    # capa de líneas (debajo de las tarjetas)
    lineas = Control.new()
    lineas.mouse_filter = Control.MOUSE_FILTER_IGNORE
    lineas.position = Vector2.ZERO
    lineas.size = Vector2(1080, 1920)
    lineas.draw.connect(_dibujar)
    holder.add_child(lineas)

    for k in range(POR_RONDA):
        var y: float = Y0 + float(k) * PASO
        cartas[0].append(_carta(str(ronda[k][0]), Vector2(X_IZQ, y)))
        cartas[1].append(_carta(str(ronda[perm[k]][1]), Vector2(X_DER, y)))

    msg = GameUI.label(holder, "", Vector2(100, 1345), Vector2(880, 110), 34, Color("#ffd8a0"), true, 6)
    GameUI.glossy(holder, I18n.t("un_accept"), Vector2(190, 1480), Vector2(700, 125), Color("#3fd35a"), Color.WHITE, _aceptar, 50)
    var v := GameUI.glossy(holder, "↩  " + I18n.t("qz_back_levels"), Vector2(250, 1745), Vector2(580, 95), Color("#4a3fd6"), Color.WHITE, _ir_niveles, 36, 40)
    v.focus_mode = Control.FOCUS_NONE
    _pintar()

func _carta(texto: String, p: Vector2) -> Panel:
    var c := Panel.new()
    c.position = p
    c.size = CARTA
    c.mouse_filter = Control.MOUSE_FILTER_IGNORE
    holder.add_child(c)
    var l := Label.new()
    l.text = texto
    l.position = Vector2(10, 0)
    l.size = Vector2(CARTA.x - 20.0, CARTA.y)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_size_override("font_size", _tam_fuente(texto))
    l.add_theme_color_override("font_color", Color("#12102a"))
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    c.add_child(l)
    return c

func _tam_fuente(t: String) -> int:
    var n: int = t.length()
    if n <= 8:
        return 58
    if n <= 11:
        return 48
    if n <= 15:
        return 40
    return 34

# ---------- Entrada: tocar una y luego la otra, o arrastrar una línea ----------

func _gui_input(event: InputEvent) -> void:
    if cerrado or rondas.is_empty():
        return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            var h: Vector2i = _carta_en(event.position)
            if h.x >= 0:
                arrastrando = true
                movido = false
                arr_lado = h.x
                arr_idx = h.y
                arr_ini = event.position
                arr_pos = event.position
                _pintar()
        elif arrastrando:
            arrastrando = false
            var h2: Vector2i = _carta_en(event.position)
            if movido and h2.x >= 0 and h2.x != arr_lado:
                _unir_lados(arr_lado, arr_idx, h2.y)
            elif not movido:
                _tocar(arr_lado, arr_idx)
            _pintar()
            lineas.queue_redraw()
    elif event is InputEventMouseMotion and arrastrando:
        arr_pos = event.position
        if arr_pos.distance_to(arr_ini) > 25.0:
            movido = true
        lineas.queue_redraw()

func _carta_en(p: Vector2) -> Vector2i:
    for lado in range(2):
        var x: float = X_IZQ if lado == 0 else X_DER
        for k in range(POR_RONDA):
            var r := Rect2(Vector2(x, Y0 + float(k) * PASO), CARTA).grow(12.0)
            if r.has_point(p):
                return Vector2i(lado, k)
    return Vector2i(-1, -1)

func _tocar(lado: int, idx: int) -> void:
    if sel_lado == -1:
        sel_lado = lado
        sel_idx = idx
    elif sel_lado == lado:
        if sel_idx == idx:
            sel_lado = -1
            sel_idx = -1
        else:
            sel_idx = idx
    else:
        _unir_lados(sel_lado, sel_idx, idx)
        sel_lado = -1
        sel_idx = -1

# lado1 / idx1 = tarjeta de origen; idx2 = tarjeta del otro lado
func _unir_lados(lado1: int, idx1: int, idx2: int) -> void:
    if lado1 == 0:
        _unir(idx1, idx2)
    else:
        _unir(idx2, idx1)

func _unir(izq: int, der: int) -> void:
    # una tarjeta solo puede tener una unión: se quitan las anteriores de esta izquierda y de esta derecha
    links.erase(izq)
    malos.erase(izq)
    for i in links.keys():
        if links[i] == der:
            links.erase(i)
            malos.erase(i)
    links[izq] = der
    msg.text = ""
    Audio.play("tick")
    lineas.queue_redraw()

# ---------- Aceptar ----------

func _aceptar() -> void:
    if cerrado:
        return
    if links.size() < POR_RONDA:
        msg.text = I18n.t("un_need_all")
        msg.add_theme_color_override("font_color", Color("#ffd8a0"))
        return
    malos.clear()
    for i in links.keys():
        if perm[links[i]] != i:
            malos[i] = true
    sel_lado = -1
    sel_idx = -1
    if malos.is_empty():
        cerrado = true
        msg.text = I18n.t("un_ok")
        msg.add_theme_color_override("font_color", Color("#8dfcae"))
        _pintar()
        lineas.queue_redraw()
        Audio.play("win")
        await get_tree().create_timer(1.0).timeout
        if not is_inside_tree():
            return
        pos += 1
        if pos >= rondas.size():
            _termino()
        else:
            _mostrar()
    else:
        # las uniones malas quedan en rojo y la ronda no avanza hasta corregirlas
        msg.text = I18n.t("un_wrong")
        msg.add_theme_color_override("font_color", Color("#ffb0b0"))
        Audio.play("error")
        _pintar()
        lineas.queue_redraw()

# ---------- Dibujo ----------

func _pintar() -> void:
    for lado in range(2):
        for k in range(POR_RONDA):
            var c: Panel = cartas[lado][k]
            var vinculada: bool = false
            var mala: bool = false
            if lado == 0:
                vinculada = links.has(k)
                mala = malos.has(k)
            else:
                for i in links.keys():
                    if links[i] == k:
                        vinculada = true
                        mala = malos.has(i)
            var fill: Color = Color.WHITE
            var borde: Color = Color("#c9cfe8")
            var ancho: int = 4
            if cerrado:
                fill = Color("#e3ffe3")
                borde = VERDE
                ancho = 8
            elif mala:
                fill = Color("#ffe6e6")
                borde = ROJO
                ancho = 8
            elif vinculada:
                borde = AZUL
                ancho = 7
            if (sel_lado == lado and sel_idx == k) or (arrastrando and arr_lado == lado and arr_idx == k):
                borde = ORO
                ancho = 10
            c.add_theme_stylebox_override("panel", GameUI.flat_box(fill, borde, 28, ancho))

func _dibujar() -> void:
    for i in links.keys():
        var k: int = links[i]
        var a := Vector2(X_IZQ + CARTA.x, Y0 + float(i) * PASO + CARTA.y / 2.0)
        var b := Vector2(X_DER, Y0 + float(k) * PASO + CARTA.y / 2.0)
        var col: Color = AZUL
        if cerrado:
            col = VERDE
        elif malos.has(i):
            col = ROJO
        lineas.draw_line(a, b, col, 12.0, true)
        lineas.draw_circle(a, 12.0, col)
        lineas.draw_circle(b, 12.0, col)
    if arrastrando and movido:
        var x: float = X_IZQ + CARTA.x if arr_lado == 0 else X_DER
        var ini := Vector2(x, Y0 + float(arr_idx) * PASO + CARTA.y / 2.0)
        lineas.draw_line(ini, arr_pos, ORO, 10.0, true)
        lineas.draw_circle(arr_pos, 14.0, ORO)

func _termino() -> void:
    Global.edu_pasar_nivel(Global.categoria_actual, Global.nivel_actual - 1)
    get_tree().change_scene_to_file("res://EducativoGano.tscn")

func _ir_niveles() -> void:
    get_tree().change_scene_to_file("res://EducativoNiveles.tscn")
