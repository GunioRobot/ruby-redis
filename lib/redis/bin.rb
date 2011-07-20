require File.expand_path '../redis', File.dirname(__FILE__)
require_relative 'config'
require_relative 'logger'
require_relative 'strict'
require_relative 'connection'
require_relative 'protocol'
require_relative 'database'
require_relative 'server'
require_relative 'keys'
require_relative 'strings'
require_relative 'lists'
require_relative 'sets'
require_relative 'zsets'
require_relative 'hashes'
require_relative 'pubsub'

class Redis
  class Bin

    class RubyRedis < EventMachine::Connection

      include Strict
      include Connection
      include Protocol
      include Sender
      
      def initialize password=nil
        @password = password
        @database = Redis.databases[0]
        authorized nil
        super()
      end

      def authorized password
        return if @authorized
        return false unless @password == password
        extend Server
        extend Keys
        extend Strings
        extend Lists
        extend Sets
        extend ZSets
        extend Hashes
        extend PubSub
        @authorized = true
      end
      
    end
    
    def self.server

      if ARGV==['-v'] or ARGV==['--version']
        print "Redis server version %s (Ruby)\n" % Redis::VERSION
        exit 0
      end

      if ARGV==['--help'] or ARGV.size > 1
        STDERR.print "Usage: ruby-redis [/path/to/redis.conf]\n"
        STDERR.print "       ruby-redis - (read config from stdin)\n"
        exit 1
      end

      show_no_config_warning = (ARGV.size == 0)

      config = Config.new(ARGV.empty? ? [] : ARGF)

      Dir.chdir config[:dir]

      Redis.logger config[:logfile] unless config[:logfile] == 'stdout'

      #TODO
      # Set server verbosity to 'debug'
      # it can be one of:
      # debug (a lot of information, useful for development/testing)
      # verbose (many rarely useful info, but not a mess like the debug level)
      # notice (moderately verbose, what you want in production probably)
      # warning (only very important / critical messages are logged)
      # loglevel verbose

      if show_no_config_warning
        Redis.logger.warn "Warning: no config file specified, using the default config. In order to specify a config file use 'ruby-redis /path/to/redis.conf'"
      end

      EventMachine.epoll
      EventMachine.run {
  
        (0...config[:databases]).each do |db_index|
          Redis.databases[db_index] ||= Database.new
        end

        #TODO support changing host and EventMachine::start_unix_domain_server
        EventMachine::start_server "127.0.0.1", config[:port], RubyRedis, config[:requirepass]

        if config[:daemonize]
          raise 'todo'
          # daemonize();
          # FILE *fp = fopen(server.pidfile,"w");
          # if (fp) { fprintf(fp,"%d\n",(int)getpid()); fclose(fp); }
        end
        
        Redis.logger.notice "Server started, Ruby Redis version %s" % Redis::VERSION
        Redis.logger.notice "The server is now ready to accept connections on port %d" % config[:port]

        # The test suite blocks until it gets the pid from the log.
        Redis.logger.flush

      }
      
    end
  end
end
