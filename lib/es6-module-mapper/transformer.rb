require 'es6-module-mapper/js_runner'
require 'yajl'

module ES6ModuleMapper
  class Transformer
    VERSION = '1'
    NODEJS_CMD = %w[node nodejs].map { |cmd| %x{which #{cmd}}.chomp }.find { |cmd| !cmd.empty? }
    TRANSFORMER_CMD = "#{NODEJS_CMD} #{File.join(File.dirname(__FILE__), 'transformer.js')}"

    MODULES_GLOBAL_VAR_NAME = 'window.____modules____'
    MODULES_LOCAL_VAR_NAME = '__m__'

    def self.call(input)
      logger = input[:environment].logger
      if input[:metadata][:import_mapping].keys.size == 0 && input[:data].match(/^export\s/).nil?
        logger.info "Skipping transform for #{input[:name]}"
        return { data: input[:data] }
      end
      logger.info "Transforming #{input[:name]}"

      env = {
        "NODE_PATH" => File.expand_path('../../node_modules', File.dirname(__FILE__)),
        "MODULES_GLOBAL_VAR_NAME" => MODULES_GLOBAL_VAR_NAME,
        "MODULES_LOCAL_VAR_NAME" => MODULES_LOCAL_VAR_NAME,
        "IMPORT_MAPPING" => Yajl::Encoder.encode(input[:metadata][:import_mapping]),
        "MODULE_NAME" => input[:name]
      }

      { data: JSRunner.call(TRANSFORMER_CMD, input[:data], env, logger) }
    rescue => e
      logger.debug "Transform failed for #{input[:name]}"
      raise e
    end
  end
end
