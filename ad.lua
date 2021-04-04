local libcore = require "core.libcore"
local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local GainBias = require "Unit.ViewControl.GainBias"
local ply = app.SECTION_PLY

local AD = Class{}
AD:include(Unit)

function AD:init(args)
   args.title = "ad"
   args.mnemonic = "Ad"
   Unit.init(self,args)
end

function AD:onLoadGraph(channelCount)
   local trig = self:addObject("trig", app.Comparator())
   trig:setTriggerMode()
   local pre_env = self:addObject("env", libcore.SkewedSineEnvelope())
   local adsr = self:addObject("adsr", libcore.ADSR())
   local attack = self:addObject("attack", app.GainBias())
   local decay = self:addObject("decay", app.GainBias())
   local attackRange = self:addObject("attackRange", app.MinMax())
   local decayRange = self:addObject("decayRange", app.MinMax())
   local pre_env_level = self:addObject("pre_env_level", app.Constant())
   local pre_env_dur_bias = self:addObject("pre_env_dur_bias", app.Constant())
   local pre_env_dur_sum = self:addObject("pre_env_dur_sum", app.Sum())
   local duration = self:addObject("duration", app.ParameterAdapter())
   
   -- setup trigger route: in -> pre_env -> adsr
   connect(self,"In1",trig,"In")
   connect(trig,"Out",pre_env,"Trigger")
   connect(pre_env,"Out",adsr,"Gate") --needed to trigger pre_env
   
   -- setup pre_env
   pre_env_dur_bias:hardSet("Value",.02)
   connect(attack, "Out", pre_env_dur_sum, "Left")
   connect(pre_env_dur_bias, "Out", pre_env_dur_sum, "Right")
   pre_env:hardSet("Skew", -1)
   pre_env_level:hardSet("Value", 1)
   connect(pre_env_level, "Out", pre_env, "Level")
   -- connect to adapter
   tie(pre_env,"Duration",duration,"Out")
   connect(pre_env_dur_sum, "Out", duration, "In")
   duration:hardSet("Gain",1)

   -- setup adsr
   connect(attack,"Out",adsr,"Attack")
   connect(decay,"Out",adsr,"Decay")
   connect(decay,"Out",adsr,"Release")
   adsr:hardSet("Sustain",0)
   connect(attack,"Out",attackRange,"In")
   connect(decay,"Out",decayRange,"In")

   connect(adsr,"Out",self,"Out1")
   if channelCount==2 then
      connect(adsr,"Out",self,"Out2")
   end

   self:addMonoBranch("attack",attack,"In",attack,"Out")
   self:addMonoBranch("decay",decay,"In",decay,"Out")
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
      --initialBias = 0
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
