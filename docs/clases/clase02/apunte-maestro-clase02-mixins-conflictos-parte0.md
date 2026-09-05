# 📘 APUNTE MAESTRO — clase02 · Mixins: resolución de conflictos
## Parte 0 — Mapa de la unidad

| Campo | Valor |
|---|---|
| **Unidad** | `clase02` (+ `preclase02`, procesada aparte) |
| **Fecha** | Sábado 22 de agosto de 2026 |
| **Tema** | Mixins y Traits. Qué son, cómo resuelven conflictos, qué rol le queda a la clase, en qué tecnologías están |
| **Tecnología** | Ruby |
| **Dominio de ejercicio** | Age of Empires (continúa el de la clase 1) |
| **Lugar en la materia** | Segunda y **última clase del primer módulo** (repaso de objetos + mixins). Lo que sigue es metaprogramación, y ahí los mixins se usan, no se vuelven a explicar |
| **Lectura previa** | Paper de Bracha (mixins) + paper de Ducasse (traits) — ya procesados como `preclase02` |

---

## Cómo está armada esta unidad

El apunte está partido en cinco piezas. Cada una se para sobre la anterior; ninguna se salta.

| Parte | Título | Qué vas a poder hacer al terminarla |
|---|---|---|
| **0** | Mapa de la unidad *(este archivo)* | Saber qué se asume, qué se evalúa, y con qué nombres se habla |
| **1** | Dos herramientas nuevas y de dónde salen | Explicar qué es un mixin y qué es un trait, por qué existen, y por qué **complementan** la herencia en vez de reemplazarla |
| **2** | Conflictos, linearización y el rol de la clase | Dado un modelo con mixins, **decir qué método se ejecuta y por qué**, dibujar la cadena de linearización, y explicar qué cambia con traits |
| **3** | Qué tiene cada tecnología | Clasificar Ruby, Scala, Java, Kotlin, Python y JavaScript contra los criterios, y defender por qué clasificar sirve para diseñar |
| **4** | Age of Empires: el descanso, el kamikaze y el guerrero que hace dos cosas | Resolver un conflicto real de tres formas distintas (orden de inclusión, cadena con centinela, `alias_method`) y elegir cuál con fundamento |

El hilo es uno solo: **una entidad que quiere ser dos cosas a la vez.** La clase 1 mostró que la herencia simple no puede con eso. Esta unidad trae la herramienta que sí puede, y pasa el resto del tiempo mostrando dónde *esa* herramienta también se complica.

---

## Cómo leer este apunte

**Marcas de importancia** (van en cada sección):

- 🔴 **Central.** Es lo que la unidad viene a enseñar. Va a reaparecer en el TP y en los individuales.
- 🟡 **Secundario.** Se explicó en clase con desarrollo, pero es contexto o alternativa: hay que entenderlo, no dominarlo.
- 🟢 **Al pasar.** Mencionado, sin desarrollo. Saber que existe alcanza.

**Otros bloques que vas a encontrar:**

> 🕳️ **Madriguera** — un tema que la clase rozó y que no se va a usar. Una o dos líneas para saber que existe, y seguís.

> ⚠️ **Advertencia** — cuando lo que se enseña y lo que pasa en la práctica difieren. Termina siempre con "para el examen, respondé X".

> 📝 **Para el parcial, si te preguntan** — pregunta probable con su respuesta modelo, en el formato en que conviene responderla.

**Código:** todo el código va comentado línea por línea, con el resultado esperado escrito al lado. Se puede leer sin ejecutar. Ejecutar es para practicar, no para entender.

---

## Qué se asume de la clase 1

Esta unidad se para sobre la clase 1 sin volver a explicarla. Lo que se da por sabido:

- **El modelo de Age of Empires** y su problema: `Guerrero` necesita ser `Atacante` *y* `Defensor` a la vez, y con herencia simple no hay cableado posible que no ensucie interfaces o repita código.
- **Method lookup:** cuando un objeto recibe un mensaje, se busca el método en su clase, si no está se sube a la superclase, y así hasta encontrarlo o llegar a `Object`.
- **Sobreescritura y `super`:** una subclase redefine un método y, si quiere, llama al de arriba con `super`.
- **Ruby mínimo:** `class` / `def` / `end`, `self`, `attr_accessor` (genera getter y setter de una variable de instancia), `@variable` es estado del objeto, `Clase.new` instancia.
- **`module` e `include`** se nombraron al final de la clase 1 como la salida al callejón. Esta unidad los explica de verdad; no hace falta traerlos sabidos.

---

## Nomenclatura del código de esta unidad

Los nombres que se usan en todo el apunte son los del código real de la clase. Conviene fijarlos porque son los que aparecen en el TP.

| Concepto | Nombre en código |
|---|---|
| Mixin de los que atacan | `Atacante` |
| Mixin de los que defienden | `Defensor` |
| Mixin terminador (aparece en la Parte 4) | `Unidad` |
| Clases concretas | `Guerrero`, `Misil`, `Muralla`, `Kamikaze`, `Espadachin` |
| Potencial de ataque | `potencial_ofensivo` |
| Potencial de defensa | `potencial_defensivo` |
| Vida del defensor | `energia` |
| Bandera de descanso del atacante | `descansado` |
| Atacar | `atacar(un_defensor)` |
| Recibir daño | `sufri_danio(danio)` — *así, sin la erre* |
| Descansar | `descansar` |

Todo en `snake_case`, que es la convención de Ruby (palabras en minúscula separadas por guion bajo).

---

## Mapa de evaluabilidad

Cómo se infiere la marca: cuánto tiempo se le dedicó en clase, si hubo código y ejemplos, si se dijo "esto no lo vamos a pedir", y si es prerrequisito de lo que viene.

| Tema | Marca | Por qué |
|---|---|---|
| Qué es un mixin, qué es un trait, diferencia | 🔴 | Primera pregunta de la unidad; base de todo lo demás |
| Los seis criterios de comparación (granularidad, estado, resolución de conflictos, runtime, `super`, rol de la clase) | 🔴 | Es la herramienta para clasificar cualquier tecnología nueva; se usa en las Partes 3 y 4 |
| Por qué complementan la herencia simple y no la reemplazan | 🔴 | Se pidió explícitamente el *porqué*, no la afirmación |
| Conflicto: qué es, distinguirlo de la herramienta que lo resuelve | 🔴 | Concepto que la herencia simple te ocultó |
| **Regla de linearización de Ruby** y por qué se preserva el último | 🔴 | El núcleo mecánico de la unidad; sin esto no se predice qué método corre |
| Aplanado (flattening) en traits y qué implica para `super` | 🔴 | Define la diferencia de fondo entre las dos herramientas |
| Leer `include` de abajo hacia arriba | 🔴 | Error más probable escribiendo código |
| Cambiar el orden de los `include` es un cambio mayor | 🔴 | Argumento de diseño que el profe usa para evaluar |
| Rol de la clase según cada autor y cuándo usar cada herramienta | 🔴 | Tercera y cuarta pregunta de la unidad |
| Clasificar Ruby y Scala | 🔴 | Son los lenguajes de la cursada |
| Clasificar Java, Kotlin, Python, JavaScript | 🟡 | Desarrollado, pero como ejercicio de criterio, no como contenido |
| Resolver conflictos con orden de inclusión y con `alias_method` | 🔴 | Código escrito en clase, con tests |
| **Cake Pattern** (cadena con `super` + mixin centinela) | 🟡 | Se desarrolló completo, pero se avisó que **no se va a pedir**. Hay que entenderlo porque es el mejor argumento a favor de la linearización |
| Decorator y por qué el Cake Pattern lo supera | 🟡 | Comparación conceptual, sin código propio |
| Por qué el estado es difícil en estas herramientas | 🟡 | Explicado con un ejemplo, no evaluado directo |
| `override` como protección del programador | 🟡 | Al pasar, pero con desarrollo |
| Open classes en Ruby | 🟢 | Anticipo de metaprogramación; se explica en la clase 3 |
| Persistencia con ORM de jerarquías con mixins | 🟢 | Respuesta a una pregunta, fuera de alcance |
| Historia de los paradigmas, React, Svelte | 🟢 | Digresión; queda como madriguera |

---

## Información operativa capturada en clase

- **El primer módulo no tiene evaluación propia.** Mixins se evalúan dentro de metaprogramación, es decir, dentro del **TP1** y del **Individual 1**.
- **Recomendación explícita para los TPs:** usar mixins **lo más posible**, no porque siempre sea lo mejor sino porque es la herramienta nueva y el reflejo va a ser volver a la herencia. Cuanto más cómodo estés con ella, más libre vas a ser cuando tengas que elegir.
- **Grupos:** quien esté en la planilla sin grupo va a ser asignado a uno. Los ayudantes se reparten por grupo.
- **TP1:** el enunciado sale entre la semana siguiente y la otra.
- **Material:** todo lo de la clase se publica (código en el repo, scripts en la página). La indicación es participar en clase y no sacar fotos: se puede bajar después.

---

## Glosario de la unidad

Términos que esta unidad introduce. Una línea cada uno; la explicación completa está en la parte indicada.

| Término | Qué es | Parte |
|---|---|---|
| **Mixin** | Paquete de comportamiento que una clase puede incluir; no se instancia; se pueden incluir varios | 1 |
| **Trait** | Como un mixin, pero se combina método por método y desaparece en tiempo de ejecución | 1 |
| **Módulo** | Palabra genérica para cualquier proveedor de lógica: clase, mixin, trait. En Ruby además es la palabra clave `module` | 1 |
| **Granularidad** | Unidad mínima que se puede combinar: el módulo entero, o método por método | 1 |
| **Conflicto** | Dos métodos disponibles para un mismo mensaje | 2 |
| **Linearización** | Convertir una jerarquía con mixins en una lista ordenada donde buscar métodos | 2 |
| **Aplanado (flattening)** | Copiar los métodos de los traits dentro de la clase antes de ejecutar; los traits no existen en runtime | 2 |
| **Álgebra de traits** | Las operaciones para combinar traits a mano: sumar, quitar un método, renombrar | 2 |
| **Glue code** | El código que la clase escribe para pegar traits y resolver sus conflictos | 2 |
| **`super` dinámico** | `super` que va al siguiente de la lista linearizada, no a la superclase | 2 |
| **Centinela / terminador** | Mixin al fondo de la cadena cuyo único trabajo es frenar los `super` | 4 |
| **Cake Pattern** | Cadena de mixins que hacen su parte y llaman a `super`, cerrada con un centinela | 4 |
| **`alias_method`** | En Ruby: copiar un método existente con otro nombre | 4 |
| **Open classes** | En Ruby, `class X` no define X: la *abre* y agrega cosas | 2 (glosa) |

---

**FIN DE LA PARTE 0 — Mapa de la unidad**
