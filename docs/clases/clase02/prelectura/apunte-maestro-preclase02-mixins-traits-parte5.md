# 📘 APUNTE MAESTRO — preclase02 · Mixins & Traits — Parte 5

## El precio de no tener estado: stateful traits

> **Unidad:** `preclase02` · Parte 5 de 5 · Lectura previa de la clase 2 ("Mixins: resolución de conflictos")

**Qué cubre esta parte:** las cuatro cuentas que paga la prohibición del estado · stateful traits: variables privadas + el operador `@@` · los tres escenarios (privado / acceso / merge) · qué pasa adentro de la máquina (comprimido) · la prueba en las colecciones (el caso Heap) · **el cierre del arco completo del bloque**.

**De las partes anteriores se asume:** todo el modelo de traits — provided/required, glue, flattening, alias `@`, exclusión `−`, suma `+` (Parte 4) · el wrapper SyncA/SyncB (Partes 3 y 4) · el arco 1990→2003 (Partes 1-3).

---

## 1. 🟡 El wrapper, tercera aparición: SyncStream

El caso estrella del bloque vuelve una vez más, ahora con nombre de stream — 🕳️ un flujo de datos que se lee y escribe de a pedazos (un archivo, una conexión de red). Año 2006: los traits ya están adoptados y en uso; el grupo que los mantiene (Bergel, Ducasse, Nierstrasz, Wuyts — dos de ellos, autores del modelo original) construye la versión sincronizada del stream **con traits sin estado**, tal como manda la Parte 4:

```
┌─────────────────────────────┐      ┌───────────────────┐
│       TSyncReadWrite        │      │      TStream      │
│ PROVEE       │ REQUIERE     │      │ PROVEE   │ REQ.   │
│ syncRead     │ read         │      │ read     │        │
│ syncWrite    │ write        │      │ write    │        │
│ hash         │ lock:        │      │ hash     │        │
│              │ lock    ◄────┼──┐   └───────────────────┘
└──────────────┴──────────────┘  │        ▲
        ▲ @ {hashFromSync->hash} │        │ @ {hashFromStream->hash}
        │                        │        │
        └──────────┬─────────────┼────────┘
           ┌───────┴────────┐    │
           │   SyncStream   │    │
           │ variable: lock │    └── el candado se pide VÍA ACCESSOR,
           │ glue: lock,    │        y los accessors los pone la clase
           │  lock:, isBusy,│
           │  hash          │
           └────────────────┘
```

El corazón del trait, con la idiom de la Parte 4 (estado solo a través de accessors requeridos):

```smalltalk
syncRead
    | value |
    self lock acquire.       "pedí el candado… vía el ACCESSOR self lock
                              (acquire = tomarlo; espera si está ocupado)"
    value := self read.      "read: requerido conceptual — lo pone TStream"
    self lock release.       "soltá el candado"
    ↑ value
```

El conflicto de `hash` (ambos traits lo proveen, orígenes distintos) se resuelve exactamente como aprendiste en la Parte 4: doble alias y glue que combina — `hash ↑ self hashFromSync bitAnd: self hashFromStream` (`bitAnd:` — AND bit a bit, otra forma válida de fundir dos hashes).

**Funciona.** Y sin embargo, mirá la columna de requirements de `TSyncReadWrite` con ojos de la Parte 3: `read` y `write` son requirements *conceptuales* — los hooks reales, 🕳️ hook: el método que el cliente legítimamente debe aportar porque es su responsabilidad. Pero `lock` y `lock:`… son ruido. El trait no quiere *pedirle* el candado a nadie: quiere **tenerlo**. Lo pide porque el modelo le prohíbe tenerlo. Esa diferencia entre "lo que el trait necesita del cliente" y "lo que el trait necesita porque no lo dejan tener" es la espina de toda esta parte.

---

## 2. 🔴 Las cuatro cuentas de la prohibición

La decisión "traits sin estado" pagó buena parte del pliego de la Parte 3 (cero conflictos de variables, diamante disuelto). Tres años de uso real mostraron su factura, en cuatro cuotas:

### 2.1 Reusabilidad limitada

Prácticamente **ningún trait útil es completo**: casi todos necesitan algo de estado, así que casi todos arrastran accessors requeridos. Consecuencia: ningún trait se compone *off-the-shelf* — 🕳️ "sacado del estante": usable tal cual, sin adaptación — siempre hay tarea previa. Y peor: la interfaz requerida, que debería mostrar los hooks conceptuales, queda **tapada de accessors triviales**. El que quiere reusar el trait tiene que separar la señal (`read`, `write` — esto sí es tu responsabilidad) del ruido (`lock`, `lock:` — esto es burocracia).

### 2.2 Boilerplate y clases-cáscara

Alguien tiene que pagar los accessors: cada clase cliente. Todas. Con el mismo código:

```
                 ┌────────────────────┐
                 │   TSyncReadWrite   │
                 │ req: read, write,  │
                 │      lock, lock:   │
                 └────────────────────┘
                   ▲        ▲        ▲
          ┌────────┘        │        └────────┐
   ┌────────────┐    ┌────────────┐    ┌────────────┐
   │  SyncFile  │    │ SyncStream │    │ SyncSocket │
   │▓ lock      │    │▓ lock      │    │▓ lock      │  ▓ = el MISMO
   │▓ lock      │    │▓ lock      │    │▓ lock      │      código,
   │▓ lock:     │    │▓ lock:     │    │▓ lock:     │      tres veces
   │  read      │    │  read      │    │  read      │
   │  write     │    │  write     │    │  write     │
   └────────────┘    └────────────┘    └────────────┘
```

La variable `lock`, el getter y el setter, **duplicados letra por letra** en cada cliente. Duplicación mecánica — *exactamente el pecado que los traits vinieron a erradicar*. Y el fenómeno escala: en la jerarquía de colecciones refactorizada con traits (Parte 4), **7 de las 29 clases — el 24% — son *shell classes***: cáscaras que no hacen NADA salvo declarar variables y sus accessors (Heap, Dictionary, LinkedList, OrderedCollection, entre otras). Un cuarto de la jerarquía es puro embalaje.

### 2.3 Propagación de accessors: la fragilidad vuelve por la ventana

Un trait evoluciona: la nueva versión de `TSyncReadWrite` necesita contar cuántos clientes esperan el candado → variable nueva `numberWaiting` → **dos accessors requeridos nuevos** → que se propagan, de trait en trait, hasta **todas las clases cliente** — que deben tocarse aunque la interfaz pública del trait *no cambió en nada*. Un cambio de representación interna viajando por todo el sistema: la definición de libro de fragilidad — la enfermedad que los traits le diagnosticaron a los mixins, de vuelta en casa.

### 2.4 Encapsulamiento violado, dos veces

- **Hacia la interfaz:** el trait *publica su representación interna* como requirements — información que a ningún cliente le interesa, ensuciando el contrato. Lo sano sería lo que hace una clase abstracta: declarar responsabilidad solo sobre lo conceptual.
- **Hacia afuera:** en Smalltalk todo método es público → los accessors requeridos son públicos → **cualquier objeto del sistema puede manosear el candado desde afuera** (`unStream lock release` — y adiós sincronización). En lenguajes con `private`/`protected` se mitiga a medias; en Smalltalk, ni eso.

> 📌 **Para el parcial, si te preguntan** — *¿Cuáles son las limitaciones de los traits sin estado?*
> Cuatro, todas derivadas de codificar el estado como accessors requeridos: (1) reusabilidad limitada — casi ningún trait es completo ni componible tal cual, y la interfaz requerida se llena de accessors triviales que tapan los hooks conceptuales; (2) boilerplate — cada clase cliente debe duplicar variables, accessors e inicialización, generando clases-cáscara de puro glue (24% de la jerarquía de colecciones); (3) propagación — agregar estado interno a un trait propaga nuevos required accessors a todos sus clientes aunque la interfaz pública no cambie, reintroduciendo fragilidad; (4) encapsulamiento violado — la representación interna queda expuesta como requirements, y los accessors públicos permiten manipular desde afuera estado que debía ser privado.

---

## 3. 🔴 Stateful traits: la extensión mínima

La solución de 2006/2007 se propone tocar lo menos posible: que los traits sin estado queden como **caso particular** de los nuevos, que los traits puedan por fin ser *completos*, y que se conserve intacto el principio rector de todo el modelo: **el cliente controla la composición**. Tres movimientos:

> 1. Un trait puede declarar **variables de instancia** — que son **privadas al scope del trait** por defecto. Nadie las ve: ni otros traits, ni la clase que lo usa.
> 2. El **cliente** (la clase o el trait compuesto que lo usa) puede **darse acceso** a variables elegidas de un trait, bajo un nombre posiblemente nuevo, con el operador **`@@`**.
> 3. El cliente puede **mergear** variables de traits distintos, mapeándolas a un nombre común.

La consecuencia inmediata del movimiento 1 es la que sostiene todo: **los conflictos de variables no pueden existir**. Si `T1` define `x` y `T2` también, componerlos no choca nada — cada `x` vive encerrada en su trait. El fantasma que aterrorizaba a la herencia múltiple (Parte 3 §2.1) no es que se resuelva: **no puede nacer**.

### SyncStream, reescrito

```smalltalk
Trait named: #TSyncReadWrite
    uses: {}
    instVarNames: 'lock'        "← la novedad: el trait DECLARA su variable"
```

```smalltalk
initialize
    super initialize.            "flattening intacta: super mira la superclase
                                  de la clase que use este trait"
    lock := Lock new             "el trait inicializa SU candado. Lock = un
                                  objeto candado, con acquire/release"

syncRead
    | value |
    lock acquire.                "la variable, DIRECTA — es mía, no la pido"
    value := self read.
    lock release.
    ↑ value
"syncWrite: idéntico, con self write"

hash
    ↑ self hashFromSync bitAnd: self hashFromStream
```

Compará las dos columnas de requirements:

```
   ANTES (stateless):  read · write · lock · lock:
   AHORA (stateful):   read · write
                       └── SOLO los hooks conceptuales.
                           El trait es dueño de su estado,
                           y su contrato dice la verdad.
```

La clase que compone, ahora:

```smalltalk
Object subclass: #SyncStream
    uses: TSyncReadWrite @  { #hashFromSync -> #hash }
                         @@ { syncLock -> lock }
        + TStream @ { #hashFromStream -> #hash }
    instVarNames: ''             "la clase no declara NINGUNA variable"

"── el único glue que queda: lo que SyncStream de verdad agrega ──"
isBusy
    ↑ syncLock isAcquired        "¿está tomado el candado? — para poder
                                  preguntarlo, la clase se dio acceso a la
                                  variable lock del trait bajo el nombre
                                  syncLock: eso es el @@ de arriba"

hash
    ↑ self hashFromSync bitAnd: self hashFromStream
"Resultado esperado: SyncStream funciona igual que antes — pero sin
 variable propia, sin accessors públicos, sin boilerplate. Las tres
 clases hermanas (SyncFile, SyncSocket) ya no duplican nada."
```

Fijate la simetría deliberada de la sintaxis: **`@` es a los métodos lo que `@@` es a las variables** — un nombre *adicional*, visible solo en el scope del cliente, sin tocar el original. Dentro del trait, la variable se sigue llamando `lock`; `syncLock` existe únicamente para `SyncStream`.

### Los tres escenarios, uno por figura

**(i) Sin `@@`: todo privado (el default).** `C` usa `T1 + T2`; los tres definen su propia `x`; nadie ve la de nadie:

```
   T1 tiene x  ·  T2 tiene x  ·  C tiene x        TRES celdas distintas

   c setXT1: 1.   c setXT2: 2.   c setX: 3.
   ──────────────────────────────────────
   c getXT1 → 1      c getXT2 → 2      c getX → 3      cero conflicto ✓
```

Composición ciega y segura — *black-box*, 🕳️ caja negra: usar la pieza sin conocer ni tocar su interior.

**(ii) `@@` para acceder.** `C` quiere construir sobre el estado de sus traits:

```
   C:  T1 @@ { xFromT1 -> x }  +  T2 @@ { xFromT2 -> x }

   (dos variables homónimas → el renombre las distingue en el scope de C)

   C define:  sum   ↑ xFromT1 + xFromT2

   c setXT1: 1.   c setXT2: 2.
   c sum → 3   ✓
```

**(iii) `@@` para mergear.** El movimiento más fuerte: dos variables de traits distintos, **fundidas en una sola celda** por decisión del cliente:

```
   C:  T1 @@ { w -> x }  +  T2 @@ { w -> y }
       (la x de T1 y la y de T2 pasan a ser LA MISMA variable, w)

   C define getW / setW:.
   c setW: 3.
   ──────────────────────────────────────
   c getX → 3      c getY → 3      c getW → 3      una sola celda ✓
```

¿Dónde estaba este problema en el bloque? Es la mitad buena del diamante: "quiero que el estado heredado por dos caminos sea UNO solo" — lo que la herencia múltiple no sabía decidir (¿una `x` o dos?), acá **lo decide explícitamente el que compone**, caso por caso: sin `@@`, dos; con merge, una.

Dos garantías cierran el diseño: la visibilidad de una variable **jamás se propaga sola** a un scope contenedor (no hay captura accidental de nombres posible); y si la clase declara una variable con el mismo nombre que usó en un `@@`, eso es **error**, directamente — no puede ocurrir como efecto colateral de que alguien cambie un trait remoto, porque los nombres del scope del cliente los eligió el cliente.

Balance contra las cuatro cuentas: (1) interfaces requeridas limpias — solo hooks; (2) cero boilerplate — las cáscaras se vacían; (3) agregar estado a un trait es **invisible** para los clientes (privado por defecto): la propagación murió; (4) nada de accessors públicos no deseados. Y los traits sin estado siguen funcionando igual: son el caso `instVarNames: ''`.

> 📌 **Para el parcial, si te preguntan** — *¿Qué agregan los stateful traits y cómo evitan los conflictos de variables?*
> Permiten que un trait declare variables de instancia privadas a su propio scope. Como son privadas por defecto, componer traits con variables homónimas no genera conflicto alguno: cada una vive aislada. El cliente — fiel al principio de que quien compone controla la composición — puede ampliar selectivamente la visibilidad con el operador `@@`, que da acceso a una variable bajo un nombre nuevo local al cliente (análogo al alias `@` de métodos), y puede mergear variables de traits distintos mapeándolas a un nombre común, unificándolas en una sola celda. Agregar estado a un trait no afecta a ningún cliente; quitar o renombrar variables afecta solo a los clientes directos que se dieron acceso explícito.

---

## 4. 🟡 ¿Y adentro de la máquina?

Hay una razón técnica por la que "traits con estado" no era gratis, y entenderla ilumina medio siglo de decisiones de lenguajes. En la implementación estándar, los métodos acceden a las variables **por offset** — 🕳️ la posición fija de la variable dentro del objeto en memoria: "leé la celda 0". Rápido y simple… mientras cada método viva en una sola clase. Un trait vive en muchas:

```
   T2 solo:                     T4 = compone T1 (x,y,z) y T2 (v,x):
     celda 0: v                   celda 0: x   (de T1)
     celda 1: x                   celda 1: y
                                  celda 2: z
   getV compilado como            celda 3: v   (de T2)  ← ¡v ya no es la 0!
   "leé la celda 0"               celda 4: x   (de T2)

   → el MISMO getV, usado en T4, leería la x de T1. Desastre.
```

El estado no se deja linearizar de una vez para todos los usuarios — es el pariente en memoria del problema que la linearización de CLOS tenía en semántica. Tres salidas conocidas, cada una con su factura: **C++** mantiene sub-objetos con punteros internos (*virtual base pointers*) para que cada parte encuentre su estado — potente y pesadísimo, exige una representación de objetos compleja; **Python** guarda las variables en un diccionario por nombre (nada de offsets; un merge son dos claves apuntando al mismo valor) — refleja la semántica directo, pero pagás una búsqueda por cada acceso; y **copy-down** (de Strongtalk — 🕳️ un Smalltalk de alta performance con máquina virtual consciente de mixins): las variables se ordenan linealmente en cada clase concreta, y los métodos que tocan variables **se copian y reajustan** con los offsets de cada usuaria — memoria extra mínima, acceso a costo cero. La implementación de stateful traits eligió copy-down, y los números la avalan: en los benchmarks (streams sincronizados, un chequeador de links HTML), los tiempos con stateful traits, con traits sin estado y sin traits son **indistinguibles**.

---

## 5. 🟡 La prueba: el caso Heap

De vuelta a la jerarquía de colecciones (Parte 4), a visitar una de esas cáscaras del 24%. `Heap` — 🕳️ una colección que mantiene siempre accesible su elemento mínimo (o máximo) — en la versión sin estado:

```
   STATELESS                              STATEFUL
   ─────────────────────────             ─────────────────────────
   Heap                                   Heap
     variables: array, tally, sortBlock     (VACÍA — nada que declarar)
     métodos: SEIS accessors… y nada más      │ usa
       │ usa                                THeapImpl
   THeapImpl (add:, copy, grow…)              (add:, copy, grow…)
     requiere los SEIS accessors              sin requirements de estado
       │ compone                                │ compone
   TArrayBased                              TArrayBased
     requiere array, array:, tally, tally:    DEFINE array, tally ✓
   TSortBlockBased                          TSortBlockBased
     requiere sortBlock…                      DEFINE sortBlock ✓
```

En la versión stateless, `Heap` existe solo para pagar la burocracia: declara las tres variables **que en realidad usan los traits** y les provee los seis accessors que ellos requieren. Con estado en los traits, cada variable **migra a la pieza que la necesita** — `TArrayBased` es dueño de `array` y `tally`; `TSortBlockBased`, de `sortBlock` — los requirements de estado se evaporan en cadena, y `Heap` queda vacía. Y el paso final natural: si `THeapImpl` no tiene ningún otro usuario, su contenido se muda a `Heap` y el trait intermedio **desaparece**. Menos métodos, menos requirements, representación encapsulada: las tres promesas, cobradas.

---

## 6. 🟡 Los detalles finos

**La flattening sobrevive** — era la joya del modelo y la extensión no la rompe. El requisito: al aplanar, las variables del trait deben seguir siendo invisibles fuera de sus métodos. Se logra con *alpha-renaming* — 🕳️ renombrar variables sin cambiar la semántica del código — en la práctica, *name-mangling*: 🕳️ generar nombres únicos anteponiendo el nombre del trait (`lock` → `TSyncReadWrite_lock`) al insertar en el scope de la clase. Accesos y merges aplanan igual: son renombres.

**El radio de los cambios**, comparado con todo lo anterior del bloque: agregar una variable a un trait → **cero clientes afectados** (es privada). Quitarla o renombrarla → afecta *solo* a los clientes directos que se dieron acceso con `@@` — y una vez adaptados ellos, **el efecto no sigue viaje**: los clientes indirectos ni se enteran. Contrastá con la cadena de mixins (override silencioso a distancia) y con los accessors propagándose (§2.3).

**¿`@@` no viola encapsulamiento?** La objeción es legítima: un operador para mirar variables ajenas. La defensa del diseño: el default es black-box total (más estricto que los stateless, que exponían todo vía accessors); la apertura es **selectiva, explícita y del lado del cliente** — white-box a pedido, jamás por accidente; y como el cliente controla los nombres de su scope, ningún cambio remoto puede colarse. Es la misma filosofía de los conflictos de métodos en la Parte 4: no esconder la decisión — exigirla.

**Contra los parientes.** Eiffel (de nuevo): permite compartir features heredados… pero solo puede unificar variables que *provienen de un ancestro común*; el merge de stateful traits une variables de traits sin ningún parentesco — la decisión es del compositor, no del árbol genealógico. Jigsaw (el de Bracha, otra vez): sus módulos sí tienen estado, pero son cajas negras estrictas — las variables **no pueden compartirse** entre módulos; stateful traits eligen el punto medio: negro por defecto, abrible por decisión. Y un detalle de tipos que cierra elegante: en sistemas de módulos con subtipado estructural, la asociatividad hace que composiciones distintas resulten *el mismo tipo* y deban compartir representación — un dolor de cabeza serio; los traits lo esquivan de raíz porque **un trait no define un tipo**.

⚠️ **Nota de actualización** — el material de esta época afirma que los traits de **Scala** no pueden definir estado. Era cierto entonces; los traits de Scala modernos **sí admiten** variables. Lo vas a comprobar de primera mano en la segunda mitad de la materia. Para discutir estos textos: la afirmación va fechada.

---

## 7. 🔴 El arco completo

Fin del bloque. La historia entera, en una foto:

```
 1990                        2003                       2006/07
 Bracha & Cook               Schärli, Ducasse,          Bergel, Ducasse,
                             Nierstrasz, Black          Nierstrasz, Wuyts
──────────────────────────────────────────────────────────────────────────
 herencia simple
 (Smalltalk ↕ Beta:
  un mecanismo,      ╲
  dos direcciones)    ╲
                       ►  MIXINS ──revientan──► TRAITS ──duelen──► TRAITS
 herencia múltiple    ╱   (el delta   (orden      (sin estado,     CON ESTADO
 (CLOS: diamante,    ╱     con vida    total,      conflictos       (privado
  linearización)          propia)      glue        explícitos,      por defecto
                                       disperso,   glue en el       + @@ del
                                       fragilidad  compositor,      cliente)
                                       silenciosa) flattening)
```

| Herramienta | Problema que ataca | Su jugada | Su precio |
|---|---|---|---|
| Herencia simple | definir por diferencia | delta + un padre | no factoriza entre ramas |
| Herencia múltiple | reusar de varios padres | varios padres | diamante, estado ambiguo, `super` roto |
| Linearización (CLOS) | el diamante | grafo → lista, implícita | encapsulamiento violado, sorpresa a distancia |
| Mixins | el delta sin vida propia | subclase abstracta componible | orden total, glue disperso, fragilidad silenciosa |
| Traits | componer sin heredar | piezas chicas sin estado, conflictos explícitos, glue del compositor, flattening | accessors requeridos: boilerplate, cáscaras, propagación |
| Stateful traits | el precio del no-estado | variables privadas + `@@` del cliente | (pregunta abierta abajo) |

Y la moraleja — que no es de este apunte: es la tesis con la que se estudia toda esta materia. **Ninguna de estas herramientas cayó del cielo ni es "la buena". Cada una nace de un problema concreto y medible de la anterior, compra algo específico, y paga con una moneda que engendra a la siguiente.** Saber la historia es saber responder la única pregunta que importa frente a cualquier herramienta de diseño: *¿qué problema real la motivó?* — y su gemela: *¿qué me cuesta salir si me equivoqué?*

El arco queda abierto, además, con una pregunta honesta que en 2007 nadie había respondido: si la composición de traits es tan capaz… **¿puede reemplazar del todo a la herencia como mecanismo primario de estructura?** Quedó como problema abierto. Tenela a mano el sábado: es exactamente el tipo de pregunta que esta cátedra disfruta demoler y reconstruir.

---

## ✅ Checkpoint — Parte 5

*(Sin respuestas — se validan en el chat; las respuestas modelo van al complemento.)*

1. En el `TSyncReadWrite` sin estado, ¿cuáles requirements son "señal" y cuáles "ruido"? ¿Qué distingue a unos de otros?
2. ¿Qué es una shell class y qué proporción de la jerarquía de colecciones refactorizada lo era? ¿Por qué es una ironía para los traits?
3. Un trait sin estado agrega una variable interna nueva. ¿A quiénes afecta y por qué? ¿Y si el trait es stateful?
4. ¿De qué dos maneras violan encapsulamiento los traits sin estado?
5. ¿Por qué con stateful traits los conflictos de variables *no pueden existir* — ni siquiera hay que resolverlos?
6. ¿Qué hace exactamente `T @@ {y -> x}`? ¿En qué scope vive cada nombre? ¿A qué operador de métodos es análogo y en qué se parecen?
7. Describí los tres escenarios de composición de variables y quién decide cuál aplica.
8. ¿Por qué el acceso por offset se rompe cuando un trait con estado se usa en varias clases? ¿Qué estrategia se eligió para resolverlo y qué mostraron los benchmarks?
9. Contá la transformación del caso Heap: qué migró, qué se evaporó y qué quedó vacío.
10. ¿Cómo se preserva la flattening property con variables en juego?

### ✅ Checkpoint integrador — el bloque completo

11. Reconstruí el arco 1990 → 2003 → 2007 en tus palabras: cada herramienta, el problema que la motivó y el precio que pagó.
12. El wrapper de sincronización aparece tres veces en el bloque (SyncA/SyncB imposible, SyncA/SyncB resuelto, SyncStream con espina y sin espina). Contá qué cambia en cada aparición y qué demuestra cada una.
13. "El diamante" atraviesa el bloque entero: ¿cómo lo trata la herencia múltiple, cómo la linearización, por qué los traits lo disuelven para los métodos, y qué les devuelve el control a los clientes para el estado?
14. Un compañero te dice: "los mixins son malos, por eso inventaron los traits". Armá la respuesta que esa afirmación se merece — con los problemas concretos y los precios de cada lado.

---

**FIN DE LA PARTE 5 — FIN DEL APUNTE MAESTRO DE `preclase02`**
