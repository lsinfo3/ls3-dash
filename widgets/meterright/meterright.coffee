class Dashing.Meterright extends Dashing.Widget

  @accessor 'value', Dashing.AnimatedValue
  constructor: ->
    super
    paused = false

    @observe 'value', (value) ->
      $(@node).find(".meterright").val(value).trigger('change')
      if (value == '00:00' or value == 0 or value == 100) and paused
         $('#dc-switcher-pause-reset').click()
         paused = false
      else if /[0-9]+:[0-9]+/.test(value) and not paused
         $('#dc-switcher-pause-reset').click()
         paused = true

  ready: ->
    meterright = $(@node).find(".meterright")
    meterright.attr("data-bgcolor", meterright.css("background-color"))
    meterright.attr("data-fgcolor", meterright.css("color"))
    meterright.knob
        "parse": (value) -> 
            min = parseInt((value+"").split(':')[0])
            sec = parseInt((value+"").split(':')[1])
            parseFloat(min * 60 + sec)
