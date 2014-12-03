require 'sprockets'
require 'es6-module-mapper/version'
require 'es6-module-mapper/processor'

module ES6ModuleMapper
  Sprockets.register_preprocessor('application/javascript', Processor)
end
