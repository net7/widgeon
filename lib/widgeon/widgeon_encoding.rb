require 'zlib'
require 'base64'
require 'json'

module WidgeonEncoding
  
  # Helper to encode an object for putting it into the HTML
  def self.encode_object(obj)
    Base64.encode64(Zlib::Deflate.deflate(Marshal.dump(obj)))
  end
  
  # Helper to encode an object for putting it into the HTML
  def self.decode_object(code)
    Marshal.load(Zlib::Inflate.inflate(Base64.decode64(code)))
  end
  
  
end
