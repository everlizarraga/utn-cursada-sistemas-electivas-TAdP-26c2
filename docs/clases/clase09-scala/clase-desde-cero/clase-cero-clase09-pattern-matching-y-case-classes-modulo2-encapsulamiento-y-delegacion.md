# Clase desde cero — Pattern matching, case classes y el híbrido objeto-funcional — Módulo 2: Objetos puros: encapsulamiento y delegación, revisados

**Unidad:** clase09 · **Lenguaje:** Scala 3.3.1 · **Archivo del proyecto:** `objetos/puro/Instructions.scala` (lectura guiada) · **Densidad:** 🔴 una sesión con el código abierto

---

## Sobre este documento

**Qué cubre.** La primera solución al problema del micro, con las operaciones adentro de las instrucciones, y sobre ella la revisión de dos de las tres ideas que sostienen objetos: **encapsulamiento** y **delegación**. No la frase hecha de cada una, sino el problema concreto que resuelven, por qué importan y dónde empiezan a hacer agua. Antes de la lectura guiada de `simplify`, lo que objetos garantiza y funcional no puede (el Módulo 8 lo da vuelta).

**Qué no cubre.** Polimorfismo, que es la tercera idea y tiene el Módulo 3 para ella sola. Tampoco el Visitor ni las herramientas de funcional; de funcional entra solo, en la sección 8, la comparación sobre invariantes.

**Una aclaración sobre el código.** La solución `puro` está en el proyecto para que la unidad tenga el punto de partida completo, pero su diseño interno (cómo simplifica, en particular) es una forma posible entre varias. Acá se lee de forma guiada; lo que se evalúa son las ideas, no esa implementación.

## De dónde venís

Del Módulo 1: el micro, las siete instrucciones, el programa como lista, las tres operaciones y la pregunta de dónde van. De las clases anteriores: `trait` como contrato, `object` como instancia única, `override`, `Seq`. De Ruby y de Paradigmas: objeto, mensaje, responsabilidad, y que un objeto "sabe hacer" cosas. De Diseño de Sistemas (DSI): Java, con sus getters y setters.

---

## 1. 🔴 La primera solución: las operaciones adentro de las instrucciones

> Cada instrucción es un objeto que **sabe ejecutarse, imprimirse y simplificarse**. El programa delega cada operación en sus instrucciones, una por una.

Es la respuesta refleja de objetos, y en el proyecto está en `objetos/puro/Instructions.scala`. El contrato de una instrucción:

```scala
trait Instruction {
  def beExecutedBy(micro: Micro): Unit   // ejecutate sobre este micro
  def print: String                      // tu texto

  // para simplificar: ¿qué queda de vos y de la que te sigue? ¿y de vos sola, si sos la última?
  def simplifiedBefore(next: Instruction): Seq[Instruction] = Seq(this, next)
  def simplifiedAtTheEnd: Seq[Instruction] = Seq(this)
  def cancelsWithSwap = false
  def overwritesAWithoutReading = false
  def overwritesAddress(address: Int) = false
}
```

Las dos primeras operaciones son un método cada una. Simplificar necesita cinco (vuelve en la sección 9). Las instrucciones sin parámetro son `object` (una sola instancia alcanza); las que llevan dirección son `class`. `Mul` es gemela de `Add` y está en el archivo; acá van las demás:

```scala
object Add extends Instruction {
  def beExecutedBy(micro: Micro): Unit = {
    micro.a = micro.a + micro.b
  }
  def print = "ADD"
}

object Swap extends Instruction {
  def beExecutedBy(micro: Micro): Unit = {
    val temp = micro.a                   // la variable temporal del Módulo 1
    micro.a = micro.b
    micro.b = temp
  }
  def print = "SWP"
  override def simplifiedBefore(next: Instruction) = if (next.cancelsWithSwap) Seq() else super.simplifiedBefore(next)
  override def cancelsWithSwap = true
}

class Load(val address: Int) extends Instruction {
  def beExecutedBy(micro: Micro): Unit = {
    micro.a = micro.mem(address)
  }
  def print = s"LOD[$address]"
  override def simplifiedBefore(next: Instruction) = if (next.overwritesAWithoutReading) Seq(next) else super.simplifiedBefore(next)
  override def overwritesAWithoutReading = true
}

class Store(val address: Int) extends Instruction {
  def beExecutedBy(micro: Micro): Unit = {
    micro.mem(address) = micro.a
  }
  def print = s"STR[$address]"
  override def simplifiedBefore(next: Instruction) = if (next.overwritesAddress(address)) Seq(next) else super.simplifiedBefore(next)
  override def overwritesAddress(address: Int) = this.address == address
}

class If(subInstructions: Program) extends Instruction {
  def beExecutedBy(micro: Micro): Unit = {
    if (micro.a == 0) subInstructions.runOn(micro)   // delega en su sub-programa
  }
  def print = s"IF[${subInstructions.print}]"
  // simplifiedBefore y simplifiedAtTheEnd: sección 9
}

object Halt extends Instruction {
  def beExecutedBy(micro: Micro): Unit = {
    throw new ExecutionHaltException
  }
  def print = "HLT"
  override def simplifiedBefore(next: Instruction) = Seq(this)   // lo que sigue, desaparece
}
```

Y el programa, que es dueño de la lista y reparte el trabajo:

```scala
class Program(private var instructions: Seq[Instruction]) {
  def runOn(micro: Micro): Unit = {
    for (instruction <- instructions)
      instruction.beExecutedBy(micro)    // cada una se ejecuta sola
  }

  def print = instructions.map(_.print).mkString(", ")   // cada una se imprime sola; se unen con coma

  def simplify: Unit = { /* sección 9 */ }

  def instructionCount = instructions.size
}
```

Tres cosas de sintaxis: `s"LOD[$address]"` es un string con un valor insertado (lo que va después de `$`, o entre `${ }` si es una expresión, se evalúa y se inserta); `instructions.map(_.print)` es "a cada instrucción, mandale `print`" y devuelve la lista de strings; `mkString(", ")` los pega con coma y espacio. Y el programa recibe sus instrucciones por constructor, como `Corral` recibía sus animales.

Funciona. Lo de arriba son recortes del archivo para leer; lo que sigue corre contra el paquete del proyecto, con `import tadp.microprocesador.objetos.puro._` y el `Micro` del Módulo 1:

```scala
import tadp.microprocesador.objetos.puro._
import tadp.microprocesador.objetos.Micro

val micro = new Micro
List(13, 39, 0, 0, 4, 8, 15, 16, 23, 0).zipWithIndex.foreach((v, i) => micro.mem(i) = v)
val programa = new Program(Seq(new Load(0), Swap, new Load(1), Add, new Store(9)))

programa.runOn(micro)
(micro.a, micro.b, micro.mem(9))   // Resultado: (52,13,52)
programa.print                     // Resultado: LOD[0], SWP, LOD[1], ADD, STR[9]

val redundante = new Program(Seq(new Load(0), new Load(0), Swap, Swap, Swap, new Store(1), new Store(1)))
redundante.simplify                // modifica el programa en el lugar
redundante.print                   // Resultado: LOD[0], SWP, STR[1]
redundante.instructionCount        // Resultado: 3

new Program(Seq(new Load(0), Halt, new Load(1))).runOn(micro)
// Resultado: tadp.microprocesador.objetos.ExecutionHaltException (A quedó en 13: el LOAD 1 nunca corrió)
```

Fijate la forma: **el programa no sabe qué es un `Add`**. Le manda `beExecutedBy` y el `Add` sabe qué hacer. El programa tampoco sabe qué texto tiene un `Load`: le manda `print`. Cada pieza de lógica vive adentro del dato al que le corresponde. Esa es la idea radical de objetos, y es lo que las secciones siguientes revisan: ¿por qué queremos eso?

## 2. 🔴 Encapsulamiento: lo que te dijeron, y por qué no alcanza

> Un objeto **garantiza que está siempre en un estado consistente**, y lo hace regulando por qué puerta se lo toca. "No accedas a los atributos" es un caso particular de eso; la idea de fondo es más grande.

Empezá por el contraste con estructurado. Imaginate que te dan esto y te dicen "subile la nota al alumno":

```
alumno = { campo1: 7, campo2: true, campo3: 3, campo4: "K", campo5: 1023 }
```

¿Cuál es la nota? ¿`campo1`? ¿Hay un rango válido? ¿`campo2` es "promocionado" y hay que mantenerlo sincronizado con la nota? ¿`campo3` cuenta algo que cambia cuando cambia la nota? Para tocar un campo tenés que entender la estructura entera y todas las reglas que la relacionan, que viven en la cabeza de alguien o en un documento. Con un objeto, mandás `alumno.subirNota` y, si el método existe, el objeto se encarga de todo lo que ese cambio implica; si falta, es porque está prohibido. **Toda la lógica que en estructurado vive en la cabeza de alguien, en objetos vive en el objeto, y el objeto la recuerda.**

La definición que te dieron en Paradigmas: el objeto cierra el acceso a su estado interno. Es cierta. Pero en los lenguajes que usás, esa regla ya está cumplida por el lenguaje. En Ruby, el estado interno es inaccesible sin metaprogramación. En Scala es más fuerte todavía: **no hay atributos**. Cuando escribís `var peso = 100` en una clase, Scala genera un método `peso` para leer y otro `peso_=` para escribir, y la variable que guarda el valor queda sin nombre accesible. Lo viste en el Módulo 1 con `a` y `a_=`: escrito a mano, es lo que `var` hace solo. ¿Qué valor tiene una regla que dice "no accedas a los atributos" en un lenguaje donde no se puede? Ninguno. Una ley que prohíbe volar por las avenidas no regula nada.

La regla tuvo sentido en su contexto. Java, en sus primeras versiones, tenía atributos públicos por defecto, a propósito: así la gente que venía de estructurado podía copiar y pegar sus programas y después, de a poco, ir convirtiéndolos en objetos. Las rueditas de la bicicleta. "Hacelos privados" era el siguiente paso de ese entrenamiento, y quedó repetido tantas veces que todavía se escucha el eco. Pero para ver la idea de fondo hay que preguntar **por qué** acceder al estado desde afuera es un problema.

**Las dos reglas de objetos.** Todo lo demás se deriva de estas:

1. Un objeto está siempre en un estado consistente: desde que nace hasta que desaparece, su estado es válido para el programa.
2. Toda operación hace exactamente lo que tiene que hacer, o no hace nada y explota.

La segunda existe para sostener la primera. Y el encapsulamiento es el mecanismo: si la única forma de cambiar el estado es a través de operaciones que el objeto expone, y cada operación cumple la regla 2, entonces se cumple la regla 1. Si alguien puede escribir el estado desde afuera, las dos reglas se caen juntas.

Eso es lo que se pierde cuando alguien escribe el estado desde afuera: le quita el control al objeto. Alcanza con que una persona, en un lugar, deje un valor inválido para que el programa quede oficialmente roto y nadie sepa dónde.

**Para el parcial, si te preguntan:** *"¿Qué es el encapsulamiento?"* Es el mecanismo por el cual un objeto garantiza su propia consistencia: el estado solo cambia a través de las operaciones que el objeto expone, y cada operación hace lo que debe o explota. "No acceder a los atributos" es la forma más concreta de esa idea, pero la idea es regular quién sabe qué sobre el objeto, para que el objeto pueda cambiar sin que los demás se enteren.

## 3. 🔴 Acceso uniforme: por qué todo es un mensaje

> Una propiedad se accede **siempre de la misma forma**, sea un atributo guardado o un valor calculado. Así, pasar de uno a otro deja igual a todos los de afuera.

Supongamos un alumno con `legajo` guardado y `nombreCompleto` calculado (concatena nombre y apellido). Si el lenguaje te deja escribir `alumno.legajo` para el atributo y `alumno.getNombreCompleto()` para el cálculo, te está obligando a saber desde afuera cuál es cuál. Ese saber queda escrito en cada lugar que los usa: queda *hardcodeado*. Y el día que el legajo pasa a calcularse (porque ahora tiene una parte que sale de la facultad donde cursa), todos los `alumno.legajo` del sistema se rompen y hay que buscarlos uno por uno.

La propuesta del acceso uniforme es: **todo se pide con un mensaje**. `alumno.legajo` y `alumno.nombreCompleto` se escriben igual y se leen igual, y adentro cada uno hace lo suyo. Si mañana uno deja de ser atributo y pasa a ser cálculo, desde afuera se ve igual.

Scala te lo da gratis, por lo de la sección anterior: `var legajo` ya genera el método `legajo`, y un `def nombreCompleto = …` se usa exactamente igual. Hay un segundo motivo, además del cambio: el **polimorfismo**. Si tenés cinco cosas con legajo y cuatro lo guardan y una lo calcula, con acceso uniforme las cinco se usan igual; sin él, la quinta queda afuera. El Módulo 3 vuelve sobre esto.

Es otra idea que el lenguaje absorbió, y eso tiene una lectura general: **un patrón o una práctica recurrente marca el lugar donde la tecnología te abandonó**. Existe porque la solución automática todavía no está. Por eso varios patrones del libro clásico de diseño hoy son caducos: nadie programa un singleton a mano cuando el lenguaje tiene `object`. Cuando el lenguaje absorbe la práctica, la práctica deja de ser una guía. Esto vuelve en el Módulo 5, con un patrón que todavía se usa.

## 4. 🔴 Encapsular es ceder control: la cadena de mensajes

> Encapsulamiento habla de **acoplamiento**: cuánto sabe un pedazo de código sobre cómo está hecho otro. Un objeto encapsulado te priva de información **a propósito**, para que tu código dependa de menos cosas.

Ocultar la implementación sirve para tres cosas: **preservar invariantes** (sección 8), **resistir el cambio** y **disminuir el acoplamiento**. Las dos últimas se ven en una línea. Mirá esta: todos son mensajes, sin tocar ningún atributo:

```scala
universidad.facultad.materia.curso.profesor
```

¿Rompe el encapsulamiento? Sí. Quien escribió eso sabe que una universidad tiene una facultad, que la facultad tiene una materia, que la materia tiene un curso y que el curso tiene un profesor. Cuatro decisiones de diseño ajenas, escritas en una línea. Dibujalo como una cadena de cajas:

```
 ┌─────────────┐    ┌──────────┐    ┌─────────┐    ┌───────┐    ┌──────────┐
 │ universidad │───►│ facultad │───►│ materia │───►│ curso │───►│ profesor │
 └─────────────┘    └──────────┘    └─────────┘    └───────┘    └──────────┘
                                         ✱ cualquier eslabón puede cambiar
```

¿En cuántos lugares puede romperse? En cualquiera. Que una facultad pase a tener varias materias, que el curso pueda tener dos profesores, que alguien renombre `materia` a `subject`: cualquier cambio en cualquier eslabón rompe esta línea, y todas las líneas parecidas que haya en el sistema.

La alternativa:

```scala
universidad.profesor
```

¿Es mejor? Tiene un problema menos, seguro. Esta línea depende de que la universidad sepa darte un profesor, que es lo que tu lógica necesitaba. Adentro de `Universidad`, el método `profesor` puede tener exactamente la cadena de antes, y la discusión se vuelve a abrir ahí, un nivel más adentro. Pero **vos elegiste hasta dónde acoplarte**. Eso es encapsular: ceder el control de un recorrido a quien lo conoce, y compartimentar el conocimiento. Desde afuera de la universidad ignorás, a propósito, si tiene facultades; adentro, lo sabés.

Lo mismo, con código y con el segundo "para qué". Una `Tarea` tiene un responsable, y afuera alguien quiere saber si va a terminar antes de una fecha. La forma acoplada recorre todo: `unaTarea.responsable.equipo.cronograma.terminaAntesDe(unaFecha)`. La forma encapsulada (es un esquema: `Empleado` y `Fecha` quedan sin definir):

```scala
class Tarea(val responsable: Empleado) {
  def vaATerminarAntesDe(fecha: Fecha): Boolean = responsable.vaATerminarAntesDe(this, fecha)
}

unaTarea.vaATerminarAntesDe(unaFecha)
```

El de afuera sabe una cosa: una tarea puede decir si termina antes de una fecha. Si mañana la tarea deja de tener responsable y pasa a tener un equipo, cambia `Tarea` por adentro y nadie de afuera se entera: eso es **resistir el cambio**. Y como el responsable es una decisión que vive adentro, quien usa `Tarea` ni sabe que existe: **quien construye el objeto decide qué ve cada usuario**, y usuarios distintos pueden tener acoplamientos distintos con el mismo objeto.

Un acoplamiento de cero no existe: usar un objeto es depender de él. Lo que se regula es el acoplamiento **innecesario**, el que no te hacía falta para tu lógica. Su contracara se llama **cohesión**: que la interfaz de un objeto sea completa para lo que el objeto debe hacer, y nada más. Una universidad que te da el profesor es cohesiva; una que te obliga a pasar por facultad, materia y curso te está delegando a vos su propio trabajo.

Hay una regla con nombre para esto: **"no hables con extraños"** (*don't talk to strangers*). Hablá con la universidad; el curso es un extraño que conociste a través de la facultad. Tomada al pie de la letra ("un solo punto por línea") es ridícula; tomada como alerta sirve: una cadena larga de mensajes te está diciendo que tu código depende de que todo lo que hay atrás siga igual.

**Para el parcial, si te preguntan:** *"¿Por qué `a.b.c.d.e()` rompe el encapsulamiento si solo manda mensajes?"* Porque acopla al que lo escribe con la estructura interna de cuatro objetos: cualquier cambio en cualquiera de ellos lo rompe. Encapsular es que `a` exponga la operación que vos necesitás (`a.e()`) y se haga cargo del recorrido; así vos dependés de una decisión de diseño en vez de cuatro.

## 5. 🔴 Delegación: siempre hay un responsable

> En objetos, toda acción tiene un **sujeto**: la oración es siempre `objeto.mensaje(parámetros)`. Delegar es elegir a quién le toca el siguiente paso.

Cada vez que encapsulás, estás delegando: `universidad.profesor` le encarga a la universidad resolver el recorrido. Y cada vez que programás en objetos, la primera pregunta es "¿de quién es responsabilidad esto?". A veces la respuesta es obvia. A veces es lo más difícil del enunciado: "quiero saber la nota del alumno" cuando todavía no existe la idea de alumno, y hay que inventarla para tener a quién pedírselo.

Delegar es tan central que define si estás en objetos o no. Una clase `Programa` con un método `main` que tiene adentro literalmente todo tu código es estructurado escrito de la forma más incómoda posible: tenés clases, objetos y mensajes, y no usás ninguno. **Objetos con la delegación mal hecha ya no es objetos: es otra cosa.** Las herramientas no te obligan a trabajar de una manera; las ideas son las que guían.

Un ejemplo que parece tonto: `7 * 9`. En objetos eso es `7.*(9)`: objeto `7`, mensaje `*`, parámetro `9`. Un número sabe multiplicarse. Hay gente que, viniendo de otra forma de pensar, propone que "en la realidad los números no se multiplican solos": hace falta un objeto `Calculadora`, y escribe `calculadora.mul(9, 7)`. ¿Por qué es peor? Dos motivos.

Primero, **toda la información para multiplicar estaba en el 9 y el 7**, y ahora dependés de un tercero que nadie te dio: ¿de dónde sale la calculadora? ¿cómo se construye? ¿tengo acceso a ella acá? Introdujiste una dependencia ajena al problema. Llevado al extremo, es el antipatrón del **objeto sistema**: un `Hospital` que sabe todo, y para que un médico atienda a un paciente hay que ir al hospital, que lo único que puede hacer es delegar en el médico o en el paciente. Una indirección vacía.

Segundo, y más revelador: **intentá implementarla**. `???` es la forma de Scala de escribir "todavía no lo escribí": compila, y explota si se ejecuta.

```scala
class Calculadora {
  def mul(a: Int, b: Int): Int = ???   // ¿y ahora?
}
```

Para multiplicar `a` por `b` necesitás, en algún momento, el estado interno de `a` o de `b`. La calculadora no lo tiene. Lo único que puede hacer es `a * b`: delegar en `a`. Así te das cuenta de que la calculadora nunca fue la responsable; solo estorbaba.

**Para el parcial, si te preguntan:** *"¿Por qué `9 * 7` y no `calculadora.mul(9, 7)`?"* Porque en objetos el responsable de una operación es quien tiene la información para hacerla, y acá la tienen los números. La calculadora agrega una dependencia ajena al problema (hay que conseguirla, construirla, tenerla a mano) y, al implementarla, lo único que puede hacer es delegar en `a`: es una indirección sin contenido, la misma que el antipatrón del objeto sistema.

## 6. 🔴 Los tanques: cuando el responsable es más de uno

> Cuando una acción depende de **dos objetos a la vez**, objetos igual te obliga a elegir un sujeto, y el elegido ignora qué es el otro. La salida es el **doble despacho**: el primero codifica su tipo en el nombre del mensaje que le manda al segundo, y el segundo resuelve. Cuesta un método por combinación.

Hay tres objetos: el tanque `T1`, un misil `M`, el tanque `T2`. Quiero que `T1` ataque a `T2` con `M`. ¿A quién le mando el mensaje?

```scala
t1.atacar(m, t2)          // sujeto: el que ataca
t2.recibirAtaque(m, t1)   // sujeto: el atacado
m.seUsaEntre(t1, t2)      // sujeto: el misil
```

Las tres son razonables; el enunciado "T1 ataca a T2 con M" te guía hacia la primera, pero "T2 recibe un ataque" te guiaría hacia la segunda. Ninguna es la correcta, porque **hay tres responsables, y elegir uno como sujeto le quita el rol a los otros dos.**

El problema aparece apenas la lógica depende de los tipos. Un misil solo tiene poder; supongamos que el daño depende de qué tipo de tanque ataca y qué tipo recibe:

| | recibe `Ligero` | recibe `Pesado` |
|---|---|---|
| ataca `Ligero` | daño = poder | daño = poder / 2 |
| ataca `Pesado` | daño = poder × 2 | daño = poder |

Entrás por `t1.atacar(m, t2)`. `t1` sabe qué es él (su fila), pero `t2` le llegó como `Tanque` a secas: puede elegir fila, pero la columna le falta. Entonces lo primero que hace es… delegar en `t2`: "recibí un ataque". Pero `t2` tiene el problema espejo: `t1` le dice "recibí un ataque", y `t2` necesita saber de quién, pero `t1` le llegó como `Tanque` a secas. Nadie puede dar el primer paso. Es un *deadlock* de responsabilidades.

La salida es el **doble despacho** (*double dispatch*): el primero que recibe el mensaje **esconde su tipo en el nombre del mensaje** que le manda al segundo. Hay tantos mensajes "fuiste atacado por…" como tipos de tanque:

```scala
class Misil(val poder: Int)

trait Tanque {
  def atacar(misil: Misil, otro: Tanque): String
  def recibirAtaqueDeLigero(misil: Misil): String   // un mensaje por tipo de atacante
  def recibirAtaqueDePesado(misil: Misil): String
}

class Ligero extends Tanque {
  def atacar(misil: Misil, otro: Tanque): String = otro.recibirAtaqueDeLigero(misil)  // "soy ligero" va en el nombre
  def recibirAtaqueDeLigero(misil: Misil): String = s"ligero vs ligero: daño ${misil.poder}"
  def recibirAtaqueDePesado(misil: Misil): String = s"pesado vs ligero: daño ${misil.poder * 2}"
}

class Pesado extends Tanque {
  def atacar(misil: Misil, otro: Tanque): String = otro.recibirAtaqueDePesado(misil)
  def recibirAtaqueDeLigero(misil: Misil): String = s"ligero vs pesado: daño ${misil.poder / 2}"
  def recibirAtaqueDePesado(misil: Misil): String = s"pesado vs pesado: daño ${misil.poder}"
}

val t1: Tanque = new Ligero
val t2: Tanque = new Pesado
val m = new Misil(10)
t1.atacar(m, t2)   // Resultado: ligero vs pesado: daño 5
t2.atacar(m, t1)   // Resultado: pesado vs ligero: daño 20
t2.atacar(m, t2)   // Resultado: pesado vs pesado: daño 10
```

Seguí el primer caso. `t1` es `Ligero`, así que su `atacar` manda `recibirAtaqueDeLigero`: el nombre del mensaje ya dice quién ataca. Ese mensaje le llega a `otro`, que es `Pesado`, así que corre la versión de `Pesado`. Dos despachos, uno por cada tipo, y recién ahí hay un método que sabe las dos cosas.

Funciona. El costo: **tantos mensajes `recibirAtaqueDe…` como tipos de tanque, en cada tanque**. Con tres tipos, nueve implementaciones de recibir (tres por tanque), más los tres `atacar`. Si además el misil tiene tipos, deja de ser doble y pasa a ser **múltiple despacho**: pensá razas y profesiones que se atacan entre sí; un orco mago contra un humano guerrero es una combinación más, y cada combinación es un método. Es algo con lo que en objetos te cruzás todo el tiempo.

Y acá un dato que vas a reencontrar: **en estructurado esto es trivial**. Un procedimiento `ataque(t1, t2)` recibe los dos, les mira el estado ("vos sos ligero, vos sos pesado") y resuelve. Sin mensajes, sin encapsulamiento, mirando desde afuera. Guardalo: la dificultad de los tanques es el precio de que la lógica viva *adentro* de los datos (el Módulo 4 vuelve sobre esto).

La opción que está definitivamente mal: `campoDeBatalla.ataque(t1, m, t2)`. Te construiste un objeto que, sabés de antemano, no resuelve nada por sí mismo, para que su primer paso sea delegar en uno de los tres. Es la calculadora, con más pasos.

**Para el parcial, si te preguntan:** *"¿Qué es el doble despacho y cuándo aparece?"* Es la técnica por la que el primer objeto reenvía el mensaje al segundo codificando su propio tipo en el nombre (`recibirAtaqueDeLigero` / `recibirAtaqueDePesado`), para que el segundo, que ya conoce los dos tipos, resuelva. Aparece cuando una operación depende del tipo de dos objetos y en objetos solo uno puede ser el sujeto del mensaje. El costo es un método por combinación.

## 7. 🟡 Delegar bien: lo que se gana y lo que se cede

> Delegar bien es decidir **quién va a poder variar mañana**: el que delega renuncia a hacerlo a su manera; el que recibe gana un lugar para participar. Aprender eso es aprender diseño.

Cuando le delegás una responsabilidad a un objeto, su interfaz crece. Un objeto con demasiadas responsabilidades es difícil de usar y, peor, difícil de cambiar: cada método toca el estado, y para modificar uno hay que asegurarse de que todos los demás sigan dejando el objeto consistente. Ese objeto se llama **God object** (el que sabe todo), y suele estar tapando una delegación mejor.

Pero cuidado con las heurísticas con número ("una clase tiene entre 9 y 12 métodos"): un objeto que expone una API externa de 150 operaciones y lo único que hace es delegar cada una en el servicio remoto tiene 150 métodos y está bien. Su acoplamiento es el de la API, y solo cambia cuando la API cambia. Un `Alumno` con 160 métodos, en cambio, pide una explicación.

En el otro extremo está el **data object** (o objeto anémico): un objeto sin lógica, que solo expone sus datos. Es un registro con otro nombre: su consistencia depende de los demás y le está cediendo sus operaciones a alguien que probablemente ya quedó demasiado grande. Anotá esta idea: en el Módulo 6 vas a ver instrucciones que son exactamente eso, **a propósito**.

Y lo que se cede. Imaginá una variante de los tanques donde el atacante le delega el daño al misil: "manejalo vos". El tanque renuncia a que **sus** subtipos lo hagan distinto: ya no pueden aparecer tanques que calculen el daño a su manera, porque esa lógica se fue a otro lado. Toda delegación es esa renuncia. Por eso delegar es una decisión de diseño y no una regla: estás eligiendo **quién** va a poder variar mañana. En el flujo real de la sección 6, atacante y atacado participan los dos, y cada uno tiene un lugar para decir "yo lo hago así": mañana puede aparecer un tanque nuevo sin tocar a los demás. Si en cambio alguien resolvió todo en un solo método, los demás quedaron sin oportunidad de participar, y toda variación futura va a tener que meterse ahí. Eso es lo que el Módulo 3 llama polimorfismo: delegar bien es lo que lo hace posible.

## 8. 🔴 Invariantes: lo que objetos garantiza y funcional no puede

> En objetos, **sin constructor no hay instancia**. Eso permite garantizar que un objeto nace válido. En funcional, nada te obliga a pasar por un constructor.

Es el primer "para qué" de la sección 4: **preservar invariantes**. Una `Tarea` con un setter que valida que el responsable pueda encargarse:

```scala
class Empleado(val nombre: String, val nivel: Int) {
  def puedeEncargarseDe(tarea: Tarea): Boolean = nivel >= tarea.dificultad
}

class Tarea(val dificultad: Int) {
  private var _responsable: Empleado = null

  def responsable: Empleado = _responsable

  def responsable_=(empleado: Empleado): Unit = {
    if (!empleado.puedeEncargarseDe(this))
      throw new RuntimeException("No le da")
    _responsable = empleado
  }
}

val tarea = new Tarea(5)
tarea.responsable = new Empleado("Bruno", 7)
tarea.responsable.nombre           // Resultado: Bruno
tarea.responsable = new Empleado("Ana", 2)
// Resultado: java.lang.RuntimeException: No le da
tarea.responsable.nombre           // Resultado: Bruno (la asignación inválida quedó afuera)
```

Es el par `a`/`a_=` del Módulo 1: desde afuera parece una asignación, adentro corre la regla. Vive en un solo método, y nadie puede saltearla, porque `_responsable` es privado. Pero falta una puerta: si la tarea nace con responsable, hay que validar también en el constructor. Borrá la `Tarea` de arriba y pegá esta en su lugar; `Empleado` queda como está:

```scala
class Tarea(val dificultad: Int, responsable: Empleado) {
  if (!responsable.puedeEncargarseDe(this))
    throw new RuntimeException("No le da")
  // ...
}

new Tarea(5, new Empleado("Ana", 2))   // Resultado: java.lang.RuntimeException: No le da
```

Es el patrón de siempre en objetos: la misma validación en dos lugares (o el truco de llamar al setter desde el constructor, para escribirla una vez). Lo que objetos garantiza, a cambio, es fuerte: **si el constructor valida, ningún objeto inválido existe**, porque la única forma de tener una instancia es pasar por él.

Ahora pensá cómo harías esto en Haskell. Funcional también encapsula, pero a nivel operación: una función esconde cómo está implementada. Para los datos es otra cosa. Tenés una estructura y querés que toda estructura nazca válida. Lo mejor que podés hacer, con lo que viste en Paradigmas, es una función constructora `mkTarea` que valide. ¿Y qué obliga a la gente a usarla? Nada: cualquiera puede escribir la estructura a mano, saltearse la función, y ahora hay un dato inválido circulando por el sistema. Podés ser estricto en las reglas de equipo, pero el lenguaje mira para otro lado. **En objetos, el constructor es la única puerta.**

Guardá las dos puntas: objetos garantiza invariantes pero necesita validar en dos lugares; funcional puede garantizarlas solo por convención. El Módulo 8 muestra que el híbrido consigue algo que ninguno de los dos tiene por separado: validar en un solo lugar, y que alcance.

**Para el parcial, si te preguntan:** *"¿Qué garantiza objetos sobre los invariantes de un objeto, y por qué funcional no puede?"* Objetos garantiza que todo objeto nace válido y se mantiene válido, porque la única forma de crearlo es el constructor y la única forma de cambiarlo son sus operaciones, y ambos validan. En funcional los datos se construyen directamente: una función constructora que valide es una convención, y nada impide armar la estructura a mano sin pasar por ella.

## 9. 🟡 Lectura guiada: cómo simplifica la solución `puro`

> En esta solución, simplificar es un diálogo **entre una instrucción y la que la sigue**: `simplifiedBefore(next)` devuelve qué queda de las dos. Para decidirlo sin preguntar "¿qué sos?", cada instrucción expone mensajes como `cancelsWithSwap`.

Volvé al contrato de la sección 1. Las reglas del Módulo 1 son todas sobre pares (o sobre "todo lo que sigue"), y en objetos cada instrucción tiene que resolver su parte del par **sin mirar la clase de la vecina**. La forma de hacerlo es preguntarle cosas:

| Regla | Quién pregunta | Qué pregunta | Qué devuelve |
|---|---|---|---|
| `SWAP, SWAP` | el primer `Swap` | `next.cancelsWithSwap` | `Seq()` si sí; los dos si no |
| `LOAD, LOAD` | el primer `Load` | `next.overwritesAWithoutReading` | solo `next` si sí |
| `STORE n, STORE n` | el primer `Store` | `next.overwritesAddress(address)` | solo `next` si sí |
| `IF[]` | el `If` | (simplifica su sub-programa y mira si quedó vacío) | solo `next` si quedó vacío |
| `HALT, x` | el `Halt` | nada | solo `this`, siempre |

Verificado:

```scala
Swap.simplifiedBefore(Swap)                              // Resultado: List()
Swap.simplifiedBefore(Add).map(_.print)                  // Resultado: List(SWP, ADD)
new Load(0).simplifiedBefore(new Load(1)).map(_.print)   // Resultado: List(LOD[1])
new Store(1).simplifiedBefore(new Store(1)).map(_.print) // Resultado: List(STR[1])
new Store(1).simplifiedBefore(new Store(2)).map(_.print) // Resultado: List(STR[1], STR[2])
Swap.cancelsWithSwap                                     // Resultado: true
Add.cancelsWithSwap                                      // Resultado: false
new Store(1).overwritesAddress(1)                        // Resultado: true
```

El `If` tiene dos casos: con una instrucción después, y como última del programa (recorte del archivo, para leer):

```scala
class If(subInstructions: Program) extends Instruction {
  // ...
  override def simplifiedBefore(next: Instruction) = {
    subInstructions.simplify                                    // primero adentro
    if (subInstructions.instructionCount == 0) Seq(next) else super.simplifiedBefore(next)
  }

  override def simplifiedAtTheEnd = {
    subInstructions.simplify
    if (subInstructions.instructionCount == 0) Seq() else super.simplifiedAtTheEnd
  }
}
```

Y el `Program.simplify` (también recorte del archivo) recorre la lista de a pares, reemplazando cada par por lo que `simplifiedBefore` devolvió, y al final le pregunta a la última instrucción qué queda de ella sola. `init` es la lista sin el último elemento; `last`, el último; `drop(n)` saca los primeros `n`:

```scala
def simplify: Unit = {
  var simplified = 0
  while (simplified < instructions.size - 1) {
    val simplifiedPair: Seq[Instruction] = instructions(simplified).simplifiedBefore(instructions(simplified + 1))
    instructions = instructions.take(simplified) ++ simplifiedPair ++ instructions.drop(simplified + 2)
    simplified += 0.max(simplifiedPair.size - 1)   // si el par se achicó, vuelve a mirar la misma posición
  }
  if (instructions.nonEmpty) instructions = instructions.init ++ instructions.last.simplifiedAtTheEnd
}
```

Resuelve los casos del Módulo 1 (lo viste en la sección 1), y tiene un límite: solo avanza. Si un par desaparece, lo que quedó a la izquierda ya fue revisado y queda sin comparar con el nuevo vecino: `LOD[0], SWP, SWP, LOD[1]` queda `LOD[0], LOD[1]`. Es fiel a objetos: nadie pregunta `isInstanceOf`, todo es delegación. Pero mirá lo que costó una regla como "dos `SWAP` seguidos se eliminan": un método `cancelsWithSwap` en la interfaz de **todas** las instrucciones, que casi todas responden `false`, solo para que `Swap` pueda enterarse de que su vecino es otro `Swap` sin preguntarle la clase. Cada regla nueva de simplificación es un mensaje nuevo en la interfaz de `Instruction`. Y cada operación nueva (el "+500" del Módulo 1) es otro `def` en el trait y en las siete clases.

Esa es la tensión que el módulo deja abierta: todo lo que las secciones 2 a 8 defienden (consistencia, ceder control, un responsable, puntos de extensión) se paga acá con una interfaz que crece con cada operación, y con lógica que para resolver un par de instrucciones da varias vueltas de mensajes. El Módulo 3 le pone nombre a esa tensión.

---

## Checkpoint

1. ¿Qué dicen las dos reglas de objetos, y cuál existe para sostener a la otra?
2. ¿Por qué "no accedas a los atributos" no alcanza como definición de encapsulamiento? ¿Qué pasa con esa regla en Scala?
3. ¿Qué problema resuelve el acceso uniforme, y qué tiene que ver con el polimorfismo?
4. `pedido.cliente.direccion.ciudad.provincia.nombre` solo manda mensajes, y quien lo escribe lo necesita para calcular el costo de envío. ¿Por qué rompe el encapsulamiento? ¿Cómo lo escribirías?
5. ¿Por qué `calculadora.mul(9, 7)` es peor que `9 * 7`? Da los dos motivos.
6. En el ejemplo de los tanques, ¿por qué `t1` no puede resolver el ataque solo? ¿Qué hace el doble despacho para destrabarlo, y cuánto cuesta?
7. ¿Por qué en estructurado el ataque entre tanques es fácil? ¿Qué se pierde a cambio?
8. ¿Qué es un God object, qué es un data object, y por qué un objeto con 150 métodos puede estar bien?
9. ¿Qué cede un objeto cuando delega una responsabilidad en otro? ¿Qué gana el otro?
10. ¿Qué garantiza objetos sobre los invariantes de un objeto que funcional no puede garantizar? ¿Y cuántos lugares necesita objetos para hacerlo?
11. En la solución `puro`, ¿para qué existe `cancelsWithSwap` en la interfaz de **todas** las instrucciones? ¿Qué pasa con esa interfaz cada vez que aparece una regla o una operación nueva?

## Qué viene después

**Módulo 3:** la tercera idea, el polimorfismo. Por qué objetos crece tan fácil cuando aparece una estructura nueva, por qué crece tan mal cuando aparece una operación nueva, y el `switch` que objetos te enseñó a tachar.

**FIN DEL MÓDULO 2 — Objetos puros: encapsulamiento y delegación, revisados**
