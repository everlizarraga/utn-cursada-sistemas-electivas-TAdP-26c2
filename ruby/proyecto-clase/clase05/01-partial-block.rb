require 'pry'

# =========================================================
# =========================================================

class PartialBlock
  def initialize(types, &block)
    # Validacion: Lista de tipos VS parametros del bloque
    # if types.length != block.arity
    unless types.length == block.arity
      raise ArgumentError, "La cantidad de tipos no coincide con los parámetros del bloque"
      # raise ArgumentError.new("La cantidad de tipos no coincide con los parámetros del bloque")
    end

    @types = types
    @block = block
  end

  def matches?(*args)
    # Los argumentos reales VS lista de tipos
    # 1ro comparando cantidades
    # unless args.length == @types.length; return false; end
    return false unless args.length == @types.length

    # 2do comparando cada uno de los tipos
    args.zip(@types).all? do |valor, tipo|
      valor.is_a? tipo
    end
  end

  def call(*args)
    unless self.matches?(*args)
      raise ArgumentError.new("Los argumentos no coinciden con la firma")
    end
    @block.call(*args)
  end

end

# =========================================================
# =========================================================

helloBlock = PartialBlock.new([String]) do |who|
  "Hello #{who}"
end

puts helloBlock.matches?("a") # true
puts helloBlock.matches?(1) # false
puts helloBlock.matches?("a", "b") # false

puts helloBlock.call("world!") #devuelve "Hello world!"

# puts helloBlock.call(1) #Arroja excepción! no matchea el tipo

# =========================================================
# =========================================================

binding.pry # al final: te deja la consola adentro de este archivo
# Ejecutar con ruby + la ruta del archivo:
# > ruby <...>
