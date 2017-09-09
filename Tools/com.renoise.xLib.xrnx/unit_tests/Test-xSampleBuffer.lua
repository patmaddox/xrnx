--[[ 

  Testcase for xSampleBuffer

--]]

_xlib_tests:insert({
name = "xSampleBuffer",
fn = function()

  LOG(">>> xSampleBuffer: starting unit-test...")

  require (_clibroot.."cLib")
  require (_xlibroot.."xSampleBuffer")
  _trace_filters = {"^xSampleBuffer*"}

  -------------------------------------------------------------------------------------------------
  -- check for missing offsets in small buffers 
  -- (check against "offset minus one", because offsets are zero-based...)

  local filled,gaps = xSampleBuffer.get_offset_indices(67)
  --rprint(gaps)
  --assert(gaps[1]==0x02)
  assert(gaps[1]==0x01)
  assert(gaps[2]==0x03)
  assert(gaps[3]==0x04)
  assert(gaps[4]==0x05)
  assert(gaps[5]==0x07)
  assert(gaps[6]==0x08)
  assert(gaps[7]==0x09)
  assert(gaps[8]==0x0B)
  assert(gaps[9]==0x0C)
  assert(gaps[10]==0x0D)
  assert(gaps[11]==0x0F)
  assert(gaps[12]==0x10)
  assert(gaps[13]==0x11)
  assert(gaps[14]==0x13)
  assert(gaps[15]==0x14)
  assert(gaps[16]==0x15)

  local filled,gaps = xSampleBuffer.get_offset_indices(168)
  --rprint(gaps)
  assert(gaps[1]==0x02)
  assert(gaps[2]==0x05)
  assert(gaps[3]==0x08)
  assert(gaps[4]==0x0B)
  assert(gaps[5]==0x0E)
  assert(gaps[6]==0x11)
  assert(gaps[7]==0x13)
  assert(gaps[8]==0x16)
  assert(gaps[9]==0x19)
  assert(gaps[10]==0x1C)
  assert(gaps[11]==0x1F)

  local filled,gaps = xSampleBuffer.get_offset_indices(202)
  --rprint(gaps)
  assert(gaps[1]==0x03)
  assert(gaps[2]==0x08)
  assert(gaps[3]==0x0C)
  assert(gaps[4]==0x11)
  assert(gaps[5]==0x16)
  assert(gaps[6]==0x1B)
  assert(gaps[7]==0x1F)
  
  -------------------------------------------------------------------------------------------------
  -- frame <-> offset converters 

  -- testing against "smaller than offsets"
  local fake_buffer = {
    has_sample_data = true,
    number_of_frames = 67,
  }

  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,2)
  assert((offset==0x02),"expected offset to be 0x02: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,3)
  assert((offset==0x06),"expected offset to be 0x06: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,4)
  assert((offset==0x0A),"expected offset to be 0x0A: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,5)
  assert((offset==0x0E),"expected offset to be 0x0E: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,6)
  assert((offset==0x12),"expected offset to be 0x12: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,7)
  assert((offset==0x16),"expected offset to be 0x16: "..("%x"):format(offset))

  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x02)
  assert((frame==2),"expected frame to be 1: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x03) -- <= 0x02
  assert((frame==2),"expected frame to be 2: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x04) -- <= 0x02
  assert((frame==2),"expected frame to be 2: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x05) -- => 0x06
  assert((frame==3),"expected frame to be 3: "..tostring(frame))


  -- testing against "larger than offsets"
  local fake_buffer = {
    has_sample_data = true,
    number_of_frames = 1000,
  }

  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x00)
  assert((frame==1),"expected frame to be 1")
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x02)
  assert((frame==9),"expected frame to be 9: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x06)
  assert((frame==24),"expected frame to be 24: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x20)
  assert((frame==126),"expected frame to be 126: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x40)
  assert((frame==251),"expected frame to be 251: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x60)
  assert((frame==376),"expected frame to be 376: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x80)
  assert((frame==501),"expected frame to be 501: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0xFF)
  assert((frame==997),"expected frame to be 997: "..tostring(frame))

  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,1)
  assert((offset==0x00),"expected offset to be 0x00: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,9)
  assert((offset==0x02),"expected offset to be 0x02: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,24)
  assert((offset==0x06),"expected offset to be 0x06: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,126)
  assert((offset==0x20),"expected offset to be 0x20: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,251)
  assert((offset==0x40),"expected offset to be 0x40: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,376)
  assert((offset==0x60),"expected offset to be 0x60: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,501)
  assert((offset==0x80),"expected offset to be 0x80: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,997)
  assert((offset==0xFF),"expected offset to be 0xFF: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,1000)
  assert((offset==0x100),"expected offset to be 0x100: "..("%x"):format(offset))


  -- testing against "smaller than offsets"
  local fake_buffer = {
    has_sample_data = true,
    number_of_frames = 168,
  }

  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x00)
  assert((frame==1),"expected frame to be 1: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x01)
  assert((frame==2),"expected frame to be 2: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x02)
  assert((frame==2),"expected frame to be 2: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x03)
  assert((frame==3),"expected frame to be 3: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x10)
  assert((frame==12),"expected frame to be 12: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x20)
  assert((frame==22),"expected frame to be 22: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x30)
  assert((frame==33),"expected frame to be 33: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x40)
  assert((frame==43),"expected frame to be 43: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x50)
  assert((frame==54),"expected frame to be 54: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x60)
  assert((frame==64),"expected frame to be 64: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x70)
  assert((frame==75),"expected frame to be 75: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x80)
  assert((frame==85),"expected frame to be 85: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0xFE) -- 0xFF
  assert((frame==168),"expected frame to be 168: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0xFF)
  assert((frame==168),"expected frame to be 168: "..tostring(frame))

  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,1)
  assert((offset==0x00),"expected offset to be 0x00: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,2)
  assert((offset==0x01),"expected offset to be 0x01: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,3)
  assert((offset==0x03),"expected offset to be 0x03: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,12)
  assert((offset==0x10),"expected offset to be 0x10: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,22)
  assert((offset==0x20),"expected offset to be 0x20: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,33)
  assert((offset==0x30),"expected offset to be 0x30: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,43)
  assert((offset==0x40),"expected offset to be 0x40: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,54)
  assert((offset==0x50),"expected offset to be 0x50: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,64)
  assert((offset==0x60),"expected offset to be 0x60: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,75)
  assert((offset==0x70),"expected offset to be 0x70: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,85)
  assert((offset==0x80),"expected offset to be 0x80: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,168)
  assert((offset==0xFE),"expected offset to be 0xFE: "..("%x"):format(offset))

  -- testing against "smaller than offsets"
  local fake_buffer = {
    has_sample_data = true,
    number_of_frames = 202,
  }

  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x00)
  assert((frame==1),"expected frame to be 1: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x01)
  assert((frame==2),"expected frame to be 2: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x02)
  assert((frame==3),"expected frame to be 3: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x03) -- => 0x04
  assert((frame==3),"expected frame to be 3: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x10)
  assert((frame==14),"expected frame to be 14: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x20)
  assert((frame==26),"expected frame to be 26: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x30)
  assert((frame==39),"expected frame to be 39: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x40)
  assert((frame==52),"expected frame to be 52: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x50)
  assert((frame==64),"expected frame to be 64: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x60)
  assert((frame==77),"expected frame to be 77: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x70) -- => 0x6F
  assert((frame==89),"expected frame to be 89: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0x80)
  assert((frame==102),"expected frame to be 102: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0xFD)
  assert((frame==201),"expected frame to be 201: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0xFE) -- => 0xFD
  assert((frame==201),"expected frame to be 201: "..tostring(frame))
  local frame = xSampleBuffer.get_frame_by_offset(fake_buffer,0xFF)
  assert((frame==202),"expected frame to be 202: "..tostring(frame))

  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,1)
  assert((offset==0x00),"expected offset to be 0x00: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,2)
  assert((offset==0x01),"expected offset to be 0x01: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,4) 
  assert((offset==0x04),"expected offset to be 0x04: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,14)
  assert((offset==0x10),"expected offset to be 0x10: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,26)
  assert((offset==0x20),"expected offset to be 0x20: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,39)
  assert((offset==0x30),"expected offset to be 0x30: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,52)
  assert((offset==0x40),"expected offset to be 0x40: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,64)
  assert((offset==0x50),"expected offset to be 0x50: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,77)
  assert((offset==0x60),"expected offset to be 0x60: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,90)
  assert((offset==0x71),"expected offset to be 0x71: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,102)
  assert((offset==0x80),"expected offset to be 0x80: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,201)
  assert((offset==0xFD),"expected offset to be 0xFD: "..("%x"):format(offset))
  local offset = xSampleBuffer.get_offset_by_frame(fake_buffer,202)
  assert((offset==0xFF),"expected offset to be 0xFF: "..("%x"):format(offset))

  -------------------------------------------------------------------------------------------------
  -- bits_to_xbits

  local xbit = xSampleBuffer.bits_to_xbits(23)
  assert((xbit==24),"expected xbit to be 24: "..tostring(xbit))
  local xbit = xSampleBuffer.bits_to_xbits(12)
  assert((xbit==16),"expected xbit to be 16: "..tostring(xbit))
  local xbit = xSampleBuffer.bits_to_xbits(3)
  assert((xbit==8),"expected xbit to be 8: "..tostring(xbit))


  LOG(">>> xSampleBuffer: OK - passed all tests")


end
})
