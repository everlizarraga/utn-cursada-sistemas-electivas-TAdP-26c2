# Clase desde cero — Multimethods — Módulo 4: Contexto

**Unidad:** clase05 · **Módulo:** 4 de 7 · **Densidad:** 🔴 · **Parte del enunciado:** 2, el párrafo de `self`

## Sobre este documento

**Qué cubre:** cómo hacer que, dentro de una definición parcial, `self` sea el objeto que recibió el mensaje. Es una línea de código (`instance_exec`) y una decisión de diseño (dónde ponerla). Se construye en dos pasos: primero la línea donde funciona, después movida al lugar que le corresponde. Al terminar, el framework cumple todo lo que la parte 2 pide sobre `self`, y queda el archivo entero al final.

**Qué NO cubre:** distancia, `multimethods`, `respond_to?` con firma, firma repetida (Módulo 5) ni duck typing (Módulo 6).

**Tené el enunciado a mano**, en la parte 2, el párrafo que empieza con "Cabe aclarar que el código de los multimethods".

## De dónde venís

Del Módulo 3, sección 8: `G.new.quien_soy` devuelve `G` porque el bloque recuerda el `self` del lugar donde fue escrito, que es la clase.
De clase04: `instance_eval` e `instance_exec` cambian el `self` con el que se ejecuta un bloque; un bloque se pasa a un método con `&`.

---

## 1. 🔴 Qué pide el párrafo de `self`

> 📄 **El enunciado dice** (Parte 2, después de los ejemplos de `respond_to?`):
> *"Cabe aclarar que el código de los multimethods debe poder hacer referencia a self, que debe apuntar al objeto receptor del mensaje:"*

Y sigue con el ejemplo de `Tanque`:

```ruby
class Tanque
  # ... implementación de tanque

  partial_def :ataca_a, [Tanque] do |objetivo|
    self.ataca_con_canion(objetivo)
  end

  partial_def :ataca_a, [Soldado] do |objetivo|
    self.ataca_con_ametralladora(objetivo)
  end
end
```

**En criollo:** adentro del bloque de un `partial_def`, `self` tiene que ser **el tanque que recibió `ataca_a`**, para que pueda llamar a sus propios métodos (`ataca_con_canion`) y usar su propio estado. Con el código del Módulo 3 eso no pasa: `self` es la clase `Tanque`, y `Tanque.ataca_con_canion` no existe.

Este párrafo es corto y es **el más importante de la parte 2**. El error de contexto es el que más se repite en los individuales, porque el código "anda" para definiciones que solo usan sus parámetros (`s1 + s2`) y explota recién cuando una definición quiere hablar con el receptor.

---

## 2. 🔴 Paso 0: el síntoma, con el ejemplo del enunciado

> **Regla.** Una clausura recuerda el `self` del lugar donde fue escrita. `Proc#call` la ejecuta con ese `self` recordado, sin posibilidad de cambiarlo.

```ruby
class Soldado
  def to_s; "un soldado"; end
end

class Tanque
  def to_s; "un tanque"; end
  def ataca_con_ametralladora(o); "ráfaga a #{o}";   end
  def ataca_con_canion(o);        "cañonazo a #{o}"; end

  partial_def :ataca_a, [Soldado] do |objetivo|     # el bloque se escribe acá, donde self = Tanque
    self.ataca_con_ametralladora(objetivo)
  end
end

Tanque.new.ataca_a(Soldado.new)
# => NoMethodError: undefined method `ataca_con_ametralladora' for Tanque:Class
#    "for Tanque:Class": self adentro del bloque es la CLASE Tanque, no la instancia
```

El mensaje de error lo dice: *for Tanque:Class*. `find` eligió bien, `matches?` dio `true`, los argumentos llegaron; lo único mal es **quién es `self`** cuando corre el bloque. Es el hilo que el Módulo 3 dejó abierto.

---

## 3. 🔴 Paso 1: ejecutar el bloque con otro `self`

> **Regla.** `objeto.instance_exec(arg1, arg2, …, &bloque)` ejecuta `bloque` con `self` igual a `objeto`, pasándole `arg1, arg2, …` como parámetros. Es la herramienta para ejecutar un Proc guardado con un `self` distinto del que recuerda **y** con argumentos.

El mismo bloque, ejecutado de cuatro formas. `t` es un tanque, `s` un soldado, y el bloque quiere hablar con el receptor:

```ruby
bloque = proc { |objetivo| self.ataca_con_ametralladora(objetivo) }   # escrito en el nivel principal
t = Tanque.new
s = Soldado.new
```

| Escribís | Ruby entiende | Sale |
|---|---|---|
| `bloque.call(s)` | Ejecuta con el `self` **recordado** (acá, `main`) | ``NoMethodError: undefined method `ataca_con_ametralladora' for main:Object`` |
| `t.instance_exec(s, &bloque)` | `self` = `t`; `objetivo` = `s` | `"ráfaga a un soldado"` ✅ |
| `t.instance_eval(&bloque)` | `self` = `t`; **no pasa argumentos**: al bloque le llega el propio receptor como parámetro | `"ráfaga a un tanque"`  (el tanque se ataca a sí mismo) |
| `t.instance_exec([s], &bloque)` | `self` = `t`; `objetivo` = el Array entero | `"ráfaga a [#<Soldado:0x…>]"` |

La segunda fila es la que queremos. Las otras dos que "andan" son peores que la que falla: devuelven un resultado incorrecto sin ningún error. (`main` es el objeto sobre el que corre el código escrito fuera de toda clase; es el `self` que ese bloque recordó.)

**Por qué `instance_exec` y no `instance_eval`.** Los dos cambian `self`. La diferencia es qué recibe el bloque como parámetros: `instance_eval` le pasa **el receptor** (una convención de Ruby para bloques que quieren nombrarlo), `instance_exec` le pasa **lo que vos le des**. Las definiciones parciales tienen parámetros propios (`|objetivo|`, `|s1, s2|`), así que hace falta `instance_exec`.

> 🎯 **Para el parcial, si te preguntan** por la diferencia entre `instance_eval` e `instance_exec`:
> Los dos ejecutan un bloque con `self` cambiado al receptor. `instance_eval` no admite argumentos propios (le pasa el receptor al bloque); `instance_exec` sí, y por eso es el que sirve para ejecutar un bloque que declara parámetros, como una definición parcial.

Con eso, la línea que cambia en `partial_def`. En el momento 2, adentro del `define_method`, `self` **ya es** la instancia que recibió el mensaje; solo hay que usarla como contexto:

```ruby
class Module
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
      self.instance_exec(*args, &definicion.block)    # ← antes: definicion.call(*args)
    end                                                #   self acá es la instancia; el bloque sale del PartialBlock
  end
end

Tanque.new.ataca_a(Soldado.new)    # => "ráfaga a un soldado"
```

Anda. Es la forma más directa, y la que primero sale al escribirlo.

### ⚠️ Trampa: pasar el PartialBlock en vez del bloque

`&` necesita un Proc (o algo convertible a Proc). Un `PartialBlock` no lo es, aunque contenga uno:

```ruby
self.instance_exec(*args, &definicion)
# => TypeError: wrong argument type PartialBlock (expected Proc)

self.instance_exec(*args, &definicion.block)    # el Proc que el PartialBlock guarda
# => "ráfaga a un soldado"
```

> 🛠️ **Lo que te va a marcar el editor:** RubyMine no marca `&definicion` como error antes de ejecutar; el `TypeError` aparece recién al correr. Y dentro del bloque de `instance_exec` tampoco autocompleta los métodos del receptor, porque no puede saber quién va a ser `self`.

---

## 4. 🔴 Paso 2: la línea va en `PartialBlock`

> **Regla.** `PartialBlock` gana un mensaje, `call_in_context(contexto, *args)`, que valida como `call` y ejecuta el bloque con `contexto.instance_exec(*args, &block)`. El método definido por `partial_def` lo invoca pasándose a sí mismo (`self`, la instancia) como contexto.

La versión del paso 1 funciona, pero le saca el bloque al `PartialBlock` y lo ejecuta desde afuera, sin pasar por `matches?`. Quien sabe validar y ejecutar es el `PartialBlock`; lo que le falta es saber ejecutarse **en un contexto**:

```ruby
class PartialBlock
  def call_in_context(contexto, *args)
    unless matches?(*args)                       # misma validación que call
      raise ArgumentError, "los argumentos no coinciden con la firma #{types}"
    end
    contexto.instance_exec(*args, &block)        # ejecutar el bloque CON self = contexto
  end
end

class Module
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
      definicion.call_in_context(self, *args)    # ← la línea final: el PartialBlock se ejecuta con self como contexto
    end
  end
end
```

```
# ¿CÓMO FUNCIONA?  t.ataca_a(s)
# 1. El método ataca_a (definido con define_method) corre con self = t
# 2. find elige el PartialBlock [Soldado]
# 3. definicion.call_in_context(t, s)
# 4. matches?(s) → true
# 5. t.instance_exec(s, &block) → el bloque corre con self = t y objetivo = s
# 6. self.ataca_con_ametralladora(s) → t.ataca_con_ametralladora(s) → "ráfaga a un soldado"
```

Las dos formas, sobre el mismo caso:

| Escribís | Ruby entiende | Sale |
|---|---|---|
| `self.instance_exec(*args, &definicion.block)` (paso 1) | Le sacás el bloque al `PartialBlock` y lo ejecutás vos; **nadie valida** | `"ráfaga a un soldado"` |
| `definicion.call_in_context(self, *args)` (paso 2) | Le pedís al `PartialBlock` que se ejecute en un contexto; él valida y ejecuta | `"ráfaga a un soldado"` |

Las dos dan lo mismo, y el material usa la segunda. **Por qué:** validar y ejecutar son responsabilidad del `PartialBlock`; es él quien sabe su firma. La primera forma lo trata como una bolsa de la que se saca el bloque, y la validación de `call` queda salteada. (En el flujo actual `find` ya garantiza que matchea, así que no se pierde un chequeo real; se pierde la encapsulación.) Si más adelante `PartialBlock` cambia cómo valida, con la segunda forma `partial_def` no se entera.

---

## 5. 🔴 Qué gana el bloque con el `self` correcto

> **Regla.** Con `self` igual al receptor, una definición parcial puede usar los métodos y el estado de la instancia, con `self.metodo`, con `metodo` a secas, o con `@atributo`.

El ejemplo del enunciado completo, más dos variantes:

```ruby
class Tanque
  partial_def :ataca_a, [Tanque] do |objetivo|
    self.ataca_con_canion(objetivo)          # self explícito, como en el enunciado
  end
  partial_def :ataca_a, [Soldado] do |objetivo|
    self.ataca_con_ametralladora(objetivo)
  end
  partial_def :ataca_a, [Integer] do |n|
    ataca_con_canion(n)                      # self implícito: mismo receptor    también: self.ataca_con_canion(n)
  end
end

t = Tanque.new
t.ataca_a(Soldado.new)    # => "ráfaga a un soldado"
t.ataca_a(Tanque.new)     # => "cañonazo a un tanque"
t.ataca_a(3)              # => "cañonazo a 3"

class Guerrero
  attr_reader :energia
  def initialize(e); @energia = e; end

  partial_def :pelear_con, [Guerrero] do |otro|
    "#{@energia} contra #{otro.energia}"     # @energia es la del receptor
  end
end
Guerrero.new(10).pelear_con(Guerrero.new(7))   # => "10 contra 7"

class G
  partial_def :quien_soy, [] do self end
end
G.new.quien_soy           # => #<G:0x…>    la instancia; se cerró el hilo del Módulo 3
```

**Por qué esto era el problema más importante.** Sin el contexto correcto, el framework "anda" para definiciones que solo usan sus parámetros y falla, o hace algo raro, en cuanto una definición quiere hablar con el objeto que la recibió. Que `self` sea el receptor es lo que convierte a `partial_def` en un método de verdad y no en una función suelta con nombre.

> 🎯 **Para el parcial, si te preguntan** por qué `self` dentro de una definición parcial no es el receptor si no se hace nada especial:
> Porque el bloque es una clausura escrita en el cuerpo de la clase, y una clausura recuerda el `self` del lugar donde se escribió: la clase. Para ejecutarlo con `self` igual a la instancia hay que pedirlo explícitamente con `instance_exec`, pasándole los argumentos.

---

## 6. 🔴 Las piezas armadas

Todo el framework, en el estado en que queda al final de este módulo. Es un archivo ejecutable.

```ruby
# multimethods.rb — estado al final del Módulo 4

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
      definicion.call_in_context(self, *args)
    end
  end
end
```

Son unas 50 líneas. Cada una tiene una razón que ya leíste; si alguna no la tiene para vos, esa es la pregunta para el chat.

### Los tests que este módulo agrega

```ruby
describe 'self dentro de una definición parcial' do
  it 'es el receptor del mensaje' do
    class Tanque
      def ataca_con_canion(o); "cañonazo"; end
      partial_def :ataca_a, [Tanque] do |objetivo| self.ataca_con_canion(objetivo) end
    end
    expect(Tanque.new.ataca_a(Tanque.new)).to eq "cañonazo"
  end
  it 've el estado del receptor' do
    class Guerrero
      def initialize(e); @energia = e; end
      partial_def :energia_total, [] do @energia end
    end
    expect(Guerrero.new(10).energia_total).to eq 10
  end
end
```

---

## Checkpoint del Módulo 4

1. El error del paso 0 dice *for Tanque:Class*. ¿Qué te está diciendo sobre `self`, y por qué `find` y `matches?` no tienen nada que ver con el problema?
2. `t.instance_eval(&bloque)` con `bloque = proc { |objetivo| … }` hace que el tanque se ataque a sí mismo. ¿Qué recibió `objetivo` y por qué?
3. ¿Qué error da `instance_exec(*args, &definicion)` si `definicion` es un `PartialBlock`? ¿Qué hay que pasar en su lugar?
4. `self.instance_exec(*args, &definicion.block)` y `definicion.call_in_context(self, *args)` dan el mismo resultado. ¿Cuál usa el material y qué argumento de diseño lo justifica?
5. ¿Qué diferencia hay, dentro de una definición parcial, entre escribir `self.ataca_con_canion(x)` y `ataca_con_canion(x)`?
6. Una definición parcial escribe `@energia`. ¿De qué objeto es esa variable en el momento 2, y qué pasaría con `call` en vez de `call_in_context`?
7. Explicá en dos oraciones por qué el bloque recuerda un `self` y en qué momento lo recordó.

## Qué viene en el Módulo 5

Lo que queda de la parte 2, sobre este código ya cerrado: el punto 2 de la regla de elección (cuando varias definiciones matchean, gana la más específica, con una **distancia**), las dos líneas de reflection (`multimethods` y `multimethod`), el paréntesis de "la nueva pisa la anterior", y `respond_to?` con firma sin romper el `respond_to?` de Ruby. Cada una toca un solo lugar.

**FIN DEL MÓDULO 4**
