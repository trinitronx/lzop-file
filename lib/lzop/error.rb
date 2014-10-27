module LZOP

  class Error

    class InvalidCompressionMethod < RuntimeError
      def initialize(method)
        super "Invalid LZO method: #{method}. Valid values are: 1 (LZO1X-1(15)), 2 (LZO1X-1), and  3 (LZO1X-999)"
      end
    end

    class UnsupportedCompressionMethod < RuntimeError
      def initialize(method)
        super "LZO method: #{method} is currently unsupported by lzoruby"
      end
    end

    class InvalidCompressionLevel < RuntimeError
      def initialize(level)
        super "Invalid LZO level: #{level}. Valid values are 1-9"
      end
    end
  end
end