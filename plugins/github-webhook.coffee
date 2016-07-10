{Plugin, dependencies, configuration} = require 'plugin'
{Promise} = dependencies
{exec} = require 'child_process'

class GitHubWebHookPlugin extends Plugin
  transformExpressApp: (app) ->
    app.post '/github/update', (req, res) ->
      # Please set up HTTP Basic authentication on the path '/github/update'
      # And then setup a proper webhook pointing to this address
      res.sendStatus 200
      console.log 'Updating local repository'
      exec 'git pull && git submodule update', (err, stdout, stderr) ->
        console.error err if err
        console.log stdout
        configuration.reload()

module.exports = new GitHubWebHookPlugin