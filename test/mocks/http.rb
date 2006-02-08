require 'net/http'

module Net
  class HTTP
    alias_method :old_get, :get
    def get(path, *args)
      begin
        filename = File.dirname(__FILE__) + "/" + File.basename(path)
        return File.open(filename)
      rescue Errno::ENOENT
        old_get(path, *args)
      end
    end
  end
end

class File
  alias_method :body, :read
end
