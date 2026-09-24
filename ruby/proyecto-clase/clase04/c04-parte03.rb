require 'pry'
require_relative '../lib/age'

# =========================================================
# =========================================================

numeros = [10, 20, 30, 40]

imprimir = proc { puts "hola" }
imprimir_n = proc { |n| puts n }
imprimir_self = proc { puts self }

def m1
  yield # ejecuta el bloque que llegó pegado a este envío
  puts "M1"
end

def m2
  yield if block_given? # ejecutá el bloque solo si me pasaron uno
  puts "M2"
end

def m3
  if block_given?
    yield
  end
  puts "M3"
end

def m4
  if block_given?;
    yield;
  end
  puts "M4"
end

# =========================================================

def m11(&bloque)
  # &bloque: "el bloque que llegue al final de los parámetros, dámelo con este nombre"
  bloque.call(10) # ahora bloque es un objeto: un Proc. Lo ejecuto con call, pasándole 10
  puts "M11"
end

def m22(a, b, &bloque)
  if block_given? # ¿me pasaron un bloque?
    bloque.call(a + b) #   sí → lo ejecuto con la suma
  else
    puts "sin bloque: #{a + b}" #   no → imprimo la suma
  end
end

# V2 — mismo método, pero atiende primero el caso "sin bloque" y sale
def m23(a, b, &bloque)
  if !block_given? # ! = negación, como en JS: "si NO me pasaron bloque"
    puts "sin bloque: #{a + b}"
    return # sale del método acá. Lo de abajo NO se ejecuta.
  end
  bloque.call(a + b) # solo se llega acá si SÍ vino bloque
end

def m24(a, b, &bloque)
  # x if c === hacé x si c
  return bloque.call(a + b) if block_given?
  puts("sin bloque: #{a + b}")
end

def m25(a, b, &bloque)
  # x unless c === hacé x si c es falso. === x if !c
  return puts("sin bloque: #{a + b}") unless block_given?
  bloque.call(a + b)
end

def m26(a, b, &bloque)
  return puts("sin bloque: #{a + b}") unless bloque # o: unless block_given?
  bloque.call(a + b)
end

def m33(proc1, proc2)
  proc1.call + proc2.call
end

def m44(&bloque)
  bloque.call
end

mostrar = proc { |n| puts "mostrando ::::::> #{n}" }

# un proc que recibe a, y devuelve OTRO proc que recibe b
sumar = proc { |a| proc { |b| a + b } }
# es una función que devuelve otra función.
# (Esto se llama aplicación parcial, y la forma general, currificación.
sumar_1 = sumar.call(1) # aplico el primero: obtengo un proc "que sabe que a es 1"
puts sumar_1.call(2) # => 3
puts sumar.call(1).call(2) # => 3     ← lo mismo, encadenado

# =========================================================

mi_proc = proc { |x| puts x.inspect }
mi_lambda = lambda { |x| puts x.inspect }

mi_lambda.call(10) # => 10       ← se comporta básicamente igual que el proc
puts mi_proc.class # => Proc
puts mi_lambda.class # => Proc     ← ⚠️ la MISMA clase. No hay una clase Lambda.
puts mi_proc.lambda? # => false
puts mi_lambda.lambda? # => true     ← lo distingue una marca interna
puts mi_lambda # => #<Proc:0x… archivo.rb:2 (lambda)>   ← y se ve en el inspect

mi_proc.call(1) # => 1
mi_proc.call # => nil      ← faltó un parámetro: x vale nil. No falla.
mi_proc.call(1, 2) # => 1        ← sobró uno: lo recibe y lo ignora. No falla.

mi_lambda.call(1) # => 1
=begin
mi_lambda.call # => ArgumentError: wrong number of arguments (given 0, expected 1)
mi_lambda.call(1, 2) # => ArgumentError: wrong number of arguments (given 2, expected 1)
=end

# =========================================================

def m1_proc
  proc_con_return = proc { return 5 } # un proc que retorna 5
  proc_con_return.call # lo ejecuto
  10 # y el método devuelve 10… ¿o no?
end

def m2_proc
  proc_con_return = proc { return "<#{self}> >>> 5" }
  proc_con_return.call
  10
end

def m1_lambda
  lambda_con_return = lambda { return 5 } # return DENTRO de una lambda
  lambda_con_return.call # sale de la LAMBDA, nada más; el método sigue
  10
end

# puts m1_lambda # => 10

# =========================================================

def contador
  n = 0 # variable local del método: nace acá, y "debería" morir cuando el método termina
  proc do
    # el proc que se devuelve usa n…
    n += 1 # …la incrementa…
    n # …y la devuelve
  end
end

# el método termina. Su contexto, con su n, se descarta. ¿O no?

=begin
c1 = contador # c1 es el proc. El método contador ya terminó.
puts c1.call # => 1     ← n sigue viva adentro del proc
puts c1.call # => 2     ← y sigue siendo LA MISMA n: la aumentó el call anterior
c2 = contador # otra llamada a contador: otro contexto, OTRA n, otro proc
puts c2.call # => 1     ← c2 arranca de cero
puts c1.call # => 3     ← c1 sigue con la suya
=end

# A esto se lo llama closure (clausura):
# un objeto que representa código y
# que encierra el contexto en el que fue definido,
# manteniéndolo vivo mientras el objeto viva.
# En Ruby, bloques, procs y lambdas son closures.

# =========================================================
# =========================================================

binding.pry # al final: te deja la consola adentro de este archivo
# Ejecutar con ruby + la ruta del archivo:
# > ruby clase04/experimentos_parte2.rb
