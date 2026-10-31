# Clase desde cero — Pattern matching, case classes y el híbrido objeto-funcional — Módulo 6: El lenguaje: case classes y pattern matching

**Unidad:** clase09 · **Lenguaje:** Scala 3.3.1 · **Archivo del proyecto:** `mutable/Instructions.scala` · **Densidad:** 🟡 se lee de corrido; cada patrón se puede probar en un worksheet

---

## Sobre este documento

**Qué cubre.** La herramienta que el Visitor simulaba. `case object` y `case class`: qué le agregan a una clase y por qué hacen falta para matchear. Las instrucciones del micro reescritas como datos. `match` como expresión, y los patrones que se usan en la unidad: constante, constructor, tipo, lista con `::` y `Nil`, comodín y guarda. Y lo que el `match` resuelve de los problemas del `switch` del Módulo 3: sin caída al caso siguiente, variables propias por rama, y un aviso del compilador cuando falta un caso.

**Qué no cubre.** Las tres operaciones del micro escritas con esto: son el Módulo 7. Acá los ejemplos son sueltos o miran una sola instrucción.

## De dónde venís

Del Módulo 2: el *data object* como antipatrón de objetos. Del Módulo 3: el type check con `isInstanceOf`, el `break` olvidado, el scope compartido del `switch` y "¿cómo sabías qué funciones tocar?". Del Módulo 4: polimorfismo paramétrico, decidir por la forma del dato, y que pattern matching es la herramienta que lo vuelve concreto. Del Módulo 5: las instrucciones como clases que solo saben aceptar. De Paradigmas: el pattern matching de Haskell, con `[]` y `(cabeza:cola)`.

---

## 1. 🟡 `case`: una clase que se deja mirar

> Anteponer **`case`** a una clase o a un `object` le agrega lo necesario para el **patrón de constructor** (`Load(address)`), y de regalo: construcción sin `new`, campos de solo lectura, igualdad por contenido, un `toString` legible y `copy`. Es azúcar sintáctico: todo eso se podría escribir a mano.

Un `Load` de juguete, en un worksheet aparte del proyecto (si no, choca con el `Load` del paquete):

```scala
case class Load(address: Int)

Load(2)                       // Resultado: Load(2)
Load(2).address               // Resultado: 2
Load(2) == Load(2)            // Resultado: true
Load(2).copy(address = 5)     // Resultado: Load(5)
```

Lo que te regala:

- **Construcción sin `new`.** `Load(2)` llama a una función constructora con el nombre de la clase.
- **`toString` legible.** Se imprime `Load(2)`. Con una clase común, `new LoadComun(2)` imprime algo como `LoadComun@3fb6a447`: el nombre de la clase y un número que identifica al objeto.
- **Campos expuestos.** `address` se lee desde afuera y no se puede reasignar, sin que escribas `val`.
- **Igualdad por contenido.** Dos `Load(2)` son iguales porque tienen lo mismo adentro. Con una clase común, `new LoadComun(2) == new LoadComun(2)` da `false`: son dos objetos distintos. `==` usa `equals`, que `case` genera comparando el contenido, junto con un `hashCode` acorde (el número que usan los `Set` y los `Map` para ubicar el objeto).
- **`copy`.** Una copia con los mismos campos, cambiando solo los que nombrás. `address = 5` es un **parámetro nombrado**: le pasás el valor diciendo a qué parámetro va. El Módulo 8 lo usa con el micro, que es donde se luce.
- **El patrón de constructor.** Es lo que habilita escribir `case Load(address) =>` en la sección 4.

**`case object`.** Lo mismo para un `object`, que tiene una sola instancia: se imprime con su nombre (`Add`).

**Inmutables.** Las `case class` se usan para datos que no cambian. Matchear sobre algo mutable es un compromiso: la forma que miraste puede cambiar después. Scala te empuja hacia ahí: sus parámetros ya son campos de solo lectura.

Es tan cómodo que a veces se le pone `case` a clases que no lo necesitan, solo por el `toString` y el `==`.

> 🕳️ **Madriguera — matchear sin `case`**
> Los patrones de constante y de tipo andan con cualquier clase. Para el de constructor, sin `case` hay que escribir a mano el *extractor* (el método `unapply`). Para esta unidad, `case` es la forma de entrar.
> *Volvé al camino — esto se profundiza aparte, otro día.*

## 2. 🔴 Las instrucciones como datos

> Con pattern matching, las instrucciones pasan a ser **datos puros**: siete declaraciones, una por instrucción, sin ninguna operación adentro. Lo que en objetos era un antipatrón, el *data object*, acá es una decisión.

El archivo entero (`mutable/Instructions.scala`). `sealed` marca que todas las instrucciones están declaradas en este archivo; la sección 7 muestra para qué sirve.

```scala
package tadp.microprocesador.mutable

sealed trait Instruction

case object Add extends Instruction
case object Mul extends Instruction
case object Swap extends Instruction
case class Load(address: Int) extends Instruction
case class Store(address: Int) extends Instruction
case class If(subInstructions: List[Instruction]) extends Instruction
case object Halt extends Instruction
```

Lo que sigue en el módulo corre con `import tadp.microprocesador.mutable._`. Compará con el Módulo 5: ni `accept`, ni `Program`, ni un método por instrucción. Las que vienen sin parámetros son `case object`: su única gracia es existir y ser `Add`. `Load` y `Store` tienen una dirección, de solo lectura. `If` tiene la lista de instrucciones a ejecutar si se cumple la condición; la lista también es inmutable, y un programa es directamente una `List[Instruction]`.

En el Módulo 2, una clase que solo guarda datos y deja que otros operen sobre ella era un antipatrón de objetos. Acá las instrucciones quedaron chiquitas, tontas y limpias, a propósito: **lo que se va a hacer con ellas está afuera**, en funciones que miran su forma. Es el triángulo rojo, ahora con la herramienta para escribirlo. Las instrucciones no van a cambiar en todo el resto de la unidad.

Siguen siendo objetos. Si algún día conviene, se puede delegar en ellas. Lo que cambió es que la operación ya no está obligada a vivir adentro.

## 3. 🔴 `match`: una expresión que decide por la forma

> `valor match { case patrón => resultado ... }` prueba los patrones **en orden**, entra por el **primero que encaja** y el resultado de esa rama es el valor de todo el `match`.

Volvé al `A`/`B` del Módulo 3. Con `A` y `B` como datos, las operaciones se escriben así:

```scala
sealed trait I
case object A extends I
case object B extends I

def m1(unI: I): String = unI match {
  case A => "m1 de A"
  case B => "m1 de B"
}

def m2(unI: I): String = unI match {
  case A => "m2 de A"
  case B => "m2 de B"
}

m1(A)   // Resultado: m1 de A
m2(B)   // Resultado: m2 de B
```

Es el type check de la versión roja del Módulo 3, sin `isInstanceOf` ni `???`: la operación mira la forma de lo que recibe y elige. Con un `case object`, preguntar si es `A` y preguntar si es de tipo `A` es lo mismo, porque hay uno solo. La flecha `=>` separa el patrón de lo que se devuelve si encaja.

**Una expresión, no una sentencia.** El `match` devuelve un valor. Lo mismo hace el `if … else` de Scala: `if (c) 1 else 2` vale `1` o `2`. Se puede usar donde vaya cualquier expresión. En el ejemplo, `_` es el comodín: cualquier cosa, como en Haskell.

```scala
import tadp.microprocesador.mutable._

val unaInstruccion: Instruction = Add
val codigo = unaInstruccion match {
  case Add => 1
  case Mul => 2
  case _ => 3
}
codigo   // Resultado: 1
```

**La diferencia con Haskell.** En Haskell estabas acostumbrado a ver el pattern matching en la definición de la función: una ecuación por forma (`largo [] = 0`, `largo (_:cola) = …`). Es lógico, porque en Haskell solo se definen funciones. En Scala, `match` es una expresión que se aplica a cualquier valor, en cualquier lugar: al principio de una función, en el medio, en una variable. Se parece más a un `switch`, y como es una expresión, sirve en más lugares.

**Los tanques, cerrados.** El Módulo 2 dejó abierto que en estructurado el ataque era fácil: un proceso recibe los dos tanques y les mira la forma. Con `match`, eso se escribe así:

```scala
class Misil(val poder: Int)
sealed trait Tanque
case object Ligero extends Tanque
case object Pesado extends Tanque

def atacar(misil: Misil, atacante: Tanque, atacado: Tanque): String = atacante match {
  case Ligero => atacado match {
    case Ligero => s"ligero vs ligero: daño ${misil.poder}"
    case Pesado => s"ligero vs pesado: daño ${misil.poder / 2}"
  }
  case Pesado => atacado match {
    case Ligero => s"pesado vs ligero: daño ${misil.poder * 2}"
    case Pesado => s"pesado vs pesado: daño ${misil.poder}"
  }
}

atacar(new Misil(10), Ligero, Pesado)   // Resultado: ligero vs pesado: daño 5
atacar(new Misil(10), Pesado, Ligero)   // Resultado: pesado vs ligero: daño 20
```

Una función que recibe los dos y mira las dos formas: el doble despacho del Módulo 2 sobra.

## 4. 🔴 Los patrones

> Un patrón describe una **forma**. Puede ser un valor exacto, un constructor con variables adentro, un tipo, una lista con cabeza y cola, un comodín, y cualquiera puede llevar una **guarda** `if` que agrega una condición.

Una función de ejemplo sobre una instrucción, con las instrucciones del micro. `Nil` es la lista vacía (el `[]` de Haskell), y `s"…"` es el string con valores insertados que ya viste:

```scala
def describir(i: Instruction): String = i match {
  case Add => "suma"
  case Load(address) => s"carga la posición $address"
  case If(Nil) => "un IF vacío"
  case If(sub) => s"un IF con ${sub.size} instrucciones"
  case _ => "otra"
}

List(Add, Load(4), If(Nil), If(List(Add, Mul)), Mul).map(describir)
// Resultado: List(suma, carga la posición 4, un IF vacío, un IF con 2 instrucciones, otra)
```

| Patrón | Ejemplo | Encaja cuando… |
|---|---|---|
| **Constante** | `case Add =>` | el valor es exactamente `Add` (el `case object`) |
| **Constructor** | `case Load(address) =>` | es un `Load`; además, **liga** la variable `address` a lo que tiene adentro |
| **Tipo** | `case l: Load =>`, `case _: Load =>` | es de tipo `Load`; `l` queda ligada a la instrucción, ya con tipo `Load` (con `_`, si no te hace falta nombrarla) |
| **Lista** | `case cabeza :: cola =>`, `case Nil =>` | la lista tiene cabeza y cola, o está vacía (abajo) |
| **Comodín** | `case _ =>`, `case Load(_) =>` | siempre. `_` es "cualquier cosa, y no me interesa nombrarla"; también va adentro: `Load(_)` es "un `Load`, con cualquier dirección" |
| **Guarda** | `case … if condición =>` | el patrón encaja **y** la condición da `true` (abajo) |

Los patrones se meten unos dentro de otros: `If(Nil)` es un `If` cuya lista es la vacía.

El patrón de constructor es el que más se usa, y es al que Haskell te acostumbró: `Load(address)` pregunta "¿sos un `Load`?" y, si sí, abre la instrucción y te da su dirección en una variable. En un solo paso: preguntar el tipo, castear y leer el campo, las tres cosas que con `isInstanceOf` eran separadas.

El orden importa: entra por el primero que encaja. `If(Nil)` va antes que `If(sub)`, porque `If(sub)` encaja con cualquier `If`, vacío incluido.

**Listas: `::` y `Nil`.** Una lista tiene dos formas: vacía o cabeza-y-cola. En Scala, la vacía es `Nil` (el `[]` de Haskell), y "cabeza seguida de cola" se escribe `cabeza :: cola` (el `(cabeza:cola)` de Haskell). Son dos puntos dobles porque Scala usa el `:` simple para los tipos. Es al revés que en Haskell, donde `::` anotaba el tipo (`largo :: [a] -> Int`) y `:` armaba la lista. Sirve para construir y para matchear:

```scala
Add :: Mul :: Nil   // Resultado: List(Add, Mul)
```

```scala
def primeras(programa: List[Instruction]): String = programa match {
  case Nil => "programa vacío"
  case Swap :: Swap :: resto => s"dos SWAP y después ${resto.size} más"
  case Store(a1) :: Store(a2) :: _ if a1 == a2 => s"dos STORE a la misma dirección $a1"
  case (l: Load) :: _ => s"empieza con un LOAD a ${l.address}"
  case cabeza :: cola => s"empieza con $cabeza, siguen ${cola.size}"
}

primeras(Nil)                              // Resultado: programa vacío
primeras(List(Swap, Swap, Add, Mul))       // Resultado: dos SWAP y después 2 más
primeras(List(Store(1), Store(1), Add))    // Resultado: dos STORE a la misma dirección 1
primeras(List(Store(1), Store(2), Add))    // Resultado: empieza con Store(1), siguen 2
primeras(List(Load(7), Add))               // Resultado: empieza con un LOAD a 7
```

`Swap :: Swap :: resto` mira **dos** elementos a la vez: "una lista que empieza con dos `SWAP`, y al resto llamalo `resto`". Es lo que el `SimplifyVisitor` del Módulo 5 necesitaba y no podía tener: ver el par entero. Cada patrón se combina con los demás: constantes, constructores y tipos adentro de una lista. El patrón de tipo va entre paréntesis, `(l: Load) :: _`, para que el `:` del tipo no se mezcle con el `::` de la lista.

**Guardas.** `case Store(a1) :: Store(a2) :: _ if a1 == a2 =>` es una **guarda**: el patrón tiene que encajar **y** la condición dar `true`. En Haskell la guarda iba con `|`; acá, con `if`. Si la condición da `false`, el patrón falla y se sigue probando con los siguientes. Por eso `List(Store(1), Store(2), Add)` termina en la última rama.

Usa la palabra `if`, pero no funciona como un `if` adentro de la rama. Compará:

```scala
def conIfAdentro(programa: List[Instruction]): String = programa match {
  case Store(a1) :: Store(a2) :: _ =>
    if (a1 == a2) "dos STORE iguales" else "dos STORE distintos"
  case _ :: _ => "otra cosa"
  case Nil => "vacío"
}

conIfAdentro(List(Store(1), Store(2), Add))   // Resultado: dos STORE distintos
```

Acá el patrón encajó, y una vez que entraste a una rama, ya entraste: el `if` de adentro decide entre dos resultados de **esa** rama, y nunca se vuelve a buscar otro caso. La guarda, en cambio, es parte del patrón: si da `false`, el `match` sigue buscando. Cuando lo que querés es "si no se cumple, probá los otros casos", va guarda.

## 5. 🔴 Lo que el `match` arregla del `switch`

> En un `match`, cada rama es **cerrada**: termina sin caer en la siguiente, y las variables que crea son solo suyas. Los dos problemas del `switch` del Módulo 3 desaparecen por diseño.

**Sin caída al caso siguiente** (*fallthrough*)**.** En el `switch` del Módulo 3, olvidarse un `break` hacía que los `B` ejecutaran también la lógica de `C`. En un `match` eso es imposible: se entra por una sola rama, se evalúa y se sale con su valor. El `break` desaparece: cada rama termina sola.

**Variables por rama.** Una variable creada en una rama vive solo ahí:

```scala
def f(x: Int): Int = x match {
  case 1 =>
    val doble = 2
    doble
  case _ => doble
}
// ❌ Not found: doble
```

El *scope* compartido del `switch`, donde una variable de un caso quedaba visible en el otro, tampoco existe. Y las variables que liga cada patrón (`address`, `resto`, `a1`) son también solo de su rama.

## 6. 🟡 Sin casteos ni bandera

> El patrón de constructor pregunta la forma y entrega el contenido ya tipado; la operación mira el dato directamente y no necesita más estado que el suyo.

Del Módulo 3 al Módulo 5 hubo dos maneras de decidir por el tipo. Con `isInstanceOf` (Módulo 5, sección 3): preguntar, después castear con `asInstanceOf`, después leer el campo. Con Visitor: doble despacho para recuperar el tipo, y estado en el visitante para lo que no se podía mirar. Con `match` (esquema):

```
i match {
  case Load(address) => …   ya sabés que es un Load, y ya tenés su dirección
  …
}
```

Un paso. Y la operación es una función común: elige qué mirar y en qué orden. El Módulo 7 escribe las tres operaciones del micro así, y la diferencia con el Visitor salta a la vista.

## 7. 🔴 El aviso por el caso que falta: `sealed`

> Con un **`sealed trait`**, el compilador conoce todas las formas posibles y **avisa cuando un `match` se olvida alguna**. Es la respuesta a "¿cómo sabías qué funciones tocar?".

`sealed` antes de `trait` quiere decir que todas sus subclases directas tienen que estar en el mismo archivo: nadie puede agregar una desde afuera. Así el compilador sabe cuáles son, sin excepción.

Volvé al Módulo 3: aparece `C`. Lo agregás al archivo, y te olvidás de actualizar `m1`:

```scala
sealed trait I
case object A extends I
case object B extends I
case object C extends I

def m1(unI: I): String = unI match {
  case A => "m1 de A"
  case B => "m1 de B"
}
// ⚠️ match may not be exhaustive.
//    It would fail on pattern case: C
```

El compilador revisó todos los `match` sobre `I` y te dice cuál quedó incompleto y qué caso falta. Ya no hace falta el *Control F* ni rezar: la lista de lugares a tocar te la da él. Es un **aviso** (*warning*): el programa compila igual, así que hay que leer los avisos.

Ojo: un `case _` (o un `cabeza :: cola`) encaja con cualquier forma, y ahí el compilador no tiene nada que avisar. Un comodín al final apaga la alarma.

Sin `sealed`, el compilador ignora si hay más subclases en otro archivo, y calla:

```scala
trait I
class A extends I
class B extends I
class C extends I

def m1(unI: I): String = unI match {
  case _: A => "m1 de A"
  case _: B => "m1 de B"
}

m1(new C)   // Resultado: scala.MatchError: C@… (of class C) (compila sin aviso; explota al ejecutar)
```

Igual que el `???` del Módulo 3, explota en ejecución. Por eso las instrucciones del micro están declaradas `sealed trait Instruction`: el día que aparezca una octava, cada `match` que enumere las instrucciones caso por caso y se olvide de la nueva va a quedar marcado.

> 🕳️ **Madriguera — `sealed` y sus variantes**
> Scala 3 tiene también `enum`, otra forma de declarar un conjunto cerrado de formas, y hay detalles sobre qué cuenta como exhaustivo (guardas, tipos genéricos). Para esta unidad alcanza con `sealed trait` y sus `case class` y `case object` en el mismo archivo.
> *Volvé al camino — esto se profundiza aparte, otro día.*

**Para el parcial, si te preguntan:** *"¿Qué problemas del `switch` resuelve el `match` de Scala?"* Las ramas no caen en la siguiente, así que no hay `break` que olvidar. Cada rama tiene sus propias variables, así que no hay scope compartido. El patrón de constructor pregunta el tipo y entrega el contenido en un paso, sin casteo. Y si el tipo está declarado `sealed`, el compilador avisa en qué `match` falta un caso cuando aparece una forma nueva, en lugar de explotar en ejecución (salvo que el `match` tenga un comodín que lo atrape todo).

**Para el parcial, si te preguntan:** *"¿Qué agrega la palabra `case` a una clase?"* Es azúcar sintáctico: construcción sin `new`, los parámetros como campos de solo lectura, `equals`/`hashCode` por contenido, un `toString` legible, el método `copy` y lo necesario para usarla con patrones de constructor.

---

## Checkpoint

1. Enumerá lo que agrega `case` a una clase. ¿Cuál de esas cosas habilita el patrón de constructor? ¿Qué patrones andan igual sin `case`?
2. ¿Qué da `Load(2) == Load(2)` y qué da lo mismo con una clase común? ¿Por qué?
3. ¿Por qué las instrucciones como datos son un antipatrón en objetos y una decisión acá?
4. ¿En qué se diferencia el `match` de Scala del pattern matching de Haskell? ¿Qué ventaja tiene?
5. ¿Qué hace el patrón `Load(address)` que con `isInstanceOf` y `asInstanceOf` (Módulo 5, sección 3) llevaba tres pasos?
6. ¿Por qué `If(Nil)` tiene que ir antes que `If(sub)`?
7. ¿Qué es `Nil`? ¿Qué es `::`? ¿Por qué dos puntos dobles?
8. ¿Qué mira el patrón `Swap :: Swap :: resto`? ¿Por qué el `SimplifyVisitor` no podía hacer eso?
9. Explicá la diferencia entre una guarda y un `if` adentro de la rama, con un ejemplo donde den distinto.
10. ¿Qué pasa con el `break` y con las variables compartidas en un `match`?
11. ¿Qué significa `sealed`? ¿Qué avisa el compilador, y qué pasa si el `trait` no es `sealed`?

## Qué viene después

**Módulo 7:** las tres operaciones del micro (ejecutar, imprimir y simplificar) escritas con `match`, al lado de los visitantes del Módulo 5. Y el criterio para decidir cuándo usar polimorfismo y cuándo pattern matching.

**FIN DEL MÓDULO 6 — El lenguaje: case classes y pattern matching**
