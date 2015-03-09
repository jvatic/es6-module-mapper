require 'es6-module-mapper/js_runner'
require 'yajl'

module ES6ModuleMapper
  class Transformer
    VERSION = '1'
    TRANSFORMER_CMD = 'node '+ File.join(File.dirname(__FILE__), 'transformer.js')

    MODULES_GLOBAL_VAR_NAME = 'window.____modules____'
    MODULES_LOCAL_VAR_NAME = '__m__'

    def self.call(input)
      logger = input[:environment].logger
      logger.info "Transforming #{input[:name]}"

      env = {
        "NODE_PATH" => File.expand_path('../../node_modules', File.dirname(__FILE__)),
        "MODULES_GLOBAL_VAR_NAME" => MODULES_GLOBAL_VAR_NAME,
        "MODULES_LOCAL_VAR_NAME" => MODULES_LOCAL_VAR_NAME,
        "IMPORT_MAPPING" => Yajl::Encoder.encode(input[:metadata][:import_mapping]),
        "MODULE_NAME" => input[:name]
      }

      { data: JSRunner.call(TRANSFORMER_CMD, input[:data], env, logger) }
    end
  end
end
