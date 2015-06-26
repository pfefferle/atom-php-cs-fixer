# php-cs-fixer Atom-Package

Run the "[PHP Coding Standards Fixer](http://cs.sensiolabs.org)" within your Atom Editor

![A screenshot of your package](https://raw.github.com/pfefferle/atom-php-cs-fixer/master/php-cs-fixer.gif)

## Installation

```sh
$ apm install php-cs-fixer
```

or find it in the Packages tab under settings

## Requirements

The package requires the "[PHP Coding Standards Fixer](http://cs.sensiolabs.org)" Cli build by [SensioLabs](http://sensiolabs.com).

Installation via Composer

```sh
$ ./composer.phar global require fabpot/php-cs-fixer
```

For other installation methods, see <http://cs.sensiolabs.org/#installation>

## Usage

`ctrl-cmd-s` or **Php Cs Fixer: Fix** in the Command Palette.

(The commands can also be found in the settings-menu of the Package)

## FAQ

### I have updated the plugin to 2.3.0 and it does not work any more

I had to add a new settings-parameter `Php Executable Path` to get the plugin running on Windows, so be sure to check if the new settings is configured properly.
