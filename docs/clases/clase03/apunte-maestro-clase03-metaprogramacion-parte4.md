# 📘 Apunte Maestro — Clase 03: Metaprogramación en Ruby

## Parte 4 — Self-modification: modificar el programa en marcha

**Materia:** Técnicas Avanzadas de Programación (TAdP) · **Unidad:** clase03 · **Clase del:** 29/08/2026

> **Serie completa:** Parte 0 (entorno) · Parte 1 (qué es metaprogramar) · Parte 2 (introspection) · Parte 3 (method lookup y métodos como objetos) · **Parte 4 (self-modification)** · Parte 5 (el metamodelo) · Parte 6 (autoclases y cierre).
> Sesión nueva de la consola: `age-clase2.rb` cargado, `atila = Guerrero.new` y `conan = Guerrero.new` recién creados. En esta parte vas a romper la consola a propósito; cuando pase, `exit` y volvé a entrar (Parte 0, sección 6).

---

## 1. La línea que no existe 🟡

En la Parte 1 separamos reflection en dos familias: las herramientas que **consultan** (introspection) y las que **modifican** (self-modification). Hasta acá estuvimos del lado de consultar. Ahora cruzamos.

Pero no nos pongamos rígidos con eso, porque la separación es mentira. Cuando hicimos `instance_variable_set` en la Parte 2 cambiamos el estado de un objeto desde afuera: ¿eso era consultar? ¿Ya habíamos cruzado la línea? No importa. Esa línea es como un río que hace de frontera entre dos países: cambia de curso y el límite se mueve con él. No sirve para decidir en qué categoría cae cada cosa.

Lo que sí es cierto es que **de acá en adelante nos metemos en cambios agresivos sobre la definición de las cosas**, y que hay muchas más tecnologías que admiten lo que hicimos hasta ahora que lo que viene. Java, por ejemplo, hace fácil todo lo de las Partes 2 y 3, y hace muy difícil esto.

---

## 2. Open classes: reabrir una clase que ya existe 🔴

Empecemos por el caso más directo. En Ruby, `class Algo ... end` no significa "creá la clase Algo". Significa **"abrí la clase Algo"**: si no existe, la crea; si ya existe, la abre y lo que escribas adentro se agrega. Cualquier clase. Incluso las del lenguaje:

```ruby
class String                       # String ya existe: la estamos ABRIENDO, no creando
  def importante
    self + '!'                     # self es el string que recibe el mensaje
  end
end
# => :importante

'aprobe'.importante
# => "aprobe!"
"cualquier string".importante
# => "cualquier string!"           ← TODOS los strings lo entienden ahora
```

`importante` no existía en `String`. Abriste la clase, lo definiste, y a partir de ese momento cualquier string del programa lo entiende. El programa se modificó a sí mismo mientras corría. Eso, en Java, es lo que en la Parte 1 requería matar el ClassLoader.

### Es retroactivo

Ahora fijate en `conan`, que **ya existía** antes de que abriéramos nada:

```ruby
class Guerrero
  def comete_un_pollo
    self.energia += 100
  end
end
# => :comete_un_pollo

conan.comete_un_pollo
# => 200                           ← conan ya estaba creado y lo entiende igual
```

No hizo falta crear un guerrero nuevo. `conan` fue instanciado antes de que `comete_un_pollo` existiera, y lo entiende. Esto debería ser obvio con lo que ya sabés del method lookup: **los objetos no tienen métodos adentro; los van a buscar a su clase.** El primer paso del lookup es el paso azul, directo a la clase, sin mirar nada en el objeto. Entonces cualquier cosa que le agregues a la clase está automáticamente disponible para todas sus instancias, viejas y nuevas. No hay nada que actualizar en los objetos, porque nunca tuvieron nada.

Alguien se va a preguntar: "si los métodos van a la clase, ¿y si yo quiero agregarle un método a `atila` directamente, y no a todos los guerreros?". Buena pregunta. Esperá a la Parte 6.

### Se puede pisar, y es destructivo

Si definís un método con un nombre que **ya existe** en esa clase, el nuevo **reemplaza** al anterior. No lo extiende, no lo encadena: lo pisa, y el anterior desaparece.

```ruby
class Guerrero
  def descansar                    # descansar YA EXISTE en Guerrero
    self.energia += 1000
  end
end

atila.descansar
# => 1100                          ← el descansar original (atacante + defensor) ya no existe
```

Y acá hay algo que en Ruby es distinto de otros lenguajes que conozcas, y que hay que tener muy claro: **para Ruby, la firma de un método es solo su nombre.** En otras tecnologías la firma incluye el nombre, la cantidad de parámetros, a veces sus tipos y el orden; dos métodos con el mismo nombre y distinta cantidad de parámetros son dos métodos distintos. En Ruby no. Mismo nombre, distinto parámetro: **es el mismo método**, y lo pisás.

```ruby
class Guerrero
  def descansar(cuanto)            # mismo nombre, ahora con un parámetro
    self.energia += cuanto
  end
end

atila.descansar
# ArgumentError: wrong number of arguments (given 0, expected 1)
#   ← el descansar sin parámetros ya no existe: fue pisado por el que recibe uno

atila.descansar(5)
# => 1105
```

Y como el orden en que escribís las cosas es el orden en que Ruby las evalúa, **siempre gana la última definición**. Si en un archivo definís `descansar` arriba y lo volvés a definir más abajo, la de abajo pisa a la de arriba. Ruby es un lenguaje profundamente imperativo en esto.

*(Para recuperar el `descansar` original: `exit` y volvé a cargar. Todo lo que hiciste en la sesión desaparece; el archivo no se tocó.)*

> **Para el parcial, si te preguntan:** *¿Qué es una open class? ¿Qué pasa con las instancias que ya existían?*
> En Ruby, `class X ... end` sobre una clase que ya existe la reabre y agrega lo que se defina adentro, incluso para clases del lenguaje como `String`. Las instancias ya creadas ven el cambio inmediatamente, porque los objetos no guardan métodos: los buscan en su clase en cada envío de mensaje. Si se define un método con un nombre que ya existía, se reemplaza de forma destructiva; como la firma en Ruby es solo el nombre, un método con el mismo nombre y distinta cantidad de parámetros pisa al anterior.

---

## 3. Con poder viene la responsabilidad: romper el lenguaje 🔴

Si podés abrir `String`, podés abrir cualquier cosa. Y "cualquier cosa" incluye lo que Ruby necesita para funcionar. Averigüemos de qué clase son los números, con lo que ya sabemos:

```ruby
2.class
# => Integer
```

Ahora abramos `Integer` y redefinamos la suma:

```ruby
class Integer
  def +(otro)                      # + es un método común, con nombre "+"
    123
  end
end

2 + 2
# => 123
```

Y acá **la consola se murió**. Vas a ver que el número de línea del prompt deja de avanzar, que las respuestas aparecen o no aparecen, que nada anda bien. ¿Por qué? Porque Pry está escrito en Ruby y corre **adentro del mismo Ruby** que vos acabás de modificar. Para calcular el número de línea del prompt, Pry suma uno. Vos le cambiaste lo que significa sumar. Todo lo que en Ruby suma —incluida la herramienta que te muestra la consola— ahora devuelve 123.

No hay forma de arreglarlo desde adentro (cómo sacar un método es tema de la clase que viene, y en este estado ni eso te serviría). `exit`, y volvés a entrar limpio. No rompiste tu instalación; rompiste una sesión.

En las tecnologías dinámicas, este es un problema **cotidiano**. Smalltalk, por ejemplo, maneja un ambiente vivo: mientras programás, el ambiente está corriendo, tu código está adentro del código que corre, y el editor con el que escribís está construido sobre ese mismo Smalltalk. Y pasaba, cada tanto, que alguien iba y cambiaba una clase básica del sistema, y después decía "perdí todos los trabajos prácticos". Sí, los perdiste: los que no habías guardado en otro lado.

Otros lenguajes tienen formas menos destructivas de abordar esto.

> 🕳️ **Madriguera — métodos de extensión (Scala)**
> Un mecanismo para agregarle métodos a un tipo existente sin modificar el tipo: la extensión vive aparte, se activa donde se importa y no afecta al resto del programa. Es la alternativa "con cinturón" a abrir una clase. Se ve más adelante en la materia.
> *Volvé al camino.*

Ruby no tiene cinturón acá. Lo que Ruby te dice es: podés hacer lo que quieras. ¿Querés abrir `Integer`? Abrila. ¿Querés abrir `Kernel`? Abrilo. Es tu problema: tenés que ser una persona responsable, saber lo que estás haciendo y ser consciente de las consecuencias. **No hay nada que te proteja de vos.**

### Dos nombres para lo que acabás de hacer 🟢

Estas dos prácticas tienen nombre, y los vas a ver por todos lados.

**Duck typing**: *"si camina como un pato y hace cuac como un pato, es un pato"*. En un lenguaje de tipado dinámico como Ruby, no importa de qué clase es un objeto sino cómo se comporta: si un objeto entiende `atacar`, es un atacante a todos los efectos, sea de la clase que sea. Es la razón por la que `is_a?` importa más que `class ==`.

**Monkey patching**: *"si camina como un mono y hace ruido como un mono, es un mono; y si el mono no hace el ruido que querés, le pegás hasta que lo haga"*. Modificar un tipo existente —abrir `String`, abrir `Integer`— para que responda a lo que vos necesitás. Es exactamente lo que hicimos con `importante`. El nombre ya te dice cómo lo ve la comunidad: útil, y peligroso.

---

## 4. `define_method`: definir métodos con nombres que no conocés 🔴

Volvamos a `comete_un_pollo`. Lo agregamos así:

```ruby
class Guerrero
  def comete_un_pollo
    self.energia += 100
  end
end
```

Es exactamente la misma sintaxis que usamos para escribir `Guerrero` en el archivo, y tiene la misma limitación. Fijate cuántas cosas están **hardcodeadas** ahí: el nombre de la clase (`Guerrero`), el nombre del método (`comete_un_pollo`) y el cuerpo entero. Con `def` no podés construir un método cuyo nombre sea dinámico. Si te digo "definí un método que se llame `get_` seguido de este nombre que te paso", **no podés**: con `def` tenés que escribir el nombre a mano, no podés concatenar cosas para armarlo. Tampoco podés decir "el cuerpo hace estos tres pasos y después ejecuta este otro pedazo de código que tengo por acá", porque el cuerpo tiene que estar escrito ahí adentro.

Es el mismo problema que resolvimos con `send` en la Parte 2 —"quiero mandar un mensaje sin hardcodear el selector"— trasladado a definir: **"quiero definir un método sin hardcodear el nombre"**.

La herramienta es un mensaje que entienden las clases, `define_method`, que recibe **el selector** y **un bloque** con el cuerpo:

```ruby
Guerrero.define_method(:comete_una_pata_de_pollo) {   # el selector es un VALOR
  self.energia += 50                                   # el cuerpo es un bloque
}
# => :comete_una_pata_de_pollo

conan.comete_una_pata_de_pollo
# => 250                            ← conan lo entiende, igual que con def
```

*(Bloque: el pedazo de código entre llaves que ya venís pasándole a `each` y `select`; en la clase 2 lo usaste para las estrategias de `Peloton`. Por ahora pensalo como una lambda: código guardado para ejecutar después. Cuando el método se ejecute, `self` va a ser el objeto que recibió el mensaje, exactamente igual que dentro de un `def`.)*

Hasta acá parece solo otra forma de escribir lo mismo. Las diferencias aparecen cuando usás lo que `def` no te daba.

**El selector es un valor.** Lo podés armar:

```ruby
comida = "milanesa"
Guerrero.define_method("comete_una_#{comida}".to_sym) {   # "comete_una_" + comida, convertido a símbolo
  self.energia += 10
}
# => :comete_una_milanesa

conan.comete_una_milanesa
# => 260
```

*(`"...#{x}..."` es interpolación: mete el valor de `x` adentro del string.)* Con `def`, esto es imposible. Con `define_method`, el nombre del método puede ser producto de cualquier computación: venir de una lista, de un archivo, de una pregunta que le hiciste a otro objeto con las herramientas de la Parte 2.

**El bloque retiene el contexto donde fue creado.** Esta es la otra diferencia, y es más profunda:

```ruby
bonus = 30                                          # una variable local, acá afuera
Guerrero.define_method(:comete_bonus) {
  self.energia += bonus                             # ...y el bloque la ve
}
# => :comete_bonus

conan.comete_bonus
# => 290
```

El cuerpo del método usa `bonus`, una variable que existe **afuera** del método, en el lugar donde escribiste el bloque. Con `def` esto no funciona: el cuerpo de un `def` está encerrado en el contexto de la clase y no ve las variables de afuera. El bloque, en cambio, se lleva consigo el contexto en el que nació. Eso te permite definir métodos **a partir de información que obtuviste antes**, con los mecanismos de reflection, y que esa información quede adentro del método.

Contextos es todo el tema de la clase que viene, así que no lo vamos a desarrollar más ahora. Quedate con el hecho: `define_method` es más dinámico que `def`, y te da herramientas que `def` no tiene.

> **Para el parcial, si te preguntan:** *¿Qué diferencia hay entre `def` y `define_method`?*
> `def` es sintaxis: el nombre del método y su cuerpo están escritos fijos en el código. `define_method` es un mensaje que recibe el selector como un valor (un símbolo, que puede construirse dinámicamente) y el cuerpo como un bloque, que además retiene las variables del contexto donde fue escrito. Permite definir métodos cuyo nombre o cuerpo dependen de información obtenida en tiempo de ejecución, cosa que `def` no puede.

---

## 5. Ejercicio resuelto: programar `attr_accessor` a mano 🔴

Con `define_method`, `instance_variable_get` e `instance_variable_set` en la mano, hay algo que podés programar ahora mismo y que hace dos horas parecía parte del lenguaje: **`attr_accessor`**.

Repasemos qué sabemos de él (Parte 2, sección 9). Cuando escribís esto:

```ruby
module Defensor
  attr_accessor :potencial_defensivo, :energia
```

no estás usando una palabra clave. Estás mandando un mensaje, `attr_accessor`, a `Defensor` —al módulo mismo, no a sus instancias—, con dos símbolos como argumentos. Y lo que ese mensaje hace es generar, para cada símbolo, un getter y un setter. Nada más. El atributo no se declara: aparece cuando alguien lo setea.

Vamos a escribir nuestra propia versión, que reciba un solo nombre para no complicarnos. La llamamos `mi_attr_accessor` para no pisar la real. ¿Quién tiene que entenderla? **La clase**: es a `Guerrero` a quien le vamos a escribir `mi_attr_accessor :apodo` en el cuerpo, y ya sabés (Parte 2, sección 9) que eso es un mensaje a `self`, y que en el cuerpo de una clase `self` es la clase.

Entonces necesitamos un método que entienda `Guerrero`, no sus instancias. Es lo que en el archivo de la Parte 1 hace `Peloton` con `def self.cobarde`, y ahora podemos leer esa sintaxis con todo lo que sabemos:

```ruby
class Guerrero
  def self.mi_attr_accessor(attr)     # attr va a ser un símbolo, por ejemplo :apodo
    # ...
  end
end
```

`def self.mi_attr_accessor` se lee así: "definí `mi_attr_accessor` en el objeto que es `self` **ahora**". Y como estamos en el cuerpo de `Guerrero`, `self` es `Guerrero`. Comparalo con un `def` común: `def descansar` define el método para las instancias —es lo que `atila` va a entender—; `def self.descansar` lo definiría para la clase —es lo que `Guerrero` va a entender—. Una vez definido, se usa mandándole el mensaje a la clase, con o sin receptor explícito:

```ruby
Guerrero.mi_attr_accessor :apodo    # desde afuera: receptor explícito
mi_attr_accessor :apodo             # adentro del cuerpo de Guerrero: self implícito, como attr_accessor
```

Dónde va a parar exactamente un método definido con `def self.` —porque no está ni en `Guerrero` ni en la clase de `Guerrero`— es la pregunta central de la Parte 6. Por ahora, con "es un método que entiende la clase" alcanza.

Ahora, ¿qué tiene que hacer? Generar dos métodos. Empecemos por el getter, que se llama igual que el atributo y devuelve su valor. Definir un método con un nombre que viene en una variable: `define_method`. Leer una variable de instancia por su nombre: `instance_variable_get`.

```ruby
define_method(attr) {
  instance_variable_get(attr)         # ← esto NO funciona todavía. Pensá por qué.
}
```

Acá te chocás con el primer problema real de manipular esto. Lo que te llega en `attr` es `:apodo`. Pero las variables de instancia **se llaman con arroba**: la variable es `:@apodo`, y `instance_variable_get(:apodo)` explota con el `NameError` que ya viste en la Parte 2. Tenés un símbolo que dice `apodo` y necesitás uno que diga `@apodo`. ¿Qué hacés?

Lo que harías con cualquier string: convertís el símbolo a string, le pegás el arroba adelante, y lo volvés a convertir a símbolo.

```ruby
nombre = "@#{attr}".to_sym            # :apodo → "@apodo" → :@apodo
```

Es una pelotudez cuando entendés dónde estás parado. Hace dos minutos no lo era. Con eso, el getter:

```ruby
define_method(attr) {
  instance_variable_get(nombre)       # nombre viene del contexto de afuera: el bloque lo retiene
}
```

Ahora el setter. ¿Cómo se llama un setter en Ruby? Como el campo, más `=` al final: `apodo=`. Otro nombre que hay que armar. ¿Y en qué se diferencia del getter? En que **recibe un parámetro**: el valor nuevo. Ese parámetro se declara como parámetro del bloque.

```ruby
define_method("#{attr}=".to_sym) { |value|   # el nombre es "apodo=" como símbolo; value es lo que le pasen
  instance_variable_set(nombre, value)
}
```

Y ya está. Todo junto, en la clase, y usándolo:

```ruby
class Guerrero
  def self.mi_attr_accessor(attr)
    nombre = "@#{attr}".to_sym                   # :apodo → :@apodo, el nombre real de la variable

    define_method(attr) {                        # el getter: se llama :apodo
      instance_variable_get(nombre)              # devuelve @apodo
    }

    define_method("#{attr}=".to_sym) { |value|   # el setter: se llama :apodo=, recibe el valor
      instance_variable_set(nombre, value)       # setea @apodo
    }
  end

  mi_attr_accessor :apodo                        # ← se usa exactamente igual que attr_accessor
end

atila.apodo = 'el huno'
# => "el huno"
atila.apodo
# => "el huno"
atila.instance_variables
# => [:@potencial_ofensivo, :@energia, :@potencial_defensivo, :@apodo]   ← la variable apareció al setearla
```

Acabás de programar `attr_accessor`. Fijate en cada pieza: `def self.` para que lo entienda la clase, `define_method` para que el nombre del método sea un valor, la conversión de símbolo a nombre de variable, `instance_variable_get` y `set` para el estado, y el bloque reteniendo `nombre` del contexto. No hay una sola cosa mágica; son las herramientas de esta clase, combinadas como cualquier otro programa.

Una limitación de esta versión que vale la pena notar: `mi_attr_accessor` solo lo entiende `Guerrero`, porque lo definimos ahí. El `attr_accessor` de verdad lo entienden **todas** las clases y todos los módulos. Para lograr eso hay que saber quién le provee comportamiento a las clases —dónde vive lo que todas las clases entienden— y eso es exactamente lo que descubre la Parte 5. Cuando llegues ahí, vas a ver que la respuesta es el lugar donde Ruby tiene definido el `attr_accessor` real.

> **Para el parcial, si te preguntan:** *¿`attr_accessor` es una palabra clave de Ruby? ¿Cómo funciona?*
> No. Es un mensaje que se le manda a la clase o módulo dentro de cuyo cuerpo se escribe. Por cada símbolo que recibe, define dos métodos con `define_method`: un getter con el nombre del símbolo que devuelve la variable de instancia correspondiente (`instance_variable_get`), y un setter con el nombre más `=` que la asigna (`instance_variable_set`). No declara ni crea el atributo: la variable de instancia aparece cuando el setter la asigna por primera vez.

---

## 6. Casi nada en Ruby es una primitiva 🟡

Lo que acabás de hacer con `attr_accessor` es la regla, no la excepción. **Ruby hace mucho esto.** Casi todas las cosas que vas a usar y que parecen parte del lenguaje son, en realidad, construcciones elaboradas usando estos mismos mecanismos de reflection. Con muy poco podés hacer cualquier locura del lenguaje.

Si quisieras programar *traits*, ya tenés las herramientas para meterle traits a Ruby. Si quisieras herencia múltiple, también. ¿Cómo? Y, es un programa: como cualquier programa, empezás a pensar qué necesitás, cómo se llama, cómo lo armás. Y necesitás una cosa más: entender el metamodelo. Entender **por qué las cosas se conectan como se conectan**, dónde vive cada pedazo de comportamiento, qué otras alternativas habría. Eso es lo que sigue, y es la parte picante.

---

## Qué sigue

Ya podés modificar el programa en marcha: abrir clases, agregar y pisar métodos, construir métodos con nombres dinámicos, y programar cosas que parecían primitivas. Lo que te falta es el mapa: el diagrama de la Parte 3 quedó incompleto, con cajas sin flecha roja y cajas sin flecha azul. La Parte 5 lo completa, y al hacerlo descubre qué es una clase, qué es un módulo, y dónde termina todo.

---

### Antes de seguir, tres preguntas para vos

1. Creás un guerrero, después abrís `Guerrero` y le agregás un método. El guerrero viejo lo entiende. Explicalo en términos del method lookup.
2. Definís `def atacar(un_defensor, con_fuerza)` en una clase que ya tenía `def atacar(un_defensor)`. ¿Cuántos métodos `atacar` hay ahora? ¿Por qué?
3. En `mi_attr_accessor`, la variable `nombre` se calcula una vez y los dos bloques la usan cada vez que alguien llama al getter o al setter, mucho después. ¿Qué característica de los bloques hace que eso funcione, y por qué con `def` no funcionaría?

*(Las respuestas no están acá. Si alguna no te sale, es la señal de qué releer.)*
