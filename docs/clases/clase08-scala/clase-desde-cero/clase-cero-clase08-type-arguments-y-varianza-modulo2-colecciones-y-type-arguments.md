# Clase desde cero — Type arguments y varianza en Scala — Módulo 2: Colecciones: el tipo de lo que contiene

**Unidad:** clase08 · **Lenguaje:** Scala 3.3.1 · **Densidad:** 🔴 pide una sesión con el código abierto

---

## Sobre este documento

**Qué cubre.** Qué pasa con las dos reglas del Módulo 1 cuando el objeto está adentro de un conjunto: qué tipo le da el compilador a `Set(new Vaca, new Caballo)` y por qué elige ese, qué le da cuando adentro también hay un granero y por qué `estaGordo` deja de compilar, y cómo se le dice al tipo del conjunto **de qué** es (`Set[Animal]`). De paso, el vocabulario de la unidad: tipo paramétrico, parámetro de tipo, argumento de tipo.

**Qué no cubre.** Cómo se define un tipo paramétrico propio (Módulo 3) ni qué pasa cuando se mezclan con el subtipado (Módulo 5). Acá solo se *usan* los que Scala ya trae.

## De dónde venís

Del Módulo 1: una variable deja mandar solo los mensajes de su tipo declarado. De la clase anterior: el compilador asigna a cada expresión el tipo más específico que puede (M8), `Any` arriba de todo (M4), una función anónima `{ a => a.aprobo }` (M8), y `filter` como mensaje de la lista, con un parámetro menos que en Haskell (M8). De Paradigmas: `filter :: (a -> Bool) -> [a] -> [a]`.

---

## 1. 🔴 Un conjunto con dos animales

> Cuando guardás varios objetos en un `Set` sin decirle el tipo, el compilador **infiere el tipo más específico que todos los elementos tienen en común**, y lo que sacás del conjunto es de ese tipo.

`Set(a, b, c)` construye un **conjunto** (una colección sin elementos repetidos; es inmutable, como `List`). El caso:

```scala
  val unaColeccion = Set(new Vaca, new Caballo)
  val gordos = unaColeccion.filter(unElemento => unElemento.estaGordo)   // ✅ compila
  println(gordos.size)                                                     // Resultado: 0
```

`filter` recibe una función que decide por cada elemento si queda, y devuelve un conjunto nuevo con los que quedaron. La función `unElemento => unElemento.estaGordo` recibe un elemento y devuelve un `Boolean`. ¿De qué tipo es `unElemento`? El compilador necesita saberlo para aceptar `.estaGordo`, y lo sabe: **`Animal`**. Es el tipo que infirió para los elementos del conjunto, porque es lo más específico que una `Vaca` y un `Caballo` tienen en común.

**Un truco para ver qué tipo infirió.** Pedile al compilador algo imposible y leé el `Found`:

```scala
  val unaColeccion = Set(new Vaca, new Caballo)
  val n: Int = unaColeccion
  // ❌ Found:    (unaColeccion : Set[tadp.granja.Animal])
  //    Required: Int
```

Ahí está: `Set[tadp.granja.Animal]`. Leé `Set[Animal]` como "conjunto de animales": lo que va entre corchetes dice de qué es el conjunto. En la sección 4 vas a ver qué es exactamente esa sintaxis.

**Por qué el más específico, y no `Any`.** El compilador podría decir siempre "esto es un `Set[Any]`" y tendría razón: todo es `Any`. Pero una variable de tipo `Any` deja mandar solo los mensajes de `Any` (Módulo 1), y eso es casi nada. El tipo sirve para **habilitar mensajes**; cuanto más específico, más mensajes. Con `Set[Animal]`, lo que sale del conjunto entiende `come`, `estaGordo` y `peso`. Con `Set[Any]`, nada de eso.

Y si los dos elementos son vacas, el tipo inferido es más específico todavía:

```scala
  val vacas = Set(new Vaca, new VacaLoca)        // el compilador infiere Set[Vaca]
  vacas.foreach(vaca => vaca.ordeñate)           // ✅ ordeñate es de Vaca
  vacas.foreach(vaca => vaca.reite)              // ❌ value reite is not a member of tadp.granja.Vaca
```

`foreach` le aplica una función a cada elemento y descarta el resultado. La vaca loca está adentro; a través de un `Set[Vaca]`, `reite` es invisible. Es la regla del Módulo 1, ahora sobre el elemento de un conjunto.

## 2. 🔴 Un conjunto con un granero adentro

> Si los elementos **no tienen un ancestro útil en común**, el compilador infiere la **unión** de sus tipos, y a esa unión solo se le pueden mandar los mensajes que **todos** entienden.

Un `Granero` tiene granos; es un objeto más, ajeno a la jerarquía de `Animal`:

```scala
package tadp.granja

class Granero {
  var granos: Int = 10000
}
```

Ahora el conjunto mezcla cosas:

```scala
  val unaColeccion = Set(new Vaca, new Caballo, new Granero)
  unaColeccion.filter(unElemento => unElemento.estaGordo)
  // ❌ value estaGordo is not a member of tadp.granja.Vaca | tadp.granja.Caballo | tadp.granja.Granero
```

| Escribís | Scala entiende | Sale |
|---|---|---|
| `Set(new Vaca, new Caballo)` | un conjunto de lo que vaca y caballo tienen en común | `Set[Animal]` |
| `Set(new Vaca, new VacaLoca)` | un conjunto de lo que vaca y vaca loca tienen en común | `Set[Vaca]` |
| `Set(new Vaca, new Caballo, new Granero)` | un conjunto de vacas, caballos y graneros, sin ancestro útil | `Set[Vaca \| Caballo \| Granero]` |
| `unaColeccion.filter(unElemento => unElemento.estaGordo)` sobre ese último | mandar `estaGordo` a algo que puede ser un granero | ❌ `value estaGordo is not a member of Vaca \| Caballo \| Granero` |
| `unaColeccion.foreach(x => x.come)` sobre ese último | mandar `come` a algo que puede ser un granero | ❌ `value come is not a member of Vaca \| Caballo \| Granero` |

`Vaca | Caballo | Granero` es un **tipo unión**: "una de estas tres cosas". Lo viste en la clase anterior con `Persona | Asistente` (M5). A un valor de tipo unión solo se le pueden mandar los mensajes que las tres alternativas entienden, y un granero ignora `estaGordo` y `come`. Por eso `filter` falla.

En Scala 2, en este caso el compilador infería `Object`, el ancestro común de todo; el efecto era el mismo: ningún mensaje de animal disponible.

**Lo que esto te dice.** El conjunto **sí sabe** qué tipo tienen sus elementos: es parte de su tipo. El problema de la vaca loca del Módulo 1 vuelve, con otra forma: el compilador decide por lo que está garantizado para **todos** los elementos, y vos tal vez sabés más. Para pedirle `estaGordo` a lo que saques del conjunto, el conjunto tiene que ser de animales. Eso se escribe.

🕳️ **Madriguera — traits vs mixins en lenguajes con tipos.** Cuando el tipo de algo se decide por su nombre y su jerarquía (tipado nominal, como acá), las herramientas que arman una clase juntando piezas sueltas vuelven difícil responder "¿esto sigue siendo de este tipo?". Por eso en lenguajes tipados los mixins son más fáciles de manejar que los traits. *Volvé al camino — esto se profundiza aparte, otro día.*

## 3. 🔴 Decirle al conjunto de qué es: `Set[Animal]`

> Un tipo de colección se escribe con **el tipo de sus elementos entre corchetes**: `Set[Animal]`. Con eso, el compilador **rechaza al construir** cualquier elemento que no sea animal, y **acepta mensajes de animal** sobre lo que sale.

```scala
  val unaColeccion: Set[Animal] = Set(new Vaca, new Caballo, new VacaLoca)
  val gordos: Set[Animal] = unaColeccion.filter(_.estaGordo)   // ✅
  println(gordos.size)                                           // Resultado: 0
```

`_.estaGordo` es la forma corta de `unElemento => unElemento.estaGordo`: cuando la función usa su único parámetro una sola vez, el `_` lo reemplaza y el nombre se omite. Es la forma que vas a ver en todo el código de la unidad; la larga es la de la sección 1.

Y el granero, ahora, se rechaza **antes**, al construir:

```scala
  val unaColeccion: Set[Animal] = Set(new Vaca, new Caballo, new Granero)
  //                                                        ^^^^^^^^^^^
  // ❌ Found:    tadp.granja.Granero
  //    Required: tadp.granja.Animal
```

| Escribís | Scala entiende | Sale |
|---|---|---|
| `val c = Set(new Vaca, new Caballo, new Granero)` | inferí el tipo | ✅ `Set[Vaca \| Caballo \| Granero]`; `estaGordo` falla después, al usarlo |
| `val c: Set[Animal] = Set(new Vaca, new Caballo, new Granero)` | un conjunto de animales con un granero adentro | ❌ `Found: Granero / Required: Animal`, al construir |
| `val c: Set[Animal] = Set(new Vaca, new Caballo, new VacaLoca)` | un conjunto de animales | ✅; `c.filter(_.estaGordo)` compila |
| `val c: Set = Set(new Vaca, new Caballo)` | un conjunto a secas | ❌ `Missing type parameter for Set` |

La última fila es la que define el tema: **`Set` a secas, con los corchetes vacíos, es un tipo incompleto**. El compilador lo dice con esas palabras. `Set` necesita un parámetro para ser un tipo completo: `Set[Animal]`, `Set[Vaca]`, `Set[Int]`. Así como en Haskell `[a]` es "lista de `a`" y la lista necesita su `a` para significar algo, acá `Set[A]` es "conjunto de `A`".

**Por qué el error se movió.** Sin anotación, el compilador infirió lo que había y el error apareció al mandar `estaGordo`. Con `Set[Animal]`, vos declaraste qué contiene, y el error apareció al meter el granero. Es la misma información, puesta por vos en vez de inferida, y el error se corre al lugar donde está el problema de verdad: el granero, y la línea que lo mete.

Los tests 4 y 5 de `GranjaTest.scala` verifican esto: un `Set[Animal]` con una vaca gorda filtra bien, y un granero en un `Set[Animal]` **no compila** (ese test usa `assertTypeError`, que le pide al compilador que rechace el código entre comillas).

> **Para el parcial, si te preguntan**
> *¿Por qué `Set(new Vaca, new Caballo, new Granero).filter(_.estaGordo)` no compila, y qué cambia con `val c: Set[Animal] = …`?* — Sin anotación, el compilador infiere para los elementos el tipo más específico común a los tres; con un granero adentro es la unión `Vaca | Caballo | Granero`, y `estaGordo` es un mensaje que un granero ignora. Con `Set[Animal]`, el tipo de los elementos queda fijado por vos: el granero se rechaza al construir el conjunto, y sobre lo que sale se pueden mandar los mensajes de `Animal`.

## 4. 🔴 El vocabulario: tipos paramétricos

> Un **tipo paramétrico** es un tipo que **recibe otro tipo como parámetro** para estar completo. `Set` es un tipo paramétrico; `Set[Animal]` es un tipo. `A` en `Set[A]` es el **parámetro de tipo**; `Animal` en `Set[Animal]` es el **argumento de tipo**.

La misma idea con la que ya trabajás en funciones, llevada a los tipos: una función tiene parámetros en su definición y recibe argumentos cuando se la llama. Un tipo paramétrico tiene parámetros de tipo en su definición y recibe argumentos de tipo cuando se lo usa.

| Término | Qué es | Ejemplo |
|---|---|---|
| Tipo paramétrico | un tipo incompleto, que necesita uno o más tipos para completarse | `Set`, `List` |
| Parámetro de tipo | el nombre que ocupa el lugar del tipo faltante, en la definición | `A` en `Set[A]` |
| Argumento de tipo | el tipo concreto que se le pasa al usarlo | `Animal` en `Set[Animal]` |
| Tipo compuesto (o completo) | el paramétrico con su argumento | `Set[Animal]`, `List[Vaca]` |

Dos nombres para lo mismo, que vas a encontrar mezclados: **tipo paramétrico** y **tipo genérico**. Acá se usa el primero.

**Haskell ya lo tenía.** `filter :: (a -> Bool) -> [a] -> [a]`: la `a` minúscula es el parámetro de tipo, `[a]` es "lista de `a`", y la firma dice que lo que entra y lo que sale son listas del mismo `a`. En Scala, `filter` sobre un `Set[A]` recibe una función `A => Boolean` y devuelve un `Set[A]` (`A => Boolean` es el tipo de una función que recibe un `A` y devuelve un `Boolean`; esa sintaxis se profundiza en el Módulo 6). Misma operación, mismo parámetro, un argumento menos porque el conjunto es el receptor del mensaje.

Lo único que cambia respecto de la clase anterior es que ahora el parámetro de tipo **lo vas a escribir vos**: el Módulo 3 define un tipo paramétrico propio, y ahí el `A` deja de ser algo que viene en la biblioteca.

## 5. 🟡 Lo que viene

> Un `Set[Animal]` resuelve el conjunto. Un **corral** tiene el mismo problema, y no viene resuelto.

El corral del Módulo 3 guarda animales, y un lechero quiere ordeñar las vacas de un corral. Con lo que tenés hasta acá, el corral guarda un `Set[Animal]`, y lo que sale de ahí es `Animal`: la regla del Módulo 1 dice que `ordeñate` es invisible. Hace falta un corral que sepa **de qué** es, igual que el conjunto.

---

## Checkpoint (sin respuestas)

1. ¿Qué tipo infiere el compilador para `Set(new Vaca, new Caballo)`? ¿Y para `Set(new Vaca, new VacaLoca)`? ¿Con qué criterio?
2. ¿Por qué el compilador infiere el tipo más específico y no `Any`? ¿Qué se ganaría y qué se perdería con `Any`?
3. ¿Qué tipo infiere para `Set(new Vaca, new Caballo, new Granero)`? ¿Qué mensajes se le pueden mandar a un elemento de ese conjunto?
4. `Set(new Vaca, new Caballo, new Granero).filter(_.estaGordo)` falla. ¿Dónde falla, al construir o al usar? ¿Y `val c: Set[Animal] = Set(new Vaca, new Caballo, new Granero)`?
5. ¿Qué dice el error `Missing type parameter for Set`? ¿Qué le falta a `Set` para ser un tipo?
6. Definí tipo paramétrico, parámetro de tipo y argumento de tipo, con un ejemplo de cada uno.
7. Compará `filter :: (a -> Bool) -> [a] -> [a]` con el `filter` de un `Set[A]` en Scala. ¿Qué es lo mismo y qué cambia?
8. Escribí `unElemento => unElemento.estaGordo` en la forma corta. ¿Cuándo se puede usar esa forma?

## Qué viene después

El Módulo 3 agrega al dominio un `Corral`, un `Pastor` que pastorea y un `Lechero` que ordeña. El lechero va a chocar con la misma pared que el `filter` de la sección 2, y la salida va a ser definir el primer tipo paramétrico propio de la unidad: `Corral[T]`.

**FIN DEL MÓDULO 2**
