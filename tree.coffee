NODE_DISTANCE = 5
ATTRACTION_RADIUS = 30
KILL_DISTANCE = 4 * NODE_DISTANCE
MIN_ATTRACTIONS = 400
MAX_ATTRACTIONS = 800

CENTER_X = 200
CENTER_Y = 200

C_BLACK = "#000"
C_BACKGROUND = "#FFF"
C_NODE = C_BLACK
C_ATTRACTOR = "#FAAFBE"
C_ATTRACTION = "#38ACEC"
C_CROWN = "#E9AB17"

cardioidRadius = (a, theta) ->
	a * (1 - Math.sin theta)

inCardioid = (cx, cy, a, x, y) ->
	dx = x - cx
	dy = y - cy
	r = Math.sqrt(dx*dx + dy*dy)
	theta = Math.atan2(dy, dx)
	r <= cardioidRadius(a, theta)

fillContext = (context, color) ->
	context.fillStyle = color
	context.fill()

strokeContext = (context, color, lineWidth=2) ->
	context.lineWidth = 2
	context.strokeStyle = color
	context.stroke()

drawRect = (context, x, y, w, h, color=C_BLACK, alpha=1) ->
	context.globalAlpha = alpha
	context.fillStyle = color
	context.fillRect x, y, w, h

drawCircle = (context, x, y, radius, color=C_BLACK, alpha=1, filled=true) ->
	context.globalAlpha = alpha
	context.beginPath()
	context.arc(x, y, radius, 0, 2 * Math.PI, false)
	if filled
		fillContext(context, color)
	else
		strokeContext(context, color)

drawCardiod = (context, x, y, a, color=C_BLACK, alpha=1, filled=true) ->
	context.globalAlpha = alpha
	context.beginPath()
	context.moveTo(x, y)
	for i in [0...21]
		thetai = i * Math.PI * 2 / 20
		ri = cardioidRadius a, thetai
		xi = x + ri * Math.cos thetai
		yi = y + ri * Math.sin thetai
		context.moveTo xi, yi if i is 0
		context.lineTo xi, yi
	if filled
		fillContext context, color
	else
		strokeContext context, color

drawPoint = (context, x, y, color=C_BLACK) ->
	drawCircle(context, x, y, 2, color)

distance = (p1, p2) -> Math.sqrt((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y))

class Vec2
	constructor: (@x, @y) ->

	plus: (v) -> new Vec2 v.x + this.x, v.y + this.y
	length: -> Math.sqrt this.x*this.x + this.y*this.y
	normal: -> new Vec2 this.x / this.length(), this.y / this.length()

class Crown
	constructor: (@context, @x, @y) ->

class CircleCrown extends Crown
	constructor: (context, x, y, @radius) ->
		super(context, x, y)

	nextPoint: ->
		r = Math.random() * this.radius
		theta = Math.random() * Math.PI * 2
		new Vec2 this.x + r * Math.cos(theta), this.y + r * Math.sin(theta)

	draw: ->
		drawCircle(this.context, this.x, this.y, this.radius, C_CROWN, 0.5, false)

class CardioidCrown extends Crown
	constructor: (context, x, y, @a) ->
		super(context, x, y)

	makeSomePoint: ->
		theta = Math.PI * 2 * Math.random()
		r = this.a * 2 * Math.random()
		new Vec2(this.x + r * Math.cos(theta), this.y + r * Math.sin(theta))

	pointIsValid: (point) ->
		inCardioid(this.x, this.y, this.a, point.x, point.y)

	nextPoint: ->
		point = this.makeSomePoint()
		point = this.makeSomePoint() until this.pointIsValid(point)
		point

	draw: ->
		drawCardiod this.context, this.x, this.y, this.a, C_CROWN, 0.5, false

class Attraction
	constructor: (@node, @point) ->

class AttractionPoint
	constructor: (@context, @x, @y, @attractionRadius=ATTRACTION_RADIUS, @killDistance=KILL_DISTANCE) ->
	draw: ->
		drawCircle this.context, this.x, this.y, this.attractionRadius, color=C_ATTRACTION, alpha=0.2
		drawCircle this.context, this.x, this.y, 3, color=C_ATTRACTOR
	attraction: (nodes) ->
		attraction = null
		closest = null
		
		for node in nodes
			if distance(node, this) < this.attractionRadius
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
		this.isFinished = false
		this.iterations = 0
		this.maxIterations = 80

		this.tree = new Tree this.context, CENTER_X, CENTER_Y + 100
		this.crown = new CardioidCrown this.context, CENTER_X, CENTER_Y + 0, 100
		#this.crown = new CircleCrown this.context, CENTER_X, CENTER_Y - 40, 80
		#this.crown = new CircleCrown this.context, CENTER_X, CENTER_Y - 60, 120

		this.attractors = []
		for i in [0...(MIN_ATTRACTIONS + Math.floor(Math.random() * (MAX_ATTRACTIONS - MIN_ATTRACTIONS)))]
			pos = this.crown.nextPoint()
			this.attractors.push new AttractionPoint(
							this.context,
							pos.x,
							pos.y)

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

			if distance(closest, attractor) < attractor.killDistance
				attractors.push attractor

		attractors

	noAttractorsAreReachable: ->
		reachable = false

		for attractor in this.attractors
			closest = this.findClosestNode attractor

			if distance(closest, attractor) <= attractor.attractionRadius
				reachable = true

		return not reachable

	removeReachedAttractors: ->
		attractorsToRemove = this.findAttractorsToRemove()
		this.attractors = (attractor for attractor in this.attractors when attractor not in attractorsToRemove)

	iterate: ->
		++this.iterations
		if not this.isFinished
			this.isFinished = this.noAttractorsAreReachable()
		if not this.isFinished and this.iterations > this.maxIterations
			this.isFinished = true

		allAttractions = this.findAttractions()

		for node in this.tree.nodes
			nodeAttractions =  (attraction for attraction in allAttractions when attraction.node == node)
			if this.attractionExistsFor nodeAttractions
				this.growNode node, nodeAttractions

		this.removeReachedAttractors()
		this.redraw()

	removeAllAttractors: ->
		this.attractors = []

	finish: ->
		console.log "finished!"
		this.removeAllAttractors()
		this.redraw()

	redraw: ->
		drawRect this.context, 0, 0, 400, 400, C_BACKGROUND
		this.crown.draw()
		for attractor in this.attractors
			attractor.draw()
		this.tree.draw()

$().ready ->
	console.log "give 'er"

	canvas = $("#canvas")[0]
	context = canvas.getContext('2d')

	tb = new TreeBuilder context

	iterator = setInterval ->
		tb.iterate()
		if tb.isFinished
			clearInterval iterator
			tb.finish()
	, 1000.0 / 20
