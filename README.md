<div align="center">

# trail_marker.nvim
#### Hike frequented code paths

</div>

## Table of Contents
* [What are Trail Markers](#what-are-trail-markers)
* [Installation](#installation)
* [Getting Started](#getting-started)


## What are Trail Markers
Trail markers highlight specific points in your code. Multiple markers make a trail. Trail markers are meant
to be traversed in order to guide you down a specific code path. Multiple trails can exist per project and
trails are always persisted through restarts, allowing you to go on your favorite hikes again and again.

Trail markers differ from [marks](https://neovim.io/doc/user/motion.html#mark-motions) in that you don't assign them
a letter. An ordered relationship is fundamental to the way trail markers are designed to be used. With trail
markers you don't need to remember how you named your marks.

The [jumplist](https://neovim.io/doc/user/motion.html#jump-motions) is the closest parallel to trail markers. Think of
trail markers as a more intentional jumplist that only populates when you tell it. No more smashing `<C-o>` to get
where you need to go.

Trail markers are a hybrid of marks and the jumplist.

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
