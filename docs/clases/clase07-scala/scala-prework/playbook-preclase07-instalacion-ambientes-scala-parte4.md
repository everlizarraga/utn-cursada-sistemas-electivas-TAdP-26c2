# Playbook — preclase07: Instalación de ambientes para Scala — Parte 4: Abrir el repo del TP

**Unidad:** preclase07 · **Parte 4 de 4** · **Dónde corre:** IntelliJ; la terminal integrada en la sección 1.

**De dónde venís:** Parte 3. Sabés crear un proyecto, dónde va cada archivo y cómo se corren los tests.

**Qué hacés acá:** abrís el repo del TP que entrega la cátedra, que **no es un proyecto Scala en su raíz**: es una carpeta con `ruby/` y `scala/` adentro, cada una un proyecto distinto. Hay una forma de abrirlo que IntelliJ entiende y otra que no. Las dos están documentadas con lo que vas a ver, para que reconozcas en qué caso estás.

---

## 1. Cómo es el repo

Si todavía no lo clonaste, hacelo desde la terminal, parado en la carpeta donde guardás los repos de la materia, con el link que te dio la cátedra (el repo se llama `grupoN-2026-2c`, con el número de tu grupo):

```bash
git clone <url-del-repo>
```

**✅ Deberías ver:** `Cloning into 'grupo1-2026-2c'…` y al final `done`. Queda una carpeta con `.github/`, `ruby/`, `scala/` y `README.md`.

La estructura, resumida:

```
grupo1-2026-2c/                 ← raíz del repo. Acá está el .git y el README
├── .github/                    ← los tests automáticos que corre GitHub con cada push
├── .idea/                      ← vino en el repo; no es tuyo. Ignorala
├── .gitignore
├── README.md
├── ruby/                       ← el proyecto de la primera mitad (RSpec, Gemfile…)
└── scala/                      ← el proyecto de la segunda mitad. ESTE es el proyecto sbt
    ├── build.sbt
    ├── project/build.properties
    ├── src/main/scala/Prueba.scala
    ├── src/test/scala/ProjectSpec.scala
    └── .gitignore
```

El `build.sbt` de la cátedra, resumido, es este y fija las versiones de la Parte 1:

```scala
ThisBuild / organization := "ar.edu.utn.frba.tadp"
ThisBuild / scalaVersion := "3.3.1"
ThisBuild / version := "1.0"

name := "tp-hibrido-objetos-funcional"

resolvers += "jitpack" at "https://jitpack.io"

libraryDependencies += "org.scalactic" %% "scalactic" % "3.2.19"
libraryDependencies += "org.scalatest" %% "scalatest" % "3.2.19" % "test"
```

Dos diferencias con el `build.sbt` que escribiste en la Parte 2, ninguna importante: las dependencias van sueltas en lugar de dentro de `.settings(...)` (sbt acepta las dos formas), y `% "test"` entre comillas es lo mismo que `% Test`. El archivo real además repite la dependencia de ScalaTest en un segundo bloque `libraryDependencies ++= Seq(...)`: es redundante e inofensivo. Vos no tocás este archivo.

---

## 2. La forma que no funciona: abrir la raíz del repo

Es lo primero que uno intenta, y conviene saber cómo se ve cuando falla.

**File → Open** → elegís la carpeta `grupo1-2026-2c` (la raíz) → Open.

**Lo que ves:** IntelliJ abre la carpeta como un proyecto vacío. Señales de que **no** detectó el proyecto Scala:

- `scala/` aparece como una carpeta común, igual que `ruby/`. Las subcarpetas `src/main/scala` y `src/test/scala` están en gris, sin el azul ni el verde que las marca como código y tests.
- `Prueba.scala` y `ProjectSpec.scala` tienen un ícono gris, sin el ▷ al margen para correrlos.
- Botón derecho sobre `scala/build.sbt`: el menú no ofrece ninguna opción del estilo "Link sbt Project" o "Import sbt Project".
- En el borde derecho de la ventana no hay pestaña **sbt**.

Desde la raíz, IntelliJ busca un `build.sbt` **en la carpeta que abriste**, no una más adentro. Como no lo encuentra, trata todo como texto. Cerrá esa ventana (File → Close Project) y hacé la sección 3.

⚠️ Si al abrir la raíz IntelliJ te preguntó algo sobre Maven o Gradle, es porque otro proyecto Java tuyo dejó configuración; decile que no. Acá nada es Maven.

---

## 3. La forma que funciona: abrir la carpeta `scala/`

**File → Open**. Dos caminos; **anotá cuál usaste**, por si lo repetís en otra máquina:

- **Camino A (el comprobado):** navegá hasta `scala/build.sbt`, seleccioná el archivo y **Open**. Aparece un cartel titulado *Open Project*: *"build.sbt is a project file. Would you like to open the project?"* con botones *Cancel / Open as File / Open as Project*. Elegí **Open as Project**.
- **Camino B:** navegá hasta la carpeta `scala` (adentro de `grupo1-2026-2c`), seleccionala y **Open**. Debería dar lo mismo. Si al terminar la importación no aparece la pestaña sbt, cerrá la ventana y usá el Camino A.

En los dos casos, si tenías otro proyecto abierto, IntelliJ pregunta **This Window / New Window**. Elegí **New Window**: cada proyecto en su ventana.

**✅ Deberías ver:** barra de progreso abajo ("Importing sbt project…"). Al terminar:

- La ventana se titula **`tp-hibrido-objetos-funcional`**: IntelliJ leyó el nombre del `build.sbt`.
- En el panel Project, la raíz dice `scala [tp-hibrido-objetos-funcional]`.
- `src/main/scala` tiene el ícono azul de código y `src/test/scala` el verde de tests.
- Apareció la pestaña **sbt** en el borde derecho; al abrirla muestra `tp-hibrido-objetos-funcional` con los nodos `sbt commands`, `sbt settings`, `sbt tasks`, `Dependencies`, `main`, `test` y `tp-hibrido-objetos-funcional-build`. En `sbt tasks` está el `test` que corre todo, como en la Parte 3.
- Aparecieron `.bsp/` y `target/`, que ya están en el `.gitignore` de la carpeta `scala/`.
- Arriba, al lado del nombre del proyecto, aparece la rama de git (`main`). IntelliJ encontró el `.git` en la carpeta de arriba y lo usa igual: **commits y push los hacés normalmente desde esta ventana**, aunque hayas abierto una subcarpeta.

---

## 4. Verificar el JDK (paso que se saltea sin darse cuenta)

🔴 **Al importar, IntelliJ no pregunta qué JDK usar: toma el primero que encuentra en la máquina.** Si tenés Java por otra materia (21, 26, el que sea), es probable que haya elegido ese, y vos no te enteraste. El proyecto compila igual, pero con una versión distinta a la de los tests de GitHub. Se revisa en dos lugares, porque son dos configuraciones.

**1. El JDK del proyecto** (el que usan el editor y el ▷):

**File → Project Structure** (`⌘ ;` en Mac / `Ctrl Alt Shift S`) → **Project** → campo **SDK**.

**✅ Deberías ver:** `ms-17 Microsoft OpenJDK 17.0.x - aarch64` (o el nombre del 17 que bajaste en la Parte 2). Si dice otra cosa, como `homebrew-21`, desplegá: el 17 está en la lista, porque ya lo bajaste. Elegilo → **Apply** → **OK**. Más abajo, bajo "Detected SDKs", pueden aparecer otros Java de tu máquina; ignoralos.

**2. El Java con el que corre sbt** (el de la sbt shell y de `sbt tasks`):

Abrí la **sbt shell** (ícono en la barra izquierda, o View → Tool Windows → sbt shell). Si ya estaba corriendo de antes, apagala con el cuadrado rojo y volvé a arrancarla con la flecha verde, para que tome el cambio. Leé la primera línea `[info]`.

**✅ Deberías ver:** `[info] welcome to sbt 1.9.0 (Microsoft Java 17.0.x)`. sbt toma el JDK del proyecto, así que con el paso 1 alcanza.

⚠️ Si la shell sigue diciendo otro Java: **Settings** (`⌘ ,` / `Ctrl Alt S`) → **Build, Execution, Deployment → Build Tools → sbt** → campo **JRE** → elegí **Project JDK** → Apply, y reiniciá la shell.

⚠️ El mismo chequeo vale para cualquier proyecto Scala que abras, incluido el de la clase07 (sección "Lo que viene").

---

## 5. Correr el test de la cátedra

El repo viene con un test de humo, `ProjectSpec`, cuyo único propósito es confirmar que las dependencias bajaron y que todo compila. Abrilo: `src/test/scala/ProjectSpec.scala`.

```scala
import org.scalatest.matchers.should.Matchers._
import org.scalatest.freespec.{AnyFreeSpec}

class ProjectSpec extends AnyFreeSpec {

  "Este proyecto" - {

    "cuando está correctamente configurado" - {
      "debería resolver las dependencias y pasar este test" in {
        Prueba.materia shouldBe "tadp"
      }
    }
  }

}
```

Hacé clic en el **▷** al margen de `class ProjectSpec` → Run.

**✅ Deberías ver:** barra verde, **"1 test passed, 1 test total"**, y en el árbol: *Este proyecto → cuando está correctamente configurado → debería resolver las dependencias y pasar este test* con tilde verde. `Process finished with exit code 0`.

Con eso el repo está operativo. Lo que escribas en `src/main/scala` y `src/test/scala` compila con las mismas versiones que todo el material.

`Prueba.scala`, el otro archivo del repo, no tiene ▷: es un `case object` con un solo método y sin `extends App`, así que no hay nada para ejecutar. Existe para que `ProjectSpec` tenga algo que probar. Un programa ejecutable se escribe como el `Main` de la Parte 3.

---

## 6. Dos estilos de test, la misma librería

Este test se ve distinto al `SocioTest` de la Parte 3. Son dos **estilos** de ScalaTest, y los dos vienen en la misma librería que ya tenés:

| | `AnyFunSuite` (Parte 3, clases de la materia) | `AnyFreeSpec` (el `ProjectSpec` del repo) |
|---|---|---|
| Base | `extends AnyFunSuite with Matchers` | `extends AnyFreeSpec` + `import …Matchers._` |
| Un caso | `test("descripción") { … }` | `"descripción" in { … }` |
| Agrupar | una clase por tema | `"grupo" - { … }` anidable |
| Comparar | `x shouldBe 90` | `x shouldBe 90` (igual) |

Corren igual, fallan igual (`X was not equal to Y`) y se mezclan sin problema en el mismo proyecto. En el TP podés escribir tus tests en cualquiera de los dos; el material de las clases usa `AnyFunSuite` porque es el que usa la cátedra en las clases (`AtaqueTest`) y el más simple: una clase, una lista de `test`. `ProjectSpec` queda como está: es de la cátedra.

🕳️ **Nota al margen — `import …Matchers._`.** En `ProjectSpec` los matchers entran con un `import` con `_` al final (trae todo lo de adentro) en lugar de `with Matchers`. Es otra forma de tener `shouldBe` disponible; las dos valen. *Seguí: lo que importa es que `shouldBe` está.*

---

🕳️ **Madriguera — varios proyectos en un solo `build.sbt`.** Si venís de Maven con un POM padre y módulos hijos: sbt tiene lo mismo, se llama *multi-proyecto*. Un `build.sbt` en la raíz declara cada módulo con `lazy val servicioA = project in file("servicio-a")`, y uno depende de otro con `.dependsOn(servicioA)`; IntelliJ lo importa como módulos, igual que con Maven. El repo del TP está armado de otra forma: `ruby/` y `scala/` son dos proyectos sueltos, sin un `build.sbt` arriba que los una, y por eso la raíz no se importa. En esta materia alcanza con un proyecto solo. *Volvé al camino — esto se profundiza aparte, otro día.*

## 7. Qué pasa con `ruby/`

La carpeta `ruby/` es el proyecto de la primera mitad. Se abre con RubyMine (o IntelliJ Ultimate con el plugin de Ruby) apuntando a esa carpeta, igual que acá apuntaste a `scala/`. Desde IntelliJ Community con el plugin de Scala, `ruby/` es texto plano y no hace falta abrirla: la ventana de `scala/` es tu proyecto de la segunda mitad.

---

## Checkpoint de la Parte 4

- [ ] Viste cómo se ve el repo abierto desde la raíz (todo gris, sin pestaña sbt) y sabés que esa no es la forma.
- [ ] Abriste `scala/build.sbt` → Open as Project (camino A) o la carpeta `scala/` (camino B); anotaste cuál.
- [ ] La ventana se llama `tp-hibrido-objetos-funcional` y tiene la pestaña sbt.
- [ ] Project Structure → SDK dice 17, y la sbt shell arranca con `Microsoft Java 17`.
- [ ] `ProjectSpec` da 1 test en verde.
- [ ] Reconocés los dos estilos de test y sabés que `shouldBe` funciona en ambos.

## Lo que viene

Hasta acá la preclase. Lo que sigue es la **clase07** (Tipado estático en Scala), empezando por el Módulo 0, que presenta el proyecto en el que corre todo el código de la unidad. Ese proyecto es el `tadp-clase07-tipado-estatico.zip` del `fuente-repo-clase07`: descomprimilo y abrilo como en el Camino A de esta parte: File → Open, seleccioná su `build.sbt` → Open as Project. Verificá el JDK como en la sección 4. Si `AtaqueTest` da seis tests en verde, estás listo para el Módulo 0.

**FIN DE LA PARTE 4 — FIN DEL PLAYBOOK preclase07**
