# 📘 Apunte Maestro — Clase 03: Metaprogramación en Ruby

## Parte 2 — Introspection: preguntarle cosas al programa

**Materia:** Técnicas Avanzadas de Programación (TAdP) · **Unidad:** clase03 · **Clase del:** 29/08/2026

> **Serie completa:** Parte 0 (entorno) · Parte 1 (qué es metaprogramar) · **Parte 2 (introspection)** · Parte 3 (method lookup y métodos como objetos) · Parte 4 (self-modification) · Parte 5 (el metamodelo) · Parte 6 (autoclases y cierre).
> Todo lo que sigue se hace en la consola con `age-clase2.rb` cargado (Parte 0, sección 6). Los `=>` son lo que la consola responde; los números largos como `0x000055c7452ed490` van a ser otros en tu máquina.

---

## 1. Dejar de pensar en atila como guerrero 🔴

Arrancamos como siempre: creamos un guerrero.

```ruby
atila = Guerrero.new
# => #<Guerrero:0x000055c7452ed490 @energia=100, @potencial_defensivo=10, @potencial_ofensivo=20>
```

Hasta la clase pasada, con `atila` en la mano lo que hacías era usar **la interfaz de los guerreros**: `atila.descansar`, `atila.atacar(otro)`, `atila.energia`. Eso es programar el dominio.

Ahora vamos a cambiar de perspectiva. `atila` no es solo la representación de un guerrero: es **un objeto que forma parte de un programa**. Y si el dominio que nos interesa es el programa en sí, entonces lo que queremos preguntarle a `atila` no es cuánta energía tiene, sino cosas sobre **su representación**: de qué clase es, qué mensajes entiende, qué guarda adentro.

Las preguntas de esta parte son todas de ese tipo. Ninguna cambia nada; solo consultan. Esa es la mitad segura de reflection: **introspection**.

---

## 2. `class`: de qué clase es un objeto 🔴

Lo primero que sabemos de cualquier objeto es que es instancia de una clase. Y hay un mensaje para preguntarlo:

```ruby
atila.class
# => Guerrero
```

Parece trivial, pero fijate en un detalle que va a ser enorme dentro de un rato: **la respuesta no es un nombre**. No te devolvió el string `"Guerrero"`. Te devolvió **la clase**: un objeto que representa a la clase Guerrero. En la consola se nota porque aparece subrayado, no entre comillas, como sí aparecería un string:

```ruby
atila.class.name
# => "Guerrero"            ← esto sí es un string: el nombre de la clase
atila.class
# => Guerrero              ← esto es la clase misma, un objeto
atila.class == Guerrero
# => true                  ← es exactamente el mismo objeto al que te referís cuando escribís "Guerrero"
```

**Las clases en Ruby son objetos.** Y eso significa que son ciudadanos de primer orden del lenguaje, que es una forma de decir cuatro cosas concretas:

1. Le podés **mandar un mensaje**.
2. La podés **guardar en una variable**.
3. La podés **pasar por parámetro**.
4. La podés **retornar** desde un método.

Ya lo hiciste sin darte cuenta: `Guerrero.new` es mandarle el mensaje `new` al objeto `Guerrero`. Y si la clase es un objeto, entonces también es instancia de alguna clase:

```ruby
atila.class.class
# => Class
```

`Guerrero` es instancia de una clase que se llama `Class`. Guardá ese dato; en la Parte 5 se convierte en el centro de todo. Por ahora alcanza con saber que el objeto que representa a una clase también tiene clase.

Una comparación que ayuda a valorar esto: en Wollok, el lenguaje de Paradigmas, no podés preguntarle a un objeto de qué clase es. Es una decisión didáctica a propósito, para que nadie escriba `if es de tal clase entonces...`. En la mayoría de las tecnologías reales, en cambio, sí podés. Ruby te lo da, y además te devuelve un objeto con el que podés seguir trabajando.

---

## 3. Símbolos: los nombres de las cosas 🔴

Antes de seguir preguntando, hay que entender un tipo de dato que va a aparecer en casi todas las respuestas de esta clase. Escribí esto:

```ruby
:descansar
# => :descansar
```

Eso es un **símbolo**: un identificador que empieza con dos puntos. Pensalo como un string, con una diferencia importante: **de cada símbolo hay una única instancia en todo el sistema**. Dos strings iguales son dos objetos distintos; dos símbolos iguales son el mismo objeto:

```ruby
"descansar".equal?("descansar")     # equal? pregunta si son EL MISMO objeto, no si son iguales
# => false                           ← dos strings con el mismo texto: dos objetos
:descansar.equal?(:descansar)
# => true                            ← el símbolo :descansar es uno solo en todo el programa
```

Por eso Ruby los usa como **nombres**: nombres de métodos, nombres de atributos, nombres de cualquier cosa. Es más barato y más seguro que usar strings para eso. Y se convierten en ambos sentidos cuando hace falta:

```ruby
:descansar.to_s
# => "descansar"          ← de símbolo a string
"descansar".to_sym
# => :descansar           ← de string a símbolo
```

Regla práctica para el resto de la clase: **cuando veas `:algo`, leelo como "el nombre algo"**. Cuando una respuesta sea una lista de símbolos, es una lista de nombres.

---

## 4. `methods` e `instance_methods`: qué mensajes entiende 🔴

Ya sabemos de qué clase es `atila`. La siguiente pregunta obvia es **qué le puedo mandar**. Hay un mensaje para eso:

```ruby
atila.methods
# => [:descansar_atacante,
#     :descansar_defensor,
#     :peloton,
#     :lastimado,
#     :cansado,
#     :sufri_danio,
#     :descansar,
#     :peloton=,
#     :energia=,
#     :potencial_defensivo=,
#     :energia,
#     :potencial_defensivo,
#     :descansado=,
#     :potencial_ofensivo,
#     :potencial_ofensivo=,
#     :descansado,
#     :atacar,
#     :pry,
#     :pretty_print,
#     :is_a?,
#     :instance_variables,
#     :instance_variable_get,
#     :method,
#     :send,
#     :class,
#     :methods,
#     ...]                            ← sigue: más de medio centenar en total
```

Una lista de **símbolos**: los nombres de todos los mensajes que `atila` entiende. Los primeros son nuestros; después vienen decenas que no escribimos nosotros —`is_a?`, `send`, `class`, el propio `methods`— y que todo objeto de Ruby entiende. Es la interfaz sucia de la que hablamos en la Parte 1: cada objeto trae puestos los mensajes de metaprogramación.

Fijate que en la lista aparecen `descansar_atacante` y `descansar_defensor`: son los alias que Guerrero se guardó para resolver el conflicto de los dos mixins. Ahí están, como mensajes comunes.

Ahora, la misma pregunta se le puede hacer **a la clase** en vez de a la instancia, y es importante entender que no es el mismo mensaje:

```ruby
atila.class.instance_methods
# => [:descansar_atacante, :descansar_defensor, :peloton, ...]     ← la misma lista
```

Las dos listas coinciden, pero las preguntas son distintas:

| Mensaje | Se le manda a | Qué responde |
|---|---|---|
| `methods` | un objeto cualquiera (`atila`) | **¿Qué mensajes te puedo mandar a vos?** |
| `instance_methods` | una clase (`Guerrero`) | **¿Qué mensajes les das a tus instancias?** |

`atila` responde los métodos que **él entiende**. `Guerrero` responde los métodos que **él provee**, en su rol de proveedor de comportamiento. Por eso `atila` no entiende `instance_methods` —no le provee métodos a nadie— y `Guerrero` sí:

```ruby
atila.instance_methods
# NoMethodError: undefined method `instance_methods' for #<Guerrero:0x...>
```

### El flag `false`

`instance_methods` sin argumento te trae todo: lo que Guerrero define y lo que hereda. Si querés **solo lo que está definido en esa clase**, sin lo de más arriba, le pasás `false`:

```ruby
atila.class.instance_methods(false)
# => [:descansar_atacante, :descansar_defensor, :peloton, :lastimado, :cansado, :sufri_danio, :descansar, :peloton=]
```

Ocho métodos, y son exactamente los que Guerrero define en su cuerpo: los dos alias, `descansar`, `lastimado`, `sufri_danio`, `cansado`, y el getter y setter que genera `attr_accessor :peloton`. No están `energia` ni `atacar`, porque esos vienen de los mixins.

### Una queja justificada sobre los nombres

Acá hay algo que conviene decir de entrada, porque Ruby nombra mal estas operaciones y eso confunde. Cuando le preguntaste a `atila` su clase, te devolvió **la clase**, un objeto. Cuando le preguntaste sus métodos, **no te devolvió métodos: te devolvió nombres de métodos**. Símbolos. Un nombre no es un método: un método tiene muchos más aspectos que solo su nombre (qué parámetros recibe, quién lo definió, cómo ejecutarlo), y un símbolo no sabe responder nada de eso.

A esos nombres los vamos a llamar **selectores**: el selector es el nombre con el que seleccionás un método. `methods` e `instance_methods` devuelven **listas de selectores**. En la Parte 3 vas a ver cómo pedir el método de verdad.

> **Para el parcial, si te preguntan:** *¿Qué diferencia hay entre `methods` e `instance_methods`?*
> `methods` se le manda a un objeto y responde los selectores de los mensajes que ese objeto entiende. `instance_methods` se le manda a una clase (o módulo) y responde los selectores que esa clase provee a sus instancias. Un objeto común no entiende `instance_methods` porque no provee comportamiento a nadie. Con `instance_methods(false)` se obtienen solo los definidos en esa clase, sin los heredados.

---

## 5. `is_a?`: pertenecer a un tipo 🔴

Preguntarle a un objeto **de qué clase es** no es lo mismo que preguntarle **si es de cierto tipo**. Mirá:

```ruby
atila.is_a? Guerrero
# => true
atila.is_a? Atacante
# => true                  ← atila ES un atacante...
atila.class == Atacante
# => false                 ← ...pero su clase no es Atacante
```

`atila` es un atacante: entiende todo lo que un atacante entiende, se puede usar donde se espere un atacante. Pero no es *instancia* de `Atacante`, que además es un mixin y no se instancia. **Pertenecer a un tipo es más que ser instancia de una clase**: incluye los mixins que la clase incorpora y toda la cadena de superclases.

```ruby
atila.is_a? Object
# => true                  ← todo es un objeto
atila.is_a? Class
# => false                 ← atila no es una clase
atila.is_a? Espadachin
# => false                 ← Espadachin hereda de Guerrero, no al revés

zorro = Espadachin.new(Espada.new(30))
zorro.is_a? Guerrero
# => true                  ← un espadachín es un guerrero
zorro.class == Guerrero
# => false                 ← pero su clase es Espadachin
```

Sobre el signo de pregunta: forma parte del nombre del mensaje. En Ruby es convención que los mensajes que responden verdadero o falso terminen en `?`. No hace nada especial; es un nombre más.

> **Para el parcial, si te preguntan:** *¿Qué diferencia hay entre `atila.class == Guerrero` y `atila.is_a?(Guerrero)`?*
> `class` responde la clase exacta de la que el objeto es instancia. `is_a?` responde si el objeto pertenece a un tipo, lo que incluye su clase, las superclases de esa clase y los mixins incluidos en cualquiera de ellas. `zorro.class == Guerrero` es falso (es un Espadachin), pero `zorro.is_a?(Guerrero)` es verdadero.

---

## 6. `superclass` y `ancestors`: de dónde viene el comportamiento 🔴

Ya podemos pedirle a una clase su superclase:

```ruby
atila.class.superclass
# => Object
Espadachin.superclass
# => Guerrero
Espadachin.superclass.superclass
# => Object
```

Nadie escribió `class Guerrero < Object`. Cuando definís una clase sin decir de quién hereda, Ruby pone `Object` como superclase. Y `Object` es la clase que le da a todo objeto las cosas básicas: `class`, `methods`, `is_a?` y compañía.

Con `class` y `superclass` ya podemos dibujar. En los diagramas de esta clase se usan dos flechas con significado fijo, y en la cátedra tienen color: **azul = "es instancia de" (`class`)** y **rojo = "hereda de" (`superclass`)**. Acá, en texto, van etiquetadas:

```
                       ┌──────────┐
                       │  Object  │
                       └────▲─────┘
                            │ superclass (rojo)
                       ┌────┴─────┐   class (azul)   ┌───────┐
   atila ─────────────►│ Guerrero │─────────────────►│ Class │
        class (azul)   └────▲─────┘                  └───────┘
                            │ superclass (rojo)
                       ┌────┴──────┐
   zorro ─────────────►│ Espadachin│
        class (azul)   └───────────┘
```

Este diagrama **está incompleto**, a propósito. Lo vamos a ir completando durante toda la clase, y para el final va a ser el metamodelo entero de Ruby. Vos no lo tenés que memorizar: lo tenés que poder **descubrir** con los dos mensajes que ya conocés.

### Pero `superclass` no cuenta toda la historia

Fijate que en el diagrama no están `Atacante` ni `Defensor`. `superclass` te da **una** clase, la de arriba. No te dice nada de los mixins, que no son clases. Y sin embargo los mixins están en el medio del camino que Ruby recorre para encontrar un método: dijimos en la Parte 1 que un mensaje a `atila` se busca en `Guerrero`, después en `Defensor`, después en `Atacante`, y recién después en `Object`.

Ese camino completo tiene un nombre —**linearización**— y hay un mensaje para pedirlo:

```ruby
Guerrero.ancestors
# => [Guerrero, Defensor, Atacante, Object, PP::ObjectMixin, Kernel, BasicObject]
```

Leelo elemento por elemento, porque cada uno enseña algo:

- **`Guerrero`** — arranca por sí mismo. El primer lugar donde se busca un método es la propia clase.
- **`Defensor`, `Atacante`** — los dos mixins, **en orden de búsqueda**: primero `Defensor` porque fue el último que se incluyó. El último `include` queda más cerca. Por eso, cuando los dos definían `descansar`, ganaba el de `Defensor`.
- **`Object`** — la superclase.
- **`PP::ObjectMixin`** — esto **no es de Ruby**: lo mete Pry para poder mostrarte los objetos bonitos (Parte 0, sección 8). Ignoralo. Si corrés sin Pry, no está.
- **`Kernel`** — un mixin que Ruby le incluye a `Object`, con una cantidad enorme de comportamiento básico. Está entre `Object` y lo que hay arriba, exactamente donde estaría cualquier mixin de `Object`.
- **`BasicObject`** — una clase que está **por encima de `Object`**, que acabamos de descubrir. Se explica en la Parte 5.

Y comprobá que `superclass` efectivamente se saltea los mixins:

```ruby
Espadachin.ancestors
# => [Espadachin, Guerrero, Defensor, Atacante, Object, PP::ObjectMixin, Kernel, BasicObject]
Espadachin.superclass
# => Guerrero               ← saltó Defensor y Atacante: no son clases
```

`ancestors` es algo que se le pregunta a alguien capaz de tener ancestros: una clase o un módulo. `atila.ancestors` falla igual que `atila.instance_methods`.

> **Para el parcial, si te preguntan:** *¿Qué diferencia hay entre `superclass` y `ancestors`?*
> `superclass` devuelve únicamente la clase de la que se hereda directamente; no muestra mixins porque no son clases. `ancestors` devuelve la linearización completa: la lista ordenada de todos los lugares donde se busca un método, empezando por la propia clase e incluyendo los mixins en su orden de precedencia, la superclase, sus mixins, y así hasta `BasicObject`. La linearización es lo que define qué implementación gana cuando hay conflicto.

---

## 7. Ejercicio resuelto: qué métodos de un objeto vienen de un mixin 🔴

Ahora una pregunta que junta todo lo anterior, planteada como te la plantearían de verdad: **dado un objeto cualquiera, del que no sabés nada, decime cuáles de sus métodos vienen de un mixin.** No de `Atacante`, que vos sabés que está. De *algún* mixin, el que sea.

Ruby no tiene un mensaje `mixin_methods`. Uno lo buscaría, no lo encontraría, y entonces hay que armarlo con lo que hay. Es exactamente como cuando aprendías a programar: partir el problema en las porciones que sí sabés resolver. Solo que el dominio ahora es el programa.

Razonemos qué piezas tenemos:

1. Ya sabemos pedirle **los métodos** a un objeto: `methods`.
2. Ya sabemos pedirle **la linearización** a su clase: `ancestors`. Los métodos del objeto vienen, seguro, de alguno de esos lugares.
3. Ya sabemos preguntarle a cada uno de esos lugares **qué métodos define**: `instance_methods(false)`.
4. Nos falta una sola cosa: **saber cuáles de esos lugares son mixins.**

¿Cómo le preguntás a algo si es un mixin? De la misma forma que le preguntás cualquier cosa: pidiéndole la clase. Y acá aparece otro pedazo del metamodelo:

```ruby
Atacante.class
# => Module                ← un mixin es instancia de Module
Guerrero.class
# => Class                 ← una clase es instancia de Class
```

Los mixins son instancias de `Module`. Ya tenemos todas las partes:

```ruby
# 1. De todos los ancestros de la clase de atila, quedarse con los que son módulos
mixins = atila.class.ancestors.select { |ancestro| ancestro.class == Module }
# => [Defensor, Atacante, PP::ObjectMixin, Kernel]
#    (ojo: is_a?(Module) también daría true para las clases, porque una clase es un tipo
#     especial de módulo —lo vas a ver en la Parte 5—; por eso se compara la clase exacta)

# 2. Juntar todos los métodos que esos módulos definen
metodos_de_mixins = mixins.flat_map { |mixin| mixin.instance_methods(false) }
#    flat_map: aplica el bloque a cada elemento y aplana el resultado en una sola lista

# 3. Quedarse con los que atila efectivamente entiende
metodos_de_mixins & atila.methods
# => [:potencial_defensivo, :potencial_defensivo=, :energia, :energia=, :sufri_danio, :descansar,
#     :potencial_ofensivo, :potencial_ofensivo=, :descansado, :descansado=, :atacar,
#     :pretty_print, ...,
#     :class, :methods, :send, :is_a?, :instance_variables, ...]
#    & es la intersección de dos listas: los elementos que están en ambas
```

Los primeros son los de `Defensor` y `Atacante`, como esperabas. Después vienen los de Pry. Y después una lista larga que viene de **`Kernel`**: resulta que casi todos los mensajes de metaprogramación que estamos usando —`class`, `methods`, `send`, `is_a?`— no viven en `Object` sino en ese mixin que `Object` incluye. Lo acabás de descubrir vos, con tres preguntas.

Dos cosas para llevarte de este ejercicio.

**Nada de esto es magia.** Son métodos que devuelven objetos, y esos objetos se trabajan con el Ruby que ya sabés: `select`, `flat_map`, intersección de listas. No hay un lenguaje aparte para metaprogramar. Solo tenés que encontrar a qué objeto mandarle qué mensaje para que te responda. Y si esto lo vas a hacer seguido, definís un método `mixin_methods` y listo: **metaprogramar no es dejar de programar.**

**Hay más de una forma.** Esta es una. En la Parte 3 vas a ver un mensaje que le podés hacer a un método para que te diga directamente quién lo definió, y con eso este ejercicio se resuelve de otra manera. Lo importante es que con las herramientas de esta parte ya podés responderlo solo.

*(La cátedra publica en el contenido de la materia una guía del lenguaje con los métodos más útiles. Tenela a mano; no la necesitás para seguir este apunte, pero te va a ahorrar búsquedas cuando programes.)*

---

## 8. El estado: qué guarda un objeto adentro 🔴

Además de métodos, un objeto tiene **estado**. Y acá Ruby es particularmente generoso, tanto que hay que romper un marco conceptual que traés de otros lenguajes.

Mirá el archivo de la Parte 1: en ningún lugar dice "un guerrero tiene un atributo llamado energía". Declaramos `attr_accessor :energia`, que genera el getter y el setter. Pero el atributo en sí, la variable de instancia `@energia`, nunca se declaró. **En Ruby los atributos no se declaran.** Cualquier variable de instancia por la que preguntes, está. Si nunca la seteaste, vale `nil`; en el momento en que la seteás, existe. A diferencia de Java o de Wollok, donde primero declarás qué atributos tiene la clase y después los usás.

Hay un mensaje para ver **qué variables de instancia tiene un objeto ahora mismo**:

```ruby
atila.instance_variables
# => [:@potencial_ofensivo, :@energia, :@potencial_defensivo]
```

Tres símbolos, con **arroba**. El `@` es parte del nombre: en Ruby, `@energia` quiere decir "la variable de instancia energía", y así es como se llama.

¿Por qué responde estas tres y no todas las variables imaginables? Porque son las tres que el constructor seteó. Fijate que son exactamente las que la consola te mostró al crear el objeto: `@energia=100, @potencial_defensivo=10, @potencial_ofensivo=20`. Esa línea no es una "ficha" de la clase; es la lista de **qué campos fueron seteados hasta ahora**.

Ahora hacé que `atila` descanse, y volvé a preguntar:

```ruby
atila.descansar
# => 110
atila.instance_variables
# => [:@potencial_ofensivo, :@energia, :@potencial_defensivo, :@descansado]
```

**Apareció una variable nueva.** `descansar` hace `self.descansado = true`, y hasta ese momento `@descansado` no existía en `atila`. No es que estaba escondida: no estaba. Y un guerrero recién creado sigue sin tenerla:

```ruby
conan = Guerrero.new
conan.instance_variables
# => [:@potencial_ofensivo, :@energia, :@potencial_defensivo]     ← sin @descansado
```

Dos guerreros de la misma clase, con distinto conjunto de variables de instancia. En Ruby, **qué variables tiene una instancia es propio de la instancia y se define por el uso**. Si dibujaras el diagrama de clases pondrías `descansado` como atributo de Guerrero, porque conceptualmente lo es. Pero mecánicamente no tenés forma de obtenerlo hasta que alguien lo setee.

*(Si querés verlo todavía más crudo: agregá una línea `@falopa = true` adentro de `descansar` en el archivo, salí de Pry, volvé a entrar y cargá. Un guerrero nuevo no va a tener `@falopa` hasta que descanse.)*

Esto te dice algo sobre **todas** las respuestas de esta clase: son transicionales. `instance_variables` te dice qué flechas salen del objeto **ahora**. `methods` te dice qué entiende **ahora**. Ruby te deja abrir una clase en cualquier momento y agregarle cosas —lo vas a hacer en la Parte 4— y a partir de ahí la respuesta cambia. Todo lo que le preguntás a Ruby es la respuesta correcta en este instante; no te la guardes por mucho tiempo.

---

## 9. Tres formas de decir "energía" 🔴

Ya que estamos adentro de un método, hay una distinción que hace falta tener clara, porque genera errores silenciosos. Adentro de un método de Guerrero podés escribir tres cosas que parecen la misma y no lo son:

```ruby
def atacar(otro)
  @energia          # 1. el ATRIBUTO: la variable de instancia, acceso directo
  energia           # 2. un MENSAJE a self... o una variable local. Depende.
  self.energia      # 3. un MENSAJE a self, explícito: el getter
end
```

**Forma 3, `self.energia`**, es la más clara: le mandás el mensaje `energia` al receptor implícito `self`, y ejecuta el getter.

**Forma 1, `@energia`**, es el atributo pelado. Uno casi nunca lo usa directo: se trabaja con getters y setters. Fijate que en todo el archivo, `Defensor` usa `self.energia` y `self.energia=`, nunca `@energia`. Pero el `@energia` existe por atrás, y es lo que `instance_variables` te mostró.

**Forma 2, `energia` a secas**, es la ambigua. Cuando no escribís el receptor, Ruby lo interpreta como un envío de mensaje a `self`... **si ese mensaje existe**. Si no existe, lo interpreta como una variable local. Ruby resuelve el conflicto priorizando el mensaje. Y eso tiene una consecuencia que muerde:

```ruby
def ejemplo
  energia = 5        # esto NO llama al setter. Crea una variable local llamada energia y le pone 5.
                     # El atributo @energia queda como estaba.
  self.energia = 5   # esto SÍ llama al setter energia=, que setea @energia.
end
```

Al asignar, `energia = 5` **siempre** es variable local, aunque exista el setter. Si querés el setter, el `self.` es obligatorio. Y si escribís mal el nombre de un getter sin `self.` —`enrgia` en vez de `energia`— Ruby no falla: inventa una variable local con ese nombre, que vale `nil`, y el error aparece tres líneas más adelante en otro lado. Cuidado con eso.

### Y `attr_accessor` no es una palabra clave

Ya que estamos mirando el archivo con estos ojos, esta línea merece una segunda lectura:

```ruby
module Defensor
  attr_accessor :potencial_defensivo, :energia
```

Eso no es una declaración ni una palabra reservada del lenguaje. **Es un envío de mensaje.** Todo lo que escribís en el cuerpo de una clase o un módulo es un mensaje que se le manda a esa clase o a ese módulo —no a las instancias, a la clase misma. Esa línea es exactamente lo mismo que `self.attr_accessor(:potencial_defensivo, :energia)` con `self` siendo `Defensor`. Ruby te deja sacar el `self.` y los paréntesis, nada más.

Y lo que hace ese mensaje es solo esto: **generar el getter y el setter**. `energia` y `energia=`. No declara el atributo, no lo inicializa, no lo crea: el atributo va a existir cuando alguien lo setee, como vimos. En la Parte 4 vas a programar `attr_accessor` a mano, y ahí se termina de entender que no tiene nada de primitivo.

---

## 10. Leer y escribir el estado desde afuera 🔴

Volvamos al estado. Si tenés a `atila` y querés saber su energía, en condiciones normales le mandás el getter: `atila.energia`. Así se trabaja en objetos: el objeto te expone una interfaz para consultar su estado, y vos la usás.

Pero pensá en el otro universo, el del metaprograma. `atila.energia` es un **hardcodeo** de tu conocimiento de que `energia` es un campo de atila. No se maneja dinámicamente: si mañana el campo se llama distinto, esa línea no se entera. Y si estás escribiendo una herramienta que dibuja diagramas de objetos —cualquier objeto, de cualquier programa— vas a necesitar leer campos **para los que no hay getter**, porque el autor de la clase los dejó privados. ¿Cómo hacés?

Hay un mensaje para leer una variable de instancia directamente, sin pasar por ningún getter:

```ruby
atila.instance_variable_get(:energia)
# NameError: `energia' is not allowed as an instance variable name
```

Falló, y el error es instructivo: **el nombre de la variable incluye el arroba**. Hay que pasarle exactamente el símbolo que `instance_variables` te devolvió:

```ruby
atila.instance_variable_get(:@energia)
# => 110
```

Y para escribir, el simétrico:

```ruby
atila.instance_variable_set(:@energia, 80)
# => 80
atila.energia
# => 80                  ← el getter confirma que el atributo cambió
atila
# => #<Guerrero:0x000055c7452ed490 @descansado=true, @energia=80, @potencial_defensivo=10, @potencial_ofensivo=20>
```

Acabás de cambiarle la energía a un guerrero sin usar su setter. Bypaseaste la interfaz que el objeto ofrece.

**Esto no se hace programando el dominio.** Si estás modelando guerreros, usás el setter, porque para eso está y porque el objeto es el que tiene que garantizar que su estado sea consistente. Estos mensajes son para cuando **el dominio de tu problema son programas**: una herramienta que necesita leer o escribir estado de objetos que no conoce y que no le van a ofrecer un getter. Las reglas son otras porque el problema es otro.

> **Para el parcial, si te preguntan:** *¿Qué hace `instance_variable_get` y cuándo se justifica usarlo en vez del getter?*
> Lee directamente una variable de instancia de un objeto, por su nombre (con arroba), sin pasar por ningún método. Se justifica cuando se está metaprogramando: una herramienta que trabaja sobre objetos que no conoce y que no exponen getter para ese campo. En código de dominio se usa el getter, porque el objeto es responsable de su propio estado.

---

## 11. `send`: mandar un mensaje sin hardcodearlo 🔴

Con `instance_methods` ya podés obtener la lista de selectores que entiende un objeto. Volvamos al framework de testing de la Parte 1: puede filtrar los selectores que empiezan con `test`, y ya sabe cuáles métodos son tests. Pero después los tiene que **ejecutar**. Y no puede escribir `objeto.test_suma`, porque no sabe que se llama `test_suma`. Tiene un símbolo en una variable y quiere mandarlo como mensaje.

Hay un mensaje para mandar mensajes:

```ruby
atila.send(:descansar)
# => 90                  ← hizo exactamente lo mismo que atila.descansar
```

Y la gracia no es esta línea, donde el selector está escrito a mano. La gracia es esta:

```ruby
selector = :descansar    # el selector es un VALOR: puede venir de una lista, de un cálculo, de otro lado
atila.send(selector)
# => 100
```

¿Cuál es la diferencia real entre `atila.descansar` y `atila.send(:descansar)`? En `atila.descansar`, la palabra `descansar` está hardcodeada en el código: no es un ciudadano de primer orden, no la podés guardar, concatenar ni pasar por parámetro. En `atila.send(:descansar)`, `descansar` es **un valor**: un símbolo que podés armar como quieras. Fijate que esto no funciona:

```ruby
atila.selector
# NoMethodError: undefined method `selector' for #<Guerrero:0x...>
#   ← le mandaste el mensaje "selector", que no tiene nada que ver con la variable selector
```

`send` es la única forma de tratar un selector que viene de otro lado como un envío de mensaje. Y es un envío de mensaje común: hace el mismo recorrido que cualquier otro para encontrar el método, y falla de la misma forma cuando no lo encuentra:

```ruby
atila.send(:descansr)
# NoMethodError: undefined method `descansr' for #<Guerrero:0x...>
# Did you mean?  descansar
```

Un typo, y explota igual que `atila.descansr`. Nada te impide usar `send` en un programa común, pero sería absurdo: si sabés qué mensaje querés mandar, mandalo con el punto. `send` es para cuando **no sabés de antemano cuál va a ser el mensaje**, porque es producto de una computación.

🟢 Un detalle que conviene saber: `send` no respeta la visibilidad. Un método privado no se puede llamar con el punto desde afuera, pero con `send` sí:

```ruby
class A
  private                              # todo lo que sigue es privado
  def metodo_privado
    'cosa privada, no te metas'
  end
end

a = A.new
a.metodo_privado
# NoMethodError: private method `metodo_privado' called for #<A:0x...>
a.send(:metodo_privado)
# => "cosa privada, no te metas"      ← send se saltea el control
```

La privacidad en Ruby es una sensación: existe para que no lo hagas por accidente, no para impedírtelo.

> **Para el parcial, si te preguntan:** *¿Para qué sirve `send` si ya se puede mandar el mensaje con el punto?*
> `send` permite mandar un mensaje cuyo selector es un valor —un símbolo guardado en una variable o calculado— en vez de estar escrito fijo en el código. Es lo que necesita un framework que descubre los métodos en tiempo de ejecución y tiene que invocarlos sin conocer sus nombres de antemano. Hace el mismo method lookup que un envío común.

---

## 12. La caja de herramientas hasta acá 🔴

Todo lo de esta parte, en una tabla. Fijate que son pocos mensajes, y con esos pocos se descubre todo.

| Quiero saber... | Se lo pregunto a... | Mensaje | Responde |
|---|---|---|---|
| de qué clase es un objeto | el objeto | `class` | la clase (un objeto) |
| si un objeto es de cierto tipo | el objeto | `is_a?(Tipo)` | `true`/`false` |
| qué mensajes entiende un objeto | el objeto | `methods` | lista de selectores |
| qué métodos provee una clase a sus instancias | la clase | `instance_methods` / `instance_methods(false)` | lista de selectores |
| de quién hereda una clase | la clase | `superclass` | la superclase |
| en qué orden se busca un método | la clase o módulo | `ancestors` | la linearización |
| si algo es un mixin | el módulo | `class` | `Module` |
| qué variables tiene un objeto ahora | el objeto | `instance_variables` | lista de símbolos con `@` |
| el valor de una variable, sin getter | el objeto | `instance_variable_get(:@x)` | el valor |
| cambiar una variable, sin setter | el objeto | `instance_variable_set(:@x, v)` | el valor nuevo |
| mandar un mensaje cuyo nombre es un valor | el objeto | `send(:selector)` | lo que responda el método |

Con esto queda cubierto lo básico de introspection: descubrir de dónde le viene el comportamiento a un objeto, qué estado tiene, y cómo interactuar con él sin hardcodear nada. La Parte 3 formaliza el recorrido que Ruby hace para encontrar un método, y después obtiene el método en sí —no el nombre— como un objeto al que se le pueden hacer preguntas.

---

### Antes de seguir, tres preguntas para vos

1. `atila.methods` y `Guerrero.instance_methods` devuelven la misma lista. ¿Por qué entonces no son el mismo mensaje, y por qué `atila.instance_methods` falla?
2. Si dos instancias de la misma clase pueden tener distinto conjunto de variables de instancia, ¿qué te dice eso sobre lo que `instance_variables` está respondiendo realmente?
3. Adentro de un método escribís `energia = energia - 10` para que el guerrero pierda energía. No pasa nada. ¿Qué hizo Ruby con esa línea?

*(Las respuestas no están acá. Si alguna no te sale, es la señal de qué releer.)*
