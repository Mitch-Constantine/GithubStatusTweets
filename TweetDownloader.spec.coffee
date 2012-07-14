tweetDownloader = require('./TweetDownloader')

describe "Tweet downloader", ->
	it "Downloads all relevant tweets if no sinceId found in the database", ->
		mockTweets = [ { id: 12, text : 'First' }, { id: 2, text: 'Second' } ]

		mockConfiguration = { term: 'term' }

		mockStorage = {
			getNextSinceId : () ->,
			setNextSinceId : () ->,
			save : () ->
			configure: () ->	
		}
		spyOn(mockStorage, 'configure')
		spyOn(mockStorage, 'getNextSinceId').andCallFake( (callback)->callback(null, null) )
		spyOn(mockStorage, 'setNextSinceId').andCallFake( (nextSinceId, callback)->
			expect(nextSinceId).toBe(12)
			callback(null) )
		spyOn(mockStorage, 'save').andCallFake( (tweets, callback)->
			expect(tweets).toBe(mockTweets)
			callback(null) )
		
		mockTweeter = 
		{
			query : ()->
		}
		spyOn( mockTweeter, 'query').andCallFake( (term, limit, callback)->
				expect
				expect(term).toBe('term')
				expect(limit).toBe(null)
				callback(null, mockTweets)
				expect(mockStorage).toHaveBeenCalledWith(mockConfiguration)
			)
		tweetDownloader.download mockConfiguration, mockStorage, mockTweeter, ()->
			expect( mockStorage.getNextSinceId ).toHaveBeenCalled()
			expect( mockStorage.setNextSinceId ).toHaveBeenCalled()
			expect( mockStorage.save ).toHaveBeenCalled()

	it "Downloads all tweets since sinceId if sinceId found in the database", ->
		mockTweets = [ { id: 12, text : 'First' }, { id: 2, text: 'Second' } ]

		mockStorage = {
			getNextSinceId : () ->,
			setNextSinceId : () ->,
			save : () ->
			configure : () ->
			}
		mockConfiguration = { term: 'term' }
		spyOn(mockStorage, 'getNextSinceId').andCallFake( (callback)->callback(null, 33) )
		spyOn(mockStorage, 'setNextSinceId').andCallFake( (nextSinceId, callback)->
			expect(nextSinceId).toBe(12)
			callback(null) )
		spyOn(mockStorage, 'save').andCallFake( (tweets, callback)->
			expect(tweets).toBe(mockTweets)
			callback(null) )
		
		mockTweeter = 
		{
			query : ()->
		}
		spyOn( mockTweeter, 'query').andCallFake( (since_id, term, limit, callback)->
				expect(since_id).toBe(33)
				expect(term).toBe('term')
				expect(limit).toBe(null)
				callback(null, mockTweets)
				expect(mockStorage).toHaveBeenCalledWith(mockConfiguration)
			)
		tweetDownloader.download mockConfiguration, mockStorage, mockTweeter, ()->
			expect( mockStorage.getNextSinceId ).toHaveBeenCalled()
			expect( mockStorage.setNextSinceId ).toHaveBeenCalled()
			expect( mockStorage.save ).toHaveBeenCalled()
