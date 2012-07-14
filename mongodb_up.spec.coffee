mongo = require('mongodb')
async = require('async')

Server = mongo.Server
Db = mongo.Db

describe "mongodb operation", ->

	server = null
	db = null
	
	beforeEach ->
			server = new Server('localhost', 27017, {auto_reconnect: true})
			db = new Db('exampleDb', server)		

	it "connects to local database as per sample", ->

		done = null
		runs -> 
			async.waterfall [
				(cb)-> db.open (err)->cb err,
				(cb)-> db.close true, (err)->cb err,
				],
				(err)-> 
					done = true
					expect(err).toBeFalsy() 
		waitsFor (->done), "connection test", 1000

	it "retrieves things as they were sent", ->

		done = null
		runs -> 
			async.waterfall [
				(cb)-> db.open (err)-> cb err ,
				(cb)-> db.collection "abc", (err, collection)->cb(err, collection),
				(collection, cb)-> collection.insert {x:5}, {safe:true}, (err) -> cb(err, collection),
				((collection, cb)-> collection.findOne {x:5}, (err, found) ->
					expect(found.x).toBe(5)
					cb(err)),
				(cb)-> db.close true, (err)->cb err
				],
				(err)-> 
					done = true
					expect(err).toBeFalsy() 
		waitsFor (->done), "Find things sent", 1000
