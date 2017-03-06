# Description:
#   Interacts with the Google Maps API.
#
# Commands:
#   hubot map <query> - Returns a map view of the area returned by `query`.

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

  robot.respond quote (.+)/i, (msg) ->
    address      = msg.match[2]
    key         = process.env.HUBOT_GOOGLE_API_KEY

    if !key
      msg.send "Please enter your Google API key in the environment variable HUBOT_GOOGLE_API_KEY."

    url         = "https://dev-api.repoweramerica.io/quote"
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
   	
   	msg.send "Sending quote request"
   	
    robot.http(url).header('Content-Type', 'application/json').header('Authorization', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJlbWFp').post(payload) (err, res, body) ->
      jsonBody = JSON.parse(body)
      response = "Response: #{body}"
      msg.send response
    
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