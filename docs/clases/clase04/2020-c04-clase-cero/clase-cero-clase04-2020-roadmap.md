# Clase desde Cero — Clase 04 (2020) — Roadmap

> **Qué es este material.** La clase 04 de TADP dada de nuevo, desde cero, en el orden en que los conceptos dependen unos de otros. Cubre lo que la planificación pide para esta clase: `instance_eval`, `class_eval`, `method_missing` y modelado con bloques. Está escrito para alguien que no siguió la clase: cada término se explica antes de usarse. Si ya sabés algo, lo leés rápido; si no, está todo.
>
> **Dominio de los ejemplos:** Age of Empires (guerreros, espadachines, murallas, misiles), el mismo que usa la materia en todas las clases y el que va a aparecer en el TP. El código base es el `age.rb` de la cátedra.
>
> **Versión de Ruby:** 3.x. Todo el código de los módulos se ejecutó antes de escribirse; los resultados que figuran como comentario son reales. El texto exacto de los mensajes de error cambia un poco entre versiones de Ruby (3.2, 3.3, 3.4): lo que importa es el tipo de error y la idea del mensaje, no la puntuación.

---

## Lo que hay que entender, en serio

Toda la clase se sostiene sobre **tres ideas**. El resto es sintaxis o aplicación.

| # | Idea | Pregunta que responde | Módulo |
|---|---|---|---|
| 1 | **Recepción dinámica de mensajes** | ¿Qué pasa cuando un objeto recibe un mensaje que no entiende, y quién decide qué hacer? | 2 |
| 2 | **El bloque como objeto que se lleva su contexto** | ¿Cómo guardo "algo para hacer después" sin ejecutarlo todavía, y qué variables ve cuando lo ejecuto? | 3 y 4 |
| 3 | **Cambiar el `self` de un bloque** | ¿A quién le llegan los mensajes que mando dentro de un bloque, y cómo hago que le lleguen a otro objeto? | 5 |

El módulo 1 es el Ruby que hace falta para leer el resto sin frenar. El módulo 6 junta las tres ideas en una herramienta real.

---

## Fases y módulos

### Fase A — Poder leer el código (módulo 1)

| Módulo | Archivo | Qué cubre | Densidad |
|---|---|---|---|
| **1** | `clase-cero-clase04-2020-modulo1-el-ruby-que-te-falta.md` | Todo es un envío de mensaje. `puts` vs `p` vs `inspect`. Arrays y `<<`. Hashes. `*args` en las dos direcciones. Strings e interpolación. `==` vs `equal?`. `nil` y booleanos. Las dos formas de escribir un bloque. `attr_reader`, `private def`. Gemas, `Gemfile`, `colorize`. `lib/` y `spec/`. | 🟡 Sintaxis, sin conceptos nuevos. Corto. Se lee una vez y se vuelve a consultar. |

### Fase B — Recepción dinámica de mensajes (módulo 2)

| Módulo | Archivo | Qué cubre | Densidad |
|---|---|---|---|
| **2** | `clase-cero-clase04-2020-modulo2-method-missing.md` | El lookup de la clase 3, con los mixins de la clase 2 ubicados adentro. Qué hace Ruby cuando llega al final sin encontrar nada. Por qué la decisión se la delega al objeto. `method_missing` y su firma. `respond_to_missing?`. Delegar a `super`. Por qué existe `BasicObject`. El registrador de mensajes completo. | 🔴 Idea 1. Es independiente de los bloques: se puede leer sin haber leído 3, 4 y 5. |

### Fase C — Bloques y contexto (módulos 3, 4 y 5)

| Módulo | Archivo | Qué cubre | Densidad |
|---|---|---|---|
| **3** | `clase-cero-clase04-2020-modulo3-contexto-y-scope-gates.md` | Qué es el contexto de un punto del programa. Por qué `class`, `def` y `module` cortan las variables (scope gates). El `NameError` explicado. Acá se siembra el dolor que los dos módulos siguientes curan. | 🟡 Corto. Sin él, el módulo 4 se entiende a medias. |
| **4** | `clase-cero-clase04-2020-modulo4-bloques-procs-lambdas.md` | Reificar comportamiento: un objeto que representa "algo para hacer". `proc`, `call`. Pasar un bloque a un método: `yield` y `&bloque`. Closures: qué se puede leer, modificar y crear adentro. Las dos diferencias entre proc y lambda (argumentos y `return`). Flat scope: `define_method` y `Class.new` como respuesta al módulo 3. | 🔴 Idea 2. El módulo más largo. |
| **5** | `clase-cero-clase04-2020-modulo5-self-e-instance-eval.md` | El receptor implícito: `puts "hola"` es `self.puts "hola"`. Quién es `self` dentro de un bloque. `instance_eval` cambia ese `self`. `instance_exec`. Qué pasa con un `def` adentro de un bloque: `instance_eval` vs `class_eval` y la *target class*. Autoclases en acción, incluidas las encadenadas "bajo demanda" que quedaron flotando de la clase 3. | 🔴 Idea 3. Es donde se junta todo. |

### Fase D — Integrador (módulo 6)

| Módulo | Archivo | Qué cubre | Densidad |
|---|---|---|---|
| **6** | `clase-cero-clase04-2020-modulo6-integrador-framework-de-testing.md` | Definir objetos y clases con una sintaxis propia (`objeto do … end`, `clase do … end`). Construir un framework de testing paso a paso: suite, tests diferidos, `assert`, cortar un test cuando falla (el `return` de un proc usado a propósito), decidir quién imprime resultados. Cada paso con su test. Cómo se llama cada cosa en el repo de la cátedra. | 🔴 Aplicación de las tres ideas. Nada nuevo conceptualmente; todo nuevo en cómo se combina. |

**Total: 6 módulos + este roadmap.**

---

## Por qué este orden y no otro

- **Módulo 1 primero** porque sin `<<`, `*args`, hashes e interpolación no se puede leer una sola línea del registrador de mensajes ni del framework. Es la sintaxis que aparece sin aviso.
- **Módulo 2 antes que los bloques** porque `method_missing` no necesita bloques para entenderse, y es la idea más autocontenida de las tres. Empezar por ahí da un cierre completo temprano.
- **Módulo 3 antes del 4** porque los bloques y los procs son *la solución* a un problema, y el problema es que `def` y `class` te cortan el contexto. Si ves la solución antes que el problema, `define_method` y `Class.new` parecen sintaxis rara en vez de herramientas.
- **Módulo 5 después del 4** porque `instance_eval` no se puede explicar sin tener claro qué ve un bloque cuando se ejecuta. `self` es la última variable del contexto que falta entender, y es la única que se puede cambiar desde afuera.
- **Módulo 6 al final** porque el framework usa las tres ideas a la vez. Verlo antes es verlo sin entenderlo.

---

## Hilos que se cierran

Cabos que se abren a propósito en un módulo y se resuelven en otro. Si en el medio sentís que falta algo, es porque falta: está marcado.

| Se abre en | Qué queda abierto | Se cierra en |
|---|---|---|
| Módulo 1 | `puts "hola"` es un mensaje sin receptor visible. ¿A quién se lo mando? | Módulo 5 |
| Módulo 1 | En las firmas aparece `&bloque`. Se dice qué es, no cómo funciona. | Módulo 4 |
| Módulo 1 | `"PASS".green` existe porque `colorize` le agregó un método a `String`. ¿Y cómo "existe" `assert` adentro de un test, si nadie le agregó nada a nadie? | Módulo 6 |
| Módulo 2 | El registrador anota los mensajes en una lista, pero es *otro* objeto: `is_a?` miente. ¿Cómo se arregla de verdad? | Módulo 2 (cierre) |
| Módulo 3 | Una variable definida afuera de `def` no se ve adentro. ¿Y si la necesito? | Módulo 4 |
| Módulo 4 | Un proc ve las variables de afuera. ¿Ve también a `self`? ¿Es el mismo `self`? | Módulo 5 |
| Módulo 4 | `return` dentro de un proc sale del método que lo contiene. Parece un defecto. | Módulo 6 (se usa a favor) |
| Módulo 5 | Un `def` adentro de un `instance_eval` define el método en la autoclase del receptor. ¿Y si quiero definirlo en la clase, para todas las instancias? | Módulo 5 (cierre) y 6 |

---

## Leyenda de bloques

| Marca | Significa |
|---|---|
| 🔴 | Central, evaluable. Si no entendés esto, no entendiste la clase. |
| 🟡 | Secundario. Necesario para seguir, pero no es el corazón. |
| 🟢 | Mencionado al pasar. Saber que existe alcanza. |
| 🕳️ **Madriguera** | Tangente que la clase roza y no usa. Se lee en diez segundos y se sigue. Nunca hace falta para el camino principal. |
| ⚠️ | Trampa: un error que te va a pasar escribiendo código. Viene con la forma correcta al lado. |
| 🎓 **Para el parcial, si te preguntan** | Respuesta modelo, corta, con la terminología de la materia. En esta materia la instancia individual es sobre tu propio TP, así que estos bloques apuntan a *dónde pondrías esto y por qué*, no a definiciones. |
| `# => …` | Resultado real de ejecutar esa línea. Está para que no tengas que ir a la consola a comprobarlo. |
| `# Resultado esperado:` | Lo mismo, para bloques de varias líneas o salidas de varias líneas. |

---

## Cómo usar este material

1. **En orden.** Cada módulo asume los anteriores. La única flexibilidad: el módulo 2 no depende de los bloques, así que podés leerlo en su lugar (después del 1) o dejarlo para después del 5. Pero no lo saltees.
2. **Leé el código comentado como si fuera el texto.** Está escrito para eso: cada línea relevante dice qué hace y por qué. Si podés predecir el `# =>` antes de leerlo, vas bien. Si no, releé esa sección antes de seguir.
3. **No abras la consola para leer.** Los resultados ya están. Abrila para practicar, después de cada módulo, con el checkpoint en la mano.
4. **El checkpoint no tiene respuestas a propósito.** Si no podés contestar una pregunta, buscá en el módulo, no en el chat. Las respuestas van al complemento cuando cerremos la unidad.
5. **Dudas por chat, de a un módulo.** Se aclara, y si hace falta se rehace el módulo con la aclaración adentro. Recién después, el siguiente.
6. **Cuando termines el 6**, vas a poder abrir `6_framework_tests.rb` del repo de tu cursada y leerlo de corrido. Esa es la prueba de que la clase está entendida.

---

**FIN DEL ROADMAP — Clase desde Cero, Clase 04 (2020)**
