require 'rake/clean'

SRCS = FileList['src/**/*.as']
MAIN = 'src/DemoOBJ.as'

task :default => 'debug.swf'

file 'debug.swf' => SRCS do |task|
  sh [
    'mxmlc',
    '-debug',
    '-verbose-stacktraces',
    '-strict',
    '-static-rsls',
    '-swf-version=13',
    '-target-player=11.0.0',
    "-output #{task.name}",
    '-sp+=src',
    MAIN
  ].join(' ')
end
CLEAN << 'debug.swf'

file 'release.swf' => SRCS do |task|
  sh [
    'mxmlc',
    '-strict',
    '-static-rsls',
    '-swf-version=13',
    '-target-player=11.0.0',
    "-output #{task.name}",
    '-sp+=src',
    MAIN
  ].join(' ')
end
CLEAN << 'release.swf'

task :fdb do
  Debugger.new.run
end

class Debugger
  def initialize
    $stdout.sync = true
    @line_triggers = {
      "Player connected; session starting." => proc { trigger :connected },
      "Player session terminated" => proc { trigger :connect },
      "Failed to connect; session timed out." => proc { trigger :connect }
    }
    @triggers = {
      "(fdb) " => proc { trigger :idle }
    }
    @read_buffer = ""
    @write_buffer = ""
    @state = :starting
  end

  def run
    open('|fdb', 'w+') do |handle|
      @pipe = handle
      while true do
        IO.select [@pipe], [], [@pipe]

        # read
        begin
          data = @pipe.read_nonblock 1024
          print data
          @read_buffer += data
        rescue Errno::EAGAIN, Errno::EWOULDBLOCK
          nil
        end

        # parse
        until (i = @read_buffer.index("\n")) == nil
          line, @read_buffer = @read_buffer.split("\n", 2)
          # puts line
          if (trigger = @line_triggers[line]) || (trigger = @triggers[line])
            trigger.call
          end
        end
        if (trigger = @triggers[@read_buffer])
          @read_buffer = ""
          trigger.call
        end

        # write
        unless @write_buffer.empty?
          length = @pipe.write_nonblock @write_buffer
          @write_buffer.slice! length..-1 if length > 0
        end
      end
    end
  end

  def trigger(type)
    case type
    when :connect
      write "run"
      @state = :connecting
    when :connected
      @state = :connected
    when :continue
      write "continue"
      @state = :running
    when :idle
      case @state
      when :starting then trigger :connect
      when :connected then trigger :continue
      end
    else
      raise "Unknown trigger type #{type}"
    end
  end

  def write(command)
    print command, "\n"
    @pipe.write command + "\n"
  end
end
