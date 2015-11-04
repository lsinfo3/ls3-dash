class Dashing.Meterright extends Dashing.Widget

  @accessor 'value', Dashing.AnimatedValue

  constructor: ->
    super
    @observe 'value', (value) ->
      $(@node).find(".meterright").val(value).trigger('change')

  ready: ->
    meterright = $(@node).find(".meterright")
    meterright.attr("data-bgcolor", meterright.css("background-color"))
    meterright.attr("data-fgcolor", meterright.css("color"))
    meterright.knob()
