class Gemini::UserGridWithoutModel < Marty::Grid
  has_marty_permissions create: :dev,
                        read: :dev,
                        update: :dev,
                        delete: :dev

  def configure(c)
    super
    c.title = 'User Grid Without Model'
    c.attributes = [
      :id,
      :login,
      :firstname,
      :lastname,
      :active,
    ]
    c.paging = false
    c.model = ServiceAdapter
  end

  attribute :id do |c|
    c.primary
    c.type = :integer
  end

  attribute :active do |c|
    c.label = 'Active'
    c.type = :boolean
    c.default_value = false
  end

  class ServiceAdapter < ::Marty::Grid::HashDataAdapter
    def model_name
      'Modelless User'
    end

    def human_model_name
      'Modelless User'
    end
    def find_record(id, options = {})
      Marty::User.find_by(id: id)&.attributes || {}
    end

    def get_records(params, columns)
      Marty::User.order(:id).map do |user|
        {
          'id' => user.id,
          'login' => user.login,
          'firstname' => user.firstname,
          'lastname' => user.lastname,
          'active' => user.active,
        }
      end
    end

    def save_record(record)
      model = Marty::User.find_by(id: record.delete('id')) || Marty::User.new
      return true if model.update(record)

      record['errors'] = model.errors.keys.each_with_object({}) do |field, hash|
        hash[field.to_s] = model.errors.full_messages_for(field)
      end
      
      false
    end
    
    def destroy_record(record)
      model = Marty::User.find(record.delete('id'))
      return true if model.destroy

      record['errors'] = model.errors.keys.each_with_object({}) do |field, hash|
        hash[field.to_s] = model.errors.full_messages_for(field)
      end

      false
    end

    def model_attribute_names
      [
        :id,
        :login,
        :firstname,
        :lastname,
        :active,
      ].map(&:to_s)
    end
  end

  def model_adapter
    @model_adapter ||= ServiceAdapter.new(model)
  end
end
