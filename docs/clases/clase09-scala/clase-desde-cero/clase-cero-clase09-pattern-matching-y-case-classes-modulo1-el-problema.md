# Clase desde cero — Pattern matching, case classes y el híbrido objeto-funcional — Módulo 1: El problema: un micro y sus operaciones

**Unidad:** clase09 · **Lenguaje:** Scala 3.3.1 · **Archivo del proyecto:** `objetos/Micro.scala` · **Densidad:** 🟡 se lee de corrido

---

## Sobre este documento

**Qué cubre.** El problema sobre el que trabaja toda la unidad: un microprocesador chico, su lenguaje de siete instrucciones, qué es un programa, cómo se ejecuta uno paso a paso, y las tres operaciones que se piden sobre un programa (ejecutarlo, imprimirlo, simplificarlo). Termina con la pregunta que motiva todo lo que sigue: **¿dónde van las operaciones?**

**Qué no cubre.** Ninguna de las soluciones. Acá se entiende el problema; resolverlo empieza en el Módulo 2.

## De dónde venís

De las dos unidades anteriores en Scala: `class`, `trait`, `val`/`var`, `def`, `List[A]`, `Array`, y que el compilador revisa los tipos antes de ejecutar. De Ruby: `attr_accessor` y la idea de que un objeto guarda estado y responde mensajes. Y del Módulo 0: qué hay en el proyecto y cómo se corre un bloque de código.

---

## 1. 🟡 El micro

> Un micro tiene **dos registros**, `A` y `B`, que guardan un entero cada uno, y **128 posiciones de memoria** del mismo tamaño que un registro. Un registro acepta valores **de -1023 a 1023**.

Un registro es una celda donde el procesador guarda un número con el que está trabajando ahora. La memoria es la fila de celdas donde guarda lo demás, numeradas desde 0. Eso es todo lo que tiene: faltan saltos, pila y entrada/salida. Es un juguete a propósito: el problema tiene que ser chico para que lo difícil sea **cómo se diseña la solución**, y no el dominio.

```
        ┌────────┐   ┌────────┐
        │   A    │   │   B    │        registros
        └────────┘   └────────┘
  mem   ┌────┬────┬────┬────┬────┬ ··· ┬────┐
        │  0 │  1 │  2 │  3 │  4 │     │127 │  128 posiciones
        └────┴────┴────┴────┴────┴ ··· ┴────┘
```

Tres cosas nuevas aparecen en el archivo: un par *getter*/*setter* escrito a mano (se explica debajo), `require(cond)`, que lanza `IllegalArgumentException` si `cond` es falsa y nada se asigna, y `= _`, que significa "valor por defecto del tipo" (`0` para `Int`; el guion bajo del nombre `_a` es solo una convención para distinguir la variable interna del método público). La excepción del final la usa `HALT` (sección 3). Así está en el proyecto, en `objetos/Micro.scala`:

```scala
package tadp.microprocesador.objetos

class Micro {
  private val MEM_SIZE = 128
  private val REGISTER_SIZE = 1024

  private var _a: Int = _
  private var _b: Int = _
  private var _mem: Array[Int] = new Array(MEM_SIZE)

  def a = _a
  def a_=(value: Int): Unit = {
    require(value < REGISTER_SIZE && value > -REGISTER_SIZE)
    _a = value
  }

  def b = _b
  def b_=(value: Int): Unit = {
    require(value < REGISTER_SIZE && value > -REGISTER_SIZE)
    _b = value
  }

  def mem = _mem
}

class ExecutionHaltException extends RuntimeException
```

**`def a = _a` y `def a_=(value: Int)` son un par de *getter* y *setter*.** Scala tiene una regla: si una clase define `a` y `a_=` juntos, entonces `micro.a = 42` se traduce a `micro.a_=(42)`. Desde afuera parece una asignación a un atributo; adentro corre el método, con su validación. La clase07 presentó `var`; esto es lo que un `var` genera por vos, escrito a mano para poder meter el `require` en el medio.

⚠️ **Trampa: la sintaxis de procedimiento de Scala 2.** Si ves `def a_=(value: Int) { … }`, sin `: Unit =`, es Scala 2; 3.3.1 lo rechaza con `'=' expected, but '{' found`. Acá siempre `: Unit = { … }`, y lo mismo en los `def` abstractos: `: Unit` en vez de nada.

Lo que hace, verificado (desde afuera del paquete, con el `import`):

```scala
import tadp.microprocesador.objetos.Micro

val micro = new Micro
micro.a            // Resultado: 0
micro.mem.length   // Resultado: 128
micro.mem(5)       // Resultado: 0

micro.a = 42       // corre a_=(42): pasa el require
micro.a            // Resultado: 42
micro.mem(9) = 13  // escribir la memoria: es un Array común
micro.mem(9)       // Resultado: 13

micro.a = 1023     // pasa el require
micro.a            // Resultado: 1023 (es el máximo que entra)
micro.a = 1024     // Resultado: java.lang.IllegalArgumentException: requirement failed
micro.a = -1024    // Resultado: java.lang.IllegalArgumentException: requirement failed
micro.mem(128) = 1 // Resultado: java.lang.ArrayIndexOutOfBoundsException: Index 128 out of bounds for length 128
```

⚠️ **Trampa.** El enunciado dice "entre -1024 y 1024" y el código usa `<` y `>` estrictos: 1024 y -1024 quedan afuera. En esta unidad vale el código.

> 🕳️ **Madriguera — `= _` y `uninitialized`**
> Scala 3 tiene una forma más nueva de escribir "valor por defecto": `= uninitialized` (con `import scala.compiletime.uninitialized`). `= _` sigue compilando en 3.3.1 y es lo que usa el proyecto.
> *Volvé al camino — esto se profundiza aparte, otro día.*

## 2. 🟡 Las siete instrucciones

> El lenguaje del micro tiene **siete instrucciones**. Cuatro no llevan parámetro; `LOAD` y `STORE` llevan una dirección de memoria; `IF` lleva **una lista de instrucciones adentro**.

| Instrucción | Qué hace |
|---|---|
| `ADD` | Suma los dos registros y guarda el resultado en `A` |
| `MUL` | Multiplica los dos registros y guarda el resultado en `A` |
| `SWAP` | Intercambia los valores de `A` y `B` |
| `LOAD(address)` | Carga en `A` el valor de la memoria en la posición `address` |
| `STORE(address)` | Guarda el valor de `A` en la memoria, en la posición `address` |
| `IF(sub)` | Ejecuta la lista de instrucciones `sub` **solo si `A` vale 0** |
| `HALT` | Detiene la ejecución: ninguna instrucción posterior se evalúa |

Fijate la asimetría: `ADD` y `MUL` escriben en `A`, nunca en `B`. `LOAD` también. La única forma de poner algo en `B` es un `SWAP`. Eso va a hacer que `SWAP` aparezca mucho en los programas.

**Un programa es una lista de instrucciones**, en orden. Y como `IF` lleva una lista adentro, un programa puede tener sub-programas, con la profundidad que quieras:

```
LOAD 0, SWAP, IF[ LOAD 1, IF[ ADD ], SWAP ], STORE 9
```

Este detalle importa más de lo que parece: el problema no es "ejecutar siete instrucciones" sino **recorrer una estructura** que puede anidarse. Varias de las dificultades de los módulos siguientes nacen ahí.

## 3. 🟡 Ejecutar, paso a paso

> Ejecutar un programa es **recorrer la lista** y, por cada instrucción, modificar el micro según la tabla. El micro cambia; el programa no.

Un micro con la memoria cargada así (posiciones 0 a 9; el resto en 0) y el programa `LOAD 0, SWAP, LOAD 1, ADD, STORE 9`:

```
  A = 0   B = 0
  mem: 13  39   0   0   4   8  15  16  23   0
        0   1   2   3   4   5   6   7   8   9
```

| Paso | Instrucción | Qué pasa | A | B | mem(9) |
|---|---|---|---|---|---|
| 1 | `LOAD 0` | `A` toma lo que hay en la posición 0 | **13** | 0 | 0 |
| 2 | `SWAP` | `A` y `B` se intercambian | **0** | **13** | 0 |
| 3 | `LOAD 1` | `A` toma la posición 1 | **39** | 13 | 0 |
| 4 | `ADD` | `A` = 39 + 13 | **52** | 13 | 0 |
| 5 | `STORE 9` | la posición 9 toma `A` | 52 | 13 | **52** |

Resultado: `A = 52`, `B = 13`, y la memoria queda `13, 39, 0, 0, 4, 8, 15, 16, 23, 52`. Hecho a mano sobre el `Micro` del proyecto, sale exactamente eso. Tres métodos de lista aparecen acá por primera vez: `zipWithIndex` empareja cada valor con su posición (`(13, 0)`, `(39, 1)`, …), el `foreach` recibe cada par ya desarmado en `v` e `i`, y `take(10)` corta los primeros diez.

```scala
import tadp.microprocesador.objetos.Micro

val m = new Micro
List(13, 39, 0, 0, 4, 8, 15, 16, 23, 0).zipWithIndex.foreach((v, i) => m.mem(i) = v)

m.a = m.mem(0)                       // LOAD 0
val t = m.a; m.a = m.b; m.b = t      // SWAP
m.a = m.mem(1)                       // LOAD 1
m.a = m.a + m.b                      // ADD
m.mem(9) = m.a                       // STORE 9
(m.a, m.b)                           // Resultado: (52,13)
m.mem.take(10).toList                // Resultado: List(13, 39, 0, 0, 4, 8, 15, 16, 23, 52)
```

Dos cosas del ejemplo que después vuelven. **El `SWAP` necesitó una variable temporal** (`t`): para intercambiar dos valores en el lugar hay que guardar uno aparte. Y **`ADD` puede fallar**: con `A = 1000` y `B = 1000`, `m.a = m.a + m.b` lanza `IllegalArgumentException: requirement failed`, porque 2000 se pasa del rango. El micro queda como estaba (`A = 1000`): el `require` corre antes de asignar.

**`HALT`** no modifica el micro: detiene el recorrido. En el proyecto eso se hace lanzando `ExecutionHaltException`, la clase que está al final de `Micro.scala`. La excepción sale de la ejecución y llega a quien la pidió; él decide qué hacer con ella. Es una decisión que el Módulo 9 va a cuestionar.

**`IF`** mira `A` en ese momento: si vale 0, ejecuta su lista; si no, la saltea entera. Con `A = 5`, `IF[ LOAD 0 ]` deja `A` en 5.

## 4. 🟡 Las otras dos operaciones

> Además de ejecutar, el enunciado pide **imprimir** un programa como texto y **simplificarlo** quitando instrucciones que no cambian nada. Las tres operaciones trabajan sobre la misma estructura: la lista de instrucciones.

Imprimir existe porque un programa armado en memoria es un árbol de objetos, incómodo de leer: el string es la vista para un desarrollador. **Imprimir** da un string con cada instrucción separada por coma, y los parámetros entre corchetes. Un `IF` imprime su lista adentro de los corchetes:

```
LOAD 0, SWAP, IF[ LOAD 1, IF[ ADD ], SWAP ], STORE 9   →(imprimir)   "LOD[0], SWP, IF[LOD[1], IF[ADD], SWP], STR[9]"
```

Las abreviaturas de tres letras (`LOD`, `SWP`, `STR`, `HLT`) son las que usa el código; el resto queda igual. De acá en adelante, los programas se escriben con esa notación, y `antes  →  después` muestra lo que sale de una operación.

**Simplificar** produce un programa sin las instrucciones redundantes (nuevo o modificado en el lugar, según la solución), según cinco reglas del enunciado:

| Regla | Antes | Después | Por qué |
|---|---|---|---|
| Dos `SWAP` seguidos | `SWP, SWP` | *(nada)* | Intercambiar dos veces es no hacer nada |
| Dos `LOAD` seguidos | `LOD[0], LOD[1]` | `LOD[1]` | El segundo pisa `A` sin que nadie haya leído el primero |
| Dos `STORE` seguidos **en la misma dirección** | `STR[1], STR[1]` | `STR[1]` | El segundo pisa la posición sin que nadie la haya leído |
| Un `IF` sin instrucciones adentro | `IF[]` | *(nada)* | "Si `A` es 0, no hagas nada" es no hacer nada |
| Cualquier instrucción después de un `HALT` | `HLT, ADD, SWP` | `HLT` | Nunca se ejecutarían |

Cuatro de las cinco reglas tienen algo en común: **no se deciden mirando una instrucción sola.** Hay que ver la de al lado, o la dirección de la de al lado, o todo lo que viene después de un `HALT`. Guardá eso: es lo que va a hacer que simplificar sea la operación más incómoda de resolver.

Sobre un programa con las tres redundancias juntas:

```
LOD[0], LOD[0], SWP, SWP, SWP, STR[1], STR[1]   →(simplificar)   LOD[0], SWP, STR[1]
```

Los dos `LOAD 0` quedan en uno; de los tres `SWAP`, dos se cancelan y queda uno; los dos `STORE 1` quedan en uno. Son tres aplicaciones de reglas, fáciles de ver mirando la lista "desde afuera". Guardá esa frase: **lo fácil es verlo desde afuera.** Cuánto cuesta programarlo depende de dónde pongas la lógica, y eso es exactamente lo que la unidad compara.

Un detalle sobre `HALT` y `IF`: un `HALT` dentro de un `IF` corta el resto **de ese `IF`**, no lo que viene después del `IF`, porque el `IF` podría no ejecutarse. `IF[HLT, ADD], MUL` simplifica a `IF[HLT], MUL`.

## 5. 🔴 ¿Dónde van las operaciones?

> Tres operaciones hoy; mañana pueden ser muchas más. **Dónde se pone cada operación** es la decisión de diseño que esta unidad estudia, y las cuatro soluciones del proyecto son cuatro respuestas distintas a esa pregunta.

Ejecutar, imprimir y simplificar son las tres del enunciado. Pero pensá en quién usa esto. Un lenguaje de micro se compila, se ejecuta, se publica; distintas marcas de micro podrían querer implementarlo para sus chips. Cada una va a querer sus propias operaciones: ejecutarlo en un micro con tres registros, simularlo, inspeccionarlo, depurarlo, modificarlo, tipar el programa. Las operaciones se multiplican y las instrucciones siguen siendo siete.

```
      micro de 3 registros           micro de 4 registros          micro de 2 registros
      ┌───────────────┐              ┌───────────────────┐         ┌───────────────┐
      │ A   B   C     │   (print)    │ A1  B1  A2  B2    │ (print) │ A   B         │ (print)
      │ mem           │   (simplify) │ mem               │ (run)   │ mem           │ (run)
      └───────────────┘   (run)      └───────────────────┘ (debug) └───────────────┘ (simplify)
                                                            (modify)                 (debug)
                                                            (inspect)                (type)
                                                           (simulate)
```

La respuesta refleja de objetos es: las operaciones van **adentro de las instrucciones**. Cada instrucción sabe ejecutarse, imprimirse, simplificarse. La interfaz quedaría así:

```
   ┌ - - - - - - - - - - ┐
   ¦     Instrucción     ¦
   ├ - - - - - - - - - - ┤
   ¦  run(micro)         ¦
   ¦  print()            ¦
   ¦  simplify()         ¦
   ¦  ...                ¦
   ¦  +500               ¦
   └ - - - - - △ - - - - ┘
               ¦
    ┌ - - - - -┼ - - - - -┐
 ┌──────┐  ┌───────┐  ┌──────┐
 │ Load │  │ Store │  │ Swap │   ...
 └──────┘  └───────┘  └──────┘
```

(Las cajas punteadas son interfaces o `trait`; las sólidas, clases concretas. Así en toda la unidad.)

Y acá aparece el problema. Cada operación nueva es un método más en la interfaz, y **hay que agregarlo en cada una de las siete clases**. Con quinientas operaciones, la interfaz de `Instrucción` es un monstruo. Peor: si el lenguaje lo publicás vos y las marcas de micro son otras empresas, cada una tendría que mandarte un pedido de cambio a tu código (un *pull request*) para agregar *su* operación, esperar que lo aceptes, y pelearse con las demás por los nombres (si una llamó `print` a su impresión, la siguiente ya no puede). Y cada vez que una toca su método, puede romper el código de las otras, porque todas viven en la misma interfaz. Las operaciones cambian a un ritmo, las instrucciones a otro, y meter las dos cosas en el mismo lugar las ata.

Ese diagrama, tachado con una cruz, es el punto de partida. La primera solución del proyecto hace exactamente eso, para ver el costo; las otras tres son tres formas de no hacerlo:

| Solución | Dónde van las operaciones | Módulo |
|---|---|---|
| Objetos sin Visitor (`puro`) | Adentro de las instrucciones (el diagrama de arriba, tal cual) | M2 |
| Visitor | Afuera, en objetos "visitantes"; las instrucciones solo saben aceptarlos | M5 |
| Pattern matching, micro mutable | Afuera, como funciones que miran la forma de cada instrucción | M7 |
| Pattern matching, micro inmutable | Igual, y además ejecutar no modifica nada: devuelve un micro nuevo | M8, M9 |

**Para el parcial, si te preguntan:** *"¿Qué tiene de particular el dominio del simulador de micros?"* Que las instrucciones del lenguaje son **datos**: un programa es una estructura (una lista, con `IF` que anida otra lista), y las operaciones (ejecutar, imprimir, simplificar) recorren esa estructura. Hay pocas estructuras y estables, y muchas operaciones que pueden crecer. Esa asimetría es la que decide dónde conviene poner cada cosa.

---

## Checkpoint

1. ¿Qué guarda un registro y qué guarda la memoria? ¿Cuántos de cada uno tiene el micro?
2. ¿Por qué `SWAP` es la única forma de poner un valor en `B`?
3. Con `A = 7`, `B = 2` y `mem(3) = 0`: ¿en qué queda el micro después de `STORE 3, LOAD 3, IF[ SWAP ], MUL`?
4. ¿Qué pasa si `ADD` da 2000? ¿En qué estado queda el micro?
5. ¿Por qué el `SWAP` necesitó una variable temporal al hacerlo a mano?
6. ¿Cómo se detiene la ejecución con `HALT` en el proyecto, y qué le pasa al que llamó a ejecutar?
7. Simplificá a mano: `SWP, SWP, SWP, LOD[2], LOD[2], IF[SWP, SWP], STR[0], HLT, ADD`.
8. ¿Por qué un `HALT` dentro de un `IF` no elimina lo que viene después del `IF`?
9. ¿En qué dirección crece más este dominio: en instrucciones o en operaciones? ¿Qué problema trae ponerlas en la misma interfaz?
10. ¿Qué pasaría, con las operaciones adentro de las instrucciones, si dos empresas distintas quisieran agregar cada una su operación `print`?

## Qué viene después

**Módulo 2:** la primera solución, con las operaciones adentro de las instrucciones, y sobre ella la revisión de dos de las tres ideas de objetos: qué dan de verdad el encapsulamiento y la delegación, y dónde empiezan a hacer agua.

**FIN DEL MÓDULO 1 — El problema: un micro y sus operaciones**
