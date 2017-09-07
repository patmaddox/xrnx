--[[===============================================================================================
xSampleMapping
===============================================================================================]]--

--[[--

Static methods for working with renoise sample mappings
.
#

### See also
@{xInstrument}

--]]
--=================================================================================================

class 'xSampleMapping'

---------------------------------------------------------------------------------------------------
-- a 'virtual' sample-mapping object, 

function xSampleMapping:__init(...)

  local args = cLib.unpack_args(...)

  --self.read_only

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

