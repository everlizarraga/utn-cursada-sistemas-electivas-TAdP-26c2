# Clase desde cero — Prototype — Módulo 10: La otra forma: módulos

**Unidad:** clase06 · **Módulo:** 10 (opcional) · **Densidad:** 🟡 · **Parte del enunciado:** ninguna

## Sobre este documento

**Qué cubre:** la arquitectura que este framework **no** eligió: un módulo de Ruby por cada objeto, incluido en su autoclase, donde `set_method` es `define_method` sobre ese módulo, `set_prototype` es `include`, y el lookup lo hace Ruby de punta a punta. Anda, resuelve la trampa de `to_s`, regala la reflexión y convierte `call_next` en `super`. Y tiene sus propios costos, que este módulo muestra uno por uno.

**Qué NO cubre:** ningún cambio al framework. El código bueno es el de `clase06-prototype.rb` y no se toca. **Si vas justo de tiempo, salteálo.**

## De dónde venís

Del Módulo 3: `define_singleton_method` deja el contexto y la reflexión a cargo de Ruby.
Del Módulo 5: los métodos pasaron a un diccionario porque con la autoclase no había gancho para buscar en otro objeto, y porque un método de autoclase no se puede bindear a otro objeto.
Del Módulo 6: `to_s` nunca llega a `method_missing`.
De clase02 y clase03: `Module.new` crea un módulo sin nombre; `singleton_class.include(m)` mete un módulo en la autoclase de un objeto (`extend` es el atajo); `super` dentro de un método sigue por la linealización.

---

## 1. 🟡 La idea

> **Regla.** Si cada objeto tiene **su propio módulo** metido en su autoclase, "darle un método a un objeto" es definirlo en su módulo, y "tener un prototipo" es que **mi módulo incluya el módulo del prototipo**. A partir de ahí, Ruby hace el lookup, la linealización, `super`, `respond_to?` y `method` sin que escribamos nada.

Es la cuarta alternativa que siempre estuvo sobre la mesa: en vez de un lookup paralelo (`method_missing`), **ajustar nuestra idea a lo que Ruby ya soporta**, y que todas las herramientas asociadas funcionen como deberían. El Módulo 5 la descartó por dos razones; las dos se disuelven con módulos:

- "Con la autoclase no hay gancho": no hace falta gancho, porque el prototipo **está en la cadena de clases** del derivado (su módulo está incluido).
- "Un método de autoclase no se puede bindear a otro objeto": un método de **módulo** sí, porque un módulo no es de nadie.

---

## 2. 🟡 La implementación, completa

```ruby
module PrototypedConModulos
  def comportamiento                                                  # el módulo propio de este objeto, creado al primer uso
    @__module__ ||= Module.new.tap { |modulo| singleton_class.include(modulo) }   # tap: hacer algo con el objeto y devolverlo
  end

  def set_property(nombre, valor)
    propiedades[nombre] = valor
    comportamiento.define_method(nombre) { propiedades[nombre] }      # el getter es un método del módulo
  end

  def get_property(nombre)
    propiedades[nombre]
  end

  def set_method(selector, bloque)
    comportamiento.define_method(selector, &bloque)                   # el proc pasa a ser un método del módulo
  end

  def set_prototype(prototipo)
    comportamiento.include(prototipo.comportamiento)                  # mi módulo incluye el suyo: Ruby linealiza
  end

  def set_prototypes(prototipos)
    prototipos.reverse_each { |prototipo| comportamiento.include(prototipo.comportamiento) }   # al revés, para que el primero quede más cerca
  end

  private

  def propiedades
    @__properties__ ||= {}
  end

  def method_missing(selector, *args)                                 # method_missing SOLO para el azúcar del setter
    if selector.end_with?("=")
      nombre = selector.to_s.chomp("=").to_sym
      args.first.is_a?(Proc) ? set_method(nombre, args.first) : set_property(nombre, args.first)
    else
      super
    end
  end

  def respond_to_missing?(selector, include_private = false)
    selector.end_with?("=") || super
  end
end

class PO
  include PrototypedConModulos
end
```

Menos de la mitad de líneas que el framework de los módulos anteriores, sin `find_method`, sin `prototype_chain`, sin pila, sin `call_next`. Veamos qué hace y qué no.

```ruby
guerrero = PO.new
guerrero.energia = 100
guerrero.potencial_ofensivo = 30
guerrero.potencial_defensivo = 10
guerrero.atacar_a = proc { |otro| otro.recibe_danio(self.potencial_ofensivo - otro.potencial_defensivo) if otro.potencial_defensivo < self.potencial_ofensivo }
guerrero.recibe_danio = proc { |danio| self.energia = self.energia - danio }

guerrero.singleton_class.ancestors.first(3)
# => [#<Class:#<PO:0x…>>, #<Module:0x…>, PO]     ← la autoclase, el módulo propio, la clase

espadachin = PO.new
espadachin.set_prototype(guerrero)
espadachin.energia = 100; espadachin.potencial_defensivo = 10; espadachin.potencial_ofensivo = 30
espadachin.habilidad = 0.5; espadachin.potencial_espada = 30

espadachin.singleton_class.ancestors.first(4)
# => [#<Class:#<PO:0x…>>, módulo(espadachin), módulo(guerrero), PO]   ← el prototipo, EN la cadena de Ruby
```

---

## 3. 🟡 Lo que se gana

```ruby
# el super de los prototipos es super, a secas (con paréntesis: ver abajo)
espadachin.potencial_ofensivo = proc { super() + potencial_espada * habilidad }
espadachin.potencial_ofensivo        # => 45.0

# un método agregado al prototipo después, llega
guerrero.sanar = proc { self.energia = self.energia + 10 }
espadachin.sanar                     # => 110

# la reflexión, gratis
espadachin.respond_to?(:sanar)       # => true
espadachin.method(:sanar).owner == guerrero.comportamiento   # => true
espadachin.methods.include?(:sanar)  # => true

# to_s SÍ se puede pisar: el módulo va antes que Object en la cadena
guerrero.to_s = proc { "Atila" }
[guerrero.to_s, espadachin.to_s]     # => ["Atila", "Atila"]       ← cierra el hilo del Módulo 6

# múltiples prototipos, en orden, y super sigue por la linealización de Ruby
atacante = PO.new; atacante.grito = proc { "ataco" }
defensor = PO.new; defensor.grito = proc { "defiendo" }
x = PO.new; x.set_prototypes([atacante, defensor])
x.grito                              # => "ataco"
atacante.grito = proc { super().upcase }
x.grito                              # => "DEFIENDO"               ← desde atacante, el siguiente para x es defensor

# un método de módulo se bindea a quien sea: el callejón del Módulo 5 no existe acá
guerrero.comportamiento.instance_method(:atacar_a).bind(PO.new).class   # => Method
```

Todo lo que el Módulo 9 construyó a mano (pila, `resolver`, `prototype_chain`) lo hace Ruby, porque la cadena de prototipos **es** la cadena de ancestros.

---

## 4. 🟡 Lo que se pierde

Cada cosa que Ruby hace por nosotros la hace **a su manera**, y su manera no siempre es la del enunciado.

| Qué | Con módulos | Qué pide el enunciado |
|---|---|---|
| **`clone`** | `c = guerrero.clone; guerrero.nuevo = proc { 1 }; c.respond_to?(:nuevo)` → `true`. La autoclase copiada incluye **el mismo módulo** que el original, así que el clon ve todo lo que el original aprende después | "Los cambios no se impactan en el objeto que es clon" ✗ |
| **Ciclos** | `x.set_prototype(y); y.set_prototype(x)` → `ArgumentError: cyclic include detected`, al linkear | No lo pide; es más estricto, y más claro |
| **Objetos congelados** | `5.set_method(…)` → `TypeError: can't define singleton`: un entero no tiene autoclase propia | `include Prototyped` en `Object` deja afuera a números, símbolos, `nil` |
| **`super` implícito** | `proc { super }` → `RuntimeError: implicit argument passing of super from method defined by define_method() is not supported`. Hay que escribir `super()` o `super(a, b)` | El enunciado escribe `call_next` sin paréntesis |
| **Conflictos** | Los decide la linealización de Ruby: para que "gane el primero de la lista" hay que incluir al revés | A criterio del grupo |
| **Propiedad del derivado** | El getter es un método del módulo del prototipo; `h.set_prototype(g); h.energia` → `nil`, igual que en el Módulo 5 | "Métodos y no estado" ✓, con la conducta vieja |

El primero es el que pesa: arreglar `clone` con módulos obliga a crear un módulo nuevo para el clon y **copiarle los métodos** del original, cosa que `Module` no ofrece directo (hay que recorrer `instance_methods` y redefinir cada uno con `instance_method` + `define_method`). Se puede; ya no es "gratis".

> 🎯 **Para el parcial, si te preguntan** cuál es la ventaja y la desventaja de implementar prototipos con un módulo por objeto:
> La ventaja es que el lookup, la linealización, `super` y toda la reflexión los hace Ruby, porque el prototipo queda en la cadena de ancestros del derivado; eso resuelve lo que `method_missing` no puede, como redefinir `to_s`. La desventaja es que Ruby decide con sus reglas: `clone` comparte el módulo y el clon ve cambios posteriores, los objetos sin autoclase quedan afuera, `super` exige argumentos explícitos dentro de `define_method`, y los conflictos siguen el orden de `include`. Cada regla del enunciado que no coincida con la de Ruby hay que emparcharla.

---

## 5. 🟡 Cuándo elegir cada una

> **Regla.** `method_missing` es la herramienta cuando el comportamiento que querés **no coincide** con el modelo de Ruby y necesitás control total: el clon como foto, propiedades en diccionario, `call_next` con una semántica propia, ciclos tolerados. Los módulos son la herramienta cuando tu modelo **sí coincide** con el de Ruby y querés que todo lo demás funcione solo.

Las dos son defendibles en un TP. Lo que no es defendible es no saber qué se paga en cada una. Si un docente te pregunta "¿por qué no usaste módulos?", la respuesta no es "no se me ocurrió": es "porque el enunciado pide que el clon no vea cambios y que cualquier objeto sea prototipable, y con módulos esas dos cosas hay que emparcharlas". Y si te pregunta "¿por qué no usaste `define_singleton_method`?", la respuesta es el Módulo 5: no hay gancho, y no hay `bind`.

> 💎 **Otra forma de hacerlo.** Híbrida: métodos en módulos (para `to_s`, reflexión y `super`) y `clone` redefinido para fabricar un módulo nuevo copiando los métodos. Es más código que cualquiera de las dos puras, y junta lo mejor de ambas. Si tu grupo elige módulos, es la versión que cumple el enunciado entero.

---

## Checkpoint del Módulo 10

1. ¿Por qué con un módulo por objeto no hace falta `method_missing` para buscar en el prototipo? ¿Dónde está el prototipo, visto desde Ruby?
2. Las dos razones del Módulo 5 para abandonar la autoclase, ¿por qué no aplican a un módulo?
3. ¿Por qué `guerrero.to_s = proc { "Atila" }` anda acá y no en el framework de los Módulos 5 a 9?
4. `espadachin.potencial_ofensivo = proc { super + … }` explota. ¿Qué dice el error y cómo se escribe bien?
5. Explicá por qué un clon ve los métodos que el original aprende después, mirando `singleton_class.ancestors` de los dos.
6. ¿Qué pasa con `5.set_method(…)` y por qué? ¿Qué parte del enunciado deja sin cumplir?
7. `set_prototypes([a, b])` incluye al revés. ¿Qué pasaría con el orden de conflicto si incluyera en orden?
8. Elegí una de las dos arquitecturas para un TP y defendela en tres oraciones, nombrando qué pagás.

**FIN DEL MÓDULO 10**

**FIN DE LA CLASE DESDE CERO — PROTOTYPE**
