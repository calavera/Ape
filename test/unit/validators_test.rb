require File.dirname(__FILE__) + '/../test_helper.rb'

class ValidatorsTest < Test::Unit::TestCase
  def setup
    @reporter = Ape::Reporter.instance('text')
  end
  def test_schema_validate    
    assert_equal(true, validate_schema)    
  end
  
  def test_chema_validate_with_ruby_shows_an_info
    if RUBY_PLATFORM !=~ /java/
      validate_schema
      assert_equal(1, @reporter.infos.size)
    end
  end
  
  def validate_schema
    schema = Ape::Validator.instance(:schema, @reporter)    
    schema.validate(:schema => Ape::Samples.service_RNC, :title => 'Service doc', :doc => service)
  end
  
  def test_validator_is_deterministic
    assert(ValidatorMock.new.deterministic? == true, "Validator mock is nondeterministic")
  end
  
  def test_validator_is_enabled
    assert(ValidatorMock.new.enabled? == true, "Validator mock is disabled")
  end
  
  def service
    <<END_SERVICE
    <?xml version="1.0" encoding="utf-8"?>
    <service xmlns="http://www.w3.org/2007/app" xmlns:atom="http://www.w3.org/2005/Atom">
      <workspace>
        <atom:title>Verbosemode in wordpress Workspace</atom:title>
        <collection href="http://verbosemode.wordpress.com/wp-app.php/posts">
          <atom:title>Verbosemode in wordpress Posts</atom:title>
          <accept>application/atom+xml;type=entry</accept>
          <categories href="http://verbosemode.wordpress.com/wp-app.php/categories" />
        </collection>
        <collection href="http://verbosemode.wordpress.com/wp-app.php/attachments">
          <atom:title>Verbosemode in wordpress Media</atom:title>
          <accept>image/*</accept><accept>audio/*</accept><accept>video/*</accept>
        </collection>
      </workspace>
    </service>
END_SERVICE
  end
end
