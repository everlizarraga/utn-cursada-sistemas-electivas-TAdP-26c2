# Clase desde cero — Prototype — Módulo 3: Métodos

**Unidad:** clase06 · **Módulo:** 3 de 9 (+1 opcional) · **Densidad:** 🔴 · **Parte del enunciado:** 4.1, `set_method`

## Sobre este documento

**Qué cubre:** `set_method`: guardar en un objeto un método cuyo nombre y cuyo cuerpo (un proc) llegan en ejecución. Se construye viendo primero a quién **no** se le puede mandar `define_method` y por qué, después la forma que anda (`define_singleton_method`), por qué `self` queda bien sin hacer nada, y al final **la otra forma** (un diccionario de procs y `method_missing`), escrita completa, con lo que hay que arreglarle a mano y las razones para dejarla en espera. Al final del módulo, `atacar_a` y `recibe_danio` del enunciado andan entre dos guerreros armados a mano.

**Qué NO cubre:** `clone` (Módulo 4): el enunciado usa `guerrero.clone` para tener al segundo guerrero, y acá todavía no existe. Este módulo deja **abierta a propósito** la pregunta de la sección 6: con los métodos en la autoclase, ¿dónde se engancha una búsqueda en otro objeto?

**Tené el enunciado a mano**, en la parte 4.1, el bloque de `set_method(:atacar_a, …)`.

## De dónde venís

Del Módulo 1: `set_method` recibe un **proc como argumento**, no un bloque. Dentro del proc de `atacar_a` aparece `self.potencial_ofensivo`: `self` tiene que ser el guerrero que recibió el mensaje.
Del Módulo 2: el diccionario de propiedades con inicialización perezosa; `define_singleton_method` para un método de un solo objeto; los dos únicos caminos para responder un mensaje.
De clase03: `define_method` lo entienden las clases y los módulos (los proveedores de comportamiento), no las instancias; un método se busca primero en la autoclase y después en la clase.
De clase04: un proc recuerda el `self` del lugar donde fue escrito; `instance_exec(*args, &proc)` lo ejecuta con otro `self` y le pasa argumentos; `method_missing` y `respond_to_missing?` van juntos.

---

## 1. 🔴 Qué pide `set_method`

> 📄 **El enunciado dice** (4.1, primer bloque):
> ```ruby
> guerrero.set_method(:atacar_a,
>   proc {
>   |otro_guerrero|
>   if(otro_guerrero.potencial_defensivo < self.potencial_ofensivo)
>     otro_guerrero.recibe_danio(self.potencial_ofensivo - otro_guerrero.potencial_defensivo)
>   end
>   });
>
> guerrero.set_method(:recibe_danio, proc {...})
> ```

**En criollo:** `set_method` recibe un **selector** (el nombre del mensaje, como símbolo) y un **proc** con el cuerpo. Después de eso, **ese guerrero, y solo ese**, entiende `atacar_a` con un argumento, y adentro del cuerpo `self` es el guerrero. El `recibe_danio` lo escribís vos: le resta a `energia` el daño que recibe. (El `);` suelto al final del proc es una errata del enunciado; el proc cierra con `}` y el paréntesis de `set_method` con `)`.)

```ruby
guerrero.set_method(:descansar, proc { 1 })
# => NoMethodError: undefined method `set_method' for #<PrototypedObject:0x…>     (hoy)
```

---

## 2. 🔴 Paso 0: a quién le mandás `define_method`

> **Regla.** `define_method` lo entienden los **proveedores de comportamiento**: clases y módulos. Una instancia de `PrototypedObject` no lo entiende, porque en el modelo de Ruby no provee comportamiento. Para definirle un método a un objeto hay que mandárselo a una clase: la suya, o **su autoclase**.

Primer intento, el obvio: dentro de `set_method`, `self` es el guerrero, así que `define_method` directo.

```ruby
class PrototypedObject
  def set_method(selector, bloque)
    define_method(selector, &bloque)   # ⚠️ self es la instancia: no entiende define_method
  end
end

guerrero.set_method(:descansar, proc { 1 })
# => NoMethodError: undefined method `define_method' for #<PrototypedObject:0x…>
```

Dentro de nuestro modelo de prototipos, el guerrero sí es un proveedor de comportamiento. Pero ahora estamos adentro de Ruby, y para Ruby es una instancia. Hay dos clases a mano: la clase del guerrero y su autoclase.

| Escribís | Ruby entiende | Sale |
|---|---|---|
| `define_method(selector, &bloque)` | se lo mandás a la instancia | `NoMethodError: undefined method 'define_method'` |
| `self.class.send(:define_method, selector, &bloque)` | lo definís en `PrototypedObject` | anda… y **todas** las instancias entienden `descansar` |
| `define_singleton_method(selector, &bloque)` | lo definís en la **autoclase** del guerrero | anda, y **solo** este guerrero lo entiende |

La segunda fila es un error de diseño, no de Ruby: `set_method` es para **este** prototipo, como `set_property` era para este objeto y no para todos. Cada método es propio de la instancia puntual. Va a la autoclase.

---

## 3. 🔴 Paso 1: `define_singleton_method`

> **Regla.** `set_method` define el método en la autoclase del receptor con `define_singleton_method`. El proc pasa a ser el cuerpo de un método común: lo encuentra el lookup, lo ven `respond_to?` y `methods`, y **`self` adentro es el receptor** sin que hagamos nada.

```ruby
class PrototypedObject
  def set_method(selector, bloque)
    define_singleton_method(selector, &bloque)   # &bloque: el proc se pasa como el bloque que define_singleton_method espera
  end
end

guerrero = PrototypedObject.new
guerrero.set_property(:energia, 100)

guerrero.set_method(:descansar, proc { self.energia + 20 })   # el proc usa self
guerrero.descansar                  # => 120       ← self fue el guerrero
guerrero.singleton_methods          # => [:descansar, :energia]
guerrero.respond_to?(:descansar)    # => true
PrototypedObject.new.descansar      # => NoMethodError: undefined method `descansar' for an instance of PrototypedObject

guerrero.set_method(:suma, proc { |a, b| a + b })
guerrero.suma(1, 2)                 # => 3
guerrero.suma(1)                    # => ArgumentError: wrong number of arguments (given 1, expected 2)
#                                      es un método de verdad: controla la cantidad de argumentos
```

`# también: singleton_class.define_method(selector, &bloque)`, que es lo que `define_singleton_method` hace por dentro.

### Por qué `self` queda bien solo

Un proc recuerda el `self` del lugar donde fue escrito. El de `descansar` fue escrito afuera de todo, en el programa principal:

```ruby
suelto = proc { self }
suelto.call        # => main          ← el self del programa principal
```

Pero `define_singleton_method` **no ejecuta el proc**: lo convierte en el cuerpo de un método. Y un método se ejecuta siempre con `self` igual al receptor del mensaje; es cómo está cableado Ruby. Cuando llega `guerrero.descansar`, el lookup encuentra el método en la autoclase y lo corre con `self = guerrero`. El `self` que el proc recordaba queda descartado.

```ruby
guerrero.set_method(:yo, proc { self })
guerrero.yo.equal?(guerrero)       # => true     ← self es el receptor, no main
```

Esta es la ventaja grande de ir por la autoclase: **el contexto lo resuelve Ruby**. En la sección 5 vas a ver lo que cuesta resolverlo a mano.

### La firma: dos parámetros comunes

> **Regla.** `set_method(selector, bloque)` tiene **dos parámetros comunes**, porque el enunciado pasa el proc como argumento. Con `&bloque` en la firma, el enunciado explota.

| Escribís | Ruby entiende | Sale con `set_method(:a, proc { 1 })` |
|---|---|---|
| `def set_method(selector, bloque)` | dos argumentos; el segundo es un objeto `Proc` | anda |
| `def set_method(selector, &bloque)` | un argumento más un bloque pegado al mensaje | `ArgumentError: wrong number of arguments (given 2, expected 1)` |

Adentro, el `&` sí hace falta: `define_singleton_method(selector, &bloque)` convierte el objeto proc en el bloque que `define_singleton_method` espera (clase04: un proc se pasa como bloque con `&`).

> 🛠️ **Lo que te va a marcar el editor:** RubyMine no autocompleta `descansar` ni `atacar_a` sobre un `PrototypedObject`, porque esos métodos no existen hasta que el programa corre. Es normal en todo este ejercicio.

---

## 4. 🔴 Paso 2: `atacar_a` del enunciado

> **Regla.** Con `set_property` y `set_method`, el combate del enunciado anda entre dos guerreros armados a mano. Lo único que falta del primer bloque de 4.1 es `clone`.

```ruby
def armar_guerrero
  guerrero = PrototypedObject.new
  guerrero.set_property(:energia, 100)
  guerrero.set_property(:potencial_defensivo, 10)
  guerrero.set_property(:potencial_ofensivo, 30)

  guerrero.set_method(:atacar_a, proc { |otro_guerrero|                  # verbatim del enunciado
    if otro_guerrero.potencial_defensivo < self.potencial_ofensivo      # self: el que ataca
      otro_guerrero.recibe_danio(self.potencial_ofensivo - otro_guerrero.potencial_defensivo)
    end
  })

  guerrero.set_method(:recibe_danio, proc { |danio|                     # el proc {...} del enunciado
    set_property(:energia, energia - danio)                             # se pisa la propiedad; energia es el getter
  })
  guerrero
end

atila = armar_guerrero
jack  = armar_guerrero       # dos objetos distintos, armados igual

atila.atacar_a(jack)
jack.energia                 # => 80      ← 30 de ataque contra 10 de defensa: 20 de daño
atila.energia                # => 100     ← el que ataca no se toca

jack.set_property(:potencial_defensivo, 50)
atila.atacar_a(jack)         # => nil     ← el if no se cumple: no hay daño, y el if sin else devuelve nil
```

```
# ¿CÓMO FUNCIONA?  atila.atacar_a(jack)
# 1. lookup de atacar_a en la autoclase de atila → está (lo puso set_method) → self = atila, otro_guerrero = jack
# 2. jack.potencial_defensivo → getter en la autoclase de jack → 10
# 3. self.potencial_ofensivo → getter en la autoclase de atila → 30 ; 10 < 30 → entra al if
# 4. jack.recibe_danio(30 - 10) → lookup en la autoclase de jack → está → self = jack, danio = 20
# 5. set_property(:energia, energia - 20) → energia es el getter de jack → 100 → guarda 80
```

`recibe_danio` usa `set_property` para escribir, porque todavía no existe `energia =` (eso es azúcar sintáctico, Módulo 6). El enunciado deja el cuerpo a tu criterio; esta es la versión mínima.

---

## 5. 🟡 La otra forma: un diccionario de procs y `method_missing`

> **Regla.** La misma funcionalidad se puede lograr **sin definir ningún método**: `set_method` guarda el proc en un diccionario, y cuando llega un mensaje que el objeto no entiende, `method_missing` busca el proc por nombre y lo ejecuta. Anda, pero el contexto, la reflexión y los errores hay que resolverlos **a mano**.

Es el segundo camino de los dos únicos del Módulo 2, aplicado a métodos. Se escribe completo acá, en una clase aparte, para compararlo con lo que ya anda y para tenerlo listo: el Módulo 5 lo va a necesitar.

### Primer intento: guardar y ejecutar con `call`

```ruby
class OtraForma
  def set_property(nombre, valor)                      # igual que en PrototypedObject
    define_singleton_method(nombre) { propiedades[nombre] }
    propiedades[nombre] = valor
  end

  def set_method(selector, bloque)
    metodos[selector] = bloque                          # solo guarda: no define nada
  end

  def method_missing(selector, *args)                   # llega lo que el lookup no encontró
    if metodos.key?(selector)                           # ¿tengo un proc con ese nombre?
      metodos[selector].call(*args)                     # ⚠️ lo ejecuto tal cual
    else
      super                                             # no es mío: NoMethodError normal
    end
  end

  private

  def propiedades; @__properties__ ||= {}; end
  def metodos;     @__methods__    ||= {}; end          # segundo diccionario: selector → proc
end

o = OtraForma.new
o.set_property(:energia, 100)
o.set_method(:descansar, proc { self.energia + 20 })
o.descansar
# => NoMethodError: undefined method `energia' for main
#    ← el proc se ejecutó con el self que recordaba: main, el programa principal. main no tiene energia.
```

Acá está el problema que la autoclase resolvía sola. `call` ejecuta el proc **en el contexto donde fue escrito**. Con `define_singleton_method`, Ruby cableaba `self` al receptor porque el proc pasaba a ser un método. Con un diccionario, el proc sigue siendo un proc suelto, "volador": no está en contexto de nada. **Somos nosotros los responsables de ponerlo en contexto.**

### Bindear: `instance_exec`

> **Regla.** `objeto.instance_exec(*args, &proc)` ejecuta el proc con `self = objeto`, pasándole los argumentos. Es la forma de ejecutar un proc "como si fuera un método" de ese objeto.

```ruby
class OtraForma
  def method_missing(selector, *args)
    if metodos.key?(selector)
      instance_exec(*args, &metodos[selector])   # self = el receptor; args van al proc
    else
      super
    end
  end
end

o.descansar                       # => 120     ← ahora self fue o
o.set_method(:yo, proc { self })
o.yo.equal?(o)                    # => true
```

`instance_exec` es, exactamente, hacer a mano lo que `define_singleton_method` hacía por nosotros. Recordalo como **"no olvidar bindear"**: cada vez que un proc guardado se ejecuta, alguien tiene que decidir quién es `self`.

### Lo que `method_missing` rompe

Con `instance_exec` la segunda forma anda igual que la primera. Pero no es igual:

```ruby
o.methods(false)             # => [:energia]     ← descansar y yo no aparecen: no son métodos
o.respond_to?(:descansar)    # => false          ← ⚠️ miente: lo respondió hace tres líneas
o.method(:descansar)         # => NameError: undefined method `descansar' for class `#<Class:#<OtraForma…>>'
```

Todo lo que Ruby sabe sobre "qué mensajes entiende un objeto" mira los métodos definidos. `method_missing` le dijo a Ruby **qué hacer** con un mensaje, no **qué mensajes entendés**. Lo sabés de clase04: cada `method_missing` va con su `respond_to_missing?`, con el mismo criterio:

```ruby
class OtraForma
  def respond_to_missing?(selector, include_private = false)
    metodos.key?(selector) || super            # el MISMO criterio que method_missing
  end
end

o.respond_to?(:descansar)    # => true      ← ahora dice la verdad
o.method(:descansar).class   # => Method    ← y method también anda
o.volar                      # => NoMethodError: undefined method `volar' for #<OtraForma:0x…>
```

`methods` sigue sin listarlos, y la lista de métodos de un objeto deja de ser finita en el sentido en que todo el mundo la piensa. Cada herramienta de reflexión que usemos va a necesitar su parche.

### Tres razones para no ir por acá todavía

1. **No es la herramienta que la gente tiene en la cabeza cuando piensa en objetos.** Un método en la autoclase se entiende con el modelo de Ruby de siempre: lookup, `self` = receptor, `respond_to?`. `method_missing` es un mecanismo que está por afuera de ese modelo, y hay que explicárselo a cualquiera que toque el código.
2. **Rompe la reflexión, de a una herramienta por vez.** `respond_to?` se arregla con `respond_to_missing?`; `method` también; `methods` no. Y la asunción razonable de que un objeto tiene una interfaz finita deja de valer.
3. **Te ata a Ruby.** `method_missing` existe en Ruby; migrar este framework a otra tecnología obliga a cambiar la interfaz, no solo la implementación. Un método definido es un método en cualquier lenguaje.

Y una cuarta, práctica: es fácil olvidarse del `super`, del `respond_to_missing?`, del `instance_exec`. Son tres cosas que la autoclase hacía solas.

> 🎯 **Para el parcial, si te preguntan** por qué no conviene resolver `set_method` con `method_missing` si es posible hacerlo:
> Porque definir el método en la autoclase deja el contexto (`self`), la verificación de argumentos y la reflexión (`respond_to?`, `method`, `methods`) a cargo de Ruby, mientras que con `method_missing` cada una de esas cosas hay que programarla a mano (`instance_exec`, `respond_to_missing?`) y algunas no se pueden (`methods`). Además, `method_missing` ata la interfaz a Ruby. Se reserva para cuando no hay otro camino.

---

## 6. 🔴 Lo que queda abierto: dónde engancharse

> **Regla.** Con los métodos en la autoclase, **el lookup lo hace Ruby**. Cuando un objeto recibe un mensaje, Ruby busca en su autoclase y sube por la clase; si no encuentra, va a `method_missing` y de ahí a `NoMethodError`. En ningún punto de ese recorrido hay un lugar donde nuestro código pueda decir "antes de fallar, fijate en **otro objeto**".

Hoy no hace falta, porque todavía no existe el "otro objeto": cada guerrero tiene sus métodos y listo. Pero el enunciado, unas líneas más abajo, pide que `espadachin` reciba de `guerrero` los métodos que no tiene (`set_prototype`). Ese día va a hacer falta un gancho, y con la forma de la sección 3 no lo hay.

La forma de la sección 5 sí lo tiene: `method_missing` **es** el gancho. Es el único lugar al que Ruby llega diciendo "no encontré nada", y desde ahí se puede ir a buscar a donde uno quiera. Por eso la segunda forma queda escrita y en espera, no borrada.

**La decisión de hoy:** `define_singleton_method`. Es más simple, más segura, y cumple todo lo que el enunciado pidió hasta acá. Cuando aparezca el requerimiento que la rompe, se vuelve a discutir con las dos formas sobre la mesa.

---

## 7. 🔴 Las piezas armadas

El framework al final de este módulo. Lo del Módulo 2 sigue igual.

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
    define_singleton_method(selector, &bloque)    # el proc pasa a ser un método de este objeto
  end

  private

  def propiedades
    @__properties__ ||= {}
  end
end
```

### Los tests de esta pieza

```ruby
def armar_guerrero
  guerrero = PrototypedObject.new
  guerrero.set_property(:energia, 100)
  guerrero.set_property(:potencial_defensivo, 10)
  guerrero.set_property(:potencial_ofensivo, 30)
  guerrero.set_method(:atacar_a, proc { |otro_guerrero|
    if otro_guerrero.potencial_defensivo < self.potencial_ofensivo
      otro_guerrero.recibe_danio(self.potencial_ofensivo - otro_guerrero.potencial_defensivo)
    end
  })
  guerrero.set_method(:recibe_danio, proc { |danio| set_property(:energia, energia - danio) })
  guerrero
end

describe 'métodos' do
  it 'un método definido con set_method lo entiende solo ese objeto' do
    guerrero = PrototypedObject.new
    guerrero.set_property(:energia, 100)
    guerrero.set_method(:descansar, proc { self.energia + 20 })
    expect(guerrero.descansar).to eq 120
    expect(guerrero.respond_to?(:descansar)).to be true
    expect { PrototypedObject.new.descansar }.to raise_error(NoMethodError)
  end
  it 'self dentro del proc es el receptor' do
    guerrero = PrototypedObject.new
    guerrero.set_method(:yo, proc { self })
    expect(guerrero.yo).to be guerrero
  end
  it 'un guerrero ataca a otro' do
    atila = armar_guerrero
    jack  = armar_guerrero
    atila.atacar_a(jack)
    expect(jack.energia).to eq 80
    expect(atila.energia).to eq 100
  end
end
```

---

## Checkpoint del Módulo 3

1. ¿Por qué `define_method` dentro de `set_method` explota, si `self` es el guerrero? ¿En qué modelo el guerrero sí es un proveedor de comportamiento, y en cuál no?
2. ¿Qué pasa si `set_method` hace `self.class.send(:define_method, …)`? ¿Por qué es un error de diseño y no de Ruby?
3. Un proc escrito en el programa principal recuerda `self = main`. ¿Por qué, al pasarlo por `define_singleton_method`, `self` termina siendo el receptor?
4. Escribí las dos firmas posibles de `set_method` (con `bloque` y con `&bloque`) y decí cuál cumple el enunciado y qué error da la otra.
5. En `atacar_a`, ¿quién es `self` y quién es `otro_guerrero`? Seguí el flujo completo de `atila.atacar_a(jack)` hasta que `jack` queda en 80.
6. En la "otra forma", `metodos[selector].call(*args)` falla con `undefined method 'energia' for main`. Explicá de dónde sale `main`.
7. ¿Qué hace `instance_exec(*args, &proc)` y qué cosa reemplaza que `define_singleton_method` hacía sola?
8. Con la "otra forma", `o.respond_to?(:descansar)` da `false` aunque `o.descansar` ande. ¿Por qué, y con qué se arregla? ¿Qué herramienta de reflexión no se arregla?
9. Dá las tres razones para no usar `method_missing` mientras haya otra opción.
10. Con los métodos en la autoclase, ¿en qué punto del lookup de Ruby podría nuestro código "ir a buscar a otro objeto"? ¿Y con `method_missing`?

## Qué viene en el Módulo 4

`otro_guerrero = guerrero.clone`, con el `clone` que Ruby ya tiene. Vas a ver qué copia y qué no (la autoclase sí, el diccionario **no**: Atila y Jack van a compartir la misma energía), qué es una copia superficial y una profunda, y cómo se le enseña a `clone` a copiar lo que nos importa con `initialize_copy`. Y vas a comprobar el primer requerimiento negativo del enunciado: el clon no se entera de los métodos que el original aprende después.

**FIN DEL MÓDULO 3**
