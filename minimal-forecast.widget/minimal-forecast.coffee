# CONFIG:

apiKey:           'YOUR API KEY HERE'
gridlineEvery:    10
units:            'auto'
apparentTemps:    false

# END CONFIG

refreshFrequency: '1h'
command:          ''
exclude:          'alerts,flags,minutely,hourly,currently'
heightEms:        10
iMin:             if @apparentTemps then 'apparentTemperatureMin' else 'temperatureMin'
iMax:             if @apparentTemps then 'apparentTemperatureMax' else 'temperatureMax'

render: (out) ->
  html = ''
  html += '<div class="day-wrap"><div class="day"><div class="high"></div><div class="low"></div></div></div>' for [1..7]
  html

afterRender: (domEl) ->
  if @apiKey.length != 32
    domEl.innerHTML = '<a href="http://developer.forecast.io" style="color: inherit">You need an API key!</a>'
    return
  geolocation.getCurrentPosition (e) =>
    coords     = e.position.coords
    [lat, lon] = [coords.latitude, coords.longitude]
    @command   = @makeCommand(@apiKey, "#{lat},#{lon}")

    @refresh()

makeCommand: (apiKey, location) ->
  "curl -sS 'https://api.forecast.io/forecast/#{apiKey}/#{location}?units=#{@units}&exclude=#{@exclude}'"

update: (o, dom) ->
  return 0 if o == ''
  o = JSON.parse(o)
  data = o.daily.data


  for day in data
    max = day[@iMax] if !(day[@iMax] < max)
    min = day[@iMin] if !(day[@iMin] > min)

  for day, i in dom.querySelectorAll('.day')
    day = $(day)
    day.addClass 'loaded'
    day.find('.high').text(Math.round(data[i][@iMax]))
    day.find('.low').text(Math.round(data[i][@iMin]))
    day.css top: @map(data[i][@iMax], max, min, 0, @heightEms)+'em'
    day.css height: @map(data[i][@iMax] - data[i][@iMin], max-min, 0, @heightEms, 0)+'em'

  $('.gridline').remove()
  maxInt = Math.floor(max/@gridlineEvery)*@gridlineEvery
  minInt = Math.ceil(min/@gridlineEvery)*@gridlineEvery
  for t in [minInt..maxInt] by @gridlineEvery
    line = $('<div>', {class: "gridline"}).appendTo(dom)
    $(line).css top: (@map(t, max, min, 0, @heightEms)+1.5)+'em'
    $(line).addClass('zero') if t == 0

map: (input, omin, omax, mmin, mmax) ->
  (input-omin) * ((mmax-mmin)/(omax-omin)) + mmin

style: """
display: flex
cursor: normal
position: absolute
bottom: 32px
left: 32px
padding: 1.5em 0
height: 10em
color: #fff
font-family: system, -apple-system, sans-serif
font-size: 12px
font-weight: 400
text-shadow: 0 0 0.2em black

.gridline
  position: absolute
  left: 0
  width: 100%
  border-top: 0.1em solid rgba(255,255,255,0.5)
  box-shadow: 0 0 0.2em black
  z-index: 1

.zero
  border-top: 0.2em solid rgba(255,255,255,0.7)

.day
  position: relative
  width: 1em
  height: 10em
  margin: 0 0.75em
  border-radius: 0.5em
  background-color: #fff
  opacity: 0.5
  text-align: center
  transition: all 0.6s
  box-shadow: 0 0 0.3em rgba(0,0,0,0.6)
  z-index: 2

.day-wrap:last-child .day
  margin-right: 0

.day.loaded
  opacity: 1

.high, .low
  opacity: 0
  transition: opacity 0.5s
  position: absolute
  width: 3em
  right: -1em

.high
  top: -1.5em

.low
  bottom: -1.5em

.day-wrap:hover .high, .day-wrap:hover .low
  opacity: 1
"""