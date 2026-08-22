# 📗 APUNTE RESUMEN — preclase02 · Mixins & Traits

> **Unidad:** `preclase02` · Destila el apunte maestro (5 partes) · Lectura previa de la clase 2 ("Mixins: resolución de conflictos")
>
> **Marcas:** 🔴🟡🟢 importancia (heredadas del maestro) · **🎯 esencial para aplicar** · **📘 contexto para parcial**. Repaso exprés: leé solo los 🎯.

---

# PARTE 1 — El mecanismo escondido debajo de la herencia

## 1.1 🔴📘 La pregunta del bloque

Tres lenguajes de fines de los 80, tres "herencias": **Smalltalk** (OO puro, todo es mensajes), **Beta** (danés, heredero de Simula, obsesión: seguridad), **CLOS** (Lisp, herencia múltiple). Bracha & Cook (1990): **debajo hay un único mecanismo; Smalltalk y Beta solo difieren en la dirección**. Caso del bloque: `Person` muestra su nombre (`A. Smith`); `Graduate` agrega título (`A. Smith Ph.D.`); luego `Doctor` antepone `Dr.`. Herencia = **programación incremental**: definir lo nuevo como diferencia (**delta, Δ**) sobre lo existente.

## 1.2 🟡📘 Kit Smalltalk

`name display` = "mandale el mensaje display a name" · `self` = this · `super m` = buscá `m` desde la clase padre · `↑` = return · `:=` asigna · `"…"` = comentario · `.` = fin de sentencia · `entre: 1 y: 10` = UN mensaje `entre:y:` con dos argumentos · `| x |` = variable temporal · `[ … ]` = bloque (lambda) · `#nombre` = symbol · `Circle>>hash` = "el método hash de Circle".

## 1.3 🔴🎯 Smalltalk: el hijo tiene el micrófono

```smalltalk
class Person
    instance variables: name
    method: display
        name display                "imprime el nombre"

class Graduate
    superclass: Person
    instance variables: degree
    method: display                 "REDEFINE display"
        super display.              "1º ejecuta el del padre → nombre"
        degree display              "2º agrega el título"
"g display → A. Smith Ph.D. (la búsqueda arranca en la clase REAL del objeto)"
```

La subclase decide todo: puede extender, reordenar (`'Dr. ' display. super display` → `Dr. A. Smith`) o **reemplazar por completo** (un display que muestra la hora: compila). **La subclase manda; Person no puede garantizar que su display se ejecute.** Flexibilidad total, cero garantías de consistencia.

> 📌 **Para el parcial, si te preguntan** — *¿Quién controla el comportamiento resultante en la herencia de Smalltalk?*
> La subclase. El método de la subclase reemplaza al del padre en caso de conflicto de nombres, y el acceso al método original es opcional y explícito vía `super` — la subclase decide si lo invoca, cuándo y si lo invoca siquiera. El padre no puede garantizar que su versión se ejecute.

## 1.4 🔴🎯 La máquina formal: records, `⊕`, Δ

Objeto = **record** (diccionario nombre→valor; `↦` = "mapea a"; `r.a` selecciona). **`⊕` combina records; ante conflicto GANA LA IZQUIERDA** (regla que sostiene todo el bloque):

```
{ a↦3, b↦'x' } ⊕ { a↦true, c↦8 }  =  { a↦3, b↦'x', c↦8 }
```

La subclase es una **función del padre** (el parámetro ES `super`):

```
P    = { display ↦ (mostrar name) }                    ← Person
Δ(s) = { display ↦ (s.display; mostrar degree) }       ← Graduate; s = super
C    = Δ(P) ⊕ P                                        ← la subclase completa
     = { display ↦ (mostrar name; mostrar degree) }
```

`P` aparece dos veces = una sola instancia, dos roles (resolver `super` / aportar lo no pisado). **El Δ de Smalltalk no puede vivir solo**: nace soldado a un padre concreto — retener para P2.

## 1.5 🔴🎯 Beta: el padre escribe el guion

Vocabulario: **pattern** (constructo único de Beta), **prefijo/subpattern** (padre/hijo), `virtual` (extensible, NO libremente redefinible), `extended` (se enchufa en el hueco), `inner` (el hueco).

```beta
Person: class
(#  name : string;
    display: virtual proc
    (#  do  name.display;      (* 1º SIEMPRE el nombre *)
            inner              (* 2º ACÁ corre la extensión del hijo;
                                  sin hijo, inner = no-op *)
    #);  #);

Graduate: class Person
(#  degree: string;
    display: extended proc
    (#  do  degree.display; inner  #);  #);
(* g.display → arranca en PERSON: nombre, inner→título → A. Smith Ph.D.
   Mismo output que Smalltalk, pero el ORDEN lo fijó Person *)
```

Analogía: **guion con huecos marcados** — el hijo rellena donde el padre dejó `inner`. Imposible anteponer `Dr.` (el hueco quedó después del nombre) e imposible reemplazar. **El padre manda:** compra consistencia garantizada, paga rigidez.

> 📌 **Para el parcial, si te preguntan** — *¿Qué es `inner` y en qué se diferencia de `super`?*
> `inner` es la instrucción con la que un método de Beta cede el control a la extensión que aporte el subpattern (o no hace nada si no hay extensión). Es el espejo de `super`: `super` lo invoca el hijo para ejecutar al padre — el hijo controla; `inner` lo coloca el padre para ejecutar al hijo — el padre controla en qué punto exacto corre el código nuevo. Con `super` el hijo puede omitir al padre; con `inner` el hijo no puede evitar al padre ni moverse del hueco asignado.

## 1.6 🟡📘 La formalización de Beta

El padre es **función de su hijo** (de su `inner`); `∅` = record de métodos nulos (inner apagado):

```
P′(i) = { display ↦ (mostrar name; i.display) }        Person = P′(∅)
Δ′(i) = { display ↦ (mostrar degree; i.display) }
C′(i) = P′( Δ′(i) ⊕ i ) ⊕ Δ′(i)                        Graduate = C′(∅)
        └── al padre se le enchufa el hijo ──┘└─ y si chocan, gana el padre ─┘
```

Smalltalk: el padre se le pasa al hijo. Beta: el hijo se le pasa al padre. **La dependencia se invirtió.** Detalle: `inner` es más restrictivo que `super` (solo cede al método homónimo; `super` puede invocar cualquier método del padre) — deliberado, por seguridad.

## 1.7 🔴🎯 Un solo operador, dos direcciones

```
Δ ▷ P = Δ(P) ⊕ P        ("el izquierdo recibe al derecho como super/inner,
                          se combinan, gana el izquierdo" — NO asociativo)

Smalltalk:  C     = Δ  ▷ P        ← lo NUEVO a la izquierda
Beta:       C′(∅) = P′ ▷ Δ′(∅)    ← lo VIEJO a la izquierda
```

```
      SMALLTALK                 BETA
   ┌──────────┐              Usuario
   │  Parent  │                 ▼
   └────┬─────┘            ┌──────────┐
        ▲ super            │  Prefix  │◄─ control (var ancla acá)
   ┌────┴─────┐            └────┬─────┘
   │  Child   │◄─ control       │ inner
   └──────────┘  (self          ▼
        ▲         ancla acá) ┌──────────┐
     Usuario                 │  Suffix  │
                             └──────────┘
```

| | Smalltalk | Beta |
|---|---|---|
| Arranca | el hijo | el padre |
| Delegación | `super` (sube) | `inner` (baja) |
| ¿Reemplazar? | sí, total | no — solo rellenar huecos |
| ¿Padre garantiza? | no | sí |
| En `⊕` gana | lo nuevo | lo viejo |
| Compra / paga | flexibilidad / sin garantías | consistencia / rigidez |

**Ninguna dirección expresa a la otra.** No hay "la buena": dos respuestas a problemas distintos.

> 📌 **Para el parcial, si te preguntan** — *¿Por qué se dice que Smalltalk y Beta tienen el mismo mecanismo de herencia?*
> Porque ambos se reducen a la misma operación: combinar el conjunto de atributos nuevos con el heredado, donde un lado tiene prioridad en los conflictos y puede referirse al otro (vía `super` en Smalltalk, vía `inner` en Beta). Formalmente los dos se escriben con el mismo operador `Δ ▷ P = Δ(P) ⊕ P`; solo cambia el orden de los operandos — en Smalltalk las extensiones tienen precedencia sobre lo heredado, en Beta lo heredado tiene precedencia sobre las extensiones. Las jerarquías resultan invertidas: una es el espejo de la otra.

## 1.8 🟢📘 Cabos abiertos

(1) El delta no tiene vida propia. (2) CLOS (herencia múltiple) pendiente. (3) La tensión flexibilidad↔seguridad quedó nítida, no resuelta.

## ✅ Checkpoint P1

1. ¿Por qué Smalltalk y Beta implementan el mismo mecanismo? ¿Qué es lo único que cambia? · 2. ¿Qué representa `s` en `Δ(s)`? · 3. ¿Por qué `P` aparece dos veces en `C = Δ(P) ⊕ P`? · 4. ¿Qué garantiza Beta que Smalltalk no puede, y a qué costo? · 5. ¿Por qué es imposible el `Dr.` antes del nombre en Beta? · 6. ¿Qué gana en `⊕` y cómo se traduce en cada lenguaje? · 7. Pasos que deben ejecutarse siempre en todas las subclases: ¿qué estilo y qué construcción? · 8. ¿Qué significa que el delta "no puede vivir solo" y qué puerta abre?

---

# PARTE 2 — Herencia múltiple, linearización y el nacimiento de los mixins

## 2.1 🔴🎯 CLOS y `call-next-method`

Caso nuevo: `Research-Doctor` = doctor Y graduado (`Dr. A. Smith Ph.D.`) → necesita **dos padres** → CLOS. Kit: `(defclass Graduate (Person) (degree))` = clase, padres, atributos · `(defmethod display ((self Graduate)) …)` · `(slot-value self 'name)` = leer atributo · **`(call-next-method)`** = híbrido: rol de `super` (lo invoca el nuevo, cuando quiere) con la restricción de `inner` (solo el **siguiente método homónimo de la cadena**). Con varios padres, "¿cuál es el siguiente?" es LA pregunta.

```lisp
(defmethod display ((self Graduate))
  (call-next-method)                     ; el siguiente display de la cadena
  (display (slot-value self 'degree)))   ; después, el título
```

## 2.2 🔴🎯 El diamante

```
            Person        ← heredado por DOS caminos
           ▲      ▲
      Doctor    Graduate
           ▲      ▲
        Research-Doctor
```

**Diamante** = una clase heredada por más de un camino. Recorrido ingenuo (cada camino entero): Person corre dos veces → `Dr. A. SmithA. Smith Ph.D.`. Es **inevitable** en herencia múltiple: todas las clases comparten raíz (`Object`) con los métodos universales.

## 2.3 🔴🎯 Linearización: solución y precio

CLOS **aplana el grafo en una lista** (cada ancestro una vez, de específico a general): `Research-Doctor → Doctor → Graduate → Person`. `call-next-method` recorre la lista → `Dr. A. Smith Ph.D.` ✓. Formalmente: **`C = Δ₁ ▷ (Δ₂ ▷ (… ▷ (Δₙ ▷ ∅)))`** — el mismo operador de P1, iterado: tercer lenguaje, misma máquina.

**Precio:** Doctor declaró heredar directo de Person; la linearización le metió Graduate en el medio. Una clase ya no sabe, leyendo su definición, a quién delega → viola **encapsulamiento** (sentido Snyder: depender solo de lo declarado, no de decisiones globales). Consecuencias: sorpresa a distancia + fragilidad ante cambios chicos de jerarquía.

> 📌 **Para el parcial, si te preguntan** — *¿Qué es el problema del diamante y cómo lo resuelve CLOS?*
> El diamante ocurre en herencia múltiple cuando una clase es heredada por más de un camino (típicamente porque los padres comparten un ancestro común), con el riesgo de que sus atributos y métodos se dupliquen o ejecuten repetidos. CLOS lo resuelve linearizando: convierte el grafo de ancestros en una lista donde cada clase aparece una sola vez, y `call-next-method` recorre esa lista. El costo es que la linearización puede alterar las relaciones padre-hijo declaradas (insertar clases entre una clase y su padre directo), violando el encapsulamiento: el comportamiento de una clase pasa a depender de la jerarquía global.

## 2.4 🔴🎯 Mixins: el delta con nombre propio

Caso: "lo de graduado" aplicable a personas **y** a perros (`Guard-Dog` con diploma de obediencia).

```lisp
(defclass Graduate-mixin () (degree))    ; SIN padres
(defmethod display ((self Graduate-mixin))
  (call-next-method)                     ; delegación "colgando": la firma
  (display (slot-value self 'degree)))   ;   del patrón. Solo, da ERROR.

(defclass Graduate  (Graduate-mixin Person) ())   ; → A. Smith Ph.D.
(defclass Guard-Dog (Graduate-mixin Dog) ())      ; → Rex obediencia-nivel-2
```

**Mixin = subclase abstracta**: extensión sin padre fijado, aplicable a padres distintos. Es **el Δ de P1 con vida propia**. Claves: (1) en CLOS es pura convención, sin estatus formal; (2) Smalltalk y Beta fallan en espejo (uno copia el mixin, el otro copia la base — la dirección de crecimiento); (3) **linearizar = aplicar**: la linearización liga el padre formal del mixin a una clase concreta — el problema no son los mixins, es que la aplicación esté escondida.

> 📌 **Para el parcial, si te preguntan** — *¿Qué es un mixin?*
> Una subclase abstracta: la especificación de una extensión (métodos y atributos que agrega o redefine) sin un padre fijado, que puede aplicarse a distintas clases padre para generar una familia de clases modificadas. En CLOS se reconoce porque invoca `call-next-method` sin tener un padre aparente — el destino de esa delegación lo decide la linearización al componerlo con una clase concreta. Conceptualmente es el "delta" de la herencia simple, promovido a pieza independiente y reutilizable.

## 2.5 🔴🎯 Herencia = composición de mixins

Propuesta: el mixin como constructo primario, con operador de composición que devuelve **otro mixin** (sigue componible):

```
M₁ ⋆ M₂  =  fun(i)  M₁( M₂(i) ⊕ i )  ⊕  M₂(i)
   (la fórmula de Beta de P1, pero mixin × mixin → mixin;
    M₁ gana conflictos y ve a M₂; M₂ ve al próximo de la cadena)
```

Propiedades: **asociativo** (sub-cadenas con nombre: `PGMixin = PersonMixin ⋆ GraduateMixin`) y **NO conmutativo** → el orden importa **y lo escribe el programador** (adiós linearización implícita). Duplicación posible pero visible. Taxonomía: clase ordinaria = mixin degenerado (ignora `i`) · abstracta = usa lo que no define · **completo** (instanciable) vs **parcial** · Smalltalk = nuevo a la izquierda · Beta = viejo a la izquierda · CLOS = la cadena, a mano.

> 📌 **Para el parcial, si te preguntan** — *¿Qué relación hay entre la linearización de CLOS y los mixins?*
> La linearización es, en los hechos, el mecanismo de aplicación de los mixins: al ordenar el grafo en una cadena, liga el padre formal de cada mixin a la clase que le sigue en la lista. La crítica de que "viola encapsulamiento" apunta a que esa aplicación es implícita y global. La propuesta de la herencia por composición de mixins conserva la idea (cadenas de aplicación) pero hace el orden explícito y elegido por el programador, eliminando la resolución escondida.

## 2.6 🟡📘 Modula-3: la idea tipa

Mixins esbozados sobre un lenguaje de tipado estático fuerte. El mixin suelto exige cláusula `super display() := No_Op` (declara firma + default; `No_Op` = el `∅` hecho sintaxis). Composición por yuxtaposición **con prioridad al operando DERECHO** (sintaxis espejada de `⋆` — trampa de lectura): `type Graduate = Person GraduateMixin` (rol Smalltalk) vs `type Graduate = GraduateMixin PersonMixin` (rol Beta — posición invertida, rol invertido). El diamante sin linearización: `type ResearchDoctor = PersonMixin GraduateMixin Doctor`. Tipos: la composición es subtipo de cada parte; asociatividad respetada (`ResearchDoctor ≤ PGMixin`); `super` solo en `mixin procedure`; todo chequeable estáticamente.

## 2.7 🔴📘 Balance

**Compra:** delta reusable sin copiar · ambas direcciones a elección por posición · jerarquías CLOS sin resolución implícita · sub-cadenas nombrables. **Paga:** la jerarquía = colección de cadenas · ciertos refactors difíciles · duplicación posible · **el orden sigue siendo total y lineal** (la palabra que P3 convierte en acusación).

## 2.8 🟢📘 Siembra

2003: la práctica dicta veredicto — tres dolores con nombre.

## ✅ Checkpoint P2

1. ¿Por qué el diamante es inevitable en herencia múltiple? · 2. Sin linearización, ¿qué imprimía Research-Doctor y por qué? · 3. ¿En qué sentido `call-next-method` es híbrido super/inner? · 4. ¿Qué declaró Doctor, qué decidió la linearización, por qué viola encapsulamiento? · 5. ¿Cómo se reconoce un mixin en CLOS y qué pasa al instanciarlo solo? · 6. "Linearizar es aplicar": ¿qué se aplica a qué? · 7. `⋆` asociativo no conmutativo: ¿qué habilita cada propiedad? · 8. ¿Cómo expresa el modelo (a) clase común, (b) Smalltalk, (c) Beta, (d) CLOS? · 9. ¿Qué aporta `super display() := No_Op` y qué concepto encarna `No_Op`?

---

# PARTE 3 — Donde los mixins revientan

## 3.1 🔴🎯 Los dos sombreros de una clase

2003, Schärli/Ducasse/Nierstrasz/Black. Dato: tras ~20 años, ni herencia múltiple ni mixins se adoptaron masivamente; Java y C# las dejaron afuera. *"Multiple inheritance is good, but there is no good way to do it"* (Cook resumiendo a Snyder, OOPSLA '87). Diagnóstico raíz:

```
Rol 1: GENERADORA DE INSTANCIAS      Rol 2: UNIDAD DE REUSO
  completa · lugar fijo único          chica · aplicable en cualquier lado
```

**Las dos cosas a la vez no se puede** — todos los dolores son ese conflicto apretando. Base: la herencia simple no factoriza rasgos entre ramas → duplicación. 🟡 Interfaces de Java: resuelven tipado/modelado, **cero líneas de implementación reusadas**.

> 📌 **Para el parcial, si te preguntan** — *¿Por qué una clase es una mala unidad de reuso?*
> Porque sus dos roles exigen propiedades opuestas. Como generadora de instancias debe ser completa (sus objetos tienen que funcionar) y ocupar un lugar único en la jerarquía; como unidad de reuso debería ser pequeña (para reusar exactamente lo necesario) y aplicable en lugares arbitrarios. La herencia múltiple y los mixins reutilizan clases o especificaciones de subclase, y heredan ese conflicto: piezas demasiado grandes, atadas a una jerarquía, que chocan entre sí al combinarse.

## 3.2 🔴🎯 Herencia múltiple: tres dolores

**a) Features en conflicto.** El diamante está *garantizado*: toda clase trae de `Object` los universales (`=`, `hash`, `asString`) → reusar dos clases ya choca. Y la asimetría clave: **métodos** en conflicto = manejable (se pisa, se elige); **estado** en conflicto = sin salida limpia (¿una `x` o dos? cualquier respuesta rompe a alguien).

**b) Acceder a lo pisado.** Con homónimos de varias bases, `super` es ambiguo. C++/Eiffel: nombrar la clase en el código (`A::read`) → nombres cableados, frágil ante reorganización. CLOS: linearización → precio conocido. Sin salida elegante.

**c) El wrapper genérico imposible** (caso estrella). `A` tiene `read`/`write` sin sincronizar (sincronizar = proteger con **lock**/candado: tomar antes, soltar después). Intento (a), funciona:

```smalltalk
class SyncA
    superclass: A
    method: read
        | value |
        self acquireLock.          "1º tomo el candado"
        value := super read.       "2º leo con el read ORIGINAL de A"
        self releaseLock.          "3º suelto"
        ↑ value                    "4º devuelvo"
```

Aparece `B` con sus `read`/`write` → quiero factorizar el candado en superclase común `SyncReadWrite` (intento (b)) → **NO FUNCIONA: `super` se resuelve estáticamente** — queda fijado por la clase donde el método está *escrito*; el `super read` de SyncReadWrite busca en `Object`, jamás puede significar "A para SyncA, B para SyncB". Intento (c): reemplazar `super` por `self`-sends de abstractos (`syncRead` usa `self directRead`; cada hija define `directRead ↑ super read`, `directWrite ↑ super write`, `read ↑ self syncRead`, `write ↑ self syncWrite`) → funciona, pagando: **cuatro métodos duplicados por hija** (boilerplate), danza de nombres torpe, y cuidar que los crudos no queden públicos (esquivan el candado).

> 📌 **Para el parcial, si te preguntan** — *¿Por qué la herencia múltiple no permite factorizar un wrapper genérico?*
> Porque `super` se resuelve estáticamente: queda ligado a la superclase de la clase donde el método está definido, no a la jerarquía de quien lo reusa. Un wrapper factorizado en una superclase común (`SyncReadWrite`) no puede hacer que su `super read` signifique "A" para un cliente y "B" para otro. El paliativo — reemplazar `super` por `self`-sends de métodos abstractos — funciona pero obliga a duplicar los métodos de conexión en cada subclase, a malabarear nombres entre la versión cruda y la envuelta, y a cuidar que la versión cruda no quede expuesta.

## 3.3 🔴🎯 Mixins: tres dolores nuevos

Un mixin ortogonal anda; componer **muchos** no: chocan, y el operador de composición es el de herencia — lineal, de a uno, el de atrás pisa todo en bloque.

**a) Orden total obligatorio.** El posterior pisa TODOS los homónimos anteriores. Si la resolución pide elegir features de mixins distintos, **puede no existir orden**:

```
MixinA: saludar(A), despedir(A)  ·  MixinB: saludar(B), despedir(B)
Quiero saludar de A + despedir de B → …⋆A último: todo A ✗ · …⋆B último: todo B ✗
```

**b) Glue code disperso.** `MyRectangle` usa `MColor` y `MBorder`; cada `asString` extiende al heredado (`↑ super asString, ' ', self color asString`). La cadena fabrica **intermedias** (`Rectangle+MColor`, `+MBorder`) → resultado `"rect(2,3) rojo 5"` ✓. Pero cambiar el separador: **MyRectangle no puede** — solo accede a MBorder y a lo *ya mezclado*; los originales de MColor y Rectangle quedaron inalcanzables dentro de las intermedias. El **glue** (pegamento entre piezas) no vive en el compositor: hay que **modificar los mixins** para ajustar UNA composición. Principio violado: *el que compone debería controlar la composición*.

**c) Jerarquías frágiles.** Hoy: MBorder sin `asString` → vale el de MColor ✓. Mañana: alguien le agrega `asString` a MBorder → **pisa en silencio** al de MColor en todas las cadenas donde va después — sin warning; y volver atrás puede exigir tocar varios mixins más. Cuanto más reusado el mixin, mayor el radio.

> 📌 **Para el parcial, si te preguntan** — *¿Cuáles son los tres problemas de componer con mixins?*
> (1) **Orden total:** la composición es lineal y el mixin posterior pisa todos los features homónimos anteriores; si la resolución del conflicto exige elegir features de mixins distintos, puede no existir ningún orden que la produzca. (2) **Glue code disperso:** la lógica que conecta y adapta los mixins queda cableada en las clases intermedias generadas al aplicarlos de a uno; la entidad compuesta no controla cómo se pegan sus piezas y adaptar la composición exige modificar los mixins. (3) **Jerarquías frágiles:** agregar un método a un mixin puede pisar silenciosamente un homónimo de otro mixin anterior en la cadena, y restablecer el comportamiento original puede requerir cambiar varios mixins. Raíz común: usar el operador de herencia — lineal y de precedencia en bloque — como operador de composición.

## 3.4 🔴🎯 El mapa y el pliego

| Mecanismo | Compra | Duele |
|---|---|---|
| Herencia simple | simplicidad, `super` claro | duplicación entre ramas |
| + interfaces | tipado, modelado | el código se duplica igual |
| Herencia múltiple | reusar clases enteras | diamante garantizado · estado ambiguo · `super` roto · wrappers imposibles |
| Mixins | extensión con vida propia | orden total · glue disperso · fragilidad silenciosa |

Raíz única de los dolores de mixins: **heredaron el operador equivocado** (el de herencia, para componer). Pliego de la herramienta que falta: unidad **más chica que una clase**, sin jerarquía · composición **sin orden** · conflictos **explícitos, a la cara** · glue **en el compositor** · **estado afuera** · cambios que **no rompan en silencio**. Eso, punto por punto, es el trait.

## ✅ Checkpoint P3

1. Los dos roles de una clase y qué exige cada uno · 2. ¿Por qué las interfaces no resuelven el reuso? · 3. ¿Por qué el diamante está *garantizado*? · 4. ¿Por qué el estado en conflicto es peor que los métodos? · 5. "Super-sends se resuelven estáticamente": qué significa y por qué mata (b) · 6. Las tres facturas del intento (c) · 7. Ejemplo donde ningún orden total sirve · 8. ¿Por qué cambiar el separador exige modificar los mixins? · 9. ¿Por qué la fragilidad es *silenciosa* y empeora con el reuso? · 10. La raíz común de los tres dolores.

---

# PARTE 4 — Traits: componer sin heredar

## 4.1 🔴🎯 La unidad nueva

Caso: objetos gráficos con dos aspectos separables — geometría y dibujo. **Trait** = grupo de métodos con dos listas: **provee** (lo que implementa) y **requiere** (lo que usa sin definir — los parámetros; quien lo use los consigue). Regla de oro: **un trait no define estado, jamás, ni accede a variables directamente** — si necesita estado lo pide como requeridos (típicamente accessors). Convención: nombres `T…`; notación gráfica: columna izquierda provee, derecha (itálica) requiere.

```
TDrawing  provee: draw, refresh, refreshOn:   requiere: bounds, drawOn:
TCircle   provee: area, bounds, =, hash, <…   requiere: center(:), radius(:)
```

Un trait **no vive en la jerarquía**: se aplica donde haga falta.

## 4.2 🔴🎯 Armar una clase

```
Clase  =  Superclase  +  Estado  +  Traits  +  Glue
```

**Glue methods** = los que conectan los traits, satisfacen requirements (accessors del estado) y resuelven conflictos. Clase **completa** = todo requirement satisfecho (por la clase, su superclase u otro trait).

```smalltalk
Object subclass: #Circle
    instanceVariableNames: 'center radius'    "el ESTADO vive en la clase"
    uses: { TCircle . TDrawing }              "los TRAITS"

initialize          center := 0@0. radius := 50      "0@0 = punto (0,0)"
center              ↑ center                          "glue: accessors que"
center: aPoint      center := aPoint                  "satisfacen a TCircle"
radius              ↑ radius
radius: aNumber     radius := aNumber
drawOn: aCanvas     aCanvas fillOval: self bounds color: Color black
    "bounds, que TDrawing requería, NO se escribe: lo provee TCircle
     — un trait le satisface el requirement al otro"
```

Precedencias fijas: **clase pisa trait · trait pisa superclase** · entre traits nadie pisa a nadie (→ 4.5).

> 📌 **Para el parcial, si te preguntan** — *¿Qué es un trait y cómo se construye una clase con traits?*
> Un trait es un grupo de métodos que provee comportamiento y declara métodos requeridos que lo parametrizan; no define estado ni accede a variables directamente, y no ocupa un lugar en la jerarquía de herencia. Una clase se construye según `Clase = Superclase + Estado + Traits + Glue`: hereda de una superclase (herencia simple intacta), define las variables, incorpora traits y escribe los glue methods que satisfacen los requirements (típicamente accessors) y resuelven conflictos. La clase es completa cuando todos los requirements quedan satisfechos por la clase, su superclase u otro trait.

## 4.3 🔴🎯 Flattening property

**La semántica de una clase con traits = exactamente la de la misma clase con los métodos no-pisados escritos en su cuerpo.** Consecuencias: `super` en un trait no tiene semántica especial (busca desde la superclase de la clase usuaria — clave en 4.6) · componer estructura, no cambia significados (vs mixins, donde la posición lo era todo) · **dos vistas coexisten**: composición (para reusar) y aplanada (para entender) — el dilema reuso-vs-comprensibilidad era falso.

## 4.4 🔴🎯 Traits de traits

Mismas reglas un nivel arriba: `TCircle uses: {TMagnitude. TGeometry}`; `TMagnitude` usa `TEquality` (requiere `=`,`hash`; provee `~=`). Lo **provisto sube** al compuesto; lo **requerido no satisfecho también sube** (`center`… los pagará Circle); el compuesto pisa a sus subtraits; orden irrelevante; flattening vale a cualquier profundidad. Glue de `TCircle`: `= other ↑ self radius = other radius and: [self center = other center]` · `hash ↑ self radius hash bitXor: self center hash` (`bitXor:` funde hashes) · `< other ↑ self radius < other radius`.

## 4.5 🔴🎯 Conflictos: que exploten a la cara

**Conflicto ⟺ dos traits proveen métodos homónimos que NO se originan en el mismo trait.** La segunda mitad = **same-operation exception**: el mismo método llegando por varios caminos NO conflictúa → **el diamante se disuelve** (sin estado, llegar 1 o 5 veces da igual). El conflicto real **no se resuelve solo**: la composición instala un método *marcador*; el compositor debe resolverlo a su nivel. Premio: composición **asociativa Y conmutativa** (`⋆` era solo asociativa).

Caso: `TColor` (usa TEquality; `= ↑ self rgb = other rgb`, `hash ↑ self rgb hash`) + `TCircle` → conflicto en `=` y `hash` (orígenes distintos); `~=` no (ambos de TEquality). Dos salidas:

```smalltalk
"a) Override + alias (@ = nombre ADICIONAL, el original sigue vivo)"
Object subclass: #Circle
    instanceVariableNames: 'center radius rgb'
    uses: { TCircle  @ { #circleHash -> #hash.  #circleEqual: -> #= } .
            TDrawing .
            TColor   @ { #colorHash  -> #hash.  #colorEqual:  -> #= } }
hash        ↑ self circleHash bitXor: self colorHash
= anObject  ↑ (self circleEqual: anObject) and: [self colorEqual: anObject]
    "igualdad = geometría Y color; la clase pisa el conflicto,
     los aliases dan acceso a los originales para combinarlos"

"b) Exclusión (−): evitar el conflicto antes de que exista"
    uses: { TCircle . TDrawing . TColor − { #= . #hash } }
    "TColor entra sin sus = y hash → valen los de TCircle, cero glue
     (decisión de dominio: el color no cuenta para la igualdad)"
```

La resolución **vive en el compositor, a la vista, y expresa una decisión de dominio** — no un accidente del orden. **Alias ≠ renaming** (Eiffel): el alias agrega nombre sin matar el original ni tocar referencias; y como no modifica el cuerpo, **el alias de un método recursivo no es recursivo**.

> 📌 **Para el parcial, si te preguntan** — *¿Cuándo hay conflicto entre traits y cómo se resuelve?*
> Hay conflicto si y solo si dos traits compuestos proveen métodos homónimos que no se originan en el mismo trait; si el mismo método llega varias veces por caminos distintos no hay conflicto (same-operation exception), lo que disuelve el diamante porque los traits no tienen estado. El conflicto no se resuelve por precedencia ni orden: la composición lo marca explícitamente y debe resolverlo el compositor, ya sea definiendo un método propio que pisa el conflicto (usando aliases `@` para acceder a las versiones originales y combinarlas) o excluyendo (`−`) el método de todos los traits menos uno. Por eso la composición es asociativa y conmutativa.

## 4.6 🔴🎯 El pliego, respondido

**El wrapper, resuelto con la solución "imposible":** si `SyncReadWrite` es un **trait**, su `super` es placeholder de la superclase de la clase usuaria → `SyncA` = subclase de A + usa `TSyncReadWrite` (el `super read` aplanado busca en A) · `SyncB` ídem con B. **Una copia del candado, cero duplicados, cero danza de nombres.** El diseño era correcto; faltaba la unidad. Resto: estado → eliminado por prohibición (y menos conflictos: piezas chicas) · orden → simétrico; si querés precedencia la recupera la herencia (`C'` usa T1, `C` hereda de `C'` y usa T2 → T2 pisa por "trait pisa superclase": orden *parcial* a la carta) · glue → siempre en el compositor · acceso a lo pisado → aliases, sin nombres cableados · fragilidad → los conflictos nuevos **suenan en el momento exacto**, resolución local del cliente directo, sin dominó si preserva interfaz.

## 4.7 🟡📘 Decisiones finas

**Alias y no referencias con nombre de trait** (`TColor.hash` estilo C++): contradiría flattening + cablearía la estructura en los cuerpos + exigiría extender la sintaxis. **Límite honesto:** conflictos *no intencionales* (mismo nombre, semánticas distintas) — los traits no lo resuelven; hace falta namespaces + refactoring tools. **El diamante de traits defendido:** X usa Y1,Y2 que usan Z → `foo` llega dos veces, sin conflicto; si Y2 *copia* `foo`, nace un conflicto en X — local, X lo resuelve. Alternativas peores: elegir automático (linearización: cero aviso) o conflicto siempre (Snyder: elección arbitraria de entrada y cambios posteriores sin señal). La regla adoptada avisa exactamente cuando nace.

## 4.8 🟢📘 La evidencia

Implementación (Squeak): trait = clase despojada; métodos entran al diccionario de la clase; alias = segunda entrada; **bytecode compartido** salvo métodos con `super` (se copian); **performance indistinguible**, sin tocar la VM. Herramientas: browser con dos vistas + lista de pendientes (conflictos/requirements). Refactor de colecciones Smalltalk-80: interfaz separada de implementación, combinables; herencia para orden parcial; subtraits finos reusables ("emptiness": requiere `size`, provee `isEmpty`…; "enumeration": requiere `do:`, provee `collect:`, `select:`…). Números: 48 traits, 567 métodos, **−10% métodos, −12% código**, clases de hasta 22 traits legibles gracias al aplanado. Guiño: *Jigsaw* (tesis de **Bracha**, 1992) definió operadores casi idénticos, independientemente — convergencia como señal.

## 4.9 🟢📘 La siembra

Todo el pliego pagado por UNA decisión: prohibir el estado. ¿Su precio? Todos los traits útiles piden accessors… y alguien los escribe. Muchas veces.

## ✅ Checkpoint P4

1. Las dos listas de un trait · 2. ¿Por qué sin estado? Conectar con P3 · 3. La ecuación de 4 términos y qué es glue · 4. Flattening + dos consecuencias · 5. ¿Quién satisface `bounds` y qué regla ilustra? · 6. Definición exacta de conflicto; por qué same-operation es segura sin estado · 7. Alias vs renaming; por qué el alias de un recursivo no es recursivo · 8. Las dos resoluciones de `=`/`hash` y qué decisión de dominio expresa cada una · 9. ¿Por qué la solución (b) del wrapper funciona con un trait? · 10. ¿Cómo se recupera precedencia entre traits? · 11. Asociativa Y conmutativa vs solo asociativa: qué cambió.

---

# PARTE 5 — El precio de no tener estado: stateful traits

## 5.1 🟡📘 SyncStream (el wrapper, tercera vez)

2006, el mismo grupo. `SyncStream` = `TSyncReadWrite` (provee syncRead/syncWrite/hash; requiere `read`, `write`, `lock`, `lock:`) + `TStream` (read/write/hash), conflicto de `hash` resuelto con doble alias + `hash ↑ self hashFromSync bitAnd: self hashFromStream`. La clase pone la variable `lock` y sus accessors.

```smalltalk
syncRead
    | value |
    self lock acquire.       "el candado VÍA ACCESSOR (self lock)"
    value := self read.
    self lock release.
    ↑ value
```

La espina: `read`/`write` son requirements **conceptuales** (hooks reales); `lock`/`lock:` son **ruido** — el trait no quiere pedirlos, quiere *tener* el candado; los pide porque el modelo se lo prohíbe.

## 5.2 🔴🎯 Las cuatro cuentas de la prohibición

1. **Reusabilidad limitada:** casi ningún trait es completo ni off-the-shelf (usable tal cual); la interfaz requerida se llena de accessors triviales que tapan los hooks.
2. **Boilerplate y cáscaras:** cada cliente duplica variable + getter + setter idénticos (`SyncFile`/`SyncStream`/`SyncSocket`, el mismo `lock` tres veces) — *el pecado que los traits venían a erradicar*. **Shell classes**: 7 de 29 (24%) de las colecciones refactorizadas son puro embalaje (declaran variables + accessors, nada más).
3. **Propagación:** el trait evoluciona (variable interna nueva, p.ej. `numberWaiting`) → accessors requeridos nuevos → **todos los clientes tocados** aunque la interfaz pública no cambió. La fragilidad, de vuelta.
4. **Encapsulamiento violado dos veces:** la representación interna expuesta como requirements; y accessors públicos (en Smalltalk, todo método lo es) → cualquiera manosea el candado desde afuera.

> 📌 **Para el parcial, si te preguntan** — *¿Cuáles son las limitaciones de los traits sin estado?*
> Cuatro, todas derivadas de codificar el estado como accessors requeridos: (1) reusabilidad limitada — casi ningún trait es completo ni componible tal cual, y la interfaz requerida se llena de accessors triviales que tapan los hooks conceptuales; (2) boilerplate — cada clase cliente debe duplicar variables, accessors e inicialización, generando clases-cáscara de puro glue (24% de la jerarquía de colecciones); (3) propagación — agregar estado interno a un trait propaga nuevos required accessors a todos sus clientes aunque la interfaz pública no cambie, reintroduciendo fragilidad; (4) encapsulamiento violado — la representación interna queda expuesta como requirements, y los accessors públicos permiten manipular desde afuera estado que debía ser privado.

## 5.3 🔴🎯 Stateful traits: la extensión mínima

Tres movimientos (stateless queda como caso particular; el cliente sigue controlando la composición):

1. El trait puede declarar variables — **privadas a su scope por defecto** (nadie las ve).
2. El **cliente** puede darse acceso con **`@@`**, bajo nombre nuevo local a él.
3. El cliente puede **mergear** variables de traits distintos a un nombre común.

Consecuencia del movimiento 1: **los conflictos de variables no pueden nacer** (T1 con `x` + T2 con `x` → cada una la suya).

```smalltalk
Trait named: #TSyncReadWrite
    uses: {}
    instVarNames: 'lock'          "el trait DECLARA su variable"

initialize    super initialize. lock := Lock new    "e inicializa SU candado"
syncRead
    | value |
    lock acquire.                 "la variable DIRECTA: es mía, no la pido"
    value := self read.
    lock release.
    ↑ value
"Requirements: ANTES read·write·lock·lock: → AHORA read·write (solo hooks)"

Object subclass: #SyncStream
    uses: TSyncReadWrite @  { #hashFromSync -> #hash }
                         @@ { syncLock -> lock }       "acceso a la variable"
        + TStream @ { #hashFromStream -> #hash }
    instVarNames: ''              "la clase: CERO variables, cero accessors"
isBusy    ↑ syncLock isAcquired   "para esto era el @@: mirar el candado"
hash      ↑ self hashFromSync bitAnd: self hashFromStream
```

Simetría deliberada: **`@` es a métodos lo que `@@` es a variables** — nombre adicional, visible solo en el cliente; adentro del trait sigue siendo `lock`. Tres escenarios:

```
(i)  SIN @@ (default)      T1 x · T2 x · C x = TRES celdas · black-box · cero conflicto
(ii) ACCESO                C: T1@@{xFromT1->x} + T2@@{xFromT2->x}
                           sum ↑ xFromT1 + xFromT2   → setXT1:1, setXT2:2, sum→3
(iii) MERGE                C: T1@@{w->x} + T2@@{w->y}  → x de T1 e y de T2 = LA
                           MISMA celda: setW:3 → getX=getY=getW=3
```

El merge es la mitad buena del diamante: "¿una `x` o dos?" **lo decide el compositor, caso por caso**. Garantías: la visibilidad jamás se propaga sola (sin captura accidental); cliente que declara variable homónima a su `@@` = error directo, imposible como efecto de un cambio remoto. Balance: interfaces limpias · cáscaras vacías · agregar estado = invisible para clientes · sin accessors públicos forzados.

> 📌 **Para el parcial, si te preguntan** — *¿Qué agregan los stateful traits y cómo evitan los conflictos de variables?*
> Permiten que un trait declare variables de instancia privadas a su propio scope. Como son privadas por defecto, componer traits con variables homónimas no genera conflicto alguno: cada una vive aislada. El cliente — fiel al principio de que quien compone controla la composición — puede ampliar selectivamente la visibilidad con el operador `@@`, que da acceso a una variable bajo un nombre nuevo local al cliente (análogo al alias `@` de métodos), y puede mergear variables de traits distintos mapeándolas a un nombre común, unificándolas en una sola celda. Agregar estado a un trait no afecta a ningún cliente; quitar o renombrar variables afecta solo a los clientes directos que se dieron acceso explícito.

## 5.4 🟡📘 Adentro de la máquina

El acceso por **offset** (posición fija en memoria) muere: el mismo trait en clientes distintos → posiciones distintas (la `v` de T2 es la celda 0 sola, la 3 dentro de T4 → el `getV` compilado leería otra variable). Tres salidas: C++ (sub-objetos + virtual base pointers — pesado, no) · diccionario estilo Python (variables por nombre; merge = dos claves, un valor; fiel pero lento) · **copy-down** (Strongtalk): los métodos que tocan variables se copian y reajustan offsets por clase — elegido; **benchmarks: tiempos indistinguibles** de no usar traits.

## 5.5 🟡📘 El caso Heap

Stateless: `Heap` declara `array`, `tally`, `sortBlock` + seis accessors **y nada más** (cáscara del 24%) porque `THeapImpl` → `TArrayBased`/`TSortBlockBased` los requieren. Stateful: **cada variable migra al trait que la usa** (`TArrayBased` define `array`,`tally`; `TSortBlockBased` define `sortBlock`) → requirements de estado evaporados en cadena → `Heap` queda vacía; y si `THeapImpl` no tiene otros usuarios, se colapsa dentro de `Heap` y desaparece.

## 5.6 🟡📘 Detalles finos

**Flattening sobrevive:** al aplanar, las variables se mantienen privadas por *alpha-renaming* (renombrar sin cambiar semántica) / *name-mangling* (`lock` → `TSyncReadWrite_lock`). **Radio de cambios:** agregar variable → cero afectados; quitar/renombrar → solo clientes directos con `@@`, sin viaje río abajo. **¿`@@` viola encapsulamiento?** Defensa: default black-box total; apertura selectiva, explícita, del lado del cliente — por eso los cambios no llegan lejos. **Parientes:** Eiffel solo unifica variables de ancestro común (el merge de stateful une sin parentesco) · Jigsaw: estado sí, compartir no (black-box estricto) · el problema de tipos estructurales (composiciones distintas = mismo tipo, representaciones distintas) no aplica: **un trait no define un tipo**. ⚠️ El material afirma que los traits de **Scala** no pueden definir estado — cierto en 2007; los traits de Scala modernos **sí admiten variables** (lo vas a ver en la segunda mitad de la materia). Afirmación fechada.

## 5.7 🔴🎯 El arco completo

```
 1990                    2003                    2006/07
 herencia simple ─┐
 (Smalltalk↕Beta) ├─► MIXINS ──revientan──► TRAITS ──duelen──► STATEFUL
 herencia múltiple┘   (delta con  (orden,      (sin estado,    TRAITS
 (CLOS, diamante,      vida       glue,         explícitos,    (privado
  linearización)       propia)    fragilidad)   flattening)    + @@)
```

| Herramienta | Ataca | Jugada | Precio |
|---|---|---|---|
| Herencia simple | definir por diferencia | delta + un padre | no factoriza entre ramas |
| Herencia múltiple | reusar de varios padres | varios padres | diamante, estado ambiguo, `super` roto |
| Linearización | el diamante | grafo → lista implícita | encapsulamiento, sorpresa a distancia |
| Mixins | delta sin vida propia | subclase abstracta componible | orden total, glue disperso, fragilidad |
| Traits | componer sin heredar | piezas sin estado, conflictos explícitos, glue del compositor, flattening | accessors: boilerplate, cáscaras, propagación |
| Stateful traits | el precio del no-estado | variables privadas + `@@` | pregunta abierta |

**Tesis del bloque:** ninguna herramienta es "la buena" — cada una nace de un problema concreto de la anterior, compra algo, y paga con la moneda que engendra a la siguiente. Preguntas que importan: *¿qué problema real la motivó?* y *¿qué cuesta salir?*. Abierta desde 2007: ¿puede la composición reemplazar del todo a la herencia?

## ✅ Checkpoint P5

1. En TSyncReadWrite stateless: requirements "señal" vs "ruido" · 2. Shell class: qué es, proporción, la ironía · 3. Variable interna nueva: ¿a quiénes afecta stateless vs stateful? · 4. Las dos violaciones de encapsulamiento · 5. ¿Por qué los conflictos de variables *no pueden existir*? · 6. `T @@ {y -> x}`: qué hace, scopes, análogo de métodos · 7. Los tres escenarios y quién decide · 8. ¿Por qué el offset se rompe, qué estrategia se eligió, qué dieron los benchmarks? · 9. Heap: qué migró, qué se evaporó, qué quedó vacío · 10. ¿Cómo sobrevive la flattening con variables?

### ✅ Checkpoint integrador del bloque

11. El arco 1990→2003→2007 en tus palabras: herramienta, problema, precio · 12. Las tres apariciones del wrapper: qué cambia y qué demuestra cada una · 13. El diamante a través del bloque: herencia múltiple, linearización, por qué traits lo disuelve en métodos, y qué devuelve al cliente para el estado · 14. "Los mixins son malos, por eso inventaron los traits" — armá la respuesta que esa afirmación se merece.

---

**FIN DEL APUNTE RESUMEN — `preclase02`**
