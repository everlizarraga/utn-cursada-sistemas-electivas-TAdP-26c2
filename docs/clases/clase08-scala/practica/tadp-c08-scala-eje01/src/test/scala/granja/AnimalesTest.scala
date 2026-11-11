// CÓMO SE CREÓ: clic derecho en src/test/scala/granja → New → Scala Class/File → Class → "AnimalesTest".
// QUÉ ES: los mismos tests que AnimalesSpec.scala, escritos en el otro estilo de ScalaTest, para comparar.
// ESTILO: AnyFunSuite, el del material de clase. Cada test("…") { … } es un caso; no hay grupos anidados.
// CÓMO SE CORRE: ▶ al lado de "class AnimalesTest" (todos) o al lado de un test("…") (solo ese).

package granja

import org.scalatest.funsuite.AnyFunSuite
import org.scalatest.matchers.should.Matchers

class AnimalesTest extends AnyFunSuite with Matchers {

  // ---------- Un animal ----------

  test("un animal nace pesando 100") {
    val animal = new Animal
    animal.peso shouldBe 100
  }

  test("un animal, cuando come, sube 10 de peso") {
    val animal = new Animal
    animal.come()
    animal.peso shouldBe 110
  }

  test("un animal, después de comer 5 veces, está gordo") {
    val animal = new Animal
    for (i <- 1 to 5) {
      animal.come()
    }
    animal.estaGordo shouldBe true
  }

  // ---------- Una vaca ----------

  test("una vaca, al ordeñarse, baja 10 de peso") {
    val vaca: Vaca = new Vaca
    vaca.ordeñar()
    vaca.peso shouldBe 90
  }

}
