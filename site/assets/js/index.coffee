start = 0
pageSize = 20
userMode = 0

showTweets = ->
	$("#previous").hide() if start == 0
	$("#previous").show() if start != 0
	url = sprintf("tweets?start=%d&count=%d&relevantOnly=%d", 
				  start, pageSize, userMode) 
	$.getJSON url, (tweets) -> 
		$("#tweets").html("")
		for tweet in tweets
			template_text = $("#tweet_template").html()
			html = _.template template_text, tweet
			$("#tweets").append html
			newDiv = $("#tweets").find(".tweetDisplay").last()
			do ->
				tweetId = tweet.id
				newDiv.find(".relevantButton").click -> setRelevance tweetId, 1	
				newDiv.find(".irelevantButton").click -> setRelevance tweetId, 0

hideButtons = -> 
	$(".relevantButton").hide()
	$(".irelevantButton").hide()	

setRelevance = (tweetId, isRelevant) ->
	$.post( "/setRelevance", 
		{ id : tweetId, isRelevant: isRelevant },
		() -> 
			relevance = if (isRelevant == 1) then "relevant" else "irelevant"
			alert( "Tweet marked as " + relevance))
		
$(document).ready ->
	
	txtUserMode = $("#relevantOnly").val()
	userMode = parseInt( txtUserMode )

	showTweets()
	
	if userMode == 1
		hideButtons()
		
	$("#next").click -> 
		start = start + pageSize
		showTweets()
	$("#previous").click -> 
		start = start - pageSize
		showTweets()