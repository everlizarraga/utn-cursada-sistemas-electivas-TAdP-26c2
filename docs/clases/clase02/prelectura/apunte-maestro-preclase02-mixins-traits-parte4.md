# 📘 APUNTE MAESTRO — preclase02 · Mixins & Traits — Parte 4

## Traits: componer sin heredar

> **Unidad:** `preclase02` · Parte 4 de 5 · Lectura previa de la clase 2 ("Mixins: resolución de conflictos")

**Qué cubre esta parte:** qué es un trait (provided / required / sin estado) · cómo se arma una clase: `Clase = Superclase + Estado + Traits + Glue` · la flattening property · traits compuestos de traits · conflictos: cuándo existen, cómo explotan y las tres herramientas para resolverlos · el pliego de la Parte 3, respondido punto por punto · la evidencia real (Squeak y el refactor de colecciones).

**Qué NO cubre (viene después):** el precio de prohibir el estado, y su solución → Parte 5.

**De las partes anteriores se asume:** los dos roles de la clase, el wrapper imposible SyncA/SyncB, los tres dolores de mixins y el pliego de condiciones (Parte 3) · diamante y linearización (Parte 2) · `super` estático, el kit de Smalltalk (Parte 1).

---

## 1. 🔴 La unidad nueva

El caso de esta parte: un sistema de objetos gráficos — círculos, cuadrados — que se dibujan en un lienzo. Mirado con la lupa de la Parte 3, cada objeto gráfico mezcla **aspectos** separables: su *geometría* (área, radio, comparaciones) y su *forma de dibujarse* en pantalla. Dos responsabilidades que querríamos escribir una vez y reusar por separado — sin heredar nada de nadie.

La propuesta de 2003: una unidad de reuso nueva, más chica que una clase, llamada **trait**. Un trait es, en esencia, **un grupo de métodos con dos listas**:

```
        ┌─────────────────────────────┐
        │           TDrawing          │   ← convención: los nombres
        ├──────────────┬──────────────┤     de traits empiezan con T
        │  PROVEE      │  REQUIERE    │
        │  draw        │  bounds      │   ← columna derecha en itálica
        │  refresh     │  drawOn:     │     en la notación gráfica
        │  refreshOn:  │              │
        └──────────────┴──────────────┘
```

- **Provee** (*provided*): los métodos que el trait implementa — el comportamiento que aporta.
- **Requiere** (*required*): los métodos que el trait **usa pero no define** — los parámetros de su comportamiento. Quien incorpore el trait deberá conseguirlos de algún lado.

Y la regla de oro, la decisión que la Parte 3 dejó justificada de antemano:

> **Un trait no define estado. Nunca. Y sus métodos jamás acceden a variables directamente** — si necesitan estado, lo piden como métodos requeridos (que típicamente terminan siendo *accessors*: getters/setters). El conflicto sin salida limpia — el de estado — queda eliminado por prohibición.

El código de `TDrawing` ("saber dibujarse"), completo:

```smalltalk
Trait named: #TDrawing uses: {}
    "un trait nuevo, llamado TDrawing, que no usa otros traits.
     El # marca un symbol — 🕳️ un nombre único e inmutable de Smalltalk;
     las {} son una colección literal (acá, vacía)."

draw
    ↑ self drawOn: World canvas
    "dibujate en el lienzo global de la pantalla (World canvas).
     OJO: drawOn: es REQUERIDO — este trait lo usa sin definirlo.
     'Cómo' se dibuja cada figura lo pondrá otro."

refresh
    ↑ self refreshOn: World canvas
    "redibujate en pantalla"

refreshOn: aCanvas
    aCanvas form
        deferUpdatesIn: self bounds
        while: [ self drawOn: aCanvas ]
    "redibujá de forma eficiente: 'posponé las actualizaciones de
     pantalla dentro de mi rectángulo (bounds — REQUERIDO) mientras
     ejecutás este bloque'. Los [ ] son un bloque — 🕳️ un pedazo de
     código empaquetado como objeto, la lambda de Smalltalk."
```

`TDrawing` provee tres métodos parametrizados por dos requeridos (`bounds`, `drawOn:`). Su gemelo geométrico es `TCircle`: provee `area`, `bounds`, `circumference`, `scaleBy:`, y las comparaciones `=`, `hash`, `<`, `<=`… y requiere los accessors `center`, `center:`, `radius`, `radius:`. Puro comportamiento, cero estado, cero jerarquía: un trait **no vive en ningún lugar del árbol de herencia** — se aplica donde haga falta.

*(Convención de escritura que vas a ver en lo que queda del bloque: `Circle>>hash` significa "el método `hash` definido en `Circle`".)*

---

## 2. 🔴 Armar una clase: la ecuación de cuatro términos

Los traits **no reemplazan** a la herencia simple: la complementan. La herencia sigue relacionando clases *entre sí*; los traits estructuran el comportamiento *adentro* de una clase. La ecuación que resume el modelo — memorizala, es de las frases centrales del bloque:

```
Clase  =  Superclase  +  Estado  +  Traits  +  Glue
```

Una clase se define eligiendo un padre (herencia simple, como siempre), declarando sus variables de instancia, incorporando un conjunto de traits, y escribiendo los **glue methods** — el pegamento: los métodos que conectan los traits entre sí, satisfacen sus requirements (típicamente accessors del estado) y resuelven conflictos. La clase queda **completa** cuando todo requirement de sus traits está satisfecho — por la clase misma, por su superclase, o por otro trait incorporado.

El círculo, armado entero:

```smalltalk
Object subclass: #Circle
    instanceVariableNames: 'center radius'     "el ESTADO vive en la clase"
    uses: { TCircle . TDrawing }               "los TRAITS incorporados"

"── glue: inicialización ──"
initialize
    center := 0@0.        "0@0 = el punto (0,0) — x@y construye un punto"
    radius := 50

"── glue: accessors que satisfacen los requirements de TCircle ──"
center            ↑ center                "getter"
center: aPoint    center := aPoint        "setter"
radius            ↑ radius
radius: aNumber   radius := aNumber

"── glue: el requirement de dibujo de TDrawing ──"
drawOn: aCanvas
    aCanvas fillOval: self bounds color: Color black
    "dibujá un óvalo relleno negro en mi rectángulo contenedor.
     ¿Y bounds, que TDrawing también requería? NO hay que escribirlo:
     lo PROVEE TCircle — un trait le satisface el requirement al otro,
     dentro de la clase que los junta."
```

```
── La foto completa ─────────────────────────────────────────────
┌───────────────────────────────────────────────┐
│                    Circle                     │
│  estado: center, radius                       │
│  glue:   initialize, accessors, drawOn:       │
│                                               │
│   ┌────────────────────┐  ┌────────────────┐  │
│   │       TCircle      │  │    TDrawing    │  │
│   │ area, bounds, =,   │  │ draw, refresh, │  │
│   │ hash, <, scaleBy:… │  │ refreshOn:     │  │
│   │ req: center(:),    │  │ req: bounds ◄──┼──┼── lo provee TCircle
│   │      radius(:)  ◄──┼──┼── lo provee    │  │
│   └────────────────────┘  │    el glue     │  │
│                           └────────────────┘  │
└───────────────────────────────────────────────┘
── Resultado esperado: Circle new draw → un círculo negro de radio
   50 en (0,0). Clase COMPLETA: cero requirements sin satisfacer. ──
```

Cuando un nombre choca, dos reglas de precedencia fijas ordenan la casa:

1. **Los métodos de la clase pisan a los de sus traits** (así el glue puede adaptar y resolver).
2. **Los métodos de los traits pisan a los de la superclase.**

¿Y entre trait y trait? Ninguno pisa a ninguno — eso es la sección 5.

> 📌 **Para el parcial, si te preguntan** — *¿Qué es un trait y cómo se construye una clase con traits?*
> Un trait es un grupo de métodos que provee comportamiento y declara métodos requeridos que lo parametrizan; no define estado ni accede a variables directamente, y no ocupa un lugar en la jerarquía de herencia. Una clase se construye según `Clase = Superclase + Estado + Traits + Glue`: hereda de una superclase (herencia simple intacta), define las variables, incorpora traits y escribe los glue methods que satisfacen los requirements (típicamente accessors) y resuelven conflictos. La clase es completa cuando todos los requirements quedan satisfechos por la clase, su superclase u otro trait.

---

## 3. 🔴 La flattening property

La propiedad estrella del modelo, la que responde al dilema de fondo — ¿reuso o comprensibilidad? — con "los dos":

> **Flattening property (propiedad de aplanado):** la semántica de una clase definida con traits es **exactamente la misma** que la de una clase que tuviera todos los métodos no-pisados de sus traits escritos directamente en su cuerpo.

Consecuencias, de la más técnica a la más profunda:

- **`super` no tiene semántica especial en un trait.** Un `super` escrito dentro de un método de trait simplemente arranca la búsqueda en la superclase **de la clase que usa el trait** — como si el método estuviera escrito ahí. (Retené esto: en la sección 6 gana un partido entero solo.)
- **Componer no cambia significados.** La composición es una herramienta de *estructura*, no de semántica: dónde está definido un método — en la clase, en un trait, en un trait de un trait — no afecta lo que hace. Compará con mixins, donde la posición en la cadena lo era todo.
- **Dos vistas, cero conflicto.** Una clase construida con veinte traits puede *verse* de dos maneras: como composición (ideal para reusar y entender responsabilidades) o **aplanada** — una lista lisa de métodos, como una clase de toda la vida (ideal para entender qué hace). Como la semántica no depende de la vista, ambas coexisten sin mentirse. El conflicto reuso-vs-comprensibilidad que la Parte 3 planteó era, con la herramienta correcta, un falso dilema.

---

## 4. 🔴 Traits hechos de traits

Igual que las clases, **los traits se componen de otros traits** — y acá el modelo escala sin cambiar reglas. `TCircle`, mirado de cerca, mezcla dos aspectos: comparaciones y geometría. Se refactoriza:

```
┌───────────────────────────────┐
│            TCircle            │  provee =, hash, <  (glue del compuesto)
│                               │
│  ┌─────────────────────────┐  │
│  │       TMagnitude        │  │  provee <=, >, >=, max:, between:and:
│  │  requiere: <            │  │  requiere <  ← lo define TCircle
│  │  ┌───────────────────┐  │  │
│  │  │     TEquality     │  │  │  provee ~=  ("distinto")
│  │  │ requiere: =, hash │  │  │  ← sus requirements SUBEN:
│  │  └───────────────────┘  │  │    los termina definiendo TCircle
│  │                         │  │
│  └─────────────────────────┘  │
│  ┌─────────────────────────┐  │
│  │        TGeometry        │  │  provee area, bounds, diameter…
│  │  requiere: center(:),   │  │  ← estos requirements suben hasta
│  │            radius(:)    │  │    TCircle y quedan como SUS
│  └─────────────────────────┘  │    requirements (los pagará Circle)
└───────────────────────────────┘
```

```smalltalk
Trait named: #TCircle uses: { TMagnitude . TGeometry }

"glue del trait compuesto: satisface lo que sus subtraits piden"
= other
    ↑ self radius = other radius and: [ self center = other center ]
    "dos círculos son iguales si coinciden radio y centro.
     and: [...] evalúa el bloque solo si lo anterior fue true"

hash
    ↑ self radius hash bitXor: self center hash
    "combiná los hash de radio y centro con XOR bit a bit (bitXor:)
     — la forma estándar de fundir dos hashes en uno"

< other
    ↑ self radius < other radius
    "orden entre círculos: por radio (satisface el < de TMagnitude)"
```

Las reglas son las mismas de la sección 2, un nivel más arriba: lo **provisto** por los subtraits se propaga al compuesto (`max:`, `~=`, `area`… quedan provistos por `TCircle`); lo **requerido y no satisfecho** también se propaga (`center`, `radius:`… quedan requeridos por `TCircle`); los métodos del compuesto pisan a los de sus subtraits; el orden no importa; y la flattening property **sigue valiendo a cualquier profundidad** — `TCircle` aplanado es indistinguible de un trait escrito de una pieza.

---

## 5. 🔴 Conflictos: que exploten a la cara

La Parte 3 pidió que los conflictos no se resolvieran solos por precedencia — que fueran explícitos y los resolviera el compositor. Así lo entrega el modelo.

**La definición exacta, palabra por palabra:** hay conflicto **si y solo si** se combinan dos traits que proveen métodos con el mismo nombre **que no se originan en el mismo trait**.

La segunda mitad de la frase es una decisión de diseño con nombre propio — la **same-operation exception**: si el *mismo* método (el mismo, del mismo trait de origen) llega dos veces por caminos distintos, **no hay conflicto**. ¿Te suena la geometría? Es el diamante — y acá, sencillamente, **se disuelve**: como los traits no tienen estado, que un método llegue una o cinco veces da idéntico resultado. El problema que la linearización de CLOS atacaba con un algoritmo global, los traits lo hacen desaparecer por construcción.

Cuando el conflicto es real, la composición **no elige por vos**: instala en ese nombre un método *marcador* que señala el conflicto. La clase no está completa hasta que el compositor lo resuelva **a su nivel** — jamás lo resuelve "de casualidad" otro subtrait que pase por ahí. Esta disciplina tiene un premio algebraico directo: la composición de traits es **asociativa y conmutativa** — el `⋆` de la Parte 2 era asociativo pero *no* conmutativo (el orden decidía los conflictos); acá el orden no decide nada, porque los conflictos no se deciden: se declaran.

### El caso: círculos con color

`TColor` empaqueta el comportamiento de color — y como los colores también se comparan, usa `TEquality` y define sus propios `=` y `hash`:

```smalltalk
Trait named: #TColor uses: { TEquality }
    "provee red, green, hue, saturation…  requiere rgb, rgb:"

hash
    ↑ self rgb hash               "el hash de un color: el de su rgb"

= other
    ↑ self rgb = other rgb        "dos colores son iguales si su rgb coincide"
```

Ahora armemos el círculo coloreado con `TCircle`, `TDrawing` y `TColor`:

```
        TCircle provee:   = (por radio y centro)   hash   ~=
        TColor  provee:   = (por rgb)              hash   ~=

        =    → dos implementaciones, orígenes DISTINTOS →  ✗ CONFLICTO
        hash → dos implementaciones, orígenes DISTINTOS →  ✗ CONFLICTO
        ~=   → ambas copias vienen del MISMO trait (TEquality)
               → same-operation exception → ✓ sin conflicto
```

La composición marca `=` y `hash` en conflicto; `Circle` no compila completo hasta resolverlos. Herramientas disponibles, de la más usada a la más quirúrgica:

**a) Override + alias.** La clase define su propia versión (regla 1 de precedencia: la clase pisa el conflicto)… pero ¿y si la versión buena *combina* las dos originales, que quedaron pisadas? Para eso está el **alias** (`@`): darle un nombre *adicional* a un método de un trait, sin tocar el original.

```smalltalk
Object subclass: #Circle
    instanceVariableNames: 'center radius rgb'
    uses: { TCircle  @ { #circleHash  -> #hash.  #circleEqual: -> #= } .
            TDrawing .
            TColor   @ { #colorHash   -> #hash.  #colorEqual: -> #= } }
    "cada @ {...} lee: 'este nombre nuevo -> apunta al método este'.
     Los = y hash originales siguen ahí, ahora TAMBIÉN alcanzables
     como circleEqual:/circleHash y colorEqual:/colorHash."

"── el glue resuelve el conflicto combinando ambos mundos ──"
hash
    ↑ self circleHash bitXor: self colorHash

= anObject
    ↑ (self circleEqual: anObject) and: [ self colorEqual: anObject ]
    "dos círculos coloreados son iguales si coinciden en geometría
     Y en color.
     Resultado esperado: círculos con igual centro, radio y rgb → true;
     igual forma, distinto color → false."
```

**b) Exclusión.** Si la decisión de diseño es otra — "la igualdad de un círculo coloreado ignora el color" — el conflicto se puede evitar antes de que exista, **excluyendo** (`−`) métodos de un trait al componerlo:

```smalltalk
Object subclass: #Circle
    instanceVariableNames: 'center radius rgb'
    uses: { TCircle . TDrawing . TColor − { #= . #hash } }
    "TColor entra SIN sus = y hash → no hay dos orígenes → no hay
     conflicto → valen los de TCircle, sin escribir glue ninguno."
```

Fijate lo que las dos soluciones tienen en común, porque es el punto de la parte entera: **la resolución vive en el compositor** — a la vista, en la cláusula `uses:` y el glue de `Circle` — y expresa una decisión de *dominio* ("¿el color cuenta para la igualdad?"), no un accidente del orden de composición.

### Alias no es renombrar

Detalle fino con nombre y apellido (la comparación es contra el *renaming* de Eiffel — 🕳️ lenguaje OO de Meyer con herencia múltiple, que resuelve homónimos renombrando features al heredar): **el alias agrega un nombre; el renaming mata el original.** Renombrar obliga a corregir todas las referencias viejas por todo el código; el alias no toca ninguna. Y una consecuencia sutil para anotar: como el alias no modifica el cuerpo del método, **el alias de un método recursivo no es recursivo** — su cuerpo sigue llamando al nombre original.

> 📌 **Para el parcial, si te preguntan** — *¿Cuándo hay conflicto entre traits y cómo se resuelve?*
> Hay conflicto si y solo si dos traits compuestos proveen métodos homónimos que no se originan en el mismo trait; si el mismo método llega varias veces por caminos distintos no hay conflicto (same-operation exception), lo que disuelve el diamante porque los traits no tienen estado. El conflicto no se resuelve por precedencia ni orden: la composición lo marca explícitamente y debe resolverlo el compositor, ya sea definiendo un método propio que pisa el conflicto (usando aliases `@` para acceder a las versiones originales y combinarlas) o excluyendo (`−`) el método de todos los traits menos uno. Por eso la composición es asociativa y conmutativa.

---

## 6. 🔴 El pliego de la Parte 3, punto por punto

La Parte 3 cerró con cinco condiciones. Pasemos lista — y empecemos por la revancha del caso estrella.

**El wrapper genérico, resuelto — y con la solución "imposible".** ¿Te acordás del intento (b): subir el código del candado a `SyncReadWrite`, muerto porque `super` se resolvía estáticamente hacia `Object`? Releelo con la flattening property en la mano: si `SyncReadWrite` es un **trait**, su `super` es un *placeholder* que se liga a la superclase **de la clase que lo use**. Entonces:

```
   SyncA = subclase de A, usa TSyncReadWrite
     → el "super read" del trait, aplanado en SyncA, busca en A  ✓
   SyncB = subclase de B, usa TSyncReadWrite
     → el MISMO método, aplanado en SyncB, busca en B            ✓

   ┌───┐                                   ┌───┐
   │ A │◄──herencia──┐       ┌──herencia──►│ B │
   └───┘             │       │             └───┘
              ┌──────┴─┐   ┌─┴──────┐
              │ SyncA  │   │ SyncB  │
              └──▲─────┘   └────▲───┘
                 │  usa         │  usa
              ┌──┴──────────────┴───┐
              │   TSyncReadWrite    │   ← UNA sola copia del candado.
              │  (read/write con    │     Cero métodos duplicados.
              │   lock vía super)   │     Cero danza de nombres.
              └─────────────────────┘
```

El diseño que la herencia múltiple no podía expresar era el *correcto* — lo que faltaba era la unidad adecuada. (En la Parte 5 este mismo ejemplo vuelve una vez más, con otro nombre y una espina nueva.)

El resto del pliego, al galope:

- **Estado en conflicto** → eliminado por prohibición: traits sin estado, punto. Y de paso hay *menos* conflictos de método que en herencia múltiple, porque los traits son piezas chicas y enfocadas — no clases enteras arrastrando todo su equipaje.
- **Orden** → la composición es simétrica: no hay orden que elegir ni que te sorprenda. ¿Y si *querés* precedencia? La recuperás con la herramienta que ya tenías: herencia. Para que `T2` pise a `T1`: una superclase `C'` que usa `T1`, y `C` que hereda de `C'` y usa `T2` — por la regla "trait pisa a superclase", gana `T2`. Orden *parcial*, a la carta, donde lo pidas — no total y obligatorio en todos lados.
- **Glue** → siempre en la entidad que compone, separado del código de los aspectos. La clase se entiende leyendo sus traits + su glue.
- **Acceso a lo pisado** → `super` sigue funcionando hacia la superclase, y para lo demás: aliases — sin nombres de clases cableados dentro de los métodos (la fragilidad arquitectónica de C++/Eiffel, esquivada).
- **Fragilidad** → cambiar un trait *puede* introducir conflictos o requirements nuevos en sus clientes — eso es inevitable en cualquier composición — pero la diferencia está en el radio: el conflicto **se señala en el momento exacto** en que aparece, y el cliente **directo** lo resuelve solo, sin reimplementar nada; si preserva su interfaz, **no hay efecto dominó** río abajo. Compará con el override silencioso de los mixins que se propagaba por cadenas desconocidas.

---

## 7. 🟡 Las decisiones finas (y sus porqués)

Tres discusiones de diseño del modelo, del tipo que esta materia premia saber defender:

**a) ¿Por qué alias y no referencias con nombre de trait?** Podría haberse elegido escribir `TColor.hash` dentro de los métodos (como el `A::read` de C++). Se descartó por tres razones encadenadas: contradiría la flattening property (un método con `TColor.hash` adentro no puede aplanarse sin reescribirlo) · cablearía la estructura de traits dentro de los cuerpos (mover un método de un trait a otro rompería a quienes lo nombran) · y exigiría extender la sintaxis del lenguaje base. El alias, en cambio, es solo una entrada más en la tabla de nombres: aplana trivial, no cablea nada, no toca la sintaxis de los métodos.

**b) El límite honesto: conflictos de nombre no intencionales.** Dos traits pueden *requerir* métodos con el mismo nombre y semánticas distintas (el clásico: dos interfaces exigen `close`, una "cerrar archivo", otra "cerrar ventana"). Los traits **no resuelven esto** — los aliases alivian apenas. El propio modelo lo admite: la solución completa pide namespaces — 🕳️ espacios de nombres: contextos separados donde el mismo nombre puede significar cosas distintas — y buenas herramientas de refactoring, que son otra película. Anotalo como está: un límite reconocido, no negado.

**c) El diamante de traits, defendido contra las alternativas.** Aún sin estado, la geometría del diamante puede aparecer: `X` usa `Y1` y `Y2`, y ambos usan `Z` — el método `Z>>foo` llega dos veces a `X`. La decisión (same-operation exception: sin conflicto) tiene una sorpresa admitida: si mañana `Y2` se reescribe y *copia* `foo` en vez de tomarlo de `Z`, un cambio que parecía interno **crea** un conflicto en `X`. ¿Defecto? El análisis dice que no, comparando contra las dos alternativas posibles: (i) que `X` obtenga automáticamente uno u otro `foo` — es la linearización: cero aviso aunque la semántica de `X` haya cambiado; (ii) declarar conflicto *siempre*, aun con el mismo método (la postura de Snyder) — obliga a elegir arbitrariamente de entrada, y lo peor: un cambio posterior al `foo` elegido **no** se señala. Con la regla adoptada, el conflicto suena **exactamente cuando nace**, que es cuando el programador tiene la información para resolverlo — y la resolución es local (`X` suprime uno de los dos y listo). Trade-off elegido con argumento, no dogma.

---

## 8. 🟢 La evidencia

**La implementación** (Squeak, un Smalltalk abierto): un trait se implementa como una clase despojada — sin estado, sin superclase — y al usarlo, sus métodos no-pisados entran al diccionario de métodos de la clase; un alias es solo una segunda entrada apuntando al mismo método. El bytecode se **comparte** entre el trait y todos sus usuarios — única excepción: los métodos con `super`, que se copian para ajustar la referencia a cada superclase concreta. Resultado medido: **performance indistinguible** de la misma jerarquía escrita a mano, sin tocar la máquina virtual. La otra mitad del éxito son las herramientas: el browser muestra cada clase en las dos vistas (composición ↔ aplanada), distingue provided / required / overridden / glue, recompila incrementalmente, y mantiene una lista de "pendientes" con cada conflicto o requirement insatisfecho del sistema. La flattening property no es solo un teorema: es lo que permite que ambas vistas existan a la vez.

**La aplicación real:** el refactor de la jerarquía de colecciones de Smalltalk-80 — veinte años de evolución, considerada ejemplo paradigmático de OO… y sin embargo llena de código duplicado y de métodos ubicados "demasiado arriba" a propósito (para compartirlos) y luego *deshabilitados* en las subclases donde no aplicaban: la herencia simple no daba para modelar propiedades cruzadas (ordenado/no, extensible/no, inmutable/no, con claves/no…). Con traits: las propiedades de **interfaz** se separaron de las de **implementación** y se volvieron combinables libremente; la herencia quedó para lo que sirve (orden parcial: traits específicos pisando genéricos); y aparecieron subtraits finos reusables hasta fuera de las colecciones ("emptiness": requiere `size`, provee `isEmpty`, `notEmpty`…; "enumeration": requiere `do:`, provee `collect:`, `select:`, `detect:`…). Números: 21 clases construidas con 48 traits, 567 métodos — **10% menos métodos y 12% menos código** que el original, con clases de hasta **22 traits** que, gracias al aplanado, se leen como clases comunes.

**Y un guiño que cierra el círculo del bloque:** entre los antecedentes del modelo está *Jigsaw* — la tesis doctoral (1992) de **Bracha**, el mismo de las Partes 1 y 2 — cuyo sistema de módulos definía operadores (merge, override, restrict, copy-as) asombrosamente parecidos a la suma, el override, la exclusión y el alias de los traits… definidos de forma independiente. Cuando dos búsquedas separadas aterrizan en las mismas cuatro operaciones, suele ser señal de que las operaciones eran las correctas.

---

## 9. 🟢 Dónde quedamos parados

El pliego de la Parte 3 quedó respondido entero — con una decisión pagando buena parte de la cuenta: **prohibir el estado**. Gracias a ella no hay conflictos de variables, el diamante se disuelve, el bytecode se comparte. La pregunta que abre la Parte 5 es la de siempre en este bloque: ¿y esa decisión, qué precio esconde? Adelanto en una imagen: si ningún trait puede tener estado, *todos* los traits útiles terminan pidiendo accessors… y alguien tiene que escribirlos. Muchas veces. Las mismas veces.

---

## ✅ Checkpoint — Parte 4

*(Sin respuestas — se validan en el chat; las respuestas modelo van al complemento.)*

1. ¿Qué dos listas definen a un trait, y qué papel juega cada una?
2. ¿Por qué los traits no definen estado? Conectá la decisión con un dolor concreto de la Parte 3.
3. Explicá cada término de `Clase = Superclase + Estado + Traits + Glue` y qué es exactamente un glue method.
4. Enunciá la flattening property y dos de sus consecuencias.
5. En la clase `Circle`, el requirement `bounds` de `TDrawing` no lo escribe la clase. ¿Quién lo satisface y qué regla general ilustra eso?
6. ¿Cuál es la definición exacta de conflicto entre traits? ¿Por qué la same-operation exception es semánticamente segura acá y no lo sería con estado?
7. ¿Qué hace el alias `@` y en qué se diferencia del renaming? ¿Por qué el alias de un método recursivo no es recursivo?
8. Mostrá las dos resoluciones posibles del conflicto `=`/`hash` entre `TCircle` y `TColor`, y qué decisión de dominio expresa cada una.
9. ¿Por qué la solución (b) del wrapper — la que era imposible en la Parte 3 — funciona si `SyncReadWrite` es un trait?
10. ¿Cómo se recupera un orden de precedencia entre dos traits cuando de verdad se lo necesita?
11. La composición de traits es asociativa **y conmutativa**; la de mixins era solo asociativa. ¿Qué cambió y por qué importa?

---

**FIN DE LA PARTE 4** — *sigue en la Parte 5: el precio de no tener estado — stateful traits.*
