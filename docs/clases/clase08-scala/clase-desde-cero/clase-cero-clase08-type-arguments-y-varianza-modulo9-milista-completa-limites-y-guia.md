# Clase desde cero — Type arguments y varianza en Scala — Módulo 9: `MiLista` completa, los límites de la teoría y la guía para el TP

**Unidad:** clase08 · **Lenguaje:** Scala 3.3.1 · **Densidad:** 🔴 pide una sesión con el código abierto; cierra la unidad

---

## Sobre este documento

**Qué cubre.** La lista del Módulo 7 terminada y corriendo: un caso vacío (`Vacia`) que sirve como lista de **cualquier** cosa gracias a `Nothing` y a la covarianza, un caso con elementos (`Nodo`), y cada operación resuelta por polimorfismo. El `add` rechazado en el Módulo 7, resuelto con `[U >: T]`, e inferido. Hasta dónde llega todo esto: un `contains(elem: T)` que sería seguro y el compilador rechaza igual, y por qué eso es un problema abierto. Dos bounds con varianza en un mismo tipo. Y lo que vas a usar en el TP: una **guía de decisión en tres preguntas** y dos ejercicios del dominio con su resolución.

**Qué no cubre.** Pattern matching y case classes, que son la forma habitual de escribir esta lista en Scala y son el tema de la clase siguiente.

## De dónde venís

De toda la unidad, y en particular: `Nothing` abajo de todo y `List()` es `List[Nothing]` (clase anterior, M6 y M8); `object` como objeto único (clase anterior, M0); `abstract class` (Módulo 5); posiciones y `[U >: T]` (Módulo 7); `[U >: T <: Animal]` (Módulo 8). Y de la clase anterior, M4: un `trait` o clase abstracta declara mensajes que cada subclase resuelve a su manera.

---

## 1. 🔴 El caso vacío: `Vacia` es `MiLista[Nothing]`

> Una lista vacía sirve como lista de vacas, de caballos o de cualquier cosa. Con `+T`, eso se expresa con un solo objeto: **`Vacia extends MiLista[Nothing]`**. Como `Nothing` es subtipo de todo y `MiLista` es covariante, `MiLista[Nothing]` es subtipo de **toda** `MiLista[T]`.

La lista del Módulo 7 tenía un solo nodo y ningún final; `MiLista.scala` la termina así (es el código del proyecto de referencia, completo):

```scala
package tadp.granja

abstract class MiLista[+T] {

  def head: T

  def tail: MiLista[T]

  def isEmpty: Boolean

  def length: Int

  def add[U >: T](elem: U): MiLista[U] = new Nodo(elem, this)

  def contains[U >: T](elem: U): Boolean

  def filter(f: T => Boolean): MiLista[T]

  def map[U](f: T => U): MiLista[U]

  def concat[U >: T](otra: MiLista[U]): MiLista[U]

  def foreach(f: T => Unit): Unit
}

object Vacia extends MiLista[Nothing] {

  def head: Nothing = throw new NoSuchElementException("head de una lista vacía")

  def tail: MiLista[Nothing] = throw new NoSuchElementException("tail de una lista vacía")

  def isEmpty: Boolean = true

  def length: Int = 0

  def contains[U >: Nothing](elem: U): Boolean = false

  def filter(f: Nothing => Boolean): MiLista[Nothing] = this

  def map[U](f: Nothing => U): MiLista[U] = this

  def concat[U >: Nothing](otra: MiLista[U]): MiLista[U] = otra

  def foreach(f: Nothing => Unit): Unit = ()
}

class Nodo[+T](primero: T, cola: MiLista[T]) extends MiLista[T] {

  def head: T = primero

  def tail: MiLista[T] = cola

  def isEmpty: Boolean = false

  def length: Int = 1 + cola.length

  def contains[U >: T](elem: U): Boolean = primero == elem || cola.contains(elem)

  def filter(f: T => Boolean): MiLista[T] = {
    if (f(primero)) {
      new Nodo(primero, cola.filter(f))
    } else {
      cola.filter(f)
    }
  }

  def map[U](f: T => U): MiLista[U] = new Nodo(f(primero), cola.map(f))

  def concat[U >: T](otra: MiLista[U]): MiLista[U] = new Nodo(primero, cola.concat(otra))

  def foreach(f: T => Unit): Unit = {
    f(primero)
    cola.foreach(f)
  }
}
```

Tres piezas. `MiLista[+T]` es la clase abstracta: declara qué sabe hacer toda lista. `Nodo[+T](primero, cola)` es el caso con elementos, el nodo del Módulo 7 con los nombres de allá. `Vacia` es el caso vacío, y está escrito como `object` (un único objeto, sin `new`) de tipo `MiLista[Nothing]`.

**Por qué `Nothing`.** La lista vacía de vacas y la de caballos son **la misma lista**: ninguna tiene elementos. Para escribirla una sola vez hace falta un tipo de elemento que sea subtipo de `Vaca`, de `Caballo` y de todo lo demás, y ese tipo existe: `Nothing`, el que está abajo de todo (clase anterior). `MiLista[Nothing]` es "una lista cuyos elementos son de un tipo que ningún valor tiene", es decir, una lista que **garantiza** estar vacía. Y por la covarianza, `Nothing <: Vaca` implica `MiLista[Nothing] <: MiLista[Vaca]`:

```scala
  val vacas: MiLista[Vaca] = Vacia          // ✅ MiLista[Nothing] es MiLista[Vaca]
  val caballos: MiLista[Caballo] = Vacia    // ✅ y también MiLista[Caballo]
```

Es exactamente lo que la clase anterior mostró con `List()`, que es `List[Nothing]` y entra en cualquier variable de lista. Ahí lo viste desde afuera; acá lo escribiste. Y es el hilo que faltaba cerrar: sin covarianza, el truco se cae:

| Escribís | Scala entiende | Sale |
|---|---|---|
| `val vacas: MiLista[Vaca] = Vacia` con `MiLista[+T]` | la vacía como lista de vacas | ✅ `MiLista[Nothing] <: MiLista[Vaca]` |
| lo mismo con una `MiListaInv[T]` invariante y `VaciaInv extends MiListaInv[Nothing]` | ídem | ❌ `Found: VaciaInv.type / Required: MiListaInv[Vaca]` |

Con invarianza haría falta una vacía por cada tipo. La covarianza es lo que permite **un** `Vacia` para todas.

`Vacia.head` lanza `NoSuchElementException`: es la operación parcial de la clase anterior (`List().head`), escrita por vos. Su tipo de retorno es `Nothing`, el tipo de "esto nunca devuelve", y por eso cumple el contrato `def head: T` para cualquier `T`.

## 2. 🔴 Cada operación la resuelve quien sabe: polimorfismo

> Cada método está **declarado** en `MiLista` y **resuelto** en `Vacia` y en `Nodo`, cada uno a su manera. Ninguna implementación pregunta "¿estoy vacía?": la pregunta la responde el despacho del mensaje.

Es la regla de diseño de objetos de las primeras clases, aplicada a esta estructura. Mirá `length`: `Vacia` responde `0`; `Nodo` responde `1 + cola.length`. La recursión no tiene un `if (isEmpty)` porque el caso base **es un objeto distinto** que responde distinto. Lo mismo `contains`, `filter`, `map`, `concat`, `foreach`. Si en algún método te encontrás escribiendo `if (lista.isEmpty) … else …`, hay un objeto que debería estar respondiendo eso.

Una sola operación es concreta en la clase abstracta, `add`, porque es idéntica en los dos casos: "un nodo nuevo con `elem` adelante de mí".

**El `add` del Módulo 7, resuelto e inferido:**

```scala
  val vacas: MiLista[Vaca] = Vacia.add(new Vaca).add(new VacaLoca)
  val animales: MiLista[Animal] = vacas
  val conCaballo: MiLista[Animal] = animales.add(new Caballo)         // una lista NUEVA; la original sigue igual

  println(vacas.length)                                               // Resultado: 2
  println(conCaballo.length)                                          // Resultado: 3
  println(vacas.contains(new Caballo))                                // Resultado: false
```

Las tres primeras líneas compilan por lo que ya sabés: `add[U >: T]` acepta la vaca loca y el caballo, y la covarianza deja ver `vacas` como `MiLista[Animal]`. El `contains(new Caballo)` compila por `[U >: T]` y responde `false`. Y la cadena de inferencia sobre `Vacia`, que es `MiLista[Nothing]`: `Vacia.add(new Vaca)` tiene `T = Nothing`, `U >: Nothing` con una vaca, así que `U = Vaca`; el resultado es `MiLista[Vaca]`. El `.add(new VacaLoca)` sobre eso: `U >: Vaca` con una vaca loca; `U = Vaca`. Si en vez de una vaca loca fuera un caballo, `U` subiría a `Animal`. El lower bound calculando el tipo común en cada paso.

```scala
  val gordita: Vaca = new Vaca
  gordita.peso = 150
  val vacas: MiLista[Vaca] = Vacia.add(new Vaca).add(gordita)

  println(vacas.head eq gordita)                           // Resultado: true   ← add pone adelante
  println(vacas.filter(_.estaGordo).length)                // Resultado: 1
  vacas.map(_.peso).foreach(println)                       // Resultado: 150, después 100
  println(vacas.concat(Vacia.add(new Caballo)).length)     // Resultado: 3   ← y es una MiLista[Animal]
```

Los tests 20 a 23 de `GranjaTest.scala` verifican todo esto: `add` deja la original igual, la covarianza de `MiLista`, `contains`/`filter`/`map`/`concat`/`foreach`, y que `Vacia.head` falla.

> **Para el parcial, si te preguntan**
> *¿Cómo se escribe una lista inmutable covariante en Scala sin pattern matching?* — Una clase abstracta `MiLista[+T]` que declara las operaciones; un `object Vacia extends MiLista[Nothing]` para el caso vacío, que gracias a `Nothing` y a la covarianza sirve como lista de cualquier tipo; y una clase `Nodo[+T](primero: T, cola: MiLista[T])` para el caso con elementos. Cada operación la resuelve cada caso por polimorfismo, sin preguntar si la lista está vacía. Los métodos que reciben un elemento usan `[U >: T]` y devuelven `MiLista[U]`, el tipo común.

## 3. 🔴 Hasta dónde llega la teoría: `contains` sería seguro

> `contains(elem: T)` en una lista covariante **jamás podría explotar**: solo compara con `==`, que todo objeto entiende. El compilador lo rechaza igual, porque la regla de posiciones mira la firma y no distingue un uso inofensivo de uno peligroso. Es un **falso negativo que la teoría actual no sabe evitar**.

```scala
class MiLista[+T](primero: T, cola: MiLista[T]) {
  def contains(elem: T): Boolean = elem == primero
  //           ^^^^^^^
  // ❌ covariant type T occurs in contravariant position in type T of parameter elem
}
```

Mirá el cuerpo: `elem == primero`. La igualdad es un mensaje de `Any`; cualquier cosa que entre como `elem` lo entiende. Aunque una `MiLista[Vaca]` vista como `MiLista[Animal]` reciba un caballo, comparar un caballo con una vaca da `false` y sigue. **Todo programa posible con ese `contains` termina bien**, y el compilador lo rechaza igual.

**Por qué no puede hacer otra cosa.** La regla "un `T` en un parámetro es posición contravariante" es una regla sobre **firmas**. Para dejar pasar este `contains`, el compilador tendría que mirar el **cuerpo**, ver que solo usa `==`, y además garantizar que ninguna subclase redefina `contains` con algo más (el escenario de ruptura del Módulo 7). Eso es razonar sobre comportamiento, y los tipos razonan sobre firmas. Un sistema de tipos que acepte este caso con fundamento, sin aceptar también los peligrosos, es hoy **tema de investigación**. Dicho sin vueltas: todavía se desconoce cómo hacerlo mejor.

Ese es el límite de la unidad, y conviene tenerlo claro porque cambia cómo leés los errores de varianza: no todos señalan un peligro real. Algunos señalan un programa válido que el chequeador rechaza por falta de herramientas, el falso negativo de la clase anterior, en su versión más fina. La salida práctica es la de siempre: `[U >: T]`, que compila, es segura, y paga una garantía débil (Módulo 8).

🕳️ **Madriguera — sistemas de efectos.** Una línea de investigación para aceptar casos como este es que el tipo de un método diga también qué **efectos** tiene (si modifica algo, si llama a otros métodos); con eso, un `contains` que solo compara podría probarse inofensivo. *Volvé al camino — esto se profundiza aparte, otro día.*

## 4. 🟡 Bounds y varianza en un mismo tipo

> Un parámetro puede tener bound y varianza a la vez, y un tipo puede tener parámetros con combinaciones distintas: `Foo[+T <: Vaca, -R >: Animal]`.

```scala
class Foo[+T <: Vaca, -R >: Animal]

  val foo: Foo[Vaca, Animal] = new Foo[VacaLoca, Any]     // ✅ T sube de VacaLoca a Vaca (+); R baja de Any a Animal (−)
  val mal: Foo[Animal, Animal] = ???
  // ❌ Type argument tadp.granja.Animal does not conform to upper bound tadp.granja.Vaca
```

`T` es covariante **dentro** del tramo que el bound permite (`Vaca` y sus subtipos); `R` es contravariante **dentro** de los supertipos de `Animal`. El bound dice qué argumentos se aceptan; la varianza dice cómo se relacionan dos `Foo` con argumentos distintos. Son las dos preguntas del Módulo 5, sobre cada parámetro por separado.

## 5. 🔴 La guía de decisión para el TP

> Ante un tipo paramétrico nuevo, tres preguntas, en orden: **¿bound?**, **¿signo?**, **¿cómo recibo un `T`?**. Y una regla práctica: poné lo que querés y leé los errores.

| Pregunta | Si… | Entonces |
|---|---|---|
| **1. ¿Necesito mandarle mensajes a `T` adentro?** | sí (`estaGordo`, `come`, …) | upper bound: `T <: Animal`. Sin bound, `T` solo entiende `Any` |
| **2. ¿`T` entra, sale, o las dos cosas?** | solo **sale** (retornos, `val`) | `+T` (una colección inmutable, un productor) |
| | solo **entra** (parámetros) | `-T` (un `Printer`, un `Veterinario`, un consumidor) |
| | entra **y** sale | sin signo (invariante), **o** `+T` con los métodos que reciben `T` escritos como en la pregunta 3 |
| **3. Tengo `+T` y un método tiene que recibir un `T`.** | | `def m[U >: T](x: U): …`, y si adentro hace falta hablar de `Animal`: `[U >: T <: Animal]`. El resultado se expresa en `U` |

**La regla práctica.** Declarar la varianza que querés y dejar que el compilador diga dónde falla es un método legítimo. Cada error de posición dice exactamente **qué** `T` está en **qué** posición; con la tabla de signos del Módulo 7 se lee de corrido. Lo que hay que saber de memoria es poco: `+` donde sale, `-` donde entra, `[U >: T]` para recibir en un `+`, `List` covariante y `Set` invariante, y que el bound y la varianza son dos preguntas distintas.

**Lo que ningún signo arregla.** Si un tipo necesita que un método reciba exactamente `T` y lo trate como `T` (una colección mutable, un `add` que ordeña lo que recibe), **es invariante**, y es correcto que lo sea. La varianza es una herramienta para los tipos que pueden pagarla, y una colección mutable, por diseño, es de las que no.

### Ejercicio 1: un veterinario

*Aparece `Veterinario[T <: Animal] { def atender(t: T): Unit }`, con un `VeterinarioGeneral extends Veterinario[Animal]` que hace comer a cualquier animal. Querés usarlo donde se pide un `Veterinario[Vaca]`. ¿Qué le ponés?*

Las tres preguntas: (1) sí, `atender` usa mensajes de animal → `T <: Animal`, ya está. (2) `T` solo **entra** (parámetro de `atender`) → `-T`. (3) no aplica: con `-T`, recibir `T` es la posición correcta.

```scala
trait Veterinario[-T <: Animal] {
  def atender(t: T): Unit
}

class VeterinarioGeneral extends Veterinario[Animal] {
  def atender(t: Animal): Unit = t.come
}

class VeterinarioDeVacas extends Veterinario[Vaca] {
  def atender(t: Vaca): Unit = t.ordeñate
}

  val deVacas: Veterinario[Vaca] = new VeterinarioGeneral      // ✅ contravarianza: atiende cualquier animal, luego cualquier vaca
  val unaVaca: Vaca = new Vaca
  deVacas.atender(unaVaca)
  println(unaVaca.peso)                                         // Resultado: 110
```

| Escribís | Scala entiende | Sale |
|---|---|---|
| `val deVacas: Veterinario[Vaca] = new VeterinarioGeneral` con `-T` | un veterinario de animales como veterinario de vacas | ✅ |
| `val general: Veterinario[Animal] = new VeterinarioDeVacas` | un veterinario de vacas como veterinario de animales | ❌ `Found: VeterinarioDeVacas / Required: Veterinario[Animal]`: le pasarían un caballo y lo ordeñaría |
| `trait Veterinario[+T <: Animal] { def atender(t: T): Unit }` | el signo equivocado | ❌ `covariant type T occurs in contravariant position in type T of parameter t` |

Es `Printer[-T]` con otro nombre; el punto es reconocer la forma: **un tipo que solo consume `T` es contravariante**.

### Ejercicio 2: agregar a un corral covariante

*Aparece `def agregar(a: T): Corral[T]` en `Corral[+T <: Animal]`. No compila. ¿Qué le ponés, y de qué tipo es el corral que devuelve si a un corral de vacas le agregás un caballo?*

Pregunta 3: `+T` y un método que recibe `T`. Y adentro, construir un corral con `a` en la lista pide que `a` sea un animal: `[U >: T <: Animal]`.

```scala
class Corral[+T <: Animal](val animales: List[T]) {
  def agregar[U >: T <: Animal](a: U): Corral[U] = new Corral(a :: animales)
}

  val corralDeVacas: Corral[Vaca] = new Corral(List(new Vaca))
  val conOtraVaca: Corral[Vaca] = corralDeVacas.agregar(new Vaca)      // U = Vaca; en la línea siguiente, U = Animal
  val conCaballo = corralDeVacas.agregar(new Caballo)
  println(conCaballo.animales.size)                             // Resultado: 2
```

`a :: animales` es el `prepended` del Módulo 8 en su forma corta. Un corral de vacas más un caballo es un corral de animales: el tipo común, calculado por el lower bound, en un corral **nuevo**; `corralDeVacas` sigue siendo un `Corral[Vaca]` con una vaca. Es el `cruzar` del Módulo 8 y el `add` de `MiLista`: la misma plantilla.

> **Para el parcial, si te preguntan**
> *Te dan un tipo paramétrico nuevo del dominio. ¿Cómo decidís el bound, el signo y la firma de los métodos que reciben `T`?* — Bound: si adentro le mando mensajes a `T`, `T <: X` con el `X` que los tenga. Signo: si `T` solo sale (retornos, `val`), `+T`; si solo entra (parámetros), `-T`; si entra y sale, invariante, o `+T` con los métodos que reciben `T` escritos como `[U >: T](x: U)` y devolviendo en términos de `U` (con `<: X` si adentro hace falta el bound). Después, compilar y leer cada error de posición: dice qué `T` está en qué posición, y la regla de los signos lo resuelve.

## 6. 🟢 Qué cambió en el TP

> Todo lo que la segunda mitad de la materia construye sobre Scala usa tipos paramétricos. Esta unidad te dio el criterio para escribirlos; lo que sigue te da más herramientas para usarlos.

Con esta unidad, los tipos paramétricos del TP se leen y se escriben con criterio: cada `[T]` tiene su bound o su razón para no tenerlo, cada `+` y cada `-` tiene su porqué, y cada método que recibe `T` en un tipo covariante lleva su `[U >: T]`. Y cuando el compilador rechace algo, vas a saber distinguir las tres situaciones: un peligro real (el caballo), una restricción de firma que se resuelve con `U`, y un límite de la teoría que se acepta y se rodea.

El código final de la unidad (`fuente-repo-clase08-type-arguments-y-varianza.md`) tiene todo lo que construiste en los Módulos 1 a 9, compilable y con sus 23 tests. Los checkpoints de los nueve módulos, hechos de corrido sin mirar, son el repaso.

---

## Checkpoint (sin respuestas)

1. ¿Por qué `Vacia` es `MiLista[Nothing]`? ¿Qué dos cosas hacen falta para que sirva como `MiLista[Vaca]`?
2. ¿Qué pasa con `Vacia` si `MiLista` fuera invariante?
3. ¿Dónde está la recursión de `length` y por qué no tiene un `if`? ¿Qué objeto responde el caso base?
4. Seguí la inferencia de `Vacia.add(new Vaca).add(new Caballo)` paso a paso. ¿De qué tipo es el resultado?
5. `contains(elem: T)` en `MiLista[+T]` sería seguro y se rechaza. ¿Por qué el compilador no puede aceptarlo? ¿Qué clase de error es, en términos de la clase anterior?
6. ¿Qué dice `Foo[+T <: Vaca, -R >: Animal]` de cada parámetro?
7. Enunciá las tres preguntas de la guía y qué respuesta lleva a `+`, a `-` y a invariante.
8. `Veterinario[T <: Animal] { def atender(t: T) }`: ¿qué signo lleva y por qué? ¿Qué pasa si le ponés `+`?
9. `agregar(a: T): Corral[T]` en `Corral[+T <: Animal]`: firma correcta, y tipo de `corralDeVacas.agregar(new Caballo)`.
10. ¿Qué tipo de los que viste en la unidad es correcto que sea invariante, y por qué?

## Qué viene después

Esta fue la última pieza de la unidad. La clase siguiente toma estas mismas estructuras (listas, corrales, casos vacíos y con elementos) y les da otra forma de escribirse y de recorrerse: pattern matching y case classes, con la inmutabilidad como tema central. La lectura previa es el patrón Visitor, que es justamente la forma de recorrer una estructura como `MiLista` desde afuera.

**FIN DEL MÓDULO 9 — FIN DE LA CLASE DESDE CERO**
