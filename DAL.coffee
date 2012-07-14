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
		
	save : (item, callback) -> 
		async.waterfall [
			(next)=> @connect next,
			(next)=> @tweetCollection.insert item, {safe: true}, (err)=>next(err)
			],
			callback
				
	getAll : (callback)->
		async.waterfall [
			(next)=> @connect next,
			(next) => @tweetCollection.find().toArray next
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

	close: (callback)=>	@db.close true, (err)->callback(err)
			
	connect: (callback)=>
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
				(err, sinceIdCollection)->next(err, tweetCollection, sinceIdCollection)
		],
		(err, tweetCollection, sinceIdCollection) =>
			@tweetCollection = tweetCollection
			@sinceIdCollection = sinceIdCollection
			callback(err)
	
queries = 5

exports.Twitter = class root.Twitter

	rpp : 100
	T : null

	query: (term, limit, callback) => 
		@accumulate_results null, null, [], term, limit, callback		
	
	query_after: (since_id, term, limit, callback) => 
		@accumulate_results null, since_id, [], term, limit, callback		
	
	accumulate_results: (max_id, since_id, already_found, term, limit, callback)=>
	
		params = { q: term, rpp:@rpp }
		params.since_id = since_id if since_id
		params.max_id = max_id if max_id
			
		@T = new Twit {
			consumer_key:         'ILqKkqOZsNWLvSKiw1QSw'
		  , consumer_secret:      'XtgOiG4R3mBQYeeUdDtCUNmbiWc8lgrrTaEHdRvMIsY'
		  , access_token:         '590361240-PE92HYQYkODoX8wqIxWB5REk5rWJVFtI6RaOihBn'
		  , access_token_secret:  'ZjRjSC5ZmOoIlRN295BKTCzXvQlFLWZl9SoLYuuMUE'
		} unless @T
		
		@T.get 'search', params, (err, reply)=> 
			
			if err
				callback(err, null)
				return			
		
			data_found = reply.results ? []			
			already_found = already_found.concat data_found
			
			if data_found.length == 0 or (limit and limit < already_found.length)
				data_to_return = if limit then  already_found[0..limit-1] else already_found
				callback( null, data_to_return)
				return

			max_id = data_found[data_found.length-1].id
			@accumulate_results max_id, since_id, already_found, term, limit, callback
