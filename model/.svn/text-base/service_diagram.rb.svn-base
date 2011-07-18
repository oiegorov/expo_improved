require 'rubygems'
require 'uml/class_diagram'
require 'expctrl/expctrl_service'


cd = UML::ClassDiagram.new :show_private_methods => false,
  :show_protected_methods => false,
  :show_public_methods => true,
  :cluster_packages => true,
  :include => [/Ctrl/, /Expo/]

cd.include Expo::ExpCtrlService

service = Expo::ExpCtrlService::new

service.command("date")

result = service.delayed_command("date",DateTime::now + (2.0)/(24*60*60))

sleep 3

File.open('service_diagram.dot', 'w') { |file|
  file.write cd.to_dot
}
