tweetDownloader = require './tweetDownloader' 
dal = require './DAL'
twitterInterface = require './TwitterInterface'

configuration = {
	pollInterval : 1000
	term : "401 OR 400 OR 403 OR 407 OR QEW OR DVP OR \"Queen Elizabeth Way\" OR \"Don Valley Parkway\"",
	location: "43.716589,-79.340686,20mi"
	host: 'localhost'
	port: 27017
	databaseName: 'test'
	tweetCollectionName: 'tweets'
	sinceIdCollectionName: 'sinceId'
}

storage = new dal.Storage()
tweets = new twitterInterface.Twitter()

doDownload = ()->
	tweetDownloader.download configuration, storage, tweets, (err, err_twitter)->
		console.log err if err
		console.log err_twitter if err_twitter
		setTimeout doDownload, configuration.pollInterval

doDownload()