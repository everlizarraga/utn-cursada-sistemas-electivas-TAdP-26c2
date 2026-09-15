# Clase desde Cero — Clase 04 (2020) — Módulo 4
## Bloques, procs y lambdas

> **Sobre este documento.** Cubre la segunda de las tres ideas de la clase: **un objeto que guarda código para ejecutarlo después, y que se lleva el contexto donde nació**. Vas a ver qué es un proc, cómo se ejecuta, cómo se le pasa un bloque a un método (`yield` y `&bloque`), qué ve un bloque y qué no (closures), las dos diferencias entre proc y lambda, y la resolución del problema del módulo 3: `define_method` y `Class.new`. Es el módulo más largo.
> **No cubre:** quién es `self` dentro de un bloque y cómo cambiarlo. Eso se roza al final y es el módulo 5.

> **De dónde venís.** Del módulo 3: el contexto es variables locales + `self`; `class`, `module` y `def` lo cortan; el problema de empaquetar código sin perder las variables. Del módulo 1: `each` con bloque, las dos sintaxis `{}` / `do…end`, `p` vs `puts`. De la clase 03: `define_method` existía como herramienta; acá vas a entender por qué recibe un bloque.

---

## 1. Reificar comportamiento: el proc 🔴

Esta línea imprime "hola":

```ruby
puts "hola"      # => hola
```

Es un envío de mensaje: `puts` a `self`. Ahora quiero **tener** esa colaboración sin **hacerla** todavía. Guardarla en una variable, como si fuera un dato, y decidir después si la ejecuto, cuántas veces, o si se la paso a otro.

```ruby
imprimir_hola = proc { puts "hola" }    # proc + un bloque: crea un OBJETO que representa esa colaboración
                                        # (no se imprime nada: solo se creó el objeto)
p imprimir_hola.class                   # => Proc          ← es un objeto, de la clase Proc
p imprimir_hola                         # => #<Proc:0x... archivo.rb:1>
```

A esto se le dice **reificar**: convertir en objeto algo que no lo era. Un envío de mensaje no es un objeto; es algo que pasa. Un `Proc` es ese "algo que pasa" convertido en cosa, con identidad, que podés guardar, pasar y ejecutar cuando quieras.

### Dónde va esto en tu mapa

Nada nuevo en el metamodelo de la clase 3. Un proc es un objeto más, y `Proc` es una clase más, en el mismo diagrama que ya tenés:

```ruby
p imprimir_hola.class               # => Proc                      ← es instancia de Proc
p Proc.class                        # => Class                     ← Proc es una clase, como Guerrero
p Proc.superclass                   # => Object                    ← hereda de Object, como Guerrero
p imprimir_hola.singleton_class     # => #<Class:#<Proc:0x...>>    ← y tiene autoclase, como todo objeto
```

```
   imprimir_hola ──(clase)──► Proc ──(superclase)──► Object ──► Kernel ──► BasicObject
        │                      │
   #imprimir_hola          (clase)──► Class            ← igual que atila / Guerrero / Class
```

Y `proc { … }` tampoco es sintaxis nueva: es un **mensaje** a `self`, como `puts`. Lo entiende `main` porque está definido en `Kernel`. Lo que tiene de particular es que recibe un bloque, y devuelve ese bloque convertido en objeto.

Para ejecutarlo, le mandás `call`:

```ruby
imprimir_hola.call     # => hola
imprimir_hola.call     # => hola     ← tantas veces como quieras
```

Si nunca le mandás `call`, el código adentro **nunca se ejecuta**. Un proc es una promesa, no una acción.

Puede recibir argumentos, que se declaran entre barras verticales:

```ruby
saludar = proc { |a_quien| puts "hola #{a_quien}" }   # |a_quien| es el parámetro del proc
saludar.call("atila")                                  # => hola atila
p saludar.call("x")                                    # => hola x
                                                       #    nil          ← call devuelve lo que devolvió el bloque; puts devuelve nil
```

---

## 2. El proc se lleva el contexto donde nació: closures 🔴

Acá está la respuesta al módulo 3. Un proc **no es una compuerta**: ve las variables locales del lugar donde fue creado.

```ruby
nombre = "atila"
presentar = proc { puts "Soy " + nombre }    # el proc usa una variable de AFUERA
presentar.call                               # => Soy atila     ← la ve. def no podía; proc sí.
```

Y no es una copia: es una referencia viva al contexto. Las puede **modificar**, y ve los cambios que ocurran después de crearlo:

```ruby
nombre = "atila"
renombrar = proc { nombre = "marta" }     # el proc asigna la variable de afuera
puts nombre                               # => atila     ← todavía no se ejecutó el proc
renombrar.call
puts nombre                               # => marta     ← el proc modificó la variable del contexto exterior

saludar = proc { puts "hola " + nombre }
nombre = "josefa"                         # cambio la variable DESPUÉS de crear el proc
saludar.call                              # => hola josefa   ← el proc ve el valor actual, no el de cuando nació
```

⚠️ **Trampa de orden:** si ponés el `puts nombre` *antes* del `call`, ves el valor viejo y podés creer que el proc no modifica nada. El proc no hizo nada todavía. Modifica cuando se ejecuta, no cuando se define.

Lo que un proc **no** puede es agregar variables al contexto de afuera. Lo que crea adentro, se queda adentro:

```ruby
crear = proc { adentro = 1 }     # variable nueva, creada dentro del proc
crear.call
puts adentro
# => NameError: undefined local variable or method 'adentro' for main:Object
```

Esto cierra el hilo del módulo 3, sección 5: el bloque **lee y modifica** el contexto exterior, pero **no le agrega** nombres. Un contexto a medias: abierto hacia afuera, cerrado hacia adentro.

### El contador: el contexto sobrevive al método

La demostración definitiva de que el proc *se lleva* el contexto, no lo consulta:

```ruby
def contador
  n = 0                    # variable local del método: nace acá
  proc do                  # el proc se lleva n consigo
    n += 1
    n
  end                      # el método devuelve el proc. Al terminar, el contexto del método "debería" morir...
end

c1 = contador              # c1 es un proc. El método contador ya terminó.
p c1.call                  # => 1     ← ...pero n sigue viva, adentro del proc
p c1.call                  # => 2
p c1.call                  # => 3

c2 = contador              # OTRA llamada a contador: OTRO n, otro proc
p c2.call                  # => 1     ← c2 tiene su propio n
p c1.call                  # => 4     ← c1 sigue con el suyo
```

`n` nació en un contexto que ya no existe (el método terminó), y sin embargo sigue ahí, porque el proc la **encerró**. Por eso a estos objetos se les dice **closures** (clausuras): cierran sobre el contexto donde nacieron y lo mantienen vivo mientras ellos vivan.

```
   contador()                          contador()
   ┌──────────────┐                    ┌──────────────┐
   │ n = 0        │                    │ n = 0        │
   │ proc { n+=1 }│──► c1              │ proc { n+=1 }│──► c2
   └──────────────┘                    └──────────────┘
      el método termina,                  otro contexto,
      el proc se queda con SU n           otro n
```

> 🎓 **Para el parcial, si te preguntan:** *¿Qué es un closure?*
> Un objeto que representa un pedazo de código y que conserva el contexto (las variables locales y `self`) del lugar donde fue definido. Cuando se ejecuta, ve y puede modificar esas variables, aunque el contexto original ya haya terminado. En Ruby, bloques, procs y lambdas son closures.

---

## 3. Pasarle un bloque a un método: `yield` y `&bloque` 🔴

Ya usaste esto sin saber cómo funciona:

```ruby
[1, 2, 3].each { |n| puts n }     # el { |n| puts n } es un BLOQUE que le pasás a each
```

Conceptualmente, ese bloque es lo mismo que un proc: código para ejecutar después, con su contexto. Pero sintácticamente **no es un objeto**: no hay `proc` adelante, no lo guardaste en ninguna variable. Es parte de la sintaxis del envío de mensaje. En Ruby, **cualquier mensaje puede llevar un bloque al final**, y el método que lo recibe decide qué hacer con él.

Por eso el bloque **no está en el mapa** de la clase 3, y por eso cuesta ubicarlo: no tiene clase, no tiene autoclase, no se le puede mandar un mensaje. Existe solo pegado al mensaje que lo lleva.

```
   [1, 2, 3].each { |n| puts n }
                  └─────┬──────┘
                     bloque: fuera del mapa. Sin clase, sin autoclase, sin variable.
                     Vive solo mientras dura el envío de each.

   def m4(&bloque) … end            ← con & en la firma (más abajo), el bloque ENTRA al mapa:
        bloque ──(clase)──► Proc       pasa a ser un Proc, y ahí sí tiene todo lo demás
```

### Todo método recibe un bloque, aunque lo ignore

```ruby
def m1        # un método sin parámetros y sin cuerpo
end

m1 do         # le pasás un bloque igual. No falla: no imprime nada, pero no falla.
  puts "chau"
end
```

El bloque llegó. `m1` no lo usó. Y no lo podés recibir como parámetro común:

```ruby
def m1b(un_bloque)      # ⚠️ esto NO recibe el bloque: declara un parámetro posicional
end

m1b do
  puts "chau"
end
# => ArgumentError: wrong number of arguments (given 0, expected 1)
#    "given 0": el bloque no cuenta como argumento. Es otra cosa.
```

Hay dos formas de usar el bloque que te pasaron.

### Forma 1: `yield`, ejecutalo acá

```ruby
def m2
  yield          # ejecuta el bloque asociado a esta llamada
  yield          # otra vez
end

m2 do
  puts "chau"
end
# Resultado esperado:
# chau
# chau
```

`yield` le puede pasar argumentos al bloque, y devuelve lo que el bloque devolvió:

```ruby
def m3
  yield(3)                 # ejecuta el bloque pasándole 3
end

p m3 { |x| x + 2 }         # => 5     ← el bloque recibió 3, devolvió 5, yield devolvió 5, m3 devolvió 5
```

Limitación de `yield`: solo podés ejecutar el bloque **ahí adentro**. No lo podés guardar ni pasárselo a otro, porque no lo tenés como objeto.

### Forma 2: `&bloque`, capturalo como objeto

```ruby
def m4(&bloque)      # el & en la firma dice: "el bloque que me pasen, dámelo como un Proc llamado bloque"
  p bloque.class     # => Proc     ← ahora es un objeto
  bloque.call        # se ejecuta como cualquier proc
  bloque.call
end

m4 { puts "chau" }
# Resultado esperado:
# Proc
# chau
# chau
```

Ahora sí lo tenés como cosa. Lo podés devolver, guardar en una variable de instancia, meter en una lista:

```ruby
def m5(&bloque)
  bloque                        # devuelvo el proc sin ejecutarlo
end

guardado = m5 { puts "guardado" }    # el bloque salió del método convertido en objeto
p guardado.class                     # => Proc
guardado.call                        # => guardado    ← lo ejecuto cuando quiero
```

Esto es lo que hace el framework de testing del módulo 6: `def test(nombre, &contenido)` guarda el bloque en una lista y lo ejecuta más tarde.

```
   m4 { puts "chau" }
        │
        │  yield             → ejecuta el bloque acá, no lo tenés como objeto
        │
        │  def m4(&bloque)   → bloque = Proc (el bloque reificado): call, guardar, devolver, pasar
```

### El `&` también va al revés: pasar un proc como bloque

Si ya tenés un proc y el método espera un bloque, el `&` en la **llamada** convierte el proc en el bloque de ese mensaje:

```ruby
imprimir_3 = proc { puts "3" }

def m6(&b)
  b.call
end

m6(&imprimir_3)              # => 3     ← el proc entró como bloque

mostrar = proc { |n| puts n }
[1, 2].each(&mostrar)        # => 1     ← each recibe el proc como si fuera { |n| puts n }
                             #    2
```

⚠️ **Trampa:** sin el `&`, le estás pasando el proc como argumento posicional, y `each` no acepta argumentos:

```ruby
[1, 2].each(mostrar)
# => ArgumentError: wrong number of arguments (given 1, expected 0)
```

Regla para el `&`: **en una firma captura** (bloque → Proc); **en una llamada desparrama** (Proc → bloque). Igual que el `*` con los arrays, en el módulo 1.

> 🕳️ **Madriguera — `block_given?`**
> Adentro de un método, `block_given?` devuelve `true` si le pasaron un bloque. Sirve para hacer `yield` solo si hay bloque; un `yield` sin bloque lanza `LocalJumpError: no block given`.
> *Volvé al camino — esto se profundiza aparte, otro día.*

---

## 4. Proc vs lambda: dos diferencias, y nada más 🔴

Hay otra forma de crear el mismo tipo de objeto:

```ruby
mi_lambda = lambda { |x| p x }
p mi_lambda.class       # => Proc      ← también es un Proc
p mi_lambda.lambda?     # => true      ← pero marcado como lambda

mi_proc = proc { |x| p x }
p mi_proc.lambda?       # => false
```

Los dos son closures, los dos se ejecutan con `call`, los dos se pasan con `&`. Se diferencian en **exactamente dos cosas**.

### Diferencia 1: qué hacen con la cantidad de argumentos

```ruby
mi_proc = proc { |x| p x }
mi_proc.call(2)          # => 2
mi_proc.call             # => nil       ← faltó un argumento: x vale nil, no falla
mi_proc.call(2, 3, 4)    # => 2         ← sobraron: ignora los extras, no falla

mi_lambda = lambda { |x| p x }
mi_lambda.call(2)        # => 2
mi_lambda.call           # => ArgumentError: wrong number of arguments (given 0, expected 1)
mi_lambda.call(2, 3, 4)  # => ArgumentError: wrong number of arguments (given 3, expected 1)
```

El proc es permisivo: acomoda lo que le den. La lambda es estricta, como un método: la cantidad tiene que coincidir.

### Diferencia 2: a dónde va el `return`

Esta es la importante, y la que se usa a propósito en el módulo 6.

```ruby
def m_lambda
  l = lambda { |x| return x }    # return DENTRO de una lambda
  l.call(2)                      # ejecuta la lambda: el return sale de la LAMBDA, y nada más
  puts "sigo"                    # el método continúa
  44                             # y devuelve 44
end

p m_lambda
# Resultado esperado:
# sigo
# 44
```

```ruby
def m_proc
  pr = proc { |x| return x }     # return DENTRO de un proc
  pr.call(2)                     # ejecuta el proc: el return sale del MÉTODO que contiene al proc
  puts "sigo"                    # ← esta línea NUNCA se ejecuta
  44                             # ← esta tampoco
end

p m_proc
# Resultado esperado:
# 2                              ← m_proc devolvió 2, el valor del return del proc
```

¿Por qué? Porque el proc es un closure, y el `return` es **parte del contexto** que se llevó. El proc nació adentro de `m_proc`, así que su `return` es el `return` de `m_proc`. La lambda, en cambio, tiene su propio `return`: se comporta como un método anónimo.

Y esto vale aunque el proc lo ejecute otro objeto, en otro lugar:

```ruby
class Ejecutador
  def ejecutar(bloque)
    bloque.call                    # el ejecutador dispara el proc...
    puts "el ejecutador sigue"     # ← ...y esta línea tampoco se ejecuta
  end
end

def m_proc2
  pr = proc { return 5 }
  Ejecutador.new.ejecutar(pr)      # se lo doy a otro para que lo ejecute
  10
end

p m_proc2                          # => 5    ← el return del proc cortó todo hasta m_proc2, que es donde nació
```

El `return` del proc no sale "del método que lo ejecutó". Sale **del método donde el proc fue definido**, atravesando lo que haya en el medio.

⚠️ **Trampa:** si ese método ya terminó, no hay a dónde volver:

```ruby
def fabricar
  proc { return 1 }
end

pr = fabricar        # fabricar terminó; el proc quedó vivo
pr.call
# => LocalJumpError: unexpected return     ← el return apunta a un método que ya no está ejecutándose
```

> **Hilo abierto.** Que un `return` dentro de un proc corte el método de afuera parece un defecto. En el módulo 6 lo vas a usar a favor: un test que falla tiene que dejar de ejecutarse *en ese momento*, y un proc con `return` guardado en una variable de instancia hace exactamente eso.

### Resumen

| | `proc { }` | `lambda { }` |
|---|---|---|
| Clase | `Proc` | `Proc` (`lambda?` → `true`) |
| Closure (ve el contexto) | Sí | Sí |
| Argumentos de más o de menos | Los acomoda (nil / ignora) | `ArgumentError` |
| `return` | Sale del **método donde se definió** | Sale de la **lambda** |

> 🎓 **Para el parcial, si te preguntan:** *¿En qué se diferencian un proc y una lambda?*
> En dos cosas. La lambda valida la cantidad de argumentos como un método (`ArgumentError` si no coincide); el proc acomoda lo que reciba. Y el `return` de una lambda sale solo de la lambda, mientras que el `return` de un proc sale del método en el que el proc fue definido. En todo lo demás son iguales: los dos son `Proc`, closures, y se ejecutan con `call`.

🟢 Dos grafías que vas a ver por ahí y son lo mismo: `Proc.new { }` es igual a `proc { }`, y `->(x) { x * 2 }` (la "stabby lambda") es igual a `lambda { |x| x * 2 }`.

---

## 5. Flat scope: `define_method` y `Class.new` 🔴

Ahora sí, el problema del módulo 3, sección 8. Querías un método que use una variable de afuera:

```ruby
nombre = "atila"

def saludar
  puts "Hola " + nombre     # NameError: def cortó el contexto
end
```

`def` es una compuerta. Pero **un bloque no lo es**. Y `define_method`, que conocés de la clase 03, recibe el cuerpo del método **como bloque**:

```ruby
nombre = "atila"

define_method(:saludar) do    # define un método llamado saludar...
  puts "Hola " + nombre       # ...cuyo cuerpo es este bloque, que SÍ ve nombre
end

saludar                       # => Hola atila
```

(Suelto en un archivo, `define_method` funciona porque `main` es un objeto especial que lo entiende y define el método en `Object`. Un objeto común no entiende `define_method`; las clases y los módulos sí. Adentro de una clase, `define_method` define en esa clase, como en la clase 03.)

Mismo método, misma llamada, sin compuerta. Por eso `define_method` recibe un bloque y no otra cosa: el bloque es el único envoltorio de código que **no corta el contexto**.

Lo mismo con las clases. `class` es una compuerta; `Class.new` recibe el cuerpo de la clase como bloque:

```ruby
nombre = "atila"

Presentacion = Class.new do        # crea una clase nueva; el bloque es su cuerpo
  puts "Hola " + nombre            # => Hola atila    ← el cuerpo ve la variable de afuera
  def hola                         # adentro se puede usar def normal: define métodos de instancia como siempre
    "hola desde el método"
  end
end

p Presentacion.new.hola            # => "hola desde el método"
p Presentacion.class               # => Class          ← es una clase como cualquiera
```

Y las dos combinadas, que es lo que se ve en los repos de la cátedra:

```ruby
x = 10

C2 = Class.new do
  define_method(:m2) do       # método de instancia cuyo cuerpo ve x
    "desde m2 #{x}"
  end
end

p C2.new.m2                   # => "desde m2 10"
x = 99
p C2.new.m2                   # => "desde m2 99"    ← referencia viva: el método ve el valor actual de x
```

A esta técnica se la llama **flat scope** (contexto aplanado): reemplazar la compuerta (`def`, `class`) por su equivalente con bloque (`define_method`, `Class.new`) para que el código de adentro comparta el contexto de afuera.

| Con compuerta | Sin compuerta (flat scope) |
|---|---|
| `def nombre … end` | `define_method(:nombre) do … end` |
| `class Nombre … end` | `Nombre = Class.new do … end` |

> 🎓 **Para el parcial, si te preguntan:** *¿Cómo hacés que un método vea una variable local definida afuera?*
> Definiéndolo con `define_method` en vez de `def`. `def` es un scope gate: crea un contexto nuevo y vacío. `define_method` recibe el cuerpo como bloque, y un bloque es un closure que conserva el contexto donde fue escrito. La técnica se llama flat scope.

### Una trampa que junta módulo 3 con este

`define_method` también acepta un proc ya existente, con `&`:

```ruby
class A
  attr_accessor :nombre           # A tiene un MÉTODO llamado nombre
end

nombre = "atila"                  # y afuera hay una VARIABLE llamada nombre
saludo = proc { "hola #{nombre}" }

A.define_method(:saludar2, &saludo)    # el proc pasa a ser el cuerpo del método saludar2 de A

a = A.new
a.nombre = "pepe"
p a.saludar2                      # => "hola atila"    ← ⚠️ no dice "pepe"
```

El bloque encontró primero la **variable local** `nombre` (que se llevó del contexto donde nació) y nunca miró el método `nombre` del objeto. Es la regla del módulo 3, sección 6, aplicada a un closure. Si querés el método, receptor explícito:

```ruby
saludo_bien = proc { "hola #{self.nombre}" }    # self.nombre: con receptor, Ruby no busca variables
A.define_method(:saludar3, &saludo_bien)
p a.saludar3                      # => "hola pepe"     ← ahora sí
```

Y fijate qué acaba de pasar: dentro de ese proc, `self` es `a`. **No es `main`**, que era el `self` del lugar donde el proc nació. `define_method` cambió el `self` del bloque para que el método funcione como método. Las variables viajaron con el closure; `self` fue reemplazado. Esa asimetría es todo el módulo 5.

---

## 6. Los tres nombres, dichos completos 🟡

| | Bloque `{ }` / `do…end` | `proc { }` | `lambda { }` |
|---|---|---|---|
| ¿Es un objeto? | No: es sintaxis del envío de mensaje | Sí, `Proc` | Sí, `Proc` con `lambda?` |
| ¿Cómo se ejecuta? | `yield` dentro del método, o se captura con `&` | `call` | `call` |
| ¿Es closure? | Sí | Sí | Sí |
| Argumentos | Permisivo | Permisivo | Estricto |
| `return` | Sale del método donde se definió | Sale del método donde se definió | Sale de la lambda |

Un bloque **se convierte en** proc al capturarlo con `&bloque` en la firma. Un proc **se convierte en** bloque al pasarlo con `&proc` en la llamada. Son dos caras de lo mismo; la diferencia es si en ese momento lo tenés como objeto o no.

---

## Checkpoint del Módulo 4

Sin respuestas.

1. ¿Qué significa "reificar" un envío de mensaje? ¿Qué es un `Proc` en esos términos?
2. `pr = proc { puts "x" }`: ¿qué se imprime al ejecutar esa línea? ¿Y qué falta para que se imprima "x"?
3. ¿Qué puede hacer un proc con las variables locales del contexto donde nació, y qué no puede? Dá un ejemplo de cada caso.
4. Explicá con el contador por qué se dice que un proc "cierra" sobre su contexto. ¿Por qué `c1` y `c2` no comparten el `n`?
5. `def m(bloque); end; m { 1 }` da `ArgumentError`. ¿Por qué el bloque no cuenta como argumento, y cuáles son las dos formas correctas de recibirlo?
6. ¿Qué te permite hacer `&bloque` que `yield` no?
7. El `&` significa cosas distintas en `def m(&b)` y en `m(&un_proc)`. ¿Cuáles? ¿Con qué operador del módulo 1 tiene la misma dualidad?
8. Dos diferencias entre proc y lambda. Para cada una, un ejemplo de código donde se note.
9. `def m; pr = proc { return 1 }; otro.ejecutar(pr); 2; end`: ¿qué devuelve `m` si `ejecutar` hace `pr.call`? ¿Por qué?
10. ¿Qué es flat scope? Reescribí `def saludar; puts "hola " + nombre; end` para que funcione con un `nombre` definido afuera.
11. En la trampa de `define_method` con `&saludo`, ¿por qué apareció `"atila"` y no `"pepe"`? ¿Qué cambió con `self.nombre`?

---

## Qué viene en el Módulo 5

La última pieza del contexto: `self`. Un proc se lleva las variables de donde nació, y también se lleva su `self`: un proc creado adentro de un método de `atila` sigue "hablándole" a `atila` aunque lo ejecute otro objeto. Vas a ver eso, y después la herramienta que lo cambia: `instance_eval`, que ejecuta un bloque **con otro `self`**. De ahí salen `instance_exec`, `class_eval`, y la pregunta que cierra la clase: si escribís un `def` adentro de un bloque, ¿en qué clase queda definido ese método?

**FIN DEL MÓDULO 4**
