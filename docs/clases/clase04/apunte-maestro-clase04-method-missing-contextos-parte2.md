# Apunte maestro — clase04 — `method_missing`, bloques, contextos e `instance_eval`
## Parte 2 — El registrador de mensajes, `BasicObject` y cuándo no usar `method_missing`

> **Qué cubre esta parte.** Un uso real de `method_missing`: un objeto que se pone adelante de otro, anota todo lo que le mandan y se lo reenvía. Construirlo destapa qué mensajes se le escapan y por qué, de dónde sale `BasicObject` como superclase, a qué familia de patrones pertenece, y el corolario que define para qué sirve `method_missing` y para qué no.
>
> **De dónde venís.** De la Parte 1: `method_missing(name, *args)`, el doble lookup, `super` y `respond_to_missing?`. De la clase 3: `send`. De la clase 2: `atacar` vive en el mixin `Atacante` y pregunta `potencial_defensivo` al defensor.
>
> **Código.** Ruby 3.3 con el `age.rb` de la materia. Resultados como comentario al lado de cada línea.

---

## 1. Un uso real: registrar los mensajes que recibe un objeto 🔴

El guerrero que come sánguches es un ejemplo forzado. Este no. Tenés un método que hace cosas con un guerrero:

```ruby
require_relative 'age'

def hacer_combatir(guerrero)              # recibe un guerrero, lo hace pelear, devuelve su energía final
  oponente = Guerrero.new(20, 100, 20)    # potencial ofensivo 20, energía 100, potencial defensivo 20
  guerrero.atacar(oponente)
  oponente.atacar(guerrero)
  guerrero.energia
end

atila = Guerrero.new                      # 20, 100, 10: los defaults
puts atila.energia                        # => 100
puts hacer_combatir(atila)                # => 90     ← perdió 10: su ataque no pasó (20 no supera 20), el del oponente sí
                                          #    (20 > 10, daño 10). Pero ¿qué mensajes recibió atila para llegar ahí?
```

`atila` no sabe nada de "guardar qué mensajes me mandaron": recibió los mensajes, cambió su estado, y ya. Lo que queremos es **la lista exacta de mensajes que recibió `atila` durante el combate**, con sus parámetros, en orden. Y lo queremos **sin tocar `Guerrero`, sin tocar `hacer_combatir`**: no sabemos qué hace adentro, y no queremos abrir ninguna clase para averiguarlo.

La idea: en vez de pasarle `atila` a `hacer_combatir`, pasarle **otro objeto que envuelva a `atila`**. Ese objeto recibe todos los mensajes que iban para `atila`, anota cada uno, y después se lo manda a `atila`. `hacer_combatir` no se entera de que hay un intermediario.

Para eso el intermediario tiene que **recibir cualquier mensaje**: `atacar`, `descansar`, `energia`, y cualquiera que le agreguen a `Guerrero` mañana. Es el caso ideal para `method_missing`: un objeto que **no entiende nada**, y por eso le llega todo.

---

## 2. Construir el registrador 🔴

De a un paso, viendo dónde revienta cada versión.

**Intento 1: la clase vacía.**

```ruby
class RegistradorDeMensajes
end

hacer_combatir(RegistradorDeMensajes.new)
# => NoMethodError: undefined method `atacar' for an instance of RegistradorDeMensajes
```

Obvio: `hacer_combatir` le manda `atacar` y no lo entiende. Además, para reenviar mensajes a `atila` tiene que **conocer** a `atila`: un `initialize` que se guarde el objeto envuelto.

**Intento 2, el que anda: conoce al objeto, atiende cualquier mensaje, anota y reenvía.**

```ruby
class RegistradorDeMensajes
  attr_reader :mensajes_recibidos                              # solo getter: la lista se consulta desde afuera, no se reasigna

  def initialize(objeto)
    @objeto = objeto                                           # el objeto de verdad, al que vamos a reenviar todo
    @mensajes_recibidos = []                                   # acá se acumulan los mensajes, en orden
  end

  private def method_missing(method, *args)                    # cae acá TODO lo que este objeto no entiende (o sea, casi todo)
    @mensajes_recibidos << { mensaje: method, parametros: args }   # 1) anotar: un hash por mensaje
    @objeto.send(method, *args)                                # 2) reenviar tal cual, y devolver lo que devuelva el objeto
  end
end
```

Dos cosas de sintaxis:

- **`<<`** sobre un array agrega al final ("empujá esto adentro"). **`{ mensaje: method, parametros: args }`** es un hash: un diccionario con dos claves, el nombre del mensaje y sus parámetros. Podríamos haber creado una clase para representar "un mensaje recibido"; para esto alcanza con el hash.
- **`send(method, *args)`**: `send` manda el mensaje cuyo nombre viene en `method`. El `*args` acá hace **lo contrario** que en la firma: en la firma juntó los argumentos en un array; en la llamada **desparrama** el array en argumentos sueltos. Lo que entró junto, sale junto: si el mensaje original traía dos parámetros, `atila` recibe dos parámetros.

```
   hacer_combatir manda:   registrador.atacar(oponente)
                                   │
                                   ▼  lookup falla → Ruby manda
                           registrador.method_missing(:atacar, oponente)      args = [oponente]   ← el * JUNTA
                                   │
                                   ▼  anota { mensaje: :atacar, parametros: [oponente] }, y reenvía:
                           atila.send(:atacar, *args)  →  atila.atacar(oponente)                 ← el * DESPARRAMA
```

Ahora sí, en vez de `atila`, le pasamos a `hacer_combatir` un registrador que envuelve a `atila`:

```ruby
atila = Guerrero.new
registrador = RegistradorDeMensajes.new(atila)     # el registrador se pone adelante de atila

puts atila.energia                                 # => 100
hacer_combatir(registrador)                        # el combate ocurre a través del registrador
puts atila.energia                                 # => 90     ← atila quedó igual que si hubiera peleado él: los mensajes le llegaron
puts registrador.mensajes_recibidos
# Resultado esperado (un hash por línea):
# {:mensaje=>:atacar, :parametros=>[#<Guerrero:0x… @potencial_ofensivo=20, @energia=100, @potencial_defensivo=20>]}
# {:mensaje=>:potencial_defensivo, :parametros=>[]}
# {:mensaje=>:potencial_defensivo, :parametros=>[]}
# {:mensaje=>:sufri_danio, :parametros=>[10]}
# {:mensaje=>:energia, :parametros=>[]}
```

Leé esa lista con atención. `hacer_combatir` escribió dos envíos al guerrero: `atacar` y `energia`. Pero la lista tiene cinco mensajes. **Los dos `potencial_defensivo` y el `sufri_danio` nunca los escribiste**: los mandó el oponente, desde adentro de su `atacar`, que pregunta el potencial defensivo del que ataca (una vez para decidir si el ataque pasa, otra para calcular el daño) y después le manda `sufri_danio`. Nunca abriste `Atacante`, y aun así ves exactamente qué le pidió al guerrero, con qué parámetros y en qué orden. Eso es lo que no podías conseguir de ninguna otra forma.

**¿CÓMO FUNCIONA?** Con el segundo mensaje de la lista:

1. `oponente.atacar(registrador)` ejecuta el `atacar` de `Atacante`, que hace `un_defensor.potencial_defensivo`. Ese `un_defensor` es el registrador.
2. Lookup de `potencial_defensivo` en `RegistradorDeMensajes` → `Object` → `Kernel` → `BasicObject`. No está en ninguno.
3. Ruby manda `registrador.method_missing(:potencial_defensivo)` con `args = []`.
4. Nuestro `method_missing` agrega `{ mensaje: :potencial_defensivo, parametros: [] }` a la lista y hace `atila.send(:potencial_defensivo)`.
5. `atila` responde `10`. `method_missing` devuelve ese `10`, así que para el oponente `un_defensor.potencial_defensivo` vale `10`. Ni se enteró de que había un intermediario.

Fijate que esta parte no tiene casi nada de metaprogramación. Es programación común: una lista, un hash, un `send`. Lo único "raro" es que el punto de entrada es `method_missing`.

---

## 3. Lo que le falta: `respond_to_missing?` 🔴

Contrato de la Parte 1: redefiniste `method_missing`, redefinís `respond_to_missing?`. ¿Con qué criterio? El registrador **responde lo que `atila` responde**, ni más ni menos. Y eso no lo decide el registrador: lo decide `atila`. Entonces la pregunta se delega:

```ruby
class RegistradorDeMensajes
  def respond_to_missing?(method, include_private = false)
    @objeto.respond_to?(method, include_private)       # ¿atila lo responde? entonces yo también
  end
end

p registrador.respond_to?(:atacar)        # => true     ← antes daba false
p registrador.respond_to?(:volar)         # => false    ← atila tampoco
```

---

## 4. Los mensajes que se escapan 🔴

El registrador anota y delega `atacar`, `descansar`, `energia`. **Pero no todos los mensajes.** ¿Cuáles no?

Solo delega lo que llega a `method_missing`, y a `method_missing` solo llega lo que el lookup **no encontró**. El registrador es una instancia de `RegistradorDeMensajes`, que hereda de `Object`, y `Object` (vía `Kernel`) trae puestos unos cuantos métodos: `is_a?`, `to_s`, `class`, `inspect`, y alrededor de cuarenta más. **Esos el lookup los encuentra**, así que se responden con la versión del registrador y nunca se delegan:

```ruby
p atila.is_a?(Guerrero)             # => true     (is_a?: ¿es instancia de Guerrero, o de una subclase?)
p registrador.is_a?(Guerrero)       # => false                        ← ⚠️ lo contestó el registrador, no atila
puts atila.to_s                     # => #<Guerrero:0x…>              (to_s: el objeto como texto; es lo que puts muestra)
puts registrador.to_s               # => #<RegistradorDeMensajes:0x…> ← ídem
p registrador.mensajes_recibidos.size   # => 5                        ← y no quedaron anotados: no pasaron por method_missing
```

Acá no parece grave. Pero pensá en el uso: `hacer_combatir` recibe "un guerrero" y le manda cosas de guerrero. Si en algún punto necesita `to_s`, o pregunta `is_a?(Guerrero)` para decidir algo, no obtiene la respuesta de `atila` sino la del registrador. Y queremos exactamente lo contrario: que este objeto sea **lo más polimórfico posible** con la cosa que reemplaza. Lo usamos para interceptar lo que recibiría otro, y queremos que se comporte como ese otro **en todo lo que se pueda**. Si no, se rompe la sustitución.

🎯 **Pattern en contexto: Proxy (familia "un objeto adelante de otro").**
**Qué es:** un objeto que se pone adelante de otro, recibe los mensajes que iban para él, agrega algo en el camino (anotar, controlar, retrasar, adaptar) y se los reenvía. Es una familia entera de patrones que difieren en *qué agregan*: **Proxy, Decorator, Interceptor, Adapter, Embajador**… todos con la misma estructura.
**Por qué lo usamos:** para agregar comportamiento (acá, registrar) **sin modificar la clase original ni el código que la usa**. `Guerrero` y `hacer_combatir` quedan intactos.
**Dónde lo ves en este código:** `RegistradorDeMensajes` es el proxy; `@objeto` es el objeto envuelto; `method_missing` + `send` es el reenvío; la lista es "lo que agrega".
**Analogía:** un secretario que anota cada llamado antes de pasártelo. Vos atendés igual; él tiene el registro.
**❌ Sin `method_missing`:** un método por cada mensaje de `Guerrero`, que anota y reenvía, y que hay que mantener a mano: el día que `Guerrero` gane un método, el registrador queda incompleto sin que nadie avise.
**✅ Con `method_missing`:** un solo método reenvía todo, incluidos los mensajes que todavía no existen.

---

## 5. Corolario: `method_missing` extiende interfaces, nunca las pisa 🔴

Lo de la sección 4 es una limitación general, no un detalle del registrador, y conviene enunciarla bien porque define para qué sirve la herramienta:

> **`method_missing` sirve para extender una interfaz con mensajes que todavía no están. Nunca para pisar un mensaje que ya existe.** Si el objeto ya tiene el método (propio, heredado o de un mixin), el lookup lo encuentra antes de fallar, y `method_missing` no se entera.

No podés "overridear" lógica con `method_missing`. El override, en Ruby y en casi todo lenguaje, lo tiene la clase o el objeto concreto: quien está más abajo en la cadena tiene la última palabra, y `method_missing` está al final de la cadena, no al principio.

> 🕳️ **Madriguera — `Proxy` en JavaScript**
> Hay muy pocas tecnologías con una construcción que permita interceptar *todos* los mensajes, incluidos los que el objeto ya entiende. La única industrial es el `Proxy` de JavaScript (ES6): un objeto que se pone adelante de otro y maneja absolutamente todo, con poder de override. Tiene que venir implementado en la máquina virtual; no se puede simular. Ni los *extension methods* ni las demás formas de extender interfaces de los lenguajes comunes te dejan pisar.
> *Volvé al camino — esto se profundiza aparte, otro día.*

Consecuencia para escribir un `method_missing`: **tenés que tener muy claro el mapa de qué mensajes no van a pasar por ahí**, porque los hereda tu objeto. Todo lo que tu clase trae de `Object` es una trampa potencial: te parece que "todo" pasa por `method_missing`, y `to_s` no.

---

## 6. Dos salidas, y de dónde sale `BasicObject` 🔴

Quiero que **también** `is_a?` y `to_s` se registren y se deleguen. ¿Cómo? Es la misma respuesta de la Parte 1, y cuesta verla en la niebla: cuando viene el quilombo, volvé al terreno conocido.

**Salida 1: pisar esos métodos, uno por uno.** `is_a?` y `to_s` son métodos comunes de `Object`. Los redefinís en el registrador para que anoten y deleguen, como hace `method_missing`. Anda. El problema es que son cuarenta y pico, y volviste al ❌ del pattern: enumerar a mano.

**Salida 2: que el registrador entienda menos mensajes.** O ninguno. Si el registrador **no hereda nada de `Object`**, casi nada se encuentra por lookup, y casi todo cae en `method_missing`. Ruby tiene una clase para exactamente esto: `BasicObject`, la que está arriba de `Object` y trae solo lo indispensable (`==`, `equal?`, `!`, `__send__` y un par más), sin `Kernel`.

Es una decisión de diseño del lenguaje que se entiende recién acá: `Object` existe con cuarenta métodos porque son cómodos; `BasicObject` existe con casi ninguno para cuando querés un objeto que reenvíe **todo**.

```
   Salida 1                                   Salida 2
   RegistradorDeMensajes < Object             RegistradorDeMensajes < BasicObject
   ┌───────────────────────┐                  ┌───────────────────────┐
   │ method_missing        │                  │ method_missing        │
   │ is_a?   (pisado)      │                  │                       │
   │ to_s    (pisado)      │                  │  nada más: todo cae   │
   │ class   (pisado)      │                  │  en method_missing    │
   │ … ×40                 │                  │                       │
   └───────────────────────┘                  └───────────────────────┘
```

La versión completa, en un archivo nuevo (Ruby no deja cambiarle la superclase a una clase que ya está definida en la misma sesión: `TypeError: superclass mismatch`):

```ruby
require_relative 'age'

def hacer_combatir(guerrero)
  oponente = Guerrero.new(20, 100, 20)
  guerrero.atacar(oponente)
  oponente.atacar(guerrero)
  guerrero.energia
end

class RegistradorDeMensajes < BasicObject                    # ← el único cambio: hereda de BasicObject, no de Object
  attr_reader :mensajes_recibidos

  def initialize(objeto)
    @objeto = objeto
    @mensajes_recibidos = []
  end

  private def method_missing(method, *args)
    @mensajes_recibidos << { mensaje: method, parametros: args }
    @objeto.send(method, *args)
  end

  def respond_to_missing?(method, include_private = false)
    @objeto.respond_to?(method, include_private)
  end
end

atila = Guerrero.new
registrador = RegistradorDeMensajes.new(atila)
hacer_combatir(registrador)

p registrador.is_a?(Guerrero)        # => true                  ← ahora lo contesta atila
puts registrador.to_s                # => #<Guerrero:0x…>       ← indistinguible de atila desde afuera
puts registrador.mensajes_recibidos.size   # => 7               ← los 5 del combate + is_a? + to_s: también quedaron anotados
```

Ahora el registrador es **transparente**: `is_a?`, `to_s` y cualquier otro mensaje van a `method_missing` y de ahí a `atila`, y quedan registrados. Ya no los entiende por sí mismo, porque no están.

Dos cosas a tener en cuenta con `BasicObject`:

- **El costo es total.** Adentro de una subclase de `BasicObject` no tenés `puts`, `p`, `raise` ni nada de `Kernel` sin receptor: no está incluido. Si tu proxy necesita imprimir algo, tenés que mandárselo a alguien explícitamente: `::Kernel.puts(...)` (el `::` adelante dice "la constante `Kernel` de nivel superior"; hace falta porque una subclase de `BasicObject` tampoco ve las constantes que ve `Object`). Para un registrador que solo anota y reenvía, no hace falta nada de eso, y por eso es la elección correcta.
- **Hay que decidir qué casos funcionan y cuáles no.** Ninguna de las dos salidas es "la" solución: una enumera, la otra renuncia a todo `Object`. Elegís según lo que el objeto tiene que hacer.

> 🎓 **Para el parcial, si te preguntan:** *¿Por qué `RegistradorDeMensajes` hereda de `BasicObject` y no de `Object`?*
> Porque `Object` incluye `Kernel`, que define `is_a?`, `to_s` y unos cuarenta métodos más; el lookup los encuentra antes de llegar a `method_missing`, así que el registrador los respondería por sí mismo en vez de reenviarlos al objeto envuelto. `BasicObject` casi no tiene métodos: casi todo cae en `method_missing` y el proxy queda transparente. La alternativa es pisar cada uno de esos métodos a mano.

---

## 7. El caso mínimo: un objeto que se traga todo 🟡

Hay un patrón entero basado en esta misma conducta. Un objeto que **entiende todos los mensajes** y, no importa cuál, **se responde a sí mismo**:

```ruby
class DeafObject < BasicObject                # "objeto sordo"
  def method_missing(name, *args)
    self                                      # cualquier mensaje: "sí, sí" y devuelvo el mismo objeto
  end
  def respond_to_missing?(name, include_private)
    true                                      # dice que entiende todo
  end
end

d = DeafObject.new
resultado = d.atacar(1).descansar.lo_que_sea  # una cadena entera de mensajes, y nada explota
p resultado.equal?(d)                         # => true     ← cada mensaje devolvió el mismo objeto
```

`equal?` pregunta "¿son el mismo objeto?" (identidad, no valor); está en `BasicObject`, por eso `d` lo entiende.

**Para qué sirve:** para *mockear* o neutralizar. Tenés un método que exige un colaborador que, cuando le mandás mensajes, causa efectos. Ponés un `DeafObject` en su lugar y toda la ejecución sobre ese colaborador queda neutralizada: recibe todo, no hace nada, nunca falla.

> **Mock:** objeto falso que se pone en lugar de uno real durante una prueba, para aislar lo que se quiere probar.

**Por qué es peligroso:** es absolutamente **indebuggeable**. Nada falla nunca, así que nada te avisa que algo anda mal. Descubrir que existe `method_missing` porque te cruzaste con un objeto así en un sistema real es un evento canónico de la industria. Variante peor: un proxy con `method_missing` **sin** `respond_to_missing?`; un código que preguntaba "¿podés responder esto?" antes de mandar, recibía `false` de un objeto que en realidad sí respondía, y una tarde entera de debugging para descubrir que "el mensaje estaba ahí escrito" pero el objeto no era el que parecía.

---

## 8. Cuándo sí, cuándo no 🟡

`method_missing` funciona bárbaro. El problema no es el código: es que **jode con el modelo que la gente tiene en la cabeza** de cómo se comporta un objeto. Cualquiera que venga de otro lenguaje (y ustedes mismos hasta la clase pasada) asume que los objetos entienden los mensajes que vienen de sus clases. Con un `method_missing` en la jerarquía, eso deja de ser verdad, y quien no lo sepa **no tiene chance** de entender qué está pasando. Por eso es disruptivo.

**Cuándo sí:** cuando la lista de mensajes es **abierta o no la controlás**. Un proxy, un decorator, un registrador, un mock: objetos que tienen que reenviar "lo que sea que venga", incluidos mensajes que todavía no existen. O una familia de mensajes por convención de nombre (`comerse_*`) cuando de verdad es más expresiva que definir quince métodos casi iguales.

**Cuándo no:** cuando podés escribir el `def`. Un método definido se lee, se busca, aparece en `methods`, lo entiende el autocompletado y lo puede investigar cualquiera con las herramientas de la clase pasada. Uno dinámico se descubre. Si tenés la opción entre `method_missing` y otro camino, en general vas a preferir el otro.

**El precio, en concreto** (todo viene de las Partes 1 y 2):

- La interfaz se vuelve **invisible e infinita**: `methods` no la lista, no entra en un diagrama de clases.
- **Dos lookups** por cada mensaje atendido así.
- Obligaciones que si olvidás rompen cosas lejos: `super` (si no, errores silenciosos) y `respond_to_missing?` (si no, `respond_to?` miente).
- **Los mensajes que tu objeto ya entiende no pasan por ahí**, y hay que saber cuáles son.

Y hay un costo más grande que ninguno de esos, que aparece cuando lo que construís **se tiene que integrar con otra cosa**. Dos frameworks no son incompatibles porque se peleen a propósito: son incompatibles porque los dos hacen magia metiéndose en el mismo mecanismo del lenguaje para cosas distintas. Si vos pisás `method_missing` y de pronto todos los objetos entienden cosas que vienen de otro lado, el que tenía en la cabeza "los objetos entienden lo que dicen sus clases" está perdido. Es la misma razón por la que los mods de un juego vienen con una lista de "compatible con tal, incompatible con tal otro": están metiendo cosas donde no se suponía que estuvieran, y cuando dos hacen eso, chocan.

**¿Quiere decir que hay que pensar en todos los recovecos siempre?** En principio, sí. Cuando resolvés un problema en un dominio propio, donde controlás qué se hace y qué no, podés relajar. Cuando hacés una herramienta genérica que otros van a integrar, esto está en el centro. Y la pregunta que se instala a partir de acá, para cada decisión de diseño, ya no es "encontremos una manera que funcione". Es: **¿cuáles son todas las maneras de hacer esto, qué precio se paga por cada una, qué garantías estoy asumiendo, y qué incompatibilidades produce?** Con las herramientas de esta unidad vas a tener tres docenas de maneras de hacer lo mismo, y muchas no se diferencian en velocidad ni en dificultad: se diferencian en que, si elegís esa, el programa después no lo puede extender ninguna otra herramienta.

Última cosa, para no irse al otro extremo. A medida que entiendas estas herramientas, vas a tender a asumir el peor caso ante cualquier cosa rara: "un objeto entendió algo que no debería → seguro hay un `method_missing` escondido". No hay que entrar en pánico. No todo es rayos cósmicos cambiando bits. Para eso están las herramientas de introspección: `methods`, `respond_to?`, `method(:x).owner`, `ancestors`. Navegar, inspeccionar y descular es mucho mejor que asumir el peor camino.

> 🎓 **Para el parcial, si te preguntan:** *¿Cuándo usarías `method_missing` y cuándo no?*
> Cuando la lista de mensajes a atender es abierta o no la controlo (proxies, decorators, registradores, mocks) o cuando una convención de nombres expresa mejor una familia de mensajes que muchos `def` iguales. No cuando puedo escribir el `def`: un método definido es visible, buscable e introspectable; uno dinámico hace la interfaz infinita e invisible, cuesta dos lookups, y obliga a `super` y `respond_to_missing?`. Además, nunca sirve para pisar un mensaje que ya existe.

---

## Checkpoint de la Parte 2

Sin respuestas.

1. `hacer_combatir` escribió `atacar` y `energia`, pero el registrador anotó cinco mensajes. Explicá de dónde salen los otros tres y por qué el registrador los vio.
2. Explicá qué hace `*args` en la firma de `method_missing` y qué hace en `send(method, *args)`. ¿Qué pasaría si en el `send` olvidás el asterisco?
3. ¿Con qué criterio implementaste `respond_to_missing?` en el registrador, y por qué ese criterio no lo decide el registrador?
4. Con `RegistradorDeMensajes < Object`, `registrador.is_a?(Guerrero)` da `false`. Explicá por qué `is_a?` no llega a `method_missing` y dónde vive `is_a?`.
5. Enunciá el corolario de la sección 5 con tus palabras y dá un ejemplo concreto de algo que `method_missing` **no** puede hacer.
6. Nombrá las dos salidas para que `to_s` también se registre. ¿Qué gana y qué paga cada una?
7. ¿Qué tiene `BasicObject` que no tiene `Object`, o mejor dicho, qué *no* tiene? ¿Qué no podés hacer adentro de una subclase de `BasicObject` sin receptor explícito?
8. Un compañero propone un `DeafObject` para reemplazar al oponente en los tests del TP. ¿Qué gana, qué riesgo corre, y qué pieza tiene que tener sí o sí ese objeto?
9. Aparece este requerimiento: "quiero que un guerrero, cuando le mandan un mensaje que no entiende, lo reintente contra su espada". ¿Es un caso para `method_missing`? ¿Dónde lo pondrías, y qué dos cosas más tenés que escribir?
10. Aparece este otro: "quiero cambiar cómo se comporta `atacar` en todos los guerreros". ¿Sirve `method_missing`? ¿Por qué?

---

## Qué viene en la Parte 3

Cambiamos de tema y de ritmo. Hasta acá el objeto decidía qué hacer con un mensaje; ahora el problema es **el código en sí**: cómo se guarda un pedazo de código para ejecutarlo después, quién es `self` cuando lo ejecutás, y qué son de verdad esos `do … end` que venís usando con `each` desde la clase 1. Vas a ver que en Ruby un bloque **no es un objeto**, que `proc` lo convierte en uno, que todo mensaje puede recibir un bloque y casi todos lo ignoran, cómo se usa (`yield`, `&bloque`), en qué se diferencian un proc y una lambda, y un contador que recuerda una variable de un método que ya terminó.

**FIN DE LA PARTE 2**
