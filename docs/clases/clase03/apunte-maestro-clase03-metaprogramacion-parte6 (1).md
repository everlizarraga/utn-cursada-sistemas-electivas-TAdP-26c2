# 📘 Apunte Maestro — Clase 03: Metaprogramación en Ruby

## Parte 6 — Autoclases y el method lookup de verdad

**Materia:** Técnicas Avanzadas de Programación (TAdP) · **Unidad:** clase03 · **Clase del:** 29/08/2026

> **Serie completa:** Parte 0 (entorno) · Parte 1 (qué es metaprogramar) · Parte 2 (introspection) · Parte 3 (method lookup y métodos como objetos) · Parte 4 (self-modification) · Parte 5 (el metamodelo) · **Parte 6 (autoclases y cierre)**.
> Sesión nueva: `age-clase2.rb` cargado, `atila = Guerrero.new`, `conan = Guerrero.new`, `zorro = Espadachin.new(Espada.new(30))`. Es la parte más densa de la clase. Si algo no cierra en la primera pasada, no pasa nada: el objetivo no es tenerla en la cabeza sino saber que existe y poder preguntarle a la consola.

---

## 1. Métodos estáticos: lo que Ruby no quería 🔴

Arranquemos por algo que conocés de otras tecnologías. ¿Qué es un **método estático**? Funcionalmente, un método que no se le manda a la instancia sino a la clase: no tenés que instanciar nada para usarlo. Pero ¿por qué se llama *estático* y no "método de clase"? Porque son dos conceptos distintos, y la diferencia es exactamente el tema de esta parte.

Imaginate que en `Guerrero` querés un método `crear_vikingo` que te devuelva un guerrero con una configuración particular. Un *factory method*: una forma de instanciar un tipo de guerrero. Tiene sentido que viva en `Guerrero`. En Java lo escribís como método estático, y cuando alguien escribe `Guerrero.crearVikingo()`, **eso se compila directamente como un llamado a esa función**. No hay lookup. En tiempo de compilación ya se sabe exactamente qué método se va a ejecutar. Por eso es estático: está clavado.

Y eso hace que se pierdan cosas. **No se hereda**: `Espadachin.crearVikingo()` no existe. **No se puede redefinir**: no podés hacer que `Espadachin` tenga su propio `crearVikingo`, llamar a `super`, cambiarle algo — no hay `super`, porque no hay herencia entre esas cosas. Un método estático es, básicamente, una **función global** que asociás a una clase para tener un lugar donde escribirla. Nada más. Da igual que esté ahí o en cualquier otro lado.

Es muy distinto de `objeto.mensaje`, donde hay lookup: no sabés de antemano qué método se ejecuta, se busca en la jerarquía en tiempo de ejecución.

¿Dónde hay métodos estáticos? En los lenguajes donde **las clases no son objetos**. Scala los tiene. Smalltalk no: en Smalltalk las clases son objetos, así que `crearVikingo` es un mensaje que se le manda a la clase, y como es un envío de mensaje, se hereda, se redefine, se le hace `super`. Todo lo que se puede hacer con métodos, a nivel de clases.

**Ruby quiere eso.** Ruby quiere que lo que otros llaman métodos estáticos sean en realidad **mensajes que le mandás al objeto clase**, con lookup, con herencia, con todo.

> ⚠️ Para el examen: en Ruby no hay métodos estáticos; hay **métodos de clase**, que son mensajes enviados al objeto que representa la clase y que se resuelven con method lookup como cualquier otro. "Estático" es el concepto de Java: sin lookup, sin herencia.

---

## 2. El problema: dónde ponés `crear_vikingo` 🔴

Ahora tratemos de ubicar `crear_vikingo` en el diagrama de la Parte 5, para que lo entienda `Guerrero`. Y que lo entienda **`Guerrero`**, no cualquiera. ¿Dónde?

**¿En `Class`?** `Guerrero` lo entendería, sí: paso azul a `Class`, lo encuentra. Pero también lo entendería todo el mundo: `NilClass.crear_vikingo`, `Integer.crear_vikingo`, `Espada.crear_vikingo`. Es un método de guerreros colgado del lugar que le da comportamiento a todas las clases. No.

**¿En `Guerrero`?** Entonces lo entiende `atila`. Un método puesto en `Guerrero` es para sus instancias; el lookup de `atila` es paso azul a `Guerrero` y lo encuentra. Pero `Guerrero` mismo no lo entiende: su lookup es paso azul a `Class`, y de ahí rojos a `Module`, `Object`... nunca pasa por `Guerrero`. No.

Entonces **este lookup y este metamodelo no admiten la idea**. Necesitaría que hubiera **algo entre `Guerrero` y `Class`**: un lugar propio de `Guerrero`, donde buscar antes de pasar a `Class`.

```
   Guerrero ──azul──► [ ¿algo acá, solo de Guerrero? ] ──?──► Class
```

Smalltalk lo resuelve solo para las clases: cambia el metamodelo para que cada clase tenga una **metaclase acompañante**, creada automáticamente cuando creás la clase, que le provee comportamiento a ella y solo a ella. Y si querés, una metaclase que le provee comportamiento a esa metaclase, y otra para esa... un grupo infinito que se va creando a medida que lo vas accediendo.

Ruby da un paso más. Dice: ¿y si además de querer ponerle comportamiento a **la clase**, querés ponerle comportamiento a **`atila`**? ¿Un método que sea solo para `atila` y no para `conan`? Es la misma idea. Y si es la misma idea, que sea el mismo mecanismo, consistente, para objetos y para clases.

---

## 3. "Hasta ahora les mentí": la autoclase 🔴

Todo lo que dijimos hasta acá es verdad. Todo existe y es así. Pero el method lookup **no** es un paso azul y n pasos rojos.

**El lookup es, y siempre fue, un paso verde y n pasos rojos.**

La idea de clase existe; el camino de la clase es verdad. Pero cuando un objeto empieza a buscar un método en Ruby, **no empieza por su clase**. Empieza por una clase **dedicada a él, solo para él**, que Ruby le da a **cada objeto**. Se llama **singleton class**. En castellano, **autoclase**; también la vas a ver como *eigenclass*, que es autoclase en alemán. Tres nombres, un concepto: **una clase privada, personal, de un único objeto**, donde va el comportamiento que es solo para ese objeto.

En el diagrama es la **tercera flecha, verde**: de cada objeto a su autoclase. Y con eso el diagrama vuelve a estar incompleto, porque ahora todo lo que dijimos que era un objeto —que es todo— tiene que tener una flecha verde. Y además, para que siga siendo verdad que el lookup pasa por todos los lugares que dijimos, tiene que haber algo intermedio que conecte la autoclase con lo que ya conocíamos. Vamos por partes.

Alguien está a punto de hacer la pregunta correcta: **¿incluso las clases tienen autoclase?** Sí. Cada objeto tiene una clase para sí mismo. Y las clases son objetos; por lo tanto tienen su autoclase; y esa autoclase es un objeto; por lo tanto tiene la suya... Este diagrama podríamos no terminarlo nunca, y no lo vamos a hacer. **Las autoclases se crean de forma dinámica, solo cuando las usás.** Hasta que no pedís la autoclase de algo, no existe; en el momento en que la pedís, Ruby la crea. Si no fuera así, esto no terminaría.

---

## 4. Métodos de clase: dónde viven de verdad 🔴

Con la autoclase ya podemos ubicar `crear_vikingo`. Los métodos de clase en Ruby se escriben con `def self.`, como viste en `Peloton` (Parte 1) y en `mi_attr_accessor` (Parte 4):

```ruby
class Guerrero
  def self.crear_vikingo          # self acá es Guerrero, la clase
    self.new(70)                  # un guerrero con potencial ofensivo 70
  end

  def self.gritar
    'haaaa'
  end
end

Guerrero.crear_vikingo
# => #<Guerrero:0x... @energia=100, @potencial_defensivo=10, @potencial_ofensivo=70>
Guerrero.gritar
# => "haaaa"
atila.gritar
# NoMethodError: undefined method `gritar' for #<Guerrero:0x...>    ← no es para las instancias
```

Una cosa sobre la notación: `def self.gritar` no está pensada para vos, que ahora entendés la mecánica de abajo. Está pensada para ser intuitiva para el usuario común: "este método es **para mí**, que soy la clase". La sintaxis no trata de revelar el mecanismo; trata de ser amigable. Pero vos sí necesitás saber qué hace.

Sabemos que no lo puso en `Guerrero` (sería para `atila`) ni en `Class` (sería para todos). Verifiquémoslo:

```ruby
Guerrero.methods.include?(:gritar)
# => true                    ← Guerrero lo entiende
Guerrero.instance_methods.include?(:gritar)
# => false                   ← pero no lo provee a sus instancias: no está en Guerrero
Guerrero.class.instance_methods.include?(:gritar)
# => false                   ← y no está en Class
```

`Guerrero` entiende un método que no está ni en `Guerrero` ni en `Class`. Está en su autoclase. Y hay un mensaje para pedirla:

```ruby
Guerrero.singleton_class
# => #<Class:Guerrero>       ← así se muestra la autoclase de Guerrero
Guerrero.singleton_class.instance_methods(false)
# => [:crear_vikingo, :gritar]
```

Ahí están. `def self.` **define el método en la autoclase de la clase**. En los diagramas la vamos a llamar `#Guerrero`.

Y así como `def` tiene su versión dinámica en `define_method` (Parte 4), `def self.` tiene la suya: **`define_singleton_method`**. Recibe lo mismo —un selector como valor y un bloque— y define el método **en la autoclase del receptor**. Es un atajo: estas dos líneas son exactamente lo mismo:

```ruby
Guerrero.define_singleton_method(:gritar_fuerte) { 'HAAAA' }        # el atajo
Guerrero.singleton_class.define_method(:gritar_fuerte) { 'HAAAA' }   # lo que hace por atrás
Guerrero.gritar_fuerte
# => "HAAAA"
```

Fijate la segunda línea: es el `define_method` que ya conocés, mandado a la autoclase en vez de a la clase. Todo lo que aprendiste en la Parte 4 sobre `define_method` —nombre dinámico, bloque que retiene contexto— vale igual acá.

> **Para el parcial, si te preguntan:** *¿Dónde queda definido un método escrito con `def self.metodo` dentro de una clase? ¿Por qué no en la clase ni en `Class`?*
> En la singleton class (autoclase) de esa clase: una clase dedicada exclusivamente a ese objeto. No queda en la clase porque lo que se define ahí lo entienden sus instancias, no la clase. No queda en `Class` porque lo entenderían todas las clases del sistema. La autoclase es el lugar intermedio, propio de un único objeto, donde el lookup busca antes que en cualquier otro lado.

---

## 5. La jerarquía paralela 🔴

`#Guerrero` es una caja. Le falta la flecha roja, y de a dónde apunte depende cuántos features tenés. Uno pensaría: es una clase, eventualmente tiene que llegar a `Class`, apuntará directo a `Class`. Preguntemos:

```ruby
Guerrero.singleton_class.superclass
# => #<Class:Object>         ← la autoclase de Object, no Class
```

Apunta a **la autoclase de `Object`**. ¿Por qué? Porque si fuera derecho a `Class`, **no estarías heredando los métodos de clase**. `Espadachin` hereda de `Guerrero`; queremos que `Espadachin.gritar` funcione, y que `Espadachin` pueda redefinir `gritar` y llamar a `super`. Para eso, cuando `Espadachin` busca `gritar`, tiene que pasar primero por `#Espadachin`, después por `#Guerrero`, después por `#Object`:

```ruby
Espadachin.singleton_class.superclass
# => #<Class:Guerrero>       ← #Espadachin hereda de #Guerrero
Espadachin.gritar
# => "haaaa"                 ← heredado: lo encontró en #Guerrero
```

Son **dos caminos paralelos**: la jerarquía de clases que ya conocías, y una jerarquía fantasma de autoclases que la imita, y que se va creando a medida que se usa. Esto no es un capricho de Ruby: **en cualquier tecnología donde quieras poder redefinir métodos de clase por herencia, necesitás una jerarquía paralela**. Es la única forma de que cada clase tenga sus métodos y a la vez herede los de arriba.

¿Y hasta dónde sube? Hasta donde ya no hay más arriba:

```ruby
Object.singleton_class.superclass
# => #<Class:BasicObject>
BasicObject.singleton_class.superclass
# => Class                   ← acá sí: la autoclase de arriba de todo hereda de Class
```

`#BasicObject` es la última de la cadena, y **esa** es la que apunta a `Class`. Tiene que hacerlo: las autoclases son clases. Y fijate lo que eso significa: **si ninguna clase usara su autoclase**, buscar en `#Guerrero`, `#Object`, `#BasicObject` y llegar a `Class` es exactamente lo mismo que ir derecho a `Class`. Por eso todo lo que dijimos en la Parte 5 era verdad. Lo que pasa es que **el paso azul es conceptual**: vos no vas derecho a tu clase; pasás primero por toda la jerarquía de autoclases, y si están vacías, es como si no estuvieran.

```ruby
Guerrero.singleton_class.instance_methods.include?(:new)
# => true                    ← new le llega a #Guerrero por la cadena: #Object, #BasicObject, Class
```

### `Class` y `Module` también

Tomate un segundo para registrar el nivel de locura al que llegamos, y preguntate qué te contestaría tu yo de hace cuatro horas. `Class` tiene que tener autoclase, por supuesto. ¿A dónde apunta su flecha roja?

```ruby
Class.singleton_class
# => #<Class:Class>
Class.singleton_class.superclass
# => #<Class:Module>         ← imita la jerarquía: Class < Module
Module.singleton_class.superclass
# => #<Class:Object>         ← y Module < Object
```

Tiene sentido: si querés poner métodos que entiendan **los módulos** (como objetos, mensajes que se le mandan a `Module` o a `Atacante`), necesitás un lugar donde las clases —que son módulos— también los encuentren. Y acá es donde se conectan `Guerrero` y `Module`: no son tan distintas, las dos son subclases de `Object`, y sus autoclases van las dos a `#Object`. Y `#Object` va a `#BasicObject`, y esa a `Class`. Todas llegan a `Class`, lo cual es razonable.

---

## 6. Las autoclases de las instancias 🔴

Falta la otra mitad: las cosas que no son clases. `atila`, `conan`, `zorro`. ¿Tienen autoclase? Todo objeto tiene:

```ruby
atila.singleton_class
# => #<Class:#<Guerrero:0x000055c7452ed490>>     ← la autoclase de ESTE guerrero
conan.singleton_class
# => #<Class:#<Guerrero:0x000055c74568b980>>     ← otra, distinta
atila.singleton_class == conan.singleton_class
# => false
```

Dos guerreros, dos autoclases. Y ahora sí la pregunta de la Parte 4: agregarle un método a `atila` sin agregárselo a `conan`.

```ruby
atila.define_singleton_method(:saludar) { 'hola, soy atila' }
# => :saludar

atila.saludar
# => "hola, soy atila"
conan.saludar
# NoMethodError: undefined method `saludar' for #<Guerrero:0x...>   ← conan no lo tiene
atila.singleton_class.instance_methods(false)
# => [:saludar]
```

`saludar` está en `#atila`, y `#atila` es un lugar por el que solo pasa `atila`. Es el mismo mecanismo que `gritar` en `#Guerrero`: un lugar por el que solo pasa `Guerrero`.

### ¿A dónde apunta la flecha roja de `#atila`?

Acá está la parte fina. Uno podría pensar: las autoclases de las clases imitan la jerarquía de clases; ¿las autoclases de los objetos imitarán algo? ¿`#zorro` apunta a `#atila`?

**No.** Y no está bueno que lo haga, porque ¿quién es `atila` para `zorro`? Un objeto cualquiera. Entre las clases hay un orden: para crear `Guerrero`, primero tuvo que existir `Object`, si no no la hubieras podido usar como superclase. La sintaxis y la semántica de crear una clase establecen esa relación, y la jerarquía de autoclases la copia. Entre `atila` y `conan` **no hay ninguna relación**. Son objetos distintos que pudieron aparecer en momentos distintos, sin nada uno debajo del otro. No hay jerarquía que copiar.

Entonces, ¿a dónde va `atila` a buscar código si no lo encuentra en su autoclase? A donde sabemos que tiene que ir. **A su clase.**

```ruby
atila.singleton_class.superclass
# => Guerrero
zorro.singleton_class.superclass
# => Espadachin
```

`#atila` hereda de `Guerrero`. No de `#Guerrero`, que es donde `atila` entendería `crear_vikingo` —y `atila` no debe entender `crear_vikingo`. De `Guerrero`, donde `atila` recibe el comportamiento que sabemos que tiene que recibir.

Y acá cierra todo: **una flecha verde seguida de una roja equivale a la flecha azul.** Al principio de la clase pensábamos que el comportamiento de `atila` estaba en `Guerrero` y que el lookup llegaba ahí con un paso azul. Eventualmente llega. Pero antes, siempre, pasa por su autoclase. Todo siempre fue verdad, visto con filtros.

Mirá la linearización completa de `atila`, pidiéndosela a su autoclase:

```ruby
atila.singleton_class.ancestors
# => [#<Class:#<Guerrero:0x...>>, Guerrero, Defensor, Atacante, Object, PP::ObjectMixin, Kernel, BasicObject]
#     ▲ la autoclase, primero              ▲ y de ahí en adelante, lo que ya sabíamos
```

Y compará con lo que responde `Guerrero.ancestors`, que arranca en `Guerrero`: **la clase no sabe nada de las autoclases de sus instancias**. Esto va a importar en un rato.

### Otras formas de ponerle cosas a un solo objeto 🟢

`define_singleton_method` no es la única. Como la autoclase es una clase, le podés hacer lo que le hacés a cualquier clase: incluirle un mixin, o mandarle `attr_accessor`, que —ya sabés— es un mensaje que entienden los módulos:

```ruby
module Presentable
  def presentarse
    'un gusto'
  end
end

atila.singleton_class.include Presentable   # incluir un mixin en la autoclase de atila
atila.presentarse
# => "un gusto"
conan.extend Presentable                    # extend: atajo para "incluí esto en mi autoclase"
conan.presentarse
# => "un gusto"
zorro.presentarse
# NoMethodError                             ← zorro no fue tocado

atila.singleton_class.attr_accessor :edad   # un getter y un setter solo para atila
atila.edad = 40
atila.edad
# => 40
zorro.edad
# NoMethodError                             ← zorro no tiene edad
```

Un detalle que explica una flecha del diagrama: `nil` es un objeto tan especial que **su autoclase es su propia clase**:

```ruby
nil.singleton_class
# => NilClass                               ← verde y azul apuntan al mismo lugar
```

> **Para el parcial, si te preguntan:** *¿Cuál es la superclase de la autoclase de `Guerrero`, y cuál la de la autoclase de `atila`? ¿Por qué la diferencia?*
> `Guerrero.singleton_class.superclass` es `Object.singleton_class`: las autoclases de las clases forman una jerarquía paralela a la de las clases, para que los métodos de clase se hereden y puedan redefinirse (`#Espadachin` → `#Guerrero` → `#Object` → `#BasicObject` → `Class`). `atila.singleton_class.superclass` es `Guerrero`, su clase: entre las instancias no hay ninguna relación de orden que copiar, así que la autoclase de una instancia hereda directamente de la clase de esa instancia. En los dos casos, el lookup es un paso a la autoclase y después pasos `superclass`.

---

## 7. El diagrama, completo 🔴

Este es el metamodelo de Ruby entero. Leelo con la tabla de abajo, y verificá cada flecha en la consola: **cada una es una pregunta que ya sabés hacer**.

```
   LEYENDA   ──azul──►  class          ──rojo──►  superclass          ──verde──► singleton_class
             ✱ = tiene flecha azul hacia Class (se omite el trazo)
             Cada caja X tiene además una flecha verde hacia su autoclase #X (columna derecha).

        CLASES Y OBJETOS                                     AUTOCLASES

          BasicObject ✱ ──rojo (punteada)──► nil             #BasicObject ──rojo──► Class
               ▲                                                  ▲
               │ rojo                                             │ rojo
          Object ✱ (+Kernel)                                 #Object ◄──rojo── #Module ◄──rojo── #Class
               ▲        ▲                                         ▲
               │ rojo   │ rojo                                    │ rojo
          Guerrero ✱    NilClass ✱ ◄──azul y verde── nil       #Guerrero          #NilClass ──rojo──► #Object
               ▲                                                  ▲
               │ rojo                                             │ rojo
          Espadachin ✱                                        #Espadachin

          Module ✱ ──rojo──► Object
          Class  ──rojo──► Module          Class ──azul──► Class (a sí misma)

          atila ──azul──► Guerrero         atila ──verde──► #atila ──rojo──► Guerrero
          conan ──azul──► Guerrero         conan ──verde──► #conan ──rojo──► Guerrero
          zorro ──azul──► Espadachin       zorro ──verde──► #zorro ──rojo──► Espadachin
```

| Desde | Flecha | Hacia | Lo verificás con |
|---|---|---|---|
| cualquier objeto `x` | verde | `#x` | `x.singleton_class` |
| `#atila`, `#conan` | rojo | `Guerrero` | `atila.singleton_class.superclass` |
| `#zorro` | rojo | `Espadachin` | `zorro.singleton_class.superclass` |
| `#Espadachin` | rojo | `#Guerrero` | `Espadachin.singleton_class.superclass` |
| `#Guerrero`, `#NilClass`, `#Module` | rojo | `#Object` | `Guerrero.singleton_class.superclass`, etc. |
| `#Class` | rojo | `#Module` | `Class.singleton_class.superclass` |
| `#Object` | rojo | `#BasicObject` | `Object.singleton_class.superclass` |
| `#BasicObject` | rojo | `Class` | `BasicObject.singleton_class.superclass` |
| toda autoclase | azul | `Class` | `Guerrero.singleton_class.class` |
| `nil` | verde | `NilClass` | `nil.singleton_class` (caso especial) |
| *(las azules y rojas de la columna izquierda son las de la Parte 5)* | | | |

### El method lookup, definitivo

Con todo esto, el algoritmo real, que vale para instancias y para clases por igual:

1. **Un paso verde**: a la autoclase del receptor.
2. **n pasos rojos**: por las superclases de esa autoclase, hasta llegar a `nil`.
   - Si el receptor es una **instancia**, el primer paso rojo cae en su clase, y de ahí sigue por la jerarquía de clases que ya conocías (con los mixins de cada clase en su linearización).
   - Si el receptor es una **clase**, los pasos rojos recorren primero la jerarquía paralela de autoclases (`#Guerrero`, `#Object`, `#BasicObject`), después `Class`, `Module`, `Object`, `BasicObject`.
3. Cuando del otro lado de una flecha roja hay `nil`, se corta. Si no se encontró el método, `NoMethodError`.

> **Para el parcial, si te preguntan:** *Describa el method lookup completo de Ruby.*
> Al recibir un mensaje, el objeto busca el método primero en su singleton class (autoclase), y después sube por la cadena de `superclass` hasta encontrar `nil`. Para una instancia, la superclase de su autoclase es su clase, y desde ahí sigue por mixins y superclases. Para una clase, la superclase de su autoclase es la autoclase de su superclase (jerarquía paralela), hasta `#BasicObject`, cuya superclase es `Class`; desde ahí sigue por `Module`, `Object` y `BasicObject`. En todos los casos: un paso `singleton_class`, n pasos `superclass`, corte en `nil`.

---

## 8. Por qué Ruby lo hace así, y qué te cambia 🟡

Ruby es un lenguaje que **no te deja definir un objeto suelto**, como el `object` de Wollok. En Wollok escribías `object tal` y el objeto tenía los métodos adentro: era un contenedor de código, buscaba en sí mismo y si no en su superclase; no necesitaba autoclase ni nada. En Ruby siempre tenés que definir una clase e instanciarla. Si querés una sola instancia, creás una clase y la instanciás una vez. ¿Y si querés lógica solo para **esa** instancia y no para las otras? Tenés diez guerreros y uno es un loquito que hace algo distinto. "Bueno, hacele una clase." No, no quiero: ya es instancia de algo, ya lo tengo. Ruby te dice: ponéselo en su autoclase.

¿Era necesario resolverlo así? No. Podría haber otras formas de lograr lo mismo. Así lo resolvió Ruby, te guste o no. Y después de ver muchos lenguajes, la razón por la que la materia usa Ruby para esto es que **esto es elegante y es claro** comparado con cómo lo implementan otros.

Y te cambia la perspectiva para diagnosticar. Escenario: mandás un mensaje, no responde lo que corresponde, vas a la clase, lees el método, dice que devuelve 7, lo llamás, no devuelve 7. Brujería. Si no sabés que existen las autoclases, **te podés pasar el resto de tu vida buscando ese método**: le pediste `ancestors` a la clase, la clase te dio *su* jerarquía, y no te dio lo que venía antes. Vos tenías que saber que eso existía.

Por eso es muy importante que cuando vayas a trabajar en una tecnología conozcas su metamodelo. No hace falta tener esto de memoria: hace falta saber **que Ruby tiene la capacidad de ponerle lógica a un objeto**, y con eso solo ya podés elaborar las preguntas que te lleven a "¿cómo está cableado esto?". En el trabajo práctico se va a ser muy quisquilloso con **dónde elegís poner las cosas** y cómo modelás eso, para no contaminar la interfaz, y para que domines la capacidad de preguntar y encontrar algo en el metamodelo.

Fijate que las reglas de las que partimos eran muy simples: "¿cómo querés buscar el código? Un paso verde y pasos rojos". Y a partir de ahí, cada feature nuevo —que las clases sean objetos, que `nil` sea un objeto, que cada objeto pueda tener lógica propia— fue complicando el modelo. El modelo de Java es muchísimo más fácil. Pero Java no te deja hacer un montón de cosas, incluida esta.

---

## 9. ¿Por qué me dan una librería para romper todo? 🔴

Cerremos con la pregunta que alguien tiene que hacer. En Paradigmas partiste de una base: hay objetos, les ponés responsabilidades, esas responsabilidades tienen forma de métodos, y **la única manera de comunicarte con un objeto es mandándole mensajes**. ¿Puedo acceder a los atributos? No: le mandás mensajes, y el objeto decide si te contesta. Encapsulamiento. Delegación. No te metés adentro del objeto, no le preguntás de qué clase es: le mandás el mensaje y ahí tenés polimorfismo. Cualquier libro que leas te va a hablar de eso, y de que el objeto siempre tiene que estar en un estado consistente y garantizarlo él.

Entonces, ¿por qué te dan una librería para romper toda esa mierda? Porque **todo lo que aprendimos hoy sirve exactamente para romper esas reglas**. Revisar adentro de un objeto. Ver qué métodos tiene. Preguntarle su clase. Preguntar si es de un tipo. Leer y escribir sus atributos. Mandarle un mensaje que no sabés cuál es. Ejecutarle un método que no está en su jerarquía. Un lenguaje que quiere que trabajes de una forma te da una interfaz para trabajar de esa forma; ¿y por qué no alcanza con una sola forma? **Porque a veces hace falta.** Esa es la respuesta miserable que uno tiene sobre metaprogramación.

No estás aprendiendo algo para usar todos los días. Cuando aprendés un paradigma, aprendés "en este paradigma se trabaja así" y lo usás siempre. Cuando aprendés metaprogramación, la respuesta es: **nunca usás esto, a menos que haya que usar esto.** La metaprogramación es un **matafuego**. ¿Por qué tenés un matafuego en tu casa? ¿Querés que se prenda fuego? No: tu plan es vivir de tal manera que el matafuego nunca se use. Pero cuando haga falta, es la única forma de llegar a la escalera.

¿Por qué no usarlo siempre, si podrías escribir todos tus programas con `send` en vez de con el punto, obteniendo vos el método en vez de dejar que el objeto haga el lookup, seteando vos el atributo? Porque el paradigma de objetos **no se expresa sobre cuándo usar metaprogramación**: por más que esté definida dentro de la sintaxis de objetos, no está dentro de las reglas que guían el paradigma. Seguís usando objetos, pero los estás usando, entre comillas, mal. Y si usás esto en lo cotidiano, tu programa se vuelve **inintegrable**: no lo podés combinar con nada, no podés poner a alguien a trabajar con él, te quedás sin las garantías mínimas. Usá `define_method` para todo y el IDE deja de entender que le estás definiendo cosas a tus clases, y deja de autocompletar. Todo lo que esperás de la vida deja de funcionar.

**Las restricciones que le ponemos a los grados de libertad de una herramienta son las que hacen que esa libertad tenga sentido.** Un paradigma es un conjunto de herramientas, de restricciones y de guías de cómo usarlas. Las restricciones son las paredes sobre las cuales construís el techo. Si querés moverte para todos lados, no podés tener techo. Entonces arquitecturás: quiero una puerta acá, después capaz otra allá.

¿Cuándo usás metaprogramación, entonces? **De una forma súper controlada**, porque activamente rompe todas las expectativas de cualquier usuario de tu código. Y esto se pone mucho peor la clase que viene: lo de hoy es el contrato seguro, lo que todavía no es agresivo con las reglas del programa. La semana que viene vas a hacer métodos con interfaces infinitas, y operaciones cuyo solo uso hace que otras operaciones ya no signifiquen lo que creías. Vas a ver que preguntar `methods` no te da las garantías que creías, porque no estás considerando todas las otras cosas locas que se pueden hacer —igual que hoy, cuando el lookup "era un paso azul" hasta que dejó de serlo.

Pero con estas herramientas se pueden construir programas que no se podrían construir de ninguna otra manera. Si antes de hoy te pidiera implementar herencia múltiple en Ruby, no podías: tendrías que cambiar el parser, el metamodelo, y tampoco sabrías hacerlo. Hoy es tan fácil que no llegaría a ser un trabajo práctico —probablemente te falte una herramienta que se ve la semana que viene, pero se puede. **Para definir reglas nuevas en el paradigma, necesitás romper las que hay.** El que va a arreglar los semáforos no puede parar en los semáforos.

Ahora, **no tenés que cambiar cómo programás normalmente.** No empieces a cuestionarte si cada objeto debería tener una autoclase. Probablemente no. Si llegaste hasta acá sin usar esto, hay una manera de seguir sin esto. Pero una vez que necesitás un método en un solo lugar, ahí sí, lo tenés que usar, y cualquier otro camino va a estar mal.

### Cuándo se justifica

Criterio práctico, con dos casos.

**Mal uso.** Tenés tres tipos de alumno, cada uno calcula su nota distinto. Lo resolvés preguntándole al objeto de qué clase es y haciendo `if es de tal clase entonces esto, si es de tal otra entonces aquello`. El triángulo de objetos —encapsulamiento, delegación, polimorfismo— te dice que no: eso está mal, para eso está el polimorfismo. Si usás metaprogramación **sabiendo qué mensaje querías mandar**, estás haciendo trampa, y los objetos no se van a portar como deberían.

**Buen uso.** Cuando **no sos vos el que define la cosa**. Cuando escribís código pensando en un dominio que todavía no existe: cambiás cosas para que otro pueda después escribir clases que vos no conocés, con mensajes que no sabés cuáles van a ser. Ahí no hay otra forma. Eso es hacer frameworks, y de eso se trata el trabajo práctico.

Es relativo al tipo de trabajo: en diseño web, esto lo vas a usar en casos muy particulares; haciendo frameworks, tampoco todos los días. Y la línea se desdibuja: en JavaScript, `objeto.campo = function...` es el `define_method` de JavaScript, y es la forma normal de hacer las cosas. Distinguir cuándo un problema amerita metaprogramación es como distinguir cuándo usar herencia y cuándo composición: no hay regla, hay que formar un criterio de diseño durante un año, y aún así vas a dudar. Los dos trabajos prácticos que siguen en el aula son para juntar casos concretos y afinar ese criterio.

> **Para el parcial, si te preguntan:** *¿Cuándo se justifica usar metaprogramación?*
> Cuando el problema no puede resolverse dentro de las reglas del paradigma: típicamente al construir frameworks o herramientas que trabajan sobre programas y dominios que su autor no conoce de antemano, y por lo tanto deben descubrir clases, métodos y atributos en tiempo de ejecución. No se justifica para resolver problemas de dominio conocido, donde mandar mensajes y usar polimorfismo alcanza: usarla ahí rompe el encapsulamiento y las garantías del programa sin necesidad.

---

## 10. Información operativa de la cursada 🟡

Lo que se dijo en clase que afecta a la cursada, todo junto:

- **Queda una clase teórica más** sobre este tema (la clase 4), y es necesaria para hacer el trabajo práctico.
- **El trabajo práctico se libera esta semana.** Conviene arrancarlo ya, aunque no tengas todas las herramientas: por lo menos para chocarte con qué te falta. Hay aspectos que no vas a poder encarar hasta la clase que viene, y está bien.
- Después de la clase 4 hay **dos clases prácticas**, donde se encaran problemas —incluidos trabajos prácticos viejos— y se ve cómo se resuelven con esto.
- En el medio hay un **checkpoint**: hay que llegar con el TP lo más construido posible. Si llegás sin nada, la ayuda que te pueden dar es mucho menor.
- **Grupos:** todo el mundo tiene que estar anotado en la planilla. Si no estás en un grupo, estás en falta y la cátedra no sabe que existís: escribí por Discord o por mail.
- **Esta semana se asigna el ayudante y el team de GitHub** a cada grupo. Los accesos vencen: aceptá la invitación apenas llegue y clonate el repo, que viene con la base que necesitás para el TP.
- **Asegurate de que tu ambiente funcione** para la semana que viene. Si llegaste hasta acá con la Parte 0 hecha, ya está.
- En la corrección del TP se va a ser **muy quisquilloso con dónde elegís poner cada cosa** y cómo lo modelás, para no contaminar la interfaz.
- La cátedra tiene, en el contenido de la materia, una **guía del lenguaje** con los métodos útiles, y una **grabación** que recorre este tema despacio, paso por paso. Ninguna es necesaria para seguir este apunte; están si querés otra pasada.

---

## Checkpoint de la clase 03

Diez preguntas sobre toda la clase, sin respuestas. Si podés responderlas sin mirar el apunte, la clase está entendida. Si alguna no sale, es la señal de qué releer.

1. ¿Qué diferencia hay entre metaprogramación y reflection, y cuáles de los tres tipos de reflection se trabajan en la materia?
2. `atila.methods` devuelve una lista de símbolos. ¿Por qué esa respuesta "miente", y qué mensaje devuelve el método de verdad?
3. Explicá por qué `atila.is_a?(Atacante)` es `true` pero `atila.class == Atacante` es `false`.
4. ¿Qué diferencia hay entre `superclass` y `ancestors`? ¿Cuál de los dos describe el method lookup y por qué?
5. Dos instancias de `Guerrero` pueden tener distinto conjunto de variables de instancia. Explicá por qué y qué implica sobre "declarar atributos" en Ruby.
6. ¿Qué diferencia hay entre `atila.send(:descansar)` y `atila.method(:descansar).call` respecto del method lookup?
7. Un `UnboundMethod` de una clase solo se puede bindear a instancias de esa clase o de sus subclases, pero uno de un módulo se puede bindear a cualquier objeto. ¿Por qué tiene sentido esa asimetría?
8. `Class.class` es `Class` y `BasicObject.superclass` es `nil`. Explicá por qué ninguna de las dos cosas hace que el lookup entre en un loop infinito.
9. ¿Dónde queda un método definido con `def self.x` dentro de una clase, y por qué no podía quedar ni en la clase ni en `Class`?
10. `Guerrero.singleton_class.superclass` es `#Object`, pero `atila.singleton_class.superclass` es `Guerrero`. ¿Por qué las autoclases de las clases forman una jerarquía paralela y las de las instancias no?

---

**FIN DEL APUNTE MAESTRO — Clase 03: Metaprogramación en Ruby**
