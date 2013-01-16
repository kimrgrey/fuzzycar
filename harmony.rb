#!/usr/bin/env ruby

require 'benchmark'


class HarmonySearch
  PARAMS = [:bw, :nvar, :hmcr, :hms, :par, :iteration_count, :low_bound, :high_bound]
  PARAMS.each{|param| class_eval { attr_accessor param }}
  
  def print_state
    PARAMS.each {|param| puts "#{param.to_s} => #{self.send param}"}
  end

  def best_harmony
    self.before_start
    (0...iterantion_count).each do
      (0...self.nvar).each do |i|
        if (self.generate_random < self.hmcr)
          self.nchv[i] = hm[self.r]
          pitch_adjusment(i) if self.generate_random < self.par
        else
          random_selection(i)
        end
      end
    end
  end
end

class SlowdownAlgorithm
  attr_accessor :slowdown_rules
  attr_accessor :optimization_strategy
end


hs = HarmonySearch.new.tap do |hs|
  hs.bw = 0.2
  hs.nvar = 9
  hs.hmcr = 0.9
  hs.hms = 5
  hs.par = 0.4
  hs.iteration_count = 10000
  hs.low_bound = (0...hs.nvar).map{0.0}
  hs.high_bound = (0...hs.nvar).map{1.0}
end

hs.best_harmony 
