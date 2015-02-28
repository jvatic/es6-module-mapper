require 'es6-module-mapper/js_runner'

module ES6ModuleMapper
  class Processor
    VERSION = '1'
    TRANSFORMER_CMD = 'node '+ File.join(File.dirname(__FILE__), 'transformer.js')

    MODULES_GLOBAL_VAR_NAME = 'window.____modules____'
    MODULES_LOCAL_VAR_NAME = '__m__'

    def self.call(input)
      key = [VERSION, input[:data]]
      input[:cache].fetch(key) do
        new(input).transform
      end
    end

    def initialize(input)
      @environment  = input[:environment]
      @load_path    = input[:load_path]
      @name         = input[:name]
      @dirname      = File.dirname(input[:filename])
      @content_type = input[:content_type]

      @input_data = input[:data]

      @required = Set.new(input[:metadata][:required])
    end

    def transform
      transformed_data = nil
      env = {
        "NODE_PATH" => File.expand_path('../../node_modules', File.dirname(__FILE__))
      }
      JSRunner.call(TRANSFORMER_CMD, env) do |event, cb|
        case event.name
        when :start
          cb.call(JSRunner::Event.new(:transform, {
            modulesGlobalVarName: MODULES_GLOBAL_VAR_NAME,
            modulesLocalVarName: MODULES_LOCAL_VAR_NAME,
            moduleName: @name,
            body: @input_data
          }))
        when :transformed
          cb.call(JSRunner::Event.new(:end))
          transformed_data = event.data["body"]
        when :moduleNameLookup
          uri, _ = resolve(event.data["lookupName"], accept: @content_type, bundle: false, compat: false)
          name = @environment.load(uri).to_hash[:name]
          @required << uri
          cb.call(JSRunner::Event.new(:moduleName, {
            lookupName: event.data["lookupName"],
            name: name
          }))
        end
      end

      {
        data: transformed_data,
        required: @required
      }
    end

    private

    def resolve(path, options = {})
      if @environment.absolute_path?(path)
        raise Sprockets::FileOutsidePaths, "can't require absolute file: #{path}"
      elsif @environment.relative_path?(path)
        path = expand_relative_path(path)
        if logical_path = @environment.split_subpath(@load_path, path)
          if filename = @environment.resolve(logical_path, options.merge(load_paths: [@load_path]))
            filename
          else
            accept = options[:accept]
            message = "couldn't find file '#{logical_path}' under '#{@load_path}'"
            message << " with type '#{accept}'" if accept
            raise Sprockets::FileNotFound, message
          end
        else
          raise Sprockets::FileOutsidePaths, "#{path} isn't under path: #{@load_path}"
        end
      else
        filename = @environment.resolve(path, options)
      end

      if filename
        filename
      else
        accept = options[:accept]
        message = "couldn't find file '#{path}'"
        message << " with type '#{accept}'" if accept
        raise Sprockets::FileNotFound, message
      end
    end

    def expand_relative_path(path)
      File.expand_path(path, @dirname)
    end
  end
end
