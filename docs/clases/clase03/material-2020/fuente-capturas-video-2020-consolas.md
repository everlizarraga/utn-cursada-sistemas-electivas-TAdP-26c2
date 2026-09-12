# Capturas de consola — video 2020 (sesión de pry sobre `age-clase2.rb`)

> Conversión fiel a Markdown de capturas-video-2020-consolas.pptx (26 slides | 26 capturas de pantalla, sin texto nativo).

## Notas de conversión

- **Formato de origen fuera del alcance nominal de la conversión (PDF):** el `.pptx` no contiene texto, solo una imagen PNG por slide (capturas de pantalla de una terminal Linux con `pry`, más una del editor VS Code). Toda la transcripción se hizo por lectura visual de las 26 imágenes a resolución completa.
- **Dos sesiones de consola:** la primera sesión de `pry` (slides 1–11) termina con la consola rota tras redefinir `Integer#+`, `exit` y `clear`; la segunda (slides 12–26) arranca con un `pry` nuevo y la numeración de prompts vuelve a `[1]`. El archivo se divide en dos partes por ese hecho, visible en el material.
- **Formato de los bloques:** cada captura de terminal se transcribe en un bloque de código con lenguaje `ruby` (los prompts de pry no son Ruby puro, pero es el resaltado más útil disponible), conservando los prompts de pry (`[N] pry(main)>` / `[N] pry(main)*`) y las salidas (`=> ...`). Las líneas del shell (`ernesto@aldebaran:...$`) van en el mismo bloque, tal como aparecen. La barra de título de la terminal dice `ernesto@aldebaran: ~/tadp/tadp-clases/src 114x30` en todas las capturas que la incluyen.
- **Títulos de slide:** las capturas no tienen título; los `### Slide N — ...` son etiquetas descriptivas asignadas en la conversión, tomadas del contenido visible.
- **Slides compuestos por varios recortes** (2, 3, 11, 20, 21): el autor de las capturas pegó dos o tres recortes de la misma terminal en un slide. Se transcribe cada recorte por separado, en orden de lectura (izquierda→derecha / arriba→abajo). Algunos recortes se solapan (repiten líneas del anterior) y se transcriben tal cual.
- **Cortes de línea por ancho de terminal:** las salidas largas de `#<Method: ...>` (slides 5 y 6) aparecen partidas por el ancho de 114 columnas (`@descans` / `ado=true`); se unieron en una sola línea. Los saltos que sí son de pry (pretty-print con sangría, slide 16 `[39]`) se conservan.
- **Salidas truncadas en el origen:** varias listas de `methods` / `instance_methods` se ven a través del paginador de pry (prompt `:` al pie) o entran a la captura ya empezadas. Se transcribe solo lo visible; el principio o el final de esas listas no está en el material (slides 2, 3, 17, 18, 19, 20, 21).
- **Errores del original transcriptos tal cual:** `a.metodo_pivado` (slide 5, `[26]`, tipeo por `metodo_privado`); `Esucadron.singleton_class` (slide 22, `[64]`, tipeo por `Escuadron`); en slide 13 `[9]` quedó registrada una autocompletación con TAB (`Object.class.is_` → sugerencias) antes del comando definitivo; en slide 10 `[93]` un `marine.energia=` sin argumento seguido de `class Guerrero ... end` produce el `ArgumentError`.
- **Slide 15 (VS Code):** las líneas 150 y 154 del archivo se ven cortadas por el borde derecho de la captura (`... !i.is_a? Guer` y `... !i.is_a? Ataca`). Se transcriben hasta donde se ven, con la marca `# ← recortado en la captura`; no se completó el resto.
- **Slide 19:** la última línea de la captura está cortada por el borde inferior (solo se ve el borde superior de los caracteres); no se transcribe.
- **Slide 11:** los dos recortes muestran la misma zona en momentos distintos y difieren: el izquierdo muestra `=> 2` tras los dos `2 + 2`; el derecho no lo muestra y agrega `2 + 4444`, prompts vacíos, `exit` y `clear`. Se transcriben ambos.
- **Hipervínculos:** se revisaron las relaciones de los 26 slides; no hay hipervínculos (solo referencias a imágenes). El slide 17 tiene un campo de notas del orador vacío.
- Peso: 33,5 MB (`.pptx`) → este archivo.

---

## Parte 1 — Primera sesión de pry (slides 1–11)

### Slide 1 — Inicio de pry, `require_relative`, `Guerrero`, clases `A` y `B`

```ruby
ernesto@aldebaran:~$ cd tadp/tadp-clases/
ernesto@aldebaran:~/tadp/tadp-clases$ cd src/
ernesto@aldebaran:~/tadp/tadp-clases/src$ ls
age-clase2.rb  age.rb
ernesto@aldebaran:~/tadp/tadp-clases/src$ pry
[1] pry(main)> require_relative 'age-clase2.rb'
=> true
[2] pry(main)> marine = Guerrero.new
=> #<Guerrero:0x0000559106bcff38 @energia=100, @potencial_defensivo=10, @potencial_ofensivo=20>
[3] pry(main)> marine.class
=> Guerrero
[4] pry(main)> marine.class
=> Guerrero
[5] pry(main)> marine.class.superclass
=> Object
[6] pry(main)> class A
[6] pry(main)* end
=> nil
[7] pry(main)> class B < A
[7] pry(main)* end
=> nil
[8] pry(main)> b = B.new
=> #<B:0x00005591064d56d8>
[9] pry(main)> b.class
=> B
[10] pry(main)> b.class.superclass
=> A
[11] pry(main)> marine
=> #<Guerrero:0x0000559106bcff38 @energia=100, @potencial_defensivo=10, @potencial_ofensivo=20>
[12] pry(main)> marine.methods
```

### Slide 2 — Salida de `marine.methods`; `marine.descansar`

*(Slide compuesto por dos recortes de la misma terminal, uno al lado del otro. El primero termina en el prompt `:` del paginador; el segundo continúa la misma lista.)*

Recorte 1:

```ruby
=> [:descansar_atacante,
 :descansar_defensor,
 :peloton,
 :lastimado,
 :cansado,
 :sufri_danio,
 :descansar,
 :peloton=,
 :energia=,
 :potencial_defensivo=,
 :energia,
 :potencial_defensivo,
 :descansado=,
 :potencial_ofensivo,
 :potencial_ofensivo=,
 :descansado,
 :atacar,
 :pry,
 :__binding__,
 :pretty_print_inspect,
 :pretty_print_cycle,
 :pretty_print,
 :pretty_print_instance_variables,
 :instance_variable_defined?,
 :remove_instance_variable,
 :instance_of?,
 :kind_of?,
 :is_a?,
 :tap,
:
```

Recorte 2:

```ruby
 :inspect,
 :object_id,
 :send,
 :to_s,
 :display,
 :nil?,
 :hash,
 :class,
 :singleton_class,
 :clone,
 :dup,
 :itself,
 :yield_self,
 :then,
 :taint,
 :tainted?,
 :untaint,
 :untrust,
 :untrusted?,
 :trust,
 :frozen?,
 :methods,
 :singleton_methods,
 :equal?,
 :!,
[13] pry(main)> marine.descansar
=> 110
[14] pry(main)> marine.energia
=> 110
[15] pry(main)>
```

### Slide 3 — `marine.class.instance_methods`

*(Slide compuesto por tres recortes. El primero es el prompt; el segundo es el comienzo de la salida hasta el paginador; el tercero es una posición más avanzada de la misma lista y repite sus primeras cuatro líneas.)*

Recorte 1:

```ruby
 :!,
[13] pry(main)> marine.descansar
=> 110
[14] pry(main)> marine.energia
=> 110
[15] pry(main)> marine.class
=> Guerrero
[16] pry(main)> marine.class.instance_methods
```

Recorte 2:

```ruby
=> [:descansar_atacante,
 :descansar_defensor,
 :peloton,
 :lastimado,
 :cansado,
 :sufri_danio,
 :descansar,
 :peloton=,
 :energia=,
 :potencial_defensivo=,
 :energia,
 :potencial_defensivo,
 :descansado=,
 :potencial_ofensivo,
 :potencial_ofensivo=,
 :descansado,
 :atacar,
 :pry,
 :__binding__,
 :pretty_print_inspect,
 :pretty_print_cycle,
 :pretty_print,
 :pretty_print_instance_variables,
 :instance_variable_defined?,
 :remove_instance_variable,
 :instance_of?,
 :kind_of?,
 :is_a?,
 :tap,
:
```

Recorte 3:

```ruby
 :instance_of?,
 :kind_of?,
 :is_a?,
 :tap,
 :instance_variable_set,
 :protected_methods,
 :instance_variables,
 :instance_variable_get,
 :private_methods,
 :public_methods,
 :public_send,
 :method,
 :public_method,
 :singleton_method,
 :define_singleton_method,
 :extend,
 :to_enum,
 :enum_for,
 :pretty_inspect,
 :<=>,
 :===,
 :=~,
 :!~,
 :eql?,
 :respond_to?,
 :freeze,
 :inspect,
 :object_id,
 :send,
[17] pry(main)>
```

### Slide 4 — `instance_methods(false)`, `send`, clase `A` con método privado

```ruby
 :object_id,
 :send,
[17] pry(main)> marine.class.instance_methods(false)
=> [:descansar_atacante, :descansar_defensor, :peloton, :lastimado, :cansado, :sufri_danio, :descansar, :peloton=]
[18] pry(main)> marine.descansar
=> 120
[19] pry(main)> marine.send(:descansar)
=> 130
[20] pry(main)> sym = :descansar
=> :descansar
[21] pry(main)> marine.send(sym)
=> 140
[22] pry(main)> class A
[22] pry(main)*   def bleh
[22] pry(main)*     2
[22] pry(main)*   end
[22] pry(main)*
[22] pry(main)*   private
[22] pry(main)*   def metodo_privado
[22] pry(main)*     'estamos en un metodo privado'
[22] pry(main)*   end
[22] pry(main)* end
=> :metodo_privado
[23] pry(main)> A.new
=> #<A:0x0000559106b75e70>
[24] pry(main)> a = A.new
=> #<A:0x0000559106ba84b0>
[25] pry(main)> a.bleh
=> 2
[26] pry(main)>
```

### Slide 5 — `send` a método privado, `method(:descansar)`, `call`, `parameters`

```ruby
[26] pry(main)> a.metodo_pivado
NoMethodError: undefined method `metodo_pivado' for #<A:0x0000559106ba84b0>
from (pry):37:in `__pry__'
[27] pry(main)> a.send(:bleh)
=> 2
[28] pry(main)> a.send(:metodo_privado)
=> "estamos en un metodo privado"
[29] pry(main)> a.metodo_privado
NoMethodError: private method `metodo_privado' called for #<A:0x0000559106ba84b0>
from (pry):40:in `__pry__'
[30] pry(main)> marine.class.instance_methods false
=> [:descansar_atacante, :descansar_defensor, :peloton, :lastimado, :cansado, :sufri_danio, :descansar, :peloton=]
[31] pry(main)> marine.method(:descansar)
=> #<Method: #<Guerrero:0x0000559106bcff38 @potencial_ofensivo=20, @energia=140, @potencial_defensivo=10, @descansado=true>.descansar>
[32] pry(main)> marine
=> #<Guerrero:0x0000559106bcff38 @descansado=true, @energia=140, @potencial_defensivo=10, @potencial_ofensivo=20>
[33] pry(main)> metodo_descansar_marine = marine.method(:descansar)
=> #<Method: #<Guerrero:0x0000559106bcff38 @potencial_ofensivo=20, @energia=140, @potencial_defensivo=10, @descansado=true>.descansar>
[34] pry(main)> metodo_descansar_marine.call
=> 150
[35] pry(main)> metodo_descansar_marine.parameters
=> []
[36] pry(main)> marine.method(:recibi_danio)
NameError: undefined method `recibi_danio' for class `#<Class:#<Guerrero:0x0000559106bcff38>>'
from (pry):47:in `method'
[37] pry(main)>
```

### Slide 6 — `method(:sufri_danio)`: `parameters`, `arity`, `receiver`; `instance_method` (UnboundMethod)

```ruby
[37] pry(main)> marine.method(:sufri_danio)
=> #<Method: #<Guerrero:0x0000559106bcff38 @potencial_ofensivo=20, @energia=150, @potencial_defensivo=10, @descansado=true>.sufri_danio>
[38] pry(main)> marine.method(:sufri_danio).parameters
=> [[:req, :un_danio]]
[39] pry(main)> marine.method(:sufri_danio).arity
=> 1
[40] pry(main)> marine.method(:sufri_danio).receiver
=> #<Guerrero:0x0000559106bcff38 @descansado=true, @energia=150, @potencial_defensivo=10, @potencial_ofensivo=20>
[41] pry(main)> marine.method(:sufri_danio).receiver == marine
=> true
[42] pry(main)> marine.class
=> Guerrero
[43] pry(main)> marine.class.instance_methods false
=> [:descansar_atacante, :descansar_defensor, :peloton, :lastimado, :cansado, :sufri_danio, :descansar, :peloton=]
[44] pry(main)> marine.class.instance_method :descansar
=> #<UnboundMethod: Guerrero#descansar>
[45] pry(main)> metodo_descansar = marine.class.instance_method :descansar
=> #<UnboundMethod: Guerrero#descansar>
[46] pry(main)> metodo_descansar.parameters
=> []
[47] pry(main)> metodo_descansar.arity
=> 0
[48] pry(main)> metodo_descansar.receiver
NoMethodError: undefined method `receiver' for #<UnboundMethod: Guerrero#descansar>
from (pry):59:in `__pry__'
[49] pry(main)> metodo_descansar.call
NoMethodError: undefined method `call' for #<UnboundMethod: Guerrero#descansar>
from (pry):60:in `__pry__'
[50] pry(main)>
```

### Slide 7 — `bind`, `owner`, métodos heredados de `Atacante`

```ruby
[50] pry(main)> metodo_descansar.bind(marine)
=> #<Method: Guerrero#descansar>
[51] pry(main)> metodo_descansar.bind(marine).receiver
=> #<Guerrero:0x0000559106bcff38 @descansado=true, @energia=150, @potencial_defensivo=10, @potencial_ofensivo=20>
[52] pry(main)> metodo_descansar.bind(marine).receiver == marine
=> true
[53] pry(main)> A
=> A
[54] pry(main)> a
=> #<A:0x0000559106ba84b0>
[55] pry(main)> metodo_descansar.bind(a)
TypeError: bind argument must be an instance of Guerrero
from (pry):66:in `bind'
[56] pry(main)> metodo_descansar
=> #<UnboundMethod: Guerrero#descansar>
[57] pry(main)> metodo_descansar.owner
=> Guerrero
[58] pry(main)> marine.class.instance_methods false
=> [:descansar_atacante, :descansar_defensor, :peloton, :lastimado, :cansado, :sufri_danio, :descansar, :peloton=]
[59] pry(main)> marine.class.instance_method :descansar_atacante
=> #<UnboundMethod: Guerrero(Atacante)#descansar_atacante(descansar)>
[60] pry(main)> unboundm = marine.class.instance_method :descansar_atacante
=> #<UnboundMethod: Guerrero(Atacante)#descansar_atacante(descansar)>
[61] pry(main)> unboundm.owner
=> Guerrero
[62] pry(main)> unboundm.parameters
=> []
[63] pry(main)> marine.class.instance_method :atacar
=> #<UnboundMethod: Guerrero(Atacante)#atacar>
[64] pry(main)>
```

### Slide 8 — `owner` de `atacar`, `Espadachin`, `ancestors`, variables de instancia

```ruby
[64] pry(main)> matacar = marine.class.instance_method :atacar
=> #<UnboundMethod: Guerrero(Atacante)#atacar>
[65] pry(main)> matacar.owner
=> Atacante
[66] pry(main)> Espadachin
=> Espadachin
[67] pry(main)> Espadachin.superclass
=> Guerrero
[68] pry(main)> Espadachin.superclass.superclass
=> Object
[69] pry(main)> Espadachin.ancestors
=> [Espadachin, Guerrero, Defensor, Atacante, Object, PP::ObjectMixin, Kernel, BasicObject]
[70] pry(main)> marine
=> #<Guerrero:0x0000559106bcff38 @descansado=true, @energia=150, @potencial_defensivo=10, @potencial_ofensivo=20>
[71] pry(main)> marine.instance_variables
=> [:@potencial_ofensivo, :@energia, :@potencial_defensivo, :@descansado]
[72] pry(main)> marine.instance_variable_get(:energia)
NameError: `energia' is not allowed as an instance variable name
from (pry):83:in `instance_variable_get'
[73] pry(main)> marine.instance_variable_get(:@energia)
=> 150
[74] pry(main)> marine.instance_variable_set(:@energia, 20)
=> 20
[75] pry(main)> marine
=> #<Guerrero:0x0000559106bcff38 @descansado=true, @energia=20, @potencial_defensivo=10, @potencial_ofensivo=20>
[76] pry(main)> marine.instance_variable_get(:@energia)
=> 20
[77] pry(main)>
[78] pry(main)>
[79] pry(main)>
```

### Slide 9 — Reabrir `class Guerrero`: agregar `blah`, redefinir `energia`

```ruby
[78] pry(main)>
[79] pry(main)> Guerrero
=> Guerrero
[80] pry(main)> class Guerrero
[80] pry(main)*   def blah
[80] pry(main)*     2
[80] pry(main)*   end
[80] pry(main)* end
=> :blah
[81] pry(main)> s = Guerrero.new
=> #<Guerrero:0x0000559106bfa198 @energia=100, @potencial_defensivo=10, @potencial_ofensivo=20>
[82] pry(main)> s.energia
=> 100
[83] pry(main)> s.blah
=> 2
[84] pry(main)> marine
=> #<Guerrero:0x0000559106bcff38 @descansado=true, @energia=20, @potencial_defensivo=10, @potencial_ofensivo=20>
[85] pry(main)> marine.blah
=> 2
[86] pry(main)> class Guerrero
[86] pry(main)*   def energia
[86] pry(main)*     34
[86] pry(main)*   end
[86] pry(main)* end
=> :energia
[87] pry(main)> class Guerrero
[87] pry(main)*   def energia
[87] pry(main)*     42
[87] pry(main)*   end
[87] pry(main)* end
=> :energia
[88] pry(main)>
```

### Slide 10 — Redefinir `energia=` sin parámetro; `ArgumentError`

```ruby
=> :energia
[88] pry(main)> marine
=> #<Guerrero:0x0000559106bcff38 @descansado=true, @energia=20, @potencial_defensivo=10, @potencial_ofensivo=20>
[89] pry(main)> marine.energia
=> 42
[90] pry(main)> class Guerrero
[90] pry(main)*   def energia=
[90] pry(main)*     41
[90] pry(main)*   end
[90] pry(main)* end
=> :energia=
[91] pry(main)> marine.energia= 30
ArgumentError: wrong number of arguments (given 1, expected 0)
from (pry):112:in `energia='
[92] pry(main)> class Guerrero
[92] pry(main)*   def energia=
[92] pry(main)*     43
[92] pry(main)*   end
[92] pry(main)*   def energia=
[92] pry(main)*     40
[92] pry(main)*   end
[92] pry(main)* end
=> :energia=
[93] pry(main)> marine.energia=
[93] pry(main)* class Guerrero
[93] pry(main)* end
ArgumentError: wrong number of arguments (given 1, expected 0)
from (pry):121:in `energia='
```

### Slide 11 — `Object#sarasa`, `Numeric#+`, `Integer#+`: la consola se rompe; `exit` y `clear`

*(Slide compuesto por dos recortes de la misma terminal, uno al lado del otro, tomados en momentos distintos: el segundo empieza en `[96]` y llega hasta la salida de pry. En la zona común difieren: el primero muestra `=> 2` tras los dos `2 + 2`; el segundo no.)*

Recorte 1:

```ruby
[94] pry(main)> class Object
[94] pry(main)*   def sarasa
[94] pry(main)*     42
[94] pry(main)*   end
[94] pry(main)* end
=> :sarasa
[95] pry(main)> marine.sarasa
=> 42
[96] pry(main)> :descansar.sarasa
=> 42
[97] pry(main)> 2.sarasa
=> 42
[98] pry(main)> class Numeric
[98] pry(main)*   def +(a)
[98] pry(main)*     2
[98] pry(main)*   end
[98] pry(main)* end
=> :+
[99] pry(main)>
[100] pry(main)> 2 + 2
=> 4
[101] pry(main)> class Integer
[101] pry(main)*   def +(a)
[101] pry(main)*     2
[101] pry(main)*   end
[101] pry(main)* end
[2] pry(main)> 2 + 2
[2] pry(main)> 2 + 2
=> 2
[2] pry(main)>
```

Recorte 2:

```ruby
[96] pry(main)> :descansar.sarasa
=> 42
[97] pry(main)> 2.sarasa
=> 42
[98] pry(main)> class Numeric
[98] pry(main)*   def +(a)
[98] pry(main)*     2
[98] pry(main)*   end
[98] pry(main)* end
=> :+
[99] pry(main)>
[100] pry(main)> 2 + 2
=> 4
[101] pry(main)> class Integer
[101] pry(main)*   def +(a)
[101] pry(main)*     2
[101] pry(main)*   end
[101] pry(main)* end
[2] pry(main)> 2 + 2
[2] pry(main)> 2 + 2
[2] pry(main)> 2 + 4444
[2] pry(main)> 2 + 4444
[2] pry(main)>
[2] pry(main)>
[2] pry(main)>
[2] pry(main)>
[2] pry(main)>
[2] pry(main)> exit
[2] pry(main)> exit
ernesto@aldebaran:~/tadp/tadp-clases/src$ clear
```

---

## Parte 2 — Segunda sesión de pry (slides 12–26)

### Slide 12 — Nuevo `pry`; `A` ya no existe

```ruby
ernesto@aldebaran:~/tadp/tadp-clases/src$ pry
[1] pry(main)> require_relative 'age-clase2'
=> true
[2] pry(main)> A
NameError: uninitialized constant A
from (pry):2:in `__pry__'
[3] pry(main)> A.new
NameError: uninitialized constant A
from (pry):3:in `__pry__'
[4] pry(main)>
```

### Slide 13 — `.class` de clases es `Class`; cadena de `superclass` de `Espadachin`

```ruby
from (pry):3:in `__pry__'
[4] pry(main)> marine = Guerrero.new
=> #<Guerrero:0x000055c7452ed490 @energia=100, @potencial_defensivo=10, @potencial_ofensivo=20>
[5] pry(main)> marine.class
=> Guerrero
[6] pry(main)> Guerrero.class
=> Class
[7] pry(main)> Espadachin.class
=> Class
[8] pry(main)> Object.class
=> Class
[9] pry(main)> Object.class.is_
Object.class.is_a?              Object.class.is_reachable_from?
[9] pry(main)> Object.class.is_a? Class
=> true
[10] pry(main)> Object.class
=> Class
[11] pry(main)> Object.class.class
=> Class
[12] pry(main)> Espadachin.ancestors
=> [Espadachin, Guerrero, Defensor, Atacante, Object, PP::ObjectMixin, Kernel, BasicObject]
[13] pry(main)> Espadachin.superclass
=> Guerrero
[14] pry(main)> Espadachin.superclass.superclass
=> Object
[15] pry(main)> Espadachin.superclass.superclass.superclass
=> BasicObject
[16] pry(main)> Espadachin.superclass.superclass.superclass.superclass
=> nil
[17] pry(main)>
```

### Slide 14 — `BasicObject.superclass` es `nil`; `nil.class` y su cadena; `Atacante.class` es `Module`

```ruby
[17] pry(main)> BasicObject.superclass
=> nil
[18] pry(main)> BasicObject.superclass.is_a? Class
=> false
[19] pry(main)> BasicObject.superclass.is_a? Object
=> true
[20] pry(main)> BasicObject.superclass.superclass
NoMethodError: undefined method `superclass' for nil:NilClass
from (pry):20:in `__pry__'
[21] pry(main)> marine.superclass
NoMethodError: undefined method `superclass' for #<Guerrero:0x000055c7452ed490>
from (pry):21:in `__pry__'
[22] pry(main)> marine.is_a? Object
=> true
[23] pry(main)> nil
=> nil
[24] pry(main)> BasicObject.superclass == nil
=> true
[25] pry(main)> nil.class
=> NilClass
[26] pry(main)> nil.class.class
=> Class
[27] pry(main)> nil.class.superclass
=> Object
[28] pry(main)> nil.class.superclass.superclass
=> BasicObject
[29] pry(main)> nil.class.superclass.superclass.superclass
=> nil
[30] pry(main)> nil.class.superclass.superclass.superclass.superclass
NoMethodError: undefined method `superclass' for nil:NilClass
from (pry):30:in `__pry__'
[31] pry(main)> Atacante
=> Atacante
[32] pry(main)> Atacante.class
=> Module
[33] pry(main)> Atacante.class.class
=> Class
[34] pry(main)> Atacante.class.superclass
=> Object
[35] pry(main)>
```

### Slide 15 — Editor VS Code: `src/age-clase2.rb`, líneas 125–158 (`class Escuadron`)

Captura del editor VS Code (tema oscuro). Explorador a la izquierda: proyecto `TADP-CLASES` con carpetas `spec` y `src` (dentro de `src`: `age-clase2.rb` marcado `M`, `age.rb`), y en la raíz `.gitignore`, `.ruby-version` (marcado `U`), `Gemfile`, `Gemfile.lock`, `image_0.png`, `image_1.png`, `README.md`, `script-clase-1.md`. Pestaña abierta: `age-clase2.rb`. Barra de estado: rama `ruby-age*`, `Ln 135, Col 5 (21 selected)`, `Spaces: 2`, `UTF-8`, `LF`, `Ruby`. En la línea 135 está seleccionado `self.new(integrantes)`. Las líneas 150 y 154 exceden el ancho visible y quedan cortadas.

```ruby
    self.energia = 0
  end

end

class Escuadron
  attr_accessor :integrantes

  def self.entrenar(integrantes)
    check_atacantes integrantes
    self.new(integrantes)
  end

  def self.entrenar_guerreros(integrantes)
    check_guerreros integrantes
    self.new(integrantes)
  end

  def initialize(integrantes)
    self.integrantes = integrantes
  end

  protected

  def self.check_guerreros(integrantes)
    raise StandardError.new('Uno de los integrantes no es un guerrero') if integrantes.any? {|i| !i.is_a? Guer # ← recortado en la captura
  end

  def self.check_atacantes(integrantes)
    raise StandardError.new('Uno de los integrantes no es un atacante') if integrantes.any? {|i| !i.is_a? Ataca # ← recortado en la captura
  end
end

class Peloton
```

### Slide 16 — `Class.superclass`; `Escuadron.entrenar` con y sin error

```ruby
[35] pry(main)> Class.superclass
=> Module
[36] pry(main)> Class.superclass.superclass
=> Object
[37] pry(main)> Escuadron
=> Escuadron
[38] pry(main)> Escuadron.entrenar [Guerrero.new,2]
StandardError: Uno de los integrantes no es un atacante
from /home/ernesto/tadp/tadp-clases/src/age-clase2.rb:159:in `check_atacantes'
[39] pry(main)> Escuadron.entrenar [Guerrero.new]
=> #<Escuadron:0x000055c745635e90
 @integrantes=[#<Guerrero:0x000055c745635f08 @energia=100, @potencial_defensivo=10, @potencial_ofensivo=20>]>
[40] pry(main)> Escuadron.class
=> Class
[41] pry(main)> Escuadron.instance_methods
```

### Slide 17 — Final de `Escuadron.instance_methods`; `instance_methods false`

*(La captura entra con la lista de `[41]` ya empezada; el principio no está en el material.)*

```ruby
 :pry,
 :__binding__,
 :pretty_print_inspect,
 :pretty_print_cycle,
 :pretty_print,
 :pretty_print_instance_variables,
 :instance_variable_defined?,
 :remove_instance_variable,
 :instance_of?,
 :kind_of?,
 :is_a?,
 :tap,
 :instance_variable_set,
 :protected_methods,
 :instance_variables,
 :instance_variable_get,
 :private_methods,
 :public_methods,
 :public_send,
 :method,
 :public_method,
 :singleton_method,
 :define_singleton_method,
 :extend,
 :to_enum,
 :enum_for,
 :pretty_inspect,
[42] pry(main)> Escuadron.instance_methods false
=> [:integrantes, :integrantes=]
[43] pry(main)> Escuadron.methods
```

### Slide 18 — Final de `Escuadron.methods`; `include? :entrenar`

*(La captura entra con la lista de `[43]` ya empezada; el principio no está en el material.)*

```ruby
 :new,
 :<=>,
 :<=,
 :>=,
 :==,
 :===,
 :included_modules,
 :include?,
 :name,
 :ancestors,
 :attr,
 :attr_reader,
 :attr_writer,
 :attr_accessor,
 :instance_methods,
 :public_instance_methods,
 :protected_instance_methods,
 :private_instance_methods,
 :constants,
 :const_get,
 :const_set,
 :const_defined?,
 :class_variables,
[44] pry(main)> Escuadron.methods.include? :entrenar
=> true
[45] pry(main)> Escuadron.class.instance_methods.include? :entrenar
=> false
[46] pry(main)> marine
=> #<Guerrero:0x000055c7452ed490 @energia=100, @potencial_defensivo=10, @potencial_ofensivo=20>
[47] pry(main)> marine.methods
```

### Slide 19 — Comienzo de la salida de `marine.methods`

*(Recorte angosto; la línea que sigue a `:tap,` está cortada por el borde inferior de la captura y no se transcribe.)*

```ruby
=> [:descansar_atacante,
 :descansar_defensor,
 :peloton,
 :lastimado,
 :cansado,
 :sufri_danio,
 :descansar,
 :peloton=,
 :energia=,
 :potencial_defensivo=,
 :energia,
 :potencial_defensivo,
 :descansado=,
 :potencial_ofensivo,
 :potencial_ofensivo=,
 :descansado,
 :atacar,
 :pry,
 :__binding__,
 :pretty_print_inspect,
 :pretty_print_cycle,
 :pretty_print,
 :pretty_print_instance_variables,
 :instance_variable_defined?,
 :remove_instance_variable,
 :instance_of?,
 :kind_of?,
 :is_a?,
 :tap,
```

### Slide 20 — `methods.include?` vs `class.instance_methods.include?`; `singleton_class`

*(Slide compuesto por dos recortes: el primero es la terminal principal; el segundo es la salida de `[57]` hasta el prompt `[58]`.)*

Recorte 1:

```ruby
 :__binding__,
 :pretty_print_inspect,
 :pretty_print_cycle,
 :pretty_print,
 :pretty_print_instance_variables,
 :instance_variable_defined?,
 :remove_instance_variable,
 :instance_of?,
 :kind_of?,
 :is_a?,
 :tap,
[48] pry(main)> marine.methods.include? :cansado
=> true
[49] pry(main)> marine.class.instance_methods.include? :cansado
=> true
[50] pry(main)> Escuadron.methods.include? :entrenar
=> true
[51] pry(main)> Escuadron.class.instance_methods.include? :entrenar
=> false
[52] pry(main)> Escuadron.methods.include? :new
=> true
[53] pry(main)> Escuadron.class.instance_methods.include? :new
=> true
[54] pry(main)> Escuadron.class
=> Class
[55] pry(main)> Guerrero.class
=> Class
[56] pry(main)> Escuadron.singleton_class
=> #<Class:Escuadron>
[57] pry(main)> Escuadron.singleton_class.instance_methods
```

Recorte 2:

```ruby
=> [:entrenar_guerreros,
 :check_guerreros,
 :entrenar,
 :check_atacantes,
 :allocate,
 :superclass,
 :new,
 :<=>,
 :<=,
 :>=,
 :==,
 :===,
 :included_modules,
 :include?,
 :name,
 :ancestors,
 :attr,
 :attr_reader,
 :attr_writer,
 :attr_accessor,
 :instance_methods,
 :public_instance_methods,
 :protected_instance_methods,
 :private_instance_methods,
 :constants,
 :const_get,
 :const_set,
 :const_defined?,
 :class_variables,
[58] pry(main)>
```

### Slide 21 — `singleton_class.instance_methods false`; `Escuadron.instance_methods` de nuevo

*(Slide compuesto por dos recortes apilados: arriba, los prompts `[58]`–`[60]`; abajo, el final de la salida de `[60]` y los prompts siguientes.)*

Recorte 1:

```ruby
[58] pry(main)> Escuadron.singleton_class.instance_methods false
=> [:entrenar_guerreros, :check_guerreros, :entrenar, :check_atacantes]
[59] pry(main)> Escuadron.singleton_class
=> #<Class:Escuadron>
[60] pry(main)> Escuadron.instance_methods
```

Recorte 2:

```ruby
 :pry,
 :__binding__,
 :pretty_print_inspect,
 :pretty_print_cycle,
 :pretty_print,
 :pretty_print_instance_variables,
 :instance_variable_defined?,
 :remove_instance_variable,
 :instance_of?,
 :kind_of?,
 :is_a?,
 :tap,
 :instance_variable_set,
 :protected_methods,
 :instance_variables,
 :instance_variable_get,
 :private_methods,
 :public_methods,
 :public_send,
 :method,
 :public_method,
 :singleton_method,
 :define_singleton_method,
 :extend,
 :to_enum,
 :enum_for,
 :pretty_inspect,
[61] pry(main)> Escuadron.instance_methods false
=> [:integrantes, :integrantes=]
[62] pry(main)>
```

### Slide 22 — `Escuadron.class.instance_methods false`; `marine.singleton_class`

```ruby
[62] pry(main)> Escuadron.class.instance_methods false
=> [:allocate, :superclass, :new]
[63] pry(main)> Escuadron.entrenar []
=> #<Escuadron:0x000055c745620bf8 @integrantes=[]>
[64] pry(main)> Esucadron.singleton_class
NameError: uninitialized constant Esucadron
Did you mean?  Escuadron
from (pry):64:in `__pry__'
[65] pry(main)> Escuadron.singleton_class
=> #<Class:Escuadron>
[66] pry(main)> Escuadron.singleton_class.instance_methods false
=> [:entrenar_guerreros, :check_guerreros, :entrenar, :check_atacantes]
[67] pry(main)> marine
=> #<Guerrero:0x000055c7452ed490 @energia=100, @potencial_defensivo=10, @potencial_ofensivo=20>
[68] pry(main)> marine.singleton_class
=> #<Class:#<Guerrero:0x000055c7452ed490>>
[69] pry(main)>
```

### Slide 23 — `module Saludar`; `include` en la singleton class de `marine`

```ruby
[69] pry(main)> module Saludar
[69] pry(main)*   def saludar
[69] pry(main)*     "Hola"
[69] pry(main)*   end
[69] pry(main)* end
=> :saludar
[70] pry(main)> marine_2 = Guerrero.new
=> #<Guerrero:0x000055c74568b980 @energia=100, @potencial_defensivo=10, @potencial_ofensivo=20>
[71] pry(main)> marine
=> #<Guerrero:0x000055c7452ed490 @energia=100, @potencial_defensivo=10, @potencial_ofensivo=20>
[72] pry(main)> marine_2.singleton_class
=> #<Class:#<Guerrero:0x000055c74568b980>>
[73] pry(main)> marine.singleton_class
=> #<Class:#<Guerrero:0x000055c7452ed490>>
[74] pry(main)> marine.singleton_class.include Saludar
=> #<Class:#<Guerrero:0x000055c7452ed490>>
[75] pry(main)> marine.saludar
=> "Hola"
[76] pry(main)> marine_2.saludar
NoMethodError: undefined method `saludar' for #<Guerrero:0x000055c74568b980>
from (pry):80:in `__pry__'
[77] pry(main)>
```

### Slide 24 — Singleton classes de instancias y de clases; `superclass` de una singleton class

```ruby
[77] pry(main)> marine_2.singleton_class
=> #<Class:#<Guerrero:0x000055c74568b980>>
[78] pry(main)> marine.singleton_class
=> #<Class:#<Guerrero:0x000055c7452ed490>>
[79] pry(main)> marine.singleton_class.superclass
=> Guerrero
[80] pry(main)> Espadachin.singleton_class
=> #<Class:Espadachin>
[81] pry(main)> Espadachin.singleton_class
=> #<Class:Espadachin>
[82] pry(main)> Guerrero.singleton_class
=> #<Class:Guerrero>
[83] pry(main)> marine.saludar
=> "Hola"
[84] pry(main)> marine_2.saludar
NoMethodError: undefined method `saludar' for #<Guerrero:0x000055c74568b980>
from (pry):88:in `__pry__'
[85] pry(main)> Espadachin.singleton_class
=> #<Class:Espadachin>
[86] pry(main)> Guerrero.singleton_class
=> #<Class:Guerrero>
[87] pry(main)> Guerrero.singleton_class
=> #<Class:Guerrero>
[88] pry(main)> Guerrero.new
=> #<Guerrero:0x000055c745622b10 @energia=100, @potencial_defensivo=10, @potencial_ofensivo=20>
[89] pry(main)> Guerrero.singleton_class
=> #<Class:Guerrero>
[90] pry(main)> Guerrero.singleton_class.instance_methods false
=> []
[91] pry(main)>
```

### Slide 25 — Cadena de `superclass` de las singleton classes; `Class.instance_methods false`

```ruby
=> #<Class:Guerrero>
[90] pry(main)> Guerrero.singleton_class.instance_methods false
=> []
[91] pry(main)> Guerrero.singleton_class.instance_methods.include? :new
=> true
[92] pry(main)> Espadachin.singleton_class
=> #<Class:Espadachin>
[93] pry(main)> Espadachin.singleton_class.superclass
=> #<Class:Guerrero>
[94] pry(main)> Espadachin.singleton_class.superclass.superclass
=> #<Class:Object>
[95] pry(main)> Espadachin.singleton_class.superclass.superclass.superclass
=> #<Class:BasicObject>
[96] pry(main)> Object.singleton_class
=> #<Class:Object>
[97] pry(main)> Object.singleton_class == Espadachin.singleton_class.superclass.superclass
=> true
[98] pry(main)> BasicObject.singleton_class
=> #<Class:BasicObject>
[99] pry(main)> BasicObject.singleton_class.superclass
=> Class
[100] pry(main)> Espadachin.singleton_class.superclass.superclass.superclass
=> #<Class:BasicObject>
[101] pry(main)> Espadachin.singleton_class.superclass.superclass.superclass.superclass
=> Class
[102] pry(main)> Class.instance_methods false
=> [:allocate, :superclass, :new]
[103] pry(main)> Object.new
=> #<Object:0x000055c74525b798>
[104] pry(main)>
```

### Slide 26 — Singleton class de una singleton class; `Class.singleton_class` y su cadena

```ruby
[104] pry(main)> marine.singleton_class
=> #<Class:#<Guerrero:0x000055c7452ed490>>
[105] pry(main)> marine.singleton_class.singleton_class
=> #<Class:#<Class:#<Guerrero:0x000055c7452ed490>>>
[106] pry(main)> Class.singleton_class
=> #<Class:Class>
[107] pry(main)> Class.singleton_class.superclass
=> #<Class:Module>
[108] pry(main)> Class.singleton_class.superclass.superclass
=> #<Class:Object>
[109] pry(main)>
```

---

**FIN DEL ARCHIVO FUENTE — Capturas de consola — video 2020 (sesión de pry sobre `age-clase2.rb`)**
