class Marty::VwPromise < Marty::Base
  has_many :children,
           foreign_key: 'parent_id',
           class_name: 'Marty::VwPromise',
           dependent: :destroy

  belongs_to :parent, class_name: 'Marty::VwPromise'
  belongs_to :user, class_name: 'Marty::User'

  self.table_name = 'marty_vw_promises'
  self.primary_key = 'id'

  class VirtualRoot
    def self.primary_key
      'id'
    end

    def id
      'root'
    end

    def user_id
      0
    end
    alias_method :job_id, :user_id

    def result
      nil
    end
    [:start_dt, :end_dt].each { |m| alias_method m, :result }

    def status
      true
    end
  end

  def self.root
    VirtualRoot.new
  end

  def self.children_for_id(id, search_order)
    q = id == 'root' ? where(parent_id: nil) : find(id).children
    q.live_search(search_order).order(id: :desc).includes(:children, :user)
  end

  def leaf
    children.empty?
  end

  def to_s
    inspect
  end

  # Support UI live search -- FIXME: hacky to have UI scoping here
  scope :live_search, lambda { |search_text|
    return if !search_text || search_text.strip.empty?

    # Searches user login/firstname/lastname
    query = [
      'marty_users.login ILIKE ?',
      'marty_users.firstname ILIKE ?',
      'marty_users.lastname ILIKE ?',
      'marty_user_roles.role::text ILIKE ?',
    ].join(' OR ')

    st = "%#{search_text}%"
    # Convert "Role Name" or "Role name" to "role_name" (underscore is key)
    st2 = "%#{search_text.titleize.gsub(/\s/, '').underscore}%"
    joins(user: :user_roles).where(query, st, st, st, st2).distinct
  }
end
