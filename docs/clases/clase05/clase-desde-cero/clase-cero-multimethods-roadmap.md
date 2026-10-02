# Clase desde cero — Multimethods — Roadmap

**Unidad:** clase05 (Ruby, ejercicio integrador de metaprogramación)
**Tipo de material:** clase desde cero, 7 módulos
**Qué es esto:** el índice de la clase. Dice qué necesitás tener a mano, en qué orden leer, qué parte del enunciado resuelve cada módulo, qué dolores se siembran en un módulo y se curan en otro, y cómo leer los bloques.

---

## Antes de empezar: tené el enunciado a mano

Esta clase **consiste en resolver un enunciado**: el ejercicio "Metaprogramación MultiMethods", un trabajo práctico de años anteriores que la cátedra usa como práctica integradora. No hay tema nuevo; hay que bajar a código todo lo visto hasta la clase04, guiados por ese enunciado.

Por eso necesitás tenerlo **impreso o abierto al lado**, en el archivo `fuente-ejercicio-multimethods.md` (si lo perdiste, en el repo de la cátedra figura como el ejercicio de multimethods, 5 páginas). Cada módulo cita el pedazo del enunciado que resuelve, te ubica en qué parte estás, y lo desarma. El material se lee **con el enunciado en la mano**, no en lugar del enunciado.

## Qué vas a poder hacer al terminar

Vas a haber escrito, entendido y ejecutado un framework de menos de 100 líneas que le agrega **multimétodos** a Ruby: métodos que eligen qué implementación ejecutar mirando el tipo de **cada argumento**, en tiempo de ejecución. Al final sabés:

- leer el enunciado completo sin trabarte en ninguna palabra;
- qué es un multimétodo y por qué no es lo mismo que la sobrecarga;
- cómo se guarda en una clase información que se va a usar mucho después;
- cómo se define un método cuyo nombre recién se conoce al ejecutar;
- cómo se ejecuta un bloque en el contexto de otro objeto;
- cómo se localiza el impacto de un requerimiento nuevo sobre código propio.

Las últimas tres son las habilidades que se evalúan en el individual.

## Qué parte del enunciado resuelve cada módulo

| Módulo | Parte del enunciado | Qué cubre | Densidad |
|---|---|---|---|
| M1 · El problema | Introducción | Panorama; qué le falta a Ruby; la introducción del enunciado frase por frase, con cada término definido donde aparece; los dos momentos | 🟡 |
| M2 · PartialBlock | Parte 1, *Partial Blocks* | Un bloque que sabe para qué argumentos vale: `matches?` y `call`, construidos paso a paso | 🔴 |
| M3 · partial_def | Parte 2, *Multi Methods*, primera mitad | Abrir `Module`, guardar las definiciones en cada clase, crear el método con `define_method`, elegir en ejecución | 🔴 |
| M4 · Contexto | Parte 2, el párrafo de `self` | Hacer que `self` dentro del bloque sea el receptor: `instance_exec` | 🔴 |
| M5 · El resto de la parte 2 | Parte 2, lo que falta | Distancia (la definición más específica), `multimethods` / `multimethod`, `respond_to?` con firma, pisar una firma repetida | 🔴 |
| M6 · Duck typing | Parte 3, *Nuevo requerimiento* | Un tipo puede ser una lista de mensajes; el cambio es local | 🔴 |
| M7 · La otra forma: method_missing | (no está en el enunciado) | La misma idea con `method_missing`; qué gana, qué pierde, cuándo sí hace falta. Se puede saltear. | 🟡 |

**Densidad:** 🔴 central y evaluable · 🟡 secundario · 🟢 mencionado al pasar. La marca aparece también sección por sección dentro de cada módulo.

**Orden:** sigue al enunciado, y adentro de cada parte sigue las dependencias. M3 usa `PartialBlock` (M2). M4 corrige un problema que M3 deja abierto. M5 completa la parte 2 sobre el código cerrado en M4. M6 modifica un solo método. M7 se entiende solo después de tener la forma buena.

## Hilos que se siembran y se cierran

| Hilo | Se siembra en | Se cierra en |
|---|---|---|
| H1 · `def` pisa `def`: dos cuerpos con el mismo nombre no conviven | M1 | M3 (el método se crea una sola vez con cuerpo genérico; las implementaciones viven aparte) |
| H2 · El `if` con chequeo de tipos anda, pero cada caso nuevo obliga a reabrir el método | M1 | M3 (cada `partial_def` agrega un caso sin tocar los anteriores) |
| H3 · Un diccionario que parece guardar y no guarda nada | M3 | M3, misma sección (la forma correcta de `Hash.new` con bloque) |
| H4 · El método anda para la clase que lo definió y explota para una subclase | M3 | M3, sección de herencia (capturar la lista en la clausura) |
| H5 · El bloque se ejecuta, pero `self` adentro no es el receptor | M3 (se muestra el síntoma) | M4 (`instance_exec`) |
| H6 · Se ejecuta el primer bloque que matchea, aunque haya uno más específico | M3 | M5 (distancia) |
| H7 · `respond_to?` sabe que el multimétodo existe, pero nada de firmas | M3 | M5 |

## Leyenda de bloques

| Bloque | Qué es |
|---|---|
| 📄 **El enunciado dice** | Recuadro con la frase o el fragmento **textual** del enunciado, con su ubicación exacta (parte y tema). Abajo, "en criollo": qué pide, y en qué método o línea va a terminar. Se cita solo lo que vale la pena reconocer después; lo que está confuso se señala y se reemplaza por la explicación. |
| `> Regla` | Recuadro al inicio de cada sección. Una a tres líneas, en afirmativo. Es el enunciado de la regla; el porqué viene después del caso. |
| Código comentado | Cada línea relevante lleva qué hace y por qué. La salida real va como comentario `# => …`, verificada por ejecución. `# también: …` al lado de una línea muestra otra forma de escribir lo mismo. |
| Código en construcción | El mismo método mostrado en pedazos: primero incompleto, con lo que devuelve así y por qué, después completo. Las piezas armadas van al final del módulo. |
| Tabla *escribís / Ruby entiende / sale* | Cuando algo admite varias formas, las muestra todas sobre el mismo caso, incluidas las que fallan y su error exacto. |
| 🛠️ **Lo que te va a marcar el editor** | Una línea por cada aviso, sugerencia o atajo de RubyMine que aparece con ese código, donde aparece por primera vez. |
| 🕳️ **Madriguera** | Algo que existe, se nombra en una a tres líneas, y no forma parte del camino. Se saltea sin culpa. |
| 🎯 **Para el parcial, si te preguntan** | Respuesta en formato examen: la primera oración ya responde, con la terminología de la materia. |
| ⚠️ **Trampa** | Un error que le pasa a cualquiera escribiendo este código, con la forma correcta al lado. |
| **Checkpoint** | Preguntas sin respuesta al final de cada módulo. Las respuestas van al complemento, después de que las contestes. |

**Términos:** cada palabra técnica se define **una sola vez, la primera vez que aparece**, en negrita y en una línea, dentro del flujo. No hay glosario aparte: el material se lee en orden, y la primera vez que te cruzás con la palabra ahí está su definición.

## Cómo usarlo

1. Enunciado a mano. Un módulo por sesión. Leé el código comentado completo; está escrito para entenderse sin ejecutarlo, y para reconocerlo después cuando lo escribas o lo veas escrito de otra forma.
2. Cuando termines el módulo, contestá el checkpoint por escrito antes de seguir. Las dudas van al chat.
3. Recién con las dudas cerradas se pasa al siguiente módulo.
4. Al terminar M6 tenés el archivo `multimethods.rb` completo con sus tests. Ahí sí conviene ejecutarlo y romperlo a propósito. M7 es opcional.

## Sintaxis de Ruby que aparece por primera vez en esta unidad

Cada una se presenta en el paso del módulo donde se usa, primero en su forma normal, con la alternativa en una línea al lado.

| Construcción | Módulo |
|---|---|
| `return` y el valor de retorno implícito de un método | M2 |
| `*args` (argumentos variables) y el desarmado de pares en bloques | M2 |
| `zip`, `all?` | M2 |
| `&block` como parámetro de un método, `arity` | M2 |
| `raise` en sus dos formas | M2 |
| `find` | M3 |
| `Hash.new` con bloque, `\|\|=` | M3 |
| `select`, `min_by`, `sum` con bloque, `each_with_index`, `reject!` | M5 |
| `<=` entre clases, `alias_method`, `fetch` con bloque y con valor por defecto | M5 |
| `? :` (ternario), `method_defined?` | M6 |

---

**FIN DEL ROADMAP**
