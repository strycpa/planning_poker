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


unTpUser = (user) ->
	id: user.Id
	email: user.Email
	name: "#{user.FirstName} #{user.LastName}"
	role: user.Role.Name

unTpTeam = (team) ->
	id: team.Id
	name: team.Name

unTpUserStory = (userStory) ->
	id: userStory.Id
	name: userStory.Name
	description: userStory.Description

isScrummaster = (teamId) ->
	return yes unless teams[teamId]
	no

writeToTp = (userStoryId, estimation) ->
	no

app.io.route 'user_log', (req) ->
	tp.getUserId req.data.mail, (err, id) ->
		return err if err
		tp.getUser id, (err, user) ->
			return err if err
			user = unTpUser user
			req.session.user = user

			tp.getTeamIds user.id, (err, teamIds) ->
				return err if err
				for teamId in teamIds	#only one team
					req.session.teamId = teamId

					tp.getTeam teamId, (err, team) ->
						return err if err
						teams[teamId] = team
						req.session.team = team
						req.io.join team

						req.io.emit 'user_log_reply',
							teams: teams #array of int, currently an object


app.io.route 'user_choose_team', (req) ->
	req.io.join req.session.team
	req.io.emit 'user_enter_team',
		role: if isScrummaster req.session.teamId then 'sm' else 'monkey'
		team: [req.session.team]


app.io.route 'fetch_user_stories', (req) ->
	tp.getUserStories req.session.teamId, (err, stories) ->
		return err if err
		for story in stories
			story = unTpUserStory story
			userStories[req.session.teamId] ?= {}
			userStories[req.session.teamId][story.id] = story
		req.io.emit 'user_stories_list',
			list: userStories[req.session.teamId]


app.io.route 'user_story_for_estimation', (req) ->
#	if not userStories[req.session.teamId]?
#		tp.getUserStories req.session.teamId, (err, res) ->
#			return err if err
#			req.io.room(req.session.team).broadcast 'user_story_estimate', userStories[req.session.teamId][id]	#to samy
#	else
	req.io.room(req.session.team).broadcast 'user_story_estimate', userStories[req.session.teamId][req.data.id]	#to samy


app.io.route 'user_story_estimation', (req) ->
	value = req.data.value
	user = req.session.user.id
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