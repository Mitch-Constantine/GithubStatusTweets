mongo = require('mongodb')
async = require('async')
logger = require('./logger')

Server = mongo.Server
Db = mongo.Db

root = exports ? this
log = (message, what)->logger.log 'database', message, what

exports.Storage = class root.Storage
	
	configure : (configuration) => 
		log 'configuration', configuration
		@host = configuration.mongo.hostname
		@port = configuration.mongo.port
		@username = configuration.mongo.username
		@password = configuration.mongo.password
		@databaseName = configuration.mongo.db
		@url = configuration.mongo.url
		@tweetCollectionName = configuration.tweetCollectionName
		@sinceIdCollectionName = configuration.sinceIdCollectionName 
	
	reset : (callback)-> 
			log 'reset', ''
			async.waterfall [
				(next)=> @connect next,
				(next) => @db.executeDbCommand {drop:@tweetCollectionName}, (err)->next(err),
				(next) => @db.executeDbCommand {drop:@sinceIdCollectionName}, (err)->next(err)
			],
			callback
		
	save : (data, callback) ->
		log 'save', data
		async.waterfall [
			(next)=> @connect next,
			(next)=> @getNextSeqNumber next,
			(nextId, next)=> 
				@assignSeqNumber nextId, data
				@insert_each data, next
			],
			callback
	
	insert_each : (data, callback) =>
		async.forEach data,
			(item, next) => 
				if item.id != undefined 
					@tweetCollection.update {id: item.id}, item, 
						{safe:true, upsert:true}, (err)->next(err)
				else # this code is test-only
					next()
			callback
				
	update : (condition, change, callback) ->
		log 'update', [condition, change]
		async.waterfall [
			(next)=> @connect next,
			(next)=> @tweetCollection.update condition, change,  
				{safe:true}, (err)->next(err)
			],
			callback				
	
	setRelevant : (id, isRelevant, callback) ->
		log 'setRelevant', [id, isRelevant]
		async.waterfall [
			(next)=> @connect next,
			(next)=> @getById id, next
			(arr, next)=>
				obj = null
				if arr.length == 1
					obj = arr[0]
				if obj
					field = "irelevantCount"
					if isRelevant == 1
						field = "relevantCount"
					oldCount = 0
					if (obj[field])
						oldCount = obj[field]
					obj[field] = oldCount + 1
					@tweetCollection.save obj, next
				else
					next("Missing id:" + id)
			],
			callback

	getById : (id, callback)->
		log 'getById', id
		async.waterfall [
			(next)=> @connect next,
			(next) => @tweetCollection.find({id : id}).toArray next
		],
		(err, data)->
			log 'getById', data
			callback(err, data)

	getAll : (callback)->
		log 'getAll', ''
		async.waterfall [
			(next)=> @connect next,
			(next) => @tweetCollection.find().toArray next
		],
		(err, data)->
			log 'getAll', data
			callback(err, data)
			
	eachTweet : (forEachElement, atEnd) =>
		logger.log 'database', 'eachTweet'
		@connect (err, data)=>
			unless err
				cursor = @tweetCollection.find()
				cursor.each (err, item)=> 
					unless err
						if item 
							log 'eachTweet - processing', [err, item]
							forEachElement err, item
						else
							log 'eachTweet - done', err
							cursor.close()	
							atEnd err
							
	getPage : (start, pageSize, otherParams...)->
		log 'getPage', [start, pageSize, otherParams]
		
		relevantOnly = otherParams.length == 2 && otherParams[0]
		callback = otherParams[otherParams.length-1]
		
		searchParameters = 
			(if relevantOnly 
				{ $where : "this.deemedRelevant || " +
				 "( (this.relevantCount || 0) > (this.irelevantCount ||0) )"
				} 
			else 
				{})
		log 'getPage', searchParameters
		
		async.waterfall [
			(next)=> @connect next,
			(next) => @tweetCollection.find(searchParameters)
				.sort({seqNumber:-1})
				.skip(start)
				.limit(pageSize)
				.toArray next
		],
		(err, data) -> 
			log 'getPage', data
			callback(err, data)

	setNextSinceId : (id, callback) =>
		log 'setNextSinceId', id
		async.waterfall [
			(next)=> @connect next,
			(next)=> @sinceIdCollection.update {}, {sinceId : id}, 
				{safe:true, upsert:true}, (err)->next(err)
		],
		callback
		
	getNextSinceId : (callback) =>
		log 'getNextSinceId'
		async.waterfall [
			(next)=> @connect next,
			(next)=> @sinceIdCollection.findOne (err,data)->
				next(err, if data then data.sinceId else null) 
		],
		(err, data) ->
			log 'getNextSinceId', [err, data]
			callback err, data	

	getNextSeqNumber : (callback) =>
		log 'getNextSeqNumber'
		lastTweet = null
		@tweetCollection.find().sort({seqNumber:-1}).limit(1).toArray (err,data)->
			log 'getNextSeqNumber', [err, data]
			if err or data == null or data.length == 0 
				callback(err, 0)
				return
			callback(err, data[0].seqNumber+1)

	close: (callback)=>	@db.close true, (err)->callback(err)	
			
	connect : (callback)=>
		if @db
			callback(null) 		
			return
				
		async.waterfall [		
			(next)=>
				mongo.connect @getDatabaseUrl(), 
							  [@tweetCollectionName, @sinceIdCollectionName], next
			(db, next)=>
				@db = db
				@db.createCollection @tweetCollectionName, 
					(err, tweetCollection)->next(err,tweetCollection)
			(tweetCollection, next)=>@db.createCollection @sinceIdCollectionName, 
				(err, sinceIdCollection)->next(err, tweetCollection, sinceIdCollection),
		],
		(err, tweetCollection, sinceIdCollection) =>
			@tweetCollection = tweetCollection
			@sinceIdCollection = sinceIdCollection
			callback(err)
			
	getDatabaseUrl : () => 
		if @url 
			url = @url
		else if @username and @password
			url = "mongodb://" + @username + ":" + @password + "@" + @host + ":" + @port + "/" + @databaseName
		else
			url = "mongodb://" + @host + ":" + @port + "/" + @databaseName
		log 'getDatabaseUrl', url
		url
		
	assignSeqNumber: (startNumber, data) =>
		unless data.length
			@assignSeqNumber startNumber, [data]
			return
		seqNumber = startNumber + data.length-1
		for element in data
			element.seqNumber = seqNumber
			seqNumber = seqNumber-1

