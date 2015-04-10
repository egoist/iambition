moment = require 'moment'

compare = (a, b) ->
  b.score - a.score

helpers = module.exports = {}

helpers.vesion = ->
  require('../package').version

helpers.css = (filename) ->
  '<link rel="stylesheet" href="/static/css/' + filename + '.css' + '">'

helpers.js = (filename) ->
  '<script src="' + '/static/js/' + filename + '.js' + '">'

helpers.getDate = (date) ->
  days = ['天','一','二','三','四','五','六']
  date = if date then new Date(date) else new Date()
  date.getMonth() + 1 + ' 月 ' +  date.getDate() + ' 日' + '，星期' + days[ date.getDay() ]

helpers.md5 = (string) ->
  md5 = require 'MD5'
  md5 string

helpers.xss = (text) ->
  xss = require('xss')
  xss.whiteList['pre'] = ['class', 'style','id']
  xss.whiteList['p'] = ['class', 'style','id']
  xss.whiteList['span'] = ['class', 'style','id']
  xss.whiteList['div'] = ['class', 'style','id']
  xss.whiteList['img'] = ['class', 'src']
  xss.whiteList['i'] = ['class']
  xss.whiteList['ul'] = ['class']
  xss.whiteList['li'] = ['class']
  xss.whiteList['input'] = ['type', 'class', 'disabled', 'id', 'checked']
  xss text

helpers.gravatar = (string, size) ->
  size = size || 80
  'http://gravatar.duoshuo.com/avatar/' + string + '?s='+ size + '&d=monsterid'

helpers.salt = (length) ->
  randomstring = require 'randomstring'
  randomstring.generate(length).toLowerCase()

helpers.slug = (string) ->
  seperator = '-'
  string = require('unidecode')(string)
  string = string.replace(/[:\/\?#\[\]@!$&'()*+,;=\\%<>\|\^~£"]/g, '')
            .replace(/(\s|\.)/g, seperator)
            .replace(/-+/g, seperator)
            .toLowerCase()
  if string.substring(string.length - 1) == '-'
    string = string.substring 0, string.length - 1
  string = string || helpers.salt(3)
  string

helpers.checkInArray = (array, value) ->
  return true if array.indexOf(value) > -1
  return false

helpers.removeInArray = (array) ->
  a = arguments
  L = a.length
  while L > 1 and array.length 
    what = a[--L]
    while (ax= array.indexOf(what)) isnt -1
      array.splice(ax, 1)
  array

helpers.stripTags = (text) -> 
  text.replace(/(<([^>]+)>)/ig,"")

helpers.md = (text) ->
  marked = require 'marked'
  cheerio = require 'cheerio'
  renderer = new marked.Renderer()
  complete = '<input type="checkbox" class="task-list-item-checkbox" checked="" disabled="">'
  uncomplete = '<input type="checkbox" class="task-list-item-checkbox" disabled="">'
  renderer.list = (body, ordered) ->
    type = if ordered then 'ol' else 'ul'
    startType = type
    $ = cheerio.load(body)

    startType = type + ' class="task-list-items"' if $('li').find('input').length > 0
    '<' + startType + '>\n' + body + '</' + type + '>\n'
  renderer.listitem = (text) ->
    if /^\s*\[[x ]\]\s*/.test(text)
      checkbox = if /^\s*\[[xX]\]\s*/.test(text) then complete else uncomplete
      text = text.replace(/^\s*\[ \]\s*/, checkbox).replace(/^\s*\[x\]\s*/, checkbox)
      '<li class="task-list-item">' + text + '</li>'
    else
      '<li>' + text + '</li>'
  marked.setOptions
    renderer: renderer
    gfm: true
    tables: true
    breaks: false
    pedantic: false
    sanitize: true
    smartLists: true
    smartypants: false
    highlight: (code) ->
      require('highlight.js').highlightAuto(code).value
  marked(text)

helpers.timeago = (date) ->
  moment.locale('zh-cn')
  moment(new Date(date)).fromNow()
  
helpers.sort = (array) ->
  g = 1.8
  for k,v of array
    addtime = new Date(v.createdAt)
    addtime = addtime.getTime()
    now = new Date
    now = now.getTime()
    ageInHour = (now - addtime) / 1000 / 360
    array[k].score = (v.hearts.length - 1) / Math.pow((ageInHour + 2), g)
  array.sort compare
  array

helpers.arrayUnique = (a) ->
  a.reduce ((p, c) ->
    if p.indexOf(c) < 0
      p.push c
    p
  ), []