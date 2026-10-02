CHMAGSECRET — GODOT 4
==========================
Proyecto Android vertical 1080x1920. Estilo visual neón espacial con marcos morados,
botones tipo píldora con franja tricolor y tarjetas doradas, todo dibujado por código
(sin texturas externas).

ESCENAS
-------
MenuPrincipal · NumJugadores (configuración de participantes) · RetosAnonimos (desafíos secretos)
RetosCompletados · Ruleta · SeleccionCarta (incluye la ventana con el desafío) · Paywall · Configuracion

ARCHIVOS CLAVE
--------------
UI.gd        Estilos reutilizables (GameUI.pill, frame, modal, bg...). Cambia colores aquí.
I18n.gd      Todos los textos en español e inglés. Se usa I18n.t("clave").
Global.gd    Datos de la partida, guardado en user://s.dat.
Wheel.gd     Ruleta dibujada con los colores de la bandera.
StarField.gd Fondo de estrellas.

PARA USAR TUS PROPIAS IMÁGENES
------------------------------
Copia los PNG al proyecto y reemplaza el fondo (GameUI.bg) por un TextureRect con tu imagen,
o la ruleta (Wheel.gd) por un TextureRect que rote.

PREMIUM
-------
La activación real debe venir del backend (ver BACKEND_SEGURIDAD.txt). Paywall.gd tiene el placeholder de Wompi.

NOVEDADES v30
-------------
Cartas / Ruleta / Desafíos secretos rediseñados con fondos propios (assets/bg_cartas.jpg, bg_ruleta.jpg, bg_desafios.jpg),
reverso de carta (assets/carta_reverso.png) y botones brillantes (GameUI.glossy). Puedes cambiar esas imágenes por las tuyas.
Voz.gd (autoload): lee en voz alta el participante elegido y el desafío. Botón 🔊/🔇 en ruleta y cartas (Global.voz se guarda).
ClubPrivado.tscn/.gd: sala VIP de 4 jugadores (assets/bg_club.jpg). Sus datos van aparte de la partida normal.
Ruleta del Club: cada giro elimina a un jugador hasta que queda uno; luego botón "Ir a selección de cartas".

NOVEDADES v32
-------------
Fuente global Carlito Bold (fonts/) y sombra suave en todas las letras (GameUI.label).
Desafíos secretos: título en una línea, texto de ayuda sobre panel oscuro.
Participantes: sin el marco morado grande. Ajustes: ya no tiene "Personalizar" (pasó al Club Privado).
Club Privado: todo en español, 2 a 8 jugadores (sin colores ni avatares), lista editable de retos (ClubRetos.tscn),
  personalización (Temas.tscn): jugadores, fondo, cartas y modo de carta (voltear / raspar). Fondo y cartas solo afectan al Club.
Ruleta: gira 8 s y frena poco a poco (Ruleta.gd, _animar).
Academia: áreas Física, Matemáticas, Inglés, Conocimiento de famosos y Zootecnia. 3 niveles por área (fácil, medio, difícil),
  20 preguntas por nivel en preguntas/<area>_<nivel>.json. 1 punto por pregunta; hay que acertar las 20.
  Puntos compartidos: con 20 se desbloquea otra área y la anterior se bloquea (Global.edu_*).

NOVEDADES v33
-------------
Academia: áreas activas = Agronomía, Zootecnia, Psicología, Biología, Mecánica de moto y Chivolo (preguntas del usuario, 60 por área).
Las demás áreas salen "En desarrollo". Borradores de Física, Matemáticas, Inglés y Famosos: preguntas/pendientes/.
Para activar un área: añadir su id a Global.EDU_ACTIVAS y poner sus 3 JSON en preguntas/.

NOVEDADES v34
-------------
Menú principal nuevo (MenuPrincipal.gd): fondo assets/menu_fondo.jpg con el logo abajo, título dorado y botones brillantes centrados.
Pantalla completa: project.godot usa aspect "expand" y Ajuste.gd (autoload) centra el contenido; GameUI.cubrir() hace que los fondos
llenen toda la pantalla sin deformarse.

NOVEDADES v35
-------------
Apariencia (Apariencia.tscn/.gd): el usuario elige el fondo (el original de cada pantalla + 6 fondos propios en fondos/tema_1..6.jpg)
y el color de los botones (original + 8 colores, GameUI.TEMA_BOTONES). Se abre desde Ajustes ("Fondo y botones") y desde Personalizar del Club.
Se aplica a TODAS las pantallas MENOS el menú principal (MenuPrincipal.gd se marca con set_meta("sin_tema") y usa GameUI.bg_fijo).
Se guarda en user://progreso.cfg, sección [tema] (Global.tema_fondo / Global.tema_boton). Logo (assets/logo_hardfmo.png, GameUI.logo()): solo en el menú principal; el fondo del menú (assets/menu_fondo.jpg) ya no lleva el logo dibujado.
Los botones rojos (cancelar, reiniciar) y los grises/oscuros no cambian de color. Para que un botón nunca cambie, pasa tematizar=false
en GameUI.pill(...) o GameUI.glossy(...).

Corrección v35b: las ventanas emergentes (GameUI.modal / neon_modal y Donacion.popup) salían desplazadas arriba-izquierda porque el fondo
oscuro tenía un desplazamiento de -700 y el panel iba dentro de él. Ahora el overlay usa GameUI.cubrir() y el panel se compensa.

NOVEDADES v36 (Academia)
------------------------
Áreas activas: Zootecnia (siempre empieza abierta), Agronomía, Psicología, Biología, Mecánica de moto, Chivolo, Matemáticas e Inglés
(las dos últimas con preguntas/matematicas_*.json e ingles_*.json; 20 preguntas por nivel). Física y Famosos siguen en preguntas/pendientes/.
Reglas: siempre hay UN área abierta; abrir otra cuesta 20 puntos y cierra la actual. Cada nivel superado por primera vez da 20 puntos.
El nivel fácil siempre está abierto; el medio y el difícil se abren con 20 puntos (en cualquier orden). Lo ya abierto en un área se conserva
si la vuelves a abrir. Todo en Global.gd (sección Academia; constantes EDU_COSTO, EDU_PUNTOS_NIVEL, EDU_INICIAL, EDU_ACTIVAS).
Migración: al actualizar, el área abierta pasa a Zootecnia una sola vez y el progreso anterior se conserva.

NOVEDADES v37 (Inglés: unir parejas)
------------------------------------
Los niveles de Inglés ya no son preguntas: son "unir parejas" (Unir.tscn / Unir.gd). 20 rondas por nivel; cada ronda tiene 4 palabras en inglés
a la izquierda y sus significados en español (mezclados) a la derecha. Se une tocando una y luego la otra, o arrastrando una línea, y se pulsa Aceptar.
Si hay uniones malas salen en rojo y la ronda no avanza hasta corregirlas. Al terminar las 20 rondas se supera el nivel (20 puntos la primera vez).
Datos: preguntas/ingles_facil_pares.json, ingles_medio_pares.json, ingles_dificil_pares.json -> [["Cat","Gato"], ...] (80 pares por nivel, sin repetir
ni en inglés ni en español). Las preguntas antiguas de Inglés quedaron en preguntas/pendientes/ingles_preguntas_*.json.
Para usar esta dinámica en otra área: añadir su id a Global.EDU_UNIR y crear sus 3 archivos *_pares.json.

NOVEDADES v44 (Academia, donación e icono)
------------------------------------------
Icono del APK: icon.png (logo HF dorado) + config/icon en project.godot. En Exportar > Android asigna assets/icon_192.png (principal) y
assets/icon_adaptive_fg.png / icon_adaptive_bg.png (adaptativo).
Academia: solo 5 áreas (Zootecnia, Mecánica de moto, Biología, Agronomía, Psicología). Chivolo se eliminó por completo.
Zootecnia empieza desbloqueada; las otras 4 salen con candado y "En Desarrollo" (Global.EDU_ACTIVAS = áreas con contenido; para activar una, añade su id ahí).
Cada área tiene 60 preguntas: dificultad fácil 20, media 20, difícil 20.
Desbloqueo de la siguiente área: al llegar a 30 preguntas respondidas en el área (20 fáciles + 10 medias) sale el popup "Área Desbloqueada".
  Se cuenta el mejor progreso de cada dificultad (Global.edu_respondidas / edu_registrar_progreso, constante EDU_PARA_DESBLOQUEAR).
Dificultades: la fácil siempre abierta; la media se abre al terminar la fácil; la difícil solo al terminar la media completa
  (si intenta entrar antes: "Completa el nivel medio para desbloquear"). Ya no se gastan puntos para abrir nada en la Academia.
Los nombres pasan a "Dificultad fácil / media / difícil". La pantalla de dificultades (EducativoNiveles.gd) tiene el estilo de la lista de niveles de
  referencia y su fondo cambia según el área (assets/<area>_fondo.jpg; Zootecnia = zoo_fondo.jpg; si no existe, fondo normal).
Textos nuevos: anuncio del menú principal (Donacion.anuncio, claves ann_*) y pantalla de donar (Paywall.gd, claves don_*), en español e inglés (I18n.gd).

NOVEDADES v45 (opiniones, pistas y Nivel 9)
-------------------------------------------
Opiniones: botón "✉️ Opiniones y sugerencias" en Configuración. Copia el correo y abre la app de correo con el asunto listo.
  El correo es Global.CORREO_OPINIONES (retosdiversionharfdmo@gmail.com); es distinto de Global.CORREO_SECRETO.
Pistas (cuestan Jugador.COSTO_PISTA = 3 gemas; Jugador.gastar_gemas(n) descuenta y devuelve false si no alcanzan):
  · Quiz de 4 opciones: quita 2 incorrectas al azar (quedan 1 correcta y 1 incorrecta, las otras 2 en gris y deshabilitadas). 1 pista por pregunta.
  · Crucigramas (el de palabra clave y el de Chibolo): revela 1 letra al azar, aún no descubierta, de la palabra seleccionada.
  · Sin gemas suficientes: "Te faltan gemas, necesitas 3. Tienes X" y no se descuenta nada.
Nivel 9 (CrucigramaChibolo.gd): en TODAS las áreas y dificultades el nivel 9 es el crucigrama 12x12 "Veredas de Chibolo".
  8 palabras que se cruzan (LAESPERANZA, ELPAVO, PUEBLONUEVO, LAESTRELLA, LACHINA, LAPOLA, ELPLAN, LADIVISA).
  Se toca una palabra (en un cruce, tocar otra vez cambia de palabra), se escribe con el teclado y, al completarla bien, se fija en verde
  y se tacha de la lista "PALABRAS A ENCONTRAR: n/8". Al encontrar las 8 se supera el nivel. Para cambiar el nivel: CrucigramaChibolo.NIVEL.

NOVEDADES v46 (donación y salvarse con gemas)
---------------------------------------------
Anuncio de donación del menú principal (Donacion.anuncio, variante 0): ahora incluye "¿Por qué una donación?" y "¿Para qué es?"
  (claves ann_why_t, ann_why, ann_for_t, ann_for en I18n.gd). El panel es más alto (1500) y los botones bajaron. Edita esos textos a tu gusto.
Errores en la Academia: ahora cuentan en TODOS los niveles (Global.EDU_NIVEL_RIESGO = 1). Con 2 errores:
  · si tiene una vida, la gasta y sigue en el mismo nivel (como antes);
  · si no tiene vidas, vuelve al nivel 1, pero sale una ventana: "Pagar 2 💎 y seguir" (Jugador.COSTO_SALVAR) o "Volver al nivel 1".
    Si paga, recupera su avance y repite el nivel con 0 errores (EduRun.guardar_salvavidas / restaurar_salvavidas).
    Si le faltan gemas: "Te faltan gemas, necesitas 2. Tienes X" y no se descuenta nada.
Gemas arriba: Quiz.gd (_cabecera, "💎 N" arriba al centro, se actualiza al gastar en pistas) y EducativoLista.gd (debajo de las vidas).

CORRECCIONES v47 (errores y avisos del depurador de Godot 4.7)
--------------------------------------------------------------
Error rojo: Global.edu_run ya no llama get_value(..., null) (Godot 4.7 lo marca como "sin valor por defecto"); ahora comprueba has_section_key.
Avisos amarillos: parámetro "wrap" renombrado a "envolver" (UI.label, UI.left_label, Donacion.texto); parámetro "texto" de Donacion.boton
  renombrado a "etiqueta"; variable local "tr" renombrada (PagoClub, PanelesJugador); divisiones enteras marcadas con @warning_ignore("integer_division").
