# 📘 APUNTE MAESTRO — preclase02 · Mixins & Traits — Parte 2

## Herencia múltiple, linearización y el nacimiento de los mixins

> **Unidad:** `preclase02` · Parte 2 de 5 · Lectura previa de la clase 2 ("Mixins: resolución de conflictos")

**Qué cubre esta parte:** la herencia múltiple de CLOS · el problema del diamante · la linearización, lo que arregla y lo que rompe · el mixin como subclase abstracta con vida propia · la propuesta grande: herencia = composición explícita de mixins · la versión tipada (Modula-3).

**Qué NO cubre (viene después):** los mixins puestos a prueba en serio y sus tres dolores → Parte 3 · traits → Parte 4 · estado → Parte 5.

**De la Parte 1 se asume:** la notación de records, `⊕` (gana la izquierda), el delta Δ, el operador `▷`, y la tesis Smalltalk/Beta como direcciones opuestas del mismo mecanismo.

---

## 1. 🔴 CLOS: cuando el padre deja de ser uno solo

El caso crece. Al sistema de personas de la Parte 1 le sumamos un requerimiento nuevo:

- Un **Doctor** es una persona que se muestra con `Dr.` adelante: `Dr. A. Smith`
- Un **Research-Doctor** (doctor que investiga) es doctor **y** graduado a la vez: `Dr. A. Smith Ph.D.`

Ahí está el problema: Research-Doctor quiere heredar de **dos** clases al mismo tiempo. Ni Smalltalk ni Beta pueden expresarlo — ambos son de herencia **simple** (un solo padre). El tercer lenguaje del bloque sí puede: **CLOS**, el sistema de objetos de Common Lisp, con herencia **múltiple**.

### Kit de lectura: CLOS en cinco minutos

CLOS es Lisp, así que todo son paréntesis y notación prefija (primero la operación, después los argumentos). Lo mínimo para leer el código de esta parte:

| Se escribe | Se lee |
|---|---|
| `(defclass Person () (name))` | "definí la clase `Person`, sin padres `()`, con el atributo `name`" |
| `(defclass Graduate (Person) (degree))` | "definí `Graduate`, con padre `Person`, atributo `degree`" |
| `(defmethod display ((self Person)) …)` | "definí el método `display` para instancias de `Person`" |
| `(slot-value self 'name)` | "el valor del atributo `name` de `self`" |
| `(call-next-method)` | delegación — se explica ya mismo, es la estrella de la sección |

El caso base, recodificado:

```lisp
;; ── La clase padre ────────────────────────────────────────────
(defclass Person () (name))              ; Person: sin padres, atributo name

(defmethod display ((self Person))       ; display para Person:
  (display (slot-value self 'name)))     ;   imprime el nombre

;; ── La subclase ───────────────────────────────────────────────
(defclass Graduate (Person) (degree))    ; Graduate hereda de Person

(defmethod display ((self Graduate))     ; display para Graduate:
  (call-next-method)                     ;   1º: ejecutá el SIGUIENTE display
                                         ;       de la cadena de herencia
  (display (slot-value self 'degree)))   ;   2º: imprimí el título
;; Resultado esperado para name='A. Smith', degree='Ph.D.':
;;   A. Smith Ph.D.
```

**`call-next-method` es un híbrido de las dos palabras de la Parte 1.** Juega el rol de `super` (lo invoca el método más nuevo para ejecutar al heredado, cuando él decide), pero con la restricción de `inner`: solo da acceso **al siguiente método de la cadena con el mismo nombre** — no a cualquier método del padre. "El siguiente de la cadena" es la frase clave: en herencia simple la cadena es obvia (hijo → padre → abuelo…); con varios padres, ¿cuál es "el siguiente"? Esa pregunta es el corazón de esta parte.

---

## 2. 🔴 El diamante

Sumemos Doctor y Research-Doctor:

```lisp
(defclass Doctor (Person) ())            ; Doctor hereda de Person, sin atributos nuevos

(defmethod display ((self Doctor))
  (display "Dr. ")                       ; 1º: imprime el prefijo honorífico
  (call-next-method))                    ; 2º: sigue con el display heredado

(defclass Research-Doctor (Doctor Graduate) ())
;;                        └────┬───────┘
;;                    DOS padres, en este orden.
;;                    No define métodos propios: todo heredado.
```

Dibujemos la jerarquía completa:

```
                 ┌────────┐
                 │ Person │            ← heredado por DOS caminos
                 └────────┘
                  ▲      ▲
                 /        \
        ┌────────┐      ┌──────────┐
        │ Doctor │      │ Graduate │
        └────────┘      └──────────┘
                  ▲      ▲
                   \    /
             ┌────────────────┐
             │ Research-Doctor│
             └────────────────┘
```

Esa forma de rombo tiene nombre propio: **el problema del diamante** — una clase (Person) heredada más de una vez, por caminos distintos. Y no es un capricho del ejemplo: es *inevitable* en herencia múltiple, porque casi todas las clases comparten una raíz común (una clase `Object` de la que todo desciende — 🕳️ en los lenguajes OO reales, métodos básicos como comparar o convertir a texto viven ahí, así que **cualquier** herencia múltiple diamantea contra la raíz).

### Qué pasa si nadie hace nada

Recorrido ingenuo del grafo: ejecutar cada camino completo, uno después del otro.

```
(display un-research-doctor)
 │
 ├─ camino 1: Doctor → Person
 │     "Dr. "  →  "A. Smith"
 │
 └─ camino 2: Graduate → Person
       "A. Smith"  →  "Ph.D."      ← ¡Person ejecutado OTRA VEZ!

Resultado (buggeado):  Dr. A. SmithA. Smith Ph.D.
Resultado deseado:     Dr. A. Smith Ph.D.
```

El display de Person corrió dos veces porque Person *está* dos veces en el grafo. Ese es el diamante mordiendo.

---

## 3. 🔴 Linearización: la solución de CLOS… y su precio

La respuesta de CLOS: **aplanar el grafo**. Antes de ejecutar nada, el grafo de ancestros se convierte en una **lista** donde cada clase aparece exactamente una vez, ordenada de más específica a más general:

```
      GRAFO                              LISTA (linearización)

        Person
       ▲      ▲
      /        \                Research-Doctor → Doctor → Graduate → Person
  Doctor    Graduate
       ▲      ▲                 (cada ancestro UNA sola vez,
        \    /                   en un orden total)
    Research-Doctor
```

Con la lista, "el siguiente" de `call-next-method` queda definido sin ambigüedad: es el próximo de la lista que tenga un método con ese nombre. Ejecutemos:

```
── ¿CÓMO FUNCIONA? ──────────────────────────────────────────────
(display un-research-doctor)

 lista: Research-Doctor → Doctor → Graduate → Person

 ├─ Research-Doctor: no define display → se avanza
 ├─ Doctor.display:
 │     imprime "Dr. "
 │     (call-next-method) → el siguiente con display es… Graduate
 │        ├─ Graduate.display:
 │        │     (call-next-method) → el siguiente es… Person
 │        │        └─ Person.display: imprime "A. Smith"
 │        │     imprime "Ph.D."
 │        ▼
 └─ fin

Resultado esperado:  Dr. A. Smith Ph.D.   ✓ y Person corrió UNA vez
─────────────────────────────────────────────────────────────────
```

Y acá viene un click importante con la Parte 1. Con la jerarquía hecha lista, la clase final es sencillamente el operador `▷` **aplicado en cadena** sobre los deltas de la lista:

```
C = Δ₁ ▷ ( Δ₂ ▷ ( … ▷ ( Δₙ ▷ ∅ ) ) )

    Δ₁ = lo que aporta Research-Doctor, Δ₂ = Doctor, Δ₃ = Graduate, Δ₄ = Person
```

La herencia múltiple de CLOS **no es un mecanismo nuevo**: es el mismo mecanismo de Smalltalk/Beta, iterado sobre una lista que la linearización fabricó. Tercer lenguaje, misma máquina.

### El precio

La linearización resuelve el diamante, pero mirá lo que le hizo a la jerarquía en el camino:

```
Doctor declaró:            La linearización decidió:

Doctor hereda              Research-Doctor → Doctor → Graduate → Person
DIRECTAMENTE                                    │        ▲
de Person                                       └────────┘
                                          ¡Graduate se metió ENTRE
                                           Doctor y su padre declarado!
```

El `call-next-method` de Doctor, que en su definición apuntaba "obviamente" a Person, en Research-Doctor ejecuta… Graduate. **Una clase ya no puede saber, leyendo su propia definición, a quién delega**: depende de la jerarquía completa en la que alguien la use. Eso es una violación de **encapsulamiento** — 🕳️ acá, en el sentido de Snyder (1986): que una clase dependa solo de lo que declaró, no de decisiones globales tomadas en otra parte del sistema.

Consecuencias concretas que el análisis de 1990 deja anotadas (y que la Parte 3 va a ver sangrar en la práctica):

- **Sorpresa a distancia:** para predecir qué ejecuta `call-next-method` hay que conocer TODA la jerarquía, no la clase que lo escribe.
- **Fragilidad:** un cambio chico en la jerarquía (por ejemplo, partir una clase base en dos) puede reordenar las cadenas linearizadas de formas muy distintas.

Guardá el juicio final para después de la próxima sección — porque esta misma "traición" de la linearización es la que hace posible la herramienta que viene.

> 📌 **Para el parcial, si te preguntan** — *¿Qué es el problema del diamante y cómo lo resuelve CLOS?*
> El diamante ocurre en herencia múltiple cuando una clase es heredada por más de un camino (típicamente porque los padres comparten un ancestro común), con el riesgo de que sus atributos y métodos se dupliquen o ejecuten repetidos. CLOS lo resuelve linearizando: convierte el grafo de ancestros en una lista donde cada clase aparece una sola vez, y `call-next-method` recorre esa lista. El costo es que la linearización puede alterar las relaciones padre-hijo declaradas (insertar clases entre una clase y su padre directo), violando el encapsulamiento: el comportamiento de una clase pasa a depender de la jerarquía global.

---

## 4. 🔴 Mixins: el delta consigue nombre propio

Cambio de escena, mismo sistema. Requerimiento nuevo:

> En el sistema también hay **perros**. Y un **perro guardián** tiene diploma… de la escuela de obediencia. Al mostrarse: `Rex obediencia-nivel-2`.

O sea: "lo de graduado" — tener un `degree` y agregarlo al display — lo quiero aplicar a personas **y** a perros. Dos jerarquías sin nada en común (salvo la raíz). ¿Cómo se escribe "lo de graduado" UNA sola vez?

En CLOS, los programadores de la época ya lo hacían, con un truco idiomático:

```lisp
;; ── "Lo de graduado", como pieza suelta ───────────────────────
(defclass Graduate-mixin () (degree))    ; ¡SIN padres! solo el atributo degree

(defmethod display ((self Graduate-mixin))
  (call-next-method)                     ; ⚠️ delega… ¿a QUIÉN? no tiene padre.
  (display (slot-value self 'degree)))   ; después agrega el título
```

Ese `call-next-method` "colgando" — invocado por una clase que no aparenta tener a quién delegar — es la firma del patrón. Si instanciás `Graduate-mixin` solo y llamás `display`, **error**: la delegación no tiene destino. La pieza no está pensada para instanciarse; está pensada para **mezclarse**:

```lisp
(defclass Graduate  (Graduate-mixin Person) ())   ; persona graduada
(defclass Guard-Dog (Graduate-mixin Dog) ())      ; perro con diploma
;; Resultado esperado:
;;   (display una-graduate)  → A. Smith Ph.D.
;;   (display un-guard-dog)  → Rex obediencia-nivel-2
```

```
     Graduate-mixin                Graduate-mixin
           +                             +
        Person                          Dog
           │                             │
           ▼                             ▼
       Graduate                      Guard-Dog

   la MISMA pieza, aplicada a dos padres distintos
```

¿Por qué funciona? Por la linearización: al listar `Graduate-mixin` **antes** del padre, la cadena queda `Graduate → Graduate-mixin → Person`, y el `call-next-method` del mixin encuentra destino: el display de Person (o de Dog). La linearización le enchufa el padre.

A esta pieza se la llama **mixin**: una **subclase abstracta** — una definición de subclase *sin padre fijado*, aplicable a padres distintos para fabricar una familia de clases modificadas. ¿Te suena? **Es el delta de la Parte 1, con nombre propio y vida propia.** El cabo suelto nº 1 ("el delta no puede vivir solo") acaba de cerrarse: en CLOS, sí puede.

Tres observaciones que arman el puente a la propuesta grande:

1. **En CLOS el mixin es solo una convención.** No hay estatus formal: cualquier clase que aporte comportamiento parcial "puede usarse de mixin". El lenguaje no sabe que existen.
2. **Smalltalk y Beta no pueden expresarlo — y fallan en espejo.** En Smalltalk, para "mezclar lo de graduado" en dos jerarquías hay que *copiar el código del mixin* en cada subclase. En Beta, un prefijo se parece mucho a un mixin… pero no se puede enchufar a clases ya definidas: hay que *copiar la clase base* por cada combinación. El que crece hacia abajo copia lo de arriba; el que crece hacia arriba copia lo de abajo — es la dirección de crecimiento de la Parte 1 mostrando los dientes.
3. **La revelación técnica:** ¿qué hace exactamente la linearización cuando ubica al mixin en la cadena y le "enchufa" el padre? Le está ligando su parámetro padre formal a una clase concreta. Es decir: **linearizar = aplicar una función**. El mixin es una función esperando su padre; la linearización es el mecanismo (escondido, implícito, global) que se la pasa. Y la crítica del encapsulamiento, leída con esta luz, cambia de signo: la técnica de mixins *depende* de que la linearización meta clases entre padre e hijo — eso no es un bug de la técnica, es su mecanismo de aplicación disfrazado. El problema no son los mixins: es que la aplicación esté **escondida**.

> 📌 **Para el parcial, si te preguntan** — *¿Qué es un mixin?*
> Una subclase abstracta: la especificación de una extensión (métodos y atributos que agrega o redefine) sin un padre fijado, que puede aplicarse a distintas clases padre para generar una familia de clases modificadas. En CLOS se reconoce porque invoca `call-next-method` sin tener un padre aparente — el destino de esa delegación lo decide la linearización al componerlo con una clase concreta. Conceptualmente es el "delta" de la herencia simple, promovido a pieza independiente y reutilizable.

---

## 5. 🔴 La propuesta: herencia = composición de mixins

Si el mixin es la abstracción real y la linearización solo una forma turbia de aplicarlo, el paso honesto es darlo vuelta: **que el mixin sea el constructo primario del lenguaje, y la herencia se defina como composición explícita de mixins**. Esa es la propuesta de Bracha y Cook.

La pieza técnica es un operador de composición, `⋆`, que toma **dos mixins y devuelve otro mixin**:

```
M₁ ⋆ M₂  =  fun(i)  M₁( M₂(i) ⊕ i )  ⊕  M₂(i)
```

Miralo bien, porque ya lo conocés — es la fórmula de Beta de la Parte 1, con una diferencia decisiva:

```
Beta (Parte 1):   C′(i) = P′( Δ′(i) ⊕ i ) ⊕ Δ′(i)     dos piezas → un RECORD
Composición ⋆:    M₁⋆M₂ = fun(i) M₁( M₂(i) ⊕ i ) ⊕ M₂(i)   dos mixins → OTRO MIXIN
```

El resultado **sigue siendo función de `i`** — sigue teniendo el enchufe libre. Por eso se puede seguir componiendo: `M₁ ⋆ M₂ ⋆ M₃ ⋆ …`, cadenas de cualquier largo. En la composición, `M₁` (izquierda) gana los conflictos y su `super`/`inner` queda ligado a `M₂`; el `super`/`inner` de `M₂` queda ligado al enchufe `i` del resultado — esperando al próximo de la cadena.

### Las propiedades, y por qué importan

- **`⋆` es asociativo** (porque `⊕` lo es): `(M₁⋆M₂)⋆M₃ = M₁⋆(M₂⋆M₃)`. Las cadenas se escriben sin paréntesis y se pueden partir en sub-piezas con nombre — `PGMixin = PersonMixin ⋆ GraduateMixin` es una pieza legítima, reusable a su vez.
- **`⋆` NO es conmutativo** (porque `⊕` favorece a la izquierda): `M₁⋆M₂ ≠ M₂⋆M₁`. **El orden importa — y por eso lo elegís VOS, explícitamente.** Nada de algoritmo global decidiendo por atrás: donde CLOS linearizaba implícitamente, acá el programador escribe la cadena con sus manos. La "sorpresa a distancia" de la sección 3 desaparece por construcción.
- Si componés el mismo mixin dos veces en una cadena, **aparece dos veces** (duplicación explícita y visible — comparalo con el diamante silencioso). ¿Querés compartirlo? Componés las dos piezas sobre un padre común, una sola vez.

### La taxonomía que ordena todo

Con el mixin como constructo primario, las nociones clásicas quedan como casos particulares:

| Noción clásica | En el modelo de mixins |
|---|---|
| Clase ordinaria | mixin **degenerado**: ignora su enchufe `i` (no usa `super`/`inner`) |
| Clase abstracta | mixin que usa métodos que no define en sí mismo |
| Mixin **completo** | no depende de su enchufe y define todo lo que usa → **instanciable** |
| Mixin **parcial** | le falta algo (usa el enchufe o métodos ajenos) → solo componible |
| Herencia Smalltalk | componer con lo nuevo a la IZQUIERDA (el delta gana) |
| Herencia Beta | componer con lo viejo a la IZQUIERDA (el prefijo gana) |
| Jerarquía CLOS | una cadena explícita de mixins (la linearización, escrita a mano) |

Un solo constructo expresa los tres lenguajes del bloque. La tesis de la Parte 1 ("un mecanismo, dos direcciones") escaló a: **un constructo, todas las herencias**.

> 📌 **Para el parcial, si te preguntan** — *¿Qué relación hay entre la linearización de CLOS y los mixins?*
> La linearización es, en los hechos, el mecanismo de aplicación de los mixins: al ordenar el grafo en una cadena, liga el padre formal de cada mixin a la clase que le sigue en la lista. La crítica de que "viola encapsulamiento" apunta a que esa aplicación es implícita y global. La propuesta de la herencia por composición de mixins conserva la idea (cadenas de aplicación) pero hace el orden explícito y elegido por el programador, eliminando la resolución escondida.

---

## 6. 🟡 La prueba de fuego: mixins con tipos (Modula-3)

Una idea de diseño vale más si sobrevive fuera de su nicho. Los tres lenguajes del bloque son dinámicos; la propuesta se puso a prueba esbozándola sobre **Modula-3** — 🕳️ lenguaje imperativo de DEC/Olivetti (1989), herencia simple y **tipado estático fuerte**: el peor clima posible para una idea nacida en Lisp. Los mixins nunca habían pisado un lenguaje tipado.

Lo esencial del esbozo, comprimido:

**a) El mixin se declara suelto, y el tipo exige una cláusula extra.** Sin padre a la vista, el compilador no puede inferir ni la firma ni el valor de lo que `super` va a invocar. Solución: declararlo.

```modula3
type GraduateMixin =
  object degree: string
  methods display := displayGraduateMixin
  super  display() := No_Op        (* ← la cláusula nueva: declara que ESTE mixin
                                       redefine display, fija su firma, y le da
                                       un valor por defecto si nadie lo provee *)
  end;

procedure No_Op(self: root) = begin end No_Op;
  (* un procedimiento que no hace nada, válido para cualquier objeto.
     ¿Lo reconocés? Es el ∅ de la Parte 1, hecho sintaxis. *)
```

**b) La composición es por yuxtaposición — con la prioridad INVERTIDA en la página.** Para parecerse a la sintaxis existente de Modula-3 (la modificación se escribe a la derecha de la base), acá **gana el operando derecho**. Misma álgebra que `⋆`, espejada en el papel — no te comas la trampa al leerla:

```modula3
type Graduate = Person GraduateMixin;
     (* GraduateMixin (derecha) tiene prioridad y ve a Person vía super
        → rol Smalltalk: el mixin actúa de subclase *)

type Graduate = GraduateMixin PersonMixin;
     (* PersonMixin (derecha) tiene prioridad; su super es GraduateMixin
        → ¡rol Beta! el "padre" controla — invertiste la posición,
          invertiste el rol. La dualidad de la Parte 1, elegible por sintaxis. *)
```

**c) El diamante de la sección 3, recodificado sin linearización:**

```modula3
type ResearchDoctor = PersonMixin GraduateMixin Doctor;
     (* la cadena que CLOS calculaba a escondidas, escrita a mano,
        a la vista, elegida por el programador. Cada pieza reusable
        sin copiar una línea. *)
```

**d) El tipado cierra.** Reglas principales, en cuatro líneas: toda composición es subtipo de cada una de sus partes (`ResearchDoctor ≤ Doctor`, `≤ GraduateMixin`, `≤ PersonMixin`); como la composición es asociativa, también `ResearchDoctor ≤ PGMixin` si `PGMixin = PersonMixin GraduateMixin` — el subtipado respeta el álgebra; `super` solo puede usarse en procedimientos marcados `mixin procedure`, y estos solo se invocan como métodos (nadie puede manosear desde afuera los métodos redefinidos de una instancia). Todo **estáticamente chequeable** — condición necesaria para seguridad y eficiencia.

La moraleja de la sección, más que el detalle sintáctico: la idea **tipa**. No era un truco de lenguajes dinámicos.

---

## 7. 🔴 Balance: qué compró y qué pagó la propuesta

En el espíritu con el que esta materia discute diseño — nada es gratis, la pregunta es siempre qué comprás y con qué lo pagás:

**Compra:**
- El delta como pieza con nombre, reutilizable sobre padres distintos, **sin copiar texto** (lo que Smalltalk y Beta no podían).
- Las dos direcciones de la Parte 1 disponibles a elección, por posición en la cadena.
- Las jerarquías de herencia múltiple de CLOS, expresables **sin resolución implícita**: el orden lo escribe el programador.
- Asociatividad: sub-cadenas con nombre, componibles a su vez.

**Paga:**
- La jerarquía deja de ser un grafo declarado y pasa a ser una **colección de cadenas explícitas**; una clase puede aparecer en muchas cadenas.
- Ciertos cambios estructurales se vuelven difíciles — en particular los que ya violaban encapsulamiento (partir una clase base en dos factores puede obligar a reescribir varias cadenas).
- La duplicación por composición repetida es posible (aunque al menos es visible y evitable).
- El orden sigue siendo **total y lineal**: toda la cadena, un solo hilo. Anotá esta palabra — *lineal* — porque la Parte 3 la va a convertir en acusación.

Si en la discusión aparece "los mixins arreglan la herencia múltiple" o "la linearización es mala", a secas: ambas son indefendibles sin el problema concreto sobre la mesa. Lo defendible: qué problema resolvía cada mecanismo, qué precio pagaba, y quién hereda ese precio.

---

## 8. 🟢 Dónde quedamos parados

La propuesta de 1990 es elegante en el papel. La pregunta que abre la Parte 3 es la que esta materia hace siempre: **¿y en la práctica?** Trece años después, un grupo de investigación con un sistema real entre manos escribió la respuesta — y no es amable. Tres dolores con nombre: el **orden total** que a veces no existe, el **glue code disperso** por las clases intermedias, y las **jerarquías frágiles** que se rompen en silencio. Los mixins pasan de solución a acusados.

---

## ✅ Checkpoint — Parte 2

*(Sin respuestas — se validan en el chat; las respuestas modelo van al complemento.)*

1. ¿Por qué la herencia múltiple hace prácticamente inevitable el problema del diamante, aun cuando el programador no dibuje rombos a propósito?
2. Sin linearización, ¿qué imprimía exactamente el display de un Research-Doctor y por qué?
3. ¿En qué sentido `call-next-method` es un híbrido entre `super` y `inner`?
4. La linearización "traiciona" la declaración de Doctor. ¿Qué declaró Doctor, qué decidió la linearización, y por qué eso viola encapsulamiento?
5. ¿Cómo se reconoce, leyendo código CLOS, que una clase está pensada como mixin? ¿Qué pasa si la instanciás sola?
6. "Linearizar es aplicar." Explicá qué se está aplicando a qué, y por qué esa lectura cambia el signo de la crítica a la linearización.
7. `⋆` es asociativo pero no conmutativo. ¿Qué habilita cada propiedad (o su ausencia) en la práctica de composición?
8. ¿Cómo expresa el modelo de composición de mixins (a) una clase común, (b) la herencia estilo Smalltalk, (c) la estilo Beta, (d) una jerarquía CLOS?
9. En la versión tipada, ¿qué información aporta la cláusula `super display() := No_Op` y qué concepto de la Parte 1 encarna `No_Op`?

---

**FIN DE LA PARTE 2** — *sigue en la Parte 3: donde los mixins revientan.*
