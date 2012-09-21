define ['jquery', 'hbs!template/map_location_marker', "async!http://maps.googleapis.com/maps/api/js?sensor=true#{window.gmapsKey}"], ($, template) ->

  WIDTH = 100
  HEIGHT = 20

  class MapLocationMarker extends google.maps.OverlayView

    constructor: (@location, @name, @map, @anchor = 'left') ->
      @setMap(map)

    onAdd: ->
      @div = $(template(anchor: @anchor, content: @name))[0]
      @getPanes().floatPane.appendChild(@div)
      $(@div).on 'click', @onClicked

    draw: ->
      {x: x, y: y} = @getProjection().fromLatLngToDivPixel(@location)
      switch @anchor
        when 'top' 
          x -= WIDTH / 2
          y -= (HEIGHT + 10)
        when 'bottom'
          x -= WIDTH / 2
        when 'left'
          x -= (WIDTH + 10)
          y -= HEIGHT / 2
        when 'right'
          y -= HEIGHT / 2
      @div.style.left = "#{x}px"
      @div.style.top = "#{y}px"

    onClicked: =>
      @map.panTo @location
      @map.setZoom 18

    onRemove: ->
      @div.parentNode.removeChild(@div)
      @div = null
