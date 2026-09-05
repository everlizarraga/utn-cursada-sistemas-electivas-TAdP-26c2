# 📘 APUNTE MAESTRO — clase02 · Mixins: resolución de conflictos
## Parte 1 — Dos herramientas nuevas y de dónde salen

*Al terminar esta parte vas a poder explicar qué es un mixin, qué es un trait, en qué se parecen, en qué se diferencian, y —lo más importante— por qué existen y por qué se montan encima de la herencia simple en vez de reemplazarla.*

---

## 1. 🔴 Dónde quedamos, y qué vamos a prometer

La clase 1 terminó en un lugar incómodo a propósito. Teníamos esto:

```
┌──────────────────────┐                      ┌──────────────────────┐
│       Atacante       │                      │       Defensor       │
├──────────────────────┤                      ├──────────────────────┤
│ atacar(un_defensor)  │◄─────────┬──────────►│ sufri_danio(danio)   │
│ potencial_ofensivo   │          ✗           │ potencial_defensivo  │
└──────────────────────┘          │           │ energia              │
          ▲                       │           └──────────────────────┘
          │                       │                      ▲
    ┌─────┴─────┐          ┌──────┴──────┐         ┌─────┴─────┐
    │   Misil   │          │  Guerrero   │         │  Muralla  │
    └───────────┘          └─────────────┘         └───────────┘
```

`Misil` hereda de `Atacante`. `Muralla` hereda de `Defensor`. Y `Guerrero` necesita ser las dos cosas a la vez, y con herencia simple **no hay ningún cableado posible** que no termine repitiendo código o ensuciando la interfaz de alguien. La cruz roja no es un bug del dibujo: es el límite de la herramienta.

La salida es bajarse de una premisa que el paradigma de objetos trae de fábrica: **que los objetos se crean solamente a partir de una clase, y que una clase tiene una sola superclase.** No vamos a tirar eso. Lo vamos a *extender* con una construcción que está por afuera del planteo original de Alan Kay.

Concretamente, vamos a reemplazar las clases `Atacante` y `Defensor` por **otra cosa** —todavía no dijimos qué— que sí se pueda meter en `Guerrero` dos veces sin conflicto:

```
┌──────────────────────┬────┐                 ┌──────────────────────┬────┐
│       Atacante       │    │                 │       Defensor       │    │
├──────────────────────┼────┤                 ├──────────────────────┼────┤
│ atacar(un_defensor)  │    │                 │ sufri_danio(danio)   │    │
│ potencial_ofensivo   │    │◄◄──────┬──────►►│ potencial_defensivo  │    │
└──────────────────────┴────┘        │        │ energia              │    │
          ▲▲                         │        └──────────────────────┴────┘
          ││                         │                    ▲▲
    ┌─────┴┴────┐             ┌──────┴──────┐        ┌────┴┴─────┐
    │   Misil   │             │  Guerrero   │        │  Muralla  │
    └───────────┘             └─────────────┘        └───────────┘
```

Mismo modelo, notación nueva. Dos cosas cambiaron, y las dos significan algo:

**Las flechas tienen doble punta (▲▲).** Una punta es herencia. Dos puntas es *inclusión*: "esta clase incorpora eso". Es una notación de la cátedra; UML no tiene una forma de dibujar esto, y la única propuesta académica —una flechita de dos puntas que aparece en la literatura de traits— no dice nada útil por sí sola. La vamos a refinar en la Parte 4 cuando haga falta.

**Las cajas de `Atacante` y `Defensor` tienen dos columnas.** La izquierda es lo que el módulo **provee**: los métodos que trae. La derecha es lo que **requiere**: métodos que no implementa pero que necesita que alguien le dé para funcionar. Por ahora la derecha está vacía. Cuando deje de estarlo, va a ser el centro de la Parte 4.

Esa es la promesa: `Guerrero` va a poder incluir las dos cosas. El resto de la unidad es entender qué es "esa cosa", cómo se comporta cuando dos de ellas chocan, y qué se rompe en el camino.

---

## 2. 🔴 Las cinco preguntas que ordenan la unidad

La lectura previa venía con una lista de preguntas. No eran retóricas: son el esqueleto de esta clase, y en el orden en que se responden.

1. **¿Qué es un mixin? ¿Qué es un trait? ¿Cuál es la diferencia?** → esta parte.
2. **¿Qué es un conflicto? ¿Cómo se maneja en cada tecnología?** → Parte 2.
3. **¿Cuál es el rol que le queda a la clase?** → Parte 2.
4. **¿Cuándo sugiere cada autor usar estas herramientas?** → Parte 2.
5. **¿Cuáles de estas herramientas se usan en Ruby? ¿Y en Scala?** → Parte 3. Esta pregunta no se responde leyendo: hay que ir a mirar cada tecnología y sacar conclusiones propias.

Si al terminar la unidad podés contestar las cinco con un *porqué* atrás de cada una, la unidad está.

---

## 3. 🟡 De dónde salen estas herramientas

Antes de definir nada conviene entender **por qué aparecen** cosas como mixins y traits, porque eso explica la forma rara que tienen.

### El paradigma de objetos es heterogéneo

Objetos resuelve todo de la misma manera: hay alguien responsable de un problema, se le manda un mensaje, y ese alguien lo resuelve mandando mensajes a otros. Polimorfismo, encapsulamiento, delegación: todas las ideas fuertes del paradigma hablan de **objetos interactuando con objetos**.

Lo que el paradigma **no** dice es qué pasa *antes* de que haya objetos. Cómo se construyen. Cómo se organizan las definiciones. Cómo se combinan. Ahí la cancha está abierta, y por ahí entran las tecnologías con construcciones que no vienen de una capa gruesa de teoría que las unifique, sino de alguien que tuvo un problema y le puso un parche —*herramientas locas*, sin ironía. Algunas mueren, algunas sobreviven, algunas se pulen.

Mixins y traits son dos de esas. Y son **anecdóticas** en un sentido preciso: ninguna de las dos ganó. No hay una herramienta definitiva para este problema. Lo que sí hay es que una de las dos está presente en los dos lenguajes de la cursada, y por eso vale la pena entenderlas bien.

### Academia e industria no se ponen de acuerdo

Una consecuencia de que las herramientas nazcan como parches: **los conceptos se desarrollan antes de que se comuniquen.** Alguien implementa algo, le pone un nombre, y años después viene otro y lo formaliza con otro nombre. Y después viene un tercero, con más tracción o más plata, y usa el nombre del segundo para algo que no tiene nada que ver.

En medicina nadie discute qué es una vena. Acá vamos a discutir si algo es un mixin o no. Eso no es un defecto de la materia: es el estado real del campo, y vas a tener que aprender a moverte en él.

### Los dos nombres

**Gilad Bracha** es quien formaliza los mixins. La idea ya andaba dando vueltas en construcciones prácticas; él la piensa, la escribe, y la propone como una mejora al modelado con herencia simple que además esquiva los problemas de la herencia múltiple. Su tesis doctoral es la introducción académica formal al tema (la lectura previa fue un paper más corto donde compara y generaliza).

**Stéphane Ducasse** viene después. Toma la idea de Bracha, la analiza, y propone una herramienta que desde su punto de vista es superadora: traits. El intercambio que propone es **automatización por control**. Los mixins resuelven cosas solos; los traits te dan más control a cambio de que resuelvas vos.

Lo importante no es la cronología sino el gesto: **traits está pensado encima de mixins**, como respuesta a un problema que Bracha dejó abierto.

> 🕳️ **Madriguera — Bracha después de los mixins**
> Estuvo involucrado en casi todas las tecnologías interesantes de las últimas décadas; entre otras, trabajó con Google definiendo Dart. No hace falta para la materia; sí para entender por qué su opinión pesa.
> *Volvé al camino.*

---

## 4. 🔴 Mixins, según Bracha

### El caso primero

Antes de la definición, el código. Así se ve un mixin en Ruby:

```ruby
module Atacante                          # 'module' en vez de 'class': esto NO se instancia
  attr_accessor :potencial_ofensivo      # el mixin puede declarar estado (getter + setter)

  def atacar(un_defensor)                # y puede definir comportamiento
    if self.potencial_ofensivo > un_defensor.potencial_defensivo
      danio = self.potencial_ofensivo - un_defensor.potencial_defensivo
      un_defensor.sufri_danio(danio)     # 'sufri_danio' no está definido acá: lo tiene que traer el defensor
    end
  end
end

module Defensor
  attr_accessor :potencial_defensivo, :energia

  def sufri_danio(danio)
    self.energia = self.energia - danio
  end
end

class Guerrero
  include Atacante                       # "Guerrero es Atacante": trae todo lo que Atacante define
  include Defensor                       # y también es Defensor. Dos includes, ningún conflicto

  def initialize(potencial_ofensivo = 20, energia = 100, potencial_defensivo = 10)
    self.potencial_ofensivo  = potencial_ofensivo
    self.energia             = energia
    self.potencial_defensivo = potencial_defensivo
  end
end

# ¿CÓMO FUNCIONA?
atila   = Guerrero.new            # potencial_ofensivo 20, energia 100, potencial_defensivo 10
vikingo = Guerrero.new(70)        # potencial_ofensivo 70
vikingo.atacar(atila)             # 70 > 10 → danio = 70 - 10 = 60 → atila.sufri_danio(60)
atila.energia                     # Resultado esperado: 40

Atacante.new                      # Resultado esperado: NoMethodError — undefined method `new' for Atacante:Module
```

Lo que cambió respecto de la clase 1 es una palabra: `class` por `module`. La sintaxis para definir métodos y estado adentro es idéntica. Lo que se pierde es `new`; lo que se gana es poder `include`-ir el módulo en tantas clases como quieras, y que una clase incluya tantos módulos como quiera.

### La definición

Hay dos maneras de definir algo nuevo: por **álgebra** —el conjunto mínimo de reglas de cómo se opera, se reduce, se convierte— o por **analogía**: "es como X, pero". La analogía es más accesible porque partís de algo que ya conocés; el precio es que depende de qué entendía por X quien la dijo, y "clase" es una idea que cambia según a quién le preguntes. Tenelo presente, porque Bracha usa las dos.

Lo dice así, y vale la pena leerlo despacio:

> Un mixin especifica un **conjunto de modificaciones** —sobreescrituras y/o extensiones— aplicable a una clase parametrizable. Los mixins pueden verse como **funciones que reciben una superclase y producen una subclase.**

Hay dos metáforas ahí, y las dos son útiles.

**La primera: un mixin es un paquetito de cambios.** Todo lo que normalmente harías al extender una clase —agregar métodos, sobreescribir otros, declarar atributos— empaquetado por separado, sin decidir todavía a qué clase se lo vas a aplicar. `Atacante` es "todo lo que tiene que cambiar en una clase para que sepa atacar". Después vos elegís a quién se lo aplicás.

**La segunda: un mixin es una función de clases.** Recibe una clase, devuelve otra clase con los cambios aplicados. `Guerrero` es lo que da aplicar `Atacante` y después `Defensor` a una clase vacía. Esta lectura es hermosa y es más literal en la implementación de traits que en la de mixins, pero como forma de *pensar* funciona para las dos.

### "Es como una clase abstracta"

La forma tradicional de explicar un mixin es por analogía: **es como una clase abstracta que se puede heredar múltiples veces.** Esta frase es correcta y engañosa al mismo tiempo, así que hay que desarmarla.

Primero, qué hace abstracta a una clase. Hay dos respuestas y las dos valen:

- **Por limitación:** le falta un método que necesita. Tiene un *método abstracto*: un lugar donde dice "yo debería tener esto, no lo tengo, quien me herede lo tiene que proveer". No la podés instanciar porque un objeto de esa clase no funcionaría.
- **Por decisión:** no le falta nada, pero decidiste que no tiene sentido instanciarla. Como cuando en la clase 1 `Defensor` era una clase abstracta y `Muralla` la instanciable, aunque `Muralla` estuviera vacía y no completara ningún hueco. Le ponés una etiqueta y listo.

En Ruby no hay sintaxis para "método abstracto". Es una convención: un comentario, un nombre, un acuerdo del equipo. El lenguaje no te frena; el tipado laxo habilita cosas que un lenguaje más duro no dejaría.

Ahora, cuando Bracha dice que un mixin es *como* una clase abstracta se refiere a esto: **es una clase que no tenés el propósito de instanciar**, que puede definir comportamiento, definir estado, combinarse con otros mixins, y aplicarse a otras clases. Bracha usa el verbo *heredar* para eso porque habla en el lenguaje de la época; nosotros vamos a decir *incluir*.

Y cuando habla de mixin **completo** o **incompleto**, habla exactamente de lo mismo que en la clase abstracta: si tiene o no tiene requerimientos pendientes. Esa columna derecha vacía de las cajas de la Sección 1 es la lista de requerimientos. `Atacante` hoy es completo: no le falta nada. En la Parte 4 va a dejar de serlo.

Alguien inquisitivo puede preguntar: si es como una clase abstracta, ¿por qué no hacer que las clases abstractas hagan esto y listo? ¿Por qué un concepto nuevo? Es una pregunta legítima que la lectura no responde, y la retomamos en la Sección 7, porque la respuesta no es técnica.

### Las tres propiedades

De la definición y de la lectura salen tres propiedades que conviene tener nombradas:

1. **No se instancia.** `Atacante.new` no existe. Esta restricción es *arbitraria*: en un mixin, a diferencia de un trait, la entidad sí existe en tiempo de ejecución y no habría problema técnico en instanciarla. No se hace porque Bracha estaba vendiendo una herramienta a gente que ya sabía usar clases, y la forma más fácil de que la adopten era decirles "las clases siguen siendo lo que eran; esto es otra cosa".

2. **Admite múltiples inclusiones.** Una clase puede incluir tantos mixins como quiera, y un mixin puede ser incluido por tantas clases como quiera. Esa es la diferencia con la herencia, que sigue siendo simple: **una clase hereda de una única clase, pero incluye N mixins.**

3. **Es independiente de la clase que lo usa.** El mixin no queda atado a ninguna jerarquía. Es la clase la que decide usarlo y la que lo combina con otros. `Atacante` no sabe que existe `Guerrero`.

### La herencia como caso particular

Hay una observación de Bracha que cierra la idea: **la herencia simple es un caso particular de mixins.** Si pensás que una clase es "un mixin que además se puede instanciar, y que solo se puede extender de un único otro mixin", la mecánica cierra. No hace falta que lo uses así, pero muestra que el concepto nuevo no es un agregado raro: es una generalización del que ya tenías.

---

## 5. 🔴 Traits, según Ducasse

### El problema que ve Ducasse

Ducasse arranca reconociendo el mérito:

> Los mixins permiten obtener mejor reutilización del código que la herencia simple, manteniendo la simpleza. El problema es que, usualmente, **los mixins no encajan del todo bien entre ellos.**

Lo que dice es esto. Un paquetito de cambios es una gran idea cuando aplicás *un* paquete, ortogonal a una jerarquía. El problema aparece cuando querés combinar varios: te vas a topar con situaciones en las que **querés una porción de uno y una porción del otro**, y no calzan. Querés el método `m` de acá y el método `n` de allá, y el mixin te obliga a traer el paquete entero.

La respuesta de Ducasse es cambiar la **granularidad**. Un mixin se combina a nivel de módulo: incluís todo o nada. Un trait se combina **a nivel de método**: elegís qué métodos querés de cada uno.

### "Módulo" — una palabra que hay que fijar

Módulo es la palabra que se usa para cualquier abstracción que funciona como **proveedor de lógica para definir una entidad**: clases, mixins, traits. No hay un estudio muy elaborado que lo defina mejor, así que se usa esa. Ojo: en Ruby además es la palabra clave `module`, y en otros contextos significa paquete. Acá, salvo que se diga otra cosa, es el sentido genérico.

### Qué es un trait, entonces

De la definición de Ducasse y de la lectura se puede concluir:

- **Similar a un mixin** en lo esencial: parecido a una clase abstracta, se pueden incluir varios en una jerarquía, complementa la herencia simple.
- **Granularidad a nivel de método.** Se puede elegir método por método qué traer. Combinar traits es aplicar operaciones: sumar dos traits, quitar un método, renombrar otro. A ese conjunto de operaciones se lo llama el **álgebra de traits**. Se desarrolla en la Parte 2.
- **Se aplanan sobre la clase que los usa.** Habrás leído *flatten* o *flattening*. Quiere decir que después de que el lenguaje hace su trabajo de integrar los traits, **los traits desaparecen en tiempo de ejecución**: sus métodos quedan copiados dentro de la clase, y lo que corre es una jerarquía de herencia simple común. Una especie de copy-paste inteligente que no hacés a mano y que se mantiene consistente. Las consecuencias de esto son grandes y van en la Parte 2.
- **Sin estado (\*).** Los traits, en su presentación original y en la mayoría de las implementaciones existentes, no definen estado: solo interfaz. El asterisco es porque el propio Ducasse publicó después un paper de *stateful traits* mostrando cómo agregarles estado. Se menciona porque es curioso que tantas tecnologías con construcciones tipo trait sigan sin manejar estado, y la razón es la Sección 6.

### ⚠️ La pregunta incómoda

Todo lo anterior es lo que dice el autor. Ahora la mirada crítica.

Cuando lo ponés en abstracto —"tengo el mixin A con `m` y `n`, el mixin B con `m` y `n`, y quiero el `m` de A con el `n` de B"— suena razonable, algo que te podría pasar cualquier día. Y después te ponés a pensar: **¿cuándo me pasó?** Es muy difícil construir un ejemplo natural. Compará con lo fácil que fue romper la herencia simple: tres clases, un dominio de juguete, dos minutos.

¿Por qué cuesta tanto? Porque diseñar consiste justamente en agrupar cosas de forma cohesiva. Si te encontrás con un mixin del que querés la mitad, la pregunta no es "cómo lo parto con un álgebra" sino **"¿por qué ese mixin es tan grande?"**. Partilo en dos mixins más chicos y listo: ahora tenés cuatro en vez de dos, pero no tenés que escribir código de pegado para cada inclusión.

Y ahí está el costo que la flexibilidad esconde: **traits es indiscutiblemente más flexible, pero cada relación entre un trait y una clase se paga con un bloque de código que dice "quiero este método, y este, y este atributo"** —eso es el *glue code*, el código pegamento que la clase escribe para armar sus traits. Un bloque que con mixins no existe. Hacé un programa de cuatro o cinco clases con traits y fijate si no te cansaste de escribirlo.

> **Para el examen:** las propiedades de un trait son las de la lista de arriba, y la diferencia con mixins es la de la tabla de la Sección 8. La crítica es criterio de diseño: te sirve para el "cuándo usar" de la Parte 2, no para redefinir qué es un trait.

---

## 6. 🟡 Por qué el estado es el problema difícil

"Sin estado" no es una limitación caprichosa. **Definir y manipular estado en construcciones combinables es muchísimo más difícil de lo que parece**, y entender por qué te va a evitar sorpresas.

### El caso

Dos módulos, cada uno con su variable, que terminan combinados en el mismo objeto:

```ruby
module Contador
  def incrementar
    @cuenta = (@cuenta || 0) + 1      # el mixin usa @cuenta como SU contador numérico
  end
end

class Cajero
  include Contador

  def initialize
    @cuenta = "CA-1234"               # la clase usa @cuenta como SU número de cuenta bancaria
  end
end

# ¿CÓMO FUNCIONA?
c = Cajero.new                        # @cuenta = "CA-1234"
c.incrementar                         # el mixin lee @cuenta: encuentra "CA-1234", no nil
                                      # intenta "CA-1234" + 1
# Resultado esperado: TypeError — no implicit conversion of Integer into String
```

Los dos módulos declararon una variable con el mismo nombre para cosas distintas. ¿Cuál se accede cuando `incrementar` toca `@cuenta`? En Ruby, **la misma**: el objeto tiene un solo espacio de estado y los dos escriben ahí. Nadie te avisó. El error salta después, en runtime, y con un mensaje que no menciona el conflicto.

La pregunta general —"cuando dos módulos combinados definen el mismo estado, ¿cuál gana?"— **no tiene una buena respuesta**, y está bien que no la tengas. La propuesta habitual en tecnologías más estrictas es directamente **no dejar** que un módulo cree por segunda vez un atributo que ya existe más arriba: resolverlo sería un quilombo de constructores, inicializaciones y pisadas.

### Por qué es tan pesado

Dos cosas son sumamente complejas en cualquier lenguaje de objetos, y las dos tocan estado:

- **Los constructores.** Tienen su propio lookup, su propia estructura de llamado al anterior. Son una pesadilla que las tecnologías intentan esconder.
- **Dónde y cómo se define el estado.** Cambiar la definición de estado cambia el **espacio de memoria** que ocupa el objeto. No es lo mismo necesitar un puntero que dos. Eso afecta de verdad cómo se comporta el runtime.

Por eso, cuando te encuentres con una construcción que **no te deja definir estado**, ya tenés una pista: se comporta más como un trait que como un mixin. Y por eso también, si la herramienta te lo permite, los mixins pueden definir estado pero conviene pensarlo dos veces.

> ⚠️ **Advertencia.** Ruby te deja definir estado en un módulo y no chequea colisiones. En la materia se usa esa libertad (`attr_accessor` dentro de `Atacante` y `Defensor`), y para el examen esa es la respuesta: *los mixins de Ruby tienen estado*. En la práctica, los nombres de variables de instancia de un mixin son parte de su contrato y hay que elegirlos como si fueran públicos.

---

## 7. 🔴 Complementos de herencia simple, no reemplazos

Esta es la propiedad que más importa y la que más cuesta ver, porque está a la vista.

### Qué significa

**Ni mixins ni traits vienen a reemplazar la herencia. Vienen a montarse encima.** En el mismo sistema seguís teniendo clases, seguís teniendo `<`, seguís teniendo una única superclase. Lo que se agrega es un paso más.

Mirá cómo lo hace cada uno:

- **Mixins extienden el mecanismo.** Cuando buscás un método, antes de subir a la superclase pasás por los mixins. Si una clase no incluye ningún mixin, el lookup es exactamente el de siempre. **El caso base de "tener mixins" es la herencia simple**: vos siempre tuviste mixins, solo que la lista estaba vacía. Para que esto ande hay que tocar un poco el mecanismo de lookup de la máquina virtual.

- **Traits no tocan nada.** Como se aplanan antes de ejecutar, la máquina virtual ni se entera de que existieron: en runtime solo ve clases y herencia simple. Lo único que hay que construir es el aparato previo que copia los métodos. Por eso traits es **más fácil de meter en un lenguaje**.

Uno fue por un camino, otro por el otro. Los dos dejaron la herencia intacta.

### Por qué — la respuesta no es técnica

Acá está la respuesta a la pregunta de la Sección 4: si un mixin es como una clase abstracta, ¿por qué no cambiar las clases y listo?

**Porque no vamos a cambiar todo ahora.** Cuando aparecen estas ideas, objetos acaba de ganar la batalla cultural contra el paradigma estructurado. Hay una industria entera de programadores que vienen de C, Cobol y Pascal, a los que hubo que convencer de una cosa dificilísima: que cuando escribís `objeto.mensaje` **no sabés qué método se va a ejecutar**. Eso se llama *binding dinámico*, es intrínseco a objetos, y le costó años entrar. Ahora imaginate ir seis meses después a decirles: "¿sabés qué? tampoco sabés de qué jerarquía viene: podría ser un mixin tirado por ahí".

**Porque tocar la máquina virtual es carísimo.** Sobre la JVM (la máquina virtual de Java) están montados muchos otros lenguajes; cada cambio es chiquito, cuidado, medido. Java estuvo décadas sin lambdas por eso. Cuando Python rompió todo entre la versión 2 y la 3, le costó una migración masiva y un peso político enorme, aunque todos coincidan en que fue para mejor. A veces podés hacer eso. Casi nunca.

**Porque la alternativa era hacer tu propio lenguaje, y eso no funciona.** Bracha lo hizo: la tesis viene con un lenguaje propio donde los mixins son la construcción central. No lo usó nadie. Ducasse forqueó un lenguaje que ya existía, y aun así dejó la herencia porque rehacer una jerarquía de cero era muy difícil. Si cualquiera de los dos hubiera dejado su idea solo en su lenguaje, hubiera sido una más de los millones de ideas interesantes de laboratorio. Lo que hicieron en cambio fue decir: *"esto es muy fácil de meter, vos seguís haciendo todo igual, y si un día te pasa que algo tiene que ser dos cosas, ahí me llamás y ponemos un mixin".*

**Porque por eso mismo ninguno de los dos tiene razón del todo.** Ambos comparten un problema clave: **no se animaron a liquidar el concepto anterior.** Era muy costoso. Y esa media medida es lo que hace que la discusión "mixins vs traits" siga abierta: las dos son herramientas construidas bajo una restricción que hoy ya no es tan fuerte.

> ⚠️ **Advertencia.** La opinión explícita de la cátedra es que la **herencia múltiple bien hecha**, como la de Python, es ampliamente superadora de las dos: no hay un concepto que discuta el rol de la entidad sobre la que implementás, son clases y se combinan las que querés. Python pudo hacerlo porque tiene su propia máquina virtual y no dependía de una pensada para herencia simple. Se retoma en la Parte 3. **Para el examen:** mixins y traits *complementan* la herencia simple; la razón es el costo de cambiar la VM y de reeducar a la industria, no una imposibilidad técnica.

---

## 8. 🔴 Los seis criterios: la tabla como mapa

Toda la unidad se puede resumir en una tabla de seis filas. Es la herramienta que después vas a usar para clasificar cualquier tecnología que te crucen, así que conviene tenerla entera aunque todavía no esté toda explicada.

| Criterio | **Mixins** (G. Bracha) | **Traits** (S. Ducasse) | Se desarrolla en |
|---|---|---|---|
| **Granularidad** | Módulo | Método | Parte 1 ✔ |
| **Estado** | Sí | No (\*) | Parte 1 ✔ |
| **Resolución de conflictos** | Automática | Manual (mediante un álgebra) | Parte 2 |
| **Runtime** | Linearización | Flattening (aplanado) | Parte 2 |
| **`super`** | Dinámico | Jerárquico | Parte 2 |
| **Rol de la clase** | El de siempre (?) | Instanciar, glue code y estado | Parte 2 |

Y encabezando todo, lo que las dos comparten: **complementos de herencia simple.**

Las dos primeras filas ya las tenés. Las cuatro que faltan son las que salen de preguntarse qué pasa cuando dos de estas cosas chocan, y eso es la Parte 2. El signo de pregunta en la última celda no es un error de tipeo: es la respuesta real que da Bracha, y también se explica ahí.

Dos advertencias sobre cómo usar la tabla:

**No la memorices como una ley natural.** Es fácil clasificar cosas que ya responden a una clasificación. Siempre hay un ornitorrinco. Vas a encontrar tecnologías que tienen granularidad de módulo pero resolución manual, o linearización sin `super` dinámico. La tabla no está para encajarlas: está para saber **con qué herramientas de diseño contás** cuando caés en una tecnología nueva.

**El nombre que usa el lenguaje no importa.** Ruby le dice `module`. Scala le dice `trait`. La clasificación se hace contra los criterios, no contra la palabra clave. Eso es la Parte 3.

---

## 📝 Para el parcial, si te preguntan

**¿Qué es un mixin?**
Un módulo de comportamiento (y opcionalmente estado) que no se instancia y que una clase puede incluir junto con otros. Se puede pensar como un paquete de modificaciones aplicable a cualquier clase, o como una función que recibe una superclase y devuelve una subclase. Complementa la herencia simple: la clase sigue heredando de una única superclase, pero incluye N mixins.

**¿Cuál es la diferencia de fondo entre un mixin y un trait?**
La granularidad y quién resuelve los conflictos. El mixin se incluye entero y los conflictos se resuelven automáticamente por un orden (linearización). El trait se combina método por método mediante un álgebra, los conflictos los resuelve el programador, y el trait se aplana sobre la clase: no existe en tiempo de ejecución.

**¿Por qué mixins y traits complementan la herencia simple en vez de reemplazarla?**
Porque cambiar el modelo de clases implicaba tocar la máquina virtual y reeducar a una industria que recién había adoptado objetos; el costo de salida era prohibitivo. Los dos autores optaron por una construcción que se monta encima del mecanismo existente: mixins agregan pasos al lookup, traits se aplanan antes de ejecutar. El caso base sin mixins ni traits es exactamente la herencia simple de siempre.

**¿Por qué "sin estado" en los traits?**
Porque combinar estado de varios módulos en un mismo objeto no tiene una resolución buena: dos módulos pueden declarar el mismo atributo para cosas distintas, los constructores tienen su propio lookup, y la definición de estado afecta la memoria que ocupa el objeto. Los traits esquivan el problema declarando solo interfaz; el estado lo provee la clase. Existe una extensión posterior (stateful traits) que lo agrega.

---

## ✅ Checkpoint parcial — Parte 1

*Sin respuestas. Si podés contestarlas en voz alta con un porqué, seguí a la Parte 2.*

1. ¿Qué tiene que cambiar en `Guerrero` para que pueda ser `Atacante` y `Defensor` a la vez, y qué palabra de Ruby cambia en `Atacante` para permitirlo?
2. Un compañero te dice "un mixin es una clase abstracta". ¿En qué tiene razón y en qué se queda corto?
3. ¿Por qué la restricción de no instanciar un mixin es arbitraria, y por qué en un trait no lo es?
4. Ducasse dice que los mixins "no encajan bien entre ellos". ¿Cuál es el problema concreto, y cuál es la salida sin traits?
5. ¿Qué significa que "el caso base de tener mixins es la herencia simple"?
6. ¿Qué le costó a cada autor no liquidar el concepto de clase?

---

**FIN DE LA PARTE 1 — Dos herramientas nuevas y de dónde salen**
