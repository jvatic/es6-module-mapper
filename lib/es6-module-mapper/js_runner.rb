require 'open3'
require 'yajl'
require 'uri'
require 'net/http'

module ES6ModuleMapper
  module JSRunner
    def self.call(cmd, input_data, env={}, logger)
      Open3.popen3(env, cmd) do |stdin, stdout, stderr, t|
        stdin.puts(input_data)
        stdin.close

        output_data = ""

        begin
          while true
            readables = IO.select([stdout, stderr]).to_a[0]
            readables.each do |io|
              if io == stdout
                while l = io.readline
                  output_data << l
                end
              else
                while l = io.readline
                  logger.info(l)
                end
              end
            end
          end
        rescue EOFError
        end

        exit_status = t.value # wait for cmd to exit

        if exit_status != 0
          logger.debug "non-zero exit status: #{exit_status}"
        end

        output_data
      end
    end
  end
end
