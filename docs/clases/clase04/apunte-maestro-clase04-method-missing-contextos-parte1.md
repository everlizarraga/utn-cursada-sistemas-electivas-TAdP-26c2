# Apunte maestro — clase04 — `method_missing`, bloques, contextos e `instance_eval`
## Parte 1 — Cuando el lookup falla: `method_missing`

> **Qué cubre esta parte.** Qué pasa cuando le mandás a un objeto un mensaje que no entiende: qué podría hacer un lenguaje con eso, qué hace Ruby, y la herramienta que Ruby te da para cambiarlo, `method_missing`. Cierra con el contrato que viene pegado a esa herramienta: `super` y `respond_to_missing?`.
>
> **Cómo sigue la unidad.** Parte 2: el registrador de mensajes, `BasicObject` y cuándo no usar `method_missing`. Parte 3: bloques, procs y lambdas. Parte 4: contextos, qué los corta y qué no, e `instance_eval`. Parte 5: construir una sintaxis propia con todo eso, información operativa y cierre.
>
> **De dónde venís.** De las clases 1 a 3 se asume: el method lookup con autoclase (`#atila → Guerrero → … → BasicObject`), los mixins linearizados dentro de esa cadena, `Kernel` como el mixin de `Object`, `send`, `methods`, `method(:x)` y `define_method`.
>
> **Código.** Ruby 3.3 con el `age.rb` de la materia (`Guerrero`, `Atacante`, `Defensor`, `Espadachin`, `Misil`, `Muralla`). Todos los resultados están como comentario al lado de la línea: no hace falta ejecutar para leer. Los mensajes de error cambian un poco entre versiones (en 3.2 dicen `for #<Guerrero:0x…>` en vez de `for an instance of Guerrero`); lo que importa es el tipo de error.

---

## 1. El camino infeliz del lookup 🟡

Un guerrero recibe dos mensajes. Uno lo entiende, el otro no:

```ruby
require_relative 'age'           # carga Atacante, Defensor, Guerrero, Espadachin, Misil, Muralla

atila = Guerrero.new             # sin argumentos: potencial ofensivo 20, energía 100, potencial defensivo 10
p Guerrero.ancestors             # => [Guerrero, Defensor, Atacante, Object, Kernel, BasicObject]
                                 #    la cadena completa que recorre el lookup, mixins incluidos
                                 #    (p muestra el valor "como programador": con corchetes, comillas, nil visible; puts lo muestra como texto)

atila.descansar                  # lookup: #atila (vacía) → Guerrero ✓ está: se ejecuta
atila.comerse_un_sanguche        # lookup: #atila → Guerrero → Defensor → Atacante → Object → Kernel → BasicObject → ✗
# => NoMethodError: undefined method `comerse_un_sanguche' for an instance of Guerrero
```

El camino de `comerse_un_sanguche`, dibujado (dejo afuera los mixins para no ensuciar: están, y el lookup los recorre, pero no cambian nada de lo que sigue):

```
atila.comerse_un_sanguche

  #atila ──► Guerrero ──► Object ──► BasicObject ──► *
    no          no          no          no           ↑
                                              se acabó el camino
```

Ese `*` no es una clase ni define comportamiento. Es el punto donde el algoritmo del lookup tiene cableado un corte: "si llegaste acá, no hay ningún otro lugar donde buscar". La superclase de `BasicObject` es `nil` justamente para eso: para que el recorrido termine.

**Qué significa haber llegado ahí.** No es un problema que el programa pueda resolver en tiempo de ejecución. No es "me quedé sin lugar en el array y hay que redimensionarlo". Es que alguien escribió en el código fuente un envío de mensaje que **no puede funcionar**: el objeto no lo entiende, y ningún mecanismo del sistema lo va a hacer entender. La única forma de arreglarlo es que una persona cambie el código. Desde el punto de vista de la máquina virtual, es un error conceptual del programa. *(Cuando veamos tipado estático, más adelante en la materia, esta situación se va a categorizar con más precisión; por ahora alcanza con esto.)*

> **Máquina virtual (VM):** el programa que ejecuta tu programa. En Ruby, el intérprete; en Java, la JVM. Cuando decimos "la VM tiene que hacer algo", hablamos del intérprete que está corriendo tu código.

Pero la VM es un programa, y un programa no puede "salirse del personaje" y quedarse mirando. Tiene que hacer **algo**, determinístico. Así como el lookup tiene un algoritmo para el camino feliz, necesita uno para el infeliz. Y ahí hay más de una opción.

---

## 2. Qué puede hacer el lenguaje cuando llega al `*` 🟡

Antes de ver lo que hace Ruby, vale la pena enumerar lo que *podría* hacer cualquier lenguaje. Recordá que el programa ya está mal: no estamos buscando una manera de que funcione, estamos eligiendo cómo fallar.

| Opción | Qué hace la VM | Qué oportunidad te da |
|---|---|---|
| **Lanzar una excepción** | Interrumpe la ejecución y sube por la pila de llamadas (los métodos que están ejecutándose, uno adentro del otro) hasta que alguien la ataje | Una última chance de hacer algo con el fallo |
| **Panic** | Mata el proceso, sin más | Ninguna |
| **No hacer nada** | Sigue con la siguiente sentencia como si el mensaje se hubiera ejecutado | Ninguna, y encima no te enterás |
| **Código de error** | El envío "retorna" un valor universal de error | Chequearlo a mano después de cada paso |
| **Reintentar** | Vuelve a hacer el lookup | Ninguna: nada cambió entre un intento y otro |
| **Loop infinito** | En vez de cortar en el `*`, la flecha vuelve al principio | Ninguna, y no sabés si se colgó o está trabajando |

> **Panic:** terminar el proceso de golpe, sin darle al programa ninguna posibilidad de intervenir. Algunas máquinas virtuales lo hacen cuando detectan algo que no pueden manejar.

Algunas observaciones que salen de la tabla:

- **Reintentar no sirve** porque un envío de mensaje es, en el escenario más optimista, atómico: nada pudo haber cambiado en el medio. (Sacando hilos y paralelismo, que son otra discusión.)
- **No hacer nada es de lo más peligroso.** Permite que el resto del programa siga ejecutando después de que una sentencia no se ejecutó. Es importantísimo que cada sentencia de un programa se ejecute; no podés saltear una y seguir como si nada.
- **Los códigos de error** existieron mucho tiempo (un registro que se seteaba cuando algo fallaba, y alguien tenía que ir a leerlo). El problema: si nadie lo lee, "pagar los sueldos" termina con la mitad sin pagar y un mensajito guardado que dice "algo salió mal".
- **El loop infinito y el panic**, a efectos del guerrero, dan lo mismo que la excepción: el mensaje no se ejecutó. La diferencia está del lado del usuario: con un loop no sabés si el sistema se rompió o está procesando algo largo; con un panic no tenés ninguna oportunidad de intervenir.

**Entonces, ¿qué diferencia hay entre lanzar una excepción y matar la VM directamente?** Si nadie ataja la excepción, sube hasta arriba de todo y la VM hace lo único que le queda: panic. Termina igual. La diferencia es que **la podés atajar**. No para hacer que `atila.comerse_un_sanguche` funcione (eso no va a pasar), sino para resolver *el nuevo problema*: que se está por morir el servidor porque alguien mandó un mensaje mal. En vez de matar todo, mostrás un cartel, avisás, y el resto sigue corriendo. Fallaste, pero con más gracia.

Un ejemplo que usás todos los días: la consola de Ruby. Le mandás un mensaje que no entiende, te muestra el error… y sigue viva, podés seguir escribiendo. Alguien, en la capa más externa de ese programa, atajó la excepción, la imprimió y siguió. La capa más cercana al usuario de casi cualquier programa tiene un gran "atajá todo" que convierte cualquier excepción en un aviso en vez de una muerte.

**Las mecánicas son mejores o peores según cuánta oportunidad te den de hacer algo al respecto.** Con ese criterio, la excepción es más generosa que las otras cinco.

### Atajar la excepción: `rescue`

Una lista de guerreros con un intruso. A todos se les manda `descansar`:

```ruby
require_relative 'age'

[Guerrero.new(10, 10, 10),
 Guerrero.new(10, 10, 10),
 "atila",                              # un String en el medio: no entiende descansar
 Guerrero.new(10, 10, 10)].each do |guerrero|
  guerrero.descansar
  puts "se mandó descansar"
end
# Resultado esperado:
# se mandó descansar
# se mandó descansar
# NoMethodError: undefined method `descansar' for an instance of String   ← el tercero explota
#                                                                           y el cuarto nunca recibe descansar
```

`NoMethodError` es la excepción que Ruby lanza para este caso particular. Como es una excepción, la puedo atajar. `begin … rescue … end` es la forma de hacer *try/catch* en Ruby: intento hacer esto; si pasa esta excepción, hago esto otro.

```ruby
[Guerrero.new(10, 10, 10),
 Guerrero.new(10, 10, 10),
 "atila",
 Guerrero.new(10, 10, 10)].each do |guerrero|
  begin                                   # intento…
    guerrero.descansar
    puts "se mandó descansar"
  rescue NoMethodError                    # …y si se levanta un NoMethodError, en vez de explotar:
    puts "no se entendió el mensaje"      # me como la excepción y sigo
  end
end
# Resultado esperado:
# se mandó descansar
# se mandó descansar
# no se entendió el mensaje               ← el String falló, pero el programa no se frenó
# se mandó descansar                      ← el cuarto guerrero sí recibió su mensaje
```

El programa corrió hasta el final. Eso es lo que compra la excepción: control sobre el fallo.

⚠️ **Atajar `NoMethodError` es mala práctica en el 99% de los casos.** Es un error del programa (sección 1): al taparlo, no lo arreglás, lo escondés, y va a aparecer más lejos y más raro. Lo que sí es buena práctica es *fail-fast*: fallar temprano y cerca de la causa. Acá lo atajamos para ver que se puede, no como receta.

> **Fail-fast:** principio de diseño que prefiere que un error explote lo antes posible y lo más cerca posible de donde se originó, en vez de propagarse en silencio.

> 🕳️ **Madriguera — cómo lo manejan otras tecnologías**
> Smalltalk implementa el lookup en el propio lenguaje y, al fallar, manda un mensaje al objeto (`doesNotUnderstand`); su entorno deja frenar en el error, corregir el código y continuar desde ahí. La JVM hace *panic* ante bytecode inválido. Bash sigue ejecutando tras una línea fallida salvo que lo configures. Haskell, ante una división por cero, no tiene manejo de excepciones: corta.
> *Volvé al camino — esto se profundiza aparte, otro día.*

Ruby es más generoso que todo lo anterior: además de la excepción, tiene una opción más, pensada específicamente para este punto del lookup. Es de lo que se trata esta parte.

---

## 3. Una segunda oportunidad: a quién avisarle 🔴

Imaginate que estás armando Ruby, y querés que cuando el lookup llegue al `*` el programa tenga una segunda chance: "no se entendió este mensaje, pero si tenías programado cómo seguir, seguí".

**¿Qué información tenés en ese momento?** Para hacer el lookup tuviste que partir de algo. Sabés exactamente tres cosas:

1. **El receptor:** `atila`. Le tuviste que pedir su autoclase para arrancar el camino.
2. **El nombre del mensaje:** `comerse_un_sanguche`. Es lo que fuiste buscando en cada clase.
3. **Los parámetros:** ninguno, en este caso. Los tenías a mano por si encontrabas el método.

Es decir, tenés **todo lo que hubiera hecho falta para ejecutar el mensaje, menos el método.**

**¿A quién le avisás?** Estamos en un lenguaje de objetos: si queremos que alguien decida algo, le mandamos un mensaje. Los candidatos:

- **La clase `Object`.** Todo el mundo hereda de ahí, así que "todos" podrían participar. Pero si quisieras cambiar qué se hace, lo cambiarías para todo el programa a la vez.
- **Un objeto bien conocido** que resuelva estos casos, como `nil` representa "la nada" o como tener un objeto calculadora que resuelve las cuentas en lugar de los números. Mismo problema: un único plan B para todos.
- **El receptor.** Fijate en los tres datos de arriba: hay un objeto particularmente interesado en que esto se maneje, y es el que iba a recibir el mensaje. Si le avisás a él, **cada objeto (o cada jerarquía) puede tener su propio plan B**: los guerreros manejan de una forma lo que no entienden, las murallas de otra.

Ruby elige la tercera. Cuando el lookup llega al `*`, Ruby le manda **al mismo receptor** un segundo mensaje con los tres datos:

```
receptor.method_missing(mensaje, parámetros)

atila.method_missing(:comerse_un_sanguche)        # el nombre viaja como símbolo; parámetros, ninguno
```

Ese segundo mensaje tiene que poder llegarle a **cualquier** objeto, o el mecanismo no sirve. ¿Cómo se garantiza eso? Igual que con cualquier otro mensaje que todos entienden: definiéndolo arriba de todo. Comprobalo:

```ruby
require_relative 'age'

atila = Guerrero.new
puts atila.method(:method_missing).owner    # => BasicObject   ← el method_missing que atila usa hoy está en BasicObject
```

Y ese `method_missing` de `BasicObject` hace lo que vimos en la sección 1: lanza `NoMethodError`. **La excepción no la lanza el lookup: la lanza un método común y corriente**, que se encontró con un lookup común y corriente.

```
atila.comerse_un_sanguche
   │
   ▼  lookup 1: ¿quién tiene comerse_un_sanguche?
 #atila → Guerrero → Object → BasicObject → *          ✗ nadie
   │
   ▼  al llegar al *, Ruby manda un SEGUNDO mensaje al mismo receptor:
atila.method_missing(:comerse_un_sanguche)
   │
   ▼  lookup 2: ¿quién tiene method_missing?
 #atila → Guerrero → Object → BasicObject               ✓ el de BasicObject → lanza NoMethodError
```

Tres cosas para quedarse con esto:

- **Cada vez que falla un lookup, corriste dos lookups.** El primero busca tu método; el segundo busca `method_missing`. Es más caro que un envío normal.
- **El segundo lookup siempre tiene éxito**, porque `method_missing` viene con Ruby, en `BasicObject`. Si de alguna manera lo sacaras de ahí, el `*` mandaría `method_missing`, que no se encontraría, y mandaría `method_missing`… el loop infinito de la sección 2. Por eso el corte está cableado ahí.
- **No es distinto de las opciones de la sección 2**: es una excepción. La diferencia es que antes de lanzarla, Ruby te deja intervenir con un mensaje. Es un *hook*.

> **Hook (gancho):** un punto del mecanismo del lenguaje donde vos podés enganchar código propio para cambiar lo que pasa por defecto.

Ruby ya viene cableado así. Lo único que vamos a hacer nosotros es cambiar cómo está cableado.

> 🎓 **Para el parcial, si te preguntan:** *¿Qué pasa cuando un objeto recibe un mensaje que no entiende?*
> El method lookup recorre toda la jerarquía (autoclase, clase, mixins, superclases hasta `BasicObject`) y no encuentra el método. Entonces Ruby le manda **al mismo receptor** el mensaje `method_missing`, con el nombre del mensaje original como símbolo y sus parámetros. Ese segundo mensaje hace el lookup normal; la implementación por defecto está en `BasicObject` y lanza `NoMethodError`. Se le avisa al receptor y no a un objeto global para que cada objeto pueda decidir su propio plan B.

---

## 4. Cambiar el plan B: redefinir `method_missing` 🔴

Como `method_missing` se encuentra por lookup, si lo definís en cualquier lugar de la cadena **más abajo** que `BasicObject`, el lookup encuentra el tuyo primero y el de `BasicObject` no se ejecuta nunca. La versión más chica posible:

```ruby
require_relative 'age'

class Guerrero
  private def method_missing(name, *args)          # name: el mensaje que no se entendió, como símbolo
    puts "Me mataste, no entiendo #{name}"         # args: sus parámetros, en un array
  end
end

atila = Guerrero.new(10, 10, 10)                   # potencial ofensivo 10, energía 10, potencial defensivo 10
puts atila.energia                                 # => 10
atila.comerse_un_sanguche                          # => Me mataste, no entiendo comerse_un_sanguche
puts atila.energia                                 # => 10          ← no explotó: el programa siguió
puts atila.method(:method_missing).owner           # => Guerrero    ← ahora el lookup encuentra este primero
```

Tres cosas de sintaxis que aparecen acá y no habíamos usado:

- **`*args`** (se pronuncia *splat*): el asterisco junta en un array llamado `args` todos los argumentos que vengan, sean cuantos sean. `method_missing` no sabe de antemano cuántos parámetros trae el mensaje que no se entendió, así que los recibe todos en una lista. Si no vino ninguno, `args` es `[]`.
- **`private def`**: define el método y lo marca privado en la misma línea. Se lo marca privado porque `method_missing` es un mecanismo interno del objeto, no parte de su interfaz: nadie de afuera debería mandarlo a propósito. Ruby lo invoca igual aunque sea privado.
- **`#{name}`**: interpolación, mete el valor de `name` adentro del string. Solo funciona con comillas dobles.

Volvamos a recorrer el lookup con esta definición puesta, porque es el momento de fijar la mecánica:

**¿CÓMO FUNCIONA?** `atila.comerse_un_sanguche`:

1. Lookup 1: `#atila` → `Guerrero` → `Defensor` → `Atacante` → `Object` → `Kernel` → `BasicObject` → `*`. No está.
2. Ruby manda `atila.method_missing(:comerse_un_sanguche)` con `args = []`.
3. Lookup 2: `#atila` → `Guerrero` ✓. Está el nuestro. Se ejecuta: imprime "Me mataste…".
4. `method_missing` devuelve lo que devolvió `puts` (`nil`), y ese `nil` es lo que "devuelve" `atila.comerse_un_sanguche`.
5. El programa sigue en la línea siguiente. El de `BasicObject` nunca corrió.

Con esto, `atila` responde `comerse_un_sanguche`. Y también `sarasa`, `volar`, `resolver_un_cubo_rubik`: **cualquier** mensaje que no tenga método cae acá. Ahora la pregunta incómoda.

---

## 5. ¿Entendió el mensaje? `methods` vs `respond_to?` 🔴

Le mandaste `comerse_un_sanguche` a `atila` y te respondió. **¿Entendió el mensaje?**

Depende de qué signifique "entender":

- Si entender es *tener un método asociado en la jerarquía*, no lo entendió.
- Si entender es *le mandé el mensaje y me respondió algo*, lo entendió.

Y las dos definiciones se pueden dar vuelta: si un objeto **tiene** un método `comerse_un_sanguche` cuyo cuerpo lanza `NoMethodError`, a efectos prácticos es como no haberlo entendido. Y si no lo tiene pero su `method_missing` lo atiende, a todos los efectos de la interfaz lo entendió: le mandaste "comete un sánguche" y el sánguche está comido. Que haya un método, un mixin o un `method_missing` atrás es **una mecánica más** por la cual el objeto llegó a responder. Llevado al extremo: podrías programar todo Ruby con un solo método `method_missing` en `BasicObject` con un `if` gigante que mire quién es el receptor y qué mensaje llegó.

Hasta hoy, el modelo era simple: los objetos tienen métodos, y los mensajes que entienden son los de sus métodos. **`method_missing` rompe ese modelo**, y no por cómo lo uses: por existir. Consecuencias concretas:

**1. `methods` ya no lista lo que un objeto entiende.** `atila.methods` te da `descansar`, `atacar`, `energia`… y no `comerse_un_sanguche`. Tampoco puede listarlo: con el `method_missing` de la sección 4, `atila` entiende **infinitos** mensajes. Tiene una interfaz infinita. No podés dibujar un diagrama de clases de `Guerrero` con infinitos mensajes adentro.

**2. `methods` y `respond_to?` son dos preguntas distintas.** Una es "dame la lista"; la otra es "¿podés responder a esto?" y da un booleano. La lista no siempre se puede armar. El booleano, en principio, sí.

> **`respond_to?(:mensaje)`:** le pregunta a un objeto si puede responder ese mensaje. Devuelve `true` o `false`.

**3. Y `respond_to?` miente.**

```ruby
p atila.methods.include?(:comerse_un_sanguche)   # => false   ← esperable: no hay método
p atila.respond_to?(:comerse_un_sanguche)        # => false   ← mentira: lo respondió hace tres líneas
p atila.respond_to?(:descansar)                  # => true    ← lo normal sigue andando
```

`respond_to?` mira los métodos definidos en la jerarquía. No sabe nada de `method_missing`, y no podría: `method_missing` puede atender cualquier cosa, y `respond_to?` no tiene forma de adivinar cuáles. Ruby tampoco lo puede arreglar solo: en `method_missing` le dijiste **qué hacer** con un mensaje, no **qué mensajes entendés**.

Esto importa porque hay código que **pregunta antes de mandar**: "de esta lista de mensajes, le mando a este objeto solamente los que pueda responder". Ese código, con nuestro guerrero, se equivoca: descarta `comerse_un_sanguche` porque `respond_to?` dijo que no, y después el guerrero lo hubiera respondido perfectamente. Ya no podés confiar en `respond_to?`.

### Salir de la magia: es un mensaje

Acá está la gracia de todo el diseño de `method_missing`, y vale la pena decirla explícita. El lookup hace un salto mágico hasta arriba de todo, corta… **y manda un mensaje**. En ese momento dejamos de estar en un mundo extraño donde la VM hace cosas, y volvemos al terreno conocido: mensajes. `respond_to?` es un mensaje. Si miente, se arregla como se arregla cualquier mensaje que no hace lo que querés: redefiniéndolo.

```ruby
class Guerrero
  def respond_to?(name, include_all = false)   # ⚠️ respond_to? tiene un 2° parámetro opcional (incluir privados):
    name.start_with?("comerse_") || super      #    si lo pisás con uno solo, rompés a quien lo llame con dos
  end                                          # los míos → true; para el resto, lo que ya decía
end

p atila.respond_to?(:comerse_un_sanguche)   # => true    ← ahora dice la verdad
p atila.respond_to?(:descansar)             # => true    ← gracias al super
p atila.respond_to?(:sarasa)                # => false
```

`start_with?("comerse_")` pregunta si el nombre empieza con ese texto; los símbolos lo entienden. Y el `|| super` es lo que hace que `descansar` siga dando `true`: `super` ejecuta el `respond_to?` original, que mira los métodos de la jerarquía como siempre. Si no ponés `super`, tenés que ir vos a buscar todos los métodos de toda la jerarquía para ver si el que te pasaron está ahí, cada vez que redefinís esto, y `descansar` te da `false` mientras tanto.

**Regla que aparece acá y va a volver toda la materia: siempre que redefinís un método, sé consciente de qué estás tapando, y si corresponde, llamá a `super`.** Especialmente en los mensajes que responden **consultas**: cuando redefinís una consulta, casi siempre querés que la respuesta anterior sea parte de tu respuesta. Cuando redefinís algo que *causa un efecto*, a veces sí querés tapar lo anterior; pero eso tiene que ser una decisión, no un olvido.

---

## 6. Un `method_missing` con criterio: `comerse_*` 🔴

El `method_missing` de la sección 4 contesta cualquier cosa. Queremos algo más útil: que un guerrero entienda **los mensajes que empiezan con `comerse_`**, y que comer le suba la energía en tantos puntos como letras tenga lo que comió. `sarasa` no queremos que lo entienda.

```ruby
require_relative 'age'

class Guerrero
  private def method_missing(name, *args)
    if name.start_with?("comerse_")                              # ¿es un mensaje de los nuestros? (name es un símbolo)
      @energia += name.to_s.delete_prefix("comerse_").size       # sí: energía += cantidad de letras de lo que comió
    end
  end
end

atila = Guerrero.new(10, 10, 10)
puts atila.energia                 # => 10
puts atila.comerse_un_sanguche     # => 21    ← el método devuelve el resultado de la asignación: la energía nueva
puts atila.energia                 # => 21    ← "un_sanguche" tiene 11 caracteres
```

**¿CÓMO FUNCIONA?** `atila.comerse_un_sanguche`:

1. Lookup 1 falla. Ruby manda `atila.method_missing(:comerse_un_sanguche)`.
2. `name` es el símbolo `:comerse_un_sanguche`. `name.start_with?("comerse_")` → `true`.
3. `name.to_s` → `"comerse_un_sanguche"`. `.delete_prefix("comerse_")` → `"un_sanguche"`. `.size` → `11`.
4. `@energia += 11` → 21. Es lo último que se evalúa, así que es lo que devuelve el método.

⚠️ **Trampa de símbolo vs string.** `name` llega como símbolo. Un símbolo entiende `start_with?`, pero **no** entiende `delete_prefix`: si escribís `name.delete_prefix("comerse_")` te da `NoMethodError` (y como estás adentro de `method_missing`, el error confunde el doble). Para recortarlo, primero pasalo a string con `to_s`.

Funciona. Y tiene un bug que todavía no ves.

### Lo que pasa con lo que no es nuestro

```ruby
p atila.sarasa            # => nil     ← ⚠️ no explota. Devuelve nil en silencio.
p atila.sarasa(1, 2)      # => nil
p atila.energia           # => 21      ← y no tocó nada
```

`sarasa` cae en `method_missing`, el `if` no se cumple, el método termina sin hacer nada y devuelve `nil`. **Te comiste el `NoMethodError`.** Es exactamente la opción "no hacer nada" de la sección 2, la más peligrosa: ahora cualquier error de tipeo en cualquier mensaje a un guerrero pasa desapercibido, y aparece tres archivos más lejos como un `nil` inexplicable.

Lo que queremos para `sarasa` es **lo que Ruby ya hacía**: que use el `method_missing` original. Y "lo que ya hacía" se pide con `super`:

```ruby
class Guerrero
  private def method_missing(name, *args)
    if name.start_with?("comerse_")
      @energia += name.to_s.delete_prefix("comerse_").size
    else
      super            # no es mío: que lo resuelva el method_missing de más arriba en la cadena
    end                # (super sin paréntesis reenvía los mismos argumentos: name y *args)
  end
end

atila.sarasa
# => NoMethodError: undefined method `sarasa' for an instance of Guerrero   ← el error normal, como corresponde
atila.comerse_una_pizza
puts atila.energia         # => 30    ← "una_pizza" tiene 9 letras: 21 + 9
```

¿Por qué `super` y no lanzar vos el `NoMethodError` a mano (con `raise`, la instrucción que lanza una excepción)? Porque **no sabés qué hay más arriba**. Si algún mixin de la jerarquía también definió `method_missing` para atender otros mensajes, tu `raise` lo pisa y esa lógica se pierde. Con `super`, el mensaje sigue subiendo por la cadena: si alguien lo atiende, lo atiende; si nadie, llega a `BasicObject` y explota como siempre. Es la misma regla de la sección 5 aplicada a `method_missing`.

> 🎓 **Para el parcial, si te preguntan:** *¿Por qué hay que delegar a `super` en `method_missing`?*
> Porque un `method_missing` sin `super` responde **todos** los mensajes, incluidos los que no sabe atender: devuelve `nil` en vez de fallar, y el error aparece lejos de la causa. Con `super` el mensaje sigue subiendo por la jerarquía: lo atiende otro `method_missing` si lo hay, y si no, `BasicObject` lanza `NoMethodError` como corresponde. Además no pisa la lógica de nadie más arriba.

---

## 7. El contrato: `respond_to_missing?` 🔴

En la sección 5 arreglamos `respond_to?` pisándolo. Anda, pero cada vez que lo hacés tenés que repetir la lógica de "además de los míos, todos los métodos de la jerarquía". Ruby previó esta situación: `respond_to?` está escrito para que, cuando no encuentra el método pedido, **consulte un segundo mensaje** antes de contestar `false`. Ese mensaje se llama `respond_to_missing?` y existe específicamente para que lo redefinas cuando redefinís `method_missing`.

La versión completa, en un archivo nuevo (sin la redefinición de `respond_to?` de la sección 5):

```ruby
require_relative 'age'

class Guerrero
  private def method_missing(name, *args)
    if name.start_with?("comerse_")
      @energia += name.to_s.delete_prefix("comerse_").size
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)   # misma firma que usa respond_to? por dentro
    name.start_with?("comerse_") || super                    # el MISMO criterio que method_missing; el resto, super
  end
end

atila = Guerrero.new(10, 10, 10)
p atila.respond_to?(:comerse_un_sanguche)   # => true     ← respond_to? no encontró método, consultó respond_to_missing?
p atila.respond_to?(:descansar)             # => true     ← lo encontró directo: respond_to_missing? ni se consultó
p atila.respond_to?(:sarasa)                # => false    ← respond_to_missing? dijo que no (vía super)
```

El segundo parámetro (`include_private`) es el que le dice si tiene que contar también los métodos privados; lo recibís y se lo pasás a `super`, no hace falta hacer nada más con él.

```
atila.respond_to?(:comerse_un_sanguche)
   │
   ▼  ¿hay un método comerse_un_sanguche en la jerarquía?       ✗ no
   │
   ▼  entonces respond_to? pregunta:
atila.respond_to_missing?(:comerse_un_sanguche, false)
   │
   ▼  el nuestro: start_with?("comerse_") → true                 ✓ respond_to? devuelve true
```

**El contrato:** cada vez que redefinís `method_missing`, redefinís `respond_to_missing?` con el mismo criterio. Si no, el objeto entiende mensajes que dice no entender, y todo código que pregunte antes de mandar se equivoca. Los dos van juntos, siempre, como un par.

> 🎓 **Para el parcial, si te preguntan:** *Redefiniste `method_missing`. ¿Qué más tenés que redefinir y por qué?*
> `respond_to_missing?`, con el mismo criterio que `method_missing`, delegando a `super` lo que no es tuyo. `respond_to?` solo mira los métodos definidos en la jerarquía; para lo que se atiende dinámicamente consulta `respond_to_missing?`. Sin eso, `respond_to?` devuelve `false` para mensajes que el objeto sí responde, y el código que consulta antes de enviar se rompe.

### Lo que dejaste de poder asumir

Con estas dos herramientas, si te preguntan "¿qué mensajes entiende un objeto en Ruby?", la respuesta honesta es "no siempre se puede saber". Para armar la lista completa tendrías que revisar si alguien en la jerarquía se metió con `method_missing`; y aun así, alguien pudo haber reabierto el de `BasicObject`. Es parte de la naturaleza de un lenguaje dinámico: podés hacer lo que quieras, y cuando podés hacer lo que quieras, las reglas pierden valor. Una regla que no se cumple siempre no sirve para construir encima.

Por eso la disciplina: si usás `method_missing`, defendés `respond_to?` a capa y espada con `respond_to_missing?`, porque es la única manera que le queda al resto del programa de chequear si un objeto entiende algo. Y cuando algo se comporta raro, en vez de asumir el peor caso ("seguro hay un `method_missing` escondido"), usás las herramientas de introspección para investigar (las de la clase pasada, más `respond_to?`): `methods`, `respond_to?`, `method(:x).owner`, `ancestors`. Un `method_missing` escondido es una posibilidad, no la explicación por defecto.

En la Parte 2 vamos a construir algo con esto: un objeto cuya única razón de existir es **no entender** ningún mensaje.

---

## Checkpoint de la Parte 1

Sin respuestas. Si alguna no te sale, buscala en esta parte.

1. `atila.volar(3)`: describí el camino completo, desde el primer lookup hasta el `NoMethodError`, nombrando quién lanza la excepción y cuántos lookups corrieron.
2. Un lenguaje podría, ante un mensaje no entendido, no hacer nada y seguir. ¿Por qué eso es peor que una excepción, si el programa ya está mal de todas formas?
3. ¿Qué diferencia hay entre lanzar una excepción y hacer *panic*, si una excepción que nadie ataja termina en *panic* igual?
4. ¿Por qué Ruby le manda `method_missing` **al receptor** y no a `Object` o a un objeto global "resolvedor"? ¿Qué gana con eso?
5. ¿Qué tres datos recibe `method_missing`, y por qué son exactamente esos?
6. Si borraras `method_missing` de `BasicObject`, ¿en cuál de las opciones de la sección 2 caería Ruby? ¿Por qué?
7. Escribí un `method_missing` para `Muralla` que atienda cualquier mensaje que empiece con `reforzar_` sumándole 5 al potencial defensivo, y que falle normalmente con cualquier otro mensaje. Agregale lo que le falte para que `respond_to?` no mienta.
8. Tu `method_missing` no llama a `super`. Mostrá una línea de código que se rompe *en silencio* por eso, y explicá con la tabla de la sección 2 por qué es peor que un error.
9. Para el mismo problema, ¿por qué conviene redefinir `respond_to_missing?` en vez de `respond_to?` directamente, si las dos andan?
10. Después de esta parte, ¿qué le contestás a alguien que te pregunta "dame la lista de mensajes que entiende `atila`"?

---

## Qué viene en la Parte 2

La misma herramienta, usada al revés: en vez de un objeto que entiende *algunos* mensajes más, un objeto que **no entiende ninguno** y por eso los recibe todos. Con eso se arma un registrador de mensajes: un objeto que se pone adelante de un guerrero, anota todo lo que le mandan y se lo reenvía. Vas a ver qué mensajes se le escapan (`is_a?`, `to_s`) y por qué, de dónde sale `BasicObject` como superclase, qué familia de patrones es esta, y el corolario que define cuándo usar `method_missing`: sirve para extender interfaces, nunca para pisar métodos que ya existen.

**FIN DE LA PARTE 1**
