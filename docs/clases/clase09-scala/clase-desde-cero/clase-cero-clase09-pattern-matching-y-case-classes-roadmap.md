# Clase desde cero — Pattern matching, case classes y el híbrido objeto-funcional — Roadmap

**Unidad:** clase09 (TADP, 2C 2026) · **Lenguaje:** Scala 3.3.1 · **Tipo de material:** clase desde cero, 9 módulos + 1 de orientación
**Qué es esto:** el índice de la clase. Dice qué tener a mano, en qué orden leer y por qué, qué dolor se siembra en un módulo y se cura en otro, cómo leer cada bloque, qué queda afuera y de dónde salió cada parte.

---

## Antes de empezar: cuatro cosas a mano

1. **El código final de la unidad**, en `fuente-repo-clase09-pattern-matching-y-case-classes.md`. Es un proyecto Scala con **cuatro soluciones al mismo problema** (un simulador de microprocesador), cada una en su paquete: objetos sin Visitor, objetos con Visitor, pattern matching con el micro mutable, y pattern matching con el micro inmutable. Más el ejemplo de figuras y 54 tests. Todo el código del micro y de figuras sale de ahí; los ejemplos sueltos (tanques, `A`/`B`/`C`, `Tarea`, los de funcional) se pegan en un worksheet. El Módulo 0 lo recorre.
2. **El enunciado del simulador** (`fuente-enunciado-simulador-microprocesadores.md`; está resumido en el Módulo 1). Lo ideal es haberlo leído.
3. **La lectura previa de la unidad**, el patrón Visitor (`fuente-visitor-design-pattern.md`). M5 la retoma.
4. **Las dos unidades anteriores leídas** (`clase-cero-clase07-tipado-estatico` y `clase-cero-clase08-type-arguments-y-varianza`). Esta clase se para sobre ellas: `trait` como contrato, subtipado, `override`, cast, `List[A]`, parámetros de tipo. No se re-explican. También asume la primera mitad de la materia en Ruby (objetos, mensajes, `method_missing`) y lo que viste de Haskell en Paradigmas (pattern matching sobre listas, `foldl`, funciones como valores).

## De qué va esta clase

Hasta acá la materia estuvo adentro de objetos: en Ruby, estirándolos con mixins y metaprogramación; en Scala, poniéndoles tipos. Esta clase abre la parte objeto-funcional de la segunda mitad y pregunta otra cosa: **¿y si objetos no fuera siempre la mejor forma de pensar?**

El vehículo es un problema chico: un microprocesador con dos registros, una memoria y siete instrucciones, y tres cosas que se quieren hacer con un programa (ejecutarlo, imprimirlo, simplificarlo). Se resuelve cuatro veces. La primera, con objetos como los conocés. La segunda, con el patrón Visitor, que es lo que objetos propone cuando lo anterior se vuelve incómodo. Y ahí aparece la tesis de la clase: el Visitor es objetos **rindiéndose**: renuncia a sus tres ideas para conseguir, por el camino difícil, lo que funcional hace de forma natural. Las dos soluciones siguientes usan herramientas de funcional dentro de Scala (case classes, pattern matching, inmutabilidad, `foldLeft`), y con ellas aparece el criterio que esta mitad de la materia va a trabajar: **cuándo conviene cada cosa, y por qué.**

## Qué vas a poder hacer al terminar

- Explicar qué dan encapsulamiento, delegación y polimorfismo de subtipado, con el problema concreto que cada uno resuelve, y no con la frase hecha ("no accedas a los atributos").
- Decir en qué dirección crece fácil objetos (estructuras nuevas) y en cuál crece mal (operaciones nuevas), y mostrarlo con `A`, `B`, `C` y `m3`.
- Leer el patrón Visitor: su estructura, el doble despacho (*double dispatch*), para qué situación lo propone Gamma (el libro de patrones de diseño de 1994, *Design Patterns*) y qué renuncia implica.
- Nombrar las tres ideas de funcional (polimorfismo paramétrico, pureza, orden superior) y decir con cuál idea de objetos choca cada una.
- Escribir `case class`/`case object` y usar `match` con patrones de constante, constructor, tipo, `::`/`Nil`, `_` y guarda, sabiendo qué te regala la palabra `case`.
- Resolver las tres operaciones del micro con pattern matching, y comparar cada una con su versión Visitor.
- Hacer un micro inmutable con `case class`, validar sus invariantes en un solo lugar, y escribir `run` con `foldLeft` sin variable mutable.
- Ante un requerimiento nuevo del TP, decidir si va con polimorfismo o con pattern matching, y defenderlo con el criterio de la clase.

Lo que se evalúa en el individual es decidir **con qué herramienta** va un requerimiento nuevo y por qué (M7), y los porqués que sostienen esa decisión (M2, M3, M4, M5 y M8).

## Los módulos

Tres fases: **A** el problema y objetos (M0–M3) · **B** el triángulo rojo y la rendición (M4–M5) · **C** el híbrido (M6–M9). El Módulo 0 es orientación.

| Módulo | Archivo (`clase-cero-clase09-pattern-matching-y-case-classes-…`) | Densidad | Qué cierra |
|---|---|---|---|
| **0** El proyecto en el que trabajamos | `modulo0-el-proyecto.md` | 🟢 corto | Qué hay en el código de referencia, por qué son cuatro soluciones y cómo se reparten en paquetes, qué archivo usa cada módulo, cómo correr los tests, qué es un worksheet |
| **1** El problema: un micro y sus operaciones | `modulo1-el-problema.md` | 🟡 | El micro y las siete instrucciones; un programa es una lista de instrucciones y el `If` lleva otra adentro; el ejemplo paso a paso; las tres operaciones del enunciado; "¿y si mañana aparecen 500 operaciones más?" |
| **2** Objetos puros: encapsulamiento y delegación, revisados | `modulo2-encapsulamiento-y-delegacion.md` | 🔴 | Las dos reglas de objetos; por qué "no accedas a los atributos" no alcanza; acceso uniforme; la cadena `universidad.facultad.materia.curso.profesor`; encapsular es ceder control; siempre hay un responsable; la calculadora; los tanques y el doble despacho; God object y data object; delegar crea puntos de extensión; las invariantes que funcional no puede garantizar; la solución sin Visitor leída |
| **3** Polimorfismo y las dos direcciones de crecimiento | `modulo3-polimorfismo-y-crecimiento.md` | 🔴 | `Figura`, `Circulo`, `Rectangulo`; polimorfismo se diseña; `A`/`B` con `m1`/`m2` contra el `switch`; agregar `C` en cada lado; agregar `m3` en cada lado; por qué objetos se comió a estructurado; subtipado, ad-hoc, paramétrico |
| **4** El triángulo rojo | `modulo4-el-triangulo-rojo.md` | 🔴 | Por qué funcional vuelve ahora; polimorfismo paramétrico y pattern matching; pureza; orden superior como "la operación es un individuo"; el antagonismo vértice a vértice; pérdida de identidad; funcional no es tonto |
| **5** El Visitor, o cómo objetos se rinde | `modulo5-el-visitor.md` | 🔴 | Para qué situación lo propone Gamma; `accept`/`visit` y el doble despacho; el control del recorrido lo tiene la estructura; `RunVisitor` con su bandera, `PrintVisitor`, `SimplifyVisitor` con su pila; las cuatro citas y los tres vértices tachados; complejidad accidental |
| **6** El lenguaje: case classes y pattern matching | `modulo6-case-classes-y-pattern-matching.md` | 🟡 | `case object`, `case class` y lo que regalan; las instrucciones como datos; `match` como expresión; los seis tipos de patrón; sin *fallthrough* (sin caer al caso siguiente); el aviso por caso faltante |
| **7** Las tres operaciones con pattern matching | `modulo7-operaciones-con-pattern-matching.md` | 🔴 | `simplify` sobre la forma de la lista; `print` con `map`; `run` que controla el flujo; comparación lado a lado con el Visitor; **el criterio híbrido** |
| **8** Pureza en la práctica: el micro inmutable | `modulo8-el-micro-inmutable.md` | 🔴 | Consultas vs efectos; Scala tiene efecto, Haskell no; el argumento del debugging; `case class Micro` con `require`; `copy`; `run` con variable local y después con `foldLeft`; el swap sin temporal |
| **9** Un resultado en vez de una excepción (puente) | `modulo9-un-resultado-en-vez-de-excepcion.md` | 🟡 | El `throw` rompe la pureza; `Result` con tres formas; el `foldLeft` que deja de aplicar; la firma que cuenta lo que pasa; hacer vs responder; qué sigue la próxima clase |

**Densidad:** 🔴 pide una sesión con el código abierto; 🟡 se lee de corrido; 🟢 es operativo, se consulta. (Las mismas tres marcas, dentro de un módulo, significan importancia de la sección; ver la leyenda.)

## El orden, y por qué

```
 M0 Proyecto
  │
  ▼
 M1 El problema ──► M2 Encapsulamiento y delegación ──► M3 Polimorfismo y crecimiento
                                                         │
                                                         ▼
                                                        M4 El triángulo rojo
                                                         │
                                                         ▼
                                                        M5 El Visitor (la rendición)
                                                         │
                                                         ▼
                                                        M6 Case classes y pattern matching
                                                         │
                                                         ▼
                                                        M7 Las operaciones con pattern matching
                                                         │
                                                         ▼
                                                        M8 El micro inmutable
                                                         │
                                                         ▼
                                                        M9 Un resultado en vez de una excepción
```

El orden es por dependencias, y difiere del de la clase real en dos lugares. **El problema va primero** (M1), para que cada idea de los módulos 2 a 5 se vea sobre código que ya conocés. **El triángulo rojo va antes del Visitor** (M4 antes de M5): la lectura del Visitor como "funcional disfrazado" necesita saber qué es funcional.

- **M1 → M2:** las tres ideas de objetos se revisan sobre la primera solución del micro, la que tiene las operaciones adentro de las instrucciones.
- **M2 → M3:** delegar bien es lo que crea los puntos de extensión que el polimorfismo necesita; el `switch` de M3 es el mismo problema que los tanques de M2.
- **M3 → M4:** M3 termina con una dirección en la que objetos crece mal. M4 muestra la tecnología que crece bien en esa dirección, y por qué eso le cuesta todo lo demás.
- **M4 → M5:** el Visitor se entiende recién cuando se puede decir "esto es el triángulo rojo hecho con las piezas del azul".
- **M5 → M6:** el Visitor deja el dolor de dónde está cada cosa. M6 trae la herramienta; es el único módulo de sintaxis pura.
- **M6 → M7:** las tres operaciones se reescriben con esa herramienta y se comparan con el Visitor, caso por caso.
- **M7 → M8:** `run` sigue causando efecto sobre el micro. M8 saca el efecto.
- **M8 → M9:** sacar el efecto no alcanza para ser puro: queda el `throw`. M9 lo convierte en un valor, y deja el resto para la clase que viene.

## Hilos que se siembran y se cierran

| Hilo | Se siembra | Se cierra |
|---|---|---|
| **H1** Cada operación nueva agranda la interfaz de `Instruction` ("+500"; cada marca de micro tendría que mandarte pull requests) | M1 | M5 (el Visitor la saca de la interfaz) → M7 (pattern matching lo hace sin burocracia) |
| **H2** En estructurado los tanques son fáciles: un proceso recibe los dos y les mira el estado | M2 | M4 (eso es pattern matching: mirar la forma desde afuera) → M6 |
| **H3** Funcional no puede garantizar invariantes; objetos las valida en el constructor **y** en el setter | M2 | M8 (`case class Micro` con `require`: un solo lugar, la ventaja que objetos y funcional, cada uno por su lado, dejan sin resolver) |
| **H4** El data object es un antipatrón | M2 | M6 (las instrucciones son datos a propósito) |
| **H5** Delegar bien crea puntos de extensión | M2 | M3 (polimorfismo de subtipado) |
| **H6** El `switch`: el `break` olvidado y el scope compartido | M3 | M6 (`match` sin *fallthrough*, sin caer al caso siguiente; scope por rama) |
| **H7** "¿Cómo sabías qué funciones tocar? Control F" | M3 | M6 (el compilador avisa el caso faltante) |
| **H8** El control del recorrido lo tiene la estructura: `RunVisitor` necesita estado propio para saltear lo que le mandan; `SimplifyVisitor` necesita una pila | M5 | M7 (`run` decide si entra al `If`; `simplify` mira la forma de la lista) |
| **H9** Imprimir no necesita el micro, y el Visitor no te impide pasárselo igual a un visitante que nunca lo usa | M5 | M7 (`print` recibe solo el programa) |
| **H10** `run` sigue mutando el micro: no se puede "volver un paso" | M7 | M8 |
| **H11** El `swap` necesita una variable temporal | M1 (vuelve en M2, M5 y M7) | M8 (`copy(a = micro.b, b = micro.a)`) |
| **H12** `Halt` sigue siendo un `throw` | M8 | M9, y la próxima clase |

## Cómo leer cada bloque

| Bloque | Qué es |
|---|---|
| `> Recuadro` al inicio de cada sección | La regla, en afirmativo, en una a tres líneas. Después viene el caso, después el porqué |
| 🔴 🟡 🟢 en los títulos de sección | Importancia: central y evaluable · secundario · mencionado al pasar |
| Bloque sin lenguaje con `antes  →  después` | Un programa en la notación del `print` (`IF[LOD[0]]`) y lo que sale de ejecutarlo o simplificarlo |
| `// Resultado:` dentro del código | Qué sale al ejecutar, para saberlo sin salir de la lectura |
| **Para el parcial, si te preguntan** | Respuesta modelo. Con forma de diseño cuando la pregunta es de diseño ("aparece este requerimiento: ¿polimorfismo o pattern matching, y por qué?"); conceptual cuando la pregunta es conceptual |
| ⚠️ **Trampa** | Un error que está en el código original o que te puede pasar al escribirlo, con la forma correcta al lado; también una denominación distinta de la misma cosa |
| 🕳️ **Madriguera** | Algo que existe, está fuera del alcance de la materia, y se nombra para que no te lo lleves de tema |
| **Checkpoint** | Preguntas al cierre, sin respuestas. Las respuestas van al complemento de la unidad. (El Módulo 0, que es operativo, va sin checkpoint) |
| **De dónde venís** | Lo que el módulo asume sabido de módulos o clases anteriores |

## Cómo usarlo

1. En orden. Cada módulo se apoya en el anterior y la pregunta que lo cierra la abre el siguiente.
2. Con el proyecto de referencia abierto: todo bloque de código se pega y corre, y el texto dice qué tiene que salir. Cada módulo con código dice arriba qué paquete y qué archivo del proyecto usa; el Módulo 0 trae la tabla completa.
3. El checkpoint se hace al final de cada módulo, sin mirar atrás. Lo que no salga, se anota.
4. Las dudas van por chat durante la lectura. Al cerrar la unidad se destilan en el complemento, junto con las respuestas de los checkpoints.

## Información operativa de la clase

- **El TP2** (grupal, objeto-funcional en Scala) se presenta con esta clase; su enunciado figura en la planificación para el 24-Oct. Con lo visto en esta clase todavía no alcanza para resolverlo; la clase que viene completa las herramientas.
- **Para el checkpoint del TP2 (7-Nov)** conviene llegar con una solución imperfecta, hecha, para poder iterarla. Si te gusta más objetos, "el volante te va a tirar para el triángulo azul"; si te gusta más funcional, para el rojo. La idea es explorar variantes y poder justificar cada elección con el docente asignado.
- **El código de la clase está publicado** con todas las implementaciones (el repo de cátedra `scala-microprocesador-tuneado`; el código de referencia de esta unidad es su unificación, con los errores arreglados y declarados). Conviene llegar a la clase siguiente con ese código entendido.

## Qué queda afuera, y dónde está

- **Mónadas, `Option`, `Try`, `map`/`flatMap` sobre un `Result`, for-comprehension:** clase siguiente. El repo de la unidad ya trae ese código (`funcional-monadas`); no se usa acá.
- **La solución `puro` (objetos sin Visitor)** no se explicó en clase: está en el repo. M2 la lee de forma guiada, declarándolo.
- Como madrigueras, nombradas y cerradas: worksheets de IntelliJ (M0); `uninitialized` como reemplazo de `= _` (M1); matchear sin `case`, y `sealed` con sus variantes (M6); simplificar de una pasada (M7). Nombrados al pasar, sin madriguera: el patrón Composite (M5) y actores y arquitecturas distribuidas (M4).

## Limitaciones declaradas

- **Todo el código de los módulos se compiló y ejecutó en Scala 3.3.1** con el compilador real; los resultados que figuran como `// Resultado:` son los que salieron. Los mensajes de error son los del compilador 3.3.1, sin los sufijos `did you mean …`.
- **El código original de la cátedra tiene errores** (nueve en el repo, varios proyectados en clase). El código de referencia los tiene arreglados y declarados; los módulos muestran el error solo cuando enseña algo, según el tratamiento fijado al planificar la unidad (trampa inline, antipatrón con sección o errata en silencio).
- **Parte de los dibujos de la presencial se reconstruyó desde la transcripción** (dos fotos desenfocadas y varias lecturas dudosas de palabras sueltas); cuáles, lo dice el mapa de procedencia.
- **Circula la afirmación de que `RunVisitor` necesita una pila para soportar un `If` dentro de otro.** El código de referencia muestra que, con la bandera bien conectada, alcanza. M5 enseña el punto que sí vale (el visitor necesita estado propio) y marca la pila como trampa.

## Mapa de procedencia

Los módulos están escritos sin referencias a sus fuentes. Esta tabla existe para la trazabilidad: qué viene de la clase presencial del 24-Oct (que fija el recorte), qué completa el material anterior (video y capturas 2020, script, repo de cátedra, página del Visitor), y qué es ilustración propia.

| Módulo | Clase presencial | Completado desde material anterior | Ilustración propia |
|---|---|---|---|
| 0 | Foto 16 (árbol del proyecto); foto 3 (worksheet) | Estructura del repo `scala-microprocesador-tuneado` y su README | El recorrido del proyecto de referencia |
| 1 | Parte 2, líneas 1–2: "las operaciones del lenguaje son los datos"; el `If` con subprograma; "cada marca tendría que hacerme pull requests" (2:01) | Slides 12–23 del 2020 (el chip, la tabla de instrucciones, el ejemplo paso a paso, el programa redundante, los tres micros, el diagrama tachado); enunciado | — |
| 2 | 11:33–1:09: las dos reglas; Ruby y Scala sin atributos; Java y los públicos; acceso uniforme; la cadena universidad; ceder control; `obj msj par`; calculadora; objeto sistema; tanques; doble dispatch; Warcraft; estructurado; God object; data object; puntos de extensión; invariantes en funcional (42:38) | Slides 2–8 del 2020 (`Tarea`, `Equipo`, `vaATerminarAntesDe`); repo `puro` | La lectura guiada de `puro/Instructions.scala` |
| 3 | 1:09–1:32: polimorfismo se diseña; paloma y avión; `Figura` (foto 3); A/B/C y `m3` (fotos 4–6, 12); el `switch` y el `break` (foto 9); Control F; borrar; refactor; objetos vs estructurado; 1:46–1:52: `m3`, "objetos sabe que esto es un problema" | Slides 9–11 del 2020; script (llama "ad-hoc" al polimorfismo de objetos; trampa) | — |
| 4 | 0:00–5:41 (por qué funcional vuelve); 1:32–1:46 (las tres ideas; 1:34, pureza = falta de efecto + transparencia referencial; antagonismo, identidad, el delfín); fotos 7, 8, 14 (los triángulos; las 7 y 8 desenfocadas, reconstruidas desde la 14 y la transcripción) | Slide 1 del 2020; script (definición formal de transparencia referencial) | — |
| 5 | 1:53–2:14 (Gamma, estructura, doble despacho, citas, rendición); parte 2, líneas 3–43 (el código recorrido: `accept`, `visitProgram`, `Run`, `Print`, `Simplify`); fotos 10, 11, 13, 15, 17–20, 23 (el diagrama de las dos jerarquías de la sección 3 y los triángulos tachados de la sección 11 se reconstruyen desde la transcripción) | Página de SourceMaking (preclase); slides pt2 y capturas pt3 del 2020; repo `visitor` | — |
| 6 | Parte 2, 44–53 y 84–91: `::` vs `:`, `match` como expresión, guardas, `case class` y lo que regala, `copy` | Capturas pt4 slide 1 del 2020; fotos 21–22 (de donde salen los patrones de ejemplo) | Los ejemplos neutros de cada patrón |
| 7 | Parte 2, 43–68: `simplify`, `run`, "¿cuál extenderías?", el criterio, "pensá si te conviene estar en objetos puros"; fotos 21–22; 2:14–2:16 | Capturas pt4 slides 2–6; script | La comparación lado a lado |
| 8 | Parte 2, 69–98: consultas vs efectos, Scala con efecto, debugging, `case class Micro`, `require`, `copy`, `Operations1`, `foldLeft` | Capturas pt4 slides 7–11; script (transparencia referencial, debugging) | — |
| 9 | Parte 2, 98–114; fotos 24–25 | Repo `Operations3`; video 2020 2:09–2:13 (el error contemplado como un resultado posible); script (la firma `Result` vs `Unit`) | Los cuatro ejemplos de ejecución con resultados |
| Info operativa | Parte 2, 43, 115–120 | — | — |

---

**FIN DEL ROADMAP — Clase desde cero — Pattern matching, case classes y el híbrido objeto-funcional**
