require 'pry'
require_relative '../lib/age'

# =========================================================
# =========================================================

def hacer_combatir(guerrero)              # recibe un guerrero, lo hace pelear, devuelve su energía final
  oponente = Guerrero.new(20, 100, 20)    # potencial ofensivo 20, energía 100, potencial defensivo 20
  guerrero.atacar(oponente)
  oponente.atacar(guerrero)
  guerrero.energia
end

atila = Guerrero.new           # 20, 100, 10: los defaults
puts atila.energia             # => 100
puts hacer_combatir(atila)     # => 90     ← perdió 10: su ataque no pasó (20 no supera 20), el del oponente sí
#    (20 > 10, daño 10). Pero ¿qué mensajes recibió atila para llegar ahí?


# =========================================================
# =========================================================

binding.pry    # al final: te deja la consola adentro de este archivo
