# Clase desde cero — Pattern matching, case classes y el híbrido objeto-funcional — Módulo 0: El proyecto en el que trabajamos

**Unidad:** clase09 · **Lenguaje:** Scala 3.3.1 · **Archivos del proyecto:** todos (este módulo es el índice) · **Densidad:** 🟢 operativo; se consulta, no se estudia

---

## Sobre este documento

**Qué cubre.** Qué hay en el proyecto de referencia de la unidad (`fuente-repo-clase09-pattern-matching-y-case-classes.md`), por qué el mismo problema está resuelto cuatro veces, cómo se reparten esas soluciones en paquetes, qué archivo usa cada módulo, cómo se corren los tests y qué es un worksheet.

**Qué no cubre.** Cómo se instala el entorno ni cómo se arma un proyecto sbt: eso es el Módulo 0 de la clase07. Tampoco explica el código: eso son los módulos 1 a 9.

## De dónde venís

De los módulos 0 de las dos clases anteriores: un proyecto sbt tiene `build.sbt`, `project/build.properties`, el código en `src/main/scala` y los tests en `src/test/scala`; un test de ScalaTest se corre desde IntelliJ o con `sbt test`; un `package` es el nombre bajo el que se agrupan las clases, y la primera línea de cada archivo lo declara.

---

## 1. 🟢 Un problema, cuatro soluciones

> El proyecto de referencia tiene **cuatro soluciones al mismo problema**, el simulador de microprocesador del Módulo 1, cada una en su paquete. Los módulos las recorren en orden; la unidad consiste en compararlas.

Las unidades anteriores tenían un estado final: el código al que se llega al terminar. Esta tiene cuatro, porque la unidad no construye una solución sino que **cambia de herramienta** tres veces sobre el mismo problema, y lo que se aprende está en la diferencia entre una solución y la siguiente.

| Paquete | Qué solución es | Módulos que la usan |
|---|---|---|
| `tadp.microprocesador.objetos.puro` | Objetos como los conocés: cada instrucción sabe ejecutarse, imprimirse y simplificarse | M2 |
| `tadp.microprocesador.objetos.visitor` | El patrón Visitor: las instrucciones solo saben "aceptar" un visitante; cada operación es un visitante | M5 |
| `tadp.microprocesador.mutable` | Las instrucciones son datos (`case class`) y las operaciones son funciones que las miran con pattern matching. El micro sigue siendo mutable | M6, M7 |
| `tadp.microprocesador.inmutable` | Solo ejecutar, con el micro inmutable, en tres versiones: dos devuelven un micro nuevo y la tercera un `Result`. Imprimir y simplificar serían iguales a `mutable` | M8, M9 |

Los dos paquetes de objetos comparten el micro, que vive un nivel arriba, en `tadp.microprocesador.objetos`. Y aparte está `tadp.figuras`, un ejemplo chico de polimorfismo que usa el Módulo 3.

**Sobre el nombre "objetos puro".** El proyecto original que contenía las dos soluciones de objetos (con y sin Visitor) se llamaba así. En esta unidad, cuando un módulo dice "la solución `puro`" se refiere solo a la que está en el paquete `puro`: la que tiene las operaciones adentro de las instrucciones, sin Visitor.

## 2. 🟢 Qué hay en el proyecto

> El proyecto es un solo sbt con un paquete por solución; cada paquete se lee solo, sin saltar a otro.

```
tadp-clase09-pattern-matching-y-case-classes/
├── build.sbt                                Scala 3.3.1, ScalaTest 3.2.19
├── .gitignore
├── project/build.properties                 sbt 1.9.0
└── src/
    ├── main/scala/tadp/
    │   ├── microprocesador/
    │   │   ├── objetos/
    │   │   │   ├── Micro.scala              el micro mutable + ExecutionHaltException
    │   │   │   ├── puro/
    │   │   │   │   └── Instructions.scala   Program e instrucciones que se ejecutan, imprimen y simplifican
    │   │   │   └── visitor/
    │   │   │       ├── Instructions.scala   Program e instrucciones con accept
    │   │   │       └── Visitors.scala       InstructionVisitor, RunVisitor, PrintVisitor, SimplifyVisitor
    │   │   ├── mutable/
    │   │   │   ├── Instructions.scala       sealed trait + case objects + case classes
    │   │   │   ├── Micro.scala              el mismo micro mutable, copiado, sin la excepción
    │   │   │   └── Operations.scala         run, print y simplify con pattern matching + ExecutionHaltException
    │   │   └── inmutable/
    │   │       ├── Instructions.scala       las mismas instrucciones, copiadas
    │   │       ├── Micro.scala              case class Micro
    │   │       ├── Operations1.scala        run con una variable local
    │   │       ├── Operations2.scala        run con foldLeft
    │   │       └── Operations3.scala        run con Result (Success, Halted, Failure)
    │   └── figuras/
    │       └── Figuras.scala                Figura, Circulo, Rectangulo, imprimirArea
    └── test/scala/tadp/
        ├── microprocesador/
        │   └── MicroprocesadorTest.scala    52 tests, los mismos casos contra las cuatro soluciones
        └── figuras/
            └── FigurasTest.scala            2 tests
```

Dos archivos están repetidos a propósito: `mutable/Micro.scala` es una copia de `objetos/Micro.scala` sin la excepción (en los paquetes funcionales, `ExecutionHaltException` vive adentro de cada `Operations`), e `inmutable/Instructions.scala` es una copia de `mutable/Instructions.scala`. Cada paquete es autosuficiente: podés leer una solución sin saltar a otra.

## 3. 🟢 Qué archivo usa cada módulo

> Cada módulo con código dice arriba qué archivo usa. Esta es la tabla completa, para ubicarse.

| Módulo | Archivo(s) | Qué pasa con él |
|---|---|---|
| **1** El problema | `objetos/Micro.scala` | Se lee: es el micro del enunciado, con registros, memoria y validación de rango |
| **2** Encapsulamiento y delegación | `objetos/puro/Instructions.scala` | Lectura guiada: muestra la interfaz que crece con cada operación |
| **3** Polimorfismo y crecimiento | `figuras/Figuras.scala` | Se construye |
| **4** El triángulo rojo | — | Conceptual |
| **5** El Visitor | `objetos/visitor/Instructions.scala`, `objetos/visitor/Visitors.scala` | Se recorre entero, visitante por visitante |
| **6** Case classes y pattern matching | `mutable/Instructions.scala` | Se construye, después de ejemplos sueltos |
| **7** Las operaciones con pattern matching | `mutable/Operations.scala` (y `mutable/Micro.scala`) | Se construye, operación por operación, contra el Visitor |
| **8** El micro inmutable | `inmutable/Micro.scala`, `inmutable/Operations1.scala`, `inmutable/Operations2.scala` (y `inmutable/Instructions.scala`, copia de `mutable`) | Se construye |
| **9** Un resultado en vez de una excepción | `inmutable/Operations3.scala` | Se lee y se comenta; el detalle queda para la clase siguiente |

## 4. 🟢 Cómo se corre

> No hay aplicaciones (`object … extends App`): cada solución se usa desde los tests, desde una consola de Scala o desde un worksheet.

- **Los tests:** `sbt test` desde la raíz, o desde IntelliJ con el botón de play sobre cada clase de test (cuatro en `MicroprocesadorTest.scala`, una en `FigurasTest.scala`) o sobre la carpeta `test`. Corren 54 tests: 14 por cada una de las tres soluciones con las tres operaciones, 10 para el paquete inmutable y 2 para figuras. Los 54 pasan.
- **Un fragmento a mano:** la consola de sbt (`sbt console`) abre un REPL (una consola donde escribís una expresión y ves su valor al instante) con el proyecto cargado. Ahí se puede escribir, por ejemplo, `tadp.microprocesador.mutable.Operations.print(List(tadp.microprocesador.mutable.Add))` y ver `ADD`.
- **Un worksheet:** un archivo con extensión `.sc` dentro del proyecto. IntelliJ lo evalúa línea por línea y muestra el resultado de cada expresión al costado. Es la forma más cómoda de probar un bloque de los módulos sin armar un test. El ejemplo de figuras del Módulo 3 es el candidato natural para probar en uno.

> 🕳️ **Madriguera — worksheets de IntelliJ**
> Tienen dos modos (REPL y "plain") y detalles de configuración propios. Para esta unidad alcanza con crear el `.sc`, pegar código y ver el resultado al costado.
> *Volvé al camino — esto se profundiza aparte, otro día.*

## 5. 🟢 Lo que vas a ver por primera vez

> Tres construcciones de Scala aparecen por primera vez en esta unidad. Acá solo se nombran; cada una se explica en su módulo.

| Construcción | Dónde está | Dónde se explica |
|---|---|---|
| `sealed trait` + `case object` + `case class` | los dos `Instructions.scala` (`mutable` e `inmutable`) y `Result` en `Operations3.scala`; `case class` sola en `inmutable/Micro.scala` | M6 §1 (`case`), M6 §7 (`sealed`; las variantes, en madriguera) |
| `match` con patrones (`case Swap :: Swap :: otherInstructions =>`, `case Load(address) =>`, guardas `if`) | `mutable/Operations.scala` y las tres `Operations` de `inmutable` | M6 y M7 |
| `package object Operations { … }` | las cuatro `Operations` | M7: es una forma de agrupar funciones sueltas bajo un nombre; se usa como `Operations.run(…)` |

Y dos cosas chicas que conviene saber de entrada:

- `private var _a: Int = _` (en los dos `Micro.scala` mutables) significa "arranca con el valor por defecto del tipo", que para `Int` es `0`. M1 lo retoma.
- `List.fill(Micro.MEM_SIZE)(0)` (en el `Micro` inmutable, con `MEM_SIZE = 128`) arma una lista de 128 ceros. M8 lo usa.

## 6. 🟢 Qué difiere entre lo que los módulos construyen y el código final

> Los módulos construyen exactamente lo que está en el proyecto, con una diferencia: tres módulos (5, 8 y 9) muestran, además del código final, **errores que el código original tenía** y que el proyecto ya tiene corregidos.

En el Módulo 5 son cuatro. Uno tiene sección propia porque enseña la tesis del módulo: el `accept` del programa salteaba la redefinición de `visitInstruction`, y por eso la bandera de `RunVisitor` nunca actuaba. Los otros tres son trampas: una coma de más al imprimir un `If`, una lista que no se achicaba y una marca que nadie leía. En el Módulo 8, una trampa: el `If` de `Operations1`, cuyo resultado nadie guardaba. En el Módulo 9, otra: el `Result.apply` que volvía a evaluar el micro al fallar (y arrastra la firma, las llamadas y el arranque del `foldLeft`). En todos los casos se ve el error, se entiende por qué fallaba y se ve la forma correcta, que es la del proyecto.

---

**FIN DEL MÓDULO 0 — El proyecto en el que trabajamos**
