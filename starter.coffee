updateDaemon = require './UpdateDaemon'
downloadDaemon = require './DownloadDaemon'
site = require './site/app'
async = require 'async'
logger = require './logger'

logger.enable 'daemonRuns'
log = (category, what) -> logger.log 'daemonRuns', category, what

configuration = require('./configuration').getConfiguration()
runDaemons = ()->
	async.waterfall [
		(next)->
			log 'Starting download', ''
			downloadDaemon.start next
		(next)->
			log 'Starting database update'
			updateDaemon.start next
	], ()->
		log 'Database update done'
		setTimeout runDaemons,configuration.pollInterval
		
site.start()
runDaemons()