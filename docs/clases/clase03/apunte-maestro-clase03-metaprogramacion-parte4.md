# 📘 Apunte Maestro — Clase 03: Metaprogramación en Ruby

## Parte 4 — Self-modification: modificar el programa en marcha

**Materia:** Técnicas Avanzadas de Programación (TAdP) · **Unidad:** clase03 · **Clase del:** 29/08/2026

> **Serie completa:** Parte 0 (entorno) · Parte 1 (qué es metaprogramar) · Parte 2 (introspection) · Parte 3 (method lookup y métodos como objetos) · **Parte 4 (self-modification)** · Parte 5 (el metamodelo) · Parte 6 (autoclases y cierre).
> Sesión nueva de la consola: `age-clase2.rb` cargado, `atila = Guerrero.new` y `conan = Guerrero.new` recién creados (energía 100 cada uno). En esta parte vas a romper la consola a propósito; cuando pase, `exit` y volvé a entrar (Parte 0, sección 6). Cada vez que la sesión se reinicia, el apunte lo dice; los outputs siguen esa secuencia.

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

Con el modelo de la Parte 3 esto es literal: `String` tiene una tabla de nombres que apuntan a definiciones, y lo que hiciste fue **agregarle una fila**: `:importante` → una definición nueva.

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

Alguien se va a preguntar: "si los métodos van a la clase, ¿y si yo quiero agregarle un método a `atila` directamente, y no a todos los guerreros?". Buena pregunta. Se puede, y es la Parte 6.

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

En términos de la tabla: la fila `:descansar` **no se duplica**, se le cambia la flecha hacia una definición nueva. La definición vieja pierde su nombre, y ningún envío de mensaje la vuelve a encontrar. (La única forma de conservarla es haber pedido un envoltorio `Method` antes del cambio, como viste en la Parte 3, sección 6; si no lo pediste, se fue.)

```ruby
Guerrero.instance_methods(false).count(:descansar)
# => 1                             ← una sola fila: la nueva
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

> Después del `exit` de la sección 3 estás en una **sesión nueva**: `atila` y `conan` recién creados, energía 100, y `comete_un_pollo` ya no existe (murió con la sesión). Lo primero es volver a agregarlo.

```ruby
class Guerrero
  def comete_un_pollo
    self.energia += 100
  end
end

conan.comete_un_pollo
# => 200
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

Fijate que `define_method` es **un mensaje que le mandás a la clase**, con receptor explícito: `Guerrero.define_method(...)`. Es una línea más de tu programa, como cualquier otra. No hace falta abrir la clase para usarlo; y adentro de la clase también se puede, como vas a ver en la sección 6.

El efecto es idéntico al de `def`: una fila nueva en la tabla de `Guerrero`. Una vez ahí, nadie sabe ni le importa que la puso `define_method`. El lookup de `conan.comete_una_pata_de_pollo` es el mismo paso azul de siempre.

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

*(`"...#{x}..."` es interpolación: mete el valor de `x` adentro del string. Solo funciona con comillas dobles; con simples, `'#{x}'` es texto literal.)* Con `def`, esto es imposible. Con `define_method`, el nombre del método puede ser producto de cualquier computación: venir de una lista, de un archivo, de una pregunta que le hiciste a otro objeto con las herramientas de la Parte 2.

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

**Si el método recibe parámetros**, van como parámetros del bloque, entre barras, **como lo primero** adentro del bloque. Es sintaxis, no convención: no pueden ir en el medio ni al final. Las dos formas son equivalentes:

```ruby
Guerrero.define_method(:comete) { |cantidad| self.energia += cantidad }   # con llaves

Guerrero.define_method(:comete) do |cantidad|                              # con do/end
  self.energia += cantidad
end
```

> **Para el parcial, si te preguntan:** *¿Qué diferencia hay entre `def` y `define_method`?*
> `def` es sintaxis: el nombre del método y su cuerpo están escritos fijos en el código. `define_method` es un mensaje que recibe el selector como un valor (un símbolo, que puede construirse dinámicamente) y el cuerpo como un bloque, que además retiene las variables del contexto donde fue escrito. Permite definir métodos cuyo nombre o cuerpo dependen de información obtenida en tiempo de ejecución, cosa que `def` no puede. El resultado es el mismo: un método más en la clase, que todas sus instancias entienden.

---

## 5. Dos poblaciones de métodos: los que entiende la instancia y los que entiende la clase 🔴

Antes de programar algo más grande hay que separar dos cosas que hasta ahora estaban mezcladas, y que si no se separan hacen ruido en todo lo que sigue.

Todo lo que definiste hasta acá —`importante`, `comete_un_pollo`, `comete_bonus`— lo entienden **las instancias**: `conan`, `atila`, cualquier guerrero. `Guerrero` mismo no lo entiende:

```ruby
Guerrero.descansar
# NoMethodError: undefined method `descansar' for Guerrero:Class
#    ← Guerrero PROVEE descansar; no lo ENTIENDE
```

Pero `Guerrero` sí entiende cosas. Entiende `new`. Entiende `instance_methods`. Entiende `define_method`, que acabás de usar. Y entiende `attr_accessor`: cuando en el archivo escribiste `attr_accessor :peloton` adentro del cuerpo, le mandaste un mensaje a `Guerrero` (Parte 2, sección 9). Ninguno de esos lo entiende `atila`:

```ruby
atila.respond_to?(:attr_accessor)
# => false
Guerrero.respond_to?(:attr_accessor)
# => true
```

Entonces hay **dos poblaciones de métodos**, y cada una tiene su público:

```
┌──────────────────────────────────────────────────────────────┐
│ Guerrero                                                     │
│                                                              │
│  Lo que Guerrero PROVEE a sus instancias                     │
│    descansar, cansado, comete_un_pollo, comete_bonus...      │
│    → los usa atila:   atila.descansar                        │
│    → se definen con:  def, define_method                     │
│    → se listan con:   Guerrero.instance_methods              │
│                                                              │
│  Lo que Guerrero ENTIENDE como objeto                        │
│    new, instance_methods, define_method, attr_accessor...    │
│    → los usa Guerrero:  Guerrero.new                         │
│    → se definen con:    def self.  (ahora lo vemos)          │
│    → se listan con:     Guerrero.methods                     │
└──────────────────────────────────────────────────────────────┘
```

Ya conocés la mitad de arriba. La mitad de abajo es la que hace falta para lo que viene.

### `def self.`: definir un método que entienda la clase

En el archivo de la Parte 1, `Peloton` tiene esto:

```ruby
class Peloton
  def self.cobarde(guerreros)     # ← ese "self." es lo nuevo
    # ...
  end
end
```

Ahora se puede leer con todo lo que sabés. En el cuerpo de una clase, `self` es la clase (Parte 2, sección 9). `def self.gritar` se lee: **"definí `gritar` para el objeto que es `self` ahora"**, y ese objeto es `Guerrero`. Compará:

```ruby
class Guerrero
  def descansar                   # lo entiende atila     (población de arriba)
    # ...
  end

  def self.gritar                 # lo entiende Guerrero  (población de abajo)
    'haaaaa'
  end
end

Guerrero.gritar
# => "haaaaa"
atila.gritar
# NoMethodError: undefined method `gritar' for #<Guerrero:0x...>
#    ← atila no lo entiende: no es de su población

Guerrero.instance_methods(false).include?(:gritar)
# => false                         ← no está entre lo que Guerrero provee
Guerrero.methods(false)
# => [:gritar]                     ← está entre lo que Guerrero entiende
```

Si venís de Java, la analogía con `static` sirve para orientarte: es un método que se llama sobre la clase, no sobre sus instancias. La diferencia es que en Ruby no hay nada estático: `Guerrero` es un objeto, y le estás definiendo un método **a ese objeto en particular**.

**Y como es un objeto, también se le puede definir desde afuera**, sin abrir la clase. La sintaxis general es `def <objeto>.<método>`; adentro del cuerpo el objeto es `self`, y afuera lo nombrás directo:

```ruby
def Guerrero.crear_vikingo        # desde la consola, sin class ... end
  new(70)                         # self es Guerrero: new implícito
end

Guerrero.crear_vikingo.potencial_ofensivo
# => 70
atila.respond_to?(:crear_vikingo)
# => false                         ← sigue siendo de la clase
```

### Dónde vive esto: una brújula

Un `def self.gritar` **no** agrega una fila a la tabla de `Guerrero`: si lo hiciera, `atila` lo entendería, y no lo entiende. Tampoco va a `Class`, porque entonces lo entendería cualquier clase, y `String.gritar` no funciona. Va a **otra caja**, propia de `Guerrero`, que todavía no dibujamos.

Esa caja existe, tiene nombre, y es el tema central de la Parte 6. Hasta ahí, alcanza con esto: **los métodos definidos con `def self.` viven en un lugar aparte, que solo `Guerrero` alcanza en su lookup.** No hace falta saber cuál para usar `def self.`; sí hace falta saber que existe para no buscarlos donde no están.

> **Para el parcial, si te preguntan:** *¿Qué diferencia hay entre `def descansar` y `def self.descansar` dentro de `class Guerrero`?*
> `def descansar` define un método de instancia: lo entienden los objetos creados con `Guerrero.new`, y aparece en `Guerrero.instance_methods`. `def self.descansar` define un método para el objeto `self`, que dentro del cuerpo de la clase es `Guerrero`: lo entiende la clase misma (`Guerrero.descansar`), no sus instancias, y aparece en `Guerrero.methods`. Es lo que en otros lenguajes se llamaría método de clase o estático, con la diferencia de que en Ruby se define sobre la clase en tanto objeto.

---

## 6. Ejercicio resuelto: programar `attr_accessor` a mano 🔴

Con `define_method`, `instance_variable_get`, `instance_variable_set` y `def self.` en la mano, hay algo que podés programar ahora mismo y que hace dos horas parecía parte del lenguaje: **`attr_accessor`**.

Repasemos qué sabemos de él (Parte 2, sección 9). Cuando escribís esto:

```ruby
module Defensor
  attr_accessor :potencial_defensivo, :energia
```

no estás usando una palabra clave. Estás mandando un mensaje, `attr_accessor`, a `Defensor` —al módulo mismo, no a sus instancias—, con dos símbolos como argumentos. Y lo que ese mensaje hace es generar, para cada símbolo, un getter y un setter. Nada más. El atributo no se declara: la variable de instancia aparece cuando alguien la asigna por primera vez.

Vamos a escribir nuestra propia versión, que reciba un solo nombre para no complicarnos. La llamamos `mi_attr_accessor` para no pisar la real.

### Quién lo entiende y qué produce

Con la sección 5 esto se responde solo. Se lo vamos a escribir a `Guerrero` en su cuerpo, como `mi_attr_accessor :apodo`, así que **lo tiene que entender `Guerrero`**: población de abajo, `def self.`. Y lo que tiene que hacer es fabricar dos métodos que entiendan las instancias: población de arriba, `define_method`.

```
   def self.mi_attr_accessor       ──► un método que entiende Guerrero  (la fábrica)
        │
        └── define_method × 2      ──► dos métodos que entiende atila   (el producto)
```

Por eso vas a ver una definición de método **adentro** de otra. No es un mecanismo nuevo: es un método de la clase cuyo trabajo es agregar filas a la tabla de instancias.

### Armar el getter

El getter se llama igual que el atributo y devuelve su valor. Definir un método con un nombre que viene en una variable: `define_method`. Leer una variable de instancia por su nombre: `instance_variable_get`. Primer intento:

```ruby
class Guerrero
  def self.mi_attr_accessor(attr)     # attr va a ser un símbolo, por ejemplo :apodo
    define_method(attr) {
      instance_variable_get(attr)     # ← esto NO funciona todavía. Pensá por qué.
    }
  end
end
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

Un detalle sobre ese `define_method` **sin receptor**: es un mensaje a `self` implícito, igual que `energia` adentro de `descansar` es `self.energia`. Y adentro de `mi_attr_accessor`, `self` es `Guerrero` (es a quien le mandaron el mensaje). O sea que esa línea es exactamente `Guerrero.define_method(attr) { ... }`, lo mismo que venías tipeando en la consola en la sección 4, con el receptor implícito porque ya estás parado adentro de `Guerrero`. Escribirlo como `self.define_method(attr)` funciona idéntico.

### Armar el setter

¿Cómo se llama un setter en Ruby? Como el campo, más `=` al final: `apodo=`. Otro nombre que hay que armar. ¿Y en qué se diferencia del getter? En que **recibe un parámetro**: el valor nuevo. Ese parámetro se declara como parámetro del bloque, entre barras, al principio.

```ruby
define_method("#{attr}=".to_sym) { |value|   # el nombre es "apodo=" como símbolo; value es lo que le pasen
  instance_variable_set(nombre, value)
}
```

### Todo junto, y usándolo

```ruby
class Guerrero
  def self.mi_attr_accessor(attr)                # lo entiende Guerrero
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

Guerrero.instance_methods(false).include?(:apodo)
# => true                          ← el getter quedó en la tabla de instancias de Guerrero
Guerrero.instance_methods(false).include?(:apodo=)
# => true                          ← y el setter también

atila.apodo
# => nil                           ← nadie asignó @apodo todavía: leerla da nil y no la crea
atila.instance_variables
# => [:@potencial_ofensivo, :@energia, :@potencial_defensivo]   ← sigue sin @apodo

atila.apodo = 'el huno'
atila.apodo
# => "el huno"
atila.instance_variables
# => [:@potencial_ofensivo, :@energia, :@potencial_defensivo, :@apodo]   ← apareció al setearla
atila.method(:apodo).owner
# => Guerrero                      ← owner confirma dónde quedó
```

Acabás de programar `attr_accessor`. Fijate en cada pieza: `def self.` para que lo entienda la clase, `define_method` para que el nombre del método sea un valor, la conversión de símbolo a nombre de variable, `instance_variable_get` y `set` para el estado, y el bloque reteniendo `nombre` del contexto. No hay una sola cosa mágica; son las herramientas de esta clase, combinadas como cualquier otro programa.

### Cuándo corre cada cosa

Esto es lo que más cuesta ver la primera vez, así que lo vamos a hacer visible. **El cuerpo de una clase es código que se ejecuta**, línea por línea, en el momento en que Ruby lo lee. `mi_attr_accessor :apodo` no es una declaración que Ruby "anota": es una llamada, y ocurre ahí, una sola vez. Con dos `puts` de traza:

```ruby
class Guerrero
  def self.mi_attr_accessor(attr)
    puts "  [mi_attr_accessor] self es #{self}"
    # ... igual que arriba
  end

  puts "[cuerpo] antes de la llamada"
  mi_attr_accessor :apodo
  puts "[cuerpo] después de la llamada"
end
# [cuerpo] antes de la llamada
#   [mi_attr_accessor] self es Guerrero      ← corrió AHÍ, en el medio del cuerpo
# [cuerpo] después de la llamada
```

Y la tabla de `Guerrero`, antes y después de esa línea:

```
ANTES de `mi_attr_accessor :apodo`          DESPUÉS
  descansar  ──► def.                        descansar  ──► def.
  cansado    ──► def.                        cansado    ──► def.
  ...                                        ...
                                             apodo      ──► def.   ← las puso define_method
                                             apodo=     ──► def.   ← en ese instante
```

Una consecuencia directa: **el orden importa**. Si la llamada está antes de la definición, en ese momento `Guerrero` todavía no entiende `mi_attr_accessor`:

```ruby
class Guerrero
  mi_attr_accessor :temprano             # ← todavía no existe
  def self.mi_attr_accessor(attr); end
end
# NoMethodError: undefined method `mi_attr_accessor' for Guerrero:Class
```

### Dos `self` en el mismo bloque de código

Mirá de nuevo el código completo. Adentro de `mi_attr_accessor` hay mensajes sin receptor en dos lugares distintos, y **no le hablan al mismo objeto**:

```
class Guerrero
  def self.mi_attr_accessor(attr)     ──── momento 1: corre cuando Guerrero recibe
    nombre = "@#{attr}".to_sym              mi_attr_accessor. self = Guerrero.
    define_method(attr) {           ◄──── mensaje a Guerrero
      instance_variable_get(nombre) ◄──┐
    }                                  │
  end                                  └─ momento 2: corre cuando alguien hace
end                                       atila.apodo, mucho después. self = atila.
```

- En el **cuerpo de `mi_attr_accessor`**, `self` es `Guerrero`. Por eso `define_method` suelto agrega filas a `Guerrero`.
- **Adentro del bloque**, cuando el getter se ejecuta, `self` es la instancia que recibió el mensaje. Por eso `instance_variable_get(nombre)` equivale a `atila.instance_variable_get(nombre)`, y lee **el `@apodo` de atila**.

Si fueran el mismo `self`, el getter leería una variable de la clase y todos los guerreros compartirían apodo. Verificalo con un método que devuelva `self`:

```ruby
Guerrero.define_method(:quien_soy) { self }
atila.quien_soy.equal?(atila)
# => true                          ← el bloque corre con self = quien recibió el mensaje
conan.quien_soy.equal?(conan)
# => true
```

### También desde afuera

Como `mi_attr_accessor` es un método que entiende `Guerrero`, no hace falta estar adentro del cuerpo para usarlo. Desde la consola, con receptor explícito:

```ruby
Guerrero.mi_attr_accessor :lucidez   # el mismo mensaje, mismo efecto (si dejaste las trazas, imprime su línea otra vez)
atila.lucidez = 9
atila.lucidez
# => 9
```

Adentro del cuerpo se escribe sin receptor porque `self` ya es `Guerrero`; afuera, lo nombrás. Es la misma regla de siempre para cualquier mensaje.

### Una limitación, y hacia dónde apunta

`mi_attr_accessor` solo lo entiende `Guerrero`, porque lo definimos ahí. El `attr_accessor` de verdad lo entienden **todas** las clases y todos los módulos. Para lograr eso hay que saber quién le provee comportamiento a las clases —dónde vive lo que todas las clases entienden— y eso es exactamente lo que descubre la Parte 5. Podés averiguar dónde está con lo que ya sabés (`Guerrero.method(:attr_accessor).owner`); la Parte 5 explica por qué la respuesta es esa.

> **Para el parcial, si te preguntan:** *¿`attr_accessor` es una palabra clave de Ruby? ¿Cómo funciona?*
> No. Es un mensaje que se le manda a la clase o módulo dentro de cuyo cuerpo se escribe. Por cada símbolo que recibe, define dos métodos de instancia con `define_method`: un getter con el nombre del símbolo que devuelve la variable de instancia correspondiente (`instance_variable_get`), y un setter con el nombre más `=` que la asigna (`instance_variable_set`). No declara ni crea el atributo: la variable de instancia aparece cuando el setter la asigna por primera vez.

---

## 7. Casi nada en Ruby es una primitiva 🟡

Lo que acabás de hacer con `attr_accessor` es la regla, no la excepción. **Ruby hace mucho esto.** Casi todas las cosas que vas a usar y que parecen parte del lenguaje son, en realidad, construcciones elaboradas usando estos mismos mecanismos de reflection. Con muy poco podés hacer cualquier locura del lenguaje.

Si quisieras programar *traits*, ya tenés las herramientas para meterle traits a Ruby. Si quisieras herencia múltiple, también. ¿Cómo? Y, es un programa: como cualquier programa, empezás a pensar qué necesitás, cómo se llama, cómo lo armás. Y necesitás una cosa más: entender el metamodelo. Entender **por qué las cosas se conectan como se conectan**, dónde vive cada pedazo de comportamiento, qué otras alternativas habría. Eso es lo que sigue, y es la parte picante.

---

## 8. Caja de herramientas de la Parte 4 🔴

Todo lo que esta parte introdujo, en una tabla para tener al lado mientras leés o mientras probás en la consola. La última columna es una línea lista para tipear en Pry con `age-clase2.rb` cargado y `atila = Guerrero.new` hecho. Acá hay menos mensajes y más construcciones: la columna "Mensaje" trae la forma.

| Quiero... | Se lo mando a... | Mensaje o construcción | Efecto | Probalo |
|---|---|---|---|---|
| agregar un método a una clase que ya existe | la clase (reabriéndola) | `class X; def m; ...; end; end` | fila nueva en la tabla; todas las instancias lo entienden, viejas y nuevas | `class String; def importante; self + '!'; end; end` |
| pisar un método existente | la clase | el mismo `def` con el mismo nombre | la fila apunta a otra definición; la vieja se pierde; firma = solo el nombre | `class Guerrero; def descansar; self.energia += 1000; end; end` |
| definir un método cuyo nombre es un valor | la clase | `define_method(:selector) { cuerpo }` | igual que `def`, pero el selector es un símbolo y el cuerpo un bloque | `Guerrero.define_method(:hola) { 'hola' }` |
| definir un método con parámetros vía bloque | la clase | `define_method(:s) { \|x\| ... }` o `do \|x\| ... end` | los parámetros van primero, entre barras | `Guerrero.define_method(:come) { \|n\| self.energia += n }` |
| armar un selector a partir de un string | un string | `"...#{x}...".to_sym` | un símbolo (interpolación: solo con comillas dobles) | `"comete_una_#{comida}".to_sym` |
| armar el nombre de una variable de instancia | un string | `"@#{attr}".to_sym` | `:@attr` | `"@#{:apodo}".to_sym` |
| que el cuerpo use una variable de afuera | el bloque | cualquier variable local visible al escribir el bloque | el bloque la retiene (con `def` no se puede) | `bonus = 30; Guerrero.define_method(:b) { self.energia += bonus }` |
| definir un método que entienda **la clase**, no sus instancias | la clase, en su cuerpo | `def self.m; ...; end` | lo entiende `X`, no `X.new`; vive aparte (Parte 6) | `class Guerrero; def self.gritar; 'haaaa'; end; end` |
| lo mismo, desde afuera del cuerpo | la clase, por su nombre | `def X.m; ...; end` | ídem | `def Guerrero.gritar; 'haaaa'; end` |
| llamar a un método de clase | la clase | `X.m args` (afuera) · `m args` (adentro del cuerpo) | corre ahí mismo, una vez | `Guerrero.mi_attr_accessor :lucidez` |
| saber a qué población pertenece un método | la clase | `instance_methods(false)` vs `methods(false)` | lo que provee vs lo que entiende | `Guerrero.methods(false)` |
| un getter y un setter a mano | la clase | `def self.` + `define_method` + `instance_variable_get` / `_set` | lo que hace `attr_accessor` | ver §6, `mi_attr_accessor` completo |
| averiguar la clase de algo del lenguaje antes de abrirla | el valor | `class` | la clase a reabrir | `2.class` |
| volver a un estado limpio después de romper la sesión | la terminal | `exit` · `pry` · `require_relative` | sesión nueva | `exit` |

Y las cosas que no son mensajes pero hay que tener a mano:

- **El cuerpo de una clase se ejecuta** línea por línea cuando Ruby lo lee. Una llamada escrita ahí (`attr_accessor :x`, `mi_attr_accessor :x`) corre en ese momento, una vez. El orden importa.
- **Dos poblaciones:** lo que la clase provee (instancias, `def`, `instance_methods`) y lo que la clase entiende (`def self.`, `methods`). Un método está en una o en la otra, nunca en las dos.
- **Dos `self`:** en el cuerpo de un método de clase, `self` es la clase; adentro de un bloque de `define_method`, cuando el método generado corre, `self` es la instancia que recibió el mensaje.

---

## Qué sigue

Ya podés modificar el programa en marcha: abrir clases, agregar y pisar métodos, construir métodos con nombres dinámicos, definir métodos para la clase misma, y programar cosas que parecían primitivas. Lo que te falta es el mapa: el diagrama de la Parte 3 quedó incompleto, con cajas sin flecha roja y cajas sin flecha azul, y en esta parte apareció una caja más que ni siquiera dibujamos, la de los `def self.`. La Parte 5 completa el diagrama y descubre qué es una clase, qué es un módulo, y dónde termina todo. La Parte 6 dibuja la caja que falta.

---

### Antes de seguir, seis preguntas para vos

1. Creás un guerrero, después abrís `Guerrero` y le agregás un método. El guerrero viejo lo entiende. Explicalo en términos del method lookup.
2. Definís `def atacar(un_defensor, con_fuerza)` en una clase que ya tenía `def atacar(un_defensor)`. ¿Cuántos métodos `atacar` hay ahora? ¿Por qué?
3. En `mi_attr_accessor`, la variable `nombre` se calcula una vez y los dos bloques la usan cada vez que alguien llama al getter o al setter, mucho después. ¿Qué característica de los bloques hace que eso funcione, y por qué con `def` no funcionaría?
4. Adentro de `mi_attr_accessor` hay un `define_method` sin receptor y un `instance_variable_get` sin receptor. ¿A quién le habla cada uno, y en qué momento corre cada uno?
5. Movés la línea `mi_attr_accessor :apodo` arriba del `def self.mi_attr_accessor`. ¿Qué pasa y por qué?
6. ¿Cómo definís, desde la consola y sin reabrir la clase, un método que entienda `Guerrero` y no `atila`? ¿En qué lista aparece después: `instance_methods(false)` o `methods(false)`?

*(Las respuestas no están acá. Si alguna no te sale, es la señal de qué releer.)*
