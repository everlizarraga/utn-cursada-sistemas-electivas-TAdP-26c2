# Clase desde cero — Comportamiento vs estructura y mónadas — Módulo 4: Nivel 3, `fold`, recorrer sin saber cómo

**Unidad:** clase10 · **Lenguaje:** Scala 3.3.1 · **Archivos del proyecto:** `niveles/Nivel3Fold.scala`, `niveles/Monoide.scala` · **Densidad:** 🔴 pide una sesión con el código abierto (las secciones 4, 6 y 7 son 🟡: se leen de corrido)

---

## Sobre este documento

**Qué cubre.** El segundo paso atrás. Las cinco funciones del nivel 2 se usaban para una sola cosa, recorrer; el `fold` le pone nombre a eso y lo saca de las seis funciones. Qué es un `fold` (una semilla y una función de combinación), por qué la consulta queda escrita con `foldRight`, en qué se diferencian `foldLeft` y `foldRight` y cuándo importa, qué tiene que ver la semilla con el elemento neutro de una operación (y de ahí, el monoide), qué más hace un `fold` además de recorrer, y qué sigue acoplado a la lista después de todo esto.

**Qué no cubre.** Las operaciones con nombre propio (`filter`, `map`, `flatMap`). Son el Módulo 5.

## De dónde venís

Del Módulo 3: las cinco funciones, la consulta escrita sobre ellas, y la pregunta del cierre: ¿para qué se usan `head` y `tail`? De la unidad anterior: `foldLeft` sobre la lista de instrucciones del micro (`program.foldLeft(initialMicro) { (micro, instruction) => … }`). De Paradigmas: `foldl` y `foldr` de Haskell.

---

## 1. 🔴 Cabeza y cola se usaban para recorrer

> En las seis funciones, `head` y `tail` se usan para **una sola cosa**: pasar por cada elemento, hacer algo con él y seguir con el resto. Eso es recorrer, y es una idea que no depende de que haya cabeza y cola.

Mirá los usos. En `cursos`: "si está vacía, vacía; si no, tomo el primer elemento, le saco los cursos, y sigo recursivamente con la cola". En `inscriptos`: tomo el primero, hago algo, sigo con la cola. En `regulares`: tomo el primero, me fijo si cumple, sigo con la cola. Todas terminan llamándose a sí mismas con el resto, hasta que el resto está vacío. Son **visitas iterativas** de la lista: cada función pasa una vez por cada elemento.

Y acá la pregunta clave: cuando estás sacando los cursos de una materia, ¿te importa si esa materia es la primera, la última o una del medio? No. No te importa tomar *el primer* elemento; te importa que te den *cada* elemento, uno por vez, para hacer algo con él. "Primero, y después el resto, hasta que no queda nada" es **un algoritmo concreto** para pasar por todos los elementos, uno que la lista permite porque tiene orden. Un set no tiene ese algoritmo; pero a un set también le podés pedir "necesito pasar una vez por todos tus elementos", y él sabe hacerlo, sin orden. Pasar una sola vez por cada elemento no tiene nada que ver con que haya un orden.

Ese concepto, haber recorrido el conjunto, es una abstracción. Si el código estuviera acoplado a "esto se puede recorrer" en vez de a "esto tiene cabeza y cola", funcionaría con listas, sets, árboles, flujos de datos que llegan de a poco, lo que sea.

**Iterar, en funcional, tiene que llegar a algún lado.** En objetos ya tenés `foreach`: pasa por cada elemento y hace algo. Pero `foreach` está pensado para causar efecto: pasa por todos y no deja nada en el tipo de retorno (devuelve `Unit`). En funcional no hay efecto; entonces recorrer tiene que **producir un resultado**. Partís de una lista y llegás a un `R`: otra lista, un número, una función, lo que quieras. Para eso hace falta una lógica que convierta elementos en ese `R`.

## 2. 🔴 El `fold`: una semilla y una función de combinación

> `fold` recorre por vos. Le das **cómo combinar** lo que llevás acumulado con un elemento (`(R, T) => R`) y **con qué empezar** (la semilla, un `R`), y te devuelve el `R` final.

```
                ┌────────────────────────────────────────────────┐
  ( ▲ ▼ ◀ )  ──►│  fold    ⬡ semilla    ( ⬡ + △ ⇒ ⬡ ) combinar  │──►  ⬢
   la lista     └────────────────────────────────────────────────┘    un R
```

La función de combinación es la parte interesante: **dado un `R` y un `T`, dame el siguiente `R`**. Así se itera: vas elemento por elemento, mirando lo que venís acumulando y el elemento nuevo, y decidís el acumulado siguiente. Como cuando buscás el marcador de color más frío de una caja: tenés uno en la mano, agarrás otro, los comparás, te quedás con uno, agarrás el siguiente.

El problema es la primera vez: la función necesita dos cosas, un `R` y un `T`, y antes de arrancar no tenés ningún `R`. Por eso `fold` pide la **semilla**: lo primero contra lo que vas a combinar. La semilla también resuelve la lista vacía: si no hay elementos, el resultado es la semilla, y no hay ningún `if` que escribir.

Acá va con `foldRight`, cuya función recibe primero el elemento y después el acumulado; las dos firmas de Scala vienen enseguida, y la diferencia entre ellas está en la sección 4.

```scala
import tadp.niveles._

def regulares(alumnos: List[Alumno]): List[Alumno] =
  alumnos.foldRight(List.empty[Alumno])((alumno, regulares) =>
    if(alumno.regular) alumno::regulares else regulares
  )

regulares(List(Alumno("100", true), Alumno("101", false)))   // Resultado: List(Alumno(100,true))
regulares(Nil)                                               // Resultado: List()
```

Leelo así: "obtener los regulares es foldear los alumnos. Si no hay alumnos, no hay regulares: la semilla es la lista vacía. Y por cada alumno, dado el alumno y los regulares que encontré hasta ahora, si es regular lo agrego, si no, dejo lo que tenía". Eso es todo. Comparalo con el nivel 2: desaparecieron `isEmpty`, `head`, `tail` y la llamada recursiva. Ya no corrés el riesgo de un bucle infinito por olvidarte el caso de corte: el recorrido lo maneja `fold`, y vos solo describís **un paso**.

Como método de `List[T]` (la lista es el receptor, por eso la firma la omite): `fold : (R → T → R) → R → R`: la función de combinación, la semilla, el resultado. Scala la trae en dos versiones (hay más variantes, como `reduce`, que en lugar de semilla exige al menos un elemento para arrancar, o `scan`, que aparece en la sección 4; el concepto es siempre el mismo y cambia la forma para facilitar un uso):

```
foldLeft [R](semilla: R)(f: (R, T) => R): R      combina acumulado-con-elemento, de izquierda a derecha
foldRight[R](semilla: R)(f: (T, R) => R): R      combina elemento-con-acumulado, de derecha a izquierda
```

Otra forma de leer la firma, con un paréntesis: `fold : (R → T → R) → R → (List[T] → R)`. Con la combinación y la semilla, `fold` te devuelve **una función que convierte una lista en un `R`**; es la misma lectura currificada que el Módulo 5 hace con `map` y `filter`.

La diferencia entre las dos está en la sección 4. Las dos reciben la semilla en una primera lista de parámetros y la función en una segunda; eso es lo que permite escribir la función entre paréntesis o entre llaves, como en el `foldLeft` del micro.

## 3. 🔴 La consulta, con `fold`

> Las seis funciones, cada una como un `foldRight` con su semilla y su paso. Ninguna recorre: todas describen qué hacer con un elemento.

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
  // (el fold escrito a mano, de la sección 4, va acá en el proyecto)
}
```

```scala
import tadp.niveles.Nivel3Fold._

legajosDeRegularesEnElectivas(todasLasMaterias)   // Resultado: List(100, 102, 300, 301)
append(List(1, 2), List(3))                       // Resultado: List(1, 2, 3)
```

Mismo resultado que los niveles 1 y 2. Fijate `append`: la semilla es la lista de la derecha, y el paso es "poné este elemento adelante de lo que llevás". Al foldear `izq` desde la derecha, los elementos de `izq` van quedando adelante de `der`, en su orden.

**Por qué `foldRight` y no `foldLeft`.** Todas arman el resultado agregando adelante: con `::`, o con `append`, que por adentro es un `::` por elemento. Si recorrés de derecha a izquierda, el último elemento entra primero a la lista nueva, después el anteúltimo adelante de él, y así: el orden original se conserva. Con `foldLeft` el primero entraría primero y terminaría al final: la lista saldría invertida, y habría que darla vuelta o construir con `append`, que es más caro.

Y ahora mirá los seis `foldRight`: la parte de **cómo** ir paso a paso por la lista está resuelta y no aparece en el código. Dejó de depender de la cabeza, de la cola y del orden. Lo que queda escrito es la otra parte del problema, la del dominio: qué hacer con una materia, con un curso, con un alumno.

## 4. 🟡 `foldLeft` y `foldRight` no son lo mismo

> `foldLeft` tiene un resultado parcial después de cada elemento, y por eso se puede ir consumiendo un flujo a medida que llega. `foldRight` tiene que **llegar al final primero** y combinar de vuelta: recién tiene algo cuando llegó al fondo. Sobre una lista que termina, dan lo mismo si la operación lo permite; sobre un flujo que no termina, solo uno de los dos produce algo.

El `fold` escrito a mano, con pattern matching, muestra el mecanismo. Son dos ecuaciones: sobre la vacía, la semilla; sobre `x :: xs`, el mismo `fold` sobre `xs`, con la semilla ya combinada con `x`:

```scala
//   fold f e []     = e
//   fold f e (x:xs) = fold f (f e x) xs
def fold[T, R](f: (R, T) => R)(e: R)(lista: List[T]): R = lista match {
  case Nil => e
  case x :: xs => fold(f)(f(e, x))(xs)
}

fold[Int, Int]((acc, x) => acc + x)(0)(List(1, 2, 3))                 // Resultado: 6
fold[Int, String]((acc, x) => s"($acc + $x)")("e")(List(1, 2, 3))     // Resultado: (((e + 1) + 2) + 3)
```

⚠️ **Este `fold` a mano es un `foldLeft`.** Combina la semilla con el primer elemento, ese resultado con el segundo, y así: `(((e + 1) + 2) + 3)`. Es exactamente el `foldLeft` que `run` usa desde la unidad anterior. El `foldRight` es el otro:

```scala
List(1, 2, 3).foldLeft("e")((acc, x) => s"($acc + $x)")     // Resultado: (((e + 1) + 2) + 3)
List(1, 2, 3).foldRight("e")((x, acc) => s"($x + $acc)")    // Resultado: (1 + (2 + (3 + e)))

List(1, 2, 3).foldRight(List.empty[Int])((x, acc) => x :: acc)   // Resultado: List(1, 2, 3)
List(1, 2, 3).foldLeft(List.empty[Int])((acc, x) => x :: acc)    // Resultado: List(3, 2, 1)
```

El primer par muestra el orden de combinación: con `foldLeft` el paréntesis más interno tiene la semilla y el primer elemento; con `foldRight`, la semilla y el último. El segundo par es la consecuencia práctica de la sección 3: construir con `::` conserva el orden solo desde la derecha.

**Por qué importa.** `foldLeft` toma el primer elemento, lo combina y sigue: en cada paso tiene un resultado parcial. `foldRight` tiene que atravesar todo hasta el fondo, combinar el último con la semilla, y recién después volver hacia adelante; hasta llegar al fondo no tiene nada, y mientras tanto guarda todos los elementos que pasó. Sobre una lista que termina, es una diferencia de costo. Sobre algo que **no termina**, es la diferencia entre volver y quedarse colgado. Si estás procesando un flujo de datos que llega de a uno (una cola FIFO: el primero que entra es el primero que se atiende), `foldLeft` va produciendo resultados a medida que entran; `foldRight` espera un final que no llega. Con una pila LIFO (el último que entra es el primero que se atiende) lo que tenés a mano es el otro extremo, y el `fold` que sirve es el que arranca por ahí. Elegir el `fold` equivocado para la estructura equivocada va más allá de una optimización: el programa queda colgado.

Para verlo hace falta un flujo que no termina. `LazyList.from(1)` son todos los naturales desde 1, generados a medida que se piden; `scanLeft` es un `foldLeft` que entrega cada acumulado en vez de solo el final:

```scala
LazyList.from(1).take(3).toList                        // Resultado: List(1, 2, 3)
LazyList.from(1).scanLeft(0)(_ + _).take(5).toList     // Resultado: List(0, 1, 3, 6, 10)
```

Sobre los naturales infinitos funciona porque nunca necesita el último. Un `foldRight` sobre esa misma lista queda colgado, igual que un `foldLeft` que espere el resultado final: lo que sirve del `foldLeft` es que cada paso ya tiene un acumulado usable.

Esta es la razón de fondo de la pregunta del Módulo 2, "¿cuándo vas a cambiar la representación de una lista?": cuando trabajás mucho desde un extremo, la representación que te deja ese extremo a mano es la buena, y el `fold` que arranca por ahí también.

**Para el parcial, si te preguntan:** *"¿Qué diferencia hay entre `foldLeft` y `foldRight`?"* Los dos recorren la lista combinando un acumulado con cada elemento a partir de una semilla; `foldLeft` arranca por el primer elemento y tiene un acumulado parcial en cada paso; `foldRight` arranca por el último, así que tiene que llegar al final antes de combinar nada. Dan el mismo resultado cuando la operación es asociativa y la semilla es su neutro; con una operación como la resta, o construyendo con `::`, difieren (`foldRight` conserva el orden, `foldLeft` lo invierte). Sobre un flujo que no termina, solo `foldLeft` puede ir entregando acumulados.

## 5. 🔴 La semilla tiende a ser el elemento neutro

> La semilla de un `fold` suele ser **lo que no altera el resultado**: `0` para sumar, `1` para multiplicar, la lista vacía para construir una lista.

Repasá las semillas: `List.empty` en cinco de las seis funciones; en la sexta, `append`, es `der`, "la lista a la que todavía no le agregué nada". Si buscás el máximo de una lista de naturales, la semilla es un número ridículamente chico; si buscás el mínimo, uno ridículamente grande; si sumás, `0`; si contás, `0`.

```scala
List(3, 9, 2).foldLeft(Int.MinValue)((acc, x) => if (x > acc) x else acc)   // Resultado: 9
List("a", "b", "c").foldLeft(0)((acc, _) => acc + 1)                          // Resultado: 3
```

Ese "elemento que no altera" tiene nombre propio, y la sección que sigue se lo pone. Lo que importa acá es la idea: elegir la semilla es preguntarse qué valor deja la operación en paz.

## 6. 🟡 Eso tiene nombre: monoide

> Un tipo con una operación **cerrada y asociativa** que tiene un **elemento neutro** se llama **monoide**. Suma, producto y concatenación son tres monoides distintos; el neutro de cada uno es la semilla natural de su `fold`.

El "elemento que no altera" aparece en matemática discreta con ese nombre. Un **monoide** es un tipo `A` con una operación que cumple tres cosas:

1. **Cerrada:** combina dos `A` y da un `A`. En tipos: `(A, A) => A`. Sumar dos enteros da un entero.
2. **Asociativa:** `(a + b) + c` es lo mismo que `a + (b + c)`. No importa dónde pongas los paréntesis.
3. **Tiene elemento neutro:** un `A` tal que combinarlo con cualquier otro lo deja igual. El `0` de la suma; el `1` del producto.

Los números con la suma son un monoide; con el producto, otro. Y la idea va más allá de los números:

| Tipo | Operación | Neutro |
|---|---|---|
| `Int` | `+` | `0` |
| `Int` | `*` | `1` |
| `String` | `++` (concatenar) | `""` |
| `A => A` (funciones de un tipo en sí mismo) | composición (`.`) | la identidad, `a => a` |
| `Boolean` | `&&` | `true` |
| `Boolean` | `\|\|` | `false` |

En Haskell esa operación única tiene un símbolo, `<>`: `"a" <> "b"` es concatenar. Para los números hay que decir cuál de los dos monoides querés (`Sum` o `Product`), y para los booleanos lo mismo (`All` para `&&`, `Any` para `||`), porque la tabla muestra que un mismo tipo puede ser monoide de más de una manera. Un solo nombre, y una operación concreta por monoide.

En el proyecto, el monoide es un `trait` con las dos cosas que tiene que tener, y una instancia por fila:

```scala
package tadp.niveles

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

  def composicion[A]: Monoide[A => A] = new Monoide[A => A] {   // def y no object: necesita el A
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

Y acá se cierra el círculo con el `fold`: `combinarTodos` es un `foldLeft` cuya semilla es el neutro y cuyo paso es la operación. Sirve para cualquier monoide, sin saber cuál:

```scala
import tadp.niveles.Monoide._

combinarTodos(List(1, 2, 3, 4))(SumaInt)                        // Resultado: 10
combinarTodos(List(1, 2, 3, 4))(ProductoInt)                    // Resultado: 24
combinarTodos(List("ho", "la"))(ConcatenacionString)            // Resultado: hola
combinarTodos(List(true, false))(Conjuncion)                    // Resultado: false
combinarTodos(List(true, false))(Disyuncion)                    // Resultado: true
combinarTodos(List[Int => Int](_ + 1, _ * 10))(composicion[Int])(2)   // Resultado: 21
combinarTodos(List.empty[Int])(SumaInt)                         // Resultado: 0
combinarTodos(List.empty[Int])(ProductoInt)                     // Resultado: 1
```

(`f compose g` es "primero `g`, después `f`"; por eso con `_ + 1` y `_ * 10` sobre `2` sale `21`.) Fijate las dos últimas líneas: la lista vacía da el neutro, sin ningún caso especial. Eso es exactamente lo que la semilla hace en el `fold`.

**Por qué vale la pena nombrar una propiedad.** Suma, producto y concatenación parecen tres operaciones distintas, y lo son. Pero en el fondo son casos particulares de una misma cosa, y a los que piensan en funcional les gusta eso: tomar de la matemática propiedades que un código cumple, para poder decir "si este código es equivalente a este otro, puedo aplicar estas reglas". Un ejemplo concreto: cuando usás una operación que programaste vos (objeto, mensaje, parámetro), ¿da lo mismo con los paréntesis de un lado o del otro? ¿Y con los operandos al revés? Son dos propiedades distintas: **asociativa** es la de los paréntesis, **conmutativa** la del orden de los operandos. Nuestra forma de responder suele ser probar: escribir un test, cruzar los dedos, ver que más o menos da. Es rápido, y no es la mejor forma. Si te subís a un avión, no esperás que el piloto pruebe con cuál palanca se levanta el tren de aterrizaje. Ese "más o menos" al que estamos acostumbrados es lo que nos empuja al parche: cambiar algo, ver si da, cruzar los dedos. Si **sabés** que la operación es asociativa y que la semilla es su neutro, ya respondiste: `foldLeft` y `foldRight` dan lo mismo, sin probarlo. Y cuando trabajaste con suficientes operaciones asociativas, empezás a ver patrones, y sobre los patrones a generalizar. La resta, por ejemplo, es un caso en contra:

```scala
(10 - (5 - 2), (10 - 5) - 2)                         // Resultado: (7,3)
List("1", "2", "3").foldLeft("e")(_ + _)            // Resultado: e123
List("1", "2", "3").foldRight("e")(_ + _)           // Resultado: 123e
List("1", "2", "3").foldLeft("")(_ + _)             // Resultado: 123
List("1", "2", "3").foldRight("")(_ + _)            // Resultado: 123
```

Con la resta, `foldLeft` y `foldRight` dan distinto, y ninguna cantidad de tests te lo va a decir con más seguridad que la propiedad. Y la concatenación muestra la segunda mitad de la condición: es asociativa, pero con una semilla que no es el neutro los dos `fold` también difieren; con `""`, coinciden. Este tema vuelve en el Módulo 6, con nombre y todo.

**Para el parcial, si te preguntan:** *"¿Qué es un monoide? Dá ejemplos."* Un tipo con una operación cerrada (combina dos valores del tipo y da otro del tipo), asociativa (los paréntesis no cambian el resultado) y con elemento neutro (un valor que combinado con cualquier otro lo deja igual). Los enteros con la suma y el 0; con el producto y el 1; los strings con la concatenación y `""`; los booleanos con `&&` y `true`, o con `||` y `false`; las funciones de un tipo en sí mismo con la composición y la identidad. El neutro es la semilla natural de un `fold` con esa operación.

## 7. 🟡 `fold` también rompe: el catamorfismo

> Un `fold` cumple dos roles con una sola función. Es un **recorrido** (pasa por cada elemento) y es un **catamorfismo**: va de la lista a cualquier cosa, y rompe la cadena de listas.

"Cata" se suele leer como "romper" (literalmente, "hacia abajo"), "morfismo" es forma: romper la forma, colapsarla. A diferencia de las operaciones que van de lista en lista (las del Módulo 5), el `fold` **corta**: parte de una lista y llega a un `R` que puede ser un número, una lista, una función, lo que quieras. El máximo de la sección anterior es eso: una lista de números entra, un número sale, y ya no hay lista. Después de un `fold` se puede seguir operando como lista solo si el `R` resultó ser una lista.

Por eso `fold` sirve para analizar cosas de forma global (cuántos hay, cuál es el mayor, si todos cumplen algo), y no solo para visitar los elementos de a uno. Y por eso, al revés, es el que menos se parece de una estructura a otra: cada cosa se rompe según su forma. Esa idea vuelve en el Módulo 6, sobre una caja de un solo valor, y después en el 7 y el 8.

**Lo que se puede foldear.** El recorrido con resultado se puede implementar sobre cualquier cosa que tenga elementos adentro: una lista, un set, un árbol ("una lista con dos colas": no tiene cola, y se recorre), una caja con un valor, un flujo de datos que va llegando por un socket. A ese contrato (algo cuyo contenido se puede recorrer produciendo un resultado) se lo puede llamar **`Foldable`**:

```
┌───────────────────────────────────────────┐
│                 List[T]                   │
│  empty[T](): List[T]                      │
│  ::(elem: T): List[T]                     │
└───────────────────┬───────────────────────┘
                    ┆ (cumple)
                    ▽
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
               Foldable[T]
  foldLeft [R](semilla: R)(f: (R, T) => R): R
  foldRight[R](semilla: R)(f: (T, R) => R): R
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
```

```scala
Set(1, 2, 3).foldLeft(0)(_ + _)   // Resultado: 6
```

El set, sin orden, foldea igual. Un código escrito sobre `fold` funciona con él. El precio lo paga la estructura: ser foldeable es un contrato más exigente que "tener una forma" (hay que programarle el `fold`), igual que tener `head` y `tail` era más exigente que existir. Cada nivel pide más a la estructura y le pide menos al código que la usa.

## 8. 🔴 A qué estás acoplado ahora

> El recorrido ya no depende de la lista. Pero **construir el resultado** sí: la semilla `List.empty` y el `::` del paso son de listas. Hace falta que la cosa sea recorrible **y** concatenable, y eso son dos contratos superpuestos.

Volvé a `electivas`. La parte de "cómo ir paso a paso por cada materia" la resuelve `fold`: ahí desaparecieron cabeza y cola, y la materia podría venir en un set. Pero hay otra parte en el algoritmo: la que **arma el resultado**. Parte de materias, llega a electivas, y electivas es también una colección; en cada paso hay que meter la materia en la colección resultante, y eso se hace con `::`. Y la semilla es `List.empty`. Si mañana la cosa a devolver fuera un set, habría que cambiar la semilla y cambiar cómo se construye.

Es una complejidad que aparece seguido: a veces no alcanza con un solo contrato. Para esta consulta no alcanza con que algo sea recorrible: hace falta que además sea **concatenable**, que se pueda armar de a pedazos. Son dos propiedades distintas, una arriba de la otra, y el código las necesita a las dos. (Ese "concatenable" va a tener nombre en el Módulo 6, `plus`, y va a ser la operación de un monoide: el `combinar` de la sección 6.)

De paso, mirá que `cursos` e `inscriptos` usan `append` y `electivas` y `regulares` usan `::`. `append` entiende de listas y entendería de sets; `::` es solo de listas. Nada te frena de usar la operación más específica donde alcanzaba la general, y es la misma trampa del Módulo 3: cada nivel te deja bajar al anterior sin avisar.

Y la pregunta de siempre, un nivel más arriba. Es difícil, porque mirás ese código y pensás: ¿a dónde más se puede ir? Ya está, esto es todo lo abstracto que puede ser. La respuesta es que siempre se puede dar un paso más; lo único que hace falta es encontrar cómo se está **usando** el `fold`. Acá no se itera de cualquier manera: se itera de unas pocas formas concretas, y cada una de esas formas tiene nombre.

**Para el parcial, si te preguntan:** *"¿Qué resuelve `fold` que el nivel de `head`/`tail` no resolvía, y qué deja sin resolver?"* `fold` encapsula el recorrido: el código ya no dice cómo pasar por los elementos (cabeza, cola, caso de corte), sino solo qué hacer con uno (el paso) y desde dónde empezar (la semilla). Con eso deja de depender de que haya orden, y funciona sobre cualquier cosa recorrible (set, árbol, flujo). Deja sin resolver la construcción del resultado: la semilla y el `::` siguen siendo de listas, así que el código sigue acoplado a devolver una lista.

---

## Checkpoint

1. ¿Para qué se usaban `head` y `tail` en las seis funciones? ¿Por qué eso no necesita un orden?
2. ¿Por qué en funcional recorrer tiene que llegar a un `R`? Compará con `foreach`.
3. ¿Qué dos cosas recibe un `fold`? ¿Para qué sirve la semilla, y qué problema resuelve en la lista vacía?
4. ¿Por qué la consulta usa `foldRight` y no `foldLeft`? ¿Qué pasaría con `foldLeft`?
5. Escribí las dos ecuaciones del `fold` a mano. ¿Cuál de los dos `fold` de `List` es?
6. ¿Por qué `foldRight` tiene que llegar al fondo primero? ¿Qué pasa con cada uno sobre un flujo que no termina?
7. ¿Qué tres propiedades tiene un monoide? Dá tres ejemplos que no sean con números.
8. ¿Qué relación hay entre el neutro de un monoide y la semilla de un `fold`?
9. ¿Por qué vale la pena saber que una operación es asociativa, en vez de probarla?
10. ¿Qué es un catamorfismo? ¿En qué se diferencia `fold` de una operación que va de lista en lista?
11. ¿A qué sigue acoplado el código del nivel 3? ¿Qué dos contratos necesita la consulta?

## Qué viene después

El Módulo 5 mira **cómo** se usa el `fold` en las seis funciones y descubre que son solo tres maneras: filtrar, transformar, y transformar aplanando. Les pone nombre (`filter`, `map`, `flatMap`), y con eso la consulta queda en una sola expresión.

**FIN DEL MÓDULO 4 — Nivel 3, `fold`, recorrer sin saber cómo**
