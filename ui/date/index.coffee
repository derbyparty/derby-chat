moment = require 'moment'

exports.create = (model, dom) ->
  today = moment()
  unixDate = model.get 'value'
  if unixDate is 9999999999999
    value = today
  else
    value = moment unixDate
  date = ''
  if value.isBefore today, 'day'
    date = value.format 'DD-MM'# 'DD-MM-YY HH:mm:ss'
  else
    date = value.format 'HH:mm'# 'HH:mm:ss'
  model.set 'date', date