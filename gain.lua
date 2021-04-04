local libcore = require "core.libcore"
local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local Fader = require "Unit.ViewControl.Fader"
local OptionControl = require "Unit.ViewControl.OptionControl"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local Gainer = Class{}
Gainer:include(Unit)

function Gainer:init(args)
   args.title = "gain"
   args.mnemonic = "GA"
   Unit.init(self,args)
end

function Gainer:onLoadGraph(channelCount)
   if channelCount==2 then
      self:loadStereoGraph()
   else
      self:loadMonoGraph()
   end
end

function Gainer:loadMonoGraph()
   local gain = self:addObject("gain", app.ConstantGain())

   gain:setClampInDecibels(-59.9)
   gain:hardSet("Gain",1.0)
   
   connect(self,"In1",gain,"In")
   connect(gain,"Out",self,"Out1")
end

function Gainer:loadStereoGraph()
   local gain1 = self:addObject("gain1", app.ConstantGain())
   local gain2 = self:addObject("gain2", app.ConstantGain())

   gain1:setClampInDecibels(-59.9)
   gain1:hardSet("Gain",1.0)
   gain2:setClampInDecibels(-59.9)
   gain2:hardSet("Gain",1.0)

   
   connect(self,"In1",gain1,"In")
   connect(gain1,"Out",self,"Out1")
   connect(self,"In2",gain2,"In")
   connect(gain2,"Out",self,"Out2")
   
   
   tie(gain2,"Gain",gain1,"Gain")
   self.objects.gain = gain1
   
end

local views = {
   expanded = {"gain"},
   collapsed = {},
}

function Gainer:onLoadViews(objects,branches)
   local controls = {}
   
   local createMap = function (min, max, superCourse, course, fine, superFine, rounding)
      local map = app.LinearDialMap(min, max)
      map:setSteps(superCourse, course, fine, superFine)
      map:setRounding(rounding)
      return map
   end
   
   local gain_map = createMap(-60, 40, 10, 1, .1, .01, .01)
   
   controls.gain = Fader {
      button = "gain",
      description = "Gain",
      param = objects.gain:getParameter("Gain"),
      map = gain_map,
      units = app.unitDecibels
   }
   
   if self.channelCount==1 then
      local outlet = objects.gain:getOutput("Out")
      controls.gain:setMonoMeterTarget(outlet)
   else
      local left = objects.gain1:getOutput("Out")
      local right = objects.gain2:getOutput("Out")
      controls.gain:setStereoMeterTarget(left,right)
   end
   
   return controls, views
end

return Gainer
