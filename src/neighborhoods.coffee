# Shortcuts
__ =
  mapEvent: (event, map, callback) ->
    google.maps.event.addListener(map,event,callback)

window.App =
  mapOptions:
    center: {lat:35.790895, lng:-78.661153}
    zoom: 14
    streetViewControl: false

  neighborhoods: []

  init: ->
    @map = new google.maps.Map $('#map-canvas').get(0), @mapOptions
    @neighborhoodsView = new NeighborhoodsView el: '#neighborhoods'
    @neighborhoodsView.render()


  getMap: ->
    @map

  startDrawing: (poly) ->
    @drawing = true
    @map.setOptions draggableCursor: 'crosshair'

  stopDrawing: ->
    @drawing = false
    @map.setOptions draggableCursor: null

  clearMap: ->
    @neighborhood.clear()

  logPath: ->
    console.log @neighborhood.getPath()

class NeighborhoodsView extends Backbone.View
  nViews: []
  events:
    'click #add-neighborhood':'addNeighborhood'

  initialize: ->
    @getNeighborhoods()

  render: ->
    console.log 'render list', @$('.neighborhood-list')
    @$('.neighborhood-list').empty()
    for v in @nViews
      v.render()
      v.delegateEvents()
      @$('.neighborhood-list').append v.el

  getNeighborhoods: ->
    console.log "neighborhood ndata",ndata
    for d in ndata
      @nViews.push new NeighborhoodView(d)

  addNeighborhood: ->
    n = new NeighborhoodView name: "New Neighborhood"
    n.on 'remove', @removeView.bind(this)
    @nViews.push n
    @render()

  removeView: (view) ->
    @nViews = _(@nViews).without(view)


class NeighborhoodView extends Backbone.View
  tagName: 'li'
  className: 'neighborhood'
  template: _.template """
    <div class="name">
      <label>Neighborhood Name:</label>
      <input type="text" name="name" value="<%= name %>"></input>
    </div>
    <div class="actions">
      <button class="edit-poly">Start Drawing</button>
      <button class="save">Save Changes</button>
      <% if(id){ %>
        <button class="delete">Delete</button>
      <%} %>
      <span class="status"></span>
    </div>
  """
  events:
    'click .edit-poly':'toggleDrawing'
    'click .save':'save'
    'click .delete':'delete'

  initialize: (opts={}) ->
    console.log "init opts",opts
    @id = opts.id
    @name = opts.name
    @polygon = new Polygon opts.poly

  render: ->
    @$el.html @template(this)
    this

  toggleDrawing: ->
    if @drawing then @stopDrawing() else @startDrawing()

  startDrawing: ->
    @drawing = true
    @polygon.startEditing()
    @$('.edit-poly').text('Stop Drawing')

  stopDrawing: ->
    @drawing = false
    @polygon.stopEditing()
    @$('.edit-poly').text('Start Drawing')

  save: ->
    @stopDrawing()
    unless @polygon.getPath().length
      alert "Please draw a shape for this neighborhood before saving"
      return false
    @name = @$('input[name=name]').val()
    payload =
      name: @name
      poly: @polygon.getPath()
    console.log 'save payload', payload
    if @id
      @_update(payload)
    else
      @_create(payload)

  _create: (payload) ->
    @_saveRequest(
      payload, url: '/neighborhoods', type: 'POST'
    ).done( (response) =>
      @id = response.id
      @render()
    ).fail( (response) =>
      console.log "create failed", response
    )

  _update: (payload) ->
    @_saveRequest(
      payload, url: "/neighborhoods/#{@id}", type: 'PUT'
    ).done( (response) =>
      @render()
    ).fail( (response) =>
      console.log "update failed", response
    )

  _saveRequest: (payload, requestOpts) ->
    baseOpts =
      contentType: 'application/json'
      dataType: 'json'
      data: JSON.stringify(payload)
    opts = _(baseOpts).extend(requestOpts)
    $.ajax(opts)

  delete: ->
    $.ajax(
      url: "/neighborhoods/#{@id}"
      type: "DELETE"
    ).done(
      @remove()
    )

  remove: ->
    console.log 'remove'
    @stopDrawing()
    @polygon.clear()
    @trigger 'remove', this
    super()


class Polygon
  polyBase:
    strokeOpacity: 0.8
    strokeWeight: 2
    fillOpacity: 0.35
    strokeColor: '#000'
    fillColor: '#000'

  polyNormal:
    editable: false
    strokeColor: '#000'
    fillColor: '#000'

  polyEditing:
    editable: true
    strokeColor: '#FF0000'
    fillColor: '#FF0000'

  constructor: (data) ->
    @map = App.getMap()
    @gpoly ?= new google.maps.Polygon(@polyBase)
    @gpoly.setPath @parseData(data) if data
    @gpoly.setMap(@map)

  parseData: (data) ->
    _(data).map (c) -> new google.maps.LatLng(c[0],c[1])

  startEditing: ->
    App.startDrawing()
    @gpoly.setOptions(@polyEditing)
    @leftClick = __.mapEvent 'click', @map, (event) =>
      @gpoly.getPath().push(event.latLng)
    @rightClick = __.mapEvent 'rightclick', @gpoly, (event) =>
      @gpoly.getPath().removeAt(event.vertex) if event.vertex

  stopEditing: ->
    App.stopDrawing()
    google.maps.event.removeListener(@leftClick)
    google.maps.event.removeListener(@rightClick)
    @gpoly.setOptions(@polyNormal)

  getPath: ->
    pathArray = []
    @gpoly.getPath().forEach (c) ->
      pathArray.push [c.lat(),c.lng()]
    pathArray

  clear: ->
    @gpoly.setMap(null)

App.init()
