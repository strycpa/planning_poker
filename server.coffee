app = require('express.io')()
express = require('express.io')
path = require('path')
app.http().io()

rooms = {}
users = {}

app.use(express.static(path.join(__dirname, 'client')));

userUid = (user) ->
	user.email

addUserToRoom = (room, user) ->
	rooms[room] ?= {}
	rooms[room][userUid user] = user
	users[userUid user] ?= []
	users[userUid user].push room

removeUserFromRoom = (room, user) ->
	delete rooms[room][userUid user]
	delete users[userUid user][room]

isScrummaster = (room) ->
	rooms[room]?.length is 1

app.io.route 'joinRoom', (req) ->
	room = req.data.room
	user = req.data.user
	addUserToRoom room, user

	req.io.room(room).broadcast 'userJoined', {
		user: user
		isScrumMaster: isScrummaster room
	}
	console.log rooms

## send
#app.get '/', (req, res) ->
#	res.sendfile __dirname + '/client.html'


app.listen 2014