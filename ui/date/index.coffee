moment = require 'moment'

exports.create = (model, dom) ->
  today = moment()
  value = moment model.get 'value'
  date = ''
  if value.isBefore today, 'day'
    date = value.format 'DD-MM-YY HH:mm:ss'
  else
    date = value.format 'HH:mm:ss'
  model.set 'date', date