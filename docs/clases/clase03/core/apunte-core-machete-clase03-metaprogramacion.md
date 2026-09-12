# 🛠️ Apunte Core-Machete — Clase 03: Metaprogramación en Ruby

**Materia:** Técnicas Avanzadas de Programación (TAdP) · **Unidad:** clase03 · **Clase del:** 29/08/2026

> **Qué es este archivo:** la clase 03 (introspection, self-modification, open classes, autoclases, metamodelo) reducida a lo que se tiene al lado mientras se resuelve el TP1 o un ejercicio: sintaxis, reglas mecánicas, casos con código, tabla de decisión, errores comunes y checklist.
> **Asume leído el apunte maestro** (Partes 0 a 6); esta unidad no tiene apunte core porque la clase ya era core.
> **Qué no está acá:** instalación de Ruby y Pry (maestro P0 §1-4) · comparaciones con Java, Smalltalk, JavaScript y Scala (P1 §8, P3 §5, P5 §2-3, P6 §1) · madrigueras 🕳️ · bloques "Para el parcial" · el cierre sobre por qué Ruby lo hace así y el matafuego (P6 §8-9; el criterio de *cuándo* usar metaprogramación sí entra, como tabla seca en §7).

Las referencias entre paréntesis del tipo `(P2 §9)` apuntan al maestro. Son notas para profundizar, no requisitos: este archivo se sostiene solo.

---

## 0. Consola: lo mínimo para verificar `(P0 §6, §8)`

```ruby
$ cd carpeta-del-archivo         # Pry se lanza PARADO donde está el .rb
$ pry
[1] pry(main)> require_relative 'age-clase2'   # carga el archivo UNA vez por sesión
=> true
[2] pry(main)> class A            # el prompt cambia > por * mientras la definición no cierra
[2] pry(main)*   def bleh
[2] pry(main)*     2
[2] pry(main)*   end
[2] pry(main)* end
=> :bleh                          # definir un método devuelve su nombre como símbolo
[3] pry(main)> Pry.config.pager = false   # apaga el paginador (listas largas de corrido)
[4] pry(main)> exit               # todo lo definido en la sesión se pierde; el archivo no se toca
```

- ⚠️ **Editaste el archivo con Pry abierto → la sesión sigue viendo la versión vieja.** `exit`, `pry`, `require_relative` de nuevo.
- ⚠️ **Rompiste la consola** (abriste `Integer`, `Kernel`…) → `exit` y volver a entrar. Se rompió la sesión, no la instalación.
- `PP::ObjectMixin` en cualquier `ancestors` **es de Pry, no de Ruby**. Ignoralo.

---

## 1. El lenguaje que necesitás para esta unidad

Sintaxis que aparece en todo el código de la clase sin explicarse en el momento. Cada línea con su trampa al lado.

### Símbolos `(P2 §3)`

```ruby
:descansar                  # un símbolo: un NOMBRE. Único en todo el programa.
:descansar.to_s             # => "descansar"     símbolo → string
"descansar".to_sym          # => :descansar      string → símbolo
"comete_una_#{comida}".to_sym   # armar un nombre: interpolación + to_sym   (P4 §4)
"@#{attr}".to_sym           # :apodo → :@apodo  (el nombre real de una variable de instancia)  (P4 §5)
```

Cuando una respuesta de la consola es una lista de símbolos, es una **lista de nombres** (selectores), no de métodos.

### `self` `(P2 §9)`

- Adentro de un método: **el objeto que recibió el mensaje**. Cambia según quién lo recibió.
- En el cuerpo de una clase o módulo (fuera de todo método): **la clase o el módulo mismo**. Por eso `attr_accessor :x` en el cuerpo de `Defensor` es `self.attr_accessor(:x)` con `self == Defensor`.
- **Todo lo que escribís en el cuerpo de una clase es un mensaje que se le manda a la clase**, no a sus instancias.

### Tres formas de decir "energía" `(P2 §9)`

```ruby
def ejemplo
  @energia            # 1. la variable de instancia, acceso directo (casi nunca se usa así)
  self.energia        # 2. mensaje a self: el getter. La forma clara.
  energia             # 3. AMBIGUA: mensaje a self si existe el método; si no, variable local.
  energia = 5         # ⚠️ SIEMPRE variable local nueva. El atributo NO cambia. Silencio total.
  self.energia = 5    # ✅ llama al setter energia=
  enrgia              # ⚠️ typo sin self. → variable local que vale nil; el error aparece 3 líneas después
end
```

### Métodos que terminan en `=` `(P2 §9)`

```ruby
atila.energia = 80            # NO es asignación: es el mensaje energia= con argumento 80
atila.energia=(80)            # lo mismo sin azúcar
atila.send(:energia=, 80)     # lo mismo con send: el selector INCLUYE el =
self.energia += 10            # se expande a  self.energia = self.energia + 10  → getter, después setter
```

### `attr_accessor` es un mensaje, no una palabra clave `(P2 §9, P4 §5)`

```ruby
attr_accessor :energia        # genera SOLO dos métodos: energia (getter) y energia= (setter)
                              # NO declara ni crea @energia: la variable aparece cuando alguien la setea
```

### `def self.x` = método de clase `(P1 §2, P4 §5, P6 §4)`

```ruby
class Guerrero
  def descansar; end          # lo entiende atila  (una instancia)
  def self.crear_vikingo; end # lo entiende Guerrero (la clase). Se usa: Guerrero.crear_vikingo
end
```

### Bloques `(P4 §4)`

```ruby
Guerrero.define_method(:comete_bonus) { self.energia += bonus }   # { ... } es el bloque
                              # adentro, self = el objeto que reciba el mensaje (igual que en un def)
                              # el bloque VE las variables locales del lugar donde fue escrito (bonus)
{ |value| ... }               # parámetros del bloque van entre barras
```

### `class X ... end` abre, no crea `(P4 §2)`

Si `X` no existe, la crea. Si existe (incluso `String`, `Integer`), la **reabre** y lo que escribas adentro se agrega o pisa.

### Varios `(P2 §5, §7)`

```ruby
atila.is_a? Guerrero          # el ? es parte del nombre; convención para métodos que devuelven true/false
lista.select { |x| cond }     # filtra
lista.flat_map { |x| otra_lista }   # aplica y aplana en una sola lista
lista_a & lista_b             # intersección: elementos que están en ambas
lista.include?(:x)            # ¿está?
```

---

## 2. Los conceptos, en pocas líneas

| Concepto | Qué es, para trabajar | Nota |
|---|---|---|
| **Metaprogramación** | Escribir programas cuyo dominio son otros programas: los generan, manipulan o utilizan. Sirve para frameworks: código que trabaja sobre clases y métodos que su autor no conoce. | P1 §3-4 |
| **Reflection** | Metaprogramar **en el mismo lenguaje** que el programa manipulado, con las herramientas que el lenguaje da. | P1 §5 |
| **Introspection** | El programa se **analiza** a sí mismo: qué clase, qué métodos, qué variables. La mitad segura: no cambia nada. | P1 §5, P2 |
| **Self-modification** | El programa se **modifica** a sí mismo en ejecución: abrir clases, agregar/pisar métodos, construir métodos con nombres calculados. | P1 §5, P4 |
| **Intercession** | Modificar el lenguaje mismo. **No se ve en la materia.** | P1 §5 |
| **Metamodelo** | El modelo de qué es una clase, un método, un módulo y cómo se conectan. Se descubre entero con `class`, `superclass`, `ancestors`, `singleton_class`. | P1 §6, P5, P6 |
| **Selector** | El **nombre** de un método (un símbolo). `methods` e `instance_methods` devuelven selectores, no métodos. | P2 §4 |
| **`Method`** | El método como objeto, **vinculado** a un receptor. Se obtiene con `obj.method(:x)`. Entiende `call`. | P3 §2 |
| **`UnboundMethod`** | El mismo método **sin receptor**. Se obtiene con `Clase.instance_method(:x)`. No entiende `call`; sí `bind`. | P3 §3 |
| **Open class** | Reabrir una clase existente para agregarle o pisarle métodos. Retroactivo: las instancias viejas lo ven. | P4 §2 |
| **Monkey patching** | Modificar un tipo existente (abrir `String`, `Integer`) para que responda lo que necesitás. Útil y peligroso. | P4 §3 |
| **Duck typing** | Importa cómo se comporta el objeto, no de qué clase es. Por eso `is_a?` pesa más que `class ==`. | P4 §3 |
| **Autoclase** (singleton class / eigenclass) | Clase privada de **un único objeto**, donde va el comportamiento que es solo de él. Todo objeto tiene una; se crea cuando se pide. | P6 §3 |
| **Método de clase** | Mensaje que se le manda al objeto clase. Vive en la **autoclase de la clase**. Se hereda, se redefine, admite `super`. No es un "método estático". | P6 §1, §4 |

---

## 3. Reglas mecánicas

### 3.1 Method lookup `(P3 §1, P6 §7)`

**Un paso verde, n pasos rojos, corte en `nil`.**

1. A la **autoclase** del receptor (`singleton_class`).
2. Por las **superclases** de esa autoclase, hasta encontrar `nil`.
   - Receptor **instancia** → la superclase de su autoclase es **su clase**; de ahí sigue por mixins y superclases.
   - Receptor **clase** → la superclase de su autoclase es **la autoclase de su superclase** (`#Espadachin → #Guerrero → #Object → #BasicObject`), después `Class → Module → Object → BasicObject`.
3. Del otro lado de una flecha roja hay `nil` → se corta. No se encontró → `NoMethodError`.

Si ninguna autoclase tiene nada, el recorrido equivale al de siempre: **clase → mixins → superclase**. La autoclase se nota solo cuando le pusiste algo.

```ruby
atila.singleton_class.ancestors
# => [#<Class:#<Guerrero:0x...>>, Guerrero, Defensor, Atacante, Object, PP::ObjectMixin, Kernel, BasicObject]
Guerrero.ancestors
# => [Guerrero, Defensor, Atacante, Object, PP::ObjectMixin, Kernel, BasicObject]
#    ⚠️ la clase NO sabe nada de las autoclases de sus instancias: ancestors arranca en la clase
```

### 3.2 Linearización de mixins `(P1 §2, P2 §6)`

- Cada clase linealiza **sus** mixins por su cuenta, en orden de `include`: **el último incluido queda más cerca** y gana en conflicto.
- `superclass` **no** muestra mixins (no son clases). `ancestors` muestra el camino completo.
- `Guerrero`: `include Atacante` y después `include Defensor` → `[Guerrero, Defensor, Atacante, ...]`. `Kamikaze` incluye al revés → orden inverso.

### 3.3 Los objetos no tienen métodos `(P4 §2)`

Van a buscarlos a su clase en **cada** envío. Consecuencia: lo que agregás a una clase lo entienden **todas** sus instancias, viejas y nuevas, sin actualizar nada.

### 3.4 Firma = solo el nombre `(P4 §2)`

- Definir un método con un nombre que ya existe **lo reemplaza**. Destructivo: el anterior desaparece.
- Mismo nombre, distinta cantidad de parámetros = **el mismo método**, pisado. No hay sobrecarga.
- **Siempre gana la última definición** en orden de evaluación.

### 3.5 Variables de instancia `(P2 §8)`

- **No se declaran.** Existen desde que alguien las setea; antes de eso, leerlas da `nil`.
- Dos instancias de la misma clase pueden tener distinto conjunto de variables. `instance_variables` responde **qué hay ahora**.
- El nombre incluye el arroba: `:@energia`, nunca `:energia`.

### 3.6 `send` vs `call` `(P2 §11, P3 §2)`

| | Hace lookup | Cuándo |
|---|---|---|
| `obj.mensaje` | sí | sabés el mensaje: usá el punto |
| `obj.send(:mensaje)` | sí | el selector es un **valor** (viene de una lista, un cálculo) |
| `obj.method(:m).call` | **no** | ya tenés el método en la mano; se ejecuta *ese*, aunque el objeto ya no llegue a él por lookup |

- `send` **no respeta `private`**. La privacidad es una sensación, no una protección.

### 3.7 `bind`: hasta dónde `(P3 §5)`

- Método de una **clase** → solo se bindea a instancias de esa clase o de sus subclases. Otra cosa → `TypeError`.
- Método de un **módulo** → se bindea a **cualquier** objeto.

### 3.8 Autoclases `(P6 §3, §5, §6)`

- Se crean **cuando las pedís** (`singleton_class`); antes no existen.
- `#instancia.superclass == su clase` (`#atila → Guerrero`). Entre instancias no hay jerarquía que copiar.
- `#clase.superclass == #superclase` (`#Espadachin → #Guerrero`). Jerarquía paralela: así los métodos de clase se heredan y se redefinen.
- `#BasicObject.superclass == Class`. Toda autoclase es instancia de `Class`.
- `nil.singleton_class == NilClass` (caso especial).

### 3.9 Dónde vive qué `(P5 §4)`

| Vive en | Lo entienden | Ejemplos |
|---|---|---|
| `Object` (vía `Kernel`) | todos los objetos | `class`, `methods`, `is_a?`, `send`, `nil?` |
| `Module` | clases **y** módulos | `attr_accessor`, `define_method`, `instance_methods`, `ancestors` |
| `Class` | solo las clases | `new`, `allocate`, `superclass` |

`Class < Module < Object < BasicObject → nil`. **Una clase es un módulo instanciable.** `Module → Object` significa "los módulos son objetos", no "los módulos son clases".

---

## 4. Caja de herramientas

| Quiero… | Se lo pido a… | Mensaje | Devuelve |
|---|---|---|---|
| la clase de un objeto | el objeto | `class` | la clase (un objeto) |
| saber si es de un tipo (clase, superclase o mixin) | el objeto | `is_a?(Tipo)` | `true`/`false` |
| los mensajes que entiende un objeto | el objeto | `methods` | selectores |
| los métodos que una clase da a sus instancias | la clase/módulo | `instance_methods` / `instance_methods(false)` | selectores (todos / solo los propios) |
| la superclase | la clase | `superclass` | la clase de arriba (`nil` en `BasicObject`) |
| el camino del lookup | la clase/módulo | `ancestors` | linearización |
| saber si algo es mixin | el módulo | `class` | `Module` (compará con `==`, no con `is_a?`) |
| las variables que un objeto tiene ahora | el objeto | `instance_variables` | símbolos con `@` |
| leer / escribir una variable sin getter/setter | el objeto | `instance_variable_get(:@x)` / `instance_variable_set(:@x, v)` | el valor |
| mandar un mensaje cuyo nombre es un valor | el objeto | `send(:sel, args)` | lo que responda |
| el método como objeto, vinculado | el objeto | `method(:sel)` | `Method` |
| el método como objeto, suelto | la clase/módulo | `instance_method(:sel)` | `UnboundMethod` |
| qué parámetros recibe un método | el `Method`/`UnboundMethod` | `parameters` | `[[:req, :x], [:opt, :y], [:rest, :z]]` |
| cuántos parámetros | ídem | `arity` | número (negativo si hay opcionales) |
| quién lo definió | ídem | `owner` | clase o módulo |
| a quién está atado | el `Method` | `receiver` | el objeto |
| ejecutarlo | el `Method` | `call(args)` | lo que responda |
| vincular / desvincular | el `UnboundMethod` / el `Method` | `bind(obj)` / `unbind` | `Method` / `UnboundMethod` |
| definir un método con nombre calculado (para las instancias) | la clase/módulo | `define_method(:sel) { ... }` | el selector |
| definir un método solo para un objeto | el objeto | `define_singleton_method(:sel) { ... }` | el selector |
| la autoclase | cualquier objeto | `singleton_class` | `#<Class:...>` |
| meterle un mixin a un solo objeto | el objeto / su autoclase | `extend M` / `singleton_class.include M` | — |
| accessors para un solo objeto | su autoclase | `singleton_class.attr_accessor :x` | — |
| las subclases directas | la clase | `subclasses` | lista |

---

## 5. Modelo base (`age-clase2.rb`, lo que usa esta unidad) `(P1 §2)`

`Espada`, `Misil`, `Muralla` y `Kamikaze` están en el maestro; no se usan en los casos de abajo.

```ruby
module Atacante                                     # mixin: se incluye, no se instancia
  attr_accessor :potencial_ofensivo, :descansado
  def atacar(un_defensor)
    if self.potencial_ofensivo > un_defensor.potencial_defensivo
      danio = self.potencial_ofensivo - un_defensor.potencial_defensivo
      un_defensor.sufri_danio(danio)
    end
    self.descansado = false
  end
  def potencial_ofensivo
    self.descansado ? @potencial_ofensivo * 2 : @potencial_ofensivo
  end
  def descansar
    self.descansado = true
  end
end

module Defensor
  attr_accessor :potencial_defensivo, :energia
  def sufri_danio(danio)
    self.energia= self.energia - danio               # setter energia=, con el = pegado al nombre
  end
  def descansar
    self.energia += 10
  end
end

class Guerrero
  include Atacante
  alias_method :descansar_atacante, :descansar      # guarda el descansar de Atacante bajo otro nombre
  include Defensor                                  # incluido último → más cerca en el lookup
  alias_method :descansar_defensor, :descansar
  attr_accessor :peloton
  def initialize(potencial_ofensivo=20, energia=100, potencial_defensivo=10)   # defaults 20/100/10
    self.potencial_ofensivo = potencial_ofensivo
    self.energia = energia
    self.potencial_defensivo = potencial_defensivo
  end
  def descansar                                     # redefine para hacer las DOS cosas
    self.descansar_atacante
    self.descansar_defensor
  end
  def lastimado
    self.peloton.lastimado if self.peloton
  end
  def sufri_danio(un_danio)
    super(un_danio)                                 # el de Defensor
    self.lastimado if cansado
  end
  def cansado
    self.energia <= 40
  end
end

class Espadachin < Guerrero
  attr_accessor :espada
  def initialize(espada)
    super(20, 100, 2)
    self.espada= espada
  end
  def potencial_ofensivo
    super() + self.espada.potencial_ofensivo
  end
end

class Peloton                                       # solo lo que importa acá: métodos de clase
  attr_accessor :integrantes, :estrategia, :retirado
  def self.cobarde(integrantes)                     # def self. → lo entiende Peloton, no un pelotón
    self.new(integrantes) { |peloton|
      peloton.retirate
    }
  end
  # ...
end
```

```
   Object ◄──rojo── Guerrero (+ Defensor, Atacante) ◄──rojo── Espadachin
                        ▲ azul                                   ▲ azul
                      atila                                    zorro
```

---

## 6. Casos con código

Cada bloque arranca en **sesión limpia** con `age-clase2.rb` cargado. Los `=>` son lo que responde la consola; los `0x...` cambian por máquina.

### 6.1 Introspection básica `(P2)`

```ruby
atila = Guerrero.new
# => #<Guerrero:0x... @energia=100, @potencial_defensivo=10, @potencial_ofensivo=20>
#    ↑ la lista de @variables muestra qué fue seteado hasta ahora, no una "ficha" de la clase

atila.class                    # => Guerrero        (la clase, un objeto; no el string "Guerrero")
atila.class.class              # => Class
atila.class == Guerrero        # => true

atila.methods                  # => [:descansar_atacante, :descansar_defensor, :peloton, ..., :is_a?, :send, :class, ...]
Guerrero.instance_methods      # => la misma lista  (pregunta distinta: "¿qué das a tus instancias?")
Guerrero.instance_methods(false)
# => [:descansar_atacante, :descansar_defensor, :peloton, :lastimado, :cansado, :sufri_danio, :descansar, :peloton=]
#    solo lo definido en Guerrero: sin energia ni atacar (vienen de los mixins). El orden puede variar.
atila.instance_methods         # NoMethodError ← una instancia no provee métodos a nadie

atila.is_a? Guerrero           # => true
atila.is_a? Atacante           # => true   ← es un atacante (mixin incluido)...
atila.class == Atacante        # => false  ← ...pero su clase no es Atacante
zorro = Espadachin.new(Espada.new(30))
zorro.is_a? Guerrero           # => true
zorro.class == Guerrero        # => false

Espadachin.superclass          # => Guerrero        (saltea los mixins)
Guerrero.ancestors
# => [Guerrero, Defensor, Atacante, Object, PP::ObjectMixin, Kernel, BasicObject]
#     propia   último-incluido primero   super   (Pry)      mixin de Object
Atacante.class                 # => Module
Guerrero.class                 # => Class

atila.instance_variables       # => [:@potencial_ofensivo, :@energia, :@potencial_defensivo]
atila.descansar                # => 110
atila.instance_variables       # => [:@potencial_ofensivo, :@energia, :@potencial_defensivo, :@descansado]
#                                    ↑ apareció al setearse. Un Guerrero.new nuevo NO la tiene.

atila.instance_variable_get(:energia)    # NameError: `energia' is not allowed as an instance variable name
atila.instance_variable_get(:@energia)   # => 110
atila.instance_variable_set(:@energia, 80)   # => 80   ← bypasea el setter
atila.energia                            # => 80

atila.send(:descansar)         # => 90    (igual que atila.descansar)
selector = :descansar
atila.send(selector)           # => 100   ← el selector es un valor
atila.selector                 # NoMethodError: undefined method `selector'  ← eso es el mensaje "selector"
atila.send(:descansr)          # NoMethodError ... Did you mean? descansar   ← send hace lookup normal
```

```ruby
class A
  private
  def metodo_privado
    'cosa privada, no te metas'
  end
end
A.new.metodo_privado           # NoMethodError: private method `metodo_privado' called
A.new.send(:metodo_privado)    # => "cosa privada, no te metas"   ← send se saltea private
```

### 6.2 Qué métodos de un objeto vienen de un mixin (dos formas) `(P2 §7, P3 §2)`

```ruby
# Forma 1: ancestros que son módulos → sus métodos → intersección con lo que atila entiende
mixins = atila.class.ancestors.select { |ancestro| ancestro.class == Module }
# => [Defensor, Atacante, PP::ObjectMixin, Kernel]      ⚠️ == Module, no is_a?: las clases también son Module
metodos_de_mixins = mixins.flat_map { |mixin| mixin.instance_methods(false) }
metodos_de_mixins & atila.methods
# => [:potencial_defensivo, :potencial_defensivo=, :energia, :energia=, :sufri_danio, :descansar,
#     :potencial_ofensivo, ..., :atacar, ..., :class, :methods, :send, :is_a?, ...]
#     ↑ los de Defensor y Atacante, los de Pry, y los de Kernel (ahí viven class, methods, send, is_a?)

# Forma 2: preguntarle a cada método quién lo definió
atila.method(:atacar).owner    # => Atacante
atila.method(:descansar).owner # => Guerrero
atila.method(:class).owner     # => Kernel
```

### 6.3 `Method` y `UnboundMethod` `(P3 §2-4)`

```ruby
atila = Guerrero.new                                  # energía 100
descansar_de_atila = atila.method(:descansar)
# => #<Method: Guerrero#descansar() .../age-clase2.rb:52>
descansar_de_atila.class       # => Method

descansar_de_atila.parameters                 # => []
atila.method(:sufri_danio).parameters         # => [[:req, :un_danio]]
atila.method(:initialize).parameters
# => [[:opt, :potencial_ofensivo], [:opt, :energia], [:opt, :potencial_defensivo]]   (tienen default)
atila.method(:sufri_danio).arity              # => 1
atila.method(:initialize).arity               # => -1   ← negativo: hay opcionales; usá parameters
descansar_de_atila.owner                      # => Guerrero
descansar_de_atila.receiver                   # => #<Guerrero:0x... @energia=100, ...>  (atila)

descansar_de_atila.call                       # => 110    ← ejecuta SIN lookup
atila.method(:sufri_danio).call(30)           # => nil    (su última línea es un if que no se cumplió; el daño se aplicó)
atila.method(:energia).call                   # => 80

descansar_de_guerrero = Guerrero.instance_method(:descansar)
# => #<UnboundMethod: Guerrero#descansar() .../age-clase2.rb:52>
descansar_de_guerrero.call                    # NoMethodError: undefined method `call'  ← no sabe sobre quién
descansar_de_guerrero.parameters              # => []
descansar_de_guerrero.owner                   # => Guerrero
descansar_de_guerrero.receiver                # NoMethodError

descansar_de_guerrero.bind(atila)             # => #<Method: Guerrero#descansar() ...>   ← Method nuevo
descansar_de_guerrero.bind(atila).call        # => 90
descansar_de_atila.unbind                     # => #<UnboundMethod: Guerrero#descansar() ...>
descansar_de_atila.call                       # => 100   ← unbind no rompió nada: bind/unbind no tienen efecto
```

Ejecutar un método donde el lookup **no** llegaría:

```ruby
class Padre
  def correr
    'correr como padre'
  end
end

class Hijo < Padre
  def correr                              # Hijo redefine correr
    'correr como hijo'
  end
end

h = Hijo.new
h.correr                                      # => "correr como hijo"      lookup normal
Padre.instance_method(:correr).bind(h).call   # => "correr como padre"     ese método, en ese objeto, sin lookup
```

### 6.4 Límite de `bind` `(P3 §5)`

```ruby
class Zanahoria
  def color
    'naranja'
  end
end
Zanahoria.instance_method(:color).bind(atila)
# TypeError: bind argument must be an instance of Zanahoria   ← misma jerarquía o nada

module Colorido
  def color
    'naranja'
  end
end
Colorido.instance_method(:color).bind(atila).call   # => "naranja"   ← método de módulo: se bindea a cualquiera
```

### 6.5 Open classes `(P4 §2-3)`

```ruby
atila = Guerrero.new; conan = Guerrero.new           # ambos con energía 100

class String                    # String ya existe: la ABRÍS
  def importante
    self + '!'
  end
end
'aprobe'.importante             # => "aprobe!"     todos los strings lo entienden ahora

class Guerrero                  # reabrir Guerrero
  def comete_un_pollo
    self.energia += 100
  end
end
conan.comete_un_pollo           # => 200   ← conan existía de antes y lo entiende: los objetos no guardan métodos

class Guerrero
  def descansar                 # YA EXISTE → lo pisa. El descansar atacante+defensor desapareció.
    self.energia += 1000
  end
end
atila.descansar                 # => 1100

class Guerrero
  def descansar(cuanto)         # mismo nombre, un parámetro → MISMO método, pisado otra vez
    self.energia += cuanto
  end
end
atila.descansar                 # ArgumentError: wrong number of arguments (given 0, expected 1)
atila.descansar(5)              # => 1105
```

```ruby
2.class                         # => Integer
class Integer
  def +(otro)                   # + es un método común
    123
  end
end
2 + 2                           # => 123   ← y la consola se murió: Pry suma para funcionar. exit.
```

### 6.6 `define_method` `(P4 §4)`

```ruby
# misma sesión que las clases abiertas de 6.5 (antes de romper Integer): conan está en 200

Guerrero.define_method(:comete_una_pata_de_pollo) {  # selector como VALOR + bloque como cuerpo
  self.energia += 50
}
# => :comete_una_pata_de_pollo
conan.comete_una_pata_de_pollo  # => 250

comida = "milanesa"
Guerrero.define_method("comete_una_#{comida}".to_sym) {   # nombre ARMADO: imposible con def
  self.energia += 10
}
conan.comete_una_milanesa       # => 260

bonus = 30                                          # variable local de AFUERA
Guerrero.define_method(:comete_bonus) {
  self.energia += bonus                             # el bloque la ve: retiene el contexto donde nació
}
conan.comete_bonus              # => 290            (con def, bonus no sería visible)
```

### 6.7 `attr_accessor` programado a mano `(P4 §5)`

El patrón completo: método de clase + nombre armado + `define_method` + `instance_variable_get/set` + bloque que retiene contexto.

```ruby
class Guerrero
  def self.mi_attr_accessor(attr)                # lo entiende Guerrero: se usa en el cuerpo de la clase
    nombre = "@#{attr}".to_sym                   # :apodo → :@apodo   (⚠️ sin el @ → NameError)

    define_method(attr) {                        # getter: se llama :apodo
      instance_variable_get(nombre)              # nombre viene del contexto de afuera
    }

    define_method("#{attr}=".to_sym) { |value|   # setter: se llama :apodo=, recibe el valor
      instance_variable_set(nombre, value)
    }
  end

  mi_attr_accessor :apodo                        # se usa igual que attr_accessor
end

atila.apodo = 'el huno'         # => "el huno"
atila.apodo                     # => "el huno"
atila.instance_variables        # => [..., :@apodo]   ← la variable apareció al setearla
```

⚠️ Esta versión solo la entiende `Guerrero`. Para que la entiendan **todas** las clases y módulos va en `Module` (§3.9).

### 6.8 El metamodelo, verificable en consola `(P5)`

| Consulta | Responde | Qué te dice |
|---|---|---|
| `Guerrero.class` | `Class` | toda clase es instancia de `Class` |
| `Class.instance_methods(false)` | `[:allocate, :superclass, :subclasses, :attached_object, :new]` | `new` vive en `Class` |
| `Object.superclass` | `BasicObject` | hay una clase arriba de `Object` |
| `BasicObject.instance_methods(false)` | 8 métodos (`:!`, `:==`, `:__send__`, `:equal?`, `:instance_eval`, `:instance_exec`…) | esqueleto mínimo, sin `class` |
| `BasicObject.superclass` | `nil` | punto de corte del lookup |
| `nil.class` / `NilClass.superclass` | `NilClass` / `Object` | `nil` es un objeto, no un proveedor |
| `Class.superclass` | `Module` | una clase es un módulo instanciable |
| `Module.instance_methods(false).include?(:attr_accessor)` | `true` | `attr_accessor`, `define_method` viven en `Module` |
| `Module.instance_methods(false).include?(:new)` | `false` | los módulos no se instancian |
| `Module.superclass` | `Object` | los módulos son objetos |
| `Object.class`, `Module.class`, `Class.class` | `Class`, `Class`, `Class` | `Class` es instancia de sí misma |
| `atila.new` | `NoMethodError` | `atila` nunca pasa por `Class` |
| `2.class` / `Integer.superclass` | `Integer` / `Numeric` | los números se cablean igual |

Por qué el ciclo `BasicObject → nil → NilClass → Object → BasicObject` no es un loop: después del primer paso (verde/azul) solo hay pasos rojos, y `nil` no tiene flecha roja. Ídem `Class.class == Class`: un solo paso a sí misma, después `Module`, `Object`, `BasicObject`, `nil`.

### 6.9 Autoclases `(P6 §4-6)`

```ruby
atila = Guerrero.new; conan = Guerrero.new; zorro = Espadachin.new(Espada.new(30))

# --- métodos de clase: def self. define en la autoclase de la clase ---
class Guerrero
  def self.crear_vikingo
    self.new(70)                # self es Guerrero
  end
  def self.gritar
    'haaaa'
  end
end
Guerrero.crear_vikingo          # => #<Guerrero:0x... @energia=100, @potencial_defensivo=10, @potencial_ofensivo=70>
Guerrero.gritar                 # => "haaaa"
atila.gritar                    # NoMethodError   ← no es para las instancias

Guerrero.methods.include?(:gritar)                 # => true   Guerrero lo entiende
Guerrero.instance_methods.include?(:gritar)        # => false  no está en Guerrero
Guerrero.class.instance_methods.include?(:gritar)  # => false  no está en Class
Guerrero.singleton_class                            # => #<Class:Guerrero>
Guerrero.singleton_class.instance_methods(false)    # => [:crear_vikingo, :gritar]   ← acá vive

Guerrero.define_singleton_method(:gritar_fuerte) { 'HAAAA' }          # el atajo
Guerrero.singleton_class.define_method(:gritar_fuerte) { 'HAAAA' }    # lo que hace por atrás
Guerrero.gritar_fuerte          # => "HAAAA"

# --- se heredan: jerarquía paralela ---
Espadachin.gritar               # => "haaaa"   ← lo encontró en #Guerrero
Guerrero.singleton_class.superclass      # => #<Class:Object>       (no Class)
Espadachin.singleton_class.superclass    # => #<Class:Guerrero>
Object.singleton_class.superclass        # => #<Class:BasicObject>
BasicObject.singleton_class.superclass   # => Class
Class.singleton_class.superclass         # => #<Class:Module>
Module.singleton_class.superclass        # => #<Class:Object>
Guerrero.singleton_class.instance_methods.include?(:new)   # => true  (le llega por #Object, #BasicObject, Class)

# --- comportamiento para UN objeto ---
atila.singleton_class                    # => #<Class:#<Guerrero:0x...>>
atila.singleton_class == conan.singleton_class   # => false

atila.define_singleton_method(:saludar) { 'hola, soy atila' }
atila.saludar                   # => "hola, soy atila"
conan.saludar                   # NoMethodError   ← conan no lo tiene
atila.singleton_class.instance_methods(false)    # => [:saludar]
atila.singleton_class.superclass         # => Guerrero      ← la autoclase de una instancia hereda de SU CLASE
zorro.singleton_class.superclass         # => Espadachin

module Presentable
  def presentarse
    'un gusto'
  end
end
atila.singleton_class.include Presentable   # mixin en la autoclase
atila.presentarse               # => "un gusto"
conan.extend Presentable                    # extend = "incluí esto en mi autoclase"
conan.presentarse               # => "un gusto"
zorro.presentarse               # NoMethodError

atila.singleton_class.attr_accessor :edad   # accessors solo para atila
atila.edad = 40
atila.edad                      # => 40
zorro.edad                      # NoMethodError

nil.singleton_class             # => NilClass    (caso especial)
```

---

## 7. Tabla de decisión

| Quiero que… | Hago… |
|---|---|
| **todas las instancias** de una clase entiendan `x` | `def x` en la clase (abriéndola si ya existe) o `Clase.define_method(:x) { }` |
| **un solo objeto** entienda `x` | `obj.define_singleton_method(:x) { }` · o `obj.singleton_class.define_method(:x) { }` |
| un solo objeto tenga un mixin | `obj.extend M` · o `obj.singleton_class.include M` |
| un solo objeto tenga accessors | `obj.singleton_class.attr_accessor :x` |
| **la clase** (y sus subclases) entienda `x` | `def self.x` en el cuerpo · o `Clase.define_singleton_method(:x) { }` |
| **todas las clases y módulos** entiendan `x` | abrir `Module` y definirlo ahí |
| **solo las clases** (no los módulos) | abrir `Class` |
| **todos los objetos** | abrir `Object` (o un mixin incluido en `Object`) |
| el **nombre** del método salga de un valor | `define_method("prefijo_#{x}".to_sym) { }` · setter: `"#{x}=".to_sym` |
| el cuerpo use un dato calculado antes | calcularlo en una variable local y usarla adentro del bloque (la retiene) |
| mandar un mensaje cuyo nombre es un valor | `obj.send(selector, args)` |
| ejecutar *ese* método sin lookup (p. ej. el de la superclase) | `Clase.instance_method(:x).bind(obj).call` — `obj` en la jerarquía de `Clase`, o el método en un módulo |
| leer/escribir estado de un objeto que no da getter/setter | `instance_variable_get(:@x)` / `instance_variable_set(:@x, v)` — solo si tu dominio son programas |
| saber **de dónde** viene un método | `obj.method(:x).owner` · o `Clase.ancestors` |
| saber qué método vino de un mixin | `owner.class == Module` |
| saber si un objeto es "de un tipo" | `is_a?` (incluye mixins y superclases), no `class ==` |
| saber qué **entiende** una clase como objeto | `Clase.methods` · `Clase.singleton_class.instance_methods(false)` |
| ver el lookup completo de un objeto, incluida su autoclase | `obj.singleton_class.ancestors` |
| que un método de clase se herede y admita `super` | nada extra: `def self.` ya vive en la jerarquía paralela |
| sacar un método | ⚠️ todavía no tenés la herramienta: es de la clase 4 |

**Cuándo metaprogramar** `(P6 §9)`:

| Situación | Hacés |
|---|---|
| Sabés qué mensaje querés mandar | `obj.mensaje`. Con el punto. Polimorfismo, no `send`. |
| Querés distinto comportamiento según la clase del objeto | polimorfismo (un método por clase), **no** `if obj.class == ...` |
| Escribís código para clases/métodos que **no conocés** todavía (framework, herramienta) | reflection: `methods`, `send`, `define_method`, `instance_variable_*` |
| Necesitás lógica en **un** objeto y ya es instancia de algo | autoclase; no una clase nueva |
| Dudás | quedate en introspection; cruzá a modificar solo si no queda otra |

---

## 8. Errores comunes

1. **`energia = 5` adentro de un método.** Crea una variable local; el atributo no cambia. **Silencio total.** Setter siempre con `self.`. `(P2 §9)`
2. **Typo en un getter sin `self.`** (`enrgia`). Ruby inventa una variable local `nil`; el error explota lejos. `(P2 §9)`
3. **`instance_variable_get(:energia)`.** `NameError: 'energia' is not allowed as an instance variable name`. El símbolo lleva `@`: `:@energia`. Cuando armás el nombre: `"@#{attr}".to_sym`. `(P2 §10, P4 §5)`
4. **`atila.instance_methods` / `atila.ancestors`.** `NoMethodError`: se le preguntan a la clase o al módulo, no a la instancia. `(P2 §4, §6)`
5. **`atila.selector`** creyendo que usa la variable. Mandaste el mensaje literal `selector` → `NoMethodError`. Es `atila.send(selector)`. `(P2 §11)`
6. **Definir `atacar(a, b)` donde ya había `atacar(a)`** esperando sobrecarga. Lo pisó: el de un parámetro ya no existe → `ArgumentError: wrong number of arguments`. `(P4 §2)`
7. **Redefinir un método sin querer** (mismo nombre en un `class X` reabierto, o dos `def` iguales en el archivo). Gana el último, en silencio. `(P4 §2)`
8. **Abrir `Integer`, `Kernel`, `Object`** para probar. Pry corre adentro de tu Ruby: la consola muere. `exit`. `(P4 §3)`
9. **`UnboundMethod#call`.** `NoMethodError`: no sabe sobre quién. `bind(obj)` primero. `(P3 §3)`
10. **`bind` a un objeto fuera de la jerarquía del dueño.** `TypeError: bind argument must be an instance of X`. Salvo que el método viva en un módulo. `(P3 §5)`
11. **`def` cuando querías método de clase** (`Guerrero.gritar` → `NoMethodError`) o **`def self.` cuando querías método de instancia** (`atila.gritar` → `NoMethodError`). `(P6 §4)`
12. **Buscar en `Clase.ancestors` un método que "no aparece"** y sí se ejecuta. Vive en la autoclase de la instancia; `ancestors` de la clase no la muestra. Pedí `obj.singleton_class.ancestors`. `(P6 §6, §8)`
13. **Detectar mixins con `is_a?(Module)`.** Las clases también dan `true` (`Class < Module`). Compará `x.class == Module`. `(P2 §7, P5 §4)`
14. **Poner `mi_attr_accessor` (o cualquier mensaje "para todas las clases") en una clase concreta.** Solo la entiende esa clase. Para todas: `Module`. `(P4 §5, P5 §4)`
15. **Confiar en `private` como protección.** `send` lo saltea. `(P2 §11)`
16. **`Fixnum` de material viejo.** No existe en Ruby 3: `Integer`. `(P0 §2)`
17. **Editar el archivo con Pry abierto** y no ver el cambio. `require_relative` carga una vez por sesión. `exit`, entrar, cargar. `(P0 §6)`
18. **Guardarte una respuesta de introspection** (`methods`, `instance_variables`) como si fuera fija. Es la respuesta **ahora**; una open class o un setter la cambian. `(P2 §8)`

---

## 9. Checklist antes de entregar (de la técnica, no del enunciado)

- [ ] Por cada `def self.x` o `define_singleton_method` en una clase: `Clase.singleton_class.instance_methods(false)` lo lista y `Clase.instance_methods(false)` **no**.
- [ ] Por cada método que tiene que entender **una instancia**: está en `Clase.instance_methods(false)` (o en un mixin de `Clase.ancestors`), no en la autoclase de la clase.
- [ ] Por cada clase con más de un `include`: corrí `Clase.ancestors` y el orden es el que quería (el último `include` gana).
- [ ] Por cada `define_method` con nombre armado: el símbolo resultante aparece en `instance_methods(false)`; si es setter, termina en `=`.
- [ ] Por cada `instance_variable_get/set`: el símbolo empieza con `@` (y si lo armo, `"@#{x}".to_sym`).
- [ ] Ninguna asignación a un accessor sin `self.` adentro de un método (busqué `nombre_de_accessor =` sin `self.`).
- [ ] Cada método que agrego a una clase que **ya tiene** ese nombre es un pisado **intencional** (`Clase.instance_methods.include?(:x)` antes de definirlo).
- [ ] Si abrí `Object`, `Module` o `Class`: verifiqué que era el nivel correcto (§3.9) y no metí algo de dominio en un lugar que lo entiende todo el mundo.
- [ ] Por cada `send` / `instance_variable_get` / `instance_variable_set` / `define_method`: **no sabía el mensaje de antemano**. Si lo sabía, es un punto o un `def`.
- [ ] Por cada `bind`: el receptor está en la jerarquía del `owner`, o el método vive en un módulo.
- [ ] Todo probado en una **sesión limpia** de Pry (`exit` → `pry` → `require_relative`) después del último cambio en el archivo, no en la sesión donde fui pisando cosas.

---

**FIN DEL APUNTE CORE-MACHETE — Clase 03: Metaprogramación en Ruby**
