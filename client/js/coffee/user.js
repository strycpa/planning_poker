// Generated by CoffeeScript 1.6.3
j3r.User = (function() {
  function User(io, elements) {
    this.io = io;
    this.elements = elements;
    this._comunication();
  }

  User.prototype.logIn = function(userEmail) {
    var _this = this;
    this.userEmail = userEmail;
    j3r.changeContent(this.elements.content, $('<div class="msg-info component">loguju</div>'));
    this.io.emit('user_log', {
      mail: this.userEmail
    });
    this.io.on('user_log_reply', function(data) {
      if (data.teams.length > 0) {
        _this.chooseTeam(data.teams);
      }
    });
  };

  User.prototype.logOut = function() {
    this.io.emit('user_logout', {
      mail: this.userEmail
    });
    unset(window.localStorage.ppUser);
  };

  User.prototype.renderChooseTeam = function(teams) {
    var liEl, team, teamsEl, ulEl,
      _this = this;
    teamsEl = $('<div id="list-choose-teams" class="component">\
      <span class="headline">Choose your fucking team</span></div>');
    if (teams.length > 0) {
      ulEl = $('<ul></ul>');
      for (team in teams) {
        liEl = $('<li>' + team.title + '</li>');
        liEl.on('click', function() {
          _this.chooseTeam(team.id);
        });
        ulEl.append(liEl);
      }
      teamsEl.append(ulEl);
    } else {
      teamsEl.append($('<div class="msg-info component">You are in none of our fucking teams</div>'));
    }
    j3r.changeContent(this.elements.content, teamsEl);
  };

  User.prototype.chooseTeam = function(id) {
    this.io.emit('user_choose_team', {
      id: id
    });
  };

  User.prototype._comunication = function() {
    var _this = this;
    this.io.on('user_enter_team', function(data) {
      _this.userTeam = data.team;
      if (data.role === 'sm') {
        _this.user = new j3r.SmUser(_this.io, _this.elements);
      } else if (data.role === 'monkey') {
        _this.user = new j3r.MonkeyUser(_this.io, _this.elements);
      } else {
        console.log('whoopsie...wrong role returned');
      }
    });
  };

  return User;

})();

j3r.SmUser = (function() {
  function SmUser(io, elements) {
    var msg;
    this.io = io;
    this.elements = elements;
    msg = '<div class="msg-info component">waitin for us</div>';
    j3r.changeContent(this.elements.content, msg);
    this._comunication();
    return;
  }

  SmUser.prototype._comunication = function() {
    var _this = this;
    this.io.on('user_stories_list', function(data) {
      var list, _self;
      _this.us = new j3r.Us(_this.io, _this.elements, data);
      list = _this.us.getUsList();
      j3r.changeContent(_this.elements.content, list);
      _self = _this;
      list.find('li').on('click', function() {
        var selectedUsId;
        selectedUsId = $(this).find('.us-item').attr('data-us-item-id');
        _self.us.startVoting(selectedUsId);
      });
    });
    this.io.emit('fetch_user_stories');
    this.io.on('user_story_estimated', function(data) {
      _this.us.addVote(data);
    });
    this.io.on('show-estimation', function(data) {
      _this.io.emit('fetch_user_stories');
    });
  };

  return SmUser;

})();

j3r.MonkeyUser = (function() {
  function MonkeyUser(io, elements) {
    this.io = io;
    this.elements = elements;
    this.waitinMessage();
    this._comunication();
  }

  MonkeyUser.prototype._comunication = function() {
    var _this = this;
    this.io.on('user_story_estimate', function(data) {
      _this.startVoting(data);
    });
    return this.io.on('show_estimation', function(data) {
      _this.waitinMessage();
    });
  };

  MonkeyUser.prototype.startVoting = function(data) {
    var wrapper;
    this.us = new j3r.Us(this.io, this.elements, data);
    wrapper = $('<div id="voting-header"></div>');
    wrapper.append(this.us.getUsItem(data.id));
    j3r.changeContent(this.elements.content, wrapper);
    this.elements.content.append(this.getNumbers());
  };

  MonkeyUser.prototype.getNumbers = function() {
    var cardsTable, cardsWrapper, cell, i, j, numbers, row, selectedCardsWrapper, selection, _i, _j,
      _this = this;
    numbers = [0, 1, 2, 3, 5, 8, 13, 21, '?'];
    cardsWrapper = $('<div id="cards-wrapper"></div>');
    selectedCardsWrapper = $('<div id="cards-selected"></div>');
    cardsTable = $('<table id="cards-table"></table>');
    for (i = _i = 0; _i <= 2; i = _i += +1) {
      row = $('<tr></tr>');
      for (j = _j = 0; _j <= 2; j = _j += +1) {
        selection = numbers[i + j];
        cell = $('<td><div class="card-item"><br>' + selection + '</div></td>');
        cell.on('click', function() {
          _this.io.emit('user_story_estimation', {
            value: selection
          });
          return _this.afterSelectedNumber();
        });
        row.append(cell);
      }
      cardsTable.append(row);
    }
    cardsWrapper.append(selectedCardsWrapper);
    cardsWrapper.append(cardsTable);
    return cardsTable;
  };

  MonkeyUser.prototype.afterSelectedNumber = function() {};

  MonkeyUser.prototype.waitinMessage = function() {
    var msg;
    msg = '<div class="msg-info component">waitin for start of new voting</div>';
    j3r.changeContent(this.elements.content, msg);
  };

  return MonkeyUser;

})();
