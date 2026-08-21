# 📘 APUNTE MAESTRO — preclase02 · Mixins & Traits — Parte 1

## El mecanismo escondido debajo de la herencia

> **Unidad:** `preclase02` · Parte 1 de 5 · Lectura previa de la clase 2 ("Mixins: resolución de conflictos")

**Qué cubre esta parte:** la herencia de Smalltalk y la de Beta corriendo sobre un mismo caso · la notación formal (records, `⊕`, deltas) que se usa en todo el bloque · la tesis que abre la puerta a los mixins: *son el mismo mecanismo, apuntando en direcciones opuestas*.

**Qué NO cubre (viene después):** herencia múltiple, CLOS y linearización → Parte 2 · mixins como constructo propio → Parte 2 · dónde revientan los mixins → Parte 3 · traits → Parte 4 · traits con estado → Parte 5.

---

## 1. 🔴 La pregunta que abre todo el bloque

A fines de los años 80 convivían tres familias de lenguajes orientados a objetos, y cada una entendía "heredar" de una forma distinta:

- **Smalltalk** — 🕳️ lenguaje OO puro de Xerox (1980), donde todo es un objeto y todo se hace mandando mensajes; el abuelo de la herencia "clásica" que conocés.
- **Beta** — 🕳️ lenguaje danés, heredero directo de Simula (el primer lenguaje con objetos, 1967); su obsesión de diseño es la *seguridad*: que el padre pueda confiar en cómo se comportan sus hijos.
- **CLOS** — 🕳️ el sistema de objetos de Common Lisp, con herencia **múltiple** (una clase puede tener varios padres). Se desarrolla completo en la Parte 2; por ahora solo existe.

A simple vista: tres mecanismos incompatibles. En 1990, Gilad Bracha y William Cook demostraron algo mucho más interesante: **debajo de los tres hay un único mecanismo**, y las diferencias entre Smalltalk y Beta se reducen a *la dirección en la que apunta*. De esa observación va a nacer, en la Parte 2, una herramienta nueva: los mixins.

Esta parte construye esa demostración. Y para eso necesita un caso.

### El caso que atraviesa toda esta parte

Un sistema muestra personas en pantalla:

- Una **Persona** tiene un nombre. Mostrarla imprime el nombre: `A. Smith`
- Un **Graduado** es una persona con título académico. Mostrarlo imprime nombre + título: `A. Smith Ph.D.`
- Más adelante va a aparecer un **Doctor**, que antepone `Dr.` al nombre.

El dominio es deliberadamente chiquito. Lo interesante no son las personas: es **qué pasa cuando el hijo redefine un método del padre y quiere reaprovechar parte del comportamiento heredado**. Ese momento — la colisión entre lo heredado y lo nuevo — es el corazón de las cinco partes de este apunte.

Una forma de nombrar lo que la herencia hace acá: **programación incremental** — 🕳️ definir algo nuevo declarando solamente *en qué difiere* de algo que ya existe. `Graduado` no se escribe desde cero: se escribe como "una Persona, más esto". A ese "más esto" lo vamos a llamar el **delta** (Δ) de la subclase, y va a ser protagonista en unas secciones.

> Los límites de la herencia simple ya los tenés frescos de la clase 1 — acá arranca lo que existe del otro lado de ese límite.

---

## 2. 🟡 Kit de lectura: Smalltalk en diez minutos

Todo el código de esta parte (y buena parte del bloque completo) está en Smalltalk o se compara contra Smalltalk. Es sintaxis nueva, así que va el kit mínimo para leerla sin trabarte. No hace falta escribir Smalltalk — solo leerlo.

La idea central del lenguaje: **no hay "llamadas a función": hay objetos que se mandan mensajes**.

| Se escribe | Se lee | Equivalente mental |
|---|---|---|
| `name display` | "al objeto `name`, mandale el mensaje `display`" | `name.display()` |
| `self` | el objeto que está ejecutando el método | `this` / `self` |
| `super display` | "buscá `display`, pero empezando desde mi clase padre" | `super.display()` |
| `↑ valor` | "retorná este valor" | `return valor` |
| `x := 3` | asignación | `x = 3` |
| `'texto'` | string literal | `"texto"` |
| `"esto es un comentario"` | comentario (¡con comillas dobles!) | `// esto es un comentario` |
| `.` (punto) | fin de sentencia | `;` |

Dos detalles más que van a aparecer:

- **Mensajes con argumentos (keyword messages):** `lista entre: 1 y: 10` es UN solo mensaje llamado `entre:y:` con dos argumentos. Los dos puntos marcan dónde van los argumentos. Se lee como una frase.
- **Definición de clases:** en esta parte se usa una notación declarativa compacta (`class Person ... instance variables: ... method: ...`). En las Partes 4 y 5 vas a ver la forma "real" de Smalltalk moderno (`Object subclass: #Circle ...`), que dice lo mismo con otra ropa. Cuando lleguemos, se señala.

Mini-ejemplo completo, para calibrar el ojo:

```smalltalk
"Un método que saluda dos veces y devuelve el nombre"
saludar
    'Hola' display.        "imprime Hola"
    'Hola' display.        "imprime Hola de nuevo"
    ↑ name                 "retorna el contenido de la variable name"
"Resultado esperado al mandarle saludar a una Person con name='A. Smith':
 imprime HolaHola y devuelve 'A. Smith'"
```

🕳️ **Madriguera — Smalltalk hoy.** Smalltalk sigue vivo (Squeak, Pharo) y varios de los sistemas de las Partes 4 y 5 corren ahí. Instalarlo y jugar es un lindo desvío — para otro día. *Volvé al camino.*

---

## 3. 🔴 Herencia a la Smalltalk: el hijo tiene el micrófono

Arranquemos con el caso funcionando. Persona y Graduado, en Smalltalk:

```smalltalk
"── La clase padre ──────────────────────────────────────────────"
class Person
    instance variables: name        "estado: cada Person guarda su nombre"

    method: display                 "comportamiento: cómo se muestra una Person"
        name display                "manda display al objeto name → imprime el nombre"


"── La subclase ─────────────────────────────────────────────────"
class Graduate
    superclass: Person              "Graduate HEREDA de Person"
    instance variables: degree      "estado propio: el título académico"

    method: display                 "REDEFINE display (mismo nombre que el del padre)"
        super display.              "1º: ejecuta el display del PADRE → imprime el nombre"
        degree display              "2º: agrega lo suyo → imprime el título"
```

```
── ¿CÓMO FUNCIONA? ──────────────────────────────────────────────
g := un Graduate con name = 'A. Smith' y degree = 'Ph.D.'

g display
 │
 ├─ la búsqueda del método arranca en la clase REAL del objeto:
 │  Graduate tiene display ✓ → se ejecuta ESE
 │
 ├─ super display
 │    └─ busca display desde Person hacia arriba → Person.display
 │         └─ name display → imprime "A. Smith"
 │
 └─ de vuelta en el display de Graduate:
      degree display → imprime "Ph.D."

Resultado esperado en pantalla:  A. Smith Ph.D.
─────────────────────────────────────────────────────────────────
```

### El poder de la subclase

Fijate quién tomó todas las decisiones: **Graduate**. Eligió redefinir `display`, eligió llamar al padre, eligió *cuándo* llamarlo. Si quisiera el orden inverso, lo da vuelta y listo:

```smalltalk
"Un Doctor antepone el título honorífico AL nombre"
class Doctor
    superclass: Person

    method: display
        'Dr. ' display.             "primero lo nuevo…"
        super display               "…después lo heredado"
        "Resultado esperado: Dr. A. Smith"
```

Y si quisiera, puede directamente **ignorar al padre**:

```smalltalk
"Una subclase que reemplaza display por completo"
class Rebelde
    superclass: Person

    method: display
        Time now display            "muestra la hora actual. Del nombre, ni noticias."
        "Resultado esperado: 14:32:07 (o la hora que sea)"
```

`Rebelde` **compila y funciona**. Y ese es el punto central de esta sección:

> **En Smalltalk, la subclase manda.** Puede extender, reordenar o reemplazar por completo cualquier método heredado. No existe ninguna forma de escribir `Person` de modo que *obligue* a sus subclases a ejecutar su `display`. El padre propone; el hijo dispone.

Esa libertad es potentísima para reutilizar código… y no ofrece **ninguna garantía de consistencia**: nada asegura que un `Graduate` se comporte "como una Person que además hace algo". Guardá esa tensión — es la que Beta viene a atacar.

> 📌 **Para el parcial, si te preguntan** — *¿Quién controla el comportamiento resultante en la herencia de Smalltalk?*
> La subclase. El método de la subclase reemplaza al del padre en caso de conflicto de nombres, y el acceso al método original es opcional y explícito vía `super` — la subclase decide si lo invoca, cuándo y si lo invoca siquiera. El padre no puede garantizar que su versión se ejecute.

---

## 4. 🔴 La máquina formal: records, `⊕` y el delta

Para demostrar que dos lenguajes con sintaxis distintas comparten un mecanismo, hay que despojarlos de la sintaxis. Esta sección arma ese lenguaje común. Es la notación que te va a acompañar durante **todo el bloque** (la composición de mixins de la Parte 2 se define con estas mismas piezas), así que va despacio y con ejemplos.

### 4.1 Objetos como records

Un **record** es un diccionario de pares nombre → valor. El símbolo `↦` se lee "mapea a".

```
{ display ↦ (código que muestra el nombre),  nombre ↦ 'A. Smith' }
```

Un objeto, mirado con esta lupa, es un record cuyos valores son sus métodos. `r.a` selecciona el campo `a` del record `r` (igual que el acceso a propiedades que conocés de cualquier lenguaje).

### 4.2 El operador `⊕`: combinar dos records

`⊕` combina dos records en uno. Regla de oro, memorizala porque sostiene TODO lo que viene: **ante un conflicto de nombres, gana la izquierda**.

```
{ a ↦ 3, b ↦ 'x' }  ⊕  { a ↦ true, c ↦ 8 }
                    =  { a ↦ 3, b ↦ 'x', c ↦ 8 }

  a → aparece en ambos → gana el de la IZQUIERDA (3)
  b → solo en el izquierdo → pasa tal cual
  c → solo en el derecho  → pasa tal cual
```

¿Te suena de algún lado? Es exactamente lo que hace una subclase de Smalltalk con los métodos del padre: los suyos pisan, los demás se heredan. `⊕` es "redefinición + herencia" destilado a puro dato.

### 4.3 El delta: la subclase como función

Falta modelar `super`. Acá está la jugada elegante: la subclase no es un record — es una **función que recibe al padre y devuelve un record**. A esa función la llamamos Δ (delta): "lo que la subclase agrega/cambia".

Con el caso de la sección 3:

```
P    = { display ↦ (mostrar name) }                    ← Person, como record

Δ(s) = { display ↦ (s.display; mostrar degree) }       ← Graduate, como función
         ────────────┬─────────
                     └── el parámetro s ES super: "el padre que me pasen"
```

Para armar la subclase completa, se le pasa el padre al delta y se combina:

```
C = Δ(P) ⊕ P
```

Desarmemos la ecuación con el caso:

```
Paso 1 — aplicar el delta al padre (esto "cablea" super):
  Δ(P) = { display ↦ (P.display; mostrar degree) }
       = { display ↦ (mostrar name; mostrar degree) }

Paso 2 — combinar con el padre (esto hereda lo no redefinido):
  C = Δ(P) ⊕ P
    = { display ↦ (mostrar name; mostrar degree) }
      ────────────────┬───────────────
      el display nuevo (izquierda) PISA al display de P (derecha).
      Si Person tuviera más métodos, entrarían acá sin tocarse.

C.display  →  imprime "A. Smith Ph.D."   ✓ igual que el código real
```

**Ojo con una confusión clásica:** `P` aparece dos veces en la ecuación y NO significa que haya dos Person. Es una sola definición usada en dos roles distintos: dentro de `Δ(P)` resuelve a qué apunta `super`; en el `⊕ P` aporta los métodos que la subclase no tocó.

Un detalle que parece burocrático y en la Parte 2 se vuelve central: **el delta de Smalltalk no puede vivir solo**. `Δ` siempre nace pegado a una definición de subclase con un padre concreto declarado (`superclass: Person`). No hay forma, en Smalltalk, de agarrar "lo que Graduate agrega" y aplicárselo a OTRO padre. El delta existe… pero no tiene nombre propio ni vida propia. Retenelo.

---

## 5. 🔴 Herencia a la Beta: el padre escribe el guion

Ahora el mismo caso, en el lenguaje diseñado con la prioridad opuesta. Antes, tres términos de Beta con su línea:

- **pattern** — el constructo único de Beta: sirve para definir clases, métodos y tipos. Acá lo vemos solo en su rol de clase.
- **prefijo / subpattern** — el padre se llama *prefijo* (prefix); la definición que lo extiende, *subpattern*. "Graduate está prefijado por Person".
- **`virtual` / `extended` / `inner`** — las tres piezas del mecanismo; se explican en el código mismo.

```beta
(* ── El patrón padre ─────────────────────────────────────────── *)
Person: class
(#  name : string;                (* estado: el nombre *)
    display: virtual proc         (* virtual = "las extensiones PUEDEN engancharse acá"
                                     — NO significa 'libremente redefinible' *)
    (#  do
          name.display;           (* 1º, SIEMPRE: imprime el nombre *)
          inner                   (* 2º: ACÁ se ejecuta lo que agregue el subpattern.
                                     Si nadie extendió, inner = no hacer nada (no-op) *)
    #);
#);

(* ── El subpattern ───────────────────────────────────────────── *)
Graduate: class Person            (* Graduate prefijado por Person *)
(#  degree: string;
    display: extended proc        (* extended = "este código se enchufa en el inner
                                     que el padre dejó abierto" *)
    (#  do
          degree.display;         (* imprime el título… *)
          inner                   (* …y deja SU propio hueco para futuros subpatterns *)
    #);
#);
```

```
── ¿CÓMO FUNCIONA? ──────────────────────────────────────────────
g = un Graduate con name = 'A. Smith' y degree = 'Ph.D.'

g.display
 │
 ├─ el control arranca en el display de PERSON  ← ¡el padre!
 │    name.display → imprime "A. Smith"
 │
 ├─ inner → salta a la extensión aportada por Graduate
 │    degree.display → imprime "Ph.D."
 │
 └─ inner (el de Graduate) → no-op: nadie extendió a Graduate

Resultado esperado en pantalla:  A. Smith Ph.D.
                                 └─ igual que en Smalltalk…
                                    …pero el ORDEN lo fijó Person.
─────────────────────────────────────────────────────────────────
```

La analogía que mejor lo fija: **el padre escribe un guion con huecos marcados**. El método `display` de Person dice "se muestra el nombre, y *acá* — exactamente acá — puede hablar la extensión". El hijo no reescribe el guion: **rellena el hueco que el padre dejó, donde el padre lo dejó**.

### El experimento imposible

En Smalltalk, `Doctor` anteponía `Dr.` al nombre eligiendo el orden de las llamadas. Intentalo en Beta:

```
Quiero:   Dr. A. Smith
Tengo:    Person.display = [ mostrar nombre ; inner ]
                                              └── el ÚNICO lugar donde
                                                  puede correr mi código

Cualquier extensión de display corre DESPUÉS del nombre.
No existe forma, heredando de Person, de ejecutar nada ANTES.
```

Y el reemplazo total tampoco existe: `Rebelde` (el que mostraba la hora) **no se puede escribir en Beta**. `virtual` habilita a extender, jamás a sustituir.

> **En Beta, el padre manda.** El prefijo garantiza su comportamiento: todo lo que Person hace se ejecuta en TODAS sus extensiones, en el orden que Person decidió. A cambio, el hijo pierde la libertad de reordenar o reemplazar. Beta compra **consistencia** (una garantía real de que un Graduate se comporta "como una Person, y algo más") pagando con **rigidez**.

Fijate que es exactamente la tensión de la sección 3, con los platos de la balanza invertidos.

> 📌 **Para el parcial, si te preguntan** — *¿Qué es `inner` y en qué se diferencia de `super`?*
> `inner` es la instrucción con la que un método de Beta cede el control a la extensión que aporte el subpattern (o no hace nada si no hay extensión). Es el espejo de `super`: `super` lo invoca el hijo para ejecutar al padre — el hijo controla; `inner` lo coloca el padre para ejecutar al hijo — el padre controla en qué punto exacto corre el código nuevo. Con `super` el hijo puede omitir al padre; con `inner` el hijo no puede evitar al padre ni moverse del hueco asignado.

---

## 6. 🟡 La formalización de Beta (la simétrica)

La máquina de la sección 4 también expresa a Beta — y ver *cómo* la expresa es ver la inversión con rayos X. Es la parte más densa del apunte; va desarmada pieza por pieza. Lo evaluable acá es la **idea** (quién depende de quién), no reproducir la ecuación de memoria.

Primera pieza: si el hijo de Smalltalk era una función de su padre… **el padre de Beta es una función de su hijo**. Concretamente, de su `inner`:

```
P′(i) = { display ↦ (mostrar name; i.display) }
          ────────────────────────┬─────────
                                  └── i = "lo que venga a rellenar mi hueco"

∅ = el record de métodos nulos: { display ↦ (no hacer nada) }
    Es el "inner apagado".

Person instanciable = P′(∅)        ← Person con el hueco vacío:
                                     muestra el nombre y nada más ✓
```

El subpattern también es una función de SU inner (para futuros nietos):

```
Δ′(i) = { display ↦ (mostrar degree; i.display) }
```

Y la composición completa:

```
C′(i) = P′( Δ′(i) ⊕ i )  ⊕  Δ′(i)
        ───────┬───────      ──┬──
               │               └── los métodos del hijo también entran al
               │                   resultado… pero si chocan con los del
               │                   padre, GANA EL PADRE (⊕ favorece izquierda)
               │
               └── al padre se le enchufa como inner: el hijo,
                   combinado con lo que venga después (los nietos)

C′(i).display  =  mostrar name → mostrar degree → i.display
Graduate instanciable = C′(∅)   →  "A. Smith Ph.D."  ✓
```

La foto que hay que llevarse, lado a lado:

```
Smalltalk:   C  = Δ(P) ⊕ P          el PADRE se le pasa al HIJO
                  ──┬──
                    └── super cableado

Beta:       C′(i) = P′(Δ′(i) ⊕ i) ⊕ Δ′(i)     el HIJO se le pasa al PADRE
                       ────┬────
                           └── inner cableado
```

**La dependencia se dio vuelta.** Mismo juego de piezas — records, `⊕`, funciones — con los roles intercambiados.

Una asimetría fina que el formalismo no muestra pero existe: `inner` es más restrictivo que `super`. Desde el método `display` solo se puede ceder control al `display` de la extensión (al método homónimo); `super`, en cambio, permite invocar *cualquier* método del padre (`super saludar` dentro de `display` es válido en Smalltalk). La restricción es deliberada: más agujeros para saltar entre métodos = menos garantías.

---

## 7. 🔴 Un solo operador, dos direcciones

Todo lo anterior se comprime en un movimiento final. Definamos un único operador de herencia, `▷`:

```
Δ ▷ P  =  Δ(P) ⊕ P

"El izquierdo recibe al derecho como su super/inner, se combinan,
 y en los conflictos gana el izquierdo."
```

(Es un operador **no asociativo** — 🕳️ agrupar distinto da resultados distintos: `(a▷b)▷c ≠ a▷(b▷c)`. Anotalo: en la Parte 2 este detalle vuelve con consecuencias.)

Con `▷`, los dos lenguajes se escriben en una línea cada uno:

```
Smalltalk:   C     =  Δ  ▷ P            ← lo NUEVO a la izquierda
Beta:        C′(∅) =  P′ ▷ Δ′(∅)        ← lo VIEJO a la izquierda
```

**Ese es todo el descubrimiento.** El mecanismo es uno solo. Lo único que distingue a Smalltalk de Beta es *qué pieza ocupa el asiento izquierdo* — es decir, quién gana los conflictos y quién puede ver al otro. La jerarquía de uno es la del otro, cabeza abajo:

```
            SMALLTALK                          BETA

         ┌────────────┐                      Usuario
         │   Parent   │                         │  el mensaje
         └────────────┘                         ▼  ENTRA por
               ▲                          ┌────────────┐
         super │                          │   Prefix   │ ◄── acá vive
               │                          │  (padre)   │     el CONTROL
         ┌────────────┐                   └────────────┘
         │   Child    │ ◄── acá vive            │ inner
         │   (hijo)   │     el CONTROL          ▼
         └────────────┘                   ┌────────────┐
               ▲                          │   Suffix   │
               │  el mensaje              │   (hijo)   │
            Usuario  ENTRA por            └────────────┘

      la autorreferencia (self)      la autorreferencia (var)
      resuelve siempre ABAJO,        resuelve siempre ARRIBA,
      en el objeto más derivado      en el prefijo
```

**Lectura de la figura:** en Smalltalk el usuario le habla al hijo, la delegación (`super`) sube, y `self` ancla la identidad abajo — el "objeto verdadero" es el más derivado. En Beta el usuario le habla al padre, la delegación (`inner`) baja, y la autorreferencia ancla arriba — el prefijo es quien define qué es el objeto. Son la misma foto espejada: el subpattern de Beta juega el rol del *superclass* de Smalltalk, y `inner` es el reflejo exacto de `super`.

La tabla que resume la parte entera:

| | **Smalltalk** | **Beta** |
|---|---|---|
| Al llegar un mensaje, arranca | el hijo | el padre |
| Palabra de delegación | `super` (sube) | `inner` (baja) |
| ¿El hijo puede reemplazar un método? | sí, por completo | no — solo rellenar huecos |
| ¿El hijo elige dónde corre lo suyo? | sí (antes, después, nunca) | no — donde el padre puso `inner` |
| ¿El padre puede garantizar su comportamiento? | no | sí |
| En `⊕`, gana | lo nuevo | lo viejo |
| Ecuación | `C = Δ ▷ P` | `C′(∅) = P′ ▷ Δ′(∅)` |
| Compra | flexibilidad | consistencia / seguridad |
| Paga con | cero garantías | rigidez |

Y un cierre importante, en el espíritu con el que esta materia discute diseño: **ninguna de las dos direcciones puede expresar a la otra**. En Smalltalk no se puede escribir un `Person` inviolable; en Beta no se puede escribir un `Graduate` que decida. No hay "la buena y la mala": hay dos respuestas a problemas distintos, cada una con su costo. Si en la discusión aparece "la herencia de X es mejor" sin un problema concreto sobre la mesa, esa afirmación es indefendible — lo defendible es *qué compra y qué paga cada dirección*.

> 📌 **Para el parcial, si te preguntan** — *¿Por qué se dice que Smalltalk y Beta tienen el mismo mecanismo de herencia?*
> Porque ambos se reducen a la misma operación: combinar el conjunto de atributos nuevos con el heredado, donde un lado tiene prioridad en los conflictos y puede referirse al otro (vía `super` en Smalltalk, vía `inner` en Beta). Formalmente los dos se escriben con el mismo operador `Δ ▷ P = Δ(P) ⊕ P`; solo cambia el orden de los operandos — en Smalltalk las extensiones tienen precedencia sobre lo heredado, en Beta lo heredado tiene precedencia sobre las extensiones. Las jerarquías resultan invertidas: una es el espejo de la otra.

---

## 8. 🟢 Dónde quedamos parados

Tres cabos quedaron deliberadamente abiertos; los tres se retoman en la Parte 2:

1. **El delta no tiene vida propia.** Ni en Smalltalk ni en Beta se puede definir "lo que Graduate agrega" como pieza independiente y aplicarla a padres distintos. Cada delta nace soldado a un padre concreto. ¿Y si se pudiera despegar…?
2. **CLOS sigue esperando.** El tercer lenguaje tiene herencia *múltiple* — varios padres a la vez — y eso trae un problema geométrico nuevo (una clase heredada por dos caminos distintos) con una solución polémica.
3. **La tensión flexibilidad ↔ seguridad no se resolvió** — solo quedó nítida. La herramienta que viene intenta quedarse con lo mejor de ambas direcciones.

En la **Parte 2**: la herencia múltiple de CLOS, el problema del diamante, la linearización y su lado oscuro — y la generalización que convierte al delta en ciudadano de primera clase, con nombre propio: **mixin**.

---

## ✅ Checkpoint — Parte 1

*(Sin respuestas: pensalas, anotalas si querés, y las validamos en el chat. Las respuestas modelo van al complemento.)*

1. ¿Por qué se dice que Smalltalk y Beta implementan **el mismo** mecanismo de herencia? ¿Qué es lo único que cambia entre uno y otro?
2. En `Δ(s)`, ¿qué representa el parámetro `s`? ¿A qué construcción concreta del lenguaje corresponde?
3. En `C = Δ(P) ⊕ P`, `P` aparece dos veces. ¿Significa que hay dos instancias del padre? ¿Qué rol cumple cada aparición?
4. ¿Qué garantiza la herencia de Beta que la de Smalltalk no puede garantizar? ¿Qué precio paga por esa garantía?
5. ¿Por qué es **imposible**, heredando del `Person` de Beta, mostrar `Dr.` antes del nombre — cuando en Smalltalk es trivial?
6. Ante un conflicto de nombres, ¿qué lado gana en `⊕`? ¿Cómo se traduce esa regla en Smalltalk y cómo en Beta?
7. Un equipo necesita que ciertos pasos de un método se ejecuten **siempre**, en todas las subclases presentes y futuras, en un orden fijo. ¿Qué estilo de herencia se lo da, y mediante qué construcción exacta?
8. ¿Qué significa que en Smalltalk "el delta no puede vivir solo"? ¿Por qué ese detalle, que parece menor, deja la puerta abierta a una herramienta nueva?

---

**FIN DE LA PARTE 1** — *sigue en la Parte 2: herencia múltiple, linearización y el nacimiento de los mixins.*
