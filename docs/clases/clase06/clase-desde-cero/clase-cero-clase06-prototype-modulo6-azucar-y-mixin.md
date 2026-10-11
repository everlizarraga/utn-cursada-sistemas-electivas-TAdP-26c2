# Clase desde cero — Prototype — Módulo 6: Azúcar de 4.1 y el mixin

**Unidad:** clase06 · **Módulo:** 6 de 9 (+1 opcional) · **Densidad:** 🔴 · **Parte del enunciado:** 4.1, `espadachin.energia = 100` y `class Object; include Prototyped; end`

## Sobre este documento

**Qué cubre:** las dos líneas de 4.1 que faltan. Primero el **setter** `espadachin.energia = 100`: por qué es el único punto del ejercicio donde no hay dos caminos sino uno, cómo se reconoce un setter por el nombre, qué prioridad tiene frente a un método, y qué le pasa a `respond_to?`. Después, **dónde vive el comportamiento prototipable**: se extrae a un mixin, `Prototyped`, y se incluye en `Object`, con las dos trampas que eso destapa. Al final del módulo, la parte 4.1 del enunciado anda completa, verbatim.

**Qué NO cubre:** el azúcar de la parte 4.3 (`x = proc` como método, `PrototypedObject.new { … }`), que es el Módulo 8. Deja **abierto a propósito** el hilo de `to_s` (sección 7), que se cierra en el Módulo 10.

**Tené el enunciado a mano**, en 4.1: la línea `espadachin.energia = 100` y el bloque final con `class Object`.

## De dónde venís

Del Módulo 2: los dos únicos caminos para responder un mensaje; `has_property?`.
Del Módulo 5: los métodos en `@__methods__`, `find_method` en cadena, `method_missing` con `instance_exec`, `respond_to_missing?` con el mismo criterio, el getter como método del diccionario.
De clase01: un mixin es un módulo que se incluye en una clase con `include`, y sus métodos pasan a la cadena de esa clase.
De clase04: `obj.m = v` es azúcar de `obj.m=(v)`: un mensaje cuyo nombre termina en `=`, con un argumento; `name.to_s` para operar sobre un símbolo como texto; los objetos **congelados** (`frozen?`) rechazan cambios a sus variables.

---

## 1. 🔴 Qué pide el setter

> 📄 **El enunciado dice** (4.1, segundo bloque):
> ```ruby
> espadachin.energia = 100
> ```

**En criollo:** asignarle una propiedad a un objeto prototipado **con la sintaxis de Ruby**, sin `set_property`. Es la primera cucharada de azúcar sintáctico, y el enunciado la cuela en 4.1 aunque el azúcar formal sea 4.3. Hoy:

```ruby
espadachin = PrototypedObject.new
espadachin.energia = 100
# => NoMethodError: undefined method `energia=' for an instance of PrototypedObject
```

El error ya dice cómo se llama el mensaje: `energia=`. Ruby lee `objeto.m = v` y lo convierte en `objeto.m=(v)`: un mensaje de nombre `m=` con un argumento. Es lo que hace cualquier setter de `attr_accessor`.

---

## 2. 🔴 Paso 0: por qué hay un solo camino

> **Regla.** Para que `espadachin.energia = 100` responda hay, como siempre, dos caminos: definir el método `energia=` o atrapar el mensaje en `method_missing`. Pero **nunca hubo un momento anterior en el que definir `energia=`**: esta es la primera vez que alguien nombra `energia` en ese objeto. Queda uno solo: `method_missing`.

Comparalo con el getter del Módulo 2. Ahí el método `energia` se definía adentro de `set_property`, porque `set_property` **era** el momento de declaración: alguien dijo "este objeto tiene energía" y en ese instante se creó el getter. Con el setter no hay declaración previa. Mirá la secuencia del enunciado en 4.3, que es la misma idea más explícita:

> 📄 **El enunciado dice** (4.3, primer bloque):
> ```ruby
> guerrero_proto = PrototypedObject.new
> guerrero_proto.energia = 100
> ```

Línea uno: nace el objeto, vacío. Línea dos: `energia = 100`, y tiene que andar. No hubo oportunidad de decir "si en algún momento te setean energía, usá este método". Si lo que pidieran fuera *declarar* la propiedad y después asignarla, habría un momento para definir el setter. Pero lo que piden es poder escribir **cualquier nombre, `=`, un valor**, sin declaración. Eso solo lo atrapa `method_missing`.

> 🎯 **Para el parcial, si te preguntan** por qué el setter de un objeto prototipado se implementa con `method_missing` y no con `define_method`:
> Porque `define_method` necesita un momento previo en el que se conozca el nombre, y el setter es la primera vez que ese nombre aparece: `objeto.energia = 100` sobre un objeto vacío. Sin declaración no hay dónde definir el método; `method_missing` es el único mecanismo que responde un mensaje cuyo nombre no se conoció de antemano.

---

## 3. 🔴 Paso 1: reconocer un setter por el nombre

> **Regla.** Un setter es un mensaje cuyo selector **termina en `=`**. Es la única información disponible: en Ruby no hay tipos declarados que ayuden, solo la palabra. Se decide que todo selector `algo=` que no sea un método conocido **es un setter de la propiedad `algo`**.

Un ejercicio mental: te mandan `saludar`, `energia=`, `pollo=`, `🐟`. ¿Cuáles son setters? Los dos que terminan en `=`. No hay otra marca. Y es una decisión con costo: una vez que todo `algo=` se trata como setter, no vas a poder tener un **método** común que se llame `algo=`… salvo que le des prioridad al método (paso 2).

Las herramientas, sobre el mismo caso:

| Escribís | Ruby entiende | Sale |
|---|---|---|
| `:energia=.end_with?("=")` | ¿el símbolo termina con ese texto? | `true` |
| `:energia=.chomp("=")` | sacarle el `=` del final… a un símbolo | `NoMethodError: undefined method 'chomp' for an instance of Symbol` |
| `:energia=.to_s.chomp("=")` | pasar a texto, sacar el `=` | `"energia"` |
| `:energia=.to_s.chomp("=").to_sym` | y volver a símbolo | `:energia` |

Es la trampa de símbolo contra string de clase04, de nuevo: `end_with?` lo entienden los dos, `chomp` solo los strings. Para usar el nombre como clave del diccionario hay que volver a símbolo, porque `set_property(:energia, …)` y `set_property("energia", …)` serían dos propiedades distintas.

```ruby
class PrototypedObject
  private

  def method_missing(selector, *args)
    bloque = find_method(selector)
    if bloque
      instance_exec(*args, &bloque)
    elsif selector.end_with?("=")                                # ¿es un setter?
      set_property(selector.to_s.chomp("=").to_sym, args.first)  # energia= → :energia; el valor es el único argumento
    else
      super
    end
  end
end

espadachin = PrototypedObject.new
espadachin.energia = 100          # => 100      ← una asignación devuelve el valor asignado, siempre
espadachin.energia                # => 100      ← set_property creó el getter
espadachin.has_property?(:energia)  # => true
espadachin.energia = 50
espadachin.get_property(:energia)   # => 50     ← pisa, como set_property
```

```
# ¿CÓMO FUNCIONA?  espadachin.energia = 100
# 1. Ruby lo lee como espadachin.energia=(100)
# 2. lookup de energia= → no está en ningún lado → method_missing(:energia=, 100)
# 3. find_method(:energia=) → nadie en la cadena lo tiene → nil
# 4. :energia=.end_with?("=") → true → set_property(:energia, 100)
# 5. set_property define el getter energia en el diccionario de métodos y guarda 100 en el de propiedades
# 6. el valor de la expresión `espadachin.energia = 100` es 100 (Ruby ignora lo que devuelva el setter)
```

**El setter escribe en el derivado, nunca en el prototipo:**

```ruby
guerrero = armar_guerrero          # energia 100
derivado = PrototypedObject.new
derivado.set_prototype(guerrero)
derivado.energia = 5
derivado.energia                   # => 5
guerrero.energia                   # => 100     ← el estado es de cada uno (Módulo 5, sección 6)
```

Y con el setter disponible, `recibe_danio` y `sanar` se pueden escribir como el enunciado los escribe, con `self.energia = …`:

```ruby
guerrero.set_method(:recibe_danio, proc { |danio| self.energia = self.energia - danio })
guerrero.set_method(:sanar,        proc { self.energia = self.energia + 10 })        # verbatim del enunciado
```

⚠️ **Trampa: `energia = valor` sin `self.`** adentro de un proc crea una **variable local** llamada `energia` y no manda ningún mensaje. Ruby no puede distinguir una asignación a variable de un setter sin receptor explícito; por eso los setters siempre van con `self.` (`self.energia = …`), y esa es la forma que el enunciado usa.

---

## 4. 🔴 Paso 2: el método tiene prioridad

> **Regla.** `method_missing` pregunta primero si hay un método con ese selector en la cadena, y recién después si parece un setter. Así un `set_method(:energia=, …)` puede redefinir qué significa asignar `energia`. Al revés, ningún `algo=` podría ser jamás un método.

El orden de los `if` en el `method_missing` de arriba no es casual:

```ruby
espadachin.set_method(:energia=, proc { |valor| set_property(:energia, valor * 2) })   # un método que se llama energia=
espadachin.energia = 10
espadachin.energia               # => 20      ← ganó el método: find_method lo encontró antes de mirar el "="
```

| Orden de las ramas | Qué pasa con `set_method(:energia=, …)` | Consecuencia |
|---|---|---|
| método primero, setter después | el método gana | un `algo=` se puede redefinir; es un método como cualquier otro |
| setter primero, método después | el setter gana siempre | `algo=` nunca puede ser un método: la rama del método es inalcanzable para esos nombres |

Las dos son decisiones válidas para una herramienta; la segunda es más rígida sin ganar nada. Se elige la primera.

> 💎 **Otra forma de hacerlo.** Sacar el criterio "termina en `=`" a un método propio (`setter?(selector)`), para que alguien que extienda el framework pueda redefinir qué cuenta como setter. Cuesta una línea y abre una puerta; acá queda cableado porque el enunciado no pide esa puerta.

---

## 5. 🔴 Paso 3: `respond_to?` y el setter

> **Regla.** `respond_to_missing?` tiene que seguir el mismo criterio que `method_missing`: todo selector que termina en `=` se responde.

```ruby
class PrototypedObject
  private

  def respond_to_missing?(selector, include_private = false)
    !find_method(selector).nil? || selector.end_with?("=") || super
  end
end

espadachin.respond_to?(:energia=)       # => true
espadachin.respond_to?(:cualquiera=)    # => true      ← sí: cualquier asignación se acepta
espadachin.respond_to?(:cualquiera)     # => false
```

La segunda línea es consecuencia honesta de la decisión: si el objeto acepta cualquier `algo=`, `respond_to?` tiene que decirlo. Es la "interfaz infinita" del Módulo 3, declarada. Si eso molestara, la alternativa es exigir declaración previa, y el enunciado no la permite.

---

## 6. 🔴 Paso 4: dónde vive el comportamiento prototipable

> 📄 **El enunciado dice** (4.1, último bloque):
> *"Finalmente, también nos interesa hacer que el comportamiento 'prototipable' sea algo que yo pueda usar en cualquier lado. Por ejemplo:"*
> ```ruby
> class Object
>   include Prototyped
> end
> ```

**En criollo:** todo lo que escribimos en `PrototypedObject` (propiedades, métodos, prototipo, el lookup) tiene que estar en un **módulo** llamado `Prototyped`, para que cualquier clase lo incluya; incluido en `Object`, **cualquier objeto de Ruby** pasa a ser prototipable. `PrototypedObject` queda como una clase vacía que lo incluye.

Es la respuesta a la pregunta del Módulo 1 ("¿dónde se define el comportamiento de `PrototypedObject`?"). La respuesta obvia era "adentro de `PrototypedObject`", y fue lo razonable para empezar. Pero nada de lo que escribimos depende de `PrototypedObject`: usa dos diccionarios, una referencia y `method_missing`, que cualquier objeto puede tener. Es comportamiento que se **mezcla**, no que se hereda: un mixin.

> **Regla.** Se mueve todo el cuerpo de `PrototypedObject` a `module Prototyped`, sin cambiar una línea. `PrototypedObject` queda como `class PrototypedObject; include Prototyped; end`.

```ruby
module Prototyped
  # … exactamente lo que tenía PrototypedObject (sección 8, las piezas armadas)
end

class PrototypedObject
  include Prototyped
end

PrototypedObject.ancestors.first(3)    # => [PrototypedObject, Prototyped, Object]
x = PrototypedObject.new
x.energia = 3
x.energia                              # => 3       ← todo sigue andando igual
```

Y ahora cualquier clase lo puede tener:

```ruby
Perro = Class.new { include Prototyped }      # una clase nueva, por si no querés ensuciar Object todavía
perro = Perro.new
perro.set_method(:ladrar, proc { "guau" })
perro.ladrar                                   # => "guau"
```

`Class.new { … }` crea una clase sin abrir `class … end`; el bloque es su cuerpo. `# también: class Perro; include Prototyped; end`. Sirve en los tests para fabricar una clase descartable.

### Incluirlo en `Object`

```ruby
class Object
  include Prototyped
end

Object.ancestors          # => [Object, Prototyped, Kernel, BasicObject]
#                               el módulo quedó entre Object y Kernel: TODO objeto pasa por él

o = Object.new
o.energia = 1
o.energia                 # => 1       ← un Object pelado, prototipable

texto = "hola"
texto.energia = 2
texto.energia             # => 2       ← un String con una propiedad (cada literal "hola" es un objeto distinto: hay que guardarlo en una variable)
```

Es lo que pide el enunciado. Y es donde aparecen dos trampas, porque "todo objeto" incluye objetos que no esperabas.

---

## 7. 🔴 Las dos trampas de `Object`

### ⚠️ Trampa 1: los objetos congelados

> **Regla.** Los números, los símbolos, `nil`, `true` y `false` están **congelados**: no se les puede crear una variable de instancia. Con `Prototyped` en `Object`, cualquier mensaje que no entiendan pasa por nuestro `method_missing`, que intenta crear `@__methods__`, y explota con un error que no es el que corresponde.

```ruby
5.nada
# => FrozenError: can't modify frozen Integer: 5        ← ⚠️ debería ser NoMethodError
5.respond_to?(:nada)
# => FrozenError: can't modify frozen Integer: 5        ← ⚠️ respond_to? no debería explotar nunca
nil.nada
# => FrozenError: can't modify frozen NilClass: nil
```

Lo que pasa: `5.nada` → `method_missing` → `find_method` → `metodos` → `@__methods__ ||= {}` → asignar una variable a un `Integer` congelado → `FrozenError`. Rompimos el comportamiento de todo Ruby: ni los enteros responden `respond_to?` como corresponde. Esto es exactamente el riesgo de meter cosas en `Object`: **cuanto más código ponemos ahí, más potencialmente entramos en conflicto con Ruby**.

La corrección: los lectores perezosos no crean nada en un objeto congelado; devuelven un diccionario vacío **y congelado**, para que leer funcione y escribir falle con un error honesto:

```ruby
module Prototyped
  SIN_NADA = {}.freeze                                                # un Hash vacío que no se puede modificar

  private

  def propiedades
    @__properties__ || (frozen? ? SIN_NADA : @__properties__ = {})   # ya existe → ese; congelado → el vacío; si no → crearlo
  end

  def metodos
    @__methods__ || (frozen? ? SIN_NADA : @__methods__ = {})
  end
end

5.nada                     # => NoMethodError: undefined method `nada' for an instance of Integer   ✓ como siempre
5.respond_to?(:nada)       # => false                                                                ✓
nil.nada                   # => NoMethodError: undefined method `nada' for nil                      ✓
5.has_property?(:x)        # => false
5.energia = 1              # => FrozenError: can't modify frozen Hash: {}      ← no se puede, y lo dice
Object.new.energia = 1     # => 1                                               ← un objeto común sigue igual
```

`a || (cond ? b : c = d)` se lee: si `a` tiene algo, `a`; si no, según `cond`, `b` o la asignación. Es la misma inicialización perezosa del Módulo 2 con una rama más. `# también:` escribirlo con `if frozen? … elsif … else … end` en cuatro líneas.

> 🕳️ **Madriguera — `freeze` es superficial**
> Un `PrototypedObject` congelado con `freeze` después de tener propiedades sigue aceptando `energia = 2`, porque lo congelado es el objeto, no su diccionario. Congelar en profundidad es otra decisión de diseño; el enunciado no la pide.
> *Volvé al camino — esto se profundiza aparte, otro día.*

### ⚠️ Trampa 2: los métodos que `Object` ya tiene

> **Regla.** `method_missing` solo recibe mensajes que **ningún** método atendió. Un selector que `Object` ya define (`to_s`, `inspect`, `==`, `class`, `freeze`…) nunca llega a `method_missing`, así que `set_method` con ese nombre **no tiene efecto**, ni en el objeto ni en sus derivados.

```ruby
guerrero = PrototypedObject.new
guerrero.set_method(:to_s, proc { "Atila" })
guerrero.to_s                       # => "#<PrototypedObject:0x…>"    ← el to_s de Object; el nuestro nunca corre

derivado = PrototypedObject.new
derivado.set_prototype(guerrero)
derivado.to_s                       # => "#<PrototypedObject:0x…>"    ← tampoco
```

El lookup de Ruby encuentra `to_s` en `Object` y se detiene ahí, satisfecho. Nuestro `find_method` nunca se consulta. Es la contracara de haber elegido `method_missing`: **sirve para atrapar lo que no está, no para pisar lo que ya está**. Con los métodos en la autoclase (Módulo 3) esto andaba, porque la autoclase va antes que `Object`; al migrar al diccionario lo perdimos.

En el modelo de prototipos, el derivado "hereda" de su prototipo; en el modelo de Ruby, los dos son instancias de la misma clase y heredan `to_s` **de `Object`**, cada uno por su lado. Pensar en prototipos y correr en clases: esa doble vida es la fuente de este problema, y de cualquier otro que involucre métodos que Ruby ya trae. Resolverlo de verdad pide otra arquitectura, donde el lookup lo haga Ruby. Queda sembrado para el Módulo 10; para el enunciado, que nunca redefine un método de `Object`, no hace falta.

> 🎯 **Para el parcial, si te preguntan** qué limitación tiene resolver prototipos con `method_missing`:
> `method_missing` solo se ejecuta cuando el lookup de Ruby no encontró ningún método, así que no puede interceptar selectores que la jerarquía de clases ya define, como `to_s` o `==`. Un prototipo que redefina uno de esos no afecta a sus derivados, porque Ruby encuentra la versión de `Object` antes de llegar al gancho. Además, incluido en `Object`, el mecanismo alcanza a objetos congelados y hay que cuidar que leer no intente escribir.

---

## 8. 🔴 Las piezas armadas

El framework al final de este módulo, ahora como mixin. Es el código del Módulo 5 movido a `Prototyped`, con el setter en `method_missing`, el criterio en `respond_to_missing?`, y los lectores que respetan a los congelados.

```ruby
module Prototyped
  SIN_NADA = {}.freeze

  def set_property(nombre, valor)
    set_method(nombre, proc { get_property(nombre) })
    propiedades[nombre] = valor
  end

  def get_property(nombre)
    propiedades[nombre]
  end

  def has_property?(nombre)
    propiedades.key?(nombre)
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
      instance_exec(*args, &bloque)                                 # 1º: un método de la cadena
    elsif selector.end_with?("=")
      set_property(selector.to_s.chomp("=").to_sym, args.first)     # 2º: un setter
    else
      super                                                         # 3º: nadie lo entiende
    end
  end

  def respond_to_missing?(selector, include_private = false)
    !find_method(selector).nil? || selector.end_with?("=") || super
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
end
```

### Los tests de esta pieza

```ruby
describe 'azúcar de 4.1: el setter' do
  it 'asigna una propiedad sin set_property y crea el getter' do
    espadachin = PrototypedObject.new
    espadachin.energia = 100
    expect(espadachin.energia).to eq 100
    expect(espadachin.has_property?(:energia)).to be true
  end
  it 'el setter escribe en el derivado, no en el prototipo' do
    guerrero = armar_guerrero
    derivado = PrototypedObject.new
    derivado.set_prototype(guerrero)
    derivado.energia = 5
    expect(derivado.energia).to eq 5
    expect(guerrero.energia).to eq 100
  end
  it 'un método llamado algo= tiene prioridad sobre el setter' do
    objeto = PrototypedObject.new
    objeto.set_method(:energia=, proc { |valor| set_property(:energia, valor * 2) })
    objeto.energia = 10
    expect(objeto.energia).to eq 20
  end
  it 'respond_to? acepta cualquier asignación' do
    expect(PrototypedObject.new.respond_to?(:cualquiera=)).to be true
    expect(PrototypedObject.new.respond_to?(:cualquiera)).to be false
  end
  it 'el segundo bloque de 4.1, verbatim' do
    guerrero = armar_guerrero
    guerrero.set_method(:recibe_danio, proc { |danio| self.energia = self.energia - danio })
    otro_guerrero = guerrero.clone
    guerrero.atacar_a otro_guerrero
    espadachin = PrototypedObject.new
    espadachin.set_prototype(guerrero)
    espadachin.set_property(:habilidad, 0.5)
    espadachin.set_property(:potencial_espada, 30)
    espadachin.energia = 100
    espadachin.potencial_defensivo = 10
    espadachin.potencial_ofensivo = 30
    espadachin.set_method(:potencial_ofensivo, proc {
      get_property(:potencial_ofensivo) + self.potencial_espada * self.habilidad
    })
    espadachin.atacar_a(otro_guerrero)
    expect(otro_guerrero.energia).to eq 45
    guerrero.set_method(:sanar, proc { self.energia = self.energia + 10 })
    espadachin.sanar
    expect(espadachin.energia).to eq 110
    expect { otro_guerrero.sanar }.to raise_error(NoMethodError)
    guerrero.set_method(:potencial_ofensivo, proc { 1000 })
    expect(espadachin.potencial_ofensivo).to eq 45
  end
end

describe 'Prototyped como mixin' do
  it 'cualquier clase puede incluirlo' do
    clase = Class.new { include Prototyped }
    perro = clase.new
    perro.set_method(:ladrar, proc { "guau" })
    expect(perro.ladrar).to eq "guau"
  end
  it 'incluido en Object, cualquier objeto es prototipable' do
    class Object; include Prototyped; end
    objeto = Object.new
    objeto.energia = 1
    expect(objeto.energia).to eq 1
  end
  it 'y lo demás sigue funcionando como siempre' do
    expect { 5.nada }.to raise_error(NoMethodError)
    expect { nil.nada }.to raise_error(NoMethodError)
    expect(5.respond_to?(:nada)).to be false
    expect(5.respond_to?(:to_s)).to be true
    expect { 5.energia = 1 }.to raise_error(FrozenError)
  end
end
```

---

## Checkpoint del Módulo 6

1. ¿En qué mensaje convierte Ruby la línea `espadachin.energia = 100`? ¿Cuántos argumentos lleva?
2. ¿Por qué para el getter había dos caminos y para el setter hay uno solo? ¿Qué "momento" falta?
3. ¿Cómo se reconoce un setter? ¿Qué costo tiene esa decisión y cómo se mitiga con el orden de las ramas?
4. `:energia=.chomp("=")` explota y `:energia=.to_s.chomp("=")` no. ¿Por qué hay que volver a símbolo después?
5. Escribí `energia = 5` y `self.energia = 5` adentro de un proc y explicá qué hace cada uno.
6. ¿Qué devuelve la expresión `espadachin.energia = 100`, y de quién depende?
7. `respond_to?(:cualquiera=)` da `true`. ¿Es un bug? Justificá.
8. ¿Por qué el comportamiento prototipable termina en un módulo y no en la clase `PrototypedObject`? ¿Qué frase del enunciado lo pide?
9. Con `Prototyped` en `Object`, `5.nada` daba `FrozenError`. Seguí el camino desde el mensaje hasta la línea que explota, y explicá la corrección.
10. `guerrero.set_method(:to_s, …)` no tiene efecto. ¿En qué punto del lookup se decide eso? ¿Qué implementación anterior sí lo permitía y por qué?

## Qué viene en el Módulo 7

La parte 4.2: constructores. Un objeto `PrototypedConstructor` que fabrica derivados de un prototipo con el estado ya inicializado, de cuatro formas: con un proc que recibe el objeto nuevo y los argumentos, por defecto con un mapa de propiedades, copiando el estado del prototipo (`copy`), y extendiendo otro constructor (`extended`), donde los argumentos se reparten en orden entre el constructor padre y el hijo. Vas a usar `has_property?` y a necesitar listar las propiedades de un objeto, que es la primera vez que el diccionario del Módulo 2 paga la decisión de existir.

**FIN DEL MÓDULO 6**
