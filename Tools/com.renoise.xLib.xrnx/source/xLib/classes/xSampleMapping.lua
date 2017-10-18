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

xSampleMapping.MIN_VEL = 0x00
xSampleMapping.MAX_VEL = 0x7F
xSampleMapping.MIN_NOTE = 0
xSampleMapping.MAX_NOTE = 119
xSampleMapping.DEFAULT_BASE_NOTE = 48
xSampleMapping.DEFAULT_LAYER = renoise.Instrument.LAYER_NOTE_ON
xSampleMapping.DEFAULT_VEL_TO_VOL = true
xSampleMapping.DEFAULT_KEY_TO_PITCH = true

-- exportable properties (cDocument)
xSampleMapping.DOC_PROPS = {
  layer = "boolean",
  map_velocity_to_volume = "boolean",
  map_key_to_pitch = "boolean",
  base_note = "number",
  note_range = "table",
  velocity_range = "table",
}

---------------------------------------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------------------------------------
-- create a 'virtual' sample-mapping object, unbound from Renoise 
-- @param (vararg or renoise.SampleMapping)

function xSampleMapping:__init(...)

  local args = cLib.unpack_args(...)
  --print("args",rprint(args),type(args))

  -- renoise.Instrument.LAYER
  self.layer = args.layer or xSampleMapping.DEFAULT_LAYER
  -- boolean 
  self.map_velocity_to_volume = args.map_velocity_to_volume or xSampleMapping.DEFAULT_VEL_TO_VOL
  -- boolean
  self.map_key_to_pitch = args.map_velocity_to_volume or xSampleMapping.DEFAULT_KEY_TO_PITCH
  -- base_note, number (0-119, c-4=48)
  self.base_note = args.base_note or xSampleMapping.DEFAULT_BASE_NOTE
  -- note_range, table with two numbers (0-119, c-4=48)
  self.note_range = args.note_range or {xSampleMapping.MIN_NOTE,xSampleMapping.MAX_NOTE}
  -- velocity_range, table with two numbers (0-127)
  self.velocity_range = args.velocity_range or {xSampleMapping.MIN_VEL,xSampleMapping.MAX_VEL}

  -- NB: the following properties are runtime only (unable to import/export)

  -- renoise.Sample 
  self.sample = args.sample
  -- number, refers to the numerical index of the source mapping 
  self.index = (type(args)~="SampleMapping") and args.index 

end

---------------------------------------------------------------------------------------------------
-- Static Methods 
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
-- [Static] test if mapping has the maximum possible range 

function xSampleMapping.has_full_range(mapping)
  return xSampleMapping.has_full_note_range(mapping)
    and xSampleMapping.has_full_velocity_range(mapping)
end

---------------------------------------------------------------------------------------------------
-- [Static] test if mapping occupies the full note-range

function xSampleMapping.has_full_note_range(mapping)
  return (mapping.note_range[1] == xSampleMapping.MIN_NOTE) 
    and  (mapping.note_range[2] == xSampleMapping.MAX_NOTE)
end

---------------------------------------------------------------------------------------------------
-- [Static] test if mapping occupies the full note-range

function xSampleMapping.has_full_velocity_range(mapping)
  return (mapping.velocity_range[1] == xSampleMapping.MIN_VEL) 
    and  (mapping.velocity_range[2] == xSampleMapping.MAX_VEL)
end

---------------------------------------------------------------------------------------------------
-- get memoized key for a sample mapping  
-- @param mapping (SampleMapping or xSampleMapping)
-- @param idx (number) the source mapping index 
-- @return string 

function xSampleMapping.get_memoized_key(mapping)

  return ("%d.%d.%d.%d.%d"):format(
    mapping.layer,
    mapping.note_range[1],
    mapping.note_range[2],
    mapping.velocity_range[1],
    mapping.velocity_range[2]
  )

end


