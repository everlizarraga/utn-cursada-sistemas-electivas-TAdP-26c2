# Clase desde cero — Comportamiento vs estructura y mónadas — Módulo 0: El proyecto en el que trabajamos

**Unidad:** clase10 · **Lenguaje:** Scala 3.3.1 · **Archivos del proyecto:** todos (este módulo es el índice) · **Densidad:** 🟢 operativo; se consulta, no se estudia

---

## Sobre este documento

**Qué cubre.** Qué hay en el proyecto de referencia de la unidad (`fuente-repo-clase10-comportamiento-vs-estructura-y-monadas.md`), por qué tiene tres bloques que no se parecen entre sí, qué archivo usa cada módulo, cómo se corren los tests, y qué construcciones de Scala vas a ver por primera vez.

**Qué no cubre.** Cómo se instala el entorno ni cómo se arma un proyecto sbt. Tampoco explica el código: eso son los módulos 1 a 11.

## De dónde venís

De los módulos 0 de las unidades anteriores: un proyecto sbt tiene `build.sbt`, `project/build.properties`, el código en `src/main/scala` y los tests en `src/test/scala`; un test de ScalaTest se corre desde IntelliJ o con `sbt test`; un `package` es el nombre bajo el que se agrupan las clases; un worksheet (`.sc`) evalúa línea por línea y muestra el resultado al costado.

---

## 1. 🟢 Un proyecto, tres bloques

> El proyecto de referencia tiene **tres bloques** que no comparten código entre sí: el micro, una escalera de ejemplos sobre listas, y una serie de cajas. Los módulos los recorren en otro orden: primero la escalera, después las cajas, y al final se vuelve al micro.

La unidad anterior tenía un problema y cuatro soluciones. Esta tiene un problema (el micro) y, antes de volver a él, un rodeo largo: una idea que se construye sobre listas chicas y se generaliza en cajas. Por eso el código está en tres paquetes separados.

| Paquete | Qué es | Módulos que lo usan |
|---|---|---|
| `tadp.niveles` | La misma consulta sobre materias, cursos y alumnos, resuelta cinco veces, cada vez un nivel más arriba. Más una lista alternativa, el `fold` escrito a mano, el lifteo y los monoides | M2, M3, M4, M5, M9 |
| `tadp.cajas` | Una caja propia que cumple el contrato de mónada; el mail del titular con `null` y con `Option`; la inscripción a un curso con excepciones y con `Try`; dos cajas que tardan, con `Future` | M6, M7, M8, M9, M11 |
| `tadp.microprocesador.monadas` | El micro inmutable con las instrucciones de siempre y **cuatro versiones de `run`**: con un `Result` propio que sabe `map` y `flatMap`, lo mismo con `for`, con `Try` y con `Try` más `for` | M1 (vistazo), M10 |

Lo que importa de la unidad está en el paso de un nivel al siguiente (en `niveles`) y en que el código del micro **casi no cambia** entre sus cuatro versiones (en `monadas`). Las cajas son el puente.

## 2. 🟢 Qué hay en el proyecto

> Cada bloque es autosuficiente: se lee sin saltar a otro.

```
tadp-clase10-comportamiento-vs-estructura-y-monadas/
├── build.sbt                                     Scala 3.3.1, ScalaTest 3.2.19
├── .gitignore
├── project/build.properties                      sbt 1.9.0
└── src/
    ├── main/scala/tadp/
    │   ├── niveles/
    │   │   ├── Dominio.scala                     Materia, Curso, Alumno
    │   │   ├── Nivel1PatternMatching.scala       nivel 1: Nil y ::
    │   │   ├── Nivel2TipoAlgebraico.scala        nivel 2: isEmpty, head, tail
    │   │   ├── ListaSnoc.scala                   una lista que crece por el final
    │   │   ├── Nivel3Fold.scala                  nivel 3: foldRight, y el fold a mano
    │   │   ├── Nivel4OrdenSuperior.scala         nivel 4: filter, map, flatMap
    │   │   ├── Nivel5For.scala                   nivel 5: for
    │   │   ├── Lifteo.scala                      map y filter como elevadores de funciones
    │   │   └── Monoide.scala                     neutro y combinar, seis instancias
    │   ├── cajas/
    │   │   ├── monada/Caja.scala                 unit, bind, zero, plus; map y filter derivados
    │   │   ├── mail/MailDelTitular.scala         con null, con Option
    │   │   ├── inscripcion/Inscripcion.scala     con excepciones, con Try
    │   │   └── futuros/SecuencialVsParalelo.scala  dos cajas que tardan
    │   └── microprocesador/monadas/
    │       ├── Instructions.scala                sealed trait + case objects + case classes
    │       ├── Micro.scala                       case class Micro
    │       ├── Operations1.scala                 Result con map y flatMap
    │       ├── Operations2.scala                 Result con for
    │       ├── Operations3.scala                 Try[Micro] con map y flatMap
    │       └── Operations4.scala                 Try[Micro] con for
    └── test/scala/tadp/
        ├── niveles/NivelesTest.scala             10 tests
        ├── cajas/CajasTest.scala                 17 tests, en cuatro clases
        └── microprocesador/MonadasTest.scala     11 tests, los mismos casos contra las cuatro versiones
```

`Instructions.scala` y `Micro.scala` son los mismos de la unidad anterior, copiados a este paquete para que el bloque se lea solo.

## 3. 🟢 Qué archivo usa cada módulo

> Cada módulo con código dice arriba qué archivo usa. Esta es la tabla completa, para ubicarse.

| Módulo | Archivo(s) | Qué pasa con él |
|---|---|---|
| **1** De dónde venimos y la pregunta de esta clase | `monadas/Micro.scala`, `monadas/Instructions.scala` | Vistazo: de dónde se parte |
| **2** Acoplado a la forma | `niveles/Dominio.scala`, `niveles/Nivel1PatternMatching.scala`, `niveles/ListaSnoc.scala` (solo su forma) | Se lee y se rompe a propósito |
| **3** Las cinco funciones | `niveles/Nivel2TipoAlgebraico.scala`, `niveles/ListaSnoc.scala` (sus operaciones, y `Nivel2SobreSnoc` al final del archivo) | Se construye |
| **4** `fold` | `niveles/Nivel3Fold.scala`, `niveles/Monoide.scala` | Se construye |
| **5** `filter`, `map` y `flatMap` | `niveles/Nivel4OrdenSuperior.scala`, `niveles/Lifteo.scala` | Se construye |
| **6** La caja | `cajas/monada/Caja.scala` | Se construye |
| **7** `Option` | `cajas/mail/MailDelTitular.scala` | Se construye, las tres versiones |
| **8** `Try` | `cajas/inscripcion/Inscripcion.scala` | Se construye, las dos versiones |
| **9** For comprehension | `niveles/Nivel5For.scala`, `cajas/monada/Caja.scala` | Se construye; `Option` en worksheet; `Try` se ve completo en el Módulo 10 |
| **10** El micro con cajas | `monadas/Operations1.scala` a `Operations4.scala` | Se recorre entero, versión por versión |
| **11** El gran elenco | `cajas/futuros/SecuencialVsParalelo.scala` | Se lee y se corre |

## 4. 🟢 Cómo se corre

> No hay aplicaciones: cada bloque se usa desde los tests, desde una consola de Scala o desde un worksheet.

- **Los tests:** `sbt test` desde la raíz, o desde IntelliJ con el botón de play sobre cada clase de test o sobre la carpeta `test`. Son 38 y pasan todos. Los de `FuturosTest` tardan un poco más que el resto, porque esperan de verdad (menos de medio segundo cada uno).
- **Un fragmento a mano:** `sbt console` abre un REPL (una consola donde escribís una expresión y ves su valor al instante) con el proyecto cargado.
- **Un worksheet:** un `.sc` dentro del proyecto. Es la forma más cómoda de probar los bloques de los módulos: cada expresión muestra su resultado al costado. Los módulos ponen ese resultado como comentario (`// Resultado: …`), así que no hace falta ejecutar para seguir la lectura; ejecutar es para practicar.

## 5. 🟢 Lo que vas a ver por primera vez, y lo que vuelve con más uso

> Varias construcciones de Scala aparecen por primera vez en esta unidad, y otras tres ya vistas se usan mucho más. Acá solo se nombran; cada una se explica en su módulo, antes de usarse.

**Nuevas:**

| Construcción | Dónde está | Dónde se explica |
|---|---|---|
| una lista cuya forma es *snoc* (`VaciaSnoc`, `Snoc`), que crece por el final | `niveles/ListaSnoc.scala` | M2 |
| `foldRight` | `niveles/Nivel3Fold.scala` | M4 |
| un `trait` con una instancia por caso (`Monoide`): lo nuevo es el uso, no la sintaxis | `niveles/Monoide.scala` | M4 |
| una función que devuelve una función (`List[A] => List[B]`) | `niveles/Lifteo.scala` | M5 |
| `withFilter` | `cajas/monada/Caja.scala`, `niveles/Nivel5For.scala` | M9 |
| `for { … } yield …` | `niveles/Nivel5For.scala`, `monadas/Operations2.scala`, `Operations4.scala` | M9 |
| `Option`, `Some`, `None`, `getOrElse`, `fold` sobre un `Option` | `cajas/mail/MailDelTitular.scala` | M7 |
| `Try`, `Success`, `Failure`, `recover` | `cajas/inscripcion/Inscripcion.scala`, `monadas/Operations3.scala`, `Operations4.scala` | M8 |
| `LazyList` y `scanLeft` (un flujo que no termina, y el `foldLeft` que entrega cada acumulado) | solo en worksheet | M4 |
| `identity` | solo en worksheet | M5 |
| `Future`, `blocking`, `Future.sequence`, `Await` | `cajas/futuros/SecuencialVsParalelo.scala` y su test | M11 |
| `ListBuffer` y `mutable.Set` | `cajas/mail`, `cajas/inscripcion` | Son colecciones mutables de Scala; se usan como un `var` con lista adentro. Están ahí para que los ejemplos tengan un registro; no son el tema |

**Ya vistas, con más uso:**

| Construcción | Dónde está | De dónde viene |
|---|---|---|
| `:+` ("esta lista, más este elemento al final") | `niveles/ListaSnoc.scala`, donde es el constructor de la forma | Unidad 08, sobre `List`; M2 lo retoma |
| `[U >: T]` en un método (un tipo "al menos tan amplio como `T`") | `niveles/ListaSnoc.scala`, `cajas/monada/Caja.scala` | Unidad 08, varianza; M3 lo recuerda en una línea |
| un parámetro por nombre (`=> T`), que no se evalúa hasta que se usa | `Try { … }`, `Option.fold`, `Result.apply` | Unidad anterior, `Result.apply`; M7 y M8 lo usan más |

## 6. 🟢 Qué difiere entre lo que los módulos construyen y el código final

> Los módulos construyen exactamente lo que está en el proyecto, con una diferencia: el código original de las cuatro versiones del micro tenía tres errores, y el proyecto ya los tiene corregidos.

Uno, el `Result.apply` que volvía a evaluar el micro al fallar, ya fue trampa en la unidad anterior, y el Módulo 10 lo recuerda en una línea. Otro, el micro que nacía con 1024 posiciones de memoria en vez de 128, está corregido en silencio, igual que en la unidad anterior. El tercero es nuevo y va como trampa en el Módulo 10 (sección 4): la versión con `for` del `run` ejecutaba el subprograma de un `If` antes de preguntar si correspondía, y por eso un `HALT` adentro de un `If` que no debía ejecutarse detenía todo el programa. En ese caso se ve el error, se entiende por qué fallaba y se ve la forma correcta, que es la del proyecto.

El código de la escalera y de las cajas no tiene original contra el que compararse: se armó para esta unidad, y los módulos lo construyen pieza por pieza.

---

**FIN DEL MÓDULO 0 — El proyecto en el que trabajamos**
