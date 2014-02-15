app = require('express.io')()
express = require 'express.io'
path = require 'path'
tp = require './server/tp'
app.http().io()

teams = {}
userStories = {}
estimations = {}

app.use express.static path.join __dirname, 'client'
app.use express.cookieParser()
app.use express.session {secret: 'Socialbakers Planning Poker'}

userId = (user) ->
	user.Id

isScrummaster = (teamId) ->
	return yes unless teams[teamId]
	no


getUserFromTP = (email) ->
	tp.getUser tp.getUserId email

getTeams = (user) ->
	teamIds = tp.getTeamIds userId user
	for teamId in teamIds
		teams[teamId] tp.getTeam teamId
	teams

getUserStories = (teamId) ->
	tpUserStories = tp.getUserStories teamId
	for userStory in tpUserStories
		userStories[userStory.Id] =
			id: userStory.Id
			name: userStory.Name
			description: userStory.Description
	userStories

getUserStory = (teamId, id) ->
	us = getUserStories teamId
	us[id]

writeToTp = (userStoryId, estimation) ->
	no

app.io.route 'user_log', (req) ->
	user = getUserFromTP req.data.user.mail
	userTeams = getTeams user
	userTeam = userTeams.pop()
	req.session.user = user
	req.session.team = userTeam
	req.session.teamId = userTeam.Id
	req.io.emit 'user_log_reply',
		teams: userTeams #array of int, currently an object


app.io.route 'user_choose_team', (req) ->
#	team = req.data.team
#	user = req.data.user
#
#	req.session.team = team
#	req.session.teamId = teamId
#	req.session.user = user

	req.io.join req.session.team
	req.io.emit 'user_enter_team',
		role: if isScrummaster req.session.teamId then 'sm' else 'monkey'
		team: req.session.team


app.io.route 'fetch_user_stories', (req) ->
	req.io.emit 'user_stories_list',
		list: getUserStories req.session.teamId

app.io.route 'user_story_for_estimation', (req) ->
	req.io.room(req.session.team).broadcast 'user_story_estimate', getUserStory req.session.teamId, req.data.id

app.io.route 'user_story_estimation', (req) ->
	value = req.data.value
	user = userId req.session.user
	estimations[req.session.team][req.data.userStoryId][user] = value
	req.io.room(req.session.team).broadcast 'user_story_estimated',
		user: user
		value: value

app.io.route 'estimation_end', (req) ->
	writeToTp req.data.userStoryId, req.data.estimation
	req.io.room(req.session.team).broadcast 'show_estimation',
		estimation: req.data.estimation

app.io.route 'planning_end', (req) ->
	req.io.room(req.session.team).broadcast 'disconnect'
	delete userStories[req.session.team]
	delete estimations[req.session.team]


## send
#app.get '/', (req, res) ->
#	res.sendfile __dirname + '/client.html'


app.listen 2014