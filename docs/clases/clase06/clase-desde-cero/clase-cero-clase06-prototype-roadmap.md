# Clase desde cero — Prototype — Roadmap

**Unidad:** clase06 (Ruby, ejercicio integrador de metaprogramación)
**Tipo de material:** clase desde cero, 9 módulos + 1 opcional
**Qué es esto:** el índice de la clase. Dice qué necesitás tener a mano, en qué orden leer, qué parte del enunciado resuelve cada módulo, qué dolores se siembran en un módulo y se curan en otro, y cómo leer los bloques.

---

## Antes de empezar: tené el enunciado a mano

Esta clase **consiste en resolver un enunciado**: el ejercicio integrador "Prototype" (2do cuatrimestre 2015), un trabajo práctico de años anteriores que la cátedra usa como práctica integradora. No hay tema nuevo de Ruby; hay que bajar a código todo lo visto hasta la clase04, guiados por ese enunciado.

Por eso necesitás tenerlo **impreso o abierto al lado**, en el archivo `fuente-ejercicio-prototype.md` (seis páginas, cuatro partes: 4.1 a 4.4). Cada módulo cita el pedazo del enunciado que resuelve, te ubica en qué parte estás, y lo desarma. El material se lee **con el enunciado en la mano**, no en lugar del enunciado.

**Una línea para agregar a mano.** La cátedra usa hoy una versión del enunciado con una sola diferencia de fondo respecto del PDF de 2015: en la parte 4.1, justo debajo de `guerrero.set_property(:energia, 100)`, pide también

```ruby
expect(guerrero.get_property(:energia)).to eq(100)
```

y aclara que `guerrero.energia` *también* tiene que funcionar. Anotalo en tu impreso: el Módulo 2 arranca por esa línea.

## Qué vas a poder hacer al terminar

Vas a haber escrito, entendido y ejecutado un framework de unas 200 líneas que le agrega a Ruby una forma de compartir comportamiento que no trae: **prototipos**. Objetos que no sacan sus métodos de una clase sino de otro objeto, y que cuando no entienden un mensaje van a buscarlo a ese otro objeto. Al final sabés:

- leer el enunciado completo sin trabarte en ninguna palabra;
- qué es un prototipo, en qué se parece a una clase y en qué no;
- guardar propiedades y métodos en un objeto, sin clase de por medio, y elegir entre tres formas de hacerlo;
- la diferencia entre copiar un objeto y linkearlo a otro, y qué se rompe en cada caso;
- construir una búsqueda de métodos propia, a lo largo de una cadena de objetos, con `method_missing`;
- escribir constructores que reparten argumentos entre varios inicializadores, en orden;
- hacer que un método llame a "la implementación siguiente" sin que exista `super`;
- cómo localizar el impacto de un requerimiento nuevo sobre código propio.

La última es la habilidad que se evalúa en el individual; el ejemplo que la cátedra dio como muestra de individual (de un prototipo a varios) está resuelto en el Módulo 9.

## Qué parte del enunciado resuelve cada módulo

| Módulo | Parte del enunciado | Qué cubre | Densidad |
|---|---|---|---|
| M1 · El problema | Secciones 1 a 3 (objetivos, introducción, comportamiento esperado) | Qué es un prototipo, con Juan y Martín; prototipos contra clases; por qué quien usa el framework no ve clases; la introducción del enunciado frase por frase; qué queremos poder escribir | 🟡 |
| M2 · Propiedades | 4.1, las tres primeras líneas | `set_property` y `get_property`; tres lugares donde guardar una propiedad y por qué se elige el diccionario; inicialización perezosa y la trampa del `nil`; qué pasa con una propiedad que no existe; `guerrero.energia` con un getter en la autoclase | 🔴 |
| M3 · Métodos | 4.1, `set_method` | Un método para un solo objeto con `define_singleton_method`; por qué `self` queda bien sin hacer nada; la otra forma (un diccionario de procs y `method_missing`), mostrada y dejada en espera, con las razones para no usarla todavía | 🔴 |
| M4 · `clone` | 4.1, cierre del primer bloque | El `clone` de Ruby copia la autoclase pero **comparte el diccionario** (Atila y Jack); copia superficial contra profunda; `initialize_copy`; `clone` contra `dup` | 🔴 |
| M5 · `set_prototype` | 4.1, segundo bloque hasta `expect(espadachin.potencial_ofensivo).to eq(45)` | Copiar contra linkear (aplanar contra linealizar); con métodos en la autoclase no hay dónde engancharse → diccionario de métodos + `method_missing` + `instance_exec`; la cadena de prototipos; `sanar` llega al derivado; el clon no lo ve; lo redefinido no se pisa; el `@potencial_ofensivo` del enunciado | 🔴 |
| M6 · Azúcar de 4.1 | 4.1, `espadachin.energia = 100` y `include Prototyped` | El setter que solo sale con `method_missing` (el nombre termina en `=`); prioridad del método sobre el setter; `respond_to_missing?` para que `respond_to?` diga la verdad; extraer el módulo `Prototyped` y meterlo en `Object`, con la trampa de `to_s` | 🔴 |
| M7 · Constructores | 4.2 | `PrototypedConstructor`: con un proc, por defecto con un mapa, `copy`, y `extended`, que consume los argumentos en orden | 🔴 |
| M8 · Azúcar de 4.3 | 4.3 | `x = proc` define un método; `PrototypedObject.new { … }`; constructor con bloque; `create … with`, `with_properties`; `prototype` de un constructor, y el test de Atila que rompe el getter guardado como método | 🔴 |
| M9 · `call_next` y múltiples prototipos | 4.4 y el ejemplo de individual | Llamar a la implementación siguiente de la cadena; la pila de llamadas; varios prototipos, en orden, sin que se encadenen entre sí; "¿dónde se usa `prototype` en tu TP?" | 🔴 |
| M10 · La otra forma: módulos | (no está en el enunciado) | Un módulo por objeto, incluido en su autoclase: el lookup lo hace Ruby. Qué gana (`to_s`, `respond_to?` gratis), qué pierde, y el callejón de `bind`. Se puede saltear. | 🟡 |

**Densidad:** 🔴 central y evaluable · 🟡 secundario · 🟢 mencionado al pasar. La marca aparece también sección por sección dentro de cada módulo.

**Orden:** sigue al enunciado, línea por línea, y adentro de cada parte sigue las dependencias. M2 a M6 son la parte 4.1 en el orden exacto en que el enunciado la escribe: primero propiedades, después métodos, después `clone`, después `set_prototype`, y recién ahí el setter `espadachin.energia = 100`, porque ese setter necesita `method_missing`, y `method_missing` aparece recién cuando hace falta buscar en el prototipo. M7 y M8 son 4.2 y 4.3 tal cual. M9 cierra con 4.4. M10 se entiende solo después de tener la forma buena.

## Hilos que se siembran y se cierran

| Hilo | Se siembra en | Se cierra en |
|---|---|---|
| H1 · `guerrero.energia` no responde: la propiedad está en el diccionario, pero nadie definió el mensaje | M2 | M2, misma sección (un getter en la autoclase) |
| H2 · Con métodos en la autoclase, el lookup lo hace Ruby y no hay dónde engancharse para "buscar en otro lado" | M3 (se muestra la alternativa y se deja en espera) | M5 (`method_missing` es el único gancho) |
| H3 · Dos objetos que comparten el mismo diccionario: Jack baja a 90 y Atila también | M4 | M4, misma sección (copiar el diccionario) |
| H4 · El getter guardado como un método más le gana al método que el prototipo define después | M5 | M8 (buscar métodos en toda la cadena antes que la propiedad propia) |
| H5 · `@potencial_ofensivo` en el enunciado: la variable de instancia no existe, el valor está en el diccionario | M5 | M9 (`call_next`, como el propio enunciado anticipa) |
| H6 · Un objeto tiene un solo prototipo | M5 | M9 (una lista, recorrida en orden) |
| H7 · `to_s` nunca llega a `method_missing`: viene de `Object`, y el derivado no ve la versión del prototipo | M6 | M10 (módulos en la autoclase) |

## Leyenda de bloques

| Bloque | Qué es |
|---|---|
| 📄 **El enunciado dice** | Recuadro con la frase o el fragmento **textual** del enunciado, con su ubicación exacta (parte y bloque). Abajo, "en criollo": qué pide, y en qué método o línea va a terminar. Se cita solo lo que vale la pena reconocer después; lo que está confuso o tiene una errata se señala y se reemplaza por la explicación. |
| `> Regla` | Recuadro al inicio de cada sección. Una a tres líneas, en afirmativo. Es el enunciado de la regla; el porqué viene después del caso. |
| Código comentado | Cada línea relevante lleva qué hace y por qué. La salida real va como comentario `# => …`, verificada por ejecución. `# también: …` al lado de una línea muestra otra forma de escribir lo mismo. |
| Código en construcción | El mismo método mostrado en pedazos: primero incompleto, con lo que devuelve así y por qué, después completo. Las piezas armadas van al final del módulo, con sus tests. |
| Tabla *escribís / Ruby entiende / sale* | Cuando algo admite varias formas, las muestra todas sobre el mismo caso, incluidas las que fallan y su error exacto. |
| 💎 **Otra forma de hacerlo** | Al pie de una sección, en pocas líneas: una variante que resuelve lo mismo de otra manera, con su trade-off. No cambia el código principal; está para que la reconozcas si la ves en otro código. |
| 🛠️ **Lo que te va a marcar el editor** | Una línea por cada aviso, sugerencia o atajo de RubyMine que aparece con ese código, donde aparece por primera vez. |
| 🕳️ **Madriguera** | Algo que existe, se nombra en una a tres líneas, y no forma parte del camino. Se saltea sin culpa. |
| 🎯 **Para el parcial, si te preguntan** | Respuesta en formato examen: la primera oración ya responde, con la terminología de la materia. |
| ⚠️ **Trampa** | Un error que le pasa a cualquiera escribiendo este código, con la forma correcta al lado. |
| **Checkpoint** | Preguntas sin respuesta al final de cada módulo. Las respuestas van al complemento, después de que las contestes. |

**Términos:** cada palabra técnica se define **una sola vez, la primera vez que aparece**, en negrita y en una línea, dentro del flujo. No hay glosario aparte: el material se lee en orden, y la primera vez que te cruzás con la palabra ahí está su definición.

**Sobre las decisiones de diseño.** El enunciado deja varias cosas abiertas a propósito ("no se busca acotar las posibles implementaciones"). En cada punto donde hay más de un camino, el módulo muestra las opciones, dice cuál toma el código de esta clase y por qué, y deja las otras como 💎. Cuatro de esas decisiones atraviesan toda la clase y conviene saberlas de entrada:

1. **Las propiedades viven en un diccionario**, no en variables de instancia (M2). Consecuencia: el `@potencial_ofensivo` que el enunciado escribe no anda tal cual; M5 lo explica y M9 lo reemplaza por `call_next`.
2. **El getter de una propiedad es, al principio, un método más** (M5). Aguanta toda la 4.1; un test de la 4.3 lo rompe y M8 lo corrige. Se hace así para que veas por qué.
3. **`clone` y `set_prototype` son dos cosas distintas**, como las separa el enunciado: `clone` copia y se desentiende; `set_prototype` linkea (M4 y M5).
4. **Todos los constructores siguen una regla**: un proc recibe primero al objeto nuevo; un bloque se ejecuta con `self` igual al objeto nuevo (M7 y M8).

## Cómo usarlo

1. Enunciado a mano. Un módulo por sesión. Leé el código comentado completo; está escrito para entenderse sin ejecutarlo, y para reconocerlo después cuando lo escribas o lo veas escrito de otra forma.
2. Cuando termines el módulo, contestá el checkpoint por escrito antes de seguir. Las dudas van al chat.
3. Recién con las dudas cerradas se pasa al siguiente módulo.
4. Al terminar M9 tenés el archivo `clase06-prototype.rb` completo con sus tests en `clase06-prototype_spec.rb`. Ahí sí conviene ejecutarlo y romperlo a propósito. M10 es opcional.

## Sintaxis de Ruby que aparece por primera vez en esta unidad

Cada una se presenta en el paso del módulo donde se usa, primero en su forma normal, con la alternativa en una línea al lado.

| Construcción | Módulo |
|---|---|
| `Hash#key?`, `Hash#keys`, `Hash#fetch` con bloque, `\|\|=` sobre una variable de instancia | M2 |
| `define_singleton_method(sel, &proc)`; la diferencia entre `def m(bloque)` y `def m(&bloque)` | M3 |
| `initialize_copy`, `clone` contra `dup`, `Hash#dup`, `equal?` | M4 |
| `&.` (mensaje solo si no es `nil`), `instance_variable_get` para mirar adentro de un objeto | M5 |
| `Symbol#end_with?`, `String#chomp`, `String#to_sym`, `Class.new { … }`, `freeze` / `frozen?`, `a \|\| (c ? b : x = d)` | M6 |
| `Proc#arity`, `Array#take`, `Array#drop`, parámetro con nombre (`padre:`), `protected`, `let` en RSpec | M7 |
| `&bloque` opcional en `initialize`, `is_a?(Proc)`, `lambda`, `Array#zip`, `attr_reader`, encadenar mensajes que devuelven `self` o un objeto nuevo | M8 |
| `ensure`, `yield`, `Array#index` con bloque, parámetro con valor por defecto en un método recursivo, `Array#none?` | M9 |
| `Module.new`, `tap`, `singleton_class.include`, `super()` dentro de `define_method` | M10 |

---

**FIN DEL ROADMAP**
