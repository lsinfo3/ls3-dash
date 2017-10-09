class Dashing.Meterright extends Dashing.Widget

    @accessor 'value', Dashing.AnimatedValue
    @accessor 'isActive', ->
        /[0-9]+:[0-9]+/.test(@get('value')) && !(@get('value') == '00:00' or @get('value') == 0 or @get('value') == 100)
    @accessor 'isLow', ->
        /00:[0-2][0-9]/.test(@get('value')) && !(@get('value') == '00:00' or @get('value') == 0 or @get('value') == 100)

    constructor: ->
        super
        paused = false

        # cookies
        setCookie = (name, value, days) ->
          if days
            date = new Date()
            date.setTime date.getTime() + (days * 24 * 60 * 60 * 1000)
            expires = "; expires=" + date.toGMTString()
          else
            expires = ""
          document.cookie = name + "=" + value + expires + "; path=/"

        getCookie = (name) ->
          nameEQ = name + "="
          ca = document.cookie.split(";")
          i = 0
          while i < ca.length
            c = ca[i]
            c = c.substring(1, c.length)  while c.charAt(0) is " "
            return c.substring(nameEQ.length, c.length)  if c.indexOf(nameEQ) is 0
            i++
          null

        deleteCookie = (name) ->
          setCookie name, "", -1
        # end cookies
        
        # Returns a random integer between min (inclusive) and max (inclusive)
        getRandomInt = (min, max) ->
          Math.floor(Math.random() * (max - min + 1)) + min

        @observe 'value', (value) ->
            $(@node).find(".meterright").val(value).trigger('change')
            if (value == '00:00' or value == 0 or value == 100) and paused and ($("#coffee-sound").length==0)
                # set timeout for security if "Coffee finished" is missing
                ditcher = new (Dashing.DashboardSwitcher)
                ditcher.start 600000
                paused = false
            else if /[0-9]+:[0-9]+/.test(value) and not paused
                $('[id=dc-switcher-pause-reset]').each (index, value) ->
                    $(this).hasClass('fa-pause') and $(this).click()
                    return
                paused = true

        @observe 'text', (value) ->
            if (value == "Kaffee fertig!")
                if (not getCookie("ls3-dash_played"))
                    # create, embed audio tag and play
                    audio = document.createElement("audio")
                    audio.src = 'coffee' + getRandomInt(1,11) + '.wav'
                    audio.id = "coffee-sound"
                    audio.onended = ->
                        $( "audio" ).remove()
                        return
                    document.body.appendChild(audio)
                    audio.play()
                    setCookie("ls3-dash_played",true,1)
                    ditcher = new (Dashing.DashboardSwitcher)
                    ditcher.start 30000
            else
                document.getElementById('coffee-sound') && document.getElementById('coffee-sound').pause()
                $( "audio" ).remove()
                deleteCookie("ls3-dash_played")

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
