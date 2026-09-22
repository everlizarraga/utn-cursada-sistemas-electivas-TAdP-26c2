require 'pry'
require_relative '../lib/age'

# =========================================================
# =========================================================

class Guerrero
  private def method_missing(name, *args)
    if name.start_with?("comerse_")
      @energia += name.to_s.delete_prefix("comerse_").size
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    # misma firma que usa respond_to? por dentro
    name.start_with?("comerse_") || super # el MISMO criterio que method_missing; el resto, super
  end
end

# =========================================================

def hacer_combatir(guerrero)
  oponente = Guerrero.new(20, 100, 20)
  guerrero.atacar(oponente)
  oponente.atacar(guerrero)
  guerrero.energia
end

class RegistradorDeMensajes < BasicObject # ← el único cambio: hereda de BasicObject, no de Object
  attr_reader :mensajes_recibidos

  def initialize(objeto)
    @objeto = objeto
    @mensajes_recibidos = []
  end

  private def method_missing(method, *args)
    @mensajes_recibidos << { mensaje: method, parametros: args }
    @objeto.send(method, *args)
  end

  def respond_to_missing?(method, include_private = false)
    @objeto.respond_to?(method, include_private)
  end
end

atila = Guerrero.new
registrador = RegistradorDeMensajes.new(atila)
hacer_combatir(registrador)

p registrador.is_a?(Guerrero)
# => true                  ← ahora lo contesta atila
puts registrador.to_s
# => #<Guerrero:0x…>       ← indistinguible de atila desde afuera
puts registrador.mensajes_recibidos.size
# => 7               ← los 5 del combate + is_a? + to_s: también quedaron anotados

# =========================================================

class DeafObject < BasicObject # "objeto sordo"
  def method_missing(name, *args)
    self # cualquier mensaje: "sí, sí" y devuelvo el mismo objeto
  end

  def respond_to_missing?(name, include_private)
    true # dice que entiende todo
  end
end

d = DeafObject.new
resultado = d.atacar(1).descansar.lo_que_sea # una cadena entera de mensajes, y nada explota
p "DeafObject :> #{resultado.equal?(d)}"

# =========================================================
# =========================================================

binding.pry # al final: te deja la consola adentro de este archivo
# Ejecutar con ruby + la ruta del archivo:
# > ruby clase04/experimentos_parte2.rb
