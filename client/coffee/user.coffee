class  j3r.User
  constructor: (@io, @elements) ->
    @_comunication()

  logIn: (@userEmail) ->
#    login loader
    j3r.changeContent @elements.content, $('<div class="msg-info component">loguju</div>')

    #    login request
    @io.emit 'user_log',
      mail: @userEmail

    #    login response
    @io.on 'user_log_reply', (data) =>
      if data.teams.length > 0
        @chooseTeam data.teams
      return
    return

  logOut: ->
    @io.emit 'user_logout',
      mail: @userEmail
    unset window.localStorage.ppUser
    return

  renderChooseTeam: (teams) ->
    teamsEl = $('<div id="list-choose-teams" class="component">
      <span class="headline">Choose your fucking team</span></div>')
    if teams.length > 0
      ulEl = $('<ul></ul>')
      for team of teams
        liEl = $('<li>' + team.title + '</li>')
        liEl.on 'click', =>
          @chooseTeam team.id
          return
        ulEl.append liEl
      teamsEl.append ulEl
    else
      teamsEl.append $('<div class="msg-info component">You are in none of our fucking teams</div>')
    j3r.changeContent @elements.content, teamsEl
    return

  chooseTeam: (id) ->
    @io.emit 'user_choose_team', id: id
    return

  _comunication: () ->
    @io.on 'user_enter_team', (data) =>
      @userTeam = data.team
      if data.role is 'sm'
        @user = new j3r.SmUser @io, @elements
      else if data.role is 'monkey'
        @user = new j3r.MonkeyUser @io, @elements
      else
        console.log 'whoopsie...wrong role returned'
      return
    return

class j3r.SmUser
  constructor: (@io, @elements) ->
    msg = '<div class="msg-info component">waitin for us</div>'
    j3r.changeContent @elements.content, msg
    @_comunication()
    return

  _comunication: ->
#   receive us list
    @io.on 'user_stories_list', (data) =>
      @us = new j3r.Us @io, @elements, data
      list = @us.getUsList()
      j3r.changeContent @elements.content, list
      _self = @
      list.find('li').on 'click', ->
        selectedUsId = $(@).find('.us-item').attr('data-us-item-id')
        _self.us.startVoting selectedUsId
        return
      return

#    send me list of us
    @io.emit 'fetch_user_stories'


    #    receive votes
    @io.on 'user_story_estimated', (data) =>
      @us.addVote data
      return

#    after voting...init new
    @io.on 'show-estimation', (data) =>
      @io.emit 'fetch_user_stories'
      return

    return




class j3r.MonkeyUser
  constructor: (@io, @elements) ->
    @waitinMessage()
    @_comunication()

  _comunication: ->
    @io.on 'user_story_estimate', (data) =>
      @startVoting data
      return

    @io.on 'show_estimation', (data) =>
      @waitinMessage()
      return

  startVoting: (data) ->
    @us = new j3r.Us @io, @elements, data
    wrapper = $('<div id="voting-header"></div>')
    wrapper.append @us.getUsItem data.id
    j3r.changeContent @elements.content, wrapper
    @elements.content.append @getNumbers()
    return

  getNumbers: ->
    numbers = [0,1,2,3,5,8,13,21,'?']
    cardsWrapper = $('<div id="cards-wrapper"></div>')
    selectedCardsWrapper = $('<div id="cards-selected"></div>')
    cardsTable = $('<table id="cards-table"></table>')
    for i in [0..2] by +1
      row = $('<tr></tr>');
      for j in [0..2] by + 1
        selection = numbers[i+j]
        cell = $('<td><div class="card-item"><br>' + selection + '</div></td>')
        cell.on 'click', =>
          @io.emit 'user_story_estimation', value: selection
          @afterSelectedNumber()
        row.append cell
      cardsTable.append row
    cardsWrapper.append selectedCardsWrapper
    cardsWrapper.append cardsTable
    cardsTable

#    TODO some mega cool animation
  afterSelectedNumber: ->

  waitinMessage: () ->
    msg = '<div class="msg-info component">waitin for start of new voting</div>'
    j3r.changeContent @elements.content, msg
    return


