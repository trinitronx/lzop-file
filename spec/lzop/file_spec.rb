
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

describe LZOP::File::Header.members do
  
  [ :version, :lib_version, :version_needed_to_extract, :method, 
    :level, :flags, :filter, :mode, :mtime_low, :mtime_high, 
    :file_name_length, :file_name, :header_checksum
  ].each do |field|

    it { is_expected.to include(field) }
  end
end

describe 'LZOP::File' do
  ## These should never change, so hardcode away...
  let(:expected_lzop_magic) { [ 0x89, 0x4c, 0x5a, 0x4f, 0x00, 0x0d, 0x0a, 0x1a, 0x0a ] }

  it 'has correct lzop_magic bits' do
    expect(LZOP::File.class_variable_get(:@@lzop_magic)).to eq expected_lzop_magic
  end

  it "should initialize itself with default headers" do
    pending("TODO")
    fail
  end
end
