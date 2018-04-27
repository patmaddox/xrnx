--[[============================================================================
com.renoise.PhraseMate.xrnx/main.lua
============================================================================]]--
--[[

PhraseMate aims to make it more convenient to work with phrases. Launch the tool from the tool menu, by using the right-click (context-menu) shortcuts in the pattern editor or pattern matrix, or via the supplied keyboard shortcuts / MIDI mappings.

.
#

## Links

Renoise: [Tool page](http://www.renoise.com/tools/phrasemate)

Renoise Forum: [Feedback and bugs](http://forum.renoise.com/index.php/topic/46284-new-tool-31-phrasemate/)

Github: [Documentation and source](https://github.com/renoise/xrnx/tree/master/Tools/com.renoise.PhraseMate.xrnx/) 


]]

--------------------------------------------------------------------------------
-- required files
--------------------------------------------------------------------------------

_trace_filters = nil
--_trace_filters = {".*"}
--_trace_filters = {"^PhraseMate"}

_clibroot = 'source/cLib/classes/'
require (_clibroot..'cLib')
require (_clibroot..'cTable')
require (_clibroot..'cDebug')
require (_clibroot..'cDocument')
require (_clibroot.."cConfig")
require (_clibroot..'cFilesystem')
require (_clibroot..'cObservable')
require (_clibroot.."cParseXML")
require (_clibroot.."cProcessSlicer")

_xlibroot = 'source/xLib/classes/'
cLib.require (_xlibroot..'xLib')
cLib.require (_xlibroot.."xPhrase")
cLib.require (_xlibroot..'xLine')
cLib.require (_xlibroot..'xLinePattern')
cLib.require (_xlibroot..'xInstrument')
cLib.require (_xlibroot..'xNoteColumn')
cLib.require (_xlibroot..'xPhraseManager')
cLib.require (_xlibroot..'xScale')
cLib.require (_xlibroot..'xPatternSelection')
cLib.require (_xlibroot..'xPhraseSelection')
cLib.require (_xlibroot..'xMatrixSelection')
cLib.require (_xlibroot..'xNoteCapture')
cLib.require (_xlibroot..'xCursorPos')

_vlibroot = 'source/vLib/classes/'
cLib.require (_vlibroot..'vLib')
cLib.require (_vlibroot..'vDialog')
cLib.require (_vlibroot..'vTable')
cLib.require (_vlibroot..'vEditField')
cLib.require (_vlibroot..'vSearchField')
cLib.require (_vlibroot..'vPathSelector')
cLib.require (_vlibroot..'vPopup')
cLib.require (_vlibroot..'vArrowButton')

require ('source/PhraseMate')
require ('source/PhraseMateUI')
require ('source/PhraseMateExportDialog')
require ('source/PhraseMateSmartDialog')
require ('source/PhraseMatePrefs')

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

rns = nil
local prefs = PhraseMatePrefs()
renoise.tool().preferences = prefs
local phrasemate = nil

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

function start()
  rns = renoise.song()
  if not phrasemate then
    phrasemate = PhraseMate{
      app_display_name = "PhraseMate",
    }
  end
end

function show(new_song)
  start()
  if not new_song 
    or prefs.autostart.value
  then
    phrasemate:show_main_dialog()
  end
end

--------------------------------------------------------------------------------
-- Menu entries & MIDI/Key mappings
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:PhraseMate...",
  invoke = function() 
    show() 
  end
} 

renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Show Preferences...",
  invoke = function(repeated)
    if (not repeated) then 
      show() 
    end
  end
}
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Smart Write...",
  invoke = function(repeated)
    if not repeated then 
      start()
      cLib.invoke_task(PhraseMate.show_smart_dialog,phrasemate)
    end
  end
}

-- input : SELECTION_IN_PATTERN

renoise.tool():add_midi_mapping{
  name = "Tools:PhraseMate:Create Phrase from Selection in Pattern [Trigger]",
  invoke = function(msg)
    if msg:is_trigger() then
      start()
      cLib.invoke_task_logged(PhraseMate.collect_phrases,phrasemate,PhraseMate.INPUT_SCOPE.SELECTION_IN_PATTERN)
    end
  end
}
renoise.tool():add_menu_entry {
  name = "Pattern Editor:PhraseMate:Create Phrase from Selection",
  invoke = function() 
    start()
    cLib.invoke_task(PhraseMate.collect_phrases,phrasemate,PhraseMate.INPUT_SCOPE.SELECTION_IN_PATTERN)
  end
}
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Create Phrase from Selection in Pattern",
  invoke = function(repeated)
    if not repeated then 
      start()
      cLib.invoke_task(PhraseMate.collect_phrases,phrasemate,PhraseMate.INPUT_SCOPE.SELECTION_IN_PATTERN)
    end
  end
}

-- input : SELECTION_IN_MATRIX

renoise.tool():add_midi_mapping{
  name = "Tools:PhraseMate:Create Phrase from Selection in Matrix [Trigger]",
  invoke = function(msg)
    if msg:is_trigger() then
      start()
      cLib.invoke_task_logged(PhraseMate.collect_phrases,phrasemate,PhraseMate.INPUT_SCOPE.SELECTION_IN_MATRIX)
    end
  end
}
renoise.tool():add_menu_entry {
  name = "Pattern Matrix:PhraseMate:Create Phrase from Selection",
  invoke = function() 
    start()
    cLib.invoke_task(PhraseMate.collect_phrases,phrasemate,PhraseMate.INPUT_SCOPE.SELECTION_IN_MATRIX)
  end
}
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Create Phrase from Selection in Matrix",
  invoke = function(repeated)
    if not repeated then 
      start()
      cLib.invoke_task(PhraseMate.collect_phrases,phrasemate,PhraseMate.INPUT_SCOPE.SELECTION_IN_MATRIX)
    end
  end
}

-- input : TRACK_IN_PATTERN

renoise.tool():add_midi_mapping{
  name = "Tools:PhraseMate:Create Phrase from Track [Trigger]",
  invoke = function(msg)
    if msg:is_trigger() then
      start()
      cLib.invoke_task_logged(PhraseMate.collect_phrases,phrasemate,PhraseMate.INPUT_SCOPE.TRACK_IN_PATTERN)
    end
  end
}
renoise.tool():add_menu_entry {
  name = "Pattern Editor:PhraseMate:Create Phrase from Track",
  invoke = function()
    start() 
    cLib.invoke_task(PhraseMate.collect_phrases,phrasemate,PhraseMate.INPUT_SCOPE.TRACK_IN_PATTERN)
  end
}
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Create Phrase from Track",
  invoke = function(repeated)
    if not repeated then 
      start()
      cLib.invoke_task(PhraseMate.collect_phrases,phrasemate,PhraseMate.INPUT_SCOPE.TRACK_IN_PATTERN)
    end
  end
}

-- input : TRACK_IN_SONG

renoise.tool():add_midi_mapping{
  name = "Tools:PhraseMate:Create Phrases from Track in Song [Trigger]",
  invoke = function(msg)
    if msg:is_trigger() then
      start()
      cLib.invoke_task_logged(PhraseMate.collect_phrases,phrasemate,PhraseMate.INPUT_SCOPE.TRACK_IN_SONG)
    end
  end
}
renoise.tool():add_menu_entry {
  name = "Pattern Editor:PhraseMate:Create Phrases from Track in Song",
  invoke = function() 
    start()
    cLib.invoke_task(PhraseMate.collect_phrases,phrasemate,PhraseMate.INPUT_SCOPE.TRACK_IN_SONG)
  end
}
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Create Phrases from Track in Song",
  invoke = function(repeated)
    if not repeated then
      start()
      cLib.invoke_task(PhraseMate.collect_phrases,phrasemate,PhraseMate.INPUT_SCOPE.TRACK_IN_SONG)
    end
  end
}

-- output : apply_to_selection

renoise.tool():add_midi_mapping{
  name = "Tools:PhraseMate:Write Phrase to Selection In Pattern [Trigger]",
  invoke = function(msg)
    if msg:is_trigger() then
      start()
      cLib.invoke_task_logged(PhraseMate.apply_to_selection,phrasemate)
    end
  end
}
renoise.tool():add_menu_entry {
  name = "--- Pattern Editor:PhraseMate:Write Phrase to Selection In Pattern",
  invoke = function()
    start() 
    cLib.invoke_task(PhraseMate.apply_to_selection,phrasemate)
  end
} 
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Write Phrase to Selection in Pattern",
  invoke = function(repeated)
    if not repeated then 
      start()
      cLib.invoke_task(PhraseMate.apply_to_selection,phrasemate)
    end
  end
}

-- output : apply_to_track

renoise.tool():add_midi_mapping{
  name = "Tools:PhraseMate:Write Phrase to Track [Trigger]",
  invoke = function(msg)
    if msg:is_trigger() then
      start()
      cLib.invoke_task_logged(PhraseMate.apply_to_track,phrasemate)
    end
  end
}
renoise.tool():add_menu_entry {
  name = "Pattern Editor:PhraseMate:Write Phrase to Track",
  invoke = function()
    start() 
    cLib.invoke_task(PhraseMate.apply_to_track,phrasemate)
  end
} 

renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Write Phrase to Track",
  invoke = function(repeated)
    if not repeated then
      start() 
      cLib.invoke_task(PhraseMate.apply_to_track,phrasemate)
    end
  end
}

-- realtime

renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Toggle Realtime/Zxx mode",
  invoke = function(repeated)
    if not repeated then 
      prefs.zxx_mode = not prefs.zxx_mode
    end
  end
}

-- control : select phrase [set/trigger]

renoise.tool():add_midi_mapping {
  name = PhraseMate.MIDI_MAPPING.SELECT_PHRASE_IN_INSTR,
  invoke = function(msg)
    local instr = rns.selected_instrument
    local idx = cLib.clamp_value(msg.int_value,0,#instr.phrases)
    rns.selected_phrase_index = idx
  end
}

-- control : previous/next phrase

renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Select Previous Phrase in Instrument",
  invoke = function()
    if phrasemate then
      cLib.invoke_task(xPhraseManager.select_previous_phrase)
    end
  end
}
renoise.tool():add_midi_mapping {
  name = PhraseMate.MIDI_MAPPING.PREV_PHRASE_IN_INSTR,
  invoke = function(msg)
    if msg:is_trigger() then
      cLib.invoke_task_logged(xPhraseManager.select_previous_phrase)
    end
  end
}

renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Select Next Phrase in Instrument",
  invoke = function()
    cLib.invoke_task(xPhraseManager.select_next_phrase)
  end
}
renoise.tool():add_midi_mapping {
  name = PhraseMate.MIDI_MAPPING.NEXT_PHRASE_IN_INSTR,
  invoke = function(msg)
    if msg:is_trigger() then
      cLib.invoke_task_logged(xPhraseManager.select_next_phrase)
    end
  end
}

-- control : first/last phrase

renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Select First Phrase in Instrument",
  invoke = function()
    if phrasemate then
      cLib.invoke_task(xPhraseManager.select_first_phrase)
    end
  end
}
renoise.tool():add_midi_mapping {
  name = PhraseMate.MIDI_MAPPING.FIRST_PHRASE_IN_INSTR,
  invoke = function(msg)
    if msg:is_trigger() then
      cLib.invoke_task_logged(xPhraseManager.select_first_phrase)
    end
  end
}

renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Select Last Phrase in Instrument",
  invoke = function()
    cLib.invoke_task(xPhraseManager.select_last_phrase)
  end
}
renoise.tool():add_midi_mapping {
  name = PhraseMate.MIDI_MAPPING.LAST_PHRASE_IN_INSTR,
  invoke = function(msg)
    if msg:is_trigger() then
      cLib.invoke_task_logged(xPhraseManager.select_last_phrase)
    end
  end
}

-- control : playback mode

renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Set Playback Mode to 'Off'",
  invoke = function(repeated)
    if not repeated then      
      cLib.invoke_task(xPhraseManager.set_playback_mode,renoise.Instrument.PHRASES_OFF)
    end
  end
}
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Set Playback Mode to 'Program'",
  invoke = function(repeated)
    if not repeated then 
      cLib.invoke_task(xPhraseManager.set_playback_mode,renoise.Instrument.PHRASES_PLAY_SELECTIVE)
    end
  end
}
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Set Playback Mode to 'Keymap'",
  invoke = function(repeated)
    if not repeated then 
      cLib.invoke_task(xPhraseManager.set_playback_mode,renoise.Instrument.PHRASES_PLAY_KEYMAP)
    end
  end
}
renoise.tool():add_midi_mapping {
  name = PhraseMate.MIDI_MAPPING.SET_PLAYBACK_MODE,
  invoke = function(msg)
    local mode = cLib.clamp_value(msg.int_value,renoise.Instrument.PHRASES_OFF,renoise.Instrument.PHRASES_PLAY_KEYMAP)
    cLib.invoke_task_logged(xPhraseManager.set_playback_mode,mode)
  end
}
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Cycle Playback Mode",
  invoke = function(repeated)
    if not repeated then 
      cLib.invoke_task(xPhraseManager.cycle_playback_mode)
    end
  end
}
renoise.tool():add_midi_mapping {
  name = PhraseMate.MIDI_MAPPING.CYCLE_PLAYBACK_MODE,
  invoke = function(msg)
    cLib.invoke_task_logged(xPhraseManager.cycle_playback_mode)
  end
}

-- control : insert/delete phrase

renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Delete Selected Phrase",
  invoke = function(repeated)
    if (not repeated) then 
      start()
      cLib.invoke_task(PhraseMate.delete_phrase,phrasemate)
    end
  end
}
renoise.tool():add_midi_mapping {
  name = PhraseMate.MIDI_MAPPING.DELETE_PHRASE,
  invoke = function(msg)
    start()
    cLib.invoke_task_logged(PhraseMate.delete_phrase,phrasemate)
  end
}

renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Insert New Phrase",
  invoke = function(repeated)
    if not repeated then       
      start()
      cLib.invoke_task(PhraseMate.insert_phrase,phrasemate)
    end
  end
}
renoise.tool():add_midi_mapping {
  name = PhraseMate.MIDI_MAPPING.INSERT_PHRASE,
  invoke = function(msg)
    start()
    cLib.invoke_task_logged(PhraseMate.insert_phrase,phrasemate)
  end
}

-- addendum

renoise.tool():add_menu_entry {
  name = "--- Pattern Editor:PhraseMate:Adjust settings...",
  invoke = function() 
    show()
  end
}
renoise.tool():add_menu_entry {
  name = "--- Pattern Matrix:PhraseMate:Adjust settings...",
  invoke = function() 
    show()
  end
}


--------------------------------------------------------------------------------
-- Notifiers
--------------------------------------------------------------------------------

renoise.tool().app_new_document_observable:add_notifier(function()
  if prefs.autostart.value then
    show(true)
  end
end)





