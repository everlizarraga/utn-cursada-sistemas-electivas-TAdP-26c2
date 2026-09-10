# 🎯 APUNTE CORE — clase02 · Mixins: resolución de conflictos
## Parte 2 — Conflictos y linearización

*Al terminar esta parte vas a poder mirar una clase con varios `include` y decir qué método se ejecuta y por qué, dibujar su cadena, y saber qué hace `super` adentro de un módulo.*

---

## 1. Qué es un conflicto

### El caso que ya conocés

Esto lo viste mil veces y nunca lo llamaste conflicto:

```ruby
class Superclase
  def m
    "m de la superclase"
  end
end

class Clase < Superclase
  def m
    "m de la clase"
  end
end

# ¿CÓMO FUNCIONA?
Clase.new.m
# Resultado esperado: "m de la clase"
```

La respuesta te sale sola: gana el de `Clase`, porque está más cerca. Pero frená antes de responder. Cuando una instancia de `Clase` recibe `m`, **tiene dos métodos disponibles** para atenderlo. Los dos son alcanzables. Eso, y solo eso, es un **conflicto**: una ambigüedad. Un programa no puede ser ambiguo; alguien tiene que decidir.

### El conflicto no es la herramienta que lo resuelve

Lo que aprendiste fue la **solución**, no el problema. Se llama sobreescritura, y es una decisión que el lenguaje tomó por vos: *"gana el de abajo y la búsqueda se corta ahí"*. Es arbitraria —nada en la naturaleza dice que gana el de abajo— pero resultó práctica y todos los lenguajes la copiaron.

> **Quedate con esto:** el conflicto es la ambigüedad. La sobreescritura es *una* forma automática de resolverla. La herencia simple te ocultó el conflicto porque te dio la resolución junto con el problema.

---

## 2. Por qué con mixins hace falta un orden

En herencia simple los conflictos son fáciles porque **la jerarquía es una línea**: desde cualquier clase hasta `Object` hay un único camino, y "el más cercano gana" tiene sentido porque hay una sola distancia.

Con mixins, eso se rompe:

```ruby
module M
  def m; "m de M"; end
end

module N
  def m; "m de N"; end
end

class C
  include M
  include N
end

C.new.m     # ¿cuál?
```

`M` y `N` están **al mismo nivel**: ninguno está "más cerca" de `C` que el otro. Los dos son razonables. *"Corresponde el de `M`, que se incluyó primero"* es tan válido como *"corresponde el de `N`: `C` dijo que era `N` después de decir que era `M`, y eso también es una voluntad"*. No se puede satisfacer a los dos. Hay que elegir, y **la elección es arbitraria pero tiene que ser consistente** —siempre la misma regla, documentada, para todos los casos.

Hay dos cosas que casi nadie discute, y que acotan el problema:

- **Lo local va primero.** Si la propia clase define `m`, se usa ese. Es tu última palabra.
- **La herencia va última.** Los mixins se montan *encima* de la herencia, así que se consultan antes que la superclase.

Lo único que queda por decidir es el orden **entre los mixins**. Y para eso hay una regla.

---

## 3. Linearización: la regla

**Linearizar es tomar todas las entidades de las que una clase saca métodos —ella misma, sus módulos, su superclase— y ponerlas en una línea.** Un orden de búsqueda, igual al que tenías con la herencia sola. Es el paso que los mixins agregan, y es lo que hace que los conflictos se resuelvan **automáticamente**: no desaparecen; hay una regla que siempre elige.

### La regla de Ruby

Tomá el caso general. `C` incluye dos módulos, `M1` y `M2`. Los dos incluyen a su vez un módulo común, `M0`. Y `C` hereda de `S`.

```
        ┌────┐      ┌────┐
        │ M1 │      │ M2 │
        └────┘      └────┘
           ▲▲  ╲    ▲▲  ╲
           ││   ╲   ││   ╲        ┌────┐
           ││    ╲──┼┼────╲──────►│ M0 │   (M1 y M2 incluyen M0)
           ││       ││            └────┘
        ┌──┴┴───────┴┴──┐
        │       C       │        C incluye M2 y después M1
        └───────┬───────┘
                │
                ▼
             ┌─────┐
             │  S  │
             └─────┘
```

Tres pasos, y cada entidad los aplica **localmente**:

1. **Primero yo.** `C` se pone a sí misma.
2. **Después mis módulos, del último incluido al primero.** Y cada uno viene con **su propia línea completa**: `M1` aporta `M1, M0`; `M2` aporta `M2, M0`. Es recursivo.
3. **Después mi superclase**, que hace el mismo ejercicio con sus módulos y su superclase.

Resultado, antes de limpiar:

```
   C → M1 → M0 → M2 → M0 → S → Object → ...
```

Si tapás el tramo del medio —que es lo mismo que "si no usás módulos"— queda `C → S → Object`: la herencia de siempre.

### El módulo repetido: se preserva el último

`M0` aparece dos veces. Hay que limpiarlo, y hay dos formas: quedarse con la primera aparición o con la última.

```
   Preservar el primero → C → M1 → M0 → M2 → S
   Preservar el último  → C → M1 → M2 → M0 → S
```

**Ruby preserva el último.** Se tacha la primera aparición y sobrevive la del final. Anotalo: en la Parte 3 vas a ver que esta decisión es la que habilita el patrón más útil de toda la unidad.

```ruby
module M0; end
module M1; include M0; end
module M2; include M0; end
class S; end
class C < S
  include M2
  include M1
end

C.ancestors
# Resultado esperado: [C, M1, M2, M0, S, Object, Kernel, BasicObject]
```

**`ancestors` te muestra la línea real** de cualquier clase. `Kernel` y `BasicObject` son el piso de Ruby (`Object` incluye `Kernel` y hereda de `BasicObject`); siempre están al fondo, no los mires. Cuando dudes de una cadena, no razones: corré `ancestors`.

---

## 4. `include` se lee de abajo hacia arriba

Mirá la cadena: `M1`, incluido **último**, quedó **primero** en la búsqueda. No es un capricho.

Ruby es un lenguaje **destructivo**: cada línea trabaja sobre lo que dejó la anterior, y cada definición nueva **pisa** lo que había. Un `def` escrito debajo de otro `def` con el mismo nombre lo reemplaza. Con ese mismo criterio, `include` también pisa: **lo que se incluye después tiene prioridad sobre lo que se incluyó antes.**

```ruby
class Guerrero
  include Atacante
  include Defensor
  # Lookup: Guerrero → Defensor → Atacante → Object
  #                    ↑ leído de ABAJO hacia arriba: el último include gana
  # ✗ Trampa: leerlo de arriba hacia abajo ("Guerrero → Atacante → Defensor")
  #   es la lectura imperativa, y es exactamente al revés.
end

Guerrero.ancestors
# Resultado esperado: [Guerrero, Defensor, Atacante, Object, Kernel, BasicObject]
```

`Guerrero` es **más defensor que atacante**. Si `Atacante` y `Defensor` tuvieran un método con el mismo nombre, ganaría el de `Defensor`.

Y el refinamiento de la notación que hace falta: **tantas puntas de flecha como prioridad tenga la inclusión.** Más puntas, antes en la línea. La herencia queda siempre con una sola punta porque siempre va última.

```
┌──────────────┐                 ┌──────────────┐
│   Atacante   │                 │   Defensor   │
└──────────────┘                 └──────────────┘
        ▲                              ▲▲▲
         ╲                            ╱
          ╲     ┌──────────────┐     ╱
           ╲────┤   Guerrero   ├────╱
                └──────────────┘
```

---

## 5. Lo arbitrario hoy, y lo que cuesta cambiarlo mañana

Volvé a `Guerrero`. Incluye `Atacante` y después `Defensor`. ¿Por qué en ese orden? **Por ninguna razón.** Hoy no hay ningún método repetido entre los dos, así que el orden no cambia nada.

Ese es el problema: **cada vez que incluís dos módulos estás obligado a tomar una decisión que no estás preparado para tomar**, porque la herramienta no tiene forma de decir "por ahora no me importa". Lo único que podés hacer es dejarlo escrito:

```ruby
class Guerrero
  include Atacante
  include Defensor
  # Orden arbitrario: hoy no hay conflicto entre Atacante y Defensor.
  # Si aparece uno, revisar esta decisión.
```

Y cambiarlo después no es gratis. Si el orden estaba comentado como arbitrario, lo das vuelta, corrés los tests, listo. Si no, tenés que revisar **toda la jerarquía**: cada conflicto que hoy se resuelve hacia un lado va a cambiar de comportamiento. **Cambiar el orden de inclusión es un cambio tan drástico como cambiar de qué clase heredás**: cualquiera que haya construido sobre tu clase contando con esa relación tiene el código roto, sin que nada lo avise.

> **Para el diseño:** cuando el orden no importe, documentalo. Cuando importe, la pregunta es siempre la misma —*¿esta clase es más una cosa o más la otra?*— y la respuesta sale del dominio, no del código.

---

## 6. `super` dentro de un módulo

Esta es la pieza que más se subestima y la que más consecuencias tiene.

Parado dentro de un módulo, escribís `super`. ¿Adónde va? **No a "la superclase".** Va al **siguiente en la línea**, sea quien sea. Y el módulo **no sabe quién es**: la clase que lo incluye decide el orden, y con eso decide adónde cae el `super`.

```ruby
module M
  def m
    "M, y después " + super          # super: "el que venga atrás mío", sea quien sea
  end
end

module N
  def m
    "N, y después " + super
  end
end

module O
  def m
    "O"                               # no llama a super: acá termina
  end
end

class C
  include O
  include N
  include M                           # M queda primero: es el último incluido
end

# ¿CÓMO FUNCIONA?
C.ancestors                           # => [C, M, N, O, Object, Kernel, BasicObject]
C.new.m                               # C no tiene m → M#m → super → N#m → super → O#m
# Resultado esperado: "M, y después N, y después O"
```

`M` no tiene ninguna relación con `N`. Nunca lo nombró. Y sin embargo su `super` cae en `N`, porque así lo cableó `C`. Esto es una **herramienta de diseño** enorme: un módulo puede decir *"hago lo mío y sigo"* y **dejar que otro decida quién sigue**. La Parte 3 se construye entera sobre esto.

Una advertencia: si el último de la línea que tiene el método también llama a `super`, y nadie más lo tiene, la búsqueda cae en `Object`, que no lo entiende: `NoMethodError`. Toda cadena de `super` necesita alguien al final que **no** llame a `super`.

Un detalle de sintaxis: `super(x)` pasa ese argumento explícitamente; `super` a secas, sin paréntesis, pasa los mismos argumentos que recibió el método actual.

---

## 7. Mixins y traits: la comparación que vas a usar toda la cursada

Con conflicto, linearización y `super` ya explicados, ahora sí se puede decir qué es un trait y por qué importa acá.

**Un trait** resuelve el mismo problema que un mixin —una clase que quiere ser varias cosas— con otra mecánica: se combina **método por método** (podés decir "este trait, pero sin tal método"), no define estado, y cuando dos traits traen lo mismo **el código no compila** hasta que el programador resuelve el conflicto a mano, con operaciones como quitar un método, renombrarlo o sobreescribirlo. Y los traits **se aplanan**: antes de ejecutar, sus métodos se copian dentro de la clase y el trait desaparece. En tiempo de ejecución solo hay clases y herencia simple.

Esa última propiedad tiene una consecuencia directa sobre `super`: si el trait no existe en runtime, no hay "siguiente en la línea" adonde ir. **Un `super` dentro de un trait es el `super` común de la herencia**: va a la superclase de la clase donde el método quedó copiado. El cableado dinámico de la Sección 6 no existe con traits.

| Criterio | **Mixins** | **Traits** |
|---|---|---|
| Granularidad | Módulo entero | Método por método |
| Estado | Sí | No |
| Resolución de conflictos | Automática: la linearización elige | Manual: no compila hasta que resolvés |
| Runtime | Linearización: el módulo está vivo en la línea | Aplanado: se copia y desaparece |
| `super` | Dinámico: va al siguiente de la línea | Jerárquico: va a la superclase |
| Rol de la clase | El de siempre | Instanciar, pegar traits, definir estado |

Y arriba de todo, lo que comparten: **los dos complementan la herencia simple**, no la reemplazan.

**Por qué importa acá:** la segunda mitad de la cursada es Scala, y Scala le dice `trait` a su construcción. Pasala por la tabla y sale mixin en todos los criterios: se incluye entera, tiene estado, se lineariza, `super` es dinámico. **Ruby `module` y Scala `trait` son los dos mixins**, a pesar del nombre. La única diferencia práctica: Scala, por ser tipado, te obliga a sobreescribir explícitamente en la clase cuando dos traits traen el mismo método. Todo lo que aprendas en la Parte 3 vale en las dos mitades de la materia.

---

## ✅ Checkpoint — Parte 2

*Sin respuestas.*

1. ¿Por qué se dice que la herencia simple te dio la solución del conflicto junto con el problema?
2. Una clase incluye `A`, después `B`, y `B` incluye `Z`. Hereda de `S`, que incluye `Z`. Escribí la línea antes y después de limpiar.
3. Un compañero escribe `include Atacante` y abajo `include Defensor`, y comenta "primero atacante, después defensor". ¿Qué está mal?
4. ¿Qué significa que el orden de inclusión sea "arbitrario pero consistente"?
5. ¿Adónde va un `super` escrito dentro de un módulo, y quién lo decide?
6. ¿Por qué un `super` dentro de un trait no puede hacer lo mismo?
7. ¿Por qué los traits de Scala son mixins?

---

**FIN DE LA PARTE 2 — Conflictos y linearización**
