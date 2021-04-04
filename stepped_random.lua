local libcore = require "core.libcore"
local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local ply = app.SECTION_PLY

local stepped_random = Class{}
stepped_random:include(Unit)

function stepped_random:init(args)
   args.title = "stepped random"
   args.mnemonic = "sr"
   Unit.init(self,args)
end

function stepped_random:onLoadGraph(channelCount)
   local holdL = self:addObject("holdL", libcore.TrackAndHold())
   local comparator = self:addObject("comparator", app.Comparator())
   local noise = self:addObject("noise", libcore.WhiteNoise())

   comparator:setTriggerMode()

   connect(self,"In1",comparator,"In")

   connect(noise,"Out",holdL,"In")
   connect(comparator,"Out",holdL,"Track")
   connect(holdL,"Out",self,"Out1")

   self:addMonoBranch("trig",comparator,"In",comparator,"Out")
end

local views = {
   expanded = {},
   collapsed = {},
}

function stepped_random:onLoadViews(objects,branches)
   local controls = {}

   return controls, views
end

return stepped_random
