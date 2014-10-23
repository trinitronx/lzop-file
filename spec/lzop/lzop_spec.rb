require 'spec_helper'

describe ::LZOP do
  let(:expected_constants) { 
    {
      :F_ADLER32_D     => 0x00000001,
      :F_ADLER32_C     => 0x00000002,
      :F_STDIN         => 0x00000004,
      :F_STDOUT        => 0x00000008,
      :F_NAME_DEFAULT  => 0x00000010,
      :F_DOSISH        => 0x00000020,
      :F_H_EXTRA_FIELD => 0x00000040,
      :F_H_GMTDIFF     => 0x00000080,
      :F_CRC32_D       => 0x00000100,
      :F_CRC32_C       => 0x00000200,
      :F_MULTIPART     => 0x00000400,
      :F_H_FILTER      => 0x00000800,
      :F_H_CRC32       => 0x00001000, # This is used currently
      :F_H_PATH        => 0x00002000,
      :F_MASK          => 0x00003FFF,

      :LZOP_VERSION           => 0x1030,
      :LZOP_VERSION_STRING    => "1.03",
      :LZOP_VERSION_DATE      => "Nov 1st 2010",
      :LZO_VERSION            => 0x2080,

      :ADLER32_INIT_VALUE => 1, # This is used currently
      :CRC32_INIT_VALUE   => 0  # This is used currently
    }
  }
  
  it "should contain important constants from lzop source code" do
    expected_constants.each do |constant, value|
      expect(subject.constants).to include(constant)
      expect(subject.const_get(constant)). to eq value
    end
  end
end