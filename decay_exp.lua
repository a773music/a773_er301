local libcore = require "core.libcore"
local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local GainBias = require "Unit.ViewControl.GainBias"
local OutputScope = require "Unit.ViewControl.OutputScope"
local ply = app.SECTION_PLY

local Decay = Class{}
Decay:include(Unit)

function Decay:init(args)
   args.title = "decay exp"
   args.mnemonic = "Dx"
   Unit.init(self,args)
end

function Decay:onLoadGraph(channelCount)
   local gate = self:addObject("gate", app.Comparator())
   gate:setGateMode()
   
   local adsr = self:addObject("adsr", libcore.ADSR())
   local decay = self:addObject("decay", app.GainBias())
   local decayRange = self:addObject("decayRange", app.MinMax())
   local exp = self:addObject("exp", app.Multiply())
   
   connect(self,"In1",gate,"In")
   connect(gate,"Out",adsr,"Gate")

   connect(adsr,"Out",exp,"Left")
   connect(adsr,"Out",exp,"Right")
   
   adsr:hardSet("Sustain",1)
   adsr:hardSet("Attack",0)

   connect(decay,"Out",adsr,"Release")
   connect(decay,"Out",adsr,"Decay")
   connect(decay,"Out",decayRange,"In")

   connect(exp,"Out",self,"Out1")
   if channelCount==2 then
      connect(exp,"Out",self,"Out2")
   end
   
   self:addMonoBranch("decay",decay,"In",decay,"Out")
end

local views = {
   expanded = {"input","decay"},
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
