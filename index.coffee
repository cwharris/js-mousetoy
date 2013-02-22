class Unit

	friends = []

	constructor: ->
		@lifespan 	= new Rx.Subject
		@isBomb 	= new Rx.BehaviorSubject false
		@isCovered 	= new Rx.BehaviorSubject true
		@bombCount 	= new Rx.BehaviorSubject 0

	addFriend: (friend) ->
		disposer = new Rx.CompositeDisposable

		# update bomb count based on friends bomb status'
		disposer.add friend.isBomb
			.skipWhile((x)->!x)
			.select((x) -> if x then 1 else -1)
			.select((x) -> unit.bombCount.value + x)
			.subscribe unit.bombCount

		disposer.add friend.lifespan.subscribe(
			->
			-> 
			-> disposer.dispose()
			)

class UnitView

	constructor: (physics, unit) ->
		self = @
		@particle = 	new Particle Math.random() * .5 + .5
		@disposables = 	new Rx.CompositeDisposable
		@color =
			r: Math.floor Math.random() * 256
			g: Math.floor Math.random() * 256
			b: Math.floor Math.random() * 256

		console.log @color

		# @set.push circle
		# @set.push text

		# @circle.attr
		# 	'fill': '#ccc'
		# 	'stroke': 'none'

		# @disposables.add @particle.reactive.pos
		# 	# .distinctUntilChanged((a, b) -> a and b and a.x is b.x and a.y is b.y)
		# 	.subscribe (pos) ->
		# 		self.circle.attr
		# 			'cx': pos.x
		# 			'cy': pos.y

		physics.particles.push @particle

	draw: (ctx, dt) ->
		a = @particle.pos
		b = @particle.oldpos


		ctx.fillStyle = 'none'
		# console.log @color
		ctx.strokeStyle = "rgba(#{@color.r},#{@color.g},#{@color.b},1)"
		# console.log ctx.strokeStyle
		ctx.lineWidth = @particle.mass * 10
		ctx.beginPath()
		ctx.moveTo a.x, a.y
		ctx.lineTo b.x, b.y
		ctx.stroke()

		# ctx.fillStyle = '#rgba(0,0,0,0.5)'
		# ctx.strokeStyle = 'none'
		# ctx.beginPath()
		# ctx.arc(@particle.pos.x, @particle.pos.y, @particle.mass * 2, 0, Math.PI * 2)
		# ctx.fill()



	dispose: ->
		@disposables.dispose()
		@circle.remove()

$ ->

	document.ontouchstart = (e) -> e.preventDefault()
	document.ontouchmove = (e) -> e.preventDefault()

	$window 	= $ window
	$canvas	= $ 'canvas'

	docSize = new Rx.BehaviorSubject width: $window.width(), height: $window.height()

	a = new Attraction(new Vector(docSize.value.width / 2, docSize.value.height / 2), 100000, 1000);

	$window.onAsObservable('resize').subscribe ->
		docSize.onNext width: $window.width(), height: $window.height()

	docSize.subscribe (size) ->
		a.target = new Vector size.width / 2, size.height / 2
		$canvas.attr
			'width': size.width
			'height': size.height

	physics = new Physics

	$window.onAsObservable('touchstart').doAction (e) -> e.preventDefault()
	$window.onAsObservable('touchmove').doAction (e) -> e.preventDefault()

	Rx.Observable.merge(
		$window.onAsObservable('mousemove')
			.select (e) ->
				x: e.clientX
				y: e.clientY
		$window.onAsObservable('touchmove')
			.select (e) ->
				x: e.originalEvent.touches[0].clientX
				y: e.originalEvent.touches[0].clientY
		$window.onAsObservable('touchstart')
			.select (e) ->
				x: e.originalEvent.touches[0].clientX
				y: e.originalEvent.touches[0].clientY
	)
	.subscribe (pos) ->
		a.target = new Vector pos.x, pos.y

	views = []

	makeRandomUnit = ->

		x = Math.random() * docSize.value.width
		y = Math.random() * docSize.value.height

		unit = new Unit()
		view = new UnitView(physics, unit)
		view.particle.pos = new Vector x, y
		view.particle.old.pos = new Vector x, y
		view.particle.oldpos = new Vector x, y
		view.particle.vel = new Vector Math.random() * 1000 - 500, Math.random() * 1000 - 500

		views.push view

		view.particle.behaviours.push a

	# Rx.Observable.interval(50).take(250).subscribe ->
	# 	makeRandomUnit()

	for i in [0...250]
		makeRandomUnit()
	

	last = 0

	ctx = $('canvas')[0].getContext '2d'

	# ctx.fillStyle = "rgba(0,0,0,1)"
	# ctx.fillRect(0, 0, docSize.value.width, docSize.value.height)

	update = (timestamp) ->

		if timestamp is undefined
			requestAnimationFrame update
			return

		if last is 0 and timestamp isnt undefined
			last = timestamp
			requestAnimationFrame update
			return

		ms = timestamp - last
		dt = ms / 1000
		# console.log timestamp, last, ms, dt
		last = timestamp

		physics.step()

		requestAnimationFrame(update)

		ctx.fillStyle = "rgba(0,0,0,0.1)"
		ctx.strokeStyle = "none"
		ctx.globalCompositeOperation = 'source-over'
		ctx.fillRect(0, 0, docSize.value.width, docSize.value.height)
		ctx.globalCompositeOperation = 'lighter'

		for view in views
			view.draw ctx, dt
			view.particle.oldpos = new Vector view.particle.pos.x, view.particle.pos.y

		ctx.fillStyle = 'rgba(255,255,255,0.25)'
		ctx.font = '30px sans-serif'
		s = 'cwharris.com'
		size = ctx.measureText s
		ctx.fillText s, (docSize.value.width - size.width) / 2, (docSize.value.height / 2) - 100
		ctx.fill()
		
		# for particle in physics.particles
		# 	ctx.fillStyle = 'red'
		# 	ctx.beginPath()
		# 	ctx.arc(particle.pos.x, particle.pos.y, particle.mass * 2, 0, Math.PI * 2)
		# 	ctx.fill()
		
		
		
	update()