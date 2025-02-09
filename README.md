<div align="center">

# trail_marker.nvim
#### Hike frequented code paths

</div>

## Table of Contents
* [What are Trail Markers](#what-are-trail-markers)
* [Installation](#installation)
* [Example Keymaps](#example-keymaps)
* [Roadmap](#roadmap)


## What are Trail Markers
Trail markers highlight specific points in your code. Multiple trail markers make a trail. Trail markers are meant
to be traversed in order to guide you down a specific code path. Multiple trails can exist per project and trails are
always persisted through restarts, allowing you to go on your favorite hikes again and again.

Trail markers differ from [marks](https://neovim.io/doc/user/motion.html#mark-motions) in that you don't assign them
a letter. An ordered relationship is fundamental to the way trail markers are designed to be used. These aren't marks,
they're something slightly different.

The [jumplist](https://neovim.io/doc/user/motion.html#jump-motions) is the closest parallel to trail markers. Think of
trail markers as a more intentional jumplist that only populates when you tell it. No more smashing `<C-o>` to get
where you need to go.

Trail markers function as a hybrid of marks and the jumplist.

## Installation

Install using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "ryanburda/trail_marker.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
}
```


## Example Keymaps

Trail Markers doesn't assign any default keymaps. The following should be modified to your liking and added to
your config.

```lua
vim.keymap.set(
  'n',
  <leader>tm,
  require("trail_marker").trail_map,
  { desc = "Trail Markers: List markers on current trail" }
)

vim.keymap.set(
  'n',
  <leader>ta,
  require("trail_marker").place_marker,
  { desc = "Trail Markers: Add marker to current trail" }
)

vim.keymap.set(
  'n',
  <leader>tj,
  require("trail_marker").next_marker,
  { desc = "Trail Markers: Go to next marker" }
)

vim.keymap.set(
  'n',
  <leader>tk,
  require("trail_marker").prev_marker,
  { desc = "Trail Markers: Go to previous marker" }
)

vim.keymap.set(
  'n',
  <leader>tgg,
  require("trail_marker").trail_head,
  { desc = "Trail Markers: Go to start of trail" }
)

vim.keymap.set(
  'n',
  <leader>tG,
  require("trail_marker").trail_end,
  { desc = "Trail Markers: Go to end of trail" }
)

vim.keymap.set(
  'n',
  <leader>tn,
  require("trail_marker").new_trail,
  { desc = "Trail Markers: Start a new trail" }
)

vim.keymap.set(
  'n',
  <leader>tc,
  require("trail_marker").change_trail,
  { desc = "Trail Markers: Change trails" }
)
```


## Roadmap
- Visual indicators
  - Trail markers in gutter
  - Winbar support (show previous trail marker line)
- Code preview window
- Trail sharing
- Export as Github links


##
~ Happy Hiking!
