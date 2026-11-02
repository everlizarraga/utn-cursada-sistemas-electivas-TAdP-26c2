# Clase desde cero — Comportamiento vs estructura y mónadas — Módulo 9: For comprehension, el azúcar de la caja

**Unidad:** clase10 · **Lenguaje:** Scala 3.3.1 · **Archivos del proyecto:** `niveles/Nivel5For.scala`, `cajas/monada/Caja.scala` (`withFilter`), y los tests `NivelesTest` y `CajaTest` · **Densidad:** 🟡 se lee de corrido, con el worksheet al lado para probar las traducciones (las secciones 1, 2, 3 y 5 son 🔴)

---

## Sobre este documento

**Qué cubre.** Una sintaxis, y lo que hay debajo. El **for comprehension**: dos operaciones (sacar algo de una caja con `<-`, meter algo en una caja con `yield`) con las que se escribe todo lo que se escribe con `flatMap`, `map` y `filter`. La consulta de materias escrita con `for` y su traducción exacta (con `withFilter`, no con `filter`); el ejemplo del anidado contra el `for`, y la tabulación que se evita; el `if` adentro del `for`; `for` sin `yield` es `foreach`, y el `for` que ya conocías era ese caso particular; el contrato estructural: cualquier cosa con `flatMap`, `map` y `withFilter` entra en un `for`, sea lista, `Caja`, `Option` o `Try`; y el último paso de la escalera, con la vista desde arriba.

**Qué no cubre.** El `for` sobre `Try` aplicado al micro (Módulo 10, con `Operations4`). El `for` sobre futuros y la diferencia entre crear las cajas adentro o antes del `for` (Módulo 11).

## De dónde venís

Del Módulo 5: la consulta de materias con `filter`, `map` y `flatMap`, y la versión encadenada en una expresión. Del Módulo 6: `Caja`, su `withFilter`, y que Scala no nombra el contrato (`flatMap`, `map`, `filter`). Del Módulo 7: el pipeline del mail sobre `Option`. Del Módulo 8: `Try`. De la unidad anterior: el primer `run` del micro, el que recorría el programa con `for (instruction <- program)`.

---

## 1. 🔴 Dos operaciones: sacar de la caja, meter en una caja

> Cuando pensás en términos de cajas, hacés dos cosas: **sacar** algo de una caja y **meter** algo en una. El for comprehension es una sintaxis con exactamente esas dos operaciones: `<-` saca, `yield` mete. Con eso se escribe todo lo que se escribe con `flatMap`, `map` y `filter`, sin nombrarlos.

Mirá cómo venís trabajando desde el Módulo 6: en términos de caja. Meto en la caja, saco de la caja, transformo el contenido. Y lo escribís con `filter`, `map` y `flatMap`, que son operaciones que conceptualmente ya quedaron atrás: vos ya moviste el norte, estás pensando en cajas, y seguís escribiendo con las herramientas del nivel anterior.

Scala tiene otra sintaxis para eso, que viene de la notación `do` de Haskell. Se llama **for comprehension**, y tiene dos operaciones:

- `x <- caja`: **sacá** algo de la caja y llamalo `x`.
- `yield expresión`: **metelo** en una caja.

La consulta de materias, escrita así (en el proyecto, `Nivel5For`):

```scala
package tadp.niveles

object Nivel5For {

  def legajosDeRegularesEnElectivas(todasLasMaterias: List[Materia]): List[String] =
    for {
      materia <- todasLasMaterias if materia.electiva
      curso   <- materia.cursos
      alumno  <- curso.inscriptos if alumno.regular
    } yield alumno.legajo
}
```

Leela en voz alta: *de todas las materias, sacá una materia, si es electiva; de esa materia, sacá un curso; de los inscriptos de ese curso, sacá un alumno, si es regular; y metele en la caja el legajo de ese alumno.* Eso es exactamente lo que hacía la consulta de los módulos anteriores, y acá no aparece ni `filter`, ni `map`, ni `flatMap`.

```scala
import tadp.niveles._

Nivel5For.legajosDeRegularesEnElectivas(todasLasMaterias)   // Resultado: List(100, 102, 300, 301)
```

(`todasLasMaterias` son los datos de prueba del Módulo 2; es el mismo resultado que dio la consulta en cada uno de los niveles anteriores.)

Un `if` dentro del `for`, pegado a un `<-`, es un filtro: "sacá una materia, **si** es electiva". Las que no cumplen no salen de la caja.

## 2. 🔴 Lo que escribe el compilador: la traducción exacta

> El `for` es **azúcar sintáctico**: antes de compilar, Scala lo reescribe como una cadena de `flatMap`, `map` y `withFilter`. Todo lo que hace ya lo sabías hacer; te deja escribirlo pensando en sacar y meter.

Esto es lo que el compilador produce a partir del `for` de arriba (en el proyecto, `traducido`, agregado para que lo veas):

```scala
  def traducido(todasLasMaterias: List[Materia]): List[String] =
    todasLasMaterias
      .withFilter(materia => materia.electiva)
      .flatMap(materia => materia.cursos
        .flatMap(curso => curso.inscriptos
          .withFilter(alumno => alumno.regular)
          .map(alumno => alumno.legajo)
        )
      )
```

```scala
Nivel5For.traducido(todasLasMaterias)   // Resultado: List(100, 102, 300, 301)
```

Es el `encadenado` del Módulo 5, con una diferencia: donde había `filter` dice `withFilter`. Las reglas de la traducción, que conviene saber de memoria porque explican todo lo que un `for` hace:

| En el `for` | Se traduce a |
|---|---|
| El **último** `x <- caja` seguido del `yield e` | `caja.map(x => e)` |
| Cada `x <- caja` **que tiene otros después** | `caja.flatMap(x => …lo que sigue…)` |
| Un `if cond` después de un `x <- caja` | `caja.withFilter(x => cond)` |
| Un `for` **sin** `yield` | `caja.foreach(x => …)`; con varias flechas, `foreach` adentro de `foreach` |

Vistas una por una, en un worksheet:

```scala
for (n <- List(1, 2, 3)) yield n * 10                        // Resultado: List(10, 20, 30)
List(1, 2, 3).map(n => n * 10)                               // Resultado: List(10, 20, 30)     un solo <-: map

for { n <- List(1, 2); m <- List(10, 20) } yield n + m       // Resultado: List(11, 21, 12, 22)
List(1, 2).flatMap(n => List(10, 20).map(m => n + m))        // Resultado: List(11, 21, 12, 22)  dos <-: flatMap y map

for { n <- List(1, 2, 3, 4) if n % 2 == 0 } yield n * 10     // Resultado: List(20, 40)
List(1, 2, 3, 4).withFilter(n => n % 2 == 0).map(n => n * 10)   // Resultado: List(20, 40)      if: withFilter
```

Por qué `flatMap` para los `<-` del medio y `map` para el último: cada `<-` que tiene algo después produce, por cada elemento que saca, **otra caja** (lo que sigue), y hay que aplanar; el último solo transforma el elemento sacado en lo que el `yield` dice, y lo mete en una caja. Es la regla del Módulo 7 (la función devuelve caja → `flatMap`; devuelve valor → `map`), aplicada automáticamente por el compilador. Y una de las cosas que esto te ahorra es justamente tener que elegir: cuando uno está aprendiendo, decidir entre `map` y `flatMap`, y si el llamado va adentro o afuera, es tedioso; con el `for`, lo decide la traducción.

⚠️ **Trampa: el `if` se traduce a `withFilter`, no a `filter`.** `withFilter` hace lo mismo que `filter` pero **sin construir la lista intermedia**: deja el criterio anotado y lo aplica recién en el `map` o `flatMap` que sigue. Para vos es un detalle de eficiencia, con una consecuencia práctica: si tu propia caja tiene `filter` y no tiene `withFilter` (acá, una `Cajita` de prueba: la `Caja` del Módulo 6 sin esa línea), un `if` dentro del `for` **no compila**:

```
value withFilter is not a member of Cajita[Int]
```

Por eso la `Caja` del Módulo 6 trae `withFilter`, delegando en `filter`: es lo mínimo para que el `if` funcione sobre ella.

## 3. 🔴 El anidado contra el `for`: la tabulación que se evita

> Cuando encadenás `flatMap` dentro de `flatMap` dentro de `filter`, **el código se va tabulando** hacia la derecha, y se vuelve incómodo de leer. Alguien vio eso y escribió otra sintaxis para lo mismo. Esa es toda la razón de ser del `for`.

Una cadena cualquiera de transformaciones sobre una caja: aplicá `tx1` (devuelve caja), después `tx2` (devuelve caja), filtrá con `crit`, y transformá con `tx3`. Escrita con las operaciones, queda así (en el proyecto, el test `CajaTest`, con funciones concretas sobre una lista):

```scala
val caja = List(1, 2, 3)
val tx1  = (e: Int) => List(e, e * 10)
val tx2  = (e: Int) => List(e + 1)
val crit = (e: Int) => e % 2 == 0
val tx3  = (e: Int) => s"<$e>"

val anidado = caja.flatMap { e1 =>
  tx1(e1).flatMap { e2 =>
    tx2(e2).filter { e3 =>
      crit(e3)
    }.map { e4 =>
      tx3(e4)
    }
  }
}
// Resultado: List(<2>, <4>)
```

Cada paso abre una llave más adentro de la anterior. Con tres pasos ya se lee mal; con seis, llegás a lo que el mundo bautizó *callback hell*: funciones adentro de funciones adentro de funciones, todo el tiempo pasando una función que recibe otra. Lo mismo, con `for`:

```scala
val conFor = for {
  e1 <- caja
  e2 <- tx1(e1)
  e3 <- tx2(e2)
  if crit(e3)
} yield tx3(e3)
// Resultado: List(<2>, <4>)
```

Dan lo mismo, porque el compilador toma el segundo bloque y escribe el primero (con `withFilter` donde el primero dice `filter`, como en la sección 2). Y el segundo se lee de arriba abajo, como pasos: sacá `e1` de la caja; con `e1`, sacá `e2` de `tx1(e1)`; con `e2`, sacá `e3` de `tx2(e2)`; si `crit(e3)`, metele `tx3(e3)`. **Sin decir `map`, `flatMap` ni `filter` ni una sola vez**, y sin pensar en ellos: solo en poner y sacar cosas de cajas.

Y fijate el orden que eso impone: `tx1(e1)` se evalúa adentro de la función que recibe el `flatMap` de `caja`, o sea, recién cuando `caja` entregó un `e1`; `tx2(e2)`, recién cuando `tx1(e1)` entregó un `e2`. **Un `for` es una secuencia:** cada caja se pide cuando la anterior ya respondió. Con listas y con `Option` no se nota; con una caja que tarda en responder, importa, y el Módulo 11 vuelve sobre esto.

(El `if` puede ir en su propia línea, como acá, o pegado al `<-` como en la sección 1; se traduce igual.)

Lo fantástico es que podés escribir y entender este código sin saber qué es `flatMap`: entendiendo la flecha y el `yield` alcanza. Y al revés: una vez que sabés qué hay debajo, el `for` es más comprensible que la cadena, porque la cadena te obliga a seguir las llaves y el `for` te cuenta la secuencia.

## 4. 🟡 `for` sin `yield` es `foreach`: el `for` que ya conocías

> Si escribís `for (x <- caja) …` sin `yield`, el resultado es `Unit`: se traduce a `foreach` y sirve solo para causar efecto. **Ese es el `for` que venías usando como "iteración"**: un caso particular de esta sintaxis, con una sola flecha y sin `yield`.

```scala
for (n <- List(1, 2, 3)) print(s"$n ")      // Resultado: 1 2 3    imprime; no devuelve lista
```

Es lo que hace `List(1, 2, 3).foreach(n => print(s"$n "))`. De la unidad anterior: el primer `run` del micro, el mutable, recorría el programa con `for (instruction <- program) …` y ejecutaba cada instrucción por efecto. Eso era un `for` comprehension sin `yield`: una flecha que saca cada instrucción de la lista, y un cuerpo que causa efecto. Si en aquel momento parecía "el `for` de siempre", era porque es el caso más chico de esta sintaxis.

La sintaxis completa es más amplia, y está pensada para acompañar la forma de trabajar con cajas. El `for` de "iterar" es lo que queda cuando la caja es una lista y no te interesa el resultado.

## 5. 🔴 Contrato estructural: cualquier caja entra en un `for`

> El `for` pide **mensajes, no una interfaz**: tu tipo entra con solo tener `flatMap`, `map` y `withFilter` (y `foreach`, si no hay `yield`: los que el `for` que escribiste necesite), y el compilador adapta la traducción a tu tipo. Es el mismo contrato por nombres del Módulo 6, visto desde la sintaxis.

Volvé a `traducido` (sección 2): si `todasLasMaterias`, `materia.cursos` y `curso.inscriptos` fueran todas `Option` (o todas `Try`) en vez de listas, esa cadena seguiría compilando sin cambiar una letra, porque solo usa `withFilter`, `flatMap` y `map`, y esos mensajes los entiende cualquier caja. (Todas de la misma caja: las cajas no se cruzan, Módulo 8.) El `for` es azúcar sobre esos tres mensajes, así que hereda lo mismo: funciona sobre cualquier cosa que los entienda. Sobre la `Caja` del Módulo 6 (del test `CajaTest`):

```scala
import tadp.cajas.monada._

for {
  x <- Caja.unit(3) if x > 2
  y <- Caja.unit(4)
} yield x + y                                       // Resultado: Llena(7)

for { x <- Caja.unit(1) if x > 2 } yield x          // Resultado: Vacia
```

`Caja` no extiende ninguna interfaz `Monad`; tiene `flatMap`, `map` y `withFilter`, y con eso entra. Sobre `Option`, el pipeline del mail del Módulo 7, sin un solo `flatMap` escrito (en un worksheet, con `Curso` y `Docente` de `ConOption`):

```scala
import tadp.cajas.mail.ConOption._

val conTodo = Curso("K1", Some(Docente("1", Some("ana@utn.edu.ar"))))
val sinMail = Curso("K3", Some(Docente("2", None)))

for {
  docente <- conTodo.titular
  mail    <- docente.mail
} yield mandarMailA(mail)                           // Resultado: Some(mail enviado a ana@utn.edu.ar)

for {
  docente <- sinMail.titular
  mail    <- docente.mail
} yield mandarMailA(mail)                           // Resultado: None

(for {
  docente <- sinMail.titular
  mail    <- docente.mail
} yield mandarMailA(mail)).fold("No se pudo mandar")(r => "Se mandó " + r)   // Resultado: No se pudo mandar
```

Leelo: sacá el docente del titular; sacá el mail del docente; metele en la caja el resultado de mandar. Si alguna caja está vacía, el `for` se corta ahí y devuelve la vacía, porque eso es lo que hace el `flatMap` al que se traduce. El `fold` del final es el mismo: el `for` te deja adentro de la caja, y bajarse sigue siendo tu decisión.

Y sobre `Try`, igual. Sin `if`, el `for` solo pide `flatMap` y `map`:

```scala
import scala.util.Try

for { a <- Try(10); b <- Try(a / 2) } yield a + b   // Resultado: Success(15)
for { a <- Try(10); b <- Try(a / 0) } yield a + b   // Resultado: Failure(java.lang.ArithmeticException: / by zero)
```

El error viaja igual que viajaba con `flatMap`. Si le pusieras un `if`, la traducción pediría `withFilter`, y el de `Try` delega en su `filter` con asterisco del Módulo 8: en vez de una caja vacía, un `Failure` con la excepción inventada (`for { a <- Try(10) if a > 50 } yield a` da `Failure(java.util.NoSuchElementException: Predicate does not hold for 10)`). El `for` hereda lo que la caja trae, asterisco incluido. El Módulo 10 usa esto en serio: el `run` del micro, escrito con `for` sobre el `Result` y después sobre `Try[Micro]`.

Tres cajas distintas, una sintaxis, y en ninguna el `for` necesitó saber qué caja era. Es la misma idea del Módulo 6 (Scala no nombra el contrato; si tu tipo tiene los mensajes, ya se comporta como caja) llevada a la sintaxis: el `for` tampoco lo nombra.

## 6. 🟡 Un paso más, y nunca el último

> Mirá todo lo que dejaste atrás: la estructura, el tipo abstracto, el recorrido, las tres operaciones, y ahora hasta el hecho de que sea una lista. **Abstraer es olvidar lo que hay abajo, construir por encima y hablar en términos de lo que hay arriba**, y siempre se puede dar un paso más. Saber en qué nivel conviene pararse es una de las habilidades que hacen falta para estar cómodo con estas construcciones.

Parate en el último escalón y mirá hacia abajo. Primero trabajaste con la estructura (`Nil`, `::`). Te desentendiste de la estructura y pasaste a la interfaz, el tipo abstracto (`isEmpty`, `head`, `tail`). Te desentendiste del tipo abstracto y pasaste a la idea de que algo se puede recorrer (`fold`). Olvidaste que se podía recorrer y te concentraste en que se podía filtrar, transformar y aplanar (`filter`, `map`, `flatMap`). Olvidaste que tenía que ser siquiera una lista: quedó un pedazo de código que funciona con cualquier caja que cumpla el contrato. Y ahora olvidaste hasta los nombres de las operaciones: sacás y metés.

Para trabajar en este nivel no necesitás ninguno de los anteriores. Y de acá para arriba, andá a saber qué hay: qué otras cosas pueden expresarse en términos de flechas y `yield`, para después tratarlas igual. **Nunca se llega al último nivel.** Lo que sí hace falta es saber cuándo cambiar de nivel: cuándo conviene trabajar más abajo (porque la operación que querés no existe arriba, y tenés que definirla vos, o hasta inventar una sintaxis para trabajar con ese conjunto de operaciones, como alguien inventó el `for`) y cuándo más arriba (porque alguien ya te garantizó que el contrato se cumple, y todo lo de abajo simplemente funciona).

Y una recomendación práctica. Nadie te obliga a escribir con `for` (tampoco en el TP): la propuesta es que sepas que existe, que mejora el código, y que lo pruebes. Lo más probable es que, una vez que lo manejes, sea tu forma preferida de escribir estas cosas antes que `map`, `filter` y `flatMap`, porque te hace la vida más cómoda: es más sencilla, a pesar de la cantidad de conceptos que tiene abajo, porque alguien más se encarga de la traducción.

**Para el parcial, si te preguntan:** *"¿Qué es el for comprehension y a qué se traduce?"* Azúcar sintáctico de Scala, inspirado en la notación `do` de Haskell, para escribir secuencias de operaciones sobre cajas: `x <- caja` saca un elemento, `yield e` lo mete en una caja, `if cond` filtra. Antes de compilar se reescribe como `flatMap` (cada `<-` que tiene otros después), `map` (el último `<-` con el `yield`), `withFilter` (cada `if`) y `foreach` (si no hay `yield`). Funciona sobre cualquier tipo que tenga esos mensajes (contrato estructural: lista, `Option`, `Try`, una caja propia), sin implementar ninguna interfaz. Sirve para evitar la anidación de funciones dentro de funciones y para escribir pensando en sacar y meter, sin elegir entre `map` y `flatMap` a mano.

---

## Checkpoint

1. ¿Cuáles son las dos operaciones del for comprehension? ¿De dónde viene la sintaxis?
2. Escribí la consulta de materias con `for` y después la cadena a la que se traduce. ¿Qué `<-` se vuelve `flatMap` y cuál `map`? ¿Por qué?
3. ¿A qué se traduce un `if` dentro del `for`? ¿Qué diferencia hay con `filter`, y qué pasa si tu caja no tiene `withFilter`?
4. ¿Qué problema de lectura resuelve el `for`? ¿Qué es el *callback hell*?
5. ¿Qué se traduce distinto cuando el `for` no tiene `yield`? ¿Qué era, entonces, el `for (instruction <- program)` del primer `run` del micro?
6. ¿Qué quiere decir que el contrato del `for` es "estructural"? ¿Qué tiene que tener un tipo para entrar en un `for`?
7. Escribí el pipeline del mail (`titular`, `mail`, `mandarMailA`) con `for`. ¿Qué pasa cuando una de las cajas está vacía, y por qué?
8. ¿Qué hace un `for` sobre `Try` cuando un paso falla? ¿Y si le ponés un `if`: qué devuelve y por qué?
9. Enumerá los niveles que dejaste atrás desde `Nil`/`::` hasta el `for`. ¿Qué se olvidó en cada paso?
10. ¿Por qué "nunca se llega al último nivel"? ¿Qué habilidad hace falta, entonces?

## Qué viene después

Con `map`, `flatMap`, `for`, `Option` y `Try` en la mano, el Módulo 10 vuelve al micro de la unidad anterior y lo termina: `map` y `flatMap` sobre el `Result`, el `run` con `for`, una trampa en el `If` dentro del `for`, y después borrar el `Result` y poner `Try[Micro]` sin tocar el código de las instrucciones. Con eso se cierra el `throw` del `Halt` que quedó pendiente desde el Módulo 1.

**FIN DEL MÓDULO 9 — For comprehension, el azúcar de la caja**
