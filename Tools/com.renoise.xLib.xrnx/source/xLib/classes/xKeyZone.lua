--[[===============================================================================================
xKeyZone
===============================================================================================]]--

--[[--

Static methods for working with instrument keyzones (a.k.a. sample mappings)
.

]]

--=================================================================================================
require (_clibroot.."cDocument")

--=================================================================================================
-- describe a multi-sample keyzone layout 

class 'xKeyZoneLayout' (cDocument)

-- exportable properties (cDocument)
xKeyZoneLayout.DOC_PROPS = {
  note_steps = "number",
  note_min = "number",
  note_max = "number",
  vel_steps = "number",
  vel_min = "number",
  vel_max = "number",
  extend_notes = "boolean",
  layer = "number",
  map_velocity_to_volume = "boolean",
  map_key_to_pitch = "boolean",
  base_note = "number",
}

---------------------------------------------------------------------------------------------------

function xKeyZoneLayout:__init(...)

  local args = cLib.unpack_args(...)

  self.note_steps = args.note_steps or xKeyZone.DEFAULT_NOTE_STEPS
  self.note_min = args.note_min or xKeyZone.DEFAULT_NOTE_MIN
  self.note_max = args.note_max or xKeyZone.DEFAULT_NOTE_MAX
  self.vel_steps = args.vel_steps or xKeyZone.DEFAULT_VEL_STEPS
  self.vel_min = args.vel_min or xKeyZone.MIN_VEL
  self.vel_max = args.vel_max or xKeyZone.MAX_VEL
  self.extend_notes = args.extend_notes or xKeyZone.DEFAULT_EXTEND_NOTES
  self.layer = args.layer or xKeyZone.DEFAULT_LAYER
  self.map_velocity_to_volume = args.map_velocity_to_volume or xKeyZone.DEFAULT_VEL_TO_VOL
  self.map_key_to_pitch = args.map_key_to_pitch or xKeyZone.DEFAULT_KEY_TO_PITCH
  self.base_note = args.base_note or xKeyZone.DEFAULT_BASE_NOTE

end

--=================================================================================================

class 'xKeyZone'

xKeyZone.KEYS_MODE = {
  ALL_KEYS = 1,
  WHITE_KEYS = 2,
}

xKeyZone.MIN_VEL = 0x00
xKeyZone.MAX_VEL = 0x7F
xKeyZone.MIN_NOTE = 0
xKeyZone.MAX_NOTE = 119
xKeyZone.DEFAULT_NOTE_MIN = 24
xKeyZone.DEFAULT_NOTE_MAX = 95
xKeyZone.DEFAULT_NOTE_STEPS = 4
xKeyZone.DEFAULT_VEL_STEPS = 1
xKeyZone.MIN_VEL_STEPS = 1
xKeyZone.MAX_VEL_STEPS = 16
xKeyZone.MIN_NOTE_STEPS = 1
xKeyZone.MAX_NOTE_STEPS = 16
xKeyZone.DEFAULT_LAYER = renoise.Instrument.LAYER_NOTE_ON
xKeyZone.DEFAULT_BASE_NOTE = 48 
xKeyZone.DEFAULT_VEL_TO_VOL = true
xKeyZone.DEFAULT_KEY_TO_PITCH = true
xKeyZone.DEFAULT_EXTEND_NOTES = true

---------------------------------------------------------------------------------------------------
-- [Static] Shift samples by amount of semitones, starting from the sample index 
-- TODO use "mappings" array (support <xSampleMapping>)
-- @param instr (renoise.Instrument)
-- @param sample_idx_from (int)
-- @param amt (int)

function xKeyZone.shift_by_semitones(instr,sample_idx_from,amt)
  TRACE("xKeyZone.shift_by_semitones(instr,sample_idx_from,amt)",instr,sample_idx_from,amt)

  for sample_idx = sample_idx_from,#instr.samples do
    local sample = instr.samples[sample_idx]
    local smap = sample.sample_mapping
    smap.base_note = smap.base_note+amt
    smap.note_range = {smap.note_range[1]+amt, smap.note_range[2]+amt}
  end

end

---------------------------------------------------------------------------------------------------
-- Locate a sample-mapping that match the provided information

function xKeyZone.find_mapping(mappings,note_range,velocity_range)

  for k,v in ipairs(mappings) do
    local matched
    local continue = true
    if note_range then 
      continue = cLib.table_compare(note_range,v.note_range) 
      if continue then 
        matched = v
      end 
    end 
    if continue and velocity_range then 
      continue = cLib.table_compare(velocity_range,v.velocity_range) 
      if continue then 
        matched = v
      end
    end 
    if matched then 
      return v 
    end
  end

end

--------------------------------------------------------------------------------
-- [Static] Figure out which samples are mapped to the provided note
-- @return table<number> (sample indices)

function xKeyZone.get_samples_mapped_to_note(instr,note)
  TRACE("xKeyZone.get_samples_mapped_to_note(instr,note)",instr,note)

  local rslt = table.create()
  for sample_idx = 1,#instr.samples do 
    local sample = instr.samples[sample_idx]
    if xSampleMapping.within_note_range(note,sample.sample_mapping) then
      rslt:insert(sample_idx)
    end
  end
  return rslt

end

---------------------------------------------------------------------------------------------------
-- same as 'distribute' in the keyzone editor 
--[[
function xKeyZone.distribute()

  -- TODO 
  
end

---------------------------------------------------------------------------------------------------
-- same as 'layer' in the keyzone editor 

function xKeyZone.layer()

  -- TODO 
  
end
]]

---------------------------------------------------------------------------------------------------
-- create layout from the provided settings 
-- table is ordered same way as Renoise: bottom up, velocity-wise, and left-to-right, note-wise
-- @param layout (xKeyZoneLayout)
-- @return table<xSampleMapping>

function xKeyZone.create_multisample_layout(layout)
  TRACE("xKeyZone.create_multisample_layout()",layout)

  print(layout,type(layout))
  print("layout.note_steps",layout.note_steps,type(layout.note_steps))
  print("layout.note_min",layout.note_min,type(layout.note_min))
  print("layout.note_max",layout.note_max,type(layout.note_max))

  local notes = xKeyZone.compute_multisample_notes(
    layout.note_steps,layout.note_min,layout.note_max,layout.extend_notes)
  local velocities = xKeyZone.compute_multisample_velocities(
    layout.vel_steps,layout.vel_min,layout.vel_max)

  local rslt = {}

  for k,note in ipairs(notes) do 
    for k2,velocity in ipairs(velocities) do 
      table.insert(rslt,xSampleMapping{
        layer = layout.layer,
        base_note = layout.base_note,
        map_velocity_to_volume = layout.map_key_to_pitch,
        map_key_to_pitch = layout.map_key_to_pitch,
        note_range = note,
        velocity_range = velocity,
      })
    end
  end

  return rslt

end

---------------------------------------------------------------------------------------------------
-- @param vel_steps (number), the number of velocity layers to create
-- return table{number,number}

function xKeyZone.compute_multisample_velocities(vel_steps,vel_min,vel_max)
  TRACE("xKeyZone.compute_multisample_velocities()",vel_steps,vel_min,vel_max)

  if (vel_min > vel_max) then 
    vel_min,vel_max = vel_max,vel_min
  end 

  local rslt = {}
  local unit = (vel_max - vel_min + 1)/vel_steps
  local velocity = 0
  for k = 1,vel_steps do 
    local new = velocity+unit
    table.insert(rslt,{
      cLib.round_value(velocity),
      cLib.round_value(new-1)
    })
    velocity = new
  end

  --print("compute_multisample_velocities rslt...",rprint(rslt))
  return rslt

end

---------------------------------------------------------------------------------------------------
-- @param note_steps (number), create a new mapping for every Nth note 
-- @param extend (boolean), extend "outside" mapped region 
-- return table{number,number}

function xKeyZone.compute_multisample_notes(note_steps,note_min,note_max,extend)
  TRACE("xKeyZone.compute_multisample_notes(note_steps,note_min,note_max,extend)",note_steps,note_min,note_max,extend)

  if (extend == nil) then
    extend = xKeyZone.DEFAULT_EXTEND_NOTES
  end

  if (note_min > note_max) then 
    note_min,note_max = note_max,note_min
  end 

  local rslt = {}
  local note = note_min 
  while (note < note_max) do
    local from = note
    local new = note+note_steps  
    local to = new-1
    -- extend first/last sample
    if extend then 
      if (note == note_min) then 
        from = 0 
      end 
      if (new >= note_max) then 
        to = xKeyZone.MAX_NOTE
      end 
    end 
    table.insert(rslt,{
      cLib.round_value(from), 
      cLib.round_value(to),
    })
    note = new
  end

  --print("compute_multisample_notes rslt...",note_steps,note_min,note_max,extend,rprint(rslt))
  return rslt

end