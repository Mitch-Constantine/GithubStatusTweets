express = require 'express'
require 'jade'

DAL = require './DAL'
storage = new DAL.Storage
storage.configure {
	host: 'localhost'
	port: 27017
	databaseName: 'test'
	tweetCollectionName: 'tweets'
	sinceIdCollectionName: 'sinceId'
}

app = express.createServer();

app.use express.static( __dirname + '/public' ) 
app.use require('connect-assets')()
app.set 'view engine', 'jade'
app.set 'view options', {
  layout: false
}
app.get '/test', (req,res)->res.render 'test.jade'
app.get '/tweets', (req, res)->
	storage.getPage req.query["start"], req.query["pageSize"], (err, data)->
		res.send JSON.stringify( err ? data )

console.log js('test')
console.log js('index')
	
app.listen 3000