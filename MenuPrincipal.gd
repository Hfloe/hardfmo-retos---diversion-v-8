extends Control
# Menú principal: fondo negro y dorado (assets/menu_fondo.jpg con el logo abajo), título dorado y botones brillantes centrados.

const TILT := 0.0  # botones derechos (sin inclinación)
const FONDO := "res://assets/menu_fondo.jpg"

var audio_button: Button
var paneles: PanelesJugador

func _ready() -> void:
    set_meta("sin_tema", true)   # el menú principal no cambia con la personalización
    Global.salir_club()
    if Online.activo:
        Online.salir()
    if not Global.terminos_aceptados:
        get_tree().change_scene_to_file.call_deferred("res://Terminos.tscn")
        return
    GameUI.bg_fijo(self, FONDO)
    GameUI.logo(self, 540.0, 1590.0, 280.0)   # logo de HardFmo: solo aparece en el menú principal
    # Título dorado en 3D (dos líneas, centrado)
    var tit := GameUI.label3d(self, I18n.t("menu_title"), Vector2(0, 120), Vector2(1080, 360), 132, Color("#ffd84a"), Color("#b87010"), 10, Color("#6b3d00"))
    tit.autowrap_mode = TextServer.AUTOWRAP_OFF
    paneles = PanelesJugador.new()
    add_child(paneles)
    # Fila superior: Perfil · Estadísticas · Puntos
    _boton("👤  Perfil", Vector2(30, 28), Vector2(330, 100), Color("#2f8be6"), _ver_perfil, 32)
    _boton("📊  Estadísticas", Vector2(375, 28), Vector2(330, 100), Color("#ff8a1f"), _ver_estadisticas, 28)
    _boton("💎  Puntos", Vector2(720, 28), Vector2(330, 100), Color("#8a4de8"), _ver_puntos, 32)
    var listo: bool = Global.num_jugadores > 0 and Global.retos.size() >= 1
    if listo:
        _boton("🎮  " + I18n.t("start"), Vector2(172, 560), Vector2(736, 146), Color("#8cd62f"), _jugar, 52)
    else:
        GameUI.label(self, I18n.t("locked_hint"), Vector2(150, 468), Vector2(780, 76), 28, Color("#ffe9a3"), true, 6)
        var lock := _boton("🔒  " + I18n.t("locked"), Vector2(172, 560), Vector2(736, 146), Color("#7d7d92"), _jugar, 50)
        lock.disabled = true
    _boton("👥  " + I18n.t("players"), Vector2(172, 776), Vector2(736, 142), Color("#2f8be6"), _ir_participantes, 44)
    _boton("🎯  " + I18n.t("challenges"), Vector2(172, 990), Vector2(736, 142), Color("#ffab2e"), _ir_desafios, 52)
    if Online.DISPONIBLE:
        _boton("🌐  " + I18n.t("on_online_btn"), Vector2(172, 1206), Vector2(350, 120), Color("#2f8be6"), _ir_online, 40)
    else:
        _boton("🔒  " + I18n.t("on_online_btn"), Vector2(172, 1206), Vector2(350, 120), Color("#7d7d92"), _en_desarrollo, 40)
    _boton("🤍  " + I18n.t("donate"), Vector2(558, 1206), Vector2(350, 120), Color("#2fd6a0"), _ir_donar, 40)
    audio_button = _boton(_audio_text(), Vector2(172, 1400), Vector2(350, 112), Color("#ffab2e"), _toggle_audio, 36)
    _boton("⚙  " + I18n.t("settings"), Vector2(558, 1400), Vector2(350, 112), Color("#c46fe0"), _ir_ajustes, 34)
    if not Global.anuncio_inicio_visto:
        Global.anuncio_inicio_visto = true
        if not Global.premium:
            _anuncio_inicio()

func _anuncio_inicio() -> void:
    await get_tree().create_timer(0.7).timeout
    if is_inside_tree():
        Donacion.anuncio(self, "res://MenuPrincipal.tscn", 0)

func _boton(texto: String, pos: Vector2, sz: Vector2, color: Color, callback: Callable, font_size: int) -> Button:
    var b := GameUI.glossy(self, texto, pos, sz, color, Color.WHITE, callback, font_size, int(sz.y * 0.5))
    # sombra suave para que el texto blanco se lea bien sobre cualquier color
    b.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
    b.add_theme_constant_override("shadow_offset_x", 0)
    b.add_theme_constant_override("shadow_offset_y", 3)
    return b

func _audio_text() -> String:
    return ("🔊  " if Global.sonido else "🔇  ") + I18n.t("audio")

func _toggle_audio() -> void:
    Global.sonido = not Global.sonido
    Global.guardar_datos()
    Audio.actualizar_musica()
    audio_button.text = _audio_text()

func _ver_perfil() -> void:
    paneles.perfil()

func _ver_estadisticas() -> void:
    paneles.estadisticas()

func _ver_puntos() -> void:
    paneles.puntos()

func _jugar() -> void:
    get_tree().change_scene_to_file("res://Ruleta.tscn")

func _ir_participantes() -> void:
    get_tree().change_scene_to_file("res://NumJugadores.tscn")

func _ir_desafios() -> void:
    get_tree().change_scene_to_file("res://RetosAnonimos.tscn")

func _en_desarrollo() -> void:
    var p := GameUI.modal(self, Vector2(780, 560), Color("#fbf8ff"))
    GameUI.label(p, "🛠️", Vector2(0, 30), Vector2(780, 140), 100)
    GameUI.label(p, I18n.t("on_dev_title"), Vector2(40, 190), Vector2(700, 90), 52, GameUI.DARK_TEXT, true)
    GameUI.label(p, I18n.t("on_dev_msg"), Vector2(60, 290), Vector2(660, 120), 32, Color("#3c3a55"), true)
    GameUI.pill(p, I18n.t("on_ok"), Vector2(190, 430), Vector2(400, 110), "green", GameUI.close_modal.bind(p), 40)

func _ir_online() -> void:
    get_tree().change_scene_to_file("res://OnlineMenu.tscn")

func _ir_donar() -> void:
    get_tree().change_scene_to_file("res://Paywall.tscn")

func _ir_ajustes() -> void:
    get_tree().change_scene_to_file("res://Configuracion.tscn")

func _salir_app() -> void:
    get_tree().quit()
