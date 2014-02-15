app = require('express.io')()
express = require('express.io')
path = require('path')
#tp = require('target-process')
app.http().io()

teams = {}
userStories = {}
estimations = {}

app.use express.static path.join __dirname, 'client'
app.use express.cookieParser()
app.use express.session {secret: 'Socialbakers Planning Poker'}

userUid = (user) ->
	user.mail

addTeam = (team) ->
	teams[team] ?= []
	yes

addUserToTeam = (team, user) ->
	teams[team] ?= {}
	teams[team][userUid user] = user

removeUserFromTeam = (team, user) ->
	delete teams[team][userUid user]

isScrummaster = (team) ->
	teams[team]?.length is 1

getTeams = (user) ->
	{
		123: {id:123, title:"foos"}
		456: {id:456, title:"bars"}
	}

getUserStories = (team) ->
	tpUserStories = {
		123123: {id:123123, title:"foo something", description:"foo foo foo"}
		456456: {id:456456, title:"bar something else", description:"bar bar bar"}
	}
	extend (extend {}, userStories[team]), tpUserStories
	userStories

getUserStory = (id) ->
	us = getUserStories req.session.team	#nekonzistence
	us[id]

app.io.route 'user_log', (req) ->
	user = req.data.user
	req.session.email = user.email
	req.io.emit 'user_log_reply',
		logged: addUser user
		teams: getTeams user


app.io.route 'user_choose_team', (req) ->
	team = req.data.team
	user = req.data.user

	req.session.team = team
	req.session.user = user
	addUserToTeam team, user	#je to vubec potreba?

	req.io.join team
	req.io.emit 'user_enter_team',
		role: if isScrummaster team then 'sm' else 'monkey'
		team: teams[team]


app.io.route 'fetch_user_stories', (req) ->
	req.io.emit 'user_stories_list',
		list: getUserStories req.session.team

app.io.route 'user_story_for_estimation', (req) ->
	req.io.room(req.session.team).broadcast 'user_story_estimate', getUserStory(req.data.id)

app.io.route 'user_story_estimation', (req) ->
	value = req.data.value
	user = userUid req.session.user
	estimations[req.session.team][req.data.userStoryId][user] = value
	req.io.room(req.session.team).broadcast 'user_story_estimated',
		user: user
		value: value

app.io.route 'estimation_end', (req) ->
	req.io.room(req.session.team).broadcast 'show_estimations',
		estimations: estimations[req.session.team][req.data.userStoryId]

app.io.route 'planning_end', (req) ->
	req.io.room(req.session.team).broadcast 'disconnect'
	delete userStories[req.session.team]
	delete estimations[req.session.team]


## send
#app.get '/', (req, res) ->
#	res.sendfile __dirname + '/client.html'


app.listen 2014