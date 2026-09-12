# 📘 Apunte Maestro — Clase 03: Metaprogramación en Ruby

## Parte 1 — Qué es metaprogramar y sobre qué vamos a trabajar

**Materia:** Técnicas Avanzadas de Programación (TAdP) · **Unidad:** clase03 · **Clase del:** 29/08/2026

> **Serie completa:** Parte 0 (entorno) · **Parte 1 (qué es metaprogramar)** · Parte 2 (introspection) · Parte 3 (method lookup y métodos como objetos) · Parte 4 (self-modification) · Parte 5 (el metamodelo) · Parte 6 (autoclases y cierre).
> Las convenciones de lectura (marcas 🔴🟡🟢, madrigueras, advertencias) están explicadas al principio de la Parte 0.

---

## 1. Qué vamos a hacer en esta clase y en la que sigue 🟡

Este tema ocupa dos clases. En esta vamos a entender **cómo trabaja Ruby por abajo** —cómo hace para darte lo que te da cuando escribís una clase, un método o un mensaje— y vamos a conocer las herramientas que te dejan mirar y tocar esa maquinaria sin romper nada. La clase que viene trae las herramientas disruptivas: las que, por el solo hecho de usarlas, cambian el significado de otras cosas del programa y obligan a diseñar distinto.

Una advertencia de lectura que vale para las dos clases. Casi cada pregunta que surja va a tener **tres niveles de respuesta**, y conviene distinguirlos siempre:

1. **¿Qué pasa en Ruby?** — Cómo lo resolvió esta tecnología en particular.
2. **¿Cómo lo hacen otras tecnologías?** — Java, JavaScript, Smalltalk, Scala resuelven lo mismo de formas distintas, a veces ni siquiera con la misma metáfora.
3. **¿Qué es posible en teoría?** — Hay cosas que ningún lenguaje hace pero que serían perfectamente factibles, y otras que no se pueden hacer porque contradicen alguna otra construcción.

Ruby se eligió para este módulo porque su metamodelo es consistente y elegante, y eso lo hace un buen caso de estudio. Pero es un caso de estudio: cuando vayas a otra tecnología, va a ser distinto. **Lo que te tenés que llevar no es dónde está cada método en Ruby**, sino qué cosas podría haber disponibles, qué preguntas hacerle a un lenguaje nuevo, y cómo descubrir las respuestas vos.

---

## 2. El programa sobre el que vamos a trabajar 🟡

Esta clase no agrega funcionalidad a los guerreros. Los usa como conejillo de indias: un programa que ya conocés, para poder concentrarte en cómo Ruby lo sostiene por abajo. Acá está el archivo completo, `age-clase2.rb`, comentado por bloques. Para esta clase importan **Atacante, Defensor, Guerrero y Espadachin**; el resto está para que el archivo cargue y porque va a asomar en alguna salida de la consola.

*(Mixins, `include`, `alias_method`, `super`, `attr_accessor` y los bloques con `&` son de las clases 1 y 2 y se asumen. Si tenés fresca la resolución del conflicto entre Atacante y Defensor con `alias_method`, mejor: la vas a ver aparecer en la Parte 2.)*

```ruby
# ── Atacante: un mixin (módulo que se incluye en clases) con todo lo que sabe hacer
#    alguien que ataca. No se instancia: se incluye.
module Atacante

  attr_accessor :potencial_ofensivo, :descansado   # genera getters y setters para ambos

  def atacar(un_defensor)
    if self.potencial_ofensivo > un_defensor.potencial_defensivo
      danio = self.potencial_ofensivo - un_defensor.potencial_defensivo
      un_defensor.sufri_danio(danio)                # le pide al otro que se lastime
    end
    self.descansado = false                         # atacar te saca del estado "descansado"
  end

  def potencial_ofensivo
    self.descansado ? @potencial_ofensivo * 2 : @potencial_ofensivo   # si descansaste, pegás doble
  end

  def descansar
    self.descansado = true                          # descansar como atacante = quedar descansado
  end

end

# ── Defensor: el otro mixin. Sabe recibir daño y descansar recuperando energía.
module Defensor

  attr_accessor :potencial_defensivo, :energia

  def sufri_danio(danio)
    self.energia= self.energia - danio            # llama al setter energia= (el espacio antes del
  end                                             # valor es solo estilo; Parte 2 explica estos métodos)

  def descansar
    self.energia += 10                              # descansar como defensor = sumar energía
  end

end

# ── Guerrero: la clase central. Es atacante Y defensor a la vez.
class Guerrero
  include Atacante
  alias_method :descansar_atacante, :descansar      # guarda el descansar de Atacante bajo otro nombre

  include Defensor
  alias_method :descansar_defensor, :descansar      # guarda el descansar de Defensor bajo otro nombre

  attr_accessor :peloton

  # Valores por defecto: si no pasás nada, un guerrero nace con 20 / 100 / 10
  def initialize(potencial_ofensivo=20, energia=100, potencial_defensivo=10)
    self.potencial_ofensivo = potencial_ofensivo
    self.energia = energia
    self.potencial_defensivo = potencial_defensivo
  end

  # Los dos mixins definían "descansar" y el segundo incluido (Defensor) tapaba al primero.
  # Con los alias de arriba, Guerrero redefine descansar para hacer las DOS cosas.
  def descansar
    self.descansar_atacante
    self.descansar_defensor
  end

  def lastimado
    self.peloton.lastimado if self.peloton
  end

  def sufri_danio(un_danio)
    super(un_danio)                                 # llama al sufri_danio de Defensor
    self.lastimado if cansado
  end

  def cansado
    self.energia <= 40
  end

end

# ── Espadachin: hereda de Guerrero y agrega una espada que suma al potencial ofensivo.
class Espadachin < Guerrero

  attr_accessor :espada

  def initialize(espada)
    super(20, 100, 2)                               # constructor de Guerrero con valores fijos
    self.espada= espada
  end

  def potencial_ofensivo
    super() + self.espada.potencial_ofensivo        # lo que diga Guerrero, más la espada
  end
end

class Espada
  attr_accessor :potencial_ofensivo

  def initialize(potencial_ofensivo)
    self.potencial_ofensivo= potencial_ofensivo
  end
end

# ── De acá para abajo: clases de las clases anteriores que no se usan en esta.
#    Están para que el archivo cargue completo.

class Misil                                         # solo ataca
  include Atacante

  def initialize(potencial_ofensivo=200)
    self.potencial_ofensivo = potencial_ofensivo
  end
end

class Muralla                                       # solo defiende
  include Defensor

  def initialize(potencial_defensivo= 50, energia = 200)
    self.potencial_defensivo = potencial_defensivo
    self.energia = energia
  end

end

class Kamikaze                                      # ataca y defiende, pero muere al atacar
  include Defensor
  include Atacante

  def initialize(energia=100, potencial_defensivo=10)
    self.potencial_ofensivo = 250
    self.energia = energia
    self.potencial_defensivo = potencial_defensivo
  end

  def atacar(un_defensor)
    super(un_defensor)
    self.energia = 0
  end

end

class Peloton                                       # agrupa guerreros y reacciona cuando uno se lastima

  attr_accessor :integrantes, :estrategia, :retirado

  def self.cobarde(integrantes)                     # "def self." define un MÉTODO DE CLASE: lo entiende
    self.new(integrantes) { |peloton|               # Peloton (Peloton.cobarde(...)), no un pelotón. Ver abajo.
      peloton.retirate
    }
  end

  def self.descansador(integrantes)
    self.new(integrantes) { |peloton|
      peloton.descansar
    }
  end

  def initialize(integrantes, &estrategia)          # el bloque se guarda como estrategia
    self.integrantes = integrantes
    self.estrategia = estrategia
    self.integrantes.each { |integrante|
      integrante.peloton = self
    }
  end

  def lastimado
    self.estrategia.call(self)
  end

  def descansar
    cansados = self.integrantes.select { |integrante|
      integrante.cansado
    }
    cansados.each { |integrante|
      integrante.descansar
    }
  end

  def retirate
    self.retirado = true
  end

end
```

Dos construcciones de este archivo que conviene tener claras antes de seguir, porque la clase las da por sabidas y van a aparecer todo el tiempo:

- **`def self.cobarde(...)`**, en `Peloton`, define un **método de clase**: un método que entiende la clase misma, no sus instancias. Se usa como `Peloton.cobarde(guerreros)` —le mandás el mensaje a `Peloton`— y no como `un_peloton.cobarde`. Sirve para cosas como "dame un pelotón armado de tal manera", donde todavía no tenés ningún pelotón al que mandarle nada. Si venís de Java, es lo que ahí llamarías método estático; en Ruby no es exactamente eso, y la diferencia es uno de los temas centrales de la Parte 6. Por ahora: `def self.x` = "este método es para la clase".
- **`self.energia = ...`** y **`self.energia += 10`** no son asignaciones a una variable: son envíos de mensaje a un método que se llama `energia=`, con el signo igual incluido en el nombre. Es un método más, que `attr_accessor` generó. Se explica con detalle en la Parte 2, sección 9; hasta ahí, leelo como "le pido al objeto que cambie su energía".

Y así queda armado, en un dibujo que vamos a ir completando durante toda la clase:

```
                     ┌──────────┐
                     │  Object  │   (nadie lo escribió: es la superclase que Ruby pone
                     └────▲─────┘    cuando vos no decís nada)
                          │ hereda de
     ┌──────────┐         │         ┌───────────┐
     │ Atacante │◄╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌►│  Defensor │
     └──────────┘ incluye │ incluye └───────────┘
                     ┌────┴─────┐
   atila ───────────►│ Guerrero │
   es instancia de   └────▲─────┘
                          │ hereda de
                     ┌────┴──────┐
   zorro ───────────►│ Espadachin│
   es instancia de   └───────────┘
```

Un repaso de un minuto de cómo Ruby encuentra un método, que es la idea con la que llegamos a esta clase y que vamos a formalizar en la Parte 3. Si le mandás un mensaje a `atila`, Ruby lo busca primero en `Guerrero`; si no está, en sus mixins **en orden** —primero `Defensor`, que fue incluido último, y después `Atacante`— y si tampoco, sube a la superclase, `Object`. Si un método está en los dos mixins, gana el que está más cerca en ese orden. No hay negociación: hay un orden y se respeta. Ese orden se llama **linearización**, y fue el motivo de los `alias_method` de arriba.

---

## 3. Cuánto tenés que saber para escribir una sola línea 🔴

Vamos a arrancar por el caso más chiquito posible. Escribís esto:

```ruby
atila.atacar(otro)
```

Una línea. ¿Qué cosas tenías que saber para poder escribirla?

**Que `atila` es un objeto.** Está en una variable, así que la tecnología te garantiza que hay algo ahí. Bien.

**Que ese objeto es de alguna clase**, y que esa clase le da comportamiento. También bien.

**Que ese objeto entiende `atacar`.** ¿Y cómo lo sabés? Porque lo escribiste vos hace una semana, o porque lo leíste. Pero ¿alcanza con mirar la clase para saber qué métodos tiene? No. El método podría venir de un mixin. O de la superclase. O de un mixin de la superclase. **Para saber qué entiende un objeto tenés que conocer el recorrido que hace Ruby para buscar el código** —si hay mixins, en qué orden, si hay superclases— porque de ese recorrido depende qué método termina ejecutándose.

**Que `atacar` recibe un parámetro**, y **qué forma tiene que tener** ese parámetro. En Ruby esto es más laxo que en otros lenguajes, pero igual: no le podés pasar cualquier cosa.

Cuatro piezas de información, y todas están **hardcodeadas**: escritas a mano, fijas en el código, sacadas de tu cabeza. Nada de eso lo averiguó la computadora. Vos ya sabías que `atila` es un guerrero, que los guerreros atacan, que atacar recibe un defensor.

Ahora pensá en un **framework de testing**. Vos escribís una clase con métodos que empiezan con `test`, y el framework los corre todos y te dice cuáles pasaron. Preguntas que el framework necesita responder: ¿qué clases hay en el sistema? ¿Cuáles de esas heredan de la clase base de tests? ¿Qué métodos tiene cada una? ¿Cuáles empiezan con `test`? ¿Cómo instancio esa clase, que no conozco, para poder mandarle esos mensajes, que tampoco conozco?

Fijate que **ninguna de esas preguntas puede estar hardcodeada**, porque el framework se escribió antes que tu test. Su autor no sabe qué clases vas a escribir vos, ni cómo se van a llamar tus métodos. Lo único que sabe es que **hay** clases, que **hay** métodos, y que existe un lenguaje para consultarlos. Trabaja sobre la estructura sólida del universo —clases, métodos, atributos— sin conocer el contenido.

Eso es lo que hace esta clase: darte el lenguaje para hacer esas preguntas.

---

## 4. Metaprogramación 🔴

Con el caso ya visto, la definición se lee sola.

**Metaprogramación** es el proceso o la práctica de escribir programas que **generan, manipulan o utilizan otros programas**.

Los ejemplos clásicos son cada uno un verbo de esa definición:

- Un **compilador** es un programa que *genera* otro programa: recibe código fuente y produce un ejecutable.
- Un **formateador de código** es un programa que *manipula* otro programa: lo lee, lo reordena, lo reescribe con la indentación correcta.
- Una herramienta de documentación como **JavaDoc** es un programa que *utiliza* otro programa: lee las clases, los métodos y los comentarios de tu código y con eso genera páginas de documentación.

En los tres casos, **el dominio del programa es otro programa**. Un sistema de facturación modela facturas; un compilador modela programas.

### Para qué se usa

Sobre todo, para construir **frameworks y herramientas**.

> 🕳️ **Madriguera — framework**
> Un programa que resuelve cierta problemática de las aplicaciones sin estar diseñado para ninguna aplicación en particular. Un framework web te ayuda a hacer sistemas web —cualquiera— sin saber cuál vas a hacer vos. Lo distintivo es que su autor no conoce el dominio en el que lo van a usar.
> *Volvé al camino.*

Y esa es justamente la razón. Un framework se aplica a dominios que su creador desconoce; entonces no puede hardcodear nada del dominio y tiene que descubrirlo cuando el programa corre. Ejemplos:

- **ORMs** (como Hibernate): persisten las instancias de tus clases en una base de datos **sin conocer tus clases de antemano**. Tienen que preguntarle a cada objeto qué atributos tiene para saber qué guardar en qué columna.
- **Frameworks de UI**: tienen que saber mostrar cualquier objeto que les pases, sin conocerlo.
- **Frameworks de testing** (como JUnit): analizan tu clase de test para encontrar qué métodos son tests y correrlos. Es el caso de la sección 3.
- **Documentadores de código** (como JavaDoc): leen el código fuente y generan documentación.
- **Code coverage**: miden cuánto de tu código se ejecuta realmente cuando corrés los tests, y qué líneas nunca se tocan.
- **Analizadores de código**: evalúan tu código y generan métricas o detectan violaciones a reglas (estilo, complejidad).

> **Para el parcial, si te preguntan:** *¿Qué es metaprogramación? Dé un ejemplo.*
> Es la práctica de escribir programas cuyo dominio son otros programas: que los generan, manipulan o utilizan. Un compilador genera un programa a partir de código fuente; un framework de testing utiliza el programa del usuario para descubrir y ejecutar sus tests. Se usa principalmente para construir frameworks y herramientas, que deben trabajar sobre dominios que su autor no conoce.

---

## 5. Reflection 🔴

Se puede metaprogramar desde afuera: un compilador escrito en C que procesa programas Ruby está metaprogramando, con herramientas externas al lenguaje que procesa. Pero hay un caso particular que es el que nos importa:

**Reflection** es metaprogramar **en el mismo lenguaje** en que están escritos los programas que se manipulan. Todo desde adentro: un programa Ruby que inspecciona o modifica programas Ruby (incluido él mismo), usando las herramientas que Ruby le da.

Para eso el lenguaje tiene que dar soporte: facilidades, mensajes, construcciones. Y según cuánto soporte dé, va a haber más o menos de esto disponible. Reflection abarca tres cosas:

**Introspection** — la capacidad de un sistema de **analizarse a sí mismo**. Como la introspección humana, pero en términos de programa: el lenguaje te da herramientas para que el programa pueda "ver" o "reflejar" sus propios componentes. ¿De qué clase es este objeto? ¿Qué métodos entiende? ¿Qué atributos tiene? Es la primera mitad de esta clase.

**Self-modification** — la capacidad de un programa de **modificarse a sí mismo**: cambiar su comportamiento, agregar o pisar métodos, mientras está corriendo. También requiere soporte del lenguaje, y las limitaciones dependen de ese soporte. Es la segunda mitad de esta clase, y toda la que viene.

**Intercession** — la capacidad de modificar **las características del lenguaje mismo** desde adentro: agregarle al lenguaje una construcción que no tenía. El ejemplo histórico es Lisp, un lenguaje que no tenía objetos, al que le agregaron orientación a objetos desde el propio Lisp. 🟢 Esto **no se ve en la cursada**; se menciona para que sepas que la escalera tiene un escalón más.

> 🕳️ **Madriguera — CLOS y el Metaobject Protocol**
> CLOS es el sistema de objetos que se le agregó a Common Lisp usando el mismo Lisp. El libro *The Art of the Metaobject Protocol* documenta cómo se diseñó para que el usuario pueda extender y redefinir el propio sistema de objetos. Es la referencia clásica de intercession.
> *Volvé al camino — no entra en la materia.*

Una cosa sobre esta clasificación: **no te la tomes demasiado en serio como frontera**. Cuanto más dinámico es un lenguaje, más borrosa se pone la línea entre introspección y automodificación, y entre metaprogramación y programación común. Sirve para ordenar la cabeza; no sirve para decidir en qué categoría cae cada línea de código que escribas.

> **Para el parcial, si te preguntan:** *¿Qué es reflection y qué tipos hay?*
> Reflection es metaprogramar en el mismo lenguaje en que están escritos los programas, con las herramientas que ese lenguaje provee. Tiene tres tipos: introspection (el programa se analiza a sí mismo: qué clases, métodos y atributos tiene), self-modification (el programa se modifica a sí mismo en tiempo de ejecución) e intercession (se modifican características del propio lenguaje). En la materia se trabajan las dos primeras.

---

## 6. Modelos y metamodelos 🟡

Todo programa construye un **modelo** para describir su dominio. El de los guerreros describe el dominio "batalla" usando clases, métodos y atributos: hay una clase `Guerrero` que modela a los guerreros, con un método `atacar` y un atributo `energia`.

Los lenguajes pueden hacer exactamente lo mismo para describir **sus propias abstracciones**. Así como en el dominio hay guerreros, en el "metadominio" hay clases, métodos, atributos, mixins. Y un programa que describa eso es un **metamodelo**: el modelo de qué es una clase, qué es un método, cómo se relacionan.

```
   NIVEL          DOMINIO                    MODELO (lo que describe al dominio)
   ─────────      ───────────────────────    ─────────────────────────────────────
   Programa       guerreros, espadas,        clase Guerrero, método atacar,
                  batallas                   atributo energia

   Metaprograma   programas                  metamodelo: qué es una clase,
                  (el de arriba, por ej.)    qué es un método, cómo se buscan
```

Un metaprograma usa el metamodelo para trabajar sobre el programa base. Cuando el framework de testing pregunta "¿qué métodos tiene esta clase?", está usando el metamodelo: sabe que existe la abstracción "clase" y que las clases tienen "métodos", y tiene un lenguaje para consultarlo. En esta clase vamos a construir el metamodelo de Ruby entero, pieza por pieza, descubriéndolo desde la consola.

---

## 7. Dos familias de herramientas: consultar y modificar 🟡

Hay una distinción que ya conocés de Paradigmas y que acá se traslada tal cual a otro nivel.

Cuando modelás en objetos, separás los métodos que **preguntan** de los que **hacen**. Un método que pregunta es seguro: nunca te cambia el estado del programa, nunca debería interrumpir el flujo, lo podés llamar en cualquier momento. Un método que da una orden hay que usarlo con cuidado, porque cambia el estado y no cualquiera debería poder invocarlo cuando quiera.

Con reflection pasa lo mismo, un nivel más arriba. Hay operaciones que **analizan** el metaprograma —introspection— y construcciones que lo **cambian** —self-modification. Y las tecnologías se separan mucho según cuál de las dos habilitan. En Java, preguntarle a una clase qué métodos tiene es tan fácil como en Ruby; el problema en Java es querer modificar algo cuando el programa ya arrancó.

Una regla que vas a escuchar varias veces en esta clase, y que se desarrolla en la Parte 6: **lo importante de reflection es no usarla, a menos que la necesites.** A lo mejor tu programa no necesita modificar nada; a lo mejor solo necesita leer un dato preciso y el resto se resuelve con código común. Entonces uno trata de quedarse adentro de introspection, y solo cruza a la otra familia cuando no queda otra.

---

## 8. Y en otras tecnologías 🟡

Todas las tecnologías orientadas a objetos tienen algún grado de soporte para metaprogramación. No todas de la misma forma, ni con la misma elegancia, ni siquiera con la misma metáfora.

**Ruby** optó por ensuciar la interfaz: **todos los objetos entienden todos los mensajes de metaprogramación**. Cualquier objeto sabe responder de qué clase es, qué métodos tiene, qué variables de instancia guarda. Es cómodo y directo, y es lo que vamos a usar toda la clase. Tiene un costo que se va a ver cuando lo compares con otros lenguajes: la interfaz de cualquier objeto está llena de mensajes que no tienen nada que ver con su dominio.

**Scala**, por ejemplo, tomó otro camino: un modelo llamado *mirrors*, donde el objeto común no sabe nada de metaprogramación, y para preguntar sobre él tenés que traer un objeto distinto —el espejo— que es el que sabe responder.

> 🕳️ **Madriguera — Mirrors**
> Diseño en el que la capacidad de reflexión no vive en cada objeto sino en objetos dedicados (espejos) que reflejan a los demás. Mantiene limpia la interfaz de los objetos de dominio a cambio de un paso más para consultar. Scala lo usa; también existe en otros lenguajes.
> *Volvé al camino — no se usa en la materia.*

Y sobre modificar en tiempo de ejecución, una comparación concreta, porque marca muy bien dónde está parado cada uno. La pregunta es: **¿se puede agregar un método a una clase mientras el programa está corriendo?**

- **En Ruby: sí.** Fácil. Lo vas a hacer en la Parte 4 en dos líneas.
- **En JavaScript: sí.** De hecho no hay otra forma: todo se carga en tiempo de ejecución, siempre.
- **En Java: técnicamente sí, en la práctica no.** Java está pensado para ser estático. Las clases se cargan en la máquina virtual a través de un *ClassLoader*, y para cambiar un método de una clase ya cargada tendrías que: matar todas sus instancias, matar la clase, matar todas las instancias de todas las otras clases que fueron cargadas por el mismo ClassLoader, matar esas clases también, matar el ClassLoader, poner otro, y volver a cargar todo el código equivalente incluyendo la versión nueva de la clase con el método que querías. ¿Se puede? Sí. ¿Alguien lo hace? Casi nunca.

Esas diferencias no son de sintaxis. Son de **qué admite el metamodelo de cada tecnología**, y es exactamente lo que vamos a estudiar: qué decidió Ruby que sea posible, cómo cablea eso por abajo, y qué precio paga por tenerlo.

---

## Qué sigue

Ya tenés el vocabulario: metaprogramación, reflection, introspection, self-modification, metamodelo. Y tenés la pregunta que va a guiar todo: **¿qué le puedo preguntar a un objeto sobre sí mismo, y con qué mensajes?** La Parte 2 abre la consola y empieza a preguntar.

---

### Antes de seguir, tres preguntas para vos

1. Un framework de testing tiene que descubrir qué métodos de tu clase son tests. ¿Por qué no puede tener esa información escrita de antemano?
2. ¿Cuál es la diferencia entre metaprogramación y reflection? ¿Toda reflection es metaprogramación? ¿Al revés?
3. Un compilador, un formateador y un documentador son los tres metaprogramas. ¿Qué verbo de la definición cumple cada uno?

*(Las respuestas no están acá. Si alguna no te sale, es la señal de qué releer.)*
