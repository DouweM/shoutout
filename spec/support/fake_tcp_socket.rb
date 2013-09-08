require "stringio"

class FakeTCPSocket < StringIO

  def <<(*args)
    # noop
  end

  def puts(*args)
    # noop
  end
  
  def print(*args)
    # noop
  end
  
  def printf(*args)
    # noop
  end
end