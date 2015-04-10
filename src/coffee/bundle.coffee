body = $('body')
date = new Date
date.setHours(0,0,0,0)
date_from = new Date(date)
date_between = 3

tagsinput_opt =
  defaultText: ''
  width: '100%'
  height: 'auto'

$(document).pjax 'a', '.wrap', 
  fragment: '.wrap',
  timeout: 10000

$('.wrap').on 'pjax:start', ->
  appLoading.start()

$('.wrap').on 'pjax:end', ->
  appLoading.stop()
  init()

window.paceOptions = 
  restartOnRequestAfter: false

$ ->
  init()
  
  body
    .on 'click', '#idea-submit', ->
      return if not login
      title = $.trim $('#title').val()
      description = $.trim $('#description').val()
      has_error = false
      if not title
        $('#title').parent().addClass('has-error')
        has_error = true
      else
        $('#title').parent().removeClass('has-error')
        has_error = false
      if not description
        $('#description').parent().addClass('has-error')
        has_error = true
      else
        $('#description').parent().removeClass('has-error')
        has_error = false
      if not has_error
        $.post '/ideas/new', 
          title: title
          description: description
        , (data) ->
          if data.status is 'good'
            $.pjax
              url: '/'
              container: '.wrap'
    .on 'click', '.unhearted', ->
      if not login
        goLogin()
        return 
      el = $(this)
      idea_id = el.data('idea-id')
      el.removeClass('unhearted').addClass('hearted')
      hearts = parseInt el.find('span').html()
      el.find('span').html hearts + 1
      $.post '/idea/heart',
        idea_id: idea_id
        type: 'heart'
      , (data) ->
        console.log data
    .on 'click', '.hearted', ->
      if not login
        goLogin()
        return 
      el = $(this)
      idea_id = el.data('idea-id')
      el.addClass('unhearted').removeClass('hearted')
      hearts = parseInt el.find('span').html()
      el.find('span').html hearts - 1
      $.post '/idea/heart',
        idea_id: idea_id
        type: 'unheart'
      , (data) ->
        console.log data
    .on 'click', '#comment-submit', ->
      return if not login
      content = $.trim $('#comment').val()
      if content
        $.post '/comment/add',
          content: content
          idea_id: idea_id
          idea_username: idea_username
          idea_object_id: idea_object_id
        , (data) ->
          console.log data.comment.user
          data.comment.user = data.comment.user[0]
          template = $('#comment-template').html()
          Mustache.parse template
          rendered = Mustache.render template, data.comment
          $('.comments-list').append(rendered)
          $('#comment').val('')
    .on 'click', '.idea-reply', ->
      prefix = '@' + $(this).data('username') + ' '
      content = $('#comment').val()
      $('#comment').val(prefix + content).focus()
    .on 'click', '#load', ->
      load()


init = ->
  date = new Date
  date.setHours(0,0,0,0)
  date_from = new Date(date)
  date_between = 3
  autosize $('textarea')
  $('#tags').tagsInput(tagsinput_opt)
  $('[data-toggle="tooltip"]').tooltip()
  checkNotifications()
  loadBefore()
  loadPage()
  loadComments()
  clearNotifications()

loadComments = ->
  if typeof mode isnt 'undefined' and mode is 'idea'
    $.post '/idea/comments',
      idea_id: idea_id
    , (data) ->
      if data.length > 0
        for v,k in data
          data[k].user = v.user[0]
          data[k].timeago = timeago v.createdAt
        template = $('#comments-template').html()
        Mustache.parse template
        rendered = Mustache.render template, 
          comments: data
        $('.comments-list').html(rendered)
      else
         $('.comments-list').find('div').html('暂无评论')

timeago = (date) ->
  moment.locale('zh-cn')
  moment(new Date(date)).fromNow()

loadBefore = ->
  return if typeof mode is 'undefined' or mode isnt 'index'
  yesterday = new Date(date)
  yesterday.setDate(yesterday.getDate() - 1)
  $.post '/ideas/date',
    date: yesterday
  , (data) ->
    $('.timeline').append data
    yesterday.setDate(yesterday.getDate() - 1)
    $.post '/ideas/date',
      date: yesterday
    , (data) ->
      $('.timeline').append(data).show()
      $('#load').show()

load = ->
  date_from.setDate(date_from.getDate() - date_between)
  $('#load').html '正在加载...'
  $.post '/ideas/date',
      date: date_from
  , (data) ->
    date_between = 1
    if data
      $('.timeline').append data
      $('#load').html '加载更多'
    else
      $('#load').html '没有人在 '+ timeago(date_from) + ' 发布内容'

checkNotifications = ->
  return if not login
  $.get '/api/notifications/count', (data) ->
    if data.unread > 0
      $('.notie').addClass('has-notie').find('span').html(' ' + data.unread)
    else
      $('.notie').removeClass('has-notie').find('span').html('')

clearNotifications = ->
  return if not login
  if typeof page isnt 'undefined' and page is 'notifications'
    $.post '/notifications/clear',
      type: 'single'
    , (data) ->
      console.log data

goLogin =  ->
  $.pjax
    url: '/signin'
    container: '.wrap'

loadPage = ->
  if typeof snaply isnt 'undefined'
    $.get snaply, (data) ->
      $('.panel-body').html(data)