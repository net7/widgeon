require 'zlib'
require 'base64'

module WidgeonEncoding
  
  # Encodes the given option hash for HTML, adding a hash (using the
  # session secret) for security
  def self.encode_options(options)
    raise(ArgumentError, "Options must be a Hash") unless(options.is_a?(Hash))
    option_dump = Zlib::Deflate.deflate(Marshal.dump(options))
    # We compute the digest on the binary object (instead of the base64 version
    # to avoid mismatches due to a reformatted base64 string
    digest = create_digest(option_dump) # digest on the binary object
    enc_options = Base64.encode64(option_dump)
    "#{enc_options}-#{digest}"
  end
  
  # Decodes the options, checking against the security hash
  def self.decode_options(code)
    elements = code.split('-')
    enc_options = elements[0]
    option_dump = Base64.decode64(enc_options) # Strip the base64 code
    digest = elements[1]
    raise(ArgumentError, "Secret Hash doesn't match") unless(digest == create_digest(option_dump))
    options = Marshal.load(Zlib::Inflate.inflate(option_dump))
    raise(ArgumentError, "Options must be a Hash") unless(options.is_a?(Hash))
    options
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
