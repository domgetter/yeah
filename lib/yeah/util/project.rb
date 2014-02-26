require 'fileutils'
require 'opal'
require 'rack'

class Yeah::Project
  class << self
    def generate(name, dir)
      project_dir = copy_template(dir, name)
      compile_template(project_dir, name)
      delete_keep_files(project_dir)
    end

    alias_method :load, :new

    private

    def copy_template(dir, name)
      yeah_dir = File.expand_path('../../../../', __FILE__)
      template_dir = "#{yeah_dir}/lib/yeah/util/template/"
      project_dir = "#{dir}/#{name}/"

      FileUtils.cp_r(template_dir, project_dir)

      project_dir
    end

    def compile_template(dir, game_name)
      files = deep_files(dir)

      files.each do |file|
        template = File.read(file)
        game_class = game_classify(game_name)
        properties = { game_class: game_class }
        compiled = template % properties

        IO.write(file, compiled)
      end
    end

    def delete_keep_files(dir)
      keep_files(dir).each { |f| File.delete f }
    end

    def keep_files(dir)
      deep_files(dir).select { |f| File.split(f).last == '.keep' }
    end

    def deep_files(dir)
      deep_paths(dir).select { |f| File.file? f }
    end

    def deep_directories(dir)
      deep_paths(dir).select { |f| File.directory? f }
    end

    def deep_paths(dir)
      Dir.glob("#{dir}**/*", File::FNM_DOTMATCH) - %w[. ..]
    end

    def game_classify(name)
      classify(name) + "Game"
    end

    def classify(string)
      string
        .split('_')
        .collect { |w| w
          .sub(/\A(.)/) { $1
            .upcase
          }
        }
        .join
    end
  end

  def initialize(dir)
    @dir = dir
  end

  def run
    Rack::Server.start(app: Yeah::WebRackApp, Port: 1234)
  end
end

Yeah::WebRackApp = Rack::Builder.new do
  yeah_dir = File.expand_path('../../../../', __FILE__)

  map '/' do
    player_path = "#{yeah_dir}/lib/yeah/util/player.html"
    run Rack::File.new(player_path)
  end

  map '/assets' do
    sprockets = Opal::Environment.new
    sprockets.use_gem 'yeah'
    sprockets.append_path '.'
    run sprockets
  end
end
