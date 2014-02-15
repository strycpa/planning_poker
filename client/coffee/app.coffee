j3r = {}
j3r.listener = new j3r.SimpleListener()
class j3r.App
  constructor: ->
    @elements =
      header: $('#header-wrapper')
      info: $('#info-wrapper')
      content: $('#content-wrapper')
      footer: $('#footer-wrapper')
    @user = new j3r.User io.connect(), @elements
    return

  logInUser: (mail) ->
    @user.logIn mail
    return

class j3r.SimpleListener
  construct ->
    @listenOn = {}
    return

  listen: (id, scope, action) ->
    @listenOn[id] =
      action: action
      scope: scope
    return

  fire: (id, args) ->
    @listenOn[id].action() if @listenOn?
    return

j3r.changeContent = (parentEl, content) ->
   parentEl.empty().append(content)