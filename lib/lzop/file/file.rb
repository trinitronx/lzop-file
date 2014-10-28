require 'pp'
require 'lzoruby'

module LZOP
  ## "header flags" constants from lzop-1.03/src/conf.h
  F_ADLER32_D     = 0x00000001
  F_ADLER32_C     = 0x00000002
  F_STDIN         = 0x00000004
  F_STDOUT        = 0x00000008
  F_NAME_DEFAULT  = 0x00000010
  F_DOSISH        = 0x00000020
  F_H_EXTRA_FIELD = 0x00000040
  F_H_GMTDIFF     = 0x00000080
  F_CRC32_D       = 0x00000100
  F_CRC32_C       = 0x00000200
  F_MULTIPART     = 0x00000400
  F_H_FILTER      = 0x00000800
  F_H_CRC32       = 0x00001000
  F_H_PATH        = 0x00002000
  F_MASK          = 0x00003FFF

  ## LZO compression modes from lzop-1.03/src/conf.h
  M_LZO1X_1     =     1
  M_LZO1X_1_15  =     2 # Not supported by lzoruby at the moment... notice no 'lzo1x_1_15_compress' in lzoruby/ext/lzoruby.c
  M_LZO1X_999   =     3

  ## version constants from lzop-1.03/src/version.h
  # Included for file header compatibility
  LZOP_VERSION           = 0x1030
  LZOP_VERSION_STRING    = "1.03"
  LZOP_VERSION_DATE      = "Nov 1st 2010"

  ADLER32_INIT_VALUE = 1
  CRC32_INIT_VALUE   = 0
end

class LZOP::File
      
  Header = Struct.new(:version, :lib_version, :version_needed_to_extract, :method, 
               :level, :flags, :filter, :mode, :mtime_low, :mtime_high, 
               :file_name_length, :file_name, :header_checksum)
  
  @@lzop_magic = [ 0x89, 0x4c, 0x5a, 0x4f, 0x00, 0x0d, 0x0a, 0x1a, 0x0a ]

  def initialize(file_path, opts={ :level => 3 })
    @fh = nil # File Handle for writing
    @header = Header.new
    @filename = File.basename(file_path, '.lzo') # Write filename without .lzo extension to header so if lzop is used to extract, it will use this as the extracted filename
    @file_path = file_path

    @header[:version] = LZOP::LZOP_VERSION
    # LZO version constant from lzo-2.08/include/lzo/lzoconf.h
    # The default '0x2080' is the earliest lzo library version which we will attempt to be compatible to if unset
    # Since lzoruby 0.1.4, we should now have direct access to this constant rather than LZO_VERSION_STRING
    @header[:lib_version] = LZO::LZO_VERSION.is_a?(Numeric) ? LZO::LZO_VERSION : 0x2080
    @header[:version_needed_to_extract] = 0x0940
    @header[:level] = opts[:level]
    @header[:method] = set_method(opts[:level])
    @header[:flags] = 0x03000001
    @header[:filter] = nil
    @header[:mode] = 0x000081a4 # This somehow means 0644 mode... magic happens in lzop-1.03/src/util.c:327 : lzo_uint32 fix_mode_for_header(lzo_uint32 mode)
    # Set mtime_low when we write the file
    # @header[:mtime_high] = 0x00000000
    @header[:file_name_length] = @filename.length
    @header[:file_name] = @filename
    @header[:header_checksum] = (@header[:flags] & LZOP::F_H_CRC32) ? LZOP::CRC32_INIT_VALUE : LZOP::ADLER32_INIT_VALUE
    
    # puts "DEBUG: My File Header is:"
    # pp @header
    # puts "Method class: #{@header[:method].class}"
    # puts "inside: #initialize() Header ObjectID is: #{@header.__id__}"
  end

  def write_header()
    # Write LZOP file header
    # References:
    #   - https://code.google.com/p/liblzop/source/browse/trunk/FILEFORMAT?r=4
    #   - http://fossies.org/dox/lzop-1.03/lzop_8c_source.html#l00704
    #   - http://fossies.org/dox/lzop-1.03/lzop_8c_source.html#l00780
    #   - http://www.ruby-doc.org/core-1.9.3/Array.html#method-i-pack

    ## Sample File:
    # 0000000: 894c 5a4f 000d 0a1a 0a10 3020 8009 4002  .LZO......0 ..@.
    # 0000010: 0103 0000 0100 0081 a454 4563 0600 0000  .........TEc....
    # 0000020: 000e 6865 6c6c 6f77 6f72 6c64 7465 7374  ..helloworldtest
    # 0000030: 8a3e 0962 0000 04b0 0000 0029 cdbb 9ee8  .>.b.......)....
    # 0000040: 0948 656c 6c6f 2057 6f72 6c64 0a20 0000  .Hello World. ..
    # 0000050: 0000 772c 000d 726c 640a 4865 6c6c 6f20  ..w,..rld.Hello
    # 0000060: 576f 726c 640a 1100 0000 0000 00         World........
    ## Sample Header:
    ## 03000001   000081a4 54456306 00000000 0e

    lzop_file_mtime = Time.now.strftime('%s').to_i
    # puts "DEBUG: File mtime_low uepoch: #{lzop_file_mtime}"
    # puts "DEBUG: File mtime_low binary: #{[lzop_file_mtime].pack('L>').each_byte.map { |b| b.to_s(16).rjust(2,'0') } }"
    @fh ||= File.open(@header[:file_name], 'wb')

    @header[:mtime_low] = lzop_file_mtime
    @header[:mtime_high] = ( lzop_file_mtime.to_i & (0xffffffff << 16 << 16 ) ) >> 16 >> 16

    # Header fields are separated per-line along with their cooresponding pack directives
    # Seems that on OSX, lzop uses big-endian mode which gives us a different result, so we'll use '>' directives to pack()
    @fh.write( @@lzop_magic.pack("C*") )
    # puts "DEBUG: Header.values.compact: #{@header.values.compact}"
    @fh.write(@header.values.compact.pack(
          'S>S>S>' + # version, lib_version, version_needed_to_extract
          'CC' +     # method, level
          'L>' +     # flags
          (@header[:filter] ? 'L>' : '') + # filter
          'L>L>L>' + # mode, mtime_low, mtime_high
          'C' + 'A' + @header.file_name.length.to_s + 'L>') # file_name_length, file_name, header_checksum
        )
  end

  def write(data)
    @fh ||= File.open(@file_path, 'wb')
    
    write_header

    @fh.write( LZO.compress(data, @header[:level]) )

    @fh.close()
  end

  private

  def set_method(level)
    method = 0

    if (level == 1)
      # Known Bug: lzoruby doesn't support this method... 
      # lzop-1.03 uses it for --fast/level 1, but lzoruby uses lzo1x_1_compress() for level 1 which is method M_LZO1X_1
      method = LZOP::M_LZO1X_1_15
      raise LZOP::Error::UnsupportedCompressionMethod, method
    elsif (level <= 6)
      method = LZOP::M_LZO1X_1
      level = 5
    elsif (l >= 7 && l <= 9)
      method = LZOP::M_LZO1X_999
    end

    unless (method != 0 || [ LZOP::M_LZO1X_1_15, LZOP::M_LZO1X_1, LZOP::M_LZO1X_999 ].include?(method) )
      raise InvalidCompressionLevel, level
    end

    # puts "I'm setting method to #{method}"
    # puts "I'm setting level to #{level}"
    # puts "inside: #set_method() Header ObjectID is: #{@header.__id__}"

    
    @header[:level] = level  # In case of level between 2 and 6, lzop simplifies these all to level 5
    # Test files generated by lzop-1.03 for levels 2-6 are identical
    method
  end
end
