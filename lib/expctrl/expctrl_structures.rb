require 'resctrl/resctrl_structures'

module Expo

CreateExperimentParameters = Struct::new("CreateExperimentParameters")
AddCommandParameters = Struct::new(:experiment_number, :command_number)
AddCommandsParameters = Struct::new(:experiment_number, :command_numbers)
AddNodesParameters = Struct::new(:experiment_number, :nodes_name, :nodes)
AddReservationParameters = Struct::new(:experiment_number, :reservation_number)
GetNodesParameters = Struct::new(:experiment_number, :nodes_name)
GetAllNodesParameters = Struct::new(:experiment_number)
GetAllReservationsParameters = Struct::new(:experiment_number)
GetAllCommandsParameters = Struct::new(:experiment_number)
NodesParameters = Struct::new(:nodes_name, :nodes )
CommandsParameters = Struct::new("CommandsParameters")
ReservationsParameters = Struct::new("ReservationsParameters")
AllParameters = Struct::new("AllParameters")
DumpExperimentParameters = Struct::new("DumpExperimentParameters")
OpenExperementParameters = Struct::new(:experiment_number)
CloseExperimentParameters = Struct::new("CloseExperimentParameters")

end
