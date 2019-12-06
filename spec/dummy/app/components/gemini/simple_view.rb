class Gemini::SimpleView < Marty::McflyGridPanel
  has_marty_permissions create: :dev,
                        read: :dev,
                        update: :dev,
                        delete: :dev

  def configure(c)
    super
    c.title = 'Gemini Simple'
    c.model = Gemini::Simple
    c.attributes = [
      :user_id,
      :some_name,
      :active,
      :default_true
    ]
  end
end
