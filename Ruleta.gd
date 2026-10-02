extends Control

var wheel: RuletaRueda
var spinning: bool = false
var free_label: Label
var cards: Dictionary = {}
var spin_btn: Button
var _modal: Panel = null
var _ronda_vista: int = 0
var _seg_ultimo: int = 0
var _paso_tick: float = 1.0
var club: bool = false           # partida del Club Privado: cada giro elimina a un participante
var vivos: Array[int] = []

func _ready() -> void:
    club = Global.club_modo and not Online.activo
    GameUI.bg_tema(self, "res://assets/bg_ruleta.jpg")
    GameUI.glossy(self, I18n.t("exit"), Vector2(75, 104), Vector2(288, 96), Color("#ffc933"), GameUI.DARK_TEXT, _salir, 44, 48)
    GameUI.glossy(self, I18n.t("plan"), Vector2(389, 104), Vector2(284, 96), Color("#2f7df0"), Color.WHITE, _plan, 44, 48)
    if Online.activo:
        GameUI.label(self, "🌐 " + Online.codigo, Vector2(699, 104), Vector2(306, 96), 44, Color("#ffd867"), false, 8)
    else:
        GameUI.glossy(self, I18n.t("restart"), Vector2(699, 104), Vector2(306, 96), Color("#e8322e"), Color.WHITE, _reiniciar, 44, 48)

    wheel = RuletaRueda.new()
    wheel.position = Vector2(170, 300)
    wheel.size = Vector2(740, 740)
    add_child(wheel)
    if club:
        for i in range(maxi(Global.n_jugadores(), 1)):
            vivos.append(i)
        Global.club_vivos = vivos
        wheel.set_ids(vivos)
    _crear_flecha()

    spin_btn = GameUI.glossy(self, I18n.t("spin_wheel"), Vector2(270, 1085), Vector2(500, 112), Color("#f3f4f9"), Color("#14204f"), _girar, 52, 56)
    GameUI.voz_boton(self, Vector2(820, 1093), 96)
    if Online.activo:
        _ronda_vista = Online.ronda_id()
        if not Online.soy_host:
            spin_btn.disabled = true
            spin_btn.text = I18n.t("on_wait_host")
            spin_btn.add_theme_font_size_override("font_size", 30)
        Online.sala_actualizada.connect(_on_sala)
        Online.sala_cerrada.connect(_on_sala_cerrada)
    free_label = GameUI.label(self, "", Vector2(100, 1218), Vector2(880, 50), 32, Color("#f6d9a0"))
    _actualizar_gratis()

    var quienes := GameUI.label(self, "👥  " + I18n.t("names_label"), Vector2(130, 1275), Vector2(820, 50), 34, Color("#ffe2a0"))
    quienes.add_theme_constant_override("outline_size", 6)
    quienes.add_theme_color_override("font_outline_color", Color("#1a0d00"))
    _crear_jugadores()

func _crear_flecha() -> void:
    # Triángulo dorado que apunta a la porción elegida (arriba de la ruleta)
    var pts := PackedVector2Array([Vector2(-54, 0), Vector2(54, 0), Vector2(0, 104)])
    var relleno := Polygon2D.new()
    relleno.polygon = pts
    relleno.color = Color(1, 0.86, 0.3, 0.3)
    relleno.position = Vector2(540, 286)
    add_child(relleno)
    for k in range(2):
        var l := Line2D.new()
        l.points = pts
        l.closed = true
        l.width = 16.0 if k == 0 else 7.0
        l.default_color = Color(1, 0.8, 0.2, 0.3) if k == 0 else Color("#ffe27a")
        l.joint_mode = Line2D.LINE_JOINT_ROUND
        l.position = Vector2(540, 286)
        add_child(l)

func _process(_delta: float) -> void:
    if not spinning:
        return
    var seg: int = int(floor(wheel.rotation / _paso_tick))
    if seg != _seg_ultimo:
        _seg_ultimo = seg
        Audio.play("tick", -8.0)

func _actualizar_gratis() -> void:
    if club:
        free_label.text = I18n.t("club_quedan_fmt") % vivos.size()
        return
    if Online.activo:
        free_label.text = I18n.t("on_pool_fmt") % Global.retos.size()
        return
    free_label.text = I18n.t("free_left_fmt") % maxi(0, Global.LIMITE_GRATIS - Global.tiradas_usadas)

func _crear_jugadores() -> void:
    var scroll := ScrollContainer.new()
    scroll.position = Vector2(84, 1325)
    scroll.size = Vector2(912, 560)
    add_child(scroll)
    var margen := MarginContainer.new()
    margen.add_theme_constant_override("margin_left", 20)
    margen.add_theme_constant_override("margin_right", 20)
    margen.add_theme_constant_override("margin_top", 14)
    margen.add_theme_constant_override("margin_bottom", 14)
    scroll.add_child(margen)
    var grid := GridContainer.new()
    grid.columns = 3
    grid.add_theme_constant_override("h_separation", 26)
    grid.add_theme_constant_override("v_separation", 26)
    margen.add_child(grid)
    for i in range(maxi(Global.n_jugadores(), 1)):
        var c := _tarjeta(i, false)
        grid.add_child(c)
        cards[i] = c

func _tarjeta(i: int, resaltada: bool) -> Panel:
    var card := Panel.new()
    card.custom_minimum_size = Vector2(262, 244)
    card.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _estilo_tarjeta(card, i, resaltada)
    var col: Color = Global.color_de(i)
    var num := GameUI.label(card, str(i + 1), Vector2(0, 18), Vector2(262, 150), 120, Color.WHITE, false, 10)
    num.add_theme_color_override("font_outline_color", col.lightened(0.25))
    num.add_theme_color_override("font_shadow_color", Color(col.r, col.g, col.b, 0.9))
    num.add_theme_constant_override("shadow_offset_y", 0)
    num.add_theme_constant_override("shadow_outline_size", 14)
    var nombre := Label.new()
    nombre.text = Global.nombre_de(i)
    nombre.position = Vector2(14, 178)
    nombre.size = Vector2(234, 52)
    nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    nombre.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    nombre.clip_text = true
    nombre.add_theme_font_size_override("font_size", 30)
    nombre.add_theme_color_override("font_color", Color.WHITE)
    var barra := StyleBoxFlat.new()
    barra.bg_color = Color(0.04, 0.05, 0.16, 0.92)
    barra.set_corner_radius_all(18)
    nombre.add_theme_stylebox_override("normal", barra)
    nombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(nombre)
    return card

func _estilo_tarjeta(card: Panel, i: int, resaltada: bool) -> void:
    # Cristal de color con borde neón; la elegida se ilumina en blanco y dorado.
    var col: Color = Global.color_de(i)
    var s := StyleBoxFlat.new()
    s.bg_color = Color(col.r * 0.55, col.g * 0.55, col.b * 0.55, 0.86)
    s.border_color = Color.WHITE if resaltada else col.lightened(0.3)
    s.set_border_width_all(9 if resaltada else 5)
    s.set_corner_radius_all(28)
    s.shadow_color = Color(1, 0.85, 0.3, 0.85) if resaltada else Color(col.r, col.g, col.b, 0.55)
    s.shadow_size = 26 if resaltada else 12
    card.add_theme_stylebox_override("panel", s)

func _girar() -> void:
    if spinning:
        return
    if Online.activo:
        _girar_host_online()
        return
    if club:
        _girar_club()
        return
    if Global.tiradas_usadas >= Global.LIMITE_GRATIS and not Global.premium:
        get_tree().change_scene_to_file("res://Paywall.tscn")
        return
    if Global.retos.is_empty():
        get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
        return
    var n: int = maxi(Global.n_jugadores(), 1)
    var ganador: int = randi_range(0, n - 1)
    Global.tiradas_usadas += 1
    Global.guardar_datos()
    _actualizar_gratis()
    await _animar(ganador, randi_range(6, 8), randf_range(-0.35, 0.35))
    if not is_inside_tree():
        return
    await _contar_giro()
    if not is_inside_tree():
        return
    _mostrar_seleccion()

# Anima la ruleta hasta que la porción "ganador" (posición en la ruleta) quede bajo la flecha (arriba).
func _animar(ganador: int, vueltas: int, jit: float) -> void:
    spinning = true
    for k in cards.keys():
        _estilo_tarjeta(cards[k] as Panel, int(k), false)
    var pid: int = ganador
    if ganador >= 0 and ganador < wheel.ids.size():
        pid = wheel.ids[ganador]
    Global.current_player = pid
    var n: int = maxi(wheel.count, 1)
    var paso: float = TAU / float(n)
    var objetivo: float = fposmod(-(float(ganador) + 0.5) * paso + jit * paso, TAU)
    var actual: float = wheel.rotation
    var destino: float = actual + fposmod(objetivo - fposmod(actual, TAU), TAU) + TAU * float(vueltas)
    _paso_tick = paso
    _seg_ultimo = int(floor(actual / paso))
    Audio.play("whoosh")
    # Gira rápido y va frenando poco a poco: el último tramo es muy lento para dar suspenso
    var tw := create_tween()
    tw.tween_property(wheel, "rotation", destino, 8.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
    await tw.finished
    if not is_inside_tree():
        return
    spinning = false
    Audio.play("win")
    var sel: Panel = cards.get(pid) as Panel
    if sel != null:
        _estilo_tarjeta(sel, pid, true)
    if not club:
        # La voz dice quién fue elegido (se puede silenciar con el botón 🔊)
        Voz.decir(I18n.t("voice_turn_fmt") % Global.nombre_de(pid))

func _mostrar_seleccion() -> void:
    _cerrar_modal()
    var i: int = Global.current_player
    var p := GameUI.modal(self, Vector2(720, 780))
    _modal = p
    var av := GameUI.circle(p, Vector2(360, 190), 110, Global.color_de(i), Color("#f6c343"), 10)
    GameUI.label(av, str(i + 1), Vector2.ZERO, av.size, 120, Color.WHITE, false, 8)
    GameUI.label(p, Global.nombre_de(i), Vector2(30, 330), Vector2(660, 110), 62, GameUI.DARK_TEXT)
    if Online.activo and Online.mi_indice() != i:
        GameUI.label(p, I18n.t("on_picking"), Vector2(50, 470), Vector2(620, 160), 36, Color("#3c3a55"), true)
        return
    GameUI.label(p, I18n.t("selected_msg"), Vector2(50, 450), Vector2(620, 110), 32, Color("#3c3a55"), true)
    GameUI.pill(p, I18n.t("go_challenges"), Vector2(130, 590), Vector2(460, 120), "green", _ir_cartas, 46)

func _cerrar_modal() -> void:
    if _modal != null and is_instance_valid(_modal) and _modal.get_parent() != null:
        GameUI.close_modal(_modal)
    _modal = null

# ---------- Club Privado: la ruleta elimina hasta que queda un ganador ----------
# Cada 5 giros sale el mensajito de donación; el juego sigue cuando el jugador lo cierra ("Seguir Jugando").
func _contar_giro() -> void:
    Global.giros_sesion += 1
    if Global.giros_sesion % 5 == 0 and not Global.premium:
        var p := Donacion.anuncio(self, "res://Ruleta.tscn", 1)
        await p.tree_exited

func _girar_club() -> void:
    if vivos.size() <= 1:
        return
    var idx: int = randi_range(0, vivos.size() - 1)
    var eliminado: int = vivos[idx]
    spin_btn.disabled = true
    await _animar(idx, randi_range(6, 8), randf_range(-0.35, 0.35))
    if not is_inside_tree():
        return
    Voz.decir(I18n.t("club_elim_fmt") % Global.nombre_de(eliminado))
    _marcar_eliminado(eliminado)
    vivos.erase(eliminado)
    Global.club_vivos = vivos
    _actualizar_gratis()
    await _contar_giro()
    if not is_inside_tree():
        return
    await get_tree().create_timer(1.8).timeout
    if not is_inside_tree():
        return
    if vivos.size() == 1:
        Global.current_player = vivos[0]
        _mostrar_ganador_club()
        return
    wheel.set_ids(vivos)
    spin_btn.disabled = false

func _marcar_eliminado(i: int) -> void:
    var c: Panel = cards.get(i) as Panel
    if c == null:
        return
    c.modulate = Color(1, 1, 1, 0.35)
    var x := GameUI.label(c, "✖", Vector2(0, 0), c.custom_minimum_size, 140, Color("#ff4a4a"), false, 10)
    x.modulate = Color(1, 1, 1, 1)

func _mostrar_ganador_club() -> void:
    _cerrar_modal()
    var i: int = Global.current_player
    Audio.play("win")
    Voz.decir(I18n.t("club_winner_fmt") % Global.nombre_de(i))
    var p := GameUI.neon_modal(self, Vector2(880, 820))
    _modal = p
    GameUI.label(p, "🏆", Vector2(0, 50), Vector2(880, 160), 120)
    var t := GameUI.label(p, I18n.t("club_winner"), Vector2(40, 215), Vector2(800, 90), 58, Color("#ffd870"), false, 8)
    t.add_theme_color_override("font_outline_color", Color("#7a3d00"))
    GameUI.label(p, Global.nombre_de(i), Vector2(40, 320), Vector2(800, 120), 80, Global.color_de(i).lightened(0.25), false, 8)
    GameUI.glossy(p, I18n.t("club_to_cards"), Vector2(90, 500), Vector2(700, 125), Color("#3fd35a"), Color.WHITE, _ir_cartas, 42)
    GameUI.glossy(p, I18n.t("exit"), Vector2(250, 660), Vector2(380, 95), Color("#ffc933"), GameUI.DARK_TEXT, _salir, 40)

# ---------- Modo en línea ----------
func _girar_host_online() -> void:
    if not Online.soy_host:
        return
    var d: Dictionary = Online.girar()
    if d.is_empty():
        return
    _ronda_vista = int(d["id"])
    _cerrar_modal()
    await _animar(int(d["ganador"]), int(d["vueltas"]), float(d["jit"]))
    if not is_inside_tree():
        return
    _mostrar_seleccion()

func _on_sala() -> void:
    Global.retos.clear()
    for t in Online.pool():
        Global.retos.append(t)
    _actualizar_gratis()
    var r: Dictionary = Online.ronda()
    var id: int = int(r.get("id", 0))
    if id <= _ronda_vista or spinning:
        return
    _ronda_vista = id
    match str(r.get("fase", "")):
        "giro":
            _cerrar_modal()
            await _animar(int(r.get("ganador", 0)), int(r.get("vueltas", 4)), float(r.get("jit", 0.0)))
            if not is_inside_tree():
                return
            _mostrar_seleccion()
        "reto":
            _mostrar_reto_online(str(r.get("reto", "")), int(r.get("ganador", 0)))
        "espera":
            _cerrar_modal()
        "fin":
            _mostrar_fin()

func _mostrar_reto_online(texto: String, ganador: int) -> void:
    _cerrar_modal()
    var p := GameUI.modal(self, Vector2(820, 760), Color("#fbf8ff"))
    _modal = p
    GameUI.label(p, I18n.t("on_challenge_fmt") % Global.nombre_de(ganador), Vector2(40, 40), Vector2(740, 80), 38, Color("#6a3ad8"))
    GameUI.label(p, texto, Vector2(50, 140), Vector2(720, 400), 50, GameUI.DARK_TEXT, true)
    Audio.play("win")
    Voz.decir(I18n.t("your_challenge") + " " + texto)
    if Online.soy_host:
        GameUI.pill(p, I18n.t("continue"), Vector2(190, 600), Vector2(440, 105), "green", _cerrar_modal, 40)

func _mostrar_fin() -> void:
    _cerrar_modal()
    var p := GameUI.modal(self, Vector2(780, 520), Color("#fbf8ff"))
    _modal = p
    GameUI.label(p, "🎉", Vector2(0, 30), Vector2(780, 140), 100)
    GameUI.label(p, I18n.t("on_end_title"), Vector2(40, 190), Vector2(700, 140), 50, GameUI.DARK_TEXT, true)
    GameUI.pill(p, I18n.t("on_ok"), Vector2(190, 370), Vector2(400, 110), "green", _fin_salir, 40)

func _fin_salir() -> void:
    Online.salir()
    get_tree().change_scene_to_file("res://MenuPrincipal.tscn")

func _on_sala_cerrada() -> void:
    _cerrar_modal()
    var p := GameUI.modal(self, Vector2(780, 460), Color("#fbf8ff"))
    _modal = p
    GameUI.label(p, I18n.t("on_closed"), Vector2(40, 90), Vector2(700, 160), 44, GameUI.DARK_TEXT, true)
    GameUI.pill(p, I18n.t("on_ok"), Vector2(190, 300), Vector2(400, 110), "green", _fin_salir, 40)

func _ir_cartas() -> void:
    get_tree().change_scene_to_file("res://SeleccionCarta.tscn")

func _reiniciar() -> void:
    if spinning:
        return
    var p := GameUI.modal(self, Vector2(780, 560), Color("#fbf8ff"))
    GameUI.label(p, "🔄", Vector2(0, 30), Vector2(780, 130), 90)
    GameUI.label(p, I18n.t("restart_title"), Vector2(40, 170), Vector2(700, 80), 46, GameUI.DARK_TEXT, true)
    GameUI.label(p, I18n.t("restart_msg"), Vector2(60, 260), Vector2(660, 120), 30, Color("#3c3a55"), true)
    GameUI.pill(p, I18n.t("restart_yes"), Vector2(60, 410), Vector2(310, 110), "red", _confirmar_reinicio, 36)
    GameUI.pill(p, I18n.t("cancel"), Vector2(410, 410), Vector2(310, 110), "yellow", GameUI.close_modal.bind(p), 36)

func _confirmar_reinicio() -> void:
    if club:
        # En el Club Privado "Reiniciar" vuelve a la sala para cambiar jugadores o retos
        get_tree().change_scene_to_file("res://ClubPrivado.tscn")
        return
    # Borra los desafíos (hay que registrarlos de nuevo). Se conservan participantes y tiradas usadas.
    Global.retos.clear()
    Global.completados.clear()
    Global.current_player = -1
    Global.current_card = -1
    Global.guardar_datos()
    get_tree().change_scene_to_file("res://RetosAnonimos.tscn")

func _plan() -> void:
    if spinning:
        return
    get_tree().change_scene_to_file("res://Paywall.tscn")

func _salir() -> void:
    if spinning:
        return
    Voz.parar()
    Global.salir_club()
    if Online.activo:
        Online.salir()
    get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
