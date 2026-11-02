# Clase desde cero — Comportamiento vs estructura y mónadas — Módulo 3: Nivel 2, las cinco funciones (el tipo abstracto)

**Unidad:** clase10 · **Lenguaje:** Scala 3.3.1 · **Archivos del proyecto:** `niveles/Nivel2TipoAlgebraico.scala`, `niveles/ListaSnoc.scala` (sus operaciones, y `Nivel2SobreSnoc` al final del archivo) · **Densidad:** 🔴 pide una sesión con el código abierto

---

## Sobre este documento

**Qué cubre.** El primer paso atrás: esconder la forma de la lista detrás de cinco funciones (`isEmpty`, `head`, `tail`, `empty` y `::`), reescribir la consulta sin ningún `match`, y volver a cambiar la representación para ver qué se rompe ahora: cinco funciones, y nada más. Por qué son esas cinco y no otras, qué tienen de parciales dos de ellas, qué es un tipo abstracto de datos, la trampa que aparece en este nivel y en todos los siguientes, y a qué queda acoplado el código.

**Qué no cubre.** Cómo dejar de recorrer a mano. Eso es el `fold`, en el Módulo 4.

## De dónde venís

Del Módulo 2: las dos formas de la lista (`Nil` y `::`), las seis funciones con pattern matching, la lista *snoc* (`VaciaSnoc`, `Snoc`, `:+`, `last`, `init`), y el diagnóstico: el código quedó acoplado a la forma, que no es parte del problema. De la unidad 08: `[U >: T]` en un método, "un tipo al menos tan amplio como `T`", que la varianza exige cuando una lista covariante recibe un elemento.

---

## 1. 🔴 Reemplazar el pattern matching por funciones

> Lo único que el pattern matching hacía sobre la lista era **tres cosas**: preguntar si está vacía, sacar la cabeza y la cola, y construir (vacía, o elemento más lista). Cada una se puede pedir con una función, y entonces el `match` desaparece del código.

El Módulo 2 cerró con un diagnóstico: el código depende de la forma de la lista, y hay que mover ese acoplamiento. Si la lista deja de trabajarse por su forma, ¿con qué se la trabaja? En funcional queda una sola otra cosa: funciones. Entonces hay que ver qué funciones equivalen a lo que el `match` hacía.

Repasá cualquiera de las seis funciones del nivel 1. El `match` hacía, en este orden: (1) distinguir el caso `Nil` del caso `cabeza :: cola`, que es **preguntar si está vacía**; (2) en el segundo caso, **sacar la cabeza y la cola**; (3) del lado derecho de la flecha, **construir** una lista nueva, con `Nil` o con `::`. Nada más.

Tres cosas, cinco funciones:

| Lo que hacía el `match` | Función | Qué devuelve |
|---|---|---|
| Distinguir `Nil` de `cabeza :: cola` | `isEmpty` | `true` o `false` |
| Sacar la cabeza | `head` | el primer elemento |
| Sacar la cola | `tail` | la lista sin el primero |
| Construir la lista vacía | `empty` | una lista sin elementos |
| Construir elemento + lista | `::` | una lista con un elemento más adelante |

Las listas de Scala ya las tienen:

```scala
List(1, 2, 3).isEmpty      // Resultado: false
List.empty[Int].isEmpty    // Resultado: true
List(1, 2, 3).head         // Resultado: 1
List(1, 2, 3).tail         // Resultado: List(2, 3)
List.empty[Int]            // Resultado: List()
0 :: List(1, 2)            // Resultado: List(0, 1, 2)
```

Con eso, el `case Nil => …` / `case cabeza :: cola => …` se convierte en un `if (lista.isEmpty) … else …`, y `cabeza` y `cola` pasan a ser `lista.head` y `lista.tail`. La traducción es **mecánica**: no hay que pensar, se reemplaza.

## 2. 🔴 La consulta, sin ningún `match`

> Las seis funciones del nivel 1, reescritas con las cinco funciones. Mismo algoritmo, misma recursión; cambió solo la forma de preguntar y de desarmar.

```scala
package tadp.niveles

object Nivel2TipoAlgebraico {

  def append[T](izq:List[T], der:List[T]):List[T] =
    if(izq.isEmpty) der
    else izq.head::append(izq.tail, der)

  def electivas(materias:List[Materia]):List[Materia] =
    if(materias.isEmpty) List.empty
    else if (materias.head.electiva)
      materias.head::electivas(materias.tail)
    else electivas(materias.tail)

  def cursos(materias:List[Materia]):List[Curso] =
    if(materias.isEmpty) List.empty
    else append(materias.head.cursos, cursos(materias.tail))

  def inscriptos(cursos:List[Curso]):List[Alumno] =
    if(cursos.isEmpty) List.empty
    else append(cursos.head.inscriptos,inscriptos(cursos.tail))

  def regulares(alumnos:List[Alumno]):List[Alumno] =
    if(alumnos.isEmpty) List.empty
    else if(alumnos.head.regular)
      alumnos.head::regulares(alumnos.tail)
    else regulares(alumnos.tail)

  def legajos(alumnos:List[Alumno]):List[String] =
    if(alumnos.isEmpty) List.empty
    else alumnos.head.legajo::legajos(alumnos.tail)

  def legajosDeRegularesEnElectivas(todasLasMaterias: List[Materia]): List[String] =
    legajos(regulares(inscriptos(cursos(electivas(todasLasMaterias)))))
}
```

```scala
import tadp.niveles._
import tadp.niveles.Nivel2TipoAlgebraico._

legajosDeRegularesEnElectivas(todasLasMaterias)   // Resultado: List(100, 102, 300, 301)
```

(`todasLasMaterias` son los datos de prueba del Módulo 2.) Da lo mismo que el nivel 1, y tiene que dar lo mismo: es el mismo algoritmo. Lo que desapareció es todo `Nil` y todo `cabeza :: cola` del lado izquierdo de una flecha. El código pregunta y desarma **a través de funciones**, no mirando la forma.

Comparalo con el nivel 1 y vas a ver que es una traducción casi literal, línea por línea. Es igual de claro e igual de repetitivo: la repetición sigue estando exactamente igual (todas preguntan `isEmpty`, todas parten en `head` y `tail`). Lo que ganó está en otro lado.

## 3. 🔴 `head` y `tail` son parciales; `isEmpty` es su guardián

> `head` y `tail` son funciones **parciales**: tienen respuesta solo para la lista con elementos. `isEmpty` está en la lista de cinco justamente para poder preguntarlo antes de llamarlas.

```scala
List.empty[Int].head   // Resultado: java.util.NoSuchElementException: head of empty list
List.empty[Int].tail   // Resultado: java.lang.UnsupportedOperationException: tail of empty list
```

Una función **parcial** tiene valor solo para algunos argumentos de su tipo: `head` recibe cualquier `List[T]`, y para una vacía carece de respuesta. En el nivel 1 este problema no existía: el `match` pedía cabeza y cola solo adentro del caso `cabeza :: cola`, donde seguro había. Acá la protección hay que ponerla a mano, y por eso cada función arranca con `if (x.isEmpty)`. `isEmpty` está en la lista por necesidad: es lo que dice cuándo es seguro llamar a las otras dos.

> 🕳️ **Madriguera — por qué `head` lanza y no devuelve otra cosa**
> Hay otras formas de diseñar `head` para que no explote (devolver algo que pueda estar vacío, por ejemplo). Acá `head` es parcial a propósito, como en Haskell.
> *Volvé al camino — llega en el Módulo 7.*

## 4. 🔴 Cambiar la representación, otra vez

> Con la consulta escrita sobre las cinco funciones, cambiar la lista por la *snoc* **rompe las cinco funciones y nada más**. Los usos siguen andando con el tipo cambiado en la firma.

Es la prueba del nivel 2. En el Módulo 2, cambiar `List` por `ListaSnoc` rompió las seis funciones enteras, porque todas hablaban de `Nil` y `::`. Ahora las seis funciones hablan de `isEmpty`, `head`, `tail`, `empty` y `::`. Si `ListaSnoc` responde a esas cinco, la consulta anda tal cual.

¿Las responde? `isEmpty`, sí: es trivial (`VaciaSnoc` es la vacía, `Snoc` no). `empty`, sí. Y `head`, `tail` y `::` **hay que calcularlos**, porque la forma *snoc* tiene `last` e `init` a mano, y la cabeza del otro lado:

```scala
package tadp.niveles

sealed trait ListaSnoc[+T] {
  def isEmpty: Boolean
  def last: T
  def init: ListaSnoc[T]
  def :+[U >: T](elem: U): ListaSnoc[U] = Snoc(this, elem)

  def head: T = if(init.isEmpty) last else init.head
  def tail: ListaSnoc[T] = if(init.isEmpty) init else init.tail :+ last
  def ::[U >: T](elem: U): ListaSnoc[U] =
    if(isEmpty) this :+ elem else (elem :: init) :+ last
}

case object VaciaSnoc extends ListaSnoc[Nothing] {
  def isEmpty = true
  override def head = throw new NoSuchElementException("head de una ListaSnoc vacía")
  override def tail = throw new UnsupportedOperationException("tail de una ListaSnoc vacía")
  def last = throw new NoSuchElementException("last de una ListaSnoc vacía")
  def init = throw new UnsupportedOperationException("init de una ListaSnoc vacía")
}

case class Snoc[+T](init: ListaSnoc[T], last: T) extends ListaSnoc[T] {
  def isEmpty = false
}

object ListaSnoc {
  def empty[T]: ListaSnoc[T] = VaciaSnoc
}
```

Cómo se calcula `head` sobre esta forma: una lista *snoc* es "todo lo anterior" (`init`) y "el último" (`last`). Si no hay nada anterior, el último es también el primero. Si hay, la cabeza está en algún lado de `init`, y se le pregunta a `init` por su cabeza, recursivamente, hasta llegar a un `Snoc` cuyo `init` está vacío. `tail` es parecido: si no hay anterior, la cola es la vacía; si hay, es la cola de lo anterior con el último agregado al final. Y `::` (agregar adelante) mete el elemento adentro de `init`, recursivamente, y vuelve a poner `last` al final.

Calculada o a mano, es la misma cabeza. "Tiene un primer elemento, tiene un resto, puede estar vacía" es la definición de lista, independiente de la representación. En una forma la cabeza sale gratis y en la otra hay que ir a buscarla; una representación incapaz de responderla dejaría de ser una lista.

```scala
import tadp.niveles._

val unoDosTres = VaciaSnoc :+ 1 :+ 2 :+ 3
unoDosTres.head       // Resultado: 1
unoDosTres.tail       // Resultado: Snoc(Snoc(VaciaSnoc,2),3)
0 :: unoDosTres       // Resultado: Snoc(Snoc(Snoc(Snoc(VaciaSnoc,0),1),2),3)
unoDosTres.isEmpty    // Resultado: false
VaciaSnoc.head        // Resultado: java.util.NoSuchElementException: head de una ListaSnoc vacía
```

Sobre el código, tres cosas en una línea cada una. `[+T]` hace covariante la lista, para que `VaciaSnoc` sea una `ListaSnoc[Nothing]` que sirve como vacía de cualquier tipo; por eso `:+` y `::` llevan `[U >: T]`: el elemento que entra puede ser de un tipo más amplio, y la lista resultante es de ese tipo. `override` en `head` y `tail` de `VaciaSnoc` reemplaza el cálculo general por un error claro, igual que `List`. Y `(elem :: init) :+ last` lleva paréntesis porque `::` y `:+` se asocian hacia lados distintos y Scala exige decidir.

**Ahora la prueba.** `regulares` y `legajos` del nivel 2, con el mismo cuerpo, sobre la otra lista. Lo único que cambia es el tipo en la firma y la lista vacía con la que se construye:

```scala
// en el proyecto, al final de ListaSnoc.scala
object Nivel2SobreSnoc {

  def regulares(alumnos: ListaSnoc[Alumno]): ListaSnoc[Alumno] =
    if(alumnos.isEmpty) ListaSnoc.empty
    else if(alumnos.head.regular)
      alumnos.head::regulares(alumnos.tail)
    else regulares(alumnos.tail)

  def legajos(alumnos: ListaSnoc[Alumno]): ListaSnoc[String] =
    if(alumnos.isEmpty) ListaSnoc.empty
    else alumnos.head.legajo::legajos(alumnos.tail)
}
```

```scala
val alumnos = VaciaSnoc :+ Alumno("100", true) :+ Alumno("101", false) :+ Alumno("102", true)
Nivel2SobreSnoc.legajos(Nivel2SobreSnoc.regulares(alumnos))   // Resultado: Snoc(Snoc(VaciaSnoc,100),102)
```

Funciona. El cuerpo de las funciones es el del nivel 2, salvo el nombre de la vacía. Lo que se rompió al cambiar la representación fueron **cinco funciones** (`isEmpty`, `head`, `tail`, `empty`, `::`), que hubo que escribir para la lista nueva, y son fáciles. Todo lo demás, todos los usos, volvió a andar solo.

Eso es lo que ganó el nivel 2: **encapsulamiento**, en el sentido funcional. La forma de la lista quedó detrás de las cinco funciones. El pattern matching sigue existiendo, pero del otro lado de la puerta. Ya te lo corrigieron en Paradigmas: cuando modelabas un dato tuyo y escribías todo con pattern matching, la corrección era "no lo hagas así, definí funciones para trabajarlo; si cambia la estructura, solo cambiás esas funcioncitas". Esto es eso, con nombre.

## 5. 🔴 Las cinco funciones son el pattern matching, hecho funciones

> Las cinco funciones no son una elección arbitraria: son **la reificación del pattern matching**. Cada cosa que el `match` hacía sobre la forma tiene una función que la hace. Por eso con ellas se puede hacer todo lo que se podía hacer con la lista, sin demostrar nada.

Reificar es convertir en una cosa, en un valor del lenguaje, algo que antes era un mecanismo. El pattern matching era un mecanismo: deconstruir y elegir. Las cinco funciones son ese mecanismo convertido en cinco valores que se pueden llamar.

De ahí sale la respuesta a "¿por qué esas cinco y no otras?": porque son exactamente lo que el pattern matching sabía hacer. Es la pregunta del Módulo 1, respondida para la lista: lo mínimo son estas cinco. `isEmpty` distingue las dos formas. `head` y `tail` extraen las partes de la forma con contenido; son parciales porque esa forma es una de las dos. `empty` y `::` construyen cada forma. Si con pattern matching se puede escribir cualquier operación sobre listas (Módulo 2), y cada paso del pattern matching tiene su función, entonces con las cinco funciones también se puede escribir cualquier operación. Alcanza con traducir: toda función escrita con `match` pasa, mecánicamente, a una escrita con las cinco.

Ese conjunto mínimo de operaciones que representa un tipo se llama **tipo abstracto de datos**: el tipo definido por lo que se puede hacer con él, y no por cómo está armado. Lo otro, el tipo definido por sus formas (`Nil` y `::`), es la definición **algebraica**. Ya viste un pariente en Sintaxis, y otro en cualquier interfaz de Java: una lista de operaciones mínimas a través de la cual se accede a la estructura sin mirarla.

⚠️ **Nomenclatura.** Los dos nombres se cruzan con facilidad. En esta unidad: *algebraico* es la forma (`Nil`/`::`, `VaciaSnoc`/`Snoc`); *abstracto* es el conjunto de operaciones (las cinco funciones). Si en un parcial te encontrás con "tipo algebraico" para referirse a las cinco operaciones, es esto mismo: el conjunto mínimo con el que se trabaja la lista sin mirar su forma. Por eso mismo el archivo del nivel 2 se llama `Nivel2TipoAlgebraico`: lleva el nombre con el que se presentó; su contenido es el tipo abstracto.

> 🕳️ **Madriguera — por qué "algebraico"**
> Las formas de un tipo se pueden contar: `Nil` o `::` es una **suma** de dos casos; `cabeza :: cola` es un **producto** (una cabeza y una cola). Sumar y multiplicar cantidades de valores es álgebra, y de ahí el nombre "sum types" y "product types".
> *Volvé al camino — esto se profundiza aparte, otro día.*

Y una pregunta que conviene hacerse: ¿`head` se puede implementar **sin** pattern matching? No. De ninguna manera, en ningún nivel. Mirá el `head` de la sección 4: no tiene un `match` escrito, pero pregunta `isEmpty` y desarma en `init` y `last`, que son las dos partes de la forma `Snoc(init, last)`; es el mismo pattern matching, con los accesores de la `case class` en lugar de un `case`. Es como preguntar si un mensaje en objetos se puede implementar sin mandar mensajes, o un procedimiento en C sin tocar memoria: abajo de todo siempre está lo más básico. Lo que cambió no es que el pattern matching desapareció, sino **dónde** está: adentro de cinco funciones, en vez de desparramado por todo el código.

## 6. 🔴 La trampa de la compartimentalización

> La puerta que separa el pattern matching del resto del código la cerrás vos, con disciplina: el lenguaje deja pasar un `match` sobre `Nil` y `::` en cualquier lado, y funciona. La única barrera es **saber** que estás trabajando de esta forma.

Esta es la trampa que el Módulo 1 anunció para cada paso de la escalera. Supongamos que después de todo esto alguien agrega una séptima función a la consulta y la escribe con pattern matching, como en el nivel 1. ¿Qué pasa? Nada, por ahora: compila, anda, el lenguaje está feliz. ¿Y cuando cambie la representación? Se rompen las cinco funciones, como siempre, **y además esa séptima**. El mundo es un poquito peor; no mucho, no parece grave. Hay que ir y arreglarla.

Lo grave está en otro lado: **falta una restricción mecánica**. El acuerdo vive solo en tu cabeza: el compilador lo desconoce, y por eso te deja romperlo en silencio. Si mirás la implementación de `head` para guiarte, vas a ver un `match` o un `if` sobre la forma, y vas a pensar que así se trabaja. Si nadie te invitó a esta fiesta, seguís trabajando de una manera que el lenguaje soporta y que va deshaciendo, en silencio, lo que el nivel 2 construyó.

Esto se llama **compartimentalizar**: encerrar a propósito una forma de trabajar (el pattern matching sobre la forma) de un lado de una puerta, para que cuando la forma cambie, el cambio no pase al otro lado. Y la trampa es que la puerta la cerrás vos, con disciplina, no el lenguaje. Esto vuelve en cada nivel que sigue, siempre igual: en cada paso hacia arriba, nada te frena de usar lo que quedó abajo.

**Para el parcial, si te preguntan:** *"¿Qué es un tipo abstracto de datos?"* El conjunto mínimo de operaciones con el que se trabaja un tipo sin mirar cómo está armado por adentro. Para la lista son `isEmpty`, `head`, `tail`, `empty` y `::`: son lo que el pattern matching hacía sobre la forma, convertido en funciones, y por eso alcanzan para escribir cualquier operación. Se contrapone a la definición algebraica, que es la forma misma (`Nil` y `::`).

**Para el parcial, si te preguntan:** *"¿Qué cambia entre resolver una operación con pattern matching sobre la lista y resolverla con `isEmpty`, `head` y `tail`?"* Las cinco funciones (`isEmpty`, `head`, `tail`, `empty`, `::`) son el pattern matching hecho funciones: hacen exactamente lo que el `match` hacía sobre la forma. Escribir las operaciones sobre ellas encapsula la forma: si la representación cambia, se reescriben esas cinco y todos los usos siguen andando, en vez de reescribir todo. El pattern matching no desaparece; queda adentro de las cinco. Y nada obliga a respetarlo: es una disciplina, no una regla del lenguaje.

## 7. 🔴 A qué estás acoplado ahora

> El código dejó de depender de la forma de la lista y pasó a depender de **un conjunto de operaciones que representa a la lista**. Sigue acoplado a que sea una lista.

Se ganó mucho, y hay que ver qué sigue atado. Las cinco funciones no son cualquier conjunto de operaciones: son operaciones que **tienen sentido para una lista**. `head` y `tail` suponen un primer elemento y un resto; suponen un **orden**. A un set (un conjunto, sin repetidos y sin orden) le faltan `head` y `tail`; a un árbol binario también. (En Scala, `Set` hereda `head` de `Iterable` y te lo responde: `Set(1, 2, 3).head` da `1`. Sin orden, ese "primero" significa poco: es la trampa de la sección anterior, servida por la biblioteca.) Y la consulta, en ningún momento, dijo que los alumnos vinieran en orden: "los inscriptos a un curso" son muchos alumnos, y nada más. Si mañana te los mandan en un set, porque no hay repetidos y no hay orden, todo lo del nivel 2 vuelve a romperse. Y pasa: en la unidad de varianza, para que `[+T]` tipara, se cambió un `Set` por una `List` sin pensarlo dos veces, y cambió todo el conjunto de operaciones disponibles; acá, al revés, el nivel 2 entero se cae. Esta vez el código no está acoplado a cómo está armada la lista, sino a **que sea una lista**.

Así que la pregunta del Módulo 2 vuelve, un nivel más arriba: ¿para qué se usan `head` y `tail` en la consulta? Si se pudiera nombrar eso, lo que se hace con ellas, en vez de ellas mismas, el código dejaría de depender de la lista.

---

## Checkpoint

1. ¿Qué tres cosas hacía el `match` sobre la lista? ¿Con qué función se reemplaza cada una?
2. ¿Por qué la traducción del nivel 1 al nivel 2 es mecánica? ¿Qué ganó y qué no ganó el código al traducirlo?
3. ¿Qué es una función parcial? ¿Cuáles de las cinco lo son, y por qué está `isEmpty` en la lista?
4. Explicá cómo se calcula `head` sobre una lista *snoc*. ¿Y `::`?
5. Al cambiar `List` por `ListaSnoc`, ¿qué se rompe en el nivel 2? ¿Qué sigue andando? Compará con lo que pasaba en el nivel 1.
6. ¿Qué quiere decir que las cinco funciones son la "reificación" del pattern matching? ¿Por qué eso garantiza que alcanzan para todo?
7. ¿Qué es un tipo abstracto de datos y en qué se diferencia de la definición algebraica de un tipo?
8. ¿Se puede implementar `head` sin pattern matching? ¿Qué cambió entonces entre el nivel 1 y el nivel 2?
9. ¿En qué consiste la trampa de la compartimentalización? ¿Quién cierra la puerta?
10. ¿A qué está acoplado el código del nivel 2? ¿Qué estructura lo rompería?

## Qué viene después

El Módulo 4 responde la pregunta del cierre: `head` y `tail` se usan para **recorrer**. Le pone nombre al recorrido (`fold`), lo saca de las seis funciones, y aprovecha para contar qué tiene que ver la semilla del `fold` con el elemento neutro de una operación.

**FIN DEL MÓDULO 3 — Nivel 2, las cinco funciones (el tipo abstracto)**
