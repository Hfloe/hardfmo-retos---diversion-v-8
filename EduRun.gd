class_name EduRun
extends RefCounted
# Carrera actual de una dificultad de la Academia (20 niveles).
# · Cada nivel tiene un formato al azar: quiz, vf (verdadero o falso), unir y cruci (crucigrama).
# · Las preguntas y palabras salen en orden aleatorio y NO se repiten: una vez usadas no vuelven.
#   Si el participante falla, ese contenido se manda al FINAL de la cola.
# · Cuenta los errores cometidos en cualquier nivel (2 errores = vuelve al nivel 1, salvo que tenga una vida o pague gemas).
# El estado vive en memoria (se rearma al volver al nivel 1 o al abrir la app de nuevo).
# Datos:
#   res://preguntas/<area>_<dificultad>.json   ->  [{"q": "...", "o": ["a","b","c","d"], "c": indice}, ...]
#   res://preguntas/<area>_palabras.json       ->  [{"p": "SUELO", "t": "Suelo", "d": "Capa donde crecen las plantas"}, ...]
#       p = palabra en MAYÚSCULAS sin tildes (para el crucigrama) · t = como se muestra · d = pista o definición corta

const NIVELES := ["facil", "medio", "dificil"]
const MIN_PALABRAS := 12      # con menos palabras no se usan unir ni crucigrama

static var _estado: Dictionary = {}

static func _clave(cat: String, idx: int) -> String:
    return "%s|%d" % [cat, idx]

static func _leer(ruta: String) -> Array:
    var vacio: Array = []
    if not FileAccess.file_exists(ruta):
        return vacio
    var f := FileAccess.open(ruta, FileAccess.READ)
    var datos: Variant = JSON.parse_string(f.get_as_text())
    if datos is Array:
        var lista: Array = datos
        return lista
    return vacio

static func estado(cat: String, idx: int) -> Dictionary:
    var k: String = _clave(cat, idx)
    if not _estado.has(k):
        _estado[k] = _nuevo(cat, idx)
    var e: Dictionary = _estado[k]
    return e

static func _nuevo(cat: String, idx: int) -> Dictionary:
    var preg: Array = _leer("res://preguntas/%s_%s.json" % [cat, NIVELES[clampi(idx, 0, 2)]])
    var pal: Array = _leer("res://preguntas/%s_palabras.json" % cat)
    var cola_p: Array = preg.duplicate(true)
    cola_p.shuffle()
    var cola_w: Array = pal.duplicate(true)
    cola_w.shuffle()
    return {
        "preg_pool": preg,
        "pal_pool": pal,
        "preg": cola_p,
        "pal": cola_w,
        "plan": _plan(pal.size() >= MIN_PALABRAS),
        "errores": 0,
    }

# Reparte los 20 niveles entre los formatos. El nivel 1 siempre es quiz (arranque suave) y no salen 3 iguales seguidos.
static func _plan(con_palabras: bool) -> Array:
    var base: Array = []
    if con_palabras:
        base = _rep("quiz", 11) + _rep("vf", 3) + _rep("unir", 3) + _rep("cruci", 3)
    else:
        base = _rep("quiz", 16) + _rep("vf", 4)
    for intento in range(80):
        base.shuffle()
        if base[0] == "quiz" and not _tres_seguidos(base):
            return base
    base.shuffle()
    return base

static func _rep(formato: String, n: int) -> Array:
    var r: Array = []
    for i in range(n):
        r.append(formato)
    return r

static func _tres_seguidos(lista: Array) -> bool:
    for i in range(2, lista.size()):
        if lista[i] == lista[i - 1] and lista[i] == lista[i - 2]:
            return true
    return false

# Formato del nivel (1 a 20): "quiz" · "vf" · "unir" · "cruci"
static func formato(cat: String, idx: int, nivel: int) -> String:
    if nivel == CrucigramaChibolo.NIVEL:
        return "chibolo"   # el nivel 9 siempre es el crucigrama de las veredas de Chibolo
    var plan: Array = estado(cat, idx)["plan"]
    return str(plan[clampi(nivel - 1, 0, plan.size() - 1)])

# Vuelve a empezar la carrera (nuevo orden al azar). Se usa al caer al nivel 1 o al terminar la dificultad.
static func reiniciar(cat: String, idx: int) -> void:
    _estado.erase(_clave(cat, idx))

# ---------- Salvarse pagando gemas ----------
# Al fallar 2 veces sin vidas se pierde el avance (vuelve al nivel 1), pero se guarda una copia por si el participante paga para salvarse.
static var _salvar: Dictionary = {}

static func guardar_salvavidas(cat: String, idx: int, run_previo: int) -> void:
    _salvar[_clave(cat, idx)] = {"estado": estado(cat, idx).duplicate(true), "run": run_previo}

static func hay_salvavidas(cat: String, idx: int) -> bool:
    return _salvar.has(_clave(cat, idx))

# Devuelve el nivel superado que tenía antes de fallar (o -1 si no hay copia) y deja la carrera como estaba, con 0 errores.
static func restaurar_salvavidas(cat: String, idx: int) -> int:
    var k: String = _clave(cat, idx)
    if not _salvar.has(k):
        return -1
    var datos: Dictionary = _salvar[k]
    var e: Dictionary = datos["estado"]
    e["errores"] = 0
    _estado[k] = e
    _salvar.erase(k)
    return int(datos["run"])

static func descartar_salvavidas(cat: String, idx: int) -> void:
    _salvar.erase(_clave(cat, idx))

# ---------- Errores (cuentan desde Global.EDU_NIVEL_RIESGO) ----------

static func errores(cat: String, idx: int) -> int:
    return int(estado(cat, idx)["errores"])

static func sumar_error(cat: String, idx: int) -> int:
    var e: Dictionary = estado(cat, idx)
    e["errores"] = int(e["errores"]) + 1
    return int(e["errores"])

static func limpiar_errores(cat: String, idx: int) -> void:
    var e: Dictionary = estado(cat, idx)
    e["errores"] = 0

# ---------- Preguntas (quiz y verdadero o falso) ----------

static func tomar_pregunta(cat: String, idx: int) -> Dictionary:
    var e: Dictionary = estado(cat, idx)
    var cola: Array = e["preg"]
    if cola.is_empty():
        # Se acabaron todas: solo entonces se vuelven a mezclar (las repetidas quedan para el final)
        var pool: Array = e["preg_pool"]
        cola.append_array(pool.duplicate(true))
        cola.shuffle()
    if cola.is_empty():
        var vacio: Dictionary = {}
        return vacio
    var q: Dictionary = cola.pop_front()
    return q

static func devolver_pregunta(cat: String, idx: int, q: Dictionary) -> void:
    var e: Dictionary = estado(cat, idx)
    var cola: Array = e["preg"]
    cola.push_back(q)

# ---------- Palabras (unir y crucigrama) ----------

static func _rellenar(e: Dictionary, minimo: int) -> void:
    var cola: Array = e["pal"]
    if cola.size() >= minimo:
        return
    var presentes: Dictionary = {}
    for w in cola:
        presentes[str(w["p"])] = true
    var extra: Array = []
    var pool: Array = e["pal_pool"]
    for w in pool:
        if not presentes.has(str(w["p"])):
            extra.append(w)
    extra.shuffle()
    cola.append_array(extra)

static func _quitar(cola: Array, p: String) -> void:
    for i in range(cola.size()):
        if str(cola[i]["p"]) == p:
            cola.remove_at(i)
            return

static func tomar_palabras(cat: String, idx: int, n: int) -> Array:
    var e: Dictionary = estado(cat, idx)
    _rellenar(e, n)
    var cola: Array = e["pal"]
    var salida: Array = []
    for i in range(n):
        if cola.is_empty():
            break
        salida.append(cola.pop_front())
    return salida

static func devolver_palabras(cat: String, idx: int, lista: Array) -> void:
    var e: Dictionary = estado(cat, idx)
    var cola: Array = e["pal"]
    for w in lista:
        _quitar(cola, str(w["p"]))   # por si ya estaba en la cola
        cola.push_back(w)

# Crucigrama de palabra clave: una palabra clave se lee en vertical y cada letra suya cruza una palabra horizontal.
# Devuelve {"clave", "clave_d", "filas": [{"p","t","d","col"}], "izq", "cols", "usadas": [...]}
# o {} si no hay palabras suficientes.
static func tomar_cruci(cat: String, idx: int) -> Dictionary:
    var e: Dictionary = estado(cat, idx)
    _rellenar(e, 8)
    var cola: Array = e["pal"]
    var r: Dictionary = armar_cruci(cola)
    if r.is_empty():
        # No se logró cruzar: cuatro palabras sueltas, sin palabra clave
        var sueltas: Array = tomar_palabras(cat, idx, 4)
        if sueltas.size() < 4:
            var vacio: Dictionary = {}
            return vacio
        var filas: Array = []
        var ancho: int = 1
        for w in sueltas:
            filas.append({"p": str(w["p"]), "t": str(w.get("t", w["p"])), "d": str(w["d"]), "col": 0})
            ancho = maxi(ancho, str(w["p"]).length())
        return {"clave": "", "clave_d": "", "filas": filas, "izq": 0, "cols": ancho, "usadas": sueltas}
    for w in r["usadas"]:
        _quitar(cola, str(w["p"]))
    return r

static func armar_cruci(cola: Array) -> Dictionary:
    for intento in range(60):
        var cand: Array = cola.duplicate()
        cand.shuffle()
        var clave: Dictionary = {}
        for w in cand:
            var n: int = str(w["p"]).length()
            if n >= 4 and n <= 5:
                clave = w
                break
        if clave.is_empty():
            break
        var k: String = str(clave["p"])
        var usadas: Array = [clave]
        var nombres: Array = [k]
        var filas: Array = []
        var bien: bool = true
        for i in range(k.length()):
            var letra: String = k.substr(i, 1)
            var elegido: Dictionary = {}
            for w in cand:
                var p: String = str(w["p"])
                if nombres.has(p):
                    continue
                if p.find(letra) >= 0:
                    elegido = w
                    break
            if elegido.is_empty():
                bien = false
                break
            var pe: String = str(elegido["p"])
            nombres.append(pe)
            usadas.append(elegido)
            filas.append({"p": pe, "t": str(elegido.get("t", pe)), "d": str(elegido["d"]), "col": pe.find(letra)})
        if not bien:
            continue
        var izq: int = 0
        var der: int = 0
        for f in filas:
            izq = maxi(izq, int(f["col"]))
            der = maxi(der, str(f["p"]).length() - int(f["col"]) - 1)
        return {
            "clave": k,
            "clave_d": str(clave["d"]),
            "filas": filas,
            "izq": izq,
            "cols": izq + 1 + der,
            "usadas": usadas,
        }
    var vacio2: Dictionary = {}
    return vacio2
