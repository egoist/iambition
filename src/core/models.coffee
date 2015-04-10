mongoose = require 'mongoose'
mongo_uri = process.env.IAM_MONGO_URI || 'mongodb://localhost/iambition'
connection = mongoose.connect mongo_uri
Schema = mongoose.Schema
timestamps = require 'mongoose-timestamp'
autoIncrement = require 'mongoose-auto-increment'

autoIncrement.initialize connection

# initialize
UserSchema = new Schema
  username: String
  email: 
    type: String
    required: true
  is_active: 
    type: Boolean
    default: false
  tags:
    type: String
  introduction:
    type: String
  avatar:
    type: String
  gravatar:
    type: String
  password: 
    type: String
  notifications:
    type: Number
    default: 0

UserSchema.plugin timestamps
UserSchema.plugin autoIncrement.plugin,
  model: 'User',
  field: 'uid'
User = mongoose.model 'User', UserSchema

IdeaSchema = new Schema
  uid: Number
  user: 
    [
      ref: 'User',
      type: Schema.Types.ObjectId
    ]
  title: 
    type: String
    required: true
  description: 
    type: String
  slug:
    type: String
  salt:
    type: String
  hearts:
    type: Array
  comments:
    type: Number
    default: 0
  score:
    type: Number
  timeago:
    type: String

IdeaSchema.plugin timestamps
IdeaSchema.plugin autoIncrement.plugin,
  model: 'Idea',
  field: 'idea_id'
Idea = mongoose.model 'Idea', IdeaSchema

CommentSchema = new Schema
  uid: Number
  user: 
    [
      ref: 'User',
      type: Schema.Types.ObjectId
    ]
  idea_id: Number
  content: 
    type: String

CommentSchema.plugin timestamps
CommentSchema.plugin autoIncrement.plugin,
  model: 'Comment',
  field: 'comment_id'
Comment = mongoose.model 'Comment', CommentSchema

NotificationSchema = new Schema
  comment:
    [
      ref: 'Comment'
      type: Schema.Types.ObjectId
    ]
  idea:
    [
      ref: 'Idea'
      type: Schema.Types.ObjectId
    ]
  to_user: String
  from_user: 
    [
      ref: 'User',
      type: Schema.Types.ObjectId
    ]
  type: 
    type: String

NotificationSchema.plugin timestamps
NotificationSchema.plugin autoIncrement.plugin,
  model: 'Notification',
  field: 'notification_id'
Notification = mongoose.model 'Notification', NotificationSchema

module.exports = 
  user: User
  idea: Idea
  comment: Comment
  notification: Notification