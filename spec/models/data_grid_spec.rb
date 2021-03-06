require 'benchmark/ips'

module Marty::DataGridSpec
  describe DataGrid do
    G1 = <<EOS
state\tstring\tv\t\t
ltv\tnumrange\tv\t\t
fico\tnumrange\th\t\t

\t\t>=600<700\t>=700<750\t>=750
CA\t<=80\t1.1\t2.2\t3.3\tExample comment
TX|HI\t>80<=105\t4.4\t5.5\t6.6
NM\t<=80\t1.2\t2.3\t3.4\tSecond comment
MA\t>80<=105\t4.5\t5.6\t
\t<=80\t11\t22\t33
EOS

    G2 = <<EOS
units\tinteger\tv\t\t
ltv\tnumrange\tv\t\t
cltv\tnumrange\th\t\t
fico\tnumrange\th\t\t

\t\t>=100<110\t>=110<120\t>=120
\t\t>=600<700\t>=700<750\t>=750
1|2\t<=80\t1.1\t2.2\t3.3
1|2\t>80<=105\t4.4\t5.5\t6.6
3|4\t<=80\t1.2\t2.3\t3.4
3|4\t>80<=105\t4.5\t5.6\t6.7
EOS

    G3 = File.open(File.expand_path('../srp_data.csv', __FILE__)).read

    G4 = <<EOS
lenient
hb_indicator\tboolean\tv
cltv\tnumrange\th

\t<=60\t>60<=70\t>70<=75\t>75<=80\t>80<=85\t>85<=90\t>90<=95\t>95<=97
true\t-0.750\t-0.750\t-0.750\t-1.500\t-1.500\t-1.500\t\t
EOS

    G5 = <<EOS
ltv\tnumrange\tv\t\t

<=115\t-0.375
>115<=135\t-0.750
EOS

    G6 = <<EOS
ltv\tnumrange\th

<=115\t>115<=135
-0.375\t-0.750
EOS

    G7 = <<EOS
string
hb_indicator\tboolean\tv
cltv\tnumrange\th

\t<=60\t>60<=70\t>70<=75\t>75<=80\t>80<=85\t>85<=90\t>90<=95\t>95<=97
true\tThis\tis\ta\ttest\tof\tstring type\t\t
EOS

    G8 = <<EOS
Marty::DataGrid
ltv\tnumrange\tv\t\t

<=115\tG1
>115<=135\tG2
>135<=140\tG3
EOS

    G9 = <<EOS
state\tstring\tv
ltv\tnumrange\tv

CA|TX\t>80\t123
\t>80\t456
EOS

    Ga = <<EOS
dg\tMarty::DataGrid\tv\t\t

G1|G2\t7
G3\t8
EOS

    Gb = <<EOS
property_state\tGemini::State\tv\t\t

CA|TX\t70
GA\t80
MN\t90
EOS

    Gc = <<EOS
Marty::DataGrid
property_state\tGemini::State\tv\t\t

CA|TX\tGb
EOS

    Gd = <<EOS
hb_indicator\tboolean\tv

true\t456
false\t123
EOS

    Ge = <<EOS
ltv\tnumrange\th

>110\t>120
1.1\t1.1
EOS

    Gf = <<EOS
lenient string
b\tboolean\tv
i\tinteger\tv
i4\tint4range\tv
n\tnumrange\tv

true\t1\t<10\t<10.0\tY
\t2\t\t\tM
false\t\t>10\t\tN
EOS

    Gg = <<EOS
lenient
i1\tinteger\tv
i2\tinteger\tv

\t1\t1
2\t1\t21
2\t\t20
EOS

    Gh = <<EOS
lenient
property_state\tstring\tv
county_name\tstring\tv

NY\t\t10
\tR\t8
EOS

    Gi = <<EOS
units\tinteger\tv\t\t
ltv\tfloat\tv\t\t
cltv\tfloat\th\t\t
fico\tnumrange\th\t\t

\t\t80.5\t90.5\t100.5
\t\t>=600<700\t>=700<750\t>=750
1|2\t80.5\t1.1\t2.2\t3.3
1|2\t90.5\t4.4\t5.5\t6.6
3|4\t100.5\t1.2\t2.3\t3.4
3|4\t105.5\t4.5\t5.6\t6.7
EOS

    Gj = <<EOS
lenient
client_id\tinteger\tv
property_state\tstring\tv

\tCA\t0.25
700127\tCA\t0.35
EOS

    Gk = <<EOS
fha_203k_option\tstring\tv\tfha_203k_option

Investor Services\t-0.625
Admin Services\t-1.0
Admin Services Plus\t-1.625
Investor Services Acadamy\t-0.5
EOS

    Gl = <<EOS
lenient
fha_203k_option2\tstring\tv\tfha_203k_option2

Investor Services\t-0.625\tcomment 1
NOT (Admin Premium Services|Admin Services|Admin Services Plus)\t-1.0\tcomment 2
Admin Services Plus\t-1.625\tcomment 3
Investor Services Acadamy\t-0.5\tcomment 4
EOS

    G1_with_nulls = <<EOS
strict_null_mode
state\tstring\tv\t\t
ltv\tnumrange\tv\t\t
fico\tnumrange\th\t\t

\t\t>=600<700\t>=700<750\t>=750
CA\t<=80\t1.1\t2.2\t3.3
TX|HI\t>80<=105\t4.4\t5.5\t6.6
NM\t<=80\t1.2\t2.3\t3.4
MA\t>80<=105\t4.5\t5.6\t
NULL\t<=80\t11\t22\t33
EOS

    G1_with_range_nulls = <<EOS
strict_null_mode
state\tstring\tv\t\t
ltv\tnumrange\tv\t\t
fico\tnumrange\th\t\t

\t\t>=600<700\t>=700<750\t>=750
CA\t<=80\t1.1\t2.2\t3.3
TX|HI\t>80<=105\t4.4\t5.5\t6.6
NM\t\t1.2\t2.3\t3.4
MA\t>80<=105\t4.5\t5.6\t
\tNULL\t11\t22\t33
EOS

    G1_with_bool_nulls = <<EOS
strict_null_mode
bool_state\tboolean\tv\t\t
ltv\tnumrange\tv\t\t
fico\tnumrange\th\t\t

\t\t>=600<700\t>=700<750\t>=750
f\t>80<=105\t4.5\t5.6\t
NULL\t<=80\t11\t22\t33
EOS

    G1_with_integer_nulls = <<EOS
strict_null_mode
int_state\tinteger\tv\t\t
ltv\tnumrange\tv\t\t
fico\tnumrange\th\t\t

\t\t>=600<700\t>=700<750\t>=750
1\t<=80\t1.1\t2.2\t3.3
2\t>80<=105\t4.4\t5.5\t6.6
3\t<=80\t1.2\t2.3\t3.4
4|5\t>80<=105\t4.5\t5.6\t
NULL\t<=80\t11\t22\t33
EOS

    before(:each) do
      # Mcfly.whodunnit = Marty::User.find_by_login('marty')
      marty_whodunnit
    end

    def lookup_grid_helper(pt, gridname, params, follow = false, distinct = true)
      dgh = Marty::DataGrid.lookup_h(pt, gridname)
      res = Marty::DataGrid.lookup_grid_distinct_entry_h(pt, params, dgh, nil, follow,
                                                         false, distinct)
      [res['result'], res['name']]
    end

    describe 'caching' do
      # FIXME: not implemented
      xit 'should cache correctly with future pt 1' do
       dg = dg_from_import('G4', G4.gsub("\n", "\t\n"))
       pt = 1.day.from_now
       params = { 'hb_indicator' => true, 'cltv' => 82 }
       res1 = Marty::DataGrid.lookup_grid_h(pt, 'G4', params, false)

       # FIXME: we shouldn't pass created_dt here, but that won't work until
       # we start using statement_timestamp() instead of now in mcfly, because
       # now returns transaction timestamp and it's always the same
       # in transactional tests in Rspec.

       dg.update_from_import('G4', G4.gsub('-1.5', '-2.5'), 1.minute.from_now)

       res2 = Marty::DataGrid.lookup_grid_h(pt, 'G4', params, false)

       Delorean::Cache.adapter.clear_all!

       res3 = Marty::DataGrid.lookup_grid_h(pt, 'G4', params, false)

       expect(res2).to eq(-2.5)
       expect(res2).to eq(res3)
      end

      # FIXME: not implemented
      xit 'should cache correctly with future pt 2' do
        dg = dg_from_import('G4', G4.gsub("\n", "\t\n"), 1.hour.ago)
        pt = JSON.parse(1.hour.from_now.to_json)
        params = { 'hb_indicator' => true, 'cltv' => 82 }
        res1 = Marty::DataGrid.lookup_grid_h(pt, 'G4', params, false)

        # FIXME: we shouldn't pass created_dt here, but that won't work until
        # we start using statement_timestamp() instead of now in mcfly, because
        # now returns transaction timestamp and it's always the same
        # in transactional tests in Rspec.
        dg.update_from_import('G4', G4.gsub('-1.5', '-2.5'), 1.minute.from_now)

        res2 = Marty::DataGrid.lookup_grid_h(pt, 'G4', params, false)

        Delorean::Cache.adapter.clear_all!

        res3 = Marty::DataGrid.lookup_grid_h(pt, 'G4', params, false)

        expect(res2).to eq(-2.5)
        expect(res2).to eq(res3)
      end

      it 'should cache correctly with past pt 1' do
       dg = dg_from_import('G4WithoutBug', G4.gsub("\n", "\t\n"), 3.hours.ago)
       dg = dg_from_import('G4WithBug', G4.gsub("\n", "\t\n"), 3.hours.ago)

       pt = 1.hour.ago
       params = { 'hb_indicator' => true, 'cltv' => 82 }
       Marty::DataGrid.lookup_h(pt, 'G4WithoutBug')
       Marty::DataGrid.lookup_h(pt, 'G4WithBug')

       dg.update_from_import('G4WithBug', G4.gsub('-1.5', '-2.5'))

       res_without_bug = Marty::DataGrid.lookup_grid_h(pt, 'G4WithoutBug', params, false)
       res_with_bug = Marty::DataGrid.lookup_grid_h(pt, 'G4WithBug', params, false)

       expect(res_without_bug).to eq(res_with_bug)
      end

      it 'should cache correctly with past pt 2' do
       dg = dg_from_import('G4WithBug', G4.gsub("\n", "\t\n"), 3.hours.ago)

       pt = 1.hour.ago

       params1 = { 'hb_indicator' => true, 'cltv' => 82 }

       res1 = Marty::DataGrid.lookup_grid_h(pt, 'G4WithBug', params1, false)

       dg.update_from_import('G4WithBug', G4.gsub('-1.5', '-2.5'))

       params2 = { 'hb_indicator' => true, 'cltv' => 83 }

       res2 = Marty::DataGrid.lookup_grid_h(pt, 'G4WithBug', params1, false)
       res3 = Marty::DataGrid.lookup_grid_h(pt, 'G4WithBug', params2, false)

       expect(res1).to eq(res2)
       expect(res2).to eq(res3)
      end
    end

    describe 'imports' do
      it 'should not allow imports with trailing blank columns' do
        expect do
          dg_from_import('G1', G1.gsub("\n", "\t\n"))
        end.to raise_error(RuntimeError)
      end

      it 'should not allow imports with last blank row' do
        expect do
          dg_from_import('Gh', Gh + "\t\t\n")
        end.to raise_error(RuntimeError)
      end

      it 'show not allow import NULL fields unless strict_null_mode is on' do
        expect do
          dg_from_import(
            'G1_with_nulls',
            G1_with_nulls.gsub("strict_null_mode\n", '')
          )
        end.to raise_error(
          /NULL is not supported in grids without strict_null_mode/
        )
      end

      it 'should import wildcards' do
        dg = dg_from_import('G1', G1)
        state_attr = dg.metadata.find { |key| key['attr'] == 'state' }
        expect(state_attr['keys'].last).to be nil
        expect(state_attr['wildcards'].last).to be true
        expect(state_attr['wildcards']).to eq [false, false, false, false, true]
      end

      it 'should import comments' do
        dg = dg_from_import('G1', G1)
        expect(dg.comments).to eq ['Example comment', nil, 'Second comment', nil, nil]
      end

      it 'allows to import NULL values in string fields' do
        dg = dg_from_import('G1_with_nulls', G1_with_nulls)
        state_attr = dg.metadata.find { |key| key['attr'] == 'state' }
        expect(state_attr['keys'].last).to be nil
        expect(state_attr['wildcards'].last).to be false

        # FIXME: do we actually need mixing nulls with values?
        dg = dg_from_import(
          'G1_with_nulls2',
          G1_with_nulls.sub('NULL', 'NY|NULL')
        )
        state_attr = dg.metadata.find { |key| key['attr'] == 'state' }
        expect(state_attr['keys'].last).to eq [nil, 'NY']
        expect(state_attr['wildcards'].last).to be false

        dg = dg_from_import(
          'G1_with_nulls3',
          G1_with_nulls.sub('NULL', 'NOT (NULL)')
        )

        state_attr = dg.metadata.find { |key| key['attr'] == 'state' }
        expect(state_attr['keys'].last).to be nil
        expect(state_attr['wildcards'].last).to be false
        expect(state_attr['nots'].last).to be true

        dg = dg_from_import(
          'G1_with_nulls4',
          G1_with_nulls.sub('NULL', 'NOT (NY|NULL)')
        )

        state_attr = dg.metadata.find { |key| key['attr'] == 'state' }
        expect(state_attr['keys'].last).to eq [nil, 'NY']
        expect(state_attr['wildcards'].last).to be false
        expect(state_attr['nots'].last).to be true
      end

      it 'allows to import NULL values in integer field' do
        dg = dg_from_import('G1_with_integer_nulls', G1_with_integer_nulls)
        state_attr = dg.metadata.find { |key| key['attr'] == 'int_state' }
        expect(state_attr['keys'].last).to be nil
        expect(state_attr['wildcards'].last).to be false

        dg = dg_from_import(
          'G1_with_integer_nulls2',
          G1_with_integer_nulls.sub('NULL', '6|NULL')
        )

        state_attr = dg.metadata.find { |key| key['attr'] == 'int_state' }
        expect(state_attr['keys'].last).to eq [nil, 6]
        expect(state_attr['nots'].last).to be false
        expect(state_attr['wildcards'].last).to be false

        dg = dg_from_import(
          'G1_with_integer_nulls3',
          G1_with_integer_nulls.sub('NULL', 'NOT (NULL)')
        )

        state_attr = dg.metadata.find { |key| key['attr'] == 'int_state' }
        expect(state_attr['keys'].last).to be nil
        expect(state_attr['nots'].last).to be true
        expect(state_attr['wildcards'].last).to be false

        dg = dg_from_import(
          'G1_with_integer_nulls4',
          G1_with_integer_nulls.sub('NULL', 'NOT (6|NULL)')
        )

        state_attr = dg.metadata.find { |key| key['attr'] == 'int_state' }
        expect(state_attr['keys'].last).to eq [nil, 6]
        expect(state_attr['nots'].last).to be true
        expect(state_attr['wildcards'].last).to be false
      end

      it 'allows to import NULL values in boolean field' do
        dg = dg_from_import('G1_with_bool_nulls', G1_with_bool_nulls)
        state_attr = dg.metadata.find { |key| key['attr'] == 'bool_state' }
        expect(state_attr['keys'].last).to be nil
        expect(state_attr['wildcards'].last).to be false

        dg = dg_from_import('G1_with_bool_nulls2', G1_with_bool_nulls.sub('NULL', 'NOT (NULL)'))
        state_attr = dg.metadata.find { |key| key['attr'] == 'bool_state' }
        expect(state_attr['keys'].last).to be nil
        expect(state_attr['nots'].last).to be true
      end

      it 'allows to import NULL values in range field' do
        dg = dg_from_import('G1_with_range_nulls', G1_with_range_nulls)
        ltv_attr = dg.metadata.find { |key| key['attr'] == 'ltv' }
        expect(ltv_attr['keys'].last).to be nil
        expect(ltv_attr['wildcards'].last).to be false
        expect(ltv_attr['nots'].last).to be false

        dg = dg_from_import('G1_with_range_nulls2', G1_with_range_nulls.sub('NULL', 'NOT (NULL)'))
        ltv_attr = dg.metadata.find { |key| key['attr'] == 'ltv' }
        expect(ltv_attr['keys'].last).to be nil
        expect(ltv_attr['wildcards'].last).to be false
        expect(ltv_attr['nots'].last).to be true
      end

      it 'allows to import wildcard values in range field' do
        dg = dg_from_import('G1_with_range_nulls', G1_with_range_nulls)
        ltv_attr = dg.metadata.find { |key| key['attr'] == 'ltv' }
        expect(ltv_attr['keys'][2]).to be nil
        expect(ltv_attr['wildcards'][2]).to be true
      end
    end

    describe 'validations' do
      it 'should not allow bad axis types' do
        expect do
          dg_from_import('Gi', Gi)
        end.to raise_error(/unknown metadata type float/)
        expect do
          dg_from_import('Gi', Gi.sub(/float/, 'abcdef'))
        end.to raise_error(/unknown metadata type abcdef/)
      end

      it 'should not allow dup attr names' do
        g_bad = G1.sub(/fico/, 'ltv')

        expect do
          dg_from_import('G2', g_bad)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'should not allow dup grid names' do
        dg_from_import('G1', G1)

        expect do
          dg_from_import('G1', G2)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'should not allow extra attr rows' do
        g_bad = "x\tnumrange\th\t\t\n" + G1

        expect do
          dg_from_import('G2', g_bad)
        end.to raise_error(RuntimeError)
      end

      it 'should not allow dup row/col key combos' do
        g_bad = G1 + G1.split("\n").last + "\n"
        expect do
          dg_from_import('G2', g_bad)
        end.to raise_error(ActiveRecord::RecordInvalid)

        g_bad = G2 + G2.split("\n").last + "\n"
        expect do
          dg_from_import('G2', g_bad)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'Unknown keys for typed grids should raise error' do
        g_bad = G8.sub(/G3/, 'XXXXX')

        expect do
          dg_from_import('G8', g_bad)
        end.to raise_error(RuntimeError)

        g_bad = G8.sub(/DataGrid/, 'Division')

        expect do
          dg_from_import('G8', g_bad)
        end.to raise_error(RuntimeError)
      end

      it 'Unknown keys for grid headers should raise error' do
        g_bad = Ga.sub(/G3/, 'XXXXX')

        expect do
          dg_from_import('Ga', g_bad)
        end.to raise_error(RuntimeError)

        g_bad = Ga.sub(/DataGrid/, 'Division')

        expect do
          dg_from_import('Ga', g_bad)
        end.to raise_error(RuntimeError)
      end

      it 'validates grid modifier' do
        bad = ': abc def'
        g_bad = Gk.sub(/fha_203k_option$/, bad)
        expect do
          dg_from_import('Gk', g_bad)
        end.to raise_error(/invalid grid modifier expression: #{bad}/)
        expect do
          dg_from_import('Gk', Gk)
        end.not_to raise_error
      end
    end

    describe 'lookups for infinity' do
      let(:pt) { 'infinity' }

      before(:each) do
        %w[G1 G2 G3 G4 G5 G6 G7 G8 Ga Gb
           Gc Gd Ge Gf Gg Gh Gj Gl G1_with_nulls G1_with_range_nulls].each do |g|
          dg_from_import(g, "Marty::DataGridSpec::#{g}".constantize)
        end
      end

      context 'should handle NULL key values' do
        let(:dgh) { 'Gf' }

        it 'true returns Y' do
          res = Marty::DataGrid.lookup_grid_h(pt, dgh, { 'b' => true }, false)
          expect(res).to eq('Y')
        end

        it '13 returns N' do
          res = Marty::DataGrid.lookup_grid_h(pt, dgh, { 'i' => 13 }, true)
          expect(res).to eq('N')
        end

        it '13 & numrange 0 returns nil' do
          res = Marty::DataGrid.lookup_grid_h(pt, dgh, { 'i' => 13, 'n' => 0 }, true)
          expect(res).to eq('N')
        end

        it '13 & int4range 15 returns N' do
          res = Marty::DataGrid.lookup_grid_h(pt, dgh, { 'i' => 13, 'i4' => 15 }, true)
          expect(res).to eq('N')
        end

        it '13 & int4range 1 returns nil' do
          res = Marty::DataGrid.lookup_grid_h(pt, dgh, { 'i' => 13, 'i4' => 1 }, true)
          expect(res).to be_nil
        end

        it 'false, 3, numrange 15 returns N' do
          res = Marty::DataGrid.
                  lookup_grid_h(pt, dgh, { 'b' => false, 'i' => 3, 'n' => 15 }, true)
          expect(res).to eq('N')
        end

        it '13, numrange 15 returns N' do
          res = Marty::DataGrid.lookup_grid_h(pt, dgh, { 'i' => 13, 'n' => 15 }, true)
          expect(res).to eq('N')
        end
      end

      it 'should cast types' do
        res = Marty::DataGrid.lookup_grid_h(pt, 'Gf', { 'i' => 13, 'n' => 15 }, true)
        expect(res).to eq('N')

        res = Marty::DataGrid.lookup_grid_h(pt, 'Gf', { 'i' => '13', 'n' => '15' }, true)
        expect(res).to eq('N')

        res = Marty::DataGrid.lookup_grid_h(pt, 'Gf', { 'b' => 'true', 'i4' => '6' }, false)
        expect(res).to eq('Y')

        res = Marty::DataGrid.lookup_grid_h(pt, 'Gg', { 'i1' => 2, 'i2' => 1 }, false)
        expect(res).to eq(1)

        dg_from_import('G9', G9)
        res = Marty::DataGrid.lookup_grid_h(pt, 'G9', { 'state' => 4, 'ltv' => 81 }, false)
        expect(res).to eq(456)
      end

      it 'should handle ambiguous lookups' do
        h1 = {
          'property_state' => 'NY',
          'county_name'    => 'R',
        }

        res = Marty::DataGrid.lookup_grid_h(pt, 'Gh', h1, false)
        expect(res).to eq(10)
      end

      it 'should handle ambiguous lookups (2)' do
        res = Marty::DataGrid.
                lookup_grid_h(pt, 'Gg', { 'i1' => 2, 'i2' => 1 }, false)
        expect(res).to eq(1)

        res = Marty::DataGrid.
                lookup_grid_h(pt, 'Gg', { 'i1' => 3, 'i2' => 1 }, false)
        expect(res).to eq(1)

        res = Marty::DataGrid.
                lookup_grid_h(pt, 'Gg', { 'i1' => 2, 'i2' => 3 }, false)
        expect(res).to eq(20)
      end

      it 'should handle non-distinct lookups' do
        res = Marty::DataGrid.lookup_grid_h(pt, 'Ge', { 'ltv' => 500 }, false)

        expect(res).to eq(1.1)

        expect do
          Marty::DataGrid.lookup_grid_h(pt, 'Ge', { 'ltv' => 500 }, true)
        end.to raise_error(RuntimeError)
      end

      it 'should handle non-distinct lookups (2)' do
        params = {
          'client_id' => 700127,
          'property_state' => 'CA',
        }
        res = Marty::DataGrid.lookup_grid_h(pt, 'Gj', params, false)

        # should return the upper left corner match
        expect(res).to eq(0.25)

        expect do
          Marty::DataGrid.lookup_grid_h(pt, 'Gj', params, true)
        end.to raise_error(RuntimeError)
      end

      it 'should handle boolean lookups' do
        res = [true, false].map do |hb_indicator|
          lookup_grid_helper('infinity',
                             'Gd',
                             'hb_indicator' => hb_indicator,
                            )
        end
        expect(res).to eq [[456.0, 'Gd'], [123.0, 'Gd']]
      end

      it 'should handle basic lookups' do
        res = lookup_grid_helper('infinity',
                                 'G3',
                                 'amount' => 160300,
                                 'state' => 'HI',
                                )
        expect(res).to eq [1.655, 'G3']

        [3, 4].each do |units|
          res = lookup_grid_helper('infinity',
                                   'G2',
                                   'fico' => 720,
                                   'units' => units,
                                   'ltv' => 100,
                                   'cltv' => 110.1,
                                  )
          expect(res).to eq [5.6, 'G2']
        end

        dg = Marty::DataGrid.find_by(obsoleted_dt: 'infinity', name: 'G1')

        h = {
          'fico' => 600,
          'state' => 'RI',
          'ltv' => 10,
        }

        res = lookup_grid_helper('infinity', 'G1', h)
        expect(res).to eq [11, 'G1']

        dg.update_from_import('G1', G1.sub(/11/, '111'), 1.second.from_now)

        res = lookup_grid_helper('infinity', 'G1', h)
        expect(res).to eq [111, 'G1']
      end

      it 'should result in error when there are multiple cell hits' do
        expect do
          lookup_grid_helper('infinity',
                             'G2',
                             'fico' => 720,
                             'ltv' => 100,
                             'cltv' => 110.1,
                            )
        end.to raise_error(RuntimeError, /matches > 1/)
      end

      it 'should return nil when matching data grid cell is nil' do
        res = lookup_grid_helper('infinity',
                                 'G1',
                                 'fico' => 800,
                                 'state' => 'MA',
                                 'ltv' => 81,
                                )
        expect(res).to eq [nil, 'G1']
      end

      it 'should handle string wildcards' do
        res = lookup_grid_helper('infinity',
                                 'G1',
                                 'fico' => 720,
                                 'state' => 'GU',
                                 'ltv' => 80,
                                )

        expect(res).to eq [22, 'G1']
      end

      it 'should not treat nil as missing attr' do
        expect do
          res = lookup_grid_helper('infinity',
                                   'G1',
                                   'fico' => 720,
                                   'state' => 'NM',
                                   'ltv' => 80,
                                  )
        end.to raise_error(RuntimeError, /matches > 1/)

        expect do
          res = lookup_grid_helper('infinity',
                                   'G1',
                                   'fico' => 720,
                                   'ltv' => 80,
                                  )
        end.to raise_error(RuntimeError, /matches > 1/)

        res = lookup_grid_helper('infinity',
                                 'G1',
                                 'fico' => 720,
                                 'state' => nil,
                                 'ltv' => 80,
                                )

        expect(res).to eq [22, 'G1']
      end

      it 'should handle string NULLS' do
        res = lookup_grid_helper('infinity',
                                 'G1_with_nulls',
                                 'fico' => 720,
                                 'state' => nil,
                                 'ltv' => 80,
                                )

        expect(res).to eq [22, 'G1_with_nulls']

        expect do
          lookup_grid_helper('infinity',
                             'G1_with_nulls',
                             'fico' => 720,
                             'state' => 'BLABLA',
                             'ltv' => 80,
                            )
        end.to raise_error(/Data Grid lookup failed/)

        dg = dg_from_import(
          'G1_with_nulls2',
          G1_with_nulls.sub('NULL', 'NY|NULL')
        )

        res = lookup_grid_helper('infinity',
                                 dg.name,
                                 'fico' => 720,
                                 'state' => nil,
                                 'ltv' => 80,
                                )

        expect(res).to eq [22, dg.name]

        res = lookup_grid_helper('infinity',
                                 dg.name,
                                 'fico' => 720,
                                 'state' => 'NY',
                                 'ltv' => 80,
                                )

        expect(res).to eq [22, dg.name]
      end

      it 'should handle nils passed to range fields' do
        res = lookup_grid_helper('infinity',
                                 'G4',
                                 'hb_indicator' => true,
                                 'cltv' => nil
                                )

        expect(res).to eq [nil, 'G4']
      end

      it 'should handle range NULLs' do
        res = lookup_grid_helper('infinity',
                                 'G1_with_range_nulls',
                                 'state' => nil,
                                 'ltv' => nil,
                                 'fico' => 650,
                                )

        expect(res).to eq [11.0, 'G1_with_range_nulls']

        res = lookup_grid_helper('infinity',
                                 'G1_with_range_nulls',
                                 'ltv' => nil,
                                 'fico' => 650,
                                )
        expect(res).to eq [11.0, 'G1_with_range_nulls']

        # Wildcards should still work in strict_null_mode
        expect do
          lookup_grid_helper(
            'infinity',
            'G1_with_range_nulls',
            'state' => 'NM',
            'fico' => 650,
          )
        end.to raise_error(RuntimeError, /matches > 1/)
      end

      it 'should handle matches which also have a wildcard match' do
        dg_from_import('G9', G9)

        expect do
          res = lookup_grid_helper('infinity',
                                   'G9',
                                   'state' => 'CA', 'ltv' => 81,
                                  )
        end.to raise_error(RuntimeError, /matches > 1/)

        res = lookup_grid_helper('infinity',
                                 'G9',
                                 'state' => 'GU', 'ltv' => 81,
                                )
        expect(res).to eq [456, 'G9']
      end

      # it 'should raise on nil attr values' do
      #   next
      #   dg_from_import('G9', G9)
      #
      #   expect do
      #     lookup_grid_helper('infinity',
      #                        'G9',
      #                        'ltv' => 81,
      #                       )
      #   end.to raise_error(/matches > 1/)
      #
      #   err = /Data Grid lookup failed/
      #   expect do
      #     lookup_grid_helper('infinity',
      #                        'G9',
      #                        { 'state' => 'CA', 'ltv' => nil },
      #                        false, false)
      #   end.to raise_error(err)
      #
      #   res = lookup_grid_helper('infinity',
      #                            'G9',
      #                            { 'state' => nil, 'ltv' => 81 },
      #                            false, false)
      #
      #   expect(res).to eq [456, 'G9']
      # end

      it 'should raise if nothing was found' do
        dg_from_import('G9', G9)

        expect do
          lookup_grid_helper('infinity',
                             'G9',
                             'ltv' => 80,
                            )
        end.to raise_error(/Data Grid lookup failed/)
      end

      it 'should handle boolean keys' do
        res = lookup_grid_helper('infinity',
                                 'G4',
                                 'hb_indicator' => true,
                                 'cltv' => 80,
                                )
        expect(res).to eq [-1.5, 'G4']

        res = lookup_grid_helper('infinity',
                                 'G4',
                                 'hb_indicator' => false,
                                 'cltv' => 80,
                                )
        expect(res).to eq [nil, 'G4']
      end

      it 'should handle vertical-only grids' do
        res = lookup_grid_helper('infinity',
                                 'G5',
                                 'ltv' => 80,
                                )
        expect(res).to eq [-0.375, 'G5']
      end

      it 'should handle horiz-only grids' do
        res = lookup_grid_helper('infinity',
                                 'G6',
                                 'ltv' => 80, 'conforming' => true,
                                )
        expect(res).to eq [-0.375, 'G6']
      end

      it 'should handle string typed data grids' do
        expect(Marty::DataGrid.lookup('infinity', 'G7')['data_type']).to eq 'string'

        res = lookup_grid_helper('infinity',
                                 'G7',
                                 'hb_indicator' => true,
                                 'cltv' => 80,
                                )
        expect(res).to eq ['test', 'G7']
      end

      it 'should handle DataGrid typed data grids' do
        expect(Marty::DataGrid.lookup('infinity', 'G8')['data_type']).
          to eq 'Marty::DataGrid'
        g1 = Marty::DataGrid.lookup('infinity', 'G1')

        res = lookup_grid_helper('infinity', 'G8', 'ltv' => 80)
        expect(res).to eq [g1, 'G8']
      end

      it 'should handle multi DataGrid lookups' do
        expect(Marty::DataGrid.lookup('infinity', 'G8')['data_type']).
          to eq 'Marty::DataGrid'

        h = {
          'fico' => 600,
          'state' => 'RI',
          'ltv' => 10,
        }

        g1_res = lookup_grid_helper('infinity', 'G1', h)
        expect(g1_res).to eq [11, 'G1']

        res = lookup_grid_helper('infinity', 'G8', h, true)

        expect(g1_res).to eq res

        # make sure lookup_grid_h works too
        res_h = Marty::DataGrid.lookup_grid_h('infinity', 'G8', h, true)

        expect(g1_res[0]).to eq res_h
      end

      it 'should handle DataGrid typed data grids' do
        g1 = Marty::DataGrid.find_by(obsoleted_dt: 'infinity', name: 'G1')

        res = lookup_grid_helper('infinity', 'Ga', 'dg' => g1)
        expect(res).to eq [7, 'Ga']

        # should be able to lookup bu name as well
        res = lookup_grid_helper('infinity', 'Ga', 'dg' => 'G2')

        expect(res).to eq [7, 'Ga']
      end

      it 'should handle DataGrid typed data grids -- non mcfly' do
        ca = Gemini::State.find_by(name: 'CA')

        res = lookup_grid_helper('infinity', 'Gb', 'property_state' => ca)
        expect(res).to eq [70, 'Gb']

        # should be able to lookup bu name as well
        res = lookup_grid_helper('infinity', 'Gb', 'property_state' => 'CA')
        expect(res).to eq [70, 'Gb']
      end

      it 'should handle typed (enum) data lookup_grid' do
        pt = 'infinity'
        ca = Gemini::State.find_by(name: 'CA')

        res = Marty::DataGrid.
                lookup_grid_h(pt, 'Gb', { 'property_state' => ca }, false)

        expect(res).to eq 70
      end

      it 'should return grid data and metadata simple' do
        expected_data = [[1.1, 2.2, 3.3], [4.4, 5.5, 6.6], [1.2, 2.3, 3.4],
                         [4.5, 5.6, 6.7]]
        expected_metadata = [{ 'dir' => 'v',
                               'attr' => 'units',
                               'keys' => [[1, 2], [1, 2], [3, 4], [3, 4]],
                               'nots' => [false, false, false, false],
                               'wildcards' => [false, false, false, false],
                               'type' => 'integer' },
                             { 'dir' => 'v',
                               'attr' => 'ltv',
                               'keys' => ['[,80]', '(80,105]', '[,80]', '(80,105]'],
                               'nots' => [false, false, false, false],
                               'wildcards' => [false, false, false, false],
                               'type' => 'numrange' },
                             { 'dir' => 'h',
                               'attr' => 'cltv',
                               'keys' => ['[100,110)', '[110,120)', '[120,]'],
                               'nots' => [false, false, false],
                               'wildcards' => [false, false, false],
                               'type' => 'numrange' },
                             { 'dir' => 'h',
                               'attr' => 'fico',
                               'keys' => ['[600,700)', '[700,750)', '[750,]'],
                               'nots' => [false, false, false],
                               'wildcards' => [false, false, false],
                               'type' => 'numrange' }]

        dgh = Marty::DataGrid.lookup_h(pt, 'G2')
        res = Marty::DataGrid.lookup_grid_distinct_entry_h(pt, {}, dgh,
                                                           nil, true, true)
        expect(res['data']).to eq expected_data
        expect(res['metadata']).to eq expected_metadata
      end

      it 'should return grid data and metadata multi (following)' do
        expected_data = [[1.1, 2.2, 3.3], [4.4, 5.5, 6.6], [1.2, 2.3, 3.4],
                         [4.5, 5.6, nil], [11.0, 22.0, 33.0]]
        expected_metadata = [{ 'dir' => 'v',
                               'attr' => 'state',
                               'keys' => [['CA'], ['HI', 'TX'], ['NM'], ['MA'], nil],
                               'nots' => [false, false, false, false, false],
                               'wildcards' => [false, false, false, false, true],
                               'type' => 'string' },
                             { 'dir' => 'v',
                               'attr' => 'ltv',
                               'keys' => ['[,80]', '(80,105]', '[,80]', '(80,105]',
                                          '[,80]'],
                                'nots' => [false, false, false, false, false],
                                'wildcards' => [false, false, false, false, false],
                               'type' => 'numrange' },
                             { 'dir' => 'h',
                               'attr' => 'fico',
                               'keys' => ['[600,700)', '[700,750)', '[750,]'],
                               'nots' => [false, false, false],
                               'wildcards' => [false, false, false],
                               'type' => 'numrange' }]
        dgh = Marty::DataGrid.lookup_h(pt, 'G8')
        res = Marty::DataGrid.lookup_grid_distinct_entry_h(pt,
                                                           { 'ltv' => 10,
                                                             'state' => 'RI' },
                                                           dgh, nil, true,
                                                           true)
        expect(res['data']).to eq expected_data
        expect(res['metadata']).to eq expected_metadata
      end

      it 'should return grid data and metadata multi (not following)' do
        expected_data = [['G1'], ['G2'], ['G3']]
        expected_metadata = [{ 'dir' => 'v',
                               'attr' => 'ltv',
                               'keys' => ['[,115]', '(115,135]', '(135,140]'],
                               'nots' => [false, false, false],
                               'wildcards' => [false, false, false],
                               'type' => 'numrange' }]
        dgh = Marty::DataGrid.lookup_h(pt, 'G8')
        res = Marty::DataGrid.lookup_grid_distinct_entry_h(pt,
                                                           { 'ltv' => 10,
                                                             'state' => 'RI' },
                                                           dgh, nil, false,
                                                           true)
        expect(res['data']).to eq expected_data
        expect(res['metadata']).to eq expected_metadata
      end

      it 'should handle all characters in grid inputs' do
        dgh = Marty::DataGrid.lookup_h(pt, 'G1')
        5000.times do
          st = 30.times.map { rand(32..255) }.pack('U*')
          res = Marty::DataGrid.lookup_grid_distinct_entry_h(pt,
                                                             { 'ltv' => 10,
                                                               'fico' => 690,
                                                               'state' => st },
                                                             dgh, nil, false, true)
        end
      end

      it 'should handle all quote chars in grid inputs' do
        dgh = Marty::DataGrid.lookup_h(pt, 'G1')
        # single, double, backslash, grave, acute, unicode quotes: left single,
        # right single, left double, right double
        quotes = ["'", '"', '\\', '`', "\u00b4", "\u2018", "\u2019",
                  "\u201C", "\u201D"]
        100.times do
          st = 30.times.map { quotes[rand(9)] }.join
          res = Marty::DataGrid.lookup_grid_distinct_entry_h(
            pt, { 'ltv' => 10, 'fico' => 690, 'state' => st }, dgh, nil, false, true)
        end
      end

      it 'should handle quote chars in object name' do
        dgh = Marty::DataGrid.lookup_h(pt, 'G1')
        st = Gemini::State.new(name: "'\\")
        res = Marty::DataGrid.lookup_grid_distinct_entry_h(
          pt, { 'ltv' => 10, 'fico' => 690, 'state' => st }, dgh, nil, false, true)
      end

      it 'Should handle NOT condition in lookups' do
        dgh = Marty::DataGrid.lookup_h(pt, 'Gl')

        g1_res = lookup_grid_helper(
          'infinity',
          'Gl',
          { 'fha_203k_option2' => 'Admin Services Plus' },
          false,
          true
        )
        expect(g1_res).to eq([-1.625, 'Gl'])

        g1_res = lookup_grid_helper(
          'infinity',
          'Gl',
          { 'fha_203k_option2' => 'Not Existing Services' },
          false,
          true
        )
        expect(g1_res).to eq([-1.0, 'Gl'])

        g1_res = lookup_grid_helper(
          'infinity',
          'Gl',
          { 'fha_203k_option2' => 'Admin Services' },
          false,
          true
        )
        expect(g1_res).to eq([nil, 'Gl'])
      end

      it 'Should handle NOT condition in import' do
        dg = dg_from_import('Gl0', Gl)
        expect(dg.id).to be_present

        expect(dg.metadata.first['nots']).to eq([false, true, false, false])
        expect(dg.metadata.first['keys']).to eq(
          [
            ['Investor Services'],
            ['Admin Premium Services', 'Admin Services', 'Admin Services Plus'],
            ['Admin Services Plus'],
            ['Investor Services Acadamy']
          ]
        )
      end
    end

    describe 'exports' do
      it 'should export lenient grids correctly' do
        dg = dg_from_import('Gf', Gf)
        dg2 = dg_from_import('Gf2', dg.export)

        expect(dg.export).to eq(dg2.export)
      end

      it 'Should handle NOT condition in export' do
        dg = dg_from_import('Gl0', Gl)
        expect(dg.export.delete("\r")).to eq(Gl)
      end
    end

    describe 'updates' do
      it 'should be possible to modify a grid referenced from a multi-grid' do
        dgb = dg_from_import('Gb', Gb, '1/1/2014')
        dgc = dg_from_import('Gc', Gc, '2/2/2014')

        dgb.update_from_import('Gb', Gb.sub(/70/, '333'), '1/1/2015')
        dgb.update_from_import('Gb', Gb.sub(/70/, '444'), '1/1/2016')

        dgch = dgc.attributes.
                 slice('id', 'group_id', 'created_dt',  'metadata', 'data_type')
        res = Marty::DataGrid.lookup_grid_distinct_entry_h(
          '2/2/2014', { 'property_state' => 'CA' }, dgch)
        expect(res['result']).to eq(70)

        res = Marty::DataGrid.lookup_grid_distinct_entry_h(
          '2/2/2015', { 'property_state' => 'CA' }, dgch)
        expect(res['result']).to eq(333)

        res = Marty::DataGrid.lookup_grid_distinct_entry_h(
          '2/2/2016', { 'property_state' => 'CA' }, dgch)
        expect(res['result']).to eq(444)
      end

      it 'should not create a new version if no change has been made' do
        dg = dg_from_import('G4', G1)
        dg.update_from_import('G4', G1)
        expect(Marty::DataGrid.where(group_id: dg.group_id).count).to eq 1
      end

      it 'should be able to export and import back grids' do
        [G1, G2, G3, G4, G5, G6, G7, G8, G9, Ga, Gb, Gl].each_with_index do |grid, i|
          dg = dg_from_import("G#{i}", grid)
          g1 = dg.export

          dg = dg_from_import("Gx#{i}", g1)
          g2 = dg.export

          dg1 = Marty::DataGrid.lookup_h('infinity', "G#{i}").except(
            'id',
            'group_id',
            'created_dt',
            'name',
          )

          dg2 = Marty::DataGrid.lookup_h('infinity', "Gx#{i}").except(
            'id',
            'group_id',
            'created_dt',
            'name',
          )

          expect(g1).to eq g2
          expect(dg1).to eq dg2
        end
      end

      it 'Should handle NOT condition in update' do
        dgb = dg_from_import('Gl', Gl, '1/1/2014')
        new_gl = Gl.sub(/-1.0/, '-3.45').sub('Investor Services', 'NOT (Investor Services)')
        dgb.update_from_import('Gl', new_gl, '1/1/2015')

        grids = Marty::DataGrid.where(name: 'Gl')
        expect(grids.size).to eq 2

        old_dg = grids.where.not(obsoleted_dt: 'infinity').first
        new_dg = grids.where(obsoleted_dt: 'infinity').first

        expect(old_dg.metadata.first['nots']).to eq [false, true, false, false]
        expect(old_dg.data).to eq [[-0.625], [-1.0], [-1.625], [-0.5]]

        expect(new_dg.metadata.first['nots']).to eq [true, true, false, false]
        expect(new_dg.data).to eq [[-0.625], [-3.45], [-1.625], [-0.5]]
      end

      it 'should be able to externally export/import grids' do
        load_scripts(nil, Time.zone.today)

        dg = dg_from_import('G1', G1)

        p = posting('BASE', DateTime.tomorrow, '?')

        engine = Marty::ScriptSet.new.get_engine('DataReport')
        res = engine.evaluate('TableReport',
                              'result',
                              'pt_name'    => p.name,
                              'class_name' => 'Marty::DataGrid',
                             )

        # FIXME: really hacky removing "" (data_grid) -- This is a bug
        # in TableReport/CSV generation.
        res.gsub!(/\"\"/, '')
        sum = do_import_summary(Marty::DataGrid,
                                res,
                                'infinity',
                                nil,
                                nil,
                                ',',
                               )

        expect(sum).to eq(same: 1)

        res11 = res.sub(/G1/, 'G11')

        sum = do_import_summary(
          Marty::DataGrid, res11, 'infinity', nil, nil, ',')

        expect(sum).to eq(create: 1)

        g1  = Marty::DataGrid.find_by(obsoleted_dt: 'infinity', name: 'G1')
        g11 = Marty::DataGrid.find_by(obsoleted_dt: 'infinity', name: 'G11')

        expect(g1.export).to eq g11.export
      end
    end

    # write a grid of varying type and leniency;  also allow implicit
    # or explicit declaration of type (for float which is the default)
    def type_grid(lenient, type, constraint, values3, explicit_float: false)
      lenient_str = lenient ? 'lenient' : nil
      # rubocop:disable Style/NestedTernaryOperator
      type_str = type == 'float' ? (explicit_float ? 'float' : nil) : type
      # rubocop:enable Style/NestedTernaryOperator
      con_part = constraint.present? ? "\t" + constraint : ''
      top = [lenient_str, type_str].compact.join(' ') + con_part + "\n"
      (/\A\s*\z/.match?(top) ? '' : top) +
        <<~EOS
          b\tboolean\tv
          i\tinteger\tv
          i4\tint4range\tv
          n\tnumrange\tv

          true\t1\t<10\t<10.0\t#{values3[0]}
          \t2\t\t\t#{values3[1]}
          false\t\t>10\t\t#{values3[2]}
        EOS
    end

    describe 'constraint' do
      it 'constraint' do
        Mcfly.whodunnit = system_user
        Gemini::BudCategory.create!(name: 'cat1')
        Gemini::BudCategory.create!(name: 'cat2')
        Gemini::BudCategory.create!(name: 'cat3')
        tests = JSON.parse(File.read('spec/fixtures/json/data_grid.json'))
        aggregate_failures do
          tests.each do |test|
            keys = %w[id type constraint values error line1]
            id, type, constraint, values, error, line1 = test.values_at(*keys)
            err_re = Regexp.new(error) if error
            # for float, do both ex- and implicit declaration
            exfls = type == 'float' ? [true, false] : [true]
            [true, false].each do |lenient|
              exfls.each do |exfl|
                grid = type_grid(lenient, type, constraint, values,
                                 explicit_float: exfl)
                got = nil
                tnam = "Test #{id} lenient=#{lenient} exfl=#{exfl}"
                begin
                  dg = dg_from_import(tnam, grid)

                  # make sure export of line1  works correctly
                  # when dg is lenient and/or has constraint and/or
                  # not float
                  next unless lenient || constraint.present? ||
                              type != 'float'

                  # also skip grids where we included float explicitly
                  # because export will convert back to implicit
                  next if type == 'float' && exfl

                  dga = dg.export_array
                  line1 = dga.first.first.join("\t") + "\n"
                  expect(line1).to eq(grid.lines.first)
                rescue StandardError => e
                  got = e.message
                end
                ne = 'no error'
                if error
                  # rubocop:disable Lint/Debugger
                  binding.pry if ENV['PRY'] && !err_re.match(got)
                  expect(got).to match(err_re), tnam + ' failed: got ' +
                                                got || ne
                else
                  binding.pry if ENV['PRY'] && got
                  # rubocop:enable Lint/Debugger
                  expect(got).to be_nil, tnam + ' failed: got ' + (got || '')
                end
              end
            end
          end
        end
      end
    end
  end
end
