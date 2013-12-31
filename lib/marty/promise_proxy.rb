# Promise mechanism shamelessly stolen and modified from
# https://github.com/bhuga/promising-future/blob/master/lib/promise.rb

class Marty::PromiseProxy < BasicObject
  NOT_SET = ::Object.new.freeze

  instance_methods.each {|m| undef_method m unless m =~ /^(__.*|object_id)$/}

  def initialize(promise, timeout)
    @promise  	= promise
    @timeout	= timeout
    @mutex  	= ::Mutex.new
    @result 	= NOT_SET
    @error  	= NOT_SET
  end

  ##
  # Force the evaluation of this promise immediately
  #
  # @return [Object]
  def __force__
    @mutex.synchronize do
      if @result.equal?(NOT_SET) && @error.equal?(NOT_SET)
        begin
          @result = @promise.wait_for_result(@timeout)
        rescue ::Exception => e
          @error = e
        end
      end
    end if @result.equal?(NOT_SET) && @error.equal?(NOT_SET)

    # BasicObject won't send raise to Kernel
    @error.equal?(NOT_SET) ? @result : ::Kernel.raise(@error)
  end
  alias_method :force, :__force__

  ##
  # Does this promise support the given method?
  #
  # @param  [Symbol]
  # @return [Boolean]
  def respond_to?(method)
    :force.equal?(method) ||
      :__force__.equal?(method) ||
      __force__.respond_to?(method)
  end

  private

  def method_missing(method, *args, &block)
    __force__.__send__(method, *args, &block)
  end
end
