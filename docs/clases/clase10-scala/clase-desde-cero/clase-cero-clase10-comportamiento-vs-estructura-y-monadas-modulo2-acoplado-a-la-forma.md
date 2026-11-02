# Clase desde cero — Comportamiento vs estructura y mónadas — Módulo 2: Nivel 1, acoplado a la forma

**Unidad:** clase10 · **Lenguaje:** Scala 3.3.1 · **Archivos del proyecto:** `niveles/Dominio.scala`, `niveles/Nivel1PatternMatching.scala`, `niveles/ListaSnoc.scala` (solo su forma) · **Densidad:** 🔴 pide una sesión con el código abierto (las secciones 4 y 6 son 🟡: se leen de corrido)

---

## Sobre este documento

**Qué cubre.** El problema que acompaña a toda la primera mitad de la unidad (materias, cursos, alumnos, y una consulta sobre ellos), resuelto en el nivel más bajo: pattern matching sobre las dos formas de la lista. Qué tiene de malo esa solución, por qué la repetición que se ve no se puede extraer, qué pasa cuando alguien cambia la representación de la lista, y la conclusión: el código quedó acoplado a algo que no forma parte del problema.

**Qué no cubre.** La salida. El Módulo 3 esconde la forma detrás de funciones; este módulo solo muestra el problema.

## De dónde venís

Del Módulo 1: funcional construye desde lo más bajo, y lo más bajo es pattern matching sobre la forma de los datos. De la unidad anterior: `case class` y `case object`, `match` con patrones de constante, de constructor y con guarda, y el patrón `cabeza :: cola` sobre una lista. De Paradigmas: las listas de Haskell como `[]` y `(x:xs)`.

---

## 1. 🔴 El problema: materias, cursos, alumnos

> Una materia tiene cursos; un curso tiene alumnos inscriptos. La consulta de toda la primera mitad de la unidad es: **dada la lista de todas las materias, los legajos de los alumnos regulares inscriptos a cursos de materias electivas.**

```
┌────────────────────┐  cursos *   ┌────────────────────┐  inscriptos *   ┌────────────────────┐
│      Materia       │ ──────────► │       Curso        │ ──────────────► │       Alumno       │
├────────────────────┤             ├────────────────────┤                 ├────────────────────┤
│ electiva: Boolean  │             │ codigo: String     │                 │ legajo: String     │
└────────────────────┘             └────────────────────┘                 │ regular: Boolean   │
                                                                          └────────────────────┘
```

El dominio es mínimo a propósito: tres `case class`, sin comportamiento. Es un problema de datos, y lo que se va a mirar es cómo se recorre.

```scala
package tadp.niveles

case class Alumno(legajo: String, regular: Boolean)
case class Curso(codigo: String, inscriptos: List[Alumno])
case class Materia(electiva: Boolean, cursos: List[Curso])
```

Y unos datos de prueba, los mismos que usan los tests, para ver resultados concretos a lo largo de la unidad:

```scala
import tadp.niveles._

val todasLasMaterias: List[Materia] = List(
  Materia(electiva = true, cursos = List(
    Curso("K3001", List(Alumno("100", regular = true), Alumno("101", regular = false))),
    Curso("K3002", List(Alumno("102", regular = true)))
  )),
  Materia(electiva = false, cursos = List(
    Curso("K1001", List(Alumno("200", regular = true)))
  )),
  Materia(electiva = true, cursos = List(
    Curso("K4001", List(Alumno("300", regular = true), Alumno("301", regular = true)))
  ))
)
```

Tres materias: dos electivas y una que no. La respuesta a la consulta tiene que ser `List("100", "102", "300", "301")`: el 101 no es regular, y el 200 está en una materia que no es electiva.

## 2. 🔴 Una lista tiene dos formas

> Una lista es una de dos cosas: **la lista vacía** (`Nil`), o **un elemento seguido de otra lista** (`cabeza :: cola`). Con esas dos formas se construye cualquier lista y, con pattern matching, se deconstruye.

```
          ┌ Nil                                   la lista vacía
List[T] ──┤
          └ (::)  (cabeza: T, cola: List[T])      un elemento y el resto          "cons"
```

`::` se lee "cons" (de *construct*): es la operación que arma una lista nueva poniendo un elemento adelante de otra lista. Sirve para los dos lados: para construir y para preguntar.

```scala
1 :: 2 :: 3 :: Nil                                    // Resultado: List(1, 2, 3)

List(1, 2, 3) match {
  case Nil            => "vacía"
  case cabeza :: cola => s"cabeza $cabeza, cola $cola"
}                                                     // Resultado: cabeza 1, cola List(2, 3)

(Nil: List[Int]) match {
  case Nil            => "vacía"
  case cabeza :: cola => s"cabeza $cabeza, cola $cola"
}                                                     // Resultado: vacía
```

⚠️ **Trampa: `::` se asocia a la derecha.** `1 :: 2 :: Nil` se lee como `1 :: (2 :: Nil)`: el elemento va a la izquierda del operador, la lista a la derecha. Es lo que permite escribir listas sin paréntesis. Vuelve en la sección 5, cuando aparezca otro operador que se asocia al revés.

Con solo esto se puede implementar **todo** lo que se puede hacer con una lista: si conocés las formas de un tipo de dato, desde ahí construís cualquier otra operación. Es el nivel más bajo de la escalera.

## 3. 🔴 La consulta, resuelta con pattern matching

> Cada paso de la consulta es una función recursiva con dos casos: qué hacer si la lista está vacía, y qué hacer con la cabeza antes de seguir con la cola.

Se necesitan cinco pasos (quedarse con las electivas, juntar sus cursos, juntar sus inscriptos, quedarse con los regulares, sacarles el legajo) y una función auxiliar para pegar dos listas, porque los cursos de cada materia hay que concatenarlos. Todo con `match`:

```scala
package tadp.niveles

object Nivel1PatternMatching {

  def append[T](izq:List[T], der:List[T]):List[T] = izq match {
    case Nil => der
    case cabeza::cola => cabeza::append(cola, der)
  }

  def electivas(materias:List[Materia]):List[Materia] = materias match {
    case Nil => Nil
    case materia::otras if materia.electiva => materia::electivas(otras)
    case _::otras => electivas(otras)
  }

  def cursos(materias:List[Materia]):List[Curso] = materias match {
    case Nil => Nil
    case materia::otras => append(materia.cursos, cursos(otras))
  }

  def inscriptos(cursos:List[Curso]):List[Alumno] = cursos match {
    case Nil => Nil
    case curso::otros => append(curso.inscriptos, inscriptos(otros))
  }

  def regulares(alumnos:List[Alumno]):List[Alumno] = alumnos match {
    case Nil => Nil
    case alumno::otros if alumno.regular => alumno::regulares(otros)
    case _::otrosAlumnos => regulares(otrosAlumnos)
  }

  def legajos(alumnos:List[Alumno]):List[String] = alumnos match {
    case Nil => Nil
    case alumno::otrosAlumnos => alumno.legajo::legajos(otrosAlumnos)
  }

  def legajosDeRegularesEnElectivas(todasLasMaterias: List[Materia]): List[String] =
    legajos(regulares(inscriptos(cursos(electivas(todasLasMaterias)))))
}
```

Paso por paso, con los datos de prueba. (Los `.map(…)` del final de cada línea están solo para que los resultados se lean; `map` se explica en el Módulo 5, y acá se usa como "sacale el código a cada uno".)

```scala
import tadp.niveles.Nivel1PatternMatching._

electivas(todasLasMaterias).map(_.cursos.map(_.codigo))        // Resultado: List(List(K3001, K3002), List(K4001))
cursos(electivas(todasLasMaterias)).map(_.codigo)              // Resultado: List(K3001, K3002, K4001)
inscriptos(cursos(electivas(todasLasMaterias))).map(_.legajo)  // Resultado: List(100, 101, 102, 300, 301)
regulares(inscriptos(cursos(electivas(todasLasMaterias)))).map(_.legajo)
// Resultado: List(100, 102, 300, 301)
legajosDeRegularesEnElectivas(todasLasMaterias)                // Resultado: List(100, 102, 300, 301)
legajosDeRegularesEnElectivas(Nil)                             // Resultado: List()
append(List(1, 2), List(3))                                    // Resultado: List(1, 2, 3)
```


Cómo funciona `electivas`, que es la más completa: si no hay materias, no hay electivas (`Nil`). Si hay una materia y es electiva, va a la respuesta, seguida de las electivas del resto. Si hay una materia y no es electiva, se la saltea y se sigue con el resto. Las guardas (`if materia.electiva`) son lo que permite que dos casos tengan la misma forma (`materia::otras`) y se distingan por una condición.

Funciona y es correcto. Ahora, qué tiene de malo.

## 4. 🟡 Hay repetición, y no se puede extraer

> Las seis funciones se parecen, y aun así la repetición es imposible de extraer a una función. Eso es una señal de que está en un nivel más alto que el del código.

Mirá las seis: todas arrancan con `case Nil`. Todas parten en cabeza y cola. Todas llaman a sí mismas con la cola. `electivas` se parece a `regulares`; `cursos` se parece a `inscriptos`; `legajos` se parece a las dos anteriores pero un poco menos. Hay un patrón evidente.

Y aun así, tratá de hacer lo que harías con cualquier repetición: extraer una línea a una función y llamarla desde los seis lugares. No se puede. Las únicas líneas iguales son los cinco `case Nil => Nil`, y esas son justo las que no se pueden extraer: `case Nil => Nil` es el caso base de cada función, y un caso base queda adentro de su función. Encima difieren: `append` devuelve `der`. Las ramas recursivas hacen cosas distintas con la cabeza.

La repetición existe, pero está en **qué hacen** las funciones, no en **cómo lo escriben**. Están expresadas en un nivel tan bajo (cabeza, cola, vacía) que lo que tienen en común no aparece en el texto. Es la primera pista de que hay que subir de nivel para poder nombrarlo.

## 5. 🔴 Otra lista: la que crece por el final

> La lista con cabeza y cola es **una** forma de representar "muchos elementos en orden". Hay otras. Si alguien cambia la representación, todo el código escrito sobre la forma se rompe.

Nadie dijo que una lista tenga que ser "un elemento adelante del resto". Puede ser al revés: **el resto, seguido del último elemento**. Es una lista igual de válida, se recorre igual (de atrás para adelante en vez de adelante para atrás), y tiene sus dos formas:

```
                ┌ VaciaSnoc                                   la lista vacía
ListaSnoc[T] ───┤
                └ Snoc  (init: ListaSnoc[T], last: T)         todo lo anterior y el último     "snoc"
```

"Snoc" es "cons" al revés, porque construye al revés: el elemento va al final. En el proyecto esta lista se llama `ListaSnoc`, con `VaciaSnoc` como lista vacía y `Snoc` como constructor; el operador para agregar es `:+`, el mismo "esta lista, más este elemento al final" que ya usaste sobre `List`. En este módulo solo importa su forma. `last` e `init` son las dos partes de un `Snoc`, como `cabeza` y `cola` en `::`; cómo responde `head` (que acá hay que calcularlo) llega en el Módulo 3.

```scala
import tadp.niveles._

VaciaSnoc :+ 1 :+ 2 :+ 3                       // Resultado: Snoc(Snoc(Snoc(VaciaSnoc,1),2),3)
(VaciaSnoc :+ 1 :+ 2 :+ 3).last                // Resultado: 3
(VaciaSnoc :+ 1 :+ 2 :+ 3).init                // Resultado: Snoc(Snoc(VaciaSnoc,1),2)
Snoc(Snoc(Snoc(VaciaSnoc, 1), 2), 3) == (VaciaSnoc :+ 1 :+ 2 :+ 3)   // Resultado: true
```

Fijate la diferencia con `::`: `:+` se asocia a la izquierda (`(lista :+ 1) :+ 2`), porque la lista va a la izquierda y el elemento a la derecha. Es la misma lista `1, 2, 3`, armada desde el otro extremo. (En el proyecto también está `ListaSnoc.empty[Int]`: es `VaciaSnoc` con el tipo de elemento fijado, y se puede usar en su lugar.)

Cada forma favorece un extremo: con cabeza y cola, el primer elemento sale gratis; con `Snoc`, el último sale gratis, y para llegar al primero hay que atravesar todos los `init`. Si tu programa trabaja desde el final, la segunda es la buena.

**Ahora cambiá la representación.** Supongamos que los alumnos te llegan en una `ListaSnoc` en lugar de una `List`. ¿Qué código deja de funcionar? Probá reescribir `regulares` tal cual estaba, cambiando solo el tipo y la vacía (`VaciaSnoc`) y dejando los patrones `::`:

```scala
def regulares(alumnos: ListaSnoc[Alumno]): ListaSnoc[Alumno] = alumnos match {
  case VaciaSnoc => VaciaSnoc
  case alumno :: otros if alumno.regular => alumno :: regulares(otros)
  case _ :: otros => regulares(otros)
}
// Resultado: no compila.
//   value regular is not a member of Any
//   Found:    (otros : List[Any])
//   Required: tadp.niveles.ListaSnoc[tadp.niveles.Alumno]
```

El patrón `alumno :: otros` es un patrón de `List`: el compilador trata de encajarlo, no encuentra nada que le sirva y deja a `alumno` tipado como `Any`. La `ListaSnoc` no tiene cons: tiene snoc. **Todo lo que estaba escrito en términos de `Nil` y `::` deja de servir, en las seis funciones.** La estructura cambió y el código entero hay que reescribirlo.

Si tachás en el código de la sección 3 todo lo que se rompe, queda tachado, en las seis funciones, **todo lo que sigue al `=`**: el `match` y cada uno de sus casos. Sobreviven las seis firmas (salvo el nombre del tipo, `List` por `ListaSnoc`) y la llamada final, `legajos(regulares(inscriptos(cursos(electivas(todasLasMaterias)))))`, que no sabe nada de la forma.

Lo que pasó tiene nombre, y es un nombre de objetos: **se rompió el encapsulamiento**. El código conocía demasiado de cómo estaba armada la lista por adentro. Apareció otra cosa que cumple el mismo objetivo pero está armada distinto, y el código no la puede usar.

## 6. 🟡 Elegir la estructura importa

> Cambiar la representación de un dato no es un capricho: elegir la estructura correcta para un problema es una de las decisiones que más pesan en un programa real.

Es fácil pensar "¿cuándo voy a cambiar la representación de una lista? La lista está pensada, no es un objeto de negocio que yo diseñé". Dos respuestas.

La primera: hay muchas formas de representar una secuencia (simplemente enlazada, doblemente enlazada, un arreglo, una pila, una cola, un árbol), y no sirven para lo mismo. Una anécdota concreta: un sistema que dibujaba nubes de puntos en 3D se arrastraba. La nube estaba guardada en un **set**, porque "no hay puntos repetidos". Un set es la estructura que garantiza elementos únicos: cada inserción revisa primero si el elemento ya está, y ese chequeo cuesta. Agregar a una lista es gratis en ese sentido: se agrega y listo. El set es barato para lo que fue hecho (preguntar si algo está) y caro para insertar. Por eso a veces la decisión consciente es guardar en una lista y sacar los repetidos después; y lo mismo vale para una lista ordenada: mantener el orden en cada inserción cuesta. Para una nube de puntos donde los repetidos no importaban, ese costo era trabajo inútil en cada uno de millones de puntos. Reemplazar ese set por una lista, sin cambiar ninguna otra lógica, hizo el programa doce veces más rápido. La estructura equivocada era el problema entero; cualquier otra optimización habría sido migajas.

La segunda: aunque vos no cambies nada, **la representación puede cambiar debajo tuyo**. La biblioteca que te devuelve esa lista cambia de versión y deja de usar la lista estándar por otra estructura propia; o resulta que lo que modelaste como lista en realidad te llega como set, porque los alumnos de un curso no tienen orden. En los dos casos, todo lo escrito sobre `Nil` y `::` va a la basura, y son semanas de reescribir y probar.

La lista de Scala, la que usaste para todo hasta ahora, es una **lista simplemente enlazada**: para llegar al elemento 100 hay que pasar por los 99 anteriores. Sirve para casi todo lo que hiciste en la materia; no sirve para guardar un texto largo o un volumen grande de datos a los que accedés por posición.

> 🕳️ **Madriguera — los arrays de JavaScript**
> `[1, 2, 3]` en JavaScript es por dentro un objeto con claves `"0"`, `"1"`, `"2"`: las posiciones son strings. Según la anécdota, a partir del décimo elemento las claves ocupan dos caracteres, y un programa que andaba bien con pocos datos escala mal sin ninguna explicación visible. Los motores modernos optimizan ese caso; el punto es el mismo: la representación por debajo no es la que uno imagina.
> *Volvé al camino — esto se profundiza aparte, otro día.*

## 7. 🔴 A qué estás acoplado

> Siempre estás acoplado a algo: si hay código, hay algo de lo que depende. La pregunta útil es **a qué**, y si eso forma parte del problema que estás resolviendo.

Volvé a leer la consulta: "los legajos de los alumnos regulares inscriptos a cursos de materias electivas". En ningún momento dice cabeza, ni cola, ni vacía. El problema habla de materias que son electivas, de cursos, de alumnos regulares, de legajos. El código del nivel 1 habla todo el tiempo de `Nil` y `::`.

Ahí está el diagnóstico. El código está acoplado a **la forma de la lista**, y la forma de la lista **no forma parte del problema**: es una de las maneras posibles de representar "muchos de estos". Como no es parte del problema, puede cambiar sin que el problema cambie, y cuando cambia, el código se cae entero.

El objetivo de los próximos tres módulos es mover el acoplamiento: de la forma a algo que esté más cerca del problema. Cada movimiento se paga con algo, y en cada uno la pregunta va a ser la misma: **¿a qué estás acoplado ahora?**

**Para el parcial, si te preguntan:** *"¿Qué problema tiene resolver una operación sobre listas con pattern matching sobre `Nil` y `::`?"* Que el código queda acoplado a la forma de la lista (cabeza y cola), que es una decisión de representación y no parte del problema. Si la representación cambia (otra lista, un set, una biblioteca nueva), todo el código escrito sobre la forma deja de compilar y hay que reescribirlo. Es el mismo problema que en objetos se llama romper el encapsulamiento: conocer de más cómo está armado algo por adentro.

---

## Checkpoint

1. ¿Cuáles son las dos formas de una lista? ¿Qué hace `::` y en qué dos sentidos se usa?
2. ¿Hacia qué lado se asocia `::`? ¿Y `:+`? ¿Por qué?
3. Explicá cómo funciona `electivas` caso por caso. ¿Para qué están las guardas?
4. ¿Por qué hace falta `append` en `cursos` e `inscriptos` y no en `legajos`?
5. "Hay repetición pero no se puede extraer": ¿qué quiere decir? ¿Dónde está la repetición, si no está en el texto?
6. ¿Qué es una lista *snoc*? ¿En qué se diferencia de la de cabeza y cola, y en qué es igual?
7. Si los alumnos llegan en una `ListaSnoc`, ¿qué parte de `regulares` deja de funcionar? ¿Por qué el compilador dice que `alumno` es `Any`?
8. ¿Por qué insertar en un set cuesta más que agregar a una lista? ¿Qué pasó en la nube de puntos?
9. ¿A qué está acoplado el código del nivel 1? ¿Eso forma parte del problema?

## Qué viene después

El Módulo 3 da el primer paso atrás: esconde la forma de la lista detrás de cinco funciones (`isEmpty`, `head`, `tail`, `empty` y `::`), reescribe las seis funciones sin ningún `match`, y vuelve a cambiar la representación para ver qué se rompe ahora.

**FIN DEL MÓDULO 2 — Nivel 1, acoplado a la forma**
