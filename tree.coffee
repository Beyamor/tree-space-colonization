NODE_DISTANCE = 10
ATTRACTION_RADIUS = 20
KILL_DISTANCE = 10

CENTER_X = 200
CENTER_Y = 200

C_BLACK = "#000"
C_NODE = C_BLACK
C_ATTRACTOR = "#FAAFBE"
C_ATTRACTION = "#38ACEC"

drawCircle = (context, x, y, radius, color=C_BLACK, alpha=1) ->
	context.globalAlpha = alpha
	context.beginPath()
	context.arc(x, y, radius, 0, 2 * Math.PI, false)
	context.fillStyle = color
	context.fill()

drawPoint = (context, x, y, color=C_BLACK) ->
	drawCircle(context, x, y, 2, color)

class AttractionPoint
	constructor: (@context, @x, @y) ->
	draw: ->
		drawCircle this.context, this.x, this.y, ATTRACTION_RADIUS, color=C_ATTRACTION, alpha=0.2
		drawCircle this.context, this.x, this.y, 3, color=C_ATTRACTOR

class TreeNode
	parent: null
	constructor: (@context, @x, @y) ->
	setParent: (@parent) ->
	draw:  ->
		drawPoint this.context, this.x, this.y, color=C_NODE

class Tree
	constructor: (@context, @x, @y) ->
		this.nodes = (new TreeNode(this.context, this.x, this.y - i * NODE_DISTANCE) for i in [0...5])

		for node in this.nodes
			node.draw()

class TreeBuilder
	constructor: (context) ->
		t = new Tree context, CENTER_X, CENTER_Y + 100

		this.attractors = []
		for i in [0...(10 + Math.floor(Math.random() * 10))]
			this.attractors.push new AttractionPoint(
							context,
							CENTER_X - 100 + Math.random() * 200,
							CENTER_Y - 100 + Math.random() * 200)

		for attractor in this.attractors
			attractor.draw()
$().ready ->
	console.log "give 'er"

	canvas = $("#canvas")[0]
	context = canvas.getContext('2d')

	tb = new TreeBuilder context
