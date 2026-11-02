# Clase desde cero — Comportamiento vs estructura y mónadas — Módulo 11: El gran elenco

**Unidad:** clase10 · **Lenguaje:** Scala 3.3.1 · **Archivo del proyecto:** `cajas/futuros/SecuencialVsParalelo.scala` (y su test, `FuturosTest`) · **Densidad:** 🟡 se lee de corrido; las secciones 1, 4, 6 y 8 son 🔴 y piden el worksheet al lado

---

## Sobre este documento

**Qué cubre.** Las mismas operaciones (`map`, `flatMap`, `for`) sobre cosas que no son errores ni ausencias, y lo que eso enseña. `Future`, la caja de lo que todavía no está; el `then` de JavaScript y `async/await` como la misma idea; una lista de futuros convertida en un futuro de lista; el `for` secuencial contra el paralelo, con las cajas creadas adentro o antes del `for`; por qué `Future` es ansioso y se discute si es mónada; IO y la transparencia referencial, que es el problema con el que se inventaron las mónadas; `Either`, State, transformadores, functor aplicativo y categorías, nombrados; las cajas no se cruzan; funcional construye conceptos en espacios distintos, y parecerse a veces es más problema que ayuda; y null safety contra `Option`.

**Qué no cubre.** Cómo se implementa cada una de estas cajas, ni cómo se usan en serio. Se nombran para que sepas que existen y qué problema resuelve cada una; lo que el TP pide está en los módulos 7, 8 y 10.

## De dónde venís

Del Módulo 6: la mónada como contrato (`unit`, `bind`, las leyes), "no es una cosa, es una idea", y que una propiedad vale más que una prueba. Del Módulo 8: `Try`, `recover`, y que las cajas no se cruzan (`toOption`); la madriguera sobre si `Try` es mónada "pura". Del Módulo 9: un `for` es una secuencia, cada caja se pide cuando la anterior respondió. Del Módulo 7: la madriguera sobre null safety. Del Módulo 4: lo que se puede foldear (`Foldable`: listas, sets, árboles, cajas) y el monoide.

---

## 1. 🔴 `Future`: la caja de lo que todavía no está

> Pedir el docente **tarda**, y no querés frenar todo el sistema mientras llega. Lo disparás, el resto del programa sigue, y "cuando llegue el docente, recién ahí pedile el mail; cuando llegue el mail, recién ahí mandalo". Eso es otra caja: una que tiene un valor **que todavía no está**, y que te deja encadenarle cosas para cuando esté. Si contesta a `flatMap`, el mismo camino del mail sirve.

Volvé al pipeline del mail por tercera vez, y cambiá otra cosa. Obtener el docente, obtener el mail y mandar el mail ya no son operaciones que puedan faltar (Módulo 7) ni que puedan fallar (Módulo 8): son operaciones que **tardan**. Pido el docente a un servicio, y eso demora un rato. No quiero que todo mi programa se trabe esperando; quiero disparar el pedido en algún lado, que el resto siga, y que cuando el docente llegue, recién ahí se le pida el mail, y cuando el mail llegue, recién ahí se mande.

Pensalo como caja: una abstracción que te deja decir "hacé esta operación, y cuando termine, dejame encadenarle cosas". Es un valor que va a estar disponible en algún momento, y mientras tanto necesitás seguir operando sin tenerlo. Si esa caja contesta a `flatMap`, el caminito que definiste para el mail sirve para resolver el asincronismo también. A eso se lo llama **`Future`**.

Tres cosas nuevas en el bloque que sigue: `Future { … }` dispara el bloque en otro hilo y devuelve la caja enseguida; el `import` del `ExecutionContext` dice quién corre los futuros; y `Await.result(caja, 5.seconds)` espera hasta cinco segundos y abre la caja, solo para el worksheet.

```scala
import scala.concurrent.{Future, Await}
import scala.concurrent.duration._
import scala.concurrent.ExecutionContext.Implicits.global

val f = Future { 21 * 2 }                                  // se dispara ya, en otro hilo
Await.result(f.map(_ + 1), 5.seconds)                      // Resultado: 43
Await.result(Future(10).flatMap(n => Future(n * 2)), 5.seconds)   // Resultado: 20

val falla = Future { 10 / 0 }
Await.result(falla.recover { case _: ArithmeticException => -1 }, 5.seconds)   // Resultado: -1
```

`Future { … }` recibe un bloque (por nombre, como `Try`), lo manda a ejecutar en otro hilo (eso es el `ExecutionContext` importado: quién corre los futuros) y te devuelve la caja enseguida, vacía todavía. `map` y `flatMap` son los de siempre: "cuando tengas el valor, hacé esto"; también corren en el ejecutor (por eso el `import` de arriba vale para todo el worksheet, `Future.sequence` incluido). Y `Future` también guarda el fallo, como `Try`: si el bloque explota, la caja queda fallida y `recover` la recupera. `Await.result` es la forma de **esperar y abrir** la caja; sirve en un worksheet o en un test, y en un programa de verdad casi nunca, porque bloquear es lo que querías evitar.

Y acá se ve de nuevo lo que es una mónada: una estructura que contiene valores, que te interesa por los valores que contiene, y que tiene la capacidad de **operarse en secuencia**. Esa capacidad importa mucho más en funcional que en objetos, por una razón que aparece en la sección 6.

## 2. 🟡 El `then` de JavaScript y `async/await`: lo mismo con otros nombres

> La **promesa** de JavaScript es la contracara del `Future`. Su `then` es **un `map` y un `flatMap` juntos**: si tu función devuelve una promesa, la abre; si devuelve otra cosa, la envuelve. Y `async/await` es azúcar sobre `then`, como el `for` es azúcar sobre `flatMap`: cada línea debajo de un `await` se convierte en una función pasada al `then` anterior.

Si trabajaste en JavaScript, conocés la promesa: una construcción muy parecida al `Future`. Su `then` recibe una función, y hace cosas distintas según qué devuelve esa función: si devuelve una promesa, trabaja como `flatMap` (la abre y te deja el contenido); si devuelve cualquier otra cosa, la envuelve en una promesa, como `map`. Mezcla las dos operaciones en una sola, sin una firma única y prolija, y la idea es la misma. Scala no tiene un `then`: tiene `map` y `flatMap` separados, cada uno con su firma, y el `for` encima. Por eso la promesa de JavaScript no es una mónada (no hay un `bind` con una firma única), mientras que en Haskell y en Scala las interfaces parecidas sí están armadas sobre el contrato. Y una cosa que confunde: el `then` **se llama ahora**, en el momento en que lo escribís; lo que queda para después es la función que le pasaste.

Y `async/await` es exactamente lo que el `for` es para `flatMap`: una reescritura directa. **Todo lo que hacés con `async/await` lo podés hacer con promesas**; es la misma cosa, más cómoda de escribir. Lo que hay que saber, y es donde es más fácil confundirse, es que cada línea que tenés debajo de un `await` **no se ejecuta hasta que el `await` se resuelve**, porque esa línea se termina convirtiendo en una función que se pasa por parámetro al `then` del paso anterior. Es la secuencia del Módulo 9, con otra sintaxis. Por eso conviene aprender primero el `then` (y el `catch`) y después el `async/await`: para saber a qué se convierte, y no aprenderlo como dos cosas distintas cuando en el fondo es lo mismo.

> 🕳️ **Madriguera — `await 7` y devolver una promesa**
> JavaScript tiene parches: `await 7` funciona (espera el 7, listo), y devolver una promesa desde una función `async` es lo mismo que devolver el contenido si ya lo tenés. Son lugares donde la intuición de caja se vuelve turbia, porque la caja se abre y se cierra sola.
> *Volvé al camino — esto se profundiza aparte, otro día.*

## 3. 🟡 Una lista de futuros, un futuro de lista

> Pediste el docente 1 y el docente 2: tenés una **lista de dos cosas que van a resolverse en el futuro**, que es incómoda. Lo que querés es **una sola cosa que se resuelve en el futuro y adentro tiene la lista**. Pasar de una a la otra ya está hecho, y para cualquier caja: un recorrible de mónadas se convierte en una mónada de recorribles.

```
  [F(docente1), F(docente2)]
 ↳ F([docente1, docente2])
```

Es un problema que seguro tuviste con promesas: pedís varias cosas, cada una llega cuando llega, y te queda una lista de futuros. Trabajar eso es complicado: cada elemento tiene su propia caja. Lo sano es tener un solo futuro que, cuando termine, tenga adentro la lista plana con todos los docentes. En JavaScript eso es `Promise.all`; en Scala es `Future.sequence`:

```scala
val futuros: List[Future[Int]] = List(Future(1), Future(2), Future(3))
Await.result(Future.sequence(futuros), 5.seconds)          // Resultado: List(1, 2, 3)
```

(En el proyecto, `Secuencia.todosJuntos` es exactamente eso, con el dibujo en el comentario.)

Y acá está la parte importante. Esa operación está **generalizada**: lo de afuera no tiene por qué ser una lista (es algo recorrible, lo del Módulo 4, con un requisito más: que se pueda volver a armar con el mismo molde, para que adentro de la caja quede la misma estructura; en Haskell esa operación se llama `sequence`, y su hermana con una función en el medio, `traverse`), y lo de adentro no tiene por qué ser un `Future` (es una mónada). Hay una función que agarra "un recorrible de mónadas" y te devuelve "una mónada de recorribles", medio mágicamente, porque los tipos encajan. Alguien la escribió alguna vez para un tipo, probablemente IO, y por usar las mismas interfaces sirve para cualquiera que respete el contrato. **Todo lo que alguna vez pensaste armar para una caja te funciona para todas.** Esa es la ganancia de trabajar con el contrato: y el precio, que tenés que entender el concepto y trabajarlo de forma genérica.

## 4. 🔴 El `for` secuencial contra el paralelo

> La mónada **secuencia**, y la gracia del futuro es **no secuenciar**: trabajar en paralelo. Si escribís `x <- estaCaja(); y <- otraCaja()` adentro de un `for`, la segunda caja se pide recién cuando la primera respondió. Si querés que corran a la vez, las creás **antes** del `for`. Los dos códigos compilan, dan el mismo valor, y se comportan de forma aberrantemente distinta.

Este es el error que comete mucha gente, y vale la pena verlo con código. Dos cajas que tardan 200 ms cada una y anotan cuándo empiezan y terminan (en el proyecto, `Cajas`; `ListBuffer` es una lista mutable, `synchronized` evita que dos hilos anoten a la vez, y `blocking { … }` le avisa al ejecutor que ese hilo va a esperar; la trampa de más abajo dice por qué hace falta):

```scala
package tadp.cajas.futuros

import scala.collection.mutable.ListBuffer
import scala.concurrent.{Future, blocking}
import scala.concurrent.ExecutionContext.Implicits.global

class Cajas(demoraMs: Long) {
  val eventos: ListBuffer[String] = ListBuffer()

  private def anotar(evento: String): Unit = eventos.synchronized { eventos += evento }

  def estaCaja(): Future[Int] = Future {
    anotar("empieza estaCaja")
    blocking { Thread.sleep(demoraMs) }   // avisa al ejecutor que este hilo espera (ver la trampa)
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
```

Las dos sumas devuelven `3`. Mirá los eventos:

```scala
import tadp.cajas.futuros._

val c1 = new Cajas(200)
Await.result(c1.sumaSecuencial(), 5.seconds)               // Resultado: 3
c1.eventos.toList
// Resultado: List(empieza estaCaja, termina estaCaja, empieza otraCaja, termina otraCaja)     ~400 ms

val c2 = new Cajas(200)
Await.result(c2.sumaEnParalelo(), 5.seconds)               // Resultado: 3
c2.eventos.toList
// Resultado: List(empieza estaCaja, empieza otraCaja, termina estaCaja, termina otraCaja)     ~200 ms
```

En `sumaSecuencial`, `otraCaja()` **se llama adentro del `flatMap` de `estaCaja()`**: es la secuencia del Módulo 9, la expresión de cada `<-` se evalúa recién cuando la caja anterior entregó algo. La segunda caja ni siquiera existe hasta que la primera terminó. Son 400 ms. En `sumaEnParalelo`, las dos cajas se crearon antes, las dos ya están corriendo, y el `for` solo las espera: 200 ms.

Con listas o con `Option` (y con `Try`, mientras el bloque sea puro), mover afuera del `for` una expresión que no usa lo que sacaste antes es un cambio válido y da lo mismo. Acá no, porque **construir la caja produce efecto**: dispara el cómputo. Y es difícil de detectar: el razonamiento de por qué está mal cuesta seguirlo, en el código se te escapa rápido, y en tu máquina, con la base de datos local, todo corre bien; explota en producción, con la base del otro lado del mundo, y las cosas tardan minutos sin que sepas por qué.

⚠️ **Trampa: si te da lo mismo, mirá el ejecutor.** Con un solo hilo disponible, las dos versiones tardan 400 ms y los eventos salen en el mismo orden, porque no hay con qué correr dos cajas a la vez. Por eso el código del proyecto usa `blocking { … }` alrededor del `sleep`: le avisa al ejecutor que ese hilo está esperando y que puede prestar otro. Sin eso, en una máquina de un solo núcleo el test del paralelo falla, y no por el `for`.

Y la vuelta de tuerca, que es lo que importa de verdad. Alguien ve estos dos códigos, se enoja ("¡yo quiero que sea lo mismo!"), y te implementa un `for` donde las dos formas se comportan igual. Ahora vos te quedaste con la regla "adentro de la flecha está mal, afuera está bien", y con su herramienta esa regla es falsa. Eso son **los distintos niveles de abstracción por los que vas saltando**: una forma no es superior a la otra; con las reglas que hay ahora, esto trabaja de una manera distinta, y **si no sabés qué pasa por abajo, para vos es magia**: estás rezando una cosa en vez de la otra sin saber por qué.

## 5. 🟡 `Future` es ansioso, y por eso se discute si es mónada

> `Future` empieza a correr **en el momento en que lo creás**, sin que nadie le pida el valor. Eso rompe la transparencia referencial (crear la caja ya produjo un efecto), y por eso **no es exactamente una mónada**: una de las reglas que las mónadas tienen que cumplir no aplica. La intuición sirve igual; el nombre, con asterisco.

```scala
val eventos = scala.collection.mutable.ListBuffer[String]()
val fut = Future { eventos += "corrió"; 1 }
Thread.sleep(100)
eventos.toList                                             // Resultado: List(corrió)     nadie le pidió nada
```

En funcional siempre tenés que poder reemplazar una expresión por su resultado. Con `Future`, en el momento en que lo instanciaste ya se empezó a correr la lógica: la expresión `Future { … }` y su resultado no son intercambiables, porque la primera **hace** algo. Es una discusión parecida a la de la madriguera del Módulo 8 sobre `Try`, y más de fondo: `Try` tenía problemas con una de las tres leyes (la identidad izquierda, cuando la función lanza), y `Future` hereda ese mismo problema; pero además rompe la regla anterior a las leyes, la que hace falta para siquiera escribirlas: que `Future { … }` y su resultado sean intercambiables. Cumple el contrato por los nombres (`map`, `flatMap`, `for`); matemáticamente no es una de estas cosas; la intuición de caja te sirve para trabajarlo, y hay que saber que es un parecido, no una igualdad. Y acá vuelve lo que el Módulo 6 dijo de las leyes: no alcanza con que las funciones estén; tienen que cumplir las reglas. Cuando no las cumplen, el mismo código escrito de dos maneras que para una lista son equivalentes deja de serlo: eso fue la sección 4.

## 6. 🔴 IO y la transparencia referencial: el problema con el que se inventaron las mónadas

> Funcional se reserva el derecho de saltear una expresión cuyo resultado ya conoce (transparencia referencial); objetos garantiza que todo lo escrito se ejecuta, y en orden. Para lo que **tiene que** ejecutarse, y en orden, Haskell armó la mónada **IO**: ese es el problema que las mónadas vinieron a resolver.

Esta es la razón de fondo por la que secuenciar importa tanto en funcional. Objetos es más procedural: asume que las cosas se hacen como fueron descriptas, y garantiza que todo el código que escribís se ejecuta. Funcional no lo garantiza, de forma intencional: habrás escuchado que un compilador o un motor de funcional puede elegir **no ejecutar un cacho de código porque ya tiene el resultado**. A eso le decimos transparencia referencial: cualquier expresión se puede reemplazar por su resultado, porque la gracia es ir de un dominio a una imagen.

Ahora, si *pagarle a mis empleados* es una función que devuelve "ok" cuando terminó de pagar, la segunda vez que la llamo el sistema me dice "esto va a dar ok", y nunca les paga. Eso es un problema. Había que encontrar una manera de garantizar, de explicar de alguna forma, que hay cosas que se van por afuera de lo que entendemos como pureza, que **necesitan ejecutarse, y ejecutarse en orden**.

Esa es la mónada **IO**, la de entrada y salida: la puerta de atrás por la que se esconden los efectos en funcional. Cuando encadenás `io.flatMap(operación).flatMap(operación)` (o el `for` equivalente), la mónada te garantiza que cada operación se ejecuta, y en ese orden; `map` solo transforma lo que la acción anterior produjo. Y además te deja hacer lo que en Paradigmas no viste cómo hacer: obtener un número al azar, escribir por consola, grabar un archivo, hacer un pedido por internet: todo lo que representa interacción con el mundo, que está afuera del sistema funcional, pasa por IO. Si querés hacer un sistema de verdad en Haskell, una de las primeras cosas que aprendés es esta mónada: siempre que veas un sistema funcional haciendo algo que no parece funcional, es ella.

Y es **el problema por el que las mónadas entraron a la programación**: la idea ya existía en matemática, y Haskell, que es un lenguaje puro, la tomó para resolver esto. De ahí saltó "¿y si modelamos la idea de secuenciar?", y lo demás (listas, `Option`, `Try`, `Future`) son la misma idea aplicada a otros problemas.

## 7. 🟡 Los demás: `Either`, State, transformadores, y lo que hay más allá

> Hay muchísimas mónadas más. Las que conviene tener oídas: **`Either`** (izquierda o derecha: lo que Haskell usa en lugar de `Try`), **State** (acumular estado sin mutar), los **transformadores** (para combinar dos cajas, porque las cajas no se cruzan), y un pariente que pide menos que la mónada, el **functor aplicativo**, que es lo que de verdad sirve para lo paralelo.

**`Either`.** El `Try` de Scala no lo vas a encontrar en Haskell, porque Haskell usa su generalización: `Either`, una caja que es "o la izquierda o la derecha", o `A` o `B`. Representa un cómputo que puede dar uno u otro resultado, y vos encadenás operaciones como si tuvieras el que te interesa, sin chequear en cuál estás; llegado cierto punto, frenás y mirás. La convención es el error a la izquierda y el valor a la derecha, y en Scala eso está en la caja misma: `map`, `flatMap` y el `for` trabajan sobre `Right` y pasan el `Left` sin tocarlo (en los resultados de abajo, `mal` viaja intacto). Uno arma su propio tipo de error en vez de usar excepciones; visto así, `Try[T]` es un `Either[Throwable, T]` con operaciones de excepciones encima. Scala también lo tiene:

```scala
val bien: Either[String, Int] = Right(10)
val mal: Either[String, Int]  = Left("sin docente")

bien.map(_ * 2)                                            // Resultado: Right(20)
mal.map(_ * 2)                                             // Resultado: Left(sin docente)
for { a <- bien; b <- bien } yield a + b                   // Resultado: Right(20)
mal.fold(err => s"error: $err", v => s"valor $v")          // Resultado: error: sin docente
```

**State.** La forma en que funcional mantiene un estado que se acumula a lo largo de un programa, sin mutar nada: la caja no guarda el estado, guarda **un paso** que recibe el estado actual y devuelve el resultado junto con el estado siguiente, y `flatMap` enhebra los pasos pasando el estado de uno al otro; el estado inicial se le da al final, al correr todo. Es, en el fondo, lo que el `foldLeft` del micro venía haciendo a mano con el micro de instrucción en instrucción.

**Las cajas no se cruzan: combinadores y transformadores.** La mónada siempre trabaja de la misma caja a la misma caja: de lista en lista, de `Option` en `Option`, de `State` en `State`. A las cajas no les gusta mezclarse (Módulo 8: por eso existe `toOption`). ¿Y si querés algo opcional que además puede fallar, o un futuro de un `Try`? O metés una caja adentro de otra y vivís con eso, o usás **transformadores de mónadas**, que combinan las propiedades de dos mónadas en una sola. Hay combinadores, transformadores, una teoría entera: muy interesante y muy pesada; queda nombrada.

**Lo que hay alrededor.** La mónada es un contrato entre varios; uno ya lo conocés, el monoide del Módulo 4, que pide otras cosas (una operación asociativa con neutro) y sirve para otro problema. Y hay un pariente directo de la mónada que **pide menos**: el **functor aplicativo**. Toda mónada lo es; al revés no. Lo que la mónada agrega es `flatMap`, que el paso siguiente use el resultado del anterior; eso es lo que secuencia. El aplicativo solo sabe combinar cajas que no dependen entre sí ("hacé esta y esta otra, y dame una caja con las dos"), y por eso es lo que de verdad sirve para lo **paralelo**: como ningún paso espera al anterior, no hay nada que serializar. Si tenés operaciones que querés correr a la vez, lo más probable es que termines usando eso, que ya no se piensa como una secuencia. Y la idea que contiene a todas estas: las **categorías**, la matemática detrás, con muchos años de estudio y muchas definiciones. Es la madriguera más grande de todas, y hay una puerta ahí para quien quiera cruzarla.

## 8. 🔴 Espacios distintos, y parecerse no siempre ayuda

> Funcional construye conceptos **en espacios de trabajo diferentes**: el functor aplicativo no es "la mónada, mejorada"; es otra herramienta, corrida a otro lugar, para otro propósito (combinar sin secuenciar). Por eso en funcional la respuesta no es obvia como en objetos ("agarrá el objeto y mandale el mensaje"): hay que entender qué garantiza cada herramienta. Y por eso hay que conocer la mónada **por la mónada en sí**: aunque haya una solución mejor para tu problema, sin entenderla no podés ver la diferencia ni el precio.

Juntá la sección 4 (el `for` que serializa), la 5 (`Future` que se parece y no es) y la 7 (el functor aplicativo para lo paralelo). Lo que muestran es esto: en funcional, cada vez que encarás un problema distinto, la pregunta "¿qué herramienta uso?" no tiene la respuesta automática de objetos. Depende de qué quieras hacer, qué nivel de expresión necesitás, y hace falta tomar un poco de sopa para entender de dónde viene la operación, qué garantiza, qué características tiene. Es una forma de pensar distinta; cuando la conocés, hay problemas que se resuelven solos.

Y hay una costumbre que juega en contra: en ingeniería tendemos a encarar esto problema por problema. Aprendiste `map` y `filter`, y los aprendiste en listas; sabés usar listas. Futuros no usaste nunca, y usar un futuro no es tan distinto: lo que hace falta es saber generalizar, que es lo que toda esta unidad vino haciendo desde el nivel 1.

Y una advertencia que atraviesa toda la unidad: **que algo se parezca a otra cosa, a veces, es más problema que ayuda.** `Future` se parece a una mónada; `then` se parece a `flatMap`; el `for` sobre futuros se parece al `for` sobre listas. Si solo te quedás con el parecido, aplicás la regla equivocada en el lugar equivocado y no sabés por qué falló.

> 🕳️ **Madriguera — React y "envolvé todo con esta función"**
> Pasa todo el tiempo con cosas menos teóricas que esto. En algún momento, en React, se recomendaba envolver todos los componentes con una función que los "hace puros", y la gente lo repetía en todos lados sin saber qué hacía; después "eso no funciona en este componente", y "pero a mí me dijeron que hay que hacerlo siempre". Estar repitiendo una regla sin entenderla es correr detrás de un auto como un perro: no sabés qué hacer si lo agarrás, ni qué pasa cuando la herramienta cambia y vos te quedaste con la idea vieja.
> *Volvé al camino — esto se profundiza aparte, otro día.*

⚠️ **Criterio: null safety contra `Option`.** Funcional no es solo funciones e inmutabilidad: es toda una forma de construir abstracciones, de la que esta unidad mostró una. Integrar objetos con esas abstracciones es, a veces, la forma de resolver un problema; y a veces la propuesta de funcional, con todo lo interesante que es, se queda atrás de la alternativa que objetos ya tenía. La mónada no es una idea *mejor* que otras soluciones al mismo problema. Para la opcionalidad, un **null safety** bien implementado (la madriguera del Módulo 7: el tipo distingue `Docente` de `Docente?` y el compilador te obliga a chequear) es, para el docente de la materia, una solución mejor que `Option`: más limpia, menos costosa. Pero si no entendés cómo trabaja la mónada, es muy difícil entender la diferencia entre una y otra, el precio que se paga por cada una, o qué hacer cuando trabajás en un contexto donde tenés solo una. Y Scala no lo trae: está parado sobre Java, donde cualquier referencia puede ser `null`, y agregárselo a un lenguaje ya hecho es rehacer el sistema de tipos (la opción experimental de Scala 3 que el Módulo 7 nombró es eso a medio camino, y el TP no la usa; Kotlin lo trajo de nacimiento). El TP es en Scala: hay que adecuarse a este mecanismo. Si en un parcial aparece "¿`Option` o null safety?", la respuesta no es cuál es mejor, sino qué garantiza cada uno y qué cuesta.

**Para el parcial, si te preguntan:** *"¿Qué diferencia hay entre crear los futuros adentro o antes de un `for`?"* Un `for` es `flatMap` anidado, y la expresión de cada `<-` se evalúa adentro de la función del `flatMap` anterior, o sea, cuando la caja anterior ya respondió. Si los futuros se crean adentro del `for`, el segundo se dispara recién cuando terminó el primero: quedan serializados, y el tiempo total es la suma. Si se crean antes, los dos ya están corriendo cuando el `for` empieza, y el `for` solo los espera: corren en paralelo. Las dos versiones compilan y dan el mismo valor; difieren porque crear un `Future` produce efecto (dispara el cómputo), así que mover la expresión afuera no es el cambio inocente que sería con una lista o un `Option`.

*"¿Qué es la mónada IO y por qué se inventaron las mónadas?"* En funcional, por transparencia referencial, una expresión se puede reemplazar por su resultado, y el motor puede elegir no ejecutar código del que ya conoce el resultado: pagar dos veces paga una. Para las cosas que tienen que ejecutarse, y en orden (escribir, leer, pedir por red, un número al azar), Haskell tomó la mónada de la matemática y con ella armó IO, que garantiza que cada operación encadenada se ejecuta en secuencia. Ese fue el problema original; las demás mónadas son la misma idea de secuenciar, aplicada a la ausencia, el error, la demora.

---

## Checkpoint

1. ¿Qué problema resuelve `Future`? ¿Por qué el mismo pipeline del mail sirve?
2. ¿Qué hace el `then` de JavaScript, y por qué es "un `map` y un `flatMap` juntos"? ¿Qué relación tiene `async/await` con el `for`?
3. ¿Qué es más cómodo de trabajar: una lista de futuros o un futuro de lista? ¿Qué operación pasa de una a la otra, y por qué sirve para cualquier caja?
4. Escribí el `for` que serializa dos futuros y el que los corre en paralelo. ¿Por qué difieren, si la única diferencia es dónde se crean las cajas?
5. ¿Por qué mover una expresión afuera del `for` es un cambio válido con listas y no con futuros?
6. Si las dos versiones tardan lo mismo, ¿qué tenés que mirar? ¿Para qué está el `blocking`?
7. ¿Qué pasa si alguien implementa un `for` donde las dos formas se comportan igual? ¿Qué enseña eso sobre los niveles de abstracción?
8. ¿Qué quiere decir que `Future` es "ansioso"? ¿Qué regla rompe, y por qué por eso se discute si es mónada?
9. ¿Qué garantiza objetos que funcional no garantiza? ¿Qué es la transparencia referencial, y qué pasa con "pagarle a los empleados"?
10. ¿Qué es la mónada IO? ¿Por qué se dice que las mónadas se inventaron para eso?
11. ¿Qué es `Either`? ¿Qué relación tiene con `Try`?
12. ¿Qué quiere decir que las cajas no se cruzan? ¿Qué dos salidas hay cuando necesitás combinar dos?
13. ¿Qué pide un functor aplicativo que la mónada también pide, y qué le falta? ¿Por qué justamente eso lo hace servir para lo paralelo?
14. ¿Por qué "parecerse a veces es más problema que ayuda"? Dá dos ejemplos de la unidad.
15. ¿Qué opina el docente sobre null safety contra `Option`? ¿Por qué igual hay que entender la mónada?

## Qué viene después

Con esto la unidad termina. Lo que sigue es el TP, con las herramientas de los módulos 7, 8 y 10, y más adelante una clase bonus sobre cómo otras tecnologías resuelven algunas de estas cosas. Si querés el mapa de toda la unidad (qué módulo cierra qué, de dónde salió cada cosa), está en el roadmap.

**FIN DEL MÓDULO 11 — El gran elenco**
