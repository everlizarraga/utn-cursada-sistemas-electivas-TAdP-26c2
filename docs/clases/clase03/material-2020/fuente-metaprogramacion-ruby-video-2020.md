# Metaprogramación en Ruby — Metamodelo de Ruby (capturas video 2020)

> Conversión fiel a Markdown de capturas-video-2020-slides.pptx (20 slides).

**Notas de conversión**

- El original no es un PDF sino un `.pptx` de 20 slides, cada una compuesta por una única imagen PNG (captura de pantalla de una videoclase). No hay texto extraíble ni notas del orador: toda la transcripción es visual, slide por slide.
- Se buscaron hipervínculos en las relaciones del `.pptx`: no existen enlaces externos.
- En la mayoría de las capturas aparece el cursor del mouse (slides 1, 2, 3, 4, 7, 8, 11–19). No es contenido y se omite.
- La slide 12 es idéntica a la 11 (solo cambia la posición del cursor). La slide 10 repite el diagrama de la 7 con otro título. Se transcriben completas por cobertura total.
- Ortografía del original transcripta tal cual: faltan tildes y signos de apertura en "Que es la Metaprogramación?", "para que sirve", "Para que se usa", "Proxima Clase", "como seguir?".
- En los diagramas, los nombres "Nil Class" y "Basic Object" aparecen con espacio; se transcriben así.
- Colores de los diagramas convertidos a etiquetas: **(azul)** = superclass, **(rojo)** = class, **(verde)** = singleton_class, **(magenta)** = mixin/class. Dentro de las cajas, los nombres en magenta se marcan con `[m]` (mixin) y los naranjas son clases.
- La firma de la fotografía de la slide 1 es solo parcialmente legible ("Shane Will…").
- El deck no lleva número de clase; el nombre del archivo se eligió por tema.

---

## Slide 1 — Metaprogramación en Ruby

- ¿Qué es la metaprogramación y para que sirve?
- Tipos de Metaprogramación
- Metaprogramación en Ruby
- Metamodelo en Ruby

*(Imagen a la derecha: fotografía en blanco y negro de dos brazos con articulaciones mecánicas —tuercas, un rodamiento en el antebrazo, cables— cuyas manos sostienen un destornillador y una llave mientras manipulan un pequeño mecanismo electrónico con cables sobre una mesa de trabajo. Firma parcialmente legible en la esquina inferior derecha: "Shane Will…".)*

---

## Slide 2 — Que es la Metaprogramación?

Proceso o la práctica por la cual escribimos programas que generan, manipulan o utilizan otros programas.

<u>Ejemplos</u>

- Compiladores
- Formateador de Código
- Herramientas de generación de documentación

---

## Slide 3 — Para que se usa la Metaprogramación?

- Desarrollo de frameworks y herramientas
- Dominio de los frameworks

Ejemplos

- ORMs
- Testing (JUnit)
- Documentador de código
- Analizadores de código
- Code Coverage (Coveralls)

---

## Slide 4 — Reflection

"Metaprogramamos" en el mismo lenguaje que los programas.

➔ Tipos de Reflection

- Introspection
- Self-modification
- Intercession =>

*(Una llave `}` agrupa "Introspection" y "Self-modification" con el texto: "Veremos estas dos en la cursada".)*

*(Imagen arriba a la derecha: fotografía de un espejo retrovisor lateral de un auto, con la palabra "MIRRORS" reflejada al revés en la parte superior del espejo y una carretera reflejada.)*

*(Imagen debajo de "Intercession =>": tapa del libro "The Art of the Metaobject Protocol", de Gregor Kiczales, Jim des Rivières y Daniel G. Bobrow, con borde ornamentado estilo manuscrito medieval, letra capital iluminada y una miniatura a la derecha.)*

---

## Slide 5 — Metaprogramación en Ruby

- Vamos a usar de nuevo el modelo de los guerreros... de nuevo
- Pero... vamos a usarlo para mostrar introspection y self-modification
- Pry/Irb

---

## Slide 6 — Introspection en Ruby (práctico)

- métodos y clase
- bound/unbound method
- variables de instancias

---

## Slide 7 — Introspection en Ruby (práctico)

**Leyenda:** superclass ■ (azul) · class ■ (rojo) · mixin/class ■ (magenta) · ✱ Flechas que apuntan a Class

```
                                                            ┌─(rojo)─┐
                                                            │        ▼
                                                        ┌───┴─────────┐
                                                        │    Class    │
                                    ✱                   └─────────────┘
                                    ▲ (rojo)
                            ┌───────┴────────┐
                            │  Basic Object  │
                            └───────▲────────┘
                                    │ (azul)
            ✱ ◄──(rojo)─────┌───────┴────────┐
                            │  Kernel[m] <-  │
                            │  Object        │
                            └───────▲────────┘
                                    │ (azul)
            ✱ ◄──(rojo)─────┌───────┴────────┐
  (marine) ──────(rojo)────►│  Atacante[m] <-│
                            │  Defensor[m] <-│
                            │  Guerrero      │
                            └───────▲────────┘
                                    │ (azul)
            ✱ ◄──(rojo)─────┌───────┴────────┐
  (gknight) ─────(rojo)────►│   Espadachin   │
                            └────────────────┘
```

*Descripción del diagrama:* columna vertical de cajas, de abajo hacia arriba: **Espadachin** → **Atacante <- Defensor <- Guerrero** → **Kernel <- Object** → **Basic Object**, unidas por flechas azules (superclass) que apuntan hacia arriba. En las cajas compuestas, Atacante, Defensor y Kernel están en magenta (mixin) y Guerrero y Object en naranja (clase). Dos óvalos de instancias: **marine** con flecha roja (class) hacia la caja Atacante/Defensor/Guerrero, y **gknight** con flecha roja hacia Espadachin. Cada una de las cuatro cajas tiene una flecha roja saliente hacia un asterisco ✱ (apunta a Class). Aparte, arriba a la derecha, la caja **Class** con una flecha roja que sale de ella y vuelve a ella misma (loop).

---

## Slide 8 — Self-Modification en Ruby (práctico)

- Open Classes
- Duck typing
  - *...if it walks like a duck and talks like a duck, it's a duck, right?*
- Monkey patching
  - *if it walks like a monkey and talks like a monkey, it's a monkey, right? So if this monkey is not giving you the noise that you want, you've got to just punch that monkey until it returns what you expect.*

*(Imagen a la derecha, junto a "Duck typing": foto de un perro blanco esponjoso con un pico de pato de juguete celeste puesto en el hocico; en la esquina superior derecha el texto "Quaak.".)*

*(Imagen abajo a la derecha, junto a "Monkey patching": dibujo caricaturesco de un mono azul con expresión furiosa, dientes apretados, señalando con el dedo.)*

---

## Slide 9 — Metamodelo de Ruby

- Vamos a empezar de a poco descubriendo el metamodelo de Ruby
- Empezaremos por el modelo que tenemos de Guerreros y Espadachines

---

## Slide 10 — Metamodelo de Ruby

**Leyenda:** superclass ■ (azul) · class ■ (rojo) · mixin/class ■ (magenta) · ✱ Flechas que apuntan a Class

```
                                                            ┌─(rojo)─┐
                                                            │        ▼
                                                        ┌───┴─────────┐
                                                        │    Class    │
                                    ✱                   └─────────────┘
                                    ▲ (rojo)
                            ┌───────┴────────┐
                            │  Basic Object  │
                            └───────▲────────┘
                                    │ (azul)
            ✱ ◄──(rojo)─────┌───────┴────────┐
                            │  Kernel[m] <-  │
                            │  Object        │
                            └───────▲────────┘
                                    │ (azul)
            ✱ ◄──(rojo)─────┌───────┴────────┐
  (marine) ──────(rojo)────►│  Atacante[m] <-│
                            │  Defensor[m] <-│
                            │  Guerrero      │
                            └───────▲────────┘
                                    │ (azul)
            ✱ ◄──(rojo)─────┌───────┴────────┐
  (gknight) ─────(rojo)────►│   Espadachin   │
                            └────────────────┘
```

*Descripción del diagrama:* mismo diagrama que la slide 7. Columna vertical: **Espadachin** → **Atacante <- Defensor <- Guerrero** → **Kernel <- Object** → **Basic Object** con flechas azules (superclass) hacia arriba; Atacante, Defensor y Kernel en magenta (mixin), Guerrero y Object en naranja. Instancias **marine** (flecha roja a Atacante/Defensor/Guerrero) y **gknight** (flecha roja a Espadachin). Cada caja tiene flecha roja a ✱. Aparte, **Class** con loop rojo sobre sí misma.

---

## Slide 11 — Metamodelo de Ruby

**Leyenda:** superclass ■ (azul) · class ■ (rojo) · mixin/class ■ (magenta) · ✱ Flechas que apuntan a Class

```
                                                     ┌────────(azul)──────────┐
                                                     │                        │
                                                     │             ┌──────────┴──┐
                                                     │             │   Module    │
                                                     │             └──┬───────▲──┘
                                                     │          (rojo)│  (azul)│
                                                     │            ┌───▼────────┴┐
                                                     │  ┌─(rojo)─►│    Class    │
                                                     │  └─────────┤             │
      ✱                                     ✱        │            └─────────────┘
      ▲ (rojo)                              ▲ (rojo) │
  ┌───┴──────────┐              ┌───────────┴────┐   │
  │  Nil Class   │◄──(rojo)─┐   │  Basic Object  │   │
  └───┬──────────┘          │   └───┬────▲───────┘   │
      │(azul)          [nil]◄- - -(azul, punteada)   │
      │                     │           │ (azul)     │
      │         ✱ ◄──(rojo)─│───┌───────┴────────┐   │
      └─────────────────────┴──►│  Kernel[m] <-  │◄──┘
                                │  Object        │
                                └───────▲────────┘
                                        │ (azul)
                ✱ ◄──(rojo)─────┌───────┴────────┐
  (marine) ──────────(rojo)────►│  Atacante[m] <-│
                                │  Defensor[m] <-│
                                │  Guerrero      │
                                └───────▲────────┘
                                        │ (azul)
                ✱ ◄──(rojo)─────┌───────┴────────┐
  (gknight) ─────────(rojo)────►│   Espadachin   │
                                └────────────────┘
```

*Descripción del diagrama:* se mantiene la columna central de la slide 10 (Espadachin → Atacante/Defensor/Guerrero → Kernel/Object → Basic Object, flechas azules; marine y gknight con flechas rojas; cada caja con flecha roja a ✱). Se agregan:
- A la izquierda, la caja **Nil Class**, con flecha roja saliente a ✱ y flecha azul (superclass) hacia **Kernel <- Object**.
- Una caja pequeña **nil** entre Nil Class y Basic Object: de **nil** sale una flecha roja (class) hacia **Nil Class**; de **Basic Object** sale una flecha azul **punteada** (superclass) hacia **nil**.
- Arriba a la derecha, las cajas **Module** y **Class**: flecha roja de Module a Class (class); flecha azul de Class a Module (superclass); loop rojo de Class sobre sí misma; y una flecha azul larga de Module que baja hasta **Kernel <- Object** (superclass de Module es Object).

---

## Slide 12 — Metamodelo de Ruby

**Leyenda:** superclass ■ (azul) · class ■ (rojo) · mixin/class ■ (magenta) · ✱ Flechas que apuntan a Class

```
                                                     ┌────────(azul)──────────┐
                                                     │                        │
                                                     │             ┌──────────┴──┐
                                                     │             │   Module    │
                                                     │             └──┬───────▲──┘
                                                     │          (rojo)│  (azul)│
                                                     │            ┌───▼────────┴┐
                                                     │  ┌─(rojo)─►│    Class    │
                                                     │  └─────────┤             │
      ✱                                     ✱        │            └─────────────┘
      ▲ (rojo)                              ▲ (rojo) │
  ┌───┴──────────┐              ┌───────────┴────┐   │
  │  Nil Class   │◄──(rojo)─┐   │  Basic Object  │   │
  └───┬──────────┘          │   └───┬────▲───────┘   │
      │(azul)          [nil]◄- - -(azul, punteada)   │
      │                     │           │ (azul)     │
      │         ✱ ◄──(rojo)─│───┌───────┴────────┐   │
      └─────────────────────┴──►│  Kernel[m] <-  │◄──┘
                                │  Object        │
                                └───────▲────────┘
                                        │ (azul)
                ✱ ◄──(rojo)─────┌───────┴────────┐
  (marine) ──────────(rojo)────►│  Atacante[m] <-│
                                │  Defensor[m] <-│
                                │  Guerrero      │
                                └───────▲────────┘
                                        │ (azul)
                ✱ ◄──(rojo)─────┌───────┴────────┐
  (gknight) ─────────(rojo)────►│   Espadachin   │
                                └────────────────┘
```

*Descripción del diagrama:* idéntico al de la slide 11. Columna central Espadachin → Atacante/Defensor/Guerrero → Kernel/Object → Basic Object (azul); marine y gknight (rojo); flechas rojas a ✱ desde cada caja; **Nil Class** (rojo a ✱, azul a Kernel/Object); **nil** (rojo a Nil Class; Basic Object → nil en azul punteado); **Module** y **Class** arriba a la derecha (Module → Class rojo; Class → Module azul; loop rojo de Class; Module → Kernel/Object azul).

---

## Slide 13 — Metamodelo de Ruby (Introduciendo EigenClasses)

**Leyenda:** superclass ■ (azul) · class ■ (rojo) · singleton_class ■ (verde) · mixin/class ■ (magenta) · ✱ Flechas que apuntan a Class

```
                                                     ┌────────(azul)──────────┐
                                                     │                        │
                                                     │             ┌──────────┴──┐
                                                     │             │   Module    │
                                                     │             └──┬───────▲──┘
                                                     │          (rojo)│  (azul)│
                                                     │            ┌───▼────────┴┐
                                                     │  ┌─(rojo)─►│    Class    │
                                                     │  └─────────┤             │
      ✱                                     ✱        │            └─────────────┘
      ▲ (rojo)                              ▲ (rojo) │
  ┌───┴──────────┐              ┌───────────┴────┐   │
  │  Nil Class   │◄──(rojo)─┐   │  Basic Object  │   │
  └───┬──────────┘          │   └───┬────▲───────┘   │
      │(azul)          [nil]◄- - -(azul, punteada)   │
      │                     │           │ (azul)     │
      │         ✱ ◄──(rojo)─│───┌───────┴────────┐   │
      └─────────────────────┴──►│  Kernel[m] <-  │◄──┘
                                │  Object        │
                                └───────▲────────┘
                                        │ (azul)
                ✱ ◄──(rojo)─────┌───────┴────────┐
  (marine) ──────────(rojo)────►│  Atacante[m] <-│
                                │  Defensor[m] <-│
                                │  Guerrero      │
                                └───────▲────────┘
                                        │ (azul)
                ✱ ◄──(rojo)─────┌───────┴────────┐          ╔═══════════════╗
  (gknight) ─────────(rojo)────►│   Espadachin   │─(verde)─►║  #Espadachin  ║──(rojo)──► ✱
                                └────────────────┘          ╚═══════════════╝
```

*Descripción del diagrama:* igual al de la slide 12, con la leyenda ampliada (se agrega **singleton_class** en verde) y un elemento nuevo: a la derecha de **Espadachin** aparece la caja verde **#Espadachin** (singleton class). De Espadachin sale una flecha verde (singleton_class) hacia #Espadachin, y de #Espadachin sale una flecha roja (class) hacia ✱.

---

## Slide 14 — Singleton Class

**Leyenda:** superclass ■ (azul) · class ■ (rojo) · singleton_class ■ (verde) · mixin/class ■ (magenta) · ✱ Flechas que apuntan a Class

```
                                                     ┌────────(azul)──────────┐
                                                     │                        │
                                                     │             ┌──────────┴──┐
                                                     │             │   Module    │
                                                     │             └──┬───────▲──┘
                                                     │          (rojo)│  (azul)│
                                                     │            ┌───▼────────┴┐
                                                     │  ┌─(rojo)─►│    Class    │
                                                     │  └─────────┤             │
      ✱                                     ✱        │            └─────────────┘
      ▲ (rojo)                              ▲ (rojo) │
  ┌───┴──────────┐              ┌───────────┴────┐   │
  │  Nil Class   │◄──(rojo)─┐   │  Basic Object  │   │
  └───┬──────────┘          │   └───┬────▲───────┘   │
      │(azul)          [nil]◄- - -(azul, punteada)   │
      │                     │           │ (azul)     │
      │         ✱ ◄──(rojo)─│───┌───────┴────────┐   │
      └─────────────────────┴──►│  Kernel[m] <-  │◄──┘
                                │  Object        │
                  ✱             └───────▲────────┘
                  ▲ (rojo)              │ (azul)
             ╔════╩════╗ ✱ ◄──(rojo)────┌───────┴────────┐
  (marine)─(verde)─►║ #marine ║         │  Atacante[m] <-│
      └──────────(rojo)────────────────►│  Defensor[m] <-│
                                        │  Guerrero      │
                                        └───────▲────────┘
                  ✱                             │ (azul)
                  ▲ (rojo)                      │
             ╔════╩═════╗ ✱ ◄──(rojo)───┌───────┴────────┐          ╔═══════════════╗
  (gknight)─(verde)─►║ #gknight ║        │   Espadachin   │─(verde)─►║  #Espadachin  ║──(rojo)──► ✱
      └──────────(rojo)────────────────►└────────────────┘          ╚═══════════════╝
```

*Descripción del diagrama:* igual al de la slide 13, con dos singleton classes nuevas para las instancias:
- De **marine** sale una flecha verde (singleton_class) hacia la caja verde **#marine**; de #marine sale una flecha roja (class) hacia ✱. marine conserva su flecha roja hacia Atacante/Defensor/Guerrero.
- De **gknight** sale una flecha verde hacia la caja verde **#gknight**; de #gknight sale una flecha roja hacia ✱. gknight conserva su flecha roja hacia Espadachin.
- Se mantiene **#Espadachin** (verde desde Espadachin, rojo hacia ✱).

---

## Slide 15 — Metamodelo de Ruby... el verdadero method lookup...

**Leyenda:** superclass ■ (azul) · class ■ (rojo) · singleton_class ■ (verde) · mixin/class ■ (magenta) · ✱ Flechas que apuntan a Class

```
                                                     ┌────────(azul)──────────┐
                                                     │                        │
                                                     │             ┌──────────┴──┐
                                                     │             │   Module    │
                                                     │             └──┬───────▲──┘
                                                     │          (rojo)│  (azul)│
                                                     │            ┌───▼────────┴┐
                                                     │  ┌─(rojo)─►│    Class    │
                                                     │  └─────────┤             │
      ✱                                     ✱        │            └─────────────┘
      ▲ (rojo)                              ▲ (rojo) │
  ┌───┴──────────┐              ┌───────────┴────┐   │
  │  Nil Class   │◄──(rojo)─┐   │  Basic Object  │   │
  └───┬──────────┘          │   └───┬────▲───────┘   │
      │(azul)          [nil]◄- - -(azul, punteada)   │
      │                     │           │ (azul)     │
      │         ✱ ◄──(rojo)─│───┌───────┴────────┐   │
      └─────────────────────┴──►│  Kernel[m] <-  │◄──┘
                                │  Object        │
                  ✱             └───────▲────────┘
                  ▲ (rojo)              │ (azul)
             ╔════╩════╗ ✱ ◄──(rojo)────┌───────┴────────┐
  (marine)─(verde)─►║ #marine ║─(azul)─►│  Atacante[m] <-│
      └──────────(rojo)────────────────►│  Defensor[m] <-│
                                        │  Guerrero      │
                                        └───────▲────────┘
                  ✱                             │ (azul)
                  ▲ (rojo)                      │
             ╔════╩═════╗ ✱ ◄──(rojo)───┌───────┴────────┐          ╔═══════════════╗
  (gknight)─(verde)─►║ #gknight ║─(azul)─►│   Espadachin   │─(verde)─►║  #Espadachin  ║──(rojo)──► ✱
      └──────────(rojo)────────────────►└────────────────┘          ╚═══════════════╝
```

*Descripción del diagrama:* igual al de la slide 14, con dos flechas azules (superclass) nuevas: de **#marine** hacia **Atacante <- Defensor <- Guerrero**, y de **#gknight** hacia **Espadachin**. Todo lo demás se mantiene (columna central, Nil Class, nil, Module/Class, #Espadachin, flechas rojas y verdes).

---

## Slide 16 — Metamodelo de Ruby

**Leyenda:** superclass ■ (azul) · class ■ (rojo) · singleton_class ■ (verde) · mixin/class ■ (magenta) · ✱ Flechas que apuntan a Class

```
                                                     ┌────────(azul)──────────┐
                                                     │                        │
                                                     │             ┌──────────┴──┐
                                                     │             │   Module    │
                                                     │             └──┬───────▲──┘
                                                     │          (rojo)│  (azul)│
                                                     │            ┌───▼────────┴┐
                                                     │  ┌─(rojo)─►│    Class    │
                                                     │  └─────────┤             │
      ✱                                     ✱        │            └─────────────┘
      ▲ (rojo)                              ▲ (rojo) │
  ┌───┴──────────┐              ┌───────────┴────┐   │
  │  Nil Class   │◄──(rojo)─┐   │  Basic Object  │   │
  └───┬──────────┘          │   └───┬────▲───────┘   │
      │(azul)          [nil]◄- - -(azul, punteada)   │
      │                     │           │ (azul)     │
      │         ✱ ◄──(rojo)─│───┌───────┴────────┐   │
      └─────────────────────┴──►│  Kernel[m] <-  │◄──┘
                                │  Object        │
                  ✱             └───────▲────────┘
                  ▲ (rojo)              │ (azul)
             ╔════╩════╗ ✱ ◄──(rojo)────┌───────┴────────┐          ╔═══════════════╗
  (marine)─(verde)─►║ #marine ║─(azul)─►│  Atacante[m] <-│─(verde)─►║   #Guerrero   ║──(rojo)──► ✱
      └──────────(rojo)────────────────►│  Defensor[m] <-│          ╚═══════▲═══════╝
                                        │  Guerrero      │                  │ (azul)
                                        └───────▲────────┘                  │
                  ✱                             │ (azul)                    │
                  ▲ (rojo)                      │                           │
             ╔════╩═════╗ ✱ ◄──(rojo)───┌───────┴────────┐          ╔═══════╩═══════╗
  (gknight)─(verde)─►║ #gknight ║─(azul)─►│   Espadachin   │─(verde)─►║  #Espadachin  ║──(rojo)──► ✱
      └──────────(rojo)────────────────►└────────────────┘          ╚═══════════════╝
```

*Descripción del diagrama:* igual al de la slide 15, con la singleton class de Guerrero: de la caja **Atacante <- Defensor <- Guerrero** sale una flecha verde hacia la caja verde **#Guerrero**; de #Guerrero sale una flecha roja hacia ✱; y de **#Espadachin** sale una flecha azul (superclass) hacia **#Guerrero**. Todo lo demás se mantiene.

---

## Slide 17 — Metamodelo de Ruby

**Leyenda:** superclass ■ (azul) · class ■ (rojo) · singleton_class ■ (verde) · mixin/class ■ (magenta) · ✱ Flechas que apuntan a Class

```
                                                     ┌────────(azul)──────────┐
                                                     │                        │
                                                     │             ┌──────────┴──┐
                                                     │             │   Module    │
                                                     │             └──┬───────▲──┘
                                                     │          (rojo)│  (azul)│
                                                     │            ┌───▼────────┴┐
                                                     │  ┌─(rojo)─►│    Class    │
                                                     │  └─────────┤             │
      ✱                                     ✱        │            └──▲───────▲──┘
      ▲ (rojo)                              ▲ (rojo) │         (azul)│  (rojo)│
  ┌───┴──────────┐              ┌───────────┴────┐   │            ╔══╩═══════╩═══╗
  │  Nil Class   │◄──(rojo)─┐   │  Basic Object  │───│──(verde)──►║ #BasicObject ║
  └───┬──────────┘          │   └───┬────▲───────┘   │            ╚══════▲═══════╝
      │(azul)          [nil]◄- - -(azul, punteada)   │                   │ (azul)
      │                     │           │ (azul)     │            ╔══════╩═══════╗
      │         ✱ ◄──(rojo)─│───┌───────┴────────┐   │            ║   #Object    ║──(rojo)──► ✱
      └─────────────────────┴──►│  Kernel[m] <-  │◄──┘            ╚══════▲═══════╝
                                │  Object        │───(verde)─────────────┘
                  ✱             └───────▲────────┘                       │ (azul)
                  ▲ (rojo)              │ (azul)                         │
             ╔════╩════╗ ✱ ◄──(rojo)────┌───────┴────────┐          ╔═══════╩═══════╗
  (marine)─(verde)─►║ #marine ║─(azul)─►│  Atacante[m] <-│─(verde)─►║   #Guerrero   ║──(rojo)──► ✱
      └──────────(rojo)────────────────►│  Defensor[m] <-│          ╚═══════▲═══════╝
                                        │  Guerrero      │                  │ (azul)
                                        └───────▲────────┘                  │
                  ✱                             │ (azul)                    │
                  ▲ (rojo)                      │                           │
             ╔════╩═════╗ ✱ ◄──(rojo)───┌───────┴────────┐          ╔═══════╩═══════╗
  (gknight)─(verde)─►║ #gknight ║─(azul)─►│   Espadachin   │─(verde)─►║  #Espadachin  ║──(rojo)──► ✱
      └──────────(rojo)────────────────►└────────────────┘          ╚═══════════════╝
```

*Descripción del diagrama:* igual al de la slide 16, completando la columna derecha de singleton classes:
- De **Kernel <- Object** sale una flecha verde hacia la caja verde **#Object**; de #Object sale una flecha roja hacia ✱.
- De **Basic Object** sale una flecha verde hacia la caja verde **#BasicObject**.
- Cadena azul (superclass) en la columna derecha: **#Espadachin → #Guerrero → #Object → #BasicObject → Class**.
- De **#BasicObject** sale además una flecha roja (class) directa hacia **Class** (no hacia ✱).
- Se mantienen #marine, #gknight (verde desde las instancias, azul hacia sus clases, rojo hacia ✱), #Espadachin y #Guerrero (rojo hacia ✱), Nil Class, nil, Module y Class.

---

## Slide 18 — Metamodelo de Ruby

**Leyenda:** superclass ■ (azul) · class ■ (rojo) · singleton_class ■ (verde) · mixin/class ■ (magenta) · ✱ Flechas que apuntan a Class

```
                                                     ┌────────(azul)──────────┐
                                                     │                        │
                                                     │             ┌──────────┴──┐            ╔═══════════╗
                                                     │             │   Module    │──(verde)──►║  #Module  ║
                                                     │             └──┬───────▲──┘            ╚═════╤═════╝
                                                     │          (rojo)│  (azul)│  ┌───(rojo)────────┘
                                                     │            ┌───▼────────┴──▼┐           ╔═══════════╗
                                                     │  ┌─(rojo)─►│    Class       │──(verde)─►║  #Class   ║
                                                     │  └─────────┤                │◄──(rojo)──╚═══════════╝
      ✱                                     ✱        │            └──▲──────────▲──┘
      ▲ (rojo)                              ▲ (rojo) │         (azul)│    (rojo)│
  ┌───┴──────────┐              ┌───────────┴────┐   │            ╔══╩═══════╩═══╗
  │  Nil Class   │◄──(rojo)─┐   │  Basic Object  │───│──(verde)──►║ #BasicObject ║
  └───┬──────────┘          │   └───┬────▲───────┘   │            ╚══════▲═══════╝
      │(azul)          [nil]◄- - -(azul, punteada)   │                   │ (azul)
      │                     │           │ (azul)     │            ╔══════╩═══════╗
      │         ✱ ◄──(rojo)─│───┌───────┴────────┐   │            ║   #Object    ║──(rojo)──► ✱
      └─────────────────────┴──►│  Kernel[m] <-  │◄──┘            ╚══════▲═══════╝
                                │  Object        │───(verde)─────────────┘
                  ✱             └───────▲────────┘                       │ (azul)
                  ▲ (rojo)              │ (azul)                         │
             ╔════╩════╗ ✱ ◄──(rojo)────┌───────┴────────┐          ╔═══════╩═══════╗
  (marine)─(verde)─►║ #marine ║─(azul)─►│  Atacante[m] <-│─(verde)─►║   #Guerrero   ║──(rojo)──► ✱
      └──────────(rojo)────────────────►│  Defensor[m] <-│          ╚═══════▲═══════╝
                                        │  Guerrero      │                  │ (azul)
                                        └───────▲────────┘                  │
                  ✱                             │ (azul)                    │
                  ▲ (rojo)                      │                           │
             ╔════╩═════╗ ✱ ◄──(rojo)───┌───────┴────────┐          ╔═══════╩═══════╗
  (gknight)─(verde)─►║ #gknight ║─(azul)─►│   Espadachin   │─(verde)─►║  #Espadachin  ║──(rojo)──► ✱
      └──────────(rojo)────────────────►└────────────────┘          ╚═══════════════╝
```

*Descripción del diagrama:* igual al de la slide 17, agregando las singleton classes de Module y Class, arriba a la derecha:
- De **Module** sale una flecha verde hacia la caja verde **#Module**; de #Module sale una flecha roja (class) hacia **Class**.
- De **Class** sale una flecha verde hacia la caja verde **#Class**; de #Class sale una flecha roja (class) hacia **Class**.
- No hay flechas azules saliendo de #Module ni de #Class en esta slide. Todo lo demás se mantiene.

---

## Slide 19 — Metamodelo de Ruby... Final... al fin...

**Leyenda:** superclass ■ (azul) · class ■ (rojo) · singleton_class ■ (verde) · mixin/class ■ (magenta) · ✱ Flechas que apuntan a Class

```
                                                     ┌────────(azul)──────────┐
                                                     │                        │
                                                     │             ┌──────────┴──┐            ╔═══════════╗
                                                     │             │   Module    │──(verde)──►║  #Module  ║──(azul)──┐
                                                     │             └──┬───────▲──┘            ╚═════╤══▲══╝          │
                                                     │          (rojo)│  (azul)│  ┌───(rojo)────────┘  │ (azul)      │
                                                     │            ┌───▼────────┴──▼┐           ╔═══════╧═══╗          │
                                                     │  ┌─(rojo)─►│    Class       │──(verde)─►║  #Class   ║          │
                                                     │  └─────────┤                │◄──(rojo)──╚═══════════╝          │
      ✱                                     ✱        │            └──▲──────────▲──┘                                  │
      ▲ (rojo)                              ▲ (rojo) │         (azul)│    (rojo)│                                     │
  ┌───┴──────────┐              ┌───────────┴────┐   │            ╔══╩═══════╩═══╗                                    │
  │  Nil Class   │◄─(verde)─┐   │  Basic Object  │───│──(verde)──►║ #BasicObject ║                                    │
  │              │◄──(rojo)─┤   └───┬────▲───────┘   │            ╚══════▲═══════╝                                    │
  └───┬──────────┘          │       │    │           │                   │ (azul)                                     │
      │(azul)          [nil]◄- - -(azul, punteada)   │            ╔══════╩═══════╗                                    │
      │                     │           │ (azul)     │            ║   #Object    ║──(rojo)──► ✱                       │
      │         ✱ ◄──(rojo)─│───┌───────┴────────┐   │            ║              ║◄────────────(azul)─────────────────┘
      └─────────────────────┴──►│  Kernel[m] <-  │◄──┘            ╚══════▲═══════╝
                                │  Object        │───(verde)─────────────┘
                  ✱             └───────▲────────┘                       │ (azul)
                  ▲ (rojo)              │ (azul)                         │
             ╔════╩════╗ ✱ ◄──(rojo)────┌───────┴────────┐          ╔═══════╩═══════╗
  (marine)─(verde)─►║ #marine ║─(azul)─►│  Atacante[m] <-│─(verde)─►║   #Guerrero   ║──(rojo)──► ✱
      └──────────(rojo)────────────────►│  Defensor[m] <-│          ╚═══════▲═══════╝
                                        │  Guerrero      │                  │ (azul)
                                        └───────▲────────┘                  │
                  ✱                             │ (azul)                    │
                  ▲ (rojo)                      │                           │
             ╔════╩═════╗ ✱ ◄──(rojo)───┌───────┴────────┐          ╔═══════╩═══════╗
  (gknight)─(verde)─►║ #gknight ║─(azul)─►│   Espadachin   │─(verde)─►║  #Espadachin  ║──(rojo)──► ✱
      └──────────(rojo)────────────────►└────────────────┘          ╚═══════════════╝
```

*Descripción del diagrama:* igual al de la slide 18, con tres flechas nuevas:
- De **#Class** sale una flecha azul (superclass) hacia **#Module**.
- De **#Module** sale una flecha azul (superclass) que rodea el borde derecho y baja hasta **#Object**.
- De **nil** sale una flecha verde (singleton_class) hacia **Nil Class**, además de la flecha roja (class) que ya existía.

Estado final completo del diagrama: columna central **Espadachin → Atacante <- Defensor <- Guerrero → Kernel <- Object → Basic Object** (azul); **Basic Object → nil** (azul punteada); **nil → Nil Class** (rojo y verde); **Nil Class → Kernel <- Object** (azul); instancias **marine → Atacante/Defensor/Guerrero** y **gknight → Espadachin** (rojo); singleton classes **#marine, #gknight, #Espadachin, #Guerrero, #Object, #BasicObject, #Module, #Class** (verde desde su objeto); cadena azul **#gknight → Espadachin**, **#marine → Atacante/Defensor/Guerrero**, **#Espadachin → #Guerrero → #Object → #BasicObject → Class**, **#Class → #Module → #Object**; **Module → Class** (rojo), **Class → Module** (azul), loop rojo de **Class**; **Module → Kernel <- Object** (azul); flechas rojas a ✱ desde Nil Class, Basic Object, Kernel/Object, Atacante/Defensor/Guerrero, Espadachin, #marine, #gknight, #Espadachin, #Guerrero y #Object; flechas rojas directas a **Class** desde #BasicObject, #Module y #Class.

---

## Slide 20 — Metamodelo de Ruby... como seguir?

- Proxima Clase
  - Conceptos restantes de self-modification. Sean pacientes (?)

---

**FIN DEL ARCHIVO FUENTE — Metaprogramación en Ruby — Metamodelo de Ruby (capturas video 2020)**
