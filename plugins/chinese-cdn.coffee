{Plugin, dependencies} = require 'plugin'
{Promise} = dependencies

class ChineseCDNPlugin extends Plugin
  transformRenderResult: (result) ->
    promise = Promise.try ->
      result.replace /\/\/fonts\.googleapis\.com/g, '//fonts.css.network'
            .replace /\/\/cdnjs\.cloudflare\.com\/ajax/g, '//cdn.css.net'
            .replace /\/\/cdn\.materialdesignicons.com/g, '//o92gap2xr.qnssl.com/mdi'
    return [true, promise]

module.exports = new ChineseCDNPlugin