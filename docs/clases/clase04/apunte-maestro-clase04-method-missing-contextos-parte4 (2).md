# Apunte maestro — clase04 — `method_missing`, bloques, contextos e `instance_eval`
## Parte 4 — Contextos, scope gates, flat scope e `instance_eval`

> **Qué cubre esta parte.** Qué ve una línea de código según dónde esté escrita. Cómo decide Ruby si una palabra suelta es una variable o un mensaje. Qué ve un proc del contexto de afuera, qué modifica y qué agrega. Las tres construcciones que **cortan** el contexto (`def`, `class`, `module`), sus reemplazos que no lo cortan (`define_method`, `Class.new`), y la herramienta que cierra la clase: `instance_eval`, que ejecuta un bloque **eligiendo quién es `self`**. Al final, qué pasa con un `def` escrito adentro de un bloque: `instance_eval` vs `class_eval`.
>
> **De dónde venís.** De la Parte 3: `self` implícito y `main`; un proc se ejecuta con `call`; un proc conserva el `self` y el `return` del lugar donde nació; el contador. De la clase 3: `self` en el cuerpo de una clase es la clase; `def self.x` define en la autoclase; `define_method` recibe el cuerpo como bloque.
>
> **Cómo está escrita.** Cada sección abre con la **regla**, en afirmativo. Después viene el caso que la muestra, con el resultado al lado de cada línea. Todo el código se ejecutó antes de escribirse. Donde un mecanismo tiene varias formas, van en una tabla: *escribís / Ruby entiende / sale*.
>
> **Código.** Ruby 3.x, `age.rb` de la materia donde se indica. `puts x` imprime el texto; `p x` muestra el valor tal cual (los strings, con comillas). En versiones recientes de Ruby los errores dicen `for main` en vez de `for main:Object`: es el mismo error.

---

## 1. Una palabra suelta: ¿variable o mensaje? 🔴

> **Regla.** Una palabra suelta (`atila`, `nombre`, `energia`) puede ser dos cosas: una variable local o un mensaje a `self`. Ruby decide por **la forma en que está escrita** y por **lo que hay en el contexto**:
>
> | Escribís | Ruby entiende |
> |---|---|
> | `x` suelto, y hay una variable `x` en el contexto | la variable |
> | `x` suelto, y no hay variable | el mensaje `self.x` (lookup normal) |
> | `x = …` | **siempre** una variable local: la pisa si existe, la crea si no |
> | `x(…)` o `x.algo` | **siempre** un mensaje: con paréntesis o punto, ya no puede ser variable |
>
> **Contexto** es el conjunto de nombres que una línea puede usar desde el lugar donde está escrita.

El caso mínimo:

```ruby
nombre = "pepita"                  # x = …  →  variable local del archivo, creada acá

saludar = proc do
  saludo = "Hola"                  # x = …  →  variable local, creada adentro del proc
  puts saludo + " " + nombre       # dos palabras sueltas: las dos son variables → las usa
end

saludar.call                       # => Hola pepita
```

Ahora una palabra que **no** está en el contexto:

```ruby
puts atila
# => NameError: undefined local variable or method `atila' for main:Object
```

El mensaje de error nombra las dos cosas que Ruby probó, en orden: primero buscó la variable `atila`; no estaba. Entonces mandó `self.atila`, con `self` = `main`; no hubo método. Recién ahí, el error.

Si existe el método, la segunda opción funciona:

```ruby
def atila                          # ahora main tiene un método atila
  3
end
puts atila                         # => 3     ← no hay variable, sí hay método: mensaje a self
```

Y con paréntesis, Ruby ni busca la variable. Por eso este error dice solo *"method"*:

```ruby
mostrar = proc { |n| puts n }
mostrar(5)
# => NoMethodError: undefined method `mostrar' for main:Object
#    ← mostrar(5) es un mensaje, sí o sí. La variable mostrar existe, pero acá no cuenta.
#      Para ejecutar el proc: mostrar.call(5)   (Parte 3)
```

⚠️ **Trampa: el setter desde adentro de la clase.** `energia = energia - 10` escrito adentro de `Guerrero` **no** llama al setter `energia=`: la fila `x = …` dice que es siempre una variable local. Se crea una variable nueva llamada `energia`, que vale `nil`, y la línea explota con `undefined method '-' for nil`. Para llamar al setter hay que escribir el receptor: `self.energia = energia - danio`, como hace `age.rb`. El de la izquierda necesita el `self.`; el de la derecha es un mensaje sin receptor y se resuelve como siempre.

Esta regla es una sola y no cambia nunca. Lo que cambia es el contexto: **la misma línea es una variable en un contexto y un mensaje a `self` en otro.** Toda la clase de hoy es aprovechar eso a propósito: primero con las variables (secciones 2 a 5) y después con `self` (sección 6).

---

## 2. El contexto de un proc es hijo del de afuera 🔴

> **Regla.** Un proc abre un contexto **hijo** del contexto donde fue escrito.
> - **Ve** todas las variables de afuera, y **modifica** las de afuera cuando las asigna: son las mismas variables, no copias.
> - Lo que **crea** adentro (una variable nueva) **queda adentro**: afuera no existe.
> - Un `if` **no** abre contexto: lo que se crea adentro de un `if` queda en el contexto que lo rodea.

```
   contexto del archivo (main)
   ┌───────────────────────────────┐
   │ nombre, saludar, mutar        │◄── el proc VE esto, y lo MODIFICA
   │   ┌───────────────────────┐   │
   │   │ contexto del proc     │   │
   │   │ saludo                │   │──► lo que crea acá, se queda acá
   │   └───────────────────────┘   │
   └───────────────────────────────┘
```

Los tres puntos de la regla, en código:

```ruby
nombre = "pepita"

saludar = proc do
  saludo = "Hola"                  # variable nueva → se crea en el contexto del proc
  puts saludo + " " + nombre       # nombre es de afuera → la ve
end
saludar.call                       # => Hola pepita

p saludo
# => NameError: undefined local variable or method `saludo' for main:Object
#    ← saludo nació adentro del proc; afuera no existe

mutar = proc { nombre += " cosas" }   # nombre += … es nombre = nombre + …: asigna la variable de AFUERA
mutar.call
p nombre                           # => "pepita cosas"   ← la de afuera cambió
```

El `if`, para comparar:

```ruby
if true
  saludo2 = "lalala"               # se crea "adentro" del if…
end
p saludo2                          # => "lalala"     ← …y está afuera: el if no abrió contexto
```

**Cuándo pisa y cuándo crea.** Es el algoritmo de la sección 1, aplicado hacia arriba. Cuando el proc asigna `saludo = …`, Ruby busca la variable primero en el contexto del proc y después en el que lo contiene. Si la encuentra, la asigna (la pisa). Si no la encuentra, la crea en el contexto del proc, que es el suyo.

| Antes de crear el proc | Adentro del proc: `saludo = "Hola"` | Después de `call`, afuera: `p saludo` |
|---|---|---|
| `saludo` **no existe** afuera | la crea en el contexto del proc | `NameError` |
| `saludo = "..."` **existe** afuera | pisa la de afuera | `"Hola"` |

**Ver el contexto con `binding`.** `binding` es un mensaje que devuelve un objeto que representa el contexto actual (sus variables locales y su `self`). `binding.local_variables` lista los nombres de variables que esa línea puede usar. Con eso la regla se ve directamente:

```ruby
nombre = "pepita"
saludar = proc do
  saludo = "Hola"
  puts "Dentro del proc:", binding.local_variables.inspect   # .inspect: el array como texto, para imprimirlo
  puts saludo + " " + nombre
end
saludar.call
puts "Fuera del proc:", binding.local_variables.inspect
# Resultado esperado:
# Dentro del proc:
# [:saludo, :nombre, :saludar]      ← lo suyo (saludo) MÁS todo lo de afuera (nombre, saludar)
# Hola pepita
# Fuera del proc:
# [:nombre, :saludar]               ← afuera, solo lo de afuera: saludo no está
```

---

## 3. La variable que llegó tarde 🔴

> **Regla.** La decisión "¿esta palabra es variable o mensaje?" Ruby la toma **al leer el código**, de arriba hacia abajo, no al ejecutarlo. Una palabra que no era variable cuando Ruby leyó la línea del proc queda decidida como **mensaje a `self`**, aunque la variable aparezca más abajo en el archivo.

El caso: el proc usa `otra_cosa`, y `otra_cosa` se asigna **después** de escribir el proc.

```ruby
nombre = "pepita"
saludar = proc do
  puts "Dentro del proc:", binding.local_variables.inspect
  puts "Hola " + nombre + otra_cosa.to_s      # otra_cosa: cuando Ruby leyó esta línea, no era variable
end
otra_cosa = 42                                # ahora sí es variable
saludar.call
# Resultado esperado:
# Dentro del proc:
# [:nombre, :saludar, :otra_cosa]             ← binding la muestra: en tiempo de ejecución, existe
# NameError: undefined local variable or method `otra_cosa' for main:Object
#                                             ← y la línea siguiente falla igual
```

Las dos salidas son ciertas al mismo tiempo, y cada una mira otro momento:

| Qué | Cuándo decide | Qué ve |
|---|---|---|
| `binding.local_variables` | al **ejecutar** | `otra_cosa` ya existe en el contexto compartido → la lista |
| la palabra `otra_cosa` en la línea del proc | al **leer** el archivo | todavía no había ninguna asignación → quedó como `self.otra_cosa` |

Al ejecutar, esa línea manda `self.otra_cosa`, `main` no lo entiende, `NameError`. El proc se queda con las variables que existían **cuando fue escrito**. El lookup de variables no es dinámico como el de métodos.

---

## 4. `def` corta el contexto (y `class`, y `module`) 🔴

> **Regla.** Hay exactamente **tres** construcciones que abren un contexto nuevo **cortado** del anterior: **`class`, `module` y `def`**. Se llaman **scope gates** (compuertas de contexto). Adentro de una compuerta, las variables de afuera **no existen**: cualquier palabra suelta se resuelve como mensaje a `self`.
> Los bloques (`do … end`, `{ }`) abren un contexto **hijo**, que ve todo. `if`, `while` y `begin` no abren contexto.

```
   contexto exterior:  nombre = "pepita"
   ┌──────────────────────────────────────────────────────────────────────┐
   │                                                                      │
   │   class B          module M          def saludar2       proc do      │
   │   ┌──────────┐     ┌──────────┐      ┌──────────┐       ┌──────────┐ │
   │   │ NUEVO    │     │ NUEVO    │      │ NUEVO    │       │ HIJO     │ │
   │   │ (vacío)  │     │ (vacío)  │      │ (vacío)  │       │ (ve todo)│ │
   │   │ self = B │     │ self = M │      │ self = ? │       │ self = el│ │
   │   └──────────┘     └──────────┘      └──────────┘       │ de afuera│ │
   │      gate             gate              gate            └──────────┘ │
   └──────────────────────────────────────────────────────────────────────┘
```

El mismo código, con proc y con `def`:

```ruby
nombre = "pepita"

saludar = proc { puts "Hola " + nombre }
saludar.call                       # => Hola pepita     ← el proc es hijo: ve nombre

def saludar2                       # la misma lógica, pero con def
  puts "Hola " + nombre            # nombre no es variable acá → se resuelve como self.nombre
end
saludar2
# => NameError: undefined local variable or method `nombre' for main:Object
```

Y con `class`:

```ruby
nombre = "pepita"
class B
  puts nombre
end
# => NameError: undefined local variable or method `nombre' for B:Class     ← acá self es B, no main
```

**Por qué `def` corta y el proc no.** La diferencia está en `self`. Adentro de un método, `self` es el objeto que **reciba** el mensaje:

```ruby
class A
  def saludar
    self                           # la instancia que reciba saludar
  end
end
```

En el momento en que escribís el `def`, ese objeto **no existe todavía**. Ni siquiera es uno: son todas las instancias que en algún momento reciban `saludar`. El método no tiene contexto hasta que lo llaman, y cuando lo llaman, su contexto se arma a partir del receptor. Como al definirlo no hay objeto, no hay nada a lo que colgarle el contexto de afuera. El proc es lo contrario: cuando lo creás, el contexto **está ahí**, vivo, ejecutando esa línea, y el proc nace como hijo de ese contexto. Se comprueba: el `self` del proc es exactamente el mismo objeto que el de afuera.

```ruby
este = self                        # afuera: self es main
saludar = proc do
  p self.equal?(este)              # equal?: ¿son el MISMO objeto? (no "iguales": el mismo)
end
saludar.call                       # => true
```

**Quién es `self` en cada compuerta.** Es siempre el que recibe el mensaje: en un método de instancia, la instancia; en un método de clase, la clase; en el cuerpo de la clase, la clase (a ella le mandás `attr_accessor`).

```ruby
class A
  puts self                        # => A          ← cuerpo de la clase: self es la clase
  def saludar
    self                           # la instancia que reciba saludar
  end
  def self.algo
    self                           # la clase A: método de clase, lo recibe la clase
  end
end
p A.new.saludar.class              # => A
p A.algo                           # => A
```

| Dónde está escrita la línea | `self` es |
|---|---|
| archivo suelto | `main` |
| cuerpo de `class A … end` | `A` |
| adentro de `def saludar` (método de instancia) | la instancia que recibió `saludar` |
| adentro de `def self.algo` (método de clase) | `A` |
| adentro de un bloque | el `self` del lugar donde el bloque fue escrito |

Fijate que el `self` suelto del cuerpo de `A` y el `self` de adentro de `saludar` **no son el mismo**, aunque uno esté escrito "adentro" del otro. Los contextos de las compuertas no se jerarquizan por contención: entre el cuerpo de la clase y el método hay un corte. Es otra jerarquía, distinta de la de las llaves.

De acá sale una equivalencia que vas a usar todo el tiempo: **`self` y "el contexto" son casi lo mismo.** Toda palabra que no sea variable se le pide a `self`. Preguntar "¿en qué contexto estoy?" es casi preguntar "¿quién es `self` acá?".

**El problema que esto crea.** Las tres herramientas de Ruby para **empaquetar** código (`def`, `class`, `module`) son las tres que **cortan** el contexto. Empaquetás y perdés las variables. Si querés un método que use `nombre`, con `def` no podés. La sección que sigue es la solución.

---

## 5. Flat scope: `define_method` y `Class.new` 🔴

> **Regla.** Cada compuerta tiene un **reemplazo con bloque** que hace lo mismo sin cortar el contexto. Como el cuerpo viaja en un bloque, y un bloque es hijo del contexto de afuera, el código de adentro **ve las variables de afuera**. Ruby solo le cambia el `self` al bloque para que funcione como método o como cuerpo de clase. La técnica se llama **flat scope** (contexto aplanado).
>
> | Con compuerta (corta) | Sin compuerta (flat scope) |
> |---|---|
> | `def nombre … end` | `define_method(:nombre) do … end` |
> | `class Nombre … end` | `Nombre = Class.new do … end` |

**`define_method`.** Ya lo conocés de la clase 3: recibe el nombre y el cuerpo como bloque.

```ruby
nombre = "pepita"

A.define_method(:saludar2) do      # define en A un método saludar2 cuyo cuerpo es este bloque
  puts "Soy #{self}"
  puts "Hola " + nombre            # ← nombre, la variable de afuera
end

A.new.saludar2
# Resultado esperado:
# Soy #<A:0x…>                     ← self es LA INSTANCIA de A, como en cualquier método
# Hola pepita                      ← y sin embargo vio la variable de afuera
```

Las dos cosas pasan a la vez: `nombre` lo tomó del contexto de afuera, como cualquier bloque; y `self` **no** es `main` (el `self` de afuera) sino la instancia. Tiene que ser así: un método tiene que poder resolver mensajes sobre el objeto que lo recibe. Ruby **conserva las variables del bloque y le reemplaza el `self`**.

El mismo código, ejecutado de las dos formas:

```ruby
saludar2_proc = proc do            # el MISMO código, guardado como proc
  puts "Soy #{self}"
  puts "Hola " + nombre
end

A.define_method(:saludar3, &saludar2_proc)   # el proc pasa a ser el cuerpo de saludar3 (& en la llamada: Parte 3)
```

| Escribís | Ruby entiende | Sale |
|---|---|---|
| `saludar2_proc.call` | ejecutar el proc con el `self` de donde nació | `Soy main` / `Hola pepita` |
| `A.new.saludar3` | ejecutar el mismo código como método de la instancia | `Soy #<A:0x…>` / `Hola pepita` |

Literalmente el mismo código, con dos `self` distintos según **cómo** se lo invoque, y en los dos casos con la variable de afuera. Usar `define_method` en vez de `def` te da, además de lo que ya sabías (parametrizar el nombre y la lógica), **las variables que están en contexto**.

**`Class.new`.** Recibe un bloque que se evalúa como el cuerpo de la clase:

```ruby
nombre = "pepita"

B = Class.new do                   # crea una clase nueva; el bloque es su cuerpo
  nombre = "Axel"                  # ¿hay variable nombre? sí, la de afuera → la pisa (sección 2)
  puts nombre                      # => Axel
  puts self                        # => #<Class:0x…>    ← self es la clase nueva (todavía sin nombre)
  def m1                           # adentro se puede usar def normal: define un método de instancia
  end
end

puts nombre                        # => Axel            ← la de afuera cambió: misma mecánica que el proc
p B.class                          # => Class           ← es una clase como cualquiera; al asignarla a B recibe ese nombre
```

Adentro del bloque escribís lo mismo que en `class B … end`, con una diferencia: **conoce el contexto de afuera**, ve sus variables y las modifica. Y `self` es la clase, igual que en `class B`: de nuevo, Ruby le cambió el `self` al bloque.

> 🎓 **Para el parcial, si te preguntan:** *¿Cómo hacés que un método use una variable local definida afuera?*
> Definiéndolo con `define_method` en vez de `def`. `def` es un scope gate: crea un contexto nuevo cortado del anterior, porque en el momento de definir el método no existe el objeto que le daría contexto. `define_method` recibe el cuerpo como bloque, y un bloque conserva las variables del contexto donde fue escrito; Ruby solo le cambia el `self` para que sea la instancia. La técnica se llama flat scope.

En `define_method` y en `Class.new`, Ruby cambia el `self` del bloque **por su cuenta**. Lo que sigue es la herramienta para hacerlo **vos**.

---

## 6. `instance_eval`: elegir el `self` de un bloque 🔴

> **Regla.** `objeto.instance_eval` ejecuta un bloque con **`self` = `objeto`**. Las variables locales del lugar donde se escribió el bloque **siguen visibles**; lo único que cambia es `self`. Consecuencias: los mensajes sin receptor le llegan a `objeto`, y las variables de instancia que se ven son las de `objeto`.
> Un proc se le pasa con `&` (Parte 3); un bloque, directo.

```
   contexto donde nació el proc          contexto en que instance_eval lo ejecuta
   ┌──────────────────────────┐          ┌──────────────────────────┐
   │ variables: nombre, …     │ ───────► │ variables: nombre, …     │  ← iguales: siguen viajando
   │ self: main               │    ✗     │ self: atila              │  ← REEMPLAZADO por el receptor
   └──────────────────────────┘          └──────────────────────────┘
```

Es la misma jugada que `define_method` y `Class.new` hacían solos, ahora bajo tu control.

**Lo que no cambia el `self`, para tenerlo claro:** que otro objeto haga el `call`. Un proc se lleva el `self` de donde nació (Parte 3), lo dispare quien lo dispare:

```ruby
require_relative 'age'

class Guerrero
  def ejecutar_proc(un_proc)
    un_proc.call                   # atila hace el call…
  end
end

atila = Guerrero.new
atila.ejecutar_proc(saludar2_proc) # => Soy main        ← …y self sigue siendo main
                                   #    Hola Axel         (nombre vale "Axel" desde el Class.new de la sección 5)
```

**Lo que sí lo cambia:**

```ruby
atila.instance_eval(&saludar2_proc)
# => Soy #<Guerrero:0x…>           ← self es atila: el receptor de instance_eval
#    Hola Axel                     ← y la variable de afuera se sigue viendo
```

El mismo proc, con los tres `self`:

| Escribís | `self` adentro | Sale |
|---|---|---|
| `saludar2_proc.call` | `main` (donde nació) | `Soy main` |
| `atila.ejecutar_proc(saludar2_proc)` | `main` (el `call` no lo cambia) | `Soy main` |
| `atila.instance_eval(&saludar2_proc)` | `atila` | `Soy #<Guerrero:0x…>` |

**Para qué sirve.** Un bloque escrito una sola vez, sin parámetros, que hace cosas distintas según quién sea `self`:

```ruby
devolver_energia = proc { energia }   # energia, suelto: no hay variable → self.energia (sección 1)

devolver_energia.call
# => NameError: undefined local variable or method `energia' for main:Object   ← main no entiende energia

p atila.instance_eval(&devolver_energia)          # => 100    ← con self = atila, energia es atila.energia

class Golondrina
  def energia
    "sí"                           # una golondrina también entiende energia
  end
end
p Golondrina.new.instance_eval(&devolver_energia) # => "sí"   ← el MISMO bloque, con self = una golondrina
```

Un bloque, tres ejecuciones: con `main`, falla; con un guerrero, su energía; con una golondrina, otra cosa. Cambiar el `self` es cambiar **a quién le llegan los mensajes sin receptor**.

**Con el bloque directo, y las variables de instancia:**

```ruby
x = 2
atila.instance_eval do             # el bloque escrito ahí mismo, sin proc previo
  puts x                           # => 2           ← la variable local de afuera sigue visible
  puts self.class                  # => Guerrero    ← self ya no es main
  p @energia                       # => 100         ← las variables de instancia son las de atila: estás "adentro" de él
end
```

Ese último punto: adentro de un `instance_eval` ves las variables de instancia del receptor, como si fueras un método de su clase. Es una forma de romper el encapsulamiento a propósito. Mucha potencia, y hay que saber que la estás usando.

> 🎓 **Para el parcial, si te preguntan:** *¿Qué hace `instance_eval`?*
> Ejecuta un bloque cambiándole el `self`: dentro del bloque, `self` pasa a ser el receptor de `instance_eval`, así que los mensajes sin receptor van a ese objeto y sus variables de instancia quedan accesibles. Las variables locales del lugar donde se escribió el bloque siguen visibles. Sirve para escribir un bloque una vez y aplicarlo a distintos objetos sin pasarlos por parámetro, que es la base para construir sintaxis propias (Parte 5).

Esto es **core**: es lo que vas a necesitar para resolver el TP. Y es de las ideas más cortas de la materia: un bloque se lleva su contexto; `instance_eval` le cambia el `self`. Lo que falta no es más teoría: es sentarse a usarla.

---

## 7. Un `def` adentro del bloque: `instance_eval` vs `class_eval` 🟡

*Esta sección completa la unidad según la planificación de la cátedra para esta fecha.*

> **Regla.** Un `def` escrito adentro de un bloque se define en un lugar que depende de **con qué** se ejecutó el bloque:
>
> | Al ejecutar el bloque con… | `self` es… | un `def` adentro se define en… | Quién lo entiende |
> |---|---|---|---|
> | `objeto.instance_eval` | `objeto` | la **autoclase** de `objeto` | solo `objeto` |
> | `Clase.instance_eval` | `Clase` | la autoclase de `Clase` (`#Clase`) | `Clase` (método de clase) |
> | `Clase.class_eval` | `Clase` | **`Clase`** misma | todas las instancias de `Clase` |
> | `Modulo.module_eval` | `Modulo` | `Modulo` | quien incluya el módulo |
>
> Para no perderse: `instance_eval` → autoclase del receptor. `class_eval` → el receptor mismo, que tiene que ser una clase o un módulo (para un módulo se llama `module_eval`, y es el mismo método).

**Con `instance_eval`, el `def` va a la autoclase del receptor:**

```ruby
atila = Guerrero.new
otro  = Guerrero.new

atila.instance_eval do
  def gritar                       # un def, adentro de un bloque que se ejecuta con self = atila
    "haaaa"
  end
end

p atila.gritar                                     # => "haaaa"      ← atila lo entiende
otro.gritar
# => NoMethodError: undefined method `gritar' for #<Guerrero:0x…>       ← otro guerrero, no
p atila.singleton_class.instance_methods(false)    # => [:gritar]    ← quedó en #atila, la autoclase (singleton_class: clase 3)
```

Es lo mismo que `atila.define_singleton_method(:gritar) { "haaaa" }` (clase 3), con un `def` escrito adentro de un bloque. Tiene sentido: si `self` es un objeto que no es una clase, el único lugar donde "definir un método para este objeto" significa algo es su autoclase.

**Con `class_eval`, el `def` va a la clase misma:**

```ruby
Guerrero.class_eval do
  def huir                         # def adentro de un class_eval
    self.energia = energia / 2     # self. a la izquierda para llamar al setter (sección 1)
  end
end

p atila.huir                                        # => 50      ← todas las instancias lo entienden
p otro.huir                                         # => 50
p Guerrero.instance_methods(false).include?(:huir)  # => true    ← quedó en Guerrero, como método de instancia
```

`class_eval` es reabrir la clase con `class Guerrero … end`, pero **sin cortar el contexto** (flat scope, sección 5). El `def` de adentro sigue siendo compuerta: si querés que el *cuerpo del método* use una variable de afuera, adentro del `class_eval` va `define_method`:

```ruby
factor = 3
Guerrero.class_eval do
  define_method(:huir_con_factor) { self.energia = energia / factor }   # ve factor: es un bloque
end
p otro.huir_con_factor                              # => 16      (50 / 3, división entera)
```

**El caso que sorprende: sobre una clase, los dos tienen el mismo `self`.**

```ruby
Guerrero.instance_eval { p self }                   # => Guerrero
Guerrero.class_eval    { p self }                   # => Guerrero
```

Lo que cambia es **a dónde va el `def`**. Con `instance_eval` sobre una clase, va a la autoclase de la clase: queda como **método de clase**.

```ruby
Guerrero.instance_eval do
  def contar                       # def con self = Guerrero, vía instance_eval → autoclase de Guerrero
    "soy método de clase"
  end
end
p Guerrero.contar                                   # => "soy método de clase"   ← lo entiende la clase
atila.contar
# => NoMethodError: undefined method `contar' for #<Guerrero:0x…>       ← las instancias, no
```

**Con parámetros: `instance_exec`.** `instance_eval` no acepta argumentos para el bloque. Si necesitás cambiar el `self` **y** parametrizar, es `instance_exec`:

```ruby
atila.instance_exec(15) { |danio| self.energia -= danio }   # self = atila, y además el bloque recibe 15
p atila.energia                                              # => 35      (50 − 15)

atila.instance_eval(15) { |danio| }
# => ArgumentError: wrong number of arguments (given 1, expected 0)   ← instance_eval no recibe argumentos
```

Regla: `instance_eval` cuando el bloque no lleva parámetros; `instance_exec` cuando sí. En todo lo demás son idénticos.

> 🎓 **Para el parcial, si te preguntan:** *¿Qué diferencia hay entre `instance_eval` y `class_eval`?*
> Los dos ejecutan un bloque con `self` = el receptor. La diferencia está en dónde quedan los métodos escritos con `def` adentro del bloque: `instance_eval` los define en la autoclase del receptor (solo ese objeto los entiende; si el receptor es una clase, quedan como métodos de clase); `class_eval` los define en la clase receptora, para todas sus instancias. `class_eval` solo lo entienden clases y módulos.

---

## Checkpoint de la Parte 4

Sin respuestas.

1. Este código falla: `x = 1; def m; x; end; m`. Escribí el mensaje de error completo y explicá qué significa cada mitad del "variable local o método".
2. En `def m; saraza = 15; saraza; end`, con un método `saraza` que devuelve 10, ¿qué devuelve `m` y por qué? ¿Cómo alcanzarías al método igual?
3. `mostrar` es una variable que guarda un proc. `mostrar(5)` da `NoMethodError`, y el error dice solo *"undefined method"*, no *"local variable or method"*. Explicá las dos cosas.
4. ¿Qué diferencia hay entre el contexto que abre un `if`, el que abre un proc y el que abre un `def`? Dá un ejemplo de código para cada uno donde se note.
5. Un proc asigna `saludo = "Hola"`. ¿En qué caso pisa una variable de afuera y en qué caso crea una propia? ¿Qué algoritmo decide eso?
6. Creás un proc que usa `otra_cosa`, y después definís `otra_cosa = 42`. Al ejecutar el proc, `binding.local_variables` la muestra y aun así falla. Explicá las dos cosas.
7. ¿Por qué `def` no puede tener como contexto padre el contexto que lo rodea, si el proc sí puede? ¿Qué tiene que ver `self` con eso?
8. Nombrá las tres scope gates. ¿Por qué es un problema que sean exactamente las tres construcciones que empaquetan código?
9. Tenés `saludar2_proc = proc { puts self }`. Mostrá tres formas de ejecutarlo donde `self` sea `main`, una instancia de `A`, y `atila`, respectivamente.
10. `atila.ejecutar_proc(un_proc)` no cambia el `self` del proc. ¿Por qué? ¿Qué sí lo cambia?
11. Querés que **todos** los guerreros entiendan `huir`, y querés que el cuerpo del método use una variable local `factor` definida afuera. ¿Con qué combinación de herramientas lo hacés, y por qué no sirve `class Guerrero; def huir …`?
12. Aparece este requerimiento: "quiero un bloque que compruebe si un guerrero está herido, escrito una vez, y aplicarlo a varios guerreros sin pasárselos por parámetro". ¿Qué herramienta usás y cómo queda el código?

---

## Qué viene en la Parte 5

Todo lo anterior, junto, construyendo algo: una sintaxis de test que parece otro lenguaje (`test_suite do test "…" do assert(…) end end`) y que se explica entera con "cada palabra suelta es un mensaje a `self`" más `instance_eval` en cada nivel. Después, por qué se construyen estos lenguajes específicos (DSLs), un ejemplo de consulta a base de datos que se lee como SQL, las tres cosas que hay que llevarse de esta clase, y toda la información operativa: qué viene la clase que viene, el TP1, GitHub y Discord.

**FIN DE LA PARTE 4**
