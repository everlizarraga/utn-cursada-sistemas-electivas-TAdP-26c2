# Clase desde cero — Prototype — Módulo 8: Azúcar sintáctico

**Unidad:** clase06 · **Módulo:** 8 de 9 (+1 opcional) · **Densidad:** 🔴 · **Parte del enunciado:** 4.3

## Sobre este documento

**Qué cubre:** la parte 4.3 entera. `objeto.atacar_a = proc { … }` para definir un método con la sintaxis de asignación; `PrototypedObject.new { … }` con un bloque que configura el objeto; constructores que reciben un **bloque** en vez de un proc; `PrototypedConstructor.create { … }.with { … }` y `.with_properties([…])`; y `Guerrero.prototype`, cuyo test **rompe** la decisión del Módulo 5 de guardar el getter como un método más, y obliga a corregirla. Al final del módulo, la parte 4.3 anda completa.

**Qué NO cubre:** `call_next` ni múltiples prototipos (Módulo 9). Los ejemplos de 4.3 que redefinen `potencial_ofensivo` siguen usando `get_property`.

**Tené el enunciado a mano**, en la parte 4.3 entera.

## De dónde venís

Del Módulo 6: el setter en `method_missing` (3ª rama), con prioridad del método; `respond_to_missing?`.
Del Módulo 7: `PrototypedConstructor` con proc, por defecto, `copy`, `extended`; `inicializar` reparte argumentos por `arity`; `property_names`.
De clase04: un bloque se recibe en un método con `&bloque` y es `nil` si no vino; `instance_exec(&bloque)` lo corre con otro `self`; `is_a?(Proc)`; un **lambda** es un proc estricto con los argumentos (`lambda { |x| … }`).

---

## 1. 🔴 Qué pide el azúcar

> 📄 **El enunciado dice** (4.3 *Azúcar sintáctico*, primer párrafo):
> *"La implementación de prototipos que hicimos funciona, pero tiene problemas de expresividad, y realmente no es muy usable, muy cómoda para el programador. La intención ahora es entonces agregar una interfaz a nuestros objetos prototipados para que sean más fácilmente utilizables, aprovechando las características de Ruby."*

**En criollo:** nada nuevo por debajo; todo lo de 4.1 y 4.2 sigue igual. Lo que se agrega es **cómo se escribe**: cinco formas más cortas de decir lo que ya se podía decir. Cada una se apoya en una característica de Ruby que ya conocés (setters, bloques, `instance_exec`, encadenar mensajes).

---

## 2. 🔴 Paso 0: `objeto.metodo = proc { … }`

> 📄 **El enunciado dice** (4.3, primer bloque):
> ```ruby
> guerrero_proto = PrototypedObject.new
> guerrero_proto.energia = 100
> expect(guerrero_proto.energia).to eq(100)
>
> guerrero_proto.potencial_defensivo = 10
> guerrero_proto.potencial_ofensivo = 30
>
> guerrero_proto.atacar_a = proc { |otro_guerrero| ... });
> guerrero_proto.recibe_danio = proc {...}
>
> Guerrero = PrototypedConstructor.copy(guerrero_proto)
>
> un_guerrero = Guerrero.new
> Guerrero.new.atacar_a(un_guerrero)
>
> expect(un_guerrero.energia).to eq(80)
> ```
> *"La idea es que, dinámicamente, uno puede 'asignar' propiedades y métodos a los objetos prototipados."*

**En criollo:** las asignaciones de propiedades ya andan (Módulo 6). Lo nuevo es `atacar_a = proc { … }`: asignar **un proc** tiene que ser lo mismo que `set_method`. Un solo setter, que decide según **qué** le asignan: un proc es un método; cualquier otra cosa es una propiedad.

> **Regla.** Al atrapar un setter, si el valor es un `Proc` se guarda como método (`set_method`); si no, como propiedad (`set_property`).

```ruby
module Prototyped
  private

  def method_missing(selector, *args)
    bloque = find_method(selector)
    if bloque
      instance_exec(*args, &bloque)
    elsif selector.end_with?("=")
      asignar(selector.to_s.chomp("=").to_sym, args.first)      # el setter delega en asignar
    else
      super
    end
  end

  def asignar(nombre, valor)
    if valor.is_a?(Proc)                  # un proc → comportamiento
      set_method(nombre, valor)
    else                                  # cualquier otra cosa → estado
      set_property(nombre, valor)
    end
  end
end

guerrero_proto = PrototypedObject.new
guerrero_proto.energia = 100
guerrero_proto.potencial_defensivo = 10
guerrero_proto.potencial_ofensivo = 30
guerrero_proto.atacar_a = proc { |otro_guerrero|
  if otro_guerrero.potencial_defensivo < self.potencial_ofensivo
    otro_guerrero.recibe_danio(self.potencial_ofensivo - otro_guerrero.potencial_defensivo)
  end
}
guerrero_proto.recibe_danio = proc { |danio| self.energia = self.energia - danio }

guerrero_proto.has_property?(:atacar_a)        # => false    ← no es una propiedad
guerrero_proto.find_method(:atacar_a).class    # => Proc     ← es un método

Guerrero = PrototypedConstructor.copy(guerrero_proto)
un_guerrero = Guerrero.new
Guerrero.new.atacar_a(un_guerrero)
un_guerrero.energia                            # => 80       ← el bloque entero del enunciado, verbatim
```

`asignar(nombre, valor)` es `# también:` escribir el `if` adentro de `method_missing`; se saca a un método para que `method_missing` siga leyéndose como una lista de ramas.

**La consecuencia declarada:** con esta regla, **una propiedad no puede valer un proc**. `objeto.accion = proc { … }` siempre define un método. Si alguien quiere guardar un proc como dato, tiene que usar `set_property` explícito. Es un costo chico y conviene saberlo.

> 💎 **Otra forma de hacerlo.** Preguntar `valor.respond_to?(:call)` en vez de `valor.is_a?(Proc)`: cualquier objeto que entienda `call` (un `Method`, un objeto propio con `call`) pasaría como método. Es más flexible y más *duck typing*; el trade-off es que también atrapa cosas que no esperabas, y que `instance_exec(&valor)` solo acepta procs, así que habría que ejecutarlo con `valor.call(*args)` y se pierde el `self`. Con `is_a?(Proc)` entran procs y lambdas (un lambda **es** un `Proc`), y `instance_exec` los corre bien.

⚠️ **Trampa: un lambda cuenta los argumentos.** `objeto.f = lambda { |x| x }` y después `objeto.f(1, 2)` da `ArgumentError: wrong number of arguments (given 2, expected 1)`; con `proc` el 2 se ignora. Los dos son `Proc` y los dos andan como métodos; el lambda es el estricto.

---

## 3. 🔴 Paso 1: `PrototypedObject.new { … }`

> 📄 **El enunciado dice** (4.3, segundo bloque):
> *"También es incómodo repetir el receptor del mensaje en todo momento. Podemos hacer algo mejor:"*
> ```ruby
> guerrero_proto = PrototypedObject.new {
>   self.energia = 100
>   self.potencial_ofensivo = 30
>   self.potencial_defensivo = 10
>
>   self.atacar_a = proc { |otro_guerrero| ... });
>   self.recibe_danio = proc {...}
> }
> ```

**En criollo:** `new` acepta un bloque, y lo ejecuta **con `self` igual al objeto recién creado**. Adentro del bloque, `self.energia = 100` es `guerrero_proto.energia = 100`. Es exactamente `instance_exec`, en `initialize`.

> **Regla.** `PrototypedObject#initialize` recibe un bloque opcional y, si vino, lo ejecuta con `instance_exec` sobre el objeto nuevo.

```ruby
class PrototypedObject
  include Prototyped

  def initialize(&bloque)              # &bloque: el bloque pegado al new, o nil si no vino
    instance_exec(&bloque) if bloque   # correrlo con self = este objeto
  end
end

guerrero_proto = PrototypedObject.new {
  self.energia = 100
  self.potencial_ofensivo = 30
  self.potencial_defensivo = 10
  self.recibe_danio = proc { |danio| self.energia = self.energia - danio }
}
guerrero_proto.energia                     # => 100
guerrero_proto.respond_to?(:recibe_danio)  # => true
PrototypedObject.new { self }.class        # => PrototypedObject    ← self adentro es el objeto nuevo
```

El `new` de `Class` pasa el bloque a `initialize` sin tocarlo; nuestro `initialize` lo recibe con `&bloque`. `PrototypedObject.new` sin bloque sigue andando: `bloque` es `nil` y el `if` no entra.

⚠️ **Trampa: `energia = 100` sin `self.` adentro del bloque** crea una variable local y no setea nada (`PrototypedObject.new { energia = 5 }.has_property?(:energia)` → `false`). Es la trampa del Módulo 6; en un bloque de configuración se olvida más, porque "se ve" que estás adentro del objeto.

---

## 4. 🔴 Paso 2: constructores con bloque

> 📄 **El enunciado dice** (4.3, tercer bloque):
> ```ruby
> Guerrero = PrototypedConstructor.new(guerrero) do |una_energia, un_potencial_ofensivo,
>     un_potencial_defensivo|
>   self.energia = una_energia
>   self.potencial_ofensivo = un_potencial_ofensivo
>   self.potencial_defensivo = un_potencial_defensivo
> end
> ```

**En criollo:** el inicializador ya no es un proc que recibe el objeto nuevo como primer parámetro; es un **bloque** que recibe solo los argumentos, y adentro `self` es el objeto nuevo. Misma idea que `new { }` de la sección 3, aplicada al constructor.

> **Regla.** Un constructor acepta un proc (que recibe primero al objeto nuevo), **o** un bloque (que corre con `self` igual al objeto nuevo), o nada (mapa). Por dentro, los tres se convierten a la misma forma: un cuerpo `|nuevo, *args|` y una **aridad**: cuántos argumentos consume.

Es el momento de ordenar `initialize`, porque ahora hay tres entradas distintas y una sola mecánica de reparto:

```ruby
class PrototypedConstructor
  def initialize(prototipo, inicializador = nil, aridad: nil, padre: nil, &bloque)
    @prototype = prototipo
    @padre = padre
    if inicializador                                       # un proc: |nuevo, arg1, arg2, …|
      @aridad = aridad || inicializador.arity - 1          #   consume arity - 1 (el nuevo no cuenta)
      @cuerpo = inicializador
    elsif bloque                                           # un bloque: |arg1, arg2, …| con self = nuevo
      @aridad = aridad || bloque.arity                     #   consume arity (no hay parámetro para el nuevo)
      @cuerpo = proc { |nuevo, *args| nuevo.instance_exec(*args, &bloque) }   # envuelto en la forma común
    else                                                   # nada: un mapa
      @aridad = 1
      @cuerpo = inicializador_por_defecto
    end
  end

  protected

  def inicializar(nuevo, args)
    args = @padre.inicializar(nuevo, args) if @padre
    raise ArgumentError, "faltan argumentos: esperaba #{@aridad}, llegaron #{args.size}" if args.size < @aridad
    @cuerpo.call(nuevo, *args.take(@aridad))               # siempre la forma común
    args.drop(@aridad)
  end
end

Guerrero = PrototypedConstructor.new(guerrero_proto) do |una_energia, un_potencial_ofensivo, un_potencial_defensivo|
  self.energia = una_energia
  self.potencial_ofensivo = un_potencial_ofensivo
  self.potencial_defensivo = un_potencial_defensivo
end

g = Guerrero.new(1, 2, 3)
[g.energia, g.potencial_ofensivo, g.potencial_defensivo]   # => [1, 2, 3]
```

Tres cambios respecto del Módulo 7, cada uno con su porqué:

- **`@aridad` y `@cuerpo` en vez de `@inicializador`.** Antes la aridad se calculaba en cada `inicializar` desde el proc; ahora un bloque y un proc la calculan distinto, así que se decide una vez, al construir.
- **`aridad:` como parámetro con nombre, opcional.** Hace falta en la sección 5, para un inicializador cuya aridad no se puede leer de su `arity`.
- **El bloque se envuelve.** `proc { |nuevo, *args| nuevo.instance_exec(*args, &bloque) }` convierte "un bloque con `self`" en "un proc que recibe al nuevo". Así `inicializar` tiene una sola forma que llamar. Es la regla de todos los constructores de esta clase: **un proc recibe primero al objeto nuevo; un bloque corre con `self` igual al objeto nuevo.**

---

## 5. 🔴 Paso 3: `create … with` y `with_properties`

> 📄 **El enunciado dice** (4.3, cuarto bloque):
> *"También, puede ser práctico definir y utilizar el prototipo en el mismo momento:"*
> ```ruby
> Guerrero = PrototypedConstructor.create {
>   self.atacar_a = proc { |otro_guerrero| ... });
>   self.recibe_danio = proc {...}
>   }.with {
>  |una_energia, un_potencial_ofensivo, un_potencial_defensivo|
>    self.energia = una_energia
>    self.potencial_ofensivo = un_potencial_ofensivo
>    self.potencial_defensivo = un_potencial_defensivo
> }
> ```
> *"Es necesario pasarle el procedimiento del constructor para inicializar las propiedades porque no tenemos información de las propiedades existentes. También se podría definir un método para crear un constructor por defecto más sencillo:"*
> ```ruby
> Guerrero = PrototypedConstructor.create {
>   self.atacar_a = proc { |otro_guerrero| ... });
>   self.recibe_danio = proc {...}
>  }.with_properties([:energia, :potencial_ofensivo, :potencial_defensivo])
> ```

**En criollo:** `create { … }` crea el **prototipo** ahí mismo (es `PrototypedObject.new { … }` adentro) y devuelve un constructor sobre él. `.with { … }` le da a ese constructor un inicializador con bloque. `.with_properties([…])` le da uno que toma los valores **en el orden de la lista** y los setea con esos nombres. "No tenemos información de las propiedades existentes": el prototipo de `create` solo tiene métodos, así que el constructor por defecto (mapa) no tendría contra qué validar; por eso hace falta decir cómo se inicializa.

> **Regla.** `create` es un método de clase que construye el prototipo con el bloque y devuelve un constructor. `with` y `with_properties` devuelven un **constructor nuevo** sobre el mismo prototipo, con el inicializador indicado. Encadenar mensajes funciona porque cada uno devuelve un constructor.

```ruby
class PrototypedConstructor
  def self.create(&bloque)
    new(PrototypedObject.new(&bloque))                      # el prototipo, recién nacido y configurado; constructor por defecto
  end

  def with(inicializador = nil, &bloque)
    PrototypedConstructor.new(prototype, inicializador, &bloque)      # mismo prototipo, otro inicializador
  end

  def with_properties(nombres)
    PrototypedConstructor.new(prototype, proc { |nuevo, *valores|    # *valores: tantos como nombres haya
      nombres.zip(valores).each { |nombre, valor| nuevo.set_property(nombre, valor) }
    }, aridad: nombres.size)                                          # arity de |nuevo, *valores| es -2: la aridad se dice a mano
  end
end
```

`zip` empareja dos listas posición a posición: `[:a, :b].zip([1, 2])` → `[[:a, 1], [:b, 2]]`. Y acá está la razón del `aridad:` de la sección 4: `proc { |nuevo, *valores| }` tiene `arity` negativo, porque `*valores` acepta cualquier cantidad; la cantidad real la da la lista de nombres, y hay que decírsela al constructor.

```ruby
Guerrero = PrototypedConstructor.create {
  self.atacar_a = proc { |otro_guerrero|
    if otro_guerrero.potencial_defensivo < self.potencial_ofensivo
      otro_guerrero.recibe_danio(self.potencial_ofensivo - otro_guerrero.potencial_defensivo)
    end
  }
  self.recibe_danio = proc { |danio| self.energia = self.energia - danio }
}.with { |una_energia, un_potencial_ofensivo, un_potencial_defensivo|
  self.energia = una_energia
  self.potencial_ofensivo = un_potencial_ofensivo
  self.potencial_defensivo = un_potencial_defensivo
}

a = Guerrero.new(100, 50, 30)
b = Guerrero.new(100, 50, 30)
a.atacar_a(b)
b.energia                                  # => 80

GuerreroLista = PrototypedConstructor.create {
  self.recibe_danio = proc { |danio| self.energia = self.energia - danio }
}.with_properties([:energia, :potencial_ofensivo, :potencial_defensivo])

c = GuerreroLista.new(100, 50, 30)
[c.energia, c.potencial_ofensivo, c.potencial_defensivo]   # => [100, 50, 30]
GuerreroLista.new(100)                     # => ArgumentError: faltan argumentos: esperaba 3, llegaron 1
```

```
# ¿CÓMO FUNCIONA?  PrototypedConstructor.create { … }.with { |e, o, d| … }
# 1. create: PrototypedObject.new { … } → un objeto con atacar_a y recibe_danio (el prototipo)
#    → PrototypedConstructor.new(ese_objeto) → un constructor por defecto (mapa), que casi nadie usa
# 2. .with { … }: sobre ese constructor → PrototypedConstructor.new(mismo prototipo, &bloque)
#    → un constructor nuevo, con aridad 3 y cuerpo "instance_exec del bloque sobre el nuevo"
# 3. Guerrero es el constructor del paso 2. Guerrero.new(100, 50, 30) → un derivado del prototipo del paso 1
```

**Por qué `with` devuelve un constructor nuevo y no modifica el que recibe.** Para que `Guerrero.with { … }` y `Guerrero.with_properties(…)` puedan coexistir sobre el mismo prototipo sin pisarse, y para que un constructor, una vez armado, no cambie por debajo de quien ya lo usa. Es la misma razón por la que `extended` crea uno nuevo.

---

## 6. 🔴 Paso 4: `prototype`, y el test que rompe el getter

> 📄 **El enunciado dice** (4.3, quinto bloque):
> *"Si yo quisiera obtener el prototipo de un constructor de estos, debería poder pedírselo, y valen las mismas condiciones que para los prototipos con nombre:"*
> ```ruby
> atila = Guerrero.new(100, 50, 30)
>
> expect(atila.potencial_ofensivo).to eq(50)
>
> proto_guerrero = Guerrero.prototype
> proto_guerrero.potencial_ofensivo = proc {
>    1000
> }
>
> expect(atila.potencial_ofensivo).to eq(1000)
> ```

**En criollo:** `Guerrero.prototype` devuelve el prototipo (ya existe desde el Módulo 7). Y "valen las mismas condiciones": si el prototipo gana un **método** `potencial_ofensivo` después, Atila, que no definió ese método, tiene que usarlo. Es el requerimiento (a) del Módulo 5, con una diferencia: Atila **sí tiene una propiedad** `potencial_ofensivo` (vale 50), y el método nuevo del prototipo tiene que ganarle.

```ruby
atila = Guerrero.new(100, 50, 30)
atila.potencial_ofensivo                   # => 50       ✓

proto_guerrero = Guerrero.prototype
proto_guerrero.potencial_ofensivo = proc { 1000 }
atila.potencial_ofensivo                   # => 50       ✗ el enunciado espera 1000
```

**Qué pasó.** En el Módulo 5, `set_property` guarda el getter como un método más, **en el diccionario de métodos del propio objeto**. Cuando `with` hizo `self.potencial_ofensivo = 50` sobre Atila, Atila quedó con un método `potencial_ofensivo` propio (el getter). `find_method` busca primero en Atila, encuentra ese getter, y nunca llega al método del prototipo. Lo que el enunciado quiere es que **un método de la cadena le gane a una propiedad propia**; con el getter disfrazado de método, es al revés.

Es la "pata corta" anunciada en el Módulo 5. Se tomó esa decisión porque unificaba todo en un mecanismo, y aguantó toda la 4.1 y la 4.2. Acá se cae, y la corrección es la otra opción que ya estaba sobre la mesa en el Módulo 2: resolver la propiedad **en `method_missing`**, después de los métodos.

> **Regla.** `set_property` solo guarda el valor. `method_missing` resuelve en este orden: un método en toda la cadena; si no, una propiedad **propia**; si no, un setter; si no, `super`. Así un método del prototipo le gana a una propiedad del derivado, y una propiedad solo responde si nadie en la cadena tiene un método con ese nombre.

```ruby
module Prototyped
  def set_property(nombre, valor)
    propiedades[nombre] = valor            # ya no hay getter: la propiedad se resuelve en method_missing
  end

  private

  def method_missing(selector, *args)
    bloque = find_method(selector)
    if bloque
      instance_exec(*args, &bloque)        # 1º un método, en toda la cadena
    elsif has_property?(selector)
      get_property(selector)               # 2º una propiedad propia
    elsif selector.end_with?("=")
      asignar(selector.to_s.chomp("=").to_sym, args.first)   # 3º un setter
    else
      super                                # 4º nadie
    end
  end

  def respond_to_missing?(selector, include_private = false)
    !find_method(selector).nil? || has_property?(selector) || selector.end_with?("=") || super
  end
end

atila = Guerrero.new(100, 50, 30)
atila.potencial_ofensivo                   # => 50       ← nadie en la cadena tiene el método; la propiedad responde
Guerrero.prototype.potencial_ofensivo = proc { 1000 }
atila.potencial_ofensivo                   # => 1000     ← ahora el método del prototipo gana
atila.get_property(:potencial_ofensivo)    # => 50       ← la propiedad sigue ahí; solo dejó de responder al mensaje
```

**Lo que cambia hacia atrás.** Todo lo de 4.1 y 4.2 sigue pasando, con una excepción visible, y es una que vale entender:

| Antes (getter como método) | Ahora (propiedad en `method_missing`) |
|---|---|
| `espadachin.set_prototype(guerrero)` y, sin setear nada, `espadachin.respond_to?(:energia)` → `true` (heredaba el getter) y `espadachin.energia` → `nil` | `respond_to?(:energia)` → `false` y `espadachin.energia` → `NoMethodError` (no hay método ni propiedad) |

Las dos cumplen "el prototipo provee métodos y no estado". La nueva es más honesta: un derivado sin la propiedad **no responde** el mensaje, en vez de responder `nil`. El test del Módulo 5 que decía lo contrario se reescribe así en la versión final del spec.

> 🎯 **Para el parcial, si te preguntan** por qué el getter de una propiedad no debe guardarse como un método del objeto:
> Porque un método propio tiene prioridad sobre toda la cadena de prototipos, y el enunciado exige que un método agregado al prototipo después (`proto.potencial_ofensivo = proc { 1000 }`) reemplace la lectura de la propiedad en el derivado. Con el getter como método, el derivado encuentra su getter primero y nunca ve el del prototipo. Resolviendo la propiedad en `method_missing` después de buscar métodos en la cadena, el orden queda como el enunciado lo pide: método de la cadena, después propiedad propia.

---

## 7. 🔴 Paso 5: `extended` con bloque

> 📄 **El enunciado dice** (4.3, último bloque):
> ```ruby
> Espadachin = Guerrero.extended {
>   |una_habilidad, un_potencial_espada|
>   self.habilidad = una_habilidad
>   self.potencial_espada = un_potencial_espada
>
>   self.potencial_ofensivo = proc {
>     @potencial_ofensivo + self.potencial_espada * self.habilidad
>   }
> }
> ```

**En criollo:** el `extended` del Módulo 7, con un bloque en vez de un proc: sin el parámetro del objeto nuevo, con `self`. Y `self.potencial_ofensivo = proc { … }` define el método por el setter de la sección 2. El `@potencial_ofensivo` es la errata de siempre: `get_property(:potencial_ofensivo)` hasta el Módulo 9.

> **Regla.** `extended` acepta proc o bloque, igual que `new`, y se los pasa al constructor nuevo junto con `padre: self`.

```ruby
class PrototypedConstructor
  def extended(inicializador = nil, &bloque)
    PrototypedConstructor.new(prototype, inicializador, padre: self, &bloque)
  end
end

Guerrero = PrototypedConstructor.create {}.with { |una_energia, un_potencial_ofensivo, un_potencial_defensivo|
  self.energia = una_energia
  self.potencial_ofensivo = un_potencial_ofensivo
  self.potencial_defensivo = un_potencial_defensivo
}

Espadachin = Guerrero.extended { |una_habilidad, un_potencial_espada|
  self.habilidad = una_habilidad
  self.potencial_espada = un_potencial_espada
  self.potencial_ofensivo = proc {
    get_property(:potencial_ofensivo) + self.potencial_espada * self.habilidad
  }
}

Espadachin.new(100, 30, 10, 0.5, 30).potencial_ofensivo    # => 45.0
```

Fijate que acá `potencial_ofensivo` **es un método propio** del espadachín (lo definió el setter con un proc) y por eso le gana a la propiedad `potencial_ofensivo` que el padre seteó en 30: es la regla de la sección 6, usada al derecho. Y adentro, `get_property` llega al 30 salteando el método. Que ese salto se escriba `call_next` es el Módulo 9.

---

## 8. 🔴 Las piezas armadas

`Prototyped` con el setter que distingue procs, la propiedad resuelta en `method_missing` y sin getter en `set_property`; `PrototypedObject` con bloque; `PrototypedConstructor` completo.

```ruby
module Prototyped
  SIN_NADA = {}.freeze

  def set_property(nombre, valor)
    propiedades[nombre] = valor
  end

  def get_property(nombre)
    propiedades[nombre]
  end

  def has_property?(nombre)
    propiedades.key?(nombre)
  end

  def property_names
    propiedades.keys
  end

  def set_method(selector, bloque)
    metodos[selector] = bloque
  end

  def set_prototype(prototipo)
    @__prototype__ = prototipo
  end

  def prototype
    @__prototype__
  end

  def find_method(selector)
    if metodos.key?(selector)
      metodos[selector]
    elsif prototype
      prototype.find_method(selector)
    end
  end

  def initialize_copy(original)
    super
    @__properties__ = @__properties__.dup if @__properties__
    @__methods__    = @__methods__.dup    if @__methods__
  end

  private

  def method_missing(selector, *args)
    bloque = find_method(selector)
    if bloque
      instance_exec(*args, &bloque)                                 # 1º un método, en toda la cadena
    elsif has_property?(selector)
      get_property(selector)                                        # 2º una propiedad propia
    elsif selector.end_with?("=")
      asignar(selector.to_s.chomp("=").to_sym, args.first)          # 3º un setter: método o propiedad
    else
      super                                                         # 4º nadie
    end
  end

  def respond_to_missing?(selector, include_private = false)
    !find_method(selector).nil? || has_property?(selector) || selector.end_with?("=") || super
  end

  def asignar(nombre, valor)
    if valor.is_a?(Proc)
      set_method(nombre, valor)
    else
      set_property(nombre, valor)
    end
  end

  def propiedades
    @__properties__ || (frozen? ? SIN_NADA : @__properties__ = {})
  end

  def metodos
    @__methods__ || (frozen? ? SIN_NADA : @__methods__ = {})
  end
end

class PrototypedObject
  include Prototyped

  def initialize(&bloque)
    instance_exec(&bloque) if bloque
  end
end

class PrototypedConstructor
  attr_reader :prototype

  def self.copy(prototipo)
    new(prototipo, proc { |nuevo|
      prototipo.property_names.each do |nombre|
        nuevo.set_property(nombre, prototipo.get_property(nombre))
      end
    })
  end

  def self.create(&bloque)
    new(PrototypedObject.new(&bloque))
  end

  def initialize(prototipo, inicializador = nil, aridad: nil, padre: nil, &bloque)
    @prototype = prototipo
    @padre = padre
    if inicializador
      @aridad = aridad || inicializador.arity - 1
      @cuerpo = inicializador
    elsif bloque
      @aridad = aridad || bloque.arity
      @cuerpo = proc { |nuevo, *args| nuevo.instance_exec(*args, &bloque) }
    else
      @aridad = 1
      @cuerpo = inicializador_por_defecto
    end
  end

  def new(*args)
    nuevo = PrototypedObject.new
    nuevo.set_prototype(prototype)
    sobrantes = inicializar(nuevo, args)
    raise ArgumentError, "sobran argumentos: #{sobrantes.inspect}" unless sobrantes.empty?
    nuevo
  end

  def with(inicializador = nil, &bloque)
    PrototypedConstructor.new(prototype, inicializador, &bloque)
  end

  def with_properties(nombres)
    PrototypedConstructor.new(prototype, proc { |nuevo, *valores|
      nombres.zip(valores).each { |nombre, valor| nuevo.set_property(nombre, valor) }
    }, aridad: nombres.size)
  end

  def extended(inicializador = nil, &bloque)
    PrototypedConstructor.new(prototype, inicializador, padre: self, &bloque)
  end

  protected

  def inicializar(nuevo, args)
    args = @padre.inicializar(nuevo, args) if @padre
    raise ArgumentError, "faltan argumentos: esperaba #{@aridad}, llegaron #{args.size}" if args.size < @aridad
    @cuerpo.call(nuevo, *args.take(@aridad))
    args.drop(@aridad)
  end

  private

  def inicializador_por_defecto
    proc { |nuevo, valores|
      valores.each do |nombre, valor|
        raise ArgumentError, "el prototipo no tiene la propiedad #{nombre}" unless prototype.has_property?(nombre)
        nuevo.set_property(nombre, valor)
      end
    }
  end
end
```

`attr_reader :prototype` reemplaza al `def prototype` del Módulo 7: es lo mismo, en una línea.

### Los tests de esta pieza

```ruby
describe 'azúcar sintáctico (4.3)' do
  it 'asignar un proc define un método; el primer bloque, verbatim' do
    guerrero_proto = PrototypedObject.new
    guerrero_proto.energia = 100
    guerrero_proto.potencial_defensivo = 10
    guerrero_proto.potencial_ofensivo = 30
    guerrero_proto.atacar_a = proc { |otro_guerrero|
      otro_guerrero.recibe_danio(self.potencial_ofensivo - otro_guerrero.potencial_defensivo) if otro_guerrero.potencial_defensivo < self.potencial_ofensivo
    }
    guerrero_proto.recibe_danio = proc { |danio| self.energia = self.energia - danio }
    expect(guerrero_proto.has_property?(:atacar_a)).to be false
    constructor = PrototypedConstructor.copy(guerrero_proto)
    un_guerrero = constructor.new
    constructor.new.atacar_a(un_guerrero)
    expect(un_guerrero.energia).to eq 80
  end
  it 'new con bloque configura el objeto con self' do
    objeto = PrototypedObject.new { self.energia = 100; self.saludar = proc { "hola" } }
    expect(objeto.energia).to eq 100
    expect(objeto.saludar).to eq "hola"
  end
  it 'constructor con bloque' do
    proto = PrototypedObject.new
    constructor = PrototypedConstructor.new(proto) do |una_energia, un_potencial_ofensivo, un_potencial_defensivo|
      self.energia = una_energia
      self.potencial_ofensivo = un_potencial_ofensivo
      self.potencial_defensivo = un_potencial_defensivo
    end
    expect(constructor.new(1, 2, 3).potencial_ofensivo).to eq 2
  end
  it 'create … with y create … with_properties' do
    con_with = PrototypedConstructor.create {
      self.recibe_danio = proc { |danio| self.energia = self.energia - danio }
    }.with { |una_energia, un_potencial_ofensivo, un_potencial_defensivo|
      self.energia = una_energia
      self.potencial_ofensivo = un_potencial_ofensivo
      self.potencial_defensivo = un_potencial_defensivo
    }
    con_lista = PrototypedConstructor.create {
      self.recibe_danio = proc { |danio| self.energia = self.energia - danio }
    }.with_properties([:energia, :potencial_ofensivo, :potencial_defensivo])
    [con_with, con_lista].each do |constructor|
      atila = constructor.new(100, 50, 30)
      expect(atila.potencial_ofensivo).to eq 50
      atila.recibe_danio(10)
      expect(atila.energia).to eq 90
    end
    expect { con_lista.new(100) }.to raise_error(ArgumentError)
  end
  it 'un método agregado al prototipo del constructor le gana a la propiedad del derivado' do
    constructor = PrototypedConstructor.create {}.with_properties([:energia, :potencial_ofensivo, :potencial_defensivo])
    atila = constructor.new(100, 50, 30)
    expect(atila.potencial_ofensivo).to eq 50
    constructor.prototype.potencial_ofensivo = proc { 1000 }
    expect(atila.potencial_ofensivo).to eq 1000
  end
  it 'extended con bloque' do
    guerrero = PrototypedConstructor.create {}.with { |e, o, d| self.energia = e; self.potencial_ofensivo = o; self.potencial_defensivo = d }
    espadachin = guerrero.extended { |una_habilidad, un_potencial_espada|
      self.habilidad = una_habilidad
      self.potencial_espada = un_potencial_espada
      self.potencial_ofensivo = proc { get_property(:potencial_ofensivo) + self.potencial_espada * self.habilidad }
    }
    expect(espadachin.new(100, 30, 10, 0.5, 30).potencial_ofensivo).to eq 45
  end
  it 'un derivado sin la propiedad no responde el mensaje (cambio respecto del Módulo 5)' do
    guerrero = armar_guerrero
    espadachin = PrototypedObject.new
    espadachin.set_prototype(guerrero)
    expect(espadachin.has_property?(:energia)).to be false
    expect(espadachin.respond_to?(:energia)).to be false
    expect { espadachin.energia }.to raise_error(NoMethodError)
  end
end
```

---

## Checkpoint del Módulo 8

1. `objeto.atacar_a = proc { … }` y `objeto.energia = 100` entran por el mismo setter. ¿Cómo se decide qué hacer con cada uno, y qué queda imposible de guardar como propiedad?
2. ¿Qué diferencia hay entre `is_a?(Proc)` y `respond_to?(:call)` como criterio? ¿Qué pasa con un lambda en cada caso?
3. ¿Cómo hace `PrototypedObject.new { … }` para que `self` adentro del bloque sea el objeto nuevo? ¿Qué método lo recibe y con qué sintaxis?
4. Un constructor puede recibir proc, bloque o nada. ¿Qué forma común tienen los tres por dentro, y para qué sirve unificarlos?
5. ¿Por qué `with_properties` necesita decir la aridad a mano?
6. ¿Qué devuelve `PrototypedConstructor.create { … }` y por qué `.with { … }` se puede encadenar después?
7. ¿Por qué `with` crea un constructor nuevo en vez de modificar el que recibe?
8. `Guerrero.prototype.potencial_ofensivo = proc { 1000 }` y `atila.potencial_ofensivo` seguía dando 50. Explicá dónde encontraba `find_method` el método que ganaba, y qué se cambió para que gane el del prototipo.
9. Escribí el orden de las cuatro ramas de `method_missing` final y dá un ejemplo que caiga en cada una.
10. ¿Qué test del Módulo 5 cambia con la corrección, y por qué las dos conductas cumplen "el prototipo provee métodos y no estado"?

## Qué viene en el Módulo 9

La parte 4.4 y el ejemplo que la cátedra usó como muestra de individual. `call_next`: el `super` de los prototipos, que reemplaza al `@potencial_ofensivo` del enunciado y al `get_property` que venimos usando, y que para funcionar necesita saber **quién está ejecutando qué** (una pila). Y `set_prototypes([a, b])`: más de un prototipo por objeto, en orden, sin que los prototipos se encadenen entre sí, con la pregunta que define el individual: ¿dónde, en todo tu código, se usa `prototype`?

**FIN DEL MÓDULO 8**
