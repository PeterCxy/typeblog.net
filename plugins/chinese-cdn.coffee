{Plugin} = require 'plugin'

class ChineseCDNPlugin extends Plugin
  transformRenderResult: ->
    return [false, (content) ->
      content = content.replace /\/\/fonts\.googleapis\.com/g, '//fonts.cat.net'
            .replace /\/\/cdnjs\.cloudflare\.com\/ajax/g, '//cdnjs.cat.net/ajax'

      return content
    ]

module.exports = new ChineseCDNPlugin
