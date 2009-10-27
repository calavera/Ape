require File.dirname(__FILE__) + '/../test_helper.rb'


class ApeTest < Test::Unit::TestCase
  require 'rexml/document'
  def setup
    @ape = Ape::Ape.new
    @ape.media_collections = []
    @ape.entry_collections = []
  end
  
  def test_check_manifest_raises_validation_error
    @ape.media_collections = collections { collection('Attachments', ['image/jpg']) }
    assert_raise(Ape::ValidationError) {
      @ape.check_manifest(ValidatorMock.new)
    }
  end
  
  def test_check_manifest_assert_first_entry_collection
    @ape.entry_collections = collections { collection('Posts') }
    variables = @ape.check_manifest(ValidatorMock.new)
    assert_equal('Posts', variables[:entry_collection].title)
  end
  
  def test_check_manifest_assert_first_media_collection
    @ape.media_collections = collections { collection('Attachments', ['image/jpg']) }
    variables = stub_manifest([:media_collection])
    assert_equal('Attachments', variables[:media_collection].title)
  end
  
  def test_check_manifest_assert_select_last_collection
   @ape.entry_collections = collections {
      collection('Posts') +
      collection('Comments')
    }
    
    variables = stub_manifest([:entry_collection => :last])
    assert_equal('Comments', variables[:entry_collection].title)
  end
  
  def test_select_first_collection_by_type
    @ape.entry_collections = collections {
      collection('Posts') +
      collection('Attachments', ['image/jpg']) +
      collection('Attachments2', ['image/png'])
    }
    variables = stub_manifest([:media_collection => {:accept => 'image/png'}])
    assert_equal('Attachments2', variables[:media_collection].title)
  end
  
  def test_select_first_collection_by_title
    @ape.entry_collections = collections {
      collection('Posts') +
      collection('Attachments', ['image/jpg'])
    }
    variables = stub_manifest([:media_collection => {:title => 'Attachments'}])
    assert_equal('Attachments', variables[:media_collection].title)
  end
  
  def test_select_by_name_raises_validation_error
    @ape.entry_collections = collections {
      collection('Posts') +
      collection('Attachments', ['image/jpg'])
    }
    assert_raise(Ape::ValidationError) {
      variables = stub_manifest([:media_collection => {:name => 'Attachments'}])
    }
  end
  
  def stub_manifest(return_value)
    validator = ValidatorMock.new
    validator.stubs(:manifest).returns(return_value)
    @ape.check_manifest(validator)
  end
  
end