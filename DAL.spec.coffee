mongo = require('mongodb')
async = require('async')

DAL = require('./DAL')

testConfiguration = {
	host: 'localhost'
	port: 27017
	databaseName: 'test'
	tweetCollectionName: 'tweetsTest'
	sinceIdCollectionName: 'sinceIdTest'
}

describe "Data access layer", ->
	it "Can retrieve the tweets just saved", ->
		dal = new DAL.Storage()
		dal.configure testConfiguration
		done = false
		runs ->
			async.waterfall( [
				(next)->dal.reset next,
				(next)->dal.save( { test: 5 }, next ),
				(next)->dal.getAll next,
				(data, next)->dal.close (err)->next(err,data)			
			],
			(err, data) -> 
				done = true
				expect(err).toBeFalsy()
				expect(data.length).toBe(1)
				expect(data[0].test).toBe(5))
		waitsFor (->done), "tweet CRUD operation", 2000
	it "Can save and retrieve the latest since_id", ->
		dal = new DAL.Storage()
		dal.configure testConfiguration
		done = false
		runs ->
			async.waterfall [
				(next)->dal.reset next,
				(next)->dal.setNextSinceId( 12, next ),
				(next)->dal.getNextSinceId next,
				(sinceId, next)->dal.close (err)->next(err,sinceId)			
			],
			(err, sinceId) -> 
				done = true
				expect(err).toBeFalsy()
				expect(sinceId).toBe(12)
		waitsFor (->done), "tweet CRUD operation", 2000
		

describe "Twitter access", ->
	
	done = false
	twitterDal = null		
	
	it "Retrieves less than a page of tweets with a given keyword", ->
		runs ->
			done = false
			twitterDal = new DAL.Twitter()
			async.waterfall [
				(next)->twitterDal.query "party", 33, next 
			],
			(err, data)->
				done = true
				expect(err).toBeFalsy()
				expect( data.length ).toBe( 33 ) if data.length
		waitsFor (->done), "tweet searching - few", 20000
		
	it "Retrieves more than a page of tweets with a given keyword", ->
		runs ->
			done = false
			twitterDal = new DAL.Twitter()
			async.waterfall [
				(next)->twitterDal.query "party", 200, next
			],
			(err, data)->
				done = true
				expect(err).toBeFalsy()
				expect( data.length ).toBe( 200 ) if data.length
		waitsFor (->done), "tweet searching - many", 20000
		
	it "Retrieves tweets newer than a given id", ->
		runs ->
			done = false
			twitterDal = new DAL.Twitter()
			async.waterfall [
				(next)->twitterDal.query "party", 5, next
				(data, next)->twitterDal.query_after data[3].id, "party", 
					200, (err, newData)->next(err, newData, data[3].created_at)
			],
			(err, data, date_limit)->
				done = true
				expect(err).toBeFalsy()
				expect(err).toBeFalsy()
		waitsFor (->done), "tweet searching after id", 20000
