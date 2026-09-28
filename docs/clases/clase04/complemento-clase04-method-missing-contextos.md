# Complemento — clase04 — `method_missing`, bloques, contextos e `instance_eval`

> **Qué es esto.** Dos cosas que el apunte maestro no tiene. **Parte A:** aclaraciones que salieron al estudiar la unidad, reescritas limpias y autocontenidas. **Parte B:** las respuestas de los checkpoints de las cinco partes del maestro, en formato de examen (la primera oración ya responde; procedimiento cuando la pregunta es práctica).
>
> **Cómo usarlo.** Primero intentá cada pregunta del checkpoint sin mirar. Después comparás. Una respuesta que no te salió es una sección del maestro para releer, no una frase para memorizar.
>
> **Código.** Ruby 3.x, `age.rb` de la materia donde se indica. Todo el código se ejecutó antes de escribirse.

---

## Parte A — Aclaraciones

### A1. Cómo experimentar sin perder las variables 🟡

> **Regla.** Las **variables locales** de un archivo mueren cuando termina el archivo. Las **clases, métodos y constantes** sobreviven. Por eso, después de `require_relative 'age'` en una consola, tenés `Guerrero` pero no el `atila = Guerrero.new` que estaba escrito en el archivo.

La forma cómoda de experimentar, con dos carpetas:

```
proyecto/
├── lib/
│   └── age.rb                      # solo definiciones (clases, módulos). No se toca.
└── experimentos/
    ├── clase04_parte1.rb           # un archivo por tema: arranca con los requires, termina con binding.pry
    └── clase04_parte4.rb
```

```ruby
# experimentos/clase04_parte4.rb
require 'pry'
require_relative '../lib/age'      # ../ porque el experimento está una carpeta adentro

atila = Guerrero.new
factor = 3
Guerrero.define_method(:huir) { energia / factor }

binding.pry                        # abre la consola ACÁ, adentro del contexto del archivo: atila y factor están vivos
```

Se corre desde la raíz: `ruby experimentos/clase04_parte4.rb`. La consola arranca con todas las variables del archivo. Para recargar después de editar: `Ctrl-D` (salir), `↑` y Enter (correr de nuevo).

| Escribís | Qué hace |
|---|---|
| `require_relative 'x'` | ejecuta el archivo **una vez por sesión**; la segunda vez no hace nada |
| `load './x.rb'` | ejecuta el archivo **cada vez**: sirve para actualizar `lib/age.rb` sin salir de la consola (los objetos vivos siguen; los métodos viven en la clase, así que ven los cambios) |
| `binding.pry` al final del archivo | deja la consola adentro del contexto del archivo, con sus variables |

Atajos de pry: `Ctrl-L` o `clear-screen` limpian la pantalla (`clear` a secas da `NameError`: pry lo busca como variable o mensaje). `.comando` (con punto adelante) ejecuta un comando de la shell.

### A2. `puts` está dos veces en `Kernel` 🟢

> **Regla.** `puts` es **privado** como método de instancia de `Kernel` (por eso se manda sin receptor desde cualquier objeto, y por eso `Kernel.instance_methods(false)` no lo lista) **y** es **público** en la autoclase de `Kernel` (por eso `Kernel.puts("hola")` funciona). Las dos definiciones las crea `module_function`, un mensaje que hace exactamente esa duplicación.

```ruby
p Kernel.private_instance_methods(false).include?(:puts)          # => true    ← privado, para todas las instancias
p Kernel.singleton_class.instance_methods(false).include?(:puts)  # => true    ← público, en la autoclase de Kernel
Kernel.puts("hola")                                               # => hola    ← receptor explícito: la versión pública
```

Es el mismo caso que `method_missing` en `BasicObject` (maestro, Parte 1 §4): un método que "no aparece" en `instance_methods` está en la lista de privados.

🕳️ `module_function` se profundiza aparte, otro día. Para esta unidad alcanza con saber que `puts` sin receptor llega a `self` y es privado.

### A3. "¿Esto se puede ejecutar?": `respond_to?(:call)`, no `is_a?(Proc)` 🟡

> **Regla.** Para saber si un objeto se puede ejecutar, se le pregunta si **entiende `call`**, no de qué clase es. `is_a?(Proc)` funciona para procs y lambdas, pero rompe el polimorfismo: un objeto método (`method(:puts)`, clase 3) entiende `call` sin ser un `Proc`.

```ruby
p proc { }.respond_to?(:call)        # => true
p method(:puts).respond_to?(:call)   # => true     ← un Method se ejecuta con call
p method(:puts).is_a?(Proc)          # => false    ← y no es un Proc: is_a? lo descartaría
p 5.respond_to?(:call)               # => false
```

Es la regla general de objetos: preguntá por el mensaje que vas a mandar, no por la clase. `Proc` es una rama hermana de `Guerrero` en la jerarquía, no una ancestra: `atila.is_a?(Proc)` es `false`.

### A4. Un método singleton no se muda de objeto 🟡

> **Regla.** Un método definido en la autoclase de `atila` vive **en la autoclase de `atila`**, y Ruby no permite engancharlo en otro objeto. Lo que se reutiliza es el **código**, guardado en un proc, y se lo aplica a cada objeto por separado.

```ruby
require_relative 'age'
atila = Guerrero.new
otro  = Guerrero.new
atila.define_singleton_method(:gritar) { "haaaa" }

m = atila.method(:gritar)            # el envoltorio del método (clase 3): método + atila
p m.owner                            # => #<Class:#<Guerrero:0x…>>     ← la autoclase de atila

otro.define_singleton_method(:gritar, m)
# => TypeError: can't bind singleton method to a different class
m.unbind.bind(otro)
# => TypeError: singleton method called for a different object
```

Las dos formas que sí andan, con la misma salida (`otro.gritar` → `"haaaa"`):

| Escribís | Ruby entiende |
|---|---|
| `definir = proc { def gritar; "haaaa"; end }` y después `otro.instance_eval(&definir)` | ejecutar el bloque con `self` = `otro`; el `def` adentro cae en la autoclase de `otro` (Parte 4 §7) |
| `cuerpo = proc { "haaaa" }` y después `otro.define_singleton_method(:gritar, &cuerpo)` | definir en la autoclase de `otro` un método cuyo cuerpo es ese proc |

En las dos, cada objeto queda con **su** método, con su propio `self`.

### A5. Hash: lo mínimo para leer el registrador 🟢

> **Regla.** Un hash es un diccionario: claves y valores. Con claves símbolo se escribe `{ clave: valor }`; se lee con `h[:clave]`; una clave que no está devuelve `nil`. Al recorrerlo con `each`, el bloque recibe **dos parámetros**: la clave y el valor.

```ruby
h = { mensaje: :atacar, parametros: [1, 2] }   # dos claves símbolo (la forma que usa el registrador, Parte 2)

p h[:mensaje]                      # => :atacar
p h[:parametros]                   # => [1, 2]
p h[:nada]                         # => nil          ← clave inexistente: nil, sin error
p h.keys                           # => [:mensaje, :parametros]

h.each do |clave, valor|           # dos parámetros: cada vuelta trae un par
  puts "#{clave} -> #{valor.inspect}"
end
# => mensaje -> :atacar
#    parametros -> [1, 2]

h2 = { "a" => 1 }                  # con claves que no son símbolos, la flecha =>
p h2["a"]                          # => 1
```

`{ }` vacías son un hash vacío, no un bloque (Parte 3 §2).

---

## Parte B — Respuestas de los checkpoints

### Parte 1 — `method_missing`

**1.** `atila.volar(3)`: lookup 1 de `volar` por `#atila → Guerrero → Defensor → Atacante → Object → Kernel → BasicObject`, no está. Ruby manda `atila.method_missing(:volar, 3)`; lookup 2 de `method_missing`, lo encuentra en `BasicObject`, y **ese método** lanza `NoMethodError`. Dos lookups; la excepción la lanza un método común, no el lookup.

**2.** Porque el resto del programa sigue corriendo con una sentencia salteada, y el error aparece más lejos, sin relación visible con la causa. La excepción corta en el punto exacto del fallo y da la chance de atajarla; "no hacer nada" no da ninguna y encima no avisa.

**3.** Una excepción que nadie ataja termina en panic, pero **se puede atajar**: en el camino hacia arriba, cada capa tiene la oportunidad de hacer algo (avisar, mostrar un cartel, seguir con lo demás). El panic no da ninguna oportunidad.

**4.** Porque así cada objeto (o cada jerarquía) define **su propio plan B**: guerreros y murallas manejan distinto lo que no entienden. `Object` o un objeto global darían un único plan B para todo el programa.

**5.** El receptor, el nombre del mensaje (como símbolo) y los parámetros (`*args`). Son exactamente los tres datos con los que Ruby partió para hacer el lookup: todo lo necesario para ejecutar el mensaje, menos el método.

**6.** En el loop infinito. Al llegar al `*`, Ruby manda `method_missing`; sin nadie que lo defina, ese lookup también llega al `*` y manda `method_missing` otra vez. Por eso el corte está cableado en `BasicObject`: el segundo lookup tiene que tener éxito siempre.

**7.** Está definido. `instance_methods` lista solo los **públicos**, y `method_missing` se define privado. Se comprueba con `Guerrero.private_instance_methods(false)` (lo lista) o con `atila.method(:method_missing).owner` (→ `Guerrero`; `.owner` no filtra por visibilidad).

**8.**
```ruby
class Muralla
  private def method_missing(name, *args)
    if name.start_with?("reforzar_")
      self.potencial_defensivo += 5      # self. para llamar al setter
    else
      super                              # lo que no es mío sigue subiendo → NoMethodError normal
    end
  end

  def respond_to_missing?(name, include_private = false)
    name.start_with?("reforzar_") || super
  end
end
```
Verificación: `muralla.reforzar_con_piedra` sube el potencial defensivo de 10 a 15; `muralla.volar` da `NoMethodError`; `muralla.respond_to?(:reforzar_x)` da `true`.

**9.** `atila.sarasa` devuelve `nil` y sigue, en vez de `NoMethodError`. Es la opción "no hacer nada" de la tabla: la sentencia no se ejecutó, el programa continuó, y el error aparece más tarde como un `nil` inexplicable, lejos de la causa. Un error corta en el lugar; el silencio esconde.

**10.** HACER: `atila.comerse_x` → lookup falla → `method_missing(:comerse_x)` → criterio; si no es nuestro, `super` → `BasicObject` → **`NoMethodError`**. PREGUNTAR: `atila.respond_to?(:comerse_x)` → no hay método → `respond_to_missing?(:comerse_x, false)` → mismo criterio; si no es nuestro, `super` → **`false`**. El de preguntar nunca lanza excepción.

**11.** Porque `respond_to_missing?` es el hook que Ruby previó: `respond_to?` sigue haciendo su trabajo (mirar la jerarquía, contar privados o no) y vos agregás solo el criterio de tu `method_missing`. Además, `method(:x)` también consulta `respond_to_missing?`: con solo `respond_to?` pisado, `atila.method(:comerse_algo)` da `NameError`.

**12.** "No siempre se puede saber". `methods` lista los métodos definidos, y con un `method_missing` en la jerarquía la interfaz puede ser infinita. Lo que sí puedo contestar, si el objeto cumple el contrato, es `respond_to?` mensaje por mensaje.

### Parte 2 — El registrador y `BasicObject`

**1.** Los otros tres (`potencial_defensivo` dos veces y `sufri_danio`) los manda el **oponente** desde adentro de su `atacar`: pregunta el potencial defensivo del atacado (para decidir si pasa y para calcular el daño) y después le manda `sufri_danio`. El registrador los vio porque iban dirigidos al guerrero, que es el registrador: todo mensaje que él no entiende cae en su `method_missing`.

**2.** En la firma, `*args` **junta** todos los argumentos en un array. En `send(method, *args)`, **desparrama** el array en argumentos sueltos. Sin el asterisco en el `send`, `atila` recibiría **un** argumento (el array entero): `ArgumentError: wrong number of arguments (given 1, expected 2)` en cualquier mensaje con dos parámetros, o un array donde se esperaba un objeto.

**3.** `@objeto.respond_to?(method, include_private)`: el registrador responde exactamente lo que responde el objeto envuelto. No lo decide el registrador porque él no tiene interfaz propia; su interfaz **es** la de `atila`, y solo `atila` sabe cuál es.

**4.** Porque `is_a?` **existe** en el registrador: lo hereda de `Object` (vía `Kernel`), el lookup lo encuentra y lo responde el registrador mismo. A `method_missing` solo llega lo que el lookup no encontró. `is_a?` vive en `Kernel`.

**5.** `method_missing` **extiende** una interfaz con mensajes que no están; nunca **pisa** uno que ya existe, porque el lookup lo encuentra antes de fallar. Ejemplo: no se puede cambiar cómo se comporta `to_s` (o `atacar`) con `method_missing`; el método está, y `method_missing` no se entera.

**6.** Salida 1: redefinir `to_s` (y `is_a?`, y los ~40 de `Object`) uno por uno para que anoten y deleguen; anda, y enumera a mano lo que el pattern quería evitar. Salida 2: heredar de `BasicObject`, así casi nada se encuentra por lookup y todo cae en `method_missing`; el proxy queda transparente, y se pierde `Kernel` (ni `puts` ni `raise` sin receptor).

**7.** `BasicObject` **no** incluye `Kernel` ni hereda de `Object`: no tiene `puts`, `p`, `raise`, `is_a?`, `to_s`, `class`… Adentro de una subclase de `BasicObject`, nada de `Kernel` se puede mandar sin receptor; hace falta `::Kernel.puts(...)` (con `::` porque tampoco ve las constantes de `Object`).

**8.** Gana un oponente que recibe cualquier mensaje, nunca falla y no causa efectos: aísla lo que se quiere probar. Riesgo: es indebuggeable, nada avisa si el código bajo prueba manda un mensaje equivocado. Pieza obligatoria: `respond_to_missing?` que diga `true`, o el código que pregunta antes de mandar se equivoca.

**9.** Sí: es una lista de mensajes **abierta** (los que no entiende el guerrero), y no pisa nada existente. Va en `Guerrero`: `method_missing` que reenvíe con `@espada.send(name, *args)` si la espada responde, y `super` si no. Las dos cosas más: el `super` para lo que la espada tampoco entiende, y `respond_to_missing?` delegando a `@espada.respond_to?`.

**10.** No. `atacar` ya existe en la jerarquía (`Atacante`): el lookup lo encuentra y `method_missing` nunca se ejecuta. Para cambiar comportamiento existente se redefine el método (en `Guerrero`, en el mixin, o con `define_method`), no se usa `method_missing`.

### Parte 3 — Bloques, procs y lambdas

**1.** Lo recibe `self`, que en un archivo suelto es `main`. `puts` está en `Kernel`, el mixin de `Object`: cualquier objeto lo entiende. `2.puts(self)` falla porque `puts` es privado y no admite receptor explícito; `send` salta la privacidad.

**2.** Receptor: `2`. Argumento: `self`, evaluado **donde está escrito**, o sea en el archivo, donde vale `main`. Adentro de un método de `Guerrero` la misma línea imprime el guerrero, porque ahí `self` es el que recibió el mensaje.

**3.** `a = { puts "x" }` falla porque un bloque solo puede ir pegado a un envío de mensaje: suelto es error de sintaxis. `a = {}` no falla porque las llaves vacías son un **hash** vacío.

**4.** Porque el bloque **no es un parámetro**: no es un objeto y Ruby lo cuenta aparte, al final del envío. `each` declara cero parámetros; el proc es un objeto y ocupa lugar de parámetro.

**5.** No se imprime nada: `proc` guarda el código sin ejecutarlo. Falta `pr.call`. `proc` es un **mensaje** (a `self`, definido en `Kernel`) que devuelve una instancia de la clase `Proc`.

**6.** `main`, el mismo `self` del lugar donde el bloque fue escrito. Adentro de un método de `atila`, `self` del proc es `atila`, porque ese era el `self` donde el proc nació.

**7.** Porque un bloque no es objeto y no ocupa un parámetro común; `m` con un parámetro espera un objeto. Formas correctas: `def m; yield; end` (`LocalJumpError: no block given` si falta) y `def m(&b); b.call; end` (`b` vale `nil`: `NoMethodError: undefined method 'call' for nil`). En las dos se evita con `if block_given?`.

**8.** `yield if block_given?` → `if block_given?` / `yield` / `end`. `puts "x" unless c` → `if !c` / `puts "x"` / `end`.

**9.** Con tres **procs** como parámetros comunes: `m(proc { }, proc { }, proc { })` y adentro `p1.call`, etc. Con bloques no se puede porque un mensaje recibe **un solo** bloque, al final.

**10.** En la firma, `&b` **captura**: el bloque que llega entra convertido en `Proc`. En la llamada, `&un_proc` **convierte**: el proc pasa como el bloque del mensaje. Misma dualidad que `*`: junta en la firma, desparrama en la llamada.

**11.** `{ mostrar.call }`: el bloque ejecuta el proc sin pasarle nada, `n` es `nil`, sale una línea vacía. `{ |n| mostrar(n).call }`: con paréntesis, `mostrar(n)` es un **mensaje**, no la variable → `NoMethodError: undefined method 'mostrar'`. `m23(10, 20, mostrar)`: el proc ocupa un tercer parámetro → `ArgumentError (given 3, expected 2)`.

**12.** (1) Parámetros: `lambda { |x| }.call` → `ArgumentError`; `proc { |x| }.call` → `x` vale `nil`. (2) `return`: en `def m; lambda { return 5 }.call; 10; end`, `m` devuelve 10; con `proc { return 5 }` devuelve 5, porque el `return` del proc es un `return` de `m`.

**13.** Devuelve 1: el `return` del proc sale del método donde el proc nació (`m`), atravesando `ejecutar`; el `2` no se ejecuta. Si `m` devolviera `pr` y lo ejecutás afuera, `LocalJumpError: unexpected return`: el método al que apunta ese `return` ya terminó.

**14.** Cada llamada a `contador` crea un contexto nuevo con su propia `n`, y el proc que devuelve queda pegado a **ese** contexto; `c1` y `c2` salieron de dos llamadas distintas. Closure: el proc encierra el contexto donde fue definido (variables, `self`) y lo mantiene vivo mientras el proc viva, aunque el método haya terminado.

### Parte 4 — Contextos, scope gates, flat scope e `instance_eval`

**1.** `NameError: undefined local variable or method 'x' for main`. Adentro de `m`, `x` no es variable (el `def` cortó el contexto) y tampoco es un método que `main` entienda: Ruby lo buscó de las dos formas y falló en las dos.

**2.** Devuelve 15. `saraza = 15` crea una variable local, y a partir de ahí la palabra suelta `saraza` es esa variable (las variables tienen prioridad). Al método se llega con receptor explícito, `self.saraza`, o con paréntesis, `saraza()`.

**3.** `mostrar(5)` con paréntesis es siempre un mensaje: Ruby ni mira las variables. Por eso el error solo dice "undefined method": a diferencia de la palabra suelta, acá no había ambigüedad variable/método que reportar.

**4.** `if` **no abre** contexto: una variable creada adentro existe afuera. Un proc abre un contexto **hijo**: ve y modifica las de afuera; las que crea, mueren con él. `def` abre un contexto **nuevo y vacío**: las de afuera no existen. Ejemplos: `if true; a = 1; end; a` → `1`; `proc { b = 1 }.call; b` → `NameError`; `x = 1; def m; x; end; m` → `NameError`.

**5.** Pisa si ya existe una variable `saludo` en el contexto de afuera **antes** de que el proc se escriba; crea una propia si no existe. Lo decide el algoritmo de la palabra suelta: `x = …` es siempre variable, y se busca primero en el contexto actual y sus padres.

**6.** El proc captura el contexto **en el momento de escribirse**, y en ese momento `otra_cosa` no existía: para el proc es un mensaje, no una variable. `binding.local_variables` la muestra porque la lee al ejecutar, cuando ya está definida; pero el nombre ya quedó resuelto como mensaje, y `main` no lo entiende → `NameError`.

**7.** Porque al escribir un `def` el objeto que le daría contexto **no existe todavía**: `self` del método es el que reciba el mensaje, y son todas las instancias futuras. El contexto del método se arma recién al llamarlo, a partir del receptor. El proc nace con el contexto vivo alrededor y lo referencia.

**8.** `def`, `class`, `module`. Es un problema porque son las tres herramientas para **empaquetar** código, y empaquetar significa perder las variables del lugar donde estabas. Flat scope existe para eso.

**9.** `saludar2_proc.call` → `main`. `A.define_method(:m, &saludar2_proc)` y `A.new.m` → la instancia. `atila.instance_eval(&saludar2_proc)` → `atila`.

**10.** Porque un proc se lleva el `self` de donde nació, lo dispare quien lo dispare: `call` no lo cambia. Lo cambian `instance_eval`/`instance_exec` (vos) y `define_method`/`Class.new` (Ruby por su cuenta).

**11.** `Guerrero.define_method(:huir) { … factor … }` desde afuera de todo `class`. `class Guerrero; def huir` no sirve porque `def` corta el contexto. `class Guerrero; define_method(:huir)` tampoco: `class` ya cortó antes de llegar al bloque. Flat scope es **ninguna** compuerta entre `factor` y el cuerpo.

**12.** `A.define_method(:x)`: en `A`; todas sus instancias (y subclases). `A.define_singleton_method(:x)`: en la autoclase de `A`; solo la clase `A` (método de clase). `a.define_singleton_method(:x)`: en la autoclase de `a`; solo `a`.

**13.** `r` vale `:gritar` (lo que devuelve `def … end`). Quedó definido `gritar` en la **autoclase** de `atila`. El bloque no quedó asociado a nada: `instance_eval` lo ejecutó en el acto con `self` = `atila` y terminó; solo sobrevive lo que el bloque definió.

**14.** `instance_eval`: `herido = proc { energia < 50 }` y después `atila.instance_eval(&herido)`, `otro.instance_eval(&herido)`. Adentro, `energia` es un mensaje a `self`, y `self` es cada guerrero. Verificado: con energía 100 → `false`; con 20 → `true`.

### Parte 5 — DSLs y cierre

**1.** Al escribir el archivo, `self` es `main` en las tres. Al ejecutar: en `test_suite do`, `main`; adentro de su bloque, la **suite**; adentro del bloque de `test`, el **test**. Lo cambia el `instance_eval` que hay en cada nivel (en `TestSuite#initialize` y en `Test#run`).

**2.** Un método definido suelto en el archivo (`def test_suite`), que queda como método privado de `Object` y por eso `main` lo entiende sin receptor; o mandárselo a un objeto conocido con receptor explícito, `MisTest.test_suite do … end`.

**3.** Porque un test es "código para más tarde": guardarlo permite conocer la suite completa antes de correr. Si se ejecutara al toque no podría, por ejemplo, contar cuántos tests hay antes de empezar, ni correrlos sin imprimir (`run(false)`), ni informar un resumen al final.

**4.** `@cortar_test = proc { return }` nace **en `run`**, y el `return` de un proc sale del método donde el proc nació: al llamarlo desde `assert`, sale de `assert`, de `instance_eval` y de `run`. Creado en `initialize`: `LocalJumpError`, ese método ya terminó. Como lambda: el `return` sale solo de la lambda y el test sigue después del assert fallido.

**5.** Cada `assert` va al `Test` cuyo `instance_eval` lo está ejecutando: el bloque del test interno corre con `self` = el test interno (por el `run` de la suite interna); cuando termina, `self` vuelve a ser el test externo. No se confunden porque cada `run` fija su propio `self` para su propio bloque.

**6.** `TestSuite.new` es un envío común a una clase conocida (una constante, visible desde cualquier lado). `test_suite` es un método suelto del archivo, privado de `Object`, y un `Test` es un `Object`: lo entiende sin receptor.

**7.** Porque `where` es un mensaje al `self` del bloque de `query`, que es un objeto que solo existe ahí adentro; afuera nadie lo contesta. `nota` adentro de `where` lo entiende **cada alumno**: el bloque de `where` se evalúa con `instance_eval` con `self` = ese alumno, y `nota > 7` es `self.nota > 7`.

**8.**
```ruby
db.query { |q|
  q.select { |a| a.nombre & a.nota }
  q.from   { |t| t.alumnos }
  q.where  { |a| a.nota > 7 }
}
```
Sin parámetros se gana sintaxis: solo las palabras del dominio, sin `|x|` ni `x.` en cada línea. Se paga que el lector no ve quién es `self`: tiene que saber que adentro de `where` es un alumno.

**9.** En `Test`, al lado de `assert`: `def deny(un_bool); assert(!un_bool); end`. No necesita proc propio: reutiliza el corte de `assert`, que ya dispara `@cortar_test` cuando el booleano es falso.

**10.**
```ruby
test_suite do
  test "deny corta cuando el booleano es true" do
    ejecuto_mas_alla = false
    TestSuite.new do
      test("prueba") do
        deny(true)                 # va al test INTERNO: assert(false) → corta su run
        ejecuto_mas_alla = true    # no corre
      end
    end.run(false)
    assert(ejecuto_mas_alla == false)   # el assert de AFUERA
  end
end
# => -- deny corta cuando el booleano es true --
#    Tuki
```

**11.** Porque el enunciado pide **esa interfaz**, literal: el objetivo es construir exactamente esa sintaxis y lidiar con los contextos que obliga. `bloque(:m) { … }` recibe un bloque (`&bloque` en la firma, uno solo, al final); `bloque(:m, proc { … })` recibe un objeto por parámetro. Hacen "lo mismo" por dentro y no son la misma interfaz; la del enunciado es la que se evalúa.

---

**FIN DEL COMPLEMENTO — clase04**
