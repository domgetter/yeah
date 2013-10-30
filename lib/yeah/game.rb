# Manages entities.
class Yeah::Game
  # @!attribute resolution
  #   @return [Vector] size of screen
  # @!attribute screen
  #   @return [Surface] visual render
  # @!attribute [r] platform
  #   @return [Platform] underlying platform bindings
  # @!attribute entities
  #   @return [Array] active entities
  attr_accessor :resolution, :screen, :entities
  attr_reader :platform

  def initialize
    @resolution = V[320, 180]
    @screen = Surface.new(@resolution)
    @platform = Desktop.new
    @entities = []
  end

  # Start the game loop.
  def start
    platform.each_tick do
      update
      draw
      break if @stopped
    end
  end

  # Stop the game loop.
  def stop
    @stopped = true
  end

  protected

  def update
    @entities.each { |e| e.update }
  end

  def draw
    screen.fill(Color[0, 0, 0, 0])
    @entities.each do |entity|
      surface = entity.draw
      screen.draw(surface, entity.position) unless surface.nil?
    end
    platform.render(screen)
  end
end
