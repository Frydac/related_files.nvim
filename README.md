# related_files.nvim

## What

Neovim only plugin to find or create files related to the current buffer.

In a project there are usually files that are related to each other and some convention is used with respect to the their paths. This plugin lets you describe this convention and use it to find related files, or create them if they don't exist already.

## How
### Idea

The idea is that every _type of path_ has a parser function and a generator function: 

* the parser function breaks the path down to some _intermediate representation_
* the generator can use this representation to generate the path from. 

When multiple types of paths can use the same intermediate representation then one type of path can be generated from the other.  

### Example 1

A first basic example (see `examples/001_basic/*`) to explain the concepts:

Say we have a python project with _source_ files and their unit _test_ files with the following convention:  
`/path/to/project/file_a.py`  
`/path/to/project/file_a_test.py`  
Then we have two types of paths, lets name them "source" and "test".
In this example an *intermediate representation* could look like:
```
{
    parent = "/path/to/project",
    name = "file_a"
}
```
These are parts that are common between both the paths in this example. It is not hard to imagine parser and generator functions for both "source" and "test" that work with this intermediate representation, the parser takes a path/string and generates this table, the generator takes this table and generates the path. However writing these functions, even if somewhat trivial, is still a bit of work.  
So as an alternative to writing your own parser and generator functions for each type of path, this plugin provides a basic (and limited) *expression language* to describe the paths. The plugin will then derive the parser and generator functions from this expression. (if too limited you can create your own expression language, the limitations of this built in expression language are explained later).  
For this example, these expressions look like:  
`{"source", "{parent}/{name}.py"}`  
`{"test", "{parent}/{name}_test.py"}`

This combination of the name/expression/parser/generator for each type of path, I've named 'pargen' (not superhappy about it, but yeah.. naming is hard!). So above are 2 pargens, one for the source and one for the test files.

Now how to interact with the plugin to jump from one file to their related file?  

In this example there are 2 related types of paths, and it might be tempting to have a toggle type of key that switches from one to the other, similar to vim's 'alternate-file' idea.  (e.g. see a similar plugin that goes this route: https://github.com/rgroli/other.nvim )
However, in my work I have places with 4 related file types, and a toggle button wouldn't suffice.
I've chosen to go with an index for each type of related path, and by default they are mapped to `<leader>1`, `<leader>2`, `<leader>3` upto 5.
So to define the relation between the above types of paths and assign them to an index, the plugin expects you to describe it as follows:
``
