begin
  require 'rake'
  require 'ruby2ruby'
rescue LoadError
  require 'rubygems'
  require 'rake'
  require 'ruby2ruby'
end

module Rake
  class Task

    # Turn ourselves back into Rake task plaintext.
    def to_ruby
      out = ''
      out << "desc '#{@comment.gsub("'", "\\\\'")}'\n" if @comment
      out << "task '#{@name}'"

      if @arg_names && @arg_names.any?
        args = @arg_names.map { |arg| ":#{arg}" }.join(', ')
        out << ", #{args}"
      end

      if @prerequisites.any?
        deps = @prerequisites.map { |dep| "'#{dep}'" }.join(', ')
        out << ", :needs => [ #{deps} ]"
      end

      if @arg_names
        out << " do |t, args|\n"
      else
        out << " do\n"
      end

      out << @actions.map do |action|
        # get rid of the proc { / } lines
        action.to_ruby.split("\n")[1...-1].join("\n")
      end.join("\n")

      out << "\nend\n"
    end
  end

  class Application
    OPTIONS << ['--examine', '-e', GetoptLong::OPTIONAL_ARGUMENT,
                "Display the source code of the tasks (matching optional PATTERN)"]

    alias_method :original_do_option, :do_option
    def do_option(opt, value)
      if opt == "--examine"
        options.silent = true
        options.examine_tasks = true
        options.show_task_pattern = Regexp.new(value || '.')
      else
        original_do_option(opt, value)
      end
    end

    alias_method :original_top_level, :top_level
    def top_level
      standard_exception_handling do
        if options.examine_tasks
          display_task_code
        else
          original_top_level
        end
      end
    end

    def display_task_code
      out = tasks.select do |task|
        task.name =~ options.show_task_pattern
      end.map do |task|
        task.to_ruby
      end.join("\n")

      puts out
    end
  end
end
