# frozen_string_literal: true

require 'pry'

# =========================================================
# =========================================================

class PartialBlock
  attr_reader :types, :block

  def initialize(types, &block)
    unless block.arity == types.size
      raise ArgumentError, "la firma tiene #{types.size} tipos y el bloque #{block.arity} parámetros"
    end
    @types = types
    @block = block
  end

  def matches?(*args)
    return false unless args.size == types.size
    args.zip(types).all? do |valor, tipo|
      valor.is_a?(tipo)
    end
  end

  def call(*args)
    unless matches?(*args)
      raise ArgumentError, "los argumentos no coinciden con la firma #{types}"
    end
    block.call(*args)
  end

  def call_in_context(contexto, *args)
    unless matches?(*args)
      raise ArgumentError, "los argumentos no coinciden con la firma #{types}"
    end
    contexto.instance_exec(*args, &block)
  end
end

class Module
  def partial_blocks
    @partial_blocks ||= Hash.new { |hash, clave| hash[clave] = [] }
  end

  def partial_def(name, types, &block)
    definiciones = partial_blocks[name]
    definiciones << PartialBlock.new(types, &block)

    define_method(name) do |*args|
      definicion = definiciones.find do |partial_block|
        partial_block.matches?(*args)
      end
      unless definicion
        raise NoMethodError, "ninguna definición de #{name} matchea con #{args.inspect}"
      end
      definicion.call_in_context(self, *args)
    end
  end
end

# =========================================================
# =========================================================

# =========================================================
# =========================================================

binding.pry # al final: te deja la consola adentro de este archivo
# Ejecutar con ruby + la ruta del archivo:
# > ruby <...>
