require File.dirname(__FILE__) + '/sinatra/atom_exerciser'

class Sinatra::Reloader < ::Rack::Reloader
  def safe_load(file, mtime, stderr)
    Sinatra::Application.reset!
    super
  end
end
use Sinatra::Reloader

run AtomExerciser
