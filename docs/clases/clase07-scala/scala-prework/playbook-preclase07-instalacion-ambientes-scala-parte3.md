# Playbook — preclase07: Instalación de ambientes para Scala — Parte 3: Un dominio chico, con packages y tests

**Unidad:** preclase07 · **Parte 3 de 4** · **Dónde corre:** IntelliJ; la terminal integrada en la sección 6.

**De dónde venís:** Parte 2. Tenés `practica-scala` abierto, con ScalaTest en el `build.sbt` y un primer commit.

**Qué hacés acá:** escribís tres archivos en dos packages, con un `import` entre ellos, y un archivo de tests. Es la estructura de todo el código de la clase07 (packages en `main` y en `test`), en chico. El repo del TP arranca sin packages; vos los agregás cuando escribas el dominio. El dominio es a propósito mínimo: una biblioteca con libros y socios. Lo que importa es dónde va cada archivo, cómo se nombran los packages, cómo se importa y cómo se corren los tests.

**Sobre el código.** Es Scala 3.3.1 con llaves. Cada palabra nueva tiene una línea de explicación; el detalle de cada una lo da la clase07 (Módulo 0 en adelante). Acá alcanza con leerlo y copiarlo tal cual.

---

## 1. Limpiar el sample code

El `main.scala` de la Parte 2 ya cumplió. Borralo para que el proyecto quede solo con lo tuyo: en el panel Project, botón derecho sobre `src/main/scala/main.scala` → **Delete** → OK.

**✅ Deberías ver:** `src/main/scala` vacía.

---

## 2. El package de la biblioteca: `Libro`

Un **package** es una carpeta con nombre que agrupa clases. En Scala, la primera línea de cada archivo declara a qué package pertenece, y por convención la ruta de carpetas repite ese nombre. IntelliJ crea las carpetas por vos:

1. Botón derecho sobre `src/main/scala` → **New → Package**. Nombre: `practica.biblioteca`. Enter.

⚠️ Si IntelliJ muestra una sola carpeta llamada `practica.biblioteca`, con el punto en el nombre, es solo cómo la dibuja el panel (compacta las carpetas con un solo hijo). Las carpetas reales están bien. Para verlas separadas: engranaje del panel Project → destildá **Compact Middle Packages**.

2. Botón derecho sobre la carpeta `biblioteca` recién creada (o sobre `practica.biblioteca`, si el panel la muestra compactada) → **New → Scala Class**. Nombre: `Libro`. Tipo: **Class**. Enter.
3. Reemplazá el contenido del archivo por esto:

```scala
package practica.biblioteca

// Un libro con título y cantidad de páginas.
// Los parámetros con val quedan como propiedades de solo lectura: libro.titulo, libro.paginas.
class Libro(val titulo: String, val paginas: Int)
```

**✅ Deberías ver:** en el panel Project, `src/main/scala/practica/biblioteca/Libro.scala`, y el archivo con las palabras clave `package`, `class` y `val` resaltadas en el color de tu tema.

---

## 3. El package de los socios: `Socio`, con `import`

1. Botón derecho sobre `src/main/scala` → **New → Package**. Nombre: `practica.socios`.
2. Botón derecho sobre `socios` → **New → Scala Class**. Nombre: `Socio`. Tipo: Class.
3. Contenido:

```scala
package practica.socios

// Libro vive en otro package: hay que importarlo.
import practica.biblioteca.Libro

// Un socio lleva la cuenta de cuántos libros tiene y cuántas páginas le quedan por leer.
// var: propiedades que cambian. def: métodos. Unit: el método no devuelve nada (como void).
class Socio(val nombre: String) {
  var librosPrestados: Int = 0
  var paginasPendientes: Int = 0

  def pedir(libro: Libro): Unit = {
    librosPrestados = librosPrestados + 1
    paginasPendientes = paginasPendientes + libro.paginas
  }

  def devolver(libro: Libro): Unit = {
    librosPrestados = librosPrestados - 1
    paginasPendientes = paginasPendientes - libro.paginas
  }

  // Un socio puede pedir mientras tenga menos de tres libros.
  def puedePedir: Boolean = librosPrestados < 3
}
```

El `import` es el punto de esta parte. `Socio` está en `practica.socios` y `Libro` en `practica.biblioteca`; son packages hermanos, y uno no ve al otro hasta que lo importa. Probalo: **borrá la línea del `import`** y mirá el archivo.

**✅ Deberías ver:** `Libro` subrayado en rojo en los dos `def`, y al pasar el mouse: `Cannot resolve symbol Libro`. Ese es el aviso del editor; si compilás, el compilador dice lo mismo con otras palabras: `Not found: type Libro`. Los dos significan que falta un import. Volvé a poner la línea.

**✅ Deberías ver (con el import):** ningún subrayado rojo. Si quedó alguno, compará con el bloque de arriba.

---

## 4. Un programa que usa las dos clases

Este archivo va en el package de arriba, `practica`, y usa las dos clases: necesita dos `import`.

1. Botón derecho sobre la carpeta `practica` (la que contiene a `biblioteca` y `socios`) → **New → Scala Class**. Nombre: `Main`. Tipo: **Object**.
2. Contenido:

```scala
package practica

import practica.biblioteca.Libro
import practica.socios.Socio

// object + extends App: un objeto único cuyo cuerpo se ejecuta al correr el programa.
// Es la forma de punto de entrada que usa la materia.
object Main extends App {
  val quijote = new Libro("Don Quijote", 1200)
  val ana = new Socio("Ana")

  ana.pedir(quijote)

  println(ana.nombre + " tiene " + ana.librosPrestados + " libro/s")
  println("Páginas pendientes: " + ana.paginasPendientes)
  println("¿Puede pedir otro? " + ana.puedePedir)
}
```

Hacé clic en el **▷** al margen de `object Main` → **Run 'Main'**.

**✅ Deberías ver** en la pestaña Run:

```
Ana tiene 1 libro/s
Páginas pendientes: 1200
¿Puede pedir otro? true

Process finished with exit code 0
```

---

## 5. Los tests

Los tests van en `src/test/scala`, **con la misma estructura de packages** que el código que prueban. Es convención, y es la que sigue el repo del TP: el test de `Socio` va en `practica.socios`.

1. Botón derecho sobre `src/test/scala` → **New → Package**. Nombre: `practica.socios`.
2. Botón derecho sobre esa carpeta `socios` (la de `test`) → **New → Scala Class**. Nombre: `SocioTest`. Tipo: Class.
3. Contenido:

```scala
package practica.socios

// AnyFunSuite define test("…") { … }; Matchers define shouldBe. Libro viene del otro package.
import org.scalatest.funsuite.AnyFunSuite
import org.scalatest.matchers.should.Matchers
import practica.biblioteca.Libro

// Cada test("…") es un caso. shouldBe compara lo que salió con lo que esperabas.
class SocioTest extends AnyFunSuite with Matchers {

  test("un socio nuevo no tiene libros") {
    val ana = new Socio("Ana")
    ana.librosPrestados shouldBe 0
  }

  test("pedir un libro suma sus páginas") {
    val ana = new Socio("Ana")
    ana.pedir(new Libro("Don Quijote", 1200))
    ana.paginasPendientes shouldBe 1200
  }

  test("devolver un libro resta sus páginas") {
    val ana = new Socio("Ana")
    val quijote = new Libro("Don Quijote", 1200)
    ana.pedir(quijote)
    ana.devolver(quijote)
    ana.paginasPendientes shouldBe 0
  }

  test("con tres libros ya no puede pedir") {
    val ana = new Socio("Ana")
    ana.pedir(new Libro("Uno", 100))
    ana.pedir(new Libro("Dos", 100))
    ana.pedir(new Libro("Tres", 100))
    ana.puedePedir shouldBe false
  }
}
```

Fijate que `Socio` no necesita `import`: el test está en el mismo package. `Libro` sí.

Hacé clic en el **▷** al margen de `class SocioTest` → **Run 'SocioTest'**. El ▷ de la clase corre todos; el ▷ de cada `test` corre uno solo.

**✅ Deberías ver:** la pestaña Run con una barra **verde** arriba, el texto **"4 tests passed, 4 tests total"** (el texto exacto varía por versión), y a la izquierda el árbol con los cuatro nombres y un tilde verde cada uno. Al final, `Process finished with exit code 0`.

⚠️ La primera vez que corrés un test, IntelliJ tarda unos segundos más: compila los tests y arranca ScalaTest. Las siguientes son rápidas.

---

## 6. Ver un test fallar (a propósito)

Un test que falla es lo que vas a mirar cien veces este cuatrimestre. Mejor ver uno ahora, controlado.

En `SocioTest`, en el segundo test, cambiá `shouldBe 1200` por `shouldBe 1000`. Corré la clase otra vez.

**✅ Deberías ver:** la barra de arriba **roja**, "1 test failed, 3 passed, 4 tests total" (o parecido), y en el árbol de la izquierda el test "pedir un libro suma sus páginas" con una cruz roja. Al hacer clic en él, a la derecha:

```
1200 was not equal to 1000
ScalaTestFailureLocation: practica.socios.SocioTest at (SocioTest.scala:18)
```

Leé esa línea así: **lo que salió** (`1200`) **no fue igual a lo que esperabas** (`1000`), en el archivo y la línea indicados. Siempre en ese orden: primero el valor real, después el esperado. Es el formato de ScalaTest, y aparece igual en el TP.

Volvé a poner `1200`. Corré. Verde de nuevo.

**Correr todos los tests del proyecto de una vez**, como lo hace la cátedra para corregir: panel **sbt** (pestaña vertical derecha) → desplegá tu proyecto → **sbt tasks** → doble clic en **test**.

**✅ Deberías ver:** una consola de sbt con el resumen `Tests: succeeded 4, failed 0, canceled 0, ignored 0, pending 0`.

Si además tenés sbt instalado en el sistema, `sbt test` en la terminal integrada hace exactamente lo mismo. Si responde `command not found: sbt`, es normal: el plugin de IntelliJ trae su propio sbt, solo para el IDE.

---

## 7. Guardar en git

Terminal integrada:

```bash
git add .
git status
```

**✅ Deberías ver** bajo "Changes to be committed": `deleted: src/main/scala/main.scala` y cuatro archivos nuevos (`Libro.scala`, `Socio.scala`, `Main.scala`, `SocioTest.scala`). Nada de `target/`.

```bash
git commit -m "Dominio biblioteca: Libro, Socio, Main y SocioTest"
```

**✅ Deberías ver:** `[main …] Dominio biblioteca…` (o `[master …]`) seguido de `5 files changed`: cuatro nuevos y uno borrado.

---

## Checkpoint de la Parte 3

- [ ] Hay dos packages en `src/main/scala`: `practica.biblioteca` y `practica.socios`, más `Main` en `practica`.
- [ ] Viste el aviso `Cannot resolve symbol Libro` al sacar el import, y desapareció al ponerlo.
- [ ] `Run 'Main'` imprime las tres líneas.
- [ ] `SocioTest` da 4 tests en verde desde el ▷.
- [ ] Viste un test en rojo con `X was not equal to Y` y lo arreglaste.
- [ ] Segundo commit hecho.

**Para practicar un rato más, sin instrucciones:** agregale a `Socio` un método `devolverTodo` que deje ambos contadores en cero, y escribile su test primero. Cuando el test pase, listo.

## Lo que viene

**Parte 4:** abrís el repo del TP. Tiene una estructura distinta a la de este proyecto (la raíz del repo contiene `ruby/` y `scala/`), y hay una forma de abrirlo que funciona y otra que no. Las dos están documentadas, con lo que vas a ver en cada una.

**FIN DE LA PARTE 3**
