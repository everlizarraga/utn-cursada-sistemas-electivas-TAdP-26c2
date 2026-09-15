# Clase desde Cero — Clase 04 (2020) — Módulo 3
## Contexto y scope gates

> **Sobre este documento.** Es corto y tiene un solo objetivo: que entiendas **qué ve y qué no ve** una línea de código según dónde esté escrita. Qué es el contexto, cuáles son las tres construcciones que lo cortan, cómo se lee el `NameError` que eso produce, y por qué Ruby dice "variable *o* método" en ese error. Termina planteando un problema que este módulo no resuelve a propósito.
> **No cubre:** la solución. Bloques, procs, `define_method` y `Class.new` son el módulo 4.

> **De dónde venís.** Del módulo 1: `puts` es un mensaje a `self`, y en un archivo suelto `self` es `main`. De las clases 01 a 03: `def`, `class`, `module`, variables de instancia `@algo`.

---

## 1. Cada punto del programa tiene un contexto 🔴

Una **variable local** nace cuando le asignás algo por primera vez, y desde ese momento existe en el lugar donde nació. A ese lugar lo llamamos **contexto** (en inglés, *scope*): el conjunto de nombres que una línea de código puede usar.

```ruby
nombre = "atila"          # acá nace la variable local nombre
puts nombre               # => atila     ← esta línea está en el mismo contexto: la ve

p local_variables         # => [:nombre]  ← Ruby te dice qué variables locales hay en el contexto actual
```

Pensalo como una mesa de trabajo: lo que apoyás en la mesa lo tenés a mano mientras estés en esa mesa.

---

## 2. `def` corta el contexto 🔴

Ahora la misma variable, y un método que intenta usarla:

```ruby
nombre = "atila"

def presentarse            # ← acá empieza OTRA mesa
  puts nombre              # esta línea NO ve la variable nombre de afuera
end

presentarse
# => NameError: undefined local variable or method 'nombre' for main:Object
```

Adentro de `def` empieza un contexto nuevo, **vacío**. Las variables locales que había afuera no entran. Lo único que un método ve son sus parámetros y las variables que él mismo cree.

Leé el mensaje de error con atención, porque dice exactamente qué pasó:

```
undefined local variable or method 'nombre' for main:Object
           ↑                                    ↑
   "no encontré una variable local              "así que lo traté como un mensaje a self,
    llamada nombre..."                            que acá es main, y main tampoco lo entiende"
```

Ese "variable *o* método" es la sección 6. Guardalo.

---

## 3. `class` y `module` también cortan 🔴

No es solo `def`. Abrir una clase o un módulo también abre una mesa nueva:

```ruby
nombre = "atila"

class Guerrero
  puts nombre              # el cuerpo de la clase tampoco ve la variable de afuera
end
# => NameError: undefined local variable or method 'nombre' for Guerrero:Class
#                                                                 ↑ fijate: acá self es la clase Guerrero, no main

module Atacante
  puts nombre
end
# => NameError: undefined local variable or method 'nombre' for Atacante:Module
```

Las tres construcciones que crean un contexto nuevo se llaman **scope gates** (compuertas de contexto):

```
   contexto exterior:  nombre = "atila"
   ┌──────────────────────────────────────────────────────────────┐
   │                                                              │
   │   class Guerrero      module Atacante      def presentarse   │
   │   ┌────────────┐      ┌────────────┐       ┌────────────┐    │
   │   │  contexto  │      │  contexto  │       │  contexto  │    │
   │   │   NUEVO    │      │   NUEVO    │       │   NUEVO    │    │
   │   │  (vacío)   │      │  (vacío)   │       │  (vacío)   │    │
   │   └────────────┘      └────────────┘       └────────────┘    │
   │       ▲ gate              ▲ gate               ▲ gate        │
   └──────────────────────────────────────────────────────────────┘
```

**Son exactamente tres: `class`, `module` y `def`.** Cada vez que Ruby cruza una de esas palabras, deja atrás todas las variables locales. Nada más las cruza.

Una aclaración que evita una confusión: las variables de instancia (`@energia`) **no viven en el contexto**, viven en el objeto. Por eso un método las ve aunque `def` haya cortado todo: no las está sacando del contexto de afuera, se las está pidiendo a `self`.

```ruby
class Guerrero                # un Guerrero mínimo, solo para este ejemplo (sin age.rb)
  def initialize
    @energia = 100          # se guarda en el objeto que se está creando
  end
  def energia
    @energia                # otro método, otro contexto, pero el mismo objeto: la ve
  end
end
p Guerrero.new.energia      # => 100
```

---

## 4. Lo que está adentro tampoco sale 🟡

La compuerta corta en las dos direcciones. Lo que un método crea, muere cuando el método termina:

```ruby
def crear
  secreto = 42              # nace adentro de crear
  secreto                   # el método devuelve su valor...
end

p crear                     # => 42       ← el VALOR salió, como retorno
puts secreto                # => NameError: undefined local variable or method 'secreto' for main:Object
                            #    ...pero la VARIABLE no. Afuera no existe.
```

---

## 5. Lo que no corta 🟡

`if`, `while`, `case`, `begin` **no son scope gates**. Lo que definís adentro de un `if` sigue existiendo después:

```ruby
if true
  adentro_del_if = "sí se ve"
end
puts adentro_del_if         # => sí se ve     ← el if no abrió ningún contexto nuevo
```

Vale la pena tenerlo claro porque en otros lenguajes es distinto, y porque marca el contraste: en Ruby, las únicas compuertas son las tres palabras de la sección 3.

> **Hilo abierto.** ¿Y un bloque, el `do … end` de un `each`? Ese es el caso interesante: no es una compuerta para *leer* variables de afuera, pero las que se crean adentro **tampoco salen**. Es un contexto a medias, y esa "medias" es todo el módulo 4.

---

## 6. "Variable *o* método": el orden en que Ruby resuelve un nombre 🔴

Volvamos al mensaje de error. Ruby dice `undefined local variable or method` porque cuando ve un nombre suelto, sin receptor, sin paréntesis y sin argumentos, hace **dos intentos en orden**:

1. ¿Hay una **variable local** con ese nombre en el contexto actual? → la usa.
2. Si no hay, lo trata como un **mensaje a `self`** → hace el lookup.
3. Si el lookup tampoco encuentra nada → `NameError` nombrando las dos cosas que intentó.

Esto tiene una consecuencia que te va a morder:

```ruby
class X
  def m
    saraza = 15             # variable local saraza
    saraza                  # ← Ruby encuentra la VARIABLE primero. Nunca mira el método.
  end

  def m2
    saraza                  # ← acá no hay variable con ese nombre: lo trata como mensaje a self
  end

  def saraza
    10
  end
end

p X.new.m                   # => 15    ← la variable tapó al método
p X.new.m2                  # => 10    ← sin variable, llegó al método
```

⚠️ **Trampa:** si nombrás una variable local igual que un método del objeto, dentro de ese contexto **el método deja de ser alcanzable sin receptor**. `self.saraza` lo alcanzaría igual, porque con receptor explícito Ruby no busca variables. Por eso en `age.rb` vas a ver `self.energia = energia - danio` y no `energia = energia - danio`: sin el `self.`, esa línea crearía una variable local nueva llamada `energia` en vez de llamar al setter, y como esa variable recién nace vale `nil`, el lado derecho explota con `undefined method '-' for nil`.

> 🎓 **Para el parcial, si te preguntan:** *¿Qué significa el error `undefined local variable or method`?*
> Que Ruby encontró un nombre suelto, buscó primero una variable local con ese nombre en el contexto actual, no la encontró, lo trató como un mensaje a `self`, y `self` tampoco lo entiende. El error nombra las dos cosas que intentó, en ese orden.

---

## 7. `self` también es parte del contexto 🟡

Cada compuerta no solo vacía las variables: también cambia **quién es `self`**.

```ruby
puts self                   # => main         ← en el archivo suelto

class Guerrero
  puts self                 # => Guerrero     ← adentro del cuerpo de la clase, self es la clase
  def quien_soy
    self                    # adentro de un método de instancia, self es la instancia que recibió el mensaje
  end
end

p Guerrero.new.quien_soy.class    # => Guerrero
```

Entonces un contexto tiene dos cosas: las **variables locales** que puede usar, y el **`self`** al que le llegan los mensajes sin receptor. Las compuertas resetean las dos. Esto importa porque en el módulo 5 vamos a cambiar `self` a propósito, desde afuera, y hay que saber que es una pieza del contexto y no una constante.

---

## 8. El problema que esto crea 🔴

Con todo lo anterior, el problema concreto. Querés **guardar un pedazo de código para ejecutarlo más tarde**, y querés que ese código use las variables que tenés a mano ahora.

Primer intento, con `def`:

```ruby
nombre = "atila"

def saludar                 # "guardo" el código en un método, para llamarlo después
  puts "Hola " + nombre     # ← pero def cortó el contexto: nombre no está
end

saludar
# => NameError: undefined local variable or method 'nombre' for main:Object
```

Segundo intento, con `class`, porque a lo mejor quiero que ese código sea el cuerpo de una clase:

```ruby
nombre = "atila"

class Presentacion
  puts "Hola " + nombre     # ← class también cortó. Mismo error.
end
# => NameError: undefined local variable or method 'nombre' for Presentacion:Class
```

Las tres herramientas que Ruby te da para "empaquetar código" (`def`, `class`, `module`) son, justamente, las tres que **cortan el contexto**. Empaquetás y perdés las variables. Es una contradicción de diseño, y no tiene salida con lo que sabés hasta acá.

Lo que hace falta es algo que empaquete código **sin cruzar una compuerta**: que se lleve las variables de la mesa donde nació, y las siga viendo cuando lo ejecutes, en otro momento y en otro lugar. Eso existe, tiene tres formas (bloques, procs y lambdas), y es el módulo 4.

---

## Checkpoint del Módulo 3

Sin respuestas.

1. Nombrá las tres scope gates de Ruby. ¿`if` es una? ¿Un bloque `do … end` lo es?
2. Este código falla: `x = 1; def m; x; end; m`. Escribí el mensaje de error completo y explicá cada mitad.
3. ¿Por qué un método puede usar `@energia` si `def` cortó el contexto? ¿Dónde vive `@energia`?
4. En `def m; saraza = 15; saraza; end`, con un método `saraza` que devuelve 10, ¿qué devuelve `m` y por qué? ¿Cómo alcanzarías al método igual?
5. Explicá por qué en `age.rb` se escribe `self.energia = energia - danio` y qué pasaría con `energia = energia - danio`.
6. ¿Qué dos cosas forman el contexto de un punto del programa? ¿Qué vale cada una adentro del cuerpo de `class Guerrero`?
7. Describí, con tus palabras, el problema de la sección 8: qué querés hacer y por qué `def` y `class` no sirven.

---

## Qué viene en el Módulo 4

La respuesta al problema. Un **proc** es un objeto que guarda un pedazo de código sin ejecutarlo, y que **se lleva el contexto donde fue creado**: ve las variables de afuera, las puede modificar, y cuando lo ejecutás más tarde las sigue viendo. Vas a ver cómo se crea, cómo se ejecuta (`call`), cómo se pasa a un método (`yield` y `&bloque`), qué diferencia hay entre un proc y una lambda, y cómo con eso Ruby te deja definir métodos y clases **sin** cruzar una compuerta: `define_method` y `Class.new`. Es el módulo más largo, y es donde la clase empieza a cerrar.

**FIN DEL MÓDULO 3**
