
require 'pp'

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

  ADLER32_INIT_VALUE = 1
  CRC32_INIT_VALUE   = 0
end

class LZOP::File
      
  Header = Struct.new(:version, :lib_version, :version_needed_to_extract, :method, 
               :level, :flags, :filter, :mode, :mtime_low, :mtime_high, 
               :file_name_length, :file_name, :header_checksum)
  
  @@lzop_magic = [ 0x89, 0x4c, 0x5a, 0x4f, 0x00, 0x0d, 0x0a, 0x1a, 0x0a ]

  def initialize(filename)
    @header = Header.new
    puts "DEBUG Magic bits: #{@@lzop_magic}"
    puts "DEBUG HEADER: #{ @header }"

    @header[:version] = 0x1030
    @header[:lib_version] = 0x2080
    @header[:version_needed_to_extract] = 0x0940
    @header[:method] = 0x02
    @header[:level] = 0x01
    @header[:flags] = 0x03000001
    @header[:filter] = nil
    @header[:mode] = 0x000081a4 # This somehow means 0644 mode... magic happens in lzop-1.03/src/util.c:327 : lzo_uint32 fix_mode_for_header(lzo_uint32 mode)
    # Set mtime_low when we write the file
    @header[:mtime_high] = 0x00000000
    @header[:file_name_length] = filename.length
    @header[:file_name] = filename
    @header[:header_checksum] = (@header[:flags] & LZOP::F_H_CRC32) ? LZOP::CRC32_INIT_VALUE : LZOP::ADLER32_INIT_VALUE
    
    puts "DEBUG: My File Header is:"
    pp @header
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
    @header[:mtime_low] = lzop_file_mtime
    

    # Header fields are separated per-line along with their cooresponding pack directives
    # Seems that on OSX, lzop uses big-endian mode which gives us a different result 
    file_header_array = [
      @header[:version], @header[:lib_version], @header[:version_needed_to_extract],
      @header[:method], @header[:level],
      @header[:flags]
    ]
    # Optional filter field
    file_header_array += @header[:filter] if @header[:filter]
    # Rest of fields
    file_header_array += [
      @header[:mode], @header[:mtime_low], @header[:mtime_high],
      @header[:file_name_length], @header[:file_name],
      @header[:header_checksum]
    ]
  end

  def write(data)
    File.open(filename, 'wb') { |f|
      f.write( lzop_magic.pack("C*") )
      
      f.write(file_header_array.pack(
            'S>S>S>' + 
            'CC' +
            'L>' + 
            (@header[:filter] ? 'L>' : '') + 
            'L>L>L>' + 
            'C' + 'A' + @header.file_name.length.to_s + 'L>')
          )
      f.write( LZO.compress("Hello World\n" * 100) )
    }
  end
end
