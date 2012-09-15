CENTER_X = 200
CENTER_Y = 200

C_BLACK = "#000"
C_BACKGROUND = "#FFF"
C_NODE = C_BLACK
C_ATTRACTOR = "#FAAFBE"
C_ATTRACTION = "#38ACEC"
C_CROWN = "#E9AB17"
C_TRUNK = C_BLACK
C_DEBUG = "#52D017"

cardioidRadius = (a, theta) ->
	a * (1 - Math.sin theta)

inCardioid = (cx, cy, a, x, y) ->
	dx = x - cx
	dy = y - cy
	r = Math.sqrt(dx*dx + dy*dy)
	theta = Math.atan2(dy, dx)
	r <= cardioidRadius(a, theta)

distance = (p1, p2) -> Math.sqrt((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y))

class GraphicsContext
	constructor: (@context) ->

	fillContext: (color) ->
		@context.fillStyle = color
		@context.fill()

	strokeContext: (color, lineWidth=2) -> # heh
		@context.lineWidth = lineWidth
		@context.strokeStyle = color
		@context.stroke()

	fillOrStroke: (color, fill) ->
		if fill
			@fillContext color
		else
			@strokeContext color

	drawLine: (context, x1, y1, x2, y2, color=C_BLACK, alpha=1, lineWidth=2) ->
		@context.globalAlpha = alpha
		@context.beginPath()
		@context.moveTo x1, y1
		@context.lineTo x2, y2
		@strokeContext color, lineWidth

	drawRect: (x, y, w, h, color=C_BLACK, alpha=1, filled=true) ->
		@context.globalAlpha = alpha
		if filled
			@context.fillStyle = color
			@context.fillRect x, y, w, h
		else
			@context.strokeStyle = color
			@context.strokeRect x, y, w, h

	drawCircle: (x, y, radius, color=C_BLACK, alpha=1, filled=true) ->
		@context.globalAlpha = alpha
		@context.beginPath()
		@context.arc(x, y, radius, 0, 2 * Math.PI, false)
		@fillOrStroke color, filled

	drawCardioid: (x, y, a, color=C_BLACK, alpha=1, filled=true) ->
		@context.globalAlpha = alpha
		@context.beginPath()
		@context.moveTo(x, y)
		for i in [0...21]
			thetai = i * Math.PI * 2 / 20
			ri = cardioidRadius a, thetai
			xi = x + ri * Math.cos thetai
			yi = y + ri * Math.sin thetai
			@context.moveTo xi, yi if i is 0
			@context.lineTo xi, yi
		@fillOrStroke color, filled


	drawQuad: (p1, p2, p3, p4, color=C_BLACK, alpha=1, filled=true) ->
		@context.globalAlpha = alpha
		@context.beginPath()
		@context.moveTo p1.x, p1.y
		@context.lineTo p2.x, p2.y
		@context.lineTo p3.x, p3.y
		@context.lineTo p4.x, p4.y
		@context.closePath()

		@fillOrStroke color, filled

	drawPoint: (x, y, color=C_BLACK) ->
		@drawCircle x, y, 2, color

	clear: ->
		@drawRect 0, 0, 400, 400, "#fff"

class Vec2
	constructor: (@x, @y) ->

	plus: (v) -> new Vec2 v.x + @x, v.y + @y
	length: -> Math.sqrt @x*@x + @y*@y
	normal: -> new Vec2 @x / @length(), @y / @length()

class Crown
	constructor: (@context, @x, @y) ->

	numberOfPoints: (density) ->
		@area() * density

	makePoints: (density) ->
		(@nextPoint() for i in [0...@numberOfPoints(density)])

	controlValue: (id) ->
		parseFloat($('#' + id).val())

	getControls: ->
		"""<div>Crown height: <input id="crown-height" type="range" min="0" max="400" step="10" value="260"/></div>"""

	adjustForControls: ->
		@y = 400 - @controlValue('crown-height')

class CircleCrown extends Crown
	constructor: (context, x, y) ->
		super(context, x, y)

	nextPoint: ->
		r = Math.random() * @radius
		theta = Math.random() * Math.PI * 2
		new Vec2 @x + r * Math.cos(theta), @y + r * Math.sin(theta)

	draw: (alpha=1) ->
		@context.drawCircle @x, @y, @radius, C_CROWN, alpha, false

	area: ->
		Math.PI * @radius * @radius

	getControls: ->
		super() + """<div>Crown radius: <input id="crown-radius" type="range" min="0" max="200" step="10" value="100"/></div>"""

	adjustForControls: ->
		super()
		@radius = @controlValue('crown-radius')

class RectangleCrown extends Crown
	constructor: (context, x, y) ->
		super(context, x, y)

	nextPoint: ->
		x = -@width/2 + Math.random() * @width
		y = -@height/2 + Math.random() * @height
		new Vec2 @x + x, @y + y

	draw: (alpha=1) ->
		@context.drawRect @x - @width/2, @y - @height/2, @width, @height, C_CROWN, alpha, false

	area: ->
		@width * @height

	getControls: ->
		super() + """<div>Crown width: <input id="crown-width" type="range" min="0" max="400" step="20" value="200"/></div>
				<div>Crown length: <input id="crown-length" type="range" min="0" max="400" step="20" value="200"/></div>"""

	adjustForControls: ->
		super()
		@width = @controlValue('crown-width')
		@height = @controlValue('crown-length')

class ToroidCrown extends Crown
	constructor: (context, x, y) ->
		super(context, x, y)

	nextPoint: ->
		r = @inner + Math.random() * (@outer - @inner)
		theta = Math.random() * Math.PI * 2
		new Vec2 @x + r * Math.cos(theta), @y + r * Math.sin(theta)

	draw: (alpha=1) ->
		@context.drawCircle @x, @y, @inner, C_CROWN, alpha, false
		@context.drawCircle @x, @y, @outer, C_CROWN, alpha, false

	area: ->
		Math.PI * (@outer * @outer - @inner * @inner)

	getControls: ->
		super() + """<div>Crown inner radius: <input id="crown-inner" type="range" min="0" max="200" step="10" value="50"/></div>
		             <div>Crown outer radius: <input id="crown-outer" type="range" min="0" max="200" step="10" value="100"/></div>"""

	adjustForControls: ->
		super()
		@inner = @controlValue('crown-inner')
		@outer = @controlValue('crown-outer')

class CardioidCrown extends Crown
	constructor: (context, x, y) ->
		super(context, x, y)

	makeSomePoint: ->
		theta = Math.PI * 2 * Math.random()
		r = @a * 2 * Math.random()
		new Vec2(@x + r * Math.cos(theta), @y + r * Math.sin(theta) + @a)

	pointIsValid: (point) ->
		inCardioid(@x, @y + @a, @a, point.x, point.y)

	nextPoint: ->
		point = @makeSomePoint()
		point = @makeSomePoint() until @pointIsValid(point)
		point

	draw: (alpha=1) ->
		@context.drawCardioid @x, @y + @a, @a, C_CROWN, alpha, false

	area: ->
		1.5 * Math.PI * @a * @a

	getControls: ->
		super() + """<div>Crown radius: <input id="crown-radius" type="range" min="0" max="200" step="10" value="75"/></div>"""

	adjustForControls: ->
		super()
		@a = @controlValue('crown-radius')


class CrownSelector
	constructor: (@context) ->
		@isShowing = false
		@stopShowingTimer = 0
		@stopShowingPeriod = 20
		@alpha = 0

		@fadeIn = 0.15
		@fadeOut = 0.05
		@shownAlpha = 0.6
		@hidAlpha = 0.0

		$('#crown-selector').change( (e) =>
			@newSelectedCrown()
		)
		@newSelectedCrown()
		

	crownStartY: ->
		if $('#crown-height').length != 0 then $('#crown-height').val() else 140

	show: ->
		@isShowing = true
		@stopShowingTimer = @stopShowingPeriod

	draw: ->
		@crown.draw @alpha if @crown

	makeCrownControls: ->
		$('#crown-controls').html(@crown.getControls())
		$('#crown-controls').children().change(
			(e) =>
				@show()
		)

	getCrownSelection: ->
		$('#crown-selector').val()

	newSelectedCrown: ->
		switch @getCrownSelection()
			when 'circle'
				@crown = new CircleCrown @context, CENTER_X, @crownStartY()
			when 'cardioid'
				@crown = new CardioidCrown @context, CENTER_X, @crownStartY()
			when 'toroid'
				@crown = new ToroidCrown @context, CENTER_X, @crownStartY()
			when 'rectangle'
				@crown = new RectangleCrown @context, CENTER_X, @crownStartY()
			else
				alert 'whoa, unhandled crown'

		@makeCrownControls()
		@adjustForControls()
		@show()

	update: ->
		@alpha += @fadeIn if @alpha < @shownAlpha and @isShowing
		@alpha = @shownAlpha if @alpha > @showAlpha
		@alpha -= @fadeOut if @alpha > @hidAlpha and not @isShowing
		@alpha = @hidAlpha if @alpha < @hidAlpha

		--@stopShowingTimer if  @isShowing and @stopShowingTimer > 0
		@isShowing = false if @isShowing and @stopShowingTimer <= 0


		@adjustForControls()

	adjustForControls: ->
		@crown.adjustForControls()

	getCrown: ->
		return @crown

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

		@context.drawCircle @start.x, @start.y, (startWeight), C_TRUNK
		@context.drawCircle @end.x, @end.y, (endWeight), C_TRUNK

		theta = Math.atan2 @end.y - @start.y, @end.x - @start.x
		thetaLeft = theta + Math.PI / 2
		thetaRight = theta - Math.PI / 2

		p1 = new Vec2 @start.x + Math.cos(thetaLeft) * startWeight, @start.y + Math.sin(thetaLeft) * startWeight
		p2 = new Vec2 @start.x + Math.cos(thetaRight) * startWeight, @start.y + Math.sin(thetaRight) * startWeight
		p3 = new Vec2 @end.x + Math.cos(thetaRight) * endWeight, @end.y + Math.sin(thetaRight) * endWeight
		p4 = new Vec2 @end.x + Math.cos(thetaLeft) * endWeight, @end.y + Math.sin(thetaLeft) * endWeight

		@context.drawQuad p1, p2, p3, p4, C_TRUNK
		
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
			n = 2.5
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

		if not @allBranchesAreBeingDrawn
			@includeNextSetOfBranchesToDraw()

class TreeBuilder
	constructor: (@context, crownSelector) ->
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
		@verticalBias = parseFloat $('#vertical-bias').val()

		@structure = new TreeStructure @context, CENTER_X, CENTER_Y + 100, nodeDistance, initialHeight
		@crown = crownSelector.getCrown()

		@attractors = []
		for pos in @crown.makePoints(attractorDensity)
			@attractors.push new AttractionPoint @context,
								pos.x,
								pos.y,
								attractionRadius,
								killDistance

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

		g = new Vec2 0, @verticalBias
		
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

	removeAllAttractors: ->
		@attractors = []

	finalDraw: ->
		console.log "finished!"
		@removeAllAttractors()

	buildTree: ->
		(@tree = new Tree @context, @structure) if @isFinished()

$().ready ->
	console.log "give 'er"

	canvas = $("#canvas")[0]
	context = new GraphicsContext canvas.getContext('2d')

	iterator = null
	tb = null

	crownSelector = new CrownSelector context

	newTree = ->

		crownSelector.adjustForControls()
		tb = new TreeBuilder context, crownSelector

		tb.iterate() until tb.isFinished()
		tree = tb.buildTree()

		iterator = setInterval ->
			crownSelector.update()
			context.clear()
			crownSelector.draw()
			tree.draw()
		, 1000.0 / 20

	$('#generate-button').click ->
		clearInterval iterator
		newTree()

	newTree()
