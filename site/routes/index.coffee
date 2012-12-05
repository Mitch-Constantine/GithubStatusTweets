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
	storage.getPage start, count, relevantOnly == 1, (err, data)->
		res.send JSON.stringify( err ? data )

exports.setRelevance = (req, res) ->
	id = parseInt(req.body.id)
	isRelevant = parseInt(req.body.isRelevant)
	storage.setRelevant id, isRelevant, (err, data)->
		if err 
			res.send { err : err, data : null }
		else
			storage.getById id, (err, data) ->
				res.send { err : err, data : data }