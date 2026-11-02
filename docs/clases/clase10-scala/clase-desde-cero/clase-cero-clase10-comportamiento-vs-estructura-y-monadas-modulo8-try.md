# Clase desde cero — Comportamiento vs estructura y mónadas — Módulo 8: `Try`, la caja que puede haber fallado

**Unidad:** clase10 · **Lenguaje:** Scala 3.3.1 · **Archivo del proyecto:** `cajas/inscripcion/Inscripcion.scala` (y su test, `InscripcionTest`) · **Densidad:** 🔴 pide una sesión con el código abierto (la sección 6 es 🟡)

---

## Sobre este documento

**Qué cubre.** La segunda caja de la biblioteca de Scala: `Try[T]`, la caja que tiene el valor o tiene el error, como reemplazo de las excepciones. El problema que la motiva (pedir el docente por internet puede explotar), por qué las excepciones son otro patrón que te fuerza, `Success`/`Failure`, `Try { … }` y por qué recibe el bloque por nombre, anotar un alumno a un curso con excepciones y con `Try` + `recover`, qué puede `Try` que `Option` no puede y al revés (y por qué eso le cuesta el `filter`), cómo se abre un `Try` (`fold` con dos funciones, `getOrElse`, `toOption`) y por qué distintas cajas se abren distinto, qué tiene de malo devolver un código de error, el costo estructural, y el pipeline del mail con `Try` en lugar de `Option` sin tocar nada más.

**Qué no cubre.** El `for` sobre `Try` (Módulo 9, y completo en el Módulo 10 con el micro). `Try` dentro del micro, en lugar de `Result` (Módulo 10). `Future`, `Either` y las demás cajas (Módulo 11).

## De dónde venís

Del Módulo 7: `Option`, el pipeline `flatMap`/`map`/`fold`, abrir la caja una sola vez al final, `Option` como mónada plus. Del Módulo 6: `unit`, `bind`, `zero` y `plus`; `filter` necesita `zero`. Del Módulo 3: función parcial (`head` sobre la vacía). Del Módulo 1: transparencia referencial ("TR" en el vértice de pureza). De la unidad anterior: el `Result` del micro con sus tres formas (`Success`, `Halted`, `Failure`), y el parámetro por nombre (`=> R`).

---

## 1. 🔴 Pedir el docente puede explotar

> Si obtener el docente es un pedido por internet, pedir el mail es una consulta a una base de datos y mandar el mail puede fallar de mil formas, las operaciones dejan de *poder faltar* y pasan a **poder fallar**. La herramienta habitual para eso, `try`/`catch`, es **otro patrón que te fuerza**, como el `if (x != null)` y el `case Nil`.

Volvé al pipeline del Módulo 7, y cambiá una cosa: el docente ya no está en memoria. Se pide a un servicio por internet, y si no hay internet, explota. El mail se busca en una base de datos, que tal vez está caída: explota. Mandar el mail puede fallar de mil formas distintas. Cualquier cosa que falla causa un error, y la forma en que venís manejando errores es lanzar una excepción y atraparla con `try`/`catch`.

Fijate qué pasa cuando querés contemplar los dos casos (salió bien, salió mal) en cada paso: tenés que envolver el código en un `try`/`catch`. Suena parecido a envolver el código en un `if (x != null)`. Cada caso especial te impone **un patrón distinto de trabajo**: para las listas uno (`case Nil`), para los `null` otro (`if`), para las excepciones otro (`try`/`catch`). Tres formas de preguntar "¿esto salió como esperaba?", tres sintaxis, tres lugares donde olvidarse.

Lo que se propone es lo mismo que con `null`: en vez de lanzar una excepción y manejar un flujo especial, **un tipo de dato que representa "esto pudo haber salido bien o mal"**. Con una condición: como querés conservar la información de por qué explotó (si no, sería una versión inferior a las excepciones), la caja tiene que guardar, además del valor cuando salió bien, **el error cuando salió mal**.

Esta idea ya la tuviste, en su versión estructural. El `Result` del micro, de la unidad anterior, hace eso: necesitábamos que `run` pudiera explotar o devolver el micro, y lo metimos en la imagen de la función, como formas. Lo que faltó ahí fue toda la lógica para tratarlo igual que las otras cajas. Es la misma manera de pensar; `Try` es esa idea completa, y viene con Scala.

## 2. 🔴 `Try[T]`: el valor o el error

> `Try[T]` tiene dos formas: `Success(valor)`, con el `T` adentro, y `Failure(error)`, con la excepción adentro **como dato**, sin lanzarla. **`Try { … }` recibe el bloque por nombre**: lo ejecuta adentro, y si el bloque lanza una excepción, la atrapa y la guarda en un `Failure`; si termina bien, guarda el resultado en un `Success`.

```
       ┌────────────────────────────────────────────┐
       │                   Try[T]                   │
       ├────────────────────────────────────────────┤
       │  apply[T](value: => T): Try[T]             │   unit; el bloque va por nombre
       │                                            │
       │  map[R](f: T => R): Try[R]                 │
       │  flatMap[R](f: T => Try[R]): Try[R]        │   bind
       │  filter(f: T => Boolean): Try[T]           │   con asterisco (sección 4)
       │                                            │
       │  fold[R](fe: Throwable => R, f: T => R): R │
       │  getOrElse(default: T): T                  │
       │  recover(handler: Throwable => T): Try[T]  │
       │  toOption: Option[T]                       │
       └────────────────────────────────────────────┘
                              △
             ┌────────────────┴──────────────┐
             │                               │
┌────────────────────────┐   ┌──────────────────────────────┐
│  Success[T](value: T)  │   │  Failure[T](err: Throwable)  │
└────────────────────────┘   └──────────────────────────────┘
```

Las dos cajas **tienen contenido**. Solo una tiene el contenido que te interesa, el `T`; la otra tiene una explicación de por qué no lo tiene: una excusa. Eso es `Failure`: no una excepción lanzada, sino el objeto excepción, el dato que la describe, guardado adentro de la caja. En algún lugar de la cadena de cómputo algo salió mal, y acá está el porqué.

(Las firmas del dibujo están simplificadas, como en el Módulo 7: el `default` de `getOrElse` va por nombre, y `recover` recibe una función parcial; la sección 3 lo muestra.)

`Try` se construye con un bloque, y el bloque va **por nombre** (`=> T`): se evalúa adentro de `Try`, con un `try`/`catch` alrededor. Por eso captura la excepción en vez de explotar. (Atrapa las excepciones "normales"; las fatales de la JVM, como quedarse sin memoria, salen igual: no son algo de lo que un `recover` pueda recuperarse.)

```scala
import scala.util.{Try, Success, Failure}

Try(10)                                           // Resultado: Success(10)
Try(10 / 0)                                       // Resultado: Failure(java.lang.ArithmeticException: / by zero)
Try(throw new IllegalStateException("explotó"))   // Resultado: Failure(java.lang.IllegalStateException: explotó)
Try("42".toInt)                                   // Resultado: Success(42)
Try("cuarenta y dos".toInt)                       // Resultado: Failure(java.lang.NumberFormatException: For input string: "cuarenta y dos")
```

Si el parámetro fuera común, `10 / 0` se evaluaría antes de entrar a `Try`, en tu código, y explotaría ahí. Es el mismo mecanismo del `ifEmpty` del `fold` y del `Result.apply` de la unidad anterior: lo que va por nombre se ejecuta donde lo recibe, y acá eso es lo que permite atraparlo.

⚠️ **Nomenclatura: "lazy" por "por nombre".** Vas a ver que al bloque de `Try` se lo llama *lazy*. Por nombre es lo preciso: se evalúa cada vez que se usa, donde se usa; `lazy val` es otra cosa (se evalúa una sola vez, la primera que se pide).

Y las operaciones de caja, exactamente como en `Option`: `Success` aplica la función; `Failure` se pasa tal cual, sin ejecutar nada.

```scala
val bien: Try[Int] = Try(10)
val mal: Try[Int]  = Try(throw new IllegalStateException("explotó"))

bien.map(_ * 2)                                   // Resultado: Success(20)
mal.map(_ * 2)                                    // Resultado: Failure(java.lang.IllegalStateException: explotó)
bien.flatMap(n => Try(n / 0))                     // Resultado: Failure(java.lang.ArithmeticException: / by zero)
bien.flatMap(n => Try(100 / n))                   // Resultado: Success(10)
mal.flatMap(n => Try(100 / n))                    // Resultado: Failure(java.lang.IllegalStateException: explotó)
```

Un `map` sobre un `Failure` devuelve el mismo `Failure`, con la misma excusa adentro; un `flatMap` cuya función devuelve un `Failure` lo propaga con la excusa de ese paso. Y las dos atrapan: si la función que les pasás lanza (`bien.map(_ / 0)`), el resultado es un `Failure`, no una explosión. El error **viaja** por la cadena, como viajaba la caja vacía, y llega al final con el porqué.

## 3. 🔴 Anotar un alumno: con excepciones y con `Try`

> Objetos eligió las excepciones por razones históricas; **podría devolver `Try`** y sería perfectamente razonable. El código queda casi igual: `Try { … }` alrededor de lo que puede fallar, y `recover` en lugar de `catch`. Lo que cambia es que **el tipo de la función documenta que puede fallar**.

El ejemplo: anotar un alumno a un curso. El curso sabe si tiene cupo e inscribe; si el alumno no está autorizado, `inscribir` lanza `NoAutorizado`; el docente del curso puede autorizarlo. Si no hay cupo, no hay nada que hacer.

```
          ┌────────────────────────────────────┐
          │               Curso                │
          ├────────────────────────────────────┤
          │  hayCupo: Boolean                  │
          │  inscribir(alumno: Alumno): Curso  │    lanza NoAutorizado
          │  docente: Docente                  │
          └────────────────────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────┐
│                        Docente                         │
├────────────────────────────────────────────────────────┤
│  autorizarIngreso(alumno: Alumno, curso: Curso): Unit  │
└────────────────────────────────────────────────────────┘
```

La forma típica, en objetos (en el proyecto, `ConExcepciones`):

```scala
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
```

Intento inscribirlo. Si no hay cupo, lanzo `NoHayCupo` y que lo maneje quien llamó. Si falla por `NoAutorizado`, lo atrapo (acá, o en quien llamó: dónde va el `catch` es una decisión), pido al docente que lo autorice, y vuelvo a inscribir. Si falla por segunda vez, explota de verdad.

Lo mismo con `Try` (en el proyecto, `ConTry`):

```scala
import scala.util.Try

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

Comparalos línea por línea. El cuerpo es el mismo: el chequeo de cupo con su `throw`, la inscripción, y el manejo del `NoAutorizado` con la autorización y el reintento. Cambiaron tres cosas: el tipo de retorno, `Try[Curso]` en vez de `Curso`; el `Try { … }` alrededor del código que puede fallar; y `recover` en lugar de `catch`. El `throw new NoHayCupo` sigue ahí adentro, y ya no sale del método: el `Try` lo atrapa y devuelve un `Failure(NoHayCupo)` en vez de explotar.

```scala
import tadp.cajas.inscripcion._

val ana = Alumno("1")
ConTry.anotar(ana, new Curso(1, new Docente, requiereAutorizacion = false)).map(_.inscriptos.toList)
// Resultado: Success(List(Alumno(1)))
ConTry.anotar(ana, new Curso(1, new Docente, requiereAutorizacion = true)).map(_.inscriptos.toList)
// Resultado: Success(List(Alumno(1)))        falló por NoAutorizado, recover autorizó y reinscribió
ConTry.anotar(ana, new Curso(0, new Docente, requiereAutorizacion = false))
// Resultado: Failure(tadp.cajas.inscripcion.NoHayCupo: no hay cupo)
```

(`requiereAutorizacion` es un detalle del proyecto para poder provocar el `NoAutorizado` en un test; en el dominio original, `inscribir` lo decide por su cuenta.)

**`recover` es el `catch` con mensajes.** Recibe una función parcial sobre la excepción, en el sentido del Módulo 3 (definida solo para algunas excepciones), que en Scala se escribe con `case` sobre el tipo de error, como el `catch`; si la caja es un `Failure` con una excepción que la función contempla, la aplica y devuelve un `Success` con lo que dio; si es un `Success`, o un `Failure` con otra excepción, lo deja pasar. Y si lo que hace el `recover` también falla (el segundo `inscribir` vuelve a lanzar), tampoco explota: queda un `Failure` con esa excepción. Es la diferencia con la versión de excepciones, donde la segunda falla sí sale del método. Es parecido a `map`, trabajando sobre la excusa en vez de sobre el valor. Y **`recover` es una operación específica de `Try`, no del contrato de mónada**: `unit`, `bind` y lo derivado son lo que todas las cajas comparten; `recover` solo tiene sentido en una caja que guarda errores, como `getOrElse` solo tiene sentido en una que puede estar vacía.

```scala
mal.recover { case _: IllegalStateException => -1 }     // Resultado: Success(-1)
bien.recover { case _: IllegalStateException => -1 }    // Resultado: Success(10)       no había nada que recuperar
mal.recover { case _: ArithmeticException => -1 }       // Resultado: Failure(java.lang.IllegalStateException: explotó)   otra excepción: pasa
```

Lo que se conserva de las excepciones es justo lo que tenían de bueno: **vos escribís solo el camino feliz**, como si todo saliera bien, y si algo falla, el error "burbujea" solo hasta el lugar donde alguien lo quiere manejar. Mientras no te querés recuperar, seguís mapeando como si nada hubiera pasado. Lo único que le decís al `recover` es "si fue por esto, hacé esto otro".

Y el costo, dicho con honestidad: el tipo de la función cambió. `anotar` ya no devuelve un curso; devuelve "un curso, si no surgió ningún error; si surgió, el error". Eso está bueno (el tipo es explícito sobre que puede fallar) y también afecta la cadena de mensajes donde `anotar` se usa: quien llamaba y recibía un `Curso` ahora recibe una caja, y tiene que trabajar con ella.

## 4. 🔴 Qué puede `Try` que `Option` no, y al revés

> `Try` guarda **el porqué**; `Option` solo dice que falta. `Option` **puede estar vacío**; `Try` siempre tiene algo adentro (el valor o el error). Por eso `Option` es mónada plus y **`Try` es solo mónada**: sin `zero`, y sin `zero` el `filter` no se puede escribir bien.

Son dos preguntas, y conviene tenerlas separadas.

**¿Qué podés hacer con `Try` que con `Option` no?** Elegir cómo manejar el fallo, porque tenés un paso previo: la caja guarda la información del error. `Option` te dice "la cosa está o no está"; `Try` te dice "tenés la cosa o tenés un error, y este es el error". Con eso podés recuperarte de un error y de otro no (`recover` con un `case` por tipo), loguear qué pasó, decidir distinto según la causa.

**¿Qué podés hacer con `Option` que con `Try` no?** Tener la caja **vacía**. `Option` tiene `None`, un vacío único, sin explicaciones. `Try` no: siempre tiene un valor o un error. Para "vaciar" un `Try` habría que inventarse una excepción que diga "esto está vacío", y eso queda sucio: en una caja que existe para contar por qué falló, "falló porque está vacía" es un error de mentira.

Y esa segunda diferencia tiene una consecuencia en el contrato. En el Módulo 6: `filter` se escribe con `flatMap` y `zero`, porque filtrar necesita poder quedarse sin contenido. `Option` tiene `zero` (`None`) y `plus` (`orElse`): es mónada plus, y `filter` sale solo. **`Try` no tiene `zero`**: es mónada, y nada más. (Tiene `orElse`, que se parece al `plus` de `Option`; pero sin `zero` no hay neutro, y sin neutro no hay monoide: no es mónada plus.) Entonces, estrictamente, **`Try` no puede filtrar**, porque no puede construir la caja sin nada adentro.

Scala te pone igual un `filter` en `Try`. Es un parche: si el predicado no se cumple, en vez de una caja vacía te devuelve un **`Failure` con una excepción inventada** que dice "el predicado no se cumplió".

```scala
bien.filter(_ > 5)       // Resultado: Success(10)
bien.filter(_ > 50)      // Resultado: Failure(java.util.NoSuchElementException: Predicate does not hold for 10)
```

⚠️ **Trampa: el `filter` de `Try` tiene asterisco.** Compila, existe, y no cumple las reglas: el `Failure` que produce no se distingue después de un error de verdad (un `recover` genérico lo atrapa como a cualquier otro). En `List` y en `Option`, `filter` es de verdad.

> 🕳️ **Madriguera — ¿`Try` es una mónada "pura"?**
> Se discute. La identidad izquierda del Módulo 6 dice `bind f (unit v) == f v`; con `Try`, si `f(v)` lanza una excepción, `Try(v).flatMap(f)` da un `Failure` y `f(v)` explota: los dos lados no son lo mismo. Para esta unidad alcanza con que `Try` se trabaje con el contrato (`flatMap`, `map`) igual que las otras cajas.
> *Volvé al camino — vuelve en el Módulo 11, donde `Future` tiene una discusión parecida.*

⚠️ **Nomenclatura: "monoide" por `Try`.** Si te cruzás con "el monoide `Try`" (o con "mónadas, o monoide para el caso del `Try`"), es un error de nombre: monoide es lo del Módulo 4 (operación asociativa con neutro), y `Try` es una **mónada** que no es mónada plus. Respondé con eso.

## 5. 🔴 Distintas cajas se abren distinto

> `Try` se abre con un `fold` de **dos funciones** (qué hacer con el error, qué hacer con el valor), con `getOrElse`, o se convierte a `Option` con `toOption`. De las cuatro operaciones de orden superior, **`filter`, `map` y `flatMap` son iguales en todas las cajas; solo `fold` cambia**, porque cada caja se abre pensando en sus propias formas.

```
fold[R](fe: Throwable => R, f: T => R): R
```

El `fold` de `Try` es, como el de `Option`, el catamorfismo sin recorrido: da los dos caminos, y los dos son funciones: si hay un error, te doy algo que hacer con la excepción para llegar al `R`; si hay un valor, algo que hacer con el valor. Es distinto del `fold` de `Option` (un valor y una función) y del de la lista (semilla y combinación). Fijate que acá las dos van en una sola lista de parámetros, separadas por coma; en `Option` iban en dos.

```scala
bien.fold(e => "falló", n => s"dio $n")        // Resultado: dio 10
mal.fold(e => "falló", n => s"dio $n")         // Resultado: falló
mal.fold(e => s"falló: ${e.getMessage}", n => s"dio $n")   // Resultado: falló: explotó
bien.getOrElse(0)                              // Resultado: 10
mal.getOrElse(0)                               // Resultado: 0
```

Fijate que los tres `fold` **no son polimórficos entre sí**: con `fold` tratás a cada caja según lo que es, y no podés tratar una caja indistintamente de otra. Lo polimórfico son las operaciones del contrato (`map`, `flatMap`, `filter` con asterisco): con esas, el mismo código sirve para cualquier caja. Con `fold`, estás abriendo *esta* caja, y para abrirla tenés que saber cuáles son sus formas: una lista tiene `Nil` y `::`, un `Option` tiene `None` y `Some`, un `Try` tiene `Failure` y `Success`. **Distintas cajas se abren distinto.** Es lo que el Módulo 7 dejó asomar con las listas: lo que cambia es la última operación, la que te baja.

Y vale para `Try` lo que el Módulo 7 dijo de `Option`: tiene una forma (`Success`/`Failure`) y un tipo abstracto chico (`isSuccess`, `get`), y hacer `match` sobre `Success`/`Failure` es volver al nivel 1. `recover` y `fold` son las operaciones que hacen ese trabajo sin abrir la caja a mano; el Módulo 10 lo retoma con el TP.

Y `toOption`: `Try` es tan parecido a `Option` que hay un mensaje para pasar de uno a otro. Descarta la excusa y mete el valor en un `Some` (o da `None`).

```scala
bien.toOption                                  // Resultado: Some(10)
mal.toOption                                   // Resultado: None
```

Por qué existe: **las cajas no se cruzan**, no se llevan bien entre ellas. Es difícil trabajar con una caja roja (un `Try`) en un contexto de cajas azules (los `Option`): un `flatMap` sobre un `Option` quiere una función que devuelva `Option`, y si lo que tenés devuelve `Try`, los tipos no encajan. Por eso suele haber formas de convertir una caja en otra. Es un tema que vuelve en el Módulo 11.

## 6. 🟡 Por qué no un código de error, qué cuesta `Try`, y dónde se usa

> Devolver `-2` como error es **ambiguo y no tipa**; `Try` es honesto y cuesta un objeto envuelto. Y `Try` es solo un contrato: se escribe en cualquier lenguaje que deje definir un tipo, y en los lenguajes funcionales se usa más porque es lo natural cuando todo son funciones puras que van y vuelven con valores.

**El código de error.** La alternativa vieja a las excepciones era devolver un número: `0` si salió bien, `-1` o `-2` según el error. Tiene los problemas del `null` y uno más. Como el `null`, pone el peso del lado del programador: tenés que acordarte de chequear en cada paso. Y además, **no tipa**: ¿qué hacés cuando la función legítimamente puede devolver un número negativo? Si te devuelvo `-2`, ¿es el código de error `-2` o el resultado dio `-2`? Estás perdido, porque elegiste para los errores el mismo tipo de dato que para los resultados, y tenés que saberlo caso por caso.

**El costo de `Try`.** `Try` también cobra: tiene **complejidad estructural**. Para modelar que algo puede salir mal, te lo tengo que envolver en otro dato. Un valor que antes se representaba con una cosa ahora se representa con dos. Imaginate todo tu código que hoy tiene excepciones, con objetos envueltos en objetos: es más incómodo de trabajar. Las excepciones existen porque hay situaciones donde ese costo vale menos que la comodidad de no envolver.

**Lo que `Try` pide del lenguaje: nada.** Las excepciones necesitan dos mecanismos superpuestos: el de llamar y retornar (funciones, métodos) y uno de eventos, donde algo frena el proceso, sube por la pila, es capturado, y la ejecución retoma. No todas las tecnologías lo tienen. `Try`, en cambio, es solo un contrato: una estructura con dos formas y una operación muy primitiva. Lo podés implementar en cualquier lenguaje que te deje definir un tipo, y no hace falta que el lenguaje lo provea.

> 🕳️ **Madriguera — Go y los errores por valor**
> Go no tiene excepciones: cada función que puede fallar devuelve el resultado y el error, y quien llama tiene que preguntar `if err != nil` en cada paso. Es el código con `null` de la sección 1 del Módulo 7, como regla del lenguaje, y se vende como virtud ("somos rápidos"): rápido porque el chequeo que el lenguaje no hace lo hacés vos, en cada llamada de tu sistema. `Try` sería la forma de encajonar eso, y Go no lo trae; se lo escribe uno, porque es solo un contrato.
> *Volvé al camino — esto se profundiza aparte, otro día.*

**Dónde se usa más.** En los lenguajes funcionales esta forma de manejar errores es mucho más común, porque se trabaja todo el tiempo con funciones puras que reciben valores y devuelven valores: ahí es natural que "falló" sea un valor que vuelve, en vez de algo que corta el flujo y te obliga a ir a ver dónde se está ejecutando. Lanzar una excepción **rompe la transparencia referencial**: la función ya no está definida solo por sus parámetros y su resultado, porque además puede interrumpir. Devolver un `Try` la deja definida en términos de parámetros y resultado, y el resultado cuenta todo lo que pasó. `Try` es la alternativa "pura" (entre comillas) al lanzado de excepciones.

## 7. 🔴 El mismo pipeline, con `Try` en lugar de `Option`

> Sobre el pipeline del mail, **cambiá todos los `Option` por `Try`: las operaciones del medio quedan iguales y solo cambia cómo se abre al final**. Si tuvieras que cambiar `if (x != null)` por `try`/`catch` en cada paso, el cambio sería mucho más disruptivo. Esta interfaz junta las dos ideas (opcionalidad y errores) en **una misma forma de trabajar**, y podés cambiar una por la otra.

Es el pipeline del Módulo 7, con las tres operaciones devolviendo `Try` porque ahora cada una puede fallar (en un worksheet):

```scala
import scala.util.{Try, Success, Failure}

case class Docente(legajo: String, mail: String)

def obtenerTitular(codigo: String): Try[Docente] =
  if (codigo == "K1") Success(Docente("1", "ana@utn.edu.ar"))
  else Failure(new RuntimeException("el servicio no responde"))

def mailDe(docente: Docente): Try[String] =
  if (docente.mail.contains("@")) Success(docente.mail)
  else Failure(new IllegalArgumentException("mail inválido"))

def mandarMailA(mail: String): Try[String] = Try(s"mail enviado a $mail")

def enviarAlTitular(codigo: String): String =
  obtenerTitular(codigo)
    .flatMap(docente => mailDe(docente))
    .flatMap(mail => mandarMailA(mail))
    .fold(error => "No se pudo mandar: " + error.getMessage, resultado => "Se mandó " + resultado)

enviarAlTitular("K1")   // Resultado: Se mandó mail enviado a ana@utn.edu.ar
enviarAlTitular("K9")   // Resultado: No se pudo mandar: el servicio no responde
```

Compará con el Módulo 7: `flatMap`, `flatMap`, `fold`. Las operaciones del medio son las mismas, y el error viaja como en la sección 2. Lo que cambió es el `fold` (dos funciones) y lo que podés decir al final: con `Option`, "no se pudo mandar"; con `Try`, "no se pudo mandar **porque** el servicio no responde". Es la excusa, que llegó hasta el final.

Esta es la gracia de que las dos cosas sean cajas con el mismo contrato: con el pipeline hecho con `if (x != null)`, pasar a errores sería reescribirlo todo con `try`/`catch`. Acá es cambiar el tipo. Lo que sabías hacer para la opcionalidad lo aplicás a los errores sin aprender otra forma de trabajar. El Módulo 10 hace el mismo cambio sobre el micro: borra el `Result` de la unidad anterior, pone `Try`, y el código de las instrucciones queda intacto.

**Para el parcial, si te preguntan:** *"¿Qué diferencia hay entre `Option` y `Try`? ¿Cuándo usarías cada uno?"* Las dos son cajas con el mismo contrato (`flatMap`, `map`), y se encadenan igual, abriendo la caja al final. `Option` representa que un valor puede faltar: `Some(valor)` o `None`, sin explicación; es mónada plus (tiene `zero`), así que tiene `filter` de verdad. `Try` representa que una operación puede fallar: `Success(valor)` o `Failure(error)`, con la excepción guardada como dato; es mónada y no mónada plus (siempre tiene algo adentro), su `filter` es un parche que produce un `Failure` inventado, y tiene operaciones propias de errores (`recover`, `fold` con dos funciones). `Option` cuando la ausencia es normal y no hace falta saber por qué (un curso sin titular); `Try` cuando algo puede salir mal y querés saber por qué (un pedido por internet). Y `Try { … }` recibe el bloque por nombre, por eso atrapa la excepción en vez de explotar.

*"¿Por qué `Try` no tiene un `filter` de verdad?"* Porque filtrar necesita poder dejar la caja vacía (`filter` se escribe con `flatMap` y `zero`), y `Try` no tiene `zero`: siempre tiene un valor o un error. El `filter` que Scala le pone devuelve un `Failure` con una excepción inventada cuando el predicado no se cumple, que después no se distingue de un error real.

---

## Checkpoint

1. ¿En qué se parece `try`/`catch` a `if (x != null)` y a `case Nil`? ¿Qué quiere decir que cada caso especial "te fuerza un patrón"?
2. ¿Qué tiene que guardar la caja para que no sea "una versión inferior a las excepciones"?
3. ¿Qué formas tiene `Try`? ¿Qué hay adentro de un `Failure`: una excepción lanzada o un dato?
4. ¿Por qué `Try { … }` recibe el bloque por nombre? ¿Qué pasaría con `Try(10 / 0)` si fuera un parámetro común?
5. ¿Qué hace `map` sobre un `Failure`? ¿Y `flatMap` cuando su función falla?
6. En `anotar`, ¿qué cambió entre la versión con excepciones y la versión con `Try`? ¿Qué quedó igual?
7. ¿Qué hace `recover`? ¿Por qué no es una operación del contrato de mónada?
8. ¿Qué se conserva de las excepciones al pasar a `Try`? ¿Qué cuesta?
9. ¿Qué puede `Try` que `Option` no puede? ¿Y al revés?
10. ¿Por qué `Try` es mónada y no mónada plus? ¿Qué consecuencia tiene eso para `filter`?
11. ¿Qué devuelve `Try(10).filter(_ > 50)`? ¿Por qué eso es un parche?
12. ¿Cómo es el `fold` de `Try`? ¿Por qué los `fold` de las tres cajas no son polimórficos entre sí, y qué operaciones sí lo son?
13. ¿Para qué existe `toOption`? ¿Qué quiere decir que "las cajas no se cruzan"?
14. ¿Qué tiene de malo devolver un código de error como `-2`?
15. ¿Qué pide `Try` del lenguaje, y qué piden las excepciones?
16. ¿Por qué lanzar una excepción rompe la transparencia referencial, y por qué devolver un `Try` la conserva? ¿Por qué eso pesa más en un lenguaje funcional?
17. En el pipeline del mail, ¿qué cambia al pasar de `Option` a `Try`? ¿Qué podés decir al final que antes no podías?

## Qué viene después

Encadenar `flatMap` tras `flatMap` tras `map` funciona, y se vuelve incómodo de leer cuando los pasos se anidan. El Módulo 9 trae la sintaxis que Scala ofrece para escribir esa secuencia como si fueran pasos de un programa: el **for comprehension**, que es azúcar sobre `flatMap`, `map` y `withFilter`, y sirve para cualquier caja: listas, `Option`, `Try`, la `Caja` del Módulo 6.

**FIN DEL MÓDULO 8 — `Try`, la caja que puede haber fallado**
