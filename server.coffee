vertx      = require 'vertx'
async      = require 'lib/async'
geocode    = require 'geocode'
findRoutes = require 'find_routes'
hsl        = require 'hsl'
validation = require 'validation'

eb = vertx.eventBus
server = vertx.createHttpServer()
routeMatcher = new vertx.RouteMatcher
helsinkiTimezone = java.util.TimeZone.getTimeZone("Europe/Helsinki")

isResource = (path) ->
  /^.*\.(css|png|js|html|hbs|manifest|ico)$/.test(path)

filterAjaxOnly = (handler) ->
  (req) ->
    if req.headers()["x-requested-with"] is "XMLHttpRequest"
      handler(req)
    else
      req.response.statusCode = 403
      req.response.end()

routeMatcher.get '/routes', filterAjaxOnly validation.validateGetRoutes (req) ->
  req.response.putHeader 'Content-Type', 'application/json; charset=utf8'
  geocodeFrom = (cb) -> geocode req.params().from, (r) -> cb(null, r)
  geocodeTo =  (cb) -> geocode req.params().to, (r) -> cb(null, r)
  async.parallel {from: geocodeFrom, to: geocodeTo}, (error, {from,to}) ->
    if from? and to?
      params =
        from: from.coords
        to: to.coords
        date: req.params().date
        time: req.params().time
        arrivalOrDeparture: req.params().arrivalOrDeparture
        transportTypes: req.params().transportTypes
      findRoutes params, (data) ->
        req.response.end JSON.stringify(from: from, to: to, routes: data.body)
    else
      req.response.statusCode = 400
      req.response.end JSON.stringify(from: !!from, to: !!to)

routeMatcher.get '/address', filterAjaxOnly validation.validateGetAddress (req) ->
  req.response.putHeader 'Content-Type', 'application/json; charset=utf8'
  hsl.reverseGeocode req.params().coords, (address) ->
    if address
      req.response.end JSON.stringify(address)
    else
      req.response.statusCode = 400
      req.response.end()
      
routeMatcher.get '/autocomplete', filterAjaxOnly validation.validateAutocomplete (req) ->
  req.response.putHeader 'Content-Type', 'application/json; charset=utf8'
  eb.send 'reitti.searchIndex.find', query: req.params().query, (data) ->
    req.response.end JSON.stringify(itm.name for itm in data.results)

routeMatcher.get '/timezoneoffset', filterAjaxOnly (req) ->
  req.response.putHeader 'Content-Type', 'text/plain; charset=utf8'
  req.response.end helsinkiTimezone.getOffset(new java.util.Date().getTime())

routeMatcher.noMatch (req) ->
  file = '';
  if req.path.indexOf('..') is -1 and isResource(req.path)
    file = req.path
  else
    file = 'index.html'

  req.response.sendFile 'web/'+file

server.requestHandler(routeMatcher).listen 8080

stdout.println "Server started"
