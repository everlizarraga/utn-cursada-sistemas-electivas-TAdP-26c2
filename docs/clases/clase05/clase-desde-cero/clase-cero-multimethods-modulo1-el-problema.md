# Clase desde cero — Multimethods — Módulo 1: El problema

**Unidad:** clase05 · **Módulo:** 1 de 7 · **Densidad:** 🟡 · **Parte del enunciado:** Introducción

## Sobre este documento

**Qué cubre:** el panorama de la clase (qué vamos a construir y por qué), qué le falta a Ruby, la **introducción del enunciado leída frase por frase** con cada palabra técnica definida en el momento en que aparece, qué queremos poder escribir al final, por qué un `if` no alcanza, y la idea de los **dos momentos**, que es la base de todo lo que sigue.

**Qué NO cubre:** ninguna línea del framework. Acá solo hay Ruby que ya conocés. El framework empieza en el Módulo 2, con la parte 1 del enunciado.

**Tené el enunciado a mano.** Este módulo cita su introducción; los siguientes citan las partes 1, 2 y 3.

## De dónde venís

Se asume sabido de clase03 y clase04:

- una clase es un objeto, y dentro del cuerpo de `class … end` `self` es esa clase;
- un objeto guarda estado en variables `@algo`, y eso vale también para el objeto clase;
- `is_a?` pregunta si un objeto es instancia de una clase o de alguna de sus superclases, o incluye un módulo;
- `instance_methods(false)` lista los métodos que una clase define ella misma.

---

## 1. 🟡 Panorama: qué vamos a construir

> **Regla.** Toda esta clase consiste en resolver el ejercicio "Metaprogramación MultiMethods". No hay tema nuevo: se usa lo de clase03 y clase04 (abrir clases, `define_method`, `self` en cada nivel, `instance_exec`, `respond_to?`) para construir, en menos de 100 líneas, algo que Ruby no trae: **multimétodos**.

Un **multimétodo** es un método con varias implementaciones bajo el mismo nombre, donde la que se ejecuta se elige mirando **los argumentos que llegaron**, en tiempo de ejecución. Ruby elige el método mirando solo a quién le mandaste el mensaje; nosotros le vamos a agregar que mire también con qué.

El enunciado lo pide en tres partes, y cada una es un módulo o dos de esta clase:

| Parte del enunciado | Qué pide | Módulo |
|---|---|---|
| 1. *Partial Blocks* | Un objeto que envuelve un bloque y sabe para qué argumentos vale | M2 |
| 2. *Multi Methods* | `partial_def`, que junta varios de esos bloques bajo un nombre y elige cuál ejecutar | M3, M4, M5 |
| 3. *Nuevo requerimiento* | Que un "tipo" pueda ser una lista de mensajes | M6 |

El código que vamos a escribir es corto, y cada línea tiene una razón. Lo difícil no es la sintaxis: es entender **cuándo** corre cada pedazo, y eso es la sección 6 de este módulo.

---

## 2. 🟡 En Ruby, un método es solo su nombre

> **Regla.** Ruby identifica un método únicamente por su nombre. Dos `def` con el mismo nombre en la misma clase son **el mismo método**: el segundo reemplaza al primero, sin aviso.

```ruby
class Calculadora
  def sumar(a, b)      # primera definición: dos parámetros
    a + b
  end

  def sumar(a)         # segunda definición, mismo nombre: PISA a la anterior
    a + 1
  end
end

p Calculadora.instance_methods(false)
# => [:sumar]        ← hay UN solo método, no dos

p Calculadora.new.sumar(5)
# => 6               ← sobrevivió la segunda definición

Calculadora.new.sumar(5, 3)
# => ArgumentError: wrong number of arguments (given 2, expected 1)
#    la versión de dos parámetros ya no existe
```

**Por qué.** La clase guarda sus métodos en una tabla cuya clave es el nombre. `def sumar` escribe en la entrada `:sumar`; el segundo `def sumar` sobreescribe esa misma entrada. La cantidad de parámetros no forma parte de la clave.

Dos palabras que vas a ver todo el tiempo, definidas acá porque ya aparecieron: un **mensaje** es lo que se le manda a un objeto (`sumar`, con sus argumentos); un **método** es el código que se ejecuta cuando el objeto recibe ese mensaje. Y el nombre del mensaje (`:sumar`) se llama **selector**: es todo lo que Ruby usa para decidir qué método ejecutar.

Anotá esto como el primer dolor: **queremos que dos cuerpos con el mismo nombre convivan**, y Ruby no lo permite con `def`. Se cura en el Módulo 3.

> 🛠️ **Lo que te va a marcar el editor:** RubyMine no marca el segundo `def sumar` como error. Es Ruby válido; que pise al anterior es una decisión del lenguaje, no un descuido tuyo.

---

## 3. 🔴 La introducción del enunciado, frase por frase

La introducción del enunciado tiene tres párrafos y está escrita con vocabulario de teoría de lenguajes. Es corta, pero cada frase usa dos o tres palabras que, sin definir, la vuelven ilegible. Vamos frase por frase, definiendo cada palabra la primera vez que aparece.

### La primera frase: cómo eligen método los lenguajes de objetos

> 📄 **El enunciado dice** (Introducción, primer párrafo):
> *"En la mayoría de los lenguajes de programación orientados a objetos, el mecanismo de dispatch es simple: al momento de compilación se determina la firma del método, y al momento de ejecución se determina la implementación a ejecutar en función del receptor del mensaje."*

Cuatro palabras nuevas, en orden de aparición:

- **Dispatch** es el proceso por el cual un lenguaje decide **qué método ejecutar** cuando un objeto recibe un mensaje. Es una palabra inglesa (despachar: enviar algo a su destino); acá el destino es el método. Cada vez que escribís `objeto.mensaje(args)`, hay un dispatch.
- **Firma** de un método es la lista de tipos de sus parámetros: `sumar(Integer, Integer)` tiene la firma `[Integer, Integer]`. En un lenguaje con tipos declarados, la firma es parte de lo que identifica al método; en Ruby no existe, porque Ruby no declara tipos.
- **Implementación** es el cuerpo concreto que se ejecuta: el código entre `def` y `end`. Un mismo nombre puede tener varias implementaciones (en distintas clases, o, cuando terminemos, en un multimétodo).
- **Receptor** es el objeto que recibe el mensaje: en `tanque.ataca_a(soldado)`, el receptor es `tanque`.

**En criollo:** en la mayoría de los lenguajes, elegir qué método ejecutar se hace en dos etapas. Al compilar, con los tipos declarados, se fija de qué método se está hablando (su nombre y su firma). Al ejecutar, se mira **al receptor** para decidir qué implementación de ese método corre. "Dispatch simple" quiere decir que en ejecución se mira **un solo** objeto: el receptor.

Ruby no tiene etapa de compilación con tipos, así que para Ruby la frase se reduce a la segunda mitad: **en ejecución, Ruby mira al receptor y ejecuta el método que ese receptor tiene bajo ese nombre**. Ya lo conocés:

```ruby
class Soldado
  def saludar; "hola, soy soldado"; end
end

class Tanque
  def saludar; "hola, soy tanque"; end
end

[Soldado.new, Tanque.new].each { |x| puts x.saludar }
# => hola, soy soldado
# => hola, soy tanque
#    mismo mensaje, dos métodos: Ruby eligió mirando al RECEPTOR (x)
```

> 📄 **El enunciado dice** (Introducción, cierre del primer párrafo):
> *"Esto permite lograr el polimorfismo: el método a ejecutar depende del tipo del receptor en ejecución."*

**Polimorfismo** es exactamente lo que muestra el ejemplo: distintos objetos entienden el mismo mensaje, cada uno a su manera, y quien manda el mensaje no necesita saber cuál de ellos tiene enfrente. Es la consecuencia directa del dispatch por receptor.

### La segunda frase: lo que algunos lenguajes hacen distinto

> 📄 **El enunciado dice** (Introducción, segundo párrafo):
> *"Algunos lenguajes como Xtend soportan un mecanismo distinto, conocido como multiple dispatch, y básicamente permite determinar en tiempo de ejecución el método a ejecutar no sólo en función del receptor sino de los parámetros."*

- **Multiple dispatch** (despacho múltiple) es un dispatch que, en ejecución, mira **más de un objeto** para elegir el método: el receptor **y** los argumentos. "Múltiple" se refiere a la cantidad de objetos que participan en la decisión.
- El enunciado dice "parámetros" pero se refiere a los argumentos, y la diferencia importa para todo lo que sigue: un **parámetro** es el nombre que un método o bloque declara para recibir un valor (`def sumar(a, b)` declara dos parámetros: `a` y `b`); un **argumento** es el valor concreto que llega en una llamada (`sumar(5, 3)` pasa dos argumentos: `5` y `3`). Los parámetros existen al definir; los argumentos, al ejecutar. En el multiple dispatch se miran los **argumentos**, porque son los objetos reales.

**En criollo:** hay lenguajes donde, al ejecutar, se mira **también con qué** se mandó el mensaje, y según el tipo de cada argumento se elige una implementación u otra. Ruby no es uno de esos lenguajes.

El caso que Ruby no resuelve, y que da nombre a esta clase. Un tanque ataca distinto según **a quién** ataca:

```
tanque.ataca_a(un_soldado)   # queremos: ametralladora
tanque.ataca_a(otro_tanque)  # queremos: cañón
```

El receptor es el mismo (`tanque`) y el selector es el mismo (`ataca_a`). La única diferencia está en el argumento. Ruby no mira el argumento para elegir el método. Ese es el hueco que vamos a llenar.

> 📄 **El enunciado dice** (Introducción, cierre del segundo párrafo):
> *"Un conjunto de métodos definido con el mismo selector, pero con implementaciones para firmas que difieren es llamado multimethod."*

Esta es la definición que importa, y hay que leerla con cuidado porque la palabra nombra a un **conjunto**, no a cada pieza: un multimethod (multimétodo, la palabra de la sección 1) es **el paquete completo** de implementaciones que comparten un selector y se distinguen por su firma. Cuando `Tanque` tenga una implementación de `ataca_a` para `[Soldado]` y otra para `[Tanque]`, el multimétodo es `ataca_a` entero, con sus dos implementaciones adentro. Cada implementación por separado se va a llamar definición parcial, y se define en la sección 4.

**Sobrecarga contra multimétodo.** Hay una idea parecida que quizás conocés de otros lenguajes (Java, TypeScript) y conviene separar de entrada, porque se confunden:

| | **Sobrecarga** (overloading) | **Multimétodo** |
|---|---|---|
| Cuándo se decide qué implementación corre | Al compilar | Al ejecutar |
| Qué se mira | El **tipo declarado** de los argumentos | El **objeto concreto** que llegó en cada argumento |
| Si la variable está declarada como `Object` pero contiene un `String` | Se elige por `Object` | Se elige por `String` |
| Existe en Ruby | No (Ruby no declara tipos) | No (es lo que vamos a construir) |

La **sobrecarga** es tener varias implementaciones con el mismo nombre y distinta firma, elegidas **al compilar** por los tipos declarados. Se parece al multimétodo en la forma (mismo nombre, varias firmas) y difiere en el fondo: la sobrecarga decide sin ver los objetos; el multimétodo decide con los objetos en la mano.

> 🎯 **Para el parcial, si te preguntan** cuál es la diferencia entre sobrecarga y multimétodo:
> La sobrecarga resuelve qué implementación ejecutar en compilación, a partir de los tipos declarados de los argumentos; el multimétodo lo resuelve en ejecución, a partir de los objetos concretos que recibió. Ruby no tiene ninguna de las dos de forma nativa: elige el método solo por el receptor y por el selector.

> 🕳️ **Madriguera — lenguajes con multimétodos**
> CLOS (el sistema de objetos de Common Lisp), Dylan, Julia y Xtend traen multiple dispatch de fábrica. Ruby no; por eso lo vamos a construir.
> *Volvé al camino — esto se profundiza aparte, otro día.*

### La tercera frase: el objetivo del ejercicio

> 📄 **El enunciado dice** (Introducción, tercer párrafo):
> *"El objetivo de este trabajo práctico es implementar en Ruby un framework que permita definir multimethods a nivel de módulo, llevando el multiple dispatch a Ruby."*

- Un **framework**, acá, es un conjunto de clases y métodos que se agregan a Ruby para que cualquier programa pueda usarlos: no un programa que hace algo, sino una herramienta con la que otros programas definen multimétodos. Nuestro framework es el archivo `multimethods.rb`.
- **A nivel de módulo** quiere decir que el lugar donde se definen los multimétodos es una clase o un módulo (con la sintaxis `partial_def :nombre, [firma] do … end` adentro del cuerpo), y no un objeto suelto ni el programa principal. Se resuelve en el Módulo 3 definiendo `partial_def` en `Module`, que es la clase de la que heredan tanto las clases como los módulos.

**En criollo:** escribir en Ruby las piezas necesarias para que una clase (o un módulo) pueda definir un multimétodo, y para que al mandar el mensaje se elija la implementación mirando los argumentos. Eso es lo que hacen las partes 1, 2 y 3 del enunciado.

Con esto, la introducción está leída. Lo que sigue es lo mismo, pero mirando el código que queremos que exista.

---

## 4. 🔴 Lo que queremos poder escribir

> **Regla.** El objetivo de la unidad es que una clase pueda definir varias implementaciones de un mismo selector, cada una con su firma, y que al recibir el mensaje se ejecute la implementación cuya firma corresponda a los argumentos.

Así se ve el resultado final que vamos a construir. Es el ejemplo con el que abre la parte 2 del enunciado, adelantado acá porque define el contrato de todo. Todavía no existe; si lo ejecutás hoy, falla en la primera línea del cuerpo:

> 📄 **El enunciado dice** (Parte 2, *Multi Methods*, primer bloque de código):

```ruby
class A
  partial_def :concat, [String, String] do |s1, s2|   # firma: dos strings
    s1 + s2
  end

  partial_def :concat, [String, Integer] do |s1, n|   # firma: un string y un entero
    s1 * n
  end

  partial_def :concat, [Array] do |a|                 # firma: un array
    a.join
  end
end
# => NoMethodError: undefined method `partial_def' for A:Class
#    (hoy; al final del Módulo 3 esto anda)

A.new.concat('hello', ' world')          # => 'hello world'       eligió [String, String]
A.new.concat('hello', 3)                 # => 'hellohellohello'   eligió [String, Integer]
A.new.concat(['hello', ' world', '!'])   # => 'hello world!'      eligió [Array]
A.new.concat('hello', 'world', '!')      # => explota: ninguna firma tiene tres argumentos
```

**En criollo, línea por línea:**

- `partial_def` es un mensaje que recibe **la clase** (`A`), dentro de su cuerpo. Todavía no existe en Ruby: lo vamos a definir nosotros. Fijate que el enunciado te muestra **el uso**, no la definición: la definición es tu trabajo.
- Recibe tres cosas: el selector (`:concat`), la firma (una lista de tipos, entre corchetes) y el cuerpo (un bloque, entre `do` y `end`).
- Cada `partial_def` **agrega** una implementación al multimétodo `concat`; no pisa las anteriores. Esto es exactamente lo que `def` no hace (sección 2).
- Después de eso, las instancias de `A` entienden `concat`, y al mandarlo se elige la implementación según los argumentos.

Cada uno de esos bloques con su firma es una **definición parcial**: resuelve el problema solo para una parte del dominio (la parte para la que su firma vale). El multimétodo `concat` es el conjunto de las tres.

---

## 5. 🟡 La forma que ya conocés: un `if` que mira tipos

> **Regla.** Un `if` con `is_a?` resuelve el problema para un conjunto **fijo** de casos que escribís vos. Se queda corto cuando los casos los agrega otra persona, más tarde, sin tocar tu método.

```ruby
class Tanque
  def ataca_a(objetivo)
    if objetivo.is_a?(Tanque)          # ¿es un tanque? → cañón
      "cañonazo a #{objetivo}"
    elsif objetivo.is_a?(Soldado)      # ¿es un soldado? → ametralladora
      "ráfaga a #{objetivo}"
    else                               # cualquier otra cosa: error
      raise ArgumentError, "no sé atacar a #{objetivo.class}"    # también: raise ArgumentError.new("…")
    end
  end

  def to_s; "un tanque"; end
end

class Soldado; def to_s; "un soldado"; end; end
class Avion;   def to_s; "un avión";   end; end

t = Tanque.new
puts t.ataca_a(Soldado.new)   # => ráfaga a un soldado
puts t.ataca_a(Tanque.new)    # => cañonazo a un tanque
t.ataca_a(Avion.new)          # => ArgumentError: no sé atacar a Avion
```

Esto anda. El problema aparece cuando alguien quiere que el tanque también ataque aviones. Para agregar ese caso hay que **reabrir `ataca_a` y reescribir el `if` entero**: si redefinís `ataca_a` con solo el caso del avión, pisás los dos anteriores (sección 2). El método está cerrado.

Con `partial_def`, el mismo pedido se resuelve **sumando** una definición parcial, sin tocar las que ya están:

```ruby
class Tanque
  partial_def :ataca_a, [Avion] do |avion|    # se AGREGA a las firmas existentes
    "misil a #{avion}"
  end
end
```

**Por qué esto es un patrón y no un caso aislado.** Si el `if` que mira tipos aparece en un método, es una solución. Si aparece en veinte métodos, es un patrón que se repite, y los patrones que se repiten se esconden detrás de una construcción del lenguaje. `partial_def` es esa construcción: formaliza el "si recibís tal cosa, hacé esto" para que lo escriba cualquiera, en cualquier clase, de a un caso por vez.

> 🕳️ **Madriguera — el antipatrón *type check***
> Un `if` que pregunta por el tipo de un objeto para decidir qué hacer suele ser una señal de que el comportamiento debería estar en ese objeto (polimorfismo). Acá lo estamos reemplazando por un mecanismo, no defendiendo.
> *Volvé al camino — esto se profundiza aparte, otro día.*

---

## 6. 🔴 Los dos momentos

> **Regla.** El cuerpo de una clase se ejecuta **cuando Ruby lee la clase**. El cuerpo de un método se ejecuta **cuando alguien manda el mensaje**, mucho después. Son dos momentos distintos, con `self` distinto, y el framework tiene que hacer una parte de su trabajo en cada uno.

```ruby
class Guerrero
  puts "momento 1: se está definiendo la clase, self = #{self}"

  def atacar
    puts "momento 2: se ejecuta el método, self = #{self}"
  end

  puts "momento 1: sigue la definición"
end
# => momento 1: se está definiendo la clase, self = Guerrero
# => momento 1: sigue la definición
#    (el cuerpo de atacar NO se ejecutó: solo quedó definido)

puts "la clase ya quedó definida"
# => la clase ya quedó definida

Guerrero.new.atacar
# => momento 2: se ejecuta el método, self = #<Guerrero:0x…>
#    (recién ahora corre el cuerpo del método; self es la instancia, no la clase)
```

| | Momento 1: definición | Momento 2: ejecución |
|---|---|---|
| Cuándo | Al leer `class … end` | Al mandar el mensaje |
| Quién es `self` | La clase (`Guerrero`) | La instancia que recibió el mensaje |
| Qué información hay | Selector, firma y cuerpo de cada definición parcial | Los **argumentos reales**, con sus objetos concretos |
| Qué puede hacer el framework | Guardar las definiciones y crear el método | Elegir cuál definición ejecutar, con los argumentos en la mano |

**Por qué esto es la clave.** `partial_def` corre en el momento 1: en ese instante no hay argumentos, así que **no puede elegir** qué implementación ejecutar. Lo único que puede hacer es **guardar** la firma y el bloque, y **dejar creado** un método que, en el momento 2, busque entre lo guardado y elija. Todo el Módulo 3 es la puesta en práctica de esta frase.

Como la clase es un objeto, puede guardar estado propio, igual que una instancia:

```ruby
class Guerrero
  @cantidad = 0                       # variable de instancia DEL OBJETO CLASE Guerrero

  def self.cantidad;      @cantidad;     end   # lector, definido sobre la clase
  def self.cantidad=(n);  @cantidad = n; end   # escritor, definido sobre la clase
end

Guerrero.cantidad = 3
p Guerrero.cantidad               # => 3
p Guerrero.instance_variables     # => [:@cantidad]   ← vive en la clase
p Guerrero.new.instance_variables # => []            ← las instancias no la ven
```

Ahí va a vivir la información que `partial_def` guarda en el momento 1: **en el objeto clase**, no en las instancias. Cada clase tiene la suya.

> 🎯 **Para el parcial, si te preguntan** por qué `partial_def` no puede ejecutar el bloque que recibe:
> Porque `partial_def` corre durante la definición de la clase, cuando todavía no existe ningún argumento. La elección de implementación necesita los objetos reales, y esos aparecen recién al mandar el mensaje. Por eso `partial_def` guarda y define; la elección ocurre en el método que dejó definido.

---

## Checkpoint del Módulo 1

Contestá por escrito, sin mirar el módulo. Las respuestas se revisan en el chat.

1. ¿Qué queda en `Calculadora.instance_methods(false)` después de dos `def sumar`, y por qué?
2. Definí con tus palabras *dispatch*, *receptor* y *selector*, y ubicá los tres en la llamada `tanque.ataca_a(soldado)`.
3. Explicá qué información tiene el multimétodo en el momento de elegir que la sobrecarga no tiene.
4. ¿Qué diferencia hay entre un parámetro y un argumento? Dá un ejemplo de cada uno con `def sumar(a, b)`.
5. La palabra *multimethod* nombra a un conjunto. ¿Un conjunto de qué? ¿Cómo se llama cada elemento de ese conjunto?
6. En `partial_def :concat, [String, Integer] do |s1, n| … end`, ¿qué es cada uno de los tres elementos que recibe `partial_def`, con los nombres de la materia?
7. ¿Por qué agregar el caso `Avion` al `if` de `Tanque#ataca_a` obliga a reescribir los otros dos casos?
8. ¿Quién es `self` cuando se ejecuta `partial_def`? ¿Y quién es `self` cuando se ejecuta `A.new.concat('a', 'b')`?
9. ¿Por qué la información que guarda `partial_def` tiene que vivir en el objeto clase y no en cada instancia?

## Qué viene en el Módulo 2

La parte 1 del enunciado: *Partial Blocks*. Un objeto que envuelve un bloque junto con su firma y sabe responder si puede ejecutarse con ciertos argumentos. Se llama `PartialBlock`, y lo vamos a escribir de a un método por vez, viendo qué devuelve cada versión incompleta y por qué, hasta que los tres ejemplos del enunciado anden.

**FIN DEL MÓDULO 1**
