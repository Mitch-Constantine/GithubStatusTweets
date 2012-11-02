express = require('express')
routes = require('./routes')
http = require('http');

app = express();

app.configure ->
  app.set 'port', process.env.PORT || 3000
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use require('connect-assets')()
  app.use express.favicon()
  app.use express.logger('dev')
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static(__dirname + '/public')
  app.use (err, req, res, next) ->
  	console.error err
  	res.send 500, 'Something broke!'

app.configure 'development', ->
  app.use express.errorHandler()


app.get '/tweets', routes.tweets
app.post '/setRelevance', routes.setRelevance
app.get '/', routes.index
app.get '/admin', routes.admin

http.createServer(app).listen app.get('port'), ->
  console.log "Highway status tweets listening on port " + app.get('port')

