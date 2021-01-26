local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local Fader = require "Unit.ViewControl.Fader"
local GainBias = require "Unit.ViewControl.GainBias"
local Gate = require "Unit.ViewControl.Gate"
local OutputScope = require "Unit.ViewControl.OutputScope"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY
local Pitch = require "Unit.ViewControl.Pitch"
local BranchMeter = require "Unit.ViewControl.BranchMeter"

local BD1 = Class{}
BD1:include(Unit)

function BD1:init(args)
   args.title = "bd1"
   args.mnemonic = "Dx"
   Unit.init(self,args)
end

function BD1:onLoadGraph(channelCount)
   local trig = self:createObject("Comparator","trig")
   trig:setGateMode()
   --trig:setTriggerMode()
   local sync = self:createObject("Comparator","sync")
   sync:setTriggerMode()

   local osc = self:createObject("SineOscillator","osc")
   local base_freq = self:createObject("Constant","base_freq")
   
   local p_env = self:createObject("ADSR","p_env")
   local pitch_env_depth = self:createObject("GainBias","pitch_env_depth")
   local pitch_env_depth_range = self:createObject("MinMax","pitch_env_depth_range")


   local p_decay = self:createObject("GainBias","p_decay")
   local p_decay_range = self:createObject("MinMax","p_decay_range")
   local p_exp = self:createObject("Multiply","p_exp")
   local p_exp2 = self:createObject("Multiply","p_exp2")
   local a_exp = self:createObject("Multiply","a_exp")
   local a_exp2 = self:createObject("Multiply","a_exp2")
   local osc_env = self:createObject("Multiply","osc_env")
   local osc_amp = self:createObject("Multiply","osc_amp")
   local output = self:createObject("Sum","output")
   local fundamental = self:createObject("Sum","fundamental")
   local p_env_amplified = self:createObject("Multiply","p_env_amplified")

   
   local a_env = self:createObject("ADSR","a_env")
   local a_decay = self:createObject("GainBias","a_decay")
   local a_decay_range = self:createObject("MinMax","a_decay_range")


   
   
   local tune = self:createObject("ConstantOffset","tune")
   local tuneRange = self:createObject("MinMax","tuneRange")
   
   --local gain = self:createObject("ConstantGain","gain")
   --gain:setClampInDecibels(-59.9)
   --gain:hardSet("Gain",1.0)
   
   --local outGain = self:createObject("ConstantGain","outGain")
   
   
   local gain = self:createObject("GainBias","gain")
   local gain_range = self:createObject("MinMax","gain_range")
   
   local feedback = self:createObject("GainBias","feedback")
   local feedbackRange = self:createObject("MinMax","feedbackRange")
   
   local click = self:createObject("GainBias","click")
   local click_range = self:createObject("MinMax","click_range")
   

   
   --outGain:hardSet("Gain",1.0)


  
   connect(self,"In1",output,"Left")
   connect(trig,"Out",p_env,"Gate")
   connect(trig,"Out",a_env,"Gate")
   -- no click, sync on trigger
   connect(trig,"Out",sync,"In")
   connect(sync,"Out",osc,"Sync")
   -- phase is click
   connect(click,"Out",osc,"Phase")

   -- make snappy
   connect(p_env,"Out",p_exp,"Left")
   connect(p_env,"Out",p_exp,"Right")
   connect(p_exp,"Out",p_exp2,"Left")
   connect(p_exp,"Out",p_exp2,"Right")
   connect(a_env,"Out",a_exp,"Left")
   connect(a_env,"Out",a_exp,"Right")
   connect(a_exp,"Out",a_exp2,"Left")
   connect(a_exp,"Out",a_exp2,"Right")
   
   p_env:hardSet("Sustain",1)
   p_env:hardSet("Attack",0)
   a_env:hardSet("Sustain",1)
   a_env:hardSet("Attack",0)

   connect(p_decay,"Out",p_env,"Release")
   connect(p_decay,"Out",p_env,"Decay")
   connect(p_decay,"Out",p_decay_range,"In")


   connect(a_decay,"Out",a_env,"Release")
   connect(a_decay,"Out",a_env,"Decay")
   connect(a_decay,"Out",a_decay_range,"In")

   connect(pitch_env_depth,"Out",pitch_env_depth_range,"In")
   connect(gain,"Out",gain_range,"In")
   connect(feedback,"Out",osc,"Feedback")
   connect(feedback,"Out",feedbackRange,"In")
   
   -- audio
   connect(pitch_env_depth, "Out", p_env_amplified, "Left")
   connect(p_env, "Out", p_env_amplified, "Right")

   base_freq:hardSet("Value",32.703 )
   connect(base_freq, "Out", fundamental, "Left")
   connect(p_env_amplified, "Out", fundamental, "Right")
   connect(fundamental, "Out", osc, "Fundamental")

   connect(tune,"Out",tuneRange,"In")
   connect(tune,"Out",osc,"V/Oct")

   
   -- output
   connect(osc, "Out", osc_env, "Right")
   connect(a_env, "Out", osc_env, "Left")
   connect(osc_env, "Out", osc_amp, "Left")


   --connect(outGain,"Out",osc_amp,"Right")
   connect(gain,"Out",osc_amp,"Right")
   connect(osc_amp, "Out", output, "Right")
  
  
   connect(output,"Out",self,"Out1")
   if channelCount==2 then
      local output2 = self:createObject("Sum","output")
      connect(osc_amp, "Out", output2, "Right")
      connect(self,"In2",output2,"Left")
      connect(output2,"Out",self,"Out2")
   end
   self:createMonoBranch("trig",trig,"In",trig,"Out")
   self:createMonoBranch("tune",tune,"In",tune,"Out")
   self:createMonoBranch("p_decay",p_decay,"In",p_decay,"Out")
   self:createMonoBranch("a_decay",a_decay,"In",a_decay,"Out")
   self:createMonoBranch("pitch_env_depth",pitch_env_depth,"In",pitch_env_depth,"Out")
   self:createMonoBranch("gain",gain,"In",gain,"Out")
   self:createMonoBranch("click", click,"In",click,"Out")
   --self:createMonoBranch("outGain", outGain, "In", outGain,"Out")
   self:createMonoBranch("feedback",feedback,"In",feedback,"Out")
   
end

local views = {
   --expanded = {"trig","tune","a_decay", "p_decay","pitch_env_depth","feedback","gain","outGain"},
   expanded = {"trig","click","tune","a_decay", "p_decay","pitch_env_depth","feedback","gain"},
   collapsed = {},
}

function BD1:onLoadViews(objects,branches)
   local controls = {}

   local createMap = function (min, max, superCourse, course, fine, superFine, rounding)
      local map = app.LinearDialMap(min, max)
      map:setSteps(superCourse, course, fine, superFine)
      map:setRounding(rounding)
      return map
   end
   
   local time_map = createMap(.001, 2, 0.1, 0.01, 0.001, 0.001, 0.001)
   local pitch_map = createMap(0, 1000, 100, 10, 1, 1, 1)
   local gain_map = createMap(0, 1, .1, .01, .01, .01, .01)
   local click_map = createMap(0, .25, .1, .01, .01, .01, .01)
   
   controls.scope = OutputScope {
      monitor = self,
      width = 4*ply,
   }
   
   controls.trig = Gate {
      button = "trigger",
      branch = branches.trig,
      description = "Unit Trigger",
      comparator = objects.trig,
   }

   controls.click = GainBias {
      button = "click",
      branch = branches.click,
      description = "click",
      gainbias = objects.click,
      biasMap = click_map,
      --biasMap = Encoder.getMap("[0,1]"),
      range = objects.click_range,
      initialBias = 0,
   }
   


   
   controls.tune = Pitch {
      button = "V/oct",
      branch = branches.tune,
      description = "V/oct",
      offset = objects.tune,
      range = objects.tuneRange,
   }
   
   controls.pitch_env_depth = GainBias {
      button = "p depth",
      branch = branches.pitch_env_depth,
      description = "Pitch envelope depth",
      gainbias = objects.pitch_env_depth,
      biasMap = pitch_map,
      range = objects.pitch_env_depth_range,
      initialBias = 200,
      
   }
   
   controls.p_decay = GainBias {
      button = "p decay",
      branch = branches.p_decay,
      description = "Pitch Decay",
      gainbias = objects.p_decay,
      range = objects.p_decay_range,
      biasMap = time_map,
      biasUnits = app.unitSecs,
      initialBias = 0.1,
   }
   
   controls.a_decay = GainBias {
      button = "decay",
      branch = branches.a_decay,
      description = "Amp Decay",
      gainbias = objects.a_decay,
      range = objects.a_decay_range,
      biasMap = time_map,
      biasUnits = app.unitSecs,
      initialBias = 0.6,
   }
   
   controls.feedback = GainBias {
      button = "fdbk",
      description = "Feedback",
      branch = branches.feedback,
      gainbias = objects.feedback,
      range = objects.feedbackRange,
      biasMap = gain_map,
      initialBias = 0,
   }
   
   
   
   controls.gain = GainBias {
      button = "gain",
      branch = branches.gain,
      description = "gain",
      gainbias = objects.gain,
      biasMap = gain_map,
      range = objects.gain_range,
      initialBias = 1,
   }
   
--[[
      controls.outGain = Fader {
      button = "gain",
      description = "Post-Gain",
      param = objects.outGain:getParameter("Gain"),
      monitor = self,
      map = Encoder.getMap("decibel36"),
      units = app.unitDecibels
      }

   controls.gain = BranchMeter {
      button = "gain",
      branch = branches.gain,
      faderParam = objects.gain:getParameter("Gain")
   }
   self:addToMuteGroup(controls.gain)
   --]]
   
   return controls, views
end

return BD1
