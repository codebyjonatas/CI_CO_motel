class ApplicationService
  def self.call(...)
    new(...).call
  end

  private

  def success(data = nil)
    ServiceResult.new(success: true, data: data)
  end

  def failure(error, code = :unprocessable_entity)
    ServiceResult.new(success: false, error: error, code: code)
  end
end
