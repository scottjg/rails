class CodeStatistics #:nodoc:

  TEST_TYPES = %w(Units Functionals Unit\ tests Functional\ tests Integration\ tests)

  def initialize(*pairs)
    @pairs = pairs
  end

  def to_s
    CodeStatisticsView.new(self).to_s
  end

  def multiple_pairs?
    @pairs.length > 1
  end

  def statistics
    @statistics ||= Hash[@pairs.map{|pair| [pair.first, calculate_directory_statistics(pair.last)]}]
  end

  def calculate_total
    total = { "lines" => 0, "codelines" => 0, "classes" => 0, "methods" => 0 }
    statistics.each_value { |pair| pair.each { |k, v| total[k] += v } }
    total
  end

  def code_loc
    code_loc = 0
    statistics.each { |k, v| code_loc += v['codelines'] unless TEST_TYPES.include? k }
    code_loc
  end

  def tests_loc
    test_loc = 0
    statistics.each { |k, v| test_loc += v['codelines'] if TEST_TYPES.include? k }
    test_loc
  end

  def code_to_test_ratio
    tests_loc.to_f/code_loc
  end

  def lines
    @pairs.collect do |pair|
      line(pair.first, statistics[pair.first])
    end
  end

  def total
    line("Total", calculate_total)
  end

  def line(name, statistics)
    m_over_c   = (statistics["methods"] / statistics["classes"])   rescue m_over_c = 0
    loc_over_m = (statistics["codelines"] / statistics["methods"]) - 2 rescue loc_over_m = 0

    {
      :name => name,
      :lines => statistics["lines"],
      :codelines => statistics["codelines"],
      :classes => statistics["classes"],
      :methods => statistics["methods"],
      :m_over_c => m_over_c,
      :loc_over_m => loc_over_m
    }
  end

  private
  def calculate_directory_statistics(directory, pattern = /.*\.rb$/)
    stats = { "lines" => 0, "codelines" => 0, "classes" => 0, "methods" => 0 }

    Dir.foreach(directory) do |file_name|
      if File.stat(directory + "/" + file_name).directory? and (/^\./ !~ file_name)
        newstats = calculate_directory_statistics(directory + "/" + file_name, pattern)
        stats.each { |k, v| stats[k] += newstats[k] }
      end

      next unless file_name =~ pattern

      f = File.open(directory + "/" + file_name)

      while line = f.gets
        stats["lines"]     += 1
        stats["classes"]   += 1 if line =~ /class [A-Z]/
        stats["methods"]   += 1 if line =~ /def [a-z]/
        stats["codelines"] += 1 unless line =~ /^\s*$/ || line =~ /^\s*#/
      end
    end

    stats
  end
end

class CodeStatisticsView
  def initialize(stats)
    @stats = stats
  end
  def to_s
    lines = []
    lines << hr
    lines << header
    lines << hr
    lines << @stats.lines.map {|l| line(l) }
    lines << hr
    if @stats.multiple_pairs?
      lines << line(@stats.total)
      lines << hr
    end
    lines << code_test_stats
    lines << br
    lines << br
    lines.join("\n")
  end
  private
  def header
    "| Name                 | Lines |   LOC | Classes | Methods | M/C | LOC/M |"
  end
  def line(data)
    "| #{data[:name].ljust(20)} " +
      "| #{data[:lines].to_s.rjust(5)} " +
      "| #{data[:codelines].to_s.rjust(5)} " +
      "| #{data[:classes].to_s.rjust(7)} " +
      "| #{data[:methods].to_s.rjust(7)} " +
      "| #{data[:m_over_c].to_s.rjust(3)} " +
      "| #{data[:loc_over_m].to_s.rjust(5)} |"
  end
  def code_test_stats
    "  Code LOC: #{@stats.code_loc}     "+
      "Test LOC: #{@stats.tests_loc}     "+
      "Code to Test Ratio: 1:#{sprintf("%.1f", @stats.code_to_test_ratio)}"
  end
  def hr
    "+----------------------+-------+-------+---------+---------+-----+-------+"
  end
  def br
    ''
  end
end
