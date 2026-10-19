# Clase desde cero — Tipado estático en Scala — Módulo 8: Casteo, y por qué existen los tipos paramétricos

**Unidad:** clase07 · **Lenguaje:** Scala 3.3.1 · **Densidad:** 🟡 se lee de corrido; es el puente a la clase siguiente

---

## Sobre este documento

**Qué cubre.** Un problema que los tipos nominales no pueden resolver solos: una **lista que sirva para cualquier cosa** y, al mismo tiempo, te deje usar lo que guardaste. Cómo se resolvía antes, con **casteo** (`asInstanceOf`): qué es, por qué existe, por qué falla en ejecución y por qué en el TP **no lo vas a usar**. Y la salida real: los **tipos paramétricos** (`List[Alumno]`), presentados hasta donde hace falta para entender el problema que la clase siguiente resuelve.

**Qué no cubre.** Cómo se diseñan tipos paramétricos propios, la varianza y lo que se rompe cuando se combinan con subtipado. Eso es la clase siguiente.

## De dónde venís

Del Módulo 3 (falsos negativos, `List().head`), del Módulo 4 (`Any` arriba de todo), del Módulo 6 (`Nothing`). De Haskell: `filter :: (a -> Bool) -> [a] -> [a]`.

---

## 1. 🟡 La lista vacía tiene tipo `List[Nothing]`

> Scala le asigna a cada expresión **el tipo más específico posible**. Una lista sin elementos puede ser lista de cualquier cosa; lo más específico que cumple eso es **lista de `Nothing`**.

```scala
  val listaVacia = List()             // el compilador infiere: List[Nothing]
  val numeros = List(1, 2, 3)         // infiere: List[Int]

  listaVacia.head                     // compila; en ejecución: NoSuchElementException: head of empty list
  numeros.head                        // Resultado: 1
```

Leé `List[Int]` como "lista de `Int`": lo que va entre corchetes dice **de qué** es la lista. En la sección 4 vas a ver qué es exactamente. Por ahora, dos cosas: `Nothing` volvió (es el tipo de "acá falta cualquier elemento"), y `head` sobre la lista vacía es la operación parcial del Módulo 3.

## 2. 🔴 El problema: una lista que sirva para todo

> Si la lista guarda `Any` para poder guardar cualquier cosa, entonces **devuelve `Any`**, y con un `Any` solo podés hacer lo que todo objeto hace. **Lo que metés ya no lo podés usar.**

Pensá cómo diseñarías una lista en un lenguaje con tipos, antes de que exista `List`. (Una lista es una **colección**: listas, conjuntos, mapas son estructuras que agrupan elementos.) En Haskell la tenés como `[a]`, con `filter :: (a -> Bool) -> [a] -> [a]`. En objetos, `filter` tiene **un parámetro menos**: la lista no se pasa, es el receptor del mensaje.

```scala
class Lista {
  def head: Any = ???                            // el primer elemento... de algún tipo
  def tail: Lista = ???
  def isEmpty: Boolean = ???
  def filter(criterio: Any => Boolean): Lista = ???   // recibe una función de Any a Boolean
}
```

¿Qué tipo le ponés a lo que contiene? Querés que sirva para alumnos, para caballos, para cualquier dominio que todavía nadie escribió. Lo razonable es **`Any`**: la lista contiene cosas. Así se escribió durante años en Java (con `Object`), y a nivel de tipos funciona perfecto: implementar `filter` es trivial.

Hasta que la usás:

```scala
  class Alumno(val aprobo: Boolean)

  val alumnos: Lista = new Lista          // imaginá que adentro hay alumnos (los ??? de arriba no importan acá)
  alumnos.filter { a => a.aprobo }
  //                     ^^^^^^^^
  //                     value aprobo is not a member of Any
```

(Este bloque solo muestra el error de compilación; con los `???` de `Lista`, correrlo explotaría antes de filtrar.)

`{ a => a.aprobo }` es una **función anónima**: recibe `a` y devuelve `a.aprobo` (la flecha `=>` separa parámetros de cuerpo). `filter` la va a aplicar a cada elemento. Y `a` es `Any`, porque **vos dijiste que la lista contenía `Any`**. Vos sabés que ahí adentro hay alumnos; el compilador solo sabe lo que declaraste. Es el falso negativo del Módulo 3 en su versión más frecuente: el programa funcionaría, y no se puede construir.

Y esto no es un caso raro: **el 80 % de los programas manejan colecciones**. Con listas de `Any`, estás en este problema casi todo el tiempo.

## 3. 🔴 Casteo: apagar el chequeador en un punto

> **Castear** es decirle al chequeador de tipos **qué tipo tiene que creer que tiene un valor**. No convierte el valor: el objeto sigue siendo lo que era. Solo **apaga el chequeo en ese punto**; si mentiste, falla **en ejecución**.

La definición importa, así que despacio. Un objeto nace de una clase y su tipo es el conjunto de mensajes que entiende; **eso queda fijo para siempre**. Un alumno casteado a `String` sigue siendo un alumno: lo que cambió es lo que el chequeador cree. El cast es "confiá en mí: esto es un `Alumno`", y el compilador acepta y sigue.

En Scala se escribe `asInstanceOf[Tipo]`:

```scala
  alumnos.filter { a => a.asInstanceOf[Alumno].aprobo }     // ✅ compila: le dijiste que a es Alumno
```

| Escribís | Sale |
|---|---|
| `a.aprobo` con `a: Any` | ❌ `value aprobo is not a member of Any` |
| `a.asInstanceOf[Alumno].aprobo` | ✅ compila: el cast va sobre **el elemento**, que es lo que creés que es un `Alumno` |
| `alumnos.asInstanceOf[Alumno].filter { … }` | ❌ `value filter is not a member of Alumno`: le dijiste al chequeador que **la lista** es un `Alumno`, te creyó, y un `Alumno` no filtra. El cast va sobre el elemento |
| `"hola".asInstanceOf[Alumno]` | ✅ compila, ❌ al correr: `java.lang.ClassCastException: class java.lang.String cannot be cast to class …Alumno` |

**¿CÓMO FUNCIONA?** Un cast pasa por tres momentos:

1. **Al compilar, el cast en sí nunca falla**: justamente le pediste al chequeador que no mire. Lo que viene *después* del cast se chequea con el tipo que declaraste: por eso `.filter` sobre algo casteado a `Alumno` sí da error.
2. **Al ejecutar, antes de usar el valor como `Alumno`**, Scala deja una verificación: la JVM mira si el objeto pertenece a la jerarquía de `Alumno` (en ejecución todos los objetos son `Object`, así que esta es la única pregunta que puede hacer: la madriguera del Módulo 4).
3. Si pertenece, sigue. Si no, lanza `ClassCastException` y la ejecución se corta ahí.

Jamás llega a mandarle `aprobo` a un `String`. Por eso en Scala **`method_missing` y `NoMethodError` carecen de sentido**: si llegaste a mandar un mensaje a algo que no lo entiende, la pifiaste bastante más que en Ruby, donde eso es parte del día.

**Por qué existe.** Si el chequeador está para que ciertos programas no se construyan, ¿para qué te da una herramienta para saltarlo? Porque **ningún sistema de tipos es perfecto** (Módulo 3): hay una fracción de programas válidos que rechaza, y el cast es la salida de emergencia para construirlos. No existe para usarse; existe para el día en que lo necesitás. Como un matafuegos.

**Por qué no lo vas a usar.** Hay dos razones.

1. Cada cast **apaga el chequeador**. Si casteás cada vez que recorrés una lista, estás pagando el costo de tipar todo (escribir anotaciones) sin la garantía que el tipado te daba. Así eran los programas con listas de `Object`: casteo en el 80 % del código, y de ahí viene gran parte de la mala fama histórica de los tipos: "al final terminás casteando todo". Era verdad entonces; dejó de serlo cuando llegó la sección 4.
2. **Scala tiene herramientas mejores**, y el TP está armado para que no haga falta. Si en el TP sentís que necesitás un `asInstanceOf`, es una señal de **frenar y cambiar lo que estás haciendo**: casi siempre hay un tipo que te estás olvidando de declarar, o un diseño que lo evita.

> **Para el parcial, si te preguntan**
> *¿Qué es castear?* — Indicarle al chequeador de tipos que trate un valor como si fuera de un tipo determinado, desactivando la verificación estática en ese punto. El valor no cambia de tipo; cambia lo que el compilador cree. Si el valor no es de ese tipo, falla en ejecución (`ClassCastException`). Existe porque ningún sistema de tipos acepta todos los programas válidos; no se usa en el TP porque hay herramientas mejores y porque cada cast anula la garantía que da el tipado.

🕳️ **Madriguera — castear en otros lenguajes.** En algunas tecnologías el cast no deja verificación en ejecución: el mensaje se manda igual y falla después, de formas más raras. Lo que Scala hace (chequear la pertenencia antes de seguir) es la versión segura. *Volvé al camino — esto se profundiza aparte, otro día.*

## 4. 🔴 Tipos paramétricos: la lista no existe hasta que decís de qué es

> Un **tipo paramétrico** recibe otro tipo como parámetro: no hay `List`, hay **`List[A]`**, y `A` se fija cuando la usás. `List[Alumno]` devuelve `Alumno` en `head` y recibe `Alumno` en `filter`: **el cast desaparece**.

Haskell lo tuvo siempre: `[a]` es "lista de `a`", y `filter :: (a -> Bool) -> [a] -> [a]` dice que lo que entra y lo que sale son del mismo `a`. El concepto de lista **no tiene sentido hasta que le proveés el `a`**. Lo que faltaba en la sección 2 era eso: la información sobre qué contiene la lista.

```scala
class Lista[A] {                                  // A: un parámetro de tipo. Se fija al usar la clase.
  def head: A = ???                               // devuelve un A, no un Any
  def tail: Lista[A] = ???
  def isEmpty: Boolean = ???
  def filter(criterio: A => Boolean): Lista[A] = ???   // recibe una función de A a Boolean
}
```

Y con la `List` de Scala, que ya está hecha así:

```scala
  class Alumno(val aprobo: Boolean)

  val alumnos: List[Alumno] = List(new Alumno(true), new Alumno(false))

  val aprobados = alumnos.filter { a => a.aprobo }   // ✅ a es Alumno: el compilador lo sabe
  aprobados.head.aprobo                              // ✅ head devuelve Alumno
  // Resultado: true
```

Sin cast. `alumnos` es `List[Alumno]`; el compilador sabe que `filter` recibe `Alumno => Boolean` y que `head` devuelve `Alumno`. Si tratás de meter otra cosa, te frena antes de correr:

| Escribís | Sale |
|---|---|
| `alumnos.filter { a => a.aprobo }` con `alumnos: List[Alumno]` | ✅ |
| `alumnos.filter { a => a.aprobo }` con `alumnos: List[Any]` | ❌ `value aprobo is not a member of Any` |
| `val l: List[Alumno] = List("hola")` | ❌ `Found: ("hola" : String) / Required: Alumno` |

Esto es lo que la sección 1 ya mostraba: `List[Nothing]` para la vacía, `List[Int]` para `List(1, 2, 3)`. El parámetro de tipo estaba ahí desde el principio.

**Un poco de contexto.** Java agregó esto tarde (los *generics*), como una capa encima de las listas de `Object` que ya existían, y por eso quedó una herramienta incompleta. Scala lo tiene desde el diseño, imita mejor a Haskell, y lo llama **tipos paramétricos**.

**Y la trampa.** Escribir `[Alumno]` y seguir es solo el principio. En cuanto los tipos paramétricos se cruzan con el **subtipado** (Módulo 4) aparecen problemas poco intuitivos: ¿una `List[Persona]` es subtipo de una `List[Nombrable]`? ¿Y una función que recibe `Persona`, respecto de una que recibe `Nombrable`? Hay que estudiar un poco para usar esto bien, y es exactamente la clase que viene: **varianza**.

> **Para el parcial, si te preguntan**
> *¿Qué problema resuelven los tipos paramétricos?* — Permiten escribir una estructura (una lista) que sirve para cualquier tipo de contenido sin perder la información de qué contiene: `List[Alumno]` devuelve `Alumno`, así que se usa lo guardado sin castear. Antes, con listas de `Any`/`Object`, había que castear cada elemento, lo que anulaba el chequeo de tipos justo en el código más frecuente.

## 5. 🟡 Las capas, para ubicarte

> Lo que viste en esta unidad son las primeras capas de una torre. Cada una agrega poder y problemas nuevos.

| Capa | Qué relaciona | Dónde |
|---|---|---|
| **Tipado** | un valor con un tipo (`a: Persona`) | Módulos 1–3 |
| **Subtipado** | un tipo con otro (`Persona <: Nombrable`) | Módulos 4–5 |
| **Tipos paramétricos** | un tipo con un parámetro de tipo (`List[A]`) | Este módulo, hasta acá |
| **Varianza** | tipos paramétricos con subtipado (`List[Persona]` vs `List[Nombrable]`) | La clase siguiente |

Como pasaba con los metamodelos en Ruby: el sistema se vuelve más complejo en la medida en que querés que las cosas funcionen de formas más elaboradas. Lo complejo es el problema (objetos y funcional, dos paradigmas que trabajan distinto, juntos); Scala agrega herramientas para resolverlo, y cada herramienta pide entender algo más.

🕳️ **Madriguera — límites de la plataforma.** Hay programas que tampoco se pueden construir por límites de la máquina que ejecuta: un método con más parámetros de los que la JVM indexa, por ejemplo. Nadie los necesita; los frameworks que generan código a veces los chocan. *Volvé al camino — esto se profundiza aparte, otro día.*

🕳️ **Madriguera — familias de tipos.** En Haskell, `Eq a =>` y `Ord a =>` no son subtipado: son *clases de tipos*, otra rama de la teoría (teoría de categorías). Es un problema más simple que el de objetos, y queda fuera de esta materia. *Volvé al camino — esto se profundiza aparte, otro día.*

---

## Checkpoint (sin respuestas)

1. ¿Qué tipo tiene `List()` y por qué? ¿Qué relación tiene con `Nothing`?
2. ¿Por qué `filter` tiene un parámetro menos en objetos que en Haskell?
3. Diseñás una `Lista` que contiene `Any`. ¿Qué podés meter? ¿Qué podés hacer con lo que sacás?
4. Definí castear con tus palabras, sin usar la palabra "convertir". ¿Qué cambia y qué no?
5. ¿Dónde va `asInstanceOf` en `alumnos.filter { … }`: en la lista o en el elemento? ¿Qué pasa si lo ponés en el otro lado?
6. ¿Cuándo falla un cast mal hecho? ¿Qué verificación hace Scala en ejecución?
7. ¿Por qué existe el cast si el chequeador está para que ciertos programas no se construyan? ¿Por qué no lo vas a usar en el TP?
8. ¿Qué es `List[A]`? ¿Qué devuelve `head` y qué recibe `filter` en una `List[Alumno]`?
9. ¿Qué problema aparece cuando los tipos paramétricos se cruzan con el subtipado? ¿Cómo se llama el tema de la clase que viene?

## Qué viene después

Esta fue la última pieza de la unidad. La clase siguiente arranca donde terminó este módulo: `List[Persona]`, `List[Nombrable]`, y la pregunta de si una es subtipo de la otra. Antes de eso, dos cosas: el código final de la unidad (`fuente-repo-clase07-tipado-estatico.md`) tiene todo lo que construiste en los Módulos 4 a 7, compilable en el proyecto del Módulo 0 (`Alumno` y `Lista` de este módulo son demostraciones y quedan afuera de ese código); y los checkpoints de los nueve módulos, hechos de corrido sin mirar, son el repaso.

**FIN DEL MÓDULO 8 — FIN DE LA CLASE DESDE CERO**
