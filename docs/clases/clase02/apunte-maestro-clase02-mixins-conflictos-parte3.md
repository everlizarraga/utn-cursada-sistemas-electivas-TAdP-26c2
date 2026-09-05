# 📘 APUNTE MAESTRO — clase02 · Mixins: resolución de conflictos
## Parte 3 — Qué tiene cada tecnología

*Al terminar esta parte vas a poder agarrar una tecnología cualquiera, pasarla por los seis criterios, decir a qué se parece más, y —lo que de verdad importa— decir con qué herramientas de diseño contás cuando estás adentro.*

Esta parte responde la quinta pregunta de la unidad: ¿cuáles de estas herramientas se usan en Ruby? ¿Y en Scala? La respuesta no está en ninguna lectura: hay que ir a mirar y sacar conclusiones propias.

---

## 1. 🔴 Para qué sirve clasificar

Antes de empezar, una advertencia sobre el ejercicio mismo.

**Categorizar solo tiene sentido cuando la categorización responde una pregunta.** Si la pregunta es "¿esto es estrictamente un mixin o un trait?", muchas veces la respuesta es *ninguna de las dos*, y la etiqueta no aporta nada más que la opinión de quien la puso. Pero si la pregunta es **"¿cómo puedo diseñar con esto? ¿A qué se parece en términos de diseño? ¿Qué herramientas de las que conozco puedo usar acá?"**, entonces la clasificación es útil aunque sea aproximada: *"esto es más parecido a un trait; no vas a poder usar los patrones de mixins porque no hay linearización"*.

Eso es lo que vas a hacer con cada tecnología: no encajarla en una caja, sino saber **qué podés hacer adentro**. Con qué patrones contás, dónde va el estado, qué le tenés que transmitir a tu equipo.

Y una segunda advertencia: **siempre hay un ornitorrinco.** Es fácil clasificar cosas que ya responden a una clasificación. Pero las cosas no pretenden responder a un árbol —por eso teníamos este problema en primer lugar— y de vez en cuando aparece un bicho que pone huevos y es mamífero. Esto ni siquiera es culpa de la naturaleza: los conceptos los inventamos nosotros, los combinamos, y los desordenamos también. Que estén desordenados no es malo; a veces del desorden sale la herramienta superadora.

---

## 2. 🔴 Ruby: `module`

Hacé Control-F en la documentación de Ruby. ¿"mixin"? No aparece. ¿"trait"? Tampoco. Lo que hay es **`module`**.

```ruby
module Atacante                 # así se define
  attr_accessor :potencial_ofensivo
  def atacar(un_defensor); ...; end
end

class Guerrero
  include Atacante              # así se incorpora
end
```

Pasalo por los criterios, pregunta por pregunta:

| Criterio | Ruby `module` | |
|---|---|---|
| ¿Granularidad a nivel módulo o método? | **Módulo.** Incluís el paquete entero; no elegís métodos | ✔ mixin |
| ¿Puede definir estado? | **Sí.** `attr_accessor` y `@variables` adentro de un módulo funcionan | ✔ mixin |
| ¿La resolución de conflictos es automática? | **Sí.** El último incluido gana, sin que escribas nada | ✔ mixin |
| ¿Se lineariza? | **Sí.** `ancestors` te muestra la lista | ✔ mixin |
| ¿`super` es dinámico? | **Sí.** Va al siguiente de la lista | ✔ mixin |

Es suficiente. **Los módulos de Ruby son mixins.** No hay discusión ni en la comunidad de Ruby ni afuera.

¿Por qué no se llaman mixins entonces? Porque el creador del lenguaje no se molestó en leer a Bracha antes de implementarlo: hizo la herramienta, le puso `module`, y listo. Ruby tiene varias inconsistencias de nombres por el estilo —vas a ver más en metaprogramación—, y esta es una. Pero **en el momento de diseñar, las herramientas y los patrones que aplican son los de mixins.** Lo que sirve para mixins te sirve en Ruby.

---

## 3. 🔴 Scala: `trait`

Ahora Control-F en la documentación de Scala. Ahí sí aparece una palabra: **`trait`**.

```scala
trait Atacante {              // así se define
  var potencialOfensivo: Int = 0
  def atacar(unDefensor: Defensor) = { ... }
}

class Guerrero extends Defensor with Atacante   // así se incorpora
```

Mismas preguntas:

| Criterio | Scala `trait` | |
|---|---|---|
| ¿Granularidad? | **Módulo.** Se incorpora entero con `with` | ✔ mixin |
| ¿Estado? | **Sí.** Un trait puede declarar `var` y `val` | ✔ mixin |
| ¿Resolución automática? | **Sí**, por linearización — con una salvedad (abajo) | ✔ mixin |
| ¿Se lineariza? | **Sí.** `extends A with B with C` se lee de derecha a izquierda | ✔ mixin |
| ¿`super` dinámico? | **Sí.** Un `super` dentro de un trait va al siguiente de la linearización | ✔ mixin |

**Los traits de Scala son mixins.** A pesar del nombre. Y no es un descuido: esta discusión está en la propia documentación de Scala. El autor del lenguaje tiene su empresa, empuja el desarrollo, le gustó la palabra *trait*, y la usó. Solo porque Ducasse llegó primero no quiere decir que tenga patentado el término: lo que había era un acuerdo civil sobre qué significaba, y **las herramientas que vos nombrás pesan tanto como la herramienta que tenés.** Si tu lenguaje lo usa gente, tu nombre gana.

La salvedad de la resolución automática es la que viste en la Parte 2, Sección 7: Scala lineariza, pero **si dos traits traen el mismo método, te obliga a sobreescribirlo en la clase y decidir**. Es automático en la mecánica y manual en la confirmación. Lo vas a sufrir en la segunda mitad de la cursada.

Y fijate lo raro del resultado: **una herramienta que vino después, a resolver un problema de la otra, y perdió.** Scala y Ruby son posteriores a la discusión mixins-vs-traits; los dos tuvieron la opción y los dos eligieron mixins.

---

## 4. 🟡 Java: interfaces con métodos por default

Java ya tenía **interfaces**: un concepto anterior a toda esta discusión, necesario para tener polimorfismo en un lenguaje de objetos tipado. Y en algún momento, cuando ya estaba clarísimo que todos los lenguajes montados sobre su máquina virtual —Scala entre ellos— tenían una alternativa, Java dijo: vamos a poner **interfaces con métodos por default**. A partir de cierta versión, a una interfaz le podés poner un método con cuerpo, y si la clase no tiene su propia implementación, se usa esa: por eso *por default*.

Mismas preguntas, y acá empieza a doler:

| Criterio | Java, interfaz con `default` | |
|---|---|---|
| ¿Granularidad? | **Módulo.** Implementás la interfaz entera | ~ mixin |
| ¿Estado? | **No.** Una interfaz no define atributos | ~ trait |
| ¿Resolución automática? | **Ni una cosa ni la otra.** Si dos interfaces traen el mismo `default`, estás obligado a escribir el método en la clase y elegir a mano: `Interfaz.super.m()`. Es manual, pero sin álgebra: un rodeo local | ~ trait |
| ¿Se lineariza? | **No.** El lookup se hace solo por la jerarquía directa de clases; las interfaces no están en la cadena | ✗ |
| ¿Se aplana? | **Tampoco.** El conflicto queda resuelto contra algo que no está en la jerarquía, pero que existe: si aplanaras, perderías la capacidad de hacer ese llamado | ✗ |
| ¿`super` dinámico? | **No.** El `super` sigue siendo el de la herencia. `Interfaz.super.m()` es un llamado nominal, no dinámico | ~ trait |

Entonces, ¿qué tiene Java? **Lo que podía agregar sin tocar su máquina virtual.** Ni linearización ni aplanado; una resolución manual usando, en lugar de un álgebra, una suboperación del mecanismo anterior.

Si te ponen un revólver en la cabeza y te hacen elegir: **ponele que traits.** ¿Es traits? No. No es traits. Pero si la pregunta es "¿cómo diseño con esto?", la respuesta es: **como con traits**. No vas a poder usar los patrones de mixins, porque el núcleo de esos patrones es que el módulo está vivo en la jerarquía y se puede cablear con `super` después. Acá no.

---

## 5. 🟡 Kotlin: lo que tiene Java

Kotlin es un lenguaje montado sobre la máquina virtual de Java, posterior a Scala, que robó bastante de Scala y de C#. ¿Qué tiene para esto? **Lo mismo que Java.**

Y acá está lo interesante como criterio. Java estaba limitado: tenía que hacer funcionar algo *sin cambiar su máquina virtual*. **Kotlin no tenía esa limitación** —igual que Scala, trabaja en un modelo propio por encima de la VM y podía hacer lo que quisiera— y aun así tomó el camino de menor resistencia: *"a los de Java les alcanza, listo"*. Fue cauto exactamente donde podría haber sido audaz. Comparado con Scala, que se anima a muchas más cosas, es olvidable en este aspecto.

La lección no es sobre Kotlin: es que **tener libertad técnica no garantiza que se use.**

---

## 6. 🟡 Python: herencia múltiple

Python no tiene mixins ni traits. Tiene **herencia múltiple**, y la resuelve linearizando de la misma manera que Ruby.

¿Cómo pudo? Porque tiene **su propia máquina virtual**, con su propia gestión de memoria, sin errores heredados de nadie. No necesitaba colgarse de una VM pensada para herencia simple, así que pudo hacer los cambios que quería, y entonces **no necesitó una herramienta accesoria.**

> ⚠️ **Advertencia.** La opinión explícita de la cátedra: la herencia múltiple de Python es **objetivamente mejor** que mixins y que traits. ¿Por qué? Porque **no hay un concepto que discuta el rol de la entidad**: son clases. Querés combinar más de una, combinás más de una. Linearizás igual, resolvés igual, pero la pregunta "¿cuándo uso uno y cuándo el otro, y qué le queda a la clase?" **no existe**, porque el concepto es único, es integral, y cruza todo. A veces tener más cosas no es mejor: a veces necesitás una cosa correcta que se comporte de la forma correcta. Y toda la discusión "el rombo no se puede resolver" sigue repitiéndose hoy contra la evidencia de Python funcionando en sistemas productivos a gran escala. **Para el examen:** Python resuelve el problema con herencia múltiple linearizada; no tiene mixins ni traits como construcción separada.

¿Por qué entonces vemos Ruby y Scala y no Python? Porque **lo común hoy es herencia simple con mixins o herencia simple con traits.** Si caés en una tecnología de objetos, es muy probable que sea una de esas dos. Python es minoría en ese sentido, y ojalá no lo fuera.

---

## 7. 🟡 JavaScript: prototipado, y mixins como patrón

JavaScript durante muchos años no tuvo clases: tuvo **prototipado**. Es una construcción muy poderosa, una definición *célula madre*: si no te importa escribir un poco de basura en el medio, podés trabajar como si tuvieras clases. Durante mucho tiempo la gente se mintió a sí misma que tenía herencia, escribiendo prototipado como si lo fuera. Y de hecho **la herencia simple es un caso particular de uso del prototipado.**

Hoy JavaScript sí tiene clases, con herencia simple tradicional. Y para esto, ¿qué tiene? **Un patrón de diseño.** No hay una construcción que se llame mixin. Lo que se hace es una **función que recibe una clase y devuelve otra clase a la que le inyectó métodos.** Eso es un mixin en el sentido más literal de Bracha —una función de clases— y a la vez se parece a un trait porque *está aplanando*. Pero no aplana del todo, porque devuelve una clase nueva que existe en runtime. Es una combinación rara, sumamente interesante, y **no requiere cambiar absolutamente nada en la máquina**: el motor ni se entera de que no está usando prototipado como siempre.

> 🕳️ **Madriguera — Prototipado**
> Con prototipado podés implementar cualquiera de las otras construcciones: es poderoso y es desprolijo. Hay un TP que a veces se hace con prototipos, y a veces una clase sobre ese código. No es tema de esta unidad.
> *Volvé al camino.*

---

## 8. 🔴 La foto completa

| | Ruby `module` | Scala `trait` | Java `interface default` | Kotlin | Python | JavaScript (patrón) |
|---|---|---|---|---|---|---|
| **Granularidad** | Módulo | Módulo | Módulo | Módulo | Clase | Módulo |
| **Estado** | Sí | Sí | No | No | Sí | Sí |
| **Resolución** | Automática | Automática (con confirmación obligada) | Manual, sin álgebra | = Java | Automática | Según el patrón |
| **Runtime** | Linearización | Linearización | Ni lineariza ni aplana | = Java | Linearización | Aplana (a medias) |
| **`super`** | Dinámico | Dinámico | Jerárquico (+ nominal) | = Java | Dinámico | Jerárquico |
| **Veredicto** | **Mixins** | **Mixins** | *Ponele que traits* | *Ponele que traits* | Herencia múltiple | Híbrido |

La fila que decide en la práctica es **Runtime + `super`**: si el módulo está vivo en la cadena y `super` lo sigue, tenés mixins y todos sus patrones; si no, diseñás como con traits.

---

## 9. 🟡 Por qué traits no es más popular, si es "mejor"

Vale la pena detenerse en esto porque es el tipo de pregunta que la materia hace todo el tiempo.

**Traits es indiscutiblemente más flexible.** Combina a nivel de método, y eso te da más granularidad que cualquier otra cosa. Y **es más fácil de incorporar**: aplana, mantiene la jerarquía de clases intacta, no toca la máquina virtual. Un compilador puede meter traits sin que el runtime se entere.

Y sin embargo, salvo las tecnologías que se quedan con lo mínimo indispensable, las que adoptan traits tienden a ser las más restringidas, y **no se popularizó**. ¿Por qué?

Porque **no es obvio que resolver un problema del modelo anterior te haga mejor.** Eso solo se cumple si además mantenés todos los otros estándares. Traits resolvió "los mixins no encajan" al precio de que cada inclusión se paga con glue code, y de que perdés el `super` dinámico. Y la pregunta que casi nadie se hace cuando alguien le dice *"esto es más flexible"* es: **¿yo necesitaba flexibilidad? ¿Esa era la variable que había que tocar? ¿Qué pierdo por trabajar así?**

> 🕳️ **Madriguera — Por qué se enseña Newton y no Einstein**
> El paradigma de Einstein explica más cosas. Se enseña Newton porque es más útil para los problemas que uno tiene: calcular integrales triples para ver si una manzana llega a una paloma es un poco mucho. **No hay una buena razón para cambiar de paradigma a menos que el nuevo atienda lo que vos necesitás.** Esa es la analogía completa; el resto es física.
> *Volvé al camino.*

---

## 10. 🟡 Qué van a hacer las tecnologías de acá en adelante

Ideas como estas van y vienen: los nombres, los títulos, las combinaciones particulares de propiedades. Que algo funcione bien en conjunto no lo convierte en ley natural. ¿Qué van a hacer las tecnologías nuevas? **Una de tres:**

1. **Optar por alguna de las opciones existentes** —mixins, traits, herencia múltiple.
2. **Delegar en la plataforma que tienen abajo** —lo que hizo Kotlin.
3. **Inventar alguna combinación loca de soluciones** —lo que hizo JavaScript.

Lo que **no** van a poder hacer es escaparse de las preguntas de fondo, porque son parte de la dinámica del problema, no de la herramienta:

- **El conflicto existe y hay que atenderlo.** Podés resolverlo, no resolverlo, resolverlo automáticamente, resolverlo a mano. Pero una respuesta vas a tener que tener, y esa respuesta cambia cómo diseñás.
- **Las cosas existen en runtime o no existen.** O existen con otra forma, o con otro contrato. Es una pregunta que hay que responder.

Podés ser la herramienta más loca del mundo, pero no te podés ir de los ejes de la realidad. Y si sabés qué implica trabajar de una forma o de la otra, **no importa qué combinación loca te toque: no tenés que reaprender a programar en cada herramienta nueva.** Hacés un poco de filosofía sobre cómo se combinan, y fuera de eso tenés algo más o menos directo.

### El criterio como ventaja

Un día Java no tenía ninguna de las dos herramientas. Al día siguiente tenía interfaces con métodos por default, y vos —que ya sabías lo que había abajo— la sabías usar sin haberla visto nunca: *"esto se parece a esto, pero tiene tal otra cosa; esto se puede hacer; esto casi, pero no"*. Así se construye criterio. Y en algún momento te va a tocar trabajar con algo que no tiene nada parecido a esto, vas a agarrar todo lo que sabías y vas a aprender de nuevo.

**Lo peor que te puede pasar es sentirte tan cómodo con una herramienta que ya no seas capaz de ver otras.** Las herramientas van a cambiar independientemente de lo que quieras, y a veces para mal. Tu primer impulso frente a una nueva va a ser el rechazo, y es normal: es como dejar el cigarrillo, se deja todos los días. A veces las cosas son una porquería de verdad; muchas otras hay una razón, y vos solo estás incómodo porque no la sabés usar.

> 🕳️ **Madriguera — Cómo cambian los paradigmas**
> No cambian cuando aparece la idea mejor: cambian cuando la inercia se agota —cuando el último que defendía lo anterior deja de tener tracción y a alguien le conviene lo nuevo. Se ve clarísimo en la historia de los frameworks de interfaz de usuario de los últimos años, que dieron vueltas de 180 grados varias veces. Es contexto, no contenido.
> *Volvé al camino.*

---

## 📝 Para el parcial, si te preguntan

**¿Los módulos de Ruby son mixins o traits? Justificá.**
Mixins. Granularidad a nivel módulo (se incluye entero), definen estado, resuelven conflictos automáticamente por linearización (el último `include` gana), existen en runtime (`ancestors` los muestra) y `super` es dinámico (va al siguiente de la lista). El nombre `module` no importa: la clasificación se hace contra los criterios, no contra la palabra clave.

**¿Y los traits de Scala?**
También mixins, a pesar del nombre: mismos cinco criterios. La única diferencia práctica es que Scala, por ser tipado, obliga a sobreescribir explícitamente en la clase cuando dos traits traen el mismo método: la resolución es automática en la mecánica y manual en la confirmación.

**¿Qué tiene Java para esto y a qué se parece?**
Interfaces con métodos por default. Granularidad módulo, sin estado, resolución manual sin álgebra (`Interfaz.super.m()` en la clase), sin linearización ni aplanado, `super` jerárquico. No es ni mixin ni trait; para diseñar, se parece más a traits porque no hay módulo vivo en la cadena ni `super` dinámico.

**¿Para qué sirve clasificar una tecnología si nunca encaja del todo?**
Para saber con qué herramientas de diseño contás adentro: qué patrones aplican, dónde va el estado, qué le tenés que enseñar al equipo. La etiqueta importa menos que la respuesta a "¿cómo diseño con esto?".

---

## ✅ Checkpoint parcial — Parte 3

*Sin respuestas.*

1. Te dan una tecnología nueva. ¿Cuáles son las dos preguntas de la tabla que decidís primero, y por qué esas?
2. ¿Por qué Scala y Ruby, siendo posteriores a la discusión, eligieron mixins y no traits?
3. Explicá por qué las interfaces con `default` de Java no linearizan *ni* aplanan.
4. ¿Qué tenía Kotlin que Java no tenía, y por qué no lo usó?
5. ¿Por qué la cátedra considera superadora la herencia múltiple de Python, y qué pregunta de esta unidad desaparece con ella?
6. El patrón de mixins de JavaScript: ¿en qué se parece a un mixin de Bracha y en qué a un trait?
7. Nombrá las dos preguntas de fondo de las que ninguna tecnología puede escaparse.

---

**FIN DE LA PARTE 3 — Qué tiene cada tecnología**
