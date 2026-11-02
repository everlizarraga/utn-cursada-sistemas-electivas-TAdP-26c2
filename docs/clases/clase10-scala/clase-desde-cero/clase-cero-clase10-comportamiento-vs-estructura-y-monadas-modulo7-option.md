# Clase desde cero — Comportamiento vs estructura y mónadas — Módulo 7: `Option`, la caja que puede estar vacía

**Unidad:** clase10 · **Lenguaje:** Scala 3.3.1 · **Archivo del proyecto:** `cajas/mail/MailDelTitular.scala` (y su test, `MailTest`) · **Densidad:** 🔴 pide una sesión con el código abierto (la sección 6 es 🟡)

---

## Sobre este documento

**Qué cubre.** La primera caja de la biblioteca de Scala que resuelve un problema concreto: `Option[T]`, la caja que puede tener un valor o estar vacía, como reemplazo de `null`. El problema que la motiva (mandarle un mail al titular de un curso, cuando el curso puede no tener titular y el titular puede no tener mail), la versión con `null` y lo que tiene de malo, `Some`/`None`, el pipeline con `flatMap`/`map`, por qué `flatMap` para el mail y `map` para mandar, qué pasa en cada caso (había todo, faltó el docente, faltó el mail), abrir la caja una sola vez al final con `fold` o `getOrElse`, `Option` como tipo abstracto y por qué se le hace pattern matching lo menos posible, `find`, y el mismo pipeline con listas.

**Qué no cubre.** La caja que puede haber fallado, `Try` (Módulo 8). El `for` sobre `Option` (Módulo 9). `Try` dentro del micro (Módulo 10).

## De dónde venís

Del Módulo 6: la caja con un contenido, `unit` y `bind` (`flatMap`), `map` y `filter` derivados, mónada plus con `zero` y `plus`, y el `fold` que rompe la caja con dos caminos (`ifEmpty` por nombre). Del Módulo 5: `flatMap` contra `map`, la lista de listas; del Módulo 6, lo mismo dicho con cajas: la caja dentro de la caja. Del Módulo 2: el `case Nil` que se repetía en cada función. De la unidad anterior: `case class`, y el parámetro por nombre (`=> R`).

---

## 1. 🔴 El problema: mandarle un mail al titular

> Un curso puede no tener titular asignado todavía; un docente puede no tener mail todavía. Con `null`, cada paso del código tiene que preguntar antes de seguir, y **el chequeo depende solo de que te acuerdes**: el código que se olvida tipa igual y explota en tiempo de ejecución.

El dominio: un `Curso` tiene un código y un titular, que es un `Docente`; un `Docente` tiene legajo y mail. El pedido: *dado un curso, mandarle un mail al titular y loguear el resultado*.

```
┌───────────────────────┐      ┌────────────────────┐
│         Curso         │      │      Docente       │
├───────────────────────┤      ├────────────────────┤
│  codigo: String       │─────►│  legajo: String    │
│  titular: Docente?    │      │  mail: String?     │
└───────────────────────┘      └────────────────────┘
```

Los dos signos de pregunta son el problema. El curso recién creado puede no tener titular asignado; el docente recién ingresado puede no tener la cuenta de mail generada. Y una cosa que conviene notar desde el principio: **la ausencia viene del dominio**. El modelo está bien; en el mundo real hay cursos sin titular y docentes sin mail, y el código tiene que contemplarlo. Escribir solo el camino feliz sería fantástico, y es imposible.

La forma de resolverlo con `null` (en el proyecto, `ConNull`):

```scala
package tadp.cajas.mail

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
```

(`Log` es una clase chica del proyecto que guarda las líneas en una lista, para poder mirarlas después: `log.info` agrega `"INFO: …"`, `log.warning` agrega `"WARNING: …"`.)

Leelo paso a paso. Pido el titular: es *tal vez* un docente. Antes de pedirle el mail tengo que preguntar si es `null`. Si lo tengo, pido el mail: es *tal vez* un mail. Antes de mandar tengo que volver a preguntar. Mando: es *tal vez* un resultado. Antes de loguear, otra vez. **Paso trabado, paso trabado, paso trabado.** Y en cada `else`, la única respuesta inteligente que hay es `null`: el `null` se propaga porque en el medio del camino no hay nada mejor que decir.

Esto ya lo viste. Es el `case Nil =>` del nivel 1: antes de hacer cualquier cosa con la lista, preguntar si está vacía; si está vacía, se acabó, hay que dar una respuesta porque no hay elemento con qué trabajar. La misma incomodidad, con otro nombre. Y ya viste cuándo desapareció: en el `fold`, vos decís una sola vez qué hacer con la vacía (la semilla); en `filter` y `map`, ni eso, porque ya saben qué hacer con ella. Acá va a pasar lo mismo: `Option` tiene `map`, `flatMap` y `fold`, y la decisión vuelve a tomarse una sola vez.

Y hay dos cosas más que tiene de malo el `null`, que son las que importan:

- **La interfaz de `null` es distinta de la del objeto que reemplaza.** A un docente le mandás `mail`; a `null` no le podés mandar nada. Entonces lo que te devuelven es inservible hasta que no preguntes qué es. Es lo contrario del polimorfismo: en vez de mandar el mensaje y que el objeto responda, tenés que mirar primero.
- **Nada te obliga a chequear.** Sacá cualquiera de los `if` y el código tipa exactamente igual. El compilador no distingue "un docente" de "un docente o nada": para él, `curso.titular` es un `Docente`, punto. Que el chequeo esté o no depende de que te hayas acordado, y si te olvidaste te enterás cuando el programa explota corriendo.

Al `null` se lo conoce, por boca de quien lo inventó (Tony Hoare, 1965), como "el error de mil millones de dólares" (*billion-dollar mistake*; a veces se lo cita, mal, como "un millón"): una decisión de los años 60 que todavía cuesta errores en producción. Muchas tecnologías buscan alternativas para representar que un valor puede no estar, y esta unidad usa la que trae Scala.

> 🕳️ **Madriguera — null safety**
> Algunos lenguajes (Kotlin, Swift, TypeScript con `strictNullChecks`) distinguen en el tipo `Docente` de `Docente?`, y el compilador rechaza `titular.mail` sin un chequeo antes. Resuelve la segunda de las dos cosas malas. Scala no lo trae (hay una opción experimental, que el TP no usa).
> *Volvé al camino — vuelve en el Módulo 11, con lo que el docente opina de una y otra.*

## 2. 🔴 `Option[T]`: la ausencia, en el tipo

> `Option[T]` es una caja que tiene dos formas: `Some(valor)`, la caja con un `T` adentro, y `None`, la caja vacía. En vez de un `Docente` que puede ser `null`, el curso tiene un `Option[Docente]`: **el tipo dice que puede faltar**, y el compilador lo sabe.

```
┌────────────────────────────────────────────┐
│                 Option[T]                  │
├────────────────────────────────────────────┤
│  apply[T](value: T): Option[T]             │   unit:  Some(value)
│  empty[T]: Option[T]                       │   zero:  None
│                                            │
│  map[R](f: T => R): Option[R]              │
│  flatMap[R](f: T => Option[R]): Option[R]  │   bind
│  filter(f: T => Boolean): Option[T]        │
│  orElse(other: Option[T]): Option[T]       │   plus
│                                            │
│  fold[R](ifEmpty: => R)(f: T => R): R      │
│  getOrElse(default: T): T                  │
└────────────────────────────────────────────┘
                       △
              ┌────────┴───────────┐
              │                    │
   ┌─────────────────────┐   ┌───────────┐
   │  Some[T](value: T)  │   │   None    │
   └─────────────────────┘   └───────────┘
```

Es el contrato del Módulo 6 con los nombres de Scala, y dos operaciones más abajo que son propias de esta caja (sección 5). `None` es un objeto único, la caja vacía de los `Option`, distinto del `Nil` de las listas: cada caja tiene su propia vacía. `Some` es la caja con un elemento. `Option` entero se puede pensar como una lista de a lo sumo un elemento, y es más útil pensarlo como **una alternativa al `null`**: podrías representar "tal vez un docente" con una lista de cero o uno, pero `Option` dice la intención (acá hay a lo sumo uno, y falta o está), y por eso puede traer operaciones que en una lista no tienen sentido (sección 5).

En un worksheet:

```scala
Some(3)                              // Resultado: Some(3)
Option(3)                            // Resultado: Some(3)      unit, por el apply del compañero
Option(null)                         // Resultado: None         el apply convierte null en la caja vacía
Option.empty[Int]                    // Resultado: None
None                                 // Resultado: None

val talVez: Option[Int] = Some(3)
talVez.map(_ + 1)                    // Resultado: Some(4)
talVez.filter(_ > 5)                 // Resultado: None
talVez.flatMap(n => Some(n * 10))    // Resultado: Some(30)
(None: Option[Int]).map(_ + 1)       // Resultado: None         nadie preguntó si había algo
```

`Option(null)` es la puerta de entrada: si te llega algo de una biblioteca que todavía usa `null`, `Option(…)` lo mete en la caja correcta, y de ahí en adelante trabajás con cajas.

Lo que cambia con el tipo. Si una función devuelve `Option[Docente]` en vez de `Docente`, el lenguaje te está diciendo explícitamente "mirá, acá puede ser que no lo tengas", igual que `List[Docente]` te dice que son varios. Y hay una consecuencia que al principio molesta: **a un `Option[Docente]` le podés mandar solo mensajes de `Option`**. `titular.mail` ya no compila, porque `titular` es una caja, y una caja entiende `map`, `flatMap`, `filter`, `fold`; igual que a una `List[Docente]` le mandás `map` y `filter` y jamás `mail`. Es exactamente la restricción que `null` no tenía, y es la que te salva: el compilador te obliga a decidir qué hacer con la ausencia, porque el camino directo está cerrado.

De dónde sale esta idea. Haskell nunca tuvo `null`, así que la ausencia hubo que meterla **adentro del dato**, como forma: o estás o no estás. (De la unidad anterior: el `Result` del micro hace lo mismo con sus tres formas.) En Haskell esa caja se llama `Maybe`; `Option` es la de Scala. Tiene un costo: el dato se vuelve un poco más complejo, porque ya no tenés el titular suelto sino un contenedor con el titular. A cambio, lo tratás de forma indistinta: haya o no haya docente, el código es el mismo.

## 3. 🔴 El pipeline: `flatMap`, `map`, `fold`

> El código con `Option` es **el camino feliz, sin preguntas**: `titular.flatMap(mail).map(mandar).fold(…)`. Cada operación sabe qué hacer con la caja vacía (pasarla), y la decisión "¿había algo?" se toma una sola vez, al final: vos no preguntás, le das al `fold` los dos caminos y él elige.

El mismo dominio, con `Option` donde había `?` (en el proyecto, `ConOption`):

```scala
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
```

Cuatro pasos encadenados, y ninguna pregunta en el medio. A esto se le dice **pipeline**: una cañería, una línea de montaje por la que la caja pasa de una operación a la siguiente, y lo único que importa es lo que sale al final. Leelo como el dibujo:

```
┌───────────┐  flatMap mail  ┌──────────┐  map mandar  ┌───────────┐  fold   ┌─────────┐
│  Docente  │ ─────────────► │   Mail   │ ───────────► │ Resultado │ ──────► │  log    │
└───────────┘                └──────────┘              └───────────┘         └─────────┘
  tal vez                      tal vez                   tal vez              un valor
```

**Por qué `flatMap` para el mail y `map` para mandar.** La operación se elige por **el tipo de lo que devuelve la función que le pasás**. `docente.mail` devuelve `Option[String]`: una caja. Si usaras `map`, aplicaría la función al contenido y guardaría lo que devuelve en otra caja, y te quedaría una caja con una caja adentro. Es la lista de listas del Módulo 5, con `Option`:

```scala
import tadp.cajas.mail._
import ConOption._

val curso = Curso("K1", Some(Docente("1", Some("ana@utn.edu.ar"))))

curso.titular.map(docente => docente.mail)        // Resultado: Some(Some(ana@utn.edu.ar))   caja dentro de caja
curso.titular.flatMap(docente => docente.mail)    // Resultado: Some(ana@utn.edu.ar)
```

`mandarMailA`, en cambio, devuelve un `String` pelado: es `map`. Si mandar también pudiera no tener resultado, sería `flatMap` (sección 4). La regla es siempre la misma: la función devuelve caja → `flatMap`; devuelve valor → `map`.

**Caso por caso.** Lo que hace cada operación cuando la caja viene vacía:

```scala
val conTodo    = Curso("K1", Some(Docente("1", Some("ana@utn.edu.ar"))))
val sinTitular = Curso("K2", None)
val sinMail    = Curso("K3", Some(Docente("2", None)))

conTodo.titular                                                      // Resultado: Some(Docente(1,Some(ana@utn.edu.ar)))
conTodo.titular.flatMap(_.mail)                                      // Resultado: Some(ana@utn.edu.ar)
conTodo.titular.flatMap(_.mail).map(mandarMailA)                     // Resultado: Some(mail enviado a ana@utn.edu.ar)

sinTitular.titular                                                   // Resultado: None
sinTitular.titular.flatMap(_.mail)                                   // Resultado: None      la función del flatMap no corrió
sinTitular.titular.flatMap(_.mail).map(mandarMailA)                  // Resultado: None      la del map tampoco

sinMail.titular                                                      // Resultado: Some(Docente(2,None))
sinMail.titular.flatMap(_.mail)                                      // Resultado: None      había docente; el mail estaba vacío
sinMail.titular.flatMap(_.mail).map(mandarMailA)                     // Resultado: None
```

Había todo: el `flatMap` abrió la caja, sacó el docente, le pidió el mail, obtuvo una caja con un mail; el `map` sacó el mail, mandó, guardó el resultado. Todo eso pasó adentro. Faltó el docente: la primera caja ya estaba vacía, y las dos operaciones la pasaron tal cual, sin ejecutar su función, exactamente como `map` sobre una lista vacía no ejecuta nada. Faltó el mail: el docente estaba, el `flatMap` le pidió el mail y recibió una caja vacía, que es la que siguió viajando.

Fijate qué se fue. Lo único que hacía el código con `null` en cada `else` del medio era "si es `null`, devuelvo `null`", una vez por paso. Eso ahora lo hace la caja: una vacía entra, una vacía sale. Vos solo contás el camino feliz, y **el fallo lo maneja la estructura**.

Y el final, con el `Log`:

```scala
val log = new Log
enviarAlTitular(conTodo, log)
enviarAlTitular(sinTitular, log)
enviarAlTitular(sinMail, log)
log.lineas.toList
// Resultado: List(INFO: Se mandó mail enviado a ana@utn.edu.ar, WARNING: No se pudo Mandar, WARNING: No se pudo Mandar)
```

Tres cursos, un pipeline, y la decisión (`info` o `warning`) tomada una sola vez, en el `fold`.

Y la trampa de la compartimentalización, una vez más: `Option` tiene `isEmpty` y `get`, y podés escribir el mismo pipeline preguntando `if (titular.isEmpty)` en cada paso. Compila. Es el código con `null`, con otro nombre.

## 4. 🔴 Cuando mandar también puede no tener resultado: otro `flatMap`

> Si `mandarMailA` tampoco garantiza resultado (el mail estaba mal, se cayó la red), devuelve `Option[String]`, y el paso pasa de `map` a `flatMap`. **El resto del pipeline queda igual**, y el caso nuevo lo maneja la caja.

Mandar el mail también es un paso que puede fallar: `flatMap mail`, `flatMap mandar`. En el proyecto es `ConOptionYMandarQuePuedeFallar`, que reusa `Curso` y `Docente`:

```scala
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

```scala
val log2 = new Log
ConOptionYMandarQuePuedeFallar.enviarAlTitular(Curso("K1", Some(Docente("1", Some("ana@utn.edu.ar")))), log2)
ConOptionYMandarQuePuedeFallar.enviarAlTitular(Curso("K4", Some(Docente("3", Some("sin-arroba")))), log2)
log2.lineas.toList
// Resultado: List(INFO: Se mandó mail enviado a ana@utn.edu.ar, WARNING: No se pudo Mandar)
```

Un caso de fallo más (había docente, había mail, mandar falló) y una sola palabra cambiada en el pipeline. Compará con la versión `null`: ahí, cada paso nuevo que puede fallar es un `if` nuevo, y un lugar más donde olvidarse de preguntar.

Esto es lo que la caja compra: **podés seguir encadenando pasos todo el día** (pedí esto, transformá aquello, mandá lo otro), y cada paso sabe qué hacer si lo anterior quedó vacío. Vas de caja en caja hasta que llega el momento de bajarte.

## 5. 🔴 Abrir la caja recién al final: `fold` y `getOrElse`

> Te bajás de la caja una sola vez, cuando ya no te sirve la ambigüedad de "está o no está" y tenés que decidir. **`fold` sobre un `Option` es el catamorfismo sin el recorrido**: te da los dos caminos, qué hacer si está vacía y qué hacer con el contenido, y llega a un `R` siempre. (A este `fold` también se lo llama *continuation*: cada parámetro es "por dónde seguir" en cada uno de los dos casos.) `getOrElse` es el caso particular en que el `R` es el mismo `T`.

```
fold[R](ifEmpty: => R)(f: T => R): R
```

Leé la firma. `ifEmpty` es el valor para la caja vacía, y va **por nombre** (`=> R`): se evalúa solo si hace falta, igual que el `ifEmpty` de `Caja` en el Módulo 6, que ya viste. En el pipeline, eso es lo que hace que `log.warning(…)` no se ejecute cuando el mail se mandó: si `ifEmpty` fuera un parámetro común, el warning se escribiría siempre, antes de que `fold` decida nada. `f` es qué hacer con el contenido, y es una función mucho más simple que la de reducción de la lista: con un solo elemento no hay nada que combinar.

```scala
Some(3).fold("nada")(n => s"hay $n")                 // Resultado: hay 3
(None: Option[Int]).fold("nada")(n => s"hay $n")     // Resultado: nada
Some(3).fold(0)(_ * 2)                               // Resultado: 6
(None: Option[Int]).fold(0)(_ * 2)                   // Resultado: 0
```

Es el catamorfismo sin recorrido del Módulo 6, ahora sobre una caja de la biblioteca. Y es un ejemplo de lo que el Módulo 6 dijo con "la mónada no es una cosa": la lista y el `Option` comparten el contrato (`flatMap`, `map`, `filter`), y cada una tiene además operaciones propias de su problema. La lista tiene operaciones de conjunto (concatenar, buscar, "¿todos cumplen?"); el `Option` tiene las de "está o no está".

`getOrElse` es la más usada de esas: "dame el contenido, y si no hay, este otro valor".

```scala
Some("algo").getOrElse("por defecto")                  // Resultado: algo
(None: Option[String]).getOrElse("por defecto")        // Resultado: por defecto
```

Es un `fold` donde `f` es la identidad: `fold(default)(x => x)`. Y `default` también va por nombre, como `ifEmpty`: solo se evalúa si la caja está vacía (lo mismo vale para el `other` de `orElse`; las firmas del dibujo de la sección 2 están simplificadas). Sirve cuando lo único que querías era el valor tal como venía, y en listas tiene poco sentido ("¿`get` cuál?"). Y está `get`, que devuelve el contenido o explota:

```scala
Some(3).get                      // Resultado: 3
(None: Option[Int]).get          // Resultado: java.util.NoSuchElementException: None.get
```

⚠️ **Trampa: `get` es el `head` de `Option`.** Es parcial, y usarlo es volver a `null` con más pasos: si lo llamás sin haber preguntado `isEmpty`, explota; si preguntás antes, estás escribiendo el código de la sección 1. Casi siempre lo que querías era `getOrElse`, `fold`, o seguir en la caja con `map`.

## 6. 🟡 `Option` es un tipo como la lista, y por eso se le hace pattern matching lo menos posible

> `Option` está sujeto a las mismas reglas que cualquier otra estructura: tiene una forma (`None`/`Some`) y un tipo abstracto (`isEmpty`/`get`), y hacerle pattern matching es trabajar en el nivel 1. La diferencia con la lista es que **un `Option` tiene a lo sumo un contenido, y recorrer es cosa de conjuntos**; por eso lo que queda son las operaciones de caja.

`Option` se escribe igual que la lista en el Módulo 3: arriba la forma, abajo las operaciones:

```
Option[T]  { None    : Option[T]            ← la forma (algebraico): dos constructores
           { Some[T] : T → Option[T]
───────────────────────────────────────────
option[T]  { isEmpty : Boolean              ← el tipo abstracto: lo mínimo para operar
           { get     : T
           { ──────────
           { Some(T)                        ← los constructores, como empty y :: en la lista
           { None
```

Mismas reglas, tipos distintos: el de arriba es un tipo basado en la estructura, el de abajo es un tipo basado en un contrato. `List` tiene `Nil` y `::`, y debajo `isEmpty`, `head`, `tail`, `empty`, `::`; `Option` tiene `None` y `Some`, y debajo `isEmpty` y `get`, más `Some` y `None` como constructores. "¿Estás vacía?" hace falta para saber si "¿cuál es tu valor?" se puede preguntar; `get` es parcial como `head`. Lo que falta es `tail`: **recorrer un `Option` es una noción que no aplica**, porque iterar es propio de conjuntos y acá hay a lo sumo una cosa. Y eso muestra algo de la escalera: ningún nivel es prerrequisito del siguiente. `Option` salta de la forma a `map`, `filter` y `flatMap` sin pasar por un `fold` que recorra. Si en las tres firmas del Módulo 5 cambiás `List` por `Option`, lo que queda escrito vale sin tocar otra letra.

De ahí que hacer pattern matching sobre un `Option` (`case Some(d) => … case None => …`) sea, casi siempre, usarlo mal: es el nivel 1, con la pregunta "¿está vacía?" escrita a mano en cada lugar, que es lo que la caja vino a sacar. El Módulo 10 vuelve sobre esto con el TP en la mano; el reflejo tiene que ser `map`/`flatMap` adentro y `fold`/`getOrElse` al final.

**`Option` es mónada plus.** Tiene `zero` (`None`) y `plus`, que en Scala se llama `orElse` (en los diagramas genéricos del contrato figura como `++`, el nombre de `plus`; el mensaje de `Option` que se comporta así es `orElse`): la llena se queda con lo suyo, la vacía cede a la otra, igual que la `Caja` del Módulo 6. Y como tiene `zero`, tiene `filter` de verdad.

```scala
Some(1).orElse(Some(2))                  // Resultado: Some(1)
(None: Option[Int]).orElse(Some(2))      // Resultado: Some(2)
Some(3).filter(_ > 2)                    // Resultado: Some(3)
Some(3).filter(_ > 5)                    // Resultado: None      filter necesita zero, y Option lo tiene
```

**Una interfaz que mejora con `Option`: `find`.** `find` busca el primer elemento de una lista que cumple una condición. En muchos lenguajes devuelve el elemento o `null`, y lo primero que tenés que hacer con lo que te devolvió es preguntar qué es, porque el elemento y `null` tienen interfaces distintas. En Scala devuelve `Option`, y podés seguir trabajando sobre el resultado con `map`, `filter` y `flatMap` como si siguiera siendo una lista, sin saber si encontró algo:

```scala
List(1, 2, 3).find(_ > 1)                           // Resultado: Some(2)
List(1, 2, 3).find(_ > 5)                           // Resultado: None
List(1, 2, 3).find(_ > 1).map(_ * 10).getOrElse(0)  // Resultado: 20
List(1, 2, 3).find(_ > 5).map(_ * 10).getOrElse(0)  // Resultado: 0
```

Hay muchas interfaces que mejoran así. Una la dejaste pendiente en el Módulo 3: `head` lanza sobre la vacía porque es parcial a propósito. La otra forma de diseñarla es esta, y Scala la trae al lado: `headOption` devuelve `Some(cabeza)` o `None`, y con eso seguís en la caja en vez de proteger con `isEmpty`.

```scala
List(1, 2, 3).headOption                    // Resultado: Some(1)
List.empty[Int].headOption                  // Resultado: None
List.empty[Int].headOption.getOrElse(0)     // Resultado: 0
```

Toda función que "a veces no tiene respuesta" (buscar, la cabeza, parsear un número) se vuelve más honesta devolviendo `Option`, porque el tipo cuenta lo que puede pasar.

## 7. 🔴 El mismo pipeline, con listas

> Lo que hiciste con `Option` **funciona exactamente igual, con el mismo código**, si en vez de tal vez un docente tenés muchos docentes, cada uno con muchos mails, y muchos resultados. Lo que cambia es la caja de abajo; la forma de pensar la secuencia es la misma.

Si en lugar de un curso con tal vez un titular tenés un conjunto de docentes, y cada docente puede tener varios mails, y querés mandarles a todos:

```scala
case class DocenteConMails(legajo: String, mails: List[String])

val docentes = List(
  DocenteConMails("1", List("ana@utn.edu.ar", "ana@gmail.com")),
  DocenteConMails("2", List()),
  DocenteConMails("3", List("bo@utn.edu.ar"))
)

docentes
  .flatMap(docente => docente.mails)
  .map(mail => mandarMailA(mail))
// Resultado: List(mail enviado a ana@utn.edu.ar, mail enviado a ana@gmail.com, mail enviado a bo@utn.edu.ar)
```

`flatMap` para los mails (cada docente devuelve una caja: una lista), `map` para mandar (cada mail devuelve un valor). Es el pipeline de la sección 3, letra por letra, y el docente sin mails desapareció solo, como el `None` de antes. El concepto es el mismo: *tengo un contenedor de algo, opero sobre el contenido, espero que todo esté bien, y el fallo lo maneja la estructura*. Se traslada porque la operación es la misma.

Lo que sí cambia es **cómo se abre la caja al final**. Con `Option`, `fold` da dos caminos. Con una lista de resultados, "abrirla" es otra cosa (reducirla, recorrerla, contarla), y el `fold` de la lista es el del Módulo 4, con semilla y combinación. Las operaciones del medio (`flatMap`, `map`) son idénticas; la última, la que te baja de la caja, es la que depende de qué caja era. El Módulo 8 trae una tercera caja y la misma observación.

**Para el parcial, si te preguntan:** *"¿Qué problema resuelve `Option` y cómo?"* El de un valor que puede no estar. Con `null`, cada paso tiene que preguntar antes de seguir y nada obliga a preguntar: el código sin el chequeo tipa igual y explota al correr. `Option[T]` pone la ausencia en el tipo (`Some(valor)` o `None`), con lo que el compilador sabe que puede faltar y cierra el camino directo (`titular.mail` ya no compila). Las operaciones se encadenan con `flatMap` (cuando la función devuelve `Option`) y `map` (cuando devuelve un valor), cada una sabe pasar la caja vacía, y la decisión se toma una sola vez, al final, dándole a `fold` los dos caminos (o a `getOrElse` un valor por defecto), sin preguntar nunca `isEmpty`.

*"¿Por qué conviene evitar el pattern matching sobre `Option`?"* Porque es volver al nivel de la forma: escribir a mano "¿está vacía?" en cada lugar es lo que la caja vino a sacar. Con `map`/`flatMap` adentro y `fold`/`getOrElse` al final, la pregunta se hace una vez; y el mismo código sirve para otra caja (una lista, o la del Módulo 8), cosa que el `match` sobre `Some`/`None` pierde.

---

## Checkpoint

1. ¿Por qué la ausencia del mail o del titular "viene del dominio"? ¿Qué quiere decir eso para el código que la maneja?
2. ¿Cuáles son las dos cosas malas del `null`, más allá de la incomodidad de preguntar?
3. ¿Qué le podés mandar a un `Option[Docente]`? ¿Por qué `titular.mail` ya no compila, y por qué eso es bueno?
4. ¿Qué da `Option(null)`? ¿Para qué sirve?
5. En el pipeline, ¿por qué `flatMap` para el mail y `map` para mandar? ¿Cómo decidís cuál usar?
6. Describí qué pasa, paso a paso, cuando el curso no tiene titular. ¿Y cuando el docente no tiene mail?
7. Si mandar el mail también puede fallar, ¿qué cambia en el pipeline? ¿Y en la versión con `null`?
8. ¿Por qué `ifEmpty` va por nombre? ¿Qué pasaría en el pipeline si fuera un parámetro común?
9. ¿En qué se parece y en qué se diferencia el `fold` de `Option` del `fold` de la lista?
10. ¿Qué relación hay entre `getOrElse` y `fold`? ¿Y entre `get` y `head`?
11. ¿Qué tienen en común `List` y `Option` como tipos? ¿Qué le falta a `Option` y qué consecuencia tiene?
12. ¿Qué hace `orElse`? ¿Qué rol cumple en el contrato de mónada plus, y qué tiene que ver con que `Option` tenga `filter`?
13. ¿Por qué `find` y `headOption` mejoran devolviendo `Option`?
14. Con muchos docentes y muchos mails, ¿qué parte del pipeline queda igual y qué parte cambia?

## Qué viene después

`Option` dice que algo falta, y nada más. El Módulo 8 trae la caja para cuando algo **puede salir mal y querés saber por qué**: `Try`, con `Success` y `Failure(error)`, para el caso en que pedir el docente es un pedido por internet que puede explotar. Es la misma forma de trabajar, con una diferencia que importa: `Try` no puede estar vacío, y eso le cuesta el `filter`.

**FIN DEL MÓDULO 7 — `Option`, la caja que puede estar vacía**
