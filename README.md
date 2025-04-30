<div align="center">

# trail_marker.nvim
#### Hike frequented code paths

</div>

## Table of Contents
* [What are Trail Markers](#what-are-trail-markers)
* [Installation](#installation)
* [Getting Started](#getting-started)


## What are Trail Markers
Trail markers highlight specific points in your code, forming a sequenced path known as a trail. Designed to guide you
through a particular execution path, these trails can be created and customized for each project, and they persist even
after restarts, allowing for repeated exploration of specific code paths.

Unlike traditional [marks](https://neovim.io/doc/user/motion.html#mark-motions), trail markers don't require
you to assign a letter, freeing you from the need to remember mark names. The core philosophy of trail markers is
their ordered relationship, making navigation intuitive and efficient.

While they share some similarities with the [jumplist](https://neovim.io/doc/user/motion.html#jump-motions), trail
markers offer a more intentional approach. They populate only when you instruct them to, eliminating the need to
repeatedly press `<C-o>`/`<C-i>` to find your desired location.

In essence, trail markers blend the functionalities of marks and the jumplist, providing a powerful navigational tool
within your Neovim workflow.

TODO: include video

## Installation

Install using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "ryanburda/trail_marker.nvim",
}
```

## Getting Started
To learn more about Trail Marker, its commands, and how it can be configured visit the help file:
```
:help trail_marker.txt
```

##
~ Happy Hiking!
