require 'rubygems'
require 'pp'
require 'restfully'

@options = {
  :restfully_config => File.expand_path(
    ENV['RESTFULLY_CONFIG'] || "~/.restfully/api.grid5000.fr.yml"
  )
}

if File.exist?(@options[:restfully_config]) && 
    File.readable?(@options[:restfully_config]) &&
    File.file?(@options[:restfully_config])

  connection = Restfully::Session.new( 
    :configuration_file => @options.delete(:restfully_config)
  )   

  pp connection.root

else
  STDERR.puts "Restfully configuration file cannot be loaded:
  #{@options[:restfully_config].inspect} does not exist or cannot be
  read or is not a file" 
  exit(1)
end
