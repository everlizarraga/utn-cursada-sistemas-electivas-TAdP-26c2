# Traits: Composable Units of Behaviour (Traits: unidades componibles de comportamiento)

> Traducción interpretativa al español de fuente-traits-composable-units.md (conversión fiel de Scha03aTraits.pdf, ECOOP 2003); el archivo en inglés es la referencia canónica y esta capa reescribe cada oración para lectura natural, con cobertura 1:1, sin agregar, quitar ni resumir.

## Glosario de términos conservados en inglés

- **trait** («rasgo»): unidad primitiva de reutilización de comportamiento; grupo de métodos puros que sirve como bloque de construcción de clases. Se mantiene en inglés en todo el texto por ser el término técnico consagrado.
- **mixin** («mezcla»): especificación de subclase que puede aplicarse a distintas clases padre para extenderlas con un mismo conjunto de características.
- **glue / glue code / glue methods** («pegamento» / código o métodos de conexión): el código que una clase escribe para conectar los traits entre sí y resolver sus conflictos.
- **flattening property** («propiedad de aplanamiento»): la garantía de que la semántica de una clase compuesta con traits es idéntica a la de la misma clase con todos esos métodos definidos directamente en ella.
- **wrapper** («envoltorio»): entidad que envuelve métodos de otra, típicamente para agregarles comportamiento (p. ej., sincronización).
- **super-send / self-send**: envío de un mensaje a super / a self.
- **subtrait**: trait que forma parte de un trait compuesto.

---

Nathanael Schärli, Stéphane Ducasse, Oscar Nierstrasz, and Andrew P. Black

Software Composition Group, University of Bern, Switzerland
OGI School of Science & Engineering, Oregon Health and Science University
{schaerli, ducasse, oscar}@iam.unibe.ch, black@cse.ogi.edu

Publicado en ECOOP'2003, LNCS 2743, pp. 248–274, Springer Verlag, 2003

[^star]: Esta investigación fue financiada en parte por la National Science Foundation (subsidio CCR-0098323) y por el proyecto 2000-067855.02 de la Swiss National Foundation.

**Resumen.** A pesar del protagonismo indiscutido de la herencia como mecanismo fundamental de reutilización en los lenguajes orientados a objetos, sus variantes principales —herencia simple, herencia múltiple y herencia por mixins— sufren todas problemas conceptuales y prácticos. En la primera parte de este artículo identificamos e ilustramos esos problemas. Luego presentamos los traits, un modelo composicional simple para estructurar programas orientados a objetos. Un trait es, en esencia, un grupo de métodos puros que sirve como bloque de construcción de clases y como unidad primitiva de reutilización de código. En este modelo, las clases se componen a partir de un conjunto de traits especificando el glue code (código de conexión) que los une entre sí y que accede al estado necesario. Demostramos cómo los traits superan los problemas que surgen de las distintas variantes de la herencia, discutimos cómo pueden implementarse de manera eficiente y resumimos nuestra experiencia aplicándolos para refactorizar una jerarquía de clases existente.

**Palabras clave:** Herencia, mixins, herencia múltiple, traits, reutilización, Smalltalk

## 1 Introducción

Aunque la herencia simple goza de amplia aceptación como el *sine qua non* de la orientación a objetos, los programadores comprendieron hace tiempo que no es lo bastante expresiva para factorizar las características comunes (es decir, las variables de instancia y los métodos) que comparten las clases de una jerarquía compleja. En consecuencia, los diseñadores de lenguajes propusieron diversas formas de herencia múltiple [7, 23, 29, 35, 41], además de otros mecanismos como los mixins («mezclas») [3, 10, 18, 27, 32], que permiten componer clases de manera incremental a partir de conjuntos de características.

Pese a que pasaron casi veinte años, ni la herencia múltiple ni los mixins lograron una aceptación generalizada [44]. Al resumir la intervención de Alan Snyder en el panel sobre herencia de OOPSLA '87, Steve Cook escribió:

> «La herencia múltiple es buena, pero no hay una buena manera de hacerla.» [11]

La tendencia parece alejarse de la herencia múltiple; los diseñadores de lenguajes recientes como Java y C# decidieron que las complejidades que introduce superan con creces su utilidad. Está ampliamente aceptado que la herencia múltiple genera serios problemas de implementación [14, 43]; nosotros creemos que además introduce serios problemas conceptuales. El estudio de esos problemas nos condujo al diseño de traits que presentamos aquí.

Si bien la herencia múltiple hace posible reutilizar cualquier conjunto de clases que se desee, la clase no suele ser el elemento más apropiado para reutilizar. Esto se debe a que las clases cumplen dos roles que compiten entre sí. El rol primario de una clase es ser *generadora de instancias*: por lo tanto, debe estar completa. Pero como *unidad de reutilización*, una clase debería ser pequeña. Estas propiedades suelen entrar en conflicto. Más aún, el rol de las clases como generadoras de instancias exige que cada una ocupe un lugar *único* en la jerarquía, mientras que las unidades de reutilización deberían poder aplicarse en lugares *arbitrarios*.

Los Flavors de Moon [32] fueron un primer intento de atacar este problema: los Flavors son pequeños, no necesariamente completos, y pueden «mezclarse» en lugares arbitrarios de la jerarquía de clases. Después se desarrollaron nociones más sofisticadas de mixins, de la mano de Bracha y Cook [10], Mens y van Limberghen [27], Flatt, Krishnamurthi y Felleisen [18], y Ancona, Lagorio y Zucca [3]. Todos estos enfoques le permiten al programador crear componentes diseñados para la reutilización y no para la instanciación. Sin embargo, como mostraremos, pueden influir negativamente en la comprensibilidad.

Los mixins usan el operador ordinario de herencia simple para extender distintas clases base con un mismo conjunto de características. Pero aunque ese operador de herencia funciona bien para derivar clases nuevas a partir de existentes, no es apropiado para componer bloques de construcción reutilizables. En concreto, la herencia obliga a componer los mixins de forma lineal, lo cual restringe severamente la posibilidad de especificar el «glue code» necesario para adaptar los mixins de modo que encajen entre sí.

En nuestra propuesta, unas entidades livianas llamadas *traits* sirven como unidades primitivas de reutilización de código. El diseño de traits partió de la observación de que el conflicto entre reutilización y comprensibilidad es más aparente que real. En general, creemos que entender un programa resulta más fácil si es posible verlo en múltiples formas. Aunque una clase haya sido *construida* componiendo pequeños traits en una jerarquía compleja, no hay necesidad de exigir que se la *vea* de esa misma manera. Debería ser posible ver la clase *o bien* como una colección plana de métodos *o bien* como una entidad compuesta a partir de traits. La vista aplanada favorece la comprensión; la vista compuesta favorece la reutilización. No hay conflicto mientras ambas vistas puedan coexistir, lo cual exige que la composición se use únicamente como herramienta de estructuración y que *no tenga efecto alguno sobre el significado de la clase*.

Los traits satisfacen ese requisito. Aportan estructura, modularidad y reutilización *dentro* de las clases, pero pueden ignorarse cuando se consideran las relaciones entre una clase y otra. Los traits logran un equilibrio excelente entre reutilización y comprensibilidad, y a la vez habilitan un mejor modelado conceptual. Además, como los traits se ocupan exclusivamente de reutilizar comportamiento y no estado, evitan las dificultades de implementación que caracterizan a la herencia múltiple y a los mixins.

Los traits tienen las siguientes propiedades.

- Un trait *provee* un conjunto de métodos que implementan comportamiento.
- Un trait *requiere* un conjunto de métodos que sirven como parámetros del comportamiento provisto.
- Los traits no especifican variables de estado, y los métodos que proveen nunca acceden al estado directamente.
- Tanto las clases como los traits pueden componerse a partir de otros traits, pero el orden de composición es irrelevante. Los métodos en conflicto deben resolverse *explícitamente*.
- La composición de traits no afecta la semántica de una clase: el significado de la clase es el mismo que tendría si todos los métodos obtenidos de los traits estuvieran definidos directamente en ella.
- Del mismo modo, la composición de traits no afecta la semántica de un trait: un trait compuesto es equivalente a un trait *aplanado* que contenga los mismos métodos.

Una clase puede construirse heredando de una superclase y agregando un conjunto de traits, las variables de estado necesarias y los métodos requeridos. Estos métodos representan el glue que especifica cómo se conectan los traits entre sí y cómo se resuelven los conflictos. Este enfoque permite descomponer una clase en conjuntos de características coherentes —es decir, traits— y factoriza el glue code que conecta esas características. Como la semántica de un método es independiente de si está definido en un trait o en una clase que lo usa, siempre es posible *aplanar* una estructura de traits compuestos en cualquier nivel.

Las contribuciones de este artículo son la identificación de los problemas asociados a la herencia múltiple y a los mixins, y la introducción de los traits como modelo de composición que resuelve esos problemas. Procedemos así: en la sección 2 describimos los problemas de la herencia múltiple y los mixins, y en la sección 3 presentamos los traits e ilustramos su uso con ejemplos pequeños. En la sección 4 discutimos las decisiones de diseño más importantes y evaluamos los traits frente a los problemas identificados en la sección 2. En la sección 5 presentamos nuestra implementación de traits. En la sección 6 resumimos los resultados de una aplicación realista de traits: la refactorización de la jerarquía de colecciones de Smalltalk-80. Discutimos el trabajo relacionado en la sección 7. Cerramos el artículo e indicamos trabajo futuro en la sección 8.

## 2 Problemas de reutilización de la herencia

La herencia suele considerarse una de las características fundamentales de la programación orientada a objetos, pero al mismo tiempo es un mecanismo con muchos significados e interpretaciones en pugna [44]. A lo largo de los años, los investigadores desarrollaron varios modelos de herencia, entre ellos la herencia simple, la herencia múltiple y la herencia por mixins. En esta sección damos un panorama breve de estos modelos y señalamos sus falencias conceptuales y prácticas respecto de la reutilización. En particular, describimos problemas específicos de la composición de mixins que no habían sido identificados antes en la literatura.

Nótese que esta sección se concentra en cuestiones de reutilización. Otros problemas de la herencia, como las dificultades de implementación [14, 43] y los conflictos entre herencia y subtipado [2, 25, 26], quedan fuera del alcance de este artículo.

**La herencia simple** es el modelo de herencia más sencillo; permite que una clase herede de a lo sumo una superclase. Aunque este modelo está bien aceptado, no es lo bastante expresivo para que el programador factorice todas las características comunes que comparten las clases de una jerarquía compleja. Por eso, la herencia simple a veces fuerza a duplicar código. Nótese que extender la herencia simple con interfaces, como promueve Java, atiende las cuestiones de subtipado y de modelado conceptual, pero no hace nada por evitar la necesidad de duplicar código.

**La herencia múltiple** permite que una clase herede características de más de una clase padre, con los beneficios de una mejor reutilización de código y un modelado más flexible. Sin embargo, la herencia múltiple usa la noción de clase en dos roles que compiten: el de generadora de instancias y el de unidad de reutilización de código. De ahí surgen las siguientes dificultades.

**Características en conflicto.** Con herencia múltiple puede surgir ambigüedad cuando se heredan características en conflicto por caminos distintos [17]. Una situación particularmente problemática es el «diamond problem» (problema del diamante) [10, 38] (también conocido como herencia «fork-join» [33]), que ocurre cuando una clase hereda de la misma clase base por múltiples caminos. Como las clases son generadoras de instancias, todas deben proveer un mínimo de características comunes (p. ej., los métodos =, hash y asString), que típicamente se heredan de una clase raíz común como Object. Así, cuando se reutilizan varias de estas clases, las características comunes entran en conflicto.

Hay dos tipos de característica en conflicto: los métodos y las variables de estado. Mientras que los conflictos de métodos pueden resolverse con relativa facilidad (p. ej., redefiniendo), el estado en conflicto es más problemático. Aun cuando las declaraciones sean consistentes, no queda claro si el estado en conflicto debería heredarse una sola vez o varias [34].

**Acceso a características redefinidas.** Como pueden heredarse características con el mismo nombre desde distintas clases base, una única palabra clave (p. ej., super) no alcanza para acceder sin ambigüedad a los métodos heredados. Por ejemplo, C++ [42] obliga a nombrar explícitamente la superclase para acceder a un método redefinido; las versiones recientes de Eiffel [29] sugieren la misma técnica[^1]. Esto enreda las referencias a clases con el código fuente, y vuelve el código frágil frente a cambios en la arquitectura de la jerarquía. Lenguajes como CLOS [40] evitan las referencias explícitas a clases imponiendo un orden lineal sobre las superclases. Pero esa linealización suele producir comportamientos inesperados [15, 16] y viola el encapsulamiento, porque puede cambiar las relaciones padre-hijo entre las clases de la jerarquía [38, 39].

**Factorización de wrappers genéricos.** La herencia múltiple permite que una clase reutilice características de varias clases base, pero no permite escribir una entidad reutilizable que «envuelva» métodos implementados en clases aún desconocidas[^2].

Esta limitación se ilustra en la figura 1. Supongamos que la clase A contiene métodos read y write que dan acceso sin sincronizar a ciertos datos. Si se vuelve necesario sincronizar el acceso, podemos crear una clase SyncA que herede de A y envuelva los métodos read y write. Es decir, SyncA define métodos read y write que llaman a los heredados bajo el control de un lock (véase la figura 1a).

Supongamos ahora que la clase A forma parte de un framework que también contiene otra clase B con métodos read y write, y que queremos usar la misma técnica para crear una versión sincronizada de B. Naturalmente, querríamos factorizar el código de sincronización para poder reutilizarlo tanto en SyncA como en SyncB.

Con herencia múltiple, la manera natural de compartir código entre clases distintas es heredar de una superclase común. Esto significa que deberíamos mover el código de sincronización a una clase SyncReadWrite que pasaría a ser la superclase de SyncA y de SyncB (véase la figura 1b). Lamentablemente esto no puede funcionar, porque los super-sends se resuelven de manera estática. Los super-sends de los métodos read y write de SyncReadWrite no pueden referirse en un caso a los métodos heredados de A y en el otro a los heredados de B.

Es posible parametrizar los métodos de SyncReadWrite usando self-sends de métodos abstractos en lugar de super-sends explícitos. Esos métodos abstractos los implementará la subclase (véase la figura 1c). Pero esto sigue exigiendo duplicar métodos en cada subclase. Además, evitar los choques de nombres entre las versiones sincronizadas y no sincronizadas de read y write vuelve el enfoque bastante torpe, y hay que asegurarse de que los métodos no sincronizados *no* queden disponibles públicamente en SyncA y SyncB.

[^1]: La posibilidad de acceder a un método redefinido con la palabra clave precursor seguida del nombre opcional de la superclase se agregó a Eiffel en 1997 [29]. En versiones anteriores de Eiffel, acceder a los métodos originales exigía heredar repetidamente de la misma clase [28].

[^2]: En C++ y Eiffel, estructuras parametrizadas como los templates [42] y las clases genéricas [28] compensan esta limitación.

```
a)  ┌────────────────────────┐      ┌─────────┐
    │ read                   │      │    A    │
    │   self acquireLock.    │      ├─────────┤
    │   value := super read. │      │ read    │
    │   self releaseLock.    │      │ write   │
    │   ↑ value              │      └────△────┘
    └────────────────────────┘           │
    ┌────────────────────────┐      ┌────┴────────┐
    │ write                  │      │    SyncA    │
    │   self acquireLock.    │      ├─────────────┤
    │   value := super write.│─────▶│ read        │
    │   self releaseLock.    │      │ write       │
    │   ↑ value              │      │ acquireLock │
    └────────────────────────┘      │ releaseLock │
                                    └─────────────┘

b)  ┌───────┐   ┌───────────────┐   ┌───────┐
    │   A   │   │ SyncReadWrite │   │   B   │
    ├───────┤   ├───────────────┤   ├───────┤
    │ read  │   │ read          │   │ read  │
    │ write │   │ write         │   │ write │
    └──△────┘   │ acquireLock   │   └───△───┘
       │        │ releaseLock   │       │
       │        └──△─────────△──┘       │
       │           │         │          │
    ┌──┴───────────┴──┐   ┌──┴──────────┴──┐
    │      SyncA      │   │      SyncB     │
    └─────────────────┘   └────────────────┘

c)  ┌───────┐  ┌───────────────┐  ┌───────┐   ┌──────────────────────────────┐
    │   A   │  │ SyncReadWrite │  │   B   │   │ syncRead                     │
    ├───────┤  ├───────────────┤  ├───────┤   │   self acquireLock           │
    │ read  │  │ syncRead ─────┼──┼───────┼──▶│   value := self directRead.  │
    │ write │  │ syncWrite ────┼──┼───────┼─┐ │   self releaseLock.          │
    └──△────┘  │ acquireLock   │  └───△───┘ │ │   ↑ value                    │
       │       │ releaseLock   │      │     │ └──────────────────────────────┘
       │       │ *directRead*  │      │     │ ┌──────────────────────────────┐
       │       │ *directWrite* │      │     └▶│ write                        │
       │       └──△─────────△──┘      │       │   self acquireLock           │
       │          │         │         │       │   value := self directWrite. │
    ┌──┴──────────┴──┐   ┌──┴─────────┴───┐   │   self releaseLock.          │
    │      SyncA     │   │      SyncB     │   │   ↑ value                    │
    ├────────────────┤   ├────────────────┤   └──────────────────────────────┘
    │ directRead     │   │ directRead     │   ┌───────────────────┐┌───────────────────┐
    │ directWrite    │   │ directWrite    │   │ directRead        ││ directWrite       │
    │ read           │   │ read           │   │   ↑ super read    ││   ↑ super write   │
    │ write          │   │ write          │   └───────────────────┘└───────────────────┘
    └────────────────┘   └────────────────┘   ┌───────────────────┐┌───────────────────┐
                                              │ read              ││ write             │
                                              │  ↑ self syncRead  ││  ↑ self syncWrite │
                                              └───────────────────┘└───────────────────┘
```

![Figura 1 — diagrama original](fuente-traits-composable-units-fig1.png)

*Descripción textual de la figura:* La figura tiene tres partes. **(a)** Un diagrama de clases: la clase A define los métodos read y write; la clase SyncA hereda de A (flecha de herencia con triángulo blanco) y define read, write, acquireLock y releaseLock. Dos cajas de código muestran los cuerpos de los métodos de SyncA: `read` = `self acquireLock. value := super read. self releaseLock. ↑ value`; `write` = `self acquireLock. value := super write. self releaseLock. ↑ value`. **(b)** Tres clases: A (read, write), SyncReadWrite (read, write, acquireLock, releaseLock) y B (read, write). SyncA hereda simultáneamente de A y de SyncReadWrite; SyncB hereda simultáneamente de SyncReadWrite y de B. Es el intento fallido de factorizar la sincronización en una superclase común. **(c)** A (read, write), SyncReadWrite (syncRead, syncWrite, acquireLock, releaseLock, y en cursiva —abstractos— directRead y directWrite) y B (read, write). SyncA hereda de A y de SyncReadWrite; SyncB hereda de SyncReadWrite y de B; cada una define directRead, directWrite, read y write (los cuatro métodos duplicados). Cajas de código: la caja `syncRead` = `self acquireLock. value := self directRead. self releaseLock. ↑ value`; la caja conectada a syncWrite está rotulada `write` en el original = `self acquireLock. value := self directWrite. self releaseLock. ↑ value`. Las cajas de los métodos de las subclases: `directRead` = `↑ super read`; `directWrite` = `↑ super write`; `read` = `↑ self syncRead`; `write` = `↑ self syncWrite`.

**Fig. 1.** En (a), el código de sincronización está implementado en la subclase SyncA. En (b) mostramos un intento de reutilizar el código de sincronización en SyncA y SyncB a la vez. Sin embargo, esto no funciona, porque los métodos de SyncReadWrite no pueden referirse a los métodos read y write definidos en A y B. En (c) mostramos cómo puede reutilizarse el código de sincronización, aunque esto todavía exige duplicar cuatro métodos en SyncA y SyncB.

**Herencia por mixins.** Un mixin es una especificación de subclase que puede aplicarse a distintas clases padre para extenderlas con un mismo conjunto de características. Los mixins le permiten al programador lograr mejor reutilización de código que la herencia simple, conservando la simplicidad de la operación de herencia. Sin embargo, aunque la herencia funciona bien para extender una clase con un único mixin ortogonal, no funciona tan bien para componer una clase a partir de muchos mixins. El problema es que, por lo general, los mixins no encajan *del todo* entre sí —es decir, sus características pueden entrar en conflicto— y la herencia no es lo bastante expresiva para resolver esos conflictos. Este problema se manifiesta bajo varias formas.

```
    ┌────────────────┐            ┌──────────────┐
    │   Rectangle    │            │    MColor    │
    ├────────────────┤            ├──────────────┤
    │ asString       │◀╌╌╌╌╌╌╌╌╌╌╌│ asString ────┼──▶ asString
    └───────△────────┘            └──────────────┘      ↑ super asString, ' ', self color asString
            │
    ┌───────┴────────────┐        ┌──────────────┐
    │ Rectangle + MColor │        │   MBorder    │
    ├────────────────────┤        ├──────────────┤
    │ asString           │◀╌╌╌╌╌╌╌│ asString ────┼──▶ asString
    └───────△────────────┘        └──────────────┘      ↑ super asString, ' ', self borderSize asString
            │
    ┌───────┴──────────────────────┐
    │ Rectangle + MColor + MBorder │        ──────▷  Inheritance
    ├──────────────────────────────┤        ╌╌╌╌╌╌▶  Mixin application
    │ asString                     │
    └───────△──────────────────────┘
            │
    ┌───────┴────────┐
    │  MyRectangle   │
    └────────────────┘
```

![Figura 2 — diagrama original](fuente-traits-composable-units-fig2.png)

*Descripción textual de la figura:* Cadena de herencia vertical (flechas de triángulo blanco): Rectangle ← Rectangle + MColor ← Rectangle + MColor + MBorder ← MyRectangle; las tres primeras definen asString. A la derecha, los mixins MColor y MBorder (cada uno con asString) se aplican mediante flechas punteadas de "aplicación de mixin": MColor sobre Rectangle produce Rectangle + MColor; MBorder sobre Rectangle + MColor produce Rectangle + MColor + MBorder. Cajas de código: MColor>>asString = `↑ super asString, ' ', self color asString`; MBorder>>asString = `↑ super asString, ' ', self borderSize asString`. La leyenda distingue línea continua con triángulo blanco (Inheritance) de línea punteada con flecha negra (Mixin application).

**Fig. 2.** El código que interconecta los mixins está especificado en el mixin MBorder. La entidad compuesta MyRectangle no puede acceder a las implementaciones de asString del mixin MColor ni de la clase Rectangle. Las clases con + en el nombre son intermediarias generadas por la aplicación de mixins.

**Orden total.** La composición de mixins es lineal: todos los mixins que usa una clase deben heredarse de a uno por vez. Los mixins que aparecen más tarde en el orden redefinen *todas* las características homónimas de los mixins anteriores. Cuando queremos resolver conflictos seleccionando características de distintos mixins, puede ocurrir que no exista ningún orden total adecuado.

**Dispersión del glue code.** Con mixins, la entidad compuesta no tiene control pleno sobre la manera en que se componen: el código de resolución de conflictos debe quedar cableado en las clases intermedias que se crean al usar los mixins, de a uno por vez. Obtener la combinación deseada de características puede exigir modificar los mixins, introducir mixins nuevos o, a veces, usar el mismo mixin dos veces.

La dispersión se ilustra en la figura 2, donde una clase MyRectangle usa dos mixins, MColor y MBorder, que proveen ambos un método asString. Las implementaciones de asString en los mixins primero llaman a la implementación heredada y después extienden la cadena resultante con información sobre su propio estado. Cuando componemos los dos mixins para armar la clase MyRectangle, podemos elegir cuál va primero, pero no podemos especificar cómo se pegan entre sí las distintas implementaciones de asString. Esto se debe a que los mixins deben agregarse de a uno: en Rectangle + MColor + MBorder podemos acceder al comportamiento de MBorder y al comportamiento *mezclado* de Rectangle + MColor, pero *no* al comportamiento original de MColor y de Rectangle. Por lo tanto, si queremos adaptar la manera en que se componen las implementaciones de asString (*p. ej.*, cambiar el carácter separador entre las dos cadenas), tenemos que modificar los mixins involucrados.

**Jerarquías frágiles.** Por la linealidad y los medios limitados para resolver conflictos, usar múltiples mixins produce cadenas de herencia frágiles frente al cambio. Agregar un método nuevo a uno de los mixins puede redefinir silenciosamente un método homónimo de un mixin que aparece antes en la cadena. Peor aún, puede resultar imposible restablecer el comportamiento original del compuesto sin agregar o cambiar varios mixins de la cadena. Este problema es especialmente crítico si se modifica un mixin que se usa en muchos lugares de la jerarquía de clases.

A modo de ilustración, supongamos que en el ejemplo anterior (véase la figura 2) el mixin MBorder no define inicialmente un método asString. Esto significa que la implementación de asString en MyRectangle es la que especifica MColor. Supongamos ahora que más adelante se agrega el método asString al mixin MBorder. Por el orden total, este método nuevo redefine la implementación provista por MColor. Peor todavía: el comportamiento original de la clase compuesta MyRectangle no puede restablecerse sin cambiar varios mixins más.

## 3 Traits

Proponemos un modelo composicional como solución a los problemas ilustrados en la sección anterior. Nuestro modelo se basa en entidades livianas llamadas traits, que sirven como bloques de construcción básicos de las clases y como unidades primitivas de reutilización de código. Así, los traits satisfacen las necesidades de estructura, modularización y reutilización dentro de una clase.

Los traits, y todos los ejemplos de este artículo, están implementados en el dialecto Squeak de Smalltalk-80 [22], pero creemos que el mismo concepto podría aplicarse también a otros lenguajes de herencia simple (véase la sección 8). En el resto de esta sección presentamos los traits en detalle mediante un ejemplo conductor. Mostramos cómo se componen clases a partir de traits, cómo se componen traits a partir de otros traits, y cómo se resuelven los conflictos de nombres. Las restricciones de espacio nos impiden dar una especificación formal de los traits y de las operaciones de composición; está disponible en un artículo complementario [37].

### 3.1 Ejemplo conductor y convenciones de notación

Supongamos que queremos representar objetos gráficos —círculos o cuadrados— que puedan dibujarse sobre un canvas. Usaremos traits para estructurar las clases y factorizar el comportamiento reutilizable. Nos concentramos en la representación de los círculos, pero las mismas técnicas pueden aplicarse a las demás clases.

En los ejemplos, los nombres de traits empiezan con la letra T y los nombres de clases no. Como los traits están implementados en Squeak, presentamos el código en Smalltalk. La notación ClassName>>methodName indica que el método methodName está definido en la clase ClassName.

### 3.2 Especificación de traits

Un trait contiene un conjunto de métodos que implementan el comportamiento que provee. En general, un trait puede requerir un conjunto de métodos que sirven como parámetros del comportamiento provisto. Los traits no pueden especificar estado, y nunca acceden al estado directamente. Los métodos de un trait pueden acceder al estado de forma indirecta, mediante métodos requeridos que en última instancia se satisfacen con accessors (métodos getter y setter).

El propósito de los traits es descomponer las clases en bloques de construcción reutilizables, dándoles representación de primera clase a los distintos aspectos del comportamiento de una clase. Nótese que usamos el término «aspecto» para denotar una incumbencia independiente, aunque no necesariamente transversal. Los traits se diferencian de las clases en que no definen ningún tipo de estado y en que pueden componerse con mecanismos distintos de la herencia.

```
    ┌──────────────────────────────┐       ┌───────────────────────┐
    │           TCircle            │       │       TDrawing        │
    ├───────────────┬──────────────┤       ├────────────┬──────────┤
  ○─│ =             │ *center*     │──▶  ○─│ draw       │ *bounds* │──▶
  ○─│ hash          │ *center:*    │──▶  ○─│ refresh    │ *drawOn:*│──▶
  ○─│ <             │ *radius*     │──▶  ○─│ refreshOn: │          │
  ○─│ <=            │ *radius:*    │──▶    └────────────┴──────────┘
    │ ...           │              │
  ○─│ area          │              │
  ○─│ bounds        │              │
  ○─│ circumference │              │
  ○─│ scaleBy:      │              │
    │ ...           │              │
    └───────────────┴──────────────┘
```

![Figura 3 — diagrama original](fuente-traits-composable-units-fig3.png)

*Descripción textual de la figura:* Dos cajas de trait en notación UML extendida. Cada caja tiene dos columnas: la izquierda lista los métodos provistos (con conectores circulares ○ a la izquierda) y la derecha, en cursiva, los métodos requeridos (con flechas ▶ que salen a la derecha). TCircle provee =, hash, <, <=, ..., area, bounds, circumference, scaleBy:, ... y requiere center, center:, radius, radius:. TDrawing provee draw, refresh, refreshOn: y requiere bounds, drawOn:.

**Fig. 3.** Los traits TDrawing y TCircle, con los métodos provistos en la columna izquierda y los requeridos en la columna derecha.

*Ejemplo.* En nuestro ejemplo, cada objeto gráfico puede descomponerse en dos aspectos: su geometría y la manera en que se dibuja sobre un canvas. En el caso de un círculo, representamos la geometría con el trait TCircle y el comportamiento de dibujo con el trait TDrawing.

La figura 3 muestra estos traits en una extensión de UML. Para cada trait, la columna izquierda lista los métodos provistos y la derecha los métodos requeridos. El trait TDrawing provee los métodos draw, refreshOn: y refresh, y está parametrizado por los métodos requeridos bounds y drawOn:. El código que implementa este trait se muestra a continuación. La existencia de los requisitos queda capturada por métodos (mostrados en cursiva) con cuerpo self requirement.

*(En el PDF, los métodos provistos aparecen en la columna izquierda y los requeridos —en cursiva— en la columna derecha; acá se transcriben secuencialmente.)*

```smalltalk
Trait named: #TDrawing uses: {}

draw
    ↑ self drawOn: World canvas

refresh
    ↑ self refreshOn: World canvas

refreshOn: aCanvas
    aCanvas form
        deferUpdatesIn: self bounds
        while: [self drawOn: aCanvas]
```

```smalltalk
"Métodos requeridos (en cursiva en el original):"
bounds
    self requirement

drawOn: aCanvas
    self requirement
```

El trait TCircle representa la geometría de un círculo; contiene métodos como area, bounds, circumference, scaleBy:, =, < y <=. TCircle requiere los métodos center, center:, radius y radius:, que parametrizan su comportamiento.

### 3.3 Composición de clases a partir de traits

Los traits son completamente retrocompatibles con la herencia simple. En particular, la composición de traits complementa a la herencia simple en lugar de subsumirla. Mientras que la herencia se usa para derivar una clase de otra, los traits se usan para lograr estructura y reutilización *dentro* de la definición de una clase. Resumimos esta relación con la ecuación

*Class = Superclass + State + Traits + Glue*

Esto significa que una clase se deriva de una superclase agregando las variables de estado necesarias, usando un conjunto de traits e implementando los *glue methods* que conectan los traits entre sí y que hacen de accessors de las variables de estado. Para que una clase esté *completa*, todos los requisitos de los traits deben estar satisfechos, *es decir*, deben proveerse métodos con los nombres apropiados. Estos métodos pueden implementarse en la clase misma, en una superclase directa o indirecta, o en otro trait que la clase use.

La composición de traits goza de la *flattening property* (propiedad de aplanamiento). Esta propiedad dice que la semántica de una clase definida con traits es exactamente la misma que la de una clase construida directamente con todos los métodos no redefinidos de los traits. Así, si la clase A se define usando el trait T, y T define los métodos a y b, la semántica de A es la misma que tendría si a y b estuvieran definidos directamente en la clase A. Naturalmente, si el glue code de A define un método b de forma directa, ese b redefine al método b obtenido de T. En particular, la flattening property implica que la palabra clave **super** no tiene semántica especial para los traits; simplemente hace que la búsqueda del método empiece en la superclase de la clase que *usa* el trait.

Otra propiedad de la composición de traits es que el orden de composición es irrelevante, por lo cual los métodos de traits en conflicto deben desambiguarse explícitamente (cf. sección 3.5). Los conflictos entre métodos definidos en clases y métodos definidos por los traits incorporados se resuelven con las siguientes dos reglas de precedencia.

- *Los métodos de la clase tienen precedencia sobre los métodos de los traits.*
- *Los métodos de los traits tienen precedencia sobre los métodos de la superclase.* Esto se desprende de la flattening property, que establece que los métodos de los traits se comportan como si estuvieran definidos en la clase misma.

```
    ┌───────────────────────────────────────────────┐
    │                    Circle                     │
    ├───────────────────────────────────────────────┤
  ○─│ initialize                                    │
  ▶○│ drawOn:      ◀──────────────────────────┐     │
  ▶○│ center       ◀───────────────────┐      │     │
  ▶○│ center:      ◀──────────────────┐│      │     │
  ▶○│ radius       ◀─────────────────┐││      │     │
  ▶○│ radius:      ◀────────────────┐│││      │     │
    │                               ││││      │     │
    │  ┌──────────────────────────┐ ││││      │     │
    │  │         TCircle          │ ││││      │     │
    │  ├──────────────┬───────────┤ ││││      │     │
    │ ○│ =            │ *center*  │─┘│││      │     │
    │ ○│ hash         │ *center:* │──┘││      │     │
    │ ○│ <            │ *radius*  │───┘│      │     │
    │  │ ...          │ *radius:* │────┘      │     │
    │ ○│ area         │           │           │     │
    │▶○│ bounds ◀───┐ │           │           │     │
    │ ○│ scaleBy:   │ │           │           │     │
    │  │ ...        │ │           │           │     │
    │  └────────────┼─┴───────────┘           │     │
    │               │                         │     │
    │  ┌────────────┼─────────────┐           │     │
    │  │         TDrawing         │           │     │
    │  ├──────────────┬───────────┤           │     │
    │ ○│ draw         │ *drawOn:* │───────────┘     │
    │ ○│ refresh      │ *bounds*  │──── (a bounds   │
    │ ○│ refreshOn:   │           │      de TCircle)│
    │  └──────────────┴───────────┘                 │
    └───────────────────────────────────────────────┘
```

![Figura 4 — diagrama original](fuente-traits-composable-units-fig4.png)

*Descripción textual de la figura:* La clase Circle (caja exterior) define los métodos initialize, drawOn:, center, center:, radius y radius: (glue, en negrita en el original). Dentro de la caja hay dos traits. TCircle provee =, hash, <, ..., area, bounds, scaleBy:, ... y requiere center, center:, radius, radius:; cada uno de estos cuatro requisitos se conecta con una línea al método homónimo definido en Circle. TDrawing provee draw, refresh, refreshOn: y requiere drawOn: y bounds; el requisito drawOn: se conecta al método drawOn: de Circle, mientras que el requisito bounds se conecta al método bounds provisto por TCircle (única conexión trait-a-trait del diagrama).

**Fig. 4.** La clase Circle se compone de los traits TCircle y TDrawing. El requisito TDrawing>>bounds lo satisface el trait TCircle. Todos los demás requisitos los satisfacen métodos accessor especificados por la clase.

*Ejemplo.* Como ilustran la figura 4 y la definición de clase que sigue, creamos la clase Circle componiendo los traits TCircle y TDrawing. El trait TDrawing requiere los métodos bounds y drawOn:. El trait TCircle provee un método bounds, que ya satisface uno de los requisitos. Por lo tanto, la clase Circle solo tiene que proveer los métodos center, center:, radius y radius: para el trait TCircle, y el método drawOn: para el trait TDrawing.

Los métodos center, center:, radius y radius: son simples accessors de dos variables de instancia. El método drawOn: dibuja un círculo sobre el canvas que recibe como argumento. Además, la clase implementa un método para inicializar las dos variables de instancia.

*(En el PDF, los pares de accessors aparecen en dos columnas: center | center: aPoint y radius | radius: aNumber; acá se transcriben secuencialmente.)*

```smalltalk
Object subclass: #Circle
    instanceVariableNames: 'center radius'
    uses: { TCirle . TDrawing }

initialize
    center := 0@0.
    radius := 50

center
    ↑ center

center: aPoint
    center := aPoint

radius
    ↑ radius

radius: aNumber
    radius := aNumber

drawOn: aCanvas
    aCanvas fillOval: self bounds
        color: Color black
```

### 3.4 Traits compuestos

Así como las clases se componen a partir de traits, los traits pueden componerse a partir de otros traits. A diferencia de las clases, la mayoría de los traits no están completos, lo que significa que no definen todos los métodos que requieren sus subtraits. Los requisitos no satisfechos de los subtraits simplemente se convierten en métodos requeridos del trait compuesto. Otra vez, el orden de composición no importa, y los métodos definidos en el trait compuesto tienen precedencia sobre los métodos de sus subtraits.

Incluso con múltiples niveles de composición, la flattening property sigue siendo válida. La semántica de un método no depende de si está definido en un trait o en una entidad que usa ese trait directa o indirectamente (cf. sección 4.1).

*Ejemplo.* El trait TCircle contiene dos aspectos distintos: los operadores de comparación y las funciones geométricas. Para separar estos aspectos y mejorar la reutilización de código, redefinimos este trait como la composición de los traits TMagnitude y TGeometry, como muestra la figura 5(a). Además, el trait TMagnitude está especificado como trait compuesto: usa el trait TEquality, que requiere los métodos hash y =, y provee el método ~=. El trait TMagnitude, por su parte, requiere < y provee métodos como max:, <=, between:and: y >=. Nótese que TMagnitude no provee ninguno de los métodos requeridos por su subtrait TEquality; esto significa que los requisitos de TEquality se propagan como requisitos de TMagnitude. Finalmente, como se muestra abajo, el trait TCircle se compone de los traits TMagnitude y TGeometry. TCircle define los métodos =, hash y < requeridos por el trait TMagnitude. Abajo mostramos solo la definición de TCircle. La primera línea de esta definición contiene la *cláusula de composición*, que especifica que TCircle usa los subtraits TMagnitude y TGeometry.

```smalltalk
Trait named: #TCircle uses: { TMagnitude . TGeometry }

= other
    ↑ self radius = other radius and: [self center = other center]

hash
    ↑ self radius hash and: [self center hash]

< other
    ↑ self radius < other radius
```

### 3.5 Resolución de conflictos

Un conflicto surge si y solo si combinamos dos traits que proveen métodos homónimos que no se originan en el mismo trait. En particular, esto significa que si el *mismo* método (*es decir*, proveniente del mismo trait) se obtiene más de una vez por caminos distintos, no hay conflicto. Esta regla es semánticamente sólida porque los traits no pueden especificar estado (cf. sección 4.1).

Según las reglas de composición de traits presentadas en la sección 3.3, los conflictos de métodos deben resolverse explícitamente definiendo un método en la clase o en el trait compuesto. La composición de traits lo garantiza redefiniendo los métodos en conflicto con un método marcador especial que indica conflicto de método. Esto asegura que el conflicto se resuelva en el nivel del compuesto, y no por obra de otro subtrait que casualmente provea un método con el nombre apropiado. Este comportamiento hace que la composición de traits sea tanto asociativa como conmutativa.

Para dar acceso a los métodos en conflicto (y así evitar duplicarlos), los traits soportan una operación de *alias*. Los aliases se usan para hacer que un método de un trait esté disponible bajo otro nombre; esto es particularmente útil cuando el nombre original queda excluido por un conflicto. Los aliases se discuten con más detalle en la sección 4.1.

La composición de traits también soporta la *exclusión*, que permite evitar un conflicto antes de que ocurra. La cláusula de composición le permite al programador excluir métodos de un trait al componerlo. Esto suprime esos métodos y permite que la entidad compuesta adquiera la implementación —de otro modo conflictiva— provista por otro trait.

*Ejemplo.* Los círculos coloreados deben contener comportamiento de color. Para hacer reutilizable este comportamiento, lo definimos en el trait TColor que muestra la figura 5(b). Este trait provee los métodos usuales de color, como red, green, saturation, *etc*. Como los colores también pueden compararse por igualdad, TColor usa el trait TEquality e implementa los métodos requeridos = y hash como se muestra a continuación.

```smalltalk
Trait named: #TColor uses: { TEquality }

hash
    ↑ self rgb hash

= other
    ↑ self rgb = other rgb
```

```
a)                              b)                          c)
 ┌────────────────────────┐     ┌──────────────────────┐     ┌──────────────────────────┐
 │        TCircle         │     │        TColor        │     │          Circle          │
 ├────────────────┬───────┤     ├─────────────┬────────┤     ├──────────────────────────┤
○│ <              │       │   ○─│ red         │ *rgb*  │   ○─│ initialize               │
○│ =              │       │   ○─│ green       │ *rgb:* │  ▶○ │ =                        │
○│ hash           │       │   ○─│ hue         │        │   ○─│ hash                     │
 │                        │   ○─│ saturation  │        │  ▶○ │ rgb                      │
 │ ┌────────────────────┐ │   ○─│ red:        │        │   ○─│ rgb:                     │
 │ │    TMaginitude     │ │     │ ...         │        │   ○─│ center                   │
 │ ├───────────────┬────┤ │  ▶○─│ =           │        │  ▶○ │ center:                  │
 │○│ <=            │ *<*│ │  ▶○─│ hash        │        │   ○─│ radius                   │
 │○│ >             │    │ │     └─────────────┴────────┘   ○─│ radius:                  │
 │○│ >=            │    │ │     ┌──────────────────┐      ▶○ │ drawOn:                  │
 │○│ between:and:  │    │ │     │    TEquality     │         │                          │
 │○│ max:          │    │ │     ├────────┬─────────┤         │ ┌──────────────────────┐ │
 │○│ min:          │    │ │     │ ~=     │ *=*     │         │ │        TColor        │ │
 │ │               │    │ │     │        │ *hash*  │         │ ├─────────────┬────────┤ │
 │ │ ┌───────────────┐  │ │     └────────┴─────────┘         │ │ =    ╲      │ *rgb*  │ │
 │ │ │   TEquality   │  │ │                                  │ │ hash  ╲     │ *rgb:* │ │
 │ │ ├───────┬───────┤  │ │            ✗ (conflicto)         │ │ ~=     ╲    │        │ │
 │○│ │ ~=    │ *=*   │  │ │           ╱ ╲                    │○│ red     ╲── │──▶ ✗   │ │
 │ │ │       │ *hash*│  │ │          ╱   ╲                   │○│ green       │        │ │
 │ │ └───────┴───────┘  │ │                                  │ │ ...         │        │ │
 │ └────────────────────┘ │                                  │ └─────────────┴────────┘ │
 │                        │                                  │ ┌──────────────────────┐ │
 │ ┌────────────────────┐ │                                  │ │        TCircle       │ │
 │ │     TGeometry      │ │                                  │ ├─────────────┬────────┤ │
 │ ├──────────┬─────────┤ │                                  │ │ =    ╲      │*center*│ │
 │○│ area     │*center* │─┼─▶                                │ │ hash  ╲──── │──▶ ✗   │ │
 │○│ bounds   │*center:*│─┼─▶                                │ │ ~=          │*center:*││
 │○│ diameter │*radius* │─┼─▶                                │ │ ...         │*radius*│ │
 │○│ scaleBy: │*radius:*│─┼─▶                                │○│ area        │*radius:*││
 │ │ ...      │         │ │                                  │▶○ bounds      │        │ │
 │ └──────────┴─────────┘ │                                  │○│ scaleBy:    │        │ │
 └────────────────────────┘                                  │ │ ...         │        │ │
                                                             │ └─────────────┴────────┘ │
                                                             │ ┌──────────────────────┐ │
                                                             │ │       TDrawing       │ │
                                                             │ ├─────────────┬────────┤ │
                                                             │○│ draw        │*bounds*│ │
                                                             │○│ refresh     │*drawOn:*││
                                                             │○│ refreshOn:  │        │ │
                                                             │ └─────────────┴────────┘ │
                                                             └──────────────────────────┘
```

![Figura 5 — diagrama original](fuente-traits-composable-units-fig5.png)

*Descripción textual de la figura:* Tres partes. **(a)** El trait compuesto TCircle (caja exterior amarilla) declara como glue los métodos <, = y hash (en negrita). Contiene dos subtraits: TMagnitude (rotulado «TMaginitude» en el gráfico original) — provee <=, >, >=, between:and:, max:, min: y requiere < — que a su vez contiene el subtrait TEquality — provee ~= y requiere = y hash —; y TGeometry — provee area, bounds, diameter, scaleBy:, ... y requiere center, center:, radius, radius:, requisitos que salen con flechas del borde del compuesto (se propagan como requisitos de TCircle). Los servicios provistos de los subtraits (p. ej. max:, ~=, area) se propagan al compuesto, y los requisitos = , hash y < de los subtraits se conectan a los métodos glue definidos por TCircle. **(b)** El trait compuesto TColor: provee red, green, hue, saturation, red:, ..., y define como glue = y hash (en negrita); requiere rgb y rgb:. Contiene el subtrait TEquality (provee ~=, requiere = y hash, satisfechos por el glue de TColor). **(c)** La clase Circle: define como glue (en negrita) initialize, =, hash, rgb, rgb:, center, center:, radius, radius: y drawOn:. Contiene los traits TColor (provee =, hash, ~=, red, green, ...; requiere rgb, rgb:), TCircle (provee =, hash, ~=, ..., area, bounds, scaleBy:, ...; requiere center, center:, radius, radius:) y TDrawing (provee draw, refresh, refreshOn:; requiere bounds, drawOn:). Una gran X roja entre TColor y TCircle, conectada por líneas punteadas a los métodos = y hash de ambos traits, marca el conflicto entre sus implementaciones; los requisitos de cada trait se conectan a los métodos glue correspondientes de Circle, y el requisito bounds de TDrawing se satisface con el bounds de TCircle.

**Fig. 5.** La figura (a) muestra cómo un trait TCircle se compone de un trait TGeometry y de un trait compuesto TMagnitude, que contiene el subtrait TEquality. Nótese que los servicios provistos por los subtraits se propagan al trait compuesto (*p. ej.*, max:, ~= y area) y, de modo análogo, los requisitos no satisfechos de los subtraits (*p. ej.*, center y radius:) se convierten en métodos requeridos del trait compuesto. En (b) volvemos a usar el trait TEquality para especificar el comportamiento de comparación del trait TColor. La figura (c) muestra cómo se especifica una clase Circle componiendo los traits TCircle, TColor y TDrawing.

Cuando el trait TColor se incorpora a la clase Circle surge un conflicto, porque los traits TColor y TCircle proveen implementaciones distintas de los métodos = y hash, como muestra la figura 5(c). Nótese que el método ~= no genera conflicto, porque tanto en TCircle como en TColor la implementación se origina en el mismo trait, a saber, TEquality.

La figura 5(c) muestra que los métodos en conflicto quedan excluidos y se convierten así en requisitos que deben implementarse en la clase TCircle para completarla. En el código de abajo definimos el método = de modo que dos círculos coloreados sean iguales si y solo si tienen las mismas propiedades geométricas y el mismo color. Para evitar duplicar código, especificamos los aliases circleEqual:, circleHash, colorEqual: y colorHash para los métodos en conflicto, y los usamos para definir la semántica del compuesto.

*(En el PDF, los métodos hash y = anObject aparecen en dos columnas; acá se transcriben secuencialmente.)*

```smalltalk
Object subclass: #Circle
    instanceVariableNames: 'center radius rgb'
    uses: { TCircle @ {#circleHash -> #hash. #circleEqual: -> #=} .
            TDrawing .
            TColor @ {#colorHash -> #hash. #colorEqual: -> #=} }

hash
    ↑ self circleHash
        bitXor: self colorHash

= anObject
    ↑ (self circleEqual: anObject)
        and: [self colorEqual: anObject]
```

Como alternativa, podríamos decidir que la igualdad de los objetos coloreados es independiente de su color y tiene en cuenta solo sus propiedades geométricas. En ese caso, podríamos quitar los métodos en conflicto = y hash de TColor. Esto evita los conflictos y tiene el efecto de que la clase Circle simplemente usa el comportamiento de comparación provisto por el trait TCircle. La cláusula de composición correspondiente es la siguiente.

```smalltalk
Object subclass: #Circle
    instanceVariableNames: 'center radius rgb'
    uses: { TCircle . TDrawing − {#=. #hash} . TColor }
```

## 4 Discusión y evaluación

En esta sección discutimos algunas decisiones de diseño que influyeron de manera significativa en las propiedades de los traits. Nos concentramos en la reutilización y la comprensibilidad de los programas escritos con traits. Finalmente, presentamos una evaluación de los traits frente a los problemas de reutilización discutidos en la sección 2.

### 4.1 Decisiones de diseño

Los traits se diseñaron con otros modelos de reutilización en mente: tratamos de combinar sus ventajas evitando sus desventajas. Acá discutimos las decisiones de diseño más importantes.

**Desenredar la reutilización de las clases.** Aunque están inspirados en los mixins, los traits son un concepto nuevo. Son una unidad de reutilización de grano más fino que una clase y no están atados a un lugar específico de la jerarquía de herencia. Creemos que estas dos propiedades son esenciales para mejorar la reutilización de código y el modelado conceptual. La reutilización de grano fino es importante porque el abismo que separa a las clases enteras de los métodos individuales es demasiado ancho. Los traits permiten construir clases componiendo comportamientos reutilizables, en lugar de implementar un conjunto grande y desestructurado de métodos. La independencia de la jerarquía es importante porque maximiza la reutilización. Como las clases tienen el rol primario de generadoras de instancias, deben estar completas y, por eso, típicamente quedan embebidas en una jerarquía. Es justamente esta propiedad la que vuelve a las clases inapropiadas para el rol secundario que los lenguajes convencionales les hacen cumplir: el de repositorios de métodos reutilizables [5].

**Herencia simple y la flattening property.** En lugar de reemplazar la herencia simple, decidimos extenderla con la composición de traits. Las dos operaciones son similares pero complementarias, y funcionan bien juntas.

La herencia simple permite reutilizar todas las características (*es decir*, métodos y variables de estado) disponibles en una clase. Si una clase solo puede heredar de una única superclase, heredar estado no trae complicaciones, y una simple palabra clave (*p. ej.*, super) alcanza para acceder a los métodos redefinidos. Este mecanismo de acceso a las características heredadas es cómodo, pero también le da semántica al lugar que un método ocupa en la jerarquía de herencia.

La composición de traits opera con una granularidad más fina que la herencia; se usa para modularizar el comportamiento definido dentro de una clase. Como tal, la composición de traits está diseñada para componer solo comportamiento y no estado. Además, la composición de traits goza de la flattening property, lo que significa que no le asigna ninguna semántica al lugar donde un método está definido.

La flattening property se combina con la herencia simple para demostrar que los traits son una evolución lógica del paradigma de herencia simple. Un sistema basado en traits permite naturalmente escribir y ejecutar código tradicional de herencia simple. Más aún, con el soporte de herramientas apropiado, también permite ver y editar clases construidas a partir de miles de traits profundamente compuestos exactamente igual que si estuvieran implementadas sin usar traits en absoluto.

**Aliasing.** Muchas implementaciones de herencia múltiple dan acceso a las características redefinidas exigiendo que el programador nombre explícitamente en el código fuente la superclase que las define. C++ usa el operador de alcance ::, mientras que Eiffel usa la palabra clave precursor. Con traits, elegimos el aliasing de métodos en lugar de poner referencias con nombre a traits dentro de los cuerpos de los métodos; así se evitan los siguientes problemas.

- Las referencias con nombre a traits contradicen la flattening property, porque impiden crear una vista aplanada semánticamente consistente sin adaptar esas referencias en los cuerpos de los métodos.
- Las referencias con nombre a traits exigen que la estructura de traits quede cableada en todos los métodos que las usan. Esto significa que cambiar la estructura de traits, o simplemente mover métodos de un trait a otro, puede invalidar muchos métodos.
- Las referencias con nombre a traits exigirían extender la sintaxis del lenguaje de herencia simple subyacente.

El aliasing de métodos evita todos estos problemas. Es compatible con la flattening property porque el proceso de aplanamiento puede, sencillamente, introducir un nombre nuevo para el cuerpo del método con alias.

Aunque hay similitudes entre el aliasing y el renombre de métodos que provee Eiffel, también hay diferencias esenciales. Mientras que el alias solo establece un nombre alternativo sin afectar el original, con el renombre el nombre original del método queda indefinido. En consecuencia, el renombre de métodos debe cambiar todas las referencias al nombre viejo en los demás métodos para que apunten al nuevo. En cambio, el aliasing no tiene efecto sobre las referencias en otros métodos: exigir que se cambien violaría la flattening property.

**Conflictos de nombres no intencionales.** Con traits, como con cualquier otro enfoque de composición de características basado en nombres, pueden surgir conflictos de nombres no intencionales. Por ejemplo, considérese una clase Java que deba implementar dos interfaces, cada una de las cuales especifica un método con exactamente el mismo nombre (y firma), pero con semánticas distintas.

Por ahora, los traits no ofrecen una solución real a este problema: cuando se componen dos traits, puede pasar que cada uno requiera un método semánticamente distinto que casualmente lleva el mismo nombre. Los aliases alivian el problema solo en pequeña medida. A nuestro entender, una solución completa exige tanto buenas herramientas de refactorización como namespaces explícitos [1, 4].

**Estrategias de conflicto y el problema del diamante.** Aunque los traits se basan en la herencia simple, puede surgir una forma del problema del diamante cuando las características de un mismo trait se obtienen varias veces por caminos distintos. Por ejemplo, considérese un trait X que usa dos traits Y1 e Y2, que a su vez usan ambos el trait Z.

Como los traits no contienen estado, la variante más nefasta del problema del diamante no se presenta. No obstante, en nuestro ejemplo, un método foo provisto por Z será obtenido dos veces por X. La pregunta clave de diseño del lenguaje es: ¿debe considerarse esto un conflicto?

Como explicamos en la sección 3.5, decidimos que no debe haber conflicto si el mismo método se obtiene más de una vez por caminos distintos. Esta «same-operation exception» (excepción de la misma operación), como la llama Snyder [38], tiene la ventaja de una semántica simple e intuitiva, pero puede dar sorpresas si los traits subyacentes cambian. Supongamos que el trait Y2 se reimplementa de modo que ya no usa Z pero sigue soportando el mismo comportamiento (*p. ej.*, el método Z>>foo se copia al trait Y2). Esto causa un conflicto, porque el trait X ahora obtiene dos métodos foo distintos. Así, lo que podía parecer un cambio estrictamente interno del trait Y2 resulta visible para uno de sus clientes.

Aunque pueda parecer que esta situación llevará a jerarquías frágiles, sostenemos que no es así. Cuando Y2 reimplementa foo, está cambiando lo que les provee a sus clientes de una manera menos severa, pero igual de significativa, que cuando agrega o quita métodos. Cualquiera de estos cambios puede introducir conflictos de nombres. Sin embargo, el conflicto resultante es un asunto puramente local, es decir, pueden corregirlo por sí solos los clientes directos de Y2. X puede resolver el conflicto resultante con facilidad, suprimiendo uno u otro foo.

Examinemos dos alternativas a nuestra regla actual. Una alternativa es que X obtenga «automáticamente» uno u otro foo, como pasa con los mixins ordenados linealmente. El problema es que el cambio en Y2 no le daría al programador ninguna señal, aun cuando la semántica de X pudiera haber cambiado.

La alternativa que sugiere Snyder es abandonar la «same-operation exception» y anunciar un conflicto incluso si el mismo método se obtiene varias veces [38]. En nuestro ejemplo, esto significa que ya habría conflicto en el escenario original, y que el programador debería decidir arbitrariamente cuál de los dos métodos foo queda disponible en X. Sostenemos que esto es más peligroso, porque un cambio posterior en el foo provisto por Y1 o por Y2 no se señalaría como algo con posibles consecuencias sobre X. Con el enfoque actual, el conflicto se señala precisamente en el momento en que surge, que es cuando el programador está en condiciones de resolverlo con conocimiento de causa.

### 4.2 Evaluación frente a los problemas identificados

En la sección 2 identificamos un conjunto de problemas de reutilización, conceptuales y prácticos, asociados a las distintas formas de herencia. El diseño de traits estuvo fuertemente influido por el intento de resolver esos problemas. A continuación presentamos una evaluación punto por punto de los resultados.

**Características en conflicto.** Los traits evitan por completo los conflictos de estado al prohibir que los traits expresen estado. Los conflictos de métodos pueden resolverse dentro de los traits seleccionando explícitamente uno de los métodos en conflicto, pero lo más común es resolverlos en las clases, redefiniendo los conflictos. En general, surgen menos conflictos que con herencia múltiple, porque los traits tienden a mantenerse magros, enfocados en un conjunto chico de características que colaboran entre sí.

**Acceso a características redefinidas o en conflicto.** Como los traits son una extensión de la herencia simple, las *clases* siguen pudiendo acceder a las características redefinidas mediante llamadas a **super**. Sin embargo, a veces un *trait* necesita acceder a una característica en conflicto, *p. ej.*, para resolver el conflicto. A esas características se accede mediante aliases, en lugar de nombrar explícitamente el trait que provee la característica deseada. Esto produce jerarquías de traits más robustas, porque los aliases quedan *fuera* de las implementaciones de los métodos. Contrástese este enfoque con los lenguajes de herencia múltiple, en los que hay que nombrar explícitamente la clase que provee un método para resolver una ambigüedad. El enfoque de aliasing evita las referencias a clases enredadas en el código fuente y, a la vez, elimina código difícil de entender y frágil frente al cambio.

**Factorización de wrappers genéricos.** Los wrappers genéricos, como los de sincronización discutidos en la sección 2, pueden expresarse fácilmente con traits. De hecho, la solución (b) de la figura 1 funcionaría si SyncReadWrite fuera un trait, ya que **super** dentro de un trait es solo un marcador de posición para la superclase de la clase que efectivamente use ese trait. Si SyncA se define como subclase de A y SyncB como subclase de B, y ambas usan el trait SyncReadWrite, el envío a **super** de los métodos read y write del trait quedará ligado estáticamente a A o a B *en el momento en que el trait se usa para definir la clase*. Otros tipos de wrappers genéricos pueden definirse casi de la misma manera.

**Orden total.** La composición de traits es simétrica, así que el orden es irrelevante. Sin embargo, la composición de traits puede combinarse productivamente con la herencia para obtener una gran variedad de composiciones parcialmente ordenadas. La idea básica es que, si queremos que una clase C use dos traits T1 y T2 en ese orden, primero introducimos una superclase C′ que usa T1, y después definimos C de modo que herede de C′ y use T2. Esto tiene como consecuencia que los métodos de T2 redefinen a los de T1. Esta estrategia se probó en la práctica cuando refactorizamos la jerarquía de colecciones de Smalltalk (véanse la sección 6 y la figura 6).

**Dispersión del glue code.** Cuando se combinan traits, el glue code queda siempre ubicado en la entidad que combina, lo que refleja la idea de que esa entidad tiene el control total de cómo enchufar entre sí los componentes que implementan sus aspectos. Esta propiedad separa con elegancia el glue code del código que implementa los distintos aspectos, y hace que una clase sea fácil de entender aunque esté compuesta de muchos componentes diferentes.

**Jerarquías frágiles.** Cualquier enfoque jerárquico de composición de software está condenado a ser frágil frente a ciertos tipos de cambio: si cambia una característica usada por muchos clientes, el cambio impactará claramente en todos ellos. La pregunta importante es: ¿con qué severidad afectará el cambio a las características de los clientes directos e indirectos? ¿Necesitamos cambiar implementaciones, o solo glue code? ¿Habrá un efecto dominó por toda la jerarquía a raíz de cambios en apariencia inocuos? Agregar o borrar métodos provistos por un trait bien puede impactar en los clientes introduciendo conflictos o requisitos nuevos, pero los efectos dominó en general se evitan. Un cliente directo puede, por lo general, resolver un conflicto sin reimplementar ninguna característica. Más aún, si el cliente directo logra preservar la interfaz que provee, no habrá efecto dominó alguno.

## 5 Implementación

Los traits tal como se describen en este artículo están implementados en Squeak [22], un dialecto de código abierto de Smalltalk-80. Nuestra implementación consta de dos partes: una extensión del lenguaje Smalltalk-80 y una extensión de las herramientas de programación.

### 5.1 Extensión del lenguaje

Para agregar traits a Squeak, extendimos la implementación de las clases con una variable de instancia adicional que contiene la información de la cláusula de composición. Esta variable define los traits que usa la clase, incluidas las exclusiones y los aliases. Además, introdujimos una representación para los traits, que son en esencia clases despojadas que no pueden definir ni estado ni superclase. Cuando una clase C usa un trait T, el diccionario de métodos de C se extiende con una entrada por cada método de T que C no redefine. Para un alias, agregamos al diccionario de métodos una segunda entrada que asocia el nombre nuevo con el método aliasado. Como los métodos compilados de los traits no suelen depender del lugar donde se usan, el bytecode del método puede compartirse entre el trait que lo define y todas las clases y traits que lo usan. Sin embargo, los métodos que usan la palabra clave super guardan una referencia explícita a la superclase en su tabla de literales. Por eso necesitamos copiar esos métodos y cambiar apropiadamente la entrada de la superclase. Esta copia podría evitarse modificando la máquina virtual para computar super cuando haga falta.

En Smalltalk, las clases son objetos de primera clase; cada clase es instancia de una metaclase que define la forma y el comportamiento de su instancia única [19]. En nuestra implementación soportamos este concepto introduciendo la noción de metatrait; a cada trait se le puede asociar un metatrait. Cuando un trait se usa en una clase, el metatrait asociado (si lo hay) se usa automáticamente en la metaclase. Nótese que un trait sin metatrait puede aplicarse tanto a clases como a metaclases. Para preservar la compatibilidad de metaclases [8, 20], los metatraits se generan automáticamente para los traits que envían mensajes al metanivel mediante el pseudomensaje class.

Como los traits son simples y completamente retrocompatibles con la herencia simple, implementarlos en un lenguaje reflexivo de herencia simple como Squeak no presenta problemas. Que los traits no puedan especificar estado es una simplificación enorme. Evitamos la mayoría de los problemas de rendimiento y de espacio que aparecen con la herencia múltiple, porque esos problemas están relacionados con compilar métodos sin conocer los índices de las variables de instancia dentro del objeto [14].

Nuestra implementación no exige duplicar código fuente, y el bytecode se duplica solo si incluye envíos a super. Un programa con traits muestra en esencia el mismo rendimiento que el programa de herencia simple correspondiente en el que todos los métodos provistos por traits están implementados directamente en las clases que los usan. Esto es especialmente notable porque nuestra implementación no hizo ningún cambio en la máquina virtual de Squeak. Puede haber una pequeña penalización de rendimiento por el uso de métodos accessor, pero esos métodos ya se usan ampliamente de todos modos porque mejoran la mantenibilidad. Los compiladores JIT hacen inline de los accessors de manera rutinaria, así que nos parece enteramente justificable exigir su uso.

### 5.2 Herramientas de programación

Además de una extensión del lenguaje, nuestra implementación incluye una extensión de las herramientas de programación, *es decir*, del browser de Smalltalk. A continuación damos un panorama breve de este browser extendido; puede encontrarse una descripción más detallada en un artículo complementario [36].

Para cada clase (y cada trait), el browser muestra los distintos traits que lo componen. La flattening property le permite al browser aplanar esta estructura jerárquica en cualquier nivel. Además, el browser le muestra al programador los métodos provistos y requeridos, los métodos redefinidos y los glue methods, que especifican cómo la clase satisface los requisitos de sus traits componentes. Estas prestaciones ayudan al programador a trabajar con distintas vistas del código. Por un lado, puede trabajar con el código en una vista aplanada, donde una clase consiste en un conjunto desestructurado de métodos y no importa si la clase está construida con traits ni si un método está definido en un trait o en la clase misma. Por otro lado, puede trabajar en una vista de composición, donde ve cómo las responsabilidades de la clase se descomponen en varios traits y cómo esos traits se pegan entre sí para lograr el comportamiento requerido. Esta vista es especialmente valiosa porque permite entender una clase conociendo los traits involucrados y entendiendo los glue methods.

Como en el Smalltalk estándar, el browser soporta compilación incremental. Cada vez que un método de un trait se agrega, se cambia o se excluye, todos los usuarios de ese trait se actualizan instantáneamente. Las modificaciones también se analizan para inferir el conjunto de métodos requeridos. Si una modificación causa un conflicto nuevo o un requisito sin especificar en cualquier parte del sistema, las clases y traits afectados se agregan automáticamente a una lista de pendientes («to do»).

Nuestra implementación incluye varias herramientas que asisten al programador en la composición de traits y en la generación del glue code necesario. Los métodos requeridos que corresponden a accessors de variables de instancia se generan a pedido. La eliminación de conflictos también está semiautomatizada. Al programador se le presenta una lista de implementaciones alternativas; al elegir una, se genera automáticamente la cláusula de composición que excluye a las demás, y así se elimina el conflicto.

## 6 Una aplicación de traits

Como evaluación realista de su usabilidad, usamos traits para refactorizar la jerarquía de colecciones de Smalltalk-80 tal como está implementada en Squeak 3.2. En esta sección resumimos los resultados de ese trabajo; remitimos al lector interesado a un artículo complementario con más detalles [6].

Las clases centrales de la jerarquía de colecciones de Smalltalk-80 se fueron mejorando durante más de 20 años y suelen considerarse un ejemplo paradigmático de programación orientada a objetos. Cada tipo de colección puede caracterizarse por propiedades como estar ordenada explícitamente (*p. ej.*, Array), ordenada implícitamente (*p. ej.*, SortedCollection), no ordenada (*p. ej.*, Set), ser extensible (*p. ej.*, Bag), inmutable (*p. ej.*, String), con claves (*p. ej.*, Dictionary), o comparable elemento a elemento (*p. ej.*, por identidad o con un operador de comparación de más alto nivel).

Sin embargo, la herencia simple no es lo bastante expresiva para modelar un conjunto tan diverso de clases relacionadas que comparten muchas propiedades distintas en combinaciones variadas. En consecuencia, los implementadores de la jerarquía se vieron forzados a duplicar código o a subir métodos en la jerarquía para después deshabilitarlos en las subclases a las que no aplican [12].

Resolvimos estos problemas creando traits para las distintas propiedades de las colecciones y combinándolos para construir las clases de colección requeridas. Para lograr la máxima flexibilidad, separamos las propiedades que especifican la implementación de una colección de las que especifican la interfaz. Esto nos permitió combinar libremente distintas interfaces (*p. ej.*, «interfaz ordenada-extensible» e «interfaz ordenada-extensible-inmutable») con cualquiera de las implementaciones adecuadas (*p. ej.*, «implementación con lista enlazada» e «implementación basada en arreglos»). Usamos la herencia para ordenar parcialmente los traits; los métodos optimizados de los traits de implementación más específicos tienen precedencia sobre los métodos genéricos provistos por los traits de interfaz más generales.

Además de los traits necesarios para lograr una jerarquía sana y evitar la duplicación de código, usamos subtraits adicionales para estructurar el código con más finura. Estos subtraits nos permiten reutilizar partes del código fuera de la jerarquía de colecciones. Como ejemplo, introdujimos traits que representan el comportamiento de «vacuidad» (que requiere size y provee isEmpty, notEmpty, ifEmpty:, *etc*.) y el de «enumeración» (que requiere do: y provee collect:, select:, detect:, *etc*.).

Aunque algunas de las clases de colección quedaron construidas como composición de hasta 22 traits, la flattening property combinada con nuestras herramientas de programación hace que esto no perjudique la comprensibilidad. Si la estructura de traits no resulta útil para una tarea particular, siempre es posible trabajar con la jerarquía como si estuviera implementada con herencia simple ordinaria.

La figura 6 muestra la jerarquía refactorizada para 21 de las clases de colección más comunes. Además del nombre de la clase, la figura muestra los traits que cada clase usa. Lo que no muestra es que cada uno de esos traits tiene muchos subtraits. La clase abstracta Collection está en la cima; provee una pequeña cantidad de comportamiento general para todas las colecciones. Después tenemos una capa de clases abstractas que proveen distintas combinaciones de traits que representan propiedades de interfaz. En la base tenemos clases concretas que usan traits para proveer las implementaciones.

```
                                        ┌───────────────┐
                                        │ *Collection*  │
                                        ├───────────────┤
                                        │ TCommon       │
                                        │ TBasicImpl    │
                                        └───△△──△──△△───┘
              ┌─────────────────────────────┘│  │  │└─────────────────────────────┐
              │        ┌─────────────────────┘  │  └───────────────┐              │
┌─────────────┴────────────────┐ ┌──────────────┴───────┐ ┌────────┴─────────┐ ┌──┴──────────────────┐
│*ExtensibleSequencedExplicitly*│ │*ExtensibleUnsequenced*│ │*SequencedExplicitly*│ │*SequencedImmutable* │
├──────────────────────────────┤ ├──────────────────────┤ ├──────────────────┤ ├─────────────────────┤
│TExtensibleSequencedExplicitly│ │TExtensibleUnsequenced│ │TSequencedExplicitly│ │ TSequenceImmutable  │
└──────△△──────────────────────┘ └──────────△──────────┘ └────────△─────────┘ └──────────△──────────┘
       ││ ┌───────────────────────────────┐ │                     │                      │
       ││ │*ExtensibleSequencedImplicitly*│ │              ┌──────┴───────┐       ┌──────┴──────┐
       ││ ├───────────────────────────────┤ │              │    Array     │       │  Interval   │
       ││ │TExtensibleSequencedImplicitly │ │              ├──────────────┤       ├─────────────┤
       ││ └──────────△──△─────────────────┘ │              │ TArrayedImpl │       │TIntervalImpl│
       ││            │  │                   │              │TArraySpecific│       └─────────────┘
       ││   ┌────────┴┐ └┬────────────────┐ │              └──────△───────┘
       ││   │  Heap   │  │SortedCollection│ │                     │
       ││   ├─────────┤  ├────────────────┤ │              ┌──────┴──────┐
       ││   │THeapImpl│  │  TSortedImpl   │ │              │  WeakArray  │
       ││   └─────────┘  └────────────────┘ │              └─────────────┘
       ││                                   │
┌──────┴┐└┬──────────────────┐              │
│LinkedList│OrderedCollection │             │
├──────────┼──────────────────┤             │
│TLinkedImpl│  TOrderedImpl   │             │
└──────────┴──────────────────┘             │
        ┌───────────────────┬───────────────┼─────────────────────┬──────────────────┐
┌───────┴─────────────────┐ ┌───────┴───────┐ ┌───────┴──────┐ ┌──────┴───────┐
│           Bag           │ │  Dictionary   │ │     Set      │ │   SkipList   │
├─────────────────────────┤ ├───────────────┤ ├──────────────┤ ├──────────────┤
│TExtensibleInstanceCreationImpl│ │TDictionaryImpl│ │ THashedImpl  │ │ TSkipListImpl│
└────────────△────────────┘ └───────△───────┘ └───△──△──△───┘ └──────△───────┘
             │                      │             │  │  │            │
      ┌──────┴──────┐               │   ┌─────────┘  │  └─────────┐  │
      │ IdentityBag │               │   │            │            │  │
      └─────────────┘               │ ┌─┴───────┐ ┌──┴─────────┐ ┌┴──┴──────────┐
                                    │ │ WeakSet │ │IdentitySet │ │ PluggableSet │
                                    │ └─────────┘ ├────────────┤ ├──────────────┤
                                    │             │TIdentityAdaptor│ │TPluggableAdaptor│
                                    │             └────────────┘ └──────────────┘
    ┌───────────────────┬───────────┴───┬─────────────────────┬──────────────────┐
┌───┴───────────────┐ ┌─┴────────────────┐ ┌────────┴──────────┐ ┌───┴────────────────┐   ┌────────────────┐
│PluggableDictionary│ │IdentityDictionary│ │ WeakKeyDictionary │ │WeakValueDictionary │   │IdentitySkipList│
├───────────────────┤ ├──────────────────┤ └────────△──────────┘ └────────────────────┘   └──(← de SkipList)┘
│ TPluggableAdaptor │ │ TIdentityAdaptor │          │
└───────────────────┘ └──────────────────┘ ┌────────┴─────────────────┐
                                           │ WeakIdentityKeyDictionary│
                                           ├──────────────────────────┤
                                           │     TIdentityAdaptor     │
                                           └──────────────────────────┘
```

![Figura 6 — diagrama original](fuente-traits-composable-units-fig6.png)

*Descripción textual de la figura:* Árbol de herencia (todas las flechas son de herencia, triángulo blanco apuntando a la superclase). Los nombres en cursiva son clases abstractas; debajo de cada nombre figuran los traits que la clase usa directamente. En la raíz, la abstracta **Collection** (TCommon, TBasicImpl). De ella heredan cuatro abstractas: **ExtensibleSequencedExplicitly** (TExtensibleSequencedExplicitly), **ExtensibleUnsequenced** (TExtensibleUnsequenced), **SequencedExplicitly** (TSequencedExplicitly) y **SequencedImmutable** (TSequenceImmutable), más la abstracta **ExtensibleSequencedImplicitly** (TExtensibleSequencedImplicitly), que hereda de Collection. De ExtensibleSequencedExplicitly heredan las concretas **LinkedList** (TLinkedImpl) y **OrderedCollection** (TOrderedImpl). De ExtensibleSequencedImplicitly heredan **Heap** (THeapImpl) y **SortedCollection** (TSortedImpl). De SequencedExplicitly hereda **Array** (TArrayedImpl, TArraySpecific), y de Array hereda **WeakArray** (sin traits directos). De SequencedImmutable hereda **Interval** (TIntervalImpl). De ExtensibleUnsequenced heredan cuatro concretas: **Bag** (TExtensibleInstanceCreationImpl), **Dictionary** (TDictionaryImpl), **Set** (THashedImpl) y **SkipList** (TSkipListImpl). De Bag hereda **IdentityBag** (sin traits directos). De Set heredan **WeakSet** (sin traits directos), **IdentitySet** (TIdentityAdaptor) y **PluggableSet** (TPluggableAdaptor). De Dictionary heredan **PluggableDictionary** (TPluggableAdaptor), **IdentityDictionary** (TIdentityAdaptor), **WeakKeyDictionary** (sin traits directos) y **WeakValueDictionary** (sin traits directos). De WeakKeyDictionary hereda **WeakIdentityKeyDictionary** (TIdentityAdaptor). De SkipList hereda **IdentitySkipList** (sin traits directos).

**Fig. 6.** La jerarquía de colecciones refactorizada. Las clases con nombre en cursiva son abstractas; debajo del nombre de cada clase se muestran los traits que usa directamente.

En total, estas clases usan 48 traits distintos e implementan 567 métodos. Esto es apenas más de un 10% menos métodos que en la implementación original. Además, el código de la implementación con traits es un 12% más chico que el original. Esto es especialmente notable porque otro 9% de los métodos de la implementación original está implementado «demasiado arriba» en la jerarquía, justamente para habilitar el compartir código. Con herencia, la penalidad por implementar un método demasiado arriba es la necesidad reiterada de cancelar el comportamiento heredado en las subclases donde ese comportamiento no tiene sentido. En la implementación con traits no hace falta recurrir a esa táctica.

## 7 Trabajo relacionado

En la sección 2 mostramos cómo la herencia múltiple y los mixins intentan promover la reutilización de código, y los problemas con que se topan esos enfoques. En esta sección comparamos los traits con otros enfoques para estructurar artefactos complejos.

Hay varios otros modelos que usan entidades llamadas «traits» para compartir y reutilizar implementación. Uno de ellos es el lenguaje basado en prototipos Self [45]. En Self no existe la noción de clase; cada objeto define conceptualmente su propio formato, sus métodos y sus relaciones de herencia. Los objetos se derivan de otros objetos por clonación y modificación. Además, Self también tiene la noción de objetos traits, que sirven como repositorios para compartir comportamiento y estado entre múltiples objetos. Uno o más objetos traits pueden seleccionarse dinámicamente como padre(s) de cualquier objeto. Las búsquedas de selectores no resueltas en el hijo se pasan a los padres; es un error que un selector se encuentre en más de un padre.

El lenguaje de programación Mesa, usado para implementar el software de la estación de trabajo Xerox Star, también ofrecía entidades llamadas traits como enfoque de herencia múltiple [13]. Ese enfoque tiene más en común con otros enfoques de herencia múltiple que con el modelo de traits presentado en este artículo. Algunas de las diferencias principales con nuestro modelo son que los traits de Star tienen una semántica distinta respecto de la herencia, tienen otras capacidades de resolución de conflictos, portan estado y admiten múltiples implementaciones para un mismo método.

La familia Larch de lenguajes de especificación [21] también se basa en una construcción llamada trait; la relación resulta ser más que un mero nombre en común. Los traits de Larch son fragmentos de especificaciones que pueden reutilizarse libremente con granularidad fina. Por ejemplo, es posible definir un trait de Larch como IsEmpty, que agrega una única operación a un tipo de datos contenedor existente. Hay, por supuesto, diferencias significativas, ya que nuestros traits no están pensados para demostrar propiedades de los programas, y agregar un trait a una clase no restringe formalmente el comportamiento de los métodos existentes.

El framework de modularidad Jigsaw, desarrollado por Bracha en su tesis doctoral [9], define operadores de composición de módulos —merge, override, copy·as y restrict— llamativamente parecidos a los operadores suma, override, alias y exclusión de los traits. Por ejemplo, el merge de Bracha, como nuestra suma, es conmutativo. Aunque hay diferencias en los detalles de las definiciones (por ejemplo, en cómo se manejan los conflictos), las diferencias más significativas están en la motivación y el contexto. Jigsaw está pensado como un framework completo para la manipulación de módulos en grande, y hace las suposiciones apropiadas para ese escenario: namespaces, tipos y requisitos declarados, renombre total y anidamiento con significado semántico. Los traits están pensados para complementar lenguajes existentes promoviendo la reutilización en pequeño y, en consecuencia, no definen namespaces, no declaran tipos, infieren sus requisitos, no admiten renombre y no le dan significado al anidamiento. El conjunto de operaciones de Jigsaw también apunta a la completitud, mientras que en el diseño de traits renunciamos explícitamente a la completitud en favor de la simplicidad. Aun así, la similitud de los conjuntos centrales de operaciones es alentadora, dado que se definieron de manera independiente.

Las interfaces de colaboración de Caesar se parecen a los traits en que incluyen la declaración de métodos esperados, es decir, los que las clases deben proveer al ligarse a una interfaz [31]. Así, el concepto de interfaz de Caesar puede simular traits ligando una interfaz a una clase y combinándola luego con una implementación específica. Sin embargo, Caesar no tiene ninguna construcción composicional especial para lidiar con conflictos. En cambio, Caesar está diseñado para usar alguna de las estrategias de resolución de conflictos conocidas de los lenguajes de herencia múltiple como C++, lo que lleva a problemas similares a los descriptos en la sección 2. Además, Caesar se basa en wrappers explícitos, que pueden ser costosos en tiempo de ejecución, mientras que la semántica de los traits es compatible con la herencia simple y no crea penalidad de ejecución.

Mezini propuso un enfoque de composición de comportamiento en un entorno basado en clases que parte del modelo de objetos encapsulados de la herencia basada en clases, pero introduce una capa de combinación explícita entre los objetos y las clases [30]. La definición del comportamiento de un objeto en evolución queda dispersa entre una clase que provee el comportamiento estándar del objeto y un conjunto de módulos de software al estilo mixin, llamados adjustments. Una de las diferencias principales con los traits es que el enfoque de Mezini es más dinámico y complejo. De hecho, a cada objeto en evolución se le asocia un combiner-metaobject, responsable de los aspectos composicionales del comportamiento del objeto. Esto significa que el combiner-metaobject usa los adjustments para definir el entorno en el que se evalúan los mensajes enviados al objeto.

La delegación (también conocida como «herencia basada en objetos») es otra forma de composición que esquiva muchos de los problemas asociados a la herencia basada en clases [24]. A diferencia de los traits, la delegación está diseñada para soportar la adaptación dinámica de componentes.

## 8 Conclusiones y trabajo futuro

Este artículo presentó los traits, un modelo composicional simple para construir y estructurar programas orientados a objetos. Los traits se componen con un conjunto de operadores —combinación simétrica, exclusión y aliasing— cuidadosamente diseñados para permitir bastante flexibilidad de composición sin quedar sujetos a los problemas y limitaciones que identificamos para los mixins y la herencia múltiple.

Gracias a sus propiedades de composición favorables, los traits son una extensión ideal para los lenguajes de herencia simple. Los traits son completamente retrocompatibles con Smalltalk y no exigen modificar ni extender la sintaxis de métodos del lenguaje subyacente. Más aún, la flattening property garantiza una comprensibilidad óptima del código resultante, porque siempre es posible tanto ver como editar el código como si estuviera escrito con herencia simple.

Contar con las herramientas de programación correctas demostró ser crucial para que el programador obtenga el máximo beneficio de los traits. En nuestra implementación basada en Squeak, cambiamos el browser para que el programador pueda alternar sin fricción entre las distintas vistas, y para que resalte los glue methods que definen cómo se conectan los traits.

Usamos traits con éxito para refactorizar la jerarquía de colecciones, lo cual es un fuerte indicio de la usabilidad de los traits para problemas realistas y no triviales. También mostró que los traits sirven para modularizar clases ya construidas, y que elevan el nivel de abstracción al construir clases nuevas. Mientras trabajábamos con la jerarquía refactorizada, nos impresionó el poder de la flattening property, que volvió muy sencillo entender clases construidas a partir de traits compuestos.

Como trabajo futuro nos gustaría (1) evaluar el impacto de la introducción de namespaces y encapsulamiento sobre la flattening property, (2) considerar los efectos de permitir que los traits especifiquen variables de estado, (3) extender la composición de traits para que pueda reemplazar a la herencia, (4) evaluar la posibilidad de usar traits para modificar el comportamiento de instancias individuales en tiempo de ejecución, (5) desarrollar un sistema de tipos para traits e identificar las relaciones entre traits e interfaces, y (6) seguir explorando la aplicación de traits a la refactorización de jerarquías de clases complejas.

También planeamos considerar cuál es la mejor manera de agregar traits a Java, donde tanto el sistema de tipos como la sintaxis vuelven más problemático el enfoque simple que funciona tan bien para Smalltalk. Por ejemplo, el tipo de un método de un trait puede depender de la clase en la que finalmente se use; el sistema de tipos actual de Java no puede expresar eso. Hay además algunos problemas sintácticos molestos, como que el nombre de un constructor sea el mismo que el de la clase: ¿cuál debería ser el nombre de un constructor en un trait? Con todo, creemos que estos problemas pueden superarse sin cambios mayores al espíritu de Java.

**Agradecimientos.** Queremos agradecer a Gilad Bracha, William Cook, Erik Ernst, Robert Hirschfeld, Andreas Raab y Roel Wuyts por su disposición a interactuar con nosotros mientras desarrollábamos los traits y por sus comentarios sobre este artículo. Agradecemos también a los revisores de ECOOP por sus valiosas sugerencias, que ayudaron a mejorar la presentación en muchos sentidos.

## Referencias

*(Sin traducir, idénticas al archivo en inglés.)*

1. Franz Achermann and Oscar Nierstrasz. Explicit Namespaces. In Jürg Gutknecht and Wolfgang Weck, editors, *Modular Programming Languages*, volume 1897 of *LNCS*, pages 77–89, Zürich, Switzerland, September 2000. Springer-Verlag.
2. Pierre America. Designing an object-oriented programming language with behavioural subtyping. In *Proceedings REX/FOOLS Workshop*, Noordwijkerhout, June 1990.
3. Davide Ancona, Giovanni Lagorio, and Elena Zucca. Jam - a smooth extension of java with mixins. In *Proceedings ECOOP 2000*, volume 1850 of *Lecture Notes in Computer Science*, pages 145–178, 2000.
4. Alexandre Bergel, Stéphane Ducasse, and Roel Wuyts. Classboxes: A minimal module model supporting local rebinding. In *Proceedings of the Joint Modular Languages Conference 2003*. Springer-Verlag, 2003. To appear.
5. Andrew Black, Norman Hutchinson, Eric Jul, and Henry Levy. Object structure in the Emerald system. In *Proceedings OOPSLA '86, ACM SIGPLAN Notices*, volume 21, pages 78–86, November 1986.
6. Andrew Black, Nathanael Schärli, and Stéphane Ducasse. Applying traits to the Smalltalk collection hierarchy. Technical Report IAM-02-007, Institut für Informatik, Universität Bern, Switzerland, November 2002. Also available as Technical Report CSE-02-014, OGI School of Science & Engineering, Beaverton, Oregon, USA.
7. Alan H. Borning and Daniel H.H. Ingalls. Multiple inheritance in Smalltalk-80. In *Proceedings at the National Conference on AI*, Pittsburgh, PA, 1982.
8. Noury M. N. Bouraqadi-Saadani, Thomas Ledoux, and Fred Rivard. Safe metaclass programming. In *Proceedings OOPSLA '98*, pages 84–96, 1998.
9. Gilad Bracha. *The Programming Language Jigsaw: Mixins, Modularity and Multiple Inheritance*. Ph.D. thesis, Dept. of Computer Science, University of Utah, March 1992.
10. Gilad Bracha and William Cook. Mixin-based inheritance. In *Proceedings OOPSLA/ECOOP '90, ACM SIGPLAN Notices*, volume 25, pages 303–311, October 1990.
11. Steve Cook. OOPSLA '87 Panel P2: Varieties of inheritance. In *OOPSLA '87 Addendum To The Proceedings*, pages 35–40. ACM Press, October 1987.
12. William R. Cook. Interfaces and specifications for the Smalltalk-80 collection classes. In *Proceedings OOPSLA '92, ACM SIGPLAN Notices*, volume 27, pages 1–15, October 1992.
13. Gael Curry, Larry Baer, Daniel Lipkie, and Bruce Lee. TRAITS: an approach to multiple inheritance subclassing. In *Proceedings ACM SIGOA, Newsletter*, volume 3, Philadelphia, June 1982.
14. R. Dixon, T. McKee, M. Vaughan, and P. Schweizer. A fast method dispatcher for compiled languages with multiple inheritance. In *Proceedings OOPSLA '89, ACM SIGPLAN Notices*, volume 24, pages 211–214, October 1989.
15. R. Ducournau, M. Habib, M. Huchard, and M.L. Mugnier. Monotonic conflict resolution mechanisms for inheritance. In *Proceedings OOPSLA '92, ACM SIGPLAN Notices*, volume 27, pages 16–24, October 1992.
16. R. Ducournau and Michel Habib. On some algorithms for multiple inheritance in object-oriented programming. In J. Bézivin, J-M. Hullot, P. Cointe, and H. Lieberman, editors, *Proceedings ECOOP '87*, volume 276 of *LNCS*, pages 243–252, Paris, France, June 15-17 1987. Springer-Verlag.
17. Dominic Duggan and Ching-Ching Techaubol. Modular mixin-based inheritance for application frameworks. In *Proceedings OOPSLA 2001*, pages 223–240, October 2001.
18. Matthew Flatt, Shriram Krishnamurthi, and Matthias Felleisen. Classes and mixins. In *Proceedings of the 25th ACM SIGPLAN-SIGACT Symposium on Principles of Programming Languages*, pages 171–183. ACM Press, 1998.
19. Adele Goldberg and David Robson. *Smalltalk 80: the Language and its Implementation*. Addison Wesley, Reading, Mass., May 1983.
20. Nicolas Graube. Metaclass compatibility. In *Proceedings OOPSLA '89, ACM SIGPLAN Notices*, volume 24, pages 305–316, October 1989.
21. John V. Guttag, James J. Horning, and Jeannette M. Wing. The larch family of specification languages. *IEEE Transactions on Software Engineering*, 2(5):24–36, September 1985.
22. Dan Ingalls, Ted Kaehler, John Maloney, Scott Wallace, and Alan Kay. Back to the future: The story of Squeak, A practical Smalltalk written in itself. In *Proceedings OOPSLA '97*, pages 318–326, November 1997.
23. Sonia E. Keene. *Object-Oriented Programming in Common-Lisp*. Addison Wesley, 1989.
24. Günter Kniesel. Type-safe delegation for run-time component adaptation. In R. Guerraoui, editor, *Proceedings ECOOP '99*, volume 1628 of *LNCS*, pages 351–366, Lisbon, Portugal, June 1999. Springer-Verlag.
25. Wilf LaLonde and John Pugh. Subclassing ≠ Subtyping ≠ Is-a. *Journal of Object-Oriented Programming*, 3(5):57–62, January 1991.
26. Ole Lehrmann Madsen, Boris Magnusson, and Birger Møller-Pedersen. Strong typing of object-oriented languages revisited. In *Proceedings OOPSLA/ECOOP '90, ACM SIGPLAN Notices*, volume 25, pages 140–150, October 1990.
27. Tom Mens and Marc van Limberghen. Encapsulation and composition as orthogonal operators on mixins: A solution to multiple inheritance problems. *Object Oriented Systems*, 3(1):1–30, 1996.
28. Bertrand Meyer. *Eiffel: The Language*. Prentice-Hall, 1992.
29. Bertrand Meyer. *Object-Oriented Software Construction*. Prentice-Hall, second edition, 1997.
30. Mira Mezini. Dynamic object evolution without name collisions. In *Proceedings ECOOP '97*. Springer-Verlag, June 1997.
31. Mira Mezini and Klaus Ostermann. Integrating independent components with on-demand remodularization. In *Proceedings OOPSLA 2002*, pages 52–67, November 2002.
32. David A. Moon. Object-oriented programming with flavors. In *Proceedings OOPSLA '86, ACM SIGPLAN Notices*, volume 21, pages 1–8, November 1986.
33. Markku Sakkinen. Disciplined inheritance. In S. Cook, editor, *Proceedings ECOOP '89*, pages 39–56, Nottingham, July 10-14 1989. Cambridge University Press.
34. Markku Sakkinen. The darker side of C++ revisited. *Structured Programming*, 13(4):155–177, 1992.
35. Craig Schaffert, Topher Cooper, Bruce Bullis, Mike Killian, and Carrie Wilpolt. An Introduction to Trellis/Owl. In *Proceedings OOPSLA '86, ACM SIGPLAN Notices*, volume 21, pages 9–16, November 1986.
36. Nathanael Schärli and Andrew Black. A browser for incremental programming. Technical Report CSE-03-008, OGI School of Science & Engineering, Beaverton, Oregon, USA, April 2003.
37. Nathanael Schärli, Oscar Nierstrasz, Stéphane Ducasse, Roel Wuyts, and Andrew Black. Traits: The formal model. Technical Report IAM-02-006, Institut für Informatik, Universität Bern, Switzerland, November 2002. Also available as Technical Report CSE-02-013, OGI School of Science & Engineering, Beaverton, Oregon, USA.
38. Alan Snyder. Encapsulation and inheritance in object-oriented programming languages. In *Proceedings OOPSLA '86, ACM SIGPLAN Notices*, volume 21, pages 38–45, November 1986.
39. Alan Snyder. Inheritance and the development of encapsulated software systems. In *Research Directions in Object-Oriented Programming*, pages 165–188. MIT Press, 1987.
40. Guy L. Steele. *Common Lisp The Language*. Digital Press, second edition, 1990. book.
41. Bjarne Stroustrup. *The C++ Programming Language*. Addison Wesley, Reading, Mass., 1986.
42. Bjarne Stroustrup. *The Design and Evolution of C++*. Addison Wesley, 1994.
43. Peter F. Sweeney and Joseph (Yossi) Gil. Space and time-efficient memory layout for multiple inheritance. In *Proceedings OOPSLA '99*, pages 256–275. ACM Press, 1999.
44. Antero Taivalsaari. On the notion of inheritance. *ACM Computing Surveys*, 28(3):438–479, September 1996.
45. David Ungar and Randall B. Smith. Self: The power of simplicity. In *Proceedings OOPSLA '87, ACM SIGPLAN Notices*, volume 22, pages 227–242, December 1987.

---

## Notas de traducción

- **Criterio general:** traducción interpretativa oración por oración —cada frase reescrita para sonar natural en español y leerse de corrido—, con cobertura 1:1: mismos párrafos, mismas secciones, sin agregar, quitar ni resumir contenido.
- **Terminología:** los términos del glosario inicial (trait, mixin, glue code, flattening property, wrapper, super-send/self-send, subtrait) se mantienen en inglés en todo el texto, con equivalente en español en su primera aparición; el resto de la terminología va en español.
- **Erratas del original en inglés:** las erratas puramente tipográficas documentadas en las Notas de conversión del archivo fuente («one classeand another», «a completely backward-compatible», «inapproprate», «defiend», «the our programming tools», «particualr», «theTrait») se tradujeron con el sentido corregido, ya que un typo inglés no puede «mantenerse» en español. «TGeomery» (§3.4) se tradujo como TGeometry, el nombre correcto del trait. En §3.5 se mantuvo «la clase TCircle» tal como dice el original, pese a que por contexto correspondería la clase Circle, por tratarse de un posible error semántico y no tipográfico.
- **Código, ecuación y diagramas:** idénticos al archivo en inglés, erratas incluidas (p. ej., «TCirle» en la cláusula uses: del código de la clase Circle); los identificadores del código no se traducen. Las descripciones textuales de figuras y las notas al pie sí están en español.
- **Referencias bibliográficas:** sin traducir.
- **Imágenes:** cada figura lleva triple refuerzo (ASCII → imagen original → descripción textual). Los PNG (`fuente-traits-composable-units-fig1.png` a `-fig6.png`) deben guardarse en la misma carpeta que este .md para que los links relativos funcionen; si falta un PNG, el ASCII y la descripción bastan.

**FIN DE LA TRADUCCIÓN — Traits: Composable Units of Behaviour**
