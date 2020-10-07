# Promise mechanism shamelessly stolen and modified from
# https://github.com/bhuga/promising-future/blob/master/lib/promise.rb

class Marty::PromiseProxy < BasicObject
  NOT_SET = ::Object.new.freeze
  METH_SET = ::Set[
                   :force,
                   :__force__,
                   # Added for Rails 4 -- were causing forced eval.
                   # This list is very hacky and will depend on how
                   # ActiveRecord treats assignment to proxy objs.
                   :is_a?,
                   :nested_under_indifferent_access,
                   :as_json,
                  ]

  instance_methods.each { |m| undef_method m unless /^(__.*|object_id)$/.match?(m) }

  def initialize(promise_id, timeout, attr = nil)
    promise_id, @timeout, @attr = promise_id, timeout, attr
    @promise = ::Marty::Promise.find(promise_id)
    @mutex   = ::Mutex.new
    @result  = NOT_SET
  end

  def as_json(*)
    { '__promise__' => [@promise.id, @timeout, @attr] }
  end

  def __promise__
    @promise
  end

  def is_a?(_c)
    # Marty::PromiseProxy == c
    # {}.is_a? c

    # FIXME: not sure why this has to return false.  Otherwise, some
    # spec tests fail.
    false
  end

  def nested_under_indifferent_access
    false
  end

  ##
  # Force the evaluation of this promise immediately
  #
  # @return [Object]
  def __force__
    if @result.equal?(NOT_SET)
      @mutex.synchronize do
        if @result.equal?(NOT_SET)
          begin
            @result = @promise.wait_for_result(@timeout)
            @result = @result[@attr] if @attr && !@result['error']
          rescue ::Exception => e
            @result = ::Delorean::Engine.grok_runtime_exception(e)
          end
        end
      end
    end

    # FIXME: the logic for shape of exceptions from Delorean is spread
    # all over the place.
    @result.is_a?(::Hash) &&
      @result['error'] ? ::Kernel.raise(@result['error']) : @result
  end

  alias_method :force, :__force__

  ##
  # Does this promise support the given method?
  #
  # @param method [Symbol]
  # @param include_all [Boolean]
  # @return [Boolean]
  def respond_to?(method, include_all = false)
    METH_SET.member?(method) || __force__.respond_to?(method, include_all)
  end

  private

  def method_missing(method, *args, &block)
    # ::File.open('/tmp/dj.out', 'a') { |f| f.puts "FORCE MISS #{method}" }

    __force__.__send__(method, *args, &block)
  end
end
