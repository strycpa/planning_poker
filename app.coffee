app = require('express.io')()
app.http().io()

app.io.route 'joinRoom', (req) ->
	console.log req
	req.io.join req.data.room
	req.io.room(req.data.room).broadcast 'userJoined', {
		userName: req.data.userName
	}

# send
app.get '/', (req, res) ->
	res.sendfile __dirname + '/index.html'

app.listen 2014