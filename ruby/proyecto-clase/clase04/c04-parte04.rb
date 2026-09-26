require 'pry'
require_relative '../lib/age'

# =========================================================
# =========================================================

nombre = "pepita" # x = …  →  variable local del archivo, creada acá

saludar = proc do
  saludo = "Hola" # x = …  →  variable local, creada adentro del proc
  puts saludo + " " + nombre # dos palabras sueltas: las dos son variables → las usa
end

saludar.call # => Hola pepita

=begin
contexto del archivo (main)
┌───────────────────────────────┐
│ nombre, saludar, mutar        │◄── el proc VE esto, y lo MODIFICA
│   ┌───────────────────────┐   │
│   │ contexto del proc     │   │
│   │ saludo                │   │──► lo que crea acá, se queda acá
│   └───────────────────────┘   │
└───────────────────────────────┘
=end

nombre = "pepita"

saludar2_proc = proc do
  puts "Soy #{self}"
  puts "Hola" + nombre
end

class A
  puts self

  def saludar
    self;
  end

  def self.algo
    self;
  end
end

B = Class.new do
  # crea una clase nueva; el bloque es su cuerpo
  nombre = "Axel" # ¿hay variable nombre? sí, la de afuera → la pisa (sección 2)
  puts nombre # => Axel
  puts self # => #<Class:0x…>    ← self es la clase nueva (todavía sin nombre)
  def m1 # adentro se puede usar def normal: define un método de instancia
  end
end

# =========================================================
# =========================================================

binding.pry # al final: te deja la consola adentro de este archivo
# Ejecutar con ruby + la ruta del archivo:
# > ruby clase04/experimentos_parte2.rb
