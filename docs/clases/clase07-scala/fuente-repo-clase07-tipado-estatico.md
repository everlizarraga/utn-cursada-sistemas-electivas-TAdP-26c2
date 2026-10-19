# Código final unificado — clase07 — Tipado estático en Scala

> **Qué es este archivo.** El código completo y funcional de la unidad `clase07` (sábado 3-Oct-2026), en **un solo estado final**, escrito para **Scala 3.3.1**, sbt 1.9.0 y ScalaTest 3.2.19 (las versiones del repo del TP). Es la referencia sobre la que se apoya todo el material de la unidad: lo que figure acá es lo que se pega y corre. Las etapas intermedias no están acá; son tema del código impreso.
>
> **Qué no es.** No es una copia fiel de ningún repositorio de la cátedra: es una **unificación** de lo que se escribió en la clase presencial, completada con el repo de cátedra donde la clase dejó algo sin cerrar, y adaptada a 3.3.1. Las copias fieles de los repos, si se generan, son `fuente-repo-*` propios.
>
> **Generado:** 18-Oct-2026 · **Estado:** revisado en segunda pasada · **Compilación:** sin verificar en 3.3.1 al generarse (sin Scala en el entorno de generación). Los seis tests están calculados a mano contra el código; ver tabla al final de este encabezado.

## Procedencia y adaptaciones

| Archivo | De dónde sale | Adaptaciones declaradas |
|---|---|---|
| `build.sbt`, `project/build.properties` | Versiones del repo del TP (3.3.1 / 1.9.0 / 3.2.19) | Nombre del proyecto propio |
| `Saludador.scala` | **Clase presencial**, estado final (fotos 9–13): `Nombrable`, `Persona(val name)` con `override val nombre`, `Asistente`, `AI`, `Pato`, `type PersonaAsistente`, `type Saludable`, `saludar(a: Saludable): String` | Las cinco llamadas `println` al final (en clase había una sola). El `import scala.reflect.Selectable.reflectiveSelectable` que el tipo estructural exige en Scala 3 (foto 41). Erratas corregidas: `"Buen día estimado/a "` con tilde y espacio |
| `Defensor.scala` | **Clase presencial** (foto 33), idéntico al repo de cátedra `ageofempires` | Parámetro renombrado `a` → `danio` |
| `Atacante.scala` | **Repo de cátedra** `ageofempires` (en clase se vio la pestaña abierta; el cuerpo no quedó en foto) | Parámetro `otroGuerrero` → `defensor`; `: Unit` explícito |
| `Guerrero.scala` | Clase presencial (foto 38: `extends Defensor`, con `atacaA` propio) + **repo de cátedra** `ageofempires` (`with Atacante`, `atacaA` movido al trait, `.max(0)`). En las fotos `Guerrero` todavía tenía su `atacaA`; la transcripción nombra la "interfaz de atacante" sin que quede en foto | **Un cambio de diseño:** el potencial ofensivo entra como `_potencialOfensivo` y se expone con `def potencialOfensivo`, en vez de `val potencialOfensivo` como en clase. Motivo: `Espadachin` lo redefine con `super`, y `super` sobre un `val` no compila. `potencialDefensivo` es `val` (repo) y no `var` (esqueleto inicial de la clase): nada lo modifica, y un `val` también cumple el `def` abstracto |
| `Espadachin.scala` | **Material 2020** (capturas 15–17, repo `20201C-intro-tipos`), adaptado a los nombres y números de la presencial | Agregado. No se hizo en la presencial; entra como vehículo de `override def` + `super` (decisión D2 de la planificación). Se quita el parámetro `_potencialDefensivo` que tenía en 2020, porque el `Guerrero` final no lo recibe |
| `Muralla.scala` | Clase presencial (foto 39) + **repo de cátedra** para `recibeDanio` | `recibeDanio` resta `danio / 10` (repo). En la foto 39 restaba el daño entero, lo que da 980 y contradice el test de 998. Sin `override` en las implementaciones de los abstractos (opcional en Scala; el repo no lo usa) |
| `Misil.scala` | **Repo de cátedra** `ageofempires` (en clase quedó sin terminar) | Cuerpo del `def` sin llaves (en el repo las tenía). El `2016` es el año de referencia del enunciado original |
| `AtaqueTest.scala` | **Clase presencial** (fotos 16–19, 26–29, 40): los cuatro tests con `AnyFunSuite` + `Matchers` | Dos tests agregados: espadachín (del 2020, con los números de acá) y energía inicial de la muralla. Paquete `tadp.ageofempires` en vez de `tadp.clase`, para que el test viva junto al código final |
| *Todos* | — | Anotaciones de tipo explícitas donde las fuentes las omitían (`var energia: Int`, `val potencialDefensivo: Int`, `: Unit` en `recibeDanio`) y comentarios de los alias ampliados. Es la forma completa que el material usa primero (R1) |

**Lo único sin verificar que podría dar un aviso al compilar:** la llamada `a.nombre` sobre el tipo estructural usa una conversión implícita (`reflectiveSelectable`); en 3.3.1 puede emitir un *feature warning*, que se silencia con `import scala.language.implicitConversions`. Es un aviso, no un error. Todo lo demás es sintaxis que las fotos muestran compilando en Scala 3.

## Los seis tests, calculados a mano

| Test | Cuenta | Esperado |
|---|---|---|
| Guerrero (20) ataca a guerrero (defensa 10) | 10 < 20 → `recibeDanio(20 − 10)` → 100 − 10 | **90** |
| Guerrero (200) ataca a guerrero | 10 < 200 → `recibeDanio(190)` → `(100 − 190).max(0)` | **0** |
| Guerrero (20) ataca a muralla (defensa 0, energía 1000) | 0 < 20 → `recibeDanio(20)` → 1000 − 20 / 10 | **998** |
| Misil (1966) ataca a muralla | potencial = (2016 − 1966) × 10 = 500 → `recibeDanio(500)` → 1000 − 500 / 10 | **950** |
| Espadachín (20 + espada 20) ataca a guerrero | 10 < 40 → `recibeDanio(40 − 10)` → 100 − 30 | **70** |
| Muralla recién construida | `energia = 1000` en el cuerpo de la clase | **1000** |

## Cómo usarlo

Abrir la carpeta `tadp-clase07-tipado-estatico` en IntelliJ como proyecto sbt, o `sbt test` desde la raíz. `Saludador` se corre como aplicación (`object Saludador extends App`) e imprime cinco líneas:

```
Hola
Buen día estimado/a Ernesto
Buen día estimado/a Siri
Buen día estimado/a HAL
Buen día estimado/a Donald
```

## Árbol del proyecto

```
tadp-clase07-tipado-estatico/
├── build.sbt
├── .gitignore
├── project/
│   └── build.properties
└── src/
    ├── main/scala/tadp/
    │   ├── nadaquever/
    │   │   └── Saludador.scala
    │   └── ageofempires/
    │       ├── Defensor.scala
    │       ├── Atacante.scala
    │       ├── Guerrero.scala
    │       ├── Espadachin.scala
    │       ├── Muralla.scala
    │       └── Misil.scala
    └── test/scala/tadp/ageofempires/
        └── AtaqueTest.scala
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
    name := "tadp-clase07-tipado-estatico",
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

### `src/main/scala/tadp/nadaquever/Saludador.scala`

*Estado final del `Saludador`: trait `Nombrable`, `Persona` que cumple el contrato con `override val`, `Asistente`, `AI`, `Pato` (sin consentimiento), unión de tipos con alias y tipo estructural `Saludable` como parámetro de `saludar`. Las clases quedan anidadas en el `object`, como en clase.*

```scala
package tadp.nadaquever

import scala.reflect.Selectable.reflectiveSelectable

object Saludador extends App {

  trait Nombrable {
    def nombre: String
  }

  class Persona(val name: String) extends Nombrable {
    override val nombre: String = this.name
  }

  class Asistente(val nombre: String) extends Nombrable

  class AI(val nombre: String) extends Nombrable

  class Pato(val nombre: String, cantidadPlumas: Int = 20)

  type PersonaAsistente = Persona | Asistente // type alias (unión de tipos)
  type Saludable = { def nombre: String }     // type alias (tipo estructural)

  class Saludador(cordial: Boolean = false) {
    def saludar(a: Saludable): String = {
      if (cordial) {
        "Buen día estimado/a " + a.nombre
      } else {
        "Hola"
      }
    }
  }

  println(new Saludador().saludar(new Persona("Ernesto")))
  println(new Saludador(cordial = true).saludar(new Persona("Ernesto")))
  println(new Saludador(cordial = true).saludar(new Asistente("Siri")))
  println(new Saludador(cordial = true).saludar(new AI("HAL")))
  println(new Saludador(cordial = true).saludar(new Pato("Donald")))
}
```

### `src/main/scala/tadp/ageofempires/Defensor.scala`

*Contrato de todo lo que recibe daño: estado `energia` y dos métodos abstractos.*

```scala
package tadp.ageofempires

trait Defensor {
  var energia: Int = 100

  def potencialDefensivo: Int

  def recibeDanio(danio: Int): Unit
}
```

### `src/main/scala/tadp/ageofempires/Atacante.scala`

*Contrato de todo lo que ataca: `potencialOfensivo` abstracto y `atacaA` concreto sobre un `Defensor`.*

```scala
package tadp.ageofempires

trait Atacante {
  def potencialOfensivo: Int

  def atacaA(defensor: Defensor): Unit = {
    if (defensor.potencialDefensivo < this.potencialOfensivo) {
      defensor.recibeDanio(this.potencialOfensivo - defensor.potencialDefensivo)
    }
  }
}
```

### `src/main/scala/tadp/ageofempires/Guerrero.scala`

*Defensor y atacante a la vez (`extends … with …`). `potencialOfensivo` es un `def` para que `Espadachin` pueda redefinirlo con `super`.*

```scala
package tadp.ageofempires

class Guerrero(_potencialOfensivo: Int = 20) extends Defensor with Atacante {
  val potencialDefensivo: Int = 10

  def potencialOfensivo: Int = _potencialOfensivo

  def recibeDanio(danio: Int): Unit = {
    this.energia = (this.energia - danio).max(0)
  }
}
```

### `src/main/scala/tadp/ageofempires/Espadachin.scala`

*Guerrero con espada: redefine `potencialOfensivo` sumando el de la espada.*

```scala
package tadp.ageofempires

class Espada(val potencialOfensivo: Int)

class Espadachin(espada: Espada, _potencialOfensivo: Int = 20)
  extends Guerrero(_potencialOfensivo) {

  override def potencialOfensivo: Int =
    super.potencialOfensivo + espada.potencialOfensivo
}
```

### `src/main/scala/tadp/ageofempires/Muralla.scala`

*Defensor que no ataca: inicializa `energia` en el cuerpo, defensa 0 y recibe un décimo del daño.*

```scala
package tadp.ageofempires

class Muralla extends Defensor {
  this.energia = 1000

  val potencialDefensivo: Int = 0

  def recibeDanio(danio: Int): Unit = {
    this.energia = (this.energia - danio / 10).max(0)
  }
}
```

### `src/main/scala/tadp/ageofempires/Misil.scala`

*Atacante que no se defiende: su potencial depende del año de fabricación.*

```scala
package tadp.ageofempires

class Misil(val anioFabricacion: Int) extends Atacante {
  def potencialOfensivo: Int = (2016 - anioFabricacion) * 10
}
```

### `src/test/scala/tadp/ageofempires/AtaqueTest.scala`

*Los cuatro tests de la clase más dos agregados (espadachín y energía inicial de la muralla). ScalaTest `AnyFunSuite` + `Matchers`.*

```scala
package tadp.ageofempires

import org.scalatest.funsuite.AnyFunSuite
import org.scalatest.matchers.should.Matchers

class AtaqueTest extends AnyFunSuite with Matchers {

  test("un guerrero ataca a otro guerrero") {
    val g1 = new Guerrero
    val g2 = new Guerrero

    g1.atacaA(g2)

    g2.energia shouldBe 90
  }

  test("un guerrero con mucho potencial ofensivo ataca a otro guerrero") {
    val g1 = new Guerrero(200)
    val g2 = new Guerrero

    g1.atacaA(g2)

    g2.energia shouldBe 0
  }

  test("un guerrero ataca a una muralla") {
    val g1 = new Guerrero
    val m = new Muralla

    g1.atacaA(m)

    m.energia shouldBe 998
  }

  test("un misil ataca a una muralla") {
    val misil = new Misil(1966)
    val muralla = new Muralla

    misil.atacaA(muralla)

    muralla.energia shouldBe 950
  }

  test("un espadachin ataca a un guerrero") {
    val zorro = new Espadachin(new Espada(20))
    val conan = new Guerrero

    zorro.atacaA(conan)

    conan.energia shouldBe 70
  }

  test("una muralla recien construida tiene 1000 de energia") {
    val m = new Muralla

    m.energia shouldBe 1000
  }
}
```

---

**FIN DEL ARCHIVO — Código final unificado — clase07 — Tipado estático en Scala**
