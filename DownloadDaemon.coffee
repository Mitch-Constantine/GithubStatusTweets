tweetDownloader = require './tweetDownloader' 
dal = require './DAL'

configuration = {
	pollInterval : 60000
	term : "403 OR 400 OR 401 OR 427 OR \"Queen Elizabeth Way\" OR QEW OR  \"Don Valley\" OR DVP near:\"Toronto, ON\""
	host: 'localhost'
	port: 27017
	databaseName: 'test'
	tweetCollectionName: 'tweets'
	sinceIdCollectionName: 'sinceId'
}

doDownload = ()->
	tweetDownloader.download configuration, storage, tweets, (err)->
		console.log err if err
		console.log "Tick"
		setInterval configuration.pollInterval, doDownload

doDownload()