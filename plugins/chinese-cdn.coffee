{Plugin} = require 'plugin'

class ChineseCDNPlugin extends Plugin
  transformRenderResult: ->
    return [false, (content) ->
      content = content.replace /\/\/fonts\.googleapis\.com/g, '//fonts.cat.net'
            .replace /\/\/cdnjs\.cloudflare\.com\/ajax/g, '//cdnjs.cat.net/ajax'
            .replace /\/\/cdn\.materialdesignicons.com/g, '//o92gap2xr.qnssl.com/mdi'

      if process.env.NODE_ENV isnt 'debug'
        content = content.replace /\/assets\/prebuilt/g, '//oa4n7skhk.qnssl.com/assets/prebuilt'

      return content
    ]

module.exports = new ChineseCDNPlugin
