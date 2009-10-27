require File.dirname(__FILE__) + '/../test_helper.rb'

require 'rexml/document'

class CollectionTest < Test::Unit::TestCase
  
  def test_make_rake_shut_up
    assert(true, "WIll fill some tests in when I look at Collection")
  end
  
#  def test_post_require_data
#    assert_raise(StandardError) { stub_coll.post() }
#  end
  
#  def test_post_should_matches_content_type
#    assert_raise(StandardError) { stub_coll.post(:data => 'asdfsadf', :type => 'image/png') }
#  end
  
#  def test_post_method_returns_poster
#    assert_not_nil(stub_coll.post(:data => 'asdf'))
#  end
  
#  private
#  def stub_coll
#    post = Ape::Poster.new('http://localhost', nil)
#    post.stubs(:post).returns(true)
#    
#    coll = make_coll(Ape::Names::AtomEntryMediaType)
#    coll.stubs(:poster).returns(post)
#    coll
#  end
  
#  def make_coll(*accepts)
#    front = '<collection xmlns="http://www.w3.org/2007/app" xmlns:atom="http://www.w3.org/2005/Atom">
#             <atom:title>X</atom:title>'
#    back = "</collection>"
#    r = front
#    accepts.each { |a| r += "<accept>#{a}</accept>" }
#    r += back
#    r = REXML::Document.new(r).root
#    Ape::CollElement.new(r)
#  end
end
