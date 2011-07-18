require 'date'

oargridsub :res => "gdx:nodes=1,helios:nodes=1,capricorne:nodes=1,parasol:nodes=1"

check $all

fout = File::new("netmon.log.#{Time::new.to_i}", "w")

while true do
  $all.all.uniq.each do |source|
    $all.all.uniq.each do |target|
      next if source == target
      s = "#{source} -> #{target} : #{DateTime::now} "
      fout.print s
      result = task source, "'ping -q -c 1 #{target} | tail -n 2'"
      result.each_value { |h|
        h["commands"].each_value { |c|
          s = c["output"].gsub("\n"," ").gsub("/"," ")
	  fout.puts s
	  fout.flush
	}
      }
    end
  end
end
