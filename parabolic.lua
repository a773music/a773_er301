local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
--local GainBias = require "Unit.ViewControl.GainBias"
--local OutputScope = require "Unit.ViewControl.OutputScope"
local ply = app.SECTION_PLY

local Decay = Class{}
Decay:include(Unit)

function Decay:init(args)
   args.title = "Parabolic"
   args.mnemonic = "Pa"
   Unit.init(self,args)
end

function Decay:onLoadGraph(channelCount)
   local exp = self:createObject("Multiply","exp")
   
   connect(self,"In1",exp,"Left")
   connect(self,"In1",exp,"Right")

   connect(exp,"Out",self,"Out1")
   if channelCount==2 then
      connect(exp,"Out",self,"Out2")
   end
end

local views = {
   expanded = {"input","decay"},
   expanded = {"decay"},
   collapsed = {},
}

function Decay:onLoadViews(objects,branches)
   local controls = {}

   return controls, views
end

return Decay
