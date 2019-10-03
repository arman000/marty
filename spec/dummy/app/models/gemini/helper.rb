require 'delorean_lang'

class Gemini::Helper
  include Delorean::Model

  # Just for testing
  delorean_fn :sleep, sig: 1 do
    |seconds, label = ''|

    Marty::Logger.info('sleeping', {label: label}) if label.present?

    Kernel.sleep seconds
    seconds.to_s
  end

  def self.pr_wait(ids)
    idh = ids.each_with_object({}) do |id, h|
      h[id] = false
    end
    timeout = 60
    all_done = false
    loop do
      idh.each do |id, v|
        next if v
        p = Marty::Promise.uncached { Marty::Promise.find_by(id: id) }
        idh[id] = p.result if p.status
      end
      all_done = idh.values.all? { |v| v }
      break if all_done || timeout == 0
      timeout -= 1
      sleep 1
    end
    raise "DID NOT FINISH" unless all_done
    idh.values.map { |h| h['result'] }
  end

  # Just for testing
  delorean_fn :to_csv, sig: [1, 2] do
    |*args|

    # NOTE: can't use |data, config| due to delorean_fn weirdness.
    data, config = args

    Marty::DataExporter.to_csv(data, config)
  end

  # Just for testing
  delorean_fn :import_data, sig: [2, 3] do
    |import_type_name, data, col_sep|

    col_sep ||= "\t"

    imp_t = Marty::ImportType.find_by_name(import_type_name)

    raise "Insufficient permissions to run the data import" unless
      imp_t.allow_import?

    Marty::DataImporter.do_import_summary(imp_t.get_model_class,
                                          data,
                                          'infinity',
                                          imp_t.cleaner_function,
                                          imp_t.validation_function,
                                          col_sep,
                                          false)
  end

  delorean_fn :infinity_dt, sig: 1 do
    |pt|
    Mcfly.is_infinity pt
  end

  delorean_fn :testlog, sig: 2 do
    |str, data|
    10.times { Marty::Logger.info(str, data) }
    true
  end

  delorean_fn :testaction, sig: 2 do
    |str, id|
    File.open("/tmp/logaction.txt", "a") do |f|
      f.puts str % [id]
    end
    true
  end

  delorean_fn :get_inds do |cnt|
    (0..cnt-1).to_a
  end

  delorean_fn :priority_tester do |reverse, job_cnt|
    blockers = 8.times.map do |idx|
      title =  "Blocker #{idx}"
      Marty::Promises::Ruby::Create.call(
        module_name: 'Gemini::Helper',
        method_name: 'sleep',
        method_args: [5, title],
        params: {
          p_title: title,
          _user_id: 1,
          p_priority: 0,
        }.compact
      ).as_json.values.first.first
    end
    prioritized = job_cnt.times.map do |idx|
      pri = reverse ? job_cnt - idx : idx
      title =  "Prioritized #{idx} pri=#{pri}"
      Marty::Promises::Ruby::Create.call(
        module_name: 'Gemini::Helper',
        method_name: 'sleep',
        method_args: [2, title],
        params: {
          p_title: title,
          _user_id: 1,
          p_priority: pri
        }.compact
      ).as_json.values.first.first
    end
    pr_wait(blockers) + pr_wait(prioritized)
  end

  delorean_fn :priority_inh_tester do |title|
    [Marty::Promises::Ruby::Create.call(
        module_name: 'Gemini::Helper',
        method_name: 'sleep',
        method_args: [0, 'child1'],
        params: {
          p_title: title + ' child1',
          _user_id: 1,
          _parent_id: ENV['__promise_id']&.to_i
        }.compact
     ).as_json.values.first.first,
     Marty::Promises::Ruby::Create.call(
        module_name: 'Gemini::Helper',
        method_name: 'sleep',
        method_args: [0, 'child2'],
        params: {
          p_title: title + ' child2',
          _user_id: 1,
          p_priority: 10,
          _parent_id: ENV['__promise_id']&.to_i
        }.compact
     ).as_json.values.first.first]
  end
end
