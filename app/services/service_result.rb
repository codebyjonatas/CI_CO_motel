class ServiceResult
  attr_reader :data, :error, :code

  def initialize(success:, data: nil, error: nil, code: nil)
    @success = success
    @data = data
    @error = error
    @code = code
  end

  def success?
    @success
  end

  def failure?
    !@success
  end
end
