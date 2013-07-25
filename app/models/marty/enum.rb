module Marty::Enum
  def method_missing(meth, *args, &block)
    if meth.to_s =~ /^[A-Z_]+$/ && args.empty?
      items = self.all
      items.each { |item|
        name = item.name.upcase.gsub(/[\/\s-]/, '_')
        self.define_singleton_method(name) do
          item
        end unless self.methods.member?(name.to_sym)
      }

      return self.send(meth) if self.methods.member?(meth)
    end
    super
  end
end
