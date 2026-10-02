class_name BancoDesafios
extends RefCounted
# Desafíos de ejemplo para grupos que no tienen ideas. Se eligen al azar, sin repetir los ya registrados.

const CANTIDAD := 20

static func aleatorios(n: int, excluir: Array[String]) -> Array[String]:
    var pool: Array[String] = _en() if Global.idioma == "en" else _es()
    var candidatos: Array[String] = []
    for d in pool:
        if not excluir.has(d):
            candidatos.append(d)
    candidatos.shuffle()
    var salida: Array[String] = []
    for i in range(mini(n, candidatos.size())):
        salida.append(candidatos[i])
    return salida

static func _es() -> Array[String]:
    var a: Array[String] = [
        "Baila 30 segundos sin parar con la música que quieras.",
        "Imita a un animal hasta que el grupo adivine cuál es.",
        "Canta el coro de tu canción favorita.",
        "Haz 10 sentadillas contando en voz alta.",
        "Cuenta un chiste; si nadie se ríe, cuenta otro.",
        "Di un trabalenguas tres veces seguidas sin equivocarte.",
        "Habla con acento costeño durante 1 minuto.",
        "Imita a un participante y que los demás adivinen quién es.",
        "Baila una champeta durante 30 segundos.",
        "Quédate como estatua 30 segundos mientras el grupo intenta hacerte reír.",
        "Di el abecedario al revés.",
        "Cuenta hasta 20 en inglés sin equivocarte.",
        "Hazle una declaración de amor dramática a un objeto de la habitación.",
        "Camina como modelo de pasarela de un lado al otro del lugar.",
        "Cuenta una anécdota graciosa de tu vida.",
        "Haz 10 saltos de tijera.",
        "Habla 1 minuto sin decir 'sí' ni 'no' mientras el grupo te hace preguntas.",
        "Inventa un jingle publicitario para el objeto que elija el grupo.",
        "Imita a tu personaje favorito de una película o serie.",
        "Mira a los ojos a otro participante 20 segundos sin reír.",
        "Baila como un robot durante 20 segundos.",
        "Di tres cosas buenas de cada participante.",
        "Baila un vallenato con una pareja imaginaria.",
        "Da un discurso de 30 segundos sobre por qué eres el mejor jugador.",
        "Dibuja una palabra en el aire y que los demás la adivinen.",
        "Imita el sonido de tres instrumentos musicales.",
        "Narra como locutor de fútbol lo que hace otro participante durante 30 segundos.",
        "Haz una pose de portada de revista y mantenla 15 segundos.",
        "Cuenta tu mejor recuerdo de la infancia.",
        "Haz reír a otro participante en menos de 30 segundos.",
        "Nombra 10 países en 15 segundos.",
        "Baila reguetón sin usar los brazos.",
        "Aguanta una plancha abdominal durante 20 segundos.",
        "Imita a un bebé llorando y luego riendo.",
        "Di una frase completa con voz muy aguda, como una ardilla.",
        "Dile un piropo original a cada participante.",
        "Cuenta una historia de una sola frase empezando con la letra que elija el grupo.",
        "Camina 10 pasos con un objeto en la cabeza sin que se caiga.",
        "Actúa una escena de telenovela dramática durante 30 segundos.",
        "Nombra 8 frutas en 10 segundos.",
        "Haz tu mejor imitación de un cantante famoso.",
        "Cuenta hacia atrás desde 30 de tres en tres.",
        "Haz mímica de una película y que adivinen el título.",
        "Saluda de una forma creativa a cada participante.",
        "Baila salsa 30 segundos con el compañero que elijas.",
        "Habla con la boca casi cerrada 30 segundos y que el grupo te entienda.",
        "Haz 5 flexiones de brazos (pueden ser de rodillas).",
        "Cuenta un chiste malo con la cara más seria posible.",
        "Grita el nombre de una ciudad como si fuera un gol.",
        "Elige a un participante y hazle un cumplido sincero en voz alta."
    ]
    return a

static func _en() -> Array[String]:
    var a: Array[String] = [
        "Dance for 30 seconds non-stop to any music you like.",
        "Imitate an animal until the group guesses which one it is.",
        "Sing the chorus of your favorite song.",
        "Do 10 squats while counting out loud.",
        "Tell a joke; if nobody laughs, tell another one.",
        "Say a tongue twister three times in a row without a mistake.",
        "Speak in a funny accent for 1 minute.",
        "Imitate a participant and let the others guess who it is.",
        "Dance champeta for 30 seconds.",
        "Freeze like a statue for 30 seconds while the group tries to make you laugh.",
        "Say the alphabet backwards.",
        "Count to 20 in Spanish without a mistake.",
        "Make a dramatic declaration of love to an object in the room.",
        "Walk like a runway model from one side of the room to the other.",
        "Tell a funny story from your life.",
        "Do 10 jumping jacks.",
        "Talk for 1 minute without saying 'yes' or 'no' while the group asks you questions.",
        "Invent a commercial jingle for an object chosen by the group.",
        "Imitate your favorite movie or series character.",
        "Stare into another participant's eyes for 20 seconds without laughing.",
        "Dance like a robot for 20 seconds.",
        "Say three nice things about each participant.",
        "Dance vallenato with an imaginary partner.",
        "Give a 30-second speech on why you are the best player.",
        "Draw a word in the air and let the others guess it.",
        "Imitate the sound of three musical instruments.",
        "Commentate like a soccer announcer on what another participant does for 30 seconds.",
        "Strike a magazine-cover pose and hold it for 15 seconds.",
        "Tell your best childhood memory.",
        "Make another participant laugh in under 30 seconds.",
        "Name 10 countries in 15 seconds.",
        "Dance reggaeton without using your arms.",
        "Hold a plank for 20 seconds.",
        "Imitate a baby crying and then laughing.",
        "Say a full sentence in a very high voice, like a squirrel.",
        "Give each participant an original compliment.",
        "Tell a one-sentence story starting with a letter chosen by the group.",
        "Walk 10 steps with an object on your head without dropping it.",
        "Act out a dramatic soap-opera scene for 30 seconds.",
        "Name 8 fruits in 10 seconds.",
        "Do your best impression of a famous singer.",
        "Count backwards from 30 by threes.",
        "Act out a movie and let the others guess the title.",
        "Greet each participant in a creative way.",
        "Dance salsa for 30 seconds with a partner of your choice.",
        "Talk with your mouth almost closed for 30 seconds and get the group to understand you.",
        "Do 5 push-ups (knees allowed).",
        "Tell a bad joke with the most serious face possible.",
        "Shout the name of a city as if it were a goal.",
        "Pick a participant and give them a sincere compliment out loud."
    ]
    return a
