require 'yaml'
require 'sinatra/base'
require 'sinatra/reloader'
require 'slim'
require 'sass'

class MyApp < Sinatra::Base
  configure(:development){ 
    register Sinatra::Reloader
    also_reload "#{__dir__}/**/*.rb"
  }

  class Settings
    CONF_PATH = "#{__dir__}/settings.yml"

    def self.load
      @conf = YAML.load_file(CONF_PATH)
    end

    def self.[](keys)
      @conf.dig(*keys)
    end
  end

  class Project
    def self.collect
      @projects = Settings[:projects].map{|item|
        Project.new(**item)
      }

    end

    def initialize(name:, path:)
      @name, @path = name, File.expand_path(path)
    end
    attr_reader :name, :path

    def update
      Dir.chdir(@path) do
        @audit = `bundle audit check`
        @local_head = `git log --oneline -n 1`
        @remote_head = `git log --oneline -n 1 origin/master`
      end
    end
    attr_reader :audit, :local_head, :remote_head
  end

  get '/' do
    MyApp::Settings.load
    system "bundle audit update"
    @projects = Project.collect
    @projects.each(&:update)
    slim :index
  end

  get '/screen.css' do
    sass :screen
  end
end
