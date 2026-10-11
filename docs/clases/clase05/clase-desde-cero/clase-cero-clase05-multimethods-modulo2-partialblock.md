# Clase desde cero — Multimethods — Módulo 2: PartialBlock

**Unidad:** clase05 · **Módulo:** 2 de 7 · **Densidad:** 🔴 · **Parte del enunciado:** 1, *Partial Blocks*

## Sobre este documento

**Qué cubre:** la parte 1 del enunciado completa. `PartialBlock`, un objeto que guarda una firma y un bloque y sabe responder si puede ejecutarse con ciertos argumentos (`matches?`) y ejecutarse con ellos (`call`). Se escribe **de a un método por vez**: esqueleto, constructor, `matches?` a medias, `matches?` completo, `call`. En cada paso ves qué devuelve la versión incompleta y por qué, y la sintaxis nueva se explica en el paso donde aparece. La clase completa queda al final, como consolidación.

**Qué NO cubre:** `partial_def`, guardar definiciones en una clase, elegir entre varias. Eso es la parte 2 (Módulos 3 a 5). Acá hay **un** bloque con **una** firma.

**Tené el enunciado a mano**, en la parte 1.

## De dónde venís

Del Módulo 1: firma (lista de tipos), parámetro contra argumento, y que el enunciado muestra el uso mientras la definición es tu trabajo.
De clase03 y clase04: `is_a?`, `ancestors`, bloques y procs (`proc { }`, `Proc#call`), `attr_reader`, `raise`, `unless`.

---

## 1. 🔴 Qué pide la parte 1

> 📄 **El enunciado dice** (Parte 1, *Partial Blocks*, primer párrafo):
> *"Como primera aproximación, se desea contar con la posibilidad de definir un bloque de código que aplica o no a determinados argumentos. Para ello se pide implementar la clase PartialBlock, que pueda utilizarse de la siguiente manera:"*

Y sigue con este código:

```ruby
helloBlock = PartialBlock.new([String]) do |who|
  "Hello #{who}"
end
5
helloBlock.matches?("a") #true
helloBlock.matches?(1) #false
helloBlock.matches?("a", "b") #false
```

**En criollo:** hay que escribir una clase, `PartialBlock`, cuyas instancias se construyen con **una lista de tipos** (`[String]`) y **un bloque** (`do |who| … end`), y que entienden `matches?` con cualquier cantidad de argumentos, devolviendo `true` si el bloque aplica a esos argumentos y `false` si no.

Tres cosas sobre cómo leer este pedazo, que son las que traban:

- **El enunciado muestra el uso, no la clase.** `PartialBlock.new(…)` aparece como si existiera. No existe: escribirla es el ejercicio. Todo el código de los enunciados de esta materia es así: te muestran cómo se va a usar lo que vos tenés que construir.
- **El `5` suelto es una errata del PDF.** No hace nada; ignoralo.
- **`helloBlock` está en camelCase** porque el enunciado viene de otro lenguaje. En Ruby las variables van en snake_case (`hello_block`), y RubyMine lo va a marcar. Acá lo escribimos en snake_case.

Un **bloque parcial** ("partial block") es un bloque que **no está definido para cualquier entrada**: solo para los argumentos de su firma. Es la idea matemática de función parcial: definida en una parte del dominio. Por eso puede decir "esto no es para mí" antes de ejecutarse.

---

## 2. 🔴 Paso 0: el esqueleto

> **Regla.** Antes de escribir un método, se escribe la clase con sus métodos vacíos. Un método vacío es válido, se puede llamar, y devuelve `nil`.

Lo que sabemos del uso: se construye con dos cosas, entiende `matches?`, y (más adelante en el enunciado) entiende `call`. Eso da tres métodos:

```ruby
class PartialBlock
  def initialize(types, &block)   # se llama solo, cuando alguien hace PartialBlock.new(types) { … }
  end

  def matches?(*args)             # ¿aplico a estos argumentos?
  end

  def call(*args)                 # ejecutame con estos argumentos
  end
end

hello_block = PartialBlock.new([String]) do |who|
  "Hello #{who}"
end
hello_block                 # => #<PartialBlock:0x…>    se construyó; no guardó nada todavía
hello_block.matches?("a")   # => nil                    el método existe, pero está vacío
```

**Por qué `nil`.** En Ruby todo método devuelve algo, y lo que devuelve es **el valor de la última expresión que ejecutó**. Un método sin cuerpo no ejecuta ninguna expresión, así que devuelve `nil`. Vas a ver ese `nil` cada vez que pruebes un método a medio escribir; no es un error, es la señal de que falta cuerpo.

**Sobre `initialize`.** Cuando definís `initialize` estás **pisando** el `initialize` vacío que toda clase hereda de `BasicObject`. `new` crea el objeto y le manda `initialize` con los mismos argumentos que recibió `new`. Siempre fue así, en todas las clases que escribiste: si no lo definís, corre el vacío.

**Sobre `&block`.** Un último parámetro con `&` captura el bloque que acompaña a la llamada y lo convierte en un objeto `Proc`, que se puede guardar en una variable y ejecutar después. Sin `&`, el bloque existe solo mientras dura la llamada y no hay forma de guardarlo. Es lo que permite que el bloque de `hello_block` se ejecute mucho después de que `new` terminó.

> 🛠️ **Lo que te va a marcar el editor:** si probás en `pry`, `PartialBlock.new([String]) { |who| … }` te muestra el objeto con sus variables de instancia adentro, cuando las tenga: `#<PartialBlock … @types=[String], @block=#<Proc …>>`. Ahora no muestra nada porque el constructor todavía no guarda. Y `hello_block.matches?("a")` te muestra `nil`: es el método vacío.

---

## 3. 🔴 Paso 1: el constructor guarda y valida

> 📄 **El enunciado dice** (Parte 1, después del código):
> *"Un bloque parcial se construye a partir de una lista de tipos y un bloque. El constructor debe validar que la lista de tipos tenga tantos elementos como argumentos tenga el bloque proporcionado."*

**En criollo:** `initialize` guarda las dos cosas que recibe, y antes de guardar comprueba que la cantidad de tipos coincida con la cantidad de parámetros que declara el bloque. Si no coinciden, el objeto no se construye.

(El enunciado dice "argumentos" del bloque; en rigor son sus **parámetros**, los nombres entre barras. Es la distinción del Módulo 1, y acá importa: lo que se compara es cuántos nombres declara el bloque, no qué valores le van a llegar.)

Primero, guardar:

```ruby
class PartialBlock
  def initialize(types, &block)
    @types = types            # la firma: un Array de clases o módulos
    @block = block            # el cuerpo: un Proc
  end
end

PartialBlock.new([String]) { |who| "Hello #{who}" }
# => #<PartialBlock:0x… @types=[String], @block=#<Proc:0x… (pry):1>>
#    ahora sí: pry muestra las dos variables de instancia guardadas
```

Después, validar. Para eso hace falta preguntarle al bloque cuántos parámetros declara:

```ruby
proc { |a, b| }.arity   # => 2
proc { |a| }.arity      # => 1
proc { }.arity          # => 0
```

**`arity`** es el mensaje que un Proc entiende para decir cuántos parámetros declara. Es una cantidad, no una lista de tipos: Ruby no declara tipos, y justamente por eso la firma la ponemos nosotros en el Array.

```ruby
class PartialBlock
  def initialize(types, &block)
    unless block.arity == types.size          # también: if block.arity != types.size (equivalente exacto)
      raise ArgumentError, "la firma tiene #{types.size} tipos y el bloque #{block.arity} parámetros"
    end                                        # también: raise ArgumentError.new("…") (misma cosa)
    @types = types
    @block = block
  end
end

PartialBlock.new([]) { }
# => #<PartialBlock:0x… @types=[], @block=#<Proc …>>    cero tipos, cero parámetros: se construye

PartialBlock.new([String]) { }
# => ArgumentError: la firma tiene 1 tipos y el bloque 0 parámetros

PartialBlock.new([String]) { |a, b| }
# => ArgumentError: la firma tiene 1 tipos y el bloque 2 parámetros

PartialBlock.new([String])
# => NoMethodError: undefined method `arity' for nil:NilClass
#    sin bloque, block es nil; el mensaje es feo, pero también falla al nacer
```

**Por qué fallar acá y no después.** Un `PartialBlock` con dos tipos y un parámetro nunca va a poder ejecutarse bien. Si lo dejás construir, el error aparece mucho después, en algún `call`, lejos de la línea que lo causó. Fallar en el constructor (*fail-fast*) hace que el error señale la línea del `partial_def` mal escrito.

### `raise`, en sus dos formas

> **Regla.** `raise ClaseDeError, "mensaje"` y `raise ClaseDeError.new("mensaje")` hacen exactamente lo mismo: crean una instancia de esa clase de error con ese mensaje y la lanzan. Sin mensaje, el mensaje es el nombre de la clase.

| Escribís | Ruby entiende | Sale (rescatado) |
|---|---|---|
| `raise ArgumentError, "msg"` | Clase y mensaje; Ruby hace el `new` | `ArgumentError` con mensaje `"msg"` |
| `raise ArgumentError.new("msg")` | Vos hacés el `new`; Ruby lanza el objeto | `ArgumentError` con mensaje `"msg"` |
| `raise ArgumentError` | Sin mensaje | `ArgumentError` con mensaje `"ArgumentError"` |
| `raise "msg"` | Sin clase | `RuntimeError` con mensaje `"msg"` |

> 🛠️ **Lo que te va a marcar el editor:** al escribir `raise`, RubyMine te sugiere `ArgumentError.new(…)`. No es una corrección: es la segunda fila de la tabla. Las dos son correctas; el material usa la primera porque es más corta.

> 🕳️ **Madriguera — `arity` con parámetros raros**
> Con `*x`, un proc devuelve un número negativo (`proc { |*a| }.arity` → `-1`). Con opcionales, un proc devuelve positivo (`proc { |a, b = 1| }.arity` → `1`) y una lambda negativo (`-2`). Y `parameters` devuelve la **categoría** de cada parámetro (obligatorio, opcional, splat, con nombre), nunca el tipo del valor. Para este ejercicio alcanza con parámetros comunes.
> *Volvé al camino — esto se profundiza aparte, otro día.*

---

## 4. 🔴 Paso 2: `matches?`, primero solo la cantidad

> 📄 **El enunciado dice** (Parte 1, tercer párrafo):
> *"Un bloque parcial bien construido debe ser capaz de validar si está definido para un conjunto de valores dado, es decir, si podría ser evaluado con esos valores cómo parámetro. Esto se dá si los tipos de los argumentos son los que se especificaron en la definición y si además son la misma cantidad que los argumentos."*

**En criollo:** `matches?` recibe argumentos (los valores reales) y responde `true` si son **tantos como tipos tiene la firma** y **cada uno es del tipo que está en su posición**. Dos chequeos: cantidad primero, tipos después. Este paso hace el primero.

### `*args`: recibir cualquier cantidad de argumentos

> **Regla.** Un parámetro con asterisco (`*args`) **junta** en un Array todos los argumentos que lleguen, sean cuantos sean. `args` es siempre un Array, aunque llegue un solo valor o ninguno.

```ruby
def cuantos(*args)                      # args es SIEMPRE un Array
  "recibí #{args.size}: #{args.inspect}"
end

puts cuantos             # => recibí 0: []
puts cuantos(1)          # => recibí 1: [1]
puts cuantos(1, "a", :b) # => recibí 3: [1, "a", :b]
```

`matches?("a", "b")` entonces recibe `args = ["a", "b"]`, y la cantidad es `args.size`. Para compararla con la firma hace falta leer `@types`; se lo hacemos accesible con `attr_reader`:

```ruby
class PartialBlock
  attr_reader :types, :block      # crea los métodos types y block, que devuelven @types y @block
                                  # también: usar @types y @block directo adentro de la clase (funciona igual)
  def matches?(*args)
    unless args.size == types.size
      false
    end
  end
end

hello_block = PartialBlock.new([String]) { |who| "Hello #{who}" }
hello_block.matches?("a", "b")   # => false   distinta cantidad: bien
hello_block.matches?("a")        # => nil     ¡misma cantidad, y devuelve nil!
```

El primer caso anda y el segundo no. **Por qué `nil`:** cuando `args.size == types.size`, el `unless` no entra, y un `unless` sin rama `else` que no entra vale `nil`. Como es la última expresión del método, el método devuelve `nil`. Y en el primer caso, el `false` suelto adentro del `unless` se calcula y, como es la última expresión, sale. Funcionó de casualidad.

(Sobre `attr_reader` contra `@types` directo: adentro de la clase las dos formas leen lo mismo. El material usa los lectores porque `types` y `block` los van a necesitar desde **afuera** en los módulos siguientes, y porque si algún día `types` se calcula en vez de guardarse, solo cambia el método y no cada línea que lo usa.)

### `return`: cortar el método

> **Regla.** `return valor` termina el método en ese punto y devuelve `valor`. Sin `return`, un método devuelve el valor de la última expresión que ejecutó. Un `false` suelto en el medio se calcula y se pierde.

```ruby
def prueba
  return 1      # el método termina acá
  2             # esta línea nunca corre
end
prueba          # => 1

def ultima
  5                     # se calcula y se descarta
  "esto es lo que sale" # última expresión: es el valor del método
end
ultima          # => "esto es lo que sale"

def vacio; end
vacio           # => nil
```

Con `return`, el corte por cantidad queda bien:

```ruby
class PartialBlock
  def matches?(*args)
    unless args.size == types.size
      return false                # corta: distinta cantidad → false, y no sigue
    end
    # (acá va el chequeo de tipos, en el paso siguiente)
  end
end

hello_block.matches?("a", "b")   # => false
hello_block.matches?("a")        # => nil     sigue nil, pero ahora es porque FALTA el paso 3
```

Las tres formas de escribir ese corte, sobre el mismo caso:

| Escribís | Ruby entiende | Sale con `("a", "b")` |
|---|---|---|
| `unless args.size == types.size`<br>`  return false`<br>`end` | Forma normal, en bloque | `false` |
| `return false unless args.size == types.size` | Forma modificador: la condición al final, una línea. Es la que usa el framework | `false` |
| `unless args.size == types.size; return false; end` | Con punto y coma, válido, poco común | `false` |

> 🛠️ **Lo que te va a marcar el editor:** mientras `matches?` termina en el `return false` (porque el paso 3 todavía no está), RubyMine avisa *"Redundant return keyword"*: cree que es la última línea del método. Desaparece solo al agregar lo que sigue. Ignoralo mientras construís.

---

## 5. 🔴 Paso 3: `matches?` completo, tipo por tipo

Ahora el segundo chequeo: cada argumento contra el tipo de su posición. Tres piezas nuevas: `zip` para emparejar, `all?` para exigir que todos cumplan, `is_a?` para preguntar.

### `zip`: emparejar dos listas

> **Regla.** `a.zip(b)` arma una lista de pares tomando el elemento de cada posición de `a` con el de la misma posición de `b`. El largo del resultado es **el largo de `a`** (el receptor): si `b` es más larga, lo que sobra se descarta; si es más corta, se rellena con `nil`.

```ruby
["a"].zip([String])                # => [["a", String]]
[1, "a"].zip([Integer, String])    # => [[1, Integer], ["a", String]]   cada argumento con su tipo
[1].zip([Integer, String])         # => [[1, Integer]]                  receptor más corto: descarta String
[1, 2].zip([Integer])              # => [[1, Integer], [2, nil]]        receptor más largo: rellena con nil
```

Las dos últimas filas son la razón de que el chequeo de cantidad vaya **antes** que el de tipos. Sin él:

```ruby
[1, "a"].zip([Integer]).all? { |v, t| v.is_a?(t) }
# => TypeError: class or module required     más argumentos que tipos: is_a?(nil) explota

[1].zip([Integer, String]).all? { |v, t| v.is_a?(t) }
# => true                                    menos argumentos que tipos: true FALSO (nunca miró String)
```

Con `return false unless args.size == types.size` adelante, a `zip` solo llegan listas del mismo largo.

### `all?`: exigir que todos cumplan

> **Regla.** `lista.all? { |x| condición }` es `true` cuando la condición es verdadera para **todos** los elementos, y `false` en cuanto uno falla. Sin bloque, `all?` solo pregunta si cada elemento es "verdadero" (distinto de `nil` y de `false`), sin mirar qué contiene.

```ruby
[1, "a"].zip([Integer, String]).all? { |valor, tipo| valor.is_a?(tipo) }    # => true
[1, "a"].zip([Integer, Integer]).all? { |valor, tipo| valor.is_a?(tipo) }   # => false   "a" no es Integer

[[10, 10], [20, 21]].all?    # => true    ⚠️ sin bloque: solo mira que cada par no sea nil ni false
[1, nil].all?                # => false   el nil lo tumba
```

La fila con ⚠️ es una trampa real: `all?` sin bloque parece que "compara" los pares, y no compara nada.

### El desarmado de pares en un bloque

> **Regla.** Cuando cada elemento de la lista es un Array, un bloque con **dos parámetros** recibe los dos elementos del Array por separado; un bloque con **un parámetro** recibe el Array entero. Es Ruby desarmando el par por vos; solo funciona con Arrays.

Si venís de JavaScript, donde desestructurás a mano, esto es lo que te va a parecer magia:

| Escribís | Ruby entiende | Sale |
|---|---|---|
| `[[1, Integer]].each { \|par\| p par }` | Un parámetro: el par entero | `[1, Integer]` |
| `[[1, Integer]].each { \|v, t\| p [v, t] }` | Dos parámetros: `v = 1`, `t = Integer` | `[1, Integer]` |
| `[[1, 2, 3]].each { \|a, b\| p [a, b] }` | Par de tres con dos parámetros: el tercero se descarta | `[1, 2]` |
| `[5].each { \|a, b\| p [a, b] }` | El elemento no es un Array: va entero a `a`, `b` queda `nil` | `[5, nil]` |
| `[{a: 1}].each { \|x, y\| p [x, y] }` | Un Hash no se desarma: va entero a `x` | `[{:a=>1}, nil]` |

Por eso el bloque de `all?` se escribe `|valor, tipo|`: cada elemento de `args.zip(types)` es un par `[argumento, tipo]`, y Ruby lo reparte en las dos variables.

### `is_a?`, y por qué no `.class ==` ni `instance_of?`

> **Regla.** Un argumento matchea con un tipo cuando `argumento.is_a?(tipo)` es verdadero. Eso incluye la clase exacta, cualquier superclase y cualquier módulo incluido.

```ruby
v = "hola"

v.class == String       # => true
v.class == Object       # => false   "hola" ES un Object, pero su clase no es Object
v.class == Comparable   # => false   Comparable es un módulo; ninguna clase "es" Comparable

v.instance_of?(String)  # => true    "exactamente esta clase": es la forma legible de .class ==
v.instance_of?(Object)  # => false   mismo problema

v.is_a?(String)         # => true
v.is_a?(Object)         # => true    String desciende de Object
v.is_a?(Comparable)     # => true    String incluye el módulo Comparable

String.ancestors        # => [String, Comparable, Object, Kernel, BasicObject]
#                            is_a? es verdadero para CUALQUIERA de esta lista
```

`instance_of?` y `.class ==` preguntan lo mismo ("¿es exactamente de esta clase?") y por eso ninguno sirve acá. La sección 6 muestra por qué el enunciado exige `is_a?`.

### El método completo

```ruby
class PartialBlock
  def matches?(*args)
    return false unless args.size == types.size   # 1) cantidad, primero
    args.zip(types).all? do |valor, tipo|         # 2) de a pares (argumento, tipo)...  también: { |valor, tipo| … }
      valor.is_a?(tipo)                           #    ...todos tienen que cumplir is_a?
    end
  end
end

hello_block.matches?("a")        # => true    un String, como pide la firma
hello_block.matches?(1)          # => false   un Integer no es un String
hello_block.matches?("a", "b")   # => false   dos argumentos; la firma tiene uno
```

Los tres casos del enunciado, andando.

> 🛠️ **Lo que te va a marcar el editor:** `do … end` y `{ … }` son el mismo bloque. RubyMine los convierte con Alt+Enter (Option+Enter en Mac) sobre el bloque, acción *"Convert to do..end block"* o la inversa. No hay atajo de una tecla por defecto.

---

## 6. 🔴 Paso 4: `call`, y los subtipos

> 📄 **El enunciado dice** (Parte 1, cuarto párrafo):
> *"Un bloque parcial debe poder ser ejecutado enviandole el mensaje call. Si los argumentos recibidos son válidos, retorna el resultado de ejecutar, sino, lanza un ArgumentError."*

**En criollo:** `call` primero pregunta `matches?`; si da `false`, lanza `ArgumentError`; si da `true`, ejecuta el bloque guardado con esos argumentos y devuelve lo que el bloque devolvió.

```ruby
class PartialBlock
  def call(*args)                       # * JUNTA: args es un Array con todos los argumentos
    unless matches?(*args)              # también: self.matches?(*args) (el self. es opcional acá)
      raise ArgumentError, "los argumentos no coinciden con la firma #{types}"
    end
    block.call(*args)                   # * DESARMA: el Array vuelve a ser argumentos sueltos para el bloque
  end
end

hello_block.call("world!")   # => "Hello world!"
hello_block.call(1)          # => ArgumentError: los argumentos no coinciden con la firma [String]
hello_block.call("a", "b")   # => ArgumentError: los argumentos no coinciden con la firma [String]
```

**El asterisco en dos sentidos, en el mismo método.** En `def call(*args)` **junta**: los argumentos sueltos se vuelven un Array. En `block.call(*args)` **desarma**: el Array se vuelve argumentos sueltos, para que el bloque los reciba en `|who|` o en `|left, right|`. Si te olvidás el segundo asterisco:

```ruby
block.call(args)             # sin asterisco: el bloque recibe UN argumento, el Array entero
# => "Hello [\"world!\"]"    who = ["world!"], y el string interpola el Array
```

Y `matches?(*args)` adentro de `call` también lleva asterisco por lo mismo: `matches?` espera argumentos sueltos, no un Array.

> 📄 **El enunciado dice** (Parte 1, quinto párrafo):
> *"Cabe aclarar que un bloque puede ser ejecutado con instancias de subtipos de los que define y debe funcionar"*, y da el ejemplo de `pairBlock` con `[Object, Object]`.

Un **subtipo** de un tipo `T` es cualquier clase que descienda de `T` o que incluya el módulo `T`: `String` es subtipo de `Object` (desciende de él) y de `Comparable` (lo incluye). "Instancias de subtipos" son objetos cuya clase es un subtipo del que dice la firma. Es exactamente lo que `is_a?` acepta y `.class ==` rechaza:

```ruby
pair_block = PartialBlock.new([Object, Object]) do |left, right|
  [left, right]
end
pair_block.call("hello", 1)      # => ["hello", 1]    String e Integer son subtipos de Object
```

> 📄 **El enunciado dice** (Parte 1, última línea):
> *"Tener en cuenta que los módulos también cuentan como tipos y deben ser soportados para usar como parte de la firma."*

Sale gratis con `is_a?`, porque `is_a?` mira también los módulos incluidos:

```ruby
ordenable = PartialBlock.new([Comparable]) { |x| "#{x} se puede ordenar" }
ordenable.matches?(3)            # => true    Integer incluye Comparable
ordenable.matches?("a")          # => true    String también
ordenable.matches?([1, 2])       # => false   Array no
```

> 🎯 **Para el parcial, si te preguntan** por qué la firma se compara con `is_a?`:
> Porque `is_a?` respeta el subtipado: un argumento matchea con su clase, con cualquier superclase y con cualquier módulo que incluya. Así una definición para `[Object, Object]` acepta cualquier par de objetos, y un módulo puede usarse como tipo de la firma. `instance_of?` y `.class ==` solo aceptan la clase exacta.

---

## 7. 🔴 Las dos validaciones, lado a lado

`PartialBlock` valida dos veces, en dos momentos distintos, y se confunden fácil. Esta es la tabla para no mezclarlas:

| | Al construir (`initialize`) | Al usar (`matches?` / `call`) |
|---|---|---|
| Cuándo | Momento 1: cuando se escribe la definición | Momento 2: cuando llega el mensaje |
| Qué se compara | La **lista de tipos** contra **`block.arity`** (los parámetros que declara el bloque) | Los **argumentos reales** contra la **lista de tipos** |
| Qué se mira | Solo la **cantidad** | La cantidad, y después **tipo por tipo** con `is_a?` |
| Si falla | `raise ArgumentError`: el objeto no se construye | `matches?` devuelve `false`; `call` lanza `ArgumentError` |
| Para qué | Que el `PartialBlock` tenga sentido | Que este bloque aplique a estos valores |

La primera compara **parámetros** (nombres declarados) con tipos; la segunda compara **argumentos** (valores reales) con tipos. Es la distinción del Módulo 1 puesta a trabajar.

---

## 8. 🔴 Las piezas armadas

La clase completa, tal como quedó. Es lo que vas a reconocer en cualquier resolución de este ejercicio, y no cambia hasta el Módulo 4.

```ruby
class PartialBlock
  attr_reader :types, :block            # lectores: los módulos siguientes los van a necesitar

  def initialize(types, &block)         # &block: el bloque que recibe el método, como objeto Proc
    unless block.arity == types.size    # arity: cuántos parámetros declara el bloque
      raise ArgumentError, "la firma tiene #{types.size} tipos y el bloque #{block.arity} parámetros"
    end
    @types = types                      # la firma: un Array de clases o módulos
    @block = block                      # el cuerpo: un Proc
  end

  def matches?(*args)                   # *args junta: cualquier cantidad de argumentos, como Array
    return false unless args.size == types.size   # distinta cantidad → no matchea, sin mirar tipos
    args.zip(types).all? do |valor, tipo|         # de a pares (argumento, tipo)...
      valor.is_a?(tipo)                           # ...todos tienen que cumplir is_a?
    end
  end

  def call(*args)
    unless matches?(*args)              # primero preguntar, después ejecutar
      raise ArgumentError, "los argumentos no coinciden con la firma #{types}"
    end
    block.call(*args)                   # *args desarma: el Proc recibe los argumentos sueltos
  end
end
```

```
# ¿CÓMO FUNCIONA?  hello_block.call("world!")
# 1. call recibe args = ["world!"]
# 2. matches?("world!"): args.size (1) == types.size (1) → sigue
#    ["world!"].zip([String]) → [["world!", String]]
#    "world!".is_a?(String) → true; all? → true
# 3. block.call("world!") → ejecuta el bloque con who = "world!" → "Hello world!"
#
# hello_block.call(1)
# 2. matches?(1): 1.is_a?(String) → false; all? → false
# 3. raise ArgumentError → nunca llega al bloque
```

### Las formas de pasar el bloque al constructor

| Escribís | Ruby entiende | Sale |
|---|---|---|
| `PartialBlock.new([String]) { \|s\| s.upcase }` | Bloque literal; `&block` lo captura | `.call("a")` → `"A"` |
| `PartialBlock.new([String]) do \|s\| s.upcase end` | Igual que el anterior, forma larga | `.call("a")` → `"A"` |
| `mi_proc = proc { \|s\| s.upcase }`<br>`PartialBlock.new([String], &mi_proc)` | El `&` en la llamada convierte el Proc en bloque; `&block` lo vuelve a capturar | `.call("b")` → `"B"` |
| `PartialBlock.new([String], mi_proc)` | Sin `&`: el Proc viaja como **segundo argumento común** | `ArgumentError: wrong number of arguments (given 2, expected 1)` |

> 🕳️ **Madriguera — proc contra lambda**
> Una lambda (`lambda { }` o `-> { }`) sí exige la cantidad exacta de argumentos y falla con `ArgumentError`; un proc ignora los de más y rellena con `nil` los que faltan. El framework usa procs porque los bloques `do … end` que recibe `partial_def` llegan como procs, y por eso `matches?` valida adelante.
> *Volvé al camino — esto se profundiza aparte, otro día.*

---

## 9. 🟡 Los tests de esta pieza

Los casos del enunciado, como tests de RSpec. Son los ejemplos de las secciones 5 y 6, en el formato en que los vas a ver en el repo.

```ruby
describe PartialBlock do
  let(:hello_block) { PartialBlock.new([String]) { |who| "Hello #{who}" } }

  it 'matchea con un String' do
    expect(hello_block.matches?("a")).to be true
  end
  it 'no matchea con un Integer' do
    expect(hello_block.matches?(1)).to be false
  end
  it 'no matchea con más argumentos que tipos' do
    expect(hello_block.matches?("a", "b")).to be false
  end
  it 'se ejecuta con argumentos válidos' do
    expect(hello_block.call("world!")).to eq "Hello world!"
  end
  it 'falla con argumentos inválidos' do
    expect { hello_block.call(1) }.to raise_error(ArgumentError)
  end
  it 'acepta subtipos de los tipos de la firma' do
    pair_block = PartialBlock.new([Object, Object]) { |l, r| [l, r] }
    expect(pair_block.call("hello", 1)).to eq ["hello", 1]
  end
  it 'falla al construirse si la firma y el bloque no coinciden' do
    expect { PartialBlock.new([String, String]) { |a| a } }.to raise_error(ArgumentError)
  end
end
```

---

## Checkpoint del Módulo 2

1. ¿Por qué un método vacío devuelve `nil`? ¿Y por qué `matches?` con solo el `unless` del paso 2 devolvía `nil` para `("a")`?
2. Las dos validaciones de `PartialBlock`: ¿qué compara cada una, en qué momento, y qué pasa si falla?
3. `"hola".is_a?(Object)` da `true`, `"hola".instance_of?(Object)` da `false`. ¿Cuál usa `matches?` y qué se perdería con el otro?
4. ¿Qué devuelve `[1].zip([Integer, String])`? ¿Y `[1, 2].zip([Integer])`? ¿Por qué `matches?` compara los tamaños **antes** de hacer `zip`?
5. `block.call(*args)`: ¿qué cambia si escribís `block.call(args)`, sin asterisco, para `hello_block`? ¿Cuál de los dos asteriscos de `call` junta y cuál desarma?
6. ¿Qué recibe `v` y qué recibe `t` en `[[1, Integer]].each { |v, t| … }`? ¿Y en `[5].each { |v, t| … }`?
7. ¿Qué devuelve `[[10, 10], [20, 21]].all?` y por qué no sirve para comparar los pares?
8. ¿En qué línea falla `PartialBlock.new([String, Integer]) { |s| s }` y por qué conviene que falle ahí y no después?
9. ¿Qué diferencia hay entre `PartialBlock.new([String], &mi_proc)` y `PartialBlock.new([String], mi_proc)`?
10. Definí *subtipo* y dá un ejemplo con un módulo.

## Qué viene en el Módulo 3

La parte 2 del enunciado: *Multi Methods*. Ya tenemos la pieza que sabe "¿esto es para mí?". Falta el que las colecciona y elige: `partial_def`. Se define abriendo `Module`, guarda un `PartialBlock` por cada definición **en el objeto clase**, y crea con `define_method` un único método que, cuando llega el mensaje, recorre las definiciones y ejecuta la que matchea. Como acá, de a un pedazo por vez.

**FIN DEL MÓDULO 2**
