module Marty::Promises
  module Cancel
    class << self
      def call(id)
        if Marty::Config['USE_SIDEKIQ_WITH_PROMISES'].to_s == 'true'
          return call_with_sidekiq(id)
        end

        ids = get_all_ids(id)
        promises = Marty::Promise.where(id: ids)
        jobids = promises.map(&:job_id).compact.sort
        Delayed::Job.where(id: jobids).destroy_all
        promises.each do |p|
          p.update!(
            status: false,
            end_dt: p.end_dt || Time.zone.now,
            result: p.result + { error: 'Cancelled' }
          )
        end
      end

      def call_with_sidekiq(id)
        ids = get_all_ids(id)
        promises = Marty::Promise.where(id: ids)
        jobids = promises.map(&:job_id).compact.sort

        Sidekiq::Queue.all.each do |queue|
          queue.each do |job|
            job.delete if jobids.include?(job.jid)
          end
        end

        promises.each do |p|
          p.update!(
            status: false,
            end_dt: p.end_dt || Time.zone.now,
            result: p.result + { error: 'Cancelled' }
          )
        end
      end

      private

      # Promises are nodes/leaves on a tree. Given a promise id
      # from anywhere on the tree, find the ids of all promises
      # on that tree.
      def get_all_ids(id)
        get_base = lambda do |pid|
          p = Marty::Promise.find_by(id: pid)
          p.parent_id ? get_base.call(p.parent_id) : pid
        end
        base_id = get_base.call(id)
        get_children = lambda do |pid|
          children = Marty::Promise.where(parent_id: pid).pluck(:id)
          children.present? ?
            (children + children.map { |cid| get_children.call(cid) }).flatten :
            children
        end
        [base_id] + get_children.call(base_id)
      end
    end
  end
end
