NODE_DISTANCE = 5
ATTRACTION_RADIUS = 50
KILL_DISTANCE = 4 * NODE_DISTANCE
MIN_ATTRACTIONS = 50
MAX_ATTRACTIONS = 90

CENTER_X = 200
CENTER_Y = 200

C_BLACK = "#000"
C_BACKGROUND = "#FFF"
C_NODE = C_BLACK
C_ATTRACTOR = "#FAAFBE"
C_ATTRACTION = "#38ACEC"

drawRect = (context, x, y, w, h, color=C_BLACK, alpha=1) ->
	context.globalAlpha = alpha
	context.fillStyle = color
	context.fillRect x, y, w, h

drawCircle = (context, x, y, radius, color=C_BLACK, alpha=1) ->
	context.globalAlpha = alpha
	context.beginPath()
	context.arc(x, y, radius, 0, 2 * Math.PI, false)
	context.fillStyle = color
	context.fill()

drawPoint = (context, x, y, color=C_BLACK) ->
	drawCircle(context, x, y, 2, color)

distance = (p1, p2) -> Math.sqrt((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y))

class Vec2
	constructor: (@x, @y) ->

	plus: (v) -> new Vec2 v.x + this.x, v.y + this.y
	length: -> Math.sqrt this.x*this.x + this.y*this.y
	normal: -> new Vec2 this.x / this.length(), this.y / this.length()

class Attraction
	constructor: (@node, @point) ->

class AttractionPoint
	constructor: (@context, @x, @y) ->
	draw: ->
		drawCircle this.context, this.x, this.y, ATTRACTION_RADIUS, color=C_ATTRACTION, alpha=0.2
		drawCircle this.context, this.x, this.y, 3, color=C_ATTRACTOR
	attraction: (nodes) ->
		attraction = null
		closest = null
		
		for node in nodes
			if distance(node, this) < ATTRACTION_RADIUS
				if closest == null or distance(node, this) < distance(closest, this)
					closest = node

		if closest
			attraction = new Attraction closest, this
		attraction

class TreeNode
	parent: null
	constructor: (@context, @x, @y) ->
	setParent: (@parent) ->
	draw:  ->
		drawPoint this.context, this.x, this.y, color=C_NODE

class Tree
	constructor: (@context, @x, @y) ->
		this.nodes = (new TreeNode(this.context, this.x, this.y - i * NODE_DISTANCE) for i in [0...15])

		for node in this.nodes
			node.draw()

	addNode: (x, y) ->
		newNode = new TreeNode this.context, x, y
		this.nodes.push(newNode)
		newNode.draw()

	draw: ->
		for node in this.nodes
			node.draw()

class TreeBuilder
	constructor: (@context) ->
		this.tree = new Tree this.context, CENTER_X, CENTER_Y + 100

		this.attractors = []
		for i in [0...(MIN_ATTRACTIONS + Math.floor(Math.random() * (MAX_ATTRACTIONS - MIN_ATTRACTIONS)))]
			this.attractors.push new AttractionPoint(
							this.context,
							CENTER_X - 100 + Math.random() * 200,
							CENTER_Y - 100 + Math.random() * 150)

		for attractor in this.attractors
			attractor.draw()

	findAttractions: ->
		allAttractions = []
		for attractor in this.attractors
			attraction = attractor.attraction(this.tree.nodes)
			allAttractions.push attraction if attraction
		return allAttractions

	attractionExistsFor: (attractions) ->
		attractions.length > 0

	growNode: (node, attractions) ->
		avgX = 0
		avgY = 0

		for attraction in attractions
			avgX += attraction.point.x
			avgY += attraction.point.y

		avgX /= attractions.length
		avgY /= attractions.length

		dx = avgX - node.x
		dy = avgY - node.y
		d = new Vec2 dx, dy

		g = new Vec2 0, 10 # bias upwards
		
		n = (d.plus g).normal()

		newX = node.x + NODE_DISTANCE * n.x
		newY = node.y + NODE_DISTANCE * n.y

		this.tree.addNode(newX, newY)

	findClosestNode: (attractor) ->
		closest = null
		for node in this.tree.nodes
			if not closest or distance(node, attractor) < distance(closest, attractor)
				closest = node
		closest

	findAttractorsToRemove: ->
		attractors = []

		for attractor in this.attractors
			closest =  this.findClosestNode attractor

			if distance(closest, attractor) < KILL_DISTANCE
				attractors.push attractor

		attractors

	removeReachedAttractors: ->
		attractorsToRemove = this.findAttractorsToRemove()
		this.attractors = (attractor for attractor in this.attractors when attractor not in attractorsToRemove)

	iterate: ->
		allAttractions = this.findAttractions()

		for node in this.tree.nodes
			nodeAttractions =  (attraction for attraction in allAttractions when attraction.node == node)
			if this.attractionExistsFor nodeAttractions
				this.growNode node, nodeAttractions

		this.removeReachedAttractors()
		this.redraw()

	redraw: ->
		drawRect this.context, 0, 0, 400, 400, C_BACKGROUND
		this.tree.draw()
		for attractor in this.attractors
			attractor.draw()

$().ready ->
	console.log "give 'er"

	canvas = $("#canvas")[0]
	context = canvas.getContext('2d')

	tb = new TreeBuilder context

	for i in [0...100]
		tb.iterate()
