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
      description: 'the path to the `php` executable.'
    phpArguments:
      title: 'Add PHP arguments'
      type: 'array'
      default: []
      description: 'Add arguments, like for example `-n`, to the PHP executable.'
    executablePath:
      title: 'PHP-CS-fixer executable path'
      type: 'string'
      default: 'php-cs-fixer'
      description: 'the path to the `php-cs-fixer` executable.'
    configPath:
       title: 'PHP-CS-fixer config file path'
       type: 'string'
       default: ''
       description: 'optionally provide the path to the `.php_cs` config file, if the path is not provided it will be loaded from the root path of the current project.'
    rules:
      title: 'Rules'
      type: 'string'
      default: ''
      description: 'a list of rules (based on php-cs-fixer 2.0), for example: `@PSR2,no_short_echo_tag,indentation_type`. See <https://github.com/FriendsOfPHP/PHP-CS-Fixer#usage> for a complete list. Will be ignored if a config file is used.'
    executeOnSave:
      title: 'Execute on save'
      type: 'boolean'
      default: false
      description: 'execute PHP CS fixer on save'
    allowRisky:
      title: 'Allow risky'
      type: 'boolean'
      default: false
      description: 'option allows you to set whether risky rules may run. Will be ignored if a config file is used.'
    showInfoNotifications:
      title: 'Show notifications'
      type: 'boolean'
      default: false
      description: 'show some status informations from the last "fix".'

  activate: (state) ->
    atom.config.observe 'php-cs-fixer.executeOnSave', =>
      @executeOnSave = atom.config.get 'php-cs-fixer.executeOnSave'

    atom.config.observe 'php-cs-fixer.phpExecutablePath', =>
      @phpExecutablePath = atom.config.get 'php-cs-fixer.phpExecutablePath'

    atom.config.observe 'php-cs-fixer.executablePath', =>
      @executablePath = atom.config.get 'php-cs-fixer.executablePath'

    atom.config.observe 'php-cs-fixer.configPath', =>
      @configPath = atom.config.get 'php-cs-fixer.configPath'

    atom.config.observe 'php-cs-fixer.allowRisky', =>
      @allowRisky = atom.config.get 'php-cs-fixer.allowRisky'

    atom.config.observe 'php-cs-fixer.rules', =>
      @rules = atom.config.get 'php-cs-fixer.rules'

    atom.config.observe 'php-cs-fixer.showInfoNotifications', =>
      @showInfoNotifications = atom.config.get 'php-cs-fixer.showInfoNotifications'

    atom.config.observe 'php-cs-fixer.phpArguments', =>
      @phpArguments = atom.config.get 'php-cs-fixer.phpArguments'

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

    args = []

    if @phpArguments.length
      if @phpArguments.length > 1
        args = @phpArguments
      else
        args = @phpArguments[0].split(' ')

    args = args.concat [@executablePath, 'fix', filePath]

    if @configPath
      args.push '--config=' + @configPath
    else if configPath = @findFile(path.dirname(filePath), '.php_cs')
      args.push '--config=' + configPath

    # add optional options
    args.push '--allow-risky=yes' if @allowRisky and not configPath
    args.push '--rules=' + @rules if @rules and not configPath
    args.push '--using-cache=false'

    # some debug output for a better support feedback
    console.debug('php-cs-fixer Command', command)
    console.debug('php-cs-fixer Arguments', args)

    stdout = (output) ->
      if PhpCsFixer.showInfoNotifications
        if (/^\s*\d*[)]/.test(output))
          atom.notifications.addSuccess(output)
        else
          atom.notifications.addInfo(output)
      console.log(output)

    stderr = (output) ->
      if PhpCsFixer.showInfoNotifications
        if (output.replace(/\s/g,"") == "")
          # do nothing
        else if (/^Loaded config/.test(output)) # temporary fixing https://github.com/pfefferle/atom-php-cs-fixer/issues/35
          atom.notifications.addInfo(output)
        else
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
