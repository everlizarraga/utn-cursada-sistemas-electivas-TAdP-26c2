# Clase desde cero — Prototype — Módulo 7: Constructores

**Unidad:** clase06 · **Módulo:** 7 de 9 (+1 opcional) · **Densidad:** 🔴 · **Parte del enunciado:** 4.2

## Sobre este documento

**Qué cubre:** `PrototypedConstructor`, un objeto que fabrica derivados de un prototipo con el estado ya inicializado. Se construye en el orden del enunciado: con un proc que recibe el objeto nuevo y los argumentos; por defecto, con un mapa de propiedades; `copy`, que copia el estado actual del prototipo; y `extended`, un constructor que extiende a otro y **reparte los argumentos en orden** entre el padre y el hijo. Al final del módulo, la parte 4.2 anda completa.

**Qué NO cubre:** las formas con bloque y el encadenado `create … with` de 4.3 (Módulo 8). Este módulo trabaja solo con procs.

**Tené el enunciado a mano**, en la parte 4.2 entera.

## De dónde venís

Del Módulo 5: un derivado busca métodos en su prototipo y tiene su propio estado; `set_prototype`.
Del Módulo 6: el setter `objeto.x = valor`, `has_property?`, el mixin `Prototyped`.
De clase04: `proc.call(a, b)` ejecuta un proc con argumentos; `arity` es la cantidad de parámetros que un proc declara; `*args` junta los argumentos de un mensaje en una lista; un proc que recibe menos argumentos de los que declara **no falla**: rellena con `nil`.
De clase01: un **método de clase** se define con `def self.nombre` y se le manda a la clase (`PrototypedConstructor.copy(…)`).

---

## 1. 🔴 Qué piden los constructores

> 📄 **El enunciado dice** (4.2 *Constructores*, primer párrafo):
> *"Las clases proveen, además de comportamiento, un mecanismo para construir los objetos de manera tal que cada uno pueda tener inicializado su estado para funcionar según corresponda."*

**En criollo:** hasta ahora, para tener un guerrero nuevo hay que crear un `PrototypedObject`, linkearlo y setearle las propiedades una por una, a mano, cada vez. Las clases resuelven eso con `new` y `initialize`; los prototipos no tienen nada parecido. Hay que construirlo: un **constructor** es un objeto que sabe fabricar derivados de un prototipo dado, inicializados.

> 📄 **El enunciado dice** (4.2, primer bloque):
> ```ruby
> Guerrero = PrototypedConstructor.new(guerrero, proc {
>  |guerrero_nuevo, una_energia, un_potencial_ofensivo, un_potencial_defensivo|
>   guerrero_nuevo.energia = una_energia
>   guerrero_nuevo.potencial_ofensivo = un_potencial_ofensivo
>   guerrero_nuevo.potencial_defensivo = un_potencial_defensivo
> })
>
> un_guerrero = Guerrero.new(100, 30, 10)
> expect(un_guerrero.energia).to eq(100)
> ```
> *"El resultado del new sería un objeto con 'guerrero' como prototipo y el estado inicializado como indica el proc que se pasa como parámetro."*

**En criollo, línea por línea:**

- `PrototypedConstructor.new(guerrero, proc { … })`: el constructor recibe el **prototipo** y un **inicializador**: un proc cuyo primer parámetro es el objeto nuevo, y los siguientes son los argumentos del constructor.
- `Guerrero = …`: el constructor se guarda en una constante con mayúscula, como una clase. Es a propósito: para quien lo usa, `Guerrero.new(100, 30, 10)` se lee igual que si `Guerrero` fuera una clase. Pero **no es una clase**: es un objeto común, de clase `PrototypedConstructor`. Es el "no ver clases" del Módulo 1 llevado a la construcción.
- `Guerrero.new(100, 30, 10)`: crea un `PrototypedObject`, le pone `guerrero` de prototipo, y ejecuta el proc con el objeto nuevo y los tres números. Devuelve el objeto.

Y después, tres variantes más, que se ven en las secciones 3, 4 y 5.

---

## 2. 🔴 Paso 0: el constructor con un proc

> **Regla.** `PrototypedConstructor` guarda el prototipo y el inicializador. `new(*args)` crea un `PrototypedObject` vacío, lo linkea al prototipo, ejecuta el inicializador con el objeto nuevo seguido de los argumentos, y devuelve el objeto.

```ruby
class PrototypedConstructor
  def initialize(prototipo, inicializador)
    @prototype = prototipo
    @inicializador = inicializador           # un proc: |nuevo, arg1, arg2, …|
  end

  def prototype
    @prototype
  end

  def new(*args)                             # new común y corriente: es un método de instancia de ESTE objeto
    nuevo = PrototypedObject.new             # 1. un objeto vacío
    nuevo.set_prototype(prototype)           # 2. linkeado al prototipo
    @inicializador.call(nuevo, *args)        # 3. el proc lo inicializa: nuevo es su primer parámetro
    nuevo                                    # 4. se devuelve
  end
end

Guerrero = PrototypedConstructor.new(guerrero, proc {
  |guerrero_nuevo, una_energia, un_potencial_ofensivo, un_potencial_defensivo|
  guerrero_nuevo.energia = una_energia                                           # el setter del Módulo 6
  guerrero_nuevo.potencial_ofensivo = un_potencial_ofensivo
  guerrero_nuevo.potencial_defensivo = un_potencial_defensivo
})

un_guerrero = Guerrero.new(100, 30, 10)
un_guerrero.energia                        # => 100
un_guerrero.prototype.equal?(guerrero)     # => true
Guerrero.class                             # => PrototypedConstructor   ← un objeto, no una clase

otro = Guerrero.new(100, 30, 10)
un_guerrero.atacar_a(otro)                 # atacar_a viene de guerrero, por la cadena
otro.energia                               # => 80
```

```
# ¿CÓMO FUNCIONA?  Guerrero.new(100, 30, 10)
# 1. Guerrero es una instancia de PrototypedConstructor; new es un método común de esa instancia
# 2. args = [100, 30, 10]
# 3. nuevo = PrototypedObject.new → vacío; nuevo.set_prototype(guerrero)
# 4. @inicializador.call(nuevo, 100, 30, 10) → guerrero_nuevo = nuevo, una_energia = 100, …
#    → tres setters sobre nuevo → tres propiedades en SU diccionario
# 5. devuelve nuevo
```

**Por qué `new` se llama `new`.** Para que `Guerrero.new(…)` se lea como siempre. Es un método común, definido con `def new`, sobre una instancia; no tiene nada que ver con el `new` de `Class`, que crea instancias. Dos mensajes con el mismo nombre en objetos distintos, cada uno con su significado: polimorfismo.

### ⚠️ Trampa: un proc no cuenta los argumentos

> **Regla.** Un proc que recibe menos argumentos de los que declara rellena con `nil` y sigue. El constructor tiene que contar por su cuenta, o un `Guerrero.new(1, 2)` deja una propiedad en `nil` sin decir nada.

```ruby
proc { |a, b, c| [a, b, c] }.call(1, 2)    # => [1, 2, nil]     ← sin error

Guerrero.new(1, 2)                          # anda, y deja potencial_defensivo en nil
Guerrero.new(1, 2).potencial_defensivo      # => nil
```

Es la conducta "no hacer nada" del Módulo 2, la peor: el error aparece lejos, cuando alguien compara `nil < 30`. Se corrige en la sección 5, donde contar los argumentos pasa a ser necesario por otra razón.

---

## 3. 🔴 Paso 1: el constructor por defecto, con un mapa

> 📄 **El enunciado dice** (4.2, segundo bloque):
> *"Pero esa forma de definir los constructores requiere mucho trabajo. […] lo que podemos hacer es definir un constructor sencillo por defecto. Tenemos la información de las propiedades del prototipo para trabajar."*
> ```ruby
> Guerrero = PrototypedConstructor.new(guerrero)
>
> un_guerrero = Guerrero.new(
>   {energia: 100, potencial_ofensivo: 30, potencial_defensivo: 10}
> )
> expect(un_guerrero.potencial_ofensivo).to eq(30)
> ```
> *"Por el hecho de que no está claramente definido el orden de los parámetros, usamos un mapa."*

**En criollo:** si no se pasa inicializador, el constructor usa uno por defecto que recibe **un solo argumento**: un Hash de nombre → valor, y setea cada par. "Tenemos la información de las propiedades del prototipo": el constructor puede preguntarle al prototipo qué propiedades tiene, y rechazar las que no existan.

> **Regla.** Sin inicializador, el constructor usa un proc por defecto que toma un mapa y setea cada propiedad, verificando con `has_property?` que el prototipo la tenga.

```ruby
class PrototypedConstructor
  def initialize(prototipo, inicializador = nil)                 # inicializador opcional
    @prototype = prototipo
    @inicializador = inicializador || inicializador_por_defecto  # si no vino, el de abajo
  end

  private

  def inicializador_por_defecto
    proc { |nuevo, valores|                                      # |nuevo, un_mapa|: UN argumento además del objeto
      valores.each do |nombre, valor|                            # each sobre un Hash: cada par clave → valor
        unless prototype.has_property?(nombre)
          raise ArgumentError, "el prototipo no tiene la propiedad #{nombre}"
        end
        nuevo.set_property(nombre, valor)
      end
    }
  end
end

Guerrero = PrototypedConstructor.new(guerrero)
un_guerrero = Guerrero.new({energia: 100, potencial_ofensivo: 30, potencial_defensivo: 10})
un_guerrero.potencial_ofensivo          # => 30

Guerrero.new({sarasa: 1})               # => ArgumentError: el prototipo no tiene la propiedad sarasa
```

**Por qué verificar contra el prototipo.** Es lo que el enunciado sugiere con "tenemos la información de las propiedades del prototipo": el prototipo define qué propiedades tiene sentido inicializar. Un nombre que el prototipo no conoce es, casi seguro, un error de tipeo; mejor fallar acá que crear una propiedad fantasma. Y es la primera vez que el diccionario del Módulo 2 **paga**: con variables de instancia, "qué propiedades tiene el prototipo" sería imposible de responder con precisión.

**Por qué un mapa.** El enunciado lo dice: con el proc, el orden de los argumentos lo fija quien escribió el proc; sin proc no hay orden definido, y un mapa lleva los nombres.

---

## 4. 🔴 Paso 2: `copy`, el estado actual del prototipo

> 📄 **El enunciado dice** (4.2, tercer bloque):
> *"Además, queremos definir un constructor que cree un prototipo y copie el estado actual del prototipo."*
> ```ruby
> Guerrero = PrototypedConstructor.copy(guerrero)
>
> un_guerrero = Guerrero.new
> expect(un_guerrero.potencial_defensivo).to eq(10)
> ```

**En criollo:** un constructor cuyo `new` no recibe nada y produce un derivado con **los mismos valores** que tiene el prototipo en el momento de construir. Es un método de clase (`PrototypedConstructor.copy`), porque fabrica un constructor, no un objeto.

Para copiar el estado hace falta **listar** las propiedades del prototipo. El diccionario lo sabe; falta exponerlo:

```ruby
module Prototyped
  def property_names
    propiedades.keys            # keys: la lista de claves de un Hash
  end
end

guerrero.property_names         # => [:energia, :potencial_defensivo, :potencial_ofensivo]
```

> **Regla.** `copy` devuelve un constructor cuyo inicializador no toma argumentos y setea en el objeto nuevo cada propiedad del prototipo con su valor actual.

```ruby
class PrototypedConstructor
  def self.copy(prototipo)                                   # método de clase: se manda a PrototypedConstructor
    new(prototipo, proc { |nuevo|                            # |nuevo| solo: new() sin argumentos
      prototipo.property_names.each do |nombre|
        nuevo.set_property(nombre, prototipo.get_property(nombre))   # el valor de AHORA
      end
    })
  end
end

Guerrero = PrototypedConstructor.copy(guerrero)
un_guerrero = Guerrero.new
un_guerrero.potencial_defensivo          # => 10

un_guerrero.potencial_defensivo = 99
guerrero.potencial_defensivo             # => 10      ← copió valores, no comparte el diccionario
```

**`copy` no es `clone`.** Se parecen en que los dos arrancan con el estado del original, pero el objeto que `copy` produce **sigue prototipado** de `guerrero`: si guerrero aprende `sanar` después, lo entiende. `clone` cortaba el link; `copy` lo mantiene y además inicializa. Es la combinación que el enunciado quiere para "fabricar guerreros parecidos al prototipo".

```ruby
copia = Guerrero.new
guerrero.set_method(:sanar, proc { self.energia = self.energia + 10 })
copia.sanar                              # => 110     ← lo encontró en guerrero: el link está
```

---

## 5. 🔴 Paso 3: `extended`, argumentos en orden

> 📄 **El enunciado dice** (4.2, cuarto bloque):
> *"Finalmente, con lo que hicimos también podemos producir un constructor que altere los métodos que entiende el objeto, produciendo un nuevo tipo de objeto. Nos interesa que un constructor pueda extender de otro:"*
> ```ruby
> #Guerrero es la primer variante de constructores, que recibe 3 parametros
> Espadachin = Guerrero.extended {
>  |espadachin, habilidad, potencial_espada|
>   espadachin.set_property(:habilidad, habilidad)
>   espadachin.set_property(:potencial_espada, potencial_espada)
>
>   espadachin.set_method(:potencial_ofensivo, proc {
>     @potencial_ofensivo + self.potencial_espada * self.habilidad
>   })
>
> })
>
> espadachin = Espadachin.new(100, 30, 10, 0.5, 30)
> expect(espadachin.potencial_ofensivo).to eq(45)
> ```
> *"La convención que se define (de momento) es que los parámetros del constructor se pasan y se consumen en orden. Los primeros 3 parámetros del constructor generado van para Guerrero, porque Guerrero recibe 3 parámetros en su constructor."*

**En criollo, con dos erratas aclaradas:**

- `Guerrero.extended { … })`: abre con llave y cierra con `})`. Es una errata que delata la forma original: `Guerrero.extended(proc { |espadachin, habilidad, potencial_espada| … })`, **un proc**, con el objeto nuevo como primer parámetro, igual que el inicializador de la sección 2. Así se escribe en este módulo. (La forma con bloque, `extended { |habilidad, potencial_espada| … }` sin el objeto, es la de 4.3, Módulo 8.)
- `@potencial_ofensivo`: la misma errata del Módulo 5; se escribe `get_property(:potencial_ofensivo)`.
- `Espadachin.new(100, 30, 10, 0.5, 30)`: cinco argumentos. Los **tres primeros** los consume el inicializador de `Guerrero` (energía, ofensivo, defensivo); los **dos siguientes**, el de `Espadachin` (habilidad, potencial de espada). En orden: primero el padre, después el hijo.
- El espadachín resultante tiene el mismo prototipo que un guerrero (`guerrero`), más dos propiedades y un método propios, puestos por su inicializador. "Un nuevo tipo de objeto" sin crear ninguna clase.

> **Regla.** Un constructor extendido guarda a su **padre**. Al construir, primero el padre inicializa el objeto consumiendo **sus** argumentos (tantos como su inicializador declara, sin contar el objeto nuevo), y le devuelve al hijo los que sobran; el hijo consume los suyos. Para saber cuántos consume cada uno se usa `arity`.

Primero, cuántos argumentos consume un inicializador:

```ruby
proc { |nuevo, a, b, c| }.arity    # => 4      ← declara 4 parámetros; consume 4 - 1 = 3 argumentos (el nuevo no cuenta)
proc { |nuevo| }.arity             # => 1      ← consume 0: el inicializador de copy
proc { |nuevo, *resto| }.arity     # => -2     ← negativo: parámetros variables. No se soporta: los inicializadores declaran parámetros fijos
```

Después, partir la lista de argumentos:

```ruby
args = [100, 30, 10, 0.5, 30]
args.take(3)    # => [100, 30, 10]      los primeros 3
args.drop(3)    # => [0.5, 30]          lo que queda
```

Y el constructor, con la cadena padre → hijo:

```ruby
class PrototypedConstructor
  def initialize(prototipo, inicializador = nil, padre: nil)    # padre: un parámetro con nombre (keyword), opcional
    @prototype = prototipo
    @inicializador = inicializador || inicializador_por_defecto
    @padre = padre
  end

  def new(*args)
    nuevo = PrototypedObject.new
    nuevo.set_prototype(prototype)
    sobrantes = inicializar(nuevo, args)                         # inicializar devuelve lo que NO consumió
    raise ArgumentError, "sobran argumentos: #{sobrantes.inspect}" unless sobrantes.empty?
    nuevo
  end

  def extended(inicializador)
    PrototypedConstructor.new(prototype, inicializador, padre: self)   # mismo prototipo; yo soy el padre
  end

  protected                                                      # protected: lo pueden mandar otros PrototypedConstructor, no el usuario

  def inicializar(nuevo, args)
    args = @padre.inicializar(nuevo, args) if @padre             # 1. primero el padre (y el padre del padre…): consume lo suyo
    aridad = @inicializador.arity - 1                            # 2. cuántos me tocan a mí
    if args.size < aridad
      raise ArgumentError, "faltan argumentos: esperaba #{aridad}, llegaron #{args.size}"
    end
    @inicializador.call(nuevo, *args.take(aridad))               # 3. los consumo
    args.drop(aridad)                                            # 4. devuelvo el resto
  end
end
```

`padre: nil` es un **parámetro con nombre**: se pasa como `padre: self`, con la etiqueta, y si no se pasa vale `nil`. Sirve para que `new(prototipo, inicializador, padre: x)` se lea sin contar posiciones. `protected` es una visibilidad intermedia: el método lo pueden mandar **otras instancias de la misma clase** (el hijo le manda `inicializar` a su padre), pero no cualquiera desde afuera; `# también:` dejarlo público, con el costo de que `Guerrero.inicializar(…)` quede en la interfaz.

```ruby
Guerrero = PrototypedConstructor.new(guerrero, proc {
  |guerrero_nuevo, una_energia, un_potencial_ofensivo, un_potencial_defensivo|
  guerrero_nuevo.energia = una_energia
  guerrero_nuevo.potencial_ofensivo = un_potencial_ofensivo
  guerrero_nuevo.potencial_defensivo = un_potencial_defensivo
})

Espadachin = Guerrero.extended(proc { |espadachin, habilidad, potencial_espada|
  espadachin.set_property(:habilidad, habilidad)
  espadachin.set_property(:potencial_espada, potencial_espada)
  espadachin.set_method(:potencial_ofensivo, proc {
    get_property(:potencial_ofensivo) + self.potencial_espada * self.habilidad
  })
})

espadachin = Espadachin.new(100, 30, 10, 0.5, 30)
espadachin.potencial_ofensivo              # => 45.0     ← 30 + 30 × 0.5
espadachin.prototype.equal?(guerrero)      # => true     ← mismo prototipo que un Guerrero

Espadachin.new(100, 30, 10, 0.5)           # => ArgumentError: faltan argumentos: esperaba 2, llegaron 1
Guerrero.new(1, 2, 3, 4)                   # => ArgumentError: sobran argumentos: [4]
Guerrero.new(1, 2)                         # => ArgumentError: faltan argumentos: esperaba 3, llegaron 2    ← la trampa de la sección 2, cerrada
```

```
# ¿CÓMO FUNCIONA?  Espadachin.new(100, 30, 10, 0.5, 30)
# 1. nuevo vacío, prototipo guerrero
# 2. Espadachin.inicializar(nuevo, [100, 30, 10, 0.5, 30])
#    2a. tiene padre (Guerrero) → Guerrero.inicializar(nuevo, [100, 30, 10, 0.5, 30])
#        Guerrero no tiene padre; aridad = 4 - 1 = 3; call(nuevo, 100, 30, 10) → tres setters; devuelve [0.5, 30]
#    2b. args = [0.5, 30]; aridad de Espadachin = 3 - 1 = 2; call(nuevo, 0.5, 30) → dos propiedades y un método; devuelve []
# 3. sobrantes = [] → ok → devuelve nuevo
```

**La segunda variante**, que el enunciado menciona al final de 4.2: si `Guerrero` es el constructor por defecto (mapa), consume **un** argumento, y el espadachín se construye así:

```ruby
GuerreroMapa = PrototypedConstructor.new(guerrero)
EspadachinMapa = GuerreroMapa.extended(proc { |e, habilidad, potencial_espada|
  e.habilidad = habilidad
  e.potencial_espada = potencial_espada
})
e = EspadachinMapa.new({energia: 100, potencial_ofensivo: 30, potencial_defensivo: 10}, 0.5, 30)
e.habilidad                                # => 0.5
```

El mapa es el primer argumento (lo consume el padre), y después vienen los del hijo. Misma regla, otro padre. Y un constructor extendido se puede extender de nuevo: la cadena se recorre de arriba hacia abajo, cada uno consumiendo lo suyo.

> 💎 **Otra forma de hacerlo.** En vez de guardar al padre y recorrer la cadena, `extended` podría **componer** los dos inicializadores en un proc nuevo: `proc { |nuevo, *args| padre.call(nuevo, *args.take(n)); hijo.call(nuevo, *args.drop(n)) }`. Es más corto y no necesita `protected`; a cambio, el constructor hijo deja de saber quién es su padre (si alguna vez hace falta, por ejemplo para listar la cadena), y la aridad del proc compuesto es variable, con lo que la verificación de argumentos hay que hacerla a mano adentro.

> 🎯 **Para el parcial, si te preguntan** cómo reparte un constructor extendido los argumentos de `new`:
> En orden, de padre a hijo: cada inicializador declara cuántos argumentos toma (su `arity` menos el objeto nuevo), el padre consume los primeros tantos y le pasa al hijo los que sobran. La cadena de constructores se recorre antes de inicializar nada propio, igual que `super` al principio de un `initialize`. Si al final sobran o faltan argumentos, es un error de quien llamó.

---

## 6. 🔴 Las piezas armadas

`Prototyped` del Módulo 6 más `property_names`; `PrototypedConstructor` completo.

```ruby
module Prototyped
  # … todo lo del Módulo 6, más:

  def property_names
    propiedades.keys
  end
end

class PrototypedConstructor
  def self.copy(prototipo)
    new(prototipo, proc { |nuevo|
      prototipo.property_names.each do |nombre|
        nuevo.set_property(nombre, prototipo.get_property(nombre))
      end
    })
  end

  def initialize(prototipo, inicializador = nil, padre: nil)
    @prototype = prototipo
    @inicializador = inicializador || inicializador_por_defecto
    @padre = padre
  end

  def prototype
    @prototype
  end

  def new(*args)
    nuevo = PrototypedObject.new
    nuevo.set_prototype(prototype)
    sobrantes = inicializar(nuevo, args)
    raise ArgumentError, "sobran argumentos: #{sobrantes.inspect}" unless sobrantes.empty?
    nuevo
  end

  def extended(inicializador)
    PrototypedConstructor.new(prototype, inicializador, padre: self)
  end

  protected

  def inicializar(nuevo, args)
    args = @padre.inicializar(nuevo, args) if @padre
    aridad = @inicializador.arity - 1
    if args.size < aridad
      raise ArgumentError, "faltan argumentos: esperaba #{aridad}, llegaron #{args.size}"
    end
    @inicializador.call(nuevo, *args.take(aridad))
    args.drop(aridad)
  end

  private

  def inicializador_por_defecto
    proc { |nuevo, valores|
      valores.each do |nombre, valor|
        unless prototype.has_property?(nombre)
          raise ArgumentError, "el prototipo no tiene la propiedad #{nombre}"
        end
        nuevo.set_property(nombre, valor)
      end
    }
  end
end
```

### Los tests de esta pieza

```ruby
describe 'constructores' do
  let(:guerrero) { armar_guerrero }
  let(:constructor_guerrero) {
    PrototypedConstructor.new(guerrero, proc { |nuevo, una_energia, un_potencial_ofensivo, un_potencial_defensivo|
      nuevo.energia = una_energia
      nuevo.potencial_ofensivo = un_potencial_ofensivo
      nuevo.potencial_defensivo = un_potencial_defensivo
    })
  }

  it 'con un proc inicializa el estado y linkea al prototipo' do
    un_guerrero = constructor_guerrero.new(100, 30, 10)
    expect(un_guerrero.energia).to eq 100
    expect(un_guerrero.prototype).to be guerrero
    expect(un_guerrero.respond_to?(:atacar_a)).to be true
  end
  it 'cuenta los argumentos' do
    expect { constructor_guerrero.new(1, 2) }.to raise_error(ArgumentError)
    expect { constructor_guerrero.new(1, 2, 3, 4) }.to raise_error(ArgumentError)
  end
  it 'por defecto recibe un mapa y rechaza propiedades que el prototipo no tiene' do
    constructor = PrototypedConstructor.new(guerrero)
    un_guerrero = constructor.new({energia: 100, potencial_ofensivo: 30, potencial_defensivo: 10})
    expect(un_guerrero.potencial_ofensivo).to eq 30
    expect { constructor.new({sarasa: 1}) }.to raise_error(ArgumentError)
  end
  it 'copy copia el estado actual y mantiene el link' do
    constructor = PrototypedConstructor.copy(guerrero)
    copia = constructor.new
    expect(copia.potencial_defensivo).to eq 10
    copia.potencial_defensivo = 99
    expect(guerrero.potencial_defensivo).to eq 10
    guerrero.set_method(:sanar, proc { self.energia = self.energia + 10 })
    expect(copia.sanar).to eq 110
  end
  it 'extended consume los argumentos en orden, primero el padre' do
    constructor_espadachin = constructor_guerrero.extended(proc { |espadachin, habilidad, potencial_espada|
      espadachin.set_property(:habilidad, habilidad)
      espadachin.set_property(:potencial_espada, potencial_espada)
      espadachin.set_method(:potencial_ofensivo, proc {
        get_property(:potencial_ofensivo) + self.potencial_espada * self.habilidad
      })
    })
    espadachin = constructor_espadachin.new(100, 30, 10, 0.5, 30)
    expect(espadachin.potencial_ofensivo).to eq 45
    expect(espadachin.prototype).to be guerrero
    expect { constructor_espadachin.new(100, 30, 10, 0.5) }.to raise_error(ArgumentError)
  end
  it 'extended sobre el constructor por defecto: el mapa va primero' do
    constructor = PrototypedConstructor.new(guerrero).extended(proc { |e, habilidad, potencial_espada|
      e.habilidad = habilidad
      e.potencial_espada = potencial_espada
    })
    espadachin = constructor.new({energia: 100, potencial_ofensivo: 30, potencial_defensivo: 10}, 0.5, 30)
    expect(espadachin.habilidad).to eq 0.5
    expect(espadachin.potencial_ofensivo).to eq 30
  end
end
```

(`let(:nombre) { … }` define un valor que cada test obtiene fresco al nombrarlo; es la forma de RSpec de no repetir el armado en cada `it`.)

---

## Checkpoint del Módulo 7

1. ¿Qué es un `PrototypedConstructor` y por qué se guarda en una constante con mayúscula si no es una clase?
2. `Guerrero.new(100, 30, 10)`: ¿de quién es ese `new`, y qué cuatro pasos hace?
3. ¿Por qué el inicializador recibe el objeto nuevo como **primer** parámetro?
4. Un proc llamado con menos argumentos no falla. ¿Qué consecuencia tiene eso para `Guerrero.new(1, 2)` y en qué sección se corrige?
5. ¿Por qué el constructor por defecto usa un mapa y no argumentos en orden? ¿Contra qué verifica cada nombre, y con qué mensaje?
6. ¿Qué mensaje nuevo necesitó `Prototyped` para que exista `copy`? ¿Por qué con variables de instancia hubiera sido difícil?
7. `copy` y `clone` parten del mismo estado. ¿En qué se diferencia el objeto que produce cada uno?
8. Explicá "los parámetros se consumen en orden" con `Espadachin.new(100, 30, 10, 0.5, 30)`: quién toma cuáles y cómo lo sabe.
9. ¿Qué significa `arity` igual a `-2`, y por qué el constructor no lo soporta?
10. ¿Por qué `inicializar` es `protected` y no `private`? ¿Quién le manda ese mensaje a quién?

## Qué viene en el Módulo 8

La parte 4.3: el azúcar sintáctico completo. `guerrero_proto.atacar_a = proc { … }` para definir métodos con `=`; `PrototypedObject.new { self.energia = 100 … }`; constructores con bloque en vez de proc; `PrototypedConstructor.create { … }.with { … }` y `.with_properties([…])`; y el `prototype` de un constructor, que trae el test que **rompe** la decisión del Módulo 5 de guardar el getter como un método más. Vas a ver por qué se rompe y cómo se corrige con una línea en `method_missing`.

**FIN DEL MÓDULO 7**
