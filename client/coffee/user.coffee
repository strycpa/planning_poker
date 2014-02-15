class  j3r.User
  constructor: (@io, @elements) ->
    @_listenComunication()

  logIn: (@userEmail) ->
#    login loader
    j3r.changeContent @elements.content, 'loguju'

    #    login request
    @io.emit 'user_log',
      mail: @userEmail

    #    login response
    @io.on 'user_log_reply', (data) ->
      if data.logged
        @chooseTeam data.rooms
      return
    return

  logOut: ->
    @io.emit 'user_logout',
      mail: @userEmail
    unset window.localStorage.ppUser
    return

  renderChooseTeam: (teams) ->
    teamsEl = $('<div id="teams-choose"></div>')
    if teams.length > 0
      ulEl = $('<ul></ul>')
      for team of teams
        liEl = $('<li>' + team.title + '</li>')
        liEl.on 'click', ->
          @chooseTeam team.id
          return
        ulEl.append liEl
      teamsEl.append ulEl
    else
      teamsEl.append $('<div id="msg-info">you are in none of our fucking teams</div>')
    j3r.changeContent j3r.App.elements.content, teamsEl
    return

  chooseTeam: (id) ->
    @io.emit 'user_choose_team', id: id
    return

  _listenComunication: () ->
    @io.on 'user_enter_team', (role) ->
#      todo role
      return
    return

