require "stdio"
require "spec2"
require "interpreter.cr"

Spec2.describe Ly do
  let(flags) { Hash(Symbol, Bool | Float64 | Time::Span).new false }
  before { flags[:start] = Time::Span.new(nanoseconds: 0) }

  it "can do loops" do
    expect(Stdio.capture do |io|
      described_class.execute "(2706)(410)[sfl%]pu", flags
      io.out.gets
    end.not_nil!.chomp).to match /.*82/
  end

  it "can check primality of numbers outside the range of 64-bit ints" do
    expect(Stdio.capture do |io|
      described_class.execute "(2147495989)4L[Gu;]p::2%f3%*![0u;]p5s[l*L[u;]pl6+s]1u", flags
      io.out.gets
    end.not_nil!.chomp).to match /.*1/
  end

  it "can break out of loops and correctly report failures to break" do
    expect(Stdio.capture do |io|
      described_class.execute "32[[$]]u", flags
      io.out.gets
    end.not_nil!.chomp).to match /.*3/
    raise_error(Ly::LyError, /.*\(1\)/) { described_class.execute "3[[$]]", flags }
  end
end
