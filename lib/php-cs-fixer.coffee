{CompositeDisposable} = require 'atom'

module.exports = PhpCsFixer =
  subscriptions: null
  spawn: null
  config:
    executablePath:
      type: 'string'
      default: 'php php-cs-fixer.phar'
      description: 'the path to the `php-cs-fixer` executable'
    level:
      type: 'string'
      default: 'psr2'
      description: 'for example: `psr0`, `psr1`, `psr2` or `symfony`'
    fixers:
      type: 'string'
      default: ''
      description: 'a list of fixers, see <http://cs.sensiolabs.org/#usage> for a complete list'


  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'php-cs-fixer:fix': => @fix()

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->

  fix: ->
    atom.config.observe 'php-cs-fixer.executablePath', =>
      @executablePath = atom.config.get 'php-cs-fixer.executablePath'

    atom.config.observe 'php-cs-fixer.level', =>
      @level = atom.config.get 'php-cs-fixer.level'

    atom.config.observe 'php-cs-fixer.fixers', =>
      @fixers = atom.config.get 'php-cs-fixer.fixers'

    editor = atom.workspace.getActivePaneItem()

    filePath = editor.getPath() if editor && editor.getPath

    @spawn ?= require('child_process').spawn

    # init opptions
    options = ['fix', filePath]

    # add optional opptions
    options.push '--level=' + @level if @level
    options.push '--fixers=' + @fixers if @fixers

    result = @spawn(@executablePath, options) if filePath && @spawn

    # some debug output
    result.stdout.on 'data', (data) -> console.debug data.toString().trim()
    result.stderr.on 'data', (data) -> console.debug data.toString().trim()
