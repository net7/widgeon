require 'zlib'
require 'base64'

module WidgeonEncoding
  
  # Encodes the given option hash for HTML, adding a hash (using the
  # session secret) for security
  def self.encode_options(options)
    raise(ArgumentError, "Options must be a Hash") unless(options.is_a?(Hash))
    enc_options = encode_object(options)
    digest = create_digest(enc_options)
    "#{enc_options}-#{digest}"
  end
  
  # Decodes the options, checking against the security hash
  def self.decode_options(code)
    elements = code.split('-')
    enc_options = elements[0]
    digest = elements[1]
    raise(ArgumentError, "Secret Hash doesn't match") unless(digest == create_digest(enc_options))
    options = decode_object(enc_options)
    raise(ArgumentError, "Options must be a Hash") unless(options.is_a?(Hash))
    options
  end
  
  # Helper to encode an object for putting it into the HTML
  def self.encode_object(obj)
    Base64.encode64(Zlib::Deflate.deflate(Marshal.dump(obj)))
  end
  
  # Helper to encode an object for putting it into the HTML
  def self.decode_object(code)
    Marshal.load(Zlib::Inflate.inflate(Base64.decode64(code)))
  end
  
  private
  
  def self.secret
    ActionController::Base.session.first[:secret]
  end
  
  # Creates a digest for the data
  def self.create_digest(data)
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new('sha'), secret, data)
  end
  
  # Returns the given Hash as a string in a repeatable fashion
  def hash_str(hash)
    (hash.sort {|a,b| a.to_s <=> b.to_s}).to_s
  end
  
end
