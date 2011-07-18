#a sorted Heap for the delayed scheduler
module Expo
class Heap
   
  def initialize(&comparator)
     @heap = [nil]
     @comparator = comparator || lambda { |x,y| x <=> y }
  end

  def clear()
    @heap = [nil]
  end

  def shift()
    case size
      when 0
        nil
      when 1
        @heap.pop
      else
        extracted = @heap[1]
        @heap[1] = @heap.pop
        shift_down
        extracted
    end
  end

  def first()
    case size
      when 0
        nil
      else
        @heap[1]
    end
  end

  def insert( element )
    @heap << element
    shift_up
  end
   
  def size()
    @heap.size - 1
  end

  private

  def shift_down()
    i = 1
    loop do
      c = 2 * i
      break if c >= @heap.size
      c += 1 if c + 1 < @heap.size and @comparator[@heap[c + 1], @heap[c]] < 0
      break if @comparator[@heap[i], @heap[c]] <= 0
      @heap[c], @heap[i] = @heap[i], @heap[c]
      i = c
    end
  end

  def shift_up()
    i = @heap.size - 1
    until i == 1
      p = i / 2
      break if @comparator[@heap[p], @heap[i]] <= 0
      @heap[p], @heap[i] = @heap[i], @heap[p]
      i = p
    end
  end

end
end
