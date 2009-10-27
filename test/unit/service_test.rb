require File.dirname(__FILE__) + '/../test_helper.rb'

class ServiceTest < Test::Unit::TestCase    
  def test_new_service_instance_raises_not_found_error
    assert_raise(StandardError) {
      Ape::Service.new(:uri => 'http://localhost/atomPub')
    }
  end
  
  def test_service_each_gets_entry_collection
    service_doc = load_service
    titles = []
    service_doc.collections.each do |collection|
      titles << collection.title if collection.accept?(Ape::Names::AtomEntryMediaType)
    end
    assert_equal(['Posts', 'Comments'], titles)
  end
  
  def test_service_each_gets_all_collections
    service_doc = load_service
    titles = []
    service_doc.collections.each do |collection|
      titles << collection.title
    end
    assert_equal(4, titles.size)
  end
  
  def test_service_each_gets_none_collections
    service_doc = load_service
    titles = []
    service_doc.collections.each do |collection|
      titles << collection.title if collection.accept?('video/*')
    end
    assert_equal(0, titles.size)
  end
  
  def load_service
    service_doc = Ape::Service.new
    service_doc.service = service {
      collection('Posts') +
      collection('Comments') +
      collection('Attachments', ['image/jpg']) +
      collection('Attachments2', ['image/png'])
    }
    service_doc
  end
end