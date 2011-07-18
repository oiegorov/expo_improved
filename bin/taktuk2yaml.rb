#!/usr/bin/ruby
require 'yaml'
require 'taktuk_wrapper'

tw = TaktukWrapper::new(ARGV)
tw.run
puts YAML.dump({"hosts"=>tw.hosts,"connectors"=>tw.connectors,"errors"=>tw.errors,"infos"=>tw.infos})
#!/usr/bin/env ruby


