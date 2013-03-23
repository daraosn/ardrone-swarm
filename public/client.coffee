window.socket = new Faye.Client "/faye", timeout: 1, retry: 1
socket.bind "transport:down", ->
  swarm.forEach (drone) -> drone.terminate()
  $('body').append(
    $('<div id="lost-connection">').css(
      position: "fixed", top: 0, left: 0, width: '100%', height: '100%', opacity: 0.8, background: 'black'
    ).append(
      $('<div>').html(
        'Lost connection with server<br><br><span id="reconnecting">- Reconnecting -</span>'
      ).css(
        color: "white", textAlign: "center", fontSize: "16px", marginTop: "10px"
      )
    )
  )
  setInterval ->
    $('#lost-connection #reconnecting').fadeOut().fadeIn()
  , 1000
  socket.bind "transport:up", ->
    document.location.reload()

# initialize drones

window.swarm = []
$.extend(swarm,
  drones: {}
  forEach: (iterator) ->
    Object.keys(swarm.drones).forEach (id) ->
      iterator(swarm.drones[id])
  _speed: 1
  speed: (options) ->
    return swarm._speed unless options
    swarm._speed = options.speed
  # socket stuff
  action: (options, stop) ->
    return if stop
    console.log "/swarm/action", options
    socket.publish "/swarm/action", options
  move: (options, stop) ->
    #console.log "/drone/move", axis: options.axis, speed: options.vector * swarm.speed() * (if stop then 0 else 1)
    move = {}
    move[options.axis] = options.vector * swarm.speed() * (if stop then 0 else 1)
    socket.publish "/swarm/move", move
  animate: (options, stop) ->
    return if stop
    console.log "/swarm/animate", options
    socket.publish "/swarm/animate", options
)

$.ajax
  url: '/drones',
  dataType: 'json'
  success: (drones) ->
    drones.forEach (drone) ->
      swarm.drones[drone.id] = new Drone(drone)
      swarm.push swarm.drones[drone.id]

# configure ui

keys =
  38 : { event: swarm.move, options: { axis: 'y', vector: +1 } } # W
  40 : { event: swarm.move, options: { axis: 'y', vector: -1 } } # S
  37 : { event: swarm.move, options: { axis: 'x', vector: -1 } } # A
  39 : { event: swarm.move, options: { axis: 'x', vector: +1 } } # D
  87 : { event: swarm.move, options: { axis: 'z', vector: +1 } } # up
  83 : { event: swarm.move, options: { axis: 'z', vector: -1 } } # down
  65 : { event: swarm.move, options: { axis: 'r', vector: -1 } } # left
  68 : { event: swarm.move, options: { axis: 'r', vector: +1 } } # right
  32 : { event: swarm.action, options: { action: 'stop' } } # space
  13 : { event: swarm.action, options: { action: 'takeoff' } } # enter
  27 : { event: swarm.action, options: { action: 'land' } } # esc
  69 : { event: swarm.action, options: { action: 'disableEmergency' } } # E
  49 : { event: swarm.animate, options: { name: 'wave', duration: 3000 } } # 1
  # 50 : { event: swarm.animate, options: { name: 'flipAhead', duration: 3000 } } # 2
  # ... use animations with caution

$(document).keydown (e) ->
  return unless keyOptions = keys[e.keyCode]
  e.preventDefault()
  return if keyOptions.sending
  keyOptions.sending = true
  keyOptions.event(keyOptions.options, false)

$(document).keyup (e) ->
  return unless keyOptions = keys[e.keyCode]
  e.preventDefault()
  keyOptions.sending = false
  keyOptions.event(keyOptions.options, true)
