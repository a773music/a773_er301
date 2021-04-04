local libcore = require "core.libcore"
local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local ply = app.SECTION_PLY

local parabolic = Class{}
parabolic:include(Unit)

function parabolic:init(args)
   args.title = "parabolic"
   args.mnemonic = "Pa"
   Unit.init(self,args)
end

function parabolic:onLoadGraph(channelCount)
   local exp = self:addObject("exp", app.Multiply())
   
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

function parabolic:onLoadViews(objects,branches)
   local controls = {}

   return controls, views
end

return parabolic
