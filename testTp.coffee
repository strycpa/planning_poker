tp = require './server/tp'

jan_navrat_id = 296
jan_navrat_email = 'jan.navrat@socialbakers.com'
team_id = 21927
us_id = 31274
effort = 7

tp.getUser jan_navrat_id, (err, user) ->
#	console.log user

tp.getUserId jan_navrat_email, (err, userId) ->
#	console.log userId

tp.getTeam team_id, (err, team) ->
#	console.log team

tp.getTeamIds jan_navrat_id, (err, teamIds) ->
#	console.log teamIds

tp.getUserStories team_id, (err, userStories) ->
#	console.log userStories

tp.setEffort us_id, effort, (err, result) ->
	console.log result