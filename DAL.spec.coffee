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

	it "Saves correct sequence numbers", ->
		dal = new DAL.Storage()
		dal.configure testConfiguration
		done = false
		runs ->
			async.waterfall( [
				(next)->dal.reset next,
				(next)->dal.save( { test: 5 }, next ),
				(next)->dal.save( { test: 6 }, next ),
				(next)->dal.getAll next,
				(data, next)->dal.close (err)->next(err,data)			
			],
			(err, data) -> 
				done = true
				expect(err).toBeFalsy()
				expect(data.length).toBe(2)
				expect(data[0].seqNumber).toBe(0)
				expect(data[1].seqNumber).toBe(1))
		waitsFor (->done), "tweet CRUD operation", 2000

	it "Can return a page worth of saved tweets", ->
		dal = new DAL.Storage()
		dal.configure testConfiguration
		done = false
		runs ->
			async.waterfall( [
				(next)->dal.reset next,
				(next)->dal.save( [{ text: 'x'}, {text:'x'}, {text:'x'}], next ),
				(next)->dal.save( [{ text: 'b'}, {text:'a'}], next ),
				(next)->dal.save( [{ text: 'd'}, {text:'c'}], next ),
				(next)->dal.getPage( 1, 2, next ),
				(data, next)->dal.close (err)->next(err,data)			
			],
			(err, data) -> 
				done = true
				expect(err).toBeFalsy()
				expect(data.length).toBe(2)
				expect(data[0].text).toBe('c')
				expect(data[1].text).toBe('b'))
		waitsFor (->done), "tweet CRUD operation", 2000

	it "Can return a page worth of saved tweets - relevant only", ->
		dal = new DAL.Storage()
		dal.configure testConfiguration
		done = false
		runs ->
			async.waterfall( [
				(next)->dal.reset next,
				(next)->dal.save( [
					{ text: 'x', deemedRelevant: true}, 
					{ text:'x'}, 
					{text:'x', deemedRelevant: true}], next ),
				(next)->dal.save( [
					{ text: 'b'}, 
					{text:'a', deemedRelevant: true}], next ),
				(next)->dal.save( [
					{ text: 'd'}, 
					{text:'c', deemedRelevant: true}], next ),
				(next)->dal.getPage( 1, 2, true, next ),
				(data, next)->dal.close (err)->next(err,data)			
			],
			(err, data) -> 
				done = true
				expect(err).toBeFalsy()
				expect(data.length).toBe(2)
				expect(data[0].text).toBe('a')
				expect(data[1].text).toBe('x'))
				
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
		
	it "Can set tweets as relevant", ->
		dal = new DAL.Storage()
		dal.configure testConfiguration
		done = false
		runs ->
			async.waterfall( [
				(next)->dal.reset next,
				(next)->dal.save( { id: 5 }, next ),
				(next)->dal.setRelevant( 5, 1, next ),
				(next)->dal.setRelevant( 5, 1, next ),
				(next)->dal.getAll next,
				(data, next)->
					dal.close (err)->next(err,data)			
			],
			(err, data) -> 
				done = true
				expect(err).toBeFalsy()
				expect(data[0].relevantCount).toBe(2))
		waitsFor (->done), "tweet CRUD operation", 2000
	
	it "Can set tweets as irelevant", ->
		dal = new DAL.Storage()
		dal.configure testConfiguration
		done = false
		runs ->
			async.waterfall( [
				(next)->dal.reset next,
				(next)->dal.save( { id: 5 }, next ),
				(next)->dal.setRelevant( 5, 0, next ),
				(next)->dal.setRelevant( 5, 0, next ),
				(next)->dal.getAll next,
				(data, next)->dal.close (err)->next(err,data)			
			],
			(err, data) -> 
				done = true
				expect(err).toBeFalsy()
				expect(data[0].irelevantCount).toBe(2))
		waitsFor (->done), "tweet CRUD operation", 2000

	it "Can set tweets as irrelevant", ->

xdescribe "Twitter access", ->
	
	done = false
	twitterDal = null		
	
	it "Retrieves less than a page of tweets with a given keyword", ->
		runs ->
			done = false
			twitterDal = new DAL.Twitter()
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
			twitterDal = new DAL.Twitter()
			async.waterfall [
				(next)->twitterDal.query "party", null, 200, next
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
				(next)->twitterDal.query "party", null, 5, next
				(data, next)->twitterDal.query_after data[3].id, "party", null, 
					200, (err, newData)->next(err, newData, data[3].created_at)
			],
			(err, data, date_limit)->
				done = true
				expect(err).toBeFalsy()
				expect(err).toBeFalsy()
		waitsFor (->done), "tweet searching after id", 20000
