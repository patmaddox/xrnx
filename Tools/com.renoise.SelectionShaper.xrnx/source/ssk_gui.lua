--[[===============================================================================================
SSK_Gui
===============================================================================================]]--

--[[

User interface for the SSK tool 
.

]]

--=================================================================================================

local prefs = renoise.tool().preferences

--=================================================================================================

class 'SSK_Gui'

SSK_Gui.DISPLAY_AS = {
  OS_EFFECT = 1,
  BEATS = 2,
  SAMPLES = 3,
}

SSK_Gui.COLOR_SELECTED = {0xf1,0x6a,0x32}
SSK_Gui.COLOR_DESELECTED = {0x16,0x16,0x16}
SSK_Gui.COLOR_NONE = {0x00,0x00,0x00}


SSK_Gui.DIALOG_WIDTH = 400
SSK_Gui.DIALOG_MARGIN = 3
SSK_Gui.DIALOG_SPACING = 3
SSK_Gui.INPUT_WIDTH = 80
SSK_Gui.LABEL_WIDTH = 64
SSK_Gui.FORMULA_WIDTH = 120
SSK_Gui.TOGGLE_SIZE = 16
SSK_Gui.SMALL_LABEL_WIDTH = 44
SSK_Gui.STRIP_HEIGHT = 36
--SSK_Gui.PANEL_MARGIN = 6
SSK_Gui.PANEL_INNER_MARGIN = 3
SSK_Gui.ITEM_MARGIN = 6
SSK_Gui.ITEM_SPACING = 3
SSK_Gui.ITEM_HEIGHT = 20
SSK_Gui.NULL_SPACING = -3
SSK_Gui.SMALL_BT_WIDTH = 32
SSK_Gui.WIDE_BT_WIDTH = 60
SSK_Gui.TALL_BT_HEIGHT = 18
SSK_Gui.ROW_STYLE = "invisible" --"body"
SSK_Gui.ROW_SPACING = 0
SSK_Gui.ROW_MARGIN = 1
SSK_Gui.PANEL_STYLE = "group"
SSK_Gui.PANEL_HEADER_FONT = "bold"
-- derived 
SSK_Gui.SMALL_BT_X2_WIDTH = SSK_Gui.SMALL_BT_WIDTH*2 + SSK_Gui.NULL_SPACING
SSK_Gui.DIALOG_INNER_WIDTH = SSK_Gui.DIALOG_WIDTH - 2*SSK_Gui.DIALOG_MARGIN

SSK_Gui.MSG_GET_LENGTH_BEAT_TIP = [[
Input the number or the formula 
that represents the selection range, 
e.g. '168*4' , 'c#4' , '400*((1/2)^(7/12))'
]]

SSK_Gui.MSG_GET_LENGTH_FRAME_ERR = [[
Enter a number greater than zero, 
or a numerical formula - e.g. '162*8' , '400*1.4/4' , '400*((1/2)^(7/12))'
]]

SSK_Gui.MSG_MULTIPLY_TIP = [[
Input the number or the formula by that
the selection range is multiplied, e.g. '44800/200' , '(1/2)^(7/12)'
]] 

SSK_Gui.MSG_MULTIPLY_ERR = [[
Enter a number that is greater than zero,
or a numerical formula, e.g. '44100/168' ,'(1/2)^(7/12)'
]]

SSK_Gui.MSG_FADE_SHIFT = [[
Input the number or the formula that
represent the starting phase point of the wave.
100% means 1 cycle .
]]

SSK_Gui.MSG_MOD_CYCLE = [[
Enter a number or a numerical formula.
1 means 1 cycle, e.g. 1/4' , '44100/168'
]]

SSK_Gui.MSG_MOD_SHIFT = [[
Input number or formula that
represent the starting phase point of the wave.
100% means 1cycle .
]]

SSK_Gui.MSG_DUTY_VAR = [[
Input duty cycle variation value.
Duty cycle fluctuates between fiducial value
and this value plus fiducial value with minus cosine curve.
]]

SSK_Gui.MSG_DUTY_FRQ = [[
Input duty variation frequency.
Duty cycle fluctuates between fiducial value
and variation value plus fiducial value with minus cosine curve.
this frequency is used in this cosine curve. 
]]

SSK_Gui.MSG_MOD_DUTY_VAR = [[
Input duty cycle variation value.
Duty cycle fluctuates between fiducial value
and this value plus fiducial value with minus cosine curve.
]]

SSK_Gui.MSG_MOD_DUTY_FRQ = [[
Input duty variation frequency.
Duty cycle fluctuates between fiducial value
and variation value plus fiducial value with minus cosine curve.
this frequency is used in this cosine curve.
]]

SSK_Gui.MSG_COPY_PD = [[
Superscribing copy with phase distortion 
(useful with Duty cycle settings)
]]

SSK_Gui.MSG_FADE_TIP = [[
Input the number or the formula that represent the cycle of the wave.
1 means 1 cycle, e.g. '1/2' , '44100/168'
]]



---------------------------------------------------------------------------------------------------

function SSK_Gui:__init(owner)
  TRACE("SSK_Gui:__init(owner)",owner)

  assert(type(owner) == "SSK")

  -- Viewbuilder
  self.vb = renoise.ViewBuilder()
  -- SSK (SelectionShaper)
  self.owner = owner 
  -- Bitmap location table
  self.btmp = bitmap_util()
  -- boolean, scheduled updates
  self.update_strip_requested = false
  self.update_toolbar_requested = false
  self.update_selection_requested = false
  self.update_select_panel_requested = true
  self.update_modify_panel_requested = true
  self.update_generate_panel_requested = true
  self.update_selection_header_requested = false

  -- boolean, true we are displaying strip in "loop mode"
  self.display_buffer_as_loop = property(self.get_display_buffer_as_loop,self.set_display_buffer_as_loop)
  self.display_buffer_as_loop_observable = renoise.Document.ObservableBoolean(false)

  -- renoise.Dialog
  self.dialog = nil  
  -- renoise.view, dialog content 
  self.vb_content = nil

  -- SSK_Gui_Keyzone
  self.vkeyzone = nil

  -- == Observables == 

  self.display_buffer_as_loop_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:display_buffer_as_loop_observable fired...")
    self:update_selection_strip_controls()
  end)
  self.owner.tempo_changed_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:tempo_changed_observable fired...")
    --self.vb.views.set_start_val_frame.value = tostring(self.owner.sel_start_frames)
    self.update_selection_requested = true
  end)
  self.owner.selection_changed_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:selection_changed_observable fired...")
    --self.vb.views.set_start_val_frame.value = tostring(self.owner.sel_start_frames)
    self.update_strip_requested = true
    self.update_selection_header_requested = true
  end)
  self.owner.samples_changed_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:samples_changed_observable fired...")
  self.update_toolbar_requested = true
    self.update_strip_requested = true
    self.update_selection_header_requested = true
  end)
  self.owner.memorized_changed_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:memorized_changed_observable fired...")
    self:update_buffer_controls()
  end)
  self.owner.buffer_changed_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:buffer_changed_observable fired...")
    self.update_strip_requested = true
  end)
  self.owner.sel_length_frames_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:sel_length_frames_observable fired...")
    self.update_selection_requested = true    
  end)
  self.owner.sel_start_frames_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:sel_start_frames_observable fired...")
    self.update_selection_requested = true    
  end)
  self.owner.sample_name_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:sample_name_observable fired...")
    -- update controls that display the same name 
    self.update_toolbar_requested = true    
    self.update_selection_header_requested = true
  end)
  self.owner.sample_loop_changed_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:sample_loop_changed_observable fired...")
    self.update_strip_requested = true    
    self.update_selection_header_requested = true
  end)
  self.owner.sample_index_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:sample_index_observable fired...")
    -- update any controls that should be enabled or disabled
    self.update_toolbar_requested = true    
    self.update_strip_requested = true
    self.update_select_panel_requested = true
    self.update_modify_panel_requested = true
    self.update_generate_panel_requested = true
    self.update_selection_header_requested = true
  end)
  self.owner.instrument_name_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:instrument_name_observable fired...")
    self.update_toolbar_requested = true
    self.update_selection_header_requested = true
    self.update_strip_requested = true
  end)

  prefs.sync_with_renoise:add_notifier(function()
    self.update_select_panel_requested = true
  end)
  prefs.mod_duty_onoff:add_notifier(function()
    self:update_duty_cycle()
  end)
  prefs.mod_pd_duty_onoff:add_notifier(function()
    self:update_pd_duty_cycle()
  end)
  prefs.multisample_mode:add_notifier(function()
    print("multisample_mode",prefs.multisample_mode.value)
    self.update_toolbar_requested = true
    self:update_panel_visibility()
  end)
  prefs.display_selection_panel:add_notifier(function()
    self:update_panel_visibility()
  end)
  prefs.display_generate_panel:add_notifier(function()
    self:update_panel_visibility()
  end)
  prefs.display_modify_panel:add_notifier(function()
    self:update_panel_visibility()
  end)
  prefs.display_options_panel:add_notifier(function()
    self:update_panel_visibility()
  end)
  prefs.display_selection_as:add_notifier(function()
    self.update_selection_requested = true
  end)
  renoise.tool().app_idle_observable:add_notifier(function()
    self:idle_notifier()
  end)

  
end 

---------------------------------------------------------------------------------------------------
-- Getters and Setters
---------------------------------------------------------------------------------------------------

function SSK_Gui:get_display_buffer_as_loop()
  return self.display_buffer_as_loop_observable.value
end 

function SSK_Gui:set_display_buffer_as_loop(val)
  self.display_buffer_as_loop_observable.value = val
end 

---------------------------------------------------------------------------------------------------
-- Class methods
---------------------------------------------------------------------------------------------------
-- Show the dialog (build if needed)

function SSK_Gui:show()
  TRACE("ScaleMate_UI:show()")

  if not self.dialog or not self.dialog.visible then 
    if not self.vb_content then 
      self:build()
    end 
    local _self_ = self
    self.dialog = renoise.app():show_custom_dialog(
      "Selection Shaper Kai",
      self.vb_content,
      function(dialog,key)
        return self:key_handler(dialog,key)
      end
    )
  end 

  self.dialog:show()
  self:update_all()

end

---------------------------------------------------------------------------------------------------

function SSK_Gui:key_handler(dlg,key)
  TRACE("SSK_Gui:key_handler(dlg,key)",dlg,key)
  
  if (key.modifiers == "") then 
    -- pure keys (repeat allowed)
    if (key.name == "left") then 
      self.owner:flick_range_back()
      return
    elseif (key.name == "right") then
      self.owner:flick_range_forward()
      return
    elseif (key.name == "up") then
      self.owner:selection_multiply_length()
      return
    elseif (key.name == "down") then
      self.owner:selection_divide_length()
      return
    end 
    -- pure keys (no repeat)
    if (key.repeated == false) then
      if (key.name == "return") then 
        local sample = self.owner.sample
        if sample then
          xSample.set_loop_to_selection(sample)
        end
        return
      elseif (key.name == "del") then
        self.owner:sync_del()
        return
      elseif (key.name == "ins") then
        self.owner:sweep_ins()
        return
      end 
    end 
  end 

  if (key.modifiers == "control") 
    and (key.repeated == false)
  then 
    -- keys with modifier (no repeat)
    if (key.name == "c") then 
      self.owner:buffer_memorize()
      return
    elseif (key.name == "v") then 
      self.owner:buffer_redraw()
      return
    end
  end

  -- forward key to Renoise 
  return key

end

---------------------------------------------------------------------------------------------------

function SSK_Gui:update_all()
  TRACE("SSK_Gui:update_all()")

  self:update_panel_visibility()
  self:update_duty_cycle()
  self:update_pd_duty_cycle()
  self.update_select_panel_requested = true
  self.update_modify_panel_requested = true
  self.update_generate_panel_requested = true
  self.update_modify_panel_requested = true
  self.update_selection_requested = true
  self.update_toolbar_requested = true
  self.update_strip_requested = true

end

---------------------------------------------------------------------------------------------------

function SSK_Gui:update_panel_visibility()
  TRACE("SSK_Gui:update_panel_visibility()")
  self.vb.views.ssk_selection_panel.visible = prefs.display_selection_panel.value
  self.vb.views.ssk_generate_panel.visible = prefs.display_generate_panel.value
  self.vb.views.ssk_modify_panel.visible = prefs.display_modify_panel.value
  self.vb.views.ssk_multisample_editor.visible = prefs.multisample_mode.value
end

---------------------------------------------------------------------------------------------------

function SSK_Gui:update_select_panel()
  TRACE("SSK_Gui:update_select_panel()")

  local is_active = self.owner:get_sample_buffer() and true or false
  local sync_enabled = prefs.sync_with_renoise.value
  
  -- header 
  self.vb.views.ssk_sync_with_renoise.active = is_active
  self.vb.views.ssk_selection_unit_popup.active = is_active
  -- start 
  self.vb.views.ssk_get_selection_start.active = is_active and not sync_enabled
  self.vb.views.ssk_get_selection_length.active = is_active and not sync_enabled
  -- length 
  self.vb.views.ssk_selection_length.active = is_active
  self.vb.views.ssk_selection_apply_length.active = is_active
  self.vb.views.ssk_selection_multiply_length.active = is_active
  self.vb.views.ssk_selection_divide_length.active = is_active
  self.vb.views.multiply_setend.active = is_active

end

---------------------------------------------------------------------------------------------------

function SSK_Gui:update_generate_panel()
  TRACE("SSK_Gui:update_generate_panel()")

  local is_active = self.owner:get_sample_buffer() and true or false
  self.vb.views.ssk_generate_random_bt.active = is_active
  self.vb.views.ssk_generate_white_noise_bt.active = is_active
  self.vb.views.ssk_generate_brown_noise_bt.active = is_active
  self.vb.views.ssk_generate_violet_noise_bt.active = is_active
  self.vb.views.ssk_generate_sin_wave_bt.active = is_active
  self.vb.views.ssk_generate_saw_wave_bt.active = is_active
  self.vb.views.ssk_generate_square_wave_bt.active = is_active
  self.vb.views.ssk_generate_triangle_wave_bt.active = is_active

end

---------------------------------------------------------------------------------------------------

function SSK_Gui:update_modify_panel()
  TRACE("SSK_Gui:update_modify_panel()")

  local is_active = self.owner:get_sample_buffer() and true or false
  self.vb.views.ssk_generate_shift_plus_bt.active = is_active
  self.vb.views.ssk_generate_shift_minus_bt.active = is_active
  self.vb.views.ssk_generate_shift_plus_fine_bt.active = is_active
  self.vb.views.ssk_generate_shift_minus_fine_bt.active = is_active
  self.vb.views.ssk_generate_fade_center_a_bt.active = is_active
  self.vb.views.ssk_generate_fade_center_b_bt.active = is_active
  self.vb.views.ssk_generate_fade_out_bt.active = is_active
  self.vb.views.ssk_generate_fade_in_bt.active = is_active
  self.vb.views.ssk_generate_multiply_lower_bt.active = is_active
  self.vb.views.ssk_generate_multiply_raise_bt.active = is_active
  --self.vb.views.ssk_resize_expand_bt.active = is_active
  --self.vb.views.ssk_resize_shrink_bt.active = is_active
  self.vb.views.ssk_generate_rm_sin_bt.active = is_active
  self.vb.views.ssk_generate_rm_saw_bt.active = is_active
  self.vb.views.ssk_generate_rm_square_bt.active = is_active
  self.vb.views.ssk_generate_rm_triangle_bt.active = is_active
  self.vb.views.ssk_generate_pd_copy_bt.active = is_active

end

---------------------------------------------------------------------------------------------------

function SSK_Gui:update_duty_cycle()
  TRACE("SSK_Gui:update_duty_cycle()")
  local is_active = prefs.mod_duty_onoff.value 
  self.vb.views.duty_fiducial.active = is_active
  self.vb.views.duty_variation.active = is_active
  self.vb.views.duty_var_frq.active = is_active
end

---------------------------------------------------------------------------------------------------

function SSK_Gui:update_pd_duty_cycle()
  TRACE("SSK_Gui:update_pd_duty_cycle()")

  local is_active = prefs.mod_pd_duty_onoff.value 
  self.vb.views.pd_duty_fiducial.active = is_active
  self.vb.views.pd_duty_variation.active = is_active
  self.vb.views.pd_duty_var_frq.active = is_active
end

---------------------------------------------------------------------------------------------------

function SSK_Gui:update_toolbar()
  TRACE("SSK_Gui:update_toolbar()")

  local has_samples = false
  local vb_textfield = self.vb.views.ssk_status_sample_name
  if self.owner.instrument then 
    local instr_name = (self.owner.instrument.name == "") 
      and "Untitled instrument" or self.owner.instrument.name
    has_samples = #self.owner.instrument.samples > 0
    if self.owner.sample then 
      local sample_name = xSample.get_display_name(self.owner.sample,self.owner.sample_index)
      local buffer = self.owner:get_sample_buffer()
      if not buffer then 
        sample_name = ("%s (empty)"):format(sample_name)
      end 
      vb_textfield.text = ("%s - %s"):format(instr_name,sample_name)
    elseif not has_samples then 
      vb_textfield.text = ("%s - No samples present"):format(instr_name)
    else 
      vb_textfield.text = ("%s - No sample selected"):format(instr_name)
    end 
  else 
    vb_textfield.text = "Instrument N/A"
  end 

  -- force width of instr/sample readout (crop text)
  local insert_delete_w = 34
  local multisample_switch_w = 100
  vb_textfield.width = SSK_Gui.DIALOG_INNER_WIDTH - (insert_delete_w+multisample_switch_w)

  self.vb.views.ssk_sample_delete.active = (self.owner.sample and has_samples) and true or false

  local vb_multisample = self.vb.views.ssk_status_multisample
  local multi_on = prefs.multisample_mode.value 

  vb_multisample.text = multi_on and "Multisample ON" or "Multisample OFF"
  vb_multisample.font = multi_on and "bold" or "normal"
  vb_multisample.width = multisample_switch_w

end 

---------------------------------------------------------------------------------------------------
-- update buttons in buffer panel 

function SSK_Gui:update_buffer_controls()
  TRACE("SSK_Gui:update_buffer_controls()")

  local buffer = self.owner:get_sample_buffer() and true or false
  local memorized = self.owner.clip_wv_fn and true or false
  self.vb.views.ssk_buffer_delete.active = buffer
  self.vb.views.ssk_buffer_insert.active = buffer
  self.vb.views.ssk_buffer_trim.active = buffer
  self.vb.views.ssk_buffer_copy.active = buffer
  self.vb.views.ssk_buffer_copy_to_new.active = buffer
  self.vb.views.ssk_buffer_paste.active = buffer and memorized
  self.vb.views.ssk_buffer_mix_paste.active = buffer and memorized

end

---------------------------------------------------------------------------------------------------
-- update additional buttons in selection-strip (prev/next/loop/etc)

function SSK_Gui:update_selection_strip_controls()
  TRACE("SSK_Gui:update_selection_strip_controls()")

  local buffer = self.owner:get_sample_buffer() 
  local is_active = buffer and true or false
  self.vb.views.ssk_flick_forward.active = is_active
  self.vb.views.ssk_flick_back.active = is_active

  local loop_bt = self.vb.views.ssk_strip_set_loop
  loop_bt.active = is_active
  loop_bt.text = self.display_buffer_as_loop and "Clr.Loop" or "Set Loop"
  loop_bt.tooltip = self.display_buffer_as_loop and
    "Click to remove the currently set loop"
    or "Click to loop the currently selected region"

  --== update channel toggle-buttons ==--

  local toggle_right_bt = self.vb.views.ssk_selection_toggle_right
  local toggle_left_bt = self.vb.views.ssk_selection_toggle_left

  if (not buffer or buffer.number_of_channels == 1) then 
    -- mono
    local tooltip = "Toggle channel (available when in stereo)"
    toggle_left_bt.active = false
    toggle_left_bt.color = SSK_Gui.COLOR_NONE
    toggle_left_bt.tooltip = tooltip

    toggle_right_bt.active = false
    toggle_right_bt.color = SSK_Gui.COLOR_NONE  
    toggle_right_bt.tooltip = tooltip

  else
    -- stereo
    toggle_left_bt.tooltip = "Click to toggle selection in left channel"
    toggle_right_bt.tooltip = "Click to toggle selection in right channel"

    local right_is_selected = xSampleBuffer.right_is_selected(buffer)
    local left_is_selected = xSampleBuffer.left_is_selected(buffer)
    local can_toggle_right = 
      (buffer.selected_channel == renoise.SampleBuffer.CHANNEL_LEFT_AND_RIGHT)
      or (buffer.selected_channel == renoise.SampleBuffer.CHANNEL_LEFT)
    local can_toggle_left = 
      (buffer.selected_channel == renoise.SampleBuffer.CHANNEL_LEFT_AND_RIGHT)
      or (buffer.selected_channel == renoise.SampleBuffer.CHANNEL_RIGHT)
    toggle_left_bt.active = can_toggle_left
    toggle_left_bt.color = left_is_selected and SSK_Gui.COLOR_SELECTED or SSK_Gui.COLOR_NONE
    toggle_right_bt.active = can_toggle_right
    toggle_right_bt.color = right_is_selected and SSK_Gui.COLOR_SELECTED or SSK_Gui.COLOR_NONE
  end

end

---------------------------------------------------------------------------------------------------
-- produce visual overview over selection 

function SSK_Gui:update_selection_strip()
  TRACE("SSK_Gui:update_selection_strip()")

  local vb_strip = self.vb.views.ssk_selection_strip
  local total_w = SSK_Gui.DIALOG_WIDTH - 
    (SSK_Gui.SMALL_BT_X2_WIDTH + 24)

  if not self.owner:get_sample_buffer() then 
    self.selection_strip.items = {}
    self.selection_strip:update()  
    return 
  end        

  local sample = self.owner.sample
  local buffer = sample.sample_buffer
  local range = xSampleBuffer.get_selection_range(buffer) 
  local is_fully_looped = xSample.is_fully_looped(sample)

  -- required for weighing  
  local segment_length = nil
  local num_segments = 1
  local lead = nil 
  local trail = nil 
  local looped_segment_index = 0
  local selected_segment_index = 0

  -- different handling for OS Effects 
  -- (avoid rounding artifacts)
  local as_os_fx = self.owner:display_selection_as_os_fx()
  local get_segment_length = function(idx)
    local sel_offset = self.owner.sel_length_offset
    local frame_start = xSampleBuffer.get_frame_by_offset(buffer,idx*sel_offset)
    local frame_end = xSampleBuffer.get_frame_by_offset(buffer,(idx+1)*sel_offset)
    return frame_end-frame_start
  end
  local is_perfect_lead = self.owner.sel_start_offset%self.owner.sel_length_offset == 0
  local is_perfect_trail = 256%(self.owner.sel_start_offset+self.owner.sel_length_offset) == 0

  if (range == buffer.number_of_frames) and not is_fully_looped then 
    -- define leading/trailing as space before/after loop 
    self.display_buffer_as_loop = true
    num_segments = 1
    if (sample.loop_start > 1) then
      lead = sample.loop_start-1
    end
    if (sample.loop_end < buffer.number_of_frames) then
      trail = buffer.number_of_frames-sample.loop_end
    end
    segment_length = sample.loop_end - sample.loop_start + 1
    looped_segment_index = lead and 2 or 1
  else 
    self.display_buffer_as_loop = false
    segment_length = range

    -- before testing for leading/trailing space, check for perfect lead:
    -- in such a case, leading space is purely a result of rounding artifacts
    -- check if OS values (start/length) takes us back to 0   
    local num_lead_segments = function()
      return self.owner.sel_start_offset/self.owner.sel_length_offset
    end
    
    if as_os_fx and is_perfect_lead then
      num_segments = num_segments + num_lead_segments()
    else
      -- do we have leading space (how much) ?
      if (buffer.selection_start > 1) then 
        lead = buffer.selection_start - 1
        while lead > 0 do 
          lead = lead - segment_length
          num_segments = num_segments + 1
        end 
        if (lead < 0) then 
          lead = lead + segment_length 
          num_segments = num_segments - 1
        elseif (lead == 0) then 
          lead = nil
        end
      end 
    end

    local num_trail_segments = function()
      local start = self.owner.sel_start_offset
      local length = self.owner.sel_length_offset
      return (256-(start+length))/length
    end

    if as_os_fx and is_perfect_trail then
      num_segments = num_segments + num_trail_segments()
    else
      -- do we have trailing space (how much) ?
      if (buffer.selection_end < buffer.number_of_frames) then 
        trail = buffer.selection_end
        while trail <= buffer.number_of_frames do 
          trail = trail + segment_length
          num_segments = num_segments + 1
        end 
        if (trail > buffer.number_of_frames) then 
          trail = trail - segment_length
          num_segments = num_segments - 1
        elseif (trail == buffer.number_of_frames) then 
          trail = nil
        end 
      end
      if trail then 
        trail = buffer.number_of_frames - trail
      end 
    end 
  end        
  
  -- create weights, check if active/looped segment 
  local weights = {}  -- table<vButtonStripMember> 
  local tmp_frame = 0
  if lead then 
    table.insert(weights,vButtonStripMember{weight = lead})
    -- segment is selected?
    -- if (buffer.selection_start == 1 and buffer.selection_end == lead) then 
    --   selected_segment_index = 1
    -- end 
    tmp_frame = lead
  end   
  for k = 1, num_segments do 

    if as_os_fx and is_perfect_lead then
      segment_length = get_segment_length(k)
    end

    table.insert(weights,vButtonStripMember{weight = segment_length})
    if self.display_buffer_as_loop then
      selected_segment_index = 0
    else
      if (buffer.selection_start == tmp_frame+1 
        and buffer.selection_end == tmp_frame + segment_length) 
      then 
        selected_segment_index = lead and k + 1 or k
      end     
    end
    -- segment is looped?
    local sample = self.owner.sample 
    if (sample.loop_mode ~= renoise.Sample.LOOP_MODE_OFF) then
      if (sample.loop_start == tmp_frame+1 
        and sample.loop_end == tmp_frame + segment_length) 
      then 
        looped_segment_index = lead and k+1 or k
      end
    end           
    tmp_frame = tmp_frame + segment_length
  end 
  if trail then 
    table.insert(weights,vButtonStripMember{weight = trail})
    -- if (buffer.selection_start == trail 
    --   and buffer.selection_end == buffer.number_of_frames) 
    -- then 
    --   selected_segment_index = num_segments + 1
    -- end     
  end 
  
  local tmp_frame = 0
  for k,v in ipairs(weights) do
    -- selected when range matches, and not the only one
    local fully_selected = (#weights == 1) and true or false
    local is_looped = (looped_segment_index == k)
    local is_lead = lead and (k == 1)
    local is_trail = trail and (k == #weights)
    local is_selected = (selected_segment_index == 0) and false 
      or (fully_selected or (k == selected_segment_index)) and true 
      or false
    local title_txt = ""
    if self.display_buffer_as_loop then 
      title_txt = is_looped and "Loop" or "-"
    else
      title_txt = tostring(k)
    end
    local subline_txt = is_looped and "⟲" or is_lead and "‹‹" or is_trail and "››" or ""
    
    -- configure item 
    local sel_start =  tmp_frame
    local sel_length = tmp_frame+v.weight
    local sel_end = v.weight
    v.text = not fully_selected and ("%s\n%s"):format(title_txt,subline_txt) or "-"
    v.tooltip = ("Segment #%d: [%d - %d] %d"):format(k,sel_start,sel_length,sel_end)
    v.color = is_selected and SSK_Gui.COLOR_SELECTED or 
      is_looped and SSK_Gui.COLOR_NONE or SSK_Gui.COLOR_DESELECTED

    tmp_frame = tmp_frame + v.weight

  end 

  self.selection_strip.items = weights
  self.selection_strip:update()

end 

---------------------------------------------------------------------------------------------------
-- update the selection start/length inputs with frames,beats,offset

function SSK_Gui:update_selection_length()
  TRACE("SSK_Gui:update_selection_length()")

  if self.owner:display_selection_as_samples() then 
    self.vb.views.ssk_selection_start.value = tostring(self.owner.sel_start_frames) 
    self.vb.views.ssk_selection_length.value = tostring(self.owner.sel_length_frames) 
  elseif self.owner:display_selection_as_beats() then
    self.vb.views.ssk_selection_start.value = tostring(self.owner.sel_start_beats) 
    self.vb.views.ssk_selection_length.value = tostring(self.owner.sel_length_beats) 
  elseif self.owner:display_selection_as_os_fx() then
    self.vb.views.ssk_selection_start.value = tostring(self.owner.sel_start_offset) 
    self.vb.views.ssk_selection_length.value = tostring(self.owner.sel_length_offset) 
  else 
    self.vb.views.ssk_selection_start.value = ""
    self.vb.views.ssk_selection_length.value = ""
  end

end 

---------------------------------------------------------------------------------------------------
-- update the selected range readout 

function SSK_Gui:update_selection_header()
  TRACE("SSK_Gui:update_selection_header()")

  local sel_start,sel_end,sel_length
  local vb_textfield = self.vb.views.ssk_selection_header_txt
  if self.owner:get_sample_buffer() then 
    local buffer = self.owner.sample.sample_buffer
    sel_start = buffer.selection_start - 1
    sel_end = buffer.selection_end
    sel_length = sel_end - sel_start
    if self.owner:display_selection_as_os_fx() then 
      sel_start = xSampleBuffer.get_offset_by_frame(buffer,buffer.selection_start)
      sel_end = self.owner:obtain_sel_end_offset(buffer)
      sel_length = sel_end - sel_start
      vb_textfield.text = (" [%X - %X] (%X)"):format(sel_start,sel_end,sel_length)
    elseif self.owner:display_selection_as_samples() then 
      vb_textfield.text = (" [%d - %d] (%d)"):format(sel_start,sel_end,sel_length)
    elseif self.owner:display_selection_as_beats() then
      sel_start = 1 + xSampleBuffer.get_beat_by_frame(buffer,sel_start)
      sel_end = 1 + xSampleBuffer.get_beat_by_frame(buffer,sel_end)
      sel_length = 1 + sel_end - sel_start
      vb_textfield.text = (" [%s - %s] (%s)"):format(
        cString.format_beat(sel_start),
        cString.format_beat(sel_end),
        cString.format_beat(sel_length))
    end
  else 
    vb_textfield.text = ""
  end

end 

---------------------------------------------------------------------------------------------------

function SSK_Gui:build()

  self.vb_content = self.vb:column{
    margin = SSK_Gui.DIALOG_MARGIN,
    spacing = SSK_Gui.DIALOG_SPACING,
    self.vb:column{
      style = "border",
      self:build_toolbar(),
      self:build_keyzone(),
    },    
    self:build_buffer_panel(),
    self:build_selection_panel(),    
    self:build_generate_panel(),
    self:build_modify_panel(),  
  }

end 

---------------------------------------------------------------------------------------------------

function SSK_Gui:build_toolbar()

  return self.vb:horizontal_aligner{
    id = "ssk_header_aligner",
    mode = "justify",
    margin = SSK_Gui.DIALOG_MARGIN,
    self.vb:row{
      spacing = SSK_Gui.NULL_SPACING,
      self.vb:button{
        id = "ssk_sample_delete",    
        text = "‒",
        tooltip = "Delete the selected sample.",
        notifier = function()
          self.owner:delete_sample()
        end,          
      },
      self.vb:button{ 
        id = "ssk_sample_insert",    
        text = "+",
        tooltip = "Create/insert a new sample",
        notifier = function ()  
          self.owner:insert_sample()
        end,
      },       
      self.vb:space{
        width = 6,
      },
      self.vb:text{
        id = "ssk_status_sample_name",
        text = "",
        font = "normal",
      },
    },
    self.vb:text{
      id = "ssk_status_multisample",
      text = "",
      font = "normal",
      align = "center"
    },
    self.vb:checkbox{
      visible = false,
      bind = prefs.multisample_mode,
    },
  }

end

---------------------------------------------------------------------------------------------------

function SSK_Gui:build_keyzone()

  local vb = self.vb 

  self.vkeyzone = SSK_Gui_Keyzone{
    vb = self.vb,
    width = 300,
    height = 200,
    note_steps = prefs.multisample_note_steps.value,
    note_min = prefs.multisample_note_min.value,
    note_max = prefs.multisample_note_max.value,
    vel_steps = prefs.multisample_vel_steps.value,
    vel_min = prefs.multisample_vel_min.value,
    vel_max = prefs.multisample_vel_max.value,
  }

  return vb:row{
    id = "ssk_multisample_editor",
    vb:space{
      width = 3,
    },   
    self.vkeyzone.view,
    vb:column{
      vb:text{
        text = "Note Range"
      },
      vb:row{
        vb:valuebox{
          min = xKeyZone.MIN_NOTE,
          max = xKeyZone.MAX_NOTE,
          bind = prefs.multisample_note_min,
          width = SSK_Gui.SMALL_LABEL_WIDTH,
          tostring = function(val)
            return xNoteColumn.note_value_to_string(val)
          end,
          tonumber = function(val)
            return xNoteColumn.note_string_to_value(val)
          end,
          notifier = function(val)
            print("note_min notifier...",val)
            self.vkeyzone.note_min = val
          end
        },
        vb:valuebox{
          min = xKeyZone.MIN_NOTE,
          max = xKeyZone.MAX_NOTE,            
          bind = prefs.multisample_note_max,
          width = SSK_Gui.SMALL_LABEL_WIDTH,
          tostring = function(val)
            return xNoteColumn.note_value_to_string(val)
          end,
          tonumber = function(val)
            return xNoteColumn.note_string_to_value(val)
          end,          
          notifier = function(val)
            self.vkeyzone.note_max = val
          end          
        }
      },
      vb:row{
        vb:text{
          text = "Steps",
          align = "right",
          width = SSK_Gui.SMALL_LABEL_WIDTH,
        },
        vb:valuebox{
          min = xKeyZone.MIN_NOTE_STEPS,
          max = xKeyZone.MAX_NOTE_STEPS,          
          bind = prefs.multisample_note_steps,
          width = SSK_Gui.SMALL_LABEL_WIDTH,
          notifier = function(val)
            self.vkeyzone.note_steps = val
          end          
        }
      },
      vb:text{
        text = "Vel Range"
      },
      vb:row{
        vb:valuebox{
          min = xKeyZone.MIN_VEL,
          max = xKeyZone.MAX_VEL,            
          bind = prefs.multisample_vel_min,
          width = SSK_Gui.SMALL_LABEL_WIDTH,
          tostring = function(val)
            return ("%02X"):format(val)
          end,
          tonumber = function(val)
            return tonumber(val)
          end,          
          notifier = function(val)
            self.vkeyzone.vel_min = val
          end          
        },
        vb:valuebox{
          min = xKeyZone.MIN_VEL,
          max = xKeyZone.MAX_VEL,                        
          bind = prefs.multisample_vel_max,
          width = SSK_Gui.SMALL_LABEL_WIDTH,
          tostring = function(val)
            return ("%02X"):format(val)
          end,
          tonumber = function(val)
            return tonumber(val)
          end,                    
          notifier = function(val)
            self.vkeyzone.vel_max = val
          end          
        }
      },
      vb:row{
        vb:text{
          text = "Steps",
          align = "right",
          width = SSK_Gui.SMALL_LABEL_WIDTH,
        },
        vb:valuebox{
          min = xKeyZone.MIN_VEL_STEPS,
          max = xKeyZone.MAX_VEL_STEPS,
          bind = prefs.multisample_vel_steps,
          width = SSK_Gui.SMALL_LABEL_WIDTH,
          notifier = function(val)
            self.vkeyzone.vel_steps = val
          end                    
        }
      }
    }
  }

end

---------------------------------------------------------------------------------------------------

function SSK_Gui:build_buffer_panel()

  self.selection_strip = vButtonStrip{
    vb = self.vb,
    height = SSK_Gui.STRIP_HEIGHT,
    width = SSK_Gui.DIALOG_INNER_WIDTH - 75,
    placeholder_message = "Sample N/A",
    pressed = function(idx,_strip_)
      local item = _strip_.items[idx]
      local start = _strip_:get_item_offset(idx)
      self.owner.sample.sample_buffer.selection_range = {start+1,start+item.weight}
      --self.segment_index = idx
    end,
    released = function(idx)
    end,
  }

  return self.vb:column{
    self.vb:row{
      self.vb:row{
        id = "ssk_selection_strip",
        spacing = SSK_Gui.NULL_SPACING-1,
        self.selection_strip.view,
      },       
      self.vb:row{
        self.vb:column{          
          self.vb:button{
            id = "ssk_selection_toggle_left",
            text = "L",
            notifier = function()
              self.owner:selection_toggle_left()
            end,
          },
          self.vb:button{
            id = "ssk_selection_toggle_right",
            text = "R",
            notifier = function()
              self.owner:selection_toggle_right()
            end,
          },
        },
        self.vb:column{
          self.vb:row{
            spacing = SSK_Gui.NULL_SPACING,
            self.vb:button{
              id = "ssk_flick_back",
              text = "←",
              width = SSK_Gui.SMALL_BT_WIDTH,    
              tooltip = "Flick the selection range leftward.",      
              notifier = function()
                self.owner:flick_range_back()
              end,          
            },
            self.vb:button{
              id = "ssk_flick_forward",
              text = "→",
              width = SSK_Gui.SMALL_BT_WIDTH,
              tooltip = "Flick the selection range rightward.",
              notifier = function()
                self.owner:flick_range_forward()
              end,          
            },
          },
          self.vb:button{
            id = "ssk_strip_set_loop",
            width = SSK_Gui.SMALL_BT_X2_WIDTH,
            notifier = function()
              local sample = self.owner.sample
              if (self.display_buffer_as_loop) then
                xSample.clear_loop(sample)
              else
                xSample.set_loop_to_selection(sample)
              end
            end,          
          },
        }
      },        
    },    
    self.vb:row{
      --id = "ssk_buffer_panel",
      self.vb:text{
        text = "Buffer"
      },
      self.vb:row{
        spacing = SSK_Gui.NULL_SPACING,
        self.vb:button{
          id = "ssk_buffer_delete",    
          text = "‒",
          tooltip = "Clear the selection range without changing the sample length",
          notifier = function()
            self.owner:sync_del()
          end,          
        },
        self.vb:button{ 
          id = "ssk_buffer_insert",    
          text = "+",
          tooltip = "Insert silence without changing the sample length",
          notifier = function ()  
            self.owner:sweep_ins()
          end,
        },        
      },
      self.vb:space{
        width = SSK_Gui.ITEM_SPACING,
      },   
      self.vb:button{
        id = "ssk_buffer_trim",
        text = "Trim",
        tooltip = "Trim sample to the selected area.",
        notifier = function(x)
          self.owner:trim()
        end
      }, 
      self.vb:button{
        id = "ssk_buffer_copy",
        text = "Copy",
        tooltip = "Memorize the waveform in a selection area.",
        notifier = function(x)
          self.owner:buffer_memorize()
        end
      }, 
      self.vb:button{
        id = "ssk_buffer_copy_to_new",
        text = "Copy to new",
        tooltip = "Copy the selection range into new sample.",
        notifier = function()
          self.owner:copy_to_new()
        end,
      },        
      self.vb:button{
        id = "ssk_buffer_paste",
        text = 'Paste',
        tooltip = "Redraw the memorized (clipped) waveform to the selected area.",
        notifier =
        function(x)
          self.owner:buffer_redraw()
        end
      }, 
      self.vb:button{
        id = "ssk_buffer_mix_paste",
        text = 'Mix-Paste',
        tooltip = "Mix the memorized (clipped) waveform with the selected area.",
        notifier =
        function(x)
          self.owner:buffer_mixdraw()
        end
      },        
    },  
  }
end

---------------------------------------------------------------------------------------------------

function SSK_Gui:build_selection_panel()

  return self.vb:column{     
    style = SSK_Gui.PANEL_STYLE,
    margin = SSK_Gui.PANEL_INNER_MARGIN,
    self.vb:space{
      width = SSK_Gui.DIALOG_INNER_WIDTH,
    },
    self.vb:row{
      self.vb:row{
        self:build_panel_header("Selection",function()
          --             
        end,prefs.display_selection_panel),          
        self.vb:text{
          id = "ssk_selection_header_txt",
          tooltip = "The current selection - start/end, length",
          width = SSK_Gui.DIALOG_INNER_WIDTH - 200,
        },
      },    
      self.vb:row{
        tooltip = "Sync selection with waveform editor",
        self.vb:text{
          text = "Sync"
        },
        self.vb:checkbox{
          id = "ssk_sync_with_renoise",
          bind = prefs.sync_with_renoise,
        },          
      },  
      self.vb:popup{
        id = "ssk_selection_unit_popup",
        items = {
          "OS Effect",
          "Beats",
          "Samples",
        },
        bind = prefs.display_selection_as,
        --notifier = function(idx)
        --  prefs.display_selection_as.value = idx
        --end
      }        
    },
    
    self.vb:column{
      id = "ssk_selection_panel",
      visible = false,
      self.vb:space{
        height = SSK_Gui.ITEM_SPACING,
      },
      self.vb:column{
        self:build_selection_start_row(),
        self:build_selection_length_row(),
      },
    },
  }
end 

---------------------------------------------------------------------------------------------------

function SSK_Gui:build_generate_panel()

  return self.vb:column{
    style = SSK_Gui.PANEL_STYLE,
    margin = SSK_Gui.PANEL_INNER_MARGIN,
    self.vb:space{
      width = SSK_Gui.DIALOG_INNER_WIDTH,
    },
    self:build_panel_header("Generate",function()
    end,prefs.display_generate_panel),
    self.vb:row{
      id = "ssk_generate_panel",
      visible = false,
      spacing = SSK_Gui.NULL_SPACING,
      self.vb:column{
        spacing = SSK_Gui.NULL_SPACING,
        self.vb:text{
          width = SSK_Gui.LABEL_WIDTH,
          text = "Random",
          align = "center",
        },
        self.vb:button{
          id = "ssk_generate_random_bt",
          --bitmap = self.btmp.random_wave,
          --width = 80,
          --height = 80,
          bitmap = self.btmp.run_random,
          width = SSK_Gui.WIDE_BT_WIDTH,
          height = SSK_Gui.TALL_BT_HEIGHT,
          text = 'Random',
          tooltip = "Make random waves",
          notifier = function(x)
            self.owner:random_wave()
          end
        },
      },
      self.vb:column{
        spacing = SSK_Gui.NULL_SPACING,
        self.vb:text{
          width = SSK_Gui.LABEL_WIDTH,
          text = "Noise",
          align = "center",
        },
        self:build_white_noise(),
        self:build_brown_noise(), 
        self:build_violet_noise(), 
        --self:build_pink_noise(),
      },
      self.vb:column{
        spacing = SSK_Gui.NULL_SPACING,
        self.vb:text{
          width = SSK_Gui.LABEL_WIDTH,
          text = "Wave",
          align = "center",
        },
        self:build_sin_2pi(),
        self:build_saw_wave(),
        self:build_square_wave(),
        self:build_triangle_wave(), 
      },
      self.vb:column{
        self:build_band_limited_check(),    
        self:build_cycle_shift_set(),
        self.vb:space{
          height = SSK_Gui.ITEM_SPACING,
        },
        self:build_duty_cycle(), 
      },
    },
  }

  -- Karplus-Strong 
  --[[
  local ks_btn = self:build_ks_btn()
  local ks_len_input = self:build_ks_len_input()
  local ks_mix_input = self:build_ks_mix_input()
  local ks_amp_input = self:build_ks_amp_input()
  local ks_reset = self:build_ks_reset()

  local appendix
  = self.vb:row{
    id = 'appendix',
    visible = false,
    ks_btn, ks_len_input, ks_mix_input, ks_amp_input, ks_reset,
    margin = 6}

  local app_btn =
  self.vb:button
  {
    id = 'app_btn',
    width = 3,
    text = "App.",
    tooltip =
    "Appendix",
    
    notifier = 
    function()
      if
        self.vb.views.appendix.visible == false
      then
        self.vb.views.appendix.visible = true
        self.vb.views.app_btn.text = 'close'
      else
        self.vb.views.appendix.visible = false
        self.vb.views.app_btn.text = 'app.'
      end
    end
  }
  ]]  

end 


---------------------------------------------------------------------------------------------------

function SSK_Gui:build_percent_factor(label,obs)  

  return self.vb:row{
    spacing = SSK_Gui.NULL_SPACING,
    self.vb:text{
      text = "Factor",
      width = SSK_Gui.SMALL_LABEL_WIDTH,
    },
    self.vb:valuebox{
      min = 0,
      max = 100,
      bind = obs,
    },
    self.vb:space{
      width = SSK_Gui.ITEM_MARGIN,
    },
    self.vb:text{
      text = "%",
    }
  }

end

---------------------------------------------------------------------------------------------------

function SSK_Gui:build_modify_panel()

  return self.vb:column{
    style = SSK_Gui.PANEL_STYLE,
    margin = SSK_Gui.PANEL_INNER_MARGIN,
    self.vb:space{
      width = SSK_Gui.DIALOG_INNER_WIDTH,
    },
    self.vb:row{
      self:build_panel_header("Modify",function()
      end,prefs.display_modify_panel),
    },    
    self.vb:column{    
      id = "ssk_modify_panel",
      visible = false, 
      self.vb:column{
        self.vb:row{
          style = SSK_Gui.ROW_STYLE,
          margin = SSK_Gui.ROW_MARGIN,
          spacing = SSK_Gui.ROW_SPACING,
          self.vb:text{
            text = "Shift",
            width = SSK_Gui.LABEL_WIDTH,
          },
          self:build_phase_shift_plus(),
          self:build_phase_shift_minus(),
          self:build_phase_shift_fine_plus(),
          self:build_phase_shift_fine_minus(), 
        },         
        self.vb:row{
          style = SSK_Gui.ROW_STYLE,
          margin = SSK_Gui.ROW_MARGIN,
          spacing = SSK_Gui.ROW_SPACING,
          self.vb:text{
            text = "Center",
            width = SSK_Gui.LABEL_WIDTH,
          },
          self.vb:button{
            id = "ssk_generate_fade_center_a_bt",
            width = SSK_Gui.WIDE_BT_WIDTH,
            bitmap = self.btmp.center_fade,
            height = SSK_Gui.TALL_BT_HEIGHT,
            tooltip = "Fade center",
            notifier = function()
              self.owner:set_fade(SSK.center_fade_fn)
            end,
          },
          self.vb:button{
            id = "ssk_generate_fade_center_b_bt",
            width = SSK_Gui.WIDE_BT_WIDTH,
            bitmap = self.btmp.center_amplify,
            height = SSK_Gui.TALL_BT_HEIGHT,
            tooltip = "Amplify center",
            notifier = function()
              self.owner:set_fade(SSK.center_amplify_fn)
            end,
          }, 
          self:build_percent_factor("Factor",prefs.center_fade_percent),           
        },
        self.vb:row{
          style = SSK_Gui.ROW_STYLE,
          margin = SSK_Gui.ROW_MARGIN,
          spacing = SSK_Gui.ROW_SPACING,
          self.vb:text{
            text = "Multiply",
            width = SSK_Gui.LABEL_WIDTH,
          },
          self.vb:button{
            id = "ssk_generate_multiply_lower_bt",
            width = SSK_Gui.WIDE_BT_WIDTH,
            bitmap = self.btmp.multiply_lower,
            height = SSK_Gui.TALL_BT_HEIGHT,
            tooltip = "Lower amplitude",
            notifier = function()
              self.owner:set_fade(SSK.multiply_lower_fn)
            end,
          },
          self.vb:button{
            id = "ssk_generate_multiply_raise_bt",
            width = SSK_Gui.WIDE_BT_WIDTH,
            bitmap = self.btmp.multiply_raise,
            height = SSK_Gui.TALL_BT_HEIGHT,
            tooltip = "Raise amplitude",
            notifier = function()
              self.owner:set_fade(SSK.multiply_raise_fn)
            end,
          },
          self:build_percent_factor("Factor",prefs.multiply_percent),           
        },
        self.vb:row{
          style = SSK_Gui.ROW_STYLE,
          margin = SSK_Gui.ROW_MARGIN,
          spacing = SSK_Gui.ROW_SPACING,
          self.vb:text{
            text = "Fade",
            width = SSK_Gui.LABEL_WIDTH,
          },
          self.vb:button{
            id = "ssk_generate_fade_in_bt",
            width = SSK_Gui.WIDE_BT_WIDTH,
            bitmap = self.btmp.fade_in,
            height = SSK_Gui.TALL_BT_HEIGHT,
            tooltip = "Fade in",
            notifier = function()
              self.owner:set_fade(SSK.fade_in_fn)
            end,
          },
          self.vb:button{
            id = "ssk_generate_fade_out_bt",
            width = SSK_Gui.WIDE_BT_WIDTH,
            bitmap = self.btmp.fade_out,
            height = SSK_Gui.TALL_BT_HEIGHT,
            tooltip = "Fade out",
            notifier = function()
              self.owner:set_fade(SSK.fade_out_fn)
            end,
          }, 
          self:build_percent_factor("Factor",prefs.fade_percent),           
        },
        --[[
        self.vb:row{
          style = SSK_Gui.ROW_STYLE,
          margin = SSK_Gui.ROW_MARGIN,
          --width = "100%",
          spacing = SSK_Gui.ROW_SPACING,
          self.vb:text{
            text = "Resize",
            width = SSK_Gui.LABEL_WIDTH,
            --align = "center"
          },
          self.vb:button{
            id = "ssk_resize_expand_bt",
            width = SSK_Gui.WIDE_BT_WIDTH,
            bitmap = self.btmp.resize_expand,
            height = SSK_Gui.TALL_BT_HEIGHT,
            tooltip = "Expand selection",
            notifier = function()
              self.owner:resize_expand()
            end,
          },           
          self.vb:button{
            id = "ssk_resize_shrink_bt",
            width = SSK_Gui.WIDE_BT_WIDTH,
            bitmap = self.btmp.resize_shrink,
            height = SSK_Gui.TALL_BT_HEIGHT,
            tooltip = "Shrink selection",
            notifier = function()
              self.owner:resize_shrink()
            end,
          }, 
          self:build_percent_factor("Factor",prefs.resize_percent),           
        },
        ]]
        self.vb:row{
          style = SSK_Gui.ROW_STYLE,
          margin = SSK_Gui.ROW_MARGIN,
          spacing = SSK_Gui.ROW_SPACING,
          self.vb:text{
            text = "Ringmod",
            width = SSK_Gui.LABEL_WIDTH,
          },
          self:build_ring_mod_sin(),
          self:build_ring_mod_saw(),
          self:build_ring_mod_square(),
          self:build_ring_mod_triangle(),
          self:build_pd_copy(),
        },
        self.vb:row{      
          self.vb:space{
            width = SSK_Gui.ITEM_HEIGHT,
          },        
          self:build_fade_cycle_shift_set(), 
          self.vb:space{
            height = SSK_Gui.ITEM_SPACING,
          },
          self:build_pd_duty_cycle(), 
        },
      }
    }
  }

end 

---------------------------------------------------------------------------------------------------
-- set selection start 

function SSK_Gui:build_selection_start_row()

  return self.vb:row{ 
    self.vb:text{
      width = SSK_Gui.LABEL_WIDTH - SSK_Gui.TOGGLE_SIZE - 2,
      text = "Start"
    },    
    self.vb:button{
      text = "➙",
      id = "ssk_get_selection_start",
      tooltip = "Get selection start in the waveform editor.",
      notifier = function()
        self.owner:obtain_sel_start_from_editor()        
      end,
    },    
    self.vb:textfield{ 
      id = "ssk_selection_start",
      width = SSK_Gui.INPUT_WIDTH,
      tooltip = SSK_Gui.MSG_GET_LENGTH_BEAT_TIP, 
      notifier = function(x)
        print("ssk_selection_start notifier",x)
        local buffer = self.owner:get_sample_buffer()
        if not buffer then 
          return
        end
        local is_start = true -- allow first frame
        local offset,beat,frame = self.owner:interpret_selection_input(x,is_start)
        if (not frame or not beat or not offset) then 
          renoise.app():show_error(SSK_Gui.MSG_GET_LENGTH_FRAME_ERR)
        else 
          self.owner.sel_start_frames = frame
          self.owner.sel_start_beats = beat
          self.owner.sel_start_offset = offset
        end
      end
    },
    self.vb:button{
      text = "Set",
      id = "ssk_selection_apply_start",
      tooltip = "Click to update the selection start (and extend the sample if needed).",
      notifier = function()
        local sel_length = self.owner.sel_length_frames
        local sel_start = self.owner.sel_start_frames
        self.owner:apply_selection_range(sel_length,sel_start)
      end
    },

  }
end 

---------------------------------------------------------------------------------------------------
-- set selection length 

function SSK_Gui:build_selection_length_row()

  return self.vb:row{ 
    self.vb:text{
      width = SSK_Gui.LABEL_WIDTH - SSK_Gui.TOGGLE_SIZE - 2,
      text = "Length"
    },    
    self.vb:button{
      text = "➙",
      id = "ssk_get_selection_length",
      tooltip = "Get length of selection in the waveform editor.",
      notifier = function()
        self.owner:obtain_sel_length_from_editor()        
      end,
    },    
    self.vb:textfield{ 
      id = "ssk_selection_length",
      width = SSK_Gui.INPUT_WIDTH,
      tooltip = SSK_Gui.MSG_GET_LENGTH_BEAT_TIP, 
      notifier = function(x)
        print("ssk_selection_length notifier",x)
        local buffer = self.owner:get_sample_buffer()
        if not buffer then 
          return
        end
        local offset,beat,frame = self.owner:interpret_selection_input(x)
        if (not frame or not beat or not offset) then 
          renoise.app():show_error(SSK_Gui.MSG_GET_LENGTH_FRAME_ERR)
        else 
          self.owner.sel_length_frames = frame
          self.owner.sel_length_beats = beat
          self.owner.sel_length_offset = offset
        end
      end
    },
    self.vb:button{
      text = "Set",
      id = "ssk_selection_apply_length",
      tooltip = "Click to update the selection length (and extend the sample if needed).",
      notifier = function()
        self.owner:apply_selection_range(self.owner.sel_length_frames)
      end
    },
    self.vb:button{
      id = "ssk_selection_multiply_length",
      text = "*",
      tooltip = "Multiply the length of the selection range .",
      notifier = function()
        self.owner:selection_multiply_length()
      end,
    },
    self.vb:button{
      id = "ssk_selection_divide_length",
      text = "/",
      tooltip = "Reset the length of the selection range with reciprocal number.",
      notifier = function()
        self.owner:selection_divide_length()
      end,
    },
    self.vb:textfield{ 
      id = "multiply_setend",
      text = tostring(prefs.multiply_setend.value),
      tooltip = SSK_Gui.MSG_MULTIPLY_TIP,
      notifier = function(x)
        local xx = cReflection.evaluate_string(x) 
        if xx == nil
        then
          renoise.app():show_error(SSK_Gui.MSG_MULTIPLY_ERR)
        else 
          self.owner.multiply_setend = xx
        end
      end
    },
  }
end 

---------------------------------------------------------------------------------------------------
  -- Draw sin wave 2pi
function SSK_Gui:build_sin_2pi()  
  return self.vb:button{
    id = "ssk_generate_sin_wave_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.sin_2pi,
    height = SSK_Gui.TALL_BT_HEIGHT,
    tooltip = "Draw sin wave.",
    notifier = function()
      self.owner:generate_sine_wave()
    end,
  }
end

---------------------------------------------------------------------------------------------------
  -- saw wave
function SSK_Gui:build_saw_wave()  
  
  return self.vb:button{
    id = "ssk_generate_saw_wave_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.saw,
    height = SSK_Gui.TALL_BT_HEIGHT,
    tooltip = "Draw saw wave.",
    notifier = function()
      self.owner:generate_saw_wave()
    end,
  }
end

---------------------------------------------------------------------------------------------------
-- square wave

function SSK_Gui:build_square_wave()  

  return self.vb:button{
    id = "ssk_generate_square_wave_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.square,
    height = SSK_Gui.TALL_BT_HEIGHT,
    tooltip = "Draw square wave.",
    notifier = function()
      self.owner:generate_square_wave()
    end,
  }
end

---------------------------------------------------------------------------------------------------
-- triangle wave

function SSK_Gui:build_triangle_wave()
  return self.vb:button{
    id = "ssk_generate_triangle_wave_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.triangle,
    height = SSK_Gui.TALL_BT_HEIGHT,
    tooltip = "Draw triangle wave.",
    notifier = function()
      self.owner:generate_triangle_wave()
    end,
  }
end

---------------------------------------------------------------------------------------------------
-- Band limiting check box

function SSK_Gui:build_band_limited_check()

  return self.vb:row{
    self.vb:checkbox{
      id = 'band_limited',
      bind = prefs.band_limited,
    },
    self.vb:text{
      text = "Band-limiting",
      width = SSK_Gui.LABEL_WIDTH,
    },  
  }
end 

---------------------------------------------------------------------------------------------------
-- Wave modulating values input

function SSK_Gui:build_cycle_shift_set()

  return self.vb:column{
    self.vb:row{
      self.vb:text{
        text = "Cycle",
        width = SSK_Gui.SMALL_LABEL_WIDTH,
      },
      self.vb:textfield{
        id = 'mod_cycle',
        text = tostring(prefs.mod_cycle.value),
        width = SSK_Gui.FORMULA_WIDTH,
        tooltip = SSK_Gui.MSG_MOD_CYCLE,
        notifier = function(x)
          local xx = cReflection.evaluate_string(x)
          if xx == nil then
            local msg = 
            renoise.app():show_error(msg)
          else
            self.owner.mod_cycle = xx
          end
        end
      },
    },
    self.vb:row{
      self.vb:text{
        text = "Shift",
        width = SSK_Gui.SMALL_LABEL_WIDTH,
      },
      self.vb:valuebox{
        id = 'mod_shift',
        bind = prefs.mod_shift,
        min = -100,
        max = 100,
        tostring = function(x)
          return tostring(cLib.round_with_precision(x,3))
        end,
        tonumber = function(x)
          return cReflection.evaluate_string(x)
        end,
        tooltip = SSK_Gui.MSG_MOD_SHIFT,
        notifier = function(x)       
          --prefs.mod_shift.value = x/100
        end
      },
      self.vb:text {
        text = "% "
      },      
      self.vb:button{
        text = "Reset",
        tooltip = "Reset values.",
        notifier = function()
          self.vb.views.mod_cycle.text = '1'
          prefs.mod_shift.value= 0
        end,
      },      
       
    }
  }

end 

---------------------------------------------------------------------------------------------------
-- Duty Cycle variation in the range

function SSK_Gui:build_duty_cycle()

  return self.vb:column{
    self.vb:row{
      self.vb:checkbox{
        id = 'duty_onoff',
        bind = prefs.mod_duty_onoff,
      },  
      self.vb:text{
        text = "Duty cycle",
      },  
    },
    -- Input duty cycle 
    self.vb:row{
      self.vb:text{
        text = "Cycle",
        width = SSK_Gui.SMALL_LABEL_WIDTH,
      },
      self.vb:valuebox{
        id = 'duty_fiducial',
        value = prefs.mod_duty.value,
        min = 0,
        max = 100,
        tostring = function(x)
          return tostring(cLib.round_with_precision(x,3))
        end,
        tonumber = function(x)
          return cReflection.evaluate_string(x)
        end,
        tooltip = "Input duty cycle (fiducial value)",
        notifier = function(x)       
          prefs.mod_duty.value = tonumber(x)
        end
      },
      self.vb:text{
        text = "% "
      },
      self.vb:button{
        text = "Reset",
        tooltip = "Reset values.",
        notifier = function()
          self.vb.views.duty_fiducial.value = 50
          self.vb.views.duty_variation.value = 0
          self.vb.views.duty_var_frq.value = 1
        end,
      },
    },    
    self.vb:row{
      self.vb:text{
        text = "Var",
        width = SSK_Gui.SMALL_LABEL_WIDTH,
      },
      self.vb:valuebox{
        id = 'duty_variation',
        value = prefs.mod_duty_var.value,
        min = -100,
        max = 100,
        tostring = function(x)
          return tostring(cLib.round_with_precision(x,3))
        end,
        tonumber = function(x)
          return cReflection.evaluate_string(x)
        end,
        tooltip = SSK_Gui.MSG_DUTY_VAR,
        notifier = function(x)       
          prefs.mod_duty_var.value = x
        end
      },
      self.vb:text{
        text = "% "
      },
    },
    self.vb:row{
      self.vb:text{
        text = "Freq",
        width = SSK_Gui.SMALL_LABEL_WIDTH,
      },
      self.vb:valuebox{
        id = 'duty_var_frq',
        value = prefs.mod_duty_var_frq.value,
        min = -10000,
        max = 10000,
        tostring = function(x)
          return tostring(cLib.round_with_precision(x,3))
        end,
        tonumber = function(x)
          return cReflection.evaluate_string(x)
        end,
        tooltip = SSK_Gui.MSG_DUTY_FRQ,
        notifier = function(x)       
          prefs.mod_duty_var_frq.value = x
        end
      },
    },
  }
end 

---------------------------------------------------------------------------------------------------
-- White noise

function SSK_Gui:build_white_noise()
  return self.vb:button{
    id = "ssk_generate_white_noise_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    height = SSK_Gui.TALL_BT_HEIGHT,
    bitmap = self.btmp.white_noise,
    tooltip = "White noise",
    notifier = function()
      self.owner:make_wave(cWaveform.white_noise_fn)
    end,
  }
end

---------------------------------------------------------------------------------------------------
  -- Brown noise

function SSK_Gui:build_brown_noise()
  return self.vb:button{
    id = "ssk_generate_brown_noise_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    height = SSK_Gui.TALL_BT_HEIGHT,
    bitmap = self.btmp.brown_noise,
    tooltip = "Brown noise",
    notifier = function()
      self.owner:make_wave(cWaveform.brown_noise_fn)
    end,
  }
end 

---------------------------------------------------------------------------------------------------
-- Violet noise

function SSK_Gui:build_violet_noise()
  return self.vb:button{
    id = "ssk_generate_violet_noise_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    height = SSK_Gui.TALL_BT_HEIGHT,
    bitmap = self.btmp.violet_noise,
    tooltip = "Violet noise",
    notifier = function()
      self.owner:make_wave(cWaveform.violet_noise_fn)
    end,
  }
end 

---------------------------------------------------------------------------------------------------
  -- Pink noise (Unfinished)
--[[
function SSK_Gui:build_pink_noise()  
  return self.vb:button{
    width = SSK_Gui.WIDE_BT_WIDTH,
    height = SSK_Gui.TALL_BT_HEIGHT,
    tooltip = "Pink noise",
    notifier = function()
      self.owner:make_wave(cWaveform.pink_noise_fn)
      random_seed = 0
    end,
  }
end 
]]

---------------------------------------------------------------------------------------------------
  -- Phase shift 1/24 +
function SSK_Gui:build_phase_shift_plus()  
  return self.vb:button{
    id = "ssk_generate_shift_plus_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.phase_shift_plus,
    tooltip = "Phase shift +1/24",
    notifier = function()
      self.owner:phase_shift_with_ratio(1/24)
    end,
  }
end  

---------------------------------------------------------------------------------------------------
  -- Phase shift 1/24 +
function SSK_Gui:build_phase_shift_minus()  
  return self.vb:button{
    id = "ssk_generate_shift_minus_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.phase_shift_minus,
    tooltip = "Phase shift -1/24",
    notifier = function()
      self.owner:phase_shift_with_ratio(-1/24)
    end,
  }
end 

---------------------------------------------------------------------------------------------------
--  Phase shift +1sample

function SSK_Gui:build_phase_shift_fine_plus()  
  return self.vb:button{
    id = "ssk_generate_shift_plus_fine_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.phase_shift_fine_plus,
    tooltip = "Phase shift +1sample",
    notifier = function()
      self.owner:phase_shift_fine(1)
    end,
  }
end 

---------------------------------------------------------------------------------------------------
-- Phase shift -1sample

function SSK_Gui:build_phase_shift_fine_minus()  
  return self.vb:button{
    id = "ssk_generate_shift_minus_fine_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.phase_shift_fine_minus,
    tooltip = "Phase shift -1sample",
    notifier = function()
      self.owner:phase_shift_fine(-1)
    end,
  }
end 

---------------------------------------------------------------------------------------------------
--Fade with sin wave

function SSK_Gui:build_ring_mod_sin()
  return self.vb:button{
    id = "ssk_generate_rm_sin_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.ring_mod_sin,
    height = SSK_Gui.TALL_BT_HEIGHT,
    tooltip = "Fade (Ring modulation) with sin",
    notifier = function()
      self.owner:fade_mod_sin()
    end,
  }
end 

---------------------------------------------------------------------------------------------------
-- Fade with saw wave

function SSK_Gui:build_ring_mod_saw()
  return self.vb:button{
    id = "ssk_generate_rm_saw_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.ring_mod_saw,
    height = SSK_Gui.TALL_BT_HEIGHT,
    tooltip = "Fade (Ring modulation) witn saw",
    notifier = function()
      self.owner:fade_mod_saw()
    end,
  }
end 

---------------------------------------------------------------------------------------------------
-- Fade with square wave

function SSK_Gui:build_ring_mod_square()  
  return self.vb:button{
    id = "ssk_generate_rm_square_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.ring_mod_square,
    height = SSK_Gui.TALL_BT_HEIGHT,
    tooltip = "Fade (Ring modulation) witn square",
    notifier = function()
      self.owner:fade_mod_square()
    end,
  }
end 

---------------------------------------------------------------------------------------------------
-- Fade with triangle wave

function SSK_Gui:build_ring_mod_triangle()  
  return self.vb:button{
    id = "ssk_generate_rm_triangle_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.ring_mod_triangle,
    height = SSK_Gui.TALL_BT_HEIGHT,
    tooltip = "Fade (Ring modulation) witn triangle",
    notifier = function()
      self.owner:fade_mod_triangle()
    end,
  }
end 


---------------------------------------------------------------------------------------------------

function SSK_Gui:build_pd_copy()
  return self.vb:button{
    id = "ssk_generate_pd_copy_bt",
    --bitmap = self.btmp.pd_copy,
    text = "PD Copy",
    width = SSK_Gui.WIDE_BT_WIDTH,
    height = SSK_Gui.TALL_BT_HEIGHT,
    tooltip = SSK_Gui.MSG_COPY_PD,
    notifier = function()
      self.owner:pd_copy()
    end,
  }
end 

---------------------------------------------------------------------------------------------------
-- Set phase distortion values in feding & PD-copy 

function SSK_Gui:build_fade_cycle_shift_set()

  return self.vb:column{
    self.vb:row{
      self.vb:text{
        text = "Cycle",  
        width = SSK_Gui.SMALL_LABEL_WIDTH,
      },
      self.vb:textfield{
        id = 'mod_fade_cycle',
        width = SSK_Gui.FORMULA_WIDTH,
        text = tostring(prefs.mod_fade_cycle.value),
        tooltip = SSK_Gui.MSG_FADE_TIP, 
        notifier = function(x)
          local xx = cReflection.evaluate_string(x)
          if xx == nil
          then
            local msg = SSK_Gui.MSG_FADE
            renoise.app():show_error(err)
          else
            self.owner.mod_fade_cycle = xx
          end
        end
      },
    },
    self.vb:row{
      self.vb:text{
        text = "Shift",
        width = SSK_Gui.SMALL_LABEL_WIDTH,
      },
      self.vb:valuebox{
        id = 'mod_fade_shift',
        value = prefs.mod_fade_shift.value*100,
        min = -100,
        max = 100,
        tostring = function(x)
          return tostring(cLib.round_with_precision(x,3))
        end,
        tonumber = function(x)
          return cReflection.evaluate_string(x)
        end,
        tooltip = SSK_Gui.MSG_FADE_SHIFT,      
        notifier = function(x)       
          prefs.mod_fade_shift.value = x/100
        end
      },
      self.vb:text{
        text = "% "
      },    
      self.vb:button{
        text = "Reset",
        tooltip = "Reset values.",
        notifier = function()
          self.vb.views.mod_fade_cycle.text = '1'
          prefs.mod_fade_shift.value = 0
        end,
      },
    }
  }
end 

---------------------------------------------------------------------------------------------------
-- Duty cycle for fade & phase distortion copy

function SSK_Gui:build_pd_duty_cycle()
  return self.vb:column{
    self.vb:row{
      self.vb:checkbox{
        id = 'pd_duty_onoff',
        bind = prefs.mod_pd_duty_onoff,
      },  
      self.vb:text{
        text = "Duty Cycle"
      },  
    },
    self.vb:row{    
      self.vb:text{
        text = "Cycle",     
        width = SSK_Gui.SMALL_LABEL_WIDTH, 
      },
      self.vb:valuebox{
        id = 'pd_duty_fiducial',
        value = prefs.mod_pd_duty.value,
        min = 0,
        max = 100,
        tostring = function(x)
          return tostring(cLib.round_with_precision(x,3))
        end,
        tonumber = function(x)
          return cReflection.evaluate_string(x)
        end,
        tooltip = "Input duty cycle (fiducial value)",
        notifier = function(x)       
          prefs.mod_pd_duty.value = tonumber(x)
        end
      },
      self.vb:text{
        text = "% "
      },
      self.vb:button{
        text = "Reset",
        tooltip = "Reset values.",
        notifier = function()
          self.vb.views.pd_duty_fiducial.value = 50
          self.vb.views.pd_duty_variation.value = 0
          self.vb.views.pd_duty_var_frq.value = 1
        end,
      },      
    },
    self.vb:row{
      self.vb:text{
        text = "Var",
        width = SSK_Gui.SMALL_LABEL_WIDTH,
      },
      self.vb:valuebox{
        id = 'pd_duty_variation',
        value = self.owner.mod_pd_duty_var,
        min = -100,
        max = 100,
        tostring = function(x)
          return tostring(cLib.round_with_precision(x,3))
        end,
        tonumber = function(x)
          return cReflection.evaluate_string(x)
        end,
        tooltip = SSK_Gui.MSG_MOD_DUTY_VAR,
        notifier = function(x)       
          self.owner.mod_pd_duty_var = tonumber(x)
        end
      },
      self.vb:text{
        text = "% "
      },
    },
    self.vb:row{
      self.vb:text{
        text = "Freq",
        width = SSK_Gui.SMALL_LABEL_WIDTH,
      },
      self.vb:valuebox{
        id = 'pd_duty_var_frq',
        value = self.owner.mod_pd_duty_var_frq,
        min = -10000,
        max = 10000,
        tostring = function(x)
          return tostring(cLib.round_with_precision(x,3))
        end,
        tonumber = function(x)
          return cReflection.evaluate_string(x)
        end,      
        tooltip = SSK_Gui.MSG_MOD_DUTY_FRQ,
        notifier = function(x)       
          self.owner.mod_pd_duty_var_frq = x
        end
      },
    }    
  }
end 

---------------------------------------------------------------------------------------------------
-- Karplus-Strong String
--[[
function SSK_Gui:build_ks_btn()
  return self.vb:button{
    --width = 80,
    text = 'KS String',
    tooltip = "This modulates the sample with Karplus-Strong string synthesis." 
            .."\nPlease prepare selection length that is longer than ks-length value.",
    notifier = function(x)       
      local fn = ks_copy_fn_fn(
        self.owner.ks_len_var,
        self.owner.ks_mix_var,
        self.owner.ks_amp_var)
      self.owner:make_wave(fn)
    end    
  }  
end 

---------------------------------------------------------------------------------------------------
-- Input K-s string first pulse length

function SSK_Gui:build_ks_len_input()
  return self.vb:row{
    self.vb:text{
      text = "length:"
    },
    self.vb:textfield{
      id = 'ks_len',
      --edit_mode = true,
      text = tostring(self.owner.ks_len_var),
      tooltip = "Input the length of K-S synthesis first pulse."
              .."\nThis determines the pitch."
              .."\nYou can use some letters that represents pitch, e.g.'C#4'.",      
      notifier = function(x)
        local xx = SSK.string_to_frames(x,prefs.A4hz.value) 
        if xx == nil
        then
          renoise.app():show_error("Enter a  non-zero number, or a numerical formula. This decides string pitch.")
        else
          self.owner.ks_len_var = xx
        end
      end
    }
  }
end 

---------------------------------------------------------------------------------------------------
-- Input dry-mix value in K-s string

function SSK_Gui:build_ks_mix_input()
  return self.vb:row{
    self.vb:text{
      text = " mix:"
    },    
    self.vb:valuebox{
      id = 'ks_mix',
      value = self.owner.ks_mix_var,
      min = 0,
      max = 100,
      tostring = function(x)
        return tostring(cLib.round_with_precision(x,3))
      end,
      tonumber = function(x)
        return cReflection.evaluate_string(x)
      end,
      tooltip = "Input dry-mix value for K-S string.",      
      notifier = function(x)       
        self.owner.ks_mix_var = x/100
      end
    },
    self.vb:text{
      text = "% "
    }
  }
end 

---------------------------------------------------------------------------------------------------
-- Input amplification value in K-s string

function SSK_Gui:build_ks_amp_input()
  return self.vb:row{
    self.vb:text{
      text = "amp:"
    },    
    self.vb:valuebox{
      id = 'ks_amp',
      value = self.owner.ks_amp_var,
      min = 0,
      max = 1000,
      tostring = function(x)
        return tostring(cLib.round_with_precision(x,3))
      end,
      tonumber = function(x)
        return cReflection.evaluate_string(x)
      end,
      tooltip = "Input amplification value for K-S string",      
      notifier = function(x)       
        self.owner.ks_amp_var = x/1000
      end
    },
    
  }
end 

---------------------------------------------------------------------------------------------------
-- Reset K-S string values 

function SSK_Gui:build_ks_reset()
  return self.vb:button{
    text = "Reset",
    tooltip = "Reset values.",
    notifier = function()
      self.vb.views.ks_len.text = tostring(SSK.string_to_frames('C-4',prefs.A4hz.value))
      self.vb.views.ks_mix.value = 0
      self.vb.views.ks_amp.value = 0
    end,
  }
end 
]]

---------------------------------------------------------------------------------------------------
-- Make random waves

function SSK_Gui:build_panel_header(title,callback,cb_binding)
  return self.vb:row{
    self.vb:checkbox{
      bind = cb_binding,
      width = SSK_Gui.TOGGLE_SIZE,
      height = SSK_Gui.TOGGLE_SIZE,        
      notifier = callback, 
    },
    self.vb:text{
      text = title,
      font = SSK_Gui.PANEL_HEADER_FONT,
    },
  }  
end 

---------------------------------------------------------------------------------------------------

function SSK_Gui:idle_notifier()

  if self.dialog then
    if self.update_strip_requested then 
      self.update_strip_requested = false
      self:update_selection_strip()
      self:update_buffer_controls()    
      self:update_selection_strip_controls()
    end 
    if self.update_toolbar_requested then 
      self.update_toolbar_requested = false
      self:update_toolbar()
    end 
    if self.update_selection_requested then 
      self.update_selection_header_requested = true
      self.update_selection_requested = false
      self:update_selection_length()
    end 
    if self.update_selection_header_requested then 
      self.update_selection_header_requested = false
      self:update_selection_header()
    end 
    if self.update_select_panel_requested then 
      self.update_select_panel_requested = false 
      self:update_select_panel()
    end 
    if self.update_generate_panel_requested then 
      self.update_generate_panel_requested = false 
      self:update_generate_panel()
    end 
    if self.update_modify_panel_requested then 
      self.update_modify_panel_requested = false 
      self:update_modify_panel()
    end 
  end 

end

