# Clase desde Cero — Clase 04 (2020) — Módulo 5
## `self` e `instance_eval`

> **Sobre este documento.** Cubre la tercera idea de la clase: **a quién le llegan los mensajes sin receptor dentro de un bloque, y cómo cambiarlo desde afuera**. Vas a ver que un proc se lleva su `self` igual que se lleva sus variables, que `instance_eval` reemplaza ese `self` por otro objeto, qué agrega `instance_exec`, y la pregunta que cierra todo: cuando escribís un `def` adentro de un bloque, ¿en qué clase queda ese método? Ahí aparece `class_eval` y el concepto de *target class*.
> **No cubre:** construir algo con esto. Objetos inline y el framework de testing son el módulo 6.

> **De dónde venís.** Del módulo 3: el contexto es variables locales + `self`, y las compuertas cambian las dos cosas. Del módulo 4: un proc es un closure que conserva el contexto; `define_method` cambia el `self` del bloque (lo viste al final, sin explicación: acá está). Del módulo 1: `puts "hola"` es `self.puts("hola")`. De la clase 03: autoclases (`#atila`, `#Guerrero`), `def self.` define en la autoclase de la clase, `singleton_class`, `instance_methods(false)`.

---

## 1. El receptor implícito 🔴

Recordatorio del módulo 1, ahora con todo el peso: **un mensaje sin receptor va a `self`**. Adentro de un método, `self` es el objeto que recibió ese mensaje, así que los métodos se pueden hablar entre sí sin nombrarse:

```ruby
require_relative 'age'

class Guerrero
  def herido?
    energia < 50        # energia, sin receptor = self.energia: el getter del mismo guerrero
  end
end

atila = Guerrero.new(20, 100, 10)
p atila.herido?         # => false
atila.sufri_danio(60)   # energía 100 → 40
p atila.herido?         # => true
```

Escribimos `energia` y no `self.energia` porque el receptor implícito es `self`, y adentro de `herido?` `self` es `atila`. Todo `age.rb` está escrito así (`sufri_danio` hace `self.energia = energia - danio`; el `energia` de la derecha es un mensaje a `self`).

Entonces la pregunta de este módulo es: **¿quién es `self` adentro de un bloque?**

---

## 2. `self` dentro de un bloque: viaja con el closure 🔴

Un proc se lleva las variables del contexto donde nació. Y se lleva también su `self`:

```ruby
un_bloque = proc { puts self }    # el proc nace en el archivo suelto: self es main
puts self                         # => main
un_bloque.call                    # => main     ← adentro del proc, el mismo self
```

Ahora un proc que nace **adentro de un método de `atila`**:

```ruby
class Guerrero
  def dame_bloque
    proc { self }             # este proc nace con self = el guerrero que recibió dame_bloque
  end
  def lazy_energia
    proc { energia }          # mensaje sin receptor, adentro del proc: va a ESE self
  end
end

b = atila.dame_bloque         # el proc ya salió del método
p b.call.equal?(atila)        # => true     ← pero su self sigue siendo atila
```

Y esto no cambia aunque lo ejecute otro objeto, en otro lugar:

```ruby
class Golondrina
  def energia
    "poca"                    # una golondrina también entiende energia, para hacerlo interesante
  end
  def ejecutar(bloque)
    bloque.call               # la golondrina dispara el proc
  end
end

g = Golondrina.new
p g.ejecutar(atila.lazy_energia)    # => 40       ← la energía de ATILA, no "poca". El proc le habla a su self de origen.
p g.ejecutar(b).equal?(atila)       # => true
```

El proc nació en el contexto de `atila`; `energia` adentro del proc es `atila.energia`, lo dispare quien lo dispare. Consistente con todo el módulo 4: **el contexto viaja con el closure, y `self` es parte del contexto**.

```
   nace adentro de atila.lazy_energia            lo ejecuta la golondrina
   ┌────────────────────────────┐                ┌────────────────────────────────┐
   │ proc { energia }           │                │ def ejecutar(bloque)           │
   │   variables: (ninguna)     │ ── el proc ──► │   bloque.call                  │
   │   self: atila              │    viaja       │     energia → ¿a quién?        │
   └────────────────────────────┘                │     → a atila, que viene       │
                                                 │       adentro del proc  (40)   │
                                                 │     NO a la golondrina         │
                                                 └────────────────────────────────┘
```

Consecuencia directa: un proc creado en el archivo suelto le habla a `main`, y `main` no es un guerrero:

```ruby
en_main = proc { energia }    # nace con self = main
en_main.call
# => NameError: undefined local variable or method 'energia' for main:Object
```

### El problema que esto crea

Querés un bloque que "pregunte la energía" y poder aplicarlo a **distintos guerreros**. Con lo que sabés, la única salida es pasar el objeto por parámetro:

```ruby
con_param = proc { |guerrero| guerrero.energia }    # el destinatario entra como argumento
p con_param.call(atila)                             # => 40
p con_param.call(Guerrero.new)                      # => 100
```

Funciona, pero es incómodo: cada mensaje del bloque necesita el `guerrero.` adelante, y el que escribe el bloque tiene que saber que existe ese parámetro. Lo que uno quisiera es escribir `proc { energia }`, así, limpio, y decidir **después** a quién se lo pregunta. Para eso hay que poder cambiar el `self` de un bloque desde afuera.

---

## 3. `instance_eval`: ejecutar un bloque con otro `self` 🔴

```ruby
"hola".instance_eval { puts self }    # => hola     ← el bloque se ejecutó con self = el string "hola"
```

`objeto.instance_eval { … }` ejecuta el bloque **como si estuviera adentro de `objeto`**: `self` pasa a ser el receptor de `instance_eval`. Los mensajes sin receptor van a él.

```ruby
p atila.instance_eval { energia }     # => 40     ← energia, sin receptor, le llegó a atila
```

Y con un proc ya existente, pasándolo con `&` (módulo 4, sección 3):

```ruby
devolver_energia = proc { energia }              # nace en main. Si lo llamás con call, falla (sección 2).

p atila.instance_eval(&devolver_energia)         # => 40        ← el MISMO proc, ejecutado con self = atila
p g.instance_eval(&devolver_energia)             # => "poca"    ← el MISMO proc, con self = la golondrina
p Guerrero.new.instance_eval(&devolver_energia)  # => 100       ← y con un guerrero nuevo
```

Un solo bloque, escrito una vez, sin parámetros, aplicado a tres objetos distintos. Eso es lo que `instance_eval` compra.

**¿CÓMO FUNCIONA?** El contexto de un bloque tiene dos partes: las variables locales y `self`. `instance_eval` toma el bloque y lo ejecuta con **las mismas variables** pero **otro `self`**:

```
   contexto donde nació el proc        contexto en que instance_eval lo ejecuta
   ┌──────────────────────────┐        ┌──────────────────────────┐
   │ variables: x = 2, ...    │──────► │ variables: x = 2, ...    │  ← iguales: siguen viajando
   │ self: main               │   ✗    │ self: atila              │  ← REEMPLAZADO por el receptor
   └──────────────────────────┘        └──────────────────────────┘
```

Verificalo:

```ruby
x = 2
atila.instance_eval do
  puts x                  # => 2           ← la variable local de afuera sigue visible
  puts self.class         # => Guerrero    ← pero self ya no es main
  p @energia              # => 40          ← y las variables de instancia son las de atila: estás "adentro" de él
end
```

Ese último punto es importante: adentro de un `instance_eval` **ves las variables de instancia del receptor**, como si fueras un método de su clase. Es una forma de romper el encapsulamiento a propósito. Herramienta de metaprogramación: mucha potencia, y hay que saber que la estás usando.

⚠️ **Trampa con lambdas:** `instance_eval` le pasa el receptor al bloque **como argumento**. Un proc lo ignora; una lambda sin parámetros explota:

```ruby
lam = lambda { puts self }
"hola".instance_eval(&lam)
# => ArgumentError: wrong number of arguments (given 1, expected 0)    ← la lambda no esperaba nada, y le llegó "hola"

lam2 = lambda { |recibido| p recibido }
"hola".instance_eval(&lam2)          # => "hola"    ← declarando el parámetro, funciona: recibe el receptor
```

Con `instance_eval` usá procs o bloques. Las lambdas, por su aridad estricta, chocan.

> 🎓 **Para el parcial, si te preguntan:** *¿Qué hace `instance_eval`?*
> Ejecuta un bloque en el contexto de un objeto: `self` dentro del bloque pasa a ser el receptor de `instance_eval`, así que los mensajes sin receptor van a ese objeto y sus variables de instancia quedan accesibles. Las variables locales del lugar donde se escribió el bloque siguen visibles. Sirve para escribir un bloque una vez y aplicarlo a distintos objetos sin pasarlos por parámetro.

---

## 4. `instance_exec`: lo mismo, con argumentos 🟡

`instance_eval` no te deja pasarle argumentos al bloque (lo único que le pasa es el receptor). Si necesitás cambiar `self` **y** parametrizar, es `instance_exec`:

```ruby
atila.instance_exec(15) { |danio| self.energia -= danio }    # self = atila, y además el bloque recibe 15
p atila.energia                                              # => 25     (40 − 15)
```

Con un proc guardado, igual:

```ruby
class Coso
  def initialize(y); @y = y; end
  def y; @y; end
end

sumar = proc { |extra| x = 10; x + y + extra }    # y sin receptor → self; extra viene como argumento

p Coso.new(30).instance_exec(1, &sumar)    # => 41     (10 + 30 + 1)
p Coso.new(10).instance_exec(2, &sumar)    # => 22     (10 + 10 + 2)
```

Regla: `instance_eval` cuando el bloque no lleva parámetros; `instance_exec` cuando sí. Todo lo demás es idéntico.

---

## 5. Un `def` adentro de un bloque: ¿dónde queda el método? 🔴

Hasta acá los bloques *mandaban* mensajes. Ahora un bloque que **define** un método:

```ruby
atila = Guerrero.new(20, 100, 10)
otro = Guerrero.new

atila.instance_eval do
  def gritar              # un def, adentro de un bloque, que se ejecuta con self = atila
    "haaaa"
  end
end

p atila.gritar            # => "haaaa"     ← atila lo entiende
otro.gritar
# => NoMethodError: undefined method 'gritar' for an instance of Guerrero    ← otro guerrero, no
```

Solo `atila` entiende `gritar`. Entonces el método no quedó en `Guerrero`. ¿Dónde quedó?

```ruby
p atila.singleton_class.instance_methods(false)    # => [:gritar]    ← en la AUTOCLASE de atila
```

Regla: **`instance_eval` define los `def` en la autoclase del receptor**. Tiene sentido: si `self` es un objeto que no es una clase, el único lugar donde "definir métodos para este objeto" significa algo es su autoclase. Es lo mismo que hacer `def atila.gritar` (clase 03), pero con el `def` escrito adentro de un bloque.

### Ahora el receptor es una clase

Las clases son objetos, así que también entienden `instance_eval`. Y la regla es la misma, con una consecuencia que sorprende la primera vez:

```ruby
Guerrero.instance_eval do
  def crear_de_elite            # def adentro de un instance_eval cuyo receptor es la CLASE Guerrero
    new(50, 200, 30)            # new sin receptor → self → Guerrero.new
  end
end

p Guerrero.crear_de_elite.energia   # => 200     ← funciona como MÉTODO DE CLASE
atila.crear_de_elite
# => NoMethodError: undefined method 'crear_de_elite' for an instance of Guerrero    ← las instancias no lo tienen

p Guerrero.singleton_class.instance_methods(false)                  # => [:crear_de_elite]    ← quedó en #Guerrero
p Guerrero.instance_methods(false).include?(:crear_de_elite)         # => false                ← en Guerrero no está
```

Misma regla: `instance_eval` define en la autoclase del receptor. El receptor es `Guerrero`; su autoclase es `#Guerrero`; los métodos de `#Guerrero` son los **métodos de clase** (clase 03). Así que `def` adentro de `Guerrero.instance_eval` es exactamente `def self.crear_de_elite` adentro de `class Guerrero`.

Lo que **no** conseguiste es lo que probablemente querías: un método para todas las instancias.

### `class_eval`: definir en la clase misma

```ruby
Guerrero.class_eval do
  def huir                          # def adentro de un class_eval
    self.energia = energia / 2
  end
end

p atila.huir                                          # => 50      ← todas las instancias lo entienden
p otro.huir                                           # => 50
p Guerrero.instance_methods(false).include?(:huir)    # => true    ← quedó en Guerrero
Guerrero.huir
# => NoMethodError: undefined method 'huir' for Guerrero:Class    ← y NO es método de clase
```

`class_eval` ejecuta el bloque con `self` = la clase, **igual que `instance_eval`**, pero los `def` van a la clase receptora, no a su autoclase. Es como reabrir la clase con `class Guerrero … end`, con una diferencia decisiva: **es un bloque**, así que no corta el contexto (flat scope, módulo 4). Solo las clases y los módulos entienden `class_eval` (para un módulo el nombre es `module_eval`; son el mismo método).

```ruby
nombre = "atila"
class Guerrero
  puts nombre              # NameError: class es una compuerta
end
Guerrero.class_eval do
  puts nombre              # => atila     ← class_eval no lo es
end
```

⚠️ Lo que sigue siendo compuerta es el **`def`** de adentro. `Guerrero.class_eval do def huir; energia / factor; end end` no ve `factor`: el bloque lo ve, el `def` no. Si querés que el *cuerpo del método* use la variable de afuera, adentro del `class_eval` va `define_method(:huir) do … end` (módulo 4, sección 5): dos bloques, cero compuertas.

### Target class: la tercera parte del contexto

Fijate que `Guerrero.instance_eval { p self }` y `Guerrero.class_eval { p self }` imprimen los dos `Guerrero`. **`self` es el mismo.** Lo que cambia es *a dónde va un `def`*. Entonces el contexto de un bloque tiene una tercera pieza, además de las variables y `self`: la clase donde se definen los métodos, que se llama **target class** (o *default definee*).

| Al ejecutar el bloque con... | `self` es... | un `def` adentro se define en... (target class) | Quién lo entiende |
|---|---|---|---|
| `objeto.instance_eval` | `objeto` | la **autoclase** de `objeto` | solo `objeto` |
| `Clase.instance_eval` | `Clase` | la **autoclase** de `Clase` (`#Clase`) | `Clase` (método de clase) |
| `Clase.class_eval` | `Clase` | **`Clase`** misma | todas las instancias de `Clase` |
| `Modulo.module_eval` | `Modulo` | `Modulo` | quien incluya el módulo (es abrir un mixin de la clase 2 desde un bloque) |

Un dibujo del metamodelo con las cuatro filas ubicadas:

```
                 instance_eval en atila           class_eval en Guerrero        instance_eval en Guerrero
                          │                               │                              │
                          ▼                               ▼                              ▼
   atila ──(autoclase)──► #atila ──(superclase)──► Guerrero ──(autoclase)──► #Guerrero
     ▲                       ▲                        ▲                          ▲
   la instancia         solo atila               todas las instancias       métodos de clase
```

Dos variantes que aparecen cuando uno empieza a combinar, para que no te sorprendan:

```ruby
atila.singleton_class.class_eval do    # class_eval sobre la autoclase de atila: define EN #atila
  def saltar; "salto"; end
end
p atila.saltar                          # => "salto"    ← equivalente a atila.instance_eval para los def

atila.singleton_class.instance_eval do # instance_eval sobre la autoclase: define en la autoclase DE la autoclase
  def volar; "vuelo"; end
end
atila.volar
# => NoMethodError: undefined method 'volar' for an instance of Guerrero    ← atila no lo tiene
p atila.singleton_class.volar           # => "vuelo"    ← lo tiene #atila, como método propio de esa clase
```

La forma de no perderse: en cada paso, preguntá **quién es el receptor** y **si uso `instance_eval` o `class_eval`**. `instance_eval` → autoclase del receptor. `class_eval` → el receptor mismo (que tiene que ser una clase). Nada más.

### Las autoclases encadenadas, y por qué son "bajo demanda"

Eso que quedó flotando en la clase 3, "los singletons se encadenan y son lazy", es exactamente lo que acabás de hacer. `#atila` es un objeto; como todo objeto, tiene autoclase (`##atila`); y esa también. Ruby **no las crea de antemano**: crea cada una la primera vez que alguien la pide, ya sea con `singleton_class`, con `def atila.x`, o con un `def` adentro de un `instance_eval`. Eso es "bajo demanda".

```ruby
p atila.singleton_class                              # => #<Class:#<Guerrero:0x...>>            ← #atila (se creó recién, si no existía)
p atila.singleton_class.singleton_class              # => #<Class:#<Class:#<Guerrero:0x...>>>   ← ##atila (ídem)
p atila.singleton_class.superclass                   # => Guerrero
p atila.singleton_class.singleton_class.superclass   # => #<Class:Guerrero>                     ← la superclase de ##atila es #Guerrero
```

```
   atila ──► #atila ──► ##atila ──► …        cada flecha: "su autoclase". Se crea cuando alguien la pide.
     │          │           │
     ▼          ▼           ▼
   Guerrero   #Guerrero   ##Guerrero         ← la jerarquía paralela de la clase 3: la superclase de cada
                                               autoclase es la autoclase de la superclase
```

No lo vas a necesitar más allá del segundo nivel. Lo importante es que no hay magia: es el mismo mapa, repetido hacia arriba las veces que haga falta, y solo cuando hace falta.

> 🎓 **Para el parcial, si te preguntan:** *¿Qué diferencia hay entre `instance_eval` y `class_eval`?*
> Los dos ejecutan un bloque con `self` = el receptor. La diferencia está en dónde se definen los métodos escritos con `def` adentro del bloque (la target class): `instance_eval` los define en la autoclase del receptor, así que solo ese objeto los entiende (o, si el receptor es una clase, quedan como métodos de clase); `class_eval` los define en la clase receptora, así que los entienden todas sus instancias. `class_eval` solo lo entienden clases y módulos.

🟢 `class_exec` y `module_exec` son a `class_eval` lo que `instance_exec` es a `instance_eval`: la misma cosa, aceptando argumentos para el bloque.

> 🕳️ **Madriguera — `define_method` adentro de `instance_eval`**
> `define_method` no lo entienden los objetos comunes, solo las clases y módulos (y `main`, que es un caso especial y define en `Object`). Adentro de `atila.instance_eval` no podés usarlo (`NoMethodError`); adentro de `Guerrero.class_eval` sí, y define en `Guerrero`. Para el objeto solo, `atila.singleton_class.define_method(:x) { … }`.
> *Volvé al camino — esto se profundiza aparte, otro día.*

---

## 6. Resumen operativo 🟡

Todo lo del módulo, en modo "quiero X → hago Y":

| Quiero… | Hago… |
|---|---|
| Ejecutar un bloque con `self` = un objeto | `objeto.instance_eval { … }` o `objeto.instance_eval(&proc)` |
| Lo mismo, pasándole argumentos al bloque | `objeto.instance_exec(args) { \|a\| … }` |
| Agregarle un método solo a un objeto, desde un bloque | `objeto.instance_eval { def m … end }` |
| Agregarle un método de clase a una clase, desde un bloque | `Clase.instance_eval { def m … end }` |
| Agregarle un método de instancia a una clase, desde un bloque | `Clase.class_eval { def m … end }` |
| Que el cuerpo de una clase vea las variables locales de afuera | `Clase.class_eval { … }` en vez de `class Clase … end` |
| Saber a dónde va a parar un `def` | Receptor + `instance_eval` → autoclase del receptor · Receptor + `class_eval` → el receptor |

---

## Checkpoint del Módulo 5

Sin respuestas.

1. ¿Quién es `self` adentro de `proc { energia }` si el proc se creó en el archivo suelto? ¿Y si se creó adentro de un método de `atila`? ¿Cambia si lo ejecuta una golondrina?
2. ¿Qué dos partes del contexto conserva un proc, y cuál de las dos reemplaza `instance_eval`? ¿Qué pasa con las variables locales de afuera adentro de un `instance_eval`?
3. Tenés `chequear = proc { energia > 50 }`. Mostrá cómo aplicarlo a `atila` y a `otro` sin modificar el proc ni pasarles parámetros.
4. `"hola".instance_eval(&lambda { puts self })` falla. ¿Por qué, y cuáles son las dos formas de arreglarlo?
5. ¿Cuándo usás `instance_exec` en vez de `instance_eval`?
6. `atila.instance_eval { def gritar; "a"; end }`: ¿dónde queda `gritar`, quién lo entiende, y a qué sintaxis de la clase 03 equivale?
7. `Guerrero.instance_eval { def x; end }` y `Guerrero.class_eval { def x; end }`: ¿quién es `self` en cada uno? ¿Quién entiende `x` en cada caso?
8. ¿Qué es la target class? ¿Por qué hace falta como concepto separado de `self`?
9. Querés que **todos** los guerreros entiendan `huir`, y querés que el cuerpo del método use una variable local `factor` definida afuera. ¿Con qué combinación de herramientas lo hacés y por qué no sirve `class Guerrero; def huir …`?

---

## Qué viene en el Módulo 6

Las tres ideas juntas, construyendo algo. Primero, una sintaxis propia para crear objetos y clases sin `class`: `objeto do … end` y `clase do … end`, que son cuatro líneas cada una con lo que ya sabés. Después, un framework de testing desde cero: `test_suite do test "…" do assert(…) end end`. Vas a ver por qué cada `do … end` de esa sintaxis necesita `instance_eval`, por qué los tests se guardan como procs y se ejecutan después, y cómo un proc con `return` hace que un test que falla se corte en el acto. Y al final, el mapa de nombres para abrir el repo de tu cursada y leerlo de corrido.

**FIN DEL MÓDULO 5**
