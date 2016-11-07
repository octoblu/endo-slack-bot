_                = require 'lodash'
PassportStrategy = require 'passport-strategy'
request          = require 'request'
url              = require 'url'
slack            = require 'slack'

class SlackStrategy extends PassportStrategy
  constructor: (env) ->
    if _.isEmpty env.ENDO_SLACK_BOT_SLACK_CALLBACK_URL
      throw new Error('Missing required environment variable: ENDO_SLACK_BOT_SLACK_CALLBACK_URL')
    if _.isEmpty env.ENDO_SLACK_BOT_SLACK_AUTH_URL
      throw new Error('Missing required environment variable: ENDO_SLACK_BOT_SLACK_AUTH_URL')
    if _.isEmpty env.ENDO_SLACK_BOT_SLACK_SCHEMA_URL
      throw new Error('Missing required environment variable: ENDO_SLACK_BOT_SLACK_SCHEMA_URL')
    if _.isEmpty env.ENDO_SLACK_BOT_SLACK_FORM_SCHEMA_URL
      throw new Error('Missing required environment variable: ENDO_SLACK_BOT_SLACK_FORM_SCHEMA_URL')


    @_authorizationUrl = env.ENDO_SLACK_BOT_SLACK_AUTH_URL
    @_callbackUrl      = env.ENDO_SLACK_BOT_SLACK_CALLBACK_URL
    @_schemaUrl        = env.ENDO_SLACK_BOT_SLACK_SCHEMA_URL
    @_formSchemaUrl    = env.ENDO_SLACK_BOT_SLACK_FORM_SCHEMA_URL
    @_apiUrl           = env.ENDO_SLACK_BOT_SLACK_API_URL
    super

  authenticate: (req) -> # keep this skinny
    {bearerToken} = req.meshbluAuth
    {token} = req.body
    return @redirect @authorizationUrl({bearerToken}) unless token?
    @getUserRecordFromSlack {token}, (error, user) =>
      return @fail 401 if error? && error.code < 500
      return @error error if error?
      return @fail 404 unless user?
      @success {
        id:       user.user_id
        username: user.user
        secrets:
          credentials: {secret: token}
      }

  authorizationUrl: ({bearerToken}) ->
    {protocol, hostname, port, pathname} = url.parse @_authorizationUrl
    query = {
      postUrl: @postUrl()
      schemaUrl: @schemaUrl()
      formSchemaUrl: @formSchemaUrl()
      bearerToken: bearerToken
    }
    return url.format {protocol, hostname, port, pathname, query}

  formSchemaUrl: ->
    @_formSchemaUrl

  getUserRecordFromSlack: ({token}, callback) =>
    slack.auth.test {token}, callback

  postUrl: ->
    {protocol, hostname, port} = url.parse @_callbackUrl
    return url.format {protocol, hostname, port, pathname: '/auth/api/callback'}

  schemaUrl: ->
    @_schemaUrl

  _userError: (code, message) =>
    error = new Error message
    error.code = code
    return error

module.exports = SlackStrategy
