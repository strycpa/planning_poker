async = require 'async'
request = require 'request'
moment = require 'moment'

db = require './datamodel'


# Config
########
bugId = 8
userStoryId = 4
backLogId = 207
querylimit = 1000


# Tasks
#######
# average velocity for last N finished sprints
exports.velocityTask = (source, cb) ->
	if source.options.team?
		cfg = { first: "TeamIteration", second: "Team" }; id = source.options.team
	else
		cfg = { first: "Iteration", second: "Project" }; id = source.options.project
	velocityQuery id, source.options.count, cfg, (err, data) ->
		velocityParse err, data, source.options.count, cfg.first, (err, datapoints) ->
			formatOutput err, datapoints, source, (cb)

velocityQuery = (id, count, cfg, cb) ->
	url = buildUrl [ "#{cfg.first}s" ], [
		"#{cfg.second}.id eq #{id}",
		"EndDate lt '#{moment().format("YYYY-MM-DD")}'"
	], { orderByDesc: "EndDate", include: "[Id,Velocity]" }

	makeRequest url, 2 * count, 0, (err, data) -> cb err, data

velocityParse = (err, data, count, key, cb) ->
	if data? and not err?
		rs = {}; sumNew = 0; sumOld = 0; counterNew = 0; counterOld = 0
		for item, i in data
			if i < count
				sumNew += item.Velocity; counterNew++
			else
				sumOld += item.Velocity; counterOld++
		ne = if sumNew is 0 then 0 else Math.round(sumNew / counterNew * 10) / 10
		ol = if sumOld is 0 then 0 else Math.round(sumOld / counterOld * 10) / 10
		cb err, [ne, ol]
	else
		cb err, null


# axis X has days in iteration (5 work days), axis Y effortToDo for user stories and bugs in this iteration, plus ideal line
exports.burndownTask = (source, cb) ->
	if source.options.team?
		cfg = { first: "TeamIteration", second: "Team" }; id = source.options.team
	else
		cfg = { first: "Iteration", second: "Project" }; id = source.options.project
	burndownQuery id, cfg, (err, data, iterationStart, duration) ->
		db.getSource source.name, (err, result) ->
			source.data = result.data if result?.data?.length > 0
			burndownParse err, data, source, iterationStart, duration, cfg.first, (err, datapoints, command) ->
				formatOutputBurndown err, datapoints, source, command, (cb)

burndownQuery = (id, cfg, cb) ->
	url = buildUrl [ "#{cfg.first}s" ], [
		"#{cfg.second}.id eq #{id}",
		"StartDate lte '#{moment().format("YYYY-MM-DD")}'"
	], { orderByDesc: "StartDate", include: "[Id,StartDate,Duration]" }

	makeRequest url, 1, 0, (err, data) ->
		return cb err, null, null if err
		iterationStart = moment(objToList(data, "StartDate")[0]).startOf('day')
		duration = objToList(data, "Duration")[0]

		url = buildUrl [ "Assignables" ], [
			"#{cfg.first}.id in (#{objToList(data, "Id").join()})",
			"EntityType.Id in (#{userStoryId},#{bugId})"
		], { include: "[EffortToDo, Effort]" }

		makeRequest url, 0, 0, (err, data) -> cb err, data, iterationStart, duration

burndownParse = (err, data, source, iterationStart, duration, key, cb) ->
	if data?.length > 0 and not err?
		max = sumUnique(data, "Id", "Effort")
		todayValue = [moment().startOf('day').valueOf(), sumUnique(data, "Id", "EffortToDo")]
		# any data inside?
		if source.data?.length > 0
			# right iteration? more than 14 hours from iteration start? "time to add tasks"
			if moment(source.data[1][0][0]).isSame(moment(iterationStart), 'day')
				# is weekend? is this day already in?
				if moment().isoWeekday() < 6 and not moment(source.data[0][source.data[0].length-1][0]).isSame(moment(), 'day')
					cb err, todayValue, "concat"
				else
					cb err, null, null
			else if moment().isAfter(moment(iterationStart).add('hours', 14))
				cb err, burndownInitialize(max, todayValue, duration, iterationStart), "reload"
			else
				cb err, null, null
		else
			cb err, burndownInitialize(max, todayValue, duration, iterationStart), "reload"
	else
		cb err, null, null

burndownInitialize = (max, todayValue, duration, iterationStart) ->
	count = 0; workdays = 0; datapoints = [[todayValue], []]
	for day in [0...duration]
		if moment(iterationStart).add('days', day).isoWeekday() < 6
			workdays++
	for day in [0..duration]
		if moment(iterationStart).add('days', day).isoWeekday() < 6
			datapoints[1].push [moment(iterationStart).add('days', day).valueOf(), max * (workdays - count++) / workdays]
	datapoints


# average time (in days) from create date to end date in last month and prev one
exports.avgLeadTimeTask = (source, cb) ->
	if source.options.team?
		cfg = "Team"; id = source.options.team
	else
		cfg = "Project"; id = source.options.project
	avgTimeQuery id, cfg, (err, data) ->
		avgTimeParse err, data, "LeadTime", (err, datapoints) ->
			formatOutput err, datapoints, source, (cb)

# average time (in days) from start date to end date in last month and prev one
exports.avgCycleTimeTask = (source, cb) ->
	if source.options.team?
		cfg = "Team"; id = source.options.team
	else
		cfg = "Project"; id = source.options.project
	avgTimeQuery id, cfg, (err, data) ->
		avgTimeParse err, data, "CycleTime", (err, datapoints) ->
			formatOutput err, datapoints, source, (cb)

avgTimeQuery = (id, cfg, cb) ->
	urlNew = buildUrl [ "Assignables" ], [
		"#{cfg}.id eq #{id}",
		"EntityType.Id in (#{userStoryId},#{bugId})",
		"EndDate gt '#{moment().subtract('months', 1).format("YYYY-MM-DD")}'",
		"EndDate lte '#{moment().format("YYYY-MM-DD")}'"
	], { include: "[LeadTime, CycleTime]" }

	urlOld = buildUrl [ "Assignables" ], [
		"#{cfg}.id eq #{id}",
		"EntityType.Id in (#{userStoryId},#{bugId})",
		"EndDate gt '#{moment().subtract('months', 2).format("YYYY-MM-DD")}'",
		"EndDate lte '#{moment().subtract('months', 1).format("YYYY-MM-DD")}'"
	], { include: "[LeadTime, CycleTime]" }

	async.parallel
		rsNew: (callback) -> makeRequest urlNew, 0, 0, (callback)
		rsOld: (callback) -> makeRequest urlOld, 0, 0, (callback)
	, (err, data) -> cb err, data

avgTimeParse = (err, data, metric, cb) ->
	if data.rsNew? and data.rsOld? and not err?
		sumNew = 0; sumOld = 0
		sumNew += item[metric] for item in data.rsNew
		sumOld += item[metric] for item in data.rsOld
		cb err, [Math.round(sumNew / data.rsNew.length * 10) / 10, Math.round(sumOld / data.rsOld.length * 10) / 10]
	else
		cb err, null


# number of entities in various states (in progress, in testing etc.) for this iteration
exports.entityStatesTask = (source, cb) ->
	if source.options.team?
		cfg = { first: "TeamIteration", second: "Team" }; id = source.options.team
	else
		cfg = { first: "Iteration", second: "Project" }; id = source.options.project
	entityStatesQuery id, cfg, (err, data, priority) ->
		entityStatesParse err, data, priority, (err, datapoints) ->
			formatOutput err, datapoints, source, (cb)

entityStatesQuery = (id, cfg, cb) ->
	url = buildUrl [ "#{cfg.first}s" ], [
		"#{cfg.second}.id eq #{id}",
		"StartDate lte '#{moment().format("YYYY-MM-DD")}'"
	], { orderByDesc: "StartDate", include: "[Id]" }

	makeRequest url, 1, 0, (err, data) ->

		urlthis = buildUrl [ "Assignables" ], [
			"#{cfg.first}.id in (#{objToList(data, "Id").join()})",
			"EntityType.Id in (#{userStoryId},#{bugId})"
		], { include: "[EntityState]" }

		urlall = buildUrl [ "Assignables" ], [
			"#{cfg.second}.id eq #{id}",
			"EntityType.Id in (#{userStoryId},#{bugId})"
		], { include: "[EntityState]" }

		async.parallel
			rsthis: (callback) -> makeRequest urlthis, 0, 0, (callback)
			rsall: (callback) -> makeRequest urlall, 0, 0, (callback)
		, (err, data) ->

			url = buildUrl [ "EntityStates" ], [
				"Id in (#{(item.EntityState.Id for item in data.rsall).unique()})"
			], { orderBy: "NumericPriority", include: "[Name,NumericPriority]" }

			makeRequest url, 0, 0, (err, priority) -> cb err, data, priority

entityStatesParse = (err, data, priority, cb) ->
	if data? and priority? and not err?
		datapoints = []; dict = {}; states = {}
		for item in data.rsthis
			if states[item.EntityState.Name]?
				states[item.EntityState.Name] += 1
			else
				states[item.EntityState.Name] = 1
		for item in priority
			if not dict[item.Name]?
				datapoints.push { title: item.Name, count: if states[item.Name]? then states[item.Name] else 0 }
				dict[item.Name] = 1
		cb err, datapoints
	else
		cb err, null


# how many features is not-done
exports.activeFeaturesTask = (source, cb) ->
	if source.options.team?
		cfg = "Team"; id = source.options.team
	else
		cfg = "Project"; id = source.options.project

	url = buildUrl [ "Features" ], [
		"#{cfg}.id eq #{id}",
		"EntityState.Name ne 'Done'"
	], { include: "[EntityState]" }

	makeRequest url, 0, 0, (err, data) ->
		datapoints = if data? and not err? then [data.length] else null
		formatOutput err, datapoints, source, (cb)


# how many entities is in backlog
exports.entityBacklogTask = (source, cb) ->
	url = buildUrl [ "Assignables" ], [
		"Project.id eq #{source.options.project}",
		"EntityType.Id in (#{userStoryId},#{bugId})",
		"EntityState.Name eq 'Open'"
	], { include: "[EntityState]" }

	makeRequest url, 0, 0, (err, data) ->
		datapoints = if data? and not err? then [data.length] else null
		formatOutput err, datapoints, source, (cb)

# Utility
#########
# get projects in targetprocess
exports.getProjectList = (cb) ->
	makeRequest buildUrl(["Projects"], [], {include: "[Id, Name]"}), 0, 0, (err, data) ->
		if data? and not err?
			cb err, data
		else
			cb err, null

# get teams in targetprocess
exports.getTeamList = (cb) ->
	makeRequest buildUrl(["Teams"], [], {include: "[Id, Name]"}), 0, 0, (err, data) ->
		if data? and not err?
			cb err, data
		else
			cb err, null


# Helpers
#########
# objToList([ {Id: 123}, {Id: 89, Douglas: "Adams" }, {Id: 7893} ], "Id") ===> [123, 89, 7893]
objToList = (list, key) ->
	result = obj[key] for obj in list

# make sum of item[key] in list, where item[unique] is unique
sumUnique = (list, unique, key) ->
	arr = []
	sum = 0
	for item in list
		if arr.lastIndexOf(item[unique]) < 0
			arr.push item[unique]
			sum += item[key]
	sum

# return correctly formated object
formatOutput = (err, datapoints, source, cb) ->
	if datapoints? and not err?
		source.data = datapoints
		cb err, { source: source, datapoints: source.data }
	else
		cb err, { source: source, datapoints: null }

# return correctly formated object, burndown only
formatOutputBurndown = (err, datapoints, source, command, cb) ->
	if datapoints? and command? and not err?
		if command is "concat"
			source.data[0].push datapoints
			cb err, { source: source, datapoints: datapoints }
		else if command is "reload"
			source.data = datapoints
			cb err, { source: source, datapoints: "reload" }
	else
		cb err, { source: source, datapoints: null }

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
	encodeURI(url) + "&token=#{process.env.TP_TOKEN}"

# array filter unique
Array::unique = ->
	output = {}
	output[@[key]] = @[key] for key in [0...@length]
	value for key, value of output
