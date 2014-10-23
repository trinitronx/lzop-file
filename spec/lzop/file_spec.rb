
require 'spec_helper'

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
  # These should never change, so hardcode away...
  let(:expected_lzop_magic) { [ 0x89, 0x4c, 0x5a, 0x4f, 0x00, 0x0d, 0x0a, 0x1a, 0x0a ] }
  let(:uncompressed_file_data) { "Hello World\n" * 100 }
  let(:filename) { 'lzoptest.lzo' }
  let(:test_fixture_path) { File.join(File.dirname(__FILE__), '..', 'fixtures', filename) }
  let(:lzop_test_fixture_file_data) { File.open( test_fixture_path, 'rb').read }
  let(:tmp_filename) { File.basename(filename, File.extname(filename) ) }
  let(:tmp_file_path) { File.join( '', 'tmp', tmp_filename) }

  subject { LZOP::File }

  it 'has correct lzop_magic bits' do
    expect(subject.class_variable_get(:@@lzop_magic)).to eq expected_lzop_magic
  end

  it 'writes a correct LZO file header' do
    my_test_file = subject.new( tmp_file_path )
    my_test_file.write( uncompressed_file_data )
    test_file_data = File.open( tmp_file_path, 'rb').read

    expect(test_file_data).to eq lzop_test_fixture_file_data
  end
end