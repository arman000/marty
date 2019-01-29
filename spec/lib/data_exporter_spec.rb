require "spec_helper"

module Marty
groupings = <<EOF
name
g1
g2
g3
EOF

heads = <<EOF
name	condition_text
h1	foo
h2	bar
h3	baz
EOF

head_versions = <<EOF
head__name	version	result_text
h1	base	x=1
h1	600	x=2
h2	base	y=z
h3	base	z=4
EOF

grouping_head_versions = <<EOF
grouping__name	head_version__head	head_version__version
g1	h1	base
g1	h1	600
g2	h2	base
g3	h3	base
EOF

describe DataExporter do
  it "be able to import and export nested keys" do
    res = Marty::DataImporter.do_import_summary(Gemini::Grouping, groupings)
    expect(res).to eq({ create: 3 })
    Gemini::Grouping.count.should == 3

    res = Marty::DataImporter.do_import_summary(Gemini::Head, heads)
    expect(res).to eq({ create: 3 })
    Gemini::Head.count.should == 3

    res = Marty::DataImporter.do_import_summary(Gemini::HeadVersion, head_versions)
    expect(res).to eq({ create: 4 })
    Gemini::HeadVersion.count.should == 4

    res = Marty::DataImporter.do_import_summary(Gemini::GroupingHeadVersion, grouping_head_versions)
    expect(res).to eq({ create: 4 })
    Gemini::GroupingHeadVersion.count.should == 4

    res = Marty::DataExporter.do_export('infinity', Gemini::GroupingHeadVersion)

    expect(res).to eq [
      ["grouping", "head_version__head", "head_version__version"],
      ["g1", "h1", "base"],
      ["g1", "h1", "600"],
      ["g2", "h2", "base"],
      ["g3", "h3", "base"]
    ]

    csv = Marty::DataExporter.to_csv(res, col_sep: "\t")

    res = Marty::DataImporter.do_import_summary(Gemini::GroupingHeadVersion, csv)

    expect(res).to eq({ same: 4 })
  end
end
end
