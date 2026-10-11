# Clase desde cero — Prototype — Módulo 1: El problema

**Unidad:** clase06 · **Módulo:** 1 de 9 (+1 opcional) · **Densidad:** 🟡 · **Parte del enunciado:** secciones 1 a 3

## Sobre este documento

**Qué cubre:** el panorama de la clase (qué vamos a construir y por qué), qué es un prototipo y en qué se diferencia de una clase, **las secciones 1 a 3 del enunciado leídas frase por frase** con cada palabra técnica definida en el momento en que aparece, qué queremos poder escribir al final, y dónde está hoy el hueco de Ruby que vamos a llenar.

**Qué NO cubre:** ninguna línea del framework. Acá solo hay Ruby que ya conocés. El framework empieza en el Módulo 2, con las tres primeras líneas de la parte 4.1.

**Tené el enunciado a mano.** Este módulo cita sus secciones 1, 2 y 3 y el primer bloque de código de 4.1; los siguientes van parte por parte.

## De dónde venís

Se asume sabido de clase03 y clase04:

- un objeto no tiene métodos: cuando recibe un mensaje, va a buscar el método a su clase, y de ahí sube por los mixins y las superclases (**method lookup**);
- antes de la clase, el lookup pasa por la **autoclase** (`singleton_class`): una clase propia de ese único objeto, donde `define_singleton_method` deja métodos que solo él entiende;
- un objeto guarda estado en variables `@algo`, que existen desde que alguien las setea;
- un **proc** es un bloque convertido en objeto (`proc { … }`), se ejecuta con `call`, y recuerda el `self` del lugar donde fue escrito; `instance_exec` lo ejecuta con otro `self`;
- `method_missing` se ejecuta cuando el lookup termina sin encontrar nada, y va siempre acompañado de `respond_to_missing?`.

---

## 1. 🟡 Panorama: qué vamos a construir

> **Regla.** Toda esta clase consiste en resolver el ejercicio integrador "Prototype". No hay tema nuevo: se usa lo de clase03 y clase04 (autoclase, `define_singleton_method`, procs, `instance_exec`, `method_missing`) para construir, en unas 200 líneas, una forma de compartir comportamiento que Ruby no trae: **prototipos**.

Un **prototipo** es un objeto del que otro objeto saca comportamiento. Si Martín tiene como prototipo a Juan, y a Martín le mandan un mensaje que él no entiende, Martín va a buscar el método **a Juan**. No a una clase: a otro objeto como él.

El enunciado lo pide en cuatro partes, y cada una es uno o varios módulos de esta clase:

| Parte del enunciado | Qué pide | Módulos |
|---|---|---|
| 4.1 *Prototipos programáticos* | Un objeto al que se le agregan propiedades y métodos sin clase, se clona, y se linkea a un prototipo | M2, M3, M4, M5, M6 |
| 4.2 *Constructores* | Un objeto que fabrica objetos a partir de un prototipo, con el estado inicializado | M7 |
| 4.3 *Azúcar sintáctico* | Lo mismo, escrito cómodo: `guerrero.energia = 100`, bloques en vez de procs | M8 |
| 4.4 *Llamar al prototipo anterior y múltiples prototipos* | Un `super` para prototipos, y más de un prototipo por objeto | M9 |

El código que vamos a escribir es corto para lo que hace, y cada línea tiene una razón. Lo difícil no es la sintaxis: es decidir **dónde vive cada cosa** (en el objeto, en su autoclase, en su clase, en un diccionario) y **quién busca qué cuando llega un mensaje**. Eso es lo que esta clase enseña, y lo que después se evalúa en el individual: moverte en tu propio código sabiendo por qué cada pieza está donde está.

---

## 2. 🔴 Qué es un prototipo

> **Regla.** En Ruby, un objeto recibe su comportamiento de un **proveedor de comportamiento** que no es un objeto común: su clase, o un mixin. Con prototipos no hay esa distinción: **los objetos mismos son los proveedores de comportamiento**. Un objeto saca sus métodos de otro objeto.

Primero, lo que ya conocés. Dos alumnos, Juan y Martín. En Ruby, para que los dos saluden, el saludo vive en una clase, y los dos son instancias de ella:

```ruby
class Alumno
  def saludar; "hola, soy un alumno"; end    # el comportamiento vive en la CLASE
end

juan   = Alumno.new                           # juan no tiene nada propio: todo lo saca de Alumno
martin = Alumno.new

juan.saludar          # => "hola, soy un alumno"
martin.saludar        # => "hola, soy un alumno"
juan.methods(false)   # => []      ← juan, como objeto, no tiene ningún método propio
```

Con prototipos la idea es otra. No se piensa primero en "la idea de alumno" y después en los alumnos concretos. Se **construye un alumno que funciona** (Juan), y a partir de él se sacan los demás:

```
                 prototipo
   ┌────────┐  ◄──────────  ┌────────┐
   │  Juan  │               │ Martín │
   │ saludar│               │        │
   └────────┘               └────────┘

   martin.saludar   →  Martín no lo tiene  →  lo busca en su prototipo, Juan  →  "hola"
```

Martín tiene una flecha a Juan que dice "este es mi prototipo". Cuando Martín recibe `saludar` y no lo tiene, **va a buscarlo a Juan**. Si Martín define su propio `saludar`, usa el suyo y no va a Juan. Es el mismo movimiento que el method lookup de Ruby (buscar acá, si no está subir), pero la flecha no apunta a una clase: apunta a **otro objeto igual que vos**.

Dos palabras que van a aparecer todo el tiempo, definidas acá: el objeto que recibe comportamiento de otro se llama **derivado** (o *prototipado*: Martín es un derivado de Juan); y la secuencia de objetos por la que se busca un método (Martín, después Juan, después el prototipo de Juan, si tiene) es la **cadena de prototipos**.

### Lo que Ruby ya puede, y lo que no

Ruby sí sabe darle comportamiento a **un solo objeto**, sin tocar su clase: es la autoclase de clase03.

```ruby
juan.define_singleton_method(:saludar) { "hola, soy Juan" }   # queda en la autoclase de juan

juan.saludar               # => "hola, soy Juan"              ← el suyo
martin.saludar             # => "hola, soy un alumno"         ← martin no se enteró: sigue usando Alumno
juan.singleton_methods     # => [:saludar]
martin.singleton_methods   # => []
```

Lo que Ruby **no** sabe hacer es que Martín vaya a buscar a la autoclase de Juan:

```ruby
juan.define_singleton_method(:despedirse) { "chau" }

juan.despedirse     # => "chau"
martin.despedirse   # => NoMethodError: undefined method `despedirse' for #<Alumno:0x…>
#                      martin buscó en SU autoclase, en Alumno, en Object… nunca en juan
```

Ese es el hueco. El method lookup de Ruby sube por clases y mixins; **nunca pasa de un objeto a otro objeto**. Lo que vamos a construir es, justamente, un lookup que sí pase: de Martín a Juan, y de Juan a quien sea su prototipo.

> 🕳️ **Madriguera — JavaScript**
> JavaScript está construido sobre prototipos: cada objeto tiene una propiedad interna que apunta a otro objeto, y el lookup de propiedades sube por esa cadena. La sintaxis `class` que se usa hoy es azúcar sobre ese mecanismo; se compila a prototipos. Es el ejemplo más grande de lo que acá vamos a hacer en chico.
> *Volvé al camino — esto se profundiza aparte, otro día.*

---

## 3. 🟡 Prototipos contra clases

> **Regla.** Una clase solo **construye** cosas que se comportan de cierta forma; no se comporta como ellas. Un prototipo **se usa** como la cosa misma y, además, sirve de molde. Esa capacidad es su ventaja y su desorden.

Es una diferencia de filosofía de diseño, no de poder: con prototipos se puede modelar herencia simple, mixins, y lo que quieras; con clases, también. Lo que cambia es **de dónde arrancás**:

| | Clases | Prototipos |
|---|---|---|
| Primero se construye | La idea de la cosa (`Alumno`), afuera de cualquier alumno concreto | Una cosa que funciona (`juan`) |
| El molde… | solo fabrica: `Alumno.saludar` no tiene sentido | se usa: `juan.saludar` anda, y además `juan` es el molde de Martín |
| Para agregar comportamiento a todos | se toca la clase | se toca el prototipo |
| Orden | Lo da la jerarquía de clases | Hay que **saber quién es el prototipo** de quién; nada lo fuerza |

La última fila es el costo. Como cualquier objeto puede ser prototipo de cualquier otro, es fácil terminar con un grafo de flechas donde nadie sabe de dónde sale cada método. En la práctica, los que programan con prototipos terminan **eligiendo un objeto como "jefe"**, que nunca usan como instancia, y programando contra él como si fuera una clase. El mecanismo lo permite; la disciplina la pone el programador.

> 🎯 **Para el parcial, si te preguntan** cuál es la diferencia estructural entre un prototipo y una clase:
> La clase es un proveedor de comportamiento que no es instancia de nada de lo que define: solo construye objetos. El prototipo es un objeto común que, además de usarse, provee comportamiento a otros objetos; por eso un objeto prototipado tiene que poder mirar dentro de sí y dentro de otros objetos para encontrar sus métodos, cosa que en Ruby un objeto no hace.

### Dónde queda Ruby en todo esto

En Ruby las clases **también son objetos**: eso lo sabés de clase03. Entonces, ¿no es Ruby un lenguaje de prototipos? No. Que la clase sea un objeto no la convierte en instancia de sí misma: `Alumno.saludar` sigue sin andar. Lo que falta en Ruby es la pieza mecánica de que un objeto cualquiera busque comportamiento **en otro objeto cualquiera**. Y acá viene la frase que define el trabajo:

> **Regla.** Lo que construyamos va a usar clases por dentro, porque Ruby corre con clases. Pero **quien use el framework no debería ver ninguna clase**: solo objetos prototipados, con la sintaxis que el enunciado fija.

Hay una sola clase que el usuario toca: `PrototypedObject`, para crear el primer objeto (`PrototypedObject.new`). Es el punto de entrada; de ahí en adelante, todo son objetos que se configuran y se copian. Es la misma relación que tenés con `attr_accessor`: por dentro es un método, pero quien lo usa lo ve como una palabra del lenguaje.

---

## 4. 🔴 Las secciones 1 a 3 del enunciado, frase por frase

El enunciado arranca con tres secciones cortas antes del código. Vocabulario de la materia, y tres avisos que después pesan. Frase por frase, definiendo cada palabra la primera vez que aparece.

### Sección 1: qué se pide hacer

> 📄 **El enunciado dice** (1. *Objetivos y recomendaciones*):
> *"Desarrollar un framework en objetos de complejidad media."*

Un **framework** es, acá, un conjunto de clases y métodos que se agregan a Ruby para que cualquier programa pueda usarlos: no un programa que hace algo, sino una herramienta con la que otros programas definen y usan prototipos. Nuestro framework es el archivo `clase06-prototype.rb`. "En objetos" quiere decir que, por dentro, lo diseñamos con las buenas prácticas de objetos: responsabilidades repartidas, sin código repetido.

> 📄 **El enunciado dice** (1., tercer punto):
> *"La solución debe presentar buenas prácticas de diseño, tales como evitar repetición de código, buena distribución de responsabilidades, manejo adecuado de excepciones, etc."*

**En criollo:** el framework se corrige como diseño, no solo como "anda o no anda". Cada pieza en el lugar que le corresponde, y errores claros cuando se usa mal. Eso va a aparecer en decisiones chicas (qué devolver cuando piden una propiedad que no existe, en el Módulo 2) y grandes (dónde vive el comportamiento compartido, en el Módulo 6).

Los días que menciona la sección ("12 y 19 de Septiembre") son del año en que este ejercicio fue TP. Hoy es un ejercicio integrador de clase; las fechas que importan son las de la planificación de la cátedra.

### Sección 2: la idea

> 📄 **El enunciado dice** (2. *Introducción*):
> *"En Ruby existen, por defecto, dos formas de definir y compartir comportamiento entre los distintos objetos de nuestro sistema: Clases y Mixins (modules)."*

Las dos las conocés: la clase (clase01) y el mixin que se incluye en una clase (clase02). Son los dos proveedores de comportamiento de Ruby, y los dos son "cosas que no son objetos comunes".

> 📄 **El enunciado dice** (2., continuación):
> *"Pero debido a sus características dinámicas y a su metamodelo maleable, es posible alterar las formas de recibir comportamiento e incluso agregar nuevas."*

**Dinámico** quiere decir que las cosas pasan en tiempo de ejecución: definir un método, abrir una clase, agregar una variable. **Metamodelo** es el modelo de Ruby mismo (clases, autoclases, módulos, el lookup) hecho de objetos a los que se les mandan mensajes: es el diagrama de clase03. **Maleable** quiere decir que ese modelo se puede tocar desde el programa. Las tres cosas juntas son la metaprogramación de clase03 y clase04, y son lo que hace posible este ejercicio.

> 📄 **El enunciado dice** (2., cierre):
> *"El objetivo de este trabajo práctico es, entonces, implementar y analizar una nueva forma de definir y compartir comportamiento en Ruby, puntualmente a través de prototipos."*

**En criollo:** agregarle a Ruby una tercera forma de compartir comportamiento, al lado de clases y mixins: la de la sección 2 de este módulo. Fijate el verbo doble, "implementar **y analizar**": no alcanza con que ande; hay que poder decir qué hace en los casos raros.

### Sección 3: cómo se va a pedir

> 📄 **El enunciado dice** (3. *Comportamiento esperado*):
> *"Los requerimientos de cómo debe comportarse el nuevo sistema serán proporcionados en forma de código. La intención es que lo que se implemente pueda funcionar, pero no se busca acotar las posibles implementaciones."*

**En criollo:** el enunciado no explica qué hacer; **muestra código que tiene que andar**. Cada bloque de código de las partes 4.1 a 4.4 es un requerimiento: "esto, escrito exactamente así, tiene que funcionar". Y hay libertad para decidir cómo por dentro. Dos consecuencias para esta clase:

- **La sintaxis del enunciado se respeta tal cual.** Si dice `guerrero.set_method(:atacar_a, proc { … })`, el método recibe un **proc como argumento**, no un bloque pegado al mensaje. Esa diferencia la viste en clase04, y acá importa: un proc es un objeto que ocupa lugar de parámetro; un bloque no. Si escribís `set_method(:atacar_a) { … }` cuando el enunciado pasa un proc, no estás cumpliendo el requerimiento.
- **Donde el enunciado no decide, decidimos nosotros**, y el módulo dice por qué. El roadmap lista las cuatro decisiones grandes.

> 📄 **El enunciado dice** (3., segundo párrafo):
> *"Luego, cada grupo deberá analizar en detalle las características particulares de su implementación, mostrando cómo se comporta en casos de conflictos y en relación con los elementos del metamodelo existentes."*

**En criollo:** hay que saber qué pasa cuando dos prototipos definen el mismo método (conflicto, Módulo 9), y qué pasa con lo que Ruby ya trae, como `to_s` o `respond_to?`, cuando se cruza con nuestros prototipos (Módulos 6 y 10). Esas preguntas son las que un docente hace cuando corrige.

> 📄 **El enunciado dice** (3., cierre):
> *"El comportamiento esperado es el requerimiento definido, y debe estar testeado con pruebas unitarias automáticas, pero no debe probarse sólo eso."*

**En criollo:** los `expect(...)` del enunciado se convierten en tests, y se agregan tests propios para los casos que el enunciado no escribe (el clon que no ve métodos nuevos, un mensaje que nadie entiende, un ciclo de prototipos). Cada módulo cierra con los tests de su pieza.

### Sección 4, el preámbulo: cómo están armadas las partes

> 📄 **El enunciado dice** (4. *Partes*):
> *"Las partes están pensadas para guiarlos en el desarrollo […] También cada parte va elaborando sobre la anterior, por lo que es recomendable ir resolviendo los puntos en el orden propuesto."*

Es la razón del orden de esta clase: los módulos siguen las partes, y dentro de cada parte, las líneas del enunciado. Nada de la 4.3 se entiende sin la 4.1.

Con esto, el preámbulo está leído. Lo que sigue es lo mismo, pero mirando el código que queremos que exista.

---

## 5. 🔴 Lo que queremos poder escribir

> **Regla.** El objetivo de la parte 4.1 es que exista un objeto al que se le puedan agregar propiedades y métodos **uno por uno, por mensajes**, sin que ese comportamiento venga de ninguna clase; que se pueda clonar; y que pueda tener otro objeto como prototipo.

Así se ve el primer bloque de requerimientos. Es el primer código de 4.1, adelantado acá porque define el contrato de los Módulos 2, 3 y 4. Todavía no existe; si lo ejecutás hoy, falla en la primera línea:

> 📄 **El enunciado dice** (4.1 *Prototipos programáticos*, primer bloque de código):

```ruby
guerrero = PrototypedObject.new
# => NameError: uninitialized constant PrototypedObject      (hoy; al final del Módulo 2 esta línea anda)

guerrero.set_property(:energia, 100)                   # una propiedad: nombre y valor
expect(guerrero.get_property(:energia)).to eq(100)     # ← la línea que anotaste a mano
expect(guerrero.energia).to eq(100)                    # y la propiedad también como MENSAJE

guerrero.set_property(:potencial_defensivo, 10)
guerrero.set_property(:potencial_ofensivo, 30)

guerrero.set_method(:atacar_a,                         # un método: nombre y un PROC con el cuerpo
  proc {
  |otro_guerrero|
  if(otro_guerrero.potencial_defensivo < self.potencial_ofensivo)
    otro_guerrero.recibe_danio(self.potencial_ofensivo - otro_guerrero.potencial_defensivo)
  end
  });

guerrero.set_method(:recibe_danio, proc {...})         # el cuerpo queda a tu criterio

otro_guerrero = guerrero.clone #clone es un metodo que ya viene definido en Ruby

guerrero.atacar_a otro_guerrero

expect(otro_guerrero.energia).to eq(80)
```

**En criollo, línea por línea:**

- `PrototypedObject.new` es la única clase que el usuario toca (sección 3). Crea un objeto **vacío**: sin propiedades, sin métodos. Todo lo demás se le agrega después. Esa es la forma de trabajar con prototipos: armás el objeto de a una pieza, y cuando funciona, lo copiás.
- `set_property(:energia, 100)` guarda una **propiedad**: un dato con nombre, propio de ese objeto. El nombre llega como símbolo. `get_property(:energia)` lo devuelve. Y `guerrero.energia`, sin `get_property`, también tiene que devolverlo: la propiedad tiene que poder pedirse **como un mensaje**. Eso ya es una decisión de diseño (Módulo 2).
- `set_method(:atacar_a, proc { … })` guarda un **método**: un nombre y un proc con el cuerpo. Fijate que adentro del proc aparece `self.potencial_ofensivo`: cuando ese proc se ejecute, `self` tiene que ser **el guerrero que recibió `atacar_a`**, no el lugar donde el proc fue escrito. Sabés de clase04 que un proc recuerda el `self` de donde nació; acá hay que garantizar que, al ejecutarse, `self` sea el receptor. Cómo se logra es el Módulo 3.
- `recibe_danio` lo escribís vos: le resta a `energia` lo que recibe.
- `guerrero.clone` es el `clone` que Ruby ya tiene. El enunciado lo aclara a propósito: **no hay que inventar uno**, hay que ver qué hace el de Ruby con un objeto de estos y si alcanza. No alcanza del todo; es el Módulo 4.
- `guerrero.atacar_a otro_guerrero`: 30 de ataque contra 10 de defensa, le saca 20 al otro. De 100 a **80**. Si da 80, los Módulos 2, 3 y 4 están bien.

El enunciado llama a esta parte "sin azúcar sintáctico". **Azúcar sintáctico** es una forma más cómoda de escribir algo que ya se podía escribir de otra manera, sin agregar poder: `guerrero.energia = 100` en vez de `guerrero.set_property(:energia, 100)`. Primero se construye lo de abajo, con la sintaxis incómoda; el azúcar llega en 4.3.

### El proc, verbatim

Una línea del enunciado merece verse al microscopio, porque es de las que se escriben mal en el TP:

```ruby
guerrero.set_method(:atacar_a, proc { |otro_guerrero| … })
```

`set_method` recibe **dos argumentos**: el símbolo y el proc. No recibe un bloque. Son dos sintaxis distintas, y solo una cumple el enunciado:

| Escribís | Ruby entiende | Sale |
|---|---|---|
| `set_method(:atacar_a, proc { \|o\| … })` | dos argumentos: un símbolo y un objeto `Proc` | lo que pide el enunciado |
| `set_method(:atacar_a) { \|o\| … }` | un argumento (el símbolo) y un bloque pegado al mensaje; el bloque no cuenta como argumento | si `set_method` está escrito para dos argumentos: `ArgumentError: wrong number of arguments (given 1, expected 2)` |

Esto decide cómo se escribe `set_method` en el Módulo 3: `def set_method(selector, bloque)`, con dos parámetros comunes, y no `def set_method(selector, &bloque)`.

---

## 6. 🔴 Dónde vive hoy lo que un objeto sabe, y dónde va a vivir

> **Regla.** En Ruby, lo que un objeto **tiene** (su estado) vive en él, en variables `@`. Lo que un objeto **sabe hacer** (sus métodos) vive afuera de él: en su autoclase o en su clase. Un objeto prototipado necesita que **las dos cosas sean consultables objeto por objeto**, porque otro objeto va a venir a preguntarle.

Esto es lo que ya sabés, dicho desde el punto de vista del problema:

```
   Ruby hoy                                  Lo que necesitamos
   ────────                                  ──────────────────
   objeto ──@energia──► 100                  objeto ──propiedades──► { energia: 100, … }
          │                                         │
          │ lookup                                  │ lookup PROPIO
          ▼                                         ▼
   autoclase ─► clase ─► mixins ─► Object    sus métodos ─► su prototipo ─► el prototipo de ese ─► …
                                                                     (otros OBJETOS, no clases)
```

Dos cosas tienen que poder pasar, y ninguna pasa hoy:

1. **Mirar adentro de sí.** Cuando a `martin` le mandan `saludar`, Martín tiene que poder responder "¿lo tengo yo?" mirando lo que le agregaron con `set_method`. Ruby lo resuelve por él mirando la autoclase; eso puede alcanzar o no (Módulo 3 y Módulo 5).
2. **Mirar adentro de otro.** Si no lo tiene, Martín tiene que ir a **Juan**, y Juan tiene que poder contestar lo mismo. El lookup de Ruby no da ese paso. Hay que construirlo (Módulo 5).

Y hay una pregunta que conviene tener en la cabeza desde ahora, aunque la respuesta llegue en el Módulo 6: **¿dónde se define el comportamiento de `PrototypedObject`?** `set_property`, `set_method`, el lookup propio… la respuesta obvia es "adentro de la clase `PrototypedObject`". Es razonable, y es lo que vamos a hacer primero. El enunciado cierra la 4.1 con una línea que la cuestiona:

> 📄 **El enunciado dice** (4.1, último bloque):
> ```ruby
> class Object
>   include Prototyped
> end
> ```

**En criollo:** al final, el comportamiento "prototipable" tiene que ser un **mixin** (`Prototyped`), para que cualquier objeto de Ruby, no solo los `PrototypedObject`, pueda tener propiedades, métodos y prototipo. Guardá esa pregunta. Cada vez que escribamos un método en `PrototypedObject`, va a valer preguntarse si en realidad es del mixin.

> 🎯 **Para el parcial, si te preguntan** qué le falta a Ruby para soportar prototipos, si ya tiene autoclases:
> Un objeto puede tener métodos propios en su autoclase, pero el method lookup de Ruby sube por clases y mixins y nunca pasa de un objeto a otro objeto. Para prototipos hace falta que un objeto, al no entender un mensaje, lo busque en otro objeto (su prototipo), y que ese otro pueda contestar mirando lo que él mismo tiene. Esa búsqueda entre objetos hay que construirla; Ruby no la trae.

---

## Checkpoint del Módulo 1

Contestá por escrito, sin mirar el módulo. Las respuestas se revisan en el chat.

1. Definí con tus palabras *prototipo*, *derivado* y *cadena de prototipos*, y ubicalos en el ejemplo de Juan y Martín.
2. ¿Qué dos proveedores de comportamiento tiene Ruby por defecto, según el enunciado? ¿Qué tienen en común que un prototipo no tiene?
3. `juan.define_singleton_method(:despedirse) { "chau" }` y después `martin.despedirse` explota. Describí el recorrido que hace el lookup de `martin` y decí en qué punto le faltaría una flecha para que no explotara.
4. ¿Por qué el enunciado dice que la clase solo construye y el prototipo "puede ser usado"? Dá un ejemplo con `Alumno` y `juan`.
5. "Quien use el framework no debería ver clases." ¿Cuál es la única clase que sí ve, y para qué?
6. ¿Qué quiere decir que los requerimientos "serán proporcionados en forma de código"? ¿Qué consecuencia tiene para `set_method(:atacar_a, proc { … })`?
7. Explicá la diferencia entre pasarle a `set_method` un proc y pasarle un bloque. ¿Cuál pide el enunciado y cómo se nota en la firma del método?
8. Dentro del proc de `atacar_a` aparece `self.potencial_ofensivo`. ¿Quién tiene que ser `self` cuando ese proc se ejecute? ¿Quién es `self` adentro de un proc si no hacés nada especial?
9. ¿Qué es azúcar sintáctico? Dá el ejemplo del enunciado.
10. ¿Qué dos cosas tiene que poder hacer un objeto prototipado que un objeto de Ruby no hace solo?

## Qué viene en el Módulo 2

Las tres primeras líneas de la parte 4.1: `PrototypedObject.new`, `set_property` y `get_property`, y que `guerrero.energia` responda. Hay tres lugares donde una propiedad puede vivir, y elegir uno es la primera decisión de diseño del framework: la vas a tomar viendo qué se gana y qué se pierde con cada una. Y vas a ver la trampa más común de este ejercicio: un diccionario que nadie inicializó.

**FIN DEL MÓDULO 1**
