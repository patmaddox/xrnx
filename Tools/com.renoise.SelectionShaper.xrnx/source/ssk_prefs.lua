--[[===============================================================================================
SSK_Prefs
===============================================================================================]]--

--[[

Preferences for the SSK tool 

]]

--=================================================================================================

class 'SSK_Prefs'(renoise.Document.DocumentNode)

---------------------------------------------------------------------------------------------------
-- constructor, 

function SSK_Prefs:__init()
  TRACE("SSK_Prefs:__init()")

  renoise.Document.DocumentNode.__init(self)

  -- user interface / initial settings
  self:add_property("sync_with_renoise", renoise.Document.ObservableBoolean(false))
  self:add_property("display_selection_panel", renoise.Document.ObservableBoolean(true))
  self:add_property("display_generate_panel", renoise.Document.ObservableBoolean(true))
  self:add_property("display_modify_panel", renoise.Document.ObservableBoolean(false))
  self:add_property("display_options_panel", renoise.Document.ObservableBoolean(false))
  self:add_property("display_selection_as", renoise.Document.ObservableNumber(0))
  self:add_property("multisample_mode", renoise.Document.ObservableBoolean(false))
  self:add_property("safe_mode", renoise.Document.ObservableBoolean(true))

  -- misc
  self:add_property("A4hz", renoise.Document.ObservableNumber(0))
  self:add_property("sig",renoise.Document.ObservableNumber(0))

  -- multisample_note_min
  self:add_property("multisample_note_min",renoise.Document.ObservableNumber(0))
  self:add_property("multisample_note_max",renoise.Document.ObservableNumber(0))
  self:add_property("multisample_note_steps",renoise.Document.ObservableNumber(0))
  self:add_property("multisample_vel_min",renoise.Document.ObservableNumber(0))
  self:add_property("multisample_vel_max",renoise.Document.ObservableNumber(0))
  self:add_property("multisample_vel_steps",renoise.Document.ObservableNumber(0))

  -- waveform
  self:add_property("multiply_setend", renoise.Document.ObservableString(""))
  self:add_property("mod_cycle", renoise.Document.ObservableString(""))
  self:add_property("mod_shift", renoise.Document.ObservableNumber(0))
  self:add_property("mod_duty_onoff", renoise.Document.ObservableBoolean(false))
  self:add_property("mod_duty", renoise.Document.ObservableNumber(0))
  self:add_property("mod_duty_var", renoise.Document.ObservableNumber(0))
  self:add_property("mod_duty_var_frq", renoise.Document.ObservableNumber(0))
  self:add_property("mod_fade_cycle", renoise.Document.ObservableString(""))
  self:add_property("mod_fade_shift", renoise.Document.ObservableNumber(0))
  self:add_property("mod_pd_duty_onoff", renoise.Document.ObservableBoolean(false))
  self:add_property("mod_pd_duty",renoise.Document.ObservableNumber(0))
  self:add_property("mod_pd_duty_var",renoise.Document.ObservableNumber(0))
  self:add_property("mod_pd_duty_var_frq",renoise.Document.ObservableNumber(0))
  self:add_property("flick_paste", renoise.Document.ObservableBoolean(false))
  self:add_property("band_limited", renoise.Document.ObservableBoolean(false))
  self:add_property("center_fade_percent", renoise.Document.ObservableNumber(0))
  self:add_property("multiply_percent", renoise.Document.ObservableNumber(0))
  self:add_property("fade_percent", renoise.Document.ObservableNumber(0))
  self:add_property("resize_percent", renoise.Document.ObservableNumber(0))

  --[[
  self:add_property("ks_len_var", renoise.Document.ObservableString(""))
  self:add_property("ks_mix_var",renoise.Document.ObservableNumber(0))
  self:add_property("ks_amp_var",renoise.Document.ObservableNumber(0))
  ]]


  self:reset()

end

---------------------------------------------------------------------------------------------------
-- initialize with default values

function SSK_Prefs:reset()

    self.display_selection_as.value = 1 --SSK_Gui.DISPLAY_AS

    self.multisample_note_min.value = xKeyZone.MIN_NOTE
    self.multisample_note_max.value = xKeyZone.MAX_NOTE
    self.multisample_note_steps.value = xKeyZone.DEFAULT_NOTE_STEPS
    self.multisample_vel_min.value = xKeyZone.MIN_VEL
    self.multisample_vel_max.value = xKeyZone.MAX_VEL
    self.multisample_vel_steps.value = xKeyZone.DEFAULT_VEL_STEPS

    self.A4hz.value = 440
    --self.sel_start_frames.value = "1"
    --self.sel_start_beats.value = "0"
    --self.sel_length_frames.value = "168"
    --self.sel_length_beats.value = "1"
    self.multiply_setend.value = "2"
    self.mod_cycle.value = "1"
    self.mod_shift.value = 0
    self.mod_duty_onoff.value = false
    self.mod_duty.value = 50
    self.mod_duty_var.value = 0
    self.mod_duty_var_frq.value = 1
    self.mod_fade_cycle.value = "1"
    self.mod_fade_shift.value = 0
    self.mod_pd_duty_onoff.value = false
    self.mod_pd_duty.value = 50
    self.mod_pd_duty_var.value = 0
    self.mod_pd_duty_var_frq.value = 1
    self.sig.value = 6
    self.flick_paste.value = false
    self.band_limited.value = true 

    self.center_fade_percent.value = (7/8)*100
    self.multiply_percent.value = (11/12)*100
    self.fade_percent.value = (7/8)*100
    self.resize_percent.value = (7/8)*100

    --[[
    self.ks_len_var.value = "168"
    self.ks_mix_var.value = 0
    self.ks_amp_var.value = 0
    ]]
end

