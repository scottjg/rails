module ActiveORM
  class TestORMModel
    def initialize
      @new = true
      @valid = true
    end
    def save
      @new = false
    end
    def new_record?
      @new
    end
    def invalidate
      @valid = false
    end
    def valid?
      @valid
    end
  end
end