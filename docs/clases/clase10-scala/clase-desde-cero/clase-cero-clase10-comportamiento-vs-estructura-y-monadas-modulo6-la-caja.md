# Clase desde cero — Comportamiento vs estructura y mónadas — Módulo 6: La caja, el contrato de mónada

**Unidad:** clase10 · **Lenguaje:** Scala 3.3.1 · **Archivo del proyecto:** `cajas/monada/Caja.scala` · **Densidad:** 🔴 pide una sesión con el código abierto; es el módulo central de la unidad

---

## Sobre este documento

**Qué cubre.** La respuesta al desafío del Módulo 5: `filter`, `map` y `flatMap` descriptas sin hablar de colecciones, sobre una **caja** con algo adentro. Qué hace cada operación sobre una caja, por qué nunca hace falta preguntar si la caja tiene contenido, cuál es el contrato mínimo que una caja tiene que cumplir (`unit` y `bind`), por qué `bind` es `flatMap` y no `map`, las tres leyes que el contrato exige, qué agrega la mónada plus (`zero` y `plus`) y por qué de ahí sale `filter`, cómo Scala implementa todo esto sin nombrarlo, y la lista como la primera caja. Y el nombre: mónada.

**Qué no cubre.** Cajas concretas que resuelvan problemas concretos: `Option` (Módulo 7) y `Try` (Módulo 8).

## De dónde venís

Del Módulo 5: `filter`, `map` y `flatMap` sobre listas, sus firmas, `flatMap` como "mapear y aplanar", y el desafío de describirlas sin la palabra conjunto. Del Módulo 4: el monoide (operación cerrada y asociativa, con neutro) y la idea de que una propiedad vale más que una prueba. Del Módulo 3: `[+T]`, `[U >: T]` y `Nothing` en `ListaSnoc`, que `Caja` repite. De la unidad anterior: `sealed trait`, `case class`, `case object`, y el parámetro por nombre (`=> R`).

---

## 1. 🔴 Una caja con algo adentro

> Olvidate de la lista. Hay una **caja**, y adentro hay un contenido. Las tres operaciones hacen cosas con el contenido **sin que vos abras la caja**: `map` lo transforma, `flatMap` lo transforma en algo que viene en su propia caja y la desenvuelve, `filter` lo deja o lo saca. Vos describís qué hacer con el contenido; la caja se ocupa del resto.

Visualizalo. Tenés una caja cerrada; adentro, un triángulo azul. Querés el triángulo pintado de verde: eso es `map`. Le pasás a la caja "pintá de verde", la caja abre, pinta, cierra, y te da otra caja con un triángulo verde. Vos nunca abriste nada.

Ahora querés que el triángulo se vuelva un círculo. Pero la operación "volver redondo" es de las que devuelven su resultado **en una caja**. Si usaras `map`, terminarías con una caja que tiene adentro otra caja con un círculo. `flatMap` hace lo mismo que `map` y además abre esa caja interna y deja el círculo directamente en la caja de afuera. Una sola caja, un círculo.

Después querés quedarte con el contenido solo si cumple algo: `filter`. Si cumple, la caja sigue con su contenido; si no, queda una **caja vacía**.

Y la parte importante: una caja vacía **también es una caja**. Si le pedís `map`, no hay nada que pintar, y te devuelve una caja vacía. Si le pedís `flatMap`, lo mismo. Si le pedís `filter`, lo mismo. Las tres operaciones saben qué hacer con la vacía, así que **nunca tenés que preguntar si hay contenido**. Vos encadenás: pintá, redondeá, filtrá, transformá; y al final mirás qué quedó. El `case Nil` que te persiguió desde el Módulo 2 desapareció del todo.

```scala
caja.filter(f).map(g).filter(h).flatMap(i).filter(j).size > 2
```

En esta expresión no tiene ninguna importancia si la caja inicial estaba vacía, ni si alguno de los `filter` la dejó vacía: en ningún momento se necesita acceder al contenido. Solo te preocupás por el caso de que no haya contenido cuando llega el momento de abrir la caja, y eso es al final.

Con listas, en el proyecto (`CajaTest`), con funciones concretas:

```scala
val f = (n: Int) => n > 0
val g = (n: Int) => n * 10
val h = (n: Int) => n < 100
val i = (n: Int) => List(n, n + 1)
val j = (n: Int) => n % 2 == 0

List(1, 2, 3, -4).filter(f).map(g).filter(h).flatMap(i).filter(j)      // Resultado: List(10, 20, 30)
List(1, 2, 3, -4).filter(f).map(g).filter(h).flatMap(i).filter(j).size > 2   // Resultado: true
List.empty[Int].filter(f).map(g).filter(h).flatMap(i).filter(j).size > 2     // Resultado: false
List(-1, 50).filter(f).map(g).filter(h).flatMap(i).filter(j)           // Resultado: List()
```

Esa es la descripción sin la palabra conjunto. En firmas, el paso es reemplazar `[a]` por "una caja de `a`", `T a`, y nada más:

```
filter  :: (a → Bool) → (T a → T a)
map     :: (a → b)    → (T a → T b)
flatMap :: (a → T b)  → (T a → T b)
```

Las tres firmas del Módulo 5 siguen valiendo letra por letra; lo único que cambió es que `T` ya no tiene por qué ser `List`. Es vaga a propósito: "una caja con un contenido" no dice cuántas cosas hay adentro, ni si hay alguna. Una lista es una caja con muchas cosas (o ninguna). Pero hay otras cajas, y la gracia está en que **todo lo que escribiste con `filter`, `map` y `flatMap` sobre listas funciona igual sobre cualquier caja**. Antes decías "quiero mapear, no me importa si la lista está vacía"; ahora decís "quiero mapear, no me importa ni siquiera si es una lista".

## 2. 🔴 El contrato mínimo: `unit` y `bind`

> Para ser una caja alcanzan **dos operaciones**: `unit`, que guarda un valor en una caja, y `bind`, que transforma el contenido con una función que devuelve otra caja. `bind` es `flatMap`. Con las dos se escribe `map`; con `map` sola no se escribe `flatMap`.

```
unit :: T -> M[T]                        "guardá este valor en una caja"
bind :: (T -> M[R]) -> M[T] -> M[R]      "transformá el contenido; la función devuelve su resultado en caja"
```

`M` es "la caja": `M[T]` es una caja con un `T` adentro. `unit` recibe un valor pelado y lo mete en una caja: es lo que necesitás para subirte a esta forma de trabajar cuando lo que tenés es un valor suelto. Es un lifteo, como el del Módulo 5: ahí `map` levantaba una función al orden de las listas; `unit` levanta un valor al orden de las cajas. `bind` es exactamente `flatMap`: recibe una función de `T` a `M[R]` (del contenido a una caja nueva) y va de `M[T]` a `M[R]`.

¿Por qué el contrato pide `bind` (`flatMap`) y no `map`? Porque **`flatMap` es más poderoso que `map`**: con `flatMap` y `unit` se escribe `map`, y con `map` no se escribe `flatMap`. Suena al revés (`flatMap` parece una variante rara de `map`), pero pensá en la lista: `map` no puede cambiar la cantidad de elementos, es un invariante fuerte; `flatMap` sí puede (uno entra, cero o varios salen). El que puede más es la base, y el que puede menos se deriva. (Esta no es la única forma de escribir el contrato: hay formulaciones equivalentes con otra operación base en lugar de `bind`. Acá va esta porque es la que Scala calca con `flatMap`.) Es la pregunta del Módulo 1 ("¿qué es lo mínimo que necesito?"), respondida para la caja: lo mínimo son `unit` y `bind`.

Esta es la caja del proyecto, armada para cumplir el contrato y nada más. Tiene dos formas, `Llena` y `Vacia`, y sus operaciones:

```scala
package tadp.cajas.monada

import Caja.{unit, zero}

sealed trait Caja[+T] {
  def flatMap[R](f: T => Caja[R]): Caja[R]
  def ++[U >: T](otra: Caja[U]): Caja[U]
  def fold[R](ifEmpty: => R)(f: T => R): R

  def map[R](f: T => R) = this.flatMap(v => unit(f(v)))

  def filter(f: T => Boolean) = this.flatMap(v =>
    if (f(v)) unit(v) else zero
  )

  def withFilter(f: T => Boolean): Caja[T] = filter(f)   // lo pide el for con if (Módulo 9)
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

Leé primero `unit` y `flatMap`, que son el contrato. `unit(valor)` es `Llena(valor)`. `flatMap` sobre una `Llena` aplica la función al valor, y lo que la función devuelve (una caja) **es** el resultado: ahí está el "desenvolver", no hay caja dentro de caja porque la caja de la función reemplaza a la de afuera. `flatMap` sobre una `Vacia` devuelve la vacía: no hay valor al que aplicar nada. (`++`, `zero` y `fold` se explican en las secciones 4 y 6; `withFilter` en el Módulo 9.)

Y ahora `map`, que **no está programado aparte**: es `flatMap` con una función que transforma y vuelve a meter en caja con `unit`. Lo mismo `filter`: `flatMap` con una función que devuelve el valor en caja si cumple, o la caja vacía si no.

```scala
import tadp.cajas.monada._

Caja.unit(3)                                          // Resultado: Llena(3)
Caja.unit(3).flatMap(n => Caja.unit(n * 2))           // Resultado: Llena(6)
Caja.unit(3).flatMap(n => Caja.zero[Int])             // Resultado: Vacia
Caja.zero[Int].flatMap(n => Caja.unit(n * 2))         // Resultado: Vacia

Caja.unit(3).map(_ + 1)                               // Resultado: Llena(4)
Caja.unit(3).flatMap(n => Caja.unit(n + 1))           // Resultado: Llena(4)   lo mismo, escrito con flatMap y unit
Caja.zero[Int].map(_ + 1)                             // Resultado: Vacia
Caja.unit(3).filter(_ > 2)                            // Resultado: Llena(3)
Caja.unit(3).filter(_ > 5)                            // Resultado: Vacia

Caja.unit(5).map(_ * 2).filter(_ > 3).flatMap(n => Caja.unit(n + 1)).map(_.toString)     // Resultado: Llena(11)
Caja.zero[Int].map(_ * 2).filter(_ > 3).flatMap(n => Caja.unit(n + 1)).map(_.toString)   // Resultado: Vacia
```

Las dos últimas líneas son la sección 1 en código: la misma cadena sobre una caja llena y sobre una vacía, sin una sola pregunta en el medio. Sobre `[+T]`, `[U >: T]` y `Nothing`: es lo mismo que en `ListaSnoc` (Módulo 3), para que una única `Vacia` sirva como caja vacía de cualquier tipo.

## 3. 🔴 No alcanza con tener las funciones: las tres leyes

> Ser una caja es cumplir **tres leyes** con `unit` y `flatMap`; sin las leyes, los dos nombres son solo dos nombres. Recién con las leyes todo lo construido encima (`map`, `filter`, lo que venga) se comporta como corresponde.

Son estas, escritas con `bind` como función (`bind f m`, en vez de `m.flatMap(f)`):

| Ley | Enunciado | En palabras |
|---|---|---|
| **Identidad izquierda** | `bind f (unit v) == f v` | meter `v` en una caja y aplicarle `f` es lo mismo que aplicar `f` a `v` directamente |
| **Identidad derecha** | `bind unit m == m` | aplicarle `unit` al contenido de una caja la deja igual |
| **Asociatividad** | `bind g (bind f m) == bind (bind g . f) m` | encadenar dos transformaciones da lo mismo que aplicar una transformación que las encadena |

Sobre `Caja`, verificadas (`dobleSiPositivo` duplica o vacía según el signo; `masUno` suma uno):

```scala
val dobleSiPositivo = (n: Int) => if (n > 0) Caja.unit(n * 2) else Caja.zero[Int]
val masUno = (n: Int) => Caja.unit(n + 1)
val m = Caja.unit(5)

Caja.unit(5).flatMap(dobleSiPositivo)                     // Resultado: Llena(10)
dobleSiPositivo(5)                                        // Resultado: Llena(10)      identidad izquierda
m.flatMap(Caja.unit)                                      // Resultado: Llena(5)       identidad derecha
m.flatMap(dobleSiPositivo).flatMap(masUno)                // Resultado: Llena(11)
m.flatMap(x => dobleSiPositivo(x).flatMap(masUno))        // Resultado: Llena(11)      asociatividad
```

Las leyes se nombran y se sigue; en esta unidad se usan de forma implícita. Lo que importa entender es **para qué están**: son lo que garantiza que no se trate de dos mensajes que casualmente se llaman igual, sino de operaciones que cumplen el mismo criterio. Y si cumplen el mismo criterio, podés depender de eso para construir más: `map` y `filter` derivados funcionan porque `flatMap` y `unit` se comportan como deben. Es el mismo argumento que el del monoide en el Módulo 4: saber la propiedad vale más que probar cada caso. Cuando vos aprendés a trabajar con una caja que cumple las leyes, automáticamente sabés trabajar con todas, porque la manera de trabajar es con el contrato, no con la caja.

## 4. 🔴 Mónada plus: `zero` y `plus`

> Si además de `unit` y `bind` la caja puede estar **vacía** (`zero`) y dos cajas se pueden **combinar** en una (`plus`), es una **mónada plus**. `zero` y `plus` forman un monoide, y con `zero` se escribe `filter`.

Hasta acá, las cajas siempre tienen un `T`, y la única forma de obtener una es a partir de un valor. Si además podés tener una caja sin nada adentro, y podés juntar dos cajas en una, tenés dos operaciones más:

```
zero :: M[T]                       "la caja vacía"
plus :: M[T] -> M[T] -> M[T]       "dos cajas, una caja"
```

En `Caja`, `zero` es `Vacia` y `plus` es `++`: la llena se queda con lo suyo, la vacía cede a la otra.

```scala
Caja.zero[Int]                                 // Resultado: Vacia
Caja.unit(1) ++ Caja.unit(2)                   // Resultado: Llena(1)
Caja.zero[Int] ++ Caja.unit(1)                 // Resultado: Llena(1)
Caja.unit(1) ++ Caja.zero[Int]                 // Resultado: Llena(1)
((Caja.unit(1) ++ Caja.zero[Int]) ++ Caja.unit(2), Caja.unit(1) ++ (Caja.zero[Int] ++ Caja.unit(2)))
                                               // Resultado: (Llena(1),Llena(1))
Caja.zero[Int].flatMap(dobleSiPositivo)        // Resultado: Vacia
```

Mirá las leyes que cumplen `zero` y `plus`: `plus zero m == m`, `plus m zero == m`, y `plus (plus m1 m2) m3 == plus m1 (plus m2 m3)`. Son las propiedades del monoide del Módulo 4: el neutro por los dos lados y la asociatividad (cerrada la garantiza el tipo, `M[T] -> M[T] -> M[T]`). **`plus` y `zero` forman un monoide**, con `zero` como neutro. (Qué leyes exactas tiene que cumplir una mónada plus, además de esta, es algo sobre lo que ni la comunidad se pone de acuerdo; alcanza con el monoide.) La semilla del `fold` era el neutro; la caja vacía es el neutro de combinar cajas. Y hay una ley más, "zero izquierdo": `bind f zero == zero`, la última línea de arriba. Transformar la vacía da la vacía, que es lo que la sección 1 prometía.

Y ahora sí, `filter`. Volvé a mirarlo en el código de la sección 2: `flatMap` con una función que devuelve `unit(v)` si cumple y `zero` si no. **`filter` necesita `zero`.** Filtrar exige poder quedarse sin contenido: una caja que siempre está llena carece de forma de decir "no quedó nada". Este detalle vuelve en el Módulo 8, con una caja que es mónada y no mónada plus.

```
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
              Monad[T]
   unit[T](value: T): Monad[T]
   flatMap[R](f: T => Monad[R]): Monad[R]
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
                    △
                    ┆
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
            MonadPlus[T]
   zero[T](): Monad[T]
   plus(other: Monad[T]): Monad[T]
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
   map[R](f: T => R)     = flatMap(v => unit(f(v)))
   filter(f: T => Boolean) = flatMap(v => if (f(v)) unit(v) else zero)
```

Con esto queda respondido también lo que quedó colgado en el Módulo 4: la consulta necesitaba que la cosa fuera recorrible **y concatenable**. Concatenable es `plus`.

## 5. 🔴 Scala no nombra el contrato: `flatMap`, `map` y `filter`

> En Scala el contrato es implícito: hay una convención de nombres, y ninguna interfaz `Monad` que implementar. Si tu tipo tiene **`flatMap`, `map` y `filter`** (y `withFilter`, que el Módulo 9 explica), ya se comporta como una caja para todo lo que la unidad hace de acá en adelante.

Lo de arriba es el contrato formal, el matemático, con los nombres de Haskell. Scala lo implementa de otra manera: no hay `unit` ni `bind` como palabras. `unit` es el `apply` del objeto compañero (`List(3)`, `Option(3)`; en `Caja`, que es nuestra y no tiene `apply`, se llama `unit`); `bind` se llama `flatMap`; `zero` es el constructor vacío (`Nil`, `None`); `plus` es `++` en `List` (en otras cajas tiene otro nombre: el Módulo 7 lo muestra). Y en vez de pedirte el contrato mínimo y derivar el resto, Scala espera que tu tipo traiga `flatMap`, `map` y `filter` ya escritos; como `map` es derivado de `flatMap` y `filter` lo es de `zero`, es la misma cosa con los espacios llenados.

Y la **lista es una mónada plus**, aunque nunca la hayas llamado así:

| Contrato | En `List` |
|---|---|
| `unit` | `List(x)` |
| `bind` | `flatMap` |
| `zero` | `Nil` |
| `plus` | `++` |

```scala
List(5)                                                 // Resultado: List(5)      unit
List(1, 2, 3).flatMap(n => List(n, n * 10))             // Resultado: List(1, 10, 2, 20, 3, 30)   bind
List.empty[Int]                                         // Resultado: List()       zero
List(1, 2) ++ List(3)                                   // Resultado: List(1, 2, 3)   plus
List(1, 2, 3).flatMap(n => List(n * 10))                // Resultado: List(10, 20, 30)   map, escrito con flatMap y unit
List(1, 2, 3).flatMap(n => if (n > 1) List(n) else Nil) // Resultado: List(2, 3)     filter, escrito con flatMap, unit y zero
```

Son cosas que ya sabías hacer con listas, con otros nombres. Lo que cambia es la lectura: la lista no es "el tipo que tiene `flatMap`"; es **una** de las cajas, la que tiene muchas cosas adentro. El `flatMap` que sabés usar sobre listas es el mismo `bind` que vas a usar sobre todas las demás.

## 6. 🔴 La mónada no es una cosa: es una idea

> Una **mónada** es un contenedor de algo que te interesa por lo que contiene, sobre el cual podés **secuenciar operaciones** sin preguntar en cada paso si algo salió mal. No es un tipo: es un contrato que distintos tipos cumplen, cada uno para un problema distinto; más cerca de un patrón de diseño que de una interfaz: se cumplen las operaciones y lo demás sale gratis.

El nombre, por fin: a estas cajas se las llama **mónadas**. Y hay que tener cuidado con la palabra, porque sugiere una cosa concreta y es al revés. Vos no tenés "una mónada": tenés una lista, o una caja que puede estar vacía, o una que puede haber fallado, y cada una es **una forma** de mónada. La lista es una mónada. La caja del Módulo 7, que resuelve el problema del valor que no está, es otra. La del Módulo 8, que resuelve el problema del error, es otra. Cada una tiene un problema distinto sobre el que trabaja, y todas comparten la forma de trabajar.

Siempre es "una mónada de algo": trabajás con un coso **de algo**, y lo que te importa es el algo. Muchos problemas que son de los "algos" se convierten en un problema de "coso de algo" para poder trabajarlos así, porque así es fácil **secuenciar lógica**: hacé esto, después esto, después esto otro. Ese "después" es `bind`: la operación que dice "hacé lo siguiente con el contenido y decime en qué caja quedamos". Dicho con algo que ya tenés: la composición de funciones es un mecanismo para secuenciar operaciones; la mónada es un mecanismo para secuenciar transformaciones de datos. (Para después, dos lecturas que la cátedra recomienda: la página *Monad* de la wiki de Haskell y "Demystifying the Monad in Scala"; ninguna hace falta para el TP.) Y el gran objetivo es que al secuenciar no te preocupes por si algo salió mal en el camino: vos describís el camino feliz, qué hacer cuando el contenido está, cuando no falla; y el manejo del fallo lo decide el tipo de caja que tengas.

Cuando trabajás así, vas **de caja en caja**: te subís a la autopista con `unit` y seguís de caja en caja (`map`, `flatMap`, `filter`) hasta que te bajás. Bajarse es romper la caja, y para eso está `fold`: le decís qué hacer si está vacía y qué hacer con el contenido, y te da un valor pelado.

```scala
Caja.unit(3).fold("nada")(n => s"hay $n")       // Resultado: hay 3
Caja.zero[Int].fold("nada")(n => s"hay $n")     // Resultado: nada
```

Es el catamorfismo del Módulo 4, sobre una caja de un solo valor: no recorre nada; te da los dos caminos (el `ifEmpty` va por nombre, así no se evalúa si hay contenido). Hasta que llegás al `fold`, nunca preguntaste si había algo adentro.

⚠️ **Nomenclatura: mismo concepto, otros nombres.** Vas a encontrar cada operación con varios nombres según el lugar; son la misma cosa:

| Acá | En Haskell | En Scala | Otros nombres |
|---|---|---|---|
| `unit` | `return` | `apply` del compañero (`List(x)`, `Option(x)`) | `pure` |
| `bind` | `>>=` | `flatMap` | — |
| `zero` | `mzero` | `Nil`, `None` | `empty` |
| `plus` | `mplus` | `++` en `List`; `orElse` en `Option` | — |
| mónada plus | `MonadPlus` | (sin nombre) | "mónada cero" |

**Para el parcial, si te preguntan:** *"¿Qué es una mónada?"* Un contrato para contenedores: una caja con un contenido, que sabe meter un valor adentro (`unit`) y transformar el contenido con una función que devuelve otra caja (`bind`, que en Scala es `flatMap`), respetando tres leyes (identidad izquierda, identidad derecha, asociatividad). Con eso se escriben `map` y, si la caja puede estar vacía y combinarse (mónada plus: `zero` y `plus`), también `filter`. Sirve para secuenciar operaciones describiendo solo el camino feliz: la caja maneja sola el caso en que no hay contenido o algo falló. La lista es una mónada; `Option` y `Try` son otras.

*"¿Por qué el contrato pide `flatMap` y no `map`?"* Porque `flatMap` es más poderoso: con `flatMap` y `unit` se escribe `map` (`flatMap(v => unit(f(v)))`), y con `map` solo es imposible escribir `flatMap`: `map` conserva la cantidad y deja la caja devuelta por la función adentro de otra caja.

---

## Checkpoint

1. Describí `map`, `flatMap` y `filter` sobre una caja, sin usar "elemento" ni "colección".
2. ¿Por qué nunca hace falta preguntar si la caja tiene contenido? ¿Cuándo se pregunta, entonces?
3. ¿Cuáles son las dos operaciones del contrato mínimo? ¿Qué tipo tiene cada una?
4. ¿Por qué `bind` es `flatMap` y no `map`? ¿Cómo se escribe `map` a partir de `flatMap` y `unit`?
5. ¿Qué hace `flatMap` sobre una `Llena`? ¿Dónde está el "desenvolver"?
6. Enunciá las tres leyes. ¿Para qué están?
7. ¿Qué agrega una mónada plus? ¿Qué relación tienen `zero` y `plus` con el monoide?
8. ¿Por qué `filter` necesita `zero`? ¿Qué pasaría con una caja que no puede estar vacía?
9. ¿Cómo implementa Scala el contrato? ¿Qué es cada operación en `List`?
10. ¿Qué quiere decir que la mónada "no es una cosa, es una idea"? ¿Para qué sirve, en una frase?
11. ¿Qué hace `fold` sobre una caja? ¿En qué se parece y en qué se diferencia del `fold` de una lista?

## Qué viene después

El Módulo 7 trae la primera caja que resuelve un problema concreto: `Option`, la caja que puede estar vacía, para reemplazar a `null`. El ejemplo es mandarle un mail al titular de un curso, cuando el curso puede no tener titular y el titular puede no tener mail.

**FIN DEL MÓDULO 6 — La caja, el contrato de mónada**
