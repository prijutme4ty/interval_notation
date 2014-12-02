require_relative 'error'

module IntervalNotation
  class OpenOpenInterval
    attr_reader :from, :to
    def initialize(from, to)
      raise Error, "Interval from #{from} to #{to} can't be created"  unless from < to
      @from = from
      @to = to
    end
    def length; to - from; end
    def to_s; "(#{from};#{to})"; end
    def inspect; to_s; end
    def include_from?; false; end
    def include_to?; false; end
    def include_position?(value); from < value && value < to; end
    def eql?(other); other.class.equal?(self.class) && from == other.from && to == other.to; end
    def ==(other); other.is_a?(OpenOpenInterval) && from == other.from && to == other.to; end
  end

  class OpenClosedInterval
    attr_reader :from, :to
    def initialize(from, to)
      raise Error, "Interval from #{from} to #{to} can't be created"  unless from < to
      raise Error, "Infinite boundary should be open" unless to.to_f.finite?
      @from = from
      @to = to
    end
    def length; to - from; end
    def to_s; "(#{from};#{to}]"; end
    def inspect; to_s; end
    def include_from?; false; end
    def include_to?; true; end
    def include_position?(value); from < value && value <= to; end
    def eql?(other); other.class.equal?(self.class) && from == other.from && to == other.to; end
    def ==(other); other.is_a?(OpenClosedInterval) && from == other.from && to == other.to; end
  end

  class ClosedOpenInterval
    attr_reader :from, :to
    def initialize(from, to)
      raise Error, "Interval from #{from} to #{to} can't be created"  unless from < to
      raise Error, "Infinite boundary should be open" unless from.to_f.finite?
      @from = from
      @to = to
    end
    def length; to - from; end
    def to_s; "[#{from};#{to})"; end
    def inspect; to_s; end
    def include_from?; true; end
    def include_to?; false; end
    def include_position?(value); from <= value && value < to; end
    def eql?(other); other.class.equal?(self.class) && from == other.from && to == other.to; end
    def ==(other); other.is_a?(ClosedOpenInterval) && from == other.from && to == other.to; end
  end

  class ClosedClosedInterval
    attr_reader :from, :to
    def initialize(from, to)
      raise Error, "Interval from #{from} to #{to} can't be created"  unless from < to
      raise Error, "Infinite boundary should be open" unless from.to_f.finite? && to.to_f.finite?
      @from = from
      @to = to
    end
    def length; to - from; end
    def to_s; "[#{from};#{to}]"; end
    def inspect; to_s; end
    def include_from?; true; end
    def include_to?; true; end
    def include_position?(value); from <= value && value <= to; end
    def eql?(other); other.class.equal?(self.class) && from == other.from && to == other.to; end
    def ==(other); other.is_a?(ClosedClosedInterval) && from == other.from && to == other.to; end
  end

  class Point
    attr_reader :value
    protected :value
    def initialize(value)
      raise Error, "Point can't represent an infinity"  unless value.to_f.finite?
      @value = value
    end
    def from; value; end
    def to; value; end
    def length; 0; end
    def to_s; "{#{@value}}"; end
    def inspect; to_s; end
    def include_from?; true; end
    def include_to?; true; end
    def include_position?(val); value == val; end
    def eql?(other); other.class.equal?(self.class) && value == other.value; end
    def ==(other); other.is_a?(Point) && value == other.value; end
  end

  def interval_by_boundary_inclusion(include_from, from, include_to, to)
    if include_from
      if include_to
        if from != to
          ClosedClosedInterval.new(from, to)
        else
          Point.new(from)
        end
      else
        ClosedOpenInterval.new(from, to)
      end
    else
      if include_to
        OpenClosedInterval.new(from, to)
      else
        OpenOpenInterval.new(from, to)
      end
    end
  end

  module_function :interval_by_boundary_inclusion
  private_constant :OpenOpenInterval, :OpenClosedInterval, :ClosedOpenInterval, :ClosedClosedInterval, :Point
end
