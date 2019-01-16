# Execution is guaranteed to be O(n + k) on the input program length where k := the total characters in called functions
require "big"

module Ly
  class LyStack < Array(BigInt | BigFloat)
    @@backup_cell = Array(BigInt | BigFloat).new 20
    @@implicit = true

    def self.implicit=(value)
      @@implicit = value
    end

    def initialize
      initialize 20
    end

    private def top
      last
    end

    def new_pop(*, implicit = @@implicit)
      pop do
        raise EmptyStackError.new "Cannot pop from an empty stack" unless implicit
        (input = gets) ? input.to_big_i { raise InputError.new } : 0
      end
    end

    # +, -, *, /, %
    {% for op in {:+, :-, :*, :/, :%} %}
      def {{op.id}}
        y, x = new_pop, new_pop
        {% if op == :/ %}
          begin
            result = y.to_big_f / x
          rescue DivisionByZeroError
            raise LyError.new "Division by zero (current stack: #{self})"
          end
        {% else %}
          result = y {{op.id}} x
        {% end %}
        push result
      end
    {% end %}

    # :
    def duplicate : Nil
      push last
    end

    def p : Nil
      new_pop implicit: false
    end

    def f : Nil
      swap -1, -2
    end

    def r : Nil
      reverse!
    end

    # !
    def negate : Nil
      push (new_pop == 0).to_unsafe
    end

    # N
    def uN : Nil
      push -new_pop
    end

    def y : Nil
      push size
    end

    def a : Nil
      sort!
    end

    def w : Nil
      sleep new_pop
    end

    def uW : Nil
      swap (new_pop implicit: false), new_pop implicit: false
    end

    # I
    def uI : Nil
      push fetch(new_pop implicit: false) { |idx| raise IndexError.new "#{idx} is larger than the stack" }
    end

    def ~ : Nil
      push (rindex(new_pop implicit: false) ? 1 : 0)
    end

    # o, u (o prints the UTF-8 character with the codepoint on the top of the stack)
    def o(input_stack) : Nil
      _output(input_stack) { |temp| puts temp.chr }
    end

    def u(input_stack) : Nil
      _output(input_stack) { |temp| puts temp }
    end

    private def _output(input_stack, &block)
      temp = new_pop implicit: false
      input_stack ? input_stack << temp : yield temp
    end

    def i(input_stack) : Nil
      input_stack || return push input_stack.new_pop implicit: false
      (input = gets) || raise InputError.new "Required input not provided"
      input.each_codepoint { |c| push c }
    end

    def n(input_stack) : Nil
      input_stack || return push input_stack.new_pop implicit: false
      (input = gets) || raise InputError.new "Required input not provided"
      push input.to_big_i
    rescue ArgumentError
      raise InputError.new "Invalid input provided (contains non-numeric characters)"
    end

    # ?
    def u? : Nil
      x, y = new_pop, new_pop
      push Random.new.rand y..x
    end

    # TODO TODO TODO TODO TODO
    # make sure implementation matches ly.py

    # G, L
    #
    # Note that G and L are seemingly swapped - this is due to evaluation order and a wish to avoid extra assignments
    {% for method, op in {"G": "<", "L": ">"} %}
      def u{{method.id}} : Nil
        push (new_pop {{op.id}} top).to_unsafe
      end
    {% end %}

    def u= : Nil
      push (new_pop(implicit: false) == top).to_unsafe
    end

    def c : Nil
      push new_pop.to_s.size
    end

    # S
    def uS : Nil
      new_pop.to_s.each_char { |chr| push chr.to_i }
    end

    # J
    def uJ : Nil
      sum = join.to_big_i
      clear << sum
    end

    # R
    def uR : Nil
      x, y = new_pop, new_pop
      @internal += y..x.to_a
    end

    # `
    def backtick : Nil
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
      temp = sum
      clear << temp
    end

    # &n
    def stack_n : Nil
      while input = gets
        push input.to_big_i
      end
    rescue ArgumentError
      raise InputError.new "Expected integer input"
    end

    # &o
    def stack_o : Nil
      puts (map &.chr).join
      clear
    end

    # &u
    def stack_u : Nil
      puts join " "
      clear
    end

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
      @@backup_cell = self.clone
    end
  end

  class LyStrip
    protected property current_stack : LyStack
    @strip = Array(LyStack).new 10, LyStack.new
    @strip_pointer = BigInt.new 0
    @functions = {} of Char => String

    def initialize(@input_stack)
      previous_def
      @current_stack = @strip[0]
    end

    def exec(input : String, input_stack : LyStack? = nil)
      reader = Char::Reader.new input
      reader.each do |char|
        begin
          if func = @functions[char]?
            exec_function func, current_stack
            next
          end
        rescue ex : LyError
          raise FunctionError.new "Error occurred in function #{char}, called at position #{reader.pos}:\n  #{ex.message}"
        end

        # TODO: macros
        case char
        when 'i' then current_stack.i input_stack
        when 'n' then current_stack.n input_stack
        when 'o' then current_stack.o input_stack
        when 'u' then current_stack.u input_stack
        when 'r' then current_stack.r
        when 'f' then current_stack.f
        when 'p' then current_stack.p
        when 'y' then current_stack.y
        when 'a' then current_stack.a
        when 'c' then current_stack.c
        when 's' then current_stack.s
        when 'l' then current_stack.l
        when '+' then current_stack.+
        when '-' then current_stack.-
        when '/' then current_stack./
        when '*' then current_stack.*
        when '~' then current_stack.~
        when 'N' then current_stack.uN
        when 'I' then current_stack.uI
        when 'S' then current_stack.uS
        when 'J' then current_stack.uJ
        when 'R' then current_stack.uR
        when '?' then current_stack.u?
        when '!' then current_stack.negate
        when ':' then current_stack.duplicate
        when '`' then current_stack.backtick
        when '&'
          case reader.next_char
          when '+' then current_stack.stack_plus
          when 'n' then current_stack.stack_n
          when 'o' then current_stack.stack_o
          when 'u' then current_stack.stack_u
          when 'p' then current_stack.stack_p
          when ':' then current_stack.stack_dup
          when 's' then current_stack.stack_s
          end
        when '0'..'9' then current_stack.push char.to_i64
        when '(' # multi-digit numbers
          current_pos = reader.pos
          push reader.take_while do |c|
            c != ')'
          rescue IndexError
            raise LyError.new "Unclosed ( at position #{current_pos}"
          end.join.to_big_i
        when '>'  then shift :right
        when '<'  then shift :left
        when '\'' then current_stack.push reader.next_char.ord
        when ';' then raise LyStop.new # catches the case where this is called in a loop
        when '"'
          current_pos = reader.pos
          reader.take_while do |c|
            current_stack.push c.ord
            c != '"'
          rescue IndexError
            raise LyError.new %(Unclosed " at position #{current_pos})
          end
        when '['
          if current_stack.empty? || strip.current_stack[-1] == 0
            until reader.next_char == ']'
              next
            end
          end
        when ']'
          unless current_stack.empty? || strip.current_stack[-1] == 0
            until reader.previous_char == '['
              next
            end
            reader.previous_char # puts pointer back before the loop
          end
        when '$'
          current_pos = reader.pos
          break_num = current_stack.new_pop implicit: false
          begin
            while break_num > 0
              until reader.next_char == ']'
                next
              end
            end
          rescue IndexError
            raise LyError.new "$ at position #{current_pos} breaks too many loops (#{break_num})"
          end
        else
          if reader.peek_next_char == '{'
            current_pos = reader.pos
            functions[char] = reader.take_while do |c|
              c != '}'
            rescue IndexError
              raise LyError.new "Unclosed { at position #{current_pos}"
            end.join
          else
            raise LyError.new "#{char} at position #{reader.pos} is undefined"
          end
        end
      end
      # implicit output
      current_stack.stack_u
    end

    def exec_function(input : String, outer : LyStack)
      LyStack.implicit = false
      exec input, outer
    rescue LyStop # each function is its own program
      LyStack.implicit = true
      # All other exceptions are fatal
    end

    private def shift(direction : Symbol)
      if direction == :right
        @strip_pointer += 1
        @strip << LyStack.new if @strip_pointer > @strip.size
      elsif direction == :left
        if @strip_pointer > 0
          @strip_pointer -= 1
        else
          @strip.unshift LyStack.new
        end
      end
      @current_stack = @strip[@strip_pointer]
    end
  end

  def execute(inp : String)
    LyStrip.exec(input)
  rescue LyStop
  rescue ex
    puts ex.message
  end

  class LyError < Exception
  end

  class EmptyStackError < LyError
  end

  class InputError < LyError
  end

  class BackupCellError < LyError
  end

  class FunctionError < LyError
  end

  class LyStop < LyError
  end
end
