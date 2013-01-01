async = require 'async'

relevanceLogic = require './relevanceLogic'
dal = require './DAL'
logger = require './logger'

configuration = require('./configuration').getConfiguration()

storage = new dal.Storage()
storage.configure configuration

start = (next)->
	async.waterfall [
		(next)->relevanceLogic.createStatistics storage, next
		(statistics, next)->relevanceLogic.markRelevantTweets storage, statistics, next
	], (err)->
		logger.log 'UpdateDaemon', 'statistics calculated', ""
		logger.error err if err
		if next 
			next()
		else
			setTimeout start, configuration.markRelevantInterval

exports.start = start	
start() if require.main == module 
 