async = require('async')

relevanceLogic = require('./relevanceLogic')
DAL = require('./DAL')

testConfiguration = {
	host: 'localhost'
	port: 27017
	databaseName: 'test'
	tweetCollectionName: 'tweetsTest'
	sinceIdCollectionName: 'sinceIdTest'
}

describe "Finding relevant and irelevant tweets", ->

	it "Counts relevant and irelevant tweets per word", ->
		done = false
		dal = new DAL.Storage()
		dal.configure testConfiguration
		runs ->
			async.waterfall( [
				(next)->dal.reset next,
				(next)->dal.save( 
					{ text: "Relevantone, relevantTwo??", user : {screen_name:""}, relevantCount:4 }, 
					next ),
				(next)->dal.save( 
					{ text: "relevantone!", user : {screen_name:"RelevantThree"}, relevantCount : 9}, 
					next ),
				(next)->dal.save( 
					{ text: "irelevantone, irelevantTwo??", user : {screen_name:""}, irelevantCount : 3 }, 
					next ),
				(next)->dal.save( 
					{ text: "iRelevantone, ??", user : {screen_name:"irelevant_Three"}, irelevantCount : 3 }, next ),
				(next)->relevanceLogic.createStatistics dal, next,
				(data, next)->dal.close (err)->next(err,data)			
			],
			(err, wordStatistics) -> 

				done = true
				expect(err).toBeFalsy()		
			
				expect(wordStatistics["relevantone"].relevantCount).toBe(2)
				expect(wordStatistics["relevanttwo"].relevantCount).toBe(1)
				expect(wordStatistics["relevantthree"].relevantCount).toBe(1)
				
				expect(wordStatistics["relevantone"].irelevantCount).toBe(0)
				expect(wordStatistics["relevanttwo"].irelevantCount).toBe(0)
				expect(wordStatistics["relevantthree"].irelevantCount).toBe(0)
			
				expect(wordStatistics["irelevantone"].irelevantCount).toBe(2)
				expect(wordStatistics["irelevanttwo"].irelevantCount).toBe(1)
				expect(wordStatistics["irelevant_three"].irelevantCount).toBe(1)
			
				expect(wordStatistics["irelevantone"].relevantCount).toBe(0)
				expect(wordStatistics["irelevanttwo"].relevantCount).toBe(0)
				expect(wordStatistics["irelevant_three"].relevantCount).toBe(0)
			
			
				expect(wordStatistics["relevantone"].totalCount).toBe(2)
				expect(wordStatistics["relevanttwo"].totalCount).toBe(1)
				expect(wordStatistics["relevantthree"].totalCount).toBe(1)
			
				expect(wordStatistics["irelevantone"].totalCount).toBe(2)
				expect(wordStatistics["irelevanttwo"].totalCount).toBe(1)
				expect(wordStatistics["irelevant_three"].totalCount).toBe(1))
				
		waitsFor (->done), "Statistics creation", 2000

	it "Marks tweets relevant and irelevant based on count of relevance per word", ->		
		done = false
		dal = new DAL.Storage()
		dal.configure testConfiguration
		wordStatistics = {
			"w1" : {
				relevantCount : 3
				irelevantCount : 0
				totalCount : 3
			},
			"w2" : {
				relevantCount : 5
				irelevantCount : 0
				totalCount : 5
			}
			"w3" : {
				relevantCount : 0
				irelevantCount : 5
				totalCount : 5
			}
			totalRelevant : 2
			totalIrelevant : 1
		}
		phrase1 = "w1 W2!!! filler xx nnn"
		phrase2 = "yadda yadda yadda"
		phrase3 = "w3"
		text3 = "wugga wugga wugga"
		
		runs ->
			async.waterfall( [
				(next)->dal.reset next,
				(next)->dal.save( 
					{ text: phrase1, user : {screen_name :"" }, relevantCount:4 }, 
					next ),
				(next)->dal.save( 
					{ text: phrase2, user : {screen_name:"" }, relevantCount : 9}, 
					next ),
				(next)->dal.save( 
					{ text: text3, user : {screen_name:phrase3}, irelevantCount : 3 }, 
					next ),
				(next)->relevanceLogic.markRelevantTweets dal, wordStatistics, next
				(next)->dal.getAll next,
				(data, next)->dal.close (err)->next(err,data)			
			],
			(err, tweets) -> 
				done = true
				expect(err).toBeFalsy()
				expect(tweets.length).toBe(3)
				for tweet in tweets
					text = tweet.text
					expect( text == phrase1 || text == phrase2 || text == text3 )
						.toBeTruthy("Unknown tweet:" + text)
					if tweet.text == phrase1						
						expect( tweet.deemedRelevant ).toBeTruthy("Tweet 1 expected relevant")
					else if tweet.text == phrase2
						expect( tweet.deemedRelevant ).toBeFalsy("Tweet 2 expected irrelevant")
					else if tweet.user.screen_name == phrase3
						expect( tweet.deemedRelevant).toBeFalsy("Tweet 3 expected irrelevant")
			)
		
		waitsFor (->done), "Statistics creation", 2000
