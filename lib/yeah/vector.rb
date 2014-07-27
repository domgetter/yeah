require 'forwardable'

module Yeah
class Vector
  extend Forwardable

  class << self
    def [](*args)
      new(*args)
    end
  end

  attr_reader :components
  alias_method :to_a, :components
  def_delegators :@components, :[]

  def initialize(*components)
    @components = components
  end

  %i[x y z].each_with_index do |component, i|
    define_method(component) { @components[i] }
    define_method("#{component}=") { |v| @components[i] = v }
  end

  def +(vector)
    self.class.new(*(0...@components.count).map { |i|
      @components[i] + vector.components[i]
    })
  end

  def -(vector)
    self.class.new(*(0...@components.count).map { |i|
      @components[i] - vector.components[i]
    })
  end

  def *(number)
    self.class.new(*(0...@components.count).map { |i|
      @components[i] * number
    })
  end

  def /(number)
    self.class.new(*(0...@components.count).map { |i|
      @components[i] / number
    })
  end

  def +@
    self.class.new(@components)
  end

  def -@
    self.class.new(*(0...@components.count).map { |i| -@components[i] })
  end
end
end

Yeah::V = Yeah::Vector
