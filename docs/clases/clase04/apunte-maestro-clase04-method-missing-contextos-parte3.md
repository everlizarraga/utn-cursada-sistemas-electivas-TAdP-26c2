# Apunte maestro — clase04 — `method_missing`, bloques, contextos e `instance_eval`
## Parte 3 — Bloques, procs y lambdas

> **Qué cubre esta parte.** Qué es de verdad un bloque en Ruby (y por qué no es un objeto), cómo se convierte en uno (`proc`), cómo recibe un método un bloque y qué hace con él (`yield`, `&bloque`), cómo se pasa un proc donde se espera un bloque (`&proc`), en qué se diferencian un proc y una lambda, y un contador que recuerda una variable de un método que ya terminó. Antes de todo eso, un detalle que sostiene el resto: a quién le llega un mensaje sin receptor.
>
> **De dónde venís.** De las Partes 1 y 2: `method_missing`, el registrador. De la clase 3: `send`, `method(:x)`, `methods`, `instance_methods`, `ancestors`. De la clase 1: `each` con `do … end`.
>
> **Código.** Ruby 3.3 con el `age.rb` de la materia. Resultados como comentario al lado de cada línea. Los ejemplos de bloques y procs no usan `age.rb` salvo que se indique.

---

## 1. El receptor implícito: `puts "hola"` es un mensaje 🔴

La línea más común de Ruby esconde la regla más importante del lenguaje:

```ruby
puts "hola"          # => hola
self.puts("hola")    # => hola     ← es EXACTAMENTE la misma línea, escrita completa
```

`puts` no es una instrucción del lenguaje. Es un **mensaje**, como `atacar`, que recibe un string por parámetro. Y en la primera línea no hay receptor escrito. **Cada vez que hay un envío de mensaje sin receptor, el que lo recibe es `self`**: el objeto que está "hablando" en ese punto del programa. ¿Y quién es `self` en un archivo suelto, fuera de toda clase?

```ruby
puts self            # => main       ← un objeto que Ruby crea para ejecutar el archivo
puts self.class      # => Object     ← es una instancia común de Object; se llama a sí mismo "main"
```

Todo lo que escribís "suelto" en un archivo son mensajes que le mandás a `main`. Y si `main` es un `Object` y entiende `puts`, entonces `puts` tiene que estar definido en algún lugar de la cadena de `Object`. Está en `Kernel`, el mixin que `Object` incluye. Lo que implica que **cualquier objeto entiende `puts`**:

```ruby
2.puts(self)
# => NoMethodError: private method `puts' called for an instance of Integer
#    ⚠️ lo entiende, pero es privado: no se puede mandar con receptor explícito. send salta la privacidad:
2.send(:puts, self)          # => main      ← el 2 imprimió a main
"hola".send(:puts, self)     # => main      ← un string también
```

**`self` es una variable que depende del contexto**: quién es `self` en cada punto del programa lo define dónde está escrita esa línea. (Contexto: el lugar del programa en el que está una línea, con las variables que esa línea puede ver y con quién es `self` ahí. La Parte 4 lo desarma pieza por pieza.) Adentro de un método de `Guerrero`, `self` es el guerrero que recibió el mensaje; en un archivo suelto, es `main`. Esta idea vuelve en la sección 3 y es todo el eje de la Parte 4.

---

## 2. Bloques: código que no es un objeto 🔴

Esto lo venís usando desde la primera clase:

```ruby
[1, 2, 3].each { |n| puts n }        # Resultado esperado: 1, 2, 3 (uno por línea)
[1, 2, 3].each do |n| puts n end     # exactamente lo mismo: do … end y las llaves son equivalentes
```

Ese `{ |n| puts n }` es un **bloque**: un cacho de código, con sentencias adentro, que `each` ejecuta una vez por elemento. Hasta acá, igual que en cualquier lenguaje que tenga algo parecido (en Wollok, un bloque es un objeto: lo guardás en una variable, le mandás `apply`).

Y acá está lo que Ruby decidió distinto, y que va a morder si no lo sabés: **en Ruby, un bloque no es un objeto.** No lo podés guardar en una variable, no le podés mandar mensajes, no lo podés pasar como parámetro.

```ruby
a = {}                     # ⚠️ esto no es un bloque vacío: es un Hash vacío. Las llaves solas son sintaxis de hash.
p a.class                  # => Hash

a = { puts "hola" }        # => SyntaxError   ← el parser no sabe qué es esto: no es un hash y un bloque no va acá
```

Un bloque **solo puede aparecer en un lugar**: pegado al final de un envío de mensaje. Es parte de la sintaxis del envío, no una expresión que valga por sí misma:

```ruby
imprimir_n = { |n| puts n }   # => SyntaxError   ← no hay forma de "tener" el bloque suelto
```

Es una decisión rara del lenguaje, de las que parecen atadas con alambre, y la razón es que querían esta sintaxis simpática de `do … end` al final de un mensaje. No es central para metaprogramación, pero como estamos programando en Ruby hay que saberlo para no confundirse. En la sección siguiente, la forma de tener un cacho de código como objeto; y ahí se ve la otra consecuencia de esta decisión.

---

## 3. `proc`: el bloque convertido en objeto 🔴

Si quiero agarrar un cacho de lógica y usarlo **como un objeto** (guardarlo, pasarlo, ejecutarlo cuando quiera), no alcanza con el bloque. Lo que hago es mandarle el bloque al mensaje `proc`:

```ruby
imprimir = proc { puts "hola" }    # proc + un bloque → un OBJETO que representa esa lógica. No se imprime nada.
puts imprimir                      # => #<Proc:0x… archivo.rb:1>   ← es un objeto, y lo puedo mostrar
puts imprimir.class                # => Proc                       ← de la clase Proc
```

Fijate que `puts imprimir` no imprime "hola". El código de adentro **no se ejecuta** hasta que se lo pidas. Un proc es un cacho de código cuya ejecución está **diferida**: se lo pedís con `call`.

```ruby
imprimir.call                      # => hola     ← recién acá se ejecuta
imprimir.call                      # => hola     ← y tantas veces como quieras
imprimir.call                      # => hola
```

Esa es toda la gracia de los bloques y los procs: escribir código ahora para ejecutarlo después, cuantas veces haga falta, en otro momento y en otro lugar.

Y ahora que tengo el código como objeto, ¿se lo puedo pasar a `each` como parámetro, en vez de escribirle el bloque?

```ruby
imprimir_n = proc { |n| puts n }
[1, 2, 3].each(imprimir_n)
# => ArgumentError: wrong number of arguments (given 1, expected 0)      ← la excepción de "cantidad de argumentos incorrecta"
#    ⚠️ each espera CERO parámetros. El bloque no se cuenta entre los parámetros: es otra cosa.
```

Cada parámetro de un mensaje es un objeto; el bloque no lo es, así que Ruby lo cuenta aparte. Un proc es un objeto y por eso ocupa lugar de parámetro, y `each` no acepta ninguno. Cómo se le pasa un proc a un mensaje que espera un bloque es la sección 6.

### `proc` es un mensaje, `Proc` es una clase

Con lo de la sección 1 podés deducir qué es `proc`. Es una palabra suelta, sin receptor, seguida de un bloque. Y un bloque solo va pegado a un envío de mensaje. Entonces `proc` es un **mensaje a `self`**:

```ruby
puts method(:proc).owner                 # => Kernel    ← definido en Kernel: lo entiende cualquier objeto
otro_proc = Proc.new { 5 + 11 }          # Proc.new también recibe un bloque, y hace lo mismo que proc { … }
puts otro_proc.class                     # => Proc

puts Proc.instance_methods(false).inspect   # inspect: la representación "de programador" del objeto, la que muestra p
# => [:<<, :==, :===, :>>, :[], :arity, :binding, :call, :clone, :curry, :dup, :eql?, :hash, :inspect,
#     :lambda?, :parameters, :ruby2_keywords, :source_location, :to_proc, :to_s, :yield]
#    ↑ los mensajes que define Proc (el orden puede variar): call, arity, lambda?, binding, curry… varios van a aparecer
```

`proc { … }` aprovecha que todo mensaje puede recibir un bloque al final (sección 4) para crear un objeto a partir de él. Nada más que eso. Es un mensaje que devuelve una instancia de `Proc`, y en el metamodelo de la clase 3 es un objeto más: tiene clase, tiene autoclase, entiende mensajes.

### Quién es `self` adentro de un proc

```ruby
imprimir_self = proc { puts self }
puts self                    # => main
imprimir_self.call           # => main     ← el mismo self que había afuera del bloque
```

Uno podría pensar que `self` adentro del bloque es el proc. No: es **el mismo `self` que había en el lugar donde el bloque fue escrito**. El bloque se acuerda del contexto en el que se definió y lo referencia. Es lo que hacen los bloques en la mayoría de los lenguajes. Guardá esto: en la Parte 4 vamos a ver que Ruby te deja cambiarlo.

---

## 4. Todo mensaje recibe un bloque, y casi todos lo ignoran 🔴

Regla de Ruby: **todos los mensajes, además de sus parámetros, pueden recibir un bloque al final.** La mayoría no hace nada con él.

```ruby
puts() { puts self }         # imprime una línea vacía (lo que hace puts sin argumentos)… y el bloque se ignora
-10.abs { puts "hola" }      # => 10     ← abs (valor absoluto) acepta el bloque y lo ignora; "hola" nunca se imprime

def m1                       # un método propio, sin parámetros, sin cuerpo
end

m1 { puts "chau" }           # no imprime nada, y no falla: m1 recibió el bloque y no lo usó
```

`m1` recibió el bloque. Como `puts` y `abs`, no hizo nada con él. Para que un mensaje **use** el bloque, hay que escribirlo en el cuerpo del método. Hay dos formas.

---

## 5. Usar el bloque: `yield` y `&bloque` 🔴

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
```

Pero si no le pasás un bloque:

```ruby
m1
# => LocalJumpError: no block given (yield)     ← yield sin bloque explota
```

Con `yield`, el bloque es obligatorio. Si querés que sea opcional, preguntás antes con `block_given?`:

```ruby
def m1
  yield if block_given?      # ejecutá el bloque solo si me pasaron uno
  puts "M1"
end

m1                           # => M1
m1 { puts "bloqueee" }       # => bloqueee
                             #    M1
```

`yield if block_given?` es el `if` de una línea: la sentencia de la izquierda se ejecuta solo si se cumple la condición de la derecha. Es idéntico a escribir `if block_given?` / `yield` / `end` en tres líneas.

Esta forma es la que más muestra lo especial (en el mal sentido) que son los bloques: el bloque llega sin nombre, sin aparecer en la firma, y lo invocás con una palabra reservada. Hay otra sintaxis bastante más agradable.

### Forma 2: `&bloque`, capturalo como objeto

Vimos que todos los mensajes reciben un bloque después de sus parámetros. Podemos **escribir eso en la firma**:

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

Con `&`, el bloque **entra al método convertido en `Proc`**, automáticamente: es lo mismo que hacía `proc { … }`, pero hecho por Ruby al recibir el mensaje. Una vez adentro es un objeto común: lo podés ejecutar, guardar, devolver, pasar a otro. Eso no lo podías hacer con `yield`.

> **Reificar:** convertir en objeto algo que no lo era. Un envío de mensaje "pasa"; un `Proc` es ese "pasa" convertido en cosa, con identidad, que podés guardar y pasar. `&bloque` reifica el bloque.

```
   m1 { |n| puts n }
        │
        │  def m1              → yield ejecuta el bloque acá, y no lo tenés como objeto
        │
        │  def m1(&bloque)     → bloque = Proc (el bloque reificado): call, guardar, devolver, pasar
```

⚠️ **Si no pasás bloque, `bloque` vale `nil`.** El error que da no es el de `yield`:

```ruby
m1
# => NoMethodError: undefined method `call' for nil      ← bloque es nil, y nil no entiende call
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

Un método que necesita **dos** cachos de lógica. Por ejemplo, dos cálculos que vienen de lugares distintos y hay que sumar sus resultados. ¿Cómo se los pasás? Un método recibe **un solo** bloque, al final. No podés poner `&bloque, &otro_bloque`.

La salida es la de siempre cuando algo no es objeto: **hacerlo objeto**. El bloque no es un parámetro; el proc sí. Entonces se piden dos procs:

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
#    ⚠️ m2 espera cero parámetros y un bloque; le pasaste un objeto, que ocupa lugar de parámetro

m2 { imprimir_3 }          # no falla, pero no imprime nada: pasaste un bloque que DEVUELVE el proc, sin ejecutarlo
```

Ruby tiene una forma de decir "tengo un proc, convertilo en el bloque que este mensaje espera": el mismo `&`, pero **en la llamada**:

```ruby
m2(&imprimir_3)            # => 3      ← el proc entró como el bloque de m2
```

Regla del `&`: **en una firma, captura** (bloque → `Proc`); **en una llamada, convierte** (`Proc` → bloque). Es la misma dualidad del `*` con los arrays en la Parte 2.

Las reglas de los bloques, todas juntas, son pocas:

1. Todo mensaje puede recibir un bloque, uno solo, al final de sus parámetros.
2. Un bloque solo se puede escribir pegado a un envío de mensaje. No es un objeto.
3. Con `&nombre` en la firma, lo referenciás como un `Proc`. Con `&proc` en la llamada, un proc pasa como bloque.
4. `proc { … }` (o `Proc.new { … }`) convierte un bloque en objeto a mano.

### Llaves adentro de llaves

Si `{ … }` solo vale pegado a un mensaje, ¿qué pasa con un bloque adentro de otro? Lo mismo: **adentro de un bloque tiene que haber código Ruby válido**, y `{ … }` suelto no lo es. `proc { { puts "x" } }` falla igual que `a = { puts "x" }`, solo que un nivel más adentro. Lo que sí es válido es `proc { proc { … } }`: un proc que devuelve otro proc.

```ruby
sumar = proc { |a| proc { |b| a + b } }     # un proc que recibe a, y devuelve OTRO proc que recibe b
sumar_1 = sumar.call(1)                     # aplico el primero: obtengo un proc "que sabe que a es 1"
puts sumar_1.call(2)                        # => 3
puts sumar.call(1).call(2)                  # => 3     ← lo mismo, encadenado
```

Un proc que recibe un parámetro y devuelve un proc que espera el siguiente: es una función que devuelve otra función. *(Esto se llama aplicación parcial, y la forma general, currificación. Corresponde a la segunda mitad de la materia, con Scala y funcional; acá alcanza con ver que un proc dentro de otro proc tiene sentido.)*

---

## 7. Lambdas: dos diferencias, y nada más 🔴

Hay otra forma de crear un objeto a partir de un bloque: el mensaje `lambda`.

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

Ruby no modeló esto con dos clases, que sería lo esperable. Una lambda es **un proc con un flag y algunos chequeos extra**. El manejo de contextos es de las partes más turbias de implementar en cualquier lenguaje, así que no es raro que Ruby haya resuelto la variante con un flag en vez de con otra clase. Se diferencian en **exactamente dos cosas**, que no tienen nada que ver una con la otra.

### Diferencia 1: cantidad de parámetros

```ruby
mi_proc.call(1)              # => 1
mi_proc.call                 # => nil      ← faltó un parámetro: x vale nil. No falla.
mi_proc.call(1, 2)           # => 1        ← sobró uno: lo recibe y lo ignora. No falla.

mi_lambda.call(1)            # => 1
mi_lambda.call               # => ArgumentError: wrong number of arguments (given 0, expected 1)
mi_lambda.call(1, 2)         # => ArgumentError: wrong number of arguments (given 2, expected 1)
```

El proc es permisivo: de menos, `nil`; de más, ignora. Como una función de JavaScript. La lambda es estricta, **como un envío de mensaje**: la cantidad tiene que coincidir, o `ArgumentError`. A veces querés que te controlen que estás pasando lo correcto, y para eso está.

### Diferencia 2: a dónde va el `return`

Un método con un proc adentro que hace `return`:

```ruby
def m1_proc
  proc_con_return = proc { return 5 }    # un proc que retorna 5
  proc_con_return.call                   # lo ejecuto
  10                                     # y el método devuelve 10… ¿o no?
end

puts m1_proc                             # => 5
```

Devuelve **5**, no 10. ¿Por qué? Primero, la pregunta de fondo: `return` cumple **dos funciones**. Una es decir qué devuelve el cuerpo. La otra es un **salto de control**: "salí del contexto en el que estás", como cuando hacés `return` adentro de un `if` y cortás el método entero. En muchos lenguajes la misma palabra hace las dos cosas (otros tienen palabras distintas, como el `break` que corta un `switch` sin retornar). Entonces, adentro de un proc, ¿`return` sale del bloque y devuelve el valor, o sale del **método**?

Ruby eligió: **el proc liga el `return` al contexto en el que se definió.** Hacer `call` a ese proc es como si escribieras el `return` ahí mismo, en el método: corta `m1_proc` temprano, y la línea del `10` nunca se ejecuta.

Comparalo con la misma cosa sin `return`:

```ruby
def m1_proc
  proc_sin_return = proc { 5 }           # devuelve 5 (la última expresión), pero no hace ningún salto
  proc_sin_return.call                   # se ejecuta, devuelve 5, y ese 5 no se usa para nada
  10
end

puts m1_proc                             # => 10     ← el método siguió normal
```

Sintácticamente podés escribir las dos cosas. `5` solo dice "este proc devuelve 5". `return 5` dice eso **y además** "salí del contexto". Como Ruby devuelve la última expresión sin necesidad de `return`, esto tiene menos impacto que en lenguajes donde el `return` es obligatorio (en Java o Smalltalk tenés que escribirlo siempre, y la ambigüedad de "¿devolver o salir?" está en cada bloque).

Y la lambda:

```ruby
def m1_lambda
  lambda_con_return = lambda { return 5 }   # return DENTRO de una lambda
  lambda_con_return.call                    # sale de la LAMBDA, nada más; el método sigue
  10
end

puts m1_lambda                              # => 10
```

En la lambda, `return` significa solamente "devolvé esto de la lambda". Poner o no poner `return` da lo mismo, salvo para cortar temprano *dentro* de la lambda. Se comporta como un método anónimo.

### El `return` atraviesa a quien ejecute el proc

Esto es lo que hace peligroso al `return` de un proc. No sale "del método que hizo `call`": sale **del método donde el proc fue definido**, aunque el `call` lo haga otro objeto en otro lugar.

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

Y la pregunta que esto abre: ¿qué pasa si el método donde nació el proc **ya terminó** cuando lo ejecutás? Por ejemplo, un método que en vez de ejecutar el proc lo **devuelve**, y alguien lo ejecuta después, afuera. El abanico de lo que un lenguaje podría hacer: romper todo; salir de "algún" contexto; salir de ese contexto y volver de alguna forma con el resultado. Algunas de esas opciones son aberraciones. Ruby elige romper, porque no hay ningún problema en devolver un 5, pero sí lo hay en salir de un contexto que ya no existe:

```ruby
def fabricar
  proc { return 1 }                      # el proc nace acá…
end

pr = fabricar                            # …fabricar terminó, y el proc sigue vivo, afuera
pr.call
# => LocalJumpError: unexpected return   ← el return apunta a un método que ya no está ejecutándose
```

Con `proc { 1 }`, sin `return`, no pasa nada de esto: devuelve 1 y listo.

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

Un proc se acuerda del `self` del lugar donde nació (sección 3) y de dónde se ejecuta su `return` (sección 7). Ahora la demostración más fuerte de que se lleva **todo** el contexto, incluidas las variables:

```ruby
def contador
  n = 0                      # variable local del método: nace acá, y "debería" morir cuando el método termina
  proc do                    # el proc que se devuelve usa n…
    n += 1                   # …la incrementa…
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

**¿CÓMO FUNCIONA?** Cuando llamás a `contador`, se crea un contexto para esa ejecución (su pila), con la variable `n`. Se crea el proc, que referencia ese contexto. El método termina y su contexto debería desaparecer… pero el proc lo mantiene vivo: se queda con "el espíritu de esa pila" para poder seguir manipulando sus variables. Cada llamada a `contador` crea un contexto nuevo, con una `n` nueva, y un proc nuevo pegado a ella. `c1` y `c2` son cosas fantasma independientes, cada una asociada a su propio contexto muerto.

```
   contador()  → contexto 1              contador()  → contexto 2
   ┌──────────────────┐                  ┌──────────────────┐
   │ n = 0  → 1 → 2 → 3│ ◄── c1           │ n = 0  → 1       │ ◄── c2
   └──────────────────┘                  └──────────────────┘
     el método terminó;                     otro contexto,
     el proc lo mantiene vivo               otra n
```

A esto se lo llama **closure** (clausura): un objeto que representa código y que **encierra** el contexto en el que fue definido, manteniéndolo vivo mientras el objeto viva. En Ruby, bloques, procs y lambdas son closures.

Tener en memoria el contexto de un método que ya murió y poder seguir operando sobre él es tan difícil de implementar, exige tanto del metamodelo, que muy pocos lenguajes lo hacen completo. La máquina virtual de Java, por ejemplo, no lo banca: si usás una variable local desde una lambda, esa variable tiene que ser efectivamente una constante; no la podés modificar desde adentro.

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
2. `a = { puts "x" }` falla. `a = {}` no falla. Explicá las dos.
3. `[1,2,3].each(imprimir)` da "given 1, expected 0". ¿Por qué `each` espera cero parámetros si siempre lo usás con un bloque?
4. `pr = proc { puts "x" }`: ¿qué se imprime al ejecutar esa línea? ¿Qué falta para que se imprima "x"? ¿Qué es `proc`: sintaxis, mensaje, clase?
5. ¿Quién es `self` adentro de `proc { puts self }` escrito en un archivo suelto? ¿Y adentro de un proc creado dentro de un método de `atila`?
6. `def m(un_bloque); un_bloque.call; end` no recibe bloques. ¿Por qué, y cuáles son las dos formas correctas? ¿Qué error da cada forma si no le pasan bloque?
7. Necesitás pasarle a un método tres cachos de lógica. ¿Cómo lo hacés, y por qué no podés hacerlo con bloques?
8. El `&` significa cosas distintas en `def m(&b)` y en `m(&un_proc)`. ¿Cuáles? ¿Con qué operador tiene la misma dualidad?
9. Dos diferencias entre proc y lambda. Para cada una, un ejemplo de código donde se note.
10. `def m; pr = proc { return 1 }; Ejecutador.new.ejecutar(pr); 2; end`: ¿qué devuelve `m` si `ejecutar` hace `pr.call`? ¿Y si `m` devolviera `pr` sin ejecutarlo, y vos hicieras `pr.call` afuera?
11. Explicá con el contador por qué `c1` y `c2` no comparten la `n`, y qué significa que un proc es un closure.

---

## Qué viene en la Parte 4

Contextos. Un nombre suelto en Ruby (`nombre`, `energia`, `atila`) puede ser una variable local o un mensaje a `self`, y hay un algoritmo para decidirlo. Vas a ver qué ve un proc de las variables de afuera (todo), qué puede modificar (todo), qué agrega (nada), y por qué una variable creada *después* del proc no existe para él. Después, las tres construcciones que **cortan** el contexto (`def`, `class`, `module`) y sus reemplazos que no lo cortan (`define_method`, `Class.new`). Y la herramienta que cierra la clase: `instance_eval`, que ejecuta un bloque cambiándole el `self`, con `class_eval` al lado.

**FIN DE LA PARTE 3**
