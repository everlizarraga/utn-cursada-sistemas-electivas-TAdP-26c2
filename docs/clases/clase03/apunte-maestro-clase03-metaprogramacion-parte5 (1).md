# 📘 Apunte Maestro — Clase 03: Metaprogramación en Ruby

## Parte 5 — El metamodelo: las clases son objetos

**Materia:** Técnicas Avanzadas de Programación (TAdP) · **Unidad:** clase03 · **Clase del:** 29/08/2026

> **Serie completa:** Parte 0 (entorno) · Parte 1 (qué es metaprogramar) · Parte 2 (introspection) · Parte 3 (method lookup y métodos como objetos) · Parte 4 (self-modification) · **Parte 5 (el metamodelo)** · Parte 6 (autoclases y cierre).
> Sesión nueva: `age-clase2.rb` cargado, `atila = Guerrero.new`, `zorro = Espadachin.new(Espada.new(30))`. Esta parte es la picante: acá se entiende por qué las cosas se conectan como se conectan. Tranquilo si la primera lectura no cierra del todo; se aterriza releyendo.

---

## 1. Lo que ya sabíamos del dibujo 🔴

Volvamos a las dos flechas. **Azul** es `class`: "este objeto es instancia de esta clase". **Rojo** es `superclass`: "esta clase hereda de esta otra". Y volvamos al diagrama tal como quedó en la Parte 3:

```
                       ┌──────────┐
                       │  Object  │
                       └────▲─────┘
                            │ rojo
                       ┌────┴─────┐      azul      ┌───────┐
   atila ─────────────►│ Guerrero │───────────────►│ Class │
              azul     └────▲─────┘                └───────┘
                            │ rojo
                       ┌────┴──────┐
   zorro ─────────────►│ Espadachin│
              azul     └───────────┘
```

Hay una flecha ahí que todavía no discutimos en serio: la azul que sale de `Guerrero`. ¿Cómo la descubrimos? Con el mismo mensaje de siempre, aplicado dos veces:

```ruby
atila.class
# => Guerrero                ← atila es instancia de Guerrero
atila.class.class
# => Class                   ← y Guerrero es instancia de Class
```

`Guerrero` es una **caja**: un proveedor de comportamiento, el lugar donde `atila` va a buscar sus métodos. Pero también es **un objeto**, así que tiene su propia flecha azul, y apunta a otra caja que se llama `Class`. Entonces `Class` también es un proveedor de comportamiento. ¿Qué cosas provee? ¿Qué entiende `Guerrero` gracias a ser instancia de `Class`?

Pensalo así: lo que tiene `Guerrero` lo definimos nosotros, y son los mensajes que entiende `atila`. Pero `Guerrero` mismo entiende cosas que **no** definimos nosotros. Por ejemplo:

```ruby
Guerrero.new
```

`new` no está definido para `Guerrero` exclusivamente. Está definido **para todas las clases**. `Guerrero` entiende `new` porque es instancia de `Class`, y `Class` es donde vive `new`. Comprobalo:

```ruby
Class.instance_methods(false)
# => [:allocate, :superclass, :subclasses, :attached_object, :new]
#    (la lista exacta depende de la versión de Ruby; lo que importa es que new está acá)
```

Ahí está `new`. Y `superclass`, que venimos usando: es un mensaje que entienden las clases porque `Class` se lo provee. 🟢 Fijate también `subclasses`: preguntarle a una clase cuáles son sus hijas es perfectamente razonable, pero la mayoría de las tecnologías no lo ofrecen —si una clase conociera a todas sus subclases, esas subclases nunca podrían liberarse de memoria aunque ya no tuvieran instancias. Ruby lo agregó hace poco.

---

## 2. Por qué el diagrama está incompleto (y de quién es la culpa) 🔴

Ya dijimos en la Parte 3 que el diagrama está incompleto. Ahora conviene decir **por qué**, porque no es que le falten cosas porque sí.

**Si estuviéramos en Java, el diagrama ya estaría terminado.** Círculos con flecha azul, cajas con flecha roja, `Object` arriba, listo. La clase se habría acabado. Pero Ruby quería más cosas que Java. Ruby quería *features*. Y cada feature que le pedís a un lenguaje tiene un precio, y ese precio **se paga siempre en complejidad del metamodelo**: cada pequeña cosa extra tiene que estar soportada por la maquinaria que hace andar el lenguaje.

¿Qué features? Ya usamos uno sin darnos cuenta. ¿Cómo se instancia un objeto en Java? `new NombreDeClase(parámetros)`: la palabra clave `new` seguida del nombre de una clase. ¿Y en Ruby? `Clase.new`: **un envío de mensaje**. Parece una diferencia de sintaxis. No lo es. En Java la clase es una cosa especial a la que solo podés referirte por su nombre global; en Ruby la clase es un objeto, ciudadano de primer orden, y `new` es un mensaje que se le manda como cualquier otro.

La ventaja de eso la viste en la Parte 4: `attr_accessor` tampoco es una palabra clave, es un mensaje. Cualquier cosa loca que quieras poner en el cuerpo de una clase no necesita ser una palabra clave puesta ahí por el que diseñó el lenguaje; **puede ser un mensaje que definís vos**. Para agregarle un feature a Java tenés que tocar el compilador de Java. Para definir `attr_accessor` en Ruby, definiste un método con recursos que ya tenías.

Y el precio está en el dibujo. Con las dos reglas de la Parte 3:

- **Regla 1:** todo lo que recibe mensajes tiene flecha azul. Y acabamos de establecer que **las cajas también reciben mensajes** (`Guerrero.new`, `Guerrero.instance_methods`). Entonces todos los cuadrados que hasta recién eran solo cajas ahora son también objetos, y **a todos les falta una flecha azul**.
- **Regla 2:** toda caja tiene flecha roja. Y `Object`, `Class` y la caja que vamos a descubrir en un rato, `Module`, no tienen. **Faltan por lo menos tres flechas rojas.**

El lookup —la cosa más importante de cómo se resuelve un envío de mensaje— necesita que esto esté completo y consistente: sin ifs raros, sin casos especiales que lo frenen. Todo objeto tiene que tener una clase; todo proveedor tiene que tener una superclase. Resolvamos primero lo rojo.

---

## 3. Las flechas rojas: hasta dónde llega la herencia 🔴

Empecemos por `Object`, que es una caja sin flecha roja. ¿Dónde está su superclase? Ya sabemos cómo averiguarlo:

```ruby
Object.superclass
# => BasicObject
```

`BasicObject`. Ya lo habíamos visto asomar al final de `ancestors` en la Parte 2. Es una clase que Ruby decide tener **por encima de `Object`**, y que tiene muy poquitas cosas:

```ruby
BasicObject.instance_methods(false)
# => [:!, :!=, :==, :__id__, :__send__, :equal?, :instance_eval, :instance_exec]
```

Ocho métodos. Compará con los más de cincuenta que `Object` (con `Kernel`) le da a cualquier objeto. `BasicObject` es un esqueleto mínimo. Ni siquiera tiene `class`:

```ruby
BasicObject.new.class
# NoMethodError: undefined method `class' for an instance of BasicObject
```

**No es algo que vayas a usar.** Cuando querés que todos tus objetos entiendan algo, el lugar es `Object` —o un mixin que le agregás a `Object`—, nunca `BasicObject`. Entonces, ¿para qué está?

Pensalo desde un punto de vista razonable: ¿qué puede haber **por encima de la idea de objeto** en un lenguaje orientado a objetos? Un **punto de extensión**. Un lugar del cual colgar cosas que existan en el lenguaje pero que no estén atadas a las reglas de los objetos. Ruby no tiene un uso especial para `BasicObject`; te lo da a vos. Si quisieras agregar objetos basados en prototipos en vez de en herencia, podrías colgarlos de ahí, porque sus instancias no están sometidas a tener clase ni todo el comportamiento de `Object`. Si quisieras meter predicados de Prolog, o un modelo con herencia múltiple donde no tenga sentido que exista `class`, ahí tenés dónde. Smalltalk hace lo mismo con una clase llamada `ProtoObject`. Java, en cambio, no te da nada: arriba está `Object` y punto, y también es perfectamente válido. Es simplemente la posibilidad de tener algo más limpio que `Object`.

Ahora bien: **`BasicObject` es una caja**, y las cajas tienen flecha roja. ¿Qué hay del otro lado?

```ruby
BasicObject.superclass
# => nil
```

En algún momento esto tenía que terminar. Y Ruby lo termina poniendo del otro lado de la flecha roja **algo que no es una caja**: `nil`.

### `nil` es un objeto, y eso tiene consecuencias

`nil` podría ser una cosa primitiva, como el `null` de Java: un puntero a la nada, un valor especial que no es nada. Pero no lo es, porque Ruby quería que `nil` fuera un objeto. Otro feature, otro precio.

Si `nil` es un objeto, por la Regla 1 tiene que tener una **flecha azul**:

```ruby
nil.class
# => NilClass
```

¿Y flecha roja? **No.** Si `nil` tuviera flecha roja no serviría como punto de corte. Es un círculo, no una caja: recibe mensajes pero no provee comportamiento. Es exactamente lo que necesita el lookup para parar.

¿Por qué `NilClass`, y no directamente `Object`? Porque `nil` sabe responder mensajes distintos que los demás objetos. Por ejemplo:

```ruby
nil.nil?
# => true
atila.nil?
# => false
```

`nil?` está definido para todos los objetos —en `Kernel`, el mixin de `Object` donde viven los mensajes básicos— respondiendo que no, y está redefinido en `NilClass` respondiendo que sí. Herencia y redefinición, nada más. Y como `NilClass` es una clase, es una caja, y tiene su flecha roja:

```ruby
NilClass.superclass
# => Object
```

Tarde o temprano tenía que llegar a `Object`, porque `nil` es un objeto y todos los objetos van a buscar su comportamiento ahí.

Y acá alguien mira el dibujo y dice: **esto es un loop infinito**. `nil` va a `NilClass`, que va a `Object`, que va a `BasicObject`, que va a `nil`, que va a `NilClass`...

```
   nil ──azul──► NilClass ──rojo──► Object ──rojo──► BasicObject ──rojo──► nil ──azul──► NilClass ──► ...  ¿?
```

**Hay un ciclo, pero no hay un loop.** Acordate de cómo se recorre: **un paso azul y después solo pasos rojos**. Si le mandás un mensaje a `nil`, va a `NilClass` (azul), después a `Object` (rojo), después a `BasicObject` (rojo), y después... no puede seguir, porque lo que hay del otro lado de la flecha roja de `BasicObject` es `nil`, que **no es un proveedor de comportamiento**: no tiene flecha roja para continuar. Se corta. El lookup nunca vuelve a dar un paso azul, así que nunca vuelve a `NilClass`. El ciclo está en el dibujo; el recorrido no lo sigue.

Dicho más mecánicamente: el lookup tiene un `if` escondido dentro de sus n pasos rojos. Cada vez que da uno, mira qué encontró del otro lado. Si es `nil`, corta: se terminó, el método no estaba. Cómo funciona eso por dentro, y qué alternativas habría para terminar el lookup, es tema de la clase que viene.

> **Para el parcial, si te preguntan:** *¿Cuál es la superclase de `BasicObject`? ¿Por qué el metamodelo no entra en un loop infinito?*
> `BasicObject.superclass` es `nil`. `nil` es un objeto (su clase es `NilClass`, que hereda de `Object`), pero no es un proveedor de comportamiento: no tiene superclase. Como el method lookup es un paso `class` seguido únicamente de pasos `superclass`, al llegar a `BasicObject` y encontrar `nil` del otro lado no puede continuar: `nil` es el punto de corte. El ciclo existe en el diagrama, pero el recorrido del lookup nunca vuelve a dar un paso `class`.

---

## 4. `Class` y `Module`: qué es una clase, en serio 🔴

Nos faltan las flechas rojas de `Class` y de una caja que aparece ahora. ¿Cuál es la superclase de `Class`? No lo adivines: preguntá.

```ruby
Class.superclass
# => Module
```

`Module`: la clase de los mixins, que ya habíamos encontrado en la Parte 2 (`Atacante.class` → `Module`). **Las clases son casos particulares de módulos.** Y tiene mucho sentido, porque dijimos que los mixins son como clases abstractas que no se pueden instanciar. Fijate dónde vive cada cosa:

```ruby
Class.instance_methods(false).include?(:new)
# => true                    ← new está en Class
Module.instance_methods(false).include?(:new)
# => false                   ← los módulos no entienden new: no se instancian

Module.instance_methods(false).include?(:attr_accessor)
# => true                    ← attr_accessor está en Module...
Module.instance_methods(false).include?(:define_method)
# => true                    ← ...y define_method también
```

`new` está en `Class`. `attr_accessor` y `define_method` están en `Module`, y por eso los podés usar tanto en un módulo como en una clase: `Defensor` los entiende porque es un `Module`, `Guerrero` los entiende porque es un `Class`, y `Class` hereda de `Module`.

Desde el punto de vista de Ruby, **la única diferencia entre un módulo y una clase es que la clase tiene los mensajes de instanciación**. Todo lo demás es módulo. El módulo es la generalización; **la clase es un mixin instanciable**.

Con eso, el dibujo se lee así: ¿quiénes son las cajas? **Los módulos** —cualquier proveedor de comportamiento es un módulo. ¿Quiénes son las cajas instanciables? **Las clases**.

*(Y ahora se entiende algo de la Parte 2: `Guerrero.is_a?(Module)` da `true`, porque `Class` hereda de `Module`. Por eso, para detectar mixins, comparamos con la clase exacta.)*

Falta la roja de `Module`:

```ruby
Module.superclass
# => Object
```

Tiene sentido: es una clase muy abstracta, y como todo, es un objeto. Pero ojo con leer mal esta flecha. `Module → Object` **no significa que los módulos son clases**; significa que **todos los módulos son objetos**. Lo que sí significa `Class → Module` es que **todas las clases son módulos**.

### Dónde poner lógica, según a quién querés que le llegue

Entendiendo el cableado, hay una regla práctica que se deduce sola, y que vas a necesitar en el trabajo práctico:

| Quiero lógica que entiendan... | La pongo en... | Ejemplo |
|---|---|---|
| todos los objetos | `Object` (o un mixin de `Object`) | `nil?`, `class`, `methods` |
| todas las clases (y solo las clases) | `Class` | `new` |
| todo lo que puede definir comportamiento: clases y módulos | `Module` | `attr_accessor`, `define_method`, `instance_methods` |

Con esto, además, ya sabés dónde tendría que ir el `mi_attr_accessor` de la Parte 4 para que lo entiendan **todas** las clases y módulos y no solo `Guerrero`: en `Module`, exactamente donde Ruby tiene el real.

> **Para el parcial, si te preguntan:** *¿Qué relación hay entre `Class` y `Module`?*
> `Class` hereda de `Module`: toda clase es un módulo. La única diferencia es que `Class` agrega los mensajes de instanciación (`new`, `allocate`); todo lo que define comportamiento —`attr_accessor`, `define_method`, `instance_methods`— vive en `Module` y por eso lo entienden tanto las clases como los mixins. `Module` hereda de `Object`, lo que significa que los módulos son objetos (no que sean clases).

---

## 5. `ancestors` no es el árbol de herencia 🔴

Con el cableado claro, una distinción que es fácil de mezclar y que en un parcial te la pueden preguntar de costado.

Si le pedís los ancestros a `Guerrero`, te va a dar los mixins que tenga adentro, después `Object`, y después `BasicObject`. Pero **`ancestors` no son las superclases**. `ancestors` es la **linearización: el camino del lookup**. El árbol de herencia es otra cosa: **son solo las flechas rojas**. Son dos conceptos que se confunden porque, a partir del segundo paso, el lookup y el camino de superclases se unifican. Pero el primer paso no: el primer paso es azul.

Y de ahí sale algo que ya dijimos en la Parte 3 y ahora se ve completo:

```ruby
atila.new
# NoMethodError: undefined method `new' for #<Guerrero:0x...>
Guerrero.new
# => #<Guerrero:0x... @energia=100, @potencial_defensivo=10, @potencial_ofensivo=20>
```

`atila` es un guerrero. `Guerrero` **no** es un guerrero: es una clase. Cuando `atila` busca `new`, va a `Guerrero` (azul), después a `Object` (rojo), después a `BasicObject` (rojo), y corta: nunca pasa por `Class`. Cuando `Guerrero` busca `new`, va a `Class` (azul) y lo encuentra. **`atila` y `Guerrero` buscan en lugares distintos**, y `atila` no tiene ningún camino que lo lleve a los métodos que entienden las clases.

Fijate el doble rol de `Guerrero` en el dibujo: puede estar **al final de una flecha azul** (como clase de `atila`) o **al final de una flecha roja** (como superclase de `Espadachin`). `atila`, en cambio, solo puede estar **al principio** de una flecha azul. Nunca al final de nada.

Y sobre qué significa exactamente esa flecha azul: no es solo "quién te provee comportamiento". Es una relación más fuerte. Es **de dónde te instanciaste**. Cuando vos escribís `class Guerrero ... end`, el código por atrás agarra a `Class`, le hace `new`, y le pone el nombre global `Guerrero` al resultado. `Guerrero` fue creado haciéndole `new` a `Class`, exactamente como `atila` fue creado haciéndole `new` a `Guerrero`. Salvo una o dos clases que aparecen mágicamente cuando arranca Ruby, **todo lo demás fue instanciado por el mismo proceso**.

---

## 6. Las flechas azules de las cajas 🔴

Ya están todas las rojas. Faltan las azules de los cuadrados: si las clases son objetos, todas tienen que tener una. Hasta ahora la única que tiene es `Guerrero`. Vamos por las demás. No estamos hablando de "los objetos" en general: estamos hablando del **objeto cuadrado que se llama `Object`**, con mayúscula. ¿De qué es instancia?

```ruby
Object.class
# => Class
Espadachin.class
# => Class
Module.class
# => Class                   ← Module es una clase
Class.class
# => Class                   ← y Class... es instancia de sí misma
```

Se ve el patrón: **todo lo que es un cuadrado apunta a `Class`**. Un cuadrado significa literalmente "soy un proveedor de comportamiento", y `Class` es quien le provee comportamiento a los proveedores de comportamiento.

Y la última respuesta es un loop: **`Class` es instancia de `Class`**. `Class` es uno de los pocos proveedores que consume lo que vende. No solo genera cosas que entienden `new`: a `Class` misma le podés decir `new`, y tiene que poder, porque si no no podría crear a las demás. ¿Cómo pasó que una clase sea instancia de sí misma? Es magia de Ruby, en su instanciación más básica, en código primitivo que no está escrito en Ruby: hace aparecer a `Class`, que es su propio abuelo.

¿Y esto no es un loop infinito en el lookup? De nuevo, no. `Class` da **un solo** paso azul (a sí misma) y después solo rojos: `Module`, `Object`, `BasicObject`, `nil`. Se va. `Module` da un paso azul (a `Class`), y después rojos: `Object`, `BasicObject`, `nil`. Pasa por... no, no vuelve a `Module`: nunca ninguna flecha roja vuelve para atrás. Nunca, estando en `Class`, volvés a `Class`, porque después del primer paso azul solo hay rojos.

Mecánicamente, **son todos objetos**. Por eso todos tienen que llegar, por línea roja, a `Object`. Ese es el diagrama hasta acá:

```
   LEYENDA:  ──azul──►  class (es instancia de)     ──rojo──►  superclass (hereda de)
             ✱  flecha azul que apunta a Class (se omite el trazo para no saturar)

                        ┌───────────────┐
        nil ──azul──►   │   NilClass  ✱ │ ──rojo──┐
         ▲              └───────────────┘         │
         │ rojo (punteada: no es una caja)        │
    ┌────┴────────────┐                           │
    │  BasicObject  ✱ │                           │
    └────▲────────────┘                           │
         │ rojo                                   │
    ┌────┴────────────┐      rojo      ┌──────────▼────┐      rojo     ┌───────────┐
    │ Object (+Kernel)│◄──────────────┤    Module   ✱ │◄─────────────┤ Class     │◄──┐
    │               ✱ │◄──────────────┴───────────────┘              │       azul│───┘ (a sí misma)
    └────▲────────────┘                                              └───────────┘
         │ rojo
    ┌────┴────────────┐
    │  Guerrero     ✱ │◄──azul── atila
    └────▲────────────┘
         │ rojo
    ┌────┴────────────┐
    │  Espadachin   ✱ │◄──azul── zorro
    └─────────────────┘
```

Y para leerlo sin pelearse con las flechas, la tabla de todas las relaciones con el mensaje que las descubre. **Cada fila la podés verificar en tu consola**; esa es la idea:

| Desde | Flecha | Hacia | Cómo lo descubrís |
|---|---|---|---|
| `atila` | azul | `Guerrero` | `atila.class` |
| `zorro` | azul | `Espadachin` | `zorro.class` |
| `nil` | azul | `NilClass` | `nil.class` |
| `Espadachin` | rojo | `Guerrero` | `Espadachin.superclass` |
| `Guerrero` | rojo | `Object` | `Guerrero.superclass` |
| `NilClass` | rojo | `Object` | `NilClass.superclass` |
| `Module` | rojo | `Object` | `Module.superclass` |
| `Class` | rojo | `Module` | `Class.superclass` |
| `Object` | rojo | `BasicObject` | `Object.superclass` |
| `BasicObject` | rojo | `nil` | `BasicObject.superclass` (punto de corte) |
| toda caja | azul | `Class` | `Guerrero.class`, `Object.class`, `Module.class`... |
| `Class` | azul | `Class` | `Class.class` (el loop) |

**Los números se cablean igual.** Si querés meter en el dibujo a `2`:

```ruby
2.class
# => Integer                 ← un círculo con flecha azul a una caja
Integer.class
# => Class                   ← y la caja con su azul a Class, como todas
Integer.superclass
# => Numeric                 ← y sus rojas hasta Object, como todas
```

Nada nuevo. Y si vos quisieras hacer aparecer una abstracción nueva —traits, por ejemplo— ya sabés dónde la colgarías: de `Module`, o en algún nivel similar, orbitando lo que es proveer comportamiento. Ya sabés cómo se cablea.

> **Para el parcial, si te preguntan:** *¿De qué clase es `Class`? ¿Por qué eso no genera un loop infinito en el lookup?*
> `Class.class` es `Class`: es instancia de sí misma, porque todas las clases son instancias de `Class` y `Class` es una clase. No hay loop porque el lookup da un único paso `class` y después solo pasos `superclass`: desde `Class` va a `Module`, `Object`, `BasicObject` y `nil`, y nunca vuelve a `Class`. Ninguna flecha `superclass` apunta hacia atrás.

---

## 7. Acá podríamos parar 🟡

Con esto, el diagrama está completo según las dos reglas: todos los círculos tienen flecha azul, todas las cajas tienen flecha azul y roja, y el lookup termina. **Este ya es un metamodelo consistente**, que soporta que las clases sean objetos, que `nil` sea un objeto, que los números sean objetos, y que todo se busque de la misma manera. Muchas tecnologías paran acá, y les alcanza.

Pero Ruby tiene **un feature más**, uno que en otras tecnologías no está. Ya lo deslizamos varias veces: en la Parte 4, cuando alguien preguntó si se le podía agregar un método a `atila` sin agregárselo a todos los guerreros, la respuesta fue "esperá". En el archivo de la Parte 1, `Peloton` tiene métodos que empiezan con `def self.` y que se le mandan a `Peloton`, no a un pelotón. ¿Dónde viven esos métodos, en este dibujo? Si los ponés en `Peloton`, los entienden sus instancias. Si los ponés en `Class`, los entiende todo el mundo. **En este dibujo no tienen dónde vivir.** Y ese es el feature que falta, y el precio que Ruby paga por él es la Parte 6.

---

## 8. Caja de herramientas de la Parte 5 🔴

Esta parte no introduce mensajes nuevos: usa `class`, `superclass` e `instance_methods(false)` sobre las cajas del metamodelo. La tabla es el mapa de **qué preguntar para descubrir cada pieza**, con el resultado al lado.

| Quiero descubrir... | Se lo mando a... | Mensaje | Responde | Probalo |
|---|---|---|---|---|
| de qué clase es una clase | la clase | `class` | `Class` | `Guerrero.class` |
| qué provee `Class` (dónde vive `new`) | `Class` | `instance_methods(false)` | incluye `:new`, `:superclass`, `:allocate` | `Class.instance_methods(false)` |
| la superclase de `Object` | `Object` | `superclass` | `BasicObject` | `Object.superclass` |
| qué tiene `BasicObject` | `BasicObject` | `instance_methods(false)` | ocho métodos, ni siquiera `class` | `BasicObject.instance_methods(false)` |
| dónde termina la herencia | `BasicObject` | `superclass` | `nil` (el punto de corte) | `BasicObject.superclass` |
| la clase de `nil` | `nil` | `class` | `NilClass` | `nil.class` |
| de quién hereda `NilClass` | `NilClass` | `superclass` | `Object` | `NilClass.superclass` |
| de quién hereda `Class` | `Class` | `superclass` | `Module` (una clase es un módulo instanciable) | `Class.superclass` |
| de quién hereda `Module` | `Module` | `superclass` | `Object` (un módulo es un objeto) | `Module.superclass` |
| si `new` está en `Class` y no en `Module` | `Class` / `Module` | `instance_methods(false).include?(:new)` | `true` / `false` | `Module.instance_methods(false).include?(:new)` |
| dónde viven `attr_accessor` y `define_method` | `Module` | `instance_methods(false).include?(:x)` | `true` | `Module.instance_methods(false).include?(:attr_accessor)` |
| la clase de `Class` (el loop) | `Class` | `class` | `Class` | `Class.class` |
| la clase de cualquier caja | la caja | `class` | siempre `Class` | `Object.class` · `Module.class` |
| que una instancia no llega a los métodos de clase | el objeto | `new` | `NoMethodError` | `atila.new` |
| que los números se cablean igual | un número / su clase | `class` / `superclass` | `Integer` / `Class` / `Numeric` | `2.class` · `Integer.class` · `Integer.superclass` |

Y la regla práctica de la sección 4, que es lo que más vas a usar: lógica para **todos los objetos** → `Object`; para **todas las clases** → `Class`; para **todo lo que define comportamiento** (clases y módulos) → `Module`.

---


### Antes de seguir, tres preguntas para vos

1. `Module → Object` es una flecha roja. ¿Qué significa exactamente y qué **no** significa?
2. Querés que **todas las clases y todos los módulos** entiendan un mensaje nuevo `mis_metodos_publicos`. ¿En qué caja lo definís y por qué no en `Object` ni en `Class`?
3. `Guerrero.ancestors` no incluye a `Class`, pero `Guerrero.new` funciona. Explicá por qué las dos cosas son ciertas a la vez.

*(Las respuestas no están acá. Si alguna no te sale, es la señal de qué releer.)*
