local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local GainBias = require "Unit.ViewControl.GainBias"
local Gate = require "Unit.ViewControl.Gate"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local gate = Class{}
gate:include(Unit)

function gate:init(args)
   args.title = "Gate Soft"
   args.mnemonic = "gts"
   Unit.init(self,args)
end

function gate:onLoadGraph(channelCount)
   local vca1 = self:createObject("Multiply","vca1")
   local trig = self:createObject("Comparator","trig")
   trig:setGateMode()
   local slew = self:createObject("SlewLimiter","slew")
   local slew_time = self:createObject("Constant","slew_time")
   slew_time:hardSet("Value",.0001)
   slew:optionSet("Direction",app.SlewChoices.both)
   connect(slew_time,"Out",slew,"Time")
   
   
   connect(self,"In1",vca1,"Left")
   connect(vca1,"Out",self,"Out1")
   connect(trig,"Out",slew,"In")
   connect(slew,"Out",vca1,"Right")

   if channelCount==2 then
      local vca2 = self:createObject("Multiply","vca2")
      connect(self,"In2",vca2,"Left")
      connect(vca2,"Out",self,"Out2")
      connect(slew,"Out",vca2,"Right")
   end
   
   self:createMonoBranch("trig",trig,"In",trig,"Out")
end

function gate:onLoadViews(objects,branches)
   local views = {
      expanded = {"trig"},
      collapsed = {},
   }
   
   local controls = {}
   
   controls.trig = Gate {
      button = "open",
      branch = branches.trig,
      description = "Unit Trigger",
      comparator = objects.trig,
   }
   
   return controls, views
end

return gate
