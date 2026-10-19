# Playbook — preclase07: Instalación de ambientes para Scala — Parte 1: Qué instalar y por qué estas versiones

**Unidad:** preclase07 (lectura previa de la clase07, TADP 2C 2026) · **Género:** playbook (ejecutás, con verificación en cada paso) · **Partes:** 4
**Hecho sobre:** macOS (MacBook Air M5), IntelliJ IDEA Community 2026, octubre de 2026. Donde Windows o Linux cambian algo, está marcado.

---

## Sobre este playbook

**Qué resuelve.** La planificación de la cátedra pone como lectura previa de esta fecha "Instalación de ambientes", sin link ni material. El tutorial que existe es un video de hace más de diez años, en Linux, con versiones viejas. Este playbook lo reemplaza: al terminar las cuatro partes tenés IntelliJ abriendo proyectos Scala, un proyecto propio con tests corriendo, un dominio chico escrito por vos, y el repo del TP importado y verificado.

**Cómo se lee.** De corrido y en orden. Cada paso con efecto visible tiene un bloque **✅ Deberías ver** con la señal de éxito. Si la señal aparece, avanzás; si no, parás ahí y revisás ese paso. Las trampas están marcadas con ⚠️ en el lugar exacto donde muerden.

**Dónde corre cada cosa.** Todo pasa en tu máquina: en IntelliJ (ventanas y menús) o en la terminal integrada de IntelliJ (prompt `nombre@Mac carpeta %`). Cuando un paso es en terminal, lo dice.

**Las partes:**

| Parte | Qué hacés | Al terminar tenés |
|---|---|---|
| 1 (esta) | Instalás IntelliJ y el plugin de Scala; entendés qué versiones se usan y por qué | El IDE listo para crear proyectos Scala |
| 2 | Creás tu primer proyecto desde cero: sbt, `build.sbt`, ScalaTest, `.gitignore`, git | Un proyecto propio que corre un programa |
| 3 | Escribís un dominio chico en dos packages, con `import` y tests | Práctica real de la estructura que vas a usar todo el cuatrimestre |
| 4 | Abrís el repo del TP (que tiene `ruby/` y `scala/` adentro) y corrés su test | El TP listo para trabajar |

---

## 1. Las versiones de este cuatrimestre, y de dónde salen

Todo el material de la segunda mitad de la materia usa **las mismas versiones que el repo del TP** que la cátedra entregó en el 2C 2026. Es una decisión deliberada: lo que practicás en las clases desde cero, lo que imprimís y lo que escribís en el TP compila con el mismo compilador. Así no hay fricción entre aprender y entregar.

| Herramienta | Versión | Qué es, en una línea |
|---|---|---|
| **Scala** | **3.3.1** | El lenguaje. La fija `scala/build.sbt` del repo del TP. |
| **sbt** | **1.9.0** | La herramienta que compila, corre tests y descarga librerías. La fija `scala/project/build.properties` del repo. |
| **JDK (Java)** | **17** | La máquina virtual donde corre Scala. Es la versión que declara el workflow de `.github/` del repo (verificalo abriendo su `.yml`). |
| **ScalaTest** | **3.2.19** | La librería de tests. La fija `scala/build.sbt` del repo. |
| **IntelliJ IDEA** | **Community** (gratis) | El IDE. Con Community alcanza para todo el cuatrimestre. |
| **Plugin de Scala** | el que ofrece IntelliJ | Le enseña a IntelliJ a entender Scala y sbt. Trae su propio sbt. |

⚠️ **Las clases grabadas y las branches del repo de la cátedra usan otras versiones** (2.12, 2.13, 3.7). Si ves código que se escribe distinto, el material de este proyecto ya lo adapta a 3.3.1 y, donde cambia la sintaxis, lo marca debajo del bloque. Vos trabajá siempre en 3.3.1.

**Lo que no hace falta instalar:** Scala suelto, sbt suelto, ni Java por tu cuenta. IntelliJ descarga el JDK cuando creás el proyecto (Parte 2), y el plugin trae sbt, que a su vez descarga Scala y ScalaTest. Un solo instalador y un plugin.

---

## 2. Instalar IntelliJ IDEA Community

**Si ya tenés IntelliJ instalado** (por otra materia, por ejemplo): saltá a la sección 3. Cualquier versión de 2024 en adelante sirve.

1. Entrá a `jetbrains.com/idea/download`.
2. Bajá hasta **IntelliJ IDEA Community Edition**. Está debajo de la Ultimate, que es la paga; la Community es gratis y es la que usás.
   - **Mac:** elegí **Apple Silicon** si tu Mac tiene chip M1 o posterior (M5 incluido). Intel solo para Macs viejas.
   - **Windows:** el `.exe`.
   - **Linux:** el `.tar.gz`, o el snap si tu distribución lo tiene.
3. Instalalo como cualquier programa. En Mac: abrir el `.dmg` y arrastrar el ícono a Applications.
4. Abrilo. La primera vez te pregunta si querés importar configuración: **Do not import settings**.

**✅ Deberías ver:** la pantalla de bienvenida de IntelliJ, con el título "Welcome to IntelliJ IDEA", los botones New Project / Open / Get from VCS y, a la izquierda, un menú que incluye Projects, Plugins y Learn.

⚠️ Si abriste IntelliJ y te ofrece "Unlock Ultimate" o una prueba de 30 días, ignoralo. Community es completa para lo que hacés acá.

---

## 3. Instalar el plugin de Scala

El plugin es lo que convierte a IntelliJ en un IDE de Scala. Sin él, IntelliJ abre los archivos `.scala` como texto plano y no sabe qué es `build.sbt`.

1. En la pantalla de bienvenida, menú de la izquierda → **Plugins**. (Si ya tenés un proyecto abierto: menú IntelliJ IDEA → Settings → Plugins, o `⌘ ,` en Mac / `Ctrl Alt S` en Windows y Linux.)
2. Pestaña **Marketplace**, arriba.
3. En el buscador escribí `Scala`.
4. El primer resultado es **Scala**, de JetBrains. Botón **Install**.
5. Cuando termine, el botón cambia a **Restart IDE**. Hacé clic y esperá a que IntelliJ vuelva a abrir.

**✅ Deberías ver:** después del reinicio, en Plugins → pestaña **Installed**, el plugin **Scala** con su tilde activo. Y en la pantalla de bienvenida, al apretar **New Project**, aparece **Scala** en la lista de generadores de la izquierda (la posición exacta depende de la versión).

⚠️ **Hay un plugin que no necesitás: `.ignore`.** Algunos tutoriales lo recomiendan para generar el `.gitignore`. Genera archivos enormes, con plantillas de diez herramientas que no usás, y es fácil que te deje una línea pegada a otra y el archivo deje de funcionar. En la Parte 2 escribís el `.gitignore` a mano: son siete líneas.

---

## Checkpoint de la Parte 1

Antes de seguir, verificá las tres cosas. Si alguna falla, volvé a la sección que la cubre.

- [ ] IntelliJ IDEA Community abre y muestra la pantalla de bienvenida.
- [ ] En Plugins → Installed, está **Scala** activo.
- [ ] En New Project, **Scala** aparece como tipo de proyecto.

Anotá también esto, que lo vas a usar en la Parte 2: **Scala 3.3.1 · sbt 1.9.0 · JDK 17 · ScalaTest 3.2.19**.

## Lo que viene

**Parte 2:** creás tu primer proyecto con el asistente de IntelliJ, le agregás ScalaTest al `build.sbt`, corrés un programa, escribís el `.gitignore` y dejás el proyecto bajo git. Es la parte donde más cosas aparecen por primera vez; está pensada para hacerse en veinte minutos, incluida la descarga del JDK.

**FIN DE LA PARTE 1**
