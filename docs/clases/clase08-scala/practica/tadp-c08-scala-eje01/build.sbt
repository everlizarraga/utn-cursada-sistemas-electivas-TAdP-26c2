// CÓMO SE CREÓ EL PROYECTO: File → New → Project → Scala. Build system: sbt · JDK 17 · sbt 1.9.0 · Scala 3.3.1
// · "Create Git repository" desmarcado (ya está dentro del repo) · "Add sample code" marcado.
// Después se le sumó ScalaTest (la línea libraryDependencies) y se recargó sbt (ícono flotante o ⇧⌘I).
// A MANO, SIN EL ASISTENTE: este archivo + project/build.properties (sbt.version = 1.9.0)
// + las carpetas src/main/scala y src/test/scala; en IntelliJ, File → Open → la carpeta → Open as sbt project.

ThisBuild / scalaVersion := "3.3.1"

lazy val root = (project in file("."))
  .settings(
    name := "tadp-c08-scala-eje01",
    libraryDependencies += "org.scalatest" %% "scalatest" % "3.2.19" % Test
  )
