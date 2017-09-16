--[[===============================================================================================
xSampleMapping
===============================================================================================]]--

--[[--

Static methods for working with sample mappings
.
#

### See also
@{xInstrument}

--]]
--=================================================================================================
require (_clibroot.."cDocument")

class 'xSampleMapping' (cDocument)

-- exportable properties (cDocument)
xSampleMapping.DOC_PROPS = {
  layer = "boolean",
  map_velocity_to_volume = "boolean",
  map_key_to_pitch = "boolean",
  base_note = "number",
  note_range = "table<number>",
  velocity_range = "table<number>",
}

---------------------------------------------------------------------------------------------------
-- create a 'virtual' sample-mapping object 
-- @param (vararg or renoise.SampleMapping)

function xSampleMapping:__init(...)

  local args = cLib.unpack_args(...)
  print("args",rprint(args))

  if (type(args[1])=="SampleMapping") then 
    args = args[1]
  end 

  -- renoise.Instrument.LAYER
  self.layer = args.layer 
  -- boolean 
  self.map_velocity_to_volume = args.map_velocity_to_volume
  -- boolean
  self.map_key_to_pitch = args.map_velocity_to_volume
  -- base_note, number (0-119, c-4=48)
  self.base_note = args.base_note
  -- note_range, table with two numbers (0-119, c-4=48)
  self.note_range = args.note_range
  -- velocity_range, table with two numbers (0-127)
  self.velocity_range = args.velocity_range

end

---------------------------------------------------------------------------------------------------

function xSampleMapping:__tostring()

  return type(self)
    .. ":layer=" .. tostring(self.layer)
    .. ",map_velocity_to_volume=" .. tostring(self.map_velocity_to_volume)
    .. ",map_key_to_pitch=" .. tostring(self.map_key_to_pitch)
    .. ",base_note=" .. tostring(self.base_note)
    .. ",note_range=" .. tostring(self.note_range)
    .. ",velocity_range=" .. tostring(self.velocity_range)

end

---------------------------------------------------------------------------------------------------
-- [Static] Test if a given note is within the provided note-range 
-- @param note (number)
-- @param mapping (table{number,number})

function xSampleMapping.within_note_range(note,mapping)
  TRACE("xSampleMapping.within_note_range(note,mapping)",note,mapping)
  local rng = mapping.note_range
  return (note >= rng[1]) and (note <= rng[2]) 
end

---------------------------------------------------------------------------------------------------
-- [Static] test if sample mapping occupies the entire note-range

function xSampleMapping.has_full_note_range(mapping)
  return (mapping.note_range[1] == 0) 
    and  (mapping.note_range[2] == 119)
end

