local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local GainBias = require "Unit.ViewControl.GainBias"
local OutputScope = require "Unit.ViewControl.OutputScope"
local ply = app.SECTION_PLY

local AD = Class{}
AD:include(Unit)

function AD:init(args)
   args.title = "ad exp2"
   args.mnemonic = "Ax"
   Unit.init(self,args)
end

function AD:onLoadGraph(channelCount)
   local gate = self:createObject("Comparator","gate")
   gate:setGateMode()
   
   local adsr0 = self:createObject("ADSR","adsr0")
   local adsr = self:createObject("ADSR","adsr")
   local attack = self:createObject("GainBias","attack")
   local decay = self:createObject("GainBias","decay")
   local attackRange = self:createObject("MinMax","attackRange")
   local decayRange = self:createObject("MinMax","decayRange")
   local exp = self:createObject("Multiply","exp")
   local exp2 = self:createObject("Multiply","exp2")
   local out = self:createObject("Multiply","out")
   local out_gain = self:createObject("Constant","out_gain")
   
   connect(self,"In1",gate,"In")
   connect(adsr0,"Out",adsr,"Gate")
   connect(gate,"Out",adsr0,"Gate")
   
   adsr:hardSet("Sustain",1)

   connect(attack,"Out",adsr,"Attack")
   connect(decay,"Out",adsr,"Release")
   connect(attack,"Out",attackRange,"In")
   connect(decay,"Out",decayRange,"In")

   adsr0:hardSet("Attack",0)
   adsr0:hardSet("Sustain",1)
   connect(attack,"Out",adsr0,"Decay")
   connect(attack,"Out",adsr0,"Release")

   connect(adsr,"Out",exp,"Left")
   connect(adsr,"Out",exp,"Right")
   connect(exp,"Out",exp2,"Left")
   connect(exp,"Out",exp2,"Right")
   connect(exp2,"Out",out,"Left")
   
   out_gain:hardSet("Value",11.5)
   connect(out_gain,"Out",out,"Right")

   connect(out,"Out",self,"Out1")
   if channelCount==2 then
      connect(out,"Out",self,"Out2")
   end
   
   self:createMonoBranch("attack",attack,"In",attack,"Out")
   self:createMonoBranch("decay",decay,"In",decay,"Out")
end

local views = {
   expanded = {"attack","decay"},
   collapsed = {},
}

function AD:onLoadViews(objects,branches)
   local controls = {}

   local createMap = function (min, max, superCourse, course, fine, superFine, rounding)
      local map = app.LinearDialMap(min, max)
      map:setSteps(superCourse, course, fine, superFine)
      map:setRounding(rounding)
      return map
   end
   
   local time_map = createMap(.002, 2, 0.1, 0.01, 0.001, 0.001, 0.001)

   controls.attack = GainBias {
      button = "A",
      branch = branches.attack,
      description = "Attack",
      gainbias = objects.attack,
      range = objects.attackRange,
      biasMap = time_map,
      biasUnits = app.unitSecs,
      initialBias = 0.002
   }
   
   controls.decay = GainBias {
      button = "D",
      branch = branches.decay,
      description = "Decay",
      gainbias = objects.decay,
      range = objects.decayRange,
      biasMap = time_map,
      biasUnits = app.unitSecs,
      initialBias = 0.050
   }
   
   return controls, views
end

return AD
