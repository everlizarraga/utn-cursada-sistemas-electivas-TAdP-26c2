# Clase desde cero — Tipado estático en Scala — Módulo 2: El mismo programa en Scala — chequeo estático

**Unidad:** clase07 · **Lenguaje:** Scala 3.3.1 · **Densidad:** 🔴 una sesión con el proyecto abierto

---

## Sobre este documento

**Qué cubre.** El `Saludador` del Módulo 1 traducido a Scala, línea por línea; es tu primer contacto con la sintaxis. El mismo error de `nombre`, que ahora **impide compilar**. Qué es el **chequeo estático**: qué revisa, cuándo y con qué información, y en qué se diferencia del de Ruby. Por qué el compilador marca lo que marca (**el rojo es el síntoma, no el problema**). Tipado **explícito** e **implícito**, y qué es la **inferencia**. Las ventajas y las desventajas de chequear antes de correr.

**Qué no cubre.** Qué pasa cuando el compilador rechaza un programa que funcionaría (Módulo 3) y cómo se recupera el polimorfismo (Módulo 4).

## De dónde venís

Del Módulo 0 (el proyecto, `object … extends App`, `println`) y del Módulo 1 (el `Saludador` en Ruby, las tres definiciones). De clase01 a clase04, Ruby. De TypeScript o Haskell, si los viste, te va a sonar la anotación `: Tipo`; acá se explica igual.

---

## 1. 🔴 El `Saludador`, ahora en Scala

> En Scala **cada parámetro lleva su tipo**, escrito después del nombre con dos puntos. Es la única diferencia de fondo con la versión Ruby; el resto es sintaxis.

```scala
// src/main/scala/tadp/nadaquever/Saludador.scala
package tadp.nadaquever

object Saludador extends App {

  // Una clase con un parámetro. Los parámetros de la clase son su constructor:
  // new Persona("Ernesto") crea una Persona con name = "Ernesto".
  // El `val` adelante hace que `name` quede visible desde afuera: p.name.
  class Persona(val name: String)

  // Sin `val`, el parámetro solo se ve adentro de la clase. `= false` es el valor por defecto.
  class Saludador(cordial: Boolean = false) {

    // def nombreDelMetodo(parámetro: Tipo): TipoDeRetorno = { cuerpo }
    // El if/else es una expresión: produce un valor, y ese valor es lo que el método devuelve.
    def saludar(a: Persona): String = {
      if (cordial) {
        "Buen día estimado/a " + a.nombre      // ← el mismo error del Módulo 1
      } else {
        "Hola"
      }
    }
  }

  println(new Saludador().saludar(new Persona("Ernesto")))
  println(new Saludador(true).saludar(new Persona("Ernesto")))
}
```

Qué es cada cosa nueva:

| Escribís | Se lee | En Ruby era |
|---|---|---|
| `class Persona(val name: String)` | Una clase cuyo constructor recibe `name`, de tipo `String`, y lo expone como getter (un método que devuelve el valor) | `attr_accessor :name` + `initialize(name)` |
| `class Saludador(cordial: Boolean = false)` | Constructor con un parámetro `Boolean` que por defecto vale `false`; sin `val`, es privado | `initialize(cordial = false)` |
| `def saludar(a: Persona): String = { … }` | Un método que recibe `a`, de tipo `Persona`, y devuelve un `String` | `def saludar(a)` |
| `if (cordial) { … } else { … }` | Una expresión que vale una rama o la otra; el método devuelve ese valor | igual, sin paréntesis |
| `new Persona("Ernesto")` | Crear una instancia | `Persona.new("Ernesto")` |
| `: String`, `: Boolean`, `: Persona` | **Anotación de tipo**: declara de qué tipo es lo que está a la izquierda | no existía |

**Formas más cortas que vas a ver.** Las dos se usan en el código de la materia; son equivalentes a la forma completa de arriba.

| Escribís | Scala entiende | Equivale a |
|---|---|---|
| `def saludar(a: Persona) = { … }` | El tipo de retorno lo deduce del cuerpo (sección 5) | `def saludar(a: Persona): String = { … }` |
| `def saludar(a: Persona) = if (cordial) "…" else "Hola"` | Sin llaves: el cuerpo es una sola expresión | la forma completa, en una línea |

## 2. 🔴 El error, antes de correr

> El programa de arriba **no compila**. El error que en Ruby apareció al ejecutar la rama cordial, en Scala aparece **al compilar**, sin ejecutar nada.

Al compilar (o al apretar el ▷ del `object`, que compila primero):

```
-- [E008] Not Found Error: src/main/scala/tadp/nadaquever/Saludador.scala:18:34
18 |        "Buen día estimado/a " + a.nombre
   |                                 ^^^^^^^^
   |                                 value nombre is not a member of tadp.nadaquever.Saludador.Persona
```

Y el **IDE** (el editor, IntelliJ) lo marca en rojo mientras escribís, antes de que compiles: el IDE corre el mismo chequeador por detrás.

Comparalo con el Módulo 1: allá hacía falta ejecutar *justo esa rama* para enterarte. Acá el programa no existe hasta que lo arreglás. El error es el mismo; **cambió el momento** en que te enterás.

| Escribís | Sale | Cuándo |
|---|---|---|
| `a.nombre` con `class Persona(val name: String)` | `value nombre is not a member of …Persona` | Al compilar |
| `a.nombre` con `class Persona(val nombre: String)` | `Buen día estimado/a Ernesto` (cordial) | Al ejecutar |
| `a.name` con `class Persona(val name: String)` | `Buen día estimado/a Ernesto` (cordial) | Al ejecutar |

## 3. 🔴 Qué es el chequeo estático

> El **chequeo estático de tipos** es una validación del programa que se hace **analizando el código fuente**, antes de ejecutarlo: le asigna un tipo a cada elemento del lenguaje (parámetros, variables, retornos) y verifica que sean **consistentes** entre sí.

```
 ┌──────────┐      ┌─────────────────┐      ┌───────────┐
 │  Código  │ ───► │   Compilación   │ ───► │ Ejecución │
 │  fuente  │      │                 │      │           │
 └──────────┘      └────────┬────────┘      └───────────┘
                            │
                   ┌────────┴─────────┐
                   │ Chequeo estático │
                   │ Si hay un error  │
                   │ de tipos, se     │
                   │ detecta acá.     │
                   └──────────────────┘
```

En el ejemplo: el chequeador leyó `def saludar(a: Persona)` y anotó "`a` es una `Persona`". Leyó `class Persona(val name: String)` y anotó "una `Persona` entiende `name`". Leyó `a.nombre` y encontró la inconsistencia. **El chequeo ocurrió sobre las declaraciones**: todavía nada se había ejecutado, y ninguna `Persona` existía.

Esa es la diferencia completa con Ruby:

| | Chequeo dinámico (Ruby) | Chequeo estático (Scala) |
|---|---|---|
| **Cuándo** | Al ejecutar, cuando se manda el mensaje | Antes de ejecutar, al compilar |
| **Con qué información** | El objeto concreto que recibe el mensaje | Las declaraciones del código: qué tipo tiene cada cosa |

Los dos lenguajes chequean tipos. Lo que cambia es **el momento y la información**.

Un detalle de vocabulario: "estático" y "dinámico" son nombres heredados; hay lenguajes interpretados que chequean antes de ejecutar y la distinción sigue valiendo. Lo que importa es si tenés un veredicto sobre tu código **antes** de correrlo.

> **Para el parcial, si te preguntan**
> *¿Qué es el chequeo estático de tipos?* — Una validación del programa hecha sobre el código fuente, antes de ejecutar, que asigna tipos a los elementos del lenguaje y verifica que sean consistentes. Se diferencia del chequeo en ejecución por el momento (antes vs durante) y por la información que usa (las declaraciones vs el objeto concreto).

## 4. 🔴 El rojo es el síntoma, no el problema

> El compilador marca **`nombre`**, y no el tipo del parámetro, porque **apuesta a que lo que declaraste explícitamente es correcto**. Dijiste `a: Persona`; las personas tienen `name`; entonces lo que sobra es `nombre`. Eso es un dato, no un diagnóstico.

Acordate de los dos arreglos del Módulo 1. Los dos siguen siendo válidos:

| Arreglo | Qué dice | Compila |
|---|---|---|
| `class Persona(val nombre: String)` | "Me equivoqué al escribir `Persona`" | ✅ |
| `"…" + a.name` | "Me equivoqué al mandar el mensaje" | ✅ |

Y hay un tercero, fuera del alcance del compilador: "quería recibir *algo que entienda `nombre`*, y hay otra clase que lo entiende, así que `Persona` era un tipo demasiado chico". Ese arreglo pide cambiar el tipo del parámetro, y es exactamente lo que el compilador dio por correcto. Qué tipo ponerle a un parámetro es una pregunta con regla propia: Módulo 5.

El chequeador **no puede saber qué quisiste hacer**. Solo tiene la información que le diste, y quien se la dio es la misma persona a la que está controlando. Por eso un sistema de tipos tiene que ser **predecible**: ante una inconsistencia, elige una regla fija (creerle a lo declarado) y te muestra el pedacito de dato que puede mostrar. "Acá se reciben `Persona`, y `Persona` no tiene `nombre`." Punto. Vos leés "me equivoqué de mensaje", pero el compilador dijo otra cosa.

**Consecuencia práctica, la más importante de la unidad:** cuando algo se pone en rojo, **entendé el problema antes de arreglarlo**. Si arreglás siguiendo el rojo, podés estar tapando el síntoma: cambiar `nombre` por `name` compila, y si el problema real era que `saludar` tenía que aceptar también a otra clase, acabás de enterrarlo. En el Módulo 4 vas a ver un arreglo que apaga el rojo de un lado y lo prende del otro.

> **Para el parcial, si te preguntan**
> *El compilador marca `a.nombre` como error. ¿Qué arreglás?* — Primero decido qué quería el programa: si `saludar` debe recibir solo personas, corrijo el mensaje o el nombre del atributo; si debe recibir cualquier cosa con nombre, el que está mal es el tipo del parámetro, y el compilador nunca me lo va a marcar porque lo declaré yo. El error señala dónde hay una inconsistencia, no cuál de las dos partes está equivocada.

Con el primer arreglo, el programa compila y corre:

```scala
  class Persona(val nombre: String)
  // …
  println(new Saludador().saludar(new Persona("Ernesto")))       // Resultado: Hola
  println(new Saludador(true).saludar(new Persona("Ernesto")))   // Resultado: Buen día estimado/a Ernesto
```

## 5. 🟡 Explícito, implícito, inferido

> Un tipado es **explícito** cuando el lenguaje te da una forma de **escribir** el tipo de una referencia (`a: Persona`). Es **implícito** cuando no hay forma de escribirlo: la referencia es solo un nombre. La **inferencia** es que el compilador deduzca el tipo por el uso, para que puedas omitir la anotación.

Ruby es implícito: `def saludar(a)` es todo lo que podés escribir; el tipo de `a` existe (es el conjunto de mensajes que `saludar` le manda adentro), pero el lenguaje no te da dónde anotarlo. Por eso en los TPs de Ruby se suelen agregar símbolos o convenciones a los parámetros: es la anotación que falta, inventada a mano.

Scala es explícito: toda referencia tiene un tipo y hay una anotación para escribirlo. Pero Scala también **infiere**: casi siempre podés omitir la anotación y el compilador la deduce.

Antes del ejemplo, una palabra nueva: **`val nombre = expresión`** declara un nombre para un valor, como una variable que después queda fija (de la variable que sí cambia, `var`, se habla en el Módulo 6).

```scala
  val saludo = new Saludador(true).saludar(new Persona("Ernesto"))
  // Sin anotación. El compilador sabe que saludar devuelve String, así que saludo: String.

  val saludo2: String = new Saludador(true).saludar(new Persona("Ernesto"))
  // Con anotación. Mismo tipo; acá lo escribiste vos.

  def saludar(a: Persona) = { if (cordial) "…" + a.nombre else "Hola" }
  // Tipo de retorno inferido: las dos ramas son String, el método devuelve String.
```

**Lo que Scala nunca infiere, y por eso siempre se anota:**

| Qué | Por qué hace falta escribirlo |
|---|---|
| **El tipo de los parámetros de un método** (`a: Persona`) | El compilador carece de información para adivinar qué querías recibir. Es el dato que vos le das; con él, el error de la sección 2 se detecta |
| **El tipo de retorno de un método recursivo** | Para deducirlo tendría que mirar las llamadas, y las llamadas son al mismo método |

Esto pasa en todas las tecnologías con chequeo estático, con más o menos cosas que se infieren alrededor. Haskell, que ya conocés, es **explícito con inferencia**: podés escribir las firmas o no, y el compilador las deduce. Es una confusión común pensar que Haskell es implícito porque "no hace falta escribir tipos": sí hay anotación; es opcional.

> **Para el parcial, si te preguntan**
> *¿Haskell tiene tipado implícito?* — No. Tiene tipado explícito con inferencia: existe la anotación de tipo y podés omitirla porque el compilador la deduce. Implícito es cuando no existe forma de anotar, como en Ruby.

## 6. 🟡 Ventajas y desventajas de chequear antes

> Chequear antes de correr **ataja errores temprano** y hace que las herramientas te ayuden más, a cambio de **escribir más** y de que **ciertos programas no se puedan construir**.

**Ventajas**

- **Detección temprana.** El error de la sección 2 nunca llega a un entorno donde haya usuarios. Programar se vuelve más seguro.
- **El IDE sabe más.** La información de tipos es la que usa el editor para autocompletar, para mostrar el rojo mientras escribís, y para refactorizar con seguridad.
- **Expresar el dominio desde los tipos.** Podés escribir las **firmas** de un dominio (nombre, tipos de los parámetros y del retorno de cada método, sin el cuerpo) sin implementación, y el compilador te dice si son consistentes entre sí. Es otra forma de empezar a diseñar.

**Desventajas**

- **Hay construcciones muy difíciles de validar estáticamente.** Todo lo que cambia el programa mientras corre (self-modification: `define_method`, `instance_eval`, open classes) es difícil de tipar, porque el chequeador analizó un programa y vos lo cambiaste después. El caso extremo es `method_missing`: un objeto que responde a *cualquier* mensaje carece de un conjunto de mensajes declarable, y sin eso el chequeador queda sin nada que verificar. **Los programas de clase04 y del TP1, tal como están escritos, quedan afuera de Scala**: hay que resolver lo mismo con otra herramienta, o renunciar a esa forma de programa.
- **Hay que escribir más.** Toda la información de tipos va en el código. Scala infiere mucho y la diferencia con Ruby es chica (las anotaciones de los parámetros); otros lenguajes son bastante más verbosos.
- **Rechaza programas válidos.** El chequeador frena programas que, si los dejara correr, funcionarían. Esto es el Módulo 3 entero.

**Por qué objetos es más difícil de tipar que funcional.** En Haskell un valor es de un tipo y punto: un entero es un entero, una estructura es una estructura, y nunca cambia. En objetos un valor puede ser una `Persona` *y además* un `Alumno`, porque una clase hereda de otra; y una referencia puede contener hoy una cosa y mañana otra. Las dos cosas (subtipado y efecto) hacen el sistema de tipos más difícil de construir. Los módulos 4 y 5 son, en buena parte, cómo Scala lidia con la primera.

**Y sobre la queja "los tipos son incómodos".** Hay dos usuarios que la dicen: el que está tipando algo realmente complejo y el sistema no lo ayuda a expresarlo, y el que nunca se detuvo a pensar qué forma tiene lo que recibe cada método. El segundo caso es el más común. Tener que saber qué le vas a pasar a cada método es lo normal; el chequeador solo te pide que lo escribas.

🕳️ **Madriguera — `scala.Dynamic`.** Scala 3 trae un gancho tipado para objetos que aceptan miembros inexistentes (`selectDynamic`). Es una herramienta de borde, fuera de la materia; lo que se evalúa acá es la idea: un conjunto de mensajes abierto es lo que el chequeador no puede controlar. *Volvé al camino — esto se profundiza aparte, otro día.*

🕳️ **Madriguera — `if … then … else`.** Scala 3 acepta también `if cordial then "…" else "Hola"`, sin paréntesis. En esta cursada se usa la forma con paréntesis y llaves. *Volvé al camino — esto se profundiza aparte, otro día.*

---

## Checkpoint (sin respuestas)

1. ¿Qué cambió de fondo entre la versión Ruby y la versión Scala del `Saludador`, más allá de la sintaxis?
2. El error de `nombre` aparece en Scala y en Ruby. ¿Qué es lo que cambia entre los dos?
3. Definí chequeo estático en una oración. ¿Sobre qué trabaja: objetos o declaraciones?
4. ¿Por qué el compilador marcó `nombre` y no `a: Persona`? ¿Qué regla aplica ante una inconsistencia?
5. Nombrá los tres arreglos posibles del error. ¿Cuál no te va a sugerir nunca el compilador, y por qué?
6. ¿Qué diferencia hay entre tipado implícito y tipado explícito con inferencia? Ubicá a Ruby, Scala y Haskell.
7. ¿Qué dos cosas Scala no infiere nunca? ¿Por qué?
8. ¿Por qué `method_missing` no se puede tipar?
9. Da una ventaja y una desventaja del chequeo estático que no sean "detecta errores antes".

## Qué viene después

**Módulo 3:** la tercera desventaja, a fondo. Un programa que funcionaría, y el compilador lo rechaza igual. Ningún sistema de tipos es perfecto, y conviene saber exactamente en qué sentido.

**FIN DEL MÓDULO 2**
