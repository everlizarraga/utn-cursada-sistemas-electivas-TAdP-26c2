# Clase desde cero — Pattern matching, case classes y el híbrido objeto-funcional — Módulo 4: El triángulo rojo

**Unidad:** clase09 · **Lenguaje:** Scala 3.3.1 (y un poco de Haskell) · **Archivo del proyecto:** ninguno, módulo conceptual · **Densidad:** 🔴 una sesión, con papel para dibujar los dos triángulos

---

## Sobre este documento

**Qué cubre.** Las tres ideas que guían a funcional (polimorfismo paramétrico, pureza y orden superior), puestas al lado de las tres de objetos; por qué se llevan mal, vértice contra vértice; qué se pierde en el camino (la identidad); y por qué, aun así, funcional vuelve a importar hoy. Es el marco teórico que los módulos 5 a 9 usan para leer código.

**Qué no cubre.** La sintaxis de `match` en Scala (Módulo 6) ni cómo se aplican estas ideas al micro (módulos 7 a 9). Los ejemplos de acá son chicos y sueltos.

## De dónde venís

Del Módulo 2: encapsulamiento y delegación, y que en estructurado los tanques eran fáciles porque un proceso recibía a los dos y les miraba el estado. Del Módulo 3: el polimorfismo de subtipado, el type check como su alternativa, y que cada uno crece fácil en una dirección. De la clase07 y la clase08: funciones anónimas (`n => n * 2`), el tipo `A => B`, `map` y `filter` sobre listas. De Paradigmas: Haskell, listas con `[]` y `(cabeza:cola)`, composición y aplicación parcial.

---

## 1. 🔴 Dos triángulos

> Esta materia resume cada paradigma en **tres ideas** que guían cómo se programa en él. Las de objetos forman el **triángulo azul**: polimorfismo, encapsulamiento y delegación. Las de funcional forman el **triángulo rojo**: polimorfismo paramétrico, pureza y orden superior.

```
               polimorfismo             orden superior**       pureza
                     /\                 __________________________
                    /  \                 \                      /    (falta de efecto
                   /    \                 \                    /      + transparencia
                  /      \                 \                  /         referencial)
                 /        \                 \                /
                /__________\                 \              /
        delegación    encapsulamiento         \            /
                                               \          /
                                                \        /
                                                 \      /
                                                  \    /
                                                   \  /
                                                    \/
                  OBJETOS               polimorfismo paramétrico
              (triángulo azul)              (pattern matching)
                                        FUNCIONAL (triángulo rojo)
```

(Los dos asteriscos de "orden superior" se explican en la sección 5.)

**El azul.** Los módulos 2 y 3 lo recorrieron entero. Fijate qué quedó afuera: "objeto" y "mensaje". Son las **herramientas** del paradigma; las ideas son las que te dicen cómo usarlas. Con objetos y mensajes mal usados se puede programar en estructurado, y los módulos anteriores lo mostraron (el data object, el `switch` con `isInstanceOf`). La herencia también quedó afuera: algunos autores la ponen entre las claves, y acá se elige no pensar en términos de herencia, que hoy es una construcción accesoria.

**El rojo.** Funcional es más difícil de resumir: los autores no terminan de ponerse de acuerdo en cuáles son sus características clave. Esta materia elige tres, y las secciones 3 a 5 las presentan una por una. Antes, la pregunta de por qué hace falta aprenderlas.

## 2. 🟡 Por qué funcional vuelve ahora

> Un paradigma ocupa **todo** el espacio que puede. Para sumarle funcional a objetos hay que romper algo: alguna regla que dice "siempre" tiene que pasar a decir "en estas circunstancias". Y vale la pena, porque los sistemas que escalan replicándose se traban en el estado, y funcional es la teoría de cómo trabajar sin él.

Juntar dos ideas que funcionan bien por separado no garantiza que funcionen juntas. Objetos tiene sus reglas, sus guías y su marco teórico completos; funcional, los suyos. Si los dos quedan intactos, el resultado es incoherente. Un paradigma es un gas: llena todos los huecos de la habitación, porque uno que deja huecos es una solución de propósito específico.

**Los que no pudieron.** Otros intentaron reemplazar a objetos y terminaron adentro de él. **Eventos** y **aspectos** llegaron de la mano de herramientas concretas, con la promesa de cambiar la manera de programar. Aspectos decía: "puedo definir cambios transversales a toda la arquitectura". Objetos respondió "eso se puede hacer con objetos", y se lo comió: aspectos terminó siendo frameworks de objetos (en el TP1 armaste uno chico, en Ruby). No eran lo suficientemente completos, ni lo suficientemente distintos.

**El que no se deja comer.** Objetos lleva años tratando de absorber funcional de a poco, y se atraganta. Funcional es mucho mejor que objetos para ciertas cosas, y justo ahora esas cosas son las que la industria necesita:

- Cuando objetos se impuso, cada empresa tenía su propio hardware. Hoy hay nubes de servidores, software como servicio, sistemas que tienen que andar igual de bien acá que en otro continente.
- Para que esas arquitecturas funcionen, el sistema tiene que poder **replicarse**: levantar otra copia en otro lado suele ser más fácil que hacer que una sola atienda más carga.
- Ahí aparecen los cuellos de botella: una base de datos centralizada que se bloquea porque dos quieren escribir al mismo tiempo. Y todos llevan a lo mismo: **estamos manipulando estado**.
- Alguien dijo "no sabemos trabajar sin estado; no hay teoría sobre cómo se hace". Había una: **funcional**. Pensar el programa como un camino de A a B, sin efectos que interfieran con otras operaciones en paralelo.

Las herramientas que vas a escuchar nombrar (actores, paralelismo, las "lambdas" de los servicios en la nube, que cada proveedor bautiza distinto y que nada tienen que ver con las funciones anónimas, aunque compartan el apodo) son, en el fondo, operaciones que parecen funciones, trabajando sobre datos pensados para replicarse y para no afectarse entre ellas. Se pueden modelar con objetos, y es el camino más largo: usar las herramientas de una tecnología para programar las ideas de otra. El Módulo 5 muestra cómo se ve eso.

## 3. 🔴 Polimorfismo paramétrico: decidir por la forma del dato

> **Polimorfismo paramétrico** es definir **formas** de datos y, para cada forma, qué lógica se ejecuta. La operación mira la forma desde afuera y elige. La herramienta que lo hace concreto es el **pattern matching**.

En Haskell lo hiciste desde el primer día. Una lista tiene dos formas posibles, vacía o cabeza-y-cola, y una función sobre listas dice qué hacer con cada una:

```haskell
largo :: [a] -> Int
largo []         = 0
largo (_ : cola) = 1 + largo cola
```

`largo` mira la forma del dato que recibe y elige una ecuación. La lista ignora que `largo` existe: es un dato, y punto. Es la forma más primitiva de trabajar en funcional: por debajo de eso ya no hay nada más que el dato. Todo programa funcional se construye sobre definir formas y decidir por ellas.

**Herramienta y concepto.** Pattern matching es la herramienta que *reifica* (vuelve concreto) el concepto. El concepto es otro: **trabajar mirando la forma del dato**. Se puede lograr con otras herramientas, y en el Módulo 3 lo hiciste con una muy pobre: una cadena de `isInstanceOf`. Esa cadena **es** polimorfismo paramétrico con una sintaxis pobre: como objetos busca otra manera de trabajar, sus lenguajes clásicos dejaron esa herramienta sin elaborar. Con la herramienta buena (Módulo 6) se ve así de natural: "si tenés la forma de A, hacé esto; si tenés la forma de B, hacé aquello".

Y es lo que el Módulo 2 dejó abierto: en estructurado, los tanques eran fáciles porque un proceso recibía los dos y les miraba el estado para decidir el daño. Mirar el estado desde afuera y decidir es polimorfismo paramétrico, la idea que pattern matching vuelve concreta. Para objetos, es un type check: **lo opuesto de polimorfismo**. Con dos datos, además, se miran las dos formas a la vez, y el doble despacho del Módulo 2 sobra. El Módulo 6 lo escribe.

⚠️ **Trampa de nombres.** Fuera de esta materia, "polimorfismo paramétrico" nombra lo de la clase08: una operación que anda para cualquier tipo (`List[A]`; la `[a]` de la firma de `largo` es eso). La materia usa el nombre para otra idea: decidir por la forma del dato. En el parcial, cuando la pregunta es sobre los triángulos, respondé con el sentido de esta sección.

## 4. 🔴 Pureza: falta de efecto + transparencia referencial

> **Pureza** es **falta de efecto** más **transparencia referencial**: el resultado depende solo de los parámetros, y la función produce el resultado y nada más. Es la idea de función en el sentido matemático.

Las dos partes, por separado:

- **Transparencia referencial:** el resultado depende solo de los parámetros; con los mismos parámetros, el mismo resultado, siempre.
- **Falta de efecto:** la función devuelve un resultado y nada más. El contexto queda igual: lo de afuera intacto, sin excepciones, sin salida por pantalla.

⚠️ **Trampa de definiciones.** Vas a encontrar una definición más fuerte de transparencia referencial: una expresión es transparente si se puede reemplazar por su resultado sin cambiar el programa. Esa ya incluye la falta de efecto. En esta materia, las dos partes se piden por separado.

```scala
def doble(x: Int): Int = x * 2

doble(3)   // Resultado: 6
doble(3)   // Resultado: 6
```

```scala
var llamadas = 0
def dobleConCuenta(x: Int): Int = {
  llamadas += 1                 // efecto: modifica algo de afuera
  x * 2 + llamadas              // y el resultado depende de ese algo
}

dobleConCuenta(3)   // Resultado: 7
dobleConCuenta(3)   // Resultado: 8
```

La primera es pura. La segunda tiene un efecto (cambia `llamadas`) y, por ese efecto, pierde la transparencia: la misma llamada da dos resultados.

**Un programa es un viaje de un dominio a una imagen.** En funcional, el programa se piensa como un recorrido desde un **dominio** (los datos de entrada) hasta una **imagen** (los de salida). "Promocionar a la camada de alumnos" es procesar los alumnos que entran para obtener cómo serían si hubieran promocionado. La operación construye los alumnos nuevos y deja intactos los originales.

**Objetos ya aprendió esto.** Lo que sabés de listas en objetos se parece a funcional por una razón: objetos copió de funcional cómo trabajar con listas. `map`, `filter`, `all`, `any` vienen de ahí.

```scala
val notas = List(4, 7, 9)
val subidas = notas.map(n => n + 1)

subidas   // Resultado: List(5, 8, 10)
notas     // Resultado: List(4, 7, 9)
```

Un `map` de objetos podría modificar la colección original; nada lo impedía. ¿Por qué devuelve una nueva? Porque casi siempre la original sigue haciendo falta, y una lista nueva es más práctica: te ahorra clonar la original para no romperla.

## 5. 🔴 Orden superior: la operación como individuo

> **Orden superior**, en esta materia, es la **operación como individuo de primer orden**: algo que se guarda en una variable, se pasa por parámetro, se devuelve y se transforma con otras operaciones. Es más que "una función que recibe una función".

El nombre lleva dos asteriscos (`orden superior**`) porque es de los peor elegidos: falta una palabra mejor, en inglés y en español. En Paradigmas, orden superior era "una función que recibe otra por parámetro". Acá es la generalización: la operación tiene la misma jerarquía que cualquier dato, y es el dato principal con el que se construye en funcional.

```scala
val porDos: Int => Int = n => n * 2
val masUno: Int => Int = n => n + 1

def aplicarDosVeces(f: Int => Int, x: Int): Int = f(f(x))
aplicarDosVeces(porDos, 3)                  // Resultado: 12

val operaciones: List[Int => Int] = List(porDos, masUno)
operaciones.map(f => f(10))                 // Resultado: List(20, 11)
```

Las operaciones están guardadas en variables, se pasan por parámetro y viven en una lista como cualquier otro valor.

**Composición y aplicación parcial son casos particulares.** Para aprobar funcional en Paradigmas había que saber composición, orden superior y aplicación parcial. Las tres son casos particulares de la operación como individuo:

- **Orden superior de Paradigmas:** recibir una función por parámetro. Es `aplicarDosVeces`.
- **Composición:** recibe dos funciones y devuelve otra que las encadena. Es una forma de secuenciar operaciones (y vas a ver otras). En Scala, `f.andThen(g)` devuelve la función "primero `f`, después `g`". Ojo con el orden: el `.` de Haskell aplica primero la de la derecha, así que `porDos.andThen(masUno)` es `masUno . porDos`.

  ```scala
  val porDosYMasUno = porDos.andThen(masUno)
  porDosYMasUno(5)                          // Resultado: 11
  ```

- **Aplicación parcial:** le pasás un parámetro y te devuelve otra función que espera el resto. `Int => Int => Int` se lee `Int => (Int => Int)`: recibe un `Int` y devuelve una función `Int => Int`. A eso se le dice función **currificada**. En Haskell todas lo son; en Scala hay que escribirla así.

  ```scala
  val sumar: Int => Int => Int = a => b => a + b
  val sumarCinco = sumar(5)                 // una función que espera el segundo número
  sumarCinco(10)                            // Resultado: 15
  ```

  Con los dos parámetros juntos, `def sumar(a: Int, b: Int)`, `sumar(5)` no compila.

Todas tratan a la función como un valor: la reciben, la devuelven, o las dos cosas. Eso es la operación como individuo; lo demás son usos. Objetos también tomó esto de funcional: los bloques de Ruby y las funciones anónimas son operaciones sueltas, sin un objeto que las contenga.

## 6. 🔴 Los triángulos se odian, vértice contra vértice

> Cada idea del triángulo rojo choca con la manera de trabajar de objetos. Ver la forma choca con **encapsulamiento**; la operación separada del dato es la **ausencia de delegación**; la pureza va más abajo: le quita al objeto **el control de su propio estado**.

| Rojo | Choca con (azul) | Por qué |
|---|---|---|
| Polimorfismo paramétrico | Encapsulamiento (y polimorfismo) | Para decidir por la forma hay que **ver** la forma. Encapsular es justamente esconderla. Y decidir por la forma es un type check, lo opuesto de polimorfismo |
| Orden superior | Delegación | La operación vive separada del dato. Más que dejar de elegir un responsable, **no hay manera** de asignarle la tarea a un dato. Y sin mensajes en el dato, tampoco hay a quién tratar polimórficamente |
| Pureza | El objeto dueño de su estado | Un objeto tiene interfaz, estado interno e identidad, y es el responsable de cambiar su estado. Si nada cambia, el objeto pierde esa responsabilidad, y con ella la identidad (sección 7) |

Lo que funcional propone, dicho con las palabras que objetos tacha: "yo te doy algo, vos lo mirás y decidís: si sos esto, hacés esto; si sos aquello, hacés aquello". Sin alternativa. Las entidades no son delegables, porque los datos son datos: en el mejor de los casos, un registro. Los tipos de datos son estructuras sueltas, sin jerarquía entre ellos.

## 7. 🔴 Lo que se pierde: la identidad

> Si la pureza prohíbe modificar, "cambiar" un dato es **crear otro**. Lo que une al viejo con el nuevo deja de ser una identidad: es que uno entró a una función y el otro salió.

En Haskell, ¿cómo le subías la nota a un alumno? Le pasabas el alumno a una función y te devolvía **otro**. Lo mismo en Scala, escrito a mano. Al final aparece `a eq b`, que pregunta si dos referencias apuntan al **mismo objeto** (identidad):

```scala
class Alumno(val nombre: String, val nota: Int)

def subirNota(alumno: Alumno): Alumno =
  new Alumno(alumno.nombre, alumno.nota + 1)

val ana = new Alumno("Ana", 6)
val curso = List(ana)
val anaSubida = subirNota(ana)

anaSubida.nota       // Resultado: 7
ana.nota             // Resultado: 6
curso.head.nota      // Resultado: 6
anaSubida eq ana     // Resultado: false
```

La respuesta es no: son dos estructuras que representan "a la misma alumna", y lo único que las relaciona es que una entró a `subirNota` y la otra salió. Y vos confiás en que esta es aquella.

Y mirá el curso. Seguía apuntando a la Ana vieja. Cualquier referencia guardada al dato anterior sigue apuntando al anterior. Para que el curso tenga la nota nueva, hay que construir **un curso nuevo** con la alumna nueva adentro. Si el curso estaba adentro de una carrera, una carrera nueva. Por eso en funcional conviene evitar guardarse referencias a cosas que van a cambiar.

En objetos, el objeto es el mismo y cambia por adentro. En funcional, un dato representa la cosa **ahora mismo**, y conviene soltarlo pronto: funcional es un viaje de acá hasta allá, sin cargar equipaje.

**Para el parcial, si te preguntan:** *"¿Con qué idea de objetos choca cada idea de funcional?"* Polimorfismo paramétrico (pattern matching) choca con **encapsulamiento**, porque necesita ver la forma del dato que encapsular esconde; además, decidir por la forma es un type check, lo opuesto de polimorfismo. Orden superior choca con **delegación**: la operación vive separada del dato y no hay forma de asignarle la tarea a uno. Pureza choca con que el **objeto sea dueño de su estado**: si nada se modifica, cambiar es crear otro dato, y se pierde la identidad.

## 8. 🟡 Funcional no es tonto

> Que funcional se vea torpe desde objetos dice más del punto de vista que de funcional. Cada triángulo crece fácil en una dirección distinta, y por eso se complementan. Además, funcional sabe trabajar sin estado, que es lo que hoy necesitan los sistemas que escalan replicándose.

Si leíste los módulos 2 y 3 y paraste ahí, te quedaste convencido de que objetos es superior y que todo lo demás está equivocado. Mucha gente se quedó en ese punto. Visto desde objetos, funcional eligió una forma de trabajar que objetos ya había demostrado inferior: mirar la forma desde afuera es el `switch` que objetos reemplazó. Y la historia parece confirmarlo: funcional existía antes que estructurado, nadie le prestó atención, y objetos ganó.

El problema es desde dónde lo mirás. Aprendiste la teoría desde objetos, con las herramientas y el marco teórico de objetos. Un delfín mira a un gorila (uno de los pocos mamíferos incapaces de nadar) y piensa: "qué torpe, se mueve en dos dimensiones, apenas". Sacá al delfín del agua, y el gorila lo mira y piensa: "qué torpe, ¿por qué no respira?".

Volvé a la tabla del Módulo 3. El polimorfismo de objetos hace fácil agregar estructuras y caro agregar operaciones. El pattern matching de funcional hace lo inverso. Los dos triángulos tienen falencias distintas, y por eso se complementan: donde uno es flojo, el otro suele ser fuerte. Combinarlos tiene sentido aunque sus ideas se odien, y la forma de combinarlos es la de la sección 2: decidir qué regla de objetos deja de decir "siempre".

**Para el parcial, si te preguntan:** *"Si las ideas de objetos y funcional son antagónicas, ¿para qué combinarlos?"* Porque cada uno es fuerte donde el otro es flojo. Objetos crece fácil en estructuras nuevas; funcional, en operaciones nuevas, y además trabaja sin estado, que es lo que hoy necesitan los sistemas que escalan replicándose. Combinarlos obliga a romper alguna regla de objetos (algún "siempre" pasa a ser "en estas circunstancias"), y elegir cuál es el criterio que la unidad construye.

---

## Checkpoint

1. Nombrá los tres vértices de cada triángulo. ¿Por qué "objeto" y "mensaje" están fuera del azul?
2. ¿Qué significa que "un paradigma es un gas"? ¿Qué obliga a hacer al combinar dos?
3. ¿Qué les pasó a eventos y a aspectos? ¿Por qué con funcional fue distinto?
4. ¿Qué relación hay entre replicar un sistema, los cuellos de botella y el estado?
5. Pattern matching, ¿es el concepto o la herramienta? ¿Qué es el concepto?
6. ¿Por qué la cadena de `isInstanceOf` del Módulo 3 es polimorfismo paramétrico? ¿Qué le falta?
7. Definí pureza con sus dos partes. ¿Qué parte rompe `dobleConCuenta` directamente, y cuál pierde como consecuencia?
8. ¿Por qué `map` devuelve una lista nueva, si nada lo obligaba?
9. ¿Qué agrega "la operación como individuo" a "una función que recibe una función"? ¿Dónde entran composición y aplicación parcial?
10. Completá la tabla de choques sin mirar: cada vértice rojo, con qué idea de objetos choca y por qué.
11. En el ejemplo de `subirNota`, ¿por qué el curso sigue teniendo la nota vieja? ¿Qué habría que hacer?
12. Explicá el delfín y el gorila con la tabla del Módulo 3.

## Qué viene después

**Módulo 5:** el Visitor. Lo que hace objetos cuando el dominio crece en operaciones: un patrón de diseño que saca las operaciones de la jerarquía. Con este módulo en la mano se puede leer como lo que es: el triángulo rojo armado con las piezas del azul.

**FIN DEL MÓDULO 4 — El triángulo rojo**
