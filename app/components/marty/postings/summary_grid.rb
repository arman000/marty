module Marty
  module Postings
    class SummaryGrid < Marty::Grid
      def configure(c)
        super

        c.model = 'Marty::Log' # Hack, since grid requires a model to be set
        c.multi_select = false
        c.read_only = true
        c.attributes ||= [:klass, :created, :updated, :deleted]
        c.title ||= I18n.t('summary', default: 'Summary')
        c.paging = false
        c.min_height = 400
        c.height = 400
        c.bbar = nil
      end

      client_styles do |c|
        c.require :summary_grid
      end

      attribute :klass do |c|
        c.min_width = 300
        c.sortable = true
      end

      column :created do |c|
        c.sortable = true
      end

      column :updated do |c|
        c.sortable = true
      end

      column :deleted do |c|
        c.sortable = true
      end

      def get_records(params)
        return [] if config[:selected_posting_type].blank?
        return [] if config[:selected_posting_type].to_i.negative?

        last_posting = Marty::Posting.where(
          posting_type_id: config[:selected_posting_type]
        ).where.not(created_dt: 'infinity').order(:created_dt).last

        start_dt = last_posting&.created_dt || 1.year.ago
        end_dt = Time.zone.now

        posting_type = Marty::PostingType.find(config[:selected_posting_type])

        summary_records = class_list(posting_type).map do |klass|
          summary = Marty::DataChange.change_summary(start_dt, end_dt, klass)
          OpenStruct.new(summary.merge('klass' => klass))
        end

        records_with_changes = summary_records.select do |record|
          record.created > 0 || record.updated > 0 || record.deleted > 0
        end

        total_summary = OpenStruct.new(
          klass: 'Total',
          created: summary_records.sum(&:created),
          updated: summary_records.sum(&:updated),
          deleted: summary_records.sum(&:deleted)
        )

        [total_summary] + sort_records(params, records_with_changes)
      end

      def class_list(posting_type)
        method_name = "class_list_#{posting_type.name}".downcase.to_sym

        if Marty::DataChange.respond_to?(method_name)
          Marty::DataChange.send(method_name)
        else
          Marty::DataChange.class_list
        end
      end

      def sort_records(params, records)
        return records if params['sorters'].blank?

        sorting_attr = params.dig('sorters', 0, 'property').to_sym

        sorted = records.sort_by(&:sorting_attr)
        sorted = sorted.reverse if params.dig('sorters', 0, 'direction') != 'ASC'

        sorted
      end

      def count_records(_params, _columns = [])
        return 0 if config[:selected_posting_type].blank?
        return 0 if config[:selected_posting_type].to_i.negative?

        Marty::DataChange.class_list.size + 1
      end
    end
  end
end
