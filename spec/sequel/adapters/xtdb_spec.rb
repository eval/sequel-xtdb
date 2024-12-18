# frozen_string_literal: true

RSpec.describe Sequel::XTDB::Dataset do
  let(:db) { Sequel.connect("mock://xtdb") }
  let(:t1) { Time.parse("2024-12-18T00:00:00+01:00") }
  let(:d1) { Date.parse("2024-12-18") }

  describe "#select_setting_sql" do
    def as_of_dataset(...)
      db.as_of(...)
    end

    def sut(...)
      as_of_dataset(...).select_setting_sql
    end

    it "is nil when no as_of options" do
      expect(sut).to be_nil
    end

    it "includes current time formatted correctly when provided" do
      expect(sut(current: t1)).to \
        include(/CURRENT_TIME TO TIMESTAMP '#{Regexp.escape t1.iso8601}'/)
    end

    it "includes valid and system time formatted correctly when provided" do
      expect(sut(valid: t1)).to \
        include(/DEFAULT VALID_TIME AS OF TIMESTAMP '#{Regexp.escape t1.iso8601}'/)

      expect(sut(system: t1)).to \
        include(/DEFAULT SYSTEM_TIME AS OF TIMESTAMP '#{Regexp.escape t1.iso8601}'/)
    end

    it "casts valid and system correctly when a date" do
      expect(sut(valid: d1)).to \
        include(/VALID_TIME AS OF DATE '#{Regexp.escape d1.iso8601}'/)

      expect(sut(system: d1)).to \
        include(/SYSTEM_TIME AS OF DATE '#{Regexp.escape d1.iso8601}'/)
    end
  end
end
