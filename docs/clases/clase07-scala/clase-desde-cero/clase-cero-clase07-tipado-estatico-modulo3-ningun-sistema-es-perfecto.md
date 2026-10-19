# Clase desde cero — Tipado estático en Scala — Módulo 3: Ningún sistema de tipos es perfecto

**Unidad:** clase07 · **Lenguaje:** Scala 3.3.1 · **Densidad:** 🟡 se lee de corrido, con dos pruebas en el proyecto

---

## Sobre este documento

**Qué cubre.** Qué garantiza un chequeador de tipos y qué no: los dos conjuntos (programas que **acepta** y programas que **funcionan**), los **falsos positivos** y los **falsos negativos**, y un falso negativo concreto en el `Saludador`. Por qué un chequeador perfecto es imposible. Las **operaciones parciales**: errores que explotan en ejecución y el sistema de tipos deja pasar a propósito. Y la diferencia que de verdad importa entre chequear antes y chequear durante: **cuándo y cómo** aparece el error.

**Qué no cubre.** Cómo se arregla el falso negativo del `Saludador`: eso es el Módulo 4.

## De dónde venís

Del Módulo 2: el `Saludador` en Scala con `class Persona(val nombre: String)`, qué es el chequeo estático, y la lista de ventajas y desventajas. Este módulo desarrolla la última desventaja.

---

## 1. 🔴 Dos conjuntos de programas

> Hay programas que el compilador **acepta** y programas que **funcionan**. Son dos conjuntos distintos, y el chequeador de tipos es bueno en la medida en que coinciden.

```
       Programas aceptados                 Programas válidos
          (compilan)                        (funcionarían)
              │                                   │
     .────────┴────────.               .──────────┴───────.
   .'                    '.          .'                     '.
  .     Falsos          .──┴──.      Falsos                  .
  .     positivos      .   Aciertos  .   negativos            .
  .                     '.         .'                        .
   '.                    .'───────'.                       .'
     '─────────────────'             '────────────────────'
```

| Zona | Qué es | Ejemplo |
|---|---|---|
| **Aciertos** (intersección) | Programas que compilan y funcionan | Casi todo lo que vas a escribir |
| **Falsos positivos** (acepta, pero falla) | Programas que compilan y rompen en ejecución: **bugs** que el chequeador no ve | Sección 4 |
| **Falsos negativos** (rechaza, pero funcionaría) | Programas que **funcionarían** si los dejara correr, y el chequeador frena | Sección 2 |

Un chequeador perfecto haría coincidir los dos círculos: aceptaría todo lo que funciona y rechazaría todo lo que falla. La sección 3 explica por qué eso es imposible. Mientras tanto, lo que cambia entre lenguajes es **la forma del solapamiento**:

```
     Con chequeo estático               Sin chequeo estático

       .─────────.                        .─────────.
     .'  .───────'.──.                  .'──.───────  '.
    .   .           . .                . .           .  .
    .  . aceptados ≈  .                .  . válidos ≈  .  .
    .   . válidos   . .                . .  aceptados .  .
     '.  '───────.'──'                  '.──'───────.'  .'
       '─────────'                        '─────────'
   casi sin falsos positivos          casi sin falsos negativos
   quedan falsos negativos            quedan falsos positivos
```

- **Con chequeo estático**, el conjunto de aceptados queda casi adentro del de válidos: muy pocos bugs de tipos pasan; a cambio, hay programas válidos que el compilador rechaza.
- **Sin chequeo estático**, el conjunto de válidos queda casi adentro del de aceptados: casi nada válido se rechaza; a cambio, muchos programas con errores de tipos corren hasta que explotan.

Es un balance, y hay un argumento fuerte para preferir el primero: un falso positivo es un bug que llega a producción; un falso negativo es un programa que el compilador te frena en tu máquina y tenés que reescribir. El segundo costo lo pagás vos, ahora; el primero lo paga otro, después (sección 5).

## 2. 🔴 Un falso negativo concreto

> El `Saludador` acepta personas. Si aparece otra clase que **también entiende `nombre`**, el programa funcionaría, y el compilador lo rechaza igual.

```scala
package tadp.nadaquever

object Saludador extends App {

  class Persona(val nombre: String)
  class Asistente(val nombre: String)            // también tiene nombre

  class Saludador(cordial: Boolean = false) {
    def saludar(a: Persona): String = {
      if (cordial) {
        "Buen día estimado/a " + a.nombre
      } else {
        "Hola"
      }
    }
  }

  println(new Saludador(true).saludar(new Asistente("Siri")))
}
```

```
-- [E007] Type Mismatch Error: src/main/scala/tadp/nadaquever/Saludador.scala:18:39
18 |  println(new Saludador(true).saludar(new Asistente("Siri")))
   |                                      ^^^^^^^^^^^^^^^^^^^^^
   |                                      Found:    tadp.nadaquever.Saludador.Asistente
   |                                      Required: tadp.nadaquever.Saludador.Persona
```

Leé lo que pasó. Todo lo que `saludar` le manda al parámetro es `nombre`. `Asistente` entiende `nombre`. Si el programa corriera, imprimiría `Buen día estimado/a Siri`. **Es un programa correcto.** Y el chequeador dice que no, porque vos declaraste `a: Persona`, un `Asistente` es otra clase, y la regla es la de la sección 4 del Módulo 2: lo declarado se cree.

| Escribís | Sale | Es |
|---|---|---|
| `saludar(new Persona("Ernesto"))` | `Buen día estimado/a Ernesto` | Acierto |
| `saludar(new Asistente("Siri"))` | `Found: …Asistente / Required: …Persona` | **Falso negativo**: funcionaría, y se rechaza |

Fijate que esto es nuevo respecto de Ruby. En Ruby, cualquier objeto que entendiera `nombre` pasaba, porque el chequeo miraba al objeto. Acá el chequeo mira la declaración, y la declaración dice `Persona`. El Módulo 4 arranca exactamente de este error.

> **Para el parcial, si te preguntan**
> *¿Qué es un falso negativo del chequeador de tipos? Da un ejemplo.* — Un programa que funcionaría en ejecución y el compilador rechaza por una inconsistencia entre lo declarado y lo usado. Ejemplo: `saludar(a: Persona)` recibe un `Asistente` que también entiende `nombre`: el programa es correcto, y el compilador lo frena porque el tipo declarado del parámetro es `Persona`.

## 3. 🟡 Los dos extremos son triviales, y el medio es imposible

> Un chequeador que **nunca rechaza un programa válido** es trivial: dice siempre sí. Uno que **nunca acepta un programa inválido** también: dice siempre no. Lo difícil es hacer uno que haga **las dos cosas**, y está demostrado que hacerlo perfecto es imposible.

- "Siempre sí" tiene cero falsos negativos y deja pasar todos los bugs.
- "Siempre no" tiene cero falsos positivos y rechaza todo lo que escribas.

Un sistema de tipos real está en el medio, y cuanto más formas de programar soporta el lenguaje, más difícil es que la frontera entre aceptado y rechazado pase exactamente por donde debe. Está demostrado que para un lenguaje de propósito general es imposible que coincidan: siempre va a haber programas que funcionarían y no se pueden construir. El objetivo real es otro: que para cada cosa que necesitás hacer **haya alguna forma soportada** de hacerla, aunque no sea la primera que se te ocurrió. Cuando no la hay, aparecen herramientas de emergencia (Módulo 8).

## 4. 🟡 Operaciones parciales: los errores que el sistema de tipos deja pasar a propósito

> Hay operaciones que **compilan y explotan en ejecución**, y el sistema de tipos **las declara "no error de tipos"** a propósito: son **operaciones parciales**, definidas para una parte de su dominio.

En matemática una función exige dos cosas: **existencia** (todo elemento del dominio tiene imagen) y **unicidad** (una sola). En programación la primera se cumple rara vez, y la segunda a veces falla: un método que recibe enteros pero solo acepta positivos; `random`, que devuelve algo distinto cada vez. Dos casos que ya conocés:

```scala
object Parciales extends App {
  val x = 5
  val y = 0
  println(x / y)
  // Compila: los enteros entienden la división.
  // Resultado al ejecutar: java.lang.ArithmeticException: / by zero

  val lista = List()            // List() es la lista vacía; List(1, 2, 3) tiene tres elementos
  println(lista.head)           // head devuelve el primer elemento
  // Compila: las listas entienden head.
  // Resultado al ejecutar: java.util.NoSuchElementException: head of empty list
}
```

Ninguno de los dos es un error de tipos según el sistema de tipos: los enteros entienden `/`, las listas entienden `head`. El problema es el **valor** (cero, vacía), y el valor no se conoce al compilar. La operación es **parcial**: dividir está definido para todo entero salvo el cero; `head` está definido para toda lista salvo la vacía.

**¿Por qué no se tipa eso también?** Se podría: un tipo "entero distinto de cero", un tipo "lista con al menos un elemento". El precio es demasiado alto. Si las listas vacías y las no vacías fueran tipos distintos, ¿qué tipo devuelve `filter`? Depende de los datos, y los datos no se conocen al compilar; habría que devolver "una u otra", y al pedir `head` de ese resultado estás de vuelta en el mismo problema. El sistema de tipos **dibuja una línea en la arena**: de acá para acá lo chequeo, de acá para allá es responsabilidad tuya y te va a saltar en ejecución, pero por lo menos sabés exactamente dónde.

Dos consecuencias para vos:

- **Un chequeador de tipos deja pasar errores de tipos.** Siempre hay una construcción que se le escapa.
- La lista vacía vuelve en el Módulo 8, con un detalle de su tipo que todavía no podés leer.

> **Para el parcial, si te preguntan**
> *¿`x / 0` es un error de tipos?* — Para el sistema de tipos, no: los enteros entienden la división, así que la operación está bien tipada. Es una operación parcial, definida para todo entero salvo el cero; el error depende del valor y aparece en ejecución. El sistema de tipos la deja pasar porque tipar "entero distinto de cero" obligaría a tipar también todo lo que lo produce, y el costo supera al beneficio.

## 5. 🔴 La diferencia real: cuándo y cómo

> La diferencia de fondo entre chequear antes y chequear durante **no está en la cantidad de errores**, sino en **cuándo** aparecen y **a quién** le toca arreglarlos.

Imaginate el error del Módulo 1 en un sistema grande. Alguien, en algún momento, deja una referencia en `nil`. El objeto queda guardado. Cuarenta y cinco "años" después, otro pedazo del sistema le manda un mensaje, y explota con un **stack trace** enorme (la lista de llamadas que llevó hasta el error), mitad del cual es de un framework que desconocés, mientras vos estás de vacaciones. ¿Quién puso ese `nil`? ¿Hace cuánto? Lo tenés que averiguar vos, ahora, en producción.

El mismo error con chequeo estático: el que escribió el `nil` donde no iba vio el rojo **en su máquina**, antes de que nada corriera, y lo arregló él. Vos ni te enteraste.

Hay algo peor que un sistema que se cae: **un sistema que sigue corriendo en un estado inválido**. El que se cae ya dejó de hacer daño. El que sigue corriendo con un dato corrupto lo propaga: alguien lee el campo, lo copia, lo guarda, y cada minuto que pasa el problema está en más lugares. El chequeo estático corta eso en el único momento en que es barato: antes de que exista una ejecución.

Es la misma razón por la que escribís tests. Nadie quiere que el código se rompa; lo que se quiere es que, si se va a romper, **se rompa en tu entorno** antes que en el del usuario. El chequeador de tipos es la primera línea de eso, y es gratis: viene con el compilador.

Esto nació cuando ejecutar era carísimo (una computadora por universidad, con turnos para usarla), y sigue valiendo cuando fallar es carísimo: el software de un satélite con el que perdés contacto durante horas se verifica antes de lanzarlo, porque después no hay forma de arreglarlo. Un carrito de compras no es un satélite, pero el criterio es el mismo: **cada error que se detecta antes de correr es un error que nadie paga en producción.**

🕳️ **Madriguera — la tercera alternativa.** Además de chequear antes y chequear durante, hay una tercera opción: entornos (Assembler, por ejemplo) donde el error de tipos pasa sin detectarse; el programa reinterpreta el valor como dato y sigue, con algo corrupto en algún lado. Es el peor de los tres mundos. *Volvé al camino — esto se profundiza aparte, otro día.*

---

## Checkpoint (sin respuestas)

1. Dibujá los dos conjuntos y ubicá: aciertos, falsos positivos, falsos negativos. ¿Cuál de los dos "falsos" es un bug en producción?
2. ¿Cómo cambia la forma del solapamiento con y sin chequeo estático?
3. ¿Por qué `saludar(new Asistente("Siri"))` es un falso negativo? ¿Qué hubiera pasado en Ruby?
4. ¿Cómo se construye un chequeador sin falsos negativos? ¿Y uno sin falsos positivos? ¿Por qué ninguno sirve?
5. ¿Qué es una operación parcial? Da los dos ejemplos del módulo y decí qué exigencia matemática no cumplen.
6. ¿Por qué `x / 0` no es un error de tipos para el sistema de tipos? ¿Qué pasaría si se intentara tipar "lista no vacía"?
7. ¿Cuál es la diferencia real entre chequeo estático y dinámico, según este módulo? ¿Por qué no es "la cantidad de errores"?
8. ¿Por qué un sistema que sigue corriendo en estado inválido es peor que uno que se cae?

## Qué viene después

**Módulo 4:** el falso negativo de la sección 2 tiene nombre: es el problema del polimorfismo. Para que `saludar` acepte personas y asistentes, la definición de polimorfismo que traías de Ruby tiene que cambiar.

**FIN DEL MÓDULO 3**
