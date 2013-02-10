class Bill
  attr_reader :id, :issued_by, :due_date, :total_amount, :barcode, :status

  def initialize(id, issued_by, due_date, total_amount, barcode, status)
    @id            = id.to_i
    @issued_by     = issued_by
    @due_date      = due_date
    @total_amount  = total_amount.to_f
    @barcode       = barcode
    @status        = status.to_sym
  end

  def save
    REDIS.hmset("bills:#{@id}",
                :issued_by, @issued_by,
                  :due_date, @due_date,
                  :total_amount, @total_amount,
                  :barcode, @barcode,
                  :status, @status)
    REDIS.zadd 'bills', Time.now.to_i, @id
  end

  def self.find(id)
    bill = REDIS.hgetall("bills:#{id}")
    new id,
      bill['issued_by'],
      bill['due_date'],
      bill['total_amount'],
      bill['barcode'],
      bill['status'] unless bill.empty?
  end

  def self.all
    REDIS.zrevrange('bills', 0, -1).map { |id| find id }
  end

  def self.count
    REDIS.keys("bills:*").count
  end

  def ===(other_bill)
    self.instance_variables.each do |ivar|
      return false unless self.instance_variable_get(ivar).eql? other_bill.instance_variable_get(ivar)
    end
  end
end
