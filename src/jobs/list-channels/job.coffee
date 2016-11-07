http   = require 'http'
_      = require 'lodash'
slack  = require 'slack'

class ChannelList
  constructor: ({@encrypted}) ->
    @token = @encrypted.secrets.credentials.secret

  do: ({data}, callback) =>
    slack.channels.list { @token }, (error, results) =>
      return callback error if error?
      return callback null, {
        metadata:
          code: 200
          status: http.STATUS_CODES[200]
        data: results
      }

  _userError: (code, message) =>
    error = new Error message
    error.code = code
    return error

module.exports = ChannelList
