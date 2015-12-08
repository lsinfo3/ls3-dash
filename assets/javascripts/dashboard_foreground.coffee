# switch to dashboard on specific messages
source = new EventSource('events')
source.addEventListener 'message', (e) ->
  data = JSON.parse(e.data)
  sent = (Date.now() - data.updatedAt * 1000)/1000;
  window.location.pathname = "/vacation_coffee" if window.location.pathname != "/vacation_coffee" && data.id == "coffee-text" && data.value != 100 && data.value != 0 && data.value != '00:00'
  window.location.pathname = "/vacation_coffee" if window.location.pathname != "/vacation_coffee" && data.id == "welcome" && data.title == 'Welcome' && sent <= 5
