require "isolation/abstract_unit"
require 'rails/code_statistics.rb'

class CodeStatisticsTest < Test::Unit::TestCase
  include ActiveSupport::Testing::Isolation

  def setup
    build_app
    boot_rails
  end

  test "to_s" do
    stats_directories = [
      %w(Controllers        app/controllers),
      %w(Helpers            app/helpers),
      %w(Models             app/models),
      %w(Libraries          lib/),
      %w(Integration\ tests test/integration),
      %w(Functional\ tests  test/functional),
      %w(Unit\ tests        test/unit)
    ].map {|name, dir| [ name, "#{app_path}/#{dir}" ]}

    expected =<<-END
+----------------------+-------+-------+---------+---------+-----+-------+
| Name                 | Lines |   LOC | Classes | Methods | M/C | LOC/M |
+----------------------+-------+-------+---------+---------+-----+-------+
| Controllers          |     3 |     3 |       1 |       0 |   0 |     0 |
| Helpers              |     2 |     2 |       0 |       0 |   0 |     0 |
| Models               |     0 |     0 |       0 |       0 |   0 |     0 |
| Libraries            |     0 |     0 |       0 |       0 |   0 |     0 |
| Integration tests    |     0 |     0 |       0 |       0 |   0 |     0 |
| Functional tests     |     0 |     0 |       0 |       0 |   0 |     0 |
| Unit tests           |     0 |     0 |       0 |       0 |   0 |     0 |
+----------------------+-------+-------+---------+---------+-----+-------+
| Total                |     5 |     5 |       1 |       0 |   0 |     0 |
+----------------------+-------+-------+---------+---------+-----+-------+
  Code LOC: 5     Test LOC: 0     Code to Test Ratio: 1:0.0

    END
    assert_equal expected, CodeStatistics.new(*stats_directories).to_s
  end
end
