# Código final unificado — clase10 — Comportamiento vs estructura y mónadas

> **Qué es este archivo.** El código completo y funcional de la unidad `clase10` (sábado 31-Oct-2026), escrito para **Scala 3.3.1**, sbt 1.9.0 y ScalaTest 3.2.19 (las versiones del repo del TP). Es la referencia sobre la que se apoya todo el material de la unidad: lo que figura acá se pega y corre. Tiene tres bloques:
>
> 1. **El microprocesador con mónadas** (`tadp.microprocesador.monadas`): el proyecto `funcional-monadas` del repo de cátedra, con cuatro versiones de `run`.
> 2. **Los niveles de abstracción** (`tadp.niveles`): el ejemplo de materias, cursos y alumnos resuelto cinco veces, cada vez un nivel más arriba, más la lista *snoc*, el `fold` a mano, el lifteo y los monoides.
> 3. **Las cajas** (`tadp.cajas`): el contrato de mónada sobre una caja propia, el mail del titular con `Option`, la inscripción con `Try` y el `for` secuencial contra el paralelo con `Future`.
>
> **Qué no es.** No es una copia fiel del repo de cátedra. El bloque 1 sale del repo (`scala-microprocesador-tuneado`, proyecto `funcional-monadas`), con los bugs **arreglados con el cambio mínimo** y declarados uno por uno. Los bloques 2 y 3 **no están en el repo**: son el código de las diapositivas (video 2020 y lo proyectado en la presencial) y del pizarrón de la presencial, **reconstruido completo** para que compile y corra. Cada archivo dice de dónde sale y qué se completó.
>
> **Generado:** 01-Nov-2026 · **Repo de cátedra:** `tadp-utn-frba/tadp-clases`, rama `scala-microprocesador-tuneado`, commit `ea59fa3` (2025-06-07, "Actualizada version monadas a scala 3") · **Estado:** revisado en segunda pasada por un revisor independiente (14 hallazgos, todos aplicados) · **Compilación:** verificada con el compilador real de **Scala 3.3.1** (`scalac -encoding UTF-8 -deprecation -feature -Werror`): 0 errores, 0 advertencias. **Tests (agregados, no son de la cátedra):** los 38 pasan. Ver "Verificación".

## Los tres bloques

| Paquete | Qué es | De dónde sale |
|---|---|---|
| `tadp.microprocesador.monadas` | `Micro` inmutable, las instrucciones y cuatro versiones de `run`: `Operations1` (`Result` propio con `map` y `flatMap`), `Operations2` (el mismo `Result`, usado con `for`), `Operations3` (`Try[Micro]` con `map` y `flatMap`) y `Operations4` (`Try[Micro]` con `for`) | Repo de cátedra, proyecto `funcional-monadas` |
| `tadp.niveles` | Dominio `Materia` / `Curso` / `Alumno` y la misma consulta resuelta en cinco niveles: pattern matching, tipo algebraico (`isEmpty`/`head`/`tail`), `foldRight`, `filter`/`map`/`flatMap`, `for`. Además: `ListaSnoc`, el `fold` a mano, lifteo y monoides | Diapositivas (parte 1 y 3 del video 2020; la primera, proyectada también en la presencial) y pizarrón de la presencial |
| `tadp.cajas` | `Caja` (el contrato `unit`/`bind`/`zero`/`plus` con `map` y `filter` derivados), mail del titular (`null` contra `Option`), inscripción (excepciones contra `Try`), `for` secuencial contra paralelo y `Future.sequence` | Diapositivas (partes 2 y 3 del video 2020) y pizarrón de la presencial |

## Procedencia y adaptaciones

| Archivo | De dónde sale | Adaptaciones declaradas |
|---|---|---|
| `build.sbt`, `.gitignore`, `project/build.properties` | Propios, con las versiones del repo del TP (3.3.1 / 1.9.0 / 3.2.19), igual que en clase09 | El `build.sbt` de la cátedra (verbatim más abajo) dice `name := "granja"`, copiado de otra clase, y usa Scala 3.7.0 y sbt 1.11.0 |
| `monadas/Instructions.scala` | Repo `funcional-monadas`, idéntico al de `funcional-inmutable` (clase09) | Paquete. Espaciado normalizado (sin espacios al final de línea, salto de línea final) |
| `monadas/Micro.scala` | Repo `funcional-monadas` | Paquete. Espaciado normalizado (tabs a espacios, salto de línea final). **Bug A arreglado** (el mismo de clase09) |
| `monadas/Operations1.scala` | Repo `funcional-monadas` = capturas del video (parte 4, slides 5 a 8) = presencial (transcripción parte 2, 1:01:56 a 1:04:23) | Paquete. **Bug B arreglado** |
| `monadas/Operations2.scala` | Repo `funcional-monadas` = capturas del video (parte 4, slides 9 y 10). Las slides 1 a 3 de la parte 4 también dicen `Operations2`, pero muestran otro código: el `run` con `foldLeft` y excepción de `funcional-inmutable` (clase09) | Paquete. **Bugs B y C arreglados** |
| `monadas/Operations3.scala` | Repo `funcional-monadas`. **No está en el video 2020**: la cátedra lo agregó en 2023 (commit `f20b8a0`, "add Try[Micro] example without for comprehension"). En la presencial se mostró la versión con `Try` (transcripción parte 2, 1:04:23 a 1:05:27) | Solo el paquete |
| `monadas/Operations4.scala` | Repo `funcional-monadas` = capturas del video (parte 4, slides 11 y 12, donde se llamaba `Operations3`) = presencial (transcripción parte 2, 1:05:27 a 1:06:15, donde el `for` se describe como la flecha `<-` más el `yield`) | Paquete. **Bug C arreglado** |
| `niveles/Dominio.scala` | Diapositiva 1 de la parte 1 (diagrama `Materia` → `cursos *` → `Curso` → `inscriptos *` → `Alumno`) | **Reconstruido.** La diapositiva da solo los miembros; acá son `case class`. `código(): Boolean` pasa a `codigo: String` (un código de tipo booleano es errata de la diapositiva, y el código no lo usa) |
| `niveles/Nivel1PatternMatching.scala` | Diapositivas 2 a 6 de la parte 1 = foto 4 (proyectada en la presencial) | Verbatim. **Agregado:** `legajosDeRegularesEnElectivas`, que envuelve la expresión final de la diapositiva (`legajos(regulares(…(todasLasMaterias))))`) para poder llamarla |
| `niveles/Nivel2TipoAlgebraico.scala` | Diapositivas 7 a 9 de la parte 1; pizarrón, foto 9 (`head`, `tail`, `isEmpty`, `empty`, `::`) | Verbatim. Mismo agregado que el nivel 1 |
| `niveles/ListaSnoc.scala` | Diapositivas 5 y 8 de la parte 1 (`List'[T]` con `Nil`/`:+`, y el globo con `head`, `tail` y `::`); pizarrón, fotos 5, 10 y 11 (`Snoc`, `last`, `init`, `(Snoc Nil 1).head`) | **Reconstruido.** La diapositiva da tres métodos sueltos; acá es un tipo completo. Los nombres `VaciaSnoc` y `Snoc` evitan chocar con `Nil` de Scala. **Corrección necesaria:** la diapositiva escribe `elem :: init :+ last`, que no compila (ver "Erratas de las diapositivas"); acá va `(elem :: init) :+ last`. **Agregado para estudio:** `Nivel2SobreSnoc`, con `regulares` y `legajos` del nivel 2 sobre esta otra lista |
| `niveles/Nivel3Fold.scala` | Diapositivas 10 a 14 de la parte 1; el `fold` a mano, del pizarrón (fotos 6 y 8) | Verbatim. Mismo agregado que el nivel 1. **Reconstruido:** el `fold` a mano, traducido de las ecuaciones del pizarrón (escritas en Haskell) |
| `niveles/Nivel4OrdenSuperior.scala` | Diapositivas 15 a 21 de la parte 1 (las cinco funciones) y 22–23 (la expresión encadenada; repetida en la diapositiva 20 de la parte 3) | Verbatim. Mismo agregado que el nivel 1. La expresión encadenada va dentro de `encadenado` |
| `niveles/Nivel5For.scala` | Diapositivas 21 y 22 de la parte 3; pizarrón, foto 24 (`←` y `yield`) | Verbatim. **Agregado para estudio:** `traducido`, lo que el compilador escribe a partir del `for` (con `withFilter`, no con `filter`) |
| `niveles/Lifteo.scala` | Presencial (transcripción parte 1, 1:42:26 a 1:45:36); video 2020 (30:28, "Map hace lo que llama liftear"); diapositivas 17 a 20 de la parte 1 (firmas con `([a] -> [b])`); pizarrón, fotos 14 y 16 (las mismas firmas y `(filter even)`) | **Reconstruido.** La clase lo planteó con firmas de Haskell, sin código Scala |
| `niveles/Monoide.scala` | Presencial (transcripción parte 1, 18:11 a 21:55); pizarrón, foto 7 (cerrada, asociativa, elemento neutro; `<>` con `+`/`Int`, `*`/`Int`, `++`/`String`, `(.)`/`a → a`, `&&`/`Bool`, `||`/`Bool`) | **Reconstruido.** La clase lo planteó en Haskell (`<>`); acá es un `trait` con una instancia por cada fila del pizarrón |
| `cajas/monada/Caja.scala` | Diapositivas 25 a 29 de la parte 2 (`unit`, `bind`, `zero`, `plus`; `Monad[T]` y `MonadPlus[T]`; `map` y `filter` a partir de `flatMap`); pizarrón, fotos 17 a 21 (`Monada`: `bind`, `unit`; `MonadaPlus`: `zero`, `plus`) | **Reconstruido.** Las diapositivas dan el contrato y dos métodos derivados; acá es una caja completa (`Llena` / `Vacia`) que lo cumple. Con `import Caja.{unit, zero}`, los cuerpos de `map` y `filter` son los de la diapositiva 29, con la única corrección `bool` → `Boolean`. Lleva además `withFilter`, que Scala 3.3.1 exige para usar `if` dentro de un `for` (ver "Verificación") |
| `cajas/mail/MailDelTitular.scala` | Diapositivas 9 a 12 de la parte 3 (`Curso` / `Docente` con `null` y con `Option`); presencial (transcripción parte 2, 0:00 a 13:40); pizarrón, fotos 16, 17 y 22 (`flatMap mail`, `flatMap mandar`) | **Reconstruido.** Dominio, `Log` y `mandarMailA` son propios (la diapositiva los usa sin definirlos). `ConNull.enviarAlTitular` y `ConOption.enviarAlTitular` tienen el cuerpo de las diapositivas 10 y 11. `ConOptionYMandarQuePuedeFallar` es la versión del pizarrón, donde mandar el mail también devuelve una caja y por eso va con `flatMap` |
| `cajas/inscripcion/Inscripcion.scala` | Diapositivas 17 y 18 de la parte 3 (`anotar` con `try`/`catch` y con `Try`/`recover`); presencial (transcripción parte 2, 44:24 a 46:26); pizarrón, foto 22 (`recover`) | **Reconstruido.** `Alumno`, `Docente`, `Curso`, `NoHayCupo` y `NoAutorizado` son propios, armados con los miembros del diagrama de la diapositiva (`hayCupo`, `inscribir`, `autorizarIngreso`) y la flecha `Curso → Docente`, que en el código es `curso.docente`. Los dos `anotar` son verbatim |
| `cajas/futuros/SecuencialVsParalelo.scala` | Pizarrón, fotos 23 (`[F(docente1), F(docente2)]` → `F([docente1, docente2])`), 25 y 26 (`for` con `estaCaja()` / `otraCaja()` adentro y con `cx` / `cy` creados antes); presencial (transcripción parte 2, 46:52 a 49:19 y 52:44 a 57:19 para `Future` y la lista de futuros; 1:12:26 a 1:15:09 para los dos `for`) | **Reconstruido.** El pizarrón da solo los dos `for`; las cajas, la demora y el registro de eventos son propios |
| `MonadasTest.scala`, `NivelesTest.scala`, `CajasTest.scala` | **AGREGADOS.** Ni el repo ni las diapositivas traen tests | Generados para esta referencia. Los dos ejemplos de código del script de la cátedra (`caja.filter(f).map(g)…size > 2` y la cadena de `flatMap`/`filter`/`map` contra su `for`) están en `CajaTest`, con funciones concretas en lugar de `f`, `g`, `tx1`… |

**El `build.sbt` de la cátedra**, verbatim (proyecto `funcional-monadas`):

```scala
organization := "ar.edu.utn.frba.tadp"

name := "granja"

version := "1.0"

scalaVersion := "3.7.0"

libraryDependencies ++= List(
  "org.scalatest" %% "scalatest" % "3.2.19" % "test"
)
```

Y su `project/build.properties`: `sbt.version=1.11.0`. El proyecto trae además `LICENSE` (GPL) y `.bsp/sbt.json` (configuración local de IntelliJ de quien lo subió); no se copian.

**Nombres entre el video y el repo.** En el video 2020, `Operations3` era la versión con `Try` y `for`. En el repo esa versión pasó a llamarse `Operations4`, y `Operations3` es la versión con `Try` sin `for`, agregada en 2023.

**Scala 2 en las capturas.** El código del video (parte 4) está en Scala 2, pero en estos archivos se escribe igual en Scala 3.3.1: no hay diferencias que declarar.

**`script_clase10.md`.** La raíz del repo trae el script de esta clase. Es el mismo texto que la página publicada de la cátedra.

## Bugs del repo arreglados

Todos se verificaron **ejecutando el código original** de la cátedra con Scala 3.3.1 (compila sin advertencias) antes de tocarlo. Con el código original, la batería del microprocesador da **5 ✓ y 6 ✗**.

| # | Dónde | Qué pasaba con el código original | Arreglo (cambio mínimo) |
|---|---|---|---|
| A | `Micro` | El valor por defecto de `mem` es `List.fill(Micro.REGISTER_SIZE)(0)` (1024 posiciones), pero el `require` exige `MEM_SIZE` (128): `Micro(0, 0)` lanza `IllegalArgumentException: requirement failed`. Es el bug 7 de clase09, que sigue en este proyecto | `List.fill(Micro.MEM_SIZE)(0)` |
| B | `Operations1` y `Operations2` · `Result.apply` | Recibe el micro por nombre (`micro: => Micro`) y en el `catch` lo vuelve a evaluar para armar el `Failure`: la excepción se lanza **de nuevo** y escapa de `run`. `run(List(Add, Mul), Micro(1000, 1000, …))` termina con `IllegalArgumentException: requirement failed` en vez de devolver `Failure`. Es el bug 9 de clase09 | `Result(previousMicro)(micro)`: el `Failure` guarda el último micro válido. `Success.map` pasa a ser `Result(micro)(f(micro))` y el `foldLeft` arranca en `Success(initialMicro): Result`, igual que en clase09 |
| C | `Operations2` y `Operations4` · `If` dentro del `for` | El `for` calcula `run(subInstructions, micro)` **siempre**, y recién en el `yield` mira si `a` es 0. Si el subprograma tiene un `Halt` o falla, eso corta todo el programa aunque el `IF` no debía ejecutarse. Con `a = 5`, `IF[HLT], LOD[1]` devolvía `Halted` (`Operations2`) o `Failure(ExecutionHaltException)` (`Operations4`) en vez de seguir; y `IF[LOD[500]]` devolvía `Failure` (`Operations4`) o lanzaba `IndexOutOfBoundsException: 500` (`Operations2`, sumado al bug B). Las versiones con `flatMap` (`Operations1` y `Operations3`) deciden antes de llamar a `run` y no tienen el problema | La segunda línea del `for` decide antes: `nextMicro <- if (micro.a == 0) run(subInstructions, micro) else Success(micro)` en `Operations2`, `… else Try(micro)` en `Operations4`. La línea del `yield` queda como en el repo; con el arreglo, sus dos ramas dan lo mismo |

**Los bugs A, B y C también están en el código del video:** A en la parte 4, slide 4; B en las slides 5 a 9 (`Result.apply` en la 5 y la 6, `Result(f(micro))` en la 7, `foldLeft(Result(initialMicro))` en la 8 y la 9); C en las slides 10 a 12.

## Erratas de las diapositivas

Corregidas en el código reconstruido. Ninguna cambia lo que la diapositiva quiere mostrar.

| Dónde | Dice | Va |
|---|---|---|
| Parte 1, slide 1, y parte 3, slides 9 a 12 | `código(): Boolean` en `Curso` | `codigo: String` |
| Parte 1, slide 8 | `elem :: init :+ last`. No compila: `::` (asociativo a derecha) y `:+` (asociativo a izquierda) tienen la misma precedencia y no se pueden mezclar sin paréntesis. Error de Scala 3.3.1: `:: (which is right-associative) and :+ (which is left-associative) have same precedence and may not be mixed` | `(elem :: init) :+ last` |
| Parte 1, slide 8 | `def head[T](): T` (con un parámetro de tipo que no corresponde, dentro de una lista que ya es `List'[T]`), `def tail(): List'[T]` y `def ::(elem: T)` | `def head: T`, `def tail: ListaSnoc[T]` y `def ::[U >: T](elem: U)`. Sin paréntesis vacíos, como `head` y `tail` en las listas de Scala; el `[U >: T]` lo exige la covarianza de `ListaSnoc[+T]` |
| Parte 2, slides 26 a 29, y parte 3, slides 1 y 2 | `flatMap[R](f: T => List[R]): List[R]` en `Monad[T]` | `flatMap[R](f: T => Caja[R]): Caja[R]` |
| Parte 2, slide 29 | `filter(f: T => bool)` | `filter(f: T => Boolean)` |
| Parte 3, slides 13 a 18 | En `Try[T]`, `map`, `flatMap` y `filter` devuelven `Option` | Devuelven `Try` (el código usa el `Try` de Scala, no lo redefine) |
| Parte 1, slide 5; pizarrón, fotos 5 y 10 | El constructor *snoc* tipado con `init: List[T]` (`(:+):(init: List[T], last: T) => List'[T]`; `Snoc : List[T] → T → List[T]`) | `Snoc(init: ListaSnoc[T], last: T)`: lo que va antes del último es otra lista *snoc* |
| Parte 3, slides 10 a 12 | Strings con comillas tipográficas (`“Se mandó ”`) | Comillas rectas (`"Se mandó "`), las únicas que Scala acepta |

## Lo que se mantiene como en la cátedra

- **`package object Operations1` a `4`**: válido en 3.3.1 y compila sin advertencias. Scala 3 prefiere un `object` común o definiciones sueltas en el archivo; el uso es el mismo (`Operations1.run(…)`). Igual que en clase09.
- **Cada `Operations` repite su `Result` o su `ExecutionHaltException`.** `Operations1.Success` y `Operations2.Success` son tipos distintos, y lo mismo las dos excepciones. Se mantiene: cada versión se lee sola.
- **El `HALT` en las versiones con `Try`** se representa lanzando `ExecutionHaltException(micro)` adentro de un `Try`: queda como `Failure`, con el micro del momento guardado en la excepción.
- **Rango de los registros:** `-1024 < valor < 1024` (estricto), como en clase09.

## Verificación

**Compilación**, con el compilador real de Scala 3.3.1 (`scalac -encoding UTF-8 -deprecation -feature -Werror`): los 19 archivos de `src/main` compilan con 0 errores y 0 advertencias. Los tres archivos de tests también compilan con `-Werror`.

**Tests:** los 38 pasan. ScalaTest no se pudo descargar en el entorno de verificación, así que los archivos de tests se compilaron y se ejecutaron contra un reemplazo mínimo con la misma interfaz que usan (`AnyFunSuite` con `test` e `intercept`; `Matchers` con `shouldBe`), igual que en clase09. **Limitación declarada:** falta correrlos con ScalaTest real; `sbt test` cierra esa diferencia.

**Dos comportamientos de Scala 3.3.1 verificados al armar esta referencia:**

- **Un `if` dentro de un `for` necesita `withFilter`.** Con una caja que tiene `map`, `flatMap` y `filter`, pero no `withFilter`, `for { x <- caja if x > 2 } yield x` no compila: `value withFilter is not a member of …`. Por eso `Caja` lo define (delegando en `filter`).
- **Las cajas de `Future` esperan dentro de `blocking { … }`.** Sin eso, con un solo procesador disponible, el ejecutor por defecto de Scala corre una caja por vez y las dos versiones del `for` se comportan igual. Con `blocking`, los tests de futuros pasan también limitando la JVM a un procesador (`-XX:ActiveProcessorCount=1`).
- **`filter` sobre un `Try` no deja la caja vacía:** `Try(10).filter(_ > 50)` da `Failure(java.util.NoSuchElementException: Predicate does not hold for 10)`.

### Los 38 tests (AGREGADOS)

**`MonadasTest` (microprocesador, las cuatro versiones)** — 11 tests

- un micro sin memoria explícita arranca con 128 posiciones en 0
- las cuatro versiones ejecutan el programa del ejemplo y dejan el micro original igual
- IF ejecuta sus instrucciones solo si A es 0
- un IF dentro de otro: el de adentro no se ejecuta y lo que sigue en el de afuera sí
- HALT detiene la ejecución: Halted con Result, Failure con Try, y el micro del momento del HALT
- un HALT dentro de un IF que se ejecuta detiene todo el programa
- un HALT dentro de un IF que no se ejecuta no detiene nada
- una instrucción que fallaría dentro de un IF que no se ejecuta no hace fallar nada
- un registro fuera de rango: Failure con el último micro válido (Result) o con el error (Try)
- una dirección de memoria inexistente: Failure, sin excepción que se escape
- la versión con for da lo mismo que la versión con map y flatMap, en Result y en Try

**`NivelesTest`** — 10 tests

- los cinco niveles responden lo mismo: legajos de los regulares inscriptos a electivas
- sin materias, todos los niveles devuelven la lista vacía
- append concatena en los tres niveles que lo definen
- ListaSnoc: se construye agregando al final y responde head, tail y ::
- ListaSnoc: head, last y tail de una lista vacía fallan
- las funciones del nivel 2 funcionan igual sobre la otra representación
- el fold a mano es un foldLeft
- lifteo: map y filter convierten funciones de un elemento en funciones de listas
- monoides: combinar todos con el neutro como semilla
- monoides: el neutro no altera y la operación es asociativa

**`CajasTest.scala` (`CajaTest`, `MailTest`, `InscripcionTest`, `FuturosTest`)** — 17 tests

- map y filter salen de flatMap, unit y zero
- leyes: identidad izquierda, identidad derecha y asociatividad
- leyes de zero y plus: neutro, asociatividad y zero izquierdo
- cualquier caja con map, flatMap y withFilter se puede usar en un for
- script: encadenar filter, map y flatMap nunca obliga a preguntar si la caja tiene contenido
- script: la cadena de flatMap, filter y map, y su for, dan lo mismo
- la lista cumple el mismo contrato: unit = List(x), bind = flatMap, zero = Nil, plus = ++
- con null: cada caso que falta termina en el warning
- con Option: sin titular o sin mail, la caja vacía llega sola hasta el fold
- si mandar también puede no tener resultado, es flatMap y el fallo se maneja igual
- Option: construcción desde null, getOrElse y fold
- con excepciones: anota, pide autorización si hace falta, y explota si no hay cupo
- con Try: el mismo comportamiento, pero el error vuelve como Failure
- Try: getOrElse, fold, toOption y filter
- for con las cajas creadas adentro: la segunda empieza cuando termina la primera
- for con las cajas creadas antes: las dos corren a la vez
- una lista de futuros pasa a ser un futuro de lista

## Cómo usarlo

Abrir la carpeta `tadp-clase10-comportamiento-vs-estructura-y-monadas` en IntelliJ como proyecto sbt, o `sbt test` desde la raíz. No hay aplicaciones (`App`): cada parte se usa desde los tests o desde una consola de Scala (o un worksheet).

## Árbol del proyecto

```
tadp-clase10-comportamiento-vs-estructura-y-monadas/
├── build.sbt
├── .gitignore
├── project/
│   └── build.properties
└── src/
    ├── main/
    │   └── scala/
    │       └── tadp/
    │           ├── cajas/
    │           │   ├── futuros/
    │           │   │   └── SecuencialVsParalelo.scala  RECONSTRUIDO: for secuencial y paralelo
    │           │   ├── inscripcion/
    │           │   │   └── Inscripcion.scala         RECONSTRUIDO: excepciones contra Try
    │           │   ├── mail/
    │           │   │   └── MailDelTitular.scala      RECONSTRUIDO: null contra Option
    │           │   └── monada/
    │           │       └── Caja.scala                RECONSTRUIDO: unit, bind, zero, plus
    │           ├── microprocesador/
    │           │   └── monadas/
    │           │       ├── Instructions.scala        sealed trait + case objects + case classes
    │           │       ├── Micro.scala               case class Micro (bug A arreglado)
    │           │       ├── Operations1.scala         Result con map y flatMap
    │           │       ├── Operations2.scala         Result con for
    │           │       ├── Operations3.scala         Try[Micro] con map y flatMap
    │           │       └── Operations4.scala         Try[Micro] con for
    │           └── niveles/
    │               ├── Dominio.scala                 RECONSTRUIDO: Materia, Curso, Alumno
    │               ├── Lifteo.scala                  RECONSTRUIDO: lifteo
    │               ├── ListaSnoc.scala               RECONSTRUIDO: lista que crece por el final
    │               ├── Monoide.scala                 RECONSTRUIDO: monoides
    │               ├── Nivel1PatternMatching.scala   nivel 1: pattern matching
    │               ├── Nivel2TipoAlgebraico.scala    nivel 2: isEmpty, head, tail
    │               ├── Nivel3Fold.scala              nivel 3: foldRight (+ fold a mano)
    │               ├── Nivel4OrdenSuperior.scala     nivel 4: filter, map, flatMap
    │               └── Nivel5For.scala               nivel 5: for
    └── test/
        └── scala/
            └── tadp/
                ├── cajas/
                │   └── CajasTest.scala               AGREGADO
                ├── microprocesador/
                │   └── MonadasTest.scala             AGREGADO
                └── niveles/
                    └── NivelesTest.scala             AGREGADO
```

## Archivos

### `build.sbt`

Configuración del proyecto, con las versiones del repo del TP.

```scala
ThisBuild / scalaVersion     := "3.3.1"
ThisBuild / version          := "0.1.0"
ThisBuild / organization     := "ar.edu.utn.frba.tadp"

lazy val root = (project in file("."))
  .settings(
    name := "tadp-clase10-comportamiento-vs-estructura-y-monadas",
    libraryDependencies += "org.scalatest" %% "scalatest" % "3.2.19" % Test
  )
```

### `project/build.properties`

Versión de sbt del repo del TP.

```properties
sbt.version=1.9.0
```

### `.gitignore`

Mínimo para sbt e IntelliJ.

```
target/
project/target/
project/project/
.bsp/
.idea/
*.iml
```

### `src/main/scala/tadp/microprocesador/monadas/Instructions.scala`

**Las instrucciones como datos:** `sealed trait` con `case object` y `case class`. Idénticas a las de clase09.

```scala
package tadp.microprocesador.monadas

sealed trait Instruction

case object Add extends Instruction
case object Mul extends Instruction
case object Swap extends Instruction
case class Load(address: Int) extends Instruction
case class Store(address: Int) extends Instruction
case class If(subInstructions: List[Instruction]) extends Instruction
case object Halt extends Instruction
```

### `src/main/scala/tadp/microprocesador/monadas/Micro.scala`

**El micro inmutable:** una `case class` que valida sus invariantes al construirse y se "modifica" con `copy`. Con el bug A arreglado.

```scala
package tadp.microprocesador.monadas

object Micro {
  val MEM_SIZE = 128
  val REGISTER_SIZE = 1024
}

case class Micro(a: Int, b: Int, mem: List[Int] = List.fill(Micro.MEM_SIZE)(0)) {
  require(a < Micro.REGISTER_SIZE && a > -Micro.REGISTER_SIZE)
  require(b < Micro.REGISTER_SIZE && b > -Micro.REGISTER_SIZE)
  require(mem.size == Micro.MEM_SIZE)
}
```

### `src/main/scala/tadp/microprocesador/monadas/Operations1.scala`

**`Result` con orden superior.** El resultado de clase09 (`Success`, `Halted`, `Failure`) suma `map` y `flatMap`: `Success` aplica la función; `Halted` y `Failure` se devuelven a sí mismos. Cada instrucción es un `map` o un `flatMap` sobre el resultado anterior. Con el bug B arreglado.

```scala
package tadp.microprocesador.monadas

package object Operations1 {

  type Program = List[Instruction]

  // ---------------------------------------------------------------------------------------------------------------------------------
  // RESULTS
  // ---------------------------------------------------------------------------------------------------------------------------------

  object Result {
    def apply(previousMicro: Micro)(micro: => Micro): Result = try {
      Success(micro)
    } catch {
      case error: Exception => Failure(previousMicro, error)
    }
  }
  sealed trait Result {
    def micro: Micro
    def map(f: Micro => Micro): Result
    def flatMap(f: Micro => Result): Result
  }

  case class Success(micro: Micro) extends Result {
    def map(f: Micro => Micro) = Result(micro)(f(micro))
    def flatMap(f: Micro => Result) = f(micro)
  }

  case class Halted(micro: Micro) extends Result {
    def map(f: Micro => Micro) = this
    def flatMap(f: Micro => Result) = this
  }

  case class Failure(micro: Micro, error: Exception) extends Result {
    def map(f: Micro => Micro) = this
    def flatMap(f: Micro => Result) = this
  }

  // ---------------------------------------------------------------------------------------------------------------------------------
  // RUN: HIGHER ORDER
  // ---------------------------------------------------------------------------------------------------------------------------------

  def run(program: Program, initialMicro: Micro): Result = {
    program.foldLeft(Success(initialMicro): Result) { (previousResult, instruction) =>
      instruction match {
        case Add =>
          previousResult.map(micro => micro.copy(a = micro.a + micro.b))
        case Mul =>
          previousResult.map(micro => micro.copy(a = micro.a * micro.b))
        case Swap =>
          previousResult.map(micro => micro.copy(a = micro.b, b = micro.a))
        case Load(address) =>
          previousResult.map(micro => micro.copy(a = micro.mem(address)))
        case Store(address) =>
          previousResult.map(micro => micro.copy(mem = micro.mem.updated(address, micro.a)))
        case If(subInstructions) =>
          previousResult.flatMap(micro =>
            if (micro.a == 0) run(subInstructions, micro)
            else previousResult
          )
        case Halt =>
          previousResult.flatMap(micro => Halted(micro))
      }
    }
  }

}
```

### `src/main/scala/tadp/microprocesador/monadas/Operations2.scala`

**El mismo `Result`, usado con `for`.** Cada `case` saca el micro de la caja con `<-` y arma el siguiente en el `yield`. Con los bugs B y C arreglados.

```scala
package tadp.microprocesador.monadas

package object Operations2 {

  type Program = List[Instruction]

  // ---------------------------------------------------------------------------------------------------------------------------------
  // RESULTS
  // ---------------------------------------------------------------------------------------------------------------------------------

  object Result {
    def apply(previousMicro: Micro)(micro: => Micro): Result = try {
      Success(micro)
    } catch {
      case error: Exception => Failure(previousMicro, error)
    }
  }
  sealed trait Result {
    def micro: Micro
    def map(f: Micro => Micro): Result
    def flatMap(f: Micro => Result): Result
  }

  case class Success(micro: Micro) extends Result {
    def map(f: Micro => Micro) = Result(micro)(f(micro))
    def flatMap(f: Micro => Result) = f(micro)
  }

  case class Halted(micro: Micro) extends Result {
    def map(f: Micro => Micro) = this
    def flatMap(f: Micro => Result) = this
  }

  case class Failure(micro: Micro, error: Exception) extends Result {
    def map(f: Micro => Micro) = this
    def flatMap(f: Micro => Result) = this
  }

  // ---------------------------------------------------------------------------------------------------------------------------------
  // RUN: FOR COMPREHENSION
  // ---------------------------------------------------------------------------------------------------------------------------------

  def run(program: Program, initialMicro: Micro): Result = {
    program.foldLeft(Success(initialMicro): Result) { (previousResult, instruction) =>
      instruction match {
        case Add =>
          for (micro <- previousResult)
          yield micro.copy(a = micro.a + micro.b)

        case Mul =>
          for (micro <- previousResult)
          yield micro.copy(a = micro.a * micro.b)

        case Swap =>
          for (micro <- previousResult)
          yield micro.copy(a = micro.b, b = micro.a)

        case Load(address) =>
          for (micro <- previousResult)
          yield micro.copy(a = micro.mem(address))

        case Store(address) =>
          for (micro <- previousResult)
          yield micro.copy(mem = micro.mem.updated(address, micro.a))

        case If(subInstructions) =>
          for {
            micro <- previousResult
            nextMicro <- if (micro.a == 0) run(subInstructions, micro) else Success(micro)
          } yield if (micro.a == 0) nextMicro else micro

        case Halt =>
          for {
            micro <- previousResult
            haltedMicro <- Halted(micro)
          } yield haltedMicro
      }
    }
  }
}
```

### `src/main/scala/tadp/microprocesador/monadas/Operations3.scala`

**`Try[Micro]` en lugar de `Result`.** El `run` es el de `Operations1` con `Try` como caja: el `HALT` se representa lanzando `ExecutionHaltException(micro)` dentro de un `Try`.

```scala
package tadp.microprocesador.monadas

import scala.util.Try

package object Operations3 {

  type Program = List[Instruction]
  class ExecutionHaltException(val micro: Micro) extends RuntimeException

  // ---------------------------------------------------------------------------------------------------------------------------------
  // RUN: TRY MONAD
  // ---------------------------------------------------------------------------------------------------------------------------------

  def run(program: Program, initialMicro: Micro): Try[Micro] = {
    program.foldLeft(Try(initialMicro)) { (previousResult, instruction) =>
      instruction match {
        case Add =>
          previousResult.map(micro => micro.copy(a = micro.a + micro.b))

        case Mul =>
          previousResult.map(micro => micro.copy(a = micro.a * micro.b))

        case Swap =>
          previousResult.map(micro => micro.copy(a = micro.b, b = micro.a))

        case Load(address) =>
          previousResult.map(micro => micro.copy(a = micro.mem(address)))

        case Store(address) =>
          previousResult.map(micro => micro.copy(mem = micro.mem.updated(address, micro.a)))

        case If(subInstructions) =>
          previousResult.flatMap(micro =>
            if (micro.a == 0) run(subInstructions, micro)
            else previousResult
          )

        case Halt =>
          previousResult.flatMap(micro => Try(throw new ExecutionHaltException(micro)))
      }
    }
  }

}
```

### `src/main/scala/tadp/microprocesador/monadas/Operations4.scala`

**`Try[Micro]` con `for`.** El `run` es el de `Operations2` con `Try` como caja. Con el bug C arreglado.

```scala
package tadp.microprocesador.monadas

import scala.util.Try

package object Operations4 {

  type Program = List[Instruction]
  class ExecutionHaltException(val micro: Micro) extends RuntimeException

  // ---------------------------------------------------------------------------------------------------------------------------------
  // RUN: TRY MONAD
  // ---------------------------------------------------------------------------------------------------------------------------------

  def run(program: Program, initialMicro: Micro): Try[Micro] = {
    program.foldLeft(Try(initialMicro)) { (previousResult, instruction) =>
      instruction match {
        case Add =>
          for (micro <- previousResult)
          yield micro.copy(a = micro.a + micro.b)

        case Mul =>
          for (micro <- previousResult)
          yield micro.copy(a = micro.a * micro.b)

        case Swap =>
          for (micro <- previousResult)
          yield micro.copy(a = micro.b, b = micro.a)

        case Load(address) =>
          for (micro <- previousResult)
          yield micro.copy(a = micro.mem(address))

        case Store(address) =>
          for (micro <- previousResult)
          yield micro.copy(mem = micro.mem.updated(address, micro.a))

        case If(subInstructions) =>
          for {
            micro <- previousResult
            nextMicro <- if (micro.a == 0) run(subInstructions, micro) else Try(micro)
          } yield if (micro.a == 0) nextMicro else micro

        case Halt =>
          for {
            micro <- previousResult
            haltedMicro <- Try(throw new ExecutionHaltException(micro))
          } yield haltedMicro
      }
    }
  }

}
```

### `src/main/scala/tadp/niveles/Dominio.scala`

**RECONSTRUIDO** del diagrama de la diapositiva: materias con cursos, cursos con alumnos inscriptos.

```scala
package tadp.niveles

case class Alumno(legajo: String, regular: Boolean)
case class Curso(codigo: String, inscriptos: List[Alumno])
case class Materia(electiva: Boolean, cursos: List[Curso])
```

### `src/main/scala/tadp/niveles/Nivel1PatternMatching.scala`

**Nivel 1: acoplado a la forma.** Cada función recorre la lista con pattern matching sobre `Nil` y `cabeza::cola`. Verbatim de la diapositiva; `legajosDeRegularesEnElectivas` envuelve la expresión final.

```scala
package tadp.niveles

object Nivel1PatternMatching {

  def append[T](izq:List[T], der:List[T]):List[T] = izq match {
    case Nil => der
    case cabeza::cola => cabeza::append(cola, der)
  }

  def electivas(materias:List[Materia]):List[Materia] = materias match {
    case Nil => Nil
    case materia::otras if materia.electiva => materia::electivas(otras)
    case _::otras => electivas(otras)
  }

  def cursos(materias:List[Materia]):List[Curso] = materias match {
    case Nil => Nil
    case materia::otras => append(materia.cursos, cursos(otras))
  }

  def inscriptos(cursos:List[Curso]):List[Alumno] = cursos match {
    case Nil => Nil
    case curso::otros => append(curso.inscriptos, inscriptos(otros))
  }

  def regulares(alumnos:List[Alumno]):List[Alumno] = alumnos match {
    case Nil => Nil
    case alumno::otros if alumno.regular => alumno::regulares(otros)
    case _::otrosAlumnos => regulares(otrosAlumnos)
  }

  def legajos(alumnos:List[Alumno]):List[String] = alumnos match {
    case Nil => Nil
    case alumno::otrosAlumnos => alumno.legajo::legajos(otrosAlumnos)
  }

  def legajosDeRegularesEnElectivas(todasLasMaterias: List[Materia]): List[String] =
    legajos(regulares(inscriptos(cursos(electivas(todasLasMaterias)))))
}
```

### `src/main/scala/tadp/niveles/Nivel2TipoAlgebraico.scala`

**Nivel 2: acoplado a las operaciones de la lista.** El mismo código con `isEmpty`, `head`, `tail`, `List.empty` y `::` en lugar de patrones. Verbatim de la diapositiva.

```scala
package tadp.niveles

object Nivel2TipoAlgebraico {

  def append[T](izq:List[T], der:List[T]):List[T] =
    if(izq.isEmpty) der
    else izq.head::append(izq.tail, der)

  def electivas(materias:List[Materia]):List[Materia] =
    if(materias.isEmpty) List.empty
    else if (materias.head.electiva)
      materias.head::electivas(materias.tail)
    else electivas(materias.tail)

  def cursos(materias:List[Materia]):List[Curso] =
    if(materias.isEmpty) List.empty
    else append(materias.head.cursos, cursos(materias.tail))

  def inscriptos(cursos:List[Curso]):List[Alumno] =
    if(cursos.isEmpty) List.empty
    else append(cursos.head.inscriptos,inscriptos(cursos.tail))

  def regulares(alumnos:List[Alumno]):List[Alumno] =
    if(alumnos.isEmpty) List.empty
    else if(alumnos.head.regular)
      alumnos.head::regulares(alumnos.tail)
    else regulares(alumnos.tail)

  def legajos(alumnos:List[Alumno]):List[String] =
    if(alumnos.isEmpty) List.empty
    else alumnos.head.legajo::legajos(alumnos.tail)

  def legajosDeRegularesEnElectivas(todasLasMaterias: List[Materia]): List[String] =
    legajos(regulares(inscriptos(cursos(electivas(todasLasMaterias)))))
}
```

### `src/main/scala/tadp/niveles/ListaSnoc.scala`

**RECONSTRUIDO: otra representación de la lista.** Se construye agregando al final (`:+`) y responde `head`, `tail` y `::` calculándolos sobre esa forma. Es covariante (`+T`) para que una sola lista vacía sirva para cualquier tipo; por eso `:+` y `::` llevan `[U >: T]`. `head` y `tail` de la lista vacía fallan como los de `List`. `Nivel2SobreSnoc` (**agregado para estudio**) son `regulares` y `legajos` del nivel 2 con el mismo cuerpo sobre esta lista.

```scala
package tadp.niveles

// Reconstruido: diapositivas pt1 s.5 y s.8; pizarrón fotos 5, 10 y 11.
sealed trait ListaSnoc[+T] {
  def isEmpty: Boolean
  def last: T
  def init: ListaSnoc[T]
  def :+[U >: T](elem: U): ListaSnoc[U] = Snoc(this, elem)

  def head: T = if(init.isEmpty) last else init.head
  def tail: ListaSnoc[T] = if(init.isEmpty) init else init.tail :+ last
  def ::[U >: T](elem: U): ListaSnoc[U] =
    if(isEmpty) this :+ elem else (elem :: init) :+ last
}

case object VaciaSnoc extends ListaSnoc[Nothing] {
  def isEmpty = true
  override def head = throw new NoSuchElementException("head de una ListaSnoc vacía")
  override def tail = throw new UnsupportedOperationException("tail de una ListaSnoc vacía")
  def last = throw new NoSuchElementException("last de una ListaSnoc vacía")
  def init = throw new UnsupportedOperationException("init de una ListaSnoc vacía")
}

case class Snoc[+T](init: ListaSnoc[T], last: T) extends ListaSnoc[T] {
  def isEmpty = false
}

object ListaSnoc {
  def empty[T]: ListaSnoc[T] = VaciaSnoc
}

// Agregado para estudio: regulares y legajos del nivel 2 sobre ListaSnoc.
object Nivel2SobreSnoc {

  def regulares(alumnos: ListaSnoc[Alumno]): ListaSnoc[Alumno] =
    if(alumnos.isEmpty) ListaSnoc.empty
    else if(alumnos.head.regular)
      alumnos.head::regulares(alumnos.tail)
    else regulares(alumnos.tail)

  def legajos(alumnos: ListaSnoc[Alumno]): ListaSnoc[String] =
    if(alumnos.isEmpty) ListaSnoc.empty
    else alumnos.head.legajo::legajos(alumnos.tail)
}
```

### `src/main/scala/tadp/niveles/Nivel3Fold.scala`

**Nivel 3: acoplado a algo que se puede recorrer.** Cada función es un `foldRight` con una semilla y una función de combinación. Verbatim de la diapositiva. Al final, **reconstruido del pizarrón**, el `fold` escrito a mano con pattern matching.

```scala
package tadp.niveles

object Nivel3Fold {

  def append[T](izq:List[T], der:List[T]):List[T] =
    izq.foldRight(der)((elem, lista) => elem :: lista)

  def electivas(materias:List[Materia]):List[Materia] =
    materias.foldRight(List.empty[Materia])((materia, electivas) =>
      if(materia.electiva) materia::electivas else electivas
    )

  def cursos(materias:List[Materia]):List[Curso] =
    materias.foldRight(List.empty[Curso])((materia, cursos) =>
      append(materia.cursos, cursos)
    )

  def inscriptos(cursos:List[Curso]):List[Alumno] =
    cursos.foldRight(List.empty[Alumno])((curso, inscriptos) =>
      append(curso.inscriptos, inscriptos)
    )

  def regulares(alumnos:List[Alumno]):List[Alumno] =
    alumnos.foldRight(List.empty[Alumno])((alumno, regulares) =>
      if(alumno.regular) alumno::regulares else regulares
    )

  def legajos(alumnos:List[Alumno]):List[String] =
    alumnos.foldRight(List.empty[String])((alumno, legajos) =>
      alumno.legajo::legajos
    )

  def legajosDeRegularesEnElectivas(todasLasMaterias: List[Materia]): List[String] =
    legajos(regulares(inscriptos(cursos(electivas(todasLasMaterias)))))

  // Reconstruido del pizarrón (fotos 6 y 8):
  //   fold f e []     = e
  //   fold f e (x:xs) = fold f (f e x) xs
  def fold[T, R](f: (R, T) => R)(e: R)(lista: List[T]): R = lista match {
    case Nil => e
    case x :: xs => fold(f)(f(e, x))(xs)
  }
}
```

### `src/main/scala/tadp/niveles/Nivel4OrdenSuperior.scala`

**Nivel 4: `filter`, `map` y `flatMap`.** Cada función es una sola operación de orden superior. Al final, la consulta entera encadenada en una expresión. Verbatim de las diapositivas.

```scala
package tadp.niveles

object Nivel4OrdenSuperior {

  def electivas(materias:List[Materia]):List[Materia] =
    materias.filter(materia => materia.electiva)

  def cursos(materias:List[Materia]):List[Curso] =
    materias.flatMap(materia => materia.cursos)

  def inscriptos(cursos:List[Curso]):List[Alumno] =
    cursos.flatMap(curso => curso.inscriptos)

  def regulares(alumnos:List[Alumno]):List[Alumno] =
    alumnos.filter(alumno => alumno.regular)

  def legajos(alumnos:List[Alumno]):List[String] =
     alumnos.map(alumno => alumno.legajo)

  def legajosDeRegularesEnElectivas(todasLasMaterias: List[Materia]): List[String] =
    legajos(regulares(inscriptos(cursos(electivas(todasLasMaterias)))))

  // Diapositivas pt1 s.22-23
  def encadenado(todasLasMaterias: List[Materia]): List[String] =
    todasLasMaterias
        .filter(materia => materia.electiva)
        .flatMap(materia => materia.cursos
            .flatMap(curso => curso.inscriptos
                .filter(alumno => alumno.regular)
                .map(alumno => alumno.legajo)
            )
        )
}
```

### `src/main/scala/tadp/niveles/Nivel5For.scala`

**Nivel 5: `for`.** La misma consulta con `<-`, `if` y `yield`. Verbatim de la diapositiva. `traducido` (**agregado para estudio**) es lo que el compilador escribe a partir de ese `for`.

```scala
package tadp.niveles

object Nivel5For {

  def legajosDeRegularesEnElectivas(todasLasMaterias: List[Materia]): List[String] =
    for {
      materia <- todasLasMaterias if materia.electiva
      curso   <- materia.cursos
      alumno  <- curso.inscriptos if alumno.regular
    } yield alumno.legajo

  // Agregado para estudio
  def traducido(todasLasMaterias: List[Materia]): List[String] =
    todasLasMaterias
      .withFilter(materia => materia.electiva)
      .flatMap(materia => materia.cursos
        .flatMap(curso => curso.inscriptos
          .withFilter(alumno => alumno.regular)
          .map(alumno => alumno.legajo)
        )
      )
}
```

### `src/main/scala/tadp/niveles/Lifteo.scala`

**RECONSTRUIDO: lifteo.** `map` convierte una función de un elemento en una función de listas, y `filter` convierte un criterio en una función de filtrado.

```scala
package tadp.niveles

// Reconstruido: presencial (transcripción pt1) y pizarrón, fotos 14 y 16.
object Lifteo {

  def liftear[A, B](f: A => B): List[A] => List[B] =
    lista => lista.map(f)

  def filtrador[A](criterio: A => Boolean): List[A] => List[A] =
    lista => lista.filter(criterio)

  val esPar: Int => Boolean = n => n % 2 == 0
  val filtrarPares: List[Int] => List[Int] = filtrador(esPar)   // en Haskell: (filter even)
}
```

### `src/main/scala/tadp/niveles/Monoide.scala`

**RECONSTRUIDO: monoides.** Un `trait` con `neutro` y `combinar`, y una instancia por cada fila del pizarrón. `combinarTodos` usa el neutro como semilla de un `foldLeft`.

```scala
package tadp.niveles

// Reconstruido: pizarrón, foto 7.
trait Monoide[A] {
  def neutro: A
  def combinar(x: A, y: A): A
}

object Monoide {
  object SumaInt extends Monoide[Int] {
    def neutro = 0
    def combinar(x: Int, y: Int) = x + y
  }

  object ProductoInt extends Monoide[Int] {
    def neutro = 1
    def combinar(x: Int, y: Int) = x * y
  }

  object ConcatenacionString extends Monoide[String] {
    def neutro = ""
    def combinar(x: String, y: String) = x ++ y
  }

  def composicion[A]: Monoide[A => A] = new Monoide[A => A] {
    def neutro = (a: A) => a
    def combinar(f: A => A, g: A => A) = f compose g
  }

  object Conjuncion extends Monoide[Boolean] {
    def neutro = true
    def combinar(x: Boolean, y: Boolean) = x && y
  }

  object Disyuncion extends Monoide[Boolean] {
    def neutro = false
    def combinar(x: Boolean, y: Boolean) = x || y
  }

  def combinarTodos[A](valores: List[A])(monoide: Monoide[A]): A =
    valores.foldLeft(monoide.neutro)(monoide.combinar)
}
```

### `src/main/scala/tadp/cajas/monada/Caja.scala`

**RECONSTRUIDO: el contrato de mónada sobre una caja propia.** `unit` y `flatMap` (bind), `zero` y `++` (plus); `map` y `filter` se escriben a partir de ellas, con el cuerpo de la diapositiva. `withFilter` permite usarla con `if` dentro de un `for`.

```scala
package tadp.cajas.monada

// Reconstruido: diapositivas pt2 s.25-29; pizarrón, fotos 19 a 21.
import Caja.{unit, zero}

sealed trait Caja[+T] {
  def flatMap[R](f: T => Caja[R]): Caja[R]
  def ++[U >: T](otra: Caja[U]): Caja[U]
  def fold[R](ifEmpty: => R)(f: T => R): R

  def map[R](f: T => R) = this.flatMap(v => unit(f(v)))

  def filter(f: T => Boolean) = this.flatMap(v =>
    if (f(v)) unit(v) else zero
  )

  def withFilter(f: T => Boolean): Caja[T] = filter(f)
}

case class Llena[+T](valor: T) extends Caja[T] {
  def flatMap[R](f: T => Caja[R]): Caja[R] = f(valor)
  def ++[U >: T](otra: Caja[U]): Caja[U] = this
  def fold[R](ifEmpty: => R)(f: T => R): R = f(valor)
}

case object Vacia extends Caja[Nothing] {
  def flatMap[R](f: Nothing => Caja[R]): Caja[R] = this
  def ++[U](otra: Caja[U]): Caja[U] = otra
  def fold[R](ifEmpty: => R)(f: Nothing => R): R = ifEmpty
}

object Caja {
  def unit[T](valor: T): Caja[T] = Llena(valor)
  def zero[T]: Caja[T] = Vacia
}
```

### `src/main/scala/tadp/cajas/mail/MailDelTitular.scala`

**RECONSTRUIDO: mandar un mail al titular de un curso.** Tres versiones: con `null` (diapositiva 10), con `Option` (diapositiva 11) y con `Option` cuando mandar también puede no tener resultado (pizarrón). Los cuerpos de `enviarAlTitular` de las dos primeras son verbatim.

```scala
package tadp.cajas.mail

import scala.collection.mutable.ListBuffer

class Log {
  val lineas: ListBuffer[String] = ListBuffer()
  def info(mensaje: String): Unit = lineas += s"INFO: $mensaje"
  def warning(mensaje: String): Unit = lineas += s"WARNING: $mensaje"
}

// Reconstruido: "Dada un curso, enviar un mail al titular y loguear el resultado" (diapositivas pt3 s.9-12; pizarrón).

// -------------------------------------------------------------------------------------------------
// CON NULL (diapositiva pt3 s.10)
// -------------------------------------------------------------------------------------------------

object ConNull {
  class Docente(val legajo: String, val mail: String)       // mail puede ser null
  class Curso(val codigo: String, val titular: Docente)     // titular puede ser null

  def mandarMailA(mail: String): String =                   // devuelve null si no se pudo mandar
    if (mail.contains("@")) s"mail enviado a $mail" else null

  def enviarAlTitular(curso: Curso, log: Log): Unit = {
    val talVezUnDocente = curso.titular

    val talVezUnMail = if(talVezUnDocente != null) talVezUnDocente.mail
                       else null

    val talVezResultado = if(talVezUnMail != null) mandarMailA(talVezUnMail)
                          else null

    if(talVezResultado != null) log.info("Se mandó " + talVezResultado)
    else log.warning("No se pudo Mandar")
  }
}

// -------------------------------------------------------------------------------------------------
// CON OPTION (diapositiva pt3 s.11)
// -------------------------------------------------------------------------------------------------

object ConOption {
  case class Docente(legajo: String, mail: Option[String])
  case class Curso(codigo: String, titular: Option[Docente])

  def mandarMailA(mail: String): String = s"mail enviado a $mail"

  def enviarAlTitular(curso: Curso, log: Log): Unit =
    curso.titular
      .flatMap(docente => docente.mail)
      .map(mail => mandarMailA(mail))
      .fold (log.warning("No se pudo Mandar"))(resultado =>
        log.info("Se mandó " + resultado)
      )
}

// CON OPTION, mandar también devuelve una caja (pizarrón, fotos 17 y 22)
object ConOptionYMandarQuePuedeFallar {
  import ConOption.{Curso, Docente}

  def mandarMailA(mail: String): Option[String] =
    if (mail.contains("@")) Some(s"mail enviado a $mail") else None

  def enviarAlTitular(curso: Curso, log: Log): Unit =
    curso.titular
      .flatMap(docente => docente.mail)
      .flatMap(mail => mandarMailA(mail))
      .fold (log.warning("No se pudo Mandar"))(resultado =>
        log.info("Se mandó " + resultado)
      )
}
```

### `src/main/scala/tadp/cajas/inscripcion/Inscripcion.scala`

**RECONSTRUIDO: anotar un alumno a un curso.** El dominio sale del diagrama de la diapositiva; los dos `anotar`, con `try`/`catch` y con `Try`/`recover`, son verbatim.

```scala
package tadp.cajas.inscripcion

import scala.collection.mutable
import scala.util.Try

// Reconstruido: "Anotar un alumno a un curso" (diapositivas pt3 s.17-18).

case class Alumno(legajo: String)

class NoHayCupo(val curso: Curso) extends RuntimeException("no hay cupo")
class NoAutorizado(val alumno: Alumno) extends RuntimeException("no autorizado")

class Docente {
  def autorizarIngreso(alumno: Alumno, curso: Curso): Unit =
    curso.autorizados += alumno
}

class Curso(val cupo: Int, val docente: Docente, val requiereAutorizacion: Boolean) {
  val inscriptos: mutable.ListBuffer[Alumno] = mutable.ListBuffer()
  val autorizados: mutable.Set[Alumno] = mutable.Set()

  def hayCupo: Boolean = inscriptos.size < cupo

  def inscribir(alumno: Alumno): Curso = {
    if (requiereAutorizacion && !autorizados.contains(alumno)) throw new NoAutorizado(alumno)
    inscriptos += alumno
    this
  }
}

// -------------------------------------------------------------------------------------------------
// CON EXCEPCIONES (diapositiva pt3 s.17)
// -------------------------------------------------------------------------------------------------

object ConExcepciones {
  def anotar(alumno: Alumno, curso: Curso): Curso = {
    if (!curso.hayCupo) throw new NoHayCupo(curso)
    try { curso.inscribir(alumno) }
    catch { case _: NoAutorizado =>
      curso.docente.autorizarIngreso(alumno, curso)
      curso.inscribir(alumno)
    }
  }
}

// -------------------------------------------------------------------------------------------------
// CON TRY (diapositiva pt3 s.18)
// -------------------------------------------------------------------------------------------------

object ConTry {
  def anotar(alumno: Alumno, curso: Curso): Try[Curso] = Try {
    if (!curso.hayCupo) throw new NoHayCupo(curso)
    curso.inscribir(alumno)
  }.recover { case _: NoAutorizado =>
    curso.docente.autorizarIngreso(alumno, curso)
    curso.inscribir(alumno)
  }
}
```

### `src/main/scala/tadp/cajas/futuros/SecuencialVsParalelo.scala`

**RECONSTRUIDO: `for` secuencial contra paralelo.** Dos cajas que tardan y anotan cuándo empiezan y terminan. Si se crean dentro del `for`, la segunda espera a la primera; si se crean antes, corren a la vez. `todosJuntos` pasa una lista de futuros a un futuro de lista.

```scala
package tadp.cajas.futuros

import scala.collection.mutable.ListBuffer
import scala.concurrent.{Future, blocking}
import scala.concurrent.ExecutionContext.Implicits.global

// Reconstruido: pizarrón, fotos 23, 25 y 26.
class Cajas(demoraMs: Long) {
  val eventos: ListBuffer[String] = ListBuffer()

  private def anotar(evento: String): Unit = eventos.synchronized { eventos += evento }

  def estaCaja(): Future[Int] = Future {
    anotar("empieza estaCaja")
    blocking { Thread.sleep(demoraMs) }
    anotar("termina estaCaja")
    1
  }

  def otraCaja(): Future[Int] = Future {
    anotar("empieza otraCaja")
    blocking { Thread.sleep(demoraMs) }
    anotar("termina otraCaja")
    2
  }

  def sumaSecuencial(): Future[Int] =
    for {
      x <- estaCaja()
      y <- otraCaja()
    } yield x + y

  def sumaEnParalelo(): Future[Int] = {
    val cx = estaCaja()
    val cy = otraCaja()
    for {
      x <- cx
      y <- cy
    } yield x + y
  }
}

object Secuencia {
  // [F(a), F(b)] → F([a, b])
  def todosJuntos[T](futuros: List[Future[T]]): Future[List[T]] =
    Future.sequence(futuros)
}
```

### `src/test/scala/tadp/microprocesador/MonadasTest.scala`

**AGREGADO para esta referencia: el repo de la cátedra no trae tests.** La misma batería contra las cuatro versiones de `run`.

```scala
// AGREGADO para esta referencia: el repo de la cátedra no trae tests.
// La misma batería se corre contra las cuatro versiones de run:
// Operations1 (Result con map/flatMap), Operations2 (Result con for),
// Operations3 (Try con map/flatMap) y Operations4 (Try con for).
package tadp.microprocesador

import org.scalatest.funsuite.AnyFunSuite
import org.scalatest.matchers.should.Matchers
import tadp.microprocesador.monadas._
import scala.util.{Try, Success => TrySuccess, Failure => TryFailure}

class MonadasTest extends AnyFunSuite with Matchers {

  val microDelEjemplo: Micro = Micro(0, 0, List(13, 39, 0, 0, 4, 8, 15, 16, 23, 0) ++ List.fill(118)(0))
  val programaDelEjemplo: List[Instruction] = List(Load(0), Swap, Load(1), Add, Store(9))

  // Las dos versiones con Try, para correr cada caso en las dos
  def conTry(programa: List[Instruction], micro: Micro): List[Try[Micro]] =
    List(Operations3.run(programa, micro), Operations4.run(programa, micro))

  test("un micro sin memoria explícita arranca con 128 posiciones en 0") {
    Micro(0, 0).mem.size shouldBe 128
    Micro(0, 0).mem.forall(_ == 0) shouldBe true
  }

  test("las cuatro versiones ejecutan el programa del ejemplo y dejan el micro original igual") {
    val esperado = microDelEjemplo.copy(a = 52, b = 13, mem = microDelEjemplo.mem.updated(9, 52))

    Operations1.run(programaDelEjemplo, microDelEjemplo) shouldBe Operations1.Success(esperado)
    Operations2.run(programaDelEjemplo, microDelEjemplo) shouldBe Operations2.Success(esperado)
    conTry(programaDelEjemplo, microDelEjemplo) shouldBe List(TrySuccess(esperado), TrySuccess(esperado))
    microDelEjemplo.a shouldBe 0
  }

  test("IF ejecuta sus instrucciones solo si A es 0") {
    val programa = List(If(List(Load(0))))
    val conCinco = microDelEjemplo.copy(a = 5)

    Operations1.run(programa, microDelEjemplo).micro.a shouldBe 13
    Operations2.run(programa, microDelEjemplo).micro.a shouldBe 13
    conTry(programa, microDelEjemplo).map(_.get.a) shouldBe List(13, 13)

    Operations1.run(programa, conCinco) shouldBe Operations1.Success(conCinco)
    Operations2.run(programa, conCinco) shouldBe Operations2.Success(conCinco)
    conTry(programa, conCinco) shouldBe List(TrySuccess(conCinco), TrySuccess(conCinco))
  }

  test("un IF dentro de otro: el de adentro no se ejecuta y lo que sigue en el de afuera sí") {
    val programa = List(If(List(Load(0), If(List(Load(1))), Swap)))

    Operations1.run(programa, microDelEjemplo).micro.b shouldBe 13
    Operations2.run(programa, microDelEjemplo).micro.b shouldBe 13
    conTry(programa, microDelEjemplo).map(_.get.b) shouldBe List(13, 13)
  }

  test("HALT detiene la ejecución: Halted con Result, Failure con Try, y el micro del momento del HALT") {
    val programa = List(Load(0), Halt, Load(1))
    val alHalt = microDelEjemplo.copy(a = 13)

    Operations1.run(programa, microDelEjemplo) shouldBe Operations1.Halted(alHalt)
    Operations2.run(programa, microDelEjemplo) shouldBe Operations2.Halted(alHalt)

    Operations3.run(programa, microDelEjemplo) match {
      case TryFailure(e: Operations3.ExecutionHaltException) => e.micro shouldBe alHalt
      case otro => throw new AssertionError(s"se esperaba un Failure con el HALT y salió $otro")
    }
    Operations4.run(programa, microDelEjemplo) match {
      case TryFailure(e: Operations4.ExecutionHaltException) => e.micro shouldBe alHalt
      case otro => throw new AssertionError(s"se esperaba un Failure con el HALT y salió $otro")
    }
  }

  test("un HALT dentro de un IF que se ejecuta detiene todo el programa") {
    val programa = List(If(List(Load(0), Halt)), Load(1))
    val alHalt = microDelEjemplo.copy(a = 13)

    Operations1.run(programa, microDelEjemplo) shouldBe Operations1.Halted(alHalt)
    Operations2.run(programa, microDelEjemplo) shouldBe Operations2.Halted(alHalt)
    conTry(programa, microDelEjemplo).forall(_.isFailure) shouldBe true
  }

  test("un HALT dentro de un IF que no se ejecuta no detiene nada") {
    val programa = List(If(List(Halt)), Load(1))
    val conCinco = microDelEjemplo.copy(a = 5)
    val esperado = conCinco.copy(a = 39)

    Operations1.run(programa, conCinco) shouldBe Operations1.Success(esperado)
    Operations2.run(programa, conCinco) shouldBe Operations2.Success(esperado)
    conTry(programa, conCinco) shouldBe List(TrySuccess(esperado), TrySuccess(esperado))
  }

  test("una instrucción que fallaría dentro de un IF que no se ejecuta no hace fallar nada") {
    val programa = List(If(List(Load(500))))
    val conCinco = microDelEjemplo.copy(a = 5)

    Operations1.run(programa, conCinco) shouldBe Operations1.Success(conCinco)
    Operations2.run(programa, conCinco) shouldBe Operations2.Success(conCinco)
    conTry(programa, conCinco) shouldBe List(TrySuccess(conCinco), TrySuccess(conCinco))
  }

  test("un registro fuera de rango: Failure con el último micro válido (Result) o con el error (Try)") {
    val conMil = microDelEjemplo.copy(mem = microDelEjemplo.mem.updated(0, 1000).updated(1, 1000))
    val programa = List(Load(0), Swap, Load(1), Add, Load(2))

    Operations1.run(programa, conMil) match {
      case Operations1.Failure(micro, error) =>
        (micro.a, micro.b) shouldBe (1000, 1000)
        error.isInstanceOf[IllegalArgumentException] shouldBe true
      case otro => throw new AssertionError(s"se esperaba Failure y salió $otro")
    }
    Operations2.run(programa, conMil) match {
      case Operations2.Failure(micro, error) =>
        (micro.a, micro.b) shouldBe (1000, 1000)
        error.isInstanceOf[IllegalArgumentException] shouldBe true
      case otro => throw new AssertionError(s"se esperaba Failure y salió $otro")
    }
    conTry(programa, conMil).map(_.failed.get.isInstanceOf[IllegalArgumentException]) shouldBe List(true, true)
  }

  test("una dirección de memoria inexistente: Failure, sin excepción que se escape") {
    Operations1.run(List(Load(500)), microDelEjemplo) match {
      case Operations1.Failure(micro, error) =>
        micro shouldBe microDelEjemplo
        error.isInstanceOf[IndexOutOfBoundsException] shouldBe true
      case otro => throw new AssertionError(s"se esperaba Failure y salió $otro")
    }
    Operations2.run(List(Load(500)), microDelEjemplo).isInstanceOf[Operations2.Failure] shouldBe true
    conTry(List(Load(500)), microDelEjemplo).map(_.failed.get.isInstanceOf[IndexOutOfBoundsException]) shouldBe List(true, true)
  }

  test("la versión con for da lo mismo que la versión con map y flatMap, en Result y en Try") {
    val programas = List(
      programaDelEjemplo,
      List(If(List(Load(0), Halt)), Load(1)),
      List(If(List(Halt)), Load(1)),
      List(Load(500)),
      List(Load(1), Swap, Load(1), Mul, If(List(Add)), Store(3))
    )
    for (programa <- programas; micro <- List(microDelEjemplo, microDelEjemplo.copy(a = 5))) {
      Operations1.run(programa, micro).toString shouldBe Operations2.run(programa, micro).toString
      Operations3.run(programa, micro).isSuccess shouldBe Operations4.run(programa, micro).isSuccess
      Operations3.run(programa, micro).toOption shouldBe Operations4.run(programa, micro).toOption
    }
  }
}
```

### `src/test/scala/tadp/niveles/NivelesTest.scala`

**AGREGADO para esta referencia.** Los cinco niveles dan el mismo resultado; `ListaSnoc`, el `fold` a mano, lifteo y monoides.

```scala
// AGREGADO para esta referencia: el código de las diapositivas no trae tests.
package tadp.niveles

import org.scalatest.funsuite.AnyFunSuite
import org.scalatest.matchers.should.Matchers

class NivelesTest extends AnyFunSuite with Matchers {

  val todasLasMaterias: List[Materia] = List(
    Materia(electiva = true, cursos = List(
      Curso("K3001", List(Alumno("100", regular = true), Alumno("101", regular = false))),
      Curso("K3002", List(Alumno("102", regular = true)))
    )),
    Materia(electiva = false, cursos = List(
      Curso("K1001", List(Alumno("200", regular = true)))
    )),
    Materia(electiva = true, cursos = List(
      Curso("K4001", List(Alumno("300", regular = true), Alumno("301", regular = true)))
    ))
  )

  val esperado = List("100", "102", "300", "301")

  test("los cinco niveles responden lo mismo: legajos de los regulares inscriptos a electivas") {
    Nivel1PatternMatching.legajosDeRegularesEnElectivas(todasLasMaterias) shouldBe esperado
    Nivel2TipoAlgebraico.legajosDeRegularesEnElectivas(todasLasMaterias) shouldBe esperado
    Nivel3Fold.legajosDeRegularesEnElectivas(todasLasMaterias) shouldBe esperado
    Nivel4OrdenSuperior.legajosDeRegularesEnElectivas(todasLasMaterias) shouldBe esperado
    Nivel4OrdenSuperior.encadenado(todasLasMaterias) shouldBe esperado
    Nivel5For.legajosDeRegularesEnElectivas(todasLasMaterias) shouldBe esperado
    Nivel5For.traducido(todasLasMaterias) shouldBe esperado
  }

  test("sin materias, todos los niveles devuelven la lista vacía") {
    Nivel1PatternMatching.legajosDeRegularesEnElectivas(Nil) shouldBe Nil
    Nivel2TipoAlgebraico.legajosDeRegularesEnElectivas(Nil) shouldBe Nil
    Nivel3Fold.legajosDeRegularesEnElectivas(Nil) shouldBe Nil
    Nivel4OrdenSuperior.legajosDeRegularesEnElectivas(Nil) shouldBe Nil
    Nivel5For.legajosDeRegularesEnElectivas(Nil) shouldBe Nil
  }

  test("append concatena en los tres niveles que lo definen") {
    Nivel1PatternMatching.append(List(1, 2), List(3)) shouldBe List(1, 2, 3)
    Nivel2TipoAlgebraico.append(List(1, 2), List(3)) shouldBe List(1, 2, 3)
    Nivel3Fold.append(List(1, 2), List(3)) shouldBe List(1, 2, 3)
  }

  test("ListaSnoc: se construye agregando al final y responde head, tail y ::") {
    val unoDosTres = ListaSnoc.empty[Int] :+ 1 :+ 2 :+ 3

    (ListaSnoc.empty[Int] :+ 1).head shouldBe 1      // (Snoc Nil 1).head
    unoDosTres.last shouldBe 3
    unoDosTres.head shouldBe 1
    unoDosTres.tail shouldBe (ListaSnoc.empty[Int] :+ 2 :+ 3)
    (0 :: unoDosTres) shouldBe (ListaSnoc.empty[Int] :+ 0 :+ 1 :+ 2 :+ 3)
  }

  test("ListaSnoc: head, last y tail de una lista vacía fallan") {
    intercept[NoSuchElementException] { ListaSnoc.empty[Int].head }
    intercept[NoSuchElementException] { ListaSnoc.empty[Int].last }
    intercept[UnsupportedOperationException] { ListaSnoc.empty[Int].tail }
  }

  test("las funciones del nivel 2 funcionan igual sobre la otra representación") {
    val alumnos = ListaSnoc.empty[Alumno] :+ Alumno("100", true) :+ Alumno("101", false) :+ Alumno("102", true)

    Nivel2SobreSnoc.legajos(Nivel2SobreSnoc.regulares(alumnos)) shouldBe (ListaSnoc.empty[String] :+ "100" :+ "102")
  }

  test("el fold a mano es un foldLeft") {
    Nivel3Fold.fold[Int, Int]((acumulado, x) => acumulado + x)(0)(List(1, 2, 3)) shouldBe 6
    Nivel3Fold.fold[String, String]((acumulado, x) => acumulado + x)("")(List("a", "b", "c")) shouldBe "abc"
    Nivel3Fold.fold[Int, List[Int]]((acumulado, x) => x :: acumulado)(Nil)(List(1, 2, 3)) shouldBe List(3, 2, 1)
  }

  test("lifteo: map y filter convierten funciones de un elemento en funciones de listas") {
    Lifteo.liftear((n: Int) => n + 1)(List(1, 2, 3)) shouldBe List(2, 3, 4)
    Lifteo.filtrarPares(List(1, 2, 3, 4)) shouldBe List(2, 4)
  }

  test("monoides: combinar todos con el neutro como semilla") {
    import Monoide._
    combinarTodos(List(1, 2, 3, 4))(SumaInt) shouldBe 10
    combinarTodos(List(1, 2, 3, 4))(ProductoInt) shouldBe 24
    combinarTodos(List("ho", "la"))(ConcatenacionString) shouldBe "hola"
    combinarTodos(List(true, false))(Conjuncion) shouldBe false
    combinarTodos(List(true, false))(Disyuncion) shouldBe true
    combinarTodos(List[Int => Int](_ + 1, _ * 10))(composicion[Int])(2) shouldBe 21
    combinarTodos(List.empty[Int])(SumaInt) shouldBe 0
  }

  test("monoides: el neutro no altera y la operación es asociativa") {
    import Monoide._
    SumaInt.combinar(SumaInt.neutro, 7) shouldBe 7
    ConcatenacionString.combinar("ab", ConcatenacionString.neutro) shouldBe "ab"
    SumaInt.combinar(1, SumaInt.combinar(2, 3)) shouldBe SumaInt.combinar(SumaInt.combinar(1, 2), 3)
  }
}
```

### `src/test/scala/tadp/cajas/CajasTest.scala`

**AGREGADO para esta referencia.** `Caja` y sus leyes, los dos ejemplos del script, el mail del titular, la inscripción, `Try` y los futuros.

```scala
// AGREGADO para esta referencia: el código de las diapositivas y del pizarrón no trae tests.
package tadp.cajas

import org.scalatest.funsuite.AnyFunSuite
import org.scalatest.matchers.should.Matchers
import scala.concurrent.Await
import scala.concurrent.duration._
import scala.util.{Try, Success, Failure}

class CajaTest extends AnyFunSuite with Matchers {
  import tadp.cajas.monada._

  test("map y filter salen de flatMap, unit y zero") {
    Caja.unit(3).map(_ + 1) shouldBe Llena(4)
    Caja.unit(3).filter(_ > 2) shouldBe Llena(3)
    Caja.unit(3).filter(_ > 5) shouldBe Vacia
    Caja.zero[Int].map(_ + 1) shouldBe Vacia
  }

  test("leyes: identidad izquierda, identidad derecha y asociatividad") {
    val f = (n: Int) => if (n > 0) Caja.unit(n * 2) else Caja.zero[Int]
    val g = (n: Int) => Caja.unit(n + 1)
    val m = Caja.unit(5)

    Caja.unit(5).flatMap(f) shouldBe f(5)
    m.flatMap(Caja.unit) shouldBe m
    m.flatMap(f).flatMap(g) shouldBe m.flatMap(x => f(x).flatMap(g))
  }

  test("leyes de zero y plus: neutro, asociatividad y zero izquierdo") {
    (Caja.zero[Int] ++ Caja.unit(1)) shouldBe Llena(1)
    (Caja.unit(1) ++ Caja.zero[Int]) shouldBe Llena(1)
    ((Caja.unit(1) ++ Caja.zero[Int]) ++ Caja.unit(2)) shouldBe (Caja.unit(1) ++ (Caja.zero[Int] ++ Caja.unit(2)))
    Caja.zero[Int].flatMap(n => Caja.unit(n * 2)) shouldBe Vacia
  }

  test("cualquier caja con map, flatMap y withFilter se puede usar en un for") {
    val resultado = for {
      x <- Caja.unit(3) if x > 2
      y <- Caja.unit(4)
    } yield x + y
    resultado shouldBe Llena(7)

    (for { x <- Caja.unit(1) if x > 2 } yield x) shouldBe Vacia
  }

  test("script: encadenar filter, map y flatMap nunca obliga a preguntar si la caja tiene contenido") {
    val f = (n: Int) => n > 0
    val g = (n: Int) => n * 10
    val h = (n: Int) => n < 100
    val i = (n: Int) => List(n, n + 1)
    val j = (n: Int) => n % 2 == 0
    def caja(contenido: List[Int]) = contenido.filter(f).map(g).filter(h).flatMap(i).filter(j).size > 2

    caja(List(1, 2, 3, -4)) shouldBe true      // 10, 20, 30 → 10, 11, 20, 21, 30, 31 → 10, 20, 30
    caja(List.empty) shouldBe false
    caja(List(-1, 50)) shouldBe false          // ninguno sobrevive a los filtros
  }

  test("script: la cadena de flatMap, filter y map, y su for, dan lo mismo") {
    val caja = List(1, 2, 3)
    val tx1 = (e: Int) => List(e, e * 10)
    val tx2 = (e: Int) => List(e + 1)
    val crit = (e: Int) => e % 2 == 0
    val tx3 = (e: Int) => s"<$e>"

    val anidado = caja.flatMap { e1 =>
      tx1(e1).flatMap { e2 =>
        tx2(e2).filter { e3 =>
          crit(e3)
        }.map { e4 =>
          tx3(e4)
        }
      }
    }
    val conFor = for {
      e1 <- caja
      e2 <- tx1(e1)
      e3 <- tx2(e2)
      if crit(e3)
    } yield tx3(e3)

    anidado shouldBe conFor
    conFor shouldBe List("<2>", "<4>")
  }

  test("la lista cumple el mismo contrato: unit = List(x), bind = flatMap, zero = Nil, plus = ++") {
    List(5).flatMap(n => List(n, n)) shouldBe List(5, 5)
    (List.empty[Int] ++ List(1)) shouldBe List(1)
    List(1, 2, 3).flatMap(v => if (v > 1) List(v) else Nil) shouldBe List(1, 2, 3).filter(_ > 1)
  }
}

class MailTest extends AnyFunSuite with Matchers {
  import tadp.cajas.mail._

  test("con null: cada caso que falta termina en el warning") {
    val log = new Log
    ConNull.enviarAlTitular(new ConNull.Curso("K1", new ConNull.Docente("1", "ana@utn.edu.ar")), log)
    ConNull.enviarAlTitular(new ConNull.Curso("K2", null), log)
    ConNull.enviarAlTitular(new ConNull.Curso("K3", new ConNull.Docente("2", null)), log)
    ConNull.enviarAlTitular(new ConNull.Curso("K4", new ConNull.Docente("3", "sin-arroba")), log)

    log.lineas.toList shouldBe List(
      "INFO: Se mandó mail enviado a ana@utn.edu.ar",
      "WARNING: No se pudo Mandar",
      "WARNING: No se pudo Mandar",
      "WARNING: No se pudo Mandar"
    )
  }

  test("con Option: sin titular o sin mail, la caja vacía llega sola hasta el fold") {
    import ConOption._
    val log = new Log
    enviarAlTitular(Curso("K1", Some(Docente("1", Some("ana@utn.edu.ar")))), log)
    enviarAlTitular(Curso("K2", None), log)
    enviarAlTitular(Curso("K3", Some(Docente("2", None))), log)

    log.lineas.toList shouldBe List(
      "INFO: Se mandó mail enviado a ana@utn.edu.ar",
      "WARNING: No se pudo Mandar",
      "WARNING: No se pudo Mandar"
    )
  }

  test("si mandar también puede no tener resultado, es flatMap y el fallo se maneja igual") {
    import ConOption.{Curso, Docente}
    val log = new Log
    ConOptionYMandarQuePuedeFallar.enviarAlTitular(Curso("K1", Some(Docente("1", Some("ana@utn.edu.ar")))), log)
    ConOptionYMandarQuePuedeFallar.enviarAlTitular(Curso("K4", Some(Docente("3", Some("sin-arroba")))), log)

    log.lineas.toList shouldBe List("INFO: Se mandó mail enviado a ana@utn.edu.ar", "WARNING: No se pudo Mandar")
  }

  test("Option: construcción desde null, getOrElse y fold") {
    Option(null) shouldBe None
    Option("algo") shouldBe Some("algo")
    (None: Option[String]).getOrElse("por defecto") shouldBe "por defecto"
    Some("algo").getOrElse("por defecto") shouldBe "algo"
    Some(3).fold(0)(_ * 2) shouldBe 6
    (None: Option[Int]).fold(0)(_ * 2) shouldBe 0
  }
}

class InscripcionTest extends AnyFunSuite with Matchers {
  import tadp.cajas.inscripcion._

  test("con excepciones: anota, pide autorización si hace falta, y explota si no hay cupo") {
    val ana = Alumno("1")
    ConExcepciones.anotar(ana, new Curso(1, new Docente, requiereAutorizacion = false)).inscriptos.toList shouldBe List(ana)
    ConExcepciones.anotar(ana, new Curso(1, new Docente, requiereAutorizacion = true)).inscriptos.toList shouldBe List(ana)
    intercept[NoHayCupo] { ConExcepciones.anotar(ana, new Curso(0, new Docente, requiereAutorizacion = false)) }
  }

  test("con Try: el mismo comportamiento, pero el error vuelve como Failure") {
    val ana = Alumno("1")
    ConTry.anotar(ana, new Curso(1, new Docente, requiereAutorizacion = false)).map(_.inscriptos.toList) shouldBe Success(List(ana))
    ConTry.anotar(ana, new Curso(1, new Docente, requiereAutorizacion = true)).map(_.inscriptos.toList) shouldBe Success(List(ana))
    ConTry.anotar(ana, new Curso(0, new Docente, requiereAutorizacion = false)).failed.get.isInstanceOf[NoHayCupo] shouldBe true
  }

  test("Try: getOrElse, fold, toOption y filter") {
    val bien: Try[Int] = Try(10)
    val mal: Try[Int] = Try(throw new IllegalStateException("explotó"))

    mal.getOrElse(0) shouldBe 0
    bien.fold(_ => "falló", n => s"dio $n") shouldBe "dio 10"
    mal.fold(_ => "falló", n => s"dio $n") shouldBe "falló"
    bien.toOption shouldBe Some(10)
    mal.toOption shouldBe None
    mal.recover { case _: IllegalStateException => -1 } shouldBe Success(-1)

    // filter en Try no puede dejar la caja vacía: la convierte en un Failure
    bien.filter(_ > 50) match {
      case Failure(e) => e.isInstanceOf[NoSuchElementException] shouldBe true
      case otro => throw new AssertionError(s"se esperaba Failure y salió $otro")
    }
  }
}

class FuturosTest extends AnyFunSuite with Matchers {
  import tadp.cajas.futuros._

  test("for con las cajas creadas adentro: la segunda empieza cuando termina la primera") {
    val cajas = new Cajas(200)
    Await.result(cajas.sumaSecuencial(), 5.seconds) shouldBe 3
    cajas.eventos.indexOf("empieza otraCaja") > cajas.eventos.indexOf("termina estaCaja") shouldBe true
  }

  test("for con las cajas creadas antes: las dos corren a la vez") {
    val cajas = new Cajas(200)
    Await.result(cajas.sumaEnParalelo(), 5.seconds) shouldBe 3
    cajas.eventos.indexOf("empieza otraCaja") < cajas.eventos.indexOf("termina estaCaja") shouldBe true
  }

  test("una lista de futuros pasa a ser un futuro de lista") {
    val cajas = new Cajas(50)
    Await.result(Secuencia.todosJuntos(List(cajas.estaCaja(), cajas.otraCaja())), 5.seconds) shouldBe List(1, 2)
  }
}
```

---

**FIN DEL ARCHIVO — Código final unificado — clase10 — Comportamiento vs estructura y mónadas**
