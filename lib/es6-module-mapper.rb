require 'sprockets'
require 'es6-module-mapper/version'
require 'es6-module-mapper/processor'
require 'es6-module-mapper/transformer'

module ES6ModuleMapper
  Sprockets.register_preprocessor('application/javascript', Processor)
  Sprockets.register_postprocessor('application/javascript', Transformer)
end
