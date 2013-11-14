derby = require 'derby'
moment = require 'moment'
app = derby.createApp(module)
  .use(require '../../ui')

focusEnter = ->
  el = document.getElementById 'enter'
  el.focus()

scrollDown = ->
  el = document.getElementById 'chat'
  el.scrollTop = el.scrollHeight

app.get '*', (page, model, params, next) ->
  threadQuery = model.query 'threads',
    $orderby: {lastMessageDate: -1}

  model.subscribe 'threads', 'users', (err) ->
    return next(err) if err

    userId = model.get '_session.userId'
    model.ref '_page.user', 'users.' + userId
    if not model.get '_page.user.id'
      model.set '_page.user.id', userId
    model.filter('users').ref '_page.users'
    next()

app.get '/', (page, model, params, next) ->
  messageQuery = model.query 'messages',
    threadId: null
    $orderby: {date: 1}

  model.subscribe messageQuery, (err) ->
    return next(err) if err

    messageQuery.ref '_page.messages'
    page.render()

app.get '/threads/:id', (page, model, params, next) ->
  threadId = params.id
  messageQuery = model.query 'messages',
    $or: [{threadId: threadId}, {baseId: threadId}]
    $orderby: {date: 1}

  model.subscribe messageQuery, (err) ->
    return next(err) if err

    messageQuery.ref '_page.messages'
    model.set '_page.threadId', threadId
    model.ref '_page.thread', 'threads.' + threadId
    page.render()

app.enter '*', (model) ->
  focusEnter()
  scrollDown()
  model.on 'insert', '_page.messages', ->
    scrollDown()

  sortFn = (a, b) ->
    b.lastMessageDate - a.lastMessageDate
  model.sort('threads', sortFn).ref '_page.threads'

app.ready (model) ->
  favicon = new Favico {animation: 'popFade'}
  isActive = true
  badge = 0
  window.onfocus = ->
    isActive = true
    badge = 0
    favicon.reset()
  window.onblur = ->
    isActive = false

  incrementBange = ->
    if not isActive
      badge++
      favicon.badge badge
  
  model.on 'load', 'messages.*', ->
    incrementBange()
  model.on 'change', 'threads.*.messageCount', ->
    incrementBange()
  #model.on 'all', '**', ->
  #  console.log arguments


app.fn 'message.add', (e, el) ->
  model = @model
  if e.keyCode is 13
    e.preventDefault()
    text = model.del '_page.text'

    if text
      message =
        date: 9999999999999
        text: text
        userId: model.get '_session.userId'

      threadId = model.get '_page.threadId'
      answerMessageId = model.del '_page.answerMessageId'
      if answerMessageId
        $answerMessage = model.at 'messages.' + answerMessageId

        thread =
          name: model.get '_page.threadName'
          color: '#'+(0x1000000+(Math.random())*0xffffff).toString(16).substr(1,6)
          messageCount: 1

        threadId = model.add 'threads', thread, (err) ->
          model.set 'messages.' + answerMessageId + '.baseId', threadId
          message.threadId = threadId
          model.add 'messages', message
      else
        message.threadId = threadId
        model.add 'messages', message


app.fn 'thread.add', (e, el) ->
  messageId = el.getAttribute 'data-id'
  text = @model.get 'messages.' + messageId + '.text'
  @model.set '_page.threadName', text
  @model.set '_page.answerMessageId', messageId
  focusEnter()

app.fn 'thread.cancel', (e, el) ->
  @model.del '_page.answerMessageId'

app.view.fn 'color', (threadId) ->
  thread = @model.get 'threads.' + threadId
  thread?.color or 'black'

getUserName = (model, userId) ->
  name = model.get 'users.' + userId + '.name'
  name or 'Anonymous'

app.view.fn 'name', (userId) ->
  getUserName @model, userId

app.view.fn 'shortName', (userId) ->
  name = getUserName @model, userId
  if name.length > 10
    name = name.substr(0, 9) + '..'
  name

app.view.fn 'thread', (threadId) ->
  thread = @model.get 'threads.' + threadId
  if thread and thread.name
    if thread.name.length > 20
      return thread.name.substr(0, 19) + '..'
    return thread.name
  ''