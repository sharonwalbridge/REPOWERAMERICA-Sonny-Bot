# Description:
#   Interacts with the Google Maps API.
#
# Commands:
#   hubot map <address> - Returns a satellite map view of the `address`.
# 	hubot quote <address> debug-display-id <1-4> - Fires off a SURGE quote for `address`, `debug-display-id (1-4)` optional
#   hubot ml <address> - Fires off a ML design request for `address`

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

  robot.respond /quote\s([^.]+?(?=\sdisplay|$))(\sdisplay\s(\d))?/i, (msg) ->
    address					= msg.match[1]
    debugLiveDisplayId 		= msg.match[3] || 0
    googleApiKey			= process.env.SONNY_GOOGLE_API_KEY
    googleUrl				= "https://maps.googleapis.com/maps/api/geocode/json"
    googleQuery 			=
      address:        address
      key:            googleApiKey
      sensor:         false
        
    ##if !googleApiKey
    ##  msg.send "Please enter your Google API key in the environment variable SONNY_GOOGLE_API_KEY."

    msg.send "Verifying, geocoding address using Google Maps API"
    robot.http(googleUrl).query(googleQuery).get() (err, res, body) ->
      googleJsonBody = JSON.parse(body)
      latitude = googleJsonBody.results[0].geometry.location.lat
      longitude = googleJsonBody.results[0].geometry.location.lng
      
      streetNumber = ""
      streetName = ""
      city = ""
      stateCode = ""
      country = ""
      postalCode = ""
      components = googleJsonBody.results[0].address_components
      for component in components
          if (component.types[0] == 'street_number') 
              streetNumber = component.long_name
          
          if (component.types[0] == 'route') 
              streetName = component.long_name
          
          if (component.types[0] == 'locality') 
              city = component.long_name
          
          if (component.types[0] == 'administrative_area_level_1') 
              stateCode = component.short_name
          
          if (component.types[0] == 'country') 
              country = component.long_name
          
          if (component.types[0] == 'postal_code') 
              postalCode = component.short_name
          
      msg.send "Geocoding successful - Latitude: #{latitude} / Longitude: #{longitude}"

      surgeUrl	= "https://dev-api.repoweramerica.io/quote"
      payload 	= JSON.stringify({
   		  address: {
   			  street: 		"#{streetNumber} #{streetName}",
   			  city:			"#{city}",
   			  postalCode:		"#{postalCode}",
   			  stateCode:		"#{stateCode}",
   			  country:		"#{country}"
   		  },
   		  location: {
   			  id:				null,
   			  static:			null,
   			  satellite:		null,
   			  pixelsToMeters:	17,
   			  orientation:	    0,
   			  returnPolygon:	true,
   			  latitude:         latitude,
   			  longitude:		longitude
   		  },
   		  debugLiveDisplayId:  	"#{debugLiveDisplayId}",
   		  optimizeFor:		"default",
   		  financeOptions:		[
   			  "cash",
   			  "loan",
   			  "ppa"
   		  ]
   	  })
   	
   	  msg.send "Sending quote request for #{address}"
      if debugLiveDisplayId > 0
           msg.send "Live Remote Display \##{debugLiveDisplayId} activated for debug"
      robot.http(surgeUrl).header('Content-Type', 'application/json').header('Authorization', 'Basic ' + new Buffer('solar-admin@solaruniverse.com:6e4346a862594b68804ea13b44901cf6').toString('base64')).post(payload) (err, res, body) ->
        jsonBody = JSON.parse(body)
        quoteId = jsonBody.id
        if !quoteId
        	msg.send "Error:  Quote not created - #{body}"
        	return
        msg.send "Quote successfully created, ID: #{quoteId}"
      
  robot.respond /ml (.+)/i, (msg) ->
    address					= msg.match[1]
    googleApiKey			= process.env.SONNY_GOOGLE_API_KEY
    googleUrl				= "https://maps.googleapis.com/maps/api/geocode/json"
    googleQuery 			=
      address:        address
      key:            googleApiKey
      sensor:         false
        
    ##if !googleApiKey
    ##  msg.send "Please enter your Google API key in the environment variable SONNY_GOOGLE_API_KEY."

    msg.send "Verifying, geocoding address using Google Maps API"
    robot.http(googleUrl).query(googleQuery).get() (err, res, body) ->
      googleJsonBody = JSON.parse(body)
      latitude = googleJsonBody.results[0].geometry.location.lat
      longitude = googleJsonBody.results[0].geometry.location.lng
      
      streetNumber = ""
      streetName = ""
      city = ""
      stateCode = ""
      country = ""
      postalCode = ""
      components = googleJsonBody.results[0].address_components
      for component in components
          if (component.types[0] == 'street_number') 
              streetNumber = component.long_name
          
          if (component.types[0] == 'route') 
              streetName = component.long_name
          
          if (component.types[0] == 'locality') 
              city = component.long_name
          
          if (component.types[0] == 'administrative_area_level_1') 
              stateCode = component.short_name
          
          if (component.types[0] == 'country') 
              country = component.long_name
          
          if (component.types[0] == 'postal_code') 
              postalCode = component.short_name
          
      msg.send "Geocoding successful - Latitude: #{latitude} / Longitude: #{longitude}"

      surgeUrl	= "https://dev-api.repoweramerica.io/quote/roof"
      payload 	= JSON.stringify({ latitude: latitude, longitude: longitude })
   	
   	  msg.send "Sending ML design request for #{address}"
      robot.http(surgeUrl).header('Content-Type', 'application/json').header('Authorization', 'Basic ' + new Buffer('solar-admin@solaruniverse.com:6e4346a862594b68804ea13b44901cf6').toString('base64')).post(payload) (err, res, body) ->
        mlId = body 
        if !mlId
        	msg.send "Error: ML Design not started - #{err}"
        	return
        msg.send "ML Design successfully started, ID: #{mlId}"
        
        
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
