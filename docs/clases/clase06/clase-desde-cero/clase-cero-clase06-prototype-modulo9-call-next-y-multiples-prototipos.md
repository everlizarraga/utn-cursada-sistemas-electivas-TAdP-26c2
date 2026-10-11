# Clase desde cero — Prototype — Módulo 9: `call_next` y múltiples prototipos

**Unidad:** clase06 · **Módulo:** 9 de 9 (+1 opcional) · **Densidad:** 🔴 · **Parte del enunciado:** 4.4, y el ejemplo que la cátedra usa como muestra de individual

## Sobre este documento

**Qué cubre:** las dos piezas de 4.4. `call_next`: el `super` de los prototipos, que para funcionar necesita saber **qué método está corriendo y de quién es** (una pila). `set_prototypes([a, b])`: más de un prototipo por objeto, lo que obliga a convertir la cadena en una **linealización** explícita, decidir conflictos, y protegerse de ciclos. Cierra con el ejercicio que la cátedra dio como muestra de individual (pasar de un prototipo a varios) y la pregunta que lo define: ¿dónde, en todo el código, se usa `prototype`? Al final del módulo, el enunciado anda **completo**, y el archivo `clase06-prototype.rb` con su spec son el resultado.

**Qué NO cubre:** la alternativa con módulos (Módulo 10, opcional).

**Tené el enunciado a mano**, en la parte 4.4 entera.

## De dónde venís

Del Módulo 5: `find_method` busca en el objeto y después en su prototipo; `method_missing` ejecuta el proc con `instance_exec`; el `@potencial_ofensivo` del enunciado se escribe `get_property(:potencial_ofensivo)` hasta que exista algo mejor.
Del Módulo 8: `method_missing` resuelve método de la cadena → propiedad propia → setter → `super`; `extended { … }` con bloque.
De clase02: cuando hay varios módulos, Ruby arma una **lista ordenada** (la linealización) y busca en orden; el orden decide los conflictos; `super` sigue por esa lista desde el punto donde está.
De clase04: `ensure` corre siempre, haya excepción o no.

---

## 1. 🔴 Qué pide `call_next`

> 📄 **El enunciado dice** (4.4 *Llamar al prototipo anterior y Múltiples prototipos*, primer párrafo):
> *"Anteriormente, cuando definimos Espadachin nos encontramos con el inconveniente de que queríamos utilizar la implementación previa de potencial_ofensivo (que venía de guerrero), pero no teníamos forma de acceder a ella, porque estábamos pisando ese método. Nos interesa entonces definir un mecanismo para poder llamar a la implementación siguiente de la cadena de prototipos:"*
> ```ruby
> Espadachin = Guerrero.extended {
>   |una_habilidad, un_potencial_espada|
>   self.habilidad = una_habilidad
>   self.potencial_espada = un_potencial_espada
>
>   self.potencial_ofensivo = proc {
>     call_next + self.potencial_espada * self.habilidad
>   }
> }
> ```

**En criollo:** `call_next`, escrito **adentro de un método prototipado**, ejecuta "la implementación siguiente" de ese mismo selector: la que hubiera corrido si este objeto no lo hubiera redefinido. Es `super`, pero para la cadena de prototipos en vez de la cadena de clases. Reemplaza al `@potencial_ofensivo` del enunciado y al `get_property` que venimos escribiendo.

```ruby
espadachin.potencial_ofensivo = proc { call_next + self.potencial_espada * self.habilidad }
espadachin.potencial_ofensivo
# => NoMethodError: undefined method `call_next' for an instance of PrototypedObject     (hoy)
```

---

## 2. 🔴 Paso 0: lo que `call_next` necesita saber

> **Regla.** Para ejecutar "la siguiente", `call_next` necesita tres datos que no están en ningún lado: **qué selector** se está ejecutando, **de quién** es la implementación que está corriendo, y **con qué argumentos** llegó. `self` no alcanza: `self` es el receptor, y el método que corre puede ser de un prototipo dos saltos más arriba.

Compará con `super` en Ruby. Cuando escribís `super` adentro de un método, Ruby sabe en qué clase está definido ese método y qué argumentos recibió, porque **él mismo** lo está ejecutando. Nuestros métodos los ejecuta `instance_exec` desde `method_missing`, y en ese momento `method_missing` sí sabe las tres cosas: el selector (lo recibió), el dueño (lo encontró `find_method`) y los argumentos. Lo que falta es **guardarlas** mientras el proc corre, para que `call_next` las lea.

Y hay un detalle que decide la estructura: un método puede llamar a otro (que a su vez puede usar `call_next`), y cuando el interno termina, el externo sigue. Hace falta algo que apile y desapile: una **pila**, una lista donde el último que entró es el primero que sale.

```
   espadachin.potencial_ofensivo
     │ method_missing: dueño = espadachin, selector = :potencial_ofensivo, args = []
     │ pila: [ {potencial_ofensivo, espadachin, []} ]
     ├─► self.potencial_espada  → otro method_missing: apila {potencial_espada, …}, corre, desapila
     ├─► call_next              → mira el TOPE de la pila: {potencial_ofensivo, espadachin, []}
     │                             → busca potencial_ofensivo DESPUÉS de espadachin en la cadena
     └─ termina → desapila
```

---

## 3. 🔴 Paso 1: la pila y `call_next`

> **Regla.** Antes de ejecutar un proc, `method_missing` apila un **marco** con el selector, el dueño y los argumentos; al terminar lo desapila, pase lo que pase. `call_next` lee el marco del tope, busca el selector en la cadena **a partir del objeto siguiente al dueño**, y resuelve igual que `method_missing`: un método, o la propiedad propia, o error.

Primero, separar en `method_missing` la búsqueda de la ejecución, para poder reusarlas:

```ruby
module Prototyped
  private

  def pila
    @__stack__ ||= []                        # la pila de marcos de este objeto
  end

  def resolver(selector, candidatos, args)   # busca entre los candidatos; si nadie, la propiedad; si no, el bloque decide
    duenio = candidatos.find { |objeto| objeto.defines_method?(selector) }
    if duenio
      ejecutar(selector, duenio, args)
    elsif has_property?(selector)
      get_property(selector)
    else
      yield                                  # yield: ejecuta el bloque que recibió resolver (acá: super, o raise)
    end
  end

  def ejecutar(selector, duenio, args)
    pila.push({ selector: selector, duenio: duenio, args: args })   # 1. apilar el marco
    instance_exec(*args, &duenio.own_method(selector))               # 2. correr el proc con self = receptor
  ensure
    pila.pop                                                         # 3. desapilar SIEMPRE, aunque el proc explote
  end

  def method_missing(selector, *args)
    if selector.end_with?("=") && prototype_chain.none? { |objeto| objeto.defines_method?(selector) }
      asignar(selector.to_s.chomp("=").to_sym, args.first)
    else
      resolver(selector, prototype_chain, args) { super }             # nadie: el NoMethodError de siempre
    end
  end
end
```

Dos mensajes nuevos sobre los objetos, para que `resolver` pueda preguntar sin tocar diccionarios ajenos: `defines_method?(selector)` (¿**vos** definís este selector?) y `own_method(selector)` (dame **tu** proc). `prototype_chain` es la lista ordenada de objetos donde buscar; hoy es `[self, prototype, el prototipo de ese, …]` y en la sección 5 cambia.

`ensure` corre siempre al salir de `ejecutar`, haya terminado bien o con una excepción: si un proc explota a mitad, la pila no queda con un marco de más. `yield` ejecuta el bloque que el método recibió sin nombrarlo; `# también:` recibirlo como `&si_nadie` y hacer `si_nadie.call`.

Y ahora `call_next`, un método **público** del mixin, porque se lo manda el proc con `self` igual al receptor:

```ruby
module Prototyped
  def call_next(*args)
    marco = pila.last                                     # el método que está corriendo ahora
    raise NoMethodError, "call_next fuera de un método prototipado" unless marco
    args = marco[:args] if args.empty?                    # sin argumentos: los mismos que recibió el método actual
    cadena = prototype_chain
    siguientes = cadena.drop(cadena.index { |objeto| objeto.equal?(marco[:duenio]) } + 1)   # todo lo que viene DESPUÉS del dueño
    resolver(marco[:selector], siguientes, args) do
      raise NoMethodError, "#{marco[:selector]} no tiene implementación siguiente"
    end
  end
end
```

`index { … }` devuelve la posición del primer elemento que cumple el bloque (`[3, 5, 7].index { |n| n > 4 }` → `1`). `equal?` compara **identidad** (¿es el mismo objeto?), a diferencia de `==` que compara igualdad (`"a".equal?("a")` → `false`; `"a" == "a"` → `true`); acá importa el mismo objeto, no uno parecido.

```ruby
guerrero = armar_guerrero                                           # potencial_ofensivo = 30, como propiedad
espadachin = PrototypedObject.new
espadachin.set_prototype(guerrero)
espadachin.potencial_ofensivo = 30
espadachin.habilidad = 0.5
espadachin.potencial_espada = 30
espadachin.potencial_ofensivo = proc { call_next + self.potencial_espada * self.habilidad }   # el del enunciado, tal cual

espadachin.potencial_ofensivo          # => 45.0
#   call_next buscó potencial_ofensivo después de espadachin: guerrero no tiene MÉTODO con ese nombre
#   → resolver cae en "la propiedad propia" → get_property(:potencial_ofensivo) del espadachín → 30

espadachin.instance_variable_get(:@__stack__)   # => []     ← la pila quedó vacía
```

```
# ¿CÓMO FUNCIONA?  espadachin.potencial_ofensivo
# 1. method_missing(:potencial_ofensivo) → resolver sobre [espadachin, guerrero] → espadachin lo define
# 2. ejecutar: pila = [{:potencial_ofensivo, espadachin, []}]; instance_exec del proc con self = espadachin
# 3. adentro: call_next → marco = tope; args = []; cadena = [espadachin, guerrero]
#    siguientes = cadena.drop(0 + 1) = [guerrero]
#    resolver(:potencial_ofensivo, [guerrero], []) → guerrero no lo define como método
#    → has_property?(:potencial_ofensivo) en espadachin → sí → 30
# 4. 30 + 30 × 0.5 = 45.0; ensure → pila = []
```

**Por qué `call_next` termina en la propiedad.** Es exactamente lo que el `@potencial_ofensivo` del enunciado quería: "el valor que este método está tapando". La cadena de implementaciones de un selector termina, si nadie más tiene un método, en la propiedad del propio objeto. Así una sola palabra cubre los dos casos: un método más arriba, o el dato de abajo.

### `call_next` hacia un método, con y sin argumentos

```ruby
base = PrototypedObject.new { self.saludar = proc { |nombre| "hola #{nombre}" } }
hijo = PrototypedObject.new
hijo.set_prototype(base)

hijo.saludar = proc { |nombre| call_next + "!" }       # sin argumentos: reenvía los que recibió
hijo.saludar("ever")                                   # => "hola ever!"

hijo.saludar = proc { |nombre| call_next("otro") }     # con argumentos: los nuevos
hijo.saludar("ever")                                   # => "hola otro"

solo = PrototypedObject.new { self.x = proc { call_next } }
solo.x                        # => NoMethodError: x no tiene implementación siguiente
PrototypedObject.new.call_next   # => NoMethodError: call_next fuera de un método prototipado
```

Es la misma convención que `super` sin paréntesis contra `super(a, b)` en Ruby. Y se encadena: si `c → b → a` y cada uno hace `call_next`, se recorre entero (`"abc"` en el test).

⚠️ **Trampa: `g + call_next` sin receptor.** Adentro de un proc, `g + call_next` se lee como `g(+call_next)`: Ruby toma el `+` como signo del argumento de `g`. Con `self.g + call_next` o `g() + call_next` se lee bien. Es una ambigüedad de Ruby con cualquier método sin argumentos, no de este framework.

### `call_next` contra `get_property`: una diferencia que importa

Las dos dan 45 en el ejemplo. Difieren cuando el prototipo **cambia después**:

```ruby
guerrero.set_method(:potencial_ofensivo, proc { 1000 })      # guerrero gana un MÉTODO con ese nombre

# espadachín escrito con get_property(:potencial_ofensivo):  → 45.0    lee SU propiedad, siempre
# espadachín escrito con call_next:                           → 1015.0  la "siguiente" ahora es el método de guerrero
```

Ninguna está mal: son dos semánticas. `get_property` es "mi dato"; `call_next` es "lo que corresponda en la cadena, en este momento", igual que `super`. El enunciado, en 4.1, espera 45 después del cambio a 1000, y escribe `@potencial_ofensivo`: ahí pide el dato. En 4.4 pide `call_next`, y no vuelve a probar ese caso. En el spec quedan los dos, cada uno con su test.

> 🎯 **Para el parcial, si te preguntan** qué necesita `call_next` para funcionar y por qué `super` no lo necesita:
> `call_next` necesita saber el selector en ejecución, el objeto dueño de la implementación que corre y los argumentos recibidos, y buscar el selector en la cadena a partir del objeto siguiente al dueño. Ruby conoce esos datos para `super` porque él ejecuta el método y sabe en qué clase está definido; nuestros métodos los ejecuta `instance_exec` desde `method_missing`, así que hay que guardarlos en una pila antes de ejecutar y sacarlos al terminar.

---

## 4. 🔴 Qué piden los múltiples prototipos

> 📄 **El enunciado dice** (4.4, segundo párrafo):
> *"Finalmente, nos interesa incorporar una idea similar a lo que hacemos con Mixins o con herencia múltiple y permitir múltiples prototipos en un mismo objeto:"*
> ```ruby
> Guerrero.prototype.set_prototypes([proto_atacante, proto_defensor])
> ```
> *"Cabe aclarar que proto_atacante y proto_defensor no deben verse afectados en su cadena de prototipado: No es válido que proto_defensor pase a ser prototipo de proto_atacante ni vice versa."*
> *"Queda a criterio del grupo cómo se efectúa la resolución de conflictos en caso que existieran y cómo funciona el call_next al tener múltiples prototipos."*

**En criollo, con dos decisiones que el enunciado deja a criterio:**

- `set_prototypes([a, b])`: un objeto con **una lista** de prototipos. Un método se busca en el objeto, y si no está, en `a` y su cadena, y si no, en `b` y la suya. Es lo que un mixin hace por una clase, aplicado a objetos.
- "No deben verse afectados": `a` y `b` siguen con sus propias cadenas; linkear a los dos **no** convierte a `b` en prototipo de `a`. Es la trampa fácil: implementar `set_prototypes([a, b])` como `a.set_prototype(b); set_prototype(a)` cumple el test de arriba y rompe este.
- **Conflicto** (los dos definen `grito`): se decide que **gana el primero de la lista**. Es la lectura directa de "buscar en orden".
- **`call_next` con varios**: sigue por la misma lista linealizada. Desde el método de `a`, "la siguiente" es la de `b`.

---

## 5. 🔴 Paso 2: la linealización

> **Regla.** La cadena de un objeto es una **lista ordenada sin repetidos**: el objeto, después la cadena completa de su primer prototipo, después la del segundo, y así. Un objeto que ya está en la lista no se vuelve a agregar: eso resuelve los prototipos compartidos y corta los ciclos.

Hasta acá la cadena era implícita: `find_method` preguntaba a `prototype`, que preguntaba al suyo. Con una lista de prototipos hay que armarla explícitamente, y conviene que sea **un método que devuelva la lista**, porque la usan `find_method`, `call_next` y `method_missing`:

```ruby
module Prototyped
  def set_prototype(prototipo)
    set_prototypes([prototipo])              # un prototipo es una lista de uno
  end

  def set_prototypes(prototipos)
    @__prototypes__ = prototipos.dup         # copia: si el usuario modifica su lista después, no nos afecta
  end

  def prototypes
    @__prototypes__ || []
  end

  def prototype                              # el singular sigue existiendo: el primero
    prototypes.first
  end

  def prototype_chain(cadena = [])                                   # recibe la lista que se está armando
    return cadena if cadena.any? { |objeto| objeto.equal?(self) }    # ya estoy: no me agrego de nuevo (ciclos, diamantes)
    cadena << self                                                   # yo primero
    prototypes.each { |prototipo| prototipo.prototype_chain(cadena) } # y cada prototipo agrega su cadena, en orden
    cadena
  end

  def find_method(selector)
    duenio = prototype_chain.find { |objeto| objeto.defines_method?(selector) }
    duenio && duenio.own_method(selector)
  end
end
```

`prototype_chain` es **recursiva**: cada prototipo agrega su parte a la misma lista, que va pasando como argumento. El parámetro con valor por defecto (`cadena = []`) hace que desde afuera se llame sin argumentos y por dentro se pase la lista en construcción.

```ruby
atacante = PrototypedObject.new {
  self.atacar_a = proc { |otro| otro.recibe_danio(potencial_ofensivo) }
  self.grito = proc { "ataco" }
}
defensor = PrototypedObject.new {
  self.recibe_danio = proc { |danio| self.energia = energia - danio }
  self.grito = proc { "defiendo" }
}

Guerrero = PrototypedConstructor.create {}.with_properties([:energia, :potencial_ofensivo])
Guerrero.prototype.set_prototypes([atacante, defensor])              # la línea del enunciado

a = Guerrero.new(100, 30)
b = Guerrero.new(100, 30)
a.prototype_chain.size        # => 4       ← a, el prototipo de Guerrero, atacante, defensor
a.atacar_a(b)                 # atacar_a viene de atacante; recibe_danio, de defensor
b.energia                     # => 70

atacante.prototypes           # => []      ← no se afectaron entre sí
defensor.prototypes           # => []
atacante.respond_to?(:recibe_danio)   # => false
```

### Conflictos y `call_next` por la lista

```ruby
a.grito                       # => "ataco"                 ← los dos lo definen; gana el primero de la lista

Guerrero.prototype.grito = proc { call_next + " y " + call_next }
a.grito                       # => "ataco y ataco"         ← desde el prototipo de Guerrero, la siguiente es atacante

atacante.grito = proc { call_next.upcase }
a.grito                       # => "DEFIENDO y DEFIENDO"   ← desde atacante, la siguiente es defensor
```

Fijate la última línea: `atacante` **no tiene** a `defensor` como prototipo, y sin embargo su `call_next` llega a `defensor`. Es correcto, y es exactamente lo que pasa con `super` en un mixin: el "siguiente" no depende de quién definió el método, sino de **la linealización del receptor**. Para `a`, después de `atacante` viene `defensor`. Si `atacante` se usara solo, su `call_next` fallaría.

### Ciclos y diamantes

```ruby
x = PrototypedObject.new
y = PrototypedObject.new
x.set_prototype(y)
y.set_prototype(x)
x.nada                        # => NoMethodError: undefined method `nada' for an instance of PrototypedObject
x.respond_to?(:nada)          # => false      ← ya no cuelga (Módulo 5): la cadena corta al repetirse

raiz = PrototypedObject.new { self.f = proc { "raíz" } }
p1 = PrototypedObject.new; p1.set_prototype(raiz)
p2 = PrototypedObject.new; p2.set_prototype(raiz)
hijo = PrototypedObject.new; hijo.set_prototypes([p1, p2])
hijo.prototype_chain.size     # => 4           ← raiz una sola vez, aunque llega por dos caminos
hijo.f                        # => "raíz"
```

> 💎 **Otra forma de hacerlo.** Que gane el **último** de la lista, como el `include` de Ruby (el último incluido queda más cerca). Es igual de válido; cambia `prototypes.each` por `prototypes.reverse_each`. También se podría linealizar como Ruby lo hace con los módulos (cada prototipo una sola vez, respetando el orden de todos los caminos); para lo que el enunciado pide, la recorrida en profundidad con "no repetir" alcanza.

> 💎 **Otra forma de hacerlo.** Rechazar el ciclo al linkear (`set_prototypes` que explote si el nuevo prototipo ya tiene al receptor en su cadena), en vez de tolerarlo en la búsqueda. Falla antes y más claro; cuesta una recorrida en cada `set_prototypes`.

---

## 6. 🔴 El individual: ¿dónde se usa `prototype`?

> **Regla.** El individual no pide desarrollar otra rama del sistema: pide **un cambio acotado sobre tu propio TP**, y evalúa si sabés dónde impacta. "Pasar de un prototipo a varios" es el ejemplo que la cátedra dio. La respuesta correcta no es el código: es saber que **toda la lógica de prototipos pasa por un solo lugar**.

Mirá el cambio de la sección 5 con esa pregunta en la cabeza. De un prototipo a una lista, ¿qué se tocó?

| Pieza | ¿Cambió? | Por qué |
|---|---|---|
| `set_property`, `get_property`, `has_property?`, `set_method` | No | No saben nada de prototipos |
| `set_prototype` | Sí, una línea | Delega en `set_prototypes` con una lista de uno |
| `prototypes` / `prototype` | Nuevo / una línea | Antes había una referencia; ahora una lista y "el primero" |
| `prototype_chain` | Nuevo | Antes la cadena era implícita en la recursión de `find_method` |
| `find_method` | Sí | Ya no pregunta a `prototype`: recorre `prototype_chain` |
| `method_missing`, `respond_to_missing?`, `call_next` | No | Usan `find_method` y `prototype_chain`; no nombran a `prototype` |
| `initialize_copy` | Dos líneas | Copiar la lista en vez de la referencia; un clon arranca con la pila vacía |
| `PrototypedConstructor` | No | Usa `set_prototype`, que sigue existiendo |

Si tu `find_method` hubiera estado escrito adentro de `method_missing`, y `respond_to_missing?` hubiera repetido la búsqueda por su cuenta, el cambio tocaba tres lugares y era fácil olvidar uno. Si la búsqueda está en **un** método, el cambio es ese método. Eso es lo que "capacidad de moverse en código propio" quiere decir: que cuando aparece el requerimiento, puedas contestar en diez segundos "¿dónde uso `prototype`?", y que la respuesta sea un solo lugar.

La otra mitad de la evaluación es entender **qué** hacés en ese lugar. "Tengo una lista, la recorro en orden, el primero que tenga el método gana" es una respuesta; "le paso la lista y ya está" no lo es.

> 🎯 **Para el parcial, si te preguntan** cómo pasarías tu implementación de un prototipo a varios:
> Reemplazando la referencia por una lista en `set_prototypes`, y haciendo que la búsqueda recorra una linealización explícita (el objeto, después cada prototipo con su cadena, en orden, sin repetir) en lugar de preguntarle al único prototipo. Si la búsqueda está concentrada en un método (`find_method` sobre `prototype_chain`), `method_missing`, `respond_to_missing?` y `call_next` no cambian. Las decisiones nuevas son el criterio de conflicto (gana el primero de la lista) y que los prototipos no se linkeen entre sí.

---

## 7. 🔴 Las piezas armadas

El framework completo está en `clase06-prototype.rb`, con todos los tests en `clase06-prototype_spec.rb` (50 casos: cada módulo, los `expect` del enunciado verbatim donde era posible, y los casos propios). Acá, solo lo que este módulo agregó o cambió en `Prototyped`:

```ruby
module Prototyped
  # … propiedades y métodos, sin cambios (M2–M8), más:

  def defines_method?(selector)
    metodos.key?(selector)
  end

  def own_method(selector)
    metodos[selector]
  end

  def set_prototype(prototipo)
    set_prototypes([prototipo])
  end

  def set_prototypes(prototipos)
    @__prototypes__ = prototipos.dup
  end

  def prototypes
    @__prototypes__ || []
  end

  def prototype
    prototypes.first
  end

  def prototype_chain(cadena = [])
    return cadena if cadena.any? { |objeto| objeto.equal?(self) }
    cadena << self
    prototypes.each { |prototipo| prototipo.prototype_chain(cadena) }
    cadena
  end

  def find_method(selector)
    duenio = prototype_chain.find { |objeto| objeto.defines_method?(selector) }
    duenio && duenio.own_method(selector)
  end

  def call_next(*args)
    marco = pila.last
    raise NoMethodError, "call_next fuera de un método prototipado" unless marco
    args = marco[:args] if args.empty?
    cadena = prototype_chain
    siguientes = cadena.drop(cadena.index { |objeto| objeto.equal?(marco[:duenio]) } + 1)
    resolver(marco[:selector], siguientes, args) do
      raise NoMethodError, "#{marco[:selector]} no tiene implementación siguiente"
    end
  end

  def initialize_copy(original)
    super
    @__properties__ = @__properties__.dup if @__properties__
    @__methods__    = @__methods__.dup    if @__methods__
    @__prototypes__ = @__prototypes__.dup if @__prototypes__
    @__stack__      = nil                                    # un clon arranca sin nada en ejecución
  end

  private

  def method_missing(selector, *args)
    if selector.end_with?("=") && prototype_chain.none? { |objeto| objeto.defines_method?(selector) }
      asignar(selector.to_s.chomp("=").to_sym, args.first)
    else
      resolver(selector, prototype_chain, args) { super }
    end
  end

  def resolver(selector, candidatos, args)
    duenio = candidatos.find { |objeto| objeto.defines_method?(selector) }
    if duenio
      ejecutar(selector, duenio, args)
    elsif has_property?(selector)
      get_property(selector)
    else
      yield
    end
  end

  def ejecutar(selector, duenio, args)
    pila.push({ selector: selector, duenio: duenio, args: args })
    instance_exec(*args, &duenio.own_method(selector))
  ensure
    pila.pop
  end

  def pila
    @__stack__ ||= []
  end
end
```

Los tests de este módulo son los dos últimos `describe` del spec: `call_next (M9)` y `múltiples prototipos (M9)`.

---

## Checkpoint del Módulo 9

1. ¿Qué tres datos necesita `call_next` y por qué `self` no alcanza para ninguno de los tres?
2. ¿Por qué hace falta una pila y no una sola variable "método actual"? Dá un ejemplo con dos métodos anidados.
3. ¿Qué hace `ensure` en `ejecutar`, y qué quedaría mal sin él si un proc lanza una excepción?
4. Seguí `espadachin.potencial_ofensivo` con `call_next` paso por paso hasta el 45. ¿En qué rama de `resolver` termina `call_next` y por qué?
5. `call_next` sin argumentos y `call_next("otro")`: ¿qué recibe la implementación siguiente en cada caso? ¿A qué convención de Ruby se parece?
6. `get_property(:potencial_ofensivo)` y `call_next` dan lo mismo hoy. Mostrá una secuencia en la que den distinto y decí cuál corresponde a 4.1 y cuál a 4.4.
7. Escribí `prototype_chain` de memoria y explicá qué hace la primera línea con un ciclo y con un diamante.
8. `atacante` no tiene prototipos, y aun así su `call_next` llega a `defensor`. ¿Por qué es correcto? ¿Qué pasaría si `atacante.grito` se llamara sobre `atacante` directamente?
9. Implementar `set_prototypes([a, b])` como `a.set_prototype(b)` y `set_prototype(a)` pasa el primer test. ¿Cuál rompe, y qué frase del enunciado lo prohíbe?
10. Listá las piezas del framework que **no** cambiaron al pasar de un prototipo a varios, y decí qué tienen en común.

## Qué viene en el Módulo 10 (opcional)

La arquitectura que este framework **no** eligió: un módulo de Ruby por cada objeto, incluido en su autoclase, donde `set_prototype` es `include` y el lookup lo hace Ruby. Vas a ver qué se gana (`to_s` se puede pisar, `respond_to?` y `method` andan solos, `call_next` es `super`), qué se pierde (el clon ve métodos nuevos, los ciclos explotan de otra forma, los objetos congelados no entran), y por qué `bind` entre autoclases era el callejón que empujaba hacia los procs. Si vas justo de tiempo, salteálo: el enunciado ya está resuelto.

**FIN DEL MÓDULO 9**
