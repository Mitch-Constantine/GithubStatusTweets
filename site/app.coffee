express = require('express')
routes = require('./routes')
http = require('http');
assets = require 'connect-assets'

console.log __dirname + "/assets"

start = () ->
	console.log "Starting...."
	app = express();
	
	app.configure ->
	  app.set 'port', require('../configuration').getConfiguration().webPort
	  app.set 'views', __dirname + '/views'
	  app.set 'view engine', 'jade'
	  app.use assets {src:__dirname + "/assets"}
	  app.use express.favicon()
	  app.use express.logger('dev')
	  app.use express.bodyParser()
	  app.use express.methodOverride()
	  app.use app.router
	  app.use express.static(__dirname + '/public')
	  app.use (err, req, res, next) -> 
	  	console.log err
	  	res.send 500, err
	  app.use express.errorHandler()
	
	
	app.get '/tweets', routes.tweets
	app.post '/setRelevance', routes.setRelevance
	app.get '/', routes.index
	app.get '/admin', routes.admin
	
	http.createServer(app).listen app.get('port'), ->
	  console.log "Highway status tweets listening on port " + app.get('port')

exports.start = start	
start() if require.main == module 
