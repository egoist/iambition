express = require 'express'
app = express()
swig = require 'swig'
bodyParser = require 'body-parser'
logger = require 'connect-logger'
session = require 'express-session'
RedisStore = require('connect-redis')(session)
config = require './config'
helpers = require './helpers'
routes = require './routes'
global.C = config
global.H = helpers

module.exports = (root) ->
    
  sess =
    name: config.session.name
    secret: config.session.key
    store: new RedisStore()
    resave: false
    saveUninitialized: false
    cookie: 
      maxAge: 86400 * 1000 * 365
      httpOnly: false

  app.use session sess
  app.use bodyParser.json()
  app.use bodyParser.urlencoded
    extended: false

  if app.get('env') is 'development'
    app.use logger()
    app.set 'view cache', false
    swig.setDefaults cache: false

  app.use '/static', express.static('public')
  app.engine 'html', swig.renderFile
  app.set 'view engine', 'html'
  app.set 'views', root + '/views'

  auted_required = (req, res, next) ->
    if req.session.user
      res.locals.user = req.session.user
      next()
    else
      res.redirect '/signin'
      return
    return

  auted_optional = (req, res, next) ->
    res.locals.user = req.session.user
    next()
    return

  app.get '/', auted_optional, routes.index
  app.get '/ideas/new', auted_required, routes.ideas_new
  app.post '/ideas/new', auted_required, routes.ideas_newPOST
  app.post '/ideas/date', auted_optional, routes.ideasDate
  app.get '/signup', auted_optional, routes.signup
  app.post '/signup', auted_optional, routes.signupPOST
  app.get '/logout', auted_required, routes.logout
  app.get '/signin', auted_optional, routes.signin
  app.post '/signin', auted_optional, routes.signinPOST
  app.get '/settings', auted_required, routes.settings
  app.post '/settings', auted_required, routes.settingsPOST
  app.get '/settings/password', auted_required, routes.settingsPassword
  app.post '/settings/password', auted_required, routes.settingsPasswordPOST
  app.get '/settings/avatar', auted_required, routes.settingsAvatar
  app.post '/idea/heart', auted_required, routes.ideaHeart
  app.get '/idea/:slug/:salt', auted_optional, routes.idea
  app.post '/idea/comments', auted_optional, routes.ideaComments
  app.post '/comment/add', auted_required, routes.commentAdd
  app.get '/people/:username', auted_optional, routes.people
  app.get '/people/:username/ideas', auted_optional, routes.peopleIdeas
  app.get '/api/notifications/count', auted_required, routes.notificationsCount
  app.get '/notifications', auted_required, routes.notifications
  app.post '/notifications/clear', auted_required, routes.clearNotifications
  app.get '/about', auted_optional, (req, res) ->
    res.render 'page',
      title: '关于'
      slogan: '一起想，想更远'
      snaply: 'https://snaply.me/p/r0aUviEpAn7/html'

  port = config.port || 3746

  app.listen port, ->
    console.log config.site.name + ' is running at http://localhost:' + port