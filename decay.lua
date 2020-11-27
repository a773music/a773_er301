local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local GainBias = require "Unit.ViewControl.GainBias"
local OutputScope = require "Unit.ViewControl.OutputScope"
local ply = app.SECTION_PLY

local Decay = Class{}
Decay:include(Unit)

function Decay:init(args)
   args.title = "decay"
   args.mnemonic = "Dy"
   Unit.init(self,args)
end

function Decay:onLoadGraph(channelCount)
   local gate = self:createObject("Comparator","gate")
   gate:setGateMode()
   
   local adsr = self:createObject("ADSR","adsr")
   local decay = self:createObject("GainBias","decay")
   local decayRange = self:createObject("MinMax","decayRange")
   
   connect(self,"In1",gate,"In")
   connect(gate,"Out",adsr,"Gate")
   
   adsr:hardSet("Sustain",1)
   adsr:hardSet("Attack",0)

   connect(decay,"Out",adsr,"Release")
   connect(decay,"Out",adsr,"Decay")
   connect(decay,"Out",decayRange,"In")

   connect(adsr,"Out",self,"Out1")
   if channelCount==2 then
      connect(adsr,"Out",self,"Out2")
   end
   
   self:createMonoBranch("decay",decay,"In",decay,"Out")
end

local views = {
   expanded = {"decay"},
   collapsed = {},
}

function Decay:onLoadViews(objects,branches)
   local controls = {}

   local createMap = function (min, max, superCourse, course, fine, superFine, rounding)
      local map = app.LinearDialMap(min, max)
      map:setSteps(superCourse, course, fine, superFine)
      map:setRounding(rounding)
      return map
   end
   
   local time_map = createMap(0, 2, 0.1, 0.01, 0.001, 0.001, 0.001)
   
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

return Decay
