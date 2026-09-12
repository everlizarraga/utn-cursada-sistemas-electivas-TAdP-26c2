# 📘 Apunte Maestro — Clase 03: Metaprogramación en Ruby

## Parte 0 — Preparar el entorno

**Materia:** Técnicas Avanzadas de Programación (TAdP) · **Unidad:** clase03 · **Clase del:** 29/08/2026

> **Serie completa:** Parte 0 (entorno) · Parte 1 (qué es metaprogramar) · Parte 2 (introspection) · Parte 3 (method lookup y métodos como objetos) · Parte 4 (self-modification) · Parte 5 (el metamodelo) · Parte 6 (autoclases y cierre).

---

## Cómo leer esta serie

Cada sección lleva una marca de importancia:

- 🔴 **Central.** Es el núcleo de la clase y lo que se evalúa. Si solo podés leer una cosa, leé esto.
- 🟡 **Secundario.** Contexto que hace que lo central se entienda. Se lee, no se memoriza.
- 🟢 **Al pasar.** Se mencionó, sirve saber que existe, nadie te lo va a tomar.

Además vas a encontrar:

- **"Para el parcial, si te preguntan"** — la pregunta probable y una respuesta modelo, escrita como para responderla en un examen.
- 🕳️ **Madriguera** — un tema que aparece de costado y que sería fácil irse a investigar tres horas. La madriguera te dice qué es en dos líneas y te devuelve al camino. Podés saltearla sin culpa.
- ⚠️ **Advertencia** — cuando lo que se enseña y lo que pasa en la vida real difieren. Para el examen, respondé con lo que se enseña.

---

## ¿Por qué hace falta esta parte? 🟡

Hasta acá probablemente venías así: instalaste Ruby, instalaste RubyMine (el IDE de JetBrains para Ruby), escribiste clases y módulos en un archivo, apretaste el botón verde y viste el resultado abajo, en el panel de salida. Con eso alcanzó para las dos primeras clases.

Esta clase no funciona así. **Toda la clase transcurre adentro de una consola interactiva**: se carga el programa de los guerreros una vez y después se le hacen preguntas, línea por línea, viendo la respuesta de cada una al instante. "¿De qué clase sos?", "¿qué mensajes entendés?", "¿qué variables tenés adentro?". Eso es imposible de hacer con un botón que ejecuta un archivo entero y termina.

Y para que la consola muestre las respuestas de forma legible se usa una herramienta llamada **Pry**, que no viene con Ruby: hay que instalarla. Instalarla implica entender qué es una gema. Y nadie te explicó todavía qué es una gema.

Esta parte cubre exactamente ese hueco. Si ya tenés Pry andando y sabés usarlo, saltá directo a la Parte 1.

---

## 1. Qué es una gema 🟡

Arranquemos por el caso. Para instalar Pry, el comando es:

```bash
gem install pry
```

Vamos a desglosar cada palabra, porque las tres importan.

**`gem`** es un programa que ya tenés instalado: viene junto con Ruby, sin que hagas nada. Es el gestor de paquetes de Ruby. Se llama **RubyGems**.

> 🕳️ **Madriguera — gestor de paquetes**
> Un programa cuya única tarea es bajar, instalar, actualizar y desinstalar librerías escritas por otros, resolviendo solo de qué dependen. Cada lenguaje tiene el suyo: Node tiene `npm`, Python tiene `pip`, Ruby tiene `gem`.
> *Volvé al camino — con saber que existe alcanza.*

**`install`** le dice qué hacer: bajar e instalar.

**`pry`** es el nombre de la **gema** que querés. Una gema es una librería de Ruby empaquetada de una forma estándar: un montón de archivos `.rb` (más algo de metadata: nombre, versión, de qué otras gemas depende) comprimidos en un único archivo `.gem` y publicados en un sitio central llamado rubygems.org, desde donde cualquiera puede instalarla con el comando de arriba.

Entonces, cuando ejecutás `gem install pry`, lo que pasa es:

1. `gem` busca en rubygems.org una gema que se llame `pry`.
2. Lee de qué otras gemas depende (Pry depende de dos: `coderay`, que colorea el código, y `method_source`, que sabe leer el código fuente de un método).
3. Baja las tres, las descomprime y las guarda en una carpeta de tu instalación de Ruby.
4. Si la gema trae un programa ejecutable (Pry lo trae), lo deja disponible como comando: por eso después vas a poder escribir `pry` en la terminal.

**Lo que NO es una gema:** no es una aplicación que bajás de una página web y hacés doble click, ni una "consola" distinta que reemplaza a otra, ni algo que se instala por fuera de Ruby. Es código Ruby que se suma al Ruby que ya tenés. Pry, en particular, es un programa escrito en Ruby que corre adentro de tu Ruby. Esto va a importar más adelante en la clase, cuando veas que si rompés algo básico del lenguaje desde la consola, se rompe la consola misma.

---

## 2. Verificar qué tenés instalado 🟡

Abrí una terminal. En Mac, la aplicación **Terminal** (está en Aplicaciones → Utilidades, o buscala con Spotlight). En Windows, **PowerShell** o, mejor, **Windows Terminal** (viene con Windows 11; en Windows 10 se baja gratis de la Microsoft Store).

Escribí esto y mirá qué responde:

```bash
ruby -v
# Resultado esperado: una línea parecida a
#   ruby 3.3.6 (2024-11-05 revision 75015d4c1f) [arm64-darwin24]
# Lo que importa es el número después de "ruby": tiene que empezar con 3.
```

```bash
gem -v
# Resultado esperado: un número de versión, por ejemplo
#   3.5.22
# Si responde un número, RubyGems está y funciona. No hace falta más.
```

**Si `ruby -v` responde con un número que empieza con 2**, o directamente dice que el comando no existe, andá a la sección 3. Ruby 2 está discontinuado y algunos ejemplos que circulan por ahí ni siquiera corren en las versiones viejas o nuevas indistintamente.

> ⚠️ Vas a cruzarte con material viejo que usa una clase llamada `Fixnum` para los números enteros. No existe más: en Ruby 3 los enteros son `Integer`. Si un ejemplo con `Fixnum` te falla, es por eso, no por algo que hiciste mal.

**Solo en Mac**, hacé una verificación más:

```bash
which ruby
# Este comando te dice DÓNDE está el ruby que se ejecuta cuando escribís "ruby".
#
# Si responde  /usr/bin/ruby  → estás usando el Ruby que trae macOS de fábrica.
#   Es viejo (2.6) y el sistema no te deja instalarle gemas sin permisos de
#   administrador. NO lo uses: andá a la sección 3 e instalá uno propio.
#
# Si responde algo con  .rbenv  o  homebrew  u  /opt/  en la ruta → es un Ruby
#   instalado por vos. Perfecto, seguí a la sección 4.
```

En Windows no hay Ruby de fábrica, así que si `ruby -v` respondió con un 3, es uno que instalaste vos y está bien.

---

## 3. Si no tenés Ruby (o tenés el del sistema en Mac) 🟡

Salteá esta sección si la anterior te dio un Ruby 3 propio.

### Mac

La forma limpia es con **rbenv**, una herramienta que te deja tener varias versiones de Ruby instaladas y elegir cuál usar, sin tocar el Ruby del sistema. Se instala con **Homebrew**, el instalador de programas de línea de comandos para Mac. Si no tenés Homebrew, en https://brew.sh hay una única línea para instalarlo.

```bash
# 1. Instalar rbenv y su instalador de versiones de Ruby
brew install rbenv ruby-build

# 2. Activar rbenv cada vez que abrís una terminal.
#    Mac usa zsh como shell; esta línea agrega la activación a su archivo de configuración.
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc

# 3. Recargar la configuración en la terminal actual (o cerrarla y abrir otra)
source ~/.zshrc

# 4. Ver qué versiones hay disponibles y elegir la última 3.x estable
rbenv install -l
#    Resultado esperado: una lista corta de versiones, por ejemplo 3.2.6, 3.3.6, 3.4.1...

# 5. Instalar una (tarda unos minutos: compila Ruby desde el código fuente)
rbenv install 3.3.6

# 6. Dejarla como la versión por defecto de tu usuario
rbenv global 3.3.6

# 7. Verificar
ruby -v      # Resultado esperado: ruby 3.3.6 ...
which ruby   # Resultado esperado: /Users/TU-USUARIO/.rbenv/shims/ruby
```

Si el paso 7 sigue mostrando `/usr/bin/ruby`, cerrá la terminal, abrí una nueva y repetí. La activación del paso 2 solo aplica a terminales abiertas después de configurarla.

### Windows

En Windows se usa **RubyInstaller**, que es un instalador gráfico común y corriente.

1. Entrá a https://rubyinstaller.org/downloads/ y bajá la versión marcada como **"Ruby+Devkit 3.x (x64)"** — la que dice *Devkit*, no la otra. El Devkit es un conjunto de herramientas de compilación que algunas gemas necesitan para instalarse; Pry no lo necesita, pero más adelante otras sí, y es mejor tenerlo desde ahora.
2. Ejecutá el instalador. En la pantalla de opciones, dejá tildado **"Add Ruby executables to your PATH"**: es lo que hace que `ruby` y `gem` funcionen desde cualquier terminal.
3. Al terminar, se abre una ventana negra que pregunta qué componentes del Devkit instalar. Apretá **Enter** para aceptar el default. Espera a que termine y cerrá esa ventana.
4. **Abrí una terminal nueva** (las que ya estaban abiertas no ven el Ruby recién instalado) y verificá:

```powershell
ruby -v    # Resultado esperado: ruby 3.3.6 ... [x64-mingw-ucrt]
gem -v     # Resultado esperado: un número de versión
```

---

## 4. Instalar Pry 🟡

Con un Ruby 3 propio funcionando, esto es una línea:

```bash
gem install pry
# Resultado esperado: varias líneas que terminan en algo como
#   Successfully installed coderay-1.1.3
#   Successfully installed method_source-1.1.0
#   Successfully installed pry-0.15.2
#   3 gems installed
# (los números de versión pueden ser otros; lo que importa es "Successfully installed")
```

Los tres "installed" son Pry y sus dos dependencias, como vimos en la sección 1.

**Si en Mac te responde `You don't have write permissions for the /Library/Ruby/Gems/...`**, es la confirmación de que estás usando el Ruby del sistema. No le pongas `sudo` adelante para forzarlo: volvé a la sección 3 e instalá un Ruby propio. Es la solución de verdad; `sudo` es un parche que te va a traer problemas después.

Ahora probalo:

```bash
pry
# Resultado esperado: la terminal cambia a un prompt como este:
#   [1] pry(main)>
# Ya estás adentro de Pry.
```

Escribí una expresión cualquiera para ver cómo responde:

```ruby
[1] pry(main)> 2 + 2
=> 4
[2] pry(main)> "hola".upcase
=> "HOLA"
[3] pry(main)> exit
# exit te devuelve a la terminal normal.
```

Cada línea que escribís se **lee**, se **evalúa**, se **imprime** el resultado (esa es la flecha `=>`) y se vuelve a esperar. Por eso a este tipo de consola se lo llama **REPL** (*read–eval–print loop*). Vas a ver que Pry además colorea las cosas: los strings de un color, los números de otro, los nombres de clase subrayados. Ese es todo el motivo por el que se usa Pry y no la consola que trae Ruby.

### Pry no reemplaza a nada

Ruby ya trae una consola interactiva propia, que se lanza con el comando `irb`. Pry no la borra ni la reemplaza ni se vuelve "la consola por defecto": **las dos conviven**, y elegís cuál usar según el comando que escribas. `irb` lanza la de Ruby, `pry` lanza la que acabás de instalar. Nada más cambió en tu sistema. Si mañana desinstalás Pry (`gem uninstall pry`), `irb` sigue estando exactamente igual.

### Solo en Windows: los colores

Si abriste Pry desde el `cmd.exe` viejo (la ventana negra clásica) y ves símbolos raros en vez de colores, cerrala y usá **Windows Terminal** o **PowerShell**. El problema es la ventana, no Pry.

---

## 5. Conseguir el código de la clase 🔴

Toda la clase corre sobre un archivo llamado `age-clase2.rb`: el modelo de guerreros, atacantes y defensores que se construyó en las dos clases anteriores. **El código completo está en la Parte 1 de esta serie**, comentado bloque por bloque. Tenés dos formas de tenerlo en tu máquina:

**Opción A — lo escribís vos.** Creá una carpeta para la clase, y adentro un archivo `age-clase2.rb` con el código de la Parte 1 pegado tal cual. Es la opción más simple y no depende de nada externo.

**Opción B — clonás el repositorio de la cátedra.** Si tenés `git` instalado:

```bash
git clone -b ruby-age https://github.com/tadp-utn-frba/tadp-clases.git
# -b ruby-age  → trae directamente la rama donde está el código de estas clases
cd tadp-clases/src
ls
# Resultado esperado: dos archivos
#   age-clase2.rb  age.rb
# (age.rb es la versión de la clase 1; el que usamos es age-clase2.rb)
```

Cualquiera de las dos opciones te deja parado en una carpeta con `age-clase2.rb` adentro. Eso es lo único que importa.

---

## 6. Cómo se usa la consola con el programa cargado 🔴

Esta sección es la que nadie te explicó, y es donde la gente se traba. Leela entera aunque te parezca obvia.

### Lanzar Pry desde la carpeta correcta

Pry se lanza **parado en la carpeta donde está el archivo**. Si lo lanzás desde otro lado, no lo va a encontrar cuando lo quieras cargar.

```bash
cd la-carpeta-donde-esta-el-archivo
pry
```

### Cargar el programa

Una vez adentro:

```ruby
[1] pry(main)> require_relative 'age-clase2'
=> true
```

`require_relative` lee el archivo, ejecuta todo lo que tiene adentro (las definiciones de módulos y clases) y lo deja disponible en la sesión. El `=> true` significa "lo cargué". La ruta es relativa a la carpeta donde lanzaste Pry, y el `.rb` es opcional: `'age-clase2'` y `'age-clase2.rb'` son equivalentes.

A partir de acá, en la consola existen `Guerrero`, `Espadachin`, `Atacante`, `Defensor` y todo lo demás que define el archivo, y podés hacer lo que la clase hace:

```ruby
[2] pry(main)> atila = Guerrero.new
=> #<Guerrero:0x000055c7452ed490 @energia=100, @potencial_defensivo=10, @potencial_ofensivo=20>
```

Esa respuesta es Pry mostrándote el objeto: la clase, un identificador interno (el número largo, que va a ser distinto en tu máquina) y el estado interno con sus valores. Eso ya es un pedazo de lo que la clase va a explotar.

### Leer el prompt

```
[2] pry(main)>
 │   │     │
 │   │     └─ ">" significa "esperando una línea nueva"
 │   └─ "main" es el contexto en el que estás parado (el nivel más alto, fuera de toda clase)
 └─ el número de la línea, solo para ubicarte
```

### Definir algo en varias líneas

Cuando empezás una definición que no cierra en una sola línea (una clase, un método, un módulo), Pry se da cuenta y cambia el `>` por un `*`, que significa "esto sigue":

```ruby
[3] pry(main)> class A
[3] pry(main)*   def bleh
[3] pry(main)*     2
[3] pry(main)*   end
[3] pry(main)* end
=> :bleh
```

Mientras veas el `*`, Pry está acumulando. Cuando escribís el `end` que cierra todo, evalúa el bloque completo y responde. Fijate que el número de línea no avanza mientras dura la definición. Y fijate en el `=> :bleh`: definir un método **devuelve el nombre del método como símbolo**. No es un error, es Ruby siendo consistente: todo devuelve algo.

### Cuando una respuesta es demasiado larga

Algunas preguntas devuelven listas de decenas de elementos. Pry no las tira todas juntas: muestra una pantalla y se queda esperando con un `:` abajo de todo. Eso es un **paginador**.

- **Enter** avanza una línea. **Espacio** avanza una pantalla.
- **`q`** sale del paginador y vuelve al prompt.

Si el paginador te molesta, se puede apagar para la sesión actual:

```ruby
[4] pry(main)> Pry.config.pager = false
=> false
# A partir de acá las listas largas se imprimen enteras, de corrido.
```

### Salir, y cuándo hace falta salir

```ruby
[5] pry(main)> exit
```

`exit` cierra Pry y te devuelve a la terminal. **Todo lo que definiste en la sesión se pierde**: las clases que creaste, las variables, los cambios que le hiciste al programa. Lo único que queda es el archivo en disco. Esto no es un defecto: es lo que hace que puedas experimentar sin miedo.

Hay dos momentos en los que vas a tener que salir y volver a entrar:

**1. Cuando editás el archivo.** `require_relative` carga el archivo **una sola vez** por sesión; si después lo modificás en el editor, la sesión sigue viendo la versión vieja. La forma segura de ver los cambios es salir, volver a entrar y volver a cargar:

```ruby
[6] pry(main)> exit
$ pry
[1] pry(main)> require_relative 'age-clase2'
=> true
```

**2. Cuando rompés la consola.** En la Parte 4 vas a ver que desde la consola se puede modificar cualquier cosa del lenguaje, incluidas las que Pry usa para funcionar. Si hacés eso, Pry deja de responder bien, y la única salida es `exit` y volver a empezar. Está bien que pase: va a pasar a propósito, como demostración. No es que rompiste tu instalación; la sesión rota muere con `exit` y la siguiente arranca limpia.

---

## 7. Consola contra botón verde 🟡

Ahora sí se entiende la diferencia con lo que venías haciendo en RubyMine.

El **botón verde ejecuta un archivo de punta a punta**: lee `age-clase2.rb`, corre todo lo que hay adentro, muestra lo que se imprima y termina. Cuando termina, el programa dejó de existir. Si querés preguntarle algo a un objeto, tenés que escribir la pregunta en el archivo, guardar, volver a correr, leer el output, y repetir. Cada pregunta nueva es un ciclo entero.

La **consola mantiene el programa vivo** entre pregunta y pregunta. Cargás el archivo una vez, creás un guerrero, y ese guerrero sigue existiendo mientras vos pensás la próxima pregunta. Le pedís la clase, después los métodos, después le cambiás la energía, después comprobás que cambió. Todo sobre el mismo objeto, sin recargar nada. Para explorar un sistema, que es lo que esta clase hace durante tres horas, no hay comparación.

**Si preferís no salir de RubyMine**, no hace falta: el IDE trae una terminal integrada. Se abre con **View → Tool Windows → Terminal** (atajo: `⌥F12` en Mac, `Alt+F12` en Windows). Es una terminal común, ya parada en la carpeta del proyecto. Escribís `pry` ahí y funciona igual que en la Terminal del sistema, con la ventaja de tener el archivo abierto arriba y la consola abajo.

---

## 8. Una cosa que Pry mete adentro de tu programa 🟢

Guardá esto para cuando llegues a la Parte 2, porque ahí te va a hacer ruido.

Pry, para poder mostrarte los objetos bonitos, le agrega un módulo propio a **todos los objetos** del programa mientras la sesión está abierta. Se llama `PP::ObjectMixin`, y va a aparecer cuando le preguntes a una clase por sus ancestros, metido entre `Object` y `Kernel`. **No es parte de Ruby.** Es un pasajero de la herramienta. Cuando lo veas, ignoralo; y si algún día corrés el mismo código sin Pry, no va a estar. Lo menciono acá para que cuando aparezca no pienses que tu programa tiene algo raro.

---

## Estás listo

Si llegaste hasta acá con:

- `ruby -v` respondiendo un 3,
- `gem install pry` terminado en "Successfully installed",
- un `age-clase2.rb` en una carpeta,
- y `require_relative 'age-clase2'` respondiendo `=> true` adentro de Pry,

entonces tenés exactamente lo mismo que se usa en la clase. Seguí con la Parte 1.

---

### Antes de seguir, tres preguntas para vos

1. ¿Qué diferencia hay entre instalar una gema e instalar un programa como RubyMine?
2. Si editás `age-clase2.rb` mientras Pry está abierto, ¿por qué la consola no ve el cambio?
3. ¿Qué te da la consola interactiva que el botón verde de RubyMine no te puede dar?

*(Las respuestas no están acá. Si alguna no te sale, es la señal de qué releer.)*
