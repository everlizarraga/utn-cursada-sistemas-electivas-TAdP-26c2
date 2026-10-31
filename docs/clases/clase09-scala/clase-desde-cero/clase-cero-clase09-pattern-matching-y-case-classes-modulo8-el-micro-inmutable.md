# Clase desde cero — Pattern matching, case classes y el híbrido objeto-funcional — Módulo 8: Pureza en la práctica: el micro inmutable

**Unidad:** clase09 · **Lenguaje:** Scala 3.3.1 · **Archivos del proyecto:** `inmutable/Micro.scala`, `inmutable/Operations1.scala`, `inmutable/Operations2.scala` (y `inmutable/Instructions.scala`, idéntico al de `mutable`) · **Densidad:** 🔴 una sesión, con un worksheet para comparar micros antes y después

---

## Sobre este documento

**Qué cubre.** El segundo vértice del triángulo rojo llevado al código: sacarle el efecto a `run`. Por qué conviene (el argumento del debugging, y la separación entre consultas y efectos que objetos ya practica). Por qué Scala, a diferencia de Haskell, deja tener efecto. El micro como `case class` inmutable que valida sus invariantes al construirse, algo que ni objetos ni funcional consiguen solos. `copy` para "modificarlo". Y `run` en dos pasos: primero con una variable local, después con `foldLeft`.

**Qué no cubre.** El `HALT`, que sigue lanzando una excepción: es el Módulo 9.

## De dónde venís

Del Módulo 2: objetos garantiza invariantes validando en el constructor **y** en cada setter; funcional solo puede garantizarlas por convención. Del Módulo 4: pureza = falta de efecto + transparencia referencial, el programa como viaje de un dominio a una imagen, y la pérdida de identidad. Del Módulo 6: `case class`, campos de solo lectura, `copy` y los parámetros nombrados. Del Módulo 7: `run` con `match`, que modifica el micro que recibe y hace el swap con una variable temporal. De Paradigmas: `foldl`.

---

## 1. 🔴 Por qué sacar el efecto: depurar sin volver a empezar

> Con efecto, cada paso **destruye** el estado anterior: si te pasaste, hay que ejecutar todo de nuevo. Sin efecto, cada paso **devuelve** un estado nuevo y el anterior sigue ahí: todos los estados existen a la vez.

El Módulo 4 dio las razones de arquitectura (escalar replicando, el estado como cuello de botella). Hay una más chica y más cotidiana: depurar.

Imaginá que depurás `run` del Módulo 7, paso a paso. Ejecutás una instrucción y mirás: ¿se rompió el micro? Si sí, encontraste lo que buscabas, pero ya pasó: el micro quedó roto, y el estado anterior se perdió porque la instrucción lo pisó. Hay que parar, ejecutar todo desde el principio, frenar un paso antes, entrar y repetir. Depurar consiste en dejar que todo se rompa y volver a empezar.

Ahora imaginá que cada paso, en lugar de cambiar el micro, te devuelve uno nuevo y deja el anterior intacto. Ya no hace falta parar el programa: tenés el micro de antes y el de después, al mismo tiempo. Podés volver un paso, o repetir uno para ver por qué dio lo que dio, sin comprometer nada. Con `simplify` del Módulo 7 eso ya pasa, porque no modifica nada. Con `run`, no.

Sin efecto, también se puede trabajar en paralelo. Con varios hilos, o con varios procesos compitiendo por un recurso, las condiciones de carrera vienen de manipular estado compartido. Ojo: el estado se sigue manteniendo. La diferencia es que, en lugar de pisarlo, se generan copias que representan cómo sería el objeto si hubiera cambiado.

**Objetos ya lo sabe.** Objetos siempre puede causar efecto, y aun así la buena práctica es separar las operaciones que **consultan** de las que **causan efecto**. Consultar es gratis: no se rompe nada. Causar efecto tiene un costo lógico. Por eso se usa con control.

No hay nada de malo en causar efecto: está bueno que un objeto tenga su estado encapsulado y controlado, como única fuente de verdad. Lo que se busca es conservar ese encapsulamiento y esas invariantes sin necesidad de efecto.

## 2. 🟡 Scala te deja causar efecto; Haskell, no

> Scala es el primer lenguaje funcional que ves que **tiene efecto**. Haskell puede garantizar pureza porque te prohíbe asignar; Scala te deja, y la pureza queda en tus manos.

En Paradigmas, Haskell te daba código sin efecto porque el lenguaje está parado sobre la pureza. No podés asignar ni cambiar el valor de una variable. Acá, al mezclar objetos y funcional, eso se perdió en parte: **Scala no puede garantizar pureza**.

Dos ejemplos de efecto que conviene tener claros:

- **Imprimir por consola** es causar un efecto: siempre hace lo mismo, pero produce algo que sobrevive a la ejecución del programa. Ojo: el `print` del Módulo 7 es puro, porque devuelve un `String`; el efecto sería mostrarlo en pantalla. En Haskell imprimir por consola se puede, con un mecanismo particular que vas a ver en la próxima clase.
- **Generar un número aleatorio** rompe la transparencia referencial: con los mismos parámetros da resultados distintos, porque depende de algo más que sus parámetros.

## 3. 🔴 El micro como `case class`: integridad validada en un solo lugar

> Un micro inmutable es una `case class` con sus **validaciones en el cuerpo**: se ejecutan al construirlo. Como nunca cambia y toda "modificación" construye uno nuevo, **validar al construir alcanza**: es imposible tener un micro inválido.

Para sacar el efecto, lo primero es que las estructuras no puedan cambiar. ¿Qué puede cambiar su estado en el código del Módulo 7? Solo el micro. Esta es su versión inmutable (`inmutable/Micro.scala`). Antes, tres piezas:

- `object Micro { … }` al lado de `case class Micro` es su **objeto compañero**: un `object` con el mismo nombre que la clase, en el mismo archivo. Acá guarda las constantes; se usan como `Micro.MEM_SIZE`.
- `mem: List[Int] = List.fill(Micro.MEM_SIZE)(0)` es un **parámetro con valor por defecto**: si al construir no pasás `mem`, vale una lista de 128 ceros.
- `require(condición)` es el del Módulo 1: lanza `IllegalArgumentException` si la condición es falsa. Lo nuevo es dónde está: el código suelto en el cuerpo de una clase, fuera de todo método, se ejecuta al construir cada instancia.

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

```scala
import tadp.microprocesador.inmutable._

Micro(0, 0).mem.size       // Resultado: 128
Micro(2000, 0)             // Resultado: java.lang.IllegalArgumentException: requirement failed
Micro(0, 0, List(1, 2, 3)) // Resultado: java.lang.IllegalArgumentException: requirement failed
```

Compará con el micro mutable del Módulo 1: getters, setters, y la validación de rango adentro de cada setter. Acá, la declaración de la forma (dos registros y una memoria, que ya es una lista inmutable) y las mismas validaciones, en el cuerpo.

**Por qué alcanza con un lugar.** Los campos son de solo lectura: no hay setter. Si el micro nació bien, está bien para siempre. Y para "cambiarlo" hay que construir otro, con lo cual la validación vuelve a correr. Todas las operaciones de cambio quedan validadas sin escribir una línea más.

Volvé a las dos puntas del Módulo 2:

- **En funcional**, lo más parecido es una función constructora, pero siempre se puede crear el dato sin llamarla. No hay forma de protegerse del todo de un mal uso.
- **En objetos**, la misma validación hay que llamarla en el constructor **y** en cada setter (o usar el setter desde el constructor para que valga en todos lados). Y el setter solo controla el valor que se está seteando.
- **En el híbrido**, se valida una vez y es imposible hacerlo mal. Además, el cuerpo tiene a mano **todos** los campos, así que se puede comparar uno con otro, cosa que un setter de un solo campo no puede.

Es algo que ni objetos ni funcional logran solos. La clase queda simple, tonta, y tiene más operaciones de las que parece: todas las que regala `case`.

El micro es `case class` sin que nadie vaya a matchear sobre él: la razón acá es que `case` da gratis una construcción de solo lectura, el `copy`, el `toString` y la igualdad por contenido.

## 4. 🔴 `copy`: el mismo micro, con un cambio

> `micro.copy(a = 52)` construye **otro** micro, igual al original salvo en lo que nombrás. El original queda intacto, y el nuevo pasa por las validaciones.

```scala
Micro(1, 2).copy(a = 9).a   // Resultado: 9
```

`copy` es un método común que `case` genera usando dos cosas que Scala ya tiene: **parámetros nombrados** (los del Módulo 6: `a = 9`, sin importar el orden) y **parámetros con valor por defecto**. El `copy` del micro recibe `a`, `b` y `mem`, y el valor por defecto de cada uno es el que el micro ya tiene. Si no le pasás nada, te da una copia idéntica.

Y el micro nuevo pasa por las validaciones:

```scala
val m = Micro(1, 2)
m.copy(a = 2000)   // Resultado: java.lang.IllegalArgumentException: requirement failed
m.a                // Resultado: 1
```

Si usaste la sintaxis de registros de Haskell para copiar un dato cambiando un campo (`alumno { nota = 7 }`), es exactamente la misma idea.

Para la memoria hace falta una herramienta de listas: `lista.updated(i, valor)` devuelve una lista **nueva** con la posición `i` reemplazada, y deja la original igual.

```scala
List(1, 2, 3).updated(1, 9)   // Resultado: List(1, 9, 3)
```

## 5. 🔴 Primer paso: `run` devuelve un micro nuevo

> `run` recibe un micro y **devuelve otro**: el que quedaría después de ejecutar el programa. Por dentro, una variable local va guardando el micro de cada paso.

`inmutable/Operations1.scala`:

```scala
package tadp.microprocesador.inmutable

package object Operations1 {

  type Program = List[Instruction]
  class ExecutionHaltException extends RuntimeException

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

El código casi no cambió respecto del Módulo 7. Cambiaron dos cosas: la firma, `run(…): Micro` en lugar de `: Unit`, y cada rama, que en vez de modificar el micro construye una copia con el cambio y la guarda en la variable.

**El swap sin temporal.** `micro.copy(a = micro.b, b = micro.a)`. El micro original no cambia mientras se construye el nuevo, así que se pueden leer los dos registros viejos y cruzarlos. Es difícil ser más directo: "el mismo micro, con los registros invertidos".

Para mirar tres valores juntos, una tupla `(x, y, z)`, como en Haskell:

```scala
val inicial = Micro(39, 13)
val fin = Operations1.run(List(Add, Swap, Store(9)), inicial)

(fin.a, fin.b, fin.mem(9))              // Resultado: (13,52,13)
(inicial.a, inicial.b, inicial.mem(9))  // Resultado: (39,13,0)
```

El micro inicial quedó intacto. Cualquiera puede recibir un micro como respuesta sin miedo a que otro lo cambie desde afuera. Con un micro mutable (el del `RunVisitor` del Módulo 5 o el de `run` en el Módulo 7), correr dos programas a la vez sobre el mismo micro lo rompe. Acá se pueden correr en paralelo tantos como quieras sobre el mismo micro original.

⚠️ **Trampa: el `If` cuyo resultado nadie guarda.** Con un micro inmutable, `if (micro.a == 0) run(subInstructions, micro) else micro` es una expresión que **devuelve** un micro, y en este `for` nadie lo guarda: las demás ramas reasignan `micro`, esta no. Compila sin aviso, y el `If` deja de tener efecto: con `Micro(0, 5)` y `IF[ADD]`, A debería quedar en 5 y queda en 0. En un `run` con variable local, la rama tiene que reasignar: `if (micro.a == 0) micro = run(subInstructions, micro)`.

**¿Ya no hay efecto?** Sobre el micro, ya no. Pero la variable `micro` se pisa en cada instrucción. Es un efecto interno: hacia afuera, `run` no cambia nada. Igual molesta: dentro de `run`, cada paso pisa el micro del paso anterior, y si la variable queda con un micro equivocado, volver atrás sigue obligando a empezar de nuevo. Lo que sí se ganó es que, en cada paso, el micro anterior y el nuevo existen a la vez, y se pueden comparar antes de asignar. Ya es una ayuda para depurar. Estaría mejor no pisar nada.

## 6. 🔴 Segundo paso: `foldLeft`

> **`foldLeft`** recorre una lista llevando un acumulado: recibe el **valor inicial** y una **función** que, dado el acumulado y el siguiente elemento, devuelve el nuevo acumulado. Con el micro como acumulado, `run` se escribe sin una sola asignación.

`foldLeft` es el `foldl` de Haskell, como mensaje de la lista:

```scala
List(1, 2, 3).foldLeft(0)((acumulado, n) => acumulado + n)   // Resultado: 6
```

Arranca con `0`; suma `1`, después `2`, después `3`. Hacete amigo del `fold`: es de las mejores operaciones que hay. Convierte una lista de cualquier cosa en cualquier otra; es la iteración por excelencia, hecha operación. Cuesta al principio porque no responde a una idea concreta como "transformar" (`map`) o "filtrar" (`filter`), pero resuelve con elegancia muchos algoritmos que de otro modo serían recursiones a mano. Sirve cuando el resultado sale de **todos** los elementos juntos, no de cada uno por separado.

Ejecutar un programa es eso: aplicar las instrucciones en secuencia sobre un micro. El acumulado es el micro. El valor inicial, el micro que recibís. La función: dado el micro en algún estado intermedio y la siguiente instrucción, devolvé el micro que sigue. `foldLeft` se encarga de recorrer y de ir pasando cada resultado al paso siguiente.

`inmutable/Operations2.scala`. `{ (micro, instruction) => … }` es la función de dos parámetros que `foldLeft` recibe, escrita entre llaves porque ocupa varias líneas:

```scala
package tadp.microprocesador.inmutable

package object Operations2 {

  type Program = List[Instruction]
  class ExecutionHaltException extends RuntimeException

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

Lo único que se quitó es la asignación. Cada rama **devuelve** el micro nuevo; el valor del `match` es lo que `foldLeft` le pasa a la instrucción siguiente. Por eso la línea del `If` que en el paso anterior era una trampa, acá es correcta: `else micro` devuelve el micro tal cual, y ese valor sí se usa.

La única rama que no cambió es `Halt`: sigue lanzando una excepción. Se eliminó el efecto sobre el micro, pero `run` todavía no es pura (Módulo 9).

```scala
val fin2 = Operations2.run(List(Add, Swap, Store(9)), Micro(39, 13))
(fin2.a, fin2.b, fin2.mem(9))   // Resultado: (13,52,13)
```

Y algo que con efecto era impensable: como ejecutar no cambia nada, podrías correr las subinstrucciones de un `If` **antes** de mirar la condición, solo para ver cómo quedaría el micro, aunque no correspondiera ejecutarlas. Si depurás, eso sirve.

**Para el parcial, si te preguntan:** *"¿Qué ventaja tiene validar invariantes en el constructor de una `case class` inmutable, frente a objetos y a funcional?"* Que la integridad se valida en un solo lugar y alcanza. Como los campos no se pueden reasignar, un micro que nació válido es válido para siempre, y toda "modificación" (`copy`) construye uno nuevo que vuelve a pasar por las validaciones. En objetos hay que validar en el constructor y en cada setter, y el setter ve un solo campo; en funcional siempre se puede crear el dato sin pasar por la función constructora.

**Para el parcial, si te preguntan:** *"¿Por qué conviene un `run` sin efecto?"* Porque el micro original queda intacto y cada paso produce uno nuevo: se puede comparar el antes y el después, volver un paso atrás al depurar sin reejecutar todo, y correr varios programas sobre el mismo micro sin que se pisen. Con `foldLeft`, además, desaparece la variable que se pisaba en cada instrucción.

---

## Checkpoint

1. ¿Por qué depurar código con efecto obliga a volver a empezar? ¿Qué cambia sin efecto?
2. ¿Qué buena práctica de objetos tiene que ver con esto?
3. ¿Por qué Haskell puede garantizar pureza y Scala no? ¿Imprimir por consola es efecto? ¿Generar un número aleatorio? ¿Qué rompe cada uno?
4. ¿Dónde están las validaciones del micro inmutable y cuándo se ejecutan?
5. ¿Por qué alcanza con validar al construir? ¿Qué tiene que ver `copy`?
6. Compará cómo se garantizan las invariantes en objetos, en funcional y en el híbrido.
7. ¿Qué es `copy` por dentro? ¿Qué dos herramientas de Scala usa?
8. ¿Por qué el swap ya no necesita una variable temporal?
9. ¿Qué pasa si la rama del `If` en `Operations1` no reasigna `micro`? ¿Por qué en `Operations2` la misma expresión es correcta?
10. ¿Queda algún efecto en `Operations1`? ¿Dónde?
11. Explicá `foldLeft` con sus dos parámetros. ¿Qué es el acumulado en `run`?

## Qué viene después

**Módulo 9:** el efecto sobre el micro desapareció, pero `run` todavía no es pura: `HALT` lanza una excepción. Lo que queda de la materia trabaja principalmente sobre la ejecución, y el `run` al que llega el Módulo 9 es el punto de partida. El Módulo 9 la reemplaza por un resultado que dice cómo terminó la ejecución.

**FIN DEL MÓDULO 8 — Pureza en la práctica: el micro inmutable**
