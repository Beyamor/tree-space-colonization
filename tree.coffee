NODE_DISTANCE = 10

C_BLACK = "#000"

class TreeNode
	parent: null
	constructor: (@x, @y) ->
	setParent: (@parent) ->

class Tree
	constructor: (@context, @x, @y) ->
		this.nodes = (new TreeNode(this.x, this.y - i * NODE_DISTANCE) for i in [0...5])

		for node in this.nodes
			drawPoint this.context, node.x, node.y

class TreeBuilder
	constructor: (context) ->
		t = new Tree context, 200, 300


drawPoint = (context, x, y, color=C_BLACK) ->
	context.fillStyle = color
	context.fillRect x-1, y-1, 2, 2

$().ready ->
	console.log "give 'er"

	canvas = $("#canvas")[0]
	context = canvas.getContext('2d')

	tb = new TreeBuilder context
