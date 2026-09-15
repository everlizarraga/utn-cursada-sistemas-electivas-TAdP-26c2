# Apunte maestro — clase04 — `method_missing`, bloques, contextos e `instance_eval`
## Parte 4 — Contextos, scope gates, flat scope e `instance_eval`

> **Qué cubre esta parte.** Qué ve una línea de código según dónde esté escrita. Cómo decide Ruby si una palabra suelta es una variable o un mensaje. Qué ve un proc del contexto de afuera, qué modifica, qué agrega, y por qué una variable creada después del proc no existe para él. Las tres construcciones que **cortan** el contexto (`def`, `class`, `module`) y por qué, sus reemplazos que no lo cortan (`define_method`, `Class.new`), y la herramienta que cierra la clase: `instance_eval`, que ejecuta un bloque **eligiendo quién es `self`**. Al final, qué pasa con un `def` escrito adentro de un bloque: `instance_eval` vs `class_eval`.
>
> **De dónde venís.** De la Parte 3: `self` implícito y `main`; un proc se ejecuta con `call`; un proc conserva el `self` y el `return` del lugar donde nació; el contador. De la clase 3: `self` en el cuerpo de una clase es la clase; `def self.x` define en la autoclase; `define_method` recibe el cuerpo como bloque.
>
> **Código.** Ruby 3.3, `age.rb` de la materia donde se indica. Resultados como comentario al lado de cada línea.

---

## 1. Una palabra suelta: ¿variable o mensaje? 🔴

Un proc puede usar una variable definida afuera, y puede tener las suyas:

```ruby
nombre = "pepita"                  # variable local del archivo

saludar = proc do
  saludo = "Hola"                  # variable local propia del proc
  puts saludo + " " + nombre       # usa la suya y la de afuera
end

saludar.call                       # => Hola pepita     ← el proc ve nombre, que se definió afuera
```

En este punto del archivo, el **contexto** (el conjunto de nombres que una línea puede usar) tiene dos variables: `nombre` y `saludar`. Si escribís cualquiera de las dos, Ruby sabe a qué te referís. Ahora escribí algo que no está:

```ruby
puts atila
# => NameError: undefined local variable or method `atila' for main:Object
```

Leé el mensaje: **"variable local *o* método"**. `atila`, así suelto, podría ser dos cosas: una variable local definida más arriba, o un mensaje a `self` con el receptor implícito de la Parte 3 (`self.atila`). La misma palabra puede ser una u otra, y Ruby tiene que desambiguar. Lo hace en este orden:

1. **¿Hay una variable local con ese nombre en el contexto?** Es la variable.
2. **Si no, es un mensaje a `self`.** Se hace el lookup como siempre.
3. **Si tampoco hay método**, `NameError` nombrando las dos cosas que intentó.

```ruby
def atila                          # ahora hay un método llamado atila
  3
end
puts atila                         # => 3     ← no hay variable, sí hay mensaje: lo manda a self
```

Hay un cuarto caso, cuando la palabra está a la izquierda de un `=`: `saludo = "Hola"`. Alguien escribió `saludo`, y eso **tiene que hacer algo**. Acá Ruby no busca mensajes: una asignación a un nombre suelto es **siempre una variable local**. Si ya existe, la pisa; si no existe, la crea, **en el contexto actual**. No hay ningún escenario en que escribas `saludo = …` y no pase nada.

⚠️ **Trampa que sale de acá.** Para llamar a un setter (`energia=`) desde adentro de la clase hay que escribir el receptor: `self.energia = …`. Sin el `self.`, `energia = energia - 10` crea una variable local nueva que se llama `energia`, el setter nunca se ejecuta, y como esa variable recién nace vale `nil`, la línea explota con `undefined method '-' for nil`. Por eso `age.rb` escribe `self.energia = energia - danio`: el de la izquierda necesita el receptor; el de la derecha es un mensaje sin receptor y se resuelve como siempre.

El algoritmo es siempre el mismo, y por eso el mismo bloque se puede portar distinto según el contexto donde lo ejecutes: la misma palabra es una variable si existe en su contexto, y un mensaje a `self` si no. Vamos a aprovechar eso a propósito: primero con variables, y después (sección 6) con `self`.

---

## 2. El contexto de un proc es hijo del de afuera 🔴

`saludo` se creó adentro del proc. ¿Está disponible afuera?

```ruby
saludar.call                       # ejecuto el proc: saludo se crea adentro
p saludo
# => NameError: undefined local variable or method `saludo' for main:Object
```

No. Entonces **el proc abre un contexto distinto** del de afuera. Si `saludo` estuviera disponible, querría decir que adentro y afuera son el mismo contexto: que toda variable que crea un bloque en realidad la crea en el contexto que lo contiene, y que no existe un contexto local. No es el caso.

Contrastalo con el `if`, que **no** abre un contexto:

```ruby
nombre = "pepita"
if true
  saludo = "lalala"                # se crea "adentro" del if…
end
p saludo                           # => "lalala"     ← …y está disponible afuera: el if no cambió de contexto
```

Es concebible que el proc se portara igual que el `if`. Pero el `if` es una construcción sintáctica propia, y el proc es otra cosa: tienen toda la libertad de comportarse distinto, y lo hacen.

Ahora, si `saludo` **ya existe** afuera cuando el proc la asigna:

```ruby
saludo = "..."                     # ahora sí existe afuera
saludar = proc do
  saludo = "Hola"                  # ← el algoritmo de la sección 1: ¿hay variable saludo? sí → la pisa
  puts saludo + " " + nombre
end
saludar.call                       # => Hola pepita
p saludo                           # => "Hola"       ← la de afuera cambió
```

Cuando el proc dice `saludo`, Ruby busca la variable **hacia arriba, en la jerarquía de contextos**: primero en el del proc, después en el que lo contiene. Si la encuentra, es esa, y la asigna. Si no la encuentra en ningún nivel, la crea en el contexto del proc, que es el suyo, no en uno de arriba. El algoritmo no cambió; lo que cambió es si la variable estaba o no.

Un mensaje de introspección de Ruby te deja **ver** los contextos: `binding` devuelve un objeto que representa el contexto en el que se lo evalúa, y le podés pedir sus variables locales.

```ruby
nombre = "pepita"
saludar = proc do
  saludo = "Hola"
  puts "Dentro del proc:", binding.local_variables.inspect
  puts saludo + " " + nombre
end
saludar.call
puts "Fuera del proc:", binding.local_variables.inspect
# Resultado esperado:
# Dentro del proc:
# [:saludo, :nombre, :saludar]      ← lo suyo (saludo) MÁS todo lo de afuera (nombre, saludar)
# Hola pepita
# Fuera del proc:
# [:nombre, :saludar]               ← afuera, solo lo de afuera
```

> **`binding`:** mensaje que devuelve un objeto que representa el contexto actual (variables locales, `self`). `binding.local_variables` lista los nombres de variables locales visibles en ese punto.

Entonces: **el contexto del proc es hijo del contexto de afuera.** Tiene todo lo del padre, más lo que él agrega. Y lo del padre no es una copia: son **las mismas variables**. Si el proc modifica una, se modifica afuera:

```ruby
mutar = proc { nombre += " cosas" }   # nombre += es nombre = nombre + …: asigna la variable de afuera
mutar.call
p nombre                              # => "pepita cosas"
```

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

---

## 3. La variable que llegó tarde 🔴

Un caso más, que se pone raro. Creo el proc, y **después** agrego una variable al contexto de afuera. ¿El proc la ve?

```ruby
nombre = "pepita"
saludar = proc do
  puts "Dentro del proc:", binding.local_variables.inspect
  puts "Hola " + nombre + otra_cosa.to_s      # usa otra_cosa, que todavía no existe en esta línea
end
otra_cosa = 42                                # ahora existe
saludar.call
# Resultado esperado:
# Dentro del proc:
# [:nombre, :saludar, :otra_cosa]             ← ⚠️ binding dice que otra_cosa ESTÁ…
# NameError: undefined local variable or method `otra_cosa' for main:Object   ← …y la línea siguiente dice que no
```

Las dos cosas son ciertas, y la aparente contradicción enseña algo. `binding.local_variables` mira **en tiempo de ejecución**: cuando el proc corre, `otra_cosa` ya existe en el contexto compartido, y ahí está. Pero la decisión de la sección 1 (¿`otra_cosa` es variable o mensaje?) Ruby **no la toma al ejecutar: la toma al leer el código**, de arriba hacia abajo. Cuando leyó el cuerpo del proc, `otra_cosa` no era variable (todavía no había aparecido ninguna asignación) → quedó resuelto como **mensaje a `self`**. Después apareció la variable, pero esa línea ya estaba decidida. Al ejecutar, manda `self.otra_cosa`, `main` no lo entiende, `NameError`.

Conclusión: el proc no puede referenciar, como variable, algo que **no existía en el momento en que se definió**. Se queda con las variables que existían al crearse. El lookup de variables no es tan dinámico como el de métodos.

---

## 4. `def` corta el contexto (y `class`, y `module`) 🔴

Volvamos a lo de la sección 1, pero en vez de un proc, un método:

```ruby
nombre = "pepita"

saludar = proc { puts "Hola " + nombre }
saludar.call                       # => Hola pepita

def saludar2                       # la misma lógica, pero con def
  puts "Hola " + nombre
end
saludar2
# => NameError: undefined local variable or method `nombre' for main:Object
```

Tanto el `do … end` como el `def` abren un contexto nuevo. Pero el del proc es **hijo** del de afuera: tiene todo lo del padre. El del `def` está **cortado por completo**: lo que había afuera no influye de ninguna manera. Adentro de `saludar2`, `nombre` no es variable, así que se resuelve como mensaje a `self`, y no hay método: error.

**¿Por qué?** Esto es vital, así que despacio. ¿Por qué el `def` no tiene como contexto padre el que lo rodea, si el proc sí? Pensá qué es `self` adentro de un método:

```ruby
class A
  def saludar
    self                           # ¿quién es este self?
  end
end
```

Es la instancia que reciba el mensaje `saludar`. **¿Existe esa instancia en el momento en que estás definiendo el método?** No. Ni siquiera es *una*: son potencialmente infinitas instancias, en infinitos momentos distintos, entrando a ese método. El método **no tiene contexto hasta que lo llaman**, y cuando lo llaman, su contexto se arma a partir del objeto que recibió el mensaje. Al escribir el `def`, no hay objeto, así que no hay nada a lo que "colgarle" el contexto de afuera.

El proc es lo contrario: cuando lo creás, **el contexto está ahí**. Es el que sea que está ejecutando esa línea. Tenés un contexto vivo, y podés crear el del proc como hijo de ese.

```ruby
este = self                        # afuera: self es main
saludar = proc do
  este_otro = self                 # adentro del proc: ¿el mismo?
  p este_otro.equal?(este)         # => true     ← exactamente el mismo objeto
end
saludar.call
```

De acá sale una equivalencia que se usa todo el tiempo: **`self` y "el contexto" son casi intercambiables.** Cualquier palabra que no esté en el contexto como variable se le pide a `self`. Preguntar "¿quién es `self` acá?" y "¿en qué contexto estoy?" es casi la misma pregunta. Y en un método, `self` es siempre **el que recibe el mensaje**: si es un método de instancia, la instancia; si es un método de clase, la clase.

```ruby
class A
  puts self                        # => A          ← en el cuerpo de la clase, self es la clase (a ella le mandás attr_accessor)
  def saludar
    self                           # la instancia que reciba saludar
  end
  def self.algo
    self                           # la clase A: es un método de clase, lo recibe la clase
  end
end
p A.new.saludar.class              # => A
p A.algo                           # => A
```

Los dos `self` del cuerpo de `A` (el suelto y el de adentro de `saludar`) **no son el mismo**, y no porque uno esté "más adentro" que el otro. Estos contextos no se jerarquizan por contención: el de afuera es la clase, el del método es la instancia, y entre ellos hay un corte. Es otra jerarquía, que Ruby define y que no coincide con la de las llaves.

`class` corta igual que `def`, por el mismo motivo: el cuerpo de la clase se ejecuta línea por línea al evaluar la clase, con `self` = la clase, sin nada del contexto que lo rodea:

```ruby
nombre = "pepita"
class B
  puts nombre
end
# => NameError: undefined local variable or method `nombre' for B:Class     ← fijate: acá self es B, no main
```

Las construcciones que crean un contexto nuevo **cortado** del anterior se llaman **scope gates** (compuertas de contexto), y son exactamente tres: **`class`, `module` y `def`.** Nada más las cruza. `if`, `while`, `begin` y los bloques no lo son: el `if` no abre contexto, y el bloque abre uno hijo.

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

Y acá el problema que esto crea: las tres herramientas de Ruby para **empaquetar código** (`def`, `class`, `module`) son las tres que **cortan el contexto**. Empaquetás y perdés las variables. Si querés un método que use `nombre`, no podés.

---

## 5. Flat scope: `define_method` y `Class.new` 🔴

Hay **otra** forma de definir un método, que ya conocés: `define_method`. Recibe el nombre y… el cuerpo **como bloque**. Y los bloques no cortan el contexto:

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

Fijate las dos cosas a la vez. `nombre` lo tomó del contexto de afuera, como cualquier bloque. Pero **`self` no es `main`**, que era el `self` de afuera: es una instancia de `A`. Tiene que ser así: es un método, y un método tiene que poder resolver los mensajes sobre la instancia que lo recibe. Si `self` dependiera de dónde escribiste el `define_method`, no serviría para nada. Entonces acá hay algo que Ruby hace a propósito: **conserva las variables del contexto del bloque, pero le cambia el `self`.**

Para verlo bien, el mismo bloque, usado de las dos formas:

```ruby
saludar2_proc = proc do            # el MISMO código, guardado como proc
  puts "Soy #{self}"
  puts "Hola " + nombre
end

A.define_method(:saludar3, &saludar2_proc)   # el proc pasa a ser el cuerpo del método saludar3 (& en la llamada: Parte 3)

saludar2_proc.call                 # => Soy main          ← ejecutado como proc: el self del contexto donde nació
                                   #    Hola pepita
A.new.saludar3                     # => Soy #<A:0x…>      ← ejecutado como método: self es la instancia
                                   #    Hola pepita       ← en los dos casos, la variable de afuera
```

Literalmente el mismo código, con dos `self` distintos según **cómo** se lo invoque. Usar `define_method` en vez de `def`, además de lo que ya sabías (parametrizar el nombre y la lógica), te deja **incorporar las variables que están en contexto**, que con `def` se perdían del todo.

Lo mismo con `class`. `Class.new` recibe un bloque que se evalúa como el cuerpo de la clase:

```ruby
nombre = "pepita"

B = Class.new do                   # crea una clase nueva; el bloque es su cuerpo
  nombre = "Axel"                  # ¿hay variable nombre? sí, la de afuera → la pisa
  puts nombre                      # => Axel
  puts self                        # => #<Class:0x…>    ← self es la clase nueva (todavía sin nombre)
  def m1                           # adentro se puede usar def normal: define un método de instancia, como siempre
  end
end

puts nombre                        # => Axel            ← la de afuera cambió: misma mecánica que el proc
p B.class                          # => Class           ← es una clase como cualquiera; al asignarla a B recibe ese nombre
```

Adentro del bloque podés escribir lo que escribirías en el cuerpo de cualquier clase. Es muy similar a `class B … end`, con una diferencia: **conoce el contexto de afuera**, ve sus variables y las modifica. Y `self` es la clase, igual que en `class B`: de nuevo, Ruby le cambió el `self` al bloque para que funcione como cuerpo de clase.

A esta técnica se la llama **flat scope** (contexto aplanado): reemplazar la compuerta por su equivalente con bloque, para que el código de adentro comparta el contexto de afuera.

| Con compuerta (corta) | Sin compuerta (flat scope) |
|---|---|
| `def nombre … end` | `define_method(:nombre) do … end` |
| `class Nombre … end` | `Nombre = Class.new do … end` |

> 🎓 **Para el parcial, si te preguntan:** *¿Cómo hacés que un método use una variable local definida afuera?*
> Definiéndolo con `define_method` en vez de `def`. `def` es un scope gate: crea un contexto nuevo cortado del anterior, porque en el momento de definir el método no existe el objeto que le daría contexto. `define_method` recibe el cuerpo como bloque, y un bloque conserva las variables del contexto donde fue escrito; Ruby solo le cambia el `self` para que sea la instancia. La técnica se llama flat scope.

En estos dos casos, `define_method` y `Class.new`, Ruby cambia el `self` del bloque **por su cuenta**, porque el uso lo exige. Lo que sigue es la herramienta para hacerlo **vos**.

---

## 6. `instance_eval`: elegir el `self` de un bloque 🔴

Tomá `saludar2_proc`. Con `call`, `self` es `main`. Quiero ejecutarlo con **otro `self`**: `atila`. Primer intento, ingenuo: que `atila` lo ejecute desde adentro de un método suyo.

```ruby
require_relative 'age'

class Guerrero
  def ejecutar_proc(un_proc)
    un_proc.call                   # atila hace el call…
  end
end

atila = Guerrero.new
atila.ejecutar_proc(saludar2_proc) # => Soy main        ← …y no cambia nada
                                   #    Hola Axel         (nombre vale "Axel" desde el Class.new de la sección 5)
```

No va por el lado de **dónde se ejecuta**. Lo que importa en un proc es **dónde se definió** (Parte 3): se lleva su `self`, lo dispare quien lo dispare. Para cambiarlo hace falta una herramienta que Ruby pone específicamente para eso, parte de su API de metaprogramación (el conjunto de mensajes que el lenguaje ofrece para meterse con su propio modelo): `instance_eval`.

`objeto.instance_eval` recibe un **bloque** y lo ejecuta con `self` = `objeto`. Como lo que tengo es un proc, se lo paso con `&`:

```ruby
atila.instance_eval(&saludar2_proc)
# => Soy #<Guerrero:0x…>           ← ahora self es atila: el receptor de instance_eval
#    Hola Axel                     ← y la variable de afuera se sigue viendo
```

Ruby corrió el bloque **cambiándole el contexto**: el `self` que usa mientras se ejecuta es `atila`. Con esto podés tener un proc definido en cualquier lado y hacer que el `self` de esa ejecución sea otro objeto completamente distinto. Y eso permite hacer cosas que sin esto no cierran:

```ruby
devolver_energia = proc { energia }   # energia, suelto: ¿variable o mensaje? no hay variable → self.energia

devolver_energia.call
# => NameError: undefined local variable or method `energia' for main:Object   ← main no entiende energia

p atila.instance_eval(&devolver_energia)          # => 100    ← con self = atila, energia es atila.energia

class Golondrina
  def energia
    "sí"                           # una golondrina también entiende energia, para hacerlo interesante
  end
end
p Golondrina.new.instance_eval(&devolver_energia) # => "sí"   ← el MISMO bloque, con self = una golondrina
```

Un solo bloque, escrito una vez, sin parámetros. Según el contexto en que lo evalúes pasan cosas completamente distintas: con un objeto que no entiende `energia`, falla; con un guerrero, es su energía; con una golondrina, otra cosa. **Estamos cambiando el `self`**, y con él, a quién le llegan los mensajes sin receptor.

**¿CÓMO FUNCIONA?** El contexto de un bloque tiene dos partes: las variables locales y `self`. `instance_eval` ejecuta el bloque con **las mismas variables** pero **otro `self`**:

```
   contexto donde nació el proc          contexto en que instance_eval lo ejecuta
   ┌──────────────────────────┐          ┌──────────────────────────┐
   │ variables: nombre, …     │ ───────► │ variables: nombre, …     │  ← iguales: siguen viajando
   │ self: main               │    ✗     │ self: atila              │  ← REEMPLAZADO por el receptor
   └──────────────────────────┘          └──────────────────────────┘
```

Es la misma jugada que hacían `define_method` y `Class.new` por su cuenta, ahora bajo tu control.

```ruby
x = 2
atila.instance_eval do             # también se puede escribir el bloque directo, sin proc previo
  puts x                           # => 2           ← la variable local de afuera sigue visible
  puts self.class                  # => Guerrero    ← pero self ya no es main
  p @energia                       # => 100         ← y las variables de instancia son las de atila: estás "adentro" de él
end
```

Ese último punto: adentro de un `instance_eval` ves las variables de instancia del receptor, como si fueras un método de su clase. Es una forma de romper el encapsulamiento a propósito. Herramienta de metaprogramación: mucha potencia, y hay que saber que la estás usando.

> 🎓 **Para el parcial, si te preguntan:** *¿Qué hace `instance_eval`?*
> Ejecuta un bloque cambiándole el `self`: dentro del bloque, `self` pasa a ser el receptor de `instance_eval`, así que los mensajes sin receptor van a ese objeto y sus variables de instancia quedan accesibles. Las variables locales del lugar donde se escribió el bloque siguen visibles. Sirve para escribir un bloque una vez y aplicarlo a distintos objetos sin pasarlos por parámetro, que es la base para construir sintaxis propias (Parte 5).

Esto es **core**: es lo que vas a necesitar para resolver el TP. Y es de las ideas más cortas de la materia: un bloque se lleva su contexto; `instance_eval` le cambia el `self`. Lo que falta no es más teoría: es sentarse a usarla.

---

## 7. Un `def` adentro del bloque: `instance_eval` vs `class_eval` 🟡

*Esta sección no se desarrolló en la clase presencial; está en el material oficial de la cátedra para esta fecha. Va acá para que la unidad quede completa según la planificación.*

Hasta acá los bloques *mandaban* mensajes. Si adentro del bloque escribís un **`def`**, ¿en qué clase queda ese método? Depende de con qué lo ejecutes.

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
# => NoMethodError: undefined method `gritar' for an instance of Guerrero    ← otro guerrero, no
p atila.singleton_class.instance_methods(false)    # => [:gritar]    ← quedó en #atila, la autoclase
```

Tiene sentido: si `self` es un objeto que no es una clase, el único lugar donde "definir un método para este objeto" significa algo es su autoclase. Es lo mismo que `atila.define_singleton_method(:gritar) { "haaaa" }` (clase 3), con un `def` escrito adentro de un bloque.

**Con `class_eval`, el `def` va a la clase misma** (solo las clases y los módulos lo entienden; para un módulo se llama `module_eval`, y es el mismo método):

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

`class_eval` es como reabrir la clase con `class Guerrero … end`, con la diferencia de la sección 5: es un bloque, así que **no corta el contexto** (flat scope). Lo que sigue siendo compuerta es el `def` de adentro: si querés que el *cuerpo del método* use una variable de afuera, adentro del `class_eval` va `define_method`.

Y el caso que sorprende: `Guerrero.instance_eval { p self }` y `Guerrero.class_eval { p self }` imprimen **los dos `Guerrero`**. El `self` es el mismo. Lo que cambia es **a dónde va un `def`**: con `instance_eval` sobre una clase, va a la autoclase de la clase, o sea, queda como **método de clase**.

| Al ejecutar el bloque con… | `self` es… | un `def` adentro se define en… | Quién lo entiende |
|---|---|---|---|
| `objeto.instance_eval` | `objeto` | la **autoclase** de `objeto` | solo `objeto` |
| `Clase.instance_eval` | `Clase` | la autoclase de `Clase` (`#Clase`) | `Clase` (método de clase) |
| `Clase.class_eval` | `Clase` | **`Clase`** misma | todas las instancias de `Clase` |
| `Modulo.module_eval` | `Modulo` | `Modulo` | quien incluya el módulo |

La forma de no perderse: en cada paso, preguntá **quién es el receptor** y **si usás `instance_eval` o `class_eval`**. `instance_eval` → autoclase del receptor. `class_eval` → el receptor mismo, que tiene que ser una clase o módulo.

Una variante más, que aparece en cuanto empezás a combinar: `instance_eval` no te deja pasarle parámetros al bloque. Si necesitás cambiar el `self` **y** parametrizar, es `instance_exec`:

```ruby
atila.instance_exec(15) { |danio| self.energia -= danio }   # self = atila, y además el bloque recibe 15
p atila.energia                                              # => 35      (50 − 15)
```

Regla: `instance_eval` cuando el bloque no lleva parámetros; `instance_exec` cuando sí. En todo lo demás son idénticos.

> 🎓 **Para el parcial, si te preguntan:** *¿Qué diferencia hay entre `instance_eval` y `class_eval`?*
> Los dos ejecutan un bloque con `self` = el receptor. La diferencia está en dónde quedan los métodos escritos con `def` adentro del bloque: `instance_eval` los define en la autoclase del receptor (solo ese objeto los entiende; si el receptor es una clase, quedan como métodos de clase); `class_eval` los define en la clase receptora, para todas sus instancias. `class_eval` solo lo entienden clases y módulos.

---

## Checkpoint de la Parte 4

Sin respuestas.

1. Este código falla: `x = 1; def m; x; end; m`. Escribí el mensaje de error completo y explicá qué significa cada mitad del "variable local o método".
2. En `def m; saraza = 15; saraza; end`, con un método `saraza` que devuelve 10, ¿qué devuelve `m` y por qué? ¿Cómo alcanzarías al método igual?
3. ¿Qué diferencia hay entre el contexto que abre un `if`, el que abre un proc y el que abre un `def`? Dá un ejemplo de código para cada uno donde se note.
4. Un proc asigna `saludo = "Hola"`. ¿En qué caso pisa una variable de afuera y en qué caso crea una propia? ¿Qué algoritmo decide eso?
5. Creás un proc que usa `otra_cosa`, y después definís `otra_cosa = 42`. Al ejecutar el proc, `binding.local_variables` la muestra y aun así falla. Explicá las dos cosas.
6. ¿Por qué `def` no puede tener como contexto padre el contexto que lo rodea, si el proc sí puede? ¿Qué tiene que ver `self` con eso?
7. Nombrá las tres scope gates. ¿Por qué es un problema que sean exactamente las tres construcciones que empaquetan código?
8. Tenés `saludar2_proc = proc { puts self }`. Mostrá tres formas de ejecutarlo donde `self` sea `main`, una instancia de `A`, y `atila`, respectivamente.
9. `atila.ejecutar_proc(un_proc)` no cambia el `self` del proc. ¿Por qué? ¿Qué sí lo cambia?
10. Querés que **todos** los guerreros entiendan `huir`, y querés que el cuerpo del método use una variable local `factor` definida afuera. ¿Con qué combinación de herramientas lo hacés, y por qué no sirve `class Guerrero; def huir …`?
11. Aparece este requerimiento: "quiero un bloque que compruebe si un guerrero está herido, escrito una vez, y aplicarlo a varios guerreros sin pasárselos por parámetro". ¿Qué herramienta usás y cómo queda el código?

---

## Qué viene en la Parte 5

Todo lo anterior, junto, construyendo algo: una sintaxis de test que parece otro lenguaje (`test_suite do test "…" do assert(…) end end`) y que se explica entera con "cada palabra suelta es un mensaje a `self`" más `instance_eval` en cada nivel. Después, por qué se construyen estos lenguajes específicos (DSLs), un ejemplo de consulta a base de datos que se lee como SQL, las tres cosas que hay que llevarse de esta clase, y toda la información operativa: qué viene la clase que viene, el TP1, GitHub y Discord.

**FIN DE LA PARTE 4**
