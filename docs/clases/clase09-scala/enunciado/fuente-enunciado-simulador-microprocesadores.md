# Simulador de Microprocesadores

> Conversión fiel a Markdown de Enunciado - Simulador de Microprocesadores.pdf (1 página).

**Notas de conversión:**
- Se recibieron dos copias del PDF (con y sin metadato de título). Se compararon el texto extraído y la página rasterizada: el contenido y el formato visible son idénticos. Este archivo representa a ambas. También coincide con la versión publicada en Google Docs del mismo enunciado.
- En el original, "Realizar una impresión de un programa" está en negrita sin los dos puntos; en el ítem 2, la negrita incluye los dos puntos y el número "2.". Se respetó esa diferencia.
- Errores de concordancia del original, transcriptos tal cual: "los dos registro" (ADD y MUL) y "los valores de los registro" (SWAP).

---

Queremos modelar un programa que permita simular la ejecución de un pequeño lenguaje de máquina en ciertos modelos de procesadores, que tienen las siguientes características:

- 2 registros (A y B) que permiten almacenar un entero entre -1024 y 1024 c/u.
- 128 slots de memoria interna, cada uno del tamaño de un registro

El lenguaje de máquina que queremos simular tiene las siguientes instrucciones

| **Nombre** | **Descripción** |
|---|---|
| ADD | Suma los valores de los dos registro y guarda el resultado en el A |
| MUL | Multiplica los valores de los dos registro y guarda el resultado en el A |
| SWAP | Intercambia los valores de los registro |
| LOAD(address) | Carga en el registro A el valor de memoria en la posición *address*. |
| STORE(address) | Guarda el valor del registro A en memoria, en la posición *address*. |
| IF(sub) | Ejecuta la secuencia de instrucciones *sub* si el valor del registro A es 0. |
| HALT | Detiene la ejecución del programa. |

Además de poder ejecutar un programa, se estima que los equipos de desarrollo podrían querer analizarlo de diversas formas. Algunos ejemplos que deben implementarse son:

1. **Realizar una impresión de un programa**: Queremos obtener un string a partir del programa donde se muestre cada instrucción, separada por comas, con sus parámetros entre corchetes.
2. **Simplificar redundancias de un programa:** Se busca eliminar del programa las instrucciones que no producen un cambio significativo del estado. Se pide trabajar sobre los siguientes casos
    - Dos SWAP seguidos: Eliminar ambos SWAP
    - Dos LOAD seguidos: Eliminar el primer LOAD
    - Dos STORE seguidos en la misma dirección: Eliminar el primer STORE
    - Un IF sin sub instrucciones: Eliminar el IF
    - Cualquier instrucción posterior a un HALT: Eliminar todas

---

**FIN DEL ARCHIVO FUENTE — Simulador de Microprocesadores**
