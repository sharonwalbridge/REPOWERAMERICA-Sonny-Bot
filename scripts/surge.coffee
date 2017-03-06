# Description:
#   Interacts with the Google Maps API.
#
# Commands:
#   hubot map <address> - Returns a satellite map view of the `address`.
# 	hubot quote <address> - Fires off a SURGE quote for `address`.

module.exports = (robot) ->

  robot.respond /((driving|walking|bike|biking|bicycling) )?directions from (.+) to (.+)/i, (msg) ->
    mode        = msg.match[2] || 'driving'
    origin      = msg.match[3]
    destination = msg.match[4]
    key         = process.env.HUBOT_GOOGLE_API_KEY

    if origin == destination
      return msg.send "Now you're just being silly."

    if !key
      msg.send "Please enter your Google API key in the environment variable HUBOT_GOOGLE_API_KEY."
    if mode == 'bike' or mode == 'biking'
      mode = 'bicycling'

    url         = "https://maps.googleapis.com/maps/api/directions/json"
    query       =
      mode:        mode
      key:         key
      origin:      origin
      destination: destination
      sensor:      false

    robot.http(url).query(query).get()((err, res, body) ->
      jsonBody = JSON.parse(body)
      route = jsonBody.routes[0]
      if !route
        msg.send "Error: No route found."
        return
      legs = route.legs[0]
      start = legs.start_address
      end = legs.end_address
      distance = legs.distance.text
      duration = legs.duration.text
      response = "Directions from #{start} to #{end}\n"
      response += "#{distance} - #{duration}\n\n"
      i = 1
      for step in legs.steps
        instructions = step.html_instructions.replace(/<div[^>]+>/g, ' - ')
        instructions = instructions.replace(/<[^>]+>/g, '')
        response += "#{i}. #{instructions} (#{step.distance.text})\n"
        i++

      msg.send "http://maps.googleapis.com/maps/api/staticmap?size=400x400&" +
               "path=weight:3%7Ccolor:red%7Cenc:#{route.overview_polyline.points}&sensor=false"
      msg.send response
    )

  robot.respond /quote (.+)/i, (msg) ->
    address			= msg.match[1]
    googleApiKey	= process.env.SONNY_GOOGLE_API_KEY
    googleUrl		= "https://maps.googleapis.com/maps/api/geocode/json"
    googleQuery 	=
      address:        address
      key:            googleApiKey
      sensor:         false
        
    ##if !googleApiKey
    ##  msg.send "Please enter your Google API key in the environment variable SONNY_GOOGLE_API_KEY."

    msg.send "Verifying, geocoding address using Google Maps API"
    robot.http(googleUrl).query(googleQuery).get() (err, res, body) ->
      googleJsonBody = JSON.parse(body)
      latitide = googleJsonBody.results.geometry.location.lat
      longitude = googleJsonBody.results.geometry.location.lng
      msg.send "Geocoding successful - Latitude #{latitude}"
      return
    
    msg.send "TEST #{latitude}"
    surgeUrl	= "https://dev-api.repoweramerica.io/quote"
    payload 	= JSON.stringify({
   		address: {
   			street: 		"353 Warren Drive",
   			city:			"San Francisco",
   			postalCode:		"94131",
   			stateCode:		"CA",
   			country:		"United States"
   		},
   		location: {
   			id:				null,
   			static:			null,
   			satellite:		null,
   			pixelsToMeters:	17,
   			orientation:	0,
   			returnPolygon:	true,
   			latitude:		37.755674793682495,
   			longitude:		-122.46153362698362
   		},
   		optimizeFor:		"default",
   		financeOptions:		[
   			"cash",
   			"loan",
   			"ppa"
   		]
   	})
   	
   	msg.send "Sending quote request for #{address}"
    robot.http(surgeUrl).header('Content-Type', 'application/json').header('Authorization', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6Im1nb2xpY2hlbmtvQHNvbGFydW5pdmVyc2UuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImlzcyI6Imh0dHBzOi8vcmVwb3dlci5hdXRoMC5jb20vIiwic3ViIjoiZ29vZ2xlLW9hdXRoMnwxMTM5MTUwMjE2MTI3NzExODEzNjYiLCJhdWQiOiJtSnVCZGRLS2NYemkwemkzcW15cUZQb0lKOUV6TzBDQyIsImV4cCI6MTQ4ODgzNDg1MiwiaWF0IjoxNDg4MjMwMDUyfQ.0hyPH5SRbjHFjKETQSXi0vx9rNPgJ355Nce4ROWAe9c').post(payload) (err, res, body) ->
      jsonBody = JSON.parse(body)
      quoteId = jsonBody.id
      if !quoteId
      	msg.send "Error:  Quote not created - #{body}"
      	return
      msg.send "Quote successfully created, ID: #{quoteId}"
      
    
  robot.respond /(?:(roadmap|terrain|hybrid)[- ])?map (.+)/i, (msg) ->
    mapType  = msg.match[1] or "satellite"
    location = encodeURIComponent(msg.match[2])
    mapUrl   = "http://maps.google.com/maps/api/staticmap?markers=" +
                location +
                "&size=400x400&maptype=" +
                mapType +
                "&sensor=false" +
                "&format=png" # So campfire knows it's an image

    msg.send mapUrl
