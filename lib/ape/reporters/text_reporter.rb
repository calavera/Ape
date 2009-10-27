module Ape
  class TextReporter < Reporter
    def report(output = STDOUT)
      if @header
        output.puts @header 
        output.puts errors.length == 1?"1 error":"#{errors.length} errors"
        output.puts warnings.length == 1?"1 warning":"#{warnings.length} warnings"
      end
      steps.each do |step|
        if step.class == Crumbs
          output.puts "   Dialog:"
          step.each { |crumb| output.puts "     #{crumb}" }
        else
          line
          if (step.kind_of?Array)
            output.puts "INFO: #{step[0]}"
            step[1..-1].each do |li|
              lines = li[:message].split("\n")
              lines[0..-2].each do |line|
                output.puts("\t #{line} \n")
              end
              output.puts("\t #{lines[-1]}") if lines[-1]
            end
          else          
            case step[:severity]
            when :warning, :error            
              output.puts "#{step[:severity].to_s.upcase}: #{step[:message]}"
            else            
              output.puts step[:message]
            end
          end
        end
        output.puts @footer if @footer
      end
    end
  end
end
