# clase06-prototype.rb — framework completo

module Prototyped
  SIN_NADA = {}.freeze                       # diccionario vacío e inmutable, para objetos congelados (M6)

  # ---------- propiedades: estado propio de cada objeto (M2) ----------
  def set_property(nombre, valor)
    propiedades[nombre] = valor
  end

  def get_property(nombre)
    propiedades[nombre]                      # nil si no existe
  end

  def has_property?(nombre)
    propiedades.key?(nombre)
  end

  def property_names                         # M7: copy necesita listar las propiedades
    propiedades.keys
  end

  # ---------- métodos: comportamiento propio de cada objeto (M3, M5) ----------
  def set_method(selector, bloque)
    metodos[selector] = bloque               # guarda el proc; no define nada en ninguna clase
  end

  def defines_method?(selector)
    metodos.key?(selector)
  end

  def own_method(selector)
    metodos[selector]
  end

  # ---------- prototipos (M5, M9) ----------
  def set_prototype(prototipo)
    set_prototypes([prototipo])
  end

  def set_prototypes(prototipos)
    @__prototypes__ = prototipos.dup         # copia de la lista: la del usuario puede cambiar después
  end

  def prototypes
    @__prototypes__ || []
  end

  def prototype
    prototypes.first
  end

  # la linealización: yo, y después cada prototipo con su propia cadena, en orden, sin repetir (M9)
  def prototype_chain(cadena = [])
    return cadena if cadena.any? { |objeto| objeto.equal?(self) }   # ya visitado: corta ciclos y diamantes
    cadena << self
    prototypes.each { |prototipo| prototipo.prototype_chain(cadena) }
    cadena
  end

  def find_method(selector)                  # el proc del primero de la cadena que lo define, o nil
    duenio = prototype_chain.find { |objeto| objeto.defines_method?(selector) }
    duenio && duenio.own_method(selector)
  end

  # ---------- la implementación siguiente (M9) ----------
  def call_next(*args)
    marco = pila.last
    raise NoMethodError, "call_next fuera de un método prototipado" unless marco
    args = marco[:args] if args.empty?       # sin argumentos: los mismos que recibió el método actual
    cadena = prototype_chain
    siguientes = cadena.drop(cadena.index { |objeto| objeto.equal?(marco[:duenio]) } + 1)
    resolver(marco[:selector], siguientes, args) do
      raise NoMethodError, "#{marco[:selector]} no tiene implementación siguiente"
    end
  end

  # ---------- clone: copia independiente (M4, M5) ----------
  def initialize_copy(original)
    super
    @__properties__ = @__properties__.dup if @__properties__
    @__methods__    = @__methods__.dup    if @__methods__
    @__prototypes__ = @__prototypes__.dup if @__prototypes__
    @__stack__      = nil
  end

  private

  # el gancho (M5): 1º un método de la cadena · 2º una propiedad propia · 3º un setter · 4º nadie (M6, M8)
  def method_missing(selector, *args)
    if selector.end_with?("=") && prototype_chain.none? { |objeto| objeto.defines_method?(selector) }
      asignar(selector.to_s.chomp("=").to_sym, args.first)
    else
      resolver(selector, prototype_chain, args) { super }
    end
  end

  def respond_to_missing?(selector, include_private = false)
    !find_method(selector).nil? || has_property?(selector) || selector.end_with?("=") || super
  end

  # busca el selector entre los candidatos; si ninguno lo define, la propiedad propia; si no, lo que diga el bloque
  def resolver(selector, candidatos, args)
    duenio = candidatos.find { |objeto| objeto.defines_method?(selector) }
    if duenio
      ejecutar(selector, duenio, args)
    elsif has_property?(selector)
      get_property(selector)
    else
      yield
    end
  end

  def ejecutar(selector, duenio, args)
    pila.push({ selector: selector, duenio: duenio, args: args })   # call_next va a necesitar saber esto
    instance_exec(*args, &duenio.own_method(selector))               # self = el receptor, no el dueño
  ensure
    pila.pop                                                         # siempre, aunque el método explote
  end

  def asignar(nombre, valor)                 # M8: un proc es un método; cualquier otra cosa, una propiedad
    if valor.is_a?(Proc)
      set_method(nombre, valor)
    else
      set_property(nombre, valor)
    end
  end

  def pila
    @__stack__ ||= []
  end

  def propiedades                            # inicialización perezosa; en un objeto congelado, solo lectura
    @__properties__ || (frozen? ? SIN_NADA : @__properties__ = {})
  end

  def metodos
    @__methods__ || (frozen? ? SIN_NADA : @__methods__ = {})
  end
end

class PrototypedObject
  include Prototyped

  def initialize(&bloque)                    # M8: PrototypedObject.new { self.energia = 100 }
    instance_exec(&bloque) if bloque
  end
end

class PrototypedConstructor                  # M7, M8
  attr_reader :prototype

  def self.copy(prototipo)
    new(prototipo, proc { |nuevo|
      prototipo.property_names.each do |nombre|
        nuevo.set_property(nombre, prototipo.get_property(nombre))
      end
    })
  end

  def self.create(&bloque)
    new(PrototypedObject.new(&bloque))
  end

  # un proc recibe primero al objeto nuevo; un bloque corre con self = el objeto nuevo; nada: un mapa
  def initialize(prototipo, inicializador = nil, aridad: nil, padre: nil, &bloque)
    @prototype = prototipo
    @padre = padre
    if inicializador
      @aridad = aridad || inicializador.arity - 1
      @cuerpo = inicializador
    elsif bloque
      @aridad = aridad || bloque.arity
      @cuerpo = proc { |nuevo, *args| nuevo.instance_exec(*args, &bloque) }
    else
      @aridad = 1
      @cuerpo = inicializador_por_defecto
    end
  end

  def new(*args)
    nuevo = PrototypedObject.new
    nuevo.set_prototype(prototype)
    sobrantes = inicializar(nuevo, args)
    raise ArgumentError, "sobran argumentos: #{sobrantes.inspect}" unless sobrantes.empty?
    nuevo
  end

  def with(inicializador = nil, &bloque)
    PrototypedConstructor.new(prototype, inicializador, &bloque)
  end

  def with_properties(nombres)
    PrototypedConstructor.new(prototype, proc { |nuevo, *valores|
      nombres.zip(valores).each { |nombre, valor| nuevo.set_property(nombre, valor) }
    }, aridad: nombres.size)
  end

  def extended(inicializador = nil, &bloque)
    PrototypedConstructor.new(prototype, inicializador, padre: self, &bloque)
  end

  protected

  def inicializar(nuevo, args)               # consume sus argumentos (primero el padre) y devuelve el resto
    args = @padre.inicializar(nuevo, args) if @padre
    raise ArgumentError, "faltan argumentos: esperaba #{@aridad}, llegaron #{args.size}" if args.size < @aridad
    @cuerpo.call(nuevo, *args.take(@aridad))
    args.drop(@aridad)
  end

  private

  def inicializador_por_defecto
    proc { |nuevo, valores|
      valores.each do |nombre, valor|
        raise ArgumentError, "el prototipo no tiene la propiedad #{nombre}" unless prototype.has_property?(nombre)
        nuevo.set_property(nombre, valor)
      end
    }
  end
end
