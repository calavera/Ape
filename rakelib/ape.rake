namespace :ape do
  namespace :go do    
    
    Ape::Reporter.supported_outputs.split(', ').each do |output|
      desc "Executes the ape script and returns the report as #{output}"
      task output, :uri, :username, :password do |task, args|        
        ape(args, output)
      end
    end
    
    def ape(args, output = 'html')
      unless args.uri
        puts "URI argument is required"
        exit
      end     

      ape = Ape::Ape.new({:output => output, :debug => false})
      unless args.username && args.password
        ape.check(args.uri)
      else      
        ape.check(args.uri, args.username, args.password)
      end
      ape.report
    end
  end
end
