# Clase desde cero — Multimethods — Módulo 7: La otra forma: method_missing

**Unidad:** clase05 · **Módulo:** 7 de 7 · **Densidad:** 🟡 · **Parte del enunciado:** ninguna (opcional)

## Sobre este documento

**Qué cubre:** la misma funcionalidad de los Módulos 3 y 4 resuelta sin `define_method`, atrapando con `method_missing` los mensajes que la clase no entiende. Anda. Es peor diseño para este problema, y este módulo muestra exactamente por qué, y en qué problemas distintos sí es la herramienta correcta.

**Qué NO cubre:** ningún cambio al framework. El código bueno es el del Módulo 6 y no se toca. Este módulo no resuelve nada del enunciado: es una comparación para entender mejor lo que ya hiciste. **Si vas justo de tiempo, salteálo.**

## De dónde venís

Del Módulo 6: el framework completo.
De clase04: `method_missing(name, *args, &block)` se ejecuta cuando un objeto recibe un mensaje que no entiende; `super` desde ahí produce el `NoMethodError` normal; `respond_to_missing?` es su compañero para que `respond_to?` y `method` digan la verdad.

---

## 1. 🟡 La versión con `method_missing`

> **Regla.** En esta versión, `partial_def` **solo guarda** la definición. La clase no gana ningún método. Cuando una instancia recibe un mensaje que no entiende, `method_missing` busca en las definiciones de su clase y, si alguna matchea, la ejecuta; si no, delega en `super`.

Para que la comparación sea limpia, se usa la elección simple del Módulo 3 (`find`); la distancia se agregaría igual que en el Módulo 5.

```ruby
class Module
  def partial_blocks
    @partial_blocks ||= Hash.new { |hash, clave| hash[clave] = [] }
  end

  def partial_def(name, types, &block)
    partial_blocks[name] << PartialBlock.new(types, &block)   # guardar, y nada más
  end
end

class Object                                              # el receptor es una INSTANCIA: se abre Object
  def method_missing(name, *args, &block)                 # name: el selector que nadie entendió
    definiciones = self.class.partial_blocks.fetch(name, [])   # las de la clase de la instancia (o ninguna)
    definicion = definiciones.find do |partial_block|
      partial_block.matches?(*args)
    end
    if definicion
      definicion.call_in_context(self, *args)             # self ya es la instancia: mismo contexto que en M4
    else
      super                                               # no es un multimétodo: NoMethodError normal
    end
  end

  def respond_to_missing?(name, include_private = false)  # para que respond_to? no mienta
    self.class.partial_blocks.key?(name) || super
  end
end
```

Al cargar esto, Ruby avisa:

```
warning: redefining Object#method_missing may cause infinite loop
warning: redefining Object#respond_to_missing? may cause infinite loop
```

Es una advertencia razonable: cualquier mensaje mal escrito dentro de `method_missing` vuelve a entrar en `method_missing`. Acá no pasa porque el cuerpo solo usa mensajes que existen.

**`fetch` con valor por defecto:** `hash.fetch(clave, valor)` devuelve lo guardado bajo `clave`, o `valor` si la clave no existe, **sin crearla**. Ya la usaste en el `respond_to?` del Módulo 5. Importa acá porque por `method_missing` pasa **cualquier** nombre que nadie entendió (`otra_cosa`, `to_sx`, un typo): con `[]` cada uno dejaría una entrada basura en el Hash de la clase; con `fetch`, no.

Con esto, los ejemplos del enunciado andan igual:

```ruby
class A
  partial_def :concat, [String, String] do |s1, s2| s1 + s2 end
  partial_def :concat, [Array] do |a| a.join end
end

A.new.concat("a", "b")       # => "ab"
A.new.concat(["x", "y"])     # => "xy"
A.new.concat(1, 2)           # => NoMethodError: undefined method `concat' for #<A:0x…>
A.new.otra_cosa              # => NoMethodError: undefined method `otra_cosa' for #<A:0x…>
A.new.respond_to?(:concat)   # => true     gracias a respond_to_missing?
```

---

## 2. 🔴 Las dos formas, lado a lado

> **Regla.** Con `define_method`, el multimétodo es un **método real** de la clase. Con `method_missing`, la clase no tiene nada y cada llamada es un mensaje no entendido que se rescata a último momento.

| | `define_method` (Módulos 3 a 6) | `method_missing` (este módulo) |
|---|---|---|
| `A.instance_methods(false)` | `[:concat]` | `[]` |
| Qué queda en la clase | Un método por selector | Nada; las definiciones viven solo en el Hash |
| Cómo llega la llamada | Ruby encuentra `concat` en `A` y lo ejecuta | Ruby busca `concat` en `A`, en sus ancestros, no lo encuentra, y recién entonces llama a `method_missing` |
| `A.new.respond_to?(:concat)` | `true`, sin hacer nada | `false`, salvo que además escribas `respond_to_missing?` |
| Error si ninguna definición matchea | El que decidas (`raise NoMethodError, "ninguna definición…"`) | `super` → el `NoMethodError` estándar, indistinguible de un typo |
| Un selector que **ya existe** en la clase o en un ancestro | `define_method` lo pisa: el multimétodo gana | `method_missing` **nunca se ejecuta**: el método existente gana |
| Herencia (`B < A` sin definiciones propias) | Anda: el método heredado apunta a la lista de `A` | Falla: `self.class` es `B`, y `B` no tiene definiciones (habría que recorrer `ancestors`) |
| Costo por llamada | Una búsqueda de método | Búsqueda fallida por toda la cadena de ancestros + `method_missing` |

**Por qué estas diferencias importan.** Todas salen de un mismo hecho: en el momento 1 **ya sabemos el nombre** del método (`partial_def` lo recibe). `define_method` usa esa información para dejar un método hecho y derecho. `method_missing` la ignora y la reconstruye tarde, en cada llamada, cuando todo lo demás falló.

### La fila que más duele: pisar un método existente

```ruby
class Tanque
  partial_def :==, [Tanque] do |otro| "comparación de tanques" end   # Object ya entiende ==
  partial_def :to_s, [] do "un tanque" end                            # Object ya entiende to_s
end

Tanque.new == Tanque.new    # => false                  (versión method_missing) el == de Object
Tanque.new.to_s             # => "#<Tanque:0x…>"        el to_s de Object
```

Con `method_missing`, esas dos definiciones parciales **no se ejecutan jamás**: `==` y `to_s` existen en `Object`, así que ningún mensaje llega a "no entendido". Con `define_method` (Módulo 3, sección 5) el multimétodo pisa al método heredado y las definiciones corren. Un framework de multimétodos que no puede redefinir `==` es un framework a medias.

> 🎯 **Para el parcial, si te preguntan** por qué `partial_def` conviene implementarlo con `define_method` y no con `method_missing`:
> Porque en el momento de la definición el nombre del método ya se conoce, y `define_method` deja un método real en la clase: aparece en `instance_methods`, responde a `respond_to?`, se hereda y puede pisar un método existente. `method_missing` solo actúa cuando ningún método se encontró, así que no puede redefinir mensajes que la clase ya entiende, y hace pasar cada llamada por una búsqueda fallida.

---

## 3. 🟡 Cuándo `method_missing` sí es la herramienta

> **Regla.** `method_missing` es el último recurso: se usa cuando los nombres de los mensajes **no se conocen en el momento de la definición**, porque son infinitos o los decide quien llama.

El caso típico es una interfaz "por patrón de nombre". Un ejército que entiende `buscar_por_<cualquier atributo>`:

```ruby
class Guerrero
  attr_reader :nombre, :energia
  def initialize(n, e); @nombre = n; @energia = e; end
end

class Ejercito
  def initialize(*guerreros); @guerreros = guerreros; end

  def method_missing(name, *args)
    if name.to_s.start_with?("buscar_por_")                    # ¿el nombre sigue el patrón?
      atributo = name.to_s.delete_prefix("buscar_por_")        # "buscar_por_nombre" → "nombre"
      @guerreros.find { |g| g.send(atributo) == args.first }   # g.nombre == "Héctor"
    else
      super                                                    # cualquier otro nombre: error normal
    end
  end

  def respond_to_missing?(name, include_private = false)
    name.to_s.start_with?("buscar_por_") || super
  end
end

e = Ejercito.new(Guerrero.new("Aquiles", 9), Guerrero.new("Héctor", 8))
e.buscar_por_nombre("Héctor").energia    # => 8
e.buscar_por_energia(9).nombre           # => "Aquiles"
e.respond_to?(:buscar_por_apellido)      # => true    responde al patrón, aunque nadie lo escribió
e.otra                                   # => NoMethodError: undefined method `otra' for #<Ejercito …>
```

Acá `define_method` no sirve: habría que definir `buscar_por_nombre`, `buscar_por_energia`, `buscar_por_apellido`… **antes** de saber cuáles se van a usar. El conjunto es infinito. `method_missing` es la única herramienta que puede atender un mensaje que nadie definió.

`partial_def` es lo opuesto: el conjunto de nombres es finito y se conoce exactamente en el momento 1. Por eso va con `define_method`.

**`send`:** `objeto.send(:nombre, args)` manda el mensaje `nombre` construido en tiempo de ejecución; es la forma de invocar un método cuyo nombre es un valor. Acá aparece solo para leer el atributo dinámico.

---

## Checkpoint del Módulo 7

1. En la versión con `method_missing`, ¿qué muestra `A.instance_methods(false)` después de dos `partial_def :concat`? ¿Y en la versión del Módulo 3?
2. ¿Por qué `partial_def :==, [Tanque]` nunca se ejecuta con `method_missing` y sí con `define_method`?
3. Explicá el recorrido que hace Ruby desde `A.new.concat("a", "b")` hasta que se ejecuta `method_missing`.
4. ¿Qué diferencia hay entre `hash.fetch(:x, [])` y `hash[:x]` con el Hash del Módulo 3, y por qué importa dentro de `method_missing`?
5. ¿Qué hace `super` dentro de `method_missing` y qué error termina viendo el usuario?
6. Dá un ejemplo, distinto del ejército, de una interfaz donde los nombres no se conocen al definir la clase.
7. Completá la regla: "`define_method` cuando …; `method_missing` cuando …".

## Qué viene después

La clase desde cero termina acá. El paso siguiente es el **apunte maestro** de la unidad, que cubre lo mismo con cobertura plena y queda como material permanente; después de estos módulos, se lee como repaso. Antes de eso, conviene cerrar las dudas de los checkpoints por chat.

**FIN DEL MÓDULO 7**

**FIN DE LA CLASE DESDE CERO — MULTIMETHODS**
