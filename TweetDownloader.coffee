async = require 'async' 
logger = require './logger' 

log = (message, what) -> logger.log 'TweetDownloader', message, what

exports.download = (configuration, storage, twitter, callback) ->
	storage.configure configuration
	async.waterfall [
		
		(next)->storage.getNextSinceId next,
		
		(sinceId, next)->
		
			log 'sinceId', sinceId
			
			unless sinceId
				twitter.query configuration.term, configuration.location, null, 
							(err, data)->next(null, err, data, sinceId)
			else
				twitter.query_after sinceId, configuration.term, configuration.location, null, 
							(err, data)->next(null, err, data, sinceId),
							
		(err_twitter, data, sinceId, next)->
			
			log 'downloaded', [data, sinceId]
			nextId = if data and data.length > 0 then data[0].id else sinceId
			storage.setNextSinceId nextId, (err)->next(err, err_twitter, data),

		(err_twitter, data, next)->
		
			log 'uploaded sinceId', null
			
			if data.length > 0 
				storage.save data, (err)->next(err, err_twitter)
			else
				next(null, err_twitter)
	],
	callback