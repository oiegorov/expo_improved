module Expo
class RCtrlResponse

  attr_accessor :result 
  def initialize
    @result = Hash::new
  end

  def [](name)
    return @result[name]
  end

  def []=(name,value)
    return @result[name] = value
  end

  def method_missing( method_id, *args )
    super if args.length > 0
    return @result[method_id.id2name]
  end

end

class AsynchronousCommandResponse < RCtrlResponse
end

class CommandInfoResponse < RCtrlResponse
end

class CommandInputResponse < RCtrlResponse
end

class CommandResponse < RCtrlResponse
end

class CommandResultResponse < RCtrlResponse
end

class CommandRewindResponse < RCtrlResponse
end

class DelayedCommandResponse < RCtrlResponse
end

class GetCommandInputsResponse < RCtrlResponse
end

class InteractiveCommandResponse < RCtrlResponse
end

class CommandWaitResponse < RCtrlResponse
end

class RecursiveCommandResponse < RCtrlResponse
end

class RubyAsynchronousCommandResponse < RCtrlResponse
end

class RubyCommandResponse < RCtrlResponse
end

class RubyDelayedCommandResponse < RCtrlResponse
end

class CommandDeleteResponse < RCtrlResponse
end

class CommandArchiveResponse < RCtrlResponse
end

class GenericCommandResponse < RCtrlResponse
end

class BulkRCtrlResponse < RCtrlResponse
  def each( &block )
    @result.each( &block )
    return self
  end

  def each_pairs( &block )
    @result.each_pairs( &block )
    return self
  end

  def each_key( &block )
    @result.each_key( &block )
    return self
  end

  def each_value( &block )
    @result.each_value( &block )
    return self
  end

  def length
    return @result.length
  end
end

class BulkCommandsResponse < BulkRCtrlResponse
end

class BulkCommandResultsResponse < BulkRCtrlResponse
end

class BulkCommandInfosResponse < BulkRCtrlResponse
end
end
