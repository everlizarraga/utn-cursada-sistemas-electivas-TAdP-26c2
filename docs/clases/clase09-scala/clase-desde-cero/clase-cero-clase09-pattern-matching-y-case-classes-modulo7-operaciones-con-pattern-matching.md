# Clase desde cero — Pattern matching, case classes y el híbrido objeto-funcional — Módulo 7: Las tres operaciones con pattern matching

**Unidad:** clase09 · **Lenguaje:** Scala 3.3.1 · **Archivos del proyecto:** `mutable/Operations.scala` (y `mutable/Micro.scala`, el mismo micro de la solución de objetos) · **Densidad:** 🔴 una sesión, con el Módulo 5 abierto al lado

---

## Sobre este documento

**Qué cubre.** Ejecutar, imprimir y simplificar, escritas como funciones que miran la forma de las instrucciones con `match`, y comparadas una por una con sus visitantes del Módulo 5. Lo que se ganó, lo que se pagó, y el **criterio** del híbrido objeto-funcional: cuándo polimorfismo y cuándo pattern matching. Es lo que se evalúa.

**Qué no cubre.** Sacarle el efecto a `run`: el micro sigue siendo mutable en este módulo, y el Módulo 8 lo cambia.

## De dónde venís

Del Módulo 3: cada herramienta crece fácil en una dirección. Del Módulo 5: `RunVisitor` con su bandera, `PrintVisitor` armando texto a pedazos y `SimplifyVisitor` con su pila y cinco variables; el recorrido lo controlaba la estructura. Del Módulo 6: `case class`, `match`, los patrones (constante, constructor, tipo, lista, comodín, guarda) y `sealed`. De la clase07 y la clase08: `map` y las funciones anónimas.

---

## 1. 🟡 Las operaciones viven afuera, en un solo archivo

> Las tres operaciones son **funciones sueltas** agrupadas bajo un nombre, `Operations`. Reciben un programa (una `List[Instruction]`) y deciden qué hacer mirando la forma de cada instrucción.

Tres piezas de Scala que aparecen al abrir el archivo:

- `package object Operations { … }` agrupa funciones sueltas bajo un nombre. Se usan como `Operations.run(…)`, `Operations.print(…)`.
- `type Program = List[Instruction]` es un **alias de tipo**: un nombre corto para un tipo que ya existe. `Program` y `List[Instruction]` son el mismo tipo; el alias solo hace que las firmas se lean mejor.
- `ExecutionHaltException` vive acá adentro, junto con la operación que la lanza.

```scala
package tadp.microprocesador.mutable

package object Operations {

  type Program = List[Instruction]
  class ExecutionHaltException extends RuntimeException

  // run, print y simplify, en las secciones que siguen
}
```

Compará con el Módulo 5: allá había un `Program` con `accept`, siete instrucciones con `accept` cada una, un trait de visitante con ocho métodos abstractos y tres visitantes. Acá, siete líneas de instrucciones (Módulo 6) y un archivo con tres funciones.

## 2. 🔴 `run`: el flujo lo controla la operación

> `run` recorre el programa y, para cada instrucción, hace un `match`. En el `If`, **la operación decide si entra**: si A es 0, se llama a sí misma con las subinstrucciones; si no, sigue. Nadie le va a mandar las subinstrucciones si ella no quiere.

```scala
def run(program: Program, micro: Micro): Unit = {
  for (instruction <- program)
    instruction match {
      case Add => micro.a = micro.a + micro.b
      case Mul => micro.a = micro.a * micro.b
      case Swap =>
        val temp = micro.a
        micro.a = micro.b
        micro.b = temp
      case Load(address)       => micro.a = micro.mem(address)
      case Store(address)      => micro.mem(address) = micro.a
      case If(subInstructions) => if (micro.a == 0) run(subInstructions, micro)
      case Halt                => throw new ExecutionHaltException
    }
}
```

Es la misma lógica que estaba escondida adentro de `RunVisitor`, rama por rama: sumar, multiplicar, el swap con temporal, leer y escribir memoria, cortar con una excepción. Lo que cambió está en dos lugares.

**El `If`.** Era el caso más difícil del visitante: una bandera, un `visitInstruction` redefinido, un `endVisitIf` que la apagaba, y una corrección que dependía de cómo recorría la estructura. Acá es una línea: `if (micro.a == 0) run(subInstructions, micro)`. Si la condición falla, nadie visita las subinstrucciones. Prepararse para avisos futuros deja de hacer falta: el que recorre es `run`.

**El acceso a cada instrucción.** En cada rama se sabe de qué tipo es la instrucción y se tiene su contenido: `Load(address)` entrega la dirección, sin castear. Y cada rama tiene sus propias variables: el `temp` del `Swap` vive solo ahí, sin el scope compartido del `switch`.

```scala
import tadp.microprocesador.mutable._

val micro = new Micro
micro.mem(0) = 7
micro.a = 5
Operations.run(List(If(List(Load(0)))), micro)
micro.a   // Resultado: 5
```

El mismo caso del Módulo 5: con A = 5 el `If` se saltea. Los `If` anidados salen solos, por recursión:

```
IF[LOD[0], IF[STR[1]], STR[2]] con mem(0) = 7 y A = 0  →  mem(1) = 0, mem(2) = 7
IF[IF[STR[1]], STR[2]], STR[3] con A = 4               →  mem(1) = 0, mem(2) = 0, mem(3) = 4
```

Cada `run` maneja su propia lista; la bandera y el razonamiento sobre el recorrido desaparecen.

**Un costo real.** Con el Visitor, el recorrido se escribía una sola vez, en las instrucciones. Acá, cada operación que necesite entrar a un `If` lo hace por su cuenta. Es una objeción válida, y tiene su contrapunto: cada operación recorre de una forma distinta (ejecutar entra solo si A es 0, imprimir entra siempre, simplificar mira de a pares). En la práctica molesta mucho más pelearse con un recorrido que eligió otro que escribir el propio más de una vez.

**Lo que sigue igual.** `run` modifica el micro que recibe, y el swap necesita una variable temporal. Los dos quedan para el Módulo 8.

## 3. 🟡 `print`: un `map` y un `mkString`

> Imprimir es **transformar** cada instrucción en su texto y unir los textos con comas: no guarda estado ni recibe micro.

Una cosa nueva (`mkString` es el del Módulo 2: une los elementos de la lista con `", "` entre cada uno):

- `program.map { case … => … }`: una función anónima escrita **directamente como casos**. Es lo mismo que `program.map(i => i match { case … })`, más corto. `map` aplica esa función a cada instrucción y devuelve la lista de resultados.

```scala
def print(program: Program): String = program.map {
  case Add                 => "ADD"
  case Mul                 => "MUL"
  case Swap                => "SWP"
  case Load(address)       => s"LOD[$address]"
  case Store(address)      => s"STR[$address]"
  case If(subInstructions) => s"IF[${print(subInstructions)}]"
  case Halt                => "HLT"
}.mkString(", ")
```

```scala
Operations.print(List(Swap, If(List(Load(2), If(List(Add))))))   // Resultado: SWP, IF[LOD[2], IF[ADD]]
Operations.print(List(Add, If(Nil), Halt))                       // Resultado: ADD, IF[], HLT
```

Compará con `PrintVisitor`:

- **El texto.** Allá, un atributo que se modificaba a cada aviso. Acá, una lista de strings que `map` arma y `mkString` une.
- **El separador.** Allá, `addText` tenía que adivinar si poner coma, y la versión ingenua ponía una de más después de `IF[`. Acá la coma la pone `mkString` entre elementos, y el `If` imprime lo suyo llamando a `print` sobre su lista, que vuelve con sus propias comas. El error de la coma es imposible de cometer.
- **El micro.** Imprimir nunca dependió del micro (`PrintVisitor`, Módulo 5); `print` recibe un programa y nada más.

`map` y `mkString` ya venían con las listas. La operación solo dice qué es cada instrucción en texto.

## 4. 🔴 `simplify`: matchear sobre la lista entera

> Simplificar mira **la forma de la lista**, no de una instrucción: "¿empieza con dos `SWAP`?", "¿empieza con dos `STORE` a la misma dirección?". Cada regla del Módulo 1 es un patrón, y todo entra en una pantalla.

```scala
def simplify(program: Program): Program = program match {
  case Nil => Nil
  case Swap :: Swap :: otherInstructions => simplify(otherInstructions)
  case Load(_) :: (load: Load) :: otherInstructions => simplify(load :: otherInstructions)
  case (s1: Store) :: (s2: Store) :: otherInstructions if s1.address == s2.address => simplify(s2 :: otherInstructions)
  case If(subInstructions) :: otherInstructions =>
    val simplifiedSubInstructions = simplify(subInstructions)
    if (simplifiedSubInstructions.isEmpty) simplify(otherInstructions) else If(simplifiedSubInstructions) :: simplify(otherInstructions)
  case Halt :: _ => Halt :: Nil
  case i :: is   => i :: simplify(is)
}
```

Caso por caso:

| Patrón | Regla | Qué devuelve |
|---|---|---|
| `Nil` | Un programa vacío ya está simplificado | `Nil` |
| `Swap :: Swap :: otherInstructions` | Dos `SWAP` seguidos se cancelan | El resto, simplificado |
| `Load(_) :: (load: Load) :: otherInstructions` | De dos `LOAD` seguidos, el primero sobra | El segundo `LOAD` seguido del resto, simplificado. La dirección del primero no interesa (`_`); al segundo se lo nombra `load` para volver a ponerlo |
| `(s1: Store) :: (s2: Store) :: … if s1.address == s2.address` | De dos `STORE` seguidos a la misma dirección, el primero sobra | El segundo seguido del resto. La guarda hace que dos `STORE` a direcciones distintas sigan de largo |
| `If(subInstructions) :: otherInstructions` | Un `If` se simplifica por dentro; si queda vacío, desaparece | El resto, con o sin el `If` simplificado adelante |
| `Halt :: _` | Lo que viene después de un `HALT` nunca se ejecuta | Solo `Halt` |
| `i :: is` | Cualquier otra cosa queda como está | La instrucción, seguida del resto simplificado |

Fijate en el `Load(_) :: (load: Load)`: son dos formas de decir "un `Load`". La primera mira el constructor y descarta la dirección; la segunda da un nombre a la instrucción entera, con su tipo. Y el orden importa: `i :: is` va último porque encaja con cualquier lista no vacía.

```scala
Operations.print(Operations.simplify(List(Add, Load(0), Load(1), Swap, Swap, Store(2), Store(2), Mul)))
// Resultado: ADD, LOD[1], STR[2], MUL
```

```
SWP, SWP, SWP          →  SWP
ADD, HLT, MUL, SWP     →  ADD, HLT
IF[SWP, SWP], ADD      →  ADD
IF[HLT, ADD], MUL      →  IF[HLT], MUL
STR[1], STR[2]         →  STR[1], STR[2]
```

Los mismos resultados que el `SimplifyVisitor`. Comparalos:

- **El estado.** Allá: una pila de listas, cuatro banderas y la última dirección escrita. Acá: ninguno. La pila de `If` anidados la resuelve la recursión: `simplify(subInstructions)` simplifica el `If` de adentro como un programa más.
- **Mirar de a pares.** El visitante recibía un `SWAP` por aviso y tenía que recordar si el anterior también lo era. Acá el patrón `Swap :: Swap :: …` mira los dos a la vez. Un tercer `SWAP` sigue de largo: solo se cancela si tiene otro `SWAP` al lado.
- **Leerlo.** Cada regla del enunciado es un caso. Lo que no se simplifica, el último caso lo deja pasar, sin banderas que apagar en `visitAdd`.

> 🕳️ **Madriguera — simplificar de una pasada**
> `simplify` recorre la lista una vez. Si al sacar dos `SWAP` quedan juntos dos `LOAD`, esos quedan: `LOD[0], SWP, SWP, LOD[1]` sale `LOD[0], LOD[1]`. El `SimplifyVisitor` y la solución `puro` (Módulo 2) hacen lo mismo. ¿Cómo lo resolverías?
> *Volvé al camino — esto se profundiza aparte, otro día.*

## 5. 🔴 Lado a lado con el Visitor

> Pattern matching da **las mismas ventajas que el Visitor** (operaciones nuevas sin tocar las instrucciones), con menos burocracia y con el recorrido en manos de la operación.

| | Visitor (Módulo 5) | Pattern matching |
|---|---|---|
| Instrucciones | Clases con `accept`, más `Program` | Siete `case`, sin operaciones |
| Agregar una operación | Un visitante nuevo con ocho métodos | Una función nueva |
| Quién recorre | La estructura; el visitante recibe avisos | La operación |
| Ejecutar un `If` | Bandera + `visitInstruction` redefinido + `endVisitIf` | `if (micro.a == 0) run(subInstructions, micro)` |
| Imprimir | Texto que se arma a pedazos; separador que adivina | `map` + `mkString` |
| Simplificar | Pila + cinco variables | Un patrón por regla |
| Casteos | Ninguno, a costa del doble despacho | Ninguno, por los patrones de constructor y de tipo |
| Leer y depurar una operación | Saltar del visitante a la instrucción en cada paso | Todo en una función, en una pantalla |
| Agregar una instrucción | Un `visit` más en el trait y en cada visitante, de cada cliente | Un caso más en cada operación |

A un `match` se le pueden cuestionar cosas; la legibilidad no es una de ellas.

Y siguen siendo objetos. Las instrucciones son objetos; el micro también. Se puede elegir delegar en ellos, o partir `run` en funciones más chicas (una para la suma, otra para la multiplicación). Lo que cambió es que ya no estás obligado a cortar cada operación al nivel de cada elemento, como imponía el Visitor. Eso da una granularidad más fina: el código queda junto cuando conviene, y se parte cuando conviene.

**Agregar una instrucción sigue costando.** Es la columna roja del Módulo 3: hay que ir a `run`, a `print` y a `simplify` y entender cada una para agregar el caso, cuidando que la instrucción nueva no rompa nada en otro lugar. La diferencia es que las herramientas acompañan: con `sealed`, `run` y `print` quedan marcadas con un aviso de `match` incompleto (Módulo 6). `simplify` termina en `i :: is`, que encaja con todo, así que ahí la instrucción nueva pasa sin aviso, y hay que revisar a mano si alguna regla tiene que contemplarla. La clase siguiente trae herramientas que lo mitigan todavía más.

Hacé la prueba: te piden una regla más de simplificación, cualquiera. Te dan los dos códigos, el visitante y el `simplify`, y nada más. ¿Cuál preferís extender? Con los dos códigos delante, la elección es fácil: no hay razón para preferir el Visitor teniendo esto. Con el Visitor tenés los mismos problemas que tendrías con funcional, tapados por una capa de complejidad accidental.

**Con qué compararlo de verdad.** Contra el Visitor, pattern matching gana casi sin discusión. La comparación interesante es contra la solución `puro` del Módulo 2: abierta la puerta a esta herramienta, `run` se podría escribir delegando en cada instrucción (`beExecutedBy`) o desde afuera con `match`. Con las condiciones de este problema (no ensuciar la interfaz de las instrucciones, porque distintas marcas le agregan lógica desde afuera), conviene `match`. Las quinientas operaciones del Módulo 1 serían quinientas funciones afuera de las instrucciones: cada marca escribe las suyas, sin *pull requests* ni burocracia. En un dominio sin esas condiciones, la respuesta puede ser otra, y eso es lo que hay que aprender a decidir.

## 6. 🔴 Lo que se pagó

> Pattern matching **rompe objetos puros**. El precio es que ahora hay una decisión más en cada diseño: polimorfismo o pattern matching, y se puede tomar mal.

Nada es gratis. Para tener este código:

- **Se rompió una regla de objetos.** "Siempre polimorfismo" dejó de ser cierto (Módulo 4, sección 2: alguna regla tenía que pasar de "siempre" a "en estas circunstancias").
- **Un programador puede elegir mal.** Antes no había nada que decidir: polimorfismo. Ahora hay dos herramientas, y se puede usar pattern matching donde convenía delegar.
- **Las operaciones sueltas abren una puerta.** Si una operación puede vivir afuera de todo objeto, también se pueden escribir *data objects* donde convenía un objeto rico.

El costo de fondo es entender cómo se usa cada herramienta, comunicar la nueva forma de trabajar al equipo, y tomar decisiones donde antes no había ninguna. A cambio, se gana un código difícil de superar con un Visitor en cualquier aspecto.

## 7. 🔴 El criterio híbrido

> **¿Esperás que aparezcan estructuras nuevas, con operaciones estables? Polimorfismo. ¿Esperás que aparezcan operaciones nuevas, sobre estructuras estables (o operaciones que no tienen un responsable claro)? Pattern matching.** En objetos puros, "siempre polimorfismo" estaba bien; en un híbrido, hay que elegir.

Es la tabla del Módulo 3 convertida en regla de diseño. Polimorfismo hace fácil agregar estructuras; pattern matching, agregar operaciones. Elegí según el cambio más probable.

**Ya lo sabías detectar.** La parte más difícil de un criterio es reconocer cuándo aplica. Y eso ya lo tenías: era la situación que pedía un Visitor (Módulo 5, sección 2), estructura estable y operaciones que crecen. Si estás en objetos y querés un Visitor, en realidad querés funcional. El paradigma híbrido dice: usá funcional, usá pattern matching.

**Si estás en objetos puros.** Lo más parecido a pattern matching es un `switch` o un Visitor, y te toca elegir entre los dos. Pero hay una pregunta anterior: ¿te conviene estar en objetos puros? Los lenguajes mismos dejaron de intentarlo. Hoy cuesta encontrar uno que diga "soy de objetos" y nada más; todos quieren ser de todos los paradigmas, con distintos grados de éxito, y te dan pattern matching.

**Terreno nuevo.** Esto también es diseño, pero en otro paradigma. Si cursaste Diseño de Sistemas, te enseñaron diseño de objetos, y el diseño de objetos te aleja activamente de cualquier idea funcional; el diseño funcional, de cualquier idea de objetos. El híbrido es un terreno nuevo: aparecen criterios nuevos, patrones nuevos, maneras nuevas de trabajar, y hay que explorar qué aporta cada variante. Es lo que la materia va a ir armando de acá en adelante, y lo que el TP grupal en Scala te va a pedir: elegir herramientas y saber por qué. Entender el concepto es una cosa; elegir bien cuándo usarlo, otra.

**Para el parcial, si te preguntan:** *"Te piden contar cuántos accesos a memoria hace un programa del micro. ¿Polimorfismo o pattern matching? ¿Por qué?"* Pattern matching. Es una operación nueva sobre instrucciones estables: con pattern matching es una función nueva que mira la forma de cada instrucción (`Load` y `Store` cuentan, el resto no, y el `If` cuenta lo suyo), sin tocar las instrucciones ni las otras operaciones. Con polimorfismo habría que agregar un método en cada instrucción y, en este dominio, ensuciar su interfaz con la lógica de cada marca de micro. Si lo esperable fueran instrucciones nuevas con operaciones fijas, convendría polimorfismo.

**Para el parcial, si te preguntan:** *"¿Qué ventajas tiene pattern matching sobre el Visitor?"* Las mismas ventajas de extensión (operaciones nuevas sin tocar la estructura), con menos burocracia y con la operación decidiendo cómo recorrer, así que le alcanza con su propio código para saltear o recordar (el `If` de `run`, el par de `SWAP` de `simplify`). El código de cada operación queda junto, y el compilador avisa los casos que faltan si el tipo es `sealed`.

---

## Checkpoint

1. ¿Qué es `type Program = List[Instruction]`? ¿Qué cambia si lo sacás?
2. ¿Cómo resuelve `run` el `If`? ¿Qué tres piezas del `RunVisitor` reemplaza esa línea?
3. ¿Qué objeción válida tiene que cada operación haga su propio recorrido? ¿Cuál es el contrapunto?
4. ¿Qué es `program.map { case … }`? ¿Por qué `print` no puede equivocarse con la coma?
5. Para cada caso de `simplify`, decí qué regla del enunciado implementa.
6. ¿Por qué `i :: is` va último? ¿Qué pasaría si fuera primero?
7. ¿Qué reemplaza a la pila del `SimplifyVisitor`? ¿Y a las cuatro banderas?
8. Aparece una octava instrucción. ¿Qué operaciones te marca el compilador y cuál no? ¿Por qué? ¿Qué tenés que revisar a mano?
9. ¿Contra qué solución conviene comparar pattern matching, si no es contra el Visitor? ¿Qué condición del problema inclina la balanza?
10. Enumerá lo que se pagó por usar pattern matching.
11. Enunciá el criterio híbrido. ¿Qué tiene que ver con el Visitor?

## Qué viene después

**Módulo 8:** `run` sigue modificando el micro que recibe, y eso tiene consecuencias (no se puede volver un paso atrás, el swap necesita una temporal). El Módulo 8 trae la pureza del triángulo rojo: un micro inmutable, y un `run` que devuelve un micro nuevo.

**FIN DEL MÓDULO 7 — Las tres operaciones con pattern matching**
