require 'spec_helper'
require 'rspec/mocks'
require 'rspec/mocks/standalone'

## TODO: put this in helpers if needed?
def bin_to_hex(s)
    s.each_byte.map { |b| b.to_s(16).rjust(2,'0') }.join
end

## Test internal class header fields & magic bits
describe LZOP::File::Header.members do
  
  [ :version, :lib_version, :version_needed_to_extract, :method, 
    :level, :flags, :filter, :mode, :mtime_low, :mtime_high, 
    :file_name_length, :file_name, :header_checksum
  ].each do |field|

    it { is_expected.to include(field) }
  end
end

describe 'LZOP::File' do
  before(:all) {
    @expected_lzop_magic = [ 0x89, 0x4c, 0x5a, 0x4f, 0x00, 0x0d, 0x0a, 0x1a, 0x0a ]
    @uncompressed_file_data = "Hello World\n" * 100
    @filename = 'lzoptest.lzo'
    @test_fixture_path = File.join(File.dirname(__FILE__), '..', 'fixtures', @filename + '.3')
    @lzop_test_fixture_file_data = File.open( @test_fixture_path, 'rb').read
    @tmp_filename = File.basename(@filename)
    @tmp_file_path = File.join( '', 'tmp', @tmp_filename)

    # Stub calls to Time.now() with our fake mtime value so the mtime_low test against our test fixture works
    # This is the mtime for when the original uncompressed test fixture file was created
    @time_now = Time.at(0x544abd86)
  }

  it 'uses correct lzop_magic bits' do
    expect(LZOP::File.class_variable_get(:@@lzop_magic)).to eq @expected_lzop_magic
  end

  context 'when given a filename, no options and writing uncompressed test data' do
    
    
    # before(:each) {
    #   allow(Time).to receive(:now).and_return(@time_now)  
    # }

    describe 'the output binary file' do
      before(:all) {
        RSpec::Mocks.with_temporary_scope do
          allow(Time).to receive(:now).and_return(@time_now)  # { |a, b| a + b }
          # puts "TIME IS: #{Time.now}"
          # puts "TIME IS: #{Time.now.to_i}"
          my_test_file = LZOP::File.new( @tmp_file_path )
          my_test_file.write( @uncompressed_file_data )
          @test_file_data = File.open( @tmp_file_path, 'rb').read
        end
      }

      it 'has the correct magic bits' do
        expect( @test_file_data[0..8].unpack('C*') ).to eq @expected_lzop_magic
      end

      it 'has a correct version in LZO file header' do
        expect(@test_file_data[9..10]).to eq @lzop_test_fixture_file_data[9..10]
        # expect(test_file_data).to eq lzop_test_fixture_file_data
        # expect(Digest::MD5.hexdigest(test_file_data)).to eq Digest::MD5.hexdigest(lzop_test_fixture_file_data)
      end

      it 'has the correct library version in LZO file header' do
        expected_library_version = LZO::LZO_VERSION.is_a?(Numeric) ? LZO::LZO_VERSION : 0x2080
        expect(@test_file_data[11..12]).to eq [expected_library_version].pack('S>')
      end

      it 'has the correct lib version needed to extract in LZO file header' do
        expect(@test_file_data[13..14]).to eq [ 0x0940 ].pack('S>')
      end

      it 'has the correct method of compression in LZO file header' do
        expect(@test_file_data[15]).to eq @lzop_test_fixture_file_data[15]
      end

      it 'has the correct level of compression in LZO file header' do
        expect(@test_file_data[16]).to eq @lzop_test_fixture_file_data[16]
      end

      it 'has the compression flags in LZO file header' do
        expect(@test_file_data[17..21]).to eq @lzop_test_fixture_file_data[17..21]
      end

      ## Optional field :filter seems to be set if :flags has F_H_FILTER bit set
      ## LZOP docs say filters are "Rarely useful" so we do not support this!
      it 'has the filter in LZO file header' do
        unless @test_file_data[17..21].unpack('L>').first & LZOP::F_H_FILTER == 0
          pending('Optional header: Filter is not supported by lzop-file')
          fail
          # expect(@test_file_data[21..24]).to eq 'SOMETHING'
        end
      end

      it 'has the original file mode in LZO file header' do
        if @test_file_data[17..21].unpack('L>').first & LZOP::F_H_FILTER == 0
          start_byte=22
          end_byte=25
        else
          start_byte=25
          end_byte=28
        end
        # puts "start_byte: #{start_byte}"
        # puts "end_byte: #{end_byte}"
        # puts "mode: #{@test_file_data[start_byte..end_byte].unpack('L>').first.to_s(16)}"
        # puts "test: #{@lzop_test_fixture_file_data[start_byte..end_byte].unpack('L>').first.to_s(16)}"

        expect(@test_file_data[start_byte..end_byte]).to eq @lzop_test_fixture_file_data[start_byte..end_byte]
      end

      it 'has the original file mtime in LZO file header' do
        # puts "time_now= #{@time_now}"

        if @test_file_data[17..21].unpack('L>').first & LZOP::F_H_FILTER == 0
          mtime_low_start_byte=25
          mtime_low_end_byte=28
          mtime_high_start_byte=29
          mtime_high_end_byte=32
        else
          mtime_low_start_byte=29
          mtime_low_end_byte=32
          mtime_high_start_byte=33
          mtime_high_end_byte=36
        end
        # puts "start_byte: #{start_byte}"
        # puts "end_byte: #{end_byte}"
        # puts "mtime_low: #{@test_file_data[start_byte..end_byte].unpack('L>').first.to_s(16)}"
        # puts "test mtime: #{@lzop_test_fixture_file_data[start_byte..end_byte].unpack('L>').first.to_s(16)}"
        
        mtime_low = @test_file_data[mtime_low_start_byte..mtime_low_end_byte].unpack('L>').first
        mtime_high = @test_file_data[mtime_high_start_byte..mtime_high_end_byte].unpack('L>').first
        # The testing timestamp has no high bits, so this test should pass:
        expect(mtime_low).to eq @time_now.to_i
        expect(mtime_high).to eq 0

        mtime_fixed = ( mtime_high << 16 << 16 ) | mtime_low

        # puts "mtime_fixed: #{mtime_fixed}"
        # puts "mtime_fixed: #{mtime_fixed.to_s(16)}"

        expect(mtime_fixed).to eq @time_now.to_i
        
      end
    end
  end
end