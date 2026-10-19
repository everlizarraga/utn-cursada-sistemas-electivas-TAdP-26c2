# Código final unificado — clase08 — Type arguments y varianza en Scala

> **Qué es este archivo.** El código completo y funcional de la unidad `clase08` (sábado 17-Oct-2026), en **un solo estado final**, escrito para **Scala 3.3.1**, sbt 1.9.0 y ScalaTest 3.2.19 (las versiones del repo del TP). Es la referencia sobre la que se apoya todo el material de la unidad: lo que figura acá es lo que se pega y corre. Las etapas intermedias de la clase (el corral sin parámetro de tipo, los corrales por especie, el `Set` mutable, el `contiene` que no compila) no están acá; son tema de la clase desde cero y del código impreso.
>
> **Qué no es.** No es una copia fiel de ningún repositorio de la cátedra: es una **unificación** de lo que se escribió en la clase presencial, completada con el video 2020, el script y el repo de cátedra donde la clase dejó algo sin cerrar, y adaptada a 3.3.1.
>
> **Generado:** 19-Oct-2026 · **Estado:** revisado en segunda pasada por un revisor independiente y en tercera pasada propia · **Compilación:** verificada con el compilador real de **Scala 3.3.1** (`scalac -deprecation -feature -Werror`): 0 errores, 0 advertencias; las tres apps corren; los 23 tests pasan. Ver "Verificación" más abajo para el detalle y la única limitación.

## Procedencia y adaptaciones

| Archivo | De dónde sale | Adaptaciones declaradas |
|---|---|---|
| `build.sbt`, `project/build.properties` | Versiones del repo del TP (3.3.1 / 1.9.0 / 3.2.19). El repo de cátedra `scala-granja` está en 3.7.0 / sbt 1.11.0 | Nombre del proyecto propio; paquete `tadp.granja` en vez de `granja`, como en la unidad anterior |
| `Animales.scala` | **Repo de cátedra** `scala-granja`, idéntico a lo que se vio en la presencial y en 2020 | Anotaciones de tipo explícitas (`var peso: Int`, `def come: Unit`, `def estaGordo: Boolean`, …). El identificador `ordeñate` se mantiene con `ñ`, como lo escribe la cátedra |
| `Granero.scala` | **Repo de cátedra** (`var granos = 10000`); en la presencial y en 2020 solo se vio su nombre | Tipo explícito. Se usa en el test del `Set[Animal]` que rechaza un granero |
| `Aves.scala` | **Video 2020**, slide 5 (`Avestruz` que redefine `vola` con `throw new UnsupportedOperationException`). La presencial no lo mostró; entra porque todo lo que enriquece la unidad se unifica | Cuerpos de `vola`, `come` y `meteLaCabezaBajoTierra` (la slide solo tenía las firmas) |
| `Corral.scala` | **Clase presencial**, estado final (fotos 47 y 48): `Corral[+T <: Animal](val animales: List[T])`, `gordos: List[T]`, `contiene[U >: T](…) = animales.contains(…)`; `Pastor` con `List[Animal]`; `Lechero` con `Corral[Vaca]` | Parámetro `coso` → `elem`. Tipo de retorno `Unit` explícito en `pastorear` y `ordeñar`. El método `cruzar(toro: T)` de la foto 47 no entra: la clase lo escribió para mostrar el error y lo borró en la foto 48 |
| `MiLista.scala` | **Clase presencial** (fotos 37 a 45): `MiLista[+T](primero: T, cola: MiLista[T])` con `head`, `tail`, `filter(f: T => Boolean)`, `map[U](f: T => U)`, `concat[U >: T](otra: MiLista[U])` y `contains` | **Completada para que sea una lista de verdad.** La clase la dejó como un solo nodo, sin caso vacío, con `add(elem: T)` comentado porque no compila y `contains(elem: T)` con error (foto 45). Acá: `MiLista[+T]` abstracta, `Vacia` (`MiLista[Nothing]`, como `Nil`) y `Nodo(primero, cola)` con los nombres de la clase; `add[U >: T]` y `contains[U >: T]` resueltos con el mismo lower bound que la clase usó para `concat`; `isEmpty`, `length` y `foreach` agregados. Cada operación la resuelve `Vacia` o `Nodo` por polimorfismo, sin `if (isEmpty)` en la clase base. Nombres en inglés, como los que la clase eligió (`head`, `tail`, `filter`, `map`, `concat`, `contains`, `add`) |
| `Printer.scala` | **Repo de cátedra** `GranjaApp3.scala` (completo) = script = video 2020 | Sacado del `object GranjaApp3` a nivel de paquete, en archivo propio |
| `GranjaApp.scala` | **Repo de cátedra** `GranjaApp.scala` (repaso, colecciones, corral) + presencial (fotos 1–4, 14–18, 25–31) + 2020 (`List[Animal] = List[Vaca]`) | Solo quedan las líneas que compilan. Lo que en clase se escribió para ver el error (`vaca.reite`, el granero en el `Set[Animal]`, `Set[Animal] = Set[Vaca]`, `corralRaro`, `animales.add(new Caballo)`) vive en los `assertTypeError` del test, no acá. El `Set` es el inmutable de Scala (la clase usó `scala.collection.mutable.Set`); el "agregar un caballo" se hace sobre `List`, construyendo una lista nueva (`:+`), que es lo que la clase concluyó |
| `GranjaApp2.scala` | **Repo de cátedra** `GranjaApp2.scala` (firmas de `g` a `k` con `???`) + 2020 (cuerpos de `h`, `i`, `j`, `k`, `k2` y `f2`) + presencial (foto 35: 🟢 `g`, `i`; 🔴 `h`, `j`) | Cuerpo de `g` (`vaca`). `h` y `j` quedan definidas y comentadas como "no entra en `f`": las asignaciones `f = h` y `f = j` están en el test como `assertTypeError`. `f2` tipado como `Function1[Vaca, Vaca]` para mostrar qué es `Vaca => Vaca` |
| `GranjaApp3.scala` | **Repo de cátedra**, idéntico | Un `Printer[Animal]` usado con un caballo, además |
| `GranjaTest.scala` | **Propio.** La clase no escribió tests; cada test corresponde a algo que la clase afirmó o demostró | Los seis `assertTypeError` son el contenido central de la unidad: lo que el compilador rechaza y por qué |
| *Todos* | — | Anotaciones de tipo explícitas donde las fuentes las omitían. Sintaxis con llaves, como la cátedra. Sin `case class` ni pattern matching (son de la clase siguiente). `Nothing` aparece una sola vez, en `Vacia`, y es la misma razón por la que `List()` es `List[Nothing]` (clase anterior) |

## Verificación

**Compilación y ejecución**, con el compilador real de Scala 3.3.1 (`scalac -encoding UTF-8 -deprecation -feature -Werror`): los nueve archivos de `src/main` compilan con 0 errores y 0 advertencias; `GranjaApp`, `GranjaApp2` y `GranjaApp3` corren y producen la salida de abajo.

**Tests:** los 23 pasan. ScalaTest no estaba disponible en el entorno de verificación, así que el archivo de test se compiló (también con `-Werror`) y se ejecutó contra un reemplazo mínimo con la misma interfaz que usa (`AnyFunSuite` con `test` e `intercept`, `Matchers` con `shouldBe`, y `assertTypeError`, que en el reemplazo invoca al compilador real de 3.3.1 sobre el snippet y exige que parsee y que falle con un error de tipos). Los nombres y firmas son los de ScalaTest 3.2.19. **Única limitación declarada:** la macro `assertTypeError` de ScalaTest no se ejecutó como tal; los seis snippets sí fueron rechazados por el compilador con el error esperado (`Found/Required`, `Type argument Int does not conform to lower bound tadp.granja.Vaca`). Al correr `sbt test` en la máquina del estudiante se cierra esa diferencia.

**Verificado además en 3.3.1, fuera de este proyecto** (sirve para la clase desde cero): `class Corral[T >: VacaLoca <: Animal]` con los dos bounds a la vez **compila** (el video 2020 decía que no se podía; la presencial lo escribió y acá se confirma); `Corral[Caballo]` sobre esa definición falla con `Type argument Caballo does not conform to lower bound VacaLoca`; `class Foo[+T <: Vaca, -R >: Animal]` del script compila; `Set(new Vaca, new Caballo, new Granero)` sin anotación se infiere en Scala 3 como `Set[Vaca | Caballo | Granero]` (en 2020, con Scala 2, era `Set[Object]`), y `filter(_.estaGordo)` falla con `value estaGordo is not a member of Vaca | Caballo | Granero`; `Predef.Function[A, B]` sigue existiendo como alias de `Function1`.

### Salida de las apps

`GranjaApp`:

```
animal pesa 110, vaca pesa 90
el ave come: como
la colección tiene 3 animales y 0 gordos
después de pastorear, las vacas pesan List(110, 110, 110)
después de ordeñar, las vacas pesan List(100, 100, 100)
el corral de animales tiene 3 animales
gordos del corral: 1
¿contiene a la gordita? true
¿contiene a otra vaca? false
¿contiene un caballo? false
el set de vacas tiene 2, el de animales 3
lista de vacas: 2, lista con caballo: 3
miLista tiene 2, con el caballo 3
¿miLista contiene a la gordita? true
gordas en miLista: 1
concatenadas: 5
una vaca de miLista pesa 150
una vaca de miLista pesa 100
```

`GranjaApp2`:

```
f = g devuelve la misma vaca: true
f = i ordeñó la vaca que recibió: pesa 90
f = k hizo comer a la vaca que recibió: pesa 110
f2 = k2 hizo comer a la vaca que recibió: pesa 110
```

`GranjaApp3`:

```
Una vaca loca se ríe así: Muajajajjaajja
Este animal pesa: 100
Este animal pesa: 100
```

### Los 23 tests

| # | Test | Qué verifica |
|---|---|---|
| 1 | una vaca se puede guardar en una variable de tipo Animal y sigue comiendo | subtipado: `Animal = new Vaca`, `come` → 110 |
| 2 | una vaca loca se puede guardar en una variable de tipo Vaca y se ordeña | `Vaca = new VacaLoca`, `ordeñate` → 90 |
| 3 | un avestruz usado como ave rompe el principio de sustitución al volar | `ave.vola` lanza `UnsupportedOperationException` |
| 4 | un Set[Animal] sabe que todos sus elementos entienden estaGordo | `filter(_.estaGordo)` → `Set(gordo)` |
| 5 | un granero no puede entrar en un Set[Animal] | **no compila:** `Found: Granero / Required: Animal` |
| 6 | el lechero ordeña todas las vacas de un corral de vacas | pesos `List(90, 90, 90)` |
| 7 | el pastor pastorea los animales de un corral de vacas | pesos `List(110, 110)` |
| 8 | un corral solo acepta animales | **no compila:** `new Corral(List(1, 2, 3))` |
| 9 | un corral de vacas es un corral de animales | `Corral[Animal] = corralDeVacas` (covarianza) |
| 10 | gordos devuelve solo los animales gordos del corral | `gordos` → `List(gordita)` |
| 11 | contiene encuentra un animal que está en el corral | `true` / `false` / `false` (con un caballo, infiere `contiene[Animal]`) |
| 12 | contiene no acepta algo que no pueda ser un animal del corral | **no compila:** `contiene[Int](123)` → `Int does not conform to lower bound Vaca` |
| 13 | un Set de vacas no es un Set de animales: Set es invariante | **no compila:** `Set[Animal] = Set[Vaca](…)` |
| 14 | una lista de vacas se puede usar como lista de animales | `List[Animal] = vacas`; `:+` crea una lista nueva y `vacas` sigue con 2 |
| 15 | una función de Vaca en VacaLoca se puede usar como función de Vaca en Vaca | retorno covariante |
| 16 | una función de Animal en Vaca se puede usar como función de Vaca en Vaca | parámetro contravariante |
| 17 | una función que devuelve Animal no sirve como función de Vaca en Vaca | **no compila:** `f = h` |
| 18 | una función que recibe VacaLoca no sirve como función de Vaca en Vaca | **no compila:** `f = j` |
| 19 | un printer de animales se puede usar como printer de vacas locas | `Printer[VacaLoca] = new AnimalPrinter`; imprime `Este animal pesa: 100` |
| 20 | add a una MiLista devuelve una lista nueva y deja la original igual | 1 y 2 |
| 21 | una MiLista de vacas se puede usar como MiLista de animales | covarianza de `MiLista` |
| 22 | contains, filter, map, concat y foreach de MiLista | `true` / `false` / `gordita` / 150 / 3 / `foreach` ordeña → 140 |
| 23 | head de una MiLista vacía falla | `NoSuchElementException` |

## Cómo usarlo

Abrir la carpeta `tadp-clase08-type-arguments-y-varianza` en IntelliJ como proyecto sbt, o `sbt test` desde la raíz. Las tres apps se corren como aplicaciones (`object … extends App`).

## Árbol del proyecto

```
tadp-clase08-type-arguments-y-varianza/
├── build.sbt
├── .gitignore
├── project/
│   └── build.properties
└── src/
    ├── main/scala/tadp/granja/
    │   ├── Animales.scala
    │   ├── Granero.scala
    │   ├── Aves.scala
    │   ├── Corral.scala
    │   ├── MiLista.scala
    │   ├── Printer.scala
    │   ├── GranjaApp.scala
    │   ├── GranjaApp2.scala
    │   └── GranjaApp3.scala
    └── test/scala/tadp/granja/
        └── GranjaTest.scala
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
    name := "tadp-clase08-type-arguments-y-varianza",
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

### `src/main/scala/tadp/granja/Animales.scala`

*La jerarquía de la granja: `Animal` con `peso`, `come` y `estaGordo`; `Vaca` que se ordeña; `VacaLoca` que se ríe; `Caballo` que relincha.*

```scala
package tadp.granja

class Animal {
  var peso: Int = 100

  def come: Unit = peso += 10

  def estaGordo: Boolean = peso >= 150
}

class Vaca extends Animal {
  def ordeñate: Unit = peso -= 10
}

class VacaLoca extends Vaca {
  def reite: String = "Muajajajjaajja"
}

class Caballo extends Animal {
  def relincha: String = "IEIIEIEeeeeieeie"
}
```

### `src/main/scala/tadp/granja/Granero.scala`

*Un objeto que no es animal. Sirve para mostrar qué pasa cuando una colección mezcla cosas sin tipo en común (ver el test "un granero no puede entrar en un Set[Animal]").*

```scala
package tadp.granja

class Granero {
  var granos: Int = 10000
}
```

### `src/main/scala/tadp/granja/Aves.scala`

*El ejemplo del principio de sustitución de Liskov: `Avestruz` es un `Ave` que al volar lanza una excepción.*

```scala
package tadp.granja

class Ave {
  def vola: String = "vuelo"

  def come: String = "como"
}

class Avestruz extends Ave {
  override def vola: String = throw new UnsupportedOperationException("las avestruces no vuelan")

  def meteLaCabezaBajoTierra: String = "cabeza bajo tierra"
}
```

### `src/main/scala/tadp/granja/Corral.scala`

*Estado final del ejercicio: `Corral[+T <: Animal]` covariante sobre una `List` inmutable, con `gordos` y `contiene` con lower bound; `Pastor` recibe `List[Animal]`; `Lechero` recibe `Corral[Vaca]`.*

```scala
package tadp.granja

class Corral[+T <: Animal](val animales: List[T]) {

  def gordos: List[T] = animales.filter(_.estaGordo)

  def contiene[U >: T](elem: U): Boolean = animales.contains(elem)
}

class Pastor {
  def pastorear(animales: List[Animal]): Unit = animales.foreach(_.come)
}

class Lechero {
  def ordeñar(corral: Corral[Vaca]): Unit = corral.animales.foreach(_.ordeñate)
}
```

### `src/main/scala/tadp/granja/MiLista.scala`

*La lista covariante propia que se armó en clase, completa: `Vacia` (una `MiLista[Nothing]`) y `Nodo(primero, cola)`. Todo método que recibe un `T` lo hace a través de un `U >: T`. Cada caso responde por polimorfismo, sin preguntar si la lista está vacía.*

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

### `src/main/scala/tadp/granja/Printer.scala`

*`Printer[-T]` contravariante y sus dos implementaciones.*

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

### `src/main/scala/tadp/granja/GranjaApp.scala`

*Repaso de tipado, Liskov, colecciones tipadas, el corral con pastor y lechero, covarianza de `Corral` y `List`, `Set` invariante y `MiLista`.*

```scala
package tadp.granja

object GranjaApp extends App {

  // ---------- Repaso de tipado ----------

  var animal: Animal = new Vaca
  var vaca: Vaca = new Vaca

  animal.come
  vaca.ordeñate

  vaca = new VacaLoca
  vaca.ordeñate

  println(s"animal pesa ${animal.peso}, vaca pesa ${vaca.peso}")

  // ---------- Principio de sustitución de Liskov ----------

  val ave: Ave = new Avestruz

  println(s"el ave come: ${ave.come}")

  // ---------- Colecciones y type arguments ----------

  val unaColeccion: Set[Animal] = Set(new Vaca, new Caballo, new VacaLoca)
  val gordos: Set[Animal] = unaColeccion.filter(_.estaGordo)

  println(s"la colección tiene ${unaColeccion.size} animales y ${gordos.size} gordos")

  // ---------- Corral, Pastor y Lechero ----------

  val corralito: Corral[Vaca] = new Corral(List(new Vaca, new Vaca, new Vaca))
  val lechero: Lechero = new Lechero
  val pastor: Pastor = new Pastor

  pastor.pastorear(corralito.animales)
  println(s"después de pastorear, las vacas pesan ${corralito.animales.map(_.peso)}")

  lechero.ordeñar(corralito)
  println(s"después de ordeñar, las vacas pesan ${corralito.animales.map(_.peso)}")

  val corralDeAnimales: Corral[Animal] = corralito

  println(s"el corral de animales tiene ${corralDeAnimales.animales.size} animales")

  val gordita: Vaca = new Vaca
  gordita.peso = 150

  val corralConGordita: Corral[Vaca] = new Corral(List(new Vaca, gordita))

  println(s"gordos del corral: ${corralConGordita.gordos.size}")
  println(s"¿contiene a la gordita? ${corralConGordita.contiene(gordita)}")
  println(s"¿contiene a otra vaca? ${corralConGordita.contiene(new Vaca)}")
  println(s"¿contiene un caballo? ${corralConGordita.contiene(new Caballo)}")

  // ---------- Varianza: Set invariante, List covariante ----------

  val vacas: Set[Vaca] = Set(new Vaca, new VacaLoca)
  val animales: Set[Animal] = Set(new Vaca, new VacaLoca, new Caballo)

  println(s"el set de vacas tiene ${vacas.size}, el de animales ${animales.size}")

  val listaDeVacas: List[Vaca] = List(new Vaca, new VacaLoca)
  val listaDeAnimales: List[Animal] = listaDeVacas
  val conCaballo: List[Animal] = listaDeAnimales :+ new Caballo

  listaDeAnimales.foreach(_.come)
  listaDeVacas.foreach(_.ordeñate)

  println(s"lista de vacas: ${listaDeVacas.size}, lista con caballo: ${conCaballo.size}")

  // ---------- MiLista: una lista covariante propia ----------

  val miLista: MiLista[Vaca] = Vacia.add(new VacaLoca).add(gordita)
  val miListaDeAnimales: MiLista[Animal] = miLista.add(new Caballo)

  println(s"miLista tiene ${miLista.length}, con el caballo ${miListaDeAnimales.length}")
  println(s"¿miLista contiene a la gordita? ${miLista.contains(gordita)}")
  println(s"gordas en miLista: ${miLista.filter(_.estaGordo).length}")
  println(s"concatenadas: ${miLista.concat(miListaDeAnimales).length}")

  miLista.map(_.peso).foreach(peso => println(s"una vaca de miLista pesa $peso"))
}
```

### `src/main/scala/tadp/granja/GranjaApp2.scala`

*Las funciones `g` a `k` contra una variable `f: Vaca => Vaca`: las tres asignaciones que compilan, y por qué.*

```scala
package tadp.granja

object GranjaApp2 extends App {

  def g(vaca: Vaca): Vaca = vaca // Recibe una Vaca y devuelve una Vaca

  def h(vaca: Vaca): Animal = new Caballo // Devuelve un Animal: no entra en f

  def i(vaca: Vaca): VacaLoca = { // Devuelve una VacaLoca
    vaca.ordeñate
    new VacaLoca
  }

  def j(vacaLoca: VacaLoca): Vaca = { // Recibe una VacaLoca: no entra en f
    vacaLoca.reite
    vacaLoca.ordeñate
    vacaLoca
  }

  def k(animal: Animal): Vaca = { // Recibe un Animal
    animal.come
    new Vaca
  }

  var f: Vaca => Vaca = g // mismo parámetro y mismo retorno

  val vacaDeG: Vaca = new Vaca
  println(s"f = g devuelve la misma vaca: ${f(vacaDeG) eq vacaDeG}")

  f = i // devuelve VacaLoca, que es una Vaca: el retorno es covariante

  val vacaDeI: Vaca = new Vaca
  f(vacaDeI).ordeñate
  println(s"f = i ordeñó la vaca que recibió: pesa ${vacaDeI.peso}")

  f = k // recibe Animal, y una Vaca es un Animal: el parámetro es contravariante

  val vacaDeK: Vaca = new Vaca
  f(vacaDeK).ordeñate
  println(s"f = k hizo comer a la vaca que recibió: pesa ${vacaDeK.peso}")

  val k2: Animal => Vaca = { animal =>
    animal.come
    new Vaca
  }

  val f2: Function1[Vaca, Vaca] = k2

  val vacaDeF2: Vaca = new Vaca
  f2(vacaDeF2).ordeñate
  println(s"f2 = k2 hizo comer a la vaca que recibió: pesa ${vacaDeF2.peso}")
}
```

### `src/main/scala/tadp/granja/GranjaApp3.scala`

*Un `Printer[Animal]` guardado en una variable `Printer[VacaLoca]`.*

```scala
package tadp.granja

object GranjaApp3 extends App {

  var printer: Printer[VacaLoca] = new VacaLocaPrinter
  printer.print(new VacaLoca)

  printer = new AnimalPrinter
  printer.print(new VacaLoca)

  val printerDeAnimales: Printer[Animal] = new AnimalPrinter
  printerDeAnimales.print(new Caballo)
}
```

### `src/test/scala/tadp/granja/GranjaTest.scala`

*Veintitrés tests con ScalaTest `AnyFunSuite` + `Matchers`: diecisiete de comportamiento y seis `assertTypeError` con lo que esta unidad enseña que **no** compila.*

```scala
package tadp.granja

import org.scalatest.funsuite.AnyFunSuite
import org.scalatest.matchers.should.Matchers

class GranjaTest extends AnyFunSuite with Matchers {

  // ---------- Subtipado y Liskov ----------

  test("una vaca se puede guardar en una variable de tipo Animal y sigue comiendo") {
    val animal: Animal = new Vaca

    animal.come

    animal.peso shouldBe 110
  }

  test("una vaca loca se puede guardar en una variable de tipo Vaca y se ordeña") {
    val vaca: Vaca = new VacaLoca

    vaca.ordeñate

    vaca.peso shouldBe 90
  }

  test("un avestruz usado como ave rompe el principio de sustitución al volar") {
    val ave: Ave = new Avestruz

    ave.come shouldBe "como"
    intercept[UnsupportedOperationException] {
      ave.vola
    }
  }

  // ---------- Type arguments ----------

  test("un Set[Animal] sabe que todos sus elementos entienden estaGordo") {
    val gordo: Vaca = new Vaca
    gordo.peso = 150
    val coleccion: Set[Animal] = Set(new Vaca, new Caballo, gordo)

    coleccion.filter(_.estaGordo) shouldBe Set(gordo)
  }

  test("un granero no puede entrar en un Set[Animal]") {
    assertTypeError("val coleccion: Set[Animal] = Set(new Vaca, new Caballo, new Granero)")
  }

  // ---------- Corral, Pastor y Lechero ----------

  test("el lechero ordeña todas las vacas de un corral de vacas") {
    val corralito: Corral[Vaca] = new Corral(List(new Vaca, new Vaca, new Vaca))

    new Lechero().ordeñar(corralito)

    corralito.animales.map(_.peso) shouldBe List(90, 90, 90)
  }

  test("el pastor pastorea los animales de un corral de vacas") {
    val corralito: Corral[Vaca] = new Corral(List(new Vaca, new VacaLoca))

    new Pastor().pastorear(corralito.animales)

    corralito.animales.map(_.peso) shouldBe List(110, 110)
  }

  test("un corral solo acepta animales") {
    assertTypeError("new Corral(List(1, 2, 3))")
  }

  test("un corral de vacas es un corral de animales") {
    val corralDeVacas: Corral[Vaca] = new Corral(List(new Vaca, new VacaLoca))

    val corralDeAnimales: Corral[Animal] = corralDeVacas

    corralDeAnimales.animales.size shouldBe 2
  }

  test("gordos devuelve solo los animales gordos del corral") {
    val gordita: Vaca = new Vaca
    gordita.peso = 150
    val corral: Corral[Vaca] = new Corral(List(new Vaca, gordita))

    corral.gordos shouldBe List(gordita)
  }

  test("contiene encuentra un animal que está en el corral") {
    val gordita: Vaca = new Vaca
    val corral: Corral[Vaca] = new Corral(List(new Vaca, gordita))

    corral.contiene(gordita) shouldBe true
    corral.contiene(new Vaca) shouldBe false
    corral.contiene(new Caballo) shouldBe false
  }

  test("contiene no acepta algo que no pueda ser un animal del corral") {
    assertTypeError("new Corral(List(new Vaca)).contiene[Int](123)")
  }

  // ---------- Varianza de Set y List ----------

  test("un Set de vacas no es un Set de animales: Set es invariante") {
    assertTypeError("val animales: Set[Animal] = Set[Vaca](new Vaca)")
  }

  test("una lista de vacas se puede usar como lista de animales") {
    val vacas: List[Vaca] = List(new Vaca, new VacaLoca)

    val animales: List[Animal] = vacas
    val conCaballo: List[Animal] = animales :+ new Caballo

    animales.foreach(_.come)
    vacas.map(_.peso) shouldBe List(110, 110)
    conCaballo.size shouldBe 3
    vacas.size shouldBe 2
  }

  // ---------- Funciones: contravariantes en el parámetro, covariantes en el retorno ----------

  test("una función de Vaca en VacaLoca se puede usar como función de Vaca en Vaca") {
    def i(vaca: Vaca): VacaLoca = {
      vaca.ordeñate
      new VacaLoca
    }

    val f: Vaca => Vaca = i
    val vaca: Vaca = new Vaca

    f(vaca).ordeñate

    vaca.peso shouldBe 90
  }

  test("una función de Animal en Vaca se puede usar como función de Vaca en Vaca") {
    def k(animal: Animal): Vaca = {
      animal.come
      new Vaca
    }

    val f: Vaca => Vaca = k
    val vaca: Vaca = new Vaca

    f(vaca).ordeñate

    vaca.peso shouldBe 110
  }

  test("una función que devuelve Animal no sirve como función de Vaca en Vaca") {
    assertTypeError("def h(vaca: Vaca): Animal = new Caballo; val f: Vaca => Vaca = h")
  }

  test("una función que recibe VacaLoca no sirve como función de Vaca en Vaca") {
    assertTypeError("def j(vacaLoca: VacaLoca): Vaca = vacaLoca; val f: Vaca => Vaca = j")
  }

  // ---------- Printer contravariante ----------

  test("un printer de animales se puede usar como printer de vacas locas") {
    var printer: Printer[VacaLoca] = new VacaLocaPrinter
    val salida: java.io.ByteArrayOutputStream = new java.io.ByteArrayOutputStream()

    printer = new AnimalPrinter
    Console.withOut(salida) {
      printer.print(new VacaLoca)
    }

    salida.toString.trim shouldBe "Este animal pesa: 100"
  }

  // ---------- MiLista covariante ----------

  test("add a una MiLista devuelve una lista nueva y deja la original igual") {
    val vacas: MiLista[Vaca] = Vacia.add(new Vaca)

    val animales: MiLista[Animal] = vacas.add(new Caballo)

    vacas.length shouldBe 1
    animales.length shouldBe 2
  }

  test("una MiLista de vacas se puede usar como MiLista de animales") {
    val vacas: MiLista[Vaca] = Vacia.add(new VacaLoca).add(new Vaca)

    val animales: MiLista[Animal] = vacas

    animales.length shouldBe 2
  }

  test("contains, filter, map, concat y foreach de MiLista") {
    val gordita: Vaca = new Vaca
    gordita.peso = 150
    val vacas: MiLista[Vaca] = Vacia.add(new Vaca).add(gordita)

    vacas.contains(gordita) shouldBe true
    vacas.contains(new Vaca) shouldBe false
    vacas.filter(_.estaGordo).head shouldBe gordita
    vacas.map(_.peso).head shouldBe 150
    vacas.concat(Vacia.add(new Caballo)).length shouldBe 3

    vacas.foreach(_.ordeñate)
    gordita.peso shouldBe 140
  }

  test("head de una MiLista vacía falla") {
    intercept[NoSuchElementException] {
      Vacia.head
    }
  }
}
```

---

**FIN DEL ARCHIVO — Código final unificado — clase08 — Type arguments y varianza en Scala**
