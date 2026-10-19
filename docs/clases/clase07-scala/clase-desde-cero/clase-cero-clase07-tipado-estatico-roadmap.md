# Clase desde cero — Tipado estático en Scala — Roadmap

**Unidad:** clase07 (TADP, 2C 2026) · **Lenguaje:** Scala 3.3.1 · **Tipo de material:** clase desde cero, 8 módulos + 1 de setup
**Qué es esto:** el índice de la clase. Dice qué necesitás tener a mano, en qué orden leer y por qué, qué dolor se siembra en un módulo y se cura en otro, cómo leer cada bloque, qué queda afuera y de dónde salió cada parte.

---

## Antes de empezar: dos cosas a mano

1. **El código final de la unidad**, en `fuente-repo-clase07-tipado-estatico.md`: un proyecto Scala completo con el `Saludador` terminado y los guerreros con sus seis tests, en los paquetes `tadp.nadaquever` y `tadp.ageofempires`. Todo el código de los módulos converge ahí. Tenerlo abierto en IntelliJ es la forma más rápida de probar lo que leés.
2. **El entorno instalado.** Esta unidad tiene una lectura previa, la `preclase07` ("Instalación de ambientes"), que es un material aparte. El Módulo 0 asume que IntelliJ ya abre proyectos Scala.

## Qué vas a poder hacer al terminar

- Leer y escribir Scala básico: clases con parámetros, `val`/`var`/`def`, `trait`, `extends`/`with`, `override`, anotaciones de tipo, tests con ScalaTest.
- Explicar qué chequea el compilador, cuándo, con qué información, y qué garantiza y qué no (falsos positivos y negativos, operaciones parciales).
- Decir qué cambia en la definición de polimorfismo cuando hay tipos, y elegir con fundamento entre un trait, una unión de tipos y un tipo estructural según qué puerta de extensión querés abrir.
- Aplicar la regla de qué tipo poner a un parámetro y a un retorno.
- Llevar el dominio de guerreros, murallas y misiles a Scala con contratos explícitos, y leer un error de compilación como un síntoma y no como el problema.
- Explicar qué es un cast, por qué existe, por qué falla en ejecución y por qué en el TP no lo vas a usar.
- Llegar a la clase siguiente (tipos paramétricos y varianza) con el problema que la motiva ya planteado.

Las dos del medio (elegir entre trait, unión y tipo estructural; y qué tipo poner a un parámetro y a un retorno) son las que se evalúan en el individual: aparece un requerimiento nuevo y hay que decidir **qué tipo** le ponés a cada cosa y por qué.

## Los módulos

Cuatro fases: **A** el problema y el chequeo (M0–M3) · **B** el polimorfismo con tipos (M4–M5) · **C** el dominio en Scala (M6–M7) · **D** el puente a la clase siguiente (M8).

| Módulo | Archivo (`clase-cero-clase07-tipado-estatico-…`) | Densidad | Qué cierra |
|---|---|---|---|
| **0** El proyecto en el que trabajamos | `modulo0-el-proyecto.md` | 🟢 corto | sbt, carpetas, `object … extends App`, un test |
| **1** El problema: un error de tipos que el test no vio | `modulo1-el-problema.md` | 🟡 corto | Qué es un tipo, un error de tipos, chequeo dinámico |
| **2** El mismo programa en Scala: chequeo estático | `modulo2-chequeo-estatico.md` | 🔴 | Sintaxis base de Scala; qué chequea el compilador y cuándo; síntoma vs problema; explícito/implícito/inferencia |
| **3** Ningún sistema de tipos es perfecto | `modulo3-ningun-sistema-es-perfecto.md` | 🟡 | Falsos positivos y negativos; operaciones parciales; cuándo y cómo aparece un error |
| **4** ¿Y el polimorfismo? Subtipado y contratos | `modulo4-subtipado-y-contratos.md` | 🔴 | El polimorfismo cambia de definición; subtipado; `trait` como contrato fuerte; `override` |
| **5** Qué tipo poner: amplitud, unión y tipos estructurales | `modulo5-que-tipo-poner.md` | 🔴 | Regla parámetro-arriba / retorno-abajo; `\|`; `type`; `{ def … }`; nominal vs estructural |
| **6** Guerreros I — del test al código, `???`, `var`/`val` e inmutabilidad | `modulo6-guerreros-1.md` | 🔴 | `???` y `Nothing`; property; versión inmutable; energía mínima |
| **7** Guerreros II — muralla y misil, traits como contratos | `modulo7-guerreros-2.md` | 🔴 | `Defensor`, `Atacante`, `with`, linearización; `val` cumple `def`; `Espadachin` |
| **8** Casteo, y por qué existen los tipos paramétricos | `modulo8-casteo-y-tipos-parametricos.md` | 🟡 | `asInstanceOf`, por qué no castear; `List[A]` como puente a la clase siguiente |

**Densidad:** 🔴 pide una sesión con el código abierto; 🟡 se lee de corrido; 🟢 es operativo, se consulta. (Las mismas tres marcas, dentro de un módulo, significan importancia de la sección; ver la leyenda.)

## El orden, y por qué

```
 M0 Proyecto ──► M1 Error de tipos (Ruby) ──► M2 Chequeo estático (Scala)
                                                        │
                                                        ▼
                                           M3 Ningún sistema es perfecto
                                                        │
                                                        ▼
                                           M4 Subtipado, trait, contrato
                                              │                    │
                                              ▼                    ▼
                                  M5 Qué tipo poner        M6 Guerreros I
                                              │                    │
                                              └─────────┬──────────┘
                                                        ▼
                                           M7 Guerreros II: Defensor, Atacante
                                                        │
                                                        ▼
                                           M8 Casteo → tipos paramétricos
```

- **M1 → M2:** la sintaxis de Scala se aprende sobre un programa que ya entendés en Ruby, línea por línea.
- **M2 → M3:** la última desventaja del chequeo estático ("rechaza programas válidos") es la entrada al módulo 3.
- **M3 → M4:** el programa válido que el compilador rechaza *es* el problema del polimorfismo.
- **M4 → M5 y M4 → M6** son independientes entre sí. M5 termina con el `Saludador`; M6 arranca los guerreros con lo mínimo. Se lee M5 antes de M6 para cerrar un dominio antes de abrir el otro.
- **M7** necesita la regla de M5 (`atacaA` recibe un `Defensor`) y los tests de M6.
- **M8** último: necesita `Nothing` (M6) y el falso negativo (M3), y cierra mirando a la clase siguiente.

## Hilos que se siembran y se cierran

| Hilo | Se siembra | Se cierra |
|---|---|---|
| **H1** El error que el test no vio | M1 | M2: el compilador lo frena antes de correr |
| **H2** ¿Qué tipo le pongo al parámetro? | M2 (anotaste `Persona`) | M5: la regla parámetro-arriba / retorno-abajo → aplicada en M7 (`atacaA(Defensor)`) |
| **H3** Asistente no es Persona | M3 (el falso negativo) | M4: trait y consentimiento → M5: unión y estructural como alternativas |
| **H4** ¿Por qué un `val` cumple un `def`? | M4 (`override val nombre`) | M6: property y getter → M7: un `def` no pisa un `val` |
| **H5** Hay programas que no se pueden construir | M2 (`method_missing` no se tipa), M3, M5 | M8: el cast es la herramienta para construirlos, y por qué no la vas a usar |
| **H6** `Nothing` | M6 (`???`) | M8 (`List[Nothing]`) |
| **H7** Inmutabilidad | M6 (`atacaA` que devuelve un guerrero nuevo) | **Queda abierto.** Es tema de la segunda mitad de la materia |

## Cómo leer cada bloque

| Bloque | Qué es |
|---|---|
| `> Recuadro` al inicio de cada sección | La regla, en afirmativo, en una a tres líneas. Después viene el caso, después el porqué |
| 🔴 🟡 🟢 en los títulos de sección | Importancia: central y evaluable · secundario · mencionado al pasar. (En la tabla de módulos de arriba, las mismas marcas indican densidad) |
| Tabla *escribís / Scala entiende / sale* | Varias formas de hacer lo mismo sobre un mismo caso, incluidas las que fallan, con el error |
| `// Resultado:` dentro del código | Qué sale al ejecutar, para saberlo sin salir de la lectura |
| **Para el parcial, si te preguntan** | Respuesta modelo. Con forma de diseño cuando la pregunta es de diseño ("aparece esto, ¿qué tipo le ponés y por qué?"); conceptual cuando la pregunta es conceptual |
| 🕳️ **Madriguera** | Algo que existe, está fuera del alcance de la materia, y se nombra para que no te lo lleves de tema |
| **Checkpoint** | Preguntas al cierre, sin respuestas. Las respuestas van al complemento de la unidad |
| **De dónde venís** | Lo que el módulo asume sabido de módulos o clases anteriores |

## Cómo usarlo

1. En orden. Cada módulo se apoya en el anterior y la pregunta que lo cierra la abre el siguiente.
2. Con el proyecto del Módulo 0 abierto: todo bloque de código se pega y corre, y el texto dice qué tiene que salir.
3. El checkpoint se hace al final de cada módulo, sin mirar atrás. Lo que no salga, se anota.
4. Las dudas van por chat durante la lectura. Al cerrar la unidad se destilan en el complemento, junto con las respuestas de los checkpoints.

## Qué queda afuera, y dónde está

- **Sobrecarga vs polimorfismo** figura en la planificación de la materia para esta fecha y ninguna fuente de la clase lo trató. Queda fuera del material.
- **Tipos paramétricos y varianza:** M8 solo los presenta como la salida al casteo. Son la clase siguiente.
- **Inmutabilidad:** M6 la muestra una vez y la deja sembrada. Se desarrolla en la segunda mitad.
- **Mónadas, pattern matching, case classes:** clases posteriores.
- Como madrigueras, nombradas y cerradas: `@main` (M0); cómo guarda Ruby los objetos (M1); `scala.Dynamic` y la sintaxis `if … then` (M2); la tercera alternativa al chequeo, Assembler (M3); la JVM no distingue tipos en ejecución (M4); Kotlin `open`/`final`, retornos obligatorios en TypeScript y "programas que no se pueden construir" (M5); `case class` (M6); el cast en otros lenguajes, el límite de parámetros de la JVM y las familias de tipos (M8).

## Limitaciones declaradas

- **El código no se compiló en Scala 3.3.1 al generar el material.** La sintaxis es la que los compiladores de Scala 3 aceptan y los seis tests del código final están calculados a mano. Los mensajes de compilación y de ejecución se muestran en el formato de Scala 3. Son textuales los que salen de la clase presencial (`value energia is not a member of Unit`, `Found:/Required:`, `NotImplementedError`, los `was not equal to`). Están reescritos a ese formato sin verificar contra el compilador: las cabeceras con línea y columna y los `^` de los errores de M2 §2 y M3 §2; `value nombre is not a member of …Persona` (M2); `ArithmeticException: / by zero` y `NoSuchElementException: head of empty list` (M3); `class Persona needs to be abstract …` y `class Guerrero needs to be abstract …` (M4, M7); los de `override` y de tipo incompatible al implementar un contrato (M4 §5 y §7); `Reassignment to val …` (M6); `variable energia cannot override a mutable variable` y `Not found: type Defensor` (M7); los tres errores al redefinir `energia` en `Muralla` (M7); `super may not be used on value …` y `needs to be a stable, immutable value` (M7); `value filter is not a member of Alumno`, `value aprobo is not a member of Any`, `Found: ("hola" : String) / Required: Alumno` y el texto exacto de `ClassCastException` (M8); y el posible aviso por la conversión implícita del tipo estructural (M5). Si compilás y una redacción difiere, lo que vale es la del compilador.
- **Reconstrucciones:** el `Misil` terminado y el `recibeDanio` de `Muralla` que resta un décimo vienen del repo de la cátedra, porque la clase los dejó sin cerrar; el ejemplo de la `SuperEspada` con un valor al azar (M7) está reconstruido; `Espadachin` (M7) es un agregado consistente con la clase, tomado del material de años anteriores.

## Mapa de procedencia

Los módulos están escritos sin referencias a sus fuentes. Esta tabla existe para la trazabilidad: qué viene de la clase presencial del 3-Oct (que fija el recorte), qué completa el material de años anteriores (video y repo 2020, slides, script), y qué es ilustración propia.

| Módulo | Clase presencial | Completado desde material anterior | Ilustración propia |
|---|---|---|---|
| 0 | Proyecto sbt con ScalaTest, correr tests en IntelliJ (pantallas) | — | `Hola` y `HolaTest` como ejemplos mínimos |
| 1 | Error de tipos como "usar algo para lo que no es", `method_missing` como manejo de un error de tipos, "dos arreglos posibles"; definiciones de tipo y aspectos, y "Ruby sí chequea, en ejecución" (pizarrón) | `Saludador` en Ruby con el error `name`/`nombre` (video y repo 2020); redacción de las definiciones (slides y script) | La `Muralla` que recibe `atacar` |
| 2 | Síntoma vs problema; explícito/implícito e inferencia, con qué se anota siempre; ventajas y desventajas; `method_missing` no se tipa; objetos más difícil de tipar que funcional | Traducción del `Saludador` a Scala paso a paso (capturas 2020); redacción de la definición, el diagrama y las listas de ventajas y desventajas (slides); "Scala infiere pero no todo" (script) | — |
| 3 | Los dos Venn (proyectados); falso negativo con el asistente; extremos triviales; función parcial, `head` de lista vacía y división por cero; cuándo y cómo; estado inválido peor que caerse | Redacción de los Venn (slides); el código Scala de `x / 0` y `List().head` (script) | — |
| 4 | Definición de polimorfismo de objetos vs tipada; consentimiento; `Any`; trait `Nombrable`; `override val nombre`; `override` y qué protege; "arreglar `Persona` por `Asistente`" | Superclase `Nombrable` como primer intento; convención `_nombre` (video y capturas 2020); subtipado y las cuatro formas de definir subtipos (slides) | — |
| 5 | Regla parámetro-arriba / retorno-abajo; unión de tipos y alias; tipo estructural `Saludable`; `Pato`; TypeScript estructural; puntos de extensión | Nominal vs estructural y la tupla (slides); `type Atacable` (script); ejercicio "caracterizar Ruby" (slides y video 2020) | "`class A {}` en Scala sí restringe"; el ejemplo de TypeScript con variable |
| 6 | Tests, `???` y `Nothing`, `var`/`val`, property, versión inmutable, `.max(0)`, error `value energia is not a member of Unit` | Estructura del `Guerrero` inicial (repo de cátedra) | En la versión inmutable, el guerrero nuevo toma el potencial ofensivo del atacado (`otro.potencialOfensivo`), que es lo coherente; en la pantalla de la clase tomaba el del atacante |
| 7 | Type mismatch con la muralla; "hay que cambiar dos cosas"; `Defensor`; `energia = 1000` en el cuerpo; `Guerrero extends Defensor`; dónde va `recibeDanio` | `Atacante`, `Misil`, `recibeDanio` de `Muralla` (repo de cátedra); `with` y linearización, `val` cumple `def` y `super` sobre `val` (video, capturas y script); `Espadachin` (2020); "la muralla no ataca no se testea" (video) | `SuperEspada` reconstruida; la `Torre` del bloque "Para el parcial"; el test de la muralla recién construida |
| 8 | `List()` es `List[Nothing]`; la lista de `Object`; `filter` con un parámetro menos; cast: definición, falla en ejecución, "no van a castear"; `List[Alumno]`; capas tipado → varianza | `asInstanceOf` y `leerDeLaBase` (script) | `Alumno` y `filter` como snippets del módulo, fuera del código final |

---

**FIN DEL ROADMAP — Clase desde cero — Tipado estático en Scala**
