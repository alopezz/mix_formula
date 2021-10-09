# Mix Formula

*Mix Formula* is a generic template based project generator,
implemented as a *mix task*.

It's heavily inspired by
[cookiecutter](https://github.com/cookiecutter/cookiecutter), and
serves a very similar purpose, with Elixir replacing Python and EEx
replacing Jinja2.

## Installation

```
mix archive.install hex mix_formula
```

## Usage

A template is a folder containing at least:

- A folder with a name containing EEx tags, which will represent the
  root of the generated project.
- A `formula.json` file, which is a mapping from fields to default values.

The structure inside the root folder will be used for generating new
projects from it. A project generated through *mix formula* will
essentially be a copy of the root folder, with every element (folder
and file names and file contents) rendered with EEx. File
names that evaluate to a falsy value or an empty string will be
omitted from the generated project.

Values inside `formula.json` can also be templates, and will be rendered
with EEx.

Current usage is limited to non-interactive use.

```
mix formula <path/to/template> [<formula_field>=<formula_value> ...]
```

Only *formula fields* defined in `formula.json` can be set in the
command line invocation. Any unset field will default to the value
defined on `formula.json`.

For example:

```
mix formula examples/elixir-project \
  name=my_cool_project \
  project_name="My cool Project" \
  short_description="This project is cool"
```

### Writing templates

Templates are rendered using
[EEx](https://hexdocs.pm/eex/1.12/EEx.html). Refer to its
documentation for details on its use.

Some things to have in mind when writing EEx for *mix formula*
templates:

- Remember to include the equals sign (`=`) in order for a tagged
  expression to actually get rendered, i.e. `<%= expr %>`.
- If you have EEx files within your template, where the *output* of
  the template should contain EEx code, remember that you'll need to
  escape the expressions that you actually want to output with an
  additional `%`, i.e. `<%%= expr %>`.

### Hooks

A template can also define hooks to be run before and after project
generation. *mix formula* will look into the `hooks` folder in a
template and load all `.ex` and `.exs` files contained there. Modules
that `use MixFormula.Hook` have access to `pre_hook` and `post_hook`
macros to define hooks for the template.

For now, you can look at the examples in
[test_templates](./test_templates) to learn more about how to use
them.
