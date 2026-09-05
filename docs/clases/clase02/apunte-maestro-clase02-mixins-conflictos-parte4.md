# 📘 APUNTE MAESTRO — clase02 · Mixins: resolución de conflictos
## Parte 4 — Age of Empires: el descanso, el kamikaze y el guerrero que hace dos cosas

*Al terminar esta parte vas a poder tomar un conflicto real entre dos mixins y resolverlo de tres formas distintas —orden de inclusión, cadena con centinela, `alias_method`—, saber cuándo cada una se rompe, y elegir con fundamento. Es la bajada a tierra de todo lo anterior, y es lo que se parece a lo que vas a hacer en el TP.*

---

## 1. 🔴 El modelo, ahora con mixins

La transición desde la clase 1 es una palabra. Donde decía `class Atacante` ahora dice `module Atacante`, y donde `Guerrero` no podía heredar de dos cosas, ahora incluye dos módulos. La sintaxis interna no cambia nada.

```ruby
module Atacante
  attr_accessor :potencial_ofensivo

  def atacar(un_defensor)
    if self.potencial_ofensivo > un_defensor.potencial_defensivo
      danio = self.potencial_ofensivo - un_defensor.potencial_defensivo
      un_defensor.sufri_danio(danio)              # requiere que el otro sepa sufrir daño
    end
  end
end

module Defensor
  attr_accessor :potencial_defensivo, :energia

  def sufri_danio(danio)
    self.energia = self.energia - danio
  end
end

class Guerrero
  include Atacante
  include Defensor                                 # último → gana en conflictos (Parte 2)

  def initialize(potencial_ofensivo = 20, energia = 100, potencial_defensivo = 10)
    self.potencial_ofensivo  = potencial_ofensivo
    self.energia             = energia
    self.potencial_defensivo = potencial_defensivo
  end
end

class Misil
  include Atacante
  def initialize(potencial_ofensivo = 200)
    self.potencial_ofensivo = potencial_ofensivo
  end
end

class Muralla
  include Defensor
  def initialize(potencial_defensivo = 50, energia = 200)
    self.potencial_defensivo = potencial_defensivo
    self.energia             = energia
  end
end
```

Dos aclaraciones de Ruby que hacen falta: **no se puede heredar de un módulo** (`class X < Atacante` falla; la herencia es una relación entre clases), y **un módulo puede incluir otros módulos** (lo vas a necesitar en la Sección 7).

El diagrama, con la notación completa de la Parte 2:

```
┌──────────────────────┬───┐                  ┌──────────────────────┬───┐
│       Atacante       │   │                  │       Defensor       │   │
├──────────────────────┼───┤                  ├──────────────────────┼───┤
│ potencial_ofensivo   │   │                  │ potencial_defensivo  │   │
│ atacar               │   │                  │ energia              │   │
└──────────────────────┴───┘                  │ sufri_danio          │   │
      ▲▲          ▲                           └──────────────────────┴───┘
      ││           ╲                                ▲▲▲          ▲▲
      ││            ╲                              ╱             ││
┌─────┴┴─────┐       ╲                            ╱        ┌─────┴┴─────┐
│   Misil    │        ╲    ┌──────────────┐     ╱          │  Muralla   │
└────────────┘         ╲───┤   Guerrero   ├────╱           └────────────┘
                           └──────────────┘
```

Mirá las puntas de `Guerrero`: **tres hacia `Defensor`, una hacia `Atacante`.** Es el dibujo correcto de `include Atacante` seguido de `include Defensor`: el guerrero es *más defensor que atacante*.

### La decisión que no estás preparado para tomar

Esa relación entre los dos mixins **no existe en la naturaleza**. `Atacante` y `Defensor` no tienen nada que ver entre sí; es cada clase la que decide cómo los vincula. Y `Guerrero` está obligada a decidirlo ahora, por sintaxis, aunque hoy no haya ningún conflicto que lo justifique.

Es exactamente la situación de la Parte 2, Sección 4. Si no te importa, dejalo documentado:

```ruby
class Guerrero
  include Atacante
  include Defensor
  # Orden arbitrario: hoy no hay conflicto entre Atacante y Defensor.
  # Si aparece uno, revisar esta decisión.
```

Si el día de mañana aparece un conflicto que tendría que resolverse eligiendo al atacante, esta implementación es peor que la contraria. Y la herramienta no te da forma de decir "por ahora no me importa": solo el comentario, y en el mejor de los casos un test que se rompa si das vuelta el orden.

> 🟡 **¿Y componer en vez de incluir?** Podrías modelar el guerrero como un objeto que *tiene* un atacante y un defensor adentro, y delega. Es la salida de siempre y es legítima. La diferencia: la composición es una relación **blanda** —el guerrero conoce a alguien— mientras que la inclusión es una relación **dura**: el guerrero *es* atacante, cambia su interfaz, responde `atacar` él mismo. Cuál conviene depende de si en tu dominio el guerrero es un atacante o tiene uno. Modelar con clases y modelar con mixins no difiere en mucho más que eso; el código hasta es el mismo, cambiaste una palabra clave.

---

## 2. 🔴 Aparece el Kamikaze

**Requerimiento.** *Banzai!* El kamikaze se comporta como un atacante y un defensor. Su potencial ofensivo es 250, pero **después de atacar su energía queda en 0**.

### ¿Hace falta una clase?

El reflejo es "aparece una entidad, va una clase". Y la primera opción que se te ocurre es `class Kamikaze < Guerrero`: se comporta muy parecido a un guerrero.

Pero frená. **Nunca se dijo que el kamikaze y el guerrero estuvieran relacionados.** Se dijo que se comportan parecido. Y fijate qué es `Guerrero` ahora: una clase que **no define comportamiento propio**, solo incorpora dos mixins y los instancia. ¿Es una entidad del dominio, o es simplemente la clase que creaste para poder instanciar esa combinación? La pregunta cambió mucho.

Si el vínculo es solo conductual, una implementación perfectamente válida es que `Kamikaze` incluya los mismos dos mixins. No es copiar y pegar al guerrero, aunque un poco lo parece: **es linearizar activamente**, y el control del orden es tuyo. Podés decidir que el kamikaze es más atacante que defensor, que es lo contrario de lo que decidió el guerrero.

Y una tercera opción que ni siquiera requiere una clase: el kamikaze podría ser **un mixin** —el delta que convierte a un guerrero en kamikaze— que se le aplica a alguna clase. En tecnologías donde se puede armar una clase anónima en el momento, eso es muy común.

> **Lo que cambió:** la respuesta automática *"nuevo comportamiento → nueva clase"* es mentira ahora, porque hay más lugares donde poner comportamiento. Mucho de lo que tenías seguro sobre cómo trabajar cambió, y hay que construir criterio nuevo.

### La implementación

```ruby
class Kamikaze
  include Defensor
  include Atacante                    # último → el kamikaze es MÁS ATACANTE que defensor
  # Lookup: Kamikaze -> Atacante -> Defensor -> Object

  def initialize(energia = 100, potencial_defensivo = 10)
    self.potencial_ofensivo  = 250
    self.energia             = energia
    self.potencial_defensivo = potencial_defensivo
  end

  def atacar(un_defensor)
    super(un_defensor)                # hace lo que hace cualquier atacante...
    self.energia = 0                  # ...y después muere
  end
end

# ¿CÓMO FUNCIONA?
kamikaze = Kamikaze.new               # po 250, energia 100, pd 10
muralla  = Muralla.new                # pd 50, energia 200
kamikaze.atacar(muralla)              # 250 > 50 → danio 200 → muralla.sufri_danio(200)
muralla.energia                       # Resultado esperado: 0
kamikaze.energia                      # Resultado esperado: 0
```

Ese `super` en `atacar` es el `super` dinámico de la Parte 2: `Kamikaze` no sabe quién tiene el `atacar` de verdad; sabe que alguien en la cadena lo tiene.

```
┌────────────────┬──┐                       ┌────────────────┬──┐
│    Atacante    │  │                       │    Defensor    │  │
└────────────────┴──┘                       └────────────────┴──┘
   ▲▲    ▲▲▲       ▲                          ▲▲▲       ▲      ▲▲
   ││    │  ╲       ╲                        ╱         ╱       ││
┌──┴┴──┐ │   ╲       ╲──────────────────────╱         ╱     ┌──┴┴───┐
│Misil │ │    ╲                            ╱         ╱      │Muralla│
└──────┘ │     ╲──────────────────╲       ╱         ╱       └───────┘
    ┌────┴─────┐               ┌───╲─────┴──┐      ╱
    │ Kamikaze │               │  Guerrero  ├─────╱
    └──────────┘               └────────────┘
```

Las diagonales se cruzan porque cada uno prioriza al contrario: el kamikaze manda tres puntas al atacante, el guerrero tres al defensor.

---

## 3. 🔴 El requerimiento que rompe: descansar

**Requerimiento.** *El descanso de la guerra.* Todas las unidades pueden descansar. Cuando un **atacante** descansa, **duplica su potencial ofensivo en su próximo ataque**. Cuando un **defensor** descansa, **suma 10 de energía**.

### Cada mixin resuelve lo suyo, y todo compila

```ruby
module Defensor
  attr_accessor :potencial_defensivo, :energia

  def sufri_danio(danio)
    self.energia = self.energia - danio
  end

  def descansar
    self.energia += 10                          # descansar como defensor
  end
end

module Atacante
  attr_accessor :potencial_ofensivo, :descansado

  def atacar(un_defensor)
    if self.potencial_ofensivo > un_defensor.potencial_defensivo
      danio = self.potencial_ofensivo - un_defensor.potencial_defensivo
      un_defensor.sufri_danio(danio)
    end
    self.descansado = false                     # el bonus dura UN ataque
  end

  def potencial_ofensivo
    self.descansado ? @potencial_ofensivo * 2 : @potencial_ofensivo   # el getter aplica el bonus
  end

  def descansar
    self.descansado = true                      # descansar como atacante
  end
end

# ¿CÓMO FUNCIONA? — un atacante solo
misil = Misil.new(200)
misil.descansar                                 # descansado = true
misil.potencial_ofensivo                        # Resultado esperado: 400
misil.atacar(Muralla.new)                       # 400 > 50 → danio 350; descansado = false
misil.potencial_ofensivo                        # Resultado esperado: 200
```

Fijate cómo se implementó el bonus del atacante: no se toca el valor guardado, se **redefine el getter** `potencial_ofensivo` para que devuelva el doble mientras `descansado` sea verdadero. Es un detalle de Ruby que vale conocer: `attr_accessor` genera un getter, y vos podés pisarlo con un `def` propio que lea la variable de instancia `@potencial_ofensivo` directamente.

### Por qué nadie vio el conflicto

Ahora imaginate cómo llega este requerimiento a un equipo real. El enunciado dice "los atacantes hacen esto, los defensores hacen esto otro". Se paraleliza: un desarrollador implementa `descansar` en `Atacante`, otro en `Defensor`. **En ninguna de las dos ramas hay conflicto**, porque cada uno tocó su módulo. Cada uno escribe sus tests, con misiles y con murallas, y pasan.

Se mergea. Primero el atacante, todo bien. Después el defensor, todo bien. Y ahora hay dos `descansar` disponibles para el `Guerrero`, y **nada explotó**: la linearización resolvió el conflicto en silencio, y el guerrero descansa como defensor, porque es más defensor que atacante.

¿Quién lo detecta? Si el que hizo el atacante fue tan meticuloso de testear también con guerreros, un test. Si no, nadie, hasta que alguien de producto llame porque *"mis guerreros atacan flojito: los hago descansar y descansar y atacan igual"*. Y como el efecto es un número que cambia poco, tardan en darse cuenta. Recién ahí alguien investiga caso por caso y aparece el requerimiento real.

> ⚠️ **Si esto fuera traits, no hubiera compilado.** Hubiéramos tenido que resolver el conflicto del guerrero, el del kamikaze y el de todas las inclusiones. Pero también lo hubiéramos *detectado*. Es un punto a favor de la resolución manual: te obliga a mirar. El punto a favor de la automática es el que sigue: si estaba bien cableado, ya funciona para la mayoría de los casos, y solo hay que revisar los particulares.

### Los tres casos particulares

Con las cadenas de linearización a la vista, lo que el dominio realmente quiere:

```
   Misil    → Atacante → Object              descansa como atacante ✔ (ya funciona)
   Muralla  → Defensor → Object              NO debe hacer nada
   Kamikaze → Atacante → Defensor → Object   descansa SOLO como atacante
   Guerrero → Defensor → Atacante → Object   descansa de LAS DOS formas
```

- **Muralla no hace nada.** Tiene que *poder* recibir el mensaje —la querés en una colección de defensores y mandarles `descansar` a todos— pero es la operación nula.
- **Kamikaze descansa solo como atacante.** No tiene sentido que gane energía: cuando ataca, muere.
- **Guerrero hace las dos cosas.**

Misil ya anda. Los otros tres son los que siguen.

---

## 4. 🔴 Caso 1 — La muralla no hace nada

Muralla hoy descansa y gana energía. No debería. La solución no requiere ninguna herramienta nueva: es la misma sobreescritura de siempre, porque **la herencia y los mixins no son distintos desde el punto de vista del lookup.** Te parás en el lugar correcto de la cadena y hacés nada.

```ruby
class Muralla
  include Defensor

  def initialize(potencial_defensivo = 50, energia = 200)
    self.potencial_defensivo = potencial_defensivo
    self.energia             = energia
  end

  def descansar
  end                                            # vacío: el lookup para acá y no llega a Defensor#descansar
end

# ¿CÓMO FUNCIONA?
muralla = Muralla.new
muralla.descansar
muralla.energia                                  # Resultado esperado: 200 (sin cambios)
```

Sobreescritura, especialización, cualquier concepto que aplicaba a herencia aplica acá igual. Si nunca llegás al método, nunca tenés el problema.

---

## 5. 🔴 Caso 2 — El kamikaze descansa solo como atacante

Mirá la cadena: `Kamikaze → Atacante → Defensor`. El lookup encuentra primero el `descansar` de `Atacante` y **se detiene ahí**, porque ese método no llama a `super`. El kamikaze ya descansa solo como atacante. **Sin escribir una línea.**

```ruby
# ¿CÓMO FUNCIONA?
kamikaze = Kamikaze.new                          # po 250, energia 100
kamikaze.descansar                               # Atacante#descansar: descansado = true. Defensor nunca corre
kamikaze.potencial_ofensivo                      # Resultado esperado: 500
kamikaze.energia                                 # Resultado esperado: 100 (sin cambios)
```

Esto funciona porque la decisión de orden que tomaste en la Sección 2 **estaba alineada con la naturaleza** del kamikaze. Cuando te cae un requerimiento así hay dos opciones: *joya*, o *uy qué mal*. O el orden que elegiste a ciegas coincide con lo que el dominio quiere, o no.

### Si hubiera estado al revés

Supongamos que el kamikaze había quedado como el guerrero, más defensor que atacante. La solución inmediata es obvia: dar vuelta los dos `include`. Pero **eso es un cambio mayor** (Parte 2, Sección 4): no sabés cuánto de tu dominio depende hoy de esa relación. Lo que corresponde:

1. Buscar si hay un comentario que diga "este orden es arbitrario". Si está, lo das vuelta, corrés los tests, borrás el comentario porque ahora sí importa.
2. Si no, agarrar todo el mixin, toda la jerarquía de mixins que incluye, y ver **qué conflictos se están resolviendo hoy** hacia ese lado. Cualquier conflicto que encuentres cambia de comportamiento.
3. Si hay conflictos, viene un refactor: o el mixin era demasiado grande y hay que partirlo —y ya tenías que refactorizar de todos modos—, o caíste en el caso raro donde una entidad de verdad quiere resolver una cosa para un lado y otra para el otro.

Es la misma situación que en herencia cuando una clase de pronto quiere heredar de otra: no cambiás la flecha y listo, mirás todas las subclases para no fallarle a una garantía.

---

## 6. 🔴 Caso 3 — El guerrero hace las dos cosas

Acá se acaba lo automático. **No hay ninguna solución automática que admita "quiero hacer las dos cosas"**, porque incluso hacer las dos cosas implica una secuencia: primero una, después la otra. Justo en este dominio la secuencia es irrelevante, pero combinar comportamiento nunca es apendear y ya.

Necesitás una solución, y vas a ver dos:

- **Una elegante**, que sirve con mixins puros —sin ninguna herramienta extra— siempre y cuando se alineen de la forma correcta.
- **Una muy particular de Ruby**, usando herramientas que complementan lo que los mixins traen de fábrica.

---

## 7. 🔴 Solución A — La cadena con `super`, y el centinela

### El primer intento: `super` en el defensor

¿Qué herramienta tenés para decir "hacé lo tuyo y seguí"? `super`. El `Guerrero` encuentra primero `Defensor#descansar`; si ese método hace lo suyo y llama a `super`, el `super` dinámico sigue por la cadena y cae en `Atacante#descansar`. Las dos cosas.

```ruby
module Defensor
  def descansar
    self.energia += 10
    super                                        # "seguí con el que venga atrás"
  end
end
```

Los tests del guerrero pasan. Pero ese cambio está hecho en `Defensor`, y `Defensor` lo usan otros:

```
   Misil    → Atacante ● → Object                 sin super: nunca pasa por acá ✔
   Muralla  → Defensor ● → ??? → Object           super → nadie tiene descansar → NoMethodError ✗
   Kamikaze → Atacante ● → Defensor → Object      Atacante no llama super: frena ✔
   Guerrero → Defensor ● → Atacante ● → Object    super → Atacante#descansar ✔
```

**Rompiste la muralla.** Bueno: la muralla ya sobreescribía `descansar` con un método vacío, así que en realidad no llega a `Defensor#descansar`. Pero cualquier otro defensor que no lo sobreescriba explota, porque el `super` sale hacia `Object` y `Object` no entiende `descansar`.

### La objeción que arregla todo: un centinela

Si el problema es que *ahí no hay nada*, la salida es poner algo. Algo que tenga `descansar`, que no haga nada, y que esté ahí para atajar el `super`. Se llama **centinela**, o **terminador**; a veces lo vas a encontrar como *null module*, o con otros nombres. Es algo que **corta la cadena de llamados**: *"bueno, hasta acá llegué"*.

```ruby
module Unidad
  def descansar
  end                                            # no hace nada y NO llama a super: acá termina
end
```

¿Dónde lo incluís? Primera idea: que `Muralla` incluya `Unidad` antes que `Defensor`, para que quede detrás.

```ruby
class Muralla
  include Unidad
  include Defensor                               # Muralla → Defensor → Unidad → Object ✔
end
```

Funciona. Pero es muy artesanal: tenés que acordarte de meter el corte en cada clase que use un mixin con `super`. Segunda idea, más natural: **que `Defensor` incluya `Unidad`**, y así el corte viene puesto.

```ruby
module Defensor
  include Unidad                                 # un mixin incluyendo un mixin
  def descansar
    self.energia += 10
    super
  end
end
```

Y acá viene la objeción que hay que ver antes de seguir. Linearizá el guerrero con esto:

```
   Guerrero → Defensor ● → Unidad → Atacante → Object
                        └──super──▶ Unidad#descansar: vacío, sin super. FIN.
```

**Acabás de romper al guerrero.** `Unidad` quedó pegada detrás de `Defensor`, y ahora el `super` de `Defensor` cae en la caja que no hace nada **antes** de llegar a `Atacante`. El guerrero descansa como defensor y nada más.

### La solución que justifica "el último gana"

Ahora mirá lo que pasa si **los dos mixins incluyen al centinela**, y los dos llaman a `super`:

```ruby
module Unidad
  def descansar
  end
end

module Atacante
  include Unidad
  attr_accessor :potencial_ofensivo, :descansado

  def atacar(un_defensor)
    if self.potencial_ofensivo > un_defensor.potencial_defensivo
      danio = self.potencial_ofensivo - un_defensor.potencial_defensivo
      un_defensor.sufri_danio(danio)
    end
    self.descansado = false
  end

  def potencial_ofensivo
    self.descansado ? @potencial_ofensivo * 2 : @potencial_ofensivo
  end

  def descansar
    self.descansado = true
    super                                        # hago lo mío y sigo
  end
end

module Defensor
  include Unidad
  attr_accessor :potencial_defensivo, :energia

  def sufri_danio(danio)
    self.energia = self.energia - danio
  end

  def descansar
    self.energia += 10
    super                                        # hago lo mío y sigo
  end
end

class Guerrero
  include Atacante
  include Defensor                               # sin incluir Unidad: ya viene con los mixins
  def initialize(potencial_ofensivo = 20, energia = 100, potencial_defensivo = 10)
    self.potencial_ofensivo  = potencial_ofensivo
    self.energia             = energia
    self.potencial_defensivo = potencial_defensivo
  end
end
```

Linearizá el guerrero **antes de limpiar** con la regla de la Parte 2:

```
   Guerrero → Defensor → Unidad → Atacante → Unidad → Object
                          ╳ (primera aparición: se tacha)
   Guerrero → Defensor → Atacante → Unidad → Object
```

`Unidad` aparece dos veces. **Se preserva la última.** Y entonces:

```
   Guerrero → Defensor ● → Atacante ● → Unidad ● → Object
                        └─super──▶    └─super──▶  vacío: FIN
              energia += 10        descansado = true
```

**Las dos especializaciones hacen lo suyo, cada una llama hacia adelante, y el factor común queda al final atajando.** Esto es exactamente para lo que sirve que la linearización elimine la primera aparición y no la última: para que cada mixin pueda decir `super` sin miedo, con la garantía de que **siempre hay uno atrás** que frena.

Todas las cadenas, con esto:

```
   Misil    → Atacante ● → Unidad ● → Object                     ✔
   Muralla  → Defensor ● → Unidad ● → Object   (+ su override)   ✔
   Guerrero → Defensor ● → Atacante ● → Unidad ● → Object        ✔ las dos cosas
```

```ruby
# ¿CÓMO FUNCIONA?
Guerrero.ancestors                    # => [Guerrero, Defensor, Atacante, Unidad, Object, Kernel, BasicObject]
atila = Guerrero.new                  # po 20, energia 100, pd 10
conan = Guerrero.new
atila.descansar                       # Defensor: energia 110, super → Atacante: descansado true, super → Unidad: nada
atila.energia                         # Resultado esperado: 110
atila.atacar(conan)                   # po = 40 > 10 → danio 30
conan.energia                         # Resultado esperado: 70
```

> ✗ **Trampa.** Si en vez de meter `Unidad` en los mixins la incluís vos en la clase, tiene que ser **el primer `include`**, para que quede al fondo:
> ```ruby
> class Guerrero
>   include Unidad      # ✔ primero → última en el lookup
>   include Atacante
>   include Defensor
> end
> # con include Unidad al FINAL, Unidad queda primera en el lookup: el guerrero no hace nada.
> ```

Y una ventaja más, menos visible: **ahora podés usar `Atacante` y `Defensor` sin miedo.** Antes, si alguien incluía `Defensor` y se olvidaba de `Unidad`, su código eventualmente se rompía. Ahora el corte viaja con el mixin.

### Se llama Cake Pattern

Esto tiene nombre: **Cake Pattern**, el patrón torta, por las capas. (Podría haberse llamado patrón cebolla; los nombres son malos.) Es **uno de los patrones más exitosos de la nueva ola** —los que no están en el libro clásico de patrones de objetos— y hoy es casi la implementación por defecto en decenas de frameworks para cualquier cosa que se combine de formas variables, afecte ligeramente una conducta, y donde el orden importe. Es rarísimo ver otra implementación.

**Y solo se puede hacer con mixins.** Necesita tres cosas de la tabla:

1. `super` **dinámico**: que "el siguiente" lo cablee la clase, no la jerarquía.
2. **Linearización que preserva el último**: para que el terminador quede al fondo aunque lo incluyan varios.
3. **Que los módulos estén vivos en runtime**: si aplanaste, no hay cadena. Si estás en Java, no existe: tenés `super`, pero es el de la superclase, y nada de esto funciona.

> 🕳️ **Madriguera — Los patrones se mueren**
> Un patrón es un lugar donde la tecnología te soltó la mano: no tenías herramienta para resolver algo, lo hiciste a mano, salió bien, y lo escribiste. A medida que las tecnologías incorporan esas soluciones como features, los patrones mueren. Singleton no tiene sentido en un lenguaje donde podés crear un objeto solo. El Cake Pattern es, en ese sentido, la respuesta a un patrón anterior que nunca terminó de funcionar: el de la sección siguiente.
> *Volvé al camino.*

> ⚠️ **Advertencia.** Esto se mostró como una **astucia**: para que veas la cantidad de oportunidades de diseño que se abren con la herramienta. **No se va a pedir.** No siempre vas a implementar un Cake Pattern para que algo haga dos cosas; muchas veces hay alternativas más fáciles (Sección 10). Pero entenderlo es entender por qué la linearización se hace como se hace.

---

## 8. 🟡 De dónde viene: el Decorator y sus dos fallas

El Cake Pattern se parece mucho, en otro nivel de abstracción, a un patrón clásico que conviene conocer: **Decorator**.

### Qué es

Ponés muchos objetos uno atrás del otro, cada uno de una clase distinta, todos implementando la misma interfaz. Cada uno hace **un puchito** y llama al siguiente. Y el último es un objeto que toma una acción sin llamar a nadie, o que directamente no hace nada.

```
   mensaje m ──▶ [Decorator1] ──▶ [Decorator2] ──▶ [Decorator3] ──▶ [Final]
                   puchito 1        puchito 2        puchito 3        corta
```

Es una manera de armar construcciones muy dinámicas. El ejemplo típico: modelar el menú de una hamburguesería donde cualquiera puede decir "ponele mostaza, sacale lechuga, ponele queso". Cada modificación es un objeto que decora al anterior; al final le preguntás el precio al primero y el cálculo atraviesa toda la cadena.

> 🕳️ **Madriguera — Builder no es un Decorator**
> Builder es un patrón de construcción: te da una interfaz para armar un objeto en etapas, con chequeos, y el objeto final puede ser cualquier cosa. Podría usarse para *crear* un decorator, pero no es un caso particular de él. Un objeto siempre tiene que nacer consistente.
> *Volvé al camino.*

### Por qué el mundo lo rechaza

Es un patrón hermoso en el papel y el mundo real lo rechaza: en veinte años uno lo mete dos veces y uno lo saca. Tiene dos fallas de fondo:

- **Pierde la identidad.** Modelás una sola idea con muchos objetos. Entonces perdés una facultad obvia del objeto, la autorreferencia: **ninguno de los decoradores puede mandarse un mensaje a `self`**, porque `self` cuando llegaste al tercero no es el mismo `self` al que le mandaron el mensaje. Y no podés volver a empezar la cadena, porque cada objeto solo conoce al que tiene atrás. Cuando uno dice "yo soy el 10% del precio... ¿de qué precio?", todo se complica.
- **Las combinaciones son caóticas.** Tenés que pensar todas las combinaciones posibles para que cada uno mantenga un estado que se pueda comunicar hacia atrás. En el momento en que te vas del escenario de "una operación y nada más", el cuerpo lo rechaza.

### Qué arregla el Cake Pattern

**Tiene todo lo bueno del Decorator sin perder la identidad.** Podés crear cada parte que hace su puchito y llama al anterior, pero **hay un solo objeto**: la multiplicidad y la secuencia se dan a nivel de la *definición de la clase*, no a nivel de instancias. Un objeto recibe un mensaje, y la cadena vive en su linearización. Toda la insatisfacción de no poder usar Decorator se canalizó en usar esto.

---

## 9. 🟡 El límite: el kamikaze se vuelve a romper

Con el Cake Pattern armado, volvé a mirar al kamikaze. Su cadena es ahora:

```
   Kamikaze → Atacante ● → Defensor ● → Unidad ● → Object
                        └─super──▶   └─super──▶
```

`Atacante#descansar` ahora llama a `super`, y el `super` cae en `Defensor`. **El kamikaze gana energía al descansar.** Rompiste el Caso 2, que andaba solo.

La intuición dice: meto `Unidad` **en el medio**, explícitamente, entre los dos, para cortar antes de llegar al defensor:

```ruby
class Kamikaze
  include Defensor
  include Unidad          # ← ¿corta acá?
  include Atacante
end
```

Linearizá con la regla, antes de limpiar:

```
   Kamikaze → Atacante → Unidad → Unidad → Defensor → Unidad → Object
                          ╳         ╳                  (última: queda)
   Kamikaze → Atacante → Defensor → Unidad → Object
```

**No corta.** El `Unidad` del medio es una aparición repetida, y la regla preserva la última: el corte se va al fondo, y el kamikaze sigue descansando como defensor. (Ruby, concretamente, directamente ignora un `include` de un módulo que ya está en la cadena.) La intuición del "corte en el medio" es exactamente el tipo de cosa que la linearización explícita no garantiza: **incluir algo vos no pesa lo mismo que cuando lo incluyen tus sub-elementos**, y el algoritmo, cuando plancha, se queda con una sola copia.

Lo que corresponde en el kamikaze es **sobreescribir `descansar`** y hacer un llamado directo a lo que quiere. Con lo que tenés hasta acá, la forma de llamar *específicamente* al `descansar` de `Atacante` y no al de la cadena es la de la sección siguiente; la forma prolija, que le habla al método por su nombre y su módulo, es tema de metaprogramación (clase 3).

> **La lección:** el Cake Pattern asume que **todos los participantes quieren toda la cadena.** Una unidad que quiere solo un tramo tiene que salirse del patrón y resolverlo aparte. No es un defecto del patrón; es su alcance.

---

## 10. 🔴 Solución B — `alias_method`, o el álgebra a mano

El mundo no es puro. Tenés las herramientas para hacer mixins, pero también tenés un equipo que a lo mejor ve un Cake Pattern y se queda rascándose la cabeza. Y a veces solo querías que algo haga dos cosas. Ruby te deja hacerlo de otra manera.

### El mecanismo

Acordate: Ruby es **destructivo** y **cada línea trabaja sobre el contexto de la anterior**. Entonces, entre un `include` y el otro, podés hacer cosas. `alias_method` **crea una copia de un método existente con otro nombre**: no borra el original, solo agrega un método más que hace lo mismo.

```ruby
class Guerrero
  include Atacante                                  # ahora Guerrero responde descansar → el de Atacante
  alias_method :descansar_atacante, :descansar     # copio ESE descansar con un nombre nuevo
  #             ↑ nombre nuevo      ↑ nombre viejo (el que existe en este momento)

  include Defensor                                  # ahora descansar → el de Defensor (pisó el nombre)
  alias_method :descansar_defensor, :descansar     # copio ESTE con otro nombre

  def initialize(potencial_ofensivo = 20, energia = 100, potencial_defensivo = 10)
    self.potencial_ofensivo  = potencial_ofensivo
    self.energia             = energia
    self.potencial_defensivo = potencial_defensivo
  end

  def descansar                                     # y ahora sobreescribo descansar para que llame a los dos
    self.descansar_atacante
    self.descansar_defensor
  end
end

# ¿CÓMO FUNCIONA?
atila = Guerrero.new
atila.descansar                       # descansar_atacante: descansado true; descansar_defensor: energia 110
atila.energia                         # Resultado esperado: 110
atila.potencial_ofensivo              # Resultado esperado: 40
```

Fijate que **con los alias solos no resolviste nada**: lo que tenés son tres métodos —`descansar_atacante`, `descansar_defensor` y `descansar`, que sigue siendo el de `Defensor` porque fue el último en pisar el nombre. Recién cuando **sobreescribís `descansar`** conseguís el comportamiento que querías.

Esto es, literalmente, **un álgebra de traits hecha a mano**: renombrar era una de las operaciones de Ducasse. Ruby no eligió: te dio mixins *y* te dio herramientas de álgebra, y vos decidís cómo usarlas. Esa no-decisión introduce una ambigüedad: vas a ver librerías de Ruby que se basan en una cosa y librerías que se basan en la otra, y para integrarte a cada una vas a tener que hacerlo a su manera.

### Lo que cuesta

Esto es una **chanchada**, y hay que decirlo con esa palabra.

- **Ensucia la interfaz.** Ahora el guerrero tiene tres métodos públicos que responden a "descansar", dos de los cuales nadie debería llamar. Podés hacerlos privados, y ni así ayuda del todo.
- **Es rústico.** `alias_method` copia el código y le pone otra firma. No es inteligente. Si el método era recursivo —si `descansar` llamaba a `descansar`—, la copia `descansar_atacante` sigue llamando a `descansar`, o sea al de `Defensor`. No se renombró por adentro.
- **No hay `super`, no hay combinación dinámica.** Es una implementación más rabiosa, pero también más simple: no depende de que las cadenas se alineen.

### La variante híbrida

Como el último módulo incluido queda como ancestro inmediato, podés hacer `super` hacia él y usar alias solo para los demás:

```ruby
class Guerrero
  include Atacante
  alias_method :descansar_atacante, :descansar
  include Defensor                                  # Defensor es el ancestro inmediato

  def descansar
    self.descansar_atacante                         # el de Atacante, por su alias
    super                                           # el de Defensor, por super
  end
end
```

Y se generaliza: con N módulos que comparten un método, hacés `super` para el último incluido y `alias_method` para todos los demás.

### Lo que Ruby no te da

En Scala existe el **`super` nominal**: en vez de solo `super` podés orientarlo a un mixin concreto, algo como `super[Atacante].descansar` seguido de `super[Defensor].descansar`. Es lo mismo que el alias, pero sin ensuciar la interfaz, porque el lenguaje lo soporta. Ruby no provee ese acceso como sintaxis. A partir de la clase 3 vas a poder programártelo vos.

---

## 11. 🔴 ¿Cuál usar?

Hemos llegado al **depende**. Y el depende tiene contenido:

- **Lo que tenés disponible en el lenguaje.** Java no tiene ninguna de las dos. Ruby tiene las dos. Scala tiene Cake Pattern y `super` nominal.
- **Las herramientas conceptuales que conoce tu equipo.** Si venís trabajando con mixins hace rato, un Cake Pattern es probablemente **la solución más probada, más consistente y más predecible**: no tiene ninguno de los problemas de la clase 1 de ensuciar interfaz o repetir. Si el equipo está flojo, meter un Cake Pattern no se esconde ni con agua: el alias es más rústico, pero cualquiera lo lee.
- **Cuántas cosas y con qué orden.** Si algo se combina de muchas formas, afecta ligeramente una conducta, y el orden importa: Cake Pattern, sin pensarlo. Si solo querías que una clase haga dos cosas: hay alternativas más fáciles.

Y hay una tercera salida que ni siquiera usa nada de esto: **extraer los dos comportamientos con nombres distintos desde el origen.** Que `Atacante` defina `descansar_como_atacante` y `Defensor` `descansar_como_defensor`, y que `descansar` llame a los dos. No hay conflicto porque no hay dos métodos con el mismo nombre. Es simple, y también es ensuciar la interfaz. Todo vuelve a la Parte 1 de la clase 1.

> **Para el diseño:** lo que vas a tener es lo que hay en el lenguaje, lo que sabe tu equipo, y el problema concreto. Si conocés el mapa —qué implica trabajar con una cosa o con la otra— no importa qué combinación te toque.

---

## 12. 🔴 Lo que Age of Empires enseñó

Cerrá el módulo con esto en la cabeza:

1. **Incluir dos mixins te obliga a decidir un orden que hoy no importa y mañana sí.** Documentá lo arbitrario. Cambiarlo después es un cambio mayor.
2. **La resolución automática resuelve la mayoría de los casos y esconde el resto.** Los tests son tu única red: testeá cada combinación, no solo el caso que implementaste.
3. **Sobreescribir sigue funcionando igual.** Muralla no necesitó nada nuevo.
4. **`super` dinámico + preservar el último + módulos vivos = Cake Pattern.** Es el mejor argumento a favor de la linearización, y no existe sin ella.
5. **Todo patrón tiene alcance.** El kamikaze quiere un tramo de la cadena y el Cake Pattern no se lo da; se sale y resuelve aparte.
6. **Ruby te da el álgebra también.** `alias_method` es resolución manual a mano: funciona, ensucia, y no depende de que nada se alinee.
7. **"¿Hace falta una clase?" dejó de tener respuesta automática.** Hay más lugares donde poner comportamiento.

Y la tesis que cruza toda la materia: **estas herramientas nacieron de un problema concreto —una entidad que quiere ser dos cosas— y cada una lo resuelve pagando algo distinto.** Saber qué paga cada una es lo que te deja elegir.

> 🕳️ **Madriguera — Persistir jerarquías con mixins**
> Las tablas de una base relacional no tienen subtipado; representar herencia ya exige decidir entre componer tablas (una por entidad, con joins) o aplanar (todo replicado). Con traits, lo natural es aplanar. Con mixins es un poco más complejo, pero no mucho: la tabla no sabe cuántas superclases tenés, así que el problema es el mismo. Si las combinaciones son muy dinámicas, la respuesta suele ser una base no relacional. Es artesanal, y excede la materia.
> *Volvé al camino.*

---

## 📝 Para el parcial, si te preguntan

*Las preguntas de esta materia son de diseño: "aparece este requerimiento, ¿dónde lo ponés, con qué herramienta y por qué".*

**Aparece una unidad nueva que ataca y defiende. ¿Clase que hereda de Guerrero, clase con sus propios `include`, o mixin?**
Depende de si el vínculo con el guerrero es del dominio o solo conductual. Si el guerrero no define comportamiento propio, heredar de él no aporta nada y te ata a su orden de inclusión. Incluir los dos mixins en una clase nueva me deja decidir mi propio orden —y ese orden es una decisión de diseño que hay que documentar—. Si lo único que quiero es el delta, puede ser un mixin.

**Un método nuevo aparece en dos mixins que una clase incluye. ¿Qué pasa y qué hago?**
Compila y corre: la linearización elige el del último `include`. Primero verifico si eso coincide con lo que el dominio quiere para esa clase. Si quiere solo uno, el orden lo resuelve o lo sobreescribo. Si no quiere ninguno, sobreescribo con un método vacío. Si quiere los dos, hay que combinar a mano: cadena con `super` y centinela, o `alias_method`.

**¿Por qué la linearización preserva la última aparición y no la primera?**
Para que varios mixins puedan incluir un mismo módulo terminador y llamar a `super` con la garantía de que el terminador queda al fondo, después de todos. Si se preservara la primera, el corte quedaría en el medio y las especializaciones posteriores nunca correrían.

**¿Cuándo el Cake Pattern no alcanza?**
Cuando un participante quiere solo un tramo de la cadena. Incluir el terminador en el medio no corta, porque es una aparición repetida y se preserva la última. Esa clase tiene que sobreescribir el método y resolver aparte.

**¿Por qué el Cake Pattern no se puede hacer en Java?**
Porque el `super` de Java es jerárquico: va a la superclase, no al siguiente módulo. Sin `super` dinámico y sin módulos vivos en la cadena no hay forma de que cada pieza "haga lo suyo y siga".

---

## ✅ Checkpoint final de la unidad

*Sin respuestas. Cubre las cinco partes. Las respuestas van al complemento.*

1. ¿Qué problema concreto motivó los mixins, y qué problema de los mixins motivó los traits?
2. Dibujá la tabla de seis criterios de memoria y explicá en una línea cada fila.
3. ¿Por qué ninguna de las dos herramientas reemplazó a la herencia simple? Dos razones, ninguna técnica.
4. Linearizá: `class X; include A; include B; end`, donde `B` incluye `C` y `A` incluye `C`, y `X` hereda de `S` que incluye `D`. Antes y después de limpiar.
5. Un compañero pone `include Unidad` al final de su clase "para que corte". ¿Qué pasa y por qué?
6. ¿Qué tres propiedades de los mixins necesita el Cake Pattern, y cuál le falta a Java?
7. Explicá con la cadena del kamikaze por qué "incluir Unidad en el medio" no corta.
8. ¿Qué gana y qué pierde `alias_method` frente a la cadena con `super`?
9. Ruby `module` y Scala `trait`: ¿por qué los dos son mixins, y cuál es la única diferencia práctica?
10. Aparece el requerimiento "las murallas descansan como cualquier defensor, pero además reparan un 5% de su potencial defensivo". ¿Dónde lo ponés, con qué herramienta, y qué revisás antes?

---

**FIN DE LA PARTE 4 — Age of Empires: el descanso, el kamikaze y el guerrero que hace dos cosas**
**FIN DEL APUNTE MAESTRO — clase02**
