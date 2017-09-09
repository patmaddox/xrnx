--[[ 

  Testcase for cNumber

--]]

_tests:insert({
name = "cTable",
fn = function()

  LOG(">>> cTable: starting unit-test...")

  require (_clibroot.."cTable")
  _trace_filters = {"^cTable*"}

  -------------------------------------------------------------------------------------------------
  -- test nearest value 

  local vals = {0,-10,10,12,42,1000}
  local test_nearest = function(test,expected)
    local rslt = cTable.nearest(vals,test)
    assert(rslt==expected,("test:%s,\texpected:%s,\tresult:%s"):format(test,expected,rslt))
  end
  test_nearest(0,0)
  test_nearest(8,10)
  test_nearest(10,10)
  test_nearest(11,10)
  test_nearest(13,12)
  test_nearest(33,42)
  test_nearest(100,42)
  test_nearest(10000,1000)
  test_nearest(-80,-10)


  LOG(">>> cTable: OK - passed all tests")

end
})

