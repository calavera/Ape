require 'rubygems'
require 'sinatra/base'

$:.unshift File.dirname(__FILE__) + '/../lib' unless $:.include?(File.dirname(__FILE__) + '/../lib')
require 'ape'

class AtomExerciser < Sinatra::Base
  set :static, true
  set :public, File.dirname(__FILE__) + '/../web'

  get '/' do
    redirect '/index.html' 
  end

  post '/atompub/go' do
    ape = Ape::Ape.new({:output => 'html', :debug => false, :server => true, :static_path => ''})
    ape.check(params[:uri], params[:username], params[:password])
    output = StringIO.new
    ape.report(output)
    output.rewind
    output.read
  end
end
