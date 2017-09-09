--[[===============================================================================================
SSK
===============================================================================================]]--

--[[

Main class for the SSK tool 

]]

--=================================================================================================

-- allow access through static methods
local _prefs_ = nil

---------------------------------------------------------------------------------------------------

class 'SSK'

-- utility table for channel selecting
SSK.CH_UTIL = {
  {0,0,{{1,1},1}}, -- mono,selected_channel is 3
  {{{1,2},1},{{2,1},1},{{1,2},2}}, -- stereo
}

function SSK:__init(prefs)

  assert(type(prefs)=="SSK_Prefs",type(prefs))

  -- SSK_Prefs
  self.prefs = prefs
  _prefs_ = prefs

  -- Renoise.Instrument, currently targeted (can be nil)
  self.instrument = nil 
  self.instrument_index = nil 
  self.instrument_name_observable = renoise.Document.ObservableString("")
  -- Renoise.Sample, currently targeted (can be nil)
  self.sample = nil
  self.sample_index = property(self.get_sample_index)
  self.sample_index_observable = renoise.Document.ObservableNumber(0)
  self.sample_name_observable = renoise.Document.ObservableString("")
  self.sample_loop_changed_observable = renoise.Document.ObservableBang()
  self.samples_changed_observable = renoise.Document.ObservableBang()
  self.buffer_changed_observable = renoise.Document.ObservableBang()

  -- selection start/length - can be derived from formula in text input
  -- (updated in real-time when sync_with_renoise is specified)
  self.sel_start_frames = property(self.get_sel_start_frames,self.set_sel_start_frames)
  self.sel_start_frames_observable = renoise.Document.ObservableNumber(0)
  self.sel_length_frames = property(self.get_sel_length_frames,self.set_sel_length_frames)
  self.sel_length_frames_observable = renoise.Document.ObservableNumber(0)
  -- beats are derived from frames   
  self.sel_start_beats = 0
  self.sel_length_beats = 0
  -- TODO derive offsets from user-specified values 
  -- (those values are not changed as a result of programmatically changing the selection, 
  -- only when changed manually in the waveform editor)
  self.sel_start_offset = 0
  self.sel_length_offset = 0

  -- fired when the range has changed
  self.selection_changed_observable = renoise.Document.ObservableBang()
  -- fired when bpm or lpb has changed
  self.tempo_changed_observable = renoise.Document.ObservableBang()

  -- Multiplying range
  self.multiply_setend = cReflection.evaluate_string(self.prefs.multiply_setend.value)
  
  -- function, draw modulated wave
  self.wave_fn = nil
  self.mod_fn = nil
  self.mod_fade_fn = nil

  -- function, last random generator (for re-use)
  self.random_wave_fn = nil 
  self.random_generated_observable = renoise.Document.ObservableBang()  

  -- mod_shift:[-1,1]
  self.mod_cycle = cReflection.evaluate_string(self.prefs.mod_cycle.value)
  -- mod_fade_shift:[-1,1]
  self.mod_fade_cycle = cReflection.evaluate_string(self.prefs.mod_fade_cycle.value)

  -- function, expression of the memorized buffer
  self.clip_wv_fn = nil
  self.memorized_changed_observable = renoise.Document.ObservableBang()

  -- cWaveform.FORM, last selected wave generator (0 means none)
  self.recently_generated = property(self.get_recently_generated,self.set_recently_generated)
  self.recently_generated_observable = renoise.Document.ObservableNumber(0)

  -- boolean, true when the waveform should update
  self.update_wave_requested = false

  -- SSK_Gui
  self.ui = SSK_Gui{
    owner = self,
    waiting_to_show_dialog = true,
  }

  -- SSK_Dialog_Create
  self.create_dialog = SSK_Dialog_Create{
    dialog_title = "Create a new sample",
  }

  -- == Observables ==

  self.prefs.sync_with_renoise:add_notifier(function()
    if self.prefs.sync_with_renoise.value then 
      self:selection_range_notifier()
    end
  end)

  renoise.tool().app_new_document_observable:add_notifier(function()
    self:attach_to_song(true)
  end)

  --self.samples_changed_observable:add_notifier(function()
  --self:attach_to_sample()
  --end)

  -- required for detecting when buffer is created in sample
  self.buffer_changed_observable:add_notifier(function()
    self:attach_to_sample()
  end)

  renoise.tool().app_idle_observable:add_notifier(function()
    self:idle_notifier()
  end)

  self:attach_realtime_methods()

  -- == Initialize ==

  self:attach_to_song()

end

---------------------------------------------------------------------------------------------------
-- Getters & setters
---------------------------------------------------------------------------------------------------

function SSK:get_sample_index()
  return self.sample_index_observable.value
end

---------------------------------------------------------------------------------------------------

function SSK:get_sel_start_frames()
  return self.sel_start_frames_observable.value
end 

function SSK:set_sel_start_frames(val)
  self.sel_start_frames_observable.value = val
end 

---------------------------------------------------------------------------------------------------

function SSK:get_sel_length_frames()
  return self.sel_length_frames_observable.value
end 

function SSK:set_sel_length_frames(val)
  self.sel_length_frames_observable.value = val
end 

---------------------------------------------------------------------------------------------------

function SSK:get_recently_generated()
  return self.recently_generated_observable.value
end 

function SSK:set_recently_generated(val)
  self.recently_generated_observable.value = val
end 


---------------------------------------------------------------------------------------------------
-- Class methods 
---------------------------------------------------------------------------------------------------
-- delete selected sample 

function SSK:delete_sample()
  TRACE("SSK:delete_sample()")
  if self.instrument then 
    local sample = self.instrument.samples[self.sample_index]
    if sample then 
      self.instrument:delete_sample_at(self.sample_index)
    end 
  end
end

---------------------------------------------------------------------------------------------------
-- show the 'insert/create' dialog ...

function SSK:insert_sample()
  TRACE("SSK:insert_sample()")
  self.create_dialog:show()
end

---------------------------------------------------------------------------------------------------
-- Generate sample data from a function
-- @return boolean (true when created)

function SSK:make_wave(fn,mod_fn)
  print("SSK:make_wave(fn,mod_fn)",fn,mod_fn)

  local buffer = self:get_sample_buffer() 
  if not buffer then 
    return 
  end 

  local bop = xSampleBufferOperation{
    instrument_index = self.instrument_index,
    sample_index = self.sample_index,
    restore_selection = true,
    restore_loop = true,    
    restore_zoom = true,    
    operations = {
      xSampleBuffer.create_wave_fn{
        buffer=buffer,
        fn=fn,
        mod_fn=mod_fn,
      },
    },
    on_complete = function(new_buffer)
      TRACE("[make_wave] process_done - new_buffer",new_buffer)

    end 
  }
  bop:run()

end

---------------------------------------------------------------------------------------------------
-- Buffer operations
---------------------------------------------------------------------------------------------------
-- Copy to new sample (previously 'add_new')
-- Takes the memorized buffer and applies it to a new sample in the current instrument 

function SSK:copy_to_new()
  TRACE("SSK:copy_to_new()")
  
  local buffer = self:get_sample_buffer() 
  if not buffer then 
    return
  end 

  local init_range = xSampleBuffer.get_selection_range(buffer)
  local init_selected_channel = buffer.selected_channel

  local ch_tbl = SSK.CH_UTIL[buffer.number_of_channels][init_selected_channel]

  local do_process = function(new_buffer)
    local offset = buffer.selection_start-1
    for ch = 1,ch_tbl[2] do
      for fr = 1,init_range do
        new_buffer:set_sample_data(ch,fr,buffer:sample_data(ch_tbl[1][ch], fr + offset))
      end
    end
  end

  local bop = xSampleBufferOperation{
    instrument_index = self.instrument_index,
    sample_index = self.sample_index,
    create_sample = true,
    force_frames = init_range,
    operations = {
      do_process
    },
    on_complete = function(_bop_)
      -- rename and select sample 
      _bop_.sample.name = "#".._bop_.sample.name
      rns.selected_sample_index = _bop_.new_sample_index
    end
  }
  bop:run()

end

---------------------------------------------------------------------------------------------------
-- memorize the buffer (copy)

function SSK:buffer_memorize()
  local buffer = self:get_sample_buffer() 
  if buffer then 
    self.clip_wv_fn = cWaveform.table2fn(xSampleBuffer.wave2tbl{buffer=buffer})
    self.memorized_changed_observable:bang()
  end
end 

---------------------------------------------------------------------------------------------------
-- fit the memorized buffer within the selected region (paste)

function SSK:buffer_redraw()
  TRACE("SSK:buffer_mixdraw()")
  if self.clip_wv_fn then
    self:make_wave(self.clip_wv_fn)
  end
end 

---------------------------------------------------------------------------------------------------
-- mix the memorized buffer with the selected region 

function SSK:buffer_mixdraw()
  TRACE("SSK:buffer_mixdraw()")
  local buffer = self:get_sample_buffer()
  if self.clip_wv_fn and buffer then
    local fn = xSampleBuffer.copy_fn_fn(buffer)
    local mix = cWaveform.mix_fn_fn(fn,self.clip_wv_fn,0.5)
    print("fn,mix,clip_wv_fn",fn,mix,self.clip_wv_fn)
    self:make_wave(mix)
  end
end 

---------------------------------------------------------------------------------------------------
-- swap the memorized buffer with the selected region 

function SSK:buffer_swap()
  TRACE("SSK:buffer_swap()")
  local buffer = self:get_sample_buffer()
  if self.clip_wv_fn and buffer then
    
    -- TODO 
    -- first step: needs to memorize the clipped range 
    
    -- refuse if clipped range overlaps current selection 

    --[[
    local ch_tbl = SSK.CH_UTIL[buffer.number_of_channels][init_selected_channel]
    local do_process = function(new_buffer)
      local offset = buffer.selection_start-1
      for ch = 1,ch_tbl[2] do
        -- clipped range? insert selected frames... 
        -- selected frames? insert clipped data 
        -- pass through before 
        for fr = 1,init_range do
        end
      end
    end

    local bop = xSampleBufferOperation{
      instrument_index = self.instrument_index,
      sample_index = self.sample_index,
      --force_frames = range,
      restore_selection = true,
      operations = {
        do_process,
      },
      on_complete = function(_bop_)
        -- select the clipped range 
      end
    }
    bop:run()
    ]]
    
  end
end 

---------------------------------------------------------------------------------------------------

function SSK:sweep_ins()
  TRACE("SSK:sweep_ins()")

  local buffer = self:get_sample_buffer()           
  if not buffer then 
    return 
  end

  local bop = xSampleBufferOperation{
    instrument_index = self.instrument_index,
    sample_index = self.sample_index,
    restore_selection = true,
    restore_loop = true,
    restore_zoom = true,
    operations = {
      xSampleBuffer.sweep_ins{
        buffer=buffer
      },
    },
    on_complete = function()
      TRACE("[sweep_ins] process_done")
    end    
  }

  bop:run()

end

---------------------------------------------------------------------------------------------------

function SSK:sync_del()
  TRACE("SSK:sync_del()")

  local buffer = self:get_sample_buffer()           
  if not buffer then 
    return 
  end

  local bop = xSampleBufferOperation{
    instrument_index = self.instrument_index,
    sample_index = self.sample_index,
    restore_selection = true,
    restore_loop = true,        
    restore_zoom = true,        
    operations = {
      xSampleBuffer.sync_del{
        buffer=buffer
      },
    },
    on_complete = function()
      TRACE("[sync_del] process_done")
    end    
  }

  bop:run()

end


---------------------------------------------------------------------------------------------------
-- Selection methods 
---------------------------------------------------------------------------------------------------

function SSK:display_selection_as_os_fx()
  return (self.prefs.display_selection_as.value == SSK_Gui.DISPLAY_AS.OS_EFFECT) 
end

function SSK:display_selection_as_beats()
  return (self.prefs.display_selection_as.value == SSK_Gui.DISPLAY_AS.BEATS) 
end

function SSK:display_selection_as_samples()
  return (self.prefs.display_selection_as.value == SSK_Gui.DISPLAY_AS.SAMPLES) 
end

---------------------------------------------------------------------------------------------------
-- @return number or nil 

function SSK:get_selection_range()
  local buffer = self:get_sample_buffer()
  if buffer then 
    return xSampleBuffer.get_selection_range(buffer)
  end 
end 

---------------------------------------------------------------------------------------------------

function SSK:selection_toggle_left()
  local buffer = self:get_sample_buffer()
  if buffer then 
    return xSampleBuffer.selection_toggle_left(buffer)
  end 
end

---------------------------------------------------------------------------------------------------

function SSK:selection_toggle_right()
  local buffer = self:get_sample_buffer()
  if buffer then 
    return xSampleBuffer.selection_toggle_right(buffer)
  end 
end

---------------------------------------------------------------------------------------------------
-- @return renoise.SampleBuffer or nil 

function SSK:get_sample_buffer() 
  if self.sample then
    return xSample.get_sample_buffer(self.sample)
  end
end 

---------------------------------------------------------------------------------------------------
-- extend the selected range by the specified amount 

function SSK:selection_multiply_length()
  TRACE("SSK:selection_multiply_length()")

  local buffer = self:get_sample_buffer()
  if buffer then
    if self:display_selection_as_os_fx() then 
      local new_length_offset = cLib.round_value(self.multiply_setend*self.sel_length_offset)
      print("sel_length_offset",self.sel_length_offset)
      buffer.selection_end = xSampleBuffer.get_frame_by_offset(buffer,self.sel_start_offset+new_length_offset)-1      
    else  
      local range = xSampleBuffer.get_selection_range(buffer)
      local new_length = cLib.round_value(self.multiply_setend*range)
      self:apply_selection_range(new_length)
    end
  end

end

---------------------------------------------------------------------------------------------------
-- divide the selected range by the specified amount 

function SSK:selection_divide_length()
  TRACE("SSK:selection_divide_length()")

  local buffer = self:get_sample_buffer()
  if buffer then
    if self:display_selection_as_os_fx() then 
      local new_length_offset = cLib.round_value((1/self.multiply_setend)*self.sel_length_offset)
      print("new_length_offset",new_length_offset)
      buffer.selection_end = xSampleBuffer.get_frame_by_offset(buffer,self.sel_start_offset+new_length_offset)-1
    else
      local range = xSampleBuffer.get_selection_range(buffer)
      local new_length = cLib.round_value((1/self.multiply_setend)*range)
      self:apply_selection_range(new_length)
    end
  end

end

---------------------------------------------------------------------------------------------------
-- set selection range in frames, expand buffer when needed 
-- @param range (number), selection range/length
-- @param sel_start (number), can be outside current buffer 

function SSK:apply_selection_range(range,sel_start)
  TRACE("SSK:apply_selection_range(range,sel_start)",range,sel_start)

  assert(type(range)=="number")

  local buffer = self:get_sample_buffer() 
  if not buffer then 
    error("Expected an active sample-buffer")
  end 

  sel_start = sel_start or buffer.selection_start
  local end_point = sel_start + range - 1

  if (range <= 0) then 
    renoise.app():show_error('Enter a number greater than zero')
  elseif (end_point <= buffer.number_of_frames) then
    buffer.selection_range = {sel_start,end_point}
  elseif (end_point > buffer.number_of_frames) then
    local extend_by = end_point - buffer.number_of_frames
    local bop = xSampleBufferOperation{
      instrument_index = self.instrument_index,
      sample_index = self.sample_index,
      force_frames = end_point,
      operations = {
        xSampleBuffer.extend{
          buffer=buffer,
          extend_by=extend_by,
        }
      },
      on_complete = function(_bop_)
        TRACE("[apply_selection_range] process_done")
        local buffer = _bop_.buffer 
        buffer.selection_range = {sel_start,buffer.number_of_frames}
      end,
      on_error = function(err)
        TRACE("*** error message",err)
      end
    }
    bop:run()
  end

end

---------------------------------------------------------------------------------------------------
-- @return boolean 

function SSK:flick_forward()
  TRACE("SSK:flick_forward()")

  local buffer = self:get_sample_buffer() 
  if not buffer then 
    return  
  end 

  local range = xSampleBuffer.get_selection_range(buffer)
  local sel_start,new_start,new_end 

  if self:display_selection_as_os_fx() then 
    -- special handling for OS (stay precise)
    new_start = xSampleBuffer.get_frame_by_offset(
      buffer,self.sel_start_offset+self.sel_length_offset)
    new_end = xSampleBuffer.get_frame_by_offset(buffer,self.sel_start_offset+(self.sel_length_offset*2)) - 1
  else 
    -- normal, frame based calculation
    new_start = buffer.selection_start+range
    new_end = new_start+range-1
  end 

  if (new_end <= buffer.number_of_frames) then 
    buffer.selection_range = {new_start,new_end}
  else 
    -- extend buffer 
    self:apply_selection_range(range,new_start)
  end 

end

---------------------------------------------------------------------------------------------------
-- move selected region backwards, while inserting frames when needed
-- @return boolean 

function SSK:flick_back()
  TRACE("SSK:flick_back()")

  local buffer = self:get_sample_buffer() 
  if not buffer then 
    return  
  end 
  local range = xSampleBuffer.get_selection_range(buffer)
  local new_start,new_end 

  -- special handling for OS (stay precise)
  if self:display_selection_as_os_fx() then 
    new_start = xSampleBuffer.get_frame_by_offset(buffer,self.sel_start_offset-self.sel_length_offset)
    new_end = xSampleBuffer.get_frame_by_offset(buffer,self.sel_start_offset) - 1
  else 
    new_start = buffer.selection_start - range
    new_end = new_start+range-1
  end 

  print("flick back - new_start,new_end",new_start,new_end)

  if (new_start-1 >= 0) then
    buffer.selection_range = {new_start,new_end}
  else
    -- change buffer
    local extend_by = new_start-1
    local total_frames = buffer.number_of_frames + math.abs(extend_by)

    local loop_start = self.sample.loop_start
    local loop_end = self.sample.loop_end

    local bop = xSampleBufferOperation{
      instrument_index = self.instrument_index,
      sample_index = self.sample_index,
      force_frames = total_frames,
      operations = {
        xSampleBuffer.extend{
          buffer = buffer,
          extend_by = extend_by
        }
      },
      on_complete = function(_bop_)
        local sample = _bop_.sample
        TRACE("SSK:flick_back - process_done...sample",sample)
        buffer.selection_range = {1,range}
        -- preserve/shift loop points 
        loop_start = loop_start+math.abs(extend_by)
        loop_end = loop_end+math.abs(extend_by)
        xSample.set_loop_pos(sample,loop_start,loop_end)
      end       
    }
    bop:run()

  end

end

---------------------------------------------------------------------------------------------------
-- when pressing the [-->] arrow button next to the sel.start input,
-- or while sync_with_renoise is enabled

function SSK:obtain_sel_start_from_editor()
  TRACE("SSK:obtain_sel_start_from_editor()")

  local buffer = self:get_sample_buffer()
  if buffer then 
    self.sel_start_frames = buffer.selection_start
    self.sel_start_beats = self:get_beats_from_frame(buffer.selection_start)
    self.sel_start_offset = self:get_offset_from_frame(buffer.selection_start)
    print(">>> self.sel_start_offset",self.sel_start_offset)
  end 

end

---------------------------------------------------------------------------------------------------

function SSK:obtain_sel_end_offset(buffer)
  return xSampleBuffer.get_offset_by_frame(buffer,buffer.selection_end+1)
end

---------------------------------------------------------------------------------------------------
-- when pressing the [-->] arrow button next to the sel.length input,
-- or while sync_with_renoise is enabled

function SSK:obtain_sel_length_from_editor()
  TRACE("SSK:obtain_sel_length_from_editor()")

  local buffer = self:get_sample_buffer()
  if buffer then 
    local range = xSampleBuffer.get_selection_range(buffer)
    self.sel_length_frames = xSampleBuffer.get_selection_range(buffer)
    self.sel_length_beats = self:get_beats_from_frame(range)
    print(">>> self:obtain_sel_end_offset(buffer)",self:obtain_sel_end_offset(buffer))
    self.sel_length_offset = self:obtain_sel_end_offset(buffer)-self.sel_start_offset
    print(">>> self.sel_length_offset",self.sel_length_offset)
    --self.sel_length_offset = self:get_offset_from_frame(sel_length_offset)
  end 

end

---------------------------------------------------------------------------------------------------
-- @return number 

function SSK:get_beats_from_frame(frame)
  TRACE("SSK:get_beats_from_frame(frame)",frame)
  local buffer = self:get_sample_buffer() 
  if not buffer then 
    return 0 
  end  
  local beat = xSampleBuffer.get_beat_by_frame(buffer,frame) 
  return beat * (self:beat_unit_with_sync() * self:beat_unit_with_base_tune())
end

---------------------------------------------------------------------------------------------------
-- @return number 

function SSK:get_offset_from_frame(frame)
  TRACE("SSK:get_offset_from_frame(frame)",frame)
  local buffer = self:get_sample_buffer() 
  if not buffer then 
    return 0 
  end
  return xSampleBuffer.get_offset_by_frame(buffer,frame) 
end

---------------------------------------------------------------------------------------------------
-- interpret the selection start/length input as user is typing
-- (invalid values are returned as undefined)
-- @param str (string)
-- @param is_start (boolean), when interpreting the selection start input 
-- @return number or nil, number or nil, number or nil

function SSK:interpret_selection_input(str,is_start)
  print("SSK:interpret_selection_input(str)",str)

  local buffer = self:get_sample_buffer() 
  assert(type(buffer)=="SampleBuffer")

  local frame,beat,offset = nil,nil
  if self:display_selection_as_os_fx() then
    offset = cReflection.evaluate_string(str)
    if offset then 
      -- for start, we allow OS Effect to be 0 (== frame 1)
      if (offset == 0) and not is_start then
        offset = 256
      end
      if (offset >= 256) then 
        frame = buffer.number_of_frames
      else 
        frame = xSampleBuffer.get_frame_by_offset(buffer,offset)
      end
      if not is_start then 
        -- reduce end by one frame when not start 
        frame = frame - 1
      end 
      if offset then 
        beat = xSampleBuffer.get_beat_by_frame(buffer,frame)
      end
    end
  elseif self:display_selection_as_samples() then 
    frame = SSK.string_to_frames(str,self.prefs.A4hz.value,buffer.sample_rate) 
    if frame then
      beat = xSampleBuffer.get_beat_by_frame(buffer,frame)          
      offset = xSampleBuffer.get_offset_by_frame(buffer,frame)
    end
  elseif self:display_selection_as_beats() then 
    beat = cReflection.evaluate_string(str)
    if beat then
      frame = xSampleBuffer.get_frame_by_beat(buffer,beat)
      offset = xSampleBuffer.get_offset_by_frame(buffer,frame)
    end          
  end
  print(">>> interpret_selection_input - offset,beat,frame",offset,beat,frame)
  return offset,beat,frame

end

---------------------------------------------------------------------------------------------------
-- obtain the length in beats when sample is beat-synced

function SSK:beat_unit_with_sync()
  TRACE("SSK:beat_unit_with_sync()")
  assert(type(self.sample)=="Sample")
  local buffer = self:get_sample_buffer() 
  if not buffer or not self.sample.beat_sync_enabled then 
    return 1
  else
    return (buffer.number_of_frames * (rns.transport.lpb / self.sample.beat_sync_lines))
      / ((1 / rns.transport.bpm * 60) * buffer.sample_rate)
  end
end

---------------------------------------------------------------------------------------------------
-- for possible replacement - see xSample.get_transposed_note

function SSK:beat_unit_with_base_tune()
  TRACE("SSK:beat_unit_with_base_tune()")
  assert(type(self.sample)=="Sample")
  if (self.sample.transpose == 0 and self.sample.fine_tune == 0) 
    or self.sample.beat_sync_enabled
  then 
    return 1
  else 
    return math.pow ((1/2),(self.sample.transpose-(self.sample.fine_tune/128))/12)
  end
end

---------------------------------------------------------------------------------------------------
-- Generators 
---------------------------------------------------------------------------------------------------
-- Create random waveform 

function SSK:random_wave()
  TRACE("SSK:random_wave()")

  local range = self:get_selection_range()
  -- TODO move from cWaveform to here...
  self.random_wave_fn = cWaveform.random_wave(range)
  self:make_wave(self.random_wave_fn)
  self.random_generated_observable:bang()

  -- 1/10th chance of additional spice 
  --[[
  if (math.random() < 0.1) then
    local max = math.random(3)
    for i = 1,max do
      self:make_wave(cWaveform.random_copy_fn(range))
    end
  end
  ]]

end

---------------------------------------------------------------------------------------------------
-- Create random waveform 

function SSK:repeat_random_wave()
  TRACE("SSK:repeat_random_wave()")

  if not self.random_wave_fn then 
    return 
  end 

  local range = self:get_selection_range()
  self:make_wave(self.random_wave_fn)

end

---------------------------------------------------------------------------------------------------

function SSK:generate_white_noise()
  TRACE("SSK:generate_white_noise()")
  self.recently_generated = cWaveform.FORM.WHITE_NOISE
  self:make_wave(cWaveform.white_noise_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK:generate_brown_noise()
  TRACE("SSK:generate_brown_noise()")
  self.recently_generated = cWaveform.FORM.BROWN_NOISE
  self:make_wave(cWaveform.brown_noise_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK:generate_violet_noise()
  TRACE("SSK:generate_violet_noise()")
  self.recently_generated = cWaveform.FORM.VIOLET_NOISE
  self:make_wave(cWaveform.violet_noise_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK:generate_sine_wave()
  TRACE("SSK:generate_sine_wave()")
  self.recently_generated = cWaveform.FORM.SIN
  self.wave_fn = cWaveform.wave_fn(cWaveform.FORM.SIN,
    self.mod_cycle,
    self.prefs.mod_shift.value/100,
    self.prefs.mod_duty_onoff.value,
    self.prefs.mod_duty.value,
    self.prefs.mod_duty_var.value,
    self.prefs.mod_duty_var_frq.value,
    self.prefs.band_limited.value,
    self:get_selection_range())
  self.mod_fn = self:make_wave(self.wave_fn,self.mod_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK:generate_saw_wave()
  TRACE("SSK:generate_saw_wave()")
  self.recently_generated = cWaveform.FORM.SAW
  self.wave_fn = cWaveform.wave_fn(cWaveform.FORM.SAW,
    self.mod_cycle,
    self.prefs.mod_shift.value/100,
    self.prefs.mod_duty_onoff.value,
    self.prefs.mod_duty.value,
    self.prefs.mod_duty_var.value,
    self.prefs.mod_duty_var_frq.value,
    self.prefs.band_limited.value,
    self:get_selection_range())
  self.mod_fn = self:make_wave(self.wave_fn,self.mod_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK:generate_square_wave()
  TRACE("SSK:generate_square_wave()")
  self.recently_generated = cWaveform.FORM.SQUARE
  self.wave_fn = cWaveform.wave_fn(cWaveform.FORM.SQUARE,
    self.mod_cycle,
    self.prefs.mod_shift.value/100,
    self.prefs.mod_duty_onoff.value,
    self.prefs.mod_duty.value,
    self.prefs.mod_duty_var.value,
    self.prefs.mod_duty_var_frq.value,
    self.prefs.band_limited.value,
    self:get_selection_range())
  self.mod_fn = self:make_wave(self.wave_fn,self.mod_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK:generate_triangle_wave()
  TRACE("SSK:generate_triangle_wave()")
  self.recently_generated = cWaveform.FORM.TRIANGLE
  self.wave_fn = cWaveform.wave_fn(cWaveform.FORM.TRIANGLE,
    self.mod_cycle,
    self.prefs.mod_shift.value/100,
    self.prefs.mod_duty_onoff.value,
    self.prefs.mod_duty.value,
    self.prefs.mod_duty_var.value,
    self.prefs.mod_duty_var_frq.value,
    self.prefs.band_limited.value,
    self:get_selection_range())
  self.mod_fn = self:make_wave(self.wave_fn,self.mod_fn)

end 

---------------------------------------------------------------------------------------------------
-- Modifiers
---------------------------------------------------------------------------------------------------

function SSK:trim()
  TRACE("SSK:trim(ratio)")

  local buffer = self:get_sample_buffer() 
  if not buffer then 
    return
  end 

  local range = xSampleBuffer.get_selection_range(buffer)

  local bop = xSampleBufferOperation{
    instrument_index = self.instrument_index,
    sample_index = self.sample_index,
    force_frames = range,
    operations = {
      xSampleBuffer.trim{
        buffer=buffer,
      },
    },
    on_complete = function(_bop_)
      -- select/loop everything 
      local sample = _bop_.sample
      xSample.set_loop_all(sample)
      xSampleBuffer.select_all(sample.sample_buffer)
    end
  }
  bop:run()

end


---------------------------------------------------------------------------------------------------

function SSK:phase_shift_with_ratio(ratio)
  TRACE("SSK:phase_shift_with_ratio(ratio)",ratio)

  local buffer = self:get_sample_buffer() 
  if buffer then 
    local range = xSampleBuffer.get_selection_range(buffer)
    self:phase_shift_fine(range*ratio)
  end 

end

---------------------------------------------------------------------------------------------------

function SSK:phase_shift_fine(frame)
  TRACE("SSK:phase_shift_fine(frame)",frame)

  local buffer = self:get_sample_buffer() 
  if not buffer then 
    return 
  end 

  local on_complete = function()
    TRACE("[SSK:phase_shift_with_ratio] on_complete - ")
  end    

  local bop = xSampleBufferOperation{
    instrument_index = self.instrument_index,
    sample_index = self.sample_index,
    restore_selection = true,
    restore_loop = true,
    restore_zoom = true,
    operations = {
      xSampleBuffer.phase_shift{
        buffer=buffer,
        frame=frame,
      },
    }
  }
  bop:run()

end

---------------------------------------------------------------------------------------------------
-- apply fade operation to buffer 
-- @param fn 

function SSK:set_fade(fn,mod_fn)
  TRACE("SSK:set_fade(fn,mod_fn)",fn,mod_fn)
  local buffer = self:get_sample_buffer() 
  if buffer then 

    local bop = xSampleBufferOperation{
      instrument_index = self.instrument_index,
      sample_index = self.sample_index,
      restore_selection = true,
      restore_loop = true,
      restore_zoom = true,
      operations = {
        xSampleBuffer.set_fade{
          buffer=buffer,
          fn=fn,
          mod_fn=mod_fn,
        }
      },
      on_complete = function()
        TRACE("[set_fade] process_done")
      end
    }
    bop:run()

  end 
end

---------------------------------------------------------------------------------------------------

function SSK:fade_mod_sin()
  self.mod_fade_fn = cWaveform.mod_fn_fn(
    self.mod_fade_cycle,
    self.prefs.mod_fade_shift.value,
    self.prefs.mod_pd_duty_onoff.value,
    self.prefs.mod_pd_duty.value,
    self.prefs.mod_pd_duty_var.value,
    self.prefs.mod_pd_duty_var_frq.value)
  self:set_fade(cWaveform.sin_2pi_fn,self.mod_fade_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK:fade_mod_saw()
  self.mod_fade_fn = cWaveform.mod_fn_fn(
    self.mod_fade_cycle,
    self.prefs.mod_fade_shift.value,
    self.prefs.mod_pd_duty_onoff.value,
    self.prefs.mod_pd_duty.value,
    self.prefs.mod_pd_duty_var.value,
    self.prefs.mod_pd_duty_var_frq.value)
  self:set_fade(cWaveform.saw_fn,self.mod_fade_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK:fade_mod_square()
  self.mod_fade_fn = cWaveform.mod_fn_fn(
    self.mod_fade_cycle,
    self.prefs.mod_fade_shift.value,
    self.prefs.mod_pd_duty_onoff.value,
    self.prefs.mod_pd_duty.value,
    self.prefs.mod_pd_duty_var.value,
    self.prefs.mod_pd_duty_var_frq.value)
  self:set_fade(cWaveform.square_fn,self.mod_fade_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK:fade_mod_triangle()
  self.mod_fade_fn = cWaveform.mod_fn_fn(
    self.mod_fade_cycle,
    self.prefs.mod_fade_shift.value,
    self.prefs.mod_pd_duty_onoff.value,
    self.prefs.mod_pd_duty.value,
    self.prefs.mod_pd_duty_var.value,
    self.prefs.mod_pd_duty_var_frq.value)
  self:set_fade(cWaveform.triangle_fn,self.mod_fade_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK:pd_copy()  
  local buffer = self:get_sample_buffer() 
  local mod = cWaveform.mod_fn_fn(
    self.mod_fade_cycle,
    self.prefs.mod_fade_shift.value,
    self.prefs.mod_pd_duty_onoff.value,
    self.prefs.mod_pd_duty.value,
    self.prefs.mod_pd_duty_var.value,
    self.prefs.mod_pd_duty_var_frq.value)
  local fn = xSampleBuffer.copy_fn_fn(
    self.buffer,nil,buffer.selection_start,buffer.selection_end)
  self:make_wave(fn,mod)
end 

---------------------------------------------------------------------------------------------------
-- Observables
---------------------------------------------------------------------------------------------------
-- invoked when instrument name has changed

function SSK:instrument_name_notifier()
  self.instrument_name_observable.value = self.instrument.name
end 

---------------------------------------------------------------------------------------------------
-- invoked as instrument samples are added or removed 

function SSK:instrument_samples_notifier()
  self.samples_changed_observable:bang()
end 

---------------------------------------------------------------------------------------------------
-- invoked when sample range is changed in waveform editor 

function SSK:selection_range_notifier()
  TRACE("SSK:sample_buffer.selection_end fired...")
  if (self.prefs.sync_with_renoise.value) then 
    self:obtain_sel_start_from_editor()
    self:obtain_sel_length_from_editor()
  end 
  self.selection_changed_observable:bang()
end

---------------------------------------------------------------------------------------------------
-- invoked when sample name has changed

function SSK:sample_name_notifier()
  --TRACE("sample.name_observable fired... ")
  self.sample_name_observable.value = self.sample.name
end 

---------------------------------------------------------------------------------------------------
-- invoked when sample loop_mode has changed

function SSK:sample_loop_changed_notifier()
  --TRACE("sample.sample_loop_changed_notifier fired... ")
  self.sample_loop_changed_observable:bang()
end 

---------------------------------------------------------------------------------------------------
-- invoked when sample buffer has changed

function SSK:sample_buffer_notifier()
  --TRACE("sample.name_observable fired... ")
  self.buffer_changed_observable:bang()  
end 

---------------------------------------------------------------------------------------------------
-- @param new_song (boolean)

function SSK:attach_to_song(new_song)
  TRACE("SSK:attach_to_song(new_song)",new_song)

  local rns = renoise.song()

  if new_song then 
    -- immediately unset sample, instrument 
    self.instrument = nil 
    self.instrument_index = nil 
    self.sample = nil 
    self.sample_index_observable.value = 0
  end 

  rns.transport.bpm_observable:add_notifier(function()
    self.tempo_changed_observable:bang()
    self:selection_range_notifier()
  end)
  rns.transport.lpb_observable:add_notifier(function()
    self.tempo_changed_observable:bang()
    self:selection_range_notifier()
  end)

  rns.selected_instrument_observable:add_notifier(function()
    --TRACE("selected_instrument_observable fired...")
    self:attach_to_instrument()
  end)
  self:attach_to_instrument(new_song)

  rns.selected_sample_observable:add_notifier(function()
    --TRACE("selected_sample_observable fired...")
    self:attach_to_sample()
  end)
  self:attach_to_sample(new_song)

end 

---------------------------------------------------------------------------------------------------
-- @param new_song (boolean)

function SSK:attach_to_instrument(new_song)
  TRACE("SSK:attach_to_instrument(new_song)",new_song)

  local rns = renoise.song()
  if not new_song then 
    self:detach_from_instrument()
  end
  self.instrument = rns.selected_instrument  
  self.instrument_index = rns.selected_instrument_index
  if not self.instrument then 
    self.instrument_name_observable.value = ""
  else 

    local obs = self.instrument.name_observable
    if not obs:has_notifier(self,self.instrument_name_notifier) then     
      obs:add_notifier(self,self.instrument_name_notifier)
    end
    self:instrument_name_notifier()

    local obs = self.instrument.samples_observable
    if not obs:has_notifier(self,self.instrument_samples_notifier) then 
      obs:add_notifier(self,self.instrument_samples_notifier)
    end
    self:instrument_samples_notifier()
  end 

end 

---------------------------------------------------------------------------------------------------

function SSK:detach_from_instrument()
  TRACE("SSK:detach_from_instrument()")

  if self.instrument then 
    local obs = self.instrument.name_observable
    if obs:has_notifier(self,self.instrument_name_notifier) then 
      obs:remove_notifier(self,self.instrument_name_notifier)
    end
    if obs:has_notifier(self,self.instrument_samples_notifier) then 
      obs:remove_notifier(self,self.instrument_samples_notifier)
    end
    self.instrument = nil
  end 

end 

---------------------------------------------------------------------------------------------------
-- @param new_song (boolean)

function SSK:attach_to_sample(new_song)
  TRACE("SSK:attach_to_sample(new_song)",new_song)

  local rns = renoise.song()
  if not new_song then 
    self:detach_from_sample()
  end
  self.sample = rns.selected_sample 
  if not self.sample then 
    -- not available
    self.sample_index_observable.value = 0
    self.sample_name_observable.value = ""
  else 
    self.sample_index_observable.value = rns.selected_sample_index

    -- sample  
    local obs = self.sample.name_observable
    if not obs:has_notifier(self,self.sample_name_notifier) then
      obs:add_notifier(self,self.sample_name_notifier)
    end
    self:sample_name_notifier()
    local obs = self.sample.loop_mode_observable
    if not obs:has_notifier(self,self.sample_loop_changed_notifier) then 
      obs:add_notifier(self,self.sample_loop_changed_notifier)
    end 
    local obs = self.sample.loop_start_observable
    if not obs:has_notifier(self,self.sample_loop_changed_notifier) then 
      obs:add_notifier(self,self.sample_loop_changed_notifier)
    end 
    local obs = self.sample.loop_end_observable
    if not obs:has_notifier(self,self.sample_loop_changed_notifier) then 
      obs:add_notifier(self,self.sample_loop_changed_notifier)
    end 
    self:sample_loop_changed_notifier()
    local obs = self.sample.sample_buffer_observable
    if not obs:has_notifier(self,self.sample_buffer_notifier) then
      obs:add_notifier(self,self.sample_buffer_notifier)
    end
    --self:sample_buffer_notifier()

    -- sample-buffer
    if self:get_sample_buffer() then 
      local obs = self.sample.sample_buffer.selection_range_observable   
      if not obs:has_notifier(self,self.selection_range_notifier) then
        obs:add_notifier(self,self.selection_range_notifier)
      end
      self:selection_range_notifier()
    end 

  end 

end 

---------------------------------------------------------------------------------------------------

function SSK:detach_from_sample()
  TRACE("SSK:detach_from_sample()")

  if self.sample then 

    local obs = self.sample.name_observable
    if obs:has_notifier(self,self.sample_name_notifier) then
      obs:remove_notifier(self,self.sample_name_notifier)
    end    
    local obs = self.sample.loop_mode_observable
    if obs:has_notifier(self,self.sample_loop_changed_notifier) then
      obs:remove_notifier(self,self.sample_loop_changed_notifier)
    end    
    local obs = self.sample.loop_start_observable
    if obs:has_notifier(self,self.sample_loop_changed_notifier) then
      obs:remove_notifier(self,self.sample_loop_changed_notifier)
    end    
    local obs = self.sample.loop_end_observable
    if obs:has_notifier(self,self.sample_loop_changed_notifier) then
      obs:remove_notifier(self,self.sample_loop_changed_notifier)
    end    
    local obs = self.sample.sample_buffer_observable
    if not obs:has_notifier(self,self.sample_buffer_notifier) then
      obs:remove_notifier(self,self.sample_buffer_notifier)
    end    
    if self:get_sample_buffer() then 
      local obs = self.sample.sample_buffer.selection_range_observable
      if obs:has_notifier(self,self.selection_range_notifier) then 
        obs:remove_notifier(self,self.selection_range_notifier)
      end
    end 
    self.sample = nil
  end 

end 

---------------------------------------------------------------------------------------------------
-- execute realtime generating waveforms

function SSK:attach_realtime_methods()
  TRACE("SSK:attach_realtime_methods()")

  -- schedule update 
  local update_wave = function()
    print("*** update_wave")
    self.update_wave_requested = true
  end

  self.prefs.band_limited:add_notifier(update_wave)
  self.prefs.mod_cycle:add_notifier(update_wave)
  self.prefs.mod_shift:add_notifier(update_wave)
  self.prefs.mod_duty_onoff:add_notifier(update_wave)
  self.prefs.mod_duty:add_notifier(update_wave)
  self.prefs.mod_duty_var:add_notifier(update_wave)
  self.prefs.mod_duty_var_frq:add_notifier(update_wave)

end

---------------------------------------------------------------------------------------------------
-- (auto-)update recently generated

function SSK:update_wave()
  TRACE("SSK:update_wave()")
  local buffer = self:get_sample_buffer() 
  if buffer then
    local choice = {
      [cWaveform.FORM.SIN] = function()
        self:generate_sine_wave()
      end,
      [cWaveform.FORM.SAW] = function()
        self:generate_saw_wave()
      end,
      [cWaveform.FORM.SQUARE] = function()
        self:generate_square_wave()
      end,
      [cWaveform.FORM.TRIANGLE] = function()
        self:generate_triangle_wave()
      end,
    }
    if choice[self.recently_generated] then 
      choice[self.recently_generated]()
    end 
  end
end    

---------------------------------------------------------------------------------------------------

function SSK:idle_notifier()
  --TRACE("SSK:idle_notifier()")

  if self.update_wave_requested and self.wave_fn and self.recently_generated then 
    self.update_wave_requested = false
    self:update_wave()
  end 

end

---------------------------------------------------------------------------------------------------
-- Static methods
---------------------------------------------------------------------------------------------------
-- convert input to #frames (accepts notes, expressions and numbers)
-- was previous "str2wvnum"

function SSK.string_to_frames(str,ini_hz,sample_rate)
  TRACE("SSK.string_to_frames(str,ini_hz,sample_rate)",str,ini_hz,sample_rate)
  if (ini_hz==nil) then
    ini_hz=440
  end
  local st = xNoteColumn.note_string_to_value(str)
  -- check for out-of-range values (above 119)
  if not st or (st > 119) then 
    return cReflection.evaluate_string(str)
  else 
    return cLib.note_to_frames(st,sample_rate,ini_hz)
  end
end

---------------------------------------------------------------------------------------------------
-- quadratic square
function SSK.qsq(x,factor)
  return (1/2) * (x-(1/2))^2 + factor
end

-- quadratic square (inverted)
function SSK.qsq_inv(x,factor)
  return (-1/2) * (x-(1/2))^2 + factor
end

---------------------------------------------------------------------------------------------------

function SSK.raise_factor(factor)
  local y = 100/factor
  return y
end

function SSK.lower_factor(factor)
  local y = factor/100
  return y
end

function SSK.diff_factor(factor)
  local y = (100-factor)/100
  return y
end

---------------------------------------------------------------------------------------------------

function SSK.multiply_raise_fn(x)
  return SSK.raise_factor(_prefs_.multiply_percent.value)
end

function SSK.multiply_lower_fn(x)
  return SSK.lower_factor(_prefs_.multiply_percent.value)
end

---------------------------------------------------------------------------------------------------

function SSK.fade_in_fn(x)
  local diff_factor = SSK.diff_factor(_prefs_.fade_percent.value)
  local lower_factor = SSK.lower_factor(_prefs_.fade_percent.value)
  return diff_factor*x + lower_factor
end

function SSK.fade_out_fn(x)
  local diff_factor = SSK.diff_factor(_prefs_.fade_percent.value)
  local y = -diff_factor*x + 1
  return y
end

---------------------------------------------------------------------------------------------------

function SSK.center_fade_fn(x)
  local factor = SSK.lower_factor(_prefs_.center_fade_percent.value)
  local mul = 1/SSK.qsq(0,factor)
  local y = SSK.qsq(x,factor)*mul
  return y
end

function SSK.center_amplify_fn(x)
  local factor = SSK.lower_factor(_prefs_.center_fade_percent.value)
  local mul = 1/SSK.qsq_inv(0,factor)
  local y = SSK.qsq_inv(x,factor)*mul
  return y
end

