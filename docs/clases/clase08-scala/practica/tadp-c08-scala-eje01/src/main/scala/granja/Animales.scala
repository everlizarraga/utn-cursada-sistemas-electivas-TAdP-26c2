// CÓMO SE CREÓ: clic derecho en src/main/scala/granja → New → Scala Class/File → Class → "Animal".
// Después el ARCHIVO se renombró a Animales.scala porque va a tener varias clases (Animal, Vaca, …).
// Para un archivo nuevo de varias clases: New → Scala Class/File → File (crea el archivo vacío).
// (El paquete granja se creó antes: clic derecho en src/main/scala → New → Package → "granja".)
// IntelliJ escribe solo la línea "package granja".
// SUS TESTS: src/test/scala/granja/AnimalesSpec.scala (mismo paquete, del lado de test).
// También se prueba desde GranjaApp.scala (app) y desde pruebas.sc (worksheet).

package granja

class Animal {
  var peso: Int = 100

  def come(): Unit = this.peso += 10

  def estaGordo: Boolean = this.peso >= 150
}

class Vaca extends Animal {
  def ordeñar(): Unit = this.peso -= 10
}

class VacaLoca extends Vaca {
  def reite: String = "Muajajajajaja"
}

class Caballo extends Animal {
  def relincha: String = "IEIIEIEeeeeieeeie"
}