refreshFrequency: '1h'
apiKey:           'YOUR API KEY HERE'
command:          ''
exclude:          'minutely,alerts,flags,hourly,currently'
heightEms:        10

render: (out) ->
  html = '<div class="zero"></div>'
  html += '<div class="day-wrap"><div class="day"><div class="high"></div><div class="low"></div></div></div>' for i in [1..7]
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
  "curl -sS 'https://api.forecast.io/forecast/#{apiKey}/#{location}?units=si&exclude=#{@exclude}'"

update: (o, dom) ->
  return 0 if o == ''
  o = JSON.parse(o) if o != ''
  data = o.daily.data
  for day in data
    day.max = day.apparentTemperatureMax
    day.min = day.apparentTemperatureMin
    max = day.max if !(day.max < max)
    min = day.min if !(day.min > min)
  for day, i in dom.querySelectorAll('.day')
    day = $(day)
    day.addClass 'loaded'
    day.find('.high').text(Math.round(data[i].max))
    day.find('.low').text(Math.round(data[i].min))
    day.css top: @map(data[i].max, max, min, 0, @heightEms)+'em'
    day.css height: @map(data[i].max - data[i].min, max-min, 0, @heightEms, 0)+'em'
  if min < 0 and max > 0
    $('.zero').addClass 'active'
    $('.zero').css top: (@map(0, max, min, 0, @heightEms)+1.5)+'em'
  else
    $('.zero').removeClass 'active'

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

.zero.active
  position: absolute
  width: 100%
  border-top: 0.15em dashed rgba(255,255,255,0.5)

.day
  position: relative
  width: 1em
  height: 10em
  margin: 0 1.5em 0 0
  border-radius: 0.5em
  background-color: #fff
  opacity: 0.5
  text-align: center
  transition: all 0.6s

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