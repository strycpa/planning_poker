app = require('express.io')()
express = require 'express.io'
path = require 'path'
tp = require './server/tp'
app.http().io()

teams = {}
userStories = null
estimations = {}

app.use express.static path.join __dirname, 'client'
app.use express.cookieParser()
app.use express.session {secret: 'Socialbakers Planning Poker'}


convertUser = (user) ->
	id: user.Id
	email: user.Email
	name: "#{user.FirstName} #{user.LastName}"
	role: user.Role.Name

convertTeam = (team) ->
	id: team.Id
	title: team.Name

convertUserStory = (userStory) ->
	id: userStory.Id
	title: userStory.Name
	description: userStory.Description

isScrummaster = (teamId) ->
	return yes
	return yes unless teams[teamId]
	no

writeToTp = (userStoryId, estimation) ->
	no

app.io.route 'user_log', (req) ->
	tp.getUserId req.data.mail, (err, id) ->
		return err if err
		tp.getUser id, (err, user) ->
			return err if err
			user = convertUser user
			req.session.user = user

			tp.getTeamIds user.id, (err, teamIds) ->
				return err if err
				for teamId in teamIds	#only one team
					req.session.teamId = teamId

					tp.getTeam teamId, (err, team) ->
						return err if err
						team = convertTeam team
						teams[teamId] = team
						req.session.team = team
						req.io.join team

						req.io.emit 'user_log_reply',
							teams: [team]


app.io.route 'user_choose_team', (req) ->
	req.io.join req.session.team
	req.io.emit 'user_enter_team',
		role: if isScrummaster req.session.teamId then 'sm' else 'monkey'
		team: req.session.team


app.io.route 'fetch_user_stories', (req) ->
	tp.getUserStories req.session.teamId, (err, stories) ->
		return err if err
		for story in stories
			story = convertUserStory story
			userStories ?= {}
			userStories[req.session.teamId] ?= []
			userStories[req.session.teamId].push story
		req.io.emit 'user_stories_list', userStories[req.session.teamId]


app.io.route 'user_story_for_estimation', (req) ->
	for userStory in userStories[req.session.teamId]
		if userStory.id is req.data.id
			req.io.room(req.session.team).broadcast 'user_story_estimate', userStory


app.io.route 'user_story_estimation', (req) ->
	value = req.data.value
	user = req.session.user.id
	estimations[req.session.team][req.data.userStoryId][user] = value
	req.io.room(req.session.team).broadcast 'user_story_estimated',
		user: user
		value: value


app.io.route 'user_story_estimation_end', (req) ->
	tp.setEffort req.data.id, req.data.effort, (err, res) ->
		return err if err
		req.io.room(req.session.team).broadcast 'show_effort',
			effort: req.data.effort


app.io.route 'planning_end', (req) ->
	req.io.room(req.session.team).broadcast 'disconnect'
	delete userStories[req.session.team]
	delete estimations[req.session.team]


## send
#app.get '/', (req, res) ->
#	res.sendfile __dirname + '/client.html'

console.log 'Listening at http://localhost:2014/'
app.listen 2014