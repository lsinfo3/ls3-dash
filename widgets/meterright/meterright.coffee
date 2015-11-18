class Dashing.Meterright extends Dashing.Widget

  @accessor 'value', Dashing.AnimatedValue
  constructor: ->
    super
    paused = false

    @observe 'value', (value) ->
      $(@node).find(".meterright").val(value).trigger('configure','format': (value) -> value + '%')
      $(@node).find(".meterright").val(value).trigger('change')
      if value < 100 and not paused
         console.log "pausing"
         $('#dc-switcher-pause-reset').click()
         paused = true
         console.log "paused, status: " + paused
      else if paused and value is 100
         console.log "unpausing"
         $('#dc-switcher-pause-reset').click()
         paused = false
         console.log "unpaused, status: " + paused

  ready: ->
    meterright = $(@node).find(".meterright")
    meterright.attr("data-bgcolor", meterright.css("background-color"))
    meterright.attr("data-fgcolor", meterright.css("color"))
    meterright.knob('format': (value) -> value + '%')
    $control.click()
 

