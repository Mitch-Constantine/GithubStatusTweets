async = require( 'async' )

exports.download = (configuration, storage, twitter, callback) ->
	storage.configure configuration
	async.waterfall [
		(next)->storage.getNextSinceId next,
		(sinceId, next)->
			console.log "Querying...."
			unless sinceId
				twitter.query configuration.term, configuration.location, null, 
							(err, data)->next(null, err, data, sinceId)
			else
				twitter.query_after sinceId, configuration.term, configuration.location, null, 
							(err, data)->next(null, err, data, sinceId),
		(err_twitter, data, sinceId, next)->
			console.log "Saving sinceId"
			nextId = if data and data.length > 0 then data[0].id else sinceId
			storage.setNextSinceId nextId, (err)->next(err, err_twitter, data),
		(err_twitter, data, next)->
			console.log "Saving data"
			console.log data.length + " records found"
			if data.length > 0 
				storage.save data, (err)->next(err, err_twitter)
			else
				next(null, err_twitter)
	],
	callback