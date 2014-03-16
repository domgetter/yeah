# Acts and interacts with other Things within a Level.
module Yeah

class Thing
  def initialize(properties = V[])
    properties = { position: properties } unless properties.respond_to?(:to_h)
    properties = properties.to_h

    properties.each do |key, val|
      writer = "#{key}="
      send(writer, val)
    end
  end

  # The level this is in.
  #
  # @return [Level]
  def level
    @level ||= Level.new
  end
  def level=(value)
    @level = value
    @level.things << self unless @level.things.include? self
  end

  def game
    level.game
  end

  # Position within the level.
  #
  # @return [Vector]
  def position
    @position ||= V[]
  end
  def position=(value)
    @position = V[value]
  end

  def x; position[0]; end
  def x=(v); self.position[0] = v; end

  def y; position[1]; end
  def y=(v); self.position[1] = v; end

  def z; position[2]; end
  def z=(v); self.position[2] = v; end

  # Physical size.
  #
  # @return [NilClass|Vector]
  def size
    @size || visual.size || V[]
  end
  def size=(value)
    @size = V[value]
  end

  def width; size[0]; end
  def width=(v); self.size[0] = v; end

  def height; size[1]; end
  def height=(v); self.size[1] = v; end

  def depth; size[2]; end
  def depth=(v); self.size[2] = v; end

  # Graphical representation.
  #
  # @return [Visual]
  def visual
    @visual ||= NullVisual.new
  end
  attr_writer :visual

  # Origin point within bounds.
  #
  # @return [Vector]
  def anchor
    @anchor ||= V[]
  end
  def anchor=(value)
    @anchor = V[value]
  end

  # X position of right side.
  #
  # @return [Integer]
  def right
    x + width * (1 - anchor[0])
  end

  # X position of left side.
  #
  # @return [Integer]
  def left
    x + width * anchor[0]
  end

  # Y position of top side.
  #
  # @return [Integer]
  def top
    y + height * (1 - anchor[1])
  end

  # Y position of bottom side.
  #
  # @return [Integer]
  def bottom
    y + height * anchor[1]
  end

  # Z position of front side.
  #
  # @return [Integer]
  def front
    z + depth * (1 - anchor[2])
  end

  # Z position of back side.
  #
  # @return [Integer]
  def back
    z + depth * anchor[2]
  end

  # Position of center.
  #
  # @return [Vector]
  def center
    position + size * anchor
  end

  # Is intersected with instance or type of thing?
  #
  # @param [Thing|Thing class]
  # @return [Boolean]
  def colliding?(other)
    return false if other == self

    if other.is_a?(Class)
      return level.things
        .select { |e| e.is_a? other }
        .any? { |e| colliding? e }
    end

    return false if size == V[] || other.size == V[]

    not_colliding_x = left > other.right || right < other.left
    not_colliding_y = bottom > other.top || top < other.bottom
    not_colliding_z = back > other.front || front < other.back

    !(not_colliding_x && not_colliding_y && not_colliding_z)
  end

  # Update thing.
  def update; end

  protected

  # Is a key or button being pressed?
  #
  # @param [Pressable]
  # @return [Boolean]
  def pressing?(pressable)
    game.pressing? pressable
  end
end

end