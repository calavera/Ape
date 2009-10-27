require File.dirname(__FILE__) + '/../test_helper.rb'

require 'rexml/document'

class CollElementTest < Test::Unit::TestCase
     
  def test_accept  
    # no <accept> should accept only application/atom+xml;type=entry
    c = make_coll('')
    assert(c.accept?(Ape::Names::AtomEntryMediaType))
    assert(!c.accept?(Ape::Names::AtomMediaType))
    assert(!c.accept?(Ape::Names::AtomFeedMediaType))
    assert(!c.accept?(Ape::Names::AppMediaType))
    assert(!c.accept?('image/jpeg'))
    assert(!c.accept?('text/plain'))
    
    # */* should accept anything
    types = [ Ape::Names::AtomEntryMediaType, Ape::Names::AtomMediaType,
      Ape::Names::AtomFeedMediaType, Ape::Names::AppMediaType,
      'image/jpeg', 'text/plain'
    ]
    c = make_coll('*/*')
    types.each { |t| assert(c.accept?(t))}
    
    # ... even if it's got something else in front of it
    c = make_coll('image/jpeg', '*/*')
    types.each { |t| assert(c.accept?(t))}
    assert(c.accept?('image/jpeg'))
    
    # .. shouldn't accept anything but one type
    c = make_coll('audio/mp3')
    types.each { |t| assert(!c.accept?(t))}
    assert(c.accept?('audio/mp3'))
    
    # image/*
    c = make_coll('image/*')
    ['jpeg', 'png', 'gif'].each {|sub| assert(c.accept?("image/#{sub}"))}
    [ Ape::Names::AtomEntryMediaType, Ape::Names::AtomMediaType,
      Ape::Names::AtomFeedMediaType, Ape::Names::AppMediaType,
      'text/plain' ].each {|t| assert(!c.accept?(t))}
    
  end
    
  private
  
  def make_coll(*accepts)
    front = '<collection xmlns="http://www.w3.org/2007/app" xmlns:atom="http://www.w3.org/2005/Atom">
             <atom:title>X</atom:title>'
    back = "</collection>"
    r = front
    accepts.each { |a| r += "<accept>#{a}</accept>" }
    r += back
    r = REXML::Document.new(r).root
    Ape::CollElement.new(r)
  end
end
