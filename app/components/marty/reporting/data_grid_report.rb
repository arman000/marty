class Marty::Reporting::DataGridReport < Marty::ReportForm
  endpoint :update_data_grid_json_field do |params|
    pt_name = params['pt_name']
    posting = pt_name && Marty::Posting.lookup(pt_name)
    pt      = posting&.created_dt || Marty::Helper.now

    dg = Marty::DataGrid.lookup_h(pt, params['data_grid_name'])

    next '{}' unless dg

    defaults = dg['metadata'].each_with_object({}) do |attr, hash|
      type = attr['type']
      hash[attr['attr']] = case type
                           when 'boolean'
                             false
                           when 'string'
                             ''
                           when 'numrange'
                             0
                           when 'int4range'
                             0
                           when 'integer'
                             0
                           else
                             ''
                           end
    end

    JSON.pretty_generate(defaults)
  end
end
