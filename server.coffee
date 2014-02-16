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

isScrummaster = (req, teamId) ->	#after presentation, remove req
	return yes if req.session.email is 'petr.jancarik@socialbakers.com'	#presentation
	return no																														#presentation
	return yes unless teams[teamId]
	no

writeToTp = (userStoryId, estimation) ->
	no

app.io.route 'user_log', (req) ->
	mail = req.data.mail
	req.session.email = mail
	tp.getUserId mail, (err, id) ->
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
						console.log "#{user.name} logged to #{team.title} planning"
						teams[teamId] = team
						req.session.team = team
						req.io.join team

						req.io.emit 'user_log_reply',
							teams: [team]

# zrefaktorovat a odstranit
app.io.route 'user_choose_team', (req) ->
	req.io.join req.session.team
	req.io.emit 'user_enter_team',
		role: if isScrummaster req, req.session.teamId then 'sm' else 'monkey'
		team: req.session.team


app.io.route 'fetch_user_stories', (req) ->
	tp.getUserStories req.session.teamId, (err, stories) ->
		console.log "Fetched #{stories.length} user stories"
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
			console.log "Estimate user story '#{userStory.title}'"


app.io.route 'user_story_estimation', (req) ->
	value = req.data.value
	user = req.session.user
	estimations[req.session.team] ?= {}
	estimations[req.session.team][req.data.userStoryId] ?= {}
	estimations[req.session.team][req.data.userStoryId][user.id] = value
	req.io.room(req.session.team).broadcast 'user_story_estimated',
		user: user.name
		value: value
	console.log "#{user.name} thinks #{value} points"


app.io.route 'user_story_estimation_end', (req) ->
	tp.setEffort req.data.id, req.data.effort, (err, res) ->
		return err if err
		effort = req.data.effort
		req.io.room(req.session.team).broadcast 'show_effort',
			effort: effort
		console.log "Effort set to #{effort}"


app.io.route 'planning_end', (req) ->
	req.io.room(req.session.team).broadcast 'disconnect'
	delete userStories[req.session.team]
	delete estimations[req.session.team]
	console.log "Planning of #{team.title} ended"

	
console.log 'Listening at http://localhost:2014/'
app.listen 2014