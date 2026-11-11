// CÓMO SE CREÓ: clic derecho en src/main/scala/granja → New → Scala Class/File → Object → "GranjaApp",
// y a mano se le agrega "extends App".
// QUÉ ES: una app. "extends App" hace que el cuerpo del object sea el programa (como el @main del ejemplo).
// CÓMO SE CORRE: ▶ al lado de "object GranjaApp"; la salida aparece en la consola (panel Run).

package granja

object GranjaApp extends App {

  val animal = new Animal
  animal.come()
  println("Peso: " + animal.peso) // 110
  println("estaGordo: " + animal.estaGordo) // false

  val vaca: Vaca = new Vaca
  vaca.peso += 111
  vaca.ordeñar()
  println("Vaca.peso: " + vaca.peso)
}
