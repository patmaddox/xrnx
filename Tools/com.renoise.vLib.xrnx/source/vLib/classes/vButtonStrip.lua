--[[===============================================================================================
vButtonStrip
===============================================================================================]]--

--[[

A button strip - each button with configurable appearance 
.

which decides 

]]

--=================================================================================================

class 'vButtonStripMember' 

---------------------------------------------------------------------------------------------------

function vButtonStripMember:__init(...)

  local args = cLib.unpack_args(...)
  
  -- number 
  self.weight = args.weight
  -- look & feel
  self.text = args.text 
  self.color = args.color
  self.tooltip = args.tooltip 

end


--=================================================================================================

class 'vButtonStrip' (vControl)

vButtonStrip.MIN_SEGMENT_W = 5

---------------------------------------------------------------------------------------------------

function vButtonStrip:__init(...)

  local args = cLib.unpack_args(...)

  -- properties -----------------------

  -- function, @param idx (number)
  self.pressed = args.pressed
  -- function, @param idx (number)
  self.released = args.released
  -- function, @param idx (number)
  self.notifier = args.notifier

  -- table<vButtonStripMember>
  self.items = property(self.get_items,self.set_items)
  self._items = {}

  -- string, message to display when no items are available
  self.placeholder_message = args.placeholder_message or "No items"

  -- internal -------------------------

  -- button instances in strip
  self.vb_strip_bts = {}

  -- initialize -----------------------

  vControl.__init(self,...)
  self:build()

  if not table.is_empty(args.items) then
    self.items = args.items
  end

end

---------------------------------------------------------------------------------------------------
-- Getters & Setters
---------------------------------------------------------------------------------------------------

function vButtonStrip:get_items()
  return self._items
end

function vButtonStrip:set_items(items)
  self._items = {}
  if not table.is_empty(items) then
    for k,v in ipairs(items) do 
      self:add_item(v)
    end 
  end
  self:request_update()
  
end

---------------------------------------------------------------------------------------------------
-- Super methods 
---------------------------------------------------------------------------------------------------

function vButtonStrip:set_width(val)
  vControl.set_width(self,val)
  self.vb_space.width = val
  self:request_update()
end

---------------------------------------------------------------------------------------------------

function vButtonStrip:set_height(val)
  vControl.set_height(self,val)
  self:request_update()
end

---------------------------------------------------------------------------------------------------

function vButtonStrip:set_active(b)
  for k,v in ipairs(self.vb_strip_bts) do 
    v.active = b
  end 
  vControl.set_active(self,b)
end

---------------------------------------------------------------------------------------------------
-- Class methods 
---------------------------------------------------------------------------------------------------

function vButtonStrip:build()
  TRACE("vButtonStrip:build()",self)

	local vb = self.vb  
  if not self.view then
    self.vb_space = vb:space{width = self.width}
    self.vb_row = vb:row{spacing = vLib.NULL_SPACING}
    self.view = vb:column{
      id = self.id,
      self.vb_space,
      self.vb_row,
    }
  end

  --self:clear()  
  self:update()

  --vControl.build(self)

end

---------------------------------------------------------------------------------------------------

function vButtonStrip:press(idx)
  TRACE("vButtonStrip:press(idx)",idx)
  if self.pressed then
    self.pressed(idx,self)
  end
end

---------------------------------------------------------------------------------------------------

function vButtonStrip:release(idx)
  TRACE("vButtonStrip:release(idx)",idx)

  if self.released then
    self.released(idx,self)
  end
  if self.notifier then
    self.notifier(idx,self)
  end
end

---------------------------------------------------------------------------------------------------

function vButtonStrip:_clear()
  for k,v in ipairs(self.vb_strip_bts) do 
    self.vb_row:remove_child(v)
  end 
  self.vb_strip_bts = {};

end

---------------------------------------------------------------------------------------------------

function vButtonStrip:show_placeholder(str_msg)
  TRACE("vButtonStrip:show_placeholder(str_msg)",str_msg)

  self:_clear()

	local vb = self.vb  
  local bt = self.vb:button{
    text = str_msg,
    width = self.width,
    height = self.height,
    active = false,
  }
  self.vb_row:add_child(bt)
  table.insert(self.vb_strip_bts,bt)    
end  

---------------------------------------------------------------------------------------------------

function vButtonStrip:update()
  TRACE("vButtonStrip:update()")

  self:_clear()

  if (#self.items == 0) then 
    self:show_placeholder(self.placeholder_message)
  elseif ((self.width/vButtonStrip.MIN_SEGMENT_W) < #self.items) then 
    self:show_placeholder("Not able to display this many items")
  else
    if (#self.items > 0) then
      local vb = self.vb
      -- weights are computed/OK, now render  
      local combined = self:get_combined_weight()
      local unit_w = self.width/combined
      local fraction = 0
      for k,v in ipairs(self.items) do 
        local bt_width = cLib.round_value(3 + math.max(1,v.weight*unit_w))
        local bt = self.vb:button{
          text = v.text,
          color = v.color,
          tooltip = v.tooltip,
          pressed = function()
            self:press(k)
          end,
          released = function()
            self:release(k)
          end,
        }
        bt.width = math.max(vButtonStrip.MIN_SEGMENT_W,bt_width)
        bt.height = self.height
        self.vb_row:add_child(bt)
        table.insert(self.vb_strip_bts,bt)
      end 
    end

  end        

end

---------------------------------------------------------------------------------------------------
-- get combined weights until provided item 
-- @return number 

function vButtonStrip:get_item_offset(item_idx)
  TRACE("vButtonStrip:get_item_offset(item_idx)",item_idx)

  local offset = 0
  item_idx = item_idx - 1

  for k = 1,item_idx do
    local item = self.items[k]
    if item then
      offset = offset + item.weight
    else
      break
    end
  end 
  return offset

end

---------------------------------------------------------------------------------------------------
-- return combined size of strip weights 

function vButtonStrip:get_combined_weight()
  local combined = 0
  for k,v in ipairs(self.items) do
    combined = combined + v.weight
  end 
  return combined
end
 
---------------------------------------------------------------------------------------------------
-- add item 

function vButtonStrip:add_item(member,at_idx)
  TRACE("vButtonStrip:add_item(member,at_idx)",member,at_idx)
  if at_idx then
    table.insert(self._items,at_idx,member)
  else
    table.insert(self._items,member)
  end

end
