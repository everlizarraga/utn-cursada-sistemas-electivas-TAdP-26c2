// CÓMO SE CREÓ: clic derecho en src/test/scala/granja → New → Scala Class/File → Class → "AnimalSpec"; después se renombró a AnimalesSpec, espejo de Animales.scala.
// (El paquete granja de test se creó antes: clic derecho en src/test/scala → New → Package → "granja".)
// QUÉ ES: los tests de las clases de src/main/scala/granja/Animales.scala. Espeja su ubicación: mismo paquete,
// del lado de test, con el nombre del archivo + "Spec", como en el TP.
// ESTILO: AnyFreeSpec, el del TP. "-" agrupa tests, "in" define un test, shouldBe compara.
// CÓMO SE CORRE: ▶ al lado de "class AnimalesSpec" (todos los tests) o al lado de un test (solo ese).

package granja

import org.scalatest.freespec.AnyFreeSpec
import org.scalatest.matchers.should.Matchers._

class AnimalesSpec extends AnyFreeSpec{
  "Un animal" - {

    "nace pesando 100" in {
      val animal = new Animal // val = referencia que no se reasigna
      animal.peso shouldBe 100
    }

    "cuando come, sube 10 de peso" in {
      val animal = new Animal
      animal.come()
      animal.peso shouldBe 110
    }

    "después de comer 5 veces, está gordo" in {
      val animal = new Animal
      for(i <- 1 to 5) {
        animal.come()
      }
      animal.estaGordo shouldBe true
    }

  }

  "Otro animal" - {
    "experimento animal con vacas" in {
      val vaca: Vaca = new Vaca
      vaca.ordeñar()
      vaca.peso shouldBe 90
    }
  }
}
