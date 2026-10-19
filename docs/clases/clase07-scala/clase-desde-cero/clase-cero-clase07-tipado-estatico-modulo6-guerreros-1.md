# Clase desde cero — Tipado estático en Scala — Módulo 6: Guerreros I — del test al código, `???`, `var`/`val` e inmutabilidad

**Unidad:** clase07 · **Lenguaje:** Scala 3.3.1 · **Densidad:** 🔴 una sesión con el proyecto abierto

---

## Sobre este documento

**Qué cubre.** El dominio de clase01 (guerreros, murallas, misiles) en Scala, guiado por **tests que ya están escritos**. Cómo hacer compilar un método sin implementarlo (**`???`**) y qué es **`Nothing`**. La primera implementación de `atacaA`, **mutable**, con `var`. Qué son de verdad `val` y `var`: **properties**, mensajes al getter. Una versión **inmutable** del ataque y por qué podría convenir. Y la energía mínima en cero.

**Qué no cubre.** La muralla y el misil: los tests existen, pero hacerlos pasar pide traits (Módulo 7).

## De dónde venís

Del Módulo 0 (el proyecto, `AnyFunSuite`, `shouldBe`), del Módulo 2 (clases con parámetros, `val` en el constructor, `def`), del Módulo 4 (`Any` arriba de todo). De clase01: el dominio, con sus reglas (el daño es la diferencia entre el potencial ofensivo del atacante y el defensivo del atacado).

---

## 1. 🟡 Los tests mandan

> Los tests describen el comportamiento esperado **antes** del código. El trabajo es hacerlos pasar, uno por uno, y el compilador te va a decir qué falta en cada paso.

```scala
// src/test/scala/tadp/ageofempires/AtaqueTest.scala
package tadp.ageofempires

import org.scalatest.funsuite.AnyFunSuite
import org.scalatest.matchers.should.Matchers

class AtaqueTest extends AnyFunSuite with Matchers {

  test("un guerrero ataca a otro guerrero") {
    val g1 = new Guerrero              // sin paréntesis: Guerrero tiene valores por defecto
    val g2 = new Guerrero

    g1.atacaA(g2)

    g2.energia shouldBe 90             // 100 de energía − (20 de ataque − 10 de defensa)
  }

  test("un guerrero con mucho potencial ofensivo ataca a otro guerrero") {
    val g1 = new Guerrero(200)
    val g2 = new Guerrero

    g1.atacaA(g2)

    g2.energia shouldBe 0              // la energía nunca baja de cero
  }

  test("un guerrero ataca a una muralla") {
    val g1 = new Guerrero
    val m = new Muralla

    // g1.atacaA(m)                    // comentado: todavía no compila (Módulo 7)

    m.energia shouldBe 998
  }

  test("un misil ataca a una muralla") {
    val misil = new Misil(1966)
    val muralla = new Muralla

    // misil.atacaA(muralla)           // comentado: todavía no compila (Módulo 7)

    muralla.energia shouldBe 950
  }
}
```

Y el código inicial, el mínimo para que los tests **compilen**:

```scala
// src/main/scala/tadp/ageofempires/Guerrero.scala
package tadp.ageofempires

class Guerrero(val potencialOfensivo: Int = 20) {
  var energia: Int = 100                 // var: una variable que cambia (sección 4)
  var potencialDefensivo: Int = 10

  def atacaA(otro: Guerrero): Unit = {   // Unit: "no devuelve nada útil" (sección 2)
    ???                                  // todavía sin implementar
  }
}
```

```scala
// Muralla.scala y Misil.scala, por ahora lo mínimo para que los tests compilen
class Muralla {
  val energia = 1000
}

class Misil(val anioFabricacion: Int) {
  def potencialOfensivo: Int = (2016 - anioFabricacion) * 10
}
```

## 2. 🔴 `???`: compilar lo que todavía no sabés escribir

> **`???`** es un método que **compila en cualquier lugar donde se espere un valor**, y en ejecución tira `NotImplementedError`. Sirve para dejar un hueco declarado y seguir compilando el resto.

Corré el primer test con el `atacaA` de arriba:

```
[info] AtaqueTest:
[info] - un guerrero ataca a otro guerrero *** FAILED ***
[info]   scala.NotImplementedError: an implementation is missing
[info]   at scala.Predef$.$qmark$qmark$qmark(Predef.scala:…)
[info]   at tadp.ageofempires.Guerrero.atacaA(Guerrero.scala:9)
```

(La línea de `Predef.scala` varía con la versión de la librería; la de `Guerrero.scala` es la tuya.)

El programa compiló y el test llegó a ejecutar `atacaA`, que explotó con "falta una implementación". El error ahora es **tuyo** y está exactamente donde lo dejaste.

`???` es un método común de la librería estándar (vive en `Predef`, lo que está disponible sin `import`):

```scala
  def ??? : Nothing = throw new NotImplementedError      // así está definido en Scala
```

Lo interesante es su tipo de retorno: **`Nothing`**.

> **`Nothing`** es el **subtipo de todos los tipos**: está abajo de todo, como `Any` está arriba de todo. Un valor de tipo `Nothing` puede ir donde se espere **cualquier** cosa. Ningún valor tiene tipo `Nothing`: solo lo tiene algo que **jamás devuelve** (tira una excepción, o sigue para siempre).

```
            ┌───────────┐
            │    Any    │   arriba de todo: supertipo de todos
            └─────▲─────┘
                  │
        ┌─────────┴─────────┐
   ┌────┴─────┐        ┌────┴─────┐
   │  AnyVal  │        │  AnyRef  │
   │ Int, …   │        │ Guerrero,│
   └────▲─────┘        │ String, …│
        │              └────▲─────┘
        └─────────┬─────────┘
            ┌─────┴─────┐
            │  Nothing  │   abajo de todo: subtipo de todos
            └───────────┘
```

Por eso `???` compila en un método que devuelve `Unit`, en uno que devuelve `Int` o en uno que devuelve `Guerrero`: `Nothing` es subtipo de los tres. Cambiá el tipo de retorno de `atacaA` por `String` y sigue compilando.

Y `Unit`: es el tipo de los métodos que **hacen algo** y no devuelven un valor útil (el `void` de otros lenguajes). Su único valor se escribe `()`.

> **Para el parcial, si te preguntan**
> *¿Por qué `???` compila sin importar el tipo de retorno del método?* — Porque su tipo es `Nothing`, el subtipo de todos los tipos: donde se espera cualquier valor, un `Nothing` es aceptable por subtipado. Nunca produce un valor; en ejecución lanza `NotImplementedError`.

## 3. 🔴 Implementar `atacaA`: la primera versión, mutable

> Atacar es **restarle energía al otro**: la diferencia entre mi potencial ofensivo y su potencial defensivo. Como `energia` es un `var`, se puede reasignar.

```scala
  def atacaA(otro: Guerrero): Unit = {
    otro.energia = otro.energia - (this.potencialOfensivo - otro.potencialDefensivo)
  }
```

```
[info] - un guerrero ataca a otro guerrero                  ← pasa: 100 − (20 − 10) = 90
[info] - un guerrero con mucho potencial ofensivo ataca a otro guerrero *** FAILED ***
[info]   -90 was not equal to 0 (AtaqueTest.scala:24)      ← 100 − (200 − 10) = −90
```

El primero pasa. El segundo falla porque la energía quedó negativa: lo arreglamos en la sección 6. (Los tests 3 y 4, con la llamada comentada, también fallan: `1000 was not equal to 998` y `1000 was not equal to 950`. Siguen en rojo hasta el Módulo 7.) Antes, la forma corta que vas a ver en el código de la materia:

| Escribís | Equivale a |
|---|---|
| `otro.energia -= daño` | `otro.energia = otro.energia - daño` |
| `otro.energia += 10` | `otro.energia = otro.energia + 10` |

`this.potencialOfensivo` y `potencialOfensivo` son lo mismo adentro de la clase; el `this.` es opcional y acá se escribe para que se vea quién ataca y quién recibe.

## 4. 🔴 `val` y `var` son properties: siempre un mensaje, nunca la variable

> `otro.energia` **no accede a una variable**: le manda el mensaje `energia` al objeto, y el objeto responde con su getter. **`val`** genera solo el getter; **`var`** genera getter y setter. Nunca tocás la variable de verdad.

| Declarás | Se genera | `x.energia` | `x.energia = 5` |
|---|---|---|---|
| `val energia = 100` | un getter `energia` | ✅ 100 | ❌ `Reassignment to val energia` |
| `var energia = 100` | getter `energia` + setter `energia_=` | ✅ 100 | ✅ (llama al setter) |

Esto lo viste parcialmente en Ruby con `attr_reader` y `attr_accessor`: ahí también eran métodos. La diferencia es que en Scala **no hay otra forma** de acceder desde afuera: la variable que guarda el valor es siempre privada, y lo público es el método. Por eso un `val` o un `var` se pueden redefinir como métodos, y por eso (esta era la pregunta del Módulo 4) **un `val` puede cumplir un `def` abstracto**: desde afuera, `def nombre: String` y `val nombre: String` son lo mismo: un mensaje sin parámetros que devuelve un `String`. El Módulo 7 termina de cerrar esto (hay una dirección en la que no funciona).

Ahora la pregunta de diseño: ¿`energia` tiene que ser `var`? Sí, mientras atacar sea **mutar** al otro. Hay otra forma.

## 5. 🟡 La versión inmutable: atacar devuelve un guerrero nuevo

> Si `energia` es un `val`, atacar **no puede modificar** al otro. La alternativa es que `atacaA` **devuelva un guerrero nuevo**, con la energía ya descontada, y deje al original como estaba.

```scala
class Guerrero(val potencialOfensivo: Int = 20,
               val energia: Int = 100) {               // energia ahora es val: entra por el constructor

  var potencialDefensivo: Int = 10

  def atacaA(otro: Guerrero): Guerrero = {             // devuelve el resultado del ataque
    Guerrero(otro.potencialOfensivo,
             otro.energia - (this.potencialOfensivo - otro.potencialDefensivo))
  }
}
```

`Guerrero(…)` sin `new`: en Scala 3 se puede crear una instancia escribiendo la clase como si fuera una función. `new Guerrero(…)` sigue valiendo y es lo mismo.

El test tiene que cambiar, porque ahora el guerrero atacado **es otro objeto**:

```scala
  test("un guerrero ataca a otro guerrero") {
    val g1 = new Guerrero
    val g2 = new Guerrero

    val g3 = g1.atacaA(g2)      // el resultado del ataque

    g3.energia shouldBe 90      // Resultado: pasa
    g2.energia shouldBe 100     // g2 quedó intacto
  }
```

**¿CÓMO FUNCIONA?** `g1.atacaA(g2)` lee la energía de `g2` (100), calcula el daño (20 − 10 = 10), y construye un `Guerrero` nuevo con el mismo potencial ofensivo de `g2` y energía 90. `g2` sigue existiendo con 100: nadie lo tocó. `g3` es "`g2` después del ataque". Si querés el estado anterior, lo tenés; si querés el posterior, también. Fijate un detalle: el guerrero nuevo recibe solo dos datos, y `potencialDefensivo` queda en su valor por defecto. Con más estado, **todo** tendría que viajar por el constructor para que la copia sea fiel; por eso, en la segunda mitad, las clases inmutables llevan todo su estado ahí.

**¿Para qué querrías eso?** Para **guardarte el estado anterior**. Si entrenás a `g2` haciendo que lo ataquen, y después te arrepentís del entrenamiento, con la versión mutable ya es tarde: `g2` cambió y el original no existe más. Con la inmutable, `g2` sigue ahí y `g3` es un camino que podés descartar. Cuesta algo: hay que acordarse de quedarse con el resultado, y hay que crear objetos nuevos. En la segunda mitad de la materia esto se vuelve central; por ahora alcanza con haberlo visto una vez.

**De vuelta a la versión mutable.** El resto de la unidad sigue con `var energia` y `atacaA` que devuelve `Unit`, porque es el diseño de este dominio hoy. Al volver, hay una trampa: si olvidás deshacer el test, el compilador te lo recuerda.

```scala
    val g3 = g1.atacaA(g2)      // atacaA vuelve a devolver Unit
    g3.energia shouldBe 90
```

```
value energia is not a member of Unit
```

`g3` es ahora el resultado de un método `Unit`: el valor `()`, que no entiende `energia`. Error de tipos, detectado al compilar, en el test.

🕳️ **Madriguera — `case class`.** Scala tiene una forma de declarar clases pensadas para ser inmutables, que trae gratis comparación por valor y copias con cambios. Es tema de clases posteriores. *Volvé al camino — esto se profundiza aparte, otro día.*

## 6. 🔴 La energía nunca baja de cero

> Un guerrero con energía negativa es un **estado inválido**. La energía después de un ataque es el máximo entre lo que queda y cero.

```scala
  def atacaA(otro: Guerrero): Unit = {
    otro.energia = (otro.energia - (this.potencialOfensivo - otro.potencialDefensivo)).max(0)
  }
```

`.max(0)` es un mensaje que entienden los `Int`: devuelve el mayor entre el receptor y el argumento. `(-90).max(0)` es `0`; `(90).max(0)` es `90`.

```
[info] - un guerrero ataca a otro guerrero
[info] - un guerrero con mucho potencial ofensivo ataca a otro guerrero
```

Los dos primeros tests pasan. Este es el `Guerrero` al cierre del módulo:

```scala
package tadp.ageofempires

class Guerrero(val potencialOfensivo: Int = 20) {
  var energia: Int = 100
  var potencialDefensivo: Int = 10

  def atacaA(otro: Guerrero): Unit = {
    otro.energia = (otro.energia - (this.potencialOfensivo - otro.potencialDefensivo)).max(0)
  }
}
```

Los otros dos tests siguen con la llamada comentada y en rojo: `g1.atacaA(m)` con una `Muralla` **no compila**, y para eso hace falta el Módulo 7.

> **Para el parcial, si te preguntan**
> *¿Cuándo usás `val`, `var` y `def` para "tener algo" en una clase?* — `val` cuando el valor se fija una vez y no cambia (genera solo el getter). `var` cuando el estado tiene que mutar (getter y setter). `def` cuando el valor se calcula cada vez que se pide, o puede depender del estado. Los tres se usan desde afuera igual: mandando un mensaje.

---

## Checkpoint (sin respuestas)

1. ¿Por qué los tests están escritos antes que el código? ¿Qué te dice el compilador en cada paso?
2. ¿Qué es `???`? ¿Qué pasa al compilar un método que lo contiene y qué pasa al ejecutarlo?
3. ¿Qué es `Nothing` y por qué permite que `???` compile con cualquier tipo de retorno? ¿Dónde está en la jerarquía?
4. ¿Qué es `Unit`?
5. ¿Qué hace `otro.energia -= 10` exactamente? ¿Accede a una variable?
6. ¿Qué genera `val` y qué genera `var`? ¿Qué error da reasignar un `val`?
7. ¿Por qué un `val` puede cumplir un `def` abstracto de un trait?
8. ¿Qué cambia en `atacaA` y en el test en la versión inmutable? ¿Qué ganás y qué te cuesta?
9. ¿Qué error da el compilador si `atacaA` vuelve a devolver `Unit` y el test sigue haciendo `val g3 = g1.atacaA(g2); g3.energia`? ¿Por qué?
10. ¿Qué hace `.max(0)` y qué problema de diseño resuelve?

## Qué viene después

**Módulo 7:** la muralla. `g1.atacaA(m)` no compila porque `atacaA` pide un `Guerrero`. Ya resolviste este problema en el Módulo 4: hace falta un tipo común, y esta vez va a traer comportamiento.

**FIN DEL MÓDULO 6**
