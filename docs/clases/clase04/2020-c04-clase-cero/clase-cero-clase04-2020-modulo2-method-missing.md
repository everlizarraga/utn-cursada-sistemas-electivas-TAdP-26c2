# Clase desde Cero — Clase 04 (2020) — Módulo 2
## `method_missing`: recepción dinámica de mensajes

> **Sobre este documento.** Cubre la primera de las tres ideas de la clase: qué hace Ruby cuando un objeto recibe un mensaje que no entiende, por qué la decisión se la deja al objeto, y cómo se aprovecha eso. Termina con el registrador de mensajes: un objeto que se pone adelante de otro y anota todo lo que le mandan, sin tocar ninguna clase.
> **No cubre:** bloques, procs ni `self`. Este módulo se entiende solo con el módulo 1 y la clase 03; no necesita los módulos 3, 4 y 5.

> **De dónde venís.** Del módulo 1: `<<`, hashes, `*args` en las dos direcciones, `send`, `start_with?`, `delete_prefix`, `private def`, `p`. De la clase 03: el method lookup (autoclase → clase con sus mixins → superclases → `Object` → `BasicObject`), `ancestors`, y el metamodelo: `Object` incluye el mixin `Kernel`, y `BasicObject` es el tope sin superclase.

---

## 1. El lookup tiene un último paso que nadie te contó 🔴

Repasemos el camino de un mensaje, con el `Guerrero` de la materia:

```ruby
require_relative 'age'           # el age.rb de la cátedra: Atacante, Defensor, Guerrero, Espadachin, Misil, Muralla

atila = Guerrero.new             # potencial ofensivo 20, energía 100, potencial defensivo 10 (los defaults)
p Guerrero.ancestors             # => [Guerrero, Defensor, Atacante, Object, Kernel, BasicObject]
                                 #     ↑ clase   ↑ sus dos mixins (clase 02)   ↑ Object incluye el mixin Kernel
```

Cuando hacés `atila.descansar`, Ruby busca un método llamado `descansar` en este orden. Es tu diagrama de la clase 3, con una sola novedad: los mixins de la clase 2 están adentro de la cadena, no desaparecieron.

```
  #atila                                   ← la autoclase de atila (clase 03), vacía si no le definiste nada
    │ no está
    ▼
  Guerrero ──► Defensor ──► Atacante       ← la clase, y después sus MIXINS (clase 02), linearizados
    │ ¡está en Guerrero! → se ejecuta ese.
    ▼ (si no estuviera)
  Object ──► Kernel ──► BasicObject        ← Kernel también es un mixin: el que Object incluye
                             │
                            nil            ← BasicObject no tiene superclase. Acá se acaba el camino.
```

`Defensor`, `Atacante` y `Kernel` son módulos incluidos con `include`: los mixins de la clase 2. En esta clase no son tema, pero están en cada lookup que vas a seguir, y en el módulo 5 vas a ver que también se pueden abrir desde un bloque.

Ahora la pregunta que abre la clase: **¿y si llega a `BasicObject` y tampoco está?**

```ruby
atila.resolver_un_cubo_rubik
# => NoMethodError: undefined method 'resolver_un_cubo_rubik' for an instance of Guerrero
```

Ya viste este error mil veces. Lo que no viste es **quién lo lanza**. Uno diría "el lookup falló y Ruby tira el error". No es así. El lookup no lanza nada: cuando llega al final sin encontrar, hace *otra cosa*, y esa otra cosa es la que termina en el error. Y esa otra cosa la podés cambiar.

---

## 2. ¿Quién decide qué hacer? Una decisión de diseño 🔴

Cuando le decís algo a una persona y no te entiende, ¿quién decide qué pasa? La persona. Puede preguntarte "¿qué?", puede ignorarte, puede adivinar. No lo decide el aire entre los dos: lo decide quien recibió el mensaje.

Ruby, que es un lenguaje de objetos, toma la misma decisión: **el que decide qué hacer con un mensaje no entendido es el objeto que lo recibió.** Y la única forma de pedirle a un objeto que decida algo es mandarle un mensaje. Entonces, cuando el lookup de `resolver_un_cubo_rubik` llega a `BasicObject` sin encontrar nada, Ruby le manda a `atila` **un segundo mensaje**:

```
  atila.resolver_un_cubo_rubik(3, "rápido")
        │
        ▼ lookup: #atila → Guerrero → Defensor → Atacante → Object → Kernel → BasicObject → ✗ no está
        │
        ▼ entonces Ruby manda:
  atila.method_missing(:resolver_un_cubo_rubik, 3, "rápido")
        │                    ↑ el nombre del mensaje, como símbolo   ↑ los argumentos que venían
        ▼ lookup OTRA VEZ, por la misma cadena, buscando method_missing
  #atila → Guerrero → … → BasicObject → ¡está! BasicObject lo tiene definido.
```

Ese `method_missing` de `BasicObject` es el que lanza el `NoMethodError`. Es un método común y corriente, y como todo método común, **si lo definís en cualquier lugar de la cadena, el lookup encuentra el tuyo primero** y el de `BasicObject` no se ejecuta.

Comprobalo:

```ruby
p BasicObject.private_instance_methods(false)
# => [:initialize, :method_missing, :singleton_method_added, :singleton_method_removed, :singleton_method_undefined]
#                  ↑ ahí está. Es privado: no lo llamás vos, lo llama Ruby.

p BasicObject.instance_method(:method_missing).owner    # => BasicObject   ← quién lo define
```

Eso es **recepción dinámica de mensajes**: un objeto puede responder mensajes que no tiene definidos, decidiendo en el momento, porque Ruby le pregunta antes de rendirse.

> 🎓 **Para el parcial, si te preguntan:** *¿Qué pasa cuando un objeto recibe un mensaje que no entiende?*
> El method lookup recorre la jerarquía completa y no encuentra el método. Entonces Ruby le envía al mismo objeto el mensaje `method_missing`, con el nombre del mensaje original como símbolo y sus argumentos. Ese segundo mensaje hace el lookup normal; la implementación por defecto está en `BasicObject` y lanza `NoMethodError`. Redefiniendo `method_missing` en cualquier clase de la jerarquía, el objeto decide qué hacer.

---

## 3. Redefinir `method_missing`: los primeros ejemplos 🔴

### El más chico posible: un objeto que no escucha

```ruby
class Sordo
  private def method_missing(name, *args)   # name: símbolo con el nombre del mensaje. *args: lo que vino, en un array
    puts "EH?"                               # no importa qué le digas
    self                                     # devuelve el mismo objeto, para poder encadenar
  end
end

s = Sordo.new
s.hola                            # => EH?
s.hola.como.estas(1, 2).todo_bien # => EH?    ← cada mensaje vuelve a caer en method_missing
                                  #    EH?      y como devuelve self, el siguiente mensaje va al mismo Sordo
                                  #    EH?
                                  #    EH?
```

Lo marcamos `private` porque `method_missing` es un mecanismo interno: no es un mensaje que alguien de afuera deba mandar a propósito. Ruby lo invoca igual aunque sea privado.

### Con criterio: un guerrero que come

Un `Guerrero` entiende `descansar`, `atacar`, `sufri_danio`. Queremos que entienda **cualquier** mensaje que empiece con `comerse_`, y que recupere tanta energía como letras tenga lo que comió:

```ruby
require_relative 'age'

class Guerrero
  private def method_missing(name, *args)
    if name.start_with?("comerse_")                                # ¿es un mensaje de los nuestros?
      self.energia += name.to_s.delete_prefix("comerse_").size     # sí: energía += largo de lo que sigue a "comerse_"
    end                                                            #     (to_s porque delete_prefix es de String, no de Symbol)
  end
end

atila = Guerrero.new(10, 10, 10)     # energía 10
p atila.energia                      # => 10
atila.comerse_un_sanguche            # "un_sanguche" tiene 11 letras
p atila.energia                      # => 21
```

`self.energia += 11` es la forma corta de `self.energia = self.energia + 11`: usa el getter y el setter que `attr_accessor` creó.

Funciona. Y tiene un bug que todavía no ves.

---

## 4. La regla: si no lo atendés, delegá a `super` 🔴

Con la versión de arriba, ¿qué pasa con un mensaje que no empieza con `comerse_`?

```ruby
p atila.sarasa            # => nil     ← ⚠️ no explota. Devuelve nil en silencio.
p atila.sarasa(1, 2)      # => nil
```

El `if` no se cumple, el método termina, devuelve `nil`. **Te comiste el `NoMethodError`.** Ahora cualquier error de tipeo en cualquier mensaje a un guerrero pasa desapercibido y aparece tres archivos más lejos como un `nil` inexplicable. Es lo contrario de *fail-fast*: fallar temprano, cerca de la causa.

La solución es no decidir sobre lo que no es tuyo:

```ruby
class Guerrero
  private def method_missing(name, *args)
    if name.start_with?("comerse_")
      self.energia += name.to_s.delete_prefix("comerse_").size
    else
      super            # no es mío: que lo resuelva el method_missing de más arriba en la cadena
    end                # (super sin paréntesis reenvía los mismos argumentos: name y *args)
  end
end

atila.sarasa
# => NoMethodError: undefined method 'sarasa' for an instance of Guerrero   ← el error normal, como corresponde
atila.comerse_una_pizza
p atila.energia          # => 30    ← "una_pizza" tiene 9 letras; 21 + 9
```

Por qué `super` y no lanzar el error vos a mano: porque **no sabés qué hay más arriba**. Si algún mixin de la cadena también definió `method_missing` para atender otros mensajes, tu `raise` lo pisaría. Con `super` la cadena sigue, y si nadie lo atiende, llega a `BasicObject` y explota como siempre.

> 🎓 **Para el parcial, si te preguntan:** *¿Por qué hay que delegar a `super` en `method_missing`?*
> Porque un `method_missing` que no llama a `super` responde *todos* los mensajes, incluidos los que no sabe atender: devuelve `nil` en vez de fallar, y el error aparece lejos de la causa. Con `super` el mensaje sigue subiendo por la jerarquía; si nadie lo atiende, `BasicObject` lanza `NoMethodError` como corresponde.

---

## 5. `respond_to?` miente, y el contrato para que no mienta 🔴

Un guerrero ahora entiende `comerse_un_sanguche`. Preguntémosle si lo entiende:

```ruby
p atila.respond_to?(:descansar)             # => true
p atila.respond_to?(:comerse_un_sanguche)   # => false    ← ⚠️ mentira. Lo entiende: acabamos de verlo.
```

`respond_to?` mira **los métodos definidos** en la jerarquía. No sabe nada de `method_missing`, porque `method_missing` puede atender cualquier cosa y `respond_to?` no puede adivinar cuáles. Así que te da una respuesta incompleta.

Ruby te deja completar esa respuesta con otro método, que `respond_to?` consulta cuando no encontró el método normal:

```ruby
class Guerrero
  def respond_to_missing?(name, include_private = false)   # misma firma que respond_to? usa por dentro
    name.start_with?("comerse_") || super                    # ¿es de los míos? sí → true. no → que decida el de arriba
  end
end

p atila.respond_to?(:comerse_un_sanguche)   # => true     ← ahora dice la verdad
p atila.respond_to?(:sarasa)                # => false    ← y para lo que no atiende, sigue siendo false
p atila.respond_to?(:descansar)             # => true     ← lo normal no cambió
```

Y hay un premio que no es obvio: `method(:nombre)` de la clase 03 también usa `respond_to_missing?`.

```ruby
p atila.method(:comerse_un_sanguche).class   # => Method   ← ahora podés obtener el objeto método, aunque el método no exista
p atila.method(:comerse_un_sanguche).call    # => 41       ← y ejecutarlo (30 + 11)
```

**El contrato:** cada vez que redefinís `method_missing`, redefinís `respond_to_missing?` con el mismo criterio. Si no, el objeto entiende mensajes que dice no entender, y cualquier código que pregunte antes de mandar (`if obj.respond_to?(:x)`) se equivoca.

> 🎓 **Para el parcial, si te preguntan:** *Redefiniste `method_missing`. ¿Qué más tenés que redefinir y por qué?*
> `respond_to_missing?`, con el mismo criterio que `method_missing`. `respond_to?` solo consulta los métodos definidos; sin `respond_to_missing?`, responde `false` para mensajes que el objeto sí atiende dinámicamente, y `method(:nombre)` tampoco los encuentra.

---

## 6. El registrador de mensajes 🔴

Este es el caso central del módulo. Tenés un método de otro que hace cosas con un guerrero:

```ruby
require_relative 'age'

def hacer_combatir(guerrero)      # no sabés qué hace adentro. Recibe un guerrero y devuelve su energía final.
  misil = Misil.new(50)           # un Misil es un Atacante con potencial ofensivo 50
  misil.atacar(guerrero)          # el misil le manda mensajes al guerrero desde adentro de atacar
  guerrero.descansar
  guerrero.energia
end

atila = Guerrero.new(20, 100, 10)
p hacer_combatir(atila)           # => 70     ← 100 − (50 − 10) + 10. Pero ¿qué mensajes recibió atila para llegar a 70?
```

Querés **la lista exacta de mensajes que recibió `atila`**, con sus argumentos, durante ese combate. Sin tocar `Guerrero`, sin tocar `Misil`, sin tocar `hacer_combatir`. Es un problema real: registrar todas las consultas que recibe una conexión a base de datos, todos los mensajes que le llegan a un objeto que se comporta raro, todo lo que un componente le pide a otro.

### La solución a mano, y por qué no sirve

Podrías escribir una clase `GuerreroRegistrado` que tenga *todos* los métodos de `Guerrero`, y en cada uno anote el mensaje y se lo reenvíe a un guerrero de verdad:

```ruby
class GuerreroRegistrado
  def initialize(guerrero) ; @guerrero = guerrero ; @mensajes = [] ; end
  def atacar(otro)        ; @mensajes << :atacar        ; @guerrero.atacar(otro) ; end
  def descansar           ; @mensajes << :descansar     ; @guerrero.descansar    ; end
  def sufri_danio(danio)  ; @mensajes << :sufri_danio   ; @guerrero.sufri_danio(danio) ; end
  # ... y energia, potencial_ofensivo, potencial_defensivo, energia=, y cada método nuevo que le agreguen a Guerrero
end
```

Anda. Y es frágil: repite el mismo código por cada método, y **el día que `Guerrero` gane un método, `GuerreroRegistrado` queda incompleto** sin que nadie avise. Es la clase de código que hay que mantener a mano para siempre.

### La solución con `method_missing`

Si un objeto **no tiene ningún método de guerrero**, todo mensaje de guerrero cae en su `method_missing`. Y desde ahí, anota y reenvía. Un solo método reemplaza a todos:

```ruby
class RegistradorDeMensajes
  attr_reader :mensajes_recibidos            # solo lectura: la lista se consulta, no se reasigna

  def initialize(objeto_original)
    @objeto_original = objeto_original       # el objeto de verdad, al que vamos a reenviar todo
    @mensajes_recibidos = []                 # acá se acumulan los mensajes, en orden
  end

  private def method_missing(nombre, *args)                              # cae acá TODO lo que este objeto no entiende
    @mensajes_recibidos << { mensaje: nombre, argumentos: args }         # 1) anotar: un hash por mensaje
    @objeto_original.send(nombre, *args)                                 # 2) reenviar tal cual, y devolver lo que devuelva
  end                                                                    #    (*args desparrama el array: módulo 1, sección 4)
end
```

(El repo de tu cursada escribe la firma como `method_missing(nombre, *args, &bloque)` y reenvía con `send(nombre, *args, &bloque)`: así el registrador también reenvía el bloque, si el mensaje traía uno. Acá lo omitimos porque ningún mensaje de guerrero lleva bloque; en un registrador de uso general, va.)

Y ahora, en vez de pasarle `atila` al combate, le pasamos un registrador que envuelve a `atila`:

```ruby
atila = Guerrero.new(20, 100, 10)
registrador = RegistradorDeMensajes.new(atila)      # el registrador se pone adelante de atila

p hacer_combatir(registrador)                       # => 70    ← el mismo resultado que antes
p atila.energia                                     # => 70    ← y atila quedó igual que antes: los mensajes le llegaron

registrador.mensajes_recibidos.each { |m| p m }
# Resultado esperado:
# {:mensaje=>:potencial_defensivo, :argumentos=>[]}      ← el misil preguntó, para decidir si el ataque pasa
# {:mensaje=>:potencial_defensivo, :argumentos=>[]}      ← preguntó de nuevo, para calcular el daño
# {:mensaje=>:sufri_danio, :argumentos=>[40]}            ← 50 − 10 = 40 de daño
# {:mensaje=>:descansar, :argumentos=>[]}                ← lo mandó hacer_combatir
# {:mensaje=>:energia, :argumentos=>[]}                  ← ídem
```

Leé eso de nuevo. Los dos `potencial_defensivo` y el `sufri_danio` **los mandó el misil, desde adentro de su método `atacar`**. Nunca escribiste esas líneas, nunca abriste `Atacante`, y aun así ves exactamente qué le pidió al guerrero, con qué argumentos y en qué orden. Eso es lo que no podías hacer de ninguna otra forma.

**¿CÓMO FUNCIONA?** Paso a paso, con el primer mensaje:

1. `misil.atacar(registrador)` ejecuta el `atacar` de `Atacante`, que hace `un_defensor.potencial_defensivo`. Ese `un_defensor` es el registrador.
2. El lookup busca `potencial_defensivo` en `RegistradorDeMensajes`, `Object`, `Kernel`, `BasicObject`. No está en ninguno.
3. Ruby manda `registrador.method_missing(:potencial_defensivo)` con `args = []`.
4. Nuestro `method_missing` agrega `{ mensaje: :potencial_defensivo, argumentos: [] }` a la lista y hace `atila.send(:potencial_defensivo)`.
5. `atila` responde `10`. `method_missing` devuelve ese `10`, así que `un_defensor.potencial_defensivo` vale `10` para el misil, que ni se enteró de que había un intermediario.

🎯 **Pattern en contexto: Decorator (o wrapper).**
**Qué es:** un objeto que envuelve a otro, le reenvía los mensajes, y agrega algo en el camino.
**Por qué lo usamos:** para agregar comportamiento (acá, registrar) sin modificar la clase original ni el código que la usa.
**Dónde lo ves en este código:** `RegistradorDeMensajes` es el decorator; `@objeto_original` es el decorado; `method_missing` + `send` es el reenvío.
**Analogía:** un secretario que anota cada llamado antes de pasártelo. Vos atendés igual; él tiene el registro.
**❌ Sin `method_missing`:** un método por cada mensaje reenviado, a mantener a mano.
**✅ Con `method_missing`:** un solo método reenvía todo, incluidos los mensajes que todavía no existen.

### Las dos mentiras del registrador

El registrador se comporta como un guerrero. Pero si le preguntás, no lo admite:

```ruby
p atila.respond_to?(:descansar)          # => true
p registrador.respond_to?(:descansar)    # => false     ← mentira 1 (la de la sección 5)

p atila.is_a?(Guerrero)                  # => true
p registrador.is_a?(Guerrero)            # => false     ← mentira 2
p registrador.class                      # => RegistradorDeMensajes
```

**Mentira 1** ya sabés arreglarla: el registrador sabe responder lo que el original sabe responder.

```ruby
class RegistradorDeMensajes
  def respond_to_missing?(nombre, include_private = false)
    @objeto_original.respond_to?(nombre, include_private)   # delego la pregunta al original
  end
end

p registrador.respond_to?(:descansar)    # => true      ← arreglada
p registrador.is_a?(Guerrero)            # => false     ← esta sigue igual
```

**Mentira 2** es distinta, y entenderla es entender por qué existe `BasicObject`. `is_a?` **no cae en `method_missing`**, porque el lookup *sí lo encuentra*:

```ruby
p Object.instance_method(:is_a?).owner    # => Kernel    ← is_a? está definido en Kernel, el mixin que Object incluye
p Kernel.instance_methods(false).size     # => 43        ← y como ese hay unos 40 más: to_s, inspect, class, ==, freeze... (el número exacto varía por versión)
p RegistradorDeMensajes.ancestors         # => [RegistradorDeMensajes, Object, Kernel, BasicObject]
```

Toda clase que no declara superclase hereda de `Object`, y `Object` trae puestos 43 métodos vía `Kernel`. El lookup de `is_a?` encuentra el de `Kernel` **antes** de llegar a `BasicObject`, así que nunca se pregunta `method_missing`. El registrador responde `is_a?` con *su propia* respuesta, no con la de `atila`. Podrías redefinir `is_a?` a mano para delegarlo... y `class`, y `to_s`, y los otros 40. Volvemos al problema de la solución a mano.

### `BasicObject`: heredar de casi nada

```ruby
p BasicObject.instance_methods(false)
# => [:!, :!=, :==, :__id__, :__send__, :equal?, :instance_eval, :instance_exec]    ← ocho. Solo lo indispensable.
```

`BasicObject` es la clase que está arriba de `Object`, y tiene ocho métodos en vez de cincuenta. Si el registrador hereda de ahí, **casi nada se encuentra por lookup, y casi todo cae en `method_missing`**:

⚠️ Si venís ejecutando todo en un mismo archivo o consola: Ruby no deja cambiarle la superclase a una clase que ya existe (`TypeError: superclass mismatch for class RegistradorDeMensajes`). Reiniciá la consola, o borrá la definición anterior, antes de correr esta.

```ruby
class RegistradorDeMensajes < BasicObject       # ← el único cambio
  attr_reader :mensajes_recibidos

  def initialize(objeto_original)
    @objeto_original = objeto_original
    @mensajes_recibidos = []
  end

  private def method_missing(nombre, *args)
    @mensajes_recibidos << { mensaje: nombre, argumentos: args }
    @objeto_original.send(nombre, *args)
  end

  def respond_to_missing?(nombre, include_private = false)
    @objeto_original.respond_to?(nombre, include_private)
  end
end

p RegistradorDeMensajes.ancestors        # => [RegistradorDeMensajes, BasicObject]    ← ni Object ni Kernel

atila = Guerrero.new(20, 100, 10)
registrador = RegistradorDeMensajes.new(atila)
hacer_combatir(registrador)

p registrador.respond_to?(:descansar)    # => true       ← las dos mentiras,
p registrador.is_a?(Guerrero)            # => true       ←    arregladas
p registrador.class                      # => Guerrero   ← hasta la clase: class también se delegó
puts registrador                         # => #<Guerrero:0x...>   ← y to_s. Es indistinguible de atila desde afuera
```

Ahora el registrador es **transparente**: todo mensaje, incluidos `is_a?`, `class` y `to_s`, va a `method_missing` y de ahí a `atila`. Por eso existe `BasicObject`: para construir objetos que reenvían todo (proxies, decorators, dobles de test) sin que los métodos de `Object` se interpongan.

**El costo, para que lo tengas claro** 🟡: la transparencia es total, y eso incluye las preguntas *sobre el registrador mismo*.

```ruby
p registrador.mensajes_recibidos.map { |m| m[:mensaje] }.last(4)
# => [:respond_to?, :is_a?, :class, :to_s]      ← las cuatro preguntas de arriba también quedaron registradas
p registrador.respond_to?(:mensajes_recibidos)
# => false        ← atila no entiende mensajes_recibidos, y la pregunta se delegó a atila
```

Con `BasicObject`, `respond_to?` también pasa por `method_missing`, así que **`respond_to_missing?` no se consulta** (lo dejamos igual: es el contrato, y si mañana alguien define `respond_to?` en el registrador, vuelve a valer). Y el registrador "olvida" sus propios métodos cuando le preguntan por ellos, aunque siga entendiéndolos si se los mandás. Es un trade-off: elegís transparencia total sobre poder interrogar al intermediario. Para un registrador, es la elección correcta.

> 🎓 **Para el parcial, si te preguntan:** *¿Por qué `RegistradorDeMensajes` hereda de `BasicObject` y no de `Object`?*
> Porque `Object` incluye `Kernel`, que define `is_a?`, `class`, `to_s` y unos cuarenta métodos más. El lookup los encuentra antes de llegar a `method_missing`, así que el registrador los respondería por sí mismo en vez de reenviarlos. `BasicObject` tiene solo ocho métodos: casi todo cae en `method_missing` y el registrador se vuelve transparente.

---

## 7. El caso mínimo: un objeto que se traga todo 🟡

La misma idea, sin registrar ni reenviar nada. Un `BasicObject` que acepta cualquier mensaje y se devuelve a sí mismo:

```ruby
class DeafObject < BasicObject
  def method_missing(name, *args)
    self                                  # cualquier mensaje: "sí, sí" y seguimos
  end
  def respond_to_missing?(name, include_private)
    true                                  # dice que entiende todo
  end
end

d = DeafObject.new
resultado = d.atacar(1).descansar.lo_que_sea    # nada explota
p resultado.equal?(d)                           # => true    ← cada mensaje devolvió el mismo objeto
```

Sirve como "objeto que no hace nada" cuando un método exige un colaborador y vos no querés dar uno real. Es el `Sordo` de la sección 3, sin el `puts` y con `BasicObject` para que sea sordo de verdad.

---

## 8. Cuándo sí, cuándo no 🟡

`method_missing` es potente y tiene precio. Lo que se evalúa no es saber usarlo, sino saber **cuándo**.

**Lo que te da:** responder mensajes que no existen; atender familias de mensajes por convención de nombre (`comerse_X`); reenviar todo a otro objeto sin enumerar nada.

**Lo que te cuesta:**
- **La interfaz se vuelve invisible.** Leyendo `Guerrero` nadie sabe que entiende `comerse_una_pizza`. No hay `def` que lo diga, el autocompletado no lo ofrece, `methods` no lo lista.
- **Errores tardíos si te olvidás de `super`** (sección 4).
- **`respond_to?` miente si te olvidás de `respond_to_missing?`** (sección 5).
- **Dos lookups completos** por cada mensaje atendido así: el del mensaje y el de `method_missing`. Más lento que un método definido.
- **`send` salta la privacidad.** `objeto.send(:metodo_privado)` funciona. Un reenvío genérico puede exponer lo que la clase original escondía.

**Cuándo sí:** cuando la lista de mensajes es abierta o no la controlás (un proxy, un decorator, un registrador, un doble de test), o cuando una convención de nombres es más expresiva que quince métodos casi iguales. **Cuándo no:** cuando podés escribir el `def`. Un método definido se lee, se busca y se testea; uno dinámico se descubre.

> 🕳️ **Madriguera — de mensaje fantasma a método real**
> Un `method_missing` puede, la primera vez que atiende `comerse_pizza`, *definir* ese método con `define_method` y después invocarlo. La segunda vez el lookup lo encuentra directo, sin `method_missing`. Es una optimización y una forma de "materializar" la interfaz a medida que se usa.
> *Volvé al camino — esto se profundiza aparte, otro día.*

> 🕳️ **Madriguera — `const_missing`**
> Lo mismo que `method_missing` pero para constantes: `Bla::T` con `T` inexistente llama a `Bla.const_missing(:T)`. Solo lo entienden las clases y módulos.
> *Volvé al camino — esto se profundiza aparte, otro día.*

---

## Checkpoint del Módulo 2

Sin respuestas.

1. `atila.volar(3)`: describí el camino completo, desde el lookup hasta el `NoMethodError`, nombrando quién lanza la excepción.
2. ¿Por qué Ruby le manda `method_missing` al objeto en vez de lanzar el error directamente? ¿Qué decisión de diseño hay detrás?
3. Escribí un `method_missing` para `Muralla` que atienda cualquier mensaje que empiece con `reforzar_` sumando 5 al potencial defensivo, y que falle normalmente con cualquier otro mensaje.
4. Tu `method_missing` no llama a `super`. Mostrá una línea de código que se rompe *en silencio* por eso, y explicá por qué es peor que un error.
5. Definiste `method_missing` y `respond_to?` te dice `false`. ¿Qué falta, con qué firma, y por qué `respond_to?` no puede saberlo solo?
6. En el registrador, `is_a?` daba `false` aun con `respond_to_missing?` definido. ¿Por qué `is_a?` no llegaba a `method_missing`, y dónde vive `is_a?`?
7. ¿Qué tiene `BasicObject` que no tiene `Object`, o mejor dicho, qué *no* tiene? ¿Para qué tipo de objeto lo elegirías?
8. Después de `< BasicObject`, `registrador.respond_to?(:mensajes_recibidos)` da `false` aunque el método exista. Explicá por qué y decidí si es un bug o un trade-off aceptable para un registrador.
9. En el combate, dos de los cinco mensajes registrados los mandó el misil. ¿Por qué el registrador los vio, si `hacer_combatir` nunca escribió `potencial_defensivo`?

---

## Qué viene en el Módulo 3

Cambiamos de idea. Hasta acá el objeto decidía sobre mensajes que le llegan; ahora el problema es otro: **las variables**. Una variable que definís afuera de un `def` no se ve adentro, y afuera de un `class` tampoco. Vas a ver por qué (tiene nombre: *scope gates*), qué error da, y por qué eso es un problema real cuando querés "guardar un pedazo de código para después". El módulo 3 es corto y siembra el dolor; el 4 lo cura.

**FIN DEL MÓDULO 2**
