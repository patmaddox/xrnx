--[[===============================================================================================
-- cDocument
===============================================================================================]]--

--[[--

Create lightweight classes with improved import/export/debugging features
.
#

For the cDocument to work, you need to define a static DOC_PROPS property that specifies 
the 'basic' property type (number, boolean, string or table) of each property that you 
want to include. 

--]]

--=================================================================================================
require (_clibroot.."cReflection")

class 'cDocument'

---------------------------------------------------------------------------------------------------
-- import serialized values that match one of our DOC_PROPS
-- @param str (string) serialized values 

function cDocument:import(str)
  TRACE("cDocument:export(str)",str)

  assert(type(str)=="string")

  local t = cDocument.deserialize(str,self.DOC_PROPS)
  for k,v in pairs(t) do
    self[k] = v
  end

end

---------------------------------------------------------------------------------------------------
-- @return string, serialized values

function cDocument:export()
  TRACE("cDocument:export()")

  local t = cDocument.serialize(self,self.DOC_PROPS)
  return cLib.serialize_table(t)

end

---------------------------------------------------------------------------------------------------
-- [Static] apply properties to an 'actual' object

function cDocument:apply(obj)
  TRACE("cDocument:apply(obj)",obj)

  for k,v in pairs(self.DOC_PROPS) do   
    local val = self[k]
    print("*** about to apply value ",obj,k,v,val)
    if not (obj[k] == val) then
      obj[k] = val
    else
      --print("*** skipped (identical value) ")
    end
  end

end

---------------------------------------------------------------------------------------------------
-- collect properties from object
-- @param obj (class instance)
-- @param props (table) DOC_PROPS
-- @return table 

function cDocument.serialize(obj,props)
  TRACE("cDocument:serialize(obj,props)",obj,props)

  assert(type(props)=="table")

  local t = {}
  for k,v in pairs(props) do
    local prop_type = props[k]
    if prop_type then
      if cDocument.is_cdoc_instance(prop_type) then
        t[k] = obj[k]:export()
      else
        t[k] = cReflection.cast_value(obj[k],prop_type)
      end
    else
      t[k] = obj[k]
    end
  end
  return t

end

---------------------------------------------------------------------------------------------------
-- true when "classname" exists in global namespace, and contain an export method 
-- @param classname (string)
-- @return boolean

function cDocument.is_cdoc_instance(classname)
  TRACE("cDocument.is_cdoc_instance(classname)",classname)

  -- reserved names 
  if (classname == "table" or classname == "string") then 
    return false 
  end

  local success,err = pcall(function()
    return (_G[classname] and type(_G[classname].export)=="function")
  end)
  return success
  
end

---------------------------------------------------------------------------------------------------
-- deserialize string 
-- @param str (str) serialized string
-- @param props (table) DOC_PROPS
-- @return table or nil

function cDocument.deserialize(str,props)
  TRACE("cDocument:deserialize(str,props)",str,props)

  assert(type(str)=="string")
  assert(type(props)=="table")

  local t = loadstring("return "..str)
  local deserialized = t()
  if not deserialized then
    return
  end
  
  t = {}
  for k,v in pairs(props) do
    if deserialized[k] then
      local property_type = v
      if property_type then
        t[k] = cReflection.cast_value(deserialized[k],property_type)
      else
        t[k] = deserialized[k]
      end
    end
  end

  return t

end

---------------------------------------------------------------------------------------------------
-- find property descriptor by key
-- @return table or nil

function cDocument.get_property(props,key)
  TRACE("cDocument.get_property(props,key)",props,key)

  assert(type(key)=="string")
  assert(type(props)=="table")

  for k,v in ipairs(props) do
    if (v.name == key) then
      return v,k
    end
  end

end

---------------------------------------------------------------------------------------------------
-- [Static] compare two instances - true if all properties match 
-- (will allow comparison between different types with compatible properties)

function cDocument.compare_objects(doc1,doc2) 
  TRACE("cDocument.compare_objects(doc1,doc2)",doc1,doc2)

  -- attempt quick compare using rawequal()
  if (type(doc1) == type(doc2)) then 
    if (rawequal(doc1, doc2)) then 
      --print("*** matched (rawequal)")
      return true
    end
  end

  local props = doc1.DOC_PROPS or doc2.DOC_PROPS   
  if not props then 
    error("Can't compare objects without a schema (DOC_PROPS)")
  end

  for k,v in pairs(props) do
    --print("k,v",k,v,doc1[k],doc2[k])
    local type1,type2 = type(doc1[k]),type(doc2[k])
    if (type1 ~= type2) then 
      --print("*** match failed (different types)")
      return false 
    elseif (v == "table") then 
      if (type1 ~= "nil" and type2 ~= "nil") 
        and not cLib.table_compare(doc1[k],doc2[k]) 
      then 
        --print("*** match failed (different content in table)")
        return false
      end
    else
      -- boolean/string/number
      if (doc1[k] ~= doc2[k]) then 
        --print("*** match failed (boolean/string/number)")
        return false
      end
    end
  end

  return true

end


---------------------------------------------------------------------------------------------------
-- list all registered properties

function cDocument:__tostring()

  local props = {}
  for k,v in pairs(self.DOC_PROPS) do 
    local str = (v == "table") 
      and (type(self[k]) ~= "nil") and cLib.serialize_table(self[k])
      or tostring(self[k])
    table.insert(props,("%s:%s"):format(k,str))
  end

  return type(self).." ("..table.concat(props,",")..")"

end
