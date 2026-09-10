# 🔧 PROYECTO-00 — Sintaxis de Ruby con las manos

**Materia:** TADP · **Alcance:** la sintaxis que usa el código de las clases 1 y 2
**Dónde se hace:** tu proyecto `proyecto-cero-ruby` en RubyMine
**Duración:** 1-2 sesiones. Si te lleva más, algo se fue de scope — avisá.

---

## Sobre este documento

**Qué es.** Un mini-proyecto para que escribas Ruby con los dedos hasta que la sintaxis deje de frenarte. No enseña diseño ni conceptos de la materia: enseña a tipear.

**Qué cubre.** Exactamente las construcciones que aparecen en el código de la cátedra: `class`/`end`, `attr_accessor`, símbolos, `self.`, `initialize` con valores por defecto, herencia, `super`, `module` + `include`, `alias_method`, `ancestors`, bloques, `each`, `select`, y bloques guardados como objetos.

**Qué NO cubre.** Nada que el código de la cátedra no use. Sin gemas, sin RSpec, sin archivos múltiples, sin metaprogramación. Todo corre en un archivo suelto.

**El dominio es otro a propósito.** Acá se trabaja con vehículos, no con guerreros. La forma es la misma; los nombres son distintos para que cuando vuelvas al código real lo leas, no lo recites.

**Cómo se usa.** Cada bloque tiene un **ejemplo resuelto** (lo copiás, lo corrés, lo mirás) y un **tu turno** (lo escribís vos). El resultado esperado va comentado al lado: no necesitás ejecutar para saber qué debería dar, pero ejecutá igual — la idea es que tus dedos aprendan.

**Si te trabás más de 15 minutos en un ejercicio:** andá a los hints del final. Están escalonados. Si igual no sale, pasá al siguiente y avisame.

---

## Bloque 0 — 🔴 Crear y correr un archivo

En el panel Project (izquierda), botón derecho sobre la carpeta **proyecto-cero-ruby** → **New** → **Ruby File**. Nombre: `practica`. RubyMine le pone el `.rb` solo.

Escribí esto y nada más:

```ruby
puts "arranca"
```

Para correrlo: botón derecho sobre el editor → **Run 'practica'**. O el triángulo verde de la barra de arriba.

**✅ Deberías ver:** una ventana abajo (Run) con `arranca` y después `Process finished with exit code 0`.

Si eso salió, todo lo demás de este documento se hace igual: escribís en `practica.rb`, apretás correr, mirás abajo.

> 🕳️ **Madriguera — `puts` vs `p`**
> `puts` imprime para humanos (sin comillas, una línea por elemento). `p` imprime para programadores (te muestra el objeto tal cual, con comillas y símbolos visibles). En la práctica: usá `puts` para leer resultados, `p` cuando quieras ver *qué tipo de cosa* es lo que tenés.
> *Volvé al camino.*

---

## Bloque 1 — 🔴 Clases, estado y `self.`

Este es el bloque más importante de todos. La trampa que tiene adentro es la que más te va a morder.

### Ejemplo resuelto

Copiá esto entero, reemplazando lo que tenías, y corrélo.

```ruby
class Auto
  # attr_accessor genera de un saque el getter y el setter de cada variable.
  # Los nombres se pasan como SÍMBOLOS: dos puntos adelante, sin comillas.
  # Gracias a esto podés hacer un_auto.marca (leer) y un_auto.marca = "x" (escribir).
  attr_accessor :marca, :velocidad

  # initialize es el constructor: se ejecuta al hacer Auto.new(...).
  # velocidad = 0 es un valor por defecto: si no te lo pasan, vale 0.
  def initialize(marca, velocidad = 0)
    self.marca = marca          # self.marca= es el SETTER. Sin el self. esto no funcionaría (ver abajo).
    self.velocidad = velocidad
  end

  def frenar
    self.velocidad = 0
  end

  def acelerar_a(nueva_velocidad)
    self.velocidad = nueva_velocidad
  end

  # Un método sin parámetros no lleva paréntesis en la definición.
  # Y en Ruby NO se escribe return: el valor de la última línea es lo que devuelve.
  def velocidad_maxima
    180
  end
end

mi_auto = Auto.new("Peugeot")   # los paréntesis del new son opcionales, pero usalos

puts mi_auto.marca              # Peugeot
puts mi_auto.velocidad          # 0
puts mi_auto.velocidad_maxima   # 180

mi_auto.acelerar_a(120)
puts mi_auto.velocidad          # 120

mi_auto.frenar
puts mi_auto.velocidad          # 0

# ¿CÓMO FUNCIONA?
# 1. Auto.new("Peugeot") reserva un objeto nuevo y le manda initialize con "Peugeot".
# 2. initialize completa el estado interno del objeto: @marca y @velocidad.
#    Esas variables con arroba son las variables de instancia; attr_accessor
#    te dio los métodos para tocarlas sin escribir @ nunca.
# 3. Cada mensaje (mi_auto.frenar) busca el método en la clase del objeto y lo ejecuta.
```

### ⚠️ La trampa del `self.` — leela dos veces

Dentro de un método, escribir `velocidad = 0` **no toca el objeto**. Ruby lo interpreta como "creá una variable local llamada velocidad, que muere apenas termina el método". El objeto queda intacto y no salta ningún error: el código anda y no hace nada.

```ruby
def frenar
  velocidad = 0        # ✗ crea una variable local y la tira. El auto sigue a 120.
end

def frenar
  self.velocidad = 0   # ✓ manda el mensaje velocidad= al objeto. El auto frena.
end
```

Para **leer** podés escribir `velocidad` o `self.velocidad`, las dos andan. Para **escribir** el `self.` es obligatorio. Regla práctica mientras aprendés: poné `self.` siempre y no pensás más.

Este bug exacto está en el código que publicó la cátedra. Cuando lo veas, lo vas a reconocer.

### 🟡 Tu turno 1.1

Escribí una clase `Bicicleta` con:
- Un estado: `rodado` y `velocidad`.
- Constructor que reciba el rodado y arranque siempre en velocidad 0.
- Un método `pedalear` que le sume 5 a la velocidad.
- Un método `frenar` que la deje en 0.

```ruby
class Bicicleta
  # TODO: attr_accessor

  def initialize(rodado)
    # TODO: guardar rodado y arrancar la velocidad en 0
  end

  def pedalear
    # TODO: sumarle 5 a la velocidad
    # Pista: self.velocidad = self.velocidad + 5
    #        (o self.velocidad += 5, que es lo mismo escrito corto)
  end

  def frenar
    # TODO
  end
end

# Cuando esté lista, corré esto sin tocarlo:
bici = Bicicleta.new(29)
puts bici.rodado      # 29
puts bici.velocidad   # 0
bici.pedalear
bici.pedalear
puts bici.velocidad   # 10
bici.frenar
puts bici.velocidad   # 0
```

### 🟡 Tu turno 1.2

Agregale a `Bicicleta` un método `parada?` que devuelva `true` si la velocidad es 0 y `false` si no.

```ruby
# Dentro de la clase Bicicleta:
def parada?
  # TODO: una sola línea, sin if. Acordate: la última expresión es lo que devuelve.
end

# Verificación:
bici = Bicicleta.new(26)
puts bici.parada?     # true
bici.pedalear
puts bici.parada?     # false
```

> 🕳️ **Madriguera — el `?` en el nombre**
> En Ruby el signo de pregunta es parte del nombre del método, no sintaxis especial. Es una convención: los métodos que devuelven true o false terminan en `?`. Hay otra convención con `!` para métodos "peligrosos" (que modifican el objeto). Nada de esto cambia el comportamiento, solo se lee mejor.
> *Volvé al camino.*

---

## Bloque 2 — 🔴 Herencia y `super`

### Ejemplo resuelto

```ruby
class AutoDeCarrera < Auto      # el < significa "hereda de". Auto ya está definido arriba.

  attr_accessor :spoiler

  def initialize(marca, spoiler)
    super(marca)                # llama al initialize de Auto con ese argumento
    self.spoiler = spoiler      # y después agrega lo propio
  end

  # Pisamos el método del padre y lo reusamos al mismo tiempo:
  def velocidad_maxima
    super + 120                 # super acá devuelve 180 (el de Auto), así que esto da 300
  end
end

ferrari = AutoDeCarrera.new("Ferrari", "alerón trasero")

puts ferrari.marca              # Ferrari       <- método heredado de Auto
puts ferrari.spoiler            # alerón trasero
puts ferrari.velocidad_maxima   # 300
ferrari.acelerar_a(250)
puts ferrari.velocidad          # 250           <- también heredado

# ¿CÓMO FUNCIONA?
# Cuando le mandás velocidad_maxima al ferrari, Ruby busca el método en AutoDeCarrera.
# Lo encuentra, lo ejecuta, y al llegar a super sigue buscando hacia arriba (en Auto),
# ejecuta ESE, y usa lo que devolvió. A eso se le dice method lookup.
```

### ⚠️ `super` vs `super()`

- `super` **a secas** reenvía automáticamente los mismos argumentos que recibió tu método.
- `super()` **con paréntesis vacíos** llama al método del padre **sin argumentos**.

No son lo mismo y confundirlos da errores de cantidad de argumentos difíciles de leer. En el código de la cátedra vas a ver `super()` escrito así a propósito.

### 🟡 Tu turno 2.1

Hacé una clase `BicicletaElectrica` que herede de `Bicicleta`:
- Además del rodado, recibe la `potencia_bateria`.
- Pisa `pedalear` para que sume 5 (el pedaleo normal, reusando el del padre) **más** la potencia de la batería.

```ruby
class BicicletaElectrica < Bicicleta
  # TODO: attr_accessor de potencia_bateria

  def initialize(rodado, potencia_bateria)
    # TODO: delegá el rodado al padre y guardá la potencia
  end

  def pedalear
    # TODO: usá super para el pedaleo normal, y después sumá la batería
  end
end

# Verificación:
ebike = BicicletaElectrica.new(29, 15)
ebike.pedalear
puts ebike.velocidad     # 20      (5 del pedaleo + 15 de batería)
puts ebike.parada?       # false   <- heredado del abuelo... no, del padre. Es de Bicicleta.
```

---

## Bloque 3 — 🔴 Módulos y mixins

Este es el corazón de las clases 1 y 2. Acá la sintaxis se pone rara y conviene tenerla en los dedos antes de discutir diseño.

### Ejemplo resuelto — un módulo suelto

```ruby
# Un module se escribe casi igual que una clase, pero NO se puede instanciar.
# No existe Motorizado.new. Es un paquete de comportamiento para meter adentro de clases.
module Motorizado

  attr_accessor :potencia_motor

  def acelerar
    self.velocidad += self.potencia_motor
  end

  def tipo_de_impulso
    "motor"
  end
end

class Camioneta
  include Motorizado            # acá se inyecta todo lo que Motorizado define

  attr_accessor :velocidad

  def initialize
    self.velocidad = 0
    self.potencia_motor = 40    # este setter vino del módulo, no de la clase
  end
end

camioneta = Camioneta.new
camioneta.acelerar
puts camioneta.velocidad        # 40
puts camioneta.tipo_de_impulso  # motor
```

### Ejemplo resuelto — dos módulos que chocan

```ruby
module Pedaleable
  attr_accessor :fuerza_piernas

  def acelerar
    self.velocidad += self.fuerza_piernas
  end

  def tipo_de_impulso
    "piernas"
  end
end

class Ciclomotor
  include Motorizado
  include Pedaleable            # ¡los dos definen acelerar! ¿cuál gana?

  attr_accessor :velocidad

  def initialize
    self.velocidad = 0
    self.potencia_motor = 30
    self.fuerza_piernas = 5
  end
end

ciclo = Ciclomotor.new
ciclo.acelerar
puts ciclo.velocidad            # 5     <- ganó Pedaleable, el ÚLTIMO include

p Ciclomotor.ancestors
# [Ciclomotor, Pedaleable, Motorizado, Object, Kernel, BasicObject]
#      ↑           ↑            ↑
#     yo      último include  primer include
#
# ancestors te muestra la cadena real de búsqueda, en orden.
# Se lee de izquierda a derecha: Ruby pregunta en cada uno hasta encontrar el método.
# Por eso el último include gana: quedó más cerca tuyo en la cadena.
```

### Ejemplo resuelto — `alias_method` para usar los dos

```ruby
class Ciclomotor
  include Motorizado
  alias_method :acelerar_con_motor, :acelerar     # le pongo un segundo nombre al de Motorizado

  include Pedaleable
  alias_method :acelerar_con_piernas, :acelerar   # ídem con el de Pedaleable

  attr_accessor :velocidad

  def initialize
    self.velocidad = 0
    self.potencia_motor = 30
    self.fuerza_piernas = 5
  end

  # Y ahora defino el mío, que usa los dos:
  def acelerar
    self.acelerar_con_motor
    self.acelerar_con_piernas
  end
end

ciclo = Ciclomotor.new
ciclo.acelerar
puts ciclo.velocidad            # 35    (30 del motor + 5 de las piernas)

# ¿CÓMO FUNCIONA?
# alias_method :nombre_nuevo, :nombre_viejo copia el método que hoy responde a
# :nombre_viejo y lo deja también disponible bajo :nombre_nuevo.
# Los dos argumentos son SÍMBOLOS.
# El orden importa muchísimo: el alias tiene que escribirse DESPUÉS del include
# que trajo ese método, porque copia lo que hay disponible en ese momento exacto.
```

### 🟡 Tu turno 3.1

Creá un módulo `Sonoro` con:
- Un estado `volumen_bocina`.
- Un método `tocar_bocina` que devuelva la cadena `"PIII"` repetida según el volumen. Para repetir un string en Ruby: `"PIII" * 3` devuelve `"PIIIPIIIPIII"`.

Después incluílo en `Camioneta` y probalo.

```ruby
module Sonoro
  # TODO
end

# Verificación (agregá el include y seteá el volumen en el initialize):
camioneta = Camioneta.new
puts camioneta.tocar_bocina     # PIIIPIII   (si pusiste volumen 2)
```

### 🟡 Tu turno 3.2 — el ejercicio que importa

Armá una clase `Hibrido` que:
- Incluya `Motorizado` y `Pedaleable`.
- Al acelerar, use **los dos** impulsos, igual que el Ciclomotor.
- Pero además, imprima con qué aceleró.

Escribilo **sin mirar** el ejemplo del Ciclomotor. Volvé a mirarlo solo si te trabás.

```ruby
class Hibrido
  # TODO: los dos include, los dos alias_method, el attr_accessor, el initialize
  # TODO: def acelerar que use los dos y además haga puts "acelerando con motor y piernas"
end

# Verificación:
hibrido = Hibrido.new
hibrido.acelerar                # acelerando con motor y piernas
puts hibrido.velocidad          # 35
p Hibrido.ancestors             # [Hibrido, Pedaleable, Motorizado, Object, Kernel, BasicObject]
```

### 🟡 Tu turno 3.3

Sin ejecutar nada, escribí en un comentario qué te parece que va a imprimir esto. Después corrélo y comparalo.

```ruby
class Raro
  include Pedaleable
  include Motorizado            # ojo: el orden está al revés que en Ciclomotor

  attr_accessor :velocidad

  def initialize
    self.velocidad = 0
    self.potencia_motor = 30
    self.fuerza_piernas = 5
  end
end

raro = Raro.new
raro.acelerar
puts raro.velocidad             # ¿?
puts raro.tipo_de_impulso       # ¿?
```

---

## Bloque 4 — 🔴 Bloques

Un bloque es un pedazo de código que le pasás a un método para que lo ejecute. Es la construcción más usada de Ruby y la que más rara se ve al principio.

### Ejemplo resuelto — recorrer y filtrar

```ruby
autos = [Auto.new("Fiat"), Auto.new("Ford"), Auto.new("Renault")]
# Los corchetes crean un Array. Los índices arrancan en 0.

# each ejecuta el bloque UNA VEZ POR ELEMENTO. No devuelve nada útil: se usa por su efecto.
autos.each { |auto| puts auto.marca }
# Fiat
# Ford
# Renault
#
# Lo que va entre | | es el parámetro del bloque: el nombre con el que
# vas a referirte a cada elemento adentro. Lo elegís vos.

# Con do ... end es exactamente lo mismo, se usa cuando el bloque tiene varias líneas:
autos.each do |auto|
  auto.acelerar_a(100)
  puts "#{auto.marca} va a #{auto.velocidad}"
end
# Fiat va a 100
# Ford va a 100
# Renault va a 100
#
# El #{...} adentro de un string interpola: mete el valor de esa expresión ahí.
# Solo funciona con comillas dobles.

# select devuelve un array nuevo con los elementos para los que el bloque dio true:
autos.first.frenar                                  # frenamos solo al Fiat
en_movimiento = autos.select { |auto| auto.velocidad > 0 }
puts en_movimiento.length                           # 2
```

### Ejemplo resuelto — guardar un bloque para después

```ruby
class Flota
  attr_accessor :vehiculos, :reaccion

  # El & adelante del último parámetro significa "acá me llega el bloque, guardámelo
  # como objeto en esta variable". Sin el &, el bloque se ejecuta y se pierde.
  def initialize(vehiculos, &reaccion)
    self.vehiculos = vehiculos
    self.reaccion = reaccion
  end

  # Ya guardado, el bloque se ejecuta mandándole el mensaje call.
  def alerta
    self.reaccion.call(self)
  end

  def frenar_todos
    self.vehiculos.each { |vehiculo| vehiculo.frenar }
  end

  # def self.algo define un método DE CLASE: se le manda a Flota, no a una flota.
  # Sirve como constructor con nombre, para no repetir el bloque en cada uso.
  def self.prudente(vehiculos)
    self.new(vehiculos) { |flota| flota.frenar_todos }
  end
end

flota = Flota.prudente([Auto.new("Fiat"), Auto.new("Ford")])
flota.vehiculos.each { |auto| auto.acelerar_a(90) }
puts flota.vehiculos.first.velocidad     # 90

flota.alerta                             # dispara el bloque guardado
puts flota.vehiculos.first.velocidad     # 0
```

### 🟡 Tu turno 4.1

Usando el array `autos`, escribí una línea que imprima solo las marcas de los autos que están frenados.

```ruby
# TODO: combiná select y each en una sola línea encadenada.
```

### 🟡 Tu turno 4.2

Agregale a `Flota` un método de clase `self.apurada` que construya una flota cuya reacción sea acelerar todos los vehículos a 200.

```ruby
# TODO: necesitás también un método de instancia acelerar_todos.

# Verificación:
flota = Flota.apurada([Auto.new("Fiat"), Auto.new("Ford")])
flota.alerta
puts flota.vehiculos.last.velocidad      # 200
```

---

## Cierre — ¿estás listo para leer el código de la cátedra?

Marcá mentalmente cada una. Si dudás en alguna, volvé a ese bloque.

- [ ] Escribo una clase con estado y constructor sin mirar nada.
- [ ] Sé por qué `self.` es obligatorio al asignar, y qué pasa si me lo olvido.
- [ ] Distingo `super` de `super()`.
- [ ] Escribo un `module`, lo incluyo, y sé qué pasa si dos módulos definen el mismo método.
- [ ] Leo una salida de `ancestors` y digo qué implementación va a ganar.
- [ ] Escribo un `alias_method` en el lugar correcto sin copiarlo de acá.
- [ ] Paso un bloque a `each` y a `select` con las dos sintaxis.
- [ ] Entiendo qué hace el `&` en `def initialize(cosas, &bloque)`.

Cuando la mayoría esté tildada, el código de `age.rb` y `age-clase2.rb` se lee sin fricción, y estás en condiciones de arrancar con el TP1.

---

## Hints

Consultalos de a uno, en orden, solo si te trabaste 15 minutos.

**1.1** · Hint 1: el `attr_accessor` lleva los dos nombres separados por coma, con símbolos. · Hint 2: el constructor recibe un solo parámetro, pero setea dos cosas: una viene por parámetro, la otra es fija. · Hint 3: mirá el `initialize` de `Auto` y sacale el valor por defecto.

**1.2** · Hint 1: `==` compara. · Hint 2: el resultado de una comparación ya es `true` o `false`; no hace falta envolverlo en nada.

**2.1** · Hint 1: `Bicicleta` espera un argumento en su `initialize`. · Hint 2: `super` a secas reenviaría los dos argumentos que recibiste, y `Bicicleta` espera uno solo. · Hint 3: mirá el `initialize` de `AutoDeCarrera`.

**3.1** · Hint 1: `attr_accessor :volumen_bocina` adentro del `module`. · Hint 2: el método devuelve el string multiplicado, no lo imprime. · Hint 3: `include Sonoro` va adentro de `class Camioneta`, junto al otro include.

**3.2** · Hint 1: son cuatro líneas antes del `initialize`: include, alias, include, alias. · Hint 2: cada `alias_method` va inmediatamente después de su `include`. · Hint 3: el `puts` va adentro del método `acelerar` que definís vos, no en los módulos.

**3.3** · Hint: contá desde tu clase hacia afuera. El último `include` escrito es el que queda más cerca.

**4.1** · Hint 1: `select` devuelve un array nuevo, y a ese array le podés seguir mandando mensajes. · Hint 2: `algo.select { ... }.each { ... }`. · Hint 3: la condición del select usa el método `parada?`... que es de `Bicicleta`, no de `Auto`. Usá `velocidad == 0`.

**4.2** · Hint 1: copiá la forma de `self.prudente`. · Hint 2: el bloque recibe la flota como parámetro y le manda un mensaje. · Hint 3: `acelerar_todos` hace un `each` sobre los vehículos mandándole `acelerar_a(200)` a cada uno.

---

**FIN DEL PROYECTO-00 — Ruby**
