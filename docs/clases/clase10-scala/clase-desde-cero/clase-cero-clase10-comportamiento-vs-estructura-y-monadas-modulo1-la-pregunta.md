# Clase desde cero — Comportamiento vs estructura y mónadas — Módulo 1: De dónde venimos y la pregunta de esta clase

**Unidad:** clase10 · **Lenguaje:** Scala 3.3.1 · **Archivos del proyecto:** `monadas/Micro.scala`, `monadas/Instructions.scala` (vistazo) · **Densidad:** 🟡 se lee de corrido; es el mapa de la unidad

---

## Sobre este documento

**Qué cubre.** Dónde está parada la materia (los dos triángulos), dónde quedó el micro, y cuál es la pregunta que esta unidad se pone a responder: cómo hace funcional para abstraer, y por qué eso cambia la forma de encarar un problema. Es un módulo corto, de orientación: fija el vocabulario y la tesis, y deja planteado el camino de los diez que siguen.

**Qué no cubre.** Nada de lo nuevo se explica acá. Las listas, el `fold`, las cajas, `Option`, `Try` y el `for` tienen su módulo.

## De dónde venís

De la unidad anterior: el micro inmutable (`case class Micro` con `require` y `copy`), las instrucciones como `case class` y `case object`, `run` con `foldLeft`, y un `Result` con tres formas (`Success`, `Halted`, `Failure`) que `run` devuelve en lugar de lanzar la excepción del `HALT`. También las dos tríadas: las tres ideas de objetos (encapsulamiento, delegación, polimorfismo de subtipado) y las tres de funcional (polimorfismo paramétrico, pureza, orden superior), y cómo chocan vértice a vértice. De Paradigmas: `map`, `filter` y `fold` de Haskell sobre listas, y las listas como `[]` y `(x:xs)`.

---

## 1. 🟡 Los dos triángulos, como mapa

> Objetos se sostiene en tres ideas: **polimorfismo de subtipado, encapsulamiento y delegación**. Funcional, en otras tres: **orden superior, pureza y polimorfismo paramétrico**. Esta unidad trabaja el vértice de orden superior hasta llegar, a través de él, a la pureza.

```
   Polimorfismo (subtipado)          Orden superior ★         Pureza (sin efecto + TR)
            /\                        ________________________
           /  \                       \                      /
          / 👁️ \                        \        👁️         /
         /______\                         \                /
                                            \            /
  Encapsulamiento   Delegación                \        /
                                                 \    /
                                          Polimorfismo paramétrico
                                             (pattern matching)
```

El triángulo de la izquierda es el de siempre: encontrás el objeto, le mandás el mensaje, él delega. El de la derecha es el que esta mitad de la materia mete adentro de Scala, y quedó pendiente en dos de sus tres vértices:

- **Polimorfismo paramétrico** ya se usó: las instrucciones son datos y `run`, `print` y `simplify` las miran con pattern matching.
- **Pureza** se recuperó en parte: el micro no se muta (`copy` devuelve otro), y `run` devuelve un `Result` en vez de explotar. "TR" es transparencia referencial: cualquier expresión se puede reemplazar por su resultado, porque el resultado sale solo de los parámetros.
- **Orden superior** apareció apenas, con `foldLeft`. Es el vértice con la estrella: por acá entra esta unidad.

Lo que esta unidad agrega es que los tres vértices de funcional están conectados: el orden superior es la herramienta con la que funcional abstrae, y abstraer es lo que le permite manejar el efecto (los errores, la ausencia de un valor, lo que tarda) sin romper la pureza. Al final del camino se vuelve al micro con esa herramienta, y el código que la unidad anterior dejó enredado queda simple.

## 2. 🟡 Dónde quedó el micro

> El micro de esta unidad es el mismo de la anterior: el `Micro` inmutable y las siete instrucciones. Lo que cambia son las cuatro versiones de `run`, que llegan recién en el Módulo 10.

```scala
package tadp.microprocesador.monadas

object Micro {
  val MEM_SIZE = 128
  val REGISTER_SIZE = 1024
}

case class Micro(a: Int, b: Int, mem: List[Int] = List.fill(Micro.MEM_SIZE)(0)) {
  require(a < Micro.REGISTER_SIZE && a > -Micro.REGISTER_SIZE)
  require(b < Micro.REGISTER_SIZE && b > -Micro.REGISTER_SIZE)
  require(mem.size == Micro.MEM_SIZE)
}
```

```scala
package tadp.microprocesador.monadas

sealed trait Instruction

case object Add extends Instruction
case object Mul extends Instruction
case object Swap extends Instruction
case class Load(address: Int) extends Instruction
case class Store(address: Int) extends Instruction
case class If(subInstructions: List[Instruction]) extends Instruction
case object Halt extends Instruction
```

El último `run` que tenés (el de `inmutable/Operations3`, en el proyecto de la unidad anterior) devuelve un `Result`. Para hacerlo, mira **a mano** la forma del resultado anterior y la instrucción, en cada paso:

```scala
case (previousResult: Halted, _)                            => previousResult
case (previousResult: Failure, _)                           => previousResult
case (Success(micro), Add)                                  => Result(micro)(micro.copy(a = micro.a + micro.b))
// … y así con cada instrucción
case (previousResult @ Success(micro), If(subInstructions)) => if (micro.a == 0) run(subInstructions, micro) else previousResult
case (Success(micro), Halt)                                 => Halted(micro)
```

Funciona, y se ve peor que el `foldLeft` sin `Result`: cada caso pregunta dos cosas y envuelve su respuesta. Esa incomodidad es el síntoma de que falta una herramienta. `Result` quedó armado como **estructura** (tres formas y un `foldLeft` que las revisa); lo que falta es el **comportamiento** que esa estructura tendría que saber hacer sola. El título de la unidad es eso: comportamiento contra estructura.

Y ojo con el `HALT`. `Result` lo convirtió en `Halted(micro)`, pero el `throw` no desapareció del todo: las otras dos versiones de `run` de la unidad anterior (la de la variable local y la del `foldLeft` a secas) siguen lanzando `ExecutionHaltException`, y en el Módulo 10 vas a ver que las dos versiones con `Try` vuelven a lanzarla, adentro de una caja. Lo que cambia es dónde queda atrapada.

## 3. 🔴 Objetos responde siempre lo mismo; funcional construye desde abajo

> En objetos, la respuesta a "¿cómo resuelvo esto?" es siempre la misma: **encontrá el objeto y mandale el mensaje**. En funcional no hay una respuesta única: se pregunta **qué es lo mínimo que necesito** y se construye todo lo demás a partir de eso.

De objetos no hay mucho más que saber que lo que ya sabés: un objeto, un mensaje, parámetros. Hay años de experiencia en cómo aplicar esas tres herramientas, pero la forma de encarar cualquier problema es una sola, y eso es lo que lo hace tan poderoso: no importa si estás modelando un cliente o mandando bytes por un cable, la pregunta es "¿cuál es el objeto y qué mensaje le mando?". Objetos está "aflorado en las puntas": no le importa si lo hacés con mixins, traits o clases, ni qué había antes de los objetos; adentro, siempre el mismo mecanismo. Objetos no define nada por debajo de eso. Una lista, en objetos, se define igual que cualquier otra clase: instancias y mensajes.

Funcional arranca desde otro lugar. Pregunta: **¿cuál es la forma más básica de trabajar?** ¿Qué es lo más bajo de lo bajo, lo que el lenguaje tiene que dar de forma nativa, a partir de lo cual se puede construir todo el resto? Es la pregunta que se hace quien diseña un lenguaje funcional, y también la que vas a hacerte en esta unidad varias veces, cada vez un nivel más arriba.

Un ejemplo de esa forma de pensar: `map`, `filter` y todas las operaciones sobre listas se pueden escribir usando solo `fold`. Entonces un lenguaje no necesita darte cada una como primitiva: con `fold` alcanza, y lo demás se construye adentro de las reglas del lenguaje. Y construir adentro de las reglas es mejor que construir desde afuera, porque lo que está afuera es excepcional: para cambiarlo o extenderlo hay que tocar el compilador, mientras que lo que está adentro se cambia con las mismas herramientas que tenés para todo.

**Para el parcial, si te preguntan:** *"¿En qué se diferencia la forma de encarar un problema en objetos y en funcional?"* En objetos la forma es una sola: encontrar el objeto y mandarle el mensaje; el paradigma define ese mecanismo y nada por debajo. En funcional se parte de lo mínimo (pattern matching sobre la forma de los datos, o una primitiva como `fold`) y se construyen niveles de abstracción encima; cada nivel es una forma distinta de trabajar, y elegir el nivel es parte de resolver el problema.

## 4. 🟡 Pattern matching no es una función

> Pattern matching es la herramienta más básica de funcional, y **no es una función**: tiene guardas, puede fallar y seguir probando, puede no tener respuesta. El paradigma la da y enseguida la abandona a favor de las funciones.

Fijate lo que hace un `match`: detecta la forma de un valor, deconstruye sus partes, elige un camino de ejecución, y si una guarda no se cumple sigue con el caso siguiente. Es una pieza de sintaxis con reglas propias, con casos excepcionales, con la posibilidad de ser parcial (no cubrir todos los valores). (Un tercio de Paradigmas fue explicar esos casos: dónde vale poner qué patrón.) En Haskell ni siquiera había una palabra `match`: pattern matching era la forma que se le daba a los parámetros de una función, y el compilador elegía qué ecuación usar. Está muy abajo de todo, y aun así **no es ninguna de las herramientas que el paradigma promueve**. El paradigma quiere que trabajes con funciones; el pattern matching es lo que usa para arrancar.

Por eso el nombre importa: la idea es **polimorfismo paramétrico** (decidir desde afuera, mirando la forma), y el pattern matching es una herramienta para ejercerlo. Con qué ideas de objetos choca (encapsulamiento, delegación) ya se vio en la unidad anterior; acá se toma como punto de partida. Esta unidad empieza ahí, en el nivel más bajo, y se va alejando.

## 5. 🟡 Esta unidad parece de listas y es de abstracción

> Los cuatro módulos que siguen van a trabajar con listas todo el tiempo. El tema no son las listas: es **cómo funcional maneja la abstracción**, y eso es lo que hace falta para entender cómo maneja el efecto.

El plan es este. Se toma un problema chico (materias, cursos, alumnos) y se resuelve con lo más básico, pattern matching sobre la forma de la lista. Después se da un paso atrás: se esconde la forma detrás de cinco funciones. Después otro: se nombra el recorrido (`fold`). Después otro: se nombran las operaciones (`filter`, `map`, `flatMap`). Y después otro más, que ya no es de listas: se nombra la **caja** que las tres operaciones comparten, y ahí aparecen `Option`, `Try`, el `for` y la forma de volver al micro.

En cada paso se pierde algo y se gana algo. Se pierde poder: cosas que podías hacer en el nivel de abajo y en el de arriba ya no. Se ganan individuos: cosas sobre las que el mismo código ahora puede actuar. Y en cada paso hay una trampa, que el Módulo 3 enuncia y los siguientes repiten.

Una aclaración honesta. Hay una teoría completa detrás de esto (es una materia entera en otras carreras), y no la vas a ver. Es como aprender a tocar una canción de oído, sin leer música ni armonía: se puede y suena. Entender lo que hay abajo es otra cosa. Lo que esta unidad busca es un panorama de golpe, lo justo para que haga **clic**: entender la idea de caja lo suficiente como para usar `Option`, `Try` y las operaciones de orden superior con criterio en el TP. Las respuestas a "¿y cómo se describe eso sin hablar de listas?" van a parecer vagas e insatisfactorias; es a propósito. Y varias decisiones van a parecer caprichosas; parecen caprichosas porque no se ve la raíz que las justifica, y esa raíz es la teoría que no se va a dar. Dar un paso atrás para ver más cosas es exactamente perder detalle.

---

## Checkpoint

1. ¿Cuáles son las tres ideas de cada triángulo? ¿Cuál de las tres de funcional es la entrada de esta unidad, y por qué?
2. ¿Qué significa "TR" en el vértice de pureza?
3. ¿Qué tiene de incómodo el último `run` de la unidad anterior? ¿Qué quiere decir que `Result` quedó como estructura y le falta comportamiento?
4. ¿Cuál es la única respuesta que da objetos a "¿cómo resuelvo esto?"? ¿Por qué eso es una fortaleza?
5. ¿Qué pregunta se hace funcional en lugar de esa? Dá un ejemplo de "lo mínimo" a partir de lo cual se construye el resto.
6. ¿Por qué construir adentro de las reglas del lenguaje es mejor que construir desde afuera?
7. ¿Por qué pattern matching no es una función? Nombrá dos cosas que hace y una función no.
8. ¿Qué se pierde y qué se gana en cada paso de abstracción?

## Qué viene después

El Módulo 2 arranca el camino en el nivel más bajo: la consulta sobre materias, cursos y alumnos resuelta con pattern matching sobre la forma de la lista, y lo que pasa cuando esa forma cambia.

**FIN DEL MÓDULO 1 — De dónde venimos y la pregunta de esta clase**
