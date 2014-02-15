async = require 'async'
request = require 'request'
moment = require 'moment'

#db = require './datamodel'


# Config
########
bugId = 8
userStoryId = 4
backLogId = 207
querylimit = 1000

token = "Mjk2OjkzNTNCMjUyMUU1Q0U4NkRERDFFRTI3MDlDQTVCQ0FB" # JanNavrat token


team_builder_id = 21927 # Back-end team

jan_navrat_id = 296

us_id = 31274

role_dev = 1
role_smaster = 7

# EXPORTS:

exports.getUser = (userId, cb) ->
	getUserById userId, (err, user) ->
		return cb err if err
		return cb null, user

exports.getUserId = (userEmail, cb) ->
	getUserIdByEmail userEmail, (err, userId) ->
		return cb err if err
		return cb null, userId

exports.getTeam = (teamId, cb) ->
	getTeamById teamId, (err, team) ->
		return cb err if err
		return cb null, team

exports.getTeamIds = (userId, cb) ->
	getTeamIdsByUserId userId, (err, teamIds) ->
		return cb err if err
		return cb null, teamIds

exports.getUserStories = (teamId, cb) ->
	getUserStoriesByTeamId teamId, (err, userStories) ->
		return cb err if err
		return cb null, userStories

exports.setEffort = (userStoryId, effort, cb) ->
	setUserStoryEffort userStoryId, effort, (err, result) ->
		return cb err if err
		return cb null, result




postRequest = (url, query, cb) ->
	options =
		url: url
		json: query
	request.post options, (err, req, body) ->
		return cb err if err
		return cb null, body

# make TP API request, it handles paging
makeRequest = (originalUrl, howMany, page, cb) ->
	url = originalUrl

	if page > 0 and howMany > querylimit # next paging round
		url = url + "&take=#{querylimit}&skip=#{page*querylimit}"
	else if page > 0 # last paging round
		url = url + "&take=#{howMany}&skip=#{page*querylimit}"
	else if howMany > querylimit or howMany is 0 # first paging round
		url = url + "&take=#{querylimit}"
	else if howMany > 0 # no paging
		url = url + "&take=#{howMany}"

	exports.requestFunction url, (err, data) ->
		if err? or not data?.Items?.length > 0
			return cb(err, data)
		else if 0 < howMany <= querylimit or data.Items.length < querylimit
			return cb(err, data.Items)
		else if querylimit < howMany
			take = howMany - querylimit
		else
			take = querylimit

		makeRequest originalUrl, take, page + 1, (err, recursiveData) ->
			cb err, data.Items.concat(recursiveData)

exports.requestFunction = (url, cb) ->
	request { uri: url, json: true }, (err, response, data) ->
		err = response.error if response?.error? and not err? and not data?
		cb err, data

# build TP request url to hit
buildUrl = (what, where = [], param = {}) ->
	url = "http://socialbakers.tpondemand.com/api/v1"
	# what
	url = url + "/" + one for one in what
	url = url + "/?"
	# where
	first = true
	for one in where
		if first
			url = url + "where=(" + one + ")"
			first = false
		else
			url = url + "and(" + one + ")"
	# param
	url = url + "&" + key + "=" + val for key, val of param
	# token
	encodeURI(url) + "&token=#{token}"

# array filter unique
Array::unique = ->
	output = {}
	output[@[key]] = @[key] for key in [0...@length]
	value for key, value of output











getUserById = (id, cb) ->
	url = buildUrl [ "Users" ], [
		"id eq '#{id}'"
	], {include: "[Id, Email, FirstName, LastName, IsActive, AvatarUri, Role]" }
	makeRequest url, 1, 0, (err, data) ->
		return cb err if err
		return cb null, data[0]

getUserIdByEmail = (email, cb) ->
	url = buildUrl [ "Users" ], [
		"Email eq '#{email}'"
	], {include: "[Id, Email, FirstName, LastName, IsActive, AvatarUri, Role]" }
	makeRequest url, 1, 0, (err, data) ->
		return cb err if err
		return cb null, data[0].Id


getTeamMembers = (teamId, cb) ->
	url = buildUrl [ "TeamMembers" ], [
		"Team.id eq #{teamId}",
		"Role.id in (#{role_dev},#{role_smaster})"
	], {include: "[Id, User, Role]"}
	makeRequest url, 100, 0, (err, data) ->
		return cb err if err
		return cb null, data

# getTeamMembers team_builder_id, (err, data) ->
# 	console.log data


getTeamById = (teamId, cb) ->
	url = buildUrl [ "Teams" ], [
		"id eq #{teamId}"
	], {}
	makeRequest url, 100, 0, (err, data) ->
		return cb err if err
		return cb null, data[0]

getTeamIdsByUserId = (userId, cb) ->
	url = buildUrl [ "TeamMembers" ], [
		"User.id eq #{userId}"
	], {}
	makeRequest url, 100, 0, (err, teamMembers) ->
		return cb err if err
		result = []
		for teamMember in teamMembers
			result.push teamMember.Team.Id
		return cb null, result




getNextTeamIterationId = (teamId, cb) ->
	url = buildUrl [ "TeamIterations" ], [
		"Team.id eq #{teamId}",
		"StartDate gte '#{moment().format("YYYY-MM-DD")}'"
	], { orderBy: "StartDate"} #, include: "[Id,StartDate,Duration]" }
	makeRequest url, 1, 0, (err, data) ->
		return cb err if err
		return cb null, data[0].Id


getUserStoriesByTeamId = (teamId, cb) ->
	getNextTeamIterationId teamId, (err, nextTeamIterationId) ->
		return cb err if err
		url = buildUrl [ "UserStories" ], [
			"Team.id eq #{teamId}",
			"TeamIteration.id eq #{nextTeamIterationId}",
			"Effort eq 0"
		], {include: "[Name, Description, Project, Release, Iteration, TeamIteration, Team, Priority, EntityState]"}
		makeRequest url, 100, 0, (err, userStories) ->
			return cb err if err
			return cb null, userStories


getRoleEffortId = (userStoryId, roleId, cb) ->
	url = buildUrl [ "RoleEfforts" ], [
		"Assignable.Id eq #{userStoryId}",
		"Role.Id eq #{roleId}",
		# "TeamIteration.id eq #{nextTeamIterationId}",
		# "Effort eq 0"
	], {}#include: "[Name, Description, Project, Release, Iteration, TeamIteration, Team, Priority, EntityState]"}
	makeRequest url, 100, 0, (err, userStories) ->
		return cb err if err
		return cb null, userStories[0].Id

setUserStoryEffort = (userStoryId, effort, cb) ->
	roleId = role_dev
	getRoleEffortId userStoryId, roleId, (err, roleEffortId) ->
		return cb err if err
		url = buildUrl [ "RoleEfforts/#{roleEffortId}" ], [], {}

		postRequest url, {Effort:effort}, (err, body) ->
			return cb err if err
			return cb body if body.Effort isnt effort
			cb null, yes

