# Stateful Traits

> Traducción interpretativa al español de `fuente-berg07a-stateful-traits.md` (conversión fiel a Markdown de Berg07aStatefulTraits.pdf, 26 páginas). El archivo en inglés queda intacto y es la referencia canónica.

## Glosario de términos conservados en inglés

- **trait**: unidad de reuso compuesta solo de métodos; se conserva en inglés por ser el término técnico consagrado.
- **stateless / stateful**: sin estado / con estado.
- **provided methods / required methods**: métodos provistos / métodos requeridos.
- **accessor / mutator**: método de acceso (getter) / método de modificación (setter).
- **glue code / glue methods**: código/métodos "pegamento" que integran los traits en la clase.
- **shell class**: clase "cáscara", que solo declara variables y define sus accessors.
- **flattening property**: propiedad de aplanamiento.
- **mixin**: extensión componible aplicada mediante herencia lineal.
- **aliasing**: creación de un alias (nombre adicional) para un método.
- **black-box / white-box**: reuso caja negra / caja blanca.
- **offset**: desplazamiento (posición fija de una variable en la memoria del objeto).
- **copy-down**: técnica de "copiado hacia abajo" de métodos con offsets ajustados.
- **virtual base pointer**: puntero a base virtual (C++).
- **method lookup**: búsqueda de métodos.
- **scope**: alcance (ámbito de visibilidad).

---

**Alexandre Bergel¹, Stéphane Ducasse², Oscar Nierstrasz³, Roel Wuyts⁴**

1. DSG, Trinity College Dublin, Ireland
2. Language and Software Evolution – LISTIC, Université de Savoie
3. Software Composition Group, University of Bern
4. Lab for Software Composition and Decomposition, Université Libre de Bruxelles

*Advances in Smalltalk — Proceedings of 14th International Smalltalk Conference (ISC 2006), LNCS, vol. 4406, Springer, 2007, pp. 66–90*

## Resumen (Abstract)

Los traits ofrecen un mecanismo de grano fino para componer clases a partir de componentes reutilizables, evitando los problemas de fragilidad que traen la herencia múltiple y los mixins. Los traits, tal como fueron propuestos originalmente, son stateless (sin estado): contienen solo métodos, sin variables de instancia. Dentro de un trait, al estado solo puede accederse mediante accessors (métodos de acceso), que pasan a ser métodos requeridos del trait. Aunque este enfoque funciona razonablemente bien en la práctica, implica que muchos traits, vistos como componentes de software, quedan artificialmente incompletos, y que las clases que los usan pueden cargar con cantidades significativas de glue code repetitivo (código "pegamento" de integración). Si bien estas limitaciones se mitigan en gran medida con buen soporte de herramientas, buscamos una solución más limpia que soporte traits stateful (con estado). La dificultad central es cómo manejar los conflictos que surgen cuando los traits compuestos aportan variables de instancia cuyos nombres chocan. Presentamos una solución fiel al principio rector de los traits stateless: el cliente conserva el control de la composición. Los traits stateful son una extensión mínima de los traits stateless en la que las variables de instancia son puramente locales al scope (alcance) del trait, salvo que el cliente que realiza la composición las haga explícitamente accesibles. Los conflictos de nombres se evitan, y los clientes pueden fusionar explícitamente variables de traits disjuntos. Discutimos y comparamos dos estrategias de implementación, y presentamos brevemente un caso de estudio en el que usamos traits stateful para refactorizar la versión basada en traits de la jerarquía de colecciones de Smalltalk.

## 1 Introducción

Los traits son unidades puras de reuso que consisten únicamente en métodos [SDNB03, DNS+06]. Los traits pueden componerse para formar otros traits o clases. Se les reconoce su potencial para lograr mejor composición y reuso, de ahí su integración en versiones nuevas de lenguajes como Perl 6, Squeak [IKM+97], Scala [sca], Slate [Sla] y Fortress [for]. Aunque los traits fueron diseñados originalmente para lenguajes de tipado dinámico, ha habido un interés considerable en aplicarlos también a lenguajes de tipado estático [FR03, SD05, NDS06].

Los traits hacen posible que la herencia se use para reflejar la jerarquía conceptual, en lugar de usarse para reutilizar código. El código duplicado puede factorizarse en traits, en vez de calzarse a presión en lugares incómodos de la jerarquía de clases. Al mismo tiempo, los traits evitan en gran medida los problemas de fragilidad que introducen los enfoques basados en herencia múltiple y mixins, porque los traits están completamente divorciados de la jerarquía de herencia.

En su forma original, sin embargo, los traits son stateless; es decir, son puramente grupos de métodos sin ninguna variable de instancia. Como los traits no solo proveen métodos sino que también pueden requerirlos, el idioma que se introdujo para lidiar con el estado fue acceder a él únicamente a través de accessors. El cliente de un trait es una clase o un trait compuesto que usa al trait para construir su implementación. Un principio clave detrás de los traits es que el cliente conserva el control de la composición. El cliente, por lo tanto, es responsable de proveer los métodos requeridos y de resolver cualquier conflicto posible. Los accessors requeridos se propagaban hacia los traits compuestos, y solo la clase cliente que realizaba la composición quedaba obligada a implementar los accessors faltantes y las variables de instancia a las que dan acceso. En la práctica, los accessors y las variables de instancia podían generarse fácilmente con una herramienta, así que el hecho de que los traits fueran stateless era apenas una molestia menor.

Conceptualmente, sin embargo, la falta de estado significa que prácticamente todos los traits están incompletos, ya que casi cualquier trait útil va a requerir algún accessor. Más aún, el mecanismo de métodos requeridos se usa de manera abusiva para cubrir la falta de estado. Como consecuencia, la interfaz requerida de un trait queda saturada de ruido que dificulta su comprensión y, con ella, su reuso. Aun cuando el estado y los accessors faltantes puedan generarse, muchos clientes van a consistir en "shell classes" (clases cáscara): clases que no hacen otra cosa que componer traits con glue code repetitivo. Además, si los accessors requeridos se hacen públicos (como ocurre en la implementación de Smalltalk), se viola innecesariamente el encapsulamiento en las clases cliente. Por último, si un trait alguna vez se modifica para incluir estado adicional, los nuevos accessors requeridos se propagan a todos los traits y clases cliente, ¡introduciendo así una forma de fragilidad que los traits pretendían evitar!

Este paper describe los traits stateful, una extensión de los traits stateless en la que se introduce un único operador de acceso a variables que les da a los clientes de los traits control sobre la visibilidad de las variables de instancia. El enfoque es fiel al principio rector de los traits stateless, según el cual el cliente de un trait tiene control total sobre la composición. Este principio es la clave para evitar la fragilidad frente al cambio, porque cuando un trait se modifica no entra en juego ninguna regla implícita de resolución de conflictos.

En pocas palabras, las variables de instancia son privadas del trait. El cliente puede decidir, sin embargo, en el momento de la composición, acceder a variables de instancia que ofrece un trait usado, o fusionar variables ofrecidas por múltiples traits. En este paper presentamos un análisis de las limitaciones de los traits stateless y presentamos nuestro enfoque para lograr traits stateful. Describimos y comparamos dos estrategias de implementación, y describimos brevemente nuestra experiencia con un caso de estudio ilustrativo.

La estructura del paper es la siguiente: primero repasamos los traits stateless [SDNB03, DNS+06]. En la Sección 3 discutimos las limitaciones de los traits stateless. En la Sección 4 introducimos los traits stateful, que soportan la introducción de estado en los traits. La Sección 5 esboza algunos detalles de la implementación de los traits stateful. En la Sección 6 presentamos un pequeño caso de estudio en el que comparamos los resultados de refactorizar la jerarquía de colecciones de Smalltalk con traits stateless y con traits stateful. En la Sección 7 discutimos algunas de las consecuencias más amplias del diseño de los traits stateful. La Sección 8 discute el trabajo relacionado. La Sección 9 concluye el paper.

## 2 Traits stateless

### 2.1 Grupos de métodos reutilizables

Los traits stateless son conjuntos de métodos que sirven como bloque de construcción conductual de las clases y como unidades primitivas de reuso de código [DNS+06]. Además de ofrecer comportamiento, los traits también *requieren métodos*; es decir, métodos que hacen falta para que el comportamiento del trait se cumpla. Los traits no definen estado; en su lugar, requieren accessors.

**Fig. 1.** La clase `SyncStream` se compone de los dos traits `TSyncReadWrite` y `TStream`

```
 ┌────────────────────────────┐          ┌──────────────────────┐
 │       TSyncReadWrite       │          │       TStream        │
 │  provided     │  required  │          │ provided │ required  │
 ├───────────────┼────────────┤          ├──────────┼───────────┤
 │ syncRead      │ read       │          │ read     │           │
 │ syncWrite     │ write      │          │ write    │           │
 │ hash          │ lock:      │          │ hash     │           │
 │               │ lock       │          └──────────┴───────────┘
 └───────────────┴────────────┘                    △△
              △△                                   │
              │  @{hashFromSync -> hash}           │  @{hashFromStream -> hash}
              │                                    │
              └───────────────┬────────────────────┘
                              │
                      ┌───────┴──────┐
                      │  SyncStream  │
                      ├──────────────┤
                      │ lock         │
                      ├──────────────┤
                      │ lock         │
                      │ lock:        │
                      │ isBusy       │
                      │ hash         │
                      └──────────────┘

 Leyenda del original:  [Trait Name | provided methods | required methods]
                        flecha con doble punta abierta (△△) = "Uses trait"
```

![Figura 1 — diagrama original](fuente-berg07a-stateful-traits-fig1.png)

Cuerpos de métodos adjuntos como notas en la figura:

```smalltalk
syncRead
    | value |
    self lock acquire.
    value := self read.
    self lock release.
    ^ value

syncWrite
    | value |
    self lock acquire.
    value := self write.
    self lock release.
    ^ value

hash
    ^ self hashFromSync
        bitAnd: self hashFromStream
```

*Descripción: diagrama UML extendido. La clase `SyncStream` (caja con dos compartimientos: la variable `lock` arriba; los métodos `lock`, `lock:`, `isBusy` y `hash` abajo) usa dos traits mediante flechas de doble punta abierta. La flecha hacia `TSyncReadWrite` lleva el alias `@{hashFromSync -> hash}`; la flecha hacia `TStream` lleva `@{hashFromStream -> hash}`. `TSyncReadWrite` provee `syncRead`, `syncWrite` y `hash`, y requiere (en itálica) `read`, `write`, `lock:` y `lock`. `TStream` provee `read`, `write` y `hash`, sin requeridos. Los cuerpos de `syncRead`, `syncWrite` y `hash` (de `SyncStream`) cuelgan como notas.*

> En la Figura 1, el trait `TSyncReadWrite` provee los métodos `syncRead`, `syncWrite` y `hash`. Requiere los métodos `read` y `write`, y los dos accessors `lock` y `lock:`. Usamos una extensión de UML para representar traits (la columna derecha lista los métodos requeridos, mientras que la izquierda lista los provistos).

### 2.2 Componer clases a partir de mixins

La siguiente ecuación muestra cómo se construye una clase con traits:

*class = superclass + state + trait composition + glue code*

Una clase se especifica a partir de una superclase, una definición de estado, un conjunto de traits y algunos *glue methods* (métodos pegamento). Los glue methods se definen en la clase y conectan los traits entre sí; es decir, implementan métodos requeridos de los traits (a menudo para acceder al estado), adaptan métodos provistos por los traits y resuelven conflictos de métodos.

> En la Figura 1, la clase `SyncStream` define el campo `lock` y los glue methods `lock`, `lock:`, `isBusy` y `hash`. Los otros métodos requeridos de `TSyncReadWrite`, `read` y `write`, también quedan provistos porque la clase `SyncStream` usa otro trait, `TStream`, que los provee.

La composición de traits respeta las tres reglas siguientes:

- Los métodos definidos en la clase tienen precedencia sobre los métodos de los traits. Esto permite que los glue methods definidos en una clase sobrescriban métodos con el mismo nombre provistos por los traits usados.
- Propiedad de aplanamiento (flattening). Un método de un trait que no fue sobrescrito tiene la misma semántica que si estuviera implementado directamente en la clase que usa el trait.
- El orden de composición es irrelevante. Todos los traits tienen la misma precedencia y, por lo tanto, los métodos de traits en conflicto deben desambiguarse explícitamente.

Con este enfoque, las clases conservan su rol primario de generadoras de instancias, mientras que los traits son unidades de reuso puramente conductuales. Como con los mixins, las clases se organizan en una jerarquía de herencia simple, evitando así los problemas centrales de la herencia múltiple, pero las extensiones incrementales que las clases introducen sobre sus superclases se especifican mediante uno o más traits. A diferencia de los mixins, varios traits pueden aplicarse a una clase en una sola operación: la composición de traits no tiene orden. En lugar de que la composición resulte implícitamente del orden en que se componen los traits (como pasa con los mixins), queda totalmente bajo el control de la clase que compone.

### 2.3 Resolución de conflictos

Al componer traits pueden surgir conflictos de métodos. Un conflicto surge si combinamos dos o más traits que proveen métodos con el mismo nombre que no se originan en el mismo trait. Los conflictos se resuelven implementando, a nivel de la clase, un método que sobrescriba a los métodos en conflicto, o excluyendo el método de todos los traits salvo uno. Además, los traits permiten el aliasing de métodos, que le permite al programador introducir un nombre adicional para un método provisto por un trait. El nombre nuevo se usa para obtener acceso a un método que de otro modo quedaría inalcanzable por haber sido sobrescrito [DNS+06].

> En la Figura 1, `SyncStream` usa métodos de `TSyncReadWrite` y de `TStream`. La composición de traits asociada a `SyncStream` es:
>
> `TSyncReadWrite@{hashFromSync → hash} + TStream@{hashFromStream → hash}`
>
> Esto significa que `SyncStream` se compone de (i) el trait `TSyncReadWrite`, para el cual el método `hash` recibe el alias `hashFromSync`, y (ii) el trait `TStream`, para el cual el método `hash` recibe el alias `hashFromStream`.

### 2.4 Operadores de composición de métodos

La semántica de la composición de traits se basa en cuatro operadores: suma, sobrescritura (overriding), exclusión y aliasing [DNS+06].

El trait suma `TSyncReadWrite + TStream` contiene todos los métodos no conflictivos de `TSyncReadWrite` y `TStream`. Si hay un conflicto de métodos —es decir, si `TSyncReadWrite` y `TStream` definen ambos un método con el mismo nombre—, entonces en `TSyncReadWrite + TStream` ese nombre queda ligado a un método de conflicto distinguido. El operador `+` es asociativo y conmutativo.

El operador de sobrescritura construye un nuevo trait de composición extendiendo una composición de traits existente con algunas definiciones locales explícitas. Por ejemplo, `SyncStream` sobrescribe el método `hash` obtenido de su composición de traits. Esto también puede hacerse con métodos, como discutiremos en más detalle más adelante.

Un trait puede construirse excluyendo métodos de un trait existente con el operador de exclusión `−`. Así, por ejemplo, `TStream − {read, write}` tiene un único método, `hash`. La exclusión se usa para evitar conflictos, o cuando uno necesita reutilizar un trait que resulta "demasiado grande" para su aplicación.

El operador de aliasing de métodos `@` crea un nuevo trait proveyendo un nombre adicional para un método existente. Por ejemplo, si `TStream` es un trait que define `read`, `write` y `hash`, entonces `TStream @ {hashFromStream → hash}` es un trait que define `read`, `write`, `hash` y `hashFromStream`. El método adicional `hashFromStream` tiene el mismo cuerpo que el método `hash`. Los alias se usan para hacer que métodos en conflicto queden disponibles bajo otro nombre, quizás para satisfacer los requisitos de algún otro trait, o para evitar una sobrescritura. Nótese que, como el cuerpo del método con alias no se modifica en absoluto, un alias a un método recursivo no es recursivo.

## 3 Limitaciones de los traits stateless

Los traits soportan el reuso de grupos coherentes de métodos por parte de clases que, por lo demás, son independientes [DNS+06]. Los traits pueden componerse a partir de otros traits. En consecuencia, sirven bien como medio para estructurar código. Lamentablemente, los traits stateless codifican por necesidad la dependencia del estado en términos de métodos requeridos (es decir, accessors). En esencia, los traits están necesariamente incompletos, porque prácticamente cualquier trait útil se verá forzado a definir accessors requeridos. Esto significa que la clase que compone debe definir las variables de instancia y los accessors faltantes.

La incompletitud de los traits deriva en una serie de limitaciones molestas, a saber: (i) la reusabilidad del trait se ve afectada porque la interfaz requerida queda típicamente saturada de accessors requeridos sin interés, (ii) las clases cliente se ven forzadas a implementar glue code repetitivo, (iii) la introducción de estado nuevo en un trait propaga accessors requeridos a todas las clases cliente, y (iv) los accessors públicos rompen el encapsulamiento de la clase cliente.

Aunque estas molestias pueden abordarse en gran medida con buen soporte de herramientas, empañan el atractivo de los traits como mecanismo limpio y liviano para componer clases a partir de componentes reutilizables. Entender bien estas limitaciones es un prerrequisito para considerar cualquier propuesta de un enfoque más general.

### 3.1 Reusabilidad limitada

El hecho de que un trait stateless esté forzado a codificar el estado en términos de accessors requeridos significa que no puede componerse "off-the-shelf" (listo para usar) sin alguna acción adicional. Prácticamente todo trait útil está incompleto, aun cuando la parte faltante pueda completarse trivialmente.

Lo peor, sin embargo, es que la interfaz requerida de un trait queda saturada de dependencias de accessors requeridos sin interés, en lugar de concentrar la atención en los hook methods (métodos gancho) no triviales que los clientes sí deben implementar.

**Fig. 2.** La variable `lock` y los métodos `lock` y `lock:` están duplicados entre los usuarios del trait `TSyncReadWrite`.

```
                       ┌─────────────────────────────┐
                       │        TSyncReadWrite       │
                       │  provided     │  required   │
                       ├───────────────┼─────────────┤
                       │ initialize    │ read        │
                       │ syncRead      │ write       │
                       │ syncWrite     │ lock:       │
                       │               │ lock        │
                       └───────────────┴─────────────┘
                          △△          △△          △△
                          │           │           │
                ┌─────────┴──┐ ┌──────┴─────┐ ┌───┴────────┐
                │  SyncFile  │ │ SyncStream │ │ SyncSocket │
                ├────────────┤ ├────────────┤ ├────────────┤
                │ ▓ lock     │ │ ▓ lock     │ │ ▓ lock     │
                ├────────────┤ ├────────────┤ ├────────────┤
                │ ▓ lock:    │ │ ▓ lock:    │ │ ▓ lock:    │
                │ ▓ lock     │ │ ▓ lock     │ │ ▓ lock     │
                │ read       │ │ read       │ │ read       │
                │ write      │ │ write      │ │ write      │
                └────────────┘ └────────────┘ └────────────┘

 Leyenda del original:  ▓ (sombreado gris) = "Duplicated code"
                        flecha con doble punta abierta = "Use of trait"
```

![Figura 2 — diagrama original](fuente-berg07a-stateful-traits-fig2.png)

Cuerpos de métodos adjuntos como notas en la figura:

```smalltalk
initialize
    super initialize.
    self lock: Lock new

syncRead
    | value |
    self lock acquire.
    value := self read.
    self lock release.
    ^ value

syncWrite
    | value |
    self lock acquire.
    value := self write.
    self lock release.
    ^ value
```

*Descripción: el trait `TSyncReadWrite` provee `initialize`, `syncRead` y `syncWrite`, y requiere `read`, `write`, `lock:` y `lock`. Tres clases lo usan: `SyncFile`, `SyncStream` y `SyncSocket`. En cada una, la variable `lock` (compartimiento superior) y los métodos `lock:` y `lock` aparecen sombreados en gris como código duplicado; `read` y `write` no están sombreados. Los cuerpos de `initialize`, `syncRead` y `syncWrite` cuelgan como notas del trait.*

Aunque este problema puede aliviarse parcialmente con soporte de herramientas que distinga los accessors requeridos sin interés de los demás métodos requeridos, el hecho es que los traits con accessors requeridos nunca pueden reutilizarse off-the-shelf sin una acción adicional de la clase cliente final.

### 3.2 Glue code repetitivo

La acción adicional necesaria del cliente consiste esencialmente en generar glue code repetitivo (boilerplate) para inyectar las variables de instancia, los accessors y el código de inicialización faltantes. Claramente, este código repetitivo debe generarse para todas y cada una de las clases cliente. En el enfoque más directo, esto lleva al tipo de código duplicado que los traits pretendían evitar.

La Figura 2 ilustra una situación de este tipo, donde el trait `TSyncReadWrite` necesita acceder a un lock. Esta variable `lock`, el accessor `lock` y el mutador `lock:` tienen que duplicarse en `SyncFile`, `SyncStream` y `SyncSocket`.

Una vez más, para evitar esta situación haría falta soporte de herramientas (i) para generar automáticamente las variables de instancia y los accessors requeridos, y (ii) para generar el código de forma tal de evitar la duplicación efectiva.

Otro efecto secundario desagradable de la necesidad de glue code repetitivo es la aparición de "shell classes": clases que consisten en nada más que glue code. En la jerarquía de Smalltalk refactorizada con traits stateless [BSD03], observamos que el 24% (7 de 29) de las clases de la jerarquía refactorizada con traits son shell classes puras.

### 3.3 Propagación de accessors requeridos

Si la implementación de un trait evoluciona y requiere variables nuevas, puede impactar a todas las clases que lo usan, aunque la interfaz quede intacta. Por ejemplo, si la implementación del trait `TSyncReadWrite` evoluciona y requiere una nueva variable `numberWaiting`, pensada para dar el número de clientes que esperan el lock, entonces todas las clases que usan este trait se ven impactadas, aun cuando la interfaz pública no cambie.

Los accessors requeridos se propagan y se acumulan de trait en trait; por lo tanto, cuando una clase se compone de traits profundamente compuestos, puede haber que resolver un gran número de accessors. Cuando se introduce una nueva dependencia de estado en un trait profundamente anidado, los accessors requeridos pueden propagarse a un gran número de clases cliente. De nuevo, un buen soporte de herramientas puede mitigar en gran medida las consecuencias de estos cambios, pero sería bienvenida una solución más satisfactoria.

### 3.4 Violación del encapsulamiento

Los traits stateless violan el encapsulamiento de dos maneras. En primer lugar, exponen innecesariamente información sobre su representación interna, ensuciando su interfaz. Un trait stateless expone cada parte de la representación que necesita como un accessor requerido, aunque esa información no tenga ningún interés para sus clientes. El encapsulamiento estaría mejor servido si los traits se parecieran más a las clases abstractas, donde solo los métodos abstractos se declaran explícitamente como responsabilidad de la subclase cliente. Por la misma razón, una clase cliente que usa un trait debería ver solo aquellos métodos requeridos que son genuinamente su responsabilidad implementar, y ningún otro.

La segunda violación tiene que ver con la visibilidad. En Smalltalk, las variables de instancia son siempre privadas. Puede concederse acceso a otros objetos proveyendo accessors públicos. Pero si los traits requieren accessors, entonces las clases que usan esos traits deben proveer accessors públicos para el estado faltante, aunque no se desee.

En principio, este problema podría mitigarse un poco en los lenguajes tipo Java incluyendo modificadores de visibilidad para los traits stateless. Un trait podría entonces requerir un accessor privado o protegido para el estado faltante. La clase cliente podría proveer esos accessors sin violar el encapsulamiento (y, opcionalmente, relajar el modificador requerido). Esta solución, sin embargo, no resolvería el problema en los lenguajes tipo Smalltalk, donde todos los métodos son públicos y solo pueden marcarse como "privados" por convención (es decir, poniéndolos en una categoría llamada "private").

## 4 Traits stateful: reconciliar traits y estado

Presentamos ahora los traits stateful como nuestra solución a las limitaciones de los traits stateless. Aunque podría parecer que agregar variables de instancia a los traits es una extensión trivial, en realidad hay una serie de cuestiones que deben resolverse. En resumen, nuestra solución atiende las siguientes preocupaciones:

- Los traits stateless deberían ser un caso especial de los traits stateful. La semántica original de los traits stateless (y las ventajas de esa solución) no debería verse afectada.
- Cualquier extensión debería ser sintáctica y semánticamente mínima. Buscamos una solución simple.
- Deberíamos atender las limitaciones listadas en la Sección 3. En particular, debería ser posible expresar traits completos. Solo los métodos que son conceptualmente responsabilidad de las clases cliente deberían listarse como métodos requeridos.
- La solución debería ofrecer una semántica por defecto razonable para el uso de traits, habilitando así el uso black-box (caja negra).
- En consonancia con el principio rector de los traits stateless, la clase cliente debería conservar el control de la composición y, en particular, de la política de resolución de conflictos. Por lo tanto, también se soporta cierto grado de uso white-box (caja blanca), donde haga falta.
- Como con los traits stateless, buscamos evitar la fragilidad frente al cambio. Los cambios en la representación de un trait normalmente no deberían afectar a sus clientes.
- La solución debería ser, en gran medida, independiente del lenguaje. No dependemos de características oscuras o exóticas del lenguaje, así que el enfoque debería poder aplicarse con facilidad a la mayoría de los lenguajes orientados a objetos.

La solución que presentamos extiende los traits para que puedan incluir variables de instancia. En pocas palabras, nuestro enfoque tiene tres aspectos:

1. Las variables de instancia son, por defecto, privadas del scope del trait que las define.
2. El cliente de un trait —es decir, una clase o un trait compuesto— puede acceder a variables seleccionadas de ese trait, mapeándolas a nombres posiblemente nuevos. Los nombres nuevos son privados del scope del cliente.
3. El cliente de un trait compuesto puede fusionar variables de los traits que usa mapeándolas a un nombre común. El nombre nuevo es privado del scope del cliente.

En las subsecciones siguientes damos los detalles del modelo de traits stateful.

### 4.1 Definición de un trait stateful

Un trait stateful extiende un trait stateless incluyendo variables de instancia privadas. Un trait stateful consiste, por lo tanto, en un grupo de métodos públicos y variables de instancia privadas, y posiblemente una especificación de algunos métodos requeridos adicionales que los clientes deben implementar.

**Métodos.** Los métodos definidos en un trait son visibles para cualquier otro trait con el que se lo componga. Como los métodos son públicos, pueden ocurrir conflictos al componer traits. Los conflictos de métodos en los traits stateful se resuelven de la misma manera que en los traits stateless.

**Variables.** Por defecto, las variables son privadas del trait que las define. Como las variables son privadas, no pueden ocurrir conflictos entre variables al componer traits. Si, por ejemplo, los traits `T1` y `T2` definen cada uno una variable `x`, la composición `T1 + T2` no produce un conflicto de variables. Las variables solo son visibles para el trait que las define, salvo que el trait o la clase cliente que realiza la composición amplíe el acceso con el operador de acceso a variables `@@`.

**Fig. 3.** La clase `SyncStream` se compone de los traits stateful `TStream` y `TSyncReadWrite`.

```
 ┌────────────────────────────┐          ┌──────────────────────┐
 │       TSyncReadWrite       │          │       TStream        │
 │ lock                       │          │ provided │ required  │
 ├───────────────┬────────────┤          ├──────────┼───────────┤
 │  provided     │  required  │          │ read     │           │
 │ initialize    │ read       │          │ write    │           │
 │ syncRead      │ write      │          │ hash     │           │
 │ syncWrite     │            │          └──────────┴───────────┘
 │ hash          │            │                    △△
 └───────────────┴────────────┘                    │
              △△                                   │
              │  @{hashFromSync -> hash}           │  @{hashFromStream -> hash}
              │  @@{syncLock -> lock}              │
              │                                    │
              └───────────────┬────────────────────┘
                              │
                      ┌───────┴──────┐
                      │  SyncStream  │
                      ├──────────────┤
                      │ isBusy       │
                      │ hash         │
                      └──────────────┘

 Leyenda del original:  [Trait Name | provided methods | required methods]
                        flecha con doble punta abierta (△△) = "Uses trait"
```

![Figura 3 — diagrama original](fuente-berg07a-stateful-traits-fig3.png)

Cuerpos de métodos adjuntos como notas en la figura:

```smalltalk
initialize
    super initialize.
    lock := Lock new

syncRead
    | value |
    lock acquire.
    value := self read.
    lock release.
    ^ value

syncWrite
    | value |
    lock acquire.
    value := self write.
    lock release.
    ^ value

isBusy
    ^ syncLock isAcquired

hash
    ^ self hashFromSync
        bitAnd: self hashFromStream
```

*Descripción: reimplementación de la Fig. 1 con traits stateful. `TSyncReadWrite` ahora tiene un compartimiento de variables con `lock`; provee `initialize`, `syncRead`, `syncWrite` y `hash`, y requiere solo `read` y `write` (desaparecen los accessors requeridos `lock`/`lock:`). La clase `SyncStream` queda sin variables y define solo `isBusy` y `hash`. La flecha hacia `TSyncReadWrite` lleva dos etiquetas: el alias de método `@{hashFromSync -> hash}` y, debajo y en negrita itálica en el original, el operador de acceso a variable `@@{syncLock -> lock}`. La flecha hacia `TStream` lleva `@{hashFromStream -> hash}`. Los cuerpos de método usan la variable directamente (`lock acquire.`) en vez de `self lock acquire.`; `isBusy` de `SyncStream` accede a la variable del trait bajo el nombre `syncLock`.*

La Figura 3 muestra cómo la situación presentada en la Figura 1 se reimplementa usando traits stateful. La clase `SyncStream` se compone de los traits `TStream` y `TSyncReadWrite`. El trait `TSyncReadWrite` define la variable `lock`, tres métodos `syncRead`, `syncWrite` y `hash`, y requiere los métodos `read` y `write`.

Nótese que, para incluir estado en los traits, tenemos que extender el mecanismo de definición de traits. En la implementación de Smalltalk, esto se logra extendiendo el mensaje enviado a la clase `Trait` con un nuevo argumento de palabra clave que representa las variables de instancia usadas. Por ejemplo, ahora podemos definir el trait `TSyncReadWrite` así:

```smalltalk
Trait named: #TSyncReadWrite
    uses: {}
    instVarNames: 'lock'
```

El trait `TSyncReadWrite` no se compone de ningún otro trait y define una variable `lock`. La cláusula `uses:` especifica la composición de traits (vacía en este caso), e `instVarNames:` lista las variables definidas en el trait (es decir, la variable `lock`). La interfaz para definir una clase como composición de traits es la misma que con los traits stateless. La única diferencia es que la expresión de composición de traits soporta un operador adicional (`@@`) para conceder acceso a variables de los traits usados. Acá vemos cómo `SyncStream` se compone a partir de los traits `TSyncReadWrite` y `TStream`:

```smalltalk
Object subclass: #SyncStream
    uses: TSyncReadWrite @ {#hashFromSync → #hash}
            @@ {syncLock → lock}
        + TStream @ {#hashFromStream → #hash}
    instVarNames: ''
    ....
```

En este ejemplo, se concede acceso a la variable `lock` del trait `TSyncReadWrite` bajo el nuevo nombre `syncLock`. Como veremos a continuación, el operador `@@` brinda un grado fino de control sobre la visibilidad de las variables de los traits.

### 4.2 Acceso a variables

Por defecto, una variable es privada del trait que la define. Sin embargo, el operador de acceso a variables (`@@`) permite que las variables sean *accedidas* desde los clientes bajo un nombre posiblemente nuevo, y posiblemente *fusionadas* con otras variables.

Si `T` es un trait que define una variable de instancia (privada) `x`, entonces `T@@{y → x}` representa un nuevo trait en el que la variable `x` puede accederse desde el scope de su cliente bajo el nombre `y`. `x` e `y` representan la misma variable, pero el nombre `x` queda restringido al scope de `T`, mientras que el nombre `y` es visible en el scope del cliente que lo engloba (es decir, el scope de la clase que realiza la composición). Por ejemplo, en la siguiente composición:

`TSyncReadWrite@{hashFromSync → hash} @@{syncLock → lock}`

la variable `lock` definida en `TSyncReadWrite` queda accesible, bajo el nombre `syncLock`, para la clase `SyncStream` que usa ese trait. (Nótese que a menudo el renombre es necesario para distinguir variables de nombre similar que vienen de distintos traits usados.)

En una composición de variables de traits pueden darse tres situaciones: (i) las variables permanecen privadas (es decir, no se usa el operador de acceso a variables), (ii) se concede acceso a una variable privada, y (iii) las variables se fusionan.

**Fig. 4.** Variables que se mantienen privadas: al componerse, las variables quedan separadas. Los traits `T1`, `T2` y `C` tienen cada uno su propia variable `x`.

```
                                 ┌───────────────────────┐
                                 │          T1           │
                                 │ x                     │
               ┌──────────────▷▷├───────────┬───────────┤
               │                 │ getXT1    │           │
 ┌──────────┐  │                 │ setXT1:   │           │
 │    C     │  │                 └───────────┴───────────┘
 │ x        │──┤
 ├──────────┤  │                 ┌───────────────────────┐
 │ getX     │  │                 │          T2           │
 │ setX:    │  │                 │ x                     │
 └──────────┘  └──────────────▷▷├───────────┬───────────┤
                                 │ getXT2    │           │
                                 │ setXT2:   │           │
                                 └───────────┴───────────┘
```

![Figura 4 — diagrama original](fuente-berg07a-stateful-traits-fig4.png)

Nota de uso adjunta en la figura:

```
c := C new.
c setXT1: 1.
c setXT2: 2.
c setX: 3.

{ Now:
  c getXT1 = 1
  c getXT2 = 2
  c getX = 3 }
```

*Descripción: la clase `C` define su propia variable `x` y los métodos `getX` y `setX:`, y usa los traits `T1` y `T2` sin etiquetas en las flechas (sin operador de acceso a variables). `T1` define la variable `x` y los métodos `getXT1` y `setXT1:`; `T2` define la variable `x` y los métodos `getXT2` y `setXT2:`. La nota muestra que las tres variables `x` quedan separadas: asignar 1, 2 y 3 por cada vía devuelve 1, 2 y 3 respectivamente.*

**Mantener las variables privadas.** Por defecto, las variables de instancia son privadas de su trait. Si el scope de las variables no se amplía en el momento de la composición usando el operador de acceso a variables, no ocurren conflictos y los traits no comparten estado. La Figura 4 muestra un caso donde `T1` y `T2` se componen sin ampliar el acceso a variables. Cada uno de estos dos traits define una variable `x`. Además, cada uno define accessors. `C` también define una variable `x` y dos métodos, `getX` y `setX:`. `T1`, `T2` y `C` tienen cada uno su propia variable `x`, como muestra la Figura 4.

La composición de traits de `C` es: `T1 + T2`. Nótese que, si los métodos entraran en conflicto, usaríamos la estrategia por defecto de los traits para resolverlos, redefiniéndolos localmente en `C`, y que el aliasing de métodos podría usarse para acceder a los métodos sobrescritos.

Esta forma de composición es cercana al enfoque de composición de módulos propuesto en Jigsaw [Bra92] y soporta un escenario de reuso black-box.

**Fig. 5.** Concesión de acceso a variables: se da acceso en `C` a la `x` de `T1` y a la de `T2`.

```
                  @@{ xFromT1 -> x }  ┌───────────────────────┐
               ┌────────────────────▷▷│          T1           │
               │                      │ x                     │
 ┌──────────┐  │                      ├───────────┬───────────┤
 │    C     │  │                      │ getXT1    │           │
 ├──────────┤──┤                      │ setXT1:   │           │
 │ sum      │  │                      └───────────┴───────────┘
 └──────────┘  │
               │  @@{ xFromT2 -> x }  ┌───────────────────────┐
               └────────────────────▷▷│          T2           │
                                      │ x                     │
                                      ├───────────┬───────────┤
                                      │ getXT2    │           │
                                      │ setXT2:   │           │
                                      └───────────┴───────────┘
```

![Figura 5 — diagrama original](fuente-berg07a-stateful-traits-fig5.png)

Notas adjuntas en la figura:

```smalltalk
sum
    ^ xFromT1 + xFromT2
```

```
c := C new.
c setXT1: 1.
c setXT2: 2.

{ Now:
  c getXT1 = 1
  c getXT2 = 2
  c sum = 3 }
```

*Descripción: la clase `C` define el método `sum` y usa `T1` con la etiqueta `@@{ xFromT1 -> x }` y `T2` con `@@{ xFromT2 -> x }`: la variable privada `x` de cada trait queda accesible en `C` bajo los nombres `xFromT1` y `xFromT2`. El cuerpo de `sum` devuelve `xFromT1 + xFromT2`. La nota de uso muestra que tras asignar 1 y 2 por los setters de los traits, `sum` devuelve 3.*

**Conceder acceso a variables.** La Figura 5 muestra cómo la clase cliente `C` obtiene acceso a las variables privadas `x` de los traits `T1` y `T2` usando el operador de acceso a variables `@@`. Como dos variables no pueden tener el mismo nombre dentro de un mismo scope, estas variables tienen que renombrarse. La variable `x` de `T1` queda accesible como `xFromT1`, y la `x` de `T2`, como `xFromT2`. `C` también define un método `sum` que devuelve el valor `xFromT1 + xFromT2`. La composición de traits de `C` es:

```
T1 @@ {xFromT1 → x}
+ T2 @@ {xFromT2 → x}
```

`C` puede así construir funcionalidad por encima de los traits que usa, sin exponer ningún detalle hacia afuera. Nótese que los métodos del trait siguen usando el nombre 'interno' de la variable, tal como está definido en el trait. El nombre dado en el operador de acceso a variables `@@` es solo para uso de las clases cliente. Esto es similar al operador de aliasing de métodos `@`.

**Fusionar variables.** Las variables de varios traits pueden fusionarse al componerlos, usando el operador de acceso a variables para mapear múltiples variables a un *nombre común* dentro del scope del cliente. Esto se ilustra en la Figura 6.

Tanto `T1` como `T2` dan acceso a sus variables de instancia `x` e `y` bajo el nombre `w`. Esto significa que `w` se comparte entre los tres traits. Por eso, enviar `getX`, `getY` o `getW` a una instancia de una clase que implementa `C` devuelve el mismo resultado, 3. La composición de traits de `C` es:

**Fig. 6.** Fusión de variables: las variables `x` e `y` se fusionan en `C` bajo el nombre `w`.

```
                  @@{w -> x}          ┌───────────────────────┐
               ┌────────────────────▷▷│          T1           │
               │                      │ x                     │
 ┌──────────┐  │                      ├───────────┬───────────┤
 │    C     │  │                      │ getX      │           │
 ├──────────┤──┤                      │ setX:     │           │
 │ getW     │  │                      └───────────┴───────────┘
 │ setW:    │  │
 └──────────┘  │  @@{w -> y}          ┌───────────────────────┐
               └────────────────────▷▷│          T2           │
                                      │ y                     │
                                      ├───────────┬───────────┤
                                      │ getY      │           │
                                      │ setY:     │           │
                                      └───────────┴───────────┘
```

![Figura 6 — diagrama original](fuente-berg07a-stateful-traits-fig6.png)

Nota de uso adjunta en la figura:

```
c := C new.
c setW: 3.

{ Now:
  c getX = 3
  c getY = 3
  c getW = 3 }
```

*Descripción: la clase `C` define `getW` y `setW:` y usa `T1` con la etiqueta `@@{w -> x}` y `T2` con `@@{w -> y}`: la variable `x` de `T1` y la variable `y` de `T2` se fusionan bajo el nombre común `w` en el scope de `C`. La nota de uso muestra que tras `c setW: 3`, los tres getters (`getX`, `getY`, `getW`) devuelven 3.*

`T1 @@ {w → x} + T2 @@ {w → y}`

Nótese que la fusión está *totalmente* bajo el control de la clase o trait cliente. No puede haber captura accidental de nombres, porque la visibilidad de las variables de instancia nunca se propaga a un scope englobante. Los conflictos de nombres de variables no pueden surgir, ya que las variables son privadas de los traits salvo que los clientes las accedan explícitamente, y las variables se fusionan cuando se las mapea a nombres comunes.

El lector bien podría preguntarse: ¿qué pasa si el cliente también define una variable de instancia cuyo nombre coincide con el nombre bajo el cual se accede a la variable de un trait usado? Supongamos, por ejemplo, que `C` en la Figura 6 intenta definir, además, una variable de instancia llamada `w`. Consideramos que esto es un error. Esta situación no puede surgir como efecto secundario de cambiar la definición de un trait usado, porque el cliente tiene control total sobre los nombres de las variables de instancia accesibles dentro de su scope. En consecuencia, no puede tratarse de una captura accidental de nombres, y solo puede interpretarse como un error.

### 4.3 Los requisitos, revisados

Reconsideremos brevemente nuestros requisitos. Primero, los traits stateful no cambian la semántica de los traits stateless. Los traits stateless son, sencillamente, un caso especial de los traits stateful. Sintáctica y semánticamente, los traits stateful representan solo una extensión menor de los traits stateless.

Los traits stateful atienden los problemas planteados en la Sección 3. En particular, (i) ya no hace falta saturar las interfaces de los traits con accessors requeridos, (ii) los clientes ya no necesitan proveer variables de instancia y accessors repetitivos, (iii) la introducción de estado en un trait queda privada de ese trait, y (iv) no hace falta introducir accessors públicos en las clases cliente. En consecuencia, es posible definir traits "completos" que no requieren ningún método, aun cuando hagan uso de estado.

La semántica por defecto de los traits stateful habilita el uso black-box, ya que no se expone ninguna representación, y las variables de instancia, por defecto, no pueden chocar con las del cliente ni con las de otros traits usados. No obstante, el cliente conserva el control de la composición y puede obtener acceso a las variables de instancia de los traits usados. En particular, el cliente puede fusionar variables de traits, si así lo desea.

Como el cliente conserva el control total de la composición, los cambios en la definición de un trait no pueden propagarse más allá de sus clientes directos. No puede haber efectos secundarios implícitos.

Por último, el enfoque es, en gran medida, independiente del lenguaje. En particular, no se asume que el lenguaje anfitrión provea modificadores de acceso para las variables de instancia ni mecanismos exóticos de scope.

## 5 Implementación

Hemos implementado un prototipo de traits stateful como extensión de nuestra implementación de traits stateless basada en Smalltalk.[^5]

[^5]: Ver [www.iam.unibe.ch/~scg/Research/Traits](http://www.iam.unibe.ch/~scg/Research/Traits)

Como con los traits stateless, la composición y el reuso de métodos en los traits stateful no incurren en ningún costo adicional, porque los punteros a métodos se comparten entre los diccionarios de métodos de distintos traits y clases. Esto aprovecha el hecho de que los métodos se buscan por nombre en el diccionario, en lugar de accederse por índice y offset (desplazamiento), como se hace para acceder al estado en la mayoría de los lenguajes orientados a objetos. Sin embargo, al agregar estado a los traits, tenemos que resolver el hecho de que el acceso a las variables de instancia no puede ser lineal (es decir, basado en offsets), porque los mismos métodos de un trait pueden aplicarse a objetos distintos [BGG+02]. No siempre puede obtenerse una estructura lineal de representación del estado a partir de un grafo de composición. Este es un problema común de los lenguajes que soportan herencia múltiple. Evaluamos dos implementaciones: copy-down y cambiar la representación interna de los objetos. La sección siguiente ilustra el problema.

### 5.1 El problema clásico de la linealización del estado

Como señaló Bracha [Bra92, Capítulo 7], en las implementaciones de lenguajes de herencia simple como Modula-3 [CDG+92], y más recientemente en la Jikes Research Virtual Machine [Jik], la noción de funciones virtuales se soporta asociando a cada clase una tabla cuyas entradas son las direcciones de los métodos definidos para las instancias de esa clase. Cada instancia de una clase contiene una referencia a la tabla de métodos de la clase. Es a través de esta referencia que se localiza el método apropiado a invocar sobre una instancia. Bajo herencia múltiple, esta técnica debe modificarse, porque las superclases de una clase ya no comparten un prefijo común.

Como un trait stateful puede tener estado privado y puede usarse en múltiples contextos, no es posible tener una lista de offsets de variables de instancia estática y lineal, compartida por todos los métodos del trait y sus usuarios.

**Fig. 7.** El problema de combinar múltiples traits: el offset de la variable no se preserva.

```
 Modelo:
   ┌─────────────────────┐               ┌────────┐
   │         T1          │ ◁◁─────────── │   T3   │
   │ x, y, z             │               └────────┘
   ├─────────┬───────────┤
   │ getX    │           │ ◁◁────┐
   └─────────┴───────────┘       │       ┌────────┐
                                 ├────── │   T4   │
   ┌─────────────────────┐       │       └────────┘
   │         T2          │ ◁◁────┘
   │ v, x                │
   ├─────────┬───────────┤
   │ getV    │           │
   └─────────┴───────────┘

 Memory layout:                                      Variable
    T1        T2        T3        T4                 offsets
 ┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐
 │ T1.x  │ │ T2.v  │ │ T1.x  │ │ T1.x  │                0
 │ T1.y  │ │ T2.x  │ │ T1.y  │ │ T1.y  │                1
 │ T1.z  │ └───────┘ │ T1.z  │ │ T1.z  │                2
 └───────┘           └───────┘ │ T2.v  │                3
                               │ T2.x  │                4
                               └───────┘
```

![Figura 7 — diagrama original](fuente-berg07a-stateful-traits-fig7.png)

Cuerpos de métodos adjuntos como notas en la figura:

```smalltalk
getX
    ^ x

getV
    ^ v
```

*Descripción: arriba, el modelo: el trait `T1` define las variables `x`, `y`, `z` y el método `getX` (`^ x`); el trait `T2` define `v`, `x` y el método `getV` (`^ v`). `T3` usa `T1`; `T4` usa `T1` y `T2`. Abajo, el layout de memoria por offsets de cada trait: `T1` = [T1.x, T1.y, T1.z]; `T2` = [T2.v, T2.x] (resaltadas en negrita en el original); `T3` = [T1.x, T1.y, T1.z]; `T4` = [T1.x, T1.y, T1.z, T2.v, T2.x], con la columna de offsets 0–4 al costado: en `T2`, `T2.v` tiene offset 0, pero en `T4` pasa a offset 3 — el offset de la variable no se preserva.*

La mitad superior de la Figura 7 muestra un trait `T3` que usa `T1` y un trait `T4` que usa `T1` y `T2`. `T1` define 3 variables `x`, `y`, `z`, y `T2` define 2 variables `v`, `x`. La parte inferior muestra una posible representación correspondiente en memoria que usa offsets. Suponiendo que empezamos a indexar desde cero, `T2.v` tiene índice cero y `T2.x` tiene uno. Sin embargo, en `T4` las mismas dos variables podrían tener índices tres y cuatro.[^6] Así que los índices estáticos usados en los métodos de `T1` o `T2` ya no son válidos. Nótese que este problema ocurre sin importar cómo se componga el trait `T4` a partir de los traits `T1` y `T2` (necesite o no acceso a variables, fusione o no la variable `x`, …). El problema se debe a la representación lineal de las variables en el modelo de objetos subyacente.

[^6]: Suponemos que los slots de `T2` se agregan después de los de `T1`. En el caso contrario, el argumento vale para las variables de `T1`.

### 5.2 Tres enfoques para la linealización del estado

Hay tres enfoques disponibles para representar estado no lineal. C++ usa punteros intra-objeto [SG99]. Strongtalk [BGG+02] usa una técnica de *copy-down* que duplica los métodos que necesitan acceder a variables con offsets distintos. Un tercer enfoque, como hace Python [Pyt] por ejemplo, es mantener las variables en un diccionario y buscarlas ahí, de manera similar a lo que se hace con los métodos.

Implementamos los últimos dos enfoques para Smalltalk, de modo de poder compararlos para nuestra implementación prototipo. No implementamos la solución de C++ porque habría exigido un esfuerzo significativo cambiar la representación de los objetos para hacerla compatible.

### 5.3 Virtual base pointers en C++

En C++ [SE90], una instancia de una clase *C* se representa concatenando las representaciones de las superclases de *C*. Una instancia así queda compuesta de *subobjetos*, donde cada *subobjeto* corresponde a una *superclase* particular. Cada subobjeto tiene su propio puntero a una tabla de métodos adecuada. En este caso, la representación de una clase no es un prefijo de las representaciones de todas sus subclases.

Cada subobjeto comienza en un offset distinto desde el principio del objeto *C* completo. Estos offsets, llamados *virtual base pointers* (punteros a base virtual) [SG99], pueden computarse estáticamente. La técnica fue pionera de Krogdahl [Kro85, Bra92].

Por ejemplo, consideremos la situación en C++ ilustrada en la Figura 8. La parte superior de la figura muestra un diagrama de diamante clásico usando herencia virtual (es decir, `B` y `C` heredan virtualmente de `A`, por lo que la variable `w` se comparte entre `B` y `C`). La parte inferior muestra el layout de memoria de una instancia de `D`. Esta instancia se compone de 4 "sub-partes" que corresponden a las superclases `A`, `B`, `C` y `D`. Nótese que la parte de `C`, en lugar de asumir que el estado que hereda de `A` está inmediatamente "encima" del suyo, accede al estado heredado a través del virtual base pointer. De esta forma, las partes `B` y `C` de la instancia de `D` pueden compartir el mismo estado común de `A`.

**Fig. 8.** Herencia virtual múltiple en C++.

```
 Modelo (herencia virtual):
                    ┌──────────────────┐
                    │        A         │
                    │ w: int           │
                    │ getW(): int      │
                    └──────────────────┘
                       △            △
           ┌───────────┘            └───────────┐
   ┌──────────────────┐            ┌──────────────────┐
   │        B         │            │        C         │
   │ x: int           │            │ y: int           │
   │ getX(): int      │            │ getY(): int      │
   └──────────────────┘            └──────────────────┘
               △                        △
               └───────────┬────────────┘
                    ┌──────────────────┐
                    │        D         │
                    │ z: int           │
                    │ getZ(): int      │
                    └──────────────────┘

 Memory layout de una instancia de D:            VTables
        ┌──────────────┐
    A ─ │ w   ─ ─ ─ ─ ─┼─ ─ ─ ─ ─ ─ ▶ getW()
        ├──────────────┤
    B ─ │ x   ─ ─ ─ ─ ─┼─ ─ ─ ─ ─ ─ ▶ getX()
        │ ┆            │
        ├──────────────┤
    C ─ │ y   ─ ─ ─ ─ ─┼─ ─ ─ ─ ─ ─ ▶ getY()
        │ ┆            │
        ├──────────────┤
    D ─ │ z   ─ ─ ─ ─ ─┼─ ─ ─ ─ ─ ─ ▶ getZ()
        └──────────────┘
```

![Figura 8 — diagrama original](fuente-berg07a-stateful-traits-fig8.png)

*Descripción: arriba, un diamante clásico con herencia virtual: `A` (variable `w: int`, método `getW(): int`) es heredada virtualmente por `B` (`x: int`, `getX(): int`) y `C` (`y: int`, `getY(): int`); `D` (`z: int`, `getZ(): int`) hereda de `B` y `C`. Abajo, el layout de memoria de una instancia de `D`, compuesto por 4 sub-partes rotuladas `A`, `B`, `C`, `D` con los slots `w`, `x`, `y`, `z`; de cada sub-parte sale un puntero (línea punteada) a su vtable correspondiente (`getW()`, `getX()`, `getY()`, `getZ()`). Una línea punteada vertical (┆) conecta las sub-partes `B` y `C` con el estado de `A`: es el virtual base pointer por el que acceden al estado heredado compartido.*

No intentamos implementar esta estrategia en nuestro prototipo Smalltalk, porque habría requerido una modificación profunda de la VM de Smalltalk. Como Smalltalk soporta solo herencia simple, el layout de los objetos es fundamentalmente más simple. Acomodar virtual base pointers en el layout de un objeto también implicaría cambios en el algoritmo de method lookup (búsqueda de métodos).

### 5.4 El estado del objeto como diccionario

Un enfoque de implementación alternativo es introducir accesos a variables de instancia basados en nombres y no en offsets. El layout de variables tiene la semántica de una hash table, en lugar de la de un array. Para una variable dada, su offset ya no es constante, como muestra la Figura 9. El estado de un objeto se implementa con una hash table en la que múltiples claves pueden mapear al mismo valor. Por ejemplo, la variable `y` de `T1` y la variable `v` de `T2` se fusionan en `T4`. Por lo tanto, una instancia de `T4` tiene dos variables (claves), `T1.y` y `T2.v`, que en realidad apuntan al mismo valor.

**Fig. 9.** La estructura de los objetos es similar a una hash table con múltiples claves para una misma entrada.

```
 Modelo:
   ┌─────────────────────┐
   │         T1          │        @@ { v -> y }
   │ x, y, z             │ ◁◁──────────────┐
   ├─────────┬───────────┤                 │       ┌────────┐
   │ getX    │           │                 ├────── │   T4   │
   └─────────┴───────────┘                 │       └────────┘
   ┌─────────────────────┐        @@ { v -> v }
   │         T2          │ ◁◁──────────────┘
   │ v, x                │
   ├─────────┬───────────┤
   │ getV    │           │
   └─────────┴───────────┘

 Memory layout de T4:
 ┌──────────────┬───┐
 │ T1.x         │ ──┼───▶ val1
 │ T1.y, T2.v   │ ──┼───▶ val2
 │ T1.z         │ ──┼───▶ val3
 │ T2.x         │ ──┼───▶ val4
 └──────────────┴───┘
```

![Figura 9 — diagrama original](fuente-berg07a-stateful-traits-fig9.png)

Cuerpos de métodos adjuntos como notas en la figura:

```smalltalk
getX
    ^ x

getV
    ^ v
```

*Descripción: arriba, el modelo: `T4` usa `T1` con la etiqueta `@@ { v -> y }` y `T2` con `@@ { v -> v }`, con lo cual la variable `y` de `T1` y la variable `v` de `T2` quedan fusionadas bajo el nombre `v`. Abajo, el layout de memoria de `T4` como hash table: las claves `T1.x`, `T1.z` y `T2.x` apuntan a `val1`, `val3` y `val4` respectivamente, mientras que las dos claves `T1.y` y `T2.v` apuntan a la misma entrada `val2`.*

En Python [Pyt], el estado de un objeto se representa con un diccionario. Una expresión como `self.name = value` se traduce a `self.__dict__[name] = value`, donde `__dict__` es una primitiva para acceder al diccionario de un objeto. En Python, una variable se declara y se define simplemente al usarse. Por ejemplo, asignarle un valor a una variable inexistente tiene el efecto de crear una variable nueva. Representar el estado de un objeto con un diccionario es una forma de lidiar con el problema de linealización de la herencia múltiple.

### 5.5 Métodos copy-down

Strongtalk [BGG+02] es un Smalltalk de alto rendimiento con una máquina virtual consciente de los mixins. Un mixin contiene la descripción de sus variables de instancia y de clase, y un diccionario de métodos donde inicialmente se almacena todo el código. Uno de los problemas al compartir código entre aplicaciones de un mixin es que el layout físico de las instancias varía de una aplicación del mixin a otra. Este problema se aborda con el mecanismo de *copy down*: (i) los métodos que no acceden a variables de instancia ni a `super` se comparten en el mixin; (ii) los métodos que acceden a variables de instancia pueden tener que copiarse si el layout de variables difiere del de otros usuarios del mixin.

El mecanismo de copy down favorece la velocidad de ejecución por sobre el consumo de memoria. Acceder a las variables no tiene ningún costo adicional. Las variables se ordenan linealmente, y los métodos que las acceden se duplican y se ajustan con el acceso por offset correcto. Además, en Strongtalk solo los accessors pueden tocar las variables de instancia directamente a nivel de bytecode. El costo en espacio del copy-down es, por lo tanto, mínimo. El inlining efectivo de la VM se encarga del resto, salvo por los accessors, que no imponen ningún costo de espacio.

El enfoque basado en diccionario tiene la ventaja de reflejar más directamente la semántica de los traits stateful, y por eso resulta atractivo para una implementación prototipo. El rendimiento en la práctica, sin embargo, podría volverse problemático, incluso con implementaciones de diccionarios optimizadas como la de Python [Pyt]. El enfoque copy-down, en cambio, es claramente el mejor para una implementación rápida. Por eso decidimos adoptarlo en nuestra implementación de traits stateful en Squeak Smalltalk.

### 5.6 Benchmarks

Como mencionamos en la sección anterior, adoptamos la técnica copy-down para nuestra implementación de traits stateful. En esta sección comparamos el rendimiento de nuestro prototipo de traits stateful con el de Squeak regular sin traits y con el de la implementación de traits stateless. Medimos el rendimiento de los dos casos de estudio siguientes:

- el ejemplo `SyncStream` introducido al principio del paper. El experimento consistió en escribir y leer objetos grandes en un stream 1000 veces. Este ejemplo se eligió para evaluar si el acceso al estado es eficiente.
- una aplicación `link checker` (verificador de enlaces) que parsea páginas HTML para comprobar si las URLs de una página web son alcanzables o no. Esto implica parsear archivos HTML grandes hacia una representación de árbol y correr visitors sobre esos árboles. Este caso de estudio se eligió para tener un ejemplo más equilibrado, que consiste en acceder tanto a métodos como a estado.

Para ambos casos de estudio comparamos la implementación stateful con la implementación de traits stateless y con Squeak regular. Los resultados se muestran en la Tabla 1.

|             | Sin traits | Traits stateless | Traits stateful |
|-------------|------------|------------------|-----------------|
| SyncStream  | 13912      | 13913            | 13912           |
| LinkChecker | 2564       | 2563             | 2564            |

**Tabla 1.** Tiempos de ejecución de dos casos para tres implementaciones: sin traits, con traits stateless y con traits stateful (tiempos en milisegundos).

Como puede verse en la tabla, acceder a variables de instancia definidas en traits y usadas en los clientes no introduce ningún costo adicional. Era de esperarse: el acceso sigue siendo por offset y casi no se notan diferencias. En cuanto a la velocidad de ejecución general, vemos que esencialmente no hay diferencia entre las tres implementaciones. Este resultado es consistente con la experiencia previa con traits, y era de esperarse, porque no cambiamos las partes de la implementación que se ocupan de los métodos.

## 6 Refactorización de la jerarquía de colecciones de Smalltalk

Llevamos a cabo un caso de estudio en el que usamos traits stateful para refactorizar la jerarquía de colecciones de Smalltalk. Ya habíamos usado traits stateless para refactorizar la misma jerarquía [BSD03], y ahora comparamos los resultados de las dos refactorizaciones. La jerarquía de colecciones de Smalltalk basada en traits stateless consiste en 29 clases construidas a partir de un total de 52 traits. Entre esas 29 clases hay numerosas clases, que llamamos clases *shell*, que solo declaran variables y definen sus accessors asociados. Siete de las 29 clases (24%) son shell classes (`SkipList`, `PluggableSet`, `LinkedList`, `OrderedCollection`, `Heap`, `Text` y `Dictionary`).

La refactorización con traits stateful resulta en una redistribución de las variables definidas (en las clases) hacia los traits que efectivamente las necesitan y las usan. Otra consecuencia es la disminución del número de métodos requeridos y un mejor encapsulamiento del comportamiento y la representación interna de los traits.

**Fig. 10.** Fragmento de la jerarquía de colecciones de Smalltalk con traits stateless. La clase `Heap` define variables usadas por `TArrayBased` y `TSortBlockBased`.

```
                          ┌───────────────────────────┐
                          │           Heap            │
                          │ array                     │
                          │ tally                     │
                          │ sortBlock                 │
                          ├───────────────────────────┤
                          │ array                     │
                          │ array:                    │
                          │ tally                     │
                          │ tally:                    │
                          │ privateSortBlock:         │
                          │ sortBlock                 │
                          └───────────────────────────┘
                                        │
                                        ▽▽
                        ┌─────────────────────────────────────┐
                        │              THeapImpl              │
                        │  provided     │  required           │
                        ├───────────────┼─────────────────────┤
 ┌────────────────┐     │ add:          │ array               │     ┌─────────────────┐
 │ TExtensibleSeq │ ◁◁──│ copy          │ array:              │──▷▷ │ TExtensibleInst │
 │   ...  │  ...  │     │ grow          │ tally               │     │   ...  │  ...   │
 └────────────────┘     │ removeAt:     │ tally:              │     └─────────────────┘
                        │ ...           │ privateSortBlock:   │
                        │               │ sortBlock           │
                        └───────┬───────┴──────────┬──────────┘
                                ▽▽                 ▽▽
              ┌─────────────────────────┐   ┌─────────────────────────────────┐
              │       TArrayBased       │   │         TSortBlockBased         │
              │ provided │ required     │   │ provided   │ required           │
              ├──────────┼──────────────┤   ├────────────┼────────────────────┤
              │ size     │ array        │   │ sortBlock: │ privateSortBlock:  │
              │ capacity │ array:       │   │            │ sortBlock          │
              │ ...      │ tally        │   └────────────┴────────────────────┘
              │          │ tally:       │
              └──────────┴──────────────┘
```

![Figura 10 — diagrama original](fuente-berg07a-stateful-traits-fig10.png)

Cuerpos de métodos adjuntos como notas en la figura:

```smalltalk
size
    ^ self tally

capacity
    ^ self array size

sortBlock: aBlock
    ...
    self privateSortBlock: aBlock
    ...
```

*Descripción: la clase `Heap` define las variables `array`, `tally` y `sortBlock`, y los métodos (resaltados en negrita en el original) `array`, `array:`, `tally`, `tally:`, `privateSortBlock:` y `sortBlock`. `Heap` usa el trait `THeapImpl`, que provee `add:`, `copy`, `grow`, `removeAt:`, … y requiere (en negrita itálica en el original) los seis accessors `array`, `array:`, `tally`, `tally:`, `privateSortBlock:` y `sortBlock`. `THeapImpl` usa a su vez `TExtensibleSeq` y `TExtensibleInst` (contenidos abreviados como "…" en el original), `TArrayBased` (provee `size`, `capacity`, …; requiere `array`, `array:`, `tally`, `tally:`; con notas `size ^ self tally` y `capacity ^ self array size`) y `TSortBlockBased` (provee `sortBlock:`; requiere `privateSortBlock:` y `sortBlock`; con nota `sortBlock: aBlock … self privateSortBlock: aBlock …`).*

La Figura 10 muestra un caso típico que surge con traits stateless, donde la clase `Heap` debe definir 3 variables (`array`, `tally` y `sortBlock`). El comportamiento de esta clase se limita a la inicialización de los objetos y a proveer accessors para cada una de esas variables. Usa el trait `THeapImpl`, que requiere todos esos accessors. Estos requisitos son necesarios para `THeapImpl` porque está compuesto de `TArrayBased` y `TSortBlockBased`, que requieren ese estado. Estos dos traits necesitan acceso al estado definido en `Heap`.

La Figura 11 muestra cómo se refactoriza `Heap` para usar traits stateful. Todas las variables se movieron a los lugares donde se las necesitaba, con el resultado de que `Heap` queda vacía. Las variables antes definidas en `Heap` pasan a definirse en los traits que efectivamente las requieren. `TArrayBased` define dos variables, `array` y `tally`, por lo que no necesita especificar ningún accessor como método requerido. Es la misma situación con `TSortBlockBased` y la variable `sortBlock`.

**Fig. 11.** Refactorización de la clase `Heap` con traits stateful conservando el trait `THeapImpl`.

```
                          ┌───────────────┐
                          │     Heap      │
                          ├───────────────┤
                          └───────┬───────┘
                                  ▽▽
                  ┌───────────────────────────────┐
                  │           THeapImpl           │
                  │  provided       │  required   │
                  ├─────────────────┼─────────────┤
                  │ add:            │             │
                  │ copy            │             │
                  │ grow            │             │
                  │ removeAt:       │             │
                  │ ...             │             │
                  └─┬───────┬───────┴──┬───────┬──┘
          ┌─────────┘       │          │       └──────────┐
          ▽▽                ▽▽         ▽▽                 ▽▽
 ┌────────────────┐ ┌──────────────────┐ ┌─────────────────┐ ┌─────────────────┐
 │ TExtensibleSeq │ │   TArrayBased    │ │ TSortBlockBased │ │ TExtensibleInst │
 │   ...  │  ...  │ │ array            │ │ sortBlock       │ │   ...  │  ...   │
 └────────────────┘ │ tally            │ ├────────────┬────┤ └─────────────────┘
                    ├──────────┬───────┤ │ sortBlock: │    │
                    │ size     │       │ │ ...        │    │
                    │ capacity │       │ └────────────┴────┘
                    │ ...      │       │
                    └──────────┴───────┘
```

![Figura 11 — diagrama original](fuente-berg07a-stateful-traits-fig11.png)

Cuerpos de métodos adjuntos como notas en la figura:

```smalltalk
size
    ^ tally

capacity
    ^ array size

sortBlock: aBlock
    ...
    sortBlock := aBlock.
    ...
```

*Descripción: mismo fragmento que la Fig. 10 refactorizado con traits stateful. La clase `Heap` queda vacía (sin variables ni métodos) y usa `THeapImpl`, que ahora provee `add:`, `copy`, `grow`, `removeAt:`, … sin ningún método requerido. `TArrayBased` define las variables `array` y `tally` y provee `size`, `capacity`, …; `TSortBlockBased` define la variable `sortBlock` y provee `sortBlock:`, …. Los cuerpos de las notas acceden a las variables directamente (`^ tally`, `^ array size`, `sortBlock := aBlock.`), sin `self` ni accessors.*

Si estamos seguros de que `THeapImpl` no es usado por ninguna otra clase o trait, podemos simplificar aún más esta nueva composición moviendo la implementación del trait `THeapImpl` a `Heap` y eliminando `THeapImpl`. La Figura 12 muestra la jerarquía resultante. La clase `Heap` define métodos como `add:` y `copy`.

**Fig. 12.** Refactorización de la clase `Heap` con traits stateful eliminando el trait `THeapImpl`.

```
                          ┌───────────────┐
                          │     Heap      │
                          ├───────────────┤
                          │ add:          │
                          │ copy          │
                          │ grow          │
                          │ removeAt:     │
                          │ ...           │
                          └─┬────┬───┬──┬─┘
          ┌─────────────────┘    │   │  └─────────────────┐
          ▽▽                     ▽▽  ▽▽                   ▽▽
 ┌────────────────┐ ┌──────────────────┐ ┌─────────────────┐ ┌─────────────────┐
 │ TExtensibleSeq │ │   TArrayBased    │ │ TSortBlockBased │ │ TExtensibleInst │
 │   ...  │  ...  │ │ array            │ │ sortBlock       │ │   ...  │  ...   │
 └────────────────┘ │ tally            │ ├────────────┬────┤ └─────────────────┘
                    ├──────────┬───────┤ │ sortBlock: │    │
                    │ size     │       │ │ ...        │    │
                    │ capacity │       │ └────────────┴────┘
                    │ ...      │       │
                    └──────────┴───────┘
```

![Figura 12 — diagrama original](fuente-berg07a-stateful-traits-fig12.png)

Cuerpos de métodos adjuntos como notas en la figura:

```smalltalk
size
    ^ tally

capacity
    ^ array size

sortBlock: aBlock
    ...
    sortBlock := aBlock.
    ...
```

*Descripción: variante de la Fig. 11 en la que `THeapImpl` fue eliminado: la clase `Heap` define directamente `add:`, `copy`, `grow`, `removeAt:`, … y usa los cuatro traits `TExtensibleSeq`, `TArrayBased`, `TSortBlockBased` y `TExtensibleInst`, con los mismos contenidos y notas que en la Fig. 11.*

Refactorizar la jerarquía de clases de Smalltalk con traits stateful trae múltiples beneficios:

- Se preserva el encapsulamiento: la representación interna no se revela innecesariamente a las clases cliente.
- Menos definiciones de métodos: se evitan los accessors de variables innecesarios. Los accessors que estaban definidos en `Heap` se eliminan.
- Menos requisitos de métodos: como las variables se definen en los traits que las usan, evitamos especificar accessors requeridos. Los accessors de variables de `THeapImpl`, `TArrayBased` y `TSortBlockBased` ya no son requeridos. No hay propagación de métodos requeridos por uso de estado.

## 7 Discusión

### 7.1 La propiedad de aplanamiento (flattening)

En el modelo original de traits stateless [DNS+06], la composición de traits respeta la propiedad de aplanamiento (flattening property), que establece que un método de un trait que no fue sobrescrito tiene la misma semántica que si estuviera implementado directamente en la clase. Esto implica que los traits pueden "inlinearse" para dar una definición de clase equivalente que no usa traits. Es natural preguntarse si una propiedad tan importante se preserva con los traits stateful. En resumen, la respuesta es sí, aunque las variables de los traits puedan tener que alfa-renombrarse para evitar choques de nombres.

Para preservar la propiedad de aplanamiento con traits stateful, tenemos que asegurar que las variables de instancia introducidas por los traits permanezcan privadas del scope de los métodos de ese trait, incluso cuando su scope se amplía al de la clase que realiza la composición. Esto puede hacerse de varias maneras, según los mecanismos de scope que provea el lenguaje anfitrión. Semánticamente, sin embargo, el enfoque más simple es alfa-renombrar las variables de instancia privadas del trait hacia nombres que sean únicos en el scope del cliente. Técnicamente, esto podría lograrse con la técnica común de name-mangling; es decir, anteponiendo el nombre del trait al nombre de la variable al insertarla en el scope del cliente. El renombre y la fusión también son consistentes con el aplanamiento, ya que las variables pueden simplemente renombrarse o fusionarse en el scope del cliente.

### 7.2 Limitar el impacto de los cambios

Cualquier enfoque de composición de software está condenado a ser frágil frente a ciertos tipos de cambio: si cambia una característica que usan varios clientes, el cambio va a afectar a esos clientes. Extender un trait para que provea métodos adicionales bien puede afectar a los clientes introduciendo conflictos nuevos. Sin embargo, el diseño de la composición de traits, basado en resolución explícita, asegura que esos cambios no puedan derivar en cambios implícitos e inesperados en el comportamiento de los clientes directos o indirectos. Un cliente directo generalmente puede resolver un conflicto sin cambiar ni introducir ningún otro trait, así que no va a producirse un efecto dominó [DNS+06].

En los traits stateful, agregarle una variable a un trait no afecta a los clientes, porque las variables son privadas. Quitar o renombrar una variable puede requerir adaptar a sus clientes directos solo si esos clientes acceden explícitamente a esa variable. Sin embargo, una vez adaptados los clientes directos, no puede haber efecto dominó en los clientes indirectos. Al evitar la propagación de métodos requeridos, los traits stateful limitan el efecto de los cambios.

### 7.3 Sobre el acceso a variables

Por defecto, la variable de un trait es privada, imponiendo así el reuso black-box. Al mismo tiempo, ofrecemos un operador que le permite al cliente directo acceder a las variables privadas del trait. Esto puede parecer una violación del encapsulamiento [Sny86]. Sin embargo, este enfoque es consistente con nuestra visión de que los traits sirven como bloques de construcción para componer clases, sea de manera black-box o white-box. Además, es consistente con el principio de que el cliente de un trait controla la composición. Es precisamente este hecho el que asegura que los efectos de los cambios no se propaguen a rincones remotos de la jerarquía de clases.

## 8 Trabajo relacionado

Repasamos brevemente algunas de las numerosas actividades de investigación relevantes para los traits stateful.

**Self.** El lenguaje basado en prototipos Self [US87] no tiene noción de clase. Conceptualmente, cada objeto define su propio formato, sus métodos y sus relaciones de delegación. Los objetos se derivan de otros objetos por clonación y modificación. Los objetos pueden tener uno o más objetos padre; los mensajes que no se encuentran en el objeto se buscan y se delegan a un objeto padre. Self se basa en la noción de slots, que unifica métodos y variables de instancia.

Self usa trait objects para factorizar características comunes [UCCH91]. Nada impide que un trait object contenga además estado. De manera similar a la noción de traits presentada acá, esos trait objects son esencialmente grupos de métodos. Pero, a diferencia de nuestros traits, los trait objects de Self no soportan operadores de composición específicos; en cambio, se usan como objetos padre ordinarios.

**Interfaces con implementación por defecto.** Mohnen [Moh02] propuso una extensión de Java en la que las interfaces pueden equiparse con un conjunto de implementaciones por defecto de métodos. Así, las clases que implementan una interfaz de este tipo pueden declarar explícitamente que quieren usar la implementación por defecto que ofrece esa interfaz (si la hay). Si más de una interfaz menciona el mismo método, debe proveerse un cuerpo de método. Los conflictos se marcan automáticamente, pero requieren que el desarrollador los resuelva a mano. No puede asociarse estado a las interfaces. Scala [sca] también soporta traits, es decir, interfaces parcialmente definidas. Si bien la composición de traits en Scala no sigue exactamente la de los traits stateless, los traits de Scala no pueden definir estado.

**Mixins.** Los mixins [BC90] usan el operador ordinario de herencia simple para extender distintas clases padre con un conjunto empaquetado de características. Aunque este operador de herencia es adecuado para derivar clases nuevas a partir de clases existentes, no es necesariamente apropiado para componer bloques de construcción reutilizables. Específicamente, como la composición de mixins se implementa con herencia simple, los mixins se componen linealmente. Esto da lugar a varios problemas. Primero, puede ser difícil encontrar un orden total adecuado de las características, o puede directamente no existir. Segundo, el "glue code" que explota o adapta la composición lineal puede quedar disperso por toda la jerarquía de clases. Tercero, las jerarquías de clases resultantes suelen ser frágiles frente al cambio, de modo que cambios conceptualmente simples pueden impactar muchas partes de la jerarquía [DNS+06].

**Eiffel.** Eiffel [Mey92] es un lenguaje orientado a objetos puro que soporta herencia múltiple. Las features (características) —es decir, métodos o variables de instancia— pueden heredarse múltiples veces por caminos distintos. Eiffel le da al programador mecanismos que ofrecen un grado fino de control sobre si esas features se comparten o se replican. En particular, las features pueden ser *renombradas* por la clase que hereda. También es posible *seleccionar* una feature particular en caso de conflictos de nombres. Seleccionar una feature significa que, desde el contexto de la subclase que compone, la feature seleccionada tiene precedencia sobre las posiblemente conflictivas.

A pesar de las similitudes entre el esquema de herencia de Eiffel y el esquema de composición de los traits stateful, hay algunas diferencias significativas:

- *Renombre vs. aliasing* – En Eiffel, cuando se crea una subclase, las features heredadas pueden renombrarse. Renombrar una feature tiene el mismo efecto que (i) darle un nombre nuevo a esa feature y (ii) cambiar todas las referencias a esa feature. Esto implica una especie de mapeo a realizar cuando un método renombrado se accede a través del tipo estático de la superclase.

  Por ejemplo, supongamos que una clase `Component` define un método `update`. Una subclase `GraphicalComponent` renombra `update` a `repaint`, y redefine ese `repaint` con una implementación nueva. El siguiente código ilustra esta situación:

  ```eiffel
  class Component
  feature
      update is
          do
              print ('1')
          end
  end
  ```

  ```eiffel
  class GraphicalComponent
  inherit
      Component
          rename
              update as repaint
          redefine
              repaint
          end
  repaint is
      do
          print ('2')
      end
  end
  ```

  En esencia, el método `repaint` actúa como una sobrescritura de `update`. Esto significa que, si se envía `update` a una instancia de `GraphicalComponent`, se llama a `repaint`. Se ilustra en el siguiente ejemplo:

  ```eiffel
  f (c: Component) is
      do
          c.update
      end

  f (create{GraphicalComponent})
  ==> 2
  ```

  Así es como Eiffel preserva el polimorfismo a la vez que soporta el renombre.

  En los traits stateful, hacerle un alias a un método o conceder acceso a una variable le asigna un nombre nuevo. El método o la variable, por lo tanto, pueden seguir invocándose o accediéndose por su nombre original.

- *Fusión de variables* – A diferencia de los traits stateful, en Eiffel las variables solo pueden fusionarse si provienen de una superclase común. En los traits stateful, las variables provistas por dos traits pueden fusionarse sin importar cómo estén formados esos traits.

**Jigsaw.** Jigsaw [Bra92] tiene un sistema de módulos en el que un módulo es un scope auto-referencial que liga nombres a valores (es decir, constantes y funciones). Un módulo actúa como una clase (generador de objetos) y como una unidad estructural de software de grano grueso. Los módulos pueden anidarse; por lo tanto, un módulo puede definir un conjunto de clases. Se provee un conjunto de operadores para componer módulos. Esos operadores son instanciación, merge, override, rename, restrict y freeze.

Aunque hay algunas diferencias entre la definición de un módulo de Jigsaw y los traits stateful —por ejemplo, con el operador rename—, las diferencias más significativas están en la motivación y el contexto. Jigsaw es un framework para definir lenguajes modulares. Jigsaw soporta el renombre completo y le asigna una interpretación semántica al anidamiento. En Jigsaw, un renombre equivale a un reemplazo textual de todas las ocurrencias del atributo. El operador *rename* distribuye sobre *override*. Esto significa que Jigsaw tiene la siguiente propiedad:

*(m1 rename a to b) override (m2 rename a to b) = (m1 override m2) rename a to b*

Los traits están pensados para complementar lenguajes existentes promoviendo el reuso en pequeño, no declaran tipos, infieren sus requisitos y no permiten renombrar. Los traits stateless no le asignan ningún significado al anidamiento. Los traits stateful son sensibles al anidamiento solo en la medida en que las variables de instancia son privadas de un scope dado. El conjunto de operaciones de Jigsaw apunta, además, a la completitud, mientras que en el diseño de los traits sacrificamos completitud a cambio de simplicidad.

Una diferencia notable entre Jigsaw y los traits stateful está en la fusión de variables. En Jigsaw, un módulo puede tener estado, pero las variables no pueden compartirse entre módulos. Con los traits stateful, la misma variable puede ser accedida por los traits que la usan. Un módulo de Jigsaw actúa como una caja negra. Un módulo encapsula sus ligaduras y no puede abrirse. Si bien valoramos la composición black-box, los traits stateful no toman un enfoque tan restrictivo, sino que dejan que el cliente asuma la responsabilidad de la composición, a la vez que queda protegido del impacto de los cambios.

Vale la pena mencionar las cuestiones de tipado que surgieron al implementar Jigsaw. Bracha [Bra92, Capítulo 7] señaló que la dificultad de implementar la herencia en Jigsaw (que se basa en operadores) proviene de la interacción entre el subtipado estructural y las propiedades algebraicas de los operadores de herencia (p. ej., *merge* y *override*).

**Fig. 13.** `E` y `F` son estructuralmente equivalentes pero pueden tener representaciones distintas.

```
 ┌───┐          ┌───┐          ┌───┐
 │ A │          │ B │          │ D │
 └───┘          └───┘          └───┘
 ┌───┐
 │ C │                ┌───┐          ┌───┐
 └───┘                │ E │          │ F │
                      └───┘          └───┘

 Flechas de subclase (subclase ─▷ superclase, punta abierta):
   C ─▷ A     C ─▷ B
   E ─▷ D     E ─▷ C
   F ─▷ D     F ─▷ A     F ─▷ B
```

![Figura 13 — diagrama original](fuente-berg07a-stateful-traits-fig13.png)

*Descripción: grafo de herencia con seis clases. `A`, `B` y `D` en la fila superior; `C` debajo de `A`; `E` y `F` en la fila inferior. Las flechas de punta triangular abierta apuntan de cada subclase a sus superclases: `C` hereda de `A` y `B`; `E` hereda de `D` y `C`; `F` hereda de `D`, `A` y `B`. Las flechas de `E` y `F` se cruzan en el original al atravesar el diagrama hacia las clases superiores.*

Por ejemplo, consideremos las siguientes clases *A*, *B*, *C*, *D*, *E* y *F*, donde *C* es subclase de *A* y *B*, *E* es subclase de *D* y *C*, y *F* es subclase de *D*, *A* y *B*. Tenemos *C = AB*, *E = DC* y *F = DAB*, donde en *C*<sub>new</sub> *= C₁C₂...Cₙ* las superclases de *C*<sub>new</sub> se denotan *Cᵢ*. (Ver Figura 13.) Expandiendo las definiciones de todos los nombres (como dicta el tipado estructural), se encuentra que, por asociatividad, *E = F*. Esta equivalencia dicta que las tres clases tienen el mismo tipo, de modo que pueden usarse de manera intercambiable. Esto, a su vez, requiere que las tres tengan la misma representación. Sin embargo, usando las técnicas de C++ (Sección 5.3), estas tres clases tienen representaciones distintas. Este problema se evita en los traits, donde un trait no define un tipo.

**Cecil.** Cecil [Cha92] es un lenguaje puramente orientado a objetos que combina un modelo de objetos sin clases, una especie de herencia dinámica y una verificación de tipos estática opcional. El sistema de tipos estático de Cecil distingue entre subtipado y herencia de código, aun cuando el caso más común es que la jerarquía de subtipado corra en paralelo a la jerarquía de herencia. Cecil soporta herencia múltiple. Heredar del mismo ancestro más de una vez, directa o indirectamente, no tiene otro efecto que ubicar al ancestro en relación con los otros ancestros: Cecil no tiene herencia repetida. La herencia en Cecil requiere que el hijo acepte todos los campos y métodos definidos en los padres. Esos campos y métodos pueden sobrescribirse en el hijo, pero facilidades como excluir campos o métodos de los padres, o renombrarlos como parte de la herencia, no están presentes en Cecil. Esta es una diferencia importante respecto de los traits stateful.

## 9 Conclusión

Los traits stateless ofrecen un enfoque composicional simple para estructurar programas orientados a objetos. Un trait es, esencialmente, un grupo de métodos puros que sirve como bloque de construcción para las clases y como unidad primitiva de reuso de código. Sin embargo, este modelo simple sufre varias limitaciones; en particular: (i) la reusabilidad del trait se ve afectada porque la interfaz requerida queda típicamente saturada de accessors requeridos sin interés, (ii) las clases cliente se ven forzadas a implementar glue code repetitivo, (iii) la introducción de estado nuevo en un trait propaga accessors requeridos a todas las clases cliente, y (iv) los accessors públicos rompen el encapsulamiento de la clase cliente.

Hemos propuesto una manera de hacer que los traits sean *stateful*, así: primero, los traits pueden tener variables privadas. Segundo, las clases o traits compuestos a partir de traits pueden usar el *operador de acceso a variables* para (i) acceder a variables de los traits usados, (ii) atribuirles nombres locales a esas variables, y (iii) fusionar variables de múltiples traits usados, cuando así se desee. La propiedad de aplanamiento puede preservarse alfa-renombrando los nombres de variables que choquen.

Los traits stateful ofrecen numerosos beneficios: no hay propagación innecesaria de métodos requeridos, los traits pueden encapsular su representación interna, y el cliente puede identificar con más claridad los métodos requeridos esenciales. El glue code duplicado y repetitivo ya no hace falta. Un trait encapsula su propio estado; por lo tanto, un trait que evoluciona no rompe a sus clientes si su interfaz pública permanece sin modificaciones.

Los traits stateful representan una extensión relativamente modesta de los lenguajes de herencia simple, que permite expresar clases como composiciones de componentes de software reutilizables de grano fino. Una pregunta abierta para estudio futuro es si la composición de traits puede subsumir la herencia basada en clases, llevando a un lenguaje de programación basado en la composición, en lugar de la herencia, como mecanismo primario de estructuración de código, siguiendo el diseño de Jigsaw.

## Agradecimientos (Acknowledgment)

Agradecemos el apoyo financiero de la Swiss National Science Foundation para el proyecto "A Unified Approach to Composition and Extensibility" (SNF Project No. 200020-105091/1), y de Science Foundation Ireland y Lero — el Irish Software Engineering Research Centre.

También agradecemos a Nathanael Schärli, Gilad Bracha, Bernd Schoeller, Dave Thomas y Orla Greevy por sus valiosas discusiones y comentarios. Gracias a Ian Joyner por su ayuda con la implementación de Eiffel para MacOSX.

## References

*(Referencias bibliográficas sin traducir, idénticas al original.)*

- **[BC90]** Gilad Bracha and William Cook. Mixin-based inheritance. In *Proceedings OOPSLA/ECOOP '90, ACM SIGPLAN Notices*, volume 25, pages 303–311, October 1990.
- **[BGG+02]** Lars Bak, Gilad Bracha Steffen Grarup, Robert Griesemer, David Griswold, and Urs Hölzle. Mixins in Strongtalk. In *ECOOP '02 Workshop on Inheritance*, June 2002.
- **[Bra92]** Gilad Bracha. *The Programming Language Jigsaw: Mixins, Modularity and Multiple Inheritance*. PhD thesis, Dept. of Computer Science, University of Utah, March 1992.
- **[BSD03]** Andrew P. Black, Nathanael Schärli, and Stéphane Ducasse. Applying traits to the Smalltalk collection hierarchy. In *Proceedings OOPSLA'03 (International Conference on Object-Oriented Programming Systems, Languages and Applications)*, volume 38, pages 47–64, October 2003.
- **[CDG+92]** Luca Cardelli, Jim Donahue, Lucille Glassman, Mick Jordan, Bill Kalsow, and Greg Nelson. Modula-3 language definition. *ACM SIGPLAN Notices*, 27(8):15–42, August 1992.
- **[Cha92]** Craig Chambers. Object-oriented multi-methods in cecil. In O. Lehrmann Madsen, editor, *Proceedings ECOOP '92*, volume 615 of *LNCS*, pages 33–56, Utrecht, the Netherlands, June 1992. Springer-Verlag.
- **[DNS+06]** Stéphane Ducasse, Oscar Nierstrasz, Nathanael Schärli, Roel Wuyts, and Andrew Black. Traits: A mechanism for fine-grained reuse. *ACM Transactions on Programming Languages and Systems*, 28(2):331–388, March 2006.
- **[for]** The fortress language specification. http://research.sun.com/projects/plrg/fortress0866.pdf.
- **[FR03]** Kathleen Fisher and John Reppy. Statically typed traits. Technical Report TR-2003-13, University of Chicago, Department of Computer Science, December 2003.
- **[IKM+97]** Dan Ingalls, Ted Kaehler, John Maloney, Scott Wallace, and Alan Kay. Back to the future: The story of Squeak, A practical Smalltalk written in itself. In *Proceedings OOPSLA '97, ACM SIGPLAN Notices*, pages 318–326. ACM Press, November 1997.
- **[Jik]** The jikes research virtual machine. http://jikesrvm.sourceforge.net/.
- **[Kro85]** S. Krogdahl. Multiple inheritance in simula-like languages. In *BIT 25*, pages 318–326, 1985.
- **[Mey92]** Bertrand Meyer. *Eiffel: The Language*. Prentice-Hall, 1992.
- **[Moh02]** Markus Mohnen. Interfaces with default implementations in Java. In *Conference on the Principles and Practice of Programming in Java*, pages 35–40. ACM Press, Dublin, Ireland, jun 2002.
- **[NDS06]** Oscar Nierstrasz, Stéphane Ducasse, and Nathanael Schärli. Flattening Traits. *Journal of Object Technology*, 5(4):129–148, May 2006.
- **[Pyt]** Python. http://www.python.org.
- **[sca]** Scala home page. http://lamp.epfl.ch/scala/.
- **[SD05]** Charles Smith and Sophia Drossopoulou. Chai: Typed traits in Java. In *Proceedings ECOOP 2005*, 2005.
- **[SDNB03]** Nathanael Schärli, Stéphane Ducasse, Oscar Nierstrasz, and Andrew Black. Traits: Composable units of behavior. In *Proceedings ECOOP 2003 (European Conference on Object-Oriented Programming)*, volume 2743 of *LNCS*, pages 248–274. Springer Verlag, July 2003.
- **[SE90]** Bjarne Stroustrup and Magaret A. Ellis. *The Annotated C++ Reference Manual*. Addison Wesley, 1990.
- **[SG99]** Peter F. Sweeney and Joseph (Yossi) Gil. Space and time-efficient memory layout for multiple inheritance. In *Proceedings OOPSLA '99*, pages 256–275. ACM Press, 1999.
- **[Sla]** Slate. http://slate.tunes.org.
- **[Sny86]** Alan Snyder. Encapsulation and inheritance in object-oriented programming languages. In *Proceedings OOPSLA '86, ACM SIGPLAN Notices*, volume 21, pages 38–45, November 1986.
- **[UCCH91]** David Ungar, Craig Chambers, Bay-Wei Chang, and Urs Hölzle. Organizing programs without classes. *LISP and SYMBOLIC COMPUTATION: An international journal*, 4(3), 1991.
- **[US87]** David Ungar and Randall B. Smith. Self: The power of simplicity. In *Proceedings OOPSLA '87, ACM SIGPLAN Notices*, volume 22, pages 227–242, December 1987.

## Notas de traducción

- **Criterio general:** traducción interpretativa, no literal. Cada oración fue reescrita para que suene natural en español y se entienda de corrido, con cobertura 1:1: mismos párrafos, mismas secciones, sin agregar, quitar ni resumir contenido. El archivo `fuente-berg07a-stateful-traits.md` (inglés) es la referencia canónica ante cualquier duda.
- **Terminología:** los términos técnicos clave se conservan en inglés (trait, stateless/stateful, accessor, glue code, shell class, offset, scope, black-box/white-box, copy-down, virtual base pointer, etc.), con su equivalente en español en la primera aparición y un glosario al inicio del archivo.
- **Código, fórmulas y diagramas:** idénticos al archivo en inglés; los identificadores del código no se traducen. La ecuación de clase (§2.2) y la propiedad de Jigsaw (§8) se mantienen en inglés por ser fórmulas. Las descripciones textuales de las figuras y las notas al pie van en español; los rótulos internos de las cajas ASCII ("provided | required") mantienen la forma del archivo fuente, que replica la leyenda del paper.
- **Errores del original no reproducidos:** los errores tipográficos del PDF en inglés no se arrastran a esta traducción (se traduce el sentido): "reular Squeak" → "Squeak regular"; "In contrast to to stateful traits" → "A diferencia de los traits stateful"; "if they provide from a common superclass" → "si provienen de una superclase común"; "an non-existing variable" → "una variable inexistente"; "classscope" y "the scope of t" → "el scope de la clase que realiza la composición" y "el scope de `T`"; la repetición "in Java-like languages … in Java-like languages" (§3.4) se dice una sola vez; "Nathanel Schärli" y "Bernd Schoeller ," → "Nathanael Schärli" y "Bernd Schoeller,". La lista completa de errores del original está en las Notas de conversión del archivo en inglés, que los conserva tal cual.
- **Excepción:** el título de §2.2 ("Composing classes from mixins" → "Componer clases a partir de mixins") se traduce tal como figura en el original, aunque el contenido describe composición con traits, por tratarse de un título de sección del paper y no de un tipeo.
- **Imágenes:** cada figura incluye, debajo del bloque ASCII, la imagen original como PNG con link relativo (`fuente-berg07a-stateful-traits-figN.png`). Los PNG deben guardarse en la misma carpeta que este .md para que los links funcionen; si falta una imagen, el ASCII y la descripción textual bastan.
- **Referencias:** sin traducir, idénticas al original (incluidos sus propios errores tipográficos, por ser citas bibliográficas).

---

**FIN DE LA TRADUCCIÓN — Stateful Traits**
