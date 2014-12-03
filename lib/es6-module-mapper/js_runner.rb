require 'open3'
require 'yajl'
require 'uri'
require 'net/http'

module ES6ModuleMapper
  module JSRunner
    def self.call(cmd, env={}, &block)
      Open3.popen3(env, cmd) do |stdin, stdout, stderr, t|
        cb = proc do |event|
          begin
            stdin.puts(event.to_s)
          rescue => e
            p ["Error writing event", event, e]
          end
        end

        event_lines = []
        begin
          while true
            readables = IO.select([stdout, stderr]).to_a[0]
            readables.each do |io|
              if io == stdout
                while l = io.readline
                  if l == "\n"
                    block.call(Event.parse(event_lines), cb)
                    event_lines = []
                    break
                  end
                  event_lines << l.chomp
                end
              else
                begin
                  while str = io.read_nonblock(1024)
                    STDERR.print(str)
                  end
                rescue IO::EAGAINWaitReadable
                end
              end
            end
          end
        rescue EOFError
        end
        t.value # wait for cmd to exit
      end
    end

    protected

    class Event
      def self.parse(lines)
        data = lines.inject({}) do |m, l|
          _, key, val = l.match(/\A([^:]+):\s+(.*)\Z/).to_a
          m[key] = key == "data" ? Yajl::Parser.parse(val) : val
          m
        end
        Event.new(data["event"].to_sym, data["data"])
      end

      attr_reader :name, :data
      def initialize(name, data={})
        @name = name
        @data = data
      end

      def to_s(opts = {})
        str = ""
        str << "event: #{self.name}\n"
        str << "data: #{Yajl::Encoder.encode(self.data)}\n\n"
        str
      end
    end
  end
end
