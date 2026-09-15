# Apunte maestro — clase04 — `method_missing`, bloques, contextos e `instance_eval`
## Parte 5 — DSLs: una sintaxis propia, y cierre de la unidad

> **Qué cubre esta parte.** Todo lo anterior aplicado: una sintaxis de test que parece otro lenguaje y se explica entera con "cada palabra suelta es un mensaje a `self`" más `instance_eval` en cada nivel; su implementación; por qué se construyen estos lenguajes específicos (DSLs) y un ejemplo que se lee como SQL; las tres cosas que hay que llevarse de la clase; y la información operativa de la cursada.
>
> **De dónde venís.** De toda la unidad. En particular: `respond_to_missing?` y `super` (Parte 1); `&bloque` captura un bloque como `Proc` y `&proc` lo pasa como bloque (Parte 3); el `return` de un proc sale del método donde el proc fue definido (Parte 3 §7); `instance_eval` ejecuta un bloque con otro `self` (Parte 4 §6).
>
> **Código.** Ruby 3.3, `age.rb` de la materia. La gema `colorize` (que agrega `.green`, `.yellow` a los strings) aparece en el framework; si no la tenés instalada, sacá los `.green`/`.yellow` y anda igual.

---

## 1. Una sintaxis que parece otro lenguaje 🔴

Esto es un test escrito con una sintaxis "mágica":

```ruby
test_suite do
  test "Un guerrero tiene la energia con la que se lo instancio" do
    atila = Guerrero.new(20, 100, 10)

    assert(atila.energia == 100)
  end
end
```

Por momentos no parece Ruby. Pero con lo que tenés de la Parte 4 se lee de corrido. Fijate en cada palabra:

- **`test_suite`** es una palabra sola, seguida de `do`. Por la sintaxis de Ruby, o es una variable, o es `self.test_suite`. Y como lleva un `do … end` pegado, es un **mensaje que recibe un bloque**.
- **`test`** lo mismo: `self.test("…") do … end`, un mensaje con un parámetro (el nombre) y un bloque.
- **`atila = Guerrero.new(…)`** es una línea normalita. Nada de magia.
- **`assert`** es `self.assert(…)`.

Con menos azúcar sintáctico (sintaxis más cómoda que no agrega nada nuevo: solo abrevia), la misma cosa es:

```ruby
self.test_suite do
  self.test("Un guerrero tiene la energia con la que se lo instancio") do
    atila = Guerrero.new(20, 100, 10)

    self.assert(atila.energia == 100)
  end
end
```

Y la pregunta que define todo el diseño: **¿quién es `self` en cada una de esas tres líneas?**

Cuando escribís el código en el archivo, `self` es `main` en las tres. Y `main` no sabe qué es `test_suite`:

```ruby
test_suite do end
# => NoMethodError: undefined method `test_suite' for main:Object
```

Para que la primera línea funcione, alguien tiene que contestar `test_suite`. Dos opciones: que **todos los objetos** lo contesten (un método definido suelto en el archivo queda como método privado de `Object`, y todo objeto lo entiende sin receptor), o mandárselo a un **objeto bien conocido**: `MisTest.test_suite do … end`.

Después, adentro del bloque de `test_suite` hay un `self`, y adentro del bloque de `test` hay otro `self`. Con el poder de **elegir quién es `self` en cada bloque** (`instance_eval`), la sintaxis mágica se convierte en esto: instanciar un objeto que sepa contestar `test`, y evaluar el bloque de `test_suite` con `self` = ese objeto. `test` recibe el nombre y otro bloque; ese bloque se evalúa con `self` = un objeto que sabe contestar `assert`; y `assert`, si le pasan `true`, dice que el test salió bien, y si le pasan `false`, que salió mal. Nada más.

```
   archivo suelto                                      self = main
   └─ test_suite do … end                              ← mensaje a main: alguien lo tiene que contestar
        │   (adentro) el bloque se evalúa con         self = un objeto que contesta test
        └─ test "…" do … end                           ← mensaje a ese objeto
             │   (adentro) el bloque se evalúa con    self = un objeto que contesta assert
             └─ assert(…)                              ← mensaje a ese objeto
```

Lo que parecía otro lenguaje termina siendo **solamente envío de mensajes**, combinado con "agarro el bloque y decido quién es su `self`". Eso es lo que sirve para armar un **DSL**.

> **DSL (Domain-Specific Language, lenguaje de dominio específico):** un lenguaje chico, pensado para un problema concreto, que corre sobre el motor de otro lenguaje. Acá, un "lenguaje de tests" que en realidad es Ruby.

---

## 2. La implementación 🟡

En clase quedó planteado el diseño y no el código; el TP va a pedir construcciones de este tipo, así que acá va completo. Dos clases: la **suite**, que junta tests, y el **test**, que corre su bloque y contesta `assert`.

```ruby
require 'colorize'                        # gema que agrega .green, .yellow, etc. a los strings
require_relative 'age'

class TestSuite
  def initialize(&bloque)                 # recibe el bloque de test_suite do … end, capturado como Proc
    @tests = []                           # acá se guardan los tests, en orden, sin ejecutar
    instance_eval(&bloque)                # sin receptor = self.instance_eval, y self acá es la suite que se está creando:
                                          # ejecuta ese bloque con self = esta suite. Adentro, "test" es self.test
  end

  def test(nombre, &bloque)               # cada línea test "…" do … end del DSL llega acá
    @tests << Test.new(nombre, bloque)    # se guarda el test con su bloque. NO se ejecuta todavía.
  end

  def run(print_results = true)           # cuando la suite está completa, se corren todos
    @tests.each do |test|
      test.run(print_results)
    end
  end
end

class Test
  def initialize(nombre, bloque)
    @nombre = nombre                      # el texto que describe el test
    @bloque = bloque                      # el proc con el cuerpo del test, sin ejecutar
    @printing_results = true
  end

  def run(print_results = true)
    @cortar_test = proc { return }        # un proc que hace return: al llamarlo, sale de ESTE run (Parte 3 §7)
    @printing_results = print_results
    puts "-- #{@nombre} --" if @printing_results
    instance_eval(&@bloque)               # self.instance_eval, con self = este test: el cuerpo del test corre con self = el test.
                                          # Adentro, "assert" es self.assert
  end

  def assert(un_bool)
    if un_bool
      puts "Tuki".green if @printing_results
    else
      puts "Assert falló :(".yellow if @printing_results
      @cortar_test.call                   # falla → dispara el proc → return desde run. El resto del test no se ejecuta.
    end
  end
end

def test_suite(&bloque)                   # método suelto: queda en Object, se puede llamar sin receptor desde cualquier lado
  test_suite = TestSuite.new(&bloque)     # crear la suite es evaluar el bloque adentro de ella
  test_suite.run                          # y correr lo que se registró
end
```

Y ahora el test del principio, tal cual, corre:

```ruby
test_suite do
  test "Un guerrero tiene la energia con la que se lo instancio" do
    atila = Guerrero.new(20, 100, 10)
    assert(atila.energia == 100)
  end

  test "dos asserts, el segundo falla y corta" do
    assert(1 == 1)
    assert(2 == 3)
    puts "esto no se imprime"
  end
end
# Resultado esperado (en la terminal, en colores):
# -- Un guerrero tiene la energia con la que se lo instancio --
# Tuki
# -- dos asserts, el segundo falla y corta --
# Tuki
# Assert falló :(
#                                  ← "esto no se imprime" nunca salió: el segundo assert cortó el test
```

**¿CÓMO FUNCIONA?** Paso a paso, con el `self` en cada nivel:

1. `test_suite do … end`: `main` recibe `test_suite` (lo entiende: es un método suelto). Se hace `TestSuite.new(&bloque)`.
2. En `initialize`, `instance_eval(&bloque)` ejecuta el bloque con `self` = la suite nueva. Adentro, `test "…" do … end` es `suite.test("…") do … end`.
3. `suite.test` captura el bloque interno con `&bloque`, lo envuelve en un `Test` y lo agrega a `@tests`. **El cuerpo del test no se ejecutó.** Lo mismo con el segundo `test`.
4. El bloque de `test_suite` terminó. `test_suite.run` recorre `@tests` y llama a `test.run` de cada uno.
5. En `Test#run` se crea `@cortar_test` (nace **en esta ejecución de `run`**, así que su `return` es el `return` de este `run`), se imprime el nombre, y `instance_eval(&@bloque)` corre el cuerpo del test con `self` = el test. Adentro, `assert(…)` es `test.assert(…)`.
6. `assert(true)` imprime "Tuki". `assert(false)` imprime "Assert falló" y hace `@cortar_test.call`: el `return` del proc sale de `assert`, sale de `instance_eval`, y sale de `run`. Lo que quedaba del bloque del test no se ejecuta.

```
  main  ─ test_suite do … end
           │  TestSuite.new → instance_eval(&bloque)            self = suite
           │    suite.test("dos asserts…") { … }                 guarda el proc. No corre.
           │  suite.run
           │    test.run                                          self = test
           │      @cortar_test = proc { return }                  ← nace acá, ligado a ESTE run
           │      instance_eval(&@bloque)                         self = test (el cuerpo del test)
           │        assert(1 == 1)   → Tuki
           │        assert(2 == 3)   → Assert falló → @cortar_test.call
           │          ┃  sale de assert
           │          ┃  sale de instance_eval
           │          ┗━ sale de run                              ← porque el proc nació en run
           │      (puts "esto no se imprime" nunca se alcanza)
```

Tres decisiones de diseño, y por qué:

- **Los tests se guardan como procs y se ejecutan después.** Un bloque es "código para más tarde" (Parte 3). Guardarlos permite conocer la suite completa antes de correr: contar, correr en orden, y más adelante filtrar o informar al final.
- **`instance_eval` en cada nivel.** Es lo que hace que `test` y `assert` se escriban sin receptor, como si fueran palabras del lenguaje. El precio: quien lee el bloque no ve quién es `self`; tiene que saber que "adentro de `test_suite` sos la suite, adentro de `test` sos el test". Es exactamente lo que hacía que la sintaxis pareciera magia.
- **Un proc con `return` para cortar el test.** Es el "defecto" de la Parte 3 §7 usado a favor: `assert` y `run` son métodos distintos, y hace falta que desde adentro de `assert` se corte `run`. Un proc creado en `run` hace justo eso. Tiene que ser **proc** (una lambda retornaría solo de sí misma) y tiene que crearse **en cada `run`** (si naciera en `initialize`, al llamarlo daría `LocalJumpError`: ese método ya terminó). También se podría hacer con excepciones; el proc muestra el mecanismo con lo que ya tenés.

### Testear el framework con el framework

Como `TestSuite.new` recibe el bloque sin correrlo, y `run(false)` corre sin imprimir, una suite puede crearse **adentro de un test de otra suite**, y el test de afuera afirma cosas sobre lo que pasó adentro:

```ruby
test_suite do
  test "una suite de test corre el codigo de sus tests" do
    test_corrio = false                             # variable local de ESTE test…
    mi_test_suite = TestSuite.new do                # …una suite interna…
      test("test trivial") { test_corrio = true }   # …cuyo test la modifica: closure (Parte 3 §8)
    end
    mi_test_suite.run(false)                        # correr sin imprimir
    assert(test_corrio)                             # el assert de AFUERA: self volvió a ser el test externo
  end

  test "un test deberia frenarse al primer assert fallido" do
    ejecuto_mas_alla = false
    mi_test_suite = TestSuite.new do
      test("prueba") do
        assert(false)                               # este assert va al Test INTERNO: corta SU run
        ejecuto_mas_alla = true                     # y esta línea no debería correr
      end
    end
    mi_test_suite.run(false)
    assert(ejecuto_mas_alla == false)               # el test externo verifica que el corte funcionó
  end
end
# Resultado esperado:
# -- una suite de test corre el codigo de sus tests --
# Tuki
# -- un test deberia frenarse al primer assert fallido --
# Tuki
```

Tres cosas pasan a la vez, y las tres son de partes anteriores: cada `assert` va a **su** `Test` (el interno corre con `self` = el test interno por el `instance_eval` de *su* `run`; el externo, con el externo); `TestSuite.new` se puede llamar desde adentro de un test porque es un envío común; y `test_corrio` cruza tres niveles de bloques sin pasarse por parámetro, porque los bloques son closures.

---

## 3. Por qué se construyen DSLs 🔴

Dos ideas de fondo, antes del ejemplo.

**Controlar cuándo se ejecuta un pedazo de código, y cuándo se posterga, es una fuerza elemental.** Especialmente en lenguajes con efecto. Ya lo viste en el framework de colecciones: `map`, `filter`, `forAll`, todo lo que llamaste "orden superior" es la capacidad de escribir un pedazo de código que va a ejecutar **sobre algo que todavía no existe**, y parametrizarlo como si fuera una operación. Mayormente eso se resuelve **parametrizando**: cachos de código que reciben un parámetro, y alguien orquesta la ejecución. El parámetro a veces molesta: cuando querés ejecutar sobre cosas con varios parámetros, o con aridad fija (aridad: la cantidad de parámetros que algo recibe), se vuelve complejo. Diferir la ejecución, jugar con el contexto y elegir quién es `self` abre la puerta a programar cosas como el contador de la Parte 3, con trampas y evoluciones muy interesantes.

**Uno de los focos principales es la construcción de DSLs nativos.** Lenguajes de propósito específico que corren sobre el motor de otro lenguaje, y sirven para dos cosas: simular una sintaxis parecida a la de otra tecnología, para que alguien que la conoce se exprese con facilidad sin aprender esta; o simplemente decir "me gustaría que esto se escriba **así**, porque es lo más claro", y hacerlo posible. Esto es suficientemente importante como para que Ruby haya tomado todas las malas decisiones sobre los bloques (Parte 3) con tal de poder escribir `algo do … end`.

### Un DSL de consulta

Un ejemplo de lo que se puede construir con esto (no lo vamos a implementar):

```ruby
db.query {
  select { nombre & nota }
  from { Alumnos }
  where { nota > 7 }
}
```

Se lee casi como SQL. Y cada pieza está donde puede estar, y en ningún otro lado:

- **`db.query`** es un envío típico: un objeto conocido, `db`, que entiende `query`. Ahí está claro quién entiende qué. Podría hacer que todo lo de adentro ocurra de forma atómica y devolver el resultado.
- **`select`, `from`, `where`** las entiende quien sea que sea `self` adentro del bloque de `query`. Si escribís `select` afuera, no anda: está mal. **Solo se puede escribir adentro de una `query`**, que es el único lugar donde tiene sentido.
- **`nombre`, `nota`** son mensajes a un alumno. ¿A cuál? A uno que todavía no elegiste: lo elegís en la línea del `from`. Y como sabés que vas a usar `Alumnos`, podés usar los campos de alumno adentro de `select` y `where`: el bloque de `where` se va a evaluar **en el contexto de cada alumno**, con `self` = ese alumno, y `nota > 7` es `self.nota > 7`.

Esto **limita la cantidad de lugares donde podés hacer pelotudeces**. `where` es una palabra que solo podés usar donde es aceptable usarla. Toda la magia pasa por atrás, la controla el que armó el DSL, y para vos es transparente: aprendés la sintaxis y listo.

Compará con cómo lo escribirías **sin** manejar contextos: cada bloque tendría que recibir el objeto por parámetro.

```ruby
db.query { |q|
  q.select { |a| a.nombre & a.nota }
  q.from { |t| t.alumnos }
  q.where { |a| a.nota > 7 }
}
```

Un `|q|` acá, un `q.` allá, un `|a|` y un `a.` en cada línea. No parece una gran ganancia. Pero todo va sumando, y rápidamente eso hace compleja la sintaxis y la aleja de lo que querías escribir. Ruby es una tecnología no tipada: cualquier palabra que no sabés que va ahí, nadie te frena. En cualquier tecnología medianamente dinámica, la gente trata de ser lo más expresiva posible, y cualquier pedacito de sintaxis que te podés evitar, lo evitás. Es un gran nicho para jugar con contextos.

---

## 4. Qué llevarse de esta clase 🔴

**1. El TP pide una sintaxis, y cada palabra de esa sintaxis importa.** Muchas veces el enunciado viene con "esta línea se tiene que poder ejecutar". No es lo mismo `db.query` que `query` sola; no es lo mismo `where` con un bloque de un parámetro que `where` con un bloque sin parámetros. El fraseo es literal a propósito: el objetivo es que construyas **exactamente esa interfaz**, y con eso, que lidies con los contextos que esa interfaz obliga. Cualquier otra interfaz que "haga lo mismo" no es aceptable.

**2. Contextos existe, es algo, y está en todos lados.** No es esperable salir de esta clase con un manejo fluido; es una clase dura. Lo que sí hay que llevarse: uno tiene distintos grados de control, según la tecnología, sobre qué es una referencia, cómo se resuelve una palabra, cómo se anidan los contextos y cómo se establece el parentesco entre uno y otro (no siempre es por contención). Y tenés la posibilidad no solo de meter mano, sino de **evaluar cosas que fueron escritas en un contexto, en otro**. Eso no es para que funcione por casualidad: es absolutamente intencional, con la misma intencionalidad que el polimorfismo. Es jugar a que existen reglas de escritura nuevas ("en este bloque, imaginate que estás adentro de tal objeto") y encargarse de que eso se ejecute cómo, cuándo y donde corresponde. Ruby no tiene un mecanismo de puente: instalás mi librería y de pronto pareciera que esto es parte del lenguaje. **Cada vez que ves un `do` o una llave, tenés que estar en control de quién va a ejecutar eso.** A veces no lo sabés, porque se lo estás pasando a alguien que te lo pide así, y entonces no es tu problema. Pero cuando vos definís un bloque, tenés capacidades muy locas.

**3. Combinando esta clase con la anterior, se puede modificar Ruby** de una forma que en cualquier otra tecnología requeriría cambiar el compilador. Podés agarrar una clase, buscar ciertos métodos, y cambiar el comportamiento de un método por otro que estás construyendo ahora, cuyo cuerpo es solamente el `call` a un bloque que tenés en ese contexto. Ese bloque, definido en otro lado, puede llamar al cuerpo original del método, y además hacer cosas **antes y después**, referenciar, pisar, guardar y traer. Podés hacer que un objeto ya no sea `self` donde era `self`; que tenga una interfaz infinita; que los parámetros sean bloques con contexto retenido. Estamos cambiando el tejido de lo que uno consideraba las limitaciones básicas sobre las que se construye lo demás. **Cómo y cuándo hacer esas magias es lo que todavía no aprendiste**: hasta acá fue un paneo de las herramientas. Verlas y sentir que las entendiste porque alguien te las explicó es absolutamente distinto de sentarse con un problema y una hoja en blanco y tener que usarlas. Eso empieza la clase que viene.

---

## 5. Información operativa 🟡

- **El sábado siguiente (12-Sep) no hay clase.** Chequeá el calendario.
- **A partir de la clase siguiente, ejercicios de diseño.** Un problema concreto, una hoja en blanco, y ver cómo se usan estas herramientas desde cero. Dos prácticas, sobre el mismo ejercicio o sobre ejercicios distintos. Hay que **llegar con el ejercicio leído**, y con las preguntas hechas antes de que se resuelva entre todos: ¿qué no sé hacer de esto?, ¿por dónde empezaría?, ¿dónde pondría el primer cacho de código?, ¿qué me está limitando que no entiendo? Solo mirar cómo otros lo resuelven no cumple el objetivo. Además hay videos subidos con otras dos prácticas resueltas.
- **El TP1 ya fue publicado** (durante la semana). Consiste en implementar **aspectos** en Ruby: la programación orientada a aspectos es un paradigma que objetos absorbió, y el enunciado lo explica. No es largo; sí es complejo: hay muchas decisiones (cómo ejecutar la lógica, en qué contexto, cómo extenderla), y nada es trivial. Recomendación de la cátedra: **juntarse a hacerlo**, no repartirlo; lo que más sirve del grupo es la discusión. Si se reparte, que sea para hacerlo todo y después poner en común.
- **Sobre usar IA para programar:** no está prohibido. La advertencia: si esto costó entender, imaginate sentarte ante un TP que hizo otro y tener que extenderlo, sin saber qué contexto es qué. La instancia individual es exactamente eso: extender tu propio TP en el momento. Asegurate de entender lo que está escrito, o la extensión no va a salir.
- **GitHub:** se están creando los grupos y llegan las invitaciones; **aceptarlas lo antes posible porque vencen**. Clonar el proyecto en el ambiente, que ya debería estar funcionando.
- **Discord:** grupos creados, un canal por grupo para preguntarle al docente asignado. El ayudante de cada grupo figura en la planilla de grupos y notas. Recomendación: hacer un *handshake* (saludarse), y anticipar cualquier conflicto con las fechas de corrección (parciales de otras materias, etc.).
- **En lo formal, esta es la última clase teórica de metaprogramación.** Con esto cierra la sección teórica de esta unidad larga, y se llega a la mitad de la materia. Cualquier cosa, escribir por los canales.

---

## Cierre de la unidad: las herramientas, en una tabla

| Quiero… | Herramienta | Parte |
|---|---|---|
| Que un objeto responda mensajes que no tiene definidos | `method_missing` + `super` + `respond_to_missing?` | 1 |
| Un objeto que reciba **todo** y lo reenvíe a otro | `method_missing` sobre una subclase de `BasicObject` | 2 |
| Guardar código para ejecutarlo después | `proc { … }` / `call` | 3 |
| Que un método use el bloque que le pasan | `yield`, o `&bloque` en la firma | 3 |
| Pasar un proc donde se espera un bloque | `&proc` en la llamada | 3 |
| Que una cantidad de argumentos incorrecta falle | `lambda` en vez de `proc` | 3 |
| Cortar un método desde adentro de un bloque | un `proc` con `return`, creado en ese método | 3 / 5 |
| Que un método o una clase vean las variables de afuera | `define_method` / `Class.new` en vez de `def` / `class` | 4 |
| Ejecutar un bloque con `self` = otro objeto | `objeto.instance_eval { … }` / `instance_eval(&proc)` | 4 |
| Lo mismo, pasándole argumentos al bloque | `objeto.instance_exec(args) { \|a\| … }` | 4 |
| Definir un método para un solo objeto desde un bloque | `objeto.instance_eval { def … }` | 4 |
| Definir un método de instancia para una clase desde un bloque | `Clase.class_eval { def … }` | 4 |
| Que `test`, `assert`, `where` se escriban sin receptor | `instance_eval` en cada nivel del DSL | 5 |

---

## Checkpoint de la Parte 5

Sin respuestas.

1. En `test_suite do test "x" do assert(…) end end`, ¿quién es `self` en cada una de las tres líneas cuando escribís el archivo? ¿Y cuando se ejecuta cada bloque? ¿Qué hace que cambie?
2. `test_suite do end` da `NoMethodError` en un archivo vacío. Nombrá las dos formas de que ese mensaje tenga quién lo conteste.
3. ¿Por qué `test` guarda el bloque en vez de ejecutarlo en el momento? Nombrá dos cosas que la suite no podría hacer si lo ejecutara al toque.
4. `@cortar_test.call` se llama desde `assert`, pero sale de `run`. Explicá el mecanismo. ¿Qué pasa si el proc se crea en `initialize`? ¿Y si es una lambda?
5. Hay una suite adentro de un test. ¿A qué `Test` le llega cada `assert`, y por qué no se confunden?
6. ¿Cómo puede un test llamar a `TestSuite.new` o a `test_suite` sin receptor, si no están definidos en `Test`?
7. En el DSL de consulta, ¿por qué `where` solo se puede escribir adentro de `query`? ¿Quién entiende `nota` adentro de `where`, y cómo se logra eso?
8. Reescribí el DSL de consulta pasando todo por parámetro (`|q|`, `|a|`). ¿Qué se gana con la versión sin parámetros y qué se paga?
9. Agregale al framework un `deny(un_booleano)` que sea lo contrario de `assert`. ¿Dónde lo definís? ¿Necesita su propio proc de corte?
10. Escribí, con la técnica de "testear el framework con el framework", un test que verifique que `deny` corta el test cuando el booleano es `true`.
11. El enunciado del TP dice que tiene que poder ejecutarse `algo.bloque(:m) { … }`. Un compañero propone `algo.bloque(:m, proc { … })` porque "es lo mismo". ¿Por qué no es aceptable?

**FIN DE LA PARTE 5**
