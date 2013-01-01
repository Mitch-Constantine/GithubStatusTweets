async = require('async')
logger = require './logger'

log = (message, what) -> logger.log 'relevanceLogic', message, what

exports.RelevanceCalculator = class RelevanceCalculator 

	minOccurenceThreshold : 1
	relevanceThreshold : 0.7

	constructor : (dal, options)->
		options = options or {}
		@dal = dal
		@minOccurenceThreshold =  options.minOccurenceThreshold or @minOccurenceThreshold
		@relevanceThreshold = options.relevanceThreshold or @relevanceThreshold 
		
	createStatistics : (next)=>
		@statistics = {}
		@dal.eachTweet(
			(err, tweet) => 
				@addToStatistics tweet
			(err)=>
				log 'Statistics completed', @statistics
				next(err)
		)
	
	markRelevantTweets : (next)=>
		queue = async.queue(
			(task, callback) -> task(callback),
			5
		)
		errors = null
		@dal.eachTweet(
			(err, tweet)=> (
				unless err
					queue.push( 
						(callback)=> 
							@markTweet tweet, () -> callback()
						
					)
					log 'Queued ', tweet.id
					if queue.drain == null
						queue.drain = ()->
							next(errors)	
				else
					if err 
						errors = [] unless errors
						errors.push err			
			), 			
			-> 
				if queue.empty
					next(errors)
		)
		
	markTweet : (tweet, next) =>
		log 'Computing relevance for ' + tweet.id, tweet.text
		words = @wordsOf tweet
		relevance = @computeRelevance(words, @statistics)
		tweet.deemedRelevant = (relevance >= @relevanceThreshold)
		@dal.update {_id:tweet._id}, 
			{ $set : { deemedRelevant : tweet.deemedRelevant } },
			(err)-> 
				log 'Relevance of tweet ' + tweet.id, relevance
				log 'Deemed relevant for tweet ' + tweet.id, tweet.deemedRelevant
				next()
		
	computeRelevance : (words) =>
		pRelevant = 1
		pIrelevant = 1
		for word in words
			pWordRelevant = @relevanceOf word
			if pWordRelevant != null 
				pRelevant = pRelevant * pWordRelevant
				pIrelevant = pIrelevant * (1-pWordRelevant)
		relevance = if pRelevant == 0 and pIrelevant == 0 then 1 else (pRelevant/(pRelevant + pIrelevant))
		log 'word relevance for ', [words, relevance]
		relevance
		
	relevanceOf : (word)=>
		statistics = @statistics[word]
		if not statistics or statistics.relevantCount + statistics.irelevantCount < @minOccurenceThreshold
			log 'Word ' + word + ' is irrelevant', ''
			null
		else
			pRelevant = statistics.relevantCount / @statistics.totalRelevant
			pIrelevant = statistics.irelevantCount / @statistics.totalIrelevant
			relevance = (pRelevant/(pRelevant + pIrelevant))
			log 'Relevance of '+ word, statistics
			relevance
		
	addToStatistics : (tweet) =>
		words = @wordsOf tweet
		
		tweetRelevantCount = tweet.relevantCount or 0
		tweetIrelevantCount = tweet.irelevantCount or 0
		
		isRelevant = tweetRelevantCount > tweetIrelevantCount
		isIrelevant = tweetRelevantCount < tweetIrelevantCount
			
		if isRelevant
			@statistics.totalRelevant = (@statistics.totalRelevant or 0) + 1
		if isIrelevant
			@statistics.totalIrelevant = (@statistics.totalIrelevant or 0) + 1
		log 'total count', [@statistics.totalRelevant, @statistics.totalIrelevant]
			
		for word in words
			unless @statistics[word]
				@statistics[word] = {
					relevantCount : 0,
					irelevantCount : 0,
					totalCount : 0
				}
			wordStatistics = @statistics[word] 
			if isRelevant
				wordStatistics.relevantCount = wordStatistics.relevantCount + 1
			if isIrelevant
				wordStatistics.irelevantCount = wordStatistics.irelevantCount + 1
			if isRelevant or isIrelevant
				wordStatistics.totalCount = wordStatistics.totalCount+1
			log 'word statistics ' + word, wordStatistics 
	
	wordsOf : (tweet)=> @splitPhrase tweet.user.screen_name + " " + tweet.text
		
	splitPhrase : (phrase)=>
		parts = phrase.split(/[^A-Za-z0-9_]/)
		part.toLowerCase() for part in parts when part != ''
