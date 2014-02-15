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
    teamsEl = $('<div id="list-choose-teams"></div>')
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
    @io.on 'user_enter_team', (data) ->
      @userTeam = data.team
      if data.role = 'sm'
        @user = new j3r.SmUser @io, @elements
      else if data.role = 'monkey'
        @user = new j3r.MonkeyUser @io, @elements
      else
        console.log 'whoopsie...wrong role returned'
      return
    return

class j3r.SmUser
  construct: (@io, @elements) ->
    _listenComunication()
    @io.emit 'fetch_user_stories'
    return

  _listenComunication: ->
    @io.on 'user_stories_list', (data) ->
      @us = new j3r.Us @io, data
      list = @us.getUsList()
#    start voting
      list.next('li').on 'click', ->
        selectedUsId = @.next('.us-item').attr('data-us-item-id')
        @us.startVoting selectedUsId
        return

#    receive votes
    @io.on 'user_story_estimated', (data) ->
      @us.addVote data
      return

#    after voting...init new
    @io.on 'show-estimation', (data) ->
      @io.emit 'fetch_user_stories'
      return

    return




class j3r.MonkeyUser
  construct: (@io, @elements) ->
    _listenComunication()

  _listenComunication: ->


