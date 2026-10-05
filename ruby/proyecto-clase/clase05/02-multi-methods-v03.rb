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

  def matches_types?(tipos_pedidos)
    # M5: respond_to? con firma
    return false unless tipos_pedidos.size == types.size
    tipos_pedidos.zip(types).all? do |pedido, tipo|
      pedido <= tipo
    end
  end

  def distance(*args)
    # M5: distancia ponderada por posición
    args.zip(types).each_with_index.sum do |(valor, tipo), i|
      valor.class.ancestors.index(tipo) * (i + 1)
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

# =========================================================
# =========================================================

class Module
  def partial_blocks
    @partial_blocks ||= Hash.new { |hash, clave| hash[clave] = [] }
  end

  def multimethods # M5
    partial_blocks.keys
  end

  def multimethod(name)
    # M5
    partial_blocks.fetch(name) { raise ArgumentError, "#{self} no tiene el multimétodo #{name}" }
  end

  def partial_def(name, types, &block)
    definiciones = partial_blocks[name]
    definiciones.reject! { |partial_block| partial_block.types == types } # M5: misma firma → pisa
    definiciones << PartialBlock.new(types, &block)

    define_method(name) do |*args|
      candidatas = definiciones.select do |partial_block|
        # M5: todas las que matchean
        partial_block.matches?(*args)
      end
      if candidatas.empty?
        raise NoMethodError, "ninguna definición de #{name} matchea con #{args.inspect}"
      end
      definicion = candidatas.min_by do |partial_block|
        # M5: la más específica
        partial_block.distance(*args)
      end
      definicion.call_in_context(self, *args)
    end
  end
end

class Object
  alias_method :respond_to_original?, :respond_to? # M5

  def respond_to?(name, include_private = false, types = nil)
    return respond_to_original?(name, include_private) if types.nil?
    definiciones = self.class.ancestors.flat_map { |modulo| modulo.partial_blocks.fetch(name, []) }
    definiciones.any? { |partial_block| partial_block.matches_types?(types) }
  end
end

# =========================================================
# =========================================================

# =========================================================
# =========================================================

binding.pry # al final: te deja la consola adentro de este archivo
# Ejecutar con ruby + la ruta del archivo:
# > ruby <...>
