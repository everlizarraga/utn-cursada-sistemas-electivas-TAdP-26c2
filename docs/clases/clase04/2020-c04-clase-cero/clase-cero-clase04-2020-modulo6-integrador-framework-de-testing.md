# Clase desde Cero — Clase 04 (2020) — Módulo 6
## Integrador: objetos inline y un framework de testing

> **Sobre este documento.** Junta las tres ideas de la clase construyendo cosas. Primero, dos sintaxis propias para crear objetos y clases sin `class` (`objeto do … end`, `clase do … end`): cuatro líneas cada una. Después, un framework de testing desde cero, en cuatro versiones, cada una con su prueba: guardar tests como procs, ejecutarlos con `instance_eval`, cortar un test que falla con un proc que hace `return`, y testear el framework con el framework. Cierra con una extensión por `method_missing` y el mapa para leer el repo de tu cursada.
> **No cubre:** nada nuevo. Todo lo que aparece está en los módulos 1 a 5. Si una línea no te cierra, el módulo donde se explica está indicado.

> **De dónde venís.** De todo lo anterior. En particular: `&bloque` captura un bloque como `Proc` (4.3); un proc es un closure (4.2); el `return` de un proc sale del método donde el proc fue definido (4.4); `instance_eval` ejecuta un bloque con otro `self` (5.3); `instance_eval` define `def`s en la autoclase, `class_eval` en la clase (5.5); `method_missing` + `respond_to_missing?` (2.3 a 2.5).

---

# Parte A — Objetos y clases inline

## 1. `objeto do … end` 🔴

Objetivo: crear un objeto y definirle métodos en el mismo lugar, sin escribir una clase.

```ruby
pepe = objeto do
  def nombre
    "Pepe"
  end
end

p pepe.nombre    # => "Pepe"
```

Con el módulo 5 esto son cuatro líneas:

```ruby
def objeto(&bloque)          # captura el bloque como proc (módulo 4, sección 3)
  obj = Object.new           # un objeto vacío
  obj.instance_eval(&bloque) # ejecuta el bloque con self = obj: el def se define en la AUTOCLASE de obj (5.5)
  obj                        # devuelve el objeto, ya con sus métodos
end

pepe = objeto do
  def nombre
    "Pepe"
  end
end

p pepe.nombre               # => "Pepe"
p pepe.singleton_methods    # => [:nombre]    ← el método está en #pepe, en ningún otro lado
p pepe.class                # => Object       ← sigue siendo un Object común; lo especial está en su autoclase
```

Eso es todo. La sintaxis `objeto do … end` es un método común que recibe un bloque y lo evalúa en el contexto de un objeto nuevo.

---

## 2. `clase do … end` 🔴

Lo mismo para clases. Y acá vale la pena hacerlo mal dos veces, porque los errores enseñan la tabla de la sección 5.5 mejor que la tabla. (Si corrés los tres intentos en el mismo archivo, Ruby avisa `warning: already initialized constant Persona` al reasignar la constante: es un aviso, no un error.)

**Intento 1: `instance_eval` sobre la clase nueva.**

```ruby
def clase(&bloque)
  clase_nueva = Class.new
  clase_nueva.instance_eval(&bloque)    # self = la clase; los def van a la AUTOCLASE de la clase
  clase_nueva
end

Persona = clase do
  def nombre; "Persona"; end
end

Persona.new.nombre
# => NoMethodError: undefined method 'nombre' for an instance of Persona   ← las instancias no lo tienen
p Persona.nombre    # => "Persona"     ← quedó como MÉTODO DE CLASE (5.5, segunda fila de la tabla)
```

**Intento 2: `instance_eval` sobre una instancia.**

```ruby
def clase(&bloque)
  clase_nueva = Class.new
  clase_nueva.new.instance_eval(&bloque)   # self = UNA instancia; el def va a la autoclase de ESA instancia
  clase_nueva
end

Persona = clase do
  def nombre; "Persona"; end
end

Persona.new.nombre
# => NoMethodError: undefined method 'nombre' for an instance of Persona   ← esta es OTRA instancia; la que tenía el método se perdió
```

**Intento 3, el bueno: `class_eval`.**

```ruby
def clase(&bloque)
  clase_nueva = Class.new
  clase_nueva.class_eval(&bloque)    # self = la clase, y los def van a LA CLASE: métodos de instancia (5.5, tercera fila)
  clase_nueva
end

Persona = clase do
  def nombre; "Persona"; end
end

p Persona.new.nombre                # => "Persona"
p Persona.instance_methods(false)   # => [:nombre]
```

Y ahora que sabés por qué, la versión corta: **`Class.new` ya acepta un bloque y lo evalúa con `class_eval`** (módulo 4, sección 5). O sea que `clase` es exactamente `Class.new`:

```ruby
Persona = Class.new do
  def nombre; "Persona"; end
end
p Persona.new.nombre      # => "Persona"
```

🟢 Una clase creada así no tiene nombre hasta que la asignás a una constante: `Class.new.name` → `nil`. Al hacer `Persona = …`, Ruby le pone el nombre `"Persona"`.

> 🎓 **Para el parcial, si te preguntan:** *¿Por qué `clase` usa `class_eval` y no `instance_eval`?*
> Porque los dos ejecutan el bloque con `self` = la clase, pero difieren en la target class: `instance_eval` define los `def` en la autoclase de la clase (métodos de clase), `class_eval` los define en la clase misma (métodos de instancia). Para que `Persona.new.nombre` funcione, el método tiene que estar en `Persona`.

---

# Parte B — Un framework de testing desde cero

## 3. Lo que queremos escribir 🔴

Un framework de testing te deja escribir esto:

```ruby
test_suite do
  test "el guerrero arranca con 100 de energía" do
    atila = Guerrero.new
    assert atila.energia == 100
  end

  test "un misil lo lastima" do
    atila = Guerrero.new(20, 100, 10)
    Misil.new(50).atacar(atila)
    assert atila.energia == 60
  end
end
# Resultado esperado (en la terminal, en colores):
# PASS el guerrero arranca con 100 de energía
# PASS un misil lo lastima
```

Fijate qué hay ahí: **tres mensajes sin receptor** (`test_suite`, `test`, `assert`), **dos bloques anidados**, y el cuerpo del test se escribe en un lugar pero se ejecuta en otro momento. Sin el azúcar sintáctico, la misma cosa es:

```ruby
self.test_suite do
  self.test("el guerrero arranca con 100 de energía") do
    self.assert(atila.energia == 100)
  end
end
```

Y la pregunta que define todo el diseño es: **¿quién es `self` en cada una de esas tres líneas?** Cuando escribís el código, `self` es `main` en las tres. Pero `main` no sabe qué es `test` ni qué es `assert`. Así que el framework tiene que **cambiar `self`** en cada nivel para que esos mensajes le lleguen a quien corresponde. Eso es `instance_eval`, dos veces.

Vamos a construirlo en cuatro versiones. Cada versión se prueba antes de pasar a la siguiente. Y como todavía no tenemos framework, las primeras pruebas son a mano: `p`, y un `raise` si algo está mal. Todo va en un mismo archivo, con `require 'colorize'` y `require_relative 'age'` arriba de todo; los fragmentos los omiten.

---

## 4. Versión 1: los tests se guardan, no se ejecutan 🔴

Primera decisión de diseño: **cuando escribís un `test`, el test no corre**. Se guarda. Después, cuando la suite está completa, se ejecutan todos. Eso permite contar cuántos hay, correrlos en orden, saltear alguno, informar al final. Un bloque que se guarda para ejecutarse después es un proc (módulo 4, sección 1).

```ruby
class Test
  attr_reader :nombre

  def initialize(nombre, contenido)
    @nombre = nombre          # el texto que describe el test
    @contenido = contenido    # el proc con el cuerpo del test, sin ejecutar
  end

  def run
    @contenido.call           # recién acá se ejecuta
  end
end

class TestSuite
  def initialize
    @tests = []               # la lista donde se guardan los tests, en orden
  end

  def test(nombre, &contenido)               # &contenido: el bloque del test, capturado como proc (4.3)
    @tests << Test.new(nombre, contenido)    # se guarda. No se ejecuta.
  end

  def run
    @tests.each { |t| t.run }                # ahora sí, uno por uno, en orden
  end
end

def test_suite(&bloque)          # método de nivel superior: se puede llamar sin receptor desde cualquier lado
  suite = TestSuite.new
  suite.instance_eval(&bloque)   # ejecuta el bloque con self = suite: adentro, "test" es suite.test
  suite.run                      # cuando el bloque terminó de registrar tests, los corre
end
```

**¿CÓMO FUNCIONA?** Paso a paso, con la suite de la sección 3:

1. `test_suite do … end`: `main` recibe `test_suite` con el bloque. Se crea una `TestSuite` vacía.
2. `suite.instance_eval(&bloque)`: el bloque se ejecuta con `self = suite`. Adentro, la línea `test "…" do … end` es `suite.test("…") do … end`.
3. `suite.test` captura el bloque interno con `&contenido`, lo envuelve en un `Test` y lo agrega a `@tests`. **El cuerpo del test no se ejecutó.**
4. Lo mismo con el segundo `test`. Ahora `@tests` tiene dos.
5. El bloque de `test_suite` terminó. `suite.run` recorre `@tests` y hace `call` a cada proc.

El mismo camino, dibujado, con el `self` en cada nivel:

```
   archivo suelto                                       self = main
   └─ test_suite do … end                               ← mensaje a main (lo entiende: es un método suelto)
        │   suite.instance_eval(&bloque)                self = suite
        └─ test "primero" do … end                      ← mensaje a suite: GUARDA el proc, no lo corre
             │   (más tarde) suite.run → test.run → @contenido.call
             │                                          self = suite (el proc nació acá adentro: se llevó ese self)
             └─ ejecutado = true                        ← variable de afuera: closure
```

Probémoslo sin framework:

```ruby
ejecutado = false
orden = []

test_suite do
  test "primero" do
    ejecutado = true      # variables locales de afuera: el proc es un closure, las ve y las modifica (4.2)
    orden << 1
  end
  test "segundo" do
    orden << 2
  end
end

p ejecutado                                # => true      ← los tests corrieron
p orden                                    # => [1, 2]    ← en orden
raise "el test no corrió" unless ejecutado  # raise lanza un error con ese texto y corta el programa: si pasa, la v1 está rota
```

Funciona. Y ya usaste closures a favor: `ejecutado` y `orden` nacieron afuera, los tests las modificaron.

---

## 5. Versión 2: `assert`, y un problema de `self` 🔴

Ahora `assert`. ¿Dónde lo definimos? Depende de quién es `self` adentro del cuerpo de un test. Preguntémosle:

```ruby
test_suite do
  test "quién soy" do
    p self.class         # => TestSuite
  end
end
```

Es la **suite**. Tiene sentido: el bloque del test se *escribió* adentro del `instance_eval` de la suite, así que nació con `self = suite`, y `@contenido.call` lo ejecuta con ese `self` (módulo 5, sección 2). Podríamos definir `assert` en `TestSuite` y andaría. Pero está mal ubicado: un `assert` pertenece a *un test*, no a la suite; es el test el que pasa o falla. Así que cambiamos cómo se ejecuta el cuerpo: con `instance_eval` sobre el `Test`, para que `self` sea el test.

```ruby
class Test
  def run
    instance_eval(&@contenido)    # el cuerpo del test corre con self = este Test (5.3)
  end                             # (instance_eval sin receptor = self.instance_eval, y self acá es el Test)

  def assert(un_booleano)
    if un_booleano
      puts "PASS #{@nombre}".green    # colorize (módulo 1, sección 10)
    else
      puts "FAIL #{@nombre}".red
    end
  end
end
```

```ruby
test_suite do
  test "quién soy ahora" do
    p self.class                    # => Test     ← cambió
  end
  test "arranca con 100" do
    atila = Guerrero.new
    assert atila.energia == 100     # assert sin receptor → self.assert → Test#assert
  end
  test "dos asserts" do
    assert 1 == 1
    assert 2 == 3
    puts "esto corre igual, y no debería"
  end
end
# Resultado esperado:
# Test
# PASS arranca con 100
# PASS dos asserts                          ← imprimió PASS...
# FAIL dos asserts                          ← ...y después FAIL, por el mismo test
# esto corre igual, y no debería            ← y siguió ejecutando después de fallar
```

Dos problemas, ambos en el tercer test. Un test con dos `assert` informa dos veces: el resultado debería ser **uno por test**, al final. Y peor: **un `assert` que falla no detiene el test**. Todo lo que sigue corre igual, sobre un estado que ya sabemos que está mal.

Lo que hace falta: que `assert`, cuando falla, **salga de `run` en ese instante**, saltándose el resto del cuerpo. `assert` es un método; `run` es otro. Necesitamos algo que, desde adentro de `assert`, corte `run`.

---

## 6. Versión 3: cortar el test con un proc que hace `return` 🔴

Módulo 4, sección 4: el `return` de un proc sale **del método donde el proc fue definido**, atravesando lo que haya en el medio. Si creamos un proc adentro de `run` y lo llamamos desde `assert`, su `return` sale de `run`. Era el "defecto" del hilo abierto; acá es la herramienta.

```ruby
class Test
  attr_reader :nombre

  def initialize(nombre, contenido)
    @nombre = nombre
    @contenido = contenido
  end

  def run
    @cortar_test = proc { return :fail }   # nace ADENTRO de run: su return es el return de run, y devuelve :fail
    instance_eval(&@contenido)             # corre el cuerpo. Si algún assert falla, @cortar_test.call sale de run acá mismo
    :pass                                  # si llegamos a esta línea, ningún assert cortó: el test pasó
  end

  def assert(un_booleano)
    @cortar_test.call unless un_booleano   # falla → dispara el proc → return :fail desde run. Nada más se ejecuta.
  end
end
```

Ahora `Test#run` **devuelve** `:pass` o `:fail`, y no imprime nada. Imprimir es responsabilidad de la suite, que tiene la lista completa:

```ruby
class TestSuite
  def initialize
    @tests = []
  end

  def test(nombre, &contenido)
    @tests << Test.new(nombre, contenido)
  end

  def run(imprimir: true)                                   # imprimir: parámetro con nombre y valor por defecto
    resultados = @tests.map { |t| [t.nombre, t.run] }       # [[nombre, :pass], [nombre, :fail], ...] (map: módulo 1)
    if imprimir
      resultados.each do |nombre, resultado|                # |nombre, resultado| desarma cada par
        puts(resultado == :pass ? "PASS #{nombre}".green : "FAIL #{nombre}".red)
      end
    end
    resultados                                              # y devuelve la lista, para quien la quiera
  end
end

def test_suite(imprimir: true, &bloque)
  suite = TestSuite.new
  suite.instance_eval(&bloque)
  suite.run(imprimir: imprimir)
end
```

Probemos, con un test que falla a propósito y una línea después del `assert`:

```ruby
corrio_despues = false

resultados = test_suite do
  test "arranca con 100" do
    atila = Guerrero.new
    assert atila.energia == 100
  end
  test "un misil lo lastima" do
    atila = Guerrero.new(20, 100, 10)
    Misil.new(50).atacar(atila)
    assert atila.energia == 60
  end
  test "falla y se corta" do
    assert 2 == 3
    corrio_despues = true              # ← si el corte funciona, esta línea no se ejecuta
  end
end
# Resultado esperado:
# PASS arranca con 100
# PASS un misil lo lastima
# FAIL falla y se corta

p resultados        # => [["arranca con 100", :pass], ["un misil lo lastima", :pass], ["falla y se corta", :fail]]
p corrio_despues    # => false    ← el assert cortó el test. La línea de abajo nunca corrió.
```

**¿CÓMO FUNCIONA?** El camino del tercer test, con el `self` en cada paso:

```
  main  ─ test_suite do … end
           │  suite.instance_eval(&bloque)                      self = suite
           │    suite.test("falla y se corta") { … }              guarda el proc. No corre.
           │  suite.run
           │    test.run                                          self = test
           │      @cortar_test = proc { return :fail }             ← nace acá, ligado a ESTE run
           │      instance_eval(&@contenido)                      self = test (el cuerpo del test)
           │        assert(2 == 3)   →  Test#assert
           │          @cortar_test.call                            ← return :fail... ¿de dónde?
           │            ┃  sale de assert
           │            ┃  sale de instance_eval
           │            ┗━ sale de run, devolviendo :fail          ← porque el proc nació en run
           │      (":pass" nunca se alcanza; "corrio_despues = true" tampoco)
           │    resultados << ["falla y se corta", :fail]
```

⚠️ **Trampa 1: crear el proc en `initialize`.** Parece más prolijo, y rompe todo:

```ruby
class TestMal
  def initialize(contenido)
    @contenido = contenido
    @cortar = proc { return :fail }    # nace en initialize; su return es el return de initialize
  end
  def run
    instance_eval(&@contenido)
    :pass
  end
  def assert(b)
    @cortar.call unless b
  end
end

TestMal.new(proc { assert false }).run
# => LocalJumpError: unexpected return     ← initialize ya terminó hace rato. No hay a dónde volver (4.4).
```

El proc tiene que nacer **en cada `run`**, porque el `return` está ligado a *esa ejecución* del método.

⚠️ **Trampa 2: usar una lambda.** Compila, corre, y no corta nada:

```ruby
class TestLambda                        # initialize y assert iguales a los de TestMal
  def run
    @cortar = lambda { return :fail }   # el return de una lambda sale de la LAMBDA, no de run
    instance_eval(&@contenido)
    :pass
  end
end

TestLambda.new(proc { assert false; puts "sigo después del assert" }).run
# => sigo después del assert     ← la lambda devolvió :fail a assert, assert lo ignoró, el test siguió
#    :pass                       ← y encima reporta que pasó
```

Es la diferencia 2 entre proc y lambda, con consecuencias. Acá hace falta **específicamente** un proc.

> 🎓 **Para el parcial, si te preguntan:** *¿Cómo hacés que un `assert` que falla detenga el test, si `assert` y `run` son métodos distintos?*
> Con un proc creado dentro de `run` que haga `return`. El `return` de un proc sale del método donde el proc fue definido, así que llamarlo desde `assert` sale de `run` aunque `assert` esté en el medio. Tiene que ser un proc (una lambda retornaría solo de sí misma) y tiene que crearse en cada ejecución de `run` (si el método donde nació ya terminó, da `LocalJumpError`).

> 🕳️ **Madriguera — cómo lo hacen los frameworks reales**
> RSpec y Minitest cortan el test lanzando una excepción (`raise`) que el runner atrapa (`rescue`). Es el mismo efecto con otra herramienta, y es lo que usarías en un proyecto real. El proc con `return` es la versión que muestra el mecanismo de closures; las excepciones son otra clase.
> *Volvé al camino — esto se profundiza aparte, otro día.*

---

## 7. Versión 4: testear el framework con el framework 🔴

Hasta acá probamos con `p` y `raise`. Pero ya tenemos un framework. Y como `test_suite` devuelve los resultados sin imprimir si se lo pedís, **una suite puede correr adentro de un test de otra suite**, y el test de afuera afirma cosas sobre los resultados de la de adentro:

```ruby
test_suite do
  test "un test que falla no sigue ejecutando" do
    corrio = false
    resultados = test_suite(imprimir: false) do   # suite INTERNA, silenciosa
      test "interno" do
        assert false                              # este assert corta el test interno
        corrio = true                             # y esta línea no debería correr
      end
    end
    assert !corrio                                # assert de AFUERA: el test interno se cortó
    assert resultados == [["interno", :fail]]     # y reportó :fail
  end

  test "un test que pasa devuelve :pass" do
    resultados = test_suite(imprimir: false) do
      test "interno" do
        assert true
      end
    end
    assert resultados == [["interno", :pass]]
  end

  test "los tests corren en orden" do
    orden = []
    test_suite(imprimir: false) do
      test "a" do orden << :a end
      test "b" do orden << :b end
    end
    assert orden == [:a, :b]
  end
end
# Resultado esperado:
# PASS un test que falla no sigue ejecutando
# PASS un test que pasa devuelve :pass
# PASS los tests corren en orden
```

Los niveles, con quién es `self` en cada uno al momento de correr:

```
   main
   └─ test_suite do                                  self = suite EXTERNA
        └─ test "un test que falla…" do              self = Test EXTERNO   (instance_eval de su run)
             ├─ corrio = false
             ├─ test_suite(imprimir: false) do       ← mensaje al Test externo: es un Object, lo entiende
             │    │                                  self = suite INTERNA
             │    └─ test "interno" do               self = Test INTERNO   (instance_eval de SU run)
             │         ├─ assert false               → Test INTERNO #assert → su @cortar_test → corta run interno
             │         └─ corrio = true              (nunca se ejecuta)
             ├─ assert !corrio                       → Test EXTERNO #assert (self volvió a ser el externo)
             └─ assert resultados == […]             → Test EXTERNO #assert
```

Tres cosas están pasando a la vez, y las tres son de módulos anteriores:

- **Los `assert` van cada uno a su `Test`.** El `assert false` de adentro corre con `self` = el test interno (por el `instance_eval` de *su* `run`); el `assert !corrio` de afuera, con `self` = el test externo. Dos `@cortar_test` distintos, cada uno ligado a su `run`.
- **`test_suite` se puede llamar desde adentro de un test** porque es un método de nivel superior: los métodos definidos sueltos en un archivo quedan como métodos privados de `Object`, y un `Test` es un `Object`. Sin receptor, `self.test_suite` funciona desde cualquier objeto.
- **`corrio` y `orden` cruzan tres niveles de bloques** sin pasarse por parámetro. Closures.

---

## 8. Extensión: `assert` por convención, con `method_missing` 🟡

El framework usa las ideas 2 y 3 de la clase. La idea 1 entra con una extensión chica. Escribir `assert atila.energia == 100` está bien; escribir `assert_energia atila, 100` se lee mejor. No vamos a definir un `assert_<atributo>` por cada atributo posible: los atendemos por convención (módulo 2, sección 3).

```ruby
class Test
  private def method_missing(name, *args)                       # cae acá cualquier mensaje que Test no tenga
    if name.start_with?("assert_") && args.size == 2            # de los nuestros: assert_<atributo>(objeto, esperado)
      atributo = name.to_s.delete_prefix("assert_").to_sym      # "assert_energia" → :energia
      objeto, esperado = args                                    # desarma el array en dos variables
      assert objeto.send(atributo) == esperado                  # y lo reduce al assert que ya tenemos
    else
      super                                                      # no es nuestro: que falle como siempre (2.4)
    end
  end

  def respond_to_missing?(name, include_private = false)        # el contrato (2.5)
    name.start_with?("assert_") || super
  end
end

test_suite do
  test "assert por convención" do
    atila = Guerrero.new(20, 100, 10)
    assert_energia atila, 100
    assert_potencial_ofensivo atila, 20
    Misil.new(50).atacar(atila)
    assert_energia atila, 60
  end
  test "y falla cuando corresponde" do
    assert_energia Guerrero.new, 5
  end
end
# Resultado esperado:
# PASS assert por convención
# FAIL y falla cuando corresponde
```

Un error de tipeo en un test (`sarasa` en vez de `assert`) sube por `super` y explota con `NameError`, cortando la corrida. Eso está bien: un test roto no es un test que falla, es un test que no se pudo ejecutar, y tiene que gritar.

---

## 9. El framework completo, y el mapa con el repo de tu cursada 🟡

El código final, todo junto, para copiarlo y correrlo:

```ruby
require 'colorize'
require_relative 'age'       # para los tests que usan Guerrero y Misil

class Test
  attr_reader :nombre

  def initialize(nombre, contenido)
    @nombre = nombre
    @contenido = contenido
  end

  def run
    @cortar_test = proc { return :fail }
    instance_eval(&@contenido)
    :pass
  end

  def assert(un_booleano)
    @cortar_test.call unless un_booleano
  end

  private def method_missing(name, *args)
    if name.start_with?("assert_") && args.size == 2
      atributo = name.to_s.delete_prefix("assert_").to_sym
      objeto, esperado = args
      assert objeto.send(atributo) == esperado
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    name.start_with?("assert_") || super
  end
end

class TestSuite
  def initialize
    @tests = []
  end

  def test(nombre, &contenido)
    @tests << Test.new(nombre, contenido)
  end

  def run(imprimir: true)
    resultados = @tests.map { |t| [t.nombre, t.run] }
    if imprimir
      resultados.each do |nombre, resultado|
        puts(resultado == :pass ? "PASS #{nombre}".green : "FAIL #{nombre}".red)
      end
    end
    resultados
  end
end

def test_suite(imprimir: true, &bloque)
  suite = TestSuite.new
  suite.instance_eval(&bloque)
  suite.run(imprimir: imprimir)
end
```

El `6_framework_tests.rb` del repo de tu cursada es este mismo diseño con otros nombres y un par de decisiones distintas. Para leerlo de corrido:

| Acá | En el repo | Nota |
|---|---|---|
| `test_suite` crea la suite y hace `suite.instance_eval(&bloque)` | `TestSuite#initialize(&bloque)` hace el `instance_eval` adentro del constructor | mismo efecto; el repo lo mete en `new` |
| `TestSuite#run(imprimir:)` | `TestSuite#run(print_results = true)` | parámetro posicional, no con nombre |
| `Test#run` devuelve `:pass`/`:fail`, la suite imprime al final | `Test#run(print_results)` imprime `-- nombre --` y cada `assert` imprime por su cuenta | el repo informa **por assert** (`"Tuki".green` / `"Assert falló :(".yellow`), no por test |
| `@cortar_test = proc { return :fail }` | `@cortar_test = proc { return }` | igual; el comentario del repo dice "se podría hacer con excepciones también" |
| `assert` en `Test` | `assert` en `Test` | igual |
| `imprimir: false` para las suites internas | `print_results = false`, que `Test#run` guarda en `@printing_results` | mismo rol |
| `assert_<atributo>` | no está | extensión nuestra |

---

## 10. Por qué está diseñado así 🟡

Lo que se evalúa no es que funcione, sino saber qué decidiste y qué pagaste.

**Los tests se guardan como procs y se ejecutan después.** Porque el framework necesita conocer la suite completa antes de correr: para informar al final, para correr en orden, para poder saltear o filtrar. Un bloque reificado es exactamente "código para después". Precio: el estado del programa al *ejecutar* puede no ser el mismo que al *escribir*; con closures compartiendo variables entre tests, un test puede pisar a otro sin querer.

**`instance_eval` en cada nivel.** Porque queremos que `test` y `assert` se escriban sin receptor, como si fueran palabras del lenguaje. Eso se llama construir un DSL (un lenguaje específico para un dominio). Precio: quien lee el bloque no ve quién es `self`; hay que saber que "adentro de `test_suite` sos la suite, adentro de `test` sos el test". Es exactamente lo que hacía que la sintaxis pareciera magia antes de este módulo.

**Un proc con `return` para cortar.** Porque muestra el mecanismo de los closures y no requiere nada más. Precio: es frágil (tiene que crearse en `run`, tiene que ser proc), y en un framework real usarías excepciones.

**`method_missing` para los `assert_*`.** Porque la familia es abierta: no sabés de antemano qué atributos van a querer afirmar. Precio: el de siempre (módulo 2, sección 8): interfaz invisible, dos lookups, y la obligación de `respond_to_missing?` y `super`.

---

## 11. Las tres ideas, en el framework 🔴

| Idea | Dónde está en el framework |
|---|---|
| **1. Recepción dinámica de mensajes** | `Test#method_missing` atiende `assert_<atributo>` por convención y delega el resto a `super`. |
| **2. El bloque como objeto con su contexto** | `test(nombre, &contenido)` reifica el cuerpo del test y lo guarda. Al correr, el proc sigue viendo `corrio`, `orden`, `atila`. `@cortar_test` es un proc cuyo `return` está ligado a `run`. |
| **3. Cambiar el `self` de un bloque** | `suite.instance_eval(&bloque)` hace que `test` le llegue a la suite; `instance_eval(&@contenido)` hace que `assert` le llegue al test. Y en la Parte A: `instance_eval` para `objeto`, `class_eval` para `clase`. |

Si podés explicar cada fila de esa tabla con tus palabras, la clase está entendida.

---

## Checkpoint del Módulo 6

Sin respuestas.

1. Escribí `objeto do … end` de memoria. ¿Dónde quedan los métodos que se definen adentro? ¿Por qué `Object.new` y no `Class.new`?
2. En `clase`, el intento con `instance_eval` produjo un método de clase en vez de uno de instancia. Explicalo con la tabla de target class del módulo 5.
3. ¿Por qué `Class.new do … end` es equivalente a nuestro `clase do … end`? ¿Qué hace `Class.new` con el bloque?
4. En `test_suite do test "x" do … end end`, ¿quién es `self` adentro del bloque de `test_suite`? ¿Y adentro del bloque de `test`, en la v1? ¿Y en la v2? ¿Qué cambió y por qué?
5. ¿Por qué `test` guarda el bloque en vez de ejecutarlo? Nombrá dos cosas que el framework no podría hacer si lo ejecutara al toque.
6. `@cortar_test.call` se llama desde `assert`, pero sale de `run`. Explicá el mecanismo. ¿Qué pasa si el proc se crea en `initialize`? ¿Y si es una lambda?
7. En la v4, hay una suite adentro de un test. ¿A qué `Test` le llega cada `assert`, y por qué no se confunden?
8. ¿Cómo puede un `Test` llamar a `test_suite` sin receptor, si `test_suite` no está definido en `Test`?
9. Agregale al framework un `deny(un_booleano)` que sea lo contrario de `assert`. ¿Dónde lo definís? ¿Necesita su propio proc de corte?
10. Escribí un test que verifique que `deny` corta el test cuando el booleano es `true`, usando la técnica de la v4.
11. ¿Qué te da y qué te cuesta `instance_eval` en un DSL como este? ¿Cómo se lo explicarías a alguien que lee `test "x" do assert … end` por primera vez?

---

## Cómo seguir

Con esto termina la clase desde cero. Lo que corresponde ahora, en orden:

1. **Abrí el repo de tu cursada** y leé los archivos de `src/` de corrido, del `1_registrador_de_mensajes.rb` al `6_tests.rb`, con el mapa de la sección 9 al lado. Ojo que el 6 son dos archivos: `6_framework_tests.rb` es el framework (contra ese está hecho el mapa) y `6_tests.rb` son los tests que lo usan. Si alguna línea no te cierra, este es el módulo donde está explicada: archivo 1 → módulo 2 · archivo 2 → módulos 3 y 4 · archivo 3 → módulo 4 · archivo 4 → módulo 5 · archivos 5 y 6 → módulo 6.
2. **Corré los checkpoints** de los seis módulos en la consola. Las respuestas se arman en el complemento cuando cerremos la unidad.
3. **Practicá escribiendo**, no leyendo: reescribí `objeto`, `clase` y el framework de memoria, y agregales `deny`. Cuando te salga sin mirar, ya está.

**FIN DEL MÓDULO 6**
