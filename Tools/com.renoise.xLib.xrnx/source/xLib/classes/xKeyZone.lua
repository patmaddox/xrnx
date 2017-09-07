--[[===============================================================================================
xKeyZone
===============================================================================================]]--

--[[--

Static methods for working with instrument keyzones (a.k.a. sample mappings)
.

]]

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
xKeyZone.DEFAULT_NOTE_STEPS = 4
xKeyZone.DEFAULT_VEL_STEPS = 1
xKeyZone.MIN_VEL_STEPS = 1
xKeyZone.MAX_VEL_STEPS = 16
xKeyZone.MIN_NOTE_STEPS = 1
xKeyZone.MAX_NOTE_STEPS = 16
xKeyZone.DEFAULT_LAYER = renoise.Instrument.LAYER_NOTE_ON
xKeyZone.DEFAULT_BASE_NOTE = 48 -- C-4
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
    if note_range then 
      if cLib.table_compare(note_range,v.note_range) then 
        if velocity_range then 
          if cLib.table_compare(velocity_range,v.velocity_range) then 
            print("matched mapping",v)
            return v 
          end
        end 
      end 
    end 
  end

end

---------------------------------------------------------------------------------------------------
-- same as 'distribute' in the keyzone editor 

function xKeyZone.distribute()

  -- TODO 
  
end

---------------------------------------------------------------------------------------------------
-- same as 'layer' in the keyzone editor 

function xKeyZone.layer()

  -- TODO 
  
end

---------------------------------------------------------------------------------------------------
-- create layout from the provided settings 
-- table is ordered same way as Renoise: bottom up, velocity-wise, and left-to-right, note-wise
-- @return table<xSampleMapping>

function xKeyZone.create_multisample_layout(
  note_steps,note_min,note_max,
  vel_steps,vel_min,vel_max,
  extend_notes)

  print("create_multisample_layout - note_min,note_max",note_min,note_max)

  local notes = xKeyZone.compute_multisample_notes(note_steps,note_min,note_max,extend_notes)
  local velocities = xKeyZone.compute_multisample_velocities(vel_steps,vel_min,vel_max)

  local rslt = {}

  for k,note in ipairs(notes) do 
    for k2,velocity in ipairs(velocities) do 
      table.insert(rslt,xSampleMapping{
        layer = xKeyZone.DEFAULT_LAYER,
        base_note = xKeyZone.DEFAULT_BASE_NOTE,
        map_velocity_to_volume = xKeyZone.DEFAULT_VEL_TO_VOL,
        map_key_to_pitch = xKeyZone.DEFAULT_KEY_TO_PITCH,
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

  print("compute_multisample_notes rslt...",note_steps,note_min,note_max,extend,rprint(rslt))
  return rslt

end