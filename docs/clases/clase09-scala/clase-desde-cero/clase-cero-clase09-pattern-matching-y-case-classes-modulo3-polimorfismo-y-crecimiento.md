# Clase desde cero — Pattern matching, case classes y el híbrido objeto-funcional — Módulo 3: Polimorfismo y las dos direcciones de crecimiento

**Unidad:** clase09 · **Lenguaje:** Scala 3.3.1 · **Archivo del proyecto:** `figuras/Figuras.scala` · **Densidad:** 🔴 una sesión con el código abierto

---

## Sobre este documento

**Qué cubre.** La tercera idea de objetos, el **polimorfismo**: qué es (y qué no alcanza para que haya), cómo se ve en el ejemplo de figuras, y la pregunta que ordena toda la unidad: **¿hacia dónde crece un programa?** Cuando aparece una estructura nueva, objetos crece fácil. Cuando aparece una operación nueva, crece mal. El módulo muestra las dos cosas sobre el mismo ejemplo, contra la alternativa que objetos te enseñó a tachar: preguntar el tipo desde afuera.

**Qué no cubre.** Funcional como paradigma (Módulo 4) ni la herramienta `match` de Scala (Módulo 6). Acá la alternativa al polimorfismo se escribe con lo que ya conocés: `isInstanceOf`.

## De dónde venís

Del Módulo 2: encapsulamiento, delegación, el doble despacho de los tanques, que delegar bien le da a cada objeto un lugar para participar, y `???` (un cuerpo pendiente que explota si se ejecuta). De la clase07: `trait` como contrato, `extends`, `isInstanceOf` (preguntar el tipo en ejecución), `Any` (el tipo de cualquier cosa) y por qué el compilador revisa que una clase cumpla su contrato. De Ruby: el polimorfismo "por duck typing", sin contrato declarado.

---

## 1. 🔴 Polimorfismo: usar objetos distintos de la misma forma

> Hay polimorfismo cuando **un objeto usa a dos o más objetos de forma indistinta**, con el mismo propósito. Que entiendan el mismo mensaje es un requisito, y no alcanza.

El ejemplo más chico. Un contrato `Figura` que promete un área, y dos figuras que lo cumplen cada una a su manera (en el proyecto, `figuras/Figuras.scala`). La última línea es una función definida directamente en el archivo, fuera de toda clase; Scala 3 lo permite, y se usa con su nombre: `imprimirArea(…)`.

```scala
package tadp.figuras

trait Figura {
  def area: Double
}

class Circulo(val radio: Double) extends Figura {
  def area: Double = Math.PI * radio * radio
}

class Rectangulo(val ancho: Double, val alto: Double)
  extends Figura {
  def area: Double = ancho * alto
}

def imprimirArea(figura: Figura): Unit = println(figura.area)
```

En Scala, el contrato tiene nombre (`Figura`) y cada clase declara que lo cumple; en Ruby alcanzaba con entender el mensaje.

```scala
import tadp.figuras._

imprimirArea(new Circulo(1))        // Resultado: 3.141592653589793
imprimirArea(new Rectangulo(3, 4))  // Resultado: 12.0
```

Fijate qué tienen distinto las dos figuras: atributos distintos (uno tiene radio; el otro, ancho y alto), cuentas distintas, una tiene más estado que la otra. Y qué tienen en común: las dos responden `area`. `imprimirArea` está escrita **para una `Figura`**, y le delega el cálculo: "dame tu área, nada más". No le importa qué figura es.

Mañana aparece un pentágono:

```scala
class Pentagono(val lado: Double, val apotema: Double) extends Figura {
  def area: Double = 5 * lado * apotema / 2
}

imprimirArea(new Pentagono(2, 1))   // Resultado: 5.0
```

¿Qué hubo que tocar de `imprimirArea`? Nada. Ni de `Circulo`, ni de `Rectangulo`. Se agregó una clase y el resto del programa la usa sin enterarse. **Esa es toda la idea de objetos sobre cómo crece un programa.** Objetos le pone la lógica a los datos; cuando los datos cambian, aparecen formas nuevas de lógica que vienen de estructuras nuevas, y la propuesta es que cada estructura nueva traiga la suya sin reescribir el resto. Las secciones 3 y 4 la ponen a prueba.

Es el punto de extensión que dejó abierto el Módulo 2: `imprimirArea` delega el cálculo en la figura, y por ese lugar entra el pentágono sin tocar nada. Si `imprimirArea` hubiera calculado el área ella misma, mirando los atributos de cada figura, cada figura nueva la obligaría a cambiar. El acceso uniforme del Módulo 2 juega el mismo papel: si una figura guardara su área en un `val area` y otra la calculara, `imprimirArea` las usaría igual.

**Requisito, y no alcanza.** Una paloma y un avión entienden "volar". ¿Son polimórficos? Para el aeropuerto, no: nadie diseñó una pista para que aterricen las dos. Lo que hace polimórficos a dos objetos es la **intención** de que un tercero los use para el mismo propósito. Por eso **el polimorfismo se diseña**: nadie se encuentra por casualidad con dos objetos polimórficos. Alguien decidió el contrato (`Figura`) y alguien lo cumplió en cada clase.

## 2. 🟡 Tres polimorfismos con el mismo nombre

> "Polimorfismo" (muchas formas) es una palabra que todos los paradigmas usan para cosas distintas. El de objetos es el **polimorfismo de subtipado**.

| Nombre | Dónde lo ves | Qué significa |
|---|---|---|
| **De subtipado** | Objetos | Un objeto se usa a través de su supertipo (`Figura`) y cada subtipo responde a su manera |
| **Paramétrico** | Funcional | Una operación decide qué hacer **mirando la forma** del dato que recibe (el Módulo 4 lo desarrolla) |
| **Ad-hoc** | Funcional | El otro polimorfismo de funcional; la unidad lo nombra y no lo desarrolla |

⚠️ **Trampa de nombres.** Vas a encontrar textos que llaman "ad-hoc" al polimorfismo de objetos. En esta materia, el de objetos es **de subtipado**, y "ad-hoc" y "paramétrico" quedan del lado funcional. Para el examen: respondé "de subtipado". Y "paramétrico" acá nombra algo distinto de los tipos paramétricos (`List[A]`) de la clase08, aunque compartan la palabra; el Módulo 4 lo retoma.

¿Por qué objetos le da tanta importancia al suyo? Porque objetos está diseñado para **crecer de una manera** particular, y el polimorfismo de subtipado es lo que hace que esa manera funcione.

## 3. 🔴 La alternativa: preguntar el tipo desde afuera

> Lo mismo que hace el polimorfismo se puede hacer con un **type check**: una función que recibe la cosa, pregunta "¿sos A? ¿sos B?" y elige qué hacer. Objetos elige la primera, y el porqué está en cómo crece cada una.

Una guía solo tiene sentido si existe otra forma de hacer las cosas, y existe. Es el problema de los tanques del Módulo 2: una operación que pregunta desde afuera "¿sos A? ¿sos B?". Hay una lógica para cada caso, y eso es parte del dominio: un alumno de intercambio quizá se inscribe a una materia de otra forma que un alumno común. Lo que se discute es si esa lógica se delega en el alumno o se elige desde afuera.

Dos estructuras, `A` y `B`, y dos operaciones, `m1` y `m2`. Cada operación tiene una implementación para `A` y otra para `B`: eso es indiscutible, es parte del dominio. La pregunta es **dónde se escribe** cada implementación.

```
           ┌ - - - - - ┐
           ¦     I     ¦
           ├ - - - - - ┤
           ¦   m1()    ¦
           ¦   m2()    ¦
           └ - - △ - - ┘
                 ¦
        ┌ - - - -┴- - - - ┐
     ┌──────┐          ┌──────┐
     │  A   │          │  B   │
     ├──────┤          ├──────┤
     │ m1() │          │ m1() │
     │ m2() │          │ m2() │
     └──────┘          └──────┘
```

Las dos versiones. **Azul** es la de polimorfismo; **rojo**, la del type check:

```scala
// AZUL — polimorfismo: cada estructura trae sus operaciones
trait I {
  def m1: String
  def m2: String
}
class A extends I {
  def m1: String = "m1 de A"
  def m2: String = "m2 de A"
}
class B extends I {
  def m1: String = "m1 de B"
  def m2: String = "m2 de B"
}
```

```scala
// ROJO — type check: cada operación trae sus casos
object TypeCheck {
  def m1(unI: Any): String =
    if (unI.isInstanceOf[A]) "m1 de A"
    else if (unI.isInstanceOf[B]) "m1 de B"
    else ???

  def m2(unI: Any): String =
    if (unI.isInstanceOf[A]) "m2 de A"
    else if (unI.isInstanceOf[B]) "m2 de B"
    else ???
}

TypeCheck.m1(new A)   // Resultado: m1 de A
TypeCheck.m2(new B)   // Resultado: m2 de B
```

Mirá la información que hay en cada lado. Es la misma: cuatro implementaciones (m1-A, m1-B, m2-A, m2-B). En azul están **agrupadas por estructura**: abrís `A` y ves todo lo que hace `A`. En rojo están **agrupadas por operación**: abrís `m1` y ves todos los casos de `m1`. Las dos funcionan. La diferencia aparece cuando el programa cambia.

Ese `if … else if … else` sobre el tipo es lo que en otros lenguajes se escribe con un `switch`:

```
switch (x) {
    case A: ...
            break;
    case B: ...
            break;
}
```

Y es lo que la bibliografía de objetos tacha con una flecha gorda: *switch statement* → **polimorfismo**. Siempre que veas un `switch` sobre el tipo, tachalo y poné polimorfismo. La sección siguiente explica por qué esa regla tiene fundamento.

## 4. 🔴 Aparece una estructura nueva: `C`

> Con polimorfismo, agregar una estructura es **agregar una clase**, y el resto del programa queda igual. Con type check, es **abrir cada operación** y agregarle un caso, entendiendo la operación entera.

Mañana aparece `C`, con su forma de hacer `m1` y `m2`.

**En azul**, agregás esto y terminaste:

```scala
class C extends I {
  def m1: String = "m1 de C"
  def m2: String = "m2 de C"
}

val cosas: List[I] = List(new A, new B, new C)
cosas.map(_.m1)   // Resultado: List(m1 de A, m1 de B, m1 de C)
```

Ni `A` ni `B` se enteran. Y si te olvidás de un método, el compilador te frena antes de correr:

```scala
class D extends I { def m1: String = "m1 de D" }
// ❌ class D needs to be abstract, since def m2: String in trait I is not defined
```

Para programar `C` necesitás saber cómo hace `C` las dos operaciones, y nada más. Nada de entender cómo las hacen `A` y `B`. Y eso importa, porque el cambio es el peor enemigo de un sistema: cada vez que metés mano en algo que funciona, podés estar introduciendo un error.

**En rojo**, hay que ir a `m1` y agregar un caso, ir a `m2` y agregar otro. Y si te olvidás de uno:

```scala
TypeCheck.m1(new C)   // Resultado: scala.NotImplementedError: an implementation is missing (compila; explota al ejecutar)
```

Compila, y explota cuando corre. ¿Es tan grave? Alguien podría decir: "son dos líneas; tengo que escribirlas en algún lado igual". Mirá lo que esconden esas dos líneas:

- **¿Cómo sabías que había que tocar `m1`?** Nadie te lo dijo. En azul, el contrato te lo exige; en rojo, `m1` está en algún lugar de las ciento cincuenta funciones del sistema. ¿Qué hacés? *Control F*, buscás "A" y rezás. ¿Y cómo sabés que encontraste todas? Mandás a producción, y tres semanas después revienta un caso que te olvidaste. Con `isInstanceOf`, nadie te avisa del caso que falta. Hay herramientas que sí avisan; el Módulo 6 muestra una.
- **Tocar una operación es entenderla entera.** El ejemplo de arriba es trivial: cada caso está encerrado en su rama. Una operación real tiene código común antes y después, una variable que se usa en dos casos, un `if` que excluye a alguno. Para agregar `C` sin romper nada tenés que entender `m1` para `A`, para `B` y para todo lo que comparten. Y si `m1` modifica estado, un error en el caso de `C` puede romper a `A` y a `B`.
- **El `break` olvidado.** En un `switch` clásico, cada caso termina con `break`. Agregás el caso de `C` debajo del de `B` y te olvidás un `break` que hasta ayer sobraba: ahora los `B` ejecutan también la lógica de `C`. Y quizá solo a veces, si hay un `if` en el medio. Ningún test lo detecta, porque los tests de `B` se escribieron cuando `C` no existía.
- **El scope compartido.** En un `switch`, todas las ramas comparten el mismo *scope* (el espacio donde viven las variables): una variable creada en un caso queda visible en el otro. El `match` de Scala (Módulo 6) no tiene ninguno de estos dos problemas.
- **Lo genérico deja de serlo.** Un pedazo de la operación que hacía lo mismo para `A` y `B`, sin preguntar el tipo, puede no valer para `C`. Hay que partirlo en casos, y reescribir también lo de `A` y `B`.
- **Borrar duele igual.** Si `C` desaparece, hay que encontrar todos sus casos para sacarlos.
- **Copiar y pegar empeora.** Si al agregar `C` ves que en `m1` se comporta casi como `A`, lo correcto es refactorizar (extraer lo común a una función). Copiarlo es más rápido hoy y peor cada vez que vuelva a pasar.

## 5. 🟡 Por qué objetos se comió a estructurado

> Objetos ganó, sin ser necesariamente mejor, porque **escala en paralelo**: cada estructura nueva es una pieza independiente que una persona programa sin saber nada de las otras.

Pensá en un equipo de diez personas que tiene que agregar diez tipos de placa a un sistema. En objetos: se juntan una vez, definen la interfaz común, y cada uno se lleva una placa. Cada uno programa su clase, con sus métodos, sin tocar el código de nadie. Si mañana aparece un problema con la placa siete, se sabe de quién es y quién sabe arreglarlo.

En estructurado: hay diez personas escribiendo en paralelo **las mismas funciones**, cada una agregando su caso. Cada vez que alguien integra lo suyo, pisa lo del otro. Hay que juntar diez versiones de cada función a mano. La lógica es igual de difícil en los dos casos; lo que cambia es el costo social de coordinar.

Por eso objetos reemplazó a estructurado en la industria, cosa que casi nunca pasa (cambiar un paradigma entero en sistemas que ya funcionan es carísimo). Y por eso la regla "nunca uses `switch`": quien te la enseñó no tiene nada contra esa sintaxis. Te está diciendo que si escribís así, tu sistema deja de crecer de esta manera, porque cada cambio obliga a re-entender la operación entera.

Objetos te deja programar de las dos maneras: con `isInstanceOf` (o, en Ruby, con `is_a?`, como en los multimethods de la clase05) podés escribir "si sos de tal tipo, hacé esto". La guía te dice que no lo hagas. Cuando se migraban programas de estructurado a objetos, encapsular los atributos con getters era la parte fácil; **la difícil era encontrar todos los type checks y reemplazarlos por polimorfismo**.

**Para el parcial, si te preguntan:** *"¿Por qué en objetos se prefiere el polimorfismo al `switch`?"* Porque objetos espera crecer con **estructuras nuevas**: con polimorfismo, una estructura nueva es una clase nueva que implementa el contrato, y el resto del código queda intacto. Con un `switch` (o un type check), cada estructura nueva obliga a encontrar todas las operaciones que preguntan por el tipo, entender cada una entera y agregar el caso sin romper los demás.

## 6. 🔴 Aparece una operación nueva: `m3`

> Si en vez de una estructura aparece **una operación nueva**, los papeles se invierten: en rojo es **agregar una función**; en azul es **abrir cada clase** y entender toda la jerarquía.

Si cortaras acá, te irías convencido de que objetos siempre gana. Partí del sistema con `A`, `B` y `C`, con los casos de `C` ya agregados en `m1` y `m2`. Ahora lo que aparece es una operación: `m3`.

```
           ┌ - - - - - ┐
           ¦     I     ¦
           ├ - - - - - ┤
           ¦   m1()    ¦
           ¦   m2()    ¦
           ¦   m3()    ¦   ← nuevo
           └ - - △ - - ┘
                 ¦
     ┌ - - - - - ┼ - - - - - ┐
  ┌──────┐   ┌──────┐   ┌──────┐
  │  A   │   │  B   │   │  C   │
  ├──────┤   ├──────┤   ├──────┤
  │ m1() │   │ m1() │   │ m1() │
  │ m2() │   │ m2() │   │ m2() │
  │ m3() │   │ m3() │   │ m3() │   ← nuevo, en cada una
  └──────┘   └──────┘   └──────┘
```

**En rojo**, escribís una función nueva y terminaste:

```scala
def m3(unI: Any): String =
  if (unI.isInstanceOf[A]) "m3 de A"
  else if (unI.isInstanceOf[B]) "m3 de B"
  else if (unI.isInstanceOf[C]) "m3 de C"
  else ???
```

`m1` y `m2` quedaron igual. Para escribir `m3` tenés que saber cómo hace `m3` cada estructura, y nada más.

**En azul**, hay que agregar `def m3` en el trait y en **cada** clase. El compilador te avisa cuáles te faltan:

```scala
trait I { def m1: String; def m2: String; def m3: String }
class A extends I { def m1: String = "m1 de A"; def m2: String = "m2 de A" }
// ❌ class A needs to be abstract, since def m3: String in trait I is not defined
```

Y el aviso es lo de menos. Lo que cuesta es lo mismo que costaba en rojo, al revés:

- **Hay que entender toda la jerarquía.** Un método nuevo en una clase convive con su estado. Si `m3` modifica algo, tenés que saber cómo es el estado de `A`, de `B` y de `C`, y en qué combinaciones de estado se puede llamar, para que cada objeto siga consistente (la regla 1 del Módulo 2).
- **Hay que revisar si la jerarquía sigue bien armada.** Quizás `m3` hace lo mismo en `A` y en `C`, y eso pide subirlo a una superclase o sacarlo a un mixin. Agregar una operación puede mostrar que la herencia estaba mal planteada.
- **¿De quién es `m3`?** Si ninguna clase es la responsable natural de la operación, cualquier lugar donde la pongas es discutible.
- **¿Cuáles son las clases?** En Scala el contrato te las marca. En Ruby, con *duck typing* (un objeto sirve si entiende el mensaje, sin declarar contrato), "hay que agregar `m3` a los animales" abre la pregunta: ¿cuáles son los animales? ¿Los de peluche también? ¿La estatua del caballo? Cualquier objeto que en algún lugar se usa como animal es candidato, y para encontrarlos hay que leer todo el código o arriesgarte a que explote en ejecución. Es otro argumento para los tipos estáticos de la clase07.

Con herencia, a veces alcanza con una implementación de `m3` en una superclase que sirva para varias. El análisis de arriba supone el peor caso.

## 7. 🔴 La regla: cada uno crece fácil en una dirección

> **Objetos hace fácil agregar estructuras y caro agregar operaciones. El type check (y, como se verá, funcional) hace fácil agregar operaciones y caro agregar estructuras.** Para sorpresa de nadie: la tecnología que pone la lógica en los datos crece en datos; la que pone la lógica en las operaciones crece en operaciones.

| Aparece… | Azul (polimorfismo) | Rojo (type check) |
|---|---|---|
| una estructura (`C`) | una clase nueva; el resto intacto ✅ | un caso en **cada** operación; entender cada una ❌ |
| una operación (`m3`) | un método en **cada** clase; entender toda la jerarquía ❌ | una función nueva; el resto intacto ✅ |

¿Qué es más común en objetos? Que aparezca una entidad nueva que implementa distinto algo que ya existe. Una operación que flota de la nada para un conjunto arbitrario de cosas es rara. En el mundo de la otra columna, lo raro es lo inverso, porque las estructuras se piensan completas de entrada: una lista está vacía o tiene cabeza y cola, y nadie va a descubrir mañana una tercera forma de lista. Lo que sí aparece todo el tiempo es una operación más sobre listas.

Ahora volvé al Módulo 1. El micro tiene **siete instrucciones estables** y **operaciones que se multiplican** ("+500"). Es el dominio de la columna roja. Y la solución `puro` del Módulo 2 lo resolvió en azul: por eso su interfaz crece con cada operación.

Objetos sabe que esto es un problema, y no te lo cuenta. En ningún texto introductorio vas a encontrar "usá polimorfismo, salvo en este caso, donde te conviene el `switch`". ¿Por qué? Pensá a quién se lo estaban enseñando: a gente que venía de escribir `switch` toda su vida. Si le decís "a veces sí", va a usar el `switch` siempre, y nunca va a aprender polimorfismo. Entonces la doctrina introductoria dice: **polimorfismo, delegación, encapsulamiento**. Siempre. Esas tres ideas son el **triángulo azul** de objetos.

El Módulo 5 muestra lo que objetos hace cuando le toca este caso: un patrón de diseño con nombre. Antes, el Módulo 4 presenta el paradigma que crece del otro lado.

**Para el parcial, si te preguntan:** *"Te agregan una operación nueva sobre una jerarquía de diez clases. ¿Polimorfismo o type check?"* Depende de hacia dónde crece el dominio. Si lo esperable es que aparezcan **estructuras nuevas** y las operaciones son estables, polimorfismo: cada estructura nueva es una clase. Si lo esperable es que aparezcan **operaciones nuevas** sobre estructuras estables, conviene tener las operaciones afuera, cada una con sus casos: agregar una es escribir una función, sin tocar las diez clases. El criterio es el costo del cambio más probable.

---

## Checkpoint

1. Una paloma y un avión entienden `volar`. ¿Alcanza para que sean polimórficos? ¿Qué falta?
2. ¿Qué tuvo que cambiar en `imprimirArea` cuando apareció `Pentagono`? ¿Por qué?
3. ¿Cuál es el polimorfismo de objetos, y cuáles son los otros dos? ¿De qué lado quedan?
4. En el ejemplo `A`/`B`, ¿hay más información en la versión azul o en la roja? ¿Qué cambia entre las dos?
5. Aparece `C`. Enumerá lo que hay que hacer en cada versión y qué te avisa si te olvidás algo.
6. ¿Por qué agregar un caso a una operación obliga a entender la operación entera? Da dos razones.
7. ¿Qué tiene que ver el polimorfismo con que objetos haya reemplazado a estructurado en la industria?
8. Aparece `m3`. ¿Qué hay que hacer en cada versión? ¿Qué problema extra trae en Ruby?
9. ¿Por qué la doctrina introductoria de objetos dice "siempre polimorfismo" aunque sepa que a veces conviene lo otro?
10. ¿En qué columna de la tabla de la sección 7 cae el dominio del micro? ¿Qué dice eso de la solución `puro`?

## Qué viene después

**Módulo 4:** el triángulo rojo, las tres ideas de funcional. El paradigma que crece del lado de las operaciones: sus tres ideas, por qué cada una choca con una de las de objetos, y por qué hoy vuelve a importar.

**FIN DEL MÓDULO 3 — Polimorfismo y las dos direcciones de crecimiento**
