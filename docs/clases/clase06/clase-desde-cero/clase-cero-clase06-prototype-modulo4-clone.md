# Clase desde cero — Prototype — Módulo 4: `clone`

**Unidad:** clase06 · **Módulo:** 4 de 9 (+1 opcional) · **Densidad:** 🔴 · **Parte del enunciado:** 4.1, cierre del primer bloque (`guerrero.clone`)

## Sobre este documento

**Qué cubre:** `otro_guerrero = guerrero.clone` con el `clone` que Ruby ya trae. Qué copia y qué no; el bug de dos objetos que comparten el mismo diccionario (Atila y Jack); copia superficial contra copia profunda; cómo se le enseña a `clone` a copiar lo nuestro con `initialize_copy`; y el primer requerimiento **negativo** del enunciado: el clon no se entera de lo que el original aprende después. Al final del módulo, el primer bloque de 4.1 anda **completo**, verbatim.

**Qué NO cubre:** `set_prototype` (Módulo 5). `clone` y `set_prototype` son dos cosas distintas, y este módulo se ocupa de que la diferencia quede clara desde el lado de `clone`.

**Tené el enunciado a mano**, en la parte 4.1, de `otro_guerrero = guerrero.clone` hasta `expect(otro_guerrero.energia).to eq(80)`, y más abajo el párrafo "Distinto sucede con la clonación".

## De dónde venís

Del Módulo 2: las propiedades viven en `@__properties__`, un diccionario propio de cada objeto, con getters en la autoclase.
Del Módulo 3: los métodos viven en la autoclase, por `define_singleton_method`; `armar_guerrero` arma un guerrero completo.
De clase03: cada objeto tiene su autoclase; `singleton_methods` lista lo que hay en ella; `equal?` pregunta si dos variables apuntan al **mismo** objeto (identidad), a diferencia de `==` (igualdad).

---

## 1. 🔴 Qué pide `clone`

> 📄 **El enunciado dice** (4.1, cierre del primer bloque):
> ```ruby
> otro_guerrero = guerrero.clone #clone es un metodo que ya viene definido en Ruby
>
> guerrero.atacar_a otro_guerrero
>
> expect(otro_guerrero.energia).to eq(80)
> ```

**En criollo:** no hay que inventar un `clone`: hay que usar el de Ruby y ver si con nuestros objetos hace lo que esperamos. El clon tiene que tener las mismas propiedades (energía 100) y los mismos métodos (`recibe_danio`, para que el ataque le pegue), y después del ataque **el clon** queda en 80.

Y unas líneas más abajo, el enunciado dice qué **no** tiene que pasar:

> 📄 **El enunciado dice** (4.1, después de `sanar`):
> *"Distinto sucede con la clonación: Los cambios no se impactan en el objeto que es clon:"*
> ```ruby
> expect {otro_guerrero.sanar}.to raise_error(NoMethodError)
> ```
> *"Además, con la clonación se copia el estado del objeto, cosa que no debe suceder con los prototipos."*

**En criollo:** el clon es una **foto** del original en el momento de clonar. Se lleva el estado y el comportamiento de ese instante, y de ahí en más son dos objetos independientes: si el original aprende `sanar` después, el clon no lo entiende. Es lo opuesto de lo que va a hacer un prototipo (Módulo 5), y el enunciado los pone uno al lado del otro a propósito.

---

## 2. 🔴 Paso 0: qué hace el `clone` de Ruby con nuestro objeto

> **Regla.** `clone` crea un objeto nuevo de la misma clase, con **las mismas variables de instancia** (los mismos valores, no copias) y **una copia de la autoclase** del original. Es una copia **superficial**: la capa de afuera es nueva; todo lo que esa capa apunta es compartido.

```ruby
atila = armar_guerrero          # el de Módulo 3: energia 100, defensa 10, ataque 30, atacar_a, recibe_danio
jack  = atila.clone

jack.equal?(atila)              # => false      ← es OTRO objeto
jack.class                      # => PrototypedObject
jack.singleton_methods.sort     # => [:atacar_a, :energia, :potencial_defensivo, :potencial_ofensivo, :recibe_danio]
#                                  ← la autoclase se copió: jack tiene los mismos métodos y getters
jack.energia                    # => 100        ← y la energía está
```

Hasta acá parece que ya está. El ataque:

```ruby
atila.atacar_a(jack)
jack.energia                    # => 80      ✓ lo que pide el enunciado
atila.energia                   # => 80      ✗ ¡Atila también bajó!
```

El test del enunciado pasa, y el framework está roto. Esta es la razón por la que el enunciado dice "no debe probarse sólo eso": el `expect` mira a `otro_guerrero` y no mira a `guerrero`.

### Qué pasó

```ruby
jack.instance_variable_get(:@__properties__).equal?(atila.instance_variable_get(:@__properties__))
# => true      ← el MISMO diccionario. No una copia: el mismo objeto Hash.
```

`clone` copió la variable `@__properties__`, y esa variable contiene una **referencia** a un Hash. Copiar la referencia no copia el Hash. Atila y Jack tienen dos variables que apuntan al mismo diccionario:

```
   ANTES de arreglarlo                       LO QUE QUEREMOS

   atila ──@__properties__──┐                atila ──@__properties__──► { energia: 100, … }
                            ├──► { energia: 100, … }
   jack  ──@__properties__──┘                jack  ──@__properties__──► { energia: 100, … }   (otro Hash)
```

Cuando `jack.recibe_danio(20)` hace `set_property(:energia, 80)`, escribe en el diccionario compartido. Atila lee ese mismo diccionario. Conceptualmente, Jack "pisó su propia energía"; a nivel de implementación, pisó la de los dos.

**Esto es un problema porque elegimos que lo sea.** Hay tecnologías de prototipos donde un objeto queda tan atado a su origen que comparte estado con él. Pero no es lo que queremos para una copia: si clonás a Juan tres veces para tener tres alumnos, tienen que poder tener nombres distintos. La copia básica de cualquier lenguaje de prototipos da **objetos independientes**.

---

## 3. 🔴 Paso 1: copia superficial y copia profunda

> **Regla.** Una **copia superficial** (*shallow copy*) copia solo el objeto de afuera; lo que ese objeto referencia sigue siendo compartido. Una **copia profunda** (*deep copy*) copia también lo referenciado, hasta la profundidad que uno decida. Siempre que haya un `copy`, hay que preguntarse cuál de las dos es.

Es el mismo fenómeno con un Hash pelado:

```ruby
h = {a: "hola"}
c = h.dup                 # dup: copia superficial de un Hash
c[:a] = "chau"            # cambiar una CLAVE del copiado…
h[:a]                     # => "hola"     ← no afecta al original: las claves son de cada Hash

h = {a: "hola"}
c = h.dup
c[:a] << "!"              # …pero MODIFICAR el objeto que la clave apunta…
h[:a]                     # => "hola!"    ← sí afecta: el String es el mismo en los dos
```

La copia profunda no se puede hacer "recursiva por defecto, de todo". Hay objetos que **no tiene sentido duplicar**: los números y los símbolos son siempre el mismo; las clases también; los strings suelen compartirse sin problema. Qué copiar y qué no es una decisión **del dominio**. Por eso vas a ver que muchos objetos redefinen su copia: Ruby da la superficial, y cada clase agrega la profundidad que necesita.

Para nosotros la decisión es clara: **el diccionario de propiedades no se comparte**; cada objeto prototipado tiene el suyo. Los valores adentro del diccionario (100, 10, 30) sí se comparten, y da igual, porque son números.

> 🕳️ **Madriguera — `Marshal` para copias profundas**
> `Marshal.load(Marshal.dump(objeto))` serializa y deserializa, y produce una copia profunda de todo. No sirve acá: no sabe serializar procs (`TypeError: no _dump_data is defined for class Proc`), y de todos modos copiaría de más.
> *Volvé al camino — esto se profundiza aparte, otro día.*

---

## 4. 🔴 Paso 2: `initialize_copy`

> **Regla.** Cuando `clone` (o `dup`) crea el objeto nuevo, le manda `initialize_copy(original)`. Redefinirlo es la forma de decirle a Ruby "después de copiar lo de siempre, copiá también esto". Siempre se llama a `super` primero.

```ruby
class PrototypedObject
  def initialize_copy(original)                        # Ruby lo manda al objeto NUEVO, con el original como argumento
    super                                              # lo de siempre: copiar las variables de instancia
    @__properties__ = @__properties__.dup if @__properties__   # y ahora el diccionario: una copia propia
  end
end

atila = armar_guerrero
jack  = atila.clone

jack.instance_variable_get(:@__properties__).equal?(atila.instance_variable_get(:@__properties__))
# => false     ← dos diccionarios

atila.atacar_a(jack)
jack.energia                 # => 80      ✓
atila.energia                # => 100     ✓ ahora sí
```

```
# ¿CÓMO FUNCIONA?  jack = atila.clone
# 1. clone crea un objeto nuevo de PrototypedObject (jack) y le copia la autoclase de atila
# 2. clone le manda a jack: initialize_copy(atila)
# 3. super → copia las variables de instancia: jack.@__properties__ apunta al MISMO Hash que atila
# 4. @__properties__ = @__properties__.dup → jack reemplaza esa referencia por una copia del Hash
#    (el `if @__properties__` cubre el caso de clonar un objeto sin ninguna propiedad: nil.dup explotaría)
# 5. jack queda con sus propiedades, su copia del diccionario, y los métodos en su autoclase
```

**Por qué `@__properties__` directo y no `propiedades`.** Es la única excepción a la regla del Módulo 2. Acá el objetivo es justamente **reemplazar la variable**, no leerla; y si el original no tenía diccionario, no queremos crearle uno al clon por el solo hecho de clonarlo. Por eso el `if`.

**`dup` del Hash es suficiente.** Copia las claves y los valores a un Hash nuevo. Los valores siguen siendo los mismos objetos (100 es 100), y eso es exactamente la profundidad que decidimos.

> 💎 **Otra forma de hacerlo.** Sin tocar `initialize_copy`: un método propio que cree un `PrototypedObject` nuevo y le vaya seteando cada propiedad del original con `set_property`, clave por clave. Es lo mismo que acá, hecho "por afuera" y con la interfaz pública en vez de con la variable. Trade-off: hay que copiar los métodos aparte (la autoclase no viene gratis), y `guerrero.clone`, que es lo que el enunciado escribe, seguiría roto.

---

## 5. 🔴 Paso 3: el clon no se entera de lo que viene después

> **Regla.** El clon tiene **su propia autoclase**, copiada en el momento de clonar. Lo que el original define después con `set_method` va a la autoclase del original; el clon no lo ve. Y al revés: lo que el clon define no llega al original.

Es el requerimiento negativo del enunciado, y con la implementación de este módulo sale solo:

```ruby
atila = armar_guerrero
jack  = atila.clone

atila.set_method(:sanar, proc { set_property(:energia, energia + 10) })   # DESPUÉS de clonar
atila.sanar                      # anda (y deja a atila en 110)
atila.energia                    # => 110

jack.sanar                       # => NoMethodError: undefined method `sanar' for #<PrototypedObject:0x…>
jack.respond_to?(:sanar)         # => false

jack.set_method(:cortar, proc { "madera" })
jack.cortar                      # => "madera"
atila.cortar                     # => NoMethodError: undefined method `cortar' for #<PrototypedObject:0x…>

jack.singleton_class.equal?(atila.singleton_class)   # => false    ← dos autoclases
```

Esto es lo que el enunciado llama "los cambios no se impactan en el objeto que es clon": el clon es una **foto**. Lo que se copió, se copió; lo que pasa después, pasa en cada uno por separado. Fijate que no hubo que programar nada para que el clon no vea `sanar`: es consecuencia directa de que los métodos vivan en una autoclase que se copia.

Guardá esta frase para el Módulo 5, porque es la diferencia entera entre clonar y prototipar: **el clon copia y se desentiende; el prototipo linkea y se mantiene al día.**

### `clone` contra `dup`

> **Regla.** `dup` es la copia superficial **sin** la autoclase. Para nuestros objetos, un `dup` pierde los métodos y los getters.

| Escribís | Ruby entiende | Sale |
|---|---|---|
| `jack = atila.clone` | objeto nuevo, mismas variables, **autoclase copiada**, `initialize_copy` | `jack.atacar_a(…)` anda · `jack.energia` → `100` |
| `jack = atila.dup` | objeto nuevo, mismas variables, **sin autoclase**, `initialize_copy` | `jack.singleton_methods` → `[]` · `jack.energia` → `NoMethodError` |

Por eso el enunciado dice `clone` y no `dup`. `initialize_copy` corre en los dos casos, así que el diccionario se copia igual; lo que `dup` pierde es la autoclase entera.

> 💎 **Otra forma de hacerlo.** `atila.clone(freeze: true)` devuelve un clon **congelado** (`frozen?` → `true`): un objeto al que no se le pueden cambiar las variables. Sirve para fotos que no deben moverse más. Ninguna parte del enunciado lo pide, pero `clone` lo acepta y conviene saber que existe: un objeto prototipado congelado no va a poder recibir `set_property`.

> 🎯 **Para el parcial, si te preguntan** qué diferencia hay entre clonar un objeto prototipado y darle un prototipo:
> Clonar produce una copia independiente en el momento de clonar: se copia el estado (el diccionario de propiedades) y el comportamiento (la autoclase), y los cambios posteriores en cualquiera de los dos no afectan al otro. Darle un prototipo no copia nada: linkea el objeto a otro, de modo que los métodos se buscan en el prototipo en cada envío, y un método agregado al prototipo después queda disponible para el derivado. El enunciado lo resume así: con la clonación se copia el estado; con los prototipos, no.

---

## 6. 🔴 Las piezas armadas

El framework al final de este módulo:

```ruby
class PrototypedObject
  def set_property(nombre, valor)
    define_singleton_method(nombre) { get_property(nombre) }
    propiedades[nombre] = valor
  end

  def get_property(nombre)
    propiedades[nombre]
  end

  def has_property?(nombre)
    propiedades.key?(nombre)
  end

  def set_method(selector, bloque)
    define_singleton_method(selector, &bloque)
  end

  def initialize_copy(original)
    super                                                      # variables de instancia y autoclase: lo de Ruby
    @__properties__ = @__properties__.dup if @__properties__   # el diccionario: una copia propia
  end

  private

  def propiedades
    @__properties__ ||= {}
  end
end
```

### Los tests de esta pieza

```ruby
describe 'clone' do
  it 'el primer bloque del enunciado, verbatim' do
    guerrero = armar_guerrero
    otro_guerrero = guerrero.clone
    guerrero.atacar_a otro_guerrero
    expect(otro_guerrero.energia).to eq 80
  end
  it 'el clon tiene su propio estado' do
    atila = armar_guerrero
    jack  = atila.clone
    atila.atacar_a(jack)
    expect(jack.energia).to eq 80
    expect(atila.energia).to eq 100
  end
  it 'el clon no ve los métodos que el original aprende después' do
    atila = armar_guerrero
    jack  = atila.clone
    atila.set_method(:sanar, proc { set_property(:energia, energia + 10) })
    expect { jack.sanar }.to raise_error(NoMethodError)
    expect(jack.respond_to?(:sanar)).to be false
  end
  it 'el original no ve los métodos del clon' do
    atila = armar_guerrero
    jack  = atila.clone
    jack.set_method(:cortar, proc { "madera" })
    expect { atila.cortar }.to raise_error(NoMethodError)
  end
  it 'un objeto sin propiedades también se clona' do
    expect(PrototypedObject.new.clone.has_property?(:energia)).to be false
  end
end
```

---

## Checkpoint del Módulo 4

1. ¿Qué tres cosas hace el `clone` de Ruby con un objeto? ¿Cuál de ellas es la que nos deja un bug?
2. Después de `jack = atila.clone` sin `initialize_copy`, `atila.atacar_a(jack)` deja a **los dos** en 80. Dibujá las referencias y explicá por qué.
3. El `expect` del enunciado pasa con el bug. ¿Qué frase de la sección 3 del enunciado explica por qué eso no alcanza?
4. Definí copia superficial y copia profunda. ¿Por qué no existe una copia profunda "de todo" por defecto?
5. ¿Qué es `initialize_copy`, quién lo llama, y por qué se llama a `super` adentro?
6. En `initialize_copy` se escribe `@__properties__` directo, contra la regla del Módulo 2. ¿Por qué acá sí, y para qué está el `if`?
7. `atila.set_method(:sanar, …)` después de clonar, y `jack.sanar` explota. ¿Qué hubo que programar para que eso pase? ¿Dónde vive `sanar` y dónde lo busca `jack`?
8. ¿Qué diferencia hay entre `clone` y `dup` para nuestros objetos? ¿Qué pierde `jack = atila.dup`?
9. "El clon copia y se desentiende." Explicá la frase con `sanar`.
10. Con lo que tenés hasta acá, ¿qué línea del primer bloque de 4.1 queda sin cumplir? (Pista: ninguna. Verificalo contra el enunciado.)

## Qué viene en el Módulo 5

`espadachin.set_prototype(guerrero)`: lo contrario de clonar. El espadachín no copia nada de guerrero; **va a buscar** a guerrero lo que no tiene, cada vez. Vas a ver las dos únicas maneras de lograrlo (copiar los métodos al momento de linkear, o buscarlos en cada envío), por qué copiarlos no sirve, y por qué con los métodos en la autoclase no hay dónde enganchar la búsqueda. Ahí vuelve la "otra forma" del Módulo 3, y pasa a ser la forma.

**FIN DEL MÓDULO 4**
