derby = require 'derby'

exports.init = (model) ->
  path = model.get('path1') + model.get('path2') + model.get('path3')
  model.ref 'value', model.scope path