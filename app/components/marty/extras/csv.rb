module Marty::Extras::Csv

  def generate_csv(params={})
    return if config[:prohibit_read]

    begin
      # Temporarily set :enable_pagination=false so that data is not
      # limited to page size.
      orig, config[:enable_pagination] = config[:enable_pagination], false
      recs = get_data[:data]
    ensure
      config[:enable_pagination] = orig
    end

    header_key = params[:header_key] || :text

    csv_string = CSV.generate do |csv|
      # column headers
      csv << final_columns.map{ |c| c[header_key] }

      recs.each do |r|
        # hash for association column values
        av = r.pop[:association_values]
        csv << r.each_with_index.map do |item, i|
          name = final_columns[i][:name]
          av.fetch(name, item)
        end
      end
    end
  end

  # Used for testing
  def generate_txt(params={})
    generate_csv(params)
  end
end
