local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local Fader = require "Unit.ViewControl.Fader"
local GainBias = require "Unit.ViewControl.GainBias"
local InputGate = require "Unit.ViewControl.InputGate"
local OutputScope = require "Unit.ViewControl.OutputScope"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local Decay = Class{}
Decay:include(Unit)

function Decay:init(args)
   args.title = "decay exp2"
   args.mnemonic = "Dx"
   Unit.init(self,args)
end

function Decay:onLoadGraph(channelCount)
   local gate = self:createObject("Comparator","gate")
   gate:setGateMode()
   
   local adsr = self:createObject("ADSR","adsr")
   local decay = self:createObject("GainBias","decay")
   local decayRange = self:createObject("MinMax","decayRange")
   local exp = self:createObject("Multiply","exp")
   local exp2 = self:createObject("Multiply","exp2")
   
   connect(self,"In1",gate,"In")
   connect(gate,"Out",adsr,"Gate")

   connect(adsr,"Out",exp,"Left")
   connect(adsr,"Out",exp,"Right")

   connect(exp,"Out",exp2,"Left")
   connect(exp,"Out",exp2,"Right")
   
   adsr:hardSet("Sustain",1)
   adsr:hardSet("Attack",0)

   connect(decay,"Out",adsr,"Release")
   connect(decay,"Out",adsr,"Decay")
   connect(decay,"Out",decayRange,"In")

   connect(exp2,"Out",self,"Out1")
   if channelCount==2 then
      connect(exp2,"Out",self,"Out2")
   end
   
   self:createMonoBranch("decay",decay,"In",decay,"Out")
end

local views = {
   expanded = {"input","decay"},
   collapsed = {},
   input = {"scope","input"},
   decay = {"scope","decay"},
}

function Decay:onLoadViews(objects,branches)
   local controls = {}

   local createMap = function (min, max, superCourse, course, fine, superFine, rounding)
      local map = app.LinearDialMap(min, max)
      map:setSteps(superCourse, course, fine, superFine)
      map:setRounding(rounding)
      return map
   end
   
   local time_map = createMap(.001, 2, 0.1, 0.01, 0.001, 0.001, 0.001)
   
   controls.scope = OutputScope {
      monitor = self,
      width = 4*ply,
   }
   
   controls.input = InputGate {
      button = "input",
      description = "Unit Input",
      comparator = objects.gate,
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

return Decay
