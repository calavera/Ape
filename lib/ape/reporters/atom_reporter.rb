# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 

module Ape
  class AtomReporter < Reporter
    def escape(text)
      Escaper.escape(text)
    end
    
    def now
      DateTime::now.strftime("%Y-%m-%dT%H:%M:%S%z").sub(/(..)$/, ':\1')
    end
    
    def id
      id = ''
      5.times { id += rand(1000000).to_s }
      "tag:tbray.org,2005:#{id}"
    end
    
    def content(step, dialog = nil)
      xml = "<div xmlns=\"http://www.w3.org/1999/xhtml\">"
      lines = step.split("\n")
      lines[0 .. -2].each do |line|
        xml += "#{line} <br/>"
      end
      xml += escape(lines[-1]) if lines[-1]
      if dialog && dialogs[dialog]        
        xml += '<div>'
            xml += 'To server:'
            dialogs[dialog].grep(/^>/).each do |crumb|
              xml += show_message(crumb, :to)
            end
        xml += '</div>'
        xml += '<div>'
            xml += 'From server:'
            dialogs[dialog].grep(/^</).each do |crumb|
              xml += show_message(crumb, :from)
            end
        xml += '</div>'
      end
      xml += '</div>'
      xml
    end
    
    def report(output = STDOUT)      
      output.puts evaluate_template("reporters/atom_template.eruby")
    end
  end
end
