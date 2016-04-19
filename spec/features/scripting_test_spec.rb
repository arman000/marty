require 'spec_helper'

feature 'on Data Import', js: true do

  before(:all) do
    @clean_file = "/tmp/clean_#{Process.pid}.psql"
    save_clean_db(@clean_file)
    populate_test_users
    populate_sample_scripts1
    populate_sample_scripts2
    custom_selectors
  end

  after(:all) do
    restore_clean_db(@clean_file)
  end

  def go_to_scripting
    press('Applications')
    press('Scripting')
  end

  def with_user(uname, &block)
    u = Marty::User.find_by_login(uname)
    begin
      old_u, Mcfly.whodunnit = Mcfly.whodunnit, u
      block.call(u)
    ensure
      Mcfly.whodunnit = old_u
    end
  end

  def populate_sample_scripts1
    sample_script = <<DELOREAN
A:
    a =? 123.0
    b = a * 3

B: A
    c = a + b
    d =?
    e = c / a

C:
    p0 =?
    a = 456.0 + p0
DELOREAN

    with_user("dev1") { |u|
      Marty::Script.
        load_script_bodies({
                             "M1" => sample_script,
                             "M2" => sample_script.gsub(/a/, "aa").gsub(/b/, "bb"),
                           }, Date.today)

      # add a DEV version of M1.
      s = Marty::Script.lookup('infinity', "M1")
      s.body = sample_script.gsub(/A/, "AA") + '    e =? "hello"'
      s.save!
    }
  end

  def populate_sample_scripts2
    sample_script2 = <<DELOREAN
A:
    a = 2
    p =?
    c = a * 2
    pc = p + c

C: A
    p =? 3

B: A
    p =? 5
DELOREAN

    with_user("dev1") { |u|
      Marty::Script.
        load_script_bodies({
                             "M3" => sample_script2,
                           }, Date.today + 2.minute)
    }
  end

  let(:tg) { gridpanel('tag_grid') }
  let(:sg) { gridpanel('script_grid') }

  it 'switches between 2 diff tags and 2 diff scripts' do
    log_in_as('dev1')
    go_to_scripting

    by 'select M1 sample script' do
      wait_for_ajax
      zoom_out(tg)
      select_row(2, tg)
      select_row(1, sg)
      press('Testing')
    end

    and_by 'compute attrs with bad params' do
      wait_for_ajax
      find(:xpath, "//div[text()='Compute Attributes']", wait: 10)
      fill_in('attrs', with: "A.a; A.b; B.a; C.a")
      fill_in('params', with: "a = 1.1\nc = 2.2")
      press('Compute')
    end

    and_by 'see errors' do
      wait_for_ajax
      expect(page).to have_content 'undefined parameter p0'
    end

    and_by 'compute attrs with good params' do
      fill_in('params', with: "a = 1.1\nc = 2.2\np0 = 3.3\n")
      press('Compute')
    end

    and_by 'correct results' do
      wait_for_ajax
      result = find(:gridpanel, 'result', match: :first)
      expect(result).to have_content 'A.a = 1.1'
      expect(result).to have_content 'A.b = 3.3'
      expect(result).to have_content 'B.a = 1.1'
      expect(result).to have_content 'C.a = 459.3'
    end

    and_by 'compute new attrs & bad params (div by 0)' do
      fill_in('attrs', with: "B.e")
      fill_in('params', with: "a = 0\n")
      press('Compute')
    end

    and_by 'see errors' do
      wait_for_ajax
      result = find(:gridpanel, 'result', match: :first)
      expect(result).to have_content 'divided by 0'
      expect(result).to have_content 'Backtrace'
      expect(result).to have_content 'M1:8 /'
      expect(result).to have_content 'M1:8 e'
    end

    and_by 'select M1 (for dev) sample script' do
      press('Selection')
      wait_for_ajax
      find(:gridpanel, 'script_grid', match: :first, wait: 10)
      select_row(1, tg)
      select_row(1, sg)
      press('Testing')
    end

    and_by 'compute attrs with empty params' do
      wait_for_ajax
      fill_in('attrs', with: "A.a")
      fill_in('params', with: "")
      press('Compute')
    end

    and_by 'see errors' do
      wait_for_ajax
      result = find(:gridpanel, 'result', match: :first)
      expect(result).to have_content 'node A is undefined'
    end

    and_by 'compute attrs that without necessary params' do
      fill_in('attrs', with: "C.e")
      press('Compute')
    end

    and_by 'correct result' do
      wait_for_ajax
      result = find(:gridpanel, 'result', match: :first)
      expect(result).to have_content 'hello'
    end

    and_by 'select M2 sample grid' do
      press('Selection')
      wait_for_ajax
      select_row(2, sg)
      press('Testing')
    end

    and_by 'compute attrs with good params' do
      wait_for_ajax
      fill_in('attrs', with: "B.aa")
      fill_in('params', with: "aa = 111")
      press('Compute')
    end

    and_by 'correct result' do
      wait_for_ajax
      result = find(:gridpanel, 'result', match: :first)
      expect(result).to have_content 'B.aa = 111'
    end
  end

  it 'deals with malformed params/attrs input' do
    log_in_as('dev1')
    go_to_scripting

    by 'select M1 sample script' do
      wait_for_ajax
      select_row(1, sg)
      press('Testing')
    end

    and_by 'use bad attributes' do
      wait_for_ajax
      find(:xpath, "//div[text()='Compute Attributes']", wait: 10)
      fill_in('attrs', with: "A; y; >")
      press('Compute')
    end

    and_by 'see errors' do
      wait_for_ajax
      result = find(:gridpanel, 'result', match: :first)
      expect(result).to have_content 'bad attribute'
    end

    and_by 'use bad node' do
      wait_for_ajax
      fill_in('attrs', with: ">.<")
      press('Compute')
    end

    and_by 'see errors' do
      wait_for_ajax
      result = find(:gridpanel, 'result', match: :first)
      expect(result).to have_content 'bad node'
    end

    and_by 'use good attr' do
      wait_for_ajax
      fill_in('attrs', with: "A.a")
      press('Compute')
    end

    and_by 'see good result' do
      wait_for_ajax
      result = find(:gridpanel, 'result', match: :first)
      expect(result).to have_content 'A.a = 123.0'
    end

    and_by 'use undefined attr' do
      wait_for_ajax
      fill_in('attrs', with: "A.new")
      press('Compute')
    end

    and_by 'see errors' do
      wait_for_ajax
      result = find(:gridpanel, 'result', match: :first)
      expect(result).to have_content 'undefined'
    end
  end

  it 'computes simple values' do
    log_in_as('dev1')
    go_to_scripting

    by 'select M3 sample script' do
      wait_for_ajax
      zoom_out(sg)
      select_row(3, sg)
      press('Testing')
    end

    and_by 'use good attr' do
      wait_for_ajax
      find(:xpath, "//div[text()='Compute Attributes']", wait: 10)
      fill_in('attrs', with: "C.p; B.p")
      press('Compute')
    end

    and_by 'see good result' do
      wait_for_ajax
      result = find(:gridpanel, 'result', match: :first)
      expect(result).to have_content 'C.p = 3'
      expect(result).to have_content 'B.p = 5'
    end

    and_by 'add a good param' do
      wait_for_ajax
      fill_in('params', with: "p = 7")
      press('Compute')
    end

    and_by 'see good result' do
      wait_for_ajax
      result = find(:gridpanel, 'result', match: :first)
      expect(result).to have_content 'C.p = 7'
      expect(result).to have_content 'B.p = 7'
    end

    and_by 'use good attr' do
      wait_for_ajax
      fill_in('attrs', with: "C.pc; B.pc")
      fill_in('params', with: "")
      press('Compute')
    end

    and_by 'see good result' do
      wait_for_ajax
      result = find(:gridpanel, 'result', match: :first)
      expect(result).to have_content 'C.pc = 7'
      expect(result).to have_content 'B.pc = 9'
    end

     and_by 'use bad attr' do
      wait_for_ajax
      fill_in('attrs', with: "C.pc; B.pc; A.pc;")
      fill_in('params', with: "")
      press('Compute')
    end

    and_by 'see error' do
      wait_for_ajax
      result = find(:gridpanel, 'result', match: :first)
      expect(result).to have_content 'undefined parameter p'
    end

    and_by 'use good attr & params' do
      wait_for_ajax
      fill_in('attrs', with: "C.pc; B.pc")
      fill_in('params', with: "p = 123.0")
      press('Compute')
    end

    and_by 'see good result' do
      wait_for_ajax
      result = find(:gridpanel, 'result', match: :first)
      expect(result).to have_content 'C.pc = 127'
      expect(result).to have_content 'B.pc = 127'
    end
  end
end
