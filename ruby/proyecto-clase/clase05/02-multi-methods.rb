require 'pry'

# =========================================================
# =========================================================

class PartialBlock
  def initialize(types, &block)
    # Validacion: Lista de tipos VS parametros del bloque
    unless types.length == block.arity
      raise ArgumentError, "La cantidad de tipos no coincide con los parámetros del bloque"
      # raise ArgumentError.new("La cantidad de tipos no coincide con los parámetros del bloque")
    end

    @types = types
    @block = block
  end

  def matches?(*args)
    return false unless args.length == @types.length
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



# =========================================================
# =========================================================

class A
  partial_def :concat, [String, String] do |s1,s2|
    s1 + s2
  end

  partial_def :concat, [String, Integer] do |s1,n|
    s1 * n
  end

  partial_def :concat, [Array] do |a|
    a.join
  end
end

A.new.concat('hello', ' world') # devuelve 'hello world'
A.new.concat('hello', 3) # devuelve 'hellohellohello'
A.new.concat(['hello', ' world', '!']) # devuelve 'hello world!'
A.new.concat('hello', 'world', '!') # Lanza una excepción!

A.multimethods() #[:concat]
A.multimethod(:concat) #Representación del multimethod



# =========================================================
# =========================================================

binding.pry # al final: te deja la consola adentro de este archivo
# Ejecutar con ruby + la ruta del archivo:
# > ruby <...>
