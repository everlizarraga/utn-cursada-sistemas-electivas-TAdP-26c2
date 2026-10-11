require_relative 'clase06-prototype'

def armar_guerrero
  guerrero = PrototypedObject.new
  guerrero.set_property(:energia, 100)
  guerrero.set_property(:potencial_defensivo, 10)
  guerrero.set_property(:potencial_ofensivo, 30)
  guerrero.set_method(:atacar_a, proc { |otro_guerrero|
    if otro_guerrero.potencial_defensivo < self.potencial_ofensivo
      otro_guerrero.recibe_danio(self.potencial_ofensivo - otro_guerrero.potencial_defensivo)
    end
  })
  guerrero.set_method(:recibe_danio, proc { |danio| self.energia = self.energia - danio })
  guerrero
end

def armar_espadachin(guerrero)
  espadachin = PrototypedObject.new
  espadachin.set_prototype(guerrero)
  espadachin.set_property(:habilidad, 0.5)
  espadachin.set_property(:potencial_espada, 30)
  espadachin.energia = 100
  espadachin.potencial_defensivo = 10
  espadachin.potencial_ofensivo = 30
  espadachin.set_method(:potencial_ofensivo, proc {
    get_property(:potencial_ofensivo) + self.potencial_espada * self.habilidad   # el @potencial_ofensivo de 4.1
  })
  espadachin
end

describe 'propiedades (M2)' do
  it 'guarda y devuelve una propiedad, también como mensaje' do
    guerrero = PrototypedObject.new
    guerrero.set_property(:energia, 100)
    expect(guerrero.get_property(:energia)).to eq 100
    expect(guerrero.energia).to eq 100
  end
  it 'una propiedad inexistente da nil, y has_property? lo distingue' do
    guerrero = PrototypedObject.new
    expect(guerrero.get_property(:vida)).to be nil
    expect(guerrero.has_property?(:vida)).to be false
    expect { guerrero.vida }.to raise_error(NoMethodError)
  end
  it 'las propiedades son de cada objeto' do
    guerrero = PrototypedObject.new
    guerrero.set_property(:energia, 100)
    expect(PrototypedObject.new.has_property?(:energia)).to be false
    expect { PrototypedObject.new.energia }.to raise_error(NoMethodError)
  end
  it 'setear de nuevo pisa el valor' do
    guerrero = PrototypedObject.new
    guerrero.set_property(:energia, 100)
    guerrero.set_property(:energia, 50)
    expect(guerrero.energia).to eq 50
  end
end

describe 'métodos (M3)' do
  it 'un método definido con set_method lo entiende solo ese objeto' do
    guerrero = PrototypedObject.new
    guerrero.set_property(:energia, 100)
    guerrero.set_method(:descansar, proc { self.energia + 20 })
    expect(guerrero.descansar).to eq 120
    expect(guerrero.respond_to?(:descansar)).to be true
    expect { PrototypedObject.new.descansar }.to raise_error(NoMethodError)
  end
  it 'self dentro del proc es el receptor' do
    guerrero = PrototypedObject.new
    guerrero.set_method(:yo, proc { self })
    expect(guerrero.yo).to be guerrero
  end
  it 'un guerrero ataca a otro' do
    atila = armar_guerrero
    jack  = armar_guerrero
    atila.atacar_a(jack)
    expect(jack.energia).to eq 80
    expect(atila.energia).to eq 100
  end
end

describe 'clone (M4)' do
  it 'el primer bloque del enunciado, verbatim' do
    guerrero = armar_guerrero
    otro_guerrero = guerrero.clone
    guerrero.atacar_a otro_guerrero
    expect(otro_guerrero.energia).to eq 80
  end
  it 'el clon tiene su propio estado' do
    atila = armar_guerrero
    jack  = atila.clone
    atila.atacar_a(jack)
    expect(jack.energia).to eq 80
    expect(atila.energia).to eq 100
  end
  it 'el clon no ve los métodos que el original aprende después' do
    atila = armar_guerrero
    jack  = atila.clone
    atila.set_method(:sanar, proc { self.energia = self.energia + 10 })
    expect { jack.sanar }.to raise_error(NoMethodError)
    expect(jack.respond_to?(:sanar)).to be false
  end
  it 'el original no ve los métodos del clon' do
    atila = armar_guerrero
    jack  = atila.clone
    jack.set_method(:cortar, proc { "madera" })
    expect { atila.cortar }.to raise_error(NoMethodError)
  end
  it 'un objeto sin propiedades también se clona' do
    expect(PrototypedObject.new.clone.has_property?(:energia)).to be false
  end
end

describe 'set_prototype (M5)' do
  it 'el derivado usa los métodos del prototipo con self = derivado' do
    guerrero = armar_guerrero
    otro_guerrero = guerrero.clone
    guerrero.atacar_a otro_guerrero
    espadachin = armar_espadachin(guerrero)
    expect(espadachin.potencial_ofensivo).to eq 45
    espadachin.atacar_a(otro_guerrero)
    expect(otro_guerrero.energia).to eq 45          # el enunciado dice 75: errata
  end
  it 'un cambio en el prototipo impacta en el derivado' do
    guerrero = armar_guerrero
    espadachin = armar_espadachin(guerrero)
    guerrero.set_method(:sanar, proc { self.energia = self.energia + 10 })
    espadachin.sanar
    expect(espadachin.energia).to eq 110
    expect(guerrero.energia).to eq 100
  end
  it 'el clon sigue sin ver los cambios' do
    guerrero = armar_guerrero
    otro_guerrero = guerrero.clone
    guerrero.set_method(:sanar, proc { self.energia = self.energia + 10 })
    expect { otro_guerrero.sanar }.to raise_error(NoMethodError)
  end
  it 'lo redefinido en el derivado no se pisa' do
    guerrero = armar_guerrero
    espadachin = armar_espadachin(guerrero)
    guerrero.set_method(:potencial_ofensivo, proc { 1000 })
    expect(guerrero.potencial_ofensivo).to eq 1000
    expect(espadachin.potencial_ofensivo).to eq 45
  end
  it 'el prototipo provee métodos y no estado' do
    guerrero = armar_guerrero
    espadachin = PrototypedObject.new
    espadachin.set_prototype(guerrero)
    expect(espadachin.has_property?(:energia)).to be false
    expect(espadachin.respond_to?(:energia)).to be false
    expect { espadachin.energia }.to raise_error(NoMethodError)
  end
  it 'la cadena puede tener más de un salto' do
    guerrero = armar_guerrero
    espadachin = armar_espadachin(guerrero)
    nieto = PrototypedObject.new
    nieto.set_prototype(espadachin)
    expect(nieto.respond_to?(:atacar_a)).to be true
  end
  it 'un mensaje que nadie tiene falla como siempre' do
    espadachin = armar_espadachin(armar_guerrero)
    expect { espadachin.volar }.to raise_error(NoMethodError)
    expect(espadachin.respond_to?(:volar)).to be false
  end
end

describe 'azúcar de 4.1: el setter (M6)' do
  it 'asigna una propiedad sin set_property' do
    espadachin = PrototypedObject.new
    espadachin.energia = 100
    expect(espadachin.energia).to eq 100
    expect(espadachin.has_property?(:energia)).to be true
  end
  it 'el setter escribe en el derivado, no en el prototipo' do
    guerrero = armar_guerrero
    derivado = PrototypedObject.new
    derivado.set_prototype(guerrero)
    derivado.energia = 5
    expect(derivado.energia).to eq 5
    expect(guerrero.energia).to eq 100
  end
  it 'un método llamado algo= tiene prioridad sobre el setter' do
    objeto = PrototypedObject.new
    objeto.set_method(:energia=, proc { |valor| set_property(:energia, valor * 2) })
    objeto.energia = 10
    expect(objeto.energia).to eq 20
  end
  it 'respond_to? acepta cualquier asignación' do
    expect(PrototypedObject.new.respond_to?(:cualquiera=)).to be true
    expect(PrototypedObject.new.respond_to?(:cualquiera)).to be false
  end
end

describe 'Prototyped como mixin (M6)' do
  it 'cualquier clase puede incluirlo' do
    clase = Class.new { include Prototyped }
    perro = clase.new
    perro.set_method(:ladrar, proc { "guau" })
    expect(perro.ladrar).to eq "guau"
  end
  it 'incluido en Object, cualquier objeto es prototipable' do
    class Object; include Prototyped; end
    objeto = Object.new
    objeto.energia = 1
    expect(objeto.energia).to eq 1
  end
  it 'y lo demás sigue funcionando como siempre' do
    expect { 5.nada }.to raise_error(NoMethodError)
    expect { nil.nada }.to raise_error(NoMethodError)
    expect(5.respond_to?(:nada)).to be false
    expect(5.respond_to?(:to_s)).to be true
    expect { 5.energia = 1 }.to raise_error(FrozenError)
  end
end

describe 'constructores (M7)' do
  let(:guerrero) { armar_guerrero }
  let(:constructor_guerrero) {
    PrototypedConstructor.new(guerrero, proc { |nuevo, una_energia, un_potencial_ofensivo, un_potencial_defensivo|
      nuevo.energia = una_energia
      nuevo.potencial_ofensivo = un_potencial_ofensivo
      nuevo.potencial_defensivo = un_potencial_defensivo
    })
  }
  it 'con un proc inicializa el estado y linkea al prototipo' do
    un_guerrero = constructor_guerrero.new(100, 30, 10)
    expect(un_guerrero.energia).to eq 100
    expect(un_guerrero.prototype).to be guerrero
    expect(un_guerrero.respond_to?(:atacar_a)).to be true
  end
  it 'cuenta los argumentos' do
    expect { constructor_guerrero.new(1, 2) }.to raise_error(ArgumentError)
    expect { constructor_guerrero.new(1, 2, 3, 4) }.to raise_error(ArgumentError)
  end
  it 'por defecto recibe un mapa y rechaza propiedades que el prototipo no tiene' do
    constructor = PrototypedConstructor.new(guerrero)
    un_guerrero = constructor.new({energia: 100, potencial_ofensivo: 30, potencial_defensivo: 10})
    expect(un_guerrero.potencial_ofensivo).to eq 30
    expect { constructor.new({sarasa: 1}) }.to raise_error(ArgumentError)
  end
  it 'copy copia el estado actual y mantiene el link' do
    constructor = PrototypedConstructor.copy(guerrero)
    copia = constructor.new
    expect(copia.potencial_defensivo).to eq 10
    copia.potencial_defensivo = 99
    expect(guerrero.potencial_defensivo).to eq 10
    guerrero.set_method(:sanar, proc { self.energia = self.energia + 10 })
    expect(copia.sanar).to eq 110
  end
  it 'extended consume los argumentos en orden, primero el padre' do
    constructor_espadachin = constructor_guerrero.extended(proc { |espadachin, habilidad, potencial_espada|
      espadachin.set_property(:habilidad, habilidad)
      espadachin.set_property(:potencial_espada, potencial_espada)
      espadachin.set_method(:potencial_ofensivo, proc { call_next + self.potencial_espada * self.habilidad })
    })
    espadachin = constructor_espadachin.new(100, 30, 10, 0.5, 30)
    expect(espadachin.potencial_ofensivo).to eq 45
    expect(espadachin.prototype).to be guerrero
    expect { constructor_espadachin.new(100, 30, 10, 0.5) }.to raise_error(ArgumentError)
  end
  it 'extended sobre el constructor por defecto: el mapa va primero' do
    constructor = PrototypedConstructor.new(guerrero).extended(proc { |e, habilidad, potencial_espada|
      e.habilidad = habilidad
      e.potencial_espada = potencial_espada
    })
    espadachin = constructor.new({energia: 100, potencial_ofensivo: 30, potencial_defensivo: 10}, 0.5, 30)
    expect(espadachin.habilidad).to eq 0.5
    expect(espadachin.potencial_ofensivo).to eq 30
  end
end

describe 'azúcar sintáctico (M8)' do
  it 'asignar un proc define un método; el primer bloque de 4.3, verbatim' do
    guerrero_proto = PrototypedObject.new
    guerrero_proto.energia = 100
    guerrero_proto.potencial_defensivo = 10
    guerrero_proto.potencial_ofensivo = 30
    guerrero_proto.atacar_a = proc { |otro_guerrero|
      if otro_guerrero.potencial_defensivo < self.potencial_ofensivo
        otro_guerrero.recibe_danio(self.potencial_ofensivo - otro_guerrero.potencial_defensivo)
      end
    }
    guerrero_proto.recibe_danio = proc { |danio| self.energia = self.energia - danio }
    expect(guerrero_proto.has_property?(:atacar_a)).to be false
    constructor = PrototypedConstructor.copy(guerrero_proto)
    un_guerrero = constructor.new
    constructor.new.atacar_a(un_guerrero)
    expect(un_guerrero.energia).to eq 80
  end
  it 'new con bloque configura el objeto con self' do
    objeto = PrototypedObject.new { self.energia = 100; self.saludar = proc { "hola" } }
    expect(objeto.energia).to eq 100
    expect(objeto.saludar).to eq "hola"
  end
  it 'constructor con bloque' do
    constructor = PrototypedConstructor.new(PrototypedObject.new) do |una_energia, un_potencial_ofensivo, un_potencial_defensivo|
      self.energia = una_energia
      self.potencial_ofensivo = un_potencial_ofensivo
      self.potencial_defensivo = un_potencial_defensivo
    end
    expect(constructor.new(1, 2, 3).potencial_ofensivo).to eq 2
  end
  it 'create … with y create … with_properties' do
    con_with = PrototypedConstructor.create {
      self.recibe_danio = proc { |danio| self.energia = self.energia - danio }
    }.with { |una_energia, un_potencial_ofensivo, un_potencial_defensivo|
      self.energia = una_energia
      self.potencial_ofensivo = un_potencial_ofensivo
      self.potencial_defensivo = un_potencial_defensivo
    }
    con_lista = PrototypedConstructor.create {
      self.recibe_danio = proc { |danio| self.energia = self.energia - danio }
    }.with_properties([:energia, :potencial_ofensivo, :potencial_defensivo])
    [con_with, con_lista].each do |constructor|
      atila = constructor.new(100, 50, 30)
      expect(atila.potencial_ofensivo).to eq 50
      atila.recibe_danio(10)
      expect(atila.energia).to eq 90
    end
    expect { con_lista.new(100) }.to raise_error(ArgumentError)
  end
  it 'un método agregado al prototipo del constructor le gana a la propiedad del derivado' do
    constructor = PrototypedConstructor.create {}.with_properties([:energia, :potencial_ofensivo, :potencial_defensivo])
    atila = constructor.new(100, 50, 30)
    expect(atila.potencial_ofensivo).to eq 50
    constructor.prototype.potencial_ofensivo = proc { 1000 }
    expect(atila.potencial_ofensivo).to eq 1000
  end
  it 'extended con bloque' do
    guerrero = PrototypedConstructor.create {}.with { |e, o, d| self.energia = e; self.potencial_ofensivo = o; self.potencial_defensivo = d }
    espadachin = guerrero.extended { |una_habilidad, un_potencial_espada|
      self.habilidad = una_habilidad
      self.potencial_espada = un_potencial_espada
      self.potencial_ofensivo = proc { call_next + self.potencial_espada * self.habilidad }
    }
    expect(espadachin.new(100, 30, 10, 0.5, 30).potencial_ofensivo).to eq 45
  end
end

describe 'call_next (M9)' do
  it 'llega a la propiedad que el método tapa' do
    guerrero = armar_guerrero
    espadachin = armar_espadachin(guerrero)
    espadachin.set_method(:potencial_ofensivo, proc { call_next + self.potencial_espada * self.habilidad })
    expect(espadachin.potencial_ofensivo).to eq 45
  end
  it 'a diferencia de get_property, sigue la cadena en el momento de la llamada' do
    guerrero = armar_guerrero
    espadachin = armar_espadachin(guerrero)
    espadachin.set_method(:potencial_ofensivo, proc { call_next + self.potencial_espada * self.habilidad })
    guerrero.set_method(:potencial_ofensivo, proc { 1000 })
    expect(espadachin.potencial_ofensivo).to eq 1015      # con get_property seguiría en 45
  end
  it 'llega al método del prototipo, con los mismos argumentos o con otros' do
    base = PrototypedObject.new { self.saludar = proc { |nombre| "hola #{nombre}" } }
    hijo = PrototypedObject.new
    hijo.set_prototype(base)
    hijo.saludar = proc { |nombre| call_next + "!" }
    expect(hijo.saludar("ever")).to eq "hola ever!"
    hijo.saludar = proc { |nombre| call_next("otro") }
    expect(hijo.saludar("ever")).to eq "hola otro"
  end
  it 'recorre varios niveles' do
    a = PrototypedObject.new { self.f = proc { "a" } }
    b = PrototypedObject.new { self.f = proc { call_next + "b" } }
    b.set_prototype(a)
    c = PrototypedObject.new { self.f = proc { call_next + "c" } }
    c.set_prototype(b)
    expect(c.f).to eq "abc"
  end
  it 'falla si no hay implementación siguiente, y fuera de un método' do
    solo = PrototypedObject.new { self.x = proc { call_next } }
    expect { solo.x }.to raise_error(NoMethodError)
    expect { PrototypedObject.new.call_next }.to raise_error(NoMethodError)
  end
  it 'la pila queda limpia aunque el método explote' do
    objeto = PrototypedObject.new { self.x = proc { raise "boom" } }
    expect { objeto.x }.to raise_error(RuntimeError)
    objeto.y = proc { call_next }
    expect { objeto.y }.to raise_error(NoMethodError)
  end
end

describe 'múltiples prototipos (M9)' do
  let(:atacante) { PrototypedObject.new { self.atacar_a = proc { |otro| otro.recibe_danio(potencial_ofensivo) }; self.grito = proc { "ataco" } } }
  let(:defensor) { PrototypedObject.new { self.recibe_danio = proc { |danio| self.energia = energia - danio }; self.grito = proc { "defiendo" } } }
  let(:guerrero_constructor) {
    constructor = PrototypedConstructor.create {}.with_properties([:energia, :potencial_ofensivo])
    constructor.prototype.set_prototypes([atacante, defensor])
    constructor
  }
  it 'el objeto usa los métodos de todos sus prototipos' do
    a = guerrero_constructor.new(100, 30)
    b = guerrero_constructor.new(100, 30)
    a.atacar_a(b)
    expect(b.energia).to eq 70
  end
  it 'los prototipos no se afectan entre sí' do
    guerrero_constructor
    expect(atacante.prototypes).to eq []
    expect(defensor.prototypes).to eq []
    expect(atacante.respond_to?(:recibe_danio)).to be false
  end
  it 'en conflicto gana el primero de la lista, y call_next sigue por el orden' do
    a = guerrero_constructor.new(100, 30)
    expect(a.grito).to eq "ataco"
    guerrero_constructor.prototype.grito = proc { call_next + " y " + call_next }
    expect(a.grito).to eq "ataco y ataco"
    atacante.grito = proc { call_next.upcase }
    expect(a.grito).to eq "DEFIENDO y DEFIENDO"
  end
  it 'set_prototype es set_prototypes con uno solo' do
    objeto = PrototypedObject.new
    objeto.set_prototype(atacante)
    expect(objeto.prototypes).to eq [atacante]
    expect(objeto.prototype).to be atacante
  end
  it 'un ciclo no cuelga' do
    x = PrototypedObject.new
    y = PrototypedObject.new
    x.set_prototype(y)
    y.set_prototype(x)
    expect { x.nada }.to raise_error(NoMethodError)
    expect(x.respond_to?(:nada)).to be false
  end
  it 'un prototipo compartido aparece una sola vez en la cadena' do
    raiz = PrototypedObject.new { self.f = proc { "raíz" } }
    p1 = PrototypedObject.new; p1.set_prototype(raiz)
    p2 = PrototypedObject.new; p2.set_prototype(raiz)
    hijo = PrototypedObject.new; hijo.set_prototypes([p1, p2])
    expect(hijo.prototype_chain.size).to eq 4
    expect(hijo.f).to eq "raíz"
  end
end
