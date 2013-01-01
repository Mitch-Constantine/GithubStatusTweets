root = exports ? this

exports.enable = (category)-> root.categories[category] = 1
exports.disable = (category)-> root.categories[category] = null

exports.log = (category, message, what)->
	if root.categories[category]
		console.log "[" + new Date() + " " + category + "]: "  + message
		console.log what 
		
root.categories = {}

exports.enable 'error'
exports.error = (err) -> exports.log 'error', '', err