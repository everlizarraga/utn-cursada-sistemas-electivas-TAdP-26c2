# Clase desde cero — Pattern matching, case classes y el híbrido objeto-funcional — Módulo 5: El Visitor, o cómo objetos se rinde

**Unidad:** clase09 · **Lenguaje:** Scala 3.3.1 · **Archivos del proyecto:** `objetos/visitor/Instructions.scala`, `objetos/visitor/Visitors.scala` · **Densidad:** 🔴 la sesión más larga de la unidad, con el código abierto

---

## Sobre este documento

**Qué cubre.** Lo que hace objetos cuando el dominio crece en operaciones: el patrón **Visitor**. Para qué situación se propone, cómo está armado (elementos, visitantes, doble despacho), y el código real del micro recorrido visitante por visitante: imprimir, ejecutar y simplificar. Después, lo que el propio libro del patrón admite sobre él, y por qué todo el esfuerzo termina simulando el triángulo rojo por el camino más difícil.

**Qué no cubre.** La alternativa con pattern matching: el Módulo 6 presenta la herramienta y el Módulo 7 reescribe las tres operaciones con ella, al lado de estas.

## De dónde venís

Del Módulo 1: el micro, las siete instrucciones, el programa como lista y el `If` con otro programa adentro; las tres operaciones (ejecutar, imprimir, simplificar) y la pregunta "¿y si mañana son quinientas?", con cada marca de micro haciéndote *pull requests*. Del Módulo 2: el doble despacho de los tanques y la solución `puro`, con la interfaz que crece. Del Módulo 3: polimorfismo contra type check, y cada uno crece fácil en una dirección. Del Módulo 4: los dos triángulos. De la clase07: el casteo (`asInstanceOf`) y por qué apaga el chequeo de tipos.

---

## 1. 🟡 Objetos no es tonto: los patrones de diseño

> Un **patrón de diseño** es una solución conocida a un problema recurrente, **con la situación que lo produce y las consecuencias de aplicarlo**. Lo valioso es reconocer la situación y saber qué se gana y qué se pierde; el diagrama de cajitas es lo de menos.

Objetos sabe que crecer en operaciones le cuesta (Módulo 3), y su comunidad buscó una salida. La encontró en el libro *Design Patterns* (Gamma, Helm, Johnson y Vlissides, conocidos como "la banda de los cuatro"), una de las bibliografías más valoradas de objetos.

Un patrón nace de experiencia acumulada: gente que sostuvo una tecnología el tiempo suficiente para ver las consecuencias de sus decisiones, y las cruzó con otros. De ahí sale una descripción con tres partes: la situación en que aparece el problema, la solución que se aplicó y qué consecuencias tuvo. Un catálogo de patrones funciona como esos artículos académicos que resumen todo lo publicado sobre un tema: una guía de lectura armada con la experiencia de muchos. Un patrón rara vez es gratis, y por eso importa reconocer cuándo aplica.

Dos cosas más sobre los patrones. Algunos envejecieron mal, porque las tecnologías cambiaron. Y un patrón también delata una falla: si hay que reescribir el mismo código cada vez que aparece un problema, el lenguaje carece de una forma mejor de expresarlo. Por eso varios patrones terminaron absorbidos por los lenguajes, como parte de su sintaxis. Este módulo es un caso de esos.

El patrón de este módulo es el **Visitor**, y tiene algo particular: camufla una rendición de objetos.

## 2. 🔴 La situación: estructura estable, operaciones que cambian más rápido

> El Visitor se propone cuando hay una **estructura compleja y estable** sobre la que se hacen **muchas operaciones distintas**, y se quiere **evitar poner esas operaciones en las clases de la estructura**.

**Una estructura que vale por sí misma.** No se trata de una clase suelta. Es una estructura donde cada combinación de piezas significa algo distinto, valiosa por sí misma, que amerita analizarse una y otra vez. Un programa del micro es eso: una lista de instrucciones, con `If` que contienen otros programas. Por eso el Visitor suele combinarse con patrones estructurales como *Composite* (el que arma objetos compuestos de otros objetos del mismo tipo).

**No podés o no querés tocarla.** El caso más fácil de imaginar: estás publicando una librería que otra gente usa. Es la situación del Módulo 1, sección 5: vos publicás el lenguaje, cada marca de micro quiere sus operaciones, y si van en las clases del lenguaje cada marca te manda *pull requests*, se pelean por los nombres y se rompen entre sí.

Lo que el libro plantea es una situación donde **la lógica cambia a otra velocidad que la estructura**. Las instrucciones son siete y van a seguir siendo siete; las operaciones se multiplican. Es la columna roja de la tabla del Módulo 3.

Y fijate cómo suena el pedido: "no quiero acoplar la lógica a los datos". Eso debería hacerte ruido. Acoplar la lógica a los datos es la definición de objetos. El patrón arranca pidiendo exactamente lo que objetos dice que hay que evitar.

## 3. 🔴 La forma del patrón: elementos, visitantes y doble despacho

> El Visitor separa dos jerarquías. Los **elementos** representan la estructura y exponen una interfaz mínima: `accept(visitor)`. Los **visitantes** representan, cada uno, **una operación**, con un método `visit` por cada tipo de elemento.

```
  ┌ - - - - - - - - - - - - - ┐                 ┌ - - - - - - - - - ┐
  ¦     InstructionVisitor    ¦                 ¦    Instruction    ¦
  ├ - - - - - - - - - - - - - ┤                 ├ - - - - - - - - - ┤
  ¦ visitLoad(i: Load)        ¦ ◄- - - - - - - -¦ accept(visitor)   ¦
  ¦ visitStore(i: Store)      ¦                 └ - - - - △ - - - - ┘
  ¦ visitIf(i: If)            ¦                           ¦
  ¦ ...                       ¦               ┌ - - - - - ┼ - - - - - ┐
  └ - - - - - - △ - - - - - - ┘            ┌──────┐   ┌───────┐   ┌──────┐
                ¦                          │ Load │   │ Store │   │  If  │  ...
     ┌ - - - - -┼ - - - - - - ┐            └──────┘   └───────┘   └──────┘
  ┌─────┐   ┌───────┐   ┌──────────┐
  │ Run │   │ Print │   │ Simplify │  ...
  └─────┘   └───────┘   └──────────┘
```

La flecha punteada va de `accept` al visitante: aceptar es llamar al visitante.

A la izquierda, las operaciones: un visitante para ejecutar, uno para imprimir, uno para simplificar, y lugar para los que vengan. A la derecha, la estructura: una clase por instrucción. Cada visitante concreto implementa **todos** los `visit`: sabe cómo se hace su operación para cada tipo de instrucción.

**Cómo se conectan.** Cada elemento implementa `accept` de la misma forma: le dice al visitante "visitame como lo que soy" y se pasa a sí mismo.

```scala
class Load(val address: Int) extends Instruction {
  def accept(visitor: InstructionVisitor) = visitor.visitLoad(this)
}
```

**Doble despacho.** Un mensaje común de objetos es **despacho simple**: el método que se ejecuta depende del nombre del mensaje y del tipo del receptor. En el Visitor, el código que se ejecuta depende de **dos** tipos: el del elemento y el del visitante.

1. Le mandás `accept(unVisitante)` a una instrucción cuyo tipo concreto desconocés. El polimorfismo elige el `accept` de esa clase: el tipo del elemento queda "recuperado".
2. Ese `accept` le manda `visitLoad(this)` al visitante. El polimorfismo elige el `visitLoad` de ese visitante: ahora se sabe qué operación y sobre qué elemento.

Es el doble despacho de los tanques del Módulo 2: una construcción recurrente, no un patrón; el Visitor lo usa como pieza.

**Recuperar el tipo sin castear.** Sin el Visitor, la operación recibe una `Instruction`, pregunta "¿sos un `Load`?" con `isInstanceOf` y después tiene que castear con `asInstanceOf` para poder leerle la dirección. El Visitor es la técnica clásica para recuperar esa información de tipo perdida **sin castear**: `visitLoad` recibe directamente un `Load`.

**Por qué `accept` se repite en cada clase.** Las siete implementaciones de `accept` son iguales: "visitame". ¿Por qué no escribirla una vez en `Instruction` y heredarla? Porque adentro de `Instruction`, `this` tiene tipo `Instruction`, y el visitante necesita el tipo concreto para elegir método. Si los métodos se llamaran todos `visit` (sobrecargados, con el mismo nombre y distinto tipo de parámetro), el compilador lo dice así:

```scala
package acc

trait Visitante {
  def visit(i: Load): Unit
  def visit(i: Store): Unit
}
trait Instruccion {
  def accept(v: Visitante): Unit = v.visit(this)
}
class Load extends Instruccion
class Store extends Instruccion
// ❌ None of the overloaded alternatives of method visit in trait Visitante with types
//  (i: acc.Store): Unit
//  (i: acc.Load): Unit
// match arguments ((Instruccion.this : acc.Instruccion))
```

Por eso el `accept` va en cada clase: es la única forma de que `this` tenga el tipo concreto. En el micro, además, los métodos tienen nombres distintos (`visitLoad`, `visitStore`), así que ni siquiera habría un único método al que llamar desde arriba.

**Las condiciones.** Para que el patrón sirva, la jerarquía de elementos tiene que ser **bastante estable**, y su interfaz pública tiene que alcanzar para que los visitantes hagan su trabajo. Si alguna de las dos falla, el Visitor es mala idea. Y el acoplamiento es asimétrico: los elementos dependen solo del visitante base, pero cada visitante depende de cada elemento. Por eso un elemento nuevo obliga a tocar todos los visitantes.

**La objeción conocida.** Hay una objeción reconocida al Visitor: es una **regresión a la descomposición funcional**, separar los algoritmos de las estructuras de datos. Quienes lo defienden contestan que, mejor que eso, el patrón convierte las operaciones en objetos con todas las de la ley. Este módulo va a darle la razón a la objeción.

## 4. 🔴 Las instrucciones: solo saben aceptar

> En el Visitor, la estructura tiene un contrato **trivial y congelado**: aceptar visitantes. Toda la lógica de las operaciones vive afuera, y por eso se puede extender sin tocar la estructura.

El archivo completo de las instrucciones (`objetos/visitor/Instructions.scala`), ya en sintaxis de Scala 3 (la trampa del Módulo 1, sección 1: `: Unit =` donde Scala 2 permitía omitirlo). Antes, dos cosas de Scala:

- `collection.Seq[Instruction]` es una secuencia de instrucciones que acepta tanto listas inmutables como mutables; el simplificador va a necesitar pasarle una mutable.
- Las instrucciones sin parámetros (`Add`, `Mul`, `Swap`, `Halt`) son `object`: hay una sola de cada una. Las que llevan una dirección (`Load`, `Store`) o un subprograma (`If`) son clases.

```scala
package tadp.microprocesador.objetos.visitor

class Program(private var instructions: collection.Seq[Instruction]) {
  def instructionCount = instructions.size

  def accept(visitor: InstructionVisitor): Unit = {
    for (instruction <- instructions)
      visitor.visitInstruction(instruction)
  }
}

trait Instruction {
  def accept(visitor: InstructionVisitor): Unit
}

object Add extends Instruction {
  def accept(visitor: InstructionVisitor) = visitor.visitAdd(this)
}

object Mul extends Instruction {
  def accept(visitor: InstructionVisitor) = visitor.visitMul(this)
}

object Swap extends Instruction {
  def accept(visitor: InstructionVisitor) = visitor.visitSwap(this)
}

class Load(val address: Int) extends Instruction {
  def accept(visitor: InstructionVisitor) = visitor.visitLoad(this)
}

class Store(val address: Int) extends Instruction {
  def accept(visitor: InstructionVisitor) = visitor.visitStore(this)
}

class If(subInstructions: Program) extends Instruction {
  def accept(visitor: InstructionVisitor): Unit = {
    visitor.visitIf(this)
    subInstructions.accept(visitor)
    visitor.endVisitIf(this)
  }
}

object Halt extends Instruction {
  def accept(visitor: InstructionVisitor) = visitor.visitHalt(this)
}
```

Casi todo es burocracia: siete veces "visitame como lo que soy". `Program` no es una instrucción, pero usa el mismo nombre, `accept`, por uniformidad: le pasa el visitante a cada instrucción, en orden.

La única instrucción con algo más es el `If`, porque contiene otro programa. Manda **tres** mensajes: "entraste a un `If`" (`visitIf`), después hace que su subprograma acepte al visitante (cada subinstrucción recibe su visita), y al final "saliste del `If`" (`endVisitIf`). Cuando algo está compuesto de otros elementos, es común tener un mensaje para entrar y otro para salir.

**La gracia.** Este contrato queda fijo: es lo que la librería publica. Cada marca de micro crea la subclase de visitante que quiera, se la queda, y usa toda la estructura sin tocarla. Para agregar una operación alcanza con una subclase: se terminan los *pull requests* del Módulo 1, y con quinientas operaciones la interfaz de `Instruction` sigue teniendo un solo método. Para que eso funcione, el contrato tiene que ser muy genérico, y lo es: aceptar. Si el contrato pidiera algo específico de una operación, habría que tocarlo con cada operación nueva, y no serviría.

## 5. 🔴 El contrato de los visitantes

> Un visitante concreto implementa **un método por cada tipo de elemento** (dos para el `If`: entrar y salir). Programar una operación nueva es escribir esos métodos.

El comienzo de `objetos/visitor/Visitors.scala`. `Add.type` es el tipo del objeto `Add`: como `Add` es un `object` y no una clase, su tipo se escribe así.

```scala
package tadp.microprocesador.objetos.visitor

import tadp.microprocesador.objetos.Micro
import tadp.microprocesador.objetos.ExecutionHaltException
import scala.collection.mutable.ListBuffer
import scala.collection.mutable.Stack

trait InstructionVisitor {
  def visitProgram(program: Program) = program.accept(this)
  def visitInstruction(instruction: Instruction) = instruction.accept(this)

  def visitAdd(instruction: Add.type): Unit
  def visitMul(instruction: Mul.type): Unit
  def visitSwap(instruction: Swap.type): Unit
  def visitLoad(instruction: Load): Unit
  def visitStore(instruction: Store): Unit
  def visitIf(instruction: If): Unit
  def endVisitIf(instruction: If): Unit
  def visitHalt(instruction: Halt.type): Unit
}
```

Los dos primeros métodos son concretos y de comodidad: `visitProgram(p)` es lo mismo que `p.accept(this)`, y `visitInstruction(i)`, lo mismo que `i.accept(this)`. El segundo, además, es el punto por donde pasa **cada** instrucción del programa, y por eso se puede redefinir para decidir si una instrucción se visita o no (las secciones 8 y 9 dependen de esto).

Los otros ocho son abstractos. Cada visitante decide qué hace al encontrarse con cada instrucción: el que ejecuta, la ejecuta; el que imprime, la convierte en texto.

**¿Y una implementación por defecto?** Se podría dar, en el trait, una versión de cada `visit` que no haga nada, para que cada visitante redefina solo lo que le interesa. Se usa poco, porque esconde el error de olvidarse un caso: cuando agregás una operación, conviene pensar en cada tipo de instrucción y que el compilador te obligue.

## 6. 🔴 El recorrido lo controla la estructura

> En el Visitor, **la estructura decide el orden y el recorrido**; el visitante solo recibe avisos: "visitaste un `Add`", "entraste a un `If`". Como ningún aviso le trae lo que dejó el anterior, todo lo que necesite recordar lo guarda **en su propio estado**.

Mirá el `accept` del `If`: entra, recorre **todas** las subinstrucciones y sale. El visitante tiene cero voto. Su única participación es responder cada aviso. La estructura es la responsable de saber recorrerse: es, en la práctica, su propio *forEach*.

Esto tiene una consecuencia que recorre todo el resto del módulo. El contrato de un visitante trabaja nodo por nodo: un `visit` por instrucción. No hay forma de que un `visit` le pase algo al siguiente. Si la operación necesita recordar algo entre una instrucción y otra (dónde está el texto que va armando, si hay que ignorar lo que viene, qué fue lo último que vio), lo tiene que guardar en un atributo del visitante y manipularlo.

Esa complejidad de manejar estado pertenece al Visitor, no al problema. Ejecutar un `If` es "si A es 0, ejecutá esto; si no, nada". Imprimir es "escribí cada instrucción". Las tres secciones que siguen muestran cuánto cuesta decir eso cuando el recorrido es de otro.

## 7. 🟡 `PrintVisitor`: el ejemplo de libro

> Imprimir es el caso más fácil: el visitante guarda el **texto que va armando** en un atributo, y cada aviso le agrega un pedazo. El `If` agrega `IF[` al entrar y `]` al salir; sus subinstrucciones llegan solas en el medio.

`addText` agrega un separador `", "` antes de cada pedazo, salvo al principio del texto o justo después de abrir un corchete.

```scala
class PrintVisitor extends InstructionVisitor {
  private var text = ""

  private def addText(s: String) = text += (if(text.isEmpty || text.endsWith("[")) "" else ", ") + s

  def visitAdd(instruction: Add.type) = addText("ADD")
  def visitMul(instruction: Mul.type) = addText("MUL")
  def visitSwap(instruction: Swap.type) = addText("SWP")
  def visitLoad(instruction: Load) = addText(s"LOD[${instruction.address}]")
  def visitStore(instruction: Store) = addText(s"STR[${instruction.address}]")
  def visitIf(instruction: If) = addText("IF[")
  def endVisitIf(instruction: If) = text += "]"
  def visitHalt(instruction: Halt.type)  = addText("HLT")

  def result = text
}
```

Para probarlo desde afuera del paquete:

```scala
import tadp.microprocesador.objetos.Micro
import tadp.microprocesador.objetos.visitor._

val printer = new PrintVisitor
printer.visitProgram(new Program(List(Swap, new If(new Program(List(new Load(2), new If(new Program(List(Add)))))))))
printer.result   // Resultado: SWP, IF[LOD[2], IF[ADD]]
```

Fijate qué hace `visitIf`: escribe `IF[` y nada más. No imprime las subinstrucciones, porque **ya le van a llegar** los avisos de cada una. Y cuando le avisan que salió, cierra el corchete. El visitante nunca arma una oración entera: le llegan pedazos, en el orden que la estructura decide, y los va pegando en su estado.

⚠️ **Trampa: el separador después de abrir.** Con `addText(s) = text += (if(text.isEmpty) "" else ", ") + s`, cualquier pedazo que no sea el primero lleva coma, incluido el que viene justo después de `IF[`, y el mismo programa sale `SWP, IF[, LOD[2], IF[, ADD]]`. La condición tiene que contemplar el corchete abierto: `if(text.isEmpty || text.endsWith("[")) "" else ", "`. Es el tipo de error que aparece cuando el estado se arma a pedazos y cada pedazo tiene que adivinar qué vino antes.

**Sin micro.** `PrintVisitor` se construye sin parámetros: imprimir un programa es independiente del micro donde se ejecutaría. Nada en el patrón te impide pasarle un micro a un visitante que nunca lo usa; es un parámetro de más que la forma del Visitor no detecta. El Módulo 7 mantiene esa separación: `print` no toca el micro.

Este visitante es el que hace pensar que el Visitor no es tan grave, y es justamente porque la operación es trivial. Aun así, depende de un estado que se modifica a cada aviso: si algo quedara mal escrito ahí, rastrear qué aviso agregó qué al texto sería incómodo.

## 8. 🔴 `RunVisitor`: ejecutar sin controlar el recorrido

> Ejecutar modifica el micro que recibe el visitante. El problema es el `If`: si la condición falla, hay que **saltear avisos que la estructura va a mandar igual**, y la única forma es una bandera (un *flag*) en el estado del visitante.

En el bloque aparece `super.visitInstruction(instruction)`: llama a la versión del trait, la que hace `instruction.accept(this)`.

```scala
class RunVisitor(micro: Micro) extends InstructionVisitor {
  private var ignoreInstructions = false

  override def visitInstruction(instruction: Instruction) = if(!ignoreInstructions) super.visitInstruction(instruction)

  def visitAdd(instruction: Add.type): Unit = {
    micro.a = micro.a + micro.b
  }

  def visitMul(instruction: Mul.type): Unit = {
    micro.a = micro.a * micro.b
  }

  def visitSwap(instruction: Swap.type): Unit = {
    val temp = micro.a
    micro.a = micro.b
    micro.b = temp
  }

  def visitLoad(instruction: Load): Unit = {
    micro.a = micro.mem(instruction.address)
  }

  def visitStore(instruction: Store): Unit = {
    micro.mem(instruction.address) = micro.a
  }

  def visitIf(instruction: If): Unit = {
    if (micro.a != 0) ignoreInstructions = true
  }

  def endVisitIf(instruction: If): Unit = {
    ignoreInstructions = false
  }

  def visitHalt(instruction: Halt.type): Unit = {
    throw new ExecutionHaltException
  }
}
```

**Lo fácil.** `visitAdd`: tomá el registro A y el B, sumalos, guardalo en A. `visitMul`, igual con el producto. `visitLoad` y `visitStore` leen la dirección **de la instrucción** (`instruction.address`): el visitante necesita ver por dentro a cada instrucción para hacer su trabajo. `visitSwap` necesita una variable temporal: guarda A, pisa A con B, pisa B con lo guardado. Es el swap clásico, y el Módulo 8 lo va a escribir sin temporal. `visitHalt` lanza una excepción para cortar la ejecución.

El micro es el estado compartido entre todas las visitas. Se recibe al construir el visitante, y cada `visit` lo modifica desde afuera. Cuando termina la visita, el micro que pasaste quedó como si hubiera ejecutado el programa.

**Lo difícil: el `If`.** Si A es 0, hay que ejecutar las subinstrucciones; si no, saltearlas. ¿Cómo se saltean mensajes que alguien te va a mandar en el futuro? Con estado. `visitIf` prende la bandera `ignoreInstructions` si la condición falla. `visitInstruction` está redefinido: solo deja pasar la instrucción si la bandera está apagada. Y `endVisitIf` la apaga, para que lo que sigue después del `If` se ejecute.

```scala
val micro = new Micro
micro.mem(0) = 7
micro.a = 5
new RunVisitor(micro).visitProgram(new Program(List(new If(new Program(List(new Load(0)))))))
micro.a   // Resultado: 5
```

Con A = 5, el `If` se saltea y A queda en 5. Con `micro.a = 0`, el mismo programa deja A en 7.

La bandera es complejidad extra: forma parte de implementar un Visitor, no de ejecutar el lenguaje. Otras formas de escribir esta operación prescinden de ella. Aparece porque el control del recorrido lo tiene otro objeto.

⚠️ **Trampa: "con un `IF` dentro de otro, una bandera no alcanza; hace falta una pila".** La duda es si el `If` de adentro, al apagar la bandera, hace correr lo que el de afuera debía saltear. Eso nunca pasa, porque `Program` pasa cada instrucción por `visitInstruction` (sección 4): si el de afuera se saltea, el de adentro se descarta entero, sin `visitIf` ni `endVisitIf`, y la bandera queda prendida hasta que sale el de afuera.

```
IF[LOD[0], IF[STR[1]], STR[2]] con mem(0) = 7 y A = 0  →  mem(1) = 0, mem(2) = 7
IF[IF[STR[1]], STR[2]], STR[3] con A = 4               →  mem(1) = 0, mem(2) = 0, mem(3) = 4
```

Una sola bandera alcanza. Y que haga falta este razonamiento para saberlo es, en sí, el problema: el comportamiento del visitante depende de cómo la estructura decide recorrerse.

## 9. 🔴 Antipatrón: estado propio para saltear lo que te mandan

> Hay una forma de ejecutar con Visitor que anda y es mal diseño: **guardar estado en el visitante para deshacer un recorrido que no controla**. Que funcione depende de un detalle de la estructura que el visitante ni ve.

Toda la sección anterior descansa en una línea de `Program`:

```scala
def accept(visitor: InstructionVisitor): Unit = {
  for (instruction <- instructions)
    visitor.visitInstruction(instruction)
}
```

`Program` le pasa cada instrucción al visitante **a través de `visitInstruction`**, que es el método que `RunVisitor` redefinió para consultar la bandera. Ahora mirá esta otra versión, igual de razonable a la vista:

```scala
def accept(visitor: InstructionVisitor): Unit = {
  for (instruction <- instructions)
    instruction.accept(visitor)
}
```

Hace "lo mismo": `visitInstruction(i)` es `i.accept(this)`, lo dijo la sección 5. Compila sin avisos. Y rompe el `If`: la instrucción acepta directamente al visitante y el `visitInstruction` redefinido queda fuera del camino. La bandera se prende y se apaga, y ningún método la lee.

```
IF[LOD[0]] con mem(0) = 7 y A = 5, con este segundo accept  →  A queda en 7
```

El `If` se ejecuta siempre. Leyendo `RunVisitor` solo, es imposible darse cuenta: la bandera está, se prende cuando corresponde, se apaga cuando corresponde, y `visitInstruction` la consulta. El error está en **otro archivo**, en una decisión de la estructura sobre por dónde recorrerse.

Esto es lo que hace mal diseño al estado propio del visitante. La operación "ejecutar un `If`" se partió en tres lugares (`visitIf`, `endVisitIf` y el `visitInstruction` redefinido), coordinados por un atributo, y su correctitud depende de un cuarto lugar que pertenece a la estructura. Nada de eso es parte del problema. Es lo que cuesta ejecutar algo cuando el recorrido lo decide otro objeto. Para entender qué hace el visitante hay que saltar todo el tiempo entre su código y el de las instrucciones, recordando en qué estado va a estar el visitante cuando le llegue cada aviso.

La forma que corrige el antipatrón es devolverle el control del recorrido a la operación. La solución `puro` del Módulo 2 lo hacía, sin bandera:

```scala
class If(subInstructions: Program) extends Instruction {
  def beExecutedBy(micro: Micro): Unit = {
    if (micro.a == 0) subInstructions.runOn(micro)
  }
  ...
}
```

El `If` decide si entra. El costo es el de siempre: ejecutar vuelve a ser un método de cada instrucción, y la interfaz crece con cada operación. Si no querés tocar la interfaz de las instrucciones, el Visitor es lo mejor que objetos ofrece. El Módulo 7 muestra la otra salida: un `run` afuera de las instrucciones, que mira el `If` y decide si entra.

## 10. 🔴 `SimplifyVisitor`: una pila y cinco variables para una regla de dos instrucciones

> Simplificar depende de **dos instrucciones a la vez** (dos `SWAP` seguidos se cancelan), y el visitante las recibe **de a una**. Para recordar la anterior necesita una o dos variables por regla, y una pila para los `If` anidados.

Las reglas (Módulo 1) se ven a simple vista sobre la lista: dos `SWAP` seguidos se cancelan; de dos `LOAD` seguidos, el primero sobra; de dos `STORE` seguidos a la misma dirección, el primero sobra; lo que viene después de un `HALT` sobra; un `If` vacío desaparece. Cualquiera las aplica en papel. Un `SWAP` solo puede decidir si se simplifica sabiendo si antes hubo otro, y cuando el visitante recibe el segundo, el aviso es el mismo `visitSwap` que el del primero: nadie le dice "este es el segundo".

Dos herramientas nuevas de Scala, de `scala.collection.mutable`:

- `ListBuffer[Instruction]`: una lista **mutable**; `lista += x` le agrega `x` al final, y `lista.dropRightInPlace(1)` le saca el último.
- `Stack`: una **pila**. `push` pone algo arriba, `pop` saca lo de arriba y lo devuelve, `top` lo mira sin sacarlo.

```scala
class SimplifyVisitor() extends InstructionVisitor {
  private var simplified = Stack(ListBuffer[Instruction]())
  private var justVisitedSwap = false
  private var justLoadedA = false
  private var justWroteMem = false
  private var lastWroteMemAddress = 0
  private var visitedHalt = false

  override def visitInstruction(instruction: Instruction) = if(!visitedHalt) super.visitInstruction(instruction)

  def visitAdd(instruction: Add.type): Unit = {
    simplified.top += instruction

    justVisitedSwap = false
    justLoadedA = false
    justWroteMem = false
  }

  def visitMul(instruction: Mul.type): Unit = {
    simplified.top += instruction

    justVisitedSwap = false
    justLoadedA = false
    justWroteMem = false
  }

  def visitSwap(instruction: Swap.type): Unit = {
    if(justVisitedSwap){
      simplified.top.dropRightInPlace(1)
      justVisitedSwap = false
    } else {
      simplified.top += instruction
      justVisitedSwap = true
    }

    justLoadedA = false
    justWroteMem = false
  }

  def visitLoad(instruction: Load): Unit = {
    if(justLoadedA) simplified.top.dropRightInPlace(1)

    simplified.top += instruction

    justVisitedSwap = false
    justWroteMem = false
    justLoadedA = true
  }

  def visitStore(instruction: Store): Unit = {
    if(justWroteMem && lastWroteMemAddress == instruction.address) simplified.top.dropRightInPlace(1)

    simplified.top += instruction

    justVisitedSwap = false
    justWroteMem = true
    lastWroteMemAddress = instruction.address
    justLoadedA = false
  }

  def visitIf(instruction: If): Unit = {
    simplified.push(ListBuffer[Instruction]())

    justVisitedSwap = false
    justWroteMem = false
    justLoadedA = false
  }

  def endVisitIf(instruction: If): Unit = {
    val subInstructions = simplified.pop()
    if(subInstructions.nonEmpty) simplified.top += new If(new Program(subInstructions))

    justVisitedSwap = false
    justWroteMem = false
    justLoadedA = false
    visitedHalt = false
  }

  def visitHalt(instruction: Halt.type): Unit = {
    simplified.top += instruction

    visitedHalt = true
  }

  def result = new Program(simplified.top)
}
```

**El estado.** Una pila de listas, porque cada `If` arma su propia lista simplificada: al entrar se apila una vacía, al salir se desapila y, si quedó algo, se agrega como `If` a la lista de abajo. Cuatro banderas: "acabo de visitar un `SWAP`", "acabo de cargar A", "acabo de escribir memoria", "visité un `HALT`". Y la última dirección escrita, que arranca en 0 aunque nada se escribió en la posición 0: es un valor que hay que ponerle, y solo tiene sentido cuando `justWroteMem` está prendida.

**El caso más fácil.** `visitAdd`: un `ADD` nunca se simplifica. Hay que agregarlo a la lista y apagar tres banderas, porque ya no es cierto que lo último fue un `SWAP`, un `LOAD` o un `STORE`. Para no hacer nada hay que hacer todo eso. ¿Está bien este código? Para saberlo hay que releerlo varias veces y verificar que cada método apague las banderas que corresponde.

**`visitSwap`.** Si acabo de visitar un `SWAP`, saco el último de la lista (ese `SWAP`) y, además de no agregar el actual, apago la bandera: se cancelaron los dos, así que técnicamente "no acabo de visitar un `SWAP`". Si no, me agrego y prendo la bandera. Y en los dos casos, apago las de `LOAD` y `STORE`.

```scala
val simplificador = new SimplifyVisitor
simplificador.visitProgram(new Program(List(Add, new Load(0), new Load(1), Swap, Swap, new Store(2), new Store(2), Mul)))
val impresora = new PrintVisitor
impresora.visitProgram(simplificador.result)
impresora.result   // Resultado: ADD, LOD[1], STR[2], MUL
```

Más casos, en la notación del Módulo 1:

```
SWP, SWP, SWP          →  SWP
ADD, HLT, MUL, SWP     →  ADD, HLT
IF[SWP, SWP], ADD      →  ADD
IF[HLT, ADD], MUL      →  IF[HLT], MUL
```

El último muestra por qué `endVisitIf` apaga `visitedHalt`: un `HALT` dentro de un `If` corta solo el resto de ese `If`.

⚠️ **Trampa: `dropRight` sobre un `ListBuffer`.** `simplified.top.dropRight(1)` **devuelve una lista nueva** sin el último elemento y deja el `ListBuffer` igual; si nadie usa lo que devuelve, la línea no hace nada. Con eso, `ADD, SWP, SWP, MUL` queda `ADD, SWP, MUL`, y `LOD[0], LOD[1]` queda igual. Para modificar el `ListBuffer` hay que usar `dropRightInPlace(1)`. Compila igual de bien en los dos casos.

⚠️ **Trampa: una bandera que nadie lee.** Prender `visitedHalt` en `visitHalt` sirve de algo solo si otro método la consulta. Sin el `override def visitInstruction` que deja de visitar cuando está prendida, lo que viene después de un `HALT` se sigue agregando: `ADD, HLT, MUL, SWP` queda igual. Cada bandera del visitante necesita a alguien que la escriba y a alguien que la lea, en métodos distintos.

Si el final de esta materia fuera arreglar un bug en este visitante, no aprobaría nadie. Y el problema es trivial: mirar la lista y sacar lo que sobra. Si encima el problema fuera complejo, la implementación compleja lo volvería inmanejable. ¿Por qué es tan difícil? Porque al visitante le prohibiste mirar la lista entera, le diste las instrucciones de a una, en el orden que eligió otro, y le pediste igual que decida sobre pares. El Módulo 7 escribe `simplify` mirando la lista entera.

## 11. 🔴 Lo que dice el libro: tres vértices tachados

> El propio libro del patrón admite, en cuatro frases, que el Visitor **renuncia a la delegación, al encapsulamiento y al polimorfismo**, y que crece como el triángulo rojo.

Sobre el triángulo azul, una frase por vez:

```
          polimorfismo                          ✗ polimorfismo
              /\                                      /\
             /  \               →                    /  \
            /____\                                  /____\
  delegación    encapsulamiento       ✗ delegación        ✗ encapsulamiento
```

**1. Delegación.** *"Usá el patrón Visitor cuando muchas operaciones diferentes deban realizarse sobre una estructura de objetos y quieras evitar 'contaminar' sus clases con estas operaciones."* Evitar contaminar la interfaz de un objeto con lo que se hace sobre él es negarse a delegar. La operación se saca de los elementos y se pone en otro lado, a propósito: eso separa estructura de operación, que es funcional.

**2. Encapsulamiento.** *"El patrón con frecuencia te fuerza a proveer operaciones públicas para acceder al estado interno de un elemento, lo cual compromete el encapsulamiento."* Si la operación vive afuera, todo lo que necesite del elemento tiene que ser público: `visitLoad` lee `instruction.address`. El elemento queda abierto para que el visitante lo revise, y el visitante queda fuertemente acoplado a cada elemento. Las operaciones sí quedan encapsuladas en su visitante; los elementos, expuestos.

**3 y 4. Polimorfismo.** *"Los Visitors hacen fácil agregar operaciones […] simplemente agregando un nuevo visitor."* Y: *"El Visitor hace difícil agregar nuevas subclases de elementos. Cada nuevo elemento concreto conlleva una nueva operación en cada Visitor concreto."* Es la tabla del Módulo 3, del lado rojo: fácil agregar operaciones, caro agregar estructuras. Y peor que con un type check propio: si agregás una instrucción, cambia el contrato de `InstructionVisitor`, y **todos los clientes de la librería** tienen que agregar el `visit` nuevo en todas sus operaciones, ya, porque si no su código deja de compilar. En tu propio código, que el compilador te obligue es una ayuda (sección 5); en una librería, el que tiene que arreglarlo es cada cliente.

Se tacharon los tres vértices. El Visitor, desenmascarado, es el triángulo rojo: operaciones separadas de los datos, que deciden qué hacer según la forma de lo que reciben. Y el libro lo sabe: dice todo esto y aun así lo publica como patrón, porque es la mejor respuesta que objetos tiene a un problema que le pasa seguido.

**Para el parcial, si te preguntan:** *"¿Por qué se dice que el Visitor es funcional disfrazado?"* Porque separa las operaciones de la estructura (cada visitante es una operación, y los elementos solo aceptan), y eso es lo que funcional propone. El propio libro admite que el patrón evita delegar en los elementos, que los obliga a exponer su estado (compromete el encapsulamiento) y que hace fácil agregar operaciones y difícil agregar elementos, que es como crece el triángulo rojo. El doble despacho es la forma de recuperar desde afuera el tipo del elemento para decidir qué hacer: pattern matching, hecho con mensajes.

## 12. 🔴 Complejidad accidental: el triángulo rojo por el camino difícil

> El Visitor da las ventajas del triángulo rojo al precio de **complejidad accidental**: complejidad que viene de la implementación, no del dominio. Matás polimorfismo, delegación y encapsulamiento para trabajar como funcional, y lo hacés con las herramientas que funcional no usa.

Sumá lo que viste. Para ejecutar un `If`: una bandera, un método redefinido y una dependencia de cómo recorre la estructura. Para imprimir: un texto que se arma a pedazos. Para simplificar: una pila y cinco variables, para reglas que caben en una línea cada una. **La lógica para hacer esto termina siendo mucho más difícil que la lógica misma.** Eso es complejidad accidental, la que trae la implementación y el dominio jamás pidió.

Y no es que esté mal escrito: con las reglas de objetos, si la condición es no tocar la interfaz de las instrucciones, no hay una versión mejor del Visitor. Hasta sus defensores lo admiten: el Visitor da vuelta el modelo de objetos y crea una clase externa que actúa sobre los datos de otras clases; puede parecer sucio, y lo justifican con buenas razones, como agregarle funciones a una librería cuyo código no podés cambiar (la situación de la sección 2). Un `switch` con type checks también se pone feo, sobre todo en un lenguaje tipado, donde después de preguntar el tipo hay que castear para usar la referencia. Nunca tanto como un Visitor.

¿Y por qué objetos no dijo "en este caso, usá el `switch`"? Por lo del Módulo 3: había entrenado a toda una generación para reemplazar cada `switch` por polimorfismo, sin excepciones. ¿Cómo distingue ese programador este caso de cualquier otro, si aprendió a usar solo el triángulo azul? No había forma fácil de integrar la otra idea. Entonces se usó lo único que el paradigma permitía: simular el triángulo rojo con piezas del azul, y justificar que se seguía delegando, encapsulando y usando polimorfismo cuando el propio uso del patrón lo contradice.

La pregunta que abre el resto de la unidad: si tanto esfuerzo va en simular el triángulo rojo con el azul, **¿no sería más fácil ponerle pattern matching a objetos y ver qué pasa?** Así nace el híbrido objeto-funcional. Y trae una obligación: si tenés las dos herramientas, ya no alcanza con "siempre polimorfismo". Hay que madurar las dos ideas y armar un **criterio** sobre cuándo usar cada una.

**Para el parcial, si te preguntan:** *"¿Qué es la complejidad accidental y dónde aparece en el Visitor?"* Es la complejidad que viene de la implementación y no del problema. En el Visitor aparece porque el recorrido lo controla la estructura: el visitante recibe avisos de a uno y tiene que recordar todo en su propio estado. Ejecutar un `If` necesita una bandera para saltear lo que igual le van a mandar, y simplificar necesita una pila y cinco variables para reglas que miran dos instrucciones seguidas. Nada de ese estado pertenece al dominio del micro.

---

## Checkpoint

1. ¿Qué es un patrón de diseño, y qué parte importa más que el diagrama?
2. Describí la situación en la que se propone el Visitor. ¿Por qué el pedido "no quiero acoplar la lógica a los datos" debería hacer ruido?
3. ¿Qué exponen los elementos y qué representan los visitantes? ¿Cuántos métodos tiene un visitante?
4. Explicá el doble despacho paso a paso con `Load` y `RunVisitor`. ¿Qué tipo se "recupera" en cada paso?
5. ¿Por qué `accept` no puede escribirse una sola vez en `Instruction`?
6. ¿Qué mensajes manda el `If` al aceptar un visitante, y por qué tres?
7. ¿Quién controla el recorrido en el Visitor? ¿Qué consecuencia tiene para el estado de los visitantes?
8. ¿Qué hace `visitIf` en `PrintVisitor`, y por qué no imprime las subinstrucciones?
9. ¿Cómo hace `RunVisitor` para saltear el cuerpo de un `If`? ¿Por qué una sola bandera alcanza con `If` anidados?
10. Si `Program.accept` llama `instruction.accept(visitor)` en vez de `visitor.visitInstruction(instruction)`, ¿qué pasa? ¿Por qué cuesta encontrarlo?
11. ¿Para qué sirve cada variable de `SimplifyVisitor`? ¿Por qué `visitAdd` tiene que apagar banderas?
12. ¿Qué frase del libro tacha cada vértice del triángulo azul?
13. ¿Por qué agregar una instrucción a una librería con Visitor es peor que agregar un caso a un `switch` en tu propio código? ¿Quién paga el cambio?
14. ¿Qué es complejidad accidental? Da dos ejemplos del micro.

## Qué viene después

**Módulo 6:** la herramienta que el Visitor simulaba. `case class`, `case object` y `match` en Scala: datos que se dejan mirar por dentro, y operaciones que deciden según la forma de lo que reciben, sin bandera, sin pila y sin doble despacho.

**FIN DEL MÓDULO 5 — El Visitor, o cómo objetos se rinde**
