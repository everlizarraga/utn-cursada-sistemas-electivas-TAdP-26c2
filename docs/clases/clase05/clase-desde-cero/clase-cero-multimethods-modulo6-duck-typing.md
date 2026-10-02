# Clase desde cero — Multimethods — Módulo 6: Duck typing

**Unidad:** clase05 · **Módulo:** 6 de 7 · **Densidad:** 🔴 · **Parte del enunciado:** 3, *Nuevo requerimiento*

## Sobre este documento

**Qué cubre:** la parte 3 del enunciado completa. Es un requerimiento con la forma exacta de los del individual: llega un pedido nuevo sobre código que ya funciona, y hay que decidir **dónde** impacta antes de escribir nada. El pedido: además de clases y módulos, una firma tiene que poder decir "cualquier objeto que entienda estos mensajes". Al terminar, el framework está completo y queda el `multimethods.rb` final con sus tests.

**Qué NO cubre:** alternativas de implementación (Módulo 7, opcional).

**Tené el enunciado a mano**, en la parte 3.

## De dónde venís

Del Módulo 5: el framework completo de la parte 2. En particular, que hay **tres** lugares de `PartialBlock` que miran qué es un tipo: `matches?` (con `is_a?`), `matches_types?` (con `<=`) y `distance` (con `ancestors.index`).
De clase03: `respond_to?(:mensaje)` pregunta si un objeto entiende un mensaje; `method_defined?(:mensaje)` pregunta si una clase lo define.

---

## 1. 🔴 Qué pide la parte 3

> 📄 **El enunciado dice** (Parte 3, *Nuevo requerimiento*, primer párrafo):
> *"Se solicita extender la implementación actual de multimethods para soportar definiciones parciales que incluyan soporte para 'duck typing' o tipado estructural. Esto es, en lugar de solamente permitir que en las firmas se incluyan clases o módulos, se desea permitir poder especificar una lista de mensajes que el objeto debe entender para encajar en la definición:"*
> *"Para que un parámetro sea aceptado por una restricción de este tipo, el parámetro debe entender TODOS los mensajes pedidos, de lo contrario, la definición no aplica."*

Dos palabras nuevas, que nombran lo mismo: **duck typing** (o **tipado estructural**) es decidir si un objeto sirve mirando **qué mensajes entiende**, y no de qué clase es. "Si camina como pato y hace cuac, es un pato": si entiende `nombre` y `direccion`, sirve como cosa con nombre y dirección, sea de la clase que sea. Lo opuesto, lo que usamos hasta ahora, es el tipado por clase: `is_a?(Lugar)`.

**En criollo:** en una firma, además de `String` o `Comparable`, ahora se puede poner una **lista de símbolos** (`[:nombre, :direccion]`). Un argumento encaja en esa lista si entiende **todos** esos mensajes. Con uno que no entienda, esa definición no aplica.

Y sigue con el ejemplo:

> 📄 **El enunciado dice** (Parte 3, el bloque de código):

```ruby
class A
  partial_def :formatear, [String, [:nombre, :direccion]] do |titulo, coso|
    titulo + " | " + coso.nombre + ": " + coso.direccion
  end
  partial_def :formatear, [String, [:peso]] do |titulo, pesable|
    titulo + " " pesable.peso
  end
end

class Lugar
    attr_accessor :nombre, :direccion, :fotos
    def initialize (...)
end

class Perro
    attr_accessor :nombre, :edad, :peso
    def initialize (...)
end

A.new.formatear("VISITE", Lugar.new("Obelisco", "Corrientes y 9 de Julio"))
#devuelve "VISITE | Obelisco: Corrientes y 9 de Julio"

A.new.formatear("Pesado", Perro.new(32))
#devuelve "Pesado 32"

A.new.formatear("Pesado", 5)
#error! 5 no matchea con ningún tipo posible"
```

Tres erratas en ese bloque, para que no te frenen: en la segunda definición falta el `+` antes de `pesable.peso`, y además `peso` es un número, así que hace falta `.to_s` para concatenarlo; `def initialize (...)` es un "acá va el constructor" y no código Ruby; y la última línea cierra con una comilla que nadie abrió. La versión corregida es la que usamos abajo.

Fijate en el caso del medio: `Perro` entiende `nombre` (lo tiene) pero **no** `direccion`, así que no encaja en la primera definición; sí entiende `peso`, así que encaja en la segunda. Y `Lugar` y `Perro` no comparten superclase ni módulo: la elección es puramente por mensajes.

> 📄 **El enunciado dice** (Parte 3, cierre):
> *"Esta nueva forma de especificar el tipo de los parámetros debe ser compatible con la ya existente (se debe poder usar una o la otra indistintamente)."*
> *"La distancia de una restricción de duck typing es siempre de 0.5 (es decir, solo la propia clase es más específica que una definición estructural)."*

**En criollo:** en una misma firma pueden convivir clases y listas (`[String, [:peso]]` ya lo hace). Y para la distancia del Módulo 5, una lista de mensajes vale **0.5**: más que la clase exacta (0), menos que cualquier superclase (1 o más).

---

## 2. 🔴 Antes de escribir: qué tiene que cambiar y qué no

> **Regla.** El primer paso frente a un requerimiento nuevo es localizar la responsabilidad que cambia. Acá cambia **una sola idea**: "qué es un tipo de la firma". Todo lo que no mira eso no tiene por qué enterarse.

Recorrido por las piezas del Módulo 5, preguntándose "¿esto mira qué es un tipo?":

| Pieza | ¿Mira qué es un tipo? | Cambia |
|---|---|---|
| `PartialBlock#initialize` | Solo cuenta cuántos hay (`types.size`); una lista de símbolos cuenta como **un** tipo | No |
| `PartialBlock#matches?` | **Sí**: hace `valor.is_a?(tipo)` | **Sí** |
| `PartialBlock#matches_types?` | **Sí**: hace `pedido <= tipo` | **Sí** |
| `PartialBlock#distance` | **Sí**: hace `valor.class.ancestors.index(tipo)` | **Sí** (y el enunciado dice cuánto: 0.5) |
| `PartialBlock#call`, `call_in_context` | Delegan en `matches?` | No |
| `Module#partial_blocks`, `partial_def`, `multimethods`, `multimethod` | Guardan y buscan `PartialBlock`; no abren la firma | No |
| El método definido por `define_method` | Pregunta `matches?`, `distance` y ejecuta | No |
| `Object#respond_to?` | Delega en `matches_types?` | No |

Resultado: tres métodos, los tres adentro de `PartialBlock`, y todos por la misma razón. `Module` y `Object` no se tocan. Un requerimiento que obliga a tocar cinco archivos suele estar avisando que la responsabilidad estaba repartida; uno que toca una clase avisa que el diseño anterior estaba bien.

**Antes de la lista de símbolos, el valor `5` ya recorría este camino:** `matches?` → `5.is_a?(tipo)`. Lo único nuevo es que ahora `tipo` puede ser un `Array`, y para un `Array` la pregunta es otra.

---

## 3. 🔴 Paso 1: `matches?`, con una pregunta aparte

> **Regla.** `matches?` delega en un método nuevo, `acepta?(tipo, valor)`, que distingue el caso: si `tipo` es un `Array`, todos sus símbolos tienen que ser mensajes que `valor` entienda; si no, sigue siendo `valor.is_a?(tipo)`.

Primero las piezas sueltas, ejecutadas:

```ruby
[:nombre, :direccion].is_a?(Array)    # => true    el tipo es una lista → camino estructural
String.is_a?(Array)                   # => false   una clase no es un Array → camino nominal
Array.is_a?(Array)                    # => false   ni siquiera la clase Array lo es (es una Class)

lugar = Lugar.new("Obelisco", "Corrientes y 9 de Julio")
[:nombre, :direccion].all? { |m| lugar.respond_to?(m) }          # => true
[:nombre, :direccion].all? { |m| Perro.new(32).respond_to?(m) }  # => false   entiende nombre, no direccion
5.respond_to?(:peso)                                              # => false
5.respond_to?(:+)                                                 # => true    5 entiende +, por si hacía falta recordarlo

PartialBlock.new([[:nombre, :direccion]]) { |x| x }.types.size    # => 1     la lista cuenta como UN tipo
```

Y el cambio:

```ruby
class PartialBlock
  def acepta?(tipo, valor)                                   # una pregunta, dos formas de responderla
    if tipo.is_a?(Array)                                     # tipo estructural: lista de mensajes
      tipo.all? { |mensaje| valor.respond_to?(mensaje) }     # ¿entiende TODOS?
    else                                                     # tipo por clase: clase o módulo
      valor.is_a?(tipo)                                      # igual que antes
    end
  end

  def matches?(*args)
    return false unless args.size == types.size
    args.zip(types).all? do |valor, tipo|
      acepta?(tipo, valor)                                   # antes decía valor.is_a?(tipo)
    end
  end
end

class Lugar
  attr_accessor :nombre, :direccion, :fotos
  def initialize(n, d); @nombre = n; @direccion = d; end
end

class Perro
  attr_accessor :nombre, :edad, :peso
  def initialize(p); @peso = p; end
end

class A
  partial_def :formatear, [String, [:nombre, :direccion]] do |titulo, coso|
    titulo + " | " + coso.nombre + ": " + coso.direccion
  end
  partial_def :formatear, [String, [:peso]] do |titulo, pesable|
    titulo + " " + pesable.peso.to_s                         # con el + y el to_s que faltaban
  end
end

A.new.formatear("VISITE", Lugar.new("Obelisco", "Corrientes y 9 de Julio"))
# => "VISITE | Obelisco: Corrientes y 9 de Julio"
A.new.formatear("Pesado", Perro.new(32))
# => "Pesado 32"
A.new.formatear("Pesado", 5)
# => NoMethodError: ninguna definición de formatear matchea con ["Pesado", 5]
```

Los tres casos del enunciado.

```
# ¿CÓMO FUNCIONA?  A.new.formatear("Pesado", Perro.new(32))
# select recorre las dos definiciones:
# 1ª  [String, [:nombre, :direccion]]
#     acepta?(String, "Pesado") → "Pesado".is_a?(String) → true
#     acepta?([:nombre, :direccion], perro) → perro.respond_to?(:nombre) → true
#                                             perro.respond_to?(:direccion) → false → all? → false
#     matches? → false
# 2ª  [String, [:peso]]
#     acepta?(String, "Pesado") → true
#     acepta?([:peso], perro) → perro.respond_to?(:peso) → true → all? → true
#     matches? → true → única candidata → se ejecuta: "Pesado" + " " + "32"
```

**Por qué un método aparte y no el `if` adentro de `matches?`.** Funcionaría igual. Pero `matches?` responde "¿aplico a estos argumentos?" y `acepta?` responde "¿este valor cabe en este tipo?": son dos preguntas, y la segunda es la que cambia. Separarla cuesta tres líneas y deja el próximo cambio localizado.

### La firma `[Array]` y la firma `[[…]]` no son lo mismo

| Escribís | Ruby entiende | `matches?([1, 2])` | `matches?("ab")` |
|---|---|---|---|
| `PartialBlock.new([Array]) { … }` | Tipo por clase: instancias de la clase `Array` | `true` | `false` |
| `PartialBlock.new([[:size]]) { … }` | Tipo estructural: lo que entienda `size` | `true` | `true`  (`"ab"` entiende `size`) |

La primera pide "un Array"; la segunda pide "algo con `size`", que incluye Arrays, Strings y Hashes. Los corchetes dobles no son un error de tipeo: son la lista de mensajes.

> 🛠️ **Lo que te va a marcar el editor:** RubyMine no distingue `[Array]` de `[[:size]]` ni avisa nada en ninguno de los dos. Es Ruby válido en ambos casos; el significado lo pone tu `acepta?`.

---

## 4. 🔴 Paso 2: `distance`, con el 0.5 del enunciado

> **Regla.** Para un tipo estructural, la distancia de ese argumento es 0.5, sin mirar la clase del valor. Para una clase o módulo, sigue siendo `valor.class.ancestors.index(tipo)`.

```ruby
class PartialBlock
  def distance(*args)
    args.zip(types).each_with_index.sum do |(valor, tipo), i|
      distancia = tipo.is_a?(Array) ? 0.5 : valor.class.ancestors.index(tipo)   # también: if/else en cuatro líneas
      distancia * (i + 1)
    end
  end
end

PartialBlock.new([String, [:size]]) { |s, x| x }.distance("Hello", [1])   # => 1.0    0×1 + 0.5×2
```

**El operador `? :`** (ternario) es un `if`/`else` en una línea: `condición ? valor_si_sí : valor_si_no`. Es la única sintaxis nueva del módulo, y es azúcar: la forma larga hace exactamente lo mismo.

**Por qué 0.5.** El enunciado lo explica entre paréntesis: "solo la propia clase es más específica que una definición estructural". La clase exacta está a 0; la lista de mensajes, a 0.5; la primera superclase, a 1. Así, si un argumento matchea con `[Lugar]` y con `[[:nombre]]`, gana `[Lugar]`; si matchea con `[Object]` y con `[[:nombre]]`, gana la lista.

---

## 5. 🔴 Paso 3: `matches_types?`, para `respond_to?` con firma

> **Regla.** Cuando `respond_to?` recibe una firma y el tipo de la definición es una lista de mensajes, la pregunta sobre la **clase** pedida es si define todos esos mensajes: `pedido.method_defined?(mensaje)`.

En `matches?` había un valor y se preguntaba `valor.respond_to?(mensaje)`. En `matches_types?` hay una clase, y la pregunta equivalente es si esa clase define el método:

```ruby
Lugar.method_defined?(:nombre)     # => true    Lugar define nombre (attr_accessor)
Integer.method_defined?(:nombre)   # => false
```

```ruby
class PartialBlock
  def matches_types?(tipos_pedidos)
    return false unless tipos_pedidos.size == types.size
    tipos_pedidos.zip(types).all? do |pedido, tipo|
      if tipo.is_a?(Array)                                     # firma estructural: ¿la clase pedida define esos mensajes?
        tipo.all? { |mensaje| pedido.method_defined?(mensaje) }
      else                                                     # firma por clase: ¿la clase pedida es subtipo?
        pedido <= tipo
      end
    end
  end
end

A.new.respond_to?(:formatear, false, [String, Lugar])     # => true    Lugar define nombre y direccion
A.new.respond_to?(:formatear, false, [String, Integer])   # => false   Integer no define nombre ni peso
```

Con esto los tres lugares están adaptados, y la parte 3 cumple también "compatible con la ya existente": `[String, [:peso]]` mezcla las dos formas y todo el framework la entiende.

> 🎯 **Para el parcial, si te preguntan** dónde impacta agregar tipado estructural a las firmas:
> Solo en `PartialBlock`, en los tres métodos que miran qué es un tipo: `matches?` (un valor encaja en una lista de mensajes si responde `respond_to?` a todos), `distance` (una lista vale 0.5) y `matches_types?` (una clase encaja si define todos los mensajes). `partial_def`, el diccionario, `call_in_context` y `respond_to?` no cambian, porque no miran qué es un tipo.

> 🕳️ **Madriguera — un objeto `TipoEstructural` en vez de un Array**
> Otra forma de resolver esto es que la firma reciba un objeto propio (`Duck.new(:nombre, :direccion)`) que entienda `acepta?(valor)`, `distancia` y `acepta_tipo?(clase)`, y que las clases también los entiendan. Así desaparecen los tres `if` y cada tipo responde por sí mismo (polimorfismo). Es mejor diseño; el enunciado pide la lista de símbolos.
> *Volvé al camino — esto se profundiza aparte, otro día.*

---

## 6. 🔴 El archivo final

Todo el framework, en el estado en que queda al terminar el enunciado. Es el `multimethods.rb` que va junto a este módulo, con su `multimethods_spec.rb` (25 ejemplos: todos los casos de las partes 1, 2 y 3, más herencia y contexto). Se corren con `rspec multimethods_spec.rb` desde la carpeta donde están los dos archivos.

```ruby
# multimethods.rb — framework completo

class PartialBlock
  attr_reader :types, :block

  def initialize(types, &block)
    unless block.arity == types.size
      raise ArgumentError, "la firma tiene #{types.size} tipos y el bloque #{block.arity} parámetros"
    end
    @types = types
    @block = block
  end

  # ¿el tipo de la firma acepta este valor?  (M6: un tipo puede ser una lista de mensajes)
  def acepta?(tipo, valor)
    if tipo.is_a?(Array)
      tipo.all? { |mensaje| valor.respond_to?(mensaje) }
    else
      valor.is_a?(tipo)
    end
  end

  def matches?(*args)
    return false unless args.size == types.size
    args.zip(types).all? do |valor, tipo|
      acepta?(tipo, valor)
    end
  end

  # ¿la firma acepta argumentos de estos tipos?  (M5: respond_to? extendido; M6: listas de mensajes)
  def matches_types?(tipos_pedidos)
    return false unless tipos_pedidos.size == types.size
    tipos_pedidos.zip(types).all? do |pedido, tipo|
      if tipo.is_a?(Array)
        tipo.all? { |mensaje| pedido.method_defined?(mensaje) }
      else
        pedido <= tipo
      end
    end
  end

  # distancia de cada argumento a su tipo, ponderada por la posición (M5; M6: 0.5 para listas)
  def distance(*args)
    args.zip(types).each_with_index.sum do |(valor, tipo), i|
      distancia = tipo.is_a?(Array) ? 0.5 : valor.class.ancestors.index(tipo)
      distancia * (i + 1)
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

  def multimethods
    partial_blocks.keys
  end

  def multimethod(name)
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
  alias_method :respond_to_original?, :respond_to?

  def respond_to?(name, include_private = false, types = nil)
    return respond_to_original?(name, include_private) if types.nil?
    definiciones = self.class.ancestors.flat_map { |modulo| modulo.partial_blocks.fetch(name, []) }
    definiciones.any? { |partial_block| partial_block.matches_types?(types) }
  end
end
```

### Los tests que este módulo agrega

```ruby
describe 'duck typing' do
  it 'acepta un objeto por los mensajes que entiende' do
    expect(A.new.formatear("VISITE", Lugar.new("Obelisco", "Corrientes y 9 de Julio")))
      .to eq "VISITE | Obelisco: Corrientes y 9 de Julio"
  end
  it 'elige la definición cuyos mensajes entiende el argumento' do
    expect(A.new.formatear("Pesado", Perro.new(32))).to eq "Pesado 32"
  end
  it 'falla si el argumento no entiende los mensajes de ninguna definición' do
    expect { A.new.formatear("Pesado", 5) }.to raise_error(NoMethodError)
  end
  it 'respond_to? con firma entiende las listas de mensajes' do
    expect(A.new.respond_to?(:formatear, false, [String, Lugar])).to be true
    expect(A.new.respond_to?(:formatear, false, [String, Integer])).to be false
  end
end
```

---

## Checkpoint del Módulo 6

1. ¿Por qué `PartialBlock#initialize` no cambia, si ahora un tipo puede ser una lista?
2. `Lugar` y `Perro` no comparten ninguna clase ni módulo. ¿Cómo hace la firma `[String, [:peso]]` para aceptar a uno y rechazar al otro?
3. Escribí `acepta?` de memoria y explicá qué pregunta responde cada rama.
4. ¿Qué diferencia hay entre la firma `[Array]` y la firma `[[:size]]`? Dá un valor que matchee con una y no con la otra.
5. ¿Por qué la distancia de una lista de mensajes es 0.5 y no 0 ni 1? ¿Qué frase del enunciado lo explica?
6. En `matches?` la pregunta es `valor.respond_to?(mensaje)`; en `matches_types?` es `pedido.method_defined?(mensaje)`. ¿Por qué no es la misma pregunta?
7. Un compañero pone el `if` adentro de `matches?` en vez de un método `acepta?`. Anda. ¿Qué argumento le das para separarlo?
8. Definí *tipado estructural* con tus palabras y decí qué lo diferencia del tipado por clase.
9. Llega otro requerimiento: "un tipo también puede ser un bloque que recibe el valor y devuelve `true` o `false`". ¿Qué piezas tocarías?

## Qué viene en el Módulo 7

El enunciado terminó, y el framework está completo. El Módulo 7 es **opcional**: muestra la otra forma de haber hecho `partial_def`, sin `define_method`, atrapando los mensajes que la clase no entiende con `method_missing`. Anda, y es peor. Verlo al lado del código bueno muestra qué compra `define_method` y en qué casos, distintos de este, `method_missing` es la herramienta correcta. Si vas justo de tiempo, salteálo; el material de la clase termina acá.

**FIN DEL MÓDULO 6**
