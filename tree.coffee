KILL_DISTANCE = 4 * 5

CENTER_X = 200
CENTER_Y = 200

C_BLACK = "#000"
C_BACKGROUND = "#FFF"
C_NODE = C_BLACK
C_ATTRACTOR = "#FAAFBE"
C_ATTRACTION = "#38ACEC"
C_CROWN = "#E9AB17"
C_TRUNK = "#810541"
C_DEBUG = "#52D017"

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

strokeContext = (context, color, lineWidth=2) -> # heh
	context.lineWidth = lineWidth
	context.strokeStyle = color
	context.stroke()

drawLine = (context, x1, y1, x2, y2, color=C_BLACK, alpha=1, lineWidth=2) ->
	context.globalAlpha = alpha
	context.beginPath()
	context.moveTo x1, y1
	context.lineTo x2, y2
	strokeContext context, color, lineWidth

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

drawQuad = (context, p1, p2, p3, p4, color=C_BLACK, alpha=1, filled=true) ->
	context.globalAlpha = alpha
	context.beginPath()
	context.moveTo p1.x, p1.y
	context.lineTo p2.x, p2.y
	context.lineTo p3.x, p3.y
	context.lineTo p4.x, p4.y
	context.lineTo p1.x, p1.y
	context.closePath()

	if filled
		fillContext context, color
	else
		strokeContext context, color

drawPoint = (context, x, y, color=C_BLACK) ->
	drawCircle(context, x, y, 2, color)

clearCanvas = (canvas) ->
	drawRect canvas, 0, 0, 400, 400, "#fff"

distance = (p1, p2) -> Math.sqrt((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y))

class Vec2
	constructor: (@x, @y) ->

	plus: (v) -> new Vec2 v.x + @x, v.y + @y
	length: -> Math.sqrt @x*@x + @y*@y
	normal: -> new Vec2 @x / @length(), @y / @length()

class Crown
	constructor: (@context, @pointDensity, @x, @y) ->

	numberOfPoints: ->
		@area() * @pointDensity

	makePoints: ->
		(@nextPoint() for i in [0...@numberOfPoints()])

class CircleCrown extends Crown
	constructor: (context, pointDensity, x, y, @radius) ->
		super(context, pointDensity, x, y)

	nextPoint: ->
		r = Math.random() * @radius
		theta = Math.random() * Math.PI * 2
		new Vec2 @x + r * Math.cos(theta), @y + r * Math.sin(theta)

	draw: ->
		drawCircle(@context, @x, @y, @radius, C_CROWN, 0.5, false)

	area: ->
		Math.PI * @radius * @radius

class CardioidCrown extends Crown
	constructor: (context, pointDensity, x, y, @a) ->
		super(context, pointDensity, x, y)

	makeSomePoint: ->
		theta = Math.PI * 2 * Math.random()
		r = @a * 2 * Math.random()
		new Vec2(@x + r * Math.cos(theta), @y + r * Math.sin(theta))

	pointIsValid: (point) ->
		inCardioid(@x, @y, @a, point.x, point.y)

	nextPoint: ->
		point = @makeSomePoint()
		point = @makeSomePoint() until @pointIsValid(point)
		point

	draw: ->
		drawCardiod @context, @x, @y, @a, C_CROWN, 0.5, false

	area: ->
		1.5 * Math.PI * @a * @a

class Attraction
	constructor: (@node, @point) ->

class AttractionPoint
	constructor: (@context, @x, @y, @attractionRadius, @killDistance) ->

	draw: ->
		drawCircle @context, @x, @y, @attractionRadius, color=C_ATTRACTION, alpha=0.2
		drawCircle @context, @x, @y, 3, color=C_ATTRACTOR

	attraction: (nodes) ->
		attraction = null
		closest = null
		
		for node in nodes
			if distance(node, this) < @attractionRadius
				if closest == null or distance(node, this) < distance(closest, this)
					closest = node

		if closest
			attraction = new Attraction closest, this
		attraction

class TreeNode
	constructor: (@context, @x, @y, @parent) ->
		@children = []
		if @parent
			@parent.children.push this

	draw:  ->
		drawPoint @context, @x, @y, color=C_NODE
		for child in @children
			drawLine @context, @x, @y, child.x, child.y, color=C_NODE

class TreeStructure
	previousNode: null
	root: null

	constructor: (@context, @x, @y, @nodeDistance, initialHeight) ->
		@nodes = []
		@startingHeight = 0
		@addInitialNode() until @startingHeight > initialHeight

	addInitialNode: ->
		@addNode @x, @y - @startingHeight, @previousNode
		@startingHeight += @nodeDistance

	addNode: (x, y, parent) ->
		newNode = new TreeNode @context, x, y, parent
		@nodes.push(newNode)
		@previousNode = newNode
		if not @root
			@root = newNode

	findLeafNodes: ->
		(node for node in @nodes when node.children.length == 0)

	draw: ->
		for node in @nodes
			node.draw()

class TreeEdge
	constructor: (@start, @end) ->

class TreeBranch
	constructor: (@context, @parentBranch, @start, @end) ->
		@weight = 0
		@childWeights = []
		@isBeingDrawn = false

	isLeaf: ->
		@end.children.length == 0

	draw: ->
		startWeight = if @parentBranch then @parentBranch.weight else @weight
		endWeight = @weight

		drawCircle @context, @start.x, @start.y, startWeight, C_TRUNK
		drawCircle @context, @end.x, @end.y, endWeight, C_TRUNK

		theta = Math.atan2 @end.y - @start.y, @end.x - @start.x
		thetaLeft = theta + Math.PI / 2
		thetaRight = theta - Math.PI / 2

		p1 = new Vec2 @start.x + Math.cos(thetaLeft) * startWeight, @start.y + Math.sin(thetaLeft) * startWeight
		p2 = new Vec2 @start.x + Math.cos(thetaRight) * startWeight, @start.y + Math.sin(thetaRight) * startWeight
		p3 = new Vec2 @end.x + Math.cos(thetaRight) * endWeight, @end.y + Math.sin(thetaRight) * endWeight
		p4 = new Vec2 @end.x + Math.cos(thetaLeft) * endWeight, @end.y + Math.sin(thetaLeft) * endWeight

		drawQuad @context, p1, p2, p3, p4, C_TRUNK
		
		"""
		drawCircle @context, p1.x, p1.y, 1, C_DEBUG
		drawCircle @context, p2.x, p2.y, 1, C_DEBUG
		drawCircle @context, p3.x, p3.y, 1, C_DEBUG
		drawCircle @context, p4.x, p4.y, 1, C_DEBUG
		"""

class Tree
	constructor: (@context, @structure) ->
		@connectBranches()
		@weightBranches()
		@branchesToDraw = []
		@allBranchesAreBeingDrawn = false

	connectChildBranches: (branch) ->
		start = branch.end
		for end in start.children
			newBranch = new TreeBranch @context, branch, start, end
			@branches.push newBranch
			@connectChildBranches newBranch

	findFirstBranch: ->
		new TreeBranch @context, null, @structure.root, @structure.root.children[0]

	connectBranches: ->
		@rootBranch = @findFirstBranch()
		@branches = [@rootBranch]
		@connectChildBranches @rootBranch

	getBranchesByStart: (node) ->
		(branch for branch in @branches when branch.start == node)

	getChildBranches: (branch) ->
		@getBranchesByStart branch.end

	findWeight: (branch) ->
		weight = 0

		if branch.isLeaf()
			weight = 1
		else
			n = 4.0
			weight = 0
			childBranches = @getChildBranches branch
			for childBranch in childBranches
				weight += Math.pow (@findWeight childBranch), n
			weight = Math.pow weight, 1 / n

		branch.weight = weight
		return weight

	weightBranches: ->
		@findWeight @rootBranch

	includeNextSetOfBranchesToDraw: ->
		if @branchesToDraw.length == 0
			firstBranch = @findFirstBranch()
			firstBranch.isBeingDrawn = true
			@branchesToDraw.push firstBranch
		else
			branchesToAdd = []
			for branch in @branchesToDraw
				childBranches = @getChildBranches(branch)
				for childBranch in childBranches
					if not childBranch.isBeingDrawn
						branchesToAdd.push childBranch

			for branch in branchesToAdd
				branch.isBeingDrawn = true
				@branchesToDraw.push branch

			if branchesToAdd.length == 0
				@allBranchesAreBeingDrawn = true

	draw: ->
		for branch in @branchesToDraw
			branch.draw()
			#drawLine @context, branch.start.x, branch.start.y, branch.end.x, branch.end.y, C_TRUNK, 1, branch.weight

		if not @allBranchesAreBeingDrawn
			@includeNextSetOfBranchesToDraw()

class TreeBuilder
	constructor: (@context) ->
		@iterations = 0
		@maxIterations = 80

		#@crown = new CardioidCrown @context, CENTER_X, CENTER_Y + 0, 100
		#@crown = new CircleCrown @context, CENTER_X, CENTER_Y - 40, 80
		#@crown = new CircleCrown @context, CENTER_X, CENTER_Y - 60, 120

		nodeDistance = parseInt $('#node-distance').val()
		initialHeight = parseInt $('#initial-height').val()
		crownHeight = 400 - parseInt $('#crown-height').val()
		crownRadius = parseInt $('#crown-radius').val()
		attractorDensity = parseFloat $('#attractor-density').val()
		attractionRadius = parseFloat $('#attraction-radius').val()
		killDistance = parseFloat $('#kill-distance').val()

		@structure = new TreeStructure @context, CENTER_X, CENTER_Y + 100, nodeDistance, initialHeight
		@crown = new CircleCrown @context, attractorDensity, CENTER_X, crownHeight, crownRadius

		@attractors = []
		for pos in @crown.makePoints()
			@attractors.push new AttractionPoint @context,
								pos.x,
								pos.y,
								attractionRadius,
								killDistance

		#for attractor in @attractors
			#attractor.draw()

		#@redraw()


	findAttractions: ->
		allAttractions = []
		for attractor in @attractors
			attraction = attractor.attraction(@structure.nodes)
			allAttractions.push attraction if attraction
		return allAttractions

	attractionExistsFor: (attractions) ->
		attractions.length > 0

	growNode: (parentNode, attractions) ->
		avgX = 0
		avgY = 0

		for attraction in attractions
			avgX += attraction.point.x
			avgY += attraction.point.y

		avgX /= attractions.length
		avgY /= attractions.length

		dx = avgX - parentNode.x
		dy = avgY - parentNode.y
		d = new Vec2 dx, dy

		g = new Vec2 0, 10 # bias upwards
		
		n = (d.plus g).normal()

		newX = parentNode.x + @structure.nodeDistance * n.x
		newY = parentNode.y + @structure.nodeDistance * n.y

		@structure.addNode newX, newY, parentNode

	findClosestNode: (attractor) ->
		closest = null
		for node in @structure.nodes
			if not closest or distance(node, attractor) < distance(closest, attractor)
				closest = node
		closest

	findAttractorsToRemove: ->
		attractors = []

		for attractor in @attractors
			closest =  @findClosestNode attractor

			if distance(closest, attractor) < attractor.killDistance
				attractors.push attractor

		attractors

	noAttractorsAreReachable: ->
		reachable = false

		for attractor in @attractors
			closest = @findClosestNode attractor

			if distance(closest, attractor) <= attractor.attractionRadius
				reachable = true

		return not reachable

	removeReachedAttractors: ->
		attractorsToRemove = @findAttractorsToRemove()
		@attractors = (attractor for attractor in @attractors when attractor not in attractorsToRemove)

	isFinished: ->
		@iterations > @maxIterations or @noAttractorsAreReachable()

	iterate: ->
		if @isFinished()
			return
		++@iterations

		allAttractions = @findAttractions()

		for node in @structure.nodes
			nodeAttractions =  (attraction for attraction in allAttractions when attraction.node == node)
			if @attractionExistsFor nodeAttractions
				@growNode node, nodeAttractions

		@removeReachedAttractors()
		#@redraw()

	removeAllAttractors: ->
		@attractors = []

	finalDraw: ->
		console.log "finished!"
		@removeAllAttractors()
		#@redraw()

	buildTree: ->
		(@tree = new Tree @context, @structure) if @isFinished()

	redraw: ->
		drawRect @context, 0, 0, 400, 400, C_BACKGROUND
		@crown.draw()
		for attractor in @attractors
			attractor.draw()
		@structure.draw()

$().ready ->
	console.log "give 'er"

	canvas = $("#canvas")[0]
	context = canvas.getContext('2d')

	iterator = null
	tb = null

	newTree = ->

		tb = new TreeBuilder context

		"""
		iterator = setInterval ->
			tb.iterate()
			if tb.isFinished()
				clearInterval iterator
				tb.finish()
		, 1000.0 / 20
		"""

		tb.iterate() until tb.isFinished()
		tree = tb.buildTree()

		iterator = setInterval ->
			clearCanvas context
			tree.draw()
		, 1000.0 / 20

	$('#generate-button').click ->
		clearInterval iterator
		newTree()

	newTree()
