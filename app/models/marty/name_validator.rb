class Marty::NameValidator < ActiveModel::Validator
  def validate(entry)
    raise "need field option" unless options[:field]
    field = options[:field].to_sym
    value = entry.send(field)

    return if value.nil?

    # disallow leading, trailing, >1 internal spaces, special chars (|)
    if value =~ /\A\s|\s\z|\A.*\s\s.*\z|.*\|.*/
      entry.errors[field] <<
        I18n.t("activerecord.errors.messages.extraneous_spaces")
    end
  end
end
