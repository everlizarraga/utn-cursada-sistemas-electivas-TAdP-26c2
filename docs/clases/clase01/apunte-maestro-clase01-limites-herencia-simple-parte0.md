# Apunte Maestro — Clase 01 — Parte 0: Cómo funciona la materia

> **Técnicas Avanzadas de Programación (TADP) — UTN FRBA — 2C 2026**
> Esta parte no tiene contenido conceptual: es la operativa de la cursada, junta y en un solo lugar, para consultar durante todo el cuatrimestre. El contenido de la clase arranca en la Parte 1.

---

## 1. 🔴 Cómo se aprueba

No hay parcial teórico. **Toda la evaluación son cuatro instrumentos**, dos por cada mitad de la materia:

| Nº | Instrumento | Modalidad |
|---|---|---|
| 1 | **TP 1 — grupal** | Metaprogramación (Ruby) |
| 2 | **Individual 1** | Extensión del propio TP 1 |
| 3 | **TP 2 — grupal** | Objetos-Funcional (Scala) |
| 4 | **Individual 2** | Extensión del propio TP 2 |

**Cada TP grupal tiene dos momentos:** un **checkpoint** intermedio, que no lleva nota y sirve para corregir el rumbo antes de que sea tarde, y una **entrega final**.

**Cada instancia individual es, formalmente, un parcial.** Funciona así: agarrás el TP grupal que tu propio grupo desarrolló y le agregás **un requerimiento nuevo, chico, en el momento**. La extensión está pensada para resolverse en unos 15 minutos de trabajo real. No se evalúa memoria: se evalúa que puedas **moverte con soltura dentro de tu propio código y tomar una decisión de diseño**. Si participaste del TP grupal y entendés la solución, es una pavada. Si no lo tocaste y te sentás frente a un código que no conocés, puede ser durísimo.

**Aprobar los cuatro = cursada aprobada.** Con nota de promoción, la materia queda promocionada y no rendís final. Con una nota que aprueba pero no promociona (mencionada en el entorno de 6 a 7), la cursada queda aprobada y te tenés que anotar a una mesa de final donde se te canta la nota; no hay examen que rendir ahí.

**Recuperatorios:** cada instancia individual tiene **dos**, y se rinden **en fechas de final** (5 y 12 de diciembre).

> **🔴 La correlación no es casualidad.** Existe una relación directa y observable entre venir con la lectura hecha, participar en clase, hacer los TPs, y aprobar. La materia tiene alrededor de un 60% de aprobación, y no porque el contenido sea inaccesible: porque exige seguimiento clase a clase.

---

## 2. 🔴 Los grupos

**Grupos de 5 personas. Exactamente 5.**

No es una sugerencia con margen. Los grupos de 4 o de 6 son susceptibles de ser **desarmados y reacomodados**, porque la cantidad de grupos determina cómo se reparten los ayudantes disponibles. Si querés cursar con las 4 personas que ya elegiste, la forma de garantizarlo es presentar un grupo de 5 y no dar lugar a que lo toquen.

Cada grupo recibe:

- Un **ayudante/tutor asignado**, que corrige el TP grupal y funciona como punto de consulta rápido. La idea es no tener que esperar de un sábado al otro para destrabar algo.
- Un **canal propio en Discord** para hablar con el grupo y con el ayudante.
- Un **repositorio privado de GitHub**, provisto por la cátedra y ya preseteado con el proyecto.

---

## 3. 🔴 Dónde vive la materia

| Canal | Para qué | Estado |
|---|---|---|
| **Página de cátedra** — `tadp-utn-frba.github.io` | Centraliza todo: cronograma, planilla, material, scripts de clase, guías de instalación, papers, enunciados de TP | Fuente principal |
| **Discord** — `discord.gg/ppHKfn9` | **Medio oficial de comunicación.** Avisos, canal por grupo, contacto con el ayudante, canal de armado de grupos | Obligatorio |
| **Planilla de alumnos/grupos/notas** | Base de datos de la cursada: quién cursa, en qué grupo, con qué ayudante, con qué notas | Verificá que estás |
| **Canal de YouTube** | Clases grabadas | Complementario |
| **Repo de clases** — `github.com/tadp-utn-frba/tadp-clases` | Código de cada clase, en branches independientes | Complementario |
| **Aula virtual** | Prácticamente no se usa | Está caída la mayor parte del tiempo |

**Sobre el aula virtual:** se usa de forma redundante, solo para avisos formales del tipo "arrancan las clases". Cualquier cosa que se avise ahí, se avisa también por Discord. Mirala si querés, pero **lo obligatorio es Discord**.

**Sobre el Discord:** tu usuario tiene que ser identificable con tu nombre real. Si te anotás como `estrellita59`, nadie puede vincularte con tu legajo ni ayudarte cuando tengas un problema. Renombrate.

**Sobre la planilla:** es la referencia de que estás cursando. Si no figurás en la planilla, en la práctica no hay registro tuyo, y eso se detecta tarde y mal. Chequealo ahora, no en noviembre. Si algo no cuadra con tu inscripción, se resuelve con la facultad, pero el punto de detección es la planilla.

> **⚠️ Los accesos de GitHub vencen.** Cuando lleguen los accesos al repo privado, entrá **esa misma semana** y confirmá que podés clonar y pushear. Si los dejás pasar, se vencen y hay que rehacer el circuito.

**Datos que hay que mandar por grupo:** nombre, apellido, legajo, mail de contacto y **usuario de GitHub** de cada integrante. El usuario de GitHub es el que habilita la creación del repo privado.

---

## 4. 🟡 Cómo está armada la materia

Dos mitades. Cada mitad tiene **un módulo corto y uno largo**, y cada mitad usa una tecnología distinta.

```
                    ┌─────────────────────────────────────────┐
   PRIMERA MITAD    │  RUBY                                   │
                    ├─────────────────────────────────────────┤
   módulo corto     │  Repaso de objetos + Mixins / Traits    │
   módulo largo     │  Metaprogramación                       │
                    └─────────────────────────────────────────┘
                                      ↓
                    ┌─────────────────────────────────────────┐
   SEGUNDA MITAD    │  SCALA                                  │
                    ├─────────────────────────────────────────┤
   módulo corto     │  Tipado estático de objetos             │
   módulo largo     │  Objeto-funcional                       │
                    └─────────────────────────────────────────┘
                                      ↓
                         Clases bonus: objetos y funcional
                            en otras tecnologías
```

**Por qué esas dos tecnologías.** Ruby por su dinamismo y su metamodelo: es un buen exponente para trabajar metaprogramación, porque el lenguaje deja hacer cosas que en otros lados requerirían tocar el compilador. Scala porque buena parte de la formalización académica de la integración objeto-funcional se hizo ahí, y porque su sistema de tipos es de los más elaborados que existen para objetos.

**El eje transversal de toda la materia** es cuestionar el paradigma de objetos tal como se enseña. No porque esté mal, sino porque tiene límites concretos, y porque para extender una herramienta primero hay que aceptar que es imperfecta. La materia entera es una extensión del paradigma de objetos.

---

## 5. 🔴 Qué se espera de vos, clase a clase

**Venir con la lectura hecha.** Hay clases que tienen material asignado de antemano. Sin esa lectura, la clase no rinde: se discute sobre una base que no tenés. Esto es explícito y no negociable.

**Participar.** La materia se apoya en el ida y vuelta. Las clases están construidas para que propongas soluciones y se discutan, no para escuchar una exposición.

**No tomar nota.** Esto es una recomendación deliberada del curso, no un descuido: todo queda grabado y publicado (clases, código, scripts). El tiempo de clase se aprovecha mejor discutiendo que transcribiendo.

> **🕳️ Madriguera — Por qué se cursa un sábado a la mañana**
> El horario es a propósito: filtra a quien no tiene ganas, y da flexibilidad de tiempo (no hay otro curso esperando el aula). El aula puede cambiar de un sábado al otro.
> *Volvé al camino — esto no afecta nada de cómo estudiás.*

---

## 6. 🟡 Ruby y Scala no se enseñan

La sintaxis y el toolchain de ambos lenguajes son **tu responsabilidad**. En clase se mencionan detalles sintácticos a medida que los temas los necesitan, pero no hay una unidad de "cómo se programa en Ruby".

Esto no es abandono: en la página hay guías, y este apunte explica cada construcción sintáctica nueva a medida que aparece. Pero si el código se te hace cuesta arriba, la solución es dedicarle un rato aparte a la sintaxis del lenguaje —hay tutoriales, RubyMonk, Scala Exercises y las guías de Mumuki—, no esperar que la clase lo cubra.

**Entornos:** RubyMine para Ruby, Scala IDE + sbt para Scala. Hay licencias de JetBrains gratuitas a través de la facultad, y las guías de instalación están publicadas. Podés usar el editor que quieras, pero un editor de texto pelado te deja afuera de herramientas que vas a necesitar.

---

## 7. 🔴 Tarea para la clase que viene

Esta es la parte más urgente de este documento.

### Los papers

| Nº | Qué presenta | Obligatorio |
|---|---|---|
| 1 | **Gilad Bracha & Gary Cook — *Mixin-based Inheritance*** | Sí |
| 2 | **Schärli, Ducasse, Nierstrasz & Black — *Traits: Composable Units of Behaviour*** | Sí |
| 3 | **Bergel, Ducasse, Nierstrasz & Wuyts — *Stateful Traits*** | Complementario |

**Cómo leerlos:**

- **No hace falta leer las secciones de implementación.** Lo que se busca es el planteo conceptual, no el detalle de cómo se compila.
- El primer paper **puede reemplazarse por la tesis doctoral de Bracha** (*Jigsaw*, primeros capítulos): es más larga, pero está escrita como artículo de divulgación y se lee bastante más fácil. Elegí una de las dos.
- El tercero es un complemento del segundo. Si te alcanza el tiempo, ojeálo; si no, con mirarlo por encima está bien.
- Están todos linkeados en la página, y hay traducciones al español dando vueltas si el inglés te frena.
- **Empezá temprano.** Puede ser la primera vez que leés un paper académico, y ese formato tiene su propia curva. Es parte del oficio: el lenguaje formal de la disciplina son los papers, no los videos ni los posteos de blog.

### Las cinco preguntas que tenés que poder responder

Si terminás de leer y no podés contestarlas, la lectura no rindió y conviene volver sobre el texto.

1. **¿Qué es un mixin? ¿Qué es un trait? ¿Cuáles son las diferencias entre ambos conceptos?**
2. **¿Qué es un conflicto?** ¿Cómo se resuelve en mixins, cómo en traits, y cómo se manejaba —si es que existía— en herencia?
3. **¿Cuál es el rol que le queda a la clase** cuando incorporás estas herramientas? (Son herramientas que también sirven para proveer código y combinarse entre sí: le corren el piso a la clase y le sacan parte de su territorio.)
4. **¿Cuándo sugiere cada autor usar su herramienta?** Bracha y Ducasse tienen posturas **muy distintas** sobre en qué momento conviene usar mixins o traits. Esto está directamente relacionado con la pregunta 3.
5. **¿Qué hay de todo esto en Ruby y qué hay en Scala?** Las tecnologías con las que vamos a trabajar. La respuesta sorprende.

Al leer, hacé foco especialmente en **cómo se resuelven los conflictos**, **cómo se implementan las variables (el estado)**, y en la diferencia entre **flattening y linearization** —y qué implica cada una para vos como programador.

> **⚠️ Mixins y traits no reemplazan la herencia simple: la complementan.** Conviven con ella. Tenerlo presente al leer evita el malentendido más común.

### Además

- Formar el grupo de 5 y mandarlo por Discord con los datos de cada integrante.
- Estar en el Discord con nombre real.
- Verificar que figurás en la planilla.
- **Dejar el ambiente de Ruby instalado y andando.**

---

## 8. 🟢 Cronograma del cuatrimestre

| Nº | Fecha | Tema | Hito | Ejercicio | Leer para esa fecha |
|---|---|---|---|---|---|
| 1 | 15-Ago | Administrativos + Repaso Objetos (Ruby). Polimorfismo, herencia. Intro Mixins | — | Age of Empires | Formar grupos + instalar ambientes |
| 2 | 22-Ago | Mixins: resolución de conflictos | — | Age of Empires | **Papers de Bracha y Ducasse** + ambiente listo |
| 3 | 29-Ago | Metaprogramación en Ruby. Introspection. Self-modification. Open Classes. Autoclase. Metamodelo | **Enunciado TP1** | Age of Empires | — |
| 4 | 5-Sep | `instance_eval`, `class_eval`, `method_missing`, modelado con bloques | — | Age of Empires – Extended | — |
| — | 12-Sep | **SIN CLASES** | — | — | — |
| 5a | 19-Sep | Ejercicio de diseño | **Checkpoint TP1** | Multimethods o Prototype | — |
| 5b | 26-Sep | Ejercicio de diseño | — | Multimethods o Prototype | — |
| 6 | 3-Oct | Objetos con chequeo estático de tipos. Polimorfismo tipado (Scala). Contratos fuertes y débiles. Sobrecarga vs polimorfismo. Inferencia | **Entrega TP1** | Age of Empires Reloaded | Instalar ambiente de Scala |
| 7 | 10-Oct | Tipado estructural, type arguments, varianza, covarianza, contravarianza | **TP Individual 1** | Granja | — |
| 8 | 17-Oct | Pattern matching vs polimorfismo. Inmutabilidad. Case classes | **Enunciado TP2** | Microcontrolador | **Patrón Visitor** |
| 9 | 24-Oct | Comportamiento vs estructura. Mónadas | — | Microcontrolador | — |
| 10a | 31-Oct | Ejercicio de diseño. Aplicación parcial, funciones parciales, deconstrucción. Objetos como función / funciones como objetos, orden superior | — | Pociones o Pokemon | — |
| 10b | 7-Nov | Ejercicio de diseño | **Checkpoint TP2** | Pociones o Pokemon | — |
| 11 | 14-Nov | Objetos/funcional en otras tecnologías | — | — | — |
| 12 | 21-Nov | Clase bonus | **Entrega TP2** | — | — |
| 13 | 28-Nov | Clase bonus | **TP Individual 2** | — | — |
| — | 5-Dic | Fecha de final | Recuperatorios / reentrega de individuales | — | — |
| — | 12-Dic | Fecha de final | Recuperatorios / reentrega de individuales | — | — |

**Cursada:** sábados de 9:15 a 12:30, presencial, Medrano 951. El aula puede cambiar de una semana a otra.

**Los ejercicios de clase** giran sobre dominios recurrentes: *Age of Empires* (y sus variantes Extended y Reloaded), *Granja*, *Microcontrolador*, *Pociones / Pokemon*. Vas a ver el mismo dominio volver con una vuelta de tuerca nueva.

---

## 9. 🟡 Lo que todavía no está definido

Anotado acá para no dar por sabido lo que no lo está:

- **Quién es tu ayudante asignado** — se comunica por Discord una vez que el grupo esté cargado.
- **Los números exactos del régimen de promoción** — se conoce que el rango de 6 a 7 aprueba sin promocionar; el umbral preciso de promoción no se dio.
- **Los enunciados de TP1 y TP2** — se publican en la página en las fechas del cronograma.
- **La numeración final de los tres últimos sábados** (14, 21 y 28 de noviembre) — no vienen numerados.

---

**FIN DE LA PARTE 0 — Cómo funciona la materia**
