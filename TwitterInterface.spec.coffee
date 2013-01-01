async = require('async')
Twit = require('twit')
TwitterInterface = require('./TwitterInterface')

describe "Twitter access", ->
	
	done = false
	twitterDal = null		
	
	it "Retrieves less than a page of tweets with a given keyword", ->
		runs ->
			done = false
			twitterDal = new TwitterInterface.Twitter()
			async.waterfall [
				(next)->twitterDal.query "party", null, 33, next 
			],
			(err, data)->
				done = true
				expect(err).toBeFalsy()
				expect( data.length ).toBe( 33 ) if data.length
		waitsFor (->done), "tweet searching - few", 20000
		
	it "Retrieves more than a page of tweets with a given keyword", ->
		runs ->
			done = false
			twitterDal = new TwitterInterface.Twitter()
			async.waterfall [
				(next)->twitterDal.query "party", null, 70, next
			],
			(err, data)->
				done = true
				expect(err).toBeFalsy()
				expect( data.length ).toBe( 70 ) if data.length
		waitsFor (->done), "tweet searching - many", 20000
		
	it "Retrieves tweets newer than a given id", ->
		runs ->
			done = false
			twitterDal = new TwitterInterface.Twitter()
			async.waterfall [
				(next)->twitterDal.query "party", null, 5, next
				(data, next)->
					twitterDal.query_after data[3].id, "party", null, 
					70, (err, newData)->next(err, newData, data[3].created_at)
			],
			(err, data, date_limit)->
				done = true
				expect(err).toBeFalsy()
				expect(err).toBeFalsy()
		waitsFor (->done), "tweet searching after id", 20000
