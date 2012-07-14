async = require( 'async' )

exports.download = (configuration, storage, twitter, callback) ->
	storage.configure configuration
	async.waterfall [
		(next)->storage.getNextSinceId next,
		(sinceId, next)->
			if sinceId
				twitter.query configuration.term, null, (err, data)->next(err, data, sinceId)
			else
				twitter.query_after sinceId, configuration.term, null, (err, data)->next(err, data, sinceId),
		(data, sinceId, next)->
			storage.setNextId sinceId, (err)->next(err, data),
		(data, next)->
			storage.save data, next
	],
	callback