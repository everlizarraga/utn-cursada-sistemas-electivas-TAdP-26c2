# Clase desde Cero — Clase 04 (2020) — Módulo 1
## El Ruby que te falta

> **Sobre este documento.** Cubre la sintaxis y las herramientas de Ruby que aparecen en esta clase sin que nadie las presente: `<<`, hashes, `*args`, interpolación, `==` vs `equal?`, las dos formas de escribir un bloque, `attr_reader`, `private def`, gemas y la carpeta `spec`. Es corto y es de consulta: lo leés una vez y volvés cuando una línea del código no te cierre.
> **No cubre:** ningún concepto de la clase. `method_missing`, bloques, procs, `self`, `instance_eval` tienen módulo propio (2 a 6). Acá solo se nombran para saber que existen.

> **De dónde venís.** De las clases 01 a 03 ya tenés: clases, `def`, `initialize`, `new`, variables de instancia `@algo`, `attr_accessor`, módulos y `include`, `super`, `self.` para métodos de clase, símbolos (`:atacar` es "el nombre atacar"), `send` para enviar un mensaje por su nombre, `method(:x)` y `define_method`, las autoclases, `ancestors`, `require_relative`, y la consola (`irb`/Pry). Todo eso se asume. Si alguno se te desdibujó, va una línea de recordatorio donde aparezca.

---

## 1. Todo es un envío de mensaje 🔴

La línea más común de Ruby esconde la regla más importante del lenguaje.

```ruby
puts "hola"          # => hola
self.puts("hola")    # => hola     ← es EXACTAMENTE la misma línea, escrita completa
```

`puts` no es una instrucción del lenguaje. Es un **mensaje**, como `atacar` o `descansar`, y se lo estás mandando a un objeto. Cuando no escribís receptor, Ruby se lo manda a `self`: el objeto que está "hablando" en ese punto del programa. Y los paréntesis son opcionales cuando no hay ambigüedad.

¿Y quién es `self` en un archivo suelto, fuera de toda clase?

```ruby
puts self          # => main       ← un objeto que Ruby crea para ejecutar el archivo
puts self.class    # => Object     ← es una instancia común de Object
```

Ese objeto se llama `main`. Todo lo que escribís "suelto" en un archivo son mensajes que le mandás a él.

> **Hilo abierto.** Entonces `puts "hola"` adentro de un método de `Guerrero` se lo manda al guerrero, y adentro de un archivo suelto se lo manda a `main`. ¿Y adentro de un bloque? Eso cambia todo, y es el módulo 5.

### `puts`, `p` e `inspect`: tres formas de mostrar 🔴

Vas a ver las tres en el mismo archivo y no son intercambiables.

```ruby
puts "hola"            # => hola         ← muestra el texto "para humanos"
p "hola"               # => "hola"       ← muestra el texto "para programadores": con comillas
puts "hola".inspect    # => "hola"       ← lo mismo que p: inspect devuelve la versión con comillas

puts nil               # =>              ← línea VACÍA. puts nil no muestra nada
p nil                  # => nil          ← p sí te dice que era nil

puts [1, 2, 3]         # => 1            ← puts "desarma" el array y muestra un elemento por línea
                       #    2
                       #    3
p [1, 2, 3]            # => [1, 2, 3]    ← p lo muestra como array
```

Regla: `puts x` es `puts x.to_s`, y `p x` es `puts x.inspect`. `to_s` es "cómo te mostrás a un usuario"; `inspect` es "cómo te mostrás a alguien que está debuggeando". Cuando quieras ver *qué es* una cosa (si es nil, si es string, si es array), usá `p` o `.inspect`.

⚠️ **Trampa:** `puts nil` imprime una línea vacía y no falla. Si un método te devuelve `nil` sin que lo esperes y lo mostrás con `puts`, no vas a ver nada y vas a creer que no se ejecutó. Usá `p`.

---

## 2. Arrays y el operador `<<` 🔴

Un **array** es una lista ordenada. Se escribe entre corchetes.

```ruby
mensajes = []                   # array vacío
mensajes << :atacar             # << agrega al final. Se lee "empujá esto adentro"
mensajes << :descansar
p mensajes                      # => [:atacar, :descansar]

mensajes.push(:sufri_danio)     # push hace lo mismo que <<
p mensajes                      # => [:atacar, :descansar, :sufri_danio]

p mensajes.length               # => 3
p mensajes[0]                   # => :atacar        ← el primero está en la posición 0
p mensajes.first                # => :atacar
p mensajes.last                 # => :sufri_danio
p mensajes.include?(:atacar)    # => true
```

Un detalle que importa después: `<<` **devuelve el mismo array**, no una copia.

```ruby
resultado = (mensajes << :otro)
p resultado.equal?(mensajes)    # => true    ← equal? pregunta "¿es el mismo objeto?" (sección 6). Sí: por eso se puede encadenar
```

### Recorrer un array 🔴

```ruby
[1, 2, 3].each do |n|     # each ejecuta el código de adentro una vez por elemento
  puts n                  # |n| es cómo se llama el elemento en cada vuelta
end
# Resultado esperado:
# 1
# 2
# 3

[1, 2, 3].each { |n| puts n * 2 }   # misma cosa, en una línea (ver sección 8)
# Resultado esperado:
# 2
# 4
# 6
```

Ese código entre `do … end` (o entre llaves) es un **bloque**. Por ahora alcanza con esto: es un pedazo de código que `each` ejecuta por cada elemento. Qué es de verdad un bloque, y por qué es una de las tres ideas de la clase, es el módulo 4.

Dos primos de `each` que aparecen en el código de la cátedra:

```ruby
p [1, 2, 3].map { |n| n * 10 }      # => [10, 20, 30]   ← map arma un array nuevo con el resultado de cada vuelta
p [1, 2, 3].select { |n| n > 1 }    # => [2, 3]         ← select se queda con los que dan true
```

---

## 3. Hashes: diccionarios 🔴

Un **hash** es un conjunto de pares clave → valor. Se escribe entre llaves. Con símbolos como clave, la sintaxis es `clave: valor`.

```ruby
registro = { mensaje: :atacar, argumentos: [10, 20] }
p registro                   # => {:mensaje=>:atacar, :argumentos=>[10, 20]}
```

Fijate que Ruby lo **muestra** con `=>` aunque vos lo **escribiste** con `:`. Son la misma cosa: `{ mensaje: :atacar }` y `{ :mensaje => :atacar }` son equivalentes. La forma con `:` es la moderna y es la que se usa.

```ruby
p registro[:mensaje]         # => :atacar          ← se accede con la clave entre corchetes
p registro[:argumentos]      # => [10, 20]
p registro[:inexistente]     # => nil              ← una clave que no está devuelve nil, no falla

registro[:extra] = true      # agregar o modificar: asignación con corchetes
p registro                   # => {:mensaje=>:atacar, :argumentos=>[10, 20], :extra=>true}
p registro.keys              # => [:mensaje, :argumentos, :extra]
```

Dónde lo vas a ver: en el módulo 2, el registrador de mensajes guarda cada mensaje recibido como `{ mensaje: nombre, argumentos: args }` dentro de un array. Un array de hashes. Con las dos secciones anteriores ya podés leer esa línea.

⚠️ **Trampa:** `p({ a: 1 })` necesita paréntesis. `p { a: 1 }` no funciona porque Ruby lee las llaves como un bloque, no como un hash. Si un hash literal es el primer argumento de un mensaje, poné paréntesis.

---

## 4. `*args`: cualquier cantidad de argumentos 🔴

El asterisco adelante de un parámetro se llama **splat**, y hace dos cosas opuestas según de qué lado esté.

### Al recibir: junta todo en un array

```ruby
def registrar(nombre, *argumentos)    # *argumentos: "todo lo que venga después de nombre, en un array"
  p nombre                             # el primer argumento, normal
  p argumentos                         # el resto, siempre como array (aunque sea vacío)
end

registrar(:atacar)                     # => :atacar
                                       #    []                      ← no vino nada más: array vacío
registrar(:atacar, 10)                 # => :atacar
                                       #    [10]                    ← vino uno: array de uno
registrar(:atacar, 10, "fuerte", true) # => :atacar
                                       #    [10, "fuerte", true]    ← vinieron tres
```

Por eso `method_missing` se declara como `method_missing(nombre, *args)`: no sabe cuántos argumentos va a traer el mensaje que no entendió, así que los recibe todos en un array.

### Al enviar: desparrama un array en argumentos sueltos

```ruby
def sumar(a, b, c)                     # un método que espera exactamente tres argumentos
  a + b + c
end

numeros = [1, 2, 3]
p sumar(*numeros)                      # => 6       ← *numeros se convierte en 1, 2, 3
p sumar(numeros)                       # => ArgumentError: wrong number of arguments (given 1, expected 3)
                                       #    ⚠️ sin el asterisco le pasaste UN argumento: el array entero
```

### Las dos direcciones juntas: `send(nombre, *args)`

Recordatorio de la clase 03: `objeto.send(:atacar, 10)` es lo mismo que `objeto.atacar(10)`, pero con el nombre del mensaje como símbolo, o sea, como dato.

De acá en adelante los ejemplos usan el `age.rb` de la cátedra: un `Guerrero` tiene `energia`, `potencial_ofensivo` y `potencial_defensivo`, entiende `sufri_danio(danio)` (le resta energía) y `descansar` (le suma 10), y `Guerrero.new` sin argumentos arranca con energía 100.

```ruby
require_relative 'age'             # carga el age.rb de la cátedra (tiene que estar en la misma carpeta)

atila = Guerrero.new               # energía 100
args = [30]
atila.send(:sufri_danio, *args)    # *args desparrama [30] → sufri_danio(30)
p atila.energia                    # => 70

atila.send(:descansar, *[])        # *[] no desparrama nada → descansar()
p atila.energia                    # => 80
```

Esto es lo que hace el registrador de mensajes del módulo 2: recibe `(nombre, *args)`, y reenvía `send(nombre, *args)`. Lo que entró junto, sale junto. Un dibujo del viaje:

```
   objeto.atacar(10, "fuerte")
            │
            ▼  Ruby no encuentra atacar → llama a
   method_missing(:atacar, *args)      args = [10, "fuerte"]     ← el * JUNTA
            │
            ▼  reenviar tal cual
   otro.send(:atacar, *args)           → otro.atacar(10, "fuerte") ← el * DESPARRAMA
```

### Y el `&bloque` que aparece al lado 🟡

En las firmas de la cátedra vas a ver `def method_missing(nombre, *args, &bloque)`. Ese `&bloque` es "el bloque que me pasaron, si me pasaron uno". Es la misma idea que el splat pero para bloques: al recibir lo captura como objeto, al enviar (`send(nombre, *args, &bloque)`) lo reenvía. Cómo funciona de verdad es el módulo 4. Por ahora: cuando lo veas en una firma, leelo como "y también el bloque".

> 🎓 **Para el parcial, si te preguntan:** *¿Por qué `method_missing` recibe `*args` y no una lista fija de parámetros?*
> Porque tiene que poder responder cualquier mensaje, y cada mensaje puede traer cualquier cantidad de argumentos. El splat junta lo que venga en un array, y al reenviar con `send(nombre, *args)` el mismo splat lo desparrama de nuevo. El objeto original recibe exactamente lo que se le mandó al intermediario.

---

## 5. Strings: interpolación y algunos mensajes 🟡

```ruby
nombre = "Pepe"
puts "Hola, soy #{nombre}"      # => Hola, soy Pepe     ← #{} mete el valor adentro del string: INTERPOLACIÓN
puts "Hola, soy " + nombre       # => Hola, soy Pepe     ← concatenar con + también funciona
puts 'Hola, soy #{nombre}'       # => Hola, soy #{nombre} ⚠️ con comillas SIMPLES no interpola
```

Regla: comillas dobles interpolan, simples no. Adentro de `#{}` puede ir cualquier expresión, no solo una variable: `"energía: #{atila.energia}"`.

Conversiones y consultas que aparecen en la clase:

```ruby
p :atacar.to_s                                    # => "atacar"     ← de símbolo a string
p "atacar".to_sym                                 # => :atacar      ← de string a símbolo
p :comerse_un_sanguche.start_with?("comerse_")        # => true     ← ¿empieza con...? (los símbolos lo entienden)
p "comerse_un_sanguche".delete_prefix("comerse_")     # => "un_sanguche"  ← sacale ese prefijo (solo strings)
p "un_sanguche".size                                  # => 11        ← cantidad de caracteres
```

Dónde lo vas a ver: en el módulo 2, un `method_missing` que atiende cualquier mensaje que empiece con `comerse_` y usa el resto del nombre como dato. Un símbolo entiende `start_with?`, pero no `delete_prefix`: para recortarlo hay que pasarlo a string con `to_s` primero (`name.to_s.delete_prefix("comerse_")`).

---

## 6. `==` vs `equal?` 🟡

Dos formas de preguntar "¿son iguales?", con respuestas distintas.

```ruby
a = "hola"
b = "hola"
p a == b          # => true     ← ¿tienen el mismo VALOR? Sí, las dos dicen "hola"
p a.equal?(b)     # => false    ← ¿son el MISMO OBJETO? No, son dos strings distintos
p a.equal?(a)     # => true     ← el mismo objeto consigo mismo, sí
```

`==` compara valor. `equal?` compara identidad: si son literalmente el mismo objeto en memoria.

Para símbolos, `true`, `false` y `nil` da lo mismo cuál uses, porque de cada uno existe **un solo objeto** en todo el programa (recordatorio de la clase 03: `:atacar` es siempre el mismo símbolo):

```ruby
p :hola.equal?(:hola)    # => true
p true.equal?(true)      # => true
```

Dónde lo vas a ver: el framework de testing del módulo 6 compara booleanos. Si alguien escribe `un_booleano.equal?(true)` funciona por esto. Pero `==` es lo normal; `equal?` solo cuando de verdad preguntás por identidad.

---

## 7. `nil`, booleanos y `!` 🟡

`nil` es el objeto que representa "nada". Es un objeto como cualquier otro: tiene clase y responde mensajes.

```ruby
p nil             # => nil
p nil.class       # => NilClass
p nil.nil?        # => true
p "hola".nil?     # => false
p nil.to_s        # => ""       ← por eso puts nil imprime una línea vacía
```

`!` es la negación. Y acá una regla que en otros lenguajes es distinta: **en Ruby solo `nil` y `false` cuentan como falso**. Todo lo demás es verdadero, incluido el `0` y el string vacío.

```ruby
p !nil       # => true
p !false     # => true
p !"hola"    # => false    ← un string es "verdadero"
p !0         # => false    ← el cero también es "verdadero" (en JavaScript sería al revés)
```

Dónde lo vas a ver: `assert !corrio` en los tests del módulo 6 se lee "afirmá que no corrió".

---

## 8. Escribir lo mismo de dos formas 🔴

Ruby te deja escribir la misma cosa de varias maneras, y el código de la cátedra las mezcla. Si no sabés que son equivalentes, parece que son cosas distintas.

### Bloques: llaves o `do … end`

(`proc { … }` empaqueta un bloque en un objeto y `call` lo ejecuta. Es del módulo 4; acá aparece solo para poder mostrar las dos escrituras una al lado de la otra.)

```ruby
imprimir = proc { puts "hola"; puts "chau" }    # entre llaves, en una línea, sentencias separadas por ;
imprimir.call
# Resultado esperado:
# hola
# chau

imprimir = proc do        # entre do y end, en varias líneas, sin ;
  puts "hola"
  puts "chau"
end
imprimir.call
# Resultado esperado:
# hola
# chau
```

Son **idénticos**. El `;` separa sentencias en una misma línea; el salto de línea hace lo mismo. Convención (no regla): llaves para una línea, `do … end` para varias. RubyMine convierte de una a otra con Alt+Enter sobre el bloque.

⚠️ **Trampa real, de precedencia:** no son idénticos cuando el bloque es argumento de un mensaje que a su vez es argumento de otro.

```ruby
puts [1, 2, 3].select { |n| n > 1 }.inspect   # => [2, 3]                      ← las llaves se pegan a select
puts [1, 2, 3].select do |n| n > 1 end        # => #<Enumerator:0x...>         ← do…end se pega a PUTS, no a select
puts([1, 2, 3].select do |n| n > 1 end)       # => 2                           ← con paréntesis, vuelve a andar
                                              #    3
```

`do … end` se asocia al mensaje **más a la izquierda** de la línea (`puts`); las llaves, al más cercano (`select`). Por eso en el código de la cátedra vas a ver paréntesis "de más" alrededor de expresiones con `do … end`: no sobran, evitan esto.

### Paréntesis opcionales

```ruby
def saludar(nombre)
  "hola #{nombre}"
end

puts saludar("ana")     # => hola ana
puts saludar "ana"      # => hola ana     ← igual, sin paréntesis
puts(saludar("ana"))    # => hola ana     ← igual, con todos
```

Regla práctica: sin paréntesis cuando es obvio (`puts algo`, `attr_reader :x`, `include Atacante`); con paréntesis cuando hay anidamiento o cuando dudes.

### `if` en una línea, `unless`, ternario

```ruby
energia = 5
puts "cansado" if energia < 10         # => cansado    ← el if al final: se ejecuta la línea solo si se cumple
puts "cansado" unless energia >= 10    # => cansado    ← unless es "if not"
puts "no sale" if energia > 10         # (no imprime nada)

estado = energia < 10 ? "cansado" : "bien"   # ternario: condición ? si_verdadero : si_falso
puts estado                            # => cansado
```

Dónde lo vas a ver: `@cortar_test.call unless un_booleano` en el framework del módulo 6, y `puts "Tuki".green if @printing_results` en el del repo de tu cursada.

---

## 9. `attr_reader` y `private def` 🟡

Ya conocés `attr_accessor :energia`, que crea el getter `energia` y el setter `energia=`. `attr_reader` crea **solo el getter**.

```ruby
class Registro
  attr_reader :items          # crea el método items, y NO crea items=
  def initialize
    @items = []
  end
end

r = Registro.new
p r.items                     # => []
r.items = [1]                 # => NoMethodError: undefined method 'items=' ...   ← no hay setter
r.items << 5                  # ✅ esto SÍ funciona: no asignás, le mandás << al array que ya está
p r.items                     # => [5]
```

Ese último caso es exactamente el registrador de mensajes: `attr_reader :mensajes_recibidos`, y adentro `@mensajes_recibidos << {...}`. Nadie reasigna la lista; se le agregan cosas.

`private def` es la forma corta de marcar un método como privado en la misma línea que lo definís:

```ruby
class Espia
  def publico
    secreto              # desde adentro, sin receptor, un método privado se puede llamar
  end
  private def secreto    # privado: solo se puede invocar sin receptor explícito, desde adentro
    "shh"
  end
end

e = Espia.new
p e.publico     # => "shh"
e.secreto       # => NoMethodError: private method 'secreto' called for ...
```

Dónde lo vas a ver: en el repo de la cátedra, `private def method_missing`. Es una buena práctica: `method_missing` es un mecanismo interno del objeto, no parte de su interfaz, así que se lo marca privado. Ruby lo llama igual aunque sea privado.

---

## 10. Gemas, `Gemfile` y `colorize` 🟡

Una **gema** es una biblioteca de Ruby empaquetada para instalarse con un comando. El framework de testing usa una para imprimir en colores.

**`Gemfile`** es un archivo en la raíz del proyecto que lista las gemas que el proyecto necesita:

```ruby
source 'https://rubygems.org'   # de dónde bajarlas

gem 'rspec'                     # para tests (sección 11)
gem 'colorize'                  # para strings en colores
```

Con ese archivo, `bundle install` en la terminal las instala todas. Después, en el código, `require 'colorize'` las carga (fijate que es `require`, sin `_relative`, porque no es un archivo tuyo: es una gema instalada).

```ruby
require 'colorize'
puts "PASS".green      # imprime PASS en verde en la terminal
puts "FAIL".red        # imprime FAIL en rojo
```

### Cómo funciona por dentro (y por qué te importa)

`"PASS".green` es un mensaje a un string. `String` no lo entiende de fábrica. La gema lo agrega **abriendo la clase `String`** y definiéndole métodos nuevos. Es open classes, la técnica de la clase 03, usada por una biblioteca real. Una versión mínima de lo que hace, que podés correr sin instalar nada:

```ruby
class String                    # abrimos String: la clase ya existe, esto le AGREGA métodos
  def verde
    "\e[32m#{self}\e[0m"        # envuelve el texto en códigos ANSI: \e[32m = verde, \e[0m = volver al normal
  end                           # la terminal los interpreta como color; self es el string receptor
  def rojo
    "\e[31m#{self}\e[0m"        # \e[31m = rojo
  end
end

puts "PASS".verde               # => PASS   (en verde, si tu terminal soporta colores)
p "PASS".verde                  # => "\e[32mPASS\e[0m"   ← p te muestra lo que hay adentro de verdad
p "PASS".verde.length           # => 13                  ← son 13 caracteres, no 4: los códigos cuentan
```

`colorize` hace esto mismo con muchos más colores y opciones. Nada mágico: un `def` adentro de `class String`.

> **Hilo abierto.** `colorize` hace que `"PASS".green` exista agregándole un método a `String`. En el módulo 6 vas a ver que `assert(...)` "existe" adentro de un test por un camino distinto: no se le agrega nada a nadie, se cambia quién es `self`. Dos formas de que un mensaje aparezca donde antes no estaba, y conviene no confundirlas.

> 🕳️ **Madriguera — Bundler y `Gemfile.lock`**
> `bundle` es la herramienta que lee el `Gemfile`, resuelve versiones y las instala. Genera un `Gemfile.lock` con las versiones exactas, para que todos tengan lo mismo. En los repos de la cátedra el `.lock` está en `.gitignore`.
> *Volvé al camino — esto se profundiza aparte, otro día.*

---

## 11. `lib/`, `spec/` y RSpec 🟢

En los proyectos de la cátedra el código está repartido en dos carpetas, por convención:

```
proyecto/
├── Gemfile
├── lib/      (o src/)      ← el código que escribís: clases, módulos, tu framework
└── spec/                   ← los tests que prueban ese código
```

`spec` no es nada de Ruby. Es el nombre convencional de la carpeta de tests, heredado de **RSpec**, la biblioteca de testing más usada en Ruby, que llama "specs" a los tests. Los archivos adentro son `.rb` comunes. Un archivo de `spec/` carga lo que va a probar con `require_relative '../lib/lo_que_sea'`.

Un test de RSpec, para que lo reconozcas cuando lo veas en el repo (no lo vamos a usar en esta clase: en el módulo 6 construimos el nuestro):

```ruby
require 'rspec'                                   # carga la gema
require_relative '../src/age'                     # carga el código a probar

RSpec.describe 'Guerrero' do                      # describe: agrupa tests sobre un tema
  it 'arranca con 100 de energía' do              # it: un test, con su nombre en texto
    atila = Guerrero.new
    expect(atila.energia).to eq(100)              # expect(...).to eq(...): la afirmación
  end
end
```

Se ejecuta con `rspec` en la terminal, o con el botón de RubyMine sobre el archivo.

> 🕳️ **Madriguera — `# frozen_string_literal: true`**
> Un comentario en la primera línea de algunos archivos del repo. Le dice a Ruby que los strings literales de ese archivo no se pueden modificar en el lugar. Es una optimización y una convención de estilo; no cambia nada de lo que vemos en la clase.
> *Volvé al camino — esto se profundiza aparte, otro día.*

---

## Checkpoint del Módulo 1

Sin respuestas. Si alguna no te sale, buscala en el módulo.

1. ¿Qué diferencia hay entre `puts x` y `p x`? Dame un valor de `x` para el cual `puts` te engañaría.
2. `mensajes << :atacar`: ¿qué devuelve esa expresión? ¿Por qué eso permite hacer `r.items << 5` aunque `items` sea solo `attr_reader`?
3. Escribí un hash que represente el mensaje `atacar(10, "fuerte")` con las claves `mensaje` y `argumentos`, y mostrá cómo se accede al segundo argumento.
4. `def m(a, *resto)`: ¿qué vale `resto` si llamo `m(1)`? ¿Y si llamo `m(1, 2, 3)`?
5. Tenés `args = [5, 6]` y un método `def sumar(a, b)`. ¿Cuál de estas dos anda y por qué: `sumar(args)` o `sumar(*args)`?
6. `"hola" == "hola"` da `true`. ¿Qué da `"hola".equal?("hola")` y por qué?
7. ¿Cuáles son los únicos dos valores "falsos" de Ruby? ¿Qué da `!0`?
8. Esta línea imprime un `Enumerator` en vez de la lista: `puts [1,2,3].select do |n| n > 1 end`. ¿Por qué, y cuáles son las dos formas de arreglarla?
9. ¿Qué hace `colorize` para que `"PASS".green` funcione? ¿Con qué técnica de la clase 03 se relaciona?

---

## Qué viene en el Módulo 2

La primera de las tres ideas de la clase: **qué hace Ruby cuando un objeto recibe un mensaje que no entiende**. Vas a ver que el method lookup, que ya conocés, tiene un último paso que nadie te contó, y que ese paso es una decisión de diseño del lenguaje con un porqué. De ahí sale `method_missing`, y con él, un objeto que registra todos los mensajes que le mandan a otro. Usa `<<`, hashes, `*args` y `send` todo el tiempo: por eso este módulo vino primero.

**FIN DEL MÓDULO 1**
