# 📘 APUNTE MAESTRO — preclase02 · Mixins & Traits — Parte 3

## Donde los mixins revientan

> **Unidad:** `preclase02` · Parte 3 de 5 · Lectura previa de la clase 2 ("Mixins: resolución de conflictos")

**Qué cubre esta parte:** el diagnóstico de fondo (la clase juega dos roles en competencia) · los tres dolores clásicos de la herencia múltiple, incluido el wrapper genérico imposible (SyncA/SyncB) · los tres dolores propios de los mixins: orden total, glue code disperso, jerarquías frágiles.

**Qué NO cubre (viene después):** la herramienta que responde a estos dolores → Parte 4 · el estado → Parte 5.

**De las partes anteriores se asume:** el diamante y la linearización con su precio (Parte 2 §2-3) · mixins y el operador de composición lineal (Parte 2 §4-5) · `super` resuelto por el hijo, la dualidad Smalltalk/Beta (Parte 1).

---

## 1. 🔴 Trece años después: el veredicto de la práctica

La propuesta de la Parte 2 es de 1990. Esta parte salta a 2003: un grupo de investigación de Berna y Oregón (Schärli, Ducasse, Nierstrasz y Black), con un sistema real entre manos, escribió el balance de esos años. Arranca con un dato incómodo: después de casi veinte años de herencia múltiple y mixins, **ninguno de los dos logró adopción masiva**. Los lenguajes nuevos de la época — Java, C# — directamente decidieron que las complejidades de la herencia múltiple superaban su utilidad, y la dejaron afuera. Una frase de la comunidad de entonces (Cook, resumiendo a Snyder en OOPSLA '87) lo condensa: *"Multiple inheritance is good, but there is no good way to do it"* — la herencia múltiple es buena, pero no hay una buena forma de hacerla.

¿Por qué? El diagnóstico de fondo del grupo es la pieza conceptual más importante de esta parte, y ordena todo lo que sigue:

> **Una clase juega dos roles en competencia.**
>
> ```
>   Rol 1: GENERADORA DE INSTANCIAS        Rol 2: UNIDAD DE REUSO
>   ─────────────────────────────          ─────────────────────────
>   debe ser COMPLETA                      debería ser CHICA
>   (sus objetos tienen que funcionar)     (para reusar justo lo que querés)
>
>   necesita UN lugar fijo                 debería aplicarse en
>   en la jerarquía                        lugares ARBITRARIOS
> ```

Completa y chica. Fija y aplicable en cualquier lado. **Las dos cosas a la vez, no se puede.** La herencia múltiple y los mixins intentan usar la clase (o casi-clase) como unidad de reuso, y todos los dolores que vienen a continuación son formas distintas de ese conflicto de roles apretando.

### El punto de partida: la herencia simple se queda corta

Que quede claro por qué se buscó algo más. Con **un solo padre por clase**, no hay forma de factorizar rasgos compartidos por clases que viven en ramas distintas de una jerarquía compleja: el rasgo común no tiene dónde vivir, y termina **copiado y pegado** en cada rama. Duplicación lisa y llana.

🟡 Nota sobre las **interfaces** de Java — 🕳️ una interfaz declara *qué* métodos debe tener una clase, sin dar el código. Resuelven el modelado conceptual y el tipado ("esto se comporta como X"), pero **no evitan duplicar ni una línea de implementación**: el problema de reuso queda intacto.

> 📌 **Para el parcial, si te preguntan** — *¿Por qué una clase es una mala unidad de reuso?*
> Porque sus dos roles exigen propiedades opuestas. Como generadora de instancias debe ser completa (sus objetos tienen que funcionar) y ocupar un lugar único en la jerarquía; como unidad de reuso debería ser pequeña (para reusar exactamente lo necesario) y aplicable en lugares arbitrarios. La herencia múltiple y los mixins reutilizan clases o especificaciones de subclase, y heredan ese conflicto: piezas demasiado grandes, atadas a una jerarquía, que chocan entre sí al combinarse.

---

## 2. 🔴 Herencia múltiple: los tres dolores clásicos

### 2.1 Features en conflicto — y por qué el estado es peor

El diamante ya lo conocés de la Parte 2. Lo nuevo acá son dos vueltas de tuerca:

**Primera:** el diamante no es un caso raro que puedas esquivar diseñando con cuidado — está **garantizado por el rol 1**. Como toda clase debe poder generar instancias que funcionen, toda clase provee (heredados de la raíz común `Object`) los métodos mínimos universales: comparar (`=`), calcular un código de identidad (`hash` — 🕳️ un número que resume al objeto, usado por las colecciones para ubicarlo rápido), describirse (`asString`). Reusá dos clases cualesquiera y esos features universales **ya están chocando**.

**Segunda:** los conflictos no son todos igual de graves.

```
CONFLICTO DE MÉTODOS                CONFLICTO DE ESTADO (variables)
────────────────────                ───────────────────────────────
dos definiciones de asString        dos caminos aportan la variable x
→ molesto pero manejable:           → ¿el objeto final tiene UNA x
  se pisa una, se elige,              compartida o DOS x separadas?
  se redefine                       → cualquier respuesta rompe a
                                      alguien. No hay salida limpia.
```

Los métodos se pisan y listo; el estado duplicado no tiene semántica buena. Subrayá esta asimetría: es una de las decisiones fundacionales de la herramienta de la Parte 4.

### 2.2 Acceder a lo pisado: cuando `super` deja de alcanzar

Con un padre, `super` es inequívoco. Con varios padres que traen métodos homónimos, "el de arriba" es ambiguo. Las soluciones históricas, cada una con su factura:

- **C++ / Eiffel:** nombrar la clase a mano en el código (`A::read()` — "el read de A"). Funciona… y ahora el **nombre de la clase quedó cableado dentro del método**. Reorganizás la jerarquía → salís a cazar referencias rotas por todo el código. Frágil ante cambios de arquitectura.
- **CLOS:** el orden lineal decide quién es "el siguiente" — es la linearización de la Parte 2, con su precio ya conocido: comportamiento sorpresivo y encapsulamiento violado.

Sin salida elegante: o ensuciás el código con nombres, o delegás en un algoritmo global que te sorprende.

### 2.3 El wrapper genérico imposible

Este es el ejemplo estrella de la parte — va a reaparecer resuelto en la Parte 4 y otra vez en la Parte 5, así que despacio y completo.

**El caso.** Un framework tiene una clase `A` con métodos `read` y `write` que acceden a datos **sin sincronizar** — 🕳️ sincronizar: proteger un recurso para que dos procesos concurrentes no lo pisen a la vez; se hace tomando un *lock* (candado) antes de operar y soltándolo después. Aparece la necesidad de una versión sincronizada. Primera versión, directa:

```smalltalk
"── Intento (a): la subclase que envuelve ───────────────────────"
"SyncA hereda de A y ENVUELVE read y write con el candado"

class SyncA
    superclass: A

    method: read
        | value |                  "variable temporal"
        self acquireLock.          "1º tomo el candado"
        value := super read.       "2º leo usando el read ORIGINAL de A"
        self releaseLock.          "3º suelto el candado"
        ↑ value                    "4º devuelvo lo leído"

    method: write
        | value |
        self acquireLock.          "misma envoltura…"
        value := super write.      "…alrededor del write original"
        self releaseLock.
        ↑ value
    "Resultado esperado: read/write de SyncA hacen lo mismo que los
     de A, pero protegidos por el candado. Funciona perfecto."
```

A eso se le dice **wrapper** — 🕳️ envoltorio: un método que agrega comportamiento (acá, el candado) alrededor de un método existente, al que invoca en el medio.

**El problema.** El framework también tiene una clase `B`, con sus propios `read`/`write`, y hace falta `SyncB`. El código del candado es *idéntico*. Todo tu instinto dice: **factorizalo**. Con herencia, factorizar = subir a una superclase común:

```
── Intento (b): subir el código a una superclase común ──────────

        ┌───┐      ┌───────────────┐      ┌───┐
        │ A │      │ SyncReadWrite │      │ B │
        │read│     │ read  (wrap)  │      │read│
        │write│    │ write (wrap)  │      │write│
        └───┘      │ acquireLock   │      └───┘
          ▲        │ releaseLock   │        ▲
          │        └───────────────┘        │
          │           ▲       ▲             │
          └───────────┤       ├─────────────┘
               ┌──────┴─┐   ┌─┴──────┐
               │ SyncA  │   │ SyncB  │      (herencia múltiple:
               └────────┘   └────────┘       cada Sync hereda de su
                                             clase Y del wrapper)

                        ✗ NO FUNCIONA
```

¿Por qué no? Por algo que ya viste actuar en la Parte 1: **`super` se resuelve estáticamente** — queda fijado por la clase donde el método está *escrito*, no por quién lo termina usando. El `super read` dentro de `SyncReadWrite` busca `read` en la superclase de `SyncReadWrite`… que es `Object`, y no tiene `read`. Ese `super` **jamás** puede significar "A cuando me usa SyncA, B cuando me usa SyncB". La herencia múltiple te deja heredar de ambos lados, pero el wrapper no tiene forma de nombrar a su "hermano de herencia".

**El parche.** ¿Y si en vez de `super` usamos `self` con métodos abstractos? `self` sí se resuelve dinámicamente (arranca en el objeto real — Parte 1):

```smalltalk
"── Intento (c): parametrizar con self-sends ────────────────────"
class SyncReadWrite
    "provee la maquinaria del candado:"
    method: syncRead
        | value |
        self acquireLock.
        value := self directRead.    "self, no super: se resuelve en el
                                      objeto real → lo define la subclase"
        self releaseLock.
        ↑ value
    method: syncWrite
        | value |
        self acquireLock.
        value := self directWrite.
        self releaseLock.
        ↑ value
    "directRead y directWrite quedan ABSTRACTOS: los debe definir cada hija"

class SyncA
    superclass: A y SyncReadWrite
    method: directRead    ↑ super read      "el read crudo de A"
    method: directWrite   ↑ super write
    method: read          ↑ self syncRead   "la cara pública usa la versión sync"
    method: write         ↑ self syncWrite

class SyncB
    superclass: B y SyncReadWrite
    method: directRead    ↑ super read      "── los MISMOS cuatro métodos ──"
    method: directWrite   ↑ super write     "── otra vez, letra por letra ──"
    method: read          ↑ self syncRead
    method: write         ↑ self syncWrite
```

Esto **funciona**… y mirá la factura:

- **Cuatro métodos duplicados** en cada subclase — el código que queríamos factorizar se factorizó, pero engendró boilerplate — 🕳️ código repetitivo y mecánico que hay que escribir igual en todos lados — nuevo en cada cliente. Cambiamos una duplicación por otra.
- La danza de nombres (`read` vs `directRead` vs `syncRead`) para que no choquen la versión cruda y la sincronizada es **torpe**, y encima hay que asegurarse de que `directRead`/`directWrite` **no queden públicos** — si alguien los llama desde afuera, esquivó el candado y volvimos al bug original.

> 📌 **Para el parcial, si te preguntan** — *¿Por qué la herencia múltiple no permite factorizar un wrapper genérico?*
> Porque `super` se resuelve estáticamente: queda ligado a la superclase de la clase donde el método está definido, no a la jerarquía de quien lo reusa. Un wrapper factorizado en una superclase común (`SyncReadWrite`) no puede hacer que su `super read` signifique "A" para un cliente y "B" para otro. El paliativo — reemplazar `super` por `self`-sends de métodos abstractos — funciona pero obliga a duplicar los métodos de conexión en cada subclase, a malabarear nombres entre la versión cruda y la envuelta, y a cuidar que la versión cruda no quede expuesta.

---

## 3. 🔴 Mixins bajo fuego: los tres dolores nuevos

Los mixins (Parte 2) atacan parte de lo anterior: la pieza de reuso ya no es una clase completa sino una extensión con vida propia. Y para extender **una** clase con **un** mixin ortogonal — 🕳️ ortogonal: que no se pisa con nada de lo que ya hay — funcionan muy bien. El problema aparece al componer una clase desde **muchos** mixins: los mixins *no encajan del todo entre sí* — sus features chocan — y el operador de composición **es el de herencia**: lineal, de a uno, el de atrás pisa todo. La herencia es buena para *derivar* clases; como operador para *componer piezas* es demasiado poco expresiva para resolver los choques. Ese desajuste se manifiesta de tres formas.

### 3.1 Orden total obligatorio

La composición de mixins es **lineal**: se aplican de a uno, en fila (la palabra que la Parte 2 te pidió anotar). Y el que llega después pisa **todos** los features homónimos de los anteriores — en bloque, sin selección fina. Consecuencia directa:

```
MixinA provee:   saludar (versión A) ,  despedir (versión A)
MixinB provee:   saludar (versión B) ,  despedir (versión B)

Lo que quiero:   saludar de A  +  despedir de B

… ⋆ MixinA después  →  gana TODO A   ✗ (perdí despedir de B)
… ⋆ MixinB después  →  gana TODO B   ✗ (perdí saludar de A)

No existe NINGÚN orden que me dé la combinación.
```

Cuando la resolución de un conflicto pide *elegir features de mixins distintos*, **un orden total adecuado puede directamente no existir**. El operador solo sabe decir "este pisa a aquel"; no sabe decir "de este quiero esto, de aquel, aquello".

### 3.2 Glue code disperso

**El caso.** Un `Rectangle` sabe describirse: `asString` devuelve algo como `rect(2,3)`. Dos mixins lo decoran: `MColor` (agrega color) y `MBorder` (agrega borde), y cada uno extiende la descripción — llama a la heredada y le concatena lo suyo:

```smalltalk
"en MColor:"
method: asString
    ↑ super asString, ' ', self color asString
    "lo heredado + espacio + el color"

"en MBorder:"
method: asString
    ↑ super asString, ' ', self borderSize asString
    "lo heredado + espacio + el grosor del borde"
```

La composición, como es lineal, fabrica **clases intermedias** — una por cada mixin aplicado:

```
        ┌───────────┐
        │ Rectangle │  asString → "rect(2,3)"
        └───────────┘
              ▲
              │  ◄╌╌╌ MColor se aplica acá
   ┌────────────────────┐
   │ Rectangle + MColor │  asString → "rect(2,3) rojo"
   └────────────────────┘
              ▲
              │  ◄╌╌╌ MBorder se aplica acá
┌──────────────────────────────┐
│ Rectangle + MColor + MBorder │  asString → "rect(2,3) rojo 5"
└──────────────────────────────┘
              ▲
              │
       ┌─────────────┐
       │ MyRectangle │   ← la clase que VOS escribís
       └─────────────┘
```

Resultado esperado: `"rect(2,3) rojo 5"`. Funciona. Ahora pedí un cambio mínimo: **el separador entre las partes debe ser `" | "` en vez de espacio**. ¿Dónde lo cambiás?

`MyRectangle` — la entidad que compone, la que debería estar al mando — **no puede**: desde su posición solo accede al comportamiento de `MBorder` y al *ya mezclado* de `Rectangle + MColor`. Los `asString` originales de `MColor` y de `Rectangle`, sueltos, quedaron **inalcanzables**: se fundieron dentro de las intermedias. El código que decide cómo se pegan las piezas — el **glue code**, 🕳️ el pegamento: la lógica de conexión y adaptación entre componentes — no vive en el compositor: quedó **cableado y regado por las clases intermedias que nadie escribió**. Para cambiar el separador hay que ir a **modificar los mixins** (o meter mixins nuevos, o aplicar el mismo dos veces): tocás piezas compartidas por todo el sistema para ajustar UNA composición.

> El principio violado, dicho en limpio: **el que compone debería controlar la composición.** Con mixins, la controlan las intermedias.

### 3.3 Jerarquías frágiles

El más traicionero, porque rompe **en silencio**. Escenario en dos fotos:

```
FOTO 1 — hoy                          FOTO 2 — seis meses después
────────────────                      ───────────────────────────
MBorder NO define asString.           Alguien "mejora" MBorder:
MyRectangle usa el asString           le agrega asString.
que viene de MColor.
                                      Por el orden total, el nuevo
Todo anda. ✓                          asString de MBorder PISA al
                                      de MColor…

                                      …en TODAS las composiciones
                                      del sistema donde MBorder va
                                      después de MColor.

                                      Sin warning. Sin error.
                                      El comportamiento cambió solo. ✗
```

Agregar un método a un mixin — un cambio que se ve *local e inocente* — puede pisar silenciosamente métodos homónimos de mixins anteriores en cadenas que su autor ni conoce. Y la vuelta atrás es peor: restablecer el comportamiento original del compuesto puede ser **imposible sin agregar o modificar varios mixins más** de la cadena. Cuanto más reusado el mixin — es decir, cuanto mejor cumplió su propósito — más grande el radio de la explosión.

> 📌 **Para el parcial, si te preguntan** — *¿Cuáles son los tres problemas de componer con mixins?*
> (1) **Orden total:** la composición es lineal y el mixin posterior pisa todos los features homónimos anteriores; si la resolución del conflicto exige elegir features de mixins distintos, puede no existir ningún orden que la produzca. (2) **Glue code disperso:** la lógica que conecta y adapta los mixins queda cableada en las clases intermedias generadas al aplicarlos de a uno; la entidad compuesta no controla cómo se pegan sus piezas y adaptar la composición exige modificar los mixins. (3) **Jerarquías frágiles:** agregar un método a un mixin puede pisar silenciosamente un homónimo de otro mixin anterior en la cadena, y restablecer el comportamiento original puede requerir cambiar varios mixins. Raíz común: usar el operador de herencia — lineal y de precedencia en bloque — como operador de composición.

---

## 4. 🔴 El mapa de los dolores

La síntesis de la parte, en una tabla:

| Mecanismo | Qué compra | Dónde duele |
|---|---|---|
| **Herencia simple** | simplicidad, un `super` inequívoco | no factoriza rasgos entre ramas → duplicación |
| **+ interfaces (Java)** | tipado y modelado conceptual | el código se sigue duplicando igual |
| **Herencia múltiple** | reusar varias clases enteras | diamante garantizado por la raíz común · estado en conflicto sin semántica buena · `super` ambiguo (nombres cableados o linearización) · wrappers genéricos imposibles |
| **Mixins** | la extensión como pieza con vida propia | orden total que puede no existir · glue disperso en intermedias · fragilidad silenciosa |

Y la destilación final. Los tres dolores de los mixins tienen **una sola raíz**: heredaron el operador equivocado. Componen con el operador de herencia — lineal, de a uno, precedencia en bloque para el último — que es excelente para *derivar una clase de otra* y demasiado pobre para *componer piezas que chocan*. Sobre esa raíz, el diagnóstico de la sección 1 sigue abierto: la unidad de reuso sigue siendo una (casi) clase, completa de más, atada de más.

Leé los dolores al revés y tenés el **pliego de condiciones** de la herramienta que falta:

- que la unidad de reuso sea **más chica que una clase** y no viva atada a una jerarquía;
- que la composición **no tenga orden** — y entonces los conflictos no se resuelvan solos por precedencia: que **exploten a la cara, explícitos**, y los resuelva…
- …**el que compone**, con el glue **en sus manos**, no regado en intermedias;
- que el **estado** — el conflicto sin salida limpia — quede directamente **afuera** de la unidad de reuso;
- y que cambiar una pieza **no rompa en silencio** a clientes desconocidos.

Ese pliego, punto por punto, es la herramienta de la **Parte 4**. Se llama *trait*.

---

## ✅ Checkpoint — Parte 3

*(Sin respuestas — se validan en el chat; las respuestas modelo van al complemento.)*

1. ¿Cuáles son los dos roles en competencia de una clase, y qué propiedad opuesta exige cada uno?
2. ¿Por qué las interfaces de Java no resuelven el problema de reuso que la herencia simple deja abierto?
3. ¿Por qué el diamante está *garantizado* en herencia múltiple, aunque el diseñador no cree rombos a propósito?
4. ¿Por qué un conflicto de estado es más grave que un conflicto de métodos?
5. En el intento (b) de SyncReadWrite, ¿qué significa exactamente que "los super-sends se resuelven estáticamente" y por qué eso mata la factorización?
6. El intento (c) funciona. Enumerá las tres facturas que paga.
7. Construí (o reconstruí) un ejemplo donde ningún orden total de dos mixins produce la combinación de features deseada.
8. En el caso MyRectangle: ¿por qué cambiar el separador de `asString` exige modificar los mixins, si MyRectangle es quien compone?
9. ¿Por qué la fragilidad de las jerarquías de mixins es *silenciosa*, y por qué empeora cuanto más reusado es el mixin?
10. ¿Cuál es la raíz común de los tres dolores de los mixins?

---

**FIN DE LA PARTE 3** — *sigue en la Parte 4: traits.*
