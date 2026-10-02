extends Node
# Autoload: Audio. Efectos y música. Respeta Global.sonido.
# Uso: Audio.play("click") | Audio.play("win") | Audio.actualizar_musica()

const RUTA := "res://sonidos/%s.wav"
const VOL_MUSICA := -14.0
const VOL_EFECTOS := -4.0

var _streams: Dictionary = {}
var _musica: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    for n in ["click", "tick", "whoosh", "win", "chime", "carta", "error", "musica"]:
        var ruta: String = RUTA % n
        if ResourceLoader.exists(ruta):
            _streams[n] = load(ruta)
    for i in range(6):
        var p := AudioStreamPlayer.new()
        p.volume_db = VOL_EFECTOS
        add_child(p)
        _pool.append(p)
    _musica = AudioStreamPlayer.new()
    _musica.volume_db = VOL_MUSICA
    _musica.finished.connect(_reiniciar_musica)
    add_child(_musica)
    if _streams.has("musica"):
        _musica.stream = _streams["musica"]
    # Todos los botones que aparezcan en cualquier pantalla suenan al tocarlos.
    get_tree().node_added.connect(_nodo_nuevo)
    actualizar_musica()

func _nodo_nuevo(n: Node) -> void:
    if n is Button:
        var b: Button = n as Button
        b.pressed.connect(_sonar_boton.bind(b))

func _sonar_boton(b: Button) -> void:
    if b.disabled:
        return
    play("click")

func play(nombre: String, volumen_db: float = VOL_EFECTOS) -> void:
    if not Global.sonido or not _streams.has(nombre):
        return
    for p in _pool:
        if not p.playing:
            p.stream = _streams[nombre]
            p.volume_db = volumen_db
            p.play()
            return
    var p0: AudioStreamPlayer = _pool[0]
    p0.stream = _streams[nombre]
    p0.volume_db = volumen_db
    p0.play()

func actualizar_musica() -> void:
    if _musica == null or _musica.stream == null:
        return
    if Global.sonido:
        if not _musica.playing:
            _musica.play()
    else:
        _musica.stop()

func _reiniciar_musica() -> void:
    if Global.sonido:
        _musica.play()
