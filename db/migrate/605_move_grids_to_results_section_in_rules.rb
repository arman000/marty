class MoveGridsToResultsSectionInRules < ActiveRecord::Migration[5.1]
  def rule_models
    # Add your models here
    []
  end

  def up
    # Add your user here
    Mcfly.whodunnit = nil

    rule_models.each do |model|
      records = if model.respond_to?(:mcfly_pt)
                  model.mcfly_pt('infinity')
                else
                  model.all
                end

      records.find_each do |record|
        next if record.grids.empty?

        new_grids = record.grids.map do |k, v|
          attr_name = if k.ends_with?('_grid')
                        k
                      else
                        "#{k}_grid"
                      end

          [attr_name, "\"#{v}\""] 
        end.to_h

        record.grids = {}
        record.results = new_grids.merge(record.results)
        record.save!
      end
      raise "Grids left for #{model}" if records.any? { |v| v.grids.present? }

    end
  end

  def down
    announce("No-op on MoveGridsToResultsSectionInRules.down")
  end
end
