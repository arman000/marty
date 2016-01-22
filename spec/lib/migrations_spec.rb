require "spec_helper"

module Marty
  describe "Migrations" do
    it "writes db views correctly" do
      tdir = File.dirname(__FILE__) + "/migrations/"
      Marty::Migrations.write_view(tdir, Marty::Posting, {}, ["comment"])
      genfile = File.join(tdir,"Marty::Posting.sql")
      generated = File.read(genfile)
      expected = File.read(File.join(tdir,"Marty::Posting.sql.expected"))
      expect(generated).to eq(expected)
      File.delete(genfile)
    end
  end
end
