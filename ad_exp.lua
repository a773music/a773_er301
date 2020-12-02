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
   local trig = self:createObject("Comparator","trig")
   trig:setTriggerMode()
   local pre_env = self:createObject("SkewedSineEnvelope","env")
   local adsr = self:createObject("ADSR","adsr")
   local attack = self:createObject("GainBias","attack")
   local decay = self:createObject("GainBias","decay")
   local attackRange = self:createObject("MinMax","attackRange")
   local decayRange = self:createObject("MinMax","decayRange")
   local pre_env_level = self:createObject("Constant","pre_env_level")
   local pre_env_dur_bias = self:createObject("Constant","pre_env_dur_bias")
   local pre_env_dur_sum = self:createObject("Sum","pre_env_dur_sum")
   local duration = self:createObject("ParameterAdapter","duration")

   local decay_mod = self:createObject("Multiply","decay_mod")
   local level_mult = self:createObject("Multiply","level_mult")
   local level_sum = self:createObject("Sum","level_sum")
   local level_mult_value = self:createObject("Constant","level_mult_value")
   local level_sum_value = self:createObject("Constant","level_sum_value")
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

   self:createMonoBranch("attack",attack,"In",attack,"Out")
   self:createMonoBranch("decay",decay,"In",decay,"Out")
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
