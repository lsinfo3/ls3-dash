class Dashing.Meterright extends Dashing.Widget

    @accessor 'value', Dashing.AnimatedValue
    @accessor 'isActive', ->
        /[0-9]+:[0-9]+/.test(@get('value')) && !(@get('value') == '00:00' or @get('value') == 0 or @get('value') == 100)
    @accessor 'isLow', ->
        /00:[0-2][0-9]/.test(@get('value')) && !(@get('value') == '00:00' or @get('value') == 0 or @get('value') == 100)

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

        @observe 'text', (value) ->
            if (value == "Kaffee fertig!")
                audio = document.createElement("audio")
                audio.src = "coffee.wav"
                audio.id = "coffee-sound"
                document.body.appendChild(audio)
                audio.play()
            else
                document.getElementById('coffee-sound') && document.getElementById('coffee-sound').pause()
                $( "audio" ).remove()


    ready: ->
        meterright = $(@node).find(".meterright")
        meterright.attr("data-bgcolor", meterright.css("background-color"))
        meterright.attr("data-fgcolor", meterright.css("color"))
        meterright.knob
            "font": "\"Open Sans\",\"Helvetica Neue\",Helvetica,Arial,sans-serif"
            "parse": (value) ->
                min = parseInt((value+"").split(':')[0])
                sec = parseInt((value+"").split(':')[1])
                parseFloat(min * 60 + sec)
