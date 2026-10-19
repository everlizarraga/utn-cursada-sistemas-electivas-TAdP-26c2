# Clase desde cero — Type arguments y varianza en Scala — Módulo 3: Corral, Pastor y Lechero: definir un tipo paramétrico

**Unidad:** clase08 · **Lenguaje:** Scala 3.3.1 · **Densidad:** 🔴 pide una sesión con el código abierto

---

## Sobre este documento

**Qué cubre.** El primer tipo paramétrico **propio** de la unidad. Un corral que guarda animales, un pastor que los lleva a pastar y un lechero que ordeña las vacas de un corral: el lechero choca con la misma pared que el `filter` del Módulo 2. Se prueba primero la salida obvia (un corral por especie) y se ve por qué es un callejón; después se define `Corral[T]`, se entiende qué es `T` (un nombre, con una trampa), qué significa que el corral sea "coherente por dentro", cómo infiere el compilador el argumento de tipo al construir uno, y qué rechaza. Al final queda una pregunta abierta: el pastor, que andaba, deja de andar.

**Qué no cubre.** Cómo evitar que exista un corral de números (Módulo 4) ni por qué el pastor deja de andar (Módulo 5).

## De dónde venís

Del Módulo 2: `Set[Animal]` es un tipo paramétrico con su argumento; `Set` solo es incompleto; `_.estaGordo` es la forma corta de una función de un parámetro. Del Módulo 1: una variable deja mandar solo los mensajes de su tipo declarado. De la clase anterior: `val` en un parámetro de clase lo convierte en atributo visible (M6), `extends` con argumentos para la superclase (M7), `object` como objeto único (M0), `???` como cuerpo pendiente (M6).

**Sobre el `Set` de este módulo.** Todo el código de este módulo y de los dos siguientes empieza con `import scala.collection.mutable.Set`: un conjunto al que se le pueden agregar elementos con `add`. (`import` trae un nombre definido en otro paquete para escribirlo sin el camino completo; sin esa línea, `Set` es el inmutable del Módulo 2. Este conjunto se imprime con el nombre de su implementación, `HashSet`.) Es necesario para el argumento del Módulo 5, y el Módulo 0 lo explica. El código final de la unidad usa el `Set` inmutable y `List`; el Módulo 5 anticipa el cambio a `List` y el Módulo 8 lo deja definitivo.

---

## 1. 🔴 El dominio crece: corral, pastor, lechero

> Un corral guarda un conjunto de animales. Un pastor lleva a pastar un conjunto de animales. Un lechero ordeña **todas las vacas de un corral**. Con el corral guardando `Set[Animal]`, el pastor anda y el lechero **no compila**.

La primera implementación, directa:

```scala
package tadp.granja

import scala.collection.mutable.Set

class Corral(val animales: Set[Animal])

class Pastor {
  def pastorear(animales: Set[Animal]): Unit = animales.foreach(_.come)
}

class Lechero {
  def ordeñar(corral: Corral): Unit = corral.animales.foreach(_.ordeñate)
  //                                                           ^^^^^^^^^^
  // ❌ value ordeñate is not a member of tadp.granja.Animal
}
```

El pastor compila y anda:

```scala
  val corralito = new Corral(Set(new Vaca, new Vaca, new Vaca))
  val pastor = new Pastor

  pastor.pastorear(corralito.animales)
  println(corralito.animales.toList.map(_.peso))    // Resultado: List(110, 110, 110)
```

(`map` aplica una función a cada elemento y devuelve la colección con los resultados, como en Haskell. `toList` convierte el conjunto en lista antes del `map`, porque un conjunto colapsa los valores repetidos: tres pesos de 110 en un conjunto son `HashSet(110)`.)

El lechero, no. **Por qué.** `corral.animales` es un `Set[Animal]`; lo que sale de ahí es `Animal` (Módulo 2); `ordeñate` es un mensaje de `Vaca`; regla del Módulo 1. El compilador tiene razón: nada le asegura que los animales de **ese** corral sean vacas. Y vos tenés razón también: el lechero solo tiene sentido con corrales de vacas.

Filtrar adentro del lechero "los que son vacas" tampoco sirve: lo que sale de filtrar un `Set[Animal]` es otro `Set[Animal]` (Módulo 2), y `ordeñate` sigue invisible. El problema es de tipo, y el filtro deja el tipo como estaba.

El problema, dicho con precisión, **es semántico**: en el dominio existen corrales de cualquier animal, pero a vos te importa distinguir un corral de vacas, porque con uno de vacas podés hacer algo (ordeñar) que con los demás no. Hoy el tipo `Corral` dice solo "corral". Falta una forma de decir **"corral de vacas"**.

## 2. 🔴 El callejón: un corral por especie

> La salida que primero se ocurre es una subclase por especie: `CorralDeVacas`, `CorralDeCaballos`, … Funciona a medias, se multiplica con cada especie, y además choca con dos errores que todavía no podés explicar.

Probalo, porque entender por qué se descarta es la mitad de entender `Corral[T]`:

```scala
import scala.collection.mutable.Set

class Corral(val animales: Set[Animal])

class CorralDeVacas(val animales: Set[Vaca]) extends Corral(animales)
//                                                         ^^^^^^^^
// ❌ Found:    (CorralDeVacas.this.animales : collection.mutable.Set[tadp.granja.Vaca])
//    Required: collection.mutable.Set[tadp.granja.Animal]
```

Primer choque. Vos le pasás a `Corral` un conjunto de vacas, que son animales, y el compilador dice que un conjunto de vacas **no sirve** donde se espera un conjunto de animales. Parece un error del compilador. Anotalo y seguí: es el tema del Módulo 5, y ahí vas a ver que tiene razón.

Lo que sí anda: si `CorralDeVacas` se define sin heredar de `Corral`, con `def ordeñar(corral: CorralDeVacas)` el lechero compila, porque ahí `animales` es `Set[Vaca]`. Esa es la mitad que funciona.

Supongamos por un momento que eso compilara. El plan sigue así: una clase por especie, y una fábrica que construya el corral correcto según lo que reciba:

```scala
class CorralDeVacas(val animales: Set[Vaca])
class CorralDeCaballos(val animales: Set[Caballo])
class CorralDeVacasLocas(val animales: Set[VacaLoca])

object VacasFactory {
  def build(vacas: Set[Vaca]): CorralDeVacas = new CorralDeVacas(vacas)
  def build(caballos: Set[Caballo]): CorralDeCaballos = new CorralDeCaballos(caballos)
  def build(vacasLocas: Set[VacaLoca]): CorralDeVacasLocas = new CorralDeVacasLocas(vacasLocas)
}
```

Un `object` con tres métodos del mismo nombre y distinto parámetro: el compilador elige por el tipo del argumento (sobrecarga). Esto compila. Segundo choque, que aparece apenas dos `build` devuelven el mismo tipo:

```scala
object VacasFactory {
  def build(vacas: Set[Vaca]): CorralDeVacas = new CorralDeVacas(vacas)
  def build(caballos: Set[Caballo]): CorralDeVacas = ???
  // ❌ Double definition: … have the same type after erasure.
}
```

"Después del borrado tienen el mismo tipo." `Set[Vaca]` y `Set[Caballo]` son distintos para el compilador y **el mismo** para la máquina que ejecuta. Anotalo también: es el Módulo 4, erasure.

| Escribís | Scala entiende | Sale |
|---|---|---|
| `class CorralDeVacas(val animales: Set[Vaca]) extends Corral(animales)` | un corral de vacas que es un corral de animales | ❌ `Found: Set[Vaca] / Required: Set[Animal]` (Módulo 5) |
| tres `build` con parámetros y retornos distintos | sobrecarga | ✅ compila |
| dos `build` con parámetros `Set[Vaca]` y `Set[Caballo]` y el mismo retorno | sobrecarga | ❌ `Double definition … have the same type after erasure` (Módulo 4) |

**Por qué es un callejón, aunque compilara.** Mirá las tres clases: `CorralDeVacas` es un corral con un `Set[Vaca]`, `CorralDeCaballos` es un corral con un `Set[Caballo]`, `CorralDeVacasLocas` es un corral con un `Set[VacaLoca]`. Es **la misma clase tres veces**, con una sola cosa distinta: el tipo de lo que contiene. Cada especie nueva pide una clase nueva y un `build` nuevo. Así se programaba hace veinticinco años, antes de que los lenguajes tuvieran lo que viene.

Y mirá el `Set`: también tiene el problema de "¿de qué es?", y está escrito **una sola vez**. No existen `SetDeVacas` y `SetDeCaballos`. Existe `Set[Vaca]` y `Set[Caballo]`: un solo `Set` que recibe el tipo por parámetro. El corral y el conjunto tienen el mismo problema; la solución del conjunto sirve para el corral.

## 3. 🔴 `Corral[T]`: el corral recibe el tipo por parámetro

> Un tipo paramétrico propio se define poniendo **un parámetro de tipo entre corchetes después del nombre de la clase**, y usando ese nombre adentro donde antes había un tipo concreto. `class Corral[T](val animales: Set[T])` es "un corral de `T`, que guarda un conjunto de `T`".

```scala
import scala.collection.mutable.Set

class Corral[T](val animales: Set[T])

class Pastor {
  def pastorear(animales: Set[Animal]): Unit = animales.foreach(_.come)
}

class Lechero {
  def ordeñar(corral: Corral[Vaca]): Unit = corral.animales.foreach(_.ordeñate)   // ✅
}
```

El lechero compila. Recibe un `Corral[Vaca]`; adentro, `corral.animales` es un `Set[Vaca]`; lo que sale es `Vaca`; `ordeñate` es de `Vaca`. Todo el camino está tipado.

### 3.1 `T` es un nombre

`T` es el **parámetro de tipo** del Módulo 2, visto desde adentro de la clase; con ese ángulo también se lo llama **variable de tipo**: un nombre que representa "el tipo que me van a pasar". Podría llamarse `A`, `Bicho` o `Elemento`; `T` es la convención. Lo único que importa es que es un nombre que **vos elegís** y que, adentro de la clase, ocupa el lugar de un tipo que todavía nadie fijó. Es la misma idea que un parámetro de función: `def come(cantidad: Int)` no sabe qué número va a recibir, y por eso usa el nombre `cantidad`. Acá no sabés qué tipo va a recibir el corral, y por eso usás `T`.

**La trampa.** Como es un nombre, podés elegirlo mal:

```scala
class Corral[Animal](val animales: Set[Animal]) {
  def bla(a: Animal): Animal = new Animal
  //                               ^^^^^^
  // ❌ Animal does not have a constructor
}
```

Acá `Animal` es el parámetro de tipo, no la clase `Animal`. Adentro de `Corral`, cada vez que escribís `Animal`, el compilador entiende "el tipo que me pasen, sea cual sea", y a eso es imposible hacerle `new`: el compilador desconoce qué es. La clase `Animal` quedó **tapada** por el nombre. (Se puede llegar a ella con el nombre completo, `tadp.granja.Animal`, pero es una incomodidad que se evita eligiendo otro nombre.) Por eso la convención es una letra: `T` deja la clase `Animal` a la vista.

### 3.2 `Corral` solo deja de existir

Apenas el corral tiene parámetro de tipo, **toda referencia a `Corral` a secas se rompe**:

```scala
class Lechero {
  def ordeñar(corral: Corral): Unit = corral.animales.foreach(_.ordeñate)
  //                  ^^^^^^
  // ❌ Missing type parameter for tadp.granja.Corral
}
```

Es la misma regla que `Set` en el Módulo 2: `Corral` solo es incompleto. Donde se usa, hay que decir corral **de qué**. Para el lechero, `Corral[Vaca]`.

### 3.3 Coherencia interna: el `T` tiene que usarse

Poner `[T]` y seguir guardando `Set[Animal]` adentro deja todo como estaba:

```scala
class Corral[T](val animales: Set[Animal])      // T declarado y sin usar

class Lechero {
  def ordeñar(corral: Corral[Vaca]): Unit = corral.animales.foreach(_.ordeñate)
  //                                                                 ^^^^^^^^^^
  // ❌ value ordeñate is not a member of tadp.granja.Animal
}
```

El `Corral[Vaca]` del lechero promete "corral de vacas", pero adentro `animales` sigue siendo `Set[Animal]`, y de ahí salen animales. Lo que hace funcionar al lechero es que **`animales` es `Set[T]`**: el tipo del contenido está atado al parámetro. Esa es la coherencia interna: el `T` del corchete y el `T` de adentro son el mismo nombre, y el compilador los une.

| Escribís | Scala entiende | Sale |
|---|---|---|
| `class Corral(val animales: Set[Animal])` + `ordeñar(corral: Corral)` | corral de animales; ordeñar lo que sale | ❌ `value ordeñate is not a member of Animal` |
| `class Corral[T](val animales: Set[T])` + `ordeñar(corral: Corral)` | corral de `T`; recibir un corral a secas | ❌ `Missing type parameter for Corral` |
| `class Corral[T](val animales: Set[Animal])` + `ordeñar(corral: Corral[Vaca])` | corral de `T` que guarda animales | ❌ `value ordeñate is not a member of Animal` |
| `class Corral[T](val animales: Set[T])` + `ordeñar(corral: Corral[Vaca])` | corral de `T` que guarda `T`; recibir un corral de vacas | ✅ |
| `class Corral[Animal](val animales: Set[Animal]) { … new Animal }` | parámetro que tapa a la clase | ❌ `Animal does not have a constructor` |

> **Para el parcial, si te preguntan**
> *¿Qué cambia entre `class Corral(val animales: Set[Animal])` y `class Corral[T](val animales: Set[T])`?* — El corral pasa a recibir por parámetro el tipo de lo que contiene, y lo usa para tipar su conjunto. Con eso, un `Corral[Vaca]` tiene un `Set[Vaca]` y lo que sale de él entiende `ordeñate`; con `Set[Animal]` fijo, lo que sale es `Animal` y `ordeñate` es inalcanzable. El `[T]` sirve solo si se usa adentro (`Set[T]`): declararlo y guardar `Set[Animal]` deja todo como estaba.

## 4. 🔴 Usarlo: cómo el compilador infiere el argumento

> Al construir un corral sin decir el tipo, el compilador **infiere el argumento de tipo a partir de lo que le pasás**, en cascada: el tipo de los elementos fija el del conjunto, el del conjunto fija el del corral, y el del corral fija el de la variable. La inferencia **es solo escritura**: todo esto funciona igual con cada tipo escrito a mano.

```scala
  val corralito = new Corral(Set(new Vaca, new Vaca, new Vaca))
  val lechero = new Lechero

  lechero.ordeñar(corralito)                                    // ✅
  println(corralito.animales.toList.map(_.peso))                // Resultado: List(90, 90, 90)
```

¿De qué tipo es `corralito`? El truco del Módulo 2:

```scala
  val n: Int = corralito
  // ❌ Found:    (corralito : tadp.granja.Corral[tadp.granja.Vaca])
  //    Required: Int
```

`Corral[Vaca]`, y nadie lo escribió. La cadena: `new Vaca` es `Vaca` → `Set(…)` de vacas es `Set[Vaca]` → `new Corral(…)` con un `Set[Vaca]` tiene que tener `T = Vaca`, así que es `Corral[Vaca]` → `corralito` es `Corral[Vaca]`.

La forma completa, con todo escrito a mano, es esta, y hace exactamente lo mismo:

```scala
  val corralito: Corral[Vaca] = new Corral[Vaca](Set[Vaca](new Vaca, new Vaca, new Vaca))
```

`new Corral[Vaca](…)` le pasa el argumento de tipo a mano; `Set[Vaca](…)` también. Escribilo así una vez para ver que **la inferencia es solo escritura**: te ahorra tipear, y eso es todo. Cada regla de esta unidad vale igual con o sin ella.

**Un caballo cambia todo el corral.** Si el conjunto trae un caballo, la cascada infiere otra cosa:

```scala
  val mixto = new Corral(Set(new Vaca, new Vaca, new Caballo))   // el compilador infiere Corral[Animal]
  lechero.ordeñar(mixto)
  // ❌ Found:    (mixto : tadp.granja.Corral[tadp.granja.Animal])
  //    Required: tadp.granja.Corral[tadp.granja.Vaca]
```

Vaca y caballo tienen en común `Animal` (Módulo 2); el conjunto es `Set[Animal]`; el corral es `Corral[Animal]`; el lechero quiere `Corral[Vaca]`. Rechazado, y con razón: hay un caballo adentro.

Y si vos fijás el tipo, el error se corre al caballo:

```scala
  val corralito: Corral[Vaca] = new Corral(Set(new Vaca, new Vaca, new Caballo))
  //                                                                ^^^^^^^^^^^
  // ❌ Found:    tadp.granja.Caballo
  //    Required: tadp.granja.Vaca
```

| Escribís | Scala entiende | Sale |
|---|---|---|
| `val c = new Corral(Set(new Vaca, new Vaca))` | inferí | ✅ `Corral[Vaca]` |
| `val c = new Corral(Set(new Vaca, new Caballo))` | inferí | ✅ `Corral[Animal]`; `lechero.ordeñar(c)` ❌ `Found: Corral[Animal] / Required: Corral[Vaca]` |
| `val c: Corral[Vaca] = new Corral(Set(new Vaca, new Caballo))` | un corral de vacas con un caballo | ❌ `Found: Caballo / Required: Vaca`, en el caballo |
| `val c: Corral[Vaca] = new Corral[Vaca](Set[Vaca](new Vaca))` | todo explícito | ✅ |

**¿Y después de construido?** El corral no tiene `add`: lo que tiene es el conjunto, y el conjunto sabe de qué es:

```scala
  val vacas1 = Set(new Vaca, new Vaca)                   // Set[Vaca], mutable
  val corralito: Corral[Vaca] = new Corral(vacas1)

  corralito.add(new Caballo)
  // ❌ value add is not a member of tadp.granja.Corral[tadp.granja.Vaca]

  vacas1.add(new Caballo)
  // ❌ Found:    tadp.granja.Caballo
  //    Required: tadp.granja.Vaca

  vacas1.add(new VacaLoca)                                // ✅ una vaca loca es una vaca
  println(corralito.animales.size)                        // Resultado: 3
```

El conjunto de vacas rechaza al caballo por la regla del Módulo 1: `add` recibe un `Vaca`, y un `Caballo` es otra cosa. Guardá este rechazo: en el Módulo 5 es la pieza central. Y una pregunta que te podés hacer ahora: ¿y si el conjunto fuera de animales? Ahí `add(new Caballo)` compila. Anotá eso también.

Lo que ganaste, dicho en una frase: un sistema de tipos *sound* (Módulo 1) rechaza al compilar lo que explotaría al correr. Antes, con `Set[Animal]` adentro, el lechero era imposible de escribir. Ahora el lechero existe, y meter un caballo en un corral de vacas es imposible de escribir. El error cambió de lugar: de "ordeñar es imposible" a "meter un caballo es imposible". Ese es el lugar correcto.

## 5. 🔴 El pastor deja de andar

> Con `Corral[T]`, el lechero anda y **el pastor, que andaba, deja de compilar**. El error dice que un `Set[Vaca]` no sirve donde se espera un `Set[Animal]`.

```scala
  val corralito: Corral[Vaca] = new Corral(Set(new Vaca))
  val pastor = new Pastor

  pastor.pastorear(corralito.animales)
  //               ^^^^^^^^^^^^^^^^^^
  // ❌ Found:    (corralito.animales : collection.mutable.Set[tadp.granja.Vaca])
  //    Required: collection.mutable.Set[tadp.granja.Animal]
```

Es el mismo error de la sección 2, con `CorralDeVacas extends Corral(animales)`. Antes `corralito.animales` era `Set[Animal]` y el pastor lo aceptaba. Ahora es `Set[Vaca]`, y el pastor, que pide `Set[Animal]`, lo rechaza. Las vacas son animales; un conjunto de vacas, según el compilador, **no es** un conjunto de animales.

Esto queda abierto. Es la pregunta del Módulo 5, y responderla es el tema de la unidad. Por ahora, el pastor se queda sin pastorear ese corral.

## 6. 🟡 Los métodos también pueden tener parámetros de tipo

> Un parámetro de tipo se puede poner también en un **método**, con la misma sintaxis: `def nombre[U](…)`. Vive solo durante esa llamada.

Lo dejás nombrado acá y lo vas a usar en el Módulo 7, donde hace falta. La idea es la misma: un método que recibe "algo de tipo `U`" sin saber cuál, y `U` se fija en cada llamada.

## 7. 🟡 Lo que viene

> `T` hoy es **cualquier cosa**. Un corral de números compila.

```scala
  val corralRaro = new Corral(Set(1, 2, 3))     // ✅ compila: Corral[Int]
  println(corralRaro.animales)                   // Resultado: HashSet(1, 2, 3)
```

Nada en `Corral[T]` dice que `T` tenga que ver con animales. Al ganar la flexibilidad del parámetro, se perdió la restricción que el dominio pedía. El Módulo 4 la recupera.

Los tests 6 y 7 de `GranjaTest.scala` verifican al lechero y al pastor sobre la versión final del corral, la del Módulo 8; hasta el Módulo 5, el pastor sigue esperando.

---

## Checkpoint (sin respuestas)

1. ¿Por qué `corral.animales.foreach(_.ordeñate)` falla con `class Corral(val animales: Set[Animal])`? ¿Quién tiene razón, el compilador o vos? Justificá las dos.
2. ¿Por qué una subclase por especie (`CorralDeVacas`, `CorralDeCaballos`, …) es un callejón, aun si compilara? ¿Qué tiene el `Set` que el corral no tenía?
3. Escribí `Corral[T]`. ¿Qué es `T`? ¿Por qué la convención es una letra y qué pasa si lo llamás `Animal`?
4. ¿Qué dice `Missing type parameter for Corral` y cuándo aparece?
5. `class Corral[T](val animales: Set[Animal])` con `ordeñar(corral: Corral[Vaca])` falla. ¿Por qué? ¿Qué quiere decir "coherencia interna"?
6. ¿De qué tipo es `new Corral(Set(new Vaca, new Vaca))`? ¿Y `new Corral(Set(new Vaca, new Caballo))`? Describí la cascada de inferencia en cada caso.
7. Escribí la forma completa, sin inferencia, de `val corralito = new Corral(Set(new Vaca))`. ¿Cambia algo en lo que el compilador chequea?
8. `vacas1.add(new Caballo)` con `vacas1: Set[Vaca]` se rechaza. ¿Con qué regla? ¿Qué pasaría con `vacas1: Set[Animal]`?
9. El pastor andaba con `Corral(Set[Animal])` y deja de andar con `Corral[T]`. ¿Qué dice el error? ¿Qué pregunta deja abierta?

## Qué viene después

El Módulo 4 arranca con el corral de números y con un método `gordos` que el corral quiere tener y no puede escribir, porque `T` es cualquier cosa. La herramienta que lo resuelve se llama **type bound**: un límite para `T`.

**FIN DEL MÓDULO 3**
