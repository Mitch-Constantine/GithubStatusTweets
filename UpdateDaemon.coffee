async = require('async')

relevanceLogic = require( './relevanceLogic')
dal = require( './DAL')

configuration = {
	markRelevantInterval : 1000
	term : "401 OR 400 OR 403 OR 407 OR QEW OR DVP OR \"Queen Elizabeth Way\" OR \"Don Valley Parkway\"",
	location: "43.716589,-79.340686,20mi"
	host: 'localhost'
	port: 27017
	databaseName: 'test'
	tweetCollectionName: 'tweets'
	sinceIdCollectionName: 'sinceId'
}

storage = new dal.Storage()
storage.configure configuration

doDownload = ()->
	async.waterfall [
		(next)->relevanceLogic.createStatistics storage, next
		(statistics, next)->relevanceLogic.markRelevantTweets storage, statistics, next
	], (err)->
		console.log "."
		console.log err if err
		setTimeout doDownload, configuration.markRelevantInterval
		
doDownload()