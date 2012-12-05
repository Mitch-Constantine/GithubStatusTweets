async = require('async')

exports.createStatistics = (dal,next)->
	statistics = {}
	dal.eachTweet(
		(err, tweet) -> addToStatistics(statistics, tweet)
		(err)->
			next(err,statistics)
	)
	
exports.markRelevantTweets = (dal, wordStatistics, next)->
	queue = async.queue(
		(task, callback) -> task(callback),
		5
	)
	dal.eachTweet(
		(err, tweet)-> (
			unless err
				queue.push( 
					(callback)-> 
						markTweet dal, tweet, wordStatistics, () -> callback()
					
				)
				if queue.drain == null
					queue.drain = ()->
						next()	
			else
				console.log err		
		), 			
		-> 
			if queue.empty
				next()
	)
	
# Wait till everything done
relevanceThreshold = 0.7
markTweet = (dal, tweet, wordStatistics, next) ->
	words = wordsOf(tweet)
	relevance = computeRelevance(words, wordStatistics)
	tweet.deemedRelevant = (relevance >= relevanceThreshold)
	dal.update {_id:tweet._id}, 
		{ $set : { deemedRelevant : tweet.deemedRelevant } },
		(err)-> next()
	
computeRelevance = (words, wordStatistics) ->
	pRelevant = 1
	pIrelevant = 1
	for word in words
		pWordRelevant = relevanceOf( wordStatistics, word )
		if pWordRelevant != null 
			pRelevant = pRelevant * pWordRelevant
			pIrelevant = pIrelevant * (1-pWordRelevant)
	if pRelevant == 0 and pIrelevant == 0 then 1 
	else (pRelevant/(pRelevant + pIrelevant))
	
minOccurenceThreshold = 1
relevanceOf = (wordStatistics, word)->
	statistics = wordStatistics[word]
	if not statistics or statistics.relevantCount + statistics.irelevantCount < minOccurenceThreshold
		null
	else
		pRelevant = statistics.relevantCount / wordStatistics.totalRelevant
		pIrelevant = statistics.irelevantCount / wordStatistics.totalIrelevant
		(pRelevant/(pRelevant + pIrelevant))

addToStatistics = (statistics, tweet) ->
	words = wordsOf(tweet)
	
	tweetRelevantCount = tweet.relevantCount or 0
	tweetIrelevantCount = tweet.irelevantCount or 0
	
	isRelevant = tweetRelevantCount > tweetIrelevantCount
	isIrelevant = tweetRelevantCount < tweetIrelevantCount
		
	if isRelevant
		statistics.totalRelevant = (statistics.totalRelevant or 0) + 1
	if isIrelevant
		statistics.totalIrelevant = (statistics.totalIrelevant or 0) + 1
		
	for word in words
		unless statistics[word]
			statistics[word] = {
				relevantCount : 0,
				irelevantCount : 0,
				totalCount : 0
			}
		wordStatistics = statistics[word] 
		if isRelevant
			wordStatistics.relevantCount = wordStatistics.relevantCount + 1
		if isIrelevant
			wordStatistics.irelevantCount = wordStatistics.irelevantCount + 1
		if isRelevant or isIrelevant
			wordStatistics.totalCount = wordStatistics.totalCount+1 

wordsOf = (tweet)-> splitPhrase(tweet.user.screen_name + " " + tweet.text)
	
splitPhrase = (phrase)->
	parts = phrase.split(/[^A-Za-z0-9_]/)
	part.toLowerCase() for part in parts when part != ''
