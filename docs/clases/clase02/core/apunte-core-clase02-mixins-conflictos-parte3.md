# 🎯 APUNTE CORE — clase02 · Mixins: resolución de conflictos
## Parte 3 — Resolver conflictos en Age of Empires

*Al terminar esta parte vas a poder tomar un conflicto real entre dos módulos y resolverlo de tres formas —orden de inclusión, cadena con centinela, `alias_method`—, saber cuándo cada una se rompe, y elegir con fundamento. Es lo que se parece a lo que vas a hacer en el TP.*

Se parte del modelo de la Parte 1: `Atacante`, `Defensor`, `Guerrero`, `Misil`, `Muralla`.

---

## 1. Aparece el Kamikaze

**Requerimiento.** *Banzai!* El kamikaze se comporta como un atacante y un defensor. Su potencial ofensivo es 250, pero **después de atacar su energía queda en 0**.

### ¿Hace falta una clase?

El reflejo es `class Kamikaze < Guerrero`: se comporta parecido. Pero **nunca se dijo que estuvieran relacionados**; se dijo que se comportan parecido. Y mirá qué es `Guerrero` ahora: una clase que no define comportamiento propio, solo incluye dos módulos y los instancia. Heredar de ella no te aporta nada y te ata a su orden de inclusión.

Si el vínculo es solo conductual, `Kamikaze` puede incluir los mismos dos módulos. No es copiar al guerrero: **es linearizar activamente**, y el orden es tuyo. Podés decidir que el kamikaze es más atacante que defensor, lo contrario de lo que decidió el guerrero.

> **Lo que cambió:** "nuevo comportamiento → nueva clase" ya no es automático. Hay más lugares donde poner comportamiento.

### La implementación

```ruby
class Kamikaze
  include Defensor
  include Atacante                    # último → el kamikaze es MÁS ATACANTE que defensor
  # Lookup: Kamikaze → Atacante → Defensor → Object

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

Ese `super` es el de la Parte 2 §6: `Kamikaze` no sabe quién tiene el `atacar` de verdad; sabe que alguien en la línea lo tiene.

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

Las diagonales se cruzan porque cada uno prioriza al contrario.

---

## 2. El requerimiento que rompe: descansar

**Requerimiento.** *El descanso de la guerra.* Todas las unidades pueden descansar. Un **atacante** que descansa **duplica su potencial ofensivo en su próximo ataque**. Un **defensor** que descansa **suma 10 de energía**.

### Cada módulo resuelve lo suyo

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

### Se cierra el paréntesis: cuándo `@x` y cuándo `self.x`

Mirá cómo se implementó el bonus: no se toca el valor guardado; se **redefine el getter** `potencial_ofensivo` para que devuelva el doble mientras `descansado` sea verdadero. `attr_accessor` generó un getter, y un `def` propio con el mismo nombre lo pisa.

```ruby
attr_accessor :potencial_ofensivo, :descansado       # genera potencial_ofensivo y potencial_ofensivo=

def potencial_ofensivo                                # ← pisa el getter generado
  self.descansado ? @potencial_ofensivo * 2 : @potencial_ofensivo
  #                 ↑ acá SÍ se lee la variable directo. Si escribieras self.potencial_ofensivo,
  #                   estarías llamando a este mismo método: recursión infinita → SystemStackError
end
```

De acá sale la regla que faltaba en la Parte 1: **usá siempre `self.x`, salvo cuando estés escribiendo el propio getter o setter de `x`.** Razón: `self.x` respeta cualquier redefinición del getter; `@x` la ignora. `atacar` compara con `self.potencial_ofensivo`, así que ve el valor **con** el bonus; si comparara con `@potencial_ofensivo`, el descanso no serviría de nada. Y `self.energia += 10` es `self.energia = self.energia + 10`: pasa por el setter; sin el `self.` sería una variable local en `nil` y explotaría.

Notá también que `descansado` nunca se inicializa: arranca en `nil`, `nil` es falso, y el ternario elige la rama sin bonus. Es la propiedad de la Parte 1 trabajando a favor.

### Por qué nadie vio el conflicto

Así llega este requerimiento a un equipo real: "los atacantes hacen esto, los defensores esto otro". Se reparte. Uno implementa `descansar` en `Atacante`, otro en `Defensor`. **En ninguna de las dos ramas hay conflicto.** Cada uno testea con misiles y murallas, y todo pasa. Se mergea, y ahora hay dos `descansar` para el `Guerrero`, y **nada explotó**: la linearización eligió en silencio, y el guerrero descansa como defensor, porque es más defensor que atacante.

Nadie lo detecta hasta que alguien de producto avisa que *"mis guerreros atacan flojito"*. Como el efecto es un número que cambia poco, tardan en darse cuenta.

> **Ruby no avisa nunca.** Con traits, esto no hubiera compilado, y te habrías visto obligado a mirar. Con mixins, si estaba bien cableado ya funciona para la mayoría, y **los casos particulares los tenés que buscar vos**: testeá cada clase que combine módulos, no solo la que estás tocando.

### Los tres casos particulares

```
   Misil    → Atacante → Object              descansa como atacante ✔ ya funciona
   Muralla  → Defensor → Object              NO debe hacer nada     ✗ hoy gana energía
   Kamikaze → Atacante → Defensor → Object   SOLO como atacante     ✔ ya funciona, por el orden
   Guerrero → Defensor → Atacante → Object   LAS DOS formas         ✗ hoy solo defensor
```

- **Muralla no hace nada.** Tiene que poder recibir el mensaje —la querés en una colección de defensores y mandarles `descansar` a todos— pero es la operación nula.
- **Kamikaze solo como atacante.** No tiene sentido que gane energía: cuando ataca, muere.
- **Guerrero las dos.**

---

## 3. Caso 1 — La muralla no hace nada

No requiere nada nuevo: es la sobreescritura de siempre, porque **la herencia y los mixins no son distintos para el lookup**. Te parás antes en la línea y no hacés nada.

```ruby
class Muralla
  include Defensor

  def initialize(potencial_defensivo = 50, energia = 200)
    self.potencial_defensivo = potencial_defensivo
    self.energia             = energia
  end

  def descansar
  end                                            # vacío: el lookup para acá, nunca llega a Defensor#descansar
end

# ¿CÓMO FUNCIONA?
muralla = Muralla.new
muralla.descansar
muralla.energia                                  # Resultado esperado: 200 (sin cambios)
```

---

## 4. Caso 2 — El kamikaze descansa solo como atacante

Mirá la línea: `Kamikaze → Atacante → Defensor`. El lookup encuentra `Atacante#descansar` y **se detiene**, porque ese método no llama a `super`. Ya funciona, sin escribir una línea.

```ruby
kamikaze = Kamikaze.new                          # po 250, energia 100
kamikaze.descansar                               # Atacante#descansar: descansado = true. Defensor nunca corre
kamikaze.potencial_ofensivo                      # Resultado esperado: 500
kamikaze.energia                                 # Resultado esperado: 100 (sin cambios)
```

Funciona porque la decisión de orden de la Sección 1 **estaba alineada con la naturaleza del kamikaze**. Cuando cae un requerimiento así, hay dos opciones: o el orden que elegiste a ciegas coincide con lo que el dominio quiere, o no.

**Si hubiera estado al revés**, la solución obvia es dar vuelta los `include`. Pero es el cambio mayor de la Parte 2 §5: primero buscás si hay un comentario que diga "orden arbitrario"; si está, lo das vuelta, corrés los tests, borrás el comentario. Si no está, revisás toda la jerarquía por otros conflictos que hoy se resuelvan hacia ese lado. Y si los hay, viene un refactor.

---

## 5. Caso 3 — El guerrero hace las dos cosas

Acá se acaba lo automático. **No hay resolución automática que admita "quiero las dos"**, porque hasta hacer las dos implica una secuencia. Hay que combinarlas a mano, y vas a ver dos formas: una elegante que usa solo mixins, y una particular de Ruby.

---

## 6. Solución A — La cadena con `super` y el centinela

### Primer intento: `super` en el defensor

¿Qué herramienta tenés para decir "hacé lo tuyo y seguí"? `super`. El guerrero encuentra `Defensor#descansar`; si ese método hace lo suyo y llama a `super`, cae en `Atacante#descansar`. Las dos cosas.

```ruby
module Defensor
  def descansar
    self.energia += 10
    super                                        # "seguí con el que venga atrás"
  end
end
```

Los tests del guerrero pasan. Pero `Defensor` lo usan otros:

```
   Misil    → Atacante ● → Object                 sin super: no pasa por acá ✔
   Muralla  → Defensor ● → ??? → Object           super → nadie tiene descansar → NoMethodError ✗
   Kamikaze → Atacante ● → Defensor → Object      Atacante no llama super: frena ✔
   Guerrero → Defensor ● → Atacante ● → Object    super → Atacante#descansar ✔
```

**Rompiste la muralla.** La muralla concreta sobreescribe `descansar` con un método vacío, así que zafa; pero cualquier otro defensor que no lo sobreescriba explota, porque el `super` sale hacia `Object`.

### El centinela

Si el problema es que *ahí no hay nada*, la salida es poner algo: un módulo con `descansar` vacío, que **no** llame a `super`, para atajar. Se llama **centinela** o **terminador**. Corta la cadena: *"hasta acá llegué"*.

```ruby
module Unidad
  def descansar
  end                                            # no hace nada y NO llama a super: acá termina
end
```

¿Dónde lo incluís? Primera idea: en cada clase, antes que los demás módulos, para que quede al fondo.

```ruby
class Muralla
  include Unidad
  include Defensor                               # Muralla → Defensor → Unidad → Object ✔
end
```

Funciona, pero es artesanal: hay que acordarse en cada clase. Segunda idea, más natural: **que `Defensor` incluya `Unidad`**, y así el corte viene puesto.

```ruby
module Defensor
  include Unidad
  def descansar
    self.energia += 10
    super
  end
end
```

Antes de festejar, linearizá el guerrero con esto:

```
   Guerrero → Defensor ● → Unidad → Atacante → Object
                        └──super──▶ Unidad#descansar: vacío, sin super. FIN.
```

**Acabás de romper al guerrero.** `Unidad` quedó pegada detrás de `Defensor`, y el `super` cae en la caja vacía **antes** de llegar a `Atacante`.

### La solución, y por qué "se preserva el último" era importante

Ahora **los dos módulos incluyen al centinela, y los dos llaman a `super`:**

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
  include Defensor                               # sin incluir Unidad: ya viene con los módulos
  def initialize(potencial_ofensivo = 20, energia = 100, potencial_defensivo = 10)
    self.potencial_ofensivo  = potencial_ofensivo
    self.energia             = energia
    self.potencial_defensivo = potencial_defensivo
  end
end
```

Linearizá el guerrero con la regla de la Parte 2, **antes de limpiar**:

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

**Las dos especializaciones hacen lo suyo, cada una llama hacia adelante, y el factor común queda al final atajando.** Para esto sirve que la linearización preserve el último: para que cada módulo pueda decir `super` sin miedo, con la garantía de que **siempre hay alguien atrás** que frena.

```ruby
# ¿CÓMO FUNCIONA?
Guerrero.ancestors                    # => [Guerrero, Defensor, Atacante, Unidad, Object, Kernel, BasicObject]
atila = Guerrero.new                  # po 20, energia 100, pd 10
conan = Guerrero.new
atila.descansar                       # Defensor: energia 110 → super → Atacante: descansado true → super → Unidad: nada
atila.energia                         # Resultado esperado: 110
atila.atacar(conan)                   # po = 40 > 10 → danio 30
conan.energia                         # Resultado esperado: 70

# y todas las demás cadenas quedan bien:
Misil.ancestors                       # => [Misil, Atacante, Unidad, Object, ...]        ✔
Muralla.ancestors                     # => [Muralla, Defensor, Unidad, Object, ...]      ✔ (más su override vacío)
```

> ✗ **Trampa.** Si preferís que la **clase** incluya `Unidad` en vez de los módulos, tiene que ser el **primer `include`**, para que quede al fondo:
> ```ruby
> class Guerrero
>   include Unidad      # ✔ primero → última en el lookup
>   include Atacante
>   include Defensor
> end
> # con include Unidad al FINAL, Unidad queda primera en el lookup: el guerrero no hace nada.
> ```

### Se llama Cake Pattern

Esto tiene nombre: **Cake Pattern**, el patrón torta, por las capas. Es la implementación por defecto en muchísimos frameworks para cualquier cosa que se combine de formas variables, afecte ligeramente una conducta, y donde el orden importe.

**Y solo se puede hacer con mixins.** Necesita tres cosas de la tabla de la Parte 2:

1. `super` **dinámico**: que "el siguiente" lo cablee la clase.
2. **Linearización que preserva el último**: para que el terminador quede al fondo aunque lo incluyan varios.
3. **Módulos vivos en runtime**: si se aplanaron, no hay línea.

> ⚠️ Esto se mostró como una astucia, para que veas las oportunidades de diseño que abre la herramienta. **No se va a pedir.** No siempre vas a armar un Cake Pattern para que algo haga dos cosas; a veces hay alternativas más fáciles (Sección 8). Pero entenderlo es entender por qué la linearización se hace como se hace.

---

## 7. El límite: el kamikaze se vuelve a romper

Con el Cake Pattern armado, volvé al kamikaze:

```
   Kamikaze → Atacante ● → Defensor ● → Unidad ● → Object
                        └─super──▶   └─super──▶
```

`Atacante#descansar` ahora llama a `super`, y cae en `Defensor`. **El kamikaze gana energía al descansar.** Rompiste el Caso 2, que andaba solo.

La intuición dice: meto `Unidad` **en el medio**, entre los dos, para cortar antes del defensor:

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

**No corta.** El `Unidad` del medio es una aparición repetida; se preserva la última, y el corte se va al fondo. (Ruby, concretamente, ignora un `include` de un módulo que ya está en la línea.) La intuición de "corte en el medio" es justo lo que la linearización no garantiza: **incluir vos un módulo no pesa lo mismo que cuando lo incluyen tus módulos**, y el algoritmo se queda con una sola copia.

```ruby
Kamikaze.ancestors            # Resultado esperado: [Kamikaze, Atacante, Defensor, Unidad, Object, Kernel, BasicObject]
k = Kamikaze.new
k.descansar
k.energia                     # Resultado esperado: 110  ✗ (quería 100)
```

Lo que corresponde es **que el kamikaze sobreescriba `descansar`** y llame directo a lo que quiere. Cómo llamar específicamente al `descansar` de `Atacante` y no al de la línea, con lo que tenés hasta acá, es la Sección 8; la forma prolija, que le habla al método por su nombre y su módulo, es tema de la clase 3.

> **La lección:** el Cake Pattern asume que **todos los participantes quieren toda la cadena.** Una unidad que quiere solo un tramo se sale del patrón y lo resuelve aparte. No es un defecto del patrón; es su alcance.

---

## 8. Solución B — `alias_method`, o resolverlo a mano

A veces no querés armar una cadena. Solo querías que una clase haga dos cosas, y tenés un equipo que ve un Cake Pattern y se queda rascándose la cabeza. Ruby te deja hacerlo de otra manera.

### El mecanismo

Acordate: Ruby es destructivo, y **cada línea trabaja sobre lo que dejó la anterior**. Entre un `include` y el otro podés hacer cosas. **`alias_method` crea una copia de un método existente con otro nombre**: no borra el original, agrega un método más que hace lo mismo.

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

  def descansar                                     # sobreescribo descansar para que llame a los dos
    self.descansar_atacante
    self.descansar_defensor
  end
end

# ¿CÓMO FUNCIONA? — con los módulos de la Sección 2 (sin super, sin Unidad)
atila = Guerrero.new
atila.descansar                       # descansar_atacante: descansado true; descansar_defensor: energia 110
atila.energia                         # Resultado esperado: 110
atila.potencial_ofensivo              # Resultado esperado: 40
```

**Con los alias solos no resolviste nada**: tenés tres métodos, y `descansar` sigue siendo el de `Defensor` porque fue el último en pisar el nombre. Recién cuando **sobreescribís `descansar`** conseguís lo que querías.

Esto es, literalmente, resolver el conflicto a mano, como haría un trait: renombrar. Ruby no eligió una sola forma; te dio mixins **y** te dio herramientas para operar a mano, y vos decidís.

### Lo que cuesta

- **Ensucia la interfaz.** El guerrero tiene ahora tres métodos públicos que responden a "descansar", dos de los cuales nadie debería llamar.
- **Es una copia rústica.** `alias_method` copia el código y le pone otra firma. Si el método original llamaba a `descansar` por su nombre, la copia sigue llamando a `descansar` — al de `Defensor`. No se renombra por adentro.
- **No hay `super`, no hay combinación dinámica.** Más rabioso, pero también más simple: no depende de que ninguna cadena se alinee.

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

Y se generaliza: con N módulos que comparten un método, `super` para el último incluido y `alias_method` para todos los demás.

### Volviendo al kamikaze

Con esto también se resuelve el límite de la Sección 7, si el modelo usa Cake Pattern: el kamikaze sobreescribe `descansar` y llama solo a lo que quiere. Y si el modelo **no** usa Cake Pattern —los módulos sin `super`, como en la Sección 2—, el kamikaze no necesita nada: el orden lo resuelve.

---

## 9. ¿Cuál usar? La tabla de decisión, explicada

Hemos llegado al **depende**, y el depende tiene contenido. Pesan tres cosas: lo que hay en el lenguaje, lo que sabe tu equipo, y el problema concreto.

| Quiero que la clase… | Hago | Por qué esa y no otra |
|---|---|---|
| Use solo el método de **uno** de los módulos | Ordeno los `include`: el que quiero va **último** | Es gratis y es lo que la linearización hace sola. Si el orden ya estaba fijo por otro conflicto, sobreescribo en la clase |
| **No** use ninguno | Sobreescribo el método vacío en la clase | Es la sobreescritura de siempre. Nada nuevo |
| Use **los dos**, y tengo varios módulos que se encadenan con orden variable | Cake Pattern: `super` en cada módulo + centinela incluido por cada módulo | Es la solución más probada y predecible cuando hay cadena. No ensucia interfaces ni repite código. Requiere que el equipo lea mixins con soltura |
| Use **los dos**, en un caso puntual, o con equipo que no maneja mixins | `alias_method` entre `include`s + sobreescribir | Cualquiera lo lee. No depende de que nada se alinee. Paga con interfaz sucia |
| Use los dos, pero **otra** clase con los mismos módulos quiere uno solo | Cake Pattern para la primera; la otra sobreescribe y resuelve aparte | El Cake Pattern no admite que un participante quiera un tramo; no fuerces la cadena |
| Evitar el conflicto de raíz | Nombres distintos desde el origen (`descansar_como_atacante`, `descansar_como_defensor`) y un `descansar` que llame a los dos | Simple. También ensucia la interfaz, pero de forma explícita y desde el diseño |

**Regla general para el TP:** usar mixins lo más posible. El reflejo va a ser volver a la herencia; resistilo. Cuanto más cómodo estés, más libre vas a ser cuando de verdad tengas que elegir.

---

## 10. Lo que Age of Empires enseñó

1. **Incluir dos módulos te obliga a decidir un orden que hoy no importa y mañana sí.** Documentá lo arbitrario. Cambiarlo después es un cambio mayor.
2. **La resolución automática resuelve la mayoría de los casos y esconde el resto.** Los tests son tu red: testeá cada combinación, no solo el módulo que tocaste.
3. **Sobreescribir sigue funcionando igual.** Muralla no necesitó nada nuevo.
4. **`super` dinámico + preservar el último + módulos vivos = Cake Pattern.** No existe sin linearización.
5. **Todo patrón tiene alcance.** El kamikaze quiere un tramo y el Cake Pattern no se lo da; se sale y resuelve aparte.
6. **Ruby te deja resolver a mano.** `alias_method` funciona, ensucia, y no depende de que nada se alinee.
7. **"¿Hace falta una clase?" dejó de tener respuesta automática.**

---

## ✅ Checkpoint final

*Sin respuestas. Cubre las tres partes.*

1. ¿Qué cambia en el código al pasar de `class` a `module`, y qué cambia en lo que podés hacer?
2. ¿Qué diferencia hay entre `@x` y `self.x`, y cuándo va cada uno?
3. Linearizá: `class X; include A; include B; end`, donde `B` incluye `C` y `A` incluye `C`, y `X` hereda de `S` que incluye `D`. Antes y después de limpiar.
4. ¿Por qué el último `include` gana?
5. ¿Adónde va `super` dentro de un módulo, y por qué eso es una herramienta de diseño?
6. Un compañero pone `include Unidad` al final de su clase "para que corte". ¿Qué pasa?
7. ¿Qué tres propiedades necesita el Cake Pattern, y por qué no se puede hacer con traits?
8. Explicá con la cadena del kamikaze por qué "incluir Unidad en el medio" no corta.
9. ¿Qué gana y qué pierde `alias_method` frente a la cadena con `super`?
10. Aparece el requerimiento "las murallas descansan como cualquier defensor, pero además reparan un 5% de su potencial defensivo". ¿Dónde lo ponés, con qué herramienta, y qué revisás antes?

---

**FIN DE LA PARTE 3 — Resolver conflictos en Age of Empires**
**FIN DEL APUNTE CORE — clase02**
