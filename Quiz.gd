extends Control
# Un NIVEL de la Academia (20 niveles por dificultad, se eligen en EducativoLista). Cada nivel tiene un FORMATO al azar
# (lo reparte EduRun): "quiz" (4 opciones) · "vf" (verdadero o falso) · "unir" (palabra con su definición) · "cruci" (crucigrama).
# · Acertar supera el nivel (+2 puntos) y abre el siguiente. Al acertar el nivel 20 se supera la dificultad.
# · Al pasar el nivel 12 se gana una vida (máximo 3).
# · En cualquier nivel cada fallo cuenta: con 2 errores el participante vuelve al nivel 1; si tiene una vida, la gasta y sigue;
#   si no tiene vida, puede salvarse pagando 2 gemas (Jugador.COSTO_SALVAR).
# · Las preguntas salen al azar y no se repiten; lo que se falla vuelve al final de la cola (EduRun).
# Preguntas: res://preguntas/<area>_<dificultad>.json  ·  Palabras: res://preguntas/<area>_palabras.json

const LETRAS := ["A", "B", "C", "D", "E"]
const COLOR_TXT := Color("#2a1466")
const PAREJAS: Array[Color] = [Color("#4d7cff"), Color("#ff8a1f"), Color("#b04df0"), Color("#1fb5a8")]
const TECLAS := "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ"
const CREMA := Color("#fbe9d0")
const MORADO := Color("#6a3ad8")
const VERDE_OK := Color("#2f9a3a")
const ROJO_MAL := Color("#c23a3a")

var cat: String = ""
var idx: int = 0              # 0 fácil · 1 media · 2 difícil
var nivel: int = 1            # 1 a 20
var formato: String = "quiz"
var holder: Control
var cerrado: bool = false     # el nivel ya se respondió
var usado_q: Dictionary = {}  # pregunta usada (quiz / vf)
var usado_p: Array = []       # palabras usadas (unir / crucigrama)
var vida_ganada: bool = false
var modo_fallo: String = ""   # "" · "vida" (gastó una vida) · "reinicio" (vuelve al nivel 1)
var y_msg: float = 1425.0     # dónde sale el mensaje de resultado y el botón
var y_btn: float = 1540.0

# quiz
var q: Dictionary = {}
var orden: Array = []
var correcta_vis: int = 0
var botones: Array[Button] = []
# vf
var vf_verdad: bool = true
var vf_texto: String = ""
var vf_btns: Array[Button] = []
# unir
var un_items: Array = []
var un_perm: Array = []
var un_links: Dictionary = {}
var un_ver: Dictionary = {}
var un_sel_lado: int = -1
var un_sel_idx: int = -1
var un_botones: Array = [[], []]
var un_msg: Label
var un_ctrl: Control
# crucigrama
var cr: Dictionary = {}
var cr_fil: Array = []
var cr_sel: int = 0
var cr_cajas: Array = []
var cr_letras: Array = []
var cr_ver: Array = []
var cr_msg: Label
var cr_ctrl: Control
var cr_bloq: Array = []       # por fila: celdas reveladas con pista (no se pueden borrar)
# pistas del quiz
var salv_msg: Label            # mensaje de la ventana "salvarse con gemas"
var gemas_lbl: Label           # gemas del jugador, arriba de la pantalla
var pista_usada: bool = false
var pista_btn: Button
var pista_msg: Label
# crucigrama de Chibolo (nivel 9)
var ch_pal: Array = []          # palabras: {"p","t","f","c","v"}
var ch_celdas: Dictionary = {}  # "fila,col" -> letra escrita ("" = vacía)
var ch_bloq: Dictionary = {}    # "fila,col" -> "pista" o "ok" (palabra encontrada)
var ch_ok: Array = []           # por palabra: ya encontrada
var ch_sel: int = 0             # palabra seleccionada
var ch_cajas: Dictionary = {}
var ch_letras: Dictionary = {}
var ch_lista: Array = []        # por palabra: [Label, ColorRect (tachado)]
var ch_cont: Label
var ch_msg: Label
var ch_ctrl: Control

func _ready() -> void:
    cat = Global.categoria_actual
    idx = clampi(Global.nivel_actual - 1, 0, 2)
    EduFondo.aplicar(self, cat)
    GameUI.frame(self, Rect2(50, 50, 980, 1820), Color("#3b8bff"), 6, 80, true, Color(0.02, 0.03, 0.09, 0.74))
    holder = Control.new()
    holder.set_anchors_preset(Control.PRESET_FULL_RECT)
    holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(holder)
    nivel = clampi(Global.nivel_pregunta, 1, Global.EDU_PREGUNTAS)
    formato = EduRun.formato(cat, idx, nivel)
    match formato:
        "unir":
            _preparar_unir()
        "cruci":
            _preparar_cruci()
        "chibolo":
            _preparar_chibolo()
        "vf":
            _preparar_vf()
        _:
            _preparar_quiz()

func _nombre() -> String:
    return I18n.t(str(Global.EDU_NOMBRE.get(cat, "edu_title")))

func _nombre_nivel() -> String:
    return I18n.t(["lvl_easy", "lvl_mid", "lvl_hard"][idx])

func _limpiar() -> void:
    for c in holder.get_children():
        c.queue_free()

func _boton_niveles(y: float = 1745.0) -> void:
    var v := GameUI.glossy(holder, "↩  " + I18n.t("lvl_back_levels"), Vector2(250, y), Vector2(580, 95), Color("#4a3fd6"), Color.WHITE, _ir_niveles, 36, 40)
    v.focus_mode = Control.FOCUS_NONE

func _sin_preguntas() -> void:
    _limpiar()
    GameUI.label(holder, I18n.t("qz_none"), Vector2(100, 700), Vector2(880, 300), 46, Color.WHITE, true, 8)
    _boton_niveles()

# Encabezado común: área, dificultad, nivel, vidas, errores, puntos y formato del nivel
func _cabecera() -> void:
    var hechos: int = Global.edu_run(cat, idx)
    GameUI.frame(holder, Rect2(100, 100, 880, 130), Color("#3b62c8"), 3, 44, false, Color(0.05, 0.06, 0.16, 0.92))
    GameUI.label(holder, "%s · %s" % [_nombre(), _nombre_nivel()], Vector2(100, 100), Vector2(880, 130), 48, Color("#5cf0ff"), false, 6)
    GameUI.label(holder, I18n.t("lvl_n_fmt") % nivel, Vector2(100, 243), Vector2(300, 60), 40, Color.WHITE, false, 6)
    var vtxt: String = "❤️ %d" % Global.edu_vidas()
    if nivel >= Global.EDU_NIVEL_RIESGO:
        vtxt += "   ✖ %d/%d" % [EduRun.errores(cat, idx), Global.EDU_ERRORES_MAX]
    GameUI.label(holder, vtxt, Vector2(400, 243), Vector2(320, 60), 34, Color("#ff9aa8"), false, 6)
    GameUI.label(holder, "⭐ %d/%d PTS" % [hechos * 2, Global.EDU_PREGUNTAS * 2], Vector2(730, 243), Vector2(250, 60), 28, Color("#ffd23f"), false, 6)
    GameUI.label(holder, I18n.t("fm_" + formato), Vector2(100, 304), Vector2(880, 44), 32, Color("#ffd23f"), false, 6)
    # gemas arriba, siempre a la vista (se gastan en pistas y para salvarse)
    gemas_lbl = GameUI.label(holder, "", Vector2(340, 56), Vector2(400, 42), 32, Color("#e9b3ff"), false, 6)
    _gemas_refrescar()

func _gemas_refrescar() -> void:
    if is_instance_valid(gemas_lbl):
        gemas_lbl.text = "💎 %d" % Jugador.gemas()

# Pone el estilo de un botón con márgenes internos
func _estilo(b: Button, fill: Color, borde: Color, ancho: int, texto: Color, radio: int = 36) -> void:
    for st in ["normal", "hover", "pressed", "disabled"]:
        var box: StyleBoxFlat = GameUI.flat_box(fill, borde, radio, ancho)
        box.content_margin_left = 16
        box.content_margin_right = 16
        box.content_margin_top = 8
        box.content_margin_bottom = 8
        b.add_theme_stylebox_override(st, box)
    for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
        b.add_theme_color_override(c, texto)

# ============================================================ QUIZ

func _preparar_quiz() -> void:
    usado_q = EduRun.tomar_pregunta(cat, idx)
    if usado_q.is_empty():
        _sin_preguntas()
        return
    q = usado_q
    var opciones: Array = q.get("o", [])
    orden = range(opciones.size())
    orden.shuffle()
    correcta_vis = orden.find(int(q.get("c", 0)))
    _mostrar_quiz()

func _mostrar_quiz() -> void:
    _limpiar()
    cerrado = false
    botones.clear()
    y_msg = 1425.0
    y_btn = 1540.0
    _cabecera()
    GameUI.frame(holder, Rect2(110, 355, 860, 425), Color("#4a5fc8"), 3, 56, false, Color(0.06, 0.06, 0.16, 0.9))
    var txt := GameUI.label(holder, str(q.get("q", "")), Vector2(150, 365), Vector2(780, 400), 46, Color("#fff1d6"), true, 5)
    txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    var opciones: Array = q.get("o", [])
    for k in range(orden.size()):
        var real: int = orden[k]
        var b := GameUI.flat_button(holder, Vector2(120, 810 + k * 150), Vector2(840, 132), CREMA, MORADO, _responder_quiz.bind(k), 40, 5)
        b.text = "%s)  %s" % [LETRAS[k], str(opciones[real])]
        b.alignment = HORIZONTAL_ALIGNMENT_LEFT
        b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        b.add_theme_font_size_override("font_size", 40)
        _opcion_estilo(b, CREMA, MORADO)
        botones.append(b)
    pista_usada = false
    pista_btn = GameUI.glossy(holder, I18n.t("hint_btn") % Jugador.COSTO_PISTA, Vector2(290, 1410), Vector2(500, 100), Color("#8a4de8"), Color.WHITE, _pista_quiz, 38, 40, false)
    pista_msg = GameUI.label(holder, "", Vector2(100, 1518), Vector2(880, 60), 30, Color("#ffd8a0"), true, 6)
    _boton_niveles()

func _opcion_estilo(b: Button, fill: Color, borde: Color) -> void:
    for st in ["normal", "hover", "pressed", "disabled"]:
        var box: StyleBoxFlat = GameUI.flat_box(fill, borde, 40, 5)
        box.content_margin_left = 40
        box.content_margin_right = 30
        b.add_theme_stylebox_override(st, box)
    for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
        b.add_theme_color_override(c, COLOR_TXT)

func _responder_quiz(k: int) -> void:
    if cerrado:
        return
    cerrado = true
    _quitar_pista_ui()
    if k == correcta_vis:
        _opcion_estilo(botones[k], Color("#b8f2b0"), VERDE_OK)
        _acierto()
    else:
        _opcion_estilo(botones[k], Color("#f3a6a0"), ROJO_MAL)
        _opcion_estilo(botones[correcta_vis], Color("#b8f2b0"), VERDE_OK)
        _fallo()

# Pista del quiz: cuesta 3 gemas, quita 2 opciones incorrectas al azar (quedan 1 correcta y 1 incorrecta). Solo 1 por pregunta.
func _pista_quiz() -> void:
    if cerrado:
        return
    if pista_usada:
        pista_msg.text = I18n.t("hint_used")
        return
    var tiene: int = Jugador.gemas()
    if tiene < Jugador.COSTO_PISTA:
        pista_msg.text = I18n.t("hint_need") % [Jugador.COSTO_PISTA, tiene]
        return
    if not Jugador.gastar_gemas(Jugador.COSTO_PISTA):
        return
    _gemas_refrescar()
    pista_usada = true
    var malas: Array = []
    for k in range(botones.size()):
        if k != correcta_vis:
            malas.append(k)
    malas.shuffle()
    var quitar: int = mini(2, malas.size() - 1)   # siempre queda al menos una incorrecta
    for i in range(quitar):
        _opcion_gris(botones[int(malas[i])])
    pista_btn.disabled = true
    pista_msg.text = I18n.t("hint_paid") % [Jugador.COSTO_PISTA, Jugador.gemas()]

func _opcion_gris(b: Button) -> void:
    _opcion_estilo(b, Color("#bdbdc8"), Color("#8b8b99"))
    for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
        b.add_theme_color_override(c, Color("#7a7a88"))
    b.disabled = true

func _quitar_pista_ui() -> void:
    if is_instance_valid(pista_btn):
        pista_btn.hide()
        pista_btn.queue_free()
    if is_instance_valid(pista_msg):
        pista_msg.hide()
        pista_msg.queue_free()

# ============================================================ VERDADERO O FALSO

func _preparar_vf() -> void:
    usado_q = EduRun.tomar_pregunta(cat, idx)
    var ops: Array = usado_q.get("o", [])
    if usado_q.is_empty() or ops.is_empty():
        _sin_preguntas()
        return
    q = usado_q
    var c: int = clampi(int(q.get("c", 0)), 0, ops.size() - 1)
    vf_verdad = randf() < 0.5
    if ops.size() < 2:
        vf_verdad = true
    if vf_verdad:
        vf_texto = str(ops[c])
    else:
        var malos: Array = []
        for i in range(ops.size()):
            if i != c:
                malos.append(i)
        vf_texto = str(ops[malos[randi() % malos.size()]])
    _mostrar_vf()

func _mostrar_vf() -> void:
    _limpiar()
    cerrado = false
    vf_btns.clear()
    y_msg = 1425.0
    y_btn = 1540.0
    _cabecera()
    GameUI.frame(holder, Rect2(110, 355, 860, 340), Color("#4a5fc8"), 3, 56, false, Color(0.06, 0.06, 0.16, 0.9))
    var txt := GameUI.label(holder, str(q.get("q", "")), Vector2(150, 365), Vector2(780, 320), 44, Color("#fff1d6"), true, 5)
    txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    GameUI.label(holder, I18n.t("vf_prop"), Vector2(100, 715), Vector2(880, 50), 34, Color("#5cf0ff"), false, 6)
    GameUI.frame(holder, Rect2(110, 775, 860, 290), Color("#ffd23f"), 4, 56, false, Color(0.10, 0.08, 0.20, 0.92))
    var resp := GameUI.label(holder, vf_texto, Vector2(150, 785), Vector2(780, 270), 46, Color.WHITE, true, 5)
    resp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    GameUI.label(holder, I18n.t("vf_hint"), Vector2(100, 1085), Vector2(880, 50), 32, Color("#e6f6ff"), false, 6)
    vf_btns.append(GameUI.glossy(holder, I18n.t("vf_true"), Vector2(110, 1150), Vector2(410, 150), Color("#3fd35a"), Color.WHITE, _responder_vf.bind(true), 44))
    vf_btns.append(GameUI.glossy(holder, I18n.t("vf_false"), Vector2(560, 1150), Vector2(410, 150), Color("#f0524a"), Color.WHITE, _responder_vf.bind(false), 44))
    _boton_niveles()

func _responder_vf(dice_verdad: bool) -> void:
    if cerrado:
        return
    cerrado = true
    for b in vf_btns:
        b.disabled = true
    if dice_verdad == vf_verdad:
        _acierto()
    else:
        var ops: Array = q.get("o", [])
        var c: int = clampi(int(q.get("c", 0)), 0, ops.size() - 1)
        GameUI.label(holder, I18n.t("vf_was") % str(ops[c]), Vector2(100, 1320), Vector2(880, 90), 34, Color("#b8f2b0"), true, 7)
        _fallo()

# ============================================================ UNIR PAREJAS

func _preparar_unir() -> void:
    usado_p = EduRun.tomar_palabras(cat, idx, 4)
    if usado_p.size() < 4:
        _sin_preguntas()
        return
    un_items = usado_p
    un_perm = range(4)
    un_perm.shuffle()      # un_perm[k] = ítem cuya definición está en la tarjeta derecha k
    _mostrar_unir()

func _mostrar_unir() -> void:
    _limpiar()
    cerrado = false
    un_links.clear()
    un_ver.clear()
    un_sel_lado = -1
    un_sel_idx = -1
    un_botones = [[], []]
    y_msg = 1330.0
    y_btn = 1460.0
    _cabecera()
    GameUI.label(holder, I18n.t("un2_hint"), Vector2(100, 352), Vector2(880, 90), 28, Color("#e6f6ff"), true, 6)
    for i in range(4):
        var y: float = 455.0 + float(i) * 210.0
        var t: String = str(un_items[i].get("t", un_items[i]["p"]))
        var bl := GameUI.flat_button(holder, Vector2(90, y), Vector2(370, 190), CREMA, MORADO, _un_tocar.bind(0, i), 36, 5)
        bl.text = t
        bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        bl.add_theme_font_size_override("font_size", 40 if t.length() <= 9 else 32)
        un_botones[0].append(bl)
        var d: String = str(un_items[int(un_perm[i])]["d"])
        var br := GameUI.flat_button(holder, Vector2(490, y), Vector2(500, 190), CREMA, MORADO, _un_tocar.bind(1, i), 36, 5)
        br.text = d
        br.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        br.add_theme_font_size_override("font_size", 29)
        un_botones[1].append(br)
    un_msg = GameUI.label(holder, "", Vector2(100, 1300), Vector2(880, 60), 32, Color("#ffd8a0"), true, 6)
    un_ctrl = Control.new()
    un_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    holder.add_child(un_ctrl)
    GameUI.glossy(un_ctrl, I18n.t("cr_check"), Vector2(240, 1380), Vector2(600, 110), Color("#3fd35a"), Color.WHITE, _un_comprobar, 44)
    _boton_niveles()
    _un_pintar()

func _un_dueno(k: int) -> int:
    for i in un_links.keys():
        if int(un_links[i]) == k:
            return int(i)
    return -1

func _un_pintar() -> void:
    for i in range(4):
        var bl: Button = un_botones[0][i]
        var br: Button = un_botones[1][i]
        var fill_l: Color = CREMA
        var txt_l: Color = COLOR_TXT
        var borde_l: Color = MORADO
        var ancho_l: int = 5
        if un_links.has(i):
            fill_l = PAREJAS[i]
            txt_l = Color.WHITE
        if un_sel_lado == 0 and un_sel_idx == i:
            borde_l = Color("#ffd23f")
            ancho_l = 10
        var fill_r: Color = CREMA
        var txt_r: Color = COLOR_TXT
        var borde_r: Color = MORADO
        var ancho_r: int = 5
        var d: int = _un_dueno(i)
        if d >= 0:
            fill_r = PAREJAS[d]
            txt_r = Color.WHITE
        if un_sel_lado == 1 and un_sel_idx == i:
            borde_r = Color("#ffd23f")
            ancho_r = 10
        if not un_ver.is_empty():
            if un_links.has(i):
                var ok_l: bool = bool(un_ver[i])
                fill_l = VERDE_OK if ok_l else ROJO_MAL
            if d >= 0:
                var ok_r: bool = bool(un_ver[d])
                fill_r = VERDE_OK if ok_r else ROJO_MAL
        _estilo(bl, fill_l, borde_l, ancho_l, txt_l)
        _estilo(br, fill_r, borde_r, ancho_r, txt_r)

func _un_tocar(lado: int, i: int) -> void:
    if cerrado:
        return
    un_msg.text = ""
    # tocar algo ya unido deshace esa pareja
    if lado == 0 and un_links.has(i):
        un_links.erase(i)
        un_sel_lado = -1
        un_sel_idx = -1
        _un_pintar()
        return
    if lado == 1:
        var d: int = _un_dueno(i)
        if d >= 0:
            un_links.erase(d)
            un_sel_lado = -1
            un_sel_idx = -1
            _un_pintar()
            return
    if un_sel_lado == -1 or un_sel_lado == lado:
        un_sel_lado = lado
        un_sel_idx = i
    else:
        var izq: int = un_sel_idx if un_sel_lado == 0 else i
        var der: int = i if un_sel_lado == 0 else un_sel_idx
        un_links[izq] = der
        un_sel_lado = -1
        un_sel_idx = -1
    _un_pintar()

func _un_comprobar() -> void:
    if cerrado:
        return
    if un_links.size() < 4:
        un_msg.text = I18n.t("un2_fill")
        return
    cerrado = true
    var todo: bool = true
    for i in range(4):
        var k: int = int(un_links[i])
        var ok: bool = int(un_perm[k]) == i
        un_ver[i] = ok
        if not ok:
            todo = false
    _un_pintar()
    un_ctrl.queue_free()
    un_msg.queue_free()
    if todo:
        _acierto()
    else:
        _fallo()

# ============================================================ CRUCIGRAMA

func _preparar_cruci() -> void:
    cr = EduRun.tomar_cruci(cat, idx)
    if cr.is_empty():
        _sin_preguntas()
        return
    usado_p = cr["usadas"]
    cr_fil.clear()
    cr_bloq.clear()
    cr_ver.clear()
    for f in cr["filas"]:
        var largo: int = str(f["p"]).length()
        var celdas: Array = []
        var bloq: Array = []
        for j in range(largo):
            celdas.append("")
            bloq.append(false)
        cr_fil.append(celdas)
        cr_bloq.append(bloq)
        cr_ver.append(true)
    cr_sel = 0
    _mostrar_cruci()

func _mostrar_cruci() -> void:
    _limpiar()
    cerrado = false
    cr_cajas.clear()
    cr_letras.clear()
    y_msg = 1285.0
    y_btn = 1420.0
    _cabecera()
    GameUI.label(holder, I18n.t("cr_hint"), Vector2(100, 352), Vector2(880, 80), 28, Color("#e6f6ff"), true, 6)
    var filas: Array = cr["filas"]
    var n: int = filas.size()
    var cols: int = int(cr["cols"])
    var izq: int = int(cr["izq"])
    var cs: int = mini(62, int(floor(820.0 / float(cols))))
    var x_area: float = 150.0 + (820.0 - float(cols * cs)) / 2.0
    var y0: float = 445.0
    var paso: float = float(cs) + 12.0
    for r in range(n):
        var f: Dictionary = filas[r]
        var p: String = str(f["p"])
        var y: float = y0 + float(r) * paso
        var xr: float = x_area + float(izq - int(f["col"])) * float(cs)
        GameUI.label(holder, str(r + 1), Vector2(95, y), Vector2(50, cs), 30, Color("#ffd23f"), false, 5)
        var cajas: Array = []
        var letras: Array = []
        for j in range(p.length()):
            var caja := Panel.new()
            caja.position = Vector2(xr + float(j * cs), y)
            caja.size = Vector2(cs, cs)
            caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
            holder.add_child(caja)
            var lt := Label.new()
            lt.size = Vector2(cs, cs)
            lt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            lt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
            lt.add_theme_font_size_override("font_size", int(float(cs) * 0.62))
            lt.add_theme_color_override("font_color", COLOR_TXT)
            lt.mouse_filter = Control.MOUSE_FILTER_IGNORE
            caja.add_child(lt)
            cajas.append(caja)
            letras.append(lt)
        cr_cajas.append(cajas)
        cr_letras.append(letras)
        GameUI.flat_button(holder, Vector2(xr, y), Vector2(p.length() * cs, cs), Color(0, 0, 0, 0), Color(0, 0, 0, 0), _cr_elegir.bind(r), 6, 0)
    # pistas
    var yp: float = y0 + float(n) * paso + 18.0
    for r in range(n):
        var l := GameUI.left_label(holder, "%d. %s" % [r + 1, str(filas[r]["d"])], Vector2(100, yp + float(r) * 58.0), Vector2(880, 56), 27, Color("#e6f6ff"), false)
        l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    if str(cr["clave"]) != "":
        var lk := GameUI.left_label(holder, I18n.t("cr_key") % str(cr["clave_d"]), Vector2(100, yp + float(n) * 58.0 + 6.0), Vector2(880, 56), 27, Color("#ffd23f"), false)
        lk.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    # teclado y botones
    cr_msg = GameUI.label(holder, "", Vector2(100, 1205), Vector2(880, 50), 28, Color("#ffd8a0"), true, 6)
    cr_ctrl = Control.new()
    cr_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    holder.add_child(cr_ctrl)
    var total: int = TECLAS.length()
    for i in range(total):
        @warning_ignore("integer_division")
        var fila: int = i / 9
        var col: int = i % 9
        var pos := Vector2(112.0 + float(col) * 96.0, 1262.0 + float(fila) * 92.0)
        var tecla: String = TECLAS.substr(i, 1)
        var b := GameUI.flat_button(cr_ctrl, pos, Vector2(88, 84), CREMA, MORADO, _cr_tecla.bind(tecla), 20, 4)
        b.text = tecla
        b.add_theme_font_size_override("font_size", 42)
        _estilo(b, CREMA, MORADO, 4, COLOR_TXT, 20)
    var bb := GameUI.glossy(cr_ctrl, "⌫", Vector2(90, 1552), Vector2(200, 95), Color("#f0524a"), Color.WHITE, _cr_borrar, 46)
    bb.focus_mode = Control.FOCUS_NONE
    GameUI.glossy(cr_ctrl, I18n.t("cr_check"), Vector2(305, 1552), Vector2(340, 95), Color("#3fd35a"), Color.WHITE, _cr_comprobar, 38)
    GameUI.glossy(cr_ctrl, I18n.t("hint_btn") % Jugador.COSTO_PISTA, Vector2(660, 1552), Vector2(330, 95), Color("#8a4de8"), Color.WHITE, _pista_cruci, 32, 46, false)
    _boton_niveles()
    _cr_pintar()

func _cr_elegir(r: int) -> void:
    if cerrado:
        return
    cr_sel = r
    _cr_pintar()

# Primera celda vacía de una fila (-1 si está llena)
func _cr_vacia(r: int) -> int:
    var celdas: Array = cr_fil[r]
    for j in range(celdas.size()):
        if str(celdas[j]) == "":
            return j
    return -1

# Texto escrito en una fila
func _cr_texto(r: int) -> String:
    var celdas: Array = cr_fil[r]
    var t: String = ""
    for j in range(celdas.size()):
        t += str(celdas[j])
    return t

# Al llenar una fila pasa a la siguiente que falte por completar
func _cr_avanzar() -> void:
    if _cr_vacia(cr_sel) >= 0:
        return
    var n: int = cr_fil.size()
    for paso in range(1, n):
        var r: int = (cr_sel + paso) % n
        if _cr_vacia(r) >= 0:
            cr_sel = r
            break

func _cr_tecla(letra: String) -> void:
    if cerrado:
        return
    cr_msg.text = ""
    var j: int = _cr_vacia(cr_sel)
    if j >= 0:
        var celdas: Array = cr_fil[cr_sel]
        celdas[j] = letra
    _cr_avanzar()
    _cr_pintar()

func _cr_borrar() -> void:
    if cerrado:
        return
    var celdas: Array = cr_fil[cr_sel]
    var bloq: Array = cr_bloq[cr_sel]
    var j: int = celdas.size() - 1
    while j >= 0:
        if str(celdas[j]) != "" and not bool(bloq[j]):
            celdas[j] = ""
            break
        j -= 1
    cr_msg.text = ""
    _cr_pintar()

# Pista del crucigrama: cuesta 3 gemas y revela 1 letra al azar que aún no se ha descubierto de la palabra seleccionada.
func _pista_cruci() -> void:
    if cerrado:
        return
    var celdas: Array = cr_fil[cr_sel]
    var bloq: Array = cr_bloq[cr_sel]
    var palabra: String = str(cr["filas"][cr_sel]["p"])
    var pendientes: Array = []
    for j in range(palabra.length()):
        if str(celdas[j]) != palabra.substr(j, 1):
            pendientes.append(j)
    if pendientes.is_empty():
        cr_msg.text = I18n.t("hint_done")
        return
    var tiene: int = Jugador.gemas()
    if tiene < Jugador.COSTO_PISTA:
        cr_msg.text = I18n.t("hint_need") % [Jugador.COSTO_PISTA, tiene]
        return
    if not Jugador.gastar_gemas(Jugador.COSTO_PISTA):
        return
    _gemas_refrescar()
    var elegida: int = int(pendientes[randi() % pendientes.size()])
    celdas[elegida] = palabra.substr(elegida, 1)
    bloq[elegida] = true
    cr_msg.text = I18n.t("hint_paid") % [Jugador.COSTO_PISTA, Jugador.gemas()]
    _cr_avanzar()
    _cr_pintar()

func _cr_pintar() -> void:
    var filas: Array = cr["filas"]
    for r in range(filas.size()):
        var f: Dictionary = filas[r]
        var celdas: Array = cr_fil[r]
        var bloq: Array = cr_bloq[r]
        for j in range(str(f["p"]).length()):
            var caja: Panel = cr_cajas[r][j]
            var lt: Label = cr_letras[r][j]
            var es_clave: bool = j == int(f["col"]) and str(cr["clave"]) != ""
            var fill: Color = Color("#ffe08a") if es_clave else CREMA
            if bool(bloq[j]):
                fill = Color("#bfe3ff")     # letra revelada con pista
            var borde: Color = MORADO
            var ancho: int = 3
            if r == cr_sel and not cerrado:
                borde = Color("#3bd0ff")
                ancho = 6
            if cerrado:
                fill = Color("#b8f2b0") if bool(cr_ver[r]) else Color("#f3a6a0")
                borde = VERDE_OK if bool(cr_ver[r]) else ROJO_MAL
            caja.add_theme_stylebox_override("panel", GameUI.flat_box(fill, borde, 10, ancho))
            lt.text = str(celdas[j])

func _cr_comprobar() -> void:
    if cerrado:
        return
    var filas: Array = cr["filas"]
    for r in range(filas.size()):
        if _cr_vacia(r) >= 0:
            cr_msg.text = I18n.t("cr_fill")
            return
    cerrado = true
    var todo: bool = true
    for r in range(filas.size()):
        var correcta: String = str(filas[r]["p"])
        var ok: bool = _cr_texto(r) == correcta
        cr_ver[r] = ok
        if not ok:
            todo = false
            var celdas: Array = cr_fil[r]
            for j in range(correcta.length()):
                celdas[j] = correcta.substr(j, 1)      # se muestra la palabra correcta en las filas falladas
    _cr_pintar()
    cr_ctrl.queue_free()
    cr_msg.queue_free()
    if todo:
        _acierto()
    else:
        _fallo()

# ============================================================ CRUCIGRAMA DE CHIBOLO (nivel 9)
# Tablero 12x12 con 8 palabras que se cruzan (datos en CrucigramaChibolo.gd). Se toca una palabra, se escribe con el teclado
# y cada palabra correcta se fija en verde y se tacha de la lista. Al encontrar las 8 se supera el nivel.

func _k(r: int, c: int) -> String:
    return "%d,%d" % [r, c]

# Celdas (fila, columna) que ocupa la palabra i
func _ch_celdas_de(i: int) -> Array:
    var w: Dictionary = ch_pal[i]
    var largo: int = str(w["p"]).length()
    var vertical: bool = bool(w["v"])
    var r0: int = int(w["f"])
    var c0: int = int(w["c"])
    var salida: Array = []
    for j in range(largo):
        var dr: int = j if vertical else 0
        var dc: int = 0 if vertical else j
        salida.append(Vector2i(r0 + dr, c0 + dc))
    return salida

func _ch_llena(i: int) -> bool:
    for v in _ch_celdas_de(i):
        var pos: Vector2i = v
        if str(ch_celdas[_k(pos.x, pos.y)]) == "":
            return false
    return true

func _ch_encontradas() -> int:
    var n: int = 0
    for ok in ch_ok:
        if bool(ok):
            n += 1
    return n

func _preparar_chibolo() -> void:
    ch_pal = CrucigramaChibolo.COLOCADAS.duplicate(true)
    ch_celdas.clear()
    ch_bloq.clear()
    ch_ok.clear()
    for i in range(ch_pal.size()):
        ch_ok.append(false)
        for v in _ch_celdas_de(i):
            var pos: Vector2i = v
            ch_celdas[_k(pos.x, pos.y)] = ""
    ch_sel = 0
    _mostrar_chibolo()

func _mostrar_chibolo() -> void:
    _limpiar()
    cerrado = false
    ch_cajas.clear()
    ch_letras.clear()
    ch_lista.clear()
    y_msg = 1430.0
    y_btn = 1560.0
    _cabecera()
    # pista general arriba
    GameUI.label(holder, I18n.t("ch_pista"), Vector2(90, 350), Vector2(900, 50), 30, Color("#ffd23f"), true, 6)
    # tablero 12x12
    var tam: int = CrucigramaChibolo.TAM
    var cs: int = 60
    var x0: float = 540.0 - float(tam * cs) / 2.0
    var y0: float = 408.0
    GameUI.frame(holder, Rect2(x0 - 10.0, y0 - 10.0, float(tam * cs) + 20.0, float(tam * cs) + 20.0), Color("#4a5fc8"), 3, 20, false, Color(0.05, 0.06, 0.16, 0.7))
    for r in range(tam):
        for c in range(tam):
            var pos := Vector2(x0 + float(c * cs), y0 + float(r * cs))
            var caja := Panel.new()
            caja.position = pos
            caja.size = Vector2(cs, cs)
            caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
            holder.add_child(caja)
            var k: String = _k(r, c)
            if not ch_celdas.has(k):
                # casilla sin letra: solo se dibuja tenue para que se vea el tablero de 12x12
                caja.add_theme_stylebox_override("panel", GameUI.flat_box(Color(0.12, 0.13, 0.30, 0.45), Color(0.25, 0.28, 0.5, 0.5), 6, 1))
                continue
            var lt := Label.new()
            lt.size = Vector2(cs, cs)
            lt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            lt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
            lt.add_theme_font_size_override("font_size", int(float(cs) * 0.62))
            lt.add_theme_color_override("font_color", COLOR_TXT)
            lt.mouse_filter = Control.MOUSE_FILTER_IGNORE
            caja.add_child(lt)
            ch_cajas[k] = caja
            ch_letras[k] = lt
            GameUI.flat_button(holder, pos, Vector2(cs, cs), Color(0, 0, 0, 0), Color(0, 0, 0, 0), _ch_tocar.bind(r, c), 6, 0)
    # contador y lista de palabras (se tachan al encontrarlas)
    ch_cont = GameUI.label(holder, I18n.t("ch_words") % [0, ch_pal.size()], Vector2(90, 1142), Vector2(900, 42), 32, Color("#5cf0ff"), false, 6)
    for i in range(ch_pal.size()):
        @warning_ignore("integer_division")
        var col: int = i / 4
        var fila: int = i % 4
        var tx: String = str(ch_pal[i]["t"])
        var lx: float = 120.0 + float(col) * 450.0
        var ly: float = 1188.0 + float(fila) * 42.0
        var l: Label = GameUI.left_label(holder, tx, Vector2(lx, ly), Vector2(430, 40), 30, Color("#e6f6ff"), false)
        var ancho: float = l.get_theme_font("font").get_string_size(tx, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
        var raya := ColorRect.new()
        raya.color = Color("#ff6b6b")
        raya.position = Vector2(lx - 4.0, ly + 19.0)
        raya.size = Vector2(ancho + 8.0, 4.0)
        raya.mouse_filter = Control.MOUSE_FILTER_IGNORE
        raya.visible = false
        holder.add_child(raya)
        ch_lista.append([l, raya])
    ch_msg = GameUI.label(holder, "", Vector2(90, 1360), Vector2(900, 40), 28, Color("#ffd8a0"), true, 6)
    # teclado, borrar y pista
    ch_ctrl = Control.new()
    ch_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    holder.add_child(ch_ctrl)
    var total: int = TECLAS.length()
    for i in range(total):
        @warning_ignore("integer_division")
        var fila_t: int = i / 9
        var col_t: int = i % 9
        var posk := Vector2(112.0 + float(col_t) * 96.0, 1406.0 + float(fila_t) * 76.0)
        var tecla: String = TECLAS.substr(i, 1)
        var b := GameUI.flat_button(ch_ctrl, posk, Vector2(88, 70), CREMA, MORADO, _ch_tecla.bind(tecla), 20, 4)
        b.text = tecla
        b.add_theme_font_size_override("font_size", 40)
        _estilo(b, CREMA, MORADO, 4, COLOR_TXT, 20)
    var bb := GameUI.glossy(ch_ctrl, "⌫", Vector2(90, 1640), Vector2(200, 86), Color("#f0524a"), Color.WHITE, _ch_borrar, 46)
    bb.focus_mode = Control.FOCUS_NONE
    GameUI.glossy(ch_ctrl, I18n.t("hint_btn") % Jugador.COSTO_PISTA, Vector2(310, 1640), Vector2(680, 86), Color("#8a4de8"), Color.WHITE, _pista_chibolo, 38, 46, false)
    _boton_niveles()
    _ch_pintar()

# Tocar una casilla selecciona la palabra que pasa por ella (en un cruce alterna entre las dos)
func _ch_tocar(r: int, c: int) -> void:
    if cerrado:
        return
    var cand: Array = []
    for i in range(ch_pal.size()):
        for v in _ch_celdas_de(i):
            var pos: Vector2i = v
            if pos.x == r and pos.y == c:
                cand.append(i)
    if cand.is_empty():
        return
    var actual: int = cand.find(ch_sel)
    if actual >= 0:
        ch_sel = int(cand[(actual + 1) % cand.size()])
    else:
        ch_sel = int(cand[0])
    ch_msg.text = ""
    _ch_pintar()

func _ch_tecla(letra: String) -> void:
    if cerrado:
        return
    ch_msg.text = ""
    if not bool(ch_ok[ch_sel]):
        for v in _ch_celdas_de(ch_sel):
            var pos: Vector2i = v
            var k: String = _k(pos.x, pos.y)
            if str(ch_celdas[k]) == "":
                ch_celdas[k] = letra
                break
    _ch_revisar()
    if not cerrado and not bool(ch_ok[ch_sel]) and _ch_llena(ch_sel):
        ch_msg.text = I18n.t("ch_wrong")

func _ch_borrar() -> void:
    if cerrado:
        return
    var cs: Array = _ch_celdas_de(ch_sel)
    var j: int = cs.size() - 1
    while j >= 0:
        var pos: Vector2i = cs[j]
        var k: String = _k(pos.x, pos.y)
        if str(ch_celdas[k]) != "" and not ch_bloq.has(k):
            ch_celdas[k] = ""
            break
        j -= 1
    ch_msg.text = ""
    _ch_pintar()

# Pista: cuesta 3 gemas y revela 1 letra al azar que aún no se ha descubierto de la palabra seleccionada.
func _pista_chibolo() -> void:
    if cerrado:
        return
    var cs: Array = _ch_celdas_de(ch_sel)
    var palabra: String = str(ch_pal[ch_sel]["p"])
    var pendientes: Array = []
    for j in range(cs.size()):
        var pos: Vector2i = cs[j]
        if str(ch_celdas[_k(pos.x, pos.y)]) != palabra.substr(j, 1):
            pendientes.append(j)
    if pendientes.is_empty():
        ch_msg.text = I18n.t("hint_done")
        return
    var tiene: int = Jugador.gemas()
    if tiene < Jugador.COSTO_PISTA:
        ch_msg.text = I18n.t("hint_need") % [Jugador.COSTO_PISTA, tiene]
        return
    if not Jugador.gastar_gemas(Jugador.COSTO_PISTA):
        return
    _gemas_refrescar()
    var elegida: int = int(pendientes[randi() % pendientes.size()])
    var pe: Vector2i = cs[elegida]
    var ke: String = _k(pe.x, pe.y)
    ch_celdas[ke] = palabra.substr(elegida, 1)
    ch_bloq[ke] = "pista"
    Audio.play("chime")
    _ch_revisar()
    if not cerrado:
        ch_msg.text = I18n.t("hint_paid") % [Jugador.COSTO_PISTA, Jugador.gemas()]

# Marca como encontradas las palabras que ya están completas y bien escritas
func _ch_revisar() -> void:
    var nuevas: int = 0
    for i in range(ch_pal.size()):
        if bool(ch_ok[i]):
            continue
        var palabra: String = str(ch_pal[i]["p"])
        var escrito: String = ""
        var cs: Array = _ch_celdas_de(i)
        for v in cs:
            var pos: Vector2i = v
            escrito += str(ch_celdas[_k(pos.x, pos.y)])
        if escrito == palabra:
            ch_ok[i] = true
            nuevas += 1
            for v in cs:
                var pos2: Vector2i = v
                ch_bloq[_k(pos2.x, pos2.y)] = "ok"
            var par: Array = ch_lista[i]
            var lbl: Label = par[0]
            var raya: ColorRect = par[1]
            lbl.add_theme_color_override("font_color", Color("#8fd99a"))
            raya.visible = true
    if nuevas > 0:
        Audio.play("chime")
    var total: int = _ch_encontradas()
    ch_cont.text = I18n.t("ch_words") % [total, ch_pal.size()]
    # si la palabra seleccionada ya se encontró, pasa a la siguiente pendiente
    if bool(ch_ok[ch_sel]) and total < ch_pal.size():
        for paso in range(1, ch_pal.size()):
            var i2: int = (ch_sel + paso) % ch_pal.size()
            if not bool(ch_ok[i2]):
                ch_sel = i2
                break
    _ch_pintar()
    if total >= ch_pal.size():
        _ch_gano()

func _ch_pintar() -> void:
    var en_sel: Dictionary = {}
    for v in _ch_celdas_de(ch_sel):
        var ps: Vector2i = v
        en_sel[_k(ps.x, ps.y)] = true
    var en_mal: Dictionary = {}
    for i in range(ch_pal.size()):
        if not bool(ch_ok[i]) and _ch_llena(i):
            for v in _ch_celdas_de(i):
                var pm: Vector2i = v
                en_mal[_k(pm.x, pm.y)] = true
    for k in ch_cajas.keys():
        var caja: Panel = ch_cajas[k]
        var lt: Label = ch_letras[k]
        var fill: Color = CREMA
        var borde: Color = MORADO
        var ancho: int = 3
        var estado: String = str(ch_bloq.get(k, ""))
        if estado == "pista":
            fill = Color("#bfe3ff")
        if en_mal.has(k) and estado != "ok":
            fill = Color("#f3a6a0")
        if estado == "ok":
            fill = Color("#b8f2b0")
            borde = VERDE_OK
        if en_sel.has(k) and not cerrado:
            borde = Color("#3bd0ff")
            ancho = 6
        caja.add_theme_stylebox_override("panel", GameUI.flat_box(fill, borde, 8, ancho))
        lt.text = str(ch_celdas[k])

func _ch_gano() -> void:
    cerrado = true
    ch_ctrl.queue_free()
    ch_msg.queue_free()
    _ch_pintar()
    _acierto()

# ============================================================ RESULTADO (común a todos los formatos)

func _acierto() -> void:
    Audio.play("win")
    Jugador.registrar_respuesta(cat, true)
    var antes: int = Global.edu_run(cat, idx)
    var nueva: String = ""
    if nivel > antes:
        Global.edu_run_set(cat, idx, nivel)
        if nivel == Global.EDU_NIVEL_VIDA and Global.edu_vidas() < Global.EDU_VIDAS_MAX:
            Global.edu_vidas_sumar(1)   # al pasar el nivel 12 se gana una vida
            vida_ganada = true
    if nivel > Global.edu_mejor(cat, idx):
        nueva = Global.edu_registrar_progreso(cat, idx, nivel)   # cuenta para desbloquear la siguiente área
    await get_tree().create_timer(0.9).timeout
    if not is_inside_tree():
        return
    if nueva != "":
        await _popup_area(nueva)
        if not is_inside_tree():
            return
    if nivel >= Global.EDU_PREGUNTAS:
        _termino()
    else:
        _resultado(true)

func _fallo() -> void:
    Audio.play("error")
    Jugador.registrar_respuesta(cat, false)
    # lo fallado vuelve al FINAL de la cola: no se repite enseguida
    if not usado_q.is_empty():
        EduRun.devolver_pregunta(cat, idx, usado_q)
    if not usado_p.is_empty():
        EduRun.devolver_palabras(cat, idx, usado_p)
    modo_fallo = ""
    if nivel >= Global.EDU_NIVEL_RIESGO:
        var n: int = EduRun.sumar_error(cat, idx)
        if n >= Global.EDU_ERRORES_MAX:
            if Global.edu_vidas() > 0:
                Global.edu_vidas_sumar(-1)          # gasta una vida y sigue en el mismo nivel
                EduRun.limpiar_errores(cat, idx)
                modo_fallo = "vida"
            else:
                # Pierde el avance (vuelve al nivel 1), pero guardamos una copia por si paga las gemas para salvarse
                EduRun.guardar_salvavidas(cat, idx, Global.edu_run(cat, idx))
                Global.edu_run_set(cat, idx, 0)
                EduRun.reiniciar(cat, idx)
                modo_fallo = "reinicio"
    _resultado(false)

func _resultado(acerto: bool) -> void:
    if acerto:
        var t: String = "✅ " + I18n.t("lvl_correct_fmt") % 2
        if vida_ganada:
            t += "\n❤️ " + I18n.t("lvl_life_gain")
        GameUI.label(holder, t, Vector2(100, y_msg), Vector2(880, 110), 38, Color("#b8f2b0"), true, 7)
        GameUI.glossy(holder, I18n.t("lvl_next_level"), Vector2(240, y_btn), Vector2(600, 110), Color("#3fd35a"), Color.WHITE, _siguiente_nivel, 42)
        return
    var msg: String = "💔 " + I18n.t("lvl_wrong")
    var boton: String = I18n.t("qz_retry")
    var cb: Callable = _reintentar
    if modo_fallo == "vida":
        msg = "💔 " + I18n.t("lvl_life_used") % nivel
    elif modo_fallo == "reinicio":
        GameUI.label(holder, "💔 " + I18n.t("lvl_reset"), Vector2(100, y_msg), Vector2(880, 110), 36, Color("#ffb0b0"), true, 7)
        _popup_salvar()
        return
    GameUI.label(holder, msg, Vector2(100, y_msg), Vector2(880, 110), 36, Color("#ffb0b0"), true, 7)
    GameUI.glossy(holder, boton, Vector2(240, y_btn), Vector2(600, 110), Color("#f0524a"), Color.WHITE, cb, 42)

# Aviso al llegar a 30 preguntas respondidas en el área: se desbloquea la siguiente. Se puede esperar con: await _popup_area(id)
func _popup_area(id_area: String) -> void:
    Audio.play("win")
    var p := GameUI.neon_modal(self, Vector2(820, 640))
    GameUI.label(p, "🔓", Vector2(0, 40), Vector2(820, 130), 90)
    GameUI.label(p, I18n.t("edu_area_unlocked"), Vector2(30, 185), Vector2(760, 100), 62, Color("#c8f03a"), false, 8)
    var nombre: String = I18n.t(str(Global.EDU_NOMBRE.get(id_area, "edu_title")))
    GameUI.label(p, I18n.t("edu_area_unlocked_fmt") % nombre, Vector2(60, 300), Vector2(700, 170), 36, Color("#f1ecff"), true, 5)
    GameUI.pill(p, I18n.t("on_ok"), Vector2(210, 490), Vector2(400, 110), "green", GameUI.close_modal.bind(p), 40)
    await p.tree_exited

# Ventana tras 2 errores sin vidas: pagar 2 gemas para seguir donde iba, o volver al nivel 1.
func _popup_salvar() -> void:
    await get_tree().create_timer(0.8).timeout
    if not is_inside_tree():
        return
    var p := GameUI.neon_modal(self, Vector2(860, 830))
    GameUI.label(p, "💔", Vector2(0, 40), Vector2(860, 110), 80)
    GameUI.label(p, I18n.t("salv_title"), Vector2(30, 160), Vector2(800, 90), 52, Color("#ffd23f"), false, 8)
    GameUI.label(p, I18n.t("salv_msg") % [Jugador.COSTO_SALVAR, Jugador.gemas()], Vector2(60, 265), Vector2(740, 220), 34, Color("#f1ecff"), true, 5)
    salv_msg = GameUI.label(p, "", Vector2(60, 490), Vector2(740, 70), 30, Color("#ffd8a0"), true, 6)
    GameUI.pill(p, I18n.t("salv_pay") % Jugador.COSTO_SALVAR, Vector2(110, 570), Vector2(640, 100), "green", _salvar_pagar.bind(p), 38)
    GameUI.pill(p, I18n.t("lvl_reset_btn"), Vector2(110, 690), Vector2(640, 100), "red", _salvar_no.bind(p), 38)

func _salvar_pagar(p: Control) -> void:
    if not EduRun.hay_salvavidas(cat, idx):
        _salvar_no(p)
        return
    var tiene: int = Jugador.gemas()
    if tiene < Jugador.COSTO_SALVAR:
        salv_msg.text = I18n.t("hint_need") % [Jugador.COSTO_SALVAR, tiene]
        return
    if not Jugador.gastar_gemas(Jugador.COSTO_SALVAR):
        return
    var previo: int = EduRun.restaurar_salvavidas(cat, idx)
    if previo >= 0:
        Global.edu_run_set(cat, idx, previo)    # recupera el avance que tenía
    Audio.play("chime")
    GameUI.close_modal(p)
    get_tree().reload_current_scene()            # sigue en el mismo nivel, con 0 errores

func _salvar_no(p: Control) -> void:
    EduRun.descartar_salvavidas(cat, idx)
    GameUI.close_modal(p)
    _al_nivel_uno()

func _siguiente_nivel() -> void:
    Global.nivel_pregunta = mini(nivel + 1, Global.EDU_PREGUNTAS)
    get_tree().reload_current_scene()

func _reintentar() -> void:
    get_tree().reload_current_scene()

func _al_nivel_uno() -> void:
    Global.nivel_pregunta = 1
    get_tree().reload_current_scene()

# Nivel 20 acertado: se supera la dificultad.
func _termino() -> void:
    if not Global.edu_nivel_pasado(cat, idx):
        Jugador.sumar_gemas(Jugador.GEMAS_NIVEL)   # gema por superar una dificultad por primera vez
    Global.edu_pasar_nivel(cat, idx)
    EduRun.reiniciar(cat, idx)
    get_tree().change_scene_to_file("res://EducativoGano.tscn")

func _ir_niveles() -> void:
    get_tree().change_scene_to_file("res://EducativoLista.tscn")
