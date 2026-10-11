# Clase desde cero — Prototype — Módulo 5: `set_prototype`

**Unidad:** clase06 · **Módulo:** 5 de 9 (+1 opcional) · **Densidad:** 🔴 · **Parte del enunciado:** 4.1, segundo bloque hasta `expect(espadachin.potencial_ofensivo).to eq(45)`

## Sobre este documento

**Qué cubre:** `espadachin.set_prototype(guerrero)`, el corazón del ejercicio. Se construye viendo primero **qué dos caminos hay** para que el espadachín use los métodos del guerrero (copiarlos al linkear, o buscarlos en cada envío), por qué copiar no cumple el enunciado, por qué con los métodos en la autoclase **no hay dónde enganchar** la búsqueda, y cómo la "otra forma" del Módulo 3 pasa a ser la forma: diccionario de métodos, `method_missing`, `instance_exec` y una cadena de prototipos. Al final del módulo, todo el segundo bloque de 4.1 anda, salvo una línea.

**Qué NO cubre:** esa línea, `espadachin.energia = 100`, es un setter y es el Módulo 6; acá se escribe `set_property(:energia, 100)` en su lugar. Tampoco `include Prototyped` (Módulo 6). Deja **abiertos a propósito** dos hilos: el `@potencial_ofensivo` que el enunciado escribe (sección 7) y que un objeto tiene un solo prototipo (Módulo 9).

**Tené el enunciado a mano**, en la parte 4.1, desde "Lo interesante viene ahora" hasta `expect(espadachin.potencial_ofensivo).to eq(45)`.

## De dónde venís

Del Módulo 3: `set_method` con `define_singleton_method`; la "otra forma" (diccionario de procs + `method_missing` + `instance_exec` + `respond_to_missing?`), escrita y en espera; y el hueco: con la autoclase, el lookup lo hace Ruby y no hay gancho.
Del Módulo 4: `clone` copia y se desentiende; `initialize_copy` copia el diccionario de propiedades.
De clase02: cuando varios módulos aportan métodos a una clase, Ruby los **linealiza**: arma una lista ordenada y busca en orden. Ese orden es lo que decide conflictos.
De clase03: un método de la autoclase de un objeto está atado a ese objeto; `bind` lo rechaza para cualquier otro (`TypeError`).

---

## 1. 🔴 Qué pide el segundo bloque

> 📄 **El enunciado dice** (4.1, "Lo interesante viene ahora"):
> ```ruby
> espadachin = PrototypedObject.new
>
> espadachin.set_prototype(guerrero)
>
> espadachin.set_property(:habilidad, 0.5)
> espadachin.set_property(:potencial_espada, 30)
>
> espadachin.energia = 100
>
> {...} #mas inicializaciones
> #deberia llamar a super, pero eso lo resolvemos mas adelante
> espadachin.set_method(:potencial_ofensivo, proc {
>   @potencial_ofensivo + self.potencial_espada * self.habilidad
> })
>
> espadachin.atacar_a(otro_guerrero)
> expect(otro_guerrero.energia).to eq(75)
> ```

**En criollo, línea por línea:**

- `set_prototype(guerrero)`: el espadachín queda **linkeado** a guerrero. No copia nada. A partir de acá, lo que el espadachín no tenga, lo va a buscar a guerrero.
- `set_property(:habilidad, 0.5)` y `(:potencial_espada, 30)`: propiedades propias del espadachín, que guerrero no tiene.
- `espadachin.energia = 100`: un **setter**. Es azúcar sintáctico y necesita una pieza que todavía no existe. En este módulo se escribe `espadachin.set_property(:energia, 100)`; el Módulo 6 hace que la línea original ande.
- `{...} #mas inicializaciones`: el enunciado te deja a vos setear lo que falte. Falta `potencial_defensivo` y `potencial_ofensivo`, porque (sección 6) **el prototipo provee métodos y no estado**: el espadachín hereda el *getter* `potencial_ofensivo` de guerrero, pero no el valor 30. Hay que dárselo.
- `#deberia llamar a super`: el espadachín redefine `potencial_ofensivo` y quiere usar "la versión de guerrero" adentro. No hay `super` para prototipos; el enunciado lo resuelve en 4.4 (`call_next`, Módulo 9). Mientras tanto, usa `@potencial_ofensivo` para leer el valor de abajo. Ese `@` no anda con nuestro diccionario; la sección 7 lo explica y da el reemplazo.
- `atacar_a(otro_guerrero)`: el espadachín **no definió** `atacar_a`. Lo busca en guerrero. Y adentro, `self.potencial_ofensivo` tiene que ser **el del espadachín** (45 = 30 + 30 × 0,5), no el de guerrero.
- `expect(otro_guerrero.energia).to eq(75)`: una errata del enunciado. `otro_guerrero` viene del bloque anterior con 80; un ataque de 45 contra defensa 10 le saca 35 y lo deja en **45**. Para que diera 75 el espadachín tendría que atacar con 15, y tres líneas más abajo el mismo enunciado dice que `espadachin.potencial_ofensivo` es 45. El test de este módulo espera 45.

Y después del bloque, tres requerimientos más, con sus `expect`:

> 📄 **El enunciado dice** (4.1, después del bloque):
> *"Es decir, cualquier cambio en el prototipo impacta también en los objetos derivados de él. Cabe aclarar que el prototipo provee métodos y no estado."*
> *"Tampoco son afectados los métodos que fueron redefinidos por el objeto derivado:"*

**En criollo:** (a) si guerrero aprende `sanar` **después** del link, el espadachín lo entiende; (b) lo que se comparte es comportamiento, no valores; (c) si guerrero cambia `potencial_ofensivo` a 1000, el espadachín sigue dando 45, porque tiene el suyo. Las tres cosas van a salir del mismo mecanismo.

---

## 2. 🔴 Paso 0: guardar el prototipo

> **Regla.** `set_prototype` guarda una referencia al prototipo en el objeto. Solo eso. Lo que hace que el link sirva es lo que pasa **cuando llega un mensaje**, y eso todavía no existe.

```ruby
class PrototypedObject
  def set_prototype(prototipo)
    @__prototype__ = prototipo     # una variable más, con el mismo doble guión bajo que las otras
  end

  def prototype
    @__prototype__                 # nil si nunca se seteó
  end
end

guerrero   = armar_guerrero        # el de Módulo 3
espadachin = PrototypedObject.new
espadachin.set_prototype(guerrero)

espadachin.prototype.equal?(guerrero)   # => true
espadachin.atacar_a(guerrero)           # => NoMethodError: undefined method `atacar_a' for an instance of PrototypedObject
#                                          el link existe; nadie lo usa
```

Atila tiene `atacar_a` en su autoclase. Jack, prototipado de Atila, no tiene nada en la suya. Cuando Jack recibe `atacar_a`, el lookup de Ruby mira la autoclase de Jack, `PrototypedObject`, `Object`… y explota. **Nunca mira a Atila**, porque Atila no está en la cadena de clases de Jack. Es el hueco del Módulo 1, ahora con nombre.

---

## 3. 🔴 Paso 1: los dos únicos caminos

> **Regla.** Para que Jack tenga disponibles los métodos de Atila hay exactamente dos maneras: **aplanar** (al momento de linkear, copiar los métodos de Atila a Jack y mantener esa copia al día) o **linealizar** (en cada envío, buscar en Jack y, si no está, seguir buscando en Atila). El comportamiento tiene que estar en algún lado o tiene que haber un proceso que lo encuentre; no hay magia.

Son las mismas dos ideas de los mixins de clase02: un resultado de búsqueda **precalculado** que hay que mantener, o un **proceso de búsqueda** que se ejecuta cada vez.

### Aplanar: copiar al linkear

La idea es tentadora porque la copia es inmediata: "agarro los métodos de Atila y los pego en Jack". Dos problemas la descartan.

**Primero, no cumple el enunciado.** Si guerrero aprende `sanar` después del link, Jack tiene una copia vieja, sin `sanar`. Para que Jack se entere, Atila tendría que **avisarle** a cada uno de sus derivados cada vez que cambia: guardar una lista de derivados, recorrerla en cada `set_method`. Eso trae dos costos más: cada prototipo retiene a sus derivados para siempre (una pérdida de memoria, salvo que se usen referencias débiles), y hay que atrapar **toda** forma de cambiar un objeto. Si alguien le define un método a Atila por la autoclase, sin pasar por `set_method`, Ruby no da ningún gancho para enterarse.

**Segundo, Ruby no deja copiar métodos de una autoclase a otra.** Es la regla de `bind` de clase03, y acá muerde:

```ruby
espadachin.define_singleton_method(:atacar_a, guerrero.method(:atacar_a))
# => TypeError: can't bind singleton method to a different class

guerrero.method(:atacar_a).unbind.bind(espadachin)
# => TypeError: singleton method called for a different object

guerrero.singleton_class.instance_method(:atacar_a).bind(espadachin)
# => TypeError: singleton method called for a different object
```

Un método de la autoclase de Atila **es de Atila**. No hay forma de "transplantarlo". Lo único que se puede hacer con él es ejecutarlo **sobre Atila**:

```ruby
# delegar: que Atila ejecute atacar_a en lugar de Jack
espadachin.set_property(:potencial_ofensivo, 20)       # Jack tiene SU potencial
otro = armar_guerrero
guerrero.send(:atacar_a, otro)                         # lo ejecuta guerrero, con self = guerrero
otro.energia                                           # => 80     ← usó el 30 de Atila, no el 20 de Jack
```

Eso es **delegar**, y no es prototipar: `self` adentro del método fue Atila. El espadachín del enunciado ataca con *su* potencial (45), usando el *método* de guerrero. Para eso el cuerpo del método tiene que poder ejecutarse con `self = espadachin`, y un método de autoclase no puede.

> 💎 **Otra forma de hacerlo.** Avisar a los derivados (el "observer" del párrafo anterior) es una implementación válida de aplanar, y algunos lenguajes de prototipos la usan. Se descarta acá por la pérdida de memoria y porque Ruby no ofrece un gancho para detectar cambios en una autoclase.

### Linealizar: buscar en cada envío

> **Regla.** Cuando Jack recibe un mensaje que no tiene, **alguien** tiene que decir "no está acá, fijate en Atila". Con los métodos en la autoclase, ese alguien es el lookup de Ruby, y el lookup de Ruby no se puede modificar. El único punto al que Ruby llega diciendo "no encontré nada" es `method_missing`.

Esto cierra el hilo H2 del Módulo 3. Mientras `set_method` haga `define_singleton_method`, el método es "un método más de Ruby": lo encuentra Ruby, lo ejecuta Ruby, y nosotros no participamos. No hay un momento en el que podamos colarnos para mirar a Atila. Cuando el lookup falla, Ruby manda `method_missing`; **ahí sí estamos nosotros**.

Y una vez que estamos en `method_missing` buscando el método en Atila, aparece el segundo problema otra vez: lo que encontramos en Atila es un método de autoclase, que no se puede ejecutar con `self = Jack`. Para que se pueda, lo que guardamos tiene que ser **un proc**, que no está atado a nadie y se ejecuta con el `self` que uno elija (`instance_exec`).

**Conclusión:** la "otra forma" del Módulo 3 no era una alternativa peor; era la única que soporta prototipos. Guardar procs en un diccionario y atraparlos en `method_missing` cuesta lo que ya sabés (reflexión a mano, `instance_exec`, `super`), y a cambio da el gancho y el proc desatado. Si al final hay que ir a `method_missing`, conviene ir de entrada y no tener dos mecanismos conviviendo.

> 🎯 **Para el parcial, si te preguntan** por qué los métodos de un objeto prototipado no pueden vivir en su autoclase:
> Por dos razones. Primero, con los métodos en la autoclase el lookup lo resuelve Ruby de punta a punta y no ofrece ningún gancho para buscar en otro objeto antes de fallar; el único gancho es `method_missing`, que solo se alcanza si el método **no** está definido. Segundo, un método de autoclase está atado a su objeto: `bind` lo rechaza para cualquier otro, así que no se puede ejecutar con `self` igual al derivado. Guardar procs y ejecutarlos con `instance_exec` resuelve las dos cosas.

---

## 4. 🔴 Paso 2: la migración

> **Regla.** `set_method` guarda el proc en un diccionario propio del objeto (`@__methods__`). `method_missing` busca el proc por selector, primero en el objeto y después en su prototipo, y lo ejecuta con `instance_exec` sobre el receptor. `respond_to_missing?` usa la misma búsqueda. El getter de cada propiedad pasa a ser un método más de ese diccionario.

Primero `set_method` y el getter:

```ruby
class PrototypedObject
  def set_property(nombre, valor)
    set_method(nombre, proc { get_property(nombre) })   # el getter, ahora por el mismo camino que todo método
    propiedades[nombre] = valor
  end

  def set_method(selector, bloque)
    metodos[selector] = bloque                           # solo guarda; no define nada en ninguna clase
  end

  private

  def metodos
    @__methods__ ||= {}                                  # segundo diccionario: selector → proc
  end
end
```

**Por qué el getter también va al diccionario.** Ahora hay un mecanismo para "lo que este objeto sabe hacer", y el getter es una de esas cosas. Tenerlo en la autoclase y el resto en el diccionario serían dos mecanismos para lo mismo, con dos lookups distintos. Además, **`set_method` es el `define_method` de nuestro framework**: la interfaz que armamos para el usuario también la podemos usar nosotros. (Esta decisión tiene una pata corta que aparece en el Módulo 8; se toma igual porque la alternativa recién tiene sentido ahí.)

Después, la búsqueda. Un método propio para no repetir la lógica en dos lugares:

```ruby
class PrototypedObject
  def find_method(selector)              # el lookup PROPIO: ¿lo tengo yo? ¿lo tiene mi prototipo?
    if metodos.key?(selector)
      metodos[selector]                  # lo tengo: el proc
    elsif prototype
      prototype.find_method(selector)    # no lo tengo: que lo busque mi prototipo (y él en el suyo, y así)
    end                                  # sin prototipo: el if devuelve nil → nadie lo tiene
  end
end
```

`# también: metodos[selector] || prototype&.find_method(selector)`, donde `&.` manda el mensaje solo si el receptor no es `nil`.

Es una **cadena**: Jack pregunta a Atila; si Atila tuviera prototipo, le preguntaría al suyo; termina en el primero que no tiene prototipo. Es la linealización, hecha a mano: una lista implícita (yo, mi prototipo, el de él…) recorrida en orden.

Y por último, el gancho:

```ruby
class PrototypedObject
  private

  def method_missing(selector, *args)
    bloque = find_method(selector)
    if bloque
      instance_exec(*args, &bloque)     # ejecutar el proc con self = el receptor (yo, no quien lo definió)
    else
      super                             # nadie lo tiene: NoMethodError normal
    end
  end

  def respond_to_missing?(selector, include_private = false)
    !find_method(selector).nil? || super     # el MISMO criterio: ¿alguien en la cadena lo tiene?
  end
end
```

```
# ¿CÓMO FUNCIONA?  espadachin.atacar_a(otro_guerrero)      (espadachin.prototype == guerrero)
# 1. lookup de Ruby: autoclase de espadachin (vacía), PrototypedObject, Object… → no está
# 2. Ruby manda espadachin.method_missing(:atacar_a, otro_guerrero)
# 3. find_method(:atacar_a): espadachin.metodos no lo tiene → guerrero.find_method(:atacar_a)
#    → guerrero.metodos SÍ lo tiene → devuelve el proc
# 4. espadachin.instance_exec(otro_guerrero, &proc) → el cuerpo corre con self = ESPADACHIN
# 5. adentro: self.potencial_ofensivo → otro method_missing → find_method en espadachin → su getter → 45
#    otro_guerrero.recibe_danio(35) → method_missing en otro_guerrero → su propio proc → energía 80 - 35 = 45
```

### Lo que cambió, visto desde afuera

```ruby
guerrero = armar_guerrero
guerrero.singleton_methods       # => []        ← ya nada en la autoclase
guerrero.methods(false)          # => []
guerrero.respond_to?(:atacar_a)  # => true      ← gracias a respond_to_missing?
guerrero.method(:atacar_a).class # => Method    ← también
```

El primer bloque del enunciado sigue andando igual (el test de `clone` del Módulo 4 pasa). Lo que cambió es **dónde** vive lo mismo.

---

## 5. 🔴 Paso 3: los tres requerimientos, uno por uno

> **Regla.** Con la búsqueda en cadena, los tres `expect` del enunciado salen del mismo mecanismo: lo que está en el derivado gana; lo que no está se busca en el prototipo **en el momento del envío**, así que cualquier cambio posterior en el prototipo se ve.

```ruby
guerrero      = armar_guerrero
otro_guerrero = guerrero.clone
guerrero.atacar_a otro_guerrero                      # otro_guerrero: 80 (bloque 1)

espadachin = PrototypedObject.new
espadachin.set_prototype(guerrero)
espadachin.set_property(:habilidad, 0.5)
espadachin.set_property(:potencial_espada, 30)
espadachin.set_property(:energia, 100)               # en lugar de espadachin.energia = 100 (Módulo 6)
espadachin.set_property(:potencial_defensivo, 10)    # las "más inicializaciones"
espadachin.set_property(:potencial_ofensivo, 30)

espadachin.set_method(:potencial_ofensivo, proc {
  get_property(:potencial_ofensivo) + self.potencial_espada * self.habilidad   # en lugar de @potencial_ofensivo (sección 7)
})
espadachin.potencial_ofensivo          # => 45.0        ← 30 + 30 × 0.5 (Float; eq(45) lo acepta)

espadachin.atacar_a(otro_guerrero)     # el método es de guerrero; self es espadachin
otro_guerrero.energia                  # => 45.0        ← 80 − (45 − 10). El enunciado dice 75: errata.
```

**(a) Un cambio en el prototipo llega al derivado:**

```ruby
guerrero.set_method(:sanar, proc { set_property(:energia, self.energia + 10) })   # DESPUÉS del link
espadachin.sanar
espadachin.energia                     # => 110         ← espadachin no define sanar; lo encontró en guerrero
guerrero.energia                       # => 100         ← y se ejecutó sobre espadachin, no sobre guerrero
```

**(b) El clon no lo ve** (del Módulo 4, y sigue valiendo):

```ruby
otro_guerrero.sanar                    # => NoMethodError: undefined method `sanar' for an instance of PrototypedObject
```

**(c) Lo redefinido en el derivado no se pisa:**

```ruby
guerrero.set_method(:potencial_ofensivo, proc { 1000 })
guerrero.potencial_ofensivo            # => 1000
espadachin.potencial_ofensivo          # => 45.0        ← find_method lo encuentra PRIMERO en espadachin
```

La diferencia entera entre clonar y prototipar, en dos líneas: **el clon tiene su propia copia del diccionario de métodos, hecha al clonar; el derivado no tiene copia, tiene un link, y pregunta cada vez.** Por eso `sanar` llega a uno y no al otro.

### ⚠️ Trampa: `clone` después de la migración

> **Regla.** Al mover los métodos a un diccionario, `clone` vuelve a compartir: `initialize_copy` tiene que copiar **también** `@__methods__`. Si no, el clon ve los métodos nuevos del original, y el requerimiento (b) se rompe en silencio.

```ruby
# con initialize_copy copiando SOLO @__properties__ (la versión del Módulo 4):
atila = armar_guerrero
jack  = atila.clone
atila.set_method(:sanar, proc { set_property(:energia, energia + 10) })
jack.sanar                                   # anda: ⚠️ no debería
jack.respond_to?(:sanar)                     # => true
jack.instance_variable_get(:@__methods__).equal?(atila.instance_variable_get(:@__methods__))   # => true
```

Es el mismo bug de Atila y Jack del Módulo 4, con el otro diccionario. Antes no pasaba porque los métodos estaban en la autoclase, y `clone` copia la autoclase. Ahora están en un Hash, y `clone` copia la referencia. La corrección es una línea:

```ruby
class PrototypedObject
  def initialize_copy(original)
    super
    @__properties__ = @__properties__.dup if @__properties__
    @__methods__    = @__methods__.dup    if @__methods__     # ← los métodos también son estado del objeto, ahora
  end
end
```

El link al prototipo (`@__prototype__`) **no** se copia como diccionario: es una referencia al mismo objeto, y eso es lo que queremos. Un clon de espadachín sigue prototipado de guerrero.

> 🛠️ **Lo que te va a marcar el editor:** al borrar la línea de `define_singleton_method`, RubyMine ya no reconoce `atacar_a` ni `energia` como métodos en ningún lado; "Go to declaration" deja de funcionar sobre ellos. Es el precio de `method_missing` que viste en el Módulo 3.

---

## 6. 🔴 El prototipo provee métodos, no estado

> **Regla.** La cadena busca **métodos**. Las propiedades viven en el diccionario de cada objeto y no se heredan. Un derivado entiende el getter de una propiedad del prototipo, pero el valor que ese getter lee es el del diccionario **del derivado**.

Es la frase del enunciado ("el prototipo provee métodos y no estado"), y con nuestra implementación sale sola, con una consecuencia que conviene ver:

```ruby
guerrero.set_property(:fuerza, 7)
guerrero.fuerza                        # => 7
espadachin.respond_to?(:fuerza)        # => true      ← el GETTER está (es un método de guerrero)
espadachin.has_property?(:fuerza)      # => false     ← el VALOR no (el diccionario de espadachin no lo tiene)
espadachin.fuerza                      # => nil       ← el getter corre con self = espadachin y lee SU diccionario
```

Por eso el enunciado tiene las "más inicializaciones": el espadachín responde `potencial_ofensivo` desde el primer momento (hereda el getter), pero devuelve `nil` hasta que le seteás el suyo. Es coherente con el modelo: Juan es un alumno concreto con *su* nombre; Martín, derivado de Juan, sabe *cómo* decir el nombre, pero tiene que tener *el suyo*.

**Cadenas más largas** funcionan sin tocar nada:

```ruby
nieto = PrototypedObject.new
nieto.set_prototype(espadachin)        # nieto → espadachin → guerrero
nieto.set_property(:energia, 5)
nieto.sanar                            # sanar está en guerrero, dos saltos más arriba
nieto.energia                          # => 15
```

⚠️ **Trampa: un ciclo cuelga.** Si `a.set_prototype(b)` y `b.set_prototype(a)`, un mensaje que ninguno tiene recorre la cadena sin fin: `SystemStackError: stack level too deep`. El enunciado pide en 4.4 que los prototipos no se afecten entre sí; con un solo prototipo alcanza con no hacerlo, y el Módulo 9 lo protege para el caso general.

---

## 7. 🔴 El `@potencial_ofensivo` del enunciado

> **Regla.** El enunciado escribe `@potencial_ofensivo` para decir "el valor de la propiedad que este método está tapando". Con las propiedades en un diccionario, esa variable de instancia **no existe**: el valor se lee con `get_property(:potencial_ofensivo)`.

```ruby
espadachin.set_method(:potencial_ofensivo, proc {
  @potencial_ofensivo + self.potencial_espada * self.habilidad     # verbatim del enunciado
})
espadachin.potencial_ofensivo
# => NoMethodError: undefined method `+' for nil
#    @potencial_ofensivo es nil: nadie seteó esa variable; el 30 está en @__properties__

espadachin.instance_variables          # => [:@__prototype__, :@__methods__, :@__properties__]
```

Es consecuencia directa de la decisión del Módulo 2. El enunciado fue escrito pensando en una implementación donde cada propiedad es una variable de instancia (la opción A del Módulo 2), y ahí `@potencial_ofensivo` vale 30. Con el diccionario, la forma de pedir "la propiedad, no el método" es `get_property`. Lo que el enunciado quiere decir se conserva; cambia cómo se escribe:

| El enunciado escribe | Con diccionario se escribe | Por qué |
|---|---|---|
| `@potencial_ofensivo` | `get_property(:potencial_ofensivo)` | el valor está en el diccionario, no en una variable |
| `self.potencial_ofensivo` | `self.potencial_ofensivo` | el método, por la cadena; igual en las dos |

Fijate que `self.potencial_ofensivo` adentro del propio `potencial_ofensivo` sería recursión infinita: el método se llamaría a sí mismo. Por eso el enunciado necesita una forma de "saltear" el método propio y llegar al valor, y por eso dice que "debería llamar a super". Ese `super` para prototipos existe en 4.4 con el nombre `call_next`, y reemplaza tanto al `@` como al `get_property`. Queda sembrado para el Módulo 9.

> 💎 **Otra forma de hacerlo.** Con propiedades en variables de instancia (`instance_variable_set("@#{nombre}", valor)`), el `@potencial_ofensivo` del enunciado anda tal cual, y el getter sería `instance_variable_get`. El trade-off es el del Módulo 2: se pierde la distinción entre propiedad y variable, que el Módulo 7 va a necesitar para copiar "el estado del prototipo".

---

## 8. 🔴 Las piezas armadas

El framework al final de este módulo. `set_method` cambió de lugar; `set_property`, `initialize_copy` y la parte privada crecieron; lo demás es igual.

```ruby
class PrototypedObject
  def set_property(nombre, valor)
    set_method(nombre, proc { get_property(nombre) })   # el getter es un método más
    propiedades[nombre] = valor
  end

  def get_property(nombre)
    propiedades[nombre]
  end

  def has_property?(nombre)
    propiedades.key?(nombre)
  end

  def set_method(selector, bloque)
    metodos[selector] = bloque                           # guarda el proc; no define nada
  end

  def set_prototype(prototipo)
    @__prototype__ = prototipo
  end

  def prototype
    @__prototype__
  end

  def find_method(selector)                              # el lookup propio, en cadena
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
      instance_exec(*args, &bloque)                      # self = el receptor
    else
      super
    end
  end

  def respond_to_missing?(selector, include_private = false)
    !find_method(selector).nil? || super
  end

  def propiedades
    @__properties__ ||= {}
  end

  def metodos
    @__methods__ ||= {}
  end
end
```

### Los tests de esta pieza

```ruby
def armar_espadachin(guerrero)
  espadachin = PrototypedObject.new
  espadachin.set_prototype(guerrero)
  espadachin.set_property(:habilidad, 0.5)
  espadachin.set_property(:potencial_espada, 30)
  espadachin.set_property(:energia, 100)
  espadachin.set_property(:potencial_defensivo, 10)
  espadachin.set_property(:potencial_ofensivo, 30)
  espadachin.set_method(:potencial_ofensivo, proc {
    get_property(:potencial_ofensivo) + self.potencial_espada * self.habilidad
  })
  espadachin
end

describe 'set_prototype' do
  it 'el derivado usa los métodos del prototipo con self = derivado' do
    guerrero = armar_guerrero
    otro_guerrero = guerrero.clone
    guerrero.atacar_a otro_guerrero
    espadachin = armar_espadachin(guerrero)
    expect(espadachin.potencial_ofensivo).to eq 45
    espadachin.atacar_a(otro_guerrero)
    expect(otro_guerrero.energia).to eq 45          # el enunciado dice 75: errata
  end
  it 'un cambio en el prototipo impacta en el derivado' do
    guerrero = armar_guerrero
    espadachin = armar_espadachin(guerrero)
    guerrero.set_method(:sanar, proc { set_property(:energia, self.energia + 10) })
    espadachin.sanar
    expect(espadachin.energia).to eq 110
    expect(guerrero.energia).to eq 100
  end
  it 'el clon sigue sin ver los cambios' do
    guerrero = armar_guerrero
    otro_guerrero = guerrero.clone
    guerrero.set_method(:sanar, proc { set_property(:energia, self.energia + 10) })
    expect { otro_guerrero.sanar }.to raise_error(NoMethodError)
  end
  it 'lo redefinido en el derivado no se pisa' do
    guerrero = armar_guerrero
    espadachin = armar_espadachin(guerrero)
    guerrero.set_method(:potencial_ofensivo, proc { 1000 })
    expect(guerrero.potencial_ofensivo).to eq 1000
    expect(espadachin.potencial_ofensivo).to eq 45
  end
  it 'el prototipo provee métodos y no estado' do
    guerrero = armar_guerrero
    espadachin = PrototypedObject.new
    espadachin.set_prototype(guerrero)
    expect(espadachin.respond_to?(:energia)).to be true     # hereda el getter (cambia en el Módulo 8)
    expect(espadachin.has_property?(:energia)).to be false
    expect(espadachin.energia).to be nil
  end
  it 'la cadena puede tener más de un salto' do
    guerrero = armar_guerrero
    espadachin = armar_espadachin(guerrero)
    nieto = PrototypedObject.new
    nieto.set_prototype(espadachin)
    expect(nieto.respond_to?(:atacar_a)).to be true
  end
  it 'un mensaje que nadie tiene falla como siempre' do
    espadachin = armar_espadachin(armar_guerrero)
    expect { espadachin.volar }.to raise_error(NoMethodError)
    expect(espadachin.respond_to?(:volar)).to be false
  end
end
```

---

## Checkpoint del Módulo 5

1. ¿Qué hace `set_prototype` y por qué, con solo eso, `espadachin.atacar_a` sigue explotando? Describí el lookup de Ruby para ese mensaje.
2. ¿Cuáles son las dos únicas maneras de que un derivado tenga disponibles los métodos de su prototipo? ¿Con qué dos palabras de clase02 se corresponden?
3. Dá dos razones por las que "copiar los métodos al linkear" no sirve. ¿Cuál de las dos es del enunciado y cuál es de Ruby?
4. `guerrero.send(:atacar_a, otro)` desde el espadachín anda y no es lo que queremos. ¿Por qué? ¿Quién fue `self`?
5. ¿Por qué `method_missing` es el único gancho posible? ¿Qué pasa con ese gancho si el método **sí** está definido en la autoclase?
6. ¿Por qué lo guardado tiene que ser un proc y no un método? ¿Qué mensaje lo ejecuta con el `self` correcto?
7. Escribí `find_method` de memoria y explicá qué devuelve cuando nadie en la cadena tiene el selector.
8. Seguí el flujo de `espadachin.atacar_a(otro_guerrero)` paso por paso, incluyendo los `method_missing` anidados.
9. Después de la migración, `jack = atila.clone` vuelve a compartir algo. ¿Qué, por qué, y cuál es la corrección?
10. `espadachin.respond_to?(:fuerza)` da `true` y `espadachin.fuerza` da `nil`. Explicá las dos con la frase del enunciado.
11. ¿Por qué `@potencial_ofensivo` vale `nil` en nuestro framework, y qué se escribe en su lugar? ¿Qué pieza de 4.4 va a reemplazar a las dos formas?

## Qué viene en el Módulo 6

La línea que quedó pendiente, `espadachin.energia = 100`, y la última de 4.1, `class Object; include Prototyped; end`. Vas a ver que un setter sobre una propiedad que nadie declaró **solo** puede resolverse con `method_missing` (y por qué es la única vez en todo el ejercicio que no hay dos caminos sino uno), cómo distinguir un setter de un método por el nombre, y qué pasa cuando le metés todo esto a `Object`: cada número, cada string y `nil` pasan a ser prototipables, y dos de ellos te explotan en la cara.

**FIN DEL MÓDULO 5**
