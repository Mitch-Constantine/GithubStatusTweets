start = 0
pageSize = 20
userMode = 0

showTweets = ->
	$("#previous").hide() if start == 0
	$("#previous").show() if start != 0
	url = sprintf("tweets?start=%d&count=%d&relevantOnly=%d", 
				  start, pageSize, userMode)
				  
	pageNo = (start/pageSize)+1
	$("#pageNumber").text("Page " + pageNo )
				   
	$.getJSON url, (tweets) -> 
		$("#tweets").html("")
		for tweet in tweets
			appendHtml tweet, (html)-> $("#tweets").append $(html)
		if userMode == 1
			hideButtons()
			
appendHtml = (tweet, insertInTree)->
	tweet.relevantCount = tweet.relevantCount or 0
	tweet.irelevantCount = tweet.irelevantCount or 0
	tweet.deemedRelevantText =
		if tweet.deemedRelevant == true then "relevant"
		else if tweet.deemedRelevant == false then "irelevant"
		else "(unknown)"

	template_text = $("#tweet_template").html()
	html = _.template template_text, tweet

	divId = "tweet" + tweet.id
	newDiv = insertInTree($(html).attr("id", divId))
	$("#"+divId).find(".relevantButton").click -> setRelevance tweet.id, 1	
	$("#"+divId).find(".irelevantButton").click -> setRelevance tweet.id, 0

hideButtons = -> 
	$(".adminOnly").hide()

setRelevance = (tweetId, isRelevant) ->
	$.post( "/setRelevance", 
		{ id : tweetId, isRelevant: isRelevant },
		(reply) ->
			if reply.err 
				alert err
			else
				appendHtml reply.data[0], (html)->
					$("#tweet"+tweetId).replaceWith(html)
	)
		
$(document).ready ->
	
	txtUserMode = $("#relevantOnly").val()
	userMode = parseInt( txtUserMode )

	showTweets()
			
	$("#next").click -> 
		start = start + pageSize
		showTweets()
	$("#previous").click -> 
		start = start - pageSize
		showTweets()