# run the ape from terminal
#  === available options
#        -o => output format (html/text)
#        -v => verbose mode (false/true)

$:.unshift File.dirname(__FILE__) + '/../lib'
require 'cgi'
require 'ape'
require 'optparse'

OPTIONS = {
  :output => 'html',
  :verbose => false,
  :home => nil
}

OptionParser.new do |opts|
  opts.banner = 'The ape console options:'
  opts.separator ''
  opts.on('-o', '--output OUTPUT', 'Output format (html/text)', "default: html") { |v| OPTIONS[:output] = v }
  opts.on('-v', '--verbose VERBOSE', 'Verbose mode (true/false)', "default: false") { |v| OPTIONS[:verbose] = v }
  opts.on('-d', '--directory DIRECTORY', 'ape home directory', "default: #{::Ape.home}") { |v| OPTIONS[:home] = v }
  opts.on('-h', '--help', 'Displays this help') { puts opts; exit }
  opts.parse!(ARGV)
end

debug = ENV['APE_DEBUG'] || OPTIONS[:verbose]

cgi = debug ? CGI.new('html4') : CGI.new 

if !cgi['uri'] || (cgi['uri'] == '')
  if (OPTIONS[:output] == 'html')
    Ape::HTML.error "URI argument is required"
  else
    puts "URI argument is required"
  end
end

uri = cgi['uri']
user = cgi['username']
pass = cgi['password']

ape = Ape::Ape.new({:crumbs => true, :output => OPTIONS[:output], :debug => OPTIONS[:verbose]})

if user == ''
  ape.check(uri)
else
  ape.check(uri, user, pass)
end
ape.report




