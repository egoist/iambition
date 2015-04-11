M = require './models'
bcrypt = require 'bcrypt'
IS = require 'is_js'
_ = require 'underscore'


routes = module.exports = {}

routes.index = (req, res) ->
  date = if req.query.date then req.query.date else new Date
  date.setHours(0,0,0,0)
  date_end = new Date(date)
  date_end.setDate(date.getDate() + 1)
  query = 
    "createdAt":
      "$gte": new Date(date)
      "$lt": new Date(date_end)
  M.idea.find().where(query).populate('user').sort(createdAt: -1).exec (err, ideas) ->
    if ideas
      for k, v of ideas
        ideas[k].author = v.user[0]
        ideas[k].description = H.stripTags H.md H.xss v.description
        if req.session.user
          if H.checkInArray(v.hearts, req.session.user.uid)
            ideas[k].hearted = true
          else
            ideas[k].hearted = false
      ideas = H.sort ideas
    res.render 'index',
      date: H.getDate(date)
      ideas: ideas
      ajax: true

routes.ideasDate = (req, res) ->
  date = new Date(req.body.date)
  date.setHours(0,0,0,0)
  date_end = new Date(date)
  date_end.setDate(date.getDate() + 1)
  query = 
    "createdAt":
      "$gte": new Date(date)
      "$lt": new Date(date_end)
  M.idea.find().where(query).populate('user').sort(createdAt: -1).exec (err, ideas) ->
    if ideas
      for k, v of ideas
        ideas[k].author = v.user[0]
        ideas[k].description = H.stripTags H.md H.xss v.description
        if req.session.user
          if H.checkInArray(v.hearts, req.session.user.uid)
            ideas[k].hearted = true
          else
            ideas[k].hearted = false
      ideas = H.sort ideas
    res.render 'list',
      date: H.getDate(date)
      ideas: ideas
      ajax: true

routes.ideas_new = (req, res) ->
  res.render 'ideas_new',
    title: '分享创意'

routes.ideas_newPOST = (req, res) ->
  title = req.body.title
  description = req.body.description
  idea =
    title: title
    slug: H.slug title
    description: description
    uid: req.session.user.uid
    user: req.session.user._id
    salt: H.salt 3
  errors = []
  if not idea.title
    errors.push '创意标题不能为空'
  if not idea.description
    errors.push '详细描述不能为空'
  if errors.length > 0
    res.json
      status: 'bad'
      errors: errors
  else
    idea = new M.idea idea
    idea.save (err) ->
      res.json
        status: 'good'
        idea: idea


routes.signup = (req, res) ->
  res.render 'auth',
    title: '注册'

routes.signupPOST = (req, res) ->
  user = 
    username: req.body.username
    email: req.body.email
    password: req.body.password
  user.gravatar = H.md5 user.email
  errors = []
  if not user.username
    errors.push '用户名不能为空'
  if not user.email 
    errors.push '邮箱不能为空'
  if not user.password or user.password.length < 8
    errors.push '密码不能为空且需至少 8 位'
  if errors.length > 0
    res.render 'auth',
      title: '注册'
      errors: errors
      formData: user
    return
  else
    bcrypt.genSalt 10, (err, salt) ->
      bcrypt.hash user.password, salt, (err, hash) ->
        M.user.findOne().where
          $or: 
            [{email: user.email},{username: user.username}]
         .exec (err, gotUser) ->
            console.log gotUser
            if gotUser
              if gotUser.email = user.email
                errors.push '邮箱地址已经存在'
              if gotUser.username = user.username
                errors.push '用户名已经存在'
              res.render 'auth',
                title: '注册'
                errors: errors
                formData: user
              return
            else             
              user.password = hash
              user = new M.user user
              user.save (err) ->
                req.session.user = user
                res.redirect '/'

routes.logout = (req, res) ->
  req.session.destroy (err) ->
    res.redirect '/'

routes.signin = (req, res) ->
  res.render 'auth',
    title: '登录'

routes.signinPOST = (req, res) ->
  account = req.body.account
  password = req.body.password
  errors = []
  if not account
    errors.push '账户名不能为空且至少 5 位'
  if not password or password.length < 8
    errors.push '密码不能为空且需至少 8 位'
  if errors.length > 0
    res.render 'auth',
      title: '登录'
      errors: errors
      formData: 
        account: account
        password: password
    return
  else
    M.user.findOne().where
      $or:
        [{username:account}, {email: account}]
    .exec (err, gotUser) ->
      if not gotUser
        errors.push '未找到此用户'
        res.render 'auth',
          title: '登录'
          errors: errors
          formData: 
            account: account
            password: password
        return
      bcrypt.compare password, gotUser.password, (err, result) ->
        req.session.user = gotUser
        res.redirect '/'

routes.settings = (req, res) ->
  res.render 'settings',
    title: '设置'
    active: 'profile'
    formData: req.session.user

routes.settingsPOST = (req, res) ->
  user =
    email: req.body.email
    gravatar: H.md5 req.body.email
    introduction: req.body.introduction
    tags: req.body.tags
  errors = []
  if not user.email 
    errors.push '邮箱不能为空'
  if errors.length > 0
    res.render 'settings',
      title: '帐户设置'
      errors: errors
      formData: user
      active: 'profile'
    return
  else
    M.user.findOne
      $or:
        [{email: user.email},{username: user.username}]
    .exec (err, gotUser) ->
      if gotUser and gotUser.uid isnt req.session.user.uid
        console.log gotUser.uid + ':' + req.session.user.uid
        if gotUser.email is user.email
          errors.push '邮箱已被使用'
        if gotUser.username is user.username
          errors.push '用户名已被使用'
        res.render 'settings',
          title: '帐户设置'
          errors: errors
          formData: user
          active: 'profile'
        return
      else
        M.user.findOneAndUpdate 
          uid: req.session.user.uid, 
          user, 
          new: true,
          (err, result) ->
            req.session.user = result
            res.redirect '/settings'

routes.settingsPassword = (req, res) ->
  res.render 'settings',
    title: '更新密码',
    active: 'password'

routes.settingsPasswordPOST = (req, res) ->
  oldPassword = req.body.oldPassword
  newPassword = req.body.newPassword
  confirmPassword = req.body.confirmPassword
  errors = []
  if newPassword isnt confirmPassword
    errors.push '新密码两次填写不相符'
  if not oldPassword or not newPassword or not confirmPassword
    errors.push '表单填写不完整'
  if errors.length > 0
    res.render 'settings',
      title: '更新密码',
      active: 'password',
      errors: errors
    return
  else
    M.user.findOne().where(uid: req.session.user.uid).exec (err, gotUser) ->
      if not bcrypt.compareSync(newPassword, gotUser.password)
        errors.push '旧密码错误'
        res.render 'settings',
          title: '更新密码',
          active: 'password',
          errors: errors
        return
      else
        res.send 'good'

routes.settingsAvatar = (req, res) ->
  res.render 'settings',
    title: '修改头像'
    active: 'avatar'

routes.ideaHeart = (req, res) ->
  idea_id = req.body.idea_id
  type = req.body.type
  uid = req.session.user.uid
  M.idea.findOne
    idea_id: idea_id
  , (err, gotIdea) ->
    hearts = gotIdea.hearts
    if type is 'heart' and not H.checkInArray(hearts, uid)
      hearts[hearts.length] = uid
    else if type is 'unheart' and H.checkInArray(hearts, uid)
      hearts = H.removeInArray(hearts, uid)
    M.idea.findOneAndUpdate
      idea_id: idea_id
    , hearts: hearts
    , { new: true }
    , (err, result) ->
      res.json result.hearts

routes.idea = (req, res) ->
  slug = req.params.slug
  salt = req.params.salt
  M.idea.findOne
    $and:
      [{slug: slug}, {salt: salt}]
  , (err, gotIdea) ->
    query = 
      uid:
        $in: gotIdea.hearts
    M.user.find().where(query).exec (err, supporters) ->
      gotIdea.description = H.md H.xss gotIdea.description
      if gotIdea and req.session.user
        if H.checkInArray(gotIdea.hearts, req.session.user.uid)
          gotIdea.hearted = true
        else
          gotIdea.hearted = false
      M.user.findOne().where(uid: gotIdea.uid).exec (err, author) ->
        res.render 'idea',
          idea: gotIdea
          title: gotIdea.title
          supporters: supporters
          author: author

routes.ideaComments = (req, res) ->
  idea_id = req.body.idea_id
  query = 
    idea_id: idea_id
  M.comment.find().populate('user').where(query).exec (err, comments) ->
    if comments
      for k,v of comments
        comments[k].content = H.md H.xss v.content
        comments[k].timeago = H.timeago v.createdAt
    res.json comments

routes.commentAdd = (req, res) ->
  comment = 
    uid: req.session.user.uid
    idea_id: req.body.idea_id
    content: req.body.content
    user: req.session.user._id
  comment = new M.comment(comment)
  comment.save (err) ->
    comment.populate('user').populate (err, result) ->
      M.idea.findOneAndUpdate
        idea_id: comment.idea_id
      , $inc:
        comments: 1
      , (err, updated) ->
        regex = /(^|\s)@(\w*[a-zA-Z_]+\w*)/gm # /@([a-zA-Z0-9\_]+\.?)/g
        mentioned_users = comment.content.match regex || []
        console.log mentioned_users
        if req.body.idea_username isnt req.session.user.username
          mentioned_users.push '@' + req.body.idea_username      
        if mentioned_users and mentioned_users.length > 0
          mentioned_users = H.arrayUnique mentioned_users
          for k,v of mentioned_users
            mentioned_users[k] = v.substr(1)
          M.user.update
            username:
              $in: mentioned_users
          , $inc:
              notifications: 1
          , (err, users_updated) ->
            noties = []
            for k,v of mentioned_users
              noties[k] = 
                comment: result._id
                idea: req.body.idea_object_id
                to_user: v
                from_user: req.session.user._id
                type: 'comment'
            M.notification.create noties, (err, noties_updated) ->
              console.log noties_updated
        result.content = H.md H.xss result.content
        res.json
          status: 'good'
          comment: result

routes.notificationsCount = (req, res) ->
  M.user.findOne().where(uid: req.session.user.uid).exec (err, gotUser) ->
    res.json 
      unread: gotUser.notifications

routes.notifications = (req, res) ->
  M.notification.find().limit(30).sort(createdAt: -1).where(to_user: req.session.user.username).populate('idea comment from_user').exec (err, noties) ->
    res.render 'notifications',
      title: '消息提醒'
      noties: noties

routes.clearNotifications = (req, res) ->
  M.user.findOneAndUpdate
    uid: req.session.user.uid
  , notifications: 0
  , (err, result) ->
    res.json
      status: 'good'

routes.people = (req, res) ->
  username = req.params.username
  M.user.findOne().where(username: username).exec (err, gotUser) ->
    M.idea.find().where(hearts: gotUser.uid).populate('user').exec (err, ideas) ->
      if ideas
        for k,v of ideas
          ideas[k].author = v.user[0]
          ideas[k].description = H.stripTags H.md H.xss v.description
          if req.session.user
            if H.checkInArray(v.hearts, req.session.user.uid)
              ideas[k].hearted = true
            else
              ideas[k].hearted = false
        ideas = H.sort ideas
      res.render 'people',
        title: gotUser.username
        userinfo: gotUser
        ideas: ideas
        usertab: 'loves'

routes.peopleIdeas = (req, res) ->
  username = req.params.username
  M.user.findOne().where(username: username).exec (err, gotUser) ->
    M.idea.find().where(uid: gotUser.uid).populate('user').exec (err, ideas) ->
      if ideas
        for k,v of ideas
          ideas[k].author = v.user[0]
          ideas[k].description = H.stripTags H.md H.xss v.description
          if req.session.user
            if H.checkInArray(v.hearts, req.session.user.uid)
              ideas[k].hearted = true
            else
              ideas[k].hearted = false
        ideas = H.sort ideas
      res.render 'people',
        title: gotUser.username
        userinfo: gotUser
        ideas: ideas
        usertab: 'ideas'
  