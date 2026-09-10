# 🧰 APUNTE CORE-MACHETE — clase02 · Mixins: resolución de conflictos

**Qué es este archivo.** El apunte core reducido a lo que necesitás tener al lado mientras resolvés un TP o un ejercicio: sintaxis, la regla de linearización, los cuatro casos de conflicto con su código, la tabla de decisión, errores comunes y checklist. **No explica: asume que ya leíste el core o el maestro.** Si algo no hace clic, volvé al core (Parte 1 para el Ruby y los mixins, Parte 2 para linearización y `super`, Parte 3 para los casos). Todo el código está verificado corriendo.

**Qué no está acá ni en el core.** Orígenes e historia, la comparación con otros lenguajes, Decorator, ORM, el rol de la clase según cada autor. Está en el apunte maestro (Partes 1 §3-§7, 2 §8, 3, 4 §8).

---

## 1. El Ruby que necesitás para esta unidad

### `class` vs `module`, y `include`

```ruby
module Atacante              # module: igual que class por dentro, pero
  def atacar(otro); ...; end #   - no se puede instanciar (Atacante.new → NoMethodError)
end                          #   - no se puede heredar de él (class X < Atacante → TypeError)
                             #   - se puede incluir en cualquier cantidad de clases
class Guerrero
  include Atacante           # "Guerrero es Atacante": trae todos sus métodos y atributos
  include Defensor           # una clase incluye tantos módulos como quiera
end

module Defensor
  include Unidad             # un módulo también puede incluir módulos
end
```

Hereda con `<`, incluye con `include`. Una clase hereda de **una** superclase e incluye **N** módulos.

### `@variable` vs `attr_accessor` — qué es cada cosa

**`@nombre` es una variable de instancia.** El arroba significa *"esto es estado del objeto"*: vive adentro de cada objeto, cada uno tiene la suya, y sobrevive entre llamadas a métodos. Sin arroba, `nombre` es una variable **local** del método y muere cuando el método termina.

```ruby
class Guerrero
  def initialize
    @energia = 100           # variable de instancia: queda guardada en el objeto
    tmp = 5                  # variable local: desaparece al salir de initialize
  end
end
```

Dos propiedades que importan:

- **Nace en `nil`.** Leer una `@variable` que nunca se asignó devuelve `nil`, sin error. Y `nil` cuenta como falso. Por eso `descansado` funciona sin inicializarlo: `nil ? a : b` elige `b`.
- **No se ve desde afuera.** `guerrero.@energia` no existe. Para que otro objeto la lea o escriba, necesitás un método.

**`attr_accessor :energia` es un atajo que escribe esos métodos por vos.** Genera exactamente esto:

```ruby
def energia            # getter: devuelve la variable de instancia
  @energia
end

def energia=(valor)    # setter: la asigna
  @energia = valor
end
```

(`attr_reader` genera solo el getter; `attr_writer` solo el setter.) O sea: **el `@` es la variable; `attr_accessor` son los métodos para acceder a ella.** No son dos formas de declarar lo mismo; son dos capas.

### Cuándo usar `@energia` y cuándo `self.energia`

Dentro de un método tenés las dos opciones, y no dan lo mismo:

```ruby
def sufri_danio(danio)
  self.energia = self.energia - danio   # pasa por el getter y el setter
  @energia     = @energia     - danio   # toca la variable directo
end
```

**Regla práctica: usá siempre `self.nombre`, salvo que estés escribiendo el propio getter o setter.** Razón: si alguien redefine el getter, `self.nombre` respeta esa redefinición y `@nombre` la ignora.

```ruby
attr_accessor :x

def x                       # pisa el getter generado
  @x * 2                    # acá SÍ @: es el propio getter. self.x aquí → recursión infinita (SystemStackError)
end

def otro_metodo
  self.x                    # acá self.: quiero el valor que devuelve el getter (con el * 2)
end
```

El caso real de esto es el getter `potencial_ofensivo` de la Sección 4.

**Trampa del setter sin `self`.** Adentro de un método, `energia = 100` **no llama al setter**: crea una variable local llamada `energia`. Para asignar por el setter hace falta el receptor explícito:

```ruby
def descansar
  energia += 10          # ✗ variable local 'energia' (nil) + 10 → NoMethodError
  self.energia += 10     # ✔ equivale a self.energia = self.energia + 10
end
```

Para leer, `energia` sin `self` sí funciona (Ruby lo resuelve como llamado al getter si no hay local con ese nombre), pero por consistencia el código de la cátedra usa `self.` siempre.

### `super`, `ancestors`, `alias_method`

```ruby
super                      # llama al método del mismo nombre que sigue en la cadena de lookup
super(un_defensor)         # idem, pasando argumentos explícitos (sin paréntesis pasa los mismos que recibió)

Guerrero.ancestors         # la cadena de lookup completa, en orden: [Guerrero, Defensor, Atacante, Object, Kernel, BasicObject]

alias_method :nuevo, :viejo   # copia el método 'viejo' (el que existe EN ESE MOMENTO) con el nombre 'nuevo'
```

---

## 2. Mixin y trait: lo sustancial

**Mixin.** Un módulo de comportamiento —y en Ruby también de estado— que no se instancia y que una clase incluye entero, junto con otros. Se puede pensar como un paquete de modificaciones aplicable a cualquier clase. Los conflictos entre mixins se resuelven **automáticamente** por un orden llamado linearización, los mixins **existen en runtime** (están en `ancestors`), y `super` dentro de un mixin va al **siguiente de la cadena**, sea quien sea.

**Trait.** Igual en propósito, distinto en mecánica. Se combina **método por método** (podés decir "este trait sin tal método"), no define estado, los conflictos **no compilan** hasta que el programador los resuelve a mano, y los traits **se aplanan**: sus métodos se copian dentro de la clase y el trait no existe en runtime. Por eso un `super` dentro de un trait es el `super` común de la herencia, no uno que salte entre traits.

**Los dos complementan la herencia simple.** Seguís heredando de una única superclase; los mixins/traits se montan encima. Sin ninguno, tenés exactamente la herencia de siempre.

| Criterio | Mixins | Traits |
|---|---|---|
| Granularidad | Módulo entero | Método por método |
| Estado | Sí | No |
| Resolución de conflictos | Automática (linearización) | Manual (no compila; álgebra: quitar, renombrar, sobreescribir) |
| Runtime | Linearización: el módulo está vivo en la cadena | Flattening: se copia y desaparece |
| `super` | Dinámico: va al siguiente de la cadena | Jerárquico: va a la superclase de la clase |
| Rol de la clase | El de siempre | Instanciar + pegar traits + definir estado |

**En la cursada:** Ruby `module` = mixin. Scala `trait` = mixin también, a pesar del nombre; la única diferencia práctica es que Scala te obliga a sobreescribir explícitamente cuando dos traits traen el mismo método. **Los patrones de mixins (Sección 5) sirven en los dos.**

---

## 3. Conflicto y linearización

**Conflicto:** un objeto tiene más de un método disponible para un mismo mensaje. Ruby no avisa; elige.

**Cómo elige — la regla:**

1. **Primero la clase misma.**
2. **Después sus módulos, del último incluido al primero**, cada uno con su propia cadena (si un módulo incluye otros, esos van pegados detrás de él).
3. **Después la superclase**, con su cadena completa.
4. Si un módulo aparece repetido, **se preserva la última aparición** y se tachan las anteriores.

```ruby
module M0; end
module M1; include M0; end
module M2; include M0; end
class S; end
class C < S
  include M2
  include M1
end

C.ancestors
# paso a paso:  C → M1 → M0 → M2 → M0 → S → Object ...
# repetido M0:  se tacha la primera aparición
# Resultado esperado: [C, M1, M2, M0, S, Object, Kernel, BasicObject]
```

**`include` se lee de abajo hacia arriba.** El último `include` queda **primero** en el lookup y pisa a los anteriores.

```ruby
class Guerrero
  include Atacante
  include Defensor
  # Lookup: Guerrero → Defensor → Atacante → Object      ✔
  # ✗ NO es "Guerrero → Atacante → Defensor": esa es la lectura imperativa, y está al revés
end
```

**El orden es una decisión de diseño aunque hoy no haya conflicto.** "Guerrero es más defensor que atacante." Si no importa, dejalo en un comentario. **Cambiarlo después es un cambio mayor:** revisá qué conflictos se resuelven hoy hacia ese lado, porque todos cambian de comportamiento.

**`super` dinámico.** Dentro de un módulo, `super` no va a "la superclase": va al que sigue en `ancestors`, y el módulo no sabe quién es. La clase que incluye decide el orden y con eso decide la secuencia.

```ruby
module M; def m; "M → " + super; end; end
module N; def m; "N → " + super; end; end
module O; def m; "O"; end; end             # no llama a super: acá termina
class C; include O; include N; include M; end

C.ancestors    # => [C, M, N, O, Object, Kernel, BasicObject]
C.new.m        # Resultado esperado: "M → N → O"
```

Si el último de la cadena que tiene el método llama a `super` y nadie más lo tiene, cae en `Object` → `NoMethodError`.

---

## 4. El modelo base

Age of Empires en su estado final de la clase. Es el punto de partida de todos los casos de la Sección 5.

```ruby
module Atacante
  attr_accessor :potencial_ofensivo, :descansado

  def atacar(un_defensor)
    if self.potencial_ofensivo > un_defensor.potencial_defensivo
      danio = self.potencial_ofensivo - un_defensor.potencial_defensivo
      un_defensor.sufri_danio(danio)
    end
    self.descansado = false                 # el bonus dura un ataque
  end

  def potencial_ofensivo
    self.descansado ? @potencial_ofensivo * 2 : @potencial_ofensivo
  end

  def descansar
    self.descansado = true                  # descansar como atacante: duplica el próximo ataque
  end
end

module Defensor
  attr_accessor :potencial_defensivo, :energia

  def sufri_danio(danio)
    self.energia = self.energia - danio
  end

  def descansar
    self.energia += 10                      # descansar como defensor: +10 de energía
  end
end

class Guerrero
  include Atacante
  include Defensor                          # más defensor que atacante
  def initialize(potencial_ofensivo = 20, energia = 100, potencial_defensivo = 10)
    self.potencial_ofensivo  = potencial_ofensivo
    self.energia             = energia
    self.potencial_defensivo = potencial_defensivo
  end
end

class Misil
  include Atacante
  def initialize(potencial_ofensivo = 200); self.potencial_ofensivo = potencial_ofensivo; end
end

class Muralla
  include Defensor
  def initialize(potencial_defensivo = 50, energia = 200)
    self.potencial_defensivo = potencial_defensivo
    self.energia             = energia
  end
end

class Kamikaze
  include Defensor
  include Atacante                          # más atacante que defensor
  def initialize(energia = 100, potencial_defensivo = 10)
    self.potencial_ofensivo  = 250
    self.energia             = energia
    self.potencial_defensivo = potencial_defensivo
  end

  def atacar(un_defensor)
    super(un_defensor)                      # ataca como cualquier atacante
    self.energia = 0                        # y muere
  end
end
```

Las cuatro cadenas:

```
Misil    → Atacante → Object
Muralla  → Defensor → Object
Kamikaze → Atacante → Defensor → Object
Guerrero → Defensor → Atacante → Object
```

**El conflicto:** `descansar` está en los dos módulos. Todo compila. Guerrero descansa solo como defensor (gana el último `include`) y Kamikaze solo como atacante. Nadie avisó. Lo que el dominio quiere:

| Unidad | Quiere | Estado actual |
|---|---|---|
| Misil | Como atacante | ✔ ya funciona |
| Kamikaze | **Solo** como atacante | ✔ ya funciona, por el orden |
| Muralla | **Nada** | ✗ gana energía |
| Guerrero | **Las dos** | ✗ solo defensor |

---

## 5. Resolver un conflicto: los cuatro casos

### Caso A — Quiero solo uno: el orden de inclusión

Ya está resuelto si el orden coincide con lo que querés. Kamikaze:

```ruby
k = Kamikaze.new
k.descansar                 # Atacante#descansar; no llama a super → Defensor nunca corre
k.potencial_ofensivo        # Resultado esperado: 500
k.energia                   # Resultado esperado: 100 (sin cambios)
```

Si el orden estaba al revés: dar vuelta los `include` **es un cambio mayor**. Antes, revisá toda la jerarquía por otros conflictos que hoy se resuelven hacia ese lado.

### Caso B — No quiero ninguno: sobreescribir vacío

Igual que en herencia: te parás antes en la cadena y no hacés nada.

```ruby
class Muralla
  include Defensor
  def initialize(potencial_defensivo = 50, energia = 200)
    self.potencial_defensivo = potencial_defensivo
    self.energia             = energia
  end

  def descansar
  end                         # el lookup para acá; Defensor#descansar no se alcanza
end

m = Muralla.new
m.descansar
m.energia                     # Resultado esperado: 200
```

### Caso C — Quiero los dos: cadena con `super` y centinela (Cake Pattern)

Cada módulo hace lo suyo y llama a `super`. Para que el último `super` no caiga en `Object`, un módulo **centinela** con el método vacío, **incluido por cada mixin de la cadena**.

```ruby
module Unidad
  def descansar
  end                         # vacío y SIN super: acá termina la cadena
end

module Atacante
  include Unidad
  attr_accessor :potencial_ofensivo, :descansado
  # atacar y potencial_ofensivo igual que en la Sección 4
  def descansar
    self.descansado = true
    super                     # hago lo mío y sigo
  end
end

module Defensor
  include Unidad
  attr_accessor :potencial_defensivo, :energia
  # sufri_danio igual que en la Sección 4
  def descansar
    self.energia += 10
    super                     # hago lo mío y sigo
  end
end

class Guerrero
  include Atacante
  include Defensor            # NO incluye Unidad: ya viene con los mixins
  # initialize igual
end

Guerrero.ancestors
# antes de limpiar: Guerrero → Defensor → Unidad → Atacante → Unidad → Object
# preserva el último:                     ╳ tachada
# Resultado esperado: [Guerrero, Defensor, Atacante, Unidad, Object, Kernel, BasicObject]

g = Guerrero.new
g.descansar                   # Defensor: energia 110 → super → Atacante: descansado → super → Unidad: nada
g.energia                     # Resultado esperado: 110
g.potencial_ofensivo          # Resultado esperado: 40
```

**Por qué funciona:** `super` dinámico + "se preserva el último", que manda el centinela al fondo aunque lo incluyan varios + los módulos vivos en runtime. No existe con traits ni en Java.

**Trampa 1.** Si preferís que la **clase** incluya `Unidad` en vez de los mixins, tiene que ser el **primer** `include`, para que quede al fondo. Al final, queda primero en el lookup y la clase no hace nada.

**Trampa 2 — el límite del patrón.** Con `super` en `Atacante`, el Kamikaze se rompe: `Kamikaze → Atacante → Defensor → Unidad`, y ahora sí llega a `Defensor`. Meter `include Unidad` **en el medio** para cortar **no funciona**:

```ruby
class Kamikaze
  include Defensor
  include Unidad              # ← no corta: es una aparición repetida
  include Atacante
end
Kamikaze.ancestors            # Resultado esperado: [Kamikaze, Atacante, Defensor, Unidad, Object, ...]
Kamikaze.new.descansar.energia # → 110  ✗
```

Se preserva la última aparición: el del medio se tacha. **Una unidad que quiere solo un tramo de la cadena tiene que sobreescribir `descansar`** y llamar directo a lo que quiere (Caso D, o metaprogramación en la clase 3).

### Caso D — Quiero los dos: `alias_method`

Sin `super` ni centinela. Entre un `include` y el otro, copiás el `descansar` vigente con otro nombre.

```ruby
class Guerrero
  include Atacante
  alias_method :descansar_atacante, :descansar    # copia el descansar de Atacante (el vigente ahora)
  include Defensor
  alias_method :descansar_defensor, :descansar    # copia el de Defensor (pisó el nombre)

  def initialize(potencial_ofensivo = 20, energia = 100, potencial_defensivo = 10)
    self.potencial_ofensivo  = potencial_ofensivo
    self.energia             = energia
    self.potencial_defensivo = potencial_defensivo
  end

  def descansar               # sin esto, descansar sigue siendo el de Defensor
    self.descansar_atacante
    self.descansar_defensor
  end
end

g = Guerrero.new
g.descansar
g.energia                     # Resultado esperado: 110
g.potencial_ofensivo          # Resultado esperado: 40
```

**Variante híbrida:** alias para todos menos el último incluido, y `super` para ese, porque quedó como ancestro inmediato.

```ruby
class Guerrero
  include Atacante
  alias_method :descansar_atacante, :descansar
  include Defensor
  def descansar
    self.descansar_atacante
    super                     # → Defensor#descansar
  end
end
```

**Costos:** ensucia la interfaz (tres métodos públicos), es una copia rústica (si el original era recursivo, la copia sigue llamando al nombre original), y no hay combinación dinámica. **Ventaja:** no depende de que ninguna cadena se alinee; cualquiera lo lee.

---

## 6. Decisión rápida

| Quiero que la clase… | Hago |
|---|---|
| Use solo el método de **uno** de los módulos | Ordeno los `include`: el que quiero va **último** |
| **No** use ninguno | Sobreescribo el método vacío en la clase |
| Use **los dos**, y tengo varios módulos que se encadenan con orden variable | Cake Pattern: `super` en cada módulo + centinela incluido por cada módulo |
| Use **los dos**, en un caso puntual, con equipo que no maneja mixins | `alias_method` entre `include`s + sobreescribir |
| Use los dos pero **otra** clase con los mismos módulos quiere uno solo | Cake Pattern no alcanza para esa otra: la sobreescribo aparte |
| Evitar el conflicto de raíz | Nombres distintos desde el origen (`descansar_como_atacante`, `descansar_como_defensor`) y un `descansar` que llame a los dos |

**Regla general para el TP:** usar mixins lo más posible. El reflejo va a ser volver a la herencia; resistilo.

---

## 7. Errores comunes

1. **Leer los `include` de arriba hacia abajo.** El último gana. Verificá con `.ancestors`.
2. **`energia += 10` sin `self.`** → variable local `nil` → `NoMethodError`. Setters siempre con `self.`.
3. **`self.x` dentro del getter de `x`** → recursión infinita. En el getter, `@x`.
4. **`super` en un módulo sin nadie atrás** → `NoMethodError` en `Object`. Poné centinela o no llames a `super`.
5. **`include Unidad` al final de la clase** "para que corte" → queda primero y anula todo.
6. **`include Unidad` en el medio** para cortar una cadena → se tacha; no corta.
7. **`class X < Modulo`** → `TypeError`. De módulos se incluye, no se hereda.
8. **Cambiar el orden de dos `include` "porque total no hay conflicto"** sin revisar → puede haberlo en otra clase que usa los mismos módulos.
9. **Contar con que el conflicto avise.** Ruby no avisa nunca. Testeá cada clase que combine módulos, no solo la que estás tocando.

---

## 8. Checklist mental antes de entregar

- [ ] Cada clase que incluye dos o más módulos tiene el orden **justificado o comentado como arbitrario**.
- [ ] Corrí `.ancestors` de cada clase con más de un `include` y la cadena es la que esperaba.
- [ ] Todo `super` dentro de un módulo tiene garantizado alguien atrás (centinela o método sin `super` al final).
- [ ] Ningún setter se llama sin `self.`.
- [ ] Ningún getter redefinido se llama a sí mismo con `self.`.
- [ ] Hay un test por cada combinación de módulos, no solo por cada módulo.

---

**FIN DEL APUNTE CORE-MACHETE — clase02**
