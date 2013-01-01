async = require('async')
Twit = require('twit')
logger = require('./logger')

root = exports ? this

log = (message, what)->logger.log 'twitter', message, what
logProgress = (message, what)-> logger.log 'twitterProgress', message, what

exports.Twitter = class root.Twitter

	rpp : 100
	T : null

	query: (term, location, limit, callback) => 
		log 'query', [term, location, limit, callback]
		@accumulate_results null, null, [], term, location, limit, callback		
	
	query_after: (since_id, term, location, limit, callback) =>
		log 'query_after', [since_id, term, location, limit, callback] 
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
		
		@T.get 'search/tweets', params, (err, reply)=> 
		
			log "twitter reply", [err,reply]							
			data_found = if reply and reply.statuses then reply.statuses else []
			data_found = (tweet for tweet in data_found when tweet.id != since_id and tweet.id != max_id)		
			already_found = already_found.concat data_found
			
			if data_found.length == 0 or (limit and limit < already_found.length)
				data_to_return = if limit then  already_found[0..limit-1] else already_found
				log 'twitter - data ', data_to_return
				logProgress 'Retrieved ' + data_to_return.length
				callback( null, data_to_return)
				return

			max_id = data_found[data_found.length-1].id
			if not err
				@accumulate_results max_id, since_id, already_found, term, location, limit, callback
			else
				log 'twitter - error', err
				callback(err, data_to_return)