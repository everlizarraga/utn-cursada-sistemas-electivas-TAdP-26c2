require_relative 'multimethods'

describe PartialBlock do
  let(:hello_block) { PartialBlock.new([String]) { |who| "Hello #{who}" } }
  it('matchea con un String') { expect(hello_block.matches?("a")).to be true }
  it('no matchea con un Integer') { expect(hello_block.matches?(1)).to be false }
  it('no matchea con más argumentos que tipos') { expect(hello_block.matches?("a", "b")).to be false }
  it('se ejecuta con argumentos válidos') { expect(hello_block.call("world!")).to eq "Hello world!" }
  it('falla con argumentos inválidos') { expect { hello_block.call(1) }.to raise_error(ArgumentError) }
  it 'acepta subtipos' do
    pair_block = PartialBlock.new([Object, Object]) { |l, r| [l, r] }
    expect(pair_block.call("hello", 1)).to eq ["hello", 1]
  end
  it('falla al construirse si firma y bloque no coinciden') { expect { PartialBlock.new([String, String]) { |a| a } }.to raise_error(ArgumentError) }
end

describe 'partial_def' do
  class A
    partial_def :concat, [String, String] do |s1, s2| s1 + s2 end
    partial_def :concat, [String, Integer] do |s1, n| s1 * n end
    partial_def :concat, [Array] do |a| a.join end
  end
  it 'elige por los tipos' do
    expect(A.new.concat('hello', ' world')).to eq 'hello world'
    expect(A.new.concat('hello', 3)).to eq 'hellohellohello'
    expect(A.new.concat(['hello', ' world', '!'])).to eq 'hello world!'
  end
  it('falla si nada matchea') { expect { A.new.concat('hello', 'world', '!') }.to raise_error(NoMethodError) }
  it('una subclase hereda') { class B < A; end; expect(B.new.concat('a', 'b')).to eq 'ab' }
  it 'expone los multimétodos' do
    expect(A.multimethods).to eq [:concat]
    expect(A.multimethod(:concat).size).to eq 3
  end
end

describe 'contexto' do
  class Soldado; end
  class Tanque
    def ataca_con_canion(o); "cañonazo"; end
    def ataca_con_ametralladora(o); "ráfaga"; end
    partial_def :ataca_a, [Tanque] do |objetivo| self.ataca_con_canion(objetivo) end
    partial_def :ataca_a, [Soldado] do |objetivo| self.ataca_con_ametralladora(objetivo) end
  end
  it('self es el receptor') { expect(Tanque.new.ataca_a(Soldado.new)).to eq "ráfaga" }
end

describe 'duck typing' do
  class Formateador
    partial_def :formatear, [String, [:nombre, :direccion]] do |titulo, coso|
      titulo + " | " + coso.nombre + ": " + coso.direccion
    end
    partial_def :formatear, [String, [:peso]] do |titulo, pesable|
      titulo + " " + pesable.peso.to_s
    end
  end
  class Lugar
    attr_accessor :nombre, :direccion
    def initialize(n, d); @nombre = n; @direccion = d; end
  end
  class Perro
    attr_accessor :peso
    def initialize(p); @peso = p; end
  end
  it('acepta por mensajes') { expect(Formateador.new.formatear("VISITE", Lugar.new("Obelisco", "Corrientes y 9 de Julio"))).to eq "VISITE | Obelisco: Corrientes y 9 de Julio" }
  it('elige la otra definición') { expect(Formateador.new.formatear("Pesado", Perro.new(32))).to eq "Pesado 32" }
  it('falla si no entiende los mensajes') { expect { Formateador.new.formatear("Pesado", 5) }.to raise_error(NoMethodError) }
end

describe 'distancia' do
  class Distancia
    partial_def :concat, [Object, Object] do |o1, o2| "Objetos concatenados" end
    partial_def :concat, [String, Integer] do |s1, n| s1 * n end
  end
  it('elige la más específica aunque esté después') { expect(Distancia.new.concat("Hello", 2)).to eq "HelloHello" }
  it('cae a la genérica') { expect(Distancia.new.concat(Object.new, 3)).to eq "Objetos concatenados" }
  it 'la misma firma pisa a la anterior' do
    class Pisa
      partial_def :saludar, [String] do |n| "hola #{n}" end
      partial_def :saludar, [String] do |n| "chau #{n}" end
    end
    expect(Pisa.new.saludar("x")).to eq "chau x"
    expect(Pisa.multimethod(:saludar).size).to eq 1
  end
end

describe 'respond_to?' do
  it('sigue funcionando como siempre') { expect(A.new.respond_to?(:concat)).to be true; expect(A.new.respond_to?(:to_s)).to be true; expect(A.new.respond_to?(:nada)).to be false }
  it('con firma que coincide') { expect(A.new.respond_to?(:concat, false, [String, String])).to be true }
  it('con firma que matchea por subtipo') { expect(Distancia.new.respond_to?(:concat, false, [Integer, A])).to be true }
  it('no es multimétodo') { expect(A.new.respond_to?(:to_s, false, [String])).to be false }
  it('firma que no coincide') { expect(A.new.respond_to?(:concat, false, [String, String, String])).to be false }
  it('con duck typing') { expect(Formateador.new.respond_to?(:formatear, false, [String, Lugar])).to be true; expect(Formateador.new.respond_to?(:formatear, false, [String, Integer])).to be false }
  it('en una subclase') { expect(B.new.respond_to?(:concat, false, [String, String])).to be true }
end
