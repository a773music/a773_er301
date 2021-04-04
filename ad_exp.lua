local libcore = require "core.libcore"
local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local GainBias = require "Unit.ViewControl.GainBias"
local ply = app.SECTION_PLY

local AD_EXP = Class{}
AD_EXP:include(Unit)

function AD_EXP:init(args)
   args.title = "ad exp"
   args.mnemonic = "Ad"
   Unit.init(self,args)
end

function AD_EXP:onLoadGraph(channelCount)
   local trig = self:addObject("Comparator","trig")
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

   local decay_mod = self:addObject("decay_mod", app.Multiply())
   local level_mult = self:addObject("level_mult", app.Multiply())
   local level_sum = self:addObject("level_sum", app.Sum())
   local level_mult_value = self:addObject("level_mult_value", app.Constant())
   local level_sum_value = self:addObject("level_sum_value", app.Constant())
   --level_mult:hardSet("Left", 1)
   connect(level_mult_value, "Out", level_mult, "Left")
   connect(adsr, "Out", level_mult, "Right")
   connect(level_sum_value, "Out", level_sum, "Left")
   connect(level_mult, "Out", level_sum, "Right")
   level_mult_value:hardSet("Value",-2)
   level_sum_value:hardSet("Value",2.1)
   connect(decay, "Out", decay_mod, "Left")
   connect(level_sum, "Out", decay_mod, "Right")
   
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
   --connect(decay,"Out",adsr,"Decay")
   --connect(decay,"Out",adsr,"Release")
   connect(decay_mod,"Out",adsr,"Decay")
   connect(decay_mod,"Out",adsr,"Release")
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

function AD_EXP:onLoadViews(objects,branches)
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

return AD_EXP
