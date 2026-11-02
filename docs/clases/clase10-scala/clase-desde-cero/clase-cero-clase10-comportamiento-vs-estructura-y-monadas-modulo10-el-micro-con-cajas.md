# Clase desde cero — Comportamiento vs estructura y mónadas — Módulo 10: El micro con cajas

**Unidad:** clase10 · **Lenguaje:** Scala 3.3.1 · **Archivos del proyecto:** `monadas/Operations1.scala` a `Operations4.scala` (más `monadas/Micro.scala` e `Instructions.scala`, y el test `MonadasTest`) · **Densidad:** 🔴 pide una sesión con el código abierto (la sección 6 es 🟡); es donde todo lo anterior se junta sobre el código del TP

---

## Sobre este documento

**Qué cubre.** La vuelta al micro con todo lo de los módulos anteriores. De dónde se parte (el `Result` con sus tres formas, que se quedó a medio camino); `map` y `flatMap` sobre `Result`, por qué son triviales, y por qué `Result` es una pseudocaja y no una mónada; el `run` con `map` por instrucción y `flatMap` para `If` y `Halt`; el mismo `run` con `for`, y una trampa en el `If`; `Try[Micro]` en lugar de `Result`: se borra el `Result` y el código de las instrucciones no cambia; el `Halt` como una excepción adentro de un `Try`; qué se pierde y qué se gana; los trade-offs del camino entero (pattern matching contra polimorfismo, inmutabilidad, `Try` contra excepciones); y qué se espera para el TP.

**Qué no cubre.** Las demás cajas (`Future`, `Either`, IO) y lo que pasa cuando se cruzan: Módulo 11.

## De dónde venís

Del Módulo 8: `Try`, `Success`/`Failure`, `Try { … }` por nombre, `recover`. Del Módulo 9: el `for` y su traducción (`<-` es `flatMap`/`map`, `yield` mete en la caja). Del Módulo 6: `unit` y `bind`, y que Scala no nombra el contrato. Del Módulo 7: el pipeline, y que hacer pattern matching sobre una caja es volver al nivel 1. De la unidad anterior: el micro inmutable (`case class Micro` con `require` y `copy`), las instrucciones como `case class`/`case object`, el `run` con `foldLeft`, y el `Result` con sus tres formas (`Success`, `Halted`, `Failure`) y su `apply` por nombre.

---

## 1. 🔴 Dónde quedó el micro: a medio camino

> El `run` ya devolvía un `Result` (éxito, detenido o fallo) en vez de explotar, y eso era **la estructura de una caja sin sus operaciones**: cada paso del `foldLeft` preguntaba con pattern matching qué forma tenía el resultado anterior. Lo que falta es lo que esta unidad enseñó: `map` y `flatMap`, para que el `run` hable solo del camino feliz.

Así quedó el `run` al final de la unidad anterior (`inmutable/Operations3`, en el proyecto de esa unidad):

```scala
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
```

Mirá lo que hace cada `case`: pregunta por la forma del resultado anterior **y** por la instrucción. Las dos primeras líneas dicen "si ya se detuvo o ya falló, no hagas nada"; las siguientes dicen "si venís bien, hacé esto". Es el `case Nil` del Módulo 2, el `if (x != null)` del Módulo 7 y el `try`/`catch` del Módulo 8, una vez más: la pregunta "¿esto salió como esperaba?" escrita a mano en cada paso.

Y ya sabés qué pasó ahí: se programó la **estructura** de una caja (tres formas: un éxito, un detenido, un fallo) y se la usó con pattern matching, sin programar nunca **las operaciones por encima**. Es exactamente la idea del `Try`, a medio camino. Se armó la caja, y faltó el contrato.

Vale aclararlo: `try`, `catch` y `throw` son herramientas útiles y siguen en la caja. Lo que pasa es que hay dos cosas que pueden cortar un `run`: el `HALT`, y los `require` del micro, que pueden lanzar en cualquier `ADD` o `LOAD` que deje un registro fuera de rango o pida una posición que no existe. La unidad anterior ya las encajonó (`Halted` y `Result.apply`); lo que falta es que la caja sepa operar sola con ellas. Eso es el "comportamiento" del título de la unidad.

Lo que esta unidad agrega es que las operaciones son triviales, y que con ellas el `run` cambia de forma: deja de preguntar y describe solo el camino feliz. Y que, al final, ni siquiera hace falta programar la caja, porque ya existe.

## 2. 🔴 `map` y `flatMap` sobre `Result`: triviales

> `Success.map` aplica la función al micro y envuelve el resultado; `Success.flatMap` aplica una función que ya devuelve un `Result`. **`Halted` y `Failure` se devuelven a sí mismos** en las dos operaciones: cuando ya se detuvo o ya falló, no hay nada más que hacer. Con eso, mientras encadenes `map` y `flatMap`, solo se ejecuta algo si venís bien.

En el proyecto, `monadas/Operations1`, la parte de `Result`:

```scala
package tadp.microprocesador.monadas

package object Operations1 {

  type Program = List[Instruction]

  object Result {
    def apply(previousMicro: Micro)(micro: => Micro): Result = try {
      Success(micro)
    } catch {
      case error: Exception => Failure(previousMicro, error)   // guarda el último micro válido, no el que falló
    }
  }
  sealed trait Result {
    def micro: Micro
    def map(f: Micro => Micro): Result
    def flatMap(f: Micro => Result): Result
  }

  case class Success(micro: Micro) extends Result {
    def map(f: Micro => Micro) = Result(micro)(f(micro))
    def flatMap(f: Micro => Result) = f(micro)
  }

  case class Halted(micro: Micro) extends Result {
    def map(f: Micro => Micro) = this
    def flatMap(f: Micro => Result) = this
  }

  case class Failure(micro: Micro, error: Exception) extends Result {
    def map(f: Micro => Micro) = this
    def flatMap(f: Micro => Result) = this
  }
```

Leé las firmas primero. `map` recibe una función de micro en micro; `flatMap`, una de micro en `Result`. Las dos devuelven un `Result` nuevo. Es el contrato del Módulo 6 con `T` fijado en `Micro`: `map` para cuando la operación devuelve micros, `flatMap` para cuando ya devuelve un resultado. (Por el Módulo 6, con `flatMap` y `Result.apply` alcanzaría para escribir `map`; acá se escriben los dos a mano porque la versión es la más básica posible, y se lee mejor así.) Y `Result.apply` hace de `unit`: recibe el micro **por nombre**, lo evalúa adentro de un `try`, y si construirlo lanza (un `require` del micro que no se cumple, una posición de memoria que no existe) devuelve un `Failure` con la excepción y con el último micro válido. (Esa segunda cosa, `previousMicro`, es el arreglo de la trampa de la unidad anterior: el `apply` que volvía a evaluar el micro en el `catch` y lanzaba de nuevo.)

Ahora las implementaciones, que son una estupidez, en el buen sentido. `Success` tiene el micro y viene bien: `map` aplica la función y mete el resultado en un `Result` nuevo (que puede salir `Failure`, si la función explotó); `flatMap` aplica la función y lo que devuelve **es** el resultado. `Halted` y `Failure` están implementados igual, porque representan lo mismo: hay que detener la computación, sea porque alguien pidió `HALT` o porque el micro trató de ponerse en un estado inválido. Mapear un detenido es devolver el mismo detenido, con el micro en el estado en que estaba cuando se detuvo. Lo mismo para el fallo.

(Para mirar qué forma tiene un resultado, acá se usa `getClass.getSimpleName`, que es solo para el worksheet. En código de verdad, lo que hacés con un `Result` es seguir mapeando, o abrirlo al final con lo que la caja te dé.)

```scala
import tadp.microprocesador.monadas._
import Operations1._

val m = Micro(1, 2)
val bien: Result = Success(m)

bien.map(micro => micro.copy(a = micro.a + micro.b)).micro.a                // Resultado: 3
bien.flatMap(micro => Halted(micro)).getClass.getSimpleName               // Resultado: Halted
Halted(m).map(micro => micro.copy(a = 99)).micro.a                          // Resultado: 1       no hizo nada
bien.map(micro => micro.copy(a = 5000)).getClass.getSimpleName            // Resultado: Failure  el require del micro falló; map lo atrapó
bien.map(micro => micro.copy(a = 5000)).micro.a                             // Resultado: 1       el Failure guarda el último micro válido
```

Como `map` y `flatMap` de `Halted` y `Failure` no hacen nada, **el único que hace algo es el caso exitoso**: mientras encadenes llamados, se van a ejecutar siempre y cuando el resultado venga siendo un éxito. Es la caja vacía del Módulo 7 que viaja hasta el final, con dos formas de "vacía".

Una cosa más: `Result` **no es genérico**. Es `Result`, no `Result[T]`; todos los resultados tienen un micro adentro, y nada más. Para ser una mónada de verdad tendría que ser una caja de cualquier cosa. Es una **pseudocaja**: algo mucho más específico y más sencillo, que sabe hacer `map` y `flatMap` sobre micros, y alcanza para lo que sigue.

## 3. 🔴 El `run` con `map` y `flatMap`

> El `run` deja de preguntar. Arranca de un éxito (el micro inicial no tiene por qué fallar) y, por cada instrucción, **mapea el resultado anterior** con la misma operación de siempre: dado el micro, hacé la copia. `If` y `Halt` usan `flatMap`, porque lo que devuelven ya es un `Result`.

```scala
  def run(program: Program, initialMicro: Micro): Result = {
    program.foldLeft(Success(initialMicro): Result) { (previousResult, instruction) =>
      instruction match {
        case Add =>
          previousResult.map(micro => micro.copy(a = micro.a + micro.b))
        case Mul =>
          previousResult.map(micro => micro.copy(a = micro.a * micro.b))
        case Swap =>
          previousResult.map(micro => micro.copy(a = micro.b, b = micro.a))
        case Load(address) =>
          previousResult.map(micro => micro.copy(a = micro.mem(address)))
        case Store(address) =>
          previousResult.map(micro => micro.copy(mem = micro.mem.updated(address, micro.a)))
        case If(subInstructions) =>
          previousResult.flatMap(micro =>
            if (micro.a == 0) run(subInstructions, micro)
            else previousResult
          )
        case Halt =>
          previousResult.flatMap(micro => Halted(micro))
      }
    }
  }
}
```

Compará con la sección 1. El `foldLeft` ya no foldea un micro: foldea un **resultado**. Las dos primeras líneas (`Halted`, `Failure`) desaparecieron: ya no hace falta preguntar si el anterior se detuvo o falló, porque si pasó eso, el `map` no va a hacer nada y va a devolver el mismo resultado. Cada instrucción simple es `previousResult.map(micro => micro.copy(…))`: **la misma operación que tenías antes**, aplicada al contenido de la caja. Y el `match` que queda es sobre la instrucción, que es un dato con siete formas: ese pattern matching es el correcto.

Y hay una segunda ganancia, que es la que importa para lo que viene: si mañana `Result` tiene cuatro formas en vez de tres, o dos, el `run` no se entera, porque solo habla con `map` y `flatMap`. Con el pattern matching sobre el par, cada forma nueva era un `case` nuevo en cada paso.

`If` y `Halt` usan `flatMap`. En el `If`, `run` sobre las subinstrucciones ya devuelve un `Result`, así que no hay que mapear y preocuparse por cómo combinar: si el micro está en el estado en que hay que ejecutar las subinstrucciones, se corren sobre ese micro; si no, se devuelve el resultado previo tal cual. En el `Halt`, `flatMap` es la forma de **elegir qué forma tiene el resultado de ahora en más**: "de este punto en adelante, tu estado ya no es `Success`, es `Halted`". Es el único lugar donde el código decide el tipo de caja.

Con el micro y el programa del ejemplo de la unidad anterior (memoria con `13, 39, 0, 0, 4, 8, 15, 16, 23, 0` al principio; `LOD[0], SWP, LOD[1], ADD, STR[9]`):

```scala
val microDelEjemplo = Micro(0, 0, List(13, 39, 0, 0, 4, 8, 15, 16, 23, 0) ++ List.fill(118)(0))
val programaDelEjemplo = List(Load(0), Swap, Load(1), Add, Store(9))

val r1 = Operations1.run(programaDelEjemplo, microDelEjemplo)
(r1.getClass.getSimpleName, r1.micro.a, r1.micro.b, r1.micro.mem(9))        // Resultado: (Success,52,13,52)

val r2 = Operations1.run(List(Load(0), Halt, Load(1)), microDelEjemplo)
(r2.getClass.getSimpleName, r2.micro.a)                                     // Resultado: (Halted,13)      el LOD[1] no se ejecutó

val r3 = Operations1.run(List(Add, Mul), Micro(1000, 1000))
(r3.getClass.getSimpleName, r3.micro.a, r3.micro.b)                         // Resultado: (Failure,1000,1000)   el require falló en el ADD; el micro es el último válido

val r4 = Operations1.run(List(Load(500)), microDelEjemplo)
r4.getClass.getSimpleName                                                   // Resultado: Failure          la posición 500 no existe
```

Este `run` ya no lanza excepciones: siempre devuelve un resultado, de la forma correcta, que ya sabe mapearse. Si el `ADD` deja el registro fuera de rango, el `require` lanza, `Result.apply` lo atrapa, sale un `Failure`, y todas las instrucciones que siguen pasan de largo. Es una construcción mucho más pura, con la misma lógica de instrucciones.

(El test del proyecto, `MonadasTest`, mira la forma con `match`: un test existe para afirmar qué forma salió, y ese es el único lugar donde abrir la caja a mano está justificado.)

## 4. 🔴 El mismo `run` con `for`

> Con la misma definición de `Result`, cada instrucción se puede escribir con `for`: *del resultado anterior, sacá el micro; metele en la caja nueva la copia*. **Se compila a casi lo mismo**; es cuestión de gusto. Y hay una trampa en el `If`, que enseña algo.

En el proyecto, `monadas/Operations2` (el mismo `Result`; cambia solo el `run`):

```scala
  def run(program: Program, initialMicro: Micro): Result = {
    program.foldLeft(Success(initialMicro): Result) { (previousResult, instruction) =>
      instruction match {
        case Add =>
          for (micro <- previousResult)
          yield micro.copy(a = micro.a + micro.b)

        case Mul =>
          for (micro <- previousResult)
          yield micro.copy(a = micro.a * micro.b)

        case Swap =>
          for (micro <- previousResult)
          yield micro.copy(a = micro.b, b = micro.a)

        case Load(address) =>
          for (micro <- previousResult)
          yield micro.copy(a = micro.mem(address))

        case Store(address) =>
          for (micro <- previousResult)
          yield micro.copy(mem = micro.mem.updated(address, micro.a))

        case If(subInstructions) =>
          for {
            micro <- previousResult
            nextMicro <- if (micro.a == 0) run(subInstructions, micro) else Success(micro)
          } yield if (micro.a == 0) nextMicro else micro

        case Halt =>
          for {
            micro <- previousResult
            haltedMicro <- Halted(micro)
          } yield haltedMicro
      }
    }
  }
```

Leé el `Swap`: *del resultado previo, sacá un micro; lo que devuelvo, lo que va en la caja nueva, es `micro.copy(a = micro.b, b = micro.a)`*. Flechita y `yield`, las dos cosas del Módulo 9, y nada de `map`. Para las cinco instrucciones simples es un `for` de una flecha, que se traduce al `map` de la sección 3. Ganancia práctica: ninguna; se comporta igual y compila a casi lo mismo. Queda un poco más lindo, y eso es todo lo que se gana. Si te gusta más el `map`, usás el `map`; si te resulta más claro no tener que pensar si esto es un `map` o un `flatMap`, usás el `for`.

El `Halt` queda un poco más incómodo: `haltedMicro <- Halted(micro)` se lee como "sacá el micro de un `Halted` recién construido y volvé a meterlo con `yield`". En la práctica no saca nada: la traducción es `previousResult.flatMap(micro => Halted(micro).map(h => h))`, y como `Halted.map` devuelve `this` sin mirar la función, lo que sale es ese mismo `Halted`. Funciona, y se nota que el `for` está pensado para sacar y meter, y acá lo que querés es **elegir la forma** de la caja, que es un uso más extraño. Es un caso donde el `flatMap` de la sección 3 se lee mejor.

⚠️ **Trampa: el `If` que calcula antes de preguntar.** La versión original de este `If` con `for` era esta:

```scala
        case If(subInstructions) =>
          for {
            micro <- previousResult
            nextMicro <- run(subInstructions, micro)
          } yield if (micro.a == 0) nextMicro else micro
```

No es un descuido: está escrito así a propósito, con una justificación que suena bien: "puedo calcular tranquilamente las subinstrucciones antes de preocuparme por si tengo que evaluarlas; si había que ejecutarlas te devuelvo ese micro, si no el original; en términos de performance podría no ser lo mejor, se puede escribir de otra forma, pero es claro y simpático". Y el razonamiento tiene algo de cierto: con un micro inmutable, correr las subinstrucciones de más no modifica nada, así que parecería un gasto y nada más. **Pero lo que se calcula de más ya no es un micro: es un `Result`, y un `Result` puede venir `Halted` o `Failure`. Acá no es cuestión de rendimiento: es de corrección.** El `for` es una secuencia (Módulo 9): `run(subInstructions, micro)` se evalúa adentro del `flatMap`, siempre, antes de que el `yield` mire `micro.a`. Si el subprograma tiene un `HALT`, o una instrucción que falla, ese `Halted` o ese `Failure` es lo que el `flatMap` propaga, y el `yield` nunca llega a decidir. Con `a = 5` (el `IF` no debe ejecutarse) y el programa `IF[HLT], LOD[1]`, la versión original devuelve `Halted` en vez de seguir con el `LOD[1]`; con `IF[LOD[500]]` devuelve `Failure` aunque el `LOD[500]` jamás debía correr. La versión del proyecto toma la decisión en la segunda línea del `for`, antes de llamar a `run`, y la línea del `yield` queda como estaba (con la decisión ya tomada, sus dos ramas dan lo mismo). La versión con `flatMap` de la sección 3 siempre decidió primero, y nunca tuvo el problema. La misma trampa estaba en la versión con `Try` y `for` (`Operations4`): con `a = 5` e `IF[HLT], LOD[1]`, el resultado era un `Failure` con `ExecutionHaltException` en vez de seguir con el `LOD[1]`. El arreglo es el mismo, con `Try(micro)` en el `else` de la segunda línea del `for`; la sección 5 lo corre.

```scala
val conCinco = microDelEjemplo.copy(a = 5)

val r5 = Operations2.run(List(If(List(Halt)), Load(1)), conCinco)
(r5.getClass.getSimpleName, r5.micro.a)                                     // Resultado: (Success,39)    el HALT adentro del IF no corrió; el LOD[1] sí

val r6 = Operations2.run(List(If(List(Load(500)))), conCinco)
(r6.getClass.getSimpleName, r6.micro.a)                                     // Resultado: (Success,5)

Operations2.run(programaDelEjemplo, microDelEjemplo).micro.mem(9)           // Resultado: 52             lo mismo que con map y flatMap
```

## 5. 🔴 `Try[Micro]`: borrar el `Result` y no tocar nada más

> Programar `Result` fue medio tonto: **ya existe una caja bien definida que maneja la posibilidad de que algo falle**, y es `Try`. Se borra `Result`, el `run` devuelve `Try[Micro]`, y **el código de las instrucciones no cambia**, porque solo usaba el contrato. Lo único que cambia es el `Halt`: en vez de una forma propia, es una excepción adentro de un `Try`.

En el proyecto, `monadas/Operations3` (con `map` y `flatMap`) y `Operations4` (con `for`). El de `Operations3`:

```scala
package tadp.microprocesador.monadas

import scala.util.Try

package object Operations3 {

  type Program = List[Instruction]
  class ExecutionHaltException(val micro: Micro) extends RuntimeException

  def run(program: Program, initialMicro: Micro): Try[Micro] = {
    program.foldLeft(Try(initialMicro)) { (previousResult, instruction) =>
      instruction match {
        case Add =>
          previousResult.map(micro => micro.copy(a = micro.a + micro.b))

        case Mul =>
          previousResult.map(micro => micro.copy(a = micro.a * micro.b))

        case Swap =>
          previousResult.map(micro => micro.copy(a = micro.b, b = micro.a))

        case Load(address) =>
          previousResult.map(micro => micro.copy(a = micro.mem(address)))

        case Store(address) =>
          previousResult.map(micro => micro.copy(mem = micro.mem.updated(address, micro.a)))

        case If(subInstructions) =>
          previousResult.flatMap(micro =>
            if (micro.a == 0) run(subInstructions, micro)
            else previousResult
          )

        case Halt =>
          previousResult.flatMap(micro => Try(throw new ExecutionHaltException(micro)))   // el HALT: una excepción, encajonada
      }
    }
  }

}
```

Ponelo al lado de la sección 3. `Add`, `Mul`, `Swap`, `Load`, `Store`, `If`: **letra por letra iguales**. Cambió la firma (`Try[Micro]` en vez de `Result`), la semilla del `foldLeft` (`Try(initialMicro)` en vez de `Success(initialMicro)`), el `Halt`, y apareció `ExecutionHaltException`, una excepción que lleva el micro adentro (`val micro`), para que el `HALT` no lo pierda. Y se borró el bloque entero de `Result`, `Success`, `Halted` y `Failure` (casi treinta líneas), porque todo eso ya está en la biblioteca.

Por qué funciona: el código de las instrucciones hablaba solo en términos de `map` y `flatMap`. **Compartimentalizaste, y lo cerraste ahí.** Si cambiás lo que hay abajo, no importa, porque el contrato es el mismo: `Try` y `Result` no comparten ninguna interfaz, no extienden el mismo `trait`, y el código que los usa no se entera. Es el hilo que viene del Módulo 7 (listas en lugar de `Option`), del Módulo 8 (`Try` en lugar de `Option`) y ahora `Try` en lugar de `Result`. Con el `for` de `Operations4` pasa lo mismo: esa sintaxis ya sabe trabajar con cosas que son cajas, abrirlas, mirar el contenido y volver a envolver, y le da igual qué caja sea. De `Operations4` alcanza con ver lo que difiere de `Operations2`: la firma `Try[Micro]`, la semilla `Try(initialMicro)`, el `Try(micro)` en el `else` del `If`, y el `Halt`, que en vez de construir un `Halted` saca el micro de un `Try` que lanzó:

```scala
        case If(subInstructions) =>
          for {
            micro <- previousResult
            nextMicro <- if (micro.a == 0) run(subInstructions, micro) else Try(micro)
          } yield if (micro.a == 0) nextMicro else micro

        case Halt =>
          for {
            micro <- previousResult
            haltedMicro <- Try(throw new ExecutionHaltException(micro))
          } yield haltedMicro
```

Las cinco instrucciones simples son, letra por letra, las de `Operations2`.

**El `Halt` como excepción.** Antes había una forma especial de la caja, `Halted`, escrita a mano. Ahora el `HALT` es un caso particular de haber lanzado una excepción: alguien decidió interrumpir el programa, se lanza `ExecutionHaltException` con el micro de ese momento **adentro de un `Try`**, y el `Try` la atrapa y la devuelve como `Failure`. Es lo que hacía el primer `run` de todos (lanzar), pero esa excepción ya no burbujea: **viaja como valor** dentro de la caja, y el `map` de las instrucciones siguientes la pasa de largo. El hilo que el Módulo 1 dejó abierto (el `throw` del `Halt`) se cierra acá: primero se convirtió en una forma (`Halted`, con `flatMap`), y después en una excepción encajonada.

(`isFailure` pregunta si la caja es un `Failure`; `failed` da vuelta un `Try`: de un `Failure` devuelve `Success(excepción)`; con `.get` se la saca. Las dos son solo para mirar la excusa en el worksheet.)

```scala
Operations3.run(programaDelEjemplo, microDelEjemplo).map(m => (m.a, m.b, m.mem(9)))   // Resultado: Success((52,13,52))
Operations4.run(programaDelEjemplo, microDelEjemplo).map(m => (m.a, m.b, m.mem(9)))   // Resultado: Success((52,13,52))

val t2 = Operations3.run(List(Load(0), Halt, Load(1)), microDelEjemplo)
t2.isFailure                                                                            // Resultado: true
t2.recover { case e: Operations3.ExecutionHaltException => e.micro }.map(_.a)          // Resultado: Success(13)   el micro del momento del HALT viaja en la excepción

Operations3.run(List(Add, Mul), Micro(1000, 1000)).failed.get.getClass.getSimpleName   // Resultado: IllegalArgumentException
Operations4.run(List(Load(500)), microDelEjemplo).failed.get.getClass.getSimpleName    // Resultado: IndexOutOfBoundsException
Operations4.run(List(If(List(Halt)), Load(1)), conCinco).map(_.a)                      // Resultado: Success(39)
```

Fijate el `recover`: es el `catch` con mensajes del Módulo 8, usado para preguntar "si se detuvo, dame el micro con el que se detuvo". Y los dos fallos de verdad llegan con su excusa adentro, sin que nada se escape de `run`.

**Qué se pierde.** Con `Result` había tres formas; con `Try` hay dos. `Halted` era distinguible de un fallo a simple vista; ahora detenerse es un `Failure` más, y distinguirlo es mirar qué excepción trae. Y el `Failure` de `Result` guardaba **el último micro válido** en cualquier fallo (`r3` en la sección 3: el micro con `1000, 1000`); el `Failure` de `Try` guarda solo la excepción, así que cuando falla un `require` o un `Load`, el micro anterior se perdió (el del `HALT` sí viaja, porque `ExecutionHaltException` lo lleva adentro a propósito). Si el TP necesita el último estado válido ante cualquier fallo, es un dato que la excepción tiene que llevar.

**Qué se gana.** No programar la mónada. Casi treinta líneas menos, una caja probada por todo el mundo, `recover`, `getOrElse`, `fold`, `toOption` y el `for` gratis, y la certeza de que el contrato se cumple. Y es lo que la cátedra espera: usar las cajas que están, no escribirlas.

## 6. 🟡 Lo que pagó y lo que compró cada decisión

> Mirá el `run` de `Operations3` al lado de la primera solución del micro, con objetos y Visitor: **la misma tecnología, las mismas instrucciones, y dos resultados que no tienen nada que ver**, solo por cambiar la forma de pensar. Ninguna de las dos es "la mejor": cada elección pagó un precio y compró algo, y la mejor opción es siempre la mejor para este problema.

Las instrucciones son las mismas siete desde el primer paso de la unidad anterior, y las mismas `case class` desde que pasaron a ser datos; en esta unidad no se tocaron. Lo que cambió es cómo se las usa, y en cada cambio se pagó algo y se compró algo:

- **Pattern matching en lugar de polimorfismo** sobre las instrucciones: se pagó que ahora es difícil agregar instrucciones nuevas, y se compró que es fácil agregar operaciones nuevas (`run`, `print`, `simplify`, y las que vengan).
- **Inmutabilidad:** se perdió la capacidad de modificar fácilmente el estado interno de un objeto, que es una de las características clave de un objeto; se ganó seguridad sobre cómo se mantiene el estado, estados más fáciles de razonar y de paralelizar.
- **`Try` en lugar de excepciones:** se ganó poder confiar en que el resultado se obtiene siempre, y pasárselo a funciones que esperan un resultado siempre; se perdió la simplicidad del burbujeo, que requería saber menos cosas, menos construcciones, menos verbosidad, y tenía el precio de que en cualquier momento la pila se interrumpe y el flujo cambia (lo que también puede ser una herramienta).

Y la trampa de comparar. Si la herramienta te deja meter cosas que vienen de otro paradigma y te da una forma consistente de combinarlas, el resultado puede ser mucho mejor que el de cualquiera de los dos solos. La trampa es que esos resultados piden más esfuerzo para entenderlos: si te dan un código escrito con operaciones monádicas y no tenés idea de qué es un `map`, ese código te va a resultar chocante y antiintuitivo, y la forma vieja y cómoda va a parecer mejor. Hasta que no naturalizás una idea nueva, **no es justo compararla** con la que ya manejás. Todos caímos en eso alguna vez. La responsabilidad es entender la mayor cantidad de formas de trabajar posible, para elegir la que más se adecúa al problema que tenés enfrente; y la mayoría de las veces ni siquiera hay una mejor opción para un problema: hay precios y compras, y hay que elegir.

## 7. 🔴 Qué se espera para el TP

> Manejar **opcionalidad, errores y conjuntos con criterio objeto-funcional**: elegir cuándo trabajar con efecto y cuándo sin estado, cuándo algo lanza un error y cuándo lo lleva en el resultado. **Nadie espera que programen mónadas**: se espera que usen las que están, con sus operaciones. Y hacer pattern matching sobre `List`, `Option` o `Try` es usarlas mal.

Esto es lo que vuelve relevante todo lo anterior. En el TP vas a tener que tomar decisiones de este tipo, y vas a ver que hay situaciones donde hace mucha diferencia trabajar de una forma o de la otra. Un ejemplo: si querés explorar un montón de caminos, quedarte con los que tuvieron éxito y compararlos, un `Try` es mucho más cómodo que manejar errores con excepciones, frenando y volviendo en cada uno.

Las mónadas ya están programadas; son construcciones muy generales, y la cátedra no espera que escribas la tuya (el `Result` de este módulo existe para que veas cómo funciona por dentro, y después se borra). Lo que sí espera es que trabajes con **las operaciones monádicas**: `map`, `flatMap`, `filter`, el `for`, y abrir la caja al final con `fold`/`getOrElse`/`recover`. Para trabajar con pureza vas a tener que dejar de lanzar errores, y para eso está `Try`; para trabajar limpio con lo que puede no estar, está `Option`, porque si no vas a estar chequeando en cada paso si la cosa está o no está. Las dos te obligan a trabajar con orden superior, que es lo que esta mitad de la materia quiere que uses. Y lo que sabés hacer con listas (`map`, `flatMap`) es lo mismo que vas a hacer con cualquier otra caja: hay que saber generalizarlo, no aprenderlo de nuevo.

Y la regla, que cierra la trampa del Módulo 3: **el que hace pattern matching sobre una lista, sobre un `Try` o sobre un `Option`, lo está usando mal**, y en el TP va a tener que cambiarlo. En el momento en que escribís `match { case Some(x) => … case None => … }`, perdiste toda la gracia de entender esto: si te cambian lo que hay abajo, se rompe. Construí sobre el contrato. Nadie te obliga a cumplirlo (el lenguaje no te frena, como no te frenaba en ningún nivel de la escalera), pero cumplirlo es lo que después te deja trabajar mejor.

Fijate además cómo entraron estas cosas: las listas de Scala ya eran inmutables y ya sabías `map`, `filter` y `flatMap`; `Option` y `Try` usan exactamente esos mensajes. Son **caballos de Troya**: meten ideas de funcional en interfaces de objetos sin que se sienta áspero, y con solo esas tres cajas (lista, `Option`, `Try`) cambia bastante la forma de encarar un programa en objetos.

Y una propuesta, que es la de toda esta mitad de la materia: usá a propósito lo que en objetos resulta más extraño (inmutabilidad, `Option`, `Try`, pattern matching donde corresponde), aunque al principio te parezca peor, hasta naturalizarlo. Nadie espera que copies lo que la cátedra dice que conviene: la idea es que formes criterio propio, y para eso hay que haber probado las dos formas a conciencia. Una vez que estás cómodo con las dos, sos libre de elegir la que quieras.

**Para el parcial, si te preguntan:** *"¿Cómo se pasa el `run` del micro de devolver un `Result` propio a devolver un `Try[Micro]`, y qué cambia?"* `Result` era una pseudocaja (tres formas con `map` y `flatMap`, sin tipo genérico) escrita a mano, y el `run` la usaba solo a través de `map` (instrucciones simples) y `flatMap` (`If`, `Halt`). Como `Try` cumple el mismo contrato, se cambia la firma a `Try[Micro]`, la semilla del `foldLeft` a `Try(initialMicro)`, y el `Halt` pasa de devolver `Halted(micro)` a lanzar `ExecutionHaltException(micro)` adentro de un `Try`, que la atrapa como `Failure`. El código de las instrucciones no cambia. Se pierde la forma `Halted` distinguible y el último micro válido ante cualquier fallo (salvo el del `HALT`, que viaja en la excepción); se gana no programar la caja y tener `recover`, `fold`, `getOrElse` y el `for` gratis.

*"¿Por qué está mal hacer pattern matching sobre `Option` o `Try` en el TP?"* Porque es volver a la forma: preguntar a mano "¿tiene algo? ¿falló?" en cada paso, que es lo que las cajas vinieron a sacar; y porque acopla el código a esa caja en particular, cuando con `map`/`flatMap`/`for` el mismo código sirve para cualquiera. Lo correcto es encadenar con las operaciones monádicas y abrir la caja una sola vez, al final, con `fold`, `getOrElse` o `recover`.

---

## Checkpoint

1. ¿Qué tenía el `run` de la unidad anterior que lo dejaba "a medio camino"? ¿Qué le faltaba a su `Result` para ser una caja?
2. ¿Qué hace `map` sobre un `Success`? ¿Y sobre un `Halted` o un `Failure`? ¿Por qué eso alcanza para que el `run` deje de preguntar?
3. ¿Qué hace `Result.apply`? ¿Por qué recibe el micro por nombre, y qué guarda el `Failure` además de la excepción?
4. ¿Por qué `Result` es una pseudocaja y no una mónada de verdad?
5. En el `run` con `map` y `flatMap`, ¿qué instrucciones usan `map` y cuáles `flatMap`? ¿Por qué?
6. ¿Qué pattern matching queda en el `run`, y por qué ese sí es correcto?
7. ¿Qué cambia entre la versión con `map`/`flatMap` y la versión con `for`? ¿Qué se gana?
8. Explicá la trampa del `If` dentro del `for`: qué calcula de más, por qué no es solo rendimiento, y con qué programa se ve.
9. ¿Por qué el `Halt` queda incómodo escrito con `for`?
10. Al pasar a `Try[Micro]`, ¿qué líneas cambian y cuáles no? ¿Por qué el código de las instrucciones no se entera?
11. ¿Cómo se representa el `HALT` con `Try`? ¿Qué relación tiene con el `throw` del primer `run` de todos?
12. ¿Qué se pierde al pasar de `Result` a `Try`? ¿Qué se gana?
13. Nombrá las tres decisiones del camino (pattern matching, inmutabilidad, `Try`) con lo que cada uno pagó y compró.
14. ¿Por qué no es justo comparar una idea nueva con la que ya manejás?
15. ¿Qué se espera para el TP sobre opcionalidad, errores y conjuntos? ¿Qué hay que cambiar si hiciste pattern matching sobre un `Option`?

## Qué viene después

Las mismas operaciones (`map`, `flatMap`, `for`) sobre cosas que no son errores ni ausencias: algo que **todavía no está** (`Future`), algo que tiene **efecto** (IO), la caja que Haskell usa en lugar de `Try` (`Either`), y lo que pasa cuando dos cajas distintas se encuentran. Es el Módulo 11, el último: el gran elenco.

**FIN DEL MÓDULO 10 — El micro con cajas**
