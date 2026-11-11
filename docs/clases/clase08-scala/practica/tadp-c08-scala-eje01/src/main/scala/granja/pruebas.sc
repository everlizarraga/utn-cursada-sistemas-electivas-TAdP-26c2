// CÓMO SE CREÓ: clic derecho en src/main/scala/granja → New → Scala Worksheet → "pruebas" (queda pruebas.sc).
// QUÉ ES: un worksheet. Código suelto, sin package ni main: el resultado de cada línea aparece a la derecha.
// CÓMO SE CORRE: ▶ verde de la barra de arriba del worksheet (Evaluate worksheet).
// CONFIGURACIÓN (tuerquita de esa barra): "Build project before run" marcada, para que vea los cambios de Animal.

import granja.*

val animal: Animal = new Animal
animal.peso
animal.come()
animal.peso
animal.estaGordo
