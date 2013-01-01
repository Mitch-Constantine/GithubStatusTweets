tweetDownloader = require './TweetDownloader' 
dal = require './DAL'
twitterInterface = require './TwitterInterface'
logger = require './logger'

log = (message, what) -> logger.log 'downloadDaemon', message, what

configuration = require('./configuration').getConfiguration()

storage = new dal.Storage()
tweets = new twitterInterface.Twitter()

start = (next)->
	tweetDownloader.download configuration, storage, tweets, (err, err_twitter)->
		logger.error err if err
		logger.error err_twitter if err_twitter
		log 'twitter download processed', ''
		if next 
			next()
		else
			setTimeout start, configuration.pollInterval

exports.start = start	
start() if require.main == module 
