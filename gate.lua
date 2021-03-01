local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local Gate = require "Unit.ViewControl.Gate"
local ply = app.SECTION_PLY

local gate = Class{}
gate:include(Unit)

function gate:init(args)
   args.title = "Gate"
   args.mnemonic = "gt"
   Unit.init(self,args)
end

function gate:onLoadGraph(channelCount)
   local vca1 = self:createObject("Multiply","vca1")
   local trig = self:createObject("Comparator","trig")
   trig:setGateMode()
   
   connect(self,"In1",vca1,"Left")
   connect(vca1,"Out",self,"Out1")
   connect(trig,"Out",vca1,"Right")

   if channelCount==2 then
      local vca2 = self:createObject("Multiply","vca2")
      connect(self,"In2",vca2,"Left")
      connect(vca2,"Out",self,"Out2")
      connect(trig,"Out",vca2,"Right")
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
