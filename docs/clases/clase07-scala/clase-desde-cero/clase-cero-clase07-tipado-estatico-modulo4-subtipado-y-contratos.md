# Clase desde cero — Tipado estático en Scala — Módulo 4: ¿Y el polimorfismo? Subtipado y contratos

**Unidad:** clase07 · **Lenguaje:** Scala 3.3.1 · **Densidad:** 🔴 una sesión con el proyecto abierto

---

## Sobre este documento

**Qué cubre.** El falso negativo del Módulo 3 tiene nombre: es el problema del **polimorfismo**. La definición que traés de objetos ("entienden los mismos mensajes") ya no alcanza; con tipos hace falta un **tipo común declarado**. Qué es **subtipado**. Las dos formas de declarar ese tipo común que ves acá: una **superclase** y un **trait** con un método abstracto. Qué es un **contrato fuerte** y por qué las clases tienen que dar su **consentimiento**. Y `override`: cuándo es obligatorio y de qué te protege.

**Qué no cubre.** Las otras dos formas de nombrar lo común (unión de tipos y tipo estructural), y la regla para elegir qué tipo poner: Módulo 5.

## De dónde venís

Del Módulo 3: `saludar(a: Persona)` rechaza un `Asistente` que también entiende `nombre`. De clase01: la herencia simple y su costo ("la herencia es una carta cara"). De clase02: mixins, traits, linearización. De Paradigmas: la definición de polimorfismo.

---

## 1. 🔴 La definición de polimorfismo que traés, y por qué acá no alcanza

> En objetos, hay polimorfismo cuando **un tercero trata indistintamente a dos o más objetos**. Sin tipos, alcanza con que los dos **entiendan los mismos mensajes**. Con chequeo estático, además hace falta **un tipo en común, declarado**, con el que ese tercero los referencie.

La definición de Paradigmas es cuidadosa: *un objeto puede tratar de forma indistinta a dos o más objetos que comparten una interfaz*. En Ruby, en Wollok, en JavaScript, "compartir una interfaz" quiere decir **exponer los mismos mensajes**. `Persona` y `Asistente` entienden `nombre`; `saludar` les manda `nombre`; listo, hay polimorfismo. Esa es una definición **estructural**: mira la forma de los objetos.

En Scala, el Módulo 3 ya mostró que eso no alcanza:

```scala
  class Persona(val nombre: String)
  class Asistente(val nombre: String)

  class Saludador(cordial: Boolean = false) {
    def saludar(a: Persona): String = {
      if (cordial) {
        "Buen día estimado/a " + a.nombre
      } else {
        "Hola"
      }
    }
  }

  new Saludador(true).saludar(new Asistente("Siri"))
  // Found:    tadp.nadaquever.Saludador.Asistente
  // Required: tadp.nadaquever.Saludador.Persona
```

El chequeador aplica reglas sobre declaraciones y una de las reglas es "dijiste `Persona`; un `Asistente` es otra clase". Le importa poco que el programa fuera a funcionar: **no está pensando en la ejecución**. Para que trate a los dos indistintamente, necesita que los dos tipos estén **relacionados de alguna manera que él pueda ver**.

## 2. 🔴 Dos intentos que fallan, y qué enseñan

> Subir el tipo a `Any` acepta todo y te deja usar nada. Cambiar `Persona` por `Asistente` apaga el rojo de un lado y lo prende del otro.

**Intento 1: `Any`.** Todos los valores de Scala comparten un tipo, `Any`, que está arriba de todo (como `Object` en Java). Si `saludar` recibe `Any`, acepta un `Asistente`:

```scala
    def saludar(a: Any): String = {
      if (cordial) {
        "Buen día estimado/a " + a.nombre      // ← ahora el rojo está acá
      } else {
        "Hola"
      }
    }
```

```
value nombre is not a member of Any
```

El pasaje compila; el uso no. Un `Any` puede ser cualquier objeto del sistema, así que lo único que podés hacer con él es lo que **todo** objeto entiende: comparar, convertir a texto, poco más. **Cuanto más arriba el tipo, más cosas acepta y menos mensajes te deja mandar.** Esa relación es el tema del Módulo 5.

**Intento 2: cambiar `Persona` por `Asistente`.** Es lo que alguien hace siguiendo el rojo del Módulo 3:

| Escribís | Sale al llamar con `Asistente` | Sale al llamar con `Persona` |
|---|---|---|
| `def saludar(a: Persona)` | `Found: Asistente / Required: Persona` | ✅ |
| `def saludar(a: Asistente)` | ✅ | `Found: Persona / Required: Asistente` |

Arreglaste la línea que estaba en rojo y rompiste la que estaba bien. **Cumpliste el objetivo y malinterpretaste el deseo**: el deseo era que `saludar` aceptara a los dos. Es la trampa del Módulo 2 ("el rojo es el síntoma") en acción, y va a pasar más veces cuanto más complejo sea el sistema de tipos: te tapás de un lado y te destapás del otro.

Lo que hace falta es **otra cosa**, que incluya a las dos.

## 3. 🔴 Subtipado

> Si **A es subtipo de B**, entonces **sobre un A puedo hacer todo lo que puedo hacer sobre un B**. Por eso, donde se espera un B, puedo poner un A, y es seguro.

```
       ┌─────┐
       │  B  │          val unA: A = ...
       └──▲──┘          val unB: B = unA        // OK: un A es un B
          │             unB.operacionDeB()      // OK: todo A entiende lo de B
       ┌──┴──┐
       │  A  │
       └─────┘
     "A es subtipo de B"  (A <: B)
```

Es una relación entre **dos tipos**, y es lo que el chequeador necesita para dejar pasar un objeto donde se declaró otro tipo: si puede demostrar que `Asistente` es subtipo de lo que `saludar` pide, el pasaje es seguro, porque todo lo que `saludar` le mande, un `Asistente` lo entiende.

**Cómo se declaran tipos y subtipos en un lenguaje de objetos.** En Ruby, una clase hacía dos cosas: definir las operaciones de un conjunto de objetos y proveer el constructor. Con chequeo estático se suma una tercera: **una clase define un tipo**. Y hay cuatro caminos para definir un subtipo:

| # | Declarando… | Define | Dónde lo ves |
|---|---|---|---|
| 1 | una **clase** que hereda de otra (`class C extends S`) | `C` es subtipo de `S` | Sección 4 |
| 2 | una **interfaz**: firmas de mensajes sin implementación | En Scala se hace con un `trait` | Sección 5 |
| 3 | **composición de traits**: un trait también es un tipo; si un trait compone otro, o una clase usa un trait, es subtipo de ese trait | Módulo 7 |
| 4 | un **tipo estructural**: el tipo en función de la forma | Módulo 5 |

`Any` es el tope de la jerarquía; todo tipo es subtipo de `Any`. Por eso `Any` acepta todo (sección 2). Scala lo divide en `AnyVal` (los valores primitivos: `Int`, `Boolean`, `Unit`…) y `AnyRef` (los objetos, el `Object` de Java); para esta materia pensás en `Any` y listo.

## 4. 🟡 Solución 1: una superclase

> Si `Persona` y `Asistente` **heredan de la misma clase**, esa clase es un tipo común, y `saludar` puede pedirlo.

```scala
  // Una clase común que tiene el nombre. Su constructor lo recibe y lo expone.
  class Nombrable(val nombre: String)

  // extends: herencia simple. Entre paréntesis van los argumentos para el constructor del padre.
  class Persona(_nombre: String) extends Nombrable(_nombre)
  class Asistente(_nombre: String) extends Nombrable(_nombre)

  class Saludador(cordial: Boolean = false) {
    def saludar(a: Nombrable): String = {            // ← el tipo común
      if (cordial) {
        "Buen día estimado/a " + a.nombre
      } else {
        "Hola"
      }
    }
  }

  println(new Saludador(true).saludar(new Persona("Ernesto")))   // Resultado: Buen día estimado/a Ernesto
  println(new Saludador(true).saludar(new Asistente("Siri")))    // Resultado: Buen día estimado/a Siri
```

Dos cosas de sintaxis:

- **`extends Nombrable(_nombre)`**: heredar y, en la misma línea, pasarle al constructor del padre lo que necesita. En Ruby eran dos pasos (`< Nombrable` y `super(nombre)` en `initialize`).
- **`_nombre`**: el parámetro se llama distinto del método heredado `nombre` a propósito. Si se llamara igual, adentro de `Persona` la palabra `nombre` sería el parámetro y taparía al método que viene del padre. El guion bajo es una convención, no una regla del lenguaje: cualquier nombre distinto sirve.

Funciona, y tiene el costo que ya conocés de clase01: **la herencia es una carta cara**. `Persona` y `Asistente` quedan atadas a `Nombrable` para siempre, solo pueden heredar de una clase, y nada en el dominio dice que una persona y un asistente virtual sean "la misma cosa con nombre". Querés que los dos tengan nombre, sin obligarlos a ser hermanos.

## 5. 🔴 Solución 2: un trait con un método abstracto — el contrato fuerte

> Un **`trait`** con un método **abstracto** (declarado sin cuerpo) es un **contrato**: quien lo incorpora **tiene que** implementar ese método, o el programa no compila. Es la forma de decir "estas cosas tienen nombre" sin decir cómo lo tienen.

```scala
  // Un trait con un método abstracto: def sin `=` ni cuerpo. Solo la firma.
  trait Nombrable {
    def nombre: String
  }

  // `val nombre` en el constructor cumple el contrato: define nombre y devuelve un String.
  class Persona(val nombre: String) extends Nombrable
  class Asistente(val nombre: String) extends Nombrable

  class Saludador(cordial: Boolean = false) {
    def saludar(a: Nombrable): String = {
      if (cordial) {
        "Buen día estimado/a " + a.nombre
      } else {
        "Hola"
      }
    }
  }

  println(new Saludador(true).saludar(new Persona("Ernesto")))   // Resultado: Buen día estimado/a Ernesto
  println(new Saludador(true).saludar(new Asistente("Siri")))    // Resultado: Buen día estimado/a Siri
```

Qué cambió respecto de la sección 4:

- `Nombrable` **no tiene implementación**. Dice "quien sea `Nombrable` responde `nombre` con un `String`" y nada más. Nadie hereda un constructor ni un atributo.
- Las clases **no están atadas entre sí**. `Persona` y `Asistente` solo comparten la promesa.
- Un `val nombre` alcanza para cumplir un `def nombre`. Guardá esa pregunta (¿por qué un `val` cumple un `def`?): se responde en los Módulos 6 y 7.

Una variante que vas a ver en el código de la unidad: la clase guarda el dato con otro nombre y cumple el contrato explícitamente.

```scala
  class Persona(val name: String) extends Nombrable {
    override val nombre: String = this.name     // cumple `nombre` devolviendo el campo `name`
  }
```

**Por qué es un contrato fuerte.** Probá renombrar `nombre` en `Persona`:

```scala
  class Persona(val nombres: String) extends Nombrable
```

```
class Persona needs to be abstract, since def nombre: String in trait Nombrable in object Saludador is not defined
```

El compilador te frena: "dijiste que eras `Nombrable`; `Nombrable` promete `nombre`; no lo veo". Eso es un **contrato fuerte**: lo hace cumplir el chequeador, al compilar. En Ruby el contrato de un mixin era **débil**: podías incluirlo y no definir lo que esperaba, y te enterabas en ejecución, cuando alguien mandaba el mensaje que faltaba. Fijate que `nombres` por `nombre` es exactamente el error del Módulo 1, y acá se detecta antes de que exista un objeto.

| Escribís | Sale |
|---|---|
| `class Persona(val nombre: String) extends Nombrable` | ✅ compila: el `val` cumple el `def` |
| `class Persona(val nombres: String) extends Nombrable` | ❌ `class Persona needs to be abstract, since def nombre … is not defined` |
| `class Persona(val nombre: Int) extends Nombrable` | ❌ `error overriding method nombre in trait Nombrable of type => String; value nombre of type Int has incompatible type` — el contrato también fija el tipo de retorno |

**Trait y mixin.** Lo que en clase02 llamaste mixin, Scala lo escribe con la palabra `trait`. Es el mismo concepto: comportamiento que se compone en una clase (Módulo 7, con `with`). El nombre `trait` es un nombre mal puesto que quedó: no son los traits de los papers de clase02. Y un trait en el que **todo** es abstracto, como este `Nombrable`, es lo más parecido que tiene Scala a una **interfaz** de Java: una clase abstracta sin métodos concretos, de la que podés incorporar tantas como quieras.

## 6. 🔴 Consentimiento: el contrato es nominal

> Con un trait, para que dos clases sean polimórficas **tienen que decirlo**: `extends Nombrable`. Compartir la forma ya no alcanza; hay que **compartir el nombre**. Eso es un contrato **nominal**.

En Ruby, cualquier objeto que tuviera `nombre` entraba a `saludar`, incluso uno que vos no escribiste. Acá, una clase de otro **framework** (código ajeno que tu programa usa, o que usa a tu programa) que tenga exactamente el campo `nombre: String` **queda afuera**, porque le falta `extends Nombrable`. Esa clase no estaba pensada para trabajar con tu sistema, y la prueba es que no incorpora tu interfaz. Las clases **dan su consentimiento**: "yo soy `Nombrable`; de ahora en adelante acepto que me usen donde se espera uno".

¿Y `Any`? `Persona` y `Asistente` ya compartían `Any` desde antes. La diferencia es que **`Nombrable` entiende `nombre` y `Any` no**: `Nombrable` no lo implementa, pero promete que quien lo incorpore sí. Cuando recibís un `Nombrable` podés mandar `nombre`; cuando recibís un `Any`, solo lo que todo objeto entiende.

> **Para el parcial, si te preguntan**
> *Aparece una tercera clase, `AI`, con `nombre`, y también hay que saludarla. ¿Qué cambiás?* — Una sola cosa: `class AI(val nombre: String) extends Nombrable`. `saludar` no se toca, porque pide un `Nombrable` y `AI` acaba de consentir ser uno. Eso es lo que hace de `Nombrable` un **punto de extensión**: cualquiera puede sumarse implementando el contrato, sin tocar al que lo usa.

> **Para el parcial, si te preguntan**
> *¿Por qué no alcanza con que `Persona` y `Asistente` entiendan `nombre` para que `saludar` acepte a los dos?* — Porque con chequeo estático el polimorfismo necesita un tipo común **declarado**: el compilador aplica reglas sobre las declaraciones, no sobre la forma de los objetos en ejecución. Hace falta que ambas clases incorporen explícitamente un tipo que prometa `nombre` (un `trait`), y que `saludar` pida ese tipo.

## 7. 🟡 `override`: cuándo es obligatorio y de qué te protege

> Redefinir un método **concreto** heredado exige la palabra **`override`**. Implementar un método **abstracto** la acepta como opcional. El lenguaje funciona igual sin ella: está para que una pifiada sea visible.

```
   ┌───────────┐
   │     A     │   m()           ← definido acá
   └─────▲─────┘
         │
   ┌─────┴─────┐
   │     B     │
   └─────▲─────┘
         │
   ┌─────┴─────┐
   │     C     │   m()           ← redefinido acá: pide `override`
   └───────────┘
```

| Escribís en `C` | Sale |
|---|---|
| `def m(): Int = 2` (y `A` ya tiene `m`) | `error overriding method m in class A of type (): Int; method m of type (): Int needs `override' modifier` |
| `override def m(): Int = 2` | ✅ |
| `override def n(): Int = 2` (y nadie tiene `n`) | `method n overrides nothing` |
| `val nombre: String` implementando el `def nombre` abstracto del trait | ✅ con o sin `override` |

¿Qué información aporta `override`, si el compilador ya sabe que hay dos `m`? Ninguna sobre el programa. Aporta sobre **vos**: dice "lo hice a propósito". Y protege en dos direcciones:

- A vos, de redefinir sin querer algo que existía más arriba, tal vez en una librería que ni mirás.
- Al que viene después, de agregar un `m` arriba y romper tu `C` en silencio: ahora el compilador le avisa que abajo ya había uno.

Es el mismo tipo de herramienta que `private` o `final`: **mecanismos de control que la tecnología te da para protegerte de vos mismo**, no cosas que la tecnología necesite. Con el tipado pasa igual, y el Módulo 5 lo hace explícito.

🕳️ **Madriguera — la JVM no distingue tipos en ejecución.** Una vez compilado, el programa corre sobre la JVM y ahí todos los objetos son `Object`: el chequeo de tipos **ya ocurrió**, así que la ejecución no lo repite. Vuelve en el Módulo 8, con el casteo. *Volvé al camino — esto se profundiza aparte, otro día.*

---

## Checkpoint (sin respuestas)

1. Enunciá la definición de polimorfismo de Paradigmas. ¿Qué le agrega el chequeo estático?
2. ¿Por qué `saludar(a: Any)` acepta un `Asistente` y aun así no compila?
3. ¿Qué pasa si cambiás `a: Persona` por `a: Asistente`? ¿Qué nombre le dimos a ese error en el Módulo 2?
4. Definí subtipado. Si `A <: B`, ¿qué puedo hacer con un `A` y por qué es seguro ponerlo donde se espera un `B`?
5. Nombrá los cuatro caminos para definir un subtipo. ¿Cuáles viste en este módulo?
6. ¿Qué costo tiene resolver el problema con una superclase `Nombrable`?
7. ¿Qué es un contrato fuerte? ¿Qué error da el compilador si `Persona` deja de definir `nombre`? ¿Cómo era el contrato equivalente en Ruby?
8. ¿Qué quiere decir que el contrato es nominal? ¿Qué pasa con una clase ajena que tiene `nombre` pero no dice `extends Nombrable`?
9. ¿Cuándo `override` es obligatorio y cuándo opcional? ¿De qué te protege?

## Qué viene después

**Módulo 5:** ya sabés *cómo* nombrar lo común. Falta decidir *qué* tipo poner: una regla para parámetros y retornos, y las otras dos formas de nombrar lo común (unión de tipos y tipo estructural), cada una con una puerta de extensión distinta.

**FIN DEL MÓDULO 4**
