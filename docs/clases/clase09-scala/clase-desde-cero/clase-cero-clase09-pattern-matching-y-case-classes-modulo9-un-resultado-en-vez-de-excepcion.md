# Clase desde cero — Pattern matching, case classes y el híbrido objeto-funcional — Módulo 9: Un resultado en vez de una excepción (puente)

**Unidad:** clase09 · **Lenguaje:** Scala 3.3.1 · **Archivo del proyecto:** `inmutable/Operations3.scala` · **Densidad:** 🟡 se lee y se entiende la idea; el detalle es tema de la clase siguiente

---

## Sobre este documento

**Qué cubre.** El último paso de la unidad hacia la pureza. Sin efecto sobre el micro, `run` todavía tiene una salida que no es un micro: la excepción del `HALT`. Juntar esas dos puntas en un solo tipo de resultado (`Success`, `Halted`, `Failure`), cómo queda `run` con eso, y qué se gana: una firma que cuenta lo que pasa, y una operación que responde en lugar de hacer.

**Qué no cubre.** La forma "bien y bonita" de trabajar con resultados así. Este código va a parecer un paso atrás, más enredado que el del Módulo 8, y es a propósito: la clase siguiente trae las herramientas para simplificarlo. Acá alcanza con entender la idea y poder leer el código.

## De dónde venís

Del Módulo 4: pureza, y el programa como viaje de un dominio a una imagen. Del Módulo 6: `sealed trait`, `case class`, patrones de tipo y de constructor. Del Módulo 7: la función anónima escrita directamente como casos (`{ case … }`). Del Módulo 8: el micro inmutable con `require`, `copy`, y `run` con `foldLeft`, que todavía lanza `ExecutionHaltException` en el `HALT`.

---

## 1. 🔴 Sin efecto no alcanza: el `throw` abre una bifurcación

> Pureza es poder pensar `run` como una **función**: de un programa y un micro inicial, a un micro final. Mientras `HALT` lance una excepción, hay **otro camino** de salida, y `run` deja de ser un viaje de un lugar a otro.

Al final del Módulo 8 el efecto sobre el micro desapareció. ¿Ya es pura `run`? Todavía no. Con la definición del Módulo 4, lanzar una excepción ya es un efecto. Pero hay algo más importante: `run(programa, micro)` promete un `Micro`, y con un `HALT` en el camino no lo devuelve: explota, y alguien en algún lado tiene que atrapar la excepción.

Una excepción corta el flujo del programa: algo anormal pasó y hay que tener un `catch` en algún lado. Pensá en depurar otra vez: venís paso a paso y en el medio salta una excepción: aparece la traza de error y el programa se frena; no hay siguiente paso.

Además del `HALT`, hay otras formas de que `run` termine en una excepción. Un `ADD` o un `MUL` que dé fuera de rango choca con la validación del micro (Módulo 8). Un `LOAD` a una dirección que no existe se sale de la memoria. Si hubiera una instrucción de división, dividir por cero.

## 2. 🔴 Juntar las dos puntas: un tipo de resultado

> Para que una función con dos salidas vuelva a ir de un dominio a una imagen, **la imagen tiene que incluir las dos salidas**. Se define un tipo `Result` con una forma por cada manera de terminar.

Tenés dos caminos y querés ir a un solo lugar: hay que juntar las dos puntas. Una vez que lo ves, es obvio: `run` devuelve algo que puede ser "vengo bien, este es el micro" o "se detuvo, con este micro". Y, por completitud, "falló, con este error". Ese algo es un tipo de datos:

- **`Halted(micro)`**: se encontró un `HALT`; el micro quedó así.
- **`Success(micro)`**: la ejecución viene bien; este es el micro hasta ahora.
- **`Failure(micro, error)`**: algo falló (un registro fuera de rango, una dirección inválida); este es el último micro válido y el error.

Las tres son `case class` de un `sealed trait Result`, que promete que todas tienen un micro (`def micro: Micro`): datos para mirar con pattern matching, como las instrucciones. El código está en la sección 3.

El error ya no interrumpe el flujo. Pasa a ser **un estado más**, y el programa siempre da el paso siguiente.

## 3. 🟡 `run` con resultados

> `run` hace un `foldLeft` cuyo acumulado es un `Result`, y matchea sobre **el par** (resultado anterior, instrucción). Si el anterior es `Halted` o `Failure`, lo devuelve tal cual: el fold sigue recorriendo y deja de aplicar instrucciones.

Varias piezas de Scala aparecen juntas. Cada una, en una línea:

- **Parámetro por nombre.** `micro: => Micro` (con la flecha antes del tipo) recibe la **expresión**, sin evaluarla; se evalúa cada vez que el código usa `micro`. Así, el cálculo del micro nuevo ocurre adentro del `try`, donde se puede atrapar si falla.
- **`apply` en el objeto compañero.** `Result(x)` es azúcar para `Result.apply(x)`: así se llama a un objeto como si fuera una función. Es lo que `case class` hace por vos para construir sin `new`.
- **Dos listas de parámetros.** `def apply(previousMicro: Micro)(micro: => Micro)` se llama `Result(viejo)(nuevo)`.
- **`try … catch` como expresión.** Devuelve el valor del `try` si todo anda, o el de la rama del `catch` que encaje con la excepción.
- **`Success(initialMicro): Result`** le dice al compilador que el acumulado es un `Result` en general. Sin eso, el acumulado queda tipado como `Success`, y las ramas que devuelven un `Result` o un `Halted` dejan de encajar.
- **Patrones sobre un par.** `foldLeft` le pasa a la función dos valores, y `{ case (anterior, instrucción) => … }` los matchea juntos, como una tupla.
- **`nombre @ patrón`** liga un nombre al valor entero que encajó: `previousResult @ Success(micro)` es "un `Success`; a todo llamalo `previousResult` y a su micro, `micro`".

```scala
package tadp.microprocesador.inmutable

package object Operations3 {

  type Program = List[Instruction]

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

**Cómo leerlo.** Se empieza acumulando un éxito: "tengo el micro inicial, y venimos bien". En cada paso ya no alcanza con mirar la instrucción: hay que preguntar también qué forma tiene el resultado anterior.

- Si es `Halted` o `Failure`, no hay más nada que hacer: se devuelve tal cual, para todas las instrucciones que quedan.
- Si es `Success`, se hace lo mismo que en el Módulo 8, pero el micro nuevo se envuelve en un resultado con `Result(micro)(…)`: si construirlo falla, sale un `Failure` con el micro anterior.
- El `HALT` ya no lanza nada: devuelve `Halted(micro)`.
- El `If` llama a `run` sobre las subinstrucciones, que también devuelve un `Result`.

```scala
import tadp.microprocesador.inmutable._
import tadp.microprocesador.inmutable.Operations3._

run(List(Add, Swap), Micro(39, 13)).micro.a   // Resultado: 13
run(List(Add, Halt, Mul), Micro(2, 3))        // Resultado: Halted(Micro(5,3,List(0, 0, …)))
run(List(Add, Mul), Micro(1000, 1000))        // Resultado: Failure(Micro(1000,1000,List(0, 0, …)),java.lang.IllegalArgumentException: requirement failed)
run(List(Load(500)), Micro(1, 1))             // Resultado: Failure(Micro(1,1,List(0, 0, …)),java.lang.IndexOutOfBoundsException: 500)
```

(Los `…` abrevian las 128 posiciones de memoria.) En el tercero, `ADD` da 2000, el `require` del micro lo rechaza, y el resultado guarda el último micro válido. Nada se escapó: `run` devolvió un valor en los cuatro casos.

⚠️ **Trampa: volver a evaluar un parámetro por nombre.** Si `apply` recibiera solo `micro: => Micro` y en el `catch` armara `Failure(micro, error)`, ese `micro` **vuelve a evaluar** la expresión que acaba de fallar: la excepción se relanza desde el `catch`, donde nada la atrapa, y se escapa de `run` (`run(List(Add, Mul), Micro(1000, 1000))` termina con `java.lang.IllegalArgumentException: requirement failed`). El `Failure` necesita un micro que ya exista: el anterior, que viaja en la primera lista de parámetros, `Result(micro)(…)`. Por eso el fold arranca en `Success(initialMicro): Result` y no en `Result(initialMicro)`, que con dos listas quedaría esperando el micro nuevo.

Sí, se ve más complicado que el `foldLeft` del Módulo 8: cada caso tiene que mirar dos cosas y envolver su resultado. Es un estado intermedio.

## 4. 🔴 Lo que se gana: la firma cuenta lo que pasa

> Una operación que **siempre** devuelve un resultado deja de ser algo que **hace** y pasa a ser algo que **responde una pregunta**. Su firma lo dice, y se puede usar con una comodidad que una operación con efecto no permite.

Compará las firmas de `run` a lo largo de la unidad:

```
run(program: Program, micro: Micro): Unit             no cuenta para qué sirve ni cuál de los parámetros cambia
run(program: Program, initialMicro: Micro): Micro     promete un micro, pero con un HALT explota
run(program: Program, initialMicro: Micro): Result    va de un programa y un micro a un resultado, y no pasa nada más
```

La primera dice muy poco: algo hace, en algún lado. La segunda promete algo que no siempre cumple. La tercera describe con claridad lo que pasa, porque pasa poco: entra un programa y un micro, sale un resultado, que puede ser éxito, detención o falla.

**Hacer contra responder.** Si una operación siempre devuelve un resultado, incluso cuando algo sale mal, la podés usar con comodidad: llamarla todas las veces que quieras, usar el resultado como te parezca, y el resto del programa y su estado quedan intactos. Es la diferencia entre `map` y un `foreach` que modifica la colección mientras la recorre. Con `map` usás el resultado que querías, y todos los demás pueden seguir usando la lista original. Si cambiaste la colección original, ya no se puede volver atrás.

Es la separación entre consultas y efectos del Módulo 8, llevada a `run`: ejecutar un programa pasó a ser una consulta.

**Para el parcial, si te preguntan:** *"¿Por qué reemplazar la excepción del `HALT` por un `Result` acerca `run` a la pureza?"* Porque con la excepción, `run` tiene dos salidas (un micro o una interrupción), y deja de ser una función de un dominio a una imagen. `Result` junta las dos puntas en un solo tipo (`Success`, `Halted`, `Failure`): `run` siempre devuelve un valor, la firma `run(…): Result` cuenta lo que pasa, y la operación pasa de hacer algo a responder una pregunta.

## 5. 🟢 Lo que queda para la clase siguiente

> La pureza se recuperó en parte, y el código de esta unidad es el punto de partida de lo que sigue: conviene llegar con las cuatro soluciones entendidas.

La idea de pureza que se había perdido al mezclar objetos y funcional se recuperó en parte: hay falta de efecto (los datos no se mutan, se crean nuevos, y `run` ya no lanza nada) y transparencia referencial (el resultado sale solo del programa y del micro inicial). Lo que falta es encarar el `Result` como lo encara funcional, y eso necesita una clase entera.

Mientras tanto, conviene leer las cuatro soluciones del proyecto (Módulo 0) y sentirse cómodo con lo que hace cada una. Probá agregar una instrucción o una operación en cada solución y fijate qué tenés que tocar; y repasá `foldLeft`, `map` y `filter`.

---

## Checkpoint

1. Al final del Módulo 8, ¿qué le impedía a `run` ser pura, si ya no modificaba el micro?
2. ¿Qué significa "juntar las dos puntas"? ¿Qué tipo lo hace?
3. ¿Qué representa cada forma de `Result`? ¿Cuándo aparece un `Failure` en este micro?
4. ¿Qué es un parámetro por nombre? ¿Por qué `apply` lo necesita para atrapar el error?
5. ¿Por qué el acumulado arranca como `Success(initialMicro): Result` y no como `Success(initialMicro)` a secas?
6. ¿Qué hace el `foldLeft` cuando el resultado anterior es `Halted`? ¿Sigue recorriendo?
7. ¿Qué pasa si en el `catch` se usa el parámetro por nombre para armar el `Failure`?
8. Compará las firmas `: Unit` y `: Result` de `run`. ¿Cuál cuenta qué?
9. ¿Qué diferencia hay entre una operación que hace algo y una que responde una pregunta? Usá `map` como ejemplo.

## Qué viene después

Fin de la unidad. La clase siguiente parte de `Operations3` y trae la forma funcional de trabajar con resultados como `Result`, para que este código deje de verse como un paso atrás.

**FIN DEL MÓDULO 9 — Un resultado en vez de una excepción (puente)**
