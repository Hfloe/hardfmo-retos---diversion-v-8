class_name CrucigramaChibolo
extends RefCounted
# Nivel 9 de cada dificultad de la Academia: crucigrama 12x12 "Veredas de Chibolo".
# Las 8 palabras se cruzan entre sí (10 cruces). Cada palabra: p = letras sin espacios (lo que se escribe),
# t = como se muestra en la lista, f/c = fila y columna donde empieza (0 a 11), v = true si va vertical.
# Para cambiar el nivel donde aparece, edita NIVEL.

const NIVEL := 9
const TAM := 12
const COLOCADAS := [
    {"p": "LAESPERANZA", "t": "LA ESPERANZA", "f": 8, "c": 1, "v": false},
    {"p": "ELPAVO", "t": "EL PAVO", "f": 6, "c": 5, "v": false},
    {"p": "PUEBLONUEVO", "t": "PUEBLO NUEVO", "f": 0, "c": 3, "v": true},
    {"p": "LAESTRELLA", "t": "LA ESTRELLA", "f": 1, "c": 1, "v": true},
    {"p": "LACHINA", "t": "LA CHINA", "f": 0, "c": 8, "v": true},
    {"p": "LAPOLA", "t": "LA POLA", "f": 10, "c": 0, "v": false},
    {"p": "ELPLAN", "t": "EL PLAN", "f": 6, "c": 5, "v": true},
    {"p": "LADIVISA", "t": "LA DIVISA", "f": 4, "c": 3, "v": false},
]
