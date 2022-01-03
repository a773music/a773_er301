local libcore = require "core.libcore"
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
   local trig = self:addObject("trig", app.Comparator())
   trig:setGateMode()
   --trig:setTriggerMode()
   local sync = self:addObject("sync", app.Comparator())
   sync:setTriggerMode()
   
   local osc = self:addObject("osc", libcore.SineOscillator())
   local base_freq = self:addObject("base_freq", app.Constant())
   
   local p_env = self:addObject("p_env", libcore.ADSR())
   local pitch_env_depth = self:addObject("pitch_env_depth", app.GainBias())
   local pitch_env_depth_range = self:addObject("pitch_env_depth_range", app.MinMax())
   
   local p_decay = self:addObject("p_decay", app.GainBias())
   local p_decay_range = self:addObject("p_decay_range", app.MinMax())
   local p_exp = self:addObject("p_exp", app.Multiply())
   local p_exp2 = self:addObject("p_exp2", app.Multiply())
   local a_exp = self:addObject("a_exp", app.Multiply())
   local a_exp2 = self:addObject("a_exp2", app.Multiply())
   local osc_env = self:addObject("osc_env", app.Multiply())
   local osc_gain = self:addObject("osc_gain", app.ConstantGain())
   
   local output = self:addObject("output", app.Sum())
   local fundamental = self:addObject("fundamental", app.Sum())
   local p_env_amplified = self:addObject("p_env_amplified", app.Multiply())
   
   local a_env = self:addObject("a_env", libcore.ADSR())
   local a_decay = self:addObject("a_decay", app.GainBias())
   local a_decay_range = self:addObject("a_decay_range", app.MinMax())
   
   local tune = self:addObject("tune", app.ConstantOffset())
   local tuneRange = self:addObject("tuneRange", app.MinMax())
   
   osc_gain:setClampInDecibels(-59.9)
   osc_gain:hardSet("Gain",1.0)
   
   local gain = self:addObject("gain", app.GainBias())
   
   local feedback = self:addObject("feedback", app.GainBias())
   local feedbackRange = self:addObject("feedbackRange", app.MinMax())
   
   local click = self:addObject("click", app.GainBias())
   local click_range = self:addObject("click_range", app.MinMax())
   
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
   connect(osc_env,"Out",osc_gain,"In")
   connect(osc_gain,"Out",output,"Right")

   connect(output,"Out",self,"Out1")
   if channelCount==2 then
      local output2 = self:addObject("output", app.Sum())
      connect(osc_gain, "Out", output2, "Right")
      connect(self,"In2",output2,"Left")
      connect(output2,"Out",self,"Out2")
   end
   self:addMonoBranch("trig",trig,"In",trig,"Out")
   self:addMonoBranch("tune",tune,"In",tune,"Out")
   self:addMonoBranch("p_decay",p_decay,"In",p_decay,"Out")
   self:addMonoBranch("a_decay",a_decay,"In",a_decay,"Out")
   self:addMonoBranch("pitch_env_depth",pitch_env_depth,"In",pitch_env_depth,"Out")
   self:addMonoBranch("click", click,"In",click,"Out")
   self:addMonoBranch("feedback",feedback,"In",feedback,"Out")
   
end

local views = {
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
   local fb_map = createMap(0, 1, .1, .01, .01, .01, .01)
   local gain_map = createMap(-60, 1, 10, 1, .1, .01, .01)
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
      biasMap = fb_map,
      initialBias = 0,
   }
   
  controls.gain = Fader {
    button = "gain",
    description = "Gain",
    param = objects.osc_gain:getParameter("Gain"),
    map = gain_map,
    units = app.unitDecibels
  }
   
   return controls, views
end

return BD1
