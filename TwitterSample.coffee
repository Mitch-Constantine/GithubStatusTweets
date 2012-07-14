Twit = require('twit')

T = new Twit {
    consumer_key:         'ILqKkqOZsNWLvSKiw1QSw'
  , consumer_secret:      'XtgOiG4R3mBQYeeUdDtCUNmbiWc8lgrrTaEHdRvMIsY'
  , access_token:         '590361240-PE92HYQYkODoX8wqIxWB5REk5rWJVFtI6RaOihBn'
  , access_token_secret:  'ZjRjSC5ZmOoIlRN295BKTCzXvQlFLWZl9SoLYuuMUE'
}

T.get 'search', { q: 'party' }, (err, reply)->
  console.log reply
  console.log err

