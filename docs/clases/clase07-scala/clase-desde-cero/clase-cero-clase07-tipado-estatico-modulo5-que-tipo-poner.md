# Clase desde cero — Tipado estático en Scala — Módulo 5: Qué tipo poner — amplitud, unión y tipos estructurales

**Unidad:** clase07 · **Lenguaje:** Scala 3.3.1 · **Densidad:** 🔴 una sesión con el proyecto abierto; es el módulo más largo

---

## Sobre este documento

**Qué cubre.** Ya sabés nombrar lo común con un trait. Ahora, **qué tipo poner**: la regla para parámetros y retornos (**arriba** los que recibís, **abajo** lo que devolvés), y por qué el tipo se elige por lo que querés hacer y no por lo que el valor es. Después, las otras dos formas de nombrar lo común: la **unión de tipos** (`Persona | Asistente`) y el **tipo estructural** (`{ def nombre: String }`), con el **alias** `type` para darles nombre. La caracterización **nominal vs estructural**, y el ejercicio de caracterizar Ruby. Y lo que todo esto es en el fondo: una **decisión de diseño** sobre quién puede extender tu programa.

**Qué no cubre.** Los guerreros (Módulos 6 y 7) y el casteo (Módulo 8).

## De dónde venís

Del Módulo 4: subtipado, `trait Nombrable { def nombre: String }`, consentimiento, `Any` arriba de todo. Del Módulo 2: el tipo de retorno explícito `: String`. De TypeScript, si lo viste: unión `A | B` y tipos por forma te van a resultar familiares; acá se explican igual.

---

## 1. 🔴 Más arriba: más cosas, menos mensajes

> Cuanto **más arriba** en la jerarquía está un tipo, **más objetos** incluye y **menos mensajes** te deja mandar. Cuanto más abajo, al revés.

```
            ┌───────────┐
            │    Any    │   cualquier objeto · mensajes: ==, toString, …
            └─────▲─────┘
                  │
            ┌─────┴─────┐
            │ Nombrable │   lo que consintió · mensajes: nombre
            └─────▲─────┘
                  │
       ┌──────────┴──────────┐
  ┌────┴────┐           ┌────┴─────┐
  │ Persona │           │ Asistente│   mensajes: nombre, y los propios de cada una
  └─────────┘           └──────────┘
```

Subir por la flecha es ganar amplitud y perder herramientas: `Any` acepta todo y solo responde lo que todo objeto responde. Bajar es perder amplitud y ganar herramientas: una `Persona` responde `nombre` y todo lo suyo, pero solo las personas son personas.

## 2. 🔴 La regla de oro: parámetros arriba, retorno abajo

> A un **parámetro** le ponés el tipo **más arriba posible** que te deje resolver el problema: querés **aceptar** la mayor cantidad de cosas. A un **retorno** le ponés el tipo **más abajo posible**: el que te llama quiere **usar** lo que le devolvés.

**Parámetros.** `saludar` necesita mandar `nombre`. Lo más arriba que puede pedir y seguir funcionando es `Nombrable`. `Any` queda demasiado arriba (perdés `nombre`, Módulo 4); `Persona` queda demasiado abajo (rechazás al asistente). Si pudieras resolverlo con `Any`, pondrías `Any`: una función que trabaja con más cosas es mejor.

**Retornos.** `saludar` devuelve un texto. Hay dos anotaciones correctas:

```scala
    def saludar(a: Nombrable): String = { /* … */ }     // lo que devuelve, dicho con precisión
    def saludar(a: Nombrable): Any = { /* … */ }        // también es verdad: un String es un Any
```

Las dos compilan y las dos son ciertas. Pero mirá qué puede hacer el que llama:

| Escribís | Con `: String` | Con `: Any` |
|---|---|---|
| `val s = saludador.saludar(persona)` | `s: String` | `s: Any` |
| `s.split(" ")` | ✅ un arreglo (una secuencia de elementos; acá, los pedazos del texto) | `value split is not a member of Any` |
| `s.charAt(0)` | ✅ `'B'` | `value charAt is not a member of Any` |
| `println(s)` | ✅ | ✅ (todo objeto se imprime) |

**El valor es el mismo**: en los dos casos `saludar` devolvió el mismo `String`. Lo que cambia es **lo que el que lo recibe puede hacer con él**. Declarar `Any` le esconde al que te llama las herramientas de `String`. Declarar `String` le da todos los métodos de `Any` más los de `String`: cuanto más abajo le das algo, más herramientas tiene.

> **Para el parcial, si te preguntan**
> *Un método devuelve siempre un `String`. ¿Lo anotás como `String` o como `Any`?* — `String`. El tipo de retorno se elige lo más abajo posible porque quien llama quiere usar el resultado, y con `Any` solo podría mandarle los mensajes que todo objeto entiende. Al revés que los parámetros, que van lo más arriba posible para aceptar más cosas.

## 3. 🔴 Lo que importa es lo de afuera

> Desde el punto de vista del tipado, **no importa qué objeto hay guardado en una referencia**: importa **el tipo de la referencia**, porque siempre te comunicás con los objetos a través de ella. El mismo objeto, visto por dos referencias de tipos distintos, sirve para cosas distintas.

```scala
  val p: Persona   = new Persona("Ernesto")
  val n: Nombrable = p          // el mismo objeto, visto como Nombrable
  val a: Any       = p          // el mismo objeto, visto como Any

  p.nombre        // ✅ "Ernesto"
  n.nombre        // ✅ "Ernesto": Nombrable promete nombre
  a.nombre        // ❌ value nombre is not a member of Any
```

Las tres referencias apuntan **al mismo objeto**. El objeto tiene todos sus métodos adentro. Pero a través de `a` solo le podés mandar lo de `Any`: lo conocés a través de un lente que dice `Any`, y ese lente no deja ver `nombre`.

Por eso, cuando tipás, **elegís el tipo en función de lo que querés hacer con la cosa, no en función de lo que la cosa es**. `saludar` quiere mandar `nombre`: pide `Nombrable`. Quien llama quiere partir el texto: devuelve `String`. Lo que el valor es por adentro no entra en la decisión.

## 4. 🔴 Unión de tipos: `Persona | Asistente`

> `A | B` es **un tipo**: "o un A o un B". Su interfaz es **lo que A y B tienen en común**: como no sabés cuál de los dos tenés, solo podés mandarle los mensajes que los dos entienden.

```scala
  class Persona(val nombre: String)
  class Asistente(val nombre: String)

  class Saludador(cordial: Boolean = false) {
    def saludar(a: Persona | Asistente): String = {     // ← o una Persona o un Asistente
      if (cordial) {
        "Buen día estimado/a " + a.nombre               // nombre está en los dos: se puede
      } else {
        "Hola"
      }
    }
  }

  println(new Saludador(true).saludar(new Persona("Ernesto")))   // Resultado: Buen día estimado/a Ernesto
  println(new Saludador(true).saludar(new Asistente("Siri")))    // Resultado: Buen día estimado/a Siri
```

Funciona **sin trait y sin consentimiento**: `Persona` y `Asistente` siguen siendo clases sueltas. Lo que hiciste fue nombrar la lista de tipos aceptados en la firma.

Dos propiedades para tener claras:

- **La interfaz de `A | B` es la intersección de las interfaces.** Si `Persona` entiende `nombre` y `dni`, y `Asistente` entiende `nombre` y `version`, sobre un `Persona | Asistente` solo podés mandar `nombre`. (Existe la operación opuesta, `A & B`, "es un A y además un B", cuya interfaz es la unión de ambas; no la vas a usar en esta materia.)
- **No es un punto de extensión.** Aparece `AI`, también con nombre:

```scala
  class AI(val nombre: String)
  println(new Saludador(true).saludar(new AI("HAL")))
  // Found:    tadp.nadaquever.Saludador.AI
  // Required: tadp.nadaquever.Saludador.Persona | tadp.nadaquever.Saludador.Asistente
```

Hay que **tocar la firma** de `saludar`. Con el trait, `AI` se sumaba sola (`extends Nombrable`). La unión es una **lista cerrada**: sirve exactamente para esos dos.

¿Para qué sirve, entonces? Te ahorra inventar un nombre para "lo común entre personas y asistentes" cuando ese nombre no existe en el dominio o ensucia el vocabulario (`Nombrable` hoy; mañana tienen algo más en común y pasa a ser `NombrableYEdadiable`…). Y sirve cuando las clases son ajenas y el consentimiento queda fuera de tu alcance. Es una herramienta más bien estructural: lenguajes puramente nominales como Java carecen de ella, porque de todos modos te obligan a nombrar. (A veces la vas a escuchar llamada "conjunción de tipos"; en Scala el nombre es **unión**, y el símbolo es `|`.)

## 5. 🟡 Alias: darle un nombre a un tipo

> **`type Nombre = Tipo`** crea un **alias**: otro nombre para el mismo tipo. No cambia qué tipo es; solo cómo lo escribís.

```scala
  type PersonaAsistente = Persona | Asistente       // un nombre para la unión

  def saludar(a: PersonaAsistente): String = { /* … */ }
  // Exactamente lo mismo que saludar(a: Persona | Asistente). El compilador reemplaza el alias.
```

Es la misma idea que el `type` de Haskell. Y vale para cualquier tipo: `type Saludable = Nombrable` sería un alias nominal. Lo que importa es la **definición** del tipo, no que tenga nombre: un alias de una unión sigue siendo una unión; un alias de un trait sigue siendo nominal. Esto vuelve en la sección siguiente, donde confunde.

## 6. 🔴 Tipado estructural: `{ def nombre: String }`

> Un **tipo estructural** describe un tipo **por su forma**: "cualquier cosa que tenga un método `nombre` que devuelva `String`". Lo cumple cualquier objeto con esa forma, **sin consentimiento y sin herencia**. Es lo más parecido a Ruby que tiene Scala.

```scala
package tadp.nadaquever

import scala.reflect.Selectable.reflectiveSelectable   // necesario para mandar mensajes a un tipo estructural

object Saludador extends App {

  class Persona(val nombre: String)
  class Asistente(val nombre: String)
  class AI(val nombre: String)
  class Pato(val nombre: String, cantidadPlumas: Int = 20)   // nadie le pidió permiso a nadie

  class Saludador(cordial: Boolean = false) {
    def saludar(a: { def nombre: String }): String = {   // ← la forma: tiene nombre, devuelve String
      if (cordial) {
        "Buen día estimado/a " + a.nombre
      } else {
        "Hola"
      }
    }
  }

  println(new Saludador(true).saludar(new Persona("Ernesto")))   // Resultado: Buen día estimado/a Ernesto
  println(new Saludador(true).saludar(new Asistente("Siri")))    // Resultado: Buen día estimado/a Siri
  println(new Saludador(true).saludar(new AI("HAL")))            // Resultado: Buen día estimado/a HAL
  println(new Saludador(true).saludar(new Pato("Donald")))       // Resultado: Buen día estimado/a Donald
}
```

| Escribís | Sale |
|---|---|
| `saludar(new Pato("Donald"))` | ✅ `Pato` tiene `nombre: String`; entra sin declarar nada |
| `saludar(42)` | ❌ `Found: (42 : Int) / Required: Object{def nombre: String}` — un `Int` carece de `nombre` |

Fijate que acá ya acepta **cualquier cosa** que tenga la forma: también una clase de otra librería que vos no podés tocar. Ninguna clase prestó consentimiento, nadie heredó de nadie, nadie hizo una lista. Es la definición de polimorfismo de Paradigmas, escrita en Scala.

**El `import`.** Para mandarle un mensaje a algo tipado por su forma, Scala en ejecución tiene que buscar el método por nombre (lo que Ruby hace siempre). Eso requiere activar la **conversión implícita** que lo permite, y por eso hace falta `import scala.reflect.Selectable.reflectiveSelectable` al principio del archivo. Sin él, `a.nombre` no compila. Puede aparecer además un aviso del compilador por el uso de la conversión; es un aviso, no un error.

**Con alias, sigue siendo estructural.** Escribir `{ def nombre: String }` cada vez es incómodo, y si el método recibiera dos cosas con nombre habría que repetirlo. El alias lo resuelve:

```scala
  type Saludable = { def nombre: String }          // un nombre para la forma

  def saludar(a: Saludable): String = { /* … */ }  // igual que antes: Pato sigue entrando
```

**Que tenga nombre no lo vuelve nominal.** `Saludable` es un alias de una forma; nadie declara `extends Saludable`, y un alias de forma carece de esa opción, porque solo clases y traits se extienden. Lo que hace nominal a `Nombrable` del Módulo 4 es que **su definición es un trait**, y las clases lo incorporan por nombre. Lo que hace estructural a `Saludable` es que **su definición es una forma**. El `type` es solo el cartel.

**El estado final del `Saludador`.** Juntando los Módulos 4 y 5, así queda el archivo de la unidad (es el mismo que está en el código final). Dos detalles antes de leerlo: `Persona` vuelve a la variante del Módulo 4 §5 (`name` adentro, `nombre` como contrato), para que se vea que el tipo estructural también la acepta: lo que importa es que responda `nombre`, no cómo lo guarda. Y `cordial = true` es un **argumento nombrado**: lo mismo que `true`, con el nombre del parámetro adelante para que se lea.

```scala
package tadp.nadaquever

import scala.reflect.Selectable.reflectiveSelectable

object Saludador extends App {

  trait Nombrable {
    def nombre: String
  }

  class Persona(val name: String) extends Nombrable {
    override val nombre: String = this.name
  }

  class Asistente(val nombre: String) extends Nombrable

  class AI(val nombre: String) extends Nombrable

  class Pato(val nombre: String, cantidadPlumas: Int = 20)

  type PersonaAsistente = Persona | Asistente // type alias (unión de tipos)
  type Saludable = { def nombre: String }     // type alias (tipo estructural)

  class Saludador(cordial: Boolean = false) {
    def saludar(a: Saludable): String = {
      if (cordial) {
        "Buen día estimado/a " + a.nombre
      } else {
        "Hola"
      }
    }
  }

  println(new Saludador().saludar(new Persona("Ernesto")))                 // Resultado: Hola
  println(new Saludador(cordial = true).saludar(new Persona("Ernesto")))   // Resultado: Buen día estimado/a Ernesto
  println(new Saludador(cordial = true).saludar(new Asistente("Siri")))    // Resultado: Buen día estimado/a Siri
  println(new Saludador(cordial = true).saludar(new AI("HAL")))            // Resultado: Buen día estimado/a HAL
  println(new Saludador(cordial = true).saludar(new Pato("Donald")))       // Resultado: Buen día estimado/a Donald
}
```

Dos cosas quedan **definidas y sin uso** en la firma final: el trait `Nombrable` (lo incorporan `Persona`, `Asistente` y `AI`, pero `saludar` ya pide la forma, no el nombre) y el alias `PersonaAsistente`. Compilan igual: definir un tipo no obliga a usarlo. Quedan como rastro de los tres caminos que probaste, y porque en un dominio real probablemente convivan: unas firmas piden `Nombrable` cuando quieren consentimiento, otras piden `Saludable` cuando quieren apertura.

## 7. 🟡 Nominal vs estructural: caracterizar un sistema de tipos

> Un sistema de tipos es **nominal** cuando los tipos se definen por **entidades con nombre** (clases, traits) y se referencian por ese nombre. Es **estructural** cuando un tipo se puede definir por **cómo está compuesto**. Scala tiene las dos cosas.

Dos ejemplos estructurales más, para ver que la idea es más amplia que `{ def … }`:

```scala
  // Una tupla: un valor compuesto por tres partes, sin nombre propio. Su tipo es su forma.
  def precioTotal(itemFactura: (Int, Int, String)): Int = {
    itemFactura._1 * itemFactura._2            // _1, _2, _3: las partes, por posición
  }
  precioTotal((3, 250, "tornillos"))           // Resultado: 750
```

Y el caso extremo, en **TypeScript**, que es puramente estructural (esto es TypeScript, no Scala):

```typescript
class A { }                         // una clase vacía
function f(a: A) { }

const algo = { m: () => {} };       // un objeto cualquiera, con un método m
f(algo)                             // compila: `algo` tiene "la forma de A", porque A no exige nada
```

Ahí `A` ni siquiera funciona como restricción: una clase vacía es la forma de cualquier cosa. (Si le pasás el objeto escrito directamente entre los paréntesis, TypeScript avisa por la propiedad extra; con una variable, entra.) En Scala `class A {}` sí restringe, porque las clases definen tipos nominales: solo entran instancias de `A`.

**La tabla completa de caracterización.** Son tres ejes independientes, y ya viste los tres:

| Eje | Opciones | Dónde lo viste |
|---|---|---|
| **Conformación** | **Nominal** (por nombre) · **Estructural** (por forma) | Este módulo |
| **Notación** | **Explícito** (podés anotar; la inferencia es parte de esto) · **Implícito** (no hay anotación) | Módulo 2 |
| **Chequeo** | **"Estático"** (antes de ejecutar) · **"Dinámico"** (en ejecución) | Módulos 1 y 2 |

**Ejercicio: caracterizar Ruby.** Hacelo antes de leer la respuesta.

Chequeo: **dinámico** (Módulo 1). Notación: **implícito**: no hay forma de anotar un tipo (Módulo 2). Conformación: acá hay discusión. Si mirás **cómo se definen** los tipos, parece nominal: los define una clase, con nombre. Si mirás **cómo se usan**, es estructural: lo que un método puede recibir es cualquier cosa que entienda los mensajes que le manda adentro, sin importar la clase. Y como en Ruby las definiciones de clase son constructores y métodos pero no restricciones sobre qué se puede pasar, la respuesta que mejor describe cómo se programa en Ruby es **estructural**. El valor del ejercicio está en la distinción, no en el veredicto: hay que decir si estás hablando del momento de definir o del momento de usar.

> **Para el parcial, si te preguntan**
> *Caracterizá el tipado de Ruby.* — Chequeo dinámico (en ejecución), notación implícita (no existe anotación de tipo) y conformación estructural: un parámetro acepta cualquier objeto que entienda los mensajes que se le mandan, sin que la clase importe. La definición de tipos parece nominal (clases con nombre), pero el uso es por forma.

## 8. 🔴 La decisión de diseño: puntos de extensión

> Trait, unión y tipo estructural resuelven el mismo problema con **tres puertas de extensión distintas**. Elegir una es decidir **quién va a poder usar tu código y cómo**. El tipado es contarle al lenguaje **el programa que querías hacer**, para que te frene cuando lo que escribís después lo contradice.

| Forma | Quién entra a `saludar` | Qué controlás | Cuándo conviene |
|---|---|---|---|
| **Trait** `Nombrable` (nominal) | Quien declara `extends Nombrable` | Que la pertenencia sea **explícita**: cada clase consiente | El dominio es tuyo y querés que "ser nombrable" sea una decisión de diseño visible. Además, un trait puede traer comportamiento (Módulo 7) |
| **Unión** `Persona \| Asistente` | Exactamente esos dos | Una **lista cerrada**; para sumar uno, tocás la firma | Son dos o tres cosas puntuales, inventar un nombre común no aporta, o las clases no son tuyas |
| **Estructural** `{ def nombre: String }` | Cualquier cosa con esa forma, tuya o ajena | Nada: es **apertura total** | Recibís objetos de código que no controlás, o querés que todo el mundo pueda usar la función sin incorporar nada |

Un ejemplo de cada lado. Si publicás un framework y pedís `Nombrable`, el que quiera usarlo tiene que agregar `extends Nombrable` a su clase: trivial si puede tocarla, imposible si viene de otra librería. Si pedís `{ def nombre: String }`, cualquiera entra, incluido lo que nunca pensó en vos; a cambio, perdés la posibilidad de agregarle comportamiento a "lo nombrable" y el chequeo se hace por nombre de método en ejecución.

Esto conecta con `override` del Módulo 4: **los mecanismos de control existen para protegerte de vos mismo y de los que usan tu código, no porque el lenguaje los necesite.** Cuando elegís `Nombrable` en vez de `{ def nombre: String }`, estás tomando una decisión sobre el usuario de tu código: "entra el que lo diga". Cuando elegís lo estructural, decís "entra cualquiera". Ninguna es mejor en abstracto; cada una es la respuesta a una pregunta de diseño distinta, y en Scala vas a encontrar operaciones de la librería estándar definidas de las dos maneras, según lo que quisieron permitir.

Y la frase que resume la unidad: **tipar es declarar una intención y pedir coherencia.** Cuando escribís `a: Nombrable`, estás diciendo "esta función está pensada para nombrables". Si después la llamás con otra cosa, hay dos partes del programa que dicen cosas distintas, y el chequeador te frena ahí. Ignora cuál de las dos está mal; sabe que juntas chocan.

> **Para el parcial, si te preguntan**
> *Tenés que saludar objetos de una librería externa que tienen `nombre: String` y no podés modificar. ¿Qué tipo le ponés al parámetro?* — Un tipo estructural, `{ def nombre: String }` (con un alias si se repite): acepta cualquier objeto con esa forma sin que la clase lo declare. Un trait no sirve porque la clase ajena no puede incorporarlo; una unión obligaría a enumerar las clases y a tocar la firma con cada una nueva.

> **Para el parcial, si te preguntan**
> *¿Cuándo preferís un trait a un tipo estructural?* — Cuando el dominio es tuyo y querés que la pertenencia sea una decisión explícita y visible de cada clase (consentimiento), o cuando lo común va a tener también comportamiento. El trait controla quién entra; el estructural abre la puerta a todo lo que tenga la forma.

🕳️ **Madriguera — Kotlin y las clases cerradas.** Hay lenguajes donde las clases vienen cerradas a la herencia salvo que digas `open`; en la práctica, la gente termina marcando todo como `open`. Es la misma discusión de control vs apertura, aplicada a la herencia. *Volvé al camino — esto se profundiza aparte, otro día.*

🕳️ **Madriguera — tipos de retorno obligatorios en TypeScript.** En lenguajes donde el retorno se infiere, es común configurar herramientas para que exijan escribirlo igual: la gente le toma el gusto a leer la firma y saber de dónde a dónde va una función. *Volvé al camino — esto se profundiza aparte, otro día.*

🕳️ **Madriguera — hay programas que no se pueden construir.** Si un lenguaje solo tiene tipos nominales, no hay forma de hacer que una clase ajena y cerrada entre a tu función aunque tenga la forma exacta: ese programa no se puede construir. Los lenguajes agregan herramientas (unión, estructural) para achicar ese conjunto, y cuando no alcanzan aparece la herramienta de emergencia del Módulo 8. *Volvé al camino — esto se profundiza aparte, otro día.*

---

## Checkpoint (sin respuestas)

1. ¿Qué pasa con la cantidad de objetos y la cantidad de mensajes al subir en la jerarquía de tipos?
2. Enunciá la regla para el tipo de los parámetros y la del tipo de retorno. ¿Por qué van en direcciones opuestas?
3. `saludar` devuelve el mismo `String` anotado como `String` o como `Any`. ¿Qué cambia para el que llama?
4. "Lo que importa es lo de afuera": explicalo con el ejemplo de las tres referencias al mismo objeto.
5. ¿Qué mensajes le podés mandar a un `Persona | Asistente`? ¿Por qué?
6. ¿Por qué la unión no es un punto de extensión? ¿Cuándo conviene igual?
7. `type Saludable = { def nombre: String }` tiene nombre. ¿Es nominal o estructural? ¿Qué decide eso?
8. ¿Para qué hace falta `import scala.reflect.Selectable.reflectiveSelectable`?
9. Caracterizá Ruby en los tres ejes. ¿Por qué el eje de conformación admite discusión?
10. Aparece una clase ajena que tenés que saludar y no podés tocar. ¿Qué tipo le ponés al parámetro y qué descartás?

## Qué viene después

**Módulo 6:** cambio de dominio. Los guerreros, murallas y misiles de clase01, ahora en Scala, con tests. Lo primero es hacer compilar un método que todavía no sabés escribir.

**FIN DEL MÓDULO 5**
