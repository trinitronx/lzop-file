LZOP::File
==========

[![Build Status](http://img.shields.io/travis/trinitronx/lzop-file.svg)](https://travis-ci.org/trinitronx/lzop-file)
[![Gratipay](http://img.shields.io/gratipay/trinitronx.svg)](https://www.gratipay.com/trinitronx)

Ruby library for writing [LZOP](http://www.lzop.org/) files.

This gem writes the binary file format for `.lzo` or `.lz` files in native Ruby code.
The [lzoruby](https://bitbucket.org/winebarrel/lzo-ruby/src) gem is used to compress the data.

## Installation

Notes: This gem depends on `lzoruby` which uses native C extensions, and depends on the [lzo library](http://www.oberhumer.com/opensource/lzo/).
As such, it has dependencies that should probably not be used on JRuby in production.

Ruby 1.8.x is not supported due to [Array#pack()](http://ruby-doc.org/core-1.8.7/Array.html#method-i-pack) not supporting the endian-ness modifiers we need.

To install the LZO Library:

 - Ubuntu/Debian: `apt-get install liblzo2-dev`
 - RedHat/CentOS/Fedora: `yum install lzo-devel`
 - Mac OSX: `brew install lzo`

Add this line to your application's Gemfile:

```ruby
gem 'lzop-file'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lzop-file

## Usage

Writing LZO Compressed files is simple:

    require 'lzop-file'
    
    uncompressed_file_data = "Hello World\n" * 100
    
    my_test_file = LZOP::File.new( '/tmp/my_test_file.lzo' )
    my_test_file.write( uncompressed_file_data )

Or to write just the header:

    require 'lzop-file'
    
    LZOP::File.new( '/tmp/my_test_file.lzo_header' ).write_header

## Contributing

1. Fork it ( https://github.com/trinitronx/lzop-file/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
