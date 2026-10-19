# Clase desde cero — Type arguments y varianza en Scala — Módulo 1: Subtipado, de nuevo, y el principio de sustitución

**Unidad:** clase08 · **Lenguaje:** Scala 3.3.1 · **Densidad:** 🟡 se lee de corrido; fija las dos reglas sobre las que se para toda la unidad

---

## Sobre este documento

**Qué cubre.** Las dos reglas del subtipado que ya usaste en la clase anterior, dichas con precisión porque toda esta unidad las va a estirar: **qué objeto se puede guardar en una variable de un tipo** y **qué mensajes deja mandar esa variable**. El caso donde las dos reglas chocan con lo que vos sabés (una vaca loca guardada en una variable `Vaca` no se puede reír). Qué promete el chequeador de tipos a cambio de eso (que el sistema sea *sound*). Y el **principio de sustitución de Liskov**: el nombre formal de la regla, con el ejemplo de la avestruz que compila y rompe, y por qué el compilador no lo puede evitar.

**Qué no cubre.** Colecciones, tipos paramétricos, varianza. Este módulo trabaja con objetos sueltos; el siguiente los mete en un `Set` y ahí empieza el tema nuevo.

## De dónde venís

De la clase anterior: un tipo es el conjunto de mensajes que un objeto entiende (M1); el compilador rechaza programas que funcionarían, y a eso lo llamamos falso negativo (M3); una operación parcial compila y falla en ejecución para algunos valores, como `x / 0` (M3); subtipado, `extends`, `trait` como contrato, `with` y `override` (M4 y M7); `Any` arriba de todo (M4) y `Nothing` abajo de todo (M6); el cast apaga el chequeador en un punto (M8). Y la pregunta con la que terminó esa clase: si `Persona` es subtipo de `Nombrable`, ¿`List[Persona]` es subtipo de `List[Nombrable]`? Este módulo todavía no la responde; prepara el terreno para que la respuesta, en el Módulo 5, se entienda.

---

## 1. 🔴 El dominio: una granja

> Cuatro clases y una jerarquía de dos niveles. `Vaca` y `Caballo` son animales; `VacaLoca` es una vaca. Cada clase agrega un mensaje.

Es el dominio de toda la unidad. El código es `Animales.scala` del proyecto de referencia, tal cual:

```scala
package tadp.granja

class Animal {
  var peso: Int = 100

  def come: Unit = peso += 10

  def estaGordo: Boolean = peso >= 150
}

class Vaca extends Animal {
  def ordeñate: Unit = peso -= 10
}

class VacaLoca extends Vaca {
  def reite: String = "Muajajajjaajja"
}

class Caballo extends Animal {
  def relincha: String = "IEIIEIEeeeeieeie"
}
```

Tres cosas de sintaxis, una línea cada una, para no frenarte después: `peso += 10` es `peso = peso + 10`; un método cuyo resultado se descarta se anota `: Unit`, y `peso += 10` es de ese tipo; `ordeñate` lleva `ñ` y Scala lo acepta como nombre.

```
        ┌────────────────┐
        │     Animal     │
        │ peso           │
        │ come           │
        │ estaGordo      │
        └───────┬────────┘
                │ extends
        ┌───────┴────────┐
        │                │
  ┌─────┴──────┐   ┌─────┴──────┐
  │    Vaca    │   │  Caballo   │
  │ ordeñate   │   │ relincha   │
  └─────┬──────┘   └────────────┘
        │ extends
  ┌─────┴──────┐
  │  VacaLoca  │
  │ reite      │
  └────────────┘
```

Leído como tipos: un objeto `VacaLoca` entiende `reite`, `ordeñate`, `come`, `estaGordo` y `peso`. Un `Caballo` entiende `relincha`, `come`, `estaGordo` y `peso`. Un `Animal` entiende solo los tres últimos. **Subtipo = entiende todo lo del supertipo, y algo más.**

## 2. 🔴 Qué se guarda en qué variable

> Una variable de tipo `X` acepta un objeto de tipo `X` **o de cualquier subtipo de `X`**. Nada más. El compilador lo decide mirando los tipos, antes de ejecutar.

El caso, con el compilador de 3.3.1 al lado:

| Escribís | Scala entiende | Sale |
|---|---|---|
| `val animal: Animal = new Vaca` | guardar una vaca donde se espera un animal | ✅ compila: `Vaca` es subtipo de `Animal` |
| `val vaca: Vaca = new VacaLoca` | guardar una vaca loca donde se espera una vaca | ✅ compila: `VacaLoca` es subtipo de `Vaca` |
| `val animal: Animal = new Caballo` | guardar un caballo donde se espera un animal | ✅ compila |
| `val vaca: Vaca = new Animal` | guardar un animal donde se espera una vaca | ❌ `Found: tadp.granja.Animal` / `Required: tadp.granja.Vaca` |
| `val caballo: Caballo = new Vaca` | guardar una vaca donde se espera un caballo | ❌ `Found: tadp.granja.Vaca` / `Required: tadp.granja.Caballo` |

El compilador imprime los nombres completos (`tadp.granja.Animal`) porque las clases viven en el paquete `tadp.granja` (Módulo 0). Leé `Found` como "lo que me diste" y `Required` como "lo que la variable pide".

**Por qué la regla es esa.** Una variable de tipo `Vaca` existe para mandarle mensajes de vaca: `ordeñate`. La regla "solo subtipos" existe para que todo `vaca.ordeñate` del programa llegue a un objeto que lo entiende. Con una `VacaLoca` adentro, `ordeñate` anda: las vacas locas son vacas. Con un `Animal` adentro, en algún lugar del programa `vaca.ordeñate` llegaría a un objeto que lo ignora, y explotaría en ejecución; por eso el compilador frena la asignación.

`Caballo` y `Vaca` están al mismo nivel: cada uno es subtipo de `Animal`, y entre ellos hay solo parentesco, así que una variable de uno rechaza al otro. La relación de subtipo va **hacia arriba** en la jerarquía, nunca hacia los costados.

Vale igual con `var`:

```scala
  var vaca: Vaca = new Vaca
  vaca = new VacaLoca                 // una vaca loca es una vaca, y entiende los mensajes de Vaca
  vaca.ordeñate
  println(vaca.peso)                  // Resultado: 90
```

Los tests 1 y 2 de `GranjaTest.scala` verifican estas dos asignaciones: un `Animal = new Vaca` que come pesa 110; una `Vaca = new VacaLoca` que se ordeña pesa 90.

## 3. 🔴 Qué mensajes deja mandar: la vaca loca que no se puede reír

> Una variable deja mandar **los mensajes de su tipo declarado**, y solo esos. Lo que el objeto sepa de más, a través de esa variable **es invisible**.

Seguí el caso con atención, porque es el primer lugar donde el compilador rechaza algo que vos sabés que funcionaría:

```scala
  val vaca: Vaca = new VacaLoca       // adentro hay una vaca loca; la variable deja mandar lo de Vaca y lo de Animal
  vaca.ordeñate
  vaca.come
  vaca.reite                          // ❌ no compila
```

| Escribís | Scala entiende | Sale |
|---|---|---|
| `vaca.ordeñate` con `vaca: Vaca` | mandar un mensaje de `Vaca` a una `Vaca` | ✅ |
| `vaca.come` con `vaca: Vaca` | mandar un mensaje de `Animal` a una `Vaca`, que es un `Animal` | ✅ |
| `vaca.reite` con `vaca: Vaca` | mandar un mensaje de `VacaLoca` a una `Vaca` | ❌ `value reite is not a member of tadp.granja.Vaca` |
| `animal.ordeñate` con `animal: Animal = new Vaca` | mandar un mensaje de `Vaca` a un `Animal` | ❌ `value ordeñate is not a member of tadp.granja.Animal` |

**Por qué.** Vos sabés que adentro de `vaca` hay una `VacaLoca`, porque lo escribiste en la línea de arriba. El compilador **deja eso de lado**. Al asignar, chequea que lo que entra sea subtipo (sección 2); para los mensajes, después, mira solo el tipo declarado de la variable: `Vaca`. Y una `Vaca` entiende `ordeñate` y `come`, pero `reite` le es ajeno. El programa correría bien (el objeto sí sabe reírse); el compilador lo rechaza. Es exactamente el **falso negativo** de la clase anterior, en su forma más común: un programa válido, rechazado.

¿Por qué el compilador ignora la línea de arriba? Porque en general es imposible seguirla. La variable pudo haber sido asignada en otro archivo, en otro método, según una condición que solo se conoce en ejecución. Lo único garantizado en **todo** programa posible es el tipo declarado, así que es lo único sobre lo que el compilador razona. Esa limitación es deliberada, y la sección siguiente dice qué compra.

**El mismo objeto, visto desde tres variables.** Esto deja claro que el tipo es de la variable, y el objeto es uno solo:

```scala
  val vacaLoca: VacaLoca = new VacaLoca
  val vaca: Vaca = vacaLoca            // la misma vaca loca, vista como Vaca
  val animal: Animal = vaca            // la misma vaca loca, vista como Animal

  vacaLoca.reite                       // ✅ desde acá se ríe
  vaca.ordeñate                        // ✅ desde acá se ordeña (y pesa 90)
  animal.come                          // ✅ desde acá come (y vuelve a 100)

  println(s"${vacaLoca.peso} ${vaca.peso} ${animal.peso}")
  // Resultado: 100 100 100     ← es un solo objeto; las tres variables lo apuntan
```

(`s"…${x}…"` es una cadena con interpolación: lo que va entre `${}` se evalúa y se pega en el texto.) Un objeto, tres variables, tres "anchos" de interfaz. El objeto es el mismo; cambia **qué te deja hacer la variable** por la que lo mirás.

> **Para el parcial, si te preguntan**
> *¿Por qué `val vaca: Vaca = new VacaLoca; vaca.reite` no compila, si el objeto sabe reírse?* — Porque el compilador solo conoce el tipo declarado de la variable, `Vaca`, y `reite` es un mensaje de `VacaLoca`. Que en ejecución haya una `VacaLoca` es algo que el compilador puede garantizar solo en algunos casos, así que lo deja de lado en todos. Es un falso negativo: un programa válido que el chequeo estático rechaza.

## 4. 🔴 Lo que el chequeador promete: *sound*

> Un sistema de tipos es **sound** (seguro) cuando **todo programa que pasa el chequeo manda, en ejecución, solo mensajes que sus objetos entienden**. Es la promesa. A cambio, rechaza programas que funcionarían.

Las dos reglas anteriores son las dos mitades de esa promesa:

- Solo entran subtipos (sección 2): entonces lo que hay en la variable **siempre** entiende los mensajes del tipo declarado.
- Solo salen mensajes del tipo declarado (sección 3): entonces **siempre** se mandan mensajes que el objeto entiende.

Con las dos juntas, si el programa compila, cada línea le manda a cada objeto un mensaje que entiende. Ese es todo el negocio del tipado estático. Y el precio es el de la sección 3: la vaca loca que no se ríe. El compilador prefiere rechazar un programa válido antes que aceptar uno que pueda explotar. Dicho con las dos clases de error de la clase anterior: un sistema *sound* está libre de falsos positivos (programas que pasan y explotan), y paga eso con falsos negativos.

Con una salvedad que ya conocés: donde vos apagás el chequeador a mano (el cast de la clase anterior, `asInstanceOf`), la promesa deja de correr en ese punto. Por eso el cast se evita.

Guardá esta idea, porque en el Módulo 5 va a aparecer un rechazo que parece un error del compilador, y la primera pregunta va a ser: ¿está rompiendo la promesa, o está cumpliéndola y yo todavía veo solo una parte?

## 5. 🔴 El principio de sustitución de Liskov

> Si `S` es subtipo de `T`, un objeto de `S` tiene que poder **reemplazar** a uno de `T` en cualquier lugar donde se use un `T`, **sin romper** a quien lo usa. Para eso, `S` tiene que poder hacer todo lo que `T` define en su interfaz.

Hasta acá, "subtipo" era "entiende todos los mensajes del supertipo". El principio de sustitución de Liskov (por Barbara Liskov, que lo formuló) le agrega la parte que queda fuera de la vista del compilador: **entenderlos es el piso; además hay que cumplirlos**. El caso, en `Aves.scala`:

```scala
package tadp.granja

class Ave {
  def vola: String = "vuelo"

  def come: String = "como"
}

class Avestruz extends Ave {
  override def vola: String = throw new UnsupportedOperationException("las avestruces no vuelan")

  def meteLaCabezaBajoTierra: String = "cabeza bajo tierra"
}
```

`throw new UnsupportedOperationException("…")` interrumpe la ejecución lanzando una excepción con ese mensaje; es la forma de decir "este método está fuera de servicio". `Avestruz` hereda `vola` de `Ave` y lo redefine para que falle: una avestruz es un ave, y las avestruces caminan.

Mirá qué hace el compilador con esto:

```scala
  val ave: Ave = new Avestruz          // ✅ compila: Avestruz es subtipo de Ave
  println(ave.come)                    // ✅ Resultado: como
  println(ave.vola)                    // ✅ compila: vola es un mensaje de Ave
  // en ejecución: java.lang.UnsupportedOperationException: las avestruces no vuelan
```

(Dentro de un `object … extends App`, la primera línea que se ve es `java.lang.ExceptionInInitializerError`; la causa, que es esta excepción, aparece debajo.)

| Escribís | Scala entiende | Sale |
|---|---|---|
| `val ave: Ave = new Avestruz` | guardar una avestruz donde se espera un ave | ✅ compila |
| `ave.vola` | mandar un mensaje de `Ave` a un `Ave` | ✅ compila; ❌ al correr: `UnsupportedOperationException: las avestruces no vuelan` |

**Las dos reglas se cumplieron y el programa explotó igual.** `Avestruz` entiende `vola` (lo tiene, lo heredó); el chequeo de mensajes está satisfecho. Lo que rompe es el **contrato**: quien tiene un `Ave` espera que `vola` vuele, y recibe una excepción. `Avestruz` reemplaza a `Ave` rompiendo a quien lo usa. Viola el principio de sustitución.

Y la promesa de la sección 4 sigue en pie: `vola` fue entendido; lo que explotó es una decisión del método, igual que `x / 0` o `head` de una lista vacía en la clase anterior. Es una operación parcial, y eso queda fuera de la promesa del chequeador.

**El compilador deja Liskov a tu cargo.** Chequea que los mensajes existan, y lo que hacen queda afuera. Que un método "funcione como se espera" es una propiedad del comportamiento, y el comportamiento está fuera de los tipos. Por eso este programa compila: desde el punto de vista del chequeador, es correcto. Liskov es un **criterio de diseño**, tuyo.

Y ahora las dos reglas de las secciones 2 y 3 se leen mejor. ¿Por qué `val vaca: Vaca = new Animal` se rechaza? Porque un `Animal` reemplazaría a una `Vaca` rompiendo a quien le pida `ordeñate`. El compilador aplica Liskov **hasta donde puede verlo**: los mensajes. El resto es tuyo.

El test 3 de `GranjaTest.scala` verifica esto con `intercept[UnsupportedOperationException] { ave.vola }`: la excepción está ahí, y el test la espera.

**Qué se hace con la avestruz.** La solución es **prometer solo lo que se cumple**. Si solo algunas aves vuelan, `vola` pertenece a esas, y a `Ave` le queda `come`. Con lo que ya sabés de la clase anterior, un `trait` es un contrato que se mezcla solo donde corresponde:

```scala
trait Volador {
  def vola: String = "vuelo"
}

class Ave {
  def come: String = "como"
}

class Paloma extends Ave with Volador        // un ave que vuela (una clase sin cuerpo se escribe sin llaves)

class Avestruz extends Ave {                 // un ave que camina, y promete solo eso
  def meteLaCabezaBajoTierra: String = "cabeza bajo tierra"
}
```

Probalo en un archivo aparte, fuera del paquete `tadp.granja`, o con los nombres cambiados: el proyecto ya tiene un `Ave` con `vola` en `Aves.scala`, y el test 3 depende de él. (En las tablas, el `;` separa dos sentencias escritas en una misma línea, y los nombres de los errores llevan adelante el paquete donde pongas el archivo.)

| Escribís | Scala entiende | Sale |
|---|---|---|
| `val paloma: Paloma = new Paloma; println(paloma.vola)` | una paloma vuela | ✅ Resultado: `vuelo` |
| `val ave: Ave = new Avestruz; println(ave.come)` | un ave come | ✅ Resultado: `como` |
| `val ave: Ave = new Avestruz; ave.vola` | mandar `vola` a un `Ave` | ❌ `value vola is not a member of Ave` (`Ave` ya promete solo `come`) |
| `val v: Volador = new Avestruz` | usar una avestruz como voladora | ❌ `Found: Avestruz` / `Required: Volador` |

Lo que antes explotaba en ejecución, ahora **se frena al compilar**. Ese es el movimiento que vas a repetir toda la unidad: cuando algo falla en ejecución, buscar el tipo que, bien puesto, lo hubiera frenado antes.

> **Para el parcial, si te preguntan**
> *Aparece `class Avestruz extends Ave` con `override def vola = throw …`. ¿Compila? ¿Está bien? ¿Qué harías?* — Compila: `Avestruz` entiende `vola`, y el compilador solo verifica mensajes. Está mal: viola el principio de sustitución de Liskov, porque un `Avestruz` reemplaza a un `Ave` rompiendo a quien le mande `vola`. Rediseño: sacar `vola` de `Ave` y ponerlo en un `trait Volador` que solo mezclen las aves que vuelan. Así `ave.vola` sobre un `Ave` deja de compilar, que es lo que corresponde: el error pasa de ejecución a compilación.

## 6. 🟡 Lo que viene

> Con un objeto suelto, las dos reglas alcanzan. El problema empieza cuando el objeto está **adentro de otra cosa**.

Hasta acá todo se decide mirando una variable y una clase. En el Módulo 2 la vaca va a estar adentro de un `Set`, y la pregunta "¿qué mensajes le puedo mandar a lo que saco de ahí?" necesita algo más: si el tipo fuera solo `Set`, a secas, callaría sobre sus elementos. Esa falta es la que motiva el tema de la unidad.

---

## Checkpoint (sin respuestas)

1. ¿Qué objetos acepta una variable de tipo `Vaca`? Da uno que sí y dos que no, con el error de cada uno.
2. ¿Qué mensajes acepta una variable de tipo `Vaca`? Nombrá uno de `Vaca`, uno de `Animal` y uno de `VacaLoca`, y decí cuál se rechaza.
3. `val vaca: Vaca = new VacaLoca; vaca.reite`. ¿Qué sabés vos que el compilador deja de lado? ¿Por qué lo deja de lado?
4. Un objeto apuntado por tres variables de tipos `VacaLoca`, `Vaca` y `Animal`. ¿Qué cambia entre las tres? ¿Qué se mantiene?
5. ¿Qué promete un sistema de tipos *sound*? ¿Qué paga a cambio? Relacionalo con falsos positivos y falsos negativos. ¿Dónde deja de valer la promesa?
6. Enunciá el principio de sustitución de Liskov con tus palabras. ¿Qué parte de ese principio verifica el compilador y qué parte queda a tu cargo?
7. `Avestruz` compila y explota al volar. ¿Qué regla viola? ¿Rompe la promesa *sound*? ¿Cómo lo rediseñás para que el error aparezca al compilar?
8. ¿Por qué `val vaca: Vaca = new Animal` se rechaza, dicho en términos de sustitución?

## Qué viene después

El Módulo 2 pone una vaca, un caballo y un granero en un mismo `Set`, intenta filtrar los gordos, y descubre que el conjunto ignora qué contiene. Ahí aparece la primera herramienta nueva de la unidad: decirle al tipo del conjunto **de qué** es.

**FIN DEL MÓDULO 1**
