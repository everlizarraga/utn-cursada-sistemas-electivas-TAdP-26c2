# Playbook — preclase07: Instalación de ambientes para Scala — Parte 2: Tu primer proyecto

**Unidad:** preclase07 · **Parte 2 de 4** · **Dónde corre:** IntelliJ, y la terminal integrada de IntelliJ en la sección 6.

**De dónde venís:** Parte 1. Tenés IntelliJ Community con el plugin de Scala, y las versiones anotadas: Scala 3.3.1 · sbt 1.9.0 · JDK 17 · ScalaTest 3.2.19.

**Qué hacés acá:** creás un proyecto desde cero con el asistente, entendés qué carpeta es qué, agregás ScalaTest, corrés un programa, escribís el `.gitignore` y dejás el proyecto bajo git. Este proyecto es de práctica: en la Parte 3 le escribís un dominio adentro.

---

## 1. Crear el proyecto

1. Pantalla de bienvenida → **New Project**. (Con un proyecto abierto: File → New → Project.)
2. En la lista de la izquierda elegí **Scala**.
3. Completá el formulario de la derecha, campo por campo:

| Campo | Qué poner | Por qué |
|---|---|---|
| **Name** | `practica-scala` (o el que quieras, sin espacios; ver la tabla de nombres al final de esta sección) | Es el nombre de la carpeta y del proyecto. |
| **Location** | la carpeta donde guardás las cosas de la materia | Debajo se crea una carpeta con el nombre del proyecto. |
| **Create Git repository** | destildado | El git lo armás a mano en la sección 6, para ver qué hace cada paso. |
| **Build system** | **sbt** | Es el que usa el TP y el que usa la cátedra. Las otras dos opciones (IntelliJ, Scala CLI) quedan afuera. |
| **JDK** | desplegá. Si ofrece directamente **Download Microsoft OpenJDK 17.x (aarch64)**, elegilo. Si no, **Download JDK…** → versión **17** → cualquier proveedor (Microsoft, Eclipse Temurin) → Download | IntelliJ lo baja e instala solo. En Mac con chip M, la variante **aarch64** es la del procesador. |
| **sbt** | **1.9.0** | Si el desplegable trae otra, abrilo y buscá 1.9.0. |
| **Scala** | **3.3.1** | Igual: abrí el desplegable y buscá 3.3.1. |
| **Download sources** (dos casillas) | tildadas | Permite que IntelliJ te muestre el código de Scala y de las librerías cuando hacés `⌘ clic` sobre algo. |
| **Use significant indentation syntax (Optional Braces)** | **destildado** | En esta materia se escribe con llaves `{ }`, como en el repo y en las clases. |
| **Package prefix** | vacío | Los packages los escribís vos en cada archivo. |
| **Add sample code** | **tildado** | Te genera un programa mínimo para comprobar que todo corre. |

4. **Create**.

**✅ Deberías ver:** IntelliJ abre el proyecto y abajo a la derecha aparece una barra de progreso con mensajes como "Downloading JDK…", después "Importing sbt project…" o "sbt: syncing…". **Esperá a que termine**: la primera vez baja el JDK, sbt, Scala y sus librerías, y puede llevar entre dos y diez minutos según la conexión.

⚠️ Mientras la barra de progreso está activa, el proyecto todavía no funciona: los archivos `.scala` se ven con el texto en rojo o sin colores. Es normal. Cuando termina, los colores aparecen.

⚠️ Hacelo con una conexión estable y con tiempo: la primera sincronización descarga unos cientos de MB.

---

### Sugerencia de buenas prácticas para los nombres

Es convención, no regla del compilador, salvo donde lo dice la tabla. Seguirla hace que tu código se vea como el de la cátedra y el de las librerías.

| Qué nombrás | Convención | Ejemplo | Lo que el compilador exige |
|---|---|---|---|
| Proyecto y carpeta | minúsculas con guiones | `practica-scala` | Nada; pero sin espacios, tildes ni ñ te ahorrás problemas en terminal y en git |
| Package | minúsculas, solo letras y puntos | `practica.biblioteca` | **Sí:** sin guiones ni espacios, porque es un identificador. `practica-scala` como package no compila |
| Clase, trait, object | `PascalCase` | `Libro`, `SocioTest` | Nada; pero el archivo lleva el mismo nombre: `Libro.scala` |
| Método, variable, parámetro | `camelCase` | `paginasPendientes`, `pedir` | Nada |
| Test | el nombre de la clase + `Test` o `Spec` | `SocioTest`, `ProjectSpec` | Nada; es lo que usan la cátedra y el repo |

Scala distingue mayúsculas de minúsculas en todo: `libro` y `Libro` son dos nombres distintos, y así se usa (`val libro = new Libro(...)`).

## 2. Qué es cada carpeta

Cuando termina la importación, el panel **Project** de la izquierda muestra esto:

```
practica-scala/
├── .bsp/                       ← lo crea sbt para hablar con IntelliJ. Se ignora en git.
├── .idea/                      ← configuración de IntelliJ. Se ignora en git.
├── project/
│   └── build.properties        ← una sola línea: sbt.version=1.9.0
├── src/
│   ├── main/scala/             ← acá va el programa
│   │   └── main.scala          ← el sample code
│   └── test/scala/             ← acá van los tests (vacía por ahora)
├── target/                     ← lo compilado. Se ignora en git.
└── build.sbt                   ← la configuración del proyecto
```

Tres de esas carpetas (`.bsp`, `.idea`, `target`) las genera la herramienta y se regeneran solas; por eso van al `.gitignore` en la sección 5. Lo tuyo vive en `src/` y en `build.sbt`.

Abrí `build.sbt` con doble clic. Es esto:

```scala
ThisBuild / scalaVersion := "3.3.1"

lazy val root = (project in file("."))
  .settings(
    name := "practica-scala"
  )
```

Léelo así: la versión de Scala vale para todo el proyecto (`ThisBuild`), y el proyecto es la carpeta actual (`file(".")`) con un nombre. Las dependencias (las librerías) se agregan dentro de `.settings(...)`, y eso es lo que hacés ahora.

---

## 3. Agregar ScalaTest

El asistente de IntelliJ crea el proyecto sin librería de tests. Esta es la línea que más gente busca en tutoriales viejos: va **dentro de `.settings(...)`**, debajo de `name`, y la línea de `name` necesita una **coma al final**.

Dejá el `build.sbt` exactamente así:

```scala
ThisBuild / scalaVersion := "3.3.1"

lazy val root = (project in file("."))
  .settings(
    name := "practica-scala",
    libraryDependencies += "org.scalatest" %% "scalatest" % "3.2.19" % Test
  )
```

Qué dice la línea nueva, de izquierda a derecha: a las librerías del proyecto (`libraryDependencies`) agregale (`+=`) la de la organización `org.scalatest`, llamada `scalatest`, versión `3.2.19`, y usala solo para los tests (`% Test`). El `%%` del medio le pega a `scalatest` el sufijo de la versión de Scala (`scalatest_3`), que es como está publicada; con un `%` simple sbt la buscaría sin sufijo y la descarga fallaría.

Guardá (`⌘ S` / `Ctrl S`).

**✅ Deberías ver:** arriba a la derecha del editor aparece un ícono chico con dos flechas en círculo, a veces con el texto **"Load sbt Changes"** o una barra celeste que dice que el `build.sbt` cambió. Hacé clic. Vuelve la barra de progreso de abajo, esta vez más corta: está bajando ScalaTest. Si el botón no está exactamente ahí, buscá uno con dos flechas en círculo, o usá el camino del ⚠️ de abajo.

⚠️ Si guardaste y no aparece nada, abrí el panel **sbt** (pestaña vertical en el borde derecho de la ventana, con el ícono de sbt) y hacé clic en el primer botón de su barra, el de las dos flechas (**Reload All sbt Projects**). Es lo mismo.

**✅ Deberías ver (cuando termina):** en el panel Project, **External Libraries** desplegado tiene entradas que empiezan con `sbt: org.scalatest:scalatest…`. Si está, ScalaTest quedó disponible.

---

## 4. Correr el programa de ejemplo

Abrí `src/main/scala/main.scala`. El sample code tiene un `@main def main()` que imprime del 1 al 5 de dos formas. Da igual qué hace: sirve para ver que la cadena entera (JDK → sbt → compilador → ejecución) funciona.

Hacé clic en el **▷ verde** que aparece en el margen izquierdo, al lado de `def main`, y elegí **Run 'main'**.

**✅ Deberías ver:** abajo se abre la pestaña **Run**, pasan unas líneas de compilación, y después:

```
1
2
3
4
5
i = 1
i = 2
i = 3
i = 4
i = 5

Process finished with exit code 0
```

El `exit code 0` del final es la señal de que terminó bien. Con esto, Scala compila y corre en tu máquina.

🕳️ **Nota al margen — `@main` vs `extends App`.** El sample code usa `@main`, una forma de Scala 3. En la materia y en el repo del TP se usa `object X extends App { … }`. Las dos sirven de punto de entrada; en la Parte 3 escribís la de la materia. *Seguí: esto se ve en el Módulo 0 de la clase07.*

---

## 5. El `.gitignore`

Este es el archivo que más tiempo hace perder. La regla: **siete líneas, escritas a mano, las mismas que usa la cátedra** en el repo del TP (más una para macOS).

1. En el panel Project, botón derecho sobre la carpeta raíz del proyecto (`practica-scala`) → **New → File**. Nombre: `.gitignore` (con el punto adelante).
2. Pegá esto y guardá:

```
target
.idea
project/target
.bsp
.bloop
.metals
.DS_Store
```

Qué ignora cada línea: `target` y `project/target` son lo compilado; `.idea` es la configuración personal de IntelliJ; `.bsp`, `.bloop` y `.metals` son archivos de enlace entre sbt y los editores; `.DS_Store` es basura que deja el Finder de macOS (en Windows y Linux la línea no molesta).

⚠️ **Cada entrada en su línea.** Si dos nombres quedan en la misma línea, git ignora una ruta que no existe y las carpetas reales aparecen en `git status`. Es el error típico de los generadores automáticos.

⚠️ Cuando IntelliJ muestre un cartel "IDE project settings can be added to Git" con botones *View Files / Always Add / Don't Ask Again*: **Don't Ask Again**. La carpeta `.idea` no se versiona.

---

## 6. Dejar el proyecto bajo git

**Dónde corre:** terminal integrada de IntelliJ. Abrila con el ícono de terminal en la barra vertical izquierda (abajo), o con `⌥ F12` / `Alt F12`. El prompt ya está parado en la carpeta del proyecto; verificalo con `pwd`.

```bash
git init
git add .
git status
```

**✅ Deberías ver** en el `git status`, bajo "Changes to be committed", solo estas entradas:

```
.gitignore
build.sbt
project/build.properties
src/main/scala/main.scala
```

Nada de `target/`, `.idea/` ni `.bsp/`. Si aparece alguna de esas, el `.gitignore` tiene una línea mal: volvé a la sección 5 y compará carácter por carácter.

Después:

```bash
git commit -m "Proyecto inicial de práctica: Scala 3.3.1, sbt 1.9.0, ScalaTest 3.2.19"
```

**✅ Deberías ver:** una línea `[main (root-commit) …] Proyecto inicial…` o `[master (root-commit) …]`, según cómo esté configurado tu git, seguida de `4 files changed`. Si salió `master` y querés que la rama se llame `main` como en GitHub: `git branch -M main`.

⚠️ Si el commit te pide nombre y mail (`Please tell me who you are`), es porque git no está configurado en esta máquina. Corré `git config --global user.name "Tu Nombre"` y `git config --global user.email "tu@mail"`, y repetí el commit.

---

## Checkpoint de la Parte 2

- [ ] El proyecto abre sin barra de progreso activa y el código tiene colores.
- [ ] `build.sbt` tiene la línea de ScalaTest dentro de `.settings`, con la coma después de `name`.
- [ ] External Libraries muestra `scalatest`.
- [ ] Run 'main' imprime del 1 al 5 y termina con `exit code 0`.
- [ ] `git status` después del `add` muestra solo cuatro archivos.
- [ ] Hay un primer commit.

## Lo que viene

**Parte 3:** usás este mismo proyecto para escribir un dominio chico en dos packages, con `import` entre ellos y tests con ScalaTest. Es la primera vez que escribís Scala vos; el código es corto y viene con la señal de éxito de cada paso.

**FIN DE LA PARTE 2**
