# Código final unificado — clase09 — Pattern matching y case classes (Microprocesador)

> **Qué es este archivo.** El código completo y funcional de la unidad `clase09` (sábado 24-Oct-2026), escrito para **Scala 3.3.1**, sbt 1.9.0 y ScalaTest 3.2.19 (las versiones del repo del TP). Es la referencia sobre la que se apoya todo el material de la unidad: lo que figura acá se pega y corre. Esta unidad **no tiene un único estado final**: el mismo problema (el enunciado *Simulador de Microprocesadores*) se resuelve cuatro veces, y las cuatro soluciones están acá, cada una en su paquete, para poder compararlas. Además está el ejemplo de figuras con el que la clase presenta el polimorfismo de subtipado.
>
> **Qué no es.** No es una copia fiel del repo de cátedra `scala-microprocesador-tuneado`. Es una **unificación** de sus proyectos `objetos-puro`, `funcional-mutable` y `funcional-inmutable` en un solo proyecto sbt, cruzada con la **clase presencial** (transcripción y fotos del pizarrón y de la pantalla, que mandan ante cualquier diferencia), el video 2020 (transcripción y capturas del código), el script de la cátedra y el enunciado. En la pantalla de la presencial el título dice "Clase 08"; en este proyecto la unidad es `clase09`. Los bugs del repo están **arreglados con el cambio mínimo** y declarados uno por uno más abajo. Quedan afuera, a propósito, el proyecto `funcional-monadas` y el `script_clase10.md` de la raíz del repo: son el tema de la clase siguiente.
>
> **Generado:** 24-Oct-2026 · **Estado:** revisado en segunda pasada por un revisor independiente (v1: 19 hallazgos; v2, con la clase presencial: 10 hallazgos; todos aplicados) · **Compilación:** verificada con el compilador real de **Scala 3.3.1** (`scalac -encoding UTF-8 -deprecation -feature -Werror`): 0 errores, 0 advertencias. **Tests (agregados, no son de la cátedra):** los 54 pasan. Ver "Verificación".

## Las cuatro soluciones (y el ejemplo de figuras)

| Paquete | Qué es | Proyecto del repo | Operaciones |
|---|---|---|---|
| `tadp.microprocesador.objetos.puro` | Objetos sin Visitor: cada instrucción sabe ejecutarse, imprimirse y simplificarse | `objetos-puro` (paquete `puro`) | `Program.runOn`, `Program.print`, `Program.simplify` |
| `tadp.microprocesador.objetos.visitor` | Patrón Visitor: las instrucciones solo aceptan visitors; cada operación es un visitor | `objetos-puro` (paquete `visitor`) | `RunVisitor`, `PrintVisitor`, `SimplifyVisitor` |
| `tadp.microprocesador.mutable` | `case class` + pattern matching, con el micro mutable | `funcional-mutable` | `Operations.run`, `Operations.print`, `Operations.simplify` |
| `tadp.microprocesador.inmutable` | El micro pasa a ser una `case class` inmutable; `run` devuelve un micro nuevo | `funcional-inmutable` | `Operations1.run` (variable local), `Operations2.run` (`foldLeft`), `Operations3.run` (`Result`, sin excepciones) |
| `tadp.figuras` | El ejemplo de polimorfismo de subtipado de la clase: `Figura` con `area`, `Circulo` y `Rectangulo`, e `imprimirArea` que trata a cualquier figura igual | No está en el repo (se mostró en clase, en un worksheet) | `area`, `imprimirArea` |

`objetos.Micro` es el micro mutable que comparten `puro` y `visitor`. En `inmutable` solo hay `run`, como en el repo. Imprimir y simplificar no dependen del micro: su código sería el mismo de `mutable`, pero acá no se pueden aplicar a las instrucciones de `inmutable`, que son otros tipos.

## Procedencia y adaptaciones

| Archivo | De dónde sale | Adaptaciones declaradas |
|---|---|---|
| `build.sbt`, `.gitignore`, `project/build.properties` | Propios, con las versiones del repo del TP (3.3.1 / 1.9.0 / 3.2.19). El repo de cátedra está en 3.7.0 / sbt 1.11.0, con `name := "granja"` copiado de otra clase en los cuatro proyectos | Nombre del proyecto y `version := "0.1.0"` propios (el repo dice `"1.0"`). `.gitignore` mínimo para sbt e IntelliJ |
| Los `.scala` del microprocesador | Repo de cátedra, rama `scala-microprocesador-tuneado` | Paquete raíz `tadp.microprocesador` (el repo usa `ar.edu.utn.tadp.microprocesador`, con un proyecto sbt por solución). Un subpaquete por solución para que convivan en un proyecto. Espaciado normalizado (tabs a espacios, sin espacios al final de línea) |
| `objetos/Micro.scala` | Repo `objetos-puro` = clase presencial (foto 16, líneas 1 a 15; el resto quedó fuera de cuadro); igual a las capturas del video (pt3, slides 1 y 2), salvo la sintaxis de Scala 2 | Ninguna |
| `objetos/puro/Instructions.scala` | Repo `objetos-puro/puro`. **No aparece en las capturas del video.** La transcripción describe la idea en 52:17 (las operaciones como mensajes de las instrucciones, antes de ver el Visitor) y en 2:11:54 la nombra como una solución extra, "pura en objetos sin visitor", que no se vio en clase. En la presencial no se mostró ni se nombró aparte: la parte 2 arranca con "cómo está programado esto de una forma naiv en objetos usando objetos puros, usando un visitor" (el proyecto `objetos-puro`) y va directo al Visitor. La pestaña `puro/Instructions.scala` está abierta en el IDE (foto 3), pero no se recorre. El script la enlaza | Bugs 1 y 2 arreglados. `IFZ[` → `IF[`, como imprimen las otras tres soluciones |
| `objetos/visitor/Instructions.scala` | Repo `objetos-puro/visitor` = clase presencial (recorrida en pantalla, transcripción parte 2) = capturas del video (pt3, slides 3 a 6), salvo dos cosas. La sintaxis de Scala 2. Y que en la captura `Program` recibe `Seq[Instruction]` (Scala 2.12, donde `Seq` acepta colecciones mutables): desde Scala 2.13 `Seq` es inmutable, y el repo usa `collection.Seq` para que `SimplifyVisitor` pueda pasarle un `ListBuffer` | Bug 3 arreglado. Se quitó el `import` de `Micro`, que el archivo no usa |
| `objetos/visitor/Visitors.scala` | Repo `objetos-puro/visitor` = clase presencial (fotos 17 a 19: `InstructionVisitor`, `PrintVisitor`, `SimplifyVisitor.visitSwap`) = capturas del video (pt3, slides 7 a 19). Las líneas que las fotos y las capturas cortaron se completaron con el repo | Bugs 4, 5 y 6 arreglados. **`PrintVisitor` sin parámetro**, como en la presencial (foto 18): el repo y el video lo declaran `PrintVisitor(micro: Micro)`, pero imprimir no usa el micro |
| `mutable/Instructions.scala` | Repo `funcional-mutable` = clase presencial (transcripción parte 2) = capturas del video (pt4, slide 1) | Ninguna |
| `mutable/Micro.scala` | Repo `funcional-mutable` (copia del micro de `objetos-puro`, sin la excepción) | Ninguna |
| `mutable/Operations.scala` | Repo `funcional-mutable` = clase presencial (fotos 21 y 22: `simplify` y `print`; `run`, en la transcripción) = capturas del video (pt4, slides 2 a 6) | Ninguna: es la única solución del repo que funciona tal cual |
| `inmutable/Instructions.scala` | Repo `funcional-inmutable` (idéntico a `mutable`) | Ninguna |
| `inmutable/Micro.scala` | Repo `funcional-inmutable` = clase presencial (transcripción parte 2) = capturas del video (pt4, slide 7) | Bug 7 arreglado |
| `inmutable/Operations1.scala` | Repo `funcional-inmutable` = clase presencial (transcripción parte 2) = capturas del video (pt4, slides 8 y 9) | Bug 8 arreglado |
| `inmutable/Operations2.scala` | Repo `funcional-inmutable` = clase presencial (transcripción parte 2) = capturas del video (pt4, slides 10 y 11) | Ninguna |
| `inmutable/Operations3.scala` | Repo `funcional-inmutable` = clase presencial (fotos 24 y 25, y transcripción parte 2: se mostró como un paso intermedio y el detalle quedó para la clase siguiente). El video 2020 solo lo nombra al cierre (2:12:26), sin mostrar el código | Bug 9 arreglado (también está en lo proyectado en la presencial, foto 24) |
| `figuras/Figuras.scala` | Clase presencial (foto 3: `playground.sc`, un *worksheet*, archivo de Scala que se evalúa línea por línea en IntelliJ; transcripción parte 1, 1:13:06 a 1:14:34). No está en el repo | Pasado de worksheet a archivo `.scala`, con las mismas definiciones, en un paquete propio `tadp.figuras` (el worksheet no declara paquete y estaba en la carpeta `microprocesador` de `objetos-puro`). Se quitó `import Math.PI`, que no se usa (el código escribe `Math.PI`). **`imprimirArea` imprime el área:** en la foto es `def imprimirArea(figura: Figura): Unit = figura.area`, que calcula el área y la descarta (el tipo de retorno `Unit` descarta el `Double`; con las opciones de esta referencia, 3.3.1 lo compila sin aviso, y solo con `-Wvalue-discard` avisa `discarded non-Unit value of type (figura.area : => Double)`); acá es `println(figura.area)` |
| `MicroprocesadorTest.scala`, `FigurasTest.scala` | **AGREGADOS.** El repo no trae tests (aunque su README explica cómo correrlos), y el ejemplo de figuras tampoco | Generados para esta referencia: la misma batería, sobre el enunciado, contra las cuatro soluciones; y dos tests de figuras |

**Scala 2 en las capturas.** El código de las capturas está en Scala 2 y usa la sintaxis de procedimiento: definiciones sin `=` (`def accept(visitor: InstructionVisitor) { … }`, `def run(program: Program, micro: Micro) { … }`, `def a_=(value: Int) { … }`) y declaraciones abstractas sin tipo (`def visitAdd(instruction: Add.type)`). Scala 3.3.1 las rechaza con error de sintaxis: hay que escribir `: Unit = { … }` y `: Unit`, como en el repo y acá. Debajo de cada archivo que cambia hay una línea con la forma del video.

## Bugs del repo arreglados

Todos se verificaron **ejecutando el código original** de la cátedra con Scala 3.3.1 (compila sin advertencias) antes de tocarlo. Con el código original, los 52 tests del microprocesador (con el mismo reemplazo de ScalaTest, ver "Verificación", y `new PrintVisitor(new Micro)`, porque el original recibe el micro) dan **29 ✓ y 23 ✗**: `puro` falla 8, `visitor` 11, `inmutable` 4 y `mutable` ninguno.

| # | Dónde | Qué pasaba con el código original | Arreglo (cambio mínimo) |
|---|---|---|---|
| 1 | `puro` · `Program.simplify` | `instructions = simplifiedPair ++ instructions.drop(2)` reemplaza siempre las **dos primeras** instrucciones, no el par de la posición actual. `ADD, LOD[0], LOD[1], SWP, SWP, STR[2], STR[2], MUL` quedaba `STR[2], MUL, STR[2], MUL` | `instructions.take(simplified) ++ simplifiedPair ++ instructions.drop(simplified + 2)`. Con el arreglo, el mismo programa queda `ADD, LOD[1], STR[2], MUL` |
| 2 | `puro` · `If` al final | Un `If` solo se simplifica cuando tiene una instrucción a continuación (`simplifiedBefore(next)`). `ADD, IF[SWP, SWP]` quedaba igual | `simplifiedAtTheEnd` en `Instruction` (por defecto, la instrucción tal cual) y redefinido en `If` (simplifica el cuerpo; si queda vacío, desaparece). `Program.simplify` lo aplica a la última instrucción |
| 3 | `visitor` · `Program.accept` | Llama `instruction.accept(visitor)`, así que el `visitInstruction` redefinido de `RunVisitor` nunca se ejecuta y su flag `ignoreInstructions` no tiene efecto: **el `IF` ejecuta siempre**. Con A = 5, `IF[LOD[0]]` cargaba A igual (quedaba en 13 en vez de 5) | `visitor.visitInstruction(instruction)`. Con eso el flag funciona y también el `IF` dentro de otro `IF`, en los dos casos: si el de afuera no se ejecuta, el de adentro se saltea entero sin tocar el flag; si el de afuera se ejecuta y el de adentro no, el de adentro lo prende y lo apaga, y lo que sigue en el de afuera corre |
| 4 | `visitor` · `PrintVisitor.addText` | Después de `"IF["` agrega la coma igual: imprimía `IF[, LOD[2], IF[, ADD]]` | No agrega coma si el texto termina en `[`: `if(text.isEmpty \|\| text.endsWith("[")) "" else ", "` |
| 5 | `visitor` · `SimplifyVisitor` (tres lugares) | `simplified.top.dropRight(1)` **devuelve una lista nueva** y deja el `ListBuffer` igual. Con SWAP queda uno de los dos (`ADD, SWP, SWP, MUL` → `ADD, SWP, MUL`). Las reglas de LOAD y STORE dejan los dos | `simplified.top.dropRightInPlace(1)`, que sí saca el último del `ListBuffer` |
| 6 | `visitor` · `SimplifyVisitor.visitedHalt` | Se marca en `visitHalt` pero nadie lo lee: lo que viene después de un `HLT` no se eliminaba | `override def visitInstruction` que no visita nada si `visitedHalt`, y `visitedHalt = false` en `endVisitIf`: un `HLT` dentro de un `IF` corta solo el resto del `IF`, igual que en `mutable` (`IF[HLT, ADD], MUL` → `IF[HLT], MUL`) |
| 7 | `inmutable` · `Micro` | El valor por defecto de `mem` es `List.fill(Micro.REGISTER_SIZE)(0)` (1024 posiciones), pero el `require` exige `MEM_SIZE` (128): `Micro(0, 0)` lanzaba `IllegalArgumentException` | `List.fill(Micro.MEM_SIZE)(0)` |
| 8 | `inmutable` · `Operations1.run` | El `case If` es `if (micro.a == 0) run(subInstructions, micro) else micro`, una expresión **cuyo resultado nadie guarda**: las otras ramas reasignan `micro` y esta no. El `IF` no tenía efecto | `if (micro.a == 0) micro = run(subInstructions, micro)`. En `Operations2` la misma línea sí funciona, porque el valor del `match` es lo que devuelve el `foldLeft` |
| 9 | `inmutable` · `Operations3.Result.apply` | Recibe el micro por nombre (`micro: => Micro`) y en el `catch` lo vuelve a evaluar para armar el `Failure`: la excepción se lanza **de nuevo** y escapa. `Failure` nunca llegaba a construirse | `Result(previousMicro)(micro)`: el `Failure` guarda el último micro válido. El `foldLeft` arranca en `Success(initialMicro): Result` |

**Los bugs 3, 4, 5, 7 y 8 también están en el código del video:** bug 3 en pt3 slide 3, bug 4 en pt3 slide 12, bug 5 en pt3 slides 15 a 17, bug 7 en pt4 slide 7 y bug 8 en pt4 slide 9. Y los bugs 4, 5 y 9 están en lo proyectado en la presencial: bug 4 en la foto 18, bug 5 en la foto 19 y bug 9 en las fotos 24 y 25.

**Sobre el bug 3, la presencial y el video.** En la presencial (transcripción parte 2) y en el video (1:26:21), el profe dice que dejó a propósito un error en `RunVisitor`: no soporta un `IF` dentro de otro, y para eso haría falta una pila. El código proyectado, el del video y el del repo tienen un problema más grande, el bug 3: el flag no actúa nunca. Con el arreglo, un `IF` salteado se saltea entero, sin pasar por `visitIf` ni por `endVisitIf`; por eso alcanza con el flag y el caso anidado funciona (lo prueban los tests). La idea de la clase se mantiene: para ejecutar, el visitor necesita estado propio (el flag), porque el recorrido lo controlan las instrucciones.

## Lo que se mantiene como en la cátedra

- **Rango de los registros:** el código exige `-1024 < valor < 1024` (estricto); el enunciado dice "entre -1024 y 1024". Se mantiene el código.
- **`package object Operations`** (y `Operations1` a `3`): es válido en 3.3.1 y compila sin advertencias. Scala 3 prefiere un `object` común o definiciones sueltas en el archivo; el uso es el mismo (`Operations.run(…)`). Se mantiene como lo escribe la cátedra.
- **`private var _a: Int = _`** (valor por defecto del tipo, 0 para `Int`): válido en 3.3.1 sin advertencias. Con `-source future` ya figura como deprecado; la forma nueva es `= uninitialized` (con `import scala.compiletime.uninitialized`). Se mantiene.
- **Simplificar es de una pasada en las tres soluciones:** si al eliminar instrucciones quedan juntas dos que también se simplifican, quedan las dos. `LOD[0], SWP, SWP, LOD[1]` → `LOD[0], LOD[1]`; `STR[2], SWP, SWP, STR[2]` → `STR[2], STR[2]`; `LOD[0], IF[], LOD[1]` → `LOD[0], LOD[1]`. Se mantiene como en la cátedra.
- **Errata de las slides del ejemplo:** el paso a paso del video (slides 13 a 19 de la parte 1) carga A = 39 y B = 13, hace `ADD` y muestra **A = 42**, y después guarda 42 en la posición 9 (slides 17 a 19). La suma da **52**, que es lo que devuelven las cuatro soluciones y lo que esperan los tests.
- **Formato del PRINT en las slides:** las slides 20 y 21 de la parte 1 muestran `"LOAD[0],LOAD[0],SWAP,SWAP,SWAP,STORE 1,STORE 1"`. El código imprime `LOD[0], LOD[0], SWP, SWP, SWP, STR[1], STR[1]`: abreviaturas de tres letras, espacio después de la coma y corchetes también en STORE. Vale el del código.

## Verificación

**Compilación**, con el compilador real de Scala 3.3.1 (`scalac -encoding UTF-8 -deprecation -feature -Werror`): los trece archivos de `src/main` compilan con 0 errores y 0 advertencias. Los dos archivos de tests también compilan con `-Werror`.

**Tests:** los 54 pasan. ScalaTest no se pudo descargar en el entorno de verificación, así que los archivos de tests se compilaron y se ejecutaron contra un reemplazo mínimo con la misma interfaz que usan (`AnyFunSuite` con `test` e `intercept`; `Matchers` con `shouldBe`). Los nombres y la forma de uso son los de ScalaTest 3.2.19; el reemplazo implementa solo lo que usan estos dos archivos. **Limitación declarada:** falta correrlos con ScalaTest real; `sbt test` en la máquina del estudiante cierra esa diferencia.

### Los 54 tests (AGREGADOS)

Cada fila es un caso del enunciado; ✓ marca en qué solución se prueba.

| Caso | `puro` | `visitor` | `mutable` | `inmutable` |
|---|:---:|:---:|:---:|:---:|
| Ejecuta el ejemplo `LOAD 0, SWAP, LOAD 1, ADD, STORE 9` sobre la memoria `13, 39, 0, 0, 4, 8, 15, 16, 23, 0` → A = 52, B = 13, mem(9) = 52 | ✓ | ✓ | ✓ | ✓ (`Operations1`, `2` y `3` dan el mismo micro, y el original queda igual) |
| `IF` ejecuta su cuerpo solo si A es 0 | ✓ | ✓ | ✓ | ✓ (las tres) |
| `IF` dentro de `IF`: si el de afuera se ejecuta, el de adentro no, y lo que sigue en el de afuera sí | ✓ | ✓ | ✓ | ✓ (las tres) |
| `IF` dentro de `IF`: si el de afuera no se ejecuta, no corre nada | ✓ | ✓ | ✓ | ✓ (las tres) |
| `HALT` lanza `ExecutionHaltException` después de aplicar lo anterior | ✓ | ✓ | ✓ | ✓ (`Operations1` y `2`, solo la excepción) |
| Un registro fuera de rango falla con `IllegalArgumentException` | ✓ | ✓ | ✓ | ✓ (`Micro(1024, 0)`) |
| `Micro(0, 0)` arranca con 128 posiciones en 0 | | | | ✓ |
| Imprime `LOD[0], SWP, ADD, MUL, STR[1], IF[LOD[2], IF[ADD]], HLT` | ✓ | ✓ | ✓ | |
| Simplifica el ejemplo del video: `LOD[0], LOD[0], SWP, SWP, SWP, STR[1], STR[1]` → `LOD[0], SWP, STR[1]` | ✓ | ✓ | ✓ | |
| Dos `SWAP` seguidos se eliminan | ✓ | ✓ | ✓ | |
| De dos `LOAD` seguidos se elimina el primero | ✓ | ✓ | ✓ | |
| De dos `STORE` seguidos en la misma dirección se elimina el primero; en distinta, quedan los dos | ✓ | ✓ | ✓ | |
| Un `IF` vacío, o que queda vacío al simplificarlo (`IF[SWP, SWP]`), se elimina | ✓ | ✓ | ✓ | |
| Se elimina todo lo posterior a un `HALT` | ✓ | ✓ | ✓ | |
| Un `HALT` dentro de un `IF` no elimina lo que sigue después del `IF` | ✓ | ✓ | ✓ | |
| `Operations3`: `HALT` devuelve `Halted` con el micro de ese momento, sin excepción | | | | ✓ |
| `Operations3`: un `HALT` dentro de un `IF` que se ejecuta detiene todo el programa | | | | ✓ |
| `Operations3`: una instrucción que falla (registro fuera de rango, dirección 500) devuelve `Failure` con el último micro válido y el error | | | | ✓ |
| **Total** | **14** | **14** | **14** | **10** |

Y en `FigurasTest`, dos más: cada figura calcula su área (`Rectangulo(3, 4)` → 12.0, `Circulo(1)` → π), e `imprimirArea` imprime el área de cualquier figura de una lista (`12.0` para `Rectangulo(3, 4)` y π para `Circulo(1)`).

## Cómo usarlo

Abrir la carpeta `tadp-clase09-pattern-matching-y-case-classes` en IntelliJ como proyecto sbt, o `sbt test` desde la raíz. No hay aplicaciones (`App`): cada solución se usa desde los tests o desde una consola de Scala (o un worksheet, como en clase).

## Árbol del proyecto

```
tadp-clase09-pattern-matching-y-case-classes/
├── build.sbt
├── .gitignore
├── project/
│   └── build.properties
└── src/
    ├── main/scala/tadp/
    │   ├── microprocesador/
    │   │   ├── objetos/
    │   │   │   ├── Micro.scala             micro mutable + ExecutionHaltException
    │   │   │   ├── puro/
    │   │   │   │   └── Instructions.scala  Program + instrucciones que se ejecutan, imprimen y simplifican
    │   │   │   └── visitor/
    │   │   │       ├── Instructions.scala  Program + instrucciones con accept
    │   │   │       └── Visitors.scala      InstructionVisitor, RunVisitor, PrintVisitor, SimplifyVisitor
    │   │   ├── mutable/
    │   │   │   ├── Instructions.scala      sealed trait + case objects + case classes
    │   │   │   ├── Micro.scala             micro mutable
    │   │   │   └── Operations.scala        run, print y simplify con pattern matching
    │   │   └── inmutable/
    │   │       ├── Instructions.scala      las mismas instrucciones
    │   │       ├── Micro.scala             case class Micro
    │   │       ├── Operations1.scala       run con variable local
    │   │       ├── Operations2.scala       run con foldLeft
    │   │       └── Operations3.scala       run con Result (Success, Halted, Failure)
    │   └── figuras/
    │       └── Figuras.scala               Figura, Circulo, Rectangulo, imprimirArea
    └── test/scala/tadp/
        ├── microprocesador/
        │   └── MicroprocesadorTest.scala   AGREGADO: 52 tests
        └── figuras/
            └── FigurasTest.scala           AGREGADO: 2 tests
```

## Archivos

### `build.sbt`

*Configuración del proyecto, con las versiones del repo del TP.*

```scala
ThisBuild / scalaVersion     := "3.3.1"
ThisBuild / version          := "0.1.0"
ThisBuild / organization     := "ar.edu.utn.frba.tadp"

lazy val root = (project in file("."))
  .settings(
    name := "tadp-clase09-pattern-matching-y-case-classes",
    libraryDependencies += "org.scalatest" %% "scalatest" % "3.2.19" % Test
  )
```

### `project/build.properties`

*Versión de sbt del repo del TP.*

```properties
sbt.version=1.9.0
```

### `.gitignore`

*Mínimo para sbt e IntelliJ.*

```
target/
project/target/
project/project/
.bsp/
.idea/
*.iml
```

### `src/main/scala/tadp/microprocesador/objetos/Micro.scala`

*El micro **mutable** que comparten las dos soluciones de objetos (`puro` y `visitor`): registros `a` y `b` con setter que valida el rango, y 128 posiciones de memoria. También la excepción con la que `HALT` corta la ejecución.*

```scala
package tadp.microprocesador.objetos

class Micro {
  private val MEM_SIZE = 128
  private val REGISTER_SIZE = 1024

  private var _a: Int = _
  private var _b: Int = _
  private var _mem: Array[Int] = new Array(MEM_SIZE)

  def a = _a
  def a_=(value: Int): Unit = {
    require(value < REGISTER_SIZE && value > -REGISTER_SIZE)
    _a = value
  }

  def b = _b
  def b_=(value: Int): Unit = {
    require(value < REGISTER_SIZE && value > -REGISTER_SIZE)
    _b = value
  }

  def mem = _mem
}

class ExecutionHaltException extends RuntimeException
```

En el video (Scala 2) se escribía `def a_=(value: Int) { … }` y `def b_=(value: Int) { … }`, sin `: Unit =`.

### `src/main/scala/tadp/microprocesador/objetos/puro/Instructions.scala`

**Objetos sin Visitor.** Cada instrucción sabe ejecutarse (`beExecutedBy`), imprimirse (`print`) y simplificarse de a pares (`simplifiedBefore(next)`), con mensajes auxiliares (`cancelsWithSwap`, `overwritesAWithoutReading`, `overwritesAddress`) para decidir sin preguntar por la clase. Es el diseño donde la interfaz `Instruction` crece con cada operación nueva.

```scala
package tadp.microprocesador.objetos.puro

import tadp.microprocesador.objetos.Micro
import tadp.microprocesador.objetos.ExecutionHaltException

// ---------------------------------------------------------------------------------------------------------------------------------
// PROGRAM
// ---------------------------------------------------------------------------------------------------------------------------------

class Program(private var instructions: Seq[Instruction]) {
  def runOn(micro: Micro): Unit = {
    for (instruction <- instructions)
      instruction.beExecutedBy(micro)
  }

  def print = instructions.map(_.print).mkString(", ")

  def simplify: Unit = {
    var simplified = 0
    while (simplified < instructions.size - 1) {
      val simplifiedPair: Seq[Instruction] = instructions(simplified).simplifiedBefore(instructions(simplified + 1))
      instructions = instructions.take(simplified) ++ simplifiedPair ++ instructions.drop(simplified + 2)
      simplified += 0.max(simplifiedPair.size - 1)
    }
    if (instructions.nonEmpty) instructions = instructions.init ++ instructions.last.simplifiedAtTheEnd
  }

  def instructionCount = instructions.size
}

// ---------------------------------------------------------------------------------------------------------------------------------
// INSTRUCTIONS
// ---------------------------------------------------------------------------------------------------------------------------------

trait Instruction {
  def beExecutedBy(micro: Micro): Unit

  def print: String

  def simplifiedBefore(next: Instruction): Seq[Instruction] = Seq(this, next)
  def simplifiedAtTheEnd: Seq[Instruction] = Seq(this)
  def cancelsWithSwap = false
  def overwritesAWithoutReading = false
  def overwritesAddress(address: Int) = false
}

object Add extends Instruction {
  def beExecutedBy(micro: Micro): Unit = {
    micro.a = micro.a + micro.b
  }

  def print = "ADD"
}

object Mul extends Instruction {
  def beExecutedBy(micro: Micro): Unit = {
    micro.a = micro.a * micro.b
  }

  def print = "MUL"
}

object Swap extends Instruction {
  def beExecutedBy(micro: Micro): Unit = {
    val temp = micro.a
    micro.a = micro.b
    micro.b = temp
  }

  def print = "SWP"

  override def simplifiedBefore(next: Instruction) = if (next.cancelsWithSwap) Seq() else super.simplifiedBefore(next)
  override def cancelsWithSwap = true
}

class Load(val address: Int) extends Instruction {
  def beExecutedBy(micro: Micro): Unit = {
    micro.a = micro.mem(address)
  }

  def print = s"LOD[$address]"

  override def simplifiedBefore(next: Instruction) = if (next.overwritesAWithoutReading) Seq(next) else super.simplifiedBefore(next)
  override def overwritesAWithoutReading = true
}

class Store(val address: Int) extends Instruction {
  def beExecutedBy(micro: Micro): Unit = {
    micro.mem(address) = micro.a
  }

  def print = s"STR[$address]"

  override def simplifiedBefore(next: Instruction) = if (next.overwritesAddress(address)) Seq(next) else super.simplifiedBefore(next)
  override def overwritesAddress(address: Int) = this.address == address
}

class If(subInstructions: Program) extends Instruction {
  def beExecutedBy(micro: Micro): Unit = {
    if (micro.a == 0) subInstructions.runOn(micro)
  }

  def print = s"IF[${subInstructions.print}]"

  override def simplifiedBefore(next: Instruction) = {
    subInstructions.simplify
    if (subInstructions.instructionCount == 0) Seq(next) else super.simplifiedBefore(next)
  }

  override def simplifiedAtTheEnd = {
    subInstructions.simplify
    if (subInstructions.instructionCount == 0) Seq() else super.simplifiedAtTheEnd
  }
}

object Halt extends Instruction {
  def beExecutedBy(micro: Micro): Unit = {
    throw new ExecutionHaltException
  }

  def print = "HLT"

  override def simplifiedBefore(next: Instruction) = Seq(this)
}
```

### `src/main/scala/tadp/microprocesador/objetos/visitor/Instructions.scala`

**Visitor: los elementos.** Las instrucciones solo exponen `accept(visitor)`, que le devuelve el control al visitor llamando al `visitXxx` de su propio tipo (doble despacho). El `If` además recorre sus subinstrucciones y avisa cuándo entra y cuándo sale.

```scala
package tadp.microprocesador.objetos.visitor

// ---------------------------------------------------------------------------------------------------------------------------------
// PROGRAM
// ---------------------------------------------------------------------------------------------------------------------------------

class Program(private var instructions: collection.Seq[Instruction]) {
  def instructionCount = instructions.size

  def accept(visitor: InstructionVisitor): Unit = {
    for (instruction <- instructions)
      visitor.visitInstruction(instruction)
  }
}

// ---------------------------------------------------------------------------------------------------------------------------------
// INSTRUCTIONS
// ---------------------------------------------------------------------------------------------------------------------------------

trait Instruction {
  def accept(visitor: InstructionVisitor): Unit
}

object Add extends Instruction {
  def accept(visitor: InstructionVisitor) = visitor.visitAdd(this)
}

object Mul extends Instruction {
  def accept(visitor: InstructionVisitor) = visitor.visitMul(this)
}

object Swap extends Instruction {
  def accept(visitor: InstructionVisitor) = visitor.visitSwap(this)
}

class Load(val address: Int) extends Instruction {
  def accept(visitor: InstructionVisitor) = visitor.visitLoad(this)
}

class Store(val address: Int) extends Instruction {
  def accept(visitor: InstructionVisitor) = visitor.visitStore(this)
}

class If(subInstructions: Program) extends Instruction {
  def accept(visitor: InstructionVisitor): Unit = {
    visitor.visitIf(this)
    subInstructions.accept(visitor)
    visitor.endVisitIf(this)
  }
}

object Halt extends Instruction {
  def accept(visitor: InstructionVisitor) = visitor.visitHalt(this)
}
```

En el video (Scala 2) se escribía `def accept(visitor: InstructionVisitor)` en el trait, sin `: Unit`, y `def accept(visitor: InstructionVisitor) { … }` en `Program` y en `If`, sin `: Unit =`. `Program` recibía `Seq[Instruction]`.

### `src/main/scala/tadp/microprocesador/objetos/visitor/Visitors.scala`

**Visitor: las operaciones.** `InstructionVisitor` con un `visitXxx` por tipo de instrucción, y los tres visitors concretos: `RunVisitor` (ejecuta, con un flag para saltear el cuerpo del `If`), `PrintVisitor` (acumula el texto) y `SimplifyVisitor` (una pila de listas, cuatro flags y la última dirección escrita).

```scala
package tadp.microprocesador.objetos.visitor

import tadp.microprocesador.objetos.Micro
import tadp.microprocesador.objetos.ExecutionHaltException
import scala.collection.mutable.ListBuffer
import scala.collection.mutable.Stack

trait InstructionVisitor {
  def visitProgram(program: Program) = program.accept(this)
  def visitInstruction(instruction: Instruction) = instruction.accept(this)

  def visitAdd(instruction: Add.type): Unit
  def visitMul(instruction: Mul.type): Unit
  def visitSwap(instruction: Swap.type): Unit
  def visitLoad(instruction: Load): Unit
  def visitStore(instruction: Store): Unit
  def visitIf(instruction: If): Unit
  def endVisitIf(instruction: If): Unit
  def visitHalt(instruction: Halt.type): Unit
}

// ---------------------------------------------------------------------------------------------------------------------------------
// RUN
// ---------------------------------------------------------------------------------------------------------------------------------

class RunVisitor(micro: Micro) extends InstructionVisitor {
  private var ignoreInstructions = false

  override def visitInstruction(instruction: Instruction) = if(!ignoreInstructions) super.visitInstruction(instruction)

  def visitAdd(instruction: Add.type): Unit = {
    micro.a = micro.a + micro.b
  }

  def visitMul(instruction: Mul.type): Unit = {
    micro.a = micro.a * micro.b
  }

  def visitSwap(instruction: Swap.type): Unit = {
    val temp = micro.a
    micro.a = micro.b
    micro.b = temp
  }

  def visitLoad(instruction: Load): Unit = {
    micro.a = micro.mem(instruction.address)
  }

  def visitStore(instruction: Store): Unit = {
    micro.mem(instruction.address) = micro.a
  }

  def visitIf(instruction: If): Unit = {
    if (micro.a != 0) ignoreInstructions = true
  }

  def endVisitIf(instruction: If): Unit = {
    ignoreInstructions = false
  }

  def visitHalt(instruction: Halt.type): Unit = {
    throw new ExecutionHaltException
  }
}

// ---------------------------------------------------------------------------------------------------------------------------------
// PRINT
// ---------------------------------------------------------------------------------------------------------------------------------

class PrintVisitor extends InstructionVisitor {
  private var text = ""

  private def addText(s: String) = text += (if(text.isEmpty || text.endsWith("[")) "" else ", ") + s

  def visitAdd(instruction: Add.type) = addText("ADD")

  def visitMul(instruction: Mul.type) = addText("MUL")

  def visitSwap(instruction: Swap.type) = addText("SWP")

  def visitLoad(instruction: Load) = addText(s"LOD[${instruction.address}]")

  def visitStore(instruction: Store) = addText(s"STR[${instruction.address}]")

  def visitIf(instruction: If) = addText("IF[")

  def endVisitIf(instruction: If) = text += "]"

  def visitHalt(instruction: Halt.type)  = addText("HLT")

  def result = text
}


// ---------------------------------------------------------------------------------------------------------------------------------
// SIMPLIFY
// ---------------------------------------------------------------------------------------------------------------------------------

class SimplifyVisitor() extends InstructionVisitor {
  private var simplified = Stack(ListBuffer[Instruction]())
  private var justVisitedSwap = false
  private var justLoadedA = false
  private var justWroteMem = false
  private var lastWroteMemAddress = 0
  private var visitedHalt = false

  override def visitInstruction(instruction: Instruction) = if(!visitedHalt) super.visitInstruction(instruction)

  def visitAdd(instruction: Add.type): Unit = {
    simplified.top += instruction

    justVisitedSwap = false
    justLoadedA = false
    justWroteMem = false
  }

  def visitMul(instruction: Mul.type): Unit = {
    simplified.top += instruction

    justVisitedSwap = false
    justLoadedA = false
    justWroteMem = false
  }

  def visitSwap(instruction: Swap.type): Unit = {
    if(justVisitedSwap){
      simplified.top.dropRightInPlace(1)
      justVisitedSwap = false
    } else {
      simplified.top += instruction
      justVisitedSwap = true
    }

    justLoadedA = false
    justWroteMem = false
  }

  def visitLoad(instruction: Load): Unit = {
    if(justLoadedA) simplified.top.dropRightInPlace(1)

    simplified.top += instruction

    justVisitedSwap = false
    justWroteMem = false
    justLoadedA = true
  }

  def visitStore(instruction: Store): Unit = {
    if(justWroteMem && lastWroteMemAddress == instruction.address) simplified.top.dropRightInPlace(1)

    simplified.top += instruction

    justVisitedSwap = false
    justWroteMem = true
    lastWroteMemAddress = instruction.address
    justLoadedA = false
  }

  def visitIf(instruction: If): Unit = {
    simplified.push(ListBuffer[Instruction]())

    justVisitedSwap = false
    justWroteMem = false
    justLoadedA = false
  }

  def endVisitIf(instruction: If): Unit = {
    val subInstructions = simplified.pop()
    if(subInstructions.nonEmpty) simplified.top += new If(new Program(subInstructions))

    justVisitedSwap = false
    justWroteMem = false
    justLoadedA = false
    visitedHalt = false
  }

  def visitHalt(instruction: Halt.type): Unit = {
    simplified.top += instruction

    visitedHalt = true
  }

  def result = new Program(simplified.top)
}
```

En el video (Scala 2) las declaraciones de `InstructionVisitor` iban sin tipo (`def visitAdd(instruction: Add.type)`), y los métodos de `RunVisitor` y `SimplifyVisitor` se escribían `def visitAdd(instruction: Add.type) { … }`, sin `: Unit =`. En el video y en el repo, `PrintVisitor` se declaraba `PrintVisitor(micro: Micro)`; en la presencial, sin parámetro.

### `src/main/scala/tadp/microprocesador/mutable/Instructions.scala`

**Las instrucciones como datos:** `sealed trait` con `case object` para las que no tienen parámetros y `case class` para las que sí.

```scala
package tadp.microprocesador.mutable

sealed trait Instruction

case object Add extends Instruction
case object Mul extends Instruction
case object Swap extends Instruction
case class Load(address: Int) extends Instruction
case class Store(address: Int) extends Instruction
case class If(subInstructions: List[Instruction]) extends Instruction
case object Halt extends Instruction
```

### `src/main/scala/tadp/microprocesador/mutable/Micro.scala`

*El mismo micro mutable de la solución de objetos (el repo lo repite en este proyecto).*

```scala
package tadp.microprocesador.mutable

class Micro {
  private val MEM_SIZE = 128
  private val REGISTER_SIZE = 1024

  private var _a: Int = _
  private var _b: Int = _
  private var _mem: Array[Int] = new Array(MEM_SIZE)

  def a = _a
  def a_=(value: Int): Unit = {
    require(value < REGISTER_SIZE && value > -REGISTER_SIZE)
    _a = value
  }

  def b = _b
  def b_=(value: Int): Unit = {
    require(value < REGISTER_SIZE && value > -REGISTER_SIZE)
    _b = value
  }

  def mem = _mem
}
```

### `src/main/scala/tadp/microprocesador/mutable/Operations.scala`

**Pattern matching con el micro mutable.** Las tres operaciones son funciones afuera de las instrucciones: `run` modifica el micro que recibe, `print` arma el texto con `map` + `mkString`, y `simplify` matchea sobre la forma de la lista entera (`Swap :: Swap :: resto`, guardas con `if`, `_`).

```scala
package tadp.microprocesador.mutable

package object Operations {

  type Program = List[Instruction]
  class ExecutionHaltException extends RuntimeException

  // ---------------------------------------------------------------------------------------------------------------------------------
  // RUN
  // ---------------------------------------------------------------------------------------------------------------------------------

  def run(program: Program, micro: Micro): Unit = {
    for (instruction <- program)
      instruction match {
        case Add => micro.a = micro.a + micro.b
        case Mul => micro.a = micro.a * micro.b
        case Swap =>
          val temp = micro.a
          micro.a = micro.b
          micro.b = temp
        case Load(address)       => micro.a = micro.mem(address)
        case Store(address)      => micro.mem(address) = micro.a
        case If(subInstructions) => if (micro.a == 0) run(subInstructions, micro)
        case Halt                => throw new ExecutionHaltException
      }
  }

  // ---------------------------------------------------------------------------------------------------------------------------------
  // PRINT
  // ---------------------------------------------------------------------------------------------------------------------------------

  def print(program: Program): String = program.map {
    case Add                 => "ADD"
    case Mul                 => "MUL"
    case Swap                => "SWP"
    case Load(address)       => s"LOD[$address]"
    case Store(address)      => s"STR[$address]"
    case If(subInstructions) => s"IF[${print(subInstructions)}]"
    case Halt                => "HLT"
  }.mkString(", ")

  // ---------------------------------------------------------------------------------------------------------------------------------
  // SIMPLIFY
  // ---------------------------------------------------------------------------------------------------------------------------------

  def simplify(program: Program): Program = program match {
    case Nil => Nil
    case Swap :: Swap :: otherInstructions => simplify(otherInstructions)
    case Load(_) :: (load: Load) :: otherInstructions => simplify(load :: otherInstructions)
    case (s1: Store) :: (s2: Store) :: otherInstructions if s1.address == s2.address => simplify(s2 :: otherInstructions)
    case If(subInstructions) :: otherInstructions =>
      val simplifiedSubInstructions = simplify(subInstructions)
      if (simplifiedSubInstructions.isEmpty) simplify(otherInstructions) else If(simplifiedSubInstructions) :: simplify(otherInstructions)
    case Halt :: _ => Halt :: Nil
    case i :: is   => i :: simplify(is)
  }
}
```

En el video (Scala 2) se escribía `def run(program: Program, micro: Micro) { … }`, sin `: Unit =`.

### `src/main/scala/tadp/microprocesador/inmutable/Instructions.scala`

*Las mismas instrucciones de `mutable` (el repo las repite en este proyecto).*

```scala
package tadp.microprocesador.inmutable

sealed trait Instruction

case object Add extends Instruction
case object Mul extends Instruction
case object Swap extends Instruction
case class Load(address: Int) extends Instruction
case class Store(address: Int) extends Instruction
case class If(subInstructions: List[Instruction]) extends Instruction
case object Halt extends Instruction
```

### `src/main/scala/tadp/microprocesador/inmutable/Micro.scala`

**El micro inmutable:** una `case class` que valida sus invariantes al construirse (`require`) y se "modifica" con `copy`.

```scala
package tadp.microprocesador.inmutable

object Micro {
  val MEM_SIZE = 128
  val REGISTER_SIZE = 1024
}

case class Micro(a: Int, b: Int, mem: List[Int] = List.fill(Micro.MEM_SIZE)(0)) {
  require(a < Micro.REGISTER_SIZE && a > -Micro.REGISTER_SIZE)
  require(b < Micro.REGISTER_SIZE && b > -Micro.REGISTER_SIZE)
  require(mem.size == Micro.MEM_SIZE)
}
```

### `src/main/scala/tadp/microprocesador/inmutable/Operations1.scala`

**Micro inmutable, primer paso:** `run` devuelve un micro nuevo, pero todavía reasigna una variable local en cada instrucción.

```scala
package tadp.microprocesador.inmutable

package object Operations1 {

  type Program = List[Instruction]
  class ExecutionHaltException extends RuntimeException

  // ---------------------------------------------------------------------------------------------------------------------------------
  // RUN: IMMUTABLE MICRO
  // ---------------------------------------------------------------------------------------------------------------------------------

  def run(program: Program, initialMicro: Micro): Micro = {
    var micro = initialMicro

    for (instruction <- program)
      instruction match {
        case Add                 => micro = micro.copy(a = micro.a + micro.b)
        case Mul                 => micro = micro.copy(a = micro.a * micro.b)
        case Swap                => micro = micro.copy(a = micro.b, b = micro.a)
        case Load(address)       => micro = micro.copy(a = micro.mem(address))
        case Store(address)      => micro = micro.copy(mem = micro.mem.updated(address, micro.a))
        case If(subInstructions) => if (micro.a == 0) micro = run(subInstructions, micro)
        case Halt                => throw new ExecutionHaltException
      }

    micro
  }

}
```

### `src/main/scala/tadp/microprocesador/inmutable/Operations2.scala`

**Micro inmutable con `foldLeft`:** sin variable local; cada instrucción transforma el micro que le deja la anterior. `HALT` todavía lanza una excepción.

```scala
package tadp.microprocesador.inmutable

package object Operations2 {

  type Program = List[Instruction]
  class ExecutionHaltException extends RuntimeException

  // ---------------------------------------------------------------------------------------------------------------------------------
  // RUN: FOLDING
  // ---------------------------------------------------------------------------------------------------------------------------------

  def run(program: Program, initialMicro: Micro): Micro =
    program.foldLeft(initialMicro) { (micro, instruction) =>
      instruction match {
        case Add                 => micro.copy(a = micro.a + micro.b)
        case Mul                 => micro.copy(a = micro.a * micro.b)
        case Swap                => micro.copy(a = micro.b, b = micro.a)
        case Load(address)       => micro.copy(a = micro.mem(address))
        case Store(address)      => micro.copy(mem = micro.mem.updated(address, micro.a))
        case If(subInstructions) => if (micro.a == 0) run(subInstructions, micro) else micro
        case Halt                => throw new ExecutionHaltException
      }
    }

}
```

### `src/main/scala/tadp/microprocesador/inmutable/Operations3.scala`

**Sin excepciones:** `run` devuelve un `Result` (`Success`, `Halted` o `Failure`), y el `foldLeft` deja de aplicar instrucciones en cuanto el resultado es `Halted` o `Failure`.

```scala
package tadp.microprocesador.inmutable

package object Operations3 {

  type Program = List[Instruction]

  // ---------------------------------------------------------------------------------------------------------------------------------
  // RESULTS
  // ---------------------------------------------------------------------------------------------------------------------------------

  sealed trait Result { def micro: Micro }
  object Result {
    def apply(previousMicro: Micro)(micro: => Micro): Result = try {
      Success(micro)
    } catch {
      case error: Exception => Failure(previousMicro, error)
    }
  }

  case class Halted(micro: Micro) extends Result
  case class Success(micro: Micro) extends Result
  case class Failure(micro: Micro, error: Exception) extends Result

  // ---------------------------------------------------------------------------------------------------------------------------------
  // RUN: AVOIDING EXCEPTIONS
  // ---------------------------------------------------------------------------------------------------------------------------------

  def run(program: Program, initialMicro: Micro): Result = {
      program.foldLeft(Success(initialMicro): Result) {
      case (previousResult: Halted, _)                            => previousResult
      case (previousResult: Failure, _)                           => previousResult
      case (Success(micro), Add)                                  => Result(micro)(micro.copy(a = micro.a + micro.b))
      case (Success(micro), Mul)                                  => Result(micro)(micro.copy(a = micro.a * micro.b))
      case (Success(micro), Swap)                                 => Result(micro)(micro.copy(a = micro.b, b = micro.a))
      case (Success(micro), Load(address))                        => Result(micro)(micro.copy(a = micro.mem(address)))
      case (Success(micro), Store(address))                       => Result(micro)(micro.copy(mem = micro.mem.updated(address, micro.a)))
      case (previousResult @ Success(micro), If(subInstructions)) => if (micro.a == 0) run(subInstructions, micro) else previousResult
      case (Success(micro), Halt)                                 => Halted(micro)
    }
  }

}
```

### `src/main/scala/tadp/figuras/Figuras.scala`

**El ejemplo de polimorfismo de subtipado de la clase.** `Figura` define el contrato (`area`); `Circulo` y `Rectangulo` lo cumplen cada uno a su manera, con atributos distintos; `imprimirArea` recibe cualquier `Figura` y le delega el cálculo.

```scala
package tadp.figuras

trait Figura {
  def area: Double
}

class Circulo(val radio: Double) extends Figura {
  def area: Double = Math.PI * radio * radio
}

class Rectangulo(val ancho: Double, val alto: Double)
  extends Figura {
  def area: Double = ancho * alto
}

def imprimirArea(figura: Figura): Unit = println(figura.area)
```

### `src/test/scala/tadp/microprocesador/MicroprocesadorTest.scala`

**AGREGADO para esta referencia: el repo de la cátedra no trae tests.** La misma batería sobre el enunciado, corrida contra cada versión.

```scala
// AGREGADO para esta referencia: el repo de la cátedra no trae tests.
// La misma batería, sobre el enunciado (ejecutar, imprimir y las cinco reglas de simplificar),
// se corre contra cada versión para mostrar que hacen lo mismo y dónde difieren.
package tadp.microprocesador

import org.scalatest.funsuite.AnyFunSuite
import org.scalatest.matchers.should.Matchers

// ---------------------------------------------------------------------------------------------------------------------------------
// OBJETOS PURO: cada instrucción sabe ejecutarse, imprimirse y simplificarse
// ---------------------------------------------------------------------------------------------------------------------------------

class ObjetosPuroTest extends AnyFunSuite with Matchers {
  import tadp.microprocesador.objetos.{Micro, ExecutionHaltException}
  import tadp.microprocesador.objetos.puro._

  def microDelEjemplo: Micro = {
    val micro = new Micro
    List(13, 39, 0, 0, 4, 8, 15, 16, 23, 0).zipWithIndex.foreach((valor, i) => micro.mem(i) = valor)
    micro
  }

  def simplificado(instructions: Instruction*): String = {
    val program = new Program(instructions)
    program.simplify
    program.print
  }

  test("ejecuta el programa del ejemplo: LOAD 0, SWAP, LOAD 1, ADD, STORE 9") {
    val micro = microDelEjemplo

    new Program(Seq(new Load(0), Swap, new Load(1), Add, new Store(9))).runOn(micro)

    micro.a shouldBe 52
    micro.b shouldBe 13
    micro.mem(9) shouldBe 52
  }

  test("IF ejecuta sus instrucciones solo si A es 0") {
    val conCero = microDelEjemplo
    val conCinco = microDelEjemplo
    conCinco.a = 5

    new Program(Seq(new If(new Program(Seq(new Load(0)))))).runOn(conCero)
    new Program(Seq(new If(new Program(Seq(new Load(0)))))).runOn(conCinco)

    conCero.a shouldBe 13
    conCinco.a shouldBe 5
  }

  test("un IF dentro de otro: el de adentro no se ejecuta y lo que sigue en el de afuera sí") {
    val micro = microDelEjemplo

    new Program(Seq(new If(new Program(Seq(new Load(0), new If(new Program(Seq(new Load(1)))), Swap))))).runOn(micro)

    micro.a shouldBe 0
    micro.b shouldBe 13
  }

  test("un IF dentro de otro: si el de afuera no se ejecuta, no se ejecuta nada de adentro") {
    val micro = microDelEjemplo
    micro.a = 5

    new Program(Seq(new If(new Program(Seq(new Load(0), new If(new Program(Seq(new Load(1)))), Swap))))).runOn(micro)

    micro.a shouldBe 5
    micro.b shouldBe 0
  }

  test("HALT detiene la ejecución con una excepción, después de lo anterior") {
    val micro = microDelEjemplo

    intercept[ExecutionHaltException] {
      new Program(Seq(new Load(0), Halt, new Load(1))).runOn(micro)
    }

    micro.a shouldBe 13
  }

  test("un registro no acepta valores fuera de rango") {
    val micro = new Micro
    micro.mem(0) = 1000
    micro.mem(1) = 1000

    intercept[IllegalArgumentException] {
      new Program(Seq(new Load(0), Swap, new Load(1), Add)).runOn(micro)
    }
  }

  test("imprime cada instrucción separada por comas, con sus parámetros entre corchetes") {
    val program = new Program(Seq(new Load(0), Swap, Add, Mul, new Store(1), new If(new Program(Seq(new Load(2), new If(new Program(Seq(Add)))))), Halt))

    program.print shouldBe "LOD[0], SWP, ADD, MUL, STR[1], IF[LOD[2], IF[ADD]], HLT"
  }

  test("simplifica el programa del ejemplo") {
    simplificado(new Load(0), new Load(0), Swap, Swap, Swap, new Store(1), new Store(1)) shouldBe "LOD[0], SWP, STR[1]"
  }

  test("dos SWAP seguidos se eliminan") {
    simplificado(Add, Swap, Swap, Mul) shouldBe "ADD, MUL"
  }

  test("de dos LOAD seguidos se elimina el primero") {
    simplificado(Add, new Load(0), new Load(1), Mul) shouldBe "ADD, LOD[1], MUL"
  }

  test("de dos STORE seguidos en la misma dirección se elimina el primero; en distinta, quedan los dos") {
    simplificado(new Store(2), new Store(2), Add) shouldBe "STR[2], ADD"
    simplificado(new Store(2), new Store(3), Add) shouldBe "STR[2], STR[3], ADD"
  }

  test("un IF sin instrucciones, o que queda sin instrucciones al simplificarlo, se elimina") {
    simplificado(new If(new Program(Seq())), Add) shouldBe "ADD"
    simplificado(Add, new If(new Program(Seq(Swap, Swap)))) shouldBe "ADD"
  }

  test("se eliminan todas las instrucciones posteriores a un HALT") {
    simplificado(Add, Halt, Mul, Swap) shouldBe "ADD, HLT"
  }

  test("un HALT dentro de un IF no elimina lo que sigue después del IF") {
    simplificado(new If(new Program(Seq(Halt, Add))), Mul) shouldBe "IF[HLT], MUL"
  }
}

// ---------------------------------------------------------------------------------------------------------------------------------
// OBJETOS CON VISITOR: cada operación es un visitor
// ---------------------------------------------------------------------------------------------------------------------------------

class VisitorTest extends AnyFunSuite with Matchers {
  import tadp.microprocesador.objetos.{Micro, ExecutionHaltException}
  import tadp.microprocesador.objetos.visitor._

  def microDelEjemplo: Micro = {
    val micro = new Micro
    List(13, 39, 0, 0, 4, 8, 15, 16, 23, 0).zipWithIndex.foreach((valor, i) => micro.mem(i) = valor)
    micro
  }

  def run(micro: Micro, instructions: Instruction*): Unit = new Program(instructions).accept(new RunVisitor(micro))

  def printed(program: Program): String = {
    val visitor = new PrintVisitor
    program.accept(visitor)
    visitor.result
  }

  def simplificado(instructions: Instruction*): String = {
    val visitor = new SimplifyVisitor()
    new Program(instructions).accept(visitor)
    printed(visitor.result)
  }

  test("ejecuta el programa del ejemplo: LOAD 0, SWAP, LOAD 1, ADD, STORE 9") {
    val micro = microDelEjemplo

    run(micro, new Load(0), Swap, new Load(1), Add, new Store(9))

    micro.a shouldBe 52
    micro.b shouldBe 13
    micro.mem(9) shouldBe 52
  }

  test("IF ejecuta sus instrucciones solo si A es 0") {
    val conCero = microDelEjemplo
    val conCinco = microDelEjemplo
    conCinco.a = 5

    run(conCero, new If(new Program(Seq(new Load(0)))))
    run(conCinco, new If(new Program(Seq(new Load(0)))))

    conCero.a shouldBe 13
    conCinco.a shouldBe 5
  }

  test("un IF dentro de otro: el de adentro no se ejecuta y lo que sigue en el de afuera sí") {
    val micro = microDelEjemplo

    run(micro, new If(new Program(Seq(new Load(0), new If(new Program(Seq(new Load(1)))), Swap))))

    micro.a shouldBe 0
    micro.b shouldBe 13
  }

  test("un IF dentro de otro: si el de afuera no se ejecuta, no se ejecuta nada de adentro") {
    val micro = microDelEjemplo
    micro.a = 5

    run(micro, new If(new Program(Seq(new Load(0), new If(new Program(Seq(new Load(1)))), Swap))))

    micro.a shouldBe 5
    micro.b shouldBe 0
  }

  test("HALT detiene la ejecución con una excepción, después de lo anterior") {
    val micro = microDelEjemplo

    intercept[ExecutionHaltException] {
      run(micro, new Load(0), Halt, new Load(1))
    }

    micro.a shouldBe 13
  }

  test("un registro no acepta valores fuera de rango") {
    val micro = new Micro
    micro.mem(0) = 1000
    micro.mem(1) = 1000

    intercept[IllegalArgumentException] {
      run(micro, new Load(0), Swap, new Load(1), Add)
    }
  }

  test("imprime cada instrucción separada por comas, con sus parámetros entre corchetes") {
    val program = new Program(Seq(new Load(0), Swap, Add, Mul, new Store(1), new If(new Program(Seq(new Load(2), new If(new Program(Seq(Add)))))), Halt))

    printed(program) shouldBe "LOD[0], SWP, ADD, MUL, STR[1], IF[LOD[2], IF[ADD]], HLT"
  }

  test("simplifica el programa del ejemplo") {
    simplificado(new Load(0), new Load(0), Swap, Swap, Swap, new Store(1), new Store(1)) shouldBe "LOD[0], SWP, STR[1]"
  }

  test("dos SWAP seguidos se eliminan") {
    simplificado(Add, Swap, Swap, Mul) shouldBe "ADD, MUL"
  }

  test("de dos LOAD seguidos se elimina el primero") {
    simplificado(Add, new Load(0), new Load(1), Mul) shouldBe "ADD, LOD[1], MUL"
  }

  test("de dos STORE seguidos en la misma dirección se elimina el primero; en distinta, quedan los dos") {
    simplificado(new Store(2), new Store(2), Add) shouldBe "STR[2], ADD"
    simplificado(new Store(2), new Store(3), Add) shouldBe "STR[2], STR[3], ADD"
  }

  test("un IF sin instrucciones, o que queda sin instrucciones al simplificarlo, se elimina") {
    simplificado(new If(new Program(Seq())), Add) shouldBe "ADD"
    simplificado(Add, new If(new Program(Seq(Swap, Swap)))) shouldBe "ADD"
  }

  test("se eliminan todas las instrucciones posteriores a un HALT") {
    simplificado(Add, Halt, Mul, Swap) shouldBe "ADD, HLT"
  }

  test("un HALT dentro de un IF no elimina lo que sigue después del IF") {
    simplificado(new If(new Program(Seq(Halt, Add))), Mul) shouldBe "IF[HLT], MUL"
  }
}

// ---------------------------------------------------------------------------------------------------------------------------------
// FUNCIONAL MUTABLE: case classes y pattern matching, con el micro mutable
// ---------------------------------------------------------------------------------------------------------------------------------

class FuncionalMutableTest extends AnyFunSuite with Matchers {
  import tadp.microprocesador.mutable._

  def microDelEjemplo: Micro = {
    val micro = new Micro
    List(13, 39, 0, 0, 4, 8, 15, 16, 23, 0).zipWithIndex.foreach((valor, i) => micro.mem(i) = valor)
    micro
  }

  test("ejecuta el programa del ejemplo: LOAD 0, SWAP, LOAD 1, ADD, STORE 9") {
    val micro = microDelEjemplo

    Operations.run(List(Load(0), Swap, Load(1), Add, Store(9)), micro)

    micro.a shouldBe 52
    micro.b shouldBe 13
    micro.mem(9) shouldBe 52
  }

  test("IF ejecuta sus instrucciones solo si A es 0") {
    val conCero = microDelEjemplo
    val conCinco = microDelEjemplo
    conCinco.a = 5

    Operations.run(List(If(List(Load(0)))), conCero)
    Operations.run(List(If(List(Load(0)))), conCinco)

    conCero.a shouldBe 13
    conCinco.a shouldBe 5
  }

  test("un IF dentro de otro: el de adentro no se ejecuta y lo que sigue en el de afuera sí") {
    val micro = microDelEjemplo

    Operations.run(List(If(List(Load(0), If(List(Load(1))), Swap))), micro)

    micro.a shouldBe 0
    micro.b shouldBe 13
  }

  test("un IF dentro de otro: si el de afuera no se ejecuta, no se ejecuta nada de adentro") {
    val micro = microDelEjemplo
    micro.a = 5

    Operations.run(List(If(List(Load(0), If(List(Load(1))), Swap))), micro)

    micro.a shouldBe 5
    micro.b shouldBe 0
  }

  test("HALT detiene la ejecución con una excepción, después de lo anterior") {
    val micro = microDelEjemplo

    intercept[Operations.ExecutionHaltException] {
      Operations.run(List(Load(0), Halt, Load(1)), micro)
    }

    micro.a shouldBe 13
  }

  test("un registro no acepta valores fuera de rango") {
    val micro = new Micro
    micro.mem(0) = 1000
    micro.mem(1) = 1000

    intercept[IllegalArgumentException] {
      Operations.run(List(Load(0), Swap, Load(1), Add), micro)
    }
  }

  test("imprime cada instrucción separada por comas, con sus parámetros entre corchetes") {
    Operations.print(List(Load(0), Swap, Add, Mul, Store(1), If(List(Load(2), If(List(Add)))), Halt)) shouldBe
      "LOD[0], SWP, ADD, MUL, STR[1], IF[LOD[2], IF[ADD]], HLT"
  }

  test("simplifica el programa del ejemplo") {
    Operations.simplify(List(Load(0), Load(0), Swap, Swap, Swap, Store(1), Store(1))) shouldBe List(Load(0), Swap, Store(1))
  }

  test("dos SWAP seguidos se eliminan") {
    Operations.simplify(List(Add, Swap, Swap, Mul)) shouldBe List(Add, Mul)
  }

  test("de dos LOAD seguidos se elimina el primero") {
    Operations.simplify(List(Add, Load(0), Load(1), Mul)) shouldBe List(Add, Load(1), Mul)
  }

  test("de dos STORE seguidos en la misma dirección se elimina el primero; en distinta, quedan los dos") {
    Operations.simplify(List(Store(2), Store(2), Add)) shouldBe List(Store(2), Add)
    Operations.simplify(List(Store(2), Store(3), Add)) shouldBe List(Store(2), Store(3), Add)
  }

  test("un IF sin instrucciones, o que queda sin instrucciones al simplificarlo, se elimina") {
    Operations.simplify(List(If(Nil), Add)) shouldBe List(Add)
    Operations.simplify(List(Add, If(List(Swap, Swap)))) shouldBe List(Add)
  }

  test("se eliminan todas las instrucciones posteriores a un HALT") {
    Operations.simplify(List(Add, Halt, Mul, Swap)) shouldBe List(Add, Halt)
  }

  test("un HALT dentro de un IF no elimina lo que sigue después del IF") {
    Operations.simplify(List(If(List(Halt, Add)), Mul)) shouldBe List(If(List(Halt)), Mul)
  }
}

// ---------------------------------------------------------------------------------------------------------------------------------
// FUNCIONAL INMUTABLE: el micro es una case class y run devuelve un micro nuevo
// ---------------------------------------------------------------------------------------------------------------------------------

class FuncionalInmutableTest extends AnyFunSuite with Matchers {
  import tadp.microprocesador.inmutable._

  val microDelEjemplo: Micro = Micro(0, 0, List(13, 39, 0, 0, 4, 8, 15, 16, 23, 0) ++ List.fill(118)(0))

  val programaDelEjemplo: List[Instruction] = List(Load(0), Swap, Load(1), Add, Store(9))

  test("un micro sin memoria explícita arranca con 128 posiciones en 0") {
    Micro(0, 0).mem.size shouldBe 128
    Micro(0, 0).mem.forall(_ == 0) shouldBe true
  }

  test("un micro no acepta registros fuera de rango") {
    intercept[IllegalArgumentException] {
      Micro(1024, 0)
    }
  }

  test("Operations1, Operations2 y Operations3 ejecutan el programa del ejemplo y dejan el micro original igual") {
    val conVariable = Operations1.run(programaDelEjemplo, microDelEjemplo)
    val conFold = Operations2.run(programaDelEjemplo, microDelEjemplo)
    val conResult = Operations3.run(programaDelEjemplo, microDelEjemplo)

    (conVariable.a, conVariable.b, conVariable.mem(9)) shouldBe (52, 13, 52)
    conFold shouldBe conVariable
    conResult shouldBe Operations3.Success(conVariable)
    microDelEjemplo.a shouldBe 0
    microDelEjemplo.mem(9) shouldBe 0
  }

  test("IF ejecuta sus instrucciones solo si A es 0, en las tres versiones") {
    val programa = List(If(List(Load(0))))
    val conCinco = microDelEjemplo.copy(a = 5)

    Operations1.run(programa, microDelEjemplo).a shouldBe 13
    Operations2.run(programa, microDelEjemplo).a shouldBe 13
    Operations3.run(programa, microDelEjemplo).micro.a shouldBe 13
    Operations1.run(programa, conCinco).a shouldBe 5
    Operations2.run(programa, conCinco).a shouldBe 5
    Operations3.run(programa, conCinco).micro.a shouldBe 5
  }

  test("un IF dentro de otro: el de adentro no se ejecuta y lo que sigue en el de afuera sí") {
    val programa = List(If(List(Load(0), If(List(Load(1))), Swap)))

    Operations1.run(programa, microDelEjemplo).b shouldBe 13
    Operations2.run(programa, microDelEjemplo).b shouldBe 13
    Operations3.run(programa, microDelEjemplo).micro.b shouldBe 13
  }

  test("un IF dentro de otro: si el de afuera no se ejecuta, no se ejecuta nada de adentro") {
    val programa = List(If(List(Load(0), If(List(Load(1))), Swap)))
    val conCinco = microDelEjemplo.copy(a = 5)

    Operations1.run(programa, conCinco) shouldBe conCinco
    Operations2.run(programa, conCinco) shouldBe conCinco
    Operations3.run(programa, conCinco) shouldBe Operations3.Success(conCinco)
  }

  test("Operations1 y Operations2 detienen la ejecución con una excepción") {
    intercept[Operations1.ExecutionHaltException] {
      Operations1.run(List(Load(0), Halt, Load(1)), microDelEjemplo)
    }
    intercept[Operations2.ExecutionHaltException] {
      Operations2.run(List(Load(0), Halt, Load(1)), microDelEjemplo)
    }
  }

  test("Operations3 devuelve Halted con el micro del momento del HALT, sin excepción") {
    Operations3.run(List(Load(0), Halt, Load(1)), microDelEjemplo) shouldBe Operations3.Halted(microDelEjemplo.copy(a = 13))
  }

  test("Operations3: un HALT dentro de un IF que se ejecuta detiene todo el programa") {
    Operations3.run(List(If(List(Load(0), Halt)), Load(1)), microDelEjemplo) shouldBe Operations3.Halted(microDelEjemplo.copy(a = 13))
  }

  test("Operations3 devuelve Failure con el último micro válido cuando una instrucción falla") {
    val conMil = microDelEjemplo.copy(mem = microDelEjemplo.mem.updated(0, 1000).updated(1, 1000))

    Operations3.run(List(Load(0), Swap, Load(1), Add, Load(2)), conMil) match {
      case Operations3.Failure(micro, error) =>
        (micro.a, micro.b) shouldBe (1000, 1000)
        error.isInstanceOf[IllegalArgumentException] shouldBe true
      case otro => throw new AssertionError(s"se esperaba Failure y salió $otro")
    }

    Operations3.run(List(Load(500)), microDelEjemplo) match {
      case Operations3.Failure(micro, error) =>
        micro shouldBe microDelEjemplo
        error.isInstanceOf[IndexOutOfBoundsException] shouldBe true
      case otro => throw new AssertionError(s"se esperaba Failure y salió $otro")
    }
  }
}
```

### `src/test/scala/tadp/figuras/FigurasTest.scala`

**AGREGADO para esta referencia: el ejemplo de la clase no trae tests.** Dos tests sobre el ejemplo de figuras.

```scala
// AGREGADO para esta referencia: el ejemplo de la clase no trae tests.
package tadp.figuras

import org.scalatest.funsuite.AnyFunSuite
import org.scalatest.matchers.should.Matchers

class FigurasTest extends AnyFunSuite with Matchers {

  test("cada figura calcula su área a su manera") {
    new Rectangulo(3, 4).area shouldBe 12.0
    new Circulo(1).area shouldBe Math.PI
  }

  test("imprimirArea trata a cualquier figura de la misma forma") {
    val salida: java.io.ByteArrayOutputStream = new java.io.ByteArrayOutputStream()

    Console.withOut(salida) {
      List(new Rectangulo(3, 4), new Circulo(1)).foreach(imprimirArea)
    }

    salida.toString.split("\\R").toList shouldBe List("12.0", Math.PI.toString)
  }
}
```

---

**FIN DEL ARCHIVO — Código final unificado — clase09 — Pattern matching y case classes (Microprocesador)**
