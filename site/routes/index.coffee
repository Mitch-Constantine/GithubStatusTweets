DAL = require '../../DAL'

storage = new DAL.Storage
storage.configure {
	host: 'localhost'
	port: 27017
	databaseName: 'test'
	tweetCollectionName: 'tweets'
	sinceIdCollectionName: 'sinceId'
}

exports.index = (req, res) ->
  res.render 'index', { title: 'Highway status tweets', relevantOnly: 1 }

exports.admin = (req, res) ->
  res.render 'index', { title: 'Highway status tweets', relevantOnly: 0 }

exports.tweets = (req, res)->
	start = parseInt(req.query["start"])
	count = parseInt(req.query["count"])
	relevantOnly = parseInt(req.query["relevantOnly"])
	console.log relevantOnly
	storage.getPage start, count, relevantOnly == 1, (err, data)->
		res.send JSON.stringify( err ? data )

exports.setRelevance = (req, res) ->
	id = req.body.id
	isRelevant = req.body.isRelevant
	storage.setRelevant id, isRelevant, ()->res.send "OK"