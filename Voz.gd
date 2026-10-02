extends Node
# Autoload: Voz. Lee en voz alta el participante elegido y el desafío (texto a voz del sistema).
# Uso: Voz.decir("texto") | Voz.parar() | Voz.alternar()  (el botón 🔊/🔇 llama a alternar)

func decir(texto: String) -> void:
    if not Global.voz:
        return
    var limpio: String = limpiar(texto)
    if limpio == "":
        return
    var idioma: String = "es" if Global.idioma == "es" else "en"
    var voces: PackedStringArray = DisplayServer.tts_get_voices_for_language(idioma)
    if voces.is_empty():
        return
    DisplayServer.tts_stop()
    DisplayServer.tts_speak(limpio, voces[0], 100, 1.0, 1.0, 0, true)

func parar() -> void:
    DisplayServer.tts_stop()

func alternar() -> void:
    Global.voz = not Global.voz
    Global.guardar_datos()
    if not Global.voz:
        DisplayServer.tts_stop()

# Quita emojis y símbolos para que la voz no los intente leer.
func limpiar(t: String) -> String:
    var s: String = ""
    for i in range(t.length()):
        var c: int = t.unicode_at(i)
        if c < 0x2000 or (c >= 0x2010 and c <= 0x2027):
            s += t[i]
    return s.strip_edges()
