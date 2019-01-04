class LyError < Exception
end

{% for err in {:EmptyStack, :Input, :BackupCell, :Function} %}
  class {{err.id}}Error < LyError
  end
{% end %}

class LyStack < Array(Int64)
  @@implicit = true
  @@backup_cell = Array(Int64).new 20

  def self.implicit=(value)
    @@implicit = value
  end

  def initialize
    initialize 20
  end

  private def top
    last
  end

  # :
  def duplicate : Nil
    push last
  end

  private def pop(count = 1)
    results = [] of Int64
    
    count.times do 
      results << previous_def do
        raise EmptyStackError.new "Cannot pop from an empty stack" unless @@implicit
        if input = gets
          input.split do |token|
            results << token.to_i64 { raise InputError.new "Invalid implicit input" }
          end
        else
          results << 0
        end
      end
    end
    results.size == 1 ? results.first : results
  end

  # +, -, *, /, %
  {% for op in {:+, :-, :*, :/, :%} %}
    def {{op.id}}
      y, x = pop, pop
      {% if op == :/ %}
        raise DivisionByZeroError.new if x == 0
        result = y / x.to_f
      {% else %}
        result = y {{op.id}} x
      {% end %}
      push result
    end
  {% end %}

  def p : Nil
    pop
  end

  def f : Nil
    swap -1, -2
  end

  def r : Nil
    reverse!
  end

  # !
  def negate : Nil
    push (pop == 0).to_unsafe
  end

  # N
  def uN
    0 - pop
  end

  def y : Nil
    push size
  end

  def a : Nil
    sort!
  end

  # I
  def uI : Nil
    push fetch(pop) { |idx| raise IndexError.new "#{idx} is larger than the stack" }
  end

  def ~ : Nil
    push(rindex(pop) ? 1 : 0)
  end

  def o : Nil
    puts pop.chr
  end

  def u : Nil
    puts pop
  end

  def i : Nil
    raise InputError.new "Required input not provided" unless input = gets
    self.concat input.each_codepoint.to_a
  end

  def n : Nil
    raise InputError.new "Required input not provided" unless input = gets
    push input.to_i64 { raise InputError.new "Invalid input provided" }
  end

  # ?
  def u? : Nil
    x, y = pop, pop
    push Random.new.rand y..x
  end

  # =, G, L
  # 
  # Note that G and L are seemingly swapped - this is due to evaluation order and a wish to avoid extra assignments
  {% for method, op in {"=": "==", "G": "<", "L": ">"} %}
    def u{{method.id}} : Nil
      push (pop {{op.id}} top).to_unsafe
    end
  {% end %}

  def c : Nil
    push pop.to_s.size
  end

  # S
  def uS : Nil
    pop.to_s.each_char { |chr| push chr.to_i }
  end

  # J
  def uJ : Nil
    sum = join.to_i64
    clear << sum
  end

  # R
  def uR : Nil
    x, y = pop, pop
    @internal += y..x.to_a
  end

  def ` : Nil
    self[-1] += 1
  end

  # ,
  def comma : Nil
    self[-1] -= 1
  end

  def s : Nil
    @@backup_cell.clear << top
  end

  def l : Nil
    concat @@backup_cell
  end

  # &+
  def stack_plus : Nil
    push sum
  end

  # &n
  def stack_n : Nil
    while input = gets
      push input.to_i64 { break }
    end
  end

  # &o, &u
  {% for op, sep in {"o": "", "u": " "} %}
    def stack_{{op.id}} : Nil
      puts join {{sep.id}}
    end
  {% end %}

  # &p
  def stack_p : Nil
    clear
  end

  # &:
  def stack_dup : Nil
    self.concat self
  end

  # &s
  def stack_s : Nil
    @@backup_cell.clear.concat @@backup_cell
  end
end
