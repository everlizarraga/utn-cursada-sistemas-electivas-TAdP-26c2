# Apunte maestro — clase04 — `method_missing`, bloques, contextos e `instance_eval`
## Parte 1 — Cuando el lookup falla: `method_missing`

> **Qué cubre esta parte.** Qué pasa cuando le mandás a un objeto un mensaje que no entiende: qué podría hacer un lenguaje con eso, qué hace Ruby, y la herramienta que Ruby te da para cambiarlo, `method_missing`. Cierra con el contrato que viene pegado a esa herramienta: `super` y `respond_to_missing?`.
>
> **Cómo sigue la unidad.** Parte 2: el registrador de mensajes, `BasicObject` y cuándo no usar `method_missing`. Parte 3: bloques, procs y lambdas. Parte 4: contextos, qué los corta y qué no, e `instance_eval`. Parte 5: construir una sintaxis propia con todo eso, información operativa y cierre.
>
> **De dónde venís.** De las clases 1 a 3 se asume: el method lookup con autoclase (`#atila → Guerrero → … → BasicObject`), los mixins linearizados dentro de esa cadena, `Kernel` como el mixin de `Object`, `send`, `methods`, `instance_methods`, `method(:x)` con `.owner`, y `define_method`.
>
> **Cómo está escrita.** Cada sección abre con la **regla**, en afirmativo. Después viene el caso que la muestra, con el resultado al lado de cada línea. Todo el código se ejecutó antes de escribirse. Donde un mecanismo tiene varias formas, van en una tabla: *escribís / Ruby entiende / sale*.
>
> **Código.** Ruby 3.x con el `age.rb` de la materia (`Guerrero`, `Atacante`, `Defensor`, `Espadachin`, `Misil`, `Muralla`). `puts x` imprime el texto; `p x` muestra el valor tal cual (corchetes, comillas, `nil` visible). Los mensajes de error cambian un poco entre versiones (3.3 dice `for an instance of Guerrero`; 3.2 dice `for #<Guerrero:0x…>`): lo que importa es el tipo de error.

---

## 1. El camino infeliz del lookup 🟡

> **Regla.** El method lookup recorre la cadena de ancestros del receptor de abajo hacia arriba y termina en `BasicObject`. Después de `BasicObject` no hay nada (`superclass` es `nil`): ahí el algoritmo tiene un **corte** cableado. Un mensaje que llega al corte es un envío que **no puede funcionar** con el código tal como está escrito.

Un guerrero recibe dos mensajes. Uno lo entiende, el otro no:

```ruby
require_relative 'age'           # carga Atacante, Defensor, Guerrero, Espadachin, Misil, Muralla

atila = Guerrero.new             # sin argumentos: potencial ofensivo 20, energía 100, potencial defensivo 10
p Guerrero.ancestors             # => [Guerrero, Defensor, Atacante, Object, Kernel, BasicObject]
                                 #    la cadena completa que recorre el lookup, mixins incluidos

atila.descansar                  # lookup: #atila (vacía) → Guerrero ✓ está: se ejecuta
atila.comerse_un_sanguche        # lookup: #atila → Guerrero → Defensor → Atacante → Object → Kernel → BasicObject → ✗
# => NoMethodError: undefined method `comerse_un_sanguche' for an instance of Guerrero
```

El camino de `comerse_un_sanguche`, dibujado (dejo afuera los mixins: están, el lookup los recorre, y no cambian nada de lo que sigue):

```
atila.comerse_un_sanguche

  #atila ──► Guerrero ──► Object ──► BasicObject ──► *
    no          no          no          no           ↑
                                              se acabó el camino
```

Ese `*` es el corte: el punto donde el algoritmo tiene escrito "si llegaste acá, no hay ningún otro lugar donde buscar".

**Qué significa haber llegado ahí.** Alguien escribió en el código fuente un envío de mensaje que no puede funcionar: el objeto no lo entiende, y ningún mecanismo del sistema lo va a hacer entender. La única forma de arreglarlo es que una persona cambie el código. Desde el punto de vista de la máquina virtual, es un error conceptual del programa, distinto de un problema de recursos (como quedarse sin lugar en un array), que el programa sí puede resolver mientras corre. *(Cuando veamos tipado estático, más adelante en la materia, esta situación se va a categorizar con más precisión; por ahora alcanza con esto.)*

> **Máquina virtual (VM):** el programa que ejecuta tu programa. En Ruby, el intérprete; en Java, la JVM. Cuando decimos "la VM tiene que hacer algo", hablamos del intérprete que está corriendo tu código.

La VM es un programa, y un programa siempre hace **algo**, determinístico. Así como el lookup tiene un algoritmo para el camino feliz, necesita uno para el infeliz. Y ahí hay más de una opción.

---

## 2. Qué puede hacer el lenguaje cuando llega al `*` 🟡

> **Regla.** Ante un envío que no puede funcionar, el lenguaje **elige cómo fallar**; hacer que funcione está descartado. Las opciones se ordenan por cuánta oportunidad le dan al programa de hacer algo con el fallo. Lanzar una excepción es la más generosa: interrumpe, y deja que alguien la ataje.

| Opción | Qué hace la VM | Qué oportunidad te da |
|---|---|---|
| **Lanzar una excepción** | Interrumpe la ejecución y sube por la pila de llamadas (los métodos que están ejecutándose, uno adentro del otro) hasta que alguien la ataje | Una última chance de hacer algo con el fallo |
| **Panic** | Mata el proceso, sin más | Ninguna |
| **No hacer nada** | Sigue con la siguiente sentencia como si el mensaje se hubiera ejecutado | Ninguna, y encima no te enterás |
| **Código de error** | El envío "retorna" un valor universal de error | Chequearlo a mano después de cada paso |
| **Reintentar** | Vuelve a hacer el lookup | Ninguna: nada cambió entre un intento y otro |
| **Loop infinito** | En vez de cortar en el `*`, la flecha vuelve al principio | Ninguna, y encima no sabés si se colgó o está trabajando |

> **Panic:** terminar el proceso de golpe, sin darle al programa ninguna posibilidad de intervenir. Algunas máquinas virtuales lo hacen cuando detectan algo que no pueden manejar.

Lo que sale de la tabla:

- **Reintentar** parte de que algo cambió entre un intento y otro. Un envío de mensaje es atómico: entre un lookup y el siguiente, nada cambió. (Sacando hilos y paralelismo, que son otra discusión.)
- **No hacer nada** es la más peligrosa: el resto del programa sigue ejecutando después de que una sentencia se salteó. Cada sentencia de un programa tiene que ejecutarse; una salteada en silencio aparece como un error incomprensible más adelante.
- **Los códigos de error** existieron mucho tiempo (un registro que se seteaba cuando algo fallaba, y alguien tenía que ir a leerlo). Dependen de que alguien los lea: "pagar los sueldos" termina con la mitad sin pagar y un mensajito guardado que dice "algo salió mal".
- **El loop infinito y el panic**, a efectos del guerrero, dan lo mismo que la excepción: el mensaje no se ejecutó. La diferencia está del lado del usuario: con un loop no sabés si el sistema se rompió o está procesando algo largo; con un panic no tenés ninguna oportunidad de intervenir.

**Excepción vs. panic.** Una excepción que nadie ataja sube hasta arriba de todo, y ahí la VM hace lo único que le queda: panic. Terminan igual. La diferencia es que a la excepción **la podés atajar**. Atajarla sirve para resolver *el nuevo problema*: que se está por morir el servidor porque alguien mandó un mensaje mal. En vez de matar todo, mostrás un cartel, avisás, y el resto sigue corriendo. Fallaste, pero con más gracia. (`atila.comerse_un_sanguche` sigue sin funcionar: eso lo arregla una persona, no un `rescue`.)

Un ejemplo que usás todos los días: la consola de Ruby. Le mandás un mensaje que no entiende, te muestra el error… y sigue viva, podés seguir escribiendo. Alguien, en la capa más externa de ese programa, atajó la excepción, la imprimió y siguió. La capa más cercana al usuario de casi cualquier programa tiene un gran "atajá todo" que convierte cualquier excepción en un aviso en vez de una muerte.

### Atajar la excepción: `rescue`

`begin … rescue … end` es la forma de hacer *try/catch* en Ruby: intento hacer esto; si pasa esta excepción, hago esto otro. El mismo recorrido de una lista con un intruso, sin y con `rescue`:

```ruby
require_relative 'age'

lista = [Guerrero.new(10, 10, 10),
         Guerrero.new(10, 10, 10),
         "atila",                              # un String en el medio: no entiende descansar
         Guerrero.new(10, 10, 10)]

lista.each do |guerrero|                       # sin rescue
  guerrero.descansar
  puts "se mandó descansar"
end

lista.each do |guerrero|                       # con rescue
  begin                                        # intento…
    guerrero.descansar
    puts "se mandó descansar"
  rescue NoMethodError                         # …y si se levanta un NoMethodError, en vez de explotar:
    puts "no se entendió el mensaje"           # me como la excepción y sigo
  end
end
```

| Recorrido | Sale | Qué pasó con el cuarto guerrero |
|---|---|---|
| sin `rescue` | `se mandó descansar` / `se mandó descansar` / `NoMethodError: undefined method 'descansar' for an instance of String` | nunca recibió `descansar`: el programa se cortó en el tercero |
| con `rescue` | `se mandó descansar` / `se mandó descansar` / `no se entendió el mensaje` / `se mandó descansar` | recibió su mensaje: el programa corrió hasta el final |

`NoMethodError` es la excepción que Ruby lanza para este caso particular. Eso es lo que compra la excepción: control sobre el fallo.

⚠️ **Atajar `NoMethodError` es mala práctica en el 99% de los casos.** Es un error del programa (sección 1): al taparlo lo escondés, y aparece más lejos y más raro. La buena práctica es *fail-fast*: fallar temprano y cerca de la causa. Acá lo atajamos para ver que se puede, no como receta.

> **Fail-fast:** principio de diseño que prefiere que un error explote lo antes posible y lo más cerca posible de donde se originó, en vez de propagarse en silencio.

> 🕳️ **Madriguera — cómo lo manejan otras tecnologías**
> Smalltalk implementa el lookup en el propio lenguaje y, al fallar, manda un mensaje al objeto (`doesNotUnderstand`); su entorno deja frenar en el error, corregir el código y continuar desde ahí. La JVM hace *panic* ante bytecode inválido. Bash sigue ejecutando tras una línea fallida salvo que lo configures. Haskell, ante una división por cero, corta sin manejo de excepciones.
> *Volvé al camino — esto se profundiza aparte, otro día.*

Ruby es más generoso que todo lo anterior: además de la excepción, tiene una opción más, pensada específicamente para este punto del lookup. Es de lo que se trata esta parte.

---

## 3. Una segunda oportunidad: a quién avisarle 🔴

> **Regla.** Cuando el lookup llega al `*`, Ruby le manda **al mismo receptor** un segundo mensaje: `method_missing`, con el nombre del mensaje original como símbolo y sus parámetros. `method_missing` es un método común y corriente, definido en `BasicObject`, y **es él quien lanza `NoMethodError`**. La excepción no la lanza el lookup: la lanza un método, encontrado por un lookup común y corriente.

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

Comprobalo:

```ruby
require_relative 'age'

atila = Guerrero.new
puts atila.method(:method_missing).owner    # => BasicObject   ← el method_missing que atila usa hoy está en BasicObject
```

**Qué información hay en ese momento.** Para hacer el lookup, Ruby partió de tres cosas, y las tres siguen a mano cuando llega al `*`:

1. **El receptor:** `atila`. Le pidió su autoclase para arrancar el camino.
2. **El nombre del mensaje:** `comerse_un_sanguche`. Es lo que fue buscando en cada clase.
3. **Los parámetros:** ninguno, en este caso. Los tenía por si encontraba el método.

Es decir: **todo lo que hubiera hecho falta para ejecutar el mensaje, menos el método.** Eso es exactamente lo que viaja en el segundo mensaje:

```
receptor.method_missing(mensaje, parámetros)

atila.method_missing(:comerse_un_sanguche)        # el nombre viaja como símbolo; parámetros, ninguno
```

**Por qué al receptor.** Estamos en un lenguaje de objetos: para que alguien decida algo, le mandamos un mensaje. Ruby elige mandárselo al receptor porque es el objeto interesado en que esto se maneje: así **cada objeto (o cada jerarquía) tiene su propio plan B**. Los guerreros manejan de una forma lo que no entienden, las murallas de otra. Las alternativas eran un plan B único para todo el programa: avisarle a la clase `Object` (todos heredan de ahí, así que cambiarlo lo cambia para todos) o a un objeto bien conocido que resuelva estos casos (como `nil` representa "la nada"). Con el receptor, el plan B se elige por jerarquía.

**Por qué siempre llega.** El segundo mensaje tiene que poder llegarle a **cualquier** objeto, o el mecanismo no sirve. Se garantiza igual que con cualquier otro mensaje que todos entienden: definiéndolo arriba de todo, en `BasicObject`. Por eso el segundo lookup **siempre tiene éxito**, y por eso el corte del `*` está cableado justo ahí: un `method_missing` que no se encontrara mandaría `method_missing`, que no se encontraría, que mandaría `method_missing`… el loop infinito de la sección 2.

Tres cosas para quedarse:

- **Cada vez que falla un lookup, corriste dos lookups.** El primero busca tu método; el segundo busca `method_missing`. Es más caro que un envío normal.
- **El segundo lookup siempre tiene éxito**, porque `method_missing` viene con Ruby, en `BasicObject`.
- **Es una excepción, como en la sección 2**, con una diferencia: antes de lanzarla, Ruby te deja intervenir con un mensaje. Es un *hook*.

> **Hook (gancho):** un punto del mecanismo del lenguaje donde vos podés enganchar código propio para cambiar lo que pasa por defecto.

Ruby ya viene cableado así. Lo único que vamos a hacer nosotros es cambiar cómo está cableado.

> 🎓 **Para el parcial, si te preguntan:** *¿Qué pasa cuando un objeto recibe un mensaje que no entiende?*
> El method lookup recorre toda la jerarquía (autoclase, clase, mixins, superclases hasta `BasicObject`) y no encuentra el método. Entonces Ruby le manda **al mismo receptor** el mensaje `method_missing`, con el nombre del mensaje original como símbolo y sus parámetros. Ese segundo mensaje hace el lookup normal; la implementación por defecto está en `BasicObject` y lanza `NoMethodError`. Se le avisa al receptor y no a un objeto global para que cada objeto pueda decidir su propio plan B.

---

## 4. Cambiar el plan B: redefinir `method_missing` 🔴

> **Regla.** `method_missing` se encuentra por lookup. Definido en cualquier lugar de la cadena **más abajo** que `BasicObject`, el lookup encuentra el tuyo primero y el de `BasicObject` no se ejecuta. Se define **privado**, porque es un mecanismo interno del objeto y no parte de su interfaz; Ruby lo invoca igual.

La versión más chica posible:

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

Tres cosas de sintaxis que aparecen acá:

- **`*args`** (se pronuncia *splat*): el asterisco junta en un array llamado `args` todos los argumentos que vengan, sean cuantos sean. `method_missing` no sabe de antemano cuántos parámetros trae el mensaje que no se entendió, así que los recibe todos en una lista. Sin argumentos, `args` es `[]`.
- **`private def`**: define el método y lo marca privado en la misma línea. Privado quiere decir que solo se puede mandar sin receptor explícito (`atila.method_missing(...)` desde afuera no está permitido); Ruby, que lo manda por dentro, lo encuentra igual.
- **`#{name}`**: interpolación, mete el valor de `name` adentro del string. Solo funciona con comillas dobles.

**¿CÓMO FUNCIONA?** `atila.comerse_un_sanguche`:

1. Lookup 1: `#atila` → `Guerrero` → `Defensor` → `Atacante` → `Object` → `Kernel` → `BasicObject` → `*`. No está.
2. Ruby manda `atila.method_missing(:comerse_un_sanguche)` con `args = []`.
3. Lookup 2: `#atila` → `Guerrero` ✓. Está el nuestro. Se ejecuta: imprime "Me mataste…".
4. `method_missing` devuelve lo que devolvió `puts` (`nil`), y ese `nil` es lo que "devuelve" `atila.comerse_un_sanguche`.
5. El programa sigue en la línea siguiente. El de `BasicObject` nunca corrió.

**Dónde se ve y dónde no: `instance_methods` lista solo los públicos.** Esto es una regla general de la introspección, y `method_missing` es el primer lugar donde te la vas a cruzar: `instance_methods` (y `methods` sobre un objeto) muestran los métodos **públicos**. Los privados tienen su propia lista, `private_instance_methods`. `method(:x).owner` no filtra por visibilidad: encuentra al método esté donde esté.

| Escribís | Ruby entiende | Sale |
|---|---|---|
| `Guerrero.instance_methods(false)` | los métodos públicos definidos en `Guerrero` mismo | `[]` |
| `Guerrero.private_instance_methods(false)` | los privados definidos en `Guerrero` mismo | `[:initialize, :method_missing]` |
| `atila.method(:method_missing).owner` | dónde vive el que atila usaría, sin importar visibilidad | `Guerrero` |
| `BasicObject.instance_methods(false)` | los públicos de `BasicObject` | `[:!, :equal?, :__id__, :__send__, :==, :!=, :instance_eval, :instance_exec]` |
| `BasicObject.private_instance_methods(false)` | los privados de `BasicObject` | `[:initialize, :method_missing, :singleton_method_added, …]` |

El `method_missing` original también es privado: por eso `BasicObject.instance_methods(false)` no lo muestra, y por eso el nuestro se define `private`, igual que el original. `initialize` aparece en la misma lista por la misma razón: Ruby lo hace privado solo. El mismo caso se repite con `puts`, que es privado en `Kernel` y por eso no está en `Kernel.instance_methods(false)`. Regla para llevarse: **cuando un método "no aparece", antes de concluir que no existe, mirá la lista de privados o preguntale a `method(:x).owner`.**

Con esto, `atila` responde `comerse_un_sanguche`. Y también `sarasa`, `volar`, `resolver_un_cubo_rubik`: **cualquier** mensaje que no tenga método cae acá. Ahora la pregunta incómoda.

---

## 5. ¿Entendió el mensaje? `methods` vs `respond_to?` 🔴

> **Regla.** Con `method_missing`, un objeto **responde** mensajes para los que **no tiene método**. `methods` sigue listando métodos, y `respond_to?` sigue mirando métodos: los dos dejan de reflejar lo que el objeto responde. `respond_to?` es un mensaje, y como cualquier mensaje que no hace lo que querés, se arregla redefiniéndolo. La forma definitiva de arreglarlo está en la sección 7; acá va el principio.

Le mandaste `comerse_un_sanguche` a `atila` y te respondió. **¿Entendió el mensaje?** Depende de qué signifique "entender":

- Si entender es *tener un método asociado en la jerarquía*, no lo entendió.
- Si entender es *le mandé el mensaje y me respondió algo*, lo entendió.

Y las dos definiciones se pueden dar vuelta: un objeto **con** un método `comerse_un_sanguche` cuyo cuerpo lanza `NoMethodError` es, a efectos prácticos, un objeto que no lo entiende. Y un objeto sin el método pero con un `method_missing` que lo atiende, a todos los efectos de la interfaz, lo entendió: le mandaste "comete un sánguche" y el sánguche está comido. Que haya un método, un mixin o un `method_missing` atrás es **una mecánica más** por la cual el objeto llegó a responder. Llevado al extremo: podrías programar todo Ruby con un solo `method_missing` en `BasicObject` con un `if` gigante que mire quién es el receptor y qué mensaje llegó.

Hasta hoy, el modelo era simple: los objetos tienen métodos, y los mensajes que entienden son los de sus métodos. **`method_missing` rompe ese modelo**, y no por cómo lo uses: por existir. Consecuencias concretas:

**1. `methods` ya no lista lo que un objeto entiende.** `atila.methods` te da `descansar`, `atacar`, `energia`… y no `comerse_un_sanguche`. Tampoco puede listarlo: con el `method_missing` de la sección 4, `atila` entiende **infinitos** mensajes. Tiene una interfaz infinita. Un diagrama de clases de `Guerrero` con infinitos mensajes adentro no se puede dibujar.

**2. `methods` y `respond_to?` son dos preguntas distintas.** Una es "dame la lista"; la otra es "¿podés responder a esto?" y da un booleano. La lista a veces es imposible de armar. El booleano, en principio, siempre se puede contestar.

> **`respond_to?(:mensaje)`:** le pregunta a un objeto si puede responder ese mensaje. Devuelve `true` o `false`. Nunca lanza excepción.

**3. Y `respond_to?` miente.**

```ruby
p atila.methods.include?(:comerse_un_sanguche)   # => false   ← esperable: no hay método
p atila.respond_to?(:comerse_un_sanguche)        # => false   ← mentira: lo respondió hace tres líneas
p atila.respond_to?(:descansar)                  # => true    ← lo normal sigue andando
```

`respond_to?` mira los métodos definidos en la jerarquía. En `method_missing` le dijiste a Ruby **qué hacer** con un mensaje, y Ruby sigue sin saber **qué mensajes entendés**: `method_missing` puede atender cualquier cosa, y `respond_to?` no tiene forma de adivinar cuáles.

Esto importa porque hay código que **pregunta antes de mandar**: "de esta lista de mensajes, le mando a este objeto solamente los que pueda responder". Ese código, con nuestro guerrero, se equivoca: descarta `comerse_un_sanguche` porque `respond_to?` dijo que no, y después el guerrero lo hubiera respondido perfectamente. Ya no podés confiar en `respond_to?`.

### Salir de la magia: es un mensaje

Acá está la gracia de todo el diseño de `method_missing`, y vale la pena decirla explícita. El lookup hace un salto mágico hasta arriba de todo, corta… **y manda un mensaje**. En ese momento dejamos de estar en un mundo extraño donde la VM hace cosas, y volvemos al terreno conocido: mensajes. `respond_to?` es un mensaje. Si miente, se arregla redefiniéndolo.

**Paso intermedio.** Lo que sigue anda, y en la sección 7 lo vas a **reemplazar** por la forma que Ruby previó para esto. Va acá porque muestra el principio con la herramienta más básica: redefinir el mensaje que miente.

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

`start_with?("comerse_")` pregunta si el nombre empieza con ese texto; los símbolos lo entienden. El `|| super` es lo que hace que `descansar` siga dando `true`: `super` ejecuta el `respond_to?` original, que mira los métodos de la jerarquía como siempre. Sin `super`, `descansar` da `false`, y para arreglarlo tendrías que ir vos a buscar todos los métodos de toda la jerarquía cada vez que redefinís esto.

**Regla que aparece acá y va a volver toda la materia: siempre que redefinís un método, sé consciente de qué estás tapando, y si corresponde, llamá a `super`.** Especialmente en los mensajes que responden **consultas**: cuando redefinís una consulta, casi siempre querés que la respuesta anterior sea parte de tu respuesta. Cuando redefinís algo que *causa un efecto*, a veces sí querés tapar lo anterior; pero eso tiene que ser una decisión, no un olvido.

---

## 6. Un `method_missing` con criterio: `comerse_*` 🔴

> **Regla.** Un `method_missing` útil atiende **solo los mensajes que son suyos** (un criterio sobre el nombre) y delega **todo lo demás a `super`**, para que el mensaje siga subiendo por la cadena y termine en el `NoMethodError` de `BasicObject` como corresponde. Sin el `super`, el método atiende todo y devuelve `nil` en silencio: la opción "no hacer nada" de la sección 2.

El `method_missing` de la sección 4 contesta cualquier cosa. Queremos algo más útil: que un guerrero entienda **los mensajes que empiezan con `comerse_`**, y que comer le suba la energía en tantos puntos como letras tenga lo que comió. `sarasa` queremos que falle como siempre.

Primera versión, con el criterio y sin el `super`:

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

⚠️ **Trampa de símbolo vs string.** `name` llega como símbolo. Un símbolo entiende `start_with?` y **no** entiende `delete_prefix`: `name.delete_prefix("comerse_")` da `NoMethodError: undefined method 'delete_prefix' for :comerse_un_sanguche:Symbol` (y como estás adentro de `method_missing`, el error confunde el doble). Para recortarlo, primero pasalo a string con `to_s`.

### Lo que pasa con lo que no es nuestro

La misma clase, con un mensaje que no es nuestro:

```ruby
p atila.sarasa            # => nil     ← ⚠️ no explota. Devuelve nil en silencio.
p atila.sarasa(1, 2)      # => nil
p atila.energia           # => 21      ← y no tocó nada
```

`sarasa` cae en `method_missing`, el `if` no se cumple, el método termina sin hacer nada y devuelve `nil`. **Te comiste el `NoMethodError`.** Es la opción "no hacer nada" de la sección 2, la más peligrosa: cualquier error de tipeo en cualquier mensaje a un guerrero pasa desapercibido, y aparece tres archivos más lejos como un `nil` inexplicable.

Lo que queremos para `sarasa` es **lo que Ruby ya hacía**: que use el `method_missing` original. "Lo que ya hacía" se pide con `super`:

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
```

| Escribís | Ruby entiende | Sale |
|---|---|---|
| `atila.comerse_una_pizza` | es nuestro: energía += 9 | `30` (21 + las 9 letras de `una_pizza`) |
| `atila.sarasa` | no es nuestro → `super` → `BasicObject` | `NoMethodError: undefined method 'sarasa' for an instance of Guerrero` |
| `atila.descansar` | hay método: `method_missing` ni corre | lo de siempre |

**Por qué `super` y no lanzar vos el `NoMethodError` a mano** (con `raise`, la instrucción que lanza una excepción): porque **no sabés qué hay más arriba**. Con `super`, el mensaje sigue subiendo por la cadena: si algún mixin de la jerarquía también definió `method_missing` para atender otros mensajes, lo atiende; si nadie, llega a `BasicObject` y explota como siempre. Un `raise` tuyo pisa esa lógica. Es la misma regla de la sección 5 aplicada a `method_missing`.

> 🎓 **Para el parcial, si te preguntan:** *¿Por qué hay que delegar a `super` en `method_missing`?*
> Porque un `method_missing` sin `super` responde **todos** los mensajes, incluidos los que no sabe atender: devuelve `nil` en vez de fallar, y el error aparece lejos de la causa. Con `super` el mensaje sigue subiendo por la jerarquía: lo atiende otro `method_missing` si lo hay, y si no, `BasicObject` lanza `NoMethodError` como corresponde. Además no pisa la lógica de nadie más arriba.

---

## 7. El contrato: `respond_to_missing?` 🔴

> **Regla.** `respond_to?` está escrito para que, cuando no encuentra el método pedido, **consulte un segundo mensaje** antes de contestar `false`: `respond_to_missing?`. Existe específicamente para que lo redefinas cuando redefinís `method_missing`. **El contrato:** cada `method_missing` va con un `respond_to_missing?` del **mismo criterio**, y los dos delegan a `super` lo que no es suyo. Van juntos, siempre, como un par.

La versión final de `Guerrero`. Son **dos** métodos: el `respond_to?` de la sección 5 **se saca**, porque este par lo reemplaza.

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

El segundo parámetro (`include_private`) le dice si tiene que contar también los métodos privados; lo recibís y se lo pasás a `super`, sin hacer nada más con él. Y un detalle de visibilidad: Ruby hace privado a `respond_to_missing?` por su cuenta, igual que a `initialize` (`Guerrero.private_instance_methods(false)` → `[:initialize, :respond_to_missing?, :method_missing]`), porque es un hook, no interfaz.

**Los dos flujos, lado a lado.** Son dos caminos paralelos que usan el mismo criterio. Uno **hace**; el otro **pregunta**.

```
        HACER                                        PREGUNTAR
   atila.comerse_x                              atila.respond_to?(:comerse_x)
        │                                            │
        ▼  ¿hay método comerse_x?      ✗             ▼  ¿hay método comerse_x?      ✗
        │                                            │
        ▼  Ruby manda:                               ▼  respond_to? manda:
   atila.method_missing(:comerse_x)             atila.respond_to_missing?(:comerse_x, false)
        │                                            │
        ▼  ¿empieza con comerse_?                    ▼  ¿empieza con comerse_?
     sí → lo atiende (energía += …)               sí → true
     no → super → BasicObject → NoMethodError     no → super → false
```

| | HACER | PREGUNTAR |
|---|---|---|
| Lo dispara | `atila.comerse_x` | `atila.respond_to?(:comerse_x)` |
| Primer paso | lookup de `comerse_x` | ¿hay método `comerse_x` en la jerarquía? |
| Hook al fallar el primer paso | `method_missing(name, *args)` | `respond_to_missing?(name, include_private)` |
| Criterio | `name.start_with?("comerse_")` | el **mismo** |
| `super` lleva a | el `method_missing` de `BasicObject` | el `respond_to_missing?` original |
| Termina, si es nuestro | el efecto (energía nueva) | `true` |
| Termina, si no es nuestro | `NoMethodError` | `false` (nunca una excepción) |

Que el criterio sea el mismo de los dos lados es **tu responsabilidad**: Ruby no lo verifica. Un `method_missing` que atiende `comerse_*` con un `respond_to_missing?` que dice `false` deja el objeto en el estado de la sección 5: responde mensajes que dice no entender.

**Por qué `respond_to_missing?` y no `respond_to?` directamente**, si los dos andan:

1. **No repetís la lógica de la jerarquía.** `respond_to?` sigue haciendo su trabajo (mirar los métodos, contar o no los privados); vos solo agregás el pedazo que le falta: el criterio de tu `method_missing`.
2. **`method(:x)` también lo consulta.** Con `respond_to_missing?` definido, `atila.method(:comerse_algo)` devuelve un objeto método (clase 3) que funciona: `atila.method(:comerse_algo).owner` → `Guerrero`, y `.call` come "algo". Con solo `respond_to?` redefinido, `method(:comerse_algo)` da `NameError`. El hook es la vía oficial: todo lo que Ruby usa para preguntar "¿entendés esto?" pasa por ahí.

> 🎓 **Para el parcial, si te preguntan:** *Redefiniste `method_missing`. ¿Qué más tenés que redefinir y por qué?*
> `respond_to_missing?`, con el mismo criterio que `method_missing`, delegando a `super` lo que no es tuyo. `respond_to?` solo mira los métodos definidos en la jerarquía; para lo que se atiende dinámicamente consulta `respond_to_missing?`. Sin eso, `respond_to?` devuelve `false` para mensajes que el objeto sí responde, y el código que consulta antes de enviar se rompe.

### Lo que dejaste de poder asumir

Con estas herramientas, si te preguntan "¿qué mensajes entiende un objeto en Ruby?", la respuesta honesta es "no siempre se puede saber". Para armar la lista completa tendrías que revisar si alguien en la jerarquía se metió con `method_missing`; y alguien pudo haber reabierto hasta el de `BasicObject`. Es parte de la naturaleza de un lenguaje dinámico: podés hacer lo que quieras, y cuando podés hacer lo que quieras, las reglas pierden valor. Una regla que no se cumple siempre no sirve para construir encima.

Por eso la disciplina: si usás `method_missing`, defendés `respond_to?` con `respond_to_missing?`, porque es la única manera que le queda al resto del programa de chequear si un objeto entiende algo. Y cuando algo se comporta raro, usás las herramientas de introspección para investigar: `methods`, `private_methods`, `respond_to?`, `method(:x).owner`, `ancestors`. Un `method_missing` escondido es una posibilidad, no la explicación por defecto.

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
7. `Guerrero.instance_methods(false)` da `[]` después de definir `method_missing`. ¿Está o no está definido? ¿Con qué dos herramientas lo comprobás?
8. Escribí un `method_missing` para `Muralla` que atienda cualquier mensaje que empiece con `reforzar_` sumándole 5 al potencial defensivo, y que falle normalmente con cualquier otro mensaje. Agregale lo que le falte para que `respond_to?` no mienta.
9. Tu `method_missing` no llama a `super`. Mostrá una línea de código que se rompe *en silencio* por eso, y explicá con la tabla de la sección 2 por qué es peor que un error.
10. Dibujá los dos flujos (hacer / preguntar) para `atila.comerse_x` y `atila.respond_to?(:comerse_x)`. ¿En qué termina cada uno cuando el mensaje **no** es nuestro?
11. Para el mismo problema, ¿por qué conviene redefinir `respond_to_missing?` en vez de `respond_to?` directamente, si las dos andan?
12. Después de esta parte, ¿qué le contestás a alguien que te pregunta "dame la lista de mensajes que entiende `atila`"?

---

## Qué viene en la Parte 2

La misma herramienta, usada al revés: en vez de un objeto que entiende *algunos* mensajes más, un objeto que **no entiende ninguno** y por eso los recibe todos. Con eso se arma un registrador de mensajes: un objeto que se pone adelante de un guerrero, anota todo lo que le mandan y se lo reenvía. Vas a ver qué mensajes se le escapan (`is_a?`, `to_s`) y por qué, de dónde sale `BasicObject` como superclase, qué familia de patrones es esta, y el corolario que define cuándo usar `method_missing`: sirve para extender interfaces, nunca para pisar métodos que ya existen.

**FIN DE LA PARTE 1**
