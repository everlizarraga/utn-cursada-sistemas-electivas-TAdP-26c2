# 🎯 APUNTE CORE — clase02 · Mixins: resolución de conflictos
## Parte 1 — La herramienta

**Qué es este apunte.** La clase 2 completa, explicada para entenderla desde cero, pero recortada a lo que la planificación dice que toca: mixins, cómo resuelven conflictos, y cómo se usa eso en Ruby. Todo el código está verificado corriendo.

**Qué quedó afuera, y dónde está.** La historia de estas herramientas y quiénes las inventaron; la comparación con Java, Kotlin, Python y JavaScript; el patrón Decorator; persistencia con ORM; el debate sobre el rol de la clase según cada autor. Todo eso se dio en clase, es valioso como criterio profesional, y está en el apunte maestro (Partes 1 §3-§7, 2 §8, 3 entera, 4 §8). No hace falta para programar con mixins ni para el TP.

**Tres partes.** Esta explica la herramienta. La Parte 2 explica qué pasa cuando dos módulos chocan. La Parte 3 resuelve esos choques en Age of Empires.

---

## 1. El problema que la herencia simple no puede resolver

Age of Empires, en el estado en que quedó la clase 1. Hay unidades que atacan, unidades que defienden, y una que hace las dos cosas:

```
┌──────────────────────┐                      ┌──────────────────────┐
│       Atacante       │                      │       Defensor       │
├──────────────────────┤                      ├──────────────────────┤
│ potencial_ofensivo   │◄─────────┬──────────►│ potencial_defensivo  │
│ atacar(un_defensor)  │          ✗           │ energia              │
└──────────────────────┘          │           │ sufri_danio(danio)   │
          ▲                       │           └──────────────────────┘
          │                       │                      ▲
    ┌─────┴─────┐          ┌──────┴──────┐         ┌─────┴─────┐
    │   Misil   │          │  Guerrero   │         │  Muralla  │
    └───────────┘          └─────────────┘         └───────────┘
```

`Misil` hereda de `Atacante`. `Muralla` hereda de `Defensor`. `Guerrero` necesita ser las dos cosas, y **una clase hereda de una sola superclase**. No hay cableado posible: o repetís código, o le ponés a `Atacante` cosas de defensor que `Misil` no debería tener. La cruz no es un error del dibujo: es el límite de la herramienta.

La salida es no discutir la herencia, sino **agregarle un paso**. Vamos a reemplazar `Atacante` y `Defensor` por otra construcción que `Guerrero` pueda incorporar dos veces sin conflicto. Se llama **mixin**, y en Ruby se escribe `module`.

---

## 2. `module` e `include`

### El código

Lo primero es el código, porque la diferencia con la clase 1 es una palabra:

```ruby
module Atacante                          # 'module' en vez de 'class'
  attr_accessor :potencial_ofensivo

  def atacar(un_defensor)
    if self.potencial_ofensivo > un_defensor.potencial_defensivo
      danio = self.potencial_ofensivo - un_defensor.potencial_defensivo
      un_defensor.sufri_danio(danio)     # sufri_danio no está acá: lo tiene que traer el defensor
    end
  end
end

module Defensor
  attr_accessor :potencial_defensivo, :energia

  def sufri_danio(danio)
    self.energia = self.energia - danio
  end
end

class Guerrero
  include Atacante                       # "Guerrero es Atacante": trae todo lo que Atacante define
  include Defensor                       # y también es Defensor. Dos includes, ningún problema

  def initialize(potencial_ofensivo = 20, energia = 100, potencial_defensivo = 10)
    self.potencial_ofensivo  = potencial_ofensivo
    self.energia             = energia
    self.potencial_defensivo = potencial_defensivo
  end
end

class Misil
  include Atacante
  def initialize(potencial_ofensivo = 200)
    self.potencial_ofensivo = potencial_ofensivo
  end
end

class Muralla
  include Defensor
  def initialize(potencial_defensivo = 50, energia = 200)
    self.potencial_defensivo = potencial_defensivo
    self.energia             = energia
  end
end

# ¿CÓMO FUNCIONA?
atila   = Guerrero.new            # po 20, energia 100, pd 10
vikingo = Guerrero.new(70)        # po 70
vikingo.atacar(atila)             # 70 > 10 → danio = 70 - 10 = 60 → atila.sufri_danio(60)
atila.energia                     # Resultado esperado: 40

Atacante.new                      # Resultado esperado: NoMethodError — undefined method `new' for Atacante:Module
```

Adentro de un `module` se escribe exactamente lo mismo que adentro de una `class`: métodos, `attr_accessor`, estado. Lo que cambia es cómo se usa desde afuera.

### Las reglas

- **Un módulo no se instancia.** `Atacante.new` no existe. El módulo es comportamiento para agregarle a una clase, no una cosa que exista sola.
- **De un módulo no se hereda.** `class X < Atacante` falla con `TypeError`. La herencia es entre clases; los módulos se *incluyen*.
- **Una clase incluye tantos módulos como quiera**, y un módulo puede ser incluido por tantas clases como quiera. Ahí está la diferencia con la herencia, que sigue siendo simple: **una clase hereda de una única superclase e incluye N módulos.**
- **Un módulo puede incluir otros módulos.** Lo vas a necesitar en la Parte 3.
- **La herencia no se toca.** `Guerrero` sigue heredando de `Object` como siempre. Los módulos se montan encima; si una clase no incluye ninguno, todo es exactamente igual que en la clase 1.

El diagrama con la notación de la cátedra: **flecha de una punta es herencia; flecha de dos puntas es inclusión.**

```
┌──────────────────────┬────┐                 ┌──────────────────────┬────┐
│       Atacante       │    │                 │       Defensor       │    │
├──────────────────────┼────┤                 ├──────────────────────┼────┤
│ potencial_ofensivo   │    │                 │ potencial_defensivo  │    │
│ atacar               │    │◄◄──────┬──────►►│ energia              │    │
└──────────────────────┴────┘        │        │ sufri_danio          │    │
          ▲▲                         │        └──────────────────────┴────┘
          ││                         │                    ▲▲
    ┌─────┴┴────┐             ┌──────┴──────┐        ┌────┴┴─────┐
    │   Misil   │             │  Guerrero   │        │  Muralla  │
    └───────────┘             └─────────────┘        └───────────┘
```

Las cajas de los módulos tienen dos columnas. La izquierda es lo que el módulo **provee**: sus métodos. La derecha, lo que **requiere**: métodos que no implementa pero que necesita que la clase le dé. Por ahora está vacía; en la Parte 3 va a dejar de estarlo.

---

## 3. Un paréntesis de Ruby: `@`, `attr_accessor` y `self.`

El código de arriba usa tres cosas que se parecen y no son lo mismo, y que hasta ahora nadie explicó. Van con un ejemplo aparte, para no mezclarlas con el dominio.

```ruby
class Lampara
  def initialize
    @encendida = false      # @encendida: variable de INSTANCIA. Vive adentro de cada objeto Lampara
    aviso = "creada"        # aviso: variable LOCAL. Muere cuando termina initialize
  end
end
```

**`@nombre` es una variable de instancia.** El arroba significa *"esto es estado del objeto"*: cada objeto tiene la suya y sobrevive entre llamadas. Sin arroba es una variable local del método y desaparece al salir. Dos propiedades más: una `@variable` que nunca se asignó vale `nil` (y `nil` cuenta como falso, sin error); y **no se ve desde afuera**: `lampara.@encendida` no existe.

Para que otro objeto la lea o la escriba hace falta un método. **`attr_accessor :encendida` es un atajo que escribe esos dos métodos por vos**, y nada más:

```ruby
class Lampara
  attr_accessor :encendida  # equivale EXACTAMENTE a escribir:
                            #   def encendida;         @encendida;         end   ← getter
                            #   def encendida=(valor); @encendida = valor; end   ← setter
end

l = Lampara.new
l.encendida = true          # llama al setter → @encendida = true
l.encendida                 # llama al getter → Resultado esperado: true
```

**El `@` es la variable; `attr_accessor` son los métodos para llegar a ella.** Dos capas, no dos formas de declarar lo mismo. (`attr_reader` genera solo el getter; `attr_writer` solo el setter.)

Adentro de un método, `self.encendida` es lo mismo que `l.encendida` desde afuera: **llama al método**, no toca la variable. Por eso en `Atacante` se escribe `self.potencial_ofensivo` y `self.energia = ...`. Y la trampa que más se ve en un TP:

```ruby
def apagar
  encendida = false         # ✗ SIN self: crea una variable LOCAL llamada encendida. El objeto no cambia
  self.encendida = false    # ✔ CON self: llama al setter
end
```

Para asignar por el setter, el `self.` es obligatorio. Para leer, Ruby lo perdona si no hay una local con ese nombre, pero por consistencia se usa siempre. Cuándo conviene tocar `@x` directo en vez de `self.x` lo vas a ver en la Parte 3, cuando el código lo pida.

---

## 4. Qué es un mixin

Ahora que viste uno, la definición.

**Un mixin es un paquete de comportamiento —y en Ruby también de estado— que no se instancia, que una clase incluye entero, y que puede combinarse con otros mixins en la misma clase.** Se puede pensar de dos maneras, y las dos sirven:

- **Como un paquete de modificaciones.** Todo lo que harías al extender una clase —agregar métodos, sobreescribir otros, declarar atributos— empaquetado aparte, sin decidir todavía a qué clase se lo aplicás. `Atacante` es "lo que le tiene que pasar a una clase para que sepa atacar".
- **Como una función de clases.** Recibe una clase, devuelve otra con los cambios aplicados. `Guerrero` es lo que da aplicarle `Atacante` y después `Defensor` a una clase vacía.

Y tres propiedades que conviene tener nombradas:

1. **No se instancia.** Es comportamiento para incluir, no una entidad del dominio.
2. **Admite múltiples inclusiones.** N mixins por clase, N clases por mixin.
3. **Es independiente de quien lo usa.** `Atacante` no sabe que existe `Guerrero`. La clase decide incluirlo y decide con qué otros lo combina.

### Complemento, no reemplazo

Lo más importante y lo que más cuesta ver: **los mixins no vienen a reemplazar la herencia, vienen a montarse encima.** Seguís teniendo clases, `<`, y una única superclase. Lo que se agrega es un paso más en la búsqueda de métodos: antes de subir a la superclase, se pasa por los mixins. Si una clase no incluye ninguno, ese paso está vacío y todo es la herencia de siempre.

**El caso base de "tener mixins" es la herencia simple.** Vos siempre tuviste mixins; la lista estaba vacía.

Eso tiene una consecuencia práctica: **todo lo que sabés de herencia sigue valiendo.** Sobreescribir, llamar a `super`, especializar. Los mixins agregan situaciones nuevas —qué pasa cuando dos traen lo mismo— y esas son el tema de la Parte 2. Pero no borran nada de lo anterior.

---

## ✅ Checkpoint — Parte 1

*Sin respuestas.*

1. ¿Qué tiene que cambiar en `Atacante` y en `Guerrero` para que el guerrero pueda ser las dos cosas? ¿Cuántas palabras?
2. ¿Qué diferencia hay entre `@energia`, `energia` y `self.energia` adentro de un método?
3. ¿Por qué `energia = 100` adentro de un método no cambia el objeto?
4. ¿Qué genera `attr_accessor :energia`, exactamente?
5. ¿Qué significa que "el caso base de tener mixins es la herencia simple"?

---

**FIN DE LA PARTE 1 — La herramienta**
