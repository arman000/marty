module Marty::PgEnum
  def [](i0, i1 = nil)
    # if i1 is provided, then i0 is a pt and we ignore it.
    index = (i1 || i0).to_s

    raise "no such #{name}: '#{index}'" unless
      self::VALUES.include?(index)

    index
  end

  def self.extended(base)
    base.class_eval do
      extend ::Delorean::Functions unless respond_to?(:delorean_fn)

      delorean_fn :get_all do |_pt = nil|
        self::VALUES.map(&:to_s)
      end

      delorean_fn :[] do |i0, i1 = nil|
        super(i0, i1)
      end

      delorean_fn :lookup do |i0, i1 = nil|
        send(:[], i0, i1)
      end

      delorean_fn :find_by_name do |i0, i1 = nil|
        send(:[], i0, i1)
      end
    end
  end

  def seed
  end

  def _pg_enum?
    true
  end
end
