require 'pry'
require 'date'
require 'active_support'

class GFD
  START_DIRECTORY_HEADER = [254, 239]
  END_DIRECTORY_HEADER = [239, 254]
  FILE_HEADER = [238, 255]
  SEP = File::SEPARATOR.encode('utf-16le')

  def initialize(path)
    raise ArgumentError("#{path} not found") unless File.exists?(path)

    @path = path
    @mf = []
    @idx = 0
    @entries = nil
  end

  def entries
    @entries ||= process
  end

  private
  def process
    entries = []
    dirs = []

    @mf = File.binread(@path).bytes

    while (@idx < @mf.length)
      @record_start = @idx
      header = @mf[@idx, 2]
      @idx += 2

      if header == START_DIRECTORY_HEADER
        dirs << read_utf16_string

        entries << {type: :dir, path: dirs.join(SEP) }
      elsif header == END_DIRECTORY_HEADER
        dirs.pop
      elsif header == FILE_HEADER
        file = read_utf16_string

        #read file size segment, an 8-byte big endian unsigned integer
        size = @mf[@idx, 8].pack('c*').unpack('Q>').first
        @idx += 8

        #read file modified date, 2 bytes for year, 1 byte for month, 1 byte for day
        year = @mf[@idx, 2].pack('c*').unpack('s>').first
        month = @mf[@idx+2]
        day = @mf[@idx+3]
        mtime = Date.new(year, month, day).to_time
        @idx += 4

        entries << {type: :file, path: dirs.join(SEP) + SEP + file, size: size, mtime: mtime}
      else
        raise "Unknown header: #{header.join(' ')}"
      end
    end

    entries
  end

  def read_flag_str
    str = "%08d" % @mf[@idx].to_s(2).to_i
    @idx += 1
    str
  end

  def read_utf16_string
    #Read the length of the string in bytes
    len = @mf[@idx]
    @idx += 1

    #If the length is 0xFA we assume the length byte doesnt have the space to represent the true length of the filename.
    #Thus we go byte by byte and look for the ending null. Have never seen a length byte greater than 0xFA, but HAVE
    #seen plenty of longer strings.
    if len == 0xFA
      len = 0
      len += 2 while @mf[@idx+len] != 0
    elsif len > 0xFA
      raise "Got > 0xFA for a entry length byte in the record header. Not sure what to do with that."
    end

    #Read the string and pack into an utf-16 string
    #TODO: This #pack.#force_encoding could easily be wrong. and the pack template may should be "C*"
    s = @mf[@idx, len].pack("c*").force_encoding('utf-16le')
    @idx += len

    #skip the ending null
    @idx += 1

    s
  end
end