# Clase desde cero — Prototype — Módulo 2: Propiedades

**Unidad:** clase06 · **Módulo:** 2 de 9 (+1 opcional) · **Densidad:** 🔴 · **Parte del enunciado:** 4.1, las tres primeras líneas

## Sobre este documento

**Qué cubre:** `PrototypedObject`, `set_property` y `get_property`. Se construye **de a un pedazo**: dónde se guarda una propiedad (tres opciones y la elección), la trampa del diccionario que nadie inicializó, qué devolver cuando piden una propiedad que no existe, y que `guerrero.energia` responda como mensaje. Al final del módulo, las tres primeras líneas de 4.1 andan.

**Qué NO cubre:** métodos (`set_method`, Módulo 3), `clone` (Módulo 4), prototipos (Módulo 5). Este módulo deja **abierta a propósito** una pregunta en la sección 6: por qué el getter se define como se define, y qué otra forma había.

**Tené el enunciado a mano**, en la parte 4.1, con la línea de `get_property` anotada.

## De dónde venís

Del Módulo 1: el usuario no ve clases salvo `PrototypedObject.new`; una propiedad es un dato con nombre, propio del objeto; `guerrero.energia` tiene que andar además de `get_property(:energia)`.
De clase03: una variable `@x` existe desde que se la setea, y antes de eso leerla da `nil`; `instance_variable_set` / `instance_variable_get` crean y leen variables con nombre dinámico; `define_singleton_method` define un método para un solo objeto; `attr_accessor` es un mensaje que la autoclase también entiende.
De clase04: un bloque es una clausura y ve las variables locales del lugar donde fue escrito.

---

## 1. 🔴 Qué piden las tres primeras líneas

> 📄 **El enunciado dice** (4.1, primer bloque, con la línea agregada):
> ```ruby
> guerrero = PrototypedObject.new
>
> guerrero.set_property(:energia, 100)
> expect(guerrero.get_property(:energia)).to eq(100)
> expect(guerrero.energia).to eq(100)
> ```

**En criollo:** tiene que existir una clase `PrototypedObject`; sus instancias tienen que entender `set_property` con un nombre (símbolo) y un valor; tienen que entender `get_property` con el nombre y devolver ese valor; y tienen que entender **el nombre de la propiedad como mensaje** (`guerrero.energia`), devolviendo lo mismo.

Son dos cosas de dificultad muy distinta. Guardar y devolver es Ruby de todos los días. Que un objeto responda a un mensaje **cuyo nombre recién se conoce en ejecución** es metaprogramación, y es la sección 6.

---

## 2. 🔴 Paso 0: la clase

> **Regla.** `PrototypedObject` es una clase común, con `new` común. Es el punto de entrada del framework; por dentro usa clases porque Ruby corre con clases, pero el usuario solo la toca acá.

```ruby
class PrototypedObject     # vacía por ahora
end

guerrero = PrototypedObject.new
guerrero.class         # => PrototypedObject
guerrero.energia       # => NoMethodError: undefined method `energia' for an instance of PrototypedObject
```

Un objeto sin nada adentro. Lo que sigue es ir agregándole, mensaje por mensaje, lo que el enunciado pide.

> 🕳️ **Madriguera — `Object` o `BasicObject`**
> Una implementación cuidadosa podría hacer que `PrototypedObject` herede de `BasicObject` (la clase pelada de clase04), para que los objetos prototipados no arrastren los métodos de `Object`. Acá hereda de `Object`, que es lo implícito, porque esos métodos nos sirven.
> *Volvé al camino — esto se profundiza aparte, otro día.*

---

## 3. 🔴 Paso 1: dónde vive una propiedad

> **Regla.** Hay tres lugares donde un objeto puede guardar una propiedad con nombre dinámico: una variable de instancia creada al vuelo, un accessor en su autoclase, o un diccionario propio. Las tres andan. Se diferencian en **cuánto de Ruby queda funcionando gratis** y en **cuánto se mezcla lo nuestro con lo del usuario**.

Es la primera decisión de diseño del framework, y conviene tomarla con las tres sobre la mesa, con el mismo caso: guardar `:energia` → `100` y leerlo.

### Opción A: una variable de instancia por propiedad

```ruby
class OpcionA
  def set_property(nombre, valor)
    instance_variable_set("@#{nombre}", valor)   # crea @energia en este objeto
  end
  def get_property(nombre)
    instance_variable_get("@#{nombre}")          # la lee; si no existe, nil
  end
end

a = OpcionA.new
a.set_property(:energia, 100)
a.get_property(:energia)      # => 100
a.instance_variables          # => [:@energia]     ← la propiedad ES una variable de instancia
a.get_property(:nada)         # => nil             ← variable que no existe: nil, como siempre en Ruby
```

### Opción B: un accessor en la autoclase

```ruby
class OpcionB
  def set_property(nombre, valor)
    singleton_class.attr_accessor(nombre)   # un getter y un setter solo para este objeto
    send("#{nombre}=", valor)               # y se usa el setter recién creado
  end
  def get_property(nombre)
    send(nombre)                            # se usa el getter
  end
end

b = OpcionB.new
b.set_property(:energia, 100)
b.get_property(:energia)      # => 100
b.energia                     # => 100                       ← el mensaje anda GRATIS
b.singleton_methods           # => [:energia, :energia=]      ← getter y setter, en la autoclase
b.get_property(:nada)         # => NoMethodError: undefined method `nada' for #<OpcionB:0x…>
```

### Opción C: un diccionario

```ruby
class OpcionC
  def set_property(nombre, valor)
    @propiedades[nombre] = valor     # ⚠️ así como está, explota: ver sección 4
  end
  def get_property(nombre)
    @propiedades[nombre]
  end
end
```

### Comparación

| | A · variable `@` | B · accessor en la autoclase | C · diccionario |
|---|---|---|---|
| `guerrero.energia` | no anda sola | **anda gratis** | no anda sola |
| `respond_to?(:energia)`, `methods` | no la ven | **la ven gratis** | no la ven |
| Propiedad inexistente | `nil` | `NoMethodError` | lo que vos decidas |
| Nombres válidos | solo nombres de variable (`"potencial ofensivo"` → `NameError`) | solo nombres de método | **cualquier clave** |
| ¿Se distingue una propiedad de una variable que el usuario seteó por su cuenta? | **No**: `@energia` y `@contador` son iguales para Ruby | A medias: hay que mirar qué métodos son nuestros | **Sí**: lo nuestro está en un solo lugar |
| Listar las propiedades | `instance_variables` (y trae las que no son propiedades) | `singleton_methods` (ídem) | `keys` del diccionario |

**El criterio.** Cuanto más se parece lo nuestro a cómo Ruby maneja las cosas, más herramientas de Ruby siguen funcionando sin que hagamos nada: con B, `respond_to?`, `methods`, el mensaje `energia`, todo viene de regalo. El precio es el opuesto: todo lo que Ruby hace con atributos, lo hace también con nuestras propiedades, **sin distinguir**. Y una propiedad **no es** un atributo: es un concepto nuestro, que elegimos implementar con algo parecido. En cuanto importe distinguir "esto lo seteó el usuario por metaprogramación" de "esto es una propiedad del prototipo" (listar propiedades, copiarlas, preguntar si existe), A y B obligan a llevar una lista aparte de cuáles son nuestras. C ya la tiene: el diccionario **es** esa lista.

> **Regla.** El framework guarda las propiedades en un **diccionario propio de cada objeto**. Lo que se pierde (el mensaje `energia` gratis) se construye a mano en la sección 6; lo que se gana (saber exactamente qué es una propiedad) se usa en los Módulos 4, 7 y 9.

> 💎 **Otra forma de hacerlo.** La opción A, variables de instancia creadas con `instance_variable_set`, es una implementación válida y más corta. Su trade-off aparece más adelante: cuando el enunciado pide copiar "el estado actual del prototipo" (4.2), con A hay que decidir qué variables son propiedades y cuáles no, y el `@potencial_ofensivo` que el enunciado escribe en 4.1 sí funciona tal cual con A. Con C no (Módulo 5).

> 🎯 **Para el parcial, si te preguntan** por qué conviene un diccionario y no variables de instancia para las propiedades de un objeto prototipado:
> Porque una propiedad es un concepto del framework, no un atributo de Ruby, y el diccionario mantiene las propiedades separadas de cualquier variable que el usuario o un mixin le pongan al objeto. Con variables de instancia, Ruby regala más reflexión, pero se pierde la capacidad de distinguir qué es una propiedad; y copiar, listar o preguntar por propiedades necesita esa distinción.

---

## 4. 🔴 Paso 2: el diccionario que nadie inicializó

> **Regla.** Una variable de instancia que nadie seteó vale `nil`, y `nil` no entiende `[]=`. Un diccionario hay que **crearlo** antes de usarlo; si no, el primer `set_property` explota.

```ruby
class PrototypedObject
  def set_property(nombre, valor)
    @propiedades[nombre] = valor        # @propiedades todavía no existe → es nil
  end
end

PrototypedObject.new.set_property(:energia, 100)
# => NoMethodError: undefined method `[]=' for nil
```

El error dice exactamente qué pasó: le mandaste `[]=` a `nil`. Es la trampa más común de este ejercicio, porque uno piensa "voy a ir llenando el diccionario a medida que lleguen propiedades" y se olvida de que **alguien tiene que crearlo**. En otros lenguajes esto no explota (acceder a una clave que no está devuelve algo, y el programa sigue como si anduviera); Ruby por lo menos avisa.

### Inicialización perezosa

Hay dos lugares para crear el diccionario: en `initialize`, o **la primera vez que alguien lo pide**. Se elige lo segundo, por un método lector que lo crea si no está:

```ruby
class PrototypedObject
  def set_property(nombre, valor)
    propiedades[nombre] = valor        # ya no @propiedades: el lector de abajo
  end

  def get_property(nombre)
    propiedades[nombre]
  end

  def propiedades                      # lector "perezoso": crea el diccionario la primera vez
    @__properties__ ||= {}             # si @__properties__ es nil, lo asigna; si ya tiene algo, lo deja
  end
end

guerrero = PrototypedObject.new
guerrero.instance_variables          # => []                    todavía no hay diccionario
guerrero.set_property(:energia, 100) # => 100
guerrero.instance_variables          # => [:@__properties__]    recién ahora existe
guerrero.get_property(:energia)      # => 100
```

### `||=`: asignar solo si no hay nada

> **Regla.** `x ||= valor` asigna `valor` solo si `x` es `nil` o `false`; si ya tiene algo, lo deja como está.

```ruby
x = nil
x ||= 5        # x era nil → asigna
x              # => 5
x ||= 9        # x ya vale 5 → no toca
x              # => 5
```

Es la forma normal de escribir `x = x || valor` (`# también: @__properties__ = @__properties__ || {}`). Por eso `propiedades` crea el diccionario una sola vez y después lo devuelve siempre.

**Por qué perezoso y no en `initialize`.** Las dos formas andan (`# también: def initialize; @__properties__ = {}; end`). La perezosa tiene dos ventajas chicas: un prototipo que solo define comportamiento y ninguna propiedad **no gasta un diccionario**; y el lugar donde se crea el diccionario es un método, así que alguien que extienda el framework puede redefinirlo (devolver otra estructura, con otra política) sin tocar `set_property` ni `get_property`. Es un **punto de extensión** que vino gratis.

**Por qué `@__properties__` con guiones bajos.** El objeto que estamos construyendo va a ser usado para modelar dominios de otros, y los nombres del framework conviven con los del dominio en el mismo objeto. Si alguien modela una inmobiliaria con prototipos, su objeto va a tener una propiedad `:propiedades` (sus casas), y por la sección 6 un getter con ese nombre; si nuestro lector interno también se llamara `propiedades`, el getter del usuario lo pisaría y el framework leería una lista de casas donde esperaba su diccionario. Lo mismo vale para la variable: un usuario que haga metaprogramación sobre el objeto puede tocar `@propiedades` sin saber que es nuestra. El doble guión bajo es la convención (la vas a ver en Python y en JavaScript) para decir "esto es interno del framework, no lo toques". No protege nada; avisa. (El lector se llama `propiedades` por legibilidad y en la sección 7 se vuelve privado; el nombre con guiones queda en la variable, que es lo que un clon o un `instance_variable_get` ven.)

⚠️ **Trampa: acceder a la variable en vez de al lector.** Dentro de la clase, siempre se usa `propiedades`, nunca `@__properties__` directo. Si en un método nuevo escribís `@__properties__[nombre]` antes de que alguien haya seteado algo, volvés al `NoMethodError` de arriba, porque la inicialización perezosa vive **en el lector**.

> 🛠️ **Lo que te va a marcar el editor:** RubyMine subraya `@__properties__` en `set_property` con "instance variable is not initialized" cuando lo escribís directo. Con el lector `propiedades`, el aviso desaparece.

---

## 5. 🔴 Paso 3: una propiedad que no existe

> **Regla.** Pedir una propiedad que no está definida devuelve `nil`. Es lo que hace Ruby con una variable no seteada y con una clave ausente en un Hash; el framework se comporta igual para ser predecible.

Antes de preguntar "qué pasa", conviene preguntar **"qué queremos que pase"**. Un contrato no es solo qué hace cuando lo usan bien; es también qué hace cuando lo usan mal. Para `get_property(:nada)` hay cuatro conductas posibles:

| Conducta | Qué hace | Quién lo hace así |
|---|---|---|
| Devolver un valor que representa "no hay nada" (`nil`) | Pedir algo que no está da una respuesta razonable: nada | Ruby, con variables de instancia y con `Hash#[]` |
| Fallar con un error | Pedir algo que no está es un error del que pregunta | Ruby, con `Hash#fetch` y con mensajes no entendidos |
| Error insalvable (matar el proceso) | — | Nadie, a propósito: Ruby reserva eso para romperse la VM |
| Devolver basura (lo que haya en memoria) | — | C, al leer más allá del final de un array |

Las dos últimas no se eligen; están en la tabla para que veas que son conductas posibles y que un lenguaje decide no tenerlas. Entre las dos primeras, Ruby es consistente: pedirle algo que no tiene se estandariza en `nil`.

```ruby
guerrero = PrototypedObject.new
guerrero.set_property(:energia, 100)
guerrero.get_property(:energia)   # => 100
guerrero.get_property(:vida)      # => nil      ← clave ausente en el diccionario: nil

{}[:x]                            # => nil      ← lo mismo que hace un Hash pelado
```

El diccionario ya se comporta así; no hay que escribir nada. **Cuándo se vuelve un problema:** cuando necesitás distinguir "no tenés la propiedad" de "la tenés y vale `nil`". Con el retorno solo no se puede, así que si va por `nil`, hace falta **un mensaje para preguntar** si la propiedad existe:

```ruby
class PrototypedObject
  def has_property?(nombre)
    propiedades.key?(nombre)     # key?: ¿el diccionario tiene esta clave? (true aunque el valor sea nil)
  end
end

guerrero.has_property?(:energia)   # => true
guerrero.has_property?(:vida)      # => false
{a: nil}.key?(:a)                  # => true     ← key? mira la clave, no el valor
{a: nil}[:a]                       # => nil
```

El enunciado no pide `has_property?`. Entra igual, porque va por `nil`, y porque el Módulo 7 lo necesita.

> 💎 **Otra forma de hacerlo.** Fallar: `propiedades.fetch(nombre) { raise PropertyNotFound.new(nombre, self) }`, con una excepción propia del framework. `fetch` es el `[]` que explota ante clave ausente (`{}.fetch(:x)` → `KeyError: key not found: :x`), y el bloque reemplaza ese error por uno nuestro, con el nombre y el objeto adentro. Es *fail-fast*: el error aparece donde se produjo, no tres archivos más lejos como un `nil` inexplicable. Trade-off: te alejás de cómo Ruby trata su estado, y el usuario tiene que saber que acá sí explota.

**Pisar una propiedad que ya existe.** Se pisa, sin aviso, igual que una variable. El mensaje se llama `set_property`, no `define_property`: setea, no declara. Es la misma discusión de recién, con la misma respuesta.

```ruby
guerrero.set_property(:energia, 50)
guerrero.get_property(:energia)   # => 50
```

> 🎯 **Para el parcial, si te preguntan** qué debería devolver `get_property` de una propiedad inexistente:
> Es una decisión de diseño entre devolver `nil` y fallar. Devolver `nil` sigue la política de Ruby con el estado (variables no seteadas, claves ausentes) y es predecible; a cambio, obliga a tener un mensaje aparte, como `has_property?`, para distinguir "no existe" de "vale `nil`". Fallar con una excepción propia es *fail-fast* y evita que el error aparezca lejos. Cualquiera de las dos vale si está declarada y es consistente.

---

## 6. 🔴 Paso 4: la propiedad como mensaje

> **Regla.** Para que un objeto responda `guerrero.energia`, en Ruby hay exactamente **dos** caminos: **definirle el método** `energia`, o **atrapar el mensaje** en `method_missing`. No hay un tercero. Por ahora se define el método, en la autoclase, en el momento en que la propiedad se setea.

```ruby
guerrero.energia   # => NoMethodError: undefined method `energia' for an instance of PrototypedObject
```

Este es el primer dolor de la unidad: la propiedad está guardada, pero nadie le dijo al objeto que entienda el mensaje. El nombre llega a `set_property` como un símbolo, en ejecución. Así que el método hay que definirlo **con un nombre que es un valor**: eso es `define_singleton_method`, que ya conocés. Y tiene que ser *singleton*, para un solo objeto, porque la propiedad es de ese objeto y no de todos los `PrototypedObject`:

```ruby
class PrototypedObject
  def set_property(nombre, valor)
    define_singleton_method(nombre) { get_property(nombre) }   # un getter solo para este objeto
    propiedades[nombre] = valor                                # y el valor al diccionario
  end
end

guerrero = PrototypedObject.new
guerrero.set_property(:energia, 100)
guerrero.energia                       # => 100       ← el getter lee el diccionario
guerrero.singleton_methods             # => [:energia]
guerrero.respond_to?(:energia)         # => true      ← es un método real: Ruby lo ve

PrototypedObject.new.energia           # => NoMethodError: undefined method `energia' for an instance of PrototypedObject
#                                         otro objeto no tiene la propiedad ni el getter

guerrero.set_property(:energia, 7)     # pisar la propiedad redefine el getter: inofensivo, es el mismo cuerpo
guerrero.energia                       # => 7
```

```
# ¿CÓMO FUNCIONA?  guerrero.set_property(:energia, 100); guerrero.energia
# 1. set_property recibe nombre = :energia, valor = 100
# 2. define_singleton_method(:energia) { get_property(:energia) }
#    → en la autoclase de guerrero aparece el método energia. Su cuerpo recuerda `nombre`
#      (clausura): cuando se ejecute, va a pedir get_property(:energia)
# 3. propiedades[:energia] = 100 → el diccionario (creado recién ahora) guarda 100
# 4. guerrero.energia → el lookup encuentra energia en la autoclase → ejecuta el cuerpo
#    → get_property(:energia) → propiedades[:energia] → 100
```

**Por qué el getter lee el diccionario y no captura el valor.** `{ get_property(nombre) }` y no `{ valor }`. Si el bloque devolviera `valor` directo, el getter quedaría pegado al `100` del momento de definirlo; un `set_property(:energia, 7)` posterior tendría que redefinirlo, y cualquier cambio al diccionario por otro camino (Módulo 4) no se vería. Leyendo el diccionario, el getter siempre dice lo que hay **ahora**.

**Lo que queda abierto.** El otro camino, `method_missing`, también resolvería esto: atrapar `energia`, mirar si hay una propiedad con ese nombre, devolverla. No se usa todavía porque definir el método es más simple y más seguro, y porque todavía no hay nada que lo pida. Pero el enunciado tiene una línea, unas cuantas más abajo (`espadachin.energia = 100`, un **setter**, sobre una propiedad que **nadie declaró antes**), que con "definir el método" no se puede resolver, porque no hay ningún momento anterior en el que definirlo. Ahí el único camino va a ser `method_missing`. Queda sembrado para el Módulo 6.

> 🎯 **Para el parcial, si te preguntan** de qué formas puede un objeto responder a un mensaje cuyo nombre se conoce recién en ejecución:
> Solo de dos: definiendo el método con ese nombre (con `define_method` o `define_singleton_method`, porque reciben el nombre como valor) o atrapando el mensaje en `method_missing`. Definir el método es más simple y deja a `respond_to?` y `methods` funcionando solos; `method_missing` es el único camino cuando no existe un momento previo en el que definir el método.

---

## 7. 🟡 Lo interno, privado

> **Regla.** `propiedades` es interno del framework: se hace privado para que no forme parte de la interfaz del objeto prototipado.

```ruby
class PrototypedObject
  private

  def propiedades
    @__properties__ ||= {}
  end
end

guerrero.propiedades              # => NoMethodError: private method `propiedades' called for #<PrototypedObject:0x…>
guerrero.get_property(:energia)   # => 7       ← desde adentro, los métodos públicos lo siguen usando
guerrero.respond_to?(:propiedades)  # => false
```

El costo es conocido: si alguien de afuera quiere listar las propiedades, no puede. Se agrega un mensaje para eso cuando haga falta (el Módulo 7 lo necesita; se llama `property_names`). Lo que importa es la regla: **la interfaz del objeto son `set_property`, `get_property`, `has_property?` y los getters que se van definiendo**; el diccionario es un detalle de implementación. Si alguien lo quiere tocar, hace metaprogramación, y ahí ya sabe lo que hace.

> 🕳️ **Madriguera — pérdidas de memoria y diccionarios débiles**
> El diccionario referencia a los valores y el objeto referencia al diccionario; con que alguien retenga al objeto, nada de eso se libera. Un framework de producción usaría estructuras débiles (*weak*) en algunos lugares para que el recolector de basura pueda limpiar. Acá no importa.
> *Volvé al camino — esto se profundiza aparte, otro día.*

---

## 8. 🔴 Las piezas armadas

El framework al final de este módulo:

```ruby
class PrototypedObject
  def set_property(nombre, valor)
    define_singleton_method(nombre) { get_property(nombre) }   # el getter, solo para este objeto
    propiedades[nombre] = valor                                # el valor, en el diccionario propio
  end

  def get_property(nombre)
    propiedades[nombre]                  # nil si no existe
  end

  def has_property?(nombre)
    propiedades.key?(nombre)
  end

  private

  def propiedades
    @__properties__ ||= {}               # inicialización perezosa
  end
end
```

### Los tests de esta pieza

```ruby
describe 'propiedades' do
  it 'guarda y devuelve una propiedad' do
    guerrero = PrototypedObject.new
    guerrero.set_property(:energia, 100)
    expect(guerrero.get_property(:energia)).to eq 100
    expect(guerrero.energia).to eq 100
  end
  it 'una propiedad inexistente da nil, y has_property? lo distingue' do
    guerrero = PrototypedObject.new
    expect(guerrero.get_property(:vida)).to be nil
    expect(guerrero.has_property?(:vida)).to be false
    expect { guerrero.vida }.to raise_error(NoMethodError)
  end
  it 'las propiedades son de cada objeto' do
    guerrero = PrototypedObject.new
    guerrero.set_property(:energia, 100)
    expect(PrototypedObject.new.has_property?(:energia)).to be false
    expect { PrototypedObject.new.energia }.to raise_error(NoMethodError)
  end
  it 'setear de nuevo pisa el valor' do
    guerrero = PrototypedObject.new
    guerrero.set_property(:energia, 100)
    guerrero.set_property(:energia, 50)
    expect(guerrero.energia).to eq 50
  end
end
```

---

## Checkpoint del Módulo 2

1. ¿Cuáles son los tres lugares donde puede vivir una propiedad con nombre dinámico? Para cada uno, decí una cosa que Ruby te regala y una que perdés.
2. ¿Por qué "una propiedad no es un atributo", si al final la implementamos con algo parecido?
3. `@propiedades[nombre] = valor` explota con `NoMethodError: undefined method '[]=' for nil`. Explicá cada palabra de ese error.
4. ¿Qué hace `x ||= 5` si `x` vale `nil`? ¿Y si vale `0`? ¿Y si vale `false`?
5. Dá dos razones para crear el diccionario en un lector perezoso en vez de en `initialize`.
6. ¿Por qué la variable se llama `@__properties__` y no `@propiedades`?
7. Pedir una propiedad inexistente devuelve `nil`. ¿Qué problema trae eso y con qué mensaje se resuelve?
8. ¿Cuáles son los únicos dos caminos para que `guerrero.energia` responda? ¿Cuál se eligió y por qué?
9. ¿Por qué el getter hace `get_property(nombre)` en vez de devolver `valor` directo?
10. ¿Qué línea del enunciado va a obligar, más adelante, a usar el otro camino?

## Qué viene en el Módulo 3

`set_method`: guardar en un objeto un método cuyo cuerpo llega como un proc. Hay dos formas, igual que con el getter: definir el método en la autoclase, o guardar el proc y atraparlo con `method_missing`. Vas a ver por qué con la primera `self` queda bien "sin hacer nada" y con la segunda hay que arreglarlo a mano, qué tres razones hay para no ir a `method_missing` todavía, y vas a dejar la segunda forma escrita y en espera, porque el Módulo 5 la va a necesitar.

**FIN DEL MÓDULO 2**
