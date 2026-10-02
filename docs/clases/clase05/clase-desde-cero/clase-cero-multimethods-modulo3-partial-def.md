# Clase desde cero — Multimethods — Módulo 3: partial_def

**Unidad:** clase05 · **Módulo:** 3 de 7 · **Densidad:** 🔴 · **Parte del enunciado:** 2, *Multi Methods*, primera mitad

## Sobre este documento

**Qué cubre:** `partial_def`, el mensaje que una clase manda dentro de su cuerpo para agregar una definición parcial. Se construye **de a un pedazo**: dónde se define (esqueleto), dónde guarda lo que recibe, cómo crea el método que elige en el momento 2, qué pasa cuando se reabre la clase y con la herencia. Al final del módulo, los cuatro ejemplos de `concat` del enunciado andan.

**Qué NO cubre:** de la parte 2, quedan para después el párrafo de `self` (Módulo 4) y la distancia, `multimethods`, `respond_to?` con firma y "la nueva pisa la anterior" (Módulo 5). Este módulo deja **abierto a propósito** el problema de `self` en la sección 8.

**Tené el enunciado a mano**, en la parte 2.

## De dónde venís

Del Módulo 1: los dos momentos, y que la clase es un objeto que guarda estado propio en `@variables`.
Del Módulo 2: `PartialBlock`, con `matches?(*args)` y `call(*args)`.
De clase03 y clase04: abrir una clase existente (`class Module … end` agrega métodos a `Module`), `define_method` (define un método cuyo nombre es un valor, con un bloque como cuerpo), `instance_methods(false)`, clausuras (un bloque ve las variables locales del lugar donde fue escrito).

---

## 1. 🔴 Qué pide la parte 2 (esta mitad)

> 📄 **El enunciado dice** (Parte 2, *Multi Methods*, primer párrafo):
> *"El objetivo ahora es implementar multimétodos. Un módulo o clase debe poder definir un multimethod definiendo cada una de sus firmas cómo una definición parcial."*

Y sigue con el bloque de `class A … partial_def :concat …` que ya leíste en el Módulo 1, sección 4, con los cuatro usos (`'hello world'`, `'hellohellohello'`, `'hello world!'`, y el que lanza excepción).

> 📄 **El enunciado dice** (Parte 2, después del código):
> *"En este ejemplo, la clase A define un único multimethod concat con tres piezas de código asociadas a tres firmas distintas."*

**En criollo:** hay que hacer que exista `partial_def`, un mensaje que reciben las clases (y los módulos) dentro de su cuerpo, con selector, firma y bloque. Cada `partial_def` agrega una definición parcial al multimétodo de ese selector; **hay un solo `concat`** con tres piezas adentro, no tres `concat`.

> 📄 **El enunciado dice** (Parte 2, la regla de elección, punto 1):
> *"Cuando un objeto recibe un mensaje implementado con multimethods, el framework debe decidir cual implementación parcial ejecutar en función de los parámetros, de la siguiente forma: 1. Sólo debe considerar aquellas definiciones parciales que matcheen con los parámetros pasados (deben tener mismo tipo y aridad)."*

**En criollo:** cuando llega el mensaje, se miran solo las definiciones cuyo `matches?` dé `true` con los argumentos (otra vez "parámetros" por "argumentos"; **aridad** es la cantidad de argumentos, la misma palabra que `arity` del Módulo 2). El punto 2 de esa regla, qué hacer cuando **varias** matchean, queda para el Módulo 5; en este módulo se ejecuta la primera que matchea.

---

## 2. 🔴 Paso 0: dónde vive `partial_def`

> **Regla.** `partial_def` se define en `Module`. Así lo entienden todas las clases y todos los módulos, porque `Class` hereda de `Module`.

```ruby
class Module                              # se abre Module: lo que va acá lo entienden clases y módulos
  def partial_def(name, types, &block)    # name: el selector · types: la firma · &block: el cuerpo
  end                                     # vacío por ahora
end

class A
  partial_def :concat, [String, String] do |s1, s2|   # A entiende partial_def: no explota
    s1 + s2
  end                                                  # => nil    (método vacío)
end

A.instance_methods(false)   # => []      partial_def no creó ningún método todavía
A.new.concat("a", "b")      # => NoMethodError: undefined method `concat' for #<A:0x…>
```

El esqueleto ya cumple la mitad de la parte 2 que más se ve: `A` entiende `partial_def` sin error. Lo que falta es que **haga** algo.

**Por qué `Module` y no `Class` ni `Object`.** El receptor de `partial_def` es la clase `A`, que es instancia de `Class`. Con `Class` alcanzaría para clases, pero el enunciado dice "un módulo o clase", y un módulo es instancia de `Module`, no de `Class`. `Module` cubre los dos: es lo que el enunciado llamaba "a nivel de módulo". `Object` sería demasiado: cualquier instancia (`"hola".partial_def …`) entendería el mensaje, sin sentido.

Cuando Ruby lee `class A … partial_def :concat, … end`, en ese instante `self` es `A`, y `A` entiende `partial_def` porque lo busca en su clase (`Class`) y de ahí sube a `Module`. Es el momento 1 del Módulo 1.

---

## 3. 🔴 Paso 1: guardar las definiciones

> **Regla.** Cada clase guarda sus definiciones parciales en una variable de instancia **propia del objeto clase**: un Hash cuya clave es el selector y cuyo valor es la lista de `PartialBlock` de ese selector.

Primero el lugar donde se guarda, después el `partial_def` que guarda:

```ruby
class Module
  def partial_blocks                                          # lector "perezoso": crea el Hash la primera vez
    @partial_blocks ||= Hash.new { |hash, clave| hash[clave] = [] }
  end

  def partial_def(name, types, &block)
    partial_blocks[name] << PartialBlock.new(types, &block)   # agregar la definición a la lista del selector
  end
end

class B
  partial_def :concat, [String, String] do |s1, s2| s1 + s2 end
  partial_blocks
  # => {:concat=>[#<PartialBlock @types=[String, String], @block=#<Proc …>>]}

  partial_def :concat, [Array] do |a| a.join end
  partial_blocks[:concat].size          # => 2
  partial_blocks[:concat].map(&:types)  # => [[String, String], [Array]]
end

B.instance_variables         # => [:@partial_blocks]   el Hash vive en el objeto clase B
B.instance_methods(false)    # => []                   sigue sin haber método
B.new.concat("a", "b")       # => NoMethodError: undefined method `concat' for #<B:0x…>
```

Guarda bien y todavía no sirve para nada: falta el paso 2. Pero fijate dónde quedó guardado. Como `partial_blocks` está definido en `Module`, cada clase lo entiende, y cada una tiene **su propia** `@partial_blocks`, porque `@` siempre pertenece al `self` del momento, y ese `self` es la clase que recibió el mensaje. Las instancias (`B.new`) no lo tienen ni lo necesitan.

### `||=`: inicializar cuando se necesita

> **Regla.** `x ||= valor` asigna `valor` solo si `x` es `nil` o `false`; si ya tiene algo, lo deja.

```ruby
x = nil
x ||= 5          # x era nil → asigna
x                # => 5
x ||= 9          # x ya vale 5 → no toca
x                # => 5
```

Por eso `partial_blocks` crea el Hash la primera vez y lo reutiliza siempre después.

### ⚠️ Trampa: cuatro formas de crear el Hash, y solo una sirve

> **Regla.** `Hash.new { |hash, clave| hash[clave] = [] }` crea un Hash que, ante una clave inexistente, **guarda** una lista vacía bajo esa clave y la devuelve. Las otras tres formas se ven iguales y no guardan.

Sobre el mismo caso: agregar `1` bajo `:concat` y `2` bajo `:otro`.

| Escribís | Ruby entiende | Sale |
|---|---|---|
| `h = {}`<br>`h[:concat] << 1` | Sin valor por defecto: `h[:concat]` es `nil` | ``NoMethodError: undefined method `<<' for nil:NilClass`` |
| `h = Hash.new([])`<br>`h[:concat] << 1; h[:otro] << 2` | Valor por defecto: **un único** Array compartido por todas las claves, y nunca guardado | `h` → `{}` · `h[:concat]` → `[1, 2]` · `h[:nunca_usada]` → `[1, 2]` |
| `h = Hash.new { [] }`<br>`h[:concat] << 1` | Ante clave inexistente devuelve un Array **nuevo cada vez**, sin guardarlo | `h` → `{}` · `h[:concat]` → `[]`  (el `1` se perdió) |
| `h = Hash.new { \|hash, clave\| hash[clave] = [] }`<br>`h[:concat] << 1; h[:otro] << 2` | Ante clave inexistente crea el Array, **lo guarda bajo la clave** y lo devuelve | `h` → `{:concat=>[1], :otro=>[2]}` |

La tercera fila es la peligrosa: `partial_def` haría `partial_blocks[name] << PartialBlock.new(…)` sobre un Array que se descarta al instante, `partial_blocks` seguiría vacío, y cada `concat` terminaría en "ninguna definición matchea". Sin ningún error en el momento 1. La forma correcta es la cuarta.

(Un detalle de la cuarta forma: **leer** una clave inexistente también la crea. `h[:nunca_usada]` deja `:nunca_usada=>[]` guardado. Para el framework es inofensivo.)

---

## 4. 🔴 Paso 2: crear el método que elige

> **Regla.** `partial_def` define con `define_method` un método de nombre `name`, una sola vez por selector aunque haya varias definiciones, cuyo cuerpo corre en el momento 2: busca en la lista la primera definición que matchea con los argumentos y la ejecuta.

Primero, solo el método, para ver que existe y qué recibe:

```ruby
class Module
  def partial_def(name, types, &block)
    partial_blocks[name] << PartialBlock.new(types, &block)
    define_method(name) do |*args|     # crea el método de instancia `name` (el selector, como valor)
      args                             # por ahora devuelve lo que recibió
    end
  end
end

class C
  partial_def :concat, [String, String] do |s1, s2| s1 + s2 end
end

C.instance_methods(false)    # => [:concat]      ahora sí existe
C.new.concat("a", "b")       # => ["a", "b"]     y recibe los argumentos, juntados por *args
C.new.respond_to?(:concat)   # => true
```

Ahora el cuerpo de verdad. Necesita **elegir**: recorrer la lista y quedarse con la primera definición que matchee.

### `find`: el primero que cumple

> **Regla.** `lista.find { |x| condición }` devuelve el **primer** elemento para el que el bloque es verdadero, o `nil` si ninguno lo es.

```ruby
[1, 4, 9].find { |n| n > 3 }     # => 4      el primero que cumple; el 9 nunca se mira
[1, 4, 9].find { |n| n > 100 }   # => nil    ninguno cumple
```

Sobre la lista de `PartialBlock`, `find { |pb| pb.matches?(*args) }` es exactamente el punto 1 de la regla del enunciado: "solo las que matchean", y de esas la primera. Que sea *la primera* y no *la más específica* es el punto 2 de esa regla, que queda anotado para el Módulo 5.

### `partial_def` completo

```ruby
class Module
  def partial_blocks
    @partial_blocks ||= Hash.new { |hash, clave| hash[clave] = [] }
  end

  def partial_def(name, types, &block)
    definiciones = partial_blocks[name]              # la lista de ESTE selector en ESTA clase (se crea si no existe)
    definiciones << PartialBlock.new(types, &block)  # momento 1: guardar la definición nueva

    define_method(name) do |*args|                   # momento 1: crear (o recrear) el método `name`
      definicion = definiciones.find do |partial_block|   # momento 2: con los argumentos en la mano...
        partial_block.matches?(*args)                     # ...la primera definición que aplica
      end
      unless definicion                                   # ninguna aplica → error explícito
        raise NoMethodError, "ninguna definición de #{name} matchea con #{args.inspect}"
      end
      definicion.call(*args)                              # momento 2: ejecutar la definición elegida
    end
  end
end

class A
  partial_def :concat, [String, String] do |s1, s2| s1 + s2 end
  partial_def :concat, [String, Integer] do |s1, n| s1 * n end
  partial_def :concat, [Array] do |a| a.join end
end

A.new.concat('hello', ' world')          # => "hello world"
A.new.concat('hello', 3)                 # => "hellohellohello"
A.new.concat(['hello', ' world', '!'])   # => "hello world!"
A.new.concat('hello', 'world', '!')
# => NoMethodError: ninguna definición de concat matchea con ["hello", "world", "!"]
```

Los cuatro casos del enunciado, andando.

```
# ¿CÓMO FUNCIONA?  class A; partial_def :concat, [String, String] do |s1, s2| s1 + s2 end; end
# MOMENTO 1 (Ruby lee el cuerpo de A; self = A):
# 1. A recibe partial_def(:concat, [String, String], bloque)
# 2. definiciones = A.partial_blocks[:concat] → lista vacía recién creada y guardada bajo :concat
# 3. definiciones << PartialBlock.new([String, String], bloque) → la lista tiene 1 elemento
# 4. define_method(:concat) do |*args| … end → A tiene ahora un método de instancia :concat
#    Su cuerpo TODAVÍA NO SE EJECUTÓ. Quedó escrito, y "recuerda" la variable `definiciones`.
#
# MOMENTO 2 (alguien hace A.new.concat('hello', ' world'); self = la instancia):
# 5. args = ['hello', ' world']
# 6. definiciones.find { … } → el PartialBlock [String, String] matchea → definicion
# 7. definicion.call('hello', ' world') → el bloque corre con s1 = 'hello', s2 = ' world' → 'hello world'
```

**Por qué el cuerpo del `define_method` no elige nada en el momento 1.** Porque en el momento 1 no hay argumentos. Lo único que `partial_def` puede hacer es dejar escrito un cuerpo que, cuando llegue el mensaje, mire `args`. Es la aplicación directa de la sección 6 del Módulo 1.

**Por qué `definiciones` es una variable local y el bloque la usa.** El bloque del `define_method` es una clausura: ve las variables locales del lugar donde fue escrito, y las sigue viendo cuando se ejecuta mucho después. `definiciones` apunta a la lista real guardada en el Hash de la clase, así que cuando `partial_def` agrega más definiciones a esa misma lista, el método ya definido las ve. La sección 6 muestra por qué esta forma, y no otra, es la correcta.

**Sobre el error.** El enunciado dice "lanza una excepción" sin fijar cuál. `NoMethodError` con un mensaje propio es una decisión: es el error que Ruby daría si el método no existiera para esos argumentos, y el mensaje dice qué faltó. `# también: raise ArgumentError, "…"` es igual de válido.

### El estado de la clase, paso a paso

```ruby
class A
  instance_methods(false)   # => []       antes de nada
  partial_blocks            # => {}

  partial_def :concat, [String, String] do |s1, s2| s1 + s2 end
  instance_methods(false)             # => [:concat]   el método existe
  partial_blocks.keys                 # => [:concat]
  partial_blocks[:concat].size        # => 1

  partial_def :concat, [String, Integer] do |s1, n| s1 * n end
  partial_def :concat, [Array] do |a| a.join end
  instance_methods(false)             # => [:concat]   sigue habiendo UN método
  partial_blocks[:concat].size        # => 3           y TRES definiciones
  partial_blocks[:concat].map(&:types)
  # => [[String, String], [String, Integer], [Array]]
end
```

Acá se cierra el primer dolor del Módulo 1: **tres cuerpos con el mismo nombre conviven**, porque el nombre tiene un solo método (genérico) y los cuerpos viven en la lista. Es lo que decía el enunciado: "un único multimethod concat con tres piezas de código".

**Sobre redefinir el método tres veces.** Cada `partial_def` vuelve a ejecutar `define_method(:concat)`, y el segundo pisa al primero, igual que dos `def`. Es inofensivo: el cuerpo es siempre el mismo (buscar en `definiciones` y ejecutar), y `definiciones` es la misma lista. Redefinirlo es más simple que preguntar "¿ya existe?", y cuesta lo mismo.

> 🛠️ **Lo que te va a marcar el editor:** dentro del bloque de `define_method`, RubyMine no sabe quién va a ser `self` y no autocompleta métodos de la instancia. Es normal: el nombre del método es un valor, y el editor no puede resolverlo.

---

## 5. 🔴 Paso 3: reabrir la clase y métodos que ya existían

> 📄 **El enunciado dice** (Parte 2, después del ejemplo de `Tanque`):
> *"Así como con los métodos comunes, también, debe ser posible definir un multimethod para una clase ya existente, pero teniendo en cuenta que cada definición parcial se agrega a las anteriores (a menos que esté definida para una firma para la cual ya existe una definición parcial, en cuyo caso la nueva pisa la anterior)"*

**En criollo:** si reabrís una clase (`class Tanque … end` otra vez, más abajo) y hacés `partial_def :ataca_a` con una firma nueva, esa definición **se suma** a las que ya había. Y si la firma ya existía, la nueva reemplaza a la vieja. Lo primero ya sale solo; lo segundo se resuelve en el Módulo 5.

> **Regla.** Reabrir una clase y hacer `partial_def` con un selector que ya tiene definiciones **agrega** a la misma lista, porque `partial_blocks[name]` devuelve la lista que ya existía.

El ejemplo del enunciado, con los métodos de ataque simplificados:

```ruby
class Soldado; end
class Avion;   end

class Tanque
  partial_def :ataca_a, [Tanque]  do |objetivo| "cañón"         end
  partial_def :ataca_a, [Soldado] do |objetivo| "ametralladora" end
end

class Tanque                                            # se reabre, más tarde
  partial_def :ataca_a, [Avion] do |avion| "satélite" end   # firma nueva: se AGREGA
end

Tanque.partial_blocks[:ataca_a].map(&:types)   # => [[Tanque], [Soldado], [Avion]]
Tanque.new.ataca_a(Avion.new)                  # => "satélite"
Tanque.new.ataca_a(Soldado.new)                # => "ametralladora"   las anteriores siguen
```

Acá se cierra el segundo dolor del Módulo 1: cada `partial_def` **agrega** un caso sin tocar los anteriores, justo lo que el `if` no podía.

> **Regla.** `partial_def` sobre un selector que la clase ya definía con `def` lo **reemplaza**: el método común desaparece, y queda solo el multimétodo. Es la misma regla que `def` sobre `def`.

```ruby
class D
  def saludar; "hola común"; end                    # método común

  partial_def :saludar, [String] do |n|             # define_method(:saludar) pisa al anterior
    "hola #{n}"
  end
end

D.new.saludar("Ever")   # => "hola Ever"
D.new.saludar           # => NoMethodError: ninguna definición de saludar matchea con []
#                          el "hola común" ya no existe
```

Vale también al revés (`def` después de `partial_def` pisa al multimétodo). Todo esto es consistente con Ruby: **un nombre, un método por clase**.

Y dos `partial_def` con la **misma firma** en la misma clase, hoy, quedan las dos en la lista y `find` ejecuta la primera:

```ruby
class H
  partial_def :saludar, [String] do |n| "hola #{n}" end
  partial_def :saludar, [String] do |n| "chau #{n}" end
end
H.new.saludar("x")                 # => "hola x"    ganó la primera
H.partial_blocks[:saludar].size    # => 2
```

Que la nueva pise a la vieja, como pide el paréntesis del enunciado, es el Módulo 5.

---

## 6. 🔴 Paso 4: herencia, y por qué la lista se captura en la clausura

> **Regla.** Una subclase que no redefine el multimétodo lo hereda y funciona, porque el método heredado sigue apuntando a la lista de la clase donde fue definido. Una subclase que sí hace `partial_def` del mismo selector obtiene su propio método y su propia lista.

```ruby
class B < A; end                    # hereda concat sin agregar nada
B.new.concat("a", "b")              # => "ab"    usa las definiciones de A
B.partial_blocks                    # => {}      B no guardó nada propio

class C < A
  partial_def :concat, [Integer, Integer] do |a, b| a + b end   # C define su propio concat
end
C.new.concat(1, 2)                  # => 3
C.new.concat("a", "b")
# => NoMethodError: ninguna definición de concat matchea con ["a", "b"]
#    el concat de C solo ve la lista de C; las definiciones de A no se suman
```

### ⚠️ Trampa: buscar la lista a través de `self.class`

Hay una forma que **parece equivalente**, anda para la clase que define, y explota para la que hereda:

```ruby
define_method(name) do |*args|
  definicion = self.class.partial_blocks[name].find { |pb| pb.matches?(*args) }   # ⚠️
  # ...
end
```

| Escribís | Ruby entiende | Sale |
|---|---|---|
| `definiciones.find { … }` (variable capturada) | La lista de la clase que **definió** el método, siempre | `B.new.concat("a", "b")` → `"ab"` |
| `self.class.partial_blocks[name].find { … }` | La lista de la clase de **la instancia que recibió el mensaje** | `B.new.concat("a", "b")` → `NoMethodError: ninguna definición de concat matchea…` |

**Por qué.** En el momento 2, `self` es la instancia, y para `B.new` eso da `self.class == B`. `B.partial_blocks[:concat]` es una lista vacía (recién creada por el Hash), con lo cual `find` devuelve `nil` y el método falla, aunque `A` tenga tres definiciones perfectamente válidas. La variable capturada evita el problema porque **no depende de quién recibe el mensaje**: apunta a la lista que existía cuando el método se escribió.

Esto es, otra vez, los dos momentos: `self.class` se resuelve en el momento 2, con la instancia; `definiciones` quedó resuelta en el momento 1, con la clase.

> 🎯 **Para el parcial, si te preguntan** por qué el cuerpo del `define_method` no usa `self.class` para llegar a las definiciones:
> Porque en ejecución `self` es la instancia receptora, y una subclase que hereda el multimétodo tendría `self.class` apuntando a una clase sin definiciones. Capturar la lista como variable local en `partial_def` (clausura) ata el método a las definiciones de la clase que lo creó, en el momento de la definición.

> 🕳️ **Madriguera — acumular definiciones a lo largo de la jerarquía**
> Se podría hacer que el `concat` de `C` busque también en las listas de sus ancestros (`self.class.ancestors`), para que las definiciones de `A` y de `C` se sumen. Es una extensión válida; el enunciado no la pide.
> *Volvé al camino — esto se profundiza aparte, otro día.*

---

## 7. 🟡 Lo que `respond_to?` ya sabe, y lo que no

Como el multimétodo es un método real (lo creó `define_method`), `respond_to?` ya lo ve:

```ruby
A.new.respond_to?(:concat)    # => true
```

El enunciado va a pedir, más adelante en la parte 2, un `respond_to?` que además reciba una firma (`respond_to?(:concat, false, [String, String])`). Hoy eso explota (`ArgumentError: wrong number of arguments (given 3, expected 1..2)`), porque el `respond_to?` de Ruby acepta uno o dos argumentos. Queda anotado para el Módulo 5.

---

## 8. 🔴 El problema que queda abierto: `self` adentro del bloque

> **Regla.** El bloque de un `partial_def` se escribió en el cuerpo de la clase, así que dentro de él `self` es **la clase**, no la instancia que recibió el mensaje. Con el código de este módulo, `self` adentro de una definición parcial apunta al lugar equivocado.

```ruby
class G
  partial_def :quien_soy, [] do    # firma vacía: cero argumentos
    self                            # ¿quién soy cuando esto se ejecuta?
  end
end

G.new.quien_soy    # => G         la CLASE. Esperábamos la instancia (#<G:0x…>)
```

Eso rompe cualquier definición que quiera hablar con el receptor, que es casi todas las interesantes. Es exactamente el ejemplo de `Tanque` del enunciado, que hace `self.ataca_con_canion(objetivo)` adentro del bloque:

```ruby
class Tanque
  partial_def :ataca_a, [Soldado] do |objetivo|
    self.ataca_con_ametralladora(objetivo)   # self es Tanque (la clase) → NoMethodError
  end
end
```

**Por qué pasa.** El bloque es una clausura, y una clausura recuerda también el `self` del lugar donde fue escrita. Fue escrita dentro de `class G … end`, donde `self` es `G`. `definicion.call(*args)` ejecuta el Proc tal cual, con ese `self` recordado. La cantidad de argumentos está bien, los tipos están bien; el **contexto** está mal.

El dolor queda sembrado. El Módulo 4 lo cura cambiando **una línea**.

---

## 9. 🔴 Las piezas armadas

El framework al final de este módulo. `PartialBlock` es el del Módulo 2, sin cambios.

```ruby
class Module
  def partial_blocks
    @partial_blocks ||= Hash.new { |hash, clave| hash[clave] = [] }
  end

  def partial_def(name, types, &block)
    definiciones = partial_blocks[name]
    definiciones << PartialBlock.new(types, &block)

    define_method(name) do |*args|
      definicion = definiciones.find do |partial_block|
        partial_block.matches?(*args)
      end
      unless definicion
        raise NoMethodError, "ninguna definición de #{name} matchea con #{args.inspect}"
      end
      definicion.call(*args)
    end
  end
end
```

### Los tests de esta pieza

```ruby
describe 'partial_def' do
  class A
    partial_def :concat, [String, String] do |s1, s2| s1 + s2 end
    partial_def :concat, [String, Integer] do |s1, n| s1 * n end
    partial_def :concat, [Array] do |a| a.join end
  end

  it 'elige la definición por los tipos de los argumentos' do
    expect(A.new.concat('hello', ' world')).to eq 'hello world'
    expect(A.new.concat('hello', 3)).to eq 'hellohellohello'
    expect(A.new.concat(['hello', ' world', '!'])).to eq 'hello world!'
  end
  it 'falla si ninguna definición matchea' do
    expect { A.new.concat('hello', 'world', '!') }.to raise_error(NoMethodError)
  end
  it 'una subclase hereda el multimétodo' do
    class B < A; end
    expect(B.new.concat('a', 'b')).to eq 'ab'
  end
  it 'reabrir la clase agrega definiciones' do
    class A
      partial_def :concat, [Integer, Integer] do |a, b| a + b end
    end
    expect(A.new.concat(1, 2)).to eq 3
    expect(A.new.concat('a', 'b')).to eq 'ab'
  end
end
```

---

## Checkpoint del Módulo 3

1. ¿Por qué `partial_def` se define en `Module` y no en `Class`? ¿Qué frase del enunciado lo pide?
2. `@partial_blocks` se escribe dentro de un método de `Module`. ¿De qué objeto es esa variable cuando `A` ejecuta `partial_def`? ¿Y cuando lo ejecuta `B`?
3. De las cuatro formas de crear el Hash, ¿cuál hace que `partial_blocks` quede vacío sin dar ningún error? ¿Qué síntoma aparecería después?
4. `partial_def` llama a `define_method(name)` cada vez. Después de tres `partial_def :concat`, ¿cuántos métodos `concat` tiene `A` y cuántas definiciones parciales? ¿Qué frase del enunciado describe eso?
5. Explicá qué líneas del `partial_def` completo corren en el momento 1 y cuáles en el momento 2.
6. ¿Qué devuelve `B.new.concat("a", "b")` si `B < A` no define nada, y por qué la variable `definiciones` es la clave de esa respuesta?
7. Reescribí el cuerpo del `define_method` usando `self.class.partial_blocks[name]` y explicá con qué instancia falla.
8. Reabrís `Tanque` y agregás `partial_def :ataca_a, [Avion]`. ¿Qué pasa con las definiciones anteriores, y por qué?
9. `G.new.quien_soy` devuelve `G`. ¿Qué "recordó" el bloque, y en qué momento lo recordó?

## Qué viene en el Módulo 4

El párrafo de `self` de la parte 2. Una línea. `definicion.call(*args)` ejecuta el bloque con el `self` que el bloque recuerda. Hay una forma de ejecutar un bloque **con otro `self`**: la instancia que recibió el mensaje. Se llama `instance_exec`, y vas a ver por qué `PartialBlock` tiene que aprender a "ejecutarse en un contexto" en vez de solo "ejecutarse".

**FIN DEL MÓDULO 3**
