# Apunte maestro — clase04 — `method_missing`, bloques, contextos e `instance_eval`
## Parte 3 — Bloques, procs y lambdas

> **Qué cubre esta parte.** Qué es de verdad un bloque en Ruby (y por qué no es un objeto), cómo se convierte en uno (`proc`), cómo recibe un método un bloque y qué hace con él (`yield`, `&bloque`), cómo se pasa un proc donde se espera un bloque (`&proc`), en qué se diferencian un proc y una lambda, y un contador que recuerda una variable de un método que ya terminó. Antes de todo eso, un detalle que sostiene el resto: a quién le llega un mensaje sin receptor.
>
> **De dónde venís.** De las Partes 1 y 2: `method_missing`, el registrador. De la clase 3: `send`, `method(:x)`, `methods`, `instance_methods`, `ancestors`. De la clase 1: `each` con `do … end`.
>
> **Cómo está escrita.** Cada sección abre con la **regla**, en afirmativo. Después viene el caso que la muestra, con el resultado al lado de cada línea. Todo el código se ejecutó antes de escribirse. Donde un mecanismo tiene varias formas, van en una tabla: *escribís / Ruby entiende / sale*, incluidas las formas que fallan. La sintaxis nueva aparece primero en su forma larga y recién después en su forma corta.
>
> **Código.** Ruby 3.x con el `age.rb` de la materia donde se indica; los ejemplos de bloques y procs no lo usan salvo que se diga. `puts x` imprime el texto; `p x` muestra el valor tal cual. En versiones recientes los errores dicen `for main` en vez de `for main:Object`: es el mismo error.

---

## 1. El receptor implícito: `puts "hola"` es un mensaje 🔴

> **Regla.** `puts` es un mensaje, como `atacar`. Todo envío de mensaje sin receptor escrito **se lo recibe `self`**: el objeto que está "hablando" en ese punto del programa. En un archivo suelto, `self` es `main`, una instancia común de `Object` que Ruby crea para ejecutar el archivo. `puts` está definido en `Kernel`, el mixin de `Object`, así que **cualquier objeto lo entiende**; está marcado privado, así que solo se manda sin receptor (o con `send`).

La línea más común de Ruby esconde la regla más importante del lenguaje:

```ruby
puts "hola"          # => hola
self.puts("hola")    # => hola     ← es EXACTAMENTE la misma línea, escrita completa
```

Quién es `self` en un archivo suelto:

```ruby
puts self            # => main       ← un objeto que Ruby crea para ejecutar el archivo
puts self.class      # => Object     ← es una instancia común de Object; se llama a sí mismo "main"
```

Todo lo que escribís "suelto" en un archivo son mensajes que le mandás a `main`. Y como `main` es un `Object` y entiende `puts`, `puts` tiene que estar en la cadena de `Object`: está en `Kernel`. Lo que implica que cualquier objeto lo entiende:

```ruby
2.puts(self)
# => NoMethodError: private method `puts' called for an instance of Integer
#    lo entiende, y es privado: con receptor explícito no se puede. send salta la privacidad:
2.send(:puts, self)          # => main      ← el 2 imprimió
"hola".send(:puts, self)     # => main      ← un string también
```

**Qué imprime `2.send(:puts, self)` y por qué.** En esa línea hay **dos** objetos: `2` es el receptor de `puts`, y `self` es el **argumento**. Un argumento se evalúa donde está escrito, antes de mandar el mensaje: en un archivo suelto, `self` vale `main`, y eso es lo que `puts` imprime. El receptor cambió; el argumento se evaluó en el contexto de afuera. Adentro de un método de `Guerrero`, la misma línea imprime al guerrero:

```ruby
require_relative 'age'

class Guerrero
  def quien
    puts self                # receptor implícito: el guerrero
    2.send(:puts, self)      # self, escrito adentro de un método: es el guerrero que recibió quien
  end
end

2.send(:puts, self)          # => main                   ← self evaluado en el archivo
Guerrero.new.quien           # => #<Guerrero:0x…>        ← puts self
                             #    #<Guerrero:0x…>        ← 2.send(:puts, self): el mismo guerrero
```

| Escribís | El receptor de `puts` es | El argumento `self` vale | Sale |
|---|---|---|---|
| `2.send(:puts, self)` en el archivo | `2` | `main` (el `self` del archivo) | `main` |
| `2.send(:puts, self)` adentro de `quien` | `2` | el guerrero (el `self` del método) | `#<Guerrero:0x…>` |
| `puts self` adentro de `quien` | el guerrero (receptor implícito) | el guerrero | `#<Guerrero:0x…>` |

**`self` es una variable que depende del contexto**: quién es `self` en cada punto del programa lo define dónde está escrita esa línea. (Contexto: el lugar del programa en el que está una línea, con las variables que esa línea puede ver y con quién es `self` ahí. La Parte 4 lo desarma pieza por pieza.) Adentro de un método de `Guerrero`, `self` es el guerrero que recibió el mensaje; en un archivo suelto, es `main`. Esta idea vuelve en la sección 3 y es todo el eje de la Parte 4.

---

## 2. Bloques: código que no es un objeto 🔴

> **Regla.** Un bloque (`{ |n| … }` o `do |n| … end`) es un cacho de código que va **pegado al final de un envío de mensaje**, y ese es el único lugar donde puede aparecer. En Ruby, **un bloque no es un objeto**: no se guarda en una variable, no recibe mensajes, no se pasa como parámetro. Las llaves y `do … end` son equivalentes.

Esto lo venís usando desde la primera clase:

```ruby
[1, 2, 3].each { |n| puts n }        # Resultado esperado: 1, 2, 3 (uno por línea)
[1, 2, 3].each do |n| puts n end     # exactamente lo mismo
```

Ese `{ |n| puts n }` es un bloque: `each` lo ejecuta una vez por elemento. Hasta acá, igual que en cualquier lenguaje que tenga algo parecido (en Wollok, un bloque es un objeto: lo guardás en una variable, le mandás `apply`). Lo que Ruby decidió distinto, y que muerde si no lo sabés, es que el bloque no es objeto:

```ruby
a = {}                     # ⚠️ esto es un Hash vacío, no un bloque vacío: las llaves solas son sintaxis de hash
p a.class                  # => Hash

a = { puts "hola" }        # => SyntaxError   ← el parser no sabe qué es esto: no es un hash y un bloque no va acá
imprimir_n = { |n| puts n }   # => SyntaxError   ← no hay forma de "tener" el bloque suelto
```

Es una decisión rara del lenguaje, de las que parecen atadas con alambre, y la razón es que querían esta sintaxis simpática de `do … end` al final de un mensaje. Para metaprogramación no es central, pero como estamos programando en Ruby hay que saberlo para no confundirse. En la sección siguiente, la forma de tener un cacho de código como objeto; y ahí se ve la otra consecuencia de esta decisión.

---

## 3. `proc`: el bloque convertido en objeto 🔴

> **Regla.** `proc { … }` convierte un bloque en un **objeto** de la clase `Proc`: código guardado para ejecutarlo después, cuantas veces quieras, con `call`. `proc` es un mensaje (a `self`, definido en `Kernel`); `Proc` es la clase; `Proc.new { … }` hace lo mismo. Adentro de un proc, `self` es **el mismo `self` del lugar donde el bloque fue escrito**.

```ruby
imprimir = proc { puts "hola" }    # proc + un bloque → un OBJETO que representa esa lógica. No se imprime nada.
puts imprimir                      # => #<Proc:0x… archivo.rb:1>   ← es un objeto, y lo puedo mostrar
puts imprimir.class                # => Proc                       ← de la clase Proc

imprimir.call                      # => hola     ← recién acá se ejecuta
imprimir.call                      # => hola     ← y tantas veces como quieras
```

`puts imprimir` no imprime "hola": el código de adentro **no se ejecuta** hasta que se lo pidas con `call`. Esa es toda la gracia de los bloques y los procs: escribir código ahora para ejecutarlo después, cuantas veces haga falta, en otro momento y en otro lugar.

Y ahora que tengo el código como objeto, ¿se lo puedo pasar a `each` como parámetro, en vez de escribirle el bloque?

```ruby
imprimir_n = proc { |n| puts n }
[1, 2, 3].each(imprimir_n)
# => ArgumentError: wrong number of arguments (given 1, expected 0)      ← la excepción de "cantidad de argumentos incorrecta"
#    each espera CERO parámetros. El bloque no se cuenta entre los parámetros: es otra cosa.
```

Cada parámetro de un mensaje es un objeto; el bloque no lo es, así que Ruby lo cuenta aparte. Un proc es un objeto y por eso ocupa lugar de parámetro, y `each` no acepta ninguno. Cómo se le pasa un proc a un mensaje que espera un bloque es la sección 6.

### `proc` es un mensaje, `Proc` es una clase

Con lo de la sección 1 se deduce qué es `proc`: una palabra suelta, sin receptor, seguida de un bloque. Un bloque solo va pegado a un envío de mensaje. Entonces `proc` es un **mensaje a `self`**:

```ruby
puts method(:proc).owner                 # => Kernel    ← definido en Kernel: lo entiende cualquier objeto
otro_proc = Proc.new { 5 + 11 }          # Proc.new también recibe un bloque, y hace lo mismo que proc { … }
puts otro_proc.class                     # => Proc

puts Proc.instance_methods(false).inspect   # inspect: la representación "de programador" del objeto, la que muestra p
# => [:<<, :==, :===, :>>, :[], :arity, :binding, :call, :clone, :curry, :dup, :eql?, :hash, :inspect,
#     :lambda?, :parameters, :ruby2_keywords, :source_location, :to_proc, :to_s, :yield]
#    ↑ los mensajes que define Proc (el orden puede variar): call, arity, lambda?, binding, curry… varios van a aparecer
```

`proc { … }` aprovecha que todo mensaje puede recibir un bloque al final (sección 4) para crear un objeto a partir de él. Es un mensaje que devuelve una instancia de `Proc`, y en el metamodelo de la clase 3 es un objeto más: tiene clase, tiene autoclase, entiende mensajes. `proc` (minúscula) es el mensaje; `Proc` (mayúscula) es la clase. Y `Proc` es una rama hermana de `Guerrero` en la jerarquía, no una ancestra: `atila.is_a?(Proc)` → `false`.

### Quién es `self` adentro de un proc

```ruby
imprimir_self = proc { puts self }
puts self                    # => main
imprimir_self.call           # => main     ← el mismo self que había afuera del bloque
```

`self` adentro del bloque es **el mismo `self` que había en el lugar donde el bloque fue escrito**, y no el proc. El bloque se acuerda del contexto en el que se definió y lo referencia. Es lo que hacen los bloques en la mayoría de los lenguajes. Guardá esto: en la Parte 4 vamos a ver que Ruby te deja cambiarlo.

---

## 4. Todo mensaje recibe un bloque, y casi todos lo ignoran 🔴

> **Regla.** Todos los mensajes, además de sus parámetros, **pueden recibir un bloque al final**, uno solo. La mayoría no hace nada con él. Para que un método **use** el bloque hay que escribirlo en su cuerpo, y hay dos formas (sección 5).

```ruby
puts() { puts self }         # imprime una línea vacía (lo que hace puts sin argumentos)… y el bloque se ignora
-10.abs { puts "hola" }      # => 10     ← abs (valor absoluto) acepta el bloque y lo ignora; "hola" nunca se imprime

def m1                       # un método propio, sin parámetros, sin cuerpo
end

m1 { puts "chau" }           # no imprime nada, y no falla: m1 recibió el bloque y no lo usó
```

`m1` recibió el bloque. Como `puts` y `abs`, no hizo nada con él.

---

## 5. Usar el bloque: `yield` y `&bloque` 🔴

> **Regla.** Un método usa el bloque que le llegó de dos formas. **`yield`** lo ejecuta ahí mismo, sin nombre y sin que aparezca en la firma; con `yield` el bloque es obligatorio (`LocalJumpError` si falta). **`&bloque` en la firma** lo captura convertido en `Proc`, con nombre: se ejecuta con `call`, se guarda, se devuelve, se pasa; si no llega bloque, `bloque` vale `nil`. **`block_given?`** dice si llegó un bloque, y sirve con las dos formas.

### Forma 1: `yield`, ejecutalo acá

```ruby
def m1
  yield                      # ejecuta el bloque que llegó pegado a este envío
  puts "M1"
end

m1 { puts "bloqueee" }
# Resultado esperado:
# bloqueee                   ← primero el bloque
# M1                         ← después el resto del método

m1
# => LocalJumpError: no block given (yield)     ← yield sin bloque explota
```

Para que el bloque sea opcional, preguntás antes con `block_given?`. Primero en su forma larga, con el `if` que ya conocés:

```ruby
def m1
  if block_given?            # ¿llegó un bloque pegado a este envío?
    yield                    # sí: ejecutalo
  end
  puts "M1"
end

m1                           # => M1
m1 { puts "bloqueee" }       # => bloqueee
                             #    M1
```

**El `if` de una línea.** Ruby deja escribir esa condición al final de la sentencia. Las tres formas hacen lo mismo; elegí la que te resulte legible, y sabé leer las otras:

| Escribís | Se lee | Equivale a |
|---|---|---|
| `if block_given?` / `yield` / `end` | si hay bloque, ejecutalo | — (es la forma larga) |
| `yield if block_given?` | ejecutalo, si hay bloque | la forma larga |
| `puts "sin bloque" unless block_given?` | imprimí "sin bloque", **salvo que** haya bloque | `if !block_given?` / `puts "sin bloque"` / `end` |

`unless` es `if` con la condición negada: `x unless c` ejecuta `x` cuando `c` es falso. En este apunte se usa la forma larga siempre que haya más de una sentencia, y la de una línea cuando es una sola.

Esta forma es la que más muestra lo especial (en el mal sentido) que son los bloques: el bloque llega sin nombre, sin aparecer en la firma, y lo invocás con una palabra reservada. Hay otra sintaxis bastante más agradable.

### Forma 2: `&bloque`, capturalo como objeto

Todos los mensajes reciben un bloque después de sus parámetros. Podemos **escribir eso en la firma**:

```ruby
def m1(&bloque)              # &bloque: "el bloque que llegue al final de los parámetros, dámelo con este nombre"
  bloque.call(10)            # ahora bloque es un objeto: un Proc. Lo ejecuto con call, pasándole 10
  puts "M1"
end

m1 { |n| puts n }            # el bloque declara un parámetro n, que recibe el 10 del call
# Resultado esperado:
# 10
# M1
```

Con `&`, el bloque **entra al método convertido en `Proc`**, automáticamente: es lo mismo que hacía `proc { … }`, hecho por Ruby al recibir el mensaje. Una vez adentro es un objeto común: lo podés ejecutar, guardar, devolver, pasar a otro. Eso no lo podías hacer con `yield`.

> **Reificar:** convertir en objeto algo que no lo era. Un envío de mensaje "pasa"; un `Proc` es ese "pasa" convertido en cosa, con identidad, que podés guardar y pasar. `&bloque` reifica el bloque.

```
   m1 { |n| puts n }
        │
        │  def m1              → yield ejecuta el bloque acá, y no lo tenés como objeto
        │
        │  def m1(&bloque)     → bloque = Proc (el bloque reificado): call, guardar, devolver, pasar
```

**`&bloque` no obliga a pasar bloque.** Captura el que venga; si no viene ninguno, `bloque` vale `nil`. El error que da al usarlo es distinto del de `yield`, y `block_given?` sirve igual para evitarlo:

```ruby
m1
# => NoMethodError: undefined method `call' for nil      ← bloque es nil, y nil no entiende call

def m1(&bloque)
  if block_given?            # block_given? también funciona con &bloque
    bloque.call(10)
  end
  puts "M1"
end

m1                           # => M1                    ← sin bloque, sin error
```

Y si el método también tiene parámetros comunes, el `&bloque` va **último**, y los parámetros siguen siendo obligatorios:

```ruby
def m1(a, b, &bloque)        # dos parámetros y el bloque al final
  bloque.call(10)
  puts "M1"
end

m1(1, 2) { |n| puts n }      # => 10
                             #    M1
m1 { |n| puts n }            # => ArgumentError: wrong number of arguments (given 0, expected 2)
                             #    ⚠️ el bloque no cuenta: a y b siguen faltando
```

---

## 6. Dos bloques no: dos procs. Y el `&` al revés 🔴

> **Regla.** Un método recibe **un solo** bloque. Para pasarle dos cachos de lógica, se pasan **dos procs** como parámetros comunes. Y al revés: para pasar un proc que ya tenés donde se espera un bloque, va **`&proc` en la llamada**. El `&` es un convertidor de dos direcciones: en la firma, bloque → `Proc`; en la llamada, `Proc` → bloque.

Un método que necesita **dos** cachos de lógica: dos cálculos que vienen de lugares distintos y hay que sumar sus resultados. `&bloque, &otro_bloque` no existe. La salida es la de siempre cuando algo no es objeto: **hacerlo objeto**. El bloque no es un parámetro; el proc sí:

```ruby
def m1(un_proc, otro_proc)                    # dos parámetros comunes, que van a ser procs
  un_proc.call + otro_proc.call               # ejecuto los dos y sumo
end

puts m1(proc { 2 + 6 }, proc { 10 + 7 })      # => 25     ← se crean con proc { … } antes de pasarlos
```

Fijate lo natural que es: necesito dos cachos de lógica, son dos objetos, son dos parámetros, listo. Todo el problema de "cómo paso dos bloques" surge de cómo Ruby armó los bloques (uno, al final). En cuanto pasás a procs, vuelve a regir la regla de los objetos: pasás tantos como quieras. Y de paso: si a este `m1` le pegás un bloque al final además de los dos procs, lo ignora, como cualquier mensaje.

### Pasar un proc donde se espera un bloque

El caso inverso. Tenés un proc ya armado y un método que espera un **bloque**:

```ruby
def m2(&un_bloque)
  un_bloque.call
end

imprimir_3 = proc { puts "3" }

m2(imprimir_3)
# => ArgumentError: wrong number of arguments (given 1, expected 0)
#    m2 espera cero parámetros y un bloque; le pasaste un objeto, que ocupa lugar de parámetro

m2 { imprimir_3 }          # no falla, y no imprime nada: pasaste un bloque que DEVUELVE el proc, sin ejecutarlo

m2(&imprimir_3)            # => 3      ← el proc entró como el bloque de m2
```

`&` **en la llamada** dice "tengo un proc, convertilo en el bloque que este mensaje espera". Es la misma dualidad del `*` con los arrays en la Parte 2.

**Todas las formas de invocar el mismo método.** Un método con dos parámetros y un bloque opcional, y un proc guardado. Las que andan y las que fallan, lado a lado:

```ruby
def m23(a, b, &bloque)
  if block_given?
    bloque.call(a + b)       # le pasa la suma al bloque
  else
    puts "sin bloque"
  end
end

mostrar = proc { |n| puts n }   # un proc guardado, que recibe un número y lo imprime
```

| Escribís | Ruby entiende | Sale |
|---|---|---|
| `m23(10, 20) { \|n\| puts n }` | bloque escrito ahí; recibe 30 en `n` | `30` |
| `m23(10, 20, &mostrar)` | el proc, convertido en bloque por el `&` | `30` |
| `m23(10, 20) { \|n\| mostrar.call(n) }` | un bloque que adentro ejecuta el proc con `n` | `30` |
| `m23(10, 20)` | sin bloque: `block_given?` es `false` | `sin bloque` |
| `m23(10, 20) { mostrar.call }` | un bloque que ejecuta el proc **sin pasarle nada**: `n` es `nil` | una línea vacía (`puts nil`) |
| `m23(10, 20) { \|n\| mostrar(n).call }` | `mostrar(n)` con paréntesis es un **mensaje**, no la variable | `NoMethodError: undefined method 'mostrar' for main` |
| `m23(10, 20, mostrar)` | tres argumentos comunes: el proc ocupa lugar de parámetro | `ArgumentError: wrong number of arguments (given 3, expected 2)` |
| `m23(&mostrar)` | el bloque entró, y `a` y `b` faltan | `ArgumentError: wrong number of arguments (given 0, expected 2)` |

Las dos últimas filas de error son la misma regla de la sección 3: el bloque no cuenta como parámetro, y un proc sí. La fila de `mostrar(n)` es una regla que la Parte 4 desarrolla: una palabra con paréntesis es siempre un mensaje; para una variable que guarda un proc, `.call`.

Las reglas de los bloques, todas juntas, son pocas:

1. Todo mensaje puede recibir un bloque, uno solo, al final de sus parámetros.
2. Un bloque solo se puede escribir pegado a un envío de mensaje. No es un objeto.
3. Con `&nombre` en la firma, lo referenciás como un `Proc`. Con `&proc` en la llamada, un proc pasa como bloque.
4. `proc { … }` (o `Proc.new { … }`) convierte un bloque en objeto a mano.

### Llaves adentro de llaves

Adentro de un bloque tiene que haber código Ruby válido, y `{ … }` suelto no lo es: `proc { { puts "x" } }` falla igual que `a = { puts "x" }`, solo que un nivel más adentro. Lo que sí es válido es `proc { proc { … } }`: un proc que devuelve otro proc.

```ruby
sumar = proc { |a| proc { |b| a + b } }     # un proc que recibe a, y devuelve OTRO proc que recibe b
sumar_1 = sumar.call(1)                     # aplico el primero: obtengo un proc "que sabe que a es 1"
puts sumar_1.call(2)                        # => 3
puts sumar.call(1).call(2)                  # => 3     ← lo mismo, encadenado
```

Un proc que recibe un parámetro y devuelve un proc que espera el siguiente: es una función que devuelve otra función. *(Esto se llama aplicación parcial, y la forma general, currificación. Corresponde a la segunda mitad de la materia, con Scala y funcional; acá alcanza con ver que un proc dentro de otro proc tiene sentido.)*

---

## 7. Lambdas: dos diferencias, y nada más 🔴

> **Regla.** `lambda { … }` crea un objeto de **la misma clase `Proc`**, con una marca interna (`lambda?` → `true`). Se diferencia de un proc en **exactamente dos cosas**, independientes entre sí: (1) la lambda **valida la cantidad de parámetros** como un envío de mensaje (`ArgumentError`); el proc acomoda lo que reciba. (2) `return` en una lambda **sale de la lambda**; `return` en un proc **sale del método donde el proc fue definido**.

```ruby
mi_proc   = proc   { |x| puts x.inspect }
mi_lambda = lambda { |x| puts x.inspect }

mi_lambda.call(10)           # => 10       ← se comporta básicamente igual que el proc
puts mi_proc.class           # => Proc
puts mi_lambda.class         # => Proc     ← ⚠️ la MISMA clase. No hay una clase Lambda.
puts mi_proc.lambda?         # => false
puts mi_lambda.lambda?       # => true     ← lo distingue una marca interna
puts mi_lambda               # => #<Proc:0x… archivo.rb:2 (lambda)>   ← y se ve en el inspect
```

Ruby resolvió la variante con un flag y algunos chequeos extra, en vez de con otra clase. El manejo de contextos es de las partes más turbias de implementar en cualquier lenguaje, y esta fue la salida.

### Diferencia 1: cantidad de parámetros

```ruby
mi_proc.call(1)              # => 1
mi_proc.call                 # => nil      ← faltó un parámetro: x vale nil. No falla.
mi_proc.call(1, 2)           # => 1        ← sobró uno: lo recibe y lo ignora. No falla.

mi_lambda.call(1)            # => 1
mi_lambda.call               # => ArgumentError: wrong number of arguments (given 0, expected 1)
mi_lambda.call(1, 2)         # => ArgumentError: wrong number of arguments (given 2, expected 1)
```

| | `proc` | `lambda` |
|---|---|---|
| Parámetros de menos | los que faltan valen `nil` | `ArgumentError` |
| Parámetros de más | los ignora | `ArgumentError` |

El proc es permisivo, como una función de JavaScript. La lambda es estricta, **como un envío de mensaje**. A veces querés que te controlen que estás pasando lo correcto, y para eso está.

### Diferencia 2: a dónde va el `return`

`return` cumple **dos funciones**: dice qué devuelve el cuerpo, y es un **salto de control**, "salí del contexto en el que estás" (como el `return` adentro de un `if` que corta el método entero). Adentro de un proc, Ruby eligió: **el proc liga el `return` al contexto en el que se definió.** Hacer `call` a ese proc es como escribir el `return` ahí mismo, en el método.

```ruby
def m1_proc
  proc_con_return = proc { return 5 }    # un proc que retorna 5
  proc_con_return.call                   # lo ejecuto: es como un return 5 escrito acá → corta m1_proc
  10                                     # esta línea nunca se ejecuta
end

def m1_sin_return
  proc_sin_return = proc { 5 }           # devuelve 5 (la última expresión), sin ningún salto
  proc_sin_return.call                   # se ejecuta, devuelve 5, y ese 5 no se usa para nada
  10
end

def m1_lambda
  lambda_con_return = lambda { return 5 }   # return DENTRO de una lambda
  lambda_con_return.call                    # sale de la LAMBDA, nada más; el método sigue
  10
end
```

| Escribís | Ruby entiende | Sale |
|---|---|---|
| `puts m1_proc` | el `return` del proc es un `return` de `m1_proc` | `5` |
| `puts m1_sin_return` | el proc devuelve 5 y el método sigue | `10` |
| `puts m1_lambda` | el `return` sale de la lambda; el método sigue | `10` |

Sintácticamente podés escribir las dos cosas. `5` solo dice "este proc devuelve 5". `return 5` dice eso **y además** "salí del contexto". Como Ruby devuelve la última expresión sin necesidad de `return`, esto tiene menos impacto que en lenguajes donde el `return` es obligatorio (en Java o Smalltalk tenés que escribirlo siempre, y la ambigüedad de "¿devolver o salir?" está en cada bloque). En la lambda, `return` significa solamente "devolvé esto de la lambda": poner o no poner `return` da lo mismo, salvo para cortar temprano *dentro* de la lambda. Se comporta como un método anónimo.

### El `return` atraviesa a quien ejecute el proc

El `return` de un proc sale **del método donde el proc fue definido**, aunque el `call` lo haga otro objeto en otro lugar. Eso es lo que lo hace peligroso:

```ruby
class Ejecutador
  def ejecutar(bloque)
    bloque.call                          # otro objeto, otro método, dispara el proc
    puts "el ejecutador sigue"           # ← esta línea tampoco se ejecuta
  end
end

def m1_proc2
  proc_con_return = proc { return 5 }
  Ejecutador.new.ejecutar(proc_con_return)   # se lo doy a otro para que lo ejecute
  10
end

puts m1_proc2                            # => 5     ← el return cortó ejecutar Y m1_proc2, y volvió acá con el 5
```

Cuando se ejecutó el proc, Ruby descartó los dos contextos que estaban arriba (`ejecutar` y `m1_proc2`) y volvió al punto donde `m1_proc2` había sido llamado, con el 5. El proc recordó su contexto **al punto de poder matarlo**. Dibujado como pila de llamadas (los métodos en ejecución, apilados: cada uno llamó al de abajo):

```
   puts m1_proc2                 ◄──────────── vuelve acá, con 5
     └─ m1_proc2                 ✗ descartado   (acá nació el proc: su return es el return de m1_proc2)
          └─ ejecutar            ✗ descartado
               └─ proc.call      → return 5
```

**Cuando el método donde nació el proc ya terminó**, el `return` apunta a un contexto que ya no existe, y Ruby corta con `LocalJumpError`. De las opciones que tenía el lenguaje (romper; salir de "algún" contexto; salir de ese contexto y volver de alguna forma con el resultado), eligió romper, porque devolver un 5 es inofensivo y salir de un contexto que ya no está no lo es:

```ruby
def fabricar
  proc { return 1 }                      # el proc nace acá…
end

pr = fabricar                            # …fabricar terminó, y el proc sigue vivo, afuera
pr.call
# => LocalJumpError: unexpected return   ← el return apunta a un método que ya no está ejecutándose
```

Con `proc { 1 }`, sin `return`, devuelve 1 y listo.

### Resumen

| | `proc { }` | `lambda { }` |
|---|---|---|
| Clase | `Proc` | `Proc` (`lambda?` → `true`) |
| Se ejecuta con | `call` | `call` |
| Parámetros de más o de menos | Los acomoda (`nil` / ignora) | `ArgumentError` |
| `return` | Sale del **método donde se definió** el proc | Sale de la **lambda** |

> 🎓 **Para el parcial, si te preguntan:** *¿En qué se diferencian un proc y una lambda?*
> En dos cosas independientes. La lambda valida la cantidad de parámetros como un envío de mensaje (`ArgumentError` si no coincide); el proc acomoda lo que reciba. Y el `return` de una lambda sale solo de la lambda, mientras que el `return` de un proc sale del método en el que el proc fue definido, aunque lo ejecute otro objeto, y da `LocalJumpError` si ese método ya terminó. En todo lo demás son iguales: los dos son instancias de `Proc` y se ejecutan con `call`.

⚠️ **Sobre los nombres.** Tomá con pinzas las palabras *función*, *procedimiento*, *lambda*: rara vez significan lo que significan en la teoría. Una lambda "de verdad" recibe exactamente un parámetro; la de Ruby recibe los que declares. Las funciones pueden causar efecto. Un proc puede no poder retornar. Lo que importa es la mecánica concreta de cada tecnología, no el nombre.

---

## 8. El contador: el contexto sobrevive al método 🔴

> **Regla.** Un proc se lleva **todo** el contexto donde nació: `self` (sección 3), el destino del `return` (sección 7) y **las variables locales**, que siguen vivas mientras el proc viva, aunque el método que las creó haya terminado. Cada ejecución del método crea un contexto nuevo, con variables nuevas, y un proc nuevo pegado a él. A esto se lo llama **closure** (clausura). En Ruby, bloques, procs y lambdas son closures.

```ruby
def contador
  n = 0                      # variable local del método: nace acá, y "debería" morir cuando el método termina
  proc do                    # el proc que se devuelve usa n…
    n += 1                   # …la incrementa (n += 1 es n = n + 1)…
    n                        # …y la devuelve
  end
end                          # el método termina. Su contexto, con su n, se descarta. ¿O no?

c1 = contador                # c1 es el proc. El método contador ya terminó.
puts c1.call                 # => 1     ← n sigue viva adentro del proc
puts c1.call                 # => 2     ← y sigue siendo LA MISMA n: la aumentó el call anterior
c2 = contador                # otra llamada a contador: otro contexto, OTRA n, otro proc
puts c2.call                 # => 1     ← c2 arranca de cero
puts c1.call                 # => 3     ← c1 sigue con la suya
```

**¿CÓMO FUNCIONA?** Cuando llamás a `contador`, se crea un contexto para esa ejecución (su pila), con la variable `n`. Se crea el proc, que referencia ese contexto. El método termina y su contexto debería desaparecer… y el proc lo mantiene vivo: se queda con "el espíritu de esa pila" para poder seguir manipulando sus variables. Cada llamada a `contador` crea un contexto nuevo, con una `n` nueva, y un proc nuevo pegado a ella. `c1` y `c2` son cosas fantasma independientes, cada una asociada a su propio contexto muerto.

```
   contador()  → contexto 1              contador()  → contexto 2
   ┌──────────────────┐                  ┌──────────────────┐
   │ n = 0  → 1 → 2 → 3│ ◄── c1           │ n = 0  → 1       │ ◄── c2
   └──────────────────┘                  └──────────────────┘
     el método terminó;                     otro contexto,
     el proc lo mantiene vivo               otra n
```

Tener en memoria el contexto de un método que ya murió y poder seguir operando sobre él es tan difícil de implementar, exige tanto del metamodelo, que muy pocos lenguajes lo hacen completo. La máquina virtual de Java, por ejemplo, exige que una variable local usada desde una lambda sea efectivamente una constante: modificarla desde adentro está prohibido.

> 🕳️ **Madriguera — `self` en otras tecnologías**
> Uno cree que `self` es igual en todos lados y no: en JavaScript, `this` se resuelve de una forma que no tiene nada que ver con lo que conocés de otros lenguajes; en Python, `self` es el primer parámetro explícito de cada método, no una variable reservada. Vale la pena mirarlo por tu cuenta.
> *Volvé al camino — esto se profundiza aparte, otro día.*

**Lo que se abre con esto.** Diferir la ejecución de un pedazo de código tiene una consecuencia: ese código dispone de lo que su contexto le ofrece, y entre el momento en que lo escribís y el momento en que lo ejecutás, el programa siguió. Dos preguntas quedan planteadas, y cada tecnología las responde distinto:

1. ¿Qué pasa con el contexto cuando pasó el tiempo y recién ahora ejecuto la pieza? (Acá vimos una parte: las variables siguen vivas.)
2. ¿Qué pasa si ejecuto el bloque en un lugar donde **ya hay otra `n`**, u otro `self`? ¿Ve lo que tenía al crearse, o lo que le pongo alrededor?

Ruby va a hacer dos jugadas con esto. La primera ya la sabés: `self` es implícito, así que una palabra suelta puede ser una variable o un mensaje según el contexto. La segunda es construir algo en un momento y ejecutarlo en otro, con la memoria de lo anterior. Es una forma de **recordar**: como en Haskell, cuando aplicabas una función con menos parámetros y era como si "guardara" un atributo. Vamos a jugar con el contexto y con el momento de aplicación para modelar cosas que de otra manera no se podrían programar. Eso es la Parte 4.

---

## Checkpoint de la Parte 3

Sin respuestas.

1. `puts "hola"`: ¿quién recibe el mensaje? ¿Dónde está definido `puts`, y qué implica eso? ¿Por qué `2.puts(self)` falla y `2.send(:puts, self)` no?
2. `2.send(:puts, self)` imprime `main` en un archivo suelto. ¿Quién es el receptor, quién es el argumento, y dónde se evaluó cada uno? ¿Qué imprime la misma línea adentro de un método de `Guerrero`?
3. `a = { puts "x" }` falla. `a = {}` no falla. Explicá las dos.
4. `[1,2,3].each(imprimir)` da "given 1, expected 0". ¿Por qué `each` espera cero parámetros si siempre lo usás con un bloque?
5. `pr = proc { puts "x" }`: ¿qué se imprime al ejecutar esa línea? ¿Qué falta para que se imprima "x"? ¿Qué es `proc`: sintaxis, mensaje, clase?
6. ¿Quién es `self` adentro de `proc { puts self }` escrito en un archivo suelto? ¿Y adentro de un proc creado dentro de un método de `atila`?
7. `def m(un_bloque); un_bloque.call; end` no recibe bloques. ¿Por qué, y cuáles son las dos formas correctas? ¿Qué error da cada forma si no le pasan bloque, y cómo lo evitás en las dos?
8. Escribí `yield if block_given?` en su forma larga, y `puts "x" unless c` como un `if`.
9. Necesitás pasarle a un método tres cachos de lógica. ¿Cómo lo hacés, y por qué no podés hacerlo con bloques?
10. El `&` significa cosas distintas en `def m(&b)` y en `m(&un_proc)`. ¿Cuáles? ¿Con qué operador tiene la misma dualidad?
11. Con `mostrar = proc { |n| puts n }` y el `m23` de la sección 6: ¿qué sale con `m23(10, 20) { mostrar.call }`, con `m23(10, 20) { |n| mostrar(n).call }` y con `m23(10, 20, mostrar)`? Explicá cada uno.
12. Dos diferencias entre proc y lambda. Para cada una, un ejemplo de código donde se note.
13. `def m; pr = proc { return 1 }; Ejecutador.new.ejecutar(pr); 2; end`: ¿qué devuelve `m` si `ejecutar` hace `pr.call`? ¿Y si `m` devolviera `pr` sin ejecutarlo, y vos hicieras `pr.call` afuera?
14. Explicá con el contador por qué `c1` y `c2` no comparten la `n`, y qué significa que un proc es un closure.

---

## Qué viene en la Parte 4

Contextos. Un nombre suelto en Ruby (`nombre`, `energia`, `atila`) puede ser una variable local o un mensaje a `self`, y hay un algoritmo para decidirlo. Vas a ver qué ve un proc de las variables de afuera (todo), qué puede modificar (todo), qué agrega (nada), y por qué una variable creada *después* del proc no existe para él. Después, las tres construcciones que **cortan** el contexto (`def`, `class`, `module`) y sus reemplazos que no lo cortan (`define_method`, `Class.new`). Y la herramienta que cierra la clase: `instance_eval`, que ejecuta un bloque cambiándole el `self`, con `class_eval` al lado.

**FIN DE LA PARTE 3**
