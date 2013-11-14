config =
  filename: __filename
  styles: '../styles/ui'
  scripts:
    connectionAlert: require './connectionAlert'
    date: require './date'
    path: require './path'

module.exports = (app, options) ->
  app.createLibrary config, options
