require "../../spec_helper"
require "../../../../src/components/cache/page_answer"

# Equivalence spec for the hand-written Accept-Encoding refusal check that
# replaced a regular expression, so that the page cache links no PCRE2.
#
# The former pattern stays here, in the spec, and both must give the same
# answer on every input: an edge-case table plus seeded generated inputs.
private module FormerRefusesCoding
  PATTERN = /(^|;)q=0(\.0*)?$/

  def self.refuses_coding?(parameters : String) : Bool
    return false if parameters.empty?
    parameters.delete(' ').downcase.matches?(PATTERN)
  end
end

private def expect_same_answer(parameters : String) : Nil
  expected = FormerRefusesCoding.refuses_coding?(parameters)
  actual = Components::Cache::PageAnswer.refuses_coding?(parameters)
  fail "#{parameters.inspect}: former pattern #{expected}, hand-written check #{actual}" unless actual == expected
end

private EDGE_CASES = [
  "", " ", ";", ";;", "q=0", "Q=0", " q = 0 ", "q=0.", "q=0.000", "q=0.001", "q=0.0\n", "q=0\n", "q=0\n\n",
  "q=0.\n", "\nq=0", "q=0\r", "q=0\r\n", ";q=0", "a;q=0", "aq=0", "level=1;q=0", "q=0;level=1", "q=0;",
  "q=00", "q=0.0.0", "q=0..0", "q=1", "q=0.5", "q=1.0", "q=", "q", "=0", "q=0 ", "\tq=0", "q=0\t",
  "x\n;q=0", "；q=0", "q＝0", "q=\u{0660}", "ǫ=0", "Q=0.00\n", "İq=0", ";İ;q=0.0", "q=0.0\u{0301}",
  "q=0" + ".0", "q=0." + "0" * 100_000, "a" * 100_000 + ";q=0", ";" * 50_000, ";" * 50_000 + "q=0",
  String.new(Bytes[0x71, 0x3d, 0x30, 0xff]), String.new(Bytes[0xff, 0x3b, 0x71, 0x3d, 0x30]),
  String.new(Bytes[0x3b, 0x71, 0x3d, 0x30, 0x2e, 0xc3]),
]

# Characters the pattern cares about, plus neighbors that test the edges:
# case, spaces, newlines, other digits, a separator look-alike and a
# character whose lowercase form is longer than itself.
private GENERATED_ALPHABET = ['q', 'Q', '=', '0', '.', ';', ' ', '\n', '\r', '\t', '1', 'a', 'İ', '；']

describe Components::Cache::PageAnswer do
  describe ".refuses_coding?" do
    it "refuses a coding whose last parameter is a zero quality" do
      {"q=0", ";q=0", "level=1;q=0", " Q = 0.000 ", "q=0.", "q=0\n"}.each do |parameters|
        Components::Cache::PageAnswer.refuses_coding?(parameters).should be_true
      end
    end

    it "keeps a coding whose last parameter is not a zero quality" do
      {"", "q=1", "q=0.5", "q=0.001", "q=00", "q=0;level=1", "aq=0", "q=0\n\n", "q=0\r"}.each do |parameters|
        Components::Cache::PageAnswer.refuses_coding?(parameters).should be_false
      end
    end

    it "matches the former pattern on every edge case" do
      EDGE_CASES.each { |parameters| expect_same_answer(parameters) }
    end

    it "matches the former pattern on 200,000 seeded generated inputs" do
      random = Random.new(20_261_118)
      200_000.times do
        length = random.rand(0..12)
        parameters = String.build do |io|
          length.times { io << GENERATED_ALPHABET.sample(random) }
        end
        expect_same_answer(parameters)
      end
    end

    it "matches the former pattern on seeded mutations of refusing inputs" do
      random = Random.new(42)
      list_of_refusing_inputs = ["q=0", ";q=0", "gzip;q=0.0", "level=1; q = 0.000", "Q=0.\n"]
      20_000.times do
        characters = list_of_refusing_inputs.sample(random).chars
        random.rand(1..3).times do
          position = random.rand(0..characters.size)
          case random.rand(3)
          when 0 then characters.insert(position, GENERATED_ALPHABET.sample(random))
          when 1 then characters.delete_at(position) if position < characters.size
          else        characters[position] = GENERATED_ALPHABET.sample(random) if position < characters.size
          end
        end
        expect_same_answer(characters.join)
      end
    end
  end
end
