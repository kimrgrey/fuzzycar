#!/usr/bin/env ruby

MAX_DELTA = 600000.0 
RULES_COUNT = 9

class Car
  attr_accessor :weight
  attr_accessor :speed
  attr_accessor :distance
  attr_accessor :energy

  def initialize(weight, speed, distance, energy = nil)
    self.weight = weight
    self.speed = speed
    self.distance = distance
    self.energy = energy ? energy : (weight * speed ** 2.0 ) / 2.0
  end

  def crashed? 
    self.distance <= 0
  end

  def moving?
    self.distance > 0 && self.speed > 0
  end

  def apply(e)
    distance = self.distance - speed # no, it is not mistake, because speed is distance per time
    energy = self.energy - e
    speed = energy > 0.0 ? ((2.0 * energy) / self.weight) ** 0.5 : 0.0
    Car.new(self.weight, speed, distance, energy)
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
  attr_accessor :deltas
  attr_accessor :strategy

  def self.create(car, deltas)
    SlowdownAlgorithm.new.tap do |algorithm|
      algorithm.car = car
      algorithm.rules = [
        { :speed => Accessory.create(:speed, :low), :distance => Accessory.create(:distance, :small) },
        { :speed => Accessory.create(:speed, :low), :distance => Accessory.create(:distance, :average) },
        { :speed => Accessory.create(:speed, :low), :distance => Accessory.create(:distance, :large) },
        { :speed => Accessory.create(:speed, :average), :distance => Accessory.create(:distance, :small) },
        { :speed => Accessory.create(:speed, :average), :distance => Accessory.create(:distance, :average) },
        { :speed => Accessory.create(:speed, :average), :distance => Accessory.create(:distance, :large) },
        { :speed => Accessory.create(:speed, :high), :distance => Accessory.create(:distance, :small) },
        { :speed => Accessory.create(:speed, :high), :distance => Accessory.create(:distance, :average) },
        { :speed => Accessory.create(:speed, :high), :distance => Accessory.create(:distance, :large) }
      ]
      algorithm.deltas = deltas.map{|d| d * MAX_DELTA} if deltas
    end
  end

  def energy
    pw_sum = 0.0
    w_sum = 0.0
    rules.each_with_index do |rule, i|
      w = rule[:speed].value(car.speed) * rule[:distance].value(car.distance)
      w_sum += w
      pw_sum += w * deltas[i]
    end
    pw_sum / w_sum
  end

  def stop_the_car
    while self.car.moving?
      self.car = self.car.apply self.energy
    end
    self.car
  end
end

def calculate_fitness(car, individual)
  car = SlowdownAlgorithm.create(car, individual).stop_the_car
  car.crashed? ? 0.0001 : 1.0 / car.distance
end

def generate_start_population(car, population_size)
  population = (0...population_size).map do
    individual = (0...9).map{rand}
    { :individual => individual, :fitness => calculate_fitness(car, individual) } 
  end
  population
end

def crossover(population)
  population_sum = population.inject(0.0){|sum, p| sum += p[:fitness]}
  prev_sum = 0.0
  population.each do |p| 
    probability = prev_sum + p[:fitness] / population_sum
    prev_sum += probability
    p[:probability] = probability
  end
  alpha_mother = rand
  alpha_father = rand
  mother = population.find{|p| alpha_mother < p[:probability] }
  father = population.find{|p| alpha_father < p[:probability] }
  child = (0...9).map do |i|
    rand(10000) % 2 == 1 ? mother[:individual][i] : father[:individual][i]
  end
  child
end

def thinout(population)
  population
end

def generate_best_population(car, population_size = 100, iterations_count = 1000)
  population = generate_start_population(car, population_size)
  (0...iterations_count).each do |iteration_number|
     child = crossover(population)
     population << { :individual => child, :fitness => calculate_fitness(car, child) }
     population = thinout(population)
  end
  population = population.sort do |a, b| 
    d = a[:fitness] - b[:fitness] 
    if d > 0 
      1 
    elsif d < 0 
      -1 
    else 
      0 
    end
  end
  population.last[:individual]
end

car = Car.new(2000.0, 80.0, 990.0)
deltas = generate_best_population(car)
puts SlowdownAlgorithm.create(car, deltas).stop_the_car.inspect

#deltas = generate_best_deltas(car)


# this values of delta for rules was obtained experimentally
#deltas = [
#  0.9579651951789856, 0.28362135149708406, 0.175209947623089, 
#  0.9522131839125745, 0.9787151217460632, 0.2869786322116852,
#  0.18289752650522906, 0.8402485431520775, 0.1791947278657684 
#]

