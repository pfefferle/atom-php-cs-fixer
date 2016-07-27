{CompositeDisposable} = require 'atom'
{BufferedProcess} = require 'atom'
fs = require 'fs'
path = require 'path'

module.exports = PhpCsFixer =
  subscriptions: null
  config:
    phpExecutablePath:
      title: 'PHP executable path'
      type: 'string'
      default: 'php'
      description: 'the path to the `php` executable'
    executablePath:
      title: 'PHP-CS-fixer executable path'
      type: 'string'
      default: 'php-cs-fixer'
      description: 'the path to the `php-cs-fixer` executable'
    level:
      title: 'Level'
      type: 'string'
      enum: ['psr0', 'psr1', 'psr2', 'symfony']
      default: 'psr2'
      description: 'for example: psr0, psr1, psr2 or symfony'
    fixers:
      title: 'Fixers'
      type: 'string'
      default: ''
      description: 'a list of fixers, for example: `linefeed,short_tag,indentation`. See <http://cs.sensiolabs.org/#usage> for a complete list'
    executeOnSave:
      title: 'Execute on save'
      type: 'boolean'
      default: false
      description: 'execute PHP CS fixer on save'
    showInfoNotifications:
      title: 'Show notifications'
      type: 'boolean'
      default: false
      description: 'show some status informations from the last "fix"'
    runPhpWithoutAnyIni:
      title: 'Run php with the -n flag'
      type: 'boolean'
      default: false
      description: 'Runs php without any ini configuration, useful for avoiding xdebug errors'

  activate: (state) ->
    atom.config.observe 'php-cs-fixer.executeOnSave', =>
      @executeOnSave = atom.config.get 'php-cs-fixer.executeOnSave'

    atom.config.observe 'php-cs-fixer.phpExecutablePath', =>
      @phpExecutablePath = atom.config.get 'php-cs-fixer.phpExecutablePath'

    atom.config.observe 'php-cs-fixer.executablePath', =>
      @executablePath = atom.config.get 'php-cs-fixer.executablePath'

    atom.config.observe 'php-cs-fixer.level', =>
      @level = atom.config.get 'php-cs-fixer.level'

    atom.config.observe 'php-cs-fixer.fixers', =>
      @fixers = atom.config.get 'php-cs-fixer.fixers'

    atom.config.observe 'php-cs-fixer.showInfoNotifications', =>
      @showInfoNotifications = atom.config.get 'php-cs-fixer.showInfoNotifications'

    atom.config.observe 'php-cs-fixer.runPhpWithoutAnyIni', =>
      @runPhpWithoutAnyIni = atom.config.get 'php-cs-fixer.runPhpWithoutAnyIni'

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'php-cs-fixer:fix': => @fix()

    # Add workspace observer and save handler
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      @subscriptions.add editor.getBuffer().onWillSave =>
        if editor.getGrammar().name == "PHP" and @executeOnSave
          @fix()

  deactivate: ->
    @subscriptions.dispose()

  fix: ->
    editor = atom.workspace.getActivePaneItem()

    filePath = editor.getPath() if editor && editor.getPath

    command = @phpExecutablePath

    console.debug('php-cs-fixer Running with no INI?', @runPhpWithoutAnyIni);

    # init options
    if @runPhpWithoutAnyIni
        args = ['-n', @executablePath, 'fix', filePath]
    else
        args = [@executablePath, 'fix', filePath]

    if configPath = @findFile(path.dirname(filePath), '.php_cs')
      args.push '--config-file=' + configPath

    # add optional options
    args.push '--level=' + @level if @level and not configPath
    args.push '--fixers=' + @fixers if @fixers and not configPath

    # some debug output for a better support feedback
    console.debug('php-cs-fixer Command', command)
    console.debug('php-cs-fixer Arguments', args)

    stdout = (output) ->
      if PhpCsFixer.showInfoNotifications
        if (/^Fixed/.test(output))
          atom.notifications.addSuccess('Your code looks perfect... nothing to fix!')
        else if (/^\s*\d*[)]/.test(output))
          atom.notifications.addSuccess(output)
        else
          atom.notifications.addInfo(output)
      console.log(output)

    stderr = (output) ->
      atom.notifications.addError(output)
      console.error(output)

    exit = (code) -> console.log("#{command} exited with code: #{code}")

    process = new BufferedProcess({
      command: command,
      args: args,
      stdout: stdout,
      stderr: stderr,
      exit: exit
    }) if filePath

  # copied from the AtomLinter lib
  # see: https://github.com/AtomLinter/atom-linter/blob/master/lib/helpers.coffee#L112
  #
  # The AtomLinter is licensed under "The MIT License (MIT)"
  #
  # Copyright (c) 2015 AtomLinter
  #
  # See the full license here: https://github.com/AtomLinter/atom-linter/blob/master/LICENSE
  findFile: (startDir, names) ->
    throw new Error "Specify a filename to find" unless arguments.length
    unless names instanceof Array
      names = [names]
    startDir = startDir.split(path.sep)
    while startDir.length
      currentDir = startDir.join(path.sep)
      for name in names
        filePath = path.join(currentDir, name)
        try
          fs.accessSync(filePath, fs.R_OK)
          return filePath
      startDir.pop()
    return null
