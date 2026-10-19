# Clase desde cero — Type arguments y varianza en Scala — Roadmap

**Unidad:** clase08 (TADP, 2C 2026) · **Lenguaje:** Scala 3.3.1 · **Tipo de material:** clase desde cero, 9 módulos + 1 de orientación
**Qué es esto:** el índice de la clase. Dice qué necesitás tener a mano, en qué orden leer y por qué, qué dolor se siembra en un módulo y se cura en otro, cómo leer cada bloque, qué queda afuera y de dónde salió cada parte.

---

## Antes de empezar: dos cosas a mano

1. **El código final de la unidad**, en `fuente-repo-clase08-type-arguments-y-varianza.md`: un proyecto Scala completo con la granja (`Animal`, `Vaca`, `VacaLoca`, `Caballo`, `Granero`, `Ave`, `Avestruz`), el `Corral` terminado con `Pastor` y `Lechero`, una lista covariante propia (`MiLista`), el `Printer` contravariante, tres aplicaciones y veintitrés tests. Todo el código de los módulos converge ahí. El Módulo 0 lo recorre.
2. **La unidad anterior leída** (`clase-cero-clase07-tipado-estatico`, módulos 0 a 8). Esta clase se para sobre ella: subtipado, `trait` como contrato, `override`, `Any` y `Nothing`, falsos negativos, operaciones parciales, cast y la presentación de `List[A]`. No se re-explican. Y arranca con la pregunta que esa unidad dejó abierta: si `Persona` es subtipo de `Nombrable`, ¿`List[Persona]` es subtipo de `List[Nombrable]`?

## Qué vas a poder hacer al terminar

- Definir un tipo paramétrico propio (`Corral[T]`) y explicar qué gana la clase al tener `T`, qué es `T` en ejecución y qué no.
- Ponerle límites a un parámetro de tipo (`T <: Animal`, `T >: VacaLoca`, los dos juntos) y decir qué restringe cada uno.
- Explicar con un contraejemplo por qué `Set[Vaca]` no es `Set[Animal]`, por qué `List[Vaca]` sí es `List[Animal]`, y por qué un tipo propio es invariante aunque tenga bound.
- Leer `Function1[-T1, +R]` y predecir cuál de cinco funciones se puede guardar en una variable `Vaca => Vaca`, y por qué.
- Anotar un parámetro de tipo con `+` o `-` sabiendo el precio: en qué posiciones se puede usar, qué error da cuando no, y cómo escribir igual un método que recibe `T` (`[U >: T]`).
- Ante un requerimiento nuevo en el TP, decidir en tres preguntas si un parámetro lleva bound, qué signo lleva y cómo se escribe el método que recibe `T`.

Las últimas tres son las que se evalúan en el individual: aparece un requerimiento nuevo sobre un tipo paramétrico y hay que decidir **qué** le ponés y por qué.

## Los módulos

Cuatro fases: **A** repaso y el problema (M1–M2) · **B** tipos paramétricos propios (M3–M4) · **C** varianza (M5–M6) · **D** el precio, el estado final y la decisión (M7–M9). El Módulo 0 es orientación.

| Módulo | Archivo (`clase-cero-clase08-type-arguments-y-varianza-…`) | Densidad | Qué cierra |
|---|---|---|---|
| **0** El proyecto en el que trabajamos | `modulo0-el-proyecto.md` | 🟢 corto | Qué hay en el código de referencia, qué archivo usa cada módulo, cómo correr las apps y los tests, y la única diferencia entre lo que los módulos construyen y el código final (`Set` mutable) |
| **1** Subtipado, de nuevo, y el principio de sustitución | `modulo1-subtipado-y-liskov.md` | 🟡 corto | Qué se guarda en qué variable y qué mensajes deja mandar; la vaca loca que no se puede reír; *sound*; Liskov con `Ave`/`Avestruz`, y que el compilador no lo chequea |
| **2** Colecciones: el tipo de lo que contiene | `modulo2-colecciones-y-type-arguments.md` | 🔴 | `Set(new Vaca, new Caballo)` es `Set[Animal]`; con un granero adentro es una unión y `estaGordo` no compila; por qué el compilador busca el tipo más específico; `filter` de Haskell; `Set[Animal]` explícito; parámetro vs argumento de tipo |
| **3** Corral, Pastor y Lechero: definir un tipo paramétrico | `modulo3-definir-un-tipo-parametrico.md` | 🔴 | El lechero que no puede ordeñar; el callejón de un corral por especie; `Corral[T]`; `T` es un nombre; coherencia interna; inferencia en cascada; el `add` de un caballo rechazado |
| **4** Type bounds: lo que `T` tiene que ser como mínimo | `modulo4-type-bounds.md` | 🔴 | `Corral[Int]`; `gordos` con `T` libre; las salidas que funcionan y no sirven; `T <: Animal`; `gordos: Set[T]`; `T >: VacaLoca`; el diagrama de la rama; los dos bounds; erasure |
| **5** Varianza I: por qué un `Set[Vaca]` no es un `Set[Animal]` | `modulo5-varianza-set-y-list.md` | 🔴 | El pastor roto; el contraejemplo del caballo; invarianza y bivarianza con notación; `List` inmutable y covariante; `List[+A]`; tu `Corral[T]` también es invariante; bound y varianza responden preguntas distintas |
| **6** Varianza II: funciones, y la contravarianza | `modulo6-funciones-y-contravarianza.md` | 🔴 | `Vaca => Vaca` es `Function1[Vaca, Vaca]`; `g` a `k` uno por uno; `Function1[-T1, +R]`; promesa vs necesidad; `Printer[-T]`; `Map[K, +V]`; el cuadro de las tres varianzas |
| **7** El precio de poner un `+`: posiciones | `modulo7-posiciones-y-milista.md` | 🔴 | Tres posiciones; `MiLista[+T]` desde el constructor; `add(elem: T)` rechazado y el programa que explotaría; `concat[U >: T]`; `map[U]`; `filter` y la doble inversión; por qué el `Set` inmutable también es invariante |
| **8** `Corral[+T]` terminado: `contiene` y la decisión de diseño | `modulo8-corral-covariante-y-contiene.md` | 🔴 | De `Set[T]` a `List[T]`; el pastor arreglado; `contiene` con seis firmas (dos que fallan, cuatro que compilan y se comparan); explícito vs inferido; `[U >: T <: Animal]`; `var` en `+T` no compila |
| **9** `MiLista` completa, los límites de la teoría y la guía para el TP | `modulo9-milista-completa-limites-y-guia.md` | 🔴 | `Vacia` es `MiLista[Nothing]` por covarianza; `add[U >: T]`; polimorfismo en vez de preguntar; `contains` como problema abierto; `Foo[+T <: Vaca, -R >: Animal]`; la guía de decisión en tres preguntas y dos ejercicios del dominio |

**Densidad:** 🔴 pide una sesión con el código abierto; 🟡 se lee de corrido; 🟢 es operativo, se consulta. (Las mismas tres marcas, dentro de un módulo, significan importancia de la sección; ver la leyenda.)

## El orden, y por qué

```
 M0 Proyecto
   │
   ▼
 M1 Subtipado + Liskov ──► M2 Colecciones ──► M3 Corral[T] ──► M4 Bounds
                                                                   │
                                                                   ▼
                                              M5 Set invariante / List covariante
                                                                   │
                                                                   ▼
                                              M6 Funciones: Function1[-T1, +R]
                                                                   │
                                                                   ▼
                                              M7 Posiciones: MiLista[+T]
                                                                   │
                                                                   ▼
                                              M8 Corral[+T] terminado: contiene
                                                                   │
                                                                   ▼
                                              M9 MiLista completa, límites, guía
```

- **M1 → M2:** la pregunta "¿qué mensajes entiende lo que saco de la colección?" solo tiene sentido después de fijar que una variable solo acepta mensajes de su tipo declarado.
- **M2 → M3:** el `Set[Animal]` muestra el tipo compuesto *usado*; el corral lo *define*.
- **M3 → M4:** el `Corral[Int]` aparece apenas `T` queda libre; los bounds son la respuesta.
- **M4 → M5:** con el corral acotado, el pastor sigue roto. Es el primer momento en que se ve que el problema no es el corral sino el `Set`.
- **M5 → M6:** la covarianza quedó con nombre pero sin la otra dirección. Las funciones la tienen en el parámetro.
- **M6 → M7:** sin la intuición parámetro/retorno no se entienden las posiciones. `MiLista` es el laboratorio.
- **M7 → M8:** con las posiciones claras, el `Corral[+T]` final se lee entero y las cuatro firmas de `contiene` se comparan con fundamento.
- **M8 → M9:** la lista completa necesita `[U >: T]` y `Nothing` con covarianza; la guía de decisión necesita todo lo anterior.

Dos cosas aparecen en M3 antes de poder explicarse (un error de invarianza y uno de erasure). Quedan anotadas como hilos, porque el callejón de los corrales por especie tiene que venir antes del `Corral[T]`: es lo que lo motiva.

## Hilos que se siembran y se cierran

| Hilo | Se siembra | Se cierra |
|---|---|---|
| **H0** ¿`List[Persona]` es subtipo de `List[Nombrable]`? (clase anterior, M8) | Roadmap y M1, "De dónde venís" | M5 |
| **H1** El pastor roto: `pastorear(corralito.animales)` deja de compilar al poner `Corral[T]` | M3 | M5 (por qué, y `pastorear` anda con `List[T]`) → M8 (`Corral[Vaca]` como `Corral[Animal]` con `+T`) |
| **H2** "Puedo agregarle un caballo al set de animales" como peligro | M3 (el `add` rechazado) | M5 (el contraejemplo) |
| **H3** ¿Para qué sirve un lower bound? | M4 (el experimento con `VacaLoca`: "parece una herramienta sin uso") | M7 (`concat[U >: T]`) → M8 (`contiene[U >: T]`) → M9 (`add[U >: T]`) |
| **H4** ¿Dónde puedo usar `T` adentro del corral? | M4 (`gordos: Set[T]`) | M7 (posiciones) |
| **H5** Covarianza "gratis": "¿por qué no le ponen `+` a todo?" | M5 (el `+` como intención) y M6, sección 6 (la pregunta) | M7 (el precio) → M9 (`contains`, el límite) |
| **H6** `extends Corral(animales)` rechazado en los corrales por especie | M3 | M5 (invarianza) |
| **H7** Dos `build` con el mismo tipo de retorno ni compilan | M3 | M4 (erasure) |
| **H8** `List()` es `List[Nothing]` (clase anterior, M8) | M9, "De dónde venís" | M9 (`Vacia`) |
| **H9** Qué pasa con `T` en ejecución | M4 (erasure) | Queda abierto; reaparece en la segunda mitad de la materia |
| **H10** La promesa *sound*: ¿el rechazo de M5 la rompe o la cumple? | M1, sección 4 | M5 |

## Cómo leer cada bloque

| Bloque | Qué es |
|---|---|
| `> Recuadro` al inicio de cada sección | La regla, en afirmativo, en una a tres líneas. Después viene el caso, después el porqué |
| 🔴 🟡 🟢 en los títulos de sección | Importancia: central y evaluable · secundario · mencionado al pasar. (En la tabla de módulos de arriba, las mismas marcas indican densidad) |
| Tabla *escribís / Scala entiende / sale* | Varias formas de hacer lo mismo sobre un mismo caso, incluidas las que fallan, con el mensaje exacto del compilador 3.3.1 |
| `// Resultado:` dentro del código | Qué sale al ejecutar, para saberlo sin salir de la lectura |
| **Para el parcial, si te preguntan** | Respuesta modelo. Con forma de diseño cuando la pregunta es de diseño ("aparece esto: ¿compila? ¿qué le ponés y por qué?"); conceptual cuando la pregunta es conceptual |
| 🕳️ **Madriguera** | Algo que existe, está fuera del alcance de la materia, y se nombra para que no te lo lleves de tema |
| **Checkpoint** | Preguntas al cierre, sin respuestas. Las respuestas van al complemento de la unidad. (El Módulo 0, que es operativo, va sin checkpoint) |
| **De dónde venís** | Lo que el módulo asume sabido de módulos o clases anteriores |

## Cómo usarlo

1. En orden. Cada módulo se apoya en el anterior y la pregunta que lo cierra la abre el siguiente.
2. Con el proyecto de referencia abierto: todo bloque de código se pega y corre, y el texto dice qué tiene que salir. Los módulos 3, 4 y 5 construyen el corral por etapas con `scala.collection.mutable.Set`; el código final usa el `Set` inmutable y `List`. El Módulo 0 explica la diferencia; los módulos 5 y 7 explican por qué.
3. El checkpoint se hace al final de cada módulo, sin mirar atrás. Lo que no salga, se anota.
4. Las dudas van por chat durante la lectura. Al cerrar la unidad se destilan en el complemento, junto con las respuestas de los checkpoints.

## Qué queda afuera, y dónde está

- **Pattern matching, case classes, inmutabilidad como tema:** clase siguiente (y su lectura previa, el patrón Visitor).
- **`cruzar(toro: T)`:** aparece resuelto en M8 (sección 6) y se repite como `agregar` en el ejercicio 2 de M9; el código de referencia (`Corral.scala`) tiene solo `gordos` y `contiene`.
- **`VacasFactory`, `type Cosos`, `isInstanceOf` en `gordos`:** son los callejones de M3 y M4. Se muestran como lo que se probó y por qué no sirve.
- Como madrigueras, nombradas y cerradas: traits vs mixins en tipado nominal (M2); `Function1` a `Function22`, funciones de más parámetros y currificación (M6); wildcards de Java y `=:=` como tipo (M5); por qué se borra `T` en ejecución (M4); sistemas de efectos (M9).

## Limitaciones declaradas

- **Todo el código de los módulos se compiló en Scala 3.3.1** con el compilador real, y los mensajes de error son los que ese compilador imprime (en el formato `Found: … / Required: …` y `value x is not a member of …`, con los nombres calificados como `tadp.granja.Animal`). Se omiten los sufijos `did you mean …` que el compilador agrega como sugerencia, y en los `Found` se escribe el nombre de la variable a secas (`(vacas : …)`); cuando la variable es miembro de un `object`, el compilador antepone el nombre completo del objeto (`(tadp.granja.GranjaApp.vacas : …)`); dentro de un método sale a secas. Donde el material muestra un error en ejecución, la línea es la de la excepción (`java.lang.UnsupportedOperationException: …`), sin la traza; dentro de un `object … extends App` esa excepción aparece envuelta en `ExceptionInInitializerError`.
- **Los bloques de rediseño** (como el `trait Volador` de M1) se prueban en un archivo aparte o con otros nombres: el proyecto ya tiene esas clases, y los tests dependen de ellas.
- **Scala 3 infiere distinto que Scala 2 en un caso** (M2): una colección de vaca, caballo y granero se infiere como unión de tipos, no como `Object`. El módulo lo enseña como es en 3.3.1 y lo aclara en una línea.
- **Lo que no compila no está en el código de referencia.** Está en los módulos, con su mensaje, y seis casos están además como `assertTypeError` en `GranjaTest.scala`.

## Mapa de procedencia

Los módulos están escritos sin referencias a sus fuentes. Esta tabla existe para la trazabilidad: qué viene de la clase presencial del 17-Oct (que fija el recorte), qué completa el material de años anteriores (video y capturas 2020, script, repo de cátedra), y qué es ilustración propia.

| Módulo | Clase presencial | Completado desde material anterior | Ilustración propia |
|---|---|---|---|
| 0 | — | Estructura del repo `scala-granja` (archivos y nombres de las apps) | El recorrido del proyecto de referencia |
| 1 | Qué se puede guardar en una referencia y qué mensajes se pueden mandar; *sound* ("no debería dejarme escribir algo que pase el chequeador y explote") | Slides 1–6 y video del 2020: la jerarquía, `animal = new Vaca` ✅ / `vaca = new Animal` ❌, `vaca.reite` como falso negativo, Liskov y la `Avestruz` | Las tres referencias al mismo objeto; el rediseño con un trait `Volador`; la salvedad del cast y la lectura de `vola` como operación parcial |
| 2 | Fotos 1–4: `Set` con y sin granero, con y sin tipo; "el tipo más específico que cumple con todas"; `Set(vaca, vacaLoca)` infiere `Vaca`; traits vs mixins | Slides 7–9 del 2020 (`filter` de Haskell); script | Las dos reglas de inferencia de Scala 3 (join / unión) |
| 3 | Fotos 5–18: `Corral(Set[Animal])`, corrales por especie, `VacasFactory`, `Corral[Animal]` que tapa la clase, `Corral[T]`, `corralito` con caballo, `vacas1.add(new Caballo)`; "T es un nombre", "coherencia interna", "la inferencia es azúcar" | Capturas 18–23 del 2020 (`Lechero` con `Corral[Vaca]`) | El error `Missing type parameter` y la tabla parámetro/argumento |
| 4 | Fotos 19–26 y pizarrón 23–24: `gordos` con cast, `type Cosos`, `[T >: Vaca <: Animal]`, `[T <: Animal]`, `gordos: Set[T]`, `cc = new Corral[Animal](caballos)`, `[T >: VacaLoca <: Animal]`; "qué gana el corral"; erasure | Capturas 24–29 y slide 1 de la parte 2 del 2020 (`corralRaro`, upper/lower bound, pajarito/pescadito); script | — |
| 5 | Fotos 27–33 y pizarrón 29/33/38: `Set[Animal] = vacas`, el caballo, `List`, `List[+A]`, notación formal; "¿el equivocado es el compilador o soy yo?"; Ruby, TypeScript, Java | Capturas 3–9 de la parte 2 y 5–6 de la parte 3 del 2020 (`c2: Corral[Animal] = new Corral[Vaca]`, bound vs varianza); script | Por qué el `Set` inmutable también es invariante |
| 6 | Fotos 34–36: `f: Vaca => Vaca`, `Function[Vaca, Vaca]`, `g`–`k` con 🟢/🔴, `Function[-Parametro, +Retorno]`; `in`/`out`; promesa vs necesidad | Capturas 10–18 de la parte 2 y 7–10, 16–17 de la parte 3 del 2020 (cuerpos de `h`, `i`, `j`, `k`, `k2`, `f2`, `Printer`, `Predef`); script (`Printer`) | — |
| 7 | Fotos 37–46 y pizarrón 44: `MiLista[+T]`, `add`, `head`/`tail`, `concat[U >: T]`, `filter`, `map[U]`, `contains`, signos sobre `filter`, `Corral[+T]` sobre `Set[T]` (posición invariante); "el constructor es una excepción"; "la varianza se chequea en una pasada posterior" | Capturas 18–21 de la parte 3 del 2020 (`contiene[T1 <: T]`) | `def mal(f: Int => T)`; `var` en el constructor |
| 8 | Fotos 46–48: `Corral[+T]` sobre `Set`, sobre `List`, `contiene`/`cruzar`, `contiene[U >: T]` | Capturas 22–34 de la parte 3 del 2020 (`contiene[Int]`, `contiene[Vaca]`, `AnyRef`, `[T1 <: Animal]`, `List.contains`, el escenario con `t.ordeñate`); script (`var` en el corral, `Foo`) | `[U >: T <: Animal]`; `var` en `+T` |
| 9 | "`contains` sería seguro y no lo puedo escribir"; sistemas de efectos | `List.contains` del 2020; script (`Foo[+T <: Vaca, -R >: Animal]`) | `Vacia`/`Nodo`; `Veterinario[-T]`; `agregar[U >: T <: Animal]`; la guía de decisión |

---

**FIN DEL ROADMAP — Clase desde cero — Type arguments y varianza en Scala**
