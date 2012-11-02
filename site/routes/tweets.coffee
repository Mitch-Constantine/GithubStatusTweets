console.log "Loading tweets"
exports.tweets = (req, res)->
	storage.getPage req.query["start"], req.query["count"], (err, data)->
		res.send JSON.stringify( err ? data )
	