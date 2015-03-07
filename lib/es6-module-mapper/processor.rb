require 'es6-module-mapper/js_runner'
require 'yajl'

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

      @logger = @environment.logger

      @input_data = input[:data]

      @required = Set.new(input[:metadata][:required])
    end

    def transform
      @logger.info "Processing #{@name}"

      env = {
        "NODE_PATH" => File.expand_path('../../node_modules', File.dirname(__FILE__)),
        "MODULES_GLOBAL_VAR_NAME" => MODULES_GLOBAL_VAR_NAME,
        "MODULES_LOCAL_VAR_NAME" => MODULES_LOCAL_VAR_NAME,
        "IMPORT_MAPPING" => Yajl::Encoder.encode(parse_imports),
        "MODULE_NAME" => @name
      }
      transformed_data = JSRunner.call(TRANSFORMER_CMD, @input_data, env, @logger)

      {
        data: transformed_data,
        required: @required
      }
    end

    private

    def parse_imports
      @input_data.scan(/^import .*$/).inject({}) do |imports, line|
        lookup_name = line.match(/from[^'"]+(['"])([^\1]+)\1/)[2]
        uri, _ = resolve(lookup_name, accept: @content_type, bundle: false, compat: false)
        @required << uri
        name = @environment.load(uri).to_hash[:name]
        imports[lookup_name] = name
        imports
      end
    end

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
