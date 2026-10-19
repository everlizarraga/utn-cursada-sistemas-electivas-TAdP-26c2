# Clase desde cero — Type arguments y varianza en Scala — Módulo 5: Varianza I: por qué un `Set[Vaca]` no es un `Set[Animal]`

**Unidad:** clase08 · **Lenguaje:** Scala 3.3.1 · **Densidad:** 🔴 pide una sesión con el código abierto; es el centro de la unidad

---

## Sobre este documento

**Qué cubre.** El error del pastor, tomado en serio: el compilador dice que un `Set[Vaca]` no es un `Set[Animal]`, y hay que decidir si está equivocado él o vos. Se decide con un **contraejemplo**: un programa que, si el compilador cediera, explotaría. Con eso en la mano, el nombre del fenómeno (**varianza**), su primera forma (**invarianza**) con la notación formal, la forma trivial de los lenguajes sin tipos (**bivarianza**), y la colección donde la respuesta cambia: `List`, inmutable y **covariante**. Al final, dos cosas que te van a parecer raras y están bien: tu `Corral[T <: Animal]` también es invariante, y el `Set` inmutable del código de referencia también.

**Qué no cubre.** La tercera forma de varianza (contravarianza), que aparece con las funciones en el Módulo 6, y el precio de declarar un tipo covariante (Módulo 7).

## De dónde venís

Del Módulo 1: un sistema *sound* rechaza antes que arriesgar una explosión; Liskov: `S` sustituye a `T` solo si hace todo lo que `T` promete. Del Módulo 3: el pastor roto, `vacas1.add(new Caballo)` rechazado, "¿y si el conjunto fuera de animales?". Del Módulo 4: el bound acota `T` y el pastor sigue roto. De la clase anterior: el cast apaga el chequeador y explota en ejecución (M8), y la pregunta final: ¿`List[Persona]` es subtipo de `List[Nombrable]`? El código de las secciones 1 a 3 sigue con `import scala.collection.mutable.Set`.

---

## 1. 🔴 El error, simplificado

> El error del pastor es ajeno al corral. Se reproduce con dos variables: **el compilador rechaza guardar un `Set[Vaca]` en una variable `Set[Animal]`**.

```scala
import scala.collection.mutable.Set

  val vacas: Set[Vaca] = Set(new Vaca, new VacaLoca)
  val animales: Set[Animal] = vacas
  //                          ^^^^^
  // ❌ Found:    (vacas : collection.mutable.Set[tadp.granja.Vaca])
  //    Required: collection.mutable.Set[tadp.granja.Animal]
```

Leé el error con la regla del Módulo 1: una variable de tipo `X` acepta un `X` o un subtipo de `X`. El compilador rechaza la asignación; entonces, para él, **`Set[Vaca]` no es subtipo de `Set[Animal]`**. Eso es lo que dice. Y choca con lo que vos sabés: `Vaca` sí es subtipo de `Animal`, y lo probaste en el Módulo 1 con `val animal: Animal = new Vaca`.

Es también el primer choque del Módulo 3: `CorralDeVacas extends Corral(animales)` le pasaba un `Set[Vaca]` a un constructor que pedía `Set[Animal]`. Misma asignación, mismo rechazo.

Es como pedir comida en un restaurante, que te traigan humus, y que vos digas "yo pedí comida". Hay una disputa, y hay dos salidas posibles: o el chequeador tiene un defecto y rechaza algo válido (un falso negativo más, como la vaca loca que no se ríe), o hay algo que vos todavía ves de un solo lado. La promesa *sound* del Módulo 1 dice que el chequeador rechaza cuando puede garantizar poco; la pregunta es si acá puede garantizar más de lo que vos creés.

Un detalle de vocabulario, para separar las cosas: `Vaca` y `Animal` son los **tipos componentes**; `Set[Vaca]` y `Set[Animal]` son los **tipos compuestos** (el paramétrico con su argumento). La relación entre los componentes la conocés. La pregunta es sobre la relación entre los compuestos.

## 2. 🔴 El contraejemplo: el caballo en el conjunto de vacas

> `Set[Vaca]` sería subtipo de `Set[Animal]` solo si un conjunto de vacas pudiera hacer **todo** lo que hace un conjunto de animales. Hay algo que un conjunto de animales hace y uno de vacas tiene que rechazar: **aceptar un caballo**.

Es Liskov, aplicado al conjunto en vez de a la vaca. Para que `S` sustituya a `T`, `S` tiene que cumplir toda la interfaz de `T`. Entonces la pregunta se vuelve concreta: ¿hay algo que se pueda hacer con un `Set[Animal]` y rompa si adentro hay un `Set[Vaca]`? Supongamos por un momento que el compilador cede. Cada línea de este bloque es válida por sí sola para el tipo declarado de su variable:

```scala
  val vacas: Set[Vaca] = Set(new Vaca, new VacaLoca)
  val animales: Set[Animal] = vacas      // SUPONGAMOS que esto compila: las dos variables apuntan al mismo conjunto

  animales.foreach(animal => animal.come)   // ✅ válido para un Set[Animal]: todo lo de adentro come
  vacas.foreach(vaca => vaca.ordeñate)      // ✅ válido para un Set[Vaca]: todo lo de adentro se ordeña

  animales.add(new Caballo)                 // ✅ válido para un Set[Animal]: un caballo es un animal
  vacas.foreach(vaca => vaca.ordeñate)      // 💥 el tercer elemento es un caballo: caballo.ordeñate explota
```

Seguilo elemento por elemento. Las dos variables apuntan **al mismo objeto** (Módulo 1, sección 3: un objeto, varias variables). A través de `animales`, agregar un caballo es legal: `add` de un `Set[Animal]` recibe un `Animal`. El conjunto, que es uno solo, ahora tiene una vaca, una vaca loca y un caballo. A través de `vacas`, recorrerlo y ordeñar es legal: `foreach` de un `Set[Vaca]` entrega `Vaca`. La vaca se ordeña; la vaca loca se ordeña; el caballo recibe `ordeñate` y **explota en ejecución**.

Ninguna línea está mal por sí misma. La combinación explota. Y la única línea que el compilador puede frenar para evitarlo es la segunda: la que hace que dos variables de tipos distintos miren el mismo conjunto. Por eso la rechaza. **El compilador tenía razón**, y lo que vos veías de un solo lado era esto: pensabas en la vaca como individuo (una vaca es un animal), y la pregunta era sobre el conjunto como objeto con operaciones.

**Si lo forzás, explota de verdad.** El cast de la clase anterior apaga el chequeador en ese punto, y el programa de arriba se puede construir:

```scala
  val vacas: Set[Vaca] = Set(new Vaca, new VacaLoca)
  val animales: Set[Animal] = vacas.asInstanceOf[Set[Animal]]   // ✅ compila: le dijiste que confíe
  animales.add(new Caballo)                                    // ✅ el caballo entra
  println(vacas.size)                                          // Resultado: 3
  vacas.foreach(vaca => vaca.ordeñate)
  // en ejecución: java.lang.ClassCastException: class tadp.granja.Caballo cannot be cast to class tadp.granja.Vaca
```

Exactamente la explosión que el rechazo evitaba, con el mensaje que la clase anterior anticipó para un cast mentiroso. Es la respuesta al hilo que dejó el Módulo 1: el rechazo del Módulo 5 **cumple** la promesa *sound*, y el cast es el único lugar donde la promesa se suspende.

| Escribís | Scala entiende | Sale |
|---|---|---|
| `val animal: Animal = new Vaca` | una vaca donde se espera un animal | ✅ `Vaca <: Animal` |
| `val animales: Set[Animal] = vacas` con `vacas: Set[Vaca]` | un conjunto de vacas donde se espera uno de animales | ❌ `Found: collection.mutable.Set[Vaca] / Required: collection.mutable.Set[Animal]` |
| `val animales: Set[Animal] = Set[Vaca]()` | un conjunto de vacas vacío donde se espera uno de animales | ❌ `Found: scala.collection.mutable.Set[Vaca] / Required: collection.mutable.Set[Animal]`: vacío o lleno, el tipo es el que importa |
| `vacas.asInstanceOf[Set[Animal]]` y después `add(new Caballo)` | apagar el chequeador | ✅ compila; 💥 `ClassCastException` al recorrer `vacas` |

> **Para el parcial, si te preguntan**
> *¿Por qué un `Set[Vaca]` no es un `Set[Animal]`, si una vaca es un animal?* — Porque un `Set[Animal]` acepta `add(new Caballo)` y un `Set[Vaca]` tiene que rechazarlo. Si `Set[Vaca]` fuera subtipo de `Set[Animal]`, dos variables de esos tipos podrían apuntar al mismo conjunto; por la de animales entraría un caballo y por la de vacas se lo ordeñaría, y eso explota en ejecución. Es el principio de sustitución aplicado al conjunto: un `Set[Vaca]` no puede hacer todo lo que un `Set[Animal]` promete.

## 3. 🔴 Varianza: cómo se relacionan los compuestos cuando se relacionan los componentes

> **Varianza** es el estudio de cómo varía el subtipado de un tipo compuesto (`Set[A]`) en relación con el subtipado de su parámetro (`A`). Para `Set`, la respuesta es **invarianza**: `Set[A]` es subtipo de `Set[B]` **solo si `A` y `B` son el mismo tipo**.

Ya tenés el caso; ahora el nombre. La pregunta general es: si `A` es subtipo de `B`, ¿qué sé de `T[A]` respecto de `T[B]`? Para el `Set`, sabés que `Vaca <: Animal` y que, aun así, `Set[Vaca]` no es subtipo de `Set[Animal]`. Al revés, igual: un conjunto de animales en una variable de vacas dejaría ordeñar caballos. La relación entre los componentes **queda sin transmitirse** a los compuestos. A eso se lo llama invarianza, y se escribe así:

```
   A =:= B
──────────────    →   Invarianza:  T[A] es subtipo de T[B] solo si A y B son el mismo tipo
 T[A] <: T[B]
```

Leé la raya como una condición **exacta**: lo de abajo vale **exactamente cuando** vale lo de arriba. Para la invarianza: `T[A] <: T[B]` solo si `A =:= B` ("`A` es el mismo tipo que `B`"). Fijate que la `T` es la misma a los dos lados: se compara `Set` con `Set`, `Corral` con `Corral`. Es la notación que vas a encontrar en los textos sobre tipos, y la misma lectura vale para las reglas que vienen.

**Es una propiedad, y el compilador la verifica.** La varianza de un tipo se establece y después **vale**: un `Set` es invariante, y ningún uso lo cambia. Lo que vos podés hacer es entender por qué y diseñar con eso; discutirle al compilador es inútil, como se vio en la sección 1.

La invarianza es un caso trivial: ignora la relación entre `A` y `B`. **El otro caso trivial es el opuesto: bivarianza.** Es cuando `T[A] <: T[B]` vale **para todo `A` y `B`**, sin condición: un conjunto de lo que sea es subtipo de un conjunto de cualquier otra cosa.

```
 T[A] <: T[B]   ∀ A, B      →   Bivarianza        (∀ se lee "para todo")
```

Es lo que tienen los lenguajes sin chequeo de tipos, por omisión: en Ruby o en JavaScript dos conjuntos son "conjuntos" y listo. ¿Cómo evitan los caballos en los conjuntos de vacas? **No los ponen**, y cada tanto alguien ordeña un caballo. Era la situación antes del chequeo de tipos: la restricción existe para que ese error sea imposible de escribir. En Scala ningún tipo es bivariante.

Dos referencias para ubicarte. **Java** es invariante en sus tipos genéricos: una lista de vacas nunca es una lista de animales, y hay que vivir con eso o castear. **TypeScript** nació sin varianza (todo bivariante, heredado de JavaScript), y la fue agregando cuando su comunidad empezó a encontrar caballos en sus conjuntos de vacas.

🕳️ **Madriguera — `=:=` en Scala.** El símbolo de la notación existe también como tipo en Scala, para pedir en una firma que dos tipos sean iguales. No se usa en la materia. *Volvé al camino — esto se profundiza aparte, otro día.*

🕳️ **Madriguera — wildcards de Java.** Java tiene una forma de expresar "lista de algo que extiende `Animal`" en el punto de uso (`List<? extends Animal>`), que recupera parte de lo que la invarianza quita. *Volvé al camino — esto se profundiza aparte, otro día.*

## 4. 🔴 `List`: inmutable, y covariante

> La operación que rompía era `add`. **Una colección sin `add`** (inmutable) **puede ser covariante**: `List[Vaca]` **sí** es subtipo de `List[Animal]`, y el compilador lo acepta.

Volvé al contraejemplo y buscá la línea culpable. Todo el peligro venía de **una** operación: `animales.add(new Caballo)` modificaba el conjunto compartido. Sacada esa operación, dos variables que apuntan a la misma colección quedan a salvo una de otra: lo que hay adentro es lo que había al construirla, para siempre. Eso es una colección **inmutable**, y ya trabajaste con una en Paradigmas: la lista de Haskell, que se construye con cabeza y cola, y a la que nunca se le "agrega" un elemento, sino que se crea otra lista con uno más.

Scala tiene exactamente eso: `List`.

```scala
  val vacas: List[Vaca] = List(new Vaca, new VacaLoca)
  val animales: List[Animal] = vacas                     // ✅ compila: List[Vaca] es subtipo de List[Animal]

  animales.foreach(animal => animal.come)                // ✅
  vacas.foreach(vaca => vaca.ordeñate)                   // ✅

  animales.add(new Caballo)
  // ❌ value add is not a member of List[tadp.granja.Animal]

  val conCaballo: List[Animal] = animales :+ new Caballo // ✅ una lista NUEVA, con el caballo al final
  println(vacas.size)                                    // Resultado: 2
  println(conCaballo.size)                               // Resultado: 3
  println(vacas eq animales)                             // Resultado: true   ← siguen siendo el mismo objeto
```

`:+` es "esta lista, más este elemento al final": devuelve una lista nueva y deja la original igual. (`eq` compara si dos variables apuntan al mismo objeto.) Así se "agrega" en una colección inmutable: construyendo otra. El caballo quedó en `conCaballo`; `vacas` y `animales` apuntan a la misma lista de dos vacas, y recorrer `vacas` y ordeñar es seguro para siempre.

| Escribís | Scala entiende | Sale |
|---|---|---|
| `val animales: Set[Animal] = vacas` con `vacas: Set[Vaca]` mutable | conjunto de vacas como conjunto de animales | ❌ `Found: … Set[Vaca] / Required: … Set[Animal]` |
| `val animales: List[Animal] = vacas` con `vacas: List[Vaca]` | lista de vacas como lista de animales | ✅ |
| `animales.add(new Caballo)` con `animales: List[Animal]` | agregar a una lista | ❌ `value add is not a member of List[Animal]` |
| `animales :+ new Caballo` | una lista nueva con el caballo | ✅ `List[Animal]` de 3; la original sigue con 2 |

A esta relación, donde el subtipado del compuesto **va en el mismo sentido** que el de los componentes, se la llama **covarianza**:

```
   A <: B
──────────────    →   Covarianza:  si A es subtipo de B, T[A] es subtipo de T[B]
 T[A] <: T[B]
```

Las dos flechas van para el mismo lado: `Vaca → Animal`, `List[Vaca] → List[Animal]`. Guardá esa forma de decirlo (**dirección**, en vez de "es subtipo de"), porque en el Módulo 6 va a aparecer una relación que va para el otro lado.

**Dónde está escrito.** En la definición de `List`, en la biblioteca de Scala, la primera línea es esta:

```scala
sealed abstract class List[+A]
```

(`abstract class` es una clase con métodos sin cuerpo que las subclases completan; `sealed` dice que sus subclases viven en el mismo archivo. Lo que importa acá es el `+`.) Ese `+` adelante de la `A` es la anotación de covarianza: dice "este parámetro de tipo es covariante". `Set` tiene `A` a secas, y eso es invarianza, la opción por omisión. Una precisión que importa: **lo covariante es el parámetro `A`, no la lista**. Un tipo con varios parámetros puede tener uno covariante y otro invariante, y el Módulo 6 muestra uno. La frase completa es "`List` es covariante respecto de su parámetro `A`".

Es la respuesta a la pregunta con la que terminó la clase anterior: **sí**, `List[Persona]` es subtipo de `List[Nombrable]`, porque `List` es covariante en `A`. Y la razón de fondo es que la lista es inmutable: por la referencia ancha es imposible meterle un `Nombrable` ajeno a `Persona`.

**Salto de fe, declarado.** Hasta acá viste que sacar `add` elimina el contraejemplo que encontraste. Que **ninguna** otra operación de la lista pueda romper es algo que todavía te pido que creas; el Módulo 7 lo demuestra y, de paso, muestra el precio que la lista paga por ser covariante.

> **Para el parcial, si te preguntan**
> *¿Por qué `List[Vaca]` es subtipo de `List[Animal]` y `Set[Vaca]` (mutable) no?* — Porque `List` es inmutable: tiene cero operaciones que modifiquen la lista, así que dos referencias de tipos distintos a la misma lista no pueden lastimarse, y `List` puede declararse covariante (`List[+A]`). El `Set` mutable tiene `add`, por el que entraría un caballo a través de la referencia de animales; por eso es invariante. Covarianza: el subtipado del compuesto va en el mismo sentido que el de su parámetro.

## 5. 🔴 Tu `Corral[T <: Animal]` también es invariante

> Un tipo paramétrico propio es **invariante por omisión**, aunque tenga bound. El bound y la varianza responden **preguntas distintas**: el bound dice qué `T` se puede elegir; la varianza dice cómo se relacionan `Corral[A]` y `Corral[B]` entre sí.

```scala
import scala.collection.mutable.Set

class Corral[T <: Animal](val animales: Set[T])

  val c2: Corral[Animal] = new Corral[Vaca](Set(new Vaca))
  // ❌ Found:    tadp.granja.Corral[tadp.granja.Vaca]
  //    Required: tadp.granja.Corral[tadp.granja.Animal]
```

Es la misma pared, con tu propio tipo. Y es razonable que sea invariante: adentro hay un `Set` mutable de `T`, y el contraejemplo del caballo se repite igual, un nivel más adentro.

¿Y si el corral guarda una `List`? El pastor, por fin, pastorea:

```scala
class Corral[T <: Animal](val animales: List[T])

class Pastor {
  def pastorear(animales: List[Animal]): Unit = animales.foreach(_.come)
}

  val corralito: Corral[Vaca] = new Corral(List(new Vaca, new Vaca))
  new Pastor().pastorear(corralito.animales)              // ✅ List[Vaca] es List[Animal]
  println(corralito.animales.map(_.peso))                  // Resultado: List(110, 110)
```

`corralito.animales` es `List[Vaca]`; el pastor pide `List[Animal]`; `List` es covariante; entra. El hilo del pastor se cierra acá en lo que respecta al **conjunto** (la otra mitad, un `Corral[Vaca]` donde se pide un `Corral[Animal]`, es el Módulo 8). Porque el corral en sí sigue invariante:

```scala
  val c2: Corral[Animal] = new Corral[Vaca](List(new Vaca))
  // ❌ Found:    tadp.granja.Corral[tadp.granja.Vaca]
  //    Required: tadp.granja.Corral[tadp.granja.Animal]
```

Guardar una lista inmutable adentro deja al corral invariante: la varianza de `Corral` es una propiedad de `Corral`, y por omisión es invariante. Si querés que un corral de vacas sea un corral de animales, hay que decirlo, con el mismo `+` que tiene `List`. El `+` es una intención que el compilador acepta solo si las operaciones del tipo la permiten: un `Set` con `add` jamás podría llevarlo. Ese chequeo es el Módulo 7; el corral terminado, con su `+`, es el Módulo 8.

| Pregunta | La responde | Ejemplo |
|---|---|---|
| ¿Qué tipos puede tomar `T`? | el **bound** | `T <: Animal`: `Corral[Int]` se rechaza con `Type argument Int does not conform to upper bound Animal` |
| ¿`Corral[Vaca]` es subtipo de `Corral[Animal]`? | la **varianza** | por omisión queda afuera; con `+T`, entra |

> **Para el parcial, si te preguntan**
> *Un `Corral[T <: Animal]` guarda una `List[T]`. ¿`Corral[Vaca]` es subtipo de `Corral[Animal]`?* — No. Un tipo paramétrico propio es invariante por omisión; el bound y la lista inmutable de adentro dejan eso igual. El bound restringe qué argumentos de tipo acepta `Corral`; la varianza, que es otra propiedad, dice cómo se relacionan dos corrales con argumentos distintos. Para que `Corral[Vaca]` sea subtipo de `Corral[Animal]` hay que declarar el parámetro covariante, `Corral[+T <: Animal]`, y eso impone condiciones sobre cómo se usa `T` adentro.

## 6. 🟡 El `Set` inmutable también es invariante, por otra razón

> El `Set` que usa el código de referencia (el inmutable, sin `import`) **también** rechaza `Set[Animal] = Set[Vaca]`, y ahí la causa es otra: un `Set` **es también una función** `A => Boolean`.

```scala
  val vacas: Set[Vaca] = Set(new Vaca)              // el Set inmutable, sin import
  val animales: Set[Animal] = vacas
  // ❌ Found:    (vacas : Set[tadp.granja.Vaca])
  //    Required: Set[tadp.granja.Animal]
```

Sin `add`, el contraejemplo del caballo desaparece. Entonces, ¿por qué? Porque en Scala un conjunto se puede usar como función que responde "¿está este elemento?":

```scala
  val vacas: Set[Vaca] = Set(new Vaca)
  val pertenece: Vaca => Boolean = vacas            // ✅ un Set[Vaca] es una función de Vaca a Boolean
  println(pertenece(new Vaca))                      // Resultado: false   ← es otra vaca; la pertenencia compara objetos
```

Y una función que **recibe** `Vaca` tiene, respecto de ese parámetro, una varianza que todavía no viste. Es el tema del Módulo 6, y en el Módulo 7 vas a poder explicar esta invarianza con precisión. Por ahora, el dato: `List` y el `Set` inmutable son las dos inmutables, y solo `List` es covariante; la diferencia está en qué operaciones expone cada una.

El test 13 de `GranjaTest.scala` verifica, con `assertTypeError`, que `Set[Animal] = Set[Vaca](…)` **no compila** sobre el `Set` inmutable, y el test 14 que una `List[Vaca]` se usa como `List[Animal]` y que `:+` deja la original intacta.

## 7. 🟡 Lo que viene

> Hay una tercera forma de varianza, y para encontrarla hay que mirar **funciones**.

Hasta acá: invarianza (`Set`), covarianza (`List`), bivarianza (los lenguajes sin tipos). Una función `Vaca => Vaca` es un tipo paramétrico con **dos** parámetros, el del argumento y el del resultado, y el Módulo 6 pregunta, para cada uno, en qué dirección varía. Uno de los dos va **al revés**.

---

## Checkpoint (sin respuestas)

1. `val animales: Set[Animal] = vacas` con `vacas: Set[Vaca]` se rechaza. ¿Qué afirma el compilador sobre la relación entre los dos tipos? ¿Qué vale sobre la relación entre `Vaca` y `Animal`?
2. Construí el contraejemplo del caballo paso a paso: qué línea es válida para qué variable, y en qué línea explota. ¿Qué línea frena el compilador y por qué esa?
3. ¿Qué pasa si forzás la asignación con `asInstanceOf`? ¿Dónde y con qué excepción explota? ¿Qué tiene que ver con la promesa *sound* del Módulo 1?
4. Definí varianza. Escribí la notación formal de invarianza y leela en voz alta.
5. ¿Qué es bivarianza? ¿Qué lenguajes la tienen y cómo evitan los caballos en los conjuntos de vacas?
6. ¿Por qué `List` puede ser covariante y el `Set` mutable no? ¿Qué operación es la que decide?
7. ¿Qué devuelve `animales :+ new Caballo`? ¿Qué le pasa a `vacas` después de esa línea?
8. ¿Qué significa el `+` en `List[+A]`? ¿Es covariante la lista o el parámetro? ¿Por qué importa la diferencia?
9. ¿`List[Persona]` es subtipo de `List[Nombrable]`? Justificá con la varianza de `List`.
10. `Corral[T <: Animal]` con una `List[T]` adentro: ¿`Corral[Vaca]` es subtipo de `Corral[Animal]`? ¿Qué responde el bound y qué responde la varianza?
11. El `Set` inmutable rechaza `Set[Animal] = Set[Vaca]` sin tener `add`. ¿Qué otra cosa es un `Set` que explica eso? (Sin la respuesta completa todavía: ¿hacia qué módulo apunta?)

## Qué viene después

El Módulo 6 toma una variable `f: Vaca => Vaca` y cinco funciones candidatas a guardarse ahí. Tres entran y dos no, y las razones muestran que el tipo del resultado varía como `List`, y el tipo del parámetro varía **al revés**. Ese "al revés" se llama contravarianza y es la pieza que faltaba.

**FIN DEL MÓDULO 5**
