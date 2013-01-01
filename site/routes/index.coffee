DAL = require '../../DAL'

storage = new DAL.Storage
storage.configure require('../../configuration').getConfiguration()

exports.index = (req, res) ->
  noCache res
  res.render 'index', { title: 'Highway status tweets', relevantOnly: 1 }

exports.admin = (req, res) ->
  noCache res
  res.render 'index', { title: 'Highway status tweets', relevantOnly: 0 }

exports.tweets = (req, res)->
	noCache res
	start = parseInt(req.query["start"])
	count = parseInt(req.query["count"])
	relevantOnly = parseInt(req.query["relevantOnly"])
	storage.getPage start, count, relevantOnly == 1, (err, data)->
		res.send JSON.stringify( err ? data )

exports.setRelevance = (req, res) ->
	noCache res
	id = parseInt(req.body.id)
	isRelevant = parseInt(req.body.isRelevant)
	storage.setRelevant id, isRelevant, (err, data)->
		if err 
			res.send { err : err, data : null }
		else
			storage.getById id, (err, data) ->
				res.send { err : err, data : data }
				
noCache = (res)->
	res.header 'Cache-Control', 
		'no-cache, private, no-store, must-revalidate, max-stale=0, post-check=0, pre-check=0'

