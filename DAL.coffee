mongo = require('mongodb')
async = require('async')
Twit = require('twit')

Server = mongo.Server
Db = mongo.Db

root = exports ? this

exports.Storage = class root.Storage
	
	host: null
	port: null
	databaseName: null
	tweetCollectionName: null
	sinceIdCollectionName: null
	
	server : null
	db : null
	tweetCollection : null
	sinceIdCollection : null
	
	configure : (configuration) => 
		@host = configuration.host
		@port = configuration.port
		@databaseName = configuration.databaseName
		@tweetCollectionName = configuration.tweetCollectionName
		@sinceIdCollectionName = configuration.sinceIdCollectionName 
	
	reset : (callback)-> async.waterfall [
			(next)=> @connect next,
			(next) => @db.executeDbCommand {drop:@tweetCollectionName}, (err)->next(err),
			(next) => @db.executeDbCommand {drop:@sinceIdCollectionName}, (err)->next(err)
			],
			callback
		
	save : (data, callback) ->
		async.waterfall [
			(next)=> @connect next,
			(next)=> @getNextSeqNumber next,
			(nextId, next)=> 
				@assignSeqNumber nextId, data
				@tweetCollection.insert data, {safe: true}, (err)=>next(err)
			],
			callback
				
	update : (condition, change, callback) ->
		console.log condition
		console.log change
		async.waterfall [
			(next)=> @connect next,
			(next)=> @tweetCollection.update condition, change,  
				{safe:true}, (err)->next(err)
			],
			callback				
	
	setRelevant : (id, isRelevant, callback) ->
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
		async.waterfall [
			(next)=> @connect next,
			(next) => @tweetCollection.find({id : id}).toArray next
		],
		(err, data)->
			callback(err, data)

	getAll : (callback)->
		async.waterfall [
			(next)=> @connect next,
			(next) => @tweetCollection.find().toArray next
		],
		(err, data)->
			callback(err, data)
			
	eachTweet : (forEachElement, atEnd) =>
		@connect (err, data)=>
			unless err
				cursor = @tweetCollection.find()
				cursor.each (err, item)=> 
					unless err
						if item 
							forEachElement err, item
						else
							cursor.close()	
							atEnd err
							
	getPage : (start, pageSize, otherParams...)->
		relevantOnly = otherParams.length == 2 && otherParams[0]
		callback = otherParams[otherParams.length-1]
		
		searchParameters = 
			(if relevantOnly 
				{ deemedRelevant : true } 
			else 
				{})
		
		async.waterfall [
			(next)=> @connect next,
			(next) => @tweetCollection.find(searchParameters)
				.sort({seqNumber:-1})
				.skip(start)
				.limit(pageSize)
				.toArray next
		],
		callback

	setNextSinceId : (id, callback) =>
		async.waterfall [
			(next)=> @connect next,
			(next)=> @sinceIdCollection.update {}, {sinceId : id}, 
				{safe:true, upsert:true}, (err)->next(err)
		],
		callback
		
	getNextSinceId : (callback) =>
		async.waterfall [
			(next)=> @connect next,
			(next)=> @sinceIdCollection.findOne (err,data)->
				next(err, if data then data.sinceId else null) 
		],
		callback	

	getNextSeqNumber : (callback) =>
		lastTweet = null
		@tweetCollection.find().sort({seqNumber:-1}).limit(1).toArray (err,data)->
			if err or data == null or data.length == 0 
				callback(err, 0)
				return
			callback(err, data[0].seqNumber+1)

	close: (callback)=>	@db.close true, (err)->callback(err)	
			
	connect : (callback)=>
		if @server
			callback(null) 		
			return
		@server = new Server(@host, @port, {auto_reconnect: true})
		@db = new Db(@databaseName, @server)
		async.waterfall [		
			(next)=>@db.open (err)->next err
			(next)=>@db.createCollection @tweetCollectionName, 
				(err, tweetCollection)->next(err,tweetCollection)
			(tweetCollection, next)=>@db.createCollection @sinceIdCollectionName, 
				(err, sinceIdCollection)->next(err, tweetCollection, sinceIdCollection),
		],
		(err, tweetCollection, sinceIdCollection) =>
			@tweetCollection = tweetCollection
			@sinceIdCollection = sinceIdCollection
			callback(err)

	assignSeqNumber: (startNumber, data) =>
		unless data.length
			@assignSeqNumber startNumber, [data]
			return
		seqNumber = startNumber + data.length-1
		for element in data
			element.seqNumber = seqNumber
			seqNumber = seqNumber-1

exports.Twitter = class root.Twitter

	rpp : 100
	T : null

	query: (term, location, limit, callback) => 
		@accumulate_results null, null, [], term, location, limit, callback		
	
	query_after: (since_id, term, location, limit, callback) => 
		@accumulate_results null, since_id, [], term, location, limit, callback		
	
	accumulate_results: (max_id, since_id, already_found, term, location, limit, callback)=>
	
		params = { q: term, rpp:@rpp, result_type: 'recent' }
		params.since_id = since_id if since_id
		params.max_id = max_id if max_id
		params.geocode = location if location
		
		@T = new Twit {
			consumer_key:         'ILqKkqOZsNWLvSKiw1QSw'
		  , consumer_secret:      'XtgOiG4R3mBQYeeUdDtCUNmbiWc8lgrrTaEHdRvMIsY'
		  , access_token:         '590361240-PE92HYQYkODoX8wqIxWB5REk5rWJVFtI6RaOihBn'
		  , access_token_secret:  'ZjRjSC5ZmOoIlRN295BKTCzXvQlFLWZl9SoLYuuMUE'
		} unless @T
		
		@T.get 'search', params, (err, reply)=> 
			
			data_found = if reply and reply.results then reply.results else []
			data_found = (tweet for tweet in data_found when tweet.id != since_id and tweet.id != max_id)		
			already_found = already_found.concat data_found
			
			if data_found.length == 0 or (limit and limit < already_found.length)
				data_to_return = if limit then  already_found[0..limit-1] else already_found
				callback( null, data_to_return)
				return

			max_id = data_found[data_found.length-1].id
			if not err
				@accumulate_results max_id, since_id, already_found, term, location, limit, callback
			else
				callback(err, data_to_return)