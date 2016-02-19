require "spec_helper"

module Marty
  describe "Migrations" do
    it "writes db views correctly" do
      tdir = File.dirname(__FILE__) + "/migrations/"
      Marty::Migrations.write_view(tdir,
                                   'vw_marty_postings',
                                   Marty::Posting, {}, ["comment"],
                                   [["marty_posting_types", "id",
                                     "post_type_id"]])
      filename = "vw_marty_postings.sql"
      genfile = File.join(tdir,filename)
      generated = File.read(genfile)
      expected = File.read(File.join(tdir,"#{filename}.expected"))
      expect(generated).to eq(expected)
      File.delete(genfile)
    end
  end
end
