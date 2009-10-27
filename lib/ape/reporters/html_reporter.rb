require 'erubis'
module Ape
  class HtmlReporter < Reporter    
    
    def static_dir      
      dir = (server != true)?File.expand_path(File.dirname(__FILE__) + '/../../..') : ''
      dir += options[:static_path] || "/web"
      dir
    end
    
    def stylesheet
      static_dir + '/ape.css'
    end
    
    def mark(mark)
      span = "<span class=\"#{mark.to_s}\">"
      case mark
      when :success        
        span << '&#x2713;' << '</span>'
      when :warning
        span << '?' << '</span>'
      when :error
        span << '!' << '</span>'
      when :info
        span = "<img class=\"info\" src=\"#{static_dir + '/info.png'}\"/>"
      end      
    end
    
    def report_li(step, dialog = nil, marker = nil)
      html = '<li>'
      if marker
        html += "#{mark(marker)} "
      end      
      # preserve line-breaks in output
      lines = step.split("\n")
      lines[0 .. -2].each do |line|
        html += "#{line} <br/>"
      end
      html += lines[-1] if lines[-1]
      if dialog
        html += "<a class=\"diaref\" href=\"#dia-#{@dianum}\">[Dialog]</a>"
        @diarefs[dialog] = @dianum
        @dianum += 1
      end
      html += '</li>'
      html
    end
    
    def report(output = STDOUT)      
      output.puts evaluate_template("reporters/html_template.eruby")
    end
  end
end
