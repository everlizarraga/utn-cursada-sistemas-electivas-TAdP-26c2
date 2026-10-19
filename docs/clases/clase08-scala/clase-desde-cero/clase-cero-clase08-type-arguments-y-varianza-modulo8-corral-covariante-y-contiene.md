# Clase desde cero — Type arguments y varianza en Scala — Módulo 8: `Corral[+T]` terminado: `contiene` y la decisión de diseño

**Unidad:** clase08 · **Lenguaje:** Scala 3.3.1 · **Densidad:** 🔴 pide una sesión con el código abierto

---

## Sobre este documento

**Qué cubre.** El corral tal como queda en `Corral.scala`: `Corral[+T <: Animal](val animales: List[T])`, con `gordos` y `contiene`. Por qué el `Set[T]` se va y entra `List[T]`; el pastor y el lechero andando juntos; `Corral[Vaca]` por fin como `Corral[Animal]`. Después, la decisión de diseño que esta unidad te pide saber tomar: `contiene` escrito de seis formas (dos que fallan y cuatro que compilan), con lo que cada una acepta, rechaza y permite hacer adentro, incluida una diferencia que solo aparece al inferir. La relación con el `contains` de `List`. Y dos variantes que no compilan y conviene saber por qué: `cruzar(toro: T)` y `var animales`.

**Qué no cubre.** La lista completa con su caso vacío, el límite de la teoría y la guía de decisión para el TP: Módulo 9.

## De dónde venís

Del Módulo 7: posiciones covariante, contravariante e invariante; `[U >: T]` en un método; la regla de los signos. Del Módulo 5: el pastor arreglado a medias y `Corral[T]` invariante por omisión. Del Módulo 4: `gordos: Set[T]` y el experimento del lower bound. Del Módulo 2: Scala 3 infiere uniones. El código de este módulo usa `List` y el `Set` inmutable: **se terminó el `import` mutable**.

---

## 1. 🔴 De `Set[T]` a `List[T]`, y el `+`

> El corral terminado guarda una `List[T]` y declara `+T`. Con eso, un `Corral[Vaca]` **es** un `Corral[Animal]`, el pastor pastorea y el lechero ordeña el mismo corral.

El estado final de `Corral.scala`, menos `contiene`, que es la sección 3:

```scala
package tadp.granja

class Corral[+T <: Animal](val animales: List[T]) {

  def gordos: List[T] = animales.filter(_.estaGordo)
}

class Pastor {
  def pastorear(animales: List[Animal]): Unit = animales.foreach(_.come)
}

class Lechero {
  def ordeñar(corral: Corral[Vaca]): Unit = corral.animales.foreach(_.ordeñate)
}
```

Tres cambios respecto del Módulo 4 (el primero y el tercero ya aparecieron en el Módulo 5, sección 5), cada uno con su motivo:

1. **`Set[T]` → `List[T]`.** Es la posición invariante del Módulo 7: con `+T`, un `val animales: Set[T]` falla con `covariant type T occurs in invariant position`. `List` es covariante, y un `T` adentro de una `List[T]` en un `val` es posición covariante. Legal.
2. **`+T`.** Es lo que faltaba en el Módulo 5: sin el `+`, `Corral[Vaca]` y `Corral[Animal]` eran dos tipos ajenos entre sí aunque adentro hubiera una lista inmutable. El compilador acepta el `+` porque todos los usos de `T` en la clase son covariantes: `List[T]` en un `val`, y `List[T]` en el retorno de `gordos`.
3. **El pastor pide `List[Animal]`.** Antes pedía `Set[Animal]`; con el corral guardando listas, recibe listas.

```scala
  val corralito: Corral[Vaca] = new Corral(List(new Vaca, new VacaLoca))
  val lechero: Lechero = new Lechero
  val pastor: Pastor = new Pastor

  pastor.pastorear(corralito.animales)                   // el pastor, el lechero y la referencia ancha, sobre el mismo corral
  lechero.ordeñar(corralito)

  val corralDeAnimales: Corral[Animal] = corralito
  println(corralDeAnimales.animales.map(_.peso))         // Resultado: List(100, 100)   ← comió (+10) y se ordeñó (−10)
```

El hilo del pastor se cierra entero: el pastor y el lechero trabajan sobre **el mismo** `corralito`, y además el corral de vacas entra donde se pide uno de animales. Es el test 9 de `GranjaTest.scala`, y los tests 6 y 7 son el lechero y el pastor sobre este corral.

**Lo que se pagó.** Mirá la tabla:

| | `Corral[T <: Animal](val animales: Set[T])` (Módulo 4) | `Corral[+T <: Animal](val animales: List[T])` |
|---|---|---|
| `Corral[Vaca]` donde se pide `Corral[Animal]` | ❌ | ✅ |
| `corralito.animales` donde se pide una colección de animales | ❌ (`Set` invariante) | ✅ (`List` covariante) |
| ¿Se puede agregar un animal a un corral existente? | sí, por `animales.add` | no: la lista es inmutable; se construye otro corral |
| ¿Un método puede recibir un `T`? | sí | no: posición contravariante |

Las dos últimas filas son el precio, y la última es el tema de la sección siguiente.

## 2. 🔴 `contiene(t: T)` se rechaza, y qué pasaría si entrara

> El método más natural del corral, "¿contiene este animal?", recibe un `T`, y en un corral `+T` eso **falla**. Si entrara, un corral de vacas visto como corral de animales recibiría un caballo.

```scala
class Corral[+T <: Animal](val animales: List[T]) {
  def contiene(t: T): Boolean = animales.contains(t)
  //           ^^^^
  // ❌ covariant type T occurs in contravariant position in type T of parameter t
}
```

El programa que explotaría es el del Módulo 7, sección 3, con nombres de corral:

```scala
  val c: Corral[Vaca] = new Corral(List(new Vaca))   // un corral de vacas
  val c2: Corral[Animal] = c                          // válido con +T: el mismo corral, visto como de animales
  c2.contiene(new Caballo)                            // válido para un Corral[Animal]: contiene recibe Animal
```

Si `contiene(t: T)` existiera, acá `t` sería un caballo entrando a un método que, en un corral de vacas, tiene todo el derecho de tratar a `t` como vaca (una subclase podría ordeñarla). Igual que con `add`: la firma abre la puerta, y el compilador la cierra en la firma.

Dos variantes que también fallan y aparecen cuando uno tantea:

| Escribís | Scala entiende | Sale |
|---|---|---|
| `def contiene(t: T): Boolean` | recibir un `T` | ❌ `covariant type T occurs in contravariant position in type T of parameter t` |
| `def contiene[U <: T](t: U): Boolean` | recibir "un `T` o algo más específico" | ❌ `covariant type T occurs in contravariant position in type  <: T of type U` (el doble espacio es del compilador: ahí iría el nombre del tipo, y un bound suelto va sin nombre) |
| `def cruzar(toro: T): Corral[T]` | recibir un `T` y devolver un corral | ❌ `covariant type T occurs in contravariant position in type T of parameter toro` |

La segunda es la que todo el mundo prueba: "que `U` sea un subtipo de `T`". Falla porque **el upper bound de un parámetro de tipo de método también es una posición contravariante**: `U <: T` es, en el fondo, una forma de recibir `T` por abajo. Lo que sí se puede es acotar `U` por arriba con `T` abajo, y eso es la sección siguiente.

## 3. 🔴 Las firmas posibles de `contiene`, comparadas

> Hay varias formas de escribir `contiene` que compilan en un corral `+T`. Difieren en **qué argumentos aceptan**, en **qué se le puede hacer a `elem` adentro**, y en una trampa que solo aparece **al inferir**. Elegir es una decisión de diseño.

Cuatro firmas que compilan, sobre el mismo corral de vacas:

```scala
  val c: Corral[Vaca] = new Corral(List(new Vaca))
```

| Firma | `c.contiene(new Caballo)` | `c.contiene(123)` (inferido) | `c.contiene[Int](123)` (explícito) | `c.contiene[AnyRef]("vaca")` | Adentro, `elem` entiende… |
|---|---|---|---|---|---|
| `[U](elem: U)` | ✅ `false` | ✅ `false` | ✅ `false` | ✅ `false` | solo lo de `Any` (`==`, `hashCode`) |
| `[U <: Animal](elem: U)` | ✅ `false` | ❌ `Found: (123 : Int) / Required: tadp.granja.Animal` | ❌ `Type argument Int does not conform to upper bound tadp.granja.Animal` | ❌ `Type argument AnyRef does not conform to upper bound tadp.granja.Animal` | lo de `Animal` (`come`, `peso`) |
| `[U >: T](elem: U)` (la de `Corral.scala` y la de `List.contains`) | ✅ `false` | ✅ `false` — infiere `U = Vaca \| Int` | ❌ `Type argument Int does not conform to lower bound tadp.granja.Vaca` | ✅ `false` | solo lo de `Any` |
| `[U >: T <: Animal](elem: U)` | ✅ `false` | ❌ `Found: (123 : Int) / Required: tadp.granja.Vaca` | ❌ `Type argument Int does not conform to upper bound tadp.granja.Animal` | ❌ `Type argument AnyRef does not conform to upper bound tadp.granja.Animal` | lo de `Animal` |

Leé la tabla por columnas.

**Un caballo en un corral de vacas** entra en las cuatro. Es la limitación de fondo: con `+T`, ninguna firma puede exigir "exactamente `T`" al recibir, así que preguntar si un corral de vacas contiene un caballo siempre compila y siempre da `false`. La varianza te hizo pagar esa precisión.

**Un número**, la columna que importa. Con `[U]` libre entra, y la pregunta "¿el corral contiene 123?" compila: es la señal de que la firma deja pasar cualquier cosa. Con `[U >: T]`, el caso explícito `contiene[Int](123)` se rechaza, y parece que el lower bound protege; pero el caso **inferido**, `contiene(123)`, compila: el compilador busca un `U` que esté por arriba de `Vaca` y admita un `Int`, y encuentra la unión `Vaca | Int` (Módulo 2). El lower bound solo protege contra quien escribe el argumento de tipo a mano. Con `[U <: Animal]` y con `[U >: T <: Animal]`, el número se rechaza siempre, porque ningún `U` que admita un `Int` cabe debajo de `Animal`.

**Un `AnyRef`** (el supertipo de todos los objetos) muestra la otra cara: `[U >: T]` lo acepta, porque está por arriba de `Vaca`; las firmas con techo `Animal` lo rechazan.

**Adentro del método**, con `[U >: T]` el parámetro solo entiende los mensajes de `Any`: el compilador sabe que `U` es `Vaca` o algo por arriba, y por arriba de `Vaca` puede haber cualquier cosa; `elem.come` falla con `value come is not a member of U`. Con techo `Animal`, `elem.come` compila.

**Entonces, ¿cuál?** Depende de qué querés garantizar:

- `[U >: T]` es la elección de la biblioteca (`List.contains`) y la del código de referencia: la más permisiva que sigue atada a `T`, suficiente para preguntar por pertenencia, que solo necesita `==`. Su garantía real es débil, y vale saberlo.
- `[U >: T <: Animal]` es la más fina para este dominio: acepta cualquier animal, rechaza todo lo que esté fuera de la jerarquía, inferido o explícito, y adentro deja hablar en términos de `Animal`. Es la respuesta de diseño que conviene tener lista para el individual.
- `[U <: Animal]` acepta lo mismo pero **desata** `U` de `T`: funciona igual acá, y pierde la expresión "por arriba de lo que este corral contiene", que es la que hace que `concat` y `add` del Módulo 7 devuelvan el tipo común. Para un `Boolean` da lo mismo; para un método que devuelve `Corral[U]`, no.

**Explícito e inferido, con el mismo corral de animales.** Una última sutileza del `[U >: T]`, que confunde si no se vio:

```scala
  val ca: Corral[Animal] = new Corral[Animal](List(new Vaca))

  ca.contiene(new Vaca)                 // ✅ infiere U = Animal, y una vaca es un animal
  ca.contiene[Vaca](new Vaca)
  // ❌ Type argument tadp.granja.Vaca does not conform to lower bound tadp.granja.Animal
```

Sobre un corral de animales, `U` tiene que ser `Animal` o superior; `Vaca` está por **abajo**. Si dejás inferir, el compilador elige `Animal` y anda; si escribís `[Vaca]`, lo rechaza. Escribir el argumento de tipo a mano solo sirve para pedir algo distinto de lo que el compilador elegiría, y acá lo que elegiría es lo correcto.

> **Para el parcial, si te preguntan**
> *Aparece `def contiene(animal: T): Boolean` en `Corral[+T <: Animal]` y no compila. ¿Qué le ponés y qué te garantiza cada opción?* — El error es que `T` es covariante y el parámetro es posición contravariante. La salida es un parámetro de tipo del método: `def contiene[U >: T](animal: U)` compila, acepta cualquier supertipo de `T` y es la firma de `List.contains`, pero su garantía es débil (`contiene(123)` compila porque el compilador infiere `Vaca | Int`, y adentro `animal` solo entiende `Any`). `def contiene[U >: T <: Animal](animal: U)` es la más fina: rechaza cualquier cosa fuera de la jerarquía, explícita o inferida, deja usar los mensajes de `Animal` adentro y mantiene a `U` atado a `T`. Ninguna puede rechazar un caballo en un corral de vacas: ese es el precio de la covarianza.

## 4. 🔴 `List.contains` está hecho igual

> El `contains` de la `List` de Scala tiene la firma `contains[A1 >: A](elem: A1): Boolean`: la misma solución, con el mismo límite.

```scala
  val listaDeVacas: List[Vaca] = List(new Vaca)

  println(listaDeVacas.contains(new Caballo))      // Resultado: false   ← compila: A1 = Animal
  println(listaDeVacas.contains("una vaca"))       // Resultado: false   ← compila: A1 = Vaca | String
  listaDeVacas.contains[Int](123)
  // ❌ Type argument Int does not conform to lower bound tadp.granja.Vaca
```

La biblioteca eligió `[A1 >: A]` para conservar el `+A` de `List`, y aceptó la misma garantía débil que viste en la tabla. Cuando uses `contains` sobre una lista y te deje pasar algo que "no debería", ahora sabés por qué: es el precio que `List` pagó por ser covariante, y lo pagó en cada método que recibe un elemento.

## 5. 🔴 `var animales` en un corral covariante

> Con `+T`, un `var` de tipo `List[T]` **falla**: el setter recibe la lista, y una lista de `T` que entra es posición contravariante. Covarianza y `var` sobre `T` son incompatibles.

Podrías querer un corral al que se le cambien los animales, dejando la lista inmutable y mutando el corral:

```scala
class Corral[+T <: Animal](var animales: List[T])
//                         ^
// ❌ covariant type T occurs in contravariant position in type List[T] of parameter animales_=
```

Es el `var primero` del Módulo 7 otra vez. Y vale la pena ver que es el contraejemplo del caballo, un nivel más arriba: con `var`, un `Corral[Vaca]` visto como `Corral[Animal]` aceptaría `c2.animales = List(new Caballo)`, y el corral de vacas tendría un caballo. La inmutabilidad de la **lista** protegía a la lista; la del **corral** protege al corral. Elegir dónde hay efecto colateral y dónde no es una decisión de diseño con consecuencias de tipo: en un corral invariante, `val` o `var` es cuestión de gusto; en uno covariante, `var` sobre `T` es imposible.

| Escribís | Scala entiende | Sale |
|---|---|---|
| `class Corral[T <: Animal](var animales: List[T])` | corral invariante con lista reemplazable | ✅ |
| `class Corral[+T <: Animal](var animales: List[T])` | corral covariante con lista reemplazable | ❌ `covariant type T occurs in contravariant position in type List[T] of parameter animales_=` |
| `class Corral[+T <: Animal](val animales: List[T])` | corral covariante con lista fija | ✅ (`Corral.scala`) |

> **Para el parcial, si te preguntan**
> *¿Puede un `Corral[+T]` tener `var animales: List[T]`?* — Es imposible: el `var` genera un setter que recibe una `List[T]`, un parámetro es posición contravariante, y `T` es covariante; el compilador lo rechaza. Si el corral tiene que poder cambiar sus animales, hay dos salidas: dejarlo invariante (`Corral[T]`, y entonces `Corral[Vaca]` deja de ser `Corral[Animal]`), o mantenerlo inmutable y construir un corral nuevo con un método `[U >: T <: Animal]` que devuelva `Corral[U]`.

## 6. 🟡 `cruzar`, resuelto

> Un método que recibe un animal y devuelve un corral nuevo se escribe con el mismo `[U >: T <: Animal]`, y el tipo del corral resultante es el tipo común.

Es la tercera fila de la tabla de la sección 2, con su solución:

```scala
class Corral[+T <: Animal](val animales: List[T]) {
  def cruzar[U >: T <: Animal](toro: U): Corral[U] = new Corral(animales.prepended(toro))   // ✅
}

  val vacas: Corral[Vaca] = new Corral(List(new Vaca))
  val conOtraVaca: Corral[Vaca] = vacas.cruzar(new Vaca)      // U = Vaca; en la línea siguiente, U = Animal
  val conCaballo = vacas.cruzar(new Caballo)
```

`animales.prepended(toro)` es "una lista nueva con `toro` adelante de `animales`". La forma corta, que es la que vas a ver en todo el código Scala, es `toro :: animales`: el `::` es el constructor de lista de Haskell con otro nombre, y las dos líneas hacen exactamente lo mismo. El corral no cambia; se construye otro, del tipo común entre lo que tenía y lo que entró. Esta forma, método con `[U >: T <: Animal]` que devuelve `Corral[U]`, es la plantilla para **cualquier** método de un corral covariante que reciba un animal: en el Módulo 9 la vas a escribir de nuevo, con otro nombre (`agregar`), como ejercicio.

## 7. 🟡 Lo que viene

> Queda terminar `MiLista` con su caso vacío, decir con precisión hasta dónde llega todo esto, y armar la guía para decidir en el TP.

Los tests 11 y 12 de `GranjaTest.scala` verifican `contiene` sobre el corral final: encuentra a una vaca que está, rechaza a otra vaca y a un caballo con `false`, y `contiene[Int](123)` **no compila**.

---

## Checkpoint (sin respuestas)

1. ¿Por qué el corral final guarda `List[T]` y no `Set[T]`? ¿Qué error da la otra opción?
2. ¿Por qué `Corral[Vaca]` pasa a ser `Corral[Animal]`? ¿Qué tuvo que cumplir la clase para que el compilador aceptara el `+`?
3. ¿Qué se pagó por el `+`? Nombrá las dos cosas que el corral del Módulo 4 podía hacer y este no.
4. `contiene[U <: T](t: U)` también falla. ¿Por qué?
5. Con `[U >: T]`, `contiene[Int](123)` se rechaza y `contiene(123)` compila. ¿Qué infiere el compilador y por qué?
6. ¿Qué entiende `elem` adentro de `contiene[U >: T]`? ¿Y adentro de `contiene[U >: T <: Animal]`?
7. ¿Qué firma de `contiene` elegirías para el corral y por qué? ¿Qué pierde `[U <: Animal]` respecto de `[U >: T <: Animal]`?
8. ¿Qué argumento aceptan las cuatro firmas sin excepción, y por qué?
9. ¿Cómo está escrito `List.contains`? ¿Qué pasa con `listaDeVacas.contains("una vaca")`?
10. ¿Por qué `var animales: List[T]` falla en `Corral[+T]` y compila en `Corral[T]`? ¿Qué decisión de diseño hay detrás?
11. Escribí `cruzar` para `Corral[+T <: Animal]`. ¿De qué tipo es `vacas.cruzar(new Caballo)`?

## Qué viene después

El Módulo 9 completa `MiLista` con `Vacia` y `Nodo`, exactamente como `MiLista.scala`, muestra que `Vacia` sirve como lista de cualquier cosa gracias a `Nothing` y la covarianza, pone el límite de la teoría (`contains` sería seguro y el compilador no lo permite), y cierra con la guía de decisión en tres preguntas y dos ejercicios del dominio.

**FIN DEL MÓDULO 8**
