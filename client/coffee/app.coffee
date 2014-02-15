j3r = {}
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


j3r.changeContent = (parentEl, content) ->
   parentEl.empty().append(content)


