app = require('express.io')()
app.http().io()

app.io.route 'confirm', (req) ->
	console.log req
	req.io.emit 'mrdka', {foo:'bar'}

# send
app.get '/', (req, res) ->
	res.sendfile __dirname + '/index.html'

app.listen 2014