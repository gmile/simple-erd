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

SimpleERD requires a text file as an input. Such file must contained a text, formatted the a special way:

```
[entity_1]
attribute | type

[entity_2]
attribute | type | modifier

[entity_3]
attribute

(entity_group_1)
entity_1
entity_2

(entity_group_2)
entity_3

entity_1 ?--1 entity_2
entity_3 *--n entity_2
```

Here, `[entity_1]` starts a block, indicating an entity. Right below `[entity_1]` come entity attributes. An entity attribute is defined by a `attribute_name`, `type` (optional and `modifier` (optional).

At the bottom of input file – relations between entities. Syntax for relations:

* `?` – 0 or 1
* `1` – exactly 1
* `*` – 0 or more
* `+` – 1 or more
* `x` – relation is undefined, will render as `???` in the output.

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
