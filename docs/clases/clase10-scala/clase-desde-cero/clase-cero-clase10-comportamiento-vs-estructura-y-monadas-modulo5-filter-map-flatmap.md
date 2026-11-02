# Clase desde cero — Comportamiento vs estructura y mónadas — Módulo 5: Nivel 4, `filter`, `map` y `flatMap`

**Unidad:** clase10 · **Lenguaje:** Scala 3.3.1 · **Archivos del proyecto:** `niveles/Nivel4OrdenSuperior.scala`, `niveles/Lifteo.scala` · **Densidad:** 🔴 pide una sesión con el código abierto (las secciones 4 y 6 son 🟡: se leen de corrido)

---

## Sobre este documento

**Qué cubre.** El tercer paso atrás, y el último que se queda en listas: el siguiente, en el Módulo 6, ya es sobre cualquier caja. En las seis funciones el `fold` se usa solo de tres maneras, y cada una tiene nombre: filtrar, transformar, transformar y aplanar. Con esos tres nombres la consulta queda en una sola expresión. Qué hace cada operación y cuáles son sus firmas, por qué `flatMap` existe aparte de `map`, qué quiere decir que `map` "levanta" una función (lifteo), qué se pierde y qué se gana al subir a este nivel, por qué "declarativo" no es el término correcto, y el desafío con el que cierra la primera mitad de la unidad.

**Qué no cubre.** La respuesta al desafío. Es el Módulo 6.

## De dónde venís

Del Módulo 4: `fold` con semilla y paso, `foldRight` para construir listas en orden, y la pregunta del cierre: ¿cómo se está usando el `fold`? Del Módulo 3: la trampa de la compartimentalización. De Paradigmas: `map` y `filter` de Haskell, y la currificación (una función de dos parámetros es una función de uno que devuelve otra función).

---

## 1. 🔴 El `fold` se usa de tres maneras, y tienen nombre

> Las cinco funciones de la consulta (`append` aparte) son cinco `fold`, pero hacen solo tres cosas: **quedarse con algunos elementos** (filtrar), **convertir cada elemento en otro** (transformar), o convertir cada elemento en varios y juntarlos (transformar y aplanar). A cada una se le puede dar un nombre y dejar de escribir el `fold`.

Volvé a mirar las cinco funciones con la pregunta "¿qué quiero?" (`append` es auxiliar y desaparece en la sección 3), dicha en voz alta, sin hablar de listas:

- `electivas`: de las materias, quiero **las que** son electivas. `regulares`: de los alumnos, quiero **los que** son regulares. Es lo mismo: **filtrar** con una condición.
- `legajos`: de cada alumno, quiero su legajo. Un alumno entra, un legajo sale, para cada uno. Es **transformar** elemento por elemento.
- `cursos`: de cada materia, quiero sus cursos; pero cada materia tiene **varios**, y yo quiero todos los cursos juntos, no una lista de listas. `inscriptos` es igual. Es transformar, donde cada elemento da varios, y **aplanar** el resultado.

Son tres operaciones, con sus tres firmas:

```
filter (f: T => Boolean): List[T]          me quedo con los que cumplen
map    [R](f: T => R): List[R]             convierto cada uno; mismo largo
flatMap[R](f: T => List[R]): List[R]       convierto cada uno en varios; junto todo
```

```scala
List(1, 2, 3).filter(n => n > 1)             // Resultado: List(2, 3)
List(1, 2, 3).map(n => n * 10)               // Resultado: List(10, 20, 30)
List(1, 2, 3).flatMap(n => List(n, n))       // Resultado: List(1, 1, 2, 2, 3, 3)
List.empty[Int].map(n => n * 10)             // Resultado: List()
```

Las tres reciben una función y devuelven una lista. Fijate la última línea: `map` sobre la vacía da la vacía, sin que nadie pregunte nada. Esa pregunta (`isEmpty`, `case Nil`) estaba escrita en cada función de los niveles 1 y 2; el `fold` la escondió detrás de la semilla; acá ni la semilla hace falta, porque cada operación ya sabe qué hacer con la vacía.

## 2. 🔴 `flatMap` contra `map`: la lista de listas

> `map` mantiene la cantidad de elementos: uno entra, uno sale. Cuando la función devuelve **una lista** por cada elemento, `map` da una lista de listas; `flatMap` da **una sola lista** con todo adentro.

Es la diferencia que aparece en `cursos`. Cada materia tiene varios cursos; sacarle los cursos a cada materia con `map` da esto:

```scala
import tadp.niveles._

todasLasMaterias.map(materia => materia.cursos).map(_.map(_.codigo))
// Resultado: List(List(K3001, K3002), List(K1001), List(K4001))

todasLasMaterias.flatMap(materia => materia.cursos).map(_.codigo)
// Resultado: List(K3001, K3002, K1001, K4001)
```

(`todasLasMaterias` son los datos de prueba del Módulo 2; el `.map(_.codigo)` del final es solo para leer los resultados.) Con `map`, una lista de tres materias da una lista de tres listas de cursos, porque `map` no cambia la cantidad. Pero la consulta quería "todos los cursos en la misma bolsa". `flatMap` es "mapear y después aplanar": aplica la misma función, obtiene las tres listas, y las pega en una. Elegís `map` o `flatMap` según lo que devuelva la función: un elemento o una lista.

## 3. 🔴 La consulta, con las tres operaciones

> Las cinco funciones de la consulta son cada una **una sola operación con nombre** (`append` ya no hace falta: `flatMap` aplana solo). Y las cinco se pueden escribir encadenadas, en una expresión.

```scala
package tadp.niveles

object Nivel4OrdenSuperior {

  def electivas(materias:List[Materia]):List[Materia] =
    materias.filter(materia => materia.electiva)

  def cursos(materias:List[Materia]):List[Curso] =
    materias.flatMap(materia => materia.cursos)

  def inscriptos(cursos:List[Curso]):List[Alumno] =
    cursos.flatMap(curso => curso.inscriptos)

  def regulares(alumnos:List[Alumno]):List[Alumno] =
    alumnos.filter(alumno => alumno.regular)

  def legajos(alumnos:List[Alumno]):List[String] =
     alumnos.map(alumno => alumno.legajo)

  def legajosDeRegularesEnElectivas(todasLasMaterias: List[Materia]): List[String] =
    legajos(regulares(inscriptos(cursos(electivas(todasLasMaterias)))))

  // La consulta entera, encadenada
  def encadenado(todasLasMaterias: List[Materia]): List[String] =
    todasLasMaterias
        .filter(materia => materia.electiva)
        .flatMap(materia => materia.cursos
            .flatMap(curso => curso.inscriptos
                .filter(alumno => alumno.regular)
                .map(alumno => alumno.legajo)
            )
        )
}
```

```scala
import tadp.niveles.Nivel4OrdenSuperior._

legajosDeRegularesEnElectivas(todasLasMaterias)   // Resultado: List(100, 102, 300, 301)
encadenado(todasLasMaterias)                      // Resultado: List(100, 102, 300, 301)
encadenado(Nil)                                   // Resultado: List()
```

Mismo resultado que en los tres niveles anteriores. Compará el cuerpo de `electivas` con el del nivel 1: de tres casos con `match` a `materias.filter(materia => materia.electiva)`. Lo único que quedó escrito es **lo del dominio**: si la materia es electiva. Todo lo demás (recorrer, preguntar si está vacía, construir el resultado) lo hace la operación.

En `encadenado`, las operaciones están anidadas en vez de en funciones separadas: por cada materia electiva, por cada curso de esa materia, los legajos de los inscriptos regulares. Es más de lo mismo; se escribe así cuando no hace falta nombrar cada paso. Va a volver en el Módulo 9, porque esta forma de anidar tiene una sintaxis más cómoda.

Y la trampa del Módulo 3, un nivel más arriba: nada te frena de escribir `legajos` con `foldRight`, o con `head` y `tail`. Compila igual. Saber que estás en este nivel es tu responsabilidad.

## 4. 🟡 Lifteo: `map` levanta una función

> Por currificación, `map` se puede leer como una función que recibe **una función de un elemento** y devuelve **una función de listas**. Transforma tu función en otra de más alcance: la **eleva** (lift).

Las firmas, en notación de Haskell (`flatMap` va con el nombre de Scala), lo muestran poniendo paréntesis donde no estaban:

```
map     :: (a -> b)    -> [a] -> [b]       map     :: (a -> b)    -> ([a] -> [b])
filter  :: (a -> Bool) -> [a] -> [a]       filter  :: (a -> Bool) -> ([a] -> [a])
flatMap :: (a -> [b])  -> [a] -> [b]       flatMap :: (a -> [b])  -> ([a] -> [b])
```

A la izquierda, `map` recibe una función y una lista y devuelve una lista. A la derecha, la misma firma leída con un paréntesis: `map` recibe una función **y devuelve otra función**, una que va de listas a listas. Son equivalentes por currificación; cambia cómo lo pensás.

Y pensarlo así es útil. Vos tenés una función que sabe una sola cosa de un solo elemento: "¿esta materia es electiva?", "¿cuál es el legajo de este alumno?". `filter` toma ese criterio y te da una función de filtrado de listas. `map` toma esa transformación y te da una que trabaja sobre toda la estructura. En Haskell, `(filter even)` es una función de listas a listas, armada a partir del criterio `even`:

```scala
package tadp.niveles

object Lifteo {

  def liftear[A, B](f: A => B): List[A] => List[B] =
    lista => lista.map(f)

  def filtrador[A](criterio: A => Boolean): List[A] => List[A] =
    lista => lista.filter(criterio)

  val esPar: Int => Boolean = n => n % 2 == 0
  val filtrarPares: List[Int] => List[Int] = filtrador(esPar)   // en Haskell: (filter even)
}
```

```scala
import tadp.niveles.Lifteo._

esPar(4)                                     // Resultado: true
filtrarPares(List(1, 2, 3, 4))               // Resultado: List(2, 4)
liftear((n: Int) => n + 1)(List(1, 2, 3))    // Resultado: List(2, 3, 4)
```

`esPar` sabe de un número. `filtrarPares` sabe de listas, y se armó a partir de `esPar` sin escribir ningún recorrido. Eso se llama **liftear**: levantar una función del orden de un elemento al orden de muchos. Cualquier función `A => B`, aunque no haya sido pensada para listas, `map` te la convierte en una `List[A] => List[B]`. Y es lo que te deja pensar en el nivel que querías: "sé si una materia es electiva; cómo está organizada la información es otro problema, y de eso se encargan estas funciones".

## 5. 🔴 Qué perdés y qué ganás

> Subir de nivel siempre cuesta lo mismo: se **pierde poder** (operaciones que podías hacer abajo y acá no) y se **ganan individuos** (cosas sobre las que el mismo código ahora actúa). Y la protección es parte de la ganancia.

¿Podés hacer con `filter`, `map` y `flatMap` todo lo que podías hacer con pattern matching? No. Por ejemplo: con estas tres no podés preguntar si la lista está vacía antes de hacer nada; las tres devuelven una lista, siempre. Perdiste poder: hay operaciones que en el nivel 1 se escribían y acá no entran.

¿Y qué se gana a cambio? Primero, el código se ve más cerca del problema: está a la vista lo del dominio, y casi no hay algoritmo. Segundo, y es lo menos obvio: **las limitaciones marcan un camino**. Con estas tres operaciones es imposible pedir un elemento ausente, pasarte de la cantidad o hacer `head` de una lista vacía. Nunca vas a caer en esos casos inválidos, porque las operaciones se encargan por vos. Perdés la capacidad de hacer algunas cosas y ganás que no podés hacer varias cosas mal. Es bajo nivel contra alto nivel: hay detalles en los que ya no te metés, y mejor así.

Acá puede sonar a retroceso: `map` y `filter` los aprendiste como "cosas de listas", y veníamos huyendo de las listas. Pero preguntate si tiene sentido filtrar un set o mapear un árbol. Y tercero, la pregunta de todos los módulos: ¿sobre qué cosas funciona esto? Sobre listas, y sobre conjuntos, y sobre árboles: ¿tiene sentido filtrar un set o mapear un árbol? Sí. Las tres operaciones se aplican sobre muchos tipos distintos, y la unidad va a ir todavía más allá de las colecciones.

```scala
Set(1, 2, 3).map(_ * 10)   // Resultado: Set(10, 20, 30)
```

**"Declarativo" no es el término.** Es tentador decir que este código es "más declarativo" que el del nivel 1, y en comparación entre dos versiones la palabra sirve. Pero en el gran orden de las cosas lo que pasa es otra cosa: hay infinitos pasos posibles, y "la forma más abstracta" es una ilusión. Lo que existe son **órdenes de compartimentalización**: cada vez que trazás una línea y te alejás, perdés operaciones y ganás individuos. Alejarse es la palabra correcta, mejor que "subir": si hay un arriba y un abajo, hay un techo, una cantidad finita de pasos que podés dar; con la distancia siempre podés alejarte un poco más. Y cuando te alejás ves menos detalle e incluís más cosas en la vista. Y si te alejás lo suficiente, las cosas dejan de comportarse como cerca: patrones que eran claros dejan de verse, y aparecen otros que de cerca no tenían sentido.

Tampoco es una escalera con un solo camino. Es más bien un grafo: desde el pattern matching se podría haber ido a otras interfaces, y a `filter`/`map`/`flatMap` se podría haber llegado desde otro lado. Este fue un recorrido posible.

Un caso extremo lo muestra: `identity`, la función que devuelve lo mismo que recibe.

```scala
identity(5)        // Resultado: 5
identity("hola")   // Resultado: hola
```

Es una de las funciones más polimórficas que existen: funciona para **todos** los valores. Y sirve para casi nada, justamente porque ignora todo sobre lo que recibe. Es el límite de alejarse: incluir todo y no poder hacer nada.

**Para el parcial, si te preguntan:** *"¿Qué se gana y qué se pierde al escribir una operación con `filter`/`map`/`flatMap` en lugar de con pattern matching o con `fold`?"* Se pierde poder: hay cosas que ya no se pueden expresar (preguntar si la lista está vacía antes de operar; las tres siempre devuelven una lista). Se gana que el código queda escrito en términos del dominio y no del recorrido, que es imposible caer en casos inválidos (`head` de una vacía, un índice que no existe), y que las mismas tres operaciones sirven para muchas estructuras además de la lista. No es "más declarativo": es otro orden de compartimentalización, más lejos del detalle y con más individuos adentro.

## 6. 🟡 El desafío: describir las tres sin la palabra "conjunto"

> Hasta acá, `filter`, `map` y `flatMap` se describieron sobre colecciones. El siguiente paso es describirlas de una manera que **no implique** que hay muchas cosas adentro.

Hasta ahora, si tuvieras que explicar `filter`, dirías: agarra la colección, toma el primer elemento, se fija si cumple, si cumple lo mete en el resultado, sigue con el siguiente, y al terminar devuelve el resultado. `map`: agarra cada elemento, le aplica la transformación, lo mete en la lista resultante. `flatMap`: agarra cada elemento, le aplica la transformación, que da otra lista, y pone uno por uno los elementos de esa lista en la respuesta.

Ahora tratá de decir lo mismo **sin usar "cada elemento", "colección", ni nada que suponga que hay muchas cosas adentro**. Va a salir vago e insatisfactorio. Es el ejercicio de todos los módulos, una vez más: dar un paso atrás, perder poder, incluir más cosas. Pensalo antes de seguir; el Módulo 6 tiene la respuesta, y vale más si llegás con la pregunta hecha.

---

## Checkpoint

1. ¿De qué tres maneras se usaba el `fold` en las seis funciones? ¿Cómo se llama cada una?
2. Escribí las firmas de `filter`, `map` y `flatMap`. ¿Qué tienen en común las tres?
3. ¿Qué devuelve `map` si la función devuelve una lista por elemento? ¿Y `flatMap`? ¿Cuándo elegís uno u otro?
4. ¿Por qué `append` ya no hace falta en el nivel 4?
5. ¿Qué quiere decir que `map` "levanta" una función? Leé la firma de Haskell con el paréntesis.
6. ¿Qué es `filtrarPares`, y a partir de qué se construyó?
7. Nombrá algo que podías hacer con pattern matching y no podés con las tres operaciones. ¿Qué ganás a cambio?
8. ¿Por qué las limitaciones de este nivel son también una protección?
9. ¿Por qué "declarativo" no es el término correcto? ¿Qué quiere decir "órdenes de compartimentalización"?
10. ¿Qué tiene de especial `identity`, y qué muestra sobre alejarse?
11. Intentá describir `map` sin usar "cada elemento" ni "colección".

## Qué viene después

El Módulo 6 responde el desafío con una idea: una **caja** con algo adentro. Define qué operaciones mínimas tiene que tener una caja para que `filter`, `map` y `flatMap` funcionen sobre ella, y le pone el nombre con el que vas a encontrarla en todos lados: mónada.

**FIN DEL MÓDULO 5 — Nivel 4, `filter`, `map` y `flatMap`**
