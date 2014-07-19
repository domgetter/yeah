require 'pathname'
require 'rack'
require 'opal'

module Yeah
module Web
class Server
  def start(port = 1234)
    Rack::Server.start(app: Application.new, Port: port)
  end

  private

  class Application < Opal::Server
    def initialize
      @index_path = gem_path.join('lib', 'yeah', 'web', 'runner.html.erb').to_s

      super

      # Append stdlib paths
      $LOAD_PATH.each { |p| append_path(p) }

      # Append Yeah paths
      append_path gem_path.join('lib')
      append_path gem_path.join('opal')

      # Append game (working directory) paths
      append_path 'assets'
      append_path 'code'
    end

    private

    def gem_path
      @gem_path ||= Pathname.new(__FILE__).join('..', '..', '..', '..')
    end
  end
end
end
end