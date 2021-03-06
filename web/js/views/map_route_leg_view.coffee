define ['underscore', 'utils', 'views/map_leg_marker', 'views/map_location_marker'], (_, Utils, MapLegMarker, MapLocationMarker) ->
  class MapRouteLegView

    constructor: ({@routes, @routeParams, @routeIndex, @index, @map}) ->
      @leg = @routes.at(@routeIndex).getLeg(@index)
      Reitti.Event.on 'routes:change', @onRoutesChanged

    dispose: ->
      Reitti.Event.off 'routes:change', @onRoutesChanged
      @line?.setMap null
      @marker?.setMap null
      @destinationMarker?.setMap null
      @hideMarkers()
      this

    render: () ->
      path = (new google.maps.LatLng point.y, point.x for point in @leg.get('shape'))
      @line = new google.maps.Polyline
          map: @map
          path: path
          strokeWeight: 5
          strokeColor: Utils.transportColors[@leg.get('type')]
          strokeOpacity: 0.8
      @marker = new google.maps.Marker
        map: @map
        icon: new google.maps.MarkerImage('/img/sprites.png', new google.maps.Size(11, 11), new google.maps.Point(0, 0), new google.maps.Point(5, 5))
        position: path[0]
      if @index is @routes.at(@routeIndex).getLegCount() - 1
        @destinationMarker = new google.maps.Marker
          map: @map
          icon: new google.maps.MarkerImage('/img/sprites.png', new google.maps.Size(11, 11), new google.maps.Point(0, 0), new google.maps.Point(5, 5))
          position: _.last(path)

      google.maps.event.addListener @line, 'click', @onClicked
      google.maps.event.addListener @marker, 'click', @onClicked
      this

    onClicked: () =>
      Reitti.Router.navigateToRoutes _.extend(@routeParams, legIndex: @index, originOrDestination: undefined)

    onRoutesChanged: (routes, routeParams) =>
      if @isSelectedIn(routes, routeParams) and @line.getPath()?
        @showOriginMarker()
        @showDestinationMarker()
      else
        @hideMarkers()
      @originMarker?.onRoutesChanged(routes, routeParams)
      @destMarker?.onRoutesChanged(routes, routeParams)

    showOriginMarker: =>
      return unless @originLatLng()?
      anchor = MapLocationMarker.markerAnchor(@originLatLng(), @line.getPath())
      @originMarker ?= new MapLocationMarker
        leg: this
        originOrDestination: 'origin'
        location: @originLatLng()
        name: @leg.originName()
        anchor: anchor

    showDestinationMarker: =>
      return unless @originLatLng()?
      anchor = MapLocationMarker.markerAnchor(@destinationLatLng(), @line.getPath())
      @destMarker ?= new MapLocationMarker
        leg: this
        originOrDestination: 'destination'
        location: @destinationLatLng()
        name: @leg.destinationName()
        anchor: anchor

    originLatLng: ->
      @line?.getPath()?.getAt(0)

    destinationLatLng: ->
      @line?.getPath()?.getAt(@line.getPath().getLength() - 1)

    getEndCoordinates: (originOrDestination) ->
      if originOrDestination is 'origin'
        @originLatLng()
      else
        @destinationLatLng()

    hideMarkers: =>
      @originMarker?.setMap null
      @destMarker?.setMap null
      @originMarker = null
      @destMarker = null

    isSelectedIn: (routes, routeParams) ->
      routes is @routes and routeParams.routeIndex is @routeIndex and routeParams.legIndex is @index

    getBounds: () ->
      bounds = new google.maps.LatLngBounds()
      if @line? and @line.getPath()?
        bounds.extend(latLng) for latLng in @line.getPath().getArray()
      bounds