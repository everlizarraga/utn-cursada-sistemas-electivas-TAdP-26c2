# Clase desde cero — Type arguments y varianza en Scala — Módulo 6: Varianza II: funciones, y la contravarianza

**Unidad:** clase08 · **Lenguaje:** Scala 3.3.1 · **Densidad:** 🔴 pide una sesión con el código abierto

---

## Sobre este documento

**Qué cubre.** Una variable `f: Vaca => Vaca` y cinco funciones candidatas a guardarse en ella. Qué es ese tipo (`Function1[Vaca, Vaca]`, un tipo paramétrico con dos parámetros), y para cada función si entra o no, con la implementación que explotaría si el compilador cediera. De ahí salen las dos reglas: el tipo del **resultado** es covariante y el tipo del **parámetro** es **contravariante**: va al revés. Por qué es así (la intuición de promesa y necesidad), cómo está escrito en la biblioteca (`Function1[-T1, +R]`), un segundo tipo contravariante que no es una función (`Printer[-T]`), un tipo con un parámetro de cada clase (`Map[K, +V]`), y el cuadro de las tres varianzas.

**Qué no cubre.** Qué pasa cuando vos ponés `+` o `-` en un tipo propio: eso tiene un precio, y es el Módulo 7.

## De dónde venís

Del Módulo 5: varianza; invarianza y covarianza con su notación; "dirección" en vez de "es subtipo de"; `List[+A]`; un `Set` es también una función. Del Módulo 2: `A => Boolean` es el tipo de una función de `A` a `Boolean`. De la clase anterior: una función anónima `{ a => a.aprobo }` (M8). De Paradigmas: las funciones de Haskell reciben un parámetro y pueden devolver otra función.

---

## 1. 🔴 `Vaca => Vaca` es un tipo paramétrico con dos parámetros

> El tipo de una función de un parámetro se escribe `A => B` y es azúcar para **`Function1[A, B]`**: un tipo paramétrico con dos parámetros, el del argumento y el del resultado.

```scala
  val identidad: Vaca => Vaca = (v: Vaca) => v     // una función que recibe una Vaca y devuelve esa misma Vaca

  var f: Vaca => Vaca = identidad                  // una variable de tipo "función de Vaca a Vaca"
  var fSinAzucar: Function1[Vaca, Vaca] = identidad   // exactamente el mismo tipo, sin azúcar
  var fAlias: Function[Vaca, Vaca] = identidad     // un alias de Function1 que también existe
```

`(v: Vaca) => v` es una función anónima que devuelve lo que recibe; el tipo del parámetro se puede omitir (`v => v`) porque la anotación `Vaca => Vaca` ya lo fija, y va escrito para que se lea. Las tres variables tienen el mismo tipo. `Function1` es el tipo de las funciones de un parámetro, y como todo tipo paramétrico necesita sus argumentos: `Function1[Vaca, Vaca]`. `Vaca => Vaca` es la forma que vas a leer y escribir siempre; `Function1[Vaca, Vaca]` es lo que es. (`Function` es un alias viejo del mismo tipo; aparece en código de otros y nada más.)

El truco del Módulo 2 lo confirma:

```scala
  val n: Int = f
  // ❌ Found:    (f : tadp.granja.Vaca => tadp.granja.Vaca)
  //    Required: Int
```

La pregunta del módulo es la del Módulo 5, con dos parámetros en vez de uno: ¿cómo varía `Function1[P, R]` cuando varían `P` y `R`? Como `Function1` tiene dos, la respuesta puede ser distinta para cada uno, y lo es.

🕳️ **Madriguera — `Function1`, `Function2`, … `Function22`.** Hay una clase por cada cantidad de parámetros: `Function2[A, B, R]` para dos, y así hasta 22. En Haskell toda función recibe un parámetro y devuelve, si hace falta, otra función (currificación); Scala puede escribir las dos formas. *Volvé al camino — esto se profundiza aparte, otro día.*

## 2. 🔴 Cinco funciones candidatas

> Una función se puede guardar en `f: Vaca => Vaca` solo si **su tipo es subtipo de `Vaca => Vaca`**. Con cinco funciones que difieren en el parámetro o en el resultado, el compilador acepta tres y rechaza dos.

Las candidatas, con cuerpos que hacen algo, porque los cuerpos son los que explican los rechazos. Son métodos (`def`); al guardar uno en `f`, Scala lo envuelve como función, así que se juzgan por su tipo `parámetro => resultado`:

```scala
  def g(vaca: Vaca): Vaca = vaca                 // recibe una Vaca y devuelve una Vaca

  def h(vaca: Vaca): Animal = new Caballo        // devuelve un Animal

  def i(vaca: Vaca): VacaLoca = {                // devuelve una VacaLoca
    vaca.ordeñate
    new VacaLoca
  }

  def j(vacaLoca: VacaLoca): Vaca = {            // recibe una VacaLoca
    vacaLoca.reite
    vacaLoca.ordeñate
    vacaLoca
  }

  def k(animal: Animal): Vaca = {                // recibe un Animal
    animal.come
    new Vaca
  }
```

Y el uso que `f` va a tener, que es lo que hay que proteger:

```scala
  f(new Vaca).ordeñate       // a f se le pasa una Vaca, y a lo que devuelve se le manda ordeñate
```

Dos cosas tienen que ser ciertas para que esa línea sea segura: la función guardada en `f` tiene que **aceptar una `Vaca`** como argumento, y lo que devuelve tiene que **entender `ordeñate`**. Cada candidata se juzga por esas dos.

### 2.1 `g`: mismo tipo

```scala
  f = g                       // ✅ Vaca => Vaca en una variable Vaca => Vaca
  val v1: Vaca = new Vaca
  println(f(v1) eq v1)        // Resultado: true   ← g devuelve la misma vaca
```

Caso base: todo tipo es subtipo de sí mismo. Y es el único caso **mudo** sobre varianza: el parámetro quedó igual que en `f`, así que la pregunta "¿en qué dirección varía?" todavía está vacía.

### 2.2 `h`: devuelve un `Animal`

```scala
  f = h
  // ❌ Found:    tadp.granja.Animal
  //    Required: tadp.granja.Vaca
```

Rechazada, y el error señala el resultado. **Por qué.** `h` devuelve un `Animal`, y su implementación devuelve un caballo, que es un animal válido. Si `f = h` compilara, `f(new Vaca).ordeñate` le mandaría `ordeñate` a un caballo. Es intuitivo: igual que un `Animal` queda afuera de una variable `Vaca`, una función que devuelve `Animal` queda afuera de una variable que promete devolver `Vaca`.

### 2.3 `i`: devuelve una `VacaLoca`

```scala
  f = i                       // ✅
  val v2: Vaca = new Vaca
  f(v2).ordeñate              // i ordeña la vaca que recibe y devuelve una vaca loca, que se ordeña también
  println(v2.peso)            // Resultado: 90
```

Aceptada. `i` devuelve una `VacaLoca`, que es una `Vaca`: lo que sale entiende `ordeñate` y todo lo que una vaca entiende. Una función que devuelve algo **más específico** que lo prometido cumple la promesa de sobra.

Con `h` e `i` ya tenés la regla del resultado: `Vaca => VacaLoca` es subtipo de `Vaca => Vaca`, y `Vaca => Animal` no. El subtipado de la función va **en el mismo sentido** que el del resultado: `VacaLoca <: Vaca` y `(Vaca => VacaLoca) <: (Vaca => Vaca)`. Eso es covarianza, la del Módulo 5. **Las funciones son covariantes en el tipo del resultado.**

### 2.4 `j`: recibe una `VacaLoca`

```scala
  f = j
  // ❌ Found:    (vacaLoca : tadp.granja.Vaca)
  //    Required: tadp.granja.VacaLoca
```

Rechazada, y el error señala el parámetro: dice que lo que llegaría es una `Vaca` y `j` exige una `VacaLoca`. Esto parece raro, porque `VacaLoca <: Vaca`, igual que en el caso de `i`. **Por qué no entra.** Mirá el cuerpo de `j`: le manda `reite` a lo que recibe, y puede hacerlo porque su parámetro es `VacaLoca`. Si `f = j` compilara, `f(new Vaca)` le entregaría a `j` una vaca común, y `vacaLoca.reite` explotaría: una vaca no se ríe.

Entonces `VacaLoca => Vaca` **no** es subtipo de `Vaca => Vaca`, aunque `VacaLoca <: Vaca`. La función **no es covariante en el parámetro**.

### 2.5 `k`: recibe un `Animal`

```scala
  f = k                       // ✅
  val v3: Vaca = new Vaca
  f(v3).ordeñate              // k hace comer a la vaca que recibe y devuelve una vaca nueva
  println(v3.peso)            // Resultado: 110
```

Aceptada. Y esto es lo que hay que detenerse a mirar: `k` recibe un `Animal`, que es **más general** que `Vaca`, y entra en una variable que recibe `Vaca`. **Por qué es seguro.** `f` solo va a recibir vacas (es `Vaca => Vaca`). A `k` le llegan vacas, y `k` las trata como animales: les manda `come` y cosas que todo animal entiende. Nada de lo que `k` hace con su parámetro puede fallar con una vaca, porque una vaca es un animal. `k` **pide menos** de lo que `f` garantiza.

Lo mismo con una función anónima, para ver que no depende de `def`:

```scala
  val k2: Animal => Vaca = { animal =>
    animal.come
    new Vaca
  }
  val f2: Function1[Vaca, Vaca] = k2   // ✅ Animal => Vaca es subtipo de Vaca => Vaca (acá sin azúcar)
  println(f2(new Vaca).peso)           // Resultado: 100
```

Entonces `Animal => Vaca` **es** subtipo de `Vaca => Vaca`, aunque `Vaca <: Animal`. La relación va **al revés** que la de los componentes: `Vaca <: Animal`, pero `(Animal => Vaca) <: (Vaca => Vaca)`. Eso es la tercera varianza.

| Escribís | Scala entiende | Sale |
|---|---|---|
| `f = g` con `g: Vaca => Vaca` | mismo tipo | ✅ |
| `f = h` con `h: Vaca => Animal` | devuelve algo más general | ❌ `Found: Animal / Required: Vaca` |
| `f = i` con `i: Vaca => VacaLoca` | devuelve algo más específico | ✅ resultado covariante |
| `f = j` con `j: VacaLoca => Vaca` | exige algo más específico | ❌ `Found: (vacaLoca : Vaca) / Required: VacaLoca` |
| `f = k` con `k: Animal => Vaca` | acepta algo más general | ✅ parámetro contravariante |
| `val g2: Animal => Vaca = f` con `f: Vaca => Vaca` | usar `f` donde se espera aceptar animales | ❌ `Found: Vaca => Vaca / Required: Animal => Vaca` |
| `val h2: Vaca => VacaLoca = f` | usar `f` donde se espera devolver vacas locas | ❌ `Found: Vaca => Vaca / Required: Vaca => VacaLoca` |

Las dos últimas filas son el espejo: `f` tampoco entra donde se pide una función que acepte más o devuelva más.

## 3. 🔴 Contravarianza: la relación que va al revés

> Un parámetro de tipo es **contravariante** cuando el subtipado del compuesto va **en sentido contrario** al del parámetro: si `A` es subtipo de `B`, entonces `T[B]` es subtipo de `T[A]`. Las funciones son contravariantes en el tipo del parámetro.

```
   A <: B
──────────────    →   Contravarianza:  si A es subtipo de B, T[B] es subtipo de T[A]
 T[B] <: T[A]
```

Con las flechas: `Vaca → Animal`, y `(Animal => Vaca) → (Vaca => Vaca)`. Se cruzan. Es lo que se vio con `k`. También se escribe con `A :> B` arriba y `T[A] <: T[B]` abajo: es la misma regla con los nombres cambiados de lado.

**Por qué: promesa y necesidad.** La intuición que hace que deje de ser raro. Cuando una función **devuelve**, te hace una promesa: "te doy una vaca". Devolver una vaca loca cumple esa promesa y más; devolver un animal cualquiera la rompe. Por eso el resultado va en el mismo sentido que el subtipado. Cuando una función **recibe**, el que tiene una necesidad es **ella**: "necesito que lo que me des sea una vaca loca, porque la voy a hacer reír". Vos, que llamás, estás del otro lado de esa necesidad. Una función que necesita menos (un animal cualquiera) se conforma con lo que vos le das; una que necesita más (una vaca loca) puede quedarse sin lo que precisa. **En el parámetro, el sentido se invierte** porque cambia quién exige a quién.

Otra forma de verlo, que vas a usar en el Módulo 7: el resultado es lo que **sale** de la función; el parámetro es lo que **entra**. Lo que sale varía con el subtipado; lo que entra, en contra. Algunos lenguajes escriben eso literalmente: `out` para covariante, `in` para contravariante.

**Dónde está escrito.** En la definición de `Function1`, en la biblioteca de Scala:

```scala
trait Function1[-T1, +R]
```

`-T1`: el parámetro es contravariante. `+R`: el resultado es covariante. Dos parámetros de tipo, dos varianzas distintas, en el mismo tipo. Es la precisión del Módulo 5: la varianza es **de cada parámetro**, y un tipo puede tener una por cada uno.

**Las tres, juntas.** Para `S <: T` y un tipo paramétrico `G`:

| Varianza | Anotación | Relación entre `G[S]` y `G[T]` | Ejemplo |
|---|---|---|---|
| Invarianza | `G[A]` | ninguna: `G[S]` y `G[T]` quedan sin relación entre sí | `Set[A]`, `Corral[T]` sin anotar |
| Covarianza | `G[+A]` | `G[S] <: G[T]`, mismo sentido | `List[+A]`, el resultado de una función |
| Contravarianza | `G[-A]` | `G[T] <: G[S]`, sentido contrario | el parámetro de una función |

Y la bivarianza (`G[S] <: G[T]` para todo `S`, `T`), que en Scala no existe.

> **Para el parcial, si te preguntan**
> *¿Por qué una función `Animal => Vaca` se puede guardar en una variable `Vaca => Vaca`, y una `VacaLoca => Vaca` no?* — Porque las funciones son contravariantes en el tipo del parámetro: lo que la variable garantiza entregar es una `Vaca`, y una función que acepta `Animal` se conforma con eso (pide menos), mientras que una que exige `VacaLoca` podría recibir una vaca común y hacerle algo que solo una vaca loca entiende (pide más). En el parámetro, el subtipado de la función va en sentido contrario al del tipo: `Vaca <: Animal` pero `(Animal => Vaca) <: (Vaca => Vaca)`. En el resultado va en el mismo sentido (covarianza): `Vaca => VacaLoca` sí entra, `Vaca => Animal` no.

## 4. 🔴 Un tipo contravariante que no es una función: `Printer[-T]`

> Cualquier tipo cuyo parámetro solo **entra** puede declararse contravariante. `Printer[-T]` sabe imprimir un `T`; un `Printer[Animal]` sirve donde se espera un `Printer[VacaLoca]`, porque imprimir un animal cualquiera incluye imprimir una vaca loca.

Es `Printer.scala` del proyecto de referencia:

```scala
package tadp.granja

abstract class Printer[-T] {
  def print(t: T): Unit
}

class AnimalPrinter extends Printer[Animal] {
  override def print(t: Animal): Unit =
    println(s"Este animal pesa: ${t.peso}")
}

class VacaLocaPrinter extends Printer[VacaLoca] {
  override def print(t: VacaLoca): Unit =
    println(s"Una vaca loca se ríe así: ${t.reite}")
}
```

`abstract class`, como en `List` (Módulo 5), es una clase que deja métodos sin cuerpo (`print`) para que las subclases los definan; se parece a un `trait` con un solo padre posible. `Printer[T]` es "algo que sabe imprimir un `T`": el parámetro de tipo aparece una sola vez, **como parámetro de `print`**. Entra, y nunca sale.

```scala
  var printer: Printer[VacaLoca] = new VacaLocaPrinter
  printer.print(new VacaLoca)              // Resultado: Una vaca loca se ríe así: Muajajajjaajja

  printer = new AnimalPrinter              // ✅ un Printer[Animal] donde se espera un Printer[VacaLoca]
  printer.print(new VacaLoca)              // Resultado: Este animal pesa: 100
```

La segunda asignación es contravarianza pura: `VacaLoca <: Animal`, y `Printer[Animal] <: Printer[VacaLoca]`. **Por qué es seguro.** `printer` es `Printer[VacaLoca]`, así que solo le van a pasar vacas locas. Adentro hay un `AnimalPrinter`, que sabe imprimir cualquier animal; una vaca loca es un animal; lo imprime como animal (su peso), con mensajes de `Animal` solamente. Lo que la variable promete recibir es más específico que lo que el objeto necesita. Misma lógica que `k`.

| Escribís | Scala entiende | Sale |
|---|---|---|
| `val p: Printer[VacaLoca] = new AnimalPrinter` con `Printer[T]` invariante | un printer de animales como printer de vacas locas | ❌ `Found: AnimalPrinter / Required: Printer[VacaLoca]` |
| lo mismo con `Printer[-T]` | ídem, contravariante | ✅ |
| `p.print(new Vaca)` con `p: Printer[VacaLoca]` | imprimir una vaca común por un printer de vacas locas | ❌ `Found: Vaca / Required: VacaLoca` (la variable solo acepta vacas locas, aunque adentro haya un `AnimalPrinter`) |
| `val p: Printer[Animal] = new VacaLocaPrinter` con `Printer[-T]` | un printer de vacas locas como printer de animales | ❌ `Found: VacaLocaPrinter / Required: Printer[Animal]`: le pasarían un caballo y `reite` explotaría |

Fijate en la tercera fila: la contravarianza deja lo que la variable acepta tal como la variable lo declara; es el objeto de adentro el que acepta más, y por eso está siempre a salvo. Es `GranjaApp3` del proyecto de referencia, y el test 19 lo verifica capturando lo que se imprime.

> **Para el parcial, si te preguntan**
> *Aparece `abstract class Printer[T] { def print(t: T): Unit }` y querés guardar un `AnimalPrinter` en una variable `Printer[VacaLoca]`. ¿Compila? ¿Qué le ponés y por qué?* — No compila: `Printer` es invariante por omisión. Se declara `Printer[-T]`: `T` solo entra (es el parámetro de `print`), y un printer que acepta cualquier animal sirve donde se espera uno de vacas locas, porque la variable solo le va a pasar vacas locas y una vaca loca es un animal. Al revés queda rechazado: un `VacaLocaPrinter` como `Printer[Animal]` recibiría un caballo y `reite` explotaría.

## 5. 🟡 Un tipo con una varianza por parámetro: `Map[K, +V]`

> Un tipo puede tener parámetros con varianzas distintas. `Map[K, +V]` (un diccionario de claves `K` a valores `V`) es covariante en los valores e invariante en las claves.

```scala
  val pesos: Map[String, Vaca] = Map("bessie" -> new Vaca)
  val animales: Map[String, Animal] = pesos               // ✅ V es covariante: Map[String, Vaca] <: Map[String, Animal]
  println(animales.size)                                  // Resultado: 1

  val porVaca: Map[Vaca, Int] = Map()
  val porAnimal: Map[Animal, Int] = porVaca
  // ❌ Found:    (porVaca : Map[tadp.granja.Vaca, Int])
  //    Required: Map[tadp.granja.Animal, Int]
```

(`Map("bessie" -> new Vaca)` construye un diccionario con una entrada; `->` separa clave y valor.) Los valores **salen** del mapa (cuando buscás por clave), así que varían como el resultado de una función. Las claves entran (al buscar por clave) y salen (al recorrer), y quedan invariantes. La varianza se decide **parámetro por parámetro**, mirando cómo se usa cada uno. Eso, dicho con precisión, es el Módulo 7.

## 6. 🟡 Lo que viene

> Ya sabés qué significa `+` y qué significa `-`. Lo que falta es qué pasa cuando los ponés **vos**.

El `+` de `List[+A]` y el `-` de `Function1[-T1, +R]` los escribió alguien, y el compilador se los aceptó. Si todo lo que hace falta para que `Corral[Vaca]` sea `Corral[Animal]` es un `+`, ¿por qué no ponerle `+` a todo? El Módulo 7 muestra que el `+` **se paga**: restringe dónde se puede usar `T` adentro de la clase, y la lista que vas a escribir para verlo choca con esa restricción en el primer método que reciba un `T`.

Los tests 15 a 18 de `GranjaTest.scala` verifican las cuatro funciones que importan: `i` y `k` entran en `Vaca => Vaca`; `h` y `j` **no compilan** ahí.

---

## Checkpoint (sin respuestas)

1. ¿Qué es `Vaca => Vaca` sin azúcar? ¿Cuántos parámetros de tipo tiene y qué representa cada uno?
2. Para `f(new Vaca).ordeñate`, ¿qué dos cosas tiene que cumplir la función guardada en `f`?
3. `h` devuelve `Animal` y se rechaza; `i` devuelve `VacaLoca` y entra. ¿Qué regla sale de ahí? ¿Cómo se llama?
4. `j` recibe `VacaLoca` y se rechaza. Escribí el programa que explotaría si entrara.
5. `k` recibe `Animal` y entra. ¿Por qué es seguro? ¿Qué pide `k` y qué garantiza `f`?
6. Enunciá la contravarianza con la notación formal y con flechas. ¿En qué se diferencia de la covarianza?
7. Explicá "promesa y necesidad". ¿Por qué el parámetro invierte el sentido?
8. ¿Qué dice `trait Function1[-T1, +R]`? ¿Qué significa que un tipo tenga dos varianzas?
9. ¿Por qué `Printer[Animal]` sirve como `Printer[VacaLoca]`? ¿Por qué `Printer[VacaLoca]` no sirve como `Printer[Animal]`?
10. Con `p: Printer[VacaLoca]` que adentro tiene un `AnimalPrinter`, ¿se puede `p.print(new Vaca)`? ¿Por qué?
11. ¿Qué varianza tiene cada parámetro de `Map[K, +V]` y por qué tiene sentido?

## Qué viene después

El Módulo 7 escribe una lista covariante desde cero, `MiLista[+T]`, y se topa con el error `covariant type T occurs in contravariant position`. Ahí se entiende el precio del `+`, las **posiciones** donde `T` puede y no puede aparecer, y para qué servía el lower bound del Módulo 4.

**FIN DEL MÓDULO 6**
