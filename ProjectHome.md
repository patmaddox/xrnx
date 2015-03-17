## Welcome ##

... to the Renoise Lua Scripting dev mini-site!

This site targets developers who want to write their own scripts & tools for [Renoise](http://www.renoise.com).

If you are only interested in downloading tools for Renoise, not developing your own tools, then please have a look at the [Renoise Tools Page](http://tools.renoise.com).

<br />
## Getting Started ##

The downloads section on the left contains a starter pack, which is highly recommended for everyone who wants to start getting into all this Renoise scripting. Please download and read this first, in order to get an overview about all that's needed to develop tools for Renoise. It contains example tools, the full API documentation, an introduction text and some code snippets. The starter pack also contains a HTML version of the API reference which is not available online on this site.


<br />
## Documentation & API Reference ##

The main documentation and API references can also be read online, on this site. You'll find them right here in the [XRNX code repository](http://code.google.com/p/xrnx/source/browse/trunk#trunk/Documentation).

Or can view it online here:
[Renoise API Documentation - html](http://files.renoise.com/xrnx/documentation)


<br />
## How to Enable the Scripting Developer Tools in Renoise ##

By default Renoise has all the scripting stuff hidden to keep things as easy as possible for those who don't want to mess around with code. If you want to write scripts, the first thing you have to do is enable the hidden development tools that are built into Renoise. This can be done by:

  * Launching the Renoise executable with the argument "--scripting-dev"

  * Opening Renoise's config.xml file from the preferences folder, and set the `ShowScriptingDevelopmentTools` property to "true". This way, you don't have to pass the above mentioned argument all the time. If you don't know where to find the Renoise preference folder, open Renoise and click on "Help" -> "Show Preferences Folder..."

Enabling this option will add a new main menu entry "Tools" (or add new entries there if it already exists). In the "Tools" menu you will find:

  * "Reload All Tools": This will force a reload of all installed and running scripting tools (extensions). This can be handy when adding new tools by hand or when changing them.

  * "Scripting Console & Editor": This is the main developing scripting tool. It allows you to:
    1. Evaluate scripts or commands in realtime with a small terminal (command-line)
    1. Watch any script's output (all "print"s and errors from scripts will be redirected here)
    1. Create, view and edit Lua, text, and XML files that will make up tools / extensions for Renoise.

Have a look at !Introduction.txt in the [XRNX code repository](http://code.google.com/p/xrnx/source/browse/trunk#trunk/Documentation) for more info.

<br />

## Need More Help? ##

This site is also a Google source repository which already contains various complete scripting tools written by the Renoise team. The existing tools may help you to get more info about how your tools could be done.

For any questions regarding the Lua API, or this repository, have a look at the [Renoise Scripting Development Forum](http://www.renoise.com/board) please.

<br /><br />
_Have fun scripting and hacking Renoise!_