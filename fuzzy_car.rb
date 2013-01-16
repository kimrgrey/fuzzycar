#!/usr/bin/env ruby

MAX_DELTA = 600000.0

class Car
  attr_accessor :weight
  attr_accessor :speed
  attr_accessor :distance
  attr_accessor :energy

  def initialize(weight, speed, distance)
    self.weight = weight
    self.speed = speed
    self.distance = distance
    self.energy = (weight * speed ** 2.0 ) / 2.0
  end

  def moving?
    self.distance > 0 && self.speed > 0
  end

  def apply!(e)
    self.distance -= speed # no, it is not mistake, because speed is distance per time
    self.energy -= e
    self.speed = self.energy > 0.0 ? ((2.0 * self.energy) / self.weight) ** 0.5 : 0.0
  end
end

class Accessory
  def self.create(type, value)
    if type == :speed
      case value
        when :low then Accessory.new(0.0, 40.0, 0.0, 25.0, 0.0, 15.0)
        when :average then Accessory.new(25.0, 75.0, 40.0, 60.0, 15.0, 15.0)
        when :high then Accessory.new(60.0, 100.0, 75.0, 100.0, 15.0, 15.0)
      end
    else
      case value
        when :small then Accessory.new(0.0, 400.0, 0.0, 250.0, 0.0, 150.0)
        when :average then Accessory.new(250.0, 750.0, 400.0, 600.0, 150.0, 150.0) 
        when :large then Accessory.new(600.0, 1000.0, 750.0, 1000.0, 150.0, 150.0)
      end    
    end
  end

  def initialize(min, max, m_1, m_2, d_1, d_2)
    @min, @max, @m_1, @m_2, @d_1, @d_2 = min, max, m_1, m_2, d_1, d_2
  end

  def value(x)
    result = 0.0
    if x > @min && x < @max
      if @d_1 == 0.0
        result = [0.0, [1.0, (@m_2 + @d_2 - x) / @d_2].min].max
      else
        result = [0.0, [1.0, (x - @m_1 + @d_1) / @d_2, (@m_2 + @d_2 - x) / @d_2].min].max
      end
    end
    result
  end
end

class SlowdownAlgorithm
  attr_accessor :car
  attr_accessor :rules
  attr_accessor :strategy

  def energy
    pw_sum = 0.0
    w_sum = 0.0
    rules.each do |rule|
      w = rule[:speed].value(car.speed) * rule[:distance].value(car.distance)
      w_sum += w
      pw_sum += w * rule[:delta]
    end
    pw_sum / w_sum
  end

  def stop_the_car
    while self.car.moving?
      puts "#{car.inspect}"
      car.apply! self.energy
    end
    puts "#{car.inspect}"
  end
end

# value of delta for rules was obtained experimentally


algorithm = SlowdownAlgorithm.new.tap do |algorithm|
  algorithm.car = Car.new(2000.0, 80.0, 990.0)
  algorithm.rules = [
    {
      :speed => Accessory.create(:speed, :low), 
      :distance => Accessory.create(:distance, :small),
      :delta => 0.9579651951789856 * MAX_DELTA
    },
    {
      :speed => Accessory.create(:speed, :low), 
      :distance => Accessory.create(:distance, :average),
      :delta => 0.28362135149708406 * MAX_DELTA
    },
    {
      :speed => Accessory.create(:speed, :low), 
      :distance => Accessory.create(:distance, :large),
      :delta => 0.175209947623089 * MAX_DELTA
    },
    {
      :speed => Accessory.create(:speed, :average), 
      :distance => Accessory.create(:distance, :small),
      :delta => 0.9522131839125745 * MAX_DELTA
    },
    {
      :speed => Accessory.create(:speed, :average), 
      :distance => Accessory.create(:distance, :average),
      :delta => 0.9787151217460632 * MAX_DELTA
    },
    {
      :speed => Accessory.create(:speed, :average), 
      :distance => Accessory.create(:distance, :large),
      :delta => 0.2869786322116852 * MAX_DELTA
    },
    {
      :speed => Accessory.create(:speed, :high), 
      :distance => Accessory.create(:distance, :small),
      :delta => 0.18289752650522906 * MAX_DELTA
    },
    {
      :speed => Accessory.create(:speed, :high), 
      :distance => Accessory.create(:distance, :average),
      :delta => 0.8402485431520775 * MAX_DELTA
    },
    {
      :speed => Accessory.create(:speed, :high), 
      :distance => Accessory.create(:distance, :large),
      :delta => 0.1791947278657684 * MAX_DELTA
    },
  ]
end

algorithm.stop_the_car
