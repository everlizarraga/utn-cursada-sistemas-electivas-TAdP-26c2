# Clase desde cero — Tipado estático en Scala — Módulo 1: El problema — un error de tipos que el test no vio

**Unidad:** clase07 · **Lenguaje:** Ruby (este módulo) · **Densidad:** 🟡 corto, fija tres definiciones

---

## Sobre este documento

**Qué cubre.** Un programa Ruby de quince líneas con un error que pasa un test y revienta en producción. Sobre ese caso, tres definiciones que sostienen toda la unidad: qué es un **tipo**, qué es un **error de tipos**, y qué quiere decir que Ruby chequea tipos **en ejecución**. Termina con la pregunta que el resto de la unidad responde.

**Qué no cubre.** Scala. Este módulo es el último en Ruby.

## De dónde venís

De clase01 a clase04: clases, `attr_accessor`, `initialize`, `if`, concatenación de strings, `pry`, RSpec, y `method_missing` (clase04). Se asume todo eso sin volver a explicarlo.

---

## 1. 🔴 El programa que funciona hasta que deja de funcionar

> Un programa puede pasar sus pruebas y seguir teniendo un error que **ya está escrito**, esperando la rama que nadie probó.

Un saludador. Si es cordial, saluda con nombre; si no, tira un "holis".

```ruby
# saludador.rb
class Persona
  attr_accessor :name            # Persona guarda su nombre en `name`

  def initialize(name)
    self.name = name
  end
end

class Saludador
  attr_accessor :cordial         # true: saludo formal · false: saludo corto

  def initialize(cordial = false)
    self.cordial = cordial
  end

  def saludar(a)                 # `a` es "algo a quien saludar"
    if cordial
      "Buen día estimado " + a.nombre     # ← acá está el error
    else
      "Hoooliiiiisss"
    end
  end
end
```

`Persona` entiende `name`. `saludar` le manda `nombre`. Son dos palabras distintas; el programa está mal escrito. Pero mirá qué pasa al probarlo:

```ruby
# en pry, después de require_relative './saludador.rb'
Saludador.new.saludar(Persona.new("Ernesto"))
# => "Hoooliiiiisss"                      ← funciona: el saludador no es cordial, y esa rama no toca `nombre`

Saludador.new(true).saludar(Persona.new("Ernesto"))
# NoMethodError: undefined method `nombre' for #<Persona:0x0055efead8cb58 @name="Ernesto">
#   from saludador.rb:19:in `saludar'      ← revienta: la rama cordial sí manda `nombre`
```

Un test que cubra solo la primera llamada pasa. Si ese es el único test, el programa llega a producción con el error adentro, y revienta la primera vez que alguien pide un saludo cordial.

**El arreglo es de una palabra.** Hay dos arreglos posibles, y el código no dice cuál es el correcto:

| Arreglo | Qué cambia | Lectura |
|---|---|---|
| `attr_accessor :nombre` (y `self.nombre = name`) | `Persona` pasa a entender `nombre` | "El que escribió `Persona` se equivocó de palabra" |
| `a.name` en `saludar` | `saludar` manda el mensaje que `Persona` entiende | "El que escribió `saludar` se equivocó de mensaje" |

Los dos hacen pasar el programa. Cuál es *el bueno* depende de qué quería hacer quien lo escribió, y eso no está en el código. Guardá esta idea: vuelve en el Módulo 2 con más fuerza.

Con el primer arreglo:

```ruby
Saludador.new(true).saludar(Persona.new("Ernesto"))
# => "Buen día estimado Ernesto"
```

## 2. 🔴 Qué es un tipo

> El **tipo** de un objeto es **el conjunto de mensajes que entiende**: su interfaz. Dos objetos que entienden los mismos mensajes comparten un tipo.

En el programa de arriba:

| Objeto | Mensajes que entiende | Ese conjunto es su tipo |
|---|---|---|
| `Persona.new("Ernesto")` | `name`, `name=`, más los que toda instancia entiende (`class`, `to_s`, …) | "algo que entiende `name`" |
| `Saludador.new` | `cordial`, `cordial=`, `saludar` | "algo que saluda" |

Esta forma de definir tipo mira **qué operaciones se pueden hacer** sobre un valor. Se llama el aspecto **operacional** del tipo, y es el único que esta unidad usa. En general, un tipo es *un conjunto de valores asociado a un conjunto de operaciones*.

Hay otros dos aspectos, para saber que existen:

- **Representacional:** cómo se guarda el valor en memoria (cuántos bytes, en qué formato). Es asunto de la máquina; acá no lo tocamos.
- **Estructural:** cómo se compone un valor y cómo se puede armar y desarmar. Una lista es "una cabeza y una cola"; una fecha es "día, mes y año". Vuelve en el Módulo 5.

Una consecuencia de la definición: **compartir un tipo no es ser del mismo tipo**. Un `Asistente` que entienda `name` comparte con `Persona` el tipo "algo que entiende `name`", aunque `Asistente` entienda además veinte mensajes que `Persona` no.

> **Para el parcial, si te preguntan**
> *¿Qué tipo tiene que tener lo que recibe `saludar`?* — Algo que entienda `nombre`. Eso, y nada más: el tipo del parámetro es el conjunto de mensajes que el método le manda adentro. `Persona` es una de las cosas que puede cumplirlo, no la definición del tipo.

## 3. 🔴 Qué es un error de tipos

> Un **error de tipos** es mandarle a un objeto **un mensaje que no entiende**. Dicho en general: usar algo para una operación que no es.

Es exactamente lo que pasó en la sección 1: `saludar` le mandó `nombre` a algo que entiende `name`. El `NoMethodError` es la forma que toma ese error en Ruby.

La definición general es más amplia que el código. Ponerle sal al café es un error de tipos: usaste algo para el propósito equivocado y alguien se da cuenta en algún momento. En el dominio del programa pasa lo mismo: si una `Muralla` recibe el mensaje `atacar`, hay un error de tipos, aunque el programa siga corriendo porque alguien le definió `atacar` por las dudas. **Un error sin detectar sigue siendo un error.**

Cada vez que en clase04 escribiste un `method_missing`, estabas **manejando un error de tipos**: un mensaje llegó a un objeto que no lo entendía, y en vez de reventar decidiste qué hacer con él.

## 4. 🔴 Ruby chequea tipos, en ejecución

> Ruby **sí** chequea tipos. Lo hace **cuando se manda el mensaje**, con el objeto concreto en la mano. A eso se le dice chequeo **"dinámico"**.

Si Ruby no chequeara tipos, al recibir `nombre` una `Persona` intentaría ejecutar *algo* de todas formas: buscar en memoria una instrucción con ese nombre, correr lo que encuentre, seguir con un dato corrupto. El `NoMethodError` **es** el chequeo: Ruby miró el objeto, miró el mensaje, vio que no lo entiende y frenó.

Lo que define a este chequeo son dos cosas:

| | Chequeo dinámico (Ruby) |
|---|---|
| **Cuándo** | Al ejecutar, en el momento exacto en que se manda el mensaje |
| **Con qué información** | El objeto concreto que está ahí: su clase, sus métodos, su estado |

Por eso el error de la sección 1 quedó escondido: la rama cordial **nunca se ejecutó** en la prueba, así que el mensaje `nombre` nunca se mandó, así que nadie lo chequeó. El error estaba escrito desde el primer día; el chequeo llegó cuando alguien pidió un saludo cordial.

> **Para el parcial, si te preguntan**
> *"Ruby no tiene tipos."* — Falso. Ruby tiene tipos (cada objeto tiene un conjunto de mensajes que entiende) y chequea tipos (el `NoMethodError`). Lo que falta en Ruby es un chequeo **previo** a la ejecución: te enterás del error cuando el mensaje se manda.

**La pregunta que abre la unidad.** El error de la sección 1 se ve *leyendo* el código: `Persona` dice `name`, `saludar` dice `nombre`, y alcanza con leerlo para notarlo, sin ejecutar nada. Si un humano puede verlo leyendo, ¿puede una herramienta verlo leyendo, antes de ejecutar una sola línea? Eso es el Módulo 2.

🕳️ **Madriguera — cómo guarda Ruby los objetos.** El aspecto representacional (cómo está un objeto en memoria, qué es ese `0x0055efead8cb58`) es tema de otra materia. *Volvé al camino — esto se profundiza aparte, otro día.*

---

## Checkpoint (sin respuestas)

1. ¿Por qué el programa de la sección 1 pasa una prueba y revienta en otra, si el error está escrito desde el principio?
2. Nombrá los dos arreglos posibles del error. ¿Qué información haría falta para elegir el correcto?
3. Definí "tipo de un objeto" en una oración.
4. ¿Qué diferencia hay entre "comparten un tipo" y "son del mismo tipo"?
5. ¿Qué es un error de tipos? Da un ejemplo que no sea de programación.
6. ¿Qué relación hay entre `method_missing` y los errores de tipos?
7. ¿Ruby chequea tipos? ¿Cuándo y con qué información?
8. ¿Qué tipo tiene que tener el parámetro `a` de `saludar`? ¿Por qué la respuesta no es "`Persona`"?

## Qué viene después

**Módulo 2:** el mismo programa, en Scala. El mismo error, pero esta vez el programa **no llega a correr**.

**FIN DEL MÓDULO 1**
