redis=require('redis')
_=require('underscore')
emitter = require('events').EventEmitter

defaultRedisHost = '127.0.0.1'
defaultPort = 6379
defaultApiVersion = '1.0'

class EasyRpc extends emitter
  constructor: (@local_address,@remote_address,api_list,options) ->
    options = options or {}
    @host = options.host || defaultRedisHost
    @port = options.port || defaultPort
    @api_response_pending = {}
    @redisClientS = redis.createClient @port,@host
    @redisClientR = redis.createClient @port,@host
    @sendMessages
      jsonrpc: defaultApiVersion
      method: 'connect'
      params:
        api_list:api_list
    @readMessages()
          
  readMessages: ->
    @redisClientR.brpop @local_address+'easyrpc_mesg_q', 0, (err, data) =>
      if err
        throw "Stopping readMessages loop as recieved error from redis #{err}"

      message_object = JSON.parse data[1]
      #console.log 'recieved data:',data[1]

      switch message_object.method
        when 'connect'
          @remote_api_list = message_object.params.api_list
          _.each @remote_api_list,(remote_api)=>
            EasyRpc::[remote_api] = (params,callback)=>
              @redisClientR.incr 'easyrpc_ApiResponseCounter',(err,id) =>
                if err
                  callback err,null
                  return
                
                @api_response_pending[id] = callback
                @sendMessages
                  jsonrpc: defaultApiVersion
                  method: 'ApiPost'
                  api:remote_api
                  id:id
                  params: params

          @emit 'connect'

        when 'ApiPost'
          @emit message_object.api,message_object.params,(err,result)=>
            @sendMessages
                jsonrpc: defaultApiVersion
                method: 'ApiResponse'
                api:message_object.api
                id:message_object.id
                params: 
                  err:err
                  result:result

        when 'ApiResponse'
          callback = @api_response_pending[message_object.id]
          if callback
            callback message_object.params.err,message_object.params.result
            delete @api_response_pending[message_object.id]
        
        else
          @emit message_object.method,message_object.params
      
      @readMessages()

  sendMessages: (message)->
    message_str = JSON.stringify(message)
    @redisClientS.lpush @remote_address+'easyrpc_mesg_q', message_str, (err, res) ->
      if err
        throw "pressMsgSender: Error sending message #{message_str}"

module.exports = EasyRpc;