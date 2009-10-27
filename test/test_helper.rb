$:.unshift File.dirname(__FILE__) + '/../lib'
require 'test/unit'
require 'ape'
require 'mocha'

def load_test_dir(dir)
  Dir[File.join(File.dirname(__FILE__), dir, "*.rb")].each do |file|
    require file
  end
end

module Writer
  def response=(response)
    @response = response
  end
end
Ape::Invoker.send(:include, Writer)
  
module ApeAccessors
  def service=(service)
    @service = service
  end
  
  def entry_collections=(colls)
    @entry_collections = colls
  end
  
  def media_collections=(colls)
    @media_collections = colls
  end
  
  def service
    @service
  end
  
  def entry_collections
    @entry_collections
  end
  
  def media_collections
    @media_collections
  end
end
Ape::Ape.send(:include, ApeAccessors)

class ValidatorMock < Ape::Validator
  deterministic
  requires_presence_of :entry_collection
end

def collection(title, accept = ['application/atom+xml;type=entry'])
  collection = "<collection href=\"http://localhost\">" +
    "<atom:title>#{title}</atom:title>"
  accept.each do |a|
    collection += "<accept>#{a}</accept>"
  end
  collection += "</collection>"
end

def service(&block)
  service = "<service xmlns=\"http://www.w3.org/2007/app\"" +
    " xmlns:atom=\"http://www.w3.org/2005/Atom\"><workspace>"
  service += yield
  service += "</workspace></service>"
  REXML::Document.new(service)
end

def collections(&block)
  s = service(&block)
  nodes = REXML::XPath.match(s, '//app:collection', Ape::Names::XmlNamespaces)
  nodes.collect { |n| Ape::CollElement.new(n) }
end
