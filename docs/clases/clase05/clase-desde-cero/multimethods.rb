# multimethods.rb — framework completo

class PartialBlock
  attr_reader :types, :block

  def initialize(types, &block)
    unless block.arity == types.size
      raise ArgumentError, "la firma tiene #{types.size} tipos y el bloque #{block.arity} parámetros"
    end
    @types = types
    @block = block
  end

  # ¿el tipo de la firma acepta este valor?  (M6: un tipo puede ser una lista de mensajes)
  def acepta?(tipo, valor)
    if tipo.is_a?(Array)
      tipo.all? { |mensaje| valor.respond_to?(mensaje) }
    else
      valor.is_a?(tipo)
    end
  end

  def matches?(*args)
    return false unless args.size == types.size
    args.zip(types).all? do |valor, tipo|
      acepta?(tipo, valor)
    end
  end

  # ¿la firma acepta argumentos de estos tipos?  (M5: respond_to? extendido; M6: listas de mensajes)
  def matches_types?(tipos_pedidos)
    return false unless tipos_pedidos.size == types.size
    tipos_pedidos.zip(types).all? do |pedido, tipo|
      if tipo.is_a?(Array)
        tipo.all? { |mensaje| pedido.method_defined?(mensaje) }
      else
        pedido <= tipo
      end
    end
  end

  # distancia de cada argumento a su tipo, ponderada por la posición (M5; M6: 0.5 para listas)
  def distance(*args)
    args.zip(types).each_with_index.sum do |(valor, tipo), i|
      distancia = tipo.is_a?(Array) ? 0.5 : valor.class.ancestors.index(tipo)
      distancia * (i + 1)
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

  def multimethods
    partial_blocks.keys
  end

  def multimethod(name)
    partial_blocks.fetch(name) { raise ArgumentError, "#{self} no tiene el multimétodo #{name}" }
  end

  def partial_def(name, types, &block)
    definiciones = partial_blocks[name]
    definiciones.reject! { |partial_block| partial_block.types == types }   # M5: misma firma → pisa
    definiciones << PartialBlock.new(types, &block)

    define_method(name) do |*args|
      candidatas = definiciones.select do |partial_block|                  # M5: todas las que matchean
        partial_block.matches?(*args)
      end
      if candidatas.empty?
        raise NoMethodError, "ninguna definición de #{name} matchea con #{args.inspect}"
      end
      definicion = candidatas.min_by do |partial_block|                    # M5: la más específica
        partial_block.distance(*args)
      end
      definicion.call_in_context(self, *args)
    end
  end
end

class Object
  alias_method :respond_to_original?, :respond_to?

  def respond_to?(name, include_private = false, types = nil)
    return respond_to_original?(name, include_private) if types.nil?
    definiciones = self.class.ancestors.flat_map { |modulo| modulo.partial_blocks.fetch(name, []) }
    definiciones.any? { |partial_block| partial_block.matches_types?(types) }
  end
end
