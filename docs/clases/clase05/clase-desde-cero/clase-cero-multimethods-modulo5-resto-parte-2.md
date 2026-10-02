# Clase desde cero — Multimethods — Módulo 5: El resto de la parte 2

**Unidad:** clase05 · **Módulo:** 5 de 7 · **Densidad:** 🔴 · **Parte del enunciado:** 2, lo que falta

## Sobre este documento

**Qué cubre:** los cuatro pedidos de la parte 2 que el framework del Módulo 4 todavía no cumple: (1) cuando varias definiciones matchean, elegir la **más específica** con una distancia; (2) `multimethods` y `multimethod(:nombre)`; (3) que una firma repetida **pise** a la anterior; (4) `respond_to?` con firma, sin romper el `respond_to?` de Ruby. Cada uno se construye sobre el código cerrado en el Módulo 4 y toca un solo lugar. Cierra con el archivo entero y sus tests.

**Qué NO cubre:** la parte 3 (Módulo 6). Nada nuevo conceptualmente: son extensiones sobre el mismo diseño, y el valor está en ver **dónde impacta** cada una.

**Tené el enunciado a mano**, en la parte 2: el bloque de código con `A.multimethods()`, la regla de elección (puntos 1 y 2), los ejemplos de `respond_to?` con su NOTA, y el paréntesis de "la nueva pisa la anterior".

## De dónde venís

Del Módulo 3: `find` elige la **primera** definición que matchea; dos `partial_def` con la misma firma quedan las dos; `respond_to?(:concat)` ya da `true` pero con tres argumentos explota.
Del Módulo 4: el framework completo con `call_in_context`.
De clase03: `ancestors`, abrir clases existentes, `respond_to?`.

---

## 1. 🔴 Distancia: la definición más específica

> 📄 **El enunciado dice** (Parte 2, la regla de elección, punto 2):
> *"De estas definiciones, elige cual ejecutar realizando un cálculo de 'distancia de parámetros' y quedándose con la definición que presente la distancia menor."*
> *"Distancia Total de Parámetros = suma de la distancia de cada parámetro, multiplicada por el indice del parámetro (su posición en el array, empezando en 1)"*
> *"Distancia de Parámetro x = x.class.ancestors.index(tipoDefinidoEnBloqueParcial)"*

**En criollo:** de las definiciones que matchean (punto 1, ya hecho con `find`), hay que quedarse con la de **menor distancia**. La distancia de una definición se calcula argumento por argumento: para cada uno, la posición del tipo de la firma dentro de `argumento.class.ancestors`, multiplicada por la posición del argumento (1 para el primero, 2 para el segundo). Se suman esas cantidades y la definición con la suma más chica gana. "Parámetros" es, otra vez, argumentos.

### Paso 0: el síntoma, con el ejemplo del enunciado

> 📄 **El enunciado dice** (Parte 2, ejemplo de la distancia):

```ruby
class A
  partial_def :concat, [String, Integer] do |s1,n|
    s1 * n
  end

  partial_def :concat, [Object, Object] do |o1, o2|
    "Objetos concatenados"
  end
end

A.new.concat("Hello", 2) # "HelloHello", ya que ("Hello", 2) está a menor
distancia de [String,Integer] que de [Object,Object].

A.new.concat(Object.new, 3) # "Objetos concatenados" [Object,Object] es la
única definición que aplica.
```

Con `find`, ese ejemplo anda **de casualidad**, porque la específica está escrita primero. Basta dar vuelta el orden para verlo:

```ruby
class A
  partial_def :concat, [Object, Object] do |o1, o2| "Objetos concatenados" end   # la genérica, PRIMERO
  partial_def :concat, [String, Integer] do |s1, n| s1 * n end                  # la específica, después
end

A.new.concat("Hello", 2)      # => "Objetos concatenados"   ⚠️ con find: la primera que matchea
```

Las dos definiciones matchean con `("Hello", 2)` (un `String` es un `Object`), y `find` se queda con la primera. El enunciado pide la más específica, sin importar el orden.

### Paso 1: medir la distancia de un argumento a un tipo

> **Regla.** `argumento.class.ancestors.index(tipo)` es la cantidad de "saltos" entre la clase del argumento y el tipo de la firma: 0 si es la clase exacta, más cuanto más arriba esté el tipo en la cadena de ancestros.

```ruby
String.ancestors    # => [String, Comparable, Object, Kernel, BasicObject]
Integer.ancestors   # => [Integer, Numeric, Comparable, Object, Kernel, BasicObject]

String.ancestors.index(String)     # => 0    "Hello" está a distancia 0 de String
String.ancestors.index(Object)     # => 2    y a distancia 2 de Object
Integer.ancestors.index(Integer)   # => 0
Integer.ancestors.index(Object)    # => 3
```

`ancestors` es la cadena de búsqueda de métodos de una clase, ordenada de la más cercana a la más lejana; la posición del tipo en esa lista es una medida natural de "qué tan específico" es ese tipo para ese objeto. Con eso, para `("Hello", 2)`:

| Definición | Argumento 1 (`"Hello"`) | Argumento 2 (`2`) | Total |
|---|---|---|---|
| `[String, Integer]` | `0 × 1` | `0 × 2` | **0** |
| `[Object, Object]` | `2 × 1` | `3 × 2` | **8** |

Gana `[String, Integer]`. La multiplicación por la posición es una convención del enunciado: hace que desempatar por el segundo argumento pese más que por el primero.

### Paso 2: `distance` en `PartialBlock`

Es una pregunta sobre **una** definición y unos argumentos: "¿a qué distancia estás de esto?". Así que va en `PartialBlock`, al lado de `matches?`. Tres piezas nuevas de sintaxis, primero cada una:

> **Regla.** `each_with_index` recorre una lista dando cada elemento junto con su posición (desde 0). `sum { … }` suma lo que devuelve el bloque para cada elemento. Cuando el elemento es un par, `|(valor, tipo), i|` lo desarma con los paréntesis y deja `i` para el índice.

```ruby
[["Hello", String], [2, Integer]].each_with_index.to_a
# => [[["Hello", String], 0], [[2, Integer], 1]]      cada par viene acompañado de su índice

[1, 2, 3].sum                  # => 6
[1, 2, 3].sum { |n| n * 10 }   # => 60
```

```ruby
class PartialBlock
  def distance(*args)
    args.zip(types).each_with_index.sum do |(valor, tipo), i|   # (valor, tipo) es el par; i su posición desde 0
      valor.class.ancestors.index(tipo) * (i + 1)               # saltos × posición desde 1
    end
  end
end

pb1 = PartialBlock.new([String, Integer]) { |s, n| s * n }
pb2 = PartialBlock.new([Object, Object]) { |a, b| "Objetos concatenados" }
pb1.distance("Hello", 2)        # => 0
pb2.distance("Hello", 2)        # => 8
pb2.distance(Object.new, 3)     # => 6      0×1 + 3×2
```

`distance` solo se va a preguntar sobre definiciones que **ya matchearon**; por eso `ancestors.index(tipo)` nunca es `nil` ahí. (Si se le preguntara a una que no matchea, `index` devolvería `nil` y `nil * 1` explotaría.)

### Paso 3: de `find` a `select` + `min_by`

> **Regla.** `select { … }` devuelve **todos** los elementos que cumplen (`find` devolvía el primero). `min_by { … }` devuelve el elemento para el que el bloque da el valor más chico.

```ruby
[1, 4, 9].select { |n| n > 3 }     # => [4, 9]
[3, 1, 2].min_by { |n| n }         # => 1
[pb1, pb2].min_by { |b| b.distance("Hello", 2) }.types   # => [String, Integer]
```

Con eso, el cuerpo del `define_method` hace exactamente los dos puntos de la regla del enunciado, en orden:

```ruby
class Module
  def partial_def(name, types, &block)
    definiciones = partial_blocks[name]
    definiciones << PartialBlock.new(types, &block)

    define_method(name) do |*args|
      candidatas = definiciones.select do |partial_block|             # punto 1: TODAS las que matchean
        partial_block.matches?(*args)
      end
      if candidatas.empty?
        raise NoMethodError, "ninguna definición de #{name} matchea con #{args.inspect}"
      end
      definicion = candidatas.min_by do |partial_block|               # punto 2: la de menor distancia
        partial_block.distance(*args)
      end
      definicion.call_in_context(self, *args)
    end
  end
end

A.new.concat("Hello", 2)      # => "HelloHello"             la específica, aunque esté segunda
A.new.concat(Object.new, 3)   # => "Objetos concatenados"   la única que aplica
```

| Escribís | Ruby entiende | Sale con la genérica primero |
|---|---|---|
| `definiciones.find { … }` | La primera que matchea, en orden de definición | `"Objetos concatenados"` |
| `definiciones.select { … }.min_by { … }` | Todas las que matchean, y de esas la más específica | `"HelloHello"` |

Se cierra el hilo del Módulo 3: **el orden de las definiciones ya no importa**.

> 🎯 **Para el parcial, si te preguntan** cómo se elige entre varias definiciones parciales que aplican:
> Se calcula la distancia de cada una a los argumentos, sumando por argumento `argumento.class.ancestors.index(tipo)` multiplicado por su posición (desde 1), y se ejecuta la de menor distancia: la más específica. Primero se filtran las que matchean, después se ordena por distancia.

---

## 2. 🟡 Reflection: `multimethods` y `multimethod`

> 📄 **El enunciado dice** (Parte 2, últimas dos líneas del primer bloque de código):

```ruby
A.multimethods() #[:concat]
A.multimethod(:concat) #Representación del multimethod
```

**En criollo:** la clase tiene que responder `multimethods` con la lista de selectores definidos con `partial_def`, y `multimethod(:concat)` con "una representación" del multimétodo. El enunciado no dice cuál; con nuestro diseño, la representación natural es la lista de `PartialBlock` de ese selector, que tiene todo lo que hay que saber (firmas y bloques).

> **Regla.** `multimethods` son las claves del Hash `partial_blocks`; `multimethod(name)` es la lista guardada bajo esa clave, con error si no existe.

```ruby
class Module
  def multimethods
    partial_blocks.keys                                            # los selectores
  end

  def multimethod(name)
    partial_blocks.fetch(name) { raise ArgumentError, "#{self} no tiene el multimétodo #{name}" }
  end
end

A.multimethods                        # => [:concat]
A.multimethod(:concat).size           # => 2
A.multimethod(:concat).map(&:types)   # => [[Object, Object], [String, Integer]]
A.multimethod(:nada)                  # => ArgumentError: A no tiene el multimétodo nada
```

**`fetch` con bloque:** `hash.fetch(clave) { … }` devuelve lo guardado bajo `clave`, y si no existe ejecuta el bloque en vez de devolver un valor por defecto. Se usa acá para **no crear** la entrada (como haría `partial_blocks[name]`, que con nuestro Hash guarda una lista vacía) y para dar un error con sentido. Es la única línea del framework donde leer el Hash con `[]` sería un error.

> 🕳️ **Madriguera — reificar el multimétodo**
> Otro diseño crea una clase `MultiMethod` con `nombre` y `definiciones`, que sabe elegir y ejecutar por sí misma; `partial_blocks` guardaría objetos `MultiMethod` en vez de listas, y `multimethod(:concat)` devolvería uno. Mueve la lógica del `define_method` a un objeto con nombre. Vale la pena si el framework sigue creciendo.
> *Volvé al camino — esto se profundiza aparte, otro día.*

---

## 3. 🟡 Una firma repetida pisa a la anterior

> 📄 **El enunciado dice** (Parte 2, el paréntesis del párrafo de reabrir la clase):
> *"(a menos que esté definida para una firma para la cual ya existe una definición parcial, en cuyo caso la nueva pisa la anterior)"*

Y lo muestra con `Tanque` reabierto: `partial_def :ataca_a, [Avion]` **agrega**, y `partial_def :ataca_a, [Soldado]` otra vez **cambia** la definición previa de cómo atacar a un soldado.

**En criollo:** al agregar una definición, si ya había una con exactamente la misma firma, esa se saca antes de agregar la nueva.

> **Regla.** Antes de agregar el `PartialBlock` nuevo, se sacan de la lista los que tengan la misma firma. `reject!` saca de la lista, en el lugar, los elementos que cumplen el bloque.

```ruby
class Module
  def partial_def(name, types, &block)
    definiciones = partial_blocks[name]
    definiciones.reject! { |partial_block| partial_block.types == types }   # sacar la de la misma firma, si hay
    definiciones << PartialBlock.new(types, &block)
    # ... (el define_method no cambia)
  end
end

class Tanque
  partial_def :ataca_a, [Soldado] do |s| "ametralladora" end
end
class Tanque                                            # se reabre, más tarde
  partial_def :ataca_a, [Avion]   do |a| "satélite" end # firma nueva: se AGREGA
  partial_def :ataca_a, [Soldado] do |s| "pisar" end    # misma firma: REEMPLAZA
end
Tanque.multimethod(:ataca_a).map(&:types)   # => [[Avion], [Soldado]]
Tanque.new.ataca_a(Soldado.new)             # => "pisar"
```

La comparación `partial_block.types == types` compara los Arrays de tipos elemento a elemento:

```ruby
[String, String] == [String, String]    # => true
[String, Integer] == [String, String]   # => false
```

Una línea, antes del `<<`; si fuera después, sacaría también la recién agregada.

---

## 4. 🔴 `respond_to?` con firma

> 📄 **El enunciado dice** (Parte 2, después de la regla de elección):
> *"A su vez, se pide extender la interfaz de reflection con métodos que indiquen si un objeto responde a un determinado mensaje con cierta firma:"*

Y da los seis casos:

```ruby
A.new.respond_to?(:concat) # true, define el método como multimethod
A.new.respond_to?(:to_s) # true, define el método normalmente
A.new.respond_to?(:concat, false, [String,String]) # true, los tipos coinciden
A.new.respond_to?(:concat, false, [Integer,A]) # true, matchea con [Object, Object]
A.new.respond_to?(:to_s, false, [String]) # false, no es un multimethod
A.new.respond_to?(:concat, false, [String,String,String]) # false, los tipos no coinciden
```

> 📄 **El enunciado dice** (Parte 2, la NOTA en negrita):
> *"respond_to? es un mensaje que ya viene implementado en Ruby y es muy importante que su funcionamiento actual se mantenga. El mismo define dos parámetros, el primero indica el nombre del mensaje, el segundo un boolean que indica si debe inspeccionar también los métodos privados (con default en 'false')."*

**En criollo:** `respond_to?` gana un **tercer** parámetro opcional, una firma. Con firma, responde si algún multimétodo de ese nombre tiene una definición que acepte argumentos de esos tipos. **Sin** firma, tiene que seguir siendo el `respond_to?` de siempre, con su segundo parámetro en `false` por defecto. La nota es una advertencia seria: `respond_to?` lo usa Ruby por dentro (el intérprete, RSpec, muchas librerías) para decidir si mandar un mensaje. Si lo rompés, se rompen cosas lejos de tu código.

Los dos primeros casos ya andan (Módulo 3, sección 7). Los otros cuatro, hoy, explotan con `ArgumentError: wrong number of arguments (given 3, expected 1..2)`.

### Paso 1: comparar una firma pedida con la firma de una definición

El tercer caso pide `[String, String]` y el enunciado dice que `[Object, Object]` lo acepta. No hay valores para preguntar `is_a?`; hay **tipos**, y la pregunta es "¿cada tipo pedido es subtipo del tipo de la firma?".

> **Regla.** Entre clases y módulos, `A <= B` es `true` si `A` es `B` o desciende de `B` o incluye `B`; `false` si es al revés; `nil` si no tienen relación.

```ruby
Integer <= Object        # => true     Integer es subtipo de Object
A <= Object              # => true
String <= String         # => true     una clase es subtipo de sí misma
Integer <= Comparable    # => true     también funciona con módulos incluidos
String <= Integer        # => nil      clases sin relación: nil (all? lo toma como falso)
```

Es `is_a?` para tipos: donde `matches?` pregunta `valor.is_a?(tipo)`, esta pregunta es `tipo_pedido <= tipo`.

```ruby
class PartialBlock
  def matches_types?(tipos_pedidos)                            # como matches?, pero con TIPOS en vez de valores
    return false unless tipos_pedidos.size == types.size
    tipos_pedidos.zip(types).all? do |pedido, tipo|
      pedido <= tipo
    end
  end
end
```

### Paso 2: extender `respond_to?` sin perder el original

> **Regla.** `alias_method :nuevo, :viejo` crea un método `nuevo` con el mismo cuerpo que `viejo`. Después se puede redefinir `viejo` y seguir llamando a la versión anterior por `nuevo`.

```ruby
class Ejemplo
  def saludar; "hola"; end
  alias_method :saludar_original, :saludar              # copia: saludar_original hace lo que saludar hacía
  def saludar; saludar_original + " (con alias)"; end   # redefine saludar usando la copia
end
Ejemplo.new.saludar             # => "hola (con alias)"
Ejemplo.new.saludar_original    # => "hola"
Ejemplo.instance_methods(false) # => [:saludar_original, :saludar]
```

Con eso, `respond_to?` se abre en `Object` (el receptor es una instancia cualquiera), se guarda el original, y se redefine con el tercer parámetro:

```ruby
class Object
  alias_method :respond_to_original?, :respond_to?           # guardar el respond_to? de Ruby con otro nombre

  def respond_to?(name, include_private = false, types = nil)   # include_private sigue en false: la NOTA
    return respond_to_original?(name, include_private) if types.nil?     # sin firma: el de siempre, intacto
    definiciones = self.class.ancestors.flat_map do |modulo|             # las definiciones de la clase y sus ancestros
      modulo.partial_blocks.fetch(name, [])                              # fetch con valor: sin crear la entrada
    end
    definiciones.any? { |partial_block| partial_block.matches_types?(types) }
  end
end
```

Al cargarlo, Ruby avisa `warning: redefining Object#respond_to? may cause infinite loop`. Es una advertencia de que se está redefiniendo algo que Ruby usa internamente; el cuerpo no llama a `respond_to?`, así que no hay loop.

Los seis casos del enunciado, con la `A` de la sección 1 (`[Object, Object]` y `[String, Integer]`):

```ruby
A.new.respond_to?(:concat)                                  # => true    es un método real (define_method)
A.new.respond_to?(:to_s)                                    # => true    el de siempre
A.new.respond_to?(:concat, false, [String, String])         # => true    [Object, Object] los acepta
A.new.respond_to?(:concat, false, [Integer, A])             # => true    también matchea con [Object, Object]
A.new.respond_to?(:to_s, false, [String])                   # => false   to_s no es un multimethod
A.new.respond_to?(:concat, false, [String, String, String]) # => false   ninguna firma tiene tres tipos

A.new.respond_to?(:puts)           # => false   puts es privado: el de siempre lo excluye
A.new.respond_to?(:puts, true)     # => true    con include_private = true, como siempre
A.new.respond_to_original?(:concat) # => true   el original sigue accesible con su alias
```

**Por qué `ancestors` y `flat_map`.** `respond_to?` con firma tiene que ver también los multimétodos heredados (una subclase `B < A` responde `concat` con `[String, String]`). `self.class.ancestors` da la clase y todo lo que tiene arriba; `flat_map` junta en una sola lista las definiciones de cada uno. Y `fetch(name, [])` en vez de `[name]` para no dejar entradas vacías en el Hash de cada ancestro por cada `respond_to?` que se pregunte.

Las tres formas de redefinir `respond_to?`, sobre el mismo caso:

| Escribís | Ruby entiende | Sale |
|---|---|---|
| `alias_method :respond_to_original?, :respond_to?` + `def respond_to?` | Copia el original y lo redefine; el original queda disponible por su alias | Los seis casos, y `respond_to?(:puts)` sigue dando `false` |
| `def respond_to?(name, include_private = false, types = nil)` con `super(name, include_private)` adentro | Redefine en `Object` y sube a la implementación de `Kernel` | Igual que la anterior; `super` funciona porque el original vive en `Kernel`, un ancestro de `Object` |
| `def respond_to?(name, include_private = false, types = nil)` **sin** alias ni `super` | Reemplaza el original y lo **pierde** | `respond_to?(:to_s)` sin firma ya no puede responder |

Las dos primeras son equivalentes acá. El material usa `alias_method` porque no depende de saber dónde vive el original.

### ⚠️ Trampa: cambiar el default de `include_private`

Si el nuevo `respond_to?` se escribe con `include_private = true`, empieza a responder que sí a métodos privados, y código ajeno (RSpec, por ejemplo) llama a métodos que no debe y explota en lugares que no tienen nada que ver con el tuyo. Es exactamente lo que la NOTA prohíbe.

> 🎯 **Para el parcial, si te preguntan** cómo extender `respond_to?` sin romperlo:
> Guardando el original con `alias_method` (o llamando a `super`), agregando un tercer parámetro opcional `types` con default `nil`, y delegando en el original cuando `types` es `nil`. El default del segundo parámetro se mantiene en `false` porque Ruby y las librerías usan `respond_to?` por dentro.

---

## 5. 🔴 Las piezas armadas

El framework al final de la parte 2. Es el `multimethods.rb` que vas a reconocer en cualquier resolución de este ejercicio, menos la parte 3, que agrega el Módulo 6.

```ruby
# multimethods.rb — estado al final del Módulo 5 (parte 2 completa)

class PartialBlock
  attr_reader :types, :block

  def initialize(types, &block)
    unless block.arity == types.size
      raise ArgumentError, "la firma tiene #{types.size} tipos y el bloque #{block.arity} parámetros"
    end
    @types = types
    @block = block
  end

  def matches?(*args)
    return false unless args.size == types.size
    args.zip(types).all? do |valor, tipo|
      valor.is_a?(tipo)
    end
  end

  def matches_types?(tipos_pedidos)                            # M5: respond_to? con firma
    return false unless tipos_pedidos.size == types.size
    tipos_pedidos.zip(types).all? do |pedido, tipo|
      pedido <= tipo
    end
  end

  def distance(*args)                                          # M5: distancia ponderada por posición
    args.zip(types).each_with_index.sum do |(valor, tipo), i|
      valor.class.ancestors.index(tipo) * (i + 1)
    end
  end

  def call(*args)
    unless matches?(*args)
      raise ArgumentError, "los argumentos no coinciden con la firma #{types}"
    end
    block.call(*args)
  end

  def call_in_context(contexto, *args)
    unless matches?(*args)
      raise ArgumentError, "los argumentos no coinciden con la firma #{types}"
    end
    contexto.instance_exec(*args, &block)
  end
end

class Module
  def partial_blocks
    @partial_blocks ||= Hash.new { |hash, clave| hash[clave] = [] }
  end

  def multimethods                                             # M5
    partial_blocks.keys
  end

  def multimethod(name)                                        # M5
    partial_blocks.fetch(name) { raise ArgumentError, "#{self} no tiene el multimétodo #{name}" }
  end

  def partial_def(name, types, &block)
    definiciones = partial_blocks[name]
    definiciones.reject! { |partial_block| partial_block.types == types }   # M5: misma firma → pisa
    definiciones << PartialBlock.new(types, &block)

    define_method(name) do |*args|
      candidatas = definiciones.select do |partial_block|                  # M5: todas las que matchean
        partial_block.matches?(*args)
      end
      if candidatas.empty?
        raise NoMethodError, "ninguna definición de #{name} matchea con #{args.inspect}"
      end
      definicion = candidatas.min_by do |partial_block|                    # M5: la más específica
        partial_block.distance(*args)
      end
      definicion.call_in_context(self, *args)
    end
  end
end

class Object
  alias_method :respond_to_original?, :respond_to?             # M5

  def respond_to?(name, include_private = false, types = nil)
    return respond_to_original?(name, include_private) if types.nil?
    definiciones = self.class.ancestors.flat_map { |modulo| modulo.partial_blocks.fetch(name, []) }
    definiciones.any? { |partial_block| partial_block.matches_types?(types) }
  end
end
```

**Qué tocó cada pedido**, para cerrar el módulo con la idea que importa:

| Pedido del enunciado | Dónde impactó |
|---|---|
| Distancia | `PartialBlock#distance` (nuevo) + `find` → `select` + `min_by` en `partial_def` |
| `multimethods` / `multimethod` | Dos métodos nuevos en `Module`, sobre el Hash que ya existía |
| Firma repetida pisa | Una línea en `partial_def` (`reject!`) |
| `respond_to?` con firma | `PartialBlock#matches_types?` (nuevo) + `Object#respond_to?` con alias |

Ninguno obligó a rediseñar. Eso es lo que compra haber puesto cada responsabilidad en un solo lugar.

### Los tests que este módulo agrega

```ruby
describe 'distancia' do
  class Distancia
    partial_def :concat, [Object, Object] do |o1, o2| "Objetos concatenados" end
    partial_def :concat, [String, Integer] do |s1, n| s1 * n end
  end
  it 'elige la más específica aunque esté después' do
    expect(Distancia.new.concat("Hello", 2)).to eq "HelloHello"
  end
  it 'cae a la genérica cuando es la única' do
    expect(Distancia.new.concat(Object.new, 3)).to eq "Objetos concatenados"
  end
  it 'la misma firma pisa a la anterior' do
    class Pisa
      partial_def :saludar, [String] do |n| "hola #{n}" end
      partial_def :saludar, [String] do |n| "chau #{n}" end
    end
    expect(Pisa.new.saludar("x")).to eq "chau x"
    expect(Pisa.multimethod(:saludar).size).to eq 1
  end
end

describe 'respond_to?' do
  it 'sigue funcionando como siempre' do
    expect(Distancia.new.respond_to?(:concat)).to be true
    expect(Distancia.new.respond_to?(:to_s)).to be true
    expect(Distancia.new.respond_to?(:nada)).to be false
  end
  it 'con firma' do
    expect(Distancia.new.respond_to?(:concat, false, [String, String])).to be true
    expect(Distancia.new.respond_to?(:concat, false, [Integer, Distancia])).to be true
    expect(Distancia.new.respond_to?(:to_s, false, [String])).to be false
    expect(Distancia.new.respond_to?(:concat, false, [String, String, String])).to be false
  end
end
```

---

## Checkpoint del Módulo 5

1. Calculá a mano la distancia de `[Object, Object]` y de `[String, Integer]` para los argumentos `("a", 1)`, y decí cuál gana.
2. ¿Por qué `distance` puede usar `ancestors.index(tipo)` sin preocuparse por que devuelva `nil`?
3. ¿Qué cambia de `find` a `select` + `min_by`, y a qué caso del enunciado deja de afectarle el orden de las definiciones?
4. ¿Qué devuelve `A.multimethod(:concat)` con nuestro diseño, y por qué `fetch` con bloque y no `partial_blocks[name]`?
5. ¿Dónde y con qué línea se resuelve que una firma repetida pise a la anterior? ¿Por qué esa línea va **antes** del `<<`?
6. `matches?` y `matches_types?` se parecen. ¿Qué recibe cada uno y por qué no alcanza con uno solo?
7. ¿Para qué sirve `alias_method` en la extensión de `respond_to?` y qué pasaría sin él (ni `super`)?
8. ¿Por qué el default de `include_private` tiene que seguir siendo `false`? ¿Qué frase del enunciado lo pide?
9. Llega un requerimiento nuevo: "las definiciones de una subclase se suman a las de la superclase, y gana la más específica entre todas". ¿Qué piezas tocarías?

## Qué viene en el Módulo 6

La parte 3 del enunciado, *Nuevo requerimiento*: además de clases y módulos, una firma tiene que aceptar **una lista de mensajes** que el argumento debe entender (`[String, [:nombre, :direccion]]`). Es un requerimiento con la forma exacta de los del individual, y antes de escribir una línea la pregunta es: ¿qué tiene que cambiar, y qué no?

**FIN DEL MÓDULO 5**
