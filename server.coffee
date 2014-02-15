app = require('express.io')()
express = require('express.io')
path = require('path')
app.http().io()

teams = {}
users = {}

app.use express.static path.join __dirname, 'client'
app.use express.cookieParser()
app.use express.session {secret: 'Socialbakers Planning Poker'}

userUid = (user) ->
	user.mail

addUser = (user) ->
	users[userUid user] ?= []
	yes

addTeam = (team) ->
	teams[team] ?= []
	yes

addUserToTeam = (team, user) ->
	teams[team] ?= {}
	teams[team][userUid user] = user
	users[userUid user] ?= []
	users[userUid user].push team

removeUserFromTeam = (team, user) ->
	delete teams[team][userUid user]
	delete users[userUid user][team]

isScrummaster = (team) ->
	teams[team]?.length is 1

app.io.route 'user_log', (req) ->
	req.session.loginDate = new Date().toString()
	req.io.emit 'user_log_reply', {
		logged: addUser req.data.user
		teams: teams
	}

app.io.route 'user_choose_team', (req) ->
	team = req.data.team
	user = req.data.user

	req.session.team = team
	req.session.user = user
	addUserToTeam team, user	#je to vubec potreba?

	req.io.join team
	req.io.team(team).broadcast 'user_enter_team', {
		role: if isScrummaster team then 'sm' else 'monkey'
		team: teams[team]
	}

## send
#app.get '/', (req, res) ->
#	res.sendfile __dirname + '/client.html'


app.listen 2014