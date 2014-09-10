class ChunkedWriter
  def self.open(*args, **options)
    writer = new(*args, **options)
    yield(writer)
  ensure
    writer.close
  end

  attr_reader :filename, :file_count, :line_count, :options, :current_file, :limit, :lineno

  def initialize(filename, limit=1000, **options)
    @filename   = filename
    @file_count = 0
    @line_count = 0
    @options    = options
    @limit      = limit
    @lineno     = 0
  end

  def <<(row)
    if line_count >= limit
      increment_file
    end
    current_file << row
    @line_count += 1
    @lineno     += 1
  end

  def close
    close_current_file
  end

  def current_file
    @current_file ||= CSV.open(make_filename, "wb", options)
  end

  def make_filename
    "%<base>s%<number>02d%<ext>s" % {
      base: File.basename(filename, ".*"),
      number: file_count,
      ext: File.extname(filename)
    }
  end

  def increment_file
    close_current_file
    @file_count   += 1
    @current_file = nil
    @line_count   = 0
  end

  def close_current_file
    current_file.close
    $stderr.puts "Wrote #{line_count} rows to #{make_filename}"
    @current_file = nil
  end
end
