# 📘 Apunte Maestro — Clase 03: Metaprogramación en Ruby

## Parte 3 — El method lookup y los métodos como objetos

**Materia:** Técnicas Avanzadas de Programación (TAdP) · **Unidad:** clase03 · **Clase del:** 29/08/2026

> **Serie completa:** Parte 0 (entorno) · Parte 1 (qué es metaprogramar) · Parte 2 (introspection) · **Parte 3 (method lookup y métodos como objetos)** · Parte 4 (self-modification) · Parte 5 (el metamodelo) · Parte 6 (autoclases y cierre).
> Esta parte arranca con una sesión nueva de la consola: `age-clase2.rb` cargado y `atila = Guerrero.new` recién creado (energía 100). Todos los outputs de esta parte siguen esa sesión en orden: si los tipeás en el mismo orden, te van a dar exactamente esos números.

---

## 1. El method lookup, dibujado 🔴

En la Parte 2 terminamos con un typo:

```ruby
atila.send(:descansr)
# NoMethodError: undefined method `descansr' for #<Guerrero:0x...>
```

Ruby recibió el mensaje, lo fue a buscar, y no lo encontró en ningún lado. Ese "fue a buscar" es el **method lookup**: el recorrido que hace Ruby, cada vez que un objeto recibe un mensaje, para encontrar el código que tiene que ejecutar. Lo venís usando desde Paradigmas. Ahora lo vamos a formalizar, porque el resto de la clase se construye sobre él.

Y lo vamos a formalizar con las dos flechas de la Parte 2:

- **Flecha azul** — `class`: de un objeto a la clase de la que es instancia.
- **Flecha roja** — `superclass`: de una clase a su superclase.

Ponete en el lugar de `atila`. Te llega un mensaje. ¿Qué hacés? Lo único que podés hacer: ir al que te da el comportamiento. Tu clase. **El method lookup siempre arranca con un paso azul.**

Ese paso azul es más gordo de lo que parece: incluye mirar la definición de `Guerrero` **y también todos sus mixins, en el orden de linearización**. Primero `Defensor`, después `Atacante`. Y no podés pasar de ahí hasta que no revisaste los mixins, porque **cada clase linealiza los suyos por su cuenta**: `Kamikaze` incluye `Atacante` y después `Defensor`, al revés que `Guerrero`. No hay un vínculo fijo entre los dos módulos; cada clase decide el orden. Por eso, en el diagrama estático que vamos a completar, los mixins no se dibujan como cajas con flechas: quedan absorbidos adentro del paso azul de cada clase.

¿No lo encontraste ni en `Guerrero` ni en sus mixins? **Paso rojo**: subís a la superclase, `Object`, y mirás ahí (y en sus mixins, `Kernel`). ¿Tampoco? Otro paso rojo. Y otro. Y otro.

```
   atila ──azul──► Guerrero ──rojo──► Object ──rojo──► ... ──rojo──► (hasta que no haya más)
                   (+ Defensor,       (+ Kernel)
                      Atacante)
```

Eso es todo el algoritmo. **Un paso azul, n pasos rojos.** Tan trivial que da bronca, y es el algoritmo que más veces se ejecuta en la vida de cualquier programa orientado a objetos.

¿Cuántos pasos rojos? **Tantos como se puedan dar.** Cuando llegás a un lugar donde ya no hay flecha roja, el lookup terminó, y si no encontraste el método alguien tiene que avisarte: ese es el `NoMethodError`. Cómo termina exactamente ese camino —qué hay arriba de todo, y qué alternativas habría— lo vamos a ver en la Parte 5 y en la clase que viene. Por ahora, quedate con que termina.

Y una consecuencia inmediata que conviene notar ya: `atila` **nunca va a poder responder `new`**. `new` es algo que entiende `Guerrero`, no sus instancias. Cuando `atila` busca un método, da su paso azul a `Guerrero` y después pasos rojos hacia arriba: en ningún momento mira "la clase de la clase". Los métodos que entiende una clase y los que entiende una instancia viven en caminos distintos. Esto se vuelve central en la Parte 5.

### Dos reglas que salen del dibujo

Si el lookup es un paso azul y n rojos, se pueden deducir dos cosas del diagrama, y las dos van a ser la herramienta para completarlo:

**Regla 1 — Todo lo que recibe mensajes tiene que tener una flecha azul saliendo.** Si no tenés una clase asociada que sirva de proveedor de comportamiento, no podés arrancar el lookup, y entonces no se te pueden mandar mensajes. No sos un objeto. En el dibujo, los objetos son círculos, y **todo círculo tiene una flecha azul**.

**Regla 2 — Todo proveedor de comportamiento tiene que tener una flecha roja saliendo.** Si el lookup llega a algo que no tiene flecha roja, no puede continuar. En el dibujo, los proveedores de comportamiento son cajas, y **toda caja tiene una flecha roja**.

Y un corolario: **si te llega una flecha azul, sos una caja.** Alguien te está usando como proveedor de comportamiento.

Mirá el diagrama que teníamos:

```
                       ┌──────────┐
                       │  Object  │  ← es una caja: ¿dónde está su flecha roja?
                       └────▲─────┘
                            │ rojo
                       ┌────┴─────┐      azul      ┌───────┐
   atila ─────────────►│ Guerrero │───────────────►│ Class │  ← es una caja: ¿y su roja?
              azul     └────▲─────┘                └───────┘     y le llega una azul, así que
                            │ rojo                               también es una caja
                       ┌────┴──────┐
   zorro ─────────────►│ Espadachin│
              azul     └───────────┘
```

**Está claramente incompleto**, y las dos reglas te dicen exactamente qué falta. Lo vamos a completar en la Parte 5, con los mismos dos mensajes que ya sabés usar. Por ahora dejémoslo ahí y volvamos a los métodos, que quedó una deuda de la Parte 2.

> **Para el parcial, si te preguntan:** *Explique el method lookup de Ruby.*
> Cuando un objeto recibe un mensaje, Ruby busca el método primero en la clase del objeto (paso `class`), incluyendo los mixins de esa clase en su orden de linearización; si no lo encuentra, sube a la superclase (paso `superclass`) y repite; y así sucesivamente hasta que no hay más superclase. Un paso `class`, n pasos `superclass`. Si al terminar el recorrido no encontró el método, se produce un `NoMethodError`.

---

## 2. Un método como objeto: `Method` 🔴

En la Parte 2 dijimos que `methods` te miente un poco: le pedís métodos y te da nombres. Un nombre es un símbolo; no sabe nada del método. Ahora vamos a pedir el método de verdad.

Hay un mensaje que entienden todos los objetos, `method`, que recibe un selector y devuelve otra cosa:

```ruby
descansar_de_atila = atila.method(:descansar)
# => #<Method: Guerrero#descansar() .../age-clase2.rb:52>
descansar_de_atila.class
# => Method
```

Eso ya no es un símbolo. Es una instancia de una clase que se llama `Method`: **la representación programática de un método**, cómo Ruby modela un método como objeto. Fijate lo que la consola te muestra: la clase donde está definido, el nombre, los parámetros (ninguno) y hasta el archivo y la línea. Todo eso es información que un símbolo no podía darte.

La diferencia entre el símbolo `:descansar` y este objeto es la misma que entre el string `"Guerrero"` y el objeto `Guerrero`. El nombre sirve para nombrar. El objeto sirve para trabajar: al objeto clase le pedís que instancie, le pedís sus métodos; al objeto método le podés preguntar cualquier cosa relevante del método, y le podés pedir que se ejecute.

### Qué es, exactamente, lo que te devolvió

Antes de interrogarlo conviene tener claro qué es esa cosa que tenés en la variable, porque de acá salen todas las sorpresas de esta parte. Y para eso hay que empezar por otro lado: **dónde está el código de `descansar`.**

Cuando Ruby cargó `age-clase2.rb` y encontró el `def descansar ... end` adentro de `class Guerrero`, compiló ese código y lo guardó **en `Guerrero`**, bajo el nombre `:descansar`. Pensá a `Guerrero` como una tabla: cada nombre apunta a una definición, y la definición es el código, listo para ejecutarse.

```
┌────────────────────────────────────────────────┐
│ Guerrero                                       │
│   :descansar  ──► DEFINICIÓN de descansar      │  ← el código, guardado UNA sola vez
│   :cansado    ──► DEFINICIÓN de cansado        │
│   :lastimado  ──► DEFINICIÓN de lastimado      │
│   ...                                          │
└────────────────────────────────────────────────┘
```

Esa definición **no es un objeto que le puedas pedir a Ruby**: no tiene clase visible, no la podés guardar en una variable, no le podés mandar mensajes. Es una pieza interna. Lo único que podés hacer con ella, hasta ahora, es que se ejecute mandándole el mensaje a `atila`.

Lo que te devolvió `atila.method(:descansar)` es la otra cosa que podés hacer: pedir un **envoltorio** que la apunte. Un `Method` es un objeto nuevo, fabricado en el momento en que lo pediste, y adentro tiene exactamente dos flechas:

```
┌──────────────────────────────────────┐
│ descansar_de_atila   (un Method)     │
│   código   ──────────────────────────┼──► la DEFINICIÓN de descansar que está en Guerrero
│   receptor ──────────────────────────┼──► atila
└──────────────────────────────────────┘
```

Nada más que eso. **No tiene el código adentro: lo apunta.** No modifica a `atila` ni a `Guerrero`: los apunta. Y con este dibujo en la cabeza, cada mensaje que le mandes al `Method` en el resto de la parte tiene sentido inmediato: `owner` es en qué caja vive la definición apuntada, `receiver` es la segunda flecha, `call` es "ejecutá la definición apuntada sobre el receptor apuntado".

Una consecuencia que vale la pena probar ya mismo: **cada pedido fabrica un envoltorio nuevo.** Pedís dos veces, tenés dos objetos:

```ruby
a = atila.method(:descansar)
b = atila.method(:descansar)
a.equal?(b)
# => false      ← equal? pregunta si son EL MISMO objeto (Parte 2, símbolos): no lo son
a == b
# => true       ← == pregunta si son iguales: mismas dos flechas → iguales
```

Es la misma distinción que viste en la Parte 2 entre dos strings `"descansar"`: dos objetos distintos con el mismo contenido. Acá el "contenido" son las dos flechas. Guardate esto; va a explicar un par de resultados de la sección 3 que de otro modo parecen contradictorios.

### Qué le podés preguntar

**Sus parámetros.** Qué recibe, y cómo:

```ruby
descansar_de_atila.parameters
# => []                                  ← descansar no recibe nada

atila.method(:sufri_danio).parameters
# => [[:req, :un_danio]]                 ← recibe un parámetro, requerido, que se llama un_danio
```

La respuesta es una lista de listas. Cada sublista es una **tupla**: el primer elemento dice **de qué tipo de parámetro** se trata, el segundo es su nombre. Los tipos que vas a ver:

- `:req` — requerido: hay que pasarlo sí o sí.
- `:opt` — opcional: tiene un valor por defecto.
- `:rest` — argumentos variables: los que se declaran con `*`, "cero o más".

```ruby
atila.method(:initialize).parameters
# => [[:opt, :potencial_ofensivo], [:opt, :energia], [:opt, :potencial_defensivo]]
#    ← los tres tienen valor por defecto (20, 100, 10), por eso son :opt
```

**Cuántos parámetros recibe.** La **aridad** del método:

```ruby
atila.method(:sufri_danio).arity
# => 1
atila.method(:initialize).arity
# => -1                                  ← ¿-1?
```

Ese `-1` es Ruby diciendo "es complicado": cuando hay parámetros opcionales, la cantidad no es un número fijo, y la respuesta se codifica en negativo. Es un ejemplo de algo que va a pasar seguido: muchas facilidades de Ruby (los parámetros opcionales, los parámetros nombrados) aparecieron **después** de que estas interfaces ya existían, y las interfaces se fueron emparchando para soportarlas donde se pudo. Para saber qué recibe un método, `parameters` es más útil que `arity`.

**Quién lo definió.** El dueño del método, es decir, en qué caja vive la definición que el envoltorio apunta:

```ruby
atila.method(:descansar).owner
# => Guerrero
atila.method(:atacar).owner
# => Atacante                            ← atacar viene del mixin
atila.method(:class).owner
# => Kernel                              ← y class viene de Kernel, como descubrimos en la Parte 2
```

`owner` te dice **en qué lugar está definido** el método que te va a responder. Acordate del ejercicio de la Parte 2, el de encontrar qué métodos vienen de un mixin: con `owner` se resuelve de otra manera, más directa. Pedís cada método, le preguntás el dueño, y te fijás si el dueño es un módulo.

**A quién está atado.** La segunda flecha, el objeto sobre el que se va a ejecutar:

```ruby
descansar_de_atila.receiver
# => #<Guerrero:0x... @energia=100, ...>  ← es atila
```

Lo obtuviste a través de `atila`, así que está atado a `atila`. Esto va a importar en un minuto.

**Dónde está escrito.** El archivo y la línea que la consola te mostró al principio salen de `source_location`:

```ruby
descansar_de_atila.source_location
# => [".../age-clase2.rb", 52]           ← archivo y línea donde está el def
```

> 🕳️ **Madriguera — `source_location` es una etiqueta, no un puntero**
> El archivo y la línea son un cartel que Ruby guardó al compilar la definición, para vos. El código ya está adentro de la definición: si borrás `age-clase2.rb` después de cargarlo, `descansar` sigue funcionando igual y `source_location` sigue diciendo lo mismo, apuntando a un archivo que ya no existe.
> *Volvé al camino — esto se profundiza aparte, otro día.*

**Lo que NO le vas a preguntar: su código.** Se puede, pero intencionalmente nos quedamos afuera de eso. Pedir el código es el primer paso hacia parsear y manipular la estructura del programa, que es menos reflection y más metaprogramación pura. Vamos por lo básico.

**Lo que no le podés preguntar: qué devuelve, de qué tipo son sus parámetros.** Eso es lo que llamaríamos la *firma* o el *tipo* del método, y Ruby no lo maneja explícitamente: un método devuelve siempre un objeto, y qué objeto depende de lo que hizo. Ruby no se preocupa por detectarlo. Es tema de la siguiente unidad.

### Y lo que le podés pedir: que se ejecute

Además de preguntarle cosas, hay una cosa que uno quiere hacer con un método: **ejecutarlo**.

```ruby
descansar_de_atila.call
# => 110                                 ← atila descansó: energía 100 → 110

atila.method(:sufri_danio).call(30)      # ← los argumentos van en el call
# => nil                                 ← ojo: sufri_danio no devuelve la energía. Su última línea es
                                         #   "self.lastimado if cansado", un if que no se cumplió, y eso vale nil.
                                         #   El daño se aplicó igual:
atila.method(:energia).call
# => 80                                  ← 110 - 30
```

Ahora prestá atención, porque acá hay una diferencia de fondo con todo lo anterior. **`call` no es un envío de mensaje.** Cuando hacés `atila.descansar` o `atila.send(:descansar)`, Ruby hace el method lookup: paso azul, pasos rojos, encuentra un método, lo ejecuta. Cuando hacés `descansar_de_atila.call`, **no hay lookup**. `call` sigue la flecha del código que el envoltorio ya tiene, y ejecuta esa definición sobre el objeto de la otra flecha. Le estás diciendo "ejecutá *este*", no "buscá el que corresponda a este nombre".

Alguien podría objetar: "para obtener el método con `atila.method(:descansar)` Ruby sí hizo el lookup". Cierto. Pero eso fue en otro momento: el lookup se hizo **al fabricar el envoltorio**, y ahí quedó fijada la flecha. Podés obtener el método hoy, guardarlo, y ejecutarlo mañana. Y mañana, cuando hagas `call`, no se busca nada: se ejecuta lo que la flecha apunta. Nada te garantiza que en ese momento `atila` todavía llegue a ese método por las vías normales —en la Parte 4 vas a ver que las clases se pueden modificar en el medio, y en la sección 6 de esta parte vas a ver qué le pasa al envoltorio cuando eso ocurre.

Y de ahí sale un corolario fuerte: **podés ejecutar un método sobre un objeto que, por las vías normales, nunca llegaría a ese método.** Con eso, por ejemplo, alguien podría implementar una palabra como `super` a mano. Lo vas a ver concreto en un momento.

> **Para el parcial, si te preguntan:** *¿Qué diferencia hay entre `atila.send(:descansar)` y `atila.method(:descansar).call`?*
> `send` es un envío de mensaje: Ruby hace el method lookup para encontrar qué método responde al selector `descansar` en ese momento, y lo ejecuta. `method(:descansar)` obtiene el objeto que representa ese método (el lookup ocurre ahí, una sola vez); `call` lo ejecuta directamente, sin buscar nada. Con `call` se ejecuta *ese* método, aunque el objeto ya no llegara a él por el lookup.

---

## 3. El mismo método, sin objeto: `UnboundMethod` 🔴

Le pedimos el método `descansar` a `atila`. Pero `descansar` está definido en `Guerrero`. ¿Debería poder pedírselo a la clase, sin pasar por ninguna instancia? Sí. Y hay un mensaje para eso, que como `instance_methods` se le manda a la clase:

```ruby
descansar_de_guerrero = Guerrero.instance_method(:descansar)
# => #<UnboundMethod: Guerrero#descansar() .../age-clase2.rb:52>
descansar_de_guerrero.class
# => UnboundMethod
```

Una clase distinta. Cuando se lo pediste a `atila`, era un `Method`. Cuando se lo pedís a `Guerrero`, es un `UnboundMethod`: un método *sin vincular*. ¿Por qué dos clases, si es el mismo método?

Porque **es el mismo método**: la misma definición, la única que hay en la tabla de `Guerrero`. Lo que cambia es el envoltorio, que ahora tiene **una flecha menos**:

```
┌──────────────────────────────────────┐
│ descansar_de_guerrero (UnboundMethod)│
│   código   ──────────────────────────┼──► la DEFINICIÓN de descansar que está en Guerrero
│   receptor ──► (nadie)               │
└──────────────────────────────────────┘
```

Hay dos caminos para llegar a la misma definición, y los dos caminos no traen la misma información. Cuando se lo pedís a `atila`, hay algo que se asume: que si le estás pidiendo el método a `atila`, es para ejecutarlo sobre `atila`. Ya sabés quién es `self`, quién te va a dar los atributos, sobre quién correr. Cuando se lo pedís a `Guerrero`, no sabés nada de eso: hay una sola definición pero puede haber muchos guerreros, o ninguno. **No sabe en qué contexto ejecutarse.**

Y por eso no se puede ejecutar:

```ruby
descansar_de_guerrero.call
# NoMethodError: undefined method `call' for #<UnboundMethod: Guerrero#descansar()...>
```

Todo lo que dependa solo de la flecha del código, sí lo responde. Lo que dependa de la flecha que no tiene, no:

```ruby
descansar_de_guerrero.parameters
# => []
descansar_de_guerrero.owner
# => Guerrero
descansar_de_guerrero.receiver
# NoMethodError                          ← receptor no tiene; para eso no está vinculado
```

### Vincular y desvincular

De ahí emergen dos operaciones necesarias. Tenés que poder agarrar un método suelto y **vincularlo** a una instancia; y tenés que poder agarrar un método vinculado y pedir **la versión suelta**. Las dos hacen lo mismo que todo lo anterior: **fabrican un envoltorio nuevo**, con una flecha más o una flecha menos.

```ruby
descansar_de_guerrero.bind(atila)
# => #<Method: Guerrero#descansar() .../age-clase2.rb:52>      ← un Method NUEVO: misma definición + atila
descansar_de_guerrero.bind(atila).call
# => 90                                                     ← y se puede ejecutar: 80 + 10

descansar_de_atila.unbind
# => #<UnboundMethod: Guerrero#descansar() .../age-clase2.rb:52>  ← un UnboundMethod NUEVO: misma definición, sin nadie
```

Que las dos flechas del código apuntan a la misma definición se puede verificar con lo que aprendiste en la sección 2: `==` compara las flechas.

```ruby
descansar_de_atila.unbind == descansar_de_guerrero
# => true                        ← soltar el de atila da lo mismo que pedírselo a Guerrero: misma definición
```

### `Method` no entiende `bind`

Con `bind` y `unbind` en la mano, lo natural es querer llevar el `descansar` de `atila` a otro guerrero. Probemos:

```ruby
conan = Guerrero.new                     # otro guerrero, energía 100
descansar_de_atila.bind(conan)
# NoMethodError: undefined method `bind' for an instance of Method
```

No es un capricho: `bind` le pone receptor a algo que no lo tiene, y un `Method` **ya tiene** receptor. Para cambiar de receptor, primero soltás y después atás:

```ruby
descansar_de_conan = descansar_de_atila.unbind.bind(conan)
#   unbind → UnboundMethod nuevo (misma definición, sin receptor)
#   bind   → Method nuevo (misma definición, receptor conan)

descansar_de_conan.receiver
# => #<Guerrero:0x... @energia=100, ...>  ← es conan
descansar_de_conan.call
# => 110                                  ← conan descansó: 100 → 110
atila.energia
# => 90                                   ← a atila no le pasó nada: sigue en 90
```

La receta, entonces, es `unbind` → `bind(otro)` → `call`. Y la regla para no chocar: `call` es para lo que ya está atado (`Method`); `bind` es para lo que está suelto (`UnboundMethod`).

### Nada de esto tiene efecto sobre nadie

Después de todo lo anterior, esto es lo que hay en memoria:

```
                       ┌────────────────────────────────────┐
                       │ Guerrero                           │
                       │   :descansar ──► DEFINICIÓN        │  ← sigue siendo UNA sola
                       └──────────────────────▲─────────────┘
                                              │ código
              ┌───────────────────────────────┼───────────────────────────────┐
              │                               │                               │
┌─────────────┴────────────┐    ┌─────────────┴────────────┐    ┌─────────────┴────────────┐
│ descansar_de_atila       │    │ descansar_de_guerrero    │    │ descansar_de_conan       │
│ Method                   │    │ UnboundMethod            │    │ Method                   │
│ receptor ──► atila       │    │ receptor ──► (nadie)     │    │ receptor ──► conan       │
└──────────────────────────┘    └──────────────────────────┘    └──────────────────────────┘
```

Tres envoltorios, una definición. Ninguna de las operaciones que hiciste cambió nada de lo que ya existía: `Guerrero` tiene la misma tabla, `atila` y `conan` entienden exactamente los mismos mensajes que antes, y el envoltorio original sigue atado a quien estaba atado.

```ruby
descansar_de_atila.receiver.equal?(atila)
# => true                                 ← el Method original no se movió: unbind le fabricó un hermano, no lo tocó
Guerrero.instance_method(:descansar) == descansar_de_guerrero
# => true                                 ← Guerrero sigue teniendo la misma definición bajo :descansar
descansar_de_atila.call
# => 100                                  ← y sigue funcionando sobre atila: 90 → 100
```

Lo único que cambia cuando hacés `call` es el **estado** del receptor, porque ejecutaste un código que hace `self.energia += 10`. Eso no es efecto de `bind`; es efecto de descansar.

Con el dibujo delante, un resultado que suele confundir:

```ruby
atila.method(:descansar) == descansar_de_guerrero.bind(atila)
# => true                                 ← iguales: misma definición, mismo receptor
atila.method(:descansar).equal?(descansar_de_guerrero.bind(atila))
# => false                                ← pero son dos objetos: cada camino fabricó su envoltorio
```

Dos caminos para llegar a "descansar sobre atila", dos objetos, mismas dos flechas. Ni el `Method` que te da `atila` es "el método de atila", ni el `UnboundMethod` que te da `Guerrero` es "el método de Guerrero": `atila` no tiene ningún método propio, y lo que `Guerrero` tiene es la definición, que no es ninguno de los dos envoltorios.

### Cómo se relacionan las dos clases

Conceptualmente están emparentadas de la forma que esperarías: un método vinculado es un caso particular de método suelto, que agrega una sola cosa, a quién está vinculado.

> ⚠️ Así se presenta en clase, y así conviene pensarlo. Pero el Ruby real **no** las hace heredar una de otra: `Method.superclass` da `Object`, igual que `UnboundMethod.superclass`. Son dos clases hermanas con interfaces parecidas, y la consecuencia práctica ya la viste: `Method` no hereda `bind`, por eso hay que hacer `unbind` antes. Para el examen, la relación conceptual (vinculado = suelto + receptor) es lo que importa; en la consola, la receta es `unbind` → `bind` → `call`.

> **Para el parcial, si te preguntan:** *¿Qué diferencia hay entre `Method` y `UnboundMethod`?*
> Son dos representaciones del mismo método: objetos que apuntan a la misma definición, la que está en la clase. `Method` se obtiene desde una instancia (`atila.method(:x)`) y además apunta a esa instancia como receptor: sabe sobre quién ejecutarse, por eso entiende `call`. `UnboundMethod` se obtiene desde la clase (`Guerrero.instance_method(:x)`) y no tiene receptor: responde sus parámetros y su dueño, pero no puede ejecutarse ni responde `receiver`. Se pasa de uno a otro con `bind(objeto)` y `unbind`, que devuelven un objeto nuevo cada vez sin modificar la clase, el objeto ni el método original. Conceptualmente, un `Method` es un `UnboundMethod` más el objeto al que está vinculado.

---

## 4. Ejecutar un método donde el lookup no llegaría 🔴

Ahora sí, el corolario de la sección 2, concreto. Dos clases mínimas:

```ruby
class Padre
  def correr
    'correr como padre'
  end
end

class Hijo < Padre
  def correr                              # Hijo redefine correr
    'correr como hijo'
  end
end

h = Hijo.new
h.correr
# => "correr como hijo"                   ← lookup normal: paso azul a Hijo, lo encuentra, listo
```

Por las vías normales, `h` nunca ejecuta el `correr` de `Padre`: el lookup lo encuentra antes en `Hijo`. Pero con un método en la mano no hay lookup:

```ruby
Padre.instance_method(:correr).bind(h).call
# => "correr como padre"                  ← ese método, en ese objeto, sin preguntar nada
```

Agarraste el `correr` de `Padre`, suelto; lo vinculaste a un `Hijo`; lo ejecutaste. Bypaseaste el lookup por completo. Eso es lo que hace `super` por atrás, y es lo que te permite construir mecanismos que el lenguaje no te da.

---

## 5. Hasta dónde se puede vincular 🟡

Con `bind` en la mano, la pregunta que uno espera que se te ocurra: **¿puedo vincular cualquier método a cualquier objeto?** Agarro un método de zanahoria y se lo pongo a un guerrero.

Probemos:

```ruby
class Zanahoria
  def color
    'naranja'
  end
end

Zanahoria.instance_method(:color).bind(atila)
# TypeError: bind argument must be an instance of Zanahoria
```

Ruby no te deja. "Tiene que ser una instancia de Zanahoria" —o de una subclase de Zanahoria: tiene que tener, por lo menos, todo lo que Zanahoria garantiza. Es la misma jerarquía, o nada.

¿Por qué? Acá vale la pena abrir el abanico de los tres niveles de la Parte 1, porque la respuesta es distinta en cada uno.

**En teoría**, ejecutar código en un contexto que no puede soportar lo que ese código necesita es peligroso. Si `color` usara un atributo `@tono` que solo las zanahorias tienen, correrlo sobre un guerrero podría romper cosas. Alguien que diseña un lenguaje con reflection tiene que decidir qué hace con eso.

**En Java**, sería un argumento decisivo: los objetos tienen exactamente los atributos que su clase declara, y un método que espera un atributo que no está no puede ni compilar. Java no te deja, y con razón.

**En Smalltalk o JavaScript**, cero problema: agarrás un método de una clase, lo ponés en otra, lo ejecutás. Son lenguajes preparados para la idea de que lo que buscás en el contexto podría no estar. ¿Y si el método manda un mensaje que el objeto no entiende? Lo mismo que pasa cuando eso ocurre de forma normal. ¿Y si accede a un atributo que no existe? Lo mismo que siempre.

**En Ruby**, la situación es la de Smalltalk: como vimos en la Parte 2, cualquier atributo por el que preguntes está (vale `nil` si nadie lo seteó). Ruby está **perfectamente preparado** para dejarte hacer esto. Y sin embargo no te deja. ¿Por qué? No hay una razón técnica. Es un cinturón de seguridad: uno fácilmente se imagina que la gran mayoría de los métodos sacados de cualquier lado y puestos en cualquier otro no van a funcionar, y Ruby prefiere no dejarte hacer pelotudeces.

**Pero hay una puerta.** Si el método está en un **mixin** en vez de en una clase, sí se puede vincular a cualquier cosa:

```ruby
module Colorido
  def color
    'naranja'
  end
end

Colorido.instance_method(:color).bind(atila).call
# => "naranja"                            ← funcionó: atila no incluye Colorido y no importa
```

Tiene lógica: un mixin ya tiene que estar preparado para proveerle métodos a cualquiera; es su naturaleza. Así que cualquier método que pongas adentro de un mixin lo podés sacar de ahí y ponérselo a cualquier objeto. Y en el peor de los casos, siempre podés redefinir la clase para que su método esté en un mixin y tomarlo del mixin. Ruby cierra una puerta y deja la de al lado abierta.

> ⚠️ Para el examen: en Ruby, `bind` solo acepta un objeto que sea instancia de la clase dueña del método (o de una subclase); si el método pertenece a un módulo, acepta cualquier objeto.

---

## 6. Un envoltorio viejo frente a una definición nueva 🟡

En la sección 2 quedó una frase colgando: podés obtener un método hoy, guardarlo, y ejecutarlo mañana, aunque en el medio la clase haya cambiado. En la Parte 4 vas a ver **cómo** se cambia una clase en marcha: se la reabre con `class Guerrero ... end` y se vuelve a definir el método. Acá no importa la sintaxis; importa **qué flecha se mueve**, y el dibujo de la sección 3 ya te lo dice.

Antes de tocar nada, guardate un envoltorio (`atila` está en 100):

```ruby
viejo = atila.method(:descansar)         # Method: código ──► DEFINICIÓN A (la de siempre, +10)
```

Ahora `Guerrero` vuelve a definir `descansar`. Lo que hace Ruby es compilar una **definición nueva** y hacer que el nombre `:descansar` de la tabla apunte a ella. La definición vieja no se modifica ni se borra: solo pierde el nombre.

```ruby
class Guerrero
  def descansar
    self.energia += 1000                 # definición B: otro código, mismo nombre
  end
end
```

```
ANTES                                        DESPUÉS
┌────────────────────────────┐               ┌────────────────────────────┐
│ Guerrero                   │               │ Guerrero                   │
│  :descansar ──► DEF. A     │               │  :descansar ──► DEF. B     │  ← esta flecha se movió
└────────────────────────────┘               └────────────────────────────┘
                 ▲                                            (DEF. A sigue en memoria,
   viejo ────────┘                              viejo ────────► DEF. A     sin nombre en la tabla)
```

Se movió **una sola flecha**: la de la tabla. La del envoltorio nunca se movió. Y eso se ve directo en la consola:

```ruby
viejo == atila.method(:descansar)
# => false                                ← el envoltorio nuevo apunta a B; viejo sigue apuntando a A

atila.descansar
# => 1100                                 ← envío de mensaje: lookup por nombre → encuentra B → 100 + 1000
viejo.call
# => 1110                                 ← sin lookup: ejecuta A sobre atila → 1100 + 10

Guerrero.instance_methods(false).count(:descansar)
# => 1                                    ← en la tabla hay UN descansar: el nuevo
```

Lo mismo le pasa al envoltorio suelto: `descansar_de_guerrero` apunta a A, y `Guerrero` ya no.

```ruby
descansar_de_guerrero == Guerrero.instance_method(:descansar)
# => false                                ← pedirlo ahora te da un envoltorio que apunta a B
descansar_de_guerrero.bind(conan).call
# => 120                                  ← el suelto viejo sigue ejecutando A: conan 110 → 120
```

Desde la clase, la definición vieja **desapareció**: ningún envío de mensaje la vuelve a encontrar, y por eso la Parte 4 va a decir que pisar un método es destructivo. Eso es cierto para el lookup. Lo único que la mantiene viva es un envoltorio que hayas pedido antes del cambio; si no lo pediste, no hay forma de volver a ella.

> **Para el parcial, si te preguntan:** *Tenés `m = atila.method(:descansar)` y después se redefine `descansar` en `Guerrero`. ¿Qué ejecuta `m.call`?*
> Ejecuta la definición vieja. `method` fija en el objeto `Method` la definición que el lookup encontró en ese momento; redefinir el método cambia a qué definición apunta el nombre en la clase, pero no modifica ni el objeto `Method` ni la definición que apunta. `atila.descansar` hace lookup y encuentra la nueva; `m.call` no hace lookup y ejecuta la que tenía.

---

## 7. Caja de herramientas de la Parte 3 🔴

Todo lo que esta parte introdujo, en una tabla para tener al lado mientras leés o mientras probás en la consola. La última columna es una línea lista para tipear en Pry con `age-clase2.rb` cargado y `atila = Guerrero.new` hecho.

| Quiero... | Se lo mando a... | Mensaje | Responde | Probalo |
|---|---|---|---|---|
| el método como objeto, atado a una instancia | el objeto | `method(:selector)` | un `Method` nuevo (definición + receptor) | `atila.method(:descansar)` |
| el método suelto, sin objeto | la clase o el módulo | `instance_method(:selector)` | un `UnboundMethod` nuevo (solo definición) | `Guerrero.instance_method(:descansar)` |
| qué parámetros recibe y de qué tipo | el `Method` o `UnboundMethod` | `parameters` | lista de `[:req/:opt/:rest, nombre]` | `atila.method(:sufri_danio).parameters` |
| cuántos parámetros recibe | el `Method` o `UnboundMethod` | `arity` | un número (negativo si hay opcionales) | `atila.method(:initialize).arity` |
| en qué clase o módulo está definido | el `Method` o `UnboundMethod` | `owner` | la clase o el módulo dueño | `atila.method(:atacar).owner` |
| a qué objeto está atado | el `Method` | `receiver` | el objeto | `atila.method(:descansar).receiver` |
| en qué archivo y línea está escrito | el `Method` o `UnboundMethod` | `source_location` | `[archivo, línea]` (una etiqueta) | `atila.method(:descansar).source_location` |
| ejecutarlo **sin method lookup** | el `Method` | `call(args)` | lo que devuelva el método | `atila.method(:sufri_danio).call(30)` |
| atar un método suelto a un objeto | el `UnboundMethod` | `bind(objeto)` | un `Method` nuevo (no cambia nada) | `Guerrero.instance_method(:descansar).bind(atila)` |
| soltar un método atado | el `Method` | `unbind` | un `UnboundMethod` nuevo (no cambia nada) | `atila.method(:descansar).unbind` |
| ejecutar el método de un objeto sobre otro | el `Method` | `unbind.bind(otro).call` | lo que devuelva; `bind` directo sobre un `Method` da `NoMethodError` | `atila.method(:descansar).unbind.bind(conan).call` |
| saber si dos envoltorios apuntan a lo mismo | el `Method` o `UnboundMethod` | `==` | `true` si misma definición (y mismo receptor) | `atila.method(:descansar) == Guerrero.instance_method(:descansar).bind(atila)` |
| saber si dos envoltorios son el mismo objeto | el `Method` o `UnboundMethod` | `equal?` | casi siempre `false`: cada pedido fabrica uno | `atila.method(:descansar).equal?(atila.method(:descansar))` |
| ejecutar un método donde el lookup no llegaría | el `UnboundMethod` | `bind(objeto).call` | lo que devuelva | `Padre.instance_method(:correr).bind(h).call` |
| poner un método en cualquier objeto, sin restricción de jerarquía | un `UnboundMethod` **de un módulo** | `bind(cualquiera).call` | funciona aunque el objeto no incluya el módulo | `Colorido.instance_method(:color).bind(atila).call` |

Y las cosas que no son mensajes pero hay que tener a mano:

- **Method lookup:** un paso azul (`class`, mirando también los mixins de esa clase en su linearización) + n pasos rojos (`superclass`). Termina cuando no hay más flecha roja.
- **Regla 1:** todo lo que recibe mensajes tiene una flecha azul. **Regla 2:** todo proveedor de comportamiento tiene una flecha roja.
- **El código vive una sola vez**, en la definición guardada en la clase bajo un nombre. `Method` y `UnboundMethod` son envoltorios fabricados a pedido que la apuntan; el `Method` además apunta a un receptor. Ningún envoltorio copia código ni modifica a nadie.
- **Redefinir un método mueve la flecha de la tabla** hacia una definición nueva; los envoltorios que ya pediste siguen apuntando a la vieja.
- **`bind` solo acepta** instancias de la clase dueña del método o de sus subclases; si el dueño es un módulo, acepta cualquier objeto.

---

## Qué sigue

Hasta acá, todo lo que hicimos es **consultar** (y ejecutar, que no cambia la estructura del programa). Sabés cómo Ruby busca un método, sabés obtener un método como objeto, sabés qué tiene adentro ese objeto, sabés interrogarlo y sabés ejecutarlo donde quieras. Lo que no hicimos todavía es **modificar** el programa: agregarle métodos a una clase que ya existe, pisarlos, construirlos con nombres que no conocés de antemano. La sección 6 te mostró el efecto de una de esas modificaciones desde el lado del envoltorio; la Parte 4 te muestra cómo se hacen todas, y es donde Ruby se separa de casi todos los demás.

---

### Antes de seguir, cinco preguntas para vos

1. El method lookup es "un paso azul, n pasos rojos". ¿Dónde quedan los mixins en esa fórmula, y por qué no se los dibuja como cajas separadas en el diagrama?
2. Obtenés `m = atila.method(:descansar)`, y después alguien modifica `Guerrero` de forma que `atila` ya no entiende `descansar`. ¿`m.call` funciona? ¿Por qué?
3. ¿Por qué un `UnboundMethod` puede responder `parameters` y `owner` pero no `call` ni `receiver`?
4. `atila.method(:descansar) == Guerrero.instance_method(:descansar).bind(atila)` da `true`, y con `equal?` da `false`. ¿Qué compara cada uno, y qué te dice eso sobre lo que devuelven `method` e `instance_method`?
5. Tenés `d = atila.method(:descansar)` y querés ejecutar ese método sobre `conan`. ¿Qué mensajes mandás, en qué orden, y cuántos objetos nuevos aparecen en el camino? ¿Alguno de ellos cambió a `atila`, a `conan` o a `Guerrero`?

*(Las respuestas no están acá. Si alguna no te sale, es la señal de qué releer.)*
