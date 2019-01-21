require "stdio"
require "spec2"
require "interpreter.cr"

Spec2.describe Ly do
  it "can do loops" do
    (flags = Hash(Symbol, Bool | Float64 | Time::Span).new false)[:start] = Time::Span.new(nanoseconds: 0)
    expect(Stdio.capture do |io|
      described_class.execute "(2706)(410)[sfl%]pu", flags
      io.out.gets
    end.not_nil!.chomp).to eq "82"
  end

  it "can check primality of numbers outside the range of 64-bit ints" do
  end
end
