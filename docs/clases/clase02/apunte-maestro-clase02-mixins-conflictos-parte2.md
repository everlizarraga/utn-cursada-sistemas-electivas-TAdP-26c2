# 📘 APUNTE MAESTRO — clase02 · Mixins: resolución de conflictos
## Parte 2 — Conflictos, linearización y el rol de la clase

*Al terminar esta parte vas a poder mirar un modelo con mixins y decir qué método se ejecuta y por qué, dibujar su cadena de linearización, explicar qué cambia cuando en vez de mixins hay traits, y responder qué le queda por hacer a la clase.*

Esta parte completa las cuatro filas de la tabla que quedaron pendientes en la Parte 1: resolución de conflictos, runtime, `super` y rol de la clase.

---

## 1. 🔴 Qué es un conflicto (y qué no lo es)

### El caso que ya conocés

Esto lo viste mil veces y nunca lo llamaste conflicto:

```ruby
class Superclase
  def m
    "m de la superclase"               # el método "rojo"
  end
end

class Clase < Superclase
  def m
    "m de la clase"                    # el método "azul"
  end
end

# ¿CÓMO FUNCIONA?
Clase.new.m
# Resultado esperado: "m de la clase"
```

La respuesta te sale automática: se usa el de `Clase`, porque está más cerca. Pero frená un segundo antes de la respuesta. Cuando una instancia de `Clase` recibe el mensaje `m`, **tiene dos métodos disponibles** para responderlo: el rojo y el azul. Los dos son alcanzables, sin ninguna cosa rara. Eso, y solo eso, es un **conflicto**: una ambigüedad. Un programa no puede tener ambigüedad; tiene que ser determinístico. Alguien tiene que decidir.

### El conflicto no es la herramienta que lo resuelve

Lo que aprendiste no fue el conflicto: aprendiste la **solución que funcionó**. Se llama sobreescritura, y es una decisión consciente, tomada por el lenguaje: *"cuando ponés `m` acá y tenés `m` arriba, gana el de abajo y el lookup se interrumpe ahí"*. Se probó, funcionó bien, se automatizó, se le puso nombre y se lo llamó *feature*. Todos los lenguajes de objetos la copiaron porque encaja perfecto con la idea de que las clases de abajo **refinan** a las de arriba.

Pero fijate que es **arbitrario**. Nada en la naturaleza dice que gana el de abajo. Una tecnología podría decidir que gana el de arriba: "porque está más arriba, es más importante". O que el de arriba tiene que *autorizar* al de abajo. Son ideas razonables que nadie eligió porque la otra resultó más práctica. Y hay tecnologías que te dan mecanismos para saltear la decisión: `super`, o un llamado nominal que apunta a un método particular de una clase particular. Pero para cuando usás eso **ya estás diseñando**: el conflicto ya se resolvió, el proceso automático ya eligió.

> **Quedate con esta distinción:** el conflicto es la ambigüedad. La sobreescritura es *una* forma automática de resolverla. La herencia simple te ocultó el conflicto porque te dio la resolución junto con el problema.

---

## 2. 🔴 El rombo, o por qué la herencia múltiple se trabó

### Del árbol al grafo

En herencia simple los conflictos son fáciles porque **la jerarquía es un árbol**, y un árbol garantiza una línea: desde cualquier hoja hasta la raíz hay un único camino. Las cosas ya vienen ordenadas; solo hay que decidir en qué dirección recorrer.

Ahora agregá una segunda superclase:

```
              ┌───┐
              │ A │  m()  ← rojo
              └───┘
              ▲   ▲
             ╱     ╲
        ┌───┐       ┌───┐
        │ B │ m()   │ C │ m()
        └───┘ azul  └───┘ verde
            ▲       ▲
             ╲     ╱
              ┌───┐
              │ D │
              └───┘

        D.new.m()   → ¿cuál?
```

`A` define `m`. `B` y `C` heredan de `A` y cada una redefine `m`. `D` hereda de las dos y no define nada. Cuando una instancia de `D` recibe `m`, tiene **tres** métodos disponibles y ninguna regla que los ordene: hay dos caminos para llegar a `A`, y un ciclo cerrado. **Ya no tenés un árbol, tenés un grafo, y la línea no está garantizada por nada.**

Este dibujo se llama *el problema del rombo* (o del diamante), y hay variantes según qué problema querés contar: cómo se construye el estado, cómo se crean las instancias, cuál `m` corresponde. La vas a encontrar en artículos viejos como demostración de que la herencia múltiple es imposible.

### Cómo esto paralizó todo

**No era imposible.** C++ ya la tenía. Lo que pasaba en C++ era que a veces se usaba uno, a veces el otro, y a veces se rompía: estaba intentando atender muchos niveles de abstracción al mismo tiempo con herramientas muy complejas. No fue un éxito. Y las tecnologías que vinieron después miraron eso y se quedaron con *"herencia simple, porque la otra no se puede"*. Era una pelea perdida; no valía la pena subirse.

Con el tiempo, el problema "insalvable" se resolvió sin descubrir nada: **simplemente nos ordenamos un poco.** Ese ordenamiento tiene nombre y es el tema de la sección siguiente.

### Las dos líneas que nadie discute

Antes de la regla, hay que aclarar en qué terreno se da la discusión. Imaginate el caso más cargado posible: una clase que incluye tres mixins, cada uno con `m`; ella misma define `m`; y hereda de una superclase que también tiene `m`. Cinco `m` disponibles.

Parece que se complicó, pero **el problema es el mismo**, y necesitás una regla que resuelva todos los casos, no caso por caso. Porque el lookup corre miles de veces por segundo: tiene que ser simple para poder ser rápido, y muchas decisiones sobre qué features puede tener un lenguaje se toman mirando cuánto se puede complicar ese proceso.

Por suerte hay dos líneas que casi nadie cuestiona:

- **Lo local va siempre primero.** Si la propia clase define `m`, se usa ese. Es la última palabra que tenés para pisar cualquier comportamiento heredado.
- **La herencia va siempre última.** Los mixins vienen a *complementar* la herencia simple, no a reemplazarla (Parte 1, Sección 7): se montan encima, así que se consultan antes.

Con eso, la discusión real queda acotada a **las entidades que están al mismo nivel conceptual**: los mixins entre sí. Y ahí las dos posiciones son razonables. Supongamos que `C` incluye `M` y `N`, que `N` hereda su `m` de otro mixin `O`, y que `M` lo redefine:

- *"Corresponde el `m` de `M`: es el más cercano, y `M` decidió explícitamente que no valía lo de `O`."*
- *"Corresponde el `m` de `N`: `C` dijo que era `N` **después** de decir que era `M`, y esa también es una voluntad del usuario: yo soy más `N` que `M`."*

Ambos mundos son razonables. No se puede satisfacer a los dos. Hay que elegir uno, y **la elección es arbitraria, pero tiene que ser consistente** —que no es lo mismo que random. Se elige, se documenta, y de ahí en adelante programás como siempre.

---

## 3. 🔴 Linearización: la regla general

### Qué es

**Linearizar es tomar el grafo y ponerlo en una línea.** Un orden en el que vas a visitar cada entidad, igual al que tenías con el árbol. Es el paso extra que los mixins agregan a la herencia simple, y es lo que permite que los conflictos se resuelvan **automáticamente**: no porque desaparezcan, sino porque hay una regla que siempre elige.

Cada tecnología define su forma de linearizar, y en la práctica la gran mayoría copia a la que ya funciona. Vas a aprender cómo linealiza la tecnología en la que estás, y listo.

### La regla de Ruby (y de casi todos)

Tomá el caso general. Una clase `C` incluye dos mixins, `M1` y `M2`. Los dos incluyen a su vez un mixin común, `M0`. Y `C` hereda de una superclase `S`.

```
        ┌────┐      ┌────┐
        │ M1 │      │ M2 │
        └────┘      └────┘
           ▲▲  ╲    ▲▲  ╲
           ││   ╲   ││   ╲        ┌────┐
           ││    ╲──┼┼────╲──────►│ M0 │   (M1 y M2 incluyen M0)
           ││       ││            └────┘
        ┌──┴┴───────┴┴──┐
        │       C       │        C incluye M2 y después M1
        └───────┬───────┘
                │
                ▼
             ┌─────┐
             │  S  │
             └─────┘
```

La regla tiene tres pasos, y cada entidad los aplica **localmente**:

1. **Primero yo.** `C` se pone a sí misma.
2. **Después mis mixins, en orden de prioridad.** Cada uno viene con **su propia linearización completa**: le pido a `M1` "dame tu linearización", `M1` me devuelve `M1, M0`; le pido a `M2`, me devuelve `M2, M0`. Es recursivo.
3. **Después mi superclase**, que hace exactamente el mismo ejercicio con sus propios mixins y su propia superclase.

Resultado, antes de limpiar:

```
   C → M1 → M0 → M2 → M0 → S → ...
```

Si ignorás el tramo del medio —que es lo mismo que decir *"si no usás mixins"*— lo que queda es `C → S → ...`: la herencia simple de siempre. Cada clase resuelve localmente su porción de mixins, y eso garantiza que **la jerarquía de herencia nunca se toca**: `superclass` de `C` sigue siendo `S`, no un mixin. Solo el lookup pasa por los mixins.

### El elefante: `M0` está dos veces

Repetido no es un error —sigue siendo una línea y se puede recorrer— pero es un desperdicio y una molestia para diseñar. Hay dos formas de limpiarlo:

- **Preservar el primero** → `C → M1 → M0 → M2 → S`
- **Preservar el último** → `C → M1 → M2 → M0 → S`

Preservar uno del medio sería una locura: nadie podría identificarlo. Para estas resoluciones se busca algo indiscutible.

**Ruby, y la gran mayoría de las tecnologías con mixins, preserva el último.** Se tacha la primera aparición y sobrevive la del final. Esto va a ser **muy importante**: abre las dos grandes ramas de uso de mixins y habilita patrones que de otra manera no podrías armar. En la Parte 4 vas a ver por qué.

> ⚠️ **Advertencia.** Memorizar exactamente qué hace Ruby con cada caso raro es mala estrategia: te priva de diseñar por la naturaleza, que importa más. La pregunta útil es *"¿vos sos más esto o más esto otro?"*, y confiar en que si cableaste más o menos bien, la resolución automática hace el resto. **Para el examen:** la regla son los tres pasos de arriba, y ante repetidos se preserva el último.

### La cadena real, verificable

Ruby te deja ver la linearización de cualquier clase con `ancestors`:

```ruby
class Guerrero
  include Atacante
  include Defensor
end

Guerrero.ancestors
# Resultado esperado:
# [Guerrero, Defensor, Atacante, Object, Kernel, BasicObject]
#     ↑          ↑         ↑        ↑      ↑         ↑
#     yo      último    primer   super-  módulo    raíz de
#            include   include   clase   base      todo
#                                       de Ruby
```

`Kernel` y `BasicObject` son parte del piso de Ruby: `Object` incluye `Kernel` y hereda de `BasicObject`. Siempre están al fondo; no los toques y no los mires. Lo que importa es el tramo `Guerrero → Defensor → Atacante → Object`: la clase, sus mixins, la superclase.

### `include` se lee de abajo hacia arriba

Mirá la cadena de arriba: `Defensor`, que fue incluido **último**, quedó **primero** en el lookup. Esto no es un capricho: es Ruby siendo consistente consigo mismo.

Ruby nació como lenguaje de scripting y es **profundamente destructivo**: cada línea que ejecutás trabaja sobre el contexto que dejó la anterior, y cada definición nueva **pisa** lo que había. Cuando escribís `class Guerrero` no estás *definiendo* la clase: la estás *abriendo*. Podés abrirla tantas veces como quieras, en cualquier archivo, y cada apertura se suma a las anteriores; la que se carga última pisa a las demás.

> 🕳️ **Madriguera — Open classes**
> Es la razón por la que en Ruby podés abrir `String` y agregarle un método. Se ve en serio en la clase 3, con metaprogramación. Por ahora alcanza con saber que `class` no crea: agrega.
> *Volvé al camino.*

Con ese mismo criterio, `include` también es destructivo: **lo que se incluye después pisa lo que se incluyó antes.** Cualquier método que `Atacante` tenga y `Defensor` también, va a ser pisado cuando incluís `Defensor`. Por eso la lectura correcta es de abajo hacia arriba: lo último tiene mayor prioridad, igual que un `def` escrito debajo de los `include` pisa a los dos.

```ruby
class Guerrero
  include Atacante
  include Defensor
  # Lookup: Guerrero -> Defensor -> Atacante -> Object
  #                     ↑ leído de ABAJO hacia arriba: el último include gana
  # ✗ Trampa: leerlo de arriba hacia abajo ("Guerrero -> Atacante -> Defensor")
  #   es la interpretación imperativa, y es exactamente al revés.
end
```

En la Parte 1 dibujamos las inclusiones con doble punta. Ahora hace falta un refinamiento: **tantas puntas de flecha como prioridad tenga la inclusión.** Cuantas más puntas, antes en la linearización. La herencia queda siempre con una sola punta porque siempre es la última. Es una notación propia de la cátedra, y la vas a ver en todos los diagramas de acá en adelante.

En otras tecnologías la sintaxis es distinta pero la idea es la misma. Donde la inclusión se escribe en una sola línea, como `class D extends C with B`, se lee **de derecha a izquierda**: `B` tiene más prioridad que `C`. La linearización del rombo de la Sección 2, con `D` incluyendo `C` y luego `B`, queda `D → B → A → C → A`, se tacha la primera `A`, y resulta `D → B → C → A`.

---

## 4. 🔴 Lo arbitrario hoy, y lo que cuesta cambiarlo mañana

Volvé a `Guerrero`. Incluye `Atacante` y después `Defensor`: es *más defensor que atacante*. ¿Por qué en ese orden? **Por ninguna razón.** Hoy no hay ningún conflicto entre los dos mixins, así que el orden no cambia nada.

Ese es el problema. **Cada vez que incluís dos mixins estás obligado a tomar una decisión que no estás preparado para tomar**, porque la herramienta no tiene forma de decir "por ahora no me importa cuál va primero". Podés dejar un comentario. Pero el día que aparezca un conflicto que se resuelva bien con el orden que quedó, nadie va a volver a borrar el comentario.

Y cambiarlo después no es gratis:

- Si el orden estaba puesto sin razón, con comentario y todo, lo das vuelta, corrés los tests, y listo.
- Si no, tenés que agarrar **toda la jerarquía de mixins** y ver qué conflictos se están resolviendo hoy hacia un lado. Cualquier conflicto que encuentres es un comportamiento que cambia. Es un proceso automatizable, pero hay que hacerlo.
- Si aparecen conflictos, lo que viene es un **refactor**: o tenías un mixin demasiado grande y hay que partirlo, o caíste en el caso raro de una entidad que quiere resolver una cosa para un lado y otra para el otro.

**Cambiar el orden de inclusión es un cambio mayor**, tan drástico como cambiar de qué clase heredás. En versionado semántico —la convención de numerar versiones como `mayor.menor.parche`— esto sube el primer número: cualquiera que haya construido sobre tu clase asumiendo esa jerarquía tiene ahora el código roto, y no de forma trivial, porque pudo haber abierto tu clase y agregado cosas contando con que se heredaran de cierta forma.

> **Para el diseño:** cuando el orden no importe, dejalo documentado. Cuando importe, la pregunta es siempre la misma —*¿sos más una cosa o más la otra?*— y la respuesta tiene que salir del dominio, no del código.

---

## 5. 🔴 Traits: aplanado y resolución manual

### Los traits no linearizan

Los traits toman un camino que **no es alternativo** a la linearización sino directamente antagónico: **aplanan** (*flattening*). Aplanar quiere decir volcar toda la definición al modelo de runtime y que los traits **no sobrevivan a la ejecución**. Lo que hay en runtime es solo `C`, con el código que le correspondía copiado adentro. Los traits ya no están: quedaron planchados en cada una de las entidades que los usaron.

```
   Definición:            Runtime:
   ┌───┐   ┌───┐          ┌────┐
   │ B │   │ C │          │ D' │  ← una única clase, con los métodos
   └───┘   └───┘          └────┘    de B y C copiados adentro
     ▲▲     ▲▲                        (los traits no existen)
      ╲     ╱
      ┌───┐
      │ D │
      └───┘
```

Entonces, ¿cómo resuelven los traits el rombo? **¿Qué rombo?** En runtime no hay ninguno: está la jerarquía de herencia de siempre. Es muy parecido al copy-paste loco de la clase 1, pero automático y consistente. Por eso traits **no requiere tocar la máquina virtual**: solo hay que construir el aparato previo a la compilación que hace el copiado inteligente. Es más fácil de meter en un lenguaje.

Una aclaración, porque suele confundir: **la jerarquía de clases sí existe en runtime, siempre, en todos los lenguajes.** No podés eliminarla porque el lookup es dinámico: si perdés la jerarquía, no sabés qué método corresponde ni adónde va un `super`. Lo que se aplana son los traits, no las clases.

### Cómo resuelven los conflictos: no resolviéndolos

Si un trait tiene un conflicto, lo que te dice es: **tenés un conflicto, este código no compila.** Que también es una forma de resolverlo.

Vos tenés que resolverlo, y lo hacés al indicar cómo combinar: diciendo qué parte de cada trait querés. La granularidad es por método, así que podés elegir: *dame este trait, pero sacale este método*. Eso es el **álgebra de traits**: pensar la inclusión como una operación sobre la clase.

```
   class D uses C - #m + B
              ─── ──── ───
               │    │    └── sumá todo B
               │    └─────── quitale el método m a C
               └──────────── usá C
```

Ducasse presenta un álgebra formal y clásica, con todas las operaciones posicionadas. Pero **el álgebra no es lo esencial: lo esencial es lo manual.** Un álgebra puede ser mucho más simple —por ejemplo, sobreescribir el método con un llamado explícito a la implementación concreta que querés— y sigue siendo resolución manual.

Y una consecuencia del aplanado que hay que tener presente: **un método que viene de un trait tiene todo el peso de un método local de la clase.** Es literalmente lo mismo que si lo hubieras escrito ahí. Por eso si el trait trae `m` y vos también escribís `m`, el lenguaje te marca conflicto.

### La diferencia core

> **Mixins resuelve el problema por vos. Tu responsabilidad es entender cómo lo resuelve, para poner las cosas en el lugar correcto.**
> **Traits no lo resuelve. Tu responsabilidad es resolver cada conflicto que aparezca.**

Traits te da más control, y a cambio te da una responsabilidad mucho más grande: si empezás a tener demasiados conflictos, te vas a hartar de resolverlos.

---

## 6. 🔴 `super` en cada una

Esta fila de la tabla es la que más se subestima, y es la que más consecuencias de diseño tiene.

### En mixins: `super` va al siguiente de la lista

Parado dentro del código de `M`, escribís `super`. ¿Adónde va? **No a la superclase.** Va al **siguiente en la linearización**. Si la cadena es `C → M → N → O → S`, un `super` en `M` cae en `N`. Y fijate que `M` y `N` **no tienen ninguna conexión entre sí**: `M` no sabe que `N` existe.

```ruby
module M
  def m
    "M, y después " + super          # super: "el que venga atrás mío", sea quien sea
  end
end

module N
  def m
    "N, y después " + super
  end
end

module O
  def m
    "O"                               # no llama a super: acá termina
  end
end

class C
  include O
  include N
  include M                           # M queda primero: es el último incluido
end

# ¿CÓMO FUNCIONA?
C.ancestors                           # => [C, M, N, O, Object, Kernel, BasicObject]
C.new.m                               # C no tiene m → M#m → super → N#m → super → O#m
# Resultado esperado: "M, y después N, y después O"
```

Esto es una **herramienta de diseño** enorme: poder decir `super` y **dejar que otro te cablee quién viene atrás.** `M` no sabe quién continúa; solo sabe que alguien va a estar. La clase que lo incluye decide el orden, y con eso decide la secuencia de llamados. La Parte 4 se construye entera sobre esto.

### En traits: no hay `super` del trait

Los traits no existen en runtime. Entonces, ¿qué `super`? **No hay otro `super` que el de la herencia.** Si dentro de un trait escribís `super`, en la mayoría de las tecnologías te va a chillar: *"¿qué super?"*. Y si te lo acepta, lo que va a pasar es que ese método fue planchado dentro de la clase, y entonces `super` es la superclase de la clase. Es un `super` **jerárquico**.

Consecuencia: **perdés la capacidad de diseñar con `super` entre módulos.** Ese cableado dinámico de "vos hacé lo tuyo y llamá al siguiente" no existe con traits.

### El `super` nominal

Hay una tercera posibilidad que no es ni una ni otra: un `super` que apunta explícitamente a un módulo concreto, algo como `super<M>.m()`. Algunas tecnologías tipadas lo ofrecen; Ruby no lo tiene como sintaxis, aunque en la clase 3 vas a ver que se puede construir. Es resolución manual con un álgebra mínima: *"de todos los `m` que tengo, quiero este"*.

---

## 7. 🟡 `override`, y la automatización con red

### Para qué sirve `override`

En herencia simple conocés la palabra `override`. ¿Para qué sirve? La respuesta refleja es "para sobreescribir el método". No: **la sobreescritura pasa por la mecánica del lenguaje**, con o sin la palabra. `override` no causa la sobreescritura; **evita que hagas una por accidente.**

Sirve para dos cosas: que si extendés una jerarquía que no conocés y ponés un método, no pises uno sin querer; y que si alguien renombra el método de arriba, vos te enteres de que el tuyo ya no lo sobreescribe. Es información que deja el programador para protegerse de sí mismo: *esto fue a propósito*.

### Lo automático también puede pedirte confirmación

Una crítica seria a la resolución automática es que a veces hacés cosas estúpidas: combinás dos cosas y no sabés qué va a pasar, y nadie te cuida. Por eso hay lenguajes tipados que, aunque linealicen, **no te dejan incluir dos mixins con el mismo método sin que vos resuelvas el conflicto explícitamente**: te obligan a definir el método en la clase y elegir. *"Acá estás metiendo dos métodos de dos lugares distintos que no vienen de la misma jerarquía; no me queda claro que estén pensados para que uno pise al otro."*

Te va a pasar en Scala. Es un detalle, pero hace a las formas de trabajar: **cuando uno dice "esto se resuelve de forma automática", hay veces que son más automáticas que otras.** Que la computadora pueda resolverlo no quiere decir que te vayan a dejar.

---

## 8. 🔴 El rol que le queda a la clase, y cuándo usar cada herramienta

Última fila de la tabla, y tercera y cuarta pregunta de la unidad. Acá los dos autores dicen cosas opuestas, y entender **por qué** dicen lo que dicen vale más que la respuesta.

### Ducasse: la clase es burocracia

Con traits, la clase puede dedicarse a su rol principal, que es **instanciar**, y perder su rol secundario, que era reutilizar código. Dicho por él: *dado que el rol principal de las clases es instanciar, deben ser completas, lo cual las hace inapropiadas para su rol secundario de repositorios de métodos reutilizables.*

Entonces a la clase le queda:

1. **Instanciar.** Tener `new`, generar los objetos.
2. **Glue code.** Componer los traits y resolver *a mano* todos sus conflictos. Es una cantidad sorprendentemente alta de código: todo lo que un mixin resuelve solo, acá se escribe.
3. **Definir el estado.** Porque los traits no pueden.

La clase pasa de ser la construcción principal donde vive la lógica a ser **una burocracia**: larga, sin nada de lógica de negocio. ¿Dónde está la lógica? En los traits. Y de ahí la recomendación de Ducasse: **usalos siempre**, poné todo lo que se pueda poner en traits. El argumento es que conviene tener la lógica en el lugar más flexible para combinar, y la clase no se combina con nada.

### Bracha: el de siempre

¿Qué rol le queda a la clase con mixins? **No sé.** Literalmente. Bracha dice que el rol de la clase es el mismo que hasta ahora: el de siempre. Y su recomendación de uso es la opuesta a la de Ducasse: **no usés mixins.** Seguí diseñando como diseñabas; esto no te cambió nada. Cuando tengas *atacantes y defensores*, esa cosa que no podés resolver de otra forma, ahí usá un mixin. Para el resto, no.

Por eso el signo de pregunta en la tabla. Y por eso, del lado de los mixins, la respuesta honesta a "¿y las clases para qué?" es encogerse de hombros.

### Por qué dicen cosas opuestas

**El que inventa la herramienta tiene una desventaja que nadie más va a tener: la herramienta no existía.** Nadie le enseñó a usarla. Tuvo una idea de cómo esperaba que se usara, pero no hay ninguna garantía de que esa idea sea la buena.

Bracha estaba vendiendo su herramienta a una industria que recién había adoptado objetos (Parte 1, Sección 7). Su discurso tenía que ser *"no te cambia nada, seguí igual, y si un día te pasa esto, ahí me llamás"*. Es la respuesta de siempre: *¿cuándo hay que usar mi herramienta? Nunca.* Ducasse llega años después, con el terreno más educado, y dice lo que probablemente Bracha pensaba: **la clase no se combina con nada; mi herramienta se combina con todo lo que quieras. ¿Dónde te conviene tener la lógica?**

Y ojo: el propio Ducasse es el que después publica cómo darles estado a los traits. La recomendación "sin estado" duró hasta que hizo falta.

### ¿Quién tiene razón?

**Depende. Depende del momento.** Si caés en un proyecto lleno de gente que viene de otro paradigma, no vas a decir "usemos todas estas herramientas locas": vas al ritmo que podés, y de a poco, cuando aparece un problema, mostrás cómo se resuelve. Es exactamente lo que le pasó a TypeScript: durante años decidieron no incluir ciertas construcciones porque sus usuarios no las iban a entender —lo dice su documentación—, y años después la misma comunidad pide más rigurosidad. **Que una herramienta sea buena no significa que alguien la vaya a usar ni que te vayan a dejar ponerla.**

Y hay un motivo más para no darle la razón a ninguno de los dos, que ya viste en la Parte 1: ambos dejaron vivo el concepto anterior. Los tres —clase, mixin y trait— ocupan el mismo nicho existencial, y ninguno de los dos se animó a liquidar el que ya estaba.

> ⚠️ **Advertencia.** Para el examen y para el TP, la recomendación vigente es la de la cátedra, no la de Bracha: **usar mixins lo más posible**, porque es la herramienta nueva y tu reflejo va a ser volver a la herencia. Cuanto más cómodo estés, más libre vas a ser cuando de verdad tengas que elegir.

---

## 9. 🔴 La tabla, completa

| Criterio | **Mixins** (G. Bracha) | **Traits** (S. Ducasse) |
|---|---|---|
| **Granularidad** | Módulo | Método |
| **Estado** | Sí | No (\*) |
| **Resolución de conflictos** | Automática: la linearización elige | Manual: no compila hasta que resolvés, mediante un álgebra |
| **Runtime** | Linearización: los mixins existen y el lookup pasa por ellos | Flattening: los traits se copian y desaparecen |
| **`super`** | Dinámico: va al siguiente de la lista, sea quien sea | Jerárquico: el único `super` es el de la herencia |
| **Rol de la clase** | El de siempre (?) | Instanciar, glue code y estado |

Y arriba de todo: **complementos de herencia simple**. El caso base sin ninguna de las dos es exactamente la herencia que ya tenías.

---

## 📝 Para el parcial, si te preguntan

**¿Qué es un conflicto y cómo lo resuelve cada herramienta?**
Un conflicto es que un objeto tenga más de un método disponible para el mismo mensaje. La herencia simple lo resuelve automáticamente con la sobreescritura (gana el más cercano). Los mixins lo resuelven automáticamente por linearización: se arma una lista y gana el primero que aparece. Los traits no lo resuelven: el código no compila hasta que el programador lo resuelve a mano con el álgebra (quitar, renombrar, sobreescribir).

**Dada esta clase, ¿en qué orden se buscan los métodos?**
Paso 1: la clase misma. Paso 2: sus mixins, empezando por el último incluido, cada uno con su propia linearización recursiva. Paso 3: la superclase, con su cadena. Si un mixin aparece repetido, se preserva la última aparición. Verificación: `Clase.ancestors`.

**¿Qué diferencia hay entre el `super` de un mixin y el de un trait?**
En un mixin, `super` es dinámico: va al siguiente de la linearización, que el mixin no conoce; lo cablea la clase que lo incluye. En un trait no hay `super` propio porque el trait no existe en runtime: el único `super` es el jerárquico, el de la superclase de la clase donde el método quedó aplanado.

**¿Qué rol le queda a la clase?**
Con traits (Ducasse): instanciar, escribir el glue code que compone los traits y resuelve sus conflictos, y definir el estado; la lógica de negocio vive en los traits. Con mixins (Bracha): el mismo rol de siempre; los mixins se usan solo cuando algo tiene que ser dos cosas a la vez. Las recomendaciones son opuestas porque cada autor escribió en un contexto de adopción distinto.

**¿Por qué cambiar el orden de dos `include` es un cambio mayor?**
Porque redefine qué método gana en cada conflicto entre esos mixins, en toda la jerarquía que dependa de esa clase. Cualquier código construido sobre ella asumiendo la resolución anterior cambia de comportamiento sin que nada lo avise. En versionado semántico corresponde subir el número mayor.

---

## ✅ Checkpoint parcial — Parte 2

*Sin respuestas.*

1. ¿Por qué se dice que la herencia simple te dio la solución del conflicto junto con el problema?
2. Una clase incluye `A`, después `B`, y `B` incluye `Z`. Hereda de `S`, que incluye `Z`. Escribí la linearización antes y después de limpiar repetidos.
3. ¿Qué significa que la linearización sea "arbitraria pero consistente", y qué sería que fuera random?
4. Un compañero escribe `include Atacante` y abajo `include Defensor`, y comenta "primero atacante, después defensor". ¿Qué está mal y por qué Ruby lo hace al revés?
5. ¿Qué se pierde al aplanar, y por qué sin embargo aplanar es más fácil de implementar?
6. ¿Por qué el `super` de un mixin es una herramienta de diseño y el de un trait no?
7. Bracha dice "no usés mixins" y Ducasse dice "usá traits para todo". ¿Cuál es el contexto que explica cada consejo?

---

**FIN DE LA PARTE 2 — Conflictos, linearización y el rol de la clase**
