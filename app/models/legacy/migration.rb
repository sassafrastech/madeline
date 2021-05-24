module Legacy
  class Migration
    def self.skip_log
      @skip_log ||= []
    end

    def self.unexpected_errors
      @unexpected_errors ||= []
    end
  end
end
