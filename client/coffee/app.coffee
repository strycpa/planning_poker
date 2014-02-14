j3r = {}
class j3r.App
  constructor: (@name)->
    @socket = io.connect 'http://192.168.218.98:1107'
    @socket.on 'mrdka', (data) ->
      console.log data

  getName: ->
    alert @name
    return
