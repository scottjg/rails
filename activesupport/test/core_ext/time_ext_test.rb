require 'abstract_unit'
require 'active_support/time'
require 'core_ext/date_and_time_behavior'

class TimeExtCalculationsTest < ActiveSupport::TestCase
  def date_time_init(year,month,day,hour,minute,second,usec=0)
    Time.local(year,month,day,hour,minute,second,usec)
  end

  include DateAndTimeBehavior

  def test_seconds_since_midnight
    assert_equal 1,Time.local(2005,1,1,0,0,1).seconds_since_midnight
    assert_equal 60,Time.local(2005,1,1,0,1,0).seconds_since_midnight
    assert_equal 3660,Time.local(2005,1,1,1,1,0).seconds_since_midnight
    assert_equal 86399,Time.local(2005,1,1,23,59,59).seconds_since_midnight
    assert_equal 60.00001,Time.local(2005,1,1,0,1,0,10).seconds_since_midnight
  end

  def test_seconds_since_midnight_at_daylight_savings_time_start
    with_env_tz 'US/Eastern' do
      # dt: US: 2005 April 3rd 2:00am ST => April 3rd 3:00am DT
      assert_equal 2*3600-1, Time.local(2005,4,3,1,59,59).seconds_since_midnight, 'just before DST start'
      assert_equal 2*3600+1, Time.local(2005,4,3,3, 0, 1).seconds_since_midnight, 'just after DST start'
    end

    with_env_tz 'NZ' do
      # dt: New Zealand: 2006 October 1st 2:00am ST => October 1st 3:00am DT
      assert_equal 2*3600-1, Time.local(2006,10,1,1,59,59).seconds_since_midnight, 'just before DST start'
      assert_equal 2*3600+1, Time.local(2006,10,1,3, 0, 1).seconds_since_midnight, 'just after DST start'
    end
  end

  def test_seconds_since_midnight_at_daylight_savings_time_end
    with_env_tz 'US/Eastern' do
      # st: US: 2005 October 30th 2:00am DT => October 30th 1:00am ST
      # avoid setting a time between 1:00 and 2:00 since that requires specifying whether DST is active
      assert_equal 1*3600-1, Time.local(2005,10,30,0,59,59).seconds_since_midnight, 'just before DST end'
      assert_equal 3*3600+1, Time.local(2005,10,30,2, 0, 1).seconds_since_midnight, 'just after DST end'

      # now set a time between 1:00 and 2:00 by specifying whether DST is active
      # uses: Time.local( sec, min, hour, day, month, year, wday, yday, isdst, tz )
      assert_equal 1*3600+30*60, Time.local(0,30,1,30,10,2005,0,0,true,ENV['TZ']).seconds_since_midnight, 'before DST end'
      assert_equal 2*3600+30*60, Time.local(0,30,1,30,10,2005,0,0,false,ENV['TZ']).seconds_since_midnight, 'after DST end'
    end

    with_env_tz 'NZ' do
      # st: New Zealand: 2006 March 19th 3:00am DT => March 19th 2:00am ST
      # avoid setting a time between 2:00 and 3:00 since that requires specifying whether DST is active
      assert_equal 2*3600-1, Time.local(2006,3,19,1,59,59).seconds_since_midnight, 'just before DST end'
      assert_equal 4*3600+1, Time.local(2006,3,19,3, 0, 1).seconds_since_midnight, 'just after DST end'

      # now set a time between 2:00 and 3:00 by specifying whether DST is active
      # uses: Time.local( sec, min, hour, day, month, year, wday, yday, isdst, tz )
      assert_equal 2*3600+30*60, Time.local(0,30,2,19,3,2006,0,0,true, ENV['TZ']).seconds_since_midnight, 'before DST end'
      assert_equal 3*3600+30*60, Time.local(0,30,2,19,3,2006,0,0,false,ENV['TZ']).seconds_since_midnight, 'after DST end'
    end
  end

  def test_seconds_until_end_of_day
    assert_equal 0, Time.local(2005,1,1,23,59,59).seconds_until_end_of_day
    assert_equal 1, Time.local(2005,1,1,23,59,58).seconds_until_end_of_day
    assert_equal 60, Time.local(2005,1,1,23,58,59).seconds_until_end_of_day
    assert_equal 3660, Time.local(2005,1,1,22,58,59).seconds_until_end_of_day
    assert_equal 86399, Time.local(2005,1,1,0,0,0).seconds_until_end_of_day
  end

  def test_seconds_until_end_of_day_at_daylight_savings_time_start
    with_env_tz 'US/Eastern' do
      # dt: US: 2005 April 3rd 2:00am ST => April 3rd 3:00am DT
      assert_equal 21*3600, Time.local(2005,4,3,1,59,59).seconds_until_end_of_day, 'just before DST start'
      assert_equal 21*3600-2, Time.local(2005,4,3,3,0,1).seconds_until_end_of_day, 'just after DST start'
    end

    with_env_tz 'NZ' do
      # dt: New Zealand: 2006 October 1st 2:00am ST => October 1st 3:00am DT
      assert_equal 21*3600, Time.local(2006,10,1,1,59,59).seconds_until_end_of_day, 'just before DST start'
      assert_equal 21*3600-2, Time.local(2006,10,1,3,0,1).seconds_until_end_of_day, 'just after DST start'
    end
  end

  def test_seconds_until_end_of_day_at_daylight_savings_time_end
    with_env_tz 'US/Eastern' do
      # st: US: 2005 October 30th 2:00am DT => October 30th 1:00am ST
      # avoid setting a time between 1:00 and 2:00 since that requires specifying whether DST is active
      assert_equal 24*3600, Time.local(2005,10,30,0,59,59).seconds_until_end_of_day, 'just before DST end'
      assert_equal 22*3600-2, Time.local(2005,10,30,2,0,1).seconds_until_end_of_day, 'just after DST end'

      # now set a time between 1:00 and 2:00 by specifying whether DST is active
      # uses: Time.local( sec, min, hour, day, month, year, wday, yday, isdst, tz )
      assert_equal 24*3600-30*60-1, Time.local(0,30,1,30,10,2005,0,0,true,ENV['TZ']).seconds_until_end_of_day, 'before DST end'
      assert_equal 23*3600-30*60-1, Time.local(0,30,1,30,10,2005,0,0,false,ENV['TZ']).seconds_until_end_of_day, 'after DST end'
    end

    with_env_tz 'NZ' do
      # st: New Zealand: 2006 March 19th 3:00am DT => March 19th 2:00am ST
      # avoid setting a time between 2:00 and 3:00 since that requires specifying whether DST is active
      assert_equal 23*3600, Time.local(2006,3,19,1,59,59).seconds_until_end_of_day, 'just before DST end'
      assert_equal 21*3600-2, Time.local(2006,3,19,3,0,1).seconds_until_end_of_day, 'just after DST end'

      # now set a time between 2:00 and 3:00 by specifying whether DST is active
      # uses: Time.local( sec, min, hour, day, month, year, wday, yday, isdst, tz )
      assert_equal 23*3600-30*60-1, Time.local(0,30,2,19,3,2006,0,0,true, ENV['TZ']).seconds_until_end_of_day, 'before DST end'
      assert_equal 22*3600-30*60-1, Time.local(0,30,2,19,3,2006,0,0,false,ENV['TZ']).seconds_until_end_of_day, 'after DST end'
    end
  end

  def test_beginning_of_day
    assert_equal Time.local(2005,2,4,0,0,0), Time.local(2005,2,4,10,10,10).beginning_of_day
    with_env_tz 'US/Eastern' do
      assert_equal Time.local(2006,4,2,0,0,0), Time.local(2006,4,2,10,10,10).beginning_of_day, 'start DST'
      assert_equal Time.local(2006,10,29,0,0,0), Time.local(2006,10,29,10,10,10).beginning_of_day, 'ends DST'
    end
    with_env_tz 'NZ' do
      assert_equal Time.local(2006,3,19,0,0,0), Time.local(2006,3,19,10,10,10).beginning_of_day, 'ends DST'
      assert_equal Time.local(2006,10,1,0,0,0), Time.local(2006,10,1,10,10,10).beginning_of_day, 'start DST'
    end
  end

  def test_beginning_of_hour
    assert_equal Time.local(2005,2,4,19,0,0), Time.local(2005,2,4,19,30,10).beginning_of_hour
  end

  def test_end_of_day
    assert_equal Time.local(2007,8,12,23,59,59,Rational(999999999, 1000)), Time.local(2007,8,12,10,10,10).end_of_day
    with_env_tz 'US/Eastern' do
      assert_equal Time.local(2007,4,2,23,59,59,Rational(999999999, 1000)), Time.local(2007,4,2,10,10,10).end_of_day, 'start DST'
      assert_equal Time.local(2007,10,29,23,59,59,Rational(999999999, 1000)), Time.local(2007,10,29,10,10,10).end_of_day, 'ends DST'
    end
    with_env_tz 'NZ' do
      assert_equal Time.local(2006,3,19,23,59,59,Rational(999999999, 1000)), Time.local(2006,3,19,10,10,10).end_of_day, 'ends DST'
      assert_equal Time.local(2006,10,1,23,59,59,Rational(999999999, 1000)), Time.local(2006,10,1,10,10,10).end_of_day, 'start DST'
    end
  end

  def test_end_of_hour
    assert_equal Time.local(2005,2,4,19,59,59,Rational(999999999, 1000)), Time.local(2005,2,4,19,30,10).end_of_hour
  end

  def test_last_year
    assert_equal Time.local(2004,6,5,10),  Time.local(2005,6,5,10,0,0).last_year
  end

  def test_ago
    assert_equal Time.local(2005,2,22,10,10,9),  Time.local(2005,2,22,10,10,10).ago(1)
    assert_equal Time.local(2005,2,22,9,10,10),  Time.local(2005,2,22,10,10,10).ago(3600)
    assert_equal Time.local(2005,2,20,10,10,10), Time.local(2005,2,22,10,10,10).ago(86400*2)
    assert_equal Time.local(2005,2,20,9,9,45),   Time.local(2005,2,22,10,10,10).ago(86400*2 + 3600 + 25)
  end

  def test_daylight_savings_time_crossings_backward_start
    with_env_tz 'US/Eastern' do
      # dt: US: 2005 April 3rd 4:18am
      assert_equal Time.local(2005,4,2,3,18,0), Time.local(2005,4,3,4,18,0).ago(24.hours), 'dt-24.hours=>st'
      assert_equal Time.local(2005,4,2,3,18,0), Time.local(2005,4,3,4,18,0).ago(86400), 'dt-86400=>st'
      assert_equal Time.local(2005,4,2,3,18,0), Time.local(2005,4,3,4,18,0).ago(86400.seconds), 'dt-86400.seconds=>st'

      assert_equal Time.local(2005,4,1,4,18,0), Time.local(2005,4,2,4,18,0).ago(24.hours), 'st-24.hours=>st'
      assert_equal Time.local(2005,4,1,4,18,0), Time.local(2005,4,2,4,18,0).ago(86400), 'st-86400=>st'
      assert_equal Time.local(2005,4,1,4,18,0), Time.local(2005,4,2,4,18,0).ago(86400.seconds), 'st-86400.seconds=>st'
    end
    with_env_tz 'NZ' do
      # dt: New Zealand: 2006 October 1st 4:18am
      assert_equal Time.local(2006,9,30,3,18,0), Time.local(2006,10,1,4,18,0).ago(24.hours), 'dt-24.hours=>st'
      assert_equal Time.local(2006,9,30,3,18,0), Time.local(2006,10,1,4,18,0).ago(86400), 'dt-86400=>st'
      assert_equal Time.local(2006,9,30,3,18,0), Time.local(2006,10,1,4,18,0).ago(86400.seconds), 'dt-86400.seconds=>st'

      assert_equal Time.local(2006,9,29,4,18,0), Time.local(2006,9,30,4,18,0).ago(24.hours), 'st-24.hours=>st'
      assert_equal Time.local(2006,9,29,4,18,0), Time.local(2006,9,30,4,18,0).ago(86400), 'st-86400=>st'
      assert_equal Time.local(2006,9,29,4,18,0), Time.local(2006,9,30,4,18,0).ago(86400.seconds), 'st-86400.seconds=>st'
    end
  end

  def test_daylight_savings_time_crossings_backward_end
    with_env_tz 'US/Eastern' do
      # st: US: 2005 October 30th 4:03am
      assert_equal Time.local(2005,10,29,5,3), Time.local(2005,10,30,4,3,0).ago(24.hours), 'st-24.hours=>dt'
      assert_equal Time.local(2005,10,29,5,3), Time.local(2005,10,30,4,3,0).ago(86400), 'st-86400=>dt'
      assert_equal Time.local(2005,10,29,5,3), Time.local(2005,10,30,4,3,0).ago(86400.seconds), 'st-86400.seconds=>dt'

      assert_equal Time.local(2005,10,28,4,3), Time.local(2005,10,29,4,3,0).ago(24.hours), 'dt-24.hours=>dt'
      assert_equal Time.local(2005,10,28,4,3), Time.local(2005,10,29,4,3,0).ago(86400), 'dt-86400=>dt'
      assert_equal Time.local(2005,10,28,4,3), Time.local(2005,10,29,4,3,0).ago(86400.seconds), 'dt-86400.seconds=>dt'
    end
    with_env_tz 'NZ' do
      # st: New Zealand: 2006 March 19th 4:03am
      assert_equal Time.local(2006,3,18,5,3), Time.local(2006,3,19,4,3,0).ago(24.hours), 'st-24.hours=>dt'
      assert_equal Time.local(2006,3,18,5,3), Time.local(2006,3,19,4,3,0).ago(86400), 'st-86400=>dt'
      assert_equal Time.local(2006,3,18,5,3), Time.local(2006,3,19,4,3,0).ago(86400.seconds), 'st-86400.seconds=>dt'

      assert_equal Time.local(2006,3,17,4,3), Time.local(2006,3,18,4,3,0).ago(24.hours), 'dt-24.hours=>dt'
      assert_equal Time.local(2006,3,17,4,3), Time.local(2006,3,18,4,3,0).ago(86400), 'dt-86400=>dt'
      assert_equal Time.local(2006,3,17,4,3), Time.local(2006,3,18,4,3,0).ago(86400.seconds), 'dt-86400.seconds=>dt'
    end
  end

  def test_daylight_savings_time_crossings_backward_start_1day
    with_env_tz 'US/Eastern' do
      # dt: US: 2005 April 3rd 4:18am
      assert_equal Time.local(2005,4,2,4,18,0), Time.local(2005,4,3,4,18,0).ago(1.day), 'dt-1.day=>st'
      assert_equal Time.local(2005,4,1,4,18,0), Time.local(2005,4,2,4,18,0).ago(1.day), 'st-1.day=>st'
    end
    with_env_tz 'NZ' do
      # dt: New Zealand: 2006 October 1st 4:18am
      assert_equal Time.local(2006,9,30,4,18,0), Time.local(2006,10,1,4,18,0).ago(1.day), 'dt-1.day=>st'
      assert_equal Time.local(2006,9,29,4,18,0), Time.local(2006,9,30,4,18,0).ago(1.day), 'st-1.day=>st'
    end
  end

  def test_daylight_savings_time_crossings_backward_end_1day
    with_env_tz 'US/Eastern' do
      # st: US: 2005 October 30th 4:03am
      assert_equal Time.local(2005,10,29,4,3), Time.local(2005,10,30,4,3,0).ago(1.day), 'st-1.day=>dt'
      assert_equal Time.local(2005,10,28,4,3), Time.local(2005,10,29,4,3,0).ago(1.day), 'dt-1.day=>dt'
    end
    with_env_tz 'NZ' do
      # st: New Zealand: 2006 March 19th 4:03am
      assert_equal Time.local(2006,3,18,4,3), Time.local(2006,3,19,4,3,0).ago(1.day), 'st-1.day=>dt'
      assert_equal Time.local(2006,3,17,4,3), Time.local(2006,3,18,4,3,0).ago(1.day), 'dt-1.day=>dt'
    end
  end

  def test_since
    assert_equal Time.local(2005,2,22,10,10,11), Time.local(2005,2,22,10,10,10).since(1)
    assert_equal Time.local(2005,2,22,11,10,10), Time.local(2005,2,22,10,10,10).since(3600)
    assert_equal Time.local(2005,2,24,10,10,10), Time.local(2005,2,22,10,10,10).since(86400*2)
    assert_equal Time.local(2005,2,24,11,10,35), Time.local(2005,2,22,10,10,10).since(86400*2 + 3600 + 25)
    # when out of range of Time, returns a DateTime
    assert_equal DateTime.civil(2038,1,20,11,59,59), Time.utc(2038,1,18,11,59,59).since(86400*2)
  end

  def test_daylight_savings_time_crossings_forward_start
    with_env_tz 'US/Eastern' do
      # st: US: 2005 April 2nd 7:27pm
      assert_equal Time.local(2005,4,3,20,27,0), Time.local(2005,4,2,19,27,0).since(24.hours), 'st+24.hours=>dt'
      assert_equal Time.local(2005,4,3,20,27,0), Time.local(2005,4,2,19,27,0).since(86400), 'st+86400=>dt'
      assert_equal Time.local(2005,4,3,20,27,0), Time.local(2005,4,2,19,27,0).since(86400.seconds), 'st+86400.seconds=>dt'

      assert_equal Time.local(2005,4,4,19,27,0), Time.local(2005,4,3,19,27,0).since(24.hours), 'dt+24.hours=>dt'
      assert_equal Time.local(2005,4,4,19,27,0), Time.local(2005,4,3,19,27,0).since(86400), 'dt+86400=>dt'
      assert_equal Time.local(2005,4,4,19,27,0), Time.local(2005,4,3,19,27,0).since(86400.seconds), 'dt+86400.seconds=>dt'
    end
    with_env_tz 'NZ' do
      # st: New Zealand: 2006 September 30th 7:27pm
      assert_equal Time.local(2006,10,1,20,27,0), Time.local(2006,9,30,19,27,0).since(24.hours), 'st+24.hours=>dt'
      assert_equal Time.local(2006,10,1,20,27,0), Time.local(2006,9,30,19,27,0).since(86400), 'st+86400=>dt'
      assert_equal Time.local(2006,10,1,20,27,0), Time.local(2006,9,30,19,27,0).since(86400.seconds), 'st+86400.seconds=>dt'

      assert_equal Time.local(2006,10,2,19,27,0), Time.local(2006,10,1,19,27,0).since(24.hours), 'dt+24.hours=>dt'
      assert_equal Time.local(2006,10,2,19,27,0), Time.local(2006,10,1,19,27,0).since(86400), 'dt+86400=>dt'
      assert_equal Time.local(2006,10,2,19,27,0), Time.local(2006,10,1,19,27,0).since(86400.seconds), 'dt+86400.seconds=>dt'
    end
  end

  def test_daylight_savings_time_crossings_forward_start_1day
    with_env_tz 'US/Eastern' do
      # st: US: 2005 April 2nd 7:27pm
      assert_equal Time.local(2005,4,3,19,27,0), Time.local(2005,4,2,19,27,0).since(1.day), 'st+1.day=>dt'
      assert_equal Time.local(2005,4,4,19,27,0), Time.local(2005,4,3,19,27,0).since(1.day), 'dt+1.day=>dt'
    end
    with_env_tz 'NZ' do
      # st: New Zealand: 2006 September 30th 7:27pm
      assert_equal Time.local(2006,10,1,19,27,0), Time.local(2006,9,30,19,27,0).since(1.day), 'st+1.day=>dt'
      assert_equal Time.local(2006,10,2,19,27,0), Time.local(2006,10,1,19,27,0).since(1.day), 'dt+1.day=>dt'
    end
  end

  def test_daylight_savings_time_crossings_forward_start_tomorrow
    with_env_tz 'US/Eastern' do
      # st: US: 2005 April 2nd 7:27pm
      assert_equal Time.local(2005,4,3,19,27,0), Time.local(2005,4,2,19,27,0).tomorrow, 'st+1.day=>dt'
      assert_equal Time.local(2005,4,4,19,27,0), Time.local(2005,4,3,19,27,0).tomorrow, 'dt+1.day=>dt'
    end
    with_env_tz 'NZ' do
      # st: New Zealand: 2006 September 30th 7:27pm
      assert_equal Time.local(2006,10,1,19,27,0), Time.local(2006,9,30,19,27,0).tomorrow, 'st+1.day=>dt'
      assert_equal Time.local(2006,10,2,19,27,0), Time.local(2006,10,1,19,27,0).tomorrow, 'dt+1.day=>dt'
    end
  end

  def test_daylight_savings_time_crossings_backward_start_yesterday
    with_env_tz 'US/Eastern' do
      # st: US: 2005 April 2nd 7:27pm
      assert_equal Time.local(2005,4,2,19,27,0), Time.local(2005,4,3,19,27,0).yesterday, 'dt-1.day=>st'
      assert_equal Time.local(2005,4,3,19,27,0), Time.local(2005,4,4,19,27,0).yesterday, 'dt-1.day=>dt'
    end
    with_env_tz 'NZ' do
      # st: New Zealand: 2006 September 30th 7:27pm
      assert_equal Time.local(2006,9,30,19,27,0), Time.local(2006,10,1,19,27,0).yesterday, 'dt-1.day=>st'
      assert_equal Time.local(2006,10,1,19,27,0), Time.local(2006,10,2,19,27,0).yesterday, 'dt-1.day=>dt'
    end
  end

  def test_daylight_savings_time_crossings_forward_end
    with_env_tz 'US/Eastern' do
      # dt: US: 2005 October 30th 12:45am
      assert_equal Time.local(2005,10,30,23,45,0), Time.local(2005,10,30,0,45,0).since(24.hours), 'dt+24.hours=>st'
      assert_equal Time.local(2005,10,30,23,45,0), Time.local(2005,10,30,0,45,0).since(86400), 'dt+86400=>st'
      assert_equal Time.local(2005,10,30,23,45,0), Time.local(2005,10,30,0,45,0).since(86400.seconds), 'dt+86400.seconds=>st'

      assert_equal Time.local(2005,11, 1,0,45,0), Time.local(2005,10,31,0,45,0).since(24.hours), 'st+24.hours=>st'
      assert_equal Time.local(2005,11, 1,0,45,0), Time.local(2005,10,31,0,45,0).since(86400), 'st+86400=>st'
      assert_equal Time.local(2005,11, 1,0,45,0), Time.local(2005,10,31,0,45,0).since(86400.seconds), 'st+86400.seconds=>st'
    end
    with_env_tz 'NZ' do
      # dt: New Zealand: 2006 March 19th 1:45am
      assert_equal Time.local(2006,3,20,0,45,0), Time.local(2006,3,19,1,45,0).since(24.hours), 'dt+24.hours=>st'
      assert_equal Time.local(2006,3,20,0,45,0), Time.local(2006,3,19,1,45,0).since(86400), 'dt+86400=>st'
      assert_equal Time.local(2006,3,20,0,45,0), Time.local(2006,3,19,1,45,0).since(86400.seconds), 'dt+86400.seconds=>st'

      assert_equal Time.local(2006,3,21,1,45,0), Time.local(2006,3,20,1,45,0).since(24.hours), 'st+24.hours=>st'
      assert_equal Time.local(2006,3,21,1,45,0), Time.local(2006,3,20,1,45,0).since(86400), 'st+86400=>st'
      assert_equal Time.local(2006,3,21,1,45,0), Time.local(2006,3,20,1,45,0).since(86400.seconds), 'st+86400.seconds=>st'
    end
  end

  def test_daylight_savings_time_crossings_forward_end_1day
    with_env_tz 'US/Eastern' do
      # dt: US: 2005 October 30th 12:45am
      assert_equal Time.local(2005,10,31,0,45,0), Time.local(2005,10,30,0,45,0).since(1.day), 'dt+1.day=>st'
      assert_equal Time.local(2005,11, 1,0,45,0), Time.local(2005,10,31,0,45,0).since(1.day), 'st+1.day=>st'
    end
    with_env_tz 'NZ' do
      # dt: New Zealand: 2006 March 19th 1:45am
      assert_equal Time.local(2006,3,20,1,45,0), Time.local(2006,3,19,1,45,0).since(1.day), 'dt+1.day=>st'
      assert_equal Time.local(2006,3,21,1,45,0), Time.local(2006,3,20,1,45,0).since(1.day), 'st+1.day=>st'
    end
  end

  def test_daylight_savings_time_crossings_forward_end_tomorrow
    with_env_tz 'US/Eastern' do
      # dt: US: 2005 October 30th 12:45am
      assert_equal Time.local(2005,10,31,0,45,0), Time.local(2005,10,30,0,45,0).tomorrow, 'dt+1.day=>st'
      assert_equal Time.local(2005,11, 1,0,45,0), Time.local(2005,10,31,0,45,0).tomorrow, 'st+1.day=>st'
    end
    with_env_tz 'NZ' do
      # dt: New Zealand: 2006 March 19th 1:45am
      assert_equal Time.local(2006,3,20,1,45,0), Time.local(2006,3,19,1,45,0).tomorrow, 'dt+1.day=>st'
      assert_equal Time.local(2006,3,21,1,45,0), Time.local(2006,3,20,1,45,0).tomorrow, 'st+1.day=>st'
    end
  end

  def test_daylight_savings_time_crossings_backward_end_yesterday
    with_env_tz 'US/Eastern' do
      # dt: US: 2005 October 30th 12:45am
      assert_equal Time.local(2005,10,30,0,45,0), Time.local(2005,10,31,0,45,0).yesterday, 'st-1.day=>dt'
      assert_equal Time.local(2005,10, 31,0,45,0), Time.local(2005,11,1,0,45,0).yesterday, 'st-1.day=>st'
    end
    with_env_tz 'NZ' do
      # dt: New Zealand: 2006 March 19th 1:45am
      assert_equal Time.local(2006,3,19,1,45,0), Time.local(2006,3,20,1,45,0).yesterday, 'st-1.day=>dt'
      assert_equal Time.local(2006,3,20,1,45,0), Time.local(2006,3,21,1,45,0).yesterday, 'st-1.day=>st'
    end
  end

  def test_change
    assert_equal Time.local(2006,2,22,15,15,10), Time.local(2005,2,22,15,15,10).change(:year => 2006)
    assert_equal Time.local(2005,6,22,15,15,10), Time.local(2005,2,22,15,15,10).change(:month => 6)
    assert_equal Time.local(2012,9,22,15,15,10), Time.local(2005,2,22,15,15,10).change(:year => 2012, :month => 9)
    assert_equal Time.local(2005,2,22,16),       Time.local(2005,2,22,15,15,10).change(:hour => 16)
    assert_equal Time.local(2005,2,22,16,45),    Time.local(2005,2,22,15,15,10).change(:hour => 16, :min => 45)
    assert_equal Time.local(2005,2,22,15,45),    Time.local(2005,2,22,15,15,10).change(:min => 45)

    assert_equal Time.local(2005,1,2, 5, 0, 0, 0), Time.local(2005,1,2,11,22,33,44).change(:hour => 5)
    assert_equal Time.local(2005,1,2,11, 6, 0, 0), Time.local(2005,1,2,11,22,33,44).change(:min  => 6)
    assert_equal Time.local(2005,1,2,11,22, 7, 0), Time.local(2005,1,2,11,22,33,44).change(:sec  => 7)
    assert_equal Time.local(2005,1,2,11,22,33, 8), Time.local(2005,1,2,11,22,33,44).change(:usec => 8)
  end

  def test_utc_change
    assert_equal Time.utc(2006,2,22,15,15,10), Time.utc(2005,2,22,15,15,10).change(:year => 2006)
    assert_equal Time.utc(2005,6,22,15,15,10), Time.utc(2005,2,22,15,15,10).change(:month => 6)
    assert_equal Time.utc(2012,9,22,15,15,10), Time.utc(2005,2,22,15,15,10).change(:year => 2012, :month => 9)
    assert_equal Time.utc(2005,2,22,16),       Time.utc(2005,2,22,15,15,10).change(:hour => 16)
    assert_equal Time.utc(2005,2,22,16,45),    Time.utc(2005,2,22,15,15,10).change(:hour => 16, :min => 45)
    assert_equal Time.utc(2005,2,22,15,45),    Time.utc(2005,2,22,15,15,10).change(:min => 45)
  end

  def test_offset_change
    assert_equal Time.new(2006,2,22,15,15,10,"-08:00"), Time.new(2005,2,22,15,15,10,"-08:00").change(:year => 2006)
    assert_equal Time.new(2005,6,22,15,15,10,"-08:00"), Time.new(2005,2,22,15,15,10,"-08:00").change(:month => 6)
    assert_equal Time.new(2012,9,22,15,15,10,"-08:00"), Time.new(2005,2,22,15,15,10,"-08:00").change(:year => 2012, :month => 9)
    assert_equal Time.new(2005,2,22,16,0,0,"-08:00"),   Time.new(2005,2,22,15,15,10,"-08:00").change(:hour => 16)
    assert_equal Time.new(2005,2,22,16,45,0,"-08:00"),  Time.new(2005,2,22,15,15,10,"-08:00").change(:hour => 16, :min => 45)
    assert_equal Time.new(2005,2,22,15,45,0,"-08:00"),  Time.new(2005,2,22,15,15,10,"-08:00").change(:min => 45)
  end

  def test_advance
    assert_equal Time.local(2006,2,28,15,15,10), Time.local(2005,2,28,15,15,10).advance(:years => 1)
    assert_equal Time.local(2005,6,28,15,15,10), Time.local(2005,2,28,15,15,10).advance(:months => 4)
    assert_equal Time.local(2005,3,21,15,15,10), Time.local(2005,2,28,15,15,10).advance(:weeks => 3)
    assert_equal Time.local(2005,3,25,3,15,10), Time.local(2005,2,28,15,15,10).advance(:weeks => 3.5)
    assert_in_delta Time.local(2005,3,26,12,51,10), Time.local(2005,2,28,15,15,10).advance(:weeks => 3.7), 1
    assert_equal Time.local(2005,3,5,15,15,10), Time.local(2005,2,28,15,15,10).advance(:days => 5)
    assert_equal Time.local(2005,3,6,3,15,10), Time.local(2005,2,28,15,15,10).advance(:days => 5.5)
    assert_in_delta Time.local(2005,3,6,8,3,10), Time.local(2005,2,28,15,15,10).advance(:days => 5.7), 1
    assert_equal Time.local(2012,9,28,15,15,10), Time.local(2005,2,28,15,15,10).advance(:years => 7, :months => 7)
    assert_equal Time.local(2013,10,3,15,15,10), Time.local(2005,2,28,15,15,10).advance(:years => 7, :months => 19, :days => 5)
    assert_equal Time.local(2013,10,17,15,15,10), Time.local(2005,2,28,15,15,10).advance(:years => 7, :months => 19, :weeks => 2, :days => 5)
    assert_equal Time.local(2001,12,27,15,15,10), Time.local(2005,2,28,15,15,10).advance(:years => -3, :months => -2, :days => -1)
    assert_equal Time.local(2005,2,28,15,15,10), Time.local(2004,2,29,15,15,10).advance(:years => 1) #leap day plus one year
    assert_equal Time.local(2005,2,28,20,15,10), Time.local(2005,2,28,15,15,10).advance(:hours => 5)
    assert_equal Time.local(2005,2,28,15,22,10), Time.local(2005,2,28,15,15,10).advance(:minutes => 7)
    assert_equal Time.local(2005,2,28,15,15,19), Time.local(2005,2,28,15,15,10).advance(:seconds => 9)
    assert_equal Time.local(2005,2,28,20,22,19), Time.local(2005,2,28,15,15,10).advance(:hours => 5, :minutes => 7, :seconds => 9)
    assert_equal Time.local(2005,2,28,10,8,1), Time.local(2005,2,28,15,15,10).advance(:hours => -5, :minutes => -7, :seconds => -9)
    assert_equal Time.local(2013,10,17,20,22,19), Time.local(2005,2,28,15,15,10).advance(:years => 7, :months => 19, :weeks => 2, :days => 5, :hours => 5, :minutes => 7, :seconds => 9)
  end

  def test_utc_advance
    assert_equal Time.utc(2006,2,22,15,15,10), Time.utc(2005,2,22,15,15,10).advance(:years => 1)
    assert_equal Time.utc(2005,6,22,15,15,10), Time.utc(2005,2,22,15,15,10).advance(:months => 4)
    assert_equal Time.utc(2005,3,21,15,15,10), Time.utc(2005,2,28,15,15,10).advance(:weeks => 3)
    assert_equal Time.utc(2005,3,25,3,15,10), Time.utc(2005,2,28,15,15,10).advance(:weeks => 3.5)
    assert_in_delta Time.utc(2005,3,26,12,51,10), Time.utc(2005,2,28,15,15,10).advance(:weeks => 3.7), 1
    assert_equal Time.utc(2005,3,5,15,15,10), Time.utc(2005,2,28,15,15,10).advance(:days => 5)
    assert_equal Time.utc(2005,3,6,3,15,10), Time.utc(2005,2,28,15,15,10).advance(:days => 5.5)
    assert_in_delta Time.utc(2005,3,6,8,3,10), Time.utc(2005,2,28,15,15,10).advance(:days => 5.7), 1
    assert_equal Time.utc(2012,9,22,15,15,10), Time.utc(2005,2,22,15,15,10).advance(:years => 7, :months => 7)
    assert_equal Time.utc(2013,10,3,15,15,10), Time.utc(2005,2,22,15,15,10).advance(:years => 7, :months => 19, :days => 11)
    assert_equal Time.utc(2013,10,17,15,15,10), Time.utc(2005,2,28,15,15,10).advance(:years => 7, :months => 19, :weeks => 2, :days => 5)
    assert_equal Time.utc(2001,12,27,15,15,10), Time.utc(2005,2,28,15,15,10).advance(:years => -3, :months => -2, :days => -1)
    assert_equal Time.utc(2005,2,28,15,15,10), Time.utc(2004,2,29,15,15,10).advance(:years => 1) #leap day plus one year
    assert_equal Time.utc(2005,2,28,20,15,10), Time.utc(2005,2,28,15,15,10).advance(:hours => 5)
    assert_equal Time.utc(2005,2,28,15,22,10), Time.utc(2005,2,28,15,15,10).advance(:minutes => 7)
    assert_equal Time.utc(2005,2,28,15,15,19), Time.utc(2005,2,28,15,15,10).advance(:seconds => 9)
    assert_equal Time.utc(2005,2,28,20,22,19), Time.utc(2005,2,28,15,15,10).advance(:hours => 5, :minutes => 7, :seconds => 9)
    assert_equal Time.utc(2005,2,28,10,8,1), Time.utc(2005,2,28,15,15,10).advance(:hours => -5, :minutes => -7, :seconds => -9)
    assert_equal Time.utc(2013,10,17,20,22,19), Time.utc(2005,2,28,15,15,10).advance(:years => 7, :months => 19, :weeks => 2, :days => 5, :hours => 5, :minutes => 7, :seconds => 9)
  end

  def test_offset_advance
    assert_equal Time.new(2006,2,22,15,15,10,'-08:00'), Time.new(2005,2,22,15,15,10,'-08:00').advance(:years => 1)
    assert_equal Time.new(2005,6,22,15,15,10,'-08:00'), Time.new(2005,2,22,15,15,10,'-08:00').advance(:months => 4)
    assert_equal Time.new(2005,3,21,15,15,10,'-08:00'), Time.new(2005,2,28,15,15,10,'-08:00').advance(:weeks => 3)
    assert_equal Time.new(2005,3,25,3,15,10,'-08:00'), Time.new(2005,2,28,15,15,10,'-08:00').advance(:weeks => 3.5)
    assert_in_delta Time.new(2005,3,26,12,51,10,'-08:00'), Time.new(2005,2,28,15,15,10,'-08:00').advance(:weeks => 3.7), 1
    assert_equal Time.new(2005,3,5,15,15,10,'-08:00'), Time.new(2005,2,28,15,15,10,'-08:00').advance(:days => 5)
    assert_equal Time.new(2005,3,6,3,15,10,'-08:00'), Time.new(2005,2,28,15,15,10,'-08:00').advance(:days => 5.5)
    assert_in_delta Time.new(2005,3,6,8,3,10,'-08:00'), Time.new(2005,2,28,15,15,10,'-08:00').advance(:days => 5.7), 1
    assert_equal Time.new(2012,9,22,15,15,10,'-08:00'), Time.new(2005,2,22,15,15,10,'-08:00').advance(:years => 7, :months => 7)
    assert_equal Time.new(2013,10,3,15,15,10,'-08:00'), Time.new(2005,2,22,15,15,10,'-08:00').advance(:years => 7, :months => 19, :days => 11)
    assert_equal Time.new(2013,10,17,15,15,10,'-08:00'), Time.new(2005,2,28,15,15,10,'-08:00').advance(:years => 7, :months => 19, :weeks => 2, :days => 5)
    assert_equal Time.new(2001,12,27,15,15,10,'-08:00'), Time.new(2005,2,28,15,15,10,'-08:00').advance(:years => -3, :months => -2, :days => -1)
    assert_equal Time.new(2005,2,28,15,15,10,'-08:00'), Time.new(2004,2,29,15,15,10,'-08:00').advance(:years => 1) #leap day plus one year
    assert_equal Time.new(2005,2,28,20,15,10,'-08:00'), Time.new(2005,2,28,15,15,10,'-08:00').advance(:hours => 5)
    assert_equal Time.new(2005,2,28,15,22,10,'-08:00'), Time.new(2005,2,28,15,15,10,'-08:00').advance(:minutes => 7)
    assert_equal Time.new(2005,2,28,15,15,19,'-08:00'), Time.new(2005,2,28,15,15,10,'-08:00').advance(:seconds => 9)
    assert_equal Time.new(2005,2,28,20,22,19,'-08:00'), Time.new(2005,2,28,15,15,10,'-08:00').advance(:hours => 5, :minutes => 7, :seconds => 9)
    assert_equal Time.new(2005,2,28,10,8,1,'-08:00'), Time.new(2005,2,28,15,15,10,'-08:00').advance(:hours => -5, :minutes => -7, :seconds => -9)
    assert_equal Time.new(2013,10,17,20,22,19,'-08:00'), Time.new(2005,2,28,15,15,10,'-08:00').advance(:years => 7, :months => 19, :weeks => 2, :days => 5, :hours => 5, :minutes => 7, :seconds => 9)
  end

  def test_advance_with_nsec
    t = Time.at(0, Rational(108635108, 1000))
    assert_equal t, t.advance(:months => 0)
  end

  def test_last_week
    with_env_tz 'US/Eastern' do
      assert_equal Time.local(2005,2,21), Time.local(2005,3,1,15,15,10).last_week
      assert_equal Time.local(2005,2,22), Time.local(2005,3,1,15,15,10).last_week(:tuesday)
      assert_equal Time.local(2005,2,25), Time.local(2005,3,1,15,15,10).last_week(:friday)
      assert_equal Time.local(2006,10,30), Time.local(2006,11,6,0,0,0).last_week
      assert_equal Time.local(2006,11,15), Time.local(2006,11,23,0,0,0).last_week(:wednesday)
    end
  end

  def test_next_week_near_daylight_start
    with_env_tz 'US/Eastern' do
      assert_equal Time.local(2006,4,3), Time.local(2006,4,2,23,1,0).next_week, 'just crossed standard => daylight'
    end
    with_env_tz 'NZ' do
      assert_equal Time.local(2006,10,2), Time.local(2006,10,1,23,1,0).next_week, 'just crossed standard => daylight'
    end
  end

  def test_next_week_near_daylight_end
    with_env_tz 'US/Eastern' do
      assert_equal Time.local(2006,10,30), Time.local(2006,10,29,23,1,0).next_week, 'just crossed daylight => standard'
    end
    with_env_tz 'NZ' do
      assert_equal Time.local(2006,3,20), Time.local(2006,3,19,23,1,0).next_week, 'just crossed daylight => standard'
    end
  end

  def test_to_s
    time = Time.utc(2005, 2, 21, 17, 44, 30.12345678901)
    assert_equal time.to_default_s,                 time.to_s
    assert_equal time.to_default_s,                 time.to_s(:doesnt_exist)
    assert_equal "2005-02-21 17:44:30",             time.to_s(:db)
    assert_equal "21 Feb 17:44",                    time.to_s(:short)
    assert_equal "17:44",                           time.to_s(:time)
    assert_equal "20050221174430",                  time.to_s(:number)
    assert_equal "20050221174430123456789",         time.to_s(:nsec)
    assert_equal "February 21, 2005 17:44",         time.to_s(:long)
    assert_equal "February 21st, 2005 17:44",       time.to_s(:long_ordinal)
    with_env_tz "UTC" do
      assert_equal "Mon, 21 Feb 2005 17:44:30 +0000", time.to_s(:rfc822)
    end
    with_env_tz "US/Central" do
      assert_equal "Thu, 05 Feb 2009 14:30:05 -0600", Time.local(2009, 2, 5, 14, 30, 5).to_s(:rfc822)
      assert_equal "Mon, 09 Jun 2008 04:05:01 -0500", Time.local(2008, 6, 9, 4, 5, 1).to_s(:rfc822)
    end
  end

  def test_custom_date_format
    Time::DATE_FORMATS[:custom] = '%Y%m%d%H%M%S'
    assert_equal '20050221143000', Time.local(2005, 2, 21, 14, 30, 0).to_s(:custom)
    Time::DATE_FORMATS.delete(:custom)
  end

  def test_to_date
    assert_equal Date.new(2005, 2, 21), Time.local(2005, 2, 21, 17, 44, 30).to_date
  end

  def test_to_datetime
    assert_equal Time.utc(2005, 2, 21, 17, 44, 30).to_datetime, DateTime.civil(2005, 2, 21, 17, 44, 30, 0)
    with_env_tz 'US/Eastern' do
      assert_equal Time.local(2005, 2, 21, 17, 44, 30).to_datetime, DateTime.civil(2005, 2, 21, 17, 44, 30, Rational(Time.local(2005, 2, 21, 17, 44, 30).utc_offset, 86400))
    end
    with_env_tz 'NZ' do
      assert_equal Time.local(2005, 2, 21, 17, 44, 30).to_datetime, DateTime.civil(2005, 2, 21, 17, 44, 30, Rational(Time.local(2005, 2, 21, 17, 44, 30).utc_offset, 86400))
    end
    assert_equal ::Date::ITALY, Time.utc(2005, 2, 21, 17, 44, 30).to_datetime.start # use Ruby's default start value
  end

  def test_to_time
    assert_equal Time.local(2005, 2, 21, 17, 44, 30), Time.local(2005, 2, 21, 17, 44, 30).to_time
  end

  # NOTE: this test seems to fail (changeset 1958) only on certain platforms,
  # like OSX, and FreeBSD 5.4.
  def test_fp_inaccuracy_ticket_1836
    midnight = Time.local(2005, 2, 21, 0, 0, 0)
    assert_equal midnight.midnight, (midnight + 1.hour + 0.000001).midnight
  end

  def test_days_in_month_with_year
    assert_equal 31, Time.days_in_month(1, 2005)

    assert_equal 28, Time.days_in_month(2, 2005)
    assert_equal 29, Time.days_in_month(2, 2004)
    assert_equal 29, Time.days_in_month(2, 2000)
    assert_equal 28, Time.days_in_month(2, 1900)

    assert_equal 31, Time.days_in_month(3, 2005)
    assert_equal 30, Time.days_in_month(4, 2005)
    assert_equal 31, Time.days_in_month(5, 2005)
    assert_equal 30, Time.days_in_month(6, 2005)
    assert_equal 31, Time.days_in_month(7, 2005)
    assert_equal 31, Time.days_in_month(8, 2005)
    assert_equal 30, Time.days_in_month(9, 2005)
    assert_equal 31, Time.days_in_month(10, 2005)
    assert_equal 30, Time.days_in_month(11, 2005)
    assert_equal 31, Time.days_in_month(12, 2005)
  end

  def test_days_in_month_feb_in_common_year_without_year_arg
    Time.stubs(:now).returns(Time.utc(2007))
    assert_equal 28, Time.days_in_month(2)
  end

  def test_days_in_month_feb_in_leap_year_without_year_arg
    Time.stubs(:now).returns(Time.utc(2008))
    assert_equal 29, Time.days_in_month(2)
  end

  def test_time_with_datetime_fallback
    assert_equal Time.time_with_datetime_fallback(:utc, 2005, 2, 21, 17, 44, 30), Time.utc(2005, 2, 21, 17, 44, 30)
    assert_equal Time.time_with_datetime_fallback(:local, 2005, 2, 21, 17, 44, 30), Time.local(2005, 2, 21, 17, 44, 30)
    assert_equal Time.time_with_datetime_fallback(:utc, 2039, 2, 21, 17, 44, 30), DateTime.civil(2039, 2, 21, 17, 44, 30, 0)
    assert_equal Time.time_with_datetime_fallback(:local, 2039, 2, 21, 17, 44, 30), DateTime.civil_from_format(:local, 2039, 2, 21, 17, 44, 30)
    assert_equal Time.time_with_datetime_fallback(:utc, 1900, 2, 21, 17, 44, 30), DateTime.civil(1900, 2, 21, 17, 44, 30, 0)
    assert_equal Time.time_with_datetime_fallback(:utc, 2005), Time.utc(2005)
    assert_equal Time.time_with_datetime_fallback(:utc, 2039), DateTime.civil(2039, 1, 1, 0, 0, 0, 0)
    assert_equal Time.time_with_datetime_fallback(:utc, 2005, 2, 21, 17, 44, 30, 1), Time.utc(2005, 2, 21, 17, 44, 30, 1) #with usec
    # This won't overflow on 64bit linux
    unless time_is_64bits?
      assert_equal Time.time_with_datetime_fallback(:local, 1900, 2, 21, 17, 44, 30), DateTime.civil_from_format(:local, 1900, 2, 21, 17, 44, 30)
      assert_equal Time.time_with_datetime_fallback(:utc, 2039, 2, 21, 17, 44, 30, 1),
                   DateTime.civil(2039, 2, 21, 17, 44, 30, 0, 0)
      assert_equal ::Date::ITALY, Time.time_with_datetime_fallback(:utc, 2039, 2, 21, 17, 44, 30, 1).start # use Ruby's default start value
    end
    silence_warnings do
      0.upto(138) do |year|
        [:utc, :local].each do |format|
          assert_equal year, Time.time_with_datetime_fallback(format, year).year
        end
      end
    end
  end

  def test_utc_time
    assert_equal Time.utc_time(2005, 2, 21, 17, 44, 30), Time.utc(2005, 2, 21, 17, 44, 30)
    assert_equal Time.utc_time(2039, 2, 21, 17, 44, 30), DateTime.civil(2039, 2, 21, 17, 44, 30, 0)
    assert_equal Time.utc_time(1901, 2, 21, 17, 44, 30), DateTime.civil(1901, 2, 21, 17, 44, 30, 0)
  end

  def test_local_time
    assert_equal Time.local_time(2005, 2, 21, 17, 44, 30), Time.local(2005, 2, 21, 17, 44, 30)
    assert_equal Time.local_time(2039, 2, 21, 17, 44, 30), DateTime.civil_from_format(:local, 2039, 2, 21, 17, 44, 30)

    unless time_is_64bits?
      assert_equal Time.local_time(1901, 2, 21, 17, 44, 30), DateTime.civil_from_format(:local, 1901, 2, 21, 17, 44, 30)
    end
  end

  def test_last_month_on_31st
    assert_equal Time.local(2004, 2, 29), Time.local(2004, 3, 31).last_month
  end

  def test_xmlschema_is_available
    assert_nothing_raised { Time.now.xmlschema }
  end

  def test_today_with_time_local
    Date.stubs(:current).returns(Date.new(2000, 1, 1))
    assert_equal false, Time.local(1999,12,31,23,59,59).today?
    assert_equal true,  Time.local(2000,1,1,0).today?
    assert_equal true,  Time.local(2000,1,1,23,59,59).today?
    assert_equal false, Time.local(2000,1,2,0).today?
  end

  def test_today_with_time_utc
    Date.stubs(:current).returns(Date.new(2000, 1, 1))
    assert_equal false, Time.utc(1999,12,31,23,59,59).today?
    assert_equal true,  Time.utc(2000,1,1,0).today?
    assert_equal true,  Time.utc(2000,1,1,23,59,59).today?
    assert_equal false, Time.utc(2000,1,2,0).today?
  end

  def test_past_with_time_current_as_time_local
    with_env_tz 'US/Eastern' do
      Time.stubs(:current).returns(Time.local(2005,2,10,15,30,45))
      assert_equal true,  Time.local(2005,2,10,15,30,44).past?
      assert_equal false,  Time.local(2005,2,10,15,30,45).past?
      assert_equal false,  Time.local(2005,2,10,15,30,46).past?
      assert_equal true,  Time.utc(2005,2,10,20,30,44).past?
      assert_equal false,  Time.utc(2005,2,10,20,30,45).past?
      assert_equal false,  Time.utc(2005,2,10,20,30,46).past?
    end
  end

  def test_past_with_time_current_as_time_with_zone
    with_env_tz 'US/Eastern' do
      twz = Time.utc(2005,2,10,15,30,45).in_time_zone('Central Time (US & Canada)')
      Time.stubs(:current).returns(twz)
      assert_equal true,  Time.local(2005,2,10,10,30,44).past?
      assert_equal false,  Time.local(2005,2,10,10,30,45).past?
      assert_equal false,  Time.local(2005,2,10,10,30,46).past?
      assert_equal true,  Time.utc(2005,2,10,15,30,44).past?
      assert_equal false,  Time.utc(2005,2,10,15,30,45).past?
      assert_equal false,  Time.utc(2005,2,10,15,30,46).past?
    end
  end

  def test_future_with_time_current_as_time_local
    with_env_tz 'US/Eastern' do
      Time.stubs(:current).returns(Time.local(2005,2,10,15,30,45))
      assert_equal false,  Time.local(2005,2,10,15,30,44).future?
      assert_equal false,  Time.local(2005,2,10,15,30,45).future?
      assert_equal true,  Time.local(2005,2,10,15,30,46).future?
      assert_equal false,  Time.utc(2005,2,10,20,30,44).future?
      assert_equal false,  Time.utc(2005,2,10,20,30,45).future?
      assert_equal true,  Time.utc(2005,2,10,20,30,46).future?
    end
  end

  def test_future_with_time_current_as_time_with_zone
    with_env_tz 'US/Eastern' do
      twz = Time.utc(2005,2,10,15,30,45).in_time_zone('Central Time (US & Canada)')
      Time.stubs(:current).returns(twz)
      assert_equal false,  Time.local(2005,2,10,10,30,44).future?
      assert_equal false,  Time.local(2005,2,10,10,30,45).future?
      assert_equal true,  Time.local(2005,2,10,10,30,46).future?
      assert_equal false,  Time.utc(2005,2,10,15,30,44).future?
      assert_equal false,  Time.utc(2005,2,10,15,30,45).future?
      assert_equal true,  Time.utc(2005,2,10,15,30,46).future?
    end
  end

  def test_acts_like_time
    assert Time.new.acts_like_time?
  end

  def test_formatted_offset_with_utc
    assert_equal '+00:00', Time.utc(2000).formatted_offset
    assert_equal '+0000', Time.utc(2000).formatted_offset(false)
    assert_equal 'UTC', Time.utc(2000).formatted_offset(true, 'UTC')
  end

  def test_formatted_offset_with_local
    with_env_tz 'US/Eastern' do
      assert_equal '-05:00', Time.local(2000).formatted_offset
      assert_equal '-0500', Time.local(2000).formatted_offset(false)
      assert_equal '-04:00', Time.local(2000, 7).formatted_offset
      assert_equal '-0400', Time.local(2000, 7).formatted_offset(false)
    end
  end

  def test_compare_with_time
    assert_equal  1, Time.utc(2000) <=> Time.utc(1999, 12, 31, 23, 59, 59, 999)
    assert_equal  0, Time.utc(2000) <=> Time.utc(2000, 1, 1, 0, 0, 0)
    assert_equal(-1, Time.utc(2000) <=> Time.utc(2000, 1, 1, 0, 0, 0, 001))
  end

  def test_compare_with_datetime
    assert_equal  1, Time.utc(2000) <=> DateTime.civil(1999, 12, 31, 23, 59, 59)
    assert_equal  0, Time.utc(2000) <=> DateTime.civil(2000, 1, 1, 0, 0, 0)
    assert_equal(-1, Time.utc(2000) <=> DateTime.civil(2000, 1, 1, 0, 0, 1))
  end

  def test_compare_with_time_with_zone
    assert_equal  1, Time.utc(2000) <=> ActiveSupport::TimeWithZone.new( Time.utc(1999, 12, 31, 23, 59, 59), ActiveSupport::TimeZone['UTC'] )
    assert_equal  0, Time.utc(2000) <=> ActiveSupport::TimeWithZone.new( Time.utc(2000, 1, 1, 0, 0, 0), ActiveSupport::TimeZone['UTC'] )
    assert_equal(-1, Time.utc(2000) <=> ActiveSupport::TimeWithZone.new( Time.utc(2000, 1, 1, 0, 0, 1), ActiveSupport::TimeZone['UTC'] ))
  end

  def test_eql?
    assert_equal true, Time.utc(2000).eql?( ActiveSupport::TimeWithZone.new(Time.utc(2000), ActiveSupport::TimeZone['UTC']) )
    assert_equal true, Time.utc(2000).eql?( ActiveSupport::TimeWithZone.new(Time.utc(2000), ActiveSupport::TimeZone["Hawaii"]) )
    assert_equal false,Time.utc(2000, 1, 1, 0, 0, 1).eql?( ActiveSupport::TimeWithZone.new(Time.utc(2000), ActiveSupport::TimeZone['UTC']) )
  end

  def test_minus_with_time_with_zone
    assert_equal  86_400.0, Time.utc(2000, 1, 2) - ActiveSupport::TimeWithZone.new( Time.utc(2000, 1, 1), ActiveSupport::TimeZone['UTC'] )
  end

  def test_minus_with_datetime
    assert_equal  86_400.0, Time.utc(2000, 1, 2) - DateTime.civil(2000, 1, 1)
  end

  def test_time_created_with_local_constructor_cannot_represent_times_during_hour_skipped_by_dst
    with_env_tz 'US/Eastern' do
      # On Apr 2 2006 at 2:00AM in US, clocks were moved forward to 3:00AM.
      # Therefore, 2AM EST doesn't exist for this date; Time.local fails over to 3:00AM EDT
      assert_equal Time.local(2006, 4, 2, 3), Time.local(2006, 4, 2, 2)
      assert Time.local(2006, 4, 2, 2).dst?
    end
  end

  def test_case_equality
    assert Time === Time.utc(2000)
    assert Time === ActiveSupport::TimeWithZone.new(Time.utc(2000), ActiveSupport::TimeZone['UTC'])
    assert Time === Class.new(Time).utc(2000)
    assert_equal false, Time === DateTime.civil(2000)
    assert_equal false, Class.new(Time) === Time.utc(2000)
    assert_equal false, Class.new(Time) === ActiveSupport::TimeWithZone.new(Time.utc(2000), ActiveSupport::TimeZone['UTC'])
  end

  def test_all_day
    assert_equal Time.local(2011,6,7,0,0,0)..Time.local(2011,6,7,23,59,59,Rational(999999999, 1000)), Time.local(2011,6,7,10,10,10).all_day
  end

  def test_all_day_with_timezone
    beginning_of_day = ActiveSupport::TimeWithZone.new(nil, ActiveSupport::TimeZone["Hawaii"], Time.local(2011,6,7,0,0,0))
    end_of_day = ActiveSupport::TimeWithZone.new(nil, ActiveSupport::TimeZone["Hawaii"], Time.local(2011,6,7,23,59,59,Rational(999999999, 1000)))

    assert_equal beginning_of_day, ActiveSupport::TimeWithZone.new(Time.local(2011,6,7,10,10,10), ActiveSupport::TimeZone["Hawaii"]).all_day.begin
    assert_equal end_of_day, ActiveSupport::TimeWithZone.new(Time.local(2011,6,7,10,10,10), ActiveSupport::TimeZone["Hawaii"]).all_day.end
  end

  def test_all_week
    assert_equal Time.local(2011,6,6,0,0,0)..Time.local(2011,6,12,23,59,59,Rational(999999999, 1000)), Time.local(2011,6,7,10,10,10).all_week
    assert_equal Time.local(2011,6,5,0,0,0)..Time.local(2011,6,11,23,59,59,Rational(999999999, 1000)), Time.local(2011,6,7,10,10,10).all_week(:sunday)
  end

  def test_all_month
    assert_equal Time.local(2011,6,1,0,0,0)..Time.local(2011,6,30,23,59,59,Rational(999999999, 1000)), Time.local(2011,6,7,10,10,10).all_month
  end

  def test_all_quarter
    assert_equal Time.local(2011,4,1,0,0,0)..Time.local(2011,6,30,23,59,59,Rational(999999999, 1000)), Time.local(2011,6,7,10,10,10).all_quarter
  end

  def test_all_year
    assert_equal Time.local(2011,1,1,0,0,0)..Time.local(2011,12,31,23,59,59,Rational(999999999, 1000)), Time.local(2011,6,7,10,10,10).all_year
  end

  protected
    def with_env_tz(new_tz = 'US/Eastern')
      old_tz, ENV['TZ'] = ENV['TZ'], new_tz
      yield
    ensure
      old_tz ? ENV['TZ'] = old_tz : ENV.delete('TZ')
    end

    def time_is_64bits?
      Time.time_with_datetime_fallback(:utc, 2039, 2, 21, 17, 44, 30, 1).is_a?(Time)
    end
end

class TimeExtMarshalingTest < ActiveSupport::TestCase
  def test_marshaling_with_utc_instance
    t = Time.utc(2000)
    unmarshaled = Marshal.load(Marshal.dump(t))
    assert_equal "UTC", unmarshaled.zone
    assert_equal t, unmarshaled
  end

  def test_marshaling_with_local_instance
    t = Time.local(2000)
    unmarshaled = Marshal.load(Marshal.dump(t))
    assert_equal t.zone, unmarshaled.zone
    assert_equal t, unmarshaled
  end

  def test_marshaling_with_frozen_utc_instance
    t = Time.utc(2000).freeze
    unmarshaled = Marshal.load(Marshal.dump(t))
    assert_equal "UTC", unmarshaled.zone
    assert_equal t, unmarshaled
  end

  def test_marshaling_with_frozen_local_instance
    t = Time.local(2000).freeze
    unmarshaled = Marshal.load(Marshal.dump(t))
    assert_equal t.zone, unmarshaled.zone
    assert_equal t, unmarshaled
  end

  def test_marshalling_preserves_fractional_seconds
    t = Time.parse('00:00:00.500')
    unmarshaled = Marshal.load(Marshal.dump(t))
    assert_equal t.to_f, unmarshaled.to_f
    assert_equal t, unmarshaled
  end

  def test_last_quarter_on_31st
    assert_equal Time.local(2004, 2, 29), Time.local(2004, 5, 31).last_quarter
  end
end

class TimeExtBehaviorTest < ActiveSupport::TestCase
  def test_compare_with_infinity
    assert_nothing_raised do
      assert_equal(-1, Time.now <=> Float::INFINITY)
      assert_equal(1, Time.now <=> -Float::INFINITY)
    end
  end
end
