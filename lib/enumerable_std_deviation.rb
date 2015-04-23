module Enumerable
  def sum
    self.inject(0){|accum, i| accum + (i.is_a?(Numeric) ? i : 0) }
  end

  def mean
    self.sum/self.length.to_f
  end

  def sample_variance
    m = self.mean
    sum = self.inject(0){|accum, i| accum +(i-m)**2 }
    sum/(self.length - 1).to_f
  end

  def standard_deviation
    return Math.sqrt(self.sample_variance)
  end

  def normalize
    max = self.max
    self.map { |val| val.to_f / max.to_f }
  end
end 
