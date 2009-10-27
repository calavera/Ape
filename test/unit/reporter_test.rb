require File.dirname(__FILE__) + '/../test_helper.rb'

class OutputMock < String
  def puts(str)
    self << str
  end
end

class ReporterTest < Test::Unit::TestCase  
  def test_instance_text_reporter_nothing_raised
    assert_nothing_raised(Exception) { Ape::Reporter.instance('text') }
  end
  
  def test_instance_html_reporter_nothing_raised
    assert_nothing_raised(Exception) { Ape::Reporter.instance('html') }
  end

  def test_instance_html_reporter_nothing_raised
    assert_nothing_raised(Exception) { Ape::Reporter.instance('atom') }
  end
  
  def test_instance_unknown_reporter_raises_standard_error
    assert_raise(StandardError) { Ape::Reporter.instance('rss') }
  end
  
  def test_supported_outputs
    assert_equal("atom, html, text", Ape::Reporter.supported_outputs)
  end
  
  def test_errors_nothing_raised
    assert_nothing_raised(Exception) { Ape::Reporter.new.errors }
  end
  
  def test_contains_an_error
    reporter = Ape::Reporter.new
    reporter.add(self, :error, 'ape error 1')    
    assert_equal(1, reporter.errors.length)
  end
  
  def test_contains_two_errors
    reporter = Ape::Reporter.new
    reporter.add(self, :error, 'ape error 2')
    reporter.add(self, :error, 'ape error 3')
    reporter.add(self, :info, 'ape info')    
    assert_equal(2, reporter.errors.length)
  end
  
  def test_warnings_nothing_raised
    reporter = Ape::Reporter.new
    assert_nothing_raised(Exception) { reporter.warnings }
  end
  
  def test_contains_warnings
    reporter = Ape::Reporter.new
    reporter.add(self, :warning, 'ape warning')    
    assert_equal(1, reporter.warnings.length)
  end
  
  def test_html_stylesheet_exists
    reporter = Ape::Reporter.instance('html')
    assert_equal(true, File.exists?(reporter.stylesheet))
  end
  
  def test_mark_error
    reporter = Ape::Reporter.instance('html')
    assert_equal('<span class="error">!</span>', reporter.mark(:error))
  end
  
  def test_mark_info
    assert_match(/<img class="info" src="(.+)"\/>/, info)
  end
  
  def test_info_image_exists
    assert_equal(true, File.exists?(
      /<img class="info" src="(.+)"\/>/.match(info)[1]))
  end
  
  def info
    Ape::Reporter.instance('html').mark(:info)
  end
  
  def test_html_report_not_nil
    assert_not_nil(Ape::Reporter.instance('html').report(OutputMock.new("")))
  end
  
  def test_hmtl_report_contains_steps
    reporter = Ape::Reporter.instance(:html)
    reporter.add(self, :warning, 'Ape warning')    
    assert_nothing_raised(Exception) { reporter.report(OutputMock.new(""))  }
  end
  
  def test_static_dir_server
    reporter = Ape::Reporter.instance(:html, {:server => true})
    assert_equal("/web", reporter.static_dir)    
  end
  
  def test_static_dir_script
    reporter = Ape::Reporter.instance(:html)
    assert_match(/.+\/web$/, reporter.static_dir)
  end
  
end
