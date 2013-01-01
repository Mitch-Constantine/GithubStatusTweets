exports.getConfiguration = ()-> {
	pollInterval : 60000
	term : "401 OR 400 OR 403 OR 407 OR QEW OR DVP OR \"Queen Elizabeth Way\" OR \"Don Valley Parkway\"",
	location: "43.716589,-79.340686,20mi"
	mongo : nodeJitsuCredentials() or appFogMongoCredentials() or {
		hostname: 'localhost'
		port: 27017
		db: 'test'
	}
	tweetCollectionName: 'tweets'
	sinceIdCollectionName: 'sinceId'
	webPort : process.env.VMC_APP_PORT or 3000
}

nodeJitsuCredentials = ()->
	if process.env.MONGO_URL
		{ url : process.env.MONGO_URL }
	else
		null

appFogMongoCredentials = ()->
	if process.env.VCAP_SERVICES
		env = JSON.parse(process.env.VCAP_SERVICES)
		env['mongodb-1.8'][0]['credentials']
	else
		null