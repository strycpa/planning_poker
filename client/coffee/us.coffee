class j3r.Us
  constructor: (@io, @elements, data) ->
    @hasUs = if data.length > 0 then yes else no
    @data = {}
    for item in data
      @data[item.id] = item
    return

  getUsList: ->
    usEl = $('<div id="list-choose-us" class="component"></div>')
    if @hasUs
      ulEl = $('<ul></ul>')
      for id, itemData of @data
        liEl = $('<li></li>')
        liEl.append @getUsItem itemData
        ulEl.append liEl
      usEl.append ulEl
    else
      usEl.append $('<div class="msg-info component">no work. go and fuck yourself</div>')
    usEl

  getUsItem: (itemData) ->
    usItem = $('<div class="us-item" data-us-item-id="' + itemData.id + '"><span class="us-item-title">
          ' + itemData.title + '</span><br>' + itemData.description if itemData.description? + '</div>')

  startVoting: (id) =>
#    to server - we are voting
    @io.emit 'user_story_for_estimation', id: id
    wrapper = $('<div id="voting-header" class="component"></div>')
    wrapper.append @getUsItem @data[id]
    wrapper.append $('<br>')
    inputConfirm = $('<input id="voting-input">')
    confirmBtn = $('<button id="voting-confirm">Confirm voting</button>')
    wrapper.append inputConfirm
    wrapper.append confirmBtn
#    action after confirm voting
    confirmBtn.on 'click', =>
      if inputConfirm.val() != ''
        @io.emit 'user_story_estimation_end', estimation: inputConfirm.val()
      else
        console.log 'cislo vole'
      return
    votingInfoWrapper = $('<div id="voting-info"></div>')
    wrapper.append votingInfoWrapper
    j3r.changeContent @elements.content, wrapper
    return

  addVote: (data) ->
    voteInfo = $('<div class="vote-info">' + data.user + ': <strong>' + data.value + '</strong></div>')
    @elements.content.append voteInfo
    return