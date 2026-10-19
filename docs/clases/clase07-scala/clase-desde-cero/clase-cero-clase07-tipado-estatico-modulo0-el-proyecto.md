# Clase desde cero — Tipado estático en Scala — Módulo 0: El proyecto en el que trabajamos

**Unidad:** clase07 · **Lenguaje:** Scala 3.3.1 · **Densidad:** 🟢 corto, operativo

---

## Sobre este documento

**Qué cubre.** El proyecto mínimo donde va a correr todo el código de esta unidad: qué archivos tiene, qué hace cada uno, cómo se ejecuta un programa y cómo se corre un test. Es el mismo esqueleto que el repo del TP. Al terminar, cualquier bloque de código de los módulos siguientes se pega en este proyecto y corre.

**Qué no cubre.** La instalación de Java, sbt, Scala e IntelliJ. Eso es la `preclase07` ("Instalación de ambientes"), un material aparte. Acá se asume que IntelliJ abre proyectos Scala.

## De dónde venís

De cuatro clases en Ruby: clases, objetos, `attr_accessor`, mixins, `method_missing`, y tests con RSpec. De Scala no se asume nada: cada palabra nueva se explica antes de usarse.

---

## 1. 🟡 Scala se compila antes de correr

> Un programa Scala pasa por dos momentos separados: **compilar** (traducir el código a algo que la máquina ejecuta, y revisarlo) y **ejecutar**. En Ruby los dos momentos eran uno.

Lo que la máquina ejecuta se llama *bytecode*, y quien lo ejecuta es la **JVM** (Java Virtual Machine: el mismo motor que corre Java). Por eso Scala puede usar librerías de Java y por eso vas a ver `java` en las rutas y en los mensajes.

Para esta unidad lo que importa es una sola consecuencia: **hay un paso previo a ejecutar donde el código se revisa entero**. Qué se revisa ahí es el tema del Módulo 2.

## 2. 🟡 sbt: la herramienta que compila, testea y baja librerías

> **sbt** es el programa que compila el proyecto, corre los tests y descarga las **librerías** (código ya escrito por otros que el proyecto usa). Se configura con un archivo llamado `build.sbt` en la raíz.

```scala
// build.sbt — la configuración del proyecto. Vive en la raíz.

// "ThisBuild / opcion := valor" fija esa opción para todo el proyecto.
// scalaVersion: la versión de Scala que compila el código, la misma que el repo del TP.
// version y organization: etiquetas del proyecto (versión propia y quién lo hace).
ThisBuild / scalaVersion     := "3.3.1"
ThisBuild / version          := "0.1.0"
ThisBuild / organization     := "ar.edu.utn.frba.tadp"

// El proyecto es la carpeta actual ("."); settings lista sus opciones: nombre y librerías.
// "% Test" dice que ScalaTest se usa solo para los tests, no para el programa.
lazy val root = (project in file("."))
  .settings(
    name := "tadp-clase07-tipado-estatico",
    libraryDependencies += "org.scalatest" %% "scalatest" % "3.2.19" % Test
  )
```

Hay un segundo archivo, chiquito, que fija la versión de sbt:

```properties
# project/build.properties
sbt.version=1.9.0
```

**ScalaTest** es la librería de tests de Scala, el equivalente de RSpec. El `%%` del medio le agrega al nombre de la librería el sufijo de la versión de Scala (`scalatest_3`), que es como está publicada; con un `%` simple sbt buscaría un artefacto sin sufijo, inexistente en los repositorios, y la descarga fallaría.

## 3. 🟡 Dónde va cada cosa

> El código va en `src/main/scala`, los tests en `src/test/scala`. Dentro, las carpetas siguen al **`package`**: la primera línea de cada archivo dice a qué paquete pertenece, y la ruta de carpetas repite ese nombre.

```
tadp-clase07-tipado-estatico/
├── build.sbt                         ← configuración (sección 2)
├── project/
│   └── build.properties              ← versión de sbt
└── src/
    ├── main/scala/tadp/              ← el programa
    │   ├── nadaquever/               ← paquete tadp.nadaquever
    │   └── ageofempires/             ← paquete tadp.ageofempires
    └── test/scala/tadp/              ← los tests, con la misma estructura
        └── ageofempires/
```

Un **paquete** es una carpeta lógica con nombre: agrupa clases que van juntas y evita que dos clases con el mismo nombre choquen. Para usar algo de otro paquete (o de una librería) se escribe **`import`** con su nombre completo. Las dos primeras líneas de un archivo de test, por ejemplo:

```scala
package tadp.ageofempires                     // este archivo pertenece a tadp.ageofempires

import org.scalatest.funsuite.AnyFunSuite     // traigo AnyFunSuite desde ScalaTest (solo en src/test)
```

## 4. 🟡 Un programa que se ejecuta

> Un **`object`** es un objeto único con nombre: existe uno solo, sin `new`. Si además dice **`extends App`**, su cuerpo se ejecuta cuando corrés el programa.

```scala
// src/main/scala/tadp/nadaquever/Hola.scala
package tadp.nadaquever

object Hola extends App {
  println("Hola, TADP")          // println imprime una línea en la consola
}
// Resultado al correrlo:
// Hola, TADP
```

En Ruby un archivo suelto se ejecutaba de arriba abajo. En Scala el código ejecutable vive adentro de algo: acá, de un `object` con `App`. Para correrlo en IntelliJ: el triángulo ▷ al margen de `object Hola`.

🕳️ **Madriguera — `@main`.** Scala 3 también permite marcar un método con `@main` como punto de entrada. En esta cursada se usa `extends App`. *Volvé al camino — esto se profundiza aparte, otro día.*

## 5. 🟡 Un test que corre

> Un test es una clase que **`extends AnyFunSuite with Matchers`**. Cada `test("…") { … }` es un caso, y **`shouldBe`** compara lo que salió con lo que esperabas.

```scala
// src/test/scala/tadp/ageofempires/HolaTest.scala
package tadp.ageofempires

import org.scalatest.funsuite.AnyFunSuite        // la base: define test("…")
import org.scalatest.matchers.should.Matchers    // define shouldBe

class HolaTest extends AnyFunSuite with Matchers {

  test("dos mas dos") {
    (2 + 2) shouldBe 4          // Resultado: pasa
  }

  test("un texto") {
    "Hola".length shouldBe 4    // Resultado: pasa (length cuenta las letras)
  }
}
```

Para correrlo: el ▷ al margen de la clase corre todos sus tests; el ▷ de cada `test` corre uno solo. En la consola, ScalaTest informa, entre otras líneas de resumen:

```
[info] HolaTest:
[info] - dos mas dos
[info] - un texto
[info] Total number of tests run: 2
[info] Tests: succeeded 2, failed 0, canceled 0, ignored 0, pending 0
```

Si un test falla, dice qué esperaba y qué obtuvo, y en qué línea del archivo. Cambiando el `4` por `5` en el primero:

```
[info] - dos mas dos *** FAILED ***
[info]   4 was not equal to 5 (HolaTest.scala:10)
```

Esa línea, `X was not equal to Y`, va a aparecer varias veces en esta unidad.

## 6. 🟢 El mismo test, en Ruby y en Scala

> Cada idea de RSpec tiene su equivalente directo en ScalaTest. Cambia la sintaxis; la idea es la misma.

| Querés | RSpec (Ruby) | ScalaTest |
|---|---|---|
| Agrupar casos | `describe Guerrero do … end` | `class GuerreroTest extends AnyFunSuite with Matchers { … }` |
| Un caso | `it "ataca" do … end` | `test("ataca") { … }` |
| Comparar | `expect(x).to eq(90)` | `x shouldBe 90` |
| Correr todo | `rspec` | `sbt test`, o el ▷ en IntelliJ |

---

## Checkpoint (sin respuestas)

1. ¿Qué dos momentos separa Scala que en Ruby eran uno solo?
2. ¿Qué archivo declara la versión de Scala del proyecto y qué librerías usa?
3. ¿Qué relación hay entre la primera línea `package …` de un archivo y la carpeta donde está?
4. ¿Para qué sirve `import`?
5. ¿Qué diferencia hay entre un `object` y una `class`?
6. ¿Qué hace `extends App`?
7. ¿Qué dos cosas trae `extends AnyFunSuite with Matchers` a una clase de test?

## Qué viene después

**Módulo 1:** el problema que motiva toda la unidad, contado en Ruby: un error que el test no vio.

**FIN DEL MÓDULO 0**
