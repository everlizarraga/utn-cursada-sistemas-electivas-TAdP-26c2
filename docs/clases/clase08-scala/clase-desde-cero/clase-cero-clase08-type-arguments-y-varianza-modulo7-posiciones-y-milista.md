# Clase desde cero — Type arguments y varianza en Scala — Módulo 7: El precio de poner un `+`: posiciones

**Unidad:** clase08 · **Lenguaje:** Scala 3.3.1 · **Densidad:** 🔴 pide una sesión con el código abierto

---

## Sobre este documento

**Qué cubre.** Qué pasa cuando el `+` lo ponés vos. Se escribe una lista covariante desde cero, `MiLista[+T]`, y el compilador rechaza el primer método que recibe un `T` con un error que todavía no viste: `covariant type T occurs in contravariant position`. De ahí salen las **posiciones**: dónde puede aparecer un parámetro covariante, dónde uno contravariante, y una tercera posición (invariante) que obliga a sacar el `Set` de adentro del corral. La salida para los métodos que reciben `T`: un parámetro de tipo **del método** con lower bound, `[U >: T]`, que es para lo que servía el piso del Módulo 4. La doble inversión que hace que `filter(f: T => Boolean)` compile aunque reciba algo con `T` adentro. Y, con todo eso, por qué el `Set` inmutable del Módulo 5 es invariante.

**Qué no cubre.** La ejecución de la lista: en este módulo todo se juzga por el compilador, y el Módulo 9 la termina con un caso vacío y la ejecuta. El corral terminado es el Módulo 8.

## De dónde venís

Del Módulo 6: covarianza en el resultado, contravarianza en el parámetro; "lo que sale" y "lo que entra"; `A => B`. Del Módulo 5: `List[+A]`, el `+` como anotación, el contraejemplo del caballo y su versión con cast. Del Módulo 4: `T >: X` y la pregunta "¿dónde puedo usar `T` adentro?". Del Módulo 3: los métodos también pueden tener parámetros de tipo.

---

## 1. 🔴 `+` es una intención, y se paga

> Anotar un parámetro con `+` o `-` **declara** una varianza; el compilador la acepta solo si **cada uso de `T` adentro de la clase es compatible** con ella. El precio de `+T` es que `T` deja de poder aparecer donde entra un valor.

En el Módulo 5 viste que `List` lleva `+A` y `Set` lleva `A` a secas. Es tentador pensar que a `Set` "le faltó el `+`". Si fuera así de simple, le pondrías `+` a todo y `Corral[Vaca]` sería `Corral[Animal]` sin más vueltas. El `+` **se declara**, pero no se otorga gratis: el compilador revisa cada lugar donde `T` aparece y rechaza la clase si algún uso contradice la varianza declarada. La lista que sigue existe para ver ese chequeo funcionando.

## 2. 🔴 `MiLista[+T]`, desde el constructor

> Un parámetro del constructor con `T` es válido en una clase covariante. Un `val` también. Un `var` no: tiene un *setter*, y un setter **recibe** un `T`.

```scala
class MiLista[+T](primero: T, cola: MiLista[T]) {    // ✅ compila: T solo aparece en retornos y en el constructor
  def head: T = primero
  def tail: MiLista[T] = cola
}
```

Una lista hecha de un primer elemento y una cola que es otra lista: la forma de la lista de Haskell. `primero` y `cola` son parámetros del constructor sin `val`: existen adentro de la clase y nada más; `head` y `tail` los exponen. (A esta lista todavía le falta un caso vacío; por eso en este módulo se compila y se lee, y en el Módulo 9 se completa y se corre.)

| Escribís | Scala entiende | Sale |
|---|---|---|
| `class MiLista[+T](primero: T, cola: MiLista[T])` | un valor de tipo `T` que se recibe **al construir** | ✅ |
| `class MiLista[+T](val primero: T, val cola: MiLista[T])` | lo mismo, y además se puede leer desde afuera | ✅ un `val` solo sale |
| `class MiLista[+T](var primero: T, cola: MiLista[T])` | lo mismo, y además se puede **asignar** desde afuera | ❌ `covariant type T occurs in contravariant position in type T of parameter primero_=` |
| `def head: T` | un `T` que sale | ✅ |

El constructor es una excepción a lo que viene: recibe un `T`, y sin embargo es válido. **Por qué.** El argumento del constructor se entrega a un objeto que **todavía no existe**; una referencia ancha (`MiLista[Animal]`) solo puede existir sobre una lista ya construida, y por ahí la entrada está cerrada. El peligro de la covarianza es siempre el mismo del Módulo 5: dos referencias de distinto tipo al mismo objeto ya construido. El `var` sí cae, porque genera un método `primero_=` que recibe un `T` sobre un objeto que ya existe.

## 3. 🔴 El primer método que recibe `T`: `add`

> Un método de una clase `+T` **no puede recibir un `T`** como parámetro. El error es `covariant type T occurs in contravariant position`: el parámetro de un método es una posición contravariante, y `T` está declarado covariante.

```scala
class MiLista[+T](primero: T, cola: MiLista[T]) {
  def add(elem: T): MiLista[T] = new MiLista(elem, this)
  //      ^^^^^^^
  // ❌ covariant type T occurs in contravariant position in type T of parameter elem
}
```

Leé el error despacio, porque lo vas a ver muchas veces: "el tipo covariante `T` aparece en una posición contravariante, en el tipo `T` del parámetro `elem`". Dice tres cosas: `T` es covariante (vos lo pusiste); un parámetro de método es una **posición contravariante** (lo del Módulo 6: lo que entra varía al revés); y las dos cosas chocan.

**Por qué choca, con el programa que explotaría.** Este `add` devuelve una lista nueva y por sí mismo es inofensivo. El problema es que el compilador chequea la **firma**, porque cualquier subclase puede redefinir el cuerpo. Supongamos que lo dejara pasar, y que alguien escribe una lista de vacas que, al agregar, ordeña:

```scala
// ❌ hipotético: solo compilaría si el compilador aceptara add(elem: T); es lo que pasaría si cediera
class MiListaDeVacas(primero: Vaca, cola: MiLista[Vaca]) extends MiLista[Vaca](primero, cola) {
  override def add(elem: Vaca): MiLista[Vaca] = {   // válido: en una lista de vacas, elem es Vaca
    elem.ordeñate
    new MiLista(elem, this)
  }
}

  val listaDeVacas: MiListaDeVacas = new MiListaDeVacas(new Vaca, ???)
  val animales: MiLista[Animal] = listaDeVacas            // válido: +T dice que MiLista[Vaca] es MiLista[Animal]
  animales.add(new Caballo)                        // válido: add de una MiLista[Animal] recibe un Animal
  // en ejecución: caballo.ordeñate                // 💥
```

Cada línea es válida para el tipo declarado de su variable; la combinación explota. Es el contraejemplo del Módulo 5 con otra ropa: la covarianza deja que una referencia ancha (`MiLista[Animal]`) apunte a un objeto angosto (`MiListaDeVacas`), y un método que **recibe** `T` es la puerta por la que entra el caballo. El compilador cierra esa puerta en la firma, sin mirar el cuerpo. Se puede reproducir de verdad con un cast, igual que en el Módulo 5: con una versión invariante de esta lista y un `asInstanceOf[MiLista[Animal]]`, `add(new Caballo)` sobre una `MiListaDeVacas` termina en `ClassCastException: class tadp.granja.Caballo cannot be cast to class tadp.granja.Vaca`.

**Dicho como regla.** Marcar `T` con `+` te permite usarlo en **posiciones covariantes** (lo que sale: retornos) y te lo prohíbe en **posiciones contravariantes** (lo que entra: parámetros). Marcarlo con `-` es al revés:

```scala
abstract class Printer[-T] {
  def print(t: T): Unit            // ✅ T entra
  def ultimo: T                    // ❌ contravariant type T occurs in covariant position in type => T of method ultimo
}
```

Por eso la función es el buen ejemplo para acordarse: `Function1[-T1, +R]` tiene el `-` donde entra y el `+` donde sale. Si tu tipo tiene un `T` que entra y sale, le queda invarianza, o separar las dos cosas como se ve en la sección 5.

## 4. 🔴 La tercera posición: invariante

> Un `T` metido adentro de un tipo **invariante** (`Set[T]`) está en **posición invariante**: sirve solo para un parámetro invariante. Por eso un corral covariante tiene que guardar una `List[T]` y no un `Set[T]`.

```scala
class Corral[+T <: Animal](val animales: Set[T])
//                         ^^^^^^^^^^^^^^^^^^^^
// ❌ covariant type T occurs in invariant position in type Set[T] of value animales
```

Un `val` solo sale, así que la posición del `val` es covariante; pero el `T` está adentro de un `Set[T]`, y `Set` es invariante respecto de su parámetro: un `Set[Vaca]` y un `Set[Animal]` quedan sin relación. Si el corral fuera covariante, un `Corral[Vaca]` visto como `Corral[Animal]` expondría su `Set[Vaca]` como `Set[Animal]`, que es justo lo que el Módulo 5 prohibió. Vale igual para el `Set` mutable y para el inmutable: los dos son invariantes. Y si además se saca el `<: Animal`, un `gordos` como el del Módulo 4 vuelve a fallar con `value estaGordo is not a member of T`: el bound y la varianza son dos chequeos independientes, y cada uno da su propio error.

Con `List[T]` adentro, en cambio, un `Corral[Vaca]` visto como `Corral[Animal]` expone una `List[Vaca]` como `List[Animal]`, y eso es legal porque `List` es covariante. La posición de un `T` dentro de otro tipo **hereda la varianza de ese tipo**: adentro de `List[T]` es covariante; adentro de `Set[T]`, invariante; adentro del parámetro de una función, contravariante (sección 6).

El Módulo 8 arranca exactamente acá: el corral terminado cambia su `Set[T]` por `List[T]` por esta razón, independiente del pastor.

## 5. 🔴 La salida: un parámetro de tipo del método con lower bound

> Un método de una clase `+T` que necesita recibir "algo del tipo de la lista" recibe **`U`**, un parámetro de tipo propio del método, con **`U >: T`**: cualquier supertipo de `T`, `T` incluido. El resultado se expresa en `U`.

Primero el caso donde la salida es además la respuesta correcta, no un truco: concatenar dos listas.

```scala
class MiLista[+T](primero: T, cola: MiLista[T]) {
  def concat(otra: MiLista[T]): MiLista[T] = ???
  //         ^^^^^^^^^^^^^^^^
  // ❌ covariant type T occurs in contravariant position in type tadp.granja.MiLista[T] of parameter otra
}
```

Mismo error: `otra` entra, y trae un `T`. Pero pensá qué tipo tendría que tener de verdad una concatenación. Una lista de vacas más una lista de caballos ¿es una lista de qué? De animales: el tipo común más cercano, como cuando un `Set` con vaca y caballo se infería `Set[Animal]` (Módulo 2). El problema de `concat(otra: MiLista[T])` es que **pide lo incorrecto**: exige que la otra lista sea exactamente del mismo tipo, cuando lo razonable es aceptar cualquier lista y devolver una del tipo común.

```scala
class MiLista[+T](primero: T, cola: MiLista[T]) {
  def concat[U >: T](otra: MiLista[U]): MiLista[U] = ???     // ✅
}

  val vacas: MiLista[Vaca] = ???
  val caballos: MiLista[Caballo] = ???
  val n: Int = vacas.concat(caballos)
  // ❌ Found:    tadp.granja.MiLista[tadp.granja.Animal]      ← el compilador infirió U = Animal
  //    Required: Int
```

Tres cosas pasan acá. **(1)** `[U >: T]` después del nombre del método: un parámetro de tipo del método (Módulo 3, sección 6), que vive solo durante la llamada. **(2)** El lower bound `U >: T` ata `U` a `T`: `U` es `T` o algo más arriba. Si concatenás vacas con vacas, `U = Vaca`; vacas con caballos, el compilador sube hasta `Animal`, la clase común; vacas con números, donde ninguna clase común sirve, infiere la unión `Vaca | Int` (Módulo 2), y el resultado es una `MiLista[Vaca | Int]`, que es exactamente lo que es. Una aclaración sobre la forma: `U >: T` es la misma relación que `T <: U`, escrita desde el lado de `U`, que es la letra que se declara; "lower bound" acá es la manera de decir "`U` está por arriba de `T`". **(3)** El conflicto con la covarianza desaparece: el parámetro de `concat` es de tipo `MiLista[U]`, y `U` es un parámetro del método, que **queda fuera de la pregunta de varianza**. La varianza es una propiedad de los parámetros de tipo de una clase, respecto de cómo se relacionan dos instancias de esa clase; `U` existe durante una llamada, y la pregunta de varianza directamente no se le aplica.

Esto es para lo que servía el piso del Módulo 4. Allá, `T >: VacaLoca` sobre una clase restringía el corral a una rama y parecía inútil. Acá, `U >: T` sobre un **método** dice "aceptá cualquier cosa que esté por arriba de lo que esta lista contiene, y calculá el tipo común". Y como `U` solo puede subir desde `T`, el método sigue sin poder tratar al argumento como algo más específico que `T`: `otra` es una `MiLista[U]` con `U` por arriba, y nada de lo que se haga con ella puede suponer que trae vacas. La puerta de la sección 3 sigue cerrada.

**Lo que el precio compra.** Con ese costo llega un grado de seguridad que hasta acá era impensable. En la clase anterior, el camino para usar una colección de vacas donde se esperaba una de animales era el cast, y cada cast es una promesa que el compilador deja de vigilar; cuando castear es casi inevitable, el tipado estático pierde su razón de ser. Acá una `MiLista[Vaca]` sirve donde se espera una `MiLista[Animal]` **sin un solo cast**, a cambio de restringir el contrato a operaciones incapaces de romperlo. Es la promesa *sound* del Módulo 1, cumplida sobre tipos paramétricos.

El `map` es el otro método que necesita un parámetro de tipo propio, por una razón más simple: devuelve una lista de **otra** cosa.

```scala
  def map[U](f: T => U): MiLista[U] = ???            // ✅ U sin bound: el resultado es de cualquier tipo
```

`map` (Módulo 3) aplica una función a cada elemento y devuelve la lista de los resultados; si la función va de `Vaca` a `Int`, sale una `MiLista[Int]`. `U` es libre porque el tipo de los resultados puede ser cualquiera. Y el `T` de `f: T => U` está en una posición que la sección siguiente explica.

> **Para el parcial, si te preguntan**
> *En `class MiLista[+T]`, `def add(elem: T): MiLista[T]` no compila. ¿Por qué y qué le ponés?* — Porque `T` es covariante y el parámetro de un método es una posición contravariante: si se permitiera, una `MiLista[Vaca]` vista como `MiLista[Animal]` dejaría entrar un caballo por `add`. La salida es un parámetro de tipo del método con lower bound, `def add[U >: T](elem: U): MiLista[U]`: acepta el elemento, calcula el tipo común (`Vaca` con `Caballo` da `Animal`) y devuelve una lista de ese tipo. `U` es del método y queda fuera de la pregunta de varianza, así que el conflicto desaparece sin abrir la puerta.

## 6. 🔴 `filter` compila: la doble inversión

> Un `T` dentro del **parámetro de una función que se recibe como parámetro** está en posición contravariante dos veces, y dos inversiones dan **covariante**. Por eso `filter(f: T => Boolean)` es válido en una clase `+T`.

```scala
class MiLista[+T](primero: T, cola: MiLista[T]) {
  def filter(f: T => Boolean): MiLista[T] = ???       // ✅ compila
}
```

A primera vista esto debería fallar: `f` es un parámetro, entra, y tiene un `T` adentro. Mirá dónde está el `T` exactamente: en `T => Boolean`, el `T` es **el parámetro de `f`**. Y el parámetro de una función es una posición contravariante (Módulo 6: `Function1[-T1, +R]`). Entonces el `T` está en la posición contravariante de algo (`f`) que a su vez está en la posición contravariante del método. Una inversión dentro de otra inversión **vuelve al sentido original**: ese `T` queda en posición covariante, y `+T` ahí es legal.

La regla general es la de los signos al multiplicar: cada vez que entrás en una posición contravariante, el sentido se da vuelta; dos vueltas es el sentido original. Sobre la firma de `filter`:

```
   filter (f: T => Boolean): MiLista[T]
                 │                   │
                 │                   └── retorno: posición covariante (+)
                 │
                 └── parámetro de f, que es parámetro de filter: (−) · (−) = (+)
```

Y el contraste, que confirma la regla: un `T` en el **resultado** de la función recibida está en posición (−)·(+) = (−), y falla:

```scala
  def mal(f: Int => T): Unit = ()
  //      ^^^^^^^^^^^
  // ❌ covariant type T occurs in contravariant position in type Int => T of parameter f
```

| Escribís | Scala entiende | Sale |
|---|---|---|
| `def head: T` | un `T` en el retorno: (+) | ✅ |
| `def add(elem: T)` | un `T` en un parámetro: (−) | ❌ |
| `def filter(f: T => Boolean)` | un `T` en el parámetro del parámetro: (−)(−) = (+) | ✅ |
| `def mal(f: Int => T)` | un `T` en el retorno del parámetro: (−)(+) = (−) | ❌ |
| `def bien2(f: (Int => T) => Int)` | un `T` en el parámetro del parámetro del parámetro: (−)(−)(+) = (+) | ✅ |
| `val animales: Set[T]` | un `T` adentro de un tipo invariante: sin signo | ❌ posición invariante |

La última fila de la tabla y las dos de `map` y `concat` de la sección 5 son las que vas a necesitar en el TP. Las otras son para que la regla se entienda: no hace falta memorizarla, hace falta poder reconstruirla.

**Una ayuda del compilador.** La varianza se chequea en una pasada **posterior** a la del resto de los tipos. Si tu archivo tiene otro error de tipos, los errores de varianza aparecen recién cuando ese se arregla. Cuando un `+` "deja de compilar" después de corregir otra cosa, es esto.

## 7. 🔴 Por qué el `Set` inmutable es invariante

> Un `Set[A]` de Scala **es también una función** `A => Boolean` (preguntar si un elemento pertenece). Una función recibe `A` en posición contravariante; con eso, `Set` queda sin poder ser covariante.

Es la deuda del Módulo 5, sección 6. Ahí viste que un `Set[Vaca]` se asigna a una variable `Vaca => Boolean`. Eso significa que `Set` extiende a `Function1`, y el parámetro de esa función es el propio `A`:

```scala
trait MiSet[+A] extends (A => Boolean)
// ❌ covariant type A occurs in contravariant position in type Object with (A => Boolean) {...} of trait MiSet
```

El `Object with (A => Boolean) {...}` del error es el tipo padre del trait, escrito como el compilador lo ve: un objeto que es además una función de `A`. Un `A` que aparece como parámetro de la función que el conjunto *es*, en posición contravariante, con `+A` declarado: el compilador lo rechaza igual que rechazó `add`. Con cero operaciones que agreguen, el `Set` inmutable **tendría** derecho a ser covariante; lo que se lo impide es haber elegido ser una función de sus elementos. Es una decisión de diseño de la biblioteca, con un costo (invarianza) y un beneficio (`vacas(unaVaca)` responde si pertenece). `List` eligió distinto: su `contains` recibe `[A1 >: A]`, la salida de la sección 5, y conserva el `+`.

## 8. 🟡 Lo que viene

> Con las posiciones claras, el `Corral[+T <: Animal]` terminado se lee entero.

El Módulo 8 pone el `+` en el corral, cambia el `Set[T]` por `List[T]` (sección 4), y escribe `contiene` de seis formas: dos que fallan (`T` y `[U <: T]`) y cuatro que compilan (`[U]` libre, `[U <: Animal]`, `[U >: T]` y `[U >: T <: Animal]`), para elegir con fundamento. Y muestra que `var animales` en un corral covariante tampoco compila, por la misma razón que el `var` de la sección 2.

---

## Checkpoint (sin respuestas)

1. ¿Qué chequea el compilador cuando declarás `+T`? ¿Qué quiere decir que el `+` "se paga"?
2. `class MiLista[+T](primero: T, …)` compila y `class MiLista[+T](var primero: T, …)` no. ¿Por qué el constructor es una excepción y el `var` no?
3. Leé en voz alta `covariant type T occurs in contravariant position in type T of parameter elem`. ¿Qué tres cosas dice?
4. Construí el programa que explotaría si `add(elem: T)` se permitiera en `MiLista[+T]`. ¿Por qué el compilador chequea la firma y no el cuerpo?
5. ¿Qué es una posición invariante? ¿Por qué `val animales: Set[T]` falla en un corral `+T`, si un `val` solo sale?
6. Escribí `concat` para `MiLista[+T]`. ¿Qué tipo tiene `vacas.concat(caballos)` y por qué? ¿Qué varianza tiene `U`?
7. ¿Para qué servía, entonces, un lower bound? Relacionalo con el experimento del Módulo 4.
8. `filter(f: T => Boolean)` compila en una clase `+T`. Explicalo con la regla de los signos. ¿Y `mal(f: Int => T)`?
9. ¿Por qué el `Set` inmutable de Scala es invariante, si le falta `add`? ¿Qué eligió distinto `List`?
10. Tenés un tipo propio donde `T` aparece en un parámetro y en un retorno. ¿Qué opciones tenés?

## Qué viene después

El Módulo 8 escribe el corral final, `Corral[+T <: Animal](val animales: List[T])`, con `gordos` y `contiene[U >: T]`, exactamente como está en `Corral.scala`, y compara las firmas posibles de `contiene` para decidir cuál conviene.

**FIN DEL MÓDULO 7**
