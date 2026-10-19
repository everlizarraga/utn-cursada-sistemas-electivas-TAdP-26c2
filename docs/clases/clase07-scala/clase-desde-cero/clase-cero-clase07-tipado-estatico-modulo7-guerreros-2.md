# Clase desde cero — Tipado estático en Scala — Módulo 7: Guerreros II — muralla y misil, traits como contratos

**Unidad:** clase07 · **Lenguaje:** Scala 3.3.1 · **Densidad:** 🔴 una sesión con el proyecto abierto

---

## Sobre este documento

**Qué cubre.** Los dos tests que faltan: la muralla, que se defiende y no ataca, y el misil, que ataca y no se defiende. Para hacerlos pasar hace falta lo del Módulo 4 aplicado al dominio: dos traits, **`Defensor`** y **`Atacante`**, con métodos abstractos que las clases cumplen. Cómo se **componen** varios traits con `with` y en qué orden se resuelven (linearización). Por qué `energia = 1000` va **en el cuerpo** de la clase y no como `val`. La regla que faltaba sobre `val` y `def`: **un `val` puede implementar un `def`; un `def` no puede pisar un `val`**. Y `Espadachin`, para ver `override` con `super`.

**Qué no cubre.** El casteo y los tipos paramétricos (Módulo 8).

## De dónde venís

Del Módulo 6: el `Guerrero` mutable con `atacaA` y `.max(0)`, los cuatro tests, `Unit`. Del Módulo 4: trait con método abstracto, contrato fuerte, `override`. Del Módulo 5: la regla "parámetros lo más arriba posible". De clase02: mixins y linearización, en Ruby.

---

## 1. 🔴 La muralla no es un guerrero

> `atacaA` pide un `Guerrero`. Una `Muralla` **no lo es**, aunque tenga energía y defensa. Para que entre hacen falta **dos cambios, juntos**: un tipo común, y que `atacaA` lo pida.

Descomentá la línea del tercer test:

```scala
    g1.atacaA(m)
```

```
Found:    tadp.ageofempires.Muralla
Required: tadp.ageofempires.Guerrero
```

Es el mismo problema del `Asistente` (Módulo 3) con otros nombres. Y ya sabés que la solución pasa por un tipo común que los dos incorporen (Módulo 4). Lo que conviene tener claro antes de tocar nada es que hay **dos cambios** y hacer uno solo no sirve:

| Cambiás | Sale |
|---|---|
| Solo la firma: `atacaA(otro: Defensor)` | `Not found: type Defensor` (todavía no existe), y aunque existiera, `Muralla` no sería uno |
| Solo la jerarquía: `Muralla extends Defensor` | `Found: Muralla / Required: Guerrero`: la firma sigue pidiendo `Guerrero` |
| Los dos | ✅ |

Eso es general: cuando un parámetro quedó **demasiado restringido** y necesitás ampliarlo, casi siempre hay que (a) definir o elegir el tipo más amplio y (b) hacer que las clases lo incorporen y que la firma lo pida. El orden da igual; las dos cosas, no.

## 2. 🔴 `Defensor`: lo que recibe daño

> Un **`Defensor`** es cualquier cosa con energía que sabe cuánta defensa tiene y qué hace al recibir daño. Lo primero es estado concreto; lo otro, dos **métodos abstractos** que cada clase define a su manera.

```scala
// src/main/scala/tadp/ageofempires/Defensor.scala
package tadp.ageofempires

trait Defensor {
  var energia: Int = 100                  // estado concreto: todo defensor arranca con 100

  def potencialDefensivo: Int             // abstracto: cada defensor dice el suyo
  def recibeDanio(danio: Int): Unit       // abstracto: cada defensor decide cómo le pega el daño
}
```

Un trait puede tener **estado** (`var energia`), como los mixins de clase02. Lo que lo hace un contrato son los dos `def` sin cuerpo.

Ahora `Guerrero` lo incorpora. Primer intento, sin tocar nada más:

```scala
class Guerrero(val potencialOfensivo: Int = 20) extends Defensor {
  var energia: Int = 100                 // ← ya viene de Defensor
  var potencialDefensivo: Int = 10
  def atacaA(otro: Guerrero): Unit = { /* … */ }
}
```

El compilador marca dos cosas, y conviene leerlas con cuidado:

| Qué | Sale | Por qué |
|---|---|---|
| `var energia` repetido en `Guerrero` | `variable energia cannot override a mutable variable` | `Defensor` ya tiene esa variable; una variable mutable no se redefine (sección 3). Se borra la de `Guerrero`: la hereda |
| `var potencialDefensivo: Int = 10` | ✅ sin error | Cumple el `def potencialDefensivo: Int` abstracto. Un `var` también es un mensaje que devuelve un `Int` (Módulo 6) |
| Falta `recibeDanio` | `class Guerrero needs to be abstract, since def recibeDanio(danio: Int): Unit in trait Defensor is not defined` | El contrato fuerte del Módulo 4: prometiste ser `Defensor`, falta implementar algo |

Se arregla cumpliendo el contrato y moviendo la lógica donde corresponde:

```scala
package tadp.ageofempires

class Guerrero(val potencialOfensivo: Int = 20) extends Defensor {
  val potencialDefensivo: Int = 10                    // val: nada lo modifica, y cumple el def igual

  def recibeDanio(danio: Int): Unit = {               // lo que antes estaba adentro de atacaA
    this.energia = (this.energia - danio).max(0)
  }

  def atacaA(otro: Defensor): Unit = {                // ← el tipo más arriba que resuelve el problema
    otro.recibeDanio(this.potencialOfensivo - otro.potencialDefensivo)
  }
}
```

Tres decisiones en ese código:

- **`atacaA(otro: Defensor)`**: la regla del Módulo 5. `atacaA` necesita `potencialDefensivo` y `recibeDanio`; `Defensor` es lo más arriba que los tiene.
- **`recibeDanio` en el atacado, no en el atacante.** Antes `atacaA` restaba la energía ajena a mano. Ahora el atacante calcula el daño y el atacado decide qué hacer con él. Cada clase es dueña de su estado.
- **`potencialDefensivo` pasa a `val`**: era `var` en el esqueleto del Módulo 6 y nada lo modifica. Un `val` cumple el `def` abstracto exactamente igual que un `var`.

```
[info] - un guerrero ataca a otro guerrero                                 ✅  100 − (20 − 10) = 90
[info] - un guerrero con mucho potencial ofensivo ataca a otro guerrero    ✅  (100 − 190).max(0) = 0
```

## 3. 🔴 `Muralla`: estado inicial en el cuerpo de la clase

> El **cuerpo de una clase** en Scala es la **inicialización de cada instancia**: lo que escribís suelto adentro se ejecuta cada vez que hacés `new`. Por eso, para que la muralla arranque con otra energía, se **asigna** en el cuerpo: `energia = 1000`.

La `Muralla` del Módulo 6 tenía su propio `val energia = 1000` y compilaba porque no heredaba de nadie. Ahora que es `Defensor`, `energia` ya viene de arriba, y eso cambia las reglas:

```scala
// src/main/scala/tadp/ageofempires/Muralla.scala
package tadp.ageofempires

class Muralla extends Defensor {
  this.energia = 1000                                 // asignación: corre al construir cada muralla

  val potencialDefensivo: Int = 0                     // una muralla no se defiende; absorbe

  def recibeDanio(danio: Int): Unit = {
    this.energia = (this.energia - danio / 10).max(0) // le entra un décimo del daño
  }
}
```

Esto es distinto de Ruby, y vale detenerse: en Ruby, el código suelto en el cuerpo de una clase **se le manda a la clase**, que es un objeto, una sola vez, al cargar el archivo (así funcionaban `attr_accessor` y las open classes). En Scala **las clases no son objetos**: el cuerpo es el constructor, y corre **por instancia**. `this.energia = 1000` le pone 1000 a *esta* muralla, usando el setter que `var energia` generó en `Defensor`.

Las otras formas que se te pueden ocurrir, y por qué fallan:

| Escribís en `Muralla` | Sale | Por qué |
|---|---|---|
| `val energia = 1000` | `error overriding variable energia in trait Defensor; value energia needs `override' modifier` y, con `override`, `value energia cannot override a mutable variable` | `energia` ya existe arriba y es mutable; un `val` solo tiene getter y no puede reemplazar algo que tiene getter y setter |
| `override var energia = 1000` | `variable energia cannot override a mutable variable` | Las variables mutables no se redefinen: sería pisar una variable con otra |
| `energia = 1000` (o `this.energia = 1000`) | ✅ | Es una **asignación**, no una definición: usa el setter heredado |

```
[info] - un guerrero ataca a una muralla     ✅  daño 20 − 0 = 20 → 1000 − 20 / 10 = 998
```

Y un test más, el natural para `energia = 1000` en el cuerpo:

```scala
  test("una muralla recien construida tiene 1000 de energia") {
    val m = new Muralla

    m.energia shouldBe 1000           // ✅ el cuerpo de la clase corrió al hacer new
  }
```

**Una nota de diseño.** `recibeDanio` está implementado dos veces: en `Guerrero` (resta todo) y en `Muralla` (resta un décimo). Acá tiene sentido porque la lógica **es distinta**. Si las dos restaran igual, el lugar correcto sería **`Defensor`**, una sola vez, concreto, y las clases solo definirían su `potencialDefensivo`. Tener un método abstracto es una decisión: lo usás cuando cada implementación es de verdad otra.

> **Para el parcial, si te preguntan**
> *¿Dónde va `recibeDanio`: en `Defensor` o en cada clase?* — Depende de si la lógica es la misma. Si todo defensor resta el daño igual, va concreto en `Defensor`, una vez. Si cada defensor lo procesa distinto (la muralla absorbe un décimo), queda abstracto en `Defensor` y cada clase lo implementa. Un método abstracto declara que la implementación varía; si no varía, es duplicación.

## 4. 🔴 `Atacante` y el misil: componer traits con `with`

> Un **`Atacante`** es cualquier cosa con potencial ofensivo que sabe atacar a un `Defensor`. El misil ataca y no se defiende; el guerrero hace las dos cosas: **incorpora los dos traits**, con `extends … with …`.

Descomentá `misil.atacaA(muralla)`: `value atacaA is not a member of Misil`. El misil tiene que poder atacar, y la lógica de atacar ya está escrita en `Guerrero`. En vez de copiarla, va a un trait:

```scala
// src/main/scala/tadp/ageofempires/Atacante.scala
package tadp.ageofempires

trait Atacante {
  def potencialOfensivo: Int                          // abstracto: cada atacante dice el suyo

  def atacaA(defensor: Defensor): Unit = {            // concreto: la lógica de atacar, una sola vez
    if (defensor.potencialDefensivo < this.potencialOfensivo) {
      defensor.recibeDanio(this.potencialOfensivo - defensor.potencialDefensivo)
    }
  }
}
```

Con una mejora: el `if`. Si la defensa supera al ataque, no hay daño (antes el daño daba negativo y **sumaba** energía). Ahora el guerrero y el misil:

```scala
// Guerrero.scala
class Guerrero(val potencialOfensivo: Int = 20) extends Defensor with Atacante {
  val potencialDefensivo: Int = 10

  def recibeDanio(danio: Int): Unit = {
    this.energia = (this.energia - danio).max(0)
  }
  // atacaA ya no está acá: viene de Atacante. potencialOfensivo (val) cumple el def abstracto.
}

// Misil.scala
class Misil(val anioFabricacion: Int) extends Atacante {
  def potencialOfensivo: Int = (2016 - anioFabricacion) * 10   // calculado: cumple el def abstracto
}
```

```
[info] - un misil ataca a una muralla     ✅  (2016 − 1966) × 10 = 500 → 500 − 0 = 500 → 1000 − 500 / 10 = 950
```

Los cinco tests pasan (los cuatro originales y el de la muralla recién construida).

**`with`.** `extends A with B with C` incorpora varios traits en una clase. Es la composición de mixins de clase02, con otra palabra. Y como en clase02, importa el **orden de resolución** cuando dos traits definen lo mismo:

> **Linearización en Scala:** se resuelve **de derecha a izquierda** en la declaración, y **la superclase siempre queda última**.

| Declarás | Orden en que se busca un método |
|---|---|
| `class G extends Defensor with Atacante` | `G`, `Atacante`, `Defensor` |
| `class G extends Defensor with Atacante with Volador` | `G`, `Volador`, `Atacante`, `Defensor` |
| `class G extends UnaClase with A with B` | `G`, `B`, `A`, `UnaClase` (la clase, última) |

En este dominio no hay conflicto (`Defensor` y `Atacante` definen cosas distintas), así que el orden no cambia nada. Cuando lo haya, la regla es esa.

**¿CÓMO FUNCIONA?** `misil.atacaA(muralla)`: `atacaA` está en `Atacante`; `Misil` lo heredó. Adentro, `this.potencialOfensivo` se resuelve en `Misil` (500). `defensor.potencialDefensivo` se le manda a la muralla a través de la referencia `Defensor`: responde 0. Como 0 < 500, se manda `recibeDanio(500)` por la misma referencia, y quien responde es **la implementación de `Muralla`** (un décimo): 1000 − 50 = 950. `Atacante` nunca supo que era una muralla; solo que era un `Defensor`. Eso es polimorfismo con tipos.

## 5. 🔴 `val` puede implementar `def`; `def` no puede pisar `val`

> Un **`val` cumple un `def`** porque su contrato es más fuerte: siempre devuelve lo mismo, y "lo mismo" es un caso particular de "algo". Al revés falla: un **`def` no puede reemplazar a un `val`**, porque podría devolver algo distinto cada vez y rompería la promesa del `val`.

Ya lo usaste tres veces sin pensarlo: `val potencialDefensivo` cumple `def potencialDefensivo`; `val potencialOfensivo` del guerrero cumple `def potencialOfensivo` de `Atacante`; `val nombre` cumplía `def nombre` en el Módulo 4. La dirección opuesta:

```scala
class Espada(val potencialOfensivo: Int)                 // un val: la espada siempre vale lo mismo

class SuperEspada extends Espada(50) {
  override def potencialOfensivo: Int = scala.util.Random.nextInt(100)   // ← cambia en cada llamada
}
```

```
error overriding value potencialOfensivo in class Espada of type Int;
  method potencialOfensivo needs to be a stable, immutable value
```

Quien tiene una `Espada` cuenta con que `potencialOfensivo` devuelve siempre lo mismo (por eso es `val`). `SuperEspada` prometió ser una `Espada` y quiere devolver un número al azar: rompe el contrato, y el compilador lo frena. Un `val` es más restrictivo que un `def`: cumple todo lo que un `def` promete y algo más. Por eso puede ir donde se pide un `def`, y un `def` no puede ir donde se pide un `val`.

| Arriba | Abajo | Sale |
|---|---|---|
| `def x: Int` (abstracto o concreto) | `val x: Int = …` (con `override` si el de arriba es concreto) | ✅ |
| `def x: Int` | `def x: Int = …` (con `override` si el de arriba es concreto) | ✅ |
| `val x: Int` | `override val x: Int = …` | ✅ |
| `val x: Int` | `override def x: Int = …` | ❌ `method x needs to be a stable, immutable value` |
| `val x: Int` | `override val x: Int = super.x + 1` | ❌ `super may not be used on value x` |

La última fila es la que muerde cuando querés **redefinir sumando algo al valor del padre**, y es la entrada a la sección siguiente.

## 6. 🟡 `Espadachin`: redefinir con `super`

> Un espadachín es un guerrero cuyo potencial ofensivo es **el suyo más el de su espada**. Redefinir sumando al valor heredado pide `override def` y `super`, y para eso lo heredado tiene que ser un **`def`**.

```scala
// src/main/scala/tadp/ageofempires/Espadachin.scala
package tadp.ageofempires

class Espada(val potencialOfensivo: Int)

class Espadachin(espada: Espada, _potencialOfensivo: Int = 20)
  extends Guerrero(_potencialOfensivo) {

  override def potencialOfensivo: Int =
    super.potencialOfensivo + espada.potencialOfensivo     // el mío, más el de la espada
}
```

Para que esto compile, `Guerrero` tiene que cambiar: `potencialOfensivo` deja de ser un `val` del constructor y pasa a ser un **`def`**, porque sobre un `val` no se puede usar `super` (sección 5). Así queda el `Guerrero` definitivo:

```scala
// src/main/scala/tadp/ageofempires/Guerrero.scala
package tadp.ageofempires

class Guerrero(_potencialOfensivo: Int = 20) extends Defensor with Atacante {
  val potencialDefensivo: Int = 10

  def potencialOfensivo: Int = _potencialOfensivo      // def: Espadachin puede redefinirlo con super

  def recibeDanio(danio: Int): Unit = {
    this.energia = (this.energia - danio).max(0)
  }
}
```

El parámetro se llama `_potencialOfensivo` para no pisar al método `potencialOfensivo` (la misma convención del Módulo 4). Desde afuera nada cambió: `new Guerrero(200)` sigue valiendo y `g.potencialOfensivo` sigue respondiendo; solo que ahora es un `def`.

```scala
  test("un espadachin ataca a un guerrero") {
    val zorro = new Espadachin(new Espada(20))
    val conan = new Guerrero

    zorro.atacaA(conan)

    conan.energia shouldBe 70            // ✅  (20 + 20) − 10 = 30 → 100 − 30 = 70
  }
```

## 7. 🟡 Cierre: los problemas son los mismos

> El código al que llegaste en Scala se parece mucho al de clase01 en Ruby: los métodos están en el mismo lugar, las decisiones de diseño son las mismas. Lo que cambió es que ahora **hay que explicitar** lo que antes se asumía.

Dos cosas más que el tipado cambia en la forma de trabajar:

- **El rojo marca un ritmo.** En Ruby escribías asumiendo cómo iban a ser las cosas y lo descubrías al correr. Acá cada decisión de tipo incompleta te frena en el momento: un parámetro demasiado restringido, un contrato sin cumplir. Los problemas son los mismos; aparecen antes.
- **Hay cosas que ya no tiene sentido testear.** "La muralla no puede atacar" era un requerimiento, y en Ruby podías escribir un test que verificara que `Muralla` no entiende `atacaA`. Acá sobra: `muralla.atacaA(guerrero)` **no compila** (`value atacaA is not a member of Muralla`), así que el programa que viola el requerimiento queda fuera.

Este es el estado final del dominio, el mismo del código de la unidad: `Defensor` y `Atacante` como contratos, `Guerrero` con los dos, `Muralla` solo defensor, `Misil` solo atacante, `Espadachin` redefiniendo con `super`. Seis tests, todos en verde.

> **Para el parcial, si te preguntan**
> *Aparece un requerimiento nuevo: una `Torre` que ataca y se defiende, con potencial ofensivo fijo de 30 y defensa de 50. ¿Qué escribís y qué no tocás?* — `class Torre extends Defensor with Atacante` con `val potencialOfensivo = 30`, `val potencialDefensivo = 50` y su `recibeDanio`. Quedan intactos `atacaA`, `Atacante`, `Defensor` y todos los tests existentes: `Torre` consiente los dos contratos y entra donde se pida cualquiera de los dos tipos. Los `val` cumplen los `def` abstractos.

---

## Checkpoint (sin respuestas)

1. ¿Por qué `g1.atacaA(m)` no compila con `m: Muralla`? ¿Qué dos cambios hacen falta y por qué uno solo no alcanza?
2. ¿Qué tiene de concreto y qué de abstracto el trait `Defensor`?
3. ¿Qué error da dejar `var energia` en `Guerrero` cuando `Defensor` ya lo define? ¿Y cuál da no implementar `recibeDanio`?
4. ¿Por qué `energia = 1000` va en el cuerpo de `Muralla` y no como `val energia = 1000`? ¿Qué es el cuerpo de una clase en Scala, y en qué se diferencia de Ruby?
5. ¿Cuándo un método va abstracto en el trait y cuándo concreto? Usá `recibeDanio` como ejemplo.
6. ¿Qué hace `with`? ¿En qué orden se resuelven los métodos en `class G extends Defensor with Atacante with Volador`?
7. Explicá paso a paso qué pasa en `misil.atacaA(muralla)`, incluido quién responde `recibeDanio`.
8. ¿Por qué un `val` puede implementar un `def` y un `def` no puede redefinir un `val`?
9. ¿Qué error da `override val x = super.x + 1`? ¿Qué hubo que cambiar en `Guerrero` para que `Espadachin` compile?
10. ¿Por qué no hace falta un test que verifique que la muralla no ataca?

## Qué viene después

**Módulo 8:** la última herramienta y el puente a la clase que viene. Qué pasa cuando el chequeador rechaza algo que vos *sabés* que funciona, qué es castear, por qué no lo vas a usar, y qué invento hizo que dejara de ser necesario.

**FIN DEL MÓDULO 7**
