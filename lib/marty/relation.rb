class Marty::Relation
  # Given a Mcfly class (klass) and a list of classes which can
  # reference klass, returns instaces of klass which have no references.
  def self.not_referenced(klass, ref_classes)
    col = (klass.name.split('::').last.snakecase + '_id').to_sym

    ids = klass.where(obsoleted_dt: 'infinity').pluck(:group_id)

    ref_ids = ref_classes.map do |rclass|
      rclass.where(obsoleted_dt: 'infinity', col => ids).pluck(col)
    end.flatten.uniq

    klass.where(id: ids - ref_ids).to_a
  end

  # Find Mcfly references from klass instances which have been
  # obsoleted.  A hash is returned with a key for each
  # mcfly_belongs_to reference from klass.
  def self.obsoleted_references(klass)
    assoc_h = Marty::DataConversion.associations(klass)
    assoc_h.each_with_object({}) do |(a, ah), h|
      assoc_class = ah[:assoc_class]
      foreign_key = ah[:foreign_key]

      next unless Mcfly.mcfly? assoc_class

      h[a] = klass.where(obsoleted_dt: 'infinity').map do |obj|
        ref_key = obj.send(foreign_key)
        next unless ref_key

        ref = assoc_class.find(ref_key)
        obj unless Mcfly.is_infinity(ref.obsoleted_dt)
      end.compact
    end
  end
end
