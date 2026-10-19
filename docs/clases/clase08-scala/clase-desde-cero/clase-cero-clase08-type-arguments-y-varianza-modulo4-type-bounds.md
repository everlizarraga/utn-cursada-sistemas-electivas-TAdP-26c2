# Clase desde cero — Type arguments y varianza en Scala — Módulo 4: Type bounds: lo que `T` tiene que ser como mínimo

**Unidad:** clase08 · **Lenguaje:** Scala 3.3.1 · **Densidad:** 🔴 pide una sesión con el código abierto

---

## Sobre este documento

**Qué cubre.** Cómo ponerle límites a un parámetro de tipo. Arranca con lo que `Corral[T]` dejó abierto (un corral de números compila, y un método `gordos` adentro del corral es imposible de escribir), prueba las salidas que funcionan y sirven poco (filtrar desde afuera, castear, un alias), y llega al **upper bound** `T <: Animal`: qué restringe, y sobre todo qué **gana** el corral con él. Después el **lower bound** `T >: VacaLoca`, con un experimento que muestra qué hace y qué deja igual, los dos límites juntos y su orden, la lectura gráfica sobre la jerarquía, y una sección corta sobre qué es `T` cuando el programa corre (nada: **erasure**).

**Qué no cubre.** Para qué sirve de verdad un lower bound (Módulos 7 y 8) y por qué el pastor sigue roto (Módulo 5).

## De dónde venís

Del Módulo 3: `Corral[T](val animales: Set[T])`, `T` es un nombre, la inferencia en cascada, el pastor roto. Del Módulo 2: el truco del `Int` para ver un tipo inferido, `_.estaGordo`. De la clase anterior: `asInstanceOf` apaga el chequeador en un punto y falla en ejecución si mentiste (M8); `type X = Y` define un alias (M5). Todo el código sigue con `import scala.collection.mutable.Set`.

---

## 1. 🔴 Lo que `Corral[T]` dejó abierto

> Con `T` libre, un corral acepta **cualquier** tipo, y adentro del corral el compilador conoce **cero** mensajes de `T`: podría ser `Int`.

Dos síntomas del mismo problema. El primero:

```scala
  val corralRaro = new Corral(Set(1, 2, 3))     // ✅ compila: Corral[Int]
  println(corralRaro.animales)                   // Resultado: HashSet(1, 2, 3)
```

Un corral de números. El dominio dice que un corral tiene animales; el tipo dice que tiene `T`, y `T` es lo que sea.

El segundo síntoma es el importante. Querés que el corral sepa cuáles de sus animales están gordos:

```scala
class Corral[T](val animales: Set[T]) {
  def gordos = animales.filter(_.estaGordo)
  //                            ^^^^^^^^^^^
  // ❌ value estaGordo is not a member of T
}
```

`animales` es `Set[T]`; lo que sale es `T`; y el compilador desconoce todo sobre `T`: podría ser `Int`. Entonces `estaGordo` es inalcanzable. El método tiene todo el sentido en el dominio, y es imposible de escribir, porque el tipo del corral quedó demasiado abierto.

## 2. 🟡 Tres salidas que funcionan, y por qué sirven poco

> Hay tres formas de esquivar el error. Dos compilan y la tercera ni compila. Ninguna resuelve el problema, que es **decirle al compilador qué es `T` como mínimo**.

**Filtrar desde afuera.** Donde el tipo ya es concreto, el filtro anda:

```scala
  val corralito = new Corral(Set(new Vaca, new Vaca))      // Corral[Vaca]
  corralito.animales.filter(_.estaGordo)                    // ✅: acá los elementos son Vaca
```

Funciona porque afuera del corral `T` ya es `Vaca`. Lo que perdés es el método: cada cliente del corral repite el filtro, y el corral, que es quien tiene los animales, se queda sin poder hablar de ellos.

**Castear.** La herramienta de la clase anterior:

```scala
class Corral[T](val animales: Set[T]) {
  def gordos = animales.filter(_.isInstanceOf[Animal]).filter(_.asInstanceOf[Animal].estaGordo)   // ✅ compila
}
```

`isInstanceOf[Animal]` pregunta en ejecución si el objeto es un animal; `asInstanceOf[Animal]` le dice al chequeador que lo trate como tal. Compila, y sobre un corral de vacas con una gorda devuelve 1. Sobre `new Corral(Set(1, 2, 3))` devuelve un conjunto vacío, sin explotar, porque el `isInstanceOf` descarta los números. Es lo que la clase anterior dijo del cast: funciona apagando el chequeador. El corral sigue aceptando números, y `gordos` sigue devolviendo `Set[T]`: sobre el corral de enteros, un `Set[Int]` vacío. El problema sigue ahí, tapado.

**Un alias.** La tentación de "ponerle de nombre `Animal`" ya mostró su trampa (Módulo 3); la versión educada es un alias:

```scala
type Cosos = Animal                               // un nombre alternativo para Animal

class Corral[Cosos](val animales: Set[Cosos]) {
  def gordos = animales.filter(_.estaGordo)
  // ❌ value estaGordo is not a member of Cosos
}
```

Adentro del corchete, `Cosos` es otra vez **un nombre de parámetro**, y tapa al alias igual que tapaba a la clase. Un parámetro de tipo es un nombre, y un nombre, por sí solo, promete cero. Lo que vos querés decir es otra cosa: "`T` tiene que ser, como mínimo, un animal". Eso es una **restricción**, y tiene su sintaxis.

| Escribís | Scala entiende | Sale |
|---|---|---|
| `corralito.animales.filter(_.estaGordo)` desde afuera, con `corralito: Corral[Vaca]` | filtrar vacas | ✅; el corral sigue sin poder hacerlo por sí mismo |
| `def gordos = animales.filter(_.isInstanceOf[Animal]).filter(_.asInstanceOf[Animal].estaGordo)` | castear cada elemento | ✅ compila; el corral de números sigue existiendo y el chequeador quedó apagado ahí |
| `type Cosos = Animal` + `class Corral[Cosos]` | un parámetro llamado como el alias | ❌ `value estaGordo is not a member of Cosos` |

## 3. 🔴 Upper bound: `T <: Animal`

> `class Corral[T <: Animal]` restringe `T` a **`Animal` o cualquiera de sus subtipos**. Es un techo: `T` puede ser cualquiera de las cuatro clases de la granja, y ningún tipo de afuera de esa jerarquía. Con eso, adentro del corral **todo lo de `Animal` está disponible sobre `T`**.

```scala
import scala.collection.mutable.Set

class Corral[T <: Animal](val animales: Set[T]) {
  def gordos: Set[T] = animales.filter(_.estaGordo)     // ✅
}

class Pastor {
  def pastorear(animales: Set[Animal]): Unit = animales.foreach(_.come)
}

class Lechero {
  def ordeñar(corral: Corral[Vaca]): Unit = corral.animales.foreach(_.ordeñate)
}
```

`<:` se lee "es subtipo de": `T <: Animal` es "`T` subtipo de `Animal`" (`Animal` incluido). Un **type bound** (límite de tipo) es exactamente eso: una condición sobre qué tipos puede tomar un parámetro.

Techo en la jerarquía y mínimo de interfaz son la misma cosa vista de dos lados: cuanto más arriba está un tipo, menos mensajes garantiza. `T <: Animal` fija el tipo más alto que `T` puede ser y, con eso, la interfaz mínima que todo `T` tiene: la de `Animal`. Por eso el título de este módulo habla de "mínimo" y esta sección de "techo".

Los dos síntomas, resueltos:

```scala
  val corralRaro = new Corral(Set(1, 2, 3))
  // ❌ Found:    (1 : Int)
  //    Required: tadp.granja.Animal           (y lo mismo para el 2 y el 3)

  val corralRaro: Corral[Int] = new Corral[Int](Set(1, 2, 3))
  // ❌ Type argument Int does not conform to upper bound tadp.granja.Animal
```

| Escribís | Scala entiende | Sale |
|---|---|---|
| `new Corral(Set(1, 2, 3))` | inferí `T`, con `T <: Animal` | ❌ `Found: (1 : Int) / Required: Animal` (el compilador ya sabe que cada elemento tiene que ser `Animal`) |
| `new Corral[Int](Set(1, 2, 3))` | `T = Int` a mano | ❌ `Type argument Int does not conform to upper bound Animal` |
| `new Corral[String](Set("asd"))` | `T = String` | ❌ `Type argument String does not conform to upper bound Animal` |
| `new Corral(Set(new Vaca, new Vaca))` | inferí | ✅ `Corral[Vaca]` |
| `new Corral(Set(new Vaca, new Caballo))` | inferí | ✅ `Corral[Animal]` |
| `new Corral[Animal](Set(new Caballo, new Caballo))` | `T = Animal`, con caballos adentro | ✅ los caballos son animales |

Dos mensajes distintos para el mismo rechazo, según quién eligió `T`: si lo infiere, el compilador ya sabe que `T` tiene techo `Animal` y rechaza cada elemento que no lo es; si lo escribís vos, rechaza el argumento de tipo. En los dos casos la frase que vale es la segunda: el argumento **no respeta el límite**.

### 3.1 Qué gana el corral: puede hablar en términos de `T`

Esta es la parte que importa, más que el rechazo de los números. Compará:

| | `Corral(val animales: Set[Animal])` (Módulo 3, sección 1) | `Corral[T <: Animal](val animales: Set[T])` |
|---|---|---|
| ¿Acepta un corral de números? | No | No |
| ¿`gordos` se puede escribir? | Sí (`Set[Animal]`) | Sí |
| ¿Qué devuelve `gordos` de un corral de vacas? | `Set[Animal]` | **`Set[Vaca]`** |
| ¿El lechero puede ordeñar? | No | Sí |

Las dos versiones restringen igual. La diferencia es que la segunda **tiene disponible la variable `T`**: el corral puede referirse al tipo que le van a pasar, sin saber cuál es, y definir su interfaz en función de él. `gordos: Set[T]` devuelve "animales gordos **del tipo de este corral**". Sobre un `Corral[Vaca]`, eso es un `Set[Vaca]`, y lo que sale se puede ordeñar:

```scala
  val gordita: Vaca = new Vaca
  gordita.peso = 150
  val corralConGordita = new Corral(Set(new Vaca, gordita))   // Corral[Vaca]

  val gordas: Set[Vaca] = corralConGordita.gordos              // ✅ gordos devuelve Set[T], y T es Vaca
  println(gordas.size)                                     // Resultado: 1
  gordas.foreach(_.ordeñate)                               // ✅ son vacas
  println(gordita.peso)                                    // Resultado: 140
```

Con `Set[Animal]` fijo, `gordos` devolvería `Set[Animal]` y las gordas, aunque fueran vacas, serían inordeñables. El `T` es la diferencia entre "un conjunto de animales" y "un conjunto de lo que sea que este corral tenga". Es la misma razón por la que una función tiene parámetros en vez de variables globales: para poder hablar de un valor que todavía nadie fijó.

¿De qué tipo concreto es lo que devuelve `gordos`? Del tipo que le pasen al construir el corral. Esa separación entre **la información que tenés al definir** (`T`, con su techo) y **la información que tenés al usar** (`Vaca`) es lo que habilita la variable. Vos definís en función de `T`; quien construye el corral completa.

El bound suma lo segundo: el corral sabe que, sea cual sea `T`, **como mínimo es `Animal`**. Por eso `estaGordo` compila adentro.

Hasta acá `T` aparece en dos lugares: el parámetro del constructor y el retorno de `gordos`. Si puede aparecer en **cualquier** lugar de la clase es una pregunta que queda abierta; el Módulo 7 la responde, y la respuesta tiene sorpresa.

> **Para el parcial, si te preguntan**
> *Aparece `def gordos` en `class Corral[T](val animales: Set[T])` y no compila. ¿Qué le ponés y por qué?* — Un upper bound: `class Corral[T <: Animal]`. El error es que `T` puede ser cualquier tipo y `estaGordo` es de `Animal`; con el límite, el compilador sabe que `T` es `Animal` o un subtipo, y `estaGordo` está disponible sobre `T`. Además, `gordos: Set[T]` devuelve el tipo del corral (un `Set[Vaca]` para un `Corral[Vaca]`), que es mejor que fijar `Set[Animal]` y perder esa información.

## 4. 🔴 Lower bound: `T >: VacaLoca`

> `class Corral[T >: VacaLoca]` restringe `T` a **`VacaLoca` o cualquiera de sus supertipos**. Es un piso. Combinado con un techo, `[T >: VacaLoca <: Animal]` deja a `T` **en un tramo de la jerarquía**: `VacaLoca`, `Vaca` o `Animal`.

```scala
class Corral[T >: VacaLoca <: Animal](val animales: Set[T]) {
  def gordos: Set[T] = animales.filter(_.estaGordo)
}
```

`>:` se lee "es supertipo de": `T >: VacaLoca` es "`T` supertipo de `VacaLoca`" (`VacaLoca` incluida). Los dos límites van en ese orden: **primero el piso, después el techo**. Es una regla de la gramática del lenguaje, sin más razón que esa. Al revés es un error de sintaxis:

```scala
class Corral[T <: Animal >: VacaLoca](val animales: Set[T])
//                       ^^
// ❌ ']' expected, but '>:' found
```

Para acordarte de cuál es cuál: los dos puntos van siempre del lado del tipo concreto (`T <: Animal`, `T >: VacaLoca`), y la punta abierta del `<` o `>` apunta al tipo más grande, como en una desigualdad: `T <: Animal` es "`T` menor o igual que `Animal`", `T >: VacaLoca` es "`T` mayor o igual que `VacaLoca`". Es el signo de una desigualdad; la flecha de herencia de los diagramas es otra cosa. Pajarito contento `<:` para el techo, pescadito triste `>:` para el piso.

**El experimento.** Con `[T >: VacaLoca <: Animal]`, `T` puede ser `VacaLoca`, `Vaca` o `Animal`. `Caballo` es subtipo de `Animal` y **no** es supertipo de `VacaLoca`: está en otra rama.

| Escribís | Scala entiende | Sale |
|---|---|---|
| `new Corral[Caballo](Set(new Caballo))` | `T = Caballo` | ❌ `Type argument Caballo does not conform to lower bound VacaLoca` |
| `new Corral[Animal](Set(new Caballo, new Caballo))` | `T = Animal`, con caballos adentro | ✅: `Animal` está en el tramo, y los caballos son animales |
| `new Corral(Set(new Caballo))` | inferí | ✅ `Corral[Animal]`: el compilador sube `T` hasta el primer tipo que cumple el piso |
| `new Corral(Set(new VacaLoca))` con `[T >: Vaca <: Animal]` | inferí | ✅ `Corral[Vaca]`: sube de `VacaLoca` a `Vaca` por el piso |
| `c.animales.foreach(_.relincha)` sobre el `Corral[Animal]` inferido con caballos | relinchar lo que sale | ❌ `value relincha is not a member of Animal` |
| `new Corral(Set(1, 2, 3))` con solo el piso, `class Corral[T >: VacaLoca]` | inferí, sin techo | ✅ `Corral[VacaLoca \| Int]`: el piso solo acota tipos; los valores entran igual |

Mirá las dos filas de inferencia: el piso **empuja la inferencia hacia arriba**. Con un conjunto de caballos, `T = Caballo` violaría el piso, así que el compilador elige el primer `T` que cumple las dos condiciones: `Animal`. El corral se construye; lo que cambió es su tipo.

**Qué hace y qué deja igual.** El lower bound restringe **qué tipos puede tomar `T`**, y deja igual **qué valores entran**: un corral con caballos adentro existe igual, como `Corral[Animal]`. Lo que ya se puede hacer con un `Corral[Caballo]` queda fuera (relinchar lo que sale); lo que se puede hacer con un `Corral[Animal]`, sigue. El piso elige **una rama** de la jerarquía y obliga a tipar el corral dentro de ella.

**La lectura gráfica.** Los dos límites dibujan un tramo:

```
                   ┌──────────┐  ◄── techo: T <: Animal
                   │  Animal  │
                   └────┬─────┘
          ┌─────────────┼─────────────┐
    ┌─────┴─────┐  ┌────┴────┐   ┌────┴────┐
    │ (otras    │  │  Vaca   │   │ Caballo │   ◄── fuera del tramo
    │  especies)│  └────┬────┘   └─────────┘
    └───────────┘       │
                  ┌─────┴─────┐
                  │ VacaLoca  │
                  └───────────┘  ◄── piso: T >: VacaLoca

    T ∈ { Animal, Vaca, VacaLoca }
```

Fijate en una asimetría: hay **un solo techo** posible para todos (arriba la jerarquía converge), pero **muchos pisos** posibles (abajo se abre en ramas: vacas, caballos, otras especies). Poner un techo es natural: "como mínimo, un animal". Poner un piso es raro: elegir una rama y quedarse ahí. Por eso el upper bound aparece en casi todos los lenguajes con tipos paramétricos y el lower bound en pocos.

**¿Y para qué sirve?** Hasta acá, para restringir el tipo del corral a una rama, que es algo que rara vez querés. Parece una herramienta sin uso. Queda abierto: en los Módulos 7 y 8 aparece el caso donde un lower bound es exactamente lo que hace falta, y ahí se entiende por qué existe.

> **Para el parcial, si te preguntan**
> *¿Qué restringe `T <: Animal` y qué restringe `T >: VacaLoca`? ¿Se pueden combinar?* — El upper bound `T <: Animal` restringe `T` a `Animal` y sus subtipos (un techo); el lower bound `T >: VacaLoca` lo restringe a `VacaLoca` y sus supertipos (un piso). Se combinan en ese orden, `[T >: VacaLoca <: Animal]`, y dejan a `T` en el tramo `VacaLoca`–`Vaca`–`Animal`. El lower bound cambia solo qué argumentos de tipo acepta el corral y deja entrar los mismos valores (un corral con caballos existe, como `Corral[Animal]`). El upper bound, además de acotar `T`, excluye valores: con `T <: Animal`, ningún número entra.

## 5. 🟢 Qué es `T` cuando el programa corre: erasure

> Los parámetros de tipo existen **solo al compilar**. Al ejecutar, `T` **ya se borró**: un `Corral[Vaca]` y un `Corral[Animal]` son, en ejecución, la misma clase `Corral`.

Los bloques de esta sección y de la siguiente corren igual con cualquiera de las dos definiciones del corral, la de la sección 3 o la de la sección 4.

```scala
  val vacas: Corral[Vaca] = new Corral(Set(new Vaca))
  val animales: Corral[Animal] = new Corral(Set(new Caballo))

  println(vacas.getClass)                          // Resultado: class tadp.granja.Corral
  println(vacas.getClass == animales.getClass)     // Resultado: true
```

`getClass` devuelve la clase del objeto en ejecución. Las dos son `Corral` a secas: el `[Vaca]` y el `[Animal]` se fueron. A esto se lo llama **erasure** (borrado): todo lo que el compilador chequeó sobre `T` se verifica estáticamente y después desaparece del código que corre. Es parecido a los traits de la clase anterior: al ejecutar, ya fueron aplanados.

Dos consecuencias que vas a ver:

- **Preguntar por `T` en ejecución es imposible.** `vacas.isInstanceOf[Corral[Caballo]]` compila con una advertencia (`the type test for tadp.granja.Corral[tadp.granja.Caballo] cannot be checked at runtime because its type arguments can't be determined from tadp.granja.Corral[tadp.granja.Vaca]`) y devuelve `true`: en ejecución, es un `Corral`, y nada más.
- **Dos métodos que solo difieren en el argumento de tipo son el mismo método.** Es el segundo choque del Módulo 3: `build(vacas: Set[Vaca])` y `build(caballos: Set[Caballo])` con el mismo tipo de retorno dan `Double definition … have the same type after erasure`. Después del borrado, los dos son `build(Set)`.

Lo notable es que, aun así, al definir el corral vos **hablás de `T`** como si existiera: `gordos: Set[T]`. Existe, en el único momento en que importa para el chequeo: al compilar. Es información sobre el tipo que va a usar el corral, para el que está programando el corral.

🕳️ **Madriguera — por qué se borra.** La máquina que ejecuta Scala no guardaba parámetros de tipo cuando se diseñó; agregarlos después hubiera cambiado demasiado, y se eligió perderlos. Hay herramientas para hacerlos sobrevivir en ejecución cuando hace falta. *Volvé al camino — esto se profundiza aparte, otro día.*

## 6. 🟡 Lo que viene

> El corral ya tiene techo, y el pastor **sigue sin compilar**.

```scala
  val corralito: Corral[Vaca] = new Corral(Set(new Vaca))
  new Pastor().pastorear(corralito.animales)
  // ❌ Found:    (corralito.animales : collection.mutable.Set[tadp.granja.Vaca])
  //    Required: collection.mutable.Set[tadp.granja.Animal]
```

El bound restringe qué `T` puede tomar el corral, y el pastor sigue diciendo que un `Set[Vaca]` no es un `Set[Animal]`. Esto ya es evidencia de que el problema está en otro lado: en el `Set`, y en cómo se relacionan dos conjuntos cuando sus elementos se relacionan. El Módulo 5 va a eso.

Los tests 8 y 10 de `GranjaTest.scala` verifican, sobre la versión final del corral, que `new Corral(List(1, 2, 3))` **no compila** y que `gordos` devuelve solo los gordos.

---

## Checkpoint (sin respuestas)

1. ¿Por qué `def gordos = animales.filter(_.estaGordo)` es imposible de escribir en `Corral[T]`? ¿Qué sabe el compilador de `T`?
2. Tres salidas: filtrar desde afuera, castear, un alias. ¿Qué logra y qué pierde cada una?
3. ¿Qué restringe `T <: Animal`? Da los dos mensajes de error distintos para un corral de enteros y explicá por qué son distintos.
4. `Corral(val animales: Set[Animal])` y `Corral[T <: Animal](val animales: Set[T])` restringen igual. ¿Qué gana la segunda? Mostralo con `gordos`.
5. ¿Qué restringe `T >: VacaLoca`? ¿En qué orden se escriben los dos límites?
6. Con `[T >: VacaLoca <: Animal]`, ¿qué tipo infiere `new Corral(Set(new Caballo))`? ¿Por qué? ¿Se puede relinchar lo que sale?
7. "El lower bound restringe qué tipos puede tomar `T` y deja igual qué valores entran." Explicá la frase con un ejemplo.
8. ¿Por qué hay un solo techo posible y muchos pisos? ¿Qué tiene que ver con que el lower bound sea raro?
9. ¿Qué es erasure? ¿Qué devuelve `vacas.getClass == animales.getClass` y por qué? ¿Qué error del Módulo 3 explica?

## Qué viene después

El Módulo 5 toma el error del pastor en serio: un `Set[Vaca]` no es un `Set[Animal]`. Primero decide quién se equivoca, si el compilador o vos, con un contraejemplo concreto. Después le pone nombre a lo que pasa (**varianza**) y encuentra una colección donde la respuesta cambia.

**FIN DEL MÓDULO 4**
