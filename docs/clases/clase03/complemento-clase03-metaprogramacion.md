# 🧩 Complemento — Clase 03: Metaprogramación en Ruby

**Materia:** Técnicas Avanzadas de Programación (TAdP) · **Unidad:** clase03 · **Clase del:** 29/08/2026

> **Qué es este archivo.** Dos cosas que el apunte maestro no trae. **Parte A:** aclaraciones que surgieron al estudiar la clase y que no pertenecen a ninguna parte en particular: son de Ruby, de la consola, o de cómo leer un error. **Parte B:** las respuestas a todos los checkpoints del apunte maestro (Partes 0 a 6 y el de la clase entera), en formato de respuesta de examen. Leé la Parte B recién después de haber intentado responder cada checkpoint por tu cuenta.

---

# Parte A — Aclaraciones

## A1. Leer lo que la consola te devuelve 🔴

### `puts` imprime, pero devuelve `nil`

Un método que termina en `puts` muestra el texto y **devuelve `nil`**. Lo que ves impreso es el efecto; el `=> nil` de la línea siguiente es el valor de retorno del método.

```ruby
atila.define_singleton_method(:grito) { puts "Por la horda #{self}" }
atila.grito
# Por la horda #<Guerrero:0x...>      ← el efecto: puts lo imprimió
# => nil                              ← el valor: lo que puts devuelve
```

Si querés que el método **devuelva** el texto, sacá el `puts`: `{ "Por la horda #{self}" }`. La misma distinción explica por qué `atila.method(:sufri_danio).call(30)` devuelve `nil` (su última expresión es un `if` que no se cumplió) aunque el daño se haya aplicado.

### `def` devuelve el nombre del método

Cuando cerrás un `class ... end` en la consola, la respuesta es un símbolo: el nombre del **último** `def` que había adentro. `def` es una expresión que devuelve el selector que acaba de definir; no significa que solo ese método haya quedado definido.

```ruby
class Guerrero
  def self.crear_vikingo; new(70); end
  def self.gritar; 'haaaaa'; end
end
# => :gritar                          ← el último def; crear_vikingo también quedó
```

### Los mensajes de error cambian de redacción según la versión de Ruby

El mismo error puede aparecer como `undefined method 'x' for #<Method: ...>` o como `undefined method 'x' for an instance of Method`. Es la misma excepción con distinto texto. Lo que importa es la **clase** del error (la palabra final entre paréntesis) y el receptor que nombra, no la frase exacta.

---

## A2. Qué te está diciendo cada error 🔴

Cada excepción cuenta una historia distinta sobre el method lookup. Saber leerlas ahorra la mitad del tiempo de consola.

| Error | Qué pasó | Ejemplos de esta clase |
|---|---|---|
| `NoMethodError` | El lookup **no encontró** el método en todo el camino del receptor. Fijate a quién se lo mandaste: el mensaje nombra el receptor. | `atila.gritar` (es de la clase); `Guerrero.descansar` (es de las instancias); `Vikingo.new` (un módulo no llega a `Class`); `zorro.espada` cuando `zorro` era una `Espada` |
| `NameError` | Un nombre suelto que Ruby no pudo resolver ni como variable ni como método, o un nombre mal formado. | `atila.methods fals` (sin dos puntos ni comillas, `fals` es un identificador); `instance_variable_get(:energia)` (falta el `@`) |
| `TypeError` | El lookup **sí encontró** el método, lo ejecutó, y el método rechazó lo que le pasaste o el estado en que estaba. | `bind(atila)` sobre un método de `Zanahoria` o de `#Guerrero`; `atila.singleton_class.new` |
| `ArgumentError` | Encontró el método, pero la cantidad de argumentos no coincide. | `atila.descansar` después de pisarlo con `def descansar(cuanto)` |

Regla corta: **`NoMethodError` = la búsqueda falló; cualquier otro error = la búsqueda funcionó y el método se quejó.** Si te da `TypeError`, no busques dónde está el método: ya está; buscá qué condición te pide.

> **Para el parcial, si te preguntan:** *¿Qué diferencia hay entre un `NoMethodError` y un `TypeError` al vincular un método?*
> `NoMethodError` significa que el method lookup no encontró ningún método con ese selector en la linearización del receptor. `TypeError` significa que el método fue encontrado y ejecutado, y que fue él quien rechazó el argumento: en `bind`, porque el objeto no es instancia de la clase dueña del método.

---

## A3. Comillas simples y comillas dobles 🟡

Las dos crean un `String`, y `"hola" == 'hola'` es `true`. La diferencia es qué **procesan** antes de crearlo. Las dobles hacen dos cosas que las simples no.

**Interpolación `#{...}`**, solo con dobles. Adentro de las simples es texto literal:

```ruby
attr = "apodo"
"@#{attr}"
# => "@apodo"       ← evaluó attr y lo metió adentro
'@#{attr}'
# => "@\#{attr}"    ← los caracteres tal cual
```

Por eso todo `define_method` con nombre armado usa dobles: `"comete_una_#{comida}".to_sym`. Con simples, el método se llamaría literalmente `comete_una_#{comida}`.

**Secuencias de escape** (`\n` salto de línea, `\t` tabulación), solo con dobles:

```ruby
"linea1\nlinea2".length
# => 13             ← \n es UN carácter
'linea1\nlinea2'.length
# => 14             ← la barra y la ene: DOS caracteres, y se imprimen así
```

Las simples solo reconocen `\'` y `\\`. Convención práctica: simples para texto plano (`'correr como padre'`), dobles cuando interpolás o escapás. Un string con dobles y sin `#{}` ni `\n` no está mal: funciona idéntico.

---

## A4. Cuando el objeto no es lo que creés: diagnosticar con introspection 🟡

Un error frecuente en la consola es instanciar la clase equivocada y después no entender por qué "faltan" métodos. El caso típico con `age-clase2.rb`:

```ruby
zorro = Espada.new(Espada.new(30))     # se quería Espadachin.new(Espada.new(30))
zorro.espada
# NoMethodError: undefined method `espada' for an instance of Espada
```

El mensaje ya lo dice —*for an instance of **Espada***— pero conviene tener el reflejo de verificar con las herramientas de la Parte 2 antes de buscar el problema en la clase:

```ruby
zorro.class
# => Espada                                        ← primera pregunta, siempre
zorro.instance_variables
# => [:@potencial_ofensivo]                        ← una Espada tiene solo eso
zorro.class.instance_methods(false)
# => [:potencial_ofensivo, :potencial_ofensivo=]   ← el attr_accessor de Espada
```

Tres preguntas y el diagnóstico está hecho: el objeto es una espada cuyo potencial ofensivo es otra espada. Legal, pero no lo que querías. Regla: cuando un objeto no entiende algo que "debería", preguntale `class` antes que nada.

---

## A5. `initialize` es privado 🟢

`Guerrero.instance_methods(false)` no lista `initialize` aunque esté escrito en `Guerrero`. Ruby hace privado a `initialize` automáticamente, e `instance_methods` lista solo los públicos y protegidos. Se puede ver con `Guerrero.private_instance_methods(false)`, que responde `[:initialize]`. Por la misma razón, `atila.initialize` da `NoMethodError` (privado), pero `atila.method(:initialize)` sí funciona: `method` no respeta visibilidad, igual que `send` (Parte 2).

---

# Parte B — Respuestas de los checkpoints

Formato examen: la primera oración responde; el resto justifica. Terminología de la cátedra.

## Parte 0 — Entorno

**1. ¿Qué diferencia hay entre instalar una gema e instalar un programa como RubyMine?**
Una gema es código Ruby empaquetado que se instala **adentro** del Ruby que ya tenés (`gem install`, desde rubygems.org) y corre dentro de él; RubyMine es una aplicación independiente que se instala por fuera. Por eso Pry, que es una gema, se rompe si rompés el lenguaje desde la consola: corre en el mismo Ruby que estás modificando.

**2. Si editás `age-clase2.rb` mientras Pry está abierto, ¿por qué la consola no ve el cambio?**
Porque `require_relative` carga el archivo una sola vez por sesión: lee el texto, ejecuta las definiciones y las deja en memoria. Editar el archivo no toca esa memoria. Para ver el cambio hay que salir de Pry, volver a entrar y cargar de nuevo.

**3. ¿Qué te da la consola interactiva que el botón verde de RubyMine no te puede dar?**
Un programa que sigue vivo entre pregunta y pregunta. El botón verde ejecuta el archivo de punta a punta y el programa deja de existir al terminar; la consola mantiene los objetos creados, así que podés interrogarlos y modificarlos sin recargar nada.

## Parte 1 — Qué es metaprogramar

**1. Un framework de testing tiene que descubrir qué métodos de tu clase son tests. ¿Por qué no puede tener esa información escrita de antemano?**
Porque el framework se escribe antes de que existan tus clases: su autor no conoce el dominio sobre el que va a trabajar. Lo único que puede hacer es descubrir en tiempo de ejecución qué clases hay, cuáles heredan de la base de tests y qué métodos empiezan con `test`, usando reflection.

**2. ¿Cuál es la diferencia entre metaprogramación y reflection? ¿Toda reflection es metaprogramación? ¿Al revés?**
Metaprogramación es escribir programas cuyo dominio son otros programas (los generan, manipulan o utilizan); reflection es el caso particular en que se metaprograma **en el mismo lenguaje** y desde adentro, con las herramientas que el lenguaje provee. Toda reflection es metaprogramación; no toda metaprogramación es reflection: un compilador escrito en C que procesa Ruby metaprograma sin reflection.

**3. Un compilador, un formateador y un documentador son los tres metaprogramas. ¿Qué verbo de la definición cumple cada uno?**
El compilador **genera** un programa (produce un ejecutable a partir de código fuente); el formateador **manipula** un programa (lo lee y lo reescribe); el documentador **utiliza** un programa (lee sus clases y métodos para producir otra cosa, la documentación).

## Parte 2 — Introspection

**1. `atila.methods` y `Guerrero.instance_methods` devuelven la misma lista. ¿Por qué entonces no son el mismo mensaje, y por qué `atila.instance_methods` falla?**
`methods` responde qué mensajes entiende el receptor; `instance_methods` responde qué mensajes provee el receptor a sus instancias. Coinciden porque todo lo que `atila` entiende se lo da `Guerrero`. `atila.instance_methods` falla porque `atila` no es un proveedor de comportamiento: no le da métodos a nadie, así que no tiene sentido preguntárselo.

**2. `atila` entiende `energia`, pero `energia` no aparece en `Guerrero.instance_methods(false)`. ¿Dónde está escrita, y qué está preguntando exactamente el `false`?**
Está escrita en `Defensor`, donde dice `attr_accessor :energia`. `false` significa "sin ancestros": solo lo que está escrito en esa clase, y los mixins son ancestros, así que quedan afuera igual que `Object`. `Defensor.instance_methods(false)` sí la lista.

**3. Si dos instancias de la misma clase pueden tener distinto conjunto de variables de instancia, ¿qué te dice eso sobre lo que `instance_variables` está respondiendo realmente?**
Que responde qué variables fueron **asignadas hasta ahora en ese objeto**, no una ficha de atributos de la clase. En Ruby los atributos no se declaran: una variable de instancia existe desde que alguien la asigna, y eso es propio de cada instancia y de su historia.

**4. `Guerrero` tiene `attr_accessor :peloton`, pero un guerrero recién creado no tiene `@peloton` entre sus `instance_variables`. ¿Qué hace y qué no hace `attr_accessor`?**
`attr_accessor` define dos métodos, el getter `peloton` y el setter `peloton=`; no declara ni crea la variable. `@peloton` aparece cuando alguien la asigna, típicamente vía el setter. Leerla antes da `nil` y no la crea.

**5. Adentro de un método escribís `energia = energia - 10` para que el guerrero pierda energía. No pasa nada. ¿Qué hizo Ruby con esa línea?**
Creó una variable local `energia` y le asignó el resultado; el atributo `@energia` no se tocó. Al asignar sin receptor, Ruby siempre lo interpreta como variable local, aunque exista el setter. Para llamar al setter hay que escribir `self.energia = self.energia - 10`.

## Parte 3 — Method lookup y métodos como objetos

**1. El method lookup es "un paso azul, n pasos rojos". ¿Dónde quedan los mixins en esa fórmula, y por qué no se los dibuja como cajas separadas en el diagrama?**
Los mixins quedan absorbidos dentro del paso azul: al mirar una clase, el lookup revisa la clase y sus mixins en el orden de linearización de esa clase. No se dibujan como cajas porque no tienen una posición fija en la jerarquía: cada clase linealiza los suyos por su cuenta (`Guerrero` y `Kamikaze` los ordenan al revés), así que no hay una flecha única que los ubique.

**2. Obtenés `m = atila.method(:descansar)`, y después alguien modifica `Guerrero` de forma que `atila` ya no entiende `descansar`. ¿`m.call` funciona? ¿Por qué?**
Sí, funciona y ejecuta la definición original. `method` fabrica un objeto `Method` que apunta a la definición que el lookup encontró en ese momento; `call` no hace lookup, ejecuta esa definición sobre el receptor. Modificar `Guerrero` cambia a qué definición apunta el nombre en la clase, no lo que ya apunta el `Method`.

**3. ¿Por qué un `UnboundMethod` puede responder `parameters` y `owner` pero no `call` ni `receiver`?**
Porque solo tiene la flecha al código, no la del receptor. `parameters` y `owner` son propiedades de la definición; `call` necesita un objeto sobre el cual ejecutarse y `receiver` necesita un objeto al que devolver, y un `UnboundMethod` no está vinculado a ninguno. Para ejecutarlo hay que `bind` primero.

**4. `atila.method(:descansar) == Guerrero.instance_method(:descansar).bind(atila)` da `true`, y con `equal?` da `false`. ¿Qué compara cada uno, y qué te dice eso sobre lo que devuelven `method` e `instance_method`?**
`==` compara contenido: misma definición y mismo receptor. `equal?` compara identidad: si son el mismo objeto. Que dé `true` y `false` respectivamente dice que `method` e `instance_method` **fabrican un objeto nuevo en cada pedido**: dos envoltorios distintos que apuntan a lo mismo.

**5. Tenés `d = atila.method(:descansar)` y querés ejecutar ese método sobre `conan`. ¿Qué mensajes mandás, en qué orden, y cuántos objetos nuevos aparecen en el camino? ¿Alguno de ellos cambió a `atila`, a `conan` o a `Guerrero`?**
`d.unbind.bind(conan).call`: `unbind` fabrica un `UnboundMethod` nuevo (misma definición, sin receptor), `bind(conan)` fabrica un `Method` nuevo (misma definición, receptor `conan`), y `call` lo ejecuta. Dos objetos nuevos. Ninguno modificó a `atila`, a `conan` ni a `Guerrero`: lo único que cambia es el estado de `conan` al ejecutarse `descansar`, que es efecto del método, no de `bind`.

## Parte 4 — Self-modification

**1. Creás un guerrero, después abrís `Guerrero` y le agregás un método. El guerrero viejo lo entiende. Explicalo en términos del method lookup.**
Los objetos no guardan métodos: en cada envío de mensaje el lookup da un paso azul a la clase y busca ahí. Agregar un método a `Guerrero` agrega una fila a su tabla, y la próxima vez que cualquier instancia —vieja o nueva— reciba ese mensaje, el lookup la encuentra. No hay nada que actualizar en el objeto.

**2. Definís `def atacar(un_defensor, con_fuerza)` en una clase que ya tenía `def atacar(un_defensor)`. ¿Cuántos métodos `atacar` hay ahora? ¿Por qué?**
Uno solo, el de dos parámetros. En Ruby la firma de un método es únicamente su nombre: mismo nombre, mismo método. La segunda definición pisa a la primera de forma destructiva, y `atacar(un_defensor)` con un solo argumento pasa a dar `ArgumentError`.

**3. En `mi_attr_accessor`, la variable `nombre` se calcula una vez y los dos bloques la usan cada vez que alguien llama al getter o al setter, mucho después. ¿Qué característica de los bloques hace que eso funcione, y por qué con `def` no funcionaría?**
El bloque retiene el contexto en el que fue escrito: se lleva las variables locales visibles en ese momento, y las ve cuando se ejecuta más tarde. Un `def` no ve las variables locales de afuera: su cuerpo está encerrado en el contexto de la clase.

**4. Adentro de `mi_attr_accessor` hay un `define_method` sin receptor y un `instance_variable_get` sin receptor. ¿A quién le habla cada uno, y en qué momento corre cada uno?**
`define_method` le habla a `self` en el momento en que corre `mi_attr_accessor`, y ahí `self` es `Guerrero`: corre una vez, cuando se ejecuta la línea `mi_attr_accessor :apodo`. `instance_variable_get` está dentro del bloque del getter y le habla al `self` del momento en que el getter se ejecuta, que es la instancia que recibió el mensaje (`atila`): corre cada vez que alguien hace `atila.apodo`.

**5. Movés la línea `mi_attr_accessor :apodo` arriba del `def self.mi_attr_accessor`. ¿Qué pasa y por qué?**
`NoMethodError: undefined method 'mi_attr_accessor' for Guerrero:Class`. El cuerpo de una clase se ejecuta línea por línea; cuando Ruby llega a la llamada, `Guerrero` todavía no entiende ese mensaje porque el `def self.` que lo define viene después.

**6. ¿Cómo definís, desde la consola y sin reabrir la clase, un método que entienda `Guerrero` y no `atila`? ¿En qué lista aparece después: `instance_methods(false)` o `methods(false)`?**
Con `def Guerrero.gritar; 'haaaa'; end` (la sintaxis `def <objeto>.<método>`, que adentro del cuerpo se escribe `def self.`). Aparece en `Guerrero.methods(false)`, lo que `Guerrero` entiende como objeto, y no en `instance_methods(false)`, lo que provee a sus instancias.

## Parte 5 — El metamodelo

**1. `Module → Object` es una flecha roja. ¿Qué significa exactamente y qué no significa?**
Significa que `Module` hereda de `Object`: todo módulo es un objeto y entiende lo que entienden los objetos. No significa que los módulos sean clases (eso lo dice `Class → Module`, en la otra dirección: toda clase es un módulo) ni que `Object` tenga algo que ver con proveer comportamiento a módulos.

**2. Querés que todas las clases y todos los módulos entiendan un mensaje nuevo `mis_metodos_publicos`. ¿En qué caja lo definís y por qué no en `Object` ni en `Class`?**
En `Module`. `Class` hereda de `Module`, así que lo que está en `Module` lo entienden clases y mixins por igual; en `Class` lo entenderían solo las clases y se lo perderían los mixins; en `Object` lo entendería cualquier objeto, incluido `atila`, que no provee comportamiento a nadie.

**3. `Guerrero.ancestors` no incluye a `Class`, pero `Guerrero.new` funciona. Explicá por qué las dos cosas son ciertas a la vez.**
`ancestors` es la linearización que recorre **una instancia de `Guerrero`** cuando busca un método: arranca en `Guerrero` y sube por sus mixins y superclases, y `Class` no está ahí. `Guerrero.new` es un mensaje enviado a `Guerrero` como objeto, cuyo lookup arranca con un paso azul a su clase, `Class`, donde vive `new`. Son dos caminos distintos que parten de dos receptores distintos.

## Parte 6 — Autoclases

**1. `Guerrero.methods(false)` y `Guerrero.singleton_class.instance_methods(false)` dan la misma lista. ¿Por qué son la misma pregunta hecha desde dos lados?**
Porque el lookup de `Guerrero` arranca en su autoclase: lo que `Guerrero` entiende por sí solo es exactamente lo que su autoclase provee, y la autoclase tiene una única instancia, `Guerrero`. `methods(false)` lo pregunta desde el objeto ("¿qué entiendo yo solo?") e `instance_methods(false)` desde la autoclase ("¿qué le doy a mi única instancia?").

**2. `atila.singleton_class.new` da `TypeError` y `Vikingo.new` da `NoMethodError`. Explicá cada uno en términos del lookup.**
La autoclase de `atila` es una clase: su lookup como objeto llega a `Class`, encuentra `new` y lo ejecuta, y es `new` el que se niega porque una autoclase tiene una única instancia por definición (`TypeError`). `Vikingo` es un módulo: su lookup pasa por `#Vikingo`, `Module`, `Object`, nunca por `Class`, así que `new` no se encuentra (`NoMethodError`).

**3. Tenés siete guerreros y querés que dos de ellos entiendan `grito_vikingo`, sin repetir código. ¿Qué hacés y dónde queda el método en el camino de cada uno?**
Defino `grito_vikingo` en un módulo y hago `extend` sobre los dos objetos (`atila.extend Vikingo`, `conan.extend Vikingo`). `extend` incluye el módulo en la autoclase de cada objeto, así que en el lookup de cada uno queda entre su autoclase y `Guerrero`; los otros cinco guerreros no lo ven porque `Guerrero` no cambió.

**4. `Guerrero.method(:gritar).unbind.bind(atila)` falla y `.bind(Espadachin)` funciona. ¿Qué regla de la Parte 3 explica las dos cosas?**
La de que `bind` solo acepta instancias de la clase dueña del método o de sus subclases. `gritar` es dueño de `#Guerrero`, cuya única instancia es `Guerrero`; `atila` no lo es. `Espadachin` sí es instancia de una subclase, `#Espadachin`, que hereda de `#Guerrero` por la jerarquía paralela de autoclases.

## Checkpoint de la clase 03

**1. ¿Qué diferencia hay entre metaprogramación y reflection, y cuáles de los tres tipos de reflection se trabajan en la materia?**
Metaprogramación es escribir programas cuyo dominio son otros programas; reflection es hacerlo en el mismo lenguaje y desde adentro, con las herramientas que el lenguaje da. De sus tres tipos —introspection, self-modification e intercession— la materia trabaja los dos primeros.

**2. `atila.methods` devuelve una lista de símbolos. ¿Por qué esa respuesta "miente", y qué mensaje devuelve el método de verdad?**
Porque devuelve selectores, nombres de métodos, no métodos: un símbolo no sabe qué parámetros recibe, quién lo definió ni cómo ejecutarse. El método como objeto lo devuelve `method(:selector)`, que responde un `Method`; desde la clase, `instance_method(:selector)` responde un `UnboundMethod`.

**3. Explicá por qué `atila.is_a?(Atacante)` es `true` pero `atila.class == Atacante` es `false`.**
`class` responde la clase exacta de la que el objeto es instancia, y es `Guerrero`. `is_a?` responde si el objeto pertenece a un tipo, lo que incluye su clase, las superclases y los mixins que cualquiera de ellas incluye: `Atacante` está en la linearización de `Guerrero`, así que `atila` es un atacante sin ser instancia de `Atacante`.

**4. ¿Qué diferencia hay entre `superclass` y `ancestors`? ¿Cuál de los dos describe el method lookup y por qué?**
`superclass` devuelve solo la clase de la que se hereda directamente y se saltea los mixins, que no son clases; `ancestors` devuelve la linearización completa: la clase, sus mixins en orden de precedencia, la superclase, sus mixins, hasta `BasicObject`. El lookup lo describe `ancestors`, porque es exactamente la lista ordenada de lugares donde se busca un método.

**5. Dos instancias de `Guerrero` pueden tener distinto conjunto de variables de instancia. Explicá por qué y qué implica sobre "declarar atributos" en Ruby.**
Porque una variable de instancia existe desde que alguien la asigna en ese objeto: `@descansado` aparece en el guerrero que descansó y no en el que no. Implica que en Ruby los atributos no se declaran; `attr_accessor` solo genera getter y setter, y qué variables tiene un objeto lo define su uso.

**6. ¿Qué diferencia hay entre `atila.send(:descansar)` y `atila.method(:descansar).call` respecto del method lookup?**
`send` es un envío de mensaje: hace el lookup en ese momento y ejecuta lo que encuentra. `method` hace el lookup una sola vez al fabricar el `Method`, y `call` ejecuta esa definición sin buscar nada; por eso `call` sigue ejecutando la definición original aunque la clase haya cambiado o el objeto ya no llegue a ella.

**7. Un `UnboundMethod` de una clase solo se puede bindear a instancias de esa clase o de sus subclases, pero uno de un módulo se puede bindear a cualquier objeto. ¿Por qué tiene sentido esa asimetría?**
Un método de clase puede depender de lo que esa clase garantiza a sus instancias, así que Ruby exige que el receptor lo tenga: es un cinturón de seguridad, no una limitación técnica. Un mixin, por naturaleza, está hecho para proveer comportamiento a cualquier objeto que lo incluya; sus métodos ya tienen que funcionar en cualquier contexto, y por eso se vinculan a cualquiera.

**8. `Class.class` es `Class` y `BasicObject.superclass` es `nil`. Explicá por qué ninguna de las dos cosas hace que el lookup entre en un loop infinito.**
Porque el lookup es un solo paso `class` seguido únicamente de pasos `superclass`. Desde `Class` da un paso azul a sí misma y después solo rojos (`Module`, `Object`, `BasicObject`), sin volver. Al llegar a `BasicObject`, del otro lado de la flecha roja hay `nil`, que no es un proveedor de comportamiento: no tiene superclase, y ahí se corta. El ciclo está en el dibujo, no en el recorrido.

**9. ¿Dónde queda un método definido con `def self.x` dentro de una clase, y por qué no podía quedar ni en la clase ni en `Class`?**
En la autoclase (singleton class) de esa clase, una clase dedicada exclusivamente a ese objeto. En la clase lo entenderían las instancias, no la clase; en `Class` lo entenderían todas las clases del sistema. La autoclase es el único lugar por el que pasa solo esa clase.

**10. `Guerrero.singleton_class.superclass` es `#Object`, pero `atila.singleton_class.superclass` es `Guerrero`. ¿Por qué las autoclases de las clases forman una jerarquía paralela y las de las instancias no?**
Porque entre las clases hay un orden que copiar: `Guerrero` hereda de `Object`, y para que los métodos de clase se hereden y puedan redefinirse con `super`, `#Guerrero` tiene que heredar de `#Object`. Entre `atila` y `conan` no hay ninguna relación de orden, así que no hay jerarquía que imitar: la autoclase de una instancia hereda directamente de su clase, que es donde ya sabíamos que tenía que buscar.

---

**FIN DEL COMPLEMENTO — Clase 03: Metaprogramación en Ruby**
