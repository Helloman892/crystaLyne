require "interpreter"
require "option_parser"

flags = Hash(Symbol, Bool | Float64 | Time::Span).new false
flags[:start] = Time::Span.new(nanoseconds: 0)
benchmark = 1
input = uninitialized String

OptionParser.parse! do |parser|
  parser.banner = "Usage: ly_crystal filename [-d] [-s] [-ti] [-t=0.0] [-b=0]\nNOTE: `filename` may also be passed as a delimited string representing the program"
  parser.on("-d", "--debug", "Output additional debug information") { flags[:debug] = true }
  parser.on("-s", "--slow", "Go through the program step-by-step") { flags[:slow] = true }
  parser.on("-ti", "--timeit", "Display total execution time") { flags[:timeit] = true }

  parser.on("-t TIME", "--time=TIME", "Time to wait between each execution tick (default 0.0 seconds)") do |t|
    flags[:time] = t.to_f64
  rescue ArgumentError
    puts "#{t} is not convertable to Float64"
  end

  parser.on("-b N", "--benchmark=N", "Run the program N times and return the average execution time (default 1)") do |n|
    flags[:timeit] = true
    benchmark = n.to_i
  rescue ArgumentError
    puts "#{n} is not convertable to Int32"
  end

  parser.on("-h", "--help", "Shows this help") { puts parser }

  parser.invalid_option do |flag|
    STDERR.puts "Error: #{flag} is not a valid option"
    STDERR.puts parser
  end

  parser.unknown_args do |arr|
    arr.first?.try do |input|
      total = Array(Time::Span).new
      benchmark.times { total << Ly.execute((File.file?(input) ? File.read input : input), flags) }
      puts "\n"
      puts "Time to execute (seconds): #{total.sum.total_seconds / benchmark}" if flags[:timeit]
    end
    puts parser if !arr.first
  end
end
