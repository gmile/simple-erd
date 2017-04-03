# SimpleERD

SimpleERD is a tool to generate beautiful ERD digrams from plain text.

SimpleERD started out as an experiment and is currently at its early stage of development. Consider it a working prototype. SimpleERD is written in Ruby, but this is likely subject for a change.

## Installation

There are two installation options on macOS:

* via [`homebrew`](https://brew.sh):

  ```bash
  $ brew tap gmile/apps
  $ brew install simple-erd --HEAD
  ```

* via [`rubygems`](https://rubygems.org):

  1. make sure to have `graphviz` installed:

      ```bash
      $ brew install graphviz
      ```

  2. intall the gem:

      ```bash
      $ gem install simple-erd
      ```

## Usage

```bash
$ simple_erd -i input.txt -o output.pdf
```

## Examples

```bash
$ simple-erd -i samples/complex_input.txt -o /tmp/output.pdf
```

See [/samples](/samples) for more samples.

## Motivation

I was inspired by [`erd`](https://github.com/BurntSushi/erd) from [Andrew Gallant](https://github.com/BurntSushi), but had a couple of issues with it:

* mainly I found it hard, although possible, to install:

  * `erd` requires haskell runtime to be available, which takes around 1Gb when installed.
  * it is required to install `cabal` and all of `erd`'s dependencies manually.

* the libarary doesn't seem to be actively maintained.

Also, I wanted to work on the custom styling of the diagram.

## Licence

MIT
