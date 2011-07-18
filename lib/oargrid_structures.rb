module Expo

OargridsubParameters = Struct::new(:start_date,
                                   :queue,
                                   :program,
                                   :walltime,
                                   :directory,
                                   :verbose,
                                   :force,
                                   :file,
                                   :description)
OargridstatParameters = Struct::new(:help,
                                    :id,
                                    :list_nodes,
				    :cluster_name,
                                    :job_id,
                                    :xml,
                                    :yaml,
                                    :dumper,
                                    :wait,
                                    :polling,
                                    :max_polling,
                                    :monitor,
				    :cluster_names,
                                    :gantt,
                                    :list_clusters,
                                    :version)

end
