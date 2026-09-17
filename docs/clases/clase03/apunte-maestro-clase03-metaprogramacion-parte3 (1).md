# 📘 Apunte Maestro — Clase 03: Metaprogramación en Ruby

## Parte 3 — El method lookup y los métodos como objetos

**Materia:** Técnicas Avanzadas de Programación (TAdP) · **Unidad:** clase03 · **Clase del:** 29/08/2026

> **Serie completa:** Parte 0 (entorno) · Parte 1 (qué es metaprogramar) · Parte 2 (introspection) · **Parte 3 (method lookup y métodos como objetos)** · Parte 4 (self-modification) · Parte 5 (el metamodelo) · Parte 6 (autoclases y cierre).
> Esta parte arranca con una sesión nueva de la consola: `age-clase2.rb` cargado y `atila = Guerrero.new` recién creado (energía 100).

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

**Quién lo definió.** El dueño del método:

```ruby
atila.method(:descansar).owner
# => Guerrero
atila.method(:atacar).owner
# => Atacante                            ← atacar viene del mixin
atila.method(:class).owner
# => Kernel                              ← y class viene de Kernel, como descubrimos en la Parte 2
```

`owner` te dice **en qué lugar está definido** el método que te va a responder. Acordate del ejercicio de la Parte 2, el de encontrar qué métodos vienen de un mixin: con `owner` se resuelve de otra manera, más directa. Pedís cada método, le preguntás el dueño, y te fijás si el dueño es un módulo.

**A quién está atado.** El objeto sobre el que se va a ejecutar:

```ruby
descansar_de_atila.receiver
# => #<Guerrero:0x... @energia=100, ...>  ← es atila
```

Lo obtuviste a través de `atila`, así que está atado a `atila`. Esto va a importar en un minuto.

**Lo que NO le vas a preguntar: su código.** Se puede, pero intencionalmente nos quedamos afuera de eso. Pedir el código es el primer paso hacia parsear y manipular la estructura del programa, que es menos reflection y más metaprogramación pura. Vamos por lo básico.

**Lo que no le podés preguntar: qué devuelve, de qué tipo son sus parámetros.** Eso es lo que llamaríamos la *firma* o el *tipo* del método, y Ruby no lo maneja explícitamente: un método devuelve siempre un objeto, y qué objeto depende de lo que hizo. Ruby no se preocupa por detectarlo. Es tema de la siguiente unidad.

### Y lo que le podés pedir: que se ejecute

Además de preguntarle cosas, hay una cosa que uno quiere hacer con un método: **ejecutarlo**.

```ruby
descansar_de_atila.call
# => 110                                 ← atila descansó: energía 100 → 110

atila.method(:sufri_danio).call(30)      ← los argumentos van en el call
# => nil                                 ← ojo: sufri_danio no devuelve la energía. Su última línea es
                                         #   "self.lastimado if cansado", un if que no se cumplió, y eso vale nil.
                                         #   El daño se aplicó igual:
atila.method(:energia).call
# => 80                                  ← 110 - 30
```

Ahora prestá atención, porque acá hay una diferencia de fondo con todo lo anterior. **`call` no es un envío de mensaje.** Cuando hacés `atila.descansar` o `atila.send(:descansar)`, Ruby hace el method lookup: paso azul, pasos rojos, encuentra un método, lo ejecuta. Cuando hacés `descansar_de_atila.call`, **no hay lookup**. Vos ya tenés el método en la mano. Le estás diciendo "ejecutá *este*", no "buscá el que corresponda a este nombre".

Alguien podría objetar: "para obtener el método con `atila.method(:descansar)` Ruby sí hizo el lookup". Cierto. Pero eso fue en otro momento. Podés obtener el método hoy, guardarlo, y ejecutarlo mañana. Y mañana, cuando hagas `call`, no se busca nada: se ejecuta lo que tenés. Nada te garantiza que en ese momento `atila` todavía llegue a ese método por las vías normales —en la Parte 4 vas a ver que las clases se pueden modificar en el medio.

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

Porque **es el mismo método**. Hay un único `descansar`, está en `Guerrero`, y hay dos caminos para llegar a él. Pero los dos caminos no traen la misma información. Cuando se lo pedís a `atila`, hay algo que se asume: que si le estás pidiendo el método a `atila`, es para ejecutarlo sobre `atila`. Ya sabés quién es `self`, quién te va a dar los atributos, sobre quién correr. Cuando se lo pedís a `Guerrero`, no sabés nada de eso: hay un solo método pero puede haber muchos guerreros, o ninguno. **No sabe en qué contexto ejecutarse.**

Y por eso no se puede ejecutar:

```ruby
descansar_de_guerrero.call
# NoMethodError: undefined method `call' for #<UnboundMethod: Guerrero#descansar()...>
```

"¿Cómo, si es el mismo método?" Es el mismo método **visto a través de dos lentes diferentes**. Dos representaciones distintas de una misma cosa: una que ya tiene un objeto sobre el cual llamarse, y otra que no puede invocarse porque no sabe sobre quién. Fijate que las preguntas que no dependen de un objeto, las responde igual:

```ruby
descansar_de_guerrero.parameters
# => []
descansar_de_guerrero.owner
# => Guerrero
descansar_de_guerrero.receiver
# NoMethodError                          ← receptor no tiene; para eso no está vinculado
```

Es perfectamente razonable tener el método antes de que exista ningún guerrero. Es perfectamente razonable querer ejecutarlo sobre uno que todavía no nació. Un `UnboundMethod` es eso: el método, sueltito.

### Vincular y desvincular

De ahí emergen dos operaciones necesarias. Tenés que poder agarrar un método suelto y **vincularlo** a una instancia; y tenés que poder agarrar un método vinculado y pedir **la versión suelta**.

```ruby
descansar_de_guerrero.bind(atila)
# => #<Method: Guerrero#descansar() .../age-clase2.rb:52>      ← ahora es un Method, atado a atila
descansar_de_guerrero.bind(atila).call
# => 90                                                     ← y se puede ejecutar

descansar_de_atila.unbind
# => #<UnboundMethod: Guerrero#descansar() .../age-clase2.rb:52>  ← la versión suelta
```

Una cosa importante sobre las dos: **no tienen efecto.** No cambian nada. Vincular el método suelto a `atila` no hace que el método de `Guerrero` ahora sea de `atila` y los demás guerreros lo pierdan. Desvincular el método de `atila` no lo rompe ni lo saca de `atila`:

```ruby
descansar_de_atila.unbind        # devuelve la versión suelta...
descansar_de_atila.call
# => 100                         ← ...y el vinculado sigue estando ahí, intacto
```

`Method` y `UnboundMethod` **representan** el método; no **son** el método. Son lentes. `bind` te da un lente nuevo con un objeto puesto; `unbind` te da un lente nuevo sin objeto. El método real, en `Guerrero`, ni se entera.

Y conceptualmente están emparentadas de la forma que esperarías: un método vinculado es un caso particular de método suelto, que agrega una sola cosa, a quién está vinculado.

> ⚠️ Así se presenta en clase, y así conviene pensarlo. Pero si lo probás en la consola, el Ruby real **no** las hace heredar una de otra: `Method.superclass` da `Object`, igual que `UnboundMethod.superclass`. Son dos clases hermanas con interfaces parecidas. Para el examen, la relación conceptual (vinculado = suelto + receptor) es lo que importa; no te sorprendas si la consola te dice otra cosa.

> **Para el parcial, si te preguntan:** *¿Qué diferencia hay entre `Method` y `UnboundMethod`?*
> Son dos representaciones del mismo método. `Method` se obtiene desde una instancia (`atila.method(:x)`) y está vinculado a ella: sabe sobre quién ejecutarse, por eso entiende `call`. `UnboundMethod` se obtiene desde la clase (`Guerrero.instance_method(:x)`) y no está vinculado a ningún objeto: puede responder sus parámetros y su dueño, pero no puede ejecutarse. Se pasa de uno a otro con `bind(objeto)` y `unbind`, que devuelven una representación nueva sin modificar el método real. Conceptualmente, un `Method` es un `UnboundMethod` más el objeto al que está vinculado.

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

## 6. Caja de herramientas de la Parte 3 🔴

Todo lo que esta parte introdujo, en una tabla para tener al lado mientras leés o mientras probás en la consola. La última columna es una línea lista para tipear en Pry con `age-clase2.rb` cargado y `atila = Guerrero.new` hecho.

| Quiero... | Se lo mando a... | Mensaje | Responde | Probalo |
|---|---|---|---|---|
| el método como objeto, atado a una instancia | el objeto | `method(:selector)` | un `Method` (vinculado) | `atila.method(:descansar)` |
| el método suelto, sin objeto | la clase o el módulo | `instance_method(:selector)` | un `UnboundMethod` | `Guerrero.instance_method(:descansar)` |
| qué parámetros recibe y de qué tipo | el `Method` o `UnboundMethod` | `parameters` | lista de `[:req/:opt/:rest, nombre]` | `atila.method(:sufri_danio).parameters` |
| cuántos parámetros recibe | el `Method` o `UnboundMethod` | `arity` | un número (negativo si hay opcionales) | `atila.method(:initialize).arity` |
| en qué clase o módulo está definido | el `Method` o `UnboundMethod` | `owner` | la clase o el módulo dueño | `atila.method(:atacar).owner` |
| a qué objeto está atado | el `Method` | `receiver` | el objeto | `atila.method(:descansar).receiver` |
| ejecutarlo **sin method lookup** | el `Method` | `call(args)` | lo que devuelva el método | `atila.method(:sufri_danio).call(30)` |
| atar un método suelto a un objeto | el `UnboundMethod` | `bind(objeto)` | un `Method` nuevo (no cambia nada) | `Guerrero.instance_method(:descansar).bind(atila)` |
| soltar un método atado | el `Method` | `unbind` | un `UnboundMethod` nuevo (no cambia nada) | `atila.method(:descansar).unbind` |
| ejecutar un método donde el lookup no llegaría | el `UnboundMethod` | `bind(objeto).call` | lo que devuelva | `Padre.instance_method(:correr).bind(h).call` |
| poner un método en cualquier objeto, sin restricción de jerarquía | un `UnboundMethod` **de un módulo** | `bind(cualquiera).call` | funciona aunque el objeto no incluya el módulo | `Colorido.instance_method(:color).bind(atila).call` |

Y las tres cosas que no son mensajes pero hay que tener a mano:

- **Method lookup:** un paso azul (`class`, mirando también los mixins de esa clase en su linearización) + n pasos rojos (`superclass`). Termina cuando no hay más flecha roja.
- **Regla 1:** todo lo que recibe mensajes tiene una flecha azul. **Regla 2:** todo proveedor de comportamiento tiene una flecha roja.
- **`bind` solo acepta** instancias de la clase dueña del método o de sus subclases; si el dueño es un módulo, acepta cualquier objeto.

---


## Qué sigue

Hasta acá, todo lo que hicimos es **consultar** (y ejecutar, que no cambia la estructura del programa). Sabés cómo Ruby busca un método, sabés obtener un método como objeto, sabés interrogarlo y sabés ejecutarlo donde quieras. Lo que no hicimos todavía es **modificar** el programa: agregarle métodos a una clase que ya existe, pisarlos, construirlos con nombres que no conocés de antemano. Eso es la Parte 4, y es donde Ruby se separa de casi todos los demás.

---

### Antes de seguir, tres preguntas para vos

1. El method lookup es "un paso azul, n pasos rojos". ¿Dónde quedan los mixins en esa fórmula, y por qué no se los dibuja como cajas separadas en el diagrama?
2. Obtenés `m = atila.method(:descansar)`, y después alguien modifica `Guerrero` de forma que `atila` ya no entiende `descansar`. ¿`m.call` funciona? ¿Por qué?
3. ¿Por qué un `UnboundMethod` puede responder `parameters` y `owner` pero no `call`?

*(Las respuestas no están acá. Si alguna no te sale, es la señal de qué releer.)*
