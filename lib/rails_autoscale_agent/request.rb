# frozen_string_literal: true

module RailsAutoscaleAgent
  class Request
    include Logger
    
    attr_reader :id, :entered_queue_at, :path, :method, :size

    def initialize(env, config)
      @config = config
      @id = env['HTTP_X_REQUEST_ID']
      @path = env['PATH_INFO']
      @method = env['REQUEST_METHOD'].downcase
      @size = env['rack.input'].respond_to?(:size) ? env['rack.input'].size : 0

      if unix_millis = env['HTTP_X_REQUEST_START']
        @entered_queue_at = Time.at(unix_millis.to_f / 1000)
      end
    end

    def ignore?
      @config.ignore_large_requests? && @size > @config.max_request_size
    end

    def queue_time
      if entered_queue_at
        if entered_queue_at < (Time.now - 60 * 10)
          # ignore unreasonable values
          logger.info "request queued for more than 10 minutes... skipping collection"
        else
          queue_time = ((Time.now - entered_queue_at) * 1000).to_i
          queue_time = 0 if queue_time < 0
          logger.info "Collected queue_time=#{queue_time}ms request_id=#{id} request_size=#{size}"

          queue_time
        end
      end
    end
  end
end
