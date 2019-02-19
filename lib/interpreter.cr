# Execution is guaranteed to be O(n + k) on the input program length where k := the total characters in called functions
require "big"

module Ly
  extend self

  class LyStack < Array(BigInt)
    class_getter backup_cell = Array(BigInt).new 20
    @@implicit = true

    def self.implicit=(value)
      @@implicit = value
    end

    def push(value : Int32)
      push BigInt.new value
    end

    def initialize(@debug : Bool = false)
      initialize 20
    end

    private def top
      last
    end

    def new_pop(*, implicit = @@implicit)
      pop do
        raise EmptyStackError.new "Cannot pop from an empty stack" unless implicit
        (input = gets) ? input.to_big_i : BigInt.new 0
      rescue ArgumentError
        raise InputError.new
      end
    end

    # +, -, *, /, %
    {% for op in {:+, :-, :*, :/, :%} %}
      def {{op.id}}
        x, y = new_pop, new_pop
        push y {{op.id}} x
      rescue DivisionByZeroError
        raise LyError.new "Division by zero (current stack: #{self})"
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

    def w : Nil
      sleep new_pop
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
      sleep new_pop.to_i
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
      _output(input_stack) { |temp| STDOUT << temp.to_s.to_i64.chr }
    end

    def u(input_stack, s = false) : Nil
      _output(input_stack) { |temp| STDOUT << temp; STDOUT << ' ' if s }
    end

    private def _output(input_stack, &block)
      STDOUT << "outputted: " if @debug
      temp = new_pop implicit: false
      input_stack ? input_stack << temp : yield temp
      STDOUT << '\n' if @debug
    end

    def i(input_stack) : Nil
      input_stack && return push input_stack.new_pop implicit: false
      (input = gets) || raise InputError.new "Required input not provided"
      input.each_codepoint { |c| push BigInt.new c }
    end

    def n(input_stack) : Nil
      input_stack && return push input_stack.new_pop implicit: false
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

    # G, L
    #
    # Note that G and L are seemingly swapped - this is due to evaluation order and a wish to avoid extra assignments
    {% for method, op in {"G": "<", "L": ">"} %}
      def u{{method.id}} : Nil
        push (new_pop {{op.id}} top).to_unsafe
      end
    {% end %}

    def equals : Nil
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
      concat y..x
    end

    # `
    def backtick : Nil
      push new_pop + 1
    end

    # ,
    def comma : Nil
      push new_pop - 1
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
    def stack_o(input_stack) : Nil
      r
      while size > 0
        o input_stack
      end
    end

    # &u
    def stack_u(input_stack) : Nil
      r
      while size > 0
        u input_stack, s: true
      end
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
    @strip_pointer = BigInt.new 0
    @functions = {} of Char => String
    @loop_start_positions = [] of Int32

    def initialize(@flags : Hash(Symbol, Bool | Float64 | Time::Span), @input_stack : LyStack? = nil)
      @strip = Array(LyStack).new 10, LyStack.new @flags[:debug].as Bool
      @current_stack = @strip[0]
    end

    def exec(input : String, input_stack : LyStack? = nil)
      reader = Char::Reader.new input
      reader.each do |char|
        gets if @flags[:slow]
        begin
          if func = @functions[char]?
            exec_function func, current_stack
            next
          end
        rescue ex : LyError
          raise FunctionError.new "Error occurred in function #{char}, called at position #{reader.pos}:\n  #{ex.message}"
        end

        debug char, input_stack, reader

        {% begin %}
          case char
          {% for io in ['i', 'n', 'o', 'u'] %}
            when {{io}}
              if @flags[:start]
                @flags[:start] = @flags[:start].as(Time::Span) + Time.measure { current_stack.{{io.id}} input_stack }
              else
                current_stack.{{io.id}} input_stack
              end
              STDOUT.flush
          {% end %}
          {% for c in ['r', 'f', 'p', 'y', 'a', 'c', 's', 'l', 'w', '+', '-', '/', '*', '%', '~'] %}
            when {{c}} then current_stack.{{c.id}}
          {% end %}
          {% for c in ['N', 'I', 'S', 'J', 'R', 'W', '?', 'G', 'L'] %}
            when {{c}} then current_stack.u{{c.id}}
          {% end %}
          when '=' then current_stack.equals
          when '!' then current_stack.negate
          when ':' then current_stack.duplicate
          when '`' then current_stack.backtick
          when ',' then current_stack.comma
          when '&'
            debug (char = reader.next_char), input_stack, reader
            case char
            when ':' then current_stack.stack_dup
            when '+' then current_stack.stack_plus
            when 'o' then current_stack.stack_o input_stack
            when 'u' then current_stack.stack_u input_stack
              {% for c in ['n', 'p', 's'] %}
                when {{c}} then current_stack.stack_{{c.id}}
              {% end %}
            end
          when '0'..'9' then current_stack.push char.to_i32
          when '(' # multi-digit numbers
            _pos = reader.pos
            begin
              reader.next_char
              current_stack.push (reader.take_while &.!= ')').join.to_big_i
            rescue ArgumentError | IndexError
              raise LyError.new "Unclosed ( at position #{_pos}"
            end
          when '>'  then shift :right
          when '<'  then shift :left
          when '\'' then current_stack.push reader.next_char.ord
          when ';'  then return
          when '"'
            _pos = reader.pos
            begin
              reader.next_char
              reader.take_while do |c|
                break if c == '"'
                current_stack.push c.ord
              end
            rescue IndexError
              raise LyError.new %(Unclosed " at position #{_pos})
            end
          when '['
            if current_stack.empty? || current_stack.last == 0
              _pos = reader.pos
              extra = 0
              c = uninitialized Char
              loop do
                case c = reader.next_char
                when '[' then extra += 1
                when ']'
                  break if extra == 0
                  extra -= 1
                end
              rescue IndexError
                raise LyError.new "Unclosed [ at position #{_pos}"
              end
              debug c, input_stack, reader
            else # i.e. start the loop
              @loop_start_positions.push reader.pos
            end
          when ']'
            _pos = reader.pos
            begin
              if current_stack.empty? || current_stack.last == 0
                @loop_start_positions.pop # i.e. end the loop
              else
                reader.pos = @loop_start_positions.last
              end
            rescue IndexError
              raise LyError.new "] at position #{_pos} has no corresponding ["
            end
          when '$'
            begin
              _loops = loops = current_stack.new_pop
              _pos = reader.pos
              until loops == 0
                c = reader.next_char
                case c
                when '['
                  loops += 1
                when ']'
                  loops -= 1
                end
              end
              _loops.times { @loop_start_positions.pop }
            rescue IndexError
              raise LyError.new "$ at position #{_pos} breaks too many loops (#{loops})"
            end
          when '{', '}'
            raise LyError.new "Function block at position #{reader.pos} has no name"
          else
            begin
              if reader.next_char == '{'
                _pos = reader.pos
                reader.pos += 1
                blocks = 1 # allows function definition within functions
                @functions[char] = reader.take_while do |c|
                  blocks += 1 if c == '{'
                  c != '}' || (blocks -= 1) > 0
                rescue IndexError
                  raise LyError.new "Unclosed { at position #{_pos}"
                end.join
              else
                raise IndexError.new
              end
            rescue IndexError
              raise LyError.new "#{char} at position #{reader.pos} is undefined"
            end
          end
        {% end %}
        sleep @flags[:time].as Float64 if @flags[:time]
      end
      puts "Implicit output: " if @flags[:debug]
      current_stack.stack_u nil
    end

    def debug(char, input, reader : Char::Reader)
      puts "#{char} | #{current_stack.map &.to_i} | #{LyStack.backup_cell.map &.to_i} | #{input ? "function" : "main"} | #{reader.pos} | #{@strip_pointer}" if @flags[:debug]
    end

    def exec_function(input : String, outer : LyStack)
      LyStack.implicit = false
      LyStrip.new(@flags).exec input, outer
      LyStack.implicit = true
    end

    private def shift(direction : Symbol)
      if direction == :right
        @strip_pointer += 1
        @strip << LyStack.new @flags[:debug].as Bool if @strip_pointer > @strip.size
      elsif direction == :left
        if @strip_pointer > 0
          @strip_pointer -= 1
        else
          @strip.unshift LyStack.new @flags[:debug].as Bool
        end
      end
      @current_stack = @strip[@strip_pointer]
    end
  end

  def execute(input, flags)
    # strips comments before starting timing
    input = input.gsub /(#[\w\h]+)|\v/m, ""
    flags[:start] = Time.monotonic
    LyStrip.new(flags).exec input
    Time.monotonic - flags[:start].as Time::Span
  rescue ex : LyError
    puts "#{ex.class.to_s.lchop "Ly::"}: #{ex.message}"
    Time.monotonic - flags[:start].as Time::Span
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
end
