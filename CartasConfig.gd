class_name CartasConfig
extends RefCounted
# Textos de las cartas del CLUB DE RECOMPENSAS. Cambia aquí lo que dice cada carta.
# Salen 5 cartas de PREMIOS (una por cada entrada, en orden aleatorio) y 3 cartas VACÍAS.

const TITULO := "CLUB DE RECOMPENSAS"
const TEXTO_DORSO := "HF"                  # lo que se ve en el reverso de cada carta
const TEXTO_RASPA := "✋ RASPA AQUÍ"

const PREMIOS := [
    {"emoji": "🎁", "titulo": "RECOMPENSA", "detalle": ""},
    {"emoji": "🎁", "titulo": "RECOMPENSA", "detalle": ""},
    {"emoji": "🎁", "titulo": "RECOMPENSA", "detalle": ""},
    {"emoji": "🎁", "titulo": "RECOMPENSA", "detalle": ""},
    {"emoji": "🎁", "titulo": "RECOMPENSA", "detalle": ""},
]
const VACIA := {"emoji": "❌", "titulo": "VACÍA", "detalle": ""}
