# Clase desde cero — Type arguments y varianza en Scala — Módulo 0: El proyecto en el que trabajamos

**Unidad:** clase08 · **Lenguaje:** Scala 3.3.1 · **Densidad:** 🟢 operativo; se consulta, no se estudia

---

## Sobre este documento

**Qué cubre.** Qué hay en el proyecto de referencia de la unidad (`fuente-repo-clase08-type-arguments-y-varianza.md`), para qué sirve cada archivo, en qué módulo aparece, cómo se corren las apps y los tests, y la única diferencia entre lo que los módulos van a construir y lo que el código final tiene.

**Qué no cubre.** Cómo se instala el entorno ni cómo se arma un proyecto sbt: eso es el Módulo 0 de la unidad anterior. Tampoco explica el código: eso son los módulos 1 a 9.

## De dónde venís

Del Módulo 0 de la clase anterior: un proyecto sbt tiene `build.sbt`, `project/build.properties`, el código en `src/main/scala` y los tests en `src/test/scala`; un `object … extends App` se corre como aplicación; un test de ScalaTest se corre desde IntelliJ o con `sbt test`.

---

## 1. 🟢 Qué hay en el proyecto

> El proyecto de referencia es **el estado final** de la unidad: todo compila, todo corre, los 23 tests pasan. Los módulos lo construyen pieza por pieza, y cada pieza termina exactamente como está acá.

```
tadp-clase08-type-arguments-y-varianza/
├── build.sbt                         Scala 3.3.1, ScalaTest 3.2.19
├── .gitignore
├── project/build.properties          sbt 1.9.0
└── src/
    ├── main/scala/tadp/granja/
    │   ├── Animales.scala            Animal, Vaca, VacaLoca, Caballo
    │   ├── Granero.scala             un objeto que no es animal
    │   ├── Aves.scala                Ave, Avestruz
    │   ├── Corral.scala              Corral[+T <: Animal], Pastor, Lechero
    │   ├── MiLista.scala             MiLista[+T], Vacia, Nodo
    │   ├── Printer.scala             Printer[-T], AnimalPrinter, VacaLocaPrinter
    │   ├── GranjaApp.scala           app: tipado, colecciones, corral, varianza, MiLista
    │   ├── GranjaApp2.scala          app: las funciones g a k
    │   └── GranjaApp3.scala          app: el Printer
    └── test/scala/tadp/granja/
        └── GranjaTest.scala          23 tests
```

Todo vive en el paquete `tadp.granja`. Un **paquete** es el nombre bajo el que se agrupan las clases de un proyecto: la primera línea de cada archivo, `package tadp.granja`, dice que `Animal` se llama, con nombre completo, `tadp.granja.Animal`. Así lo va a escribir el compilador en sus mensajes de error, y así lo vas a ver en los módulos.

## 2. 🟢 Qué archivo usa cada módulo

> Cada archivo del proyecto se construye o se usa en módulos concretos; esta tabla dice en cuáles.

| Archivo | Qué es | Dónde se construye o se usa |
|---|---|---|
| `Animales.scala` | La jerarquía: `Animal` (`peso`, `come`, `estaGordo`), `Vaca` (`ordeñate`), `VacaLoca` (`reite`), `Caballo` (`relincha`) | M1, y todo lo demás |
| `Granero.scala` | `Granero` con `granos`. Existe para ser "una cosa que no es animal" | M2 |
| `Aves.scala` | `Ave` (`vola`, `come`) y `Avestruz`, que al volar lanza una excepción | M1 |
| `Corral.scala` | El corral terminado, `Pastor` y `Lechero` | Se construye en M3 y M4, se termina en M8 |
| `MiLista.scala` | Una lista inmutable y covariante escrita desde cero | Se construye en M7, se termina en M9 |
| `Printer.scala` | Un tipo contravariante y dos implementaciones | M6 |
| `GranjaApp.scala` | Las líneas que compilan de todo lo anterior, con su salida | M1, M2, M3, M4, M5, M8, M9 |
| `GranjaApp2.scala` | `f: Vaca => Vaca` y las funciones `g`, `h`, `i`, `j`, `k` | M6 |
| `GranjaApp3.scala` | `Printer[VacaLoca] = new AnimalPrinter` | M6 |
| `GranjaTest.scala` | 17 tests de comportamiento y 6 de "esto no compila" | El módulo que explica cada uno lo nombra |

## 3. 🟢 Cómo correrlo

> Cada app se corre sola; los tests se corren todos juntos. Lo que imprime cada app está en el archivo de referencia, sección "Salida de las apps".

- **Una app en IntelliJ:** abrir `GranjaApp.scala` y usar el botón de ejecución junto a `object GranjaApp`. Lo mismo para `GranjaApp2` y `GranjaApp3`.
- **Los tests en IntelliJ:** abrir `GranjaTest.scala` y ejecutar la clase entera; aparecen 23 tildes verdes.
- **Desde la terminal, en la carpeta del proyecto:** `sbt run` pregunta cuál de las tres apps correr; `sbt test` corre los 23 tests.

Si una línea de un módulo dice `// Resultado: …`, ese resultado sale de pegar la línea en una app y correrla. Si dice que **no compila**, el mensaje que figura es el que el compilador imprime en 3.3.1; pegarla en el proyecto lo reproduce, con dos detalles de forma. Primero: en los mensajes `Found: (vacas : …)`, el nombre aparece a secas cuando la línea está adentro de un método (por ejemplo, dentro de `main`), y con el objeto adelante (`(tadp.granja.GranjaApp.vacas : …)`) cuando es un miembro del `object`; los módulos lo escriben a secas. Segundo: a veces el compilador agrega al final una sugerencia `- did you mean …?`, que los módulos omiten y que se puede ignorar.

## 4. 🟢 La única diferencia entre los módulos y el código final: el `Set`

> Los módulos 3, 4 y 5 usan `scala.collection.mutable.Set`, un conjunto al que se le pueden agregar elementos con `add`. El código final usa el `Set` de siempre, que es inmutable, y adentro del corral usa `List`.

Scala tiene dos familias de colecciones. Las **inmutables** son las que usás tal cual, sin `import`: `Set(1, 2)`, `List(1, 2)`. Una vez creadas no cambian; "agregar" devuelve una colección nueva. Las **mutables** se importan a propósito (`import scala.collection.mutable.Set`) y sí cambian: `conjunto.add(x)` modifica ese mismo conjunto.

Los módulos 3 a 5 necesitan la mutable por una razón concreta: el argumento central de la unidad (por qué un conjunto de vacas no es un conjunto de animales) se construye agregándole un caballo a un conjunto que otra referencia cree que es de vacas. Ese programa necesita un conjunto modificable. Cuando el argumento esté hecho, el Módulo 5 muestra por qué la solución es una colección inmutable, y el Módulo 8 deja el corral con `List`, como está en `Corral.scala`.

Cuando en un módulo veas `import scala.collection.mutable.Set` al principio de un bloque, es eso. Cuando no lo veas, es el `Set` inmutable.

---

## Qué viene después

El Módulo 1 arranca con la jerarquía de `Animales.scala` y una pregunta que parece resuelta: qué se puede guardar en una variable de tipo `Vaca`, y qué mensajes se le pueden mandar.

**FIN DEL MÓDULO 0**
