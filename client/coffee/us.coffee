class j3r.Us
  constructor: (@io, @elements, @data) ->

  getUsList: ->
    usEl = $('<div id="list-choose-us"></div>')
    if @data.length > 0
      ulEl = $('<ul></ul>')
      for itemData in @data
        liEl = $('<li></li>')
        liEl.append @getUsItem itemData
        ulEl.append liEl
      usEl.append ulEl
    else
      usEl.append $('<div id="msg-info">no work. go and fuck yourself</div>')
    usEl

  getUsItem: (itemData) ->
    usItem = $('<div class="us-item" data-us-item-id="' + itemData.id + '"><span class="us-item-title">
          ' + itemData.title + '</span><br>' + itemData.description + '</div>')

  startVoting: (id) =>
#    to server - we are voting
    @io.emit 'user_story_for_estimation', id: @item.id
    wrapper = $('<div id="voting-header"></div>')
    wrapper.append @item.getUsItem id, @data[id]
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
    wrapper.apend $('<div id="voting-info"></div>')
    j3r.changeContent @elements.content, wrapper
    return

  addVote: (data) ->
    voteInfo = $('<div class="vote-info">' + data.user + ': <strong>' + id.value + '</strong></div>')
    @elements.content.append voteInfo
    return